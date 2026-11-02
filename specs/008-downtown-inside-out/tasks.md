---
description: "Task list for feature 008-downtown-inside-out implementation"
---

# Tasks: Downtown "Inside Out" Map Redesign (Concept A)

**Input**: Design documents from `/specs/008-downtown-inside-out/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/rules-and-code.md`, `contracts/world-content.md`, `contracts/pace-and-tests.md`, `.specify/memory/constitution.md`

**Tests**: Tests are included per `plan.md` and Constitution Principle III (pure Lune tests in `tests/unit`, Jest-Lua in `tests/studio`, and Studio MCP checks).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Tasks marked 🔒 require the Studio MCP and must be claimed in `tasks.md` before execution and released when done.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Core constants and schema extension required before world building

- [X] T001 [P] Update Config values (`cameraMaxDistance = 320`, `Budgets.defaultMaxPlacements = 1500`) in `src/shared/Config.luau` and assert in `tests/unit/Config.test.luau`
- [X] T002 [P] Document `"Boundary"` block kind in `src/shared/Content/GreyBoxRoom.luau` and implement invisible collider branch (`Transparency = 1`, `CanCollide = true`, `CanQuery = false`, `CanTouch = false`, `CastShadow = false`, `Material = SmoothPlastic`, skipping palette lookup) in `src/server/WorldBuilder.luau`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core test models, envelope updates, and test harness changes that MUST be complete before user story content work begins

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 [P] Implement obstacle-aware greedy eater (walls: `bottom < D and top > max(2.5, 0.5*D)`; unabsorbable: `size > 0.4*D` with corner detour) and `simulateTwelve` concurrent starter model in `tests/unit/Pace.test.luau`
- [X] T004 [P] Implement sightline-against-blocks helper (rasterise sightline keep-outs; fail if block `top > 2.5` or Tier 4/5 placement intersects) and anti-empty-field test helpers in `tests/unit/Downtown.test.luau`
- [X] T005 Update `Downtown.luau` envelope constants (`halfExtent = 440`, `outerHalfExtent = 560`, `hub.center = { x = -620, z = 0 }`, `maxPlacements = 1500`, `fogStart = 500`, `fogEnd = 1600`), add 4 `Boundary` blocks at `±440` (thickness 8, height 200), remove perimeter wall `dt_wall_*`, and update pinned bounds in `tests/unit/Downtown.test.luau` (lines 139, 140, 733, 926)
- [X] T006 [P] Audit and update Jest-Lua specs for new extent and hub center in `tests/studio/WorldSpawner.spec.luau`, `tests/studio/ThemeSwitch.spec.luau`, and `tests/studio/RunManager.spec.luau`

**Checkpoint**: Foundation ready - envelope, builder, and obstacle-aware test harness in place.

---

## Phase 3: User Story 1 - First-60-Second Vertical Slice: Old Quarter to First Terraces Block (Priority: P1) 🎯 MVP

**Goal**: Build and verify a playable vertical slice: complete Ring 1 (Old Quarter) with 12 lane spawns (each with ≥ 40 Tier 1 objects within 10 studs), dark asphalt ground, light plinths, landmark square, bollard gates, and the south 30-stud main street leading out to the first Ring 2 (Terraces) block with an enclosed 4.5 shortcut.

**Independent Test**: Load vertical slice in Studio and run automated validation; verify 12 lane spawns reach Tier 2 (`D >= 5`) within 60 seconds with first pickup ≤ 5 seconds via `simulateTwelve` in `tests/unit/Pace.test.luau`; verify visual contrast and landmark sightlines via overhead and street-level captures in both `winter` and `city` recorded in `specs/008-downtown-inside-out/playtest.md`.

### Tests for User Story 1

- [X] T007 [P] [US1] Add 12-eater first-minute test (`simulateTwelve` first pickup ≤ 5 s, D 5 ≤ 60 s for all 12 spawns) in `tests/unit/Pace.test.luau`
- [X] T008 [P] [US1] Add Stage 1 vertical slice assertions (Ring 1 8-stud lanes, 30-stud main streets, 12 lane spawns with ≥ 40 T1 within 10 studs, plinth kerbs 1.0–1.5, bollard gates) in `tests/unit/Downtown.test.luau`

### Implementation for User Story 1

