# Feature Specification: Dress Park City with the City Asset Kit and Themes

**Feature Branch**: `014-park-city-art`

**Created**: 2026-11-08

**Status**: Draft

**Input**: User description: "Aligned 2026-11-08. The owner rejected Downtown and Park City (spec `012-park-city-map`) replaced it as the world: it is already the outside-in map this item used to propose (park, suburbs, then the city). Park City overrides Downtown in `src/shared/Worlds.luau` even with `Config.Flags.Downtown` on. What is left is making it look like the game. Depends on 004h (city kit, spec `013-city-asset-kit`). Constitution: I, IV, VI, VII, XI.

Later backlog items that still say \"Downtown\" (005, 006a, 007, 009, 012, 013) mean the active world, now Park City. Each fixes its wording when it is specified.

### The gap
Park City draws its objects as plain coloured parts; only the hub is a mesh. The kit is built and uploaded (121 `ck_*` and 99 `dt_*` meshes, city and winter atlases, ids in `src/shared/Assets.luau`), but no world places a `ck_*` object. Park City also has no `activeThemeId`, and a mesh gets its atlas through the active theme (`src/shared/ObjectVisual.luau`), so this item must give it one.

### Coverage first
Map Park City's roughly 370 object ids in `src/shared/Content/Worlds/ParkCity.luau` against the kit (`src/shared/Content/CityKit.luau`) and the `dt_*` meshes. Report exact matches (16 share an id with the kit, for example `taxi`, `traffic_cone`, `garden_gnome`), close substitutes, and objects with no mesh. The owner picks which missing meshes get built.

### Budget
Measure triangles for Park City's own placement counts, including the light client-side objects (`ParkCityLight.luau`) and server parts (`ParkCityParts.luau`). Downtown's old ceiling no longer limits anything; Park City needs its own, set from a real measurement.

### Build order
Stage it so the first stage is a build the owner can play: the park zone dressed with existing meshes. Then suburbs, then the city, each ending playable. Park City is generated from one layout file (`scripts/park_city_layout.py`): change the script, never the generated world modules or the JSON. If a stage changes the layout, the owner approves the rendered maps first.

### Must be solved
- Big balls in the city: a late ball should tear through the core with no stuck moments.
- A finale: the biggest landmarks must be edible by a good run.
- Twelve starters: spawns stay stocked and do not block each other.
- The edge of the map must read as a place.
- `winter`: dark ploughed roads and snow on roofs and lawns, so it keeps its contrast.
- Budgets: at least 30 fps in Studio with 12 balls on unthrottled seconds.

### Tests
Lune: every placed object resolves to a mesh or a recorded stand-in, plus the map's playability floors. The pace test reports and never fails a feature on pace before the RC. Studio: no new console errors or warnings.

### Acceptance
- Gate 6: the owner approves fixed shots and a played build, in `city` and `winter`.
- `scripts/check.sh` exits 0, and Gate 2's Studio playtest and console read have run.

### Out of scope
Juice (004c), the people round (004d)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Coverage Mapping, Theme Wiring & Stage 1 Playable Park Zone (Priority: P1)

Before any new meshes are built, every object kind in Park City is mapped against the existing uploaded mesh catalogues (121 `ck_*` City Kit meshes, 99 `dt_*` Downtown meshes, and existing seasonal meshes) into a clear coverage report showing exact ID matches, close visual substitutes, and objects that currently have no mesh (which use recorded stand-ins until the owner selects which missing meshes to build). Park City is given an active theme (`winter` and `city`) so meshes receive their shared theme and signage atlases, lighting, and seasonal environment colours, with `winter` keeping high contrast through dark ploughed roads against snow-covered lawns and roofs. The first playable stage dresses the Park ring (including client-drawn light objects and server parts) and the outer map boundary so the owner can immediately play the park in both themes, with all 12 starter spawns stocked and unobstructed and the edge of the map reading as a believable place rather than a void.

