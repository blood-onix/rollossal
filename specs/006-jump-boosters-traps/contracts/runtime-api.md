# Contract: Runtime API (006)

Server and client surfaces. Remotes carry input-like data only; the server decides.

## Remote: `ClaimBooster` (client → server)

`ReplicatedStorage.Remotes.ClaimBooster`, RemoteEvent. Total Remotes: 13 (was 12).

| Arg | Type | Meaning |
| --- | --- | --- |
| 1 | `string` | marker id (`MarkerDef.id`) |

Extra or missing arguments, or any non-string, are dropped silently. Handler order (first failing check
returns; no reply, as `Absorb`):

1. one argument, a string of length 1–40;
2. `RunManager.acceptsPickups(player)`;
3. `Boosters.enabled(Config.Flags, subKind)`;
4. `RateLimit.allow(session.claimWindow, now, Config.boosterClaimRateLimit, Config.rateLimitWindow)`;
5. marker exists and is a `BoosterSpot`;
6. available (`state == "Available"`, or for spring `now ≥ springCooldownUntil`);
7. `distance ≤ ballRadius + boosterRadius + absorbDistanceTolerance`.

Result codes (returned from `BoosterService.tryClaim`, for tests; never sent): `Ok`, `BadArgs`, `NotActive`,
`Disabled`, `RateLimited`, `UnknownMarker`, `Unavailable`, `OutOfRange`.

No other remote is added. Jump input, surfaces and hazard contact never cross the network as client claims.

## Server modules

### `BoosterService`

```lua
BoosterService.start()
BoosterService.tryClaim(player: Player, markerId: unknown): string            -- result code above
BoosterService.step(dt: number)                                               -- Heartbeat
BoosterService.clearSession(player: Player)                                   -- run end / reset / leave
BoosterService.activeFor(player: Player): { dash: number, magnet: number, shield: number, trail: number }
```

`step` expires effects, publishes `Boost*` attributes, drifts magnet-pulled parts (10 Hz scan, per-frame step),
restores parts on expiry through `WorldSpawner.restoreHome`, lays and recycles slick-trail patches, and respawns
`Taken` markers. Spring: on claim, bumps the ball's `Launch` seq with `(forward · springForwardSpeed, springVerticalSpeed)`
and opens `springUntil = now + springFlightDuration`.

### `HazardService`

```lua
HazardService.start()
HazardService.step(dt: number)                       -- Heartbeat
HazardService.patrolEpoch(): number
HazardService.hazards(): { HazardInstance }
```

Detects bumper, sweeper and ball-to-ball contact, then calls `KnockOff`. Publishes `Launch` away from the hazard
(`bumperBounceSpeed`, `sweeperBounceSpeed`, `vy = 0`). Builds nothing for a flag-off trap.

### `KnockOff`

```lua
KnockOff.apply(player: Player, source: "obstacle" | "bumper" | "sweeper" | "ball", now: number): string
  -- the Knock.decide result; on "Knock" pops knockOffCount, shrinks, scatters, calls RunManager.onKnockOff
```

`AbsorbService.tryBump` becomes a wrapper: validate the `Bump` remote as today (speed window, threshold,
obstacle size ratio, range), then `KnockOff.apply(player, "obstacle", now)`. Behaviour for an unshielded
non-immune ball is identical to today's.

### `BallService` changes

- `Session` gains the fields in `data-model.md`.
- `step` computes `ceiling = BallGuard.speedCeiling(...)`, runs `BallGuard.verdict` with it (signature unchanged),
  then `BallGuard.verticalVerdict`; "Vertical" clamps `vy` to `upLimit` and, on an upward displacement above
  `upLimit · displacementSlack · dt`, resets to `lastValidPosition`.
- Grounded test: server raycast down `radius + groundProbeExtra` against `Workspace.World`.
- `resetBall`, `startRun`, run end and fall respawn call `BoosterService.clearSession`.

### `WorldSpawner`

