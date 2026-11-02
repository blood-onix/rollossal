# Offline capture renderer (specs/009-style-bible-bakeoff/contracts/capture-route.md).
# Draws the five fixed shots of art/capture/cameras.json from the world JSON written by
# scripts/capture-export.luau, using art/export/*.fbx and the theme atlas. Run through the Blender MCP
# (execute_blender_code), never from the shell:
#
#   PARAMS = {"root": "<repo root>", "world": "art/render/world-city.json", "out": "<dir>", "commit": "<sha>"}
#   exec(open(PARAMS["root"] + "/art/scripts/capture_render.py").read()); run(PARAMS)
#
# Roblox (x east, y up, z south) maps to Blender (x, -z, y): a proper rotation, so yaw about Roblox +Y is the same
# angle about Blender +Z, and it is the inverse of the FBX export axes (forward -Z, up Y) used by export_all.py.
# No random, fixed sample count; one 1280x720 PNG per shot. Does not write under art/export or art/atlases.

import hashlib
import json
import math
import os
from datetime import date

import bpy
from mathutils import Matrix, Vector

SUN_COLOUR = (1.0, 0.93, 0.80)
SUN_STRENGTH = 3.2
SUN_ELEVATION = 58.0
SUN_AZIMUTH = 215.0
SKY = (143, 208, 255)

PARITY_NOTES = [
    "Offline Blender (EEVEE) composition check, not a pixel match: Roblox tone mapping, bloom, atmosphere, fog and "
    "shadow filtering are not reproduced.",
    "Mesh scale follows ObjectVisual.buildMesh (longest side = object size); objects without an FBX are drawn as "
    "their fallback primitive in grey.",
    "Boundary colliders are skipped; sun direction is an approximation of Lighting.ClockTime 13.",
]


def srgb_to_linear(value):
    value = value / 255.0
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def to_blender(x, y, z):
    return Vector((x, -z, y))


def flat_material(cache, rgb):
    key = tuple(rgb)
    if key not in cache:
        material = bpy.data.materials.new("cap_" + "_".join(str(c) for c in key))
        material.use_nodes = True
        bsdf = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = (*[srgb_to_linear(c) for c in key], 1.0)
        bsdf.inputs["Roughness"].default_value = 1.0
        for name in ("Specular IOR Level", "Specular"):
            if name in bsdf.inputs:
                bsdf.inputs[name].default_value = 0.0
        cache[key] = material
    return cache[key]


def atlas_material(path):
    material = bpy.data.materials.new("cap_atlas")
    material.use_nodes = True
    tree = material.node_tree
    bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    image = bpy.data.images.load(path)
    image.colorspace_settings.name = "sRGB"
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Linear"
    tree.links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 1.0
    for name in ("Specular IOR Level", "Specular"):
        if name in bsdf.inputs:
            bsdf.inputs[name].default_value = 0.0
    return material


def box_mesh(name, wedge=False):
    mesh = bpy.data.meshes.new(name)
    # Unit cube centred at the origin, in Blender axes (x, depth, up). The wedge keeps its vertical face at +Roblox Z
    # (-Blender Y) and slopes down toward -Roblox Z.
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


def import_template(root, asset_key, atlas, collection):
    """Imports art/export/<asset_key>.fbx once; returns mesh data with the bbox centred in x/y and sitting on z=0."""
    path = os.path.join(root, "art", "export", asset_key + ".fbx")
    if not os.path.exists(path):
        return None
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=path, axis_forward="-Z", axis_up="Y")
    imported = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in imported if o.type == "MESH"]
    if not meshes:
        for o in imported:
            bpy.data.objects.remove(o, do_unlink=True)
        return None
    for o in imported:
        o.hide_render = True
    target = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.select_all(action="DESELECT")
        for o in meshes:
            o.select_set(True)
        bpy.context.view_layer.objects.active = target
        bpy.ops.object.join()
    mesh = target.data.copy()
    mesh.transform(target.matrix_world)
    corners = [v.co for v in mesh.vertices]
    lo = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    hi = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    mesh.transform(Matrix.Translation(Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))))
    mesh.materials.clear()
    mesh.materials.append(atlas)
    mesh["longest"] = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    for o in imported:
        bpy.data.objects.remove(o, do_unlink=True)
    return mesh


def set_camera(camera, shot, fov):
    position = to_blender(*shot["position"])
    target = to_blender(*shot["lookAt"])
    camera.location = position
    camera.rotation_euler = (target - position).to_track_quat("-Z", "Y").to_euler()
    camera.data.sensor_fit = "VERTICAL"
    camera.data.angle = math.radians(fov)
    camera.data.clip_start = 0.3
    camera.data.clip_end = 6000.0


