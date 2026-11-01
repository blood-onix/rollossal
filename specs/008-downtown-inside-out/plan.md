# Implementation Plan: Downtown "Inside Out" Map Redesign (Concept A)

**Branch**: `008-downtown-inside-out` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-downtown-inside-out/spec.md`

## Summary

Replace the placeholder Downtown layout with Concept A, "Inside Out": an 880 × 880 stud playable city
(`halfExtent` 440, `outerHalfExtent` 560, hub at x = -620) in five rings that grow outward from a compact Old
Quarter. The same 74 core objects, 99 `dt_*` meshes, two themes (`winter`, `city`) and the 007 theme system are kept.
`Absorb.luau`, the meshes and the palette tokens do not change. Five strands, in dependency order:

1. **Envelope, camera and tests that pin the old numbers (Luau, Lune-tested)**. `Downtown.halfExtent` 300 → 440,
   `outerHalfExtent` 400 → 560, `hub.center.x` -460 → -620. `Config.cameraMaxDistance` 80 → 320. `maxPlacements` and
   `Budgets.defaultMaxPlacements` 1,400 → 1,500 (R-02). The perimeter wall goes; four invisible boundary colliders at
   ±440 replace it through one new block kind, `Boundary`, built by `WorldBuilder` and validated as data (R-01).
2. **Test models that can tell an empty field from a city (F7, FR-011, FR-012)**. `Pace.test` becomes obstacle-aware:
   static blocks taller than the ball's clearance and unabsorbable placements (`size > 0.4·D`) add detours or
   skip targets (R-05). `Downtown.test` gets the sightline-against-blocks-and-buildings check, built coverage ≥ 20 %,
   ≥ 50 static blocks, no tall perimeter wall, the per-tier split, ring street widths and a triangle audit from
   `art/export/manifest.json` (R-08, R-09, R-10).
3. **Stage 1 vertical slice (US1)**. Ring 1 (Old Quarter) plus one 30-stud main street out through the bollard gate to
   the first Ring 2 block. 12 lane spawns with ≥ 40 Tier 1 objects within 10 studs each. Checked with overhead and
   street-level `screen_capture` in `winter` and `city`, plus the pure 12-eater first-minute test (R-04, R-06).
4. **Stage 2 ring rollout (US2)**. Ring 2 Terraces, Ring 3 Yards (Park, Market, Construction Site, Car Park, Rail
   Yard), Ring 4 Boulevard, Ring 5 Skyline and Harbour with the horizon. One Studio capture check per ring. Every
   small-only shortcut becomes 4.5 ± 0.1 wide with a roof at y 4.8 to 5.0 (F5, F6). Holiday-only blocks stay in
   `themeBindings.winter.blocks` (F2). `growthK` and the Tier 3 to 5 counts are tuned with the pace model until the
   windows in the spec hold (R-07).
5. **Performance and docs (US3)**. The 12-ball, 60 s run in `winter`, `< 2,000` parts and ≥ 30 fps on unthrottled
   seconds, goes in `playtest.md`. Single material, atlas UVs and Minimal-rating checks of the `dt_*` meshes in Play.
   `docs/design/03-city-level.md` is rewritten to Concept A. Owner-only checks move to `docs/release-candidate.md`.

No remote, no DataStore field, no new tool, no new palette token, no new mesh. One new block kind (`Boundary`) is the
only change to the content schema.

## Technical Context

**Language/Version**: Luau (`--!strict`, Roblox, Rojo 7.7.1, luau-lsp strict) for game code and tests.

**Primary Dependencies**: none new. Existing Rokit toolchain (StyLua, Selene, luau-lsp, Lune 0.10.x, Rojo), Jest-Lua in
`tests/studio`, Roblox Studio MCP. No Blender work (no new meshes).

**Storage**: none. No DataStore key, no `Profile` field, no `SCHEMA_VERSION` change.

**Testing**: Lune unit tests in `tests/unit` (`Downtown`, `Pace`, `Config` changed; `Layout`, `Markers`, `ThemeResolve`,
`ArtManifest` re-run); Jest-Lua specs in `tests/studio` (`WorldSpawner.spec`, `ThemeSwitch.spec`, `RunManager.spec`
re-checked for the new extent); agent-run Studio MCP checks and `screen_capture`.

**Target Platform**: Roblox, mobile first (30 fps on the mid-range reference phone), 12 players per server.

**Project Type**: Roblox game (single Rojo project).

**Performance Goals**: ≥ 30 fps on unthrottled seconds at 640 × 360 with 12 balls in `winter`; first pickup ≤ 5 s; D 5 at
10 to 50 s, D 12 at 70 to 110 s, D 30 at 120 to 180 s, D 80 by 210 s, D ≥ 150 by 240 s from every spawn.

**Constraints**: `src/shared/Rules` has no Roblox API, clock or random. Active server parts ≤ 1,850 and < 2,000 in both
themes (worst case 1,841, R-03). Palette tokens unchanged. Dressing slots ≤ 15 % of placements. No absorbable people
or animals. No new remote. Every string already exists in en and es (no new objects, so no new keys).

**Scale/Scope**: 1 world module redesigned (about 1,800 → about 3,000 lines of data); 1 new block kind; 4 source files
touched outside the world (`Config`, `GreyBoxRoom` types, `WorldBuilder`, `Worlds` unchanged); 3 test files reworked;
1,386 base placements (480 / 386 / 260 / 204 / 56), up to 110 `winter` overlays; at most 250 blocks; 12 spawns.

## Constitution Check

*GATE: passed before Phase 0; re-checked after Phase 1 (below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | Pass | Stage 1 is built and captured before Stage 2 starts (FR-013). The pace model decides feel numerically. Owner taste sign-off goes to `docs/release-candidate.md`, which Constitution v3.0.0 allows. Every pace number is data. |
| II Server authority | Pass | No new remote. Boundary colliders are server-built static parts. `BallGuard`, `Absorb` and ball physics are untouched. |
| III Pure, tested rules | Pass | No change under `src/shared/Rules`. All new checks are Lune tests that call the existing pure `Layout`, `Growth`, `ThemeResolve` and `Markers`. The `Rules` purity grep in `check.sh` is unchanged. |
| IV Safe for everyone | Pass | No people or animals. Shops and houses are buildings. The `fountain`, trees and vehicles are the existing 99 meshes. Pigeons stay decorative. |
| V Ethical monetization | Pass | Nothing sold, no cosmetic, no new string. |
| VI Mobile first | Pass, to be measured | Parts ≤ 1,850 by test; triangle audit from the manifest; frame rate checked at 640 × 360 with 12 balls on unthrottled seconds (US3); camera pull-back keeps the ball from filling the screen. Reference-phone fps is an RC item. |
| VII Content is data | Pass | Rings, spawns, zones, blocks, boundary colliders and both themes are tables in `Downtown.luau`. Switching theme stays one field. `Flags.Downtown` still gives the rollback to Snow Village. |
| VIII Player data | Pass | No profile change. |
| IX Strings | Pass | No new object, tier or page, so no new key. `Strings.test` re-runs. |
| X Multi-agent | Pass | Own branch. `Downtown.luau` is one file, so ring work is serial; tests, docs and Config changes are `[P]` (Delivery order). The Studio claim is written in `tasks.md` before any 🔒 task. |
| XI Asset pipeline | Pass | No new mesh or asset id. The triangle audit reads `art/export/manifest.json`. |
| XII Keep it lean | Pass | No new tool, package or remote. One new `BlockDef.kind` value; see Complexity Tracking. |

**Human Approval Required**: none new. Owner look-and-feel and pacing sign-off are RC items (Constitution v3.0.0,
Quality Gates), not blockers.

### Post-design re-check (after Phase 1)

Unchanged: all rows still pass. Points checked against the design: (a) the `Boundary` kind adds one branch to
`WorldBuilder.buildGeometry` and one `kind` value to the content type; Lune can assert it as data (R-01); (b) the
`winter` worst case is 1,496 placements + 250 blocks + 16 markers + 3 hub + 12 balls + 64 runtime = 1,841 ≤ 1,850,
and `Downtown.test` asserts the sum (R-03); (c) the per-tier counts in `data-model.md` sum to 1,386 and each tier is
inside its ±10 % band; (d) the pace levers (`growthK`, T3 to T5 counts) are data, so no rule file changes (R-07).

## Spec deviations and defaults to confirm

These resolve ambiguities in the spec text. None changes an owner decision. D1, D2 and D5 need a one-line spec edit
if accepted.

- **D1: the ±10 % per-tier split is asserted on the base layout, not on `winter` with overlays.** FR-005 names
  "1,376 base placements" and treats overlays as extra (up to 1,526). FR-012 says "resolved placements". The base
  layout (identical in both themes, because slots resolve into the same tier) is held to ±10 %; `winter` overlays
  are capped at 110 and the total is held to `maxPlacements` (R-02, R-03).
- **D2: `maxPlacements` and `defaultMaxPlacements` become 1,500, not 1,550.** 1,386 + 110 overlays = 1,496 is the
  worst case. 1,550 is allowed by FR-005 but 50 more placements would cost 50 blocks of budget.
- **D3: boundary colliders are four parts and count as blocks.** They are inside the 250-block ceiling (R-01, R-03).
- **D4: the 50 minimum for static blocks counts visible, non-ground, non-boundary blocks.** Otherwise the four
  colliders and the ground slabs would let an empty field pass.
- **D5: spawns are not on the 30-stud main streets.** They sit at the mouths of the 8-stud lanes so each spawn's
  10-stud cluster is not shared with its neighbours (R-04). 12 × 40 = 480 is the whole Tier 1 total (+2 % on 470),
  so the base is 1,386 and `winter` overlays carry no Tier 1.
- **D6: the Rail Yard, Car Park and Construction Site ramps keep the 2.0-stud step rule from 007.** Spec text says
  "≤ 2.0-stud steps/inclines"; the existing Car Park ramps rise 2 studs per step and the sphere-cast check passes.
- **D7: horizon towers and water beyond ±440 are static blocks, not placements.** They are not absorbable and not in
  the 1,376; their parts count against the 250-block ceiling (R-03).
- **D8: no direct spawn-to-landmark sightline.** FR-011 mentions "from spawns to landmarks". The lanes are enclosed by
  design, so the checked corridors are the four main streets and twelve lane corridors; the landmark is seen from the
  lane's main-street end (R-09).
- **Also changing, no owner decision involved**: `Downtown.test` lines 138 to 140, 733 and 926 and `Config.test`
  line 105 pin old values and are rewritten. `SnowVillage.test` stays unchanged (Snow Village keeps 300 / 400 / -460).
  Fog distances for Downtown are retuned for a 320-stud camera (R-11).

## Project Structure

### Documentation (this feature)

```text
specs/008-downtown-inside-out/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R-01 … R-15
├── data-model.md        # Phase 1: rings, tier split, block budget, spawns, shortcuts, boundary, themes
├── quickstart.md        # Phase 1: how to prove it end to end
├── contracts/
│   ├── rules-and-code.md   # Config, GreyBoxRoom types, WorldBuilder, Worlds, Markers bounds
│   ├── world-content.md    # Invariants (C1 … C18 revised, N1 … N10 new)
│   └── pace-and-tests.md   # Obstacle-aware pace and sightline models, triangle audit, test edits
├── checklists/requirements.md
├── playtest.md          # Agent-run results (created during implementation)
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
src/shared/
├── Config.luau                         # cameraMaxDistance 320; Budgets.defaultMaxPlacements 1500
├── Content/
│   ├── GreyBoxRoom.luau                # BlockDef.kind doc: "Boundary"
│   └── Worlds/
│       └── Downtown.luau               # REDESIGNED: envelope, five rings, boundary, growthK, themeBindings
└── Rules/                              # unchanged (Layout, Growth, Markers, ThemeResolve, Absorb)

