# Playtest record: Park City map (012)

Agent runs through the Studio MCP on 2026-11-04 (one agent in Studio at a time; this run held the claim). Studio had
the repo's code (sync probe `mismatches = {}`). The flags were switched on in the working copy for each run and
switched back off afterwards.

## Stage A: Downtown with `Flags.ReadableRules` (T016, partly run)

- Server: ball D 1, absorb mode `bulk`, six tiers. OK.
- Heap fit (client, a ball set to D 10 with stuck entries named by hand): items were scaled to at most 0.45 D (a 9.5-stud
  lamp-type object became 4.5 long) and the farthest corner was 5.42 half-extent against the 6.25 allowed (0.625 D). OK.
- **Finding (Downtown, not fixed here):** the Downtown spawn at D 1 is boxed in by its own Tier 2 doorstep objects
  (sizes 1.0 to 1.2, solid at D 1). The driver could not roll out in 30 s. Downtown with `ReadableRules` needs a
  doorstep pass if the owner wants to play Stage A there. Park City is unaffected.
- Not run: eating a violin-like object, the bump thud, the bob and wobble cues by eye, the `BallService` spec case for
  the speed cap (it ran green in the flags-off Jest run below). T016 stays open.

### Round 2 re-run (T046, T047), Downtown with `ReadableRules` and `DebugSize` on, put back off afterwards

