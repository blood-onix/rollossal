# Playtest log: 007 Downtown Holiday City

Draft, round 2. Only the smoke check below has been run; T015, T023, T034 and T036 are still open.

## Smoke check (Studio, Play, Server)
- Rojo sync probe: Downtown, Worlds and Config byte sizes matched the repo.
- World built in Play: 1,554 parts in Workspace (under the 1,890 grey-box budget and the 2,000 limit).
- Console: no script errors. Only the known DataStore and `rbxassetid://203785492` Studio lines.

## Rollback check (T036, Studio Edit)
- Cloned `ReplicatedStorage.Shared` with `Config.Flags` edited and required the clone's `Worlds`:
  Downtown on gives 74 objects; Downtown off with Snow Village on gives 64; both off gives the 4-object grey-box room.
- The unit side is `tests/unit/Config.test.luau` ("rolling Downtown back ...").

## Pace tuning (T009/T014), round 2
- All Downtown pace windows pass in `city`. In `winter`, spawn slot 3 reaches D 30 at about 141 s (window 145 to 185 s). Sweeps of
  `growthK`, slot 3 walk counts, strip counts, zone seeds, spawn x and the winter cart/reindeer positions found no passing combination
  (the model is chaotic and `city` D 80 has under 1 s of slack). Still open.

## Round 3: pace search and 12-bot run
- Pace (T009/T014): `Pace.test` fails one case: `winter` slots 2 and 3 reach D 30 at about 137 s (window 145 to 185 s). Everything else passes
  (`city` all slots; `winter` all other slots; 480 pass, 1 fail in `scripts/check.sh`). This round: removing or moving each winter overlay group
  (snow piles, carts, reindeer, stalls, pots, sleds, ploughs), a 36-point snow-pile position/seed sweep, a 36-point cart-position sweep and a
  1,200-step random hill-climb over every `TUNE` count found no passing setting. Carts and snow piles drive the early finish; other groups
  change nothing. Next lever needs a decision: widen the winter D 30 window, or let a theme override `growthK`.
- Studio synced (probe sizes match the repo). `BotRun` (12 playerless bots, 240 s, Play, `winter`): 1,520 parts (< 1,890). All 12 first
  pickups under 0.25 s. Final diameters 10.9 to 65.2; 3 bots reached Tier 4. The simple steering bot is far weaker than the
  greedy-eater model, so this shows the world builds and stays under budget, not that pacing is met. Tier 3 share left 0.17 at 240 s.
- Still open for T015: sightlines, shortcuts, kerbs, Car Park ramp checks and captures.

## Round 3 (final): pace fix, Jest, theme and performance checks
- **Pace (T009/T014)**: no `growthK` override alone worked (winter swept 1.5 to 2.2). The lever that did: winter `cocoa_cart` 7.5 -> 6.5 studs (the
  Plaza carts pulled D 30 under 145 s on the north-west spawns), with the theme-scoped `growthK` hook kept (`themeBindings.winter.growthK = 1.95`,
  read by `Worlds` and `Pace.test`). `art/scripts/budgets.json` regenerated. Winter D 30 at 145 to 153 s, D 80 by 234 s; `city` unchanged.
  `scripts/check.sh` exits 0 (481 unit tests).
- **Jest (T037)**: `ServerStorage.Tests.runner` in Studio: 150 tests, 0 failed, 3 skipped. Fixed stale Snow Village assumptions in the specs:
  the Absorb growth literal (now `Growth.growDiameter` at the world's k), the Booster refresh case (Downtown has one magnet, so it uses the two dash
  markers) and the 3 DataService tier-reward cases (skipped while the active world has no tier rewards, per D6).
- **Theme playtest (T023)**, Play, `winter`: 2 `mega_tree`, 1 `ice_rink`, 8 `market_stall`, 6 `sleigh`; `Lighting.ClockTime` 16.5; client
  `ThemeWeather` emitter on (rate 10); `ThemeMusic` playing and loaded; book pages `downtown.winter` and `downtown.city`. `Worlds.forTheme("city")`
  resolves 1,224 placements with `giant_duck`, `paddling_pool`, no tree. The data-only switch and back is covered by `ThemeSwitch.spec` (passes).
  Console clean apart from the known DataStore and `rbxassetid://203785492` lines. No screen captures saved (`screen_capture` returns the image only).
- **Performance (T034)**: 12 playerless bots plus the local ball (13 balls), 1,566 parts at start (1,520 after the bots ran), 60 s of client Heartbeat
  samples: 59 or 60 fps in every second, none at 15 fps (no throttled seconds). The viewport could not be set to 640 x 360 through MCP, so this is
  the default Studio viewport. Console showed `Displacement`/`Vertical violation` lines from the playerless bots (fake user ids 7000xx) and from the
  injected client bot, not from a real player path.
