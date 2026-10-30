# Research: Mechanics Pass (006)

Phase 0 decisions. Every spec ambiguity that touches design is settled here. Numbers marked **provisional** are
starting values for the grey-box playtest; they live in `Config` and change without code edits. Gravity is
Roblox's default `Workspace.Gravity = 196.2` studs/s² (the game never changes it); rules take `g` as an argument.

## R-01: Jump physics model (tap `0.6×`, hold `0.85×`)

**Decision.** Take-off sets the ball's vertical velocity to `v0`, the speed that gives a ballistic apex of
`h1 = max(0.6·D, 1.6)` studs: `v0 = sqrt(2·g·h1)`. A hold does not add velocity; it **lowers gravity to `q`**
for at most `T = 0.25 s` while the button is held and the ball is still rising (client applies an extra upward
acceleration `g − q` each Heartbeat). `q` is solved in closed form so the apex is exactly
`h2 = max(0.85·D, 1.6·0.85/0.6 = 2.267)`:

- If the whole ascent fits inside `T` (`v0/q ≤ T`): `q = v0² / (2·h2)`.
- Else (hold ends before the apex): solve `h2 = v0·T − q·T²/2 + (v0 − q·T)² / (2g)` for `q`, a quadratic in `q`
  (smaller root).

Hand-checked values (g = 196.2):

| D | h1 | h2 | v0 | q (held) | extra accel `g − q` | ascent (tap) |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | 1.6 (floor) | 2.267 | 25.06 | 138.49 | 57.7 | 0.128 s |
| 5 | 3.0 | 4.25 | 34.31 | 138.49 | 57.7 | 0.175 s |
| 12 | 7.2 | 10.2 | 53.15 | 131.97 | 64.2 | 0.271 s |
| 30 | 18.0 | 25.5 | 84.04 | 112.14 | 84.1 | 0.428 s |
| 70 | 42.0 | 59.5 | 128.38 | 80.16 | 116.0 | 0.654 s |

These are the fixed expected values for `tests/unit/Jump.test.luau` (Principle III: hand-computed, not read from
the code under test). Tier 1 kerbs of 1.5 studs clear from `D = 2` on a tap (1.6 > 1.5).

**Why gravity relief and not extra velocity.** Peak vertical velocity stays `v0` whether tapped or held, so the
server's upward-velocity ceiling (R-03) is one number per diameter, and releasing early stops the extension
immediately with no velocity to bleed off.

**Rejected.** (a) Charged jump (delay before take-off): the owner chose an immediate hop. (b) A larger initial
impulse when the button is held: the press frame cannot know about a hold. (c) A fixed `jumpImpulse`: it is the
bug the owner reported (1.47 studs, scales with nothing).

**Round balls and obstacles.** Clearing means the ball's *bottom* rises above the obstacle top. A big ball must
also travel horizontally across the top before landing; airtime at `D = 70` is about 2.6 s, long enough at 32
studs/s. Playtest check, not a design change: if a ball of `D` still catches an obstacle exactly `0.6·D` tall, the
fix is data (`jumpClearRatio`), not code.

**Guard rails (client).** A take-off needs: run state allows rolling, a downward raycast hit within
`radius + groundProbeExtra` (existing), `now − lastJumpAt ≥ Config.jumpCooldown`, and vertical speed not already
upward from a recent jump (`vy ≤ 2`). The hold extension needs the button held continuously, `now − takeoff ≤ T`
and `vy > 0`.

## R-02: Variable-jump input on touch and keyboard

