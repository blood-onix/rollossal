# Feature Specification: Snow Village Launch World (60+ Objects across Tiers 1–5, Blender Pipeline, World Layout, Pooled Respawning & Audio)

**Feature Branch**: `004-snow-village`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Replace the grey-box room with the launch world, Snow Village: about 60 object types across tiers 1–4, made in Blender with one shared palette, laid out as a winter town that reads at every scale, with pooled respawning objects, winter lighting and audio. Design brief: README.md §3.2 (respawning), §3.3 (tiers), §5 (art and audio), §9 (performance). Constitution: I, VI, VII, X, XI. Depends on 001 and 002 (tier tables)."

## Clarifications

### Session 2026-10-26

- Q: How should the Blender 3D asset pipeline be configured for Snow Village? → A: Approve adding pinned `blender-mcp` to `.vscode/mcp.json` and `opencode.json` (plus headless Blender CLI scripts `blender --background --python` for deterministic batch export and triangle-budget checks).
- Q: Should Tier 5 landmark objects be absorbable at launch, or should Snow Village ship Tiers 1–4 only and lower the 3-star target? → A: Include Tier 5 objects (houses, clock tower, skating rink) as absorbable at launch and keep `20 / 45 / 80` stud star thresholds.
- Q: What playable town footprint should Snow Village use for Tiers 1–4? → A: `600 x 600` studs playable Tiers 1–4 town (`halfExtent = 300`) with an `800 x 800` stud Tier 5 backdrop ring (`outerHalfExtent = 400`).

## Owner Approval Gate *(Constitution Principles I, XI, XII & Human Approval Required)*

- **Approved New Tool (`blender-mcp`, 2026-10-26)**: The owner has approved adding the Blender MCP server (`blender-mcp`, pinned version in `.vscode/mcp.json` and `opencode.json`) alongside headless Blender Python CLI scripts (`blender --background --python`) to author `.blend` sources in `art/source/` and `.fbx` exports in `art/export/`. Only one agent at a time may drive Blender and one may drive Roblox Studio, each claimed on its task in `tasks.md` (Constitution Principle X).
- **Approved Tier 5 Absorbability & Run Star Targets (2026-10-26)**: Snow Village includes all 5 tiers from `docs/rollossal-gdd.md` §3.3 as absorbable tiers: `60` object types across Tiers 1–4 (`18 / 16 / 14 / 12`) plus `4` Tier 5 landmark object types (cottage house, two-storey town house, skating rink, clock tower; sizes `25–60` studs, absorbable once ball diameter reaches `70+` studs), keeping `starThresholds = { 20, 45, 80 }` studs and enabling the Feature 008 "ball ate the clock tower" moment.
- **Approved Town Footprint (2026-10-26)**: `600 x 600` studs (`halfExtent = 300`) playable Tiers 1–4 winter town surrounded by an `800 x 800` stud (`outerHalfExtent = 400`) Tier 5 landmark ring, with the Snow Village Hub positioned outside the town perimeter.
- **Playtest Timing Gate (2026-10-26)**: The owner's grey-box sign-off from Features 001–003 satisfies the prerequisite to start Feature 004. Per Constitution Principle I (v1.1.0), the playtest with outside people (at least 3 adults and 3 children aged 10–12) is deferred to **Feature 004d**, after the world art (this feature), the mechanics pass (**004b**), and the juice pass (**004c**) are in place. Within this feature, the Snow Village layout and pooled spawner MUST first pass a grey-box check with placeholder meshes (agent Studio run + owner playing, recorded in `specs/004-snow-village/playtest.md`) before final Blender meshes are swapped in.

- **Deferred Balance and Phone Check (Confirmed Owner Decision, 2026-10-28)**: The owner is replacing the Snow Village map with a new one in the upcoming design-system spec (`docs/design/`: new models, skins, maps). This feature ships with two success criteria recorded as **known limits, not met and not waived**, to be re-measured on the new map: (1) **SC-003** balance (`growthK`, Tier 3/Tier 4 placement counts, part budget or pool shape). The latest 12-bot run has Tier 2 at 0.08 at 60 s and Tier 4 at 0.05 at 240 s against the 20% floor, and placement alone cannot fix it inside the 2,000-part budget. (2) **SC-004 (b)**, the Tier-4 half of the owner phone check. Tier 4 is hard to reach by hand on this map, so the Pixel 7 Pro check (avg 59 fps, lowest 22 fps) never reached Tier 4 and has no Tier-4 window or share. SC-004 (a), the server part budget (1,702 of 2,000 parts), is met. This resolves the open path question for SC-003 as option (a): merge with the deferral recorded here and in `playtest.md`.
- **Tier 5 Absorb Spread (Confirmed Owner Decision, 2026-10-28)**: The four Tier 5 landmarks keep sizes `28 / 34 / 40 / 48` studs, so they become absorbable at ball diameters `70 / 85 / 100 / 120`. The first is absorbable at the `70+` entry point above and the rest are staggered on purpose to give the 80-stud star target something to chase. Making all four absorbable at `70` would mean redoing the meshes, so it is left to the new map.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rolling Through a Nested-Scale Winter Town That Never Runs Dry (Priority: P1)