**Why this priority**: Constitution Principle I requires staging large features so the first stage is a playable build for the owner. Without an active theme on Park City, no mesh receives its palette or fronts atlas, and without the coverage map the owner cannot choose which missing park/city meshes to commission.

**Independent Test**: Run the coverage check and start a run in Park City in both `city` and `winter` themes. Verify that every placed Park object resolves to an uploaded mesh (with its theme atlas applied) or an explicitly recorded stand-in, that all 12 spawns have stocked, non-overlapping starter crumbs, that the outer map boundary reads as a coherent perimeter, and that `winter` shows dark ploughed roads contrasting with snowy lawns and roofs.

**Acceptance Scenarios**:

1. **Given** the catalogue of Park City object definitions and the uploaded `ck_*` and `dt_*` meshes, **When** the coverage audit runs, **Then** every Park City object ID is classified as an exact match, a close substitute, or a recorded stand-in (with no mesh), and the report is saved in the feature directory for the owner to pick which missing meshes get built.
2. **Given** Park City as the active world, **When** its theme is set to `city` or `winter` via world data, **Then** every mesh object (both server parts and client-drawn light objects) loads with the active theme's palette or fronts atlas texture, lighting, and weather, and switching between `city` and `winter` requires only a data change.
3. **Given** Park City in the `winter` theme, **When** a player views the world, **Then** roads read as dark ploughed asphalt while lawns and building/prop tops carry snow accents and trim, preserving visual contrast between routes and surroundings.
4. **Given** Stage 1 (the Park ring dressed with existing meshes), **When** a player spawns at any of the 12 starter positions, **Then** park props (including client-side Tier 1–2 light objects and Tier 3+ park parts) render with their assigned meshes and theme colours, all 12 spawns remain stocked and separated so starters never block one another, and the outer edge of the map reads as a landscaped boundary rather than a raw drop-off.

---

### User Story 2 - Stage 2 Playable Suburbs & Ring Road Dressed with the City Kit (Priority: P1)

As a player grows out of the park across the Ring Road and into the four suburban/neighbourhood districts (Market Street and Roof Run, Car Park and Building Site, Terraces and Cottages, Station and Rail Yard), the grey-box blocks and plain parts are dressed with the uploaded City Kit (`ck_*`) and `dt_*` meshes—including varied houses, corner shops, market stalls, cafe sets, street furniture, vehicles, and construction props—generated deterministically from the single layout script. Every stage ends as a playable build.

**Why this priority**: The Ring Road and Neighbourhoods form the mid-game progression bridge (Tiers 3 to 5). Dressing them with the modular house, shop, street, and vehicle kit makes the outside-in progression read as a real town surrounding the central core.

**Independent Test**: Roll a ball (or use the Studio size tool) through the Ring Road and all four Neighbourhood districts in `city` and `winter`. Verify that houses, shops, street furniture, and vehicles use the mapped `ck_*` and `dt_*` meshes without adjacent identical building repeats on a street row, and that all routes (including the Roof Run, Car Park ramps, and Terrace lanes) remain clear and playable.

**Acceptance Scenarios**:

1. **Given** Stage 2 (Ring Road and Neighbourhoods), **When** the world is generated from the layout script, **Then** suburban houses, shop rows, street kit items, vehicles, and neighbourhood scenes resolve to their mapped `ck_*` and `dt_*` meshes (or recorded stand-ins), with varied building variants along streets.
2. **Given** a ball rolling through the Ring Road and Neighbourhood routes (Spokes, Market Street, Roof Run, Car Park ramps, Terraces, Station), **When** moving at its intended tier size, **Then** mesh collision bounds and placements leave all designed lanes, ramps, and rooftop gaps unobstructed.
3. **Given** any stage that modifies object positions or footprints in `scripts/park_city_layout.py`, **When** the layout is updated, **Then** the rendered SVG maps are regenerated first for owner approval before the generated world modules are accepted.

