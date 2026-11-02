# Feature Specification: Downtown "Inside Out" Map Redesign (Concept A)

**Feature Branch**: `008-downtown-inside-out`

**Created**: 2026-11-01

**Status**: Draft

**Input**: User description: "Owner, 2026-11-01: Downtown can be the release candidate world, but its current design is bad, and map design is 90% of the game's success. This item gets it right before the juice pass (004c). Design: docs/design/03-city-level.md and the concept below. Constitution: I, IV, VI, VII, XI. Depends on 004e (the Downtown data, meshes and theme system). Chosen concept: A, Inside Out (880 x 880 studs, Ring 1 Old Quarter -> Ring 2 Terraces -> Ring 3 Yards -> Ring 4 Boulevard -> Ring 5 Skyline and Harbour)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-60-Second Vertical Slice: Old Quarter to First Terraces Block (Priority: P1)

Players start in the heart of **Downtown** inside **Ring 1 (Old Quarter)**, a compact historic centre of cobbled lanes (`8` studs wide) between small shops, crossed by two `30`-stud-wide main streets that meet at a central square holding the theme's centerpiece landmark (**Mega Tree** in Holiday City, **Giant Inflatable Duck** in Sunny City) and fountain. All 12 player spawn points sit inside the Old Quarter lanes, each stocked with at least `40` Tier 1 Pocket objects within `10` studs and bordered by `1.0–1.5`-stud kerbs that invite early jumps. Tier 2 bollards gate the main streets at the edge of the Old Quarter.

Before expanding to the full map, a playable vertical slice comprising the complete **Old Quarter (Ring 1)** and **one `30`-stud main street leading out through the bollard gate to the first Ring 2 (Terraces) block** (lined with rows of houses on both faces) is built and verified from overhead and street-level camera captures in both Holiday City (`winter`) and Sunny City (`city`). Dark asphalt roadway/lane ground contrasted against white snow-capped blocks, roofs, and lawns ensures street corridors and districts read clearly in winter without introducing new palette colours.

**Why this priority**: Proves the core visual readability, street enclosure, 12-player lane stocking, and first-60-second growth flow (Tier 1 to Tier 2 transition through the bollard gate into the Terraces) before scaling the layout across all five rings.

**Independent Test**: Can be tested by loading the vertical slice in Studio and running automated validation checks, verifying that all 12 lane spawns have `>= 40` Tier 1 pickups within `10` studs, the central square landmark is visible down the main streets, `8`-stud lanes and `30`-stud main streets are enclosed by shop and house rows on raised white/sidewalk plinths over dark asphalt ground, and all 12 simultaneous players reach Tier 2 (`diameter >= 5` studs) within `60` seconds without starving one another.

**Acceptance Scenarios**:

1. **Given** the vertical slice loaded in Holiday City (`winter`) and Sunny City (`city`), **When** inspected from overhead and street-level camera views, **Then** the Old Quarter presents `8`-stud cobbled lanes between small shops, two `30`-stud main streets meeting at the central landmark square, bollard gates at the Old Quarter edge, and a double-sided row of Terraces houses along the outbound main street, with dark asphalt ground contrasting cleanly against light pavements, roofs, and snow caps.
2. **Given** 12 players spawning simultaneously across the 12 Old Quarter lane spawns at diameter `2` studs, **When** they collect nearby Tier 1 Pocket objects over the first `60` seconds (with cluster refresh on run start and out-of-sight/starvation respawns active), **Then** every player collects their first object within `5` seconds and reaches Tier 2 (`diameter >= 5` studs, able to eat the bollard gate and enter the Terraces) within `60` seconds.
3. **Given** a small-only shortcut passage (`4.5` studs wide with an overhead roof cap at `4.8–5.0` studs) between Old Quarter / Terraces buildings, **When** a Tier 1 ball (`diameter <= 4.4` studs) rolls through it vs. a Tier 2+ ball (`diameter >= 5.0` studs) attempting to enter from the mouth or jump over from above, **Then** the Tier 1 ball passes cleanly while the `diameter >= 5.0` ball is physically blocked both horizontally and from above.

---

### User Story 2 - Full 5-Ring "Inside Out" Map Rollout & Late-Game City Eating (Priority: P1)

