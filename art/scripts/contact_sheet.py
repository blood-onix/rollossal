# Contact sheets (013; plan strand 7): one image per zone and theme, a grid of single meshes with an id and triangle
# caption under each. Meshes are loaded from the art/source/*.blend collections (one collection per id), scaled to fit
# a cell (the caption also shows the true longest side in studs), textured with the theme atlas and rendered once with
# the Workbench engine. Run through the Blender MCP (execute_blender_code):
#   PARAMS = {"root": "<repo root>", "jobs": [{"name": "audit", "theme": "city", "ids": ["dt_bench"], "out": "<png>"}]}
#   exec(open(PARAMS["root"] + "/art/scripts/contact_sheet.py").read()); run(PARAMS)
# Optional per job: "columns" (default 9), "rotate" (degrees about z, to turn the +y face toward the camera). Shop buildings, billboards and the buffering billboard (ObjectDef.atlas =
# "fronts") are textured with art/atlases/fronts/<theme>.png, every other mesh with the theme atlas.
# Which .blend holds an id is found by scanning art/source. The run replaces the open file in the claimed Blender.

import glob
import math
import os

import bpy
from mathutils import Vector

CELL = 3.0
ROW = 4.7  # row pitch: tall meshes stand up into the row behind in the three-quarter view
FIT = 2.4
ROOT = None
PX_PER_CELL = 260


def art_dir():
    return os.path.join(ROOT, "art")


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


def tri_count(obj):
    return sum(max(1, len(p.vertices) - 2) for p in obj.data.polygons)


def is_fronts(object_id):
    return (object_id.startswith("ck_shop_") or object_id.startswith("ck_billboard_")
            or object_id == "ck_meme_buffering_billboard")


def atlas_image(theme, fronts):
    name = os.path.join("atlases", "fronts", theme + ".png") if fronts else os.path.join("atlases", theme + ".png")
    return bpy.data.images.load(os.path.join(art_dir(), name), check_existing=True)


def make_text(body, location, material):
    curve = bpy.data.curves.new("cap", type="FONT")
    curve.body = body
    curve.size = 0.3
    curve.align_x = "CENTER"
    obj = bpy.data.objects.new("cap", curve)
    obj.location = location
    obj.data.materials.append(material)
    bpy.context.scene.collection.objects.link(obj)


def sheet(job, where):
    bpy.ops.wm.read_homefile(use_empty=True)
    scene = bpy.context.scene
    ids = job["ids"]
    columns = job.get("columns", 9)
    rows = math.ceil(len(ids) / columns)
    ink = bpy.data.materials.new("ink")
    ink.diffuse_color = (0.05, 0.05, 0.08, 1.0)
    objects = []
    for index, object_id in enumerate(ids):
        obj = load_mesh(object_id, where[object_id])
        scene.collection.objects.link(obj)
        for mat in obj.data.materials:
            if mat and mat.node_tree:
                for node in mat.node_tree.nodes:
                    if node.type == "TEX_IMAGE":
                        node.image = atlas_image(job["theme"], is_fronts(object_id))
                        node.interpolation = "Closest"
        corners = [Vector(c) for c in obj.bound_box]
        longest = max(max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3))
        scale = FIT / longest
        col, row = index % columns, index // columns
        cx, cy = col * CELL, -row * ROW
        obj.scale = (scale, scale, scale)
        obj.rotation_euler = (0, 0, math.radians(job.get("rotate", 0)))
        obj.location = (cx, cy, 0)
        make_text(f"{object_id.replace('dt_', '').replace('ck_', '')}", (cx, cy - 1.5, 0.01), ink)
        make_text(f"{tri_count(obj)} tris  {longest:.1f} st", (cx, cy - 1.95, 0.01), ink)
        objects.append(obj)
    width = columns * CELL
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "TEXTURE"
    shading.show_cavity = True
    shading.background_type = "WORLD"
    world = bpy.data.worlds.new("BG")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.78, 0.82, 0.88, 1.0)
    world.color = (0.80, 0.84, 0.90)  # the Workbench background reads world.color, not the node tree
    scene.world = world
    scene.view_settings.view_transform = "Standard"
    elevation = math.radians(52)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = width * 1.01
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    centre = Vector(((columns - 1) * CELL / 2, -(rows - 1) * ROW / 2 - 0.9, 1.0))
    cam.location = centre + Vector((0, -math.cos(elevation), math.sin(elevation))) * 80
    cam.rotation_euler = (math.pi / 2 - elevation, 0, 0)
    scene.camera = cam
    scene.render.resolution_x = int(columns * PX_PER_CELL)
    per_unit = scene.render.resolution_x / cam_data.ortho_scale
    scene.render.resolution_y = int(((rows * ROW) * math.sin(elevation) + 2.6) * per_unit)
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    os.makedirs(os.path.dirname(job["out"]), exist_ok=True)
    scene.render.filepath = job["out"]
    bpy.ops.render.render(write_still=True)
    print(f"contact_sheet: wrote {job['out']} ({len(ids)} meshes)")


def run(params):
    global ROOT
    ROOT = params["root"]
    bpy.ops.wm.read_homefile(use_empty=True)  # a source file open in Blender cannot be loaded from
    where = index_sources()
    for job in params["jobs"]:
        missing = [i for i in job["ids"] if i not in where]
        if missing:
            raise RuntimeError(f"{job['name']}: ids with no collection in art/source: {missing}")
        sheet(job, where)
    print("contact_sheet: OK")