- [X] T009 [US1] Implement Ring 1 (Old Quarter) plaza (top 0.3), fountain pedestal, landmark slot (`fixedAt("dt_l_1", "slot.landmark", 0, 2.4, 0)`), fountain (`size 13`), 16 sub-block plinths (top 1.2, `w-sidewalk`), 4 shop-front strips, 8 lane end walls (top 6), and 4 bollard gates (8 `traffic_cone` size 2.0 at 3.75 pitch, gap 1.75) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T010 [US1] Implement 12 Old Quarter lane spawns at lane mouths with door zones (`dt_z_door_NN_a` with 32 core T1 + `dt_z_door_NN_b` with 8 `slot.small`) and 1.2 kerb blocks in `src/shared/Content/Worlds/Downtown.luau`
- [X] T011 [US1] Implement south 30-stud main street and first double-sided Ring 2 Terraces block with plinths (top 1.2) and absorbable shops/houses (`corner_bakery`, `corner_shop_row`, `townhouse`) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T012 [US1] Implement first enclosed small-only shortcut (gap 4.5 ± 0.1 studs, flanking walls top 5.2, roof bottom face at y 4.9) and keep-out (`kind = "shortcut"`) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T013 [US1] 🔒 Studio verification: Claim Studio MCP, run sync probe, inspect overhead and street-level screen captures in `winter` and `city`, verify 12-spawn first-pickup ≤ 5 s and part count, record observations under "Stage 1" in `specs/008-downtown-inside-out/playtest.md`, release Studio MCP claim

**Checkpoint**: Stage 1 vertical slice is independently testable, visually confirmed in both themes, and recorded in `playtest.md`. Stage 2 rollout can begin.

---

## Phase 4: User Story 2 - Full 5-Ring "Inside Out" Map Rollout & Late-Game City Eating (Priority: P1)

**Goal**: Complete all 5 rings across the 880 × 880 stud playable envelope: Ring 2 (Terraces), Ring 3 (Yards), Ring 4 (Boulevard), and Ring 5 (Skyline & Harbour with horizon); achieve target tier placement split `470 / 386 / 260 / 204 / 56 ± 10%` (`1,386` base placements); tune late-game pace so D ≥ 150 is reached by 240 s and all Tier 5 landmarks can be swallowed.

**Independent Test**: Automated spatial, sightline, street-width, gate flood-fill, shortcut gap/roof, and obstacle-aware pace tests across all 12 spawns in `tests/unit/Downtown.test.luau` and `tests/unit/Pace.test.luau`; ring-by-ring Studio screen captures and live sphere-cast verification recorded in `specs/008-downtown-inside-out/playtest.md`.

### Tests for User Story 2

- [X] T014 [P] [US2] Implement layout regression tests in `tests/unit/Downtown.test.luau`: built coverage ≥ 20% on 5-stud raster (N2), ≥ 50 static blocks (N3), no perimeter wall > 8 studs (N4), tier split ±10% of 470/386/260/204/56 (N6), street widths per ring (N7), gate flood-fill D 2 blocked / D 5 passes (N8), and uniform 4.5 ± 0.1 shortcuts with roof at 4.8–5.0 (N5)
- [X] T015 [P] [US2] Implement pace window tests (first pickup ≤ 5 s, D 5 at 10–50 s, D 12 at 62–110 s, D 30 at 105–180 s, D 80 ≤ 210 s, D 150 ≤ 240 s) across all 12 spawns in `winter` and `city` in `tests/unit/Pace.test.luau`

### Implementation for User Story 2

- [X] T016 [US2] Implement complete Ring 2 (Terraces) plinths (40 + 4 split, top 1.2), house rows (`townhouse` T5, `corner_shop_row` T5, `corner_bakery` T4), 4 alleys (gap 4.5 ± 0.1, roof bottom y 4.9), storm drain tunnel, and scatter zones (190 T2, 60 T3, 56 T4, 17 T5) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T017 [US2] Implement Ring 3 (Yards) district slabs (top 0.25–0.5 for Park, Market, Construction Site, Car Park, Rail Yard), separators, climbable ramps (≤ 2.0 rise per step, ≤ 20° incline), and scatter zones (70 T2, 150 T3, 64 T4, 4 T5) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T018 [US2] Implement Ring 4 (Boulevard) 60-stud orbital road (`m` 295..355, two 26-stud carriageways, 8-stud median top 0.8), 12 shelters, 4 billboards, and vehicle scatter (30 T2, 40 T3, 44 T4) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T019 [US2] Implement Ring 5 (Skyline, Harbour, Horizon) 8 podiums (top 1.2), 4 quay blocks (top 1.2), 2 shallow basin slabs (`w-water`, top -0.4), 8 ramped exit lips (Wedges), 8 static horizon towers (`m` 450..540), and placements (10 T3, 16 T4, 28 T5) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T020 [US2] Implement theme bindings (`themeBindings.winter.blocks` for 24 garlands bottom y ≥ 9 and Park slope/ramp, `winter.overlays` ≤ 110, `city` slots), 15 built markers + 5 golden spots on static blocks, 5 pigeon districts (≤ 8 each), and fog lighting in `src/shared/Content/Worlds/Downtown.luau`
- [X] T021 [US2] Tune `growthK` (2.2–3.0) and Tier 3–5 placement distribution in `src/shared/Content/Worlds/Downtown.luau` until all pace windows in `tests/unit/Pace.test.luau` pass
- [X] T022 [US2] 🔒 Studio verification: Claim Studio MCP, take overhead and street screen captures for Rings 2–5 in `winter` and `city`, run sphere casts for 4.5 shortcuts and climbing ramps (Car Park, Construction, Rail Yard, Harbour lips), verify camera zoom at D 20 and D 80 (80 and 320 studs), record under "Stage 2" in `specs/008-downtown-inside-out/playtest.md`, release Studio MCP claim