Up to 12 players spawn into **Snow Village**, a winter town spanning `600 x 600` studs for Tiers 1–4 (`halfExtent = 300`) with an `800 x 800` stud outer Tier 5 landmark ring (`outerHalfExtent = 400`), designed as nested scales so each size tier has its own readable playground:
- **Tier 1 — Crumbs (`2–5` studs ball diameter)**: Tabletop, porch, and gift-pile micro-zones right beside each of the 12 player spawn points, each with a reserved cluster of ~10 tiny objects (`0.3–1.5` studs: sweets, buttons, pine cones, ornaments) reachable within 3 seconds of spawning so a new player rolls up their first object within 5 seconds and reaches Tier 2 within 60 seconds.
- **Tier 2 — Toys (`5–12` studs)**: Front yards and toy-strewn gardens surrounding the spawn porches (`1.5–4.0` studs: teddies, gift boxes, snowballs, cats).
- **Tier 3 — Yard (`12–30` studs)**: Side streets, village lanes, and park paths lined with benches, snowmen, sledges, fences, and dogs (`4.0–10.0` studs).
- **Tier 4 — Street (`30–70` studs)**: The main street and town square populated with cars, Christmas trees, kiosks, and buses (`10.0–25.0` studs).
- **Tier 5 — Town (`70–150` studs)**: Houses, the skating rink, and the clock tower framing the town square and outer `800 x 800` stud ring (`25.0–60.0` studs), acting as landmarks throughout the run and becoming absorbable once a ball reaches Tier 5 (`diameter >= 70` studs) to chase the 80-stud 3-star target.

As players absorb objects across a 4-minute (`240` s) run, absorbed objects are pooled and reused rather than destroyed, respawning after `60–120` seconds only when their spawn point is out of sight of nearby players. The town includes kerbs, steps, ramps, rooftops, and raised plazas (preparing routes for the 004b jump) plus tagged marker spots reserved for 004b boosters and traps, and a dedicated Snow Village Hub area where **Back to hub** lands.

**Why this priority**: Delivering the launch world layout, scale progression, and pooled out-of-sight respawning is the core gameplay foundation of Feature 004 (`docs/rollossal-gdd.md` §3.2, §3.3, §5, §9) and enforces Constitution Principles I (Grey-Box First layout check), II (Server Authority), and VI (Mobile First 5-second first pickup, 60-second first tier, and 30 fps performance).

**Independent Test**: Can be tested first with placeholder meshes (grey-box layout gate) and then with final Blender meshes in an agent-driven Studio local server with 12 simulated balls over a full 240-second run, verifying that balls reach Tier 4 (and strong runs can reach Tier 5 / 80 studs) without the world running dry, absorbed objects respawn only after `60–120` seconds when out of sight of nearby players, no new console warnings/errors occur, and the owner signs off in `playtest.md`.

**Acceptance Scenarios**:

1. **Given** a new player spawns at any of the 12 Snow Village spawn points at diameter `2` studs, **When** they steer forward from spawn, **Then** a cluster of at least `10` Tier 1 objects (`size <= 0.8` studs) lies within `3` seconds of rolling distance so the first pickup occurs within `5` seconds and Tier 2 (`diameter >= 5` studs) is reached within `60` seconds.
2. **Given** 12 concurrent balls rolling and absorbing objects in Snow Village during a full `240`-second run, **When** players progress from Tier 1 porches through Tier 2 yards, Tier 3 side streets, and Tier 4 main street/square, **Then** balls reach Tier 4 (`diameter >= 30` studs) and every tier zone maintains available absorbable objects without running dry.
3. **Given** an object is absorbed at time $t_0$, **When** the server spawner steps before $t_0 + \text{respawnDelay}$ (`60–120` s) OR while any player's ball/camera is within the out-of-sight visibility cone/radius of that object's spawn point, **Then** the pooled object remains hidden and unabsorbable; once $t \ge t_0 + \text{respawnDelay}$ AND no nearby player has line-of-sight / proximity to the spawn point, the pooled instance is restored to its spawn CFrame and marked `Available` without allocating a new `Instance`.
4. **Given** a player finishes a run and taps **Back to hub**, **When** the server moves the player to the Hub zone, **Then** the player lands in the Snow Village Hub area (built from the MVP hub asset outside the active rolling town) and can start a new run at any time.

