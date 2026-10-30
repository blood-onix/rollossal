# Art pipeline (Snow Village)

Contract: `specs/005-theme-art-pipeline/contracts/art-pipeline.md` (extends
`specs/004-snow-village/contracts/art-pipeline.md`; where they differ the 005 one wins for new exports).

## Pinned tools

| Tool | Version | Status |
| --- | --- | --- |
| Blender | 5.2.3 LTS (binary `/Applications/Blender.app/Contents/MacOS/Blender`) | installed, MCP addon connected |
| `mcp-for-blender` (the Blender MCP server, started with `uvx`) | **2.2.4** (pinned in `.vscode/mcp.json` and `opencode.json` as `uvx mcp-for-blender==2.2.4`; latest PyPI release as of 2026-10-26, addon protocol 15 — the protocol the installed addon runs) | pinned |

Update the pin only together with the Blender addon (re-running `uvx mcp-for-blender` upgrades the addon on disk;
keep both at one release).

## Files

- `scripts/budgets.json`: triangle budgets, object sizes and tiers from `Config` and the Snow Village data.
  Regenerate with `lune run scripts/art-sync` after changing either; `tests/unit/ArtManifest.test.luau` fails
  when the committed file is stale.
- `art/palette.json`, `art/atlases/`, `art/palette.png`: written by `palette.py` (see below).

## Atlas geometry (1,024 × 1,024 px, PNG row 0 at the top)

| Region | Pixels (x, y from top-left) | Content |
| --- | --- | --- |
| Palette cells | cell `i` (0–63): `x0 = (i % 8) · 128`, `y0 = (i // 8) · 64`, size 128 × 64; `y < 512` | vertical gradient of one role (R-02) |
| Trim strips | strip `k` (0–7): `x0 = 0`, `y0 = 512 + k · 64`, size 1,024 × 64 | procedural pattern (R-03) |

Usable (inner) rect of every cell and strip: **inset 1 px on every side**. Blender's UV origin is
bottom-left, so `u = x / 1024` and `v = 1 − y / 1024`; `palette.json` holds each rect's inner bounds.

**Colour rule for every mesh: each polygon's UVs sit inside the inner rect of one palette cell or one
trim strip, and the mesh carries exactly one material (`Palette`).** `export_all.py` enforces it
(inclusive, tolerance 1e-6) and fails the export on any violation.

## Build pipeline

Everything below is headless Blender and reproducible; the committed `.blend` files are the source of truth
(art-pipeline.md R9), not the scripts — the scripts exist to author and rebuild them. Order:

1. `python3 art/scripts/palette.py` (stdlib only, no Blender): reads `docs/design/tokens.json`; writes the six
   theme atlases `art/atlases/<city|winter|spring|autumn|toon|neon>.png`, `art/atlases/atlas.json`
   (pixel sha256 per theme), `art/palette.json` (inner UV rects of the 64 cells + 8 strips) and
   `art/palette.png` (byte copy of the launch theme atlas). `--check` verifies all of it in memory;
   `scripts/check.sh` runs it.
2. `remap_uv_atlas.py` (Blender, **once per atlas schema change**): moves the meshes' UVs from the legacy
   256 px 8 × 8 grid into the inner rect of the matching new atlas cells (`snow … ice` → cells 32–37),
   keeping each face's relative position inside the cell. Idempotent — a second run prints
   `remap: already migrated`. Run through the Blender MCP (owner task).
3. `blender --background --python art/scripts/export_all.py -- --out art/export`: re-checks every
   modelling rule (collection per object named by id, single `Palette` material; smooth-shaded faces and
   custom split normals are allowed and the FBX is exported with `mesh_smooth_type = "FACE"` so they
   survive; no unapplied modifiers — the 1-segment silhouette bevel must be applied; identity world matrix;
   origin at the footprint's bottom centre; longest side ±5 % of `size`; UVs inside one cell or strip inner
   rect per `art/palette.json`; post-triangulation triangles ≤ the tier budget
   `500 / 700 / 1,500 / 3,500 / 5,000`), exports one FBX per collection and `art/export/manifest.json`
   (65 meshes, sorted by id, sha256 + byte size, `atlas: "art/atlases"`), and exits non-zero on any violation.
4. QA renders (Workbench, texture colours):
   - `blender --background --python art/scripts/qa_render.py -- --out art/qa`: every mesh as one cell
     in `art/qa/grid.png` for the proportion QA.
   - `blender --background --python art/scripts/qa_grid.py -- --object <objectId> --out art/qa`:
     one prop six times, each with a different theme's atlas, into `art/qa/theme_grid_<objectId>.png`
     for the cross-theme readability check. The reference sheet is committed; the per-theme frames are not.

Support scripts: `art/scripts/build_shared.py` (atlas geometry constants shared with `export_all.py`),
`art/scripts/tri_report.py` (mesh triangle/histogram report while tweaking recipes).

## After a change

Run: the export, `scripts/check.sh` (the ArtManifest tests hash the exported files against the manifest),
and the QA renders before committing `art/palette.png`, `art/palette.json`, `art/atlases/*`,
`art/source/*.blend`, `art/export/*.fbx`, `art/export/manifest.json` and the QA sheets.

## Owner hand-off (R-07; outward-facing, requires owner approval) — checklist

- [ ] Regenerate the atlases (`python3 art/scripts/palette.py`) and copy `art/atlases/*.png` to the owner.
- [ ] Run `remap_uv_atlas.py` on the committed `.blend` sources (once; verify the idempotent second run).
- [ ] Re-export (`export_all.py -- --out art/export`) and confirm `tests/unit/ArtManifest.test.luau` passes.
- [ ] Render the reference sheet (`qa_grid.py -- --object town_house`) and confirm every theme reads.
- [ ] Upload the six atlas assets and the 65 re-UV'd FBX files.
- [ ] Fill `Assets.palettes` (all six ids) and `Assets.meshes`.
- [ ] Set `Assets.meshUv = "atlas"` and delete `Assets.palette` in the same commit;
      `ArtManifest.test` with `REQUIRE_ASSET_IDS=1` then demands all six atlas ids.