- **Grey-box bot (T015, still open)**: a client bot with no jump got stuck at D 2.0 from about 40 s (the 1.2 stud kerbs need a jump at D 2), so the
  D 5/12/30/80 times were not measured. Geometry read from the built place: kerbs 1.2 studs tall; Car Park decks rise 2 studs per ramp over 12 studs
  (0 -> 2 -> 4 -> 6), climbable. Sightlines, shortcuts and captures not done.

## Round 3 (pass 2): grey-box geometry checks (T015, partial)
Studio synced (Downtown, Config, Themes, WorldBuilder byte sizes match), Play, `winter`, read on `Server`.
- **Sightlines**: 9 rays per landmark from each of the 12 spawns at eye height 6 to `dt_h_glass_tower` (z -262) and `dt_h_ferris_wheel`
  (z 262). Every spawn reaches at least one landmark with 5/9 or more rays unobstructed: south spawns see the Glass Tower (9/9 for slots
  1 to 6 and 12), north spawns the Ferris Wheel (slots 7 to 11 at 6/9 to 9/9; slots 9 and 10 see the tower 0/9 but the wheel 6/9).
- **Kerbs**: 12 doorstep kerbs, all 1.2 studs tall. Tap apex at D 2 is `max(0.6*2, 1.6)` = 1.6 studs (clears 1.2); no jump means stuck, as
  the earlier bot found.
- **Car Park**: ramp slabs 2 studs thick at y 0 to 2, 2 to 4, 4 to 6 (decks 1 to 3); each rise is 2 studs. Held apex at D 2 is
  `max(0.85*2, 1.6*0.85/0.6)` = 2.27 studs (clears 2.0); a tap clears it from D 3.4. The ramps are stepped slabs, not inclined planes.
- **Storm-drain tunnel** (T040, fixed): the 6-stud chamber (z -8 to 8, walls at x -103.5 and -96.5) keeps golden spot 3's 6 x 6
  footprint clear; each 6-stud mouth has walls at x -102.8 and -97.2, so the entrance gap is 4.6 studs. A D 5 or larger ball cannot enter;
  Tier 1-2 (D < 5) can. `scripts/check.sh`: 481 passed, 0 failed.
- **Tunnel sphere cast in Play (Server, 2026-10-31)**: a sphere swept along x = -100 from z -30 to 30 at ground level: D 4.5 clear
  (passes the whole tunnel, so golden spot 3 is reachable); D 4.9, 5 and 6 hit a mouth wall at z -14 (blocked). Studio matched the repo
  (sync probe: Downtown 48,855 bytes).
- Not done: a driven bot with jumping (D 5/12/30/80 times), shortcut traversal, and capture files (`screen_capture` returns the image only
  and cannot save into `captures/`). T015 and T039 stay open.

## Round 4: jumping bot attempt (T015, still open)
Studio synced (Downtown 48,855 bytes), Play, `winter`, client bot (velocity steering toward the nearest absorbable cube, vertical kick when blocked).
- First bot (kick whenever slow): first pickup at 0.9 s, D 4.6 by about 60 s, then no growth for 60 s. The ball hovered at y 5.5 to 6.2 over a
  cube 0.08 studs away, with `AssemblyLinearVelocity.Y` about -8 but no change in position (bot artefact: it re-kicked every frame over the target).
- Second bot (kick only when blocked and the target is farther than D): no growth in 60 s, ball still frozen mid-air at y about 5.5 to 6.2 with Heartbeat
  running at 60 Hz. Not diagnosed; no `Displacement` or `Vertical violation` console lines. D 12/30/80 times were not measured.
