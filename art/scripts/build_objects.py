# Builds the 65 Snow Village meshes (64 objects plus the hub) as low-poly collections in Blender and
# writes them out as art/source/<tier file>.blend, one file per tier plus hub.blend. The committed .blend
# files are the source of truth; a model is rebuilt without this script (contract R9), which exists to
# author the .blend files once and to keep them reproducible (art-pipeline.md: one collection per objectId
# named exactly the id, one Palette material whose swatch cells come from palette.json, flat shading,
# origin at the bottom centre of the footprint, the longest bounding side equal to the ObjectDef size,
# triangles inside the per-tier budget). Run: blender --background --python art/scripts/build_objects.py

import json
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

CELLS = 8
CELL = 1.0 / CELLS
EPS = 1e-4

TIER_FILES = {
    1: "tier1_crumbs",
    2: "tier2_toys",
    3: "tier3_furniture",
    4: "tier4_street",
    5: "tier5_town",
}
HUB_FILE = "hub"


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def source_dir() -> str:
    return os.path.join(art_dir(), "source")


def load_json(path: str):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


# ---------------------------------------------------------------- constructors (recipe DSL)
# Swatch letters below: n snow, l snow_light, s stone, w wood, b brick, i ice.

def bx(c, d, s, yaw=0.0):
    return ("box", c, d, s, yaw)


def cy(c, r, h, s, n=8, r2=None, axis="z", yaw=0.0):
    return ("cyl", c, r, h, s, n, r2, axis, yaw)


def cn(c, r, h, s, n=8, axis="z", yaw=0.0):
    return ("cyl", c, r, h, s, n, 0.0, axis, yaw)


def sp(c, r, s, sq=(1.0, 1.0, 1.0), sub=1):
    return ("sph", c, r, s, sq, sub)


def pg(c, pts, span, s, axis="y", yaw=0.0):
    # axis "y": pts are [(x, z)] and the prism spans `span` along y (gable roofs, stars viewed from y).
    # axis "z": pts are [(x, y)] and the prism spans `span` up z (top-view wedges, like the plough blade).
    return ("prism", c, pts, span, s, axis, yaw)


def tor(c, R, r, s, major=8, minor=4, stand=False):
    return ("torus", c, R, r, s, major, minor, stand)


def star_points(outer: float, inner: float) -> list:
    pts = []
    for index in range(10):
        r = outer if index % 2 == 0 else inner
        angle = math.pi / 2 + 2.0 * math.pi * index / 10
        pts.append((r * math.cos(angle), r * math.sin(angle)))
    return pts