From the Old Quarter centre, the city expands outward across an `880 × 880` stud playable footprint (`halfExtent = 440`, `outerHalfExtent = 560`) so each concentric ring is wider than the last and street width scales with the ball's diameter:
- **Ring 1 — Old Quarter (Tier 1, centre)**: `8`-stud cobbled lanes between small shops, two `30`-stud main streets, `12` lane spawns, central square with the landmark slot (`mega_tree` / `giant_duck`) and fountain, and Tier 2 bollard gates at the main street exits.
- **Ring 2 — Terraces (Tier 2)**: Streets `16` to `30` studs wide (`16`-stud residential streets and `30`-stud main avenues), framed by rows of absorbable townhouses and corner shop rows on both faces of each city block, plus enclosed `4.5`-stud small-only shortcuts and the roofed storm-drain tunnel.
- **Ring 3 — Yards (Tier 3)**: Five distinct mid-run district yards surrounding the Terraces, each with its own ground surface and signature feature:
  1. **The Park**: Lawns (`w-grass` / `w-season`), pond (`ice_rink` in `winter`), `winter`-only sledding slope with wooden sleds, hedges/fence gate, benches, picnic tables, and trees.
  2. **The Market**: Paved market square with market stalls, pallet stacks, fruit crates, carts, vending machines, arcade cabinets, and cascade stacks.
  3. **The Construction Site**: Concrete/sand yard with perimeter hoarding, climbable scaffolding ramps, and a shipping-container stack.
  4. **The Car Park**: Multi-deck concrete structure with climbable ramps rising to an elevated top deck lined with parked cars.
  5. **The Rail Yard**: Rail-bed yard with parallel track strips, stacked shipping containers, delivery vans, and freight props.
- **Ring 4 — The Boulevard (Tier 4)**: A `60`-stud-wide orbital traffic avenue with a raised tree-lined median separating two carriageways filled with cars, taxis, pickup trucks, delivery vans, garbage trucks, fire engines, city buses, bus shelters, billboards, and hero vehicles (**Donut Food Truck** / **Cocoa Truck**, **Monster Truck**).
- **Ring 5 — Skyline and Harbour (Tier 5)**: High-rise towers, apartment blocks, cinema, EV charging station, **Rocket Water Tower**, **Tower Crane**, and **The Glass Tower** on the north and east; open harbour basin (`w-water`), quay wall, boardwalk, and **Ferris Wheel** on the south and west. There is no perimeter wall; static non-absorbable towers beyond the north/east edge and open water beyond the south/west edge form the horizon (`440` to `560` studs).

As the ball reaches Tiers 4 and 5, the camera pulls back smoothly all the way to diameter `80+` (`cameraMaxDistance = 320`), the richer Tier 3–5 placement split (`470 / 386 / 260 / 204 / 56`, totaling `~1,376` base placements) accelerates late-game growth so a strong run reaches `3` stars (`diameter >= 80`) and can push to `diameter >= 150` by `4:00` to swallow the biggest Tier 5 landmarks (**Apartment Block** at `D 100`, **Ferris Wheel** at `D 125`, **Tower Crane** at `D 137.5`, **The Glass Tower** at `D 150`), and the shops and houses of Rings 1 and 2 become edible food so a giant ball can eat its way back through the inner city.

**Why this priority**: Solves the core layout, district identity, camera framing, Tier 3–5 food starvation, and landmark eatability problems identified on the previous placeholder map.

**Independent Test**: Can be tested via automated spatial, sightline, street-width, obstacle-aware pace, and coverage tests (`scripts/check.sh`) plus ring-by-ring Studio captures and a full playtest in both `winter` and `city`.

**Acceptance Scenarios**:

1. **Given** the complete 5-ring Downtown map in Holiday City (`winter`) and Sunny City (`city`), **When** spatial and placement tests run, **Then** the playable envelope is `880 × 880` studs (`halfExtent = 440`, `outerHalfExtent = 560`, Hub at `x = -620`), placements per tier match the `470 / 386 / 260 / 204 / 56` target split within `±10%` per tier, built structures and distinct district grounds cover at least `20%` of the playable area, no perimeter wall exists, and street widths match each ring (`8`-stud lanes and `30`-stud main streets in Ring 1, `16–30` studs in Ring 2, `>= 30`-stud yard approaches in Ring 3, `60`-stud Boulevard with median in Ring 4, and open Skyline/Harbour avenues on the north/east and south/west in Ring 5).
2. **Given** a player growing from diameter `2` to diameter `80–150` over a 4-minute run, **When** the ball grows past diameter `20` up to diameter `80+`, **Then** the camera pull-back continues scaling smoothly beyond `80` studs (up to `320` studs) so the ball never fills the screen, and an optimal late-game path reaches `3` stars (`diameter >= 80`) before `3:30` and `diameter >= 150` by `4:00` so every Tier 5 landmark (including **Ferris Wheel** and **The Glass Tower**) can be absorbed in a run, while rolling back into Rings 1 and 2 allows absorbing the Old Quarter shops and Terraces houses.
3. **Given** `activeThemeId` switched between `"winter"` (Holiday City) and `"city"` (Sunny City), **When** the world builds in Studio, **Then** holiday-only static geometry (overhead street garlands and the Park sledding slope) appears only in `"winter"` and never in `"city"`, all 5 dressing slots and theme overlays swap cleanly by data alone, and all 5 booster kinds, 4 trap kinds, and 5 golden-object hiding spots remain valid and unobstructed.

