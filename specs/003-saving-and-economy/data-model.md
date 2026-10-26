# Data Model: Saving and Economy

Entities, validation and state flows. Names of the profile keys are owner-approved (spec, Owner Approval
Gate); nothing here adds, renames or retypes one. Signatures: [contracts/rules-api.md](contracts/rules-api.md).

## 1. Config additions (`src/shared/Config.luau`)

Top-level numbers must be positive and finite (`Config.test.luau`); nested tables may hold zero.

| Key | Value | Notes |
| --- | --- | --- |
| `dataStoreName` | `"PlayerProfiles_v1"` | approved |
| `playerKeyPrefix` | `"Player_"` | approved; key is prefix .. `tostring(userId)` |
| `useMockDataStoreInStudio` | `true` | Studio runs use `ProfileStore.Mock` |
| `runStartUiLockSeconds` | `5` | Book cannot open this long after a run starts |
| `settingsRateLimit` | `20` | `UpdateSettings` per `rateLimitWindow` (1 s) |
| `settingsSendDelay` | `0.3` | client debounce, seconds |
| `minUtilityTouchTarget` | `64` | TopBar, Book and Settings controls (finding F-4) |
| `noticeSeconds` | `2` | how long the Shop notice stays |
| `Settings.musicVolume` | `{ default = 0.8, min = 0, max = 1 }` | |
| `Settings.effectsVolume` | `{ default = 0.8, min = 0, max = 1 }` | |
| `Settings.cameraSensitivity` | `{ default = 1.0, min = 0.5, max = 2.0 }` | |
| `Settings.reduceMotionDefault` | `false` | |
| `Settings.languages` | `{ "auto", "en-us", "es-es" }` | order is the selector order |
| `Settings.languageDefault` | `"auto"` | |
| `DefaultWorldsUnlocked` | `{ greybox = true, snow_village = true }` | approved default |
| `Flags.Saving` | `true` | R13 |
| `Flags.Shop` | `false` | R13, finding F-5 |

`Config.test.luau` also asserts each `default` lies in `[min, max]`.

## 2. PlayerProfile v1 (`profile.Data`)

```
version        number                 1
coins          number                 0     non-negative integer, only grows in this feature
worldsUnlocked { [string]: boolean }  { greybox = true, snow_village = true }
skinsOwned     { [string]: boolean }  {}     owned cosmetic ids, including page rewards
equipped       { skin: string?, trail: string? }  {}   (nil fields are simply absent)
book           { [string]: boolean }  {}     discovered bookIds
bestSize       { [string]: number }   {}     worldId -> best final diameter (studs), never decreases
receipts       { string }             {}     reserved for Feature 006, untouched here
appliedRuns    { [string]: boolean }  {}     runIds applied in THIS session; emptied on load
settings       PlayerSettings         see 3
```

Validation on load (`Profile.reconcile`): a key that is missing is filled from defaults; a key with the
wrong type is replaced by its default; `settings` is reconciled field by field (its own defaults); the
sets and maps (`worldsUnlocked`, `skinsOwned`, `book`, `bestSize`, `appliedRuns`) are never recursed into,
so saved entries are never overwritten or re-added. `coins` must be a finite number that is zero or
more; anything else (a string, a negative, NaN) becomes `0`, and any valid stored number is kept as is.

Invariants after any call: `coins ≥ 0`; `bestSize[w]` never decreases; `book[id]` is `true` or absent;
`skinsOwned[id]` is `true` or absent; `version == Profile.SCHEMA_VERSION`.

## 3. PlayerSettings

| Field | Type | Default | Legal range |
| --- | --- | --- | --- |
| `musicVolume` | number | 0.8 | 0 to 1 (clamped) |
| `effectsVolume` | number | 0.8 | 0 to 1 (clamped) |
| `cameraSensitivity` | number | 1.0 | 0.5 to 2.0 (clamped) |
| `reduceMotion` | boolean | false | true or false |
| `language` | string | `"auto"` | one of `"auto"`, `"en-us"`, `"es-es"` (exact, lower case) |

A candidate field that is NaN, infinite, of the wrong type, or (for `language`) not in the list is
ignored and the current value kept. Unknown keys are ignored. Numbers outside the range clamp to the
nearest bound.

## 4. ProfileSnapshot (server to client, read-only)

