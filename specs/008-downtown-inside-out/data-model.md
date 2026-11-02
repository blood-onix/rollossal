# Data Model: Downtown "Inside Out" (008)

What `Downtown.luau` holds after the redesign. Everything here is data in the one world module (Principle VII). The 74
core objects, the 18 + 5 theme objects, the two hero variants, the tier ranges and the coin rule are **unchanged** from
007 (`specs/007-downtown-holiday-city/data-model.md` §2 to §5); this file only changes the envelope, the layout and the
counts. Coordinates: x east, z south, y up; origin at the centre of the Old Quarter square; `m = max(|x|, |z|)`.
Numbers marked *nominal* are fixed by a scratch search during the task phase and baked as literals with a comment.

## 1. Envelope and Config

| Field | 007 | 008 | Where |
| --- | --- | --- | --- |
| `Downtown.halfExtent` | 300 | **440** | `Downtown.luau` |
| `Downtown.outerHalfExtent` | 400 | **560** | `Downtown.luau` |
| `Downtown.hub.center` | `{ x = -460, z = 0 }` | **`{ x = -620, z = 0 }`**, `halfExtent` 24 (nearest edge −596, 36 outside the horizon) | `Downtown.luau` |
| `Downtown.maxPlacements` | 1400 | **1500** | `Downtown.luau` |
| `Config.Budgets.defaultMaxPlacements` | 1400 | **1500** | `Config.luau` |
| `Config.cameraMaxDistance` | 80 | **320** | `Config.luau` |
| `Downtown.lighting.fogStart` / `fogEnd` | 150 / 900 | **500 / 1600** (provisional) | `Downtown.luau` |
| `Downtown.growthK` | 1.95 | tuned (R-07), expected 2.2 to 3.0 | `Downtown.luau` |
| `starThresholds` | `{20, 45, 80}` | unchanged | `Downtown.luau` |
| `Config.Budgets.maxActivePartsPerServer` | 2000 | unchanged; Downtown holds ≤ 1,850 | `Config.luau` |

`SnowVillage` keeps 300 / 400 / −460 and `maxPlacements = 1700`.

## 2. Rings

| Ring | Name | `m` range | Ground | Character |
| --- | --- | --- | --- | --- |
| 1 | Old Quarter | ≤ 90 | `w-asphalt` base, `w-sidewalk` plinths, plaza slab | 8-stud lanes, 30-stud main streets, square with landmark and fountain, 12 spawns, bollard gates |
| 2 | Terraces | 90 to 185 | asphalt streets, `w-sidewalk` plinths, `w-roof-a/b` shortcut roofs | 16-stud residential streets, house rows, roofed 4.5 shortcuts, storm drain |
| 3 | Yards | 185 to 290 | five district slabs (top 0.25 to 0.5) | Park, Market, Construction Site, Car Park, Rail Yard |
| 4 | Boulevard | 290 to 360 | asphalt, 1.0 pavements, 0.8 median | 60-wide orbital road, two 26-stud carriageways and an 8-stud median |
| 5 | Skyline / Harbour | 360 to 440 | podiums (N, E); quay and shallow water floor (S, W) | 40-stud avenues, towers, ferris wheel, containers |
| Horizon | – | 440 to 560 | static towers (N, E); `w-water` slab (S, W) | not absorbable, not reachable |

## 3. Tier split (FR-005, D1, D5)

Base placements, identical in `winter` and `city` (slots resolve to the same tier). Target 470 / 386 / 260 / 204 / 56
with a ±10 % band per tier.

| Tier | Target | **Planned** | Band (±10 %) | R1 | R2 | R3 | R4 | R5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 470 | **480** | 423 to 517 | 480 | 0 | 0 | 0 | 0 |
| 2 | 386 | **386** | 347 to 425 | 96 | 190 | 70 | 30 | 0 |
| 3 | 260 | **260** | 234 to 286 | 0 | 60 | 150 | 40 | 10 |
| 4 | 204 | **204** | 184 to 224 | 24 | 56 | 64 | 44 | 16 |
| 5 | 56 | **56** | 50 to 62 | 7 | 17 | 4 | 0 | 28 |
| **Sum** | 1,376 | **1,386** | – | 607 | 323 | 288 | 114 | 54 |

- Ring 1 Tier 2 is 64 lane objects (16 per quarter) and 32 gate cones (4 gates × 8).
- Ring 1 Tier 4 is the fountain, about 16 `corner_bakery` and a few street trees. Ring 1 Tier 5 is the landmark
  (`slot.landmark`, on the fountain pedestal) and 6 `corner_shop_row`.
