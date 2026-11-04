# Level design: Park City

Status: **proposal, 2026-11-04.** A new level design written from scratch after feature 010 (Main-Street slice).
It replaces the Downtown "Inside Out" layout in [03-city-level.md](03-city-level.md) as the plan for the launch map
once the owner approves it. The object rules (absorb at `size ≤ 0.4 × D`, volume growth) and the art direction
([08-style-bible.md](08-style-bible.md)) are unchanged. Every number marked **(tune)** is a starting value for
playtests. Items the owner must decide are listed in section 13.

Map image: [maps/park-city.svg](maps/park-city.svg), drawn from `scripts/park-city-map.py` (run it after changing a
coordinate here, so the picture and the text agree).

![Park City map](maps/park-city.svg)

---

## 1. Why the last two maps did not work

Neither 008 (Inside Out) nor 010 (Main-Street slice) gave the player a reason to go anywhere. Both placed food by
zone fills and street rules, then hoped play would happen. The owner's verdict on 010 was that it failed as a map.
What went wrong, in game-design terms:

| Problem | In 008 / 010 | Rule in this design |
| --- | --- | --- |
| No destinations | Rings and streets of evenly spread food. Every direction looked the same. | Every 30 to 40 s of play leads to a **set piece** you can see from where you are (a pond island, a maze, a tree house, a roof route). |
| No challenge | Rolling was always flat and safe. Jumps, boosters and traps (006) had nowhere designed to be used. | Each set piece has a **skill route** (jump, rail, boost, timing) that pays more than walking around it. |
| Start felt like a box or a car park | 008 walled the start in; 010 opened it but put a street in front of it. | You start in a **park**, among small natural things, and the city is the horizon you grow into. |
| Small things read as litter | Bottle caps on asphalt are hard to see and dull. | Small food is **nature and play things** on grass: acorns, mushrooms, flowers, toys, picnic food. |
| No growth "moments" | Tiers changed numbers more than the world. | Tier changes **open places**: you eat the hedge maze walls, wade into the pond, eat the hoardings around Downtown, and finally the houses. |
| 12 players either starved or never met | Start pads were private; the end had no shared target. | **Spread out early, meet late.** Private doorsteps in the park, shared set pieces in the middle, one contested centre at the end. |

## 2. Design pillars for this map

1. **Always something just your size within 3 seconds.** On every main route, at every tier, the next edible
   object is visible and at most 3 s of rolling away.
2. **Always something just too big in view.** The next tier's food stands where you can see it, so you know what
   you are growing towards.
3. **Every place teaches one thing and rewards one skill.** Paths teach steering, the lily pads teach jumping,
   the skate park teaches ramps, the roofs test it all.
4. **Today's hazard is tomorrow's lunch.** Every obstacle that stops a small ball (hedge, fence, lawnmower,
   roundabout, traffic) is food for a bigger one. Growth is felt as the world giving way.
5. **Spread out, then converge.** Twelve balls start in four park quarters, mostly out of each other's way. The
   good stuff pulls everyone inwards, so the last minute is a crowd in Downtown.
6. **The skyline is the goal.** The Glass Tower in the centre is visible from every spawn, and by the bell the best
   ball can eat it.

## 3. The numbers the map is built on

All in studs (an avatar is about 5 studs tall). These come from `src/shared/Config.luau`,
`src/shared/Rules/Growth.luau`, `Movement.luau` and `Jump.luau` as they are today.

### 3.1 Size tiers (unchanged)

| Tier | Ball D | Eats objects up to | Name in this map | Where the food is |
| --- | --- | --- | --- | --- |
| 1 | 2 – 5 | 0.8 – 2 | **Acorn** | the park floor |
| 2 | 5 – 12 | 2 – 4.8 | **Picnic** | park furniture, toys, play kit |
| 3 | 12 – 30 | 4.8 – 12 | **Street** | park edge, ring road, yards, rooftops |
| 4 | 30 – 70 | 12 – 28 | **Car** | vehicles, sheds, kiosks, **cottages** |
| 5 | 70 – 150 | 28 – 60 | **Skyline** | terraces, apartment blocks, towers, landmarks |

### 3.2 Growth economy: how much food a ball needs

Growth is `D³ ← D³ + k·s³` (Downtown uses `growthK` 3.6). The pickups needed to climb one tier depend on how big the
food is compared with the ball (`r = s / D`):

| Typical food size `r` | Pickups per tier |
| --- | --- |
| 0.20 | 81 – 97 |
| 0.25 | 42 – 51 |
| 0.30 | 25 – 30 |
| 0.35 | 16 – 20 |
| 0.40 (the largest you can eat) | 12 – 14 |

**Rule: the main route at each tier serves food at `r` 0.25 to 0.35**, so a tier takes 20 to 50 pickups, one every
1 to 1.5 s. Smaller food (`r` 0.1 to 0.2) is "garnish": it gives the pop and the sound but little growth. Set pieces
serve food at `r` 0.35 to 0.4 as their reward: a set piece cleared is about half a tier.

### 3.3 Speed and jump reach

