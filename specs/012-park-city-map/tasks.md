# Tasks: Park City Map (Grey Box)

**Input**: Design documents from `/specs/012-park-city-map/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md. No `contracts/`: the layout JSON and internal modules are the interfaces (plan.md).

**Tests**: Requested. The spec's gates G1, G4, G5 and G6 are machine-checked, so test tasks are included.

**Organization**: Phase 1 and 2 are shared. Phases 3–7 follow the spec's user stories in priority order. The plan's Stages A–D map onto them: Stage A → US2 (Downtown with the new rules), Stage B → US1 (Park City as Parts), Stage C → US3 (light objects), Stage D → US4 and US5, plus the Studio checks in US3 and Polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: different files, no dependency on an incomplete task.
- **[Story]**: user story from spec.md (US1–US5). Setup, Foundational and Polish have none.
- **🔒**: a Studio check. The agent runs it through the Studio MCP server (AGENTS.md). One agent drives Studio at a time (constitution X). Before any 🔒 task: `scripts/studio-preflight.sh`, `list_roblox_studios`, then the sync probe (`mismatches = {}`).
- Owner-only checks (phone frame rate, tuning, Spanish names, pace sign-off) go to `docs/release-candidate.md`, not here.

## Path Conventions

Single Rojo project. Shared rules in `src/shared/Rules/`, content in `src/shared/Content/Worlds/`, server in `src/server/`, client in `src/client/`, Lune tests in `tests/unit/`, Jest-Lua specs in `tests/studio/`, scripts in `scripts/`, art in `art/`.

---

## Phase 1: Setup (shared infrastructure)

**Purpose**: flags, config keys and the layout script hardening that every later phase needs.

- [ ] T001 Add `Flags.ParkCity`, `Flags.HeapFix` and `Flags.ReadableRules`, each default `false`, in `src/shared/Config.luau`. Existing keys and their pinned values do not change (`tests/unit/Config.test.luau` stays green).
- [ ] T002 [P] Add the new Park City keys to `src/shared/Config.luau`: `heapNewestGrace = 3` (seconds), `lightPoolCap = 450`, `lightDrawRadius = 120` (studs), `lightCellSize = 64` (studs), `lightRefreshSeconds = 0.2`, `lightRefreshStuds = 10`, `lightDeltaSeconds = 0.25`, `bobCount = 24`, `bobRadiusDiameters = 4`, `wobbleRadiusDiameters = 6`, `heapFitMaxScale = 0.45`, `heapFitBound = 1.25`, `heapFitNewestBound = 0.25`. Values are starting points; tuning is owner work.
- [ ] T003 [P] Make `scripts/park_city_layout.py` exit 1 on a problem: overlaps must be `[]`; any park quarter with more than 5 % of its area more than 40 studs from food fails; the part and light budgets of `docs/design/09-park-city-level.md` section 13 are checked. Print the object count per tier.
- [ ] T004 Add `--check` to `scripts/park_city_layout.py`: exit 1 when `docs/design/maps/park-city-layout.json` differs from a fresh run. Depends on T003.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: pure rules, the per-world rule data and the generated world. Every story depends on these.

**⚠️ CRITICAL**: no user story work begins until this phase is complete.

- [ ] T005 [P] Add the pure rule `canEat(rule, diameter, bulk, longest)` in `src/shared/Rules/Absorb.luau`. In bulk mode: edible iff `bulk <= ratio * D and longest <= longestRatio * D` (ratio 0.5, longestRatio 1.5). In size mode, keep `size <= absorbRatio * D` exactly. Test with fixed values in `tests/unit/Absorb.test.luau`, including a long thin violin that is edible and a lamp post that is not at D 3.
- [ ] T006 [P] Add the pure rule `growByBulk(D, bulk, k, garnish)` in `src/shared/Rules/Growth.luau`: D³ grows by `growthK` × bulk³; when `bulk < garnish * D` (garnish 0.08) it returns `D` unchanged. With garnish 0 the result matches today's growth. Test in `tests/unit/Growth.test.luau`.
- [ ] T007 [P] Add `speedCap(D, rule)` in `src/shared/Rules/Movement.luau`: 32 up to D 12, then `32 + 0.4 × (D − 12)`, at most 56. Test in `tests/unit/Movement.test.luau` at D 1, 12, 20, 30 and the cap at 56.
- [ ] T008 Resolve `WorldDef.rules` into `Worlds.rules` in `src/shared/Worlds.luau`. Each field falls back to its `Config` value (`startDiameter`, `absorbRatio`, `growthK`, the speed cap, `cameraMinDistance`). Downtown and Snow Village have no `rules` table and keep today's numbers. `Worlds.active` returns Park City when `Flags.ParkCity` is on, and `Flags.HeapFix` is implied by it.
- [ ] T009 Switch every gameplay read of those `Config` values to `Worlds.rules` at: `src/server/BallService.luau` (start diameter, 3 sites), `src/server/WorldSpawner.luau` (2), `src/server/KnockOff.luau` (1), `src/server/AbsorbService.luau` (2), `src/server/BoosterService.luau` (magnet), `src/client/BallController.luau` (3), `src/client/CameraController.luau` (2), `src/server/RunManager.luau` (final diameter). Depends on T008. No existing test file is edited; an edit that the change forces is a defect (plan.md "What must keep passing unchanged").
- [ ] T010 Add the optional `dims = {l, w, h}`, `bulk`, `size`, `tier`, `solid` and `light` fields to `ObjectDef` (find its declaration with `grep -rn "ObjectDef" src/`). Per data-model.md: `bulk` is the "cube root of `l × w × h`"; `size` is "the longest side (`max(l, w, h)`)"; `solid` is "true for hedge pieces and fences"; `light` is "true for Tier 1–2: not a server Part". A def without `dims` is a cube of `size`. `src/shared/ObjectVisual.luau` sizes the stand-in to `dims` when present. Pooled Parts carry `Bulk` and `Longest` attributes next to `Size`.
- [ ] T011 Write `scripts/park_city_world.py` (standard library only: `json`, `math`, `pathlib`). It reads `docs/design/maps/park-city-layout.json` and writes four generated Luau modules: `src/shared/Content/Worlds/ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau` and `src/shared/Localization/ParkCityStrings.luau`. Each file starts with a "generated, do not edit" line. Per research.md R1: the light file is one flat number array with a kind list, stride 5 (kind index, x, y, z, yaw), rounded to 0.01; the parts file holds the 942 Tier 3–6 rows with ids `p<n>`; blocks are the 71 non-hedge blocks; hedge pieces are objects with `solid = true`; the Spanish names come from a table inside the script. The world's own triangle budget gets a sixth Skyline entry; `Config.luau` `meshTriangles` keeps its five. Add `--check`: exit 1 when a regenerate would change any file. Depends on T010.
- [ ] T012 Run `python3 scripts/park_city_world.py` and commit the four generated files from T011. Depends on T011.
- [ ] T013 Merge `src/shared/Localization/ParkCityStrings.luau` into `src/shared/Localization/Strings.luau`. Keys are `object.park.<id>` in English and Spanish, balanced; `tests/unit/Strings.test.luau` stays green. Depends on T012.
- [ ] T014 Add the world check to `scripts/check.sh` after the Lune step: `python3 scripts/park_city_layout.py --check` and `python3 scripts/park_city_world.py --check`. Depends on T004 and T012.
- [ ] T015 Write `tests/unit/ParkCity.test.luau` to match the generated data to the layout JSON, read with `serde`: the count per tier equals `summary.objectsByTier`; every JSON object is found at its position within 0.01 with the same kind; the counts of blocks, spawns, rails, pads, catapults, water and tunnels are equal; every kind's `dims` equals the JSON's; `tier` equals `Tiers.lookup(needsD)` for the six park tiers; ids are unique; positions are inside ±500; the six tiers ascend by `minDiameter` (1 / 2.5 / 6 / 15 / 35 / 80, top 150) with stars 20 / 50 / 90. `tests/unit/run.luau` picks the file up by name. Depends on T012.

**Checkpoint**: foundation ready. The flags are off, the rules are pure and tested, and the generated world matches the layout.

---

## Phase 3: User Story 1 - Play the whole Park City map (Priority: P1) 🎯 MVP

**Goal**: with `Flags.ParkCity` on, the whole 1,000 × 1,000 map is built at the layout's coordinates, with spawns, set pieces and placeholders. With the flag off, Downtown loads unchanged.

**Independent Test**: turn on the Park City flag, start a run, roll from a spawn through each ring to the Plaza. Compare with `docs/design/maps/park-city.svg` and the zone maps.

- [ ] T016 [US1] In `src/server/WorldBuilder.luau`, build the 71 blocks from `ParkCity` (ground, roads, paths, buildings, roofs, ramps, spiral ramps, decks, maze, tunnels, drains) through the existing builder. Read the data; add no new geometry rules.
- [ ] T017 [US1] In `src/server/WorldBuilder.luau`, place the hub at x = −760, z 0 from the world `hub` data (the hub moves outside the 620-stud scenery bound while Park City is active).
- [ ] T018 [US1] Pool the 942 Tier 3–6 `fixedPlacements` (`ParkCityParts.luau`, ids `p<n>`) through the existing builder in `src/server/WorldBuilder.luau` and `src/server/WorldSpawner.luau`, using `dims` from T010.
- [ ] T019 [US1] Stage B only: build the Tier 1–2 doorstep crumbs and scene food as pooled Parts in `src/server/WorldSpawner.luau`, until Phase 5 moves them to light state. If the Stage B part count is over 1,800 (measured in T026), thin them with "drop every second Tier 2 object of scenes tagged park fill" and record in `specs/012-park-city-map/playtest.md` where it was used.
- [ ] T020 [US1] Add `buildPlaceholders` to `src/server/WorldBuilder.luau` (research R5): rails (14) as thin Neon beams with end posts; pads (40) as flat discs or squares, lily pads as slabs at `y`; catapults (6) as a base block and an arm at `restYaw`; water (stream, pond, sprinklers) as an opaque slab 0.05 above the ground. All go in a `Placeholders` folder, `Name` = placeholder id, tag `Placeholder`. No scripts, no touch handlers, no attributes the game reads.
- [ ] T021 [US1] Placeholder data: `WorldDef.placeholders` keeps each layout record unchanged (rail `points`, `dMin`, `dMax`, `speed`, `exit`; pad `up`, `forward`, `dMax`; catapult `aimArc`, `range`, `apex`; water `depth`, `wadeFromD`). Extend `tests/unit/ParkCity.test.luau` so that the counts per type and ids equal the layout's. Depends on T012 and T020.
- [ ] T022 [US1] Spawns: a new ball starts at `Worlds.rules.startDiameter` (1) on one of the 12 `ParkCity.spawnPoints`, facing the city, with its spawn's 20 doorstep crumbs (`doorstep_NN` scenes). Changes in `src/server/BallService.luau` and `src/server/WorldSpawner.luau`.
- [ ] T023 [US1] Golden spots: pass `ParkCity.golden` (8 spots) to the existing daily golden-object rule. Find the consumer with `grep -rn "golden" src/server`.
- [ ] T024 [US1] Regression: with `Flags.ParkCity` off, run `lune run tests/unit/run`. The Downtown, SnowVillage, Pace and Layout tests pass unedited. Run the Jest specs unchanged from plan.md "What must keep passing unchanged" once Studio is available (see T026).
- [ ] T025 🔒 [US1] Studio: with `Flags.ParkCity` on, start Play. From `execute_luau` on `Server`, compare the built world with the `ParkCity` data: blocks, objects, placeholders and the 12 spawns are present at their layout coordinates. Record the server part count. Depends on T016–T022.
- [ ] T026 🔒 [US1] Studio: roll a bot-driven ball from one spawn through its gate to the Plaza (method: AGENTS.md "Driving the ball"). Confirm that no static geometry blocks a designed route (spec US1 scenario 4). Record in `specs/012-park-city-map/playtest.md`. Depends on T025.

**Checkpoint**: Park City loads and can be walked end to end as Parts. Downtown is unchanged with the flag off.

---

## Phase 4: User Story 2 - See what you can eat (Priority: P1)

**Goal**: the rules and cues of Park City work on the map: the bulk rule, D 1 start, garnish, the heap fix, the wobble and ripple cues, the thud, the speed cap, and no text banners. Stage A of the plan: Downtown can be tried with `Flags.ReadableRules`.

**Independent Test**: in Park City (or Downtown with `ReadableRules`), grow from D 1 to about D 10. Check the heap outline against the ball's real size, eat a long thin object the old rule refused, bump a too-big object, and watch the cues. Unit tests cover the rules.

- [ ] T027 [US2] Absorb: `src/server/AbsorbService.luau` and the client absorb path use `Absorb.canEat` with `Worlds.rules` (bulk mode for Park City, size mode for Downtown and Snow Village). Spec FR-010.
- [ ] T028 [US2] Growth: `src/server/WorldSpawner.luau` and `src/server/AbsorbService.luau` grow by `Growth.growByBulk` when `rules.absorb.mode` is bulk. An object under garnish (0.08 × D) still pops, plays its sound and adds no size. Spec FR-011.
- [ ] T029 [US2] Downtown readable table in `src/shared/Content/Worlds/Downtown.luau`, read only when `Flags.ReadableRules` is on: six tiers, stars 20 / 50 / 90, the `rules` table, and `dims` for the long thin objects (violin, lamp post, ladder and similar; at most 30 entries, from the table in section 3.2 of `docs/design/09-park-city-level.md`). Tiers are recomputed from `needsD`. Downtown's smallest object is 0.3, so a D 1 start has food.
- [ ] T030 [US2] Add a sixth Tier 6 entry to the triangle budget used by the readable Downtown table (plan.md open point). `Config.luau` `meshTriangles` keeps five entries, and `tests/studio/ObjectTemplates.spec.luau` stays unedited.
- [ ] T031 [P] [US2] Pure rule `fit(dims, D)` in `src/shared/Rules/HeapFit.luau`, per research.md R4: the item's longest side is scaled to at most `0.45 × D`; its long axis lies tangent to the surface and its thinnest axis points along the normal; its centre is pushed in so it reaches at most `0.125 × D` above the surface (a 1.25 × D box). The single newest large catch (largest bulk) may reach `0.25 × D` for `heapNewestGrace` (3 s), then eases to the normal fit. No Roblox APIs (Rules purity guard).
- [ ] T032 [P] [US2] Test `tests/unit/HeapFit.test.luau`: the placement bound holds at D 1, 2, 5, 10, 20, 50 and 100 (SC-004); scale never exceeds `0.45 × D`; the newest-catch allowance lasts `heapNewestGrace` and then eases to the normal fit, with no jump between frames.
- [ ] T033 [US2] `src/client/StuckVisuals.luau`: `offsetFor`, `createVisual` and `reseat` use `HeapFit` when `Config.Flags.HeapFix or Config.Flags.ParkCity` is on. `maxVisibleStuck` (30) and the tail rule stay. When a big catch arrives, older small stuck objects are buried smoothly, with no pop (spec edge case). Depends on T031.
- [ ] T034 [US2] Bob cue in `src/client/Feedback.luau`: up to `bobCount` (24) edible objects within `bobRadiusDiameters` (4 D) of the local ball bob gently; too-big objects never move; Reduce motion turns the bob off. Use the existing reduce-motion setting (find it with `grep -rn -i "reduce" src/client`).
- [ ] T035 [US2] Wobble cue in `src/client/Feedback.luau`: on reaching a new tier, that tier's objects within `wobbleRadiusDiameters` (6 D) wobble once together. No text.
- [ ] T036 [US2] Bump cue in `src/client/BallController.luau` and `src/client/CameraController.luau`: contact with a too-big object bounces the ball back, plays a thud and a short camera nudge, with a cooldown so repeated rubbing does not chatter. No text (FR-017).
- [ ] T037 [US2] `src/client/Hud.luau`: when Park City or `ReadableRules` is on, no tier banner, no "next tier" line and no star-target text is shown (FR-016).
- [ ] T038 [US2] `src/client/CameraController.luau`: the closest camera distance comes from `Worlds.rules.cameraMinDistance` (4 studs at D 1).
- [ ] T039 [US2] Speed cap: `src/client/BallController.luau` uses `Movement.speedCap`. The server ceiling in `src/server/BallService.luau` becomes `max(Config.maxServerBallSpeed, cap(D) × 1.1)`. `BallGuard.verdict` is unchanged. Spec FR-013.
- [ ] T040 🔒 [US2] Studio, with `Flags.ReadableRules` on for Downtown: grow to about D 10 and capture the heap outline next to the ball's real size (SC-004). Eat a violin-like object that the old rule refused, bump a lamp post, and check the cues show with no text. Record in `specs/012-park-city-map/playtest.md`. Depends on T027–T039.
- [ ] T041 🔒 [US2] `tests/studio/BallService.spec.luau`: the server accepts a Park City speed up to the cap and refuses one above it. Depends on T039.

**Checkpoint**: the owner can judge "can I tell what I can eat?" on Downtown with `ReadableRules`, and Park City has its rules as data.

---

## Phase 5: User Story 3 - Twelve players on the full map (Priority: P2)

**Goal**: Tier 1–2 objects (3,107 light objects) are server data, not Parts. The server validates every absorb against that data, each client draws only what is near it, and 12 balls hold 30 fps on every unthrottled second.

**Independent Test**: start Park City with 12 balls (the heavy-scene benchmark with bots). Read the server part count and the per-second frame rate. Absorb a light object from too far away and confirm the server refuses it.

- [ ] T042 [P] [US3] Pure module `src/shared/Rules/Light.luau`: a grid of `lightCellSize` (64) studs over the light rows, built once; a nearby query for cells within a radius; `verdict(...)` checks existence, taken state, distance from the ball to the **data** position (`radius + size/2 + absorbDistanceTolerance`) and the size rule through `Absorb.canEat`. The rate limit is checked by the caller. No Roblox APIs.
- [ ] T043 [P] [US3] Test `tests/unit/Light.test.luau`: a far claim is refused; a taken object is refused; a too-big object is refused; an in-range edible object is accepted; the grid query returns objects within 120 studs; ids match `^L%d+$` and the index is in range.
- [ ] T044 [US3] `src/server/WorldSpawner.luau`: light state as arrays indexed by light index: `lightState` (0 available, 1 taken; "Starts all 0"), `lightTakenAt`, `lightRespawnAt`, and a `pendingLight` set so the tick walks only taken indices. An `outbox` of `{ taken, restored }` is flushed every `lightDeltaSeconds` (0.25 s). Respawn uses `Respawn.canRespawn`, the same delays (`respawnDelayMin..Max`) and the starvation ceiling as parts.
- [ ] T045 [US3] `src/server/AbsorbService.luau`: `L<n>` ids are routed by prefix in `tryAbsorb` and `tryBump`. They are checked as parts are today: the run accepts pickups, the id is a string, it matches `^L%d+$` with an index in range (otherwise `UnknownObject`), the rate limit holds, the object is not taken, and the distance is to the data position. The client sends only the id string. Depends on T042, T044.
- [ ] T046 [US3] `src/server/Remotes.luau`: add the `LightDelta` RemoteEvent, server to client only. `LightDelta:FireClient(player, taken: {number}, restored: {number}, isSnapshot: boolean)`. A snapshot is sent at join and at run start and resets the client's taken set; a delta applies the two lists. "Indices only; no sizes, no positions."
- [ ] T047 [US3] Remove the Stage B thinning from T019 for Tier 1–2 (all 3,107 rows, including the 119 hedge pieces as `solid`, become light state, none are Parts). If thinning was used, note its removal in `specs/012-park-city-map/playtest.md`. Depends on T044.
- [ ] T048 [US3] `src/client/LightField.luau` (new): builds the grid once from `ParkCityLight` via `Rules/Light`. Refreshes every `lightRefreshSeconds` (0.2 s) or after `lightRefreshStuds` (10 studs) of movement. Draws the nearest objects within `lightDrawRadius` (120 studs) into a pool of at most `lightPoolCap` (450) Parts. Drops objects culled by `Tiers.isCulled(objectTier, playerTier, Config.cullTierDelta)` and objects marked taken. Pooled Parts carry `Size`, `Bulk`, `Longest`, `Tier`, `Taken`, the tag `WorldObject`, and `Name` = light id. Solid objects stay collidable until the ball can eat them.
- [ ] T049 [US3] Client receives `LightDelta` (in `src/client/RunClient.luau` or `src/client/Main.client.luau`): a snapshot resets `LightField`'s taken set, a delta applies `taken` and `restored`. A taken light object disappears for every player (FR-019).
- [ ] T050 [US3] `src/client/BallController.luau`: the contact scan and `updateCollisions` pick up `LightField` parts through the `WorldObject` tag, with no new path. Resolve the plan.md open point on how `objectParts` picks up pool parts.
- [ ] T051 [US3] `src/client/StuckVisuals.luau`: for ids starting with `L`, the kind comes from `Worlds.lightKind(id)` and the visual is built through the same template path. The published `Stuck` string shape does not change. Depends on T048.
- [ ] T052 [P] [US3] 🔒 `tests/studio/AbsorbService.spec.luau`: add cases for light ids. A far claim is refused, a taken object is refused, a too-big object is refused, the rate limit holds, and `L<n>` out of range returns `UnknownObject`. Depends on T045.
- [ ] T053 [P] [US3] 🔒 `tests/studio/WorldSpawner.spec.luau`: add cases for light state. A take sets the state and the outbox; respawn follows the sight rule after its delay; the starvation ceiling applies. Depends on T044.
- [ ] T054 [US3] `src/client/WorldCuller.luau`: Park City light objects follow the tier cull; `tests/studio/WorldCuller.spec.luau` stays unedited and green on Downtown.
- [ ] T055 🔒 [US3] Studio, with `Flags.ParkCity` on and bots running: read the server part count (under 2,000 with 12 balls; zero `WorldObject` parts with `Tier` ≤ 2 on the server); read the client `LightField` pool (above 0 and at most 450); take a light object and confirm it disappears on a second client; send `Absorb:FireServer("L1")` from far away and confirm the refusal. Record in `playtest.md`. Depends on T045–T051.
- [ ] T056 🔒 [US3] 12-ball heavy-scene benchmark (G6): `tests/studio/HeavyScene.server.luau` with `Flags.ParkCity`, and `tests/studio/HeavySampler.client.luau` (method in its header). Sample 60 s, one fps value per second, throttled seconds (exactly 15 fps) listed apart, viewport size recorded. Write the `HeavySceneReport` attribute and `specs/012-park-city-map/playtest.md`. Every unthrottled second is at or above 30 fps. If there are no unthrottled seconds, ask the owner once to keep Studio in front and rerun (AGENTS.md). Depends on T055.

**Checkpoint**: Park City runs with light objects and 12 balls, with the benchmark recorded.

---

## Phase 6: User Story 4 - Pace measured and reported, not gated (Priority: P2)

**Goal**: a pace report for 12 spawns and 3 profiles, written into the spec folder. Two hard checks: first pickup within 3 s, and the open-route ladder has no gap. Nothing fails on pace values.

**Independent Test**: run the pace report on the layout, read the per-spawn table, and confirm the two hard checks pass.

- [ ] T057 [US4] Pure pace model in `src/shared/Rules/` (or a helper under `tests/unit/`): the growth profiles of `scripts/growth-sim.py` (weak, median, skilled) run on Park City's coordinates and rules, deterministic, stdlib-equivalent. Document the mapping in the file header.
- [ ] T058 [US4] `tests/unit/ParkPace.test.luau` writes `specs/012-park-city-map/pace-report.md`: for each of the 12 spawns and each profile, the size at 0:30, 1:00, … 4:00 and the time of each tier; spawns more than 15 % behind the median are marked. It passes whatever the numbers are (FR-022). A second run leaves no diff. Depends on T057.
- [ ] T059 [US4] In `tests/unit/ParkPace.test.luau`, the first-pickup check (G4 / FR-023): a D 1 ball at every spawn reaches an edible crumb within 3 s. The doorstep check: 20 doorstep light objects per spawn within 15 studs, all with `bulk <= 0.5` and `longest <= 1.5`. These checks do fail the build. Depends on T058.
- [ ] T060 [US4] In `tests/unit/ParkPace.test.luau`, the open-route ladder check (G5 / FR-023): on routes with no rails, pads or catapults, at every size from D 1 to the size that eats the Downtown hoardings, each zone's smallest food is at most 1.25 × the previous zone's largest. Fails on a gap. Depends on T058.
- [ ] T061 [US4] Confirm that `tests/unit/Pace.test.luau` (Downtown and Snow Village) is unedited and passing.

**Checkpoint**: the pace report exists for 12 spawns × 3 profiles, and both hard checks pass.

---

## Phase 7: User Story 5 - Images for the owner (Priority: P2)

**Goal**: fixed shots from camera positions in data (one per park quarter at D 1 camera height, plus Duck Island, the Hedge Maze, the Roof Run, the Car Park, the Plaza and a high overview). The owner's approval holds the merge (gate 6).

**Independent Test**: the fixed shots exist in the spec folder and match their positions in the layout.

- [ ] T062 [US5] Shots in `ParkCity.luau` (generated by T011, research R6): four quarter shots from spawns 1, 4, 7 and 10 at D 1 camera height, looking at the quarter's set piece; then Duck Island (`pond` landmark), the Hedge Maze (maze centre), the Roof Run, the Car Park, the Plaza and a high overview. Eleven shots, each `{ name, pos, look, fov }`. Test in `tests/unit/ParkCity.test.luau` that the names and order are pinned and each position is inside the map.
- [ ] T063 [US5] Extend `scripts/capture-export.luau` with `--world parkcity`: it resolves `ParkCity` instead of Downtown and writes blocks, parts, light rows, placeholders and shots to `art/render/world-parkcity.json`. Risk: if the draw rule for light rows and placeholders needs more than about 60 lines, write `scripts/park-capture-export.luau` instead (boxes by `dims` for blocks, parts and light objects).
- [ ] T064 [US5] Render the eleven shots from T062 with `art/scripts/capture_render.py` into `specs/012-park-city-map/shots/`, one PNG per shot, named as in the shot list. Depends on T063.
- [ ] T065 🔒 [US5] Only if the offline route (T064) fails twice: ask the owner once to keep Studio in front, then take the same shots with Studio `screen_capture` as a second opinion (the image cannot be saved to a file, so this is a fallback, not the primary set). Otherwise skip. Depends on T064.

**Checkpoint**: the shots exist and match the layout. Approval is still pending (see Polish).

---

## Final Phase: Polish & cross-cutting concerns

- [ ] T066 🔒 Studio playtest (G7): with Park City on, `start_stop_play`, play a short route as a bot (`BotRun`), then `get_console_output`. Expect no new errors or warnings from game scripts; a `ContentId rbxassetid://… failed` line is checked by grepping the repo for the id. Record in `specs/012-park-city-map/playtest.md`. This runs before any pull request is opened, and a Rojo wait that runs out here does not count as a failure of the two-failure rule.
- [ ] T067 Run `scripts/check.sh` end to end: StyLua, Selene, Rojo sourcemap, luau-lsp strict analysis, design tokens, atlas, Lune tests, the GreyBoxRoom guard, the Rules purity guard, and the new layout and world `--check` steps. Fix any failure.
- [ ] T068 Run the `quickstart.md` checks for each stage that are not already covered above, and record the results in `specs/012-park-city-map/playtest.md`.
- [ ] T069 Update `docs/release-candidate.md` with the owner-only items: phone frame rate; `growthK` and star tuning; the pace sign-off, including the design document's section 5.3 ±20 % marks, which the spec makes a report rather than a gate; Spanish object names; the knock-off difference (a knocked-off light object is not scattered); and a publish-checklist line that `ServerScriptService.LoadStringEnabled` must be off in anything published (AGENTS.md).
- [ ] T070 Gate 6 is open until the owner records approval in `specs/012-park-city-map/playtest.md`. Do not merge before then. A pull request is opened only when requested, and the shots and `playtest.md` are what the reviewer reads.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: none. T003 and T002 are [P].
- **Foundational (Phase 2)**: depends on Setup. Blocks every story. T005–T007 are [P]; T008 → T009; T010 → T011 → T012 → T013 and T015.
- **US1 (Phase 3)**: depends on Foundational. Stage B.
- **US2 (Phase 4)**: depends on Foundational. Stage A. Can run in parallel with US1 on separate files; T033–T039 touch `StuckVisuals`, `Hud` and `BallController`, which US1 does not.
- **US3 (Phase 5)**: depends on US1 (it replaces its Stage B Parts) and on T005 (`canEat`) from Foundational. Stage C.
- **US4 (Phase 6)**: depends on Foundational (world data, rules) and US3's light data for the doorstep check.
- **US5 (Phase 7)**: depends on T011 (shot data) and the world being built.
- **Polish**: depends on all stories.

