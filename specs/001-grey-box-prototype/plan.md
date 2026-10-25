# Implementation Plan: Grey-Box Prototype

**Branch**: `001-grey-box-prototype` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-grey-box-prototype/spec.md`

## Summary

Build the first playable Rollossal grey-box: one client-owned rolling ball per player that absorbs
cubes of size `≤ 0.4 × diameter`, grows by volume (`newD = (D³ + 0.6·S³)^(1/3)`), loses its 3 most
recent pickups when it hits a bigger cube fast, and is followed by a camera whose distance is
`4 × diameter` (clamped). The server alone decides absorption, size, knock-offs and respawns; the
client only sends a target cube ID. All maths is pure Luau in `src/shared/Rules`, tested with Lune. Part A
also lays the repository foundations (Rojo project, linters, `scripts/check.sh`, CI, GDD move) that
every later feature depends on.

Technical approach, in one line each (reasoning and alternatives are in [research.md](research.md)):

- **Room**: 30 cubes in 4 tiers (0.75 / 0.95 / 1.2 / 1.5 studs, counts 12 / 9 / 6 / 3), derived in R1.
  The chain needs about 74 pickups, so it relies on the 15 s respawn (finding F-1).
- **Bumps**: client sends `Bump(id)`; the server checks it against its own peak speed over 0.35 s (R2).
- **Input**: no character; `PlayerModule` ControlModule move vector (R3).
- **Stuck visuals**: client-side parts for every ball, `Weld` mode by default and `Follower` fallback
  behind one Config switch; measured in the Studio spike (R4).
- **Camera**: default camera with a smoothed zoom distance (R5).

## Technical Context

**Language/Version**: Luau (strict mode, `--!strict` on every file), Roblox engine as shipped with the
installed Studio.

**Primary Dependencies**: Rojo 7.7.1, Wally 0.3.2 (already pinned in `rokit.toml`), Jest-Lua
(`jsdotlua/jest@3.10.0`, already in `wally.toml`). `ProfileStore` stays in `wally.toml` untouched; this
feature does not use it. No new tools or packages (Constitution XII).

**Storage**: N/A. Nothing is saved in this feature (saving is Feature 003).

**Testing**: Lune 0.10.5 unit tests in `tests/unit` (Rules, Config sanity, Content validation); Jest-Lua
Studio tests in `tests/studio` (absorb and bump validation), run through the Studio MCP server;
static gates StyLua 2.5.2, Selene 0.32.0, luau-lsp 1.70.1 (strict); Studio MCP playtest for console
cleanliness (SC-007).

**Target Platform**: Roblox client (PC and mobile phones, touch and keyboard) and Roblox server.
Reference phone: mid-range Android, Galaxy A53/A54 class (spec assumption).

**Project Type**: Roblox game (Rojo-managed Luau project: shared, server and client trees).

**Performance Goals**: 30 fps on the reference phone with 6+ balls and 30 stuck visuals each; zero
visible jitter when a ball with 30 visuals grows; up to 12 balls per server.

**Constraints**: first pickup within 5 s of joining and no menu (VI); one-thumb play, jump button at
least 96×96 px; server authority for everything that changes size (II); `src/shared/Rules` free of
Roblox APIs (III); no player-facing strings in this feature (the jump button uses a symbol only), so IX
has nothing to localise.

**Scale/Scope**: 1 room, 30 cubes, 4 tiers, up to 12 players, about 14 Luau source files plus tests
(see Project Structure).

## Constitution Check

*GATE: passes before Phase 0 research; re-checked after Phase 1 design.* Constitution v1.0.0.

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I. Fun proven in grey box | **Pass (this feature is the gate)** | Plain parts only; `playtest.md` (FR-025) records 3+ adults and 3+ children 10–12 by age group, commit SHA, results and owner sign-off. No art, audio, VFX or UI styling anywhere. |
| II. Server authority | **Pass** | Remotes carry only `objectId` (and an argument-less respawn intent). Server validates existence, taken, distance, size rule and rate limit (R2, contracts/remotes.md). Speed check each Heartbeat. Bump speed is measured by the server, never sent. Jest-Lua tests cover each rejection (FR-024). |
| III. Pure, tested rules | **Pass** | `src/shared/Rules` is five standalone pure modules; every function has Lune tests with hand-computed values; `check.sh` greps for forbidden identifiers (R9). |
| IV. Safe for everyone | **Pass** | Cubes and balls only. No chat, no player-vs-player swallowing, no gore. Run endings are Feature 002. Nothing here changes the maturity questionnaire. |
| V. Ethical monetization | **N/A** | No purchases. `RewardedAds` exists only as an off feature flag. |
| VI. Mobile first | **Pass** | One-thumb controls; jump button ≥ 96 px; a Tier-1 cube within 10 studs of every spawn slot (≈ 1–2 s of rolling); budgets in Config (`maxVisibleStuck`, `maxActivePartsPerServer`, triangles per tier); 30 fps checked in playtest. The jump glyph is a symbol, not text, and meaning is carried by shape and position, not colour. |
| VII. Content is data | **Pass** | Tier sizes, counts and cube layout live in `src/shared/Content/GreyBoxRoom.luau`; Lune test checks sizes ascend by tier and IDs are unique. New features (`AvatarPusher`, `BigBallMode`, `RewardedAds`) are Config flags, default off. |
| VIII. Player data | **N/A** | Nothing stored. |
| IX. Localised strings | **N/A** | No player-facing strings in this feature. |
| X. Multi-agent discipline | **Pass** | Own branch; tasks will mark `[P]` only on disjoint files (file ownership is in Project Structure); Studio MCP is claimed per task in `tasks.md`. No place files or secrets (`.gitignore`, FR-002). |
| XI. Asset pipeline | **N/A** | No imported assets; cubes are plain parts (12 triangles each, inside the 300-triangle Tier 1–2 budget). `Assets.luau` is not needed yet. |
| XII. Keep it lean | **Pass** | Only tools already named in the constitution. CI installs Rokit from the pinned release with `curl` instead of a third-party action (R9). Abstractions each have two current users: `StuckVisuals` (Weld and Follower modes), `RateLimit` (absorb and bump), `StuckStack` (server and client), `WorldSpawner` (absorb and bump). |

**Quality Gates mapping** (each PR description must state how each was met): gate 1 `scripts/check.sh`;
gate 2 Studio MCP playtest with console read, plus a phone-resolution viewport capture of the jump
button; gate 3 N/A (no assets); gate 4 N/A (no strings); gate 5 `tasks.md` ticks.

**Human Approval Required items**: none triggered. The mid-range reference phone
(`TODO(REFERENCE_PHONE)`) stays an assumption and the owner confirms or names a device at sign-off.

**Constitution TODOs resolved by this feature** (Part A): `TODO(GDD_PATH)` (GDD moved to `docs/`),
`TODO(CHECK_SCRIPT)`, `TODO(GITIGNORE)` (existing `.gitignore` gets the missing `*.pem` / `*.key`
lines), and the Ricokick leftovers in `rokit.toml` and `wally.toml`.

**Post-design re-check (after Phase 1)**: no violation found. The design adds no tool, package or
service, keeps every progress-affecting decision on the server, and keeps Rules pure. No entry is
needed in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-grey-box-prototype/
├── plan.md              # This file
├── research.md          # Phase 0 output: decisions R1 to R12
├── data-model.md        # Phase 1 output: entities, states, validation
├── quickstart.md        # Phase 1 output: how to run, test and measure
├── contracts/
│   ├── remotes.md           # RemoteEvents the client may call
│   ├── replicated-state.md  # Attributes and instances the server publishes
│   ├── rules-api.md         # Pure module signatures
│   └── config-and-content.md # Config keys, values, derivations; Content schema
├── checklists/requirements.md  # (from /speckit-specify)
├── playtest.md          # Created during implementation, filled during the playtest (FR-025)
└── tasks.md             # Phase 2 output (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
.github/workflows/check.yml          # runs scripts/check.sh on every pull request
.luaurc  stylua.toml  selene.toml  default.project.json
rokit.toml  wally.toml  .gitignore    # existing; edited for Part A
README.md                             # short overview linking the GDD and the constitution
docs/rollossal-gdd.md                 # the design brief (moved from README.md with git mv)
scripts/
├── check.sh                          # the one verification command
└── test-guard.sh                     # proves the Rules guard fails on a forbidden identifier

src/shared/                           # -> ReplicatedStorage.Shared
├── Config.luau                       # every tuning number, flag and budget
├── Content/
│   └── GreyBoxRoom.luau              # tiers, counts, room size, cube layout (data only)
└── Rules/                            # pure; standalone modules, no requires
    ├── Absorb.luau                   # canAbsorb, isKnockOff
    ├── Growth.luau                   # growDiameter, shrinkDiameter
    ├── Movement.luau                 # targetSpeed, cameraDistance
    ├── StuckStack.luau               # push (cap), popRecent, visibleTail
    └── RateLimit.luau                # sliding-window allow()

src/server/                           # -> ServerScriptService
├── Main.server.luau                  # starts services in order
├── Remotes.luau                      # creates ReplicatedStorage.Remotes
├── WorldSpawner.luau                 # builds the room, cube registry, respawn loop
├── BallService.luau                  # ball sessions, ownership, speed check, growth easing
└── AbsorbService.luau                # Absorb / Bump / RespawnBall validation and effects

src/client/                           # -> StarterPlayer.StarterPlayerScripts
├── Main.client.luau
├── BallController.luau               # input -> torque, jump, contact scan, requests
├── JumpButton.luau                   # mobile on-screen jump (>= 96 px)
├── CameraController.luau             # smoothed zoom distance
└── StuckVisuals.luau                 # Weld / Follower visuals for every ball

tests/
├── unit/                             # Lune
│   ├── harness.luau  run.luau
│   ├── Absorb.test.luau  Growth.test.luau  Movement.test.luau
│   ├── StuckStack.test.luau  RateLimit.test.luau
│   └── Config.test.luau  GreyBoxRoom.test.luau
└── studio/                           # Jest-Lua, -> ServerStorage.Tests
    ├── runner.luau
    └── AbsorbService.spec.luau
```

