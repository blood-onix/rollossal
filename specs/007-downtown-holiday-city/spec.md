# Feature Specification: Downtown Launch World — Core City Kit, Holiday City (`winter`), and Sunny City (`city`)

**Feature Branch**: `007-downtown-holiday-city`

**Created**: 2026-10-31

**Status**: Draft

**Input**: User description: "Part 2 of the Downtown work (docs/design/speckit-prompt.md): Downtown, the first city level, launching in December as Holiday City and switching to Sunny City in January. It replaces Snow Village as the launch world. Design: docs/design/02-city-assets.md, 03-city-level.md, 07-holiday-city.md, 05-roblox-limits.md, 06-art-style.md. Constitution: IV, VI, VII, IX, XI. Depends on 004a (theme system, atlas pipeline) and 004b (marker spots for boosters and traps)."

## Owner Approval Gate *(Constitution Principles I, IV, V, VI, VII, IX, XI & Governance)*

- **Constitution v2.0.0 Alignment (Ratified 2026-10-28, commit `262ecff`)**:
  - **Principle IV (Safe for Everyone — Target Rating: Minimal)**: Zero absorbable people or real/live animals. Snow Village's `cat` and `dog` are retired with Snow Village; Downtown contains no absorbable animals (ambient pigeons are non-absorbable scenery capped at `<= 8` per district that fly off when a ball approaches, and Holiday City's reindeer is a glowing wire-frame lawn decoration). Zero weapons, alcohol-like bottles, gambling imagery, crashed/burning/upside-down vehicles, real brands, logos, flags, landmarks, or words on textures (pictograms only).
  - **Principle VII (Content Is Data)**: Downtown is authored as pure content data (`src/shared/Content/Worlds/Downtown.luau`) on the existing `WorldDef` and `ThemeBinding` schemas from Features 004, 005, and 006. Switching between Holiday City (`winter`) for December launch and Sunny City (`city`) for January is a data-only change to `activeThemeId` shipped in a release—never a code change or a player-visible date check/countdown.
  - **Principle XI (Stylised-Real Asset Pipeline)**: Every core, hero, and holiday mesh is built in Blender (`art/source/*.blend` -> `art/export/*.fbx`) in real-world proportions with a 1-segment silhouette bevel, smooth shading on round parts, sharp edges on boxy parts, UVs mapped inside a single cell or trim strip of the shared `1,024 × 1,024` px theme gradient atlas, and a single material. Ground, roads, kerbs, plazas, and lawns are plain `Part`s with `SmoothPlastic` and `w-*` palette colours (no Roblox `Terrain`).
- **Grey-Box Gate Before Art (Constitution Principle I)**: Downtown loads first with themed stand-in parts (`fallback` shapes colored by `w-*` roles) so the 5-ring layout, gates, shortcuts, climbing routes, marker spots, and 4-minute growth pacing are tuned and verified via agent-driven Studio bot runs plus the owner playing and signing off in `specs/007-downtown-holiday-city/playtest.md` before final Blender meshes are swapped in.
- **Locking Per-Tier Triangle Budgets (Constitution Principle VI & XI)**: The provisional stylised-real triangle budgets `{ 500, 700, 1500, 3500, 5000 }` from Feature 005 (`004a`) are validated and locked against a measured `>= 30 fps` capture at `640 × 360` with 12 concurrent balls in Holiday City (`winter`, the heaviest theme).
- **Theme Music Tracks (Confirmed in `src/shared/Assets.luau`, commit `2005cef`)**: `Assets.sounds.musicWinter` (`rbxassetid://114423108310478`) and `Assets.sounds.musicCity` (`rbxassetid://80565841497538`) are already configured and wired to `Themes.winter` and `Themes.city`; the owner may swap the asset ID in `src/shared/Assets.luau` at any time without code or content-schema changes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Growing From Doorstep to Skyline in a 5-Ring City Layout With Stand-In Parts First (Priority: P1)

Up to 12 players spawn at shop doorsteps around the edge of **Downtown**, a `600 × 600` stud playable city (`halfExtent = 300`) surrounded by an `800 × 800` stud outer skyline envelope (`outerHalfExtent = 400`) and a western Hub (`center = { x = -460, z = 0 }`). From second one, every spawn doorstep has a clear sightline to a Tier 5 landmark (**Ferris Wheel** or **The Glass Tower**). The city is organized in five concentric/functional rings that match the five growth tiers (`minDiameters = { 2, 5, 12, 30, 70 }`, `absorbRatio = 0.4`, ~`1,400` total placements split roughly `480 / 380 / 280 / 180 / 60` by tier):
- **Ring 1 — Stoops and Alleys (12 spawn pockets, Tier 1 Pocket, ball `2–5` studs)**: Each of the 12 doorstep spawns has `40` Pocket objects (`0.3–1.5` studs: bottle caps, soda cans, coffee cups, smartphones, takeout boxes, Rubber Duck in Sunglasses, The Lost Sneaker) within `10` studs of the spawn point so a player gets their first pickup within `5` seconds and reaches Tier 2 by about `0:30`. Kerbs and stoops require the Tier 1 variable jump (`006-jump-boosters-traps`).
- **Ring 2 — Sidewalks along Market Street and Side Streets (Tier 2 Sidewalk, ball `5–12` studs)**: Clusters of traffic cones, fire hydrants, wheelie bins, e-scooters, parking meters, Spinning Office Chairs, and Pizza Box Towers (`1.6–4.0` studs) at every corner. Narrow `4`-stud alleys between buildings and a storm-drain tunnel under Market Street serve as shortcuts that only Tier 1–2 balls (`diameter < 5` studs) fit through.
- **Ring 3 — The Park (west), The Construction Site (north-east), and The Car Park (south-east) (Tier 3 Street, ball `12–30` studs)**: Three mid-run playgrounds (`4.0–10.0` studs: bikes, mopeds, benches, young street trees, Arcade Cabinets, Vending Machines, Inflatable Tube Guys), featuring lawns and a pond in the Park, scaffolding ramps and a container stack in the Construction Site, and a climbable multi-level spiral ramp with a top deck in the Car Park.
- **Ring 4 — Market Street Roadway and The Plaza (centre) (Tier 4 Block, ball `30–70` studs)**: Parked hatchbacks, taxis, delivery vans, city buses, bus shelters, kiosks, the Plaza fountain, Monster Trucks, and the Donut Food Truck (`10.0–25.0` studs). Each ring is gated by absorbable objects one tier up (Tier 2 bollards around the Plaza, Tier 3 hedges and park fence, Tier 4 parked vans lining Market Street) so former walls become food as the ball grows.
- **Ring 5 — The Skyline Block (north) and The Waterfront (south) (Tier 5 Skyline, ball `70–150` studs)**: Corner shop rows, townhouses, apartment blocks, cinema, EV charging station, Rocket Water Tower, Tower Crane, Ferris Wheel, and The Glass Tower (`25.0–60.0` studs).