- T046 doorstep fix: `Rules/Doorstep.clear` drops spawn-slot objects within 7 studs of a spawn that need more than D 1
  (`Downtown.readableRules.doorstepClearRadius`); flags-off data untouched. Lune check (`Downtown.test`, "open way
  out for a D 1 ball", both themes, all 12 spawns) fails with radius 0 and passes with 7. In Play the D 1 ball rolled
  29 studs out of its spawn in 10 s and grew from 1 to 1.63 (before: boxed in for 30 s).
- Violin-like object: at D 6 the ball ate an `acoustic_guitar` (3 x 1.1 x 0.4, bulk 1.10); the old rule needed D 7.5.
  The server accepted it (Stuck entry `#9`, the object Taken).
- Bump: at D 6 rolling into a wheelie bin (3.5, too big) knocked the one stuck object off; the diameter fell
  6.02 to 5.59. A second hit within the 1 s cooldown changed nothing, but the stuck list was empty, so that part is
  inconclusive.
- No text banner: a capture mid-play shows only the Size HUD, stars and the timer.
- **Not verified:** the bob and new-tier wobble cues, and the thud sound, need eyes and ears on a live ball. They stay
  with the owner (release-candidate). T047 stays open for them. Driving the ball across the map tripped the server
  displacement check once (the ball was returned to a spawn); the size tool only offers 1, 3, 6, 15, 35 and 80.

### Round 3 (T047): cues measured numerically, Downtown with `ReadableRules` and `DebugSize` on, put back off afterwards

Client `execute_luau` sampled part CFrames around the live ball in Play (no eyes needed for these lines).

- Bob (FR-015), D 1 and D 6: every edible object within 4 D that can be touched moved (5 of 5 at D 1; all 8 touchable
  edible objects of the nearest 27 at D 6, up to 0.26 studs). The 19 that did not move have `CanTouch` false (doorstep
  objects dropped by `Doorstep.clear`), which the cue skips by design. Too-big objects near the ball (2 at D 6): 0 moved.
- Reduce motion: with the `ReduceMotion` attribute on, the 5 bobbing objects at D 1 stopped (0 moved in 3 s). With
  the attribute back off the cue resumed. At D 15 with reduce on, a tier 5 and tier 4 `TierUnlocked` produced no wobble
  (the one part that moved, `dt_b1_0_ib_1`, also moves with no cue and no reduce motion: it is a part another script moves).
- New-tier wobble: a `TierUnlocked` for tier 5 sent from the server wobbled 8 of 8 tier 5 objects within 6 D of the ball
  (roll above 0.02 rad) and 0 of the 15 objects of tiers 3, 4 and 6. A tier 2 event found no tier 2 objects near.
  (`DebugSize` does not send `TierUnlocked`, so the event was sent by hand through the real remote.)
- Bump cooldown with a non-empty stuck list (FR-017): 7 objects stuck at D 6.8, ball held against `dt_b1_3_ia_2`
  (a too-big building). Knocks: 10 to 7 at 1.80 s, 7 to 4 at 2.83 s, 4 to 1 at 3.82 s, 1 to 0 at 4.85 s. Each is 3
  objects (`knockOffCount`) and they are 0.99 to 1.03 s apart (`bumpCooldown` 1.0) despite continuous rubbing.
  The diameter fell on each knock. This closes the inconclusive part of round 2.
- No text banner showed (round 2 capture; the Hud code path is gated by the flag).
- **Still not verified:** the thud sound and the camera nudge by ear and eye. They stay with the owner
  (release-candidate).

## Stage B and C: Park City (T026, T035, T036)

- T026: world present at its layout coordinates. 91 blocks (no missing id), 1,392 placements before Stage C, all 12 spawns,
  108 placeholder Parts tagged `Placeholder` for 67 placeholder records (every id found), 0 mismatched positions.
- T035 (Stage C): server parts 1,379 with one ball, 0 server Parts with `Tier <= 2`. Client `LightField` pool 109 to 206
  (cap 450). A far claim (`Absorb:FireServer("L3000")`) left the diameter unchanged. A bot ball grew from 1 to 1.58 in 40 s;
  the first pickup came 0.17 s after start. Jest `AbsorbServiceLight` (5) and `WorldSpawnerLight` (4) pass.
  Not run: a second client seeing a taken object disappear (one Studio client only). The delta path is covered by the
  server outbox spec.
- Size tool (`Flags.DebugSize`): `DebugSize:FireServer(15)` set the ball to 15.3; the heap stayed inside the box
  (9.52 against 9.58 allowed).
- T036 (G6): 12 balls (the player and 11 bots, `ParkHeavyScene`), 60 s sampled, viewport 1301 x 940:
  **0 throttled seconds; every second at 55.8 fps or more (average 59.9)**. Server parts 1,390. The bots only grew to
  1.4 to 3.6 in 75 s, so the stuck-visual load at larger sizes is lighter than a real run: repeat on the release candidate.
- Console read (G7, T042): no errors or warnings from game scripts. The `ContentId rbxassetid://203785492` lines are
  Studio's own (not in the repo).

## Regression (T043)

- `scripts/check.sh`: passes (StyLua, Selene, luau-lsp strict, Lune 544 tests, layout and world data in sync).
- Jest with all flags off, in Studio: 154 passed, 12 skipped (the light specs), 0 failed.

## Route checks (T027)

Server-side `Workspace:Spherecast` in Play with `Flags.ParkCity` on, against the built static geometry (141 parts;
kerbs and the 0.05 thick spoke floor slabs are floor, not obstacles). Ball centre 0.5 above the ground.

- Park Loop, 4 sides at inset 290, D 3, 6 and 15: clear.
- Spokes N, E, S, W through the gates (from 330 out to 20 in), D 3, 6 and 15: clear.
- Roof Run, centre line over each of the 8 roofs, D 6 and 10: clear (the gaps themselves are jump physics, not run here).
- Maze, all 118 open cell-to-cell edges, D 2.5, 3 and 4: none blocked. Caveat: the hedge pieces are light objects (client
  `LightField`), not server parts, so a server cast cannot see them (a control cast through a wall cell also hit nothing).
  This shows that no static geometry sits in the corridors; the hedge walls themselves are for the owner to judge by playing.
- Not run (round 1): the car park ramps and the jump gaps by driving the ball; the size tool was exercised in T036 (`DebugSize` to 15).
- Flags were switched on in the working copy for the run and put back to `false` afterwards.

## Route checks, round 2 (T048)

`Flags.ParkCity` on, server `Spherecast` against `Workspace.World.Geometry` (floors, ramps, decks and kerbs excluded;
objects and placeholders excluded, they are checked by the absorb rule). Ball centre 0.6 above the surface.

- D 1 doorstep (spawn 1) to the Park Loop: clear along the acorn trail, round the glade log and the oak (the straight
  line is blocked by the oak trunk and the glade log, by design of the trail).
- D 2 into the root hollow: clear through the south mouth. D 4 stopped at the mouth (hits `root_hollow_s2`); D 3 also
  stops, because the mouth is exactly 3 wide. FR-007 holds.
- D 12 car park open ramp to the top deck (y 24), on to deck 3: clear.
- D 17 hoardings: `hoarding` needs D 16.6; `canEat` is false at D 16 and true at D 17. OK.
- D 25 Spoke N from the gate (z -330) to the Plaza centre: clear. A radius 12.5 sphere reaches the first Spoke object
  (an ordinary part).
- **D 3 oak spiral: FAILS.** The 32 ramp pieces cast clear, but the ramp ends at x -348.8 and the tree house deck
  (-382 to -358, y 22 to 23) is 9 studs away. The deck also lies inside both the 24 x 24 x 40 `oak_trunk` block and the
  30 x 30 x 40 `giant_oak` object (needs D 66, collidable). So the deck cannot be reached or stood on. The fix is a
  layout change (move or shrink the trunk and oak footprint, extend the deck to the ramp end, move the picnic scene),
  which touches an approved map, so it waits for the owner. T048 stays open for this.

## Round 4: maze reward and exit (owner request)

Owner feedback: walls cost size, the maze centre paid too little. Change (layout script, regenerated): the centre is now a
Gnome Feast of 42 light pieces in a food ladder (9 tennis balls up to cupcakes and a toadstool). First version (51 pieces, ended
near D 5.6) stalled at D 1.9 for the owner, who missed some pieces, and was also too big a jump, so it was rebuilt: a greedy
eater from D 1 reaches D 3.35 with every piece, 2.7 to 3.0 with 70% of them. Row 6 col 13 became a wall, which seals the east lane off, and a ramp
(y 0 to 4) plus a bridge over the east wall (4 stud drop) lead out of the maze. In Play, server `Spherecast` along the lane
from the centre to the drop: clear at D 1, 3, 5 and 6. Light budget 3,489 of 3,500. `scripts/check.sh` passes (545).
Not played by eye: whether the feast and the exit feel right. Wall bump cost is unchanged.

Round 4b (owner screenshots): the owner's ball stayed at D 1.0 to 1.9 in the centre, boxed in by the mixed-size pile. The
feast was rebuilt as four rings round the centre (smallest outside: tennis balls, then acorns, grapes and cups, then hats and
small kitchen things, then ducks, apples and cupcakes). In Play a bot ball from spawn 11 drove the maze route into the room at
D 1.00, chased the nearest edible piece and ended at D 3.36 in about 8 s (greedy-eater simulation: 3.35). Studio-only debug
settings added in `Config.Debug`: `spawnSlot` (1 to 12 forces a spawn) and `quietAudio` (music off, effects cap 0.2);
both are on the publish checklist and are set to 11 and true in the working copy for now.

Round 4c (owner: "how did I lose everything?"): bumping a hedge piece knocked off 3 stuck objects per second. Hedge pieces
are now soft obstacles (`Config.softObstacles`, checked in `AbsorbService.tryBump`): the ball still bounces, nothing is knocked
off. In Play at D 3 with 25 stuck objects, 18 s of driving into the maze's outer wall: with the exemption D 3.00 and 25 stuck
throughout; with it switched off (control) D 2.80 and 0 stuck. Buildings, lamp posts and other too-big objects still knock off.

Round 4d (owner: "touched a big cube at about D 5.6 and became 1.0", also at the maze centre when small): a real bug. Growth
on a pickup adds `1.6 * bulk^3`, but a knock-off took back `1.6 * size^3` of each popped piece, with `size` the LONGEST side.
A long thin piece (a 6 stud plank of bulk 1.1) gives 1.6 * 1.3 and loses 1.6 * 216. Three such pieces take D 5.6 to the floor,
and so do three trainers or violins in the maze feast at D 2 to 3. Fixed: each stuck entry now stores `gain` (the bulk the pickup
added, 0 under the garnish) and `KnockOff` shrinks by it; size mode (Downtown with flags off) is unchanged. Covered by a Lune
round-trip test (`Growth.test`); not reproduced in live Play (needs a stack of long pieces), so the owner should repeat the
"big cube at D 5 or 6" case.

Shots re-rendered 2026-11-06 (Blender, world data at 5d7b827 plus the uncommitted maze work, 4778 boxes) so `hedge_maze.png` and
`overview.png` show the Gnome Feast ring and the maze exit ramp. The other nine shots are unchanged in content.

## Round 5: owner feedback on the map (2026-11-06)

All changes are in `scripts/park_city_layout.py` (regenerated, 547 tests pass, layout/world in sync, 0 overlaps, 3475 light /
1139 part objects against 3500 / 1200). Checked in Studio Play with sphere probes, not by driving a ball.
- **Roof Run kicking:** the roof kits sat in the centre lane. Now the lane (z -237 to -227) holds only tier 2 food a D 4.3 ball
  eats; the big props (AC unit, water tank, pigeon coop, solar panel, dish, chimney) sit one per long edge. Also found and fixed:
  a street tree from the east ring-road kerb line stood on the delivery ramp (new `prune_trails` drops trail objects that land
  inside ramps, decks, roofs, water, maze walls, pads). Probe: D 8 ball along each roof's centre line, clear on roofs 1 to 7; roof 8
  meets only the billboard launch ramp, by design.
- **Cottages:** 6 houses a side (was 7) with a 16 stud lane between neighbours (was 3), and a food trail through each lane. Probe:
  D 12 ball down each lane, clear apart from the street kerb at the lane's street end.
- **Roof still bumping (owner, same day, D 6.6 on a roof):** a bug in the bump test, not in the layout. The client sent a bump
  for any too-big object within ball radius + longest side / 2 of the object's centre, and the server accepted the same loose
  range. For a roof building (18 x 26, flush with the roof) that is every ball on the roof, and for a 30 x 16 terrace house a
  ball 7 studs from the wall counted as touching it (the "cottages: cannot squeeze past" report). Now a bump needs real contact
  with the object's own box on both sides (`touchesBox` on the client, `nearBox` with `Config.bumpContactTolerance` 2.5 on the
  server), and the 8 `roof_building_k` objects are soft obstacles like the hedge pieces (no bump, no thud). Size mode (Downtown)
  is unchanged. Not driven live: moving the ball to a roof trips the anti-teleport check, so the owner's run is the check.
