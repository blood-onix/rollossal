# Data Model: Downtown Launch World (007)

Everything here is **content data** on the existing `WorldDef` / `ThemeBinding` / `MarkerDef` schemas
(`src/shared/Content/GreyBoxRoom.luau`). Nothing is persisted: no `Profile`, DataStore or schema change
(Principle VIII). The two schema-adjacent edits are one new marker `kind` (R-04) and one optional list
(`ambient`, R-14), both read-only content.

## 1. `Downtown` (`WorldDef`)

| Field | Value | Source |
| --- | --- | --- |
| `worldId` | `"downtown"` | FR-002 |
| `starThresholds` | `{ 20, 45, 80 }` | FR-002 |
| `growthK` | solved by `Pace.test` (start 1.5) | R-08 |
| `halfExtent` / `outerHalfExtent` | `300` / `400` | FR-002 |
| `maxPlacements` | `1400` | FR-002 |
| `sizeTiers` | 5, see §2 | FR-002 |
| `objects` | 74 core, see §3 | FR-002 |
| `zones`, `fixedPlacements`, `spawnPoints` | see §6, §7 | FR-003 |
| `activeThemeId` / `supportedThemes` | `"winter"` / `{ "winter", "city" }` | FR-001, FR-005 |
| `themeBindings` | `winter`, `city`, see §5 | FR-005, FR-006 |
| `keepOutAreas` | see §9 | FR-004 |
| `environment` | `palette` (world-only colours), `blocks` (§8), `markers` (§10) | FR-003, FR-004 |
| `hub` | `center = { x = -460, z = 0 }`, `halfExtent = 24`, `spawn = { 0, 0 }`, `padRadius = 5`, `assetKey = "hub"` | same hub as Snow Village (no new hub art) |
| `lighting` | used only when `Flags.ThemeSystem` is off; copy of the `winter` look | rollback |
| `ambient` (new, optional) | `{ pigeons = { { district, x, z } } }` | R-14 |

The module has **no `require` and no Roblox API** (it must load in Lune), and starts with `--!strict`. Types
come from `GreyBoxRoom` by a type-only annotation in the consumer, as `SnowVillage` does.

## 2. Size tiers

`minDiameters = { 2, 5, 12, 30, 70 }`, tier `n`'s `maxDiameter = minDiameters[n+1]` (Tier 5 open). `absorbRatio = 0.4`.
`nameKey = tier.downtown.{n}.name`, `headlineKey = tier.downtown.{n}.headline`, `headlineIcon = "cube"`, **no
`reward`** (R-10).

| Tier | Name (en) | Ball D | Object size range | Largest absorbable (0.4 × ceiling) | Coins |
| --- | --- | --- | --- | --- | --- |
| 1 | Pocket | 2–5 | 0.3–1.5 | 2.0 | 1–2 |
| 2 | Sidewalk | 5–12 | 1.6–4.0 | 4.8 | 3–5 |
| 3 | Street | 12–30 | 4.0–10.0 | 12 | 8–15 |
| 4 | Block | 30–70 | 10.0–25.0 | 28 | 20–40 |
| 5 | Skyline | 70–150 | 25.0–60.0 | 60 | 60–100 |

## 3. Core catalogue: 74 `ObjectDef`s

Per object: `id` (below), `tier`, `size`, `coins` (§4), `bookId = "downtown." .. id`,
`nameKey = "object.downtown." .. id`, `icon = "cube"`, `assetKey = "dt_" .. id` (R-03), `fallback`, `role`.
`fallback` is `B` Block, `S` Ball, `C` Cylinder. Heroes are marked ★ (14).

**Tier 1, 18 objects**

| id | size | fb | role |
| --- | --- | --- | --- |
| bottle_cap | 0.3 | C | w-accent-red |
| aa_battery | 0.4 | C | w-accent-yellow |
| earbud_case | 0.5 | B | w-white |
| puzzle_cube | 0.5 | B | w-accent-red |
| soda_can | 0.6 | C | w-accent-red |
| tennis_ball | 0.6 | S | w-accent-yellow |
| coffee_cup | 0.7 | C | w-white |
| donut | 0.8 | C | w-accent-pink |
| smartphone | 0.8 | B | w-rubber |
| water_bottle | 0.9 | C | w-accent-blue |
| pizza_slice | 0.9 | B | w-sand |
| game_controller | 0.9 | B | w-accent-teal |
| headphones | 1.0 | B | w-accent-teal |
| basketball | 1.0 | S | w-accent-orange |
| takeout_box | 1.2 | B | w-accent-red |
| ★ rubber_duck_sunglasses | 1.2 | S | w-accent-yellow |
| ★ lost_sneaker | 1.3 | B | w-accent-red |
| keyboard | 1.5 | B | w-rubber |