---

### User Story 2 - Data-Driven Snow Village Content Model (64 Objects across Tiers 1–5) Ready for Zero-Code Reskins (Priority: P1)

All Snow Village world metadata lives in `src/shared/Content/Worlds/SnowVillage.luau` (and is selected via `src/shared/Worlds.luau`), defining the 5-tier table from `docs/rollossal-gdd.md` §3.3, `60` object types across Tiers 1–4 (`18 / 16 / 14 / 12`) plus `4` Tier 5 landmark object types (`64` total), object coin values scaling by tier, unique `id` and `bookId` identifiers, localization keys in `src/shared/Localization/Strings.luau`, and asset keys resolved exclusively through `src/shared/Assets.luau`. Server and client systems (`WorldSpawner`, `AbsorbService`, `RunManager`, `StuckVisuals`, `BallController`, `Hud`, `BookUi`, `ResultsUi`) consume world data generically so that a future world reskin (Candy Town in Feature 011) requires only content data and asset table entries—zero code changes.

**Why this priority**: Enforces Constitution Principle VII (Content Is Data: a reskin that needs a code change is a defect in the content model) and Principle IX (Localised Strings).

**Independent Test**: Can be verified by running `scripts/check.sh` and Lune unit tests (`tests/unit/SnowVillage.test.luau`) asserting uniqueness of `id` and `bookId`, tier range validity, absorbability within each tier (`size <= 0.4 * tierMaxDiameter`), `Assets.luau` key resolution, `Strings.luau` key completeness (`en` and `es`), and verifying that switching `Worlds.active` requires no code changes in server or client modules.

**Acceptance Scenarios**:

1. **Given** `src/shared/Content/Worlds/SnowVillage.luau`, **When** Lune content validation tests run, **Then** `60` distinct object types exist across Tiers 1–4 (`18` in Tier 1, `16` in Tier 2, `14` in Tier 3, `12` in Tier 4) plus `4` Tier 5 landmark object types (`64` total), every object has a unique `id` and unique `bookId`, positive integer `coins` that scale with `tier`, `size` within its tier's object-size range, and `size <= 0.4 * tierMaxDiameter` so every object is absorbable at some diameter within its own tier.
2. **Given** every object, tier, hub asset, and sound referenced by Snow Village content, **When** Lune validation inspects `src/shared/Assets.luau` and `src/shared/Localization/Strings.luau`, **Then** every `assetKey` resolves to a valid entry in `Assets.luau` (and no asset IDs are hard-coded anywhere else), and every `nameKey`, `headlineKey`, and `reward.nameKey` resolves to non-empty English (`en`) and Spanish (`es`) strings.
3. **Given** `WorldSpawner`, `AbsorbService`, `StuckVisuals`, and `BallController`, **When** inspected or tested with an alternate world definition table conforming to the shared `WorldDef` schema, **Then** no module references `GreyBoxRoom` directly or assumes a single object per tier (`objectById[objectId]` is used instead of `objectByTier[tier]`).

---

### User Story 3 - Low-Poly Blender Asset Pipeline, Shared Palette, Winter Lighting & Audio (Priority: P2)

Every Snow Village 3D model (`64` object types across Tiers 1–5 and `1` hub asset) is authored in Blender as a low-poly, flat-shaded, slightly oversized cartoon toy-diorama mesh sharing one palette texture, stored under `art/source/*.blend`, exported to `art/export/*.fbx`, checked against the per-tier triangle budgets in `src/shared/Config.luau` (`<= 300` tris for Tiers 1–2, `<= 800` for Tier 3, `<= 2,500` for Tiers 4–5), uploaded to Roblox, and recorded in `src/shared/Assets.luau`. Objects of the same type reuse one template `MeshPart` so memory stays low. Client-side culling hides world objects far below the local player's current tier (`object.tier <= playerTier - Config.cullTierDelta`), `Workspace.StreamingEnabled` is enabled, soft winter lighting and fog frame the town, and final audio (tier-pitched pickup pop, tier unlock fanfare, knock-off bump, end bell, and gentle looping winter background music) plays with full visual equivalents.

