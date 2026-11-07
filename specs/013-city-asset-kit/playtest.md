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
