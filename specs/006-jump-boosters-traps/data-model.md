# Data Model: Mechanics Pass (006)

Entities, fields, validation and state. Types are Luau (`--!strict`). "Pure" means it lives in `src/shared/Rules`
(no Roblox API, no clock, no random). Numbers are `Config` keys (research R-18); none are hard-coded here.

## Jump

### JumpParams (pure, derived from diameter `D` and gravity `g`)

| Field | Formula | Notes |
| --- | --- | --- |
| `tapApex` | `max(jumpClearRatio · D, minJumpClearHeight)` | `0.6·D`, floor 1.6 studs |
| `holdApex` | `max(jumpHoldClearRatio · D, minJumpClearHeight · jumpHoldClearRatio / jumpClearRatio)` | `0.85·D`, floor 2.267 |
| `takeoffSpeed` (`v0`) | `sqrt(2·g·tapApex)` | vertical velocity set on the press frame |
| `holdGravity` (`q`) | R-01 closed form (whole ascent inside `T`) or the quadratic root (hold ends first) | `q < g`; the client adds `g − q` upward while held |
| `upLimit` | `max(v0, springVerticalSpeed if window) · verticalSlack`, never below `ceiling · maxSlopeRatio` | server vertical-velocity cap |
| `apexAllowance` | `(holdApex + airEnergyAllowance) · verticalSlack` (spring apex while a window is open) | server energy headroom |

Validation: `D > 0`, `g > 0`; the hold never lowers `q` below `0`; `q ≤ g` always (a hold can only help).

### Client jump state (per local ball, not replicated)

`lastJumpAt: number`, `takeoffAt: number?`, `holding: boolean`, `wasGrounded: boolean`, `lastLandingVy: number`.

Transitions: `Grounded --press & cooldown ok & vy ≤ 2--> Rising(held)`; `Rising --release | now−takeoffAt > T |
vy ≤ 0--> Rising(unheld)`; `Rising/Falling --ground ray hit--> Grounded` (plays landing feedback if `−vy ≥
landingMinSpeed`).

## Boosters

### BoosterDef (content row, `Content/Hazards.luau`)

| Field | Type | Notes |
| --- | --- | --- |
| `subKind` | `"dash" \| "magnet" \| "spring" \| "shield" \| "slick_trail"` | unique key |
| `flag` | string | the booster's own `Config.Flags` key, e.g. `BoosterDash` |
| `consumable` | boolean | `true`: goes `Taken` for `boosterRespawnDelay`; `false` (spring): per-session cooldown |
| `radius` | number | claim footprint, `boosterRadius` default |
| `durationKey` | string? | Config key for the duration (`dashDuration` …); `nil` for spring |
| `dressing` | `{ [themeId]: Dressing }` | see below; `winter` and `city` required |

No price, product id or Robux field exists on any row (Principle V; Lune-tested).

### ActiveBoosterState (server `Session` additions, in `BallService.Session`)

| Field | Meaning |
| --- | --- |
| `dashUntil: number` | `0` when inactive |
| `magnetUntil: number` | |
| `shieldUntil: number` | cleared early by the next `Knock` decision of `ShieldAbsorbed` |
| `trailUntil: number`, `trailLastPos: Vector3?`, `trailDropped: number` | slick-trail laying |
| `springUntil: number`, `springVy: number` | spring launch window; `springVy` sets `upLimit` |
| `springCooldownUntil: number` | per-session pad cooldown |
| `boostGraceUntil: number` | `max(dashUntil, springUntil) + boostDecayGrace` |
| `airRefEnergy: number` | `E` reference from the last grounded step (R-03) |
| `claimWindow: RateLimit.Window` | `boosterClaimRateLimit` per `rateLimitWindow` |
| `immuneUntil: number` | ball-to-ball victim immunity (R-12) |

All reset in `BallService` on `resetBall`, run end, fall respawn and `startRun`.

### Booster marker instance (server, in `BoosterService`)

`{ markerId, subKind, position: Vector3, state: "Available" | "Taken", takenUntil: number, part: Part }`.

Transitions: `Available --valid claim--> Taken --boosterRespawnDelay--> Available`; spring never enters `Taken`.
An active booster that is claimed again is refreshed (duration restarts), never stacked.

### Ball attributes (replicated facts, set by the server)

| Attribute | Type | Meaning |
| --- | --- | --- |
| `Launch` | string `"seq;vx;vy;vz"` | applied once per new `seq` by the owner's client (R-07) |
| `BoostDash` | number | server time the Dash ends, `0` if none (client target speed, chip) |
| `BoostMagnet` | number | server time the Magnet ends |
| `BoostShield` | number | server time the Shield ends |
| `BoostTrail` | number | server time the slick-trail ends |

Clients read these for chips and the dash target speed. They cannot widen the server's guard.

### Slick-trail patch (pooled `Part`, `slickTrailPoolSize = 48`)

Anchored, `CanCollide = false`, tag `TrapSurface`, attributes `Kind = "slick"`, `OwnerUserId: number`,
`ExpiresAt: number`, `HalfX`, `HalfZ`. Recycled oldest-first when the pool or the per-trail cap
(`slickTrailMaxPatches = 8`) is full. The owner's client skips its own patches.

## Traps

### TrapDef (content row, `Content/Hazards.luau`)

