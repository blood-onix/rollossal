# Implementation Plan: Run Loop

**Branch**: `002-run-loop` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-run-loop/spec.md`

## Summary

Turn free rolling into personal 240-second runs. Every player starts a run the moment they join. The
server owns the clock, the tier, the stars and the coins; at the bell it freezes the ball, builds one
`RunResult` per `runId` and sends it to the player. The client shows a phone-first HUD (timer, star
targets, size meter, pickup pop, tier banner), a results screen, and a hub screen with one big **Play**
button. **Roll again** resets the ball and starts a new run at once; **Back to hub** moves the ball to a
grey-box plaza. All maths (stars, tier lookup, coins, clock) is pure Luau in `src/shared/Rules`, tested
with Lune. Tiers, objects, star targets and the hub are data in `src/shared/Content/GreyBoxRoom.luau`;
every player-facing string comes from a repository string table loaded into a Roblox `LocalizationTable`.

Technical approach, one line each (reasoning and alternatives are in [research.md](research.md)):

- **Grey-box star targets**: the room overrides the production `{20, 45, 80}` with `{3.0, 4.0, 5.0}`,
  because a 30-cube room cannot grow a ball past about 6 studs (finding F-1, R1).
- **Clock**: `RunManager.step(now)` takes the time as an argument, so tests step 240 s without waiting
  (R2). The client counts down from a replicated server end time.
- **Bell**: the server anchors the ball, rejects further absorbs from `now >= endsAt` onward, and the
  client also locks input (R3).
- **Falls and Reset mid-run**: the ball goes back to its spawn with size and stack kept (R4).
- **State to clients**: run state as `Player` attributes; one-shot events (pickup, tier unlock, knock-off,
  result) as four server-to-client RemoteEvents; two zero-argument client-to-server intents (R5).
- **Hub**: a second floor in `Workspace.Hub`, the same ball, a HUD **Play** button (R6).
- **Friends**: `Player:IsFriendsWith` results cached per pair inside `pcall` (R7).
- **Strings**: `Strings.luau` (data) feeds a `LocalizationTable`; a Lune test guards against literals (R8).
- **Placeholders**: engine-bundled `rbxasset://` sounds and Unicode glyph icons, listed in
  `src/shared/Assets.luau` and `Content/Icons.luau` (R9).
- **UI**: built in code with one `UiKit`, `UIScale = max(1, shortSide / 720)` (R10).

## Technical Context

**Language/Version**: Luau (strict mode, `--!strict` on every file), Roblox engine as shipped with the
installed Studio.

**Primary Dependencies**: Rojo 7.7.1, Wally 0.3.2, Jest-Lua (`jsdotlua/jest@3.10.0`), all already pinned.
Roblox services only: `LocalizationService`, `HapticService`, `SoundService`, `Players`, `Workspace`.
No new tools or packages (Constitution XII).

**Storage**: N/A. Coins, best sizes and seen book entries are in-memory per server session; saving is
Feature 003.

**Testing**: Lune 0.10.5 unit tests in `tests/unit` (Rules, Config, Content, Strings, string-literal
guard); Jest-Lua Studio tests in `tests/studio` (run authority, anti-cheat, fall, Roll again); Studio MCP
playtest with a console read and phone-resolution viewport captures; static gates StyLua 2.5.2, Selene
0.32.0, luau-lsp 1.70.1 strict.

**Target Platform**: Roblox client (PC and phones, touch and keyboard) and Roblox server. Reference
phone: Galaxy A53/A54 class (assumption carried from 001).

**Project Type**: Roblox game (Rojo-managed Luau project: shared, server and client trees).

**Performance Goals**: 30 fps on the reference phone with the HUD active. The HUD updates timer text once
per second and the meter on `Diameter` change, not every frame. Up to 12 concurrent runs per server.

**Constraints**: nothing the client sends may set a size, coin, star, tier or result (II); Rules stay free
of Roblox APIs (III); runs have clear endings and no menu stands in front of the first run (IV, VI); text
at least 18 px, buttons at least 96 px, icon plus label for every status (VI); every string localised (IX);
nothing for sale and no timers or offers on the results screen (V); new behaviour behind a Config flag
(VII).

**Scale/Scope**: 1 world (grey-box room), 4 size tiers, 4 object types, 12 players. About 10 new Luau
source files, 6 edited, 8 new test files (see Project Structure).

## Constitution Check

