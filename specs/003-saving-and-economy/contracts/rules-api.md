# Contract: Pure rules API (`src/shared/Rules`)

Three new standalone modules and one addition. No `require`, no Roblox API, no clock, no randomness
(Constitution III). Bounds, defaults and reward lookups enter as arguments. Every test value below is
written out by hand and goes into `tests/unit` as a fixed expectation. Reminder: the words `game`, `task`,
`Enum`, `Instance`, `workspace`, `tick` must not appear in these files, even in comments.

## `Profile.luau`

```lua
export type SettingsData = {
	musicVolume: number, effectsVolume: number, cameraSensitivity: number,
	reduceMotion: boolean, language: string,
}
export type Data = {
	version: number, coins: number,
	worldsUnlocked: { [string]: boolean }, skinsOwned: { [string]: boolean },
	equipped: { skin: string?, trail: string? },
	book: { [string]: boolean }, bestSize: { [string]: number },
	receipts: { string }, appliedRuns: { [string]: boolean },
	settings: SettingsData,
}
export type Defaults = { worldsUnlocked: { [string]: boolean }, settings: SettingsData }
export type RunLike = {
	runId: string, worldId: string, finalDiameter: number, coins: number, newBookIds: { string },
}
export type Outcome = {
	applied: boolean, reason: string?, isFirstRun: boolean, coinsGained: number, coinsTotal: number,
	bestSize: number, newBookIds: { string }, newRewardIds: { string },
}
export type Migrations = { [number]: (data: { [string]: any }) -> () }

Profile.SCHEMA_VERSION: number                         -- 1
Profile.migrations: Migrations                         -- {} at v1 (nothing to migrate from)

Profile.defaults(defaults: Defaults): Data             -- fresh deep copy on every call
Profile.reconcile(data: { [string]: any }, defaults: Defaults): ()          -- in place
Profile.migrate(data, migrations: Migrations, target: number): (boolean, string?)   -- in place
Profile.prepare(data: { [string]: any }, defaults: Defaults): (boolean, string?)    -- in place
Profile.applyRunResult(data: Data, result: RunLike, rewardsFor: (book: { [string]: boolean }) -> { string }): Outcome
```

**`defaults`** returns `version = 1`, `coins = 0`, `worldsUnlocked` copied from the argument,
`skinsOwned = {}`, `equipped = {}`, `book = {}`, `bestSize = {}`, `receipts = {}`, `appliedRuns = {}`,
`settings` copied from the argument. Two calls return distinct tables.

**`reconcile`** fills a missing key with the default, replaces a wrong-typed key with the default
(`coins` must be a finite number ≥ 0; `version` is left alone, `migrate` owns it), reconciles `settings`
field by field with the same rule, and never recurses into `worldsUnlocked`, `skinsOwned`, `book`,
`bestSize` or `appliedRuns` beyond requiring that each is a table. Valid saved values are never changed.

**`migrate`** runs `migrations[v](data)` for `v = data.version … target - 1`, setting `data.version = v + 1`
after each. Returns `false, "BadVersion"` when `version` is not a finite integer ≥ 1, `false,
"FutureVersion"` when it exceeds `target`, `false, "MissingMigration"` when a step has no function; `data` is
left as it was at the failing step.

**`prepare`** = (empty table: `version` becomes `SCHEMA_VERSION` and `reconcile` fills the rest) or
(`migrate(data, Profile.migrations, SCHEMA_VERSION)`, then `reconcile`), then `data.appliedRuns = {}`
(plan finding F-2). Returns `true`, or the failure from `migrate`.

**`applyRunResult`** order (nothing is written before the checks pass):

1. `Invalid` when `runId` is not a non-empty string, `worldId` not a non-empty string, `finalDiameter` not a
   finite number > 0, `coins` not a finite number, or `newBookIds` not an array of strings.
2. `Duplicate` when `data.appliedRuns[runId] == true`.
3. `isFirstRun = next(data.bestSize) == nil`.
4. `coinsGained = max(0, floor(coins))`; `data.coins += coinsGained`.
5. `data.bestSize[worldId] = max(data.bestSize[worldId] or 0, finalDiameter)`.
6. For each id in `newBookIds` not yet in `book`: `book[id] = true`, append to `Outcome.newBookIds`.
7. For each id in `rewardsFor(data.book)` not in `skinsOwned`: `skinsOwned[id] = true`, append to
   `Outcome.newRewardIds`.
8. `data.appliedRuns[runId] = true`.

A rejected call returns `applied = false`, `reason`, and zero/empty other fields (`coinsTotal` and
`bestSize` report the stored values, `0` if none); `data` is untouched.

### Test values (`tests/unit/Profile.test.luau`)

Defaults argument `D = { worldsUnlocked = { greybox = true }, settings = { musicVolume = 0.8,
effectsVolume = 0.8, cameraSensitivity = 1, reduceMotion = false, language = "auto" } }`.