---

### User Story 3 - Performance, Visual Mesh QA & Regression Gate Verification (Priority: P2)

With `~1,376` base placements (up to `1,526` with winter overlays) and `12` balls (~`1,800` total active parts), Downtown is verified for mobile rendering budgets, mesh appearance in Play, and obstacle-aware layout regressions:
- Active server parts stay strictly below `2,000` (`Config.Budgets.maxActivePartsPerServer`, targeting `~1,800` parts with 12 balls).
- Worst-case and culled (`cullTierDelta = 2`) triangle counts are audited against `art/export/manifest.json`, and a 12-ball run in Holiday City (`winter`) holds at least `30 fps` on unthrottled seconds in Studio.
- Imported `dt_*` meshes are visually inspected in Play to confirm single material, valid gradient-atlas UVs, seasonal top faces (`w-season`), and Minimal-rating compliance.
- Obstacle-aware sightline and pace tests verify that static blocks and unabsorbable buildings do not block main-street sightlines or pace routes.

**Why this priority**: Guarantees that the denser, richer 5-ring city meets Constitution Principle VI (Mobile First 30 fps and part/triangle budgets) and Principle XI (Asset Pipeline) before the juice pass (`004c`) and release candidate (`RC`).

**Independent Test**: Can be verified by running `scripts/check.sh`, executing a 12-ball Studio performance run in Holiday City (`winter`), and inspecting Studio captures of the imported `dt_*` meshes and climbing/shortcut geometry in Play.

**Acceptance Scenarios**:

1. **Given** Holiday City (`winter`) running in Studio with 12 active balls and all `dt_*` meshes loaded, **When** active parts and frame rate are sampled over 60 seconds, **Then** total active parts in `Workspace` remain `<= 1,850` (strictly `< 2,000`) and unthrottled seconds hold `>= 30 fps`.
2. **Given** the imported `dt_*` meshes placed across Rings 1–5 in Play, **When** inspected via Studio checks and captures in both `winter` and `city`, **Then** every mesh renders with a single material, clean atlas UVs (snow caps on `w-season` faces in `winter`, summer swatches in `city`), and zero moderation or console warnings.
3. **Given** an empty-field layout or a layout where a static block wall or unabsorbable building crosses a main street sightline or pace path, **When** the automated layout regression suite runs, **Then** the suite fails on built-coverage, tier-placement, street-width, shortcut-gap, sightline-block, or obstacle-aware pace assertions.

---

### Edge Cases

- **12 Players Spawning Simultaneously in the Central Old Quarter**: Because all 12 spawns sit inside Ring 1 (`|x|, |z| <= 90`), each spawn slot's `10`-stud Pocket cluster (`>= 40` Tier 1 objects) MUST be spatially separated or stocked densely enough (`~470` Tier 1 placements in Ring 1) so that 12 players starting at `t = 0` all reach `diameter >= 5` within `60` seconds without depleting neighbors' first-minute food, and `refreshCluster` immediately restores a slot's cluster whenever a player starts a new run.
- **Late-Game Eating of Inner-Ring Shops and Houses Without Leaving Floating Props**: When a Tier 4–5 ball rolls back into Ring 1 or Ring 2 and absorbs shops (`corner_bakery`, `corner_shop_row`) or houses (`townhouse`, `cinema`, `apartment_block`), small props and markers MUST sit on the ground, pavements, or static plinths—never resting unsupported on top of an absorbable building.
- **Small-Only Shortcuts Blocked in All 3 Dimensions (`F5` & `F6`)**: Every small-only route (narrow alleys between Terraces/Old Quarter buildings and the storm-drain tunnel) MUST enforce a single agreed horizontal clear width of `4.5 ± 0.1` studs and an overhead roof/bridge/arch cap with vertical clearance `4.8–5.0` studs so balls `diameter >= 5.0` cannot enter through the mouth or jump/roll over the side walls from above.
- **Holiday Dressing Strictly Theme-Scoped (`F2`)**: All holiday-only static blocks (such as Market Street/Main Street overhead garlands and the Park sledding slope) MUST reside in `themeBindings.winter.blocks` and never in base `environment.blocks`, ensuring Sunny City (`city`) contains zero winter geometry.
- **No Perimeter Wall & Open Horizon Bounds**: Removing the 40-stud perimeter wall MUST NOT allow balls to roll off the map endlessly; invisible boundary colliders at `±halfExtent` (`±440`) keep active balls inside the playable city (with `fallRespawnY` as the vertical safety net) while keeping sightlines open to the Ring 5 Harbour water (south/west) and static horizon towers (`440` to `560` studs on north/east).
- **Triangle Load With Higher Tier 3–5 Counts**: Because Tier 3–5 placements increase from `64 / 77 / 17` to `~260 / 204 / 56`, client-side distance/tier culling (`cullTierDelta = 2`) and actual mesh triangle counts from `art/export/manifest.json` MUST keep active rendered triangles within mobile limits, with early verification recorded for the RC phone check.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: "Inside Out" 5-Ring Map Architecture & Envelope (`src/shared/Content/Worlds/Downtown.luau`)