Speed is `18 × √(D/2)`, capped at 32. So a small ball darts (9 ball-lengths a second at D 2) and a big ball rolls
heavily (0.4 ball-lengths a second at D 80). Small food therefore sits close together, and big food further apart.

| D | Speed | Tap jump rise | Flat gap, tap | Flat gap, hold | Gap with Dash (×2) |
| --- | --- | --- | --- | --- | --- |
| 2 | 18 | 1.6 | 4.0 | 4.7 | 9.5 |
| 5 | 28.5 | 3.0 | 10.0 | 11.8 | 23.7 |
| 8 | 32 | 4.8 | 14.2 | 16.9 | 33.7 |
| 12 | 32 | 7.2 | 17.3 | 20.6 | 41.3 |
| 20 | 32 | 12.0 | 22.4 | 26.6 | 53.3 |
| 30 | 32 | 18.0 | 27.4 | 32.6 | 65.3 |
| 80 | 32 | 48.0 | 44.8 | 53.3 | 106.6 |

**Gap rule:** a gap meant for tier N is at most **70 %** of the tap gap of the smallest ball that should make it
(a comfortable jump), or up to **90 %** of the hold gap for a "brave" optional jump. A gap that needs a Dash says so
with a boost pad right before it.

**Speed proposal (tune):** keep the curve, but let the cap rise for big balls so the late game does not feel like
wading: cap 32 up to D 12, then `32 + 0.4 × (D − 12)`, at most 56 (`maxServerBallSpeed`). D 30 → 39, D 70 → 55.
Crossing the map at D 70 then takes 18 s instead of 31 s.

### 3.4 Pacing target for a median player (tune)

| Time | Diameter | Where they are | What they are eating |
| --- | --- | --- | --- |
| 0:00 – 0:03 | 2 | own doorstep | first pickup within 3 s |
| 0:45 | 5 | own park quarter | acorns, mushrooms, flowers, picnic food |
| 1:35 | 12 | park set pieces, Park Loop | toys, bikes, scooters, garden gnomes, hedges |
| 2:05 | 20 ★ | park edge, ring road | hot-dog trolleys, mailboxes, phone booths, benches |
| 2:30 | 30 | neighbourhoods, roof run | rooftop kit, mopeds, small trees, then cars |
| 2:55 | 45 ★★ | neighbourhoods, Downtown edge | cars, vans, sheds, kiosks, cottages |
| 3:30 | 70 | Downtown | buses, small shops, houses |
| 4:00 | 80 – 150 ★★★ | Downtown centre | terraces, apartment blocks, towers. The best run eats the Glass Tower |

Stars stay at 20 / 45 / 80. A good player should get 3 stars about one run in three. The best ball in a full
server should reach D 120 to 150.

## 4. The map at a glance

**1,000 × 1,000 studs** playable (`halfExtent` 500), inside a 1,240 × 1,240 scenery bound (`outerHalfExtent` 620).
The hub moves from x = −620 to x = −760. `m = max(|x|, |z|)` is the ring measure; x is east, z is south.

| Ring | `m` | What | Tiers |
| --- | --- | --- | --- |
| **Park** | 300 – 500 | Four park quarters with 3 spawns each, joined by the Park Loop path at `m` 400 | 1 – 2, a little 3 and 4 |
| **Ring Road** | 260 – 300 | A 40-wide loop road round the city: traffic, park gates, boost pads | 2 – 4 |
| **Neighbourhoods** | 150 – 260 | Four districts: Market Street and the Roof Run (NE), Car Park and Building Site (SE), Terraces and Cottages (SW), Station and Rail Yard (NW) | 3 – 4, the first 5 |
| **Downtown** | 0 – 150 | Plaza, four tower blocks, the Sky Rail at y 30, the Glass Tower | 4 – 5 |

Four **Spokes** (40-wide avenues on the x and z axes) run from the Plaza to the park edge. Inside the park they are
wide gravel paths. They are the fast, readable lines inwards, and every spawn sees one.

**Why 1,000 studs:** the park ring has to give 12 small balls about 57,000 square studs each for the first 1.5
minutes, while a D 70 ball at the proposed speed crosses Downtown in about 5 s and the whole map in 18 s. 880 (008)
is too tight for the park, and 1,200 leaves the big balls rolling through empty space.

## 5. Spawns and the first ten seconds

- **12 spawns**, 3 per park quarter, at `(±180, ±440)`, `(±440, ±180)` and `(±450, ±450)`. The nearest two
  spawns are 270 studs apart, so starters do not meet in the first 20 s.
- Each spawn stands on a **doorstep**: a 35-stud mown circle with **32 Tier 1 objects**, all edible at D 2
  (`size ≤ 0.8`), laid out as a **trail**: a spiral of 6 pieces round the spawn, then a line leading off towards
  the quarter's set piece. Following the trail is the tutorial.
- From every spawn you can see: the trail, a set piece (tree house, island, maze or slide tower), the Ferris wheel or
  windmill in the park, and the Glass Tower above everything. Nothing taller than 2 studs stands within 20 studs of
  a spawn, and no wall stands within 35.
- The four quarters get **the same food budget** (±10 % by volume per tier), so no spawn is better than another.
  What differs is the set piece.

## 6. The park (Tiers 1 – 2)

