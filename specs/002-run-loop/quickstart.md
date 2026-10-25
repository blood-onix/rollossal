# Quickstart: Validating the Run Loop

**Feature**: `002-run-loop` | Contracts: [contracts/](contracts/) | Data: [data-model.md](data-model.md)

This is the run-and-check guide. It holds no implementation code. Each scenario names the spec story or
success criterion it proves.

## Prerequisites

- Everything from the 001 quickstart: Roblox Studio with the Studio MCP server connected
  (`.vscode/mcp.json`), Rokit tools installed (`rokit install`), `wally install`.
- `rojo serve default.project.json`, connected from the Rojo plugin in Studio.
- For phone checks: the reference phone (Galaxy A53/A54 class unless the owner names another).

## 1. Automated gate (Story 3, SC-004, SC-005)

```bash
scripts/check.sh          # expect exit code 0
scripts/test-guard.sh     # expect exit code 0 (Rules purity guard still fails on a bad file)
```

Expect: StyLua, Selene, luau-lsp strict, Lune unit tests (Stars, Tiers, Coins, RunClock, GreyBoxRoom, Strings,
LiteralGuard, Config) and the Rules purity guard all pass. `LiteralGuard.test` failing means an English
sentence was typed into `src/client` or `src/server`; move it to `Strings.luau`.

## 2. Studio unit tests (Story 1, SC-004)

Start Play in Studio, then through the MCP `execute_luau` tool, on the server:

```text
return require(game.ServerStorage.Tests.runner)()
```

Expect all Jest suites green, including `RunManager.spec` (run ends at 240 s of injected time without client
input; one `RunResult` per `runId`; absorb rejected from `endsAt`; spoofed `RollAgain`/`BackToHub` arguments
and wrong-state calls change nothing; fall keeps size, stack and `runId`; Roll again resets and issues a new
`runId` within `Config.rollAgainDelaySeconds`; leaving mid-run publishes nothing).

## 3. Fast-forward a run in Studio

Waiting 240 s per check is slow. In Play mode, `execute_luau` on the server can step the injected clock
(the clock is an argument, see research R2):

```text
local RunManager = require(game.ServerScriptService.RunManager)
RunManager.step(os.clock() + 240)   -- every Active run ends now
```

Use it only for checks that do not depend on real time passing; scenarios 4 and 8 use real time.

## 4. Scenario checks (manual, solo)

| # | Do this | Expect | Proves |
| --- | --- | --- | --- |
| 1 | Press Play, do nothing | No menu. HUD shows `04:00` counting down, three star targets (`1 star: 3.0`, `2 star: 4.0`, `3 star: 5.0`), size `2.0`, bar empty, `Next: ▲ SMALL CUBES` | Story 1 sc.1, Story 2 sc.1, VI |
| 2 | Roll into a Tier-1 cube | Within 5 s: sound, `+ Tiny cube` pop fading in about 1 s, size number pops, bar fills | Story 2 sc.2 |
| 3 | Eat Tier-1 cubes until size ≥ 2.375 | Tier banner `You can roll up: SMALL CUBES!` once, camera pulls back, `Next:` changes to MEDIUM CUBES | Story 2 sc.3 |
| 4 | Run into a Tier-3 cube at speed with some stuck cubes | Bump flash, camera shake, sound; size drops; no coins lost (check in results) | Story 2 sc.5 |
| 5 | Grow back across a tier you already unlocked | No second banner for that tier | Story 2 sc.4, SC-003 |
| 6 | Fall off the room edge mid-run | Ball returns to spawn, size, stuck cubes and timer unchanged | Edge case, FR-016 |
| 7 | Step the clock (section 3) | Ball stops, results screen appears once: final size, stars, coins, new book entries, best row, two 96 px buttons; HUD hidden | Story 1 sc.2, FR-020 |
| 8 | Tap **Roll again**; time it | New run `04:00` within 3 s, ball size `2.0`, stuck cubes gone, new run id | Story 1 sc.3, FR-014 |
| 9 | Finish run 2 and 3 with **Roll again** | Each run has its own results; ids differ (print `RunId` attribute) | Story 1 sc.5, SC-001 |
| 10 | At results, tap **Back to hub** | Plaza floor, ball size 2, no timer, **Play** card; rolling works, absorbing does not | Story 1 sc.4, FR-015 |
| 11 | In the hub, tap **Play** | New run in the room within 3 s | FR-014 |
| 12 | Leave the server mid-run (stop Play) | No results published, no console error | Edge case |
| 13 | Two accounts, one a friend (private server) | Friend row on results shows the friend's best size; coins show the `+20%` friend bonus | FR-012, Assumptions |

## 5. Phone captures (SC-002, Quality Gate 2)

Through the Studio MCP server, capture the viewport at **640×360**, **844×390** and **1280×720** for: HUD with
a pickup pop and a tier banner visible together; results screen with four new book entries; hub screen.
Expect no clipping or overlap, text ≥ 18 px, buttons ≥ 96 px, every glyph rendering (research R9). Record the
captures in `playtest.md`.

## 6. Console cleanliness (SC-006)

Run scenarios 1 to 11 in one Play session and read the console through the MCP server. Expect no new errors
or warnings (the 001 `warn` for speed violations still counts as a failure if it appears during honest play).

## 7. Calibration for the playtest (Principle I)

Time a solo run to the bell eating everything absorbable, three times, and record final diameters, stars,
and when Tiers 2, 3, 4 opened. Expected from research R1: Tier 3 near 65 s, Tier 4 near 100 to 125 s, final
size about 4.5 to 5.7. If most runs earn 0 or 3 stars, retune `GreyBoxRoom.starThresholds` (data only).
Record in `playtest.md` with the build, adult and child counts by age group, findings and owner sign-off.
Also record whether a phone vibrates on pickup (finding F-3) and how a 6-player server feels (finding F-4).