**Checkpoint**: Full 5-ring map complete, pace tuned, shortcuts and ramps verified in Studio.

---

## Phase 5: User Story 3 - Performance, Visual Mesh QA & Regression Gate Verification (Priority: P2)

**Goal**: Verify mobile rendering budgets (< 2,000 active server parts, ≤ 1,850 planned), audit triangle ceilings against manifest (unculled ≤ 250k, culled ≤ 100k), visually inspect imported `dt_*` meshes in Play, and confirm ≥ 30 fps on unthrottled seconds in a 12-ball Studio performance run.

**Independent Test**: Triangle audit test and part budget assertion in `tests/unit/Downtown.test.luau`, 12-ball 60-second Studio performance run and mesh check recorded in `specs/008-downtown-inside-out/playtest.md`.

### Tests for User Story 3

- [X] T023 [P] [US3] Implement triangle ceiling audit (unculled `winter` ≤ 250,000, culled tier ≥ 4 ≤ 100,000) against `art/export/manifest.json` and part budget assertion (`placements + blocks + markers + 3 + 12 + 64 <= 1850` in both themes) in `tests/unit/Downtown.test.luau`
- [X] T024 [P] [US3] Add theme scoping test asserting zero base block ids contain `garland` or `slope`, garlands have `bottom >= 9`, and `city` builds zero theme blocks (N9, F2) in `tests/unit/Downtown.test.luau`

### Implementation for User Story 3

- [X] T025 [US3] 🔒 Studio verification: Claim Studio MCP, run 12-ball 60-second playtest in Holiday City (`winter`) at 640x360, sample fps per second (verify ≥ 30 fps on unthrottled seconds), verify active parts in Workspace (< 2,000), inspect `dt_*` meshes in Play (single material, atlas UVs, Minimal rating), read console output, record results under "Gate 2" in `specs/008-downtown-inside-out/playtest.md`, release Studio MCP claim

**Checkpoint**: Performance budgets and visual mesh quality verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, release candidate tracking, and final regression checks

- [X] T026 [P] Rewrite level design document to Concept A ("Inside Out" 880x880 layout, rings, tier placement targets) in `docs/design/03-city-level.md`
- [X] T027 [P] Update release candidate checklist with owner taste, human-played 12-spawn timings, and physical reference phone verification items in `docs/release-candidate.md`
- [X] T028 Perform rollback validation (`Config.Flags.Downtown = false`) ensuring Snow Village loads cleanly and passes unit tests in `src/shared/Config.luau`
- [X] T029 Execute full validation suite via `scripts/check.sh` and ensure 100% of Lune unit tests and Jest-Lua tests pass with zero errors

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) completion
- **User Story 2 (Phase 4)**: Depends on User Story 1 (Phase 3) completion (specifically Stage 1 slice verification in T013)
- **User Story 3 (Phase 5)**: Depends on User Story 2 (Phase 4) completion
- **Polish (Phase 6)**: Depends on User Story 3 (Phase 5) completion

### User Story Dependencies

- **User Story 1 (P1)**: Vertical slice of Ring 1 and first Ring 2 block - creates the core Old Quarter layout and 12 spawns
- **User Story 2 (P1)**: Extends layout to full 5 rings (Terraces, Yards, Boulevard, Skyline & Harbour) and tunes pace
- **User Story 3 (P2)**: Performance and mesh visual QA across the full 5-ring world

