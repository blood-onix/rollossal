# Quickstart: validating Downtown "Inside Out" (008)

A validation guide: what to run and what to see. It contains no implementation code. Studio steps follow `AGENTS.md`
(nothing may take over the owner's screen; the agent uses the Studio MCP only, one agent at a time, claimed in
`tasks.md`).

## 0. Prerequisites

- Toolchain from `rokit` (StyLua, Selene, luau-lsp, Lune, Rojo). `scripts/studio-preflight.sh` has started
  `rojo serve` on `localhost:34872`.
- For 🔒 steps: Studio is open on the dev place with the Rojo plugin connected. Run `scripts/studio-sync-probe.sh`
  through `execute_luau`: `mismatches = {}`. If not, ask once and re-probe every 30 to 60 s for up to 20 minutes.
- `ServerScriptService.LoadStringEnabled` on in the dev place for Jest. Off in anything published.

## 1. Pure checks

Run `scripts/check.sh`. Expect exit 0 and, in the Lune section:

- `Downtown`: envelope pins (440 / 560 / −620), four `Boundary` blocks, coverage ≥ 20 % in both themes, ≥ 50 blocks, no
  tall perimeter wall, per-tier split 470 / 386 / 260 / 204 / 56 ± 10 %, street widths per ring, shortcuts 4.5 ± 0.1
  with a roof at 4.8 to 5.0, gates sealed to D 2 and open to D 5, F2 scoping, triangle ceilings, part budget ≤ 1,850 in
  `winter` and `city`, 12 spawns with ≥ 40 Tier 1 within 10 studs.
- `Pace`: all 12 spawns inside the windows in both themes (first pickup ≤ 5 s; D 5 10 to 50 s; D 12 70 to 110 s; D 30
  120 to 180 s; D 80 ≤ 210 s; D 150 ≤ 240 s) and `simulateTwelve` (all 12 first pickup ≤ 5 s, D 5 ≤ 60 s).
- `Config`: 1500 and 320. `SnowVillage`, `Markers`, `ThemeResolve`, `Layout`, `ArtManifest`, `Strings` unchanged and green.
- The `GreyBoxRoom` guard and the `Rules` purity guard pass.

## 2. Stage 1: vertical slice (US1) 🔒

Claim Studio in `tasks.md`. Then:

1. Sync probe, `start_stop_play`, console read: no warnings from `WorldBuilder`, `ObjectVisual` or `ThemeResolve`.
2. `winter`: `screen_capture` overhead of Ring 1 plus the south main street and the first two Ring 2 blocks; then a
   street-level capture from one spawn. Dark asphalt against light plinths and roofs reads as a city.
3. Switch `activeThemeId` to `"city"`, let Rojo sync, restart Play, repeat both captures. No garlands. Restore `"winter"`.
4. Count `Workspace.World` parts against 1,850 (Stage 1 is far below it). Drive the greedy eater from one spawn
   (AGENTS.md "Driving the ball"); first pickup ≤ 5 s.
5. Record the captures' observations and the 12-eater Lune result under "Stage 1" in `playtest.md`. Stage 2 starts
   only after this is written.

## 3. Stage 2: ring rollout (US2) 🔒

Per ring, in order (Terraces, Yards, Boulevard, Skyline and Harbour), one capture in `winter` and one in `city` from
overhead and street level, plus:

- **Shortcuts**: sphere cast from the mouth and from above: D 4.4 passes, D 5.0 is blocked. Four alleys and the drain.
- **Ramps**: Car Park, Construction Site and Rail Yard ramps climb at ≤ 2.0 rise per step and ≤ 20°; a D 6 sphere cast
  rolls up. Harbour lips let a ball out of the basin.
- **Edge**: a ball driven to `±440` stays inside; the sky and horizon towers stay visible.
- **Camera**: at D 20 and D 80 the camera is 80 and 320 studs back.

## 4. Gate 2: performance and meshes (US3) 🔒

Once per feature, after Stage 2. In `winter`, 12 balls, 640 × 360:

1. Start Play; run 12 bots from the 12 spawns for 60 s.
2. Sample frame rate each second. Label seconds at exactly 15 fps "throttled" and judge on the rest: ≥ 30 fps.
3. Record active parts (≤ 1,850, < 2,000) and the unculled and culled triangle sums.
4. `dt_*` mesh check in Play, in both themes: single material, atlas UVs (snow caps on `w-season` faces in `winter`,
   summer swatches in `city`), no moderation or console warnings; Minimal-rating compliance from the manifest.
5. Console read of the whole Play session: no new warnings or errors. Ignore Studio's own `ContentId … failed` lines
   after grepping the repo for the id.
6. Write the numbers into `specs/008-downtown-inside-out/playtest.md`.

## 5. Rollback check

`Config.Flags.Downtown = false`, sync, play: Snow Village loads and `scripts/check.sh` passes. Restore.

## 6. Owner items (not blockers)

Moved to `docs/release-candidate.md`: owner look-and-feel sign-off for the slice and the full map; human-played D 5, 12,
30, 80 timings across 12 spawns; saved phone-resolution capture files; reference-phone frame rate; confirmation of
spec deviations D1 to D8 and any relaxed pace mark. Remove the "numbers come from the placeholder map" note once Gate 2
is recorded.

## 7. `playtest.md` template

Sections: Stage 1 (captures, 12-eater result), Stage 2 per ring (captures, sphere casts), Pace table (12 spawns × marks
× themes), Gate 2 (fps per second, parts, triangles, meshes, console), Deviations (D1 to D8, fallbacks used).

## 8. Done when

`check.sh` exits 0; Jest green; Stage 1, Stage 2 and Gate 2 are in `playtest.md`; `docs/design/03-city-level.md` is
Concept A; every success criterion SC-001 to SC-005 has a recorded result.
