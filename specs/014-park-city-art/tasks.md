# Tasks: Dress Park City with the City Asset Kit and Themes

**Input**: Design documents from `specs/014-park-city-art/` (`spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/dress-and-coverage.md`, `quickstart.md`)  
**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/`  
**Constitution**: 4.1.0 (Principles I, II, III, IV, VI, VII, IX, X, XI, XII; Gates 1–6)  
**Tests**: Included as specified in `spec.md` and `plan.md` (Lune unit tests in `tests/unit/`, Jest spec in `tests/studio/`, and Studio MCP benchmarks/probes)  
**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`)
- **🔒**: Studio MCP check/task run by agent; adheres to AGENTS.md safety protocols and two-failure limit
- Every task includes exact file paths in its description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, feature flags, budget scaffolding, and dress script module structure.

- [X] T001 Configure feature flags and budget keys (`Flags.LightMeshes = true`, `Budgets.parkCityTrianglesUnculled = nil`, `Budgets.parkCityTrianglesCulled = nil`) in `src/shared/Config.luau` and verify assertions in `tests/unit/Config.test.luau`
- [X] T002 [P] Create feature directory structure for camera captures and test artifacts at `specs/014-park-city-art/shots/`
- [X] T003 [P] Scaffold Python dress table module `scripts/park_city_dress.py` exporting `CURRENT_STAGE`, `ACTIVE_THEME`, `DRESS`, `SWATCH_ROLE`, `SLOT_BINDINGS`, and `THEME_ONLY` per `specs/014-park-city-art/contracts/dress-and-coverage.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core dress table schema validation, swatch mapping, world generator extensions, and contract test infrastructure that MUST be in place before any user story can generate valid world data.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Implement dress entry validation and schema rules in `scripts/park_city_dress.py` enforcing: `status` exactly one of `exact`, `substitute`, `standin`; `assetKey` required for exact/substitute and present in `src/shared/Assets.luau` and `art/export/manifest.json`; `role` present in both `Themes.winter.palette` and `Themes.city.palette`; `substitute` requires non-empty `note`; scale factor within 0.6 to 1.6; and `atlas = "fronts"` only on meshes in `Assets.frontsAtlases`
- [X] T005 [P] Define complete layout block swatch to `w-*` role mapping dictionary (`SWATCH_ROLE`) in `scripts/park_city_dress.py` mapping all 27 layout block kinds (`road`/`track` to `w-asphalt`, `grass`/`woods`/`island` to `w-grass`, `pavement`/`plaza` to `w-sidewalk`, `roof` to `w-snowcap`, `building`/`tower` to `w-wall-a`, `glass` to `w-glass`, `kerb`/`stone`/`wall`/`bowl`/`box` to `w-kerb`, `gravel`/`sand` to `w-sand`, and ramps/decks/bridges to `w-wood`/`w-bark`/`w-concrete`)
- [X] T006 Extend `scripts/park_city_world.py` to import `scripts/park_city_dress.py`, emit object dress fields (`assetKey?`, `role`, `atlas?`, `shade?`, `fallback`), generate `activeThemeId = "winter"`, `supportedThemes = { "winter", "city" }`, and `themeBindings` (with `slot.landmark`, `slot.meme.t3` to `t5`, and theme-only `mega_tree` with English/Spanish strings), and generate `specs/014-park-city-art/coverage.json` and `specs/014-park-city-art/coverage.md`
- [X] T007 Update `scripts/park_city_world.py --check` validation mode to exit 1 when generated modules (`ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau`, `ParkCityStrings.luau`) or coverage reports (`coverage.json`, `coverage.md`) are stale
- [X] T008 [P] Implement Lune unit test `tests/unit/ParkCityDress.test.luau` verifying every kind in `ParkCity.objects` resolves to an uploaded mesh or valid `w-*` role, every placed kind has an object def, `coverage.json` totals match the world module, and winter contrast luminance(`w-grass`) - luminance(`w-asphalt`) >= 90 and luminance(`w-snowcap`) - luminance(`w-asphalt`) >= 90

**Checkpoint**: Foundation ready - dress table validation, generator bindings, and contract tests are active.

---

## Phase 3: User Story 1 - Coverage Mapping, Theme Wiring & Stage 1 Playable Park Zone (Priority: P1) 🎯 MVP

**Goal**: Dress the Park ring (including client-drawn light objects, server parts, and map edge boundary) using existing uploaded meshes and recorded stand-ins, configure active theme wiring (`winter` and `city`) with high winter contrast, and verify that all 12 starter spawns are stocked and unobstructed so the owner can play Stage 1.

**Independent Test**: Run `python3 scripts/park_city_world.py`, run `lune run tests/unit/run`, and start a playtest in Park City in both `city` and `winter` themes. Verify that every placed Park object resolves to a mesh with active theme atlas or recorded stand-in, all 12 spawns have stocked crumbs, the outer map boundary reads as a landscaped perimeter, and roads read dark against snow in winter.

### Tests for User Story 1

- [X] T009 [P] [US1] Create unit test assertions in `tests/unit/ParkCity.test.luau` verifying Park City theme fields (`activeThemeId`, `supportedThemes`, `themeBindings`), theme landmark slot resolution, and solid attribute omission in `ThemeResolve`
- [X] T010 [P] [US1] Create Studio Jest test `tests/studio/LightFieldMeshes.spec.luau` verifying client light slots render MeshParts for kinds with meshes with theme atlas `TextureID`, Parts with theme role colours for stand-ins, attributes (`Size`, `Bulk`, `Longest`, `Tier`, `ObjectId`, `Taken`), `LightObject` tag, zero scripts, and pool cap enforcement <= 450

### Implementation for User Story 1

- [X] T011 [US1] Populate Stage 1 dress table entries in `scripts/park_city_dress.py` with `CURRENT_STAGE = 1`: map Stage 1 park ring kinds (park, hedge maze, Duck Island, woods, Giant Oak, 12 spawn doorstep crumbs) to `exact` / `substitute` meshes from `ck_*`, `dt_*`, and seasonal meshes, setting all remaining kinds to `standin` with their `w-*` role and fallback shape
- [X] T012 [US1] Add `edge` scenery section to `scripts/park_city_layout.py` generating a landscaped boundary ring between 500 and 620 studs (ground apron to `outerHalfExtent = 620`, tree line, fence run, low-triangle building silhouettes; anchored, `CanCollide = false`, `CanQuery = false`, no `WorldObject` tag, budget <= 120 parts and <= 40,000 triangles)
- [X] T013 [P] [US1] Update `scripts/park_city_render.py` to draw the 500-620 stud edge scenery band on the rendered SVG maps in `docs/design/maps/`
- [X] T014 [US1] Run `python3 scripts/park_city_layout.py` and `python3 scripts/park_city_render.py` to regenerate `docs/design/maps/park-city-layout.json` and SVG maps, and verify with `python3 scripts/park_city_layout.py --check`
- [X] T015 [US1] Extend `scripts/park_city_world.py` to generate edge scenery Parts into `src/shared/Content/Worlds/ParkCityParts.luau` and generate `specs/014-park-city-art/coverage.json` and `specs/014-park-city-art/coverage.md` with Stage 1 build list
- [X] T016 [US1] Update client light pooling in `src/client/LightField.luau` to construct visual templates via `ObjectVisual.build` per light kind, manage per-kind free lists and active slots, support `Flags.LightMeshes`, and cap visible slots at `Config.lightPoolCap` (450)
- [X] T017 [US1] Execute Stage 1 verification with `scripts/check.sh`, verify all 12 spawns have 20 stocked doorstep crumbs and <= 1 stud obstacles within 15 studs, and test theme switching by setting `ACTIVE_THEME = "city"` and `"winter"` via `scripts/park_city_dress.py`

**Checkpoint**: Stage 1 complete and independently testable. The park zone is dressed and playable in both `winter` and `city`.

---

## Phase 4: User Story 2 - Stage 2 Playable Suburbs & Ring Road Dressed with the City Kit (Priority: P1)

**Goal**: Dress the Ring Road and four suburban/neighbourhood districts (Market Street & Roof Run, Car Park & Building Site, Terraces & Cottages, Station & Rail Yard) with modular `ck_*` and `dt_*` meshes and fronts atlases, maintaining clear routes and lane clearance.

**Independent Test**: Roll a ball through the Ring Road and all four neighbourhood districts at mid-game size (Tiers 3 to 5). Verify that suburban houses, shop rows, street kit items, and vehicles use mapped meshes with diverse variants along streets, with 0 route obstructions.

### Tests for User Story 2

- [X] T018 [P] [US2] Implement lane and street clearance unit test in `tests/unit/ParkCityClearance.test.luau` verifying no solid block taller than 0.25 * D sits in street gaps narrower than D for ball sizes 35, 60, and 100, Spoke and Ring Road widths are >= 1.25 * max ball diameter, and no Tier 4-6 kind is both solid and on a road block

### Implementation for User Story 2

- [X] T019 [US2] Populate Stage 2 dress table entries in `scripts/park_city_dress.py` with `CURRENT_STAGE = 2` for Ring Road and the four neighbourhoods (Market Street & Roof Run, Car Park & Building Site, Terraces & Cottages, Station & Rail Yard), mapping houses, corner shops, market stalls, cafe sets, street furniture, vehicles, and construction props to `ck_*` and `dt_*` meshes with `atlas = "fronts"` where required
- [X] T020 [US2] Validate mesh scale factor constraints (between 0.6 and 1.6) in `scripts/park_city_dress.py` for all Stage 2 kinds against native dimensions in `CityKit.luau` and Downtown object definitions
- [X] T021 [US2] Run `python3 scripts/park_city_world.py` to regenerate world files (`ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau`) and updated `specs/014-park-city-art/coverage.json` and `specs/014-park-city-art/coverage.md` for Stage 2
- [X] T022 [US2] Execute Stage 2 validation with `scripts/check.sh`, `tests/unit/ParkCityDress.test.luau`, and `tests/unit/ParkCityClearance.test.luau`, confirming 0 layout overlaps and unobstructed Ring Road and neighbourhood routes (Roof Run, Car Park ramps, Terrace lanes)

**Checkpoint**: Stage 2 complete and independently testable. The suburbs and Ring Road are dressed and playable.

---

## Phase 5: User Story 3 - Stage 3 Playable City Core, Big-Ball Destruction & Edible Finale (Priority: P1)

**Goal**: Dress Downtown core, Plaza, mid-rises, towers, signage, meme slots, and landmarks, ensuring big balls (D 35 to 100+) roll through streets with zero stuck moments and reach late-game size to eat the finale landmarks (Glass Tower at D >= 96).

**Independent Test**: Drive a ball at D 35, D 60, and D 100 through Downtown core and Spokes in Studio. Confirm mid-rises and towers render with theme and fronts atlases, 0 stuck incidents occur against static geometry, and a skilled run can reach D >= 96 to eat the Glass Tower.

### Tests for User Story 3

- [X] T023 [P] [US3] Implement finale supply floor calculation test in `tests/unit/ParkCityClearance.test.luau` verifying cumulative absorbable growth along valid routes exceeds D 100 with at least 15% spare capacity so the Glass Tower (`needsD = 95.9`) is reachable on a skilled run

### Implementation for User Story 3

- [X] T024 [US3] Populate Stage 3 dress table entries in `scripts/park_city_dress.py` with `CURRENT_STAGE = 3` for Downtown core and Plaza, mapping mid-rises, towers (`dt_glass_tower` and Tier 6 skyline set), billboards, meme placements (`slot.meme.t3` to `t5`), and Plaza landmark (`slot.landmark`) to their respective meshes and fronts atlases
- [X] T025 [US3] If the finale supply floor test in `tests/unit/ParkCityClearance.test.luau` requires layout adjustments to reach D 96+ within 210 s, update `scripts/park_city_layout.py` (Tier 4-5 food density or `growthK`), re-render SVGs via `scripts/park_city_render.py` for approval, and verify with `python3 scripts/park_city_layout.py --check`
- [X] T026 [US3] Run `python3 scripts/park_city_world.py` to regenerate world files and final `specs/014-park-city-art/coverage.json` and `specs/014-park-city-art/coverage.md`
- [X] T027 [US3] 🔒 Run Studio late-game big-ball traversal verification in Park City: set ball size to D 35, D 60, and D 100 with `Flags.DebugSize`, drive through Spokes, Plaza, and Ring Road with client velocity driver, and confirm 0 stuck incidents (speed < 2 studs/s for > 3 s) and successful Glass Tower absorption at D >= 96
- [X] T028 [US3] Execute `scripts/check.sh` and verify `tests/unit/ParkCityDress.test.luau` and `tests/unit/ParkCityClearance.test.luau` pass with 100% of kinds resolved

**Checkpoint**: Stage 3 complete and independently testable. The entire city is dressed, big balls roll smoothly, and the finale is edible.

---

## Phase 6: User Story 4 - Park City Triangle Budget & 12-Ball Performance Verification (Priority: P2)

**Goal**: Measure Park City's scene triangle cost from its actual server parts and client light window, establish and enforce its triangle ceiling in `Config.Budgets`, and verify 30+ fps on all unthrottled seconds in a 12-ball Studio benchmark.

**Independent Test**: Run `ParkCityBudget.test.luau` in Lune and the 12-ball benchmark in Studio. Verify active server parts remain below 2,000, all unthrottled seconds hold >= 30 fps, and budget ceilings enforce the benchmarked limits.

### Tests for User Story 4

- [X] T029 [P] [US4] Implement Park City triangle budget sum test in `tests/unit/ParkCityBudget.test.luau` computing triangles from `art/export/manifest.json` across all `ParkCityParts.luau` rows and `ParkCityLight.luau` draw window (nearest `lightPoolCap = 450` within `lightDrawRadius = 120` at fixed probes: 12 spawns, Plaza, Roof Run, Glass Tower) unculled and culled at Tier 5 (`cullTierDelta = 2`)

### Implementation for User Story 4

- [X] T030 [US4] Create 12-ball benchmark script `tests/studio/ParkHeavyScene.luau` and sampler `tests/studio/ParkHeavySampler.luau` to simulate 12 rolling balls in dressed Park City for 60 seconds while logging active server parts and per-second FPS
- [X] T031 [US4] 🔒 Run the 12-ball Studio benchmark in Park City via Studio MCP, record per-second FPS and part counts, confirm active server parts < 2,000, and verify at least 30 fps on 100% of unthrottled seconds (reporting any 15 fps background-throttled seconds separately)
- [ ] T032 [US4] Set `Budgets.parkCityTrianglesUnculled` and `Budgets.parkCityTrianglesCulled` in `src/shared/Config.luau` based on benchmark results (highest step holding 30 fps * 0.8, floored to 10,000) and verify `tests/unit/ParkCityBudget.test.luau` enforces the ceilings
- [X] T033 [US4] Rerun `tests/unit/ParkPace.test.luau` in Lune, verify all 3 playability floors pass (first pickup <= 3 s on all 12 spawns, no food ladder gap > 1.25x, park coverage <= 5% far from food), and rewrite `specs/012-park-city-map/pace-report.md`

**Checkpoint**: Performance and budgets measured and pinned.

---

## Phase 7: User Story 5 - Visual Gate (Gate 6) Shots & Owner Play Approval in `city` and `winter` (Priority: P2)

**Goal**: Capture fixed camera shots in both `city` and `winter` themes across all key views, verify zero console errors in Studio playtest, and present the shots and playable build for owner Gate 6 sign-off.

**Independent Test**: Inspect all generated shot PNGs in `specs/014-park-city-art/shots/` for both `city` and `winter`, verify Gate 2 console output is clean, and confirm owner sign-off recorded in `specs/014-park-city-art/playtest.md`.

### Implementation for User Story 5

- [ ] T034 [US5] 🔒 Capture fixed camera shots of Park City in Studio for both `"winter"` and `"city"` themes (11 pinned camera positions plus `roof_run`, `giant_oak`, `edge`, and `overview_high`) using `screen_capture` into `specs/014-park-city-art/shots/` (falling back to Blender render script `art/scripts/park_capture_render.py` if Studio captures fail twice)
- [X] T035 [US5] 🔒 Run Gate 2 Studio playtest and read console output using `get_console_output` to verify zero new warnings or errors in both `winter` and `city` themes
- [X] T036 [US5] Document benchmark measurements, traversal results, Gate 2 console output, and fixed shot links in `specs/014-park-city-art/playtest.md`
- [ ] T037 [US5] Record owner review and approval checkpoint for Gate 6 in `specs/014-park-city-art/playtest.md`, and add human-taste/tuning items to `docs/release-candidate.md` (missing mesh build list, phone FPS check, `mega_tree` Spanish name, city-theme roof color)

**Checkpoint**: Visual gate criteria satisfied with proof in both themes.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Format, lint, typecheck, documentation synchronization, and quickstart validation.

- [X] T038 Code cleanup, linting, and formatting with `scripts/check.sh` across all modified scripts and tests
- [X] T039 [P] Update documentation in `docs/design/maps/README.md` and feature summary reflecting Park City's dressed art status and active themes
- [ ] T040 Final validation against `specs/014-park-city-art/quickstart.md` scenarios ensuring full end-to-end consistency

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 completion - BLOCKS all user stories.
- **User Story 1 (Phase 3 - P1)**: Depends on Phase 2 completion. Delivers MVP (Dressed Park Ring, Theme Wiring, Map Edge, Light Objects).
- **User Story 2 (Phase 4 - P1)**: Depends on Phase 3 completion. Delivers dressed Suburbs & Ring Road.
- **User Story 3 (Phase 5 - P1)**: Depends on Phase 4 completion. Delivers dressed Downtown Core, big-ball clearance, and edible finale.
- **User Story 4 (Phase 6 - P2)**: Depends on Phase 5 completion. Delivers measured triangle budget ceilings and 12-ball benchmark.
- **User Story 5 (Phase 7 - P2)**: Depends on Phase 6 completion. Delivers Gate 6 fixed shots and owner sign-off.
- **Polish (Phase 8)**: Depends on all user stories being complete.

### User Story Dependencies

```text
[Phase 1: Setup] -> [Phase 2: Foundational]
                           |
                           v
              [Phase 3: User Story 1 (P1)] (Park Zone, Edge, Theme Wiring, Light Meshes)
                           |
                           v
              [Phase 4: User Story 2 (P1)] (Suburbs & Ring Road, Kit Dressing)
                           |
                           v
              [Phase 5: User Story 3 (P1)] (Downtown Core, Big Balls, Finale)
                           |
                           v
              [Phase 6: User Story 4 (P2)] (Triangle Budgets & 12-Ball Benchmark)
                           |
                           v
              [Phase 7: User Story 5 (P2)] (Gate 6 Shots & Owner Play Approval)
                           |
                           v
                 [Phase 8: Polish]