### 6.1 Park-wide rules

- **Ground** is grass with gravel paths 10 studs wide. The **Park Loop** path at `m` 400 links all four quarters and
  all 12 doorsteps; paths are where the food trails run.
- **Food lives in clumps and trails, never scattered evenly.** A clump is 6 to 20 objects in a natural group: a
  fairy ring of mushrooms, acorns under an oak, a picnic blanket, a flower bed, a dropped bag of toys. Between clumps
  there is a trail along the path. Open lawn between paths stays mostly empty: the empty space is what makes the
  clumps read.
- **Edge of the park** (`m` 300) is a 3-stud railing and hedge line (size 3.2, edible from D 8) with **8 open
  gates**: the four Spokes and the four diagonals. Small balls may leave the park any time, but the ring road traffic
  bumps them and the city has little their size.
- **Late-game park:** the park keeps Tier 3 and 4 trees, sheds, the boathouse and one Tier 5 landmark per quarter,
  so a big ball has a reason to come back out (section 10).

### 6.2 NW quarter: Woods and Campsite

| Place | Where (centre) | Size window | What happens |
| --- | --- | --- | --- |
| **Mushroom Glade** | (−430, −300), radius 32 | D 2 – 5 | The densest Tier 1 spot in the game: 3 fairy rings of mushrooms, acorn piles, pine cones, snails' shells, beetles (static). 4 **toadstool bounce caps** (trampoline surfaces, 3 wide, bounce to 6 studs) lift small balls onto a log platform with 8 bigger pieces (`r` 0.4). |
| **Giant Oak and Tree House** | (−370, −370), trunk radius 12 | D 3 – 12 | A root ramp spirals twice round the trunk (8 studs wide, 12° slope) to a tree house deck at y 22. The ramp is lined with acorns, conkers and birds' nests. The deck holds a picnic of Tier 2 food and a **Magnet** booster. A **zipline** (rail R4) runs 100 studs from the deck down to the NW park gate. |
| **Root Tunnels** | under the oak | D < 3.5 only | Three tunnels 3.5 wide and 3.5 high from the glade to the oak. A small-only shortcut, and a stash of 12 objects at `r` 0.4 plus a golden-object spot. |
| **The Stream** | x = −320, z −500 to −300 | all | 10 wide, 3 deep, slow water (section 9.4). Crossings: a footbridge (z −470), stepping stones 3.5 apart (z −360), and a **fallen log** (rail R1, z −440) that is also a rail for D 2 – 8. |
| **Campsite** | (−455, −90) | D 5 – 12 | Tents (Tier 2), camping chairs, lanterns, a cool box, marshmallow bags, a campfire ring; a parked camper van (Tier 4) and a canoe rack for later. |
| Quarter landmark (Tier 5) | the Giant Oak itself | D 100+ | Size 40. The last thing in the park to go. |

### 6.3 NE quarter: Pond and Boathouse

| Place | Where | Size window | What happens |
| --- | --- | --- | --- |
| **The Pond** | (340, −340), 140 × 110 | — | Deep water for D < 12 (section 9.4). From D 12 a ball wades through it (bed 5 below the surface, slow). |
| **Duck Island** | pond centre, radius 15 | D 2 – 10 | The quarter's prize: a duck house, a rubber-duck pile, a lost picnic, 20 objects at `r` 0.35 – 0.4 for a D 4 – 8 ball (about half of Tier 2 in 10 s) and a golden-object spot. |
| Route 1: **Lily pads** | west shore (270, −340) to the island | D 3 – 8 | 6 pads, 5 wide, gaps 3.5. A tap jump makes it from D 3 (gap 70 % of a D 3 tap); D 2 must hold-jump (brave). |
| Route 2: **Jetty and diving board** | south shore (340, −290) | D 2 – 8 | A 20-stud jetty ending in a diving board (a fixed bounce pad, bounce 10 up, 18 forward) onto the island. Readable from the Park Loop. |
| Route 3: **Drain pipe** | north shore (340, −395) | D 2 – 6 | A pipe running 40 studs to the island at water level: rail R2. |
| **Rubber duck flotilla** | on the water | D 2 – 6 | 12 floating ducks (size 1.2) between the pads, reachable only by jumping from a pad. |
| **Boathouse** | east shore (418, −345) | D 12 – 45 | Pedalos, canoes and rowing boats (Tier 3) on a ramp into the water; the boathouse itself is Tier 4 (size 18). |
| **Picnic Lawn** | (230, −305) | D 2 – 12 | Blankets with cakes, sandwiches, watermelons, cool boxes, frisbees, a deckchair row. |
| Quarter landmark | **Giant Inflatable Duck** moored at (250, −430) | D 75+ | Size 30. Bobs (client tween). |

### 6.4 SE quarter: Playground, Skate Park and Courts

