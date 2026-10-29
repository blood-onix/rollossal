# Exports every Snow Village collection to art/export/<id>.fbx and writes art/export/manifest.json.
# Validates the modelling rules and exits non-zero on any violation, so a broken model can never reach
# the manifest (contract specs/005-theme-art-pipeline/contracts/art-pipeline.md §5; replaces rules 3 and
# 4 of the 004 contract): UVs inside the inner rect of one palette cell or one trim strip
# (art/palette.json schema v2), custom normals / smooth shading allowed (the FBX is exported with
# mesh_smooth_type "FACE" so split normals survive), one material named Palette, identity world matrix,
# origin at the footprint's bottom centre, longest side within +-5% of size, triangles inside the tier
# budget. tests/unit/ArtManifest.test.luau re-checks the manifest offline against the FBX files
# (bytes, sha256, budgets, hard-coded id scan).
# Run: blender --background --python art/scripts/export_all.py -- --out art/export

import datetime
import hashlib
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bmesh
import build_shared as shared
import bpy

EPS = 1e-4

REQUIRED_MATERIAL = "Palette"


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_json(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def fbx_op():
    # The FBX exporter operator name moved between Blender releases; use whichever exists.
    for candidate in ("export_scene.fbx", "io_scene_fbx.export", "io_scene_fbx.export_fb"):
        node = bpy.ops
        try:
            for part in candidate.split("."):
                node = getattr(node, part)
            return node
        except AttributeError:
            continue
    raise RuntimeError("no FBX export operator found in this Blender build")


def rects_from_palette(palette) -> dict:
    """Map every cell and strip name to its inner rect (u0, v0, u1, v1) from palette.json schema v2."""
    if "cells" not in palette or "strips" not in palette:
        raise RuntimeError("palette.json is schema v1 (run python3 art/scripts/palette.py)")
    rects = {}
    for group in ("cells", "strips"):
        for name, rect in palette[group].items():
            rects[name] = (rect["u0"], rect["v0"], rect["u1"], rect["v1"])
    return rects


def face_failures(obj, rects):
    """Every polygon's UVs must lie inside the inner rect of one cell or one strip; returns failures."""
    layer = obj.data.uv_layers.active
    if layer is None:
        return ["%s: no UV layer" % obj.name]
    failures = []
    tolerance = shared.UV_TOLERANCE
    for polygon in obj.data.polygons:
        ok = False
        for u0, v0, u1, v1 in rects.values():
            if all(u0 - tolerance <= layer.data[loop].uv.x <= u1 + tolerance
                   and v0 - tolerance <= layer.data[loop].uv.y <= v1 + tolerance
                   for loop in polygon.loop_indices):
                ok = True
                break
        if not ok:
            failures.append(f"{obj.name}: face {polygon.index} UVs span outside every cell and strip")
    return failures


def check_collection(coll, object_id, budgets, rects):
    """Validates one objectId collection against the modelling rules; returns its triangle count."""
    errors = []
    meshes = [o for o in coll.objects if o.type == "MESH"]
    others = [o.name for o in coll.objects if o.type != "MESH"]
    if not meshes:
        errors.append("collection holds no mesh")
    if others:
        errors.append(f"non-mesh children {others}")
    for obj in meshes:
        if obj.modifiers:
            errors.append(f"{obj.name}: unapplied modifiers {[m.name for m in obj.modifiers]}")
        # Contract §5 rule 2: smooth-shaded polygons and custom split normals are allowed; the FBX
        # export preserves them with mesh_smooth_type FACE (build_shared.py). No shading errors here.
        identity = obj.matrix_world.Identity(4)
        if obj.matrix_world != identity:
            errors.append(f"{obj.name}: world matrix not identity ({obj.matrix_world!r})")
        if len(obj.data.materials) != 1 or obj.data.materials[0].name != REQUIRED_MATERIAL:
            errors.append(f"{obj.name}: expected exactly one material '{REQUIRED_MATERIAL}', "
                          f"got {[m.name if m else None for m in obj.data.materials]}")

    min_x = max_x = min_y = max_y = min_z = max_z = None
    triangles = 0
    for obj in meshes:
        holes = face_failures(obj, rects)
        if holes:
            errors.extend(holes[:4])
        matrix = obj.matrix_world
        for vert in obj.data.vertices:
            wx, wy, wz = matrix @ vert.co
            min_x = wx if min_x is None else min(min_x, wx)
            max_x = wx if max_x is None else max(max_x, wx)
            min_y = wy if min_y is None else min(min_y, wy)
            max_y = wy if max_y is None else max(max_y, wy)
            min_z = wz if min_z is None else min(min_z, wz)
            max_z = wz if max_z is None else max(max_z, wz)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        triangles += len(bm.faces)
        bm.free()
    if min_x is not None:
        centre_x, centre_y = (min_x + max_x) / 2.0, (min_y + max_y) / 2.0
        longest = max(max_x - min_x, max_y - min_y, max_z - min_z)
        if abs(centre_x) > 0.02 or abs(centre_y) > 0.02:
            errors.append(f"origin not at the footprint centre ({centre_x:.3f}, {centre_y:.3f})")
        if abs(min_z) > 0.02:
            errors.append(f"origin not at the footprint bottom (min z {min_z:.3f})")
        size = budgets["sizes"].get(object_id)
        if size and abs(longest - size) > 0.05 * size:
            errors.append(f"longest side {longest:.3f} not within 5% of size {size}")
    tier = budgets["tiers"].get(object_id)
    limit = budgets["meshTriangles"][tier - 1] if tier else 10 ** 9
    if triangles > limit:
        errors.append(f"{triangles} post-triangulation triangles over budget {limit}")
    if errors:
        raise RuntimeError(f"{object_id}: " + "; ".join(errors))
    return triangles


def export_to_fbx(meshes, out_path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = meshes[-1]
    for obj in meshes:
        obj.select_set(True)
    exporter = fbx_op()
    kwargs = {
        "filepath": out_path,
        "use_selection": True,
        "apply_unit_scale": True,
        "axis_forward": "-Z",
        "axis_up": "Y",
        "object_types": {"MESH"},
        "add_leaf_bones": False,
        "bake_anim": False,
        "bake_space_transform": False,
        "mesh_smooth_type": shared.FBX_MESH_SMOOTH_TYPE,
        "path_mode": "STRIP",
    }
    try:
        exporter(**kwargs)
    except TypeError as exc:
        print(f"export: FBX operator rejected some kwargs ({exc}); retrying with the core set")
        exporter(filepath=out_path, use_selection=True, apply_unit_scale=True,
                 axis_forward="-Z", axis_up="Y", object_types={"MESH"})


def run() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    art = art_dir()
    out_abs = os.path.join(art, "export")
    if "--out" in argv:
        out_abs = os.path.normpath(os.path.join(art, "..", argv[argv.index("--out") + 1].strip()))
    source_dir = os.path.join(art, "source")
    if "--source" in argv:
        source_dir = os.path.abspath(argv[argv.index("--source") + 1])
    os.makedirs(out_abs, exist_ok=True)

    budgets = load_json(os.path.join(art, "scripts", "budgets.json"))
    rects = rects_from_palette(load_json(os.path.join(art, "palette.json")))

    entries = []
    for name in sorted(os.listdir(source_dir)):
        if not name.endswith(".blend"):
            continue
        bpy.ops.wm.open_mainfile(filepath=os.path.join(source_dir, name))
        collections = list(bpy.data.collections)
        if not collections:
            raise RuntimeError(f"{name}: no collections to export")
        for coll in sorted(collections, key=lambda c: c.name):
            object_id = coll.name
            triangles = check_collection(coll, object_id, budgets, rects)
            out_path = os.path.join(out_abs, f"{object_id}.fbx")
            export_to_fbx([o for o in coll.objects if o.type == "MESH"], out_path)
            data = open(out_path, "rb").read()
            entries.append({
                "id": object_id,
                "tier": budgets["tiers"][object_id],
                "triangles": triangles,
                "bytes": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
            })
            print(f"export: {object_id} ({triangles} tris, {len(data)} bytes)")

    expected = set(budgets["tiers"])
    exported = {entry["id"] for entry in entries}
    if expected != exported:
        raise RuntimeError(f"id mismatch: missing={sorted(expected - exported)} "
                           f"extra={sorted(exported - expected)}")

    manifest = {
        "generated": datetime.date.today().isoformat(),
        "blender": bpy.app.version_string,
        "atlas": "art/atlases",
        "palette": "palette.png",
        "meshes": sorted(entries, key=lambda entry: entry["id"]),
    }
    manifest_path = os.path.join(out_abs, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")
    print(f"export: wrote {manifest_path} ({len(entries)} meshes)")


try:
    run()
    print("export: OK")
except Exception as exc:  # Blender swallows python failures with exit code 0; make the failure real.
    print(f"export: FAILED\n{exc}")
    sys.exit(1)
