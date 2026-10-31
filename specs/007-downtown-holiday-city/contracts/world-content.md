# Contract: `Downtown.luau` content (007)

What the data module must satisfy. This is the contract `tests/unit/Downtown.test.luau` enforces; it does not
restate the numbers, which live in `data-model.md`.

## Module rules

1. `--!strict` on line 1; no `require`, no Roblox API; loads in Lune.
2. Returns one table typed as `WorldDef` plus the optional `ambient` field. The table is plain data: no function
   fields, no computed values that depend on the clock or on random numbers.
3. Offsets that came from a one-off search are **baked** as literals with a comment naming the search, never
   recomputed at require time.
4. Every coordinate is inside `halfExtent` for zones and blocks, inside `outerHalfExtent` for placements.

## Identity and naming

| Field | Rule |
| --- | --- |
| object `id` | lower snake case, unique across the 74 core, the 18 winter and the 5 city objects |
| `bookId` | `"downtown." .. id` |
| `nameKey` | `"object.downtown." .. id` |
| `assetKey` | `"dt_" .. id`; hero variants `dt_cocoa_truck`, `dt_glass_tower_bow` |
| zone id | `dt_z_<group>_<n>`; overlay zones `dt_ol_<group>_<n>`; fixed placements `dt_h_<id>`, `dt_l_<n>`, `dt_ol_f_<n>` |
| tier keys | `tier.downtown.{n}.name`, `tier.downtown.{n}.headline`; no `reward` |
| page ids | `downtown.winter`, `downtown.city`; keys `book.page.downtown.<theme>.name` / `.returning` |

## Content invariants

| # | Invariant |
| --- | --- |
| C1 | 74 objects, per tier 18 / 15 / 16 / 16 / 9; 14 carry the hero flag in the design list |
| C2 | `size` inside the tier's object range and `≤ 0.4 × tier ceiling` (Tier 5: `≤ 60`) |
| C3 | `coins` by the data-model §4 rule; whole numbers; ranges ascend by tier |
| C4 | every `fallback` ∈ {Block, Ball, Cylinder}; every `role` is a palette cell name present in every theme |
| C5 | every zone `mix` and fixed placement names a known object or a `slot.*` id; no zone mixes slot and non-slot ids |
| C6 | every `slot.*` used is mapped in both bindings, tier equal to the slot's tier |
| C7 | `placements(winter) ≤ 1400` and `placements(city) ≤ 1400`; `Layout.capacity ≥ count` for every zone |
| C8 | dressing-slot placements `≤ 15 %` of placements, in each theme |
| C9 | 12 spawns, `slot` 1…12, each with ≥ 40 Tier 1 placements within 10 studs, in each theme |
| C10 | overlay zone rectangles and overlay fixed placements intersect no `keepOutAreas` entry of any kind |
| C11 | `city.overlays` empty; `city.heroVariants` empty; `winter.heroVariants` has exactly 2 entries |
| C12 | each hero variant: same `tier`, `coins`, `bookId` as the base; declared `size` within 10 % of the base |
| C13 | `winter.bookPage.objectIds` = the 18 theme-only ids; `city.bookPage.objectIds` = the 5; neither has a `reward` |
| C14 | `environment.blocks ≤ 400`; `placements + blocks + built markers + 3 + 12 ≤ 2000 − 64` in both themes |
| C15 | `Markers.validate(..., { requireGolden = 5 })` returns no errors; 9 booster/trap sub-kinds all present |
| C16 | 12 `sightline` keep-outs, one per spawn; no base T4/T5 placement (other than the landmarks) inside any |
| C17 | `ambient.pigeons` has ≤ 8 entries per `district` and none inside a `marker` keep-out |
| C18 | Tier 1 blocks (kerbs, stoops) with top between 1.0 and 1.5 exist next to every spawn |

## Pace contract

`Pace.simulate(world, themeId)` returns the second at which a greedy eater, from each of the 12 spawns, first
reaches D ≥ 2.4 (first pickup), 5, 12, 30 and 80. Accepted windows: ≤ 5 s; 10–50 s; 70–110 s; 145–185 s; ≤ 240 s.
The same `Growth` and `Absorb` rules as the game; no clock, no randomness.

## Switching themes

Changing `activeThemeId` between `"winter"` and `"city"` and nothing else must: load with no console warning, keep
the same base placements (ids and positions), and change only slot objects, overlays, variants, palette, lighting,
weather and music. `tests/studio/ThemeSwitch.spec` covers it in Studio.