- **Road still empty (owner, same day):** cause found. `prune_trails` also deleted every trail object that landed on a gravel
  path (loops and the four paths to the city), and the four paths (200 long each) had almost nothing on them (1.5 to 3.5 objects
  per 100 studs). Pruning now leaves gravel alone, and each path to the city gets groups of Tier 2 and 3 street objects
  (`pathdrop_*`). To stay inside the light budget the loop trail is sparser (every 56 studs). Every spawn's ladder is now
  checked by an "ideal eater" (`_ideal_diameter`) while it is built, and rungs get extra food until the next rung is reachable.
  The pace model still shows spawns 11 and 12 near D 2 until about 150 s although the ideal eater climbs them: that is the
  greedy model's travel order, not a missing rung; the owner's live run is the check.
- **Road of objects:** the loop lines are now groups of 4 that wander across the road (spread 10, one group a stretch), so the road
  is neither a tidy line nor empty (owner: a first version with a clear strip down the middle left the road bare). Loop kit and
  kerb lines are scattered too. The spawn crumb trails stay straight on purpose (tutorial).
- **Empty space:** a second fill pass puts a Tier 3+ place within 38 studs of every park cell (60 places, bigger objects only).
- **Slow spawns, and the maze must not be needed (owner):** a "starter ladder" of 5 groups per spawn (6, 7, 6, 6, 4 items, 34 to
  134 studs out) climbs needs-D 1 to 4.5 on the way to the Park Loop. Pace model, median profile, D at 90 s / 120 s: spawn 11 was
  1.6 / 1.8, now 5.2 / 10.7; most spawns are 4 to 8 at 90 s. Median final size went from 25.8 to about 60: faster than before, so
  the star and growth tuning in the release-candidate list matters more. Spawn 12 (D 2 at 150 s) and spawn 6 are still slow.
  The model is chaotic: a small layout change moved spawn 11 from 4.9 to 1.8 once, so re-read the report after any layout edit.
