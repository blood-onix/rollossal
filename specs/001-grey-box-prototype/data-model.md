# Data Model: Grey-Box Prototype

**Feature**: `001-grey-box-prototype` | **Spec**: [spec.md](spec.md) | **Research**: [research.md](research.md)

All state lives on the server unless stated. Clients hold only derived or local view state. Types are
Luau strict-mode shapes; field names are the ones code should use.

---

## 1. GameConfig (`src/shared/Config.luau`)

A single read-only table. Full key list, values and derivations are in
[contracts/config-and-content.md](contracts/config-and-content.md). Validation (Lune
`Config.test.luau`): every number is finite and positive; `cameraMinDistance ≤ cameraMaxDistance`;
`baseSpeed ≤ speedCap`; `speedCap < maxServerBallSpeed`; `startDiameter ≥ 2`; `knockOffCount ≥ 1`;
`maxVisibleStuck ≤ maxTrackedStuck`; `stuckVisualMode` is `"Weld"` or `"Follower"`; the three feature
flags exist and default to `false`; `Budgets.meshTriangles` has entries for tiers 1 to 5 that match the
spec (≤ 300, ≤ 300, ≤ 800, ≤ 2500, ≤ 2500).

## 2. TierDef and RoomLayout (`src/shared/Content/GreyBoxRoom.luau`)

```lua
export type TierDef = { tier: number, size: number, count: number, shade: number }  -- shade: grey 0..255
export type CubeSpawn = { id: string, tier: number, x: number, z: number }
export type Room = {
  halfExtent: number,        -- 36: floor and walls at +-36
  wallHeight: number,        -- 20
  kerb: { x: number, z: number, length: number, depth: number, height: number },
  spawnRingRadius: number,   -- 5
  spawnSlots: number,        -- 12
  tiers: { TierDef },
  cubes: { CubeSpawn },
}
```

Tier values are in [research.md](research.md) R1 (sizes 0.75, 0.95, 1.2, 1.5; counts 12, 9, 6, 3). Cube
`y` is not stored; the server places each cube at `y = size / 2` (resting on the floor at `y = 0`).
Cube IDs are `T<tier>-<two digit index>`, for example `T1-01`, `T4-03`.

Initial layout (x, z in studs; origin is the room centre; Lune test checks bounds and spacing):

| Tier | Positions |
| --- | --- |
| 1 | 01 (11, 0) · 02 (0, 12) · 03 (−11, 0) · 04 (3, −13) · 05 (15, 9) · 06 (−9, 15) · 07 (−15, −7) · 08 (9, −18) · 09 (19, −4) · 10 (−3, 20) · 11 (−16, −19) · 12 (−24, −18) |
| 2 | 01 (24, 8) · 02 (21, −14) · 03 (8, 27) · 04 (−14, 26) · 05 (−27, 10) · 06 (−25, −4) · 07 (13, −26) · 08 (28, −3) · 09 (−5, −26) |
| 3 | 01 (30, 20) · 02 (−30, 22) · 03 (−30, −26) · 04 (28, −24) · 05 (0, 31) · 06 (−8, −31) |
| 4 | 01 (32, 31) · 02 (−32, 31) · 03 (31, −31) |

Kerb: centre (−20, −12), length 22 (along x), depth 2, height 1.0 (equal to the starting ball radius, so
the ball must hop). T1-11 and T1-12 sit on its far side; the kerb's open end lets a ball go round, so it
is a jump test, not a blocker.

Validation rules (Lune `GreyBoxRoom.test.luau`): exactly 30 cubes; IDs unique; per-tier counts equal
`TierDef.count`; tier sizes strictly ascend; every cube is within `halfExtent − 4`; any two cubes are at
least 4 studs apart (centre to centre); each of the 12 spawn slots has a Tier 1 cube within 10 studs;
Tier 1 size ≤ `absorbRatio × startDiameter` and every other tier size is above it (so Tiers 2 to 4 are
obstacles at the start).

## 3. RoomCube (server registry entry plus its `Part`)

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | Unique; also the `Part.Name` |
| `tier` | number | 1 to 4 |
| `size` | number | Edge length; the server's only source of truth for size |
| `spawnCFrame` | CFrame | From `GreyBoxRoom` (`x, size/2, z`) |
| `part` | Part | Anchored; attributes `Size`, `Tier` (static) and `Taken` (bool) replicate |
| `state` | `"Available" \| "Taken" \| "Scattered"` | See transitions |
| `respawnAt` | number? | `os.clock()` time a `Taken` cube returns |
| `availableAt` | number? | End of the post-scatter grace (`Scattered` cubes can be absorbed after it) |
| `holderKey` | string? | Key of the `StuckEntry` whose pickup made the cube `Taken`; cleared on respawn or scatter |

**State transitions**

```
Available --(valid Absorb)--> Taken --(respawnAt reached)--> Available (at spawnCFrame)
Taken (holderKey = popped entry's key) --(knocked off, Reset)--> Scattered (near the ball, visible, anchored)
Scattered --(availableAt reached)--> Available (at its scattered position; stays there until absorbed)
```

A ball's stack holds **visual-only records** (`StuckEntry`, §5), not cubes. An absorbed cube is `Taken`
and returns to its spawn point after `respawnDelay` **whether or not a ball still shows it**, so the
30-cube room refills and a solo player can climb all four tiers (research R1, finding F-1). The same
cube can therefore be eaten again and appear on a ball more than once, each time under a new entry key.