```

### Parallel Opportunities

- **Phase 1**: T002 and T003 can run in parallel.
- **Phase 2**: T005 and T008 can be authored in parallel with T004/T006.
- **Phase 3 (US1)**: T009 and T010 tests can run in parallel; T013 can run in parallel with T012.
- **Phase 4 (US2)**: T018 test can run in parallel with dress entries preparation.
- **Phase 5 (US3)**: T023 test can run in parallel with Stage 3 dress entries preparation.
- **Phase 6 (US4)**: T029 test can run in parallel with T030 benchmark harness creation.
- **Phase 8 (Polish)**: T039 documentation can run in parallel with T038 check scripts.

---

## Parallel Example: User Story 1

```bash
# Author tests and design assets in parallel:
Task T009: "Create unit test assertions in tests/unit/ParkCity.test.luau"
Task T010: "Create Studio Jest test tests/studio/LightFieldMeshes.spec.luau"
Task T013: "Update scripts/park_city_render.py to draw edge scenery band"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (flags, directories, dress module skeleton).
2. Complete Phase 2: Foundational (dress schema validation, swatch mapping, generator extensions, dress test).
3. Complete Phase 3: User Story 1 (park ring meshes, edge boundary, `LightField` visual pooling, theme wiring).
4. **STOP and VALIDATE**: Run `scripts/check.sh`, verify Park City in Studio in both `winter` and `city` themes, and verify 12 starter spawns are clear and stocked.

