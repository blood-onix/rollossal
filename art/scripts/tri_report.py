# Developer aid: prints the post-triangulation triangle count of every collection in art/source/*.blend
# against its per-tier budget, without exporting anything. Educational only — the gate lives in
# export_all.py and ArtManifest.test.luau. Run: blender --background --python art/scripts/tri_report.py

import json
import math
import os
import sys

import bmesh
import bpy
from build_shared import EPS


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def count_tris(obj) -> int:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    tris = len(bm.faces)
    bm.free()
    return tris


def bbox(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))


def run() -> None:
    art = art_dir()
    budgets = json.load(open(os.path.join(art, "scripts", "budgets.json"), encoding="utf-8"))
    source_dir = os.path.join(art, "source")
    files = sorted(n for n in os.listdir(source_dir) if n.endswith(".blend"))
    if not files:
        print("tri_report: no .blend files in art/source")
        return
    total = 0
    for name in files:
        bpy.ops.wm.open_mainfile(filepath=os.path.join(source_dir, name))
        for coll in sorted(bpy.data.collections, key=lambda c: c.name):
            tris = sum(count_tris(o) for o in coll.objects if o.type == "MESH")
            total += tris
            tier = budgets["tiers"].get(coll.name)
            limit = budgets["meshTriangles"][tier - 1] if tier else 10 ** 9
            size = budgets["sizes"].get(coll.name)
            longest = ""
            if size:
                x0, x1, y0, y1, z0, z1 = bbox(
                    next(o for o in coll.objects if o.type == "MESH"))
                span = max(x1 - x0, y1 - y0, z1 - z0)
                longest = f"  longest {span:8.3f} (target {size})"
            mark = "OK " if tris <= limit else "OVER"
            print(f"tri_report {mark} {coll.name:20s}: {tris:4d} / {limit}{longest}")
    print(f"tri_report total triangles across {len(files)} files: {total}")


try:
    run()
    print("tri_report: OK")
except Exception as exc:
    print(f"tri_report: FAILED\n{exc}")
    sys.exit(1)