- **FR-001**: `Downtown` MUST use an expanded `880 × 880` stud playable area (`halfExtent = 440`), a `1,120 × 1,120` stud horizon envelope (`outerHalfExtent = 560`), and a repositioned western Hub (`hub.center = { x = -620, z = 0 }`) outside `outerHalfExtent`, updating all unit and Studio tests that previously pinned `halfExtent = 300`, `outerHalfExtent = 400`, or `hub.center.x = -460`.
- **FR-002**: `Downtown` MUST organize its static geometry (`environment.blocks`), `spawnPoints`, `zones`, and `fixedPlacements` into five outward-growing concentric rings ("Concept A: Inside Out"):
  - **Ring 1 — Old Quarter (Tier 1, `|x|, |z| <= 90`)**:
    - Central square containing the `slot.landmark` centerpiece (`mega_tree` in `winter`, `giant_duck` in `city`) and fountain;
    - Cobbled lanes `8` studs wide between small shops (`corner_bakery`, `corner_shop_row`), crossed by two `30`-stud-wide main streets (north–south and east–west);
    - `12` spawn points inside the cobbled lanes, each with `>= 40` Tier 1 Pocket objects within `10` studs (`spawnSlot = 1..12`) and bordered by `1.0–1.5`-stud kerbs/stoops;
    - Tier 2 bollard gates (`2.0–2.4` studs) across the main street exits at the Old Quarter boundary.
  - **Ring 2 — Terraces (Tier 2, `90 < max(|x|, |z|) <= 185`)**:
    - Streets `16` to `30` studs wide (`16`-stud residential streets and `30`-stud main streets), with rows of absorbable houses and shop rows (`townhouse`, `corner_shop_row`, `corner_bakery`) lining both faces of every city block on raised pavement plinths;
    - Enclosed small-only shortcuts (`4.5 ± 0.1` studs wide, roofed at `4.8–5.0` studs high) cutting through Terrace blocks and the storm-drain tunnel.
  - **Ring 3 — Yards (Tier 3, `185 < max(|x|, |z|) <= 290`)**:
    - Five distinct districts, each with its own ground surface and signature toy/climbable feature:
      1. **The Park**: `w-grass` / `w-season` lawns, pond (`ice_rink` in `winter`), `winter`-only sledding slope with `wooden_sled` placements, hedges/fence gate, benches, picnic tables, and street trees;
      2. **The Market**: paved market square with stalls, pallet stacks, fruit crates, hot-dog/cocoa carts, vending machines, arcade cabinets, and cascade stacks;
      3. **The Construction Site**: concrete/sand ground, hoarding fence, climbable scaffolding ramps (`<= 2.0`-stud steps/inclines), and shipping-container stack;
      4. **The Car Park**: multi-level concrete deck with climbable spiral ramps (`<= 2.0`-stud steps/inclines) rising to an elevated top deck with parked cars;
      5. **The Rail Yard**: rail-bed ground with parallel track strips, stacked shipping containers, delivery vans, and freight props.
  - **Ring 4 — The Boulevard (Tier 4, `290 < max(|x|, |z|) <= 360`)**:
    - A `60`-stud-wide orbital traffic ring around the Yards with a raised tree-lined median (`big_street_tree`, `street_tree`, `street_lamp`, `traffic_light`) separating two carriageways populated with Tier 4 vehicles, bus stops, billboards, and hero trucks.
  - **Ring 5 — Skyline and Harbour (Tier 5, `360 < max(|x|, |z|) <= 440`, horizon `440–560`)**:
    - **Skyline (North and East)**: High-rise towers, `apartment_block`, `cinema`, `ev_charging_station`, `rocket_water_tower`, `tower_crane`, and `glass_tower` / `glass_tower_bow`, backed by static non-absorbable horizon towers between `440` and `560` studs;
    - **Harbour (South and West)**: Quay wall, boardwalk, `ferris_wheel`, shipping containers, and waterfront props bordering opaque `w-water` harbour basins that extend to `560` studs;
    - **No Perimeter Wall**: Zero opaque perimeter walls along `±440`; invisible boundary colliders keep active balls within the playable area while preserving open views to the horizon towers and water.
