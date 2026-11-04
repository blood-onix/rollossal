# Feature Specification: Park City Map (Grey Box)

**Feature Branch**: `claude/zealous-volta-6h9wnq` (spec folder `012-park-city-map`)

**Created**: 2026-11-04

**Status**: Draft

**Input**: User description: "012 Park City map: build the approved Park City level (docs/design/09-park-city-level.md v2, approved by the owner 2026-11-04) as a playable grey box from the layout data in docs/design/maps/park-city-layout.json. Scope: (1) the whole 1,000 x 1,000 map loaded from the layout data as a new world behind a flag, Downtown "Inside Out" stays the default until the owner switches; (2) the size and readability rules the map is built for: start at D 1, absorb by bulk, six tiers, stars 20/50/90, garnish, the heap fix, edible wobble and new-tier ripple cues, no text banners; (3) light objects: Tier 1-2 food is client-side data; (4) traversal set pieces present as static geometry, with rails, pads, catapults, water and ice as inert placeholders (their behaviour is feature 013); (5) the rising speed cap. Not in scope: 013 mechanics, 014 events and modes, 015/016 art. TESTING MUST BE REASONABLE: growth pace is measured and reported, never a pass/fail gate in this feature. The visual gate (gate 6) applies."

## Context

Features 008 (Downtown "Inside Out") and 010 (Main-Street slice) did not give the owner a map they could judge:
- Food was spread evenly, so the player had no destinations.
- The ball's heap looked about three times its real size.
- The size rule judged long thin objects by their length, so the player could not tell what was edible.
- Tests asked for growth-rate proof on a map that was not ready to play.

The owner approved a new level, Park City, on 2026-11-04. It is described in `docs/design/09-park-city-level.md` (v2) and laid out
object by object in `docs/design/maps/park-city-layout.json`, with maps in `docs/design/maps/`. This feature turns that
layout into a world the owner can play, with the size and readability rules the layout was built for. The traversal
mechanics (rails, pads, catapults, water), random events, modes and art come in later features.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Play the whole Park City map (Priority: P1)

A player joins Park City and starts as a tiny ball (D 1) on a doorstep in one of four park quarters. Crumbs lie in a
spiral around them and then in a trail. The trail leads to their quarter's set piece: the Mushroom Glade and Giant Oak,
Duck Island, the Playground and Skate Park, or the Hedge Maze. The Glass Tower stands on the horizon. As they grow they
roll along the Park Loop, out through a gate to the Ring Road, into a neighbourhood (Market Street and the Roof Run, the
Car Park, the Terraces, the Station), and finally into Downtown, which opens when they can eat its hoardings. Every
place in the layout exists, at the layout's coordinates, with every object of every scene where the layout puts it.

**Why this priority**: the owner cannot judge a map that does not exist. This is the thing 008 and 010 never delivered.

**Independent Test**: turn on the Park City flag, start a run, and roll from a spawn through each ring to the Plaza.
Compare the world with the overview and zone maps in `docs/design/maps/`.

**Acceptance Scenarios**:

1. **Given** the Park City flag is off (the default), **When** a server starts, **Then** Downtown "Inside Out" loads
   exactly as today.
2. **Given** the Park City flag is on, **When** a server starts, **Then** the world built is the layout: its zones,
   ground, roads, paths, buildings, roofs, ramps, decks, maze, tunnels, drains, water areas, 12 spawns, and every scene,
   trail, kerb line and landmark object at its layout position, height and facing.
3. **Given** a new player in Park City, **When** they spawn, **Then** they start at D 1 on one of the 12 spawns, facing
   the city, with the 20 doorstep crumbs of that spawn around them, all edible at D 1.
4. **Given** a ball at the size a route is meant for, **When** it follows that route (a Park Loop side, a gate, a Spoke,
   the Roof Run on foot with jumps, the car park ramps, the maze corridors), **Then** no static geometry blocks the way:
   ramps can be climbed, roofs and decks can be reached, and the designed gaps can be crossed with the existing jump.
