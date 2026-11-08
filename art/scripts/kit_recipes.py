# Recipes for the 84 city asset kit meshes (013): building variants, street, park, suburbs, main street and downtown
# props, billboards and the seven meme originals. Same DSL as build_objects.py (bx, cy, cn, sp, pg, tor); the builder
# rescales each mesh so its longest side equals the ObjectDef size and puts the origin at the bottom centre, so the
# dimensions here are authoring units (the data-model.md dims). Swatches are the w-* palette cells, so every theme atlas
# recolours the same mesh. Shop buildings and billboards (atlas "fronts") take their sign and facade faces from
# art/atlases/fronts/fronts.json, passed in as `fronts` (cell names sign_XX, bb_*, fx_*).
#
# Run through the Blender MCP (execute_blender_code); the run replaces the open file in the claimed Blender:
#   PARAMS = {"root": "<repo root>", "only": ["ck_bush"]}      # "only" optional: ids to build (default: all)
#   exec(open(PARAMS["root"] + "/art/scripts/kit_recipes.py").read()); run(PARAMS)
# Source files: ck_buildings.blend (zone building), ck_props_t1_t3.blend and ck_props_t4_t5.blend (everything else by
# tier). Ids in `only` rewrite just their file's other collections too (a file is rebuilt whole), so build all of a
# file's ids together.

import json
import math
import os
import sys

RED, YEL, BLU, TEAL = "w-accent-red", "w-accent-yellow", "w-accent-blue", "w-accent-teal"
ORG, PNK, WHT, WOOD = "w-accent-orange", "w-accent-pink", "w-white", "w-wood"
MET, MDK, GLS, RUB = "w-metal", "w-metal-dark", "w-glass", "w-rubber"
LEAF, LDK, BARK, GLOW = "w-leaf", "w-leaf-dark", "w-bark", "w-glow"
WA, WB, WC, ROOF, ROOFB = "w-wall-a", "w-wall-b", "w-wall-c", "w-roof-a", "w-roof-b"
SAND, KERB, WATER, TRIM, DOOR = "w-sand", "w-kerb", "w-water", "w-trim", "w-door"
ASPH, LINE, WALK, GRASS, SOIL = "w-asphalt", "w-road-line", "w-sidewalk", "w-grass", "w-soil"

BUILDING_FILE = "ck_buildings"
PROP_FILES = {"low": "ck_props_t1_t3", "high": "ck_props_t4_t5"}
ROOT = None
bo = None  # the build_objects module, loaded by run()


def P():
    return bo.bx, bo.cy, bo.cn, bo.sp, bo.pg, bo.tor


# ---------------------------------------------------------------------------------------------- shared helpers

def window_grid(cx, cy, face_w, z0, z1, cols, rows, nx, ny, s=GLS, depth=0.12, sill=True, frame=None):
    """Windows on one wall. The wall faces (nx, ny) (a unit direction); cx, cy is the wall centre on the ground."""
    bx = bo.bx
    parts = []
    tx, ty = -ny, nx  # along the wall
    cw = face_w / cols
    rh = (z1 - z0) / rows
    for r in range(rows):
        for c in range(cols):
            off = (c + 0.5) * cw - face_w / 2
            x = cx + tx * off + nx * depth / 2
            y = cy + ty * off + ny * depth / 2
            z = z0 + (r + 0.5) * rh
            yaw = math.atan2(ny, nx) - math.pi / 2 if (nx or ny) else 0
            parts.append(bx((x, y, z), (cw * 0.5, depth, rh * 0.5), s, yaw))
            if sill:
                parts.append(bx((x + nx * 0.05, y + ny * 0.05, z - rh * 0.3), (cw * 0.6, depth + 0.1, rh * 0.07),
                                frame or TRIM, yaw))
    return parts


def all_walls(w, d, z0, z1, colsf, colss, rows, s=GLS, sides=True, sill=True):
    parts = []
    parts += window_grid(0, d / 2, w, z0, z1, colsf, rows, 0, 1, s, sill=sill)
    parts += window_grid(0, -d / 2, w, z0, z1, colsf, rows, 0, -1, s, sill=sill)
    if sides:
        parts += window_grid(w / 2, 0, d, z0, z1, colss, rows, 1, 0, s, sill=sill)
        parts += window_grid(-w / 2, 0, d, z0, z1, colss, rows, -1, 0, s, sill=sill)
    return parts


def pickets(x0, x1, y, n, h=1.0, s=WHT, w=0.28):
    bx = bo.bx
    parts = [bx((x0 + (x1 - x0) * (i + 0.5) / n, y, h / 2), (w, 0.16, h), s) for i in range(n)]
    parts.append(bx(((x0 + x1) / 2, y, h * 0.3), (x1 - x0, 0.1, 0.12), s))
    parts.append(bx(((x0 + x1) / 2, y, h * 0.75), (x1 - x0, 0.1, 0.12), s))
    return parts


def gable(w, d, z, rise, s, over=0.4, yaw=0.0, cx=0.0, cy_=0.0):
    pts = [(-w / 2 - over, 0.0), (w / 2 + over, 0.0), (0.0, rise)]
    return bo.pg((cx, cy_, z), pts, d + over * 2, s, "y", yaw)


def house(w, d, h, wall, roof, floors=2, cols=3, fence=0, garage=0.0, bay=False, wing=0.0, chimney=True,
          porch=False, hip=False, side_gable=False, steps=True):
    bx, cy, cn, sp, pg, tor = P()
    rise = h * 0.42
    parts = [bx((0, 0, h / 2), (w, d, h), wall)]
    if side_gable:
        parts.append(gable(d, w, h, rise, roof, 0.4, math.pi / 2))
    else:
        parts.append(gable(w, d, h, rise, roof))
    if hip:
        parts.append(gable(d * 0.8, w * 0.5, h, rise * 0.9, roof, 0.3, math.pi / 2, 0, 0))
    parts += all_walls(w, d, h * 0.18, h * 0.82, cols, 2, floors)
    # door, step and canopy
    parts.append(bx((w * 0.2, d / 2 + 0.08, 1.0), (1.1, 0.18, 2.0), DOOR))
    if steps:
        parts.append(bx((w * 0.2, d / 2 + 0.5, 0.12), (1.8, 0.9, 0.24), WALK))
    if porch:
        parts.append(bx((w * 0.2, d / 2 + 0.9, 2.5), (2.4, 1.8, 0.15), ROOFB))
        parts.append(bx((w * 0.2 - 1.0, d / 2 + 1.7, 1.25), (0.15, 0.15, 2.5), WHT))
        parts.append(bx((w * 0.2 + 1.0, d / 2 + 1.7, 1.25), (0.15, 0.15, 2.5), WHT))
    if chimney:
        parts.append(bx((-w * 0.3, -d * 0.1, h + rise * 0.6), (0.9, 0.9, rise * 0.9), WB))
        parts.append(bx((-w * 0.3, -d * 0.1, h + rise * 1.1), (1.1, 1.1, 0.2), TRIM))
    if garage:
        gx = w / 2 + garage / 2
        parts.append(bx((gx, 0, h * 0.34), (garage, d * 0.9, h * 0.68), wall))
        parts.append(bx((gx, 0, h * 0.7), (garage + 0.5, d * 0.95, 0.3), roof))
        parts.append(bx((gx, d * 0.45 + 0.05, h * 0.27), (garage * 0.8, 0.1, h * 0.5), WHT))
        for i in range(4):
            parts.append(bx((gx, d * 0.45 + 0.1, h * 0.1 + i * h * 0.12), (garage * 0.8, 0.06, 0.07), TRIM))
    if wing:
        parts.append(bx((-w / 2 - wing / 2, 0, h * 0.35), (wing, d * 0.8, h * 0.7), wall))
        parts.append(gable(wing, d * 0.8, h * 0.7, rise * 0.7, roof, 0.3))
        parts += window_grid(-w / 2 - wing / 2, d * 0.4, wing, h * 0.18, h * 0.55, 1, 1, 0, 1)
    if bay:
        parts.append(bx((-w * 0.22, d / 2 + 0.6, h * 0.3), (2.6, 1.2, h * 0.5), wall))
        parts.append(bx((-w * 0.22, d / 2 + 0.62, h * 0.32), (2.1, 1.25, h * 0.32), GLS))
        parts.append(bx((-w * 0.22, d / 2 + 0.6, h * 0.58), (3.0, 1.5, 0.2), roof))
    if fence:
        parts += pickets(-w / 2 - wing - 0.5, w / 2 + garage + 0.5, d / 2 + 3.2, fence)
        parts += pickets(-w / 2 - wing - 0.5, -w / 2 - wing - 0.5 + 0.2, d / 2 + 1.5, 2, 1.0)
    return parts


def terrace(w, d, h, wall, roof, units=2):
    bx = bo.bx
    parts = [bx((0, 0, h / 2), (w, d, h), wall), gable(w, d, h, h * 0.4, roof, 0.3)]
    uw = w / units
    for u in range(units):
        x = -w / 2 + uw * (u + 0.5)
        parts.append(bx((x, d / 2 + 0.08, 1.0), (1.1, 0.18, 2.0), DOOR))
        parts.append(bx((x, d / 2 + 0.5, 0.12), (1.8, 0.9, 0.24), WALK))
        parts.append(bx((x + uw * 0.28, 0, h + h * 0.28), (0.8, 0.8, h * 0.4), WB))
        parts += window_grid(x, d / 2, uw, h * 0.15, h * 0.85, 2, 2, 0, 1)
        parts += window_grid(x, -d / 2, uw, h * 0.15, h * 0.85, 2, 2, 0, -1)
        parts.append(bx((x, d / 2 + 0.2, h * 0.52), (uw * 0.9, 0.25, 0.15), TRIM))
    for side in (-1, 1):
        parts += window_grid(side * w / 2, 0, d, h * 0.2, h * 0.8, 1, 2, side, 0)
    parts.append(bx((0, 0, h * 0.5), (0.2, d + 0.1, h), WB))
    return parts


def split_level(w, d, h, wall, roof):
    bx = bo.bx
    parts = [bx((-w * 0.2, 0, h * 0.55), (w * 0.6, d, h * 1.1), wall), bx((w * 0.3, 0, h * 0.35), (w * 0.4, d, h * 0.7), wall)]
    parts.append(gable(w * 0.6, d, h * 1.1, h * 0.45, roof, 0.35, cx=-w * 0.2))
    parts.append(gable(w * 0.4, d, h * 0.7, h * 0.35, roof, 0.35, cx=w * 0.3))
    parts += window_grid(-w * 0.2, d / 2, w * 0.6, h * 0.2, h * 0.95, 2, 2, 0, 1)
    parts += window_grid(w * 0.3, d / 2, w * 0.4, h * 0.15, h * 0.55, 2, 1, 0, 1)
    parts += window_grid(-w * 0.2, -d / 2, w * 0.6, h * 0.2, h * 0.95, 2, 2, 0, -1)
    parts += window_grid(w * 0.3, -d / 2, w * 0.4, h * 0.15, h * 0.55, 2, 1, 0, -1)
    parts += window_grid(w / 2, 0, d, h * 0.15, h * 0.55, 2, 1, 1, 0)
    parts += window_grid(-w / 2, 0, d, h * 0.2, h * 0.95, 2, 2, -1, 0)
    parts.append(bx((w * 0.3, d / 2 + 0.08, 1.0), (1.1, 0.18, 2.0), DOOR))
    parts.append(bx((w * 0.3, d / 2 + 0.5, 0.12), (1.8, 0.9, 0.24), WALK))
    parts.append(bx((-w * 0.35, -d * 0.1, h * 1.1 + 2.0), (0.9, 0.9, 2.2), WB))
    parts += pickets(-w / 2, w / 2, d / 2 + 3.0, 14)
    return parts


def block(w, d, h, floors, colsf, colss, wall, roof, trim=TRIM, cx=0.0, cy_=0.0, z0=0.0, roof_cap=True, win=GLS):
    """A windowed slab: body, parapet, window grid on all four faces, a cornice per few floors."""
    bx = bo.bx
    parts = [bx((cx, cy_, z0 + h / 2), (w, d, h), wall)]
    if roof_cap:
        parts.append(bx((cx, cy_, z0 + h + 0.3), (w + 0.5, d + 0.5, 0.6), roof))
    zs, ze = z0 + h * 0.07, z0 + h * 0.97
    for sx, sy, face, cols in ((0, 1, w, colsf), (0, -1, w, colsf), (1, 0, d, colss), (-1, 0, d, colss)):
        parts += window_grid(cx + sx * w / 2, cy_ + sy * d / 2, face, zs, ze, cols, floors, sx, sy, win, depth=0.1,
                             sill=False)
    for i in range(1, 4):
        parts.append(bx((cx, cy_, z0 + h * i / 4), (w + 0.3, d + 0.3, 0.25), trim))
    return parts


def shop_front(cx, y, width, wall_h, awning, awning_s, glaze=GLS, door=DOOR, panes=4):
    """A ground floor shop front on a wall facing +y at depth y: glazing, door, awning, fascia."""
    bx = bo.bx
    parts = []
    gw = width * 0.62
    parts.append(bx((cx - width * 0.12, y + 0.05, wall_h * 0.5), (gw, 0.14, wall_h * 0.62), glaze))
    for i in range(panes + 1):
        parts.append(bx((cx - width * 0.12 - gw / 2 + gw * i / panes, y + 0.1, wall_h * 0.5), (0.12, 0.12, wall_h * 0.66), TRIM))
    parts.append(bx((cx + width * 0.32, y + 0.06, wall_h * 0.4), (width * 0.16, 0.16, wall_h * 0.8), door))
    parts.append(bx((cx, y + 0.9, wall_h * 0.95), (width * 0.98, 1.8, 0.2), awning_s))
    for i in range(6):
        parts.append(bx((cx - width * 0.45 + width * 0.9 * i / 5, y + 1.7, wall_h * 0.88), (width * 0.12, 0.1, 0.3), awning_s))
    parts.append(bx((cx, y + 0.12, wall_h * 1.08), (width * 0.98, 0.2, 0.7), TRIM))
    return parts


