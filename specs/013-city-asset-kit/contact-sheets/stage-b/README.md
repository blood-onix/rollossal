# Stage B: tween-appeal rework rolled out to the kit (013 Phase 9, T076–T079)

Every `ck_*` asset (121 after Stage C) rebuilt by `art/scripts/kit_rework.py` (recipes in `kit_stage_b_buildings.py` and
`kit_stage_b_props.py`) at real size (1 m = 3.2 studs, clamped into the tier band by `kit_sizes.py`), the 12 new urban
props added (T077), and the 99 `dt_*` meshes re-audited with the new rules (T078). The vehicles follow the approved
pilot sedan's profile build. All images are EEVEE renders of the built meshes with the theme atlas and theme lighting
(`art/scripts/stage_b_shots.py`); they are not Studio captures.

## Images (gate 6, held on owner approval)

| What | Files |
|---|---|
| Contact sheets, three-quarter street level, by group | `street-<city|winter>-<group>.png` |
| Contact sheets, top view, by group | `top-<city|winter>-<group>.png` |
| Main street (shop rows, mid-rise, tower, traffic lights, meter, scooter dock, food truck, phone kiosk, scaffolding, neon sign, rooftop water tank, taxi, sports car, motorbike), D1 and D5 | `scene-mainstreet-<city|winter>-d<1|5>.png` |
| Suburb corner (four houses, fences, shed, mower, barbecue, skip, estate car), D1 and D5 | `scene-suburb-<city|winter>-d<1|5>.png` |
| Before / after (top: kit before the rework; bottom: Stage B) | `before-after-<city|winter>-<houses-shops|downtown|street|park>.png` |

Groups: houses-shops, rows-midrises-towers, street, park, suburbs-mainstreet, downtown, signage-memes.

## Rules check (`report.json`)

- Buildings (25): muted share 98% to 100% (rule: 70 %); triangles 60% to 99% of the tier ceiling (rule: 60 %).
- Tier 4 and 5 hero props: all at 60 % of the ceiling or more. No mesh is over its ceiling.
- Smooth shading: every prop with round parts has smooth-shaded faces. Flat decals (road markings, crossing, paths,
  picnic blanket) have none by design; seesaw, climbing frame and sandpit were not reworked and are out of default
  placements (`CityKit.notDefault`).
- `w-glow` is used by the neon rooftop sign only (tier 4 hero).

## 99-mesh `dt_*` audit with the new rules (T078)

`specs/013-city-asset-kit/audit/audit-rework.md`: **35 keep, 63 upgrade, 1 replace** (after Stage C).
Most upgrades are flat-shaded round parts; tier 3 to 5 buildings and heroes are also under 60 % of the ceiling.
Raising every placed `dt_*` mesh to what the rules ask would put the winter Downtown N10 sum at 879,766
unculled and 601,764 culled against 550,000 and 290,000 (now 549,918 and 271,916),
so those rebuilds wait for an owner decision (see `docs/release-candidate.md`).

The audit also found a bug: `dt_upgrade.py` read swatch tags through stale face references, so 87 rebuilt `dt_*`
meshes had every face on `w-metal`. Fixed, all 99 rebuilt with the same triangle counts and re-exported.

## Stage C: the small end (owner request 2026-11-08)

The kit had 2 tier 1 objects and no tier 2 object under 3.1 studs. Stage C (`art/scripts/kit_stage_c.py`) adds:

- **25 new kit objects**:
  - Tier 1: chip bag, padlock, newspaper bundle, soccer ball, flying disc, sand pail and shovel, garden gnome, watering
    can, flower pot, recycling box, grocery bag, cupcake, sunglasses.
  - Tier 2, 1.6 to 3.1 studs: traffic cone, kick scooter, cardboard boxes, bistro chair, flower buckets, potted shrub,
    leaf pile, bird bath, cooler, kid's bike, toolbox, rain barrel.
  - Images: `street-<theme>-small-tier1.png`, `street-<theme>-small-tier2.png` and the top views.