**Why this priority**: Fulfils `docs/rollossal-gdd.md` §5 and §9 and Constitution Principles VI (Mobile First 30 fps and performance budgets), X (Multi-Agent Discipline for Blender and Studio MCP claims), and XI (Asset Pipeline).

**Independent Test**: Can be tested via an automated triangle-budget and asset-table check script invoked by `scripts/check.sh`, a Jest-Lua Studio test for client sub-tier culling and spawner pooling, and a Studio MCP playtest with 12 simulated balls at Tier 4 plus an owner check on a real phone verifying `>= 30 fps`, active server part count within `Config.Budgets.maxActivePartsPerServer`, winter lighting/fog, and preloaded audio playback.

**Acceptance Scenarios**:

1. **Given** all exported meshes in `art/export/*.fbx` (or mesh metadata inspected by `scripts/check.sh`), **When** the triangle-budget check runs, **Then** every Tier 1–2 mesh has `<= 300` triangles, every Tier 3 mesh has `<= 800` triangles, every Tier 4–5 mesh has `<= 2,500` triangles, and every uploaded asset ID is recorded in `src/shared/Assets.luau`.
2. **Given** a player's ball grows into a higher tier (e.g., Tier 3, Tier 4, or Tier 5), **When** the client culling controller evaluates world objects whose tier is at least `Config.cullTierDelta` (`2`) tiers below the local player's current tier, **Then** those tiny objects are hidden locally (`LocalTransparencyModifier = 1`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`) for that player only without affecting other players in the server.
3. **Given** a 12-ball local server playtest reaching Tier 4 in Studio and a single-player run on the owner's reference phone, **When** frame rate and part count are measured, **Then** frame rate holds at least `30 fps`, active world parts stay within `Config.Budgets.maxActivePartsPerServer`, and both measurements are recorded in `specs/004-snow-village/playtest.md`.
4. **Given** a player joins Snow Village and plays a run, **When** background music, pickups, tier unlocks, bumps, and the run-end bell occur, **Then** the looping winter music track plays through the `Music` `SoundGroup` (respecting `settings.musicVolume`), effects play through the `Effects` `SoundGroup` with pickup pitch rising by tier (`1 + Config.pickupPitchStep * (tier - 1)`), and every audio cue has its visual equivalent on screen.

---

### Edge Cases

- **Out-of-Sight Respawn Blocking**: If an absorbed object's random respawn timer (`60–120` s) has elapsed, but a player's ball or camera is within `Config.respawnOutOfSightRadius` (`45` studs) or looking toward the spawn point within `Config.respawnViewDistance` (`120` studs), the object MUST wait and re-check on subsequent spawner ticks until no nearby player has it in sight, with a `Config.respawnForceAfterSeconds` (`180` s) starvation ceiling so a stationary player cannot permanently block respawns.
- **Spawn Cluster Availability at Run Start**: Each of the 12 player spawn points has a reserved cluster of ~10 Tier 1 objects within 3 seconds of rolling. When a player starts or restarts a run (**Roll again**) at a chosen spawn slot, the spawner selects the spawn slot with the healthiest available Tier 1 cluster and, if needed, immediately refreshes out-of-sight or personal-cluster Tier 1 objects at that slot so the 5-second first-pickup guarantee always holds.
- **Pooled Instance Reuse on Knock-Off Scatter & Respawn**: When a high-speed bump knocks off up to 3 recent objects, only pooled instances still held by that pickup entry scatter onto the ground near the ball (clamped to valid ground height via raycast or placement elevation rather than hardcoded `Y = 0`), and when a taken object respawns, the existing pooled `MeshPart`/`BasePart` is repositioned to its original `spawnCFrame`—never `Destroy()`ed and re-instantiated.
- **Client Sub-Tier Culling vs. Knock-Off Shrink**: If a player at Tier 4 (`diameter >= 30` studs) has Tier 1–2 objects hidden locally by client culling, and a knock-off shrinks the player back into Tier 3 (`diameter < 30` studs), the client culling controller MUST immediately restore visibility of Tier 2 objects so the player can see and absorb them again.
- **Uneven Terrain / Elevation Grounding (`Y > 0`)**: Unlike the flat `Y = 0` grey-box floor, Snow Village has kerbs, steps, ramps, porches, and rooftops at varying `Y` elevations. `WorldSpawner.getSpawnSlot`, `WorldSpawner.scatter`, and `BallController` ground checks MUST use full 3D `CFrame` / `Vector3` positions (with `Y` elevation from placement data or ground raycast) rather than assuming `Y = 0`.
- **Multiple Object Types Per Tier in `AbsorbService` & `StuckVisuals`**: In `GreyBoxRoom`, `Worlds.objectByTier[cube.tier]` worked only because each tier had 1 cube type. In Snow Village, each tier has multiple object types of varying sizes and meshes; `AbsorbService` MUST resolve the absorbed object's `ObjectDef` by its specific `objectId` (`Worlds.objectById[spawned.objectId]`), and `StuckVisuals` MUST clone the shared template `MeshPart` (or visual representation) for that `objectId` rather than creating a grey cube.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Content Model & Data Validation (`src/shared/Content/Worlds/SnowVillage.luau`, `src/shared/Worlds.luau`)

- **FR-001**: `src/shared/Content/Worlds/SnowVillage.luau` MUST define the Snow Village world data module with `worldId = "snow_village"`, `starThresholds = { 20, 45, 80 }`, pure data tables (zero Roblox API calls so Lune can require it directly), and a shared `WorldDef` schema supporting:
  - `sizeTiers`: 5 ordered tier definitions matching `docs/rollossal-gdd.md` §3.3:
    - Tier 1 (`Crumbs`): ball diameter `2–5` studs, object sizes `0.3–1.5` studs;
    - Tier 2 (`Toys`): ball diameter `5–12` studs, object sizes `1.5–4.0` studs;
    - Tier 3 (`Yard`): ball diameter `12–30` studs, object sizes `4.0–10.0` studs;
    - Tier 4 (`Street`): ball diameter `30–70` studs, object sizes `10.0–25.0` studs;
    - Tier 5 (`Town`): ball diameter `70–150` studs (`maxDiameter = nil`, absorbable cap `150` studs), object sizes `25.0–60.0` studs;
  - `objects`: `64` absorbable object types across Tiers 1–5 (`18` Tier 1, `16` Tier 2, `14` Tier 3, `12` Tier 4 = `60` across Tiers 1–4, plus `4` Tier 5 landmark objects: cottage house, town house, skating rink, clock tower), each with `id: string`, `tier: number`, `size: number` (longest dimension in studs), `coins: number` (positive integer scaling with tier: Tier 1 = `1–2`, Tier 2 = `3–5`, Tier 3 = `8–15`, Tier 4 = `20–40`, Tier 5 = `60–100`), `bookId: string`, `nameKey: string`, `icon: string`, and `assetKey: string` (resolving through `src/shared/Assets.luau`);
  - `placements`: data-driven object spawn records (or `CollectionService` marker definitions) specifying `id`, `objectId`, `position` (`x, y, z`), `yaw`, and optional `spawnSlotCluster` tag (`1..12` for the ~10 tiny objects reserved near each spawn point);
  - `environment`: data-driven static town geometry/zones (nested scale zones, kerbs, steps, ramps, rooftops, raised areas, and tagged marker positions for 004b boosters and traps);
  - `hub`: Snow Village hub placement data (`center`, `halfExtent`, `spawn`, `padRadius`, `assetKey`);
  - `lighting`: winter lighting and fog parameters (`ambient`, `outdoorAmbient`, `brightness`, `clockTime`, `fogColor`, `fogStart`, `fogEnd`, `atmosphereDensity`).
- **FR-002**: `src/shared/Worlds.luau` MUST switch `Worlds.active` to `SnowVillage` (while retaining `GreyBoxRoom` for existing unit tests) and expose `objectById`, `objectByBookId`, `objectsByTier` (list of `ObjectDef` per tier), `sizeTiers`, `tierLikes`, and `starThresholds` without any world-specific branches in server or client code.
- **FR-003**: Any hard-coded `GreyBoxRoom` references in `src/server/WorldSpawner.luau`, `src/server/AbsorbService.luau`, `src/client/BallController.luau`, and `src/client/StuckVisuals.luau` MUST be refactored to read from `Worlds.active` and a world-agnostic workspace container (`Workspace.World` with `Workspace.World.Objects` and `Workspace.World.Geometry`, or compatible aliases) so that future world reskins (Candy Town, Feature 011) require only data and assets (Constitution Principle VII).
- **FR-004**: Lune unit tests in `tests/unit/SnowVillage.test.luau` MUST validate:
  - All object `id`s and `bookId`s are globally unique;
  - Tier `minDiameter` and `maxDiameter` ranges strictly ascend and chain continuously across Tiers 1–5;
  - Every object's `size` falls within its tier's object-size range and satisfies `size <= Config.absorbRatio * tierCeilingDiameter` (`0.4 * tierCeilingDiameter`, using `150` studs for Tier 5) so every object is absorbable within its tier;
  - Object `coins` are positive integers and tier coin ranges ascend by tier;
  - Every object's `assetKey`, hub `assetKey`, and audio key exists in `src/shared/Assets.luau`;
  - Every `nameKey`, `headlineKey`, and tier reward `nameKey` exists in `src/shared/Localization/Strings.luau` with non-empty English (`en`) and Spanish (`es`) strings;
  - Every one of the 12 player spawn slots has at least `10` Tier 1 object placements within 3 seconds of rolling distance (`<= 45` studs along the spawn porch/runway).

#### Part B: Blender Asset Pipeline & Budgets (`art/source`, `art/export`, `src/shared/Assets.luau`)

- **FR-005**: All 3D assets for Snow Village (`64` absorbable object types across Tiers 1–5 and `1` hub asset) MUST be created or edited in Blender using the owner-approved pinned `blender-mcp` server (configured in `.vscode/mcp.json` and `opencode.json`) and/or deterministic headless Blender Python CLI scripts (`blender --background --python`), with `.blend` source files saved in `art/source/` and exported `.fbx` meshes in `art/export/` (Constitution Principles XI & XII).
- **FR-006**: All Snow Village meshes MUST be low-poly, flat-shaded, slightly oversized cartoon diorama models sharing a single palette texture (`art/source/palette.png` / uploaded texture asset in `src/shared/Assets.luau`), and MUST stay within the per-tier triangle budgets in `src/shared/Config.luau` (`Budgets.meshTriangles = { 300, 300, 800, 2500, 2500 }`):
  - Tiers 1–2: `<= 300` triangles per mesh;
  - Tier 3: `<= 800` triangles per mesh;
  - Tiers 4–5 (and Hub): `<= 2,500` triangles per mesh.
- **FR-007**: `scripts/check.sh` (or a script/Lune test invoked by `scripts/check.sh`) MUST verify that every exported mesh in `art/export/*.fbx` is within its tier's triangle budget and that no `rbxassetid://` mesh or audio ID is hard-coded outside `src/shared/Assets.luau`.
- **FR-008**: Every uploaded mesh and texture asset ID MUST be recorded in `src/shared/Assets.luau`. In Studio/runtime, objects of the same `objectId` MUST share/clone one template `MeshPart` (instancing) so geometry memory stays low, with a procedural low-poly part/mesh fallback when running in offline unit-test or grey-box check modes.
- **FR-009**: No Creator Store models containing scripts may be used; any mesh-only asset must pass an automated check confirming zero `Script`, `LocalScript`, or `ModuleScript` descendants exist (Constitution Principle XI).

#### Part C: World Layout, Elevation Routes & Grey-Box-First Gate

- **FR-010**: The Snow Village layout MUST span a playable Tiers 1–4 town footprint of `600 x 600` studs (`halfExtent = 300`) surrounded by an `800 x 800` stud (`outerHalfExtent = 400`) Tier 5 landmark ring, sized from ball speed (`18 * sqrt(D/2)` capped at `32` studs/s), `240` s run duration, `12` concurrent balls, and `60–120` s respawn times so 12 players can all reach Tier 4 without crowding or exhausting the map.
- **FR-011**: The town layout MUST include multi-elevation routes—kerbs (`1–2` studs high), porch steps, snow ramps leading onto raised terraces and low rooftops, and a central town square—plus `CollectionService`-tagged marker spots (`BoosterSpot`, `TrapSpot`) reserved for Feature 004b.
- **FR-012**: In accordance with Constitution Principle I (Fun Is Proven in Grey Box First), the Snow Village layout and pooled spawner MUST first be playable and verified with placeholder meshes in an agent-driven Studio run and by the owner playing it (recorded in `specs/004-snow-village/playtest.md`) before final Blender meshes are swapped in.

#### Part D: Pooled `WorldSpawner`, Out-of-Sight Respawning & Client Culling

- **FR-013**: `src/server/WorldSpawner.luau` MUST pool all spawned world object instances at world initialization:
  - Absorbing an object marks its pooled record `Taken`, sets a randomized respawn timestamp `respawnAt = now + random(Config.respawnDelayMin, Config.respawnDelayMax)` (`60–120` seconds in `Config.luau`), and hides/disables the pooled part in place (`Taken = true`, `Transparency = 1`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`) without destroying it;
  - Total active parts in the server MUST stay within `Config.Budgets.maxActivePartsPerServer` (updated in `Config.luau` to accommodate the pooled town within the 30 fps mobile budget).
- **FR-014**: `WorldSpawner.update(now)` MUST respawn a `Taken` object at `now >= cube.respawnAt` **only if** its `spawnCFrame.Position` is out of sight of nearby players (no active player ball is within `Config.respawnOutOfSightRadius` or within the player camera/movement forward view cone within `Config.respawnViewDistance`, implemented via a pure rule helper in `src/shared/Rules/Respawn.luau` tested by Lune), deferring respawn to a later tick if a player is watching that spot.
- **FR-015**: A new client module (`src/client/WorldCuller.luau` or within `BallController`/`StuckVisuals`) MUST hide world objects whose `Tier` attribute is far below the local player's current tier (`objectTier <= localPlayerTier - Config.cullTierDelta`, where `Config.cullTierDelta = 2` in `Config.luau`) for that client only (`LocalTransparencyModifier = 1`, `CanCollide = false`, `CanTouch = false`), and restore them if the player resets or shrinks back into range.
- **FR-016**: `Workspace.StreamingEnabled` MUST be enabled in `default.project.json` (with appropriate `StreamingMinRadius` and `StreamingTargetRadius` configured so phone clients stream the town smoothly without popping obstacles right in front of the ball).

#### Part E: Winter Lighting & Audio (`src/shared/Assets.luau`, `src/client/Feedback.luau`)

- **FR-017**: `WorldSpawner` (or a dedicated lighting initializer) MUST apply Snow Village's soft winter lighting and winter fog (`Lighting` properties and `Atmosphere`/`FogEnd` from `Worlds.active.lighting`) when loading the world.
- **FR-018**: `src/shared/Assets.luau` and `src/client/Feedback.luau` MUST provide and preload the Snow Village audio set:
  - Pickup "pop" (`Assets.sounds.pickup`) whose playback pitch rises by object tier (`1 + Config.pickupPitchStep * (tier - 1)`);
  - Tier unlock fanfare (`Assets.sounds.tierUnlock`);
  - Knock-off bump sound (`Assets.sounds.bump`) and run-end bell (`Assets.sounds.bell`);
  - Gentle looping winter background music track (`Assets.sounds.music`, parented to `SoundService`'s `Music` `SoundGroup` with `Looped = true` and controlled by `settings.musicVolume`);
  - Every sound MUST continue to have its visual equivalent on screen (pickup pop text+icon, tier unlock banner, bump indicator, results screen) per Constitution Principle VI.

### Key Entities

- **WorldDef (`SnowVillage`)**: Complete data definition of a playable world in `src/shared/Content/Worlds/SnowVillage.luau`, containing `worldId`, `starThresholds`, `sizeTiers`, `objects`, `placements`, `environment`, `hub`, `spawnPoints`, and `lighting`.
- **ObjectDef**: Metadata for one of the `64` object types (`60` across Tiers 1–4 + `4` in Tier 5): `id`, `tier` (`1..5`), `size` (longest dimension in studs), `coins`, `bookId`, `nameKey`, `icon`, `assetKey`.
- **ObjectPlacement**: A single pooled spawn slot in the world: `id` (unique placement ID, e.g., `"sv_p_001"`), `objectId` (references `ObjectDef.id`), `cframe` / `{ x, y, z, yaw }`, and optional `spawnClusterSlot` (`1..12`).
- **PooledWorldObject**: Runtime record in `WorldSpawner` representing a persistent, reusable `BasePart`/`MeshPart` instance in `Workspace.World.Objects`, tracking `id`, `objectId`, `tier`, `size`, `spawnCFrame`, `part`, `state` (`"Available" | "Taken" | "Scattered"`), `respawnAt`, `availableAt`, and `holderKey`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Lune unit tests (including Snow Village content validation and pure out-of-sight respawn rules) and Jest-Lua Studio tests pass, and `scripts/check.sh` exits `0`.
- **SC-002**: 100% of exported 3D assets in `art/export/*.fbx` meet their tier triangle budgets (`<= 300` tris for Tiers 1–2, `<= 800` for Tier 3, `<= 2,500` for Tiers 4–5), share the single palette texture, and have their asset IDs recorded exclusively in `src/shared/Assets.luau`.
- **SC-003**: In a 4-minute (`240` s) Studio local-server run with `12` concurrent simulated balls, balls reach Tier 4 (`diameter >= 30` studs) in Snow Village without any tier zone running dry, and a new player at any spawn slot rolls up their first Tier 1 object within `5` seconds and reaches Tier 2 within `60` seconds.
- **SC-004**: Frame rate holds at least `30 fps` at Tier 4 in both (a) an agent-driven Studio local server with `12` simulated balls and (b) the owner playing on a reference mobile phone, with active server parts staying within `Config.Budgets.maxActivePartsPerServer`; both measurements are recorded in `specs/004-snow-village/playtest.md`.
- **SC-005**: The grey-box layout check (with placeholder meshes before final art) and the final Snow Village check are both completed via agent-driven Studio playtest plus the owner playing, recorded with owner sign-off in `specs/004-snow-village/playtest.md`, with zero new console errors or warnings.

## Scope & Boundaries

### In Scope

- `src/shared/Content/Worlds/SnowVillage.luau` with the 5-tier Snow Village tier table (`20 / 45 / 80` stud star thresholds), `64` object types (`60` across Tiers 1–4 + `4` Tier 5 landmarks), coin values, localization keys (`en` and `es`), and `Assets.luau` keys.
- World-agnostic refactoring of `Worlds.luau`, `WorldSpawner.luau`, `AbsorbService.luau`, `BallController.luau`, and `StuckVisuals.luau` so a future reskin (Candy Town, 011) requires only data and assets.
- Blender asset pipeline (`art/source/*.blend`, `art/export/*.fbx`) using pinned `blender-mcp` and headless Blender Python CLI scripts, shared palette texture, triangle-budget enforcement in `scripts/check.sh`, and mesh/audio IDs in `src/shared/Assets.luau`.
- Nested-scale Snow Village layout (`600 x 600` stud Tiers 1–4 playable town with `800 x 800` stud Tier 5 landmark ring, 12 spawn slots each with ~10 Tier 1 objects within 3 seconds, kerbs/steps/ramps/rooftops, tagged spots for 004b boosters and traps, and 1 MVP hub asset).
- Grey-box layout check with placeholder meshes before final art (agent Studio run + owner playtest in `playtest.md`).
- Pooled `WorldSpawner` with `60–120` s out-of-sight respawning, `StreamingEnabled = true`, and per-client culling of objects far below the player's current tier.
- Soft winter lighting, winter fog, pickup pop with tier-rising pitch, tier fanfare, and looping winter background music.

### Out of Scope

- Jump tuning, active boosters, and traps mechanics (**Feature 004b**; only elevation routes and tagged marker spots are placed here).
- Animation and VFX juice polish (**Feature 004c**).
- Outside-people playtest with 3+ adults and 3+ children aged 10–12 (**Feature 004d**, per owner decision 2026-10-26).
- Co-op ball merging and Friend Boost (**Feature 005**).
- Cosmetic ball skins, trails, and Shop UI (**Feature 006**).
- Store-page icon and thumbnails (**Feature 008**).
- Candy Town world reskin (**Feature 011**).
- Weekly object drops and daily golden object (**Feature 012**).

## Assumptions

- **Outside-Player Playtest Deferral (Confirmed Owner Decision, 2026-10-26)**: The owner's grey-box sign-off is sufficient to start Feature 004, and all outside-people playtesting is deferred to Feature 004d once 004, 004b, and 004c make the game look and feel like a game.
- **Object Type Distribution (Confirmed Owner Decision, 2026-10-26)**: `18` Tier 1 objects (`0.3–1.5` studs), `16` Tier 2 objects (`1.5–4.0` studs), `14` Tier 3 objects (`4.0–10.0` studs), `12` Tier 4 objects (`10.0–25.0` studs), and `4` Tier 5 landmark objects (`25.0–60.0` studs: cottage house, town house, skating rink, clock tower) = `64` object types total, with `starThresholds = { 20, 45, 80 }` studs.
- **Playable Footprint (Confirmed Owner Decision, 2026-10-26)**: `600 x 600` studs (`halfExtent = 300`) for Tiers 1–4 nested zones surrounded by an `800 x 800` stud (`outerHalfExtent = 400`) Tier 5 landmark ring.
- **Respawn Timing & Out-of-Sight Rule**: Absorbed objects respawn after a deterministic/seeded delay between `respawnDelayMin = 60` s and `respawnDelayMax = 120` s, and only when no player ball is within `respawnOutOfSightRadius = 45` studs or looking toward the spawn point within `respawnViewDistance = 120` studs (with a `180` s starvation ceiling so a camper cannot permanently block respawns).
- **Client Sub-Tier Culling Threshold**: Objects at or below `playerTier - 2` (`Config.cullTierDelta = 2`, e.g., Tier 1 objects once a player reaches Tier 3, and Tier 1–2 objects once a player reaches Tier 4) are hidden on that player's client to keep rendering fast at large camera distances.
