# Bake-off: five props, up to four sources

Feature 009, US3. Date: 2026-11-02. Nothing here is added to `art/export/` or `manifest.json` (plan D3).

## 1. Method

- **Stage**: one Blender scene (`art/scripts/bakeoff_props.py`, `build_stage`): dark road with a yellow centre line, pale
  raised sidewalk, kerb, warm sun with the `city` direction and strength used by the capture renders, sky from the
  `city` palette, EEVEE, Standard view transform. The same stage and lighting for every candidate.
- **Cameras** (FOV 70, 960×540): `3q`, a three-quarter view at 1.9 × the longest side; and `game`, the in-game camera
  distance for the ball that can just eat the prop (`size ÷ 0.4`, then `min(320, max(8, 4·D))`), so thin detail is judged
  at the scale a player sees.
- **Sizes** (longest side, studs, from `Downtown.luau`): hatchback 14, shop_front 22, bench 7, street_tree 9,
  fire_hydrant 2.4. Tiers: 4, 5, 3, 3, 2. Floors and targets are the style bible section 4 proposals.
- **Atlas**: every face's UVs sit in the centre of one `city` atlas cell (`art/palette.json`), one material, no PBR or
  transparency.
- Scores are the agent's, 1 to 5, a note for the owner and not a gate.

## 2. Sources

1. **Source 1, upgraded in-house Blender pipeline: done.** Rebuilt with boxes, convex hulls, cylinders and ico-spheres,
   a 1-segment bevel on main silhouettes only, unbevelled small details. Script: `art/scripts/bakeoff_props.py`
   (`build_and_render`); the stats are in `renders/source1.json`.
2. **Source 2, CC0 pack (Kenney or Quaternius): not run (owner declined, 2026-11-02).** Nothing was downloaded and no
   licence record exists. The licence section below says what to capture if the owner reopens it.
3. **Source 3, `generate_3d` hero: not run (generators off).** `get_addon_status` on 2026-11-02: tripo, hunyuan3d, hyper3d
   and meshy all `off`, libraries polyhaven, sketchfab and polypizza `off`, no premium generators. It cannot run, and
   credit spend would need approval anyway.
4. **Source 4, Creator Store: searched, inspection declined by the owner (2026-11-02).** Read-only `search_asset` (scope
   `creator_store`, free only) was run for each prop. Hits are listed in section 5. No model was inserted into the place,
   so scripts, triangle counts and licence terms are not verified, and none is a candidate.

## 3. Matrix

Triangles are measured on the exported mesh (after triangulation). "Today" is the committed `dt_*` mesh.

| Prop | Tier | Budget | Floor / target | Today | Source 1 triangles | Look | Atlas fit | Effort (agent) | Licence | Cost | Source 2 | Source 3 | Source 4 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| hatchback | 4 | 3,500 | 1,050 / 1,925 | 216 | **1,420** (in band) | 3 | 5 | about 15 min | own | 0 | not run (owner declined) | not run (generators off) | searched, inspection declined |
| shop_front | 5 | 5,000 | 1,500 / 2,750 | 200 (`dt_corner_bakery`), 432 (`dt_corner_shop_row`) | **2,032** (in band) | 4 | 5 | about 15 min | own | 0 | not run (owner declined) | not run (generators off) | searched, inspection declined |
| bench | 3 | 1,500 | 450 / 825 | 48 | **564** (in band) | 3 | 5 | about 5 min | own | 0 | not run (owner declined) | not run (generators off) | searched, inspection declined |
| street_tree | 3 | 1,500 | 450 / 825 | 88 | **456** (in band, just above floor) | 3 | 5 | about 5 min | own | 0 | not run (owner declined) | not run (generators off) | searched, inspection declined |
| fire_hydrant | 2 | 700 | 210 / 385 | 176 | **364** (in band) | 3 | 5 | about 5 min | own | 0 | not run (owner declined) | not run (generators off) | searched, inspection declined |