5. **Given** the layout's rails, boost, bounce and spring pads, catapults, bullseyes, water and ice, **When** the world
   is built, **Then** each is present in its place as a visible, inert placeholder (a beam, a pad, a frame, a water
   surface) that does not change how the ball moves. Deep water behaves as a shallow floor until feature 013, so no
   ball is trapped.
6. **Given** a ball too small for a size gate (hoardings, delivery trucks, hedges), **When** it rolls into it, **Then**
   it is stopped. **Given** a ball big enough, **Then** it eats the gate and the way opens.

---

### User Story 2 - See what you can eat (Priority: P1)

The player can tell what is edible by looking. Their ball looks its real size. Anything smaller than about half the ball
can be eaten, judged by how chunky an object is, not by its longest side. A long thin violin no longer counts as a big
object, but a lamp post still cannot be eaten by a ball a third of its height. Nearby edible objects wobble gently. On
reaching a new tier, that tier's objects nearby wobble once together. Bumping something too big gives a thud and a
bounce, never a text banner.

**Why this priority**: the owner's screenshot showed a D 6.5 ball that looked about 15 across and could not eat a violin
behind it. A map is unplayable if the player cannot read sizes.

**Independent Test**: in Park City, grow from D 1 to about D 10. Check the heap's outline against the ball's real size,
eat a long thin object that the old rule refused, bump a too-big object, and watch the cues. Unit tests cover the rules.

**Acceptance Scenarios**:

1. **Given** an object and a ball, **When** the absorb rule is checked, **Then** the object is edible exactly when its
   bulk (the cube root of its length × width × height) is at most half the ball's diameter **and** its longest side is
   at most 1.5 × the diameter.
2. **Given** a ball eats an object, **When** it grows, **Then** growth uses the object's bulk. An object whose bulk is
   under 0.08 × the diameter is still swallowed (pop and sound) but adds no size (garnish).
3. **Given** a ball of any size with any eaten objects, **When** it is drawn, **Then** its outline, including the stuck
   objects, fits in a box at most 1.25 × its diameter. The one newest big catch may stick out further for a few
   seconds.
4. **Given** edible objects within 4 diameters of the local player's ball, **When** the player rolls nearby, **Then**
   up to 24 of the nearest ones bob gently, and too-big objects never move. With Reduce motion on, nothing bobs.
5. **Given** a ball that reaches a new tier, **When** the tier changes, **Then** that tier's objects within 6 diameters
   wobble once together, and no tier banner or "you can roll up" text appears.
6. **Given** a ball that hits a too-big object, **When** contact happens, **Then** it bounces back with a thud and a
   short camera nudge, with a cooldown so repeated rubbing does not chatter. No text appears.
7. **Given** Park City's tiers, **When** the player plays, **Then** the six tiers are Crumb (D 1–2.5), Pocket (2.5–6),
   Picnic (6–15), Street (15–35), House (35–80) and Skyline (80–150), and the stars are 20 / 50 / 90.

---

### User Story 3 - Twelve players on the full map without the server choking (Priority: P2)

Twelve players can play Park City together at a steady frame rate. The roughly 3,100 smallest objects (Tiers 1 and 2) do
not each cost the server a part: the server keeps their state as data and checks every absorb against their data
position, and each player's device draws only the ones near them. Bigger objects work as they do today.

**Why this priority**: the layout holds about 4,000 food objects, over the 2,000-part server budget if every object
were a part. Without this, the map cannot ship at its approved density. It is P2 because P1 can be shown with fewer
crumbs, but the feature is not done without it.

**Independent Test**: start Park City with 12 balls (the existing heavy-scene benchmark with bots). Read the server part
count and the per-second frame rate. Try absorbing a light object from too far away and confirm the server refuses it.

**Acceptance Scenarios**:

