# Street-level QA images for the 013 tween-appeal rework (Phase 9, owner decision 2026-11-07). Renders with EEVEE
# under the theme lighting (sun from Themes.<theme>.lighting.clockTime, sky and ambient from the light-* cells), on a
# mid-grey background, and writes:
#   - "tiles": one sheet of single meshes, each in its own tile, captioned with id, triangles, % of the tier ceiling and
#     longest side. view "street" = three-quarter camera at play height (at most 9.3 studs up, the D5 camera height),
#     looking at the mesh's front (+y); view "top" = the 52 degree orthographic view of the older contact sheets.
#   - "scene": a short street assembled from kit meshes at real spacing (a list of placements plus flat ground slabs),
#     seen from the ball camera at a given diameter D (distance max(8, 4 D), pitch 20 degrees, Config.camera*).
#   - "stack": stacks existing PNGs vertically (the before/after sheet).
# Meshes come from the art/source/*.blend collections (one collection per id), so a sheet can be rendered before an
# export. `atlas` (optional, per job) overrides the theme atlas path, which is how the "before" tiles use the committed
# atlas of the time. Run through the Blender MCP (execute_blender_code); the run replaces the open file:
#   PARAMS = {"root": "<repo root>", "jobs": [{"kind": "tiles", "theme": "city", "view": "street", "ids": [...],
#             "out": "<png>"}]}
#   exec(open(PARAMS["root"] + "/art/scripts/street_shots.py").read()); run(PARAMS)
# The lighting table mirrors src/shared/Content/Themes.luau; tests/unit/Themes.test.luau pins the Luau side, and
# LIGHTING below must be updated with it (a run prints the values it used).

import glob
import json
import math
import os

import bpy
from mathutils import Vector

ROOT = None
TILE = 520
CAPTION_PX = 64
GREY = 0.5  # sRGB mid-grey background
BUDGETS = None

# Themes.luau lighting, per theme: clockTime, brightness, colour-grading contrast and saturation, shadow softness.
LIGHTING = {
    "before": {"clock": 13.0, "brightness": 3.0, "contrast": 0.0, "saturation": 0.0, "soft": 0.5,
               "tint": (1.0, 1.0, 1.0), "sun": (1.0, 0.97, 0.92)},
    "city": {"clock": 16.8, "brightness": 2.6, "contrast": 0.12, "saturation": 0.06, "soft": 0.12,
             "tint": (1.0, 0.965, 0.925), "sun": (1.0, 0.86, 0.70)},
    "winter": {"clock": 16.5, "brightness": 2.2, "contrast": 0.1, "saturation": -0.04, "soft": 0.18,
               "tint": (0.94, 0.965, 1.0), "sun": (1.0, 0.88, 0.76)},
}


def art_dir():
    return os.path.join(ROOT, "art")


def srgb_to_linear(c):
    c = c / 255.0 if c > 1.0 else c
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def tokens_light(theme):
    tokens = json.load(open(os.path.join(ROOT, "docs", "design", "tokens.json"), encoding="utf-8"))
    out = {}
    for t in tokens["color"]["tokens"]:
        if t["name"] in ("light-sky", "light-fog", "light-ambient"):
            v = t["value"]
            v = v.get(theme, v["city"]) if isinstance(v, dict) else v
            v = v.lstrip("#")
            out[t["name"]] = tuple(int(v[i:i + 2], 16) for i in (0, 2, 4))
    return out


def index_sources():
    where = {}
    for path in sorted(glob.glob(os.path.join(art_dir(), "source", "*.blend"))):
        with bpy.data.libraries.load(path, link=False) as (data_from, _):
            for name in data_from.collections:
                where[name] = path
    return where


def load_mesh(object_id, path):
    with bpy.data.libraries.load(path, link=False) as (data_from, data_to):
        data_to.collections = [object_id]
    coll = data_to.collections[0]
    return next(o for o in coll.objects if o.type == "MESH")


def is_fronts(object_id):
    return (object_id.startswith("ck_shop_") or object_id.startswith("ck_billboard_")
            or object_id == "ck_meme_buffering_billboard")


def atlas_material(theme, fronts, override=None):
    key = ("fronts" if fronts else "theme", theme, override or "")
    name = "atl_" + "_".join(k for k in key if k)[-50:]
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    path = override if (override and not fronts) else os.path.join(
        art_dir(), "atlases", "fronts" if fronts else "", theme + ".png")
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    tree = mat.node_tree
    bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    tex = tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(path, check_existing=False)
    tex.interpolation = "Closest"
    tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    for inp in ("Specular IOR Level", "Specular"):
        if inp in bsdf.inputs:
            bsdf.inputs[inp].default_value = 0.15
    return mat


