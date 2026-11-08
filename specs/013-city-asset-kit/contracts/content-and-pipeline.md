# Contract: Content and Pipeline

Covers FR-010 to FR-012, SC-006 and the hand-off. These are the exact conventions the build tasks must follow.

## `CityKit.luau`

`src/shared/Content/CityKit.luau`, `--!strict`, returns `{ objects: { ObjectDef } }`. It does not require `Downtown`.

| Field | Value |
| --- | --- |
| `id` | the id from `data-model.md` §2 |
| `bookId` | `"citykit." .. id` |
| `nameKey` | `"object.citykit." .. id` |
| `assetKey` | `"ck_" .. id` |
| `tier`, `size` | `data-model.md` |
| `atlas` | `"fronts"` for the 17 fronts-atlas objects, otherwise absent |
| `coins`, `icon`, `shade`, `role`, `dims`, `bulk`, `solid`, `light` | filled like the Downtown `objectDef()` helper does for the same tier; `light` is never set on a prop |

No `src/shared/Content/Worlds/*.luau` file requires it in this feature. 004i, 010 and 012 add the placements.

## `ArtBudgets` and `budgets.json`

`ArtBudgets.meshes()` appends `CityKit.objects` after Downtown with `world = "city_kit"`. `ArtBudgets.build()` is unchanged
in shape; `sizes` and `tiers` now also hold the 84 `ck_*` keys. `lune run scripts/art-sync` regenerates
`art/scripts/budgets.json`; `ArtManifest.test` fails if the committed file is stale.

## `ArtManifest.test` changes

| Assertion | Now |
| --- | --- |
| "Downtown asks for 99 meshes" | unchanged (the `ck_` keys are in a third set) |
| new: "CityKit asks for 84 meshes, all keyed ck_ and disjoint from the other two sets" | added |
| `Assets.meshes` holds no key a world does not ask for | `kitKeys[key]` is an allowed owner |
| manifest count | `#SnowVillage.objects + 1 + downtownBuilt + kitBuilt` |
| `REQUIRE_ASSET_IDS=1` | `downtownBuilt == 99` and every kit key present; kit ids may be `""` until the hand-off lands, so the "every mesh has an imported id" test skips `ck_` keys with `""` and reports the count |
| hash and triangles from the FBX | applies to every manifest row, including `ck_*` |

## `Assets.luau`

| Item | Rule |
| --- | --- |
| New mesh keys | 84 lines `ck_<id> = "",` in one sorted block after the last existing mesh line |
| Existing `dt_*` lines | never removed or reordered; an upgrade keeps its line and old id |
| Fronts atlas | `frontsAtlases = { city = "", winter = "" }`, keyed like `palettes`, other themes absent |
| Hard-coded ids elsewhere | none (existing scan stays) |

## `ObjectVisual.textureId` (D7)

`textureId(def)`: if `def.atlas == "fronts"` and `Assets.renderingMode == "atlas"` and a theme is active and
`Assets.frontsAtlases[theme.paletteAssetKey]` is not `""`, return it. Otherwise the current branch. With an empty fronts id
the object has no `TextureID`, the same result as an unset theme atlas today. No new warning path.

## `export_all.py` and the manifest

| Step | Rule |
| --- | --- |
| Source of ids | `budgets.json` `tiers` (now includes `ck_*`) |
| Theme-atlas meshes | validated against `art/palette.json` as today |
| Fronts meshes | validated against `art/atlases/fronts/fronts.json`: each face's UVs inside one sign cell, billboard cell or facade strip |
| Output | `art/export/<id>.fbx`; one `manifest.json` row `{id, tier, triangles, bytes, sha256}` |
| Batches | export one zone at a time; each batch is one commit; an upgrade rewrites its own row only |

## Localisation

`src/shared/Localization/CityKitStrings.luau` returns `{ [key]: { en: string, es: string } }` for 84 keys
`object.citykit.<id>`; `Localizer.luau` merges it as it does `ParkCityStrings`. `Strings.test` requires every `CityKit`
`nameKey` to have both languages. Shop names on textures are not keys. Sign text that is not a shop name is a pictogram.

## Owner hand-off (FR-011, SC-005)

Each export batch adds one row to `docs/release-candidate.md` under "Owner hand-offs": the batch name, the FBX paths, the
count, the manifest commit, and the `Assets.luau` keys to fill. Until the owner gives ids the keys stay `""`, and
`ObjectVisual` draws the stand-in part with its palette colour (existing behaviour, one warning per key). The same section
carries the two fronts atlas PNGs (`city`, `winter`).

## Gate 2 smoke test

After strand 5 and 6 merge in the branch: with Rojo synced and Studio claimed, an `execute_luau` call on `Server` in a scratch
copy of the place builds one object of each of: a theme-atlas `ck_` prop with `""`, a fronts-atlas shop with `""`, and each
`slot.meme.t*` binding; `get_console_output` shows no error from game scripts. The result goes in `playtest.md`.
