# Contract: Pace, layout tests and the triangle audit (008)

Pure Lune models in `tests/unit`. They call the real `Layout`, `Growth`, `Absorb`, `Tiers`, `ThemeResolve`; no clock, no
random numbers. Written in the task phase before the world is tuned, so they fail on an empty field first.

## 1. Obstacle-aware pace (F7, R-05)

`Pace.simulate(world, themeId, spawn)` keeps its greedy nearest-first eater and gains two obstacle sets, built once per
`(world, theme)` and a 20-stud spatial hash:

- **Walls**: every block except `Boundary`, in the base and the theme, with `bottom < D` and `top > max(2.5, 0.5·D)` for
  the ball's current D. Footprint is the axis-aligned rectangle.
- **Unabsorbable placements**: `size > 0.4·D` (the real `Absorb` ratio). Footprint is a `size × size` square.

A candidate is reachable if its straight segment is clear, or if going round the first blocking obstacle via the nearest
corner (offset `D/2 + 0.5`) is clear; the cost is the longer path. A blocked candidate is skipped. Pickup rates stay
1.5 per second (small) and 1.0 (large). Speed uses the real speed rule.

`Pace.simulateTwelve(world, themeId)` runs 12 eaters from the 12 spawns with one shared `taken` set, stepping the
earliest eater first. Returns, per slot, the first-pickup time and the time to D 5.

### Windows

| Mark | Window | Source |
| --- | --- | --- |
| first pickup (D ≥ 2.4) | ≤ 5 s | FR-007 |
| D 5 | 10 to 50 s | FR-007 |
| D 12 | 70 to 110 s | FR-007 |
| D 30 | 120 to 180 s | FR-007 |
| D 80 | ≤ 210 s | FR-007 |
| D 150 | ≤ 240 s | FR-007; **fallback in R-07** |
| `simulateTwelve` | first pickup ≤ 5 s and D 5 ≤ 60 s for all 12 | FR-008 |

All windows hold for each of the 12 spawns in `winter` and `city`. If D 150 cannot be reached, `Pace.test` records the
best D and the limiting term in `playtest.md` and the owner is asked once; the mark is not silently dropped.

## 2. Sightline and street models (`Downtown.test`)

- **Sightline (C16)**: for each `sightline` keep-out, rasterise it; fail if any non-`Boundary` block with `top > 2.5` or
  any Tier 4 or 5 placement (other than `slot.landmark`) intersects it. Tier 4 and 5 footprint is `size × size`.
- **Street widths (N7)**: a hand-written table in the test (id, axis, centre line, from, to, minimum, maximum). A street
  edge is the face of a block with `top ≥ 1.0`. For every 10-stud sample along the street, the free width across the
  axis, measured on a 1-stud raster, must be inside the range. Ring 4 also checks the two carriageways and the median.
- **Gates and the edge (N8)**: flood-fill at 2-stud cells over Ring 1 using the pace walls for D 2, with the eight
  cones per gate as `size 2.0` obstacles that D 2 cannot eat. Pass when no cell on `m = 92` is reachable. Repeat for D 5
  (cones absorbable, `0.4 · 5 = 2.0`) and pass when one is.

## 3. Coverage and block counts (N2, N3, N4)

Rasterise on a 5-stud grid over `[−440, 440]²` (176 × 176). Mark the rectangle of every block with `top > 0.2` that is
not a `Boundary`, and a `size × size` square for every Tier 4 or 5 placement. Coverage = marked / 30,976. Computed
separately for `winter` (base + theme blocks, base + overlay placements) and `city`. The block-count rule counts blocks
with `top > 0.5` or footprint under 4,000 (non-ground slabs, plinths, walls), excluding `Boundary`.

## 4. Shortcut check (N5)

For each `shortcut` keep-out: find the two blocks that flank its long sides within 0.5 stud and the roof block over it.
The gap between the inner faces is `4.5 ± 0.1`; the roof bottom is `4.8 ≤ y ≤ 5.0` and its footprint covers the keep-out
length; the flank tops are ≥ 5.2.

## 5. Triangle audit (N10, R-10)

From `art/export/manifest.json`, key rows by `assetKey` (`dt_<id>`). For each resolved placement in `winter`:

- `total = Σ triangles(assetKey)` ≤ **250,000**;
- `culled = Σ triangles` over placements with tier ≥ 4 (the set a Tier 5 player sees with `cullTierDelta = 2`) ≤
  **100,000**.

A placement whose `assetKey` has no manifest row fails the test. Both ceilings are provisional (about 1.3 × the measured
value, 187,000 unculled) until the RC phone check.

## 6. Test files

| File | Edit |
| --- | --- |
| `tests/unit/Pace.test.luau` | obstacle-aware eater, `simulateTwelve`, new windows; the window table is data |
| `tests/unit/Downtown.test.luau` | N1 to N10, C7, C9, C14, C16 changes, pins at lines 139, 140, 733, 926 |
| `tests/unit/Config.test.luau` | 1500 and 320 |
| `tests/unit/ArtManifest.test.luau` | re-run only |
| `tests/studio/*.spec.luau` | audit for the old extent, spawn count and ids |

## 7. Studio-side checks (🔒, agent-run, once per feature except where noted)

Shortcut sphere casts (D 4.4 passes, D 5.0 blocked from the mouth and from above); yard ramp sphere casts; one capture
per ring in `winter` and `city`; the 12-ball 60 s perf run at 640 × 360 on unthrottled seconds; the `dt_*` mesh check in
Play; the console read. Results go in `playtest.md`.
