# Quickstart: Validating the Grey-Box Prototype

**Feature**: `001-grey-box-prototype` | Contracts: [contracts/](contracts/) | Data: [data-model.md](data-model.md)

This is the run-and-check guide. It holds no implementation code. Each scenario names the spec story or
success criterion it proves.

## Prerequisites

- Roblox Studio with the Studio MCP server connected (`.vscode/mcp.json`).
- Rokit 1.2.0 installed. Then, from the repo root: `rokit install` (Rojo 7.7.1, Wally 0.3.2, StyLua,
  Selene, luau-lsp, Lune) and `wally install`.
- For phone checks: the reference phone (mid-range Android, Galaxy A53/A54 class unless the owner names
  another) and a way to join a Studio or test-place server.

## 1. Automated gate (Story 4, SC-001)

```bash
scripts/check.sh          # expect exit code 0
scripts/test-guard.sh     # expect exit code 0: it proves check.sh's Rules guard FAILS on a bad file
```

Expect: StyLua, Selene, luau-lsp strict analysis, Lune unit tests and the Rules guard all pass. The same
script runs in `.github/workflows/check.yml` on every pull request. Also confirm by `grep -rIi ricokick .`
(outside `.git`) that no leftover references remain, and that `docs/rollossal-gdd.md` exists and
`README.md` links to it and to `.specify/memory/constitution.md`.

## 2. Run the game in Studio

```bash
rojo serve default.project.json      # then connect from the Rojo plugin in Studio
```

Press Play (one client). Expect: no menu, no avatar, a 2-stud grey ball in the room, a thumbstick on
touch or WASD on PC.

## 3. Scenario checks (manual, solo)

| # | Do this | Expect | Proves |
| --- | --- | --- | --- |
| S1 | Join and roll towards the nearest small cube | First pickup within 5 s; the cube sticks to the ball; camera starts to pull back as the ball grows | Story 1.1, SC-003 |
| S2 | Keep eating Tier 1 cubes, then Tier 2, 3, 4 as each becomes absorbable (the room refills every 15 s) | Each tier is solid until the ball is big enough, then it is eaten; all 4 tiers reached in about 2 min solo | Story 1.2, 1.3, SC-003, F-1 |
| S3 | Watch speed and camera while growing | Ball speed rises slowly (about `√D`); camera distance is `4 × D` (8 studs at the start) | Story 1.3 |
| S4 | Press Space (PC) or tap the jump button (phone); try to double-jump; hop the kerb at (−20, −12) | One hop of about 1.5 studs; no second hop in the air; kerb cleared | Story 1.4 |
| S5 | Eat at least 4 Tier 1 cubes, then hit a Tier 2/3/4 cube above 15 studs/s | 3 newest cubes pop off and land a few studs away; the ball shrinks; the cubes can be eaten again after 1 s | Story 2.1, SC-005 |
| S6 | Hit a bigger cube slowly (under 15 studs/s) | You are blocked; nothing falls off | Story 2.3 |
| S7 | Hit a bigger cube at speed with 0 or 1 cubes stuck | Only what is stuck falls off; diameter never goes below 2 | Story 2.2 |
| S8 | Eat 31 or more cubes (let the room refill) | Never more than 30 visuals on the ball; diameter keeps growing | Edge case: visual cap |
| S9 | Leave the game and rejoin; press Reset in the menu | Old ball and its visuals are gone; a fresh 2-stud ball appears | Edge case: disconnect and respawn |

## 4. Server validation tests (Jest-Lua, Story 3, SC-002)

With the Rojo-synced place open in Studio, run through the Studio MCP server:

```
execute_luau: return require(game.ServerStorage.Tests.runner)()
```

Expect all of the following to pass, including the six rejection cases of FR-024: unknown ID, already
taken, out of range, too large, non-string payload, and the 11th request within one second. The spec file
also covers: the exact-boundary pickup (size equal to `0.4 × D` passes), a knock-off with a stack of 5, the
registry invariant `#free + sum(#stacks) + #pendingRespawn = 30`, and a speed violation being corrected.

## 5. Console cleanliness (SC-007)

Run a Studio playtest driven through the Studio MCP server (start play, drive the ball, absorb, bump,
stop). Read the console with `get_console_output`. Expect zero new errors and zero warnings. A speed
violation `warn` appearing in honest play is a bug (raise `maxServerBallSpeed` or fix the cause).

## 6. Jitter measurement (R4, SC-006, the decision for `stuckVisualMode`)

A Studio script, run through the Studio MCP server, with two phases for each mode (`"Weld"` first):

1. **Resting**: place a ball on the floor with 30 visuals attached; trigger 20 growth steps (call the
   real `BallService` growth path, not a shortcut). Log the maximum change in the ball's `Position.Y` and
   the maximum `AssemblyLinearVelocity.Magnitude` between consecutive Heartbeats during the 20 steps.
2. **Rolling**: same, with the ball rolling at about 15 studs/s.

**Pass** (per mode): resting height deviation below 0.05 studs and resting speed below 1 stud/s; no
visible stutter in a screen recording. Repeat on a phone. If `"Weld"` fails and `"Follower"` passes, set
`Config.stuckVisualMode = "Follower"`. Record the numbers and the choice in `plan.md` §Risk Results and
`research.md` R4.

## 7. Multiplayer and phone checks

- Local server with 3 or more simulated clients (Studio "Local Server" test): each ball rolls
  independently; two players going for the same cube get one winner, no duplicate pickup; other
  players' stuck visuals appear on their balls; cubes respawn after 15 s (Story 3.1 to 3.4).
- 6 or more real players, at least 3 adults and 3 children aged 10 to 12, on a test place, using
  `specs/001-grey-box-prototype/playtest.md` (record date, commit SHA, counts per age group only,
  first-pickup time, jitter, growth satisfaction, frame rate on the reference phone at 30 fps or
  higher, bump-threshold notes, count of rejected honest absorbs, owner sign-off). SC-004, SC-006.
- Phone viewport screenshot (Studio MCP `screen_capture` at a phone resolution) showing the jump
  button at least 96×96 px in the bottom right, for the Quality Gate.

## Expected outcomes summary

| Check | Pass condition | Status (Studio run, 2026-10-25) |
| --- | --- | --- |
| `scripts/check.sh`, CI | exit 0 | `check.sh` passes locally; CI on the PR (T065) |
| Lune unit tests | all pass, expected values hand-computed | Pass (56 of 56) |
| Jest-Lua studio tests | all pass, including 6 rejection cases | Pass, 19 of 19 through `runner` in Studio (T056) |
| Solo scenarios §3 | S1 to S9 as listed | S1 to S8 pass (S4 on PC; S2 and S8 after T090: Tier 4 at 101 s solo, never more than 30 visuals); S9 Reset pass, rejoin deferred with T058 (owner: too early for multiplayer) |
| Studio playtest console | 0 errors, 0 warnings | Pass for a solo drive, absorb, bump, Reset run (only Studio's own `ContentId` line) |
| Jitter protocol | below the thresholds in §6, decision recorded | Laptop pass, `Weld` kept; phone run deferred by the owner (T040) |
| Phone viewport | jump button at least 96 × 96 px bottom right | Pass: Galaxy A16 in the Studio device simulator, 96 × 96 px, 24 px from the corner (T041); no touch thumbstick without a character (T091) |
| Playtest | gate recorded and signed off by the owner (Principle I) | Pending: human (T059) |