---

### User Story 3 - Stage 3 Playable City Core, Big-Ball Destruction & Edible Finale (Priority: P1)

In the final stage, the Downtown core and Plaza are dressed with the City Kit's mid-rises, towers, signage, meme slots, and landmarks. A late-game ball rolling at Tier 5 and Tier 6 (D 35 to D 100+) tears through the city core smoothly without getting snagged on static geometry, awkward collision hulls, or unabsorbable obstacles, and a strong run reaches the size needed to eat the biggest finale landmarks (such as the Glass Tower and major civic/skyline structures).

**Why this priority**: Delivering the core fantasy ("start tiny in a park, grow big enough to eat the city") requires the city centre to look like a real urban skyline and let a giant ball demolish it cleanly up to an edible finale.

**Independent Test**: Play a run into late-game sizes (D 35 to D 100+) in Downtown. Confirm that mid-rises, towers, shop fronts, billboards, and landmarks render with their `ck_*` / `dt_*` meshes and fronts atlas, that a giant ball rolls through Downtown streets and blocks without getting wedged or stuck, and that a good run can reach the threshold to eat the finale landmarks.

**Acceptance Scenarios**:

1. **Given** Stage 3 (Downtown core and Plaza), **When** the world loads in `city` or `winter`, **Then** towers, mid-rises, storefronts, billboards, `slot.meme` placements, and plaza landmarks render with their theme and fronts atlases, and the Plaza landmark swaps by theme (`city` vs. `winter`) purely via data.
2. **Given** a Tier 5 or Tier 6 ball rolling through the Ring Road, Neighbourhoods, and Downtown core, **When** it sweeps through streets and building blocks, **Then** it experiences zero stuck or wedged moments against static geometry, kerbs, ramps, or collision hulls.
3. **Given** a skilled player's 4-minute run on Park City, **When** they reach late-game Skyline tier sizes, **Then** the biggest landmarks (including the Glass Tower and Tier 6 skyline structures) are absorbable and edible as the run's finale.

---

### User Story 4 - Park City Triangle Budget & 12-Ball Performance Verification (Priority: P2)

Park City's triangle cost is measured directly from its own placement counts—combining server-side parts (`ParkCityParts.luau`) and the client-side drawn window of light objects (`ParkCityLight.luau` within the camera draw radius and pool cap)—and recorded as Park City's own scene triangle ceiling, replacing Downtown's obsolete N10 ceiling. In a 12-ball Studio benchmark, Park City holds at least 30 fps on every unthrottled second while staying under the 2,000 server part budget.

**Why this priority**: Mobile-first performance (Constitution Principle VI) requires a real, measured budget for the active world and verified 30+ fps performance with 12 balls.

**Independent Test**: Run the Park City triangle budget calculation test in Lune and the 12-ball heavy-scene benchmark in Studio. Verify that unculled and culled triangle totals are measured and enforced against Park City's ceiling, server parts stay under 2,000, and every unthrottled second is at or above 30 fps.

**Acceptance Scenarios**:

1. **Given** Park City's placements (`ParkCityParts.luau` and `ParkCityLight.luau`) and `art/export/manifest.json`, **When** the scene triangle budget is computed, **Then** it measures both total placements and the worst-case visible client window (accounting for `lightDrawRadius`, `lightPoolCap`, and `cullTierDelta`) and enforces Park City's own ceiling instead of Downtown's retired ceiling.
2. **Given** 12 balls rolling in a dressed Park City server in Studio, **When** frame rate and part counts are sampled per second, **Then** active server parts remain below 2,000 and every unthrottled second is at or above 30 fps (with any 15 fps background-throttled seconds reported separately).

---

### User Story 5 - Visual Gate (Gate 6) Shots & Owner Play Approval in `city` and `winter` (Priority: P2)