- **FR-003**: Base ground across the playable city MUST use dark asphalt (`w-asphalt`) while raised city block plinths/pavements, roofs, and Park lawns use light/white swatches (`w-sidewalk`, `w-season`, `w-roof-*`, `w-grass`) so street corridors, kerbs, and district boundaries remain high-contrast and readable in both `winter` (Holiday City) and `city` (Sunny City) with zero new palette colours added to `tokens.json`.
- **FR-004**: Shops and houses lining Ring 1 (Old Quarter) and Ring 2 (Terraces) MUST be placed as absorbable Tier 4–5 world objects (`corner_bakery`, `corner_shop_row`, `townhouse`, `cinema`, `apartment_block`) standing on static pavement plinths (`1.0–1.5` studs tall), so they act as solid street walls for Tier 1–3 balls and become absorbable food when a Tier 4–5 ball rolls back through the inner rings.

#### Part B: Placement Distribution, Camera Scaling, Landmark Eatability & 12-Player Stocking (`src/shared/Config.luau`, `src/shared/Content/Worlds/Downtown.luau`)

- **FR-005**: Base placements across Tiers 1–5 MUST match the Concept A target distribution of `470 / 386 / 260 / 204 / 56` (`1,376` base placements) within `±10%` per tier, and total active server parts (resolved placements in `winter` or `city` + static blocks + theme blocks + built markers + Hub parts + `12` balls + `64` runtime trail/hazard parts) MUST stay `<= 1,850` and strictly under `Config.Budgets.maxActivePartsPerServer` (`2,000`). If `150` `winter` overlay placements are added on top of `~1,376` base placements, `Downtown.maxPlacements` and `Config.Budgets.defaultMaxPlacements` MAY be set up to `1,550` provided total active server parts stay `<= 1,850`.
- **FR-006**: `Config.cameraMaxDistance` in `src/shared/Config.luau` MUST be raised from `80` to `320` so `Rules.Movement.cameraDistance` (`cameraMultiplier = 4`) continues pulling the camera back smoothly from `D = 2` (`8` studs) through `D = 80` (`320` studs) instead of clamping at `D = 20`.
- **FR-007**: `Downtown.growthK` and the Tier 3–5 placement density MUST be tuned for a faster late game so that from every one of the 12 Old Quarter spawns in both `winter` and `city`:
  - First pickup occurs within `<= 5` seconds;
  - Tier 2 (`D >= 5`) is reached at `0:30 ± 20 s` (`10–50 s`);
  - Tier 3 (`D >= 12`) is reached at `62–110 s` (lower bound relaxed by the owner, 2026-11-02);
  - Tier 4 (`D >= 30`) is reached at `105–180 s` (lower bound relaxed by the owner, 2026-11-02);
  - 3 stars (`D >= 80`, Tier 5) is reached by `<= 210 s`; and
  - Final diameter by `240 s` reaches `D >= 150`, allowing a full-run ball to absorb every Tier 5 landmark including `apartment_block` (`size 40`, needs `D 100`), `mega_tree` (`size 45`, needs `D 112.5`), `ferris_wheel` (`size 50`, needs `D 125`), `tower_crane` (`size 55`, needs `D 137.5`), and `glass_tower` / `glass_tower_bow` (`size 60`, needs `D 150`) without shrinking the landmark meshes.
- **FR-008**: In a simultaneous 12-player start where all 12 balls spawn at `t = 0` across the 12 Old Quarter spawns and compete for pickups in the shared world (with out-of-sight/starvation respawns active), all 12 balls MUST collect their first pickup within `<= 5` seconds and reach Tier 2 (`D >= 5`) within `<= 60` seconds.

#### Part C: PR #8 Review Resolutions (`F2`, `F5`, `F6`, `F7`) & Regression Suite (`tests/unit/Downtown.test.luau`, `tests/unit/Pace.test.luau`)

