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

## Not run
- Everything the owner decides: gate 6 below.

## Gate 6: owner approval of the shots and the build

Shots: `specs/012-park-city-map/shots/` (11 PNGs and `shots-manifest.json`, offline Blender render of the world data).

- [ ] Owner approval of the fixed shots: _pending_
- [ ] Owner has played the build: _pending_