- Ring 2 Tier 5 is 12 `townhouse` and 5 `corner_shop_row`; Tier 4 is `corner_bakery`, `big_street_tree` and vans.
- Ring 3 Tier 5 is the `cinema` and three other Tier 5 objects from the 74; Ring 4 Tier 4 is vehicles
  (`city_bus`, trucks).
- Ring 5 Tier 5 (28): `apartment_block`, `ev_charging_station`, `rocket_water_tower`, `tower_crane`, `glass_tower` /
  `glass_tower_bow` (winter variant), `ferris_wheel`, plus Skyline repeats of the 40 to 60 size heroes in the 74.
- Tier 1 is the whole 480: 12 doorsteps × 40 (R-04). Winter overlays carry Tier 2 to 4 only.
- Slot placements stay ≤ 15 % of placements in each theme (C8).

## 4. Streets (the table the width test holds)

| Street | Ring | Axis and centre line | From to | Clear width (plinth face to plinth face) |
| --- | --- | --- | --- | --- |
| Lanes `ln_*` (8) | 1 | two per quarter at `|x| = 52.5` and `|z| = 52.5` | main-street edge to the edge wall at `m = 90` | 8 ± 1 |
| Main streets `ms_n/s/e/w` | 1 to 3 | the axes, `|t| ≤ 15` | `m = 30` to `290` | 30 ± 1 |
| Plaza | 1 | `|x|, |z| ≤ 30` | – | open square, not measured |
| Loop A `ra_*` | 2 | square ring, centre `m = 100` | `m` 92 to 108 | 16 |
| Loop B `rb_*` | 2 | square ring, centre `m = 150` | `m` 142 to 158 | 16 |
| Radial streets `rr_*` (16) | 2 | tangential `t = ±55` and `±140` | loop A to `m = 185` | 16 |
| Yard approaches and spines | 3 | main-street axes, plus one spine per yard | – | ≥ 30 |
| Boulevard carriageways `bl_in`, `bl_out` | 4 | inner `m` 295 to 321, outer `m` 329 to 355 | whole ring | ≥ 24 each (26), median 8, 60 in total |
| Avenues `av_n/e/s/w` | 5 | the axes | `m = 360` to `440` | ≥ 40 |

Ring 2 radial streets use the 16 to 30 range; the two loops and 16 radials are 16, the four main streets are 30.

## 5. Old Quarter (Ring 1)

Four quarters, `[15, 90]²` mirrored. In each quarter two 8-stud lanes (at 52.5) split it into four sub-blocks of
33.5 × 33.5. The inner sub-block is notched by a 15 × 15 corner at the origin side, so the central square is
`|x|, |z| ≤ 30`. Main streets start at `m = 30` and are 30 wide.

- **Plinths**: 20: 16 sub-block plinths (one per sub-block, the inner ones notched to the square) and 4 shop-front
  strips along the main-street faces. `w-sidewalk`, top **1.2**, so 1.0 to 1.5 (C18). Shops stand on them: `corner_bakery` (T4) and `corner_shop_row` (T5), inside the plinth.
- **Plaza**: one slab (top 0.3) and a fountain pedestal; `fixedAt("dt_l_1", "slot.landmark", 0, 2.4, 0)` stands on the
  pedestal; the `fountain` (T4, size 13) sits beside it.
- **Edge walls**: 8 segments (two per side, each 75 long, one either side of the main-street gap), thickness
  2, `m` 90 to 92, **top 6**. They seal every lane at its end and the sub-block outer faces. Four gaps (the main
  streets, 30 wide) remain.
- **Bollard gates**: in each gap 8 `traffic_cone` (core T2, size 2.0) at 3.75 pitch (gap 1.75), so a ball under D 2.0
  cannot pass, no ball under D 5 can eat one (`0.4 · 4.9 = 1.96 < 2.0`), and D ≥ 5 eats through (N8).
- **Spawn kerbs**: 12 blocks, top 1.2, one beside each spawn.

## 6. Spawns (R-04)

Twelve spawns, three per quarter, on the lanes and never on a main street. Nominal north-east quarter positions (the
others mirror through the axes; `slot` numbering runs 1 to 12 clockwise from the north-east quarter):

| Quarter | Spawn A | Spawn B | Spawn C |
| --- | --- | --- | --- |
| NE (`+x, −z`) | `(52.5, −35)` on lane `x = 52.5` | `(52.5, −72)` on lane `x = 52.5` | `(35, −52.5)` on lane `z = −52.5` |

