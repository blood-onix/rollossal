# Research: Dress Park City with the City Asset Kit and Themes

Decisions for `plan.md`. Each has Decision, Rationale, Alternatives. No NEEDS CLARIFICATION remains; the open points are
the defaults D1 to D6 in `plan.md`, which the owner can overrule without changing the structure.

## Measured starting point (2026-11-08)

Counted from the files on this branch, not from the spec's prose:

| Fact | Value |
| --- | --- |
| Object kinds in `park-city-layout.json` / `ParkCity.luau` | 219 (tiers 1–6: 66 / 59 / 43 / 28 / 18 / 5) |
| Placements | 4,614 (1,139 Parts for Tier 3–6, 3,475 light for Tier 1–2) |
| Kinds with an id match in `Assets.meshes` | 53 (15 `ck_`, 32 `dt_`, 15 plain keys; 9 are in two groups) |
| Kinds with no exact mesh | 166 (tiers 1–6: 56 / 44 / 29 / 20 / 13 / 4) |
| Kit objects that are also Park City kinds | 15 (the spec says 16; the 16th does not exist in the layout) |
| `Assets.meshes` keys | 291, none empty; manifest has 285 meshes |
| Generated object fields | id, tier, size, coins, bookId, nameKey, icon, fallback `"Block"`, dims, bulk, solid. No `assetKey`, `role`, `atlas`, `shade` |
| Theme fields on Park City | none (`activeThemeId` nil, so `Worlds.activeTheme` is nil and `ObjectVisual.textureId` returns `""`) |
| Park City `zones` | empty; all 1,139 Parts are `fixedPlacements` (cap is 1,500, so no `maxPlacements` override) |
| Rough triangle load, if every placement used the mean manifest mesh of its tier | about 1.9 M all placed, about 0.67 M for Tier 4 and above |

The last row is an order-of-magnitude estimate (manifest tier is a mesh budget tier, not the layout tier). It is more
than twice Downtown's retired ceiling (550,000), so the budget in R-07 is the main risk of this feature.

## R-01: Where the visual mapping lives

**Decision**: a new stdlib-only script `scripts/park_city_dress.py` holds one table keyed by object kind: `assetKey`,
`atlas`, `role`, `fallback`, `stage`, `status`, `note`. `park_city_world.py` imports it and writes the fields into
`ParkCity.luau`; it also writes the coverage report (R-02). The dress table is a hand-edited input, like the layout
script's `OBJECTS`. The four generated modules are never edited.

**Rationale**: it is a visual map, not geometry. Keeping it out of the layout script means a dress-only change does not
re-render the maps and does not need the owner's SVG approval (FR-014 applies only to layout changes). The generator
already owns the object list, so one more input is the smallest change.

**Alternatives**: put the mapping in `park_city_layout.py` (every mesh swap would become a layout change and need map
approval); a JSON file beside the layout (a second data format to validate, and no place for comments); edit
`ParkCity.luau` (forbidden).

## R-02: Coverage buckets, fit rule and the report

**Decision**: every one of the 219 kinds has exactly one status.

| Status | Meaning | Resolves to |
| --- | --- | --- |
| `exact` | same id or same subject as an uploaded mesh | `assetKey` in `Assets.meshes` and in `manifest.json` |
| `substitute` | a mesh of matching role and silhouette | `assetKey`, plus a note and the scale factor |
| `standin` | no mesh; owner decides whether to build one | `role` (a `w-*` key in both themes) and `fallback` shape |

`park_city_world.py` fails (exit 1) when a kind has no entry, an `assetKey` is missing from `Assets.meshes` or the
manifest, a `role` is missing from either theme palette, or a substitute's scale factor (layout longest side over the
mesh's native longest side) is outside 0.6 to 1.6 where the source catalogue records the mesh's dims. It writes
`specs/014-park-city-art/coverage.md` and `coverage.json` (id, tier, placements, status, assetKey, scale, note), with
`--check` covering both. The report ends with an **owner build list**: stand-ins sorted by placements × tier, so the
owner picks which meshes Blender builds next. No mesh is authored in this feature.

