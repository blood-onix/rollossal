# Implementation Plan: Dress Park City with the City Asset Kit and Themes

**Branch**: `014-park-city-art` | **Date**: 2026-11-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/014-park-city-art/spec.md`

## Summary

Put art on the Park City grey box, in three playable stages and a closing verification stage. Park City today has no
mesh or theme data: the generator writes no `assetKey`, `role` or `atlas`, and the world has no `activeThemeId`, so
every object is a grey block. This feature adds one hand-edited dress table (`scripts/park_city_dress.py`) that the
world generator reads, so each of the 219 object kinds becomes an exact mesh, a close substitute or a recorded
stand-in, and a coverage report is generated from it. The same generator gives the world `activeThemeId = "winter"`,
`supportedThemes = { "winter", "city" }` and `themeBindings` (Plaza landmark, memes), and maps block swatches to `w-*`
roles so winter roads are dark and lawns and roofs are snow. `LightField` draws light objects through `ObjectVisual`
templates, keeping the 450 pool cap. A map-edge band is added in the layout script. A Park City triangle budget and
late-game clearance checks are added as Lune tests; the ceilings come from the 12-ball benchmark. No Blender mesh is
authored; the owner chooses from the coverage report's build list.

Read first: [research.md](research.md) (twelve decisions), [data-model.md](data-model.md), [quickstart.md](quickstart.md).
`contracts/` exists: [dress-and-coverage.md](contracts/dress-and-coverage.md) (dress table, coverage report, light visual).

## Technical Context

**Language/Version**: Luau (`--!strict`) on Roblox; Python 3 (standard library only) for the layout, world and dress
scripts; Lune for unit tests.

**Primary Dependencies**: none new (Constitution XII). Rojo 7.7.1, Lune, StyLua, Selene, luau-lsp as today.

**Storage**: none. No profile or DataStore change.

**Testing**: Lune unit tests in `tests/unit` (gate 1); Jest-Lua specs in `tests/studio` for the light visual; the Studio
MCP for the playtest, the 12-ball benchmark, the late-game drive and the console read.

**Target Platform**: Roblox, phone first. Frame rate is checked in agent Studio runs, judged on unthrottled seconds.

**Performance Goals**: server parts under 2,000 with 12 balls; every unthrottled benchmark second at 30 fps or more;
Park City triangle ceilings set from that benchmark.

**Constraints**: the 1,000 × 1,000 map (500 to 620 for the edge); the Part budget below; generated files are never
edited by hand; tier, dims, bulk and `needsD` stay the approved layout's numbers.

**Scale/Scope**: 219 object kinds (53 with an id match in `Assets.meshes`, 166 without), 4,614 placements (1,139 Parts,
3,475 light), 93 blocks, 12 spawns, an edge band of up to 120 Parts.

### Part budget (server, 12 balls)

| Item | Parts |
| --- | --- |
| Tier 3–6 objects (pooled) | 1,139 |
| Blocks | 93 |
| Placeholders (rails, drain pipes, pads, catapults, water) | about 110 |
| Boundary walls, hub | about 20 |
| Balls (12) | 12 |
| Runtime (boosters, traps, hazards, traffic) | about 100 |
| Map-edge scenery (new, R-10) | up to 120 |
| **Total** | **about 1,600**, under 2,000 (012 measured about 1,730 with its Stage B crumb Parts; those are light state now, so the margin is wider) |

Light objects are client Parts (up to 450 visible) and are not server Parts. Triangles are budgeted separately (R-07).

## Constitution Check

Constitution on disk is **4.1.0**.

| Principle / gate | Status |
| --- | --- |
| I Grey box first; pace; staging; gate 6 | Met. The grey box exists and was approved. Each stage ends in a playable build (stand-ins hold until a kind's stage). Pace is reported; the pace test fails only on its three floors. The finale gets a supply floor, not a time gate (R-09). Gate 6 applies in the final stage with shots in both themes. |
| II Server authority; light objects | Met. Nothing about who decides an absorb changes. The light visual is client drawing only; the click still sends an id string and the server judges. Edge scenery has no collision, query or object tag. |
| III Pure tested rules | Met. No new rule logic in `Rules`. The budget and clearance sums are test code over data. A pure module is added only if the benchmark script needs the same sum (R-07). |
| IV Safe | Met. Shop names are the 013 invented names (allowed). Meme objects are the 013 inanimate set. No people or animals added; the duck and flamingo are existing objects. |
| V, VIII Monetization, data | Not touched. |
| VI Mobile first | The budgets are checked against 30 fps in Studio; `Flags.LightMeshes` is the phone triage switch. Phone frame rate stays on the RC list. |
| VII Content is data; one layout file | Met. The map edge is a layout section, the SVGs are regenerated and approved first, and the world modules are generated. The dress table is a separate hand input, not generated output. A Lune test checks the world against the layout and the coverage report. Switching theme is the `ACTIVE_THEME` constant. |
| IX Localised strings | Met. `mega_tree` gets a generated English and Spanish name. Other names unchanged. |
| X Multi-agent | One agent drives Studio at a time; the claim goes on the Studio tasks in `tasks.md`. |
| XI Asset pipeline | Met. Only already-uploaded meshes and atlases are used; no new mesh and no new atlas. Stand-ins use palette roles. One atlas per theme plus the fronts atlas, as built. |
| XII Lean | One new Python module (`park_city_dress.py`, stdlib) because the mapping is a third input that changes at a different rate from layout and generator; one new client behaviour inside `LightField` (no new module). No new tool or package. |
| Gates 1–5 | Gate 1 by `scripts/check.sh`. Gate 2 by the final-stage playtest and console read. Gate 3 by "no new mesh, stand-ins recorded". Gate 4 by generated strings. Gate 5 by `tasks.md`. |
| Gate 6 | Final stage: fixed shots in `city` and `winter` and a played build, owner approval before merge. |

No violations. Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/014-park-city-art/
├── plan.md             # this file
├── research.md         # twelve decisions
├── data-model.md       # dress entry, theme binding, coverage record, budget record
├── quickstart.md       # how to validate each stage
├── contracts/
│   └── dress-and-coverage.md
├── tasks.md            # /speckit-tasks
├── coverage.md         # GENERATED by park_city_world.py
├── coverage.json       # GENERATED
├── playtest.md         # agent runs and the owner's gate 6 record
└── shots/              # fixed shots (PNG), final stage
```