Pair distances are 24.7 to 37 studs, so the 10-stud clusters do not overlap. Each spawn has:

- `dt_z_door_NN_a`: zone of **32** core Tier 1 objects (within 10 studs);
- `dt_z_door_NN_b`: zone of **8** `slot.small` (Tier 1 in both bindings);
- a 1.2 kerb block next to it (C18).

Each quarter also has `dt_z_lane_q`: 16 Tier 2 objects scattered on its two lanes, 64 in total.

## 7. Terraces (Ring 2)

Two square loops (A, centre `m = 100`; B, centre `m = 150`), 16 radial residential streets and the four 30-wide main
streets cut the band into house rows. Row 1 is 34 deep (`m` 108 to 142, for `townhouse` size 30), row 2 is 27 deep (`m`
158 to 185, for `corner_shop_row` size 26 and `corner_bakery` size 22). Rows are one plinth per city block face, top
**1.2**.

- **Plinths**: 40 (N and S bands 12 each, E and W bands 8 each), plus **4** extra where an alley splits a block.
- **Shortcuts**: 4 alleys (one per side), each through a row-1 block, 34 long. Each is: two flanking walls (top **5.2**,
  clear gap **4.5 ± 0.1**) and one roof block whose bottom face is at **y 4.9**, covering the length. 12 blocks.
  Mouths are flush with the street. Each has a `shortcut` keep-out sized to the corridor (R-12).
- **Storm drain**: one longer tunnel (about 70) with the same recipe (2 walls + roof, 3 blocks), tangential through the
  west-side row 2, so a D < 4.5 ball can pass from the south radial to the north radial without using the street.
- **Population**: 190 Tier 2 (kerbside scatter, small vehicles, bollards, mailboxes), 60 Tier 3, 56 Tier 4, 17 Tier 5
  (the houses). Tier 4 and 5 are fixed placements on the plinths; nothing sits on top of an absorbable building.

## 8. Yards (Ring 3)

| Yard | Location (nominal) | Ground | Signature | Blocks |
| --- | --- | --- | --- | --- |
| Park | NW quadrant of the annulus | `w-grass` lawn slab (top 0.3), pond slab | hedges (6), fence gates (2); `winter`: ice rink, sledding slope (theme blocks) | 10 |
| Market | NE quadrant | paved slab (top 0.3) | stalls (6 counters), pallet and crate stacks, carts, vending, arcade | 7 |
| Construction Site | west band, south half | concrete slab | hoarding (4), scaffolding ramps (4, ≤ 2.0 rise, ≤ 20°), container stack on a 2-block platform | 11 |
| Car Park | south band, west half | concrete slab | 3 deck levels, 4 ramps (≤ 2.0 rise per step), 2 parapets, parked cars on the top deck | 10 |
| Rail Yard | SE quadrant | bed slab (top 0.25) | 6 track strips, 2 platforms, containers, delivery vans | 9 |
| Separators | between yards | – | low fences (top 3) at the yard seams, 30-stud approaches open | 6 |

Total Ring 3 blocks: **53**. Yards are filled with Tier 2 and 3 scatter zones (70 T2, 150 T3) and Tier 4 props; Ring 3's
four Tier 5 are fixed placements (cinema, three heroes). No zone mixes Tier 3 with Tier 5 (R-14).

## 9. Boulevard (Ring 4)

Ring road `m` 295 to 355: inner carriageway 26, median 8 (top 0.8, trees and lamps on it), outer carriageway 26. Eight
median pieces (broken at the four main-street axes), 12 bus-stop shelters and 4 billboards: **24 blocks**. Population:
30 Tier 2, 40 Tier 3, 44 Tier 4 (vehicles in a zone of size ≤ 25 mix, plus `big_street_tree`, `street_lamp`,
`traffic_light` on the median) and no Tier 5.

## 10. Skyline and Harbour (Ring 5, horizon)

- **Skyline (N, E)**: 8 podium blocks (top 1.2) on both sides of the 40-stud avenue; towers are fixed placements on them.
- **Harbour (S, W)**: boardwalk, then a quay wall (top 1.2, 4 blocks, broken at the avenue) over a shallow basin floor
  (2 slabs, top **−0.4**, `w-water`, extending to 560). 8 wedge lips (every ≤ 110 studs) let a ball roll back out
  (R-13).
- **Horizon**: 8 static towers at `m` 450 to 540 on N and E. Not absorbable, not placements (D7).
- Population: 10 Tier 3, 16 Tier 4 (containers, boats, signs), 28 Tier 5.
- Blocks: 8 + 2 + 4 + 8 + 8 = **30**.