**Decision.** `JumpButton` stops using `Activated` and exposes `Pressed` and `Released` BindableEvents (from the
button's `InputBegan`/`InputEnded` for Touch and MouseButton1, so a drag off the button still releases).
`BallController` listens to those plus `UserInputService.InputBegan/Ended` for Space. Size stays 96 × 96 px
(`Config.minTouchTarget`), position unchanged, so one thumb still covers stick and jump.

**Rejected.** A second "high jump" button: breaks one-thumb play (Principle VI).

## R-03: Server vertical guard (velocity cap plus energy ceiling)

A velocity cap alone cannot catch a **mid-air second jump**: re-jumping at the apex produces `vy = v0`, which is
legal on the ground. The server therefore adds an **energy ceiling**, because ballistic flight conserves
`E = y + vy²/(2g)`.

**Decision.** `BallGuard.verticalVerdict` (pure) takes `y`, `vy`, `grounded`, `g`, the session's `airRefEnergy`,
and the limits, and returns `"Ok" | "Vertical"`:

1. Grounded (server raycast down `radius + groundProbeExtra` against `Workspace.World`): the check passes and the
   session's `airRefEnergy` is set to `y + max(vy, 0)²/(2g)`. Rolling up a ramp is grounded every step, so
   slopes, wedges and stairs never trip it.
2. Airborne: `vy ≤ upLimit` and `E ≤ airRefEnergy + apexAllowance`, where
   `apexAllowance = (h2(D) + Config.airEnergyAllowance) · Config.verticalSlack`.
   While a spring window is open, `apexAllowance` uses the spring apex (`springVerticalSpeed²/(2g)`).
3. `upLimit = max(v0(D), springVertical if window) · Config.verticalSlack`, but never below
   `ceiling · Config.maxSlopeRatio` (the horizontal ceiling times 0.5) so a Dash up a ramp is legal. The steepest
   authored ramp rises 11 over 26 studs (ratio 0.42).
4. On "Vertical": clamp `vy` to `upLimit` (keep position); on a step whose upward displacement exceeds
   `upLimit · displacementSlack · dt`, reset to `lastValidPosition` (same split as horizontal Speed vs
   Displacement). Falling is never limited; `fallRespawnY` already handles the void.

**Diameter used.** `max(authoritativeDiameter, physicalDiameter)`, because growth eases over `growTime` and the
client reads the attribute.

**Rejected.** Counting jump presses on the server (the intent never reaches the server and must not: Principle II
allows input-like remotes only, and a jump remote adds an exploitable surface for no gain).

## R-04: Horizontal ceiling with Dash and Spring

**Decision.** `BallGuard.speedCeiling(base, boostCap, boosted, inGrace)` is pure. The session is `boosted` while
`now < dashUntil` or a spring window is open, and in `grace` for `Config.boostDecayGrace` after either ends. The
server passes the result as `maxSpeed` to the existing `BallGuard.verdict` (signature unchanged, so
`BallGuard.test` keeps passing) and uses it for the clamp. Values (**provisional**): `maxServerBallSpeed = 56`
(unchanged), `dashSpeedMultiplier = 2.0` (target 36 at `D = 2`, 64 at the cap), `boostSpeedCap = 80`.
Boosted targets sit below the boosted ceiling and above the unboosted one, so a Dash is legal only while the
server has granted it, and a ball moving at 64 studs/s after the grace is clamped.

## R-05: Spring pads reach the 11-stud rooftops

Snow Village's roofs are 24 × 24 studs at `Y = 11`, centred `(0, ±100)`, each with a walk-up ramp on the inner
side. To reach a roof from the far side a ball needs its bottom above 11 at the roof edge.

Hand calculation (g = 196.2): `springVerticalSpeed = 70` gives a bottom apex of `70²/(2·196.2) = 12.49`.
With `springForwardSpeed = 40` and a pad 14 studs from the roof edge, the ball crosses the edge at
`t = 0.35 s` with height `70·0.35 − 98.1·0.35² = 12.5` (1.5 studs clear) and lands at `t ≈ 0.48 s`, about
`19.2` studs from the pad, i.e. 5 studs onto the roof. So the spring markers sit at `(0, ∓126)`, yaw facing the
roof. Launch velocity is fixed (not diameter-scaled): a Tier 4+ ball does not need the pad, and the server's
vertical envelope is `springVerticalSpeed` for `springFlightDuration = 1.5 s`.

**Who launches.** The ball is network-owned by the client, and a server write to a client-owned part's velocity
is unreliable. So the server **publishes** a `Launch` attribute on the ball and the client applies it (R-07).

## R-06: Server-authoritative claiming and the `ClaimBooster` remote

**Decision.** One new RemoteEvent, `ClaimBooster`, argument: one string (the marker ID). Handler order, every
failure silent and returned as a code (as `AbsorbService` does): single-string check → run accepts pickups →
master flag and the booster's own flag → claim rate limit (`RateLimit.allow` on a new `claimWindow`,
`Config.boosterClaimRateLimit = 4` per `rateLimitWindow`) → marker exists and is a `BoosterSpot` → available
(`takenUntil`) → in range (`ballRadius + boosterRadius + absorbDistanceTolerance`, same tolerance the absorb path
uses) → apply. Consumables (`dash`, `magnet`, `shield`, `slick_trail`) go `Taken` for `boosterRespawnDelay`
(**provisional** 20 s); `spring` stays and uses a per-session `springCooldown` (2 s). A booster that is already
active is refreshed (duration restarts), not stacked.

