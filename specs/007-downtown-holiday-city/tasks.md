# Tasks: Downtown Launch World — Core City Kit, Holiday City (`winter`), and Sunny City (`city`)

**Input**: Design documents from `/specs/007-downtown-holiday-city/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, `.specify/memory/constitution.md`

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to ([US1], [US2], [US3])
- **🔒**: Studio MCP task (runs through Studio MCP, claims Studio tool, does not touch user's desktop)
- **Blender**: Claims Blender MCP tool
- Descriptions include exact file paths and verbatim constraints

---

## Phase 1: Setup (Shared Infrastructure & Pipeline Generalisation)

**Purpose**: Generalise art manifests, budget sync scripts, and test runners to support both Snow Village and Downtown.

- [X] T001 Generalise art budget and sync scripts in `scripts/art-budgets.luau` and `scripts/art-sync.luau` to include Downtown objects and theme-only objects with `dt_` prefix alongside Snow Village, and regenerate `art/scripts/budgets.json`
- [X] T002 [P] Generalise art manifest unit test in `tests/unit/ArtManifest.test.luau` and pace simulation in `tests/unit/Pace.test.luau` to accept a parameterized world and theme rather than hardcoding Snow Village

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure, types, rules, and flags that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Add `Flags.Downtown = true` and `downtown = true` in `DefaultWorldsUnlocked` in `src/shared/Config.luau`, with validation in `tests/unit/Config.test.luau`
- [X] T004 [P] Implement `GoldenSpot` marker kind (`GOLDEN_FOOTPRINT = { w = 6, d = 6 }`, `subKind = "golden"`, `opts.requireGolden`) in `src/shared/Rules/Markers.luau`, update marker types in `src/shared/Content/GreyBoxRoom.luau`, update `tests/unit/Markers.test.luau`, and add `continue` skip in `src/server/WorldBuilder.luau`
- [X] T005 [P] Update `winter.lighting.clockTime` from `15.5` to `16.5` in `src/shared/Content/Themes.luau`, and update the expectation in `tests/unit/Themes.test.luau` (line 177)
- [X] T006 Update `src/shared/Worlds.luau` to implement three-way active world selection (`Downtown` if `Config.Flags.Downtown`, else `SnowVillage` if `Config.Flags.SnowVillage`, else `GreyBoxRoom`), preserving fallback and rollback paths
- [X] T007 [P] Audit existing Studio test specs (`tests/studio/RunManager.spec.luau`, `tests/studio/ThemeSwitch.spec.luau`, `tests/studio/WorldSpawner.spec.luau`) to derive active world, object IDs, and sizes dynamically from `Worlds.active`

**Checkpoint**: Foundational rules, types, flags, and world dispatch ready — user story implementation can now begin.

---

## Phase 3: User Story 1 - Growing From Doorstep to Skyline in a 5-Ring City Layout With Stand-In Parts First (Priority: P1) 🎯 MVP

**Goal**: Build and validate Downtown base layout with stand-in parts, 12 doorstep spawns with 40 Tier 1 objects within 10 studs, 74 core objects across 5 tiers, 5-ring districts, shortcuts, climbing routes, sightline corridors, markers, and verify 4-minute growth pacing targets.

**Independent Test**: Can be verified with `Assets.meshes` entries empty (stand-in mode) by running Lune unit tests (`tests/unit/Downtown.test.luau`, `tests/unit/Pace.test.luau`, `scripts/check.sh`) and an agent-driven Studio bot playtest across all 12 spawn slots, confirming 5-ring progression, 40 Tier 1 objects within 10 studs, `±20 s` pacing targets, working shortcuts/ramps/markers, active parts `< 1,890`, and owner sign-off in `specs/007-downtown-holiday-city/playtest.md`.

### Tests for User Story 1

- [X] T008 [P] [US1] Create unit test suite in `tests/unit/Downtown.test.luau` asserting invariants C1-C9, C14-C16, C18 (74 core objects, tier split 18/15/16/16/9, 14 heroes, object sizes `<= 0.4 * tier ceiling`, ascending coins, 12 spawns with `>= 40` Tier 1 placements within 10 studs, keep-outs, sightlines, and part budget `< 1,890`)
- [X] T009 [P] [US1] Extend `tests/unit/Pace.test.luau` to run deterministic greedy-eater simulations for Downtown across all 12 spawns asserting first pickup `<= 5 s`, Tier 2 at `30 ± 20 s`, Tier 3 at `90 ± 20 s`, Tier 4 at `165 ± 20 s`, and Tier 5 D `>= 80` by `240 s`

### Implementation for User Story 1

- [X] T010 [P] [US1] Author 74 core `ObjectDef` entries across 5 size tiers (`minDiameters = { 2, 5, 12, 30, 70 }`, `absorbRatio = 0.4`) with `dt_` asset keys, `w-*` palette roles, and fallback primitives (`B`, `S`, `C`) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T011 [US1] Author static `environment.blocks` (`SmoothPlastic`, palette swatch roles, `<= 400` blocks) for ground, roads, kerbs (1.0–1.5 studs), Car Park spiral ramp and deck, Construction Site scaffold ramps, storm-drain tunnel, alley walls, Plaza fountain basin, and Waterfront promenade in `src/shared/Content/Worlds/Downtown.luau`
- [X] T012 [US1] Author 12 doorstep `SpawnPoint`s, doorstep spawn zones (32 core T1 + 8 `slot.small` per doorstep), side-street sidewalk zones, and district placement zones totaling 1,245 base placements in `src/shared/Content/Worlds/Downtown.luau`
- [X] T013 [US1] Author `environment.markers` (9-12 hazard markers, 5 seeded golden spots on static geometry) and `keepOutAreas` (6 gates, 5 shortcuts, 12 sightline corridors to Glass Tower and Ferris Wheel, marker footprints) in `src/shared/Content/Worlds/Downtown.luau`
- [X] T014 [US1] Tune `growthK` (starting at 1.5) and zone placement counts in `src/shared/Content/Worlds/Downtown.luau` until `tests/unit/Downtown.test.luau` and `tests/unit/Pace.test.luau` pass with exit code 0
- [X] T015 [US1] 🔒 Run Studio grey-box playtest via MCP (claim: Studio) verifying 12-spawn bot runs, sightlines, shortcuts, jumping kerbs, Car Park ramp, part count `< 1,890`, capture screenshots in `specs/007-downtown-holiday-city/captures/`, and draft results in `specs/007-downtown-holiday-city/playtest.md` (closed by owner decision, not verified: playtest and sign-off deferred to the backlog until the real map exists; see playtest.md)
- [X] T016 [US1] Human owner approval gate: Owner plays grey-box build and signs off on layout, pacing, and sightlines in `specs/007-downtown-holiday-city/playtest.md` (closed by owner decision, not verified: playtest and sign-off deferred to the backlog until the real map exists; see playtest.md)

**Checkpoint**: At this point, User Story 1 (MVP) is fully functional and verified in grey box.

---

## Phase 4: User Story 2 - Holiday City (`winter`) Launch Theme & Data-Only Switch to Sunny City (`city`) (Priority: P1)

**Goal**: Implement launch theme `winter` (5 dressing slots, 13 overlay objects, 2 hero variants, ~150 overlays, snowfall, golden-hour lighting `clockTime = 16.5`, winter music, "Downtown: Holiday" book page) and data-only switch to `city` (5 dressing slots, summer lighting, city music, clean removal of overlays), plus client-side ambient pigeons and en/es localized strings.

**Independent Test**: Can be tested by running Lune validation (`tests/unit/Downtown.test.luau`, `tests/unit/Strings.test.luau`) and Studio bot playtests with `Downtown.activeThemeId = "winter"` and `Downtown.activeThemeId = "city"`, verifying that both themes load from the same base layout, hit the `±20 s` pacing targets, keep all gates/shortcuts/markers/sightlines clear, and preserve the **Downtown: Holiday** book page across the switch.

### Tests for User Story 2

- [X] T017 [P] [US2] Extend `tests/unit/Downtown.test.luau` with theme-binding assertions (invariants C10-C13, C17: winter overlays `<= 150`, keep-out intersections = 0, hero variants match base coins/tier/collision, book pages list correct objects with no rewards, city overlays empty)
- [X] T018 [P] [US2] Extend `tests/unit/Strings.test.luau` to check all 99 Downtown object keys, 10 tier keys, 4 book page keys in both `en` and `es`, and assert no prohibited FOMO/timer words ("limited", "ends", "hurry", dates, digits) in returning labels

### Implementation for User Story 2

- [X] T019 [P] [US2] Author `Downtown.themeBindings.winter` and `Downtown.themeBindings.city` in `src/shared/Content/Worlds/Downtown.luau` (5 slots, 13 winter overlay objects, 150 overlay placements, hero variants `dt_cocoa_truck` and `dt_glass_tower_bow`, and book pages `downtown.winter` and `downtown.city`)
- [X] T020 [P] [US2] Add complete English and Spanish translations for all 99 Downtown objects, 10 tier names and headlines, and 4 book page names and returning labels in `src/shared/Localization/Strings.luau`
- [X] T021 [P] [US2] Implement ambient pigeons client controller in `src/client/PigeonController.luau` (`<= 8` per district, unabsorbable, fly-away on ball proximity `< 12` studs, respects `Reduce motion`), configure `ambient.pigeons` in `src/shared/Content/Worlds/Downtown.luau`, and wire controller into `src/client/Main.client.luau`
- [X] T022 [US2] Update `tests/studio/ThemeSwitch.spec.luau` and `tests/studio/RunManager.spec.luau` to validate Downtown theme switching and run lifecycle in Studio
- [X] T023 [US2] 🔒 Run Studio theme playtest via MCP (claim: Studio) capturing Holiday City dressing (tree, stalls, rink, snowfall, music, book page) and proving data-only switch to `city` and back, recording findings in `specs/007-downtown-holiday-city/playtest.md`

**Checkpoint**: At this point, User Stories 1 AND 2 work independently and seamlessly across both themes.

---

## Phase 5: User Story 3 - Full Stylised-Real 3D Mesh Catalogue & 30 FPS Reference Phone Lock (Priority: P2)

**Goal**: Model and export stylised-real 3D meshes in Blender in 7 waves (A to G), hand off for Roblox upload, record asset IDs in `src/shared/Assets.luau`, and lock 30 fps performance with `< 2,000` active parts and triangle budgets at `640 × 360` with 12 concurrent balls in Holiday City.

**Independent Test**: Can be verified via `art/scripts/export_all.py` and `scripts/check.sh` (asserting UV bounds, single material, split normals, and triangle budgets across all Downtown and Holiday City `.fbx` exports, plus complete English and Spanish strings in `Strings.luau`) and a 12-ball Studio playtest in Holiday City captured at `640 × 360` holding `>= 30 fps` with `< 2,000` active parts.

### Blender Modelling & Export Tasks

- [X] T024 [P] [US3] Update `art/scripts/build_objects.py` with `--world downtown` mode to scaffold and manage Downtown collections and sources
- [X] T025 [US3] Model and export Wave A (Tier 1 core, 18 meshes) in `art/source/dt_tier1.blend` to `art/export/dt_*.fbx` following stylised-real pipeline (1-segment bevel, atlas UVs, `w-season` top faces, triangles `<= 500`) (claim: Blender)
- [X] T026 [US3] Model and export Wave B (Tier 2 core, 15 meshes) in `art/source/dt_tier2.blend` to `art/export/dt_*.fbx` (triangles `<= 700`) (claim: Blender)
- [X] T027 [US3] Model and export Wave C (Tier 3 core, 16 meshes) in `art/source/dt_tier3.blend` to `art/export/dt_*.fbx` (triangles `<= 1,500`) (claim: Blender)
- [X] T028 [US3] Model and export Wave D (Tier 4 core, 16 meshes) in `art/source/dt_tier4.blend` to `art/export/dt_*.fbx` (triangles `<= 3,500`) (claim: Blender)
- [X] T029 [US3] Model and export Wave E (Tier 5 core, 9 meshes) in `art/source/dt_tier5.blend` to `art/export/dt_*.fbx` (triangles `<= 5,000`) (claim: Blender)
- [X] T030 [US3] Model and export Wave F (Holiday City, 20 meshes: 5 winter slots, 13 overlays, 2 hero variants) in `art/source/dt_theme.blend` to `art/export/dt_*.fbx` (wire-frame light-up reindeer lamp, giant red bow tower) (claim: Blender)
- [X] T031 [P] [US3] Model and export Wave G (Sunny City slots, 5 meshes) in `art/source/dt_theme.blend` to `art/export/dt_*.fbx` (claim: Blender)

### Owner Upload Hand-Offs & Integration

- [X] T032 [US3] Human owner hand-off: Import exported FBX meshes into Studio via 3D Importer and supply numeric asset IDs
- [X] T033 [US3] Record uploaded mesh asset IDs in `src/shared/Assets.luau` and verify single material and atlas UVs via `tests/unit/ArtManifest.test.luau`

### Performance Validation & Budget Lock

- [X] T034 [US3] 🔒 Run 12-ball concurrent performance playtest in Holiday City at `640 × 360` via Studio MCP (claim: Studio), sample fps for 60 s, verify `>= 30 fps` unthrottled and parts `< 2,000`
- [X] T035 [US3] Lock per-tier triangle budgets (`500 / 700 / 1,500 / 3,500 / 5,000`) in `src/shared/Config.luau` and record final performance metrics, screen captures, and owner approval in `specs/007-downtown-holiday-city/playtest.md` (closed by owner decision, not verified: playtest and sign-off deferred to the backlog until the real map exists; see playtest.md)

**Checkpoint**: All 3 user stories complete, asset catalogue integrated, and 30 fps mobile performance locked.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements and safety validations that affect multiple user stories.

- [X] T036 [P] Verify rollback safety by toggling `Config.Flags.Downtown = false` and validating Snow Village and GreyBoxRoom fallbacks in `tests/unit/Config.test.luau` and Studio
- [X] T037 [P] Audit all updated and new test suites under `tests/unit/` and `tests/studio/` ensuring 100% pass rate
- [X] T038 Execute full repository validation via `scripts/check.sh` ensuring formatting, linting, type-checking, and unit tests exit with code 0
- [X] T039 Run `quickstart.md` validation steps end-to-end and finalize all sections in `specs/007-downtown-holiday-city/playtest.md` (closed by owner decision, not verified: playtest and sign-off deferred to the backlog until the real map exists; see playtest.md)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion. Delivers grey-box MVP.
- **User Story 2 (Phase 4)**: Depends on User Story 1 (Phase 3) base layout data.
- **User Story 3 (Phase 5)**: Depends on User Story 1 (Phase 3) and User Story 2 (Phase 4) grey-box owner sign-off.
- **Polish (Phase 6)**: Depends on completion of all user stories.

### User Story Dependencies

- **User Story 1 (P1)**: Needs Foundational phase. Can be completed and tested with stand-in parts alone.
- **User Story 2 (P1)**: Extends User Story 1 base layout with theme bindings, overlays, localized strings, and ambient pigeons.
- **User Story 3 (P2)**: Models 3D meshes for User Story 1 and 2 objects in waves, uploads IDs, and locks performance.

### Parallel Opportunities

- Within Phase 1: T002 can run in parallel with T001.
- Within Phase 2: T003, T004, T005, and T007 can all run in parallel as they touch disjoint files (`Config.luau`, `Rules/Markers.luau`, `Themes.luau`, `tests/studio/*.spec.luau`).
- Within Phase 3: T008, T009, and T010 can run in parallel.
- Within Phase 4: T017, T018, T019, T020, and T021 can all run in parallel across disjoint files (`Downtown.test.luau`, `Strings.test.luau`, `Downtown.luau`, `Strings.luau`, `PigeonController.luau`).
- Within Phase 5: Wave G (T031) can be prepared in parallel with earlier waves. Wave modelling across separate `.blend` files (T025–T030) can be batched cleanly.
- Within Phase 6: T036 and T037 can run in parallel.

---

## Parallel Example: User Story 1

```bash
# Launch test and initial catalogue tasks in parallel:
Task T008: "Create unit test suite in tests/unit/Downtown.test.luau"
Task T009: "Extend tests/unit/Pace.test.luau to run deterministic greedy-eater simulations"
Task T010: "Author 74 core ObjectDef entries across 5 size tiers in src/shared/Content/Worlds/Downtown.luau"
```

## Parallel Example: User Story 2

```bash
# Launch test, strings, theme bindings, and pigeons in parallel:
Task T017: "Extend tests/unit/Downtown.test.luau with theme-binding assertions"
Task T018: "Extend tests/unit/Strings.test.luau to check all 99 Downtown object keys"
Task T019: "Author Downtown.themeBindings.winter and Downtown.themeBindings.city in src/shared/Content/Worlds/Downtown.luau"
Task T020: "Add complete English and Spanish translations in src/shared/Localization/Strings.luau"
Task T021: "Implement ambient pigeons client controller in src/client/PigeonController.luau"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Setup) and Phase 2 (Foundational).
2. Complete Phase 3 (User Story 1 - Base Layout & Stand-Ins).
3. **STOP and VALIDATE**: Test User Story 1 independently with Lune tests and Studio bot playtest.
4. Obtain owner sign-off on grey-box layout before proceeding to art production.

### Incremental Delivery

1. Setup + Foundational → Core rules, flags, and types ready.
2. User Story 1 → Grey-box city playable with stand-in parts, 12 doorstep spawns, 5-ring districts, and tuned pacing (MVP).
3. User Story 2 → Holiday City (`winter`) and Sunny City (`city`) data switch, full translations, and ambient pigeons.
4. User Story 3 → Wave-by-wave 3D mesh modelling in Blender, upload hand-offs, and 30 fps mobile lock.
5. Polish → Rollback validation and repository-wide checks passing with exit code 0.

---

## Phase 7: Convergence (round 3)

- [X] T040 Narrow the storm-drain tunnel in `src/shared/Content/Worlds/Downtown.luau` (walls currently leave a 6.0-stud inner gap) so only Tier 1–2 balls can pass and Tier 3+ (`diameter >= 5`) is physically blocked, keeping golden spot 3 reachable for Tier 1–2 balls, then re-run `tests/unit/Downtown.test.luau`, `tests/unit/Pace.test.luau` and `scripts/check.sh` per US1/AC1 (contradicts)
