# Contract: Rules and code changes (008)

The only code outside content data. Rules stay free of Roblox APIs, `require(script…)`, clocks and randomness
(Principle III; the `check.sh` purity guard). **Nothing under `src/shared/Rules` changes.**

## 1. `Config.luau` (data)

| Key | 007 | 008 |
| --- | --- | --- |
| `cameraMaxDistance` | 80 | **320** |
| `Budgets.defaultMaxPlacements` | 1400 | **1500** |
| `Budgets.maxActivePartsPerServer`, `growthK`, `startDiameter`, `baseSpeed`, `speedCap`, `cullTierDelta` | – | unchanged |

- `Rules.Movement.cameraDistance(D, 4, 8, max)` is `4·D` clamped to `[8, max]`: D 80 now gets 320, D 20 still 80.
- `CameraController` reads the Config value and does not change.

## 2. `GreyBoxRoom.luau` (types)

`BlockDef.kind` stays a `string`. Its doc comment lists the supported values: `"Block"` (default), `"Wedge"`,
`"Cylinder"`, **`"Boundary"`**. No new field, no type change, so `Strict` analysis of every world is unaffected.

## 3. `WorldBuilder.buildGeometry` (server)

One new branch, tested by the Studio checks and by `Downtown.test` as data:

| Input | Result |
| --- | --- |
| `kind = "Boundary"` | anchored `Part`, `Transparency = 1`, `CanCollide = true`, `CanQuery = false`, `CanTouch = false`, `CastShadow = false`, `Material = SmoothPlastic`; **no palette lookup**; counts toward the returned block count |
| any other kind | unchanged, including the unknown-swatch error |

- Snow Village and the grey-box room define no `Boundary` block, so nothing about them changes.
- The unknown-swatch error is still raised for a non-`Boundary` block with a missing swatch.
- `Boundary` data still carries a valid `swatch` (`w-asphalt`) so the type is satisfied and the order of checks in
  tests is simple.

## 4. Unchanged, checked

| File | Why it needs no change |
| --- | --- |
| `Worlds.luau` | reads `Config.Flags` and `Downtown`; resolves themes as before |
| `WorldSpawner.luau` | reads `halfExtent` (clamps scatter to `halfExtent − 2`) |
| `Rules/Markers.validate` | bounds are `halfExtent`; 440 passes |
| `Rules/Layout.expand` | grid size and capacity errors are data-driven |
| `Rules/Absorb`, `Growth`, `Tiers` | `Absorb` ratio fixed by the spec; `growthK` is world data |
| `WorldCuller` | tier culling by `cullTierDelta`; `CanQuery = false` on colliders keeps rays clean |
| `CameraController` | see §1 |

## 5. Existing tests that change

| Test | Change |
| --- | --- |
| `Config.test` (105) | `defaultMaxPlacements == 1500`; add `cameraMaxDistance == 320` |
| `Downtown.test` (139, 140) | `outerHalfExtent == 560`, `maxPlacements == 1500` |
| `Downtown.test` (733) | block coordinate bound from 303 to `halfExtent + 8` for `Boundary`, `halfExtent + 2` for others |
| `Downtown.test` (926) | `hub.center.x == −620` |
| `Downtown.test` C14 (690) | see `contracts/world-content.md` |
| `Pace.test` | obstacle-aware eater, new windows, `simulateTwelve` (`contracts/pace-and-tests.md`) |
| `SnowVillage.test` | **unchanged** (keeps 300 / 400 / −460, `maxPlacements` 1700) |
| `tests/studio/WorldSpawner.spec`, `ThemeSwitch.spec`, `RunManager.spec` | audited for a hard-coded extent, spawn count or object id; made read from `Worlds.active` where they are not |
