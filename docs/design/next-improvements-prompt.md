# Prompt: the big map and what the game still lacks

Written 2026-11-12 after the owner's play sessions on Park City (1,000 × 1,000 studs, 12 balls). Paste the block
into a new session. It is a brief, not a decision record: the map size and the district list are proposals until
the owner approves them.

```text
Rollossal: start the big map, and close the gaps the owner found by playing. Read AGENTS.md, the constitution,
docs/design/README.md, docs/design/09-park-city-level.md and docs/release-candidate.md first.

WHERE WE ARE
- The game plays on Park City: 1,000 x 1,000 studs, 12 balls (1 player + 11 bots), Classic and Feast modes,
  launch ramps, catapults, crown zone, golden drop, Giant Oak shake, food flow.
- The owner's verdict: this map is a test map. It is too small for 12 balls, a ball at top speed (32 studs/s)
  crosses it in half a minute, and growth to "skyscraper" size has nowhere to happen. No more work goes into
  Park City as a final map. Its working pieces (rules, toys, events, scene generator, settle pass, dress table)
  move to the new map.
- No design document describes a bigger map: the largest one on record is Park City itself. The big map is a new
  design, and its size is the first decision.

PART 1 - THE BIG MAP (most of the effort)
Goal: one world where a ball goes from a bottle cap to eating towers in 4 minutes, with room for 12 balls to
choose different routes and still meet.

1. Size: DECIDED by the owner on 2026-11-12: 2,400 x 2,400 studs playable. The district proposal is
   docs/design/10-big-city-level.md with the overview map docs/design/maps/big-city.svg (from
   scripts/big_city_layout.py); the owner has not approved the districts yet. Still to show: studs per ball, crossing times at D 2, D 10, D 40, D 100, object counts against the
   budgets in docs/design/05-roblox-limits.md (today 1,500 Part objects and 5,200 light objects; a bigger map
   needs streaming and culling numbers, not a bigger budget by wish).
2. Propose the districts as one page with a rendered overview map: what each district is, which ball sizes it
   feeds, what is unique to do there. Rules learnt on Park City:
   - Every large set piece must be worth visiting at every ball size, or be small. The first Giant Oak took
     60 x 60 studs and only a D 2-8 ball could use it. Hedge maze, car park decks and Roof Run have the same
     flaw; do not copy them as they are.
   - Nothing that throws, lifts or boosts a ball may trigger by passing near it. The trigger is a marked spot.
   - No toy on a road or path. No two big objects in the same place (keep the settle pass and 0 overlaps).
   - A boost the player cannot see the value of is noise. Fewer, clearer, stronger.
   - Park City becomes one district of the big map (the starting park), not the whole world.
3. Stage it (constitution I and VII): stage 1 is a grey box of the whole big map with roads, ground, district
   borders, spawns and thin food that the owner can roll across in Studio. Each later stage fills one district
   and stays playable. Gate 6 applies: the owner approves rendered maps first, then the played build.
4. The layout stays one script and one JSON; world modules and pictures are generated. Generalise
   scripts/park_city_layout.py rather than writing a second copy.

PART 2 - MISSING ASSETS
specs/014-park-city-art/coverage.md is the truth: 98 of 231 object kinds are stand-in boxes or balls
(1,924 placements). Build order, biggest eyesore first:
- Landmarks and buildings: car park, station hall, the eight Roof Run buildings, windmill, boathouse, bouncy
  castle, hoardings (28).
- Mid-size park and site objects: hammock, camping tent, pedalo, rowing boat, canoe, cement mixer, pipe bundle,
  luggage trolley, solar panel, AC unit, chimney stack, roundabout, umpire chair, pigeon coop.
- High-count small food: hedge piece (480), napkin, petal, daisy, breadcrumb, strawberry, pea, ladybird, marble,
  small mushroom, cabbage, giant chess piece, log, helmet, toadstool, pumpkin, cheese wheel, watermelon.
- Toys and events are plain parts: catapult, launch ramps, lifts and pipes, crown zone, golden orb, meteor.
  Each needs a real model and a clear "use me here" marker.
- The Giant Oak is the kit oak scaled 4 x; it needs its own mesh with a trunk a ball can circle.
Blender only through the MCP. Budgets and style: docs/design/05-roblox-limits.md, 08-style-bible.md.

PART 3 - MISSING SOUNDS
Assets.luau has five engine placeholder clips (pickup, tier unlock, bump, bell, land) and two music tracks
(winter, city). Nothing else makes a sound. Needed:
- Eating: pitch that rises with a combo, a heavier sound per tier, a big one for landmarks.
- Ball: rolling loop that deepens with size, jump, landing by size.
- Toys: catapult wind-up and release, ramp launch, lift, pipe, booster pickup per kind.
- Events: crown zone opens and closes, golden orb falling and taken, oak shake, meteor warning and hit.
- Feast: the 1:00 "feast begins" sting, eating a rival, being eaten, a rival close behind you.
- Round: countdown, last 10 seconds, results, Roll Again.
- Music for spring, autumn, toon and neon themes (empty today).
Every id goes in Assets.luau only (constitution XI). Preload; check IsLoaded and TimeLength in Play.

PART 4 - GAMEPLAY GAPS STILL OPEN
- Bots do not go for the oak shake, the crown zone or the golden orb, and do not flee in Feast the way a
  player would.
- Roll Again: the reset of objects stuck to the ball was changed but never verified in Studio.
- Rails are switched off (Config.toyRails = false) because nobody understood them; decide: redesign or delete.
- The gnome army field: keep as a jackpot, or cut. Owner asked "why", no decision.
- Feast needs feedback: who can eat me, who can I eat, at a glance and by sound.
- No tutorial moment: the first 10 seconds do not teach roll, eat, grow.
- Config.Slice, Flags.DebugSize, Debug.spawnSlot and LoadStringEnabled are playtest settings and must be off
  before anything is published.

HOW TO WORK
- Fix in batches, then one long playtest. No small Studio test after every change.
- The owner plays in the same Studio: never run a ball driver or a playtest while they may be playing, never
  touch their screen, mute every agent playtest.
- Judge by playing the build, not by tests or renders. Tests are the floor.
- Start by answering Part 1 step 1 and 2 on one page and wait for the owner's answer on size and districts.
  Parts 2 and 3 can run alongside, as separate sessions, once the district list says which objects survive.
```
