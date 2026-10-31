# Playtest: 006 Mechanics Pass (jump, boosters, traps, ball bumps)

Agent-driven Studio run through the Studio MCP server, 2026-10-30, branch `006-jump-boosters-traps`, Snow Village,
grey box, one player. Expected values come from `research.md` R-01 to R-18.

**Owner sign-off (SC-004, Owner Approval Gate): GIVEN, 2026-10-30, with tuning deferred.** The owner played the
grey-box build in Studio (iPhone 6 Plus emulator) and said it was fine. Feel and numbers (jump height, booster
durations, trap strength, bump knock-back) are expected to be adjusted later: without the real map it is hard to
judge them now. The sign-off covers the mechanics as built, not their final values. Everything below the agent
measured; the verdict above is the owner's, recorded from their message in chat. Two-player bump feel was not
played (one player only).

## Jump (T020)

`Config.startDiameter` was set to 2, 5, 12, 30 and 70 in turn (reverted afterwards) so the live server session
carried that diameter. Rise of the ball's bottom, tap and held (button down 0.4 s), sampled every Heartbeat:

| D | tap (target) | held (target) |
| --- | --- | --- |
| 2 | 1.59 (1.6) | 2.22 (2.27) |
| 5 | 2.99 (3.0) | 4.12 (4.25) |
| 12 | 7.40 (7.2) | 10.25 (10.2) |
| 30 | 17.96 (18.0) | 25.27 (25.5) |
| 70 | 42.36 (42.0) | 59.60 (59.5) |

- Tier 1 kerb: a tap at D = 2 rises 1.59 studs, above the 1.5-stud kerb.
- Finding fixed: before the fix a tap at D = 2 rose only 1.40 (the physics step applies gravity before it moves the
  ball, costing about `v0·dt/2`). `BallController` now adds `g·dt/2` to the take-off speed.
- Landing: the squash mesh is created on the first landing; `rbxasset://sounds/action_get_up.mp3` loads
  (`IsLoaded` true, `TimeLength` 0.57 s).
- No `Vertical`, `Speed` or `Displacement` warning in the console at any diameter.

## Boosters (T033)

| Booster | Observed |
| --- | --- |
| Dash | peak speed 35.9 studs/s against 18.4 unboosted (2.0x), below the 80 cap; chip shown |
| Magnet | 17 small objects near the ball, 11 drifted towards it, diameter 2.0 to 2.29; chip shown |
| Spring | `Launch` `2;0.00;70.00;40.00`, ball bottom apex 12.2, came to rest on the Y = 11 roof at z = -104 |
| Shield | `BoostShield` went to 0 on the first bumper contact; the bounce still happened |
| Slick Trail | chip shown, pool 48 parts, patches owned by the ball tagged `TrapSurface` |

## Traps (T049, partial)

- Slow patch: target speed 9 inside, 18 outside (0.5x); chip "Slowed".
- Slick patch: steering torque 62.8 inside, 251.3 outside (0.25x); chip "Slippery!".
- Bumper Post: bounce `Launch` of 28 studs/s, once per cooldown while the ball keeps pushing.
- Sweeper: both sweepers move on every client at about 10 studs/s along their loops and match `Patrol.position`.
- Ball-to-ball bumps and the 3 s immunity: one MCP-driven player cannot make a second ball, so they were checked in
  Studio by `tests/studio/HazardService.spec.luau`, which runs the live `HazardService.step` on two sessions (size
  ratio, closing speed, immunity window, re-collection by a third ball; rerun 2026-10-30 after a probe-confirmed
  sync, 139 of 139 pass at the time; the full suite is 149 of 149 after the T061 rerun). The sweeper's server-side knock-off is covered there too. A two-player feel check is part
  of the owner's SC-004 sign-off. T049 done.

## Markers and themes (T055)

All 16 markers spawn (8 booster rings, 2 slick and 2 slow patches, 2 bumpers, 2 sweepers). With
`activeThemeId = "city"` (reverted) the same markers re-dressed with no code change (bumpers `e8483f` red, spring
and slow patches `e6cf96` sand, against `ffffff` in winter).

## HUD at 640 x 360 (T057)

