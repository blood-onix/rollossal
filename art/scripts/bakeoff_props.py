# Bake-off Source 1 (specs/009-style-bible-bakeoff/bakeoff/README.md): the five props rebuilt in Blender to the style
# bible's triangle floors and targets, plus the neutral small-street stage and the two fixed cameras. Run through the
# Blender MCP (execute_blender_code), never from the shell:
#
#   ROOT = "<repo root>"
#   exec(open(ROOT + "/art/scripts/bakeoff_props.py").read())
#   report = build_and_render(ROOT, "source1", "<out dir>")
#
# Everything is built from boxes, hulls, cylinders and ico-spheres with one 1-segment silhouette bevel, UV'd into
# the `city` atlas cell of its role (art/palette.json), one material. Nothing is written under art/export or
# art/atlases and nothing is added to the manifest (plan D3).

import json
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

SUN_COLOUR = (1.0, 0.93, 0.80)
SUN_STRENGTH = 3.2
SUN_ELEVATION = 58.0
SUN_AZIMUTH = 215.0
SKY = (143, 208, 255)

# Longest side in studs (Downtown.luau) and the tier whose camera distance the game view uses.
PROPS = {
    "hatchback": {"size": 14.0, "tier": 4, "where": "road"},
    "shop_front": {"size": 22.0, "tier": 5, "where": "back"},
    "bench": {"size": 7.0, "tier": 3, "where": "walk"},
    "street_tree": {"size": 9.0, "tier": 3, "where": "walk"},
    "fire_hydrant": {"size": 2.4, "tier": 2, "where": "walk"},
}
# Floor and target triangles by tier (style bible section 4).
TIER_BAND = {2: (210, 385), 3: (450, 825), 4: (1050, 1925), 5: (1500, 2750)}


def srgb_to_linear(value):
    value = value / 255.0
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


class Builder:
    """Collects parts into one bmesh; each part carries its atlas role in material_index until UVs are set."""

    def __init__(self, palette):
        self.palette = palette
        self.roles = []
        self.bm = bmesh.new()

    def _role(self, name):
        if name not in self.roles:
            self.roles.append(name)
        return self.roles.index(name)

    def _merge(self, part, role, bevel):
        if bevel > 0:
            bmesh.ops.dissolve_limit(part, angle_limit=0.01, verts=list(part.verts), edges=list(part.edges))
            bmesh.ops.bevel(part, geom=list(part.edges), offset=bevel, offset_type="OFFSET", segments=1, affect="EDGES")
        index = self._role(role)
        for face in part.faces:
            face.material_index = index
        mesh = bpy.data.meshes.new("part")
        part.to_mesh(mesh)
        part.free()
        self.bm.from_mesh(mesh)
        bpy.data.meshes.remove(mesh)

    def box(self, centre, size, role, bevel=0.0, yaw=0.0):
        part = bmesh.new()
        bmesh.ops.create_cube(part, size=1.0)
        bmesh.ops.scale(part, vec=Vector(size), verts=list(part.verts))
        self._place(part, centre, yaw)
        self._merge(part, role, min(bevel, 0.4 * min(size)) if bevel else 0.0)

    def hull(self, points, role, bevel=0.0):
        part = bmesh.new()
        for p in points:
            part.verts.new(Vector(p))
        bmesh.ops.convex_hull(part, input=list(part.verts))
        for v in [v for v in part.verts if not v.link_faces]:
            part.verts.remove(v)
        self._merge(part, role, bevel)

    def cyl(self, centre, r1, depth, role, segments=12, r2=None, axis="z", bevel=0.0):
        part = bmesh.new()
        bmesh.ops.create_cone(part, cap_ends=True, cap_tris=False, segments=segments, radius1=r1,
                              radius2=r1 if r2 is None else r2, depth=depth)
        if axis == "x":
            bmesh.ops.rotate(part, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "Y"), verts=list(part.verts))
        elif axis == "y":
            bmesh.ops.rotate(part, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "X"), verts=list(part.verts))
        self._place(part, centre, 0.0)
        self._merge(part, role, bevel)

    def sphere(self, centre, radius, role, subdivisions=1, squash=(1, 1, 1)):
        part = bmesh.new()
        bmesh.ops.create_icosphere(part, subdivisions=subdivisions, radius=radius)
        bmesh.ops.scale(part, vec=Vector(squash), verts=list(part.verts))
        self._place(part, centre, 0.0)
        self._merge(part, role, 0.0)

    @staticmethod
    def _place(part, centre, yaw):
        if yaw:
            bmesh.ops.rotate(part, cent=(0, 0, 0), matrix=Matrix.Rotation(yaw, 3, "Z"), verts=list(part.verts))
        bmesh.ops.translate(part, vec=Vector(centre), verts=list(part.verts))

    def finish(self, name, size, atlas):
        """UVs every face to its role cell, normalises the longest side to `size`, sits the base on z=0."""
        mesh = bpy.data.meshes.new(name)
        bmesh.ops.remove_doubles(self.bm, verts=list(self.bm.verts), dist=1e-5)
        uv = self.bm.loops.layers.uv.new("UVMap")
        for face in self.bm.faces:
            cell = self.palette["cells"][self.roles[face.material_index]]
            for loop in face.loops:
                loop[uv].uv = ((cell["u0"] + cell["u1"]) / 2, (cell["v0"] + cell["v1"]) / 2)
            face.material_index = 0
        self.bm.to_mesh(mesh)
        self.bm.free()
        mesh.materials.append(atlas)
        lo = Vector([min(v.co[i] for v in mesh.vertices) for i in range(3)])
        hi = Vector([max(v.co[i] for v in mesh.vertices) for i in range(3)])
        scale = size / max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
        mesh.transform(Matrix.Translation(Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))))
        mesh.transform(Matrix.Scale(scale, 4))
        obj = bpy.data.objects.new(name, mesh)
        return obj


