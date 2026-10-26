# Contract: `src/shared/Rules` additions (pure API)

Four new standalone modules next to the five from 001. No `require` between them, no Roblox APIs, no time or
randomness (time is passed in). All files start with `--!strict`. Every function has Lune tests with the
hand-computed values below; none is produced by running the code. `scripts/check.sh` already greps this folder
for forbidden identifiers.

## `Stars.luau`

```lua
stars(diameter: number, thresholds: { number }): number
-- count of thresholds t with diameter >= t (thresholds ascending). Returns 0..#thresholds.
```

| Input | Expected |
| --- | --- |
| `stars(19.99, {20,45,80})` | `0` |
| `stars(20, {20,45,80})` | `1` |
| `stars(44.99, {20,45,80})` | `1` |
| `stars(45, {20,45,80})` | `2` |
| `stars(79.99, {20,45,80})` | `2` |
| `stars(80, {20,45,80})` | `3` |
| `stars(2.99, {3,4,5})` | `0` |
| `stars(3, {3,4,5})` | `1` |
| `stars(4, {3,4,5})` | `2` |
| `stars(5, {3,4,5})` | `3` |
| `stars(1000, {3,4,5})` | `3` |
| `stars(7, {})` | `0` |

## `Tiers.luau`

```lua
export type TierLike = { minDiameter: number }

lookup(diameter: number, tiers: { TierLike }): (number, number?)
-- (index, nextThreshold): index of the last tier with minDiameter <= diameter, or 1 if below the first;
-- nextThreshold = tiers[index + 1].minDiameter, or nil on the top tier.
-- The tier record is tiers[index]; the caller indexes it (returning it again adds nothing).

progress(diameter: number, tiers: { TierLike }): number
-- 1 on the top tier; otherwise (diameter - min[i]) / (min[i+1] - min[i]) clamped to 0..1.
```

Tests use `minDiameter = { 2, 2.375, 3, 3.75 }`:

| Input | Expected `(index, next)` |
| --- | --- |
| `lookup(1.5, …)` | `(1, 2.375)` |
| `lookup(2, …)` | `(1, 2.375)` |
| `lookup(2.374, …)` | `(1, 2.375)` |
| `lookup(2.375, …)` | `(2, 3)` |
| `lookup(2.999, …)` | `(2, 3)` |
| `lookup(3, …)` | `(3, 3.75)` |
| `lookup(3.75, …)` | `(4, nil)` |
| `lookup(100, …)` | `(4, nil)` |

| Input | Expected `progress` |
| --- | --- |
| `progress(1.5, …)` | `0` |
| `progress(2, …)` | `0` |
| `progress(2.1875, …)` | `0.5` |
| `progress(2.6875, …)` | `0.5` |
| `progress(3.375, …)` | `0.5` |
| `progress(3.75, …)` | `1` |
| `progress(9, …)` | `1` |

If luau-lsp strict rejects passing `{ SizeTierDef }` where `{ TierLike }` is expected (array invariance), the
call site in `Worlds` builds the `{ TierLike }` list once; the rule's signature does not change.

## `Coins.luau`

```lua
export type Options = {
	friendBonusRate: number,
	hasFriendInServer: boolean,
	hasDoubleCoins: boolean,
	friendBoostRate: number,
	friendBoostCount: number,
}

total(absorbedCoinValues: { number }, options: Options): number
-- base  = sum(values)
-- a     = base * (hasFriendInServer ? 1 + friendBonusRate : 1)
-- b     = a * (1 + friendBoostRate * friendBoostCount)
-- c     = b * (hasDoubleCoins ? 2 : 1)
-- return math.floor(c + 0.5)
```

Values never decrease because the list is append-only; a knock-off cannot call into this module.

Tests use `values = {1, 2, 3, 5}` (base 11), `friendBonusRate = 0.2`, `friendBoostRate = 0.25` unless stated:

| Case | Expected |
| --- | --- |
| `{}` with every multiplier on | `0` |
| base 11, no multipliers | `11` |
| friend only (13.2) | `13` |
| boost count 2 only (11 × 1.5 = 16.5) | `17` |
| double only | `22` |
| friend + boost count 1 + double (13.2 → 16.5 → 33) | `33` |
| `{5}`, boost count 2 (7.5, half rounds up) | `8` |
| `{1,1,1}`, friend (3.6) | `4` |
| `{1}`, friend (1.2) | `1` |
| boost count 0 equals no boost | `11` |

## `RunClock.luau`

```lua
remaining(now: number, endsAt: number): number    -- max(0, endsAt - now)
expired(now: number, endsAt: number): boolean     -- now >= endsAt
format(seconds: number): string                   -- "mm:ss" of ceil(max(0, seconds))
```

| Input | Expected |
| --- | --- |
| `remaining(10, 250)` | `240` |
| `remaining(300, 250)` | `0` |
| `expired(249.999, 250)` | `false` |
| `expired(250, 250)` | `true` |
| `format(240)` | `"04:00"` |
| `format(239.2)` | `"04:00"` |
| `format(239)` | `"03:59"` |
| `format(61)` | `"01:01"` |
| `format(60.5)` | `"01:01"` |
| `format(59.01)` | `"01:00"` |
| `format(0.4)` | `"00:01"` |
| `format(0)` | `"00:00"` |
| `format(-3)` | `"00:00"` |
| `format(600)` | `"10:00"` |