| Case | Input | Expected |
| --- | --- | --- |
| defaults | `defaults(D)` | version 1, coins 0, `worldsUnlocked.greybox == true`, book/bestSize/skinsOwned/appliedRuns/receipts empty, `settings.musicVolume == 0.8`; two calls give different tables |
| reconcile fills | `{ version = 1, coins = 7, settings = { musicVolume = 0.3 } }` | coins 7, `settings.musicVolume == 0.3`, `settings.effectsVolume == 0.8`, `settings.language == "auto"`, `book` `{}` |
| reconcile keeps | `{ version = 1, coins = 7, book = { a = true }, bestSize = { greybox = 4.5 } }` | `book.a == true`, `bestSize.greybox == 4.5`, coins 7 |
| reconcile repairs | `{ version = 1, coins = "12", book = 5 }` | coins 0, book `{}` |
| reconcile negative | `{ version = 1, coins = -3 }` | coins 0 |
| prepare new | `{}` | returns true; `version == 1`; equals `defaults(D)` field by field |
| prepare v1 unchanged | `{ version = 1, coins = 5, book = { a = true }, appliedRuns = { ["1-1"] = true } }` | true; coins 5, `book.a`, `appliedRuns` empty |
| prepare future | `{ version = 2, coins = 5 }` | `false, "FutureVersion"`; coins still 5, version still 2 |
| prepare bad | `{ version = "x" }` | `false, "BadVersion"` |
| prepare zero | `{ version = 0 }` | `false, "BadVersion"` |
| migrate mechanism | `data = { version = 1, coins = 5 }`, `migrations = { [1] = function(d) d.coins = d.coins * 2 end }`, target 2 | true; coins 10; version 2 |
| migrate two steps | `{ version = 1 }`, `[1]` sets `a = 1`, `[2]` sets `b = 2`, target 3 | `a == 1`, `b == 2`, version 3 |
| migrate missing | `{ version = 1 }`, `migrations = {}`, target 2 | `false, "MissingMigration"`; version 1 |
| migrate v1 identity | `{ version = 1, coins = 9 }`, `Profile.migrations`, target 1 | true; coins 9, version 1 |

Apply cases use `rewardsFor = function(book) return if book["greybox.cube_t1"] then { "r1" } else {} end`
and `data = defaults(D)` unless stated.

| # | Call | Expected outcome and data |
| --- | --- | --- |
| A1 | `{ runId = "7-1", worldId = "greybox", finalDiameter = 3.5, coins = 12, newBookIds = { "greybox.cube_t1", "greybox.cube_t2" } }` | `applied`, `isFirstRun`, `coinsGained 12`, `coinsTotal 12`, `bestSize 3.5`, `newBookIds` both, `newRewardIds { "r1" }`; data: coins 12, `bestSize.greybox 3.5`, both in `book`, `skinsOwned.r1`, `appliedRuns["7-1"]` |
| A2 | then `{ runId = "7-2", worldId = "greybox", finalDiameter = 2.75, coins = 8, newBookIds = { "greybox.cube_t1" } }` | `applied`, not first run, `coinsGained 8`, `coinsTotal 20`, `bestSize 3.5` (not lowered), `newBookIds {}`, `newRewardIds {}`; data coins 20 |
| A3 | then `A1` again | `applied == false`, `reason == "Duplicate"`; data identical to after A2 (coins 20) |
| A4 | `coins = -5` | `coinsGained 0`, data coins unchanged |
| A5 | `coins = 3.7` | `coinsGained 3` |
| A6 | `coins = 0/0` | `Invalid`, data unchanged |
| A7 | `runId = ""` | `Invalid` |
| A8 | `finalDiameter = 0` | `Invalid` |
| A9 | `finalDiameter = 0/0` | `Invalid` |
| A10 | `worldId = 5` | `Invalid` |
| A11 | two worlds: `greybox` 3.5 then `snow` 2.5 | `bestSize.greybox 3.5`, `bestSize.snow 2.5`; second `isFirstRun == false` |
| A12 | `newBookIds = { "x", "x" }` | `book.x == true`, `Outcome.newBookIds == { "x" }` |
| A13 | reward already owned (`skinsOwned.r1 = true`) then book gets `greybox.cube_t1` | `newRewardIds {}`, `skinsOwned.r1` still true |

## `Book.luau`

```lua
export type BookObject = { bookId: string, tier: number, nameKey: string, icon: string }
export type BookReward = { rewardId: string, rewardType: string, nameKey: string }
export type BookTier = { tier: number, nameKey: string, reward: BookReward? }
export type BookEntry = { bookId: string, nameKey: string, icon: string, isDiscovered: boolean }
export type PageSummary = {
	tier: number, nameKey: string, collectedCount: number, totalCount: number, isComplete: boolean,
	rewardId: string?, rewardType: string?, rewardNameKey: string?, rewardEarned: boolean,
	entries: { BookEntry },
}

Book.newIds(absorbedBookIds: { string }, book: { [string]: boolean }): { string }
Book.pages(tiers: { BookTier }, objects: { BookObject }, book: { [string]: boolean }, skinsOwned: { [string]: boolean }): { PageSummary }
Book.completedRewardIds(tiers: { BookTier }, objects: { BookObject }, book: { [string]: boolean }): { string }
```