src/server/
├── WorldBuilder.luau                   # buildGeometry: Boundary kind -> invisible collider
└── WorldSpawner.luau                   # unchanged (reads halfExtent, so the new range follows)

src/client/
└── CameraController.luau               # unchanged (reads Config.cameraMaxDistance)

tests/unit/
├── Downtown.test.luau                  # envelope pins, coverage, split, widths, sightline, triangles, budget
├── Pace.test.luau                      # obstacle-aware eater, new windows, D 150 mark, 12-eater first minute
├── Config.test.luau                    # defaultMaxPlacements 1500, cameraMax 320
└── ArtManifest.test.luau               # re-run; triangle audit lives in Downtown.test

tests/studio/
└── WorldSpawner.spec, ThemeSwitch.spec, RunManager.spec   # re-checked for halfExtent 440

docs/
├── design/03-city-level.md             # rewritten to Concept A
└── release-candidate.md                # owner items from FR-014
```

**Structure Decision**: extend the single Rojo project in place. The world stays one data module, because the repo's
content modules have no `require` (Lune and Rojo resolve modules differently, and `check.sh` forbids `require(script`
under `Rules`); a per-ring file split would need a loader that does not exist. Only two Roblox-side files change
(`Config.luau` value, `WorldBuilder.luau` branch). Nothing in `src/server` or `src/client` names a world, which the
`GreyBoxRoom` guard in `check.sh` keeps true.

## Delivery order and parallelism

Tasks are generated by `/speckit-tasks`; this is the dependency spine. `Downtown.luau` is one file, so rows that edit it
run in sequence. Rows 1 to 3 and 12 to 13 touch other files and are `[P]`-safe.

| # | Slice | Files | Needs |
| --- | --- | --- | --- |
| 1 | Config values | `Config.luau`, `Config.test` | – `[P]` |
| 2 | `Boundary` block kind | `GreyBoxRoom.luau` (doc), `WorldBuilder.luau` | – `[P]` with 1 |
| 3 | Obstacle-aware pace model, sightline-vs-blocks helper (F7) | `Pace.test`, `Downtown.test` helpers | – `[P]` with 1–2 |
| 4 | Envelope and shell: extent, hub, ground, boundary, wall removal, old pins | `Downtown.luau`, `Downtown.test` pins | 1, 2 |
| 5 | **Stage 1**: Ring 1 + one 30-stud street + first Ring 2 block, 12 lane spawns | `Downtown.luau` | 4 |
| 6 | Stage 1 proof: 12-eater first minute (Lune), overhead and street captures in both themes 🔒 | `playtest.md` | 3, 5; **Studio claim** |
| 7 | Ring 2 Terraces: streets, house rows, shortcuts (F5, F6), storm drain | `Downtown.luau` | 6 |
| 8 | Ring 3 Yards: Park, Market, Construction Site, Car Park, Rail Yard | `Downtown.luau` | 7 |
| 9 | Ring 4 Boulevard and Ring 5 Skyline, Harbour, horizon | `Downtown.luau` | 8 |
| 10 | Themes: `winter` blocks (F2), overlays ≤ 110, `city` slots, markers and golden spots on new geometry | `Downtown.luau` | 9 |
| 11 | Pace tuning: `growthK`, T3 to T5 counts to the spec windows | `Downtown.luau`, scratch pace run | 3, 10 |
| 12 | Regression suite: coverage, split, widths, shortcuts, triangle audit, part budget | `Downtown.test` | 3 `[P]` with 7–11, grows with them |
| 13 | Docs | `docs/design/03-city-level.md`, `docs/release-candidate.md` | 5 `[P]` |
| 14 | Studio proof per ring: captures, shortcut and ramp sphere casts 🔒 | `playtest.md` | 7–10; **Studio claim** |
| 15 | Gate 2: one playtest, console read, 12-ball 60 s perf run, `dt_*` mesh check in Play 🔒 | `playtest.md` | 11, 12, 14; **Studio claim** |

## Complexity Tracking

| Choice | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| `Boundary` block kind (invisible collider) | FR-001 removes the perimeter wall but balls must not roll off an open map. Lune can assert the colliders as data and the "no tall wall" test can exclude them by kind. | Deriving four walls inside `WorldBuilder` from `halfExtent` hides the rule from tests and adds 4 parts to Snow Village (R-01). A tall visible wall is what FR-001 removes. |
| Obstacle-aware pace model | F7: the greedy eater ignores walls, so a dense city passes the pace test while being unplayable. | Raising `growthK` until the blind model passes hides the problem the review found (R-05). |

The single-file world and the 1,500 placement cap are not listed: both follow existing patterns and add no abstraction.
