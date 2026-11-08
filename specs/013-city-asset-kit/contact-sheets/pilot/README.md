# Stage A pilot: tween-appeal rework (owner decision 2026-11-07)

Phase 9, T065–T075. Eight pilot assets rebuilt by `art/scripts/kit_rework.py`, the city and winter palettes and
atlases reworked (muted base, wear cells, snow cells), and late-afternoon lighting in `Themes.city` and
`Themes.winter`. **Owner approved the pilot on 2026-11-07 ("I like it").** A note that the sedan read a bit square led to a rounder,
lofted sedan; the owner rejected it ("looks awful"), so the approved sedan stays as it is. Stage B is next.

## Images (gate 6, held on owner approval)

| What | City | Winter |
|---|---|---|
| Contact sheet, three-quarter street level (play height, mid-grey) | `street-city.png` | `street-winter.png` |
| Contact sheet, top view | `top-city.png` | `top-winter.png` |
| Main-street block, ball D1 | `scene-mainstreet-city-d1.png` | `scene-mainstreet-winter-d1.png` |
| Main-street block, ball D5 | `scene-mainstreet-city-d5.png` | `scene-mainstreet-winter-d5.png` |
| Suburb corner, ball D1 | `scene-suburb-city-d1.png` | `scene-suburb-winter-d1.png` |
| Suburb corner, ball D5 | `scene-suburb-city-d5.png` | `scene-suburb-winter-d5.png` |
| Before / after (top: old kit, old atlas, noon light; bottom: pilot) | `before-after-city.png` | `before-after-winter.png` |

The `_before_*.png` files are the "before" tiles, rendered once before the rework. All images are EEVEE renders of the
exported meshes with the theme atlas and the theme's sun and ambient (`art/scripts/street_shots.py`,
`art/scripts/pilot_shots.py`); they are not Studio captures, so the owner's play check in Studio still stands.

## Per-asset report (`report.json`)

Triangles as a share of the tier ceiling (`Config.Budgets.meshTriangles`); muted share = visible area on muted
(`w-*` base) cells vs accent cells; snow share = area on `w-snowcap` / `w-icicle` / `fx_snowcap`.

| Asset | Tier | Triangles | % of ceiling | Muted | Snow | Size (studs, x × y × z) | Real-size source (research R-18) |
|---|---|---|---|---|---|---|---|
| ck_house_gable_fence | 4 | 3,234 / 3,500 | 92.4 % | 100 % | 5 % | 19.6 × 21.3 × 24.5 | two storeys at 2.9 m + roof (was 16) |
| ck_shop_row_three | 5 | 4,638 / 5,000 | 92.8 % | 99 % | 4 % | 44.0 × 24.7 × 42.1 | three 4.5 m shop bays (was 28) |
| ck_tower_slab | 5 | 4,564 / 5,000 | 91.3 % | 100 % | 3 % | 23.7 × 19.0 × 52.0 | kept; storey 13–14 st (see open question) |
| ck_street_lamp_double | 3 | 942 / 1,500 | 62.8 % | 100 % | 3 % | 5.1 × 1.4 × 9.6 | 3 m heritage lamp |
| ck_bin_street | 2 | 628 / 700 | 89.7 % | 100 % | 6 % | 1.8 × 1.8 × 3.4 | 1.05 m litter bin (was 2.2) |
| ck_car_sedan | 4 | 2,568 / 3,500 | 73.4 % | 57 % (accent prop) | 4 % | 15.0 × 6.5 × 5.7 | 4.7 m sedan, scale anchor |
| ck_tree_oak | 4 | 2,552 / 3,500 | 72.9 % | 100 % | 0 % | 12.3 × 11.2 × 16.0 | 5 m street tree |
| dt_fire_hydrant | 2 | 220 / 700 | 31.4 % | 10 % (accent prop) | 0 % | 1.6 × 1.4 × 2.4 | 0.75 m hydrant |

All three buildings are above 60 % of their tier ceiling and above 70 % muted. The 70 % rule is for buildings; the car
and the hydrant are accent props by design.

## Notes for the owner

- **Hydrant is lean on purpose.** Winter Downtown places it 34 times and the N10 scene ceiling (550,000 unculled
  triangles, `tests/unit/Downtown.test.luau`) leaves room for about 220 triangles each. A 640-triangle hydrant pushed
  the scene to 564,198. Stage B has the same limit for every `dt_*` mesh placed many times.
- **Car roof snow cap** is shared geometry: in city it reads as a grey roof panel.
- **Winter sun elevation** in Blender ignores latitude; in Studio `GeographicLatitude` 52 gives a lower sun than
  the renders show.
- Open owner questions are listed in `docs/release-candidate.md` (tower floor count, tier moves for bollard, post box,
  parking meter and road lamp).