## R-07: One `Launch` fact for spring, bumper and sweeper

**Decision.** The ball carries a string attribute `Launch = "<seq>;<vx>;<vy>;<vz>"`. The server bumps `seq` and
sets the velocity for: a spring claim, a Bumper Post hit and a Sweeper hit. `BallController` applies each new
`seq` once (`AssemblyLinearVelocity = v`, keeping the vertical component for bounces). The server also registers
the matching guard window on the session. A client that launches itself with no window is caught by R-03/R-04.
Two users of one mechanism satisfies Principle XII.

## R-08: Magnet is a server-side drift of the object's pooled part

The server's absorb check measures from the server's copy of the part, which a client-side visual drift would not
move. So the **server moves the part**. Per magnetised ball: a 10 Hz scan (`magnetScanInterval = 0.1`) picks up
to `magnetMaxPulled = 24` nearest objects with `state == "Available"`, `availableAt` passed, absorbable by
`Absorb.canAbsorb(authoritativeDiameter, size, absorbRatio)` and within
`magnetRadiusFactor · D` (**provisional** `3.0`); each frame they step toward the ball at `magnetPullSpeed`
(**provisional** 14 studs/s). The existing client contact scan then fires the usual `Absorb` remote and
`AbsorbService.tryAbsorb` validates it exactly as before (no new trust). An object left unabsorbed when the magnet
ends is returned to its `spawnCFrame` (new `WorldSpawner.restoreHome`, which does not touch state). The pull
never targets `Taken`, `Scattered`-in-grace, or culled parts; if another ball absorbs a drifting object,
`AlreadyTaken` rejects the second request as today.

**Cost.** At most 24 anchored-part CFrame writes per magnetised ball per frame, only while a magnet is active.

## R-09: Slick trail pool

`BoosterService` owns a fixed pool (`slickTrailPoolSize = 48` parts, created on first use, never destroyed). A
ball with `trailUntil` active drops a patch each `slickTrailSpacing = 4` studs of travel (pure
`Boosters.shouldDrop`), at most `slickTrailMaxPatches = 8` alive per trail (oldest recycled), each living
`slickTrailPatchLifetime = 5 s`. Patches are anchored, `CanCollide = false`, tagged `TrapSurface`, with
attributes `Kind = "slick"`, `OwnerUserId`, `ExpiresAt`. The owner's client ignores patches whose `OwnerUserId` is
its own. Pool exhaustion recycles the oldest patch server-wide, so the part count never exceeds
48 + 16 + the world (Snow Village stays near 1,770 of 2,000).

## R-10: Slick and Slow patches are evaluated on the client

The ball's physics belong to the client (Principle II, "the client MAY own the ball's physics"). Slick (turn
multiplier) and Slow (speed multiplier) change only steering inputs the client already controls, and they carry
no progress, coins or size. The server cannot observe "steering" at all. Decision: the client reads `TrapSurface`
parts (tag, `Kind`, footprint from attributes) and applies the multipliers; the server enforces nothing here
except that no multiplier ever raises a speed (a cheat that ignores a Slow patch is just a ball at normal speed,
inside the normal ceiling). **Residual risk, accepted:** a modified client can ignore Slick/Slow. It gains
nothing the client does not already have by choosing its own input.

## R-11: Bumper Post and Street Sweeper contact is detected on the server

No new remote. `HazardService.step` (each Heartbeat) checks every active session's ball position against each
bumper post (static circle) and each sweeper (oriented rectangle at its deterministic position) using
`ballRadius + hazardRadius + hazardContactMargin (0.5)`. On contact it runs the shared knock-off decision (R-12),
publishes a `Launch` away from the hazard (`bumperBounceSpeed = 28`, `sweeperBounceSpeed = 34`, both
**provisional**, both horizontal with `vy = 0` so they sit inside the guard), and sets the ball's
`lastBumpAt`. The bumper post is also a real solid part, so it bounces the ball physically on the client even
when the server's decision is Cooldown or ShieldAbsorbed.

**Sweeper determinism.** `Patrol.position(waypoints, speed, t)` is pure and returns position and heading along a
closed loop. The server stores `Workspace:GetServerTimeNow()` at world build as `patrolEpoch`; every client
computes the same position from `GetServerTimeNow() − epoch`. The sweeper part is created once by the server and
never moved by it (a per-frame CFrame write would replicate); `HazardClient` moves its local copy each
RenderStepped. The streamed part is anchored at the loop start, and every authored loop stays well inside the
128-stud `StreamingMinRadius`. Contact on the server uses the same function, so server and client agree to
latency.

