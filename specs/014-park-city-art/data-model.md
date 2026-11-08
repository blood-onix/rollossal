# Data Model: Dress Park City with the City Asset Kit and Themes

All of it is data or test code. Nothing here touches player data (Principle VIII) or a remote.

## 1. Dress entry (new, hand-edited input: `scripts/park_city_dress.py`)

One per object kind, keyed by the layout's object id. 219 entries.

| Field | Type | Rule |
| --- | --- | --- |
| `status` | `exact` / `substitute` / `standin` | exactly one |
| `assetKey` | string or absent | required for `exact` and `substitute`; a key of `Assets.meshes` and an `id` in `manifest.json` |
| `atlas` | `"fronts"` or absent | `"fronts"` only for shop fronts and billboards (the 17 `CityKit` objects that use it) |
| `role` | string | a `w-*` key present in `Themes.winter.palette` and `Themes.city.palette`; required for every kind (it colours the stand-in and any mesh that falls back) |
| `fallback` | `Block` / `Ball` / `Cylinder` / `Wedge` | shape of the stand-in; `Block` by default |
| `shade` | number, optional | brightness step for stand-ins that share a role |
| `stage` | 1, 2 or 3 | the stage whose area first holds the kind; before that stage the kind is a stand-in |
| `note` | string | required for `substitute` and `standin`: what it is standing in for |

Derived by the generator and not stored in the table: `scale` (layout longest side divided by the mesh's native longest
side, when the catalogue records it), `placements` (count in the layout).

Validation (exit 1 from `park_city_world.py`): a kind with no entry; an entry for a kind not in the layout; `assetKey`
not in `Assets.meshes` or the manifest; `role` missing from either theme; `substitute` without a note; `scale` outside
0.6 to 1.6; `atlas = "fronts"` on a mesh not in `Assets.frontsAtlases`.

State: `stage` is the only value that moves during the feature. The generator writes the effective `status` for the
current build stage: a kind whose `stage` is later than `CURRENT_STAGE` (a constant in the dress script) is emitted as a
`standin`, so every stage ends playable and the report shows what is still to come.

## 2. Generated object fields (extended: `ParkCity.luau` objects)

Today: `id, tier, size, coins, bookId, nameKey, icon, fallback, dims, bulk, solid`.
Added: `assetKey?`, `role`, `atlas?`, `shade?`. `fallback` now comes from the dress entry. `icon`, `dims`, `bulk`, `tier`
and `size` are unchanged (R-06), so the Lune tests that match the world to the layout keep passing.

## 3. Park City theme binding (generated, new fields on `ParkCity.luau`)

```text
activeThemeId   = "winter"                       -- dress script constant
supportedThemes = { "winter", "city" }
themeBindings = {
  winter = { slots = winterSlots, objects = { mega_tree }, blocks? = none },
  city   = { slots = citySlots,   objects = {} },
}
winterSlots = { ["slot.landmark"] = "mega_tree", ["slot.meme.t3"] = "meme_pond_cart",
                ["slot.meme.t4"] = "meme_cone_statue", ["slot.meme.t5"] = "meme_banana_scale" }
citySlots   = { ["slot.landmark"] = "giant_duck",  ["slot.meme.t3"] = ... same as winter ... }
```

- `mega_tree` is a theme-only object copied from `giant_duck`'s dims, bulk, tier, `needsD`, with `assetKey = "dt_mega_tree"`
  and its own `nameKey` (a new generated string, English and Spanish).
- Slot placements: the layout's `theme_landmark` (fixed, id `p<n>` from the Parts order) and the meme placements.
  `ThemeResolve` requires each slot's object to have the slot's tier; `giant_duck` and `mega_tree` are both tier 5.
- A slot maps to exactly one object. `slot.meme.t4` binds to `meme_cone_statue`; the other two Tier 4 memes
  (`meme_phone_1pc`, `meme_buffering_billboard`) are plain fixed placements of their own kind. The memes are the same in
  both themes (a theme swaps atlases, not meshes), so the slot is there to meet FR-003 and the 013 contract, not to vary
  the object.
- Environment palette: block `swatch` values become `w-*` roles (section 4). The world's own `environment.palette` keeps
  the grey-box names as the base layer.

## 4. Block swatch map (generator constant)

