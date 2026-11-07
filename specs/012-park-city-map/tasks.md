# Tasks: Park City Map (Grey Box)

**Input**: Design documents from `/specs/012-park-city-map/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md. No `contracts/`: the layout JSON and internal modules are the interfaces (plan.md).

**Tests**: Requested. The spec's gates G1, G2, G4, G5 and G6 are machine-checked, so test tasks are included.

**Organization**: the phases follow the plan's stages, so every stage ends in a build the owner can play (constitution
4.1.0, playable first):

| Stage | Phase | What the owner can play at the end |
| --- | --- | --- |
| A | 2 (US2) | Downtown with the new size rules, heap fix and cues (`Flags.ReadableRules`). This is the MVP. |
| B | 3, 4 (US1) | The whole Park City map, with doorsteps, all the bigger food and the placeholders. The size tool lets them tour each ring at its size. |
| C | 5 (US3) | Park City at full food density with 12 balls. A ball can grow through the whole map. |
| D | 6, 7, Polish (US4, US5) | The pace report, the fixed shots, the Studio playtest and gate 6. |

## Format: `[ID] [P?] [Story] Description`

- **[P]**: different files, no dependency on an incomplete task.
- **[Story]**: user story from spec.md (US1 to US5). Setup, Foundational and Polish have none.
- **🔒**: a Studio check. The agent runs it through the Studio MCP server (AGENTS.md). One agent drives Studio at a time (constitution X). Before any 🔒 task, run `scripts/studio-preflight.sh`, then `list_roblox_studios`, then the sync probe (`mismatches = {}`).
- Owner-only checks (phone frame rate, tuning, Spanish names, pace sign-off) go to `docs/release-candidate.md`, not here.

## Path Conventions

Single Rojo project. Shared rules in `src/shared/Rules/`, content in `src/shared/Content/Worlds/`, server in `src/server/`, client in `src/client/`, Lune tests in `tests/unit/`, Jest-Lua specs in `tests/studio/`, scripts in `scripts/`, art in `art/`.

## Already done in the layout (before these tasks)

The layout script (`scripts/park_city_layout.py`) already does what the first draft of these tasks asked for (old T003 and T004):
- it exits 1 on overlaps;
- it exits 1 on a park quarter with more than 5 % of its area more than 40 studs from food;
- it exits 1 on server objects over 1,200 or light objects over 3,500;
- it prints the objects per tier;
- `--check` fails on a stale JSON.

The layout was also fixed so that it can be built literally:
- the maze is 476 hedge objects;
- the root tunnels are wall and roof blocks;
- the drains are pipe placeholders;
- the hoardings are pieces;
- the park edge is a kerb in segments;
- the boundary is four walls;
- ramps say which side is up, and spirals carry `turns` and `width`.

---

## Phase 1: Setup (shared infrastructure)

- [X] T001 In `src/shared/Config.luau`, add the flags `Flags.ParkCity`, `Flags.HeapFix`, `Flags.ReadableRules` and `Flags.DebugSize` (all default `false`), and these keys:
  - `heapNewestGrace = 3` (seconds);
  - `lightPoolCap = 450`;
  - `lightDrawRadius = 120` and `lightCellSize = 64` (studs);
  - `lightRefreshSeconds = 0.2` and `lightRefreshStuds = 10`;
  - `lightDeltaSeconds = 0.25`;
  - `bobCount = 24`, `bobRadiusDiameters = 4` and `wobbleRadiusDiameters = 6`;
  - `heapFitMaxScale = 0.45`, `heapFitBound = 1.25` and `heapFitNewestBound = 0.25`.

  Existing keys and their pinned values do not change (`tests/unit/Config.test.luau` stays green). Values are starting points; tuning is owner work.
- [X] T002 [P] Add `python3 scripts/park_city_layout.py --check` to `scripts/check.sh` after the Lune step.

---

## Phase 2: User Story 2 - See what you can eat (Priority: P1), Stage A 🎯 MVP

**Goal**: the size and readability rules work, first on the existing Downtown map behind `Flags.ReadableRules`. Those rules are the bulk rule, D 1 start, garnish, six tiers, stars 20 / 50 / 90, the heap fix, the bob and ripple cues, the thud, no text banners and the speed cap. Park City gets the same rules as its own world data in Phase 3.

**Independent Test**: on Downtown with `ReadableRules` on, grow from D 1 to about D 10. Check the heap outline against the ball's real size, eat a long thin object the old rule refused, bump a too-big object, and watch the cues. Unit tests cover the rules.

- [X] T003 [P] [US2] Add the pure rule `canEat(rule, diameter, bulk, longest)` in `src/shared/Rules/Absorb.luau`.
  - In bulk mode, an object is edible iff `bulk <= ratio * D and longest <= longestRatio * D` (ratio 0.5, longestRatio 1.5).
  - In size mode, keep `size <= absorbRatio * D` exactly.

  Test with fixed values in `tests/unit/Absorb.test.luau`, including a violin (3 × 1.1 × 0.4) that is edible at D 2.2 and a lamp post that is not at D 3.
- [X] T004 [P] [US2] Add the pure rule `growByBulk(D, bulk, k, garnish)` in `src/shared/Rules/Growth.luau`. D³ grows by `k` × bulk³, and when `bulk < garnish * D` it returns `D` unchanged. With garnish 0 the result matches today's growth. Test in `tests/unit/Growth.test.luau`.
- [X] T005 [P] [US2] Add `speedCap(D, rule)` in `src/shared/Rules/Movement.luau`: 32 up to D 12, then `32 + 0.4 × (D − 12)`, at most 56. Test in `tests/unit/Movement.test.luau` at D 1, 12, 20, 30 and at the 56 cap.
- [X] T006 [US2] In `src/shared/Worlds.luau`, resolve `WorldDef.rules` into `Worlds.rules`. Each field falls back to its `Config` value (`startDiameter`, `absorbRatio`, `growthK`, the speed cap, `cameraMinDistance`). Downtown and Snow Village have no `rules` table and keep today's numbers. When `Flags.ReadableRules` is on, Downtown's `readableRules` table (T009) is used instead.
- [X] T007 [US2] Switch every gameplay read of those `Config` values to `Worlds.rules` (research R3). Depends on T006. No existing test file is edited; an edit that the change forces is a defect (plan.md "What must keep passing unchanged"). The reads are in:
  - `src/server/BallService.luau` (3 sites);
  - `src/server/WorldSpawner.luau` (2);
  - `src/server/KnockOff.luau` (1);
  - `src/server/AbsorbService.luau` (2);
  - `src/server/BoosterService.luau` (magnet);
  - `src/client/BallController.luau` (3);
  - `src/client/CameraController.luau` (2);
  - `src/server/RunManager.luau` (final diameter).
- [X] T008 [US2] Add the optional fields `dims = {l, w, h}`, `bulk`, `solid` and `light` to `ObjectDef` (find its declaration with `grep -rn "ObjectDef" src/`), as data-model.md describes.
  - A def without `dims` is a cube of `size`.
  - `src/shared/ObjectVisual.luau` sizes the stand-in to `dims` when present.
  - Pooled Parts carry `Bulk` and `Longest` attributes next to `Size`.
- [X] T009 [US2] In `src/shared/Content/Worlds/Downtown.luau`, add the `readableRules` table, read only when `Flags.ReadableRules` is on. It holds:
  - six tiers and stars 20 / 50 / 90;
  - the `rules` table;
  - `dims` for the long thin objects (at most 30 entries, from section 3.2 of `docs/design/09-park-city-level.md`).

  Tiers are recomputed from `needsD`. Add a sixth Tier 6 entry to the triangle budget this table uses. `Config.luau` `meshTriangles` keeps five entries, and `tests/studio/ObjectTemplates.spec.luau` stays unedited.
- [X] T010 [US2] Absorb and growth by the world's rule (FR-010, FR-011):
  - `src/server/AbsorbService.luau` and the client absorb path use `Absorb.canEat` with `Worlds.rules`, in bulk mode for Park City and readable Downtown, and in size mode otherwise.
  - Growth uses `Growth.growByBulk` in bulk mode.
  - An object under garnish (0.08 × D) still pops, plays its sound and adds no size.
- [X] T011 [P] [US2] Pure rule `fit(dims, D)` in `src/shared/Rules/HeapFit.luau` (research R4):
  - the longest side is scaled to at most `0.45 × D`;
  - the long axis lies tangent to the surface, and the thinnest axis points along the normal;
  - the item reaches at most `0.125 × D` above the surface (a 1.25 × D box);
  - the newest large catch may reach `0.25 × D` for `heapNewestGrace`, then eases to the normal fit.

  Test in `tests/unit/HeapFit.test.luau`:
  - the bound holds at D 1, 2, 5, 10, 20, 50 and 100 (SC-004);
  - the scale never exceeds `0.45 × D`;
  - the newest-catch allowance eases out with no jump between frames.
- [X] T012 [US2] In `src/client/StuckVisuals.luau`, `offsetFor`, `createVisual` and `reseat` use `HeapFit` when `Config.Flags.HeapFix or Config.Flags.ParkCity` is on. `maxVisibleStuck` (30) and the tail rule stay. When a big catch arrives, older small stuck objects are buried smoothly with no pop. Depends on T011.
- [X] T013 [US2] Cues, all without text (FR-015 to FR-017):
  - **Bob**: up to `bobCount` edible objects within `bobRadiusDiameters` × D of the local ball bob gently. Too-big objects never move. Reduce motion turns the bob off; find that setting with `grep -rn -i "reduce" src/client`. In `src/client/Feedback.luau`.
  - **New-tier wobble**: that tier's objects within `wobbleRadiusDiameters` × D wobble once together. In `src/client/Feedback.luau`.
  - **Bump**: contact with a too-big object bounces the ball back, with a thud and a short camera nudge, and a cooldown so rubbing does not chatter. In `src/client/BallController.luau` and `src/client/CameraController.luau`.
- [X] T014 [US2] In `src/client/Hud.luau`, show no tier banner, no "next tier" line and no star-target text when Park City or `ReadableRules` is on (FR-016). In `src/client/CameraController.luau`, the closest camera distance comes from `Worlds.rules.cameraMinDistance` (4 studs at D 1).
- [X] T015 [US2] Speed cap (FR-013): `src/client/BallController.luau` uses `Movement.speedCap`. The server ceiling in `src/server/BallService.luau` becomes `max(Config.maxServerBallSpeed, cap(D) × 1.1)`. `BallGuard.verdict` is unchanged. Add a case to `tests/studio/BallService.spec.luau`: the server accepts a speed up to the cap and refuses one above it (🔒, run with T016).
- [X] T016 🔒 [US2] Studio, with `Flags.ReadableRules` on for Downtown:
  - grow to about D 10 and capture the heap outline next to the ball's real size;
  - eat a violin-like object the old rule refused;
  - bump a lamp post;
  - check that the cues show, with no text;
  - run the `BallService` spec from T015.

  Agent-run parts done in T046/T047 (see `playtest.md` rounds 2 and 3); the thud by ear and the camera nudge by eye are owner checks in `docs/release-candidate.md`.

  Record in `specs/012-park-city-map/playtest.md`. **Stage A checkpoint**: the owner can play this build and judge "can I tell what I can eat?". Depends on T003 to T015.

---

## Phase 3: Foundational for the map (blocking prerequisites for US1, US3, US4, US5)

**Purpose**: the generated Park City world.

- [X] T017 Write `scripts/park_city_world.py` (standard library only: `json`, `math`, `pathlib`), per research R1. It reads `docs/design/maps/park-city-layout.json` and writes four generated Luau modules: `src/shared/Content/Worlds/ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau` and `src/shared/Localization/ParkCityStrings.luau`.
  - Each file starts with a "generated, do not edit" line.
  - **ParkCity.luau**:
    - the `rules`, six tiers and stars;
    - 91 blocks, copied with `up`, `turns` and `width`;
    - spawns, the hub at x −760, `golden`;
    - `placeholders` (each layout record unchanged: rails with `kind` rail or pipe, pads, catapults, water);
    - `hazards` and the eleven fixed `shots` (research R6).
  - **ParkCityParts.luau**: the 1,064 Tier 3 to 6 rows with ids `p<n>`. The hoarding pieces have `solid = true`.
  - **ParkCityLight.luau**: one flat number array plus a kind list, stride 5 (kind index, x, y, z, yaw), rounded to 0.01. The 476 hedge pieces have `solid = true`.
  - **Spanish names**: from a table in the script.
  - **`--check`**: exits 1 when a regenerate would change any file.

  Run it and commit the four generated files. Depends on T008.
- [X] T018 Merge `src/shared/Localization/ParkCityStrings.luau` into `src/shared/Localization/Strings.luau`. Keys are `object.park.<id>` in English and Spanish, and must be balanced. `tests/unit/Strings.test.luau` stays green. Add `python3 scripts/park_city_world.py --check` to `scripts/check.sh`. Depends on T017.
- [X] T019 Write `tests/unit/ParkCity.test.luau`. It reads the layout JSON with `serde` and checks:
  - the count per tier equals `summary.objectsByTier`;
  - every JSON object (scene items including the maze, trail and kerb items, landmarks including hoarding pieces) is found at its position within 0.01, with the same kind;
  - the counts of blocks, spawns, rails, pipes, pads, catapults and water areas are equal, and the placeholder ids are equal;
  - every kind's `dims` equals the JSON's;
  - `tier` equals `Tiers.lookup(needsD)`;
  - ids are unique and positions are inside ±500;
  - the six tiers ascend (1 / 2.5 / 6 / 15 / 35 / 80, top 150), with stars 20 / 50 / 90;
  - the eleven shot names and their order are pinned, and every shot position is inside the map.

  `tests/unit/run.luau` picks the file up by name. Depends on T017.

**Checkpoint**: the generated world matches the layout.

---

## Phase 4: User Story 1 - Play the whole Park City map (Priority: P1), Stage B

**Goal**: with `Flags.ParkCity` on, the whole 1,000 × 1,000 map is built at the layout's coordinates. That includes blocks, all Tier 3 to 6 objects, the doorstep and spawn-trail crumbs, and the placeholders. With the flag off, Downtown loads unchanged.

**Independent Test**: turn on the Park City flag and start a run. Use the size tool to tour each ring at its size, and compare with `docs/design/maps/park-city.svg` and the zone maps.

- [X] T020 [US1] In `src/server/WorldBuilder.luau`, build the 91 blocks from `ParkCity` literally:
  - every block is a box from `y[0]` to `y[1]`;
  - a `ramp` is a wedge rising towards its `up` side;
  - a `spiral` is a spiral ramp of `turns` and `width` inside its rect;
  - `tunnel_wall`, `tunnel_roof` and `kerb` are plain boxes;
  - the four `wall` blocks are the invisible boundary.

  Place the hub from the world `hub` data (x −760, z 0).
- [X] T021 [US1] Pool the 1,064 Tier 3 to 6 rows (`ParkCityParts.luau`, ids `p<n>`) through the existing builder in `src/server/WorldBuilder.luau` and `src/server/WorldSpawner.luau`, sized by `dims`. `solid` pieces (hoardings) block smaller balls and are eaten by balls big enough (FR-006).
- [X] T022 [US1] Stage B crumbs: build only the 240 doorstep crumbs (`doorstep_NN` scenes) and the 88 spawn-trail crumbs (`trail_NN`) as pooled Parts in `src/server/WorldSpawner.luau`. No other Tier 1 or 2 object is a Part at any stage. Record the server part count in `playtest.md` (expected about 1,730 with 12 balls, under 2,000).
- [X] T023 [US1] Add `buildPlaceholders` to `src/server/WorldBuilder.luau` (research R5). Everything goes in a `Placeholders` folder, with `Name` = placeholder id and the tag `Placeholder`. No scripts, no touch handlers, and no attributes the game reads.

  | Placeholder | Drawn as |
  | --- | --- |
  | Rails (14) | thin Neon beams with end posts |
  | Drain pipes (4) | a pipe mouth at each end |
  | Pads (40) | flat discs or squares; lily pads are collidable slabs at `y` |
  | Catapults (6) | a base block and an arm at `restYaw` |
  | Water (3 areas) | an opaque slab 0.05 above the ground |
- [X] T024 [US1] Spawns and golden spots, in `src/server/BallService.luau` and `src/server/WorldSpawner.luau`:
  - a new ball starts at `Worlds.rules.startDiameter` (1) on one of the 12 `ParkCity.spawnPoints`, facing the city;
  - pass `ParkCity.golden` (8 spots) to the existing daily golden-object rule (`grep -rn "golden" src/server`).
- [X] T025 [US1] Size tool (`Flags.DebugSize`, Studio only). A small panel, or a Studio chat command, sets the local ball's diameter to 1, 3, 6, 15, 35 or 80, and the server applies it through the normal size path.
  - It is refused outright when the flag is off.
  - It is never shown to players.
  - Add a case to `tests/studio/BallService.spec.luau`: with the flag off, the request does nothing.
- [X] T026 🔒 [US1] Studio, with `Flags.ParkCity` on, start Play. From `execute_luau` on `Server`, compare the built world with the `ParkCity` data: blocks, objects, placeholders and the 12 spawns are present at their layout coordinates. Record the server part count. Depends on T020 to T024.
- [X] T027 🔒 [US1] Route check, ring by ring, at the size each part is built for. Use the size tool, and drive the ball as AGENTS.md "Driving the ball" describes. Confirm that no static geometry blocks a designed route (spec US1 scenario 4). Each check is one line in `playtest.md`. Depends on T025 and T026.
  - D 1: doorstep → Park Loop.
  - D 2: into the root hollow. At D 4 the ball is stopped at the mouth and not wedged.
  - D 3: the oak's spiral ramp to the deck.
  - D 5: the maze corridors. At D 6 the hedges are eaten.
  - D 8: the Roof Run, by the delivery ramp and the gaps with tap jumps (the brave gap is skipped until 013 adds boost pads).
  - D 12: the car park, by the open ramp to the top deck.
  - D 17: the Downtown hoardings are eaten.
  - D 25: Spoke → Plaza.

**Checkpoint (Stage B)**: Park City loads, every ring can be toured at its size, and Downtown is unchanged with the flag off.

---

## Phase 5: User Story 3 - Twelve players on the full map (Priority: P2), Stage C

**Goal**: the 3,458 Tier 1 and 2 objects, including the hedge pieces, become light objects (server data, not Parts). The server validates every absorb against that data. Each client draws only what is near it. Twelve balls hold 30 fps on every unthrottled second.

**Independent Test**: start Park City with 12 balls (the heavy-scene benchmark with bots). Read the server part count and the per-second frame rate. Absorb a light object from too far away and confirm the server refuses it.

- [X] T028 [P] [US3] Pure module `src/shared/Rules/Light.luau`.
  - A grid of `lightCellSize` studs over the light rows, built once, and a nearby query.
  - `verdict(...)` checks existence, taken state, the distance from the ball to the **data** position (`radius + size/2 + absorbDistanceTolerance`) and `Absorb.canEat`. The rate limit is checked by the caller.

  Test in `tests/unit/Light.test.luau`:
  - a far claim, a taken object and a too-big object are refused;
  - an in-range edible object is accepted;
  - the grid query returns the objects within 120 studs;
  - an id matches `^L%d+$` with an index in range.
- [X] T029 [US3] Light state in `src/server/WorldSpawner.luau`:
  - arrays by light index: `lightState` (0 or 1, all 0 at the start), `lightTakenAt` and `lightRespawnAt`;
  - a `pendingLight` set, so the tick walks only the taken indices;
  - an outbox `{ taken, restored }`, flushed every `lightDeltaSeconds`.

  Respawn uses `Respawn.canRespawn`, the same delays and the same starvation ceiling as parts. The Stage B doorstep and trail Parts from T022 move to light state here.
- [X] T030 [US3] In `src/server/AbsorbService.luau`, route `L<n>` ids by prefix in `tryAbsorb` and `tryBump`. They are checked as parts are today:
  - the run accepts pickups;
  - the id is a string matching `^L%d+$` with an index in range (otherwise `UnknownObject`);
  - the rate limit holds;
  - the object is not taken;
  - the distance is measured to the data position.

  The client sends only the id string. Depends on T028 and T029.
- [X] T031 [US3] The `LightDelta` RemoteEvent, server to client only, in `src/server/Remotes.luau`: `FireClient(player, taken: {number}, restored: {number}, isSnapshot: boolean)`, carrying indices only.
  - A snapshot is sent at join and at run start.
  - The client receives it in `src/client/RunClient.luau` or `src/client/Main.client.luau`: a snapshot resets the taken set, and a delta applies the two lists.
  - A taken light object disappears for every player (FR-019).
- [X] T032 [US3] `src/client/LightField.luau` (new). It builds the grid once from `ParkCityLight` through `Rules/Light`, and refreshes every `lightRefreshSeconds` or after `lightRefreshStuds` of movement.
  - It draws the nearest objects within `lightDrawRadius` into a pool of at most `lightPoolCap` Parts.
  - It drops objects culled by `Tiers.isCulled(objectTier, playerTier, Config.cullTierDelta)` and objects marked taken.
  - Pool Parts carry `Size`, `Bulk`, `Longest`, `Tier`, `Taken`, the tag `WorldObject` and `Name` = light id.
  - Solid hedge pieces stay collidable until the ball can eat them.
- [X] T033 [US3] Client integration. Depends on T032.
  - `src/client/BallController.luau`: the contact scan and `updateCollisions` pick up `LightField` parts through the `WorldObject` tag, with no new path.
  - `src/client/StuckVisuals.luau`: for `L` ids, the kind comes from `Worlds.lightKind(id)`, through the same template path. The `Stuck` string shape does not change.
  - `src/client/WorldCuller.luau`: light objects follow the tier cull. `tests/studio/WorldCuller.spec.luau` stays unedited and green on Downtown.
- [X] T034 🔒 [US3] Jest specs.
  - `tests/studio/AbsorbService.spec.luau`, light ids: a far claim, a taken object and a too-big object are refused; the rate limit holds; an out-of-range `L<n>` returns `UnknownObject`.
  - `tests/studio/WorldSpawner.spec.luau`, light state: a take sets the state and the outbox; respawn follows the sight rule after its delay; the starvation ceiling applies.

  Depends on T029 and T030.
- [X] T035 🔒 [US3] Studio, with `Flags.ParkCity` on and bots running:
  - the server part count is under 2,000 with 12 balls, with zero `WorldObject` parts of `Tier` ≤ 2 on the server;
  - the client `LightField` pool is above 0 and at most 450;
  - a light object taken by one client disappears on a second client;
  - `Absorb:FireServer("L1")` sent from far away is refused.

  Record in `playtest.md`. Depends on T029 to T033.
- [X] T036 🔒 [US3] The 12-ball heavy-scene benchmark (G6), with `tests/studio/HeavyScene.server.luau` (Park City) and `tests/studio/HeavySampler.client.luau`.
  - Sample 60 s, one fps value per second.
  - List the throttled seconds (exactly 15 fps) apart.
  - Record the viewport size.
  - Every unthrottled second must be at or above 30 fps. If there are no unthrottled seconds, ask the owner once to keep Studio in front and rerun (AGENTS.md).

  Write the `HeavySceneReport` attribute and `playtest.md`. Depends on T035.

**Checkpoint (Stage C)**: Park City at full density with 12 balls. A ball can grow through the whole map without the size tool.

---

## Phase 6: User Story 4 - Pace measured and reported, not gated (Priority: P2)

**Goal**: a pace report for 12 spawns and 3 profiles, written into the spec folder, and the three playability floors. Nothing fails on pace values.

**Independent Test**: run the pace report, read the per-spawn table, and confirm that the floors pass.

- [X] T037 [US4] The pace model in a helper under `tests/unit/`.
  - **Reuse** the obstacle-aware greedy eater of `tests/unit/Pace.test.luau` (extract it into a shared helper only if both tests need it), and do not write a new path-finder.
  - Feed it Park City's generated world data and rules.
  - Map the profiles of `scripts/growth-sim.py` (weak, median, skilled) onto it, and document the mapping in the file header.
  - Deterministic.
- [X] T038 [US4] `tests/unit/ParkPace.test.luau`. Depends on T037.
  - **Report**: it writes `specs/012-park-city-map/pace-report.md`. For each of the 12 spawns and each profile: the size at 0:30, 1:00, … 4:00 and the time of each tier. Spawns more than 15 % behind the median are marked. The report passes whatever the numbers are (FR-022), and a second run leaves no diff.
  - **Floors** (these fail the build, constitution 4.1.0):
    - every spawn reaches an edible crumb within 3 s at D 1 (G4);
    - every spawn has its 20 doorstep light objects within 15 studs, all with `bulk <= 0.5` and `longest <= 1.5`;
    - the open-route ladder has no gap, from D 1 to the size that eats the Downtown hoardings, on routes with no rails, pipes, pads or catapults (G5).

    The coverage floor is checked by the layout script (T002).

**Checkpoint**: the pace report exists, and the floors pass.

---

## Phase 7: User Story 5 - Images for the owner (Priority: P2)

**Goal**: fixed shots from the camera positions in the generated data. The owner's approval holds the merge (gate 6).

- [X] T039 [US5] Extend `scripts/capture-export.luau` with `--world parkcity`. It resolves `ParkCity` and writes blocks, parts, light rows, placeholders and shots to `art/render/world-parkcity.json`. If the draw rules for light rows and placeholders need more than about 60 lines, write `scripts/park-capture-export.luau` instead (boxes by `dims`). Research R6.
- [X] T040 [US5] Render the eleven shots (generated by T017, pinned by T019) with `art/scripts/capture_render.py` into `specs/012-park-city-map/shots/`, one PNG per shot, named as in the shot list. Depends on T039.
- [X] T041 🔒 [US5] Only if the offline route (T040) fails twice: ask the owner once to keep Studio in front, then take the same shots with Studio `screen_capture` as a second opinion. Otherwise skip. Depends on T040.

---

## Final Phase: Polish and cross-cutting concerns

- [X] T042 🔒 Studio playtest (G7). With Park City on: `start_stop_play`, play a short route as a bot (`BotRun`), then `get_console_output`.
  - Expect no new errors or warnings from game scripts.
  - A `ContentId rbxassetid://… failed` line is checked by grepping the repo for the id.

  Record in `playtest.md`. This runs before any pull request is opened, and a Rojo wait that runs out here does not count against the two-failure rule.
