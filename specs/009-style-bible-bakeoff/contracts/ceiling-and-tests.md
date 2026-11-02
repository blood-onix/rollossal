# Contract: Ceiling and tests

## New constants

In `tests/unit/Downtown.test.luau`, near the top with the other pinned numbers:

| Name | Value | Source |
| --- | --- | --- |
| `UNCULLED_TRIANGLE_CEILING` | `floor10k(0.8 × highest passing step)` from `playtest.md` | heavy-scene benchmark |
| `CULLED_TRIANGLE_CEILING` | same rule on that step's tier ≥ 4 set | heavy-scene benchmark |

The numbers are filled in only after the benchmark has run. Until then the old 250,000 and 100,000 stay.
`Config.Budgets` and `Config.test.luau` are not edited. Nothing at runtime reads the ceiling.

## Rewritten audit: "Downtown N10"

Current shape (lines 1451 to 1469): load `art/export/manifest.json`, map mesh id to triangles, sum over
`resolved.winter.placements`, with `culled` adding only objects of `tier >= 4`, then assert `total <= 250000` and
`culled <= 100000`.

New shape: same audit; the two literals become the named constants, and the failure message prints the constant:
`unculled {total} of {UNCULLED_TRIANGLE_CEILING}`. The `cullTierDelta = 2` rule decides the culled set; the test does
not re-derive it from `Config`, matching today's behaviour.

## Docs

`docs/design/03-city-level.md` lines 65 and 66 state the same two numbers and link to `playtest.md`.

## Tests to keep unchanged

`Config.test` (budgets `{500, 700, 1500, 3500, 5000}`), `ArtManifest.test` (every FBX hash and tier budget; 99 `dt_*`),
`Layout`, `ThemeResolve`, `Markers`, `Pace`, and every other `Downtown` test.

## New test

`tests/unit/CaptureCameras.test.luau`: loads `art/capture/cameras.json` with `@lune/fs` and `@lune/serde` and asserts:
five shots in the fixed order with the exact names; `fov == 70`; `theme` is a key of `Themes`; ball-shot camera
distance equals `min(320, max(8, 4·diameter))` within 0.01; pitch ≤ 80°; no duplicate names. It does not pin world
coordinates.

## Gate

`scripts/check.sh` exits 0 (FR-011). Python under `art/scripts/` is not linted by `check.sh`; the new Lune files under
`scripts/` and `tests/` are StyLua-formatted and pass Selene.