def run(params):
    root = params["root"]
    world = json.load(open(os.path.join(root, params["world"])))
    cameras = json.load(open(os.path.join(root, "art", "capture", "cameras.json")))
    out_dir = params["out"]
    os.makedirs(out_dir, exist_ok=True)
    theme = world["theme"]

    pools = (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras,
             bpy.data.worlds, bpy.data.collections, bpy.data.images)
    existing = [set(pool) for pool in pools]
    previous = bpy.context.window.scene if bpy.context.window else bpy.context.scene
    scene = bpy.data.scenes.new("capture_009")
    if bpy.context.window:
        bpy.context.window.scene = scene
    collection = bpy.data.collections.new("capture_world")
    scene.collection.children.link(collection)

    atlas = atlas_material(os.path.join(root, "art", "atlases", theme + ".png"))
    flats = {}
    count = 0
    for block in world["blocks"]:
        wedge = block["kind"] == "Wedge"
        mesh = box_mesh("wedge" if wedge else "box", wedge)
        obj = bpy.data.objects.new(block["id"], mesh)
        obj.location = to_blender(block["x"], block["y"], block["z"])
        obj.rotation_euler = (0, 0, block["yaw"])
        obj.scale = (block["sx"], block["sz"], block["sy"])
        mesh.materials.append(flat_material(flats, block["rgb"]))
        collection.objects.link(obj)
        count += 1

    templates = {}
    missing = {}
    grey = flat_material(flats, (150, 150, 150))
    primitives = {}
    for placement in world["placements"]:
        key = placement["assetKey"]
        if key not in templates:
            templates[key] = import_template(root, key, atlas, collection)
        template = templates[key]
        size = placement["size"]
        if template is not None:
            scale = size / template["longest"]
            obj = bpy.data.objects.new(placement["id"], template)
            obj.scale = (scale, scale, scale)
            height = 0.0
        else:
            missing[key] = missing.get(key, 0) + 1
            if "box" not in primitives:
                primitives["box"] = box_mesh("fallback_box")
                primitives["box"].materials.append(grey)
            obj = bpy.data.objects.new(placement["id"], primitives["box"])
            obj.scale = (size, size, size)
            height = size / 2
        obj.location = to_blender(placement["x"], placement["y"], placement["z"]) + Vector((0, 0, height))
        obj.rotation_euler = (0, 0, placement["yaw"])
        collection.objects.link(obj)
        count += 1

    sun_data = bpy.data.lights.new("cap_sun", "SUN")
    sun_data.energy = SUN_STRENGTH
    sun_data.color = SUN_COLOUR
    sun_data.angle = math.radians(2.0)
    sun = bpy.data.objects.new("cap_sun", sun_data)
    sun.rotation_euler = (math.radians(90 - SUN_ELEVATION), 0, math.radians(SUN_AZIMUTH))
    scene.collection.objects.link(sun)

    sky = bpy.data.worlds.new("cap_sky")
    sky.use_nodes = True
    background = next(n for n in sky.node_tree.nodes if n.type == "BACKGROUND")
    background.inputs["Color"].default_value = (*[srgb_to_linear(c) for c in SKY], 1.0)
    background.inputs["Strength"].default_value = 1.0
    scene.world = sky

    camera_data = bpy.data.cameras.new("cap_cam")
    camera = bpy.data.objects.new("cap_cam", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera

    scene.render.resolution_x, scene.render.resolution_y = cameras["resolution"]
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
    for shot in cameras["shots"]:
        set_camera(camera, shot, cameras["fov"])
        file_name = shot["name"] + ".png"
        scene.render.filepath = os.path.join(out_dir, file_name)
        bpy.ops.render.render(write_still=True, scene=scene.name)
        digest = hashlib.sha256(open(scene.render.filepath, "rb").read()).hexdigest()
        images.append({"name": shot["name"], "file": file_name, "source": "blender-offline", "sha256": digest})

    manifest = {
        "generated": date.today().isoformat(),
        "blender": bpy.app.version_string,
        "engine": engine,
        "worldCommit": params.get("commit", ""),
        "theme": theme,
        "objects": count,
        "missingFbx": missing,
        "images": images,
        "parityNotes": PARITY_NOTES,
    }
    with open(os.path.join(out_dir, "capture-manifest.json"), "w") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")

    if bpy.context.window:
        bpy.context.window.scene = previous
    bpy.data.scenes.remove(scene)
    for pool, kept in zip(pools, existing):
        for item in list(pool):
            if item not in kept:
                pool.remove(item)
    print(json.dumps({"objects": count, "missing": missing, "engine": engine, "images": len(images)}))