| Place | Where | Size window | What happens |
| --- | --- | --- | --- |
| **Playground** | (345, 235), 90 × 70 | D 2 – 12 | **Slide tower**: stairs-ramp up to y 10 and a slide that launches you over the sandpit (a ramp-launch). **Roundabout**: a spinning disc, a sweeper trap that flings balls under D 6 and is food at D 12. **Trampolines** (bounce pads, edible at D 10). **Sandpit**: slow ground with buried toys. Swings and see-saw as Tier 3 food. |
| **Skate Park** | (350, 340), 100 × 80 | D 3 – 20 | A bowl 6 deep, two quarter pipes, a funbox and a kicker ramp, with a handrail (rail R3) along the stairs. **Boost pads** at both bowl entries. Food: skateboards, scooters, helmets, caps, cans, a BMX (Tier 3). Pumping the bowl from pad to kicker launches a D 8 ball onto the roof of the shelter (a 14-stud-high stash). |
| **Courts** | (275, 430), 80 × 90 | D 2 – 12 | Tennis court with 40 tennis balls (the best Tier 1 field outside a doorstep), a basketball half-court, a five-a-side pitch with footballs and cones. Fenced 3 high (edible at D 8) with gaps at the corners. |
| Quarter landmark | **Ferris Wheel** at (450, 330) | D 125+ | Size 50, turns slowly. Visible from half the map. |

### 6.5 SW quarter: Gardens and Hedge Maze

| Place | Where | Size window | What happens |
| --- | --- | --- | --- |
| **Hedge Maze** | (−340, 340), 90 × 90 | D 2 – 8, then food | Hedges 3 high (size 3.2, edible from D 8), corridors 6 wide, two entrances. The centre has a Gnome King statue (Tier 2, `r` 0.4 for D 6), 15 objects at `r` 0.35 and a golden-object spot. **At D 8 the maze becomes food:** about 60 hedge pieces, the best Tier 2 field in the park. A small ball can solve it; a grown ball can eat straight through. |
| **Flower Beds and Rose Garden** | (−285, 430) | D 2 – 6 | Rows of flowers (Tier 1), watering cans, garden gnomes (Tier 2), bird baths, a sundial. |
| **Allotments** | (−440, 270) | D 2 – 30 | Vegetable rows (Tier 1 – 2: tomatoes, cabbages, pumpkins), a scarecrow, wheelbarrows, then **sheds** (Tier 3 – 4) and a **greenhouse** with glass walls and a 3-wide door (small-only inside, eaten whole at D 45). |
| **Sprinkler Lawn** | (−230, 350) | D 2 – 8 | Wet grass: slick trap, with a ring of rotating sprinklers. Food sits beyond it. |
| **Lawnmower** | patrols the lawns between maze and flower beds | D 2 – 10 hazard | A ride-on mower on a loop path (sweeper): bumps small balls. Size 4, so a D 10 ball eats it (a hero object). |
| Quarter landmark | **Windmill** at (−290, 470) | D 90+ | Size 36, sails turning. |

## 7. The Ring Road (Tiers 2 – 4)

- A **40-wide loop road** at `m` 260 – 300, with a 6-wide pavement on each side, round the whole city. It is the
  map's fast-travel lane: **8 boost pads** (section 9.2) in the inner lane at the four Spokes and the four
  diagonals, pointing clockwise.
- **Traffic**: 10 cars, 2 vans and 1 bus on the loop at 24 studs/s, in convoys with long gaps. A car bumps any ball
  under D 30 (`Bumper`, knocks off 3 objects); from D 35 the cars are food.
- **Pavement stalls** at each park gate: a hot-dog trolley, an ice-cream cart, a phone booth, a mailbox, a bike
  rack with bikes and e-scooters, a newspaper box and a bench (Tier 3, sizes 4.5 – 9). Eight of these "gate
  corners" are the first Tier 3 field and the first place balls meet.
- **The drain**: under each diagonal gate a storm drain (4 wide, 4 high, small-only) runs from the park to a
  neighbourhood back street: a safe crossing under the traffic for D < 4.

## 8. Neighbourhoods and Downtown (Tiers 3 – 5)

### 8.1 NE: Market Street and the Roof Run

- **Market Street** (z −200, x 40 to 250) with shop fronts both sides (invented shop names, style bible §5).
  Market stalls down the middle: fruit crates, flower buckets, a cheese counter, an ice-cream van, a hot-dog stand,
  phone booths, café tables (Tier 3).
- **The Roof Run.** The north row is a chain of **8 flat roofs** (22 × 26 each) from (240, −232) west to (45, −232),
  heights 10, 12, 12, 14, 16, 16, 18, 20.
  - **Up**: a delivery-ramp (a truck with its ramp down, 15° slope) at the east end, and a jump pad in the alley at
    (165, −205).
  - **Gaps** between roofs: 8, 10, 8, 12, 10, 12 studs (each within 70 % of a D 12 tap jump).
    Gap 7 is the **brave gap**: 24 studs, with a boost pad on the roof before it (needs a Dash or a D 22 hold).
    Falling just drops you into Market Street; nothing is lost.
  - **Rooftop food** (Tier 3, for D 12 – 30): air-conditioning units, satellite dishes, chimney stacks, solar
    panels, water tanks, a pigeon coop, rooftop deckchairs, potted trees, a rooftop hot tub (hero), a rooftop
    barbecue. About 70 objects at `r` 0.3, the best Tier 3 route in the map.
  - **Down**: the last roof (y 20) ends in a **billboard ramp** that launches south over the Downtown hoardings onto
    the Plaza. This is the **early way into Downtown** for a Tier 3 ball (normally it opens at D 30). A golden-object
    spot sits on the last roof.