**Tier 2, 15 objects**

| id | size | fb | role |
| --- | --- | --- | --- |
| boombox_speaker | 2.0 | B | w-accent-teal |
| traffic_cone | 2.0 | C | w-accent-orange |
| skateboard | 2.2 | B | w-wood |
| fire_hydrant | 2.4 | C | w-accent-red |
| suitcase | 2.6 | B | w-accent-blue |
| acoustic_guitar | 3.0 | B | w-wood |
| newspaper_box | 3.0 | B | w-accent-blue |
| ★ inflatable_flamingo | 3.0 | S | w-accent-pink |
| potted_palm | 3.2 | C | w-leaf |
| ★ spinning_office_chair | 3.4 | C | w-accent-teal |
| wheelie_bin | 3.5 | B | w-metal-dark |
| shopping_cart | 3.6 | B | w-metal |
| e_scooter | 3.8 | B | w-accent-blue |
| parking_meter | 3.8 | C | w-metal-dark |
| ★ pizza_box_tower | 3.9 | B | w-white |

**Tier 3, 16 objects**

| id | size | fb | role |
| --- | --- | --- | --- |
| mailbox | 4.5 | B | w-accent-blue |
| satellite_dish | 5.0 | C | w-white |
| drum_kit | 5.0 | C | w-accent-red |
| pallet_stack | 5.0 | B | w-wood |
| picnic_table | 6.0 | B | w-wood |
| recycling_bank | 6.0 | B | w-accent-teal |
| moped | 6.0 | B | w-accent-orange |
| bicycle | 6.5 | B | w-accent-red |
| ★ arcade_cabinet | 6.5 | B | w-accent-teal |
| bench | 7.0 | B | w-wood |
| ★ vending_machine | 7.0 | B | w-accent-red |
| hot_dog_cart | 7.5 | B | w-accent-yellow |
| street_tree | 9.0 | C | w-leaf |
| ★ inflatable_tube_guy | 9.0 | C | w-accent-red |
| street_lamp | 9.5 | C | w-metal-dark |
| traffic_light | 9.8 | C | w-metal-dark |

**Tier 4, 16 objects**

| id | size | fb | role |
| --- | --- | --- | --- |
| bus_shelter | 10 | B | w-glass |
| kiosk | 12 | B | w-wall-c |
| fountain | 13 | C | w-kerb |
| hatchback | 14 | B | w-accent-blue |
| taxi | 14 | B | w-accent-yellow |
| pickup_truck | 16 | B | w-accent-orange |
| delivery_van | 17 | B | w-white |
| ★ donut_food_truck | 18 | B | w-accent-pink |
| billboard | 18 | B | w-metal-dark |
| ★ monster_truck | 18 | B | w-accent-teal |
| shipping_container | 20 | B | w-accent-red |
| big_street_tree | 20 | C | w-leaf |
| garbage_truck | 20 | B | w-accent-teal |
| corner_bakery | 22 | B | w-wall-b |
| fire_engine | 24 | B | w-accent-red |
| city_bus | 25 | B | w-accent-red |

**Tier 5, 9 objects**

| id | size | fb | role |
| --- | --- | --- | --- |
| corner_shop_row | 26 | B | w-wall-a |
| townhouse | 30 | B | w-wall-a |
| ev_charging_station | 32 | B | w-white |
| ★ rocket_water_tower | 34 | C | w-metal |
| cinema | 36 | B | w-wall-c |
| apartment_block | 40 | B | w-wall-a |
| ★ ferris_wheel | 50 | C | w-metal |
| ★ tower_crane | 55 | B | w-accent-yellow |
| ★ glass_tower | 60 | B | w-glass |