**Rationale**: FR-001 and FR-002 need a complete, repeatable table and a test; a generated report cannot drift from the
world. Native dims exist for `ck_*` (`CityKit.objects[].dims`) and for Downtown meshes (their object defs); older Snow
Village meshes have none, so they are `exact` by name only and recorded as "fit unchecked".

**Alternatives**: a hand-written Markdown report (drifts); an automatic nearest-neighbour match (picks silhouettes by
dims only, which gets hedges and fences wrong). The first pass is chosen by the agent, then reviewed in the stage PR.

## R-03: Theme wiring in the generated world

**Decision**: the generator emits, in `ParkCity.luau`:

- `activeThemeId = "winter"` (a constant in the dress script), `supportedThemes = { "winter", "city" }`, and
  `themeBindings` for both.
- **Plaza landmark**: the layout's `theme_landmark` placement becomes a fixed placement of `slot.landmark`. City binds it
  to `giant_duck`; winter binds it to a theme-only `mega_tree` object in `binding.objects`, which copies `giant_duck`'s
  dims, bulk, tier and `needsD` and uses `assetKey = "dt_mega_tree"`. The second landmark `giant_duck` at (250, −430) is
  a plain placement and stays a duck in both themes. (A hero variant would turn both into trees.)
- **Memes**: `slot.meme.t3`, `.t4`, `.t5` fixed placements bound in both themes to the 013 meme objects of that tier
  (same mesh both themes; a theme swaps atlases, not meshes). Tier 2 (`meme_wet_floor_sign`) is a plain light kind,
  because Tier 1–2 objects live in `ParkCityLight` and carry no slot.
- `maxPlacements` is not set: 1,139 Parts plus slot placements is under the 1,500 default.

`ThemeResolve.resolve` rebuilds each fixed placement and drops `solid`. Nothing in `src` reads a placement's `solid`
(`LightField` reads the object def's), so this is harmless today; a Lune test asserts it stays unused.

**Rationale**: it reuses the contract Downtown and Snow Village already pass (`theme-content.md`), so no Rules change.
FR-006 holds because the only difference between themes is data in `themeBindings` and the `activeThemeId` constant.

**Alternatives**: a hero variant for the landmark (two ducks both change); a new slot id for the Plaza (needs a
`ThemeResolve` edit and test for one use); a `slot.meme` family on light objects (needs slot logic in `Light` data).

## R-04: Winter contrast

**Decision**: the generator emits block swatches as `w-*` roles instead of the grey-box colour names, through one map:
`road → w-asphalt`, `ground and lawn → w-grass`, `pavement → w-sidewalk`, `kerb → w-kerb`, `roof → w-snowcap`,
`building → w-wall-a`, `glass → w-glass`, and so on for the 27 block kinds. The grey-box `PALETTE` stays as the base
palette for any swatch not mapped. The theme palette overlays the world palette (`ThemeResolve`), so winter gives
(64, 68, 75) roads and (228, 233, 239) lawns, and city gives (59, 62, 68) and (104, 134, 74), from the same data.
A Lune test reads both theme palettes and checks that winter road against lawn, and road against roof, differ in
luminance by a stated minimum.

**Rationale**: `WorldBuilder.buildGeometry` already reads `palette[block.swatch]`, so no code change is needed, and
FR-005 becomes a test instead of a look.

**Alternatives**: per-block winter overrides in `themeBindings.blocks` (those add blocks; they do not recolour);
snow as overlay Parts (about 90 more Parts for no gain).

## R-05: `LightField` draws through `ObjectVisual`

**Decision**: `LightField` keeps its grid query, cull, sort and `lightPoolCap`, and changes how a slot looks.

1. At start it builds one template per light kind with `ObjectVisual.build` (about 125 kinds), meshes first through
   `buildMesh` (which yields) off the draw path. Until a kind's template is ready, its slots use the stand-in.
2. A pool is per kind. Acquiring a kind pops a free slot of that kind or clones the template. The total of visible slots
   stays at or under `lightPoolCap`; when over, the farthest slots are released first (as today), and released slots park
   in a per-kind free list. The parked total is capped at `lightPoolCap` and extra slots are destroyed.
3. Slots keep the attributes `Size`, `Bulk`, `Longest`, `Tier`, `ObjectId`, `Taken` and the tag `LightObject`, and have no
   scripts. `CanCollide` follows `def.solid`.
4. A flag `Flags.LightMeshes` (default true) switches back to today's tier-coloured block, for frame-rate triage on a
   phone.

**Rationale**: FR-007. A per-kind pool avoids swapping a mesh's `MeshId` on a live part (mesh parts cannot change mesh
after creation) and keeps the work per refresh to clones and moves. 450 visible slots is unchanged.

