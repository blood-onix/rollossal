# Tween-appeal rework of the city kit (013 Phase 9, owner decision 2026-11-07; plan "Owner decision" R1, style bible
# sections 2, 3, 7, 8, 9). "Stylised real with punch": real proportions at 1 m = 3.2 studs (research R-18), muted
# real-material walls and ground with saturated accents only, smooth round parts, triangles spent where they are seen,
# wear from the atlas, and winter as geometry (snow caps on ledges, sills, ridges, car roofs and rails; icicles).
#
# What the build_objects DSL lacks is added here, on top of the same Builder:
#   bbx  box with a one-segment bevel on all 12 edges (Constitution XI: one bevel segment, silhouettes only)
#   rcy  cylinder or cone, smooth sides, sharp caps
#   usp  UV sphere, smooth
#   lmb  limb: a smooth tapered cylinder from point a to point b (branches, arms)
#   bev  wraps any other part and bevels every edge of its island
#   raw  any polyhedron from vertex and face lists (hip roofs, wedges)
# Smoothing: faces from rcy, usp and lmb are smooth-shaded; an edge between two smooth faces turns sharp above SMOOTH_DEG
# (40 degrees for the pilot and the buildings, 60 for the Stage B props, whose low-segment lobes would read faceted),
# and every edge between a smooth and a flat face is sharp, so caps and boxes stay crisp. The FBX export keeps the split
# normals (build_shared.FBX_MESH_SMOOTH_TYPE).
#
# Authoring units are studs at the final size (the normaliser still rescales so the longest side equals the ObjectDef
# size, which is a few percent at most). Front of every object is +y.
#
# The run replaces only the named collections in their existing art/source/*.blend file (the rest of the file is left as
# it is), then prints per id: triangles, % of the tier ceiling, muted share by surface area. Run through the Blender MCP:
#   PARAMS = {"root": "<repo root>", "only": ["ck_bin_street"]}       # "only" optional (default: every recipe here)
#   exec(open(PARAMS["root"] + "/art/scripts/kit_rework.py").read()); run(PARAMS)

import glob
import json
import math
import os
import sys

ROOT = None
SMOOTH_DEG = 40  # smooth-to-smooth edges above this stay sharp; Stage B props raise it (low-segment foliage)
NATURAL = False  # params "natural": build at authoring scale (sizes come from the recipe), for sizing new recipes
bo = None  # build_objects
kr = None  # kit_recipes

# ---------------------------------------------------------------------------------------------- swatches
WA, WB, WC, ROOF, ROOFB = "w-wall-a", "w-wall-b", "w-wall-c", "w-roof-a", "w-roof-b"
GLS, TRIM, DOOR, MET, MDK, RUB = "w-glass", "w-trim", "w-door", "w-metal", "w-metal-dark", "w-rubber"
WOOD, LEAF, LDK, BARK, WHT = "w-wood", "w-leaf", "w-leaf-dark", "w-bark", "w-white"
WALK, KERB, GRASS, SOIL, ASPH = "w-sidewalk", "w-kerb", "w-grass", "w-soil", "w-asphalt"
RED, YEL, BLU, TEAL, ORG = "w-accent-red", "w-accent-yellow", "w-accent-blue", "w-accent-teal", "w-accent-orange"
GLIT, STAIN, WORN, SLUSH = "w-glass-lit", "w-pavement-stained", "w-paint-worn", "w-road-slush"
CONC, GRAF, SNOW, ICE = "w-concrete", "w-graffiti", "w-snowcap", "w-icicle"
# fronts atlas (shop buildings): facade strips, wear cells, sign cells
FX_BRICK, FX_RENDER, FX_GLASS, FX_SHUT, FX_SHOP, FX_CORN = (
    "fx_brick", "fx_render", "fx_glass", "fx_shutter", "fx_shopglaze", "fx_cornice")
FX_SNOW, FX_LIT = "fx_snowcap", "fx_glasslit"

ACCENT = ("w-accent-", "w-glow", "w-graffiti", "sign_", "bb_")


def is_accent(swatch):
    return swatch.startswith(ACCENT)


# ---------------------------------------------------------------------------------------------- constructors
def bbx(c, d, s, bev=0.12, yaw=0.0):
    return ("bbx", c, d, s, yaw, bev)


def rcy(c, r, h, s, n=16, r2=None, axis="z", yaw=0.0):
    return ("rcy", c, r, h, s, n, r2, axis, yaw)


def usp(c, r, s, sq=(1.0, 1.0, 1.0), seg=14, rings=9):
    return ("usp", c, r, s, sq, seg, rings)


def lmb(a, b, r1, r2, s, n=10):
    return ("lmb", a, b, r1, r2, s, n)


def bev(part, width):
    return ("bev", part, width)


def bx(c, d, s, yaw=0.0):
    return ("box", c, d, s, yaw)


def raw(verts, faces, s):
    """Any closed polyhedron from vertex and face index lists (hip roofs, wedges); flat-shaded."""
    return ("raw", verts, faces, s)


def pg(c, pts, span, s, axis="y", yaw=0.0):
    return ("prism", c, pts, span, s, axis, yaw)


def smo(part):
    """Any part smooth-shaded and UV-mapped as one island (a prism with an arc profile, a torus)."""
    return ("smo", part)


def trs(c, R, r, s, major=16, minor=6, stand=False):
    """Smooth torus (rings, hoops, tyres seen face on); stand=True turns it upright, facing +y."""
    return smo(("torus", c, R, r, s, major, minor, stand))


# ---------------------------------------------------------------------------------------------- builder
def make_builder(bm, tags):
    import bmesh
    from mathutils import Matrix, Vector

    class Rework(bo.Builder):
        def __init__(self):
            super().__init__(bm, tags)
            self.smooth = set()
            self.islands = []  # smooth parts, UV-mapped as one piece so the cell gradient spans the whole part

        def island(self, before):
            return [f for f in self.bm.faces if f not in before]

        def bevel_island(self, before, width, swatch_of):
            faces = self.island(before)
            verts = {v for f in faces for v in f.verts}
            edges = {e for f in faces for e in f.edges}
            bmesh.ops.bevel(self.bm, geom=list(verts) + list(edges), offset=width, offset_type="OFFSET",
                            segments=1, profile=0.5, affect="EDGES", clamp_overlap=True)
            # bevel rebuilds faces: drop dead tags, then give every untagged face of the island the island's swatch
            self.tags[:] = [(f, s) for f, s in self.tags if f.is_valid]
            tagged = {f for f, _ in self.tags}
            for f in self.island(before):
                if f not in tagged:
                    self.tags.append((f, swatch_of))

        def run(self, part):
            kind = part[0]
            before = set(self.bm.faces)
            if kind == "bbx":
                _, c, d, s, yaw, width = part
                self.box(c, d, s, yaw)
                if width > 0:
                    self.bevel_island(before, width, s)
            elif kind == "bev":
                _, inner, width = part
                self.run(inner)
                faces = set(self.island(before))
                swatch = next((s for f, s in self.tags if f in faces), None)
                self.bevel_island(before, width, swatch)
            elif kind == "rcy":
                _, c, r, h, s, n, r2, axis, yaw = part
                self.cyl(c, r, h, s, segments=n, radius_top=r if r2 is None else r2, axis=axis, yaw=yaw)
                self.smooth.update(self.island(before))
                self.islands.append(self.island(before))
            elif kind == "usp":
                _, c, r, s, sq, seg, rings = part
                scale = Matrix.Diagonal((r * sq[0], r * sq[1], r * sq[2], 1.0))
                res = bmesh.ops.create_uvsphere(self.bm, u_segments=seg, v_segments=rings, radius=1.0,
                                                matrix=Matrix.Translation(Vector(c)) @ scale, calc_uvs=False)
                faces = {f for v in res["verts"] for f in v.link_faces}
                self._record(faces, s)
                self.smooth.update(faces)
                self.islands.append(list(faces))
            elif kind == "smo":
                self.run(part[1])
                self.smooth.update(self.island(before))
                self.islands.append(self.island(before))
            elif kind == "raw":
                _, verts, faces, s = part
                vs = [self.bm.verts.new(Vector(v)) for v in verts]
                fs = [self.bm.faces.new([vs[i] for i in f]) for f in faces]
                bmesh.ops.recalc_face_normals(self.bm, faces=fs)
                self._record(fs, s)
            elif kind == "lmb":
                _, a, b, r1, r2, s, n = part
                a, b = Vector(a), Vector(b)
                axis = b - a
                rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
                matrix = Matrix.Translation((a + b) / 2) @ rot
                res = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=n, radius1=r1,
                                            radius2=r2, depth=axis.length, matrix=matrix, calc_uvs=False)
                faces = {f for v in res["verts"] for f in v.link_faces}
                self._record(faces, s)
                self.smooth.update(faces)
                self.islands.append(list(faces))
            else:
                bo.emit(self, part)

        def finish(self):
            smooth = {f for f in self.smooth if f.is_valid}
            for f in self.bm.faces:
                f.smooth = f in smooth
            for e in self.bm.edges:
                linked = e.link_faces
                if len(linked) != 2:
                    e.smooth = False
                    continue
                a, b = linked
                if a.smooth and b.smooth:
                    e.smooth = e.calc_face_angle(0.0) < math.radians(SMOOTH_DEG)
                else:
                    e.smooth = False

    return Rework()