- [X] T043 Regression and checks:
  - run `scripts/check.sh` end to end (including the layout and world `--check` steps) and fix any failure;
  - with every new flag off, the tests listed in plan.md "What must keep passing unchanged" pass unedited, including `Pace.test.luau` and the Jest specs (🔒 part with T042);
  - run the `quickstart.md` checks not already covered.

  Record the results in `playtest.md`.
- [X] T044 Update `docs/release-candidate.md` with the owner-only items:
  - phone frame rate;
  - `growthK` and star tuning;
  - the pace sign-off, including the design document's section 5.3 marks, which are a report here;
  - the Spanish object names;
  - the knock-off difference (a knocked-off light object is not scattered);
  - publish-checklist lines: `Flags.DebugSize` must be off, and `ServerScriptService.LoadStringEnabled` must be off in anything published.
- [ ] T045 Gate 6 is open until the owner records approval in `specs/012-park-city-map/playtest.md`. Do not merge before then. A pull request is opened only when requested, and the shots and `playtest.md` are what the reviewer reads.

---

## Dependencies and execution order

- **Setup (Phase 1)**: none.
- **US2 / Stage A (Phase 2)**: depends on Setup only. It needs no generated world, so it ships first, and the owner can play it.
- **Foundational for the map (Phase 3)**: depends on T008 (object fields). It can run in parallel with the rest of Phase 2.
- **US1 / Stage B (Phase 4)**: depends on Phase 3, and on T006 and T007 (world rules).
- **US3 / Stage C (Phase 5)**: depends on US1 (it moves the Stage B crumbs to light state) and on T003 (`canEat`).
- **US4 (Phase 6)**: depends on Phase 3 and on US3's light data for the doorstep floor.
- **US5 (Phase 7)**: depends on T017 (shot data) and the built world.
- **Polish**: depends on all stories.

