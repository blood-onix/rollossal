# Renders one object six times, each render with a different theme's atlas applied to its Palette
# material, and stitches the cells into a 3 x 2 sheet art/qa/theme_grid_<object>.png for the
# cross-theme readability check (contract specs/005-theme-art-pipeline/contracts/art-pipeline.md §6).
# The reference sheet committed in the repo comes from Phase 7 (T035); this script generates it.
# Run:
#   blender --background --python art/scripts/qa_grid.py -- --object bench --out art/qa

import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

CELL_PX = 512          # one render; the sheet is 3 x 2 of these
TIER_FILES = {1: "tier1_crumbs", 2: "tier2_toys", 3: "tier3_furniture",
              4: "tier4_street", 5: "tier5_town", 0: "hub"}


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def root_dir() -> str:
    # tokens.json lives above art/ in docs/design.
    return os.path.dirname(art_dir())


def out_dir() -> str:
    argv = sys.argv
    out = os.path.join(art_dir(), "qa")
    if "--out" in argv:
        out = argv[argv.index("--out") + 1].strip()
    os.makedirs(out, exist_ok=True)
    return out


def themes() -> list:
    """The six theme ids in tokens.json color.themes order."""
    with open(os.path.join(root_dir(), "docs", "design", "tokens.json"), "r", encoding="utf-8") as handle:
        tokens = json.load(handle)
    return [theme["id"] for theme in tokens["color"]["themes"]]


def budgets() -> dict:
    path = os.path.join(art_dir(), "scripts", "budgets.json")
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def tier_file_for(data, object_id) -> str:
    tier = data["tiers"][object_id]
    return TIER_FILES[0 if object_id == "hub" else tier]


def image_node(obj):
    """The image node of the object's Palette material (the only colour source of a prop).
    Look the node up by type, never by name: other Blender locales localize node names."""
    for material in obj.data.materials:
        if material and material.use_nodes:
            for node in material.node_tree.nodes:
                if node.bl_idname == "ShaderNodeTexImage":
                    return node
    raise RuntimeError(f"{obj.name}: no image node in any material")


def prepare_scene(object_id, blend):
    bpy.ops.wm.read_homefile(use_empty=True)
    scene = bpy.context.scene
    bpy.ops.wm.append(directory=os.path.join(blend, "Collection"), filename=object_id)
    obj = bpy.data.objects[object_id]
    node = image_node(obj)

    # Normalize: longest bbox side 2.4 inside a 3.0 ortho frame (same framing as qa_render.py).
    bbox = [obj.matrix_world @ v.co for v in obj.data.vertices]
    mins = [min(c[i] for c in bbox) for i in range(3)]
    maxs = [max(c[i] for c in bbox) for i in range(3)]
    centre = [(mins[i] + maxs[i]) / 2.0 for i in range(3)]
    longest = max(maxs[i] - mins[i] for i in range(3))
    scale = 2.4 / longest
    obj.location = (-centre[0] * scale, -centre[1] * scale, -mins[2] * scale)
    obj.scale = (scale, scale, scale)

    world = bpy.data.worlds.new("BG")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.72, 0.78, 0.85, 1.0)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
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
    scene.display.shading.cavity_type = "BOTH"
    scene.render.resolution_x = CELL_PX
    scene.render.resolution_y = CELL_PX
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.film_transparent = False

    direction = Vector((0.9, -2.2, 1.4)).normalized()
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 3.0
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = direction * 6.0
    cam.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    return node


def stitch(paths, out, columns=3):
    rows = math.ceil(len(paths) / columns)
    width = columns * CELL_PX
    height = rows * CELL_PX
    canvas = np.ones((height, width, 4), dtype=np.float32)
    for index, path in enumerate(paths):
        image = bpy.data.images.load(path)
        pixels = np.empty(image.size[0] * image.size[1] * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        pixels = pixels.reshape(image.size[1], image.size[0], 4)
        row, col = divmod(index, columns)
        y = (rows - 1 - row) * CELL_PX
        x = col * CELL_PX
        canvas[y:y + CELL_PX, x:x + CELL_PX, :] = pixels
        bpy.data.images.remove(image)
    sheet = bpy.data.images.new("theme_grid", width, height, alpha=False)
    sheet.pixels.foreach_set(canvas.ravel())
    sheet.filepath_raw = out
    sheet.file_format = "PNG"
    sheet.save()
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if "--object" not in argv:
        raise RuntimeError("usage: --object <objectId> --out <dir>")
    object_id = argv[argv.index("--object") + 1].strip()
    data = budgets()
    blend = os.path.join(art_dir(), "source", f"{tier_file_for(data, object_id)}.blend")

    node = prepare_scene(object_id, blend)
    out = out_dir()
    paths = []
    for theme_id in themes():
        atlas = os.path.join(art_dir(), "atlases", f"{theme_id}.png")
        if not os.path.exists(atlas):
            raise RuntimeError(f"missing atlas {atlas} (run python3 art/scripts/palette.py first)")
        # Swap only the image datablock; the node object and its mapping stay as authored.
        node.image = bpy.data.images.load(atlas, check_existing=False)
        path = os.path.join(out, f"theme_cell_{object_id}_{theme_id}.png")
        bpy.context.scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append(path)
        print(f"qa_grid: rendered {theme_id}")
    sheet_path = os.path.join(out, f"theme_grid_{object_id}.png")
    print(f"qa_grid: wrote {stitch(paths, sheet_path)}")
    for path in paths:
        os.remove(path)


try:
    main()
    print("qa_grid: OK")
except Exception as exc:  # Blender swallows python failures with exit code 0; make the failure real.
    print(f"qa_grid: FAILED\n{exc}", file=sys.stderr)
    sys.exit(1)