## R-12: One knock-off decision for obstacles, hazards and balls

**Decision.** A pure `Knock.decide` (in `Rules/Knock.luau`) returns one of
`"Knock" | "ShieldAbsorbed" | "Immune" | "Cooldown" | "NothingStuck"` from the stuck count, the shield state, the
victim's `immuneUntil`, `lastBumpAt` and `now`. A new server module `KnockOff.luau` calls it and, on `Knock`,
runs what `AbsorbService.tryBump` does today (pop `knockOffCount` entries, shrink, scatter with `scatterGrace`,
`RunManager.onKnockOff`). `AbsorbService.tryBump` is changed to call it, so there is one code path (two current
users plus the new ones: Principle XII). Behaviour:

- `ShieldAbsorbed`: zero popped, diameter unchanged, shield cleared, `lastBumpAt = now` (the standard
  `bumpCooldown`), no 3 s immunity.
- `Knock` from a ball-to-ball bump: victim `immuneUntil = now + ballBumpImmunitySeconds (3.0)`.
- `Knock` from an obstacle or hazard: `lastBumpAt = now` only (existing `bumpCooldown`).
- The victim's `KnockedOff` fact (camera shake) and `RunManager.onKnockOff` fire for every `Knock`.
- The attacker is untouched. Scattered objects are `Scattered` in the shared pool; after `scatterGrace` they are
  `Available` to any ball, including the attacker and the victim.

## R-13: Ball-to-ball bump detection

`HazardService.step` also checks pairs of Active-run sessions (at most 66 pairs at 12 players). Contact when
horizontal centre distance ≤ `rA + rB + ballBumpContactMargin (0.5)`. Pure rule `Knock.ballBump(dA, dB, closing,
ratio, threshold)` is true when `dA ≥ ratio · dB` (`ballBumpSizeRatio = 1.25`) and `closing ≥ bumpSpeedThreshold
(15)`. `closing = max(0, peakSpeed(A) − max(0, vB · unit(A→B)))`: A's recent peak speed (the existing
`peakSpeed` over `bumpSpeedWindow`, so a bump read just after the collision still counts) minus B's velocity
along the line, clamped. Neither ball is swallowed or removed.

## R-14: Marker schema and validation

`MarkerDef` becomes `{ id, kind, subKind, x, y, z, yaw, waypoints? }`. The existing 16 Snow Village markers
(`kind` only, no id) are given ids and sub-kinds by data edit; the 004 test that every kind has ≥ 6 spots keeps
passing. Final lineup: 8 `BoosterSpot` (dash 2, magnet 2, spring 2, shield 1, slick_trail 1) and 8 `TrapSpot`
(slick 2, bumper 2, slow 2, sweeper 2), so the part count does not grow from markers. A pure
`Rules/Markers.validate(markers, blocks, keepOutAreas, halfExtent, defs)` returns a list of error strings; it
checks unique ids, known sub-kind for the kind, in bounds, waypoint rules (sweeper needs ≥ 3, closed loop is
implied, no waypoint elsewhere), no overlap with block footprints or another marker, and a matching `marker`
keep-out per marker (plus one per sweeper path segment). Footprints come from content (`Hazards.luau`), so the
10 × 10 default keep-out grows for 16 × 16 patches. `tests/unit/SnowVillage.test.luau` currently asserts
`counts.marker == #markers`; it changes to "one per marker plus one per sweeper segment".

**Exact coordinates** are chosen by a scratch position search in the task phase (as 005 did for slots), with the
constraints above plus: spring pads at `(0, ∓126)` (R-05), sweeper loops on open lanes, and nothing on the gate and
shortcut keep-outs.

## R-15: Theme dressing is data; art is grey box

`src/shared/Content/Hazards.luau` holds `BoosterDef` / `TrapDef` rows: sub-kind, flag name, footprint, effect
numbers' Config keys, and `dressing[themeId] = { colourRole, nameKey, iconKey }` for `winter` and `city`.
Colours come from the active theme palette roles that already exist (`w-ice`/`w-season`, `w-water`, `w-sand`,
`w-accent-red`, `w-metal`, …) through `Worlds.resolved.environment.palette`, so switching `activeThemeId` re-dresses
every pickup and trap with no code change (Principle VII). The grey-box visuals are primitive parts (cylinder
bollard, flat slab patches, box sweeper, ring pickups). Meshes follow in 004c/004e; no asset is uploaded here
and `Assets.luau` only gains one stock sound (`land`).