| Layout block kind | `w-*` role (winter result) |
| --- | --- |
| `road`, `track` | `w-asphalt` (dark ploughed asphalt) |
| `grass`, `woods`, `island` | `w-grass` (snow) |
| `pavement`, `plaza` | `w-sidewalk` |
| `kerb`, `stone`, `wall`, `bowl`, `box` | `w-kerb` (`wall` has no swatch today and falls back to `stone`) |
| `roof` | `w-snowcap` |
| `building`, `tower` | `w-wall-a` |
| `glass` | `w-glass` |
| `gravel`, `sand` | `w-sand` |
| `ramp`, `spiral`, `deck`, `bridge`, `jetty`, `log_platform`, `tree_trunk`, `tunnel_wall`, `tunnel_roof` | `w-wood`, `w-bark` or `w-concrete` per block (listed in the dress script) |

A swatch name resolves to one role for both themes (the world palette is not per theme), so `roof → w-snowcap` is
snow white in winter and mid grey (163, 159, 151) in `city`. That is the plan's default D3.

Rule tested: for winter, luminance(`w-grass`) − luminance(`w-asphalt`) ≥ 90 on a 0–255 scale, and the same for
`w-snowcap` against `w-asphalt` and `w-road-slush` (FR-005). City keeps its own palette values from the same roles.

## 5. Coverage record (generated: `coverage.json`, `coverage.md`)

Per kind: `id`, `tier`, `placements`, `status`, `assetKey?`, `scale?`, `fitChecked`, `stage`, `note`.
Totals: kinds and placements per status and per tier. The report ends with the **owner build list**: stand-ins ordered by
`placements × (7 − tier)` so the owner sees which meshes buy the most. Not a gameplay table; read by the Lune resolve
test and by the owner.

## 6. Light slot (extended: `LightField` client state)

| Field | Meaning |
| --- | --- |
| `templates[kind]` | the `ObjectVisual.build` result for a light kind, built once; a MeshPart or a stand-in |
| `free[kind]` | list of parked slots of that kind |
| `active[id]` | slot currently showing the light id |
| `parkedTotal` | sum of `free` lengths; at most `lightPoolCap` |

Slot invariants (the ones the server and `BallController` rely on): attributes `Size`, `Bulk`, `Longest`, `Tier`,
`ObjectId`, `Taken`; tag `LightObject`; no scripts; anchored; `CanQuery` as today. Visible slots never exceed
`lightPoolCap` (450). A slot changes kind only by returning to its pool.

## 7. Triangle budget record

| Value | Source |
| --- | --- |
| `trianglesOf(assetKey)` | `manifest.json` meshes by `id`; a stand-in counts 12 |
| `partsTotal` | sum over every `ParkCityParts` row |
| `partsCulledAtTier5` | the same without rows whose tier ≤ 5 − `cullTierDelta` (3 and below) |
| `lightWindow(point)` | `Light.query` at a probe point, `lightDrawRadius`, nearest `lightPoolCap`, tier cull applied |
| `edgeTotal` | edge scenery rows (R-10) |
| Ceilings | `Config.Budgets.parkCityTrianglesUnculled`, `parkCityTrianglesCulled`; test fails above them |
| Probe points | 12 spawns, Plaza (0, 36), Roof Run centre, Glass Tower (120, −120) |

State: the ceilings start as `nil` and the test reports only; the final stage sets them from the benchmark (R-07).

## 8. Edge scenery (new layout section, generated)

`edge = { band = [500, 620], rows = [ { kind, x, y, z, yaw, scale } ], limits = { parts = 120, triangles = 40000 } }`
in `park-city-layout.json`, written by the layout script. In the world it becomes Parts with `CanCollide = false`,
`CanQuery = false`, no `WorldObject` tag, no `Size` attribute (so it is never absorbable, never culled by tier, never in
the server's object count for pace). Counted in the part budget.

## 9. Stage record

| Stage | Dress `stage` value | Layout change | Ends with |
| --- | --- | --- | --- |
| 1 | 1 | edge band (SVG approval first) | park ring and edge dressed, theme wiring, coverage report, `LightField` meshes |
| 2 | 2 | none expected | Ring Road and four neighbourhoods dressed |
| 3 | 3 | maybe the finale tuning (R-09) | Downtown core, Plaza, memes, finale |
| Final | n/a | none | ceilings, benchmark, shots, Gate 2, Gate 6 |
