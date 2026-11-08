# Data Model: Dedicated City Asset Kit, Style Audit, Shop Signage & Meme Originals

Entities, their fields, and the finalised asset list (FR-003). Sizes are the longest side in studs and sit inside the tier
bands of `art/scripts/budgets.json` (T1 0.3 to 1.5, T2 1.6 to 3.9, T3 4.2 to 9.8, T4 10 to 25, T5 26 to 60). Tier
budgets are `Config.Budgets.meshTriangles` = 500 / 700 / 1,500 / 3,500 / 5,000.

## 1. Asset Audit Record (one per `dt_*` mesh, 99 rows)

| Field | Type | Rule |
| --- | --- | --- |
| `id` | string | `dt_*`, one of the 99 manifest ids, unique |
| `tier`, `size` | number | from `manifest.json` and `budgets.json` |
| `triangles` | number | from `manifest.json` (counted from the FBX by `ArtManifest.test`) |
| `tierBudget` | number | `Config.Budgets.meshTriangles[tier]` |
| `floorClass` | `pocket` / `flat` / `panel` / `tier` | `plan.md` D3 |
| `floor` | number | 40 / 24 / 150 / tier floor |
| `fillRatio` | number | `triangles / floor` |
| `seasonShare` | number | area share of `w-season` UVs, 0 to 1, under 0.15 to pass |
| `verdict` | `keep` / `upgrade` / `replace` | `research.md` R-02 |
| `reason` | string | required when the verdict is not `keep` |
| `renders` | `{ city, winter }` | relative paths under `audit/renders/` |

### 1.1 Baseline from triangles alone (visual pass may move a verdict one step)

12 keep, 36 upgrade, 51 replace. Zone is the group the object is laid out with in the spec; Seasonal and Pickups are not
among the six kit groups and are audited so the 99 is complete. `Cls` is the floor class, `Floor` the floor used.

**Building kit (6)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_corner_bakery` | 4 | 22 | 200 | tier | 1050 | replace |
| `dt_apartment_block` | 5 | 40 | 348 | tier | 1500 | replace |
| `dt_corner_shop_row` | 5 | 26 | 432 | tier | 1500 | replace |
| `dt_glass_tower` | 5 | 60 | 224 | tier | 1500 | replace |
| `dt_glass_tower_bow` | 5 | 60 | 308 | tier | 1500 | replace |
| `dt_townhouse` | 5 | 30 | 152 | tier | 1500 | replace |

**Street kit (7)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_parking_meter` | 2 | 3.8 | 88 | tier | 210 | upgrade |
| `dt_traffic_cone` | 2 | 2 | 66 | tier | 210 | replace |
| `dt_recycling_bank` | 3 | 6 | 84 | tier | 450 | replace |
| `dt_street_lamp` | 3 | 9.5 | 80 | tier | 450 | replace |
| `dt_traffic_light` | 3 | 9.8 | 116 | tier | 450 | replace |
| `dt_billboard` | 4 | 18 | 84 | tier | 1050 | replace |
| `dt_bus_shelter` | 4 | 10 | 84 | tier | 1050 | replace |

**Park (5)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_potted_palm` | 2 | 3.2 | 124 | tier | 210 | upgrade |
| `dt_picnic_table` | 3 | 6 | 72 | tier | 450 | replace |
| `dt_street_tree` | 3 | 9 | 88 | tier | 450 | replace |
| `dt_big_street_tree` | 4 | 20 | 172 | tier | 1050 | replace |
| `dt_fountain` | 4 | 13 | 324 | tier | 1050 | replace |

**Suburbs (8)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_inflatable_flamingo` | 2 | 3 | 152 | tier | 210 | upgrade |
| `dt_wheelie_bin` | 2 | 3.5 | 64 | tier | 210 | replace |
| `dt_bicycle` | 3 | 6.5 | 180 | tier | 450 | upgrade |
| `dt_mailbox` | 3 | 4.5 | 72 | tier | 450 | replace |
| `dt_paddling_pool` | 3 | 8 | 288 | tier | 450 | upgrade |
| `dt_satellite_dish` | 3 | 5 | 136 | tier | 450 | replace |
| `dt_hatchback` | 4 | 14 | 216 | tier | 1050 | replace |
| `dt_pickup_truck` | 4 | 16 | 228 | tier | 1050 | replace |