### 8.2 SE: Car Park and Building Site

- **Multi-storey Car Park** at (197, 203), 75 × 85, three decks at y 8, 16, 24, joined by two spiral ramps (12°).
  Parked cars on every deck (Tier 4), trolleys, cones and barriers (Tier 2 – 3). A golden-object spot on the top deck.
- **Crane jib rail**: a tower crane stands in the Building Site; its jib passes over the car park's top deck.
  Rolling onto the jib from the top deck is **rail R6** (D 12 – 40): it carries you 90 studs north-west and drops you
  into Downtown's SE block. The second early way in.
- **Building Site** at (205, 85), fenced by hoardings (Tier 3 – 4): cement mixers, pallets of bricks, pipes,
  portable cabins, a digger, skips, scaffolding. Ramps of planks and a container platform (y 12) for jumping.

### 8.3 SW: Terraces and Cottages

- Two rows of **houses** facing a street (x −250 to −60, z 170 to 245) and a back alley (6 wide, small-only gates).
  This is where the owner's "at some point you start eating houses" lands.
  - **Cottages** (size 22 – 26): Tier 4, edible from D 55 – 65.
  - **Terraces** (size 30 – 34): Tier 5, edible from D 75 – 85.
- Front gardens are dense Tier 2 – 3 food for the ball on the way in: wheelie bins, bikes, garden gnomes,
  trampolines, paddling pools, washing lines (a low rail for D 5 – 12), barbecues, kennels (empty), garden sheds.
- Driveways with hatchbacks and a camper van (Tier 4).

### 8.4 NW: Station and Rail Yard

- A **station** at (−205, −205) with two platforms: benches, vending machines, luggage trolleys, ticket machines
  (Tier 3), and a parked train of 4 carriages (each size 25, Tier 4).
- **Rail Yard**: 4 tracks along z −160 to −142, x −250 to −40. The rails are **ground rails** (rail R7, D 5 – 20):
  land on a track and you grind along it to the Downtown edge.
- The **Sky Rail** station: a spiral ramp up to y 30 (the start of rail R8).

### 8.5 Downtown (Tiers 4 – 5)

- Closed by **hoardings** (size 12, edible from D 30) round the whole `m` 150 square, with delivery trucks (size 17)
  parked across the Spokes. **Downtown opens when you reach Tier 4**, unless you came in early over the Roof Run or the
  crane.
- **The Plaza** (radius 50) with a fountain (Tier 4), the theme's landmark on a pedestal (Giant Duck in `city`, the
  Mega Tree in `winter`), café terraces, a bandstand, buses at stops.
- **Four tower blocks**, 80 × 80 each:
  - NE: **The Glass Tower** (size 60, the finale; edible at D 150), with a helipad and the tethered balloon duck.
  - NW: office towers (40 – 50) and a cinema (36).
  - SE: apartment blocks (40) and a hotel (45).
  - SW: Town Hall with a clock tower (45) and a library (34).
- **The Sky Rail** (rail R8, D 20 – 80): an elevated loop at y 30 round Downtown at `m` 145, reached by the Station
  ramp or by spring pads on the four Spoke corners. It is the fast way round Downtown and the stage for the last
  minute (section 10). Its supports are Tier 5 food.
- Shops at street level (Tier 4 – 5): corner shops, a bakery, a donut food truck, kiosks, bus shelters.

## 9. New and changed mechanics this map needs

Each is a data-driven rule (Constitution III and VII). Values are **(tune)**.

### 9.1 Rails and ziplines (new)

- A **rail** is a polyline in the world data with `dMin`, `dMax`, `speed` and `exit` (`launch` or `drop`).
- A ball within its size window that touches the rail from above **snaps on**: it rides the line at
  `max(currentSpeed, speed)`, it cannot fall off, and a jump leaves the rail with the current velocity plus the
  jump. At the end it launches along the rail direction.
- A ball outside the window is not snapped: on a thin rail it simply rolls off; a ball above `dMax` may eat the rail
  (if it is an object) or roll over it.
- Server check: while on a rail the speed and vertical guard use the rail's path and speed instead of the ground
  rules (`BallGuard` gets a "railed" state).

| Rail | Where | D | Length | Speed |
| --- | --- | --- | --- | --- |
| R1 Fallen Log | stream, NW | 2 – 8 | 30 | 20 |
| R2 Drain Pipe | pond north shore → island | 2 – 6 | 40 | 22 |
| R3 Skate Handrails (×3) | skate park | 2 – 12 | 12 – 20 | 26 |
| R4 Tree House Zipline | oak deck → NW gate | 2 – 12 | 100 | 34, downhill |
| R5 Washing lines (×6) | terrace gardens | 5 – 12 | 15 | 20 |
| R6 Crane Jib | car park top deck → Downtown SE | 12 – 40 | 90 | 36 |
| R7 Rail Yard tracks (×4) | rail yard → Downtown W edge | 5 – 20 | 210 | 34 |
| R8 Sky Rail | Downtown loop, y 30 | 20 – 80 | 1,160 (loop) | 44 |