### Story dependencies

- US1 and US2 are both P1 and mostly independent.
- US3 depends on US1 (the light system replaces the Stage B Parts).
- US4 and US5 depend on the built world.

### Within each story

- Tests before the code they test where they are in the same phase (T031/T032, T042/T043).
- Pure rules before the client and server that use them.
- Studio checks (🔒) after the code they measure.

### Parallel opportunities

- Setup: T002 and T003 together.
- Foundational: T005, T006, T007 together.
- US2: T031 and T032 together.
- US3: T042 and T043 together; T052 and T053 together after their dependencies.
- US4 model (T057) and US5 shot data (T062) can start together once the world exists.

---

## Implementation Strategy

### MVP (User Story 1)

1. Phase 1 and Phase 2.
2. Phase 3 (US1): with `Flags.ParkCity` on, the whole map is playable as Parts, thinned if needed.
3. Stop and check the Studio tasks T025 and T026.

### Incremental delivery

1. Foundation (Phases 1–2).
2. US1: the map exists and can be walked (Stage B).
3. US2: sizes and cues are readable, first on Downtown with `ReadableRules` (Stage A), then on Park City.
4. US3: light objects and 12 balls (Stage C), with the benchmark.
5. US4 and US5: pace report, shots and the owner's review (Stage D).
6. Polish, then gate 6.

---

## Notes

- **Claim for Studio work (constitution X)**: the agent running a 🔒 task owns Studio until it finishes; record the claim in `playtest.md`.
- **Pace**: the spec (FR-022, US4) makes pace a report, never a gate. Design document 09 section 5.3 lists ±20 % marks, which this feature does not gate.
- **Thinning**: the Stage B thinning rule is used only if T019 measures over 1,800 parts, and it is removed in T047.
- **Gate 6**: the owner's approval of the shots and of play, recorded in `playtest.md`, holds the merge (T070).
