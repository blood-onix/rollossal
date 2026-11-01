# Contract: `Downtown.luau` content (008)

What the data module must satisfy. `tests/unit/Downtown.test.luau` enforces it; numbers live in `data-model.md`. The
007 module rules, identity table and "switching themes" section hold unchanged (`specs/007-downtown-holiday-city/
contracts/world-content.md`), with one addition: **a `Boundary` block is data like any other** (kind `"Boundary"`,
valid `swatch`).

## Module rules

1. `--!strict` on line 1; no `require`, no Roblox API; loads in Lune. One file.
2. Plain data. Offsets from a one-off search are **baked** as literals with a comment naming the search.
3. Zones and blocks are inside `halfExtent` (`Boundary` blocks may sit outside, within `halfExtent + 8`); placements are
   inside `outerHalfExtent`. Horizon towers are blocks, not placements (D7).
4. Block `yaw` is 0 or 90 (the pace and sightline tests treat blocks as axis-aligned rectangles). Wedges are exempt
   from the pace footprint.

## Revised 007 invariants

| # | Invariant (008) |
| --- | --- |
| C1 | unchanged: 74 objects, tiers 18 / 15 / 16 / 16 / 9 |
| C2, C3, C4, C5, C6 | unchanged |
| C7 | `placements(winter) ≤ 1500` and `placements(city) ≤ 1500`; `Layout.capacity ≥ count` for every zone |
| C8 | unchanged: slot placements ≤ 15 % of placements in each theme |
| C9 | 12 spawns, `slot` 1…12, all with `m ≤ 90`, none inside a main-street corridor; each ≥ 40 Tier 1 placements within 10 studs in each theme |
| C10 | unchanged: overlays intersect no keep-out |
| C11, C12, C13 | unchanged |
| C14 | base `environment.blocks ≤ 215`; `winter` total blocks (base + theme) ≤ 250; `placements + blocks + built markers + 3 + 12 + 64 ≤ 1850` in both themes |
| C15 | unchanged: `Markers.validate(..., { requireGolden = 5 })` clean; all 9 booster / trap sub-kinds; at least one booster and one trap sub-kind in each of the five ring groups |
| C16 | **replaced**: 4 main-street corridors and 12 lane corridors (sightline keep-outs). No block with `top > 2.5` (excluding `Boundary`) and no Tier 4 or 5 placement other than `slot.landmark` intersects any corridor |
| C17 | `ambient.pigeons` ≤ 8 per district, 5 districts, none inside a `marker` keep-out, each on ground or a static plinth |
| C18 | a block with top 1.0 to 1.5 within 4 studs of every spawn |

## New invariants

| # | Invariant |
| --- | --- |
| N1 | `halfExtent == 440`, `outerHalfExtent == 560`, `hub.center == (−620, 0)`; exactly four `Boundary` blocks with inner faces at `±halfExtent`, thickness ≥ 8, height ≥ 150 |
| N2 | built coverage on the 5-stud raster over `[−440, 440]²` is ≥ 0.20 in `winter` and in `city` |
| N3 | at least 50 non-ground, non-`Boundary` base blocks (D4) |
| N4 | no non-`Boundary` block within 12 studs of `±halfExtent` is taller than 8 |
| N5 | every `shortcut` keep-out has two flanking walls with clear gap `4.5 ± 0.1` and a roof whose bottom face is at `4.8 ≤ y ≤ 5.0` covering its length |
| N6 | base placements per tier within ±10 % of 470 / 386 / 260 / 204 / 56 (423–517, 347–425, 234–286, 184–224, 50–62) |
| N7 | measured clear widths by street: lanes 8 ± 1, main streets 30 ± 1, Ring 2 16 to 30, Ring 3 ≥ 30, Ring 4 carriageways ≥ 24 and 60 in total, Ring 5 avenues ≥ 40 |
| N8 | flood-fill: a D 2 ball cannot leave Ring 1 through the bollard gates or edge walls; a D 5 ball can |
| N9 | no base block id contains `garland` or `slope`; every garland has `bottom ≥ 9`; `city` builds no theme block (F2) |
| N10 | triangle ceiling: unculled `winter` ≤ 250,000; as seen by a Tier 5 player (`cullTierDelta = 2`) ≤ 100,000; every resolved `assetKey` has a manifest row |

## Pace contract

`Pace.simulate(world, themeId)` returns, for each of the 12 spawns, the second the eater first reaches D ≥ 2.4 (first
pickup), 5, 12, 30, 80 and 150. Windows: ≤ 5 s; 10 to 50 s; 70 to 110 s; 120 to 180 s; ≤ 210 s; ≤ 240 s. `simulateTwelve`
adds a shared-food run: all 12 balls first pick up ≤ 5 s and reach D 5 ≤ 60 s. Details: `pace-and-tests.md`.

## Switching themes

Unchanged from 007, plus: the `winter` blocks (garlands, slope, sled ramp) disappear and the overlays vanish; the base
blocks, the base placements and the four colliders stay the same.