1. **Given** Park City is running, **When** the server part count is read, **Then** it stays under the 2,000 budget,
   with light objects not counted as parts.
2. **Given** a light object, **When** a ball eats it, **Then** every player sees it disappear, the eater grows, and the
   object respawns later by the same out-of-sight rule as other food.
3. **Given** a client that claims to eat a light object it is not touching, or one that is already taken, too big for
   it, or past the absorb rate limit, **When** the claim reaches the server, **Then** the server refuses it, as it does
   for parts today.
4. **Given** a player's camera, **When** they move, **Then** light objects within 120 studs are drawn and those further
   away are not. Objects two tiers below the player's tier are hidden, as `cullTierDelta` does today.
5. **Given** 12 balls in the heavy-scene benchmark, **When** frame rate is sampled per second, **Then** every
   unthrottled second is at or above 30 fps. Throttled seconds (exactly 15 fps) are reported separately.

---

### User Story 4 - Pace measured and reported, not gated (Priority: P2)

The owner gets an honest report of how fast balls grow on the real map: per spawn, for the profiles of the design
document (weak, median, skilled). Nothing in this feature fails because the pace is off. The pace is tuned after the
owner plays. Two things are checked because a map cannot be played without them: every spawn's first pickup within 3
seconds, and no dead ends (from every spawn, the open route always offers something edible all the way to Downtown).

**Why this priority**: the owner could not test earlier maps because tests demanded growth-rate proof before the map
was ready. This feature measures; tuning is a later decision.

**Independent Test**: run the pace report on the layout. Read the per-spawn table. Check that the two hard checks pass.

**Acceptance Scenarios**:

1. **Given** the layout, **When** the pace report runs, **Then** it lists, for each of the 12 spawns and each profile,
   the size at 0:30, 1:00, … 4:00 and the time of each tier, and marks spawns more than 15 % behind the median. It
   passes whatever the numbers are.
2. **Given** each spawn, **When** the first-pickup check runs, **Then** a ball at D 1 reaches an edible crumb within 3 s.
3. **Given** the open routes (no rails, pads or catapults), **When** the ladder check runs, **Then** at every size from
   D 1 up to the size that eats the hoardings, the route offers food: each zone's smallest food is at most 1.25 × the
   previous zone's largest.

---

### User Story 5 - Images for the owner (Priority: P2)

The owner sees the map before playing it, from fixed shots, then plays the build and approves or rejects it (gate 6).

**Why this priority**: the constitution makes the map's look a gate, and a map once closed as done with no images was
rejected. It is P2 only because it follows from P1.

**Independent Test**: the fixed shots exist in the spec folder and match their positions in the layout.

**Acceptance Scenarios**:

1. **Given** the built world, **When** the fixed shots are taken, **Then** there is one shot per park quarter from a
   spawn at D 1 camera height, plus Duck Island, the Hedge Maze, the Roof Run, the Car Park, the Plaza and a high
   overview. Each is named, and its camera position is recorded.
2. **Given** the shots and the build, **When** the owner reviews them, **Then** their approval or rejection is recorded
   in `specs/012-park-city-map/playtest.md`. The pull request may be opened to show the images and is not merged before
   approval.

---

### Edge Cases

- **Twelve starters at once**: the 12 spawns are at least 270 studs apart. Each has its own 20 crumbs, so no two
  starters share a doorstep. A spawn whose crumbs are taken (for example by a respawned ball) refills by the normal
  respawn rule.
- **A ball that falls off a roof or the car park**: it lands on the street or the deck below. Nothing is lost, as with
  any drop today.
- **Inert water**: until feature 013, the pond and stream are a shallow floor with a water surface drawn on top, so a
  small ball cannot get stuck or drown. The island is reachable by the lily pads (jumping) and by rolling.
- **Inert rails, pads and catapults**: a ball touching them is treated like ordinary static geometry (or rolls
  through a pad), so they never trap a ball or throw it.