# ---------------------------------------------------------------------------------------------- facade helpers
def on_wall(n, p, u, z, w, d, h, out, s, bevel=0.0):
    """A box on a wall: n = outward axis ('+y', '-y', '+x', '-x'), p = wall plane coordinate, u = position along the wall
    (left to right as seen from outside), out = how far its centre stands proud of the wall plane."""
    sign = 1.0 if n[0] == "+" else -1.0
    if n[1] == "y":
        c = (u * sign, p + sign * out, z)
        dims = (w, d, h)
    else:
        c = (p + sign * out, -u * sign, z)
        dims = (d, w, h)
    return bbx(c, dims, s, bevel) if bevel else bx(c, dims, s)


def window(n, p, u, z, w, h, glass=GLS, frame=TRIM, sill=True, snow=SNOW, mull=0, transom=False, simple=False):
    """Recessed window: jambs, head and sill stand proud of the wall so the glass reads set back; snow on the sill.
    simple: rear faces, glass with a head and a sill only."""
    parts = [on_wall(n, p, u, z, w, 0.1, h, 0.04, glass)]
    if simple:
        return parts + [on_wall(n, p, u, z + h / 2 + 0.15, w + 0.4, 0.3, 0.3, 0.15, frame),
                        on_wall(n, p, u, z - h / 2 - 0.14, w + 0.6, 0.6, 0.28, 0.3, frame),
                        on_wall(n, p, u, z - h / 2 + 0.05, w + 0.4, 0.48, 0.12, 0.32, snow)]
    j = max(0.22, w * 0.09)
    parts += [on_wall(n, p, u - w / 2 - j / 2, z, j, 0.32, h + j * 2, 0.16, frame),
              on_wall(n, p, u + w / 2 + j / 2, z, j, 0.32, h + j * 2, 0.16, frame),
              on_wall(n, p, u, z + h / 2 + j / 2, w, 0.32, j, 0.16, frame)]
    if sill:
        parts.append(on_wall(n, p, u, z - h / 2 - 0.14, w + j * 2 + 0.3, 0.62, 0.28, 0.31, frame))
        parts.append(on_wall(n, p, u, z - h / 2 + 0.05, w + j * 2 + 0.1, 0.5, 0.12, 0.33, snow))
    else:
        parts.append(on_wall(n, p, u, z - h / 2 - j / 2, w, 0.32, j, 0.16, frame))
    for k in range(mull):
        parts.append(on_wall(n, p, u - w / 2 + w * (k + 1) / (mull + 1), z, 0.14, 0.18, h, 0.1, frame))
    if transom:
        parts.append(on_wall(n, p, u, z + h * 0.22, w, 0.18, 0.14, 0.1, frame))
    return parts


def drainpipe(x, y, z0, z1, s=MDK):
    return [rcy((x, y, (z0 + z1) / 2), 0.17, z1 - z0, s, 8),
            rcy((x, y, z1 - 0.2), 0.3, 0.4, s, 8, r2=0.17),
            rcy((x, y, z0 + 0.15), 0.24, 0.3, s, 8)]


def icicles(x0, x1, y, z, n, s=ICE):
    out = []
    for k in range(n):
        x = x0 + (x1 - x0) * (k + 0.5) / n
        length = 0.55 + 0.45 * ((k * 7) % 5) / 4
        out.append(rcy((x, y, z - length / 2), 0.11, length, s, 6, r2=0.0))
    return out


def gable_roof(w, d, z, rise, s, over=1.0, ridge_x=True, cx=0.0, cy_=0.0, snow=SNOW, fascia=TRIM):
    """Solid gable roof with eaves overhang, a fascia board, a ridge cap (snow in winter, coping elsewhere)."""
    if ridge_x:  # ridge along x, slopes face +y / -y
        half = d / 2 + over
        pts = [(-half, -0.35), (half, -0.35), (half, 0.0), (0.0, rise), (-half, 0.0)]
        parts = [pg((cx, cy_, z), pts, w + over * 2, s, "y", math.pi / 2)]
        parts.append(pg((cx, cy_, z), [(-1.5, rise - 1.05), (1.5, rise - 1.05), (0.0, rise + 0.22)], w + over * 2 + 0.1,
                        snow, "y", math.pi / 2))
        for sy in (-1, 1):
            parts.append(bx((cx, cy_ + sy * (half - 0.08), z - 0.2), (w + over * 2, 0.22, 0.6), fascia))
    else:  # ridge along y, gable end faces +y
        half = w / 2 + over
        pts = [(-half, -0.35), (half, -0.35), (half, 0.0), (0.0, rise), (-half, 0.0)]
        parts = [pg((cx, cy_, z), pts, d + over * 2, s, "y")]
        parts.append(pg((cx, cy_, z), [(-1.5, rise - 1.05), (1.5, rise - 1.05), (0.0, rise + 0.22)], d + over * 2 + 0.1,
                        snow, "y"))
        for sx in (-1, 1):
            parts.append(bx((cx + sx * (half - 0.08), cy_, z - 0.2), (0.22, d + over * 2, 0.6), fascia))
    return parts