**Structure Decision**: the standard Rollossal layout from the design brief §9, trimmed to what this
feature needs (no `RunManager`, `DataService`, `Hud`, `Assets.luau`; those arrive with later features).
Folders map to the Rojo tree exactly as in FR-003. `[P]` tasks can run in parallel across these
disjoint groups: Rules + unit tests; Config + Content; tooling files; server files; client files.

## Design Notes That Affect Tasks

1. **Round trip of one pickup**: client sees contact → `Absorb(id)` → server `tryAbsorb` → on success the
   server marks the cube taken (hidden), pushes `{id, size, dir}` onto the stack, computes the new
   `Diameter` with `Rules.Growth.growDiameter`, writes the `Diameter` and `Stuck` attributes, and starts
   easing the physical size. Every client's `StuckVisuals` reacts to the `Stuck` change.
2. **Knock-off round trip**: client sees contact with a too-big cube → `Bump(id)` → server checks
   (R2) → pops up to `knockOffCount` entries → `Growth.shrinkDiameter` → scatters those cubes
   (ring of `scatterDistance` studs around the ball, anchored, `availableAt = now + scatterGrace`) →
   updates attributes.
3. **Ordering inside `AbsorbService`**: type check → registry lookup → taken check → distance → size
   rule → rate limit (the order in spec FR-015). Deliberate change: the rate limiter runs right after
   the type check and counts every string-typed request, valid or not, so a flood of forged IDs also
   hits the 11th-request cutoff and costs almost nothing. The Studio test for rejection reasons
   therefore fixes the order to: type → rate limit → lookup → taken → distance → size. This still
   validates all four conditions of FR-015 before any state changes.
