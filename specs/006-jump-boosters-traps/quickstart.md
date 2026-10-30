# Quickstart: Validate the Mechanics Pass (006)

How to prove the feature end to end. Static checks need no Studio; the playtest steps are run by the agent
through the Studio MCP (tasks marked 🔒 in `tasks.md`) and then by the owner.

## 1. Static gate

```bash
scripts/check.sh
```

Expect exit 0: StyLua, Selene, luau-lsp strict, design-tokens and atlas checks, all Lune tests (including the new
`Jump`, `Boosters`, `Traps`, `Knock`, `Patrol`, `Markers` and the extended `BallGuard`, `Config`, `SnowVillage`,
`Strings`), the GreyBoxRoom guard and the rules-purity grep. Spot-check:

- `Jump.test`: the five diameters in `contracts/rules-api.md` produce the listed `tapApex`, `takeoffSpeed` and
  `holdGravity` (tolerance 0.01).
- `BallGuard.test`: a simulated tap and a simulated held jump at every diameter stay `Ok`; a second take-off at
  the apex is `Vertical`.
- `SnowVillage.test`: 8 + 8 markers, all nine sub-kinds, validator `{}` under `winter` and `city`, part budget
  under 2,000.

## 2. Studio sync

1. `scripts/studio-preflight.sh` (starts Rojo if needed).
2. `list_roblox_studios`, then run the output of `scripts/studio-sync-probe.sh` through `execute_luau` (Edit).
   `mismatches = {}` means Studio has the repo's code. If not, ask the owner once to press Connect on the Rojo
   plugin and re-poll every 30–60 s for up to 20 minutes.
3. Restart Play after any code change (Rojo syncs the Edit place only).

## 3. Jest-Lua specs

Run `tests/studio/runner` (needs `LoadStringEnabled` or `FFlagEnableLoadModule`; the owner keeps it on in the dev
place; flag it in any publish checklist). Expect `BoosterService`, `HazardService`, `BallService` and `Remotes`
specs green, with the claim refusal codes, the 13-event count and `ClaimBooster` argument rejection.

## 4. Jump playtest (US1, SC-001)

In Play (Server and Client), at each of D = 2, 5, 12, 30, 70 (set the diameter through the existing run
progression helpers, not by hand-writing client attributes):

1. Place an unabsorbable obstacle `0.6·D` tall; tap Jump at speed; the ball's bottom clears the top.
2. Hold Jump 0.25 s against a `0.85·D` obstacle; it clears. Release early; the apex is lower.
3. At D = 2 clear the 1.5-stud kerb on a tap.
4. Spam Jump in the air: no second take-off. Teleport the ball upward by 30 studs: the server resets it.
5. `get_console_output` shows zero server violation warnings; land from ≥ 12 studs/s and confirm the thump plays
   (`IsLoaded`, `TimeLength`) and the squash renders (capture; the squash is skipped with Reduce motion on).

## 5. Boosters (US2)

For each of dash, magnet, spring, shield, slick_trail: drive the ball to its marker with the client Heartbeat
driver from `AGENTS.md`, confirm the claim, the chip (icon and text), the effect, expiry, and the respawn after
`boosterRespawnDelay`. Specific checks:

- **Dash**: speed exceeds 56 for 3 s with no violation; setting `AssemblyLinearVelocity` above `boostSpeedCap`
  is clamped; after dash plus 0.5 s grace, 64 studs/s is clamped.
- **Magnet**: small objects drift in and are absorbed through the normal `Absorb` path; objects larger than
  `0.4·D` stay put; unabsorbed objects return home on expiry.
- **Spring** at `(0, -126)` and `(0, 126)`: the ball lands on the Y = 11 roof; no violation.
- **Shield**: a bumper hit pops zero objects, the diameter is unchanged and the chip clears.
- **Slick trail**: patches appear behind the ball, a second ball slips on them, the first ball does not; never
  more than 48 patches alive.
- Out of range, over the rate limit, after run end and with the flag off: no effect.

## 6. Traps and bumps (US3)

- Slick and Slow patches change steering and speed; chips show "Slippery!" and "Slowed" and clear after the linger.
- A ball with 3 or more stuck objects hits a Bumper Post and the Street Sweeper: 3 objects scatter, the ball
  shrinks (not below `startDiameter`), the camera shakes unless Reduce motion is on.
- Two balls (a second player or a test dummy session): the larger (≥ 1.25×) at ≥ 15 studs/s knocks 3 off the
  smaller; the victim has 3 s of immunity; both players can re-collect after `scatterGrace`; nobody is swallowed.
- Sweeper: stand in two Studio clients (or Server and Client) and confirm both see it within a stud of the
  server's `Patrol.position`.

## 7. Theme switch and flags (US3 scenario 1, SC-003)

1. Set `activeThemeId = "city"` in `SnowVillage.luau`; restart Play: every booster and trap uses its `city`
   dressing and name; no code changed. Set it back to `winter`.
2. Flip each flag in `Config.Flags` to `false` one at a time (and each master): that mechanic is absent or
   refused and nothing else changes. `ScaledJump = false` restores the old hop.

## 8. Phone size and performance

Build the 640 × 360 clone of the HUD as in `AGENTS.md` (96 px Jump zone bottom right, 120 px thumb zone bottom
left), with all chips active at once: measure `AbsolutePosition`, `AbsoluteSize`, `TextFits`, `TextSize ≥ 18`,
and capture it. Sample FPS per second during a run with every mechanic live; judge on the unthrottled seconds and
report seconds at exactly 15 fps as throttled (AGENTS.md). Expect ≥ 30 fps. Check the icons render under both
fonts.

## 9. Sign-off (Principle I, SC-004)

Write `specs/006-jump-boosters-traps/playtest.md` with the agent's results (sections 4–8) and the owner's
verdict on feel: does a tap clear obstacles, are boosters worth chasing, are the traps fair. Tuning changes go
into `Config` and are recorded in that file. 004c (polish) and 004d (outside testers) start only after sign-off.
