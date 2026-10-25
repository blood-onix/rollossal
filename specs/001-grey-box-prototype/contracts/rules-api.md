# Contract: `src/shared/Rules` (pure API)

Five standalone modules. No `require` between them, no Roblox APIs, no time or randomness (time is
passed in). Parameters such as ratio and `k` are passed as arguments from `Config`, so the unit tests can
use fixed numbers without importing Config. Every function has Lune tests with hand-computed expected
values (FR-011). All files start with `--!strict`.

The numbers below are the hand-computed values the tests assert; none is produced by running the code.

## `Absorb.luau`

```lua
canAbsorb(diameter: number, size: number, ratio: number): boolean
-- size <= ratio * diameter

isKnockOff(diameter: number, size: number, impactSpeed: number, ratio: number, threshold: number): boolean
-- not canAbsorb(diameter, size, ratio) and impactSpeed > threshold
```

| Test | Input | Expected |
| --- | --- | --- |
| equal passes | `canAbsorb(2, 0.8, 0.4)` | `true` |
| just above fails | `canAbsorb(2, 0.8001, 0.4)` | `false` |
| tier 1 at start | `canAbsorb(2, 0.75, 0.4)` | `true` |
| tier 2 at start | `canAbsorb(2, 0.95, 0.4)` | `false` |
| tier 2 gate | `canAbsorb(2.375, 0.95, 0.4)` | `true` |
| knock-off at speed | `isKnockOff(2, 0.95, 16, 0.4, 15)` | `true` |
| speed equal to threshold | `isKnockOff(2, 0.95, 15, 0.4, 15)` | `false` |
| absorbable cube never knocks off | `isKnockOff(2, 0.75, 40, 0.4, 15)` | `false` |

## `Growth.luau`

```lua
growDiameter(diameter: number, size: number, k: number): number
-- (D^3 + k * size^3) ^ (1/3)

shrinkDiameter(diameter: number, sizes: { number }, k: number, floor: number): number
-- max(floor, (D^3 - k * sum(size^3)) ^ (1/3)), computed as max(floor^3, D^3 - k*sum) before the root
```

| Test | Input | Expected |
| --- | --- | --- |
| first tier 1 pickup | `growDiameter(2, 0.75, 0.6)` | `8.253125 ^ (1/3)` = 2.0209 (±1e-4) |
| tier 4 pickup at D=3.75 | `growDiameter(3.75, 1.5, 0.6)` | `54.759375 ^ (1/3)` = 3.7975 (±1e-4) |
| 22 tier 1 pickups | repeated `growDiameter` from 2 | `13.56875 ^ (1/3)` = 2.3851 (±1e-3), and ≥ 2.375 |
| 21 tier 1 pickups | same, 21 times | `13.315625 ^ (1/3)` = 2.3703, and < 2.375 |
| shrink by one tier 2 | `shrinkDiameter(3, {0.95}, 0.6, 2)` | `(27 − 0.514425) ^ (1/3)` = 2.9808 (±1e-3) |
| shrink clamps | `shrinkDiameter(2.05, {1.5, 1.5, 1.5}, 0.6, 2)` | `2` exactly |
| shrink at floor stays | `shrinkDiameter(2, {0.75}, 0.6, 2)` | `2` exactly |
| empty list | `shrinkDiameter(3, {}, 0.6, 2)` | `3` |

## `Movement.luau`

```lua
targetSpeed(diameter: number, baseSpeed: number, startDiameter: number, exponent: number, cap: number): number
-- min(cap, baseSpeed * (diameter / startDiameter) ^ exponent)

cameraDistance(diameter: number, multiplier: number, minDistance: number, maxDistance: number): number
-- clamp(multiplier * diameter, minDistance, maxDistance)
```

| Test | Input | Expected |
| --- | --- | --- |
| speed at start | `targetSpeed(2, 18, 2, 0.5, 32)` | `18` |
| speed at D=8 | `targetSpeed(8, 18, 2, 0.5, 32)` | `32` (the uncapped value is 36) |
| speed at D=4.5 | `targetSpeed(4.5, 18, 2, 0.5, 32)` | `18 × 1.5 = 27` |
| camera at start | `cameraDistance(2, 4, 8, 80)` | `8` |
| camera mid | `cameraDistance(5, 4, 8, 80)` | `20` |
| camera floor clamp | `cameraDistance(1, 4, 8, 80)` | `8` |
| camera ceiling clamp | `cameraDistance(30, 4, 8, 80)` | `80` |

## `StuckStack.luau`

Generic over the entry type (`T`), so it needs no knowledge of `StuckEntry`.

```lua
push<T>(stack: { T }, entry: T, cap: number): { T }          -- returns a new list; drops oldest above cap
popRecent<T>(stack: { T }, n: number): ({ T }, { T })        -- (remaining, removed newest-last)
visibleTail<T>(stack: { T }, maxVisible: number): { T }
```

Tests: push 31 onto cap 30 drops the first; `popRecent` of 3 from 5 returns the last three and leaves
two; `popRecent` of 3 from 2 returns both; `popRecent` from empty returns two empty lists;
`visibleTail` of 40 with max 30 returns entries 11 to 40 in order; inputs are not mutated.

## `RateLimit.luau`

```lua
allow(timestamps: { number }, now: number, limit: number, window: number): (boolean, { number })
-- drop entries with t <= now - window; if count < limit then append now and return true
```

Tests: 10 calls at `now = 100.0, 100.05, …` all allowed; the 11th at `100.5` is refused; a call at
`101.06` is allowed after the oldest entries age out (window boundary: an entry at exactly `now − window`
is dropped); refused calls do not append.