`WorldSpawner.restoreHome(id: string)`: moves a pooled part back to its `spawnCFrame`; touches no state.

### `WorldBuilder`

Builds one part per marker whose flag is on: booster rings (anchored, `CanCollide = false`, tag `BoosterSpot`,
attribute `MarkerId`, `SubKind`), surface patches (`TrapSurface`, `Kind`, `HalfX`, `HalfZ`, `Yaw`), bumper posts
(solid, tag `TrapHazard`) and the sweeper (solid, anchored at the loop start, tag `TrapHazard`, attributes
`MarkerId`, `PatrolEpoch`). Colours come from `Worlds.resolved.environment.palette` through the dressing role.

## Ball attributes (server → everyone)

`Launch` (`"seq;vx;vy;vz"`), `BoostDash`, `BoostMagnet`, `BoostShield`, `BoostTrail` (server time the effect ends,
`0` if none). Set on the ball part with `SetAttribute`. Read-only for clients.

## Client modules

### `JumpButton`

```lua
JumpButton.create(parent: ScreenGui): { Pressed: BindableEvent, Released: BindableEvent, destroy: () -> () }
```

96 × 96 px at least; `Pressed` on `InputBegan` (Touch, MouseButton1), `Released` on `InputEnded` or when the
input leaves. The old `Activated` event is removed.

### `BallController` (additions)

- Press: if `Flags.ScaledJump` is off, the 001 hop (`Config.jumpImpulse`); else, if `Jump.canTakeOff(...)`, set
  `AssemblyLinearVelocity.Y = Jump.takeoffSpeed(D, g, p)` and start the hold window.
- Heartbeat while held and `vy > 0` and `now − takeoffAt ≤ jumpHoldMaxSeconds`: add upward acceleration
  `g − holdGravity`.
- On a new `Launch` seq: set `AssemblyLinearVelocity` from the attribute once.
- Surfaces: each frame test the ball against `TrapSurface` parts (other owners' trail patches only) with
  `Traps.insideRect`; apply `speedMultiplier` to the target speed and `turnMultiplier` to steering.
- Dash: target speed from `Boosters.dashTarget` while `BoostDash > GetServerTimeNow()`.
- Landing: airborne → grounded with `−vy ≥ landingMinSpeed` calls `Feedback.land()`.

### `Feedback`

`Feedback.land()`: plays `Assets.sounds.land` through the Effects `SoundGroup`; tweens the local squash
(`landingSquashScale`, `landingSquashDuration`) unless Reduce motion is on. `preloadSounds` includes `land`.

### `HazardClient`

`HazardClient.start()`: each RenderStepped, for every part tagged `TrapHazard` with `PatrolEpoch`, set its CFrame
from `Patrol.position(waypoints, speed, GetServerTimeNow() − epoch)`. Waypoints come from the part's attributes
(`Wp1X`, `Wp1Z`, …) set by `WorldBuilder`.

### `EffectChips`

`EffectChips.create(parent: Frame): { update: () -> () }`. One chip per active effect among `dash`, `magnet`,
`shield`, `slick_trail` (ball attributes) and `slick`, `slow` (surface state). Icon from `Icons`, label from
`Strings`, text size ≥ 18 px, never colour alone. Hosted by `Hud`.

## Studio spec coverage (FR-011)

- `BoosterService.spec`: every refusal code above; flag-off; rate limit; respawn after `boosterRespawnDelay`;
  shield interaction; trail pool never exceeds 48.
- `HazardService.spec`: bumper and sweeper knock; shield consumed; `Cooldown`; ball bump with size ratio, 3 s
  immunity, re-collection by the attacker and a third player after `scatterGrace`.
- `BallService.spec`: tap and held arcs produce no violation; mid-air re-jump and vertical teleport reset; Dash
  accepted under `boostSpeedCap` and clamped above it; unboosted above 56 flagged.
- `Remotes.spec`: 13 events; `ClaimBooster` rejects non-string, no-arg and extra-arg calls.
