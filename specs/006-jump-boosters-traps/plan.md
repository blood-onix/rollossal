# Implementation Plan: Mechanics Pass — Scaled Jump, Boosters, and Season-Neutral Traps

**Branch**: `006-jump-boosters-traps` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-jump-boosters-traps/spec.md`

## Summary

Make the default mode richer before polish and before outside people test it: a jump that clears obstacles at
every tier, five boosters, four season-neutral traps, and ball-to-ball bumps. Everything is grey box on Snow
Village and every mechanic ships behind a flag. Four strands, in dependency order:

1. **Pure rules, Config and tests (Luau, Lune-tested)**. New `Rules/Jump`, `Boosters`, `Traps`, `Knock`,
   `Patrol` and `Markers`; `Rules/BallGuard` gains `verticalVerdict`, `speedCeiling` and an energy ceiling
   `E = y + vy²/2g` so the server can tell a legitimate tap, hold or spring from a mid-air re-jump. `Config` gains
   the tuning table (research R-18) and the flags.
2. **Server (Roblox, Studio-checked)**. `BoosterService` (claim, active state, magnet drift, slick-trail pool),
   `HazardService` (bumper, sweeper, ball-to-ball contact), a shared `KnockOff` that `AbsorbService.tryBump`
   now calls, a vertical guard in `BallService.step`, and one new remote, `ClaimBooster` (one string).
3. **Client**. `JumpButton` emits press and release; `BallController` runs the variable jump, applies the
   server's `Launch` fact, reads slick and slow surfaces and plays landing feedback; `HazardClient` moves the
   sweeper's local copy; `EffectChips` shows each active effect (icon plus text, never colour alone).
4. **Content, markers and strings**. `Content/Hazards.luau` holds the booster and trap rows with `winter` and
   `city` dressing; `MarkerDef` becomes structured (`id`, `subKind`, `yaw`, `waypoints`); Snow Village gets 8
   `BoosterSpot` and 8 `TrapSpot` markers covering every kind (the part count does not grow); every string in
   en and es.

Player swallowing stays out of the default mode. Nothing is sold. The owner approved the maturity scope
(ball-to-ball knock-offs, 3 s victim immunity) on 2026-10-30; it is recorded in the spec's Owner Approval Gate.

## Technical Context

**Language/Version**: Luau (`--!strict`, Roblox, Rojo 7.7.1, luau-lsp strict). No Python or Blender work.

**Primary Dependencies**: none new. Existing Rokit toolchain (StyLua, Selene, luau-lsp, Lune 0.10.x, Rojo),
Jest-Lua in `tests/studio`, Roblox Studio MCP.

**Storage**: none. Booster, trap and immunity state is per run and per session in memory; nothing is persisted
(Profile schema untouched). Run end, reset and respawn clear it.

**Testing**: Lune unit tests in `tests/unit` (new `Jump`, `Boosters`, `Traps`, `Knock`, `Patrol`, `Markers`;
extended `BallGuard`, `Config`, `SnowVillage`, `Strings`); Jest-Lua specs in `tests/studio` (new
`BoosterService`, `HazardService`; extended `BallService` and `Remotes`); agent-driven Studio playtest and
captures; the owner's sign-off in `playtest.md`.

**Target Platform**: Roblox, mobile first (30 fps on the mid-range reference phone), 12 players per server.

**Project Type**: Roblox game (single Rojo project).

**Performance Goals**: ≥ 30 fps in a 640 × 360 Studio capture with every mechanic live; at most 24 magnet part
writes per magnetised ball per frame; at most 66 ball pairs checked per frame; one sweeper copy moved per client
per sweeper (2).

**Constraints**: `src/shared/Rules` has no Roblox API, no `require(script…)` and no clock or random (time,
gravity and positions are arguments); active server parts stay under 2,000 (Snow Village is at about 1,702;
this feature adds at most 16 marker visuals' worth already counted, plus 48 trail patches and 16 sweeper and
bumper parts, so about 1,770); remotes carry input-like data only; every string in en and es; boosters are never
sold; the sweeper never uses `snowplough`.

**Scale/Scope**: 6 new rule modules; 3 new server modules; 2 new client modules; 1 new content module; 1 new
remote; 12 new flags (+ `ScaledJump`); about 45 new Config keys; 16 markers re-authored; about 30 new strings.

## Constitution Check

*GATE: passed before Phase 0; re-checked after Phase 1 (below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | Pass | Everything is primitive parts on Snow Village. SC-004 and the quickstart require an agent Studio run and the owner's sign-off in `specs/006-jump-boosters-traps/playtest.md` before 004c polish. All tuning is in `Config`, so playtest changes are data. |
| II Server authority | Pass | One new remote, `ClaimBooster(string)`, validated in order (type, run, flags, rate limit, marker, availability, range). Hazard and ball-bump contact are detected on the server with no remote. Dash, spring, shield and immunity live on the server session; a vertical energy guard and a boosted speed ceiling replace "trust the client". Slick and Slow are client-evaluated by design (R-10): they only change the client's own steering and can never raise a speed. |
| III Pure, tested rules | Pass | `Jump`, `Boosters`, `Traps`, `Knock`, `Patrol`, `Markers` and the `BallGuard` additions are pure; gravity, time and positions are arguments. Each has a Lune test with hand-computed values (Jump table in research R-01). `scripts/check.sh` purity grep unchanged. |
| IV Safe for everyone | Pass | Owner approved ball-to-ball knock-offs ("cartoon bumping") and the 3 s victim immunity on 2026-10-30. No damage, health, death or loss of coins and book progress; scattered objects return to the shared pool; no player swallowing. The sweeper is a municipal machine with no driver, never the absorbable snowplough. |
| V Ethical monetization | Pass | Nothing here is sold or gated by Robux. A Lune test asserts no booster or trap row has a price field and `Config.Flags` has no product id. |
| VI Mobile first | Pass | Jump button stays 96 × 96 px and one-thumb (press and release, not a second button); the slick trail lays itself; effect chips are icon plus text ≥ 18 px; landing squash is skipped under Reduce motion; 30 fps capture at 640 × 360. |
| VII Content is data | Pass | `Hazards.luau` rows plus per-theme dressing; markers are world data validated by `Rules/Markers`; 12 spec flags plus `ScaledJump`, each checked with the master flag. Switching `activeThemeId` re-dresses with no code change. |
| VIII Player data | Pass | No profile, DataStore or schema change. Effects are session-only. |
| IX Strings | Pass | Booster and trap names, chip labels and the knock-off hint go in `Strings.luau` (en, es); `Strings.test` extended. |
| X Multi-agent | Pass | Own branch. `[P]` tasks touch disjoint files (Delivery order). Studio tasks claim "Studio" in `tasks.md` and are done by the agent through the MCP. No live publish. |
| XI Asset pipeline | Pass | No mesh, atlas or upload. Grey-box visuals are primitive parts coloured from the active theme palette; `Assets.luau` gains only one stock `rbxasset://` sound (`land`). |
| XII Keep it lean | Pass | No new tool or package. The two shared mechanisms each have ≥ 2 users: `KnockOff` (obstacle bump, bumper, sweeper, ball bump) and the `Launch` attribute (spring, bumper, sweeper). See Complexity Tracking. |

