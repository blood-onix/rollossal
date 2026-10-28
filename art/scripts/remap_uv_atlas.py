# Moves every mesh's UVs from the legacy 256 px 8 x 8 grid to the new 1024 px atlas, in place.
# Contract specs/005-theme-art-pipeline/contracts/art-pipeline.md §4. A one-off, run once after
# palette.py generates the atlases:
#   blender --background --python art/scripts/remap_uv_atlas.py
# Legacy cell = column c of row 0 of the old grid: u in [c/8, (c+1)/8], v in [7/8, 1], with columns
# 0..5 named snow, snow_light, stone, wood, brick, ice (build_shared.LEGACY_SWATCHES). Each loop UV is
# replaced with the affine image into the inner rect of the atlas cell LEGACY_TO_INDEX[c] (cells
# 32..37). A polygon whose UVs are inside exactly one of the six target inner rects is already
# migrated and left alone, so a second run touches nothing and prints "remap: already migrated".
# Anything else aborts naming the .blend, object and face. Each changed .blend is saved in place.

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_shared as shared
import bpy


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def target_rects(palette) -> dict:
    """New inner rects keyed by swatch name, from art/palette.json schema v2."""
    if "cells" not in palette:
        raise RuntimeError("palette.json is schema v1 (run python3 art/scripts/palette.py)")
    return {
        name: (palette["cells"][name]["u0"], palette["cells"][name]["v0"],
               palette["cells"][name]["u1"], palette["cells"][name]["v1"])
        for name in shared.LEGACY_SWATCHES
    }


def inside(u, v, rect, tolerance) -> bool:
    u0, v0, u1, v1 = rect
    return u0 - tolerance <= u <= u1 + tolerance and v0 - tolerance <= v <= v1 + tolerance


def legacy_column(u, v, tolerance) -> int | None:
    """Which legacy column a UV sits in, or None when it is outside row 0 (v < 7/8)."""
    if v + tolerance < shared.LEGACY_ROW_V:
        return None
    for index in range(len(shared.LEGACY_SWATCHES)):
        if index / shared.CELLS_ACROSS - tolerance <= u <= (
            index + 1
        ) / shared.CELLS_ACROSS + tolerance:
            return index
    return None


def remap_mesh(obj, targets, tolerance) -> int:
    """Remap every loop UV of one object; returns the number of remapped polygons."""
    layer = obj.data.uv_layers.active
    if layer is None:
        raise RuntimeError(f"{obj.name}: no UV layer")
    moved = 0
    for polygon in obj.data.polygons:
        uvs = [layer.data[loop].uv for loop in polygon.loop_indices]
        inside_any_target = any(
            all(inside(uv.x, uv.y, targets[name], tolerance) for uv in uvs)
            for name in shared.LEGACY_SWATCHES
        )
        if inside_any_target:
            continue
        columns = [legacy_column(uv.x, uv.y, tolerance) for uv in uvs]
        if len(set(columns)) == 1 and columns[0] is not None:
            column = columns[0]
            name = shared.LEGACY_SWATCHES[column]
            u0, v0, u1, v1 = targets[name]
            lu0 = column / shared.CELLS_ACROSS
            for loop, uv in zip(polygon.loop_indices, uvs):
                new_u = u0 + (uv.x - lu0) * shared.CELLS_ACROSS * (u1 - u0)
                new_v = v0 + (uv.y - shared.LEGACY_ROW_V) * shared.CELLS_ACROSS * (v1 - v0)
                layer.data[loop].uv = (new_u, new_v)
            moved += 1
        else:
            raise RuntimeError(
                f"{obj.name}: face {polygon.index} UVs "
                f"({[(round(uv.x, 4), round(uv.y, 4)) for uv in uvs]}) are not inside exactly one "
                "legacy cell or one target cell"
            )
    return moved


def run() -> None:
    art = art_dir()
    source_dir = os.path.join(art, "source")
    palette = json.load(open(os.path.join(art, "palette.json"), encoding="utf-8"))
    targets = target_rects(palette)
    tolerance = shared.UV_TOLERANCE

    files = sorted(name for name in os.listdir(source_dir) if name.endswith(".blend"))
    if not files:
        raise RuntimeError(f"no .blend files in {source_dir}")
    moved_total = 0
    already_count = 0
    for name in files:
        filepath = os.path.join(source_dir, name)
        bpy.ops.wm.open_mainfile(filepath=filepath)
        acted = 0
        for obj in bpy.data.objects:
            if obj.type == "MESH":
                acted += remap_mesh(obj, targets, tolerance)
        if acted:
            bpy.ops.wm.save_mainfile(filepath=filepath)
            print(f"remap: {name} moved {acted} polygons")
            moved_total += acted
        else:
            print(f"remap: {name} already migrated")
            already_count += 1
    if moved_total == 0:
        print("remap: already migrated")
    else:
        changed = len(files) - already_count
        print(f"remap: done ({moved_total} polygons across {changed}/{len(files)} files)")


try:
    run()
    print("remap: OK")
except Exception as exc:  # Blender swallows python failures with exit code 0; make the failure real.
    print(f"remap: FAILED\n{exc}")
    sys.exit(1)