## Parallel opportunities

- Phase 1: T001 and T002.
- Phase 2: T003, T004, T005 and T011 together.
- Phase 3 (T017 to T019) alongside the rest of Phase 2, once T008 is done.
- Phase 5: T028 alongside T029.
- Phase 6 (T037) and Phase 7 (T039) once the world exists.

## Implementation strategy

1. Setup, then Stage A (Phase 2). Stop: the owner plays Downtown with the new rules.
2. Phase 3, then Stage B (Phase 4). Stop: the owner tours Park City with the size tool.
3. Stage C (Phase 5). Stop: the owner plays a full run on Park City with 12 balls.
4. Stage D (Phases 6, 7 and Polish), then gate 6.

## Notes

- **Claim for Studio work (constitution X)**: the agent running a 🔒 task owns Studio until it finishes. Record the claim in `playtest.md`.
- **Pace**: the spec (FR-022, US4) makes pace a report, never a gate. The design document's section 5.3 marks are not gated here.
- **Size tool**: `Flags.DebugSize` is for Studio only and is on the publish checklist (T044).
- **Merged from the first draft (70 tasks → 45)**: old T001+T002, T027+T028, T029+T030, T031+T032, T034–T036, T037+T038, T039+T041, T011–T013, T015+T021+T062, T016+T017, T022+T023, T042+T043, T046+T049, T050+T051+T054, T052+T053, T057–T060, and T024+T061+T067+T068. Old T003 and T004 were done in the layout script. Nothing was dropped.

