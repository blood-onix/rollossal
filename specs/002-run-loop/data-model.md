# Data Model: Run Loop

**Feature**: `002-run-loop` | Spec: [spec.md](spec.md) | Research: [research.md](research.md)

All types are Luau, `--!strict`. "Server only" data never leaves the server. Nothing here is saved; every
table lives for the server session (saving is Feature 003).

## 1. Config additions (`src/shared/Config.luau`)

| Key | Value | Used by |
| --- | --- | --- |
| `runDurationSeconds` | `240` | `RunManager` |
| `rollAgainDelaySeconds` | `3` | Upper bound asserted in tests and quickstart (F-2) |
| `starThresholds` | `{ 20, 45, 80 }` | `Worlds` default when a world has none |
| `friendBonusRate` | `0.20` | `Coins` argument |
| `friendBoostRate` | `0.25` | `Coins` argument |
| `pickupPopDuration` | `1.0` | `Hud` |
| `tierBannerDuration` | `2.5` | `Hud` |
| `knockOffShakeDuration` | `0.35` | `CameraController`, `Feedback` |
| `knockOffShakeMagnitude` | `0.6` | `CameraController` |
| `pickupPitchStep` | `0.08` | `Feedback` (`PlaybackSpeed = 1 + step·(tier − 1)`) |
| `minTextSize` | `18` | `UiKit` |
| `minTouchTarget` | `96` | `UiKit` |
| `uiReferenceShortSide` | `720` | `UiKit` (`Scale = max(1, short / 720)`) |
| `Flags.RunLoop` | `true` | `RunManager`, client UI |

`Config.test` keeps its two invariants: every number finite, every top-level number greater than zero except
`fallRespawnY`. `starThresholds` must be ascending and positive (new test).

## 2. World content (`src/shared/Content/GreyBoxRoom.luau`)

New and changed fields; existing `halfExtent`, `wallHeight`, `kerb`, `spawnRingRadius`, `spawnSlots`,
`tiers` (cube layout), `cubes` are unchanged.

```text
SizeTierDef (spec: WorldTierDef)
  tier          number    1..N, sequential from 1
  nameKey       string    Strings key, e.g. "tier.greybox.2.name"
  minDiameter   number    studs; strictly ascending by tier; tier 1 == Config.startDiameter
  maxDiameter   number?   equals the next tier's minDiameter; nil on the top tier
  headlineKey   string    Strings key for the noun in "Next:" and the banner, e.g. "tier.greybox.2.headline"
  headlineIcon  string    Icons id

ObjectDef (spec: ObjectContentDef)
  id            string    unique object type id, e.g. "cube_t2"
  tier          number    the cube-layout tier it belongs to (1..4)
  size          number    studs; equals the layout tier's size
  coins         number    positive integer base coins
  bookId        string    unique per object type; collection-book entry, e.g. "greybox.cube_t2"
  nameKey       string    Strings key, e.g. "object.greybox.cube_t2"
  icon          string    Icons id

Room (existing type, extended)
  worldId         string
  starThresholds  { number }?   ascending; nil means use Config.starThresholds
  sizeTiers       { SizeTierDef }
  objects         { ObjectDef }
  hub             HubDef

HubDef
  center       { x: number, z: number }   far from the room (x = 160)
  halfExtent   number                     16
  spawn        { x: number, z: number }   offset from center for the ball (0, 0 → plaza centre)
  padRadius    number                     4 (decorative disc)
```

Grey-box values (derived in [research.md R1](research.md)):

| Tier | `minDiameter` | `maxDiameter` | Headline | Object id | Size | Coins | Book id |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2.0 | 2.375 | TINY CUBES | `cube_t1` | 0.75 | 1 | `greybox.cube_t1` |
| 2 | 2.375 | 3.0 | SMALL CUBES | `cube_t2` | 0.95 | 2 | `greybox.cube_t2` |
| 3 | 3.0 | 3.75 | MEDIUM CUBES | `cube_t3` | 1.2 | 3 | `greybox.cube_t3` |
| 4 | 3.75 | nil | LARGE CUBES | `cube_t4` | 1.5 | 5 | `greybox.cube_t4` |

`starThresholds = { 3.0, 4.0, 5.0 }`.

**Validation rules** (Lune, `GreyBoxRoom.test`):
- `sizeTiers[i].tier == i`; `minDiameter` strictly ascends; `sizeTiers[1].minDiameter == 2`;
  `maxDiameter[i] == minDiameter[i+1]`, top tier has none.
- For tier `n ≥ 2`, `minDiameter == layoutTier(n).size / 0.4` within `1e-9` (a tier opens exactly when its
  objects become absorbable). This holds for the grey-box room only; it is a test, not a rule of the model.
- Object `id` and `bookId` are unique; `coins` is a positive integer; `size == layoutTier(tier).size`;
  every layout tier has exactly one object; every cube's tier has an object.
- `starThresholds` ascending, positive, length 3.
- Every `nameKey`, `headlineKey` exists in `Strings` with a non-empty `en`; every `icon` and `headlineIcon`
  exists in `Icons`.
- `hub.halfExtent > 0`, hub area does not overlap the room (`|center.x| − hub.halfExtent > room.halfExtent + 2`).

## 3. Strings and icons

```text
Strings: { [key: string]: { en: string } }       (src/shared/Localization/Strings.luau)
Icons:   { [iconId: string]: string }            (src/shared/Content/Icons.luau; glyph text)
Assets:  { sounds: { pickup, tierUnlock, bump, bell: string } }   (src/shared/Assets.luau)
```

