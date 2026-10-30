# Contract: Pure Rules API (006)

All modules are in `src/shared/Rules`, start with `--!strict`, use no Roblox API, no `require(script`, no clock
and no random. Gravity `g`, time, positions and Config values are arguments. Each has a Lune test in `tests/unit`
with hand-computed expected values (never read from the code under test).

## `Rules/Jump.luau`

```lua
Jump.tapApex(d: number, p: JumpTuning): number            -- max(clearRatio·d, minClear)
Jump.holdApex(d: number, p: JumpTuning): number           -- max(holdRatio·d, minClear·holdRatio/clearRatio)
Jump.takeoffSpeed(d: number, g: number, p: JumpTuning): number          -- sqrt(2·g·tapApex)
Jump.holdGravity(d: number, g: number, holdSeconds: number, p: JumpTuning): number   -- q, R-01
Jump.upLimit(d: number, g: number, ceiling: number, springVy: number?, p: JumpTuning): number
Jump.apexAllowance(d: number, springVy: number?, g: number, p: JumpTuning): number
Jump.canTakeOff(grounded: boolean, now: number, lastJumpAt: number, vy: number, cooldown: number): boolean
```

`JumpTuning = { clearRatio, holdClearRatio, minClear, holdMaxSeconds, verticalSlack, airEnergyAllowance,
maxSlopeRatio }` (the matching Config keys; the caller builds it).

Fixed test values (g = 196.2; research R-01):

| D | tapApex | holdApex | takeoffSpeed | holdGravity q |
| --- | --- | --- | --- | --- |
| 2 | 1.6 | 2.267 | 25.06 | 138.49 |
| 5 | 3.0 | 4.25 | 34.31 | 138.49 |
| 12 | 7.2 | 10.2 | 53.15 | 131.97 |
| 30 | 18.0 | 25.5 | 84.04 | 112.14 |
| 70 | 42.0 | 59.5 | 128.38 | 80.16 |

Tolerance 0.01. Also: `canTakeOff` false when airborne, inside cooldown, or `vy > 2`; `holdGravity ≤ g` for all
five diameters; the 1.5-stud kerb is cleared at D = 2 (`tapApex 1.6 > 1.5`).

## `Rules/BallGuard.luau` (additions; `verdict` and `stepSpeed` unchanged)

```lua
BallGuard.speedCeiling(base: number, boostCap: number, boosted: boolean, inGrace: boolean): number
  -- boosted or inGrace → boostCap, else base

BallGuard.verticalVerdict(input: {
  y: number, vy: number, grounded: boolean, g: number,
  airRefEnergy: number, upLimit: number, apexAllowance: number,
}): ("Ok" | "Vertical", number)     -- verdict, new airRefEnergy
```

Rules: grounded → `Ok` and `airRefEnergy = y + max(vy,0)²/2g`. Airborne → `Vertical` if `vy > upLimit` or
`y + vy²/2g > airRefEnergy + apexAllowance` (for `vy ≥ 0` only; falling never fails). Tests: a tap and a held
jump at all five diameters stay `Ok` along a simulated arc; a second take-off at the apex is `Vertical`; a spring
arc is `Ok` only with the spring `upLimit`; rolling up a 0.42 ramp is `Ok`; `speedCeiling` returns 56 / 80 for the
four boolean combinations as expected.

## `Rules/Boosters.luau`

```lua
Boosters.enabled(flags: { [string]: boolean }, subKind: string): boolean     -- master and own flag
Boosters.endsAt(now: number, duration: number): number
Boosters.isActive(now: number, until_: number): boolean
Boosters.magnetPick(ballPos, diameter, candidates, p): { string }   -- ids of ≤ magnetMaxPulled nearest eligible
Boosters.shouldDrop(travelled: number, spacing: number): boolean
Boosters.trailExpire(now: number, droppedAt: number, lifetime: number): boolean
Boosters.dashTarget(baseSpeed: number, multiplier: number, cap: number): number
```

Candidate: `{ id, pos, size, available: boolean }`. Eligible when `available`, `size ≤ absorbRatio · diameter`, and
inside `magnetRadiusFactor · diameter`; nearest first. Tests: obstacles (`size > 0.4·D`) never picked; the cap of
24; `enabled` false when either flag is off; `dashTarget(18, 2.0, 80) = 36` and `dashTarget(45, 2.0, 80) = 80`.

## `Rules/Traps.luau`

```lua
Traps.enabled(flags, subKind): boolean
Traps.speedMultiplier(slowActive: boolean, mult: number): number     -- never > 1
Traps.turnMultiplier(slickActive: boolean, mult: number): number      -- never > 1
Traps.surfaceActive(now: number, insideNow: boolean, untilT: number, linger: number): (boolean, number)
Traps.insideRect(px, pz, cx, cz, halfW, halfD, yaw): boolean
```

Tests: multipliers are exactly `0.5` and `0.25` active and `1` otherwise; linger extends `untilT` to `now +
linger` while inside and holds it after leaving; rotated-rect containment at 0° and 90°.

## `Rules/Knock.luau`

```lua
Knock.decide(i: { now, stuckCount, shieldUntil, immuneUntil, lastBumpAt, bumpCooldown }):
  "Knock" | "ShieldAbsorbed" | "Immune" | "Cooldown" | "NothingStuck"
Knock.ballBump(dA: number, dB: number, closing: number, ratio: number, threshold: number): boolean
Knock.closingSpeed(peakA: number, vBAlongLine: number): number     -- max(0, peakA − max(0, vB))
```

Tests: each of the five results; `Immune` beats everything; a shield with 0 stuck is `ShieldAbsorbed`;
`ballBump(5, 4, 20, 1.25, 15) = true`, `ballBump(5, 4.1, 20, 1.25, 15) = false` (ratio 1.22), `ballBump(5, 4, 14.9,
…) = false`; `closingSpeed(30, -5) = 30`, `closingSpeed(30, 12) = 18`.

## `Rules/Patrol.luau`

```lua
Patrol.length(waypoints: { Vec2 }): number
Patrol.position(waypoints: { Vec2 }, speed: number, t: number): { x: number, z: number, heading: number }
```

Closed loop, `t` wraps by `length / speed`. Tests on a 20 × 20 square at speed 10: `t = 0 → (0,0)`, `t = 1 →
(10,0)`, `t = 2 → (20,0)`, `t = 3 → (20,10)`, `t = 8 → (0,0)`, `t = 9 = t = 1`; heading along each side.

## `Rules/Markers.luau`

```lua
Markers.validate(markers, blocks, keepOutAreas, halfExtent, defs): { string }
```

`defs` is `Content/Hazards` (footprints). Errors start with the prefixes in `data-model.md`. Tests: a valid set
returns `{}`; one malformed marker per rule returns exactly one error with that prefix; the Snow Village set
returns `{}` for both `winter` and `city`.
