# Rework audit of the 99 dt_* meshes (013 Phase 9, T078)

Rules: style bible sections 2 and 3, owner decision 2026-11-07. Buildings need a 70 % muted share; tier 3 to 5 buildings and tier 4 to 5 hero props need 60 % of the tier ceiling; props with round parts must be smooth-shaded (boxy props are exempt); w-season stays under 15 %. Replace when the mesh is under 0.35 of what it needs.

Verdicts: **35 keep, 63 upgrade, 1 replace**.

## Headroom (winter city, Downtown N10 sum)

| | Now | Every placed mesh at what it needs | Ceiling |
| --- | --- | --- | --- |
| Unculled | 549,946 | 879,794 | 550,000 |
| Culled (tier 4 and 5) | 271,916 | 601,764 | 290,000 |

Reading: raising every placed mesh to what the new rules ask exceeds a Downtown N10 ceiling, so the rebuilds go in batches, highest-visibility first, and stop where the headroom runs out (research R-03); the ceilings are not raised.

## Meshes

| Id | Tier | Role | Tris | % of ceiling | Needs | Muted | Smooth | Verdict | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `dt_aa_battery` | 1 | prop | 76 | 15% | 40 | 35% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_acoustic_guitar` | 2 | prop | 216 | 31% | 210 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_apartment_block` | 5 | building | 1500 | 30% | 3000 | 100% | 0% | upgrade | 1500 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_arcade_cabinet` | 3 | prop | 452 | 30% | 450 | 13% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_basketball` | 1 | prop | 154 | 31% | 150 | 14% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_bauble` | 1 | prop | 76 | 15% | 40 | 0% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_beach_ball` | 2 | prop | 220 | 31% | 210 | 81% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_bench` | 3 | prop | 456 | 30% | 450 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_bicycle` | 3 | prop | 452 | 30% | 450 | 55% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_big_street_tree` | 4 | hero | 1052 | 30% | 2100 | 100% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_billboard` | 4 | hero | 1052 | 30% | 2100 | 61% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_boombox_speaker` | 2 | prop | 212 | 30% | 210 | 15% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_bottle_cap` | 1 | prop | 72 | 14% | 40 | 36% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_bus_shelter` | 4 | hero | 1052 | 30% | 2100 | 95% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_cinema` | 5 | building | 1500 | 30% | 3000 | 72% | 0% | upgrade | 1500 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_city_bus` | 4 | hero | 1052 | 30% | 2100 | 55% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_cocoa_cart` | 3 | prop | 452 | 30% | 450 | 37% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_cocoa_truck` | 4 | hero | 1056 | 30% | 2100 | 46% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_coffee_cup` | 1 | prop | 108 | 22% | 40 | 100% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_corner_bakery` | 4 | building | 1056 | 30% | 2100 | 95% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_corner_shop_row` | 5 | building | 1504 | 30% | 3000 | 97% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_delivery_van` | 4 | hero | 1052 | 30% | 2100 | 96% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_donut` | 1 | prop | 180 | 36% | 40 | 61% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_donut_food_truck` | 4 | hero | 1056 | 30% | 2100 | 44% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_drum_kit` | 3 | prop | 460 | 31% | 450 | 27% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_e_scooter` | 2 | prop | 216 | 31% | 210 | 70% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_earbud_case` | 1 | prop | 40 | 8% | 40 | 100% | 72% | keep | meets every 2026-11-07 rule that applies |
| `dt_ev_charging_station` | 5 | hero | 1504 | 30% | 3000 | 99% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_fairy_light_bulb` | 1 | prop | 180 | 36% | 40 | 100% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_ferris_wheel` | 5 | hero | 1504 | 30% | 3000 | 98% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_fire_engine` | 4 | hero | 1052 | 30% | 2100 | 35% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_fire_hydrant` | 2 | prop | 220 | 31% | 210 | 10% | 90% | keep | meets every 2026-11-07 rule that applies |
| `dt_fountain` | 4 | hero | 1052 | 30% | 2100 | 100% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_game_controller` | 1 | prop | 152 | 30% | 150 | 1% | 99% | keep | meets every 2026-11-07 rule that applies |
| `dt_garbage_truck` | 4 | hero | 1056 | 30% | 2100 | 49% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_giant_duck` | 5 | hero | 1504 | 30% | 3000 | 3% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_gift_box` | 2 | prop | 212 | 30% | 210 | 0% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_gingerbread_cookie` | 1 | prop | 300 | 60% | 150 | 100% | 75% | keep | meets every 2026-11-07 rule that applies |
| `dt_glass_tower` | 5 | building | 1504 | 30% | 3000 | 100% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_glass_tower_bow` | 5 | building | 1500 | 30% | 3000 | 70% | 0% | upgrade | 1500 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_hatchback` | 4 | hero | 1056 | 30% | 2100 | 21% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_headphones` | 1 | prop | 152 | 30% | 150 | 61% | 92% | keep | meets every 2026-11-07 rule that applies |
| `dt_hot_dog_cart` | 3 | prop | 456 | 30% | 450 | 33% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_ice_cream_truck` | 4 | hero | 1056 | 30% | 2100 | 68% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_ice_lolly` | 1 | prop | 108 | 22% | 40 | 11% | 89% | keep | meets every 2026-11-07 rule that applies |
| `dt_ice_rink` | 5 | prop | 564 | 11% | 24 | 98% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_inflatable_flamingo` | 2 | prop | 216 | 31% | 210 | 48% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_inflatable_tube_guy` | 3 | prop | 452 | 30% | 450 | 15% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_keyboard` | 1 | prop | 188 | 38% | 150 | 100% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_kiosk` | 4 | building | 184 | 5% | 2100 | 65% | 0% | replace | 184 triangles is 5% of the 3500 ceiling, under 60 % of the tier ceiling (2100); muted share 65% is under the 70 % building rule: rebuilt from a new kit_rework recipe |
| `dt_leaning_present_stack` | 2 | prop | 216 | 31% | 210 | 22% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_light_up_reindeer` | 3 | prop | 456 | 30% | 450 | 0% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_lost_sneaker` | 1 | prop | 228 | 46% | 150 | 50% | 50% | keep | meets every 2026-11-07 rule that applies |
| `dt_mailbox` | 3 | prop | 456 | 30% | 450 | 15% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_market_stall` | 4 | hero | 1052 | 30% | 2100 | 60% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_mega_tree` | 5 | hero | 1502 | 30% | 3000 | 74% | 0% | upgrade | 1502 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_mini_gift` | 1 | prop | 152 | 30% | 150 | 0% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_monster_truck` | 4 | hero | 1064 | 30% | 2100 | 56% | 0% | upgrade | 1064 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_moped` | 3 | prop | 452 | 30% | 450 | 42% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_newspaper_box` | 2 | prop | 216 | 31% | 210 | 49% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_paddling_pool` | 3 | prop | 460 | 31% | 450 | 33% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_pallet_stack` | 3 | prop | 456 | 30% | 450 | 100% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_parking_meter` | 2 | prop | 216 | 31% | 210 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_pickup_truck` | 4 | hero | 1060 | 30% | 2100 | 39% | 0% | upgrade | 1060 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_picnic_table` | 3 | prop | 456 | 30% | 450 | 96% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_pizza_box_tower` | 2 | prop | 216 | 31% | 210 | 53% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_pizza_slice` | 1 | prop | 164 | 33% | 150 | 65% | 26% | keep | meets every 2026-11-07 rule that applies |
| `dt_poinsettia_pot` | 2 | prop | 216 | 31% | 210 | 18% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_potted_palm` | 2 | prop | 212 | 30% | 210 | 57% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_puzzle_cube` | 1 | prop | 44 | 9% | 40 | 0% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_recycling_bank` | 3 | prop | 452 | 30% | 450 | 33% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_rocket_water_tower` | 5 | hero | 1506 | 30% | 3000 | 61% | 0% | upgrade | 1506 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_rubber_duck_sunglasses` | 1 | prop | 328 | 66% | 150 | 4% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_satellite_dish` | 3 | prop | 468 | 31% | 450 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_shipping_container` | 4 | hero | 1056 | 30% | 2100 | 41% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_shopping_cart` | 2 | prop | 216 | 31% | 210 | 96% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_skateboard` | 2 | prop | 212 | 30% | 210 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_sleigh` | 4 | hero | 1052 | 30% | 2100 | 19% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_smartphone` | 1 | prop | 40 | 8% | 40 | 100% | 62% | keep | meets every 2026-11-07 rule that applies |
| `dt_snow_pile` | 3 | prop | 120 | 8% | 24 | 100% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_snowman` | 3 | prop | 452 | 30% | 450 | 89% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_snowplough` | 4 | hero | 1052 | 30% | 2100 | 23% | 0% | upgrade | 1052 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_soda_can` | 1 | prop | 84 | 17% | 40 | 25% | 98% | keep | meets every 2026-11-07 rule that applies |
| `dt_spinning_office_chair` | 2 | prop | 212 | 30% | 210 | 26% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_street_lamp` | 3 | prop | 452 | 30% | 450 | 98% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_street_tree` | 3 | prop | 456 | 30% | 450 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_suitcase` | 2 | prop | 212 | 30% | 210 | 9% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_takeout_box` | 1 | prop | 152 | 30% | 150 | 19% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_taxi` | 4 | hero | 1056 | 30% | 2100 | 26% | 0% | upgrade | 1056 triangles is 30% of the 3500 ceiling, under 60 % of the tier ceiling (2100); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_tennis_ball` | 1 | prop | 64 | 13% | 40 | 0% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_tower_crane` | 5 | hero | 1504 | 30% | 3000 | 10% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000); round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_townhouse` | 5 | building | 1504 | 30% | 3000 | 100% | 0% | upgrade | 1504 triangles is 30% of the 5000 ceiling, under 60 % of the tier ceiling (3000): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_traffic_cone` | 2 | prop | 214 | 31% | 210 | 66% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_traffic_light` | 3 | prop | 452 | 30% | 450 | 85% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_vending_machine` | 3 | prop | 452 | 30% | 450 | 21% | 0% | keep | meets every 2026-11-07 rule that applies |
| `dt_water_bottle` | 1 | prop | 156 | 31% | 150 | 66% | 100% | keep | meets every 2026-11-07 rule that applies |
| `dt_wheelie_bin` | 2 | prop | 212 | 30% | 210 | 100% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_wooden_sled` | 2 | prop | 216 | 31% | 210 | 95% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
| `dt_wreath` | 2 | prop | 216 | 31% | 210 | 89% | 0% | upgrade | round parts are flat-shaded (smooth share 0%): silhouette kept, rebuilt smooth and to the triangle target |
