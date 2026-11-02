# Research: Downtown "Inside Out" (008)

Phase 0 decisions. Every point where the spec leaves a design choice open, or where reading the code contradicts it,
is settled here. Numbers marked **provisional** are starting values; they live in data (`Downtown.luau`, `Config`)
and change without code edits. Coordinates: x east, z south, y up, origin at the centre of the Old Quarter square;
"north" is negative z. A point's ring is set by `m = max(|x|, |z|)`: Ring 1 `m ≤ 90`, Ring 2 `90–185`, Ring 3
`185–290`, Ring 4 `290–360`, Ring 5 `360–440`, horizon `440–560`.

## R-01: Invisible boundary colliders are a block kind

**Finding.** FR-001 removes the 40-stud perimeter wall (`dt_wall_n/s/e/w`) but balls must still stay on the map.
`WorldBuilder.buildGeometry` builds every `environment.blocks` entry as an opaque, queryable `SmoothPlastic` part and
has no way to make one invisible. `WorldSpawner.scatterSpots` already clamps to `halfExtent - 2`, so spawning is safe;
only rolling is open. `fallRespawnY = -50` catches a fall, not a roll along flat ground.

**Decision.** Add one value to `BlockDef.kind`: `"Boundary"`. `WorldBuilder` builds it as an anchored part with
`Transparency = 1`, `CanCollide = true`, `CanQuery = false`, `CanTouch = false`, `CastShadow = false`, and skips the
palette lookup (the data still carries a `swatch`, set to an existing role, so the type does not change). `Downtown`
lists four: inner faces at `±440`, thickness 8 (centres at `±444`), height 200. The north and south walls are 896
long and the east and west walls 880 long, so the corners close without overlap. Height 200 stops a D 150 ball
(clearance `0.5·D = 75`). The walls sit outside the playable edge, so no placement is touched.

**Rationale.** It is data (Principle VII): Lune can assert "four boundary blocks, inner face at `±halfExtent`, none
visible" and the "no perimeter wall taller than 8" test can exclude them by `kind`, which is what the spec means by
"no perimeter wall". `CanQuery = false` keeps the camera and `WorldCuller` ray checks from hitting an invisible wall.

**Alternatives.** (a) Derive four walls inside `WorldBuilder` from `halfExtent`: hides the rule from tests and adds
four parts to Snow Village. (b) Reuse `Block` with a transparent swatch: the builder sets `Transparency = 0`, so it
would need the same branch anyway. (c) Kill-floor outside the edge: balls would roll off visibly and drop.

## R-02: Placement cap is 1,500

**Finding.** `Downtown.maxPlacements` and `Config.Budgets.defaultMaxPlacements` are both 1,400 and `Pace.test` and
`Worlds.luau` read the Config value. FR-005 allows up to 1,550. Worst case is the base layout plus `winter`
overlays: 1,386 + 110 = 1,496.

**Decision.** Both values become **1,500**. `winter` overlays are capped at 110 and total `winter` placements at
1,500. `Config.test` line 105 changes from 1,400 to 1,500. `SnowVillage` keeps its own `maxPlacements = 1700`.

**Rationale.** The spec lets the cap rise to 1,550, but every extra placement is a part (R-03). A cap that matches
the real worst case catches growth.

**Alternatives.** 1,550 (spec ceiling): rejected, 50 spare placements are 50 fewer blocks.

## R-03: Part budget and block inventory

**Finding.** `Downtown.test` C14 sums `placements + blocks + built markers + 3 hub + 12 balls`, asserts it is
`≤ 2000 − 64`, and caps base blocks at 400. FR-005 tightens the ceiling to 1,850 with the 64 runtime parts counted.

**Arithmetic (winter, the heavier theme).**

| Term | Parts |
| --- | --- |
| Base placements | 1,386 |
| `winter` overlays (cap) | 110 |
| Blocks: base ≤ 215, `winter`-only ≤ 35 | 250 |
| Built markers (boosters, traps; golden spots build nothing) | 16 |
| Hub | 3 |
| Balls | 12 |
| Runtime trail and hazard parts | 64 |
| **Total** | **1,841** (≤ 1,850) |

`city` has no overlays and no theme blocks: 1,386 + 215 + 16 + 3 + 12 + 64 = 1,696 at the ceiling (1,694 with the
planned 213 base blocks).

**Decision.** C14 changes to: base `environment.blocks ≤ 215`, `winter` total blocks ≤ 250, and the sum
`placements + blocks + markers + 3 + 12 + 64 ≤ 1,850` in both themes. The block inventory per ring is in
`data-model.md` §5 and totals 213 base blocks. Long continuous plinths and one slab per yard are how the count stays
low: a city block face is one plinth, not one per building.