**Main street (13)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_e_scooter` | 2 | 3.8 | 152 | tier | 210 | upgrade |
| `dt_fire_hydrant` | 2 | 2.4 | 176 | tier | 210 | upgrade |
| `dt_newspaper_box` | 2 | 3 | 60 | tier | 210 | replace |
| `dt_shopping_cart` | 2 | 3.6 | 132 | tier | 210 | upgrade |
| `dt_suitcase` | 2 | 2.6 | 76 | tier | 210 | upgrade |
| `dt_bench` | 3 | 7 | 48 | tier | 450 | replace |
| `dt_hot_dog_cart` | 3 | 7.5 | 152 | tier | 450 | replace |
| `dt_moped` | 3 | 6 | 140 | tier | 450 | replace |
| `dt_pallet_stack` | 3 | 5 | 156 | tier | 450 | replace |
| `dt_vending_machine` | 3 | 7 | 60 | tier | 450 | replace |
| `dt_delivery_van` | 4 | 17 | 204 | tier | 1050 | replace |
| `dt_kiosk` | 4 | 12 | 96 | tier | 1050 | replace |
| `dt_market_stall` | 4 | 12 | 164 | tier | 1050 | replace |

**Downtown (14)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_city_bus` | 4 | 25 | 260 | tier | 1050 | replace |
| `dt_donut_food_truck` | 4 | 18 | 416 | tier | 1050 | upgrade |
| `dt_fire_engine` | 4 | 24 | 300 | tier | 1050 | replace |
| `dt_garbage_truck` | 4 | 20 | 312 | tier | 1050 | replace |
| `dt_ice_cream_truck` | 4 | 15 | 258 | tier | 1050 | replace |
| `dt_monster_truck` | 4 | 18 | 360 | tier | 1050 | replace |
| `dt_shipping_container` | 4 | 20 | 192 | tier | 1050 | replace |
| `dt_taxi` | 4 | 14 | 216 | tier | 1050 | replace |
| `dt_cinema` | 5 | 36 | 204 | tier | 1500 | replace |
| `dt_ev_charging_station` | 5 | 32 | 224 | tier | 1500 | replace |
| `dt_ferris_wheel` | 5 | 50 | 460 | tier | 1500 | replace |
| `dt_giant_duck` | 5 | 35 | 272 | tier | 1500 | replace |
| `dt_rocket_water_tower` | 5 | 34 | 262 | tier | 1500 | replace |
| `dt_tower_crane` | 5 | 55 | 192 | tier | 1500 | replace |

