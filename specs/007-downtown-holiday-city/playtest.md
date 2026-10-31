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
- **Storm-drain tunnel**: walls at x -103.5 and -96.5, 1 stud thick, so the inner gap is 6.0 studs (a D 6 ball just fits or touches; the
  spec wants D 6 kept out, so this is marginal; not changed).
- Not done: a driven bot with jumping (D 5/12/30/80 times), shortcut traversal, and capture files (`screen_capture` returns the image only
  and cannot save into `captures/`). T015 and T039 stay open.

## Not yet done
- T015 bot run with jumping, sightline and shortcut checks, captures; T039 follows it.
- Owner items: T016, T032, T033, T035.