Counts: 18 + 15 + 16 + 16 + 9 = **74**; heroes 2 + 3 + 3 + 2 + 4 = **14**. The three Corner Shop Row variants,
crushed soda can, recycling-bin colourway and hatchback colourways are role mappings of the same id (spec
Assumptions), not extra ids.

## 4. Coin rule

`coins = round(lo + (hi − lo) × (size − sizeLo) / (sizeHi − sizeLo))` with the tier's coin range `[lo, hi]` and
size range `[sizeLo, sizeHi]` from §2. Same size gives same coins; coins never fall as size rises; every tier's
range sits entirely above the previous one. Hero variants copy the base object's coins.

## 5. Theme bindings

### `winter` (Holiday City, launch)

| Slot | Object | Tier | Size | Mesh key |
| --- | --- | --- | --- | --- |
| slot.small | bauble | 1 | 0.6 | dt_bauble |
| slot.medium | gift_box | 2 | 2.0 | dt_gift_box |
| slot.yard | snowman | 3 | 8.0 | dt_snowman |
| slot.street | sleigh | 4 | 15 | dt_sleigh |
| slot.landmark | mega_tree | 5 | 45 | dt_mega_tree |

| Overlay object | Tier | Size | Role | Where | Count |
| --- | --- | --- | --- | --- | --- |
| fairy_light_bulb | 1 | 0.5 | w-glow | doorsteps | 24 |
| mini_gift | 1 | 0.9 | w-accent-red | doorsteps | 18 |
| gingerbread_cookie | 1 | 1.0 | w-wood | doorsteps | 18 |
| ★ leaning_present_stack | 2 | 3.6 | w-accent-red | Market Street corners | 6 |
| poinsettia_pot | 2 | 2.4 | w-accent-red | shop fronts | 14 |
| wooden_sled | 2 | 3.2 | w-wood | Park slope | 14 |
| wreath | 2 | 2.8 | w-leaf | shop doors | 16 |
| snow_pile | 3 | 6.0 | w-white | street edges | 12 |
| ★ light_up_reindeer | 3 | 7.0 | w-glow | Plaza approaches | 5 |
| cocoa_cart | 3 | 7.5 | w-accent-orange | Plaza | 8 |
| market_stall | 4 | 12 | w-accent-red | 6 in a ring round the tree, 2 more on Market Street | 8 |
| snowplough | 4 | 22 | w-accent-yellow | street edge | 6 |
| ice_rink | 5 | 40 | w-water | frozen Park pond | 1 |

Overlay count 150 (60 + 50 + 25 + 14 + 1). `light_up_reindeer` is a wire-frame lamp decoration, not an animal.
`heroVariants`: `donut_food_truck` → `{ assetKey = "dt_cocoa_truck", nameKey = "object.downtown.cocoa_truck", size = 18 }`;
`glass_tower` → `{ assetKey = "dt_glass_tower_bow", nameKey = "object.downtown.glass_tower_bow", size = 60 }`.
`objects` = the 5 slot + 13 overlay defs (18). `bookPage = { id = "downtown.winter", nameKey = "book.page.downtown.winter.name",
returningKey = "book.page.downtown.winter.returning", objectIds = <the 18> }`, no `reward`.

Non-absorbable winter scenery (garlands over Market Street, packed-snow slope in the Park) is part of the **`winter`
dressing** of `environment`: a short list of blocks tagged `themes = { "winter" }` is *not* supported by
`WorldBuilder` today. Decision: they are ordinary `environment.blocks` using `swatch` roles that look neutral in
`city` (garland = `w-trim`, slope = `w-season`), so there is no builder change; the garlands are 6 thin blocks and the
slope one wedge. In `city` the same wedge is a grass bank (via `w-season`) and the garlands read as street cables.

### `city` (Sunny City)

| Slot | Object | Tier | Size | Mesh key |
| --- | --- | --- | --- | --- |
| slot.small | ice_lolly | 1 | 0.7 | dt_ice_lolly |
| slot.medium | beach_ball | 2 | 2.0 | dt_beach_ball |
| slot.yard | paddling_pool | 3 | 6.5 | dt_paddling_pool |
| slot.street | ice_cream_truck | 4 | 16 | dt_ice_cream_truck |
| slot.landmark | giant_duck | 5 | 35 | dt_giant_duck |

