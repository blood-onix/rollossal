# Park City map references

Every picture here is drawn from one data file, [`park-city-layout.json`](park-city-layout.json). The pictures, the
design document ([../09-park-city-level.md](../09-park-city-level.md)) and the grey box of feature 012 all read the same
coordinates, so they cannot drift apart.

- **Change the map** in `scripts/park_city_layout.py`, then run:
  ```bash
  python3 scripts/park_city_layout.py
  ```
  ```bash
  python3 scripts/park_city_render.py
  ```
- The layout script prints a summary (objects per tier, light and Part objects) and **fails loudly on overlaps**: a
  scene or a building on a road, a path, water, the maze or another scene. Keep it at 0.
- Growth numbers come from `scripts/growth-sim.py` (design doc section 5).

## How to read the maps

- **Coordinates**: x east, z south (down on the page), y up, origin at the Plaza. A grid square's size is printed under
  each title.
- **Dots** are objects at their real bulk, coloured by tier: T1 Crumb yellow, T2 Pocket orange, T3 Picnic red, T4 Street
  purple, T5 House blue, T6 Skyline black. Tinted rectangles are buildings and landmarks, labelled with the diameter that
  eats them (`D 40`).
- **Scenes** are thin outlines. The thick edge is the scene's front: small things spill to the front, towards the path,
  and the big thing that explains the scene stands at the back.
- **Dashed lines** are trails (food with a cause: a squirrel's acorn line, petals blown off the beds) and kerb lines
  (street furniture along a kerb).
- **Pink lines** are rails and ziplines (the arrow is the exit). **Orange pads** are boost pads (the line points the way
  they push). **Green circles** are bounce pads and lily pads, **blue circles** are spring pads, and **red rings** are
  catapult bullseyes. **Brown triangles** are catapults, with their aiming arc. **Gold dots** are golden-object spots.
  **Purple dashed lines** are hazards.

## The maps

| File | What it shows |
| --- | --- |
| [park-city.svg](park-city.svg) | The whole map: 1,000 × 1,000 studs, rings, zones, spawns, every object. |
| [zone-park-nw.svg](zone-park-nw.svg) | Park NW, **Woods and Campsite**: Mushroom Glade, Giant Oak, stream, campsite, catapult C1, spawns 1 – 3. |
| [zone-park-ne.svg](zone-park-ne.svg) | Park NE, **Pond and Boathouse**: the pond in the band between the park edge and the Park Loop, picnic lawn, catapult C2, spawns 4 – 6. |
| [zone-park-se.svg](zone-park-se.svg) | Park SE, **Playground, Skate Park and Courts**: Ferris wheel, catapult C3, spawns 7 – 9. |
| [zone-park-sw.svg](zone-park-sw.svg) | Park SW, **Gardens and Hedge Maze**: flower beds, allotments, sprinkler lawn, lawnmower loop, windmill, catapult C4, spawns 10 – 12. |
| [zone-ring-gate-n.svg](zone-ring-gate-n.svg) | Close-up of the north gate on the Ring Road: gate corner, ice-cream stop, bus stop, kerb line, boost pads. |
| [zone-nbh-ne.svg](zone-nbh-ne.svg) | **Market Street and the Roof Run** (plan). |
| [zone-nbh-ne-roofrun-side.svg](zone-nbh-ne-roofrun-side.svg) | **Roof Run side view**: roof heights, every gap width, the brave gap, the ramps. |
| [zone-nbh-se.svg](zone-nbh-se.svg) | **Car Park and Building Site**: three decks, the crane jib rail, the big slingshot S1. |
| [zone-nbh-sw.svg](zone-nbh-sw.svg) | **Terraces and Cottages**: two house rows with front gardens, washing-line rails, the removal van. |
| [zone-nbh-nw.svg](zone-nbh-nw.svg) | **Station and Rail Yard**: platforms, the parked train, four track rails, the Sky Rail ramp, slingshot S2. |
| [zone-downtown.svg](zone-downtown.svg) | **Downtown**: hoardings, Plaza, four tower blocks of four plots, the Sky Rail, spring pads. |
| [detail-doorstep.svg](detail-doorstep.svg) | Spawn 1's doorstep at 12 px per stud, with the real D 1 starting ball for scale. |
| [detail-glade-oak.svg](detail-glade-oak.svg) | Mushroom Glade, bounce caps, Giant Oak and its spiral ramp, root tunnels, the stream crossings. |
| [detail-duck-island.svg](detail-duck-island.svg) | Duck Island and its three routes (8 lily pads, the jetty and diving board, the drain pipe). |
| [detail-hedge-maze.svg](detail-hedge-maze.svg) | The maze on its 6-stud grid, with the Gnome King's room in the centre. |
| [detail-skate-playground.svg](detail-skate-playground.svg) | The playground (slide tower, roundabout, sandpit) and the skate park (bowl, quarter pipes, funbox, kicker, handrails, shelter-roof stash). |

## What the layout holds (from its summary)

| | Count |
| --- | --- |
| Tier 1 Crumb | 1,102 |
| Tier 2 Pocket | 989 (including the maze's 119 hedge pieces) |
| Tier 3 Picnic | 494 |
| Tier 4 Street | 166, plus 13 cars in traffic |
| Tier 5 House | 52 |
| Tier 6 Skyline | 8 |
| Light objects (Tiers 1 – 2, client-side data) | 2,091 |
| Part objects (Tiers 3 – 6) | 720 |
| Scenes, trails and kerb lines | 157 scenes, 44 lines |
| Overlaps | 0 |

These counts are the first pass. The growth model assumed about 130 Tier 5 – 6 objects, and the layout has 60, so the
top players' ceiling will be lower until feature 012's pace test tunes it (more towers, taller variants, or more
houses).