Before any 3D meshes are required, the entire Downtown layout loads with themed stand-in parts (`SmoothPlastic` environment blocks and object fallback primitives colored by `w-*` tokens) so layout, sightlines, shortcuts, climbing routes, and 4-minute growth pacing (`0:05` first pickup, `0:30` Tier 2, `1:30` Tier 3, `2:45` Tier 4, and `80`-stud 3-star Tier 5 reachability within `±20` s) are proven and signed off in grey box first.

**Why this priority**: Enforces Constitution Principle I (Fun Is Proven in Grey Box First) and Principle VI (Mobile First 5-second pickup, 30-second first tier banner, and < 2,000 active parts) on the launch map before locking 3D art production.

**Independent Test**: Can be verified with `Assets.meshes` entries empty (stand-in mode) by running Lune layout/pacing tests (`scripts/check.sh`) and an agent-driven Studio bot playtest across all 12 spawn slots, confirming the 5-ring progression, `40` Tier 1 objects within `10` studs of each spawn, `±20` s pacing targets, working shortcuts/ramps/markers, active parts `< 2,000`, and owner sign-off in `specs/007-downtown-holiday-city/playtest.md`.

**Acceptance Scenarios**:

1. **Given** Downtown loaded in stand-in mode (`Config.Flags.Downtown = true`, default world `downtown`), **When** a player or bot spawns at any of the 12 doorstep spawn points at diameter `2` studs, **Then** at least `40` Tier 1 Pocket objects lie within `10` studs of that spawn point, a Tier 5 landmark (`ferris_wheel` or `glass_tower`) is visible along the spawn's sightline corridor, the first pickup occurs by `0:05`, and Tier 2 (`diameter >= 5`), Tier 3 (`diameter >= 12`), and Tier 4 (`diameter >= 30`) are reached at `0:30 ± 20 s`, `1:30 ± 20 s`, and `2:45 ± 20 s` respectively, with strong runs reaching Tier 5 (`diameter >= 70` / 3 stars at `80`) by `4:00`.
2. **Given** a ball at Tier 1 (`diameter < 5` studs), **When** the player navigates Downtown's `4`-stud narrow alleys, storm-drain tunnel under Market Street, kerbs/stoops (using the Tier 1 jump), Car Park spiral ramp, and Construction Site scaffolding ramps, **Then** the Tier 1–2 ball fits cleanly through the `4`-stud alleys and drain tunnel while a Tier 3+ ball (`diameter >= 5` studs) is physically blocked from entering those shortcuts, and balls can climb the Car Park spiral ramp and Construction Site scaffolding to their top decks.
3. **Given** Downtown's `environment.markers` and `keepOutAreas`, **When** the world initializes in Studio, **Then** all starter booster spots (`dash`, `magnet`, `spring`, `shield`, `slick_trail`) and trap spots (`slick`, `bumper`, `slow`, `sweeper`) from Feature 006 spawn and function, and all 5 seeded golden-object hiding spots (bus-shelter roof, car park top deck, inside the storm-drain tunnel, crane counterweight, behind the Ferris Wheel) are present in world data and clear of any placement or overlay overlap.

---

### User Story 2 - Holiday City (`winter`) Launch Theme & Data-Only Switch to Sunny City (`city`) (Priority: P1)