Six chips stacked at x 8, y 120 to 332 (190 x 32 px, 4 px gap), text size 18, `TextFits` true in English and
Spanish ("Rastro resbaladizo" is the longest). They clear the timer (x 235) and the size meter (ends y 112). Chips
4 to 6 sit over the left 120 px thumb zone, which is only drawn over (chips take no input) and only when four or
more effects are active at once. Emoji glyphs for the six icons render (capture), chips use `GothamMedium`.

## Frame rate (T060, fps part passed, sign-off open)

Earlier run (Studio in the background): 31 one-second samples, every second 15 or 16 fps, all throttled
(AGENTS.md), so nothing to judge.

Rerun 2026-10-30 with Studio in front, after a probe-confirmed sync (86 of 86 files match). A client Heartbeat
counter in a live Snow Village run (one player, both sweepers moving, HUD and effect chips live), no window
focus-lost event during either run, so none of the seconds were throttled:

| Run | Samples | Magnet | Min | Max | Seconds below 30 fps |
| --- | --- | --- | --- | --- | --- |
| A, ball idle-ish, no booster | 35 | off | 58.9 | 60.5 | 0 |
| B, Magnet claimed at ring (5.7 s drive, then 31 samples) | 31 | on for the first 5 samples | 59.0 | 60.4 | 0 |

Runs A and B used the default 1179 x 819 viewport. Run C then used the owner's Studio device emulator set to
iPhone 6 Plus:

| Run | Viewport | Samples | Magnet | Min | Max | Seconds below 30 fps |
| --- | --- | --- | --- | --- | --- | --- |
| C, fresh Play after the device change, Magnet claimed at ring (19 s drive) | 735 x 413, touch on | 35 | on for 11 samples | 59.9 | 60.1 | 0 |

Every unthrottled second in all three runs was 59 to 60.5 fps, against the budget of >= 30 fps. Run C is the
closest to the phone target (the MCP itself cannot resize the viewport; 735 x 413 is 640 x 360 plus about 15%
each way, so the render cost is a little above the 640 x 360 case). The 640 x 360 HUD layout is covered by T057
above. Sweepers and the HUD were live in every run; the Magnet pull was live for 5 s (B) and 11 s (C). Emulator
fps is a desktop GPU, not a phone, so on-device fps is still not measured.

The owner's keep-Studio-in-front request is met, and the owner's SC-004 sign-off is recorded (2026-10-30, T060).

## Jest (T059)

`tests/studio/runner`: 149 of 149 tests pass in 11 suites (new: `BoosterService`, `HazardService`, `Remotes`).

T061 rerun (2026-10-30): Studio was in Play, so Play was stopped. The sync probe for the changed files
(`BoosterService`, `Rules/Jump`, `BallController`, `BoosterService.spec`) showed no mismatches. The Jest run then
gave 149 of 149 in 11 suites (the task's 139 -> 140 estimate was low). `lune run tests/unit/run`: 429 passed,
0 failed, which covers the changed `Rules/Jump.holdActive`.
`ThemeSwitch.spec` already expected 6 beach towels in city; the fixed towel makes 7, so the spec now says so.

## Big-ball booster claim (2026-10-31)

Studio probe: 86 files, no mismatches. Jest: 150 of 150 in 11 suites (`BoosterService.spec` 16 of 16, including
"accepts a big ball rolling on the ground at the client's trigger distance").

Play, one real run, ball resized on the server (`BallService.setDiameter` plus `physicalDiameter` and `Size`, from a
throwaway Script that was removed afterwards) and driven on the client at the speed cap toward a marker. Each claim
went through `Boosters.inClaimReach` on the client and the server, and the server hid the pickup (`Taken` true):

| D  | marker           | closest flat distance | claimed |
|----|------------------|-----------------------|---------|
| 30 | booster-dash-1   | 14.8                  | yes     |
| 50 | booster-dash-2   | 25.1                  | yes     |
| 70 | booster-magnet-1 | 35.3                  | yes     |

No `OutOfRange` or other claim error reached the console. The one `Vertical violation` line came from the resize
itself popping the ball upward, not from the claim.