- **Small-only tunnels and drains**: a ball too big for a tunnel is stopped at its mouth and never wedged inside. A
  ball that grows while inside is pushed out of the nearer end.
- **A light object a client has not drawn yet**: absorbs are judged by the server's data, not by what the client drew.
  A client that never drew an object can still eat it if it is genuinely touching it.
- **The heap at a tier jump**: when a big catch arrives, older small stuck objects are buried smoothly, with no
  visible pop.
- **Bulk of the ball itself**: ball-to-ball bumps keep today's rule (`ballBumpSizeRatio` 1.25). This feature does not
  let balls eat each other.
- **Studio throttled at 15 fps**: throttled seconds are reported separately and the result is judged on unthrottled
  seconds. If none are unthrottled, the owner is asked once to keep Studio in front (AGENTS.md).

## Requirements *(mandatory)*

### Functional Requirements

**World from the layout**

- **FR-001**: The game MUST provide a Park City world, built from the approved layout data, behind a flag that is off by
  default. With the flag off, the current default world loads unchanged.
- **FR-002**: The Park City world MUST be content data in the project's content folder, produced from
  `docs/design/maps/park-city-layout.json` by a repeatable step. The layout file stays the single source: changing the
  map means changing the layout script, regenerating the layout, and regenerating the world data, never editing the
  world data by hand.
- **FR-003**: The built world MUST contain every element of the layout at its position, height and facing:
  - ground, roads, paths, buildings, roofs, ramps and spiral ramps, decks, the maze hedges, tunnels and drains, water
    surfaces;
  - 12 spawns;
  - every scene object, trail object, kerb-line object and landmark.
- **FR-004**: Every object in the world MUST carry its dimensions (length, width, height). Its bulk and tier MUST follow
  from those dimensions by the rule of FR-010.