def tower(w, d, h, floors, wall, glass, steps=0, crown=False, twin=False, slab=False):
    bx, cy, cn, sp, pg, tor = P()
    parts = []
    if twin:
        for sx in (-1, 1):
            parts += block(w * 0.4, d, h, 9, 3, 3, wall, MDK, cx=sx * w * 0.3, win=glass)
        parts.append(bx((0, 0, h * 0.62), (w * 0.22, d * 0.5, 2.0), glass))
        parts.append(bx((0, 0, h * 0.62 - 1.2), (w * 0.22, d * 0.55, 0.3), MDK))
        return parts
    if steps:
        z, ww, dd = 0.0, w, d
        for i in range(steps):
            hh = h / steps * (1.15 - 0.1 * i)
            parts += block(ww, dd, hh, max(3, floors // steps), 4, 3, wall, MDK, z0=z, win=glass)
            z += hh
            ww *= 0.78
            dd *= 0.78
    else:
        parts += block(w, d, h, floors, 6 if slab else 5, 3 if slab else 4, wall, MDK, win=glass)
    if crown:
        parts.append(bx((0, 0, h + 1.2), (w * 0.8, d * 0.8, 2.4), GLOW))
        parts.append(bx((0, 0, h + 3.0), (w * 0.5, d * 0.5, 1.2), GLOW))
        parts.append(bx((0, 0, h + 4.4), (0.4, 0.4, 3.0), MET))
    else:
        parts.append(bx((0, 0, h + 1.4), (w * 0.4, d * 0.4, 1.6), MDK))
        parts.append(bx((0, 0, h + 3.2), (0.3, 0.3, 3.0), MET))
    return parts


def wheels(xs, y, r, z=None, w=0.6, n=10, s=RUB):
    cy = bo.cy
    z = r if z is None else z
    parts = []
    for x in xs:
        parts.append(cy((x, y, z), r, w, s, n, axis="y"))
        parts.append(cy((x, -y, z), r, w, s, n, axis="y"))
        parts.append(cy((x, y + (0.02 if y > 0 else -0.02), z), r * 0.5, w + 0.08, MET, n, axis="y"))
        parts.append(cy((x, -y - 0.02, z), r * 0.5, w + 0.08, MET, n, axis="y"))
    return parts


def car(l, w, h, body, cabin_len=0.5, estate=False, stretch=False):
    bx, cy, cn, sp, pg, tor = P()
    r = h * 0.2
    base = h * 0.3
    parts = [bx((0, 0, base + h * 0.2), (l, w, h * 0.4), body)]
    cl = l * cabin_len
    cx = -l * 0.05 if not estate else -l * 0.1
    parts.append(bx((cx, 0, base + h * 0.55), (cl, w * 0.9, h * 0.38), body))
    parts.append(bx((cx, 0, base + h * 0.57), (cl * 1.02, w * 0.93, h * 0.2), GLS))
    parts.append(bx((cx + cl / 2 + 0.2, 0, base + h * 0.5), (0.3, w * 0.8, h * 0.3), GLS))
    parts.append(bx((cx - cl / 2 - 0.1, 0, base + h * 0.5), (0.3, w * 0.8, h * 0.25), GLS))
    for sy in (-1, 1):
        parts.append(bx((cx, sy * (w / 2 + 0.02), base + h * 0.2), (cl * 0.9, 0.08, 0.1), TRIM))
        parts.append(bx((l * 0.25, sy * (w / 2 + 0.03), base + h * 0.28), (0.5, 0.1, 0.2), MDK))
        parts.append(bx((l / 2 + 0.03, sy * w * 0.32, base + h * 0.27), (0.1, 0.5, 0.25), YEL))
        parts.append(bx((-l / 2 - 0.03, sy * w * 0.32, base + h * 0.27), (0.1, 0.5, 0.25), RED))
        parts.append(bx((l * 0.35, sy * (w / 2 - 0.2), base + h * 0.42), (0.35, 0.3, 0.2), body))
    parts.append(bx((l / 2 + 0.05, 0, base + h * 0.1), (0.15, w * 0.85, 0.25), MDK))
    parts.append(bx((-l / 2 - 0.05, 0, base + h * 0.1), (0.15, w * 0.85, 0.25), MDK))
    ws = (-l * 0.3, l * 0.3) if not stretch else (-l * 0.38, -l * 0.1, l * 0.3)
    parts += wheels(ws, w / 2 - 0.1, r, r, 0.5, 10)
    return parts


def tree_canopy(r, z, lobes, s, sq=1.0):
    sp = bo.sp
    parts = [sp((0, 0, z), r, s, (1, 1, sq), 1)]
    for i in range(lobes):
        a = 2 * math.pi * i / lobes
        parts.append(sp((math.cos(a) * r * 0.75, math.sin(a) * r * 0.75, z - r * 0.15 + (i % 2) * r * 0.2), r * 0.6, s,
                        (1, 1, sq), 1))
    return parts


# ---------------------------------------------------------------------------------------------- recipes

def all_recipes(fronts=None) -> dict:
    bx, cy, cn, sp, pg, tor = P()
    out = {}

    # ===== Building kit: houses (6)
    out["ck_house_semi_garage"] = house(10, 10, 6.5, WA, ROOF, cols=3, garage=4, fence=14, porch=True)
    out["ck_house_bungalow"] = house(12, 9, 4.2, WB, ROOFB, floors=1, cols=4, fence=16, hip=True, steps=True)
    out["ck_house_gable_fence"] = house(10, 10, 6.5, WC, ROOF, cols=3, fence=22, porch=True, side_gable=False)
    out["ck_house_corner_bay"] = house(10, 9, 6.0, WA, ROOFB, cols=3, bay=True, garage=4, wing=0, fence=10, hip=True)
    out["ck_house_terrace_pair"] = terrace(20, 9, 7.0, WB, ROOF, 2)
    out["ck_house_split_level"] = split_level(17, 10, 6.0, WC, ROOFB)

    # ===== Mid-rise (6) and towers (4)
    def midrise(w, d, h, floors, wall, **kw):
        return block(w, d, h, floors, kw.get("cf", 6), kw.get("cs", 4), wall, MDK)

    out["ck_midrise_brick_8"] = midrise(18, 16, 32, 8, WB, cf=6, cs=5) + [bx((0, 8.3, 1.2), (3.0, 0.5, 2.4), DOOR)]
    parts = midrise(18, 16, 38, 10, WA, cf=5, cs=4)
    for f in range(1, 10, 2):
        parts.append(bx((0, 8.5, f * 3.8 + 0.4), (14, 1.0, 0.18), MDK))
        parts.append(bx((0, 8.9, f * 3.8 + 1.0), (14, 0.1, 1.1), TRIM))
    out["ck_midrise_render_10"] = parts
    parts = block(20, 18, 24, 6, 6, 5, WC, MDK) + block(15.6, 14, 18, 5, 5, 4, WC, MDK, z0=24, roof_cap=True)
    out["ck_midrise_setback"] = parts
    parts = block(36, 8, 24, 5, 6, 3, WB, MDK, cy_=11) + block(8, 22, 24, 5, 2, 4, WB, MDK, cx=-14) \
        + block(8, 22, 24, 5, 2, 4, WB, MDK, cx=14)
    out["ck_midrise_courtyard"] = parts
    parts = block(24, 24, 36, 9, 6, 6, WA, MDK)
    parts += [bx((0, 12.6, 40), (6, 0.4, 6), WHT), cy((0, 12.9, 40), 2.4, 0.2, TRIM, 12, axis="y"),
              bx((0, 13.05, 40.6), (0.2, 0.1, 1.8), MDK), bx((0.5, 13.05, 40), (1.1, 0.1, 0.2), MDK),
              bx((0, 0, 40), (8, 8, 8), WC), gable(8, 8, 44, 4, ROOF, 0.3)]
    out["ck_midrise_corner_clock"] = parts
    parts = block(22, 18, 40, 9, 5, 4, WC, MDK, z0=5)
    parts += [bx((0, 0, 2.5), (22.4, 18.4, 5), WA)]
    parts += shop_front(0, 9.2, 22, 5.0, 1.0, RED, panes=6)[:0]
    parts += [bx((x, 9.25, 2.6), (3.2, 0.2, 3.0), GLS) for x in (-7, -2.5, 2.5, 7)]
    parts += [bx((0, 10.0, 5.2), (21.6, 1.6, 0.2), RED)] + [bx((x, 10.7, 4.8), (1.4, 0.1, 0.4), RED) for x in range(-9, 10, 3)]
    out["ck_midrise_mixed"] = parts
    out["ck_tower_slab"] = tower(26, 14, 52, 12, WA, GLS, slab=True)
    out["ck_tower_stepped"] = tower(24, 24, 56, 15, WC, GLS, steps=3)
    out["ck_tower_twin"] = tower(40, 16, 58, 14, WB, GLS, twin=True)
    out["ck_tower_crown"] = tower(22, 22, 60, 13, WA, GLS, crown=True)

    # ===== Shops and shop rows (9): theme-atlas body plus fronts cells for sign and facade faces (see run())
    out.update(shops(fronts))

    # ===== Street kit (11)
    out["ck_road_marking_dash"] = [bx((x, 0, 0.03), (0.9, 0.35, 0.06), LINE) for x in (-1.35, 0, 1.35)] \
        + [bx((x, 0, 0.0), (0.9, 0.35, 0.02), ASPH) for x in (-1.35, 0, 1.35)]
    out["ck_road_marking_arrow"] = [bx((-0.6, 0, 0.03), (1.6, 0.4, 0.06), LINE),
                                    bo.pg((0.9, 0, 0.0), [(-0.8, -0.8), (0.8, 0), (-0.8, 0.8)], 0.06, LINE, axis="z"),
                                    bx((0, 0, -0.02), (3.2, 1.6, 0.04), ASPH)]
    out["ck_crossing_zebra"] = [bx((0, -2.0 + i * 0.8, 0.03), (8, 0.5, 0.06), LINE) for i in range(6)] \
        + [bx((0, 0, 0.0), (8, 5, 0.02), ASPH)]
    out["ck_kerb_corner"] = [cy((0, 0, 0.2), 3.0, 0.4, KERB, 12, r2=2.9), cy((0, 0, 0.45), 2.4, 0.1, WALK, 12),
                             bx((2.2, 2.2, 0.15), (1.2, 1.2, 0.3), KERB), bx((0, 0, 0.0), (6, 6, 0.04), ASPH)]
    out["ck_street_sign"] = [cy((0, 0, 1.5), 0.06, 3.0, MET, 8), bx((0, 0.08, 3.0), (1.4, 0.06, 0.8), BLU),
                             bx((0, 0.12, 3.0), (1.0, 0.04, 0.12), WHT), bx((0, 0.12, 3.05), (0.12, 0.04, 0.4), WHT),
                             cy((0, 0, 0.05), 0.2, 0.1, MDK, 8), sp((0, 0, 3.4), 0.08, MET, (), 1)]
    out["ck_planter_box"] = [bx((0, 0, 0.5), (2.8, 1.2, 1.0), WOOD), bx((0, 0, 1.02), (2.5, 0.95, 0.06), SOIL)] \
        + [bx((x, 0, 1.0 + 0.1 * i), (0.14, 1.2, 0.1), TRIM) for i, x in enumerate((-1.0, 0, 1.0))] \
        + [sp((x, 0, 1.4), 0.42, LEAF, (1, 1, 0.85), 1) for x in (-0.8, 0, 0.8)] \
        + [bx((x, 0, 0.5), (0.1, 1.24, 0.9), MDK) for x in (-1.4, 1.4)]
    out["ck_bollard"] = [cy((0, 0, 0.5), 0.2, 1.0, MET, 10, r2=0.17), sp((0, 0, 1.0), 0.19, MET, (1, 1, 0.6), 1),
                         cy((0, 0, 0.7), 0.205, 0.1, YEL, 10), cy((0, 0, 0.04), 0.26, 0.08, MDK, 10),
                         cy((0, 0, 0.45), 0.21, 0.06, MDK, 10)]
    out["ck_railing_section"] = [bx((x, 0, 1.6), (0.14, 0.14, 3.2), MDK) for x in (-2.6, 2.6)] \
        + [bx((0, 0, 3.1), (5.4, 0.18, 0.14), MDK), bx((0, 0, 0.5), (5.4, 0.14, 0.12), MDK)] \
        + [bx((-2.2 + 0.55 * i, 0, 1.8), (0.08, 0.08, 2.4), MET) for i in range(9)] \
        + [bx((x, 0, 0.1), (0.5, 0.5, 0.2), KERB) for x in (-2.6, 2.6)]
    out["ck_bus_stop_pole"] = [cy((0, 0, 1.9), 0.08, 3.8, MET, 8), cy((0, 0, 0.06), 0.28, 0.12, MDK, 8),
                               bx((0, 0.04, 3.2), (0.9, 0.08, 1.0), YEL), bx((0, 0.09, 3.3), (0.5, 0.04, 0.4), MDK),
                               cy((0, 0.1, 3.0), 0.12, 0.04, MDK, 8, axis="y"),
                               bx((0, 0.04, 2.5), (0.7, 0.06, 0.4), WHT), bx((0, 0, 3.78), (0.3, 0.3, 0.1), MDK),
                               bx((0, 0, 1.0), (0.2, 0.2, 0.5), RED)]
    out["ck_street_lamp_double"] = [cy((0, 0, 4.8), 0.14, 9.6, MDK, 8, r2=0.1), cy((0, 0, 0.15), 0.35, 0.3, MDK, 8),
                                    bx((0, 0, 9.3), (4.0, 0.14, 0.14), MDK), bx((0, 0, 9.0), (1.2, 0.2, 0.3), MDK),
                                    bx((-2.0, 0, 9.1), (1.0, 0.5, 0.25), GLOW), bx((2.0, 0, 9.1), (1.0, 0.5, 0.25), GLOW),
                                    bx((-2.0, 0, 9.3), (1.2, 0.6, 0.12), MDK), bx((2.0, 0, 9.3), (1.2, 0.6, 0.12), MDK),
                                    cy((0, 0, 2.0), 0.19, 0.2, MET, 8), cy((0, 0, 5.5), 0.17, 0.2, MET, 8),
                                    bx((0, 0.2, 4.5), (0.6, 0.06, 0.8), BLU)]
    out["ck_bin_street"] = [cy((0, 0, 0.9), 0.55, 1.8, TEAL, 10, r2=0.5), cy((0, 0, 1.85), 0.58, 0.14, MDK, 10),
                            cy((0, 0, 0.1), 0.6, 0.2, MDK, 10), bx((0, 0.5, 1.2), (0.7, 0.06, 0.5), MDK),
                            bx((0, 0.52, 1.2), (0.5, 0.04, 0.3), WHT), cy((0, 0, 2.0), 0.15, 0.1, MET, 8)]

    # ===== Park (16)
    out["ck_tree_oak"] = [cy((0, 0, 3.0), 0.7, 6.0, BARK, 8, r2=0.55)] + tree_canopy(4.0, 10.0, 5, LEAF, 0.8) \
        + [bx((0, 0, 0.2), (2.2, 2.2, 0.4), BARK)] + [sp((2.5, 1.5, 8.2), 1.8, LDK, (), 1), sp((-2.4, -1.4, 8.0), 1.7, LDK, (), 1)]
    out["ck_tree_pine"] = [cy((0, 0, 1.5), 0.45, 3.0, BARK, 8)] + [cy((0, 0, 3.0 + i * 3.2), 3.6 - i * 0.65, 3.4, LDK if i % 2 else LEAF, 10, r2=2.9 - i * 0.65) for i in range(5)] + [cn((0, 0, 19.0), 0.7, 2.0, LEAF, 8)]
    out["ck_tree_birch"] = [cy((0, 0, 2.6), 0.28, 5.2, WHT, 8, r2=0.22)] + [bx((0, 0.25, 0.5 + i * 0.9), (0.4, 0.06, 0.1), MDK) for i in range(5)] + tree_canopy(2.2, 7.0, 4, LEAF, 1.3)
    out["ck_bush"] = [sp((0, 0, 1.1), 1.4, LEAF, (1, 1, 0.8), 1)] + [sp((math.cos(a) * 1.0, math.sin(a) * 1.0, 0.8), 0.8, LDK if i % 2 else LEAF, (), 1) for i, a in enumerate([0, 1.2, 2.5, 3.8, 5.0])]
    out["ck_hedge_row"] = [bx((0, 0, 1.0), (6, 1.6, 2.0), LDK), bx((0, 0, 2.05), (5.8, 1.4, 0.2), LEAF)] + [sp((x, 0.85, 1.5), 0.55, LEAF, (), 1) for x in (-2.4, -0.8, 0.8, 2.4)] + [sp((x, -0.85, 1.5), 0.55, LEAF, (), 1) for x in (-2.4, -0.8, 0.8, 2.4)] + [bx((x, 0, 0.1), (0.5, 1.7, 0.2), SOIL) for x in (-2.8, 0, 2.8)]
    out["ck_flower_bed"] = [bx((0, 0, 0.3), (3.6, 2.0, 0.6), WOOD), bx((0, 0, 0.62), (3.3, 1.7, 0.06), SOIL)] + [sp((-1.2 + 0.4 * i % 2.4 + 0.0, -0.5 + 0.5 * (i % 3), 0.85), 0.22, (PNK, YEL, RED, ORG)[i % 4], (), 0) for i in range(12)] + [bx((-1.2 + 0.4 * i, -0.5 + 0.5 * (i % 3), 0.72), (0.05, 0.05, 0.25), LEAF) for i in range(6)]
    out["ck_picnic_blanket"] = [bx((0, 0, 0.04), (2.8, 2.2, 0.08), RED)] + [bx((-1.1 + 0.55 * i, 0, 0.09), (0.28, 2.2, 0.03), WHT) for i in range(5)]
    out["ck_picnic_basket"] = [bx((0, 0, 0.4), (1.2, 0.8, 0.7), WOOD), bx((0, 0, 0.78), (1.3, 0.9, 0.12), ORG), tor((0, 0, 0.98), 0.4, 0.05, WOOD, 10, 4, True), bx((0.3, 0.42, 0.45), (0.3, 0.05, 0.3), WHT), cy((-0.2, 0, 1.0), 0.12, 0.3, RED, 8), bx((0, 0, 0.5), (1.24, 0.84, 0.08), BARK), cn((0.35, 0, 1.0), 0.14, 0.4, LEAF, 6), bx((0, 0.41, 0.6), (1.0, 0.04, 0.1), WHT)]
    out["ck_swing_set"] = [bx((x, y, 2.3), (0.2, 0.2, 4.6), MDK, 0) for x in (-3.4, 3.4) for y in (-1.5, 1.5)] + [cy((0, 0, 4.5), 0.14, 7.0, MDK, 8, axis="x")] + [bx((x, 0, 2.2), (0.04, 0.04, 3.8), MET) for x in (-2.0, -1.4, 1.4, 2.0)] + [bx((x, 0, 0.5), (1.2, 0.5, 0.12), YEL) for x in (-1.7, 1.7)] + [bx((x, 0, 0.12), (1.8, 3.4, 0.1), SAND) for x in (-1.7, 1.7)] + [bx((x, 0, 0.1), (0.5, 3.4, 0.2), MDK) for x in (-3.4, 3.4)]
    out["ck_slide"] = [bx((x, 0, 2.0), (0.14, 0.14, 4.0), MET) for x in (-2.3, -1.6)] + [bx((-1.95, y, 2.0), (0.14, 0.14, 4.0), MET) for y in (-0.5, 0.5)] + [bx((-1.95, 0, 3.9), (1.2, 1.2, 0.15), ORG)] + [bx((-1.95, 0, 0.4 + i * 0.7), (1.2, 0.08, 0.1), MET) for i in range(5)] + [bx((1.2 + 0.0, 0, 2.2), (4.5, 1.0, 0.12), YEL, 0)] + [bx((1.2, y, 2.4), (4.5, 0.1, 0.4), YEL) for y in (-0.55, 0.55)] + [bx((3.5, 0, 0.8), (1.0, 1.0, 0.1), SAND), bx((-1.95, 0.6, 4.4), (1.2, 0.1, 0.8), BLU), bx((-1.95, -0.6, 4.4), (1.2, 0.1, 0.8), BLU), bx((-1.95, 0, 0.1), (3.0, 2.0, 0.2), SAND)]
    out["ck_seesaw"] = [bx((0, 0, 0.7), (3.8, 0.4, 0.12), ORG, 0), bx((0, 0, 0.35), (0.3, 0.8, 0.7), MDK), cy((0, 0, 0.7), 0.16, 0.7, MET, 8, axis="y"), bx((-1.6, 0, 0.9), (0.14, 0.7, 0.14), MET), bx((1.6, 0, 0.9), (0.14, 0.7, 0.14), MET), bx((-1.8, 0, 0.85), (0.5, 0.5, 0.1), YEL), bx((1.8, 0, 0.85), (0.5, 0.5, 0.1), YEL), cy((-1.85, 0, 0.1), 0.4, 0.2, RUB, 8), cy((1.85, 0, 0.1), 0.4, 0.2, RUB, 8), bx((0, 0, 0.05), (0.7, 1.0, 0.1), SAND)]
    out["ck_climbing_frame"] = [bx((x, y, 2.5), (0.24, 0.24, 5.0), BLU) for x in (-3.8, 3.8) for y in (-2.3, 2.3)] + [bx((0, y, 4.9), (7.8, 0.24, 0.24), BLU) for y in (-2.3, 2.3)] + [bx((x, 0, 4.9), (0.24, 4.8, 0.24), BLU) for x in (-3.8, 3.8)] + [bx((-3.5 + i * 0.7, 2.3, 2.5), (0.1, 0.1, 4.6), RED) for i in range(11)] + [bx((0, 2.3, 0.6 + i * 0.8), (7.4, 0.1, 0.1), RED) for i in range(5)] + [bx((x, 0, 2.6), (0.4, 4.4, 0.1), WOOD) for x in (-3.8, 3.8)] + [bx((0, 0, 0.1), (8, 5, 0.2), SAND)]
    out["ck_sandpit"] = [bx((0, y, 0.25), (5, 0.4, 0.5), WOOD) for y in (-2.3, 2.3)] + [bx((x, 0, 0.25), (0.4, 4.2, 0.5), WOOD) for x in (-2.3, 2.3)] + [bx((0, 0, 0.2), (4.2, 4.2, 0.2), SAND), sp((0.8, 0.6, 0.45), 0.5, SAND, (1, 1, 0.5), 0), bx((-0.9, -0.5, 0.42), (0.5, 0.4, 0.3), RED)]
    out["ck_path_straight"] = [bx((0, 0, 0.05), (8, 2.4, 0.1), WALK)] + [bx((-3.4 + i * 1.7, 0, 0.12), (1.5, 2.1, 0.04), KERB) for i in range(5)]
    segs = 8
    out["ck_path_curve"] = [bx((math.cos(math.pi / 2 * (i + 0.5) / segs) * 5.4, math.sin(math.pi / 2 * (i + 0.5) / segs) * 5.4, 0.05), (1.5, 2.4, 0.1), WALK, math.pi / 2 * (i + 0.5) / segs + math.pi / 2) for i in range(segs)]
    out["ck_pond_edge"] = [cy((0, 0, 0.05), 4.4, 0.1, WATER, 14)] + [sp((math.cos(a) * 4.5, math.sin(a) * 4.5, 0.3), 0.7 + 0.15 * (i % 3), KERB, (1, 1, 0.6), 1) for i, a in enumerate([k * 2 * math.pi / 14 for k in range(14)])] + [cy((0, 0, 0.1), 0.4, 0.04, LEAF, 8), cy((1.5, 1.0, 0.1), 0.3, 0.04, LEAF, 8)]

    # ===== Suburbs (7)
    out["ck_barbecue"] = [sp((0, 0, 1.6), 0.85, MDK, (1, 1, 0.8), 1), cy((0, 0, 1.2), 0.85, 0.2, MDK, 10), sp((0, 0, 1.9), 0.4, MDK, (), 0)] + [cy((math.cos(a) * 0.6, math.sin(a) * 0.6, 0.55), 0.04, 1.1, MET, 6) for a in (0.5, 2.6, 4.7)] + [bx((1.0, 0, 1.9), (0.8, 0.1, 0.1), WOOD), cy((0, 0, 0.1), 0.65, 0.04, MET, 8), bx((0, 0, 1.0), (0.6, 0.6, 0.1), MET), cy((0, 0, 2.15), 0.08, 0.2, MET, 6), tor((0, 0, 0.9), 0.5, 0.03, MET, 10, 3), bx((0.9, 0, 1.0), (0.5, 0.3, 0.06), WOOD)]
    out["ck_lawn_mower"] = [bx((0, 0, 0.7), (1.8, 1.2, 0.8), RED), bx((0.3, 0, 1.2), (1.0, 0.9, 0.25), MDK), bx((-1.3, 0, 1.5), (0.1, 0.1, 1.6), MET, 0), bx((-1.5, 0, 2.2), (0.15, 1.2, 0.1), MDK), bx((-1.0, 0, 1.0), (0.3, 0.3, 0.5), MET)] + wheels((-0.7, 0.7), 0.7, 0.3, 0.3, 0.2, 8) + [bx((1.0, 0, 0.5), (0.8, 1.3, 0.12), MDK), bx((-1.35, 0, 1.0), (0.1, 0.1, 1.0), MET), bx((-1.5, 0.4, 2.1), (0.1, 0.1, 0.5), MET), bx((-1.5, -0.4, 2.1), (0.1, 0.1, 0.5), MET), bx((0.2, 0.7, 0.4), (1.4, 0.06, 0.25), YEL)]
    out["ck_garden_fence"] = pickets(-3, 3, 0, 14, 2.2, WHT, 0.3) + [bx((x, 0, 1.2), (0.3, 0.3, 2.4), WHT) for x in (-3.1, 3.1)] + [bx((x, 0, 2.5), (0.4, 0.4, 0.15), TRIM) for x in (-3.1, 3.1)] + [bx((0, 0.14, 0.45), (6, 0.08, 0.14), WHT), bx((0, 0.14, 1.7), (6, 0.08, 0.14), WHT)] + [bo.pg((-2.7 + 0.425 * i, 0, 2.2), [(-0.15, 0), (0.15, 0), (0, 0.3)], 0.16, WHT) for i in range(14)]
    out["ck_trampoline"] = [cy((0, 0, 1.2), 3.0, 0.15, BLU, 14), cy((0, 0, 1.25), 2.6, 0.1, MDK, 14)] + [bx((math.cos(a) * 2.8, math.sin(a) * 2.8, 0.6), (0.14, 0.14, 1.2), MET) for a in [k * math.pi / 3 + 0.3 for k in range(6)]] + [bx((math.cos(a) * 3.0, math.sin(a) * 3.0, 2.0), (0.1, 0.1, 1.6), MET) for a in [k * math.pi / 4 for k in range(8)]] + [tor((0, 0, 2.7), 3.0, 0.06, YEL, 14, 3)] + [bx((math.cos(a) * 3.0, math.sin(a) * 3.0, 1.9), (0.04, 0.04, 1.4), MDK) for a in [k * math.pi / 8 for k in range(16)]]
    out["ck_garden_shed"] = [bx((0, 0, 2.2), (6.4, 4.8, 4.4), WOOD), gable(6.4, 4.8, 4.4, 1.6, ROOFB, 0.5), bx((0, 2.45, 1.7), (1.6, 0.14, 3.4), DOOR), bx((1.9, 2.45, 2.4), (1.2, 0.14, 1.0), GLS), bx((1.9, 2.5, 2.4), (1.4, 0.1, 0.12), WHT)] + [bx((-3.0 + i * 0.5, 2.43, 2.2), (0.06, 0.06, 4.4), BARK) for i in range(13)] + [bx((x, 2.47, 3.4), (0.2, 0.1, 1.2), WHT) for x in (-0.9, 0.9)] + [bx((0, 0, 0.1), (6.8, 5.2, 0.2), KERB), bx((0, 0, 5.2), (0.5, 0.5, 1.0), MDK), bx((-3.25, 0, 2.5), (0.1, 2.0, 1.2), GLS), bx((3.25, 0, 2.5), (0.1, 2.0, 1.2), GLS)]
    out["ck_car_sedan"] = car(15, 6, 4.8, BLU, 0.5)
    out["ck_car_estate"] = car(16, 6, 5.2, TEAL, 0.65, estate=True)

    # ===== Main street (5)
    out["ck_cafe_table_parasol"] = [cy((0, 0, 1.9), 1.4, 0.12, WOOD, 10), cy((0, 0, 0.95), 0.1, 1.9, MDK, 8), cy((0, 0, 0.05), 0.7, 0.1, MDK, 10)] + [cy((x, y, 0.75), 0.5, 0.1, WHT, 8) for x, y in ((-2.0, 0.0), (2.0, 0.0))] + [bx((x, y, 0.37), (0.1, 0.1, 0.75), MDK) for x in (-2.0, 2.0) for y in (-0.3, 0.3)] + [bx((x + s * 0.5, 0, 1.4), (0.1, 0.9, 0.9), WHT) for x in (-2.0, 2.0) for s in (-1,)] + [cn((0, 0, 4.8), 2.6, 1.0, YEL, 8), cy((0, 0, 3.0), 0.06, 4.0, MET, 6), cy((0, 0, 4.5), 2.5, 0.1, WHT, 8), sp((0, 0, 5.4), 0.15, MET, (), 0)] + [cn((0, 0, 4.2 + 0.0), 2.4, 0.2, i, 8, yaw=0.4) for i in (RED,)]
    out["ck_fruit_crates"] = [bx((x, y, 0.4), (1.2, 0.9, 0.8), WOOD) for x in (-0.65, 0.65) for y in (-0.5, 0.5)] + [bx((0, 0, 1.2), (1.2, 0.9, 0.8), WOOD)] + [sp((x, y, 0.85), 0.2, c, (), 0) for x, y, c in ((-0.8, -0.6, RED), (-0.4, -0.3, RED), (0.6, -0.5, YEL), (0.8, -0.2, ORG), (-0.7, 0.5, LEAF), (-0.4, 0.4, LEAF), (0.5, 0.6, ORG), (0.9, 0.5, PNK))] + [bx((x, y, 0.82), (1.15, 0.06, 0.06), BARK) for x in (-0.65, 0.65) for y in (-0.5, 0.5)] + [sp((0.1, 0.0, 1.7), 0.22, RED, (), 0), sp((-0.2, 0.1, 1.7), 0.22, YEL, (), 0)] + [bx((0, 0, 0.05), (2.6, 1.9, 0.1), MDK)]
    out["ck_sandwich_board"] = [bx((0, 0.55, 1.6), (1.6, 0.12, 3.0), WOOD, 0), bx((0, 0.57, 1.7), (1.3, 0.04, 1.9), MDK), bx((0, 0.6, 2.2), (0.8, 0.02, 0.1), WHT), bx((0, 0.6, 1.7), (0.1, 0.02, 0.9), WHT), bx((0, -0.55, 1.6), (1.6, 0.12, 3.0), WOOD), bx((0, 0, 3.1), (1.7, 1.3, 0.14), WOOD), bx((-0.8, 0, 1.3), (0.1, 1.2, 0.1), MDK), bx((0.8, 0, 1.3), (0.1, 1.2, 0.1), MDK), bx((0, 0, 0.06), (1.8, 1.4, 0.12), MDK), sp((0.4, 0.62, 1.2), 0.2, YEL, (1, 0.3, 1), 0), bx((-0.3, 0.6, 1.2), (0.3, 0.02, 0.3), RED), bx((0, 0.6, 0.9), (1.0, 0.02, 0.08), WHT)]
    out["ck_bike_rack"] = [tor((-1.35 + 0.9 * i, 0, 0.7), 0.6, 0.05, MET, 8, 4, True) for i in range(4)] + [bx((0, 0, 0.07), (3.6, 0.3, 0.14), MDK), bx((-1.7, 0, 0.5), (0.1, 0.1, 1.0), MDK), bx((1.7, 0, 0.5), (0.1, 0.1, 1.0), MDK), bx((0, 0, 1.3), (3.4, 0.1, 0.1), MDK)] + [bx((-1.35 + 0.9 * i, 0, 1.28), (0.14, 0.14, 0.12), YEL) for i in range(4)] + [bx((x, 0, 0.55), (0.08, 0.5, 0.08), MET) for x in (-1.8, 1.8)]
    out["ck_post_box"] = [cy((0, 0, 1.3), 0.7, 2.6, RED, 10), sp((0, 0, 2.6), 0.7, RED, (1, 1, 0.55), 1), cy((0, 0, 0.1), 0.78, 0.2, MDK, 10), bx((0, 0.6, 1.9), (0.9, 0.1, 0.18), MDK), bx((0, 0.68, 1.1), (0.7, 0.04, 0.5), MDK), cy((0, 0, 2.95), 0.12, 0.1, MDK, 8), bx((0, 0.7, 1.9), (0.6, 0.02, 0.05), WHT), bx((0, 0.7, 0.6), (0.3, 0.02, 0.2), YEL), bx((0, 0, 1.0), (1.45, 0.06, 0.1), MDK), cy((0, 0, 2.2), 0.72, 0.1, MDK, 10), bx((0.5, 0.45, 1.5), (0.1, 0.1, 0.6), MDK), bx((-0.5, 0.45, 1.5), (0.1, 0.1, 0.6), MDK)]

    # ===== Downtown (6)
    clock = [bx((0, 0, 8), (10, 10, 16), WB), bx((0, 0, 22), (8, 8, 12), WB), bx((0, 0, 29), (9, 9, 2), TRIM), bx((0, 0, 36), (7, 7, 12), WC), gable(7, 7, 42, 6, ROOF, 0.6, 0.0)] \
        + [bx((x, y, 16.4), (0.9, 0.9, 7.4), WC) for x in (-4.6, 4.6) for y in (-4.6, 4.6)] \
        + [bx((0, 4.2, 5.0), (3.0, 0.4, 4.4), DOOR), bx((0, 0, 0.5), (11, 11, 1.0), KERB), bx((0, 0, 16.4), (11, 11, 0.8), TRIM), bx((0, 0, 42.1), (0.3, 0.3, 4.0), MET)]
    for sx, sy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        yaw = 0 if sx == 0 else math.pi / 2
        clock += [cy((sx * 3.55, sy * 3.55, 36.5), 2.4, 0.3, WHT, 14, axis="x" if sx else "y"), bx((sx * 3.75, sy * 3.75, 37.6), (0.2 if sx else 0.2, 0.2 if sx else 0.2, 1.8), MDK, yaw),
                  bx((sx * 3.75, sy * 3.75, 36.5), (0.2, 1.2, 0.2) if sx else (1.2, 0.2, 0.2), MDK)]
        clock += window_grid(sx * 5.0, sy * 5.0, 8.0, 4.0, 14.0, 2, 3, sx, sy, GLS, depth=0.1, sill=False)
        clock += window_grid(sx * 4.0, sy * 4.0, 6.0, 20.0, 27.0, 2, 2, sx, sy, GLS, depth=0.1, sill=False)
    out["ck_landmark_clock_tower"] = clock
    out["ck_landmark_obelisk"] = [bx((0, 0, 0.6), (8, 8, 1.2), KERB), bx((0, 0, 1.8), (6.4, 6.4, 1.2), KERB), bx((0, 0, 3.2), (5, 5, 1.6), WC), cy((0, 0, 20), 1.9, 33.6, WC, 4, r2=0.9, yaw=math.pi / 4), cn((0, 0, 38.0), 0.9, 3.0, MET, 4, yaw=math.pi / 4)] \
        + [bx((0, y * 2.2, 0.05), (8.4, 0.1, 0.1), MDK) for y in (-1, 1)] + [bx((x * 4.4, y * 4.4, 0.7), (0.9, 0.9, 1.4), KERB) for x in (-1, 1) for y in (-1, 1)] + [cy((0, 0, 8 + i * 6), 2.0 - i * 0.28, 0.4, TRIM, 4, yaw=math.pi / 4) for i in range(5)]
    arch = [bx((-9.5, 0, 12), (6, 10, 24), WA), bx((9.5, 0, 12), (6, 10, 24), WA), bx((0, 0, 26.5), (26, 10, 7), WA), bx((0, 0, 30.8), (27, 10.6, 1.6), TRIM), bx((0, 0, 32.6), (24, 9, 2.0), WC)]
    arch += [bx((x, y, 10), (1.2, 0.5, 12), WC) for x in (-9.5, 9.5) for y in (-5.2, 5.2)]
    arch += [bx((x, 0, 24.2), (1.8, 10.4, 1.0), TRIM) for x in (-9.5, 9.5)] + [bx((0, y, 25.0), (20, 0.4, 0.4), TRIM) for y in (-5.2, 5.2)]
    arch += [bx((x, 5.3, 16.5), (3.6, 0.3, 3.0), WC) for x in (-9.5, 9.5)] + [bx((x, -5.3, 16.5), (3.6, 0.3, 3.0), WC) for x in (-9.5, 9.5)]
    arch += [bx((-12.2 + 0.0, 0, 1.0), (0.8, 10.8, 2.0), KERB), bx((12.2, 0, 1.0), (0.8, 10.8, 2.0), KERB), bx((0, 0, 0.1), (26, 10, 0.2), WALK)]
    arch += [bx((-8 + 2.0 * i, 5.4, 28.5), (1.2, 0.3, 1.6), WC) for i in range(9)] + [bx((-8 + 2.0 * i, -5.4, 28.5), (1.2, 0.3, 1.6), WC) for i in range(9)]
    arch += [cy((0, 5.2, 21.0), 3.8, 0.8, WA, 12, axis="y"), bx((0, 5.3, 18.0), (7.6, 0.8, 6.0), WA)]
    out["ck_landmark_arch"] = arch
    tram = [bx((-5.9, 0, 3.4), (11.5, 3.6, 4.2), YEL), bx((5.9, 0, 3.4), (11.5, 3.6, 4.2), YEL), bx((0, 0, 3.0), (1.2, 3.0, 3.2), MDK), bx((-5.9, 0, 5.6), (11.5, 3.2, 0.3), WHT), bx((5.9, 0, 5.6), (11.5, 3.2, 0.3), WHT)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            tram += [bx((sx * 5.9 + (i - 2.5) * 1.7, sy * 1.83, 3.9), (1.3, 0.1, 1.5), GLS) for i in range(6)]
    tram += [bx((x, sy * 1.83, 2.4), (1.5, 0.12, 2.6), DOOR) for x in (-9.0, -2.8, 2.8, 9.0) for sy in (-1, 1)]
    tram += [bx((x, 0, 6.4), (0.9, 0.9, 0.5), MDK) for x in (-6.0, 6.0)] + [bx((-6.0, 0, 7.3), (0.14, 3.0, 0.14), MET), bx((6.0, 0, 7.3), (0.14, 3.0, 0.14), MET)]
    tram += [cy((x, 1.5, 0.55), 0.55, 0.4, RUB, 10, axis="y") for x in (-9.0, -6.0, -3.0, 3.0, 6.0, 9.0)] + [cy((x, -1.5, 0.55), 0.55, 0.4, RUB, 10, axis="y") for x in (-9.0, -6.0, -3.0, 3.0, 6.0, 9.0)]
    tram += [bx((11.95, 0, 3.9), (0.1, 3.0, 1.6), GLS), bx((-11.95, 0, 3.9), (0.1, 3.0, 1.6), GLS), bx((11.9, 1.2, 1.6), (0.2, 0.6, 0.4), YEL), bx((11.9, -1.2, 1.6), (0.2, 0.6, 0.4), YEL), bx((0, 0, 1.2), (23, 3.2, 0.3), MDK), bx((-12, 0, 5.2), (0.1, 2.4, 0.5), RED), bx((12, 0, 5.2), (0.1, 2.4, 0.5), RED)]
    out["ck_tram"] = tram
    sub = [bx((0, 0, 0.3), (11, 6, 0.6), WALK), bx((-1.5, 0, 2.4), (8, 5.4, 0.3), MDK), bx((-1.5, 2.6, 1.3), (8, 0.2, 2.2), GLS), bx((-1.5, -2.6, 1.3), (8, 0.2, 2.2), GLS), bx((-5.4, 0, 1.3), (0.2, 5.2, 2.2), GLS)] + [bx((-1.5 + i * 2.6, y, 1.3), (0.3, 0.3, 2.2), MET) for i in range(4) for y in (-2.6, 2.6)] + [bx((-1.5 + i * 2.6, y, 1.3), (0.14, 0.14, 2.2), MET) for i in range(4) for y in (-2.6, 2.6)]
    sub += [bx((3.5 + 0.0, 0, 0.5 - 0.0 + i * 0.0), (3.0, 3.2, 0.1), MDK) for i in range(1)] + [bx((3.8 + i * 0.4, 0, 0.12 + i * 0.2 - 0.0), (0.4, 3.0, 0.12), KERB) for i in range(6)] + [bx((3.2 + i * 0.4, y, 1.0 + i * 0.2), (0.08, 0.08, 0.9), MET) for i in range(6) for y in (-1.6, 1.6)]
    sub += [bx((-1.5, 2.8, 2.8), (3.0, 0.3, 1.0), BLU), bx((-1.5, 3.0, 2.8), (0.5, 0.1, 0.6), WHT), bx((-1.5, 3.0, 2.8), (1.8, 0.1, 0.2), WHT), bx((-5.5, 0, 0.6), (0.3, 5.4, 1.2), KERB), bx((-1.5, 0, 0.1), (8.4, 5.6, 0.2), MDK)]
    out["ck_subway_entrance"] = sub
    out["ck_limousine"] = car(18, 5.6, 4.4, MDK, 0.28, stretch=True) + [bx((-1.0, 0, 3.1), (11, 5.0, 0.08), GLS), bx((6.0, 0, 3.0), (4.0, 4.8, 0.1), MDK)] + [bx((-3.0 + i * 2.2, 2.82, 2.2), (1.6, 0.1, 1.0), GLS) for i in range(5)] + [bx((-3.0 + i * 2.2, -2.82, 2.2), (1.6, 0.1, 1.0), GLS) for i in range(5)]

    # ===== Billboards and the buffering billboard (fronts cells)
    out.update(billboards(fronts))

    # ===== Meme originals (7); the buffering billboard is built above
    out["ck_meme_wet_floor_sign"] = [bo.pg((0, 0, 0.0), [(-0.8, 0), (0.8, 0), (0.5, 3.0), (-0.5, 3.0)], 0.12, YEL, "y", 0.5), bo.pg((0, 0, 0.0), [(-0.8, 0), (0.8, 0), (0.5, 3.0), (-0.5, 3.0)], 0.12, YEL, "y", -0.5 + math.pi), bx((0, 0, 3.05), (1.0, 0.5, 0.1), YEL), bx((0, 0.4, 1.8), (0.7, 0.04, 0.9), BLU), bx((0, 0.42, 2.2), (0.1, 0.03, 0.6), WHT), bx((0, 0.42, 1.4), (0.14, 0.03, 0.14), WHT), bx((0, -0.4, 1.8), (0.7, 0.04, 0.9), BLU), bx((0, 0, 0.06), (1.7, 1.0, 0.12), MDK), bx((0, 0, 0.0), (2.0, 1.4, 0.04), SAND), bx((0.5, 0.42, 0.6), (0.4, 0.03, 0.3), WHT), bx((-0.5, -0.42, 0.6), (0.4, 0.03, 0.3), WHT)]
    out["ck_meme_pond_cart"] = [cy((0, 0, 0.1), 3.2, 0.2, WATER, 14), bx((0, 0, 1.6), (3.0, 1.8, 1.4), MET), bx((0, 0, 1.0), (2.6, 1.5, 0.1), MDK), bx((-1.7, 0, 2.7), (0.14, 1.9, 1.0), MET), bx((-1.7, 0, 3.2), (0.2, 2.0, 0.12), MDK)] + [bx((0, y, 1.9), (3.0, 0.06, 0.1), MDK) for y in (-0.9, 0.9)] + [bx((-1.2 + 0.4 * i, 0, 2.2), (0.06, 1.8, 0.8), MET) for i in range(7)] + [cy((x, y, 0.5), 0.3, 0.2, RUB, 8, axis="y") for x in (-1.0, 1.0) for y in (-0.8, 0.8)] + [tor((0, 0, 0.3), 3.0, 0.1, WHT, 14, 3), tor((0, 0, 0.3), 2.2, 0.08, WHT, 12, 3), sp((1.8, 1.2, 0.45), 0.5, LEAF, (1, 1, 0.3), 0), bx((0.9, 0, 2.8), (0.5, 0.5, 0.2), RED)]
    # a statue: plain faceless figure (blocks only) under a traffic cone
    out["ck_meme_cone_statue"] = [bx((0, 0, 0.8), (5.0, 5.0, 1.6), KERB), bx((0, 0, 1.8), (4.0, 4.0, 0.4), WALK), bx((0, 0, 3.8), (1.4, 1.0, 3.6), WC), bx((-0.5, 0, 1.9), (0.5, 0.8, 1.2), WC), bx((0.5, 0, 1.9), (0.5, 0.8, 1.2), WC), bx((0, 0, 6.3), (2.0, 1.2, 1.8), WC), bx((-1.35, 0, 5.5), (0.5, 0.6, 1.8), WC), bx((1.35, 0, 5.5), (0.5, 0.6, 1.8), WC), sp((0, 0, 7.8), 0.75, WC, (), 1), cn((0, 0, 9.4), 0.85, 2.2, ORG, 10), cy((0, 0, 8.5), 0.78, 0.3, WHT, 10), cy((0, 0, 8.9), 0.62, 0.2, WHT, 10), cy((0, 0, 8.3), 1.0, 0.18, ORG, 10), bx((0, 0, 4.6), (1.6, 1.1, 0.2), TRIM), bx((0, 0, 6.2), (2.2, 1.3, 0.2), TRIM), bx((0, 0, 0.1), (5.4, 5.4, 0.2), KERB), bx((2.4, 0, 0.9), (0.2, 3.0, 1.2), KERB), bx((-2.4, 0, 0.9), (0.2, 3.0, 1.2), KERB)]
    out["ck_meme_phone_1pc"] = [bx((0, 0, 7.0), (6.0, 1.2, 14.0), MDK), bx((0, 0.62, 7.0), (5.4, 0.06, 12.6), GLS), bx((0, 0.66, 12.2), (1.4, 0.04, 0.3), MDK), bx((0, 0.7, 8.0), (1.8, 0.04, 3.0), RED), bx((0, 0.74, 8.0), (1.2, 0.04, 0.5), WHT), bx((0, 0.74, 8.9), (0.5, 0.04, 0.5), WHT), bx((-1.0, 0.7, 4.2), (0.8, 0.04, 0.8), WHT), bx((0, 0.7, 4.2), (0.8, 0.04, 0.8), WHT), bx((1.0, 0.7, 4.2), (0.8, 0.04, 0.8), WHT), bx((0, 0.7, 2.5), (1.4, 0.04, 0.3), WHT), bx((2.2, 0.7, 12.0), (1.2, 0.04, 0.5), RED), bx((2.5, 0.74, 12.0), (0.2, 0.04, 0.3), WHT), bx((-2.0, 0.7, 12.0), (0.2, 0.04, 0.4), WHT), bx((0, 0, 0.4), (7.0, 3.0, 0.8), KERB), bx((0, -0.7, 7.0), (1.6, 0.2, 2.0), MET), bx((3.1, 0, 8.0), (0.12, 0.3, 1.0), MDK), bx((3.1, 0, 5.5), (0.12, 0.3, 1.4), MDK)]
    out["ck_meme_banana_scale"] = [bx((0, 0, 0.6), (10, 8, 1.2), KERB), bx((-3.5, 0, 2.6), (2.0, 2.0, 2.8), WALK)] + [sp((math.cos(t) * 5.0 - 0.0, 0, 7.0 + math.sin(t) * 9.0 + 5.0), 2.0 - abs(t - 0.4) * 0.2, YEL, (1, 0.9, 1), 1) for t in [-0.9 + 0.35 * i for i in range(10)]] \
        + [cy((-1.2, 0, 3.0), 1.0, 3.0, YEL, 8, r2=1.4), cn((0, 0, 24.5), 0.9, 2.5, BARK, 6), cy((0, 0, 0.1), 0.3, 0.2, KERB, 6)] \
        + [bx((4.2, 0, 3.4), (0.5, 0.9, 1.6), TEAL), sp((4.2, 0, 4.7), 0.35, TEAL, (), 1), bx((4.2, 0, 2.2), (0.6, 0.6, 0.2), MDK), bx((-4.8, 0, 2.2), (0.2, 4.0, 0.4), TRIM), bx((4.8, 0, 2.2), (0.2, 4.0, 0.4), TRIM), bx((0, 3.8, 1.0), (9.0, 0.3, 0.3), TRIM), bx((0, -3.8, 1.0), (9.0, 0.3, 0.3), TRIM), bx((-3.5, 0, 4.2), (2.4, 2.4, 0.2), TRIM)]
    out["ck_meme_vacant_lot"] = [bx((0, 0, 0.15), (30, 30, 0.3), WALK), bx((0, 0, 0.32), (28, 28, 0.04), WALK)] + [bx((-12 + 8 * (i // 4) + 0 * j, -12 + 8 * (j // 4), 0.42), (0.9, 0.9, 0.14), KERB) for i in range(14) for j in range(14) if (i % 4 == 1 and j % 4 == 1)] + [cy((0, 0, 0.45), 2.4, 0.2, TEAL, 12), cy((0, 0, 0.57), 1.8, 0.04, WHT, 12)] + [bx(((-14.7, 14.7)[i % 2], -14 + 4 * (i // 2) * 0 + (i // 2) * 7, 0.7), (0.4, 0.4, 0.8), MDK) for i in range(8)] + [bx((0, -14.8, 0.55), (28, 0.3, 0.5), MDK), bx((0, 14.8, 0.55), (28, 0.3, 0.5), MDK), bx((-14.8, 0, 0.55), (0.3, 28, 0.5), MDK), bx((14.8, 0, 0.55), (0.3, 28, 0.5), MDK)]
    apply_detail(out)
    return out



# ---------------------------------------------------------------------------------------------- detail passes
# Style bible section 4: every prop meets its class floor. The first recipes are the silhouette; these passes add
# rounder cylinders and spheres (REFINE: segment multiplier, sphere subdivisions added) and small flat details
# (DETAIL: extra parts per id) so each mesh lands between its floor and 60 % of its tier budget.

def refine(parts, seg=1.0, sub=0, only_axis=None):
    out = []
    for part in parts:
        if part[0] == "cyl":
            part = part[:5] + (max(3, int(round(part[5] * seg))),) + part[6:]
        elif part[0] == "sph":
            part = part[:5] + (part[5] + sub,)
        out.append(part)
    return out


def shutters(cx, y, face_w, z0, z1, cols, rows, s=WA):
    bx = bo.bx
    parts = []
    cw, rh = face_w / cols, (z1 - z0) / rows
    for r in range(rows):
        for c in range(cols):
            x = cx - face_w / 2 + (c + 0.5) * cw
            z = z0 + (r + 0.5) * rh
            for sx in (-1, 1):
                parts.append(bx((x + sx * cw * 0.34, y + 0.1, z), (cw * 0.12, 0.08, rh * 0.55), s))
    return parts


def house_extra(w, d, h, cols, floors, accent=RED):
    bx, cy, cn, sp, pg, tor = P()
    parts = shutters(0, d / 2, w, h * 0.18, h * 0.82, cols, floors, accent)
    parts += [sp((x, d / 2 + 1.2, 0.6), 0.7, LEAF if i % 2 else LDK, (1, 1, 0.9), 2) for i, x in enumerate((-w * 0.42, -w * 0.12, w * 0.45))]
    parts += [bx((0, d / 2 + 0.1, h + 0.05), (w + 0.2, 0.18, 0.2), TRIM), bx((0, -d / 2 - 0.1, h + 0.05), (w + 0.2, 0.18, 0.2), TRIM)]
    parts += [bx((w * 0.2, d / 2 + 2.6 + i * 1.0, 0.05), (1.2, 0.8, 0.1), WALK) for i in range(3)]
    parts += [bx((w * 0.2 + sx * 0.65, d / 2 + 0.1, 1.05), (0.12, 0.14, 2.1), WHT) for sx in (-1, 1)]
    parts.append(bx((w * 0.2, d / 2 + 0.1, 2.1), (1.4, 0.14, 0.14), WHT))
    parts += [bx((w / 2 - 0.2, d / 2 + 0.12, h / 2), (0.14, 0.14, h), WHT), bx((-w / 2 + 0.2, d / 2 + 0.12, h / 2), (0.14, 0.14, h), WHT)]
    return parts


def car_details(l, w, h, body):
    bx = bo.bx
    base = h * 0.3
    parts = [bx((l / 2 + 0.04, 0, base + h * 0.18 + i * 0.16), (0.08, w * 0.5, 0.06), MDK) for i in range(5)]
    for sy in (-1, 1):
        parts += [bx((-l * 0.12 + dx, sy * (w / 2 + 0.05), base + h * 0.35), (0.35, 0.06, 0.1), MET) for dx in (0.0, l * 0.28)]
        parts.append(bx((l * 0.18, sy * (w / 2 + 0.12), base + h * 0.56), (0.5, 0.2, 0.28), body))
        parts.append(bx((-l * 0.05, sy * (w / 2 - 0.02), base + h * 0.4), (0.06, 0.04, h * 0.3), TRIM))
        parts.append(bx((-l * 0.28, sy * (w / 2 - 0.02), base + h * 0.4), (0.06, 0.04, h * 0.3), TRIM))
        parts += [bx((x, sy * w * 0.2, base + h * 0.76), (l * 0.3, 0.08, 0.08), MET) for x in (-l * 0.1, -l * 0.12)]
    parts += [bx((-l / 2 - 0.05, 0, base + h * 0.2), (0.1, 0.9, 0.3), WHT), bx((l / 2 + 0.05, 0, base + h * 0.03), (0.1, 0.9, 0.3), WHT)]
    parts += [bx((x, 0, base + h * 0.4 + 0.45), (0.12, 0.12, 0.12), MDK) for x in (-l * 0.2, l * 0.1)]
    return parts


def clapboard(w, d, h, y, n, s=BARK):
    return [bo.bx((-w / 2 + w * (i + 0.5) / n, y, h / 2), (0.07, 0.05, h), s) for i in range(n)]


def ring_posts(r, n, z_h, s=MDK, post=0.18):
    bx = bo.bx
    parts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        parts.append(bx((math.cos(a) * r, math.sin(a) * r, z_h / 2), (post, post, z_h), s, a))
    return parts


DETAIL = {}
REFINE = {}


def build_detail():
    bx, cy, cn, sp, pg, tor = P()
    D = DETAIL
    D["ck_house_semi_garage"] = lambda: house_extra(10, 10, 6.5, 3, 2)
    D["ck_house_bungalow"] = lambda: house_extra(12, 9, 4.2, 4, 1, BLU) + [bx((x, d, 0.05), (0.8, 0.3, 0.1), WALK) for x, d in ((-5, 6), (-3, 6))]
    D["ck_house_gable_fence"] = lambda: house_extra(10, 10, 6.5, 3, 2, TEAL)
    D["ck_house_corner_bay"] = lambda: house_extra(10, 9, 6.0, 3, 2, BLU)
    D["ck_house_terrace_pair"] = lambda: house_extra(20, 9, 7.0, 4, 2, TEAL)
    D["ck_house_split_level"] = lambda: house_extra(17, 10, 6.0, 4, 2, RED)
    D["ck_garden_shed"] = lambda: [bx((0, 0, 4.5 + 0.2 * i), (6.9 - 0.3 * i, 5.6, 0.1), ROOFB) for i in range(1)] + [bx((x, 2.5, 0.2), (0.3, 0.2, 0.4), WHT) for x in (-3.1, 3.1)] + [bx((3.1, y, 2.2), (0.14, 0.14, 4.6), WHT) for y in (-2.45, 2.45)] + [bx((-3.1, y, 2.2), (0.14, 0.14, 4.6), WHT) for y in (-2.45, 2.45)] + [bx((0, -2.43, 2.2 + 0.7 * i - 1.4), (6.2, 0.05, 0.1), MDK) for i in range(5)] + [bx((x, 2.55, 0.6), (0.35, 0.3, 1.0), BARK) for x in (-2.2, -1.8)] + [bx((0, 2.6, 4.3), (6.6, 0.1, 0.14), WHT), bx((-1.5, 2.55, 1.9), (0.2, 0.1, 0.2), MET)] + [bx((-3.0 + i * 0.5, 2.5, 4.0), (0.3, 0.06, 0.4), WHT) for i in range(13)]
    D["ck_railing_section"] = lambda: [bx((-2.2 + 0.28 * i, 0, 1.8), (0.05, 0.05, 2.4), MET) for i in range(17) if i % 2 == 0] + [bx((x, 0, 3.3), (0.3, 0.3, 0.1), MET) for x in (-2.6, 2.6)] + [bx((x, 0, 0.3), (0.4, 0.4, 0.1), MDK) for x in (-2.6, 2.6)] + [bx((0, 0, 1.8), (5.4, 0.1, 0.1), MDK)] + [bx((x, 0, 2.55), (0.12, 0.2, 0.2), YEL) for x in (-1.5, 0, 1.5)]
    D["ck_garden_fence"] = lambda: [bx((x, 0, 2.62), (0.26, 0.26, 0.14), WHT) for x in (-3.1, 3.1)] + [bx((x, 0.16, 0.3), (0.5, 0.05, 0.3), SOIL) for x in (-2.0, 0.5, 2.5)] + [sp((x, 0.9, 0.5), 0.5, LEAF, (1, 1, 0.8), 2) for x in (-2.2, 1.0)]
    D["ck_climbing_frame"] = lambda: [bx((-3.6 + 0.36 * i, -2.3, 2.5), (0.07, 0.07, 4.6), RED) for i in range(21)] + [bx((x, 2.3, 4.5), (0.5, 0.5, 0.1), YEL) for x in (-3.8, 3.8)] + [bx((x, -0.8 + 0.8 * j, 1.0 + 0.9 * j), (0.4, 0.14, 0.1), MET) for x in (-3.9, 3.9) for j in range(4)] + [cy((x, y, 5.1), 0.18, 0.2, RED, 8) for x in (-3.8, 3.8) for y in (-2.3, 2.3)]
    D["ck_slide"] = lambda: [bx((1.0 + 0.9 * i, 0, 2.4 - 0.4 * i + 0.3), (0.9, 0.9, 0.05), ORG) for i in range(4)] + [bx((-1.95, y, 4.35), (0.1, 0.1, 0.9), MET) for y in (-0.55, 0.55)] + [bx((-1.95 - 0.7, 0, 3.6), (0.1, 1.1, 0.14), MET), bx((-1.95, 0, 4.9), (1.4, 1.4, 0.1), BLU)] + [bx((x, y, 0.1), (0.4, 0.4, 0.2), KERB) for x in (-2.3, -1.6) for y in (-0.5, 0.5)] + [bx((-1.95, 0, 0.4 + i * 0.7 + 0.35), (1.2, 0.05, 0.05), MDK) for i in range(5)]
    D["ck_swing_set"] = lambda: [bx((x + dx, 0, 4.0 - i * 0.7), (0.05, 0.05, 0.4), MET) for x in (-1.7, 1.7) for dx in (-0.3, 0.3) for i in range(4)] + [bx((x, 0, 0.75), (1.0, 0.4, 0.08), MDK) for x in (-1.7, 1.7)] + [cy((x, 0, 4.5), 0.18, 0.5, MET, 8, axis="y") for x in (-1.7, 1.7)] + [bx((x, y, 4.6), (0.3, 0.3, 0.12), MDK) for x in (-3.4, 3.4) for y in (-1.5, 1.5)]
    D["ck_trampoline"] = lambda: [sp((0, 0, 1.4), 0.3, RED, (1, 1, 0.2), 1)]
    D["ck_tree_birch"] = lambda: [bx((0.4, 0, 1.0), (0.14, 0.14, 0.9), BARK, 0.4), bx((-0.35, 0.1, 1.3), (0.14, 0.14, 0.9), BARK, 2.0), bx((0, -0.1, 0.1), (0.9, 0.9, 0.2), SOIL)]
    D["ck_cafe_table_parasol"] = lambda: [bx((x, y, 1.5), (0.8, 0.06, 0.6), MDK) for x in (-2.0, 2.0) for y in (-0.5,)] + [bx((x, y, 0.4 + 0.1), (0.08, 0.08, 0.14), MET) for x in (-2.0, 2.0) for y in (-0.3, 0.3)] + [bx((0, 0, 3.5), (0.4, 0.4, 0.14), MET)] + [cy((0, 0, 1.9), 1.5, 0.05, BARK, 10)] + [bx((0, 0, 0.9), (0.3, 0.3, 0.1), MET)]
    D["ck_bus_stop_pole"] = lambda: [bx((0, 0.1, 2.0), (0.8, 0.05, 0.14), RED), bx((0, 0.1, 1.5), (0.8, 0.05, 0.14), MDK), bx((0, 0.06, 1.0), (0.6, 0.05, 0.4), WHT), bx((0.0, 0.12, 3.9), (0.5, 0.1, 0.1), RED), bx((0, 0, 0.3), (0.5, 0.5, 0.3), MDK)]
    D["ck_street_sign"] = lambda: [bx((0, 0.08, 2.4), (1.2, 0.06, 0.5), BLU), bx((0, 0.12, 2.4), (0.8, 0.04, 0.1), WHT), bx((0, 0.14, 1.9), (0.5, 0.04, 0.4), YEL), bx((0, 0, 0.35), (0.3, 0.3, 0.1), MDK), bx((0, 0.04, 3.45), (0.2, 0.04, 0.2), WHT)]
    D["ck_seesaw"] = lambda: [bx((x, 0.3, 0.85), (0.12, 0.05, 0.3), MDK) for x in (-1.5, -1.9, 1.5, 1.9)] + [bx((0, 0, 0.45), (0.5, 0.9, 0.1), MDK)] + [bx((0, y, 0.15), (0.5, 0.1, 0.3), MET) for y in (-0.4, 0.4)] + [bx((x, 0, 0.82), (0.14, 0.14, 0.2), RED) for x in (-1.6, 1.6)]
    D["ck_sandwich_board"] = lambda: [bx((0.0, 0.62, 1.2 + 0.4 * i), (1.2 - 0.3 * i, 0.02, 0.06), WHT) for i in range(3)] + [bx((x, 0.6, 2.7), (0.1, 0.02, 0.1), WHT) for x in (-0.6, -0.3, 0.3, 0.6)] + [bx((0, -0.62, 1.7), (1.3, 0.04, 1.9), MDK), bx((0, -0.64, 2.2), (0.8, 0.02, 0.1), WHT)] + [bx((x, 0, 0.1), (0.14, 1.3, 0.08), BARK) for x in (-0.8, 0.8)]
    D["ck_meme_wet_floor_sign"] = lambda: [bx((0, 0.44, 2.6), (0.6, 0.03, 0.14), RED), bx((0, -0.44, 2.6), (0.6, 0.03, 0.14), RED), bx((0, 0.44, 0.4), (0.8, 0.03, 0.1), MDK), bx((0, -0.44, 0.4), (0.8, 0.03, 0.1), MDK), bx((0, 0.0, 3.2), (0.5, 0.2, 0.1), YEL), sp((0, 0.44, 1.2), 0.18, WHT, (1, 0.2, 1), 1)] + [bx((x, 0.43, 2.0 + 0.4 * (x > 0)), (0.12, 0.02, 0.5), BLU) for x in (-0.3, 0.3)]
    # larger props
    D["ck_landmark_obelisk"] = lambda: ring_posts(6.2, 24, 1.2, MDK, 0.35) + [bx((0, 0, 0.1 + 0.25 * i), (11.0 - 1.0 * i, 11.0 - 1.0 * i, 0.25), KERB) for i in range(5)] + [bx((x * 3.1, y * 3.1, 2.0), (0.9, 0.9, 3.0), KERB) for x in (-1, 1) for y in (-1, 1)] + [sp((x * 3.1, y * 3.1, 3.7), 0.6, WC, (), 2) for x in (-1, 1) for y in (-1, 1)] + [bx((0, y * 2.6, 1.0 + 3.6 * j), (1.6, 0.14, 1.0), TRIM) for y in (-1, 1) for j in range(2)] + [bx((x * 2.6, 0, 1.0 + 3.6 * j), (0.14, 1.6, 1.0), TRIM) for x in (-1, 1) for j in range(2)] + [bx((0, 0, 9 + 4.0 * i), (3.2 - 0.35 * i, 3.2 - 0.35 * i, 0.3), TRIM, math.pi / 4) for i in range(6)] + [bx((0, 0, 7 + 4.5 * i), (0.4, 1.9 - 0.2 * i, 2.5), WC, k * math.pi / 2) for i in range(5) for k in range(4)]
    D["ck_landmark_arch"] = lambda: [bx((x, y, 31.6), (0.7, 0.4, 0.5), TRIM) for x in [-11.5 + 1.0 * i for i in range(24)] for y in (-5.4, 5.4)] + [bx((x, y, 25.5), (0.6, 0.4, 0.4), TRIM) for x in [-12 + 1.0 * i for i in range(25)] for y in (-5.4, 5.4)] + [bx((0, y, 0.1 + 0.25 * i), (28 + 0.8 * (4 - i), 11 + 0.8 * (4 - i), 0.25), KERB) for i in range(4) for y in (0,)] + [bx((x, y, 19 + 0.0), (0.4, 0.3, 14), WC) for x in (-12.0, -7.0, 7.0, 12.0) for y in (-5.4, 5.4)] + [bx((x, 0, 36.1), (3.0, 3.0, 2.0), TRIM) for x in (-9, 0, 9)] + [bx((x, y, 14.0), (0.5, 0.5, 2.0), WC) for x in (-5, 5) for y in (-5.2, 5.2)]
    D["ck_landmark_clock_tower"] = lambda: [bx((x, y, 43.0), (1.0, 1.0, 1.2), TRIM) for x in (-3.5, 3.5) for y in (-3.5, 3.5)] + [bx((x, 5.3, 27.8), (0.9, 0.5, 0.7), TRIM) for x in [-4 + 1.0 * i for i in range(9)]] + [bx((x, -5.3, 27.8), (0.9, 0.5, 0.7), TRIM) for x in [-4 + 1.0 * i for i in range(9)]] + [bx((5.3, y, 27.8), (0.5, 0.9, 0.7), TRIM) for y in [-4 + 1.0 * i for i in range(9)]] + [bx((-5.3, y, 27.8), (0.5, 0.9, 0.7), TRIM) for y in [-4 + 1.0 * i for i in range(9)]] + [cy((0, 0, 44.5), 1.0, 5.0, MET, 12, r2=0.1)] + [bx((x, y, 1.0 + 0.4 * i), (13 - 0.8 * i, 13 - 0.8 * i, 0.4), KERB) for i in range(1) for x, y in ((0, 0),)] + [bx((x, y, 12.0), (0.5, 0.5, 10.0), WC) for x in (-4.4, 4.4) for y in (-4.4, 4.4)]
    D["ck_subway_entrance"] = lambda: [bx((-5.35, y, 1.4), (0.14, 0.14, 2.4), MET) for y in [-2.4 + 0.4 * i for i in range(13)]] + [bx((x, 2.65, 0.1 + 0.9 * (k % 2) + 0.6), (0.9, 0.06, 0.9), WHT) for k, x in enumerate([-5.0 + 1.0 * i for i in range(9)])] + [bx((x, -2.65, 0.1 + 0.9 * (k % 2) + 0.6), (0.9, 0.06, 0.9), WHT) for k, x in enumerate([-5.0 + 1.0 * i for i in range(9)])] + [cy((x, y, 2.8), 0.28, 0.2, GLOW, 10) for x in (-4.5, 1.5) for y in (-2.5, 2.5)] + [bx((-1.5, 0, 2.6), (8.2, 5.6, 0.2), MET), bx((-1.5, 0, 2.8), (8.0, 5.4, 0.1), MDK)] + [bx((-5.4, y, 0.6 + 0.7 * j), (0.1, 0.9, 0.5), WHT) for y in (-1.8, 0, 1.8) for j in range(3)] + [bx((3.6 + 0.4 * i, y, 0.3 + 0.2 * i), (0.4, 0.08, 0.2), YEL) for i in range(6) for y in (-1.4, 1.4)]
    D["ck_tram"] = lambda: [bx((x, 0, 6.0), (0.5, 0.5, 0.3), MDK) for x in (-9, -2, 2, 9)] + [bx((x, sy * 1.84, 3.0), (0.14, 0.1, 3.6), MDK) for x in [-11 + 2.4 * i for i in range(10)] for sy in (-1, 1)] + [bx((x, sy * 1.7, 0.3), (1.6, 0.3, 0.5), MDK) for x in (-9, -3, 3, 9) for sy in (-1, 1)] + [cy((x, 0, 6.5), 0.2, 0.9, MET, 8) for x in (-6, 6)]
    D["ck_meme_cone_statue"] = lambda: ring_posts(4.2, 16, 1.0, MDK, 0.3) + [bx((0, 0, 0.1 + 0.2 * i), (7.0 - 0.7 * i, 7.0 - 0.7 * i, 0.2), KERB) for i in range(3)] + [bx((0, y * 2.1, 1.0), (2.4, 0.1, 0.8), TRIM) for y in (-1, 1)] + [bx((x * 2.1, 0, 1.0), (0.1, 2.4, 0.8), TRIM) for x in (-1, 1)] + [bx((0, 0.6, 3.8 + i * 0.5), (1.3, 0.08, 0.1), TRIM) for i in range(6)] + [bx((x, 0, 2.5), (0.5, 0.9, 1.2), WC) for x in (-0.5, 0.5)] + [cy((0, 0, 8.7), 0.95, 0.12, WHT, 12), cy((0, 0, 9.3), 0.65, 0.12, WHT, 12)]
    D["ck_meme_phone_1pc"] = lambda: [bx((-1.9 + 0.95 * i, 0.72, 10.5 - 0.95 * j), (0.7, 0.04, 0.7), (RED, YEL, BLU, TEAL, ORG, PNK)[(i + j) % 6]) for i in range(5) for j in range(3)] + [bx((x, 0.68, 12.2), (0.14, 0.04, 0.14), WHT) for x in (-1.5, -1.2, 1.2)] + [bx((0, 0, 0.1 + 0.25 * i), (8.0 - 0.8 * i, 4.0 - 0.4 * i, 0.25), KERB) for i in range(3)] + [bx((0, 0.7, 6.4), (4.0, 0.04, 0.4), WHT), bx((-1.0, 0.72, 6.4), (1.2, 0.04, 0.2), RED)] + [bx((x, 0.7, 0.9 + 0.0), (0.2, 0.1, 0.4), MDK) for x in (-2.2, 2.2)] + [bx((x, 0.4, 13.8), (0.4, 0.2, 0.2), MET) for x in (-2, 2)]
    D["ck_meme_banana_scale"] = lambda: [bx((0, 0, 0.1 + 0.25 * i), (11.0 - 0.8 * i, 9.0 - 0.8 * i, 0.25), KERB) for i in range(2)] + [bx((-3.5, y, 2.0 + 0.0), (2.4, 0.1, 2.0), TRIM) for y in (-1.05, 1.05)]

    def more(key, fn):
        prev = D.get(key)
        D[key] = lambda: (prev() if prev else []) + fn()

    more("ck_bush", lambda: [sp((x, y, 0.9), 0.7, LEAF if i % 2 else LDK, (1, 1, 0.9), 2) for i, (x, y) in enumerate(((0.5, 0.3), (-0.6, -0.2), (0.0, -0.8)))])
    more("ck_bike_rack", lambda: [])
    more("ck_car_estate", lambda: [bx((x, 3.0, 2.2), (0.2, 0.06, 0.2), MET) for x in (-3.0, 0.5)])
    more("ck_meme_phone_1pc", lambda: [bx((-2.4 + 0.8 * i, 0.7, 1.9), (0.5, 0.03, 0.3), MDK) for i in range(7)] + [bx((x, 0.5, 9.8), (0.14, 0.14, 0.14), WHT) for x in (-2.4, 2.4)] + [bx((0, 0.66, 0.8), (3.0, 0.14, 0.2), MET)])
    more("ck_bus_stop_pole", lambda: [bx((0, 0.1, 3.5), (0.8, 0.05, 0.1), MDK), bx((0.3, 0.1, 2.9), (0.1, 0.05, 0.3), RED)])
    more("ck_railing_section", lambda: [bx((-2.35 + 0.28 * i, 0, 0.9), (0.05, 0.05, 0.8), MET) for i in range(0, 17, 3)] + [bx((x, 0, 3.4), (0.2, 0.2, 0.1), YEL) for x in (-2.6, 2.6)] + [bx((0, 0, 1.2), (5.4, 0.08, 0.08), MDK)])
    more("ck_slide", lambda: [bx((-1.0 + 1.0 * i, y, 2.5 - 0.35 * i), (0.9, 0.06, 0.3), YEL) for i in range(3) for y in (-0.5, 0.5)])
    more("ck_street_lamp_double", lambda: [cy((0, 0, 1.0 + 1.6 * i), 0.22, 0.14, MET, 12) for i in range(6)] + [cy((x, 0, 8.7), 0.1, 0.4, MDK, 8) for x in (-2.0, 2.0)] + [bx((0, 0, 0.5), (0.7, 0.7, 0.6), MDK, math.pi / 4)])
    more("ck_street_sign", lambda: [cy((0, 0, 0.9 + 0.8 * i), 0.1, 0.06, MET, 8) for i in range(3)] + [bx((0, 0.06, 2.0), (0.14, 0.04, 0.8), MET)])
    more("ck_car_sedan", lambda: [bx((x, y, 3.75), (0.14, 0.14, 0.14), MET) for x in (-2.0, 1.0) for y in (-1.9, 1.9)] + [bx((0, y, 1.9), (3.0, 0.08, 0.1), MDK) for y in (-3.05, 3.05)] + [bx((x, 0, 4.0), (0.5, 4.0, 0.08), MDK) for x in (-2.8, 1.8)])
    more("ck_car_estate", lambda: [bx((x, y, 4.2), (6.0, 0.1, 0.1), MET) for x in (-1.5,) for y in (-2.2, 2.2)] + [bx((x, 0, 4.4), (0.2, 4.6, 0.1), MET) for x in (-4.0, -1.5, 1.0)] + [bx((0, y, 1.9), (3.0, 0.08, 0.1), MDK) for y in (-3.05, 3.05)])
    more("ck_landmark_obelisk", lambda: [bx((0, 0, 14 + 4.0 * i), (0.4, 2.0 - 0.25 * i, 0.9), WC, k * math.pi / 2) for i in range(5) for k in range(4)])
    more("ck_meme_banana_scale", lambda: [sp((math.cos(t) * 5.0 + 0.0, 0, 12.0 + math.sin(t) * 6.0), 1.5, YEL, (1, 0.9, 1), 2) for t in (-0.3, 0.1, 0.5, 0.9, 1.3, 1.7)])
    more("ck_meme_cone_statue", lambda: [sp((x * 3.0, y * 3.0, 1.4), 0.8, LEAF if (x + y) % 4 else PNK, (1, 1, 0.8), 2) for x in (-1, 1) for y in (-1, 1)])
    more("ck_meme_phone_1pc", lambda: [bx((-1.9 + 0.95 * i, 0.72, 3.5 - 0.6 * j), (0.7, 0.04, 0.45), WHT) for i in range(5) for j in range(1)] + [bx((x, 0.64, 1.6), (0.5, 0.06, 0.12), MDK) for x in (-2.4, 2.4)] + [bx((x, 0.5, 13.6), (0.3, 0.1, 0.3), MET) for x in (-2.6, 2.6)] + [bx((0, 0.68, 13.3), (1.8, 0.04, 0.1), MDK)] + [bx((x, y, 7.0), (0.1, 0.1, 13.0), MDK) for x in (-3.05, 3.05) for y in (-0.55,)] + [bx((x, 0.4, 0.9 + 0.4 * i), (0.3, 0.3, 0.3), KERB) for x in (-3.0, 3.0) for i in range(3)] + [bx((0, 0.7, 11.0 - 0.5 * i), (4.4, 0.03, 0.06), TRIM) for i in range(3)] + [bx((-2.0 + 0.5 * i, 0.7, 5.6), (0.3, 0.03, 0.3), TEAL) for i in range(9)] + [bx((x, 0.7, 3.2), (0.3, 0.03, 0.14), WHT) for x in (-2.0, -1.0, 0, 1.0, 2.0)])
    more("ck_tree_oak", lambda: [sp((math.cos(a) * 3.2, math.sin(a) * 3.2, 7.2 + 0.7 * (i % 2)), 1.7, LEAF if i % 2 else LDK, (), 2) for i, a in enumerate([0.4 + k * 1.05 for k in range(6)])] + [bx((math.cos(a) * 0.8, math.sin(a) * 0.8, 0.3), (1.0, 0.3, 0.5), BARK, a) for a in (0, 1.6, 3.2, 4.8)])
    more("ck_tree_pine", lambda: [cy((0, 0, 3.6 + 1.5 * i), 3.1 - 0.33 * i, 2.0, LEAF if i % 2 else LDK, 20, r2=2.5 - 0.33 * i) for i in range(8)] + [bx((math.cos(a) * 0.5, math.sin(a) * 0.5, 0.25), (1.0, 0.3, 0.5), BARK, a) for a in (0, 1.6, 3.2, 4.8)])
    REFINE["ck_tree_oak"] = (1.5, 1)
    REFINE["ck_tree_pine"] = (1.8, 0)
    REFINE["ck_tree_birch"] = (1.3, 1)
    REFINE["ck_bush"] = (1.0, 0)
    REFINE["ck_hedge_row"] = (1.0, 1)
    REFINE["ck_flower_bed"] = (1.0, 1)
    REFINE["ck_planter_box"] = (1.0, 1)
    REFINE["ck_bin_street"] = (1.8, 0)
    REFINE["ck_street_lamp_double"] = (1.7, 0)
    REFINE["ck_meme_banana_scale"] = (1.0, 1)
    REFINE["ck_car_sedan"] = (1.6, 0)
    REFINE["ck_car_estate"] = (1.6, 0)
    REFINE["ck_limousine"] = (1.6, 0)
    REFINE["ck_bollard"] = (1.0, 0)


def apply_detail(out):
    if not DETAIL:
        build_detail()
    for key, (seg, sub) in REFINE.items():
        if key in out:
            out[key] = refine(out[key], seg, sub)
    for key, fn in DETAIL.items():
        if key in out:
            out[key] = out[key] + fn()
    cars = {"ck_car_sedan": (15, 6, 4.8, BLU), "ck_car_estate": (16, 6, 5.2, TEAL), "ck_limousine": (18, 5.6, 4.4, MDK)}
    for key, (l, w, h, body) in cars.items():
        out[key] = out[key] + car_details(l, w, h, body)


# ---------------------------------------------------------------------------------------------- fronts objects

# Sign cell per shop front (docs/design/shop-names.json cells). Cells with no name yet draw as a plain coloured board.
SHOP_SIGNS = {
    "ck_shop_bakery": ["sign_11"], "ck_shop_grocer": ["sign_00"], "ck_shop_pizzeria": ["sign_01"],
    "ck_shop_cafe": ["sign_09"], "ck_shop_bookshop": ["sign_03"], "ck_shop_pharmacy_cross": ["sign_10"],
    "ck_shop_row_three": ["sign_02", "sign_05", "sign_07"],
    "ck_shop_row_arcade": ["sign_06", "sign_03", "sign_04", "sign_08"],
    "ck_shop_row_corner": ["sign_00", "sign_02", "sign_05", "sign_07"],
}
FX_WALL, FX_BRICK, FX_GLASS, FX_SHOP, FX_AWN, FX_TRIM = "fx_render", "fx_brick", "fx_glass", "fx_shopglaze", "fx_shutter", "fx_cornice"


def shop_front_row(x0, width, y, wall_h, sign, awn=FX_AWN, door_left=False):
    """One shop front on a wall facing +y: glazing, mullions, door, scalloped awning, fascia sign board."""
    bx = bo.bx
    parts = []
    gw = width * 0.64
    gx = x0 + (width * 0.2 if not door_left else width * 0.38) + gw / 2 - width * 0.2
    parts.append(bx((gx, y + 0.06, wall_h * 0.45), (gw, 0.14, wall_h * 0.5), FX_SHOP))
    for k in range(5):
        parts.append(bx((gx - gw / 2 + gw * k / 4, y + 0.12, wall_h * 0.45), (0.12, 0.1, wall_h * 0.52), FX_TRIM))
    parts.append(bx((gx, y + 0.1, wall_h * 0.2), (gw, 0.16, 0.12), FX_TRIM))
    dx = x0 + width * (0.82 if not door_left else 0.14)
    parts.append(bx((dx, y + 0.08, wall_h * 0.38), (width * 0.17, 0.16, wall_h * 0.76), FX_AWN))
    parts.append(bx((dx, y + 0.18, wall_h * 0.38), (width * 0.1, 0.06, wall_h * 0.3), FX_SHOP))
    parts.append(bx((x0 + width / 2, y + 0.95, wall_h * 0.88), (width * 0.96, 1.7, 0.16), awn))
    for k in range(7):
        parts.append(bx((x0 + width * (0.06 + 0.88 * k / 6), y + 1.75, wall_h * 0.82), (width * 0.12, 0.1, 0.28), awn))
    parts.append(bx((x0 + width / 2, y + 0.14, wall_h * 1.02), (width * 0.9, 0.16, 0.9), sign))
    parts.append(bx((x0 + width / 2, y + 0.1, wall_h * 1.02 + 0.5), (width * 0.94, 0.22, 0.1), FX_TRIM))
    return parts


def shop_building(w, d, h, floors, signs, wall=FX_WALL, cols=4, extra=0):
    bx, cy, cn, sp, pg, tor = P()
    ground = h * 0.3
    parts = [bx((0, 0, h / 2), (w, d, h), wall)]
    n = len(signs)
    fw = w / n
    for k, sign in enumerate(signs):
        parts += shop_front_row(-w / 2 + fw * k, fw, d / 2, ground, sign, door_left=bool(k % 2))
    up0, up1 = ground * 1.35, h * 0.94
    for sx, sy, face, c in ((0, 1, w, cols), (0, -1, w, cols), (1, 0, d, 3), (-1, 0, d, 3)):
        parts += window_grid(sx * w / 2, sy * d / 2, face, up0, up1, c, floors, sx, sy, FX_GLASS, depth=0.12, frame=FX_TRIM)
    parts.append(bx((0, 0, h + 0.3), (w + 0.5, d + 0.5, 0.6), FX_TRIM))
    for k in range(int(w // 1.2)):
        parts.append(bx((-w / 2 + 0.6 + k * 1.2, d / 2 + 0.28, h + 0.75), (0.5, 0.3, 0.3), FX_TRIM))
    for sy in (-1, 1):
        parts.append(bx((0, sy * d / 2, ground * 1.3), (w + 0.3, 0.3, 0.2), FX_TRIM))
    for k in range(extra):
        parts.append(bx((-w / 2 + 1.0 + k * (w - 2) / max(1, extra - 1), d / 2 + 0.4, 0.5), (0.9, 0.5, 0.8), FX_AWN))
    parts.append(bx((w * 0.3, -d * 0.1, h + 1.2), (1.2, 1.2, 1.8), FX_WALL))
    return parts


def shops(fronts):
    if fronts is None:
        return {}
    out = {}
    out["ck_shop_bakery"] = shop_building(14, 8.4, 9.1, 2, SHOP_SIGNS["ck_shop_bakery"], FX_BRICK, 4, 3)
    out["ck_shop_grocer"] = shop_building(16, 9.6, 10.4, 2, SHOP_SIGNS["ck_shop_grocer"], FX_WALL, 4, 5)
    out["ck_shop_pizzeria"] = shop_building(15, 9, 9.7, 2, SHOP_SIGNS["ck_shop_pizzeria"], FX_BRICK, 4, 2)
    out["ck_shop_cafe"] = shop_building(13, 7.8, 8.4, 2, SHOP_SIGNS["ck_shop_cafe"], FX_WALL, 3, 6)
    out["ck_shop_bookshop"] = shop_building(18, 10.8, 11.7, 2, SHOP_SIGNS["ck_shop_bookshop"], FX_BRICK, 5, 0)
    ph = shop_building(17, 10.2, 11, 2, SHOP_SIGNS["ck_shop_pharmacy_cross"], FX_WALL, 4, 0)
    ph += [bo.bx((6.2, 5.4, 8.6), (0.5, 0.3, 1.8), FX_AWN), bo.bx((6.2, 5.4, 8.6), (1.8, 0.3, 0.5), FX_AWN),
           bo.bx((6.2, 5.2, 8.6), (2.2, 0.2, 2.2), FX_TRIM)]
    out["ck_shop_pharmacy_cross"] = ph
    out["ck_shop_row_three"] = shop_building(28, 14, 16, 3, SHOP_SIGNS["ck_shop_row_three"], FX_BRICK, 7, 0)
    out["ck_shop_row_arcade"] = shop_building(34, 15, 16, 3, SHOP_SIGNS["ck_shop_row_arcade"], FX_WALL, 7, 0) + [
        bo.bx((-17 + 2.2 * k, 8.4, 2.4), (0.5, 0.5, 4.8), FX_TRIM) for k in range(16)]
    corner = shop_building(38, 22, 18, 3, SHOP_SIGNS["ck_shop_row_corner"], FX_BRICK, 8, 0)
    corner += shop_front_row(19.0, 6.0, 0.0, 5.4, "sign_10")[:0]
    corner += [bo.bx((19.3, 0, 2.7), (0.4, 11, 5.4), FX_AWN), bo.bx((19.2, 0, 5.8), (0.3, 11, 0.9), "sign_11")]
    out["ck_shop_row_corner"] = corner
    return out


def billboard_panel(w, h, cell, extra=0):
    bx = bo.bx
    bh = h
    parts = [bx((0, 0, bh * 0.62 + 2.0), (w, 0.7, bh * 0.76), cell)]
    parts += [bx((0, 0.4, bh * 0.62 + 2.0), (w + 0.5, 0.2, 0.3), FX_TRIM)]
    parts += [bx((0, -0.4, bh * 0.62 + 2.0), (w + 0.5, 0.2, 0.3), FX_TRIM)]
    for sx in (-1, 1):
        parts.append(bx((sx * (w / 2 + 0.2), 0, bh * 0.62 + 2.0), (0.4, 0.8, bh * 0.76 + 0.4), FX_TRIM))
    parts.append(bx((0, 0, bh * 0.62 + 2.0 + bh * 0.38 + 0.15), (w + 0.5, 0.9, 0.3), FX_TRIM))
    parts.append(bx((0, 0, bh * 0.62 + 2.0 - bh * 0.38 - 0.15), (w + 0.5, 0.9, 0.3), FX_TRIM))
    for sx in (-w * 0.3, 0, w * 0.3):
        parts.append(bx((sx, -0.1, 1.0 + 0.0), (0.8, 0.8, 2.0 + bh * 0.1), FX_AWN))
    parts.append(bx((0, -0.7, 2.0 + 0.05), (w * 0.8, 0.9, 0.12), FX_TRIM))
    for k in range(7):
        parts.append(bx((-w * 0.3 + 0.0, -0.9, 0.5 + k * 0.5 + 0.2), (0.12, 0.12, 0.12), FX_TRIM))
    for sx in range(5):
        parts.append(bx((-w * 0.4 + sx * w * 0.2, 0.8, bh * 0.62 + 2.0 + bh * 0.38 + 0.8), (0.3, 0.8, 0.8), FX_TRIM))
        parts.append(bx((-w * 0.4 + sx * w * 0.2, 0.9, bh * 0.62 + 2.0 + bh * 0.38 + 0.4), (0.12, 0.12, 0.6), FX_TRIM))
    for k in range(extra):
        parts.append(bx((w * 0.3 + 0.3, -0.5, 1.0 + k * 0.45), (0.9, 0.08, 0.1), FX_TRIM))
    return parts


def billboards(fronts):
    if fronts is None:
        return {}
    out = {}
    for name, cell, w, h, x in (("ck_billboard_404", "bb_404", 18, 10.8, 0), ("ck_billboard_chart", "bb_chart", 18, 10.8, 0),
                                ("ck_billboard_loading", "bb_loading", 18, 10.8, 0), ("ck_billboard_empty", "bb_empty", 18, 10.8, 0),
                                ("ck_billboard_arrow", "bb_arrow", 18, 10.8, 0), ("ck_billboard_testcard", "bb_testcard", 26, 15.6, 0),
                                ("ck_billboard_nested", "bb_nested", 26, 15.6, 0), ("ck_meme_buffering_billboard", "bb_buffering", 18, 10.8, 0)):
        out[name] = billboard_panel(w, h, cell, 14)
    return out


# ---------------------------------------------------------------------------------------------- build driver

def load_modules():
    global bo
    scripts = os.path.join(ROOT, "art", "scripts")
    if scripts not in sys.path:
        sys.path.insert(0, scripts)
    import importlib
    import build_objects
    bo = importlib.reload(build_objects)
    bo.assign_uvs = assign_uvs_upright  # kit meshes only; the dt_ meshes keep the 007 mapping


def assign_uvs_upright(bm, tags, swatch_rects) -> int:
    """Planar projection of each face into its swatch rect with the picture upright: a face is mapped as seen from
    outside (u to the viewer's right, v up for walls; u along x and v along y on a roof). build_objects.assign_uvs maps a
    +y or -y wall with u along z, which turns signs and billboard designs on their side."""
    layer = bm.loops.layers.uv.new("UVMap")
    eps = 1e-4
    for face, swatch in tags:
        rect = swatch_rects[swatch]
        u0, v0 = rect[0] + eps, rect[1] + eps
        inner_u, inner_v = rect[2] - rect[0] - 2 * eps, rect[3] - rect[1] - 2 * eps
        n = face.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        if az >= ax and az >= ay:
            u_axis, u_sign, v_axis, v_sign = 0, 1.0, 1, 1.0
        elif ay >= ax:
            u_axis, u_sign, v_axis, v_sign = 0, (-1.0 if n.y > 0 else 1.0), 2, 1.0
        else:
            u_axis, u_sign, v_axis, v_sign = 1, (1.0 if n.x > 0 else -1.0), 2, 1.0
        us = [loop.vert.co[u_axis] * u_sign for loop in face.loops]
        vs = [loop.vert.co[v_axis] * v_sign for loop in face.loops]
        span_u, span_v = max(us) - min(us), max(vs) - min(vs)
        for loop, uu, vv in zip(face.loops, us, vs):
            su = (uu - min(us)) / span_u if span_u > eps else 0.5
            sv = (vv - min(vs)) / span_v if span_v > eps else 0.5
            loop[layer].uv = (u0 + su * inner_u, v0 + sv * inner_v)
    return sum(max(1, len(f.verts) - 2) for f in bm.faces)


def file_for(object_id, tier, zone_building):
    if zone_building:
        return BUILDING_FILE
    return PROP_FILES["low" if tier <= 3 else "high"]


FLAT = ("road_marking", "crossing", "kerb_corner", "picnic_blanket", "sandpit", "path_", "pond_edge", "meme_vacant")
TIER_FLOORS = [150, 210, 450, 1050, 1500]


def report(ids, budgets):
    """Prints the ids whose triangle count is under the class floor or over 60 % of the tier budget."""
    import bpy
    low, high = [], []
    for coll in bpy.data.collections:
        if coll.name not in ids:
            continue
        obj = next(o for o in coll.objects if o.type == "MESH")
        tris = sum(max(1, len(p.vertices) - 2) for p in obj.data.polygons)
        tier = budgets["tiers"][coll.name]
        flat = any(coll.name[3:].startswith(f) for f in FLAT)
        panel = coll.name.startswith("ck_billboard_") or coll.name == "ck_meme_buffering_billboard"
        floor = 24 if flat else (150 if panel else TIER_FLOORS[tier - 1])
        cap = budgets["meshTriangles"][tier - 1] * 0.6
        if tris < floor:
            low.append(f"{coll.name} {tris}<{floor}")
        elif tris > cap and not flat:
            high.append(f"{coll.name} {tris}>{int(cap)}")
    print("under floor:", low)
    print("over 60%:", high)


def run(params):
    global ROOT
    ROOT = params["root"]
    import bpy  # noqa: F401
    load_modules()
    art = os.path.join(ROOT, "art")
    with open(os.path.join(art, "scripts", "budgets.json"), encoding="utf-8") as handle:
        budgets = json.load(handle)
    with open(os.path.join(art, "palette.json"), encoding="utf-8") as handle:
        palette = json.load(handle)
    rects = {name: (c["u0"], c["v0"], c["u1"], c["v1"]) for name, c in palette["cells"].items()}
    fronts = None
    fronts_path = os.path.join(art, "atlases", "fronts", "fronts.json")
    if os.path.isfile(fronts_path):
        with open(fronts_path, encoding="utf-8") as handle:
            fronts = json.load(handle)
    if fronts is not None:
        for group in ("signs", "billboards", "strips"):
            for name, c in fronts[group].items():
                rects[name] = (c["u0"], c["v0"], c["u1"], c["v1"])
    recipes = all_recipes(fronts)
    ck_ids = sorted(k for k in budgets["sizes"] if k.startswith("ck_"))
    only = set(params.get("only", []))
    building_ids = {i for i in ck_ids if i.split("_")[1] in ("house", "shop", "midrise", "tower")}
    wanted = [i for i in ck_ids if i in recipes]
    sized = budgets["sizes"]
    sub = {"meshTriangles": budgets["meshTriangles"], "sizes": budgets["sizes"], "tiers": budgets["tiers"]}
    groups = {}
    for i in wanted:
        groups.setdefault(file_for(i, budgets["tiers"][i], i in building_ids), []).append(i)
    if only:  # a file is always rebuilt whole; `only` picks the files that hold these ids
        groups = {name: ids for name, ids in groups.items() if only & set(ids)}
    skipped = [i for i in ck_ids if i not in recipes]
    for name, ids in sorted(groups.items()):
        bo.build_file(name, ids, recipes, sized, rects, sub)
        report(ids, budgets)
    print(f"kit_recipes: built {len(wanted)} meshes, {len(skipped)} without a recipe yet: {skipped}")
