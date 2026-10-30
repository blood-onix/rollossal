# Playtest: 006 Mechanics Pass (jump, boosters, traps, ball bumps)

Agent-driven Studio run through the Studio MCP server, 2026-10-30, branch `006-jump-boosters-traps`, Snow Village,
grey box, one player. Expected values come from `research.md` R-01 to R-18.

**Owner sign-off (SC-004, Owner Approval Gate): PENDING.** The owner has not played this build. Nothing below is
a sign-off, and T060 stays open until the owner signs here and the fps run below is repeated unthrottled.

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
  sync, 139 of 139 pass). The sweeper's server-side knock-off is covered there too. A two-player feel check is part
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

## Frame rate (T060, open)

31 one-second samples at 640 x 360 with both sweepers, the Magnet pull and the HUD live: every second was 15 or 16
fps. Studio was in the background (throttled, AGENTS.md), so there are no unthrottled seconds to judge. **Owner:
please keep Studio in front for one run**; the fps check must be repeated then. Result to record: unthrottled
seconds >= 30 fps.

## Jest (T059)

`tests/studio/runner`: 139 of 139 tests pass in 11 suites (new: `BoosterService`, `HazardService`, `Remotes`).
`ThemeSwitch.spec` already expected 6 beach towels in city; the fixed towel makes 7, so the spec now says so.