### 9.2 Boost pads (new; the 006 Dash booster stays as a pickup)

- A fixed pad (chevrons on the ground, 8 × 12 for small, 20 × 30 on roads). Rolling over it sets the ball's
  velocity along the pad to `1.8 × targetSpeed(D)` for 1.5 s, then it decays over `boostDecayGrace`. No claim, no
  respawn, a 1 s cooldown per ball. Respects `boostSpeedCap` 80.
- Placed only where speed leads to something: before a jump, a ramp, a rail start or a long straight.
  Count: 8 on the Ring Road, 2 at the skate bowl, 1 before the brave roof gap, 2 at the playground slide run-up, 4
  on the Downtown Spokes facing the Plaza (total 17).

### 9.3 Bounce pads (new) and spring pads (fixed)

- **Bounce surfaces** (toadstool caps, trampolines, the diving board): a fixed up-and-forward launch for balls up
  to their `dMax` (they are objects, so above that size they are food). Bounce height 6 – 12.
- **Spring pads** at the Spoke corners of Downtown launch D 20+ balls to the Sky Rail (height 32).

### 9.4 Water (new)

- **Deep water** (the pond for D < 12, the stream never): a ball whose bottom touches deep water sinks over 1 s and
  respawns on the last shore point it left, with nothing lost. A soft fail: you lose about 3 s.
- **Wading water** (the pond for D ≥ 12, the stream for all): the slow trap (`slowSpeedMultiplier` 0.5) with a
  splash.
- Floating objects (ducks, lily pads, boats) stand at the surface and are absorbed normally.

### 9.5 Size gates (data, no new code)

A gate is just an object or wall line whose `size` sets the D that eats it:

| Gate | Size | Opens at D | What it unlocks |
| --- | --- | --- | --- |
| Root tunnels, drains, back alleys | 3.5 – 4 high | closes above D 3.5 – 4 | small-only shortcuts |
| Hedge maze, park railings, court fences | 3.2 | 8 | the maze becomes food |
| Pond depth | 5 | 12 | wading |
| Building-site hoardings | 10 | 25 | the site |
| Downtown hoardings | 12 | 30 | Downtown |
| Delivery trucks on the Spokes | 17 | 42.5 | the Spokes into the Plaza |

### 9.6 Things that change with size (summary)

| Thing | Small ball | Big ball |
| --- | --- | --- |
| Lawnmower, roundabout, traffic | hazard | food |
| Trampolines, toadstools, diving board | launcher | food |
| Hedges, fences, hoardings | walls | food |
| Pond | deep (fail) | wading |
| Tunnels, drains, alleys | shortcut | too small to enter |
| Rails | ridable in their window | rolled over or eaten |

## 10. Twelve players: spreading, meeting and fair chances

- **First 90 s**: each quarter has 3 players and its own set piece. The set pieces are big enough for 3 (the island
  takes 20 objects and three routes in).
- **90 – 150 s**: the Park Loop, the 8 gate corners and the Ring Road are where balls first meet. Bigger balls bump
  smaller ones (`ballBumpSizeRatio` 1.25, knock-off 3).
- **150 – 240 s**: every route leads inwards. The neighbourhoods give 4 directions in, Downtown has the scarce Tier 5
  food, so the last minute is a contested crowd. **Tier 5 objects never respawn in a run**: first come, first eaten.
