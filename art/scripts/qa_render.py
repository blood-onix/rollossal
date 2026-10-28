# Renders every mesh as one flat-lit cell in a contact sheet (art/qa/grid.png) so the
# proportions can be eyeballed (art-pipeline.md rule 6: cartoonish 10-20% exaggeration). Each object is
# imported from its tier .blend, normalized to fit a cell, and rendered with the Workbench engine in
# material colour mode. Run:
#   blender --background --python art/scripts/qa_render.py -- --out art/qa

import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector, Matrix


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def out_dir() -> str:
    argv = sys.argv
    out = os.path.join(art_dir(), "qa")
    if "--out" in argv:
        out = argv[argv.index("--out") + 1]
    os.makedirs(out, exist_ok=True)
    return out


CELL_PX = 260
MARGIN_PX = 6
TIER_FILES = {1: "tier1_crumbs", 2: "tier2_toys", 3: "tier3_furniture",
              4: "tier4_street", 5: "tier5_town", 0: "hub"}


def budgets() -> dict:
    path = os.path.join(art_dir(), "scripts", "budgets.json")
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def tier_file_for(data, object_id):
    tier = data["tiers"][object_id]
    tier = 0 if object_id == "hub" else tier
    return TIER_FILES[tier]


def render_cell(object_id, blend, path):
    bpy.ops.wm.read_homefile(use_empty=True)
    scene = bpy.context.scene
    directory = os.path.join(blend, "Collection")
    bpy.ops.wm.append(directory=directory, filename=object_id)
    obj = bpy.data.objects[object_id]

    # Normalize: longest bbox side 2.4 inside a 3.0 cell so every row reads at the same scale.
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

    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def stitch(paths, out, columns=9):
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
    sheet = bpy.data.images.new("grid", width, height, alpha=False)
    sheet.pixels.foreach_set(canvas.ravel())
    sheet.filepath_raw = out
    sheet.file_format = "PNG"
    sheet.save()
    return out


def main():
    data = budgets()
    ids = sorted(data["tiers"].keys())
    paths = []
    for object_id in ids:
        blend = os.path.join(art_dir(), "source", f"{tier_file_for(data, object_id)}.blend")
        path = os.path.join(out_dir(), f"{object_id}.png")
        render_cell(object_id, blend, path)
        paths.append(path)
    print(f"qa: wrote {stitch(paths, os.path.join(out_dir(), 'grid.png'))}")


main()