# ---------------------------------------------------------------------------------------------- recipes
def house_gable_fence():
    """Two-storey brick house, slate side-gable roof, a projecting front gable bay (the silhouette feature), porch
    canopy, steps, front garden behind a low brick wall with railings, chimney stack, gutters and downpipes."""
    W, D, ST, PL = 21.0, 15.0, 8.8, 0.8  # width, depth, storey, plinth
    H = ST * 2
    y0 = -3.0  # body centre y; the front wall is at y0 + D / 2 = 4.5
    fy = y0 + D / 2
    by = y0 - D / 2
    parts = [bbx((0, y0, PL / 2), (W + 0.5, D + 0.5, PL), CONC, 0.08),
             bbx((0, y0, PL + H / 2), (W, D, H), WB, 0.28)]
    parts += [bx((0, y0, PL + ST), (W + 0.3, D + 0.3, 0.45), TRIM)]  # string course between storeys
    parts += gable_roof(W, D, PL + H, 6.0, ROOFB, 1.0, True, 0, y0)
    # front gable bay, 7.6 wide, 2.6 deep, full height, with its own gable facing the street
    bay_x, bay_w, bay_d = -5.2, 7.6, 2.6
    parts.append(bbx((bay_x, fy + bay_d / 2, PL + H / 2), (bay_w, bay_d, H), WB, 0.2))
    parts += gable_roof(bay_w, bay_d + 1.2, PL + H, 4.6, ROOFB, 0.6, False, bay_x, fy + bay_d / 2 - 0.4)
    parts.append(bx((bay_x, fy + bay_d / 2, PL + ST), (bay_w + 0.3, bay_d + 0.3, 0.45), TRIM))
    parts.append(bx((bay_x, fy + bay_d, PL + H + 2.2), (1.2, 0.2, 1.2), TRIM))  # round-ish vent plaque in the gable
    bay_face = fy + bay_d
    parts += window("+y", bay_face, bay_x, PL + ST * 0.48, 5.0, 4.4, mull=2, transom=True)
    parts += window("+y", bay_face, bay_x, PL + ST * 1.5, 3.6, 4.2, mull=1)
    # front: door with canopy and steps right of the bay, windows over it and to the right
    door_x = 1.4
    parts += [on_wall("+y", fy, door_x, PL + 3.35, 2.9, 0.12, 6.7, 0.0, DOOR),
              on_wall("+y", fy, door_x - 1.65, PL + 3.5, 0.35, 0.34, 7.2, 0.17, TRIM),
              on_wall("+y", fy, door_x + 1.65, PL + 3.5, 0.35, 0.34, 7.2, 0.17, TRIM),
              on_wall("+y", fy, door_x, PL + 7.1, 3.7, 0.4, 0.4, 0.2, TRIM),
              on_wall("+y", fy, door_x, PL + 4.3, 0.9, 0.08, 1.6, 0.08, GLIT),  # fanlight glow in the door
              bbx((door_x, fy + 1.0, PL + 7.9), (4.6, 2.2, 0.3), ROOFB, 0.08),  # canopy
              bx((door_x, fy + 1.0, PL + 8.1), (4.4, 2.0, 0.14), SNOW)]
    parts += [rcy((door_x + sx * 2.0, fy + 1.85, PL + 3.95), 0.16, 7.9, WHT, 10) for sx in (-1, 1)]
    for k in range(3):  # steps down from the threshold to the garden path
        top = PL - 0.27 * k
        parts.append(bbx((door_x, fy + 0.45 + 0.9 * k, top / 2), (4.0, 0.9, top), CONC, 0.04))
    parts += window("+y", fy, 7.2, PL + ST * 0.5, 4.0, 4.6, mull=1)
    parts += window("+y", fy, door_x, PL + ST * 1.5, 2.6, 4.2)
    parts += window("+y", fy, 7.2, PL + ST * 1.5, 4.0, 4.2, mull=1)
    # back and sides
    for u in (-6.5, 0.0, 6.5):
        parts += window("-y", by, u, PL + ST * 0.5, 3.4, 4.4, mull=1)
        parts += window("-y", by, u, PL + ST * 1.5, 3.4, 4.2, mull=1)
    for side in ("+x", "-x"):
        p = W / 2 if side == "+x" else -W / 2
        parts += window(side, p, -0.5 if side == "+x" else 0.5, PL + ST * 0.5, 3.0, 4.2)
        parts += window(side, p, -0.5 if side == "+x" else 0.5, PL + ST * 1.5, 3.0, 4.0)
    # chimney stack on the +x gable, cap, two pots, snow
    cx, czb = W / 2 - 1.6, PL + H
    parts += [bbx((cx, y0 + 1.5, czb + 4.6), (2.2, 1.6, 9.2), WB, 0.1),
              bbx((cx, y0 + 1.5, czb + 9.35), (2.7, 2.1, 0.45), CONC, 0.06),
              rcy((cx - 0.45, y0 + 1.5, czb + 10.0), 0.32, 0.9, ROOF, 12, r2=0.26),
              rcy((cx + 0.45, y0 + 1.5, czb + 10.0), 0.32, 0.9, ROOF, 12, r2=0.26),
              bx((cx, y0 + 1.5, czb + 9.62), (2.5, 1.9, 0.1), SNOW)]
    # gutters with icicles along both eaves, downpipes at the corners
    for sy, yy in ((1, fy + 1.0), (-1, by - 1.0)):
        parts.append(rcy((0, yy, PL + H - 0.45), 0.24, W + 1.9, MDK, 8, axis="x"))
        parts += icicles(-W / 2 + 1, W / 2 - 1, yy, PL + H - 0.7, 7 if sy > 0 else 4)
    parts += drainpipe(W / 2 - 0.3, fy + 0.95, PL, PL + H - 0.4) + drainpipe(-W / 2 + 0.3, by - 0.95, PL, PL + H - 0.4)
    # front garden: lawn, path, low brick wall with coping, railing posts and rails, gate piers, a shrub
    gy0, gy1 = fy + 0.0, fy + 8.6
    parts += [bx((-4.0, (gy0 + gy1) / 2, 0.08), (W - 8.0, gy1 - gy0, 0.16), GRASS),
              bx((door_x, (gy0 + gy1) / 2 + 1.4, 0.06), (3.2, gy1 - gy0 - 2.8, 0.12), STAIN),
              bx((W / 2 - 1.0, (gy0 + gy1) / 2, 0.08), (2.0, gy1 - gy0, 0.16), GRASS)]
    wall_y = gy1 - 0.4
    for x0, x1 in ((-W / 2, door_x - 2.2), (door_x + 2.2, W / 2)):
        mid, span = (x0 + x1) / 2, x1 - x0
        parts += [bbx((mid, wall_y, 1.0), (span, 0.9, 2.0), WB, 0.06),
                  bx((mid, wall_y, 2.08), (span + 0.1, 1.1, 0.16), CONC),
                  bx((mid, wall_y, 2.22), (span, 0.95, 0.12), SNOW),
                  bx((mid, wall_y, 3.55), (span, 0.12, 0.14), WORN)]
        for k in range(int(span / 1.4)):
            parts.append(bx((x0 + 0.7 + k * 1.4, wall_y, 2.95), (0.12, 0.12, 1.5), WORN))
    for gx in (door_x - 2.35, door_x + 2.35):  # gate piers with caps
        parts += [bbx((gx, wall_y, 1.6), (1.1, 1.1, 3.2), WB, 0.06), bbx((gx, wall_y, 3.35), (1.4, 1.4, 0.3), CONC, 0.05),
                  bx((gx, wall_y, 3.55), (1.2, 1.2, 0.1), SNOW)]
    parts += [usp((-8.2, gy0 + 2.2, 1.7), 1.9, LEAF, (1.15, 0.9, 0.9), 12, 7),
              usp((-6.6, gy0 + 2.6, 1.3), 1.4, LDK, (1.0, 0.9, 0.95), 10, 6),
              usp((8.4, gy0 + 1.8, 1.4), 1.5, LEAF, (1.0, 1.0, 0.95), 12, 7)]
    return parts