def triangle_count(obj):
    mesh = obj.data
    return sum(len(p.vertices) - 2 for p in mesh.polygons)


def panel(b, quad, offset, role, bevel=0.0):
    """A thin slab: the four corners of `quad` pushed by `offset` into eight points (a flat hull has no volume)."""
    points = [tuple(q) for q in quad] + [tuple(c + o for c, o in zip(q, offset)) for q in quad]
    b.hull(points, role, bevel)


def wheel(b, x, y, z, radius, width):
    b.cyl((x, y, z), radius, width, "w-rubber", 20, axis="y")
    b.cyl((x, y + math.copysign(width * 0.52, y), z), radius * 0.55, 0.06, "w-metal", 12, axis="y")
    b.cyl((x, y + math.copysign(width * 0.56, y), z), radius * 0.18, 0.06, "w-metal-dark", 8, axis="y")


def build_hatchback(b):
    b.box((0, 0, 0.85), (4.2, 1.9, 0.8), "w-accent-blue", 0.12)  # lower body
    b.hull([(-1.9, -0.82, 1.25), (1.2, -0.82, 1.25), (0.7, -0.78, 1.95), (-1.5, -0.78, 1.95),
            (-1.9, 0.82, 1.25), (1.2, 0.82, 1.25), (0.7, 0.78, 1.95), (-1.5, 0.78, 1.95)], "w-accent-blue", 0.07)  # cabin
    for side in (-1, 1):
        panel(b, [(-1.3, side * 0.84, 1.3), (0.9, side * 0.84, 1.3), (0.55, side * 0.80, 1.85), (-1.2, side * 0.80, 1.85)],
              (0, side * 0.04, 0), "w-glass")  # side glass
        for x in (-0.9, -0.2, 0.45):
            b.box((x, side * 0.96, 0.95), (0.05, 0.03, 0.5), "w-metal-dark")  # door seams
        b.box((0.0, side * 1.0, 1.1), (0.25, 0.06, 0.05), "w-metal")  # door handle
        b.box((0.9, side * 1.0, 1.35), (0.22, 0.2, 0.14), "w-accent-blue", 0.03)  # mirror
        b.box((1.95, side * 0.62, 1.0), (0.12, 0.38, 0.2), "w-glow", 0.03)  # headlight
        b.box((-2.12, side * 0.7, 1.05), (0.1, 0.3, 0.2), "w-accent-red", 0.03)  # tail light
        b.box((1.8, side * 0.45, 0.62), (0.3, 0.14, 0.14), "w-glow")  # fog light
        b.box((-0.2, side * 0.98, 0.5), (3.0, 0.06, 0.12), "w-metal-dark")  # sill
        b.box((0.0, side * 0.4, 2.0), (2.4, 0.06, 0.05), "w-metal")  # roof rail
    panel(b, [(1.2, -0.7, 1.28), (2.0, -0.7, 1.12), (2.0, 0.7, 1.12), (1.2, 0.7, 1.28)], (0, 0, 0.05), "w-accent-blue")  # bonnet
    panel(b, [(1.12, -0.74, 1.28), (0.72, -0.74, 1.93), (0.72, 0.74, 1.93), (1.12, 0.74, 1.28)], (0.04, 0, 0), "w-glass")  # screen
    panel(b, [(-1.5, -0.74, 1.93), (-1.9, -0.74, 1.3), (-1.9, 0.74, 1.3), (-1.5, 0.74, 1.93)], (-0.04, 0, 0), "w-glass")  # tailgate
    b.box((2.12, 0, 0.55), (0.35, 1.9, 0.22), "w-metal-dark", 0.06)  # front bumper
    b.box((-2.14, 0, 0.55), (0.3, 1.9, 0.22), "w-metal-dark", 0.06)  # rear bumper
    b.box((2.1, 0, 0.9), (0.06, 0.7, 0.28), "w-metal-dark")  # grille
    for k in range(3):
        b.box((2.14, 0, 0.8 + k * 0.1), (0.03, 0.62, 0.03), "w-metal")
    b.box((-2.16, 0, 0.9), (0.04, 0.45, 0.16), "w-white")  # plate
    b.box((-1.9, 0, 1.4), (0.2, 0.3, 0.05), "w-metal-dark")  # spoiler lip
    b.cyl((-2.1, 0.6, 0.38), 0.07, 0.25, "w-metal", 8, axis="x")  # exhaust
    b.box((-0.2, 0, 2.0), (1.2, 0.7, 0.04), "w-glass")  # roof glass
    for x in (-1.3, 1.3):
        for y in (-1.02, 1.02):
            wheel(b, x, y, 0.45, 0.45, 0.35)
        for y in (-0.93, 0.93):
            b.box((x, y, 0.95), (1.1, 0.1, 0.1), "w-metal-dark")  # arch lip