When an entry is knocked off (or the ball is reset), its cube moves only if it is still waiting to
respawn **from that same pickup** (`state == "Taken"` and `holderKey == entry.key`): it becomes
`Scattered`, then `Available`. Otherwise the cube is already back in the room (or taken again by a later
pickup) and stays where it is; the record just leaves the ball. A cube absorbed from a scattered position
respawns at its **original** `spawnCFrame` after `respawnDelay` like any other. A cube has at most one
holder at a time, so no pickup is ever duplicated.

Invariant (Studio test): `#free + #pendingRespawn = 30`, where free is `Available` or `Scattered` and
pending is `Taken`. Stack records are not cubes and are not counted.

## 4. PlayerBall (server session, `BallService`)

| Field | Type | Notes |
| --- | --- | --- |
| `player` | Player | |
| `ownerUserId` | number | |
| `part` | Part | `Shape = Ball`, network owner = `player`, in `workspace.Balls`, named `Ball_<UserId>` |
| `authoritativeDiameter` | number | Starts at `Config.startDiameter` (2). Mirrored to the `Diameter` attribute |
| `physicalDiameter` | number | Eased towards `authoritativeDiameter` over `growTime` |
| `stuckStack` | `{ StuckEntry }` | Oldest first, capped at `maxTrackedStuck`; operations in `Rules.StuckStack` |
| `absorbWindow` | `{ number }` | Request timestamps for the absorb rate limit (`Rules.RateLimit`) |
| `bumpWindow` | `{ number }` | Same, for `Bump` |
| `lastBumpAt` | number | For `bumpCooldown` |
| `lastRespawnAt` | number | For the `RespawnBall` cooldown |
| `speedSamples` | ring buffer of `{ t: number, speed: number }` | One per Heartbeat, kept for `bumpSpeedWindow` |
| `lastValidPosition` | Vector3 | Updated when a step passes the sanity check |
| `lastValidVelocity` | Vector3 | Same |
| `violations` | number | Count of speed violations (for the playtest report) |

**Lifecycle**: `PlayerAdded` → create session and ball at a free spawn slot (`Active`) → on speed
violation, correct in place (stays `Active`) → on `RespawnBall` (cooldown 3 s) or `y < fallRespawnY`,
reset: diameter back to 2, stack emptied, the cubes it still holds (§3) scattered back to the room as
`Available`, ball repositioned (`Active`) → `PlayerRemoving`: the cubes the stack still holds returned
to their spawn points, ball destroyed, session dropped (nothing leaks).

## 5. StuckEntry (server) and StuckVisualEntry (client)

```lua
export type StuckEntry = { key: string, id: string, size: number, tier: number, dir: { x: number, y: number, z: number } }
```

`key` is `<id>#<n>` with `n` a server-wide pickup counter, so it is unique per pickup across balls and
respawns. It names the visual on clients and matches the cube's `holderKey` while the cube is pending.

`dir` is the unit direction from the ball centre to the cube centre at pickup, in the ball's local space
(`ballCFrame:PointToObjectSpace(cubePosition).Unit`), rounded to 2 decimals. The server owns `size` (from
the registry); the client never sends it.

`StuckVisualEntry` (client only, one per visible entry of each ball, keyed by `key`): `{ part, dir, weld? }`. A part
that is `CanCollide = false`, `Massless = true`, and sized and shaded from the cube's `Size` and `Tier`
attributes. Visible entries are always `StuckStack.visibleTail(stack, maxVisibleStuck)`: at most 30.

**Rules on the stack** (pure, in `Rules.StuckStack`):

- `push(stack, entry, cap)`: append; if the length exceeds `cap` (`maxTrackedStuck = 120`) drop the oldest.
- `popRecent(stack, n)`: remove and return up to `n` newest entries (fewer if the stack is shorter).
- `visibleTail(stack, maxVisible)`: the newest `maxVisible` entries, oldest first.

## 6. Diameter and volume bookkeeping

The authoritative diameter is a function of the stack, not an independent variable that could drift:

- On absorb: `D' = growDiameter(D, S, k)`.
- On knock-off of entries `e1..en`: `D' = shrinkDiameter(D, {S1..Sn}, k, startDiameter)`, which
  subtracts `k · ΣS³` from `D³` and clamps to `startDiameter`.
- Buried entries (older than the 30 visible ones) still count in `D`; they leave the stack only when
  the 120-entry tracking cap drops them (their volume stays in `D`; they can no longer be knocked off).

## 7. RateLimitState

A plain `{ number }` list of timestamps inside the window. `RateLimit.allow(timestamps, now, limit,
window)` returns `(allowed, newTimestamps)`; it drops timestamps older than `now − window` and, if the
count is below `limit`, appends `now`. Used twice: absorb (10 per 1 s) and bump (10 per 1 s). The
respawn request uses the simpler `lastRespawnAt` cooldown.

## 8. ViolationLog entry (server, in memory)

`{ userId: number, kind: "Speed" | "Displacement", measured: number, limit: number, at: number }`.
Only these produce a `warn`. The count per player is printed in the playtest report. Not persisted.
