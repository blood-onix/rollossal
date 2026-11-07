# Audit of the 99 dt_* meshes (013 US1)

Verdicts: **12 keep, 36 upgrade, 51 replace** (triangle-only baseline 12 / 36 / 51). Class floors: pocket 40, flat 24, tier 150 / 210 / 450 / 1,050 / 1,500 (style bible section 11). `seasonShare` is the area share of w-season UVs; it depends on the mesh only, so city and winter match.

## Headroom (winter city, Downtown N10 sum)

| | Now | Every upgrade and replacement at its floor | At its target | Ceiling |
| --- | --- | --- | --- | --- |
| Unculled | 189,802 | 574,598 | 785,988 | 550,000 |
| Culled (tier 4 and 5) | 54,552 | 301,164 | 413,164 | 290,000 |

Reading: this is the 013 finding on scene cost. Rebuilding every non-keep mesh to its floor already exceeds the unculled or culled ceiling when the table above says so, so the upgrades cannot all land at once. They are built highest-visibility first, Downtown N10 is re-run after each batch and the order stops when the headroom runs out (research R-03); the ceilings are not raised. The heaviest placed meshes are the kiosk, taxi, corner bakery, apartment block, townhouse and the hatchback, van and pickup.

## Meshes

| Id | Tier | Size | Tris | Budget | Class | Floor | Fill | Season | Verdict | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `dt_aa_battery` | 1 | 0.4 | 76 | 500 | pocket | 40 | 1.9 | 0.00 | keep | 76 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_acoustic_guitar` | 2 | 3 | 92 | 700 | tier | 210 | 0.438 | 0.00 | upgrade | 92 triangles is 0.44 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_apartment_block` | 5 | 40 | 348 | 5000 | tier | 1500 | 0.232 | 0.00 | replace | 348 triangles is 0.23 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_arcade_cabinet` | 3 | 6.5 | 100 | 1500 | tier | 450 | 0.222 | 0.00 | replace | 100 triangles is 0.22 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_basketball` | 1 | 1 | 116 | 500 | tier | 150 | 0.773 | 0.00 | upgrade | 116 triangles is 0.77 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_bauble` | 1 | 0.6 | 76 | 500 | pocket | 40 | 1.9 | 0.00 | keep | 76 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_beach_ball` | 2 | 2 | 220 | 700 | tier | 210 | 1.048 | 0.00 | keep | 220 triangles meets the tier floor 210 and w-season stays under 15%. |
| `dt_bench` | 3 | 7 | 48 | 1500 | tier | 450 | 0.107 | 0.00 | replace | 48 triangles is 0.11 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_bicycle` | 3 | 6.5 | 180 | 1500 | tier | 450 | 0.4 | 0.00 | upgrade | 180 triangles is 0.40 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_big_street_tree` | 4 | 20 | 172 | 3500 | tier | 1050 | 0.164 | 0.00 | replace | 172 triangles is 0.16 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_billboard` | 4 | 18 | 84 | 3500 | tier | 1050 | 0.08 | 0.00 | replace | 84 triangles is 0.08 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_boombox_speaker` | 2 | 2 | 108 | 700 | tier | 210 | 0.514 | 0.00 | upgrade | 108 triangles is 0.51 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_bottle_cap` | 1 | 0.3 | 72 | 500 | pocket | 40 | 1.8 | 0.00 | keep | 72 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_bus_shelter` | 4 | 10 | 84 | 3500 | tier | 1050 | 0.08 | 0.00 | replace | 84 triangles is 0.08 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_cinema` | 5 | 36 | 204 | 5000 | tier | 1500 | 0.136 | 0.00 | replace | 204 triangles is 0.14 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_city_bus` | 4 | 25 | 260 | 3500 | tier | 1050 | 0.248 | 0.00 | replace | 260 triangles is 0.25 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_cocoa_cart` | 3 | 6.5 | 220 | 1500 | tier | 450 | 0.489 | 0.00 | upgrade | 220 triangles is 0.49 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_cocoa_truck` | 4 | 18 | 320 | 3500 | tier | 1050 | 0.305 | 0.00 | replace | 320 triangles is 0.30 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_coffee_cup` | 1 | 0.7 | 108 | 500 | pocket | 40 | 2.7 | 0.00 | keep | 108 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_corner_bakery` | 4 | 22 | 200 | 3500 | tier | 1050 | 0.19 | 0.00 | replace | 200 triangles is 0.19 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_corner_shop_row` | 5 | 26 | 432 | 5000 | tier | 1500 | 0.288 | 0.00 | replace | 432 triangles is 0.29 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_delivery_van` | 4 | 17 | 204 | 3500 | tier | 1050 | 0.194 | 0.00 | replace | 204 triangles is 0.19 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_donut` | 1 | 0.8 | 180 | 500 | pocket | 40 | 4.5 | 0.00 | keep | 180 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_donut_food_truck` | 4 | 18 | 416 | 3500 | tier | 1050 | 0.396 | 0.00 | upgrade | 416 triangles is 0.40 of the tier floor 1050; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_drum_kit` | 3 | 5 | 300 | 1500 | tier | 450 | 0.667 | 0.00 | upgrade | 300 triangles is 0.67 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_e_scooter` | 2 | 3.8 | 152 | 700 | tier | 210 | 0.724 | 0.00 | upgrade | 152 triangles is 0.72 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_earbud_case` | 1 | 0.5 | 24 | 500 | pocket | 40 | 0.6 | 0.00 | upgrade | 24 triangles is 0.60 of the pocket floor 40; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_ev_charging_station` | 5 | 32 | 224 | 5000 | tier | 1500 | 0.149 | 0.00 | replace | 224 triangles is 0.15 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_fairy_light_bulb` | 1 | 0.5 | 40 | 500 | pocket | 40 | 1.0 | 0.00 | keep | 40 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_ferris_wheel` | 5 | 50 | 460 | 5000 | tier | 1500 | 0.307 | 0.00 | replace | 460 triangles is 0.31 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_fire_engine` | 4 | 24 | 300 | 3500 | tier | 1050 | 0.286 | 0.00 | replace | 300 triangles is 0.29 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_fire_hydrant` | 2 | 2.4 | 176 | 700 | tier | 210 | 0.838 | 0.00 | upgrade | 176 triangles is 0.84 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_fountain` | 4 | 13 | 324 | 3500 | tier | 1050 | 0.309 | 0.00 | replace | 324 triangles is 0.31 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_game_controller` | 1 | 0.9 | 108 | 500 | tier | 150 | 0.72 | 0.00 | upgrade | 108 triangles is 0.72 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_garbage_truck` | 4 | 20 | 312 | 3500 | tier | 1050 | 0.297 | 0.00 | replace | 312 triangles is 0.30 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_giant_duck` | 5 | 35 | 272 | 5000 | tier | 1500 | 0.181 | 0.00 | replace | 272 triangles is 0.18 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_gift_box` | 2 | 2 | 56 | 700 | tier | 210 | 0.267 | 0.00 | replace | 56 triangles is 0.27 of the tier floor 210 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_gingerbread_cookie` | 1 | 1 | 112 | 500 | tier | 150 | 0.747 | 0.00 | upgrade | 112 triangles is 0.75 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_glass_tower` | 5 | 60 | 224 | 5000 | tier | 1500 | 0.149 | 0.00 | replace | 224 triangles is 0.15 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_glass_tower_bow` | 5 | 60 | 308 | 5000 | tier | 1500 | 0.205 | 0.00 | replace | 308 triangles is 0.20 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_hatchback` | 4 | 14 | 216 | 3500 | tier | 1050 | 0.206 | 0.00 | replace | 216 triangles is 0.21 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_headphones` | 1 | 1 | 136 | 500 | tier | 150 | 0.907 | 0.00 | upgrade | 136 triangles is 0.91 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_hot_dog_cart` | 3 | 7.5 | 152 | 1500 | tier | 450 | 0.338 | 0.00 | replace | 152 triangles is 0.34 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_ice_cream_truck` | 4 | 15 | 258 | 3500 | tier | 1050 | 0.246 | 0.00 | replace | 258 triangles is 0.25 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_ice_lolly` | 1 | 0.6 | 44 | 500 | pocket | 40 | 1.1 | 0.00 | keep | 44 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_ice_rink` | 5 | 40 | 564 | 5000 | flat | 24 | 23.5 | 0.00 | keep | 564 triangles meets the flat floor 24 and w-season stays under 15%. |
| `dt_inflatable_flamingo` | 2 | 3 | 152 | 700 | tier | 210 | 0.724 | 0.00 | upgrade | 152 triangles is 0.72 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_inflatable_tube_guy` | 3 | 9 | 276 | 1500 | tier | 450 | 0.613 | 0.00 | upgrade | 276 triangles is 0.61 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_keyboard` | 1 | 1.5 | 132 | 500 | tier | 150 | 0.88 | 0.00 | upgrade | 132 triangles is 0.88 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_kiosk` | 4 | 12 | 96 | 3500 | tier | 1050 | 0.091 | 0.00 | replace | 96 triangles is 0.09 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_leaning_present_stack` | 2 | 3.6 | 80 | 700 | tier | 210 | 0.381 | 0.00 | upgrade | 80 triangles is 0.38 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_light_up_reindeer` | 3 | 7 | 160 | 1500 | tier | 450 | 0.356 | 0.00 | upgrade | 160 triangles is 0.36 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_lost_sneaker` | 1 | 1.3 | 48 | 500 | tier | 150 | 0.32 | 0.00 | replace | 48 triangles is 0.32 of the tier floor 150 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_mailbox` | 3 | 4.5 | 72 | 1500 | tier | 450 | 0.16 | 0.00 | replace | 72 triangles is 0.16 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_market_stall` | 4 | 12 | 164 | 3500 | tier | 1050 | 0.156 | 0.00 | replace | 164 triangles is 0.16 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_mega_tree` | 5 | 45 | 418 | 5000 | tier | 1500 | 0.279 | 0.00 | replace | 418 triangles is 0.28 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_mini_gift` | 1 | 0.9 | 56 | 500 | tier | 150 | 0.373 | 0.00 | upgrade | 56 triangles is 0.37 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_monster_truck` | 4 | 18 | 360 | 3500 | tier | 1050 | 0.343 | 0.00 | replace | 360 triangles is 0.34 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_moped` | 3 | 6 | 140 | 1500 | tier | 450 | 0.311 | 0.00 | replace | 140 triangles is 0.31 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_newspaper_box` | 2 | 3 | 60 | 700 | tier | 210 | 0.286 | 0.00 | replace | 60 triangles is 0.29 of the tier floor 210 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_paddling_pool` | 3 | 8 | 288 | 1500 | tier | 450 | 0.64 | 0.00 | upgrade | 288 triangles is 0.64 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_pallet_stack` | 3 | 5 | 156 | 1500 | tier | 450 | 0.347 | 0.00 | replace | 156 triangles is 0.35 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_parking_meter` | 2 | 3.8 | 88 | 700 | tier | 210 | 0.419 | 0.00 | upgrade | 88 triangles is 0.42 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_pickup_truck` | 4 | 16 | 228 | 3500 | tier | 1050 | 0.217 | 0.00 | replace | 228 triangles is 0.22 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_picnic_table` | 3 | 6 | 72 | 1500 | tier | 450 | 0.16 | 0.00 | replace | 72 triangles is 0.16 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_pizza_box_tower` | 2 | 3.9 | 96 | 700 | tier | 210 | 0.457 | 0.00 | upgrade | 96 triangles is 0.46 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_pizza_slice` | 1 | 0.9 | 68 | 500 | tier | 150 | 0.453 | 0.00 | upgrade | 68 triangles is 0.45 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_poinsettia_pot` | 2 | 2.4 | 156 | 700 | tier | 210 | 0.743 | 0.00 | upgrade | 156 triangles is 0.74 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_potted_palm` | 2 | 3.2 | 124 | 700 | tier | 210 | 0.59 | 0.00 | upgrade | 124 triangles is 0.59 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_puzzle_cube` | 1 | 0.5 | 36 | 500 | pocket | 40 | 0.9 | 0.00 | upgrade | 36 triangles is 0.90 of the pocket floor 40; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_recycling_bank` | 3 | 6 | 84 | 1500 | tier | 450 | 0.187 | 0.00 | replace | 84 triangles is 0.19 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_rocket_water_tower` | 5 | 34 | 262 | 5000 | tier | 1500 | 0.175 | 0.00 | replace | 262 triangles is 0.17 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_rubber_duck_sunglasses` | 1 | 1.2 | 64 | 500 | tier | 150 | 0.427 | 0.00 | upgrade | 64 triangles is 0.43 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_satellite_dish` | 3 | 5 | 136 | 1500 | tier | 450 | 0.302 | 0.00 | replace | 136 triangles is 0.30 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_shipping_container` | 4 | 20 | 192 | 3500 | tier | 1050 | 0.183 | 0.00 | replace | 192 triangles is 0.18 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_shopping_cart` | 2 | 3.6 | 132 | 700 | tier | 210 | 0.629 | 0.00 | upgrade | 132 triangles is 0.63 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_skateboard` | 2 | 2.2 | 148 | 700 | tier | 210 | 0.705 | 0.00 | upgrade | 148 triangles is 0.70 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_sleigh` | 4 | 15 | 108 | 3500 | tier | 1050 | 0.103 | 0.00 | replace | 108 triangles is 0.10 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_smartphone` | 1 | 0.8 | 24 | 500 | pocket | 40 | 0.6 | 0.00 | upgrade | 24 triangles is 0.60 of the pocket floor 40; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_snow_pile` | 3 | 6 | 120 | 1500 | flat | 24 | 5.0 | 0.00 | keep | 120 triangles meets the flat floor 24 and w-season stays under 15%. |
| `dt_snowman` | 3 | 8 | 356 | 1500 | tier | 450 | 0.791 | 0.00 | upgrade | 356 triangles is 0.79 of the tier floor 450; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_snowplough` | 4 | 22 | 236 | 3500 | tier | 1050 | 0.225 | 0.00 | replace | 236 triangles is 0.23 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_soda_can` | 1 | 0.6 | 84 | 500 | pocket | 40 | 2.1 | 0.00 | keep | 84 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_spinning_office_chair` | 2 | 3.4 | 124 | 700 | tier | 210 | 0.59 | 0.00 | upgrade | 124 triangles is 0.59 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_street_lamp` | 3 | 9.5 | 80 | 1500 | tier | 450 | 0.178 | 0.00 | replace | 80 triangles is 0.18 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_street_tree` | 3 | 9 | 88 | 1500 | tier | 450 | 0.196 | 0.00 | replace | 88 triangles is 0.20 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_suitcase` | 2 | 2.6 | 76 | 700 | tier | 210 | 0.362 | 0.00 | upgrade | 76 triangles is 0.36 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_takeout_box` | 1 | 1.2 | 40 | 500 | tier | 150 | 0.267 | 0.00 | replace | 40 triangles is 0.27 of the tier floor 150 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_taxi` | 4 | 14 | 216 | 3500 | tier | 1050 | 0.206 | 0.00 | replace | 216 triangles is 0.21 of the tier floor 1050 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_tennis_ball` | 1 | 0.6 | 68 | 500 | pocket | 40 | 1.7 | 0.00 | keep | 68 triangles meets the pocket floor 40 and w-season stays under 15%. |
| `dt_tower_crane` | 5 | 55 | 192 | 5000 | tier | 1500 | 0.128 | 0.00 | replace | 192 triangles is 0.13 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_townhouse` | 5 | 30 | 152 | 5000 | tier | 1500 | 0.101 | 0.00 | replace | 152 triangles is 0.10 of the tier floor 1500 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_traffic_cone` | 2 | 2 | 66 | 700 | tier | 210 | 0.314 | 0.00 | replace | 66 triangles is 0.31 of the tier floor 210 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_traffic_light` | 3 | 9.8 | 116 | 1500 | tier | 450 | 0.258 | 0.00 | replace | 116 triangles is 0.26 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_vending_machine` | 3 | 7 | 60 | 1500 | tier | 450 | 0.133 | 0.00 | replace | 60 triangles is 0.13 of the tier floor 450 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_water_bottle` | 1 | 0.9 | 92 | 500 | tier | 150 | 0.613 | 0.00 | upgrade | 92 triangles is 0.61 of the tier floor 150; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_wheelie_bin` | 2 | 3.5 | 64 | 700 | tier | 210 | 0.305 | 0.00 | replace | 64 triangles is 0.30 of the tier floor 210 (under 0.35), so the silhouette cannot meet the style bible and is rebuilt from a new recipe. |
| `dt_wooden_sled` | 2 | 3.2 | 100 | 700 | tier | 210 | 0.476 | 0.00 | upgrade | 100 triangles is 0.48 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
| `dt_wreath` | 2 | 2.8 | 200 | 700 | tier | 210 | 0.952 | 0.00 | upgrade | 200 triangles is 0.95 of the tier floor 210; the silhouette is kept and rebuilt with bevels and detail up to the floor-to-target band. |
