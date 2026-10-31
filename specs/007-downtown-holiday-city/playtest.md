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

## Not yet done
- 12-spawn bot runs, sightlines, shortcuts, kerbs, Car Park ramp, screen captures (T015).
- Theme switch playtest (T023).
- 12-ball 640x360 fps sampling (T034).