### Source code

```text
scripts/
├── park_city_dress.py          # NEW: kind -> mesh/role/stage table, swatch map, slot bindings (stdlib)
├── park_city_world.py          # extended: reads the dress table; writes theme data, object visuals, coverage report
├── park_city_layout.py         # extended: `edge` section (stage 1) and any finale tuning (stage 3)
├── park_city_render.py         # extended: draws the edge band
└── check.sh                    # unchanged (already runs layout and world --check)

src/shared/
├── Config.luau                 # Flags.LightMeshes; Budgets.parkCityTriangles* (set in the final stage)
├── Content/Worlds/ParkCity.luau        # GENERATED: assetKey/role/atlas, theme fields
├── Content/Worlds/ParkCityParts.luau   # GENERATED: edge rows
├── Localization/ParkCityStrings.luau   # GENERATED: mega_tree name
└── ObjectVisual.luau           # unchanged unless the light templates need a cache hook

src/client/
└── LightField.luau             # extended: per-kind templates and pools via ObjectVisual

tests/unit/
├── ParkCityDress.test.luau     # NEW: every kind resolves; coverage report matches; winter contrast
├── ParkCityBudget.test.luau    # NEW: triangle sums; ceilings
├── ParkCityClearance.test.luau # NEW: late-game clearance; finale supply floor
├── ParkCity.test.luau          # extended: edge rows, theme fields
└── Config.test.luau            # extended: new keys (no existing pin changes)

tests/studio/
└── LightFieldMeshes.spec.luau  # NEW

docs/design/maps/               # regenerated: park-city-layout.json and SVGs (edge band)
specs/012-park-city-map/pace-report.md   # rewritten by the ParkPace test
```

**Structure Decision**: single Rojo project as today. One new script, three new Lune tests and one Jest spec. The
generated world modules are rewritten by the generator, never by hand. No new module under `src`.

## Stages

Each stage ends with a build the owner can play and with `scripts/check.sh` at exit 0. About 40 tasks in all;
`/speckit-tasks` splits them.

### Stage 1: park ring, map edge, theme wiring, coverage (about 14 tasks)

- Dress table for the kinds whose `stage` is 1 (park, hedge maze, Duck Island, woods, Giant Oak, the 12 spawn ring
  crumbs): first pass chosen from `ck_*`, `dt_*` and older meshes; all other kinds start as `standin` with a role.
- Generator: dress fields, `activeThemeId`, `supportedThemes`, `themeBindings`, swatch map, `mega_tree`, coverage
  report, validations, `--check`. `ParkCityDress.test`, including the winter contrast test.
- `LightField` through `ObjectVisual` (R-05), `Flags.LightMeshes`, `LightFieldMeshes` spec.
- Edge band in the layout script and `park_city_render.py`. The regenerated SVGs go to the owner before the world is
  regenerated from them.
- Owner sees: the park in winter and in `city` with meshes where they exist; dark roads, snow lawns; the edge reads as
  a place; every other area still grey but coloured by role. A coverage report with the build list.

### Stage 2: Ring Road and the four neighbourhoods (about 8 tasks)

- Dress entries for the stage 2 kinds (houses, shops, vehicles, street kit, suburb props, fronts-atlas shops).
- Fit check of the scale factors; the clearance test for the Ring Road and neighbourhood streets.
- Owner sees: the suburbs and Ring Road dressed, rolled through at mid-game size.

### Stage 3: Downtown core, Plaza, finale, big balls (about 10 tasks)