**Human Approval Required**: the maturity-questionnaire item (ball-to-ball bumps) is already approved in the
spec. If it were reversed, `BallToBallBumps` defaults to off with one Config edit and no code change.

### Post-design re-check (after Phase 1)

Unchanged: all rows still pass. Points checked against the design: (a) `Patrol.position` takes `t` as an argument
and the server and client both pass `GetServerTimeNow() − epoch`, so the rule stays clock-free; (b) `Knock.decide`
takes `now` and the shield and immunity state as arguments; (c) the `Launch` attribute carries only a velocity the
server computed, so the client cannot invent one, and the guard windows (R-03, R-04) catch a client that launches
itself; (d) the new remote has exactly one argument and the same silent-failure style as `Absorb`.

## Spec deviations to confirm

These resolve conflicts between the spec text and the code or the constitution. None changes an owner decision.
D1 and D2 need a one-line spec edit if accepted.

- **D1: a `ScaledJump` flag is added.** The spec lists flags for boosters, traps and bumps but none for the jump,
  while Principle VII says every new feature ships behind a flag. `Flags.ScaledJump` defaults to `true`; off
  restores the 001 hop (`Config.jumpImpulse`).
- **D2: `Remotes` grows from 12 to 13 events.** `ClaimBooster` is the only addition (FR-005). The docstring and
  the `Remotes.spec` count are updated.