def flat_material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*[srgb_to_linear(c) for c in rgb], 1.0)
    bsdf.inputs["Roughness"].default_value = 0.95
    return mat


def emit_material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    tree = mat.node_tree
    for n in list(tree.nodes):
        tree.nodes.remove(n)
    out = tree.nodes.new("ShaderNodeOutputMaterial")
    em = tree.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*rgb, 1.0)
    tree.links.new(em.outputs[0], out.inputs[0])
    return mat


def setup_scene(theme, light_key):
    bpy.ops.wm.read_homefile(use_empty=True)
    scene = bpy.context.scene
    light = LIGHTING[light_key]
    cells = tokens_light(theme)
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    ee = scene.eevee
    for attr, val in (("use_shadows", True), ("shadow_ray_count", 2), ("shadow_step_count", 8),
                      ("use_raytracing", False), ("taa_render_samples", 32)):
        if hasattr(ee, attr):
            setattr(ee, attr, val)
    # Sun: elevation from clockTime (sunrise 6, solar noon 12.5, about 62 degrees at noon), azimuth sweeping west.
    hour = light["clock"]
    elevation = max(8.0, 62.0 * math.sin(math.pi * (hour - 6.0) / 13.0))
    azimuth = 180.0 + (hour - 12.5) * 15.0
    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy = light["brightness"] * 1.25
    sun_data.color = light["sun"]
    sun_data.angle = math.radians(1.0 + 10.0 * light["soft"])
    sun = bpy.data.objects.new("sun", sun_data)
    sun.rotation_euler = (math.radians(90 - elevation), 0, math.radians(azimuth))
    scene.collection.objects.link(sun)
    # World: lighting from the outdoor ambient (light-sky), camera rays see mid-grey.
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    tree = world.node_tree
    for n in list(tree.nodes):
        tree.nodes.remove(n)
    out = tree.nodes.new("ShaderNodeOutputWorld")
    mix = tree.nodes.new("ShaderNodeMixShader")
    path = tree.nodes.new("ShaderNodeLightPath")
    amb = tree.nodes.new("ShaderNodeBackground")
    sky = cells["light-sky"]
    amb.inputs["Color"].default_value = (*[srgb_to_linear(c) for c in sky], 1.0)
    amb.inputs["Strength"].default_value = 0.55
    bg = tree.nodes.new("ShaderNodeBackground")
    g = srgb_to_linear(GREY)
    bg.inputs["Color"].default_value = (g, g, g, 1.0)
    tree.links.new(path.outputs["Is Camera Ray"], mix.inputs["Fac"])
    tree.links.new(amb.outputs[0], mix.inputs[1])
    tree.links.new(bg.outputs[0], mix.inputs[2])
    tree.links.new(mix.outputs[0], out.inputs[0])
    scene.world = world
    # Colour grading approximation: Standard view, contrast via a look when the build offers one.
    vs = scene.view_settings
    vs.view_transform = "Standard"
    looks = [i.identifier for i in vs.bl_rna.properties["look"].enum_items]
    want = "None"
    if light["contrast"] >= 0.1:
        want = next((l for l in looks if "Medium High Contrast" in l), "None")
    try:
        vs.look = want
    except TypeError:
        vs.look = "None"
    vs.exposure = 0.0
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.film_transparent = False
    print(f"street_shots: lighting {light_key} theme {theme}: sun elevation {elevation:.0f} azimuth {azimuth:.0f}, "
          f"look {vs.look}")
    return scene, light


def ground(scene, size, rgb, z=0.0, centre=(0, 0)):
    mesh = bpy.data.meshes.new("ground")
    s = size / 2
    mesh.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
    obj = bpy.data.objects.new("ground", mesh)
    obj.location = (centre[0], centre[1], z)
    mesh.materials.append(flat_material(f"g{rgb}", rgb))
    scene.collection.objects.link(obj)
    return obj


def slab(scene, x0, y0, x1, y1, z0, z1, rgb, name="slab"):
    mesh = bpy.data.meshes.new(name)
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh.from_pydata(v, [], f)
    obj = bpy.data.objects.new(name, mesh)
    mesh.materials.append(flat_material(f"s{rgb}", rgb))
    scene.collection.objects.link(obj)
    return obj


def tri_count(obj):
    return sum(max(1, len(p.vertices) - 2) for p in obj.data.polygons)


def place(scene, object_id, where, theme, atlas=None):
    obj = load_mesh(object_id, where[object_id])
    scene.collection.objects.link(obj)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material(theme, is_fronts(object_id), atlas))
    return obj