- **FR-009 (Review F2 — Theme-Scoped Holiday Scenery)**: All holiday-only static geometry (including overhead street garlands and the Park sledding slope) MUST be defined exclusively in `Downtown.themeBindings.winter.blocks` and never in base `Downtown.environment.blocks`, so Sunny City (`city`) builds zero winter scenery blocks.
- **FR-010 (Review F5 & F6 — Uniform Enclosed Small-Only Shortcuts)**: Every small-only route (`keepOutAreas` with `kind = "shortcut"`, covering the narrow Old Quarter/Terraces alleys and the storm-drain tunnel) MUST enforce one agreed horizontal clear width of `4.5 ± 0.1` studs between flanking solid walls and an overhead roof/arch block with bottom face at `y = 4.8–5.0` studs covering the shortcut length, physically blocking `diameter >= 5.0` balls both horizontally and from above.
- **FR-011 (Review F7 — Block- & Building-Aware Sightline and Pace Tests)**:
  - The sightline test in `tests/unit/Downtown.test.luau` MUST check sightline corridors along the Old Quarter main streets and from spawns to landmarks against both static `environment.blocks` (with `top > 2.5` studs) and Tier 4–5 building placements, failing if any wall or non-target building intersects a sightline corridor;
  - The pace model in `tests/unit/Pace.test.luau` MUST account for static `environment.blocks` taller than the ball's jump clearance and unabsorbable placements (`size > 0.4 * diameter`), penalizing or routing around obstructed straight-line segments so barriers cannot be ignored by the greedy eater.
- **FR-012 (Anti-Empty-Field Layout Regressions)**: `tests/unit/Downtown.test.luau` MUST enforce layout checks that an empty field or sparse placeholder map would fail:
  - **Built & district coverage**: Static non-ground blocks (`top > 0.2`) plus Tier 4–5 building footprints cover at least `20%` of the `880 × 880` playable area, with at least `50` static city/yard blocks and zero perimeter wall blocks taller than `8` studs at the map boundary;
  - **Per-tier placement split**: Resolved placements per tier sit within `±10%` of `470 / 386 / 260 / 204 / 56` (Tiers 1–5);
  - **Ring street widths vs. ball size**: Verified clear corridor widths in each ring matching target ball sizes (`8`-stud lanes and `30`-stud main streets in Ring 1 for `D 2–5`; `16–30`-stud streets in Ring 2 for `D 5–12`; `>= 30`-stud yard corridors in Ring 3 for `D 12–30`; `60`-stud Boulevard with two `>= 24`-stud carriageways in Ring 4 for `D 30–70`; and `>= 40`-stud Skyline/Harbour avenues in Ring 5 for `D 70–150`);
  - **Triangle budget audit**: Total unculled and `cullTierDelta = 2` culled scene triangles computed from `art/export/manifest.json` across all resolved placements stay within the documented scene ceiling.

#### Part D: Staged Workflow, Carried-Over 007 Verification & RC Routing

- **FR-013**: Implementation MUST proceed in two visual stages verified with Studio MCP `screen_capture` in both `winter` and `city`:
  1. **Stage 1 (Vertical Slice)**: Old Quarter (`Ring 1`) + one `30`-stud main street out to the first Terraces block (`Ring 2`), verified with overhead and street-level captures and 60-second 12-spawn checks;
  2. **Stage 2 (Full Map Rollout)**: Ring-by-ring completion of `Ring 2 (Terraces)`, `Ring 3 (Yards: Park, Market, Construction Site, Car Park, Rail Yard)`, `Ring 4 (Boulevard)`, and `Ring 5 (Skyline, Harbour, and Horizon)`, verified with Studio captures per ring, live sphere-cast/geometry checks of shortcuts and climbing ramps, visual check of imported `dt_*` meshes in Play (single material, atlas UVs, Minimal-rating compliance), and a 12-ball 60-second performance sampling run in Holiday City (`>= 30 fps` on unthrottled seconds, `< 2,000` active parts) recorded in `specs/008-downtown-inside-out/playtest.md`.
- **FR-014**: Checks requiring a human player, a physical phone, disk-saved capture files, or owner aesthetic sign-off (owner approval of slice and full map look/feel, human-played D 5/12/30/80 timings across 12 spawns, saved phone-resolution capture files, and reference-phone frame-rate testing) MUST be updated and tracked in `docs/release-candidate.md` alongside the agent-verified results in `specs/008-downtown-inside-out/playtest.md`, in accordance with Constitution v3.0.0 Quality Gates.