def bin_street():
    """Slim cast litter bin (1.05 m tall, 0.5 m wide): worn painted body with vertical ribs, a domed hood with a front
    slot, a band, a plinth; a snow cap on the hood."""
    parts = [rcy((0, 0, 0.12), 0.84, 0.24, MDK, 16),
             rcy((0, 0, 1.45), 0.74, 2.42, WORN, 16, r2=0.78),
             rcy((0, 0, 2.66), 0.83, 0.16, MDK, 16),
             rcy((0, 0, 0.95), 0.79, 0.12, MDK, 16),
             usp((0, 0, 2.74), 0.8, WORN, (1.0, 1.0, 0.55), 16, 6),
             rcy((0, 0, 3.12), 0.2, 0.14, MDK, 10),
             usp((0, 0, 2.88), 0.62, SNOW, (1.0, 1.0, 0.42), 12, 4)]
    for k in range(8):  # cast ribs
        a = 2 * math.pi * (k + 0.5) / 8
        parts.append(bx((math.cos(a) * 0.76, math.sin(a) * 0.76, 1.5), (0.12, 0.12, 2.2), MDK, a))
    parts += [bx((0, 0.6, 2.56), (0.9, 0.3, 0.3), RUB),  # throw slot under the hood
              bx((0, 0.78, 1.9), (0.5, 0.06, 0.34), TRIM)]  # pictogram plate
    return parts


def fire_hydrant():
    """Pillar hydrant (0.75 m), kept lean: Downtown places 34 of them and the winter scene sits at the 550,000-triangle
    ceiling (tests/unit/Downtown.test.luau N10), so it stays near its old 216 triangles and gets its roundness from
    smooth shading: flared base, barrel, bonnet dome, pentagon operating nut, two hose nozzles and a front pumper nozzle
    with caps."""
    parts = [rcy((0, 0, 0.13), 0.52, 0.26, RED, 8, r2=0.42),
             rcy((0, 0, 0.97), 0.36, 1.42, RED, 10, r2=0.34),
             usp((0, 0, 1.68), 0.4, RED, (1.0, 1.0, 0.7), 8, 4),
             bx((0, 0, 2.02), (0.2, 0.2, 0.2), MDK, 0.4)]
    for sx in (-1, 1):
        parts += [rcy((sx * 0.48, 0, 1.2), 0.14, 0.32, RED, 6, axis="x"),
                  bx((sx * 0.66, 0, 1.2), (0.06, 0.26, 0.26), MDK)]
    parts += [rcy((0, 0.5, 1.0), 0.2, 0.36, RED, 6, axis="y"), bx((0, 0.7, 1.0), (0.36, 0.08, 0.36), MDK)]
    return parts


def street_lamp_double():
    """Heritage double lamp (3 m, a pedestrian lamp): fluted base, slim tapered pole, collar, scrolled cross-arm, two
    hanging lanterns with warm glass and roofs, finial; snow on the lantern roofs."""
    parts = [rcy((0, 0, 0.18), 0.62, 0.36, WORN, 14), rcy((0, 0, 0.9), 0.44, 1.1, WORN, 14, r2=0.3),
             rcy((0, 0, 0.42), 0.5, 0.14, MDK, 14), rcy((0, 0, 1.5), 0.32, 0.12, MDK, 12),
             rcy((0, 0, 4.6), 0.19, 6.2, WORN, 12, r2=0.13),
             rcy((0, 0, 7.8), 0.22, 0.25, MDK, 12), rcy((0, 0, 3.0), 0.21, 0.12, MDK, 12)]
    for k in range(8):  # flutes on the base
        a = 2 * math.pi * k / 8
        parts.append(bx((math.cos(a) * 0.41, math.sin(a) * 0.41, 0.9), (0.08, 0.08, 1.0), MDK, a))
    for sx in (-1, 1):
        parts += [lmb((0, 0, 7.6), (sx * 1.3, 0, 8.25), 0.09, 0.08, WORN, 8),
                  lmb((sx * 1.3, 0, 8.25), (sx * 1.85, 0, 8.05), 0.08, 0.07, WORN, 8),
                  lmb((sx * 0.5, 0, 7.3), (sx * 1.05, 0, 7.95), 0.06, 0.06, WORN, 8)]
        lx = sx * 1.9
        parts += [rcy((lx, 0, 7.85), 0.08, 0.35, MDK, 8),
                  rcy((lx, 0, 7.45), 0.42, 0.5, MDK, 6, r2=0.5),  # lantern roof (hexagonal, as cast lanterns are)
                  rcy((lx, 0, 7.72), 0.3, 0.12, SNOW, 6, r2=0.12),
                  rcy((lx, 0, 6.75), 0.3, 0.9, GLIT, 6, r2=0.38),
                  rcy((lx, 0, 6.25), 0.26, 0.14, MDK, 6, r2=0.3),
                  rcy((lx, 0, 6.08), 0.1, 0.2, MDK, 6, r2=0.0)]
    parts += [usp((0, 0, 8.05), 0.2, MDK, (1, 1, 1.2), 10, 6), rcy((0, 0, 8.5), 0.06, 0.6, MDK, 6, r2=0.0)]
    return parts


def tree_oak():
    """Street oak: flared trunk, three main limbs and twigs into a clustered canopy of smooth lobes in two greens,
    sitting in a square tree pit with a grate."""
    parts = [bx((0, 0, 0.06), (4.2, 4.2, 0.12), KERB), bx((0, 0, 0.1), (3.5, 3.5, 0.08), MDK),
             rcy((0, 0, 0.5), 0.95, 0.8, BARK, 12, r2=0.6),
             lmb((0, 0, 0.8), (0.15, 0.1, 5.6), 0.6, 0.45, BARK, 12)]
    for k in range(4):  # grate bars
        parts.append(bx((-1.2 + 0.8 * k, 0, 0.16), (0.12, 3.4, 0.06), MET))
    limbs = [((0.15, 0.1, 5.4), (2.8, 1.0, 8.6), 0.4, 0.2), ((0.15, 0.1, 5.2), (-2.6, 0.8, 8.2), 0.38, 0.2),
             ((0.15, 0.1, 5.6), (0.4, -2.6, 8.9), 0.36, 0.2), ((0.15, 0.1, 5.6), (0.0, 0.3, 10.2), 0.34, 0.18)]
    for a, b, r1, r2 in limbs:
        parts.append(lmb(a, b, r1, r2, BARK, 8))
    parts += [lmb((2.8, 1.0, 8.6), (4.2, 1.6, 9.4), 0.18, 0.1, BARK, 6),
              lmb((-2.6, 0.8, 8.2), (-4.0, 0.2, 9.0), 0.18, 0.1, BARK, 6)]
    lobes = [((0.0, 0.2, 11.4), 3.6, LEAF, (1.15, 1.1, 0.85)), ((3.1, 1.2, 10.2), 2.7, LEAF, (1.1, 1.0, 0.85)),
             ((-3.0, 0.7, 10.0), 2.8, LDK, (1.1, 1.05, 0.85)), ((0.5, -2.8, 10.4), 2.6, LEAF, (1.05, 1.0, 0.85)),
             ((0.6, 3.0, 10.6), 2.5, LDK, (1.05, 1.0, 0.85)), ((-1.8, -1.9, 12.3), 2.3, LDK, (1.0, 1.0, 0.9)),
             ((2.2, -1.4, 12.6), 2.2, LEAF, (1.0, 1.0, 0.9)), ((-0.4, 1.6, 13.6), 2.2, LEAF, (1.0, 1.0, 0.85)),
             ((4.3, 1.8, 9.5), 1.5, LDK, (1.0, 1.0, 0.85)), ((-4.2, 0.2, 9.2), 1.5, LEAF, (1.0, 1.0, 0.85))]
    for c, r, s, sq in lobes:
        parts.append(usp(c, r, s, sq, 14, 9))
    return parts


