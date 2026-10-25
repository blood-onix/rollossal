# Phase 0 Research: Grey-Box Prototype

**Feature**: `001-grey-box-prototype` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

Every `NEEDS CLARIFICATION` in the Technical Context is resolved here. Items marked **Studio-verify**
are decisions made on documented engine behaviour that the first Studio spike (task T-spike) must
confirm. Each has a named fallback, so the plan does not depend on the guess being right.

---

## R1. Cube tiers: sizes, counts and the growth maths

**Decision**: 30 cubes in 4 tiers, defined as data in `src/shared/Content/GreyBoxRoom.luau`.

| Tier | Edge `S` (studs) | Count | Unlock diameter `S / 0.4` | Unlock volume `(S/0.4)³` | Volume per pickup `0.6·S³` |
| --- | --- | --- | --- | --- | --- |
| 1 | 0.75 | 12 | 1.875 (open at start) | 6.592 | 0.253125 |
| 2 | 0.95 | 9 | 2.375 | 13.3965 | 0.514425 |
| 3 | 1.20 | 6 | 3.000 | 27.0000 | 1.036800 |
| 4 | 1.50 | 3 | 3.750 | 52.7344 | 2.025000 |

Start state: `D = 2`, `D³ = 8`. Tier 1 sits below the start limit `0.4·2 = 0.8`, so Tier 1 is
absorbable at spawn and Tiers 2 to 4 are solid obstacles (0.95, 1.2 and 1.5 are all above 0.8). The
spec's exact-boundary case (`S = 0.4·D`) is covered by unit tests, not by a room cube, so no cube
sits on a floating-point boundary.

**Hand-computed gates** (these become fixed numbers in `tests/unit`; the ball is always fed the
largest cube it can absorb):

- Tier 2 opens at `D³ ≥ 13.3965`. 21 Tier-1 pickups give `8 + 21·0.253125 = 13.3156` (D ≈ 2.370, not
  enough). 22 give `13.56875` (D ≈ 2.385, open). **22 pickups.**
- Tier 3 opens at `D³ ≥ 27`. 26 Tier-2 pickups on top of 22 Tier-1 give `13.56875 + 26·0.514425 =
  26.9438` (not enough). 27 give `27.4582` (D ≈ 3.017, open). **27 pickups.**
- Tier 4 opens at `D³ ≥ 52.7344`. 24 Tier-3 pickups give `27.4582 + 24·1.0368 = 52.3414` (not
  enough). 25 give `53.3782` (D ≈ 3.766, open). **25 pickups.**

**Finding F-1: 30 cubes cannot complete the chain in one pass.** One pass over the whole room (12 + 9 + 6
cubes before Tier 4) gives `D³ = 8 + 3.0375 + 4.6298 + 6.2208 = 21.888` (D ≈ 2.80), short of the
Tier 4 gate (3.75). The chain needs 74 pickups before the first Tier 4 cube, so the room must refill about
2.7 times. This follows from the brief's parameters: with `k = 0.6` and a 0.4 ratio, going from one
gate to the next by a size ratio `ρ` needs about `26·(ρ³ − 1)` pickups of the current tier. Backlog
Part F allows "respawns or more cubes, record why". **Decision: keep 30 cubes (spec FR-023) and rely on
`respawnDelay = 15 s`.** This needs every taken cube to respawn while a ball still shows it, so stack
entries are visual-only records (data-model §3, T090). Measured solo after T090: Tier 2 at 24 s, Tier 3
at 62 s, Tier 4 at 101 s.

Expected solo timeline with a player who eats everything absorbable (about 1.4 pickups/s in a 72×72
room): Tier 2 opens at about 35 s, Tier 3 at about 70 s, Tier 4 at about 105 s to 120 s. That is inside
"a couple of minutes" for a solo run (SC-003). With 6 players sharing 30 cubes each player sees about
one sixth of the supply, so chain completion is a solo measure and the 6-player test is a fun test.