## Implementation notes (round 1)

- T018: the Park City strings are merged in `Localizer.luau`, not `Strings.luau` (Lune loads `Strings.luau` and cannot
  use `script`). `ParkCity.test` checks the generated names.
- T019: tiers are by bulk (the layout's rule, inclusive at the top), so the test checks `Tiers.lookup(2 * bulk - 1e-6)`;
  a longest side only changes what is edible.
- T017: the eleven shots are the four quarters, Duck Island, the Hedge Maze, the Roof Run, the Car Park, the Plaza, the
  Giant Oak and the overview. The layout script gained `turns` and `width` on the Sky Rail spiral, and two doorstep
  objects (bird_seed_bag, tennis_ball) were made edible at D 1 (a floor in `ParkPace.test`).
- T024: golden spots are `GoldenSpot` markers (no daily rule exists in the code yet); spawn facing sets the camera.
- T034: the light specs are separate files (`AbsorbServiceLight.spec`, `WorldSpawnerLight.spec`) because the existing
  specs build fixtures from Downtown.
- T036: `ParkHeavyScene.server.luau` and `ParkHeavySampler.client.luau` are new Park City versions of the benchmark.
- T039: `scripts/park-capture-export.luau` and `art/scripts/park_capture_render.py` (the research R6 fallback).
- T041: not needed, the offline route worked.
- Open: T016 and T047 (bob/wobble cues and bump thud by eye), T048 (oak deck moved to the ramp end 2026-11-06 and probed with a D 3 sphere; driving the ball is left to the owner), T045 (gate 6: the pull request is opened to show the shots; do not merge before the owner approves).


---

## Phase 8: Convergence

- [X] T046 [US2] Fix the Downtown doorstep so a D 1 ball can roll out of its spawn with `Flags.ReadableRules` on (the Tier 2 doorstep objects of size 1.0 to 1.2 box it in; `playtest.md` Stage A finding). Edit `readableRules` in `src/shared/Content/Worlds/Downtown.luau` (or the doorstep data it reads) without touching the flags-off numbers or any existing test file, and add a Lune check in `tests/unit/Downtown.test.luau` that every spawn has an open way out at D 1 per US2 (Stage A playable) and T009 (partial)
- [X] T047 🔒 [US2] Re-run the open parts of T016 on Downtown with `Flags.ReadableRules` on, after T046: grow to about D 10, eat a violin-like long thin object the old rule refused, bump a lamp post (thud, nudge, bounce, cooldown), check the bob and new-tier wobble cues and that no text banner shows, then switch the flag back off and record each line in `playtest.md` per FR-010, FR-015, FR-016, FR-017 and T016 (partial)
- [ ] T048 🔒 [US1] Run the route checks left out of T027 by Spherecast or by driving the ball, and record one line each in `playtest.md`: D 1 doorstep to Park Loop, D 2 into the root hollow and D 4 stopped at the mouth (FR-007), D 3 the oak spiral ramp to the deck, D 12 the car park open ramp to the top deck, D 17 the Downtown hoardings eaten, D 25 Spoke to Plaza, per US1 scenario 4 and T027 (partial)