*GATE: passes before Phase 0 research; re-checked after Phase 1 design.* Constitution v1.0.0.

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I. Fun proven in grey box | **Pass** | The run loop is a new mechanic, so it gets a grey-box playtest before polish: `specs/002-run-loop/playtest.md` (date, commit, adults and children 10–12 by age group, findings, owner sign-off). Star targets are provisional until that playtest (R1). UI is plain frames and text, sounds are engine placeholders, no art. |
| II. Server authority | **Pass** | The server alone starts, ends and scores runs. The only client intents are `RollAgain` and `BackToHub`, with zero arguments, accepted only in `Ended` or `Hub`. Absorb and Bump are rejected from `now >= endsAt` onward, before the step even runs. Jest-Lua tests cover early end, spoofed arguments, absorb after the bell, and single publication (FR-024). |
| III. Pure, tested rules | **Pass** | `Stars`, `Tiers`, `Coins` and `RunClock` are standalone pure modules with hand-computed Lune tests; `check.sh` already greps `src/shared/Rules` for forbidden identifiers. Time enters as an argument. |
| IV. Safe for everyone | **Pass** | This feature is what gives the game runs with clear endings. No chat needed, no player-vs-player swallowing, no gore. Nothing changes the maturity answers. |
| V. Ethical monetization | **Pass** | Results screen has no offers, discounts, countdowns or prices (FR-020). `friendBoost` and `doubleCoins` are only function arguments, fixed at `false`/`0` here. |
| VI. Mobile first | **Pass** | No menu before the first run (run starts on join). Text ≥ 18 px after `UIScale` (which never goes below 1), buttons ≥ 96 px, icon + label for every status. Layout checked at 640×360 and 844×390 viewport captures. One-thumb: **Roll again** and **Play** are single large buttons. |
| VII. Content is data | **Pass** | Tiers, objects, star targets and hub layout live in `GreyBoxRoom.luau`. Lune tests validate them (R12). New behaviour sits behind `Config.Flags.RunLoop`. A second world needs only data plus one line in `Worlds.luau`. |
| VIII. Player data | **N/A** | Nothing is stored; session-only tables. User IDs only, no names. |
| IX. Localised strings | **Pass** | Every UI string, tier name, headline and object name is a key in `Strings.luau`. A Lune test rejects letter-bearing string literals on `Text` assignments (R8). English complete; Spanish is Feature 007. |
| X. Multi-agent discipline | **Pass** | Own branch. File ownership in Project Structure keeps `[P]` tasks disjoint. Studio MCP is claimed per task. No place files or secrets. |
| XI. Asset pipeline | **Pass** | No imported assets. Placeholder sounds are engine-bundled `rbxasset://sounds/...` files, recorded in the new `src/shared/Assets.luau` and nowhere else (R9). No uploads. |
| XII. Keep it lean | **Pass** | No new tool or package. Each new abstraction has at least two users: `UiKit` (Hud, ResultsUi, HubUi), `RunClient` (Hud, ResultsUi, HubUi, Feedback, BallController), `Worlds` (RunManager, Hud, ResultsUi, Feedback), `Localizer` (all UI). |

**Quality Gates mapping** (the PR description states how each was met): gate 1 `scripts/check.sh`; gate 2
Studio MCP playtest of a full run, tier unlock, knock-off, bell, Roll again and Back to hub with console
read, plus phone-resolution captures of HUD, results and hub; gate 3 sounds recorded in `Assets.luau`
(engine built-ins, no budget impact); gate 4 every new string in `Strings.luau`; gate 5 `tasks.md` ticks.

**Human Approval Required items**: none triggered (no publish, no DataStore, no prices, no maturity
change, no new tools, no spending).

**Post-design re-check (after Phase 1)**: no violation found. The design adds no tool, package or
service; every progress decision stays on the server; Rules stay pure. Complexity Tracking stays empty.

### Findings (spec and constitution conflicts or gaps the plan resolves)

- **F-1 Star targets do not fit the grey-box room.** The spec's `{20, 45, 80}` studs are Snow Village
  targets. In the 30-cube room a ball reaches about 4.5 to 6 studs at most (R1). With the production
  values, nobody could ever earn a star in this feature, and SC-001/SC-004 acceptance scenarios (a results
  screen showing stars) could not be exercised. The spec's own Assumptions allow a world-level override;
  the plan uses it and keeps `Config.starThresholds = { 20, 45, 80 }` as the default.
- **F-2 `rollAgainDelaySeconds = 3` is a budget, not a delay.** The plan resets and restarts at once
  (Constitution VI favours no waiting). The constant is the upper bound asserted by tests and the
  quickstart.
- **F-3 Phone haptics may be unavailable.** `HapticService` covers gamepad motors; the engine may expose
  no phone vibration. The plan wraps the call so it never errors, and records the outcome of a real-device
  check in `playtest.md` (R11).
- **F-4 Crowded servers starve the room.** With 6+ players sharing 30 cubes each player sees a fraction of
  the supply, so stars are a solo/small-group measure in this feature (same limit as 001 F-1). Pooling and
  refill rules come with Feature 004. Not fixed here.