**Alternatives considered**:

- *Tighter ladder (0.75, 0.85, 0.95, 1.05) so one pass completes.* Rejected: a 1.4× size range between
  the smallest and largest cube is unreadable, and the ball would only grow to D ≈ 2.7. That does not
  test growth feel.
- *More cubes (for example 16/10/6/3).* Rejected for now: the spec fixes 30. The counts are data, so the
  playtest can change them without code changes (Constitution VII).
- *Shorter respawn.* Kept as the first tuning lever (`Config.respawnDelay`), not a plan change.

---

## R2. Bump detection: server touch or verified client report

**Decision**: the client reports contact with an unabsorbable cube, `Bump(objectId)`. The server decides
using its own measurements. The client sends only the cube ID, never a speed.

Server checks, in order: the argument is a string; the player is under the rate limit; the cube exists
and is not taken; distance within `ballRadius + size/2 + absorbDistanceTolerance`; the per-player bump
cooldown `bumpCooldown = 1 s` has passed; and `Rules.Absorb.isKnockOff` is true for the server's
authoritative diameter, the cube size, and the **peak speed the server measured over the last
`bumpSpeedWindow = 0.35 s`** (it needs the cube to be too big and the speed to exceed
`bumpSpeedThreshold`). If all pass, pop up to 3 entries (an empty stack is a no-op).

**Rationale**: for a client-owned part the server only sees replicated, slightly late state. Its `Touched`
events can fire late or twice, and the velocity at the moment of `Touched` is already the
post-collision velocity, so "relative speed at touch" under-reads. A rolling window of the server's own
velocity samples (taken every Heartbeat in `BallService`, which it needs anyway for the speed check)
captures the speed just before impact and cannot be forged. This follows Constitution II: remotes carry
only a target ID.

**Alternatives considered**:

- *Server `Touched` plus `AssemblyLinearVelocity`.* Rejected for the reasons above, and because
  `Touched` on a replicated client-owned assembly is unreliable.
- *Client reports its own impact speed.* Rejected: forbidden by Constitution II.

---

## R3. Reading movement input with the avatar hidden

**Decision**: remove the character. Set `Players.CharacterAutoLoads = false` in `default.project.json`.
The ball is the only thing a player controls. `BallController` reads
`PlayerModule:GetControls():GetMoveVector()` (the ControlModule), converts it to a camera-relative world
direction with the flattened `CurrentCamera.CFrame`, and normalises it.

**Rationale**: no character means no avatar to hide, no humanoid physics, and nothing to leak. The brief
(§3.1) names `Humanoid.MoveDirection` but the spec (FR-019) allows the ControlModule when the character
is removed. `GetMoveVector()` returns the thumbstick or WASD vector regardless of a humanoid.

**Studio-verify**: that the touch thumbstick and WASD still work with no character. **Fallback**: spawn
a hidden character (`CharacterAutoLoads = true`, transparent, collision-less, root anchored out of
play) and read `Humanoid.MoveDirection`. Only `BallController`'s input function changes.

**R3 Studio result** (2026-10-25): no character works, but `GetMoveVector()` is gone in current Studio.
The PlayerModule now lives under `StarterPlayer` (not `PlayerScripts`), is driven by the Input Action
System, and its public API exposes only `ControlModule.Enabled`. `BallController` therefore reads
`StarterPlayer.PlayerModule.InputContexts.CharacterContext.MoveAction` (a `Direction2D` action bound to
keyboard, gamepad and both touch thumbsticks; W gives `(0, 1)`) and converts it to the legacy convention
`(x, 0, -y)`. If that action is missing it falls back to the legacy `GetControls():GetMoveVector()`.
Only the input function changed, as the fallback rule required. WASD verified; the touch thumbstick
with no character still needs a phone or emulator check (T080).