def build_shop_front(b):
    W, D, H = 22.0, 14.0, 11.0
    b.box((0, 0, H / 2), (W, D, H), "w-wall-b", 0.25)  # shell
    b.box((0, 0, H + 0.3), (W + 0.6, D + 0.6, 0.6), "w-roof-a", 0.1)  # parapet cap
    b.box((0, -D / 2 - 0.2, 3.3), (W, 0.4, 0.5), "w-trim")  # fascia band
    b.box((0, -D / 2 - 0.3, 3.85), (9.0, 0.3, 1.0), "w-accent-yellow", 0.06)  # sign board
    for k in range(7):  # sign lettering blocks (invented name, kept abstract here)
        b.box((-3.6 + k * 1.2, -D / 2 - 0.5, 3.85), (0.7, 0.1, 0.55), "w-trim")
    b.box((-W / 2 + 0.2, -D / 2 - 0.1, H / 2), (0.5, 0.5, H), "w-trim", 0.08)  # corner pilasters
    b.box((W / 2 - 0.2, -D / 2 - 0.1, H / 2), (0.5, 0.5, H), "w-trim", 0.08)
    for k in range(5):  # awning stripes
        col = "w-accent-red" if k % 2 == 0 else "w-white"
        x = -8.0 + k * 3.2
        b.hull([(x - 1.6, -D / 2, 3.2), (x + 1.6, -D / 2, 3.2), (x - 1.6, -D / 2 - 2.2, 2.7),
                (x + 1.6, -D / 2 - 2.2, 2.7), (x - 1.6, -D / 2 - 2.2, 2.4), (x + 1.6, -D / 2 - 2.2, 2.4)], col, 0.04)
    for k in range(3):  # shop windows
        x = -7.0 + k * 4.6
        b.box((x, -D / 2 - 0.1, 1.5), (3.8, 0.2, 2.4), "w-glass", 0.05)
        b.box((x, -D / 2 - 0.2, 0.25), (4.2, 0.4, 0.5), "w-wall-c")  # stall riser
        for m in range(2):
            b.box((x - 1.9 + m * 3.8, -D / 2 - 0.2, 1.5), (0.18, 0.2, 2.5), "w-trim")  # mullion
    b.box((6.8, -D / 2 - 0.1, 1.4), (2.0, 0.25, 2.8), "w-door")  # door
    b.box((6.8, -D / 2 - 0.2, 1.3), (1.6, 0.1, 1.6), "w-glass")
    b.box((7.6, -D / 2 - 0.3, 1.3), (0.1, 0.1, 0.4), "w-metal")  # handle
    for floor in range(2):  # upper windows with sills and lintels
        z = 5.6 + floor * 2.7
        for k in range(5):
            x = -8.0 + k * 4.0
            b.box((x, -D / 2 - 0.05, z), (1.8, 0.15, 1.6), "w-glass", 0.04)
            b.box((x, -D / 2 - 0.2, z - 0.95), (2.3, 0.45, 0.2), "w-trim")  # sill
            b.box((x, -D / 2 - 0.15, z + 0.95), (2.1, 0.3, 0.2), "w-trim")  # lintel
            b.box((x, -D / 2 - 0.12, z), (0.1, 0.18, 1.7), "w-trim")  # window bar
    for side in (-1, 1):
        for k in range(3):  # side windows
            b.box((side * (W / 2 + 0.05), -3.0 + k * 3.5, 6.2), (0.15, 1.5, 1.6), "w-glass", 0.04)
    b.box((7.5, 3.0, H + 1.4), (1.2, 1.2, 2.2), "w-wall-c", 0.1)  # chimney
    b.box((7.5, 3.0, H + 2.6), (1.5, 1.5, 0.25), "w-trim", 0.05)
    b.box((-6.0, 2.0, H + 0.95), (2.6, 2.0, 1.1), "w-metal", 0.08)  # rooftop unit
    b.cyl((-6.0, 2.0, H + 1.7), 0.7, 0.2, "w-metal-dark", 12)
    b.box((0, -D / 2 - 0.5, 0.15), (W + 0.4, 1.2, 0.3), "w-sidewalk", 0.05)  # step apron


