# Default level: Downtown "Inside Out"

The first city level, redesigned in feature 008 as Concept A. The playable square is **880 × 880 studs** (`halfExtent`
440) inside a 1,120 × 1,120 outer bound (`outerHalfExtent` 560), with 12 spawn points and the hub off to the west at
x = -620. `Layout`, `WorldSpawner` and the culler read those numbers and need no change; the world is one data module,
`src/shared/Content/Worlds/Downtown.luau`.

## The idea: start in the middle, eat your way outwards

The city grows **inside out**. Every ball starts in a tight Old Quarter at the centre, where the lanes are 8 studs wide
and the food is the size of a coin. Each ring is a tier up and a street wider, so the route out of the middle *is* the
growth curve. The edge of the map is open: a 200-tall invisible wall at the playable edge keeps balls in, and the
horizon beyond it (towers to the north and east, water to the south and west) is scenery.

Coordinates: x east, z south, y up. `m = max(|x|, |z|)` is the ring measure.

| Ring | Name | `m` | Streets | What you do there |
| --- | --- | --- | --- | --- |
| 1 | **Old Quarter** | to 90 | 8-stud lanes, four 30-stud main streets, a plaza | 12 spawns on the lanes, 40 Tier 1 objects within 10 studs of each. A bollard gate (eight cones) closes every main street. The landmark stands on a pedestal in the plaza. |
| 2 | **Terraces** | 90 to 185 | two 16-stud loops, 16-stud radials | House rows on 1.2-tall plinths, four roofed 4.5-stud shortcuts and a storm drain, Tier 2 clutter on the loop. |
| 3 | **Yards** | 185 to 290 | the main streets, 30 wide | Park (north-west), Market (north-east), Construction Site (west), Car Park (south), Rail Yard (south-east). Tier 3 scatter, ramps, a container platform, three car-park decks. |
| 4 | **Boulevard** | 295 to 355 | 60 wide: two 26-stud carriageways and an 8-stud median | Vehicles (Tier 4), shelters and billboards on the median. |
| 5 | **Skyline and Harbour** | 360 to 440 | 40-stud avenues | Towers on podiums (north, east); quays, containers and a shallow basin (south, west). The crane, Ferris Wheel, Glass Tower and Rocket Water Tower stand here. |

## Growth pacing (4-minute run)

| Mark | Window | Where |
| --- | --- | --- |
| First pickup | within 5 s | the doorstep |
| D 5 | 10 to 50 s | the end of your lane |
| D 12 | 62 to 110 s | the Terraces |
| D 30 | 105 to 180 s | the Yards |
| D 80 | by 210 s | the Boulevard |
| D 150 | by 240 s | the Skyline: every Tier 5 landmark can be swallowed |

`tests/unit/Pace.test.luau` checks these for all 12 spawns in `winter` and `city` with an obstacle-aware greedy eater
(walls and unabsorbable buildings add detours) and, separately, with all 12 starters sharing the food (first pickup
≤ 5 s, D 5 by 60 s). The levers are `growthK` and the zone counts in the `TUNE` table of the world module.

## Layout rules that make it interesting

- **Walls become food.** The Old Quarter's edge wall (top 6) and its four bollard gates hold a D 2 ball in; a D 5 ball
  eats through the cones and a D 12 ball rolls over the wall. Hoardings (top 4) and fences (top 3) in the Yards do the
  same for the next tiers.
- **Small-only shortcuts.** Four alleys through the Terraces and a storm drain are 4.5 studs wide between 5.2-tall
  walls, roofed with the roof's underside at y 4.9, so a D 5 ball can neither enter nor drop in from above.
- **Something to climb.** The Car Park has three decks and four ramps, the Construction Site a container platform on
  four ramps; every ramp rises at most 2 studs per step and at most 20°. The Harbour has ramped lips so a ball can roll
  back out of the basin.
- **Heroes on the streets.** Never hide a hero behind a building: the four main-street corridors and the twelve lane
  corridors are kept clear of blocks above 2.5 studs and of Tier 4 and 5 buildings.
- **One golden object a day.** Five seeded spots: a Terraces plinth, the Park pedestal, the Car Park top deck, a
  Boulevard median and a Skyline podium.
- **Dense, then sparse.** Tier 1 is packed at the spawns (12 × 40 = 480 objects); Tier 4 and 5 stand alone with room
  to roll at them.

## Zones and budgets

- About **1,390 base placements**: Tier 1 to 5 within ±10 % of 470 / 386 / 260 / 204 / 56. The `winter` overlays add 72
  (Tier 2 to 4, one ice rink); the cap is `maxPlacements` 1,500.
- At most 215 base blocks and 250 in `winter`. Active parts stay at or under 1,850 (placements + blocks + built markers
  + 3 hub + 12 balls + 64 runtime parts), under the 2,000 budget, in both themes.
- Built coverage (blocks above 0.2 and Tier 4 and 5 footprints) is at least 20 % of the square; at least 50 static
  blocks; nothing near the edge is taller than 8 studs.
- Triangle ceilings from `art/export/manifest.json`: the whole `winter` scene at most 250,000, and what a Tier 5 player
  sees (`cullTierDelta` 2) at most 100,000.
- `cullTierDelta` 2: a Tier 4 ball no longer renders Tier 1 to 2 litter. The city empties as you outgrow it, which is
  both the feeling and the frame-rate win.
- The camera pulls back to 320 studs at D 80 (`Config.cameraMaxDistance`); the fog is 500 to 1600.

## Theme notes for Downtown

- `winter` (**Holiday City, the launch theme**): snow on every `w-season` face, the Mega Tree on the plaza pedestal,
  24 garlands over the Old Quarter and Terraces main streets (overhead, bottom at y 9 or higher), a sledding slope and
  ramp in the Park, the pond as an ice rink, a cocoa and market-stall run in the Market. These are `themeBindings`, so
  `city` builds none of them.
- `city`: the Giant Duck on the pedestal, no overlays, no theme blocks, summer swatches.
- `neon` and `toon` remain design ideas; neither is built.

## Stage 1 and Stage 2

Stage 1 (the Old Quarter, one main street and the first Terraces block) is built and checked first, in both themes,
before the other rings. Studio captures and sphere casts are recorded in
`specs/008-downtown-inside-out/playtest.md`. Owner taste sign-off is on the release-candidate list.
