# Contract: Atlas generator and Blender pipeline

Extends `specs/004-snow-village/contracts/art-pipeline.md`; where they differ this one wins for new exports.
Constitution Principle XI v2.0.0.

## 1. Atlas geometry (1,024 × 1,024 px, PNG row 0 at the top)

| Region | Pixels (x, y from top-left) | Content |
| --- | --- | --- |
| Palette cells | cell `i` (0–63): `x0 = (i % 8) · 128`, `y0 = (i // 8) · 64`, size 128 × 64; `y < 512` | vertical gradient of one role (R-02) |
| Trim strips | strip `k` (0–7): `x0 = 0`, `y0 = 512 + k · 64`, size 1,024 × 64 | procedural pattern (R-03) |

Usable (inner) rect of every cell and strip: **inset 1 px on every side** (UV margin ≈ 0.00098). Bilinear
sampling at the inner edge therefore never reaches a neighbour.

UV convention (Blender, origin bottom-left): `u = x / 1024`, `v = 1 − y / 1024`.

Gradient: lightness factor at pixel row `r` of a cell (`r = 0` top … `63` bottom) is `1.12 − 0.27 · r / 63`
(R-02). A face's v inside the cell therefore picks its shade: high in the cell = lighter.

## 2. `art/scripts/palette.py` (stdlib Python)

```
python3 art/scripts/palette.py            # generate everything below
python3 art/scripts/palette.py --check    # no writes; exit 1 and print the first difference
```

Reads: `docs/design/tokens.json` (`color.themes`, `color.tokens`, `color.hero`). Writes:

| File | Content |
| --- | --- |
| `art/atlases/<themeId>.png` | 1,024 × 1,024, 8-bit RGB, for the six themes in `tokens.json` order |
| `art/atlases/atlas.json` | `{ "version": 2, "size": 1024, "themes": { "<id>": { "pixelSha256": "<hex>" } } }`, keys sorted |
| `art/palette.png` | byte copy of `art/atlases/winter.png` (the launch theme) |
| `art/palette.json` | layout map, §3 |

Exit codes: 0 ok; 1 `--check` mismatch or unreadable tokens; 2 invalid tokens (missing theme value, bad hex,
not exactly 32 `w-*` tokens, not exactly 32 `color.hero` entries, a `ref` to an unknown role).

`--check` regenerates the pixel buffers in memory and compares them to `atlas.json` **and** to the pixels
decoded from each committed PNG and from `art/palette.png`; it also compares `palette.json` byte for byte.

## 3. `art/palette.json` (schema v2)

```json
{
  "version": 2,
  "size": 1024,
  "inset": 1,
  "cells": {
    "w-asphalt": { "index": 0, "col": 0, "row": 0, "u": 0.0625, "v": 0.96875,
                   "u0": 0.000977, "v0": 0.938477, "u1": 0.124023, "v1": 0.999023 }
  },
  "strips": {
    "trim-grille": { "index": 0, "u": 0.5, "v": 0.46875, "u0": 0.000977, "v0": 0.438477, "u1": 0.999023, "v1": 0.498992 }
  }
}
```

- `u, v` are the rect centre; `u0, v0, u1, v1` the inner rect (inclusive), rounded to 6 decimals; keys sorted;
  `cells` has exactly 64 entries (names from data-model §4), `strips` exactly 8.
- The old format (`name → {u, v}`) is gone; nothing outside `export_all.py`, `build_objects.py` and
  `qa_render.py` reads it, and all three are updated in this feature. `build_objects.py` keeps its recipes but
  its UV placement helper reads this file; `remap_uv_atlas.py` is the path for existing sources.

## 4. `remap_uv_atlas.py` (Blender; run once through the Blender MCP; Blender claim)

For each `art/source/*.blend` and each collection: for every polygon, find the legacy cell containing its
loop UVs (legacy cell = column `c` of row 0 of the old 8 × 8 grid: `u ∈ [c/8, (c+1)/8]`,
`v ∈ [7/8, 1]`; `c` 0–5 = `snow, snow_light, stone, wood, brick, ice`), then replace each loop UV with the
affine image into the inner rect of cell `32 + c`:
`u' = u0 + (u − c/8)/(1/8) · (u1 − u0)`, `v' = v0 + (v − 7/8)/(1/8) · (v1 − v0)`.
A polygon whose UVs are not inside exactly one legacy cell aborts the script naming the object and face.
Idempotent: a second run finds UVs already in the new layout and leaves them (legacy UVs all have
`v ≥ 7/8`; cells 32–37 sit at `v ≤ 0.75`, so `v < 7/8` ⇒ already migrated) and prints `remap: already migrated`. The script saves each `.blend`.

## 5. `export_all.py` rules (replace rules 3 and 4 of the 004 contract)

1. Collection per object (unchanged), one material named `Palette` (unchanged), identity world matrix,
   origin at the footprint's bottom centre, longest side within ±5 % of `size`, no unapplied modifiers
   (the 1-segment silhouette **bevel**, 4–8 % of object size, must already be applied; unchanged check).
2. Shading: smooth-shaded polygons are **allowed**; custom normals are **allowed**. The FBX is exported with
   `mesh_smooth_type = "FACE"` (split normals preserved). The old "has smooth-shaded faces / custom normals"
   errors are removed.
3. UV: every polygon's loop UVs lie inside the **inner rect of one cell or one strip** from `art/palette.json`
   (inclusive, tolerance `1e-6`). The error names the object and face, e.g.
   `bench: face 12 UVs span outside every cell and strip`. A mesh with no UV layer fails.
4. Triangles after triangulation ≤ `budgets.meshTriangles[tier]` where the budgets are
   `{ 500, 700, 1500, 3500, 5000 }` (read from `art/scripts/budgets.json`).
5. `manifest.json` gains `"atlas": "art/atlases"` and `"palette": "palette.png"` stays; entries unchanged.
6. Exit non-zero with `export: FAILED` and the list of violations on any failure (unchanged mechanism).

## 6. `qa_grid.py` (Blender; Blender claim)

`blender --background --python art/scripts/qa_grid.py -- --object bench --out art/qa` (or `execute_blender_code`
with the same arguments) renders one object six times, each with a different theme atlas applied to its
`Palette` material, into a 3 × 2 sheet `art/qa/theme_grid_<object>.png`. Used for the cross-theme readability
check; one sheet (for an object with several colours, such as `town_house`) is committed as
`art/qa/theme_grid.png` (add it to the `.gitignore` exceptions next to `grid.png`).

## 7. Budget sync

`Config.Budgets.meshTriangles` is the source. After changing it:
`lune run scripts/art-sync` rewrites `art/scripts/budgets.json`; `ArtManifest.test` fails when it is stale
(unchanged mechanism). `scripts/art-budgets.luau` needs no logic change.

## 8. `scripts/check.sh` additions

Two steps, placed before "Lune unit tests":

```
== Design tokens in sync
python3 scripts/design-tokens.py --check
== Atlas determinism
python3 art/scripts/palette.py --check
```

Both fail the script (`set -e`). `scripts/design-tokens.py` gains `--check` (compare in memory, exit 1 on
difference) and the Luau-block writer.

## 9. README

`art/README.md` is updated: pinned tools unchanged, the build pipeline lists `palette.py` (stdlib) →
`remap_uv_atlas.py` (once) → `export_all.py` → `qa_render.py` / `qa_grid.py`, the atlas geometry table, the
rule "one cell or strip, inset 1 px", and the owner upload hand-off (R-07) as a checklist.