**Seasonal (19)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_bauble` | 1 | 0.6 | 76 | pocket | 40 | keep |
| `dt_fairy_light_bulb` | 1 | 0.5 | 40 | pocket | 40 | keep |
| `dt_gingerbread_cookie` | 1 | 1 | 112 | tier | 150 | upgrade |
| `dt_ice_lolly` | 1 | 0.6 | 44 | pocket | 40 | keep |
| `dt_mini_gift` | 1 | 0.9 | 56 | tier | 150 | upgrade |
| `dt_gift_box` | 2 | 2 | 56 | tier | 210 | replace |
| `dt_leaning_present_stack` | 2 | 3.6 | 80 | tier | 210 | upgrade |
| `dt_poinsettia_pot` | 2 | 2.4 | 156 | tier | 210 | upgrade |
| `dt_wooden_sled` | 2 | 3.2 | 100 | tier | 210 | upgrade |
| `dt_wreath` | 2 | 2.8 | 200 | tier | 210 | upgrade |
| `dt_cocoa_cart` | 3 | 6.5 | 220 | tier | 450 | upgrade |
| `dt_light_up_reindeer` | 3 | 7 | 160 | tier | 450 | upgrade |
| `dt_snow_pile` | 3 | 6 | 120 | flat | 24 | keep |
| `dt_snowman` | 3 | 8 | 356 | tier | 450 | upgrade |
| `dt_cocoa_truck` | 4 | 18 | 320 | tier | 1050 | replace |
| `dt_sleigh` | 4 | 15 | 108 | tier | 1050 | replace |
| `dt_snowplough` | 4 | 22 | 236 | tier | 1050 | replace |
| `dt_ice_rink` | 5 | 40 | 564 | flat | 24 | keep |
| `dt_mega_tree` | 5 | 45 | 418 | tier | 1500 | replace |

**Pickups (27)**

| Id | Tier | Size | Tris | Cls | Floor | Baseline |
| --- | --- | --- | --- | --- | --- | --- |
| `dt_aa_battery` | 1 | 0.4 | 76 | pocket | 40 | keep |
| `dt_basketball` | 1 | 1 | 116 | tier | 150 | upgrade |
| `dt_bottle_cap` | 1 | 0.3 | 72 | pocket | 40 | keep |
| `dt_coffee_cup` | 1 | 0.7 | 108 | pocket | 40 | keep |
| `dt_donut` | 1 | 0.8 | 180 | pocket | 40 | keep |
| `dt_earbud_case` | 1 | 0.5 | 24 | pocket | 40 | upgrade |
| `dt_game_controller` | 1 | 0.9 | 108 | tier | 150 | upgrade |
| `dt_headphones` | 1 | 1 | 136 | tier | 150 | upgrade |
| `dt_keyboard` | 1 | 1.5 | 132 | tier | 150 | upgrade |
| `dt_lost_sneaker` | 1 | 1.3 | 48 | tier | 150 | replace |
| `dt_pizza_slice` | 1 | 0.9 | 68 | tier | 150 | upgrade |
| `dt_puzzle_cube` | 1 | 0.5 | 36 | pocket | 40 | upgrade |
| `dt_rubber_duck_sunglasses` | 1 | 1.2 | 64 | tier | 150 | upgrade |
| `dt_smartphone` | 1 | 0.8 | 24 | pocket | 40 | upgrade |
| `dt_soda_can` | 1 | 0.6 | 84 | pocket | 40 | keep |
| `dt_takeout_box` | 1 | 1.2 | 40 | tier | 150 | replace |
| `dt_tennis_ball` | 1 | 0.6 | 68 | pocket | 40 | keep |
| `dt_water_bottle` | 1 | 0.9 | 92 | tier | 150 | upgrade |
| `dt_acoustic_guitar` | 2 | 3 | 92 | tier | 210 | upgrade |
| `dt_beach_ball` | 2 | 2 | 220 | tier | 210 | keep |
| `dt_boombox_speaker` | 2 | 2 | 108 | tier | 210 | upgrade |
| `dt_pizza_box_tower` | 2 | 3.9 | 96 | tier | 210 | upgrade |
| `dt_skateboard` | 2 | 2.2 | 148 | tier | 210 | upgrade |
| `dt_spinning_office_chair` | 2 | 3.4 | 124 | tier | 210 | upgrade |
| `dt_arcade_cabinet` | 3 | 6.5 | 100 | tier | 450 | replace |
| `dt_drum_kit` | 3 | 5 | 300 | tier | 450 | upgrade |
| `dt_inflatable_tube_guy` | 3 | 9 | 276 | tier | 450 | upgrade |

## 2. Zone Asset Kit entry (one per new `ck_*` mesh, 84 rows)

| Field | Type | Rule |
| --- | --- | --- |
| `id` | string | `snake_case`, unique inside `CityKit` |
| `assetKey` | string | `"ck_" .. id`; the mesh file is `art/export/ck_<id>.fbx` |
| `zone` | `building` / `street` / `park` / `suburbs` / `mainstreet` / `downtown` / `meme` / `signage` | contact-sheet grouping |
| `tier`, `size` | number | size inside the tier band; `size <= Config.absorbRatio * TIER_CEILINGS[tier]` |
| `triTarget` | number | at most `Config.Budgets.meshTriangles[tier]`; at or above the class floor |
| `class` | `pocket` / `flat` / `panel` / `tier` | picks the floor |
| `atlas` | `"fronts"?` | set only on the 17 shop, billboard and buffering-billboard meshes (R-10) |
| `signCell` / `billboardCell` | string? | on a fronts object: the `sign_XX` or `bb_*` cell its faces use (`fronts.json`) |
| `nameKey` | string | `object.citykit.<id>`; `en` and `es` in `CityKitStrings` |
| `role` | string | accent colour role, one per object |

Triangle targets used below: T1 200, T2 300, T3 600, T4 1,400, T5 2,200; flats 24 to 80; vehicles 1,400 to 1,600; shop
buildings 2,000. All are above the class floor and below 60 % of the budget.

### 2.1 Building kit, 25 meshes (Building kit group, with the six upgraded `dt_` buildings above)

Modules (wall, window bay at 6 studs, door, shop front, awning, cornice, roof) at 1, 2 and 3 bays are Blender collections,
not exported meshes. Each variant below is one joined mesh.

| Id | Tier | Size | Tri target | Atlas | Note |
| --- | --- | --- | --- | --- | --- |
| `house_semi_garage` | 4 | 14 | 1,400 | theme | suburban, integral garage |
| `house_bungalow` | 4 | 12 | 1,200 | theme | single storey, hipped roof |
| `house_gable_fence` | 4 | 16 | 1,600 | theme | gable front, picket fence in the mesh |
| `house_corner_bay` | 4 | 15 | 1,500 | theme | bay window, side garage |
| `house_terrace_pair` | 4 | 20 | 1,800 | theme | two units, shared roof |
| `house_split_level` | 4 | 17 | 1,600 | theme | two roof heights |
| `shop_bakery` | 4 | 14 | 2,000 | fronts | awning, display window |
| `shop_grocer` | 4 | 16 | 2,000 | fronts | crates outside in the mesh |
| `shop_pizzeria` | 4 | 15 | 2,000 | fronts | corner door |
| `shop_cafe` | 4 | 13 | 2,000 | fronts | glass front |
| `shop_bookshop` | 4 | 18 | 2,000 | fronts | two-bay window |
| `shop_pharmacy_cross` | 4 | 17 | 2,000 | fronts | pictogram cross sign |
| `shop_row_three` | 5 | 28 | 2,200 | fronts | three fronts, shared cornice |
| `shop_row_arcade` | 5 | 34 | 2,200 | fronts | covered walkway |
| `shop_row_corner` | 5 | 38 | 2,200 | fronts | corner entrance, two streets |
| `midrise_brick_8` | 5 | 32 | 2,200 | theme | eight storeys, brick roles |
| `midrise_render_10` | 5 | 38 | 2,200 | theme | ten storeys, balconies |
| `midrise_setback` | 5 | 42 | 2,200 | theme | upper storey set back |
| `midrise_courtyard` | 5 | 36 | 2,200 | theme | U-shape |
| `midrise_corner_clock` | 5 | 44 | 2,200 | theme | corner clock face (pictogram) |
| `midrise_mixed` | 5 | 40 | 2,200 | theme | shop base, flats above |
| `tower_slab` | 5 | 52 | 2,200 | theme | repeating bays |
| `tower_stepped` | 5 | 56 | 2,200 | theme | three set-backs |
| `tower_twin` | 5 | 58 | 2,200 | theme | two cores, skybridge |
| `tower_crown` | 5 | 60 | 2,200 | theme | lit crown (`Neon` by material role) |

Per class, variants are 6 houses, 9 shop buildings, 6 mid-rise, 4 towers; each class has at least four, which meets the
no-neighbour-repeat condition (R-06).

### 2.2 Street kit, 11 meshes

| Id | Tier | Size | Tri target | Class | Note |
| --- | --- | --- | --- | --- | --- |
| `road_marking_dash` | 2 | 3.6 | 24 | flat | lane dash set |
| `road_marking_arrow` | 2 | 3.2 | 32 | flat | turn arrow |
| `crossing_zebra` | 3 | 8 | 80 | flat | pedestrian crossing |
| `kerb_corner` | 3 | 6 | 120 | flat | rounded corner, dropped kerb |
| `street_sign` | 2 | 3.4 | 300 | tier | pictogram only |
| `planter_box` | 2 | 2.8 | 300 | tier | planter with shrub |
| `bollard` | 1 | 1.3 | 200 | tier | single post |
| `railing_section` | 3 | 5.5 | 600 | tier | pedestrian railing |
| `bus_stop_pole` | 2 | 3.8 | 300 | tier | pole and pictogram plate |
| `street_lamp_double` | 3 | 9.6 | 600 | tier | two heads |
| `bin_street` | 2 | 2.2 | 300 | tier | litter bin |

Existing `dt_street_lamp`, `dt_traffic_light`, `dt_bus_shelter` cover the lamp, light and stop in the spec.

### 2.3 Park, 16 meshes

| Id | Tier | Size | Tri target | Class | Note |
| --- | --- | --- | --- | --- | --- |
| `tree_oak` | 4 | 16 | 1,100 | tier | broad canopy, five lobes |
| `tree_pine` | 4 | 18 | 1,100 | tier | stacked cone canopy |
| `tree_birch` | 3 | 8.5 | 600 | tier | slim, light trunk role |
| `bush` | 2 | 3 | 300 | tier | round |
| `hedge_row` | 3 | 6 | 600 | tier | clipped, flat top |
| `flower_bed` | 2 | 3.6 | 300 | tier | three colour roles |
| `picnic_blanket` | 2 | 2.8 | 24 | flat | checked pattern from the atlas |
| `picnic_basket` | 1 | 1.4 | 200 | tier | lid, handle |
| `swing_set` | 3 | 7 | 600 | tier | two swings |
| `slide` | 3 | 6.5 | 600 | tier | ladder, curved chute |
| `seesaw` | 2 | 3.8 | 300 | tier | plank and post |
| `climbing_frame` | 3 | 8 | 600 | tier | rope net as slats |
| `sandpit` | 3 | 5 | 80 | flat | timber surround |
| `path_straight` | 3 | 8 | 40 | flat | paving strip |
| `path_curve` | 3 | 8 | 80 | flat | quarter curve |
| `pond_edge` | 3 | 9.5 | 120 | flat | rocks and coping |

Existing `dt_picnic_table`, `dt_street_tree`, `dt_big_street_tree`, `dt_fountain` complete the park.

### 2.4 Suburbs, 7 meshes

| Id | Tier | Size | Tri target | Class | Note |
| --- | --- | --- | --- | --- | --- |
| `barbecue` | 2 | 2.6 | 300 | tier | kettle, legs |
| `lawn_mower` | 2 | 3.4 | 300 | tier | push mower |
| `garden_fence` | 3 | 6 | 600 | tier | picket section |
| `trampoline` | 3 | 6.5 | 600 | tier | net as slats |
| `garden_shed` | 3 | 8 | 600 | tier | gable roof |
| `car_sedan` | 4 | 15 | 1,500 | tier | driveway car |
| `car_estate` | 4 | 16 | 1,500 | tier | driveway car |

Existing `dt_mailbox`, `dt_wheelie_bin`, `dt_bicycle`, `dt_hatchback`, `dt_pickup_truck` complete the suburbs.

### 2.5 Main street, 5 meshes

| Id | Tier | Size | Tri target | Class | Note |
| --- | --- | --- | --- | --- | --- |
| `cafe_table_parasol` | 3 | 5.5 | 600 | tier | table, two chairs, parasol |
| `fruit_crates` | 2 | 2.6 | 300 | tier | stacked crates, fruit as colour roles |
| `sandwich_board` | 2 | 3.2 | 300 | tier | pictogram only |
| `bike_rack` | 2 | 3.6 | 300 | tier | four hoops |
| `post_box` | 2 | 3 | 300 | tier | pillar box, no real postal marks |

Existing `dt_newspaper_box`, `dt_fire_hydrant`, `dt_bench`, `dt_e_scooter`, `dt_delivery_van` complete the street.

### 2.6 Downtown, 6 meshes

| Id | Tier | Size | Tri target | Class | Note |
| --- | --- | --- | --- | --- | --- |
| `landmark_clock_tower` | 5 | 48 | 2,400 | tier | pictogram clock face |
| `landmark_obelisk` | 5 | 40 | 1,600 | tier | square plinth |
| `landmark_arch` | 5 | 34 | 2,400 | tier | triumphal arch, no inscription |
| `tram` | 4 | 24 | 1,600 | tier | two-section |
| `subway_entrance` | 4 | 11 | 1,400 | tier | stair canopy, pictogram |
| `limousine` | 4 | 18 | 1,500 | tier | stretch car |

Existing `dt_taxi`, `dt_city_bus`, `dt_kiosk`, `dt_cinema` and the glass towers complete downtown.

### 2.7 Signage, 7 meshes (all `atlas = "fronts"`, class `panel`, after strand 0)

| Id | Tier | Size | Tri target | Design cell | Gag |
| --- | --- | --- | --- | --- | --- |
| `billboard_404` | 4 | 18 | 500 | `bb_404` | a 404 number |
| `billboard_chart` | 4 | 18 | 500 | `bb_chart` | line going up and to the right, no axes text |
| `billboard_loading` | 4 | 18 | 500 | `bb_loading` | loading ring |
| `billboard_empty` | 4 | 18 | 500 | `bb_empty` | an empty frame |
| `billboard_arrow` | 4 | 18 | 500 | `bb_arrow` | arrow pointing at nothing |
| `billboard_testcard` | 5 | 26 | 600 | `bb_testcard` | colour bars |
| `billboard_nested` | 5 | 26 | 600 | `bb_nested` | a billboard of a billboard |

### 2.8 Meme originals, 7 meshes (zone `meme`)

| Id | Tier | Size | Tri target | Class | Slot | Idea (not image, name or music) |
| --- | --- | --- | --- | --- | --- | --- |
| `meme_wet_floor_sign` | 2 | 3 | 300 | tier | `slot.meme.t2` | a wet-floor sign in the middle of nowhere |
| `meme_pond_cart` | 3 | 4.6 | 600 | tier | `slot.meme.t3` | a shopping cart abandoned in a pond |
| `meme_cone_statue` | 4 | 12 | 1,400 | tier | `slot.meme.t4` | a statue wearing a traffic cone |
| `meme_phone_1pc` | 4 | 14 | 1,400 | tier | `slot.meme.t4` | a giant phone statue at 1 % (a number, no brand) |
| `meme_buffering_billboard` | 4 | 18 | 500 | panel | `slot.meme.t4` | a billboard that is stuck loading (fronts atlas) |
| `meme_banana_scale` | 5 | 28 | 2,200 | tier | `slot.meme.t5` | a banana statue, a person-sized plinth for scale |
| `meme_vacant_lot` | 5 | 30 | 80 | flat | `slot.meme.t5` | a bare grey stud-plate lot with a spawn pad, no logo |

### 2.9 Counts

| Group | New (`ck_`) | Retained or upgraded (`dt_`) |
| --- | --- | --- |
| Building kit | 25 | 6 |
| Street kit | 11 | 7 |
| Park | 16 | 5 |
| Suburbs | 7 | 8 |
| Main street | 5 | 13 |
| Downtown | 6 | 14 |
| Signage | 7 | 0 |
| Meme | 7 | 0 |
| Seasonal and Pickups | 0 | 46 |
| **Total** | **84** | **99** |

By tier (new): T1 2, T2 17, T3 18, T4 27, T5 20 (total 84). Every target is at or above its class floor and at most 60 % of
the tier budget.

## 3. Fronts atlas layout (1,024 px, generated per theme, same layout everywhere)

| Region | Cells | Cell size | Y range | Content |
| --- | --- | --- | --- | --- |
| Sign cells | 24 (4 across, 6 down) | 256 x 64 | 0 to 383 | one shop name each, two lines of at most 13 characters |
| Billboard cells | 8 (4 across, 2 down) | 256 x 128 | 384 to 639 | the 8 designs of `billboardTextures` |
| Facade strips | 6 | 1,024 x 64 | 640 to 1,023 | brick, render, curtain glass, shutters, shop glazing, cornice trim |

`fronts.json` lists the inner UV rect for each cell and strip, the way `art/palette.json` does for the theme atlas.

## 4. Billboard design (8 cells)

| Cell | Used by |
| --- | --- |
| `bb_404`, `bb_chart`, `bb_loading`, `bb_empty`, `bb_arrow`, `bb_testcard`, `bb_nested` | the 7 `billboard_*` meshes |
| `bb_buffering` | `meme_buffering_billboard` |

The cap is `Config.Budgets.billboardTextures = 8`; the number of `bb_*` cells in `fronts.json` is at most that.

## 5. Shop Sign Catalogue (26 candidates, at least 20 and at most 24 end up `clear`)

Candidate names are invented and unvetted until `contracts/shop-names-and-memes.md` has their search record.

| # | Candidate | Trade | # | Candidate | Trade |
| --- | --- | --- | --- | --- | --- |
| 1 | Blocky Mart | grocer | 14 | Sunny Side Diner | diner |
| 2 | Cafe Cube | cafe | 15 | Gadget Garage | electronics |
| 3 | Stud Pizza | pizzeria | 16 | Mitten Market | clothes |
| 4 | Crumb Corner | bakery | 17 | Cobble Cobbler | shoe repair |
| 5 | Noodle Nook | noodles | 18 | Button Tailor | tailor |
| 6 | Spoke & Chain | bike shop | 19 | Wick & Wax | candles |
| 7 | Plum Books | bookshop | 20 | Rivet Hardware | hardware |
| 8 | Lamp & Lens | optician | 21 | Toast Lab | breakfast |
| 9 | Daily Stack | newsagent | 22 | Dumpling Den | dumplings |
| 10 | Pocket Records | music | 23 | Hat Trick Barber | barber |
| 11 | Tin Can Toys | toys | 24 | Tidy Laundry | laundrette |
| 12 | Fern & Fig | florist | 25 | Brick & Bean | cafe |
| 13 | Corner Scoop | ice cream | 26 | Tuck Shop | sweets |

Fields per record: `name`, `trade`, `lines` (two strings), `searches` (queries run), `date`, `seen` (top results noted),
`verdict` (`clear`, `close`, `banned`), `note`, `cell` (sign cell index or `null`).

## 6. `slot.meme` binding

| Field | Rule |
| --- | --- |
| Slot ids | `slot.meme.t2` (tier 2), `.t3`, `.t4`, `.t5` in `ThemeResolve.SLOT_TIERS` |
| Binding | `themeBindings[theme].slots["slot.meme.t4"] = "<object id>"` |
| Object tier | must equal the slot's tier (existing error otherwise) |
| Swap | change the binding value; no layout, placement or Rules change |
| Share | counted with other dressing slots under `maxDressingSlotShare` (0.15) |

## 7. Zone Contact Sheet

| Field | Rule |
| --- | --- |
| `zone` | one of the eight zones above, plus `audit` |
| `theme` | `city` or `winter` |
| `path` | `contact-sheets/<theme>/<zone>.png` |
| `assets` | the ids shown, each with triangle count caption |
| `approved` | `null` until the owner approves (Gate 6) |

18 images: 9 sheets × 2 themes. The audit sheet may use up to three pages (`audit-1.png` to `audit-3.png`).

## 8. State flow of an asset

`dt_*`: audited, then `keep` (no change) or `upgrade`/`replace` (rebuilt, same key and size, new hash in the manifest,
old uploaded id kept in `Assets.luau` until the owner re-uploads).

`ck_*`: listed, built, exported (`""` in `Assets.luau`, row in the manifest), on a hand-off batch, uploaded by the owner,
id filled in.