### Incremental Delivery

1. **Stage 1 (US1)**: Park zone dressed with existing meshes + map edge + theme wiring + light meshes. Playable build.
2. **Stage 2 (US2)**: Suburbs and Ring Road dressed with `ck_*` and `dt_*` kit + clearance tests. Playable build.
3. **Stage 3 (US3)**: City core dressed + mid-rises/towers/memes + big-ball traversal + edible finale. Playable build.
4. **Verification (US4 & US5)**: Triangle budget measured and pinned + 12-ball benchmark + Gate 6 shots in both themes + owner approval.
5. Each stage leaves the game fully functional and passing all automated test suites.

---

## Phase 9: Convergence

**Purpose**: Remaining work found by `/speckit-converge` round 1. Open tasks T032 (ceilings: owner decision) and T037 (owner approval) stay as they are and are not repeated here.

- [ ] T041 [US5] 🔒 Copy the 24 captured Studio shots (12 views per theme) from the agent session folder into `specs/014-park-city-art/shots/` as `<theme>-<view>.jpg`, using the command in `specs/014-park-city-art/playtest.md`; if the copy is refused again, re-capture them with `screen_capture` straight into the repo path or render them another way, and check the files are listed in `playtest.md` per FR-017, SC-006 (partial)
- [ ] T042 [US5] 🔒 Capture the missing Gate 6 views in both `winter` and `city` into `specs/014-park-city-art/shots/`: a ground-level `edge` shot (camera height about 3 studs, looking along the 500-620 band) and a whole-map overview (`overview` / `overview_high`, or a working substitute) that shows the full square, then update the shot list in `specs/014-park-city-art/playtest.md` per FR-009, FR-017 (partial)
- [ ] T043 Rerun quickstart scenarios 3 (light objects in Play) and 6 (late-game traversal) in Studio, then update the T040 validation table in `specs/014-park-city-art/playtest.md` so only owner-dependent rows (5 map approval, 8 owner approval and pull request) stay open per FR-016, SC-004 (partial)