- **D3: the 10 × 10 marker keep-out grows with the footprint.** FR-009 and 004's rule give each marker a 10 × 10
  `marker` rect. A 16 × 16 slick patch or a sweeper loop does not fit in it, so keep-outs come from
  `Hazards.luau` footprints, plus one rect per sweeper path segment. `SnowVillage.test` changes from
  `counts.marker == #markers` to "one per marker plus one per sweeper segment".
- **D4: `w-ice` does not exist in `tokens.json`.** FR-006 names it for the winter slick patch. The plan uses
  `w-water` (ice) and `w-season`; adding a role means regenerating the atlas, which is outside this feature.
- **D5: Slick and Slow are evaluated on the client** (R-10). The spec says "the ball is affected"; the ball's
  physics belong to the client (Principle II), so the server enforces nothing here. The accepted residual risk is
  that a modified client can ignore a patch and gain nothing it could not get by steering.
- **D6: `Assets.sounds.land` is a stock `rbxasset://sounds/` clip.** FR-003 wants a preloaded thump; no upload is
  allowed in this feature, and Studio-streamed sounds are checked for `IsLoaded` in Play (AGENTS.md).
- **D7: the Dash multiplier and every other number are provisional.** FR-004 names the keys; R-18 lists the
  starting values. They are playtest inputs.
- **D8: spring pads sit at `(0, ∓126)`, 14 studs from the roof edge,** facing each Y = 11 rooftop (R-05). The
  exact marker coordinates for the other kinds are chosen by a scratch position search in the task phase.

## Project Structure

### Documentation (this feature)

```text
specs/006-jump-boosters-traps/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R-01 … R-18
├── data-model.md        # Phase 1: entities, fields, validation, state
├── quickstart.md        # Phase 1: how to prove it end to end
├── contracts/
│   ├── rules-api.md           # Pure Rules signatures and fixed test values
│   ├── runtime-api.md         # ClaimBooster, ball attributes, services, client modules
│   └── content-and-config.md  # Config keys, Flags, MarkerDef, Hazards rows, Strings, Icons
├── playtest.md          # Owner sign-off (created during implementation, Principle I)
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
src/shared/
├── Config.luau                               # tuning table (R-18), Flags (+13), claim rate limit
├── Assets.luau                               # + sounds.land (stock rbxasset)
├── Content/
│   ├── Hazards.luau                          # NEW: BoosterDef / TrapDef rows + per-theme dressing
│   ├── Icons.luau                            # + dash, magnet, spring, shield, slick, slow glyphs
│   ├── GreyBoxRoom.luau                      # MarkerDef: id, subKind, yaw, waypoints
│   └── Worlds/SnowVillage.luau               # 16 markers re-authored; keep-outs per footprint
├── Rules/
│   ├── Jump.luau                             # NEW: v0, hold gravity q, apex, upLimit, cooldown
│   ├── Boosters.luau                         # NEW: enabled, durations, magnet pick, shouldDrop
│   ├── Traps.luau                            # NEW: enabled, speed and turn multipliers, linger
│   ├── Knock.luau                            # NEW: decide, ballBump
│   ├── Patrol.luau                           # NEW: position(waypoints, speed, t)
│   ├── Markers.luau                          # NEW: validate
│   └── BallGuard.luau                        # + verticalVerdict, speedCeiling (verdict unchanged)
└── Localization/Strings.luau                 # + booster, trap and chip strings (en, es)

src/server/
├── BoosterService.luau                       # NEW: claim, active state, magnet drift, trail pool
├── HazardService.luau                        # NEW: bumper, sweeper, ball-to-ball contact; patrol epoch
├── KnockOff.luau                             # NEW: shared knock-off executor over Rules/Knock
├── AbsorbService.luau                        # tryBump calls KnockOff
├── BallService.luau                          # vertical guard, boosted ceiling, Session fields
├── WorldBuilder.luau                         # builds booster and trap parts from markers
├── WorldSpawner.luau                         # + restoreHome (magnet release)
├── Remotes.luau                              # + ClaimBooster
├── RunManager.luau                           # clears effects on run end and reset
└── Main.server.luau                          # starts the two services

src/client/
├── JumpButton.luau                           # Pressed / Released instead of Activated
├── BallController.luau                       # variable jump, Launch, surfaces, landing
├── HazardClient.luau                         # NEW: moves local sweeper copies from server time
├── EffectChips.luau                          # NEW: icon + label chips
├── Feedback.luau                             # landing sound, preload
├── Hud.luau                                  # hosts EffectChips
└── Main.client.luau                          # starts the two client modules

tests/unit/    Jump, Boosters, Traps, Knock, Patrol, Markers (new); BallGuard, Config, SnowVillage, Strings (extended)
tests/studio/  BoosterService.spec, HazardService.spec (new); BallService.spec, Remotes.spec (extended)
```

