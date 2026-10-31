# Contract: Rules and code changes (007)

The only code outside content data. Each change is small, pure where it lives in `src/shared/Rules`, and has a
Lune test. Rules stay free of Roblox APIs, `require(script…)`, clocks and randomness (Principle III;
`scripts/check.sh` purity guard).

## 1. `Worlds.luau` (shared, not a Rule)

```text
local active: WorldDef =
    if Config.Flags.Downtown then Downtown
    elseif Config.Flags.SnowVillage then SnowVillage
    else GreyBoxRoom
```

- `Downtown` is required beside `SnowVillage`. Everything below that line is unchanged: theme resolution, the
  `themeBookPages` build, `forTheme`, indexes.
- Behaviour 1: with `Downtown = true`, `Worlds.active.worldId == "downtown"` and `Worlds.resolved` carries the
  `winter` objects, zones and palette.
- Behaviour 2: with `Downtown = false, SnowVillage = true`, the result is exactly today's.
- Behaviour 3: `Worlds.forTheme("city")` resolves with no overlays and no hero variants.

## 2. `Rules/Markers.validate` (R-04)

Signature gains one optional trailing argument; existing calls are unchanged.

```text
Markers.validate(markers, blocks, keepOutAreas, halfExtent, defs, opts?)
opts = { requireGolden: number? }      -- minimum count of GoldenSpot markers; nil = no requirement
Markers.GOLDEN_FOOTPRINT = { w = 6, d = 6 }
```

| Input | Result |
| --- | --- |
| marker `kind = "GoldenSpot"`, `subKind = "golden"` | valid kind; footprint is `GOLDEN_FOOTPRINT` centred on `x, z`, `yaw` ignored; no `waypoints` allowed |
| `GoldenSpot` with any other `subKind` | error `marker subKind <id> is <x> for GoldenSpot` |
| `GoldenSpot` overlapping a solid block, another marker, outside the world, or with no covering `marker` keep-out | the same errors as other markers (`marker overlap`, `marker bounds`, `marker keepout`) |
| `opts.requireGolden = 5` with 4 golden spots | error `marker coverage GoldenSpot golden needs 5, has 4` |
| `BoosterSpot` / `TrapSpot` | unchanged |

`SUBKINDS` stays booster + trap only; the golden rule is separate so Snow Village (no golden spots) stays valid.
`findRow` must not be called for `GoldenSpot`.

## 3. `WorldBuilder.buildMarkers` (server)

`GoldenSpot` markers are skipped before the `findRow` lookup (`continue`): no part, no tag, no count. Nothing else
in the builder changes. `BoosterService` already filters on `BoosterSpot`.

## 4. `Config` (data)

| Key | Change |
| --- | --- |
| `Flags.Downtown` | new, `true` |
| `DefaultWorldsUnlocked` | gains `downtown = true` (existing keys unchanged) |
| `Budgets`, `growthK`, `startDiameter`, `baseSpeed`, `speedCap` | **unchanged** |

`worldsUnlocked` has no reader today (R-02). A later world-picker must read a missing key as
`Config.DefaultWorldsUnlocked[key]`.

## 5. `Content/Themes.luau`

`winter.lighting.clockTime`: `15.5` → `16.5`. No other field changes.

## 6. Client: `PigeonController` (new, R-14)

```text
PigeonController.start(world: WorldDef, camera, ballPart): ()   -- reads world.ambient.pigeons; no-op if nil
```

- ≤ 8 pigeons per `district`; parts are anchored, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`,
  never given the `Absorbable` tag, never replicated.
- Flies off (client tween, 1.2 s, upward and away) when the player's ball is within 12 studs; not restored that run.
- Skipped when `Settings.reduceMotion` is true.
- Registered in `Main.client` behind `Flags.Downtown`.

## 7. Art scripts

- `scripts/art-budgets.luau`: `build()` returns the union of Snow Village and Downtown object ids (Downtown keyed
  `dt_<id>`, theme-only objects included) plus `hub`. `scripts/art-sync.luau` rewrites `art/scripts/budgets.json`.
- `tests/unit/ArtManifest.test.luau`: iterate both worlds; `#manifest.meshes` equals the combined count.
- `art/scripts/build_objects.py`: `--world downtown` writes `art/source/dt_tier{1..5}.blend` and `dt_theme.blend`.
  `export_all.py` is unchanged (it exports every collection and checks it against `budgets.json`).

## 8. Existing tests that change

| Test | Change |
| --- | --- |
| `Config.test` | default-unlock test also expects `downtown`; `Flags.Downtown == true` |
| `Themes.test` line 177 | `winter.clockTime == 16.5` |
| `Pace.test` | parametrised on world and theme; Downtown × {winter, city} added |
| `Markers.test` | golden-spot cases (§2) |
| `ArtManifest.test` | both worlds (§7) |
| `Strings.test` | Downtown key block |
| `tests/studio/RunManager.spec` | derive world id, ids and expected diameter from `Worlds.active` and `Growth` |
| `tests/studio/ThemeSwitch.spec` | Downtown hero variant `donut_food_truck` → `dt_cocoa_truck` |
| other studio specs naming `snow_village` / `acorn` | audited; made world-agnostic (R-17) |