4. **Logging**: only speed-check violations call `warn`. Ordinary rejections (lost races, too far) are
   silent counters, so a clean playtest has zero console warnings (SC-007).
5. **Time**: server code reads time with `os.clock()` and passes it into `Rules`; Rules never read a clock.
6. **Randomness**: only the scatter angle offset uses `Random.new()`, in `AbsorbService`, never in Rules.

## Risk Results (to be filled during implementation)

| Risk | Measured result | Decision |
| --- | --- | --- |
| Jitter when resizing a rolling sphere with welded visuals (GDD §12, R4) | Laptop, Studio solo, `Weld`, 30 visuals, 20 growth steps: resting height change 0.0034 studs, resting speed 0.003 studs/s; rolling at 15 studs/s speed error 0.029 studs/s. Reference phone: pending (T040) | `stuckVisualMode = "Weld"` |
| No-character input and default-camera behaviour (R3, R5) | No character works. Current Studio removed `GetControls():GetMoveVector()` (PlayerModule moved to `StarterPlayer`, Input Action System); reading `CharacterContext.MoveAction` gives the same vector. WASD rolls the ball without slipping at `baseSpeed` (17.9 studs/s against ω·r 18.0). The default `Custom` camera accepts the ball as `CameraSubject`; distance eases 8.0 → 8.9 with growth, no snap. Touch (Galaxy A16 in the Studio device simulator, T041): jump button 96 × 96 px bottom right passes, and `ControlModule` builds its `TouchGui` only for a player with a Humanoid, so touch movement comes from our own stick (`src/client/TouchStick.luau`, T091): drag moves the ball, release stops it, the camera does not pan from the stick | Keep no-character input, reading `MoveAction` with the legacy `GetMoveVector` as fallback (input function only); keep the default camera. `rollTorqueGain` 60 and `rollForceGain` 6 unchanged |