The Street Sweeper is **not** an object: it has no row in `objects`, no `WorldObject` tag, never `snowplough`
(an absorbable Tier 4 object). A Lune test asserts that no hazard id or dressing key contains `snowplough`.

## R-16: Flags

Spec flags: `Boosters`, `BoosterDash`, `BoosterMagnet`, `BoosterSpring`, `BoosterShield`, `BoosterSlickTrail`,
`Traps`, `TrapSlick`, `TrapBumper`, `TrapSlow`, `TrapSweeper`, `BallToBallBumps`. A mechanic is live only if the
master flag **and** its own flag are true. Plan adds **`ScaledJump`** (default `true`): off keeps the 001 hop
(`Config.jumpImpulse`), because Principle VII says every new feature ships behind a flag and the spec lists none
for the jump. Flag-off checks are Lune-tested through a pure `Boosters.enabled(flags, subKind)` /
`Traps.enabled(flags, subKind)`.

## R-17: Feedback and HUD

- **Landing.** The client watches grounded → airborne → grounded; landing with `−vy ≥ landingMinSpeed`
  (**provisional** 12) plays `Assets.sounds.land` (stock `rbxasset://sounds/` clip, preloaded in `Feedback`) via
  the Effects group and a squash pulse. The squash is a client-only `SpecialMesh` (Sphere) added to the *local*
  ball and tweened `Scale (1.15, 0.8, 1.15) → 1` over `landingSquashDuration = 0.15`; physics size is untouched.
  Skipped under Reduce motion. Welded stuck objects do not squash (grey box). Needs a Studio capture to confirm a
  `SpecialMesh` on a `Shape = Ball` part renders.
- **Chips.** `EffectChips.luau` shows an icon plus a localised label for `dash`, `magnet`, `shield`,
  `slick_trail` (from ball attributes) and `slick`, `slow` (from the client's surface state), text ≥ 18 px,
  never colour or sound alone. Icon glyphs are checked in a capture under both fonts (AGENTS.md: Glyphs).

## R-18: Tuning table (all provisional, all in `Config`)

| Key | Value | Key | Value |
| --- | --- | --- | --- |
| `jumpClearRatio` | 0.6 | `dashDuration` | 3 s |
| `jumpHoldClearRatio` | 0.85 | `dashSpeedMultiplier` | 2.0 |
| `minJumpClearHeight` | 1.6 | `boostSpeedCap` | 80 |
| `jumpHoldMaxSeconds` | 0.25 | `boostDecayGrace` | 0.5 s |
| `jumpCooldown` | 0.3 s | `magnetDuration` | 6 s |
| `landingMinSpeed` | 12 | `magnetRadiusFactor` | 3.0 |
| `landingSquashScale` | 0.8 | `magnetPullSpeed` | 14 |
| `landingSquashDuration` | 0.15 | `magnetMaxPulled` | 24 |
| `verticalSlack` | 1.25 | `springVerticalSpeed` | 70 |
| `airEnergyAllowance` | 1.0 stud | `springForwardSpeed` | 40 |
| `maxSlopeRatio` | 0.5 | `springFlightDuration` | 1.5 s |
| `boosterRadius` | 2.5 | `springCooldown` | 2 s |
| `boosterRespawnDelay` | 20 s | `shieldDuration` | 15 s |
| `boosterClaimRateLimit` | 4 / s | `slickTrailDuration` | 8 s |
| `slickTurnMultiplier` | 0.25 | `slickTrailSpacing` | 4 studs |
| `slickLingerSeconds` | 0.6 s | `slickTrailMaxPatches` | 8 |
| `slowSpeedMultiplier` | 0.5 | `slickTrailPatchLifetime` | 5 s |
| `slowLingerSeconds` | 0.5 s | `slickTrailPoolSize` | 48 |
| `bumperBounceSpeed` | 28 | `sweeperSpeed` | 10 studs/s |
| `sweeperBounceSpeed` | 34 | `hazardContactMargin` | 0.5 |
| `ballBumpSizeRatio` | 1.25 | `ballBumpImmunitySeconds` | 3.0 |
| `ballBumpContactMargin` | 0.5 | `magnetScanInterval` | 0.1 s |

`knockOffCount (3)`, `bumpSpeedThreshold (15)`, `bumpCooldown (1.0)`, `scatterGrace (1.0)`,
`absorbDistanceTolerance (6.0)` and `maxServerBallSpeed (56)` already exist and are reused.
