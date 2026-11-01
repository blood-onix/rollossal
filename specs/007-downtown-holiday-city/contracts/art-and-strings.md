# Contract: Art, strings and the owner hand-off (007)

## Mesh rules (FR-007, Constitution XI)

Per mesh, checked by `art/scripts/export_all.py` and `ArtManifest.test`:

| Rule | Value |
| --- | --- |
| Collection and object name | the `dt_<id>` key |
| Material | exactly one, `Palette` |
| UVs | every face inside one `128 × 64` px cell or the `1,024 × 64` px strip of `art/palette.json`, inset 1 px |
| Top face | mapped to `w-season` |
| Triangles | `≤ Config.Budgets.meshTriangles[tier]` = 500 / 700 / 1,500 / 3,500 / 5,000 |
| Origin / size | bottom centre; longest bounding side equals `ObjectDef.size` |
| Modifiers | applied; world matrix identity; split normals exported |
| Collision (set in Roblox) | `Box` for Tiers 1–3, `Hull` for Tiers 4–5 |
| Banned | `SurfaceAppearance`/PBR, transparency, per-prop lights, Unions, multi-part models |
| Glow | `Material.Neon` child parts on Tier 4–5 heroes only |
| Moderation | docs/design/05-roblox-limits.md: no people or live animals, no weapons, no words on textures, bottles are water or soda |

`Assets.luau` is the only file holding `rbxassetid://` numbers. A key absent or `""` means a stand-in part.

## Waves

| Wave | Content | Meshes | Blender source |
| --- | --- | --- | --- |
| A | Tier 1 core | 18 | `art/source/dt_tier1.blend` |
| B | Tier 2 core | 15 | `dt_tier2.blend` |
| C | Tier 3 core | 16 | `dt_tier3.blend` |
| D | Tier 4 core | 16 | `dt_tier4.blend` |
| E | Tier 5 core | 9 | `dt_tier5.blend` |
| F | Holiday City: 5 slots, 13 overlays, 2 variants | 20 | `dt_theme.blend` |
| G | Sunny City slots (may defer to 011) | 5 | `dt_theme.blend` |

Total 99 (94 for launch). A wave is playable with stand-ins for the rest.

## Owner hand-off checklist (per wave)

1. Agent: model in Blender, run `export_all.py`, `lune run scripts/art-sync`, `scripts/check.sh` green.
2. Owner: import the wave's FBX files through Studio's 3D Importer; send the asset ids.
3. Agent: write the ids into `Assets.meshes` (keys per R-03); run the Studio capture; owner approves the look.
4. Never paste an id anywhere but `Assets.luau`.

## Strings (Principle IX)

All new keys have `en` and `es`. Counts: 99 `object.downtown.*`, 10 `tier.downtown.*`, 4 `book.page.downtown.*`.

| Key | en | es |
| --- | --- | --- |
| `book.page.downtown.winter.name` | Downtown: Holiday | Centro: Fiestas |
| `book.page.downtown.winter.returning` | Back for the holidays | De vuelta por fiestas |
| `book.page.downtown.city.name` | Downtown: Sunny | Centro: Soleado |
| `book.page.downtown.city.returning` | Back for the sunshine | De vuelta con el sol |

(Examples; the owner may reword.) Banned in every returning label: "limited", "ends", "hurry", digits, dates,
timers, "only". `Strings.test` asserts the ban with a pattern check.

## Safety checklist per object (Principle IV)

Run before each wave's upload hand-off: no person/animal shape (the `light_up_reindeer` is a wire-frame lamp
frame, flagged for owner review), no weapon silhouette, no brand/flag/landmark, no word on any face, upright
intact vehicles only, bottles clearly water or soda, nothing gambling-like (no dice, no slot or claw machine).