**Structure Decision**: extend the single Rojo project in place. New logic goes in `src/shared/Rules`
(Lune-tested), data in `src/shared/Content`, Roblox-only code in `src/server` and `src/client`. The server owns
every fact that matters (claims, shield, immunity, knock-offs, sweeper contact); the client owns the ball's
physics and applies only server-published facts (`Launch`, `Boost*` attributes).

## Delivery order and parallelism

Tasks are generated by `/speckit-tasks`; this is the dependency spine they follow.

| # | Slice | Files (disjoint → `[P]`-safe) | Needs |
| --- | --- | --- | --- |
| 1 | Config keys and flags | `Config.luau`, `Config.test` | – |
| 2 | Jump and guard rules | `Rules/Jump`, `Rules/BallGuard`, `Jump.test`, `BallGuard.test` | 1 `[P]` internally |
| 3 | Booster, trap, knock, patrol rules | `Rules/Boosters`, `Traps`, `Knock`, `Patrol` and their tests | 1; `[P]` with 2 |
| 4 | Marker schema, `Hazards.luau`, `Markers` rule | `GreyBoxRoom.luau`, `Content/Hazards.luau`, `Rules/Markers`, `Markers.test` | 1 |
| 5 | Snow Village markers and keep-outs | `SnowVillage.luau`, `SnowVillage.test` | 4 |
| 6 | Strings, Icons, Assets | `Strings.luau`, `Icons.luau`, `Assets.luau`, `Strings.test` | – `[P]` with 2–5 |
| 7 | Server: vertical guard, `KnockOff`, `AbsorbService` refactor | `BallService`, `KnockOff`, `AbsorbService`, `BallService.spec` | 2, 3 |
| 8 | Server: boosters, remote | `BoosterService`, `Remotes`, `WorldSpawner`, `WorldBuilder`, `Main.server`, `BoosterService.spec` | 3, 4, 5, 7 |
| 9 | Server: hazards and ball bumps | `HazardService`, `HazardService.spec` | 3, 7 `[P]` with 8 |
| 10 | Client: jump, launch, surfaces, landing | `JumpButton`, `BallController`, `Feedback` | 2, 6 `[P]` with 8–9 |
| 11 | Client: chips and sweeper | `EffectChips`, `HazardClient`, `Hud`, `Main.client` | 6, 9 `[P]` with 10 |
| 12 | Studio proof: Jest specs, flag toggles, `winter` ⇄ `city`, 640 × 360 captures, fps | `tests/studio/*`, `captures/` | 8–11; **Studio claim**, 🔒 tasks |
| 13 | Owner sign-off | `playtest.md` | 12, owner |

## Complexity Tracking

Three choices that could look like speculative abstraction, kept because each has a concrete current use.

| Choice | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| Shared `KnockOff` module over `Rules/Knock.decide` | Obstacle bump, bumper post, sweeper and ball bump all pop, shrink, scatter and notify the run identically, and each needs shield, cooldown and immunity decided the same way. | Copying `AbsorbService.tryBump` into `HazardService` leaves four diverging copies of the most exploit-prone path in the game. |
| `Launch` attribute (`"seq;vx;vy;vz"`) | Spring, bumper and sweeper all must change a client-owned ball's velocity. | A server write to a client-owned part's velocity is unreliable; three bespoke remotes would add surface for nothing. |
| Energy-ceiling vertical guard (`E = y + vy²/2g`) | A velocity cap cannot catch a second jump at the apex (`vy = v0` is legal on the ground). | Counting jump presses needs a jump remote, which Principle II forbids as a new attack surface with no gain. |