def build_bench(b):
    for k in range(5):  # seat slats
        b.box((0, -0.45 + k * 0.22, 0.85), (3.2, 0.18, 0.1), "w-wood", 0.025)
    for k in range(4):  # back slats
        b.box((0, 0.55, 1.15 + k * 0.28), (3.2, 0.1, 0.2), "w-wood", 0.025)
    for x in (-1.45, 1.45):
        b.box((x, 0, 0.42), (0.14, 1.1, 0.14), "w-metal-dark")  # leg bar
        for y in (-0.5, 0.5):
            b.box((x, y, 0.4), (0.14, 0.14, 0.8), "w-metal-dark")  # leg
        b.box((x, 0.55, 1.2), (0.14, 0.14, 1.0), "w-metal-dark")  # back post
        b.box((x, -0.05, 1.05), (0.16, 1.2, 0.1), "w-metal")  # armrest
        b.box((x, -0.55, 0.95), (0.16, 0.1, 0.25), "w-metal")  # armrest support
    b.box((0, 0.5, 0.78), (3.0, 0.1, 0.1), "w-metal-dark")  # rear rail
    b.box((0, -0.5, 0.78), (3.0, 0.1, 0.1), "w-metal-dark")  # front rail


def build_street_tree(b):
    b.box((0, 0, 0.15), (1.8, 1.8, 0.3), "w-kerb", 0.05)  # tree pit kerb
    b.cyl((0, 0, 0.35), 0.5, 0.2, "w-soil", 10)  # soil
    b.cyl((0, 0, 1.9), 0.22, 3.2, "w-bark", 8, r2=0.15)  # trunk
    b.cyl((0, 0, 0.5), 0.34, 0.3, "w-bark", 8, r2=0.22)  # root flare
    for dx, dy in ((0.5, 0.3), (-0.45, -0.3), (0.0, -0.5)):
        b.cyl((dx * 0.8, dy * 0.8, 3.6), 0.06, 1.0, "w-bark", 6, r2=0.04)  # branches
    b.sphere((0, 0, 5.4), 1.9, "w-leaf", 2, (1, 1, 0.85))
    b.sphere((1.2, 0.5, 4.5), 1.3, "w-leaf-dark", 2)
    b.sphere((-1.1, -0.5, 4.7), 1.15, "w-leaf", 1)
    b.sphere((0.2, -1.2, 4.3), 0.9, "w-leaf-dark", 1)
    b.sphere((-0.6, 1.1, 5.0), 0.9, "w-leaf", 1)
    b.sphere((0.9, -0.6, 6.0), 0.8, "w-leaf-dark", 1)
    b.sphere((-1.0, 0.9, 6.0), 0.8, "w-leaf", 1)