`newIds` keeps first-seen order, drops duplicates and ids already in `book`. `pages` returns one summary per
tier, in the order of `tiers`; `entries` follow the order of `objects`. `completedRewardIds` lists the
`rewardId` of every complete page that has a reward, in tier order.

### Test values (`tests/unit/Book.test.luau`)

`tiers = { { tier = 1, nameKey = "t1", reward = { rewardId = "r1", rewardType = "trail", nameKey = "rn1" } },
{ tier = 2, nameKey = "t2" } }`; `objects`: `a`, `b`, `c`, `d` in tier 1, `e` in tier 2 (bookIds are the
letters).

| Case | Input | Expected |
| --- | --- | --- |
| newIds | `newIds({ "b", "z", "b", "a" }, { a = true })` | `{ "b", "z" }` |
| newIds empty | `newIds({}, {})` | `{}` |
| pages partial | `book = { a = true, c = true }`, `skinsOwned = {}` | page 1: collected 2, total 4, not complete, `rewardId "r1"`, `rewardEarned false`, entries discovered `{ true, false, true, false }`; page 2: 0 / 1, `rewardId nil` |
| pages complete | book has a, b, c, d, e | page 1 complete, page 2 complete; `completedRewardIds` is `{ "r1" }` (tier 2 has no reward) |
| reward earned | complete page 1, `skinsOwned = { r1 = true }` | `rewardEarned == true` |
| pages order | tiers given as `{ tier 2, tier 1 }` | pages come back in that order (no re-sort) |
| empty page | a tier with no objects and a reward | `totalCount 0`, `isComplete false`, reward not in `completedRewardIds` |
| entries fields | page 1 entry 1 | `{ bookId = "a", nameKey, icon, isDiscovered = true }` copied from the object |
| unknown book id | `book = { zzz = true }` | no page counts it |
| input untouched | any call | arguments are not mutated |

## `Settings.luau`

```lua
export type Range = { min: number, max: number }
export type Bounds = {
	musicVolume: Range, effectsVolume: Range, cameraSensitivity: Range, languages: { string },
}
Settings.validate(current: Profile.SettingsData, candidate: unknown, bounds: Bounds): SettingsData
```

(`Profile.SettingsData` is shown for clarity; the module declares its own identical type, because Rules
modules do not require each other.) Returns a **new** table; `current` and `candidate` are never mutated.
Per field, independently: a number that is finite is clamped to `[min, max]`, any other value is ignored;
`reduceMotion` accepts only a boolean; `language` accepts only a string equal to an entry of
`bounds.languages` (case-sensitive). A non-table `candidate` returns a copy of `current`. Unknown keys are
ignored.

### Test values (`tests/unit/Settings.test.luau`)

`current = { musicVolume = 0.8, effectsVolume = 0.8, cameraSensitivity = 1, reduceMotion = false,
language = "auto" }`, bounds `0..1`, `0..1`, `0.5..2`, languages `{ "auto", "en-us", "es-es" }`.

| Candidate | Result differs from `current` in |
| --- | --- |
| `{ musicVolume = 0.25 }` | `musicVolume 0.25` |
| `{ musicVolume = 1.5 }` | `musicVolume 1` |
| `{ musicVolume = -0.2 }` | `musicVolume 0` |
| `{ effectsVolume = 0 }` | `effectsVolume 0` |
| `{ cameraSensitivity = 0.1 }` | `cameraSensitivity 0.5` |
| `{ cameraSensitivity = 3 }` | `cameraSensitivity 2` |
| `{ cameraSensitivity = 1.25 }` | `cameraSensitivity 1.25` |
| `{ reduceMotion = true }` | `reduceMotion true` |
| `{ reduceMotion = "yes" }` | nothing |
| `{ language = "es-es" }` | `language "es-es"` |
| `{ language = "fr-fr" }` | nothing |
| `{ language = "ES-ES" }` | nothing |
| `{ musicVolume = 0/0 }` | nothing |
| `{ musicVolume = math.huge }` | nothing |
| `{ musicVolume = "0.5" }` | nothing |
| `{ volume = 3 }` | nothing |
| `{ musicVolume = 0.5, language = "xx", reduceMotion = true }` | `musicVolume 0.5`, `reduceMotion true`, language kept (fields are independent) |
| `"hello"`, `5`, `nil`, `true` | nothing (copy of `current`) |
| `{}` | nothing |
| any | returned table is not `current`; `current` unchanged |

## `RunClock.luau` addition

```lua
RunClock.uiLocked(now: number, endsAt: number, duration: number, lockSeconds: number): boolean
-- elapsed = duration - remaining(now, endsAt); true while elapsed < lockSeconds
```

`duration = 240`, `endsAt = 240` (run started at `now = 0`), `lockSeconds = 5`:

| now | locked |
| --- | --- |
| 0 | true |
| 4.99 | true |
| 5 | false |
| 100 | false |
| 240 | false |
| 300 (past the end) | false |
| -1 (before the start) | true |