Fixed camera shots of the dressed Park City map are captured in both `city` and `winter` themes across all key views (the four park quarter spawns, Duck Island, Hedge Maze, Roof Run, Car Park, Plaza, Giant Oak, map edge, and high overview) and presented on the pull request for the owner to inspect and playtest before merge.

**Why this priority**: Constitution Principle I and Quality Gate 6 require visual proof and owner approval of fixed shots and a played build in both `city` and `winter` before a world-art/map feature can merge.

**Independent Test**: Confirm all fixed shots exist for both `city` and `winter` themes, that Gate 2's Studio playtest and console check pass with zero new warnings or errors, and that the owner's review is recorded in `playtest.md`.

**Acceptance Scenarios**:

1. **Given** the dressed Park City world, **When** the fixed camera shots are taken in `city` and `winter`, **Then** every required shot is saved in the feature folder and shown on the pull request.
2. **Given** the fixed shots and the playable build, **When** the owner reviews the images and plays Park City in `city` and `winter`, **Then** their approval (or requested adjustments) is recorded in `playtest.md` before the pull request merges.

---

### Edge Cases

- **Client-Side Light Objects Using Meshes**: Tiers 1 and 2 in Park City (`ParkCityLight.luau`) are pooled on the client (`LightField.luau`) rather than spawned as server parts. When a light object kind maps to a mesh (`ck_*`, `dt_*`, or Snow Village mesh), the client pool must display that mesh with its active theme atlas and scale it to the object's dimensions without exceeding `Config.lightPoolCap` or stalling frame rate when recycling pool slots.
- **Dimension & Aspect Differences Between Layout Objects and Kit Meshes**: A Park City object's layout `dims` (`{L, W, H}`) and a mapped `ck_*` or `dt_*` mesh's authored proportions may differ. Scaling and collision must preserve the layout's gameplay bulk, edibility threshold (`needsD`), and lane clearance so swapping a stand-in for a mesh never blocks a path or changes absorb rules unexpectedly.
- **Objects With No Existing Mesh**: Any Park City object kind that has no exact match or close substitute in the uploaded mesh set must use an explicitly recorded stand-in (shape and theme palette `w-*` role) with zero runtime warnings spam, while being listed in the coverage report for the owner to decide which missing meshes to build.
- **Big Balls in Tight Urban Spaces**: Static geometry blocks (kerbs, ramps, elevated decks, Sky Rail supports, tunnel roofs) and Tier 5–6 building collisions can snag a D 35–100+ ball if steps are sharp or hulls protrude. High-tier collision fidelity and static block transitions must allow large balls to roll smoothly over low kerbs and eat buildings cleanly upon reaching their required diameter.
- **Map Edge Readability**: At `halfExtent = 500` (and `outerHalfExtent = 620`), the outer boundary must read visually as a continuous perimeter (such as perimeter trees, hedges, fencing, water/shore, or horizon framing inside the scenery bound) rather than a flat slab ending in empty sky, while keeping balls inside the playable square.
- **Single Source of Truth for Layout Changes**: Park City is generated from `scripts/park_city_layout.py` → `docs/design/maps/park-city-layout.json` → `scripts/park_city_world.py`. Hand-editing `ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau`, or `park-city-layout.json` is forbidden; any layout change must pass the 0-overlap, park coverage (≤ 5% far from food per quarter), and budget checks, and have its regenerated SVG maps approved by the owner.

## Requirements *(mandatory)*

### Functional Requirements

#### Coverage & Content Mapping

- **FR-001**: The feature MUST produce a complete coverage report mapping every object ID in Park City (`src/shared/Content/Worlds/ParkCity.luau`) against the uploaded `ck_*` City Kit (`src/shared/Content/CityKit.luau`), `dt_*` Downtown meshes, and existing world meshes in `src/shared/Assets.luau`, classifying each object into one of three buckets:
  1. **Exact match** (shares its ID or exact subject with an existing kit/world mesh, e.g., `taxi`, `traffic_cone`, `garden_gnome`);
  2. **Close substitute** (maps cleanly to an existing uploaded mesh of matching role and silhouette);
  3. **No mesh / recorded stand-in** (uses a themed stand-in part with a defined `w-*` palette role and shape until the owner chooses which missing meshes get built).