## Tuning Notes (round 4, T088)

- No `src/shared/Config.luau` value changed in this round. Every number still matches
  `contracts/config-and-content.md`, and `tests/unit/Config.test.luau` passes.
- Open tuning, all needing a Studio run or a playtest: `rollTorqueGain` and `rollForceGain` (T037/T079,
  ball must roll without slipping at `baseSpeed`); `stuckVisualMode` (T079, laptop JitterProbe; T040 on the
  reference phone is human-only); `respawnDelay`, `bumpSpeedThreshold` and `absorbDistanceTolerance`
  (T046, the playtest T059; multi-client T058 deferred by the owner).
- Cube layout and tier counts are unchanged from data-model §2 (research R1 and finding F-1 still apply:
  Tier 4 depends on the 15 s respawn).

## Studio Run (T079, 2026-10-25)

Solo Play in Studio driven through the Studio MCP server, with a scripted driver that feeds the real
`MoveAction`, so input, `BallController`, the remotes and the server checks all run as in play.

Defects fixed:

- No ball on the client: `Workspace.StreamingEnabled` is on (GDD) and with no character nothing set a
  streaming focus, so the client never received its ball. `BallService` now sets
  `player.ReplicationFocus` to the ball.
- No input: see Risk Results row 2 (`MoveAction` instead of `GetMoveVector`).
- The edit place still held the template `SpawnLocation` (a 12 × 1 × 12 platform raised 1 stud above
  the room floor at the centre, under the spawn ring) and the `Baseplate`. Both were removed from the
  edit DataModel; the owner must save the place to keep this.
- `JitterProbe`: it never grew the ball (an MCP `require` gets its own `BallService` instance that the
  live loop does not step), rolled into the east wall over cubes, and counted the standing-start
  friction transient as jitter. It now steps its own session, rolls on a cube-free lane from x = -32 and
  spins up before measuring.

Tuning changes (both in `contracts/config-and-content.md`):

- `absorbDistanceTolerance` 2.0 → 6.0. The server sees the client-owned ball about 0.16 s late even in
  Studio (2.9 studs at 18 studs/s, 5.1 at the 32 cap). With 2.0, every first absorb was `OutOfRange`
  (it succeeded 0.5 s later on resend) and every at-speed bump was `OutOfRange`; by the resend the
  0.35 s peak speed had dropped below 15, so knock-off never fired. Retune against real ping (R12).
- `displacementSlack` 1.5 → 4. Honest play at 18 studs/s raised `Displacement` warnings of 85 to 107
  studs/s (limit 84) about once a minute from single-frame replication snaps, rubber-banding the player.
  The limit is now 224 studs/s, about 3.7 studs in one frame, which still stops teleports (a 600 studs/s
  client teleport was caught and reverted in the same run).

Scenario results: S1 pass (first pickup at 2.0 s); S3 pass (peak speed 18.6 to 19.0 at D 2.23 against
18·√(D/2) = 19.0; camera 4 × D); S4 pass on PC (hop 1.47 studs, kerb cleared at speed, no second hop);
S5, S6, S7 pass (3 newest popped at 18.2 studs/s, D 2.100 → 2.041, re-eaten after 1.2 s; a 4 studs/s
hit changed nothing; 1 stuck → 0 and D 2.000; 0 stuck → no change); console clean (SC-007) apart from
Studio's own `ContentId 203785492` line, which no game script produces.

**Resolved: S2 and S8 (solo soft-lock), T090.** Held cubes used to stay `Taken` until knocked off, so a
solo player stopped at D ≈ 2.227 (Tier 2 needs 2.375). Following research F-1, a taken cube now respawns
after `respawnDelay` whatever a ball shows; stack entries are visual-only records with a unique key, and
knock-off, Reset and leave move a cube only if it is still pending from the same pickup (data-model §3).
Solo autopilot after the change: Tier 2 at 24 s, Tier 3 at 62 s, Tier 4 at 101 s; 248 pickups in 180 s,
never more than 30 visuals; S5 still pops 3 and lands 3; console clean.

**Resolved: Jest suite (T056, 2026-10-25).** `require(game.ServerStorage.Tests.runner)()` through the
Studio MCP runs `Tests/AbsorbService.spec`: 19 of 19 pass, 0 fail, including the six rejection cases.
The earlier load failure (`debug.loadmodule` needing `FFlagEnableLoadModule`) did not occur in this run.
The one `Speed violation` warn in the console comes from the deliberate speed-violation test case.

## Complexity Tracking

No Constitution Check violations. Nothing to justify.