## 11. Block inventory (R-03)

| Group | Blocks | Notes |
| --- | --- | --- |
| Shell | 5 | asphalt base slab (top 0.0), 4 `Boundary` |
| Ring 1 | 42 | plaza 1, pedestal 1, plinths 20, edge walls 8, spawn kerbs 12 |
| Ring 2 | 59 | plinths 40 + 4 splits, shortcuts 12, drain 3 |
| Ring 3 | 53 | yards 47, separators 6 |
| Ring 4 | 24 | medians 8, shelters 12, billboards 4 |
| Ring 5 + horizon | 30 | podiums 8, basins 2, quay 4, lips 8, horizon 8 |
| **Base** | **213** | ≤ 215 (C14) |
| `winter` theme blocks | 26 | 24 garlands (Ring 1 and Ring 2 main streets, y = 11, bottom ≥ 9), Park slope, sled ramp; ≤ 35 |

`Boundary` blocks: inner faces at `±440`, thickness 8 (centres at `±444`), height 200 (centre y 100); N/S length 896, E/W
length 880 (R-01). Palette role: an existing `w-asphalt`, never rendered.

## 12. Keep-outs

`KeepOutDef.kind` stays `"gate" | "shortcut" | "sightline" | "marker"`.

| Kind | Count | Notes |
| --- | --- | --- |
| `gate` | 4 | the four bollard gaps, so overlays never fill them |
| `shortcut` | 5 | 4 alleys and the drain, sized to the corridor |
| `sightline` | 16 | four main-street corridors (30 wide, `m` 30 to 185) and twelve 8-wide lane corridors |
| `marker` | one per built marker | as in 007 |

## 13. Markers (R-15)

15 built markers (budget allows 16) plus 5 `GoldenSpot`:

| Group | Built | Sub-kinds |
| --- | --- | --- |
| Old Quarter | 2 | dash (booster), bumper (trap) |
| Terraces | 3 | magnet, slick_trail (boosters), slow (trap) |
| Yards | 4 | spring, shield (boosters), slick, sweeper (traps) |
| Boulevard | 3 | dash (booster), sweeper, bumper (traps) |
| Skyline / Harbour | 3 | shield, magnet (boosters), slick (trap) |

All nine sub-kinds appear (C15). Each golden spot stands on a static block: one on a Terraces plinth, one in the Park,
one on the Car Park top deck, one on a Boulevard median, one on a Skyline podium.

## 14. Theme bindings

- `winter.blocks`: the 24 garlands, the Park slope and the sled ramp (F2); no base block id contains `garland` or `slope`.
- `winter.overlays`: ≤ 110, Tier 2 to 4: Plaza (stall rows, tree), Park (rink, sleds), Market (cocoa carts), Ring 2
  stoops. They avoid every keep-out (C10).
- `winter.slots` / `city.slots`: unchanged mapping; `slot.landmark` is `mega_tree` / `giant_duck`.
- `city`: no overlays, no theme blocks, no hero variants.
- Switching theme is the one field `activeThemeId`.

## 15. Pigeons and lighting

Pigeons: 5 districts (Old Quarter, Terraces, Park, Market, Harbour), ≤ 8 each, on ground or a static plinth, none in a
`marker` keep-out. Lighting: `winter` golden hour and snow as in 007; `fogStart` 500, `fogEnd` 1600 (both themes).

## 16. Part budget (worst case, `winter`)

`1,386 + 110 + (213 + 26) + 15 + 3 + 12 + 64 = 1,829` (the 16-marker ceiling gives 1,830; the 250-block ceiling
1,841). `city`: `1,386 + 213 + 15 + 3 + 12 + 64 = 1,693`. Both ≤ 1,850 and < 2,000.

## 17. Validation rules → tests

Each row is a contract in `contracts/world-content.md` and runs in `tests/unit/Downtown.test.luau` or `Pace.test.luau`.

| Rule | Test |
| --- | --- |
| Envelope pins (440 / 560 / −620, 8-thick colliders) | `Downtown` N1 |
| Per-tier split inside the bands | N6 |
| Coverage ≥ 20 %, ≥ 50 blocks, no wall > 8 | N2, N3, N4 |
| Street widths | N7 |
| Gates and the Ring 1 edge | N8 |
| Shortcut 4.5 ± 0.1 with roof 4.8 to 5.0 | N5 |
| F2 theme scoping | N9 |
| Triangle ceiling | N10 |
| Pace windows, 12-eater first minute | `Pace` (contracts/pace-and-tests.md) |
