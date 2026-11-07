# Offline renderer for the Park City fixed shots (specs/012-park-city-map, research R6, T040).
# Draws the boxes of art/render/world-parkcity.json (written by scripts/park-capture-export.luau) and renders one
# PNG per shot. Grey box only: every object is a box by dims, ramps are wedges, no meshes. Run through the Blender MCP
# (execute_blender_code), never from the shell:
#
#   PARAMS = {"root": "<repo root>", "out": "<repo root>/specs/012-park-city-map/shots", "commit": "<sha>"}
#   exec(open(PARAMS["root"] + "/art/scripts/park_capture_render.py").read()); run(PARAMS)
#
# Roblox (x east, y up, z south) maps to Blender (x, -z, y), as in capture_render.py. No random, fixed sample count.

import hashlib
import json
import math
import os
from datetime import date

import bpy
from mathutils import Vector

SUN_COLOUR = (1.0, 0.95, 0.85)
SUN_STRENGTH = 3.4
SUN_ELEVATION = 55.0
SUN_AZIMUTH = 215.0
SKY = (170, 215, 250)
RESOLUTION = (1280, 720)

PARITY_NOTES = [
    "Offline Blender (EEVEE) composition check of the world data, not a pixel match: Roblox lighting, fog and shadow "
    "filtering are not reproduced.",
    "Every object is a box by its dims (tier colours: T1 yellow, T2 orange, T3 red, T4 purple, T5 blue, T6 dark); "
    "ramps are wedges; spirals are planks along the helix; placeholders are simple boxes.",
]


def srgb_to_linear(value):
    value = value / 255.0
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def to_blender(x, y, z):
    return Vector((x, -z, y))


def flat_material(cache, rgb):
    key = tuple(rgb)
    if key not in cache:
        material = bpy.data.materials.new("park_" + "_".join(str(c) for c in key))
        material.use_nodes = True
        bsdf = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = (*[srgb_to_linear(c) for c in key], 1.0)
        bsdf.inputs["Roughness"].default_value = 1.0
        for name in ("Specular IOR Level", "Specular"):
            if name in bsdf.inputs:
                bsdf.inputs[name].default_value = 0.0
        cache[key] = material
    return cache[key]


def box_mesh(name, wedge=False):
    mesh = bpy.data.meshes.new(name)
    if wedge:
        vertices = [(-.5, -.5, -.5), (.5, -.5, -.5), (.5, .5, -.5), (-.5, .5, -.5), (-.5, -.5, .5), (.5, -.5, .5)]
        faces = [(0, 3, 2, 1), (0, 1, 5, 4), (3, 4, 5, 2), (0, 4, 3), (1, 2, 5)]
    else:
        vertices = [(-.5, -.5, -.5), (.5, -.5, -.5), (.5, .5, -.5), (-.5, .5, -.5),
                    (-.5, -.5, .5), (.5, -.5, .5), (.5, .5, .5), (-.5, .5, .5)]
        faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    return mesh


def run(params):
    root = params["root"]
    world = json.load(open(os.path.join(root, "art", "render", "world-parkcity.json")))
    out_dir = params["out"]
    os.makedirs(out_dir, exist_ok=True)

    pools = (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras,
             bpy.data.worlds, bpy.data.collections, bpy.data.images)
    existing = [set(pool) for pool in pools]
    previous = bpy.context.window.scene if bpy.context.window else bpy.context.scene
    scene = bpy.data.scenes.new("capture_012")
    if bpy.context.window:
        bpy.context.window.scene = scene
    collection = bpy.data.collections.new("park_world")
    scene.collection.children.link(collection)

    materials = {}
    shared = {"box": box_mesh("park_box"), "wedge": box_mesh("park_wedge", True)}
    for key in ("box", "wedge"):
        shared[key].materials.append(flat_material(materials, (150, 150, 150)))
    count = 0
    for item in world["boxes"]:
        mesh = shared["wedge" if item.get("wedge") else "box"]
        obj = bpy.data.objects.new(item["id"], mesh)
        obj.location = to_blender(item["x"], item["y"], item["z"])
        obj.rotation_euler = (item.get("rx", 0.0), 0.0, item["yaw"])
        obj.scale = (item["sx"], item["sz"], item["sy"])
        obj.data = mesh
        # One material per colour on the object, so the shared mesh can be reused.
        obj.active_material_index = 0
        obj.material_slots  # noqa: B018 (slots exist from the mesh)
        obj.material_slots[0].link = "OBJECT"
        obj.material_slots[0].material = flat_material(materials, item["rgb"])
        collection.objects.link(obj)
        count += 1

    sun_data = bpy.data.lights.new("park_sun", "SUN")
    sun_data.energy = SUN_STRENGTH
    sun_data.color = SUN_COLOUR
    sun_data.angle = math.radians(2.0)
    sun = bpy.data.objects.new("park_sun", sun_data)
    sun.rotation_euler = (math.radians(90 - SUN_ELEVATION), 0, math.radians(SUN_AZIMUTH))
    scene.collection.objects.link(sun)

    sky = bpy.data.worlds.new("park_sky")
    sky.use_nodes = True
    background = next(n for n in sky.node_tree.nodes if n.type == "BACKGROUND")
    background.inputs["Color"].default_value = (*[srgb_to_linear(c) for c in SKY], 1.0)
    background.inputs["Strength"].default_value = 1.0
    scene.world = sky

    camera_data = bpy.data.cameras.new("park_cam")
    camera = bpy.data.objects.new("park_cam", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera

    scene.render.resolution_x, scene.render.resolution_y = RESOLUTION
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"
    engine = "BLENDER_EEVEE"
    try:
        scene.render.engine = engine
    except TypeError:
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.color_type = "MATERIAL"
        engine = "BLENDER_WORKBENCH"
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 16

    images = []
    for shot in world["shots"]:
        position = to_blender(*shot["position"])
        target = to_blender(*shot["lookAt"])
        camera.location = position
        camera.rotation_euler = (target - position).to_track_quat("-Z", "Y").to_euler()
        camera.data.sensor_fit = "VERTICAL"
        camera.data.angle = math.radians(shot["fov"])
        camera.data.clip_start = 0.2
        camera.data.clip_end = 6000.0
        file_name = shot["name"] + ".png"
        scene.render.filepath = os.path.join(out_dir, file_name)
        bpy.ops.render.render(write_still=True, scene=scene.name)
        digest = hashlib.sha256(open(scene.render.filepath, "rb").read()).hexdigest()
        images.append({"name": shot["name"], "file": file_name, "source": "blender-offline", "sha256": digest,
                       "position": shot["position"], "lookAt": shot["lookAt"]})

    manifest = {
        "generated": date.today().isoformat(),
        "blender": bpy.app.version_string,
        "engine": engine,
        "worldCommit": params.get("commit", ""),
        "objects": count,
        "images": images,
        "parityNotes": PARITY_NOTES,
    }
    with open(os.path.join(out_dir, "shots-manifest.json"), "w") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")

    if bpy.context.window:
        bpy.context.window.scene = previous
    bpy.data.scenes.remove(scene)
    for pool, kept in zip(pools, existing):
        for entry in list(pool):
            if entry not in kept:
                pool.remove(entry)
    print(json.dumps({"objects": count, "engine": engine, "images": len(images)}))