### Key Entities

- **Inside Out Ring Layout (`Ring 1` to `Ring 5`)**: Five concentric/directional zones expanding from `(0, 0)` across the `880 × 880` stud playable city (`Old Quarter` -> `Terraces` -> `Yards: Park, Market, Construction Site, Car Park, Rail Yard` -> `Boulevard` -> `Skyline & Harbour`), with static horizon towers and water extending to `1,120 × 1,120` studs (`outerHalfExtent = 560`).
- **Late-Game Edible Street Frontage**: Absorbable Tier 4–5 building placements (`corner_bakery`, `corner_shop_row`, `townhouse`, `cinema`, `apartment_block`) arranged along raised static pavement plinths to form `8`-stud lanes in Ring 1 and `16–30`-stud streets in Ring 2 early in the run and edible city blocks late in the run.
- **Enclosed Small-Only Shortcut**: A `keepOut` corridor (`kind = "shortcut"`) flanked by solid walls with a uniform `4.5 ± 0.1` stud horizontal gap and capped by a roof block at `y = 4.8–5.0` studs so only balls with `diameter < 4.5` studs can traverse it.
- **Obstacle-Aware Pace & Sightline Models**: Pure Lune verification models in `tests/unit/Pace.test.luau` and `tests/unit/Downtown.test.luau` that test line-of-sight and travel routes against both `environment.blocks` and unabsorbable building placements, plus a 12-eater concurrent lane-stocking check.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `scripts/check.sh` exits `0` with 100% of Lune unit tests and Jest-Lua Studio tests passing, including the new anti-empty-field layout regressions (`>= 20%` built/district coverage, `470 / 386 / 260 / 204 / 56 ± 10%` placements per tier, uniform `4.5 ± 0.1` stud roofed shortcuts, ring street widths vs. ball size, block/building-aware sightlines, obstacle-aware 12-spawn pace model reaching `D >= 80` by `210 s` and `D >= 150` by `240 s`, and 12-player concurrent first-minute lane stocking).
- **SC-002**: Both the Stage 1 Vertical Slice (Old Quarter + first Terraces block) and the Stage 2 Full 5-Ring Map render as a recognizable, high-contrast city at every tier in both Holiday City (`winter`) and Sunny City (`city`), with dark asphalt streets contrasting against white/light blocks, roofs, and lawns, verified through overhead and street-level Studio captures inspected during implementation.
- **SC-003**: Switching between Holiday City (`winter`) and Sunny City (`city`) remains a single-line data change (`activeThemeId = "winter"` vs. `"city"`) with zero code changes and zero winter-only blocks (`garlands`, `sledding slope`) leaking into Sunny City.
- **SC-004**: As a ball grows from `diameter = 2` to `diameter = 150`, the camera pulls back smoothly past `D = 20` up to `320` studs (`Config.cameraMaxDistance = 320`), late-game balls can eat Rings 1–2 shops and houses as well as every Tier 5 landmark (up to `size = 60` at `D = 150`), and all shortcuts and climbing routes (Car Park spiral ramp, Construction Site scaffolding) are verified in Studio Play.
- **SC-005**: In a 60-second Studio Play session in Holiday City (`winter`) with 12 active balls and all 99 `dt_*` meshes loaded, total active parts stay `<= 1,850` (strictly `< 2,000`), unthrottled seconds maintain `>= 30 fps`, console output shows zero new warnings or errors, and all agent-run results and RC hand-off items are recorded in `specs/008-downtown-inside-out/playtest.md` and `docs/release-candidate.md`.

## Scope & Boundaries

### In Scope

- Redesigning `src/shared/Content/Worlds/Downtown.luau` to implement Concept A ("Inside Out") across an `880 × 880` stud playable area (`halfExtent = 440`, `outerHalfExtent = 560`, `hub.center = { x = -620, z = 0 }`)):
  - Stage 1 vertical slice: Ring 1 (Old Quarter with `8`-stud cobbled lanes, two `30`-stud main streets, 12 lane spawns, central landmark square, bollard gates) + one main street out to the first Ring 2 (Terraces) block;
  - Stage 2 full rollout: Ring 2 (Terraces `16–30`-stud streets with double-sided house rows), Ring 3 (five Yards: Park, Market, Construction Site, Car Park, Rail Yard, each with its own ground and toy/ramp), Ring 4 (`60`-stud Boulevard with tree-lined median), and Ring 5 (Skyline on north/east, Harbour water on south/west, static horizon towers beyond the edge, no perimeter wall).