- **FR-002**: Every placed object in Park City (both in `ParkCityParts.luau` and `ParkCityLight.luau`) MUST resolve in `scripts/park_city_world.py` / `ParkCity.luau` to either a valid uploaded mesh key in `src/shared/Assets.luau` or an explicitly recorded stand-in entry, verified by a Lune unit test.
- **FR-003**: `CityKit` objects and `slot.meme` dressing slots MUST be integrated into Park City's generated world data so that Park City places the uploaded `ck_*` buildings, street kit, park kit, suburb props, vehicles, shop fronts/billboards (`atlas = "fronts"`), and meme originals (`CityKit.notDefault` playground items remain excluded unless explicitly named).

#### Theme Support & Winter Contrast

- **FR-004**: Park City MUST define `activeThemeId` (default `"winter"`), `supportedThemes = { "winter", "city" }`, and `themeBindings` in its generated world definition so that `Worlds.luau` and `ObjectVisual.luau` resolve the active theme's palette atlas, fronts atlas, lighting, weather, music, hero variants, and dressing slots.
- **FR-005**: In the `winter` theme, Park City's environment and static geometry palette MUST maintain clear visual contrast: roads and carriageways use dark ploughed asphalt/slush roles (`w-asphalt` / `w-road-slush`), while lawns, park ground, and roof/hedge tops use snow roles (`w-grass` snow, `w-snowcap` / `w-season`), preventing white-on-white washout.
- **FR-006**: Switching Park City between `"winter"` and `"city"` MUST be a data-only change to `activeThemeId` (Constitution Principle VII), with zero code changes required.

#### Client-Side Light Object Meshes

- **FR-007**: Client-side light objects (`src/client/LightField.luau`) MUST render using each object definition's visual template (`ObjectVisual.build`, including `MeshPart` templates with the active theme's texture atlas and stand-in parts with theme palette `w-*` colours) instead of untextured tier-coloured block primitives, while preserving pooling and the `Config.lightPoolCap` limit.

#### Playability, Map Edge & Finale

- **FR-008**: All 12 starter spawns MUST remain stocked with their 20 D 1-edible doorstep crumbs and starter ladders, separated by at least 270 studs with no static obstacle taller than 1 stud within 15 studs of any spawn, so 12 concurrent starters never block or starve one another.
- **FR-009**: The outer edge of the Park City map (`halfExtent = 500` to `outerHalfExtent = 620`) MUST be dressed so that it reads visually as a coherent place and perimeter from ground and mid-game camera heights, rather than an abrupt flat plate edge.
- **FR-010**: Late-game balls (Tiers 5 and 6, D 35 to D 100+) MUST be able to roll through the Ring Road, Neighbourhoods, and Downtown core without getting stuck or wedged on static geometry, kerbs, ramps, or building/prop collisions.
- **FR-011**: The largest finale landmarks in Park City (including the Glass Tower and Tier 6 skyline landmarks) MUST be absorbable and reachable by a skilled run within the 4-minute run duration.

#### Budgets, Single-Source Pipeline & Staged Build Order