**Alternatives.** Keep 400 blocks and drop overlays to 0: rejected, `winter` would lose its identity (FR-009 needs
the garlands and the slope as blocks; overlays are the theme's dressing).

## R-04: Spawns sit at lane mouths, three per quadrant

**Decision.** Twelve spawns, three per quarter, on the 8-stud lanes and never on a 30-stud main street (spec FR-002,
deviation D5). Each quarter is the block `[15, 90]²` (mirrored four ways; the corner `[15, 30]²` belongs to the square) with a lane
on `x = 52.5` and a lane on `z = 52.5`, so it holds four 33.5 × 33.5 sub-blocks. Nominal spawns in the north-east
quarter are `(52.5, -35)`, `(52.5, -72)` and `(35, -52.5)`; the other quarters mirror them. The pairs are 25 to 37 studs apart, so the 10-stud clusters do not
overlap. The exact values are baked by a scratch search. Each spawn gets the 007 doorstep recipe: a `dt_z_door_NN_a`
zone of 32 core Tier 1 objects and a `_b` zone of 8 `slot.small`, so 40 within 10 studs. Each spawn stands next to
a plinth kerb of 1.2 (C18), which is the lane edge. Each quarter also holds 16 Tier 2 objects on its lanes
(64 in total), so a D 4 ball has food before the gate; with the 32 gate cones Ring 1 holds 96 Tier 2.

**Rationale.** Twelve separate clusters of 40 keep 12 simultaneous starters from sharing food (FR-008). Starting off
the main streets keeps the sightline corridors (R-09) free of players' first-second clutter. The 007 per-spawn
recipe is already a tested pattern in `Downtown.luau` (`WALK_IN`, `WALK_OUT`, crumbs).

**Alternatives.** Spawns on the main streets: rejected, 30 studs wide splits the 10-stud cluster and invites
collisions at the square. Clusters of 60: rejected, 12 × 60 = 720 breaks the Tier 1 band (423 to 517).

## R-05: The pace model is obstacle-aware (F7)

**Finding.** `Pace.test` models a greedy eater that rolls straight to the nearest absorbable object, ignoring
walls. In a city of plinths and buildings that makes the test pass while the route is blocked.

**Decision.** `Pace.simulate` gets two obstacle sets, built once per `(world, theme)`:

1. **Walls**: `environment.blocks` plus the theme's blocks, except `Boundary`, that overlap the ball's body for the
   current `D`: `bottom < D` **and** `top > clearance(D)`, with `clearance(D) = max(2.5, 0.5·D)`. A block that
   passes both tests is a wall the ball must go round or cannot cross. So a street garland (bottom ≥ 9) never blocks
   a D ≤ 9 ball, a shortcut roof (bottom 4.9) blocks D ≥ 5 balls from entering but not a D 2 to 4.4 ball, and a 1.2
   kerb never blocks anyone. Footprint is the axis-aligned rectangle of the block (yaw 0 or 90 only, which `Downtown`
   guarantees and a test asserts).
2. **Unabsorbable placements**: any placement with `size > 0.4·D` for the current `D`. Footprint is a `size × size`
   square (conservative).

The eater walks candidates nearest-first. A candidate is **reachable** if the straight segment crosses no obstacle,
or if going round the first blocking obstacle via the nearest corner (offset `D/2 + 0.5`) crosses none; its cost is
the longer path. A blocked candidate is skipped. Shortcut roofs and the Old Quarter edge wall (R-06) are walls like
any other, so a D 5 ball cannot cut through a 4.5-wide shortcut. A new `simulateTwelve` runs all 12 eaters in one
world with one shared `taken` set, stepping the earliest eater first, to assert FR-008 (first pickup ≤ 5 s, D ≥ 5 by
60 s for all 12).

**Rationale.** The model stays pure and deterministic (no clock, no random), uses the real `Absorb` ratio and
`Growth`, and is the same model the spec's windows are written for. A spatial hash (20-stud cells) keeps the
nearest-first search cheap with 1,500 placements.

**Alternatives.** Full A* on a grid: more faithful, but 880 × 880 at 2 studs is 193k cells per step per eater; too
slow for Lune and not needed to catch a wall that blocks the whole street. Ignore walls and add a "detour factor":
rejected, it is the F7 finding.

## R-06: Stage 1 slice, and the Old Quarter edge is sealed except at the gates

**Decision.** Stage 1 is built and measured before Stage 2 starts. It contains: the Old Quarter (square, four
quarters, 16 sub-blocks, lanes), the 12 spawns, the south main street (+z) through its bollard gate, and the first
two Ring 2 blocks on each side of it. Everything else is the `asphalt` shell. Checks: the 12-eater Lune test on the
slice, `screen_capture` from overhead and from street level in `winter` and `city`, and a console read.

The Old Quarter edge (`m = 90`) is closed by the outer faces of the sub-blocks, the shop-front strips and eight
lane end walls (each lane dead-ends at `m = 90`, top 6), with exactly four gaps: the 30-stud main streets. Each gap
is filled by a row of 8 `traffic_cone` bollards (core Tier 2, size 2.0) with a 1.8-stud gap between them. A D 2 to
4.9 ball cannot pass the 1.8 gap or eat a cone (`0.4·4.9 = 1.96 < 2.0`); a D ≥ 5 ball eats its way through. The
4.5-stud shortcuts of Ring 2 never cross `m = 90`. A flood-fill test (N8) proves a D 2 ball cannot leave Ring 1 and a
D 5 ball can.

**Rationale.** The spec makes "Tier 2 bollards gate the main streets" the transition from Tier 1 to Tier 2; without
a sealed edge a D 2 ball would walk round the gate. The edge is static and 6 tall, so a D ≥ 12 ball rolls over it
(`clearance = 6`), and Rings 1 and 2 stay reachable late (FR-004).

**Alternatives.** Leave Ring 1 open: gates become decoration. Make the wall absorbable: more T4/T5 placements than
the budget has.

## R-07: Pace tuning, and the D 150 risk

**Finding.** `growthK = 1.95` gave D 30 at 145 to 185 s and D 80 by 240 s on the 007 layout. The new windows are
D 30 at 120 to 180 s, D 80 by 210 s and D ≥ 150 by 240 s. Volume to D 150 is `150³ = 3.4 M`; at `k` the eaten
`size³` must sum to `3.4 M / k`. The five heroes alone (glass tower 216 k, crane 166 k, ferris wheel 125 k,
landmark 91 k, apartment 64 k) are about 660 k.

**Decision.** The levers are, in order: (1) `growthK`; (2) Tier 3 to 5 counts inside their ±10 % bands (T3 up to
286, T4 up to 224, T5 up to 61), traded against `winter` overlays so the total stays ≤ 1,500; (3) placement
positions (put the Tier 4 and 5 food along the route a Tier 3 ball takes). The early windows (D 5 at 10 to 50 s, D
12 at 70 to 110 s) pin `k` from below and above, so `k` is solved from them and the late marks then come from the
counts. No rule file changes: `Absorb` and `Growth` stay as they are. The solving is a scratch search in the task
phase and the result is baked as literals with a comment, as 007 did.

**Risk.** D ≥ 150 at 240 s may not be reachable inside those levers with the pace model's pickup rates
(1.5 per second small, 1.0 large). A rough supply check: D 150 needs `150³ / k = 1.73 M` of eaten `size³` at
`k = 1.95`, and the nine Tier 5 sizes average about 82 k each (`size³`), so the supply is probably there; the
binding limit is more likely time and pickup rate. The task phase computes the real figure from the baked layout
before tuning. **Fallback**: record the best reachable D and the limiting term in `playtest.md`
and ask the owner once to relax that single mark (for example to D ≥ 130, which still eats the Ferris Wheel). The
tasks must not shrink the 99 meshes or change `absorbRatio`.

**Later change (2026-11-02).** The owner relaxed the lower bounds to D 12 at 62 s and D 30 at 105 s after the search
below the old bounds stalled; see `playtest.md` "Deviations". The windows above are the originals.

## R-08: Built coverage is measured on a grid

**Decision.** `Downtown.test` rasterises onto a 5-stud grid over `[-440, 440]²` (176 × 176 cells): every
`environment.blocks` and theme block with `top > 0.2` that is not a `Boundary` marks its rectangle; every Tier 4 and
5 placement marks a `size × size` square. Coverage is `marked / 30,976`; it must be `≥ 0.20` in `city` (no theme
blocks) and in `winter`. District ground slabs (Park lawn, Market paving, Construction yard, Rail Yard bed and the
Car Park footprint) sit at top 0.25 to 0.5 so they count as built ground; the asphalt base (top 0.0) and
the harbour water (top 0.05) do not. Static blocks counted for the "at least 50" rule are non-ground, non-`Boundary`
(deviation D4).

**Rationale.** A 5-stud grid is exact enough for a 20 % threshold, runs in milliseconds, and an empty field scores
0 %. A rough estimate from the `data-model.md` inventory (Ring 1 about 17 k studs², Ring 2 about 55 k, the five yard
slabs about 120 k out of the ring's 200 k, Boulevard and Skyline podiums about 40 k) is **25 to 30 %** against the
155 k needed. It is not measured yet; the yard slabs and Skyline podiums are the levers if the first run lands
under 20 %.

**Alternatives.** Exact polygon union: more code for no gain. Count blocks only: lets a map of 50 tiny blocks pass.

## R-09: Street widths and sightlines are measured on the same grid

**Decision.** The test holds a hand-written table of streets (id, ring, axis, centre line, from, to, minimum clear
width, tolerance), taken from the spec and `data-model.md` §3. It is not `Downtown` data: the layout is data, the
rule that checks it is test code (as C16 is today). A street edge is the face of a **plinth or wall**: any block
with `top ≥ 1.0` (the 1.0 to 1.5 plinths are what the buildings stand on, so the plinth face is the street the
player sees). For each street the test samples every 10 studs, rasterises those blocks at 1 stud, and measures the
free width across the street axis. Buildings stand inside their plinth, at most 4 studs from its face, so they never
narrow a street below its plinth-to-plinth width. Required widths: Ring 1 lanes `8 ± 1`; main streets `30 ± 1`;
Ring 2 `16 to 30`; Ring 3 approaches `≥ 30`; Ring 4 carriageways `≥ 24` each plus a median, 60 in total; Ring 5
avenues `≥ 40`.

**Sightlines (F7).** Four corridors along the main streets (30 wide, from `m = 30` to `185`) and twelve lane
corridors (8 wide, from each spawn to the main street its lane meets) replace the 007 per-spawn corridors to the
Ferris Wheel and Glass Tower. In each, no block with `top > 2.5` and no Tier 4 or 5 placement other than the
`slot.landmark` object may intersect it. A direct spawn-to-landmark line is **not** required (deviation D8): the
lanes are enclosed by design, and the landmark is seen from the lane's main-street end.

## R-10: Triangle audit and the scene ceiling

**Finding.** The spec asks for "the documented scene ceiling" but no document defines one; `Config.Budgets.meshTriangles
= {500, 700, 1500, 3500, 5000}` is per mesh. `art/export/manifest.json` holds 164 meshes (41/37/35/33/18 by tier).
Measured averages per mesh: T1 79, T2 117, T3 154, T4 232, T5 307 triangles. At the 008 split the unculled total is
about **187,000** triangles (1,889,200 is the per-mesh cap times counts, not a useful ceiling).

**Decision.** The ceiling is defined here and in `contracts/pace-and-tests.md`, and asserted by `Downtown.test`:
unculled `winter` total `≤ 250,000`; and as seen by a Tier 5 player (`cullTierDelta = 2` hides Tiers 1 to 3)
`≤ 100,000`. Each placement's cost is the manifest `triangles` of its resolved `assetKey`; an object with no manifest
row fails the test. Both numbers are about 1.3 × the measured value and are **provisional** until the RC reference
phone check.

**Alternatives.** Assert the per-mesh cap times counts: always passes. No ceiling: SC-001 asks for one.

## R-11: Camera and fog follow the larger map

**Finding.** `Rules.Movement.cameraDistance(D, 4, 8, max)` is `4·D` clamped to `[min, max]`. With `max = 80` it stops
growing at D 20. `Downtown.lighting` has `fogStart = 150`, `fogEnd = 900` (copied from Snow Village). With the camera
320 studs from a D 80 ball, fog would start before the ball.

**Decision.** `Config.cameraMaxDistance = 320` (so D 80 gets 320). The `Config.test` check
`cameraMin ≤ cameraMax` still holds. `Downtown.lighting.fogStart` and `fogEnd` become **500** and **1600**
(provisional, themed lighting is data), so the player's ball is clear at the maximum zoom and the horizon at 560 still
fades. `CameraController` is unchanged (it reads the Config value). The Snow Village fog is untouched.

**Alternatives.** Scale the camera by tier rather than diameter: a rule change for no gain (Principle XII).

## R-12: Shortcuts are one pattern: 4.5 wide, roofed at 4.8 to 5.0 (F5, F6)

**Finding.** 007 had inconsistent widths (4.0 to 4.6) and open tops, so a D 5 ball could jump in from above.

**Decision.** One recipe, repeated: two flanking wall blocks (top 5.2, so they exceed `clearance = 2.5` for D ≤ 5)
with a clear gap of **4.5** (tolerance ±0.1, asserted), and one roof block whose **bottom face is at y 4.9**
(`y = 4.9 + thickness/2`), covering the whole length. Each shortcut has a matching `keepOutAreas` entry
(`kind = "shortcut"`) sized to the corridor. The storm drain is the same recipe, longer. Where a shortcut meets the
street the mouth is flush (no step). Test: for every `shortcut` keep-out, find the two walls and the roof, check gap
`4.5 ± 0.1`, roof bottom `4.8 ≤ y ≤ 5.0`, roof covers the keep-out length. Studio: a sphere cast confirms D 4.4
passes and D 5.0 is blocked from the mouth and from above (🔒, in `playtest.md`).

**Rationale.** A D 4.4 ball is the largest Tier 1 ball; D ≥ 5 is Tier 2. The 4.5 gap stops a D ≥ 5 ball at the
mouth, and a roof bottom at 4.8 to 5.0 is below a D 5.0 ball's top when it drops in, so a ball that jumps onto the
wall and rolls sideways into the gap hits the roof instead of landing inside. A D 4.4 ball (top at 4.4) still fits
under it. That is the F5 case, a ball entering from above.

## R-13: Harbour water is a shallow floor, and yard ramps keep the 2.0 step

**Decision.** The Harbour basin (`w-water`) is a floor slab whose top is **−0.4**, with a 1.2 quay wall and a
**ramped lip** (a Wedge) at every 40 studs, so a ball that rolls in can roll out; it is not a pit. The boundary
collider stays at ±440, so open water to 560 is visible but not reachable. The Car Park, Construction Site and Rail
Yard ramps keep the 007 rule of ≤ 2.0 rise per step and ≤ 20° incline, and the sphere cast from 007 is re-run on the
new coordinates (deviation D6).

**Rationale.** A deep basin traps a D 80 ball that rolls over a 1.2 quay; a shallow floor cannot.

**Alternatives.** Deep water with a kill-floor: needs a new rule; water that is a decal on the asphalt: no quay
silhouette.

## R-14: Large objects are placed with fixed placements and sized zones

**Finding.** `Layout.expand` places a zone's count on a seeded grid whose cell edge is 1.2 × the largest size in the
mix, and errors when `count > capacity`. A 30-stud townhouse needs a 36-stud cell, so a zone that mixes small and
large objects wastes capacity.

**Decision.** Tier 4 and 5 buildings along streets (Old Quarter shops, Terraces houses, Skyline blocks, the heroes)
are **fixed placements** at baked coordinates, set by a scratch search from the manifest's mesh bounds and the
footprint rule `size × size` (R-09). Zones are used only for Tier 1 to 3 scatter and for Tier 4 vehicles on the
Boulevard (`size ≤ 25`, mix of one tier). No zone mixes Tier 3 with Tier 5. Each yard is its own zone group, so
`capacity ≥ count` is checked per zone (C7).

## R-15: Themes, markers, pigeons, hub and docs

**Decisions.**

1. **F2.** All holiday-only blocks (street garlands over the two Ring 1 main streets and the Ring 2 avenues, the Park
   sledding slope) are in `themeBindings.winter.blocks`. A test asserts no base block id contains `garland` or
   `slope` and that `city` builds none. Garlands are overhead (bottom y ≥ 9) so they never block a sightline.
2. **Overlays** (winter): up to 110, zones and fixed placements outside every keep-out (C10). Slots resolve to the
   same tiers as before; `slot.landmark` is the centre of the Old Quarter square (`mega_tree` / `giant_duck`).
3. **Markers.** 9 to 16 built markers and 5 `GoldenSpot` markers, re-placed on the new geometry; every golden spot
   stands on a static block (D2 of 007 still holds). `Markers.validate` bounds follow `halfExtent = 440` with no code
   change. At least one booster and one trap sub-kind per ring group (Old Quarter, Terraces, Yards, Boulevard,
   Skyline/Harbour) so the hazards teach the same way at every scale.
4. **Pigeons.** The five districts become Old Quarter, Terraces, Park, Market, Harbour; at most 8 each, on ground or
   a static plinth, none in a marker keep-out (C17 unchanged in shape).
5. **Hub.** `hub.center = { x = -620, z = 0 }`, `halfExtent = 24`: its nearest edge (−596) is 36 outside
   `outerHalfExtent = 560`. Studio-side hub parts are built from this data and need no code change.
6. **Docs.** `docs/design/03-city-level.md` is rewritten to Concept A. `docs/release-candidate.md` gets the owner
   items of FR-014 and the "numbers come from the placeholder map" note is removed once the Gate 2 run is recorded.
7. **Tests that pin old values.** `Downtown.test` lines 138, 139, 140, 733, 926 and C14; `Config.test` line 105;
   `Pace.test` windows and marks. `SnowVillage.test` is unchanged because Snow Village keeps 300 / 400 / −460.