def car_sedan():
    """Mid-size sedan, 4.7 x 1.8 x 1.45 m: side-profile body (hood, cabin, boot) bevelled, greenhouse with pillars and a
    roof, wheel wells, smooth tyres and rims, lights, grille, mirrors, door seams, bumpers; a thin snow cap on the roof."""
    L, W = 15.0, 5.8
    body = [(-7.45, 0.95), (7.45, 0.95), (7.55, 1.55), (7.35, 2.45), (3.4, 2.85), (-4.4, 2.95), (-7.3, 2.75),
            (-7.55, 1.75)]
    glass = [(-4.3, 2.85), (3.1, 2.8), (0.9, 4.45), (-3.3, 4.5)]
    roof = [(-3.35, 4.42), (0.95, 4.38), (0.85, 4.62), (-3.25, 4.66)]
    parts = [bev(pg((0, 0, 0), body, W * 0.97, BLU, "y"), 0.18),
             bev(pg((0, 0, 0), glass, W * 0.84, GLS, "y"), 0.06),
             bev(pg((0, 0, 0), roof, W * 0.86, BLU, "y"), 0.05),
             pg((0, 0, 0.05), [(-2.9, 4.62), (0.55, 4.6), (0.5, 4.68), (-2.85, 4.7)], W * 0.62, SNOW, "y")]
    for sy in (-1, 1):  # B and C pillars, belt line, door seams, handles, mirrors
        y = sy * W * 0.42
        parts += [pg((0, y, 0), [(-1.05, 2.85), (-0.55, 2.85), (-0.8, 4.48), (-1.25, 4.48)], 0.12, BLU, "y"),
                  pg((0, y, 0), [(-4.3, 2.85), (-3.3, 2.85), (-2.95, 4.48), (-3.3, 4.5)], 0.12, BLU, "y"),
                  bx((-0.6, sy * W * 0.487, 2.82), (8.0, 0.06, 0.1), TRIM),
                  bx((-0.85, sy * W * 0.487, 1.9), (0.06, 0.06, 1.8), MDK),
                  bx((2.8, sy * W * 0.487, 1.9), (0.06, 0.06, 1.6), MDK),
                  bx((0.3, sy * W * 0.49, 2.45), (0.6, 0.08, 0.14), MET),
                  bx((-2.6, sy * W * 0.49, 2.45), (0.6, 0.08, 0.14), MET),
                  bbx((2.75, sy * (W * 0.5 + 0.2), 3.05), (0.6, 0.45, 0.35), BLU, 0.05)]
    for x in (-4.6, 4.5):  # wheel wells with arch lips, tyres, rims with five spokes, hubs
        parts += [rcy((x, 0, 1.15), 1.38, W * 0.975, RUB, 20, axis="y")]
        for sy in (-1, 1):
            yw = sy * (W / 2 - 0.05)
            parts += [rcy((x, sy * (W / 2 - 0.55), 1.05), 1.05, 0.95, RUB, 24, axis="y"),
                      rcy((x, sy * (W / 2 - 0.12), 1.05), 0.7, 0.06, MDK, 16, axis="y"),
                      rcy((x, yw, 1.05), 0.2, 0.1, MET, 10, axis="y"),
                      rcy((x, yw, 1.05), 0.68, 0.05, MET, 16, r2=0.62, axis="y")]
            for k in range(5):
                a = 2 * math.pi * k / 5
                parts.append(bx((x + math.cos(a) * 0.38, yw + sy * 0.03, 1.05 + math.sin(a) * 0.38), (0.5, 0.06, 0.13),
                                MET, 0.0) if abs(math.sin(a)) < 0.6 else
                             bx((x + math.cos(a) * 0.38, yw + sy * 0.03, 1.05 + math.sin(a) * 0.38), (0.13, 0.06, 0.5),
                                MET, 0.0))
            parts.append(pg((x, sy * (W * 0.485), 0), [(-1.55, 1.05), (-1.4, 1.75), (-0.9, 2.3), (0.0, 2.55), (0.9, 2.3),
                                                       (1.4, 1.75), (1.55, 1.05), (1.75, 1.05), (1.6, 1.9), (1.0, 2.55),
                                                       (0.0, 2.8), (-1.0, 2.55), (-1.6, 1.9), (-1.75, 1.05)], 0.12, MDK, "y"))
    for sy in (-1, 1):  # side skirts
        parts.append(bbx((0, sy * W * 0.485, 0.95), (8.2, 0.16, 0.3), MDK, 0.03))
    parts += [lmb((3.0, -1.6, 2.9), (2.2, 0.2, 3.3), 0.05, 0.04, MDK, 6), lmb((3.0, 0.4, 2.9), (2.2, 1.9, 3.3), 0.05, 0.04, MDK, 6),
              rcy((-7.55, 1.8, 0.8), 0.14, 0.4, MET, 10, axis="x"), lmb((-2.8, 0.0, 4.66), (-3.6, 0.0, 5.6), 0.04, 0.02, MDK, 6)]
    for sy in (-1, 1):  # lights
        parts += [bbx((7.5, sy * 2.05, 2.0), (0.2, 1.1, 0.5), WHT, 0.04),
                  bbx((-7.55, sy * 2.1, 2.2), (0.2, 1.2, 0.45), RED, 0.04),
                  bx((7.55, sy * 2.05, 1.3), (0.1, 0.6, 0.12), ORG)]
    parts += [bbx((7.58, 0, 1.6), (0.15, 2.4, 0.6), MDK, 0.04),  # grille
              bbx((7.4, 0, 1.0), (0.6, W * 0.96, 0.45), MDK, 0.08),  # bumpers
              bbx((-7.45, 0, 1.05), (0.55, W * 0.96, 0.5), MDK, 0.08),
              bx((-7.62, 0, 1.75), (0.06, 1.6, 0.5), YEL)]  # number plate (blank)
    return parts