- T015 and T039 stay open. Needs a better driver (use the game's own jump input via `user_keyboard_input` Space, not velocity writes) and a way to
  save captures (`screen_capture` returns the image only).

## Round 5: real jump input (T015, still open)
Studio synced (8 key scripts match), Play, `winter`. The ball started at a doorstep (y 1.63, stuck behind a kerb).
- `user_keyboard_input` Space held 300 ms: ball apex y 3.96 (rise of about 2.3 studs), so the game's own jump input works and clears a
  1.2-stud kerb. This replaces the velocity-write bot of round 4 as the driver.
- Not done: the full driven run with jump input to D 5/12/30/80 (needs a steering loop plus timed Space presses over a 240 s run),
  shortcut traversal, Car Park climb in play, and capture files. T015 and T039 stay open.

## Round 6: velocity-steered bot with real Space presses (T015, still open)
Studio synced (8 key scripts match), Play, `winter`, spawn slot at about (-250, -135). Client Heartbeat bot steers horizontally only (Y velocity
left to the game) toward the nearest absorbable cube; jumps are real `user_keyboard_input` Space presses every 1.1 s (`VirtualInputManager`
is not callable from `execute_luau`: lacks RobloxScript capability).
- First pickup at 0.08 s. D 2.2 at 11 s, then D 2.0 and the ball at the same spot (-249.9, 2.8, -135.9) at 58 s: it hops in place at the
  doorstep. The nearest small cubes (`dt_z_door_01_a_008`, 2.3 studs; `_003`, 3.3 studs) are not reachable in a straight line, so the
  straight-line steering never leaves the doorstep. D 5/12/30/80 times not measured; no 240 s run completed.
- The bot, not the build, is the limit: it has no path-finding. T015 needs a driver with obstacle avoidance (or `character_navigation`),
  plus a way to save captures. Shortcut traversal and captures not done.
- T035: the budgets `{ 500, 700, 1500, 3500, 5000 }` are in `src/shared/Config.luau` (`Budgets.meshTriangles`). Its other part (owner sign-off,
  final captures) needs the owner and the uploaded meshes (T032/T033). T039 depends on T015 and the owner. All three stay open.

## Round 7: obstacle-avoiding bot with real Space press (T015, still open)
Studio synced (Downtown, Config, Themes, WorldBuilder, RunManager, Jump match), Play, `winter`, spawn at about (-250, -135). Client Heartbeat bot:
horizontal velocity toward the nearest absorbable cube within 60 studs, 13 raycast headings (15 degree steps) for obstacle avoidance, a random
wander after 3 s without 1.5 studs of movement; one real `user_keyboard_input` Space press at the start.
- The bot left the doorstep (the earlier rounds stalled there): first growth past D 2.5 at 1.5 s, D 4.3 at 8 s, D 4.9 at about 70 s.
- D 5 at 87.2 s; D 5.6 at about 250 s (240 s run ended, Play was still running the bot). D 12, 30 and 80 were **not reached**. The bot
  shuttles between nearby cubes and walls (nearest-cube choice has no memory of blocked targets), so this is a bot limit, not evidence
  about the pace windows, which the `Pace` model covers for all 12 spawns in both themes.
- Parts under `World`: 1,508 (under 1,890). Console: only the known DataStore/ProfileStore and `rbxassetid://203785492` lines; no
  `Displacement` or `Vertical violation` lines.
- Not done: D 12/30/80 times, spawns other than slot at (-250, -135), shortcut traversal and Car Park climb in play, capture files
  (`screen_capture` cannot save into `captures/`). Geometry for kerbs, Car Park and tunnel is recorded above from the built place.
- T035 final metrics: the budgets `500 / 700 / 1,500 / 3,500 / 5,000` are locked in `Config.luau`; performance numbers are in Round 3
  (59 to 60 fps, 1,566 parts at start). Captures, meshes (T032/T033) and owner sign-off remain with the owner.
- T015, T035 and T039 stay open.

## Round 8: reconciliation (T015, T039 still open)
`scripts/check.sh` passes (all checks). No new Studio driver run this round: rounds 4 to 7 showed that a no-memory bot cannot reach D 12/30/80,
and no new routing tool exists (the MCP `character_navigation` drives characters, not the ball; `screen_capture` cannot save into `captures/`).
Recorded geometry (kerbs, Car Park ramps, tunnel sphere cast), sightlines, part count (1,508 under 1,890) and console cleanliness stand.
- T015 and T039 stay unchecked: a bot with path memory (D 12/30/80 timings across 12 spawns, shortcut and ramp traversal in Play) and capture
  files are still missing. Owner items unchanged: T016, T032, T033, T035.

## Round 9: path-memory bot (T015, T039 still open)
Studio synced (8 key scripts match), Play, spawn at about (-250, -134). Client Heartbeat bot with a visited-cell penalty (6-stud cells), a 20 s
block list for targets it could not reach, 13 raycast headings and a random wander after 2.5 s without movement. No Space presses.
- D 2.7 at 10 s, 4.8 at 30 s, 5.6 at 60 s (best), 5.1 at 90 s, 5.0 at 120 s, 4.4 at 150 s, 4.3 at 160 s (run stopped there). D fell after 60 s,
  so something shrank or reset the ball (not diagnosed: hazards or knock-off are the likely cause, no console check this round).
- D 12, 30 and 80 were not reached; only one of the 12 spawn slots was driven. Parts under `World`: 1,508 (under 1,890).
- Result: a bot with path memory still stalls near D 5, and the MCP cannot save captures. T015 and T039 stay unchecked.

## Round 10: final reconciliation (T015, T039 still open)
`scripts/check.sh` passes. No new Studio run: rounds 4 to 9 showed that velocity-steered bots (with raycast avoidance, visited-cell memory and
block lists) stall near D 5 on the winter spawn, and the MCP has no ball-routing driver or capture-to-file path. Nothing new was measured.
- T015 stays open: D 12/30/80 across the 12 spawns, shortcut and Car Park climb in Play, capture files. T039 depends on it.
- Needs the owner (T016, T032, T033, T035), or a human-played run to cover the D 12/30/80 timings.

## Converge round 10: waypoint-spine bot and tunnel attempt (T015, T039 still open)
`scripts/check.sh` passes (481 unit tests, all guards). Studio synced (88 scripts, `mismatches = {}`). Play, `winter`, spawn slot 1, fresh run.
- **Run A (waypoint spine)**: a 34-waypoint route (doorstep → crumbs → fill_d → Park east → fill_a → Plaza west gate → Plaza → east gate → fill units → Market centre → Car Park climb), cube targeting filtered to absorbable sizes only (`Size <= 0.4 * Diameter`), fragments of shrink/teleport logging, real `Space` presses every ~1 s.
  The ball left the doorstep, grew D 2.33 → 2.75 by t 13 s, then the sweeper knocked it twice (D shrank to 2.54 — `KnockOff` loses eaten stuck objects), and it drove the route to waypoint 11 of 34 (Park west edge, about (-137, -47)) with zero respawns, staying under D 2.75. Parts under `Workspace`: 1,598 with 1,374 cubes; console clean apart from the known DataStore/ProfileStore and `rbxassetid://203785492` Studio lines. D 5/12/30/80 were not reached: the physical bot eats at a fraction of the greedy-eater model the `Pace` ladder is solved with, confirming rounds 4-9.
- **Run B (tunnel)**: pure-waypoint, no cube pull, 13-heading raycast dodging toward the storm-drain tunnel entry (-100, -30). The bot reached waypoint 7 (-112, -50) in 9.5 s — past the doorstep bands and the fill_e lane — then jammed against unmapped solid geometry at (-134, -81) for the rest of the run (velocity writes zeroed by contact; no tunnel entry).
- After the 240 s run ends the ball anchors in place (matches earlier rounds) — reads after that measure the finished run, not live play.
- Conclusion after nine bot attempts across rounds 4-10 plus these two: the Studio MCP has no ball routing (`character_navigation` drives characters, not balls), and `screen_capture` returns images only and cannot save into `captures/`. The D 12/30/80 timings, live shortcut and Car Park traversals, and capture files therefore need a human-played session; geometry (kerbs 1.2, ramps 2.0 rise, tunnel gap 4.6, sphere casts), sightlines (12/12), parts (< 1,890), console and the world-build checks all stand from rounds 3-10.

## Owner play: one full round (T015 partial, T016 not signed)
Reported by the owner after the size-meter fix, one full 240 s round, `winter`, one spawn (not noted), Studio in front (unthrottled).
- D 12 at about 120 s (2 minutes left). Final size D 30 at 240 s, so 1 star (thresholds 20 / 45 / 80); D 80 not reached.
- Against the pace windows (model, optimal eater): Tier 3 (D 12) 70 to 110 s, so about 10 s late; Tier 4 (D 30) 145 to 185 s, so at least 55 s late.
  A first human run is expected to trail the greedy-eater model; this is one run on one spawn, not a pass or a fail of the windows.
- Not measured: D 5 time, the other 11 spawns, shortcuts, Car Park ramp, captures. The HUD size meter was hidden behind the Roblox top bar
  during this run (fixed in dbfef42), which may have cost some pace.
- **Owner decision**: pace polish waits for the real map. This build is a playground, the owner is not a top player, and the numbers depend on
  the final layout, so `growthK` and the windows stay as they are for now.

## Mesh import (T032, T033)
The owner imported the 99 new `dt_*` FBX meshes through the 3D Importer. Their `MeshId`s were read from Studio and recorded in `Assets.meshes`
(`dt_` plus the object id). `scripts/check.sh` passes (481 unit tests), also with `REQUIRE_ASSET_IDS=1`. The 65 Snow Village meshes kept their
earlier ids. Not yet looked at in Play: mesh appearance, single material and atlas UVs on screen (T035).

## Open items
- T015: one owner round is logged above (D 12 at ~120 s, D 30 at 240 s). Still needed: D 5/12/30/80 timings across the 12 spawns, live shortcut and Car Park climb, and capture files; all static geometry already verified in rounds 3-10.
- T039 depends on T015. Owner items: T016, T032, T033, T035 (captures, sign-off).