### Within Each User Story

- Tests written first, verified failing or asserting against target criteria
- Data layout and geometry changes before tuning
- Studio MCP claimed for 🔒 tasks, verified, recorded in `playtest.md`, and released
- Checkpoint validated before proceeding to next phase

### Parallel Opportunities

- Phase 1: T001 and T002 touch disjoint files and can run in parallel
- Phase 2: T003, T004, and T006 touch disjoint test files and can run in parallel
- Phase 3: T007 and T008 touch disjoint test files and can run in parallel
- Phase 4: T014 and T015 touch disjoint test files and can run in parallel
- Phase 5: T023 and T024 touch disjoint test areas in `Downtown.test.luau` and can run in parallel
- Phase 6: T026 and T027 touch disjoint documentation files and can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch test tasks for User Story 1 in parallel:
Task: T007 [P] [US1] "Add 12-eater first-minute test in tests/unit/Pace.test.luau"
Task: T008 [P] [US1] "Add Stage 1 vertical slice assertions in tests/unit/Downtown.test.luau"
```

---

## Parallel Example: User Story 2

```bash
# Launch test tasks for User Story 2 in parallel:
Task: T014 [P] [US2] "Implement layout regression tests in tests/unit/Downtown.test.luau"
Task: T015 [P] [US2] "Implement pace window tests in tests/unit/Pace.test.luau"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`Config.luau`, `WorldBuilder.luau` Boundary kind)
2. Complete Phase 2: Foundational (obstacle-aware pace model, sightline helpers, envelope pins)
3. Complete Phase 3: User Story 1 (Ring 1 Old Quarter + first Terraces block, 12 lane spawns, bollard gates)
4. **STOP and VALIDATE**: Verify 12-eater first minute via Lune, inspect overhead/street captures in Studio, record Stage 1 in `playtest.md`
5. Proceed to full rollout only after Stage 1 passes

### Incremental Delivery

1. Setup + Foundational → Foundation and test safety net ready
2. User Story 1 → Stage 1 vertical slice verified in Studio (MVP!)
3. User Story 2 → Full 5 rings rolled out, shortcuts/ramps verified, pace tuned
4. User Story 3 → 12-ball 60 s performance run, triangle ceilings, mesh visual inspection
5. Polish → Docs updated (`03-city-level.md`, `release-candidate.md`), rollback verified, `scripts/check.sh` clean

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Studio tasks (🔒) must be claimed before use and released after recording in `playtest.md`
- Owner taste items, human timings, and physical reference phone checks belong in `docs/release-candidate.md`, not `tasks.md`
- Commit after each task or logical group

## Phase 7: Convergence

- [X] T030 [US2] Reconcile the Downtown slot kinds so the Studio-pinned data-only switch passes `tests/studio/ThemeSwitch.spec.luau` ("replaces the slot objects…", line 166, failing 2026-11-02 at 149 passed / 2 failed): `Downtown.themeBindings` maps five slot kinds (`src/shared/Content/Worlds/Downtown.luau:1766–1778`, pinned in `tests/unit/Downtown.test.luau:325–345`) but the world builds slot placements only for `slot.small` door zones and `slot.landmark`; either build the missing `slot.medium`/`slot.yard`/`slot.street` placements in `src/shared/Content/Worlds/Downtown.luau` and renumber the pinned 97 dressing-slot count in `tests/unit/Downtown.test.luau:398–410`, or scope the ThemeSwitch assertion to the slot kinds the world builds — then record which option was taken and why (partial, HIGH)
- [X] T031 [US3] Fix the scatter probe premise in `tests/studio/WorldSpawner.spec.luau` ("scatter lands the same part on the ground, above Y = 0", line 184, failing 2026-11-02, expected 0.25 received 0.55): (-200, -150) is the Ring 3 Park lawn `dt_park_lawn_w` (top 0.3, `src/shared/Content/Worlds/Downtown.luau:1252`) in the Downtown world, not the open Y = 0 lawn the 007 comment describes; move the probe to genuinely open Y = 0 ground in Downtown and refresh the comment (partial, MEDIUM)
- [X] T032 [US3] 🔒 Re-run the Jest-Lua suites through Studio MCP (`return require(game.ServerStorage.Tests.runner)()` in Edit) after T030/T031 until zero failing suites and tests, and record the final pass/fail counts under a "Jest" heading in `specs/008-downtown-inside-out/playtest.md` (verification of the Studio half of T029)
