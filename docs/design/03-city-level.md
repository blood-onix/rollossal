# Default level: Downtown

The first city level. It uses the same envelope as the current world data, so `Layout`, `WorldSpawner` and the culler need no changes: a 600 × 600 stud play area (`halfExtent` 300) inside an 800 × 800 outer bound, 12 spawn points, and the hub off to the west.

## The idea: grow from the doorstep to the skyline

Every spawn is a shop doorstep at the edge of the map. Every spawn can see the **Ferris Wheel** and **The Glass Tower**: you see the goal from second one. The city is laid out in rings that match the tiers, so the route out of your doorstep *is* the growth curve.

| Ring | District | Tiers | What you do there |
| --- | --- | --- | --- |
| 1 | **Stoops and Alleys** (12 spawn pockets) | 1 | 40 Pocket objects within 10 studs of each spawn. First pickup inside 5 s, first banner by about 30 s. |
| 2 | **Sidewalks** along Market Street and the side streets | 2 | Cones, bins, scooters, hydrants in clusters at every corner. |
| 3 | **The Park** (west), **The Construction Site** (north-east), **The Car Park** (south-east) | 3 | Three play spaces, each with its own toy: lawns and pond, ramps and scaffolding, a spiral ramp. |
| 4 | **Market Street** roadway and **The Plaza** (centre) | 4 | Parked cars, buses at stops, food trucks, the fountain. |
| 5 | **The Skyline Block** (north) and **The Waterfront** (south) | 5 | Buildings, the crane, the Ferris Wheel, The Glass Tower. |

The CityMap preview shows the layout; switch themes to see it recolour.

## Growth pacing (4-minute run)

| Time | Target | Where |
| --- | --- | --- |
| 0:05 | First pickup | The doorstep |
| 0:30 | Tier 2 banner (ball 5) | End of your block's sidewalk |
| 1:30 | Tier 3 banner (ball 12) | Entering the park, site or car park |
| 2:45 | Tier 4 banner (ball 30), 1 star at 20 | Market Street, the Plaza |
| 4:00 | 2 stars at 45; 3 stars at 80 means tier 5 | The Skyline Block |

Tune zone counts until a bot run (AGENTS.md "Driving the ball") hits these times within ±20 s.

## Layout rules that make it interesting

- **Walls become food.** Each ring is fenced by something one tier up: bollards (tier 2) around the Plaza, hedges and the park fence (tier 3), parked vans (tier 4) lining Market Street. Yesterday's wall is today's snack, and the map opens as you grow.
- **Small-only shortcuts.** Alleys between buildings (4 studs wide) and a storm-drain tunnel under Market Street are quick routes for tier 1–2 balls. At diameter 5+ you simply stop fitting. Players feel their size.
- **Heroes on sightlines.** Every street ends on a hero: the Tube Guy at the Plaza's west entrance, the Rocket Water Tower at the north-east, the Donut Truck turning in the Plaza. Never hide a hero behind a building.
- **Something to climb.** The Car Park's spiral ramp has cars on every level and a view from the top deck; the Construction Site has scaffolding ramps and a container stack. Kerbs and stoops need the Jump button at tier 1, not later.
- **Cascades.** Piles that spill when hit: the Pizza Box Tower, the pallet stacks of fruit, the Vending Machine dropping cans. Knocked-off objects are re-collectable, so a hit is a little jackpot rather than a punishment.
- **One golden object a day.** Seeded hiding spots: a bus-shelter roof, the top of the car park, inside the drain tunnel, the crane's counterweight, behind the Ferris Wheel.
- **Dense, then sparse.** Tier 1 is packed tight at spawns. Tier 4–5 objects stand alone with room to roll at them: big things need a run-up.

## Zones and budgets

- About **1,400 placements** in total, so with 12 balls × 30 visible stuck objects the server stays under `Config.Budgets.maxActivePartsPerServer` (2,000). Ground, roads and buildings count as Parts too.
- Rough split by tier: 480 / 380 / 280 / 180 / 60 placements (tier 5 includes the buildings that make up the skyline).
- Zones use the existing seeded `Layout.expand` mixes; heroes and buildings are `fixedPlacements`.
- `cullTierDelta` 2: a tier-4 ball no longer renders tier-1–2 litter. The city empties as you outgrow it, which is both the feeling and the frame-rate win.
- Respawns (60–120 s, out of sight) refill the doorsteps for new joiners.

## Theme notes for Downtown

- `winter` (**Holiday City, the launch theme**): snow on every `w-season` face, the Mega Tree in the Plaza fountain, a Christmas market around it, the pond as an ice rink, a sledding slope in the park. Full plan in *Launch theme: Holiday City*.
- `neon`: `clockTime` 21, windows and signs lit, the Tube Guy and the Ferris Wheel get Neon trims. It is the strongest theme for 16+ thumbnails.
- `toon`: shadows off, high ambient, every role saturated. Best as an event weekend, not the default.