**Alternatives**: one pool of generic parts with a `MeshPart` child swapped per kind (extra instance per slot, double
the draw objects); `SpecialMesh` on a Part (legacy path, no atlas); build per refresh (yields on the draw path).

## R-06: Fitting a mesh to the layout's dims

**Decision**: gameplay never changes. `ObjectVisual` scales a mesh uniformly so its longest side equals `def.size`, and the
layout's `dims` and `bulk` stay the numbers the rules read. The coverage report records the scale factor per kind and
flags anything outside 0.6 to 1.6 as a stand-in candidate. A kind whose proportions are wrong but whose scale is fine
is a note for the owner, not a failure.

**Rationale**: Tier, bulk and `needsD` come from the approved layout (013 left the tier moves as owner hand-offs); the
mesh must not move them. A taxi is tier 3 in the layout and tier 4 in the kit; the layout wins.

**Alternatives**: adopt the kit's dims per kind (changes tiers and the approved pace); non-uniform scale to the layout
dims (stretched textures on the atlas).

## R-07: Park City triangle budget

**Decision**: a Lune test `ParkCityBudget.test.luau` sums triangles from `art/export/manifest.json` over the real
placements: all of `ParkCityParts` plus the light window, using the manifest entry of each placed kind's resolved
`assetKey` (a stand-in counts as 12). The window is the `lightPoolCap` (450) nearest light objects within
`lightDrawRadius` (120), taken at fixed probe points (the 12 spawns, the Plaza, the Roof Run); the Part total is
reported twice, unculled and culled at a Tier 5 ball (`cullTierDelta` 2, so Tier 3 and below hidden). The ceilings are
two new keys in `Config.Budgets` (`parkCityTrianglesUnculled`, `parkCityTrianglesCulled`). The Downtown test and its
550,000 / 290,000 stay as they are (Downtown is not the active world).

The ceilings are set from the 12-ball benchmark, as 009 did: the highest step that held 30 fps on every unthrottled
second, times 0.8, floored to 10,000. Until then the test only reports.

**Rationale**: the rough estimate above says Park City starts far over Downtown's number. Setting the ceiling from the
spec's own rule (30 fps, measured) is what FR-012 asks. If the measured ceiling is below the dressed total, the levers
are, in order: map low-triangle meshes for the highest-count Tier 3 kinds, use stand-ins for the rest, move
`cullTierDelta`, and only then ask the owner. Each is a dress-table change, not a code change.

**Alternatives**: keep Downtown's ceiling (fails at once); a pure `Rules` module (one test user today; the function stays
in the test file like Downtown's and moves if the benchmark script needs it).

## R-08: Late-game clearance (no stuck moments)

**Decision**: two layers.

- **Lune** (`ParkCityClearance.test.luau`, from the layout): no solid block taller than 0.25 × D for the ball sizes
  35, 60 and 100 sits in a street gap narrower than D; the Spoke and Ring Road widths are at least 1.25 × the largest
  ball that is meant to use them; every `softObstacle` kind is listed; and no tier 4–6 kind is both `solid` and in a
  road block.
- **Studio** (agent-run, 🔒): with `Flags.DebugSize`, the ball is set to D 35, 60, 100 and driven along the Spokes, the
  Plaza and the Ring Road with the AGENTS.md client-side velocity driver. A stuck incident is speed under 2 studs/s for
  more than 3 s while the driver is pushing. The run records incidents per route; the target is zero.

