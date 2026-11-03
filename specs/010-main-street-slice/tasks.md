# Tasks: Main-Street Slice

**Input**: Design documents from `/specs/010-main-street-slice/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

**Tests**: Unit tests (Lune) in `tests/unit/`, Studio benchmarks and playtest checks in `tests/studio/`, and fixed camera captures in `specs/010-main-street-slice/captures/`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., `[US1]`, `[US2]`, `[US3]`, `[US4]`)
- **🔒**: Studio MCP check executed by the agent
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Shared project configuration, assets placeholders, and release-candidate documentation

- [X] T001 [P] Document release-candidate hand-off items in docs/release-candidate.md under a new "Main-Street slice (010)" section (Gate 6 owner visual/play approval before merge, phone fps with 12 balls vs 30 fps, owner upload of facade/sign atlas and at most 6 billboard textures, swapping real 004h meshes via assetKey data, owner size-readability sign-off, deciding default flag values, and confirming defaults D1 to D11)
- [X] T002 [P] Add placeholder asset keys in src/shared/Assets.luau: `facadeAtlas: string = ""` and `billboards: { b1: string, b2: string, b3: string, b4: string, b5: string, b6: string } = { b1 = "", b2 = "", b3 = "", b4 = "", b5 = "", b6 = "" }`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core configuration flags, caps, and test pins required before user stories begin

**⚠️ CRITICAL**: Must be completed before user story implementation

- [X] T003 Add configuration keys to src/shared/Config.luau: `Flags.MainStreetSlice = false`, `Flags.SliceHud = false`, `Flags.HeapRedesign = false`, `billboardTextureCap = 6`, `maxPublishedStuck = 60`, `heapLocalCap = 40`, `heapRemoteCap = 12`, `heapScaleExponent = 1.0`, `heapCoverageTargetD = 5`, `heapCoverageTarget = 0.6`, `tooLargeBumpCooldown = 0.4`, and `tooLargeBumpImpulse = 18`
- [X] T004 Update configuration unit test pins in tests/unit/Config.test.luau asserting the new flags (`MainStreetSlice`, `SliceHud`, `HeapRedesign`), numeric limits (`billboardTextureCap = 6`, `maxPublishedStuck = 60`, `heapLocalCap = 40`, `heapRemoteCap = 12`, `heapScaleExponent = 1.0`, `heapCoverageTargetD = 5`, `heapCoverageTarget = 0.6`), and contact bump parameters (`tooLargeBumpCooldown = 0.4`, `tooLargeBumpImpulse = 18`)

**Checkpoint**: Foundation ready - user stories can now be implemented

---

## Phase 3: User Story 1 - Playable Main-Street Vertical Slice with Open Park Start & Rule-Driven Placement (Priority: P1) 🎯 MVP

**Goal**: Deliver a playable ~200 × 500 stud vertical slice world (`city` theme, gated behind `Config.Flags.MainStreetSlice`) with an open park start (12 non-blocking spawns, first pickup within 5 s), suburb corner, continuous main street with building fronts on both sides, and skyline goal ahead, populated via pure deterministic street rules and 10 scene kits.

**Independent Test**: Unit tests in `tests/unit/StreetRules.test.luau`, `tests/unit/SceneKit.test.luau`, and `tests/unit/MainStreetSlice.test.luau` verify that street expansion, kit expansion, and world content resolve deterministically with exact bounds, 12 spawns facing +z with Tier 1 food within 15 studs, placement count <= 1,200, and valid object IDs.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T005 [P] [US1] Implement pure street rules unit tests in tests/unit/StreetRules.test.luau checking hand-computed coordinates and guarantees: kerb band 0.4 stud high, sidewalk width `sidewalk >= 6`, road surface `w-asphalt` >= 2.5x darker than `w-sidewalk`, centre/lane markings (1-stud stripe, 1-stud gap), zebra crossings at junctions, trees every `treeEvery = 18`, lamps every `lampEvery = 24` with clearance `lampTreeClear = 4` (no lamp within 4 studs of a tree trunk), corner bins, road-facing benches, parallel-parked cars, and seeded jitter bounds (+-0.5 stud position, +-3 degrees yaw)
- [X] T006 [P] [US1] Implement pure scene kit expansion unit tests in tests/unit/SceneKit.test.luau verifying kit translation and rotation `x = ox + dx*cos(yaw) + dz*sin(yaw)` and `z = oz - dx*sin(yaw) + dz*cos(yaw)`, seeded jitter, placement IDs prefixed `idPrefix .. "_" .. index`, and hard error when any entry falls outside kit footprint (`halfX`, `halfZ`) or world bounds
- [ ] T007 [US1] Implement slice world unit tests in tests/unit/MainStreetSlice.test.luau asserting `worldId = "main_street_slice"`, `halfExtent = 250`, boundaries at x in [-100, 100] and z in [-250, 250], exactly 12 spawn points >= 10 studs apart pairwise facing +z within 30 degrees with Tier 1 pickup within 15 studs, zone order along z (park [-250, -130], suburb [-130, -60], main street [-60, 170], skyline [170, 250]), placement count <= `maxPlacements = 1200`, unique placement IDs, object sizes <= `absorbRatio * tier ceiling`, all 10 kits present, and full determinism across repeated seeded runs

### Implementation for User Story 1

- [X] T008 [P] [US1] Implement pure street rules generator in src/shared/Rules/StreetRules.luau expanding `StreetDef` into `StreetOut = { blocks: { BlockDef }, placements: { Placement } }` with zero engine calls or clock reads (using Park-Miller RNG `seed * 48271 % 2147483647`, kerb height 0.4 stud, `sidewalk >= 6`, zebra crossings, `treeEvery = 18`, `lampEvery = 24`, `lampTreeClear = 4`, corner bins, road-facing benches, and parallel-parked cars)
- [X] T009 [P] [US1] Implement pure scene kit expansion engine in src/shared/Rules/SceneKit.luau defining `SceneKit.expand(kit, instance, idPrefix, bounds) -> { Placement }` rotating entries by `instance.yaw`, adding origin `(ox, oz)`, applying seeded jitter, generating IDs, and throwing error on footprint or boundary overflow
- [X] T010 [P] [US1] Define the 10 starter scene kits as data in src/shared/Content/SceneKits.luau (`picnic_spread`, `cafe_terrace`, `bus_stop`, `fruit_stall`, `bike_rack`, `road_works`, `car_park_rows`, `yard_sale`, `flower_bed`, `recycling_point`) with relative offsets (`dx`, `dz`, `yaw`), footprints (`halfX`, `halfZ`), and valid object IDs
- [ ] T011 [US1] Implement vertical slice world definition and precedence in src/shared/Content/Worlds/MainStreetSlice.luau, src/shared/Worlds.luau, and tests/unit/Downtown.test.luau with `worldId = "main_street_slice"`, `halfExtent = 250`, `outerHalfExtent = 300`, `maxPlacements = 1200`, 12 park spawn points >= 10 studs apart facing +z, Boundary blocks at x = +-100 and z = +-250, slice ObjectDefs (`shop_front`, `fruit_crate`, `flower_pot`, `picnic_blanket`, `awning`, `road_barrier` with `bookId = "slice." .. id`), building fixed placements and blocks via `StreetRules.expand` and `SceneKit.expand`, and updating `Worlds.active` precedence chain `if Config.Flags.MainStreetSlice then MainStreetSlice :: any elseif Config.Flags.Downtown ...`
- [ ] T012 [P] [US1] Update ambient controller start condition in src/client/Main.client.luau to check "world has `ambient`" instead of `Config.Flags.Downtown`, starting pigeons on the slice while leaving traffic disabled
- [ ] T013 [P] [US1] Document street placement rules and scene kit data contract in specs/010-main-street-slice/contracts/street-rules-and-scene-kits.md for reuse by 004j on Downtown

**Checkpoint**: User Story 1 is functional and testable independently (MVP increment)

---

## Phase 4: User Story 2 - Player Ball as a Lumpy Object Heap (Priority: P1)

**Goal**: Redesign the player ball into a dense, lumpy heap of absorbed items that mostly hides the base sphere (>= 60% coverage) by D = 5, keeps biggest and newest catches (including Tier 4+ milestone catches like buses) on the outside shell, buries older small items without popping, and scales attached meshes with ball diameter.

**Independent Test**: Unit tests in `tests/unit/Heap.test.luau` verify that heap selection ranks by `score = size / (1 + age)`, preserves Tier >= 4 protected items, achieves >= 0.6 coverage at D = 5, calculates average buried colour in `coreColor`, and interpolates `buryProgress` linearly.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T014 [P] [US2] Implement pure ball heap unit tests in tests/unit/Heap.test.luau verifying deterministic scoring `score(e) = e.size / (1 + e.age)`, tie-breaking by key, protecting items with tier >= `protectTier = 4`, `coverage(ballD, outer, itemFootprint)` >= `Config.heapCoverageTarget = 0.6` at `heapCoverageTargetD = 5`, `coreColor(buried, paletteOf)` average RGB calculation, and linear `buryProgress(elapsed, duration)`

### Implementation for User Story 2

- [ ] T015 [P] [US2] Implement pure heap selection and coverage logic in src/shared/Rules/Heap.luau exporting `select(entries, params) -> HeapResult`, `coverage(ballD, outer, itemFootprint) -> number`, `coreColor(buried, paletteOf) -> { r: number, g: number, b: number }`, and `buryProgress(elapsed, duration) -> number` with no engine types or `require(script`
- [ ] T016 [P] [US2] Update stuck replication in src/server/BallService.luau to publish up to `Config.maxPublishedStuck = 60` entries in the `Stuck` attribute when `Config.Flags.HeapRedesign` is true while keeping server `maxTrackedStuck = 120` and knock-off logic intact
- [ ] T017 [US2] Redesign ball attachment rendering in src/client/StuckVisuals.luau using `Heap.select` (with `Config.heapLocalCap = 40` for local ball and `heapRemoteCap = 12` for remote balls) when `Config.Flags.HeapRedesign` is true, welding outer visuals at `radius + size * stuckEmbed` scaled by `(D / refD) ^ heapScaleExponent`, smoothly shrinking buried items over `buryProgress`, and tinting the base sphere with `Heap.coreColor`

**Checkpoint**: User Stories 1 and 2 work independently and together

---

## Phase 5: User Story 3 - Visual Size Readability Without HUD Text Prompts (Priority: P1)

**Goal**: Deliver clear visual size readability by removing text prompts (`Next:`, star row, tier banner) from the HUD during slice runs and providing an immediate physical bump impulse and impact sound when contacting an unabsorbable object.

**Independent Test**: Studio playtest verifies HUD displays only the countdown timer and size readout (omitting `Next:`, star row, and `YOU CAN ROLL UP` banner), and rolling into an oversized object triggers an immediate physical bump away from contact and sound with no text popup.

### Implementation for User Story 3

- [ ] T018 [P] [US3] Update HUD component gating in src/client/Hud.luau to omit creation of `NextTier`, `Star1..n`, and `TierBanner` when `Config.Flags.SliceHud` is true, displaying only the timer and ball size readout
- [ ] T019 [P] [US3] Implement bump audio trigger hook in src/client/Feedback.luau to play `Assets.sounds.bump` upon client-side too-large obstacle contact
- [ ] T020 [US3] Implement physical too-large obstacle bump in src/client/BallController.luau applying an immediate `AssemblyLinearVelocity` impulse of `Config.tooLargeBumpImpulse = 18` studs/s away from contact with cooldown `Config.tooLargeBumpCooldown = 0.4` s when `Absorb.canAbsorb` returns false and `Config.Flags.SliceHud` is true

**Checkpoint**: User Stories 1, 2, and 3 are functional and verifiable

---

## Phase 6: User Story 4 - Data-Driven Shop Front Signs & Capped Billboard Slots (Priority: P2)

**Goal**: Provide data tables for shop-front sign slots (invented proper-noun names sharing a facade atlas) and billboard slots (`sponsored = false`, capped unique textures) in content data, ensuring changing signs or billboards requires only data edits.

**Independent Test**: Lune unit tests in `tests/unit/MainStreetSlice.test.luau` verify that all sign and billboard slots lie within world bounds, every sign references a valid atlas region, distinct billboard textures do not exceed `Config.billboardTextureCap = 6`, all billboards carry `sponsored == false`, and shop names contain no banned words or real brands.

### Implementation for User Story 4

- [ ] T021 [P] [US4] Define sign slots and billboard slots as data in src/shared/Content/Signs.luau specifying `SignSlot = { id, facadeId, shopName, atlasRegion, x, y, z, yaw }` with invented proper-noun shop names and `BillboardSlot = { id, x, y, z, yaw, imageAsset, sponsored }` with `sponsored = false` and `imageAsset` keys `"b1"` through `"b6"`
- [ ] T022 [US4] Integrate sign and billboard slot tables into src/shared/Content/Worlds/MainStreetSlice.luau, attaching signs to main-street building facades and placing billboards along designated street and skyline structures
- [ ] T023 [US4] Add sign and billboard validation suite to tests/unit/MainStreetSlice.test.luau asserting all `facadeId` references exist, all `atlasRegion` names are valid, distinct `imageAsset` count <= `Config.billboardTextureCap = 6`, all slots have `sponsored == false`, all slots lie within world bounds, and shop names/billboard IDs pass the banned word and real-brand filter list

**Checkpoint**: All user stories (US1 through US4) are implemented and testable

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Offline capture tooling, static validation, Studio 12-ball benchmark, playtest verification, and fixed shots capture

- [ ] T024 [P] Define the five slice camera shots in art/capture/cameras-slice.json (`01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`) and pin the file with unit test tests/unit/CaptureCamerasSlice.test.luau
- [ ] T025 [P] Add `--world slice` option to scripts/capture-export.luau to export slice camera configurations and bounds for offline Blender fallback rendering
- [ ] T026 Execute quality gate 1 validation via scripts/check.sh verifying StyLua formatting, Selene linting, strict luau-lsp typechecking, pure rules purity grep, and all Lune unit tests pass clean with exit code 0
- [ ] T027 🔒 Extend Studio benchmark harness in tests/studio/HeavyScene.server.luau and tests/studio/HeavySampler.client.luau to load MainStreetSlice with 12 active balls at 640x360, evaluate heap candidates (1: baseline, 2: outer cap A, 3: A+B, 4: A+B+C, 5: D), record per-second fps, active parts, triangles, and draw calls in specs/010-main-street-slice/playtest.md, and verify >= 30 fps on unthrottled seconds under 2,000 server parts (Quality Gate 2)
- [ ] T028 🔒 Run Studio playtest and console read on MainStreetSlice using scripts/studio-sync-probe.sh and Roblox_Studio_get_console_output to verify 0 new console errors or warnings and confirm open park start and too-large bump behavior (Quality Gate 2)
- [ ] T029 🔒 Capture the five fixed camera shots (`01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`) into specs/010-main-street-slice/captures/ via Studio screen_capture or offline Blender fallback renderer (Quality Gate 6)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2)
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) - Can run in parallel with US1 (touches disjoint files)
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) - Can run in parallel with US1 and US2 (touches disjoint files)
- **User Story 4 (Phase 6)**: Depends on User Story 1 (Phase 3) completion (integrates signs/billboards into `MainStreetSlice.luau`)
- **Polish & Cross-Cutting (Phase 7)**: Depends on all desired user stories being complete (T024 and T025 can run earlier as [P])

### User Story Dependencies

```text
Foundational (T003, T004)
     │
     ├───► US1: Vertical Slice & Street Rules (T005 - T013) ───► US4: Signs & Billboards (T021 - T023)
     │                                                               │
     ├───► US2: Ball Heap Redesign (T014 - T017) ────────────────────┤
     │                                                               │
     └───► US3: Size Readability & HUD (T018 - T020) ────────────────┘
                                                                     │
                                                                     ▼
                                                         Polish & Gates (T024 - T029)
```

### Within Each User Story

- Unit tests written first and verified to fail before implementation
- Pure rules (`Rules/`) before content modules (`Content/`)
- Content definitions before world assembly
- Presentation controllers before visual integration

### Parallel Opportunities

- **Phase 1**: `T001` and `T002` can run in parallel
- **User Story 1 Tests**: `T005` and `T006` can run in parallel
- **User Story 1 Rules/Content**: `T008`, `T009`, `T010`, `T012`, `T013` can run in parallel
- **Cross-Story Parallelism**: Once Phase 2 is complete, US1 (`T005`-`T013`), US2 (`T014`-`T017`), and US3 (`T018`-`T020`) can be implemented in parallel across independent developers or threads
- **Phase 7 Tooling**: `T024` and `T025` can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch test creation for US1 in parallel:
Task: "Implement pure street rules unit tests in tests/unit/StreetRules.test.luau"
Task: "Implement pure scene kit expansion unit tests in tests/unit/SceneKit.test.luau"

# Launch pure rules and content modules in parallel:
Task: "Implement pure street rules generator in src/shared/Rules/StreetRules.luau"
Task: "Implement pure scene kit expansion engine in src/shared/Rules/SceneKit.luau"
Task: "Define the 10 starter scene kits as data in src/shared/Content/SceneKits.luau"
```

---

## Parallel Example: User Story 2

```bash
# Launch heap test and server stuck publication in parallel:
Task: "Implement pure ball heap unit tests in tests/unit/Heap.test.luau"
Task: "Update stuck replication in src/server/BallService.luau"

# Implement pure heap rule module:
Task: "Implement pure heap selection and coverage logic in src/shared/Rules/Heap.luau"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`, `T002`)
2. Complete Phase 2: Foundational (`T003`, `T004`)
3. Complete Phase 3: User Story 1 (`T005` to `T013`)
4. **STOP and VALIDATE**: Run `tests/unit/StreetRules.test.luau`, `tests/unit/SceneKit.test.luau`, and `tests/unit/MainStreetSlice.test.luau`. Boot slice in Studio to verify 12 spawns on open park ground with immediate Tier 1 food and sightline to skyline.

### Incremental Delivery

1. **Increment 1 (MVP)**: Setup + Foundational + US1 → Playable slice world with rule-driven placement and open park start
2. **Increment 2**: Add US2 → Lumpy heap ball visual with milestone catches and burial
3. **Increment 3**: Add US3 → Simplified HUD and physical bump feedback on oversized objects
4. **Increment 4**: Add US4 → Invented shop signs on shared atlas and capped placeholder billboards
5. **Increment 5 (Release Gate)**: Run `scripts/check.sh` (Gate 1), Studio 12-ball benchmark & playtest (Gate 2), and capture five fixed shots for owner visual review (Gate 6)

---

## Notes

- All tasks strictly follow `- [ ] [TaskID] [P?] [Story?] Description with file path`
- `[P]` indicates tasks touching disjoint files that can execute in parallel
- `[Story]` labels map directly to `spec.md` user stories: `[US1]`, `[US2]`, `[US3]`, `[US4]`
- 🔒 denotes Studio MCP checks requiring Studio connection
- Owner checks (phone fps, atlas upload, Gate 6 sign-off) are documented in `docs/release-candidate.md`
- Gate 6 approval holds the PR merge, but the PR can be opened to display the captured shots
