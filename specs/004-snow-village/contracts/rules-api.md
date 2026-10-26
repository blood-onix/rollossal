# Contract: Pure rules API (`src/shared/Rules`)

Two new standalone modules and one addition. No `require`, no Roblox API, no clock, no randomness
(Constitution III). Every number enters as an argument. Test values below are worked out by hand and go into
`tests/unit` as fixed expectations. Reminder: `scripts/check.sh` greps `src/shared/Rules` for the words
`game`, `task`, `Enum`, `Instance`, `workspace`, `tick`, `Vector3`, `CFrame`, `DateTime`, `GetService` even in
comments, and for `math.random`, `os.clock`, `os.time`.

## `Respawn.luau`

Horizontal (x, z) geometry only; height is ignored, so a player on a rooftop still sees the street below.

```lua
export type Point = { x: number, z: number }
-- hx, hz: unit heading of the ball's horizontal velocity, or 0, 0 when it is slower than the minimum speed.
export type Watcher = { x: number, z: number, hx: number, hz: number }
export type SightParams = { radius: number, viewDistance: number, viewCos: number }

Respawn.delayFrom(unit: number, minDelay: number, maxDelay: number): number
-- minDelay + clamp(unit, 0, 1) * (maxDelay - minDelay). `unit` is a 0..1 number the caller got from its Random.

Respawn.isSeen(point: Point, watchers: { Watcher }, params: SightParams): boolean
-- true when any watcher is within `radius` (inclusive) of the point, or within `viewDistance` (inclusive) and
-- (point - watcher) . heading / distance >= viewCos (heading must be non-zero). A point exactly on a watcher
-- counts as seen. No watchers: false.

Respawn.canRespawn(now: number, takenAt: number, respawnAt: number, point: Point,
	watchers: { Watcher }, params: SightParams, forceAfter: number): boolean
-- true when now >= takenAt + forceAfter (starvation ceiling), else when now >= respawnAt and not isSeen.
```

Hand-computed tests (params `radius 45`, `viewDistance 120`, `viewCos 0.5`; watcher W at (0, 0) heading
(1, 0)):

| Case | Expected |
| --- | --- |
| point (45, 0) | seen (radius boundary, inclusive) |
| point (0, 46) | not seen (46 > 45, heading dot 0 < 0.5) |
| point (120, 0) | seen (view distance boundary, dot 1) |
| point (121, 0) | not seen |
| point (-100, 0) | not seen (dot -1) |
| point (0, 100) | not seen (dot 0) |
| point (60, 60) | seen (distance 84.85, dot 0.7071) |
| point (50, 86.6) | seen (distance 99.998, dot 0.50001) |
| point (49, 86.6) | not seen (distance 99.50, dot 0.4925) |
| watcher heading (0, 0), point (100, 0) | not seen (cone off, 100 > 45) |
| watcher heading (0, 0), point (30, 0) | seen (radius only) |
| no watchers | not seen |
| `delayFrom(0, 60, 120)` / `(0.5, …)` / `(1, …)` / `(2, …)` / `(-1, …)` | 60 / 90 / 120 / 120 / 60 |

`canRespawn` with `takenAt = 0`, `respawnAt = 100`, `forceAfter = 180`, point (10, 0):

| now | watchers | Expected |
| --- | --- | --- |
| 99.99 | none | false (too early) |
| 100 | none | true |
| 100 | W (point is seen) | false |
| 179.99 | W | false |
| 180 | W | true (starvation ceiling) |

## `Layout.luau`

Seeded zone expander (research R2). Rectangular zones only. Uses its own Park–Miller generator
(`state = state * 48271 % 2147483647`, exact in double precision), never `math.random`.

```lua
export type Zone = {
	id: string,
	x: number, z: number, w: number, d: number,   -- rectangle centre and size
	y: number,
	mix: { { objectId: string, weight: number } },
	count: number,
	seed: number,
	spawnSlot: number?,
}
export type Placement = { id: string, objectId: string, x: number, y: number, z: number, yaw: number, spawnSlot: number? }

Layout.cellEdge(zone: Zone, sizes: { [string]: number }): number
-- 1.2 * the largest `size` among the objectIds in the zone's mix.

Layout.capacity(zone: Zone, sizes: { [string]: number }): number
-- floor(w / edge) * floor(d / edge).

Layout.next(state: number): number
-- one generator step on a state in 1 .. 2147483646.

Layout.normaliseSeed(seed: number): number
-- seed % 2147483646 + 1, so 0 and negative-looking seeds are valid.

Layout.expand(zones: { Zone }, sizes: { [string]: number }): { Placement }
-- Per zone, in order: build the grid cells (row-major), shuffle the cell order with the generator
-- (Fisher-Yates), take the first `count` cells, give each a centre jitter of up to
-- (edge - size) / 2 on each axis from the generator, pick the objectId by cumulative weight from the
-- generator, and yaw = (generator output % 360) degrees converted to radians. Ids are
-- `<zone.id>_<index>` with a 3-digit zero-padded index. errors if count > capacity.
```

Hand-computed tests:

- `next(1) = 48271`, `next(48271) = 182605794`, `next(182605794) = 1291394886`.
- `normaliseSeed(0) = 1`, `normaliseSeed(5) = 6`, `normaliseSeed(2147483646) = 1`.
- zone `w = 20, d = 10`, mix of one object of size 1.0: `cellEdge = 1.2`, `capacity = 16 * 8 = 128`.
- two sizes 1.0 and 2.5 in the mix: `cellEdge = 3.0`, `capacity = floor(20/3) * floor(10/3) = 6 * 3 = 18`.
- determinism: expanding the same zones twice gives deep-equal lists; changing one seed changes only that
  zone's placements.
- no overlap: for a zone with `count = capacity`, no two placements are closer than the sum of their
  radii (`size/2` each).
- `count = capacity + 1` raises an error.

## `Tiers.luau` (addition)

```lua
Tiers.isCulled(objectTier: number, playerTier: number, delta: number): boolean
-- objectTier <= playerTier - delta
```

| objectTier, playerTier, delta | Expected |
| --- | --- |
| 1, 3, 2 | true |
| 2, 3, 2 | false |
| 2, 4, 2 | true |
| 3, 4, 2 | false |
| 3, 5, 2 | true |
| 4, 5, 2 | false |
| 1, 1, 2 | false |
| 1, 2, 2 | false (a delta of 2 needs a gap of at least 2 tiers) |