**Rationale**: physics wedging cannot be proved from data, but clearance can be bounded from data and the rest sampled in
Studio. Hull collision for Tier 4 and above (`ObjectVisual`) is the existing rule and stays.

**Alternatives**: only a Studio drive (no regression guard); a full physics simulation in Lune (a second engine).

## R-09: Finale reachable

**Decision**: split it like the pace rule. A Lune **supply floor** fails the test: the summed growth available from
objects a ball can eat on the way (by `needsD`, through `Growth.growByBulk`) must reach D 100 with at least 15 % spare,
so the Glass Tower (`needsD` 95.9) is possible at all. The **pace** (when a skilled profile gets there, Tier 6 at about
163–238 s in 012) stays a report in `pace-report.md`. If the report shows the skilled profile cannot reach D 96 in 210 s,
the fix is a layout change (more Tier 4–5 near the core, or `growthK`), done in the layout script and approved on the
maps first.

**Rationale**: Principle I says pace is reported, never gated. FR-011 asks for "absorbable and reachable by a skilled
run", which the supply floor guarantees and the report shows. The spec's assumptions already allow the layout change.

**Alternatives**: gate on the skilled time (contradicts Principle I); do nothing (leaves FR-011 to the owner's play).

## R-10: Map edge between 500 and 620

**Decision**: the layout script gains an `edge` section that produces a ring of scenery in the 120-stud band: a ground
apron to `outerHalfExtent`, a tree line, a fence run, and a skyline backdrop of low-triangle building meshes. It is
scenery: `CanCollide` false, `CanQuery` false, not absorbable, anchored, placed beyond the invisible `Boundary` walls.
Budget: at most 120 server Parts and 40,000 triangles, counted in the budget test and the part budget. Mesh choices go
in the dress table (`dt_street_tree`, hedges, ck houses and midrise silhouettes at tier-1 triangle counts). Because
this changes the layout, the regenerated SVGs are shown to the owner before the stage continues.

**Rationale**: FR-009 asks that the edge reads as a place from the ground and mid-game cameras; the walls are invisible
and the band is empty now. Non-colliding scenery cannot cause a stuck moment and adds no gameplay rule.

**Alternatives**: client-only decoration (not in the layout, so not in the maps, and VII asks for one layout file); a
painted skybox (not mesh art, does not read as a perimeter from the ground).

## R-11: Staging

**Decision**: each kind has a `stage` in the dress table: the earliest stage whose area contains it (park ring and edge,
then Ring Road and neighbourhoods, then the core and Plaza). A kind not yet in its stage stays a recorded stand-in, so
every stage ends playable with a complete coverage report. Stage 1 also carries the shared work: the theme wiring, the
swatch map, the `LightField` change, the coverage generator and the budget measurement. A final stage sets ceilings,
runs the benchmark, the shots, Gate 2 and Gate 6. Any stage that changes the layout presents the rendered SVGs first.

**Rationale**: the shared work is needed for the park ring to show anything (Tier 1–2 food is all light objects), and
the stand-in default makes every intermediate build valid.

**Alternatives**: shared work as a stage 0 (not a build the owner can play); mapping per zone rather than per kind (a
kind used in two zones would have two meshes).

## R-12: Fixed shots for Gate 6

**Decision**: the 11 pinned Park City shots plus Roof Run, Giant Oak, a map-edge shot and a high overview, each in `city` and
`winter`. Taken in Studio with `screen_capture` at the camera positions in the pinned shot list. The theme is changed by
the dress table's one constant, then regenerate and sync with Rojo (no other edit). If a capture fails twice, the
Blender route (`art/scripts/park_capture_render.py` over the world data) is the fallback, as AGENTS.md describes.

**Rationale**: the shots must show the atlas-textured meshes; a grey-box render would not.

**Alternatives**: Blender only (no live lighting); the owner takes them (blocks the agent for no reason).
