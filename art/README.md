# Art pipeline (Snow Village)

Contract: `specs/004-snow-village/contracts/art-pipeline.md`.

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

## Build pipeline

Everything below is headless Blender and reproducible; the committed `.blend` files are the source of truth
(art-pipeline.md R9), not the scripts — the scripts exist to author and rebuild them:

1. `python art/scripts/palette.py` (any Python 3): writes `art/palette.png` (256x256, 8x8 grid, row 0 holds
   the six swatches snow/snow_light/stone/wood/brick/ice duplicated from `SnowVillage.environment.palette`)
   and `art/palette.json` with each swatch's u,v centre.
2. `blender --background --python art/scripts/build_objects.py`: models all 65 collections (64 objects plus
   the hub) as recipes of bmesh primitives, normalizes each mesh (longest bounding side `ObjectDef.size`
   ±5%, hub keeps its authored scale), puts the origin at the bottom centre of the footprint, planar-shrinks
   every face's UVs into one swatch cell with a 5% margin, and writes `art/source/<tier>.blend` (plus
   `hub.blend`). It self-checks budget and recipe/data coverage.
3. `blender --background --python art/scripts/export_all.py -- --out art/export`: re-checks every
   modelling rule (collection names, single `Palette` material, flat shading/no custom normals/unapplied
   modifiers/stale scale-rot, UVs inside one swatch, size, origin, triangle budget), exports one FBX per
   collection and `art/export/manifest.json` (65 meshes, sorted by id, with sha256 and byte size). Exits
   non-zero on any violation.
4. `blender --background --python art/scripts/qa_render.py -- --out art/qa`: renders every mesh as one cell
   in `art/qa/grid.png` (Workbench, palette colours) for the proportion QA; the sheet is committed, the
   per-object frames are not.

Support scripts: `scripts/build_shared.py` (CELLS/EPS constants shared with `export_all.py`),
`scripts/tri_report.py` (mesh triangle/histogram report while tweaking recipes).

After a change: run the export, `scripts/check.sh` (the ArtManifest tests hash the exported files against
the manifest), and the QA render before committing `art/palette.png`, `art/palette.json`, `art/source/*.blend`,
`art/export/*.fbx`, `art/export/manifest.json` and `art/qa/grid.png`. The studio import hand-off (uploading
the FBX files and filling `Assets.meshes`) stays owner work and is done with the date-stamped export set.