def build_fire_hydrant(b):
    b.cyl((0, 0, 0.08), 0.42, 0.16, "w-metal-dark", 10)  # base plate
    b.cyl((0, 0, 0.5), 0.3, 0.7, "w-accent-red", 10)  # barrel
    b.cyl((0, 0, 0.88), 0.34, 0.1, "w-accent-red", 10)  # collar
    b.cyl((0, 0, 1.08), 0.3, 0.3, "w-accent-red", 10, r2=0.12)  # dome as a cone, cheaper than a sphere
    b.cyl((0, 0, 1.28), 0.08, 0.14, "w-metal", 8)  # top nut
    for sign in (-1, 1):
        b.cyl((sign * 0.38, 0, 0.62), 0.13, 0.26, "w-accent-red", 8, axis="x")  # side nozzle
        b.cyl((sign * 0.52, 0, 0.62), 0.1, 0.06, "w-metal", 6, axis="x")  # cap
    b.cyl((0, -0.36, 0.52), 0.15, 0.2, "w-accent-red", 8, axis="y")  # front nozzle
    b.cyl((0, -0.48, 0.52), 0.1, 0.06, "w-metal", 6, axis="y")
    for k in range(4):  # base bolts
        a = math.pi / 2 * k + math.pi / 4
        b.box((0.34 * math.cos(a), 0.34 * math.sin(a), 0.19), (0.07, 0.07, 0.06), "w-metal")


BUILDERS = {
    "hatchback": build_hatchback,
    "shop_front": build_shop_front,
    "bench": build_bench,
    "street_tree": build_street_tree,
    "fire_hydrant": build_fire_hydrant,
}


def atlas_material(path):
    material = bpy.data.materials.new("bakeoff_atlas")
    material.use_nodes = True
    tree = material.node_tree
    bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
    image = bpy.data.images.load(path)
    texture = tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    tree.links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 1.0
    for name in ("Specular IOR Level", "Specular"):
        if name in bsdf.inputs:
            bsdf.inputs[name].default_value = 0.0
    return material


def flat_material(name, rgb):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*[srgb_to_linear(c) for c in rgb], 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    for name_ in ("Specular IOR Level", "Specular"):
        if name_ in bsdf.inputs:
            bsdf.inputs[name_].default_value = 0.0
    return material


def slab(scene_collection, name, centre, size, material):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=list(bm.verts))
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    obj.location = centre
    scene_collection.objects.link(obj)
    return obj


def build_stage(scene):
    """Dark road, pale raised sidewalk and kerb: the small neutral street every candidate is judged on."""
    asphalt = flat_material("stage_asphalt", (60, 66, 82))
    walk = flat_material("stage_sidewalk", (150, 162, 176))
    kerb = flat_material("stage_kerb", (110, 120, 134))
    line = flat_material("stage_line", (240, 200, 70))
    c = scene.collection
    slab(c, "ground", (0, 0, -0.5), (1400, 1400, 1.0), asphalt)
    slab(c, "road_line", (0, 0, 0.01), (1400, 0.3, 0.02), line)
    for side, sign in (("n", 1), ("s", -1)):
        slab(c, "walk_" + side, (0, sign * 105.0, 0.2), (1400, 190, 0.4), walk)
        slab(c, "kerb_" + side, (0, sign * 10.3, 0.2), (1400, 0.6, 0.44), kerb)