def bbox(obj):
    pts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def look_at(cam, target):
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()


def caption(scene, cam, lines, ink):
    """Caption text parented to the camera, along the bottom of the frame."""
    for k, body in enumerate(lines):
        curve = bpy.data.curves.new("cap", type="FONT")
        curve.body = body
        curve.align_x = "CENTER"
        obj = bpy.data.objects.new("cap", curve)
        obj.data.materials.append(ink)
        scene.collection.objects.link(obj)
        obj.parent = cam
        if cam.data.type == "ORTHO":
            w = cam.data.ortho_scale
            obj.location = (0, -w * (0.43 + 0.055 * k), -1.0)
            curve.size = w * 0.045
        else:
            d = 1.0
            half = math.tan(cam.data.angle / 2) * d
            obj.location = (0, -half * (0.86 + 0.11 * k), -d)
            curve.size = half * 0.09


def tile_job(job, where, out_png):
    theme = job["theme"]
    scene, _ = setup_scene(theme, job.get("lighting", theme))
    ids = job["ids"]
    ink = emit_material("ink", (0.02, 0.02, 0.03))
    tiles = []
    tmp = os.path.join(os.path.dirname(out_png), "_tiles")
    os.makedirs(tmp, exist_ok=True)
    for object_id in ids:
        for o in [o for o in scene.objects if o.type in ("MESH", "FONT", "CAMERA")]:
            bpy.data.objects.remove(o, do_unlink=True)
        obj = place(scene, object_id, where, theme, job.get("atlas"))
        obj.rotation_euler = (0, 0, math.radians(job.get("rotate", {}).get(object_id, 0)))
        bpy.context.view_layer.update()
        lo, hi = bbox(obj)
        size = max(hi - lo)
        ground(scene, size * 400, (104, 104, 104), 0.0, ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2))
        centre = (lo + hi) / 2
        cam_data = bpy.data.cameras.new("cam")
        cam = bpy.data.objects.new("cam", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
        if job["view"] == "top":
            elev = math.radians(52)
            cam_data.type = "ORTHO"
            cam_data.ortho_scale = size * 1.55
            yaw = math.radians(0)
            d = size * 4
            cam.location = centre + Vector((math.sin(yaw) * math.cos(elev), math.cos(yaw) * math.cos(elev),
                                            math.sin(elev))) * d - Vector((0, 0, size * 0.12))
            look_at(cam, centre - Vector((0, 0, size * 0.12)))
        else:
            cam_data.lens_unit = "FOV"
            cam_data.angle = math.radians(50)
            yaw = math.radians(32)
            height = min(9.3, max(1.2, 0.5 * (hi.z - lo.z)))
            target = Vector((centre.x, centre.y, (lo.z + hi.z) * 0.5))
            flat = Vector((math.sin(yaw), math.cos(yaw), 0))
            # back off until every bbox corner is inside the frame (with room for the caption)
            dist = size * 0.8
            for _ in range(80):
                cam.location = Vector((target.x, target.y, 0)) + flat * dist + Vector((0, 0, height))
                look_at(cam, target - Vector((0, 0, (hi.z - lo.z) * 0.06)))
                bpy.context.view_layer.update()
                inv = cam.matrix_world.inverted()
                ok = True
                half = math.tan(cam_data.angle / 2)
                for c in obj.bound_box:
                    p = inv @ (obj.matrix_world @ Vector(c))
                    if p.z >= -0.1:
                        ok = False
                        break
                    x, y = p.x / -p.z, p.y / -p.z
                    if abs(x) > half * 0.86 or y > half * 0.86 or y < -half * 0.66:
                        ok = False
                        break
                if ok:
                    break
                dist *= 1.08
            cam_data.clip_end = dist * 20
        tier = BUDGETS["tiers"].get(object_id, 0)
        ceiling = BUDGETS["meshTriangles"][tier - 1] if tier else 0
        tris = tri_count(obj)
        pct = f"{100 * tris / ceiling:.0f}% of T{tier}" if ceiling else ""
        caption(scene, cam, [object_id.replace("ck_", "").replace("dt_", ""),
                             f"{tris} tris  {pct}  {BUDGETS['sizes'].get(object_id, size):g} st"], ink)
        scene.render.resolution_x = TILE
        scene.render.resolution_y = TILE
        path = os.path.join(tmp, f"{job['name']}_{object_id}.png")
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        tiles.append(path)
    compose(tiles, job.get("columns", 4), out_png, job.get("title"))
    for p in tiles:
        os.remove(p)
    try:
        os.rmdir(tmp)
    except OSError:
        pass


def read_pixels(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    import numpy as np
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    bpy.data.images.remove(img)
    return px


def write_pixels(px, path):
    import numpy as np
    h, w = px.shape[:2]
    img = bpy.data.images.new("out", w, h, alpha=False)
    img.pixels.foreach_set(np.ascontiguousarray(px, dtype=np.float32).reshape(-1))
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def compose(paths, columns, out_png, title=None):
    import numpy as np
    images = [read_pixels(p) for p in paths]
    h, w = images[0].shape[:2]
    rows = math.ceil(len(images) / columns)
    sheet = np.full((rows * h, columns * w, 4), 0.5, dtype=np.float32)
    sheet[..., 3] = 1.0
    for i, im in enumerate(images):
        r, c = i // columns, i % columns
        y0 = (rows - 1 - r) * h  # Blender pixel rows start at the bottom
        sheet[y0:y0 + h, c * w:(c + 1) * w] = im
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    write_pixels(sheet, out_png)
    print(f"street_shots: wrote {out_png} ({len(images)} tiles)")


def stack(paths, out_png, gap=12):
    import numpy as np
    images = [read_pixels(p) for p in paths]
    width = max(im.shape[1] for im in images)
    height = sum(im.shape[0] for im in images) + gap * (len(images) - 1)
    sheet = np.full((height, width, 4), 1.0, dtype=np.float32)
    y = height
    for im in images:
        h, w = im.shape[:2]
        y -= h
        sheet[y:y + h, 0:w] = im
        y -= gap
    write_pixels(sheet, out_png)
    print(f"street_shots: wrote {out_png} (stack of {len(images)})")


def scene_job(job, where, out_png):
    """job: theme, D, ground: [[x0,y0,x1,y1,z0,z1,[r,g,b]]], items: [[id, x, y, yaw_deg]], ball: [x, y], heading."""
    theme = job["theme"]
    scene, _ = setup_scene(theme, job.get("lighting", theme))
    for g in job.get("ground", []):
        slab(scene, *g[:6], tuple(g[6]))
    for object_id, x, y, yaw in job["items"]:
        obj = place(scene, object_id, where, theme, job.get("atlas"))
        obj.location = (x, y, job.get("lift", {}).get(object_id, 0.0))
        obj.rotation_euler = (0, 0, math.radians(yaw))
    d = job["D"]
    bx_, by_ = job["ball"]
    heading = math.radians(job.get("heading", 0))
    dist = max(8.0, 4.0 * d)
    pitch = math.radians(job.get("pitch", 20))
    ball_mesh = bpy.data.meshes.new("ball")
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=16, radius=d / 2)
    bm.to_mesh(ball_mesh)
    bm.free()
    for p in ball_mesh.polygons:
        p.use_smooth = True
    ball = bpy.data.objects.new("ball", ball_mesh)
    ball.location = (bx_, by_, d / 2 + job.get("ball_z", 0.0))
    ball_mesh.materials.append(flat_material("ballmat", (226, 92, 60)))
    scene.collection.objects.link(ball)
    fwd = Vector((math.sin(heading), math.cos(heading), 0))
    cam_data = bpy.data.cameras.new("cam")
    cam_data.lens_unit = "FOV"
    cam_data.sensor_fit = "VERTICAL"
    cam_data.angle = math.radians(70)
    cam_data.clip_end = 3000
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    target = Vector(ball.location)
    cam.location = target - fwd * dist * math.cos(pitch) + Vector((0, 0, dist * math.sin(pitch)))
    look_at(cam, target + fwd * dist * 0.35)
    scene.camera = cam
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)
    print(f"street_shots: wrote {out_png}")


def run(params):
    global ROOT, BUDGETS
    ROOT = params["root"]
    bpy.ops.wm.read_homefile(use_empty=True)
    BUDGETS = json.load(open(os.path.join(art_dir(), "scripts", "budgets.json"), encoding="utf-8"))
    where = index_sources()
    for job in params["jobs"]:
        if job["kind"] == "stack":
            stack(job["paths"], job["out"])
            continue
        ids = job.get("ids") or sorted({i[0] for i in job.get("items", [])})
        missing = [i for i in ids if i not in where]
        if missing:
            raise RuntimeError(f"{job.get('name')}: ids with no collection in art/source: {missing}")
        if job["kind"] == "tiles":
            tile_job(job, where, job["out"])
        elif job["kind"] == "scene":
            scene_job(job, where, job["out"])
    print("street_shots: OK")
