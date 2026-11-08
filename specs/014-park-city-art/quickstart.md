# Quickstart: validating Park City art

Run from the repo root. Studio steps follow AGENTS.md: preflight, sync probe, no touching the desktop.

## Every stage

```bash
scripts/check.sh                              # gate 1: format, lint, types, tokens, tests, layout and world --check
python3 scripts/park_city_layout.py --check   # overlaps, coverage rule, limits
python3 scripts/park_city_world.py --check    # generated modules, strings, coverage report all fresh
lune run tests/unit/run                       # all unit tests, including ParkCityDress and ParkCityBudget
```

Expect exit 0. After a dress-table edit: `python3 scripts/park_city_world.py`, then `--check`.

## 1. Coverage report (US1, SC-001)

1. Open `specs/014-park-city-art/coverage.md`. Totals add up to 219 kinds; every stand-in has a note.
2. `lune run tests/unit/run` includes `ParkCityDress`: every placed kind resolves to a mesh or a `w-*` role.
3. Owner build list at the end of the report is ordered by value.

## 2. Theme switch (US2, SC-002)

1. Set `ACTIVE_THEME = "city"` in `scripts/park_city_dress.py`; run `park_city_world.py`; sync with Rojo.
2. Check the generated diff: only `activeThemeId` changes (`git diff src/shared/Content/Worlds/ParkCity.luau`).
3. In Studio (Edit): `Worlds.activeThemeId` is `"city"`; the Plaza landmark is `giant_duck`; in `winter` it is `mega_tree`.
4. Winter contrast: roads dark, lawns and roofs snow. The Lune contrast test passes.

## 3. Light objects (US3, FR-007)

1. `start_stop_play`; on `Client` read the `LightObject`-tagged parts near a spawn: MeshParts for kinds with a mesh, each
   with the atlas `TextureID`; Parts for stand-ins; visible count at most 450.
2. Roll through a dense block; no console errors; the Jest spec `LightFieldMeshes` passes.

## 4. Spawns and playability (US4, SC-003)

1. `lune run tests/unit/run` includes `ParkPace`: playability floors pass; pace report rewritten
   (`specs/012-park-city-map/pace-report.md`).
2. Each spawn: 20 doorstep crumbs, nothing above 1 stud within 15 studs (existing `ParkCity` test).

## 5. Map edge (US5, FR-009)

1. Present the regenerated SVG maps to the owner first (layout change). Then sync.
2. Fixed shot `edge` from the ground and from a mid-game camera height; the band reads as a place.
3. Edge Parts do not collide and are not tagged as objects (Lune test).

## 6. Late-game and finale (US6, SC-004)

1. `ParkCityClearance` and the finale supply floor pass in Lune.
2. Studio: set D to 35, 60, 100 with `Flags.DebugSize`; drive the Spokes, Plaza, Ring Road with the client velocity
   driver; record stuck incidents (target 0) and the Glass Tower eaten at D 96+.

## 7. Budgets (SC-005)

1. `ParkCityBudget` prints unculled and culled totals and the part count.
2. `ParkHeavyScene` + `ParkHeavySampler`, 12 balls, 60 s: parts under 2,000; every unthrottled second at 30 fps or more;
   throttled seconds (15 fps) reported separately.
3. Set the ceilings in `Config.Budgets` from that run; the test now fails above them.

## 8. Gate 2 and Gate 6 (SC-006)

1. Gate 2: full playtest, `get_console_output` shows no new errors or warnings.
2. Shots: the 11 pinned names plus `roof_run`, `giant_oak`, `edge`, `overview_high`, each in `city` and `winter`, saved
   in `specs/014-park-city-art/shots/`.
3. Open the pull request; the owner plays the build and approves the shots. Record it in `playtest.md`.
