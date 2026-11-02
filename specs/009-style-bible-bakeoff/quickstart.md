# Quickstart: validating the style bible, look gate and bake-off (009)

A validation guide: what to run and what to see. It contains no implementation code. Studio steps follow `AGENTS.md`
(nothing may take over the owner's screen; the agent uses the Studio MCP only, one agent at a time, claimed in
`tasks.md`). Blender is driven through the Blender MCP, never by running the binary from the shell.

## 0. Prerequisites

- Rokit toolchain (StyLua, Selene, luau-lsp, Lune, Rojo). `scripts/studio-preflight.sh` has started `rojo serve` on
  `localhost:34872`.
- Blender 5.2.3 LTS with the pinned `mcp-for-blender` 2.2.4 connected (`get_addon_status`). Note which generators are
  on; if all are off, Source 3 is "not run".
- For 🔒 steps: Studio open on the dev place with the Rojo plugin connected; `scripts/studio-sync-probe.sh` through
  `execute_luau` gives `mismatches = {}`. If not, ask once and re-probe every 30 to 60 s for up to 20 minutes.
- Constitution status: read `.specify/memory/constitution.md`. If the visual gate, the invented-name signage rule and
  the CC0 rule are absent, step 0 of the plan is open. Work that needs them (signage, a CC0 import into the game, the
  gate as binding) waits; everything else proceeds.

## 1. Pure checks

Run `scripts/check.sh`. Expect exit 0 and:

- `CaptureCameras`: five shots in order, FOV 70, theme valid, distance-by-diameter, pitch ≤ 80°.
- `Downtown`: "Downtown N10" uses the two named ceiling constants once the benchmark has set them.
- `Config`, `ArtManifest` (99 `dt_*`, hashes, tier budgets), `Layout`, `ThemeResolve`, `Pace`, `Strings` unchanged and
  green.
- Design-token and palette checks pass (`design-tokens.py --check`, `palette.py --check`). The `Rules` purity and
  `GreyBoxRoom` guards pass.
- `git status` shows nothing under `src/`, `art/export/` or `art/atlases/`.

## 2. Capture route (US1)

1. Run the Lune exporter for `city`; run it twice and confirm the two JSON files are identical.
2. Through the Blender MCP, render the five shots from `cameras.json`. Check each PNG: 1280×720, the camera matches
   the shot name (D2 low and close; D5 street level; D12 wider; D80 high pull-back; overhead shows the whole 880 stud
   city), buildings use atlas colours, trees and lamps are present, no object missing for lack of an FBX.
3. Write `capture-manifest.json` (source, Blender version, world commit, theme, parity notes). Commit the five PNGs.
4. Optional second run in `winter`.
5. 🔒 Supplementary: sync probe, then `screen_capture` for each shot with the same cameras; save as `studio_*.png`.
   Compare composition with the offline set and note differences under "parity" in `playtest.md`. If Rojo does not
   connect in the wait window, record one tooling failure and keep the offline set; this does not hold the feature.

## 3. Style bible (US2)

- `docs/design/08-style-bible.md` has the 12 sections, states that it overrides `06-art-style.md`, and links the
  concept image path.
- `docs/design/README.md` Contents list links it; the pictogram-only and `w-season`-on-every-top lines no longer
  contradict it (R-06). `tokens.md` is regenerated, not hand-edited.
- Read the bible once against the "before" set and list in the report where the current map misses it.
- The concept image: if absent, the bible says so, and the owner is asked once (RC list).

## 4. Bake-off (US3)

1. Build the neutral stage in Blender (floor, warm sun matching `city`, fixed cameras).
2. Source 1: upgraded in-house meshes for the five props, within the bible's floor and target.
3. Source 2: after owner approval of the CC0 download, import, re-UV to the atlas, record the licence.
4. Source 3: only after owner approval of credit use and only if a generator is on; otherwise "not run".
5. Source 4: Creator Store search with the Studio MCP; record scripts, triangle counts and terms; insert only to
   inspect, then delete.
6. Fill `bakeoff/README.md` per `contracts/bakeoff-report.md`; copy the sourcing rule into bible section 11.
7. Confirm `art/export/manifest.json` and `art/export/` did not change.

## 5. Gate 2: heavy-scene benchmark (US4) 🔒

Claim Studio in `tasks.md`. In `winter` (and `city` for the passing step), 12 balls:

1. Sync probe; `start_stop_play`; clone `tests/studio/HeavyScene.server.luau` into `ServerScriptService` during Play.
2. For steps 300k, 500k, 750k and 1M triangles: build the scene (parts < 2,000), run 60 s, log one fps sample per second
   with the client Heartbeat sampler. Label seconds at exactly 15 fps "throttled"; judge on the rest: ≥ 30 fps.
3. Record parts, `PrimitivesCount`, `InstanceCount`, the culled-set size and, optionally, a MicroProfiler GPU/CPU split.
4. Derive the ceiling per `contracts/ceiling-and-tests.md`; rewrite N10 and `03-city-level.md` lines 65 to 66.
5. One playtest and a console read of the whole session: no new warnings or errors (ignore Studio's own
   `ContentId … failed` lines after grepping the repo for the id).
6. If every second is throttled, count one failure, ask the owner once to keep Studio in front, rerun.
7. Run `scripts/check.sh` again: exit 0.

## 6. Owner items (not blockers)

Moved to `docs/release-candidate.md`: owner approval of the constitution amendment (PR), approval to download the CC0
pack and to spend credits on `generate_3d`, the concept image, an early phone-fps reading, taste review of the "before"
set and the bake-off, and confirmation of D1 to D9.

## 7. `playtest.md` template

Sections: Capture route (offline vs Studio, parity notes, tooling failures), Benchmark (table per step: culled set,
parts, 60 samples, throttled seconds, lowest, average, verdict), Ceiling (steps, margin, constants), Console read,
Deviations (D1 to D9, fallbacks used).

## Done when

- The amendment is merged, or the plan's open-gate list names what is waiting.
- Five "before" PNGs and a manifest are committed.
- `08-style-bible.md` is linked and the conflicting lines are fixed.
- `bakeoff/README.md` covers the five props on the sources that ran, with licences and a sourcing rule.
- `playtest.md` holds a measured ceiling, N10 and `03-city-level.md` use it, and `scripts/check.sh` exits 0.