- Dark asphalt base ground (`w-asphalt`) with light/white blocks, roofs, and lawns for winter readability without adding new palette colours.
- Placing shops and houses as absorbable Tier 4–5 objects along Ring 1–2 block plinths so big balls can eat their way back through the inner rings.
- Rebalancing placements by tier to match `470 / 386 / 260 / 204 / 56` (`±10%`, `~1,376` base placements, `~1,800` total parts with 12 balls, strictly `< 2,000` active parts).
- Raising `Config.cameraMaxDistance` from `80` to `320` in `src/shared/Config.luau`.
- Tuning `Downtown.growthK` and Tier 3–5 density for a faster late game so `D >= 150` is reachable by `240 s` and every Tier 5 landmark (`apartment_block`, `mega_tree`, `ferris_wheel`, `tower_crane`, `glass_tower`) can be eaten in a run.
- Verifying 12-player concurrent starting density and respawn stocking in the Old Quarter lanes.
- Resolving PR #8 review findings `F2` (holiday blocks scoped to `themeBindings.winter.blocks`), `F5` (small-only shortcuts blocked from above), `F6` (single agreed `4.5 ± 0.1` stud width and test for small-only gaps), and `F7` (pace and sightline tests aware of static blocks and buildings).
- Updating `tests/unit/` and `tests/studio/` for the new map dimensions, coverage, tier split, street widths, triangle audit, and obstacle-aware pace/sightline checks.
- Executing agent-runnable Studio checks carried over from Feature 007 (live shortcut/ramp verification, imported `dt_*` mesh visual inspection in Play, 12-ball 30 fps / part budget run, overhead and street-level captures via `screen_capture`) and updating `docs/release-candidate.md` for owner RC sign-off items.

### Out of Scope

- Animation and VFX juice pass (**Feature 004c**).
- Outside-people playtest with 3+ adults and 3+ children aged 10–12 (**Feature 004d**, run on the RC).
- New colour tokens in `docs/design/tokens.json` or new 3D mesh assets beyond the existing 99 `dt_*` meshes and `SmoothPlastic` environment blocks.
- Player cosmetics, shop UI, co-op merge, and daily golden-object runtime spawning logic (**Features 005, 006a, 006b, 012**).

## Assumptions

- **Constitution v3.0.0 Governance on Owner Taste & RC Checks**: Under Constitution v3.0.0 (Quality Gates and Governance, ratified 2026-11-01), feature gates and `tasks.md` require only what an agent can run (`scripts/check.sh`, Lune, Jest-Lua, and Studio MCP checks/captures), while owner taste sign-off (approving the slice and full map look/feel by playing), human-played 12-spawn timings, disk-saved capture files, and physical-phone testing are recorded on `docs/release-candidate.md` and do not block the feature pull request. During implementation, the agent still builds the vertical slice first and inspects Studio MCP `screen_capture` views at the slice and each ring before completing the rollout.
- **Landmark Eatability Solved via Faster Late Game (Preserving Existing Meshes)**: Of the three options proposed in the prompt (*"Choose smaller landmarks, a faster late game, or a finale that lets the biggest ball take them"*), **a faster late game** (enabled by the 3.3× increase in Tier 3–5 placements from `64 / 77 / 17` to `260 / 204 / 56`, late-game edible Ring 1–2 shops/houses, and tuning `Downtown.growthK`) is chosen as the default because it makes all Tier 5 landmarks (`size 40–60`, requiring `D 100–150`) absorbable before `240 s` while preserving all 99 already-exported and uploaded `dt_*` meshes (`art/scripts/budgets.json` and `src/shared/Assets.luau`) and keeping `src/shared/Rules/Absorb.luau` unchanged.
- **Placement Cap & Part Budget Balance**: The drawing's `470 / 386 / 260 / 204 / 56` (`1,376`) split is enforced within `±10%` per tier. So that both `city` and `winter` (which adds ~`150` holiday overlay placements) fit cleanly while keeping total active server parts around `~1,800` and strictly below `Config.Budgets.maxActivePartsPerServer` (`2,000`), `Downtown.maxPlacements` and `Config.Budgets.defaultMaxPlacements` may be set up to `1,550` (or `winter` overlays may share the `1,400` cap) as long as the hard server part budget (`< 2,000` parts including `12` balls, static blocks, Hub, markers, and `64` runtime parts) is met in both themes.
- **Docs Synchronisation (`docs/design/03-city-level.md`)**: `docs/design/03-city-level.md` will be updated alongside `Downtown.luau` so the level design document reflects the chosen Concept A ("Inside Out") `880 × 880` layout, rings, and tier placement targets.