`overlays = { zones = {}, fixedPlacements = {} }`, `heroVariants = {}`, `objects` = the 5 defs, `bookPage`
`downtown.city` listing them. Mesh keys may be absent (stand-ins render until Feature 011).

## 6. Spawns

12 `SpawnPoint`s, `slot` 1…12, `y` = doorstep porch height 0.6, `yaw` facing the centre. They sit on the
perimeter streets of the four sides, three per side, 40 to 70 studs in from the outer edge. Provisional
coordinates are fixed in `Downtown.luau`, not computed. Each has a `spawnSlot` zone (§7) with exactly
32 core Tier 1 plus 8 `slot.small` placements within 10 studs, so every spawn passes the `≥ 40` rule in both
themes.

## 7. Zones and fixed placements

| Group | Zone/fixed | Content | Placements |
| --- | --- | --- | --- |
| Doorstep ×12 | zone | 32 T1 core + 8 `slot.small` | 480 |
| Side-street sidewalks | zones | T2 clusters at corners (`slot.medium` ×30) | 330 |
| Park, Site, Car Park | zones + fixed | T3 mixes, `slot.yard` ×14, fence hedges (T3), picnic sets | 230 |
| Market Street, Plaza | zones + fixed | T4 vans along the road (gate), heroes, `slot.street` ×6 | 150 |
| Skyline Block, Waterfront | fixed | T5 buildings (spaced ≥ run-up), 2 × `slot.landmark` | 55 |
| **Base** | | | **1,245** |
| `winter` overlays | zones + fixed | §5 | 150 |
| **`winter` total** | | | **1,395** |

`city` total is 1,245. Dressing share (148 slots) = 10.6 % in `winter`, 11.9 % in `city`. Heroes and landmarks
are `fixedPlacements` with ids `dt_h_<id>` / `dt_l_<n>`; overlay zone and placement ids are prefixed `dt_ol_` so
they cannot clash with base ids (`ThemeResolve` rejects a clash).

**Ring gates** (food walls): Tier 2 bollards round the Plaza apron (reusing `traffic_cone` and `parking_meter`
placements on a ring), Tier 3 hedges (`street_tree`) and fence (`bench`, `recycling_bank`) round the Park,
Tier 4 vans (`delivery_van`, `pickup_truck`, `taxi`) lining Market Street. Each gate has a `gate` keep-out so
overlays never plug it.

## 8. Environment blocks (`BlockDef`)

All `SmoothPlastic`, anchored, swatch roles from the active theme. Target ≈ 330, cap 400.

| Group | Blocks | Notes |
| --- | --- | --- |
| Ground, roads, pavements, kerbs | ≈ 70 | Tier 1 kerbs and stoops are 1.0–1.5 tall so the jump is needed |
| Park (lawns, pond, slope wedge, fence rails) | ≈ 45 | pond is the ice rink in winter |
| Construction Site (scaffold ramps as `Wedge`, container stack, hoardings) | ≈ 50 | crane ballast stack for golden spot 4 |
| Car Park (three-level spiral of wedges, deck slabs, parapets, pillars) | ≈ 70 | top deck slab for golden spot 2 |
| Plaza fountain (basin, water disc, pedestal), planters | ≈ 12 | R-11 |
| Storm-drain tunnel (floor, two side walls, no roof under the road) | ≈ 8 | height 3.8: a Tier 3 ball cannot enter; floor holds golden spot 3 |
| Alley walls (4-stud gaps between building blocks) | ≈ 40 | 4-stud clear width |
| Waterfront (quay, railings, promenade, ticket hut platform) | ≈ 25 | platform for golden spot 5 |
| Bus-stop slab roofs | ≈ 6 | one is golden spot 1 |
| Garlands and slope (winter-neutral, §5) | ≈ 7 | |
| Boundary and far skyline | ≈ 10 | one merged skyline strip, non-colliding |

## 9. Keep-outs (`KeepOutDef`)

| Kind | Count | What |
| --- | --- | --- |
| `gate` | 6 | each ring-boundary opening in the food walls |
| `shortcut` | 5 | 4 alleys (4 wide) + the drain tunnel mouth, each with its approach |
| `sightline` | 12 | one axis-aligned corridor per spawn (12 wide, ≥ 80 long) along its street toward the Glass Tower (north) or Ferris Wheel (south) |
| `marker` | ≈ 25 | one per booster/trap footprint, one per sweeper path segment, one per golden spot (6 × 6) |