- **Giant Oak (T048):** the tree house deck is now a landing at y 21 to 22 at the top of the root ramp, outside the trunk, with the
  picnic on it. Probe: a D 3 sphere walks the whole ramp (no blockers) and onto the deck; the picnic table sits near the ramp
  end, so the ball steers round it.
Shots re-rendered again (4711 boxes). Not done: driving a real ball over the roofs, the oak ramp and the cottage lanes; feel is
the owner's check.

## Not run
- Everything the owner decides: gate 6 below.
- Driving a real ball over the roofs, the oak ramp and the cottage lanes after the round 5 rework (the anti-teleport check
  respawns a moved ball); the owner's next play is the check. `Config.Debug` was put back to spawn 0 and loud audio.

## Gate 6: owner approval of the shots and the build

Shots: `specs/012-park-city-map/shots/` (11 PNGs and `shots-manifest.json`, offline Blender render of the world data).

- [ ] Owner approval of the fixed shots: _pending_
- [ ] Owner has played the build: played 2026-11-06, **not approved** (feedback below)

Owner feedback after playing (2026-11-06), in the owner's words, tidied:
- Knock-off collapse (D 5.6 to 1.0): not seen again. Maze: reachable and passable.
- Object placement: the road of objects needs no steering, you just roll along it.
- Roof Run: unusable, it kicked the ball off ("started to kick me").
- Cottage area (Terraces and Cottages, SW): odd, you cannot squeeze around without hitting a cottage.
- Lots of empty space between things.
These are map design problems, not code bugs. Gate 6 stays open until they are reworked and the owner approves a new round.