(`dt_bench`, `dt_street_tree` and `dt_fire_hydrant` counts in the plan, 48 / 88 / 176, are the figures used above; the
manifest's older `bench` entry is a different mesh.)

## 4. Renders

All under `renders/`, prefix `source1_`:

| Prop | Three-quarter | Game distance |
| --- | --- | --- |
| hatchback | [3q](renders/source1_hatchback_3q.png) | [game](renders/source1_hatchback_game.png) (140 studs) |
| shop_front | [3q](renders/source1_shop_front_3q.png) | [game](renders/source1_shop_front_game.png) (220 studs) |
| bench | [3q](renders/source1_bench_3q.png) | [game](renders/source1_bench_game.png) (70 studs) |
| street_tree | [3q](renders/source1_street_tree_3q.png) | [game](renders/source1_street_tree_game.png) (90 studs) |
| fire_hydrant | [3q](renders/source1_fire_hydrant_3q.png) | [game](renders/source1_fire_hydrant_game.png) (24 studs) |

## 5. Licences and inspection

- **Source 1**: own work, no external licence.
- **Source 2**: none recorded (not run). If the owner reopens it, record per pack: name, URL, licence page text (CC0 1.0),
  download date, creator, and the credit line even though CC0 needs none.
- **Source 4 search hits** (2026-11-02, Creator Store, free; scripts and triangles **not** verified, so none is usable):

| Prop | Hit (asset id, creator) |
| --- | --- |
| hatchback | Seat Ibiza fumarento (9475963675, ComboioSuprimido); Electric Car By Daycey Motors V1, V2, V4, V5 (18243653569, 18255419483, 18378192913, 18376561667, DrexTobu; description credits another creator, so provenance is unclear) |
| shop_front | Store Kuokiez Retail Shop Convenience Supermarket (99485598744700, Gracshad9015; "104 parts, 9 lights, about 65 x 38 x 74 studs. No scripts" per its own description, far over the part budget); House 1 and 2 (81318270, 81318303); Market (8893476619) |
| bench | Park Bench (393609716, AeliteOfficial); Park Bench (6700841242, ForestFossils); The Generic Park Bench with Seats (741384218); Park Bench (with seats) (14874085291) |
| street_tree | five "Low poly Street Lantern … Tree" models (e.g. 96038968250920, BellaCraft3066): keyword-stuffed titles, no description |
| fire_hydrant | Fire Hydrant (398237268, UntamedCow); (10202368997, N00BLANCE); (16650935345, I_have23Crayons); (9095886159, InuB30) |

Inspection attempt (2026-11-02, round 1): `InsertService:LoadAsset` through `execute_luau` (Edit, nothing parented into
the place) on 11 of these ids all failed with "User is not authorized to access Asset", so scripts, triangles and licence
terms stay unverified. The remaining route is `insert_asset`, which puts untrusted third-party models into the place; the
owner declined it on 2026-11-02 and it was not done.

The shop and tree hits are typical of the store: multi-part models (many `Part`s, not one mesh) and spam titles. They
do not meet the one-mesh, one-material, atlas rule without a rebuild.

## 6. Findings

- **Source 1** puts every prop inside its floor-to-target band while staying well under the tier budget (hatchback 41 %,
  shop front 41 %, bench 38 %, tree 30 %, hydrant 52 % of budget), which is 2 to 12 times today's counts. The cost is
  bevel discipline: first attempts with a bevel on every part landed at 724 (hydrant), 2,762 (hatchback), 3,632 (shop) and
  1,012 (bench) triangles, over the targets; bevelling only the main silhouettes and leaving small details flat is what
  fits the band. Cylinders and ico-spheres are the cheapest way to look round at 8 to 12 segments.
- At **game distance** the shop front, car and tree read from silhouette and colour block; the hydrant and bench are
  small and rely on their colour (red, wood) more than on added geometry, which supports per-class floors below the
  tier floor for the small props (hydrant 210 to 385 is already generous).
- Facade continuity (style bible section 5) cannot be judged on a single shop; it needs a row, which is a map feature.
- Source 2, 3 and 4 give no comparison, so no claim is made about them.

## 7. Sourcing rule

**Owner decision, 2026-11-02**: new world props are made in Blender with the in-house pipeline to the style bible's
per-tier floors and targets (Source 1). The owner declined the CC0 download and the Creator Store inspection, so this
rule rests on Source 1's counts and not on a side-by-side comparison. The owner can reopen the CC0 test after looking at
the renders; a CC0 mesh would still need the download and the constitution amendment approved. `generate_3d` and Creator
Store models are not used unless they have been run through this same comparison. Copied into
`docs/design/08-style-bible.md` section 11.

## 8. Upload hand-off

At most 5 props, none uploaded by the agent. Nothing is proposed for upload from this bake-off: the Source 1 meshes are
comparison builds kept in a scratch Blender scene, not in `art/source` or `art/export`. With Source 1 chosen, the
follow-up build feature adds them to `art/source`, exports them through `export_all.py` and hands the five FBX files
over.