- **FR-012**: A Park City triangle budget measurement MUST be implemented in Lune, computing triangle counts from `art/export/manifest.json` across Park City's actual placements (`ParkCityParts.luau` and the visible client window of `ParkCityLight.luau`) and enforcing Park City's own measured triangle ceiling in `Config.Budgets` / test gates in place of Downtown's retired ceiling.
- **FR-013**: All map, object, and environment changes to Park City MUST flow from `scripts/park_city_layout.py` → `docs/design/maps/park-city-layout.json` and `docs/design/maps/*.svg` → `scripts/park_city_world.py` → generated Luau modules (`ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau`, `ParkCityStrings.luau`). Never edit the generated JSON, SVGs, or Luau world modules by hand (Constitution Principle VII).
- **FR-014**: Work MUST be staged so that Stage 1 delivers a playable build with the Park zone (and map edge) dressed with existing meshes, Stage 2 dresses the Suburbs / Neighbourhoods and Ring Road, and Stage 3 dresses the Downtown City core and finale. Each stage MUST end playable and pass `scripts/check.sh`. If any stage alters the layout geometry or placements in `scripts/park_city_layout.py`, the regenerated SVG maps MUST be presented for owner approval first.
- **FR-015**: Automated Lune tests MUST verify that:
  1. Every placed object in Park City resolves to an uploaded mesh or a recorded stand-in;
  2. All playability floors hold (first pickup within 3 s at every spawn, no open-route food ladder gap > 1.25×, and park coverage with ≤ 5% of each park quarter more than 40 studs from food);
  3. Growth pace is measured and reported across the 12 spawns without failing the feature on pace windows before the RC (Constitution Principle I).
- **FR-016**: A Studio playtest (Gate 2) and 12-ball heavy-scene benchmark MUST run in Park City, verifying zero new console errors or warnings, fewer than 2,000 active server parts, and at least 30 fps on every unthrottled second.
- **FR-017**: Fixed camera shots of Park City in both `city` and `winter` themes MUST be produced and approved by the owner alongside a played build before merge (Constitution Gate 6).

### Key Entities

- **Object Coverage Map**: The complete mapping of Park City's object kinds to `ck_*` meshes, `dt_*` meshes, Snow Village meshes, or recorded stand-in definitions (with `w-*` palette role, fallback shape, and rationale), used both by `scripts/park_city_world.py` and by the owner to pick which missing meshes to build next.
- **Park City Theme Binding**: The data configuration on `ParkCity.luau` (`activeThemeId`, `supportedThemes`, `themeBindings`, and themed environment block palette) connecting Park City to `Themes.winter` and `Themes.city`, the shared gradient and fronts atlases, weather, lighting, and dressing slots (`slot.meme`, theme landmark).
- **Park City Triangle Budget**: The measured scene triangle count and ceiling for Park City, combining server part placements (`ParkCityParts.luau`) and the client's active light-object draw window (`ParkCityLight.luau` capped by `lightDrawRadius` and `lightPoolCap`).
- **Staged Dress Pass**: The three playable increments—Stage 1 (Park & Map Edge), Stage 2 (Ring Road & Suburbs/Neighbourhoods), and Stage 3 (Downtown City Core & Finale)—generated from `scripts/park_city_layout.py` and `scripts/park_city_world.py`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of placed object kinds in Park City (across all server placements and client light objects) are accounted for in the coverage report and resolve in Lune tests to either an uploaded mesh ID in `src/shared/Assets.luau` or an explicitly recorded stand-in with a valid theme palette role.
- **SC-002**: 100% of Park City mesh objects render with the active theme's texture atlas (`palettes` or `frontsAtlases`) in both `city` and `winter`, and switching `activeThemeId` between `"winter"` and `"city"` requires zero code changes and produces dark ploughed roads contrasting with snowy lawns and roofs in `winter`.
- **SC-003**: Across all 3 build stages (Park, Suburbs/Neighbourhoods, City Core), `scripts/park_city_layout.py --check`, `scripts/park_city_world.py --check`, and `scripts/check.sh` exit `0` with 0 layout overlaps, ≤ 5% of each park quarter more than 40 studs from food, first pickup ≤ 3 s on all 12 spawns, and zero open-route ladder gaps > 1.25×.
- **SC-004**: In a late-game traversal check (D 35 to D 100+) across the Downtown core and Spokes, a ball rolls through streets and absorbs eligible buildings and the finale landmarks (including the Glass Tower at D ≥ 96) with 0 stuck or wedged incidents.
- **SC-005**: Park City's scene triangle budget is measured from its own server and client light-object placements and enforced by automated tests; with 12 balls in Studio, server part count stays below 2,000 and frame rate holds at least 30 fps on 100% of unthrottled seconds, with 0 new console errors or warnings.
- **SC-006**: Fixed camera shots of the dressed Park City map in both `city` and `winter` themes are committed to the feature directory, presented on the pull request, and approved by the owner after playing the build (Constitution Gate 6).

