# Quickstart: prove the theme system and the art pipeline

Run from the repo root. Nothing here touches the desktop outside the Studio MCP tools (`AGENTS.md`). Contracts:
[theme-content](contracts/theme-content.md), [art-pipeline](contracts/art-pipeline.md). Entities:
[data-model](data-model.md).

## 0. Prerequisites

- `scripts/studio-preflight.sh` has run (Rojo on `localhost:34872`); for Studio steps, `list_roblox_studios`
  then the Luau from `scripts/studio-sync-probe.sh` returns `mismatches = {}`.
- Rokit tools installed (`rokit install`), `wally install` done (as for 004).
- Blender steps: the Blender MCP addon is connected (`get_addon_status`). The Blender claim is written on the
  task line in `tasks.md`; the Studio claim likewise.
- Python 3 on `PATH` (already needed for `scripts/design-tokens.py`).

## 1. Everything that needs no Roblox and no Blender (fast loop)

```sh
python3 scripts/design-tokens.py            # tokens.css / tokens.md / the Themes.luau palette block
python3 art/scripts/palette.py              # six atlases, atlas.json, palette.json, palette.png
python3 art/scripts/palette.py --check      # expect: exit 0
lune run scripts/art-sync                   # budgets.json for { 500, 700, 1500, 3500, 5000 }
scripts/check.sh                            # expect: "All checks passed"
```

Expected observations:

- Running `palette.py` twice leaves `git status` clean (same pixel hashes).
- `art/atlases/` holds `city winter spring autumn toon neon` `.png` plus `atlas.json`; each PNG is
  1,024 × 1,024; `art/palette.json` lists 64 cells and 8 strips.
- Open `art/atlases/winter.png`: top half is an 8 × 8 grid of cells that are lighter at the top and darker at
  the bottom; bottom half is eight horizontal patterns, no letters anywhere.
- Edit one hex in `tokens.json` without regenerating: `check.sh` fails at "Design tokens in sync"; edit a PNG
  by hand: it fails at "Atlas determinism". Revert both.

## 2. Data-only theme switch (Lune)

```sh
lune run tests/unit/run                      # all suites
```

Look for these suites in the output and expect zero failures: `Themes`, `ThemeResolve`, `Atlas`, `Book`,
`SnowVillage`, `Config`, `ArtManifest`, `Strings`.

Manual proof of "no code change": in `src/shared/Content/Worlds/SnowVillage.luau` change
`activeThemeId = "winter"` to `"city"` and nothing else, then `lune run tests/unit/run`. Expect the suites to
still pass (tests resolve every supported theme, not only the active one). Revert after the Studio step.

## 3. Blender (Blender claim; sequential, one agent)

Through `execute_blender_code` (the Blender CLI is not on `PATH` here), run in this order:

1. `art/scripts/remap_uv_atlas.py` — expect `remap: 65 collections migrated`; run again — expect
   `remap: already migrated`.
2. `art/scripts/export_all.py` with `--out art/export` — expect `export: OK` and 65 meshes in the manifest.
   Negative check (do not commit): move one face's UVs across a cell edge in a scratch copy and re-run —
   expect `export: FAILED` naming the object and face; add a second material — expect failure; exceed a tier's
   budget — expect failure.
3. `art/scripts/qa_grid.py -- --object town_house --out art/qa` — look at `art/qa/theme_grid_town_house.png`:
   six renders, each clearly a different season, walls/roof/door still readable in all six.
4. `lune run tests/unit/run` — `ArtManifest` verifies byte sizes and sha256 of the new FBX files.

## 4. Studio proof (Studio claim, 🔒 tasks)

Sync probe passes first. Then, with `activeThemeId = "winter"`:

1. `start_stop_play`; `get_console_output` shows no new errors or warnings. Record: `Lighting.ClockTime`,
   `Atmosphere.Color`, the weather emitter exists and `Enabled`, the music `Sound` named `ThemeMusic` is
   playing, `workspace.World.Objects` contains the 32 slot placements with the winter object ids.
2. Stop. Change `activeThemeId` to `"city"` in data only, wait for Rojo to sync, re-run the probe, start Play
   again (a running playtest keeps old code). Record the same values: lighting changed, **no** emitter enabled
   (`kind = "none"`), no `ThemeMusic` sound (empty id), the slot placements are the five city stand-ins with
   `role` colours, the overlay stand-ins (`beach_towel`) exist, `big_snowman` placements use the fountain mesh,
   ground blocks use the `city` colours (`w-grass`, `w-kerb`, `w-sidewalk`). `get_console_output`: no new
   errors or warnings.
3. Weather and Reduce motion (set `winter` again): set `LocalPlayer` attribute `ReduceMotion = true` — emitter
   `Enabled` becomes false within one frame; set false — it returns. Sample `Rate × Lifetime.Max` from the
   emitter: ≤ 40.
4. Template rules (also covered by `tests/studio/ObjectTemplates.spec`): for each world object template,
   `RenderFidelity == Automatic`, `CollisionFidelity` is `Box` for tiers 1–3 and `Hull` for 4–5, no descendant
   `SurfaceAppearance`/`Light`, `Transparency == 0` for every visible world part.
5. Book: absorb one `winter_lights` object in a `winter` run (drive the ball as in `AGENTS.md`), open the Book:
   the Holiday page shows 1/1. Switch to `city`, Play again: the Holiday page is still listed, 1/1, with the
   returning sentence and no timer or "limited" wording; the five tier pages still reach 100 % without
   `city`-only objects.
6. 640 × 360 capture (clone the root frame as described in `AGENTS.md`): Book theme page and HUD, text ≥ 18 px,
   `TextFits` true. Record fps per second over a 60-second run with 12 balls' worth of parts; seconds at exactly
   15 fps are reported as "throttled" and excluded from the judgement; the unthrottled mean must be ≥ 30.
   Record the active part count (< 2,000).

Colour of **meshes** changes with the theme only after the owner hand-off in step 5; steps 1–6 above still
show the change on ground, stand-ins, lighting, weather and music, and say so in `playtest.md`.

## 5. Owner hand-off (after the above; ask first, outward-facing)

1. Upload `art/atlases/*.png` (six images) and the 65 FBX files in `art/export` (as in 004).
2. In one commit set `Assets.palettes.*`, `Assets.meshes.*`, `Assets.meshUv = "atlas"`, delete `Assets.palette`.
3. `REQUIRE_ASSET_IDS=1 lune run tests/unit/run` — expect pass; re-run step 4 and confirm meshes recolour
   between `winter` and `city`.
4. Remember: `LoadStringEnabled` must be off in anything published (`AGENTS.md`).

## Done when

`scripts/check.sh` exits 0 (including the two new steps); Studio steps 1–6 recorded in
`specs/005-theme-art-pipeline/playtest.md` with the date and commit; the PR description lists which Quality
Gates applied and how each was met (gates 1–5 all apply: server/client behaviour, UI, assets, strings).