## Project Structure

### Documentation (this feature)

```text
specs/002-run-loop/
├── plan.md              # This file
├── research.md          # Phase 0 output: decisions R1 to R13
├── data-model.md        # Phase 1 output: entities, states, validation
├── quickstart.md        # Phase 1 output: how to run, test and measure
├── contracts/
│   ├── remotes.md             # client-to-server intents, server-to-client events
│   ├── replicated-state.md    # Player attributes, Workspace.Hub, ball behaviour per state
│   ├── rules-api.md           # Stars, Tiers, Coins, RunClock signatures and test values
│   ├── content-and-config.md  # Config keys, World schema, string keys, Assets
│   └── ui.md                  # HUD, pickup pop, tier banner, results, hub layout
├── checklists/requirements.md  # (from /speckit-specify)
├── playtest.md          # Created during implementation, filled during the playtest
└── tasks.md             # Phase 2 output (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
src/shared/                           # -> ReplicatedStorage.Shared
├── Config.luau                       # EDIT: run-loop keys, Flags.RunLoop, UI constants
├── Assets.luau                       # NEW: placeholder sound paths (only place SoundIds live)
├── Worlds.luau                       # NEW: the active world plus indexes (objects by tier/id/book)
├── Content/
│   ├── GreyBoxRoom.luau              # EDIT: worldId, starThresholds, sizeTiers, objects, hub
│   └── Icons.luau                    # NEW: icon id -> glyph (placeholder until real assets)
├── Localization/
│   ├── Strings.luau                  # NEW: key -> { en = "..." } (data only, Lune-testable)
│   └── Localizer.luau                # NEW: builds the LocalizationTable, Localizer.t(key, args)
└── Rules/                            # pure; standalone modules, no requires
    ├── Stars.luau                    # NEW: stars(diameter, thresholds)
    ├── Tiers.luau                    # NEW: lookup, progress
    ├── Coins.luau                    # NEW: total(values, options)
    └── RunClock.luau                 # NEW: remaining, expired, format

src/server/                           # -> ServerScriptService
├── Main.server.luau                  # EDIT: start RunManager, step it each Heartbeat
├── Remotes.luau                      # EDIT: 2 intents + 4 events
├── WorldSpawner.luau                 # EDIT: build Workspace.Hub, getHubSpawn
├── BallService.luau                  # EDIT: zone, freeze, returnToSpawn, resetBall; fall keeps size
├── AbsorbService.luau                # EDIT: run gate, pickup/knock-off hooks, Reset policy
├── RunManager.luau                   # NEW: run state machine, results, post-run intents
└── FriendCache.luau                  # NEW: pcall'd IsFriendsWith cache per pair

src/client/                           # -> StarterPlayer.StarterPlayerScripts
├── Main.client.luau                  # EDIT: start the new modules
├── RunClient.luau                    # NEW: reads run attributes, re-signals the 4 events
├── UiKit.luau                        # NEW: ScreenGui, UIScale, labels with UIStroke, 96 px buttons
├── Hud.luau                          # NEW: timer, star targets, size meter, pop, banner
├── ResultsUi.luau                    # NEW: results screen, Roll again, Back to hub
├── HubUi.luau                        # NEW: hub screen with Play
├── Feedback.luau                     # NEW: pickup sound/pop/haptic, tier banner sound, knock-off
├── CameraController.luau             # EDIT: shake(duration, magnitude), reduceMotion
└── BallController.luau               # EDIT: no input unless the run is Active or Hub

tests/unit/
├── Stars.test.luau  Tiers.test.luau  Coins.test.luau  RunClock.test.luau     # NEW
├── Strings.test.luau                 # NEW: keys exist, placeholders balanced
├── LiteralGuard.test.luau            # NEW: no letter-bearing Text literals in src/client, src/server
├── GreyBoxRoom.test.luau             # EDIT: tiers, objects, stars, hub
└── Config.test.luau                  # EDIT: new keys

tests/studio/
└── RunManager.spec.luau              # NEW: end at 240 s, once-only result, anti-cheat, fall, Roll again
```

**Structure Decision**: extend the 001 tree. Server logic splits by owner: `RunManager` owns run state and
the only mutation path from state to `BallService`; `AbsorbService` asks it one question (`acceptsPickups`)
and reports two facts (`onPickup`, `onKnockOff`). `BallService` never requires `RunManager`, so there is no
require cycle. Client modules are one file per screen; `RunClient` is the single reader of run state.

**Parallel work** (for `tasks.md`): Rules + their tests, Content + Strings + tests, server, client UI and
the Studio spec touch disjoint files after `Config.luau`, `Worlds.luau` and the contracts land first.

## Complexity Tracking

No Constitution Check violations. Section intentionally empty.