def all_recipes() -> dict:
    n, l, s, w, b, i = "snow", "snow_light", "stone", "wood", "brick", "ice"
    out = {}

    # ---- Tier 1: crumbs and mini toys (budget 300 tris) ----
    out["gumdrop"] = [
        sp((0, 0, 0.14), 0.2, b, (1.0, 1.0, 0.7)),
        sp((0.11, 0.05, 0.24), 0.06, l, (), 0),
        sp((-0.09, -0.07, 0.2), 0.05, l, (), 0),
    ]
    out["button"] = [
        cy((0, 0, 0.05), 0.22, 0.1, n, 9),
        cy((0.08, 0, 0.07), 0.04, 0.12, w, 6),
        cy((-0.08, 0, 0.07), 0.04, 0.12, w, 6),
    ]
    out["jingle_bell"] = [
        sp((0, 0, 0.26), 0.22, w, (1.0, 1.0, 0.92)),
        cy((0, 0, 0.05), 0.235, 0.08, w, 9),
        cy((0, 0, 0.5), 0.06, 0.1, w, 6),
        tor((0, 0, 0.58), 0.07, 0.025, w, 8, 4),
    ]
    out["acorn"] = [
        sp((0, 0, 0.2), 0.17, w, (0.85, 0.85, 1.0)),
        cy((0, 0, 0.36), 0.2, 0.14, s, 9, r2=0.12),
        bx((0, 0, 0.47), (0.05, 0.05, 0.12), s),
    ]
    out["marshmallow"] = [cy((0, 0, 0.21), 0.24, 0.42, n, 7)]
    out["peppermint"] = [
        cy((0, 0, 0.07), 0.35, 0.14, b, 13),
        cy((0.38, 0, 0.07), 0.055, 0.12, l, 7, axis="x"),
        cy((-0.38, 0, 0.07), 0.055, 0.12, l, 7, axis="x"),
    ]
    out["pine_cone"] = [
        cy((0, 0, 0.4), 0.32, 0.72, w, 8, r2=0.07),
        bx((0.2, 0.12, 0.42), (0.12, 0.1, 0.1), w, yaw=0.6),
        bx((-0.2, -0.12, 0.45), (0.12, 0.1, 0.1), w, yaw=2.2),
        bx((0.05, -0.2, 0.66), (0.1, 0.1, 0.09), w, yaw=1.0),
        bx((0, 0, 0.84), (0.07, 0.07, 0.14), w),
    ]
    out["bauble"] = [
        sp((0, 0, 0.36), 0.3, i, (1.0, 1.0, 1.12)),
        cy((0, 0, 0.74), 0.1, 0.16, s, 8),
        tor((0, 0, 0.86), 0.08, 0.025, s, 8, 4),
    ]
    out["cookie"] = [
        cy((0, 0, 0.07), 0.46, 0.14, w, 10),
        bx((0.16, 0.12, 0.16), (0.12, 0.12, 0.05), s),
        bx((-0.18, -0.1, 0.16), (0.12, 0.12, 0.05), s),
        bx((-0.08, 0.2, 0.16), (0.1, 0.1, 0.05), s),
        bx((0.22, -0.16, 0.16), (0.1, 0.1, 0.05), s),
    ]
    out["ribbon_bow"] = [
        bx((0, 0, 0.5), (0.22, 0.24, 0.2), w),
        bx((-0.38, 0, 0.5), (0.46, 0.26, 0.16), w),
        bx((0.38, 0, 0.5), (0.46, 0.26, 0.16), w),
        bx((-0.15, 0, 0.2), (0.12, 0.1, 0.38), w),
        bx((0.15, 0, 0.2), (0.12, 0.1, 0.38), w),
    ]
    out["mini_snow_globe"] = [
        cy((0, 0, 0.11), 0.3, 0.22, s, 9),
        sp((0, 0, 0.56), 0.32, i, (1.0, 1.0, 0.92)),
        sp((0, 0, 0.44), 0.2, n, (1.0, 1.0, 0.5), 0),
        sp((0.09, 0.03, 0.56), 0.12, n, (), 0),
    ]
    out["wooden_star"] = [
        pg((0, 0, 0.07), star_points(0.56, 0.24), 0.14, w, axis="z"),
    ]
    out["candy_cane"] = [
        bx((0, 0, 0.43), (0.14, 0.14, 0.86), b),
        bx((0, 0.17, 0.88), (0.14, 0.38, 0.14), b),
        bx((0, 0.32, 0.73), (0.14, 0.14, 0.32), b),
        sp((0, 0.32, 0.6), 0.09, b, (), 0),
    ]
    out["sock_ornament"] = [
        bx((0, 0, 0.9), (0.3, 0.28, 0.6), b),
        bx((0.15, 0, 0.2), (0.56, 0.32, 0.28), b),
        bx((0, 0, 1.24), (0.38, 0.36, 0.18), l),
        bx((0.42, 0, 0.2), (0.38, 0.3, 0.22), l),
    ]
    out["gingerbread_man"] = [
        bx((0, 0, 1.06), (0.34, 0.24, 0.32), w),
        bx((0, 0, 0.62), (0.42, 0.2, 0.56), w),
        bx((0.42, 0, 0.78), (0.4, 0.18, 0.15), w),
        bx((-0.42, 0, 0.78), (0.4, 0.18, 0.15), w),
        bx((0.13, 0, 0.25), (0.2, 0.18, 0.45), w),
        bx((-0.13, 0, 0.25), (0.2, 0.18, 0.45), w),
        bx((0, 0.12, 0.78), (0.06, 0.05, 0.05), s),
        bx((0, 0.12, 0.58), (0.06, 0.05, 0.05), s),
    ]
    out["matchbox_car"] = [
        bx((0, 0, 0.14), (1.0, 0.44, 0.2), b),
        bx((-0.08, 0, 0.36), (0.44, 0.4, 0.2), l),
        cy((0.32, 0.25, 0.12), 0.12, 0.09, s, 8, axis="y"),
        cy((0.32, -0.25, 0.12), 0.12, 0.09, s, 8, axis="y"),
        cy((-0.32, 0.25, 0.12), 0.12, 0.09, s, 8, axis="y"),
        cy((-0.32, -0.25, 0.12), 0.12, 0.09, s, 8, axis="y"),
    ]
    out["toy_soldier"] = [
        cy((0, 0, 0.06), 0.32, 0.12, s, 9),
        bx((0, 0, 0.48), (0.5, 0.34, 0.68), b),
        sp((0, 0, 0.95), 0.14, s, (), 0),
        cy((0, 0, 1.3), 0.16, 0.45, b, 8, r2=0.0),
        bx((0.3, 0.18, 0.52), (0.07, 0.07, 0.9), s),
    ]
    out["cocoa_mug"] = [
        cy((0, 0, 0.29), 0.4, 0.56, b, 9),
        cy((0, 0, 0.6), 0.33, 0.07, l, 9),
        bx((0.5, 0, 0.33), (0.07, 0.09, 0.42), b),
        bx((0.44, 0, 0.54), (0.14, 0.09, 0.07), b),
        bx((0.44, 0, 0.13), (0.14, 0.09, 0.07), b),
    ]

    # ---- Tier 2: toys and carryables (budget 300 tris) ----
    out["rubber_duck"] = [
        sp((0, 0, 0.3), 0.4, w, (1.05, 0.85, 0.72)),
        sp((0.25, 0, 0.62), 0.2, w),
        bx((0.5, 0, 0.6), (0.18, 0.15, 0.08), b),
        sp((0.24, 0.14, 0.72), 0.05, s, (), 0),
        sp((0.24, -0.14, 0.72), 0.05, s, (), 0),
        cn((-0.5, 0, 0.42), 0.11, 0.28, w, 7),
    ]
    out["mitten_pair"] = [
        bx((0.58, 0, 0.55), (0.45, 0.32, 0.62), b),
        bx((0.58, 0, 1.03), (0.4, 0.36, 0.2), l),
        cy((0.32, 0, 0.42), 0.1, 0.34, b, 7, axis="x"),
        bx((-0.58, 0, 0.55), (0.45, 0.32, 0.62), b),
        bx((-0.58, 0, 1.03), (0.4, 0.36, 0.2), l),
        cy((-0.32, 0, 0.42), 0.1, 0.34, b, 7, axis="x"),
    ]
    out["gift_box"] = [
        bx((0, 0, 0.35), (1.2, 1.2, 0.7), b),
        bx((0, 0, 0.86), (1.4, 1.4, 0.32), l),
        bx((0, 0, 0.4), (0.16, 1.24, 0.62), n),
        bx((0, 0, 0.4), (1.24, 0.16, 0.62), n),
        sp((0.2, 0, 1.1), 0.12, n, (), 0),
        sp((-0.2, 0, 1.1), 0.12, n, (), 0),
    ]
    out["block_stack"] = [
        bx((0, 0, 0.18), (1.1, 0.85, 0.36), b),
        bx((0.06, 0.02, 0.55), (0.95, 0.7, 0.36), l),
        bx((-0.04, -0.02, 0.9), (0.8, 0.6, 0.34), i, yaw=0.35),
        bx((0.05, 0.04, 1.25), (0.62, 0.52, 0.32), w),
        bx((-0.02, 0, 1.56), (0.46, 0.44, 0.3), s),
    ]
    out["snowball"] = [sp((0, 0, 1.0), 1.0, n)]
    out["snow_boot"] = [
        bx((0, 0, 0.16), (1.5, 0.75, 0.32), s),
        bx((-0.05, 0, 0.58), (1.2, 0.65, 0.55), l),
        bx((0.52, 0, 0.48), (0.44, 0.7, 0.35), n),
        bx((-0.12, 0, 1.0), (1.0, 0.6, 0.28), n),
        bx((-0.15, 0, 0.78), (0.5, 0.72, 0.06), b),
        bx((-0.15, 0, 0.95), (0.5, 0.72, 0.06), b),
    ]
    out["toy_drum"] = [
        cy((0, 0, 0.75), 0.6, 1.5, b, 10),
        cy((0, 0, 0.07), 0.66, 0.14, s, 10),
        cy((0, 0, 1.43), 0.66, 0.14, s, 10),
        bx((0, 0, 0.75), (1.3, 0.14, 0.16), s),
        bx((0, 0, 0.75), (0.14, 1.3, 0.16), s),
        cy((0, 0, 1.53), 0.46, 0.02, l, 10),
    ]
    out["teddy_bear"] = [
        sp((0, 0, 0.85), 0.48, w, (0.95, 0.75, 1.05)),
        sp((0, 0, 1.72), 0.3, w, (1.0, 0.9, 0.95)),
        sp((0.16, 0, 1.98), 0.1, w, (), 0),
        sp((-0.16, 0, 1.98), 0.1, w, (), 0),
        sp((0, 0.24, 1.66), 0.12, l, (1.0, 0.6, 0.7), 0),
        sp((0, 0.26, 0.9), 0.28, l, (0.7, 0.35, 0.85), 0),
        bx((0.53, 0, 0.88), (0.24, 0.24, 0.62), w),
        bx((-0.53, 0, 0.88), (0.24, 0.24, 0.62), w),
        bx((0.26, 0, 0.28), (0.3, 0.28, 0.5), w),
        bx((-0.26, 0, 0.28), (0.3, 0.28, 0.5), w),
    ]
    out["plush_penguin"] = [
        sp((0, 0, 0.85), 0.55, s, (0.85, 0.85, 1.15)),
        sp((0, 0.2, 0.85), 0.5, n, (0.66, 0.45, 1.0)),
        cy((0, 0.62, 1.02), 0.09, 0.22, b, 6, r2=0.0, axis="y"),
        sp((0.15, 0.42, 1.24), 0.06, s, (), 0),
        sp((-0.15, 0.42, 1.24), 0.06, s, (), 0),
        bx((0.58, 0, 0.78), (0.14, 0.32, 0.78), s),
        bx((-0.58, 0, 0.78), (0.14, 0.32, 0.78), s),
        bx((0.18, 0.02, 0.06), (0.26, 0.36, 0.12), b),
        bx((-0.18, 0.02, 0.06), (0.26, 0.36, 0.12), b),
    ]
    out["tin_robot"] = [
        bx((0, 0, 0.85), (0.85, 0.55, 0.95), s),
        bx((0, 0.31, 0.9), (0.45, 0.06, 0.5), b),
        bx((0, 0, 1.55), (0.5, 0.45, 0.4), s),
        bx((0, 0.26, 1.58), (0.36, 0.06, 0.2), i),
        cy((0, 0, 1.92), 0.03, 0.3, s, 5),
        sp((0, 0, 2.14), 0.06, b, (), 0),
        bx((0.56, 0, 0.82), (0.2, 0.2, 0.75), s),
        bx((-0.56, 0, 0.82), (0.2, 0.2, 0.75), s),
        bx((0.2, 0, 0.28), (0.26, 0.28, 0.52), s),
        bx((-0.2, 0, 0.28), (0.26, 0.28, 0.52), s),
        bx((0.2, 0.06, 0.05), (0.32, 0.44, 0.1), b),
        bx((-0.2, 0.06, 0.05), (0.32, 0.44, 0.1), b),
    ]
    out["lantern"] = [
        cy((0, 0, 0.08), 0.5, 0.16, s, 9),
        cy((0, 0, 0.89), 0.07, 1.5, s, 6),
        bx((0, 0, 1.66), (0.5, 0.5, 0.1), s),
        bx((0, 0, 2.0), (0.42, 0.42, 0.62), i),
        bx((0, 0, 2.36), (0.5, 0.5, 0.1), s),
        cy((0, 0, 2.64), 0.42, 0.5, s, 8, r2=0.0),
        cy((0, 0, 2.94), 0.05, 0.2, s, 5),
    ]
    out["cat"] = [
        bx((-0.15, 0, 0.75), (1.5, 0.65, 0.65), w),
        bx((0.8, 0, 1.28), (0.6, 0.55, 0.5), w),
        cy((0.66, 0.16, 1.62), 0.1, 0.22, w, 4, r2=0.0),
        cy((0.66, -0.16, 1.62), 0.1, 0.22, w, 4, r2=0.0),
        bx((1.16, 0, 1.18), (0.2, 0.3, 0.2), l),
        bx((-1.02, 0, 1.42), (0.14, 0.14, 0.5), w),
        bx((-1.02, 0, 1.72), (0.2, 0.2, 0.12), l),
        bx((0.4, 0.26, 0.26), (0.16, 0.16, 0.52), w),
        bx((0.4, -0.26, 0.26), (0.16, 0.16, 0.52), w),
        bx((-0.6, 0.26, 0.26), (0.16, 0.16, 0.52), w),
        bx((-0.6, -0.26, 0.26), (0.16, 0.16, 0.52), w),
    ]
    out["wreath"] = [
        tor((0, 0, 0.3), 1.15, 0.28, w, 9, 4),
        sp((1.15, 0, 0.3), 0.09, b, (), 0),
        sp((-0.74, 0.88, 0.3), 0.09, b, (), 0),
        sp((-0.55, -1.05, 0.3), 0.09, b, (), 0),
    ]
    out["flower_pot"] = [
        cy((0, 0, 0.48), 0.58, 0.95, b, 10, r2=0.86),
        cy((0, 0, 0.99), 0.9, 0.1, s, 10),
        cy((0, 0, 1.05), 0.68, 0.1, s, 10),
        sp((0, 0, 1.24), 0.32, n, (1.0, 1.0, 0.75), 0),
    ]
    out["toy_sled"] = [
        bx((0, 0, 0.8), (1.8, 0.9, 0.12), w),
        bx((0, 0.46, 0.14), (2.0, 0.14, 0.28), l),
        bx((0, -0.46, 0.14), (2.0, 0.14, 0.28), l),
        bx((0.6, 0.46, 0.45), (0.1, 0.1, 0.5), w),
        bx((0.6, -0.46, 0.45), (0.1, 0.1, 0.5), w),
        bx((-0.6, 0.46, 0.45), (0.1, 0.1, 0.5), w),
        bx((-0.6, -0.46, 0.45), (0.1, 0.1, 0.5), w),
        bx((0.94, 0.46, 0.42), (0.16, 0.14, 0.44), s),
        bx((0.94, -0.46, 0.42), (0.16, 0.14, 0.44), s),
    ]
    out["rocking_horse"] = [
        bx((0, 0.34, 0.15), (2.8, 0.14, 0.3), w),
        bx((0, -0.34, 0.15), (2.8, 0.14, 0.3), w),
        bx((0.75, 0.34, 0.62), (0.12, 0.12, 0.62), w),
        bx((0.75, -0.34, 0.62), (0.12, 0.12, 0.62), w),
        bx((-0.75, 0.34, 0.62), (0.12, 0.12, 0.62), w),
        bx((-0.75, -0.34, 0.62), (0.12, 0.12, 0.62), w),
        bx((0, 0, 1.15), (1.2, 0.5, 0.5), b),
        bx((0.8, 0, 1.45), (0.5, 0.38, 0.42), b),
        bx((1.12, 0, 1.42), (0.2, 0.3, 0.26), l),
        cy((0.62, 0.12, 1.78), 0.09, 0.2, l, 4, r2=0.0),
        cy((0.62, -0.12, 1.78), 0.09, 0.2, l, 4, r2=0.0),
        bx((0.45, 0.13, 0.62), (0.14, 0.16, 0.6), b),
        bx((0.45, -0.13, 0.62), (0.14, 0.16, 0.6), b),
        bx((-0.45, 0.13, 0.62), (0.14, 0.16, 0.6), b),
        bx((-0.45, -0.13, 0.62), (0.14, 0.16, 0.6), b),
        cy((-0.66, 0, 1.15), 0.14, 0.4, b, 7, axis="y"),
    ]

    # ---- Tier 3: street furniture (budget 800 tris) ----
    out["barrel"] = [
        cy((0, 0, 0.5), 1.1, 1.0, w, 12, r2=1.5),
        cy((0, 0, 2.1), 1.5, 2.2, w, 12),
        cy((0, 0, 3.7), 1.5, 1.0, w, 12, r2=1.1),
        cy((0, 0, 0.8), 1.57, 0.15, s, 12),
        cy((0, 0, 3.4), 1.57, 0.15, s, 12),
    ]
    out["mailbox"] = [
        bx((0, 0, 1.0), (0.3, 0.3, 2.0), w),
        cy((1.3, 0, 2.6), 0.6, 2.2, b, 9, axis="x"),
        bx((2.44, 0, 2.6), (0.08, 0.95, 0.64), s),
        bx((1.8, 0, 3.25), (0.12, 0.32, 0.35), b),
        bx((0, 0, 0.06), (0.7, 0.7, 0.12), s),
    ]
    out["giant_gift"] = [
        bx((0, 0, 1.3), (3.2, 3.2, 2.6), b),
        bx((0, 0, 2.8), (3.5, 3.5, 0.4), l),
        bx((0, 0, 1.3), (0.45, 3.24, 2.6), n),
        bx((0, 0, 1.3), (3.24, 0.45, 2.6), n),
        sp((0.5, 0, 3.2), 0.3, n),
        sp((-0.5, 0, 3.2), 0.3, n),
        bx((0, 0, 3.2), (0.4, 0.4, 0.4), n),
    ]
    out["snow_mound"] = [sp((0, 0, 1.3), 2.4, n, (1.0, 1.0, 0.55))]
    out["dog"] = [
        bx((0, 0, 1.15), (2.2, 1.0, 1.0), w),
        bx((1.5, 0, 1.9), (0.85, 0.8, 0.75), w),
        bx((2.15, 0, 1.75), (0.45, 0.42, 0.4), l),
        cy((1.45, 0.3, 2.42), 0.14, 0.45, b, 4, r2=0.0),
        cy((1.45, -0.3, 2.42), 0.14, 0.45, b, 4, r2=0.0),
        sp((1.95, 0.26, 2.15), 0.08, s, (), 0),
        sp((1.95, -0.26, 2.15), 0.08, s, (), 0),
        bx((-1.35, 0, 1.85), (0.4, 0.16, 0.55), w),
        bx((0.75, 0.38, 0.5), (0.28, 0.28, 1.0), w),
        bx((0.75, -0.38, 0.5), (0.28, 0.28, 1.0), w),
        bx((-0.75, 0.38, 0.5), (0.28, 0.28, 1.0), w),
        bx((-0.75, -0.38, 0.5), (0.28, 0.28, 1.0), w),
        bx((1.02, 0, 1.6), (0.14, 0.88, 0.3), b),
    ]
    out["fence_section"] = [
        bx((-1.7, 0, 0.95), (0.2, 0.16, 1.9), w),
        bx((-0.57, 0, 0.95), (0.2, 0.16, 1.9), w),
        bx((0.57, 0, 0.95), (0.2, 0.16, 1.9), w),
        bx((1.7, 0, 0.95), (0.2, 0.16, 1.9), w),
        bx((-2.3, 0, 1.1), (0.34, 0.34, 2.2), w),
        bx((2.3, 0, 1.1), (0.34, 0.34, 2.2), w),
        bx((0, 0, 0.55), (4.4, 0.12, 0.16), w),
        bx((0, 0, 1.55), (4.4, 0.12, 0.16), w),
    ]
    out["firewood_stack"] = (
        [cy((x, 0, 0.32), 0.32, 4.6, w, 7, axis="y") for x in (-1.5, -0.5, 0.5, 1.5)]
        + [cy((x, 0, 0.88), 0.32, 4.6, w, 7, axis="y") for x in (-1.0, 0.0, 1.0)]
        + [cy((x, 0, 1.44), 0.32, 4.6, w, 7, axis="y") for x in (-0.5, 0.5)]
        + [cy((0, 0, 2.0), 0.32, 4.6, w, 7, axis="y")]
    )
    out["sledge"] = [
        bx((0, 0, 1.35), (4.2, 1.9, 0.3), w),
        bx((0, 0.85, 1.0), (4.4, 0.16, 0.42), w),
        bx((0, -0.85, 1.0), (4.4, 0.16, 0.42), w),
        bx((0, 0.85, 0.15), (4.8, 0.2, 0.3), s),
        bx((0, -0.85, 0.15), (4.8, 0.2, 0.3), s),
        bx((1.4, 0.85, 0.62), (0.14, 0.14, 0.85), w),
        bx((1.4, -0.85, 0.62), (0.14, 0.14, 0.85), w),
        bx((-1.4, 0.85, 0.62), (0.14, 0.14, 0.85), w),
        bx((-1.4, -0.85, 0.62), (0.14, 0.14, 0.85), w),
        cy((2.35, 0, 1.9), 0.09, 1.7, w, 7, axis="y"),
        bx((2.2, 0, 1.35), (0.15, 0.15, 0.9), w),
    ]
    out["bicycle"] = [
        tor((1.75, 0, 1.12), 1.05, 0.12, s, 10, 4, stand=True),
        tor((-1.75, 0, 1.12), 1.05, 0.12, s, 10, 4, stand=True),
        bx((-0.35, 0, 1.45), (0.12, 0.12, 1.5), w),
        bx((0.55, 0, 2.05), (1.6, 0.12, 0.12), w),
        bx((0.45, 0, 1.45), (1.7, 0.12, 0.12), w),
        bx((-0.3, 0, 1.15), (1.5, 0.12, 0.12), w),
        bx((1.3, 0, 1.7), (0.12, 0.12, 0.9), w),
        cy((1.35, 0, 2.2), 0.06, 1.1, w, 7, axis="y"),
        bx((1.75, 0, 1.7), (0.1, 0.14, 1.3), w),
        bx((-0.35, 0, 2.3), (0.5, 0.3, 0.12), b),
        cy((-0.35, 0, 1.05), 0.16, 0.06, s, 6, axis="y"),
    ]
    out["bench"] = [
        bx((0, 0, 0.95), (3.0, 1.0, 0.16), w),
        bx((0, 0, 1.08), (2.9, 0.9, 0.12), n),
        bx((0, 0.62, 1.85), (3.0, 0.14, 1.0), w),
        bx((0, 0.62, 2.42), (2.85, 0.18, 0.14), n),
        bx((1.3, 0.38, 0.48), (0.2, 0.2, 0.95), w),
        bx((1.3, -0.38, 0.48), (0.2, 0.2, 0.95), w),
        bx((-1.3, 0.38, 0.48), (0.2, 0.2, 0.95), w),
        bx((-1.3, -0.38, 0.48), (0.2, 0.2, 0.95), w),
    ]
    out["snowman"] = [
        sp((0, 0, 1.55), 1.6, n, (1.0, 1.0, 0.95)),
        sp((0, 0, 3.95), 1.15, n),
        sp((0, 0, 5.4), 0.85, n),
        sp((0.26, 0.68, 5.6), 0.12, s, (), 0),
        sp((-0.26, 0.68, 5.6), 0.12, s, (), 0),
        cy((0, 0.78, 5.35), 0.17, 0.62, b, 7, axis="y", r2=0.0),
        cy((0, 0, 6.52), 0.95, 0.14, s, 10),
        cy((0, 0, 6.9), 0.6, 0.65, s, 10),
        bx((0, 0, 4.62), (2.3, 2.3, 0.3), b),
        bx((0.45, 0.92, 4.1), (0.3, 0.22, 0.9), b),
        bx((1.35, 0, 4.4), (1.4, 0.12, 0.12), w),
        bx((-1.35, 0, 4.4), (1.4, 0.12, 0.12), w),
        sp((0, 1.02, 3.6), 0.12, s, (), 0),
        sp((0, 1.02, 3.05), 0.12, s, (), 0),
    ]
    out["cocoa_cart"] = [
        bx((0, 0, 1.4), (2.6, 1.8, 1.6), b),
        bx((0, 0, 2.34), (2.8, 1.9, 0.14), w),
        cy((0.95, 1.02, 0.75), 0.75, 0.14, w, 10, axis="y"),
        cy((0.95, -1.02, 0.75), 0.75, 0.14, w, 10, axis="y"),
        cy((-1.6, 0, 1.95), 0.07, 1.7, w, 7, axis="y"),
        bx((0.7, 0, 2.7), (0.3, 0.3, 0.95), s),
        bx((1.25, 0.85, 3.02), (0.12, 0.12, 1.15), w),
        bx((1.25, -0.85, 3.02), (0.12, 0.12, 1.15), w),
        bx((-1.25, 0.85, 3.02), (0.12, 0.12, 1.15), w),
        bx((-1.25, -0.85, 3.02), (0.12, 0.12, 1.15), w),
        bx((0, 0, 3.66), (2.9, 2.1, 0.14), l),
    ]
    out["pine_sapling"] = [
        cy((0, 0, 1.2), 0.4, 2.4, w, 7),
        cy((0, 0, 3.4), 2.0, 2.0, w, 9, r2=0.0),
        cy((0, 0, 5.0), 1.55, 1.9, w, 9, r2=0.0),
        cy((0, 0, 6.5), 1.1, 1.8, w, 9, r2=0.0),
        sp((0, 0, 3.0), 0.5, n, (1.0, 1.0, 0.55), 0),
        sp((0.95, 0, 4.85), 0.4, n, (1.0, 1.0, 0.55), 0),
        sp((-0.7, 0, 6.4), 0.35, n, (1.0, 1.0, 0.55), 0),
    ]
    out["street_lamp"] = [
        cy((0, 0, 0.25), 0.7, 0.5, s, 9),
        cy((0, 0, 1.5), 0.32, 0.3, s, 8),
        cy((0, 0, 4.55), 0.22, 7.3, s, 8),
        bx((0, 0, 8.55), (0.75, 0.75, 1.0), i),
        cy((0, 0, 9.3), 0.62, 0.55, s, 8, r2=0.0),
        sp((0, 0, 9.65), 0.12, s, (), 0),
    ]

    # ---- Tier 4: landmarks of the street (budget 2500 tris) ----
    out["bus_shelter"] = [
        bx((0, 0, 0.12), (4.6, 2.6, 0.24), s),
        bx((0, 0, 3.0), (5.0, 3.2, 0.3), b),
        bx((2.2, 1.3, 1.6), (0.18, 0.18, 2.6), w),
        bx((2.2, -1.3, 1.6), (0.18, 0.18, 2.6), w),
        bx((-2.2, 1.3, 1.6), (0.18, 0.18, 2.6), w),
        bx((-2.2, -1.3, 1.6), (0.18, 0.18, 2.6), w),
        bx((0, -1.25, 1.6), (4.4, 0.14, 2.5), i),
        bx((2.2, 0, 1.6), (0.12, 2.4, 2.5), i),
        bx((-2.2, 0, 1.6), (0.12, 2.4, 2.5), i),
        bx((0, -0.55, 0.75), (3.4, 0.4, 0.14), w),
        bx((1.4, 1.42, 2.3), (0.8, 0.1, 0.6), l),
    ]
    out["market_stall"] = [
        bx((0, -0.6, 0.5), (5.0, 1.5, 1.0), w),
        bx((2.5, -1.25, 1.6), (0.2, 0.2, 3.2), w),
        bx((2.5, 1.25, 1.6), (0.2, 0.2, 3.2), w),
        bx((-2.5, -1.25, 1.6), (0.2, 0.2, 3.2), w),
        bx((-2.5, 1.25, 1.6), (0.2, 0.2, 3.2), w),
        bx((0, 0, 3.2), (5.6, 2.6, 0.26), l),
        bx((0, 0, 3.5), (6.2, 3.0, 0.24), b),
        bx((-1.6, -0.45, 1.15), (0.5, 0.4, 0.3), b),
        bx((-0.4, -0.45, 1.15), (0.45, 0.4, 0.3), s),
        bx((0.8, -0.5, 1.18), (0.5, 0.35, 0.3), i),
        sp((1.9, -0.45, 1.18), 0.2, b, (), 0),
        bx((-1.9, 0.9, 0.25), (0.7, 0.7, 0.5), w),
        bx((1.9, 0.9, 0.25), (0.7, 0.7, 0.5), w),
        bx((0, 1.28, 2.6), (4.0, 0.06, 0.55), b),
    ]
    out["big_snowman"] = [
        sp((0, 0, 2.3), 2.4, n, (1.0, 1.0, 0.95)),
        sp((0, 0, 5.85), 1.7, n),
        sp((0, 0, 8.15), 1.25, n),
        sp((0.38, 1.0, 8.4), 0.18, s, (), 0),
        sp((-0.38, 1.0, 8.4), 0.18, s, (), 0),
        sp((0, 1.6, 6.2), 0.2, s, (), 0),
        sp((0, 1.55, 5.35), 0.2, s, (), 0),
        sp((0, 1.45, 4.5), 0.2, s, (), 0),
        cy((0, 1.2, 8.1), 0.3, 1.0, b, 7, axis="y", r2=0.0),
        cy((0, 0, 10.0), 1.4, 0.18, s, 10),
        cy((0, 0, 10.55), 0.95, 0.95, s, 10),
        bx((0, 0, 7.35), (2.7, 2.7, 0.5), b),
        bx((0.4, 1.45, 6.6), (0.45, 0.3, 1.4), b),
        bx((2.2, 0, 6.0), (1.6, 0.2, 0.2), w),
        bx((-2.2, 0, 6.0), (1.6, 0.2, 0.2), w),
    ]
    out["kiosk"] = [
        bx((0, 0, 1.8), (3.4, 3.4, 3.6), w),
        bx((0, 0, 2.7), (3.5, 3.5, 1.0), i),
        bx((0, 0, 3.72), (3.9, 3.9, 0.2), s),
        cy((0, 0, 4.62), 2.7, 1.8, b, 4, r2=0.0, yaw=math.pi / 4),
        bx((0, 1.95, 0.65), (1.8, 1.0, 0.3), w),
        bx((0, -1.75, 3.05), (2.4, 0.14, 0.62), l),
    ]
    out["fountain"] = [
        cy((0, 0, 0.55), 4.2, 1.1, s, 14),
        tor((0, 0, 1.12), 4.2, 0.18, i, 14, 4),
        cy((0, 0, 1.55), 0.5, 1.8, s, 8),
        cy((0, 0, 2.72), 1.7, 0.55, s, 12, r2=0.9),
        cy((0, 0, 2.98), 1.25, 0.12, i, 12),
        cy((0, 0, 3.3), 0.14, 0.55, s, 6),
        cn((0, 0, 3.55), 0.4, 0.5, i, 8),
    ]
    out["car"] = [
        bx((0, 0, 1.15), (4.6, 2.0, 0.75), l),
        bx((-0.3, 0, 1.9), (2.3, 1.75, 0.75), i),
        bx((-0.3, 0, 2.33), (2.1, 1.6, 0.12), n),
        cy((1.7, 0.95, 0.5), 0.5, 0.3, s, 10, axis="y"),
        cy((1.7, -0.95, 0.5), 0.5, 0.3, s, 10, axis="y"),
        cy((-1.7, 0.95, 0.5), 0.5, 0.3, s, 10, axis="y"),
        cy((-1.7, -0.95, 0.5), 0.5, 0.3, s, 10, axis="y"),
        bx((2.42, 0, 0.95), (0.32, 1.9, 0.35), s),
        bx((-2.42, 0, 0.95), (0.32, 1.9, 0.35), s),
        bx((2.4, 0.55, 1.3), (0.1, 0.3, 0.2), i),
        bx((2.4, -0.55, 1.3), (0.1, 0.3, 0.2), i),
    ]
    out["sleigh"] = [
        bx((0, 0, 1.5), (4.4, 2.3, 1.4), b),
        bx((2.0, 0, 2.75), (0.5, 2.3, 1.9), b),
        sp((2.2, 0, 3.85), 0.35, b, (), 0),
        bx((0, 1.2, 0.2), (4.8, 0.22, 0.4), w),
        bx((0, -1.2, 0.2), (4.8, 0.22, 0.4), w),
        bx((1.6, 1.2, 0.85), (0.18, 0.18, 0.9), w),
        bx((1.6, -1.2, 0.85), (0.18, 0.18, 0.9), w),
        bx((-1.6, 1.2, 0.85), (0.18, 0.18, 0.9), w),
        bx((-1.6, -1.2, 0.85), (0.18, 0.18, 0.9), w),
        bx((-0.5, 0, 2.4), (1.5, 2.0, 0.35), w),
        bx((-1.7, 0, 2.9), (0.3, 2.0, 1.1), w),
    ]
    out["van"] = [
        bx((0, 0, 2.1), (5.2, 2.6, 3.8), l),
        bx((2.65, 0, 3.1), (0.14, 2.3, 1.3), i),
        bx((0.6, 1.32, 3.0), (3.0, 0.12, 1.1), i),
        bx((0.6, -1.32, 3.0), (3.0, 0.12, 1.1), i),
        bx((0, 0, 4.12), (5.0, 2.4, 0.16), n),
        bx((0, 1.15, 4.3), (4.6, 0.15, 0.2), s),
        bx((0, -1.15, 4.3), (4.6, 0.15, 0.2), s),
        cy((1.9, 1.35, 0.65), 0.65, 0.35, s, 10, axis="y"),
        cy((1.9, -1.35, 0.65), 0.65, 0.35, s, 10, axis="y"),
        cy((-1.9, 1.35, 0.65), 0.65, 0.35, s, 10, axis="y"),
        cy((-1.9, -1.35, 0.65), 0.65, 0.35, s, 10, axis="y"),
        bx((2.7, 0, 0.7), (0.35, 2.4, 0.55), s),
        bx((-2.7, 0, 0.7), (0.35, 2.4, 0.55), s),
    ]
    out["bandstand"] = (
        [cy((0, 0, 0.15), 6.8, 0.3, s, 14)]
        + [cy((0, 0, 0.55), 6.0, 0.5, w, 14)]
        + [cy((x, y, 3.2), 0.28, 4.8, l, 8) for x, y in (
            (4.7, 0.0), (3.32, 3.32), (0.0, 4.7), (-3.32, 3.32),
            (-4.7, 0.0), (-3.32, -3.32), (0.0, -4.7), (3.32, -3.32))]
        + [tor((0, 0, 5.74), 4.9, 0.35, w, 12, 4), cy((0, 0, 7.2), 5.8, 2.4, b, 14, r2=0.0),
           cy((0, 0, 8.95), 0.15, 0.55, s, 6), sp((0, 0, 9.4), 0.35, b, (), 0)]
    )
    out["christmas_tree"] = [
        cy((0, 0, 1.4), 0.9, 2.8, w, 8),
        cy((0, 0, 4.35), 4.0, 3.9, w, 9, r2=0.0),
        cy((0, 0, 7.1), 3.1, 3.6, w, 9, r2=0.0),
        cy((0, 0, 9.65), 2.3, 3.1, w, 9, r2=0.0),
        cy((0, 0, 11.9), 1.55, 2.7, w, 9, r2=0.0),
        pg((0, 0, 14.1), star_points(0.95, 0.4), 0.4, w, axis="y"),
        sp((2.2, 0, 4.5), 0.45, b, (), 0),
        sp((-1.9, 1.4, 6.9), 0.45, b, (), 0),
        sp((1.3, -1.7, 9.3), 0.45, b, (), 0),
        sp((0, 2.0, 11.4), 0.45, b, (), 0),
        sp((-1.2, -0.9, 5.6), 0.4, b, (), 0),
    ]
    out["snowplough"] = [
        bx((-0.4, 0, 0.8), (6.6, 3.0, 1.0), s),
        bx((-0.4, 0, 2.6), (6.6, 3.2, 3.6), b),
        bx((1.1, 0, 5.5), (2.8, 3.0, 2.2), l),
        bx((2.55, 0, 5.85), (0.14, 2.7, 1.15), i),
        bx((-2.9, 0.85, 5.95), (0.4, 0.4, 1.5), s),
        cy((2.2, 1.72, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((2.2, -1.72, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((0.2, 1.72, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((0.2, -1.72, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((-2.4, 1.72, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((-2.4, -1.72, 0.85), 0.85, 0.4, s, 10, axis="y"),
        pg((4.4, 0, 1.5), [(-1.25, -1.7), (-1.25, 1.7), (1.35, 0.0)], 2.9, s, axis="z"),
    ]
    out["bus"] = [
        bx((0, 0, 0.9), (9.4, 3.2, 0.8), s),
        bx((0, 0, 3.4), (9.8, 3.4, 5.0), b),
        bx((0, 0, 4.4), (9.85, 3.45, 2.0), i),
        bx((0, 0, 6.05), (9.6, 3.3, 0.2), l),
        cy((3.6, 1.75, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((3.6, -1.75, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((0.2, 1.75, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((0.2, -1.75, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((-3.4, 1.75, 0.85), 0.85, 0.4, s, 10, axis="y"),
        cy((-3.4, -1.75, 0.85), 0.85, 0.4, s, 10, axis="y"),
        bx((4.85, 0, 5.65), (0.9, 0.1, 0.7), l),
        bx((0, 1.2, 6.3), (8.4, 0.14, 0.18), s),
        bx((0, -1.2, 6.3), (8.4, 0.14, 0.18), s),
    ]

    # ---- Tier 5: landmarks (budget 2500 tris) ----
    out["cottage"] = [
        bx((0, 0, 3.75), (13.0, 10.5, 7.5), l),
        pg((0, 0, 7.5), [(-7.4, 0.0), (7.4, 0.0), (0.0, 4.8)], 12.0, n, axis="y"),
        bx((3.8, -2.4, 9.3), (1.7, 1.7, 4.8), b),
        bx((3.8, -2.4, 11.85), (2.1, 2.1, 0.35), s),
        bx((0, -5.4, 2.1), (2.3, 0.3, 4.2), b),
        bx((3.4, -5.38, 4.6), (1.9, 0.25, 1.9), i),
        bx((-3.4, -5.38, 4.6), (1.9, 0.25, 1.9), i),
        bx((3.4, -5.42, 3.5), (2.3, 0.35, 0.3), s),
        bx((-3.4, -5.42, 3.5), (2.3, 0.35, 0.3), s),
        bx((0, -6.9, 3.4), (5.5, 2.4, 0.3), w),
        bx((2.3, -6.6, 1.6), (0.5, 0.5, 3.2), w),
        bx((-2.3, -6.6, 1.6), (0.5, 0.5, 3.2), w),
        bx((0, -6.5, 0.2), (2.7, 1.4, 0.4), s),
    ]
    out["town_house"] = [
        bx((0, 0, 7.5), (12.0, 10.0, 15.0), b),
        bx((0, 0, 15.9), (13.2, 11.0, 1.6), l),
        bx((0, 0, 16.92), (11.0, 9.0, 0.3), n),
        bx((0, -5.2, 2.3), (2.6, 0.35, 4.6), s),
        bx((0, -5.9, 0.2), (3.2, 1.6, 0.4), s),
        *(
            part
            for x in (-3.6, 3.6)
            for z in (4.4, 9.6, 13.0)
            for part in (
                bx((x, -5.15, z), (2.0, 0.2, 2.6), i),
                bx((x, -5.2, z - 1.72), (2.6, 0.35, 0.3), s),
                bx((x, -5.2, z + 1.72), (2.6, 0.35, 0.3), s),
            )
        ),
        bx((-6.35, 0, 9.6), (0.2, 2.0, 2.6), i),
        bx((6.35, 0, 9.6), (0.2, 2.0, 2.6), i),
    ]
    out["skating_rink"] = [
        cy((0, 0, 0.25), 17.0, 0.5, i, 18),
        tor((0, 0, 0.88), 17.0, 1.3, n, 18, 4),
        *(
            part
            for angle_deg in (30, 150, 210, 330)
            for angle in (math.radians(angle_deg),)
            for part in (
                cy((12.5 * math.cos(angle), 12.5 * math.sin(angle), 2.25),
                   0.28, 4.5, s, 7),
                sp((12.5 * math.cos(angle), 12.5 * math.sin(angle), 4.85),
                   0.55, i, (), 0),
            )
        ),
        pg((0, 0, 2.6), [(-2.0, 2.0), (6.4, 0.9), (4.0, 3.4)], 0.6, w, axis="z"),
    ]
    out["clock_tower"] = [
        bx((0, 0, 0.5), (15.0, 15.0, 1.0), s),
        bx((0, 0, 7.0), (13.0, 13.0, 13.0), s),
        bx((0, 0, 18.5), (10.0, 10.0, 8.0), s),
        cy((0, 5.35, 18.6), 2.9, 0.35, s, 12, axis="y"),
        cy((0, 5.6, 18.6), 2.55, 0.3, i, 12, axis="y"),
        bx((0, 5.75, 19.35), (0.35, 0.16, 1.9), s),
        bx((0.55, 5.75, 18.55), (1.5, 0.16, 0.35), s),
        bx((0, 0, 26.0), (9.0, 9.0, 5.0), s),
        cy((0, 0, 32.5), 6.8, 7.0, b, 4, r2=0.0, yaw=math.pi / 4),
        cy((0, 0, 36.7), 0.3, 1.4, s, 6),
        sp((0, 0, 37.7), 0.5, b, (), 0),
    ]

    # ---- Hub decoration (no size rule; budget = top tier) ----
    out["hub"] = [
        cy((0, 0, 0.3), 5.6, 0.6, s, 8),
        cy((0, 0, 0.74), 5.15, 0.28, w, 8),
        bx((0, -5.35, 0.15), (2.2, 1.2, 0.3), w),
        bx((0, -6.15, 0.45), (2.2, 1.2, 0.3), s),
        *(
            cy((4.55 * math.cos(math.radians(60.0 * k)), 4.55 * math.sin(math.radians(60.0 * k)), 2.8),
               0.26, 3.4, w, 7)
            for k in range(6)
        ),
        tor((0, 0, 4.66), 4.55, 0.24, w, 12, 4),
        cy((0, 0, 5.9), 6.0, 2.2, n, 8, r2=0.0),
        cy((0, 0, 7.2), 0.18, 0.5, w, 6),
        sp((0, 0, 7.6), 0.32, b, (), 0),
        cy((0, 0, 2.3), 0.1, 1.7, s, 6),
        cy((0, 0, 3.4), 0.34, 0.4, i, 6),
    ]
    return out


# ---------------------------------------------------------------- assembly

def emit(builder: "Builder", part) -> None:
    kind = part[0]
    if kind == "box":
        _, c, dims, swatch, yaw = part
        builder.box(c, dims, swatch, yaw)
    elif kind == "cyl":
        _, c, radius, depth, swatch, segments, r2, axis, yaw = part
        builder.cyl(c, radius, depth, swatch, segments=segments,
                    radius_top=r2 if r2 is not None else radius, axis=axis, yaw=yaw)
    elif kind == "sph":
        _, c, radius, swatch, squash, sub = part
        builder.sphere(c, radius, swatch, squash=tuple(squash), subdivisions=sub)
    elif kind == "prism":
        _, c, pts, span, swatch, axis, yaw = part
        builder.prism(c, list(pts), span, swatch, axis=axis, yaw=yaw)
    elif kind == "torus":
        _, c, R, r, swatch, major, minor, stand = part
        builder.torus(c, R, r, swatch, major=major, minor=minor, stand=stand)
    else:
        raise RuntimeError(f"unknown primitive kind {kind}")


class Builder:
    """Adds primitives to a shared bmesh, tagging every face with its palette swatch."""

    def __init__(self, bm, tags):
        self.bm = bm
        self.tags = tags

    def _record(self, faces, swatch: str) -> None:
        for face in faces:
            self.tags.append((face, swatch))

    @staticmethod
    def _faces_of(result) -> set:
        # Every face linked to the verts that bmesh.ops.create_* just returned.
        return {face for vert in result["verts"] for face in vert.link_faces}

    def _matrix(self, centre, yaw=0.0, extra=None):
        m = Matrix.Translation(Vector(centre))
        if yaw:
            m = m @ Matrix.Rotation(yaw, 4, "Z")
        if extra is not None:
            m = m @ extra
        return m

    def box(self, c, dims, swatch, yaw=0.0):
        scale = Matrix.Diagonal((dims[0], dims[1], dims[2], 1.0))
        result = bmesh.ops.create_cube(self.bm, size=1.0, matrix=self._matrix(c, yaw, scale))
        self._record(self._faces_of(result), swatch)

    def cyl(self, c, radius, depth, swatch, segments=8, radius_top=None, axis="z", yaw=0.0):
        rot = {"z": None, "x": Matrix.Rotation(math.pi / 2, 4, "Y"),
               "y": Matrix.Rotation(-math.pi / 2, 4, "X")}[axis]
        matrix = self._matrix(c, yaw, rot)
        result = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=max(3, segments),
                                       radius1=radius, radius2=radius if radius_top is None else radius_top,
                                       depth=depth, matrix=matrix, calc_uvs=False)
        self._record(self._faces_of(result), swatch)

    def prism(self, c, pts, span, swatch, axis="y", yaw=0.0):
        rot = self._matrix(c, yaw)
        n = len(pts)
        faces = []
        if axis == "y":
            base = [self.bm.verts.new(rot @ Vector((x, -span / 2.0, z))) for x, z in pts]
            top = [self.bm.verts.new(rot @ Vector((x, span / 2.0, z))) for x, z in pts]
        else:
            base = [self.bm.verts.new(rot @ Vector((x, y, -span / 2.0))) for x, y in pts]
            top = [self.bm.verts.new(rot @ Vector((x, y, span / 2.0))) for x, y in pts]
        faces.append(self.bm.faces.new(list(reversed(base))))
        faces.append(self.bm.faces.new(top))
        for index in range(n):
            faces.append(self.bm.faces.new(
                (base[index], base[(index + 1) % n], top[(index + 1) % n], top[index])))
        self._record(faces, swatch)

    def sphere(self, c, radius, swatch, squash=(1.0, 1.0, 1.0), subdivisions=1):
        if not squash:
            squash = (1.0, 1.0, 1.0)
        scale = Matrix.Diagonal((radius * squash[0], radius * squash[1], radius * squash[2], 1.0))
        result = bmesh.ops.create_icosphere(self.bm, subdivisions=subdivisions, radius=1.0,
                                            matrix=self._matrix(c, 0.0, scale), calc_uvs=False)
        self._record(self._faces_of(result), swatch)

    def torus(self, c, R, r, swatch, major=8, minor=4, stand=False):
        rotation = Matrix.Rotation(math.pi / 2, 4, "X") if stand else Matrix.Identity(4)
        ring = [[None for _ in range(minor)] for _ in range(major)]
        for i in range(major):
            angle = 2.0 * math.pi * i / major
            ring_dir = Vector((math.cos(angle), math.sin(angle), 0.0))
            slide = Vector((-math.sin(angle), math.cos(angle), 0.0))
            centre_i = (rotation @ ring_dir) * R + Vector(c)
            for j in range(minor):
                phi = 2.0 * math.pi * j / minor
                offset = ring_dir * math.cos(phi) * r + Vector((0.0, 0.0, 1.0)) * math.sin(phi) * r
                point = centre_i + rotation @ offset
                ring[i][j] = self.bm.verts.new(point)
        faces = []
        for i in range(major):
            for j in range(minor):
                i2 = (i + 1) % major
                j2 = (j + 1) % minor
                faces.append(self.bm.faces.new((ring[i][j], ring[i2][j], ring[i2][j2], ring[i][j2])))
        self._record(faces, swatch)


def bbox_of(bm) -> tuple:
    xs, ys, zs = [], [], []
    for v in bm.verts:
        xs.append(v.co.x)
        ys.append(v.co.y)
        zs.append(v.co.z)
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def assign_uvs(bm, tags, swatch_rects) -> int:
    """Planar-projects each polygon into its swatch cell; returns the post-triangulation tri count."""
    layer = bm.loops.layers.uv.new("UVMap")
    inner = CELL * (1.0 - 2.0 * UV_MARGIN)
    for face, swatch in tags:
        u, v = swatch_rects[swatch]
        u0, v0 = u - inner / 2.0, v - inner / 2.0
        nx, ny, nz = abs(face.normal.x), abs(face.normal.y), abs(face.normal.z)
        if nx >= ny and nx >= nz:
            ax_u, ax_v = 1, 2
        elif ny >= nz:
            ax_u, ax_v = 2, 0
        else:
            ax_u, ax_v = 0, 1
        us = [loop.vert.co[ax_u] for loop in face.loops]
        vs = [loop.vert.co[ax_v] for loop in face.loops]
        span_u = max(us) - min(us)
        span_v = max(vs) - min(vs)
        for loop in face.loops:
            su = (loop.vert.co[ax_u] - min(us)) / span_u if span_u > EPS else 0.5
            sv = (loop.vert.co[ax_v] - min(vs)) / span_v if span_v > EPS else 0.5
            loop[layer].uv = (u0 + su * inner, v0 + sv * inner)
    return sum(max(1, len(f.verts) - 2) for f in bm.faces)


def palette_material() -> bpy.types.Material:
    material = bpy.data.materials.get("Palette")
    if material is not None:
        return material
    material = bpy.data.materials.new("Palette")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    image = bpy.data.images.load(os.path.join(art_dir(), "palette.png"), check_existing=True)
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Closest"
    bsdf = next((n for n in nodes if n.bl_idname == "ShaderNodeBsdfPrincipled"), None)
    if bsdf is None:
        raise RuntimeError("no principled BSDF in the new material")
    links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def build_file(tier_file: str, object_ids: list, recipes: dict, sizes: dict,
               swatch_rects: dict, budgets: dict) -> None:
    bpy.ops.wm.read_homefile(use_empty=True)
    palette_material()
    for object_id in object_ids:
        bm = bmesh.new()
        tags = []
        builder = Builder(bm, tags)
        for part in recipes[object_id]:
            emit(builder, part)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

        # Normalise: uniform scale so the longest bounding side equals the ObjectDef size, then origin at
        # the bottom centre of the footprint. The hub has no size rule and keeps its authored scale.
        x0, x1, y0, y1, z0, z1 = bbox_of(bm)
        longest = max(x1 - x0, y1 - y0, z1 - z0)
        size = sizes.get(object_id, 0) or 0
        if size:
            scale = size / longest
            bmesh.ops.scale(bm, vec=Vector((scale, scale, scale)), verts=bm.verts)
            x0, x1, y0, y1, z0, z1 = bbox_of(bm)
        bmesh.ops.translate(
            bm,
            vec=Vector((-(x0 + x1) / 2.0, -(y0 + y1) / 2.0, -z0)),
            verts=bm.verts,
        )

        tier = budgets["tiers"][object_id]
        limit = budgets["meshTriangles"][tier - 1]
        tris = assign_uvs(bm, tags, swatch_rects)
        if tris > limit:
            raise RuntimeError(f"{object_id}: {tris} post-triangulation triangles over budget {limit}")

        mesh = bpy.data.meshes.new(object_id)
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        mesh.materials.append(palette_material())
        obj = bpy.data.objects.new(object_id, mesh)
        collection = bpy.data.collections.get(object_id) or bpy.data.collections.new(object_id)
        collection.objects.link(obj)
        bpy.context.scene.collection.children.link(collection)
        print(f"build: {object_id}: {tris} / {limit} tris")
    path = os.path.join(source_dir(), f"{tier_file}.blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    print(f"build: wrote {path}")


def main() -> None:
    os.makedirs(source_dir(), exist_ok=True)
    budgets = load_json(os.path.join(art_dir(), "scripts", "budgets.json"))
    palette = load_json(os.path.join(art_dir(), "palette.json"))
    rects = {
        name: (centre["u"], centre["v"]) for name, centre in palette.items()
    }
    recipes = all_recipes()
    missing = [obj_id for obj_id in budgets["sizes"] if obj_id not in recipes]
    extra = [obj_id for obj_id in recipes if obj_id != "hub" and obj_id not in budgets["sizes"]]
    if missing or extra:
        raise RuntimeError(f"recipe/data mismatch: missing={missing} extra={extra}")

    grouped = {}
    for object_id in sorted(budgets["sizes"]):
        grouped.setdefault(budgets["tiers"][object_id], []).append(object_id)

    for tier, tier_file in sorted(TIER_FILES.items()):
        build_file(tier_file, sorted(grouped[tier]), recipes, budgets["sizes"], rects, budgets)
    build_file(HUB_FILE, ["hub"], recipes, {}, rects, budgets)


UV_MARGIN = 0.05

main()