| Field | Type | Notes |
| --- | --- | --- |
| `subKind` | `"slick" \| "bumper" \| "slow" \| "sweeper"` | |
| `flag` | string | `TrapSlick` … |
| `footprint` | `{ w: number, d: number }` | studs; drives the marker keep-out (D3) |
| `surface` | boolean | `slick` and `slow` are surface patches (client-evaluated) |
| `knocks` | boolean | `bumper` and `sweeper` run the knock-off rule |
| `dressing` | `{ [themeId]: Dressing }` | `winter` and `city` required |

### Dressing

`{ colourRole: string, nameKey: string, iconKey: string }`. `colourRole` is a `w-*` palette role present in
`tokens.json` (`w-water`, `w-season`, `w-sand`, `w-accent-red`, `w-metal`, `w-glow`, …). `w-ice` does not exist
(D4). `nameKey` and `iconKey` resolve in `Strings` and `Icons`.

### HazardInstance (server, in `HazardService`)

`{ markerId, subKind, part: Part, centre: Vector3, radius or halfExtents, waypoints: { Vector2 }?, speed }`.
Static hazards never move. The sweeper part is created once at the loop start; only clients move their copy
(R-11). `patrolEpoch: number` is `Workspace:GetServerTimeNow()` taken at world build.

### SurfaceState (client, not replicated)

`{ slickUntil: number, slowUntil: number }` per local ball: set while the ball is inside a patch footprint and
extended by `slickLingerSeconds` / `slowLingerSeconds` after leaving. Multipliers come from `Rules/Traps`.

## Knock-off decision (pure)

`Knock.decide(input) -> "Knock" | "ShieldAbsorbed" | "Immune" | "Cooldown" | "NothingStuck"`

Input: `{ now, stuckCount, shieldUntil, immuneUntil, lastBumpAt, bumpCooldown }`. Order of checks:

1. `now < immuneUntil` → `Immune`.
2. `now − lastBumpAt < bumpCooldown` → `Cooldown`.
3. `now < shieldUntil` → `ShieldAbsorbed` (checked before `NothingStuck`: a shield is spent by any qualifying hit).
4. `stuckCount == 0` → `NothingStuck`.
5. otherwise `Knock`.

`Knock.ballBump(dA, dB, closing, ratio, threshold) -> boolean` is true when `dA ≥ ratio · dB` and
`closing ≥ threshold`.

Side effects (in `KnockOff`, not in the rule): `Knock` pops `knockOffCount` entries, shrinks the diameter (never
below `startDiameter`), scatters with `scatterGrace`, calls `RunManager.onKnockOff`; a ball-to-ball `Knock` also
sets `immuneUntil = now + ballBumpImmunitySeconds`. `ShieldAbsorbed` clears `shieldUntil` and sets `lastBumpAt =
now`. The attacker is never touched.

## Patrol (pure)

`Patrol.position(waypoints, speed, t) -> { x, z, heading }` along the closed loop (last waypoint joins the
first). `t` is `GetServerTimeNow() − patrolEpoch`, wrapped by loop length / speed. Segments of zero length are
rejected by `Markers.validate`.

## MarkerDef (world data, `GreyBoxRoom.luau`)

```lua
export type MarkerDef = {
	id: string,                       -- unique within the world, e.g. "booster-dash-1"
	kind: string,                     -- "BoosterSpot" | "TrapSpot"
	subKind: string,                  -- one of the nine sub-kinds
	x: number, y: number, z: number,
	yaw: number,                      -- degrees; spring pads face the roof
	waypoints: { { x: number, z: number } }?,   -- sweeper only, ≥ 3, closed loop implied
}
```

### Validation (`Rules/Markers.validate` → `{ string }`, empty means valid)

| Rule | Error text starts with |
| --- | --- |
| `id` non-empty and unique | `marker id` |
| `kind` is `BoosterSpot` or `TrapSpot` | `marker kind` |
| `subKind` known and matches `kind` | `marker subKind` |
| centre and footprint inside `halfExtent` | `marker bounds` |
| no overlap with a block footprint (excluding the ground) or another marker | `marker overlap` |
| `sweeper` has ≥ 3 waypoints, all inside bounds, no zero-length segment; no other kind has waypoints | `marker waypoints` |
| a matching `marker` keep-out per marker, sized to its footprint, plus one per sweeper segment | `marker keepout` |
| all nine sub-kinds present across the world | `marker coverage` |

Counts for Snow Village: 8 `BoosterSpot` (dash 2, magnet 2, spring 2, shield 1, slick_trail 1) and 8 `TrapSpot`
(slick 2, bumper 2, slow 2, sweeper 2).

## Flags (`Config.Flags`)

`ScaledJump`, `Boosters`, `BoosterDash`, `BoosterMagnet`, `BoosterSpring`, `BoosterShield`, `BoosterSlickTrail`,
`Traps`, `TrapSlick`, `TrapBumper`, `TrapSlow`, `TrapSweeper`, `BallToBallBumps`. A mechanic is live only if its
master flag (where one exists) and its own flag are `true` (`Boosters.enabled`, `Traps.enabled`). A flag-off
booster or trap is not built and its claim is refused.

## State summary

| Event | Effect on session |
| --- | --- |
| Valid claim | sets the booster's `…Until`, publishes `Boost*`, spring also publishes `Launch` and opens a guard window |
| Knock decision | may clear `shieldUntil`; sets `lastBumpAt`; ball bump sets `immuneUntil` |
| Run end, Roll again, hub, reset, fall respawn | every field above reset; trail patches owned by that run expire at once; magnet-drifted parts restored home |
| Theme switch | no session state; dressing re-resolved at world build |