**Related**: with no character the Roblox menu's Reset button does nothing, so the client binds
`StarterGui:SetCore("ResetButtonCallback", bindable)` and sends the argument-less `RespawnBall` intent
(server cooldown 3 s). This covers the "player resets" edge case. A ball that falls below
`fallRespawnY` is respawned by the server.

---

## R4. StuckVisuals: weld or client follower (the risk this feature must prove)

**Decision**: stuck visuals are **client-side parts built by `StuckVisuals` for every ball**, from the
replicated state (R10). They never exist on the server, so welds add no server physics cost. Two modes
share one module, selected by `Config.stuckVisualMode`:

- `"Weld"` (default, the brief's design): each visual has `CanCollide = false`, `Massless = true`, and a
  legacy `Weld` (`Part0 = ball`, `Part1 = visual`). Growth re-seats a visual by updating `Weld.C1`, not
  the part's `CFrame`.
- `"Follower"` (the documented fallback): no weld; each `RenderStepped` sets
  `visual.CFrame = ball.CFrame * offset(r)`.

Both place a visual at `ballLocalDirection * (r + S * embedFraction)` where `r` is the ball's current
physical radius, so the cube stays on the surface as the ball grows.

**Why `Weld` and not `WeldConstraint`**: writing `CFrame` on a part held by a `WeldConstraint` moves the
whole assembly, so a constraint cannot be re-seated on growth. A legacy `Weld` exposes `C0/C1`.

**Why both modes exist**: the brief says Feature 1 must *prove* welds do not jitter, and the backlog
says to switch to followers if they do. Both are current users of the module, which is the minimum for
the abstraction (Constitution XII). The switch is a one-line Config change.

**Measurement protocol (the evidence for the decision, recorded in this file's R4 result below)**: see
`quickstart.md` §Jitter measurement. In short: a Studio script grows a ball 20 times through the real
pipeline with 30 visuals attached, while the ball rolls at a steady speed and while it rests. It logs the
peak frame-to-frame deviation of the ball's height and speed. Pass if rest height deviation is below
0.05 studs and speed deviation is below 1 stud/s during growth. Check it on a laptop and on the
reference phone.

**R4 result** (laptop, Studio solo, 2026-10-25): `"Weld"` passes. Resting with 30 visuals and 20 growth
steps: ball height change 0.0034 studs per frame, speed 0.003 studs/s. Rolling at 15 studs/s through
20 growth steps: speed error 0.029 studs/s, height change 0.0035 studs. All 30 visuals stayed attached
on the client. **`stuckVisualMode = "Weld"`** stays. The reference-phone run (T040) is still owed.

**Alternatives considered**:

- *Server-side welded parts.* Rejected: 30 server parts per player replicated to everyone, welded to a
  client-owned assembly, with ownership and re-seating problems on every growth step.
- *`WeldConstraint`.* Rejected (above).

---

## R5. Camera

**Decision**: use Roblox's default `Custom` camera with `CameraSubject = ball`. `CameraController`
smooths the follow distance and applies it by writing `LocalPlayer.CameraMinZoomDistance` and
`CameraMaxZoomDistance` to the same smoothed value each frame:
`d += (Rules.Movement.cameraDistance(D) − d) · (1 − exp(−cameraSmoothing · dt))`.

**Rationale**: the default camera already gives drag-to-orbit on mouse and touch, collision avoidance,
and a follow behaviour, which the grey-box needs for steering on both PC and phone. A hand-written chase
camera would also need its own touch orbit input, which is not in scope.

**Studio-verify**: the default camera accepts a `BasePart` subject without a character, and changing the
zoom limits each frame does not snap. **Fallback**: a `Scriptable` camera at fixed pitch that orbits
with drag input. Only `CameraController` changes.

---

## R6. Ball physics: driving and resizing

**Decision**:

- The server builds the ball: `Part`, `Shape = Ball`, `CustomPhysicalProperties(density 1, friction 0.8,
  elasticity 0, 1, 1)`, an `Attachment`, and an `AngularVelocity` (`RelativeTo = World`, goal zero,
  `MaxTorque` set by the client from `rollTorqueGain · mass · r²`). The server grants
  `SetNetworkOwner(player)`.
- The client drives it. Each frame, with direction `d` (unit, horizontal) and target speed
  `v = Rules.Movement.targetSpeed(D)`: `AngularVelocity = Y × d · (v / r)` (rolling without slipping)
  plus `ApplyImpulse(d · mass · rollForceGain · dt)` as the small forward force. With no input, the goal
  is zero angular velocity and the ball coasts and brakes by friction.
- **Resizing**: the authoritative diameter is set at once as the `Diameter` attribute. The physical
  `Size` is eased by the server over `growTime = 0.25 s` (Heartbeat steps), so each frame's change is
  small and the solver depenetrates smoothly. Visuals and camera read the physical size.
- `jumpImpulse = 24` is a vertical velocity change in studs/s, applied as `ApplyImpulse(Y · mass ·
  jumpImpulse)` when grounded. Hop height is `24² / (2·196.2) ≈ 1.47` studs, which clears the room's
  1.0-stud kerb. Grounded means a downward raycast of `r + groundProbeExtra` hits the room's static
  geometry. Not grounded means no jump, so there is no double jump.

**Rationale**: matches brief §3.1. `rollTorqueGain`, `rollForceGain` and the physical properties are
tuning values; their first numbers are set in the Studio spike and live in Config.

---

## R7. Making absorbable cubes passable and big cubes solid

**Decision**: cubes are anchored server parts. Each client sets `CanCollide` **locally** on each cube
every 0.1 s: `false` if the cube is absorbable for the local ball's authoritative diameter or is taken,
`true` otherwise. The ball is simulated by its owner's client, so the local setting is what matters for
that ball's physics.

**Rationale**: the server needs no per-player collision state, and the 30-cube loop is trivial.
Without it, absorbable cubes would bounce the ball away before it could touch them.

**Studio-verify**: other players' balls (simulated on their own clients) collide correctly. Taken cubes
are hidden (`Transparency = 1`, `CanCollide = false`, `CanTouch = false`) by the server, and the
server only writes `CanCollide = true` on respawn.

---

## R8. Detecting contact and sending requests (client)

**Decision**: with only 30 cubes, `BallController` loops over the cube registry each Heartbeat, with no
spatial query. For each cube not marked `Taken`, if the centre distance is at most
`r + S/2 + clientContactMargin (0.3)`, it sends `Absorb(id)` (if absorbable) or `Bump(id)` (if not). A
per-cube pending flag (0.5 s) and a client send budget below the server limit (8/s) avoid spamming.
Rejections are silent: two players racing for one cube is normal and must not log (SC-007).

---

## R9. Tooling: Rojo, `scripts/check.sh`, Lune, CI

- **Rojo tree**: as FR-003, plus `Players.CharacterAutoLoads = false` and `tests/studio` mapped to
  `ServerStorage.Tests` (never replicated to clients, never run automatically).
- **`scripts/check.sh`** (fail-fast, `set -euo pipefail`): `stylua --check src tests scripts`,
  `selene src tests`, `rojo sourcemap default.project.json --output sourcemap.json`, `luau-lsp analyze`
  on `src` and `tests/studio` with the Roblox definitions file, `lune run tests/unit/run` (this also
  analyses `tests/unit` with Lune type definitions from `lune setup`), then the Rules guard.
- **Rules guard**: `grep -nE` on `src/shared/Rules/**/*.luau` for the forbidden word list (word-bounded:
  `Instance`, `workspace`, `game`, `task`, `math.random`, `os.clock`, `os.time`, `tick`, `DateTime`,
  `Vector3`, `CFrame`, `GetService`, `Enum`, `require(script`). Fail on any hit. Comments are not
  exempt, so Rules files avoid those words even in prose. A unit-level negative test in
  `scripts/test-guard.sh` writes a bad file to a temp dir and expects the guard to fail (this proves
  story 4 scenario 2 without dirtying the tree).
- **Rules modules are standalone** (no `require` between them). Lune resolves requires by file path and
  Roblox by `script.Parent`, so a Rules file that requires another would need two code paths. Each
  Rules file gets its parameters as arguments instead.
- **Lune tests**: a ~40-line `tests/unit/harness.luau` (`test`, `expect.near`, `expect.equal`) and one
  `*.test.luau` per Rules module plus `Config.test.luau` and `GreyBoxRoom.test.luau`. Expected numbers
  are written out by hand. No new test library (Constitution XII).
- **CI** (`.github/workflows/check.yml`): `actions/checkout` (first-party), then install Rokit by
  downloading the pinned release `rojo-rbx/rokit v1.2.0` binary with `curl`, then `rokit install`, then
  `wally install`, then `scripts/check.sh`. No third-party action is used, so no new service needs
  approval. The luau-lsp definitions file is downloaded from the `luau-lsp` repository at the pinned
  tag `1.70.1`, and the filename is confirmed during setup (**Studio-verify** equivalent for CI).
- **Jest-Lua in Studio**: `tests/studio/runner.luau` calls `Jest.runCLI` against the spec modules. It is
  started through the Studio MCP server (`execute_luau`: `require(game.ServerStorage.Tests.runner)()`).
  CI cannot run Studio, so CI covers everything in `scripts/check.sh` only.

---

## R10. Replicated state and how clients draw other players' balls

**Decision**: the server publishes two attributes on each ball and nothing else:

- `Diameter` (number): the authoritative diameter.
- `Stuck` (string): the visible tail of the stuck stack, oldest first, entries separated by `;`, each
  `id,dx,dy,dz` where `(dx,dy,dz)` is the contact direction in the ball's local space, quantised to
  2 decimals. At most 30 entries (about 600 characters).

Cube size and tier come from the cube's own replicated attributes (`Size`, `Tier`), which are also in
`Content`. `StuckVisuals` on every client builds the same visuals for every ball from these attributes.
When `Stuck` changes, it diffs against the current list: new entries appear, missing ones are removed.
This one mechanism handles absorb, the 31st-object eviction and knock-off.

**Rationale**: attributes replicate to late joiners with no extra code, and the cost is one short string
per pickup.

---

## R11. Server structure

**Decision**: `WorldSpawner` (named as in brief §9) builds the room from Content and owns the cube
registry and the respawn loop. `BallService` owns ball sessions and the Heartbeat speed check.
`AbsorbService` owns the `Absorb`, `Bump` and `RespawnBall` remotes and the validation. `Remotes` creates
the three RemoteEvents. Validation is a pure-style function `AbsorbService.tryAbsorb(session, objectId,
now)` that returns a result code, so Jest-Lua tests call it directly with a stub session instead of faking
a network call. The remote handler is a thin wrapper around it.

---

## R12. Items that remain tuning values, not unknowns

- `absorbDistanceTolerance = 2.0` versus ping: at 18 studs/s, 100 ms of replication delay is 1.8
  studs, and at 25 studs/s it is 2.5. If the playtest shows honest pickups being rejected, raise the
  value (the spec calls it an assumption). The playtest records the rejection count.
- `bumpSpeedThreshold = 15` versus `baseSpeed = 18`: full-speed contact at the start size is above the
  threshold, grazing contact at under 15 is not. Tuned in the playtest.
- `respawnDelay = 15 s` shared across 6 players, see R1 finding F-1.
- Reference phone: the spec's Galaxy A53/A54-class assumption stands until the owner names another
  device at sign-off (`TODO(REFERENCE_PHONE)`).