Downtown launches in December with `activeThemeId = "winter"` (**Holiday City**) and switches to `activeThemeId = "city"` (**Sunny City**) in January as a pure content-data change:
- **Holiday City (`winter`, December Launch)**:
  - Applies the `winter` gradient atlas (`snow` / `w-season` white caps on every core prop's top face, snowy pavements, warm amber `w-glass` windows, holiday red and gold accents), golden-hour lighting (`clockTime` ~`16.5`, warm fog starting at `150` studs), camera-attached snowfall (`<= 40` particles, disabled with `Reduce motion`), and the holiday music track (`Assets.sounds.musicWinter`).
  - Fills the 5 seasonal dressing slots with festive props: `slot.small` -> **Bauble** (`0.6`), `slot.medium` -> **Gift box** (`2.0`), `slot.yard` -> **Snowman** (`8.0`, traffic cone nose), `slot.street` -> **Sleigh** (`15`, parked empty like a car), and `slot.landmark` -> **Mega Tree** (`45`, lit tree in the Plaza fountain).
  - Layers ~`150` theme overlay placements (carved from slot and Tier 1–2 counts so total placements remain `<= 1,400` and all keep-outs stay clear): a Christmas market of `6` market stalls, a cocoa cart, and gift piles around the Mega Tree in the Plaza; non-absorbable lit garlands strung across Market Street and absorbable wreaths on shop doors; fairy-light bulbs, baubles, mini gifts, and gingerbread cookies at the doorsteps; a packed-snow sledding slope with wooden sleds and an absorbable frozen pond **Ice rink** (`40`) in the Park; and absorbable snow piles (`6.0`) and a parked **Snowplough** (`22`) at the street edges.
  - Maps two hero variants: **Donut Food Truck** (`18`) -> **Cocoa Truck** (`18`, giant mug on the roof) and **The Glass Tower** (`60`) -> **The Glass Tower, bow-wrapped** (`60`, giant red bow).
  - Adds the **Downtown: Holiday** Collection Book page (`book.page.downtown.winter.name`) tracking all theme-only Holiday objects, with no elves, plush toys, or cartoon Santa (the **Light-up Reindeer** is a glowing wire-frame lawn decoration).
- **Sunny City (`city`, January Switch)**:
  - Setting `activeThemeId = "city"` in `Downtown.luau` switches the palette atlas to `city`, lighting to bright summer day (`clockTime = 13`), weather to `"none"`, music to `Assets.sounds.musicCity`, removes all `winter` overlays and hero variants, and fills the 5 dressing slots with Sunny City props: **Ice lolly** (`slot.small`), **Beach ball** (`slot.medium`), **Paddling pool** (`slot.yard`), **Ice-cream truck** (`slot.street`), and **Giant Inflatable Duck** (`slot.landmark`). If the 5 Sunny City dressing meshes are not yet uploaded, `city` runs cleanly with its palette, lighting, and themed stand-in parts for those 5 slots (with mesh uploads finishing in Feature 011).
  - The **Downtown: Holiday** book page remains visible in the Collection Book with all discovered entries preserved and a localised returning-next-December label (no countdown timer, never "limited").

**Why this priority**: Delivers the December launch theme and proves Constitution Principle VII (Content Is Data) on the full production map so the January season switch requires zero code edits and keeps all 12-player servers on one shared map.

**Independent Test**: Can be tested by running Lune validation and Studio bot playtests with `Downtown.activeThemeId = "winter"` and `Downtown.activeThemeId = "city"`, verifying that both themes load from the same base layout, hit the `±20` s pacing targets, keep all gates/shortcuts/markers/sightlines clear, and preserve the **Downtown: Holiday** book page across the switch.

**Acceptance Scenarios**:

1. **Given** `src/shared/Content/Worlds/Downtown.luau` with `activeThemeId = "winter"`, **When** the world resolves and loads in Studio, **Then** all 20 Holiday City objects (`5` slots, `13` overlay objects, `2` hero variants) and non-absorbable holiday scenery (Market Street garlands and Park sledding slope) appear in their designated districts, total placements stay `<= 1,400`, `clockTime` is `16.5`, snowfall and winter music play, and the **Downtown: Holiday** book page lists the holiday theme-only objects.
2. **Given** `activeThemeId` in `Downtown.luau` is changed from `"winter"` to `"city"`, **When** the world resolves and loads in Studio without any code changes, **Then** all `winter` overlays, hero variants, and holiday slot objects are removed, the 5 dressing slots resolve to `ice_lolly`, `beach_ball`, `paddling_pool`, `ice_cream_truck`, and `giant_duck`, base placements stay at identical coordinates, bot runs hit the `±20` s pacing targets in both `"winter"` and `"city"`, and the **Downtown: Holiday** book page stays visible as a returning seasonal page with saved progress intact.

---

### User Story 3 - Full Stylised-Real 3D Mesh Catalogue & 30 FPS Reference Phone Lock (Priority: P2)

All 74 core Downtown absorbable objects (including 2–3 hero props per tier and every top face mapped to `w-season`), the 20 Holiday City objects (`5` winter slots, `13` winter overlay objects, `2` winter hero variants), static background/scenery meshes (such as the far skyline and holiday garlands), and any ready Sunny City slot meshes are modelled in Blender (`art/source/`) and exported (`art/export/*.fbx`) using the stylised-real pipeline from Feature 005:
- Real-world proportions with only the single hero twist exaggerated by at most `10%`, 1-segment silhouette bevel (`4–8%`), smooth-shaded round parts, sharp hard edges, split normals, single `Palette` material, and every face's UVs inside one `128 × 64` px gradient cell or `1,024 × 64` px trim strip of the `1,024 × 1,024` px theme atlas.
- Every mesh passes moderation and Minimal-rating rules: water/soda bottles have screw caps and colour bands (no long glass necks), puzzle cubes and game controllers use generic shapes, signs use pictograms with zero text, vehicles are upright and intact, and ambient pigeons (`<= 8` per district) flutter away when approached and are never absorbable.
- In Holiday City (`winter`, the heaviest theme) at full placement density with 12 balls at `640 × 360`, the game holds at least `30 fps` and stays under `Config.Budgets.maxActivePartsPerServer` (`2,000`), locking the per-tier triangle budgets (`500 / 700 / 1,500 / 3,500 / 5,000`) in `src/shared/Config.luau`.

**Why this priority**: Completes the visual transformation from Snow Village's flat-shaded toy look to the 16+-ready stylised-real city look while guaranteeing 30 fps mobile performance (Constitution Principles IV, VI, IX, XI).

**Independent Test**: Can be verified via `art/scripts/export_all.py` and `scripts/check.sh` (asserting UV bounds, single material, split normals, and triangle budgets across all Downtown and Holiday City `.fbx` exports, plus complete English and Spanish strings in `Strings.luau`) and a 12-ball Studio playtest in Holiday City captured at `640 × 360` holding `>= 30 fps` with `< 2,000` active parts.

**Acceptance Scenarios**:

1. **Given** all exported `.fbx` meshes for Downtown's 74 core objects and 20 Holiday City objects in `art/export/`, **When** `art/scripts/export_all.py` and `scripts/check.sh` run, **Then** 100% of meshes pass triangle budgets (`<= 500 / 700 / 1,500 / 3,500 / 5,000` tris for Tiers 1–5), single-material and atlas cell/strip UV checks, and size tolerance (`±5%`), and every uploaded asset ID is recorded in `src/shared/Assets.luau`.
2. **Given** Holiday City (`winter`) loaded in Studio with all meshes, overlays, snowfall, and 12 active balls rolling through the map, **When** captured at `640 × 360` and profiled over a run, **Then** unthrottled frame rate holds `>= 30 fps`, active server parts remain `< 2,000` (`Config.Budgets.maxActivePartsPerServer`), zero `SurfaceAppearance`, semi-transparent world parts, or per-prop lights exist, and the per-tier triangle budgets in `Config.Budgets.meshTriangles` are locked and recorded in `specs/007-downtown-holiday-city/playtest.md`.
3. **Given** every core, holiday, and Sunny City object name, tier headline, and book page string in `src/shared/Localization/Strings.luau`, **When** Lune localization tests run, **Then** every key has non-empty, deadpan shop-label translations in both English (`en`) and Spanish (`es`), and zero textures or signs contain words.

---

### Edge Cases

- **Rollback to Snow Village or GreyBoxRoom (`Config.Flags.Downtown`)**: Setting `Config.Flags.Downtown = false` in `src/shared/Config.luau` MUST cleanly fall back to `SnowVillage` (and `SnowVillage = false` falls back to `GreyBoxRoom`), keeping existing unit tests and rollback paths intact without dead-code errors.
- **Saved Player Profiles After Default World Switch**: Existing player profiles created when `snow_village` was the default world MUST automatically have `"downtown"` unlocked via `Config.DefaultWorldsUnlocked` without requiring a destructive DataStore schema change or losing previously earned coins or book progress.
- **Base Tier Book Completion Across Themes**: Base tier pages (Tiers 1–5) for Downtown MUST include only the 74 core kit objects, and every one of the 74 core kit objects MUST appear in at least one base placement (even when `slot.*` placements swap by theme) so a player can reach 100% completion on Tiers 1–5 in both `winter` (Holiday City) and `city` (Sunny City).
- **Sunny City (`city`) Partial Mesh Readiness Fallback**: If any of the 5 Sunny City slot dressing meshes (`ice_lolly`, `beach_ball`, `paddling_pool`, `ice_cream_truck`, `giant_duck`) has `Assets.meshes[key] == ""` at release time, `ObjectVisual` MUST seamlessly render its themed stand-in part using its declared `w-*` palette role colour without console warnings or errors until Feature 011 uploads the remaining meshes.
- **Overlay Budget & Keep-Out Enforcement**: Holiday City adds ~`150` overlay placements (`6` market stalls, cocoa cart, gift piles, doorsteps crumbs, wreaths, park sleds, ice rink, snow piles, snowplough). Base placements (`~1,250`) plus `winter` overlays (`~150`) MUST stay `<= 1,400` (`maxPlacements`), and zero overlay zones or fixed placements may intersect any declared `keepOutAreas` (`gate`, `shortcut`, `sightline`, `marker`, including the 5 golden-object hiding spots).
- **Absorbable Parked Snowplough vs. Non-Absorbable Roaming Street Sweeper**: Holiday City's Tier 4 parked `snowplough` (`size = 22`) is an absorbable world object in `themeBindings.winter`, whereas the roaming `sweeper` hazard at `TrapSpot` markers is a non-absorbable municipal Street Sweeper (`006-jump-boosters-traps`); the two MUST use distinct IDs and visuals so players never confuse the trap with the Tier 4 pickup.
- **Ambient Pigeons Non-Absorbability & District Cap**: Ambient pigeons are strictly non-absorbable client-side scenery (`<= 8` per district, never registered in `WorldSpawner` or `Objects`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`) that flutter away when a ball approaches and respect `Reduce motion`.

## Clarifications

### Session 2026-11-01 (PR #8 review, round 1)
- Q: FR-005/FR-006 sizes differ from the code (`cocoa_cart`, `ice_lolly`, `paddling_pool`, `ice_cream_truck`); which wins? -> A: The code sizes (`6.5`, `0.6`, `8.0`, `15.0`) win, so each Sunny City slot object matches its Holiday City slot object in size and a theme switch never moves a base placement. FR-005 and FR-006 now state them, and `tests/unit/Downtown.test.luau` pins them.
- Q: Theme-scoped `growthK` override? -> A: Removed (review F8). The world's `growthK` is the only constant; the winter value equalled it, so nothing changes.
- Q: Garlands and sledding slope only in winter (F2), storm-drain tunnel blocking Tier 3+ balls from above (F5), and the other layout findings (F6, F7)? -> A: Deferred to backlog item 004f, where the layout is being redesigned. No fix in this feature; recorded in `playtest.md`.
- Q: Review round 2 re-raised F2 and F5 because the requirement text still says winter-only and Tier 3+ blocked. -> A: Fixed in code, no requirement change: garlands and slope moved to `themeBindings.winter.blocks` (built by `WorldBuilder` only for the active theme); tunnel walls raised from 3.8 to 5, then a 0.5 roof slab added on top (a held jump clears `0.85 x diameter`, so D of about 5.9 or more would clear 5-tall walls). A ball can still land on the roof, never inside; the wider layout stays in 004f. The other layout findings (F6, F7) stay in 004f.
- Q: The human checks of the review (pacing over 12 spawns, 640x360 capture, mesh look in Play, live Car Park and scaffolding traversal, sign-off)? -> A: Closed by owner decision and moved to 004f. No new bot runs.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Downtown World Data, Default World Switch & Core Kit (`src/shared/Content/Worlds/Downtown.luau`, `src/shared/Config.luau`, `src/shared/Worlds.luau`)

- **FR-001**: `src/shared/Config.luau` and `src/shared/Worlds.luau` MUST make **Downtown** the default launch world:
  - Add `Config.Flags.Downtown = true` and include `downtown = true` in `Config.DefaultWorldsUnlocked`;
  - When `Config.Flags.Downtown` is `true`, `Worlds.active` selects `src/shared/Content/Worlds/Downtown.luau` (`worldId = "downtown"`); when `Config.Flags.Downtown` is `false`, `Worlds.active` falls back to `SnowVillage` (if `Config.Flags.SnowVillage` is `true`) or `GreyBoxRoom`;
  - Snow Village remains in the repository only as the `Config` rollback path and theme-system unit-test fixture; its `cat` and `dog` props are not carried into Downtown.
- **FR-002**: `src/shared/Content/Worlds/Downtown.luau` MUST be a pure data module (zero Roblox APIs or `require` calls so Lune loads it directly) conforming to `WorldDef`:
  - `worldId = "downtown"`, `halfExtent = 300` (`600 × 600` stud play area), `outerHalfExtent = 400` (`800 × 800` stud outer envelope), `maxPlacements = 1400`, `starThresholds = { 20, 45, 80 }`, and a tuned `growthK` so 4-minute runs hit the pacing targets in both `winter` and `city`;
  - `activeThemeId = "winter"` for the December Holiday City launch, with `supportedThemes = { "winter", "city" }`;
  - `sizeTiers`: 5 ordered tiers with `minDiameters = { 2, 5, 12, 30, 70 }` (`absorbRatio = 0.4`):
    1. Tier 1 — **Pocket** (`ball 2–5` studs, objects `0.3–1.5` studs, coins `1–2`);
    2. Tier 2 — **Sidewalk** (`ball 5–12` studs, objects `1.6–4.0` studs, coins `3–5`);
    3. Tier 3 — **Street** (`ball 12–30` studs, objects `4.0–10.0` studs, coins `8–15`);
    4. Tier 4 — **Block** (`ball 30–70` studs, objects `10.0–25.0` studs, coins `20–40`);
    5. Tier 5 — **Skyline** (`ball 70–150` studs, objects `25.0–60.0` studs, coins `60–100`);
  - `objects`: the **74 core absorbable city object types** from `docs/design/02-city-assets.md` (`18` in Tier 1, `15` in Tier 2, `16` in Tier 3, `16` in Tier 4, `9` in Tier 5, including `2–3` hero props per tier: Tier 1 `rubber_duck_sunglasses`, `lost_sneaker`; Tier 2 `inflatable_flamingo`, `spinning_office_chair`, `pizza_box_tower`; Tier 3 `arcade_cabinet`, `vending_machine`, `inflatable_tube_guy`; Tier 4 `donut_food_truck`, `monster_truck`; Tier 5 `rocket_water_tower`, `ferris_wheel`, `tower_crane`, `glass_tower`), each with unique `id` and `bookId` (`"downtown.<id>"`), ascending tier coin values, `fallback` shape, and `role` (`w-*` palette token) so stand-in parts render in season colours before meshes are uploaded.

#### Part B: 5-Ring Layout, Gates, Shortcuts, Climbing Routes, Sightlines & Marker Spots (`src/shared/Content/Worlds/Downtown.luau`)

- **FR-003**: Downtown's `spawnPoints`, `zones`, `fixedPlacements`, and `environment.blocks` MUST implement the 5-ring layout from `docs/design/03-city-level.md` totaling ~`1,400` placements (with theme overlays included, rough tier split `480 / 380 / 280 / 180 / 60` and dressing slots `<= 15%` of total placements):
  - **Ring 1 — Stoops and Alleys**: `12` doorstep spawn points around the map perimeter, each with at least `40` Tier 1 Pocket placements within `10` studs of the spawn point (`spawnSlot = 1..12`), bordered by Tier 1 kerbs/stoops (`1.0–1.5` studs tall) that require the Tier 1 jump;
  - **Ring 2 — Sidewalks**: Sidewalks along Market Street and side streets with corner clusters of Tier 2 objects, plus narrow `4`-stud alleys between buildings and a storm-drain tunnel under Market Street that only Tier 1–2 balls (`diameter < 5` studs) can pass through;
  - **Ring 3 — The Park (west), The Construction Site (north-east), and The Car Park (south-east)**: Three Tier 3 districts featuring Park lawns and pond, Construction Site scaffolding ramps and shipping-container stack, and a climbable multi-level Car Park spiral ramp leading to an elevated top deck;
  - **Ring 4 — Market Street and The Plaza (centre)**: Main roadway and central Plaza with Tier 4 vehicles, bus stops, food trucks, and the Plaza fountain;
  - **Ring 5 — The Skyline Block (north) and The Waterfront (south)**: Tier 5 buildings, Tower Crane, Ferris Wheel, and The Glass Tower, plus static non-absorbable ground/road/kerb/waterfront `SmoothPlastic` `BlockDef`s and far-skyline boundary geometry;
  - **Ring Gates & Sightlines**: Each ring boundary is fenced by absorbable objects one tier above the inner ring (Tier 2 bollards around the Plaza, Tier 3 hedges and park fence, Tier 4 parked vans along Market Street). Hero props sit on street sightlines, and every one of the 12 spawns has a declared `sightline` keep-out corridor to a Tier 5 landmark (`ferris_wheel` or `glass_tower`).
- **FR-004**: Downtown's `environment.markers` and `keepOutAreas` MUST declare and protect all gameplay marker spots:
  - `BoosterSpot` markers covering all 5 starter boosters (`dash`, `magnet`, `spring`, `shield`, `slick_trail`) and `TrapSpot` markers covering all 4 starter traps (`slick`, `bumper`, `slow`, and closed-loop `waypoints` for the roaming `sweeper`) from Feature 006 (`004b`);
  - `5` seeded golden-object hiding spot markers (for Feature 012) at the exact design locations: (1) bus-shelter roof, (2) Car Park top deck, (3) inside the storm-drain tunnel, (4) Tower Crane counterweight, and (5) behind the Ferris Wheel;
  - `keepOutAreas` rectangles (`kind = "gate" | "shortcut" | "sightline" | "marker"`) covering every ring gate, `4`-stud alley and storm-drain shortcut, spawn-to-landmark sightline, booster/trap footprint (and sweeper segments), and golden-object hiding spot so theme overlays never block or overlap them.

#### Part C: Holiday City (`winter`) and Sunny City (`city`) Theme Bindings (`src/shared/Content/Worlds/Downtown.luau`, `src/shared/Content/Themes.luau`)

- **FR-005**: `Downtown.themeBindings.winter` (**Holiday City**, the launch theme) MUST configure all 20 holiday objects and overlays from `docs/design/07-holiday-city.md`:
  - `Themes.winter.lighting.clockTime` set to golden hour (`16.5`, with warm fog from `150` to `900` studs), camera snowfall (`kind = "snow"`, `maxParticles <= 40`), and `musicAssetKey = "musicWinter"`;
  - `slots`:
    - `slot.small` -> `bauble` (Tier 1, `size = 0.6`);
    - `slot.medium` -> `gift_box` (Tier 2, `size = 2.0`);
    - `slot.yard` -> `snowman` (Tier 3, `size = 8.0`);
    - `slot.street` -> `sleigh` (Tier 4, `size = 15.0`);
    - `slot.landmark` -> `mega_tree` (Tier 5, `size = 45.0`);
  - `overlays` (~`150` placements within the `1,400` placement budget, clear of all `keepOutAreas`) and `objects` defining the remaining 13 theme-only absorbable holiday props:
    - Tier 1: `fairy_light_bulb` (`0.5`), `mini_gift` (`0.9`), `gingerbread_cookie` (`1.0`) mixed into Stoops and Alleys doorstep crumbs;
    - Tier 2: `leaning_present_stack` (`3.6`, Hero), `poinsettia_pot` (`2.4`), `wooden_sled` (`3.2` on the Park sledding slope), `wreath` (`2.8` on shop doors);
    - Tier 3: `snow_pile` (`6.0` at street edges), `light_up_reindeer` (`7.0`, Hero wire-frame glowing decoration, not a live animal), `cocoa_cart` (`6.5` in the Plaza);
    - Tier 4: `market_stall` (`12.0`, 6 stalls in a ring around the Mega Tree in the Plaza), `snowplough` (`22.0`, parked at street edge);
    - Tier 5: `ice_rink` (`40.0`, frozen Park pond);
    - Plus non-absorbable holiday scenery (`Market Street` overhead lit garlands and `The Park` packed-snow sledding slope) activated only when the active theme is `"winter"`;
  - `heroVariants`:
    - `donut_food_truck` -> `{ assetKey = "cocoa_truck", nameKey = "object.downtown.cocoa_truck", size = 18 }`;
    - `glass_tower` -> `{ assetKey = "glass_tower_bow", nameKey = "object.downtown.glass_tower_bow", size = 60 }`;
  - `bookPage`: `id = "downtown.winter"`, `nameKey = "book.page.downtown.winter.name"` (*"Downtown: Holiday"*), `returningKey = "book.page.downtown.winter.returning"`, listing all 18 theme-only Holiday City `ObjectDef`s (`5` slots + `13` overlay objects).
- **FR-006**: `Downtown.themeBindings.city` (**Sunny City**, for the January switch) MUST configure:
  - `slots`:
    - `slot.small` -> `ice_lolly` (Tier 1, `size = 0.6`);
    - `slot.medium` -> `beach_ball` (Tier 2, `size = 2.0`);
    - `slot.yard` -> `paddling_pool` (Tier 3, `size = 8.0`);
    - `slot.street` -> `ice_cream_truck` (Tier 4, `size = 15.0`);
    - `slot.landmark` -> `giant_duck` (Tier 5, `size = 35.0`);
  - `overlays = { zones = {}, fixedPlacements = {} }` and `heroVariants = {}` so switching `activeThemeId` to `"city"` strips all Holiday City overlays, hero variants, and holiday slots while leaving the base Downtown layout untouched;
  - `bookPage`: `id = "downtown.city"`, `nameKey = "book.page.downtown.city.name"`, `returningKey = "book.page.downtown.city.returning"`, listing the 5 Sunny City slot objects.

#### Part D: Stylised-Real Blender Assets, Moderation Safety, Localization & Tests (`art/`, `src/shared/Assets.luau`, `src/shared/Localization/Strings.luau`, `tests/unit/`)

- **FR-007**: All 3D meshes for the 74 core Downtown objects, the 20 Holiday City objects (`18` theme-only objects + `2` hero variant meshes), and any ready Sunny City slot objects MUST be built in Blender (`art/source/*.blend`) and exported to `art/export/*.fbx` via `art/scripts/export_all.py`:
  - Real-world proportions (hero twist exaggerated `<= 10%`), 1-segment silhouette bevel (`4–8%`), smooth shading on round parts and sharp edges on boxy parts with split normals exported;
  - Single `Palette` material with every face's UVs inside a single `128 × 64` px gradient cell or `1,024 × 64` px trim strip of `art/palette.json`, and every object's top face mapped to `w-season` so snow caps/blossoms/leaves swap automatically by atlas;
  - Triangle count within `Config.Budgets.meshTriangles[tier]` (`500 / 700 / 1,500 / 3,500 / 5,000`), `RenderFidelity = Enum.RenderFidelity.Automatic`, `CollisionFidelity = Box` (Tiers 1–3) or `Hull` (Tiers 4–5), zero `SurfaceAppearance`/PBR, zero semi-transparency, and zero per-prop lights (`Material.Neon` glow child parts on Tier 4–5 heroes only);
  - All uploaded mesh asset IDs recorded exclusively in `src/shared/Assets.luau`.
- **FR-008**: All Downtown and Holiday City props and strings MUST obey Constitution Principle IV (Minimal rating) and Principle IX (Localised Strings):
  - Zero absorbable people or live animals (ambient pigeons are non-absorbable client scenery, `<= 8` per district, flying off when approached);
  - Bottles are clearly water or soda (screw cap and colour band, no long glass neck); generic puzzle cube and game controller shapes; upright intact vehicles only; no weapons, gambling imagery, real brands, flags, or landmarks;
  - Zero words on textures or 3D signs (pictograms only);
  - Every object `nameKey`, tier `nameKey` and `headlineKey`, and book page `nameKey` and `returningKey` MUST have complete English (`en`) and Spanish (`es`) entries in `src/shared/Localization/Strings.luau`.
- **FR-009**: Lune unit tests (`tests/unit/Downtown.test.luau`, `tests/unit/Themes.test.luau`, `tests/unit/Pace.test.luau`, `tests/unit/Markers.test.luau`, `tests/unit/ArtManifest.test.luau`) invoked by `scripts/check.sh` MUST validate:
  - Unique `id` and `bookId` across all 74 base objects, 18 `winter` theme-only objects, and 5 `city` theme-only objects;
  - Tier diameter ranges (`2 / 5 / 12 / 30 / 70`) and object sizes ascending by tier, with every object absorbable within its tier (`size <= 0.4 * tierCeilingDiameter`);
  - Every `slot.*` filled in both `winter` and `city` themes, dressing slot share `<= 15%`, and all 64 palette cells + lighting roles present in every theme;
  - Total placements (`base + overlays`) `<= 1,400` in both `winter` and `city`, with `>= 40` Tier 1 objects within `10` studs of each of the 12 spawns, zero footprint overlaps, and zero overlay intersections with `keepOutAreas` (`gate`, `shortcut`, `sightline`, `marker`, and golden spots);
  - Every `heroVariant` (`cocoa_truck` for `donut_food_truck`, `glass_tower_bow` for `glass_tower`) matches its base hero's `tier`, `size` (`±10%`), collision class, `coins`, and `bookId`;
  - Deterministic pace simulation across all 12 spawns in both `winter` and `city` hitting the pacing targets (`0:05` first pickup, `0:30 ± 20 s` Tier 2, `1:30 ± 20 s` Tier 3, `2:45 ± 20 s` Tier 4, and Tier 5 / `80` studs reachability by `4:00`).

### Key Entities

- **Downtown (`src/shared/Content/Worlds/Downtown.luau`)**: The launch `WorldDef` defining the `600 × 600` stud 5-ring city layout, 12 doorstep spawns, 74 core absorbable objects across 5 tiers (`Pocket`, `Sidewalk`, `Street`, `Block`, `Skyline`), static `SmoothPlastic` environment blocks, booster/trap/golden-spot `MarkerDef`s, `keepOutAreas`, and `themeBindings` for `"winter"` and `"city"`.
- **Core City Kit (74 `ObjectDef`s)**: Season-neutral city props (`18` Tier 1, `15` Tier 2, `16` Tier 3, `16` Tier 4, `9` Tier 5, including `14` ★ Hero props across Tiers 1–5) whose top faces use `w-season` so they re-theme automatically via the theme's `1,024 × 1,024` px gradient atlas.
- **Holiday City Binding (`themeBindings.winter`)**: Launch theme binding mapping the 5 dressing slots (`bauble`, `gift_box`, `snowman`, `sleigh`, `mega_tree`), adding ~`150` festive overlay placements across 13 overlay object types (`fairy_light_bulb`, `mini_gift`, `gingerbread_cookie`, `leaning_present_stack`, `poinsettia_pot`, `wooden_sled`, `wreath`, `snow_pile`, `light_up_reindeer`, `cocoa_cart`, `market_stall`, `snowplough`, `ice_rink`) plus non-absorbable garlands and sledding slope, mapping 2 hero variants (`cocoa_truck`, `glass_tower_bow`), and declaring the **Downtown: Holiday** book page.
- **Sunny City Binding (`themeBindings.city`)**: January theme binding mapping the 5 dressing slots (`ice_lolly`, `beach_ball`, `paddling_pool`, `ice_cream_truck`, `giant_duck`) with empty overlays and hero variants so the base city runs in summer palette and lighting.
- **GoldenSpot Marker**: Seeded hiding spot `MarkerDef` (`kind = "GoldenSpot"` or `subKind = "golden"`, guarded by a `keepOutAreas` entry) at the 5 Downtown locations reserved for Feature 012's daily golden object.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Downtown loads and is playable first with themed stand-in parts and then with final stylised-real Blender meshes, with 100% of Lune unit tests (`Downtown.test.luau`, `Themes.test.luau`, `Pace.test.luau`, `Markers.test.luau`, `ArtManifest.test.luau`) and Jest-Lua Studio tests passing and `scripts/check.sh` exiting `0`.
- **SC-002**: Holiday City (`winter`) and Sunny City (`city`) both load from the exact same base Downtown layout, and switching between them is a single-line data change (`activeThemeId = "winter"` vs. `"city"`) with zero code changes and zero new Studio console warnings or errors.
- **SC-003**: In agent-driven Studio bot runs (`AGENTS.md` "Driving the ball") across both `winter` (Holiday City) and `city` (Sunny City), balls hit the 4:00 pacing targets within `±20` seconds: first pickup by `0:05`, Tier 2 (`5` studs) by `0:30 ± 20 s`, Tier 3 (`12` studs) by `1:30 ± 20 s`, Tier 4 (`30` studs) by `2:45 ± 20 s`, and 3 stars (`80` studs / Tier 5 `70+` studs) reachable by `4:00`.
- **SC-004**: In a `640 × 360` Studio capture with 12 concurrent balls in Holiday City (`winter`, the heaviest theme with overlays and snowfall), unthrottled frame rate holds at least `30 fps`, active server parts remain strictly below `Config.Budgets.maxActivePartsPerServer` (`2,000`), and the per-tier triangle budgets (`500 / 700 / 1,500 / 3,500 / 5,000`) are locked from this capture and recorded in `specs/007-downtown-holiday-city/playtest.md`.
- **SC-005**: The grey-box layout check (before art) and the final Holiday City check are both completed via agent-driven Studio bot runs plus the owner playing and signing off in `specs/007-downtown-holiday-city/playtest.md`.

## Scope & Boundaries

### In Scope

- `src/shared/Content/Worlds/Downtown.luau` defining the 5-ring Downtown layout (`600 × 600` stud play area, `800 × 800` outer envelope, 12 doorstep spawns with 40 Pocket objects within 10 studs each, ~1,400 total placements split ~`480 / 380 / 280 / 180 / 60`), static `SmoothPlastic` ground/road/kerb/waterfront/ramp blocks, ring gates, `4`-stud alley and storm-drain shortcuts, sightlines, booster/trap markers, and 5 golden-object hiding spot markers.
- Promoting Downtown to the default unlocked launch world (`Config.Flags.Downtown = true`, `Config.DefaultWorldsUnlocked.downtown = true`), retiring Snow Village to the `Config` rollback path (and retiring Snow Village's `cat` and `dog`).
- Holiday City (`winter`) full theme binding and art: 20 holiday objects (`5` slots, `13` overlays, `2` hero variants), non-absorbable Market Street garlands and Park sledding slope, golden-hour lighting (`clockTime` ~`16.5`), snowfall, looping winter music, and the **Downtown: Holiday** Collection Book page.
- Sunny City (`city`) theme binding: `city` palette, lighting, music, and 5 slot definitions (`ice_lolly`, `beach_ball`, `paddling_pool`, `ice_cream_truck`, `giant_duck`), shipping with stand-in slot parts if the 5 Sunny City dressing meshes are deferred to Feature 011.
- Blender source (`.blend`) and exported (`.fbx`) stylised-real meshes for the 74 core Downtown objects and 20 Holiday City objects, uploaded to Roblox and recorded in `src/shared/Assets.luau`, plus complete English and Spanish localization keys in `src/shared/Localization/Strings.luau`.
- Non-absorbable ambient pigeons (`<= 8` per district) that fly off when a ball approaches.
- Grey-box layout and pacing playtest (before art) and full-density 12-ball Holiday City performance capture (`>= 30 fps` at `640 × 360`, `< 2,000` active parts) recorded with owner sign-off in `specs/007-downtown-holiday-city/playtest.md`.

### Out of Scope

- Ball skins (`<= 512` px textures), toppers, trails, auras, and the Shop UI, including holiday cosmetics (**Features 006a / 006b**).
- Co-op ball merge and Friend Boost (**Feature 005** in backlog).
- Outside-people playtest with 3+ adults and 3+ children aged 10–12 (**Feature 004d**).
- Dressing meshes and overlays for `spring`, `autumn`, `toon`, and `neon` themes (palette and lighting tokens already exist from Feature 005).
- Store-page icon and thumbnails (**Feature 008**).
- Active daily golden-object spawning and weekly object drops logic (**Feature 012**; only the 5 seeded hiding spot markers are placed in Downtown data here).

## Assumptions

- **Holiday & Sunny Music Tracks Already Configured**: `Assets.sounds.musicWinter` (`rbxassetid://114423108310478`) and `Assets.sounds.musicCity` (`rbxassetid://80565841497538`) were selected and added in commit `2005cef` (2026-10-30) and are wired to `Themes.winter` and `Themes.city`; if the owner chooses a different holiday track later, updating `Assets.sounds.musicWinter` in `src/shared/Assets.luau` requires no code or schema changes.
- **Holiday City Golden-Hour `clockTime = 16.5`**: `Themes.winter.lighting.clockTime` is updated from `15.5` to `16.5` to match the Holiday City design specification (`docs/design/07-holiday-city.md`: "clockTime about 16.5, warm sun").
- **Sunny City Dressing Fallback**: If the 5 Sunny City (`city`) dressing meshes (`ice_lolly`, `beach_ball`, `paddling_pool`, `ice_cream_truck`, `giant_duck`) are not uploaded before the December Holiday City launch, their `ObjectDef`s in `Downtown.themeBindings.city` ship with `assetKey = nil` (or `Assets.meshes[key] = ""`) so `city` runs with themed stand-in parts and finishes mesh uploads in Feature 011, as explicitly permitted by the feature prompt.
- **Core Kit Variant Count (74 Object Types)**: The 74 core absorbable object types correspond 1-to-1 with the 74 non-slot rows in `docs/design/02-city-assets.md` (`18` Tier 1, `15` Tier 2, `16` Tier 3, `16` Tier 4, `9` Tier 5). Colour/scale variations mentioned in the Twist column (such as crushed soda can, recycling wheelie bin, hatchback colour roles, shipping container colour roles, and corner shop row facade roles) are represented either within those 74 IDs or via palette role mapping so the core catalogue and base Collection Book pages total exactly 74 core city objects.