Key list and placeholders are in [contracts/content-and-config.md](contracts/content-and-config.md).

## 4. RunSession (server only, in `RunManager`)

```text
RunSession
  runId               string    "<userId>-<serverRunSeq>"; serverRunSeq increments per server, never reused
  userId              number
  worldId             string
  state               "Active" | "Ended" | "Hub"
  startedAt           number    injected clock (os.clock in production)
  endsAt              number    startedAt + Config.runDurationSeconds
  absorbedCoinValues  { number }  append-only; one base-coin entry per validated pickup; never removed
  absorbedBookIds     { string }  distinct, in first-pickup order
  unlockedTiers       { [number]: boolean }  tiers whose banner already fired this run (tier 1 starts true)
  resultPublished     boolean   guards single publication
```

Module-level server state (also in `RunManager`, per `userId`):

```text
runs            { [number]: RunSession }
bestSelfSize    { [number]: number }        best completed finalDiameter this server session
seenBookIds     { [number]: { [string]: boolean } }   book ids collected in earlier runs this session
runSeq          number                      server-wide counter
```

`FriendCache`: `friends[userId][otherUserId] = boolean`.

`BallService.Session` (existing) gains `zone: "Room" | "Hub"` (default `"Room"`) and `frozen: boolean`
(default `false`). Everything else is unchanged.

### State transitions

```text
        join / PlayerAdded (Flags.RunLoop)
                │  startRun(): new runId, endsAt = now + 240, zone Room, ball at spawn slot
                ▼
           ┌─ Active ──────────────────────────────┐
           │  absorbs, bumps, pickups, tier events │ player leaves → run discarded, no result
           └──────────────┬────────────────────────┘
                          │ step(now): now >= endsAt
                          ▼   freeze ball, build RunResult once, FireClient(RunResult)
                        Ended
              ┌───────────┴───────────┐
   RollAgain  │                       │  BackToHub
              ▼                       ▼
     resetBall, startRun            resetBall, zone Hub, unfreeze
         (→ Active)                   Hub
                                       │ RollAgain
                                       ▼
                              resetBall, startRun (→ Active)
```

Rules: `RollAgain` is accepted in `Ended` and `Hub`; `BackToHub` only in `Ended`. Any other state or any
arguments → ignored silently. `Active → Ended` happens only in `step`, only when `now >= endsAt`.
A fall (`y < fallRespawnY`) or the Reset button in `Active` calls `returnToSpawn` and leaves everything else
untouched. `PlayerRemoving` in any state deletes the run, `bestSelfSize` row stays until the server closes
(it is only read for players present), the friend cache row is removed.

### Per-event updates

| Event | Where | Effect on `RunSession` |
| --- | --- | --- |
| Validated absorb | `AbsorbService.tryAbsorb` → `RunManager.onPickup(userId, object, now)` | append `object.coins` to `absorbedCoinValues`; add `bookId` if new to the run; look up the tier of the new diameter; if tier `> 1` and not in `unlockedTiers`, mark every tier up to it and `FireClient TierUnlocked(tier)`; `FireClient PickupConfirmed(object.id)` |
| Validated knock-off | `AbsorbService.tryBump` → `RunManager.onKnockOff(userId)` | nothing stored; `FireClient KnockedOff()`. Coins and `unlockedTiers` are never reduced |
| Bell | `RunManager.step(now)` | state `Ended`; freeze; `RunResult` built and sent once |

A pickup that crosses two tier thresholds in one step (not possible with grey-box sizes, possible with
other content) fires one banner for the highest tier and marks the lower ones unlocked silently.

## 5. RunResult (immutable; built once per `runId`)

```text
RunResult
  runId            string
  worldId          string
  finalDiameter    number    session.authoritativeDiameter at the bell
  stars            number    0..3 = Stars.stars(finalDiameter, world thresholds)
  coins            number    integer = Coins.total(absorbedCoinValues, options)
  newBookIds       { string }  distinct bookIds in this run, minus seenBookIds[userId]; first-pickup order
  bestSelfSize     number    max(previous bestSelfSize, finalDiameter)
  bestFriendSize   number?   max bestSelfSize among present friends that have one; nil if none
```

`userId` from the spec's entity list is not sent (the client is the user). After publication: `seenBookIds`
gains this run's book ids and `bestSelfSize` is updated, in that order, so `newBookIds` and `bestSelfSize` in
the payload describe the run just ended.

Coin options at the bell: `hasFriendInServer` from `FriendCache`, `friendBonusRate = Config.friendBonusRate`,
`hasDoubleCoins = false`, `friendBoostRate = Config.friendBoostRate`, `friendBoostCount = 0`.

## 6. Client state (`RunClient`)

Derived, never authoritative:

```text
RunClient
  state     "Active" | "Ended" | "Hub" | nil   from Player attribute RunState (nil → no run UI)
  runId     string?                            from RunId
  endsAt    number                             from RunEndsAt (server time)
  signals   pickup(objectId), tierUnlocked(tier), knockedOff(), result(RunResult), stateChanged(state)
```

HUD-only derived values (from the ball's `Diameter` attribute and `Worlds`): `tierIndex`, `nextThreshold`,
`progress` (0..1) via `Tiers`; `starMarkers` from the world's thresholds; time text via `RunClock.format`.

## 7. Replicated surface summary

Authoritative list and reject behaviour: [contracts/remotes.md](contracts/remotes.md) and
[contracts/replicated-state.md](contracts/replicated-state.md).