- **The Downtown pocket set rebuilt in the kit style** (19 `dt_*` tier 1 meshes): smooth round parts, real proportions,
  same keys and sizes. Images: `street-<theme>-pocket.png`, `top-<theme>-pocket.png`.
  - Winter Downtown had 82 triangles of headroom under its 550,000 ceiling. Heavily placed meshes stay at or under
    their old counts, and the rarely placed duck, sneaker and keyboard take the extra detail.
  - The placement-weighted sum grew by 28, to 549,946.
  - The cost: the tennis ball and the bauble stay 8 × 5 spheres and read slightly faceted up close.
- **The D1 and D5 street scenes now have small objects at ball height**: litter, cones, boxes, chairs and planters on
  the main street; gnome, watering can, bike, ball, leaf pile and bird bath in the front gardens.

## Per asset

| Asset | Zone | Tier | Triangles | % of ceiling | Muted | Smooth | Size (studs) |
|---|---|---|---|---|---|---|---|
| `ck_house_bungalow` | building | 4 | 2,670 / 3,500 | 76.3% | 100% | 4% | 25 |
| `ck_house_corner_bay` | building | 4 | 3,172 / 3,500 | 90.6% | 100% | 17% | 25 |
| `ck_house_gable_fence` | building | 4 | 3,234 / 3,500 | 92.4% | 100% | 3% | 24.5 |
| `ck_house_semi_garage` | building | 4 | 2,314 / 3,500 | 66.1% | 100% | 2% | 25 |
| `ck_house_split_level` | building | 4 | 2,104 / 3,500 | 60.1% | 100% | 2% | 25 |
| `ck_house_terrace_pair` | building | 4 | 2,922 / 3,500 | 83.5% | 100% | 2% | 25 |
| `ck_midrise_brick_8` | building | 5 | 4,944 / 5,000 | 98.9% | 99% | 2% | 60 |
| `ck_midrise_corner_clock` | building | 5 | 4,848 / 5,000 | 97.0% | 100% | 10% | 60 |
| `ck_midrise_courtyard` | building | 5 | 4,888 / 5,000 | 97.8% | 100% | 1% | 46.4 |
| `ck_midrise_mixed` | building | 5 | 4,424 / 5,000 | 88.5% | 99% | 0% | 56 |
| `ck_midrise_render_10` | building | 5 | 4,808 / 5,000 | 96.2% | 100% | 0% | 60 |
| `ck_midrise_setback` | building | 5 | 4,944 / 5,000 | 98.9% | 100% | 1% | 58.8 |
| `ck_shop_bakery` | building | 4 | 2,164 / 3,500 | 61.8% | 99% | 1% | 25 |
| `ck_shop_bookshop` | building | 4 | 2,598 / 3,500 | 74.2% | 99% | 19% | 25 |
| `ck_shop_cafe` | building | 4 | 2,264 / 3,500 | 64.7% | 99% | 1% | 25 |
| `ck_shop_grocer` | building | 4 | 2,442 / 3,500 | 69.8% | 98% | 1% | 25 |
| `ck_shop_pharmacy_cross` | building | 4 | 2,452 / 3,500 | 70.1% | 98% | 1% | 25 |
| `ck_shop_pizzeria` | building | 4 | 2,756 / 3,500 | 78.7% | 99% | 3% | 25 |
| `ck_shop_row_arcade` | building | 5 | 4,920 / 5,000 | 98.4% | 99% | 2% | 45.8 |
| `ck_shop_row_corner` | building | 5 | 4,856 / 5,000 | 97.1% | 99% | 11% | 46.2 |
| `ck_shop_row_three` | building | 5 | 4,638 / 5,000 | 92.8% | 99% | 1% | 44 |
| `ck_tower_crown` | building | 5 | 3,326 / 5,000 | 66.5% | 100% | 0% | 60 |
| `ck_tower_slab` | building | 5 | 4,564 / 5,000 | 91.3% | 100% | 2% | 52 |
| `ck_tower_stepped` | building | 5 | 3,268 / 5,000 | 65.4% | 100% | 0% | 60 |
| `ck_tower_twin` | building | 5 | 3,660 / 5,000 | 73.2% | 100% | 0% | 60 |
| `ck_car_sports` | downtown | 4 | 2,780 / 3,500 | 79.4% | 58% | 28% | 14.7 |
| `ck_landmark_arch` | downtown | 5 | 4,700 / 5,000 | 94.0% | 100% | 13% | 50 |
| `ck_landmark_clock_tower` | downtown | 5 | 4,864 / 5,000 | 97.3% | 100% | 17% | 60 |
| `ck_landmark_obelisk` | downtown | 5 | 3,826 / 5,000 | 76.5% | 100% | 19% | 60 |
| `ck_limousine` | downtown | 4 | 2,596 / 3,500 | 74.2% | 100% | 15% | 25 |
| `ck_neon_sign` | downtown | 4 | 2,660 / 3,500 | 76.0% | 86% | 32% | 14.2 |
| `ck_scaffolding` | downtown | 4 | 2,212 / 3,500 | 63.2% | 96% | 33% | 22.7 |
| `ck_subway_entrance` | downtown | 4 | 2,344 / 3,500 | 67.0% | 99% | 6% | 23.2 |
| `ck_taxi` | downtown | 4 | 2,836 / 3,500 | 81.0% | 58% | 28% | 15.4 |
| `ck_tram` | downtown | 4 | 3,068 / 3,500 | 87.7% | 98% | 2% | 25 |
| `ck_water_tank` | downtown | 4 | 2,924 / 3,500 | 83.5% | 100% | 59% | 23.6 |
| `ck_bike_rack` | mainstreet | 2 | 696 / 700 | 99.4% | 93% | 38% | 3.9 |
| `ck_bistro_chair` | mainstreet | 2 | 384 / 700 | 54.9% | 100% | 82% | 2.7 |
| `ck_cafe_table_parasol` | mainstreet | 3 | 1,288 / 1,500 | 85.9% | 44% | 90% | 9.1 |
| `ck_cupcake` | mainstreet | 1 | 264 / 500 | 52.8% | 44% | 100% | 0.3 |
| `ck_flower_buckets` | mainstreet | 2 | 512 / 700 | 73.1% | 89% | 55% | 2.6 |
| `ck_food_truck` | mainstreet | 4 | 2,684 / 3,500 | 76.7% | 60% | 13% | 22.2 |
| `ck_fruit_crates` | mainstreet | 2 | 572 / 700 | 81.7% | 90% | 15% | 3.9 |
| `ck_grocery_bag` | mainstreet | 1 | 256 / 500 | 51.2% | 98% | 15% | 1.5 |
| `ck_phone_repair_kiosk` | mainstreet | 3 | 944 / 1,500 | 62.9% | 98% | 0% | 9.8 |
| `ck_post_box` | mainstreet | 2 | 500 / 700 | 71.4% | 25% | 92% | 3.9 |
| `ck_potted_shrub` | mainstreet | 2 | 404 / 700 | 57.7% | 100% | 43% | 2.8 |
| `ck_sandwich_board` | mainstreet | 2 | 304 / 700 | 43.4% | 100% | 4% | 3.4 |
| `ck_sunglasses` | mainstreet | 1 | 272 / 500 | 54.4% | 42% | 73% | 0.4 |
| `ck_meme_banana_scale` | meme | 5 | 4,000 / 5,000 | 80.0% | 64% | 43% | 32.9 |
| `ck_meme_buffering_billboard` | meme | 4 | 2,316 / 3,500 | 66.2% | 74% | 20% | 20.1 |
| `ck_meme_cone_statue` | meme | 4 | 2,588 / 3,500 | 73.9% | 98% | 16% | 21.7 |
| `ck_meme_phone_1pc` | meme | 4 | 2,160 / 3,500 | 61.7% | 97% | 4% | 15.3 |
| `ck_meme_pond_cart` | meme | 3 | 1,152 / 1,500 | 76.8% | 99% | 99% | 9.8 |
| `ck_meme_vacant_lot` | meme | 5 | 4,444 / 5,000 | 88.9% | 96% | 14% | 32.7 |
| `ck_meme_wet_floor_sign` | meme | 2 | 416 / 700 | 59.4% | 73% | 65% | 3.4 |
| `ck_bird_bath` | park | 2 | 400 / 700 | 57.1% | 100% | 100% | 2.6 |
| `ck_bush` | park | 2 | 608 / 700 | 86.9% | 100% | 100% | 3.9 |
| `ck_climbing_frame` | park | 3 | 808 / 1,500 | 53.9% | 47% | 0% | 8 |
| `ck_cooler` | park | 2 | 200 / 700 | 28.6% | 65% | 2% | 2 |
| `ck_flower_bed` | park | 2 | 588 / 700 | 84.0% | 91% | 30% | 3.9 |
| `ck_flying_disc` | park | 1 | 232 / 500 | 46.4% | 13% | 100% | 0.9 |
| `ck_hedge_row` | park | 3 | 1,380 / 1,500 | 92.0% | 100% | 44% | 7.4 |
| `ck_leaf_pile` | park | 2 | 380 / 700 | 54.3% | 79% | 97% | 2.6 |
| `ck_path_curve` | park | 3 | 584 / 1,500 | 38.9% | 100% | 0% | 9.8 |
| `ck_path_straight` | park | 3 | 760 / 1,500 | 50.7% | 100% | 0% | 8.2 |
| `ck_picnic_basket` | park | 1 | 388 / 500 | 77.6% | 98% | 6% | 1.5 |
| `ck_picnic_blanket` | park | 2 | 144 / 700 | 20.6% | 45% | 0% | 3.9 |
| `ck_pond_edge` | park | 3 | 1,292 / 1,500 | 86.1% | 100% | 100% | 9.8 |
| `ck_sand_pail` | park | 1 | 308 / 500 | 61.6% | 25% | 96% | 1 |
| `ck_sandpit` | park | 3 | 92 / 1,500 | 6.1% | 99% | 0% | 5 |
| `ck_seesaw` | park | 2 | 276 / 700 | 39.4% | 65% | 0% | 3.8 |
| `ck_slide` | park | 3 | 1,063 / 1,500 | 70.9% | 62% | 19% | 9.8 |
| `ck_soccer_ball` | park | 1 | 224 / 500 | 44.8% | 100% | 100% | 0.7 |
| `ck_swing_set` | park | 3 | 932 / 1,500 | 62.1% | 93% | 51% | 9.8 |
| `ck_tree_birch` | park | 3 | 1,420 / 1,500 | 94.7% | 100% | 100% | 9.8 |
| `ck_tree_oak` | park | 4 | 2,552 / 3,500 | 72.9% | 100% | 92% | 16 |
| `ck_tree_pine` | park | 4 | 2,204 / 3,500 | 63.0% | 100% | 100% | 25 |
| `ck_billboard_404` | signage | 4 | 2,316 / 3,500 | 66.2% | 74% | 20% | 20.1 |
| `ck_billboard_arrow` | signage | 4 | 2,316 / 3,500 | 66.2% | 74% | 20% | 20.1 |
| `ck_billboard_chart` | signage | 4 | 2,316 / 3,500 | 66.2% | 74% | 20% | 20.1 |
| `ck_billboard_empty` | signage | 4 | 2,316 / 3,500 | 66.2% | 74% | 20% | 20.1 |
| `ck_billboard_loading` | signage | 4 | 2,316 / 3,500 | 66.2% | 74% | 20% | 20.1 |
| `ck_billboard_nested` | signage | 5 | 3,760 / 5,000 | 75.2% | 70% | 19% | 39.3 |
| `ck_billboard_testcard` | signage | 5 | 3,760 / 5,000 | 75.2% | 70% | 19% | 39.3 |
| `ck_bin_street` | street | 2 | 628 / 700 | 89.7% | 100% | 79% | 3.4 |
| `ck_bollard` | street | 1 | 236 / 500 | 47.2% | 100% | 100% | 1.5 |
| `ck_bus_stop_pole` | street | 2 | 464 / 700 | 66.3% | 78% | 36% | 3.9 |
| `ck_cardboard_boxes` | street | 2 | 180 / 700 | 25.7% | 100% | 0% | 2.1 |
| `ck_chip_bag` | street | 1 | 264 / 500 | 52.8% | 12% | 88% | 0.8 |
| `ck_crossing_zebra` | street | 3 | 644 / 1,500 | 42.9% | 100% | 0% | 9.8 |
| `ck_kerb_corner` | street | 3 | 1,144 / 1,500 | 76.3% | 99% | 0% | 9.8 |
| `ck_kick_scooter` | street | 2 | 388 / 700 | 55.4% | 49% | 48% | 2.5 |
| `ck_motorbike` | street | 3 | 1,448 / 1,500 | 96.5% | 92% | 66% | 6.9 |
| `ck_newspaper_bundle` | street | 1 | 124 / 500 | 24.8% | 100% | 0% | 1.4 |
| `ck_padlock` | street | 1 | 176 / 500 | 35.2% | 100% | 39% | 0.3 |
| `ck_parking_meter` | street | 3 | 1,256 / 1,500 | 83.7% | 100% | 52% | 5.1 |
| `ck_planter_box` | street | 2 | 640 / 700 | 91.4% | 100% | 21% | 3.9 |
| `ck_railing_section` | street | 3 | 584 / 1,500 | 38.9% | 100% | 72% | 7 |
| `ck_road_marking_arrow` | street | 2 | 116 / 700 | 16.6% | 100% | 0% | 3.9 |
| `ck_road_marking_dash` | street | 2 | 264 / 700 | 37.7% | 100% | 3% | 3.9 |
| `ck_scooter_dock` | street | 3 | 1,424 / 1,500 | 94.9% | 86% | 18% | 9.6 |
| `ck_street_lamp_double` | street | 3 | 942 / 1,500 | 62.8% | 100% | 93% | 9.6 |
| `ck_street_sign` | street | 2 | 608 / 700 | 86.9% | 54% | 30% | 3.9 |
| `ck_traffic_cone` | street | 2 | 232 / 700 | 33.1% | 54% | 67% | 2.3 |
| `ck_traffic_lights` | street | 4 | 3,200 / 3,500 | 91.4% | 80% | 28% | 18.1 |
| `ck_barbecue` | suburbs | 2 | 648 / 700 | 92.6% | 100% | 98% | 3.1 |
| `ck_car_estate` | suburbs | 4 | 2,584 / 3,500 | 73.8% | 58% | 25% | 15.5 |
| `ck_car_sedan` | suburbs | 4 | 2,568 / 3,500 | 73.4% | 57% | 29% | 15 |
| `ck_flower_pot` | suburbs | 1 | 336 / 500 | 67.2% | 94% | 100% | 1.2 |
| `ck_garden_fence` | suburbs | 3 | 1,100 / 1,500 | 73.3% | 100% | 1% | 7 |
| `ck_garden_gnome` | suburbs | 1 | 372 / 500 | 74.4% | 52% | 100% | 1.2 |
| `ck_garden_shed` | suburbs | 3 | 860 / 1,500 | 57.3% | 98% | 4% | 9.8 |
| `ck_kids_bike` | suburbs | 2 | 556 / 700 | 79.4% | 73% | 91% | 3.1 |
| `ck_lawn_mower` | suburbs | 2 | 656 / 700 | 93.7% | 56% | 61% | 3.9 |
| `ck_rain_barrel` | suburbs | 2 | 436 / 700 | 62.3% | 100% | 100% | 3 |
| `ck_recycling_box` | suburbs | 1 | 208 / 500 | 41.6% | 19% | 7% | 1.4 |
| `ck_skip` | suburbs | 3 | 1,008 / 1,500 | 67.2% | 57% | 28% | 9.8 |
| `ck_toolbox` | suburbs | 2 | 152 / 700 | 21.7% | 7% | 4% | 1.6 |
| `ck_trampoline` | suburbs | 3 | 1,400 / 1,500 | 93.3% | 70% | 96% | 9.8 |
| `ck_watering_can` | suburbs | 1 | 216 / 500 | 43.2% | 2% | 100% | 1.3 |
