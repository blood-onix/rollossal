# 013 T025: raises the upgraded and replaced dt_* meshes (audit verdicts "upgrade" and "replace") to their class floor.
# Keys, sizes and origins are untouched: build_objects.build_file calls apply() on the recipe's bmesh before it rescales
# the mesh, so the longest side and the bottom-centre origin still come from the normal pipeline.
# Two steps, both on the recipe's own silhouette (the shapes stay; they gain finish):
#   1. one bevel segment on hard edges, width 1.5 % of the longest side (style bible section 11, Constitution XI);
#   2. window and panel reveals: the largest flat faces get an inset and a shallow recess, which adds 8 triangles a face,
#      until the floor is reached. Every new face keeps the swatch of the face it came from, so w-season share is unchanged.
# Floors and verdicts come from specs/013-city-asset-kit/audit/audit.json.

import json
import math
import os

import bmesh
from mathutils import Vector

BEVEL_FRACTION = 0.015
HARD_ANGLE = math.radians(35.0)
MIN_AREA = 4e-4
INSET = 0.14
RECESS = 0.35  # recess depth as a fraction of the inset width


# Meshes whose rebuild stops short of the audit floor because the winter city's Downtown N10 headroom runs out
# (research R-03: built highest-visibility first, the order stops when the ceilings are reached). Kiosk: 35 placements;
# at its 1,050 floor the sum was 580,302 unculled against 550,000. With every other mesh rebuilt the sum is 546,702, so
# 3,298 / 35 = 94 more triangles fit: the kiosk is built to at most 180 (the reveal step adds 8, so it lands at 180 to 187; 190 is the hard limit).
# Revisit when 009 raises a ceiling.
CAPPED = {"dt_kiosk": 180}


def audit_path(art_dir: str) -> str:
    return os.path.join(os.path.dirname(art_dir), "specs", "013-city-asset-kit", "audit", "audit.json")


def load_floors(art_dir: str) -> dict:
    with open(audit_path(art_dir), "r", encoding="utf-8") as handle:
        rows = json.load(handle)["meshes"]
    return {r["id"]: min(r["floor"], CAPPED.get(r["id"], r["floor"])) for r in rows if r["verdict"] != "keep"}


def tri_count(bm) -> int:
    return sum(max(1, len(f.verts) - 2) for f in bm.faces)


def _longest(bm) -> float:
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    zs = [v.co.z for v in bm.verts]
    return max(max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))


def apply(bm, tags, floor: int, cap: int):
    """Returns the new (face, swatch) list. `cap` is the triangle ceiling (60 % of the budget)."""
    layer = bm.faces.layers.string.get("swatch") or bm.faces.layers.string.new("swatch")
    for face, swatch in tags:
        if not face.is_valid:
            continue
        face[layer] = swatch.encode()
    bm.faces.ensure_lookup_table()
    longest = _longest(bm)

    # 1. silhouette bevel on the longest hard edges that fit under the floor (a trial copy sizes the edge count)
    hard = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0.0) > HARD_ANGLE]
    hard.sort(key=lambda e: -e.calc_length())
    base = tri_count(bm)
    bm.edges.index_update()
    room = max(floor - base, 12)
    width = longest * BEVEL_FRACTION
    keep_n = 0
    for n in range(len(hard), 0, -max(1, len(hard) // 12)):
        trial = bm.copy()
        trial.edges.ensure_lookup_table()
        edges = [trial.edges[e.index] for e in hard[:n]]
        bmesh.ops.bevel(trial, geom=edges, offset=width, segments=1, affect="EDGES", profile=0.5)
        grown = tri_count(trial) - base
        trial.free()
        if grown <= room:
            keep_n = n
            break
    if keep_n:
        result = bmesh.ops.bevel(bm, geom=hard[:keep_n], offset=width, segments=1, affect="EDGES", profile=0.5)
        for face in result["faces"]:
            if not face[layer]:
                source = next((n for e in face.edges for n in e.link_faces if n is not face and n[layer]), None)
                face[layer] = source[layer] if source else b"w-metal"
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    # 2. reveals, largest flat faces first, upright faces before roofs
    guard = 0
    rounds = 0
    while tri_count(bm) + 8 <= cap and tri_count(bm) < floor and guard < 4000:
        guard += 1
        candidates = [f for f in bm.faces if len(f.verts) >= 4 and not f.tag and f.calc_area() > MIN_AREA * longest ** 2]
        if not candidates:
            rounds += 1
            if rounds >= 4:
                break
            for f in bm.faces:
                f.tag = False
            continue
        candidates.sort(key=lambda f: (abs(f.normal.z) > 0.7, -f.calc_area()))
        face = candidates[0]
        swatch = face[layer]
        width = math.sqrt(face.calc_area()) * INSET
        normal = face.normal.copy()
        res = bmesh.ops.inset_individual(bm, faces=[face], thickness=width, depth=0.0, use_even_offset=True)
        # the original face is now the inner panel; res["faces"] are the new ring faces
        for f in res["faces"]:
            f[layer] = swatch
            f.tag = True
        face.tag = True
        for v in face.verts:
            v.co -= normal * width * RECESS
    bm.faces.ensure_lookup_table()
    return [(f, f[layer].decode() or "w-metal") for f in bm.faces]