def place_camera(scene, camera, target, distance, yaw_deg, pitch_deg, fov=70.0):
    yaw, pitch = math.radians(yaw_deg), math.radians(pitch_deg)
    offset = Vector((math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch))) * distance
    camera.location = target + offset
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.sensor_fit = "VERTICAL"
    camera.data.angle = math.radians(fov)
    camera.data.clip_start = 0.1
    camera.data.clip_end = 5000.0


def build_and_render(root, tag, out_dir, only=None, resolution=(960, 540), meshes=None):
    """Builds (or takes `meshes`: name -> object) and renders every prop with both cameras into out_dir."""
    palette = json.load(open(os.path.join(root, "art", "palette.json")))
    os.makedirs(out_dir, exist_ok=True)
    pools = (bpy.data.objects, bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras,
             bpy.data.worlds, bpy.data.images, bpy.data.scenes)
    existing = [set(p) for p in pools]
    previous = bpy.context.window.scene if bpy.context.window else bpy.context.scene
    scene = bpy.data.scenes.new("bakeoff_009")
    if bpy.context.window:
        bpy.context.window.scene = scene
    atlas = atlas_material(os.path.join(root, "art", "atlases", "city.png"))
    build_stage(scene)

    objects = {}
    report = {}
    for name, spec in PROPS.items():
        if only and name not in only:
            continue
        if meshes is not None:
            obj = meshes[name]
        else:
            builder = Builder(palette)
            BUILDERS[name](builder)
            obj = builder.finish(name, spec["size"], atlas)
        scene.collection.objects.link(obj)
        obj.hide_render = True
        objects[name] = obj
        floor, target = TIER_BAND[spec["tier"]]
        report[name] = {"triangles": triangle_count(obj), "tier": spec["tier"], "floor": floor, "target": target,
                        "size": spec["size"]}

    sun_data = bpy.data.lights.new("sun", "SUN")
    sun_data.energy, sun_data.color, sun_data.angle = SUN_STRENGTH, SUN_COLOUR, math.radians(2.0)
    sun = bpy.data.objects.new("sun", sun_data)
    sun.rotation_euler = (math.radians(90 - SUN_ELEVATION), 0, math.radians(SUN_AZIMUTH))
    scene.collection.objects.link(sun)
    sky = bpy.data.worlds.new("sky")
    sky.use_nodes = True
    next(n for n in sky.node_tree.nodes if n.type == "BACKGROUND").inputs["Color"].default_value = (
        *[srgb_to_linear(c) for c in SKY], 1.0)
    scene.world = sky
    camera = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 16

    for name, obj in objects.items():
        spec = PROPS[name]
        obj.hide_render = False
        y = {"road": 0.0, "walk": 20.0, "back": 30.0}[spec["where"]]
        obj.location = (0, y, 0.4 if spec["where"] != "road" else 0.0)
        obj.rotation_euler = (0, 0, 0)
        bpy.context.view_layer.update()
        height = spec["size"]
        target = Vector((0, y, 0.4 + height * 0.35 if spec["where"] != "road" else height * 0.12))
        # 3/4 view at 2 x the longest side; game view at the in-game camera distance for the tier that eats it.
        ball = spec["size"] / 0.4
        game_distance = min(320.0, max(8.0, 4.0 * ball))
        for view, distance, yaw, pitch in (("3q", spec["size"] * 1.9, -35.0, 22.0), ("game", game_distance, 0.0, 32.0)):
            place_camera(scene, camera, target, distance, yaw, pitch)
            scene.render.filepath = os.path.join(out_dir, "%s_%s_%s.png" % (tag, name, view))
            bpy.ops.render.render(write_still=True, scene=scene.name)
        report[name]["render3q"] = "%s_%s_3q.png" % (tag, name)
        report[name]["renderGame"] = "%s_%s_game.png" % (tag, name)
        report[name]["gameDistance"] = game_distance
        obj.hide_render = True

    if bpy.context.window:
        bpy.context.window.scene = previous
    bpy.data.scenes.remove(scene)
    kept = set(objects.values()) if meshes is not None else set()
    for pool, was in zip(pools, existing):
        for item in list(pool):
            if item not in was and item not in kept:
                try:
                    pool.remove(item)
                except Exception:
                    pass
    return report
