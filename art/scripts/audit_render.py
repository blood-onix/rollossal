# Audit renders for the 99 dt_* meshes (013 US1; contracts/audit-and-asset-list.md). For every dt_* collection in the
# Downtown source files it renders one PNG per theme (city, winter) with the Workbench engine and that theme's atlas,
# and measures the w-season share: the share of the mesh's surface area, by face, whose UVs sit in the w-season cell.
# The share depends on the mesh only, so city and winter carry the same number; both are written so the contract's
# per-theme field is filled and a theme-specific mesh variant could differ later.
# Writes <out>/render-data.json and <out>/renders/<theme>/<id>.png. art/scripts/audit_report.py turns that into
# audit.json and audit.md. Run through the Blender MCP (execute_blender_code):
#   PARAMS = {"root": "<repo root>", "out": "<repo root>/specs/013-city-asset-kit/audit", "only": ["dt_bench"]}
#   exec(open(PARAMS["root"] + "/art/scripts/audit_render.py").read()); run(PARAMS)
# `only` is optional (omit it for all 99). The run replaces the open file in the claimed Blender.

import json
import math
import os

import bpy
from mathutils import Vector

THEMES = ("city", "winter")
PX = 384
SEASON_CELL = "w-season"
SOURCES = ("dt_tier1", "dt_tier2", "dt_tier3", "dt_tier4", "dt_tier5", "dt_theme")
ROOT = None


def art_dir() -> str:
    return os.path.join(ROOT, "art")


def season_share(obj, cell) -> float:
    layer = obj.data.uv_layers.active
    total = inside = 0.0
    u0, v0, u1, v1 = cell
    tol = 1e-6
    for polygon in obj.data.polygons:
        total += polygon.area
        if all(u0 - tol <= layer.data[i].uv.x <= u1 + tol and v0 - tol <= layer.data[i].uv.y <= v1 + tol
               for i in polygon.loop_indices):
            inside += polygon.area
    return inside / total if total > 0 else 0.0


def setup_scene(scene):
    world = bpy.data.worlds.new("BG")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.72, 0.78, 0.85, 1.0)
    scene.world = world
    sun = bpy.data.lights.new("Sun", type="SUN")
    sun.energy = 3.0
    sun_obj = bpy.data.objects.new("Sun", sun)
    sun_obj.rotation_euler = (math.radians(52), 0.0, math.radians(28))
    scene.collection.objects.link(sun_obj)
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = PX
    scene.render.resolution_y = PX
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def frame(cam, obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    mins = [min(c[i] for c in corners) for i in range(3)]
    maxs = [max(c[i] for c in corners) for i in range(3)]
    centre = Vector([(mins[i] + maxs[i]) / 2.0 for i in range(3)])
    radius = max(maxs[i] - mins[i] for i in range(3))
    direction = Vector((0.9, -2.2, 1.4)).normalized()
    cam.data.ortho_scale = radius * 1.35
    cam.location = centre + direction * (radius * 4.0 + 5.0)
    cam.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()


def main(out, only):
    art = art_dir()
    with open(os.path.join(art, "palette.json"), encoding="utf-8") as handle:
        rect = json.load(handle)["cells"][SEASON_CELL]
    cell = (rect["u0"], rect["v0"], rect["u1"], rect["v1"])
    data = {}
    for name in SOURCES:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(art, "source", name + ".blend"))
        scene = bpy.context.scene
        cam = setup_scene(scene)
        material = bpy.data.materials["Palette"]
        image_node = next(n for n in material.node_tree.nodes if n.type == "TEX_IMAGE")
        for object_id in sorted(c.name for c in bpy.data.collections if c.name.startswith("dt_")):
            if only and object_id not in only:
                continue
            obj = next(o for o in bpy.data.collections[object_id].objects if o.type == "MESH")
            for other in bpy.data.objects:
                if other.type == "MESH":
                    other.hide_render = other is not obj
            frame(cam, obj)
            share = season_share(obj, cell)
            renders = {}
            for theme in THEMES:
                image_node.image = bpy.data.images.load(os.path.join(art, "atlases", theme + ".png"),
                                                        check_existing=True)
                image_node.interpolation = "Closest"
                rel = f"renders/{theme}/{object_id}.png"
                os.makedirs(os.path.join(out, "renders", theme), exist_ok=True)
                scene.render.filepath = os.path.join(out, rel)
                bpy.ops.render.render(write_still=True)
                renders[theme] = rel
            data[object_id] = {"seasonShare": {theme: round(share, 4) for theme in THEMES}, "renders": renders}
    path = os.path.join(out, "render-data.json")
    merged = {}
    if only and os.path.isfile(path):
        with open(path, encoding="utf-8") as handle:
            merged = json.load(handle)["meshes"]
    merged.update(data)
    os.makedirs(out, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump({"version": 1, "blender": bpy.app.version_string, "meshes": dict(sorted(merged.items()))},
                  handle, indent=2)
        handle.write("\n")
    print(f"audit_render: wrote {path} ({len(merged)} meshes)")


def run(params):
    global ROOT
    ROOT = params["root"]
    main(os.path.abspath(params["out"]), set(params.get("only", [])))
    print("audit_render: OK")