def tower_slab():
    """Residential slab at real storeys (research R-18; tower floor count is an open owner question): glazed double-
    height lobby behind concrete columns, four storeys of recessed ribbon windows in a concrete frame, a stacked corner
    balcony column (the silhouette feature), AC units, a roof plant room and a water tank on legs, abstract graffiti on
    the plinth side, a sign-free canopy."""
    W, D, LOBBY, ST = 26.0, 16.0, 13.0, 9.0
    top = LOBBY + ST * 4
    fy, by = D / 2, -D / 2
    parts = [bbx((0, 0, top / 2), (W, D, top), WC, 0.3),
             bbx((0, 0, LOBBY / 2), (W - 1.4, D - 1.4, LOBBY), GLS, 0.0),
             bbx((0, 0, top + 0.6), (W + 0.6, D + 0.6, 1.2), CONC, 0.12)]  # roof slab and parapet
    for sy in (-1, 1):  # snow only on the parapet copings, never a blanket over the roof
        parts.append(bx((0, sy * (D / 2 + 0.05), top + 1.27), (W + 0.5, 0.6, 0.14), SNOW))
    for sx in (-1, 1):
        parts.append(bx((sx * (W / 2 + 0.05), 0, top + 1.27), (0.6, D - 0.6, 0.14), SNOW))
    # lobby: columns, canopy, entrance doors, glazing mullions, graffiti on the -x plinth
    for u in (-12.3, -6.2, 0.0, 6.2, 12.3):
        parts.append(bbx((u, fy - 0.3, LOBBY / 2), (1.3, 1.3, LOBBY), CONC, 0.08))
    for u in (-9.25, -3.1, 3.1, 9.25):
        for k in (1, 2):
            parts.append(bx((u - 3.1 + 2.07 * k, fy - 0.55, LOBBY * 0.45), (0.14, 0.12, LOBBY * 0.86), MDK))
        parts.append(bx((u, fy - 0.55, LOBBY * 0.62), (6.0, 0.12, 0.16), MDK))
    parts += [bbx((0, fy + 2.0, LOBBY - 1.2), (11.0, 4.6, 0.6), CONC, 0.1), bx((0, fy + 2.0, LOBBY - 0.85), (10.6, 4.2, 0.12), SNOW),
              on_wall("+y", fy - 0.7, 0, 3.4, 4.6, 0.12, 6.8, 0.0, MDK),
              on_wall("+y", fy - 0.7, 0, 3.4, 4.0, 0.14, 6.2, 0.05, GLIT),
              on_wall("-x", -W / 2, 2.0, 2.6, 9.0, 0.06, 4.4, 0.02, GRAF)]
    # four storeys: concrete floor bands and ribbon windows on all faces; one window in four lit
    lit = 0
    for f in range(4):
        z0 = LOBBY + ST * f
        parts.append(bx((0, 0, z0 + 0.3), (W + 0.5, D + 0.5, 0.6), CONC))
        for side, p, span, cols in (("+y", fy, W, 4), ("-y", by, W, 4), ("+x", W / 2, D, 2), ("-x", -W / 2, D, 2)):
            pitch = span / cols
            for c in range(cols):
                u = -span / 2 + pitch * (c + 0.5)
                if side == "+y" and c == cols - 1:
                    continue  # the balcony column takes the right bay
                lit += 1
                glass = GLIT if lit % 4 == 1 else GLS
                parts += window(side, p, u, z0 + ST * 0.52, pitch * 0.66, ST * 0.52, glass, CONC, mull=1,
                                simple=side != "+y")
        # corner balcony stack on the front right bay: slab, solid parapet, rail, door, planter
        bxc = W / 2 - W / 8
        parts += [bbx((bxc, fy + 1.6, z0 + 0.35), (W / 4 + 0.4, 3.4, 0.7), CONC, 0.08),
                  bx((bxc, fy + 3.2, z0 + 1.4), (W / 4 + 0.4, 0.3, 1.5), CONC),
                  bx((bxc, fy + 3.2, z0 + 2.9), (W / 4 + 0.4, 0.18, 0.18), MET),
                  bx((bxc, fy + 3.25, z0 + 2.25), (W / 4 + 0.3, 0.2, 0.08), SNOW),
                  on_wall("+y", fy, bxc - 1.2, z0 + 3.6, 2.6, 0.12, 6.2, 0.02, GLS),
                  on_wall("+y", fy, bxc + 1.9, z0 + 4.2, 1.8, 0.12, 3.6, 0.02, GLIT if f % 2 else GLS)]
        for sx in (-1, 1):
            parts.append(bx((bxc + sx * (W / 8 + 0.1), fy + 2.4, z0 + 2.1), (0.18, 1.6, 0.18), MET))
        # AC units on the -y face
        parts += [bbx((-W / 4, by - 0.75, z0 + 1.8), (2.0, 1.4, 1.4), WHT, 0.06),
                  bx((-W / 4, by - 1.47, z0 + 1.8), (1.2, 0.06, 1.0), MDK)]
    parts += drainpipe(-W / 2 + 0.35, fy + 0.35, 0.2, top - 0.2) + drainpipe(W / 2 - 0.35, by - 0.35, 0.2, top - 0.2)
    # roof: plant room, vents, water tank on a steel frame (silhouette), aerial
    rz = top + 1.2
    parts += [bbx((-5.5, -1.5, rz + 2.4), (9.0, 7.0, 4.8), CONC, 0.12),
              on_wall("+y", 2.0, -5.5, rz + 2.0, 1.8, 0.12, 3.6, 0.0, MDK),
              bx((-5.5, -5.1, rz + 3.2), (6.0, 0.1, 1.6), MDK)]
    parts += [rcy((6.0, -2.0, rz + 6.6), 2.4, 4.0, WOOD, 16), rcy((6.0, -2.0, rz + 9.05), 2.55, 0.9, MDK, 16, r2=0.25)]
    for k in range(4):
        x = 6.0 + (1 if k % 2 else -1) * 1.6
        y = -2.0 + (1 if k // 2 else -1) * 1.6
        parts.append(bx((x, y, rz + 2.3), (0.3, 0.3, 4.6), MDK))
    parts += [bx((6.0, -2.0, rz + 4.55), (3.8, 3.8, 0.25), MDK), bx((6.0, -2.0, rz + 2.3), (3.6, 0.15, 0.15), MDK)]
    parts += [rcy((1.0, 4.5, rz + 0.8), 0.6, 1.6, MET, 12), usp((1.0, 4.5, rz + 1.65), 0.62, MET, (1, 1, 0.4), 12, 5),
              rcy((-11.0, 5.5, rz + 0.8), 0.45, 1.6, MET, 12), rcy((-11.5, -6.0, rz + 4.0), 0.07, 8.0, MDK, 6)]
    return parts


def shop_row_three():
    """Three shops under two storeys of flats, real storeys (4 m shop floor, 3 m upper): brick upper floors with
    recessed windows (a third lit), cornice and parapet, three shopfronts with stall risers, mullioned glazing, recessed
    doors, fascia signs and sloped awnings; pilasters between shops; a fire escape on the right bay and a timber water
    tank on the roof (the silhouette features); AC units, drainpipes; snow on sills, cornice and awnings."""
    W, D, GF, ST = 44.0, 20.0, 13.0, 9.6
    top = GF + ST * 2
    fy, by = D / 2, -D / 2
    signs = ["sign_02", "sign_05", "sign_07"]
    parts = [bbx((0, 0, top / 2), (W, D, top), FX_BRICK, 0.3),
             bbx((0, 0, GF / 2), (W + 0.2, D + 0.2, GF), FX_RENDER, 0.15),
             bx((0, 0, GF + 0.3), (W + 0.6, D + 0.6, 0.6), FX_CORN),
             bbx((0, 0, top + 0.8), (W + 1.2, D + 1.2, 1.0), FX_CORN, 0.12),
             bx((0, fy + 0.3, top - 0.9), (W + 0.4, 0.6, 0.8), FX_CORN),
             bx((0, fy + 0.35, top + 1.36), (W + 1.0, 0.5, 0.12), FX_SNOW),
             bx((0, by - 0.35, top + 1.36), (W + 1.0, 0.5, 0.12), FX_SNOW)]
    bay = W / 3
    for k, sign in enumerate(signs):
        cx = -W / 2 + bay * (k + 0.5)
        door_left = k == 1
        dx = cx + (-bay * 0.3 if door_left else bay * 0.3)
        gx = cx + (bay * 0.12 if door_left else -bay * 0.12)
        gw = bay * 0.58
        parts += [on_wall("+y", fy, gx, 1.0, gw + 0.4, 0.5, 2.0, 0.2, FX_RENDER),  # stall riser
                  on_wall("+y", fy, gx, 5.6, gw, 0.12, 7.0, 0.06, FX_SHOP),  # shop glazing
                  on_wall("+y", fy, gx, 2.05, gw + 0.3, 0.6, 0.2, 0.3, FX_CORN),
                  on_wall("+y", fy, dx, 3.6, 3.2, 0.12, 7.2, -0.3, FX_SHUT),  # recessed door
                  on_wall("+y", fy, dx, 7.5, 3.2, 0.12, 0.8, 0.02, FX_LIT),
                  on_wall("+y", fy, dx, 7.35, 3.8, 0.4, 0.3, 0.2, FX_CORN),
                  on_wall("+y", fy, cx, 10.4, bay - 1.8, 0.4, 2.0, 0.25, sign)]  # fascia sign
        for m in range(4):
            parts.append(on_wall("+y", fy, gx - gw / 2 + gw * m / 3, 5.6, 0.22, 0.24, 7.2, 0.14, FX_CORN))
        parts.append(on_wall("+y", fy, gx, 6.9, gw, 0.2, 0.18, 0.12, FX_CORN))
        # sloped awning with a valance and a snow line
        parts += [pg((cx, fy, 9.15), [(0.0, 0.0), (3.8, -1.6), (3.8, -2.2), (3.6, -2.2), (0.0, -0.25)], bay - 2.4, FX_SHUT,
                     "y", math.pi / 2),
                  pg((cx, fy, 9.15), [(0.0, 0.05), (3.8, -1.55), (3.8, -1.45), (0.0, 0.17)], bay - 2.6, FX_SNOW, "y",
                     math.pi / 2)]
        parts += icicles(cx - bay / 2 + 1.6, cx + bay / 2 - 1.6, fy + 3.75, 6.95, 5, FX_SNOW)
        # upper floors: three windows per bay, recessed, one in three lit
        for f in range(2):
            z = GF + ST * f + ST * 0.5
            for w in range(3):
                u = cx - bay / 3 + bay / 3 * w
                glass = FX_LIT if (k + f + w) % 3 == 0 else FX_GLASS
                parts += window("+y", fy, u, z, 2.6, 4.8, glass, FX_CORN, snow=FX_SNOW, transom=True)
                parts += window("-y", by, u, z, 2.6, 4.8, FX_GLASS, FX_CORN, snow=FX_SNOW, simple=True)
    for u in (-W / 2 + 0.6, -bay / 2, bay / 2, W / 2 - 0.6):  # pilasters
        parts.append(on_wall("+y", fy, u, GF / 2, 1.2, 0.6, GF, 0.3, FX_CORN))
    for side, p in (("+x", W / 2), ("-x", -W / 2)):
        for f in range(2):
            for u in (-4.0, 4.0):
                parts += window(side, p, u, GF + ST * f + ST * 0.5, 2.6, 4.8, FX_GLASS, FX_CORN, snow=FX_SNOW,
                                simple=True)
    # fire escape on the right bay front: two landings with rails, a ladder and stair stringers
    fx0 = W / 2 - bay / 2
    for f in range(2):
        z = GF + ST * f + 0.4
        parts += [bx((fx0, fy + 1.6, z), (bay - 3.0, 3.0, 0.2), FX_SHUT), bx((fx0, fy + 3.05, z + 1.6), (bay - 3.0, 0.15, 0.15), FX_SHUT),
                  bx((fx0, fy + 3.1, z + 0.22), (bay - 3.2, 0.5, 0.08), FX_SNOW)]
        for k in range(6):
            parts.append(bx((fx0 - (bay - 3.0) / 2 + (bay - 3.0) * k / 5, fy + 3.05, z + 0.8), (0.12, 0.12, 1.6), FX_SHUT))
        # stair stringer between the landings (a slanted prism) and a drop ladder below the first landing
        if f == 0:
            parts.append(pg((fx0, fy + 2.4, z), [(-4.0, 0.1), (-3.4, 0.1), (2.6, ST - 0.1), (2.0, ST - 0.1)], 1.2,
                            FX_SHUT, "y"))
            for sx in (-0.5, 0.5):
                parts.append(bx((fx0 + 4.2 + sx, fy + 2.9, z - 3.6), (0.12, 0.12, 6.4), FX_SHUT))
            for k in range(8):
                parts.append(bx((fx0 + 4.2, fy + 2.9, z - 0.8 - k * 0.8), (1.0, 0.1, 0.1), FX_SHUT))
    # AC units, drainpipes
    for u in (-14.0, 2.0):
        parts += [bbx((u, by - 0.75, GF + ST + 2.0), (2.2, 1.4, 1.5), FX_RENDER, 0.06), bx((u, by - 1.47, GF + ST + 2.0), (1.4, 0.06, 1.1), FX_GLASS)]
    parts += drainpipe(-W / 2 + 0.5, fy + 0.45, 0.2, top - 0.3, FX_SHUT) + drainpipe(W / 2 - 0.5, by - 0.45, 0.2, top - 0.3, FX_SHUT)
    # roof: timber water tank on a steel stand (silhouette feature), access hatch, vents
    rz = top + 1.3
    parts += [rcy((-10.0, -2.0, rz + 6.4), 2.6, 4.6, FX_SHUT, 16), rcy((-10.0, -2.0, rz + 9.1), 2.75, 0.9, FX_CORN, 16, r2=0.3),
              rcy((-10.0, -2.0, rz + 9.6), 1.2, 0.22, FX_SNOW, 12, r2=0.2)]
    for k in range(4):
        parts.append(bx((-10.0 + (1 if k % 2 else -1) * 1.7, -2.0 + (1 if k // 2 else -1) * 1.7, rz + 2.0), (0.3, 0.3, 4.0), FX_SHUT))
    parts += [bx((-10.0, -2.0, rz + 4.05), (4.0, 4.0, 0.25), FX_SHUT),
              bbx((8.0, -3.0, rz + 1.2), (4.0, 3.0, 2.4), FX_RENDER, 0.08),
              rcy((14.0, 3.0, rz + 0.8), 0.55, 1.6, FX_CORN, 12), rcy((16.0, -5.0, rz + 0.8), 0.45, 1.6, FX_CORN, 12)]
    return parts


RECIPES = {
    "ck_house_gable_fence": house_gable_fence,
    "ck_shop_row_three": shop_row_three,
    "ck_tower_slab": tower_slab,
    "ck_car_sedan": car_sedan,
    "ck_tree_oak": tree_oak,
    "ck_street_lamp_double": street_lamp_double,
    "ck_bin_street": bin_street,
    "dt_fire_hydrant": fire_hydrant,
}
BUILDINGS = ("ck_house_", "ck_shop_", "ck_midrise_", "ck_tower_")


# ---------------------------------------------------------------------------------------------- driver
def load_modules():
    global bo, kr
    scripts = os.path.join(ROOT, "art", "scripts")
    if scripts not in sys.path:
        sys.path.insert(0, scripts)
    import importlib
    import kit_recipes
    kr = importlib.reload(kit_recipes)
    kr.ROOT = ROOT
    kr.load_modules()
    bo = kr.bo


def source_of(object_id, tier=None):
    """The .blend that holds the id's collection; a new id goes to the kit file for its zone or tier."""
    import bpy
    for path in sorted(glob.glob(os.path.join(ROOT, "art", "source", "*.blend"))):
        with bpy.data.libraries.load(path, link=False) as (data_from, _):
            if object_id in data_from.collections:
                return path
    if tier is None:
        raise RuntimeError(f"{object_id}: no collection in art/source")
    name = "ck_buildings" if object_id.startswith(BUILDINGS) else ("ck_props_t1_t3" if tier <= 3 else "ck_props_t4_t5")
    return os.path.join(ROOT, "art", "source", name + ".blend")


STAGE_B = ("kit_stage_b_buildings.py", "kit_stage_b_props.py", "kit_stage_c.py")
STAGE_B_PROPS = set()  # filled by kit_stage_b_props.py
UNIT = {}  # id -> studs per authoring unit for a natural run (Stage C recipes are authored in metres: 3.2)


def load_stage_b():
    """Stage B recipe modules (013 Phase 9 T076, T077): run into this module's namespace so they share the builder
    vocabulary, and add their recipes to RECIPES."""
    for name in STAGE_B:
        path = os.path.join(ROOT, "art", "scripts", name)
        if os.path.exists(path):
            exec(compile(open(path, encoding="utf-8").read(), path, "exec"), globals())


def island_uvs(bm, islands, swatch_of, rects):
    """Round parts: map the whole part into its cell at once (u across x + y, v up z), so the cell's top-to-bottom
    gradient becomes one soft light-to-shade sweep over a canopy or a bin instead of stripes face by face."""
    layer = bm.loops.layers.uv.active
    eps = 1e-4
    for faces in islands:
        faces = [f for f in faces if f.is_valid and f in swatch_of]
        if not faces:
            continue
        verts = {v for f in faces for v in f.verts}
        zs = [v.co.z for v in verts]
        ws = [v.co.x + v.co.y for v in verts]
        z0, z1, w0, w1 = min(zs), max(zs), min(ws), max(ws)
        for f in faces:
            r = rects[swatch_of[f]]
            iu, iv = r[2] - r[0] - 2 * eps, r[3] - r[1] - 2 * eps
            for loop in f.loops:
                co = loop.vert.co
                su = (co.x + co.y - w0) / (w1 - w0) if w1 - w0 > eps else 0.5
                sv = (co.z - z0) / (z1 - z0) if z1 - z0 > eps else 0.5
                loop[layer].uv = (r[0] + eps + su * iu, r[1] + eps + sv * iv)


def build_one(object_id, rects, budgets):
    import bmesh
    import bpy
    from mathutils import Vector
    bm = bmesh.new()
    tags = []
    builder = make_builder(bm, tags)
    global SMOOTH_DEG
    SMOOTH_DEG = 60 if object_id in STAGE_B_PROPS else 40
    for part in RECIPES[object_id]():
        builder.run(part)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    builder.finish()
    area = {}
    for face, swatch in tags:
        if face.is_valid:
            area[swatch] = area.get(swatch, 0.0) + face.calc_area()
    x0, x1, y0, y1, z0, z1 = bo.bbox_of(bm)
    size = budgets["sizes"][object_id]
    scale = UNIT.get(object_id, 1.0) if NATURAL else size / max(x1 - x0, y1 - y0, z1 - z0)
    bmesh.ops.scale(bm, vec=Vector((scale, scale, scale)), verts=bm.verts)
    x0, x1, y0, y1, z0, z1 = bo.bbox_of(bm)
    bmesh.ops.translate(bm, vec=Vector((-(x0 + x1) / 2, -(y0 + y1) / 2, -z0)), verts=bm.verts)
    dims = (x1 - x0, y1 - y0, z1 - z0)
    live = [(f, s) for f, s in tags if f.is_valid]
    tris = kr.assign_uvs_upright(bm, live, rects)
    island_uvs(bm, builder.islands, dict(live), rects)
    tier = budgets["tiers"][object_id]
    limit = budgets["meshTriangles"][tier - 1]
    if tris > limit and not NATURAL:
        raise RuntimeError(f"{object_id}: {tris} triangles over the tier {tier} budget {limit}")
    mesh = bpy.data.meshes.new(object_id)
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    mesh.materials.append(bo.palette_material())
    obj = bpy.data.objects.new(object_id, mesh)
    coll = bpy.data.collections.new(object_id)
    coll.objects.link(obj)
    bpy.context.scene.collection.children.link(coll)
    total = sum(area.values()) or 1.0
    muted = sum(a for s, a in area.items() if not is_accent(s)) / total
    season = (area.get(SNOW, 0) + area.get(FX_SNOW, 0) + area.get(ICE, 0)) / total
    return {"id": object_id, "tier": tier, "triangles": tris, "ceiling": limit,
            "pctCeiling": round(100.0 * tris / limit, 1), "mutedShare": round(muted, 3),
            "snowShare": round(season, 3), "scale": round(scale, 3), "dims": [round(v, 2) for v in dims]}


def run(params):
    global ROOT, NATURAL
    ROOT = params["root"]
    NATURAL = bool(params.get("natural"))
    import bpy
    load_modules()
    load_stage_b()
    art = os.path.join(ROOT, "art")
    budgets = json.load(open(os.path.join(art, "scripts", "budgets.json"), encoding="utf-8"))
    palette = json.load(open(os.path.join(art, "palette.json"), encoding="utf-8"))
    rects = {n: (c["u0"], c["v0"], c["u1"], c["v1"]) for n, c in palette["cells"].items()}
    fronts = json.load(open(os.path.join(art, "atlases", "fronts", "fronts.json"), encoding="utf-8"))
    for group in ("signs", "billboards", "strips"):
        for n, c in fronts[group].items():
            rects[n] = (c["u0"], c["v0"], c["u1"], c["v1"])
    ids = params.get("only") or list(RECIPES)
    bpy.ops.wm.read_homefile(use_empty=True)
    files = {}
    for object_id in ids:
        files.setdefault(source_of(object_id, budgets["tiers"].get(object_id)), []).append(object_id)
    report = []
    for path, file_ids in sorted(files.items()):
        bpy.ops.wm.open_mainfile(filepath=path)
        for object_id in file_ids:
            coll = bpy.data.collections.get(object_id)
            if coll is not None:
                for obj in list(coll.objects):
                    data = obj.data
                    bpy.data.objects.remove(obj, do_unlink=True)
                    if data is not None and data.users == 0:
                        bpy.data.meshes.remove(data)
                bpy.data.collections.remove(coll)
            row = build_one(object_id, rects, budgets)
            row["file"] = os.path.relpath(path, ROOT)
            report.append(row)
        if not NATURAL:
            bpy.ops.wm.save_as_mainfile(filepath=path)
    for row in report:
        flag = ""
        if row["id"].startswith(BUILDINGS):
            if row["pctCeiling"] < 60:
                flag += " UNDER-60%"
            if row["mutedShare"] < 0.7:
                flag += " UNDER-70%-MUTED"
        print(f"kit_rework: {row['id']}: {row['triangles']} tris = {row['pctCeiling']}% of T{row['tier']} "
              f"({row['ceiling']}), muted {row['mutedShare']:.0%}, snow {row['snowShare']:.0%}, dims {row['dims']}{flag}")
    out = params.get("report")
    if out:
        with open(out, "w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2)
            handle.write("\n")
    print("kit_rework: OK")
    return report