## Scope & Boundaries

### In Scope

- Mapping all Park City object IDs against `CityKit` (`ck_*`), Downtown (`dt_*`), and existing uploaded meshes, and documenting exact matches, close substitutes, and recorded stand-ins for owner selection.
- Giving Park City `activeThemeId`, `supportedThemes` (`"winter"`, `"city"`), `themeBindings` (including `slot.meme` and the Plaza theme landmark), and themed environment block palettes with high-contrast `winter` roads, roofs, and lawns.
- Updating `LightField.luau` so client-side Tier 1–2 light objects use `ObjectVisual` mesh/stand-in templates with theme colours and atlases.
- Staging the dress pass in three playable increments (Stage 1: Park & map edge; Stage 2: Suburbs/Neighbourhoods & Ring Road; Stage 3: Downtown core & finale) via `scripts/park_city_layout.py` and `scripts/park_city_world.py`.
- Ensuring big balls (Tier 5–6) tear through the city core without getting stuck, finale landmarks are edible on a strong run, all 12 spawns stay stocked and unobstructed, and the map edge reads as a place.
- Measuring and enforcing Park City's own triangle budget across `ParkCityParts.luau` and `ParkCityLight.luau`, and running the 12-ball 30+ fps Studio benchmark and Gate 2 playtest.
- Producing fixed shots in `city` and `winter` for Gate 6 owner approval.

### Out of Scope

- Juice pass (visual/audio polish effects beyond world art, backlog item `004c`).
- Outside-people playtest round (`004d`, which runs on the release candidate per Constitution Principle I).
- Authoring new Blender meshes before the owner selects which missing meshes from the coverage report should be built (recorded stand-ins hold in the meantime per Constitution Gate 3).
- Active traversal mechanics behaviour (rails, boost/bounce/spring pads, catapults, water/ice physics) beyond keeping their placeholders and routes clear, unless already enabled by their feature flags.

## Assumptions

- **Feature Numbering**: Sequentially numbered `014-park-city-art` following `013-city-asset-kit`. Later backlog items that still say "Downtown" (`005`, `006a`, `007`, `009`, `012`, `013`) refer to the active world, now Park City.
- **Object Count Wording**: The prompt notes "roughly 370 object ids in `src/shared/Content/Worlds/ParkCity.luau` against the kit (`src/shared/Content/CityKit.luau`) and the `dt_*` meshes"; specifically, `ParkCity.luau` currently defines 219 object IDs and `CityKit.luau` defines 121 object IDs (with 16 exact ID overlaps, totaling 324 unique IDs across the two catalogues, plus the 99 `dt_*` mesh keys). The coverage report will map every object in `ParkCity.luau` and every unused `CityKit` / `dt_*` mesh so all ~370+ catalogue entries are accounted for.
- **Default Active Theme**: Park City defaults to `activeThemeId = "winter"` (Holiday City launch theme) and supports `"winter"` and `"city"`, matching `Downtown` and `SnowVillage` so the January switch to `"city"` remains a one-line data change.
- **Finale Landmarks Edibility**: A good run reaches the Skyline tier (D 80–100+) where the Glass Tower (needs D 96) and Tier 6 skyline landmarks are edible. If the current layout's Tier 5–6 food count or `growthK` prevents a skilled route from reaching D 96+ to eat the Glass Tower and finale landmarks, the layout/world data will be adjusted within `scripts/park_city_layout.py` so the finale is genuinely achievable by a good run while keeping the pace test's playability floors green.