- Dress entries for the core: mid-rises, towers (`dt_glass_tower` and the Tier 6 set), signage, memes, Plaza landmark.
- `slot.meme.t3` to `t5` and `slot.landmark` placements in the generator.
- Finale supply floor and `ParkCityClearance` for the core; the Studio drive at D 35, 60 and 100.
- If the pace report shows the skilled profile cannot reach D 96, a layout change (more Tier 4–5 near the core, or
  `growthK`) with its SVG approval first.
- Owner sees: the whole city dressed; the Glass Tower edible on a strong run.

### Final: budgets, benchmark, shots, Gate 2, Gate 6 (about 8 tasks)

- `ParkCityBudget`: ceilings set from the benchmark (`ParkHeavyScene`, `ParkHeavySampler`); levers in R-07 if over.
- `ParkPace` rerun and the report rewritten; playability floors green.
- Fixed shots in both themes into `shots/`; Gate 2 playtest and console read.
- The pull request opens to show the shots; the owner's approval is recorded in `playtest.md` and holds the merge.
- Owner-only items go to `docs/release-candidate.md`: which stand-ins to build, phone frame rate, Spanish name of
  `mega_tree`, the city-theme roof colour, the tower floors vs the 60-stud cap and the street prop tier moves left open
  by 013.

## Spec deviations and defaults to confirm

| # | Item | Default |
| --- | --- | --- |
| D1 | The spec says ~370 ids and 16 kit overlaps. Park City has 219 kinds; 15 overlap `CityKit` (53 kinds in all match an uploaded mesh by id). | Report the measured numbers; the 16th overlap does not exist in the layout. |
| D2 | Tier 2 meme (`meme_wet_floor_sign`) is a light kind, so it cannot be a slot. | Tier 2 meme is a plain light kind; slots `slot.meme.t3` to `t5` on Parts. |
| D3 | Block swatches map to one role for both themes, so `roof` is `w-snowcap` (grey in `city`). | Accept; the owner sees it in the `city` shots. |
| D4 | `ThemeResolve` copies placements without `solid`. | Nothing in `src` reads the placement's `solid`; a test keeps it that way. |
| D5 | The spec says the Plaza landmark swaps by theme; the second duck at (250, −430) stays a duck. | Plaza only, via `slot.landmark`. |
| D6 | Kit tiers differ from layout tiers (a taxi is 3 and 4). | The layout wins; the mesh is scaled to the layout's longest side. |

## Flags

| Flag | Default | Effect |
| --- | --- | --- |
| `Flags.LightMeshes` | true | `LightField` draws meshes and stand-ins through `ObjectVisual`; off draws tier-coloured blocks as today. Removed after the RC if unused. |
| `Flags.ParkCity`, `ThemeSystem`, `HeapFix`, `DebugSize` | as today | unchanged. |

The theme switch is the `ACTIVE_THEME` constant in the dress script, not a runtime flag (FR-006).

## What must keep passing unchanged

With nothing else touched, these existing tests are not edited and must pass: `Absorb`, `Growth`, `Tiers`, `Stars`,
`Movement`, `Light`, `Pace`, `Layout`, `Downtown` (including its 550,000 and 290,000 ceilings, since Downtown stays
valid), `SnowVillage`, `CityKit`, `Themes`, `ThemeResolve`, `Strings`, `Atlas`, `ArtManifest`, `Config` (new keys are
added; the `meshTriangles` length stays 5), `ParkCity` (extended, existing assertions stay), `ParkPace` (floors stay,
pace stays a report), and the Jest specs `ThemeSwitch`, `ObjectTemplates`, `WorldSpawner`, `WorldSpawnerLight`,
`AbsorbServiceLight`, `WorldCuller`. A change to an existing function signature that would force a test edit is a
defect in the change.

## Hard gates

Gates 1 and 2 on every stage that changes code or content (gate 2's Studio playtest and console read must run before
the pull request opens). Gate 6 at the end. Playability floors fail the build; pace never does. No new console
errors or warnings. `park_city_layout.py --check` and `park_city_world.py --check` exit 0 with no overlaps.

## Open points for the first tasks of a stage (not blockers)

- Stage 1: whether `ObjectVisual.build` can be called for about 125 light kinds at load without a visible hitch
  (`CreateMeshPartAsync` yields); if so, preload by distance to the spawn.
- Stage 1: which of the 15 plain-key meshes (e.g. `cottage`, `lantern`) fit the layout dims; "fit unchecked" until
  the native dims are known.
- Stage 3: whether `edge` triangles push the culled total past the measured ceiling; the lever is fewer skyline meshes.
- Stage 3: the clearance numbers in R-08 (0.25 × D, 1.25 × width) are starting values; the Studio drive may move them.

## Post-design re-check

Re-read against the constitution after `research.md`, `data-model.md` and the contract: no new violation. The dress
module is justified under XII (a third input with its own rate of change). The one fact worth watching is the
triangle estimate in `research.md` (about 1.9 M if every placement used a mean mesh), far above Downtown's retired
ceiling; R-07 makes the benchmark, not the spec, decide the number, and gives the levers in order.