```
coins          number
bestSize       { [string]: number }
book           { [string]: boolean }
skinsOwned     { [string]: boolean }
equipped       { skin: string?, trail: string? }
settings       PlayerSettings
```

Not sent: `version`, `worldsUnlocked`, `receipts`, `appliedRuns`. The client never writes into it and
never sends it back.

## 5. RunResult additions (002 type, additive)

```
coinsTotal   number?    persistent balance after this result; nil when no profile
isFirstRun   boolean    true only for the first applied run of a profile (finding F-3)
```

`bestSelfSize` keeps its 002 meaning but now comes from the persistent best (`max(stored, finalDiameter)`);
`newBookIds` is computed against the persistent `book`. `RunClient.parseResult` accepts a payload without
the new fields (treated as `nil` and `false`).

## 6. ApplyOutcome (`Profile.applyRunResult` return value)

```
applied        boolean
reason         string?     "Duplicate" | "Invalid" when applied is false
isFirstRun     boolean
coinsGained    number      >= 0
coinsTotal     number
bestSize       number      stored best for the world after the call
newBookIds     { string }  ids actually inserted (absent before)
newRewardIds   { string }  rewards actually granted (absent from skinsOwned before)
```

`DataService.applyRunResult` returns the same table with `applied = true`, or `nil` when there is no
active profile. A rejected call (`applied = false`) leaves `data` byte-for-byte unchanged.

## 7. BookPageSummary (`Book.pages`, derived, never stored)

```
tier            number
nameKey         string        tier name key from the tier definition
collectedCount  number
totalCount      number
isComplete      boolean       totalCount > 0 and collectedCount == totalCount
rewardId        string?       from tier.reward; nil when the tier has no reward
rewardType      "skin" | "trail"?
rewardNameKey   string?
rewardEarned    boolean       rewardId ~= nil and skinsOwned[rewardId] == true
entries         { { bookId, nameKey, icon, isDiscovered } }   world object order
```

## 8. State flows

**Profile session (server, per player).**

```
(joined) --PlayerAdded--> Loading --profile--> Active --PlayerRemoving / BindToClose / OnSessionEnd--> Ended
                             |                    |
                             +-- nil / error ---> Kicked (no profile stored)
                             +-- future version -> Kicked (profile released unchanged)
```

Transitions to `Active` run `Profile.prepare` then `ProfileSync`. In `Active`: `applyRunResult`,
`updateSettings`. In `Ended`/`Kicked`: every call returns `nil`/`false` and mutates nothing.

**Run result application (one run).**

```
RunManager.endRun
  buildResult (newBookIds, bestSelfSize from DataService or fallback)
  DataService.applyRunResult
    profile active?  no -> nil
    Profile.applyRunResult
      invalid? -> {applied=false,"Invalid"}
      appliedRuns[runId]? -> {applied=false,"Duplicate"}
      isFirstRun = next(bestSize) == nil
      coins += max(0, floor(result.coins))
      bestSize[worldId] = max(old or 0, finalDiameter)
      book[id] = true for each newBookIds
      for id in rewardsFor(book): if not skinsOwned[id] then grant
      appliedRuns[runId] = true
    ProfileSync
  merge coinsTotal, isFirstRun -> publish RunResult
```

**Settings change (one update).** client change -> apply locally -> debounce -> `UpdateSettings` -> rate
limit -> `Settings.validate` -> write -> `ProfileSync` -> client re-applies the authoritative values
(a clamped value moves the control).

**Book button availability (client).** `Active` and `RunClock.uiLocked == false`: open. `Active` and
locked: ignored, lock glyph. `Ended`, `Hub`: open. Panel closes on its own if the run restarts into the
lock window.

## 9. Content shape (`GreyBoxRoom.luau`)

```lua
export type RewardDef = { rewardId: string, rewardType: "skin" | "trail", nameKey: string }
export type SizeTierDef = {
	tier: number, nameKey: string, minDiameter: number, maxDiameter: number?,
	headlineKey: string, headlineIcon: string,
	reward: RewardDef?,          -- new
}
```

Grey-box data: tier 1 `greybox.reward.tier1` trail, tier 2 `greybox.reward.tier2` trail, tier 3
`greybox.reward.tier3` skin, tier 4 `greybox.reward.tier4` skin; name keys
`reward.greybox.tier1.name` to `tier4.name`. Lune tests: reward ids unique and non-empty, `rewardType`
legal, every name key exists in `Strings`, a tier without `reward` is allowed.
