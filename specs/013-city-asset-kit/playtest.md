# Gate 2 smoke test (013 city asset kit)

Run 2026-11-07 by the agent through the Studio MCP (studio `Rollossal`), Rojo synced (the eight changed modules matched
the repo byte counts: Assets, Config, CityKit, GreyBoxRoom, CityKitStrings, Localizer, ObjectVisual, ThemeResolve). Play
was started fresh after the sync; nothing was placed in a map (plan D12), objects were built by `execute_luau` on `Server`.

| Check | Result |
| --- | --- |
| `ObjectVisual.build` for `tree_oak` (theme atlas, mesh id `""`) | stand-in `Part` 13 x 16 x 13, no error |
| same for `shop_bakery` and `billboard_404` (`atlas = "fronts"`, ids `""`) | stand-in `Part` at the object's dims, no error |
| same for `meme_buffering_billboard` and `meme_wet_floor_sign` | stand-in `Part`, no error |
| `Assets.frontsAtlases.city` and `.winter` | both `""`; the fronts branch returns no `TextureID` and raises no warning |
| `ThemeResolve.resolve` of a toy world with `slot.meme.t2` to `t5` fixed placements | resolves under both themes |
| data-only swap: city binds `t4` to the cone statue and `t5` to the banana, winter binds `buffering billboard` and `vacant lot` | resolved objects differ, placement ids and positions equal |
| console (`get_console_output`) | no error or warning from game scripts |

Console lines seen and not from game scripts: DataStore and ProfileStore "API access not enabled" (Studio setting) and
three `ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type` lines. The id is not in
the repository (grep over `src`, `tests`, `scripts`, `docs`, `art/scripts`), so it is Studio's own.

Not covered here: real mesh upload (the ids are `""` until the owner's batch), a visual check of a placed kit object, and
phone sizes. The kit is not placed in any map by this feature.

## Phase 9 Stage A: late-afternoon lighting (T074, Gate 2)

Run 2026-11-07 by the agent through the Studio MCP (studio `Rollossal`). The sync probe over the 83 game scripts
returned `mismatches = {}` (Themes 19,893 bytes after StyLua, WorldBuilder 22,107). Play was started fresh after the
sync. The active world is unthemed, so its own lighting stays; the theme lighting was applied in the running server by
calling `WorldBuilder.applyLighting` with `Themes.city.lighting`, then `Themes.winter.lighting`, then
`Themes.spring.lighting` (the function only writes to the `Lighting` service, so the MCP's fresh module copy runs the
same code the game runs).

| Check | City | Winter |
| --- | --- | --- |
| `ClockTime` / `Brightness` | 16.8 / 2.6 | 16.5 / 2.2 |
| `ShadowSoftness` / `GeographicLatitude` | 0.12 / 41 | 0.18 / 52 |
| `FogStart` / `FogEnd` | 250 / 1100 | 180 / 900 |
| `OutdoorAmbient` | (142, 168, 196), cool | (152, 171, 196), cool |
| `ThemeGrading` `ColorCorrectionEffect` contrast / saturation / tint | 0.12 / 0.06 / (255, 246, 236) | 0.10 / -0.04 / (240, 246, 255) |

- City then winter leaves exactly one `ThemeGrading` effect (updated, not duplicated); applying spring (no grading)
  removes it.
- Console (`get_console_output`): no error or warning from game scripts. Only the known Studio lines: DataStore and
  ProfileStore "API access not enabled" and `ContentId rbxassetid://203785492 failed` (not in the repository).
- Not covered: the look in Studio. A themed city or winter world is not the active world in the dev place, and the
  pilot meshes are not uploaded yet (owner batch), so the owner's play check of the pilot stays in
  `docs/release-candidate.md`.

## Gate 2, Stage B (2026-11-08)

- Sync probe on the changed modules (Assets, CityKit, Themes, Downtown, CityKitStrings, Config, WorldSpawner,
  WorldBuilder): `mismatches = {}`.
- Playtest (Server): `CityKit.objects` has 96 entries, `CityKit.notDefault` present, the world built 1,405 parts, one
  player joined. Console: the usual DataStore-in-Studio lines and Studio's own `ContentId rbxassetid://203785492` line
  (not in the repo); no game script errors or warnings.

## Gate 2, Stage C (2026-11-08)

- Full sync probe (106 modules, including Assets 13,481, CityKit 41,507, CityKitStrings 11,029 and Downtown 60,146
  bytes): `mismatches = {}`.
- Playtest (Server): `CityKit.objects` has 121 entries, the world built 1,456 parts with 1,139 sized objects, one
  player joined. Console: the usual DataStore and ProfileStore lines from Studio, plus Studio's own
  `ContentId rbxassetid://203785492` line (not in the repo). No errors or warnings from game scripts.
- Not covered: the look of the new meshes in Studio. The 121-entry check is the kit's data table: no world places a
  `ck_*` object yet, and the rebuilt `dt_*` meshes are not uploaded (owner batch), so the world still shows the old
  `dt_*` meshes. The owner's play check stays in `docs/release-candidate.md`.