- **Respawn**: Tiers 1 – 3 respawn after 60 – 120 s out of sight (today's rule); Tier 4 after 90 – 150 s; Tier 5 never.
- **Catch-up (tune)**:
  - Magnet boosters (006) appear twice as often within 60 studs of the three smallest balls after 1:30.
  - The park keeps 20 % of its Tier 1 – 2 food and all of its Tier 3 – 4 park objects, so a late starter still has a
    good route.
  - **Big balls cannot eat other balls** in the default mode (the GDD's swallow-a-friend mode stays opt-in).
- **Timed beats (tune)**:
  - **2:00 Parade**: a parade of 6 vehicles (floats, an ice-cream van, a marching-band truck; sizes 8 – 20) does one lap
    of the Ring Road. Food for Tier 3 and 4, and a spectacle that pulls balls to the road. A banner announces it.
  - **3:20 Last Light**: the Sky Rail lights up and a golden object appears on the Glass Tower helipad (reachable
    from the Sky Rail with a jump). A last skill target for the leaders.
- **Golden object**: one per day (as today), seeded among 8 spots: Duck Island, the maze centre, the root-tunnel
  stash, the tree-house deck, the skate shelter roof, the last roof of the Roof Run, the car park top deck and the
  Glass Tower helipad.

## 11. Object catalogue for this map

The Downtown list in [02-city-assets.md](02-city-assets.md) stays and is placed in the city rings. The park needs
these **new** objects. Sizes in studs (longest side). ★ = hero (see 02's rule). Names follow the deadpan rule; the
twist is in the model.

### Tier 1 (park floor, 0.3 – 2; eaten from D 0.75 – 5)

| Object | Size | Place | Object | Size | Place |
| --- | --- | --- | --- | --- | --- |
| Acorn | 0.3 | woods | Sunflower seed pile | 0.4 | flower beds |
| Pine cone | 0.5 | woods | Conker | 0.4 | woods |
| Pebble | 0.4 | pond, paths | Ladybird (still) | 0.3 | flower beds |
| Daisy | 0.5 | lawns | Snail shell | 0.5 | woods, beds |
| Toadstool (small) | 0.6 | glade | Mushroom cluster | 0.9 | glade |
| Tulip | 0.8 | beds | Rose | 0.9 | rose garden |
| Strawberry | 0.4 | picnic, allotment | Cherry tomato | 0.4 | allotment |
| Biscuit | 0.5 | picnic | Cupcake | 0.7 | picnic |
| Sandwich | 0.8 | picnic | Apple | 0.7 | woods, picnic |
| Rubber duck | 1.2 | pond | Tennis ball | 0.6 | courts |
| Shuttlecock | 0.6 | courts | Marble bag | 0.7 | playground |
| Toy car | 0.9 | sandpit | Building brick (toy) | 0.5 | sandpit |
| Bird's nest | 1.4 | oak ramp | Feather | 0.8 | pond |
| Sunglasses | 0.8 | picnic | Flip-flop | 1.2 | pond, picnic |
| Bubble wand | 1.0 | playground | Sand bucket and spade | 1.2 | sandpit |
| Garden trowel | 1.1 | allotment | Seed packet | 0.6 | allotment |
| Marshmallow bag | 0.9 | campsite | Lantern (small) | 1.3 | campsite |
| ★ Golden Acorn | 0.6 | glade (the daily golden candidate) | ★ Gnome's Lost Hat | 1.2 | maze |

### Tier 2 (park kit, 2 – 4.8; eaten from D 5 – 12)

| Object | Size | Place | Object | Size | Place |
| --- | --- | --- | --- | --- | --- |
| Garden gnome | 2.2 | beds, maze | Watering can | 2.0 | beds |
| Football | 2.0 | courts | Basketball (big) | 2.2 | courts |
| Beach ball | 2.4 | picnic, pond | Frisbee | 2.0 | picnic |
| Picnic basket | 2.2 | picnic | Cool box | 2.6 | picnic, campsite |
| Watermelon | 2.4 | picnic | Pumpkin | 2.8 | allotment |
| Cabbage | 2.0 | allotment | Hay bale (small) | 3.6 | allotment |
| Skateboard | 2.2 | skate park | Kick scooter | 3.0 | skate park |
| Helmet | 2.0 | skate park | Traffic cone | 2.0 | courts, site |
| Camping chair | 3.0 | campsite | Tent (pop-up) | 4.5 | campsite |
| Bird bath | 3.2 | beds | Sundial | 3.0 | rose garden |
| Wheelbarrow | 4.0 | allotment | Scarecrow | 4.6 | allotment |
| Hedge piece | 3.2 | maze, park edge | Railing piece | 3.2 | park edge |
| Trampoline (garden) | 4.4 | playground, yards | Paddling pool | 4.6 | yards |
| Lily pad | 4.0 | pond | Pedal car | 3.4 | playground |
| Toadstool (bounce cap) | 3.0 | glade | Deckchair | 3.4 | picnic lawn |
| ★ Gnome King | 3.6 | maze centre | ★ Inflatable Flamingo | 3.0 | pond shore |
| ★ Three-Tier Birthday Cake | 2.8 | picnic lawn | ★ Spinning Office Chair | 3.4 | building site |

### Tier 3 (park edge and street, 4.8 – 12; eaten from D 12 – 30)

| Object | Size | Place | Object | Size | Place |
| --- | --- | --- | --- | --- | --- |
| Bicycle | 6.0 | racks, yards | BMX | 5.0 | skate park |
| E-scooter | 3.8 → 5 (upright) | racks | Moped | 6.0 | streets |
| Bench | 7.0 | everywhere | Picnic table | 6.0 | picnic lawn |
| Hot-dog trolley | 7.5 | gate corners, market | Ice-cream cart | 6.5 | gate corners |
| Phone booth | 8.0 | gate corners | Mailbox | 4.5 | gate corners |
| Newspaper box | 5.0 | gate corners | Vending machine | 7.0 | station |
| Ride-on lawnmower ★ | 4.0 → hazard, then food | SW lawns | Roundabout | 9.0 | playground |
| See-saw | 8.0 | playground | Swing set | 10 | playground |
| Pedalo (swan) | 7.0 | pond | Canoe | 9.0 | boathouse |
| Rowing boat | 10 | pond | Garden shed | 9.0 | allotments, yards |
| Young tree | 9.0 | parks, streets | Big bush | 6.0 | park |
| Air-conditioning unit | 5.0 | roofs | Satellite dish | 5.0 | roofs |
| Chimney stack | 6.0 | roofs | Solar panel | 5.0 | roofs |
| Water tank | 8.0 | roofs | Pigeon coop | 6.0 | roofs |
| Fruit stall | 8.0 | market | Café table set | 5.0 | market |
| Luggage trolley | 6.0 | station | Ticket machine | 6.0 | station |
| Cement mixer | 8.0 | site | Skip | 10 | site |
| ★ Rooftop Hot Tub | 9.0 | roof run | ★ Inflatable Tube Guy | 9.0 | market |
| ★ Arcade Cabinet | 6.5 | station | ★ Vending Machine (drops cans) | 7.0 | station |

### Tier 4 (vehicles and small buildings, 12 – 28; eaten from D 30 – 70)

Everything in 02's Tier 4 list (hatchback, taxi, van, food trucks, bus, fire engine, containers, big trees), plus:
camper van (16), boathouse (18), bandstand (16), greenhouse (18), digger (16), portable cabin (14), train carriage
(25), park café (20), playground slide tower (14), skate shelter (14), parade floats (15 – 20), **cottage (22 – 26)**.

### Tier 5 (skyline, 28 – 60; eaten from D 70 – 150)

Everything in 02's Tier 5 list, plus: terrace row (30 – 34), Giant Inflatable Duck (30), Windmill (36), Giant Oak (40),
station hall (40), car park (50), Ferris Wheel (50), Glass Tower (60).

### Moving objects (cap: 24 moving at once)

Traffic (13), the parade (6, only during the beat), the lawnmower (1), ducks on the pond (4, path-follow). Pigeons stay
ambient scenery that flies off (02 "Not in the kit"). Everything moves on a path or a spin, never free physics.

## 12. Budgets

Within today's limits (`maxActivePartsPerServer` 2,000, `defaultMaxPlacements` 1,500):

| Tier | Park | Ring Road | Neighbourhoods | Downtown | Total |
| --- | --- | --- | --- | --- | --- |
| 1 | 540 (12 × 32 doorsteps + 156 in set pieces) | – | – | – | **540** |
| 2 | 330 | 30 | 60 | – | **420** |
| 3 | 70 | 70 | 140 | 20 | **300** |
| 4 | 24 | 13 moving + 10 | 103 | 40 | **190** |
| 5 | 4 | – | 16 | 30 | **50** |
| | | | | | **1,500** |

- Plus at most **250 blocks** (ground, roads, roofs, ramps, rails, water) and **17 boost pads**. Active parts ≤ 1,850
  as in 008.
- Food check against section 3.2: each tier gives every ball that reaches it about 30 – 45 pickups, counting
  respawns. Tier 5 is deliberately short (50 objects for the 3 to 5 balls that get there): the scarcity is the contest.
- `cullTierDelta` 2 stays: a Tier 4 ball no longer renders the park's Tier 1 – 2 food.
- Triangle ceilings as in 03 (whole scene ≤ 550,000 in `winter`; what a Tier 5 player sees ≤ 290,000).

## 13. Open decisions for the owner

1. **Approve this map** as the launch layout instead of Downtown "Inside Out" (008).
2. **Speed cap for big balls**: keep 32 for all, or the rising cap of section 3.3.
3. **Rails, boost pads, bounce pads and water** are new mechanics (section 9). Approve all four, or name the ones to
   cut. Without rails, R1 – R8 become plain ramps and bridges.
4. **Timed beats** (Parade at 2:00, Last Light at 3:20): yes or no.
5. **Ball-eats-ball** stays off by default: confirm.
6. Holiday City (`winter`) dressing for this map: the pond becomes an ice rink (slick, and it no longer drowns small
   balls), the maze gets lights, the Plaza gets the Mega Tree. Confirm the pond rule.

## 14. How to build it (proposed feature order)

Constitution I applies: grey box first, fun judged on the release candidate. Gate 6 applies: the map is not done until
the owner has seen the images and played it.

1. **011 Park City grey box.** The whole 1,000-stud map as blocks and placeholder objects from this document's
   coordinates, all 12 spawns, all food counts. The pace test (`tests/unit/Pace.test.luau`) moves to the new map with
   the targets of section 3.4. Fixed shots: one per spawn quarter, the island, the maze, the roof run, the car park,
   the Plaza, and an overhead of the map. Owner plays it. **Nothing else starts until the owner says the grey box is
   fun.**
2. **012 Traversal mechanics.** Rails, boost pads, bounce pads, water (section 9), each behind a flag, each with pure
   rules and unit tests, placed in the grey box.
3. **013 Park art.** The Tier 1 – 3 park objects of section 11 to the style bible.
4. **014 City art pass.** Reuse and rebuild the Downtown kit for the neighbourhoods and Downtown.
5. **015 Beats and catch-up.** The parade, Last Light, the magnet bias.

### Acceptance checks for 011 (all automatable)

- Every spawn: first pickup ≤ 3 s, 32 doorstep objects all edible at D 2, no block above 2 studs within 20 studs.
- Pace model, 12 spawns, both themes: D 5 by 0:50, D 12 by 1:45, D 30 by 2:40, D 70 by 3:40 for the median spawn;
  no spawn more than 15 % behind the median at any mark.
- Density: along each main route, at every tier, the gap between edible objects of `r` ≥ 0.2 is at most 3 s of
  rolling at that tier's speed.
- Every gap on a designed jump route meets the gap rule of section 3.3 for its stated D window.
- Every place a small ball can fail (water, falling off a roof) has a way back to the route within 5 s.
- Budgets of section 12.