Keep-outs are axis-aligned `{ id, kind, x, z, w, d }`. Overlay zones and overlay fixed placements may not
intersect any of them; `Downtown.test` checks the overlay set against the whole list.

## 10. Markers (`MarkerDef`)

| id | kind | subKind | Notes |
| --- | --- | --- | --- |
| booster-dash-1, -2 | BoosterSpot | dash | on Market Street, two sides of the Plaza |
| booster-magnet-1 | BoosterSpot | magnet | Park path |
| booster-spring-1 | BoosterSpot | spring | at the container stack (R-12) |
| booster-shield-1 | BoosterSpot | shield | Plaza apron |
| booster-slick_trail-1 | BoosterSpot | slick_trail | Waterfront promenade |
| trap-slick-1, -2 | TrapSpot | slick | side streets |
| trap-bumper-1 | TrapSpot | bumper | Car Park forecourt |
| trap-slow-1 | TrapSpot | slow | Construction Site mud |
| trap-sweeper-1, -2 | TrapSpot | sweeper | closed loop of ≥ 3 waypoints each, inside `halfExtent` |
| golden-1 … golden-5 | GoldenSpot | golden | bus-stop roof, Car Park top deck, drain tunnel, crane ballast, behind Ferris Wheel |

Validity: no marker overlaps a block whose top is above 0.2, another marker, or leaves the world; each has a
covering `marker` keep-out; golden spots take the constant 6 × 6 footprint (`Markers.GOLDEN_FOOTPRINT`). Built
parts: 12 hazards, 0 golden.

## 11. Ambient pigeons

`ambient.pigeons = { { district: string, x: number, z: number } }`, at most 8 per district for 5 districts (≤ 40),
all on static geometry or ground and none inside a `marker` keep-out. Client-only; never absorbable; never counted
in the server budget.

## 12. Assets and strings

- `Assets.luau` gets **no** new IDs in this feature until the owner uploads; it gets keys as meshes arrive.
  Keys follow R-03. Missing or `""` keys mean stand-ins.
- Strings (en + es), all new keys (R-16): 99 `object.downtown.*`, 10 `tier.downtown.*`, 4 `book.page.downtown.*`.
  Returning labels never say "limited", never carry a date or timer.

## 13. Validation rules → tests

| Rule | Test |
| --- | --- |
| 74 objects; per tier 18/15/16/16/9; 14 heroes; unique ids and bookIds; naming (`downtown.<id>`, `object.downtown.<id>`, `dt_<id>`) | `Downtown.test` |
| Sizes inside tier range and ≤ 0.4 × tier ceiling; coins by §4; tier ranges ascend | `Downtown.test` |
| Every slot mapped in both themes with matching tier; dressing share ≤ 15 % | `Downtown.test`, `ThemeResolve` |
| Overlay set clash-free; placements ≤ 1,400 in both themes; part budget (R-05) | `Downtown.test` |
| ≥ 40 T1 within 10 studs of each spawn, both themes; no zone beyond `halfExtent`; no placement beyond `outerHalfExtent` | `Downtown.test` |
| Zero overlay/keep-out intersections (all four kinds, golden spots included); zero footprint overlaps | `Downtown.test` |
| 12 sightline keep-outs, none containing base T4–T5 placements except landmarks | `Downtown.test` |
| Hero variants match base tier, coins, bookId, collision class; size ± 10 % | `Downtown.test`, `ThemeResolve` |
| Markers valid; all 9 sub-kinds present; 5 golden spots; `requireGolden` | `Markers.test`, `Downtown.test` |
| `winter.clockTime == 16.5`; palette cells + lighting roles in every theme | `Themes.test` |
| Pace targets from all 12 spawns, both themes | `Pace.test` |
| Triangle budgets, manifest, budgets.json cover Downtown | `ArtManifest.test` |
| en + es text for every key above | `Strings.test` |
| `Flags.Downtown`, `DefaultWorldsUnlocked.downtown`, active-world priority | `Config.test`, `Downtown.test` |