- **FR-005**: Rails, boost, bounce and spring pads, catapults and slingshots, bullseyes, water and ice MUST be present
  as inert placeholders: visible, at their layout positions, with no effect on movement. Each MUST carry the data that
  feature 013 needs (for example a rail's points, size window and speed), so 013 adds behaviour without moving
  anything.
- **FR-006**: Size gates (hoardings, delivery trucks on the Spokes, hedges, fences, railings) MUST be ordinary objects
  that block smaller balls and are eaten by balls big enough for them.
- **FR-007**: Small-only tunnels and drains MUST admit balls up to their size (3 studs) and stop bigger balls at the
  mouth without wedging them.
- **FR-008**: Spawns MUST follow the layout. A new ball starts at D 1 on its spawn, facing the city.
- **FR-009a**: The park MUST have no empty lawn: in each park quarter, at most 5 % of the area may be more than 40 studs
  from the nearest food (the layout reports this).
- **FR-009**: The layout's golden-object spots MUST be available to the existing daily golden-object rule.

**Size and readability**

- **FR-010**: In Park City, an object MUST be edible exactly when its bulk is at most 0.5 × the ball's diameter **and**
  its longest side is at most 1.5 × the diameter. Bulk is the cube root of length × width × height.
- **FR-011**: In Park City, growth MUST use bulk (D³ grows by `growthK` × bulk³). An object with bulk under 0.08 × the
  diameter adds nothing, and is still swallowed with its pop and sound.
- **FR-012**: Park City MUST use the start diameter 1, the six tiers Crumb, Pocket, Picnic, Street, House and Skyline at
  D 1 / 2.5 / 6 / 15 / 35 / 80, the stars 20 / 50 / 90, and its own `growthK` (starting value 1.6, tune), all as world
  data. The camera's closest distance MUST suit a D 1 ball (starting value 4 studs).
- **FR-013**: In Park City, the speed cap MUST be 32 up to D 12, then 32 + 0.4 × (D − 12), at most 56. The server's speed
  check MUST accept it.
- **FR-014**: The drawn ball, with its stuck objects, MUST fit in a box at most 1.25 × its diameter at every size:
  - stuck objects sit inside the surface, with their long axis along it;
  - each stuck object is drawn no larger than 0.45 × the diameter;
  - the single newest large catch may stick out up to 0.25 × the diameter for 3 s.

  This fix MUST have its own flag, on whenever Park City is on.
- **FR-015**: Up to 24 edible objects within 4 diameters of the local player's ball MUST bob gently. Objects too big to
  eat MUST NOT bob. Reduce motion MUST turn the bob off.
- **FR-016**: On reaching a new tier, that tier's objects within 6 diameters MUST wobble once together. In Park City the
  tier banner, the "next tier" line and the star-target text MUST NOT appear.
- **FR-017**: Hitting a too-big object MUST give a thud, a short camera nudge and a bounce, with a cooldown, and MUST NOT
  show text.

**Light objects**

- **FR-018**: In Park City, Tier 1 and Tier 2 objects (light objects) MUST NOT be server parts. The server MUST keep each
  one's state (available, taken, respawn time) as data, and MUST validate every absorb of one against its data position
  and size, with today's checks (touch distance, size rule, taken state, rate limit).
- **FR-019**: Each client MUST draw the light objects within 120 studs of its camera, MUST NOT draw the rest, and MUST
  hide those culled by the tier rule (`cullTierDelta`). A taken light object MUST disappear for every player.
- **FR-020**: Light objects MUST respawn by the same out-of-sight rule and delays as other Tier 1 and 2 food.
- **FR-021**: In Park City, the server part count (parts, blocks, placeholders, balls, runtime parts) MUST stay under the
  2,000 budget with 12 balls.

**Measurement (reported, not gated)**

- **FR-022**: A pace report MUST run on the layout for the 12 spawns and the design document's profiles, and MUST write
  its table into the spec folder. It MUST NOT fail on pace values.
- **FR-023**: Two pace-related checks MUST pass:
  - every spawn has a first pickup within 3 s at D 1;
  - the open-route size ladder has no gap (each zone's smallest food is at most 1.25 × the previous zone's largest),
    from D 1 to the size that eats the Downtown hoardings.

**Images and review**

- **FR-024**: Fixed shots MUST be produced from camera positions recorded in data: one per park quarter from a spawn,
  Duck Island, the Hedge Maze, the Roof Run, the Car Park, the Plaza and a high overview. If live Studio captures fail,
  the shots MUST come from another route that renders the world data (for example the existing Blender route), per the
  constitution.
- **FR-025**: The owner's review of the shots and of play MUST be recorded in `specs/012-park-city-map/playtest.md`.

### Hard gates for this feature (all machine-checkable)

| Gate | Check |
| --- | --- |
| G1 | `scripts/check.sh` passes, including new unit tests for: bulk and edibility, garnish, growth by bulk, the speed cap, the heap placement bound, light-object absorb validation, and the world data (unique ids, every object has dims, positions inside the map). |
| G2 | The layout regenerates with **0 overlaps**, no park quarter has more than 5 % of its area more than 40 studs from food, and the world data matches the layout (same objects, same positions). |
| G3 | Budgets: server part count under 2,000 with 12 balls; placement and triangle budgets as in the design document. |
| G4 | Every spawn: 20 doorstep crumbs edible at D 1; first pickup within 3 s. |
| G5 | The open-route ladder has no gap (FR-023). |
| G6 | The 12-ball heavy-scene benchmark holds 30 fps or more on every unthrottled second (viewport size recorded). |
| G7 | A Studio playtest of Park City with a clean console (no new errors or warnings from game scripts). |
| G8 | Constitution gate 6: the fixed shots exist and the owner has approved them and played the build. The pull request may open before this; it merges after. |

The growth pace (sizes and tier times) is **reported, never gated** in this feature.

### Key Entities

- **Layout**: the approved map as data. It holds:
  - zones, blocks, spawns;
  - scenes (a kind, a position, a facing, a footprint and the objects placed in it);
  - trails and kerb lines (a cause, a path and the objects along it);
  - landmarks, rails, pads, catapults, gates, tunnels, water, hazards and golden spots.

  Owned by the design; regenerated by script.
- **Object definition**: an object kind with its dimensions, bulk, tier and the diameter that eats it.
- **Scene**: a short story at one place (a picnic, a gate corner, a parking row). Small things sit at the front and
  the big thing at the back.
- **Light object**: a Tier 1 or 2 food item that exists as server data and client drawings, not as a server part.
- **Placeholder**: a rail, pad, catapult, bullseye or water surface that is visible and inert until feature 013, and
  carries 013's data.
- **Fixed shot**: a named camera position and target used for the owner's images.
- **Pace report**: a per-spawn, per-profile table of sizes over time and tier times, kept in the spec folder.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With the flag on, 100 % of the layout's objects, scenes, landmarks and placeholders appear in the world at
  their layout positions (checked by comparing the world data with the layout).
- **SC-002**: From each of the 12 spawns, a D 1 ball reaches its first pickup within 3 s, and all 20 doorstep crumbs are
  edible at D 1.
- **SC-003**: At every size from D 1 to the size that opens Downtown, the open route has no gap in its food ladder.
- **SC-004**: At sizes D 1, 2, 5, 10, 20, 50 and 100, with a full heap, the drawn ball fits in 1.25 × its diameter.
- **SC-005**: With 12 balls, the server uses fewer than 2,000 parts, and every unthrottled second of the benchmark is
  at or above 30 fps.
- **SC-006**: The pace report exists for all 12 spawns and 3 profiles, and lists every spawn more than 15 % behind the
  median, without failing the build.
- **SC-007**: The owner has seen the fixed shots, played the build, and recorded approval (or the changes they want) in
  `playtest.md`.
- **SC-008**: In a short owner session, the owner can say which nearby objects are edible without any text on screen.
  Recorded in `playtest.md` with the gate 6 review. Not a separate gate.

## Assumptions

- **Feature numbering**: the owner named this feature 012. Feature 010 exists on its own branch, and there is no 011.
  The work stays on this session's branch.
- **No 011**: the readability and size rules (the heap fix, bulk, D 1, cues) were proposed as a separate step 011. They
  are part of this feature because the map is built for them and cannot be judged without them.
- **Rules per world**: the size rule, start diameter, tiers, stars, `growthK` and speed cap are Park City world data, so
  Downtown and Snow Village keep today's rules. The heap fix is a general fix behind its own flag.
- **Placeholders do nothing**: rails, pads, catapults, water and ice behave as plain geometry or open floor until
  feature 013. Deep water is a shallow floor, so nobody is trapped.
- **Grey box**: objects use their existing stand-in shapes and palette colours (or existing meshes where an object
  already has one), sized by their dimensions. New art is features 015 and 016.
- **Respawn and culling**: today's respawn rule, delays and `cullTierDelta` 2 apply. The Tier 5 and 6 rules of the
  design document (Tier 6 never respawns, Tier 5 after 120 to 180 s) apply in Park City as world data.
- **Pace numbers**: the growth model's profiles and the design document's section 5.3 targets are the reference for the
  report. The model assumed more Tier 5 and 6 objects than the first-pass layout holds, so the report is expected to
  show a lower ceiling for the top players. That is input for tuning after the owner plays, not a failure.
- **Benchmark size**: the Studio MCP cannot resize the viewport, so the benchmark records the size it ran at. The phone
  check stays on `docs/release-candidate.md`.
- **Owner-only checks** go to `docs/release-candidate.md`: phone frame rate, feel and tuning values, and the people
  round.
- **Hub**: the hub moves to x = −760, outside Park City's 620-stud scenery bound, while Park City is active.
