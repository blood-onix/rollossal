# Contract: Ball heap

## Goal

By diameter 5, at least 60% of the base sphere is hidden (`Config.heapCoverageTarget` at `heapCoverageTargetD`).
The biggest and newest items stay on the outside. Old small items are buried without popping. Attachments scale
with the ball.

## Data path

1. Server: `AbsorbService` pushes `StuckEntry` as before. `BallService.publishStuck` publishes the last
   `Config.maxPublishedStuck` (60) entries in the existing `key,dx,dy,dz;...` format when `HeapRedesign` is on.
   The server's `maxTrackedStuck` (120) and knock-off rules are unchanged.
2. Client: `StuckVisuals` parses the attribute, calls `Heap.select(entries, {cap, protectTier = 4})` with
   `cap = heapLocalCap` for the local ball and `heapRemoteCap` for others.
3. `outer` entries get a welded visual at `radius + size * stuckEmbed`, scaled by `(D / refD) ^ heapScaleExponent`.
4. `buried` entries shrink to the core over `buryProgress` (a few frames), then their visual is removed.
5. The core sphere colour follows `Heap.coreColor` so a thinly covered ball is not bare.

## Pure API (`Rules/Heap.luau`)

| Function | Returns |
| --- | --- |
| `select(entries, params)` | `{ outer, buried }`, deterministic (score then key) |
| `coverage(ballD, outer, footprint)` | number in [0, 1] |
| `coreColor(buried, paletteOf)` | `{ r, g, b }`; `paletteOf` injected |
| `buryProgress(elapsed, duration)` | number in [0, 1] |

## Tests (hand-computed)

- Newest large item beats old small item at equal cap.
- Tier 4 and above stay outer while protected count is at most `cap`.
- Ties break by key (stable).
- `coverage` at D = 5 with N outer items is at least 0.6 for the default caps.
- `buryProgress(0.1, 0.4) = 0.25`.

## Measurement (Studio, 12 balls, `playtest.md`)

Candidates: (1) raise `maxVisibleStuck` only, (2) outer cap A, (3) A + core colour B, (4) A + B + remote LOD C,
(5) merged lumps D. Record parts, triangles, draw calls, fps (unthrottled seconds) for each. Pass: 30 fps or more,
fewer than 2,000 parts. The default is 4; D is measured only if 4 misses.

Wobble is deferred to 004c.
