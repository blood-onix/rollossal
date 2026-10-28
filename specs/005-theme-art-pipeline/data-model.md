# Data Model: Season-Theme System and Stylised-Real Art Pipeline

Types are Luau (`--!strict`) unless marked JSON. Field names match the spec; where the plan moved a field
(spec deviation D1) it says so. "Test" names the Lune file that enforces a rule.

## 1. ThemeDef (`src/shared/Content/Themes.luau`, data only, no requires)

| Field | Type | Rule |
| --- | --- | --- |
| `id` | `"city" \| "winter" \| "spring" \| "autumn" \| "toon" \| "neon"` | unique; equals a `tokens.json` theme id |
| `nameKey` | `string` | `theme.<id>.name`; has `en` and `es` in `Strings` |
| `paletteAssetKey` | `string` | key in `Assets.palettes` (the key equals the theme id) |
| `palette` | `{ [cellName]: { number } }` | exactly 64 cells (32 `w-*` + 32 hero, see §4) plus `light-sky`, `light-fog`, `light-ambient`; each value 3 integers 0–255; equals the `tokens.json` colour (Test: Themes) |
| `lighting` | `LightingDef` | colours derived from `light-*` (below); `brightness` 0–5, `clockTime` 0–24, `fogEnd > fogStart > 0`, `atmosphereDensity` 0–1 |
| `weather` | `WeatherDef` | §2 |
| `musicAssetKey` | `string` | key in `Assets.sounds` (value `""` allowed = no track) |

`LightingDef` is the existing type in `Content/GreyBoxRoom.luau` (unchanged). Derivation, checked by test:
`ambient = light-ambient`, `outdoorAmbient = light-sky`, `fogColor = light-fog`, `atmosphereColor = light-sky`,
`atmosphereDecay = light-fog`.

Planned look per theme (the numbers are authored in the file; ranges only are tested):

| Theme | `clockTime` | Weather | Music key |
| --- | --- | --- | --- |
| `winter` | 15.5 (today's Snow Village) | `snow` | `musicWinter` |
| `city` | 13 | `none` | `musicCity` (`""`) |
| `spring` | 14 | `petals` | `musicSpring` (`""`) |
| `autumn` | 16.5 | `leaves` | `musicAutumn` (`""`) |
| `toon` | 12 | `none` | `musicToon` (`""`) |
| `neon` | 22 | `sparkle` | `musicNeon` (`""`) |

## 2. WeatherDef

| Field | Type | Rule |
| --- | --- | --- |
| `kind` | `"snow" \| "petals" \| "leaves" \| "sparkle" \| "none"` | |
| `rate` | `number` | particles per second; `0` when `kind == "none"` |
| `maxParticles` | `number` | integer 0–`Config.Budgets.maxWeatherParticles` (40) |
| `lifetime` | `number` | seconds (the larger end of the emitter's range); `> 0` unless `kind == "none"` |
| `color` | `{ number }` | 3 integers |
| `size` | `number` | studs, `> 0` |
| `speed` | `number` | studs/second, `>= 0` |

Rule (Test: Themes): `rate × lifetime ≤ maxParticles ≤ 40`. The emitter's `Rate` is `rate` exactly.

## 3. World additions (`WorldDef`, `Content/GreyBoxRoom.luau` types; data in `Worlds/SnowVillage.luau`)

| Field | Type | Rule |
| --- | --- | --- |
| `activeThemeId` | `string?` | in `supportedThemes`; absent ⇒ no theme (pre-005 behaviour) |
| `supportedThemes` | `{ string }?` | order = order of theme pages in the Book; each has a binding and a `ThemeDef` |
| `themeBindings` | `{ [themeId]: ThemeBinding }?` | §3.1 (replaces the spec's "themeOverrides / ThemeDef.slots …", deviation D1) |
| `keepOutAreas` | `{ KeepOut }?` | `kind` ∈ `gate`, `shortcut`, `sightline`, `marker`; `w, d > 0` |
| `maxPlacements` | `number?` | default `Config.Budgets.defaultMaxPlacements` (1400); Snow Village sets 1700 |

`ObjectDef` gains one optional field: `role: string?` (a palette cell name; the stand-in part takes its
`Color` from `theme.palette[role]`, falling back to the tier colour). `ObjectDef.assetKey` already exists.

### 3.1 ThemeBinding

| Field | Type | Rule |
| --- | --- | --- |
| `slots` | `{ [slotId]: objectId }` | must define every slot id the world's zones/fixed placements use; the object's `tier` equals the slot's tier (`slot.small`=1 … `slot.landmark`=5); the object's size ≤ the size of the winter/base object it replaces in the same slot zone, so zones still fit |
| `overlays` | `{ zones: { ZoneDef }, fixedPlacements: { PlacementSeed } }` | ids unique against the base; objects exist in `world.objects` or this binding's `objects`; no overlap with any `KeepOut` |
| `heroVariants` | `{ [baseObjectId]: { assetKey: string, nameKey: string?, size: number? } }` | `assetKey` exists in `Assets.meshes`; `size`, when given, within ±10 % of the base object's size; gameplay always uses the **base** size, tier, coins, `bookId`, collision class |
| `objects` | `{ ObjectDef }?` | theme-only objects (slot objects and overlay objects not in the base kit); `bookId` unique across the world; sizes inside the tier's size range; not counted by base tier pages |
| `bookPage` | `ThemeBookPage?` | §5 |

Slot ids and tiers: `slot.small` T1, `slot.medium` T2, `slot.yard` T3, `slot.street` T4, `slot.landmark` T5.

**Zone rule** (R-06): in `world.zones`, a zone's `mix` contains either only slot ids or no slot ids.

### 3.2 KeepOut

`{ id: string, kind: "gate" | "shortcut" | "sightline" | "marker", x: number, z: number, w: number, d: number }`,
axis-aligned, centre `x, z`, full extents `w, d`.

## 4. Palette cells (the 64) and the atlas layout

Cell index `i = 0 … 63`, `col = i % 8`, `row = i // 8`.

| Cells | Rows | Names | Source |
| --- | --- | --- | --- |
| 0–31 | 0–3 | the 32 `w-*` tokens in `tokens.json` order | `color.tokens[name].value[theme]` |
| 32–37 | 4 | `snow`, `snow_light`, `stone`, `wood`, `brick`, `ice` | `color.hero[i].ref` → a `w-*` role (R-04) |
| 38–63 | 4–7 | `hero-07 … hero-32` | `#ff00ff`, `reserved` (004e overwrites) |

Trim strips 0–7: `trim-grille`, `trim-vent-slats`, `trim-tyre-tread`, `trim-window-frame`,
`trim-brick-course`, `trim-panel-seams`, `trim-kerb-stone`, `trim-wood-grain`. Pixel geometry and JSON schemas
are in [contracts/art-pipeline.md](contracts/art-pipeline.md).

`light-sky`, `light-fog`, `light-ambient` are not atlas cells; they are carried in `ThemeDef.palette` for the
lighting derivation only.

## 5. Book entities

```
ThemeBookPage = {
  id: string,             -- "<worldId>.<themeId>", e.g. "snow_village.city"
  nameKey: string,        -- page title, en + es
  returningKey: string,   -- shown when the theme is not active, en + es; must not contain "limited", "left", "ends", "hurry", digits-with-colon (a timer)
  reward: RewardDef?,     -- in the type for 006a; unused and not granted in 005
  objectIds: { string },  -- ids in the binding's `objects` (theme-only); non-empty
}

PageSummary (existing, tier pages)  +  themeId: string?, isActive: boolean?, returningKey: string?
  -- theme page: tier = 0, collectedCount/totalCount over objectIds, entries like tier pages
```

Rules: a `bookId` appears on at most one page; base tier pages never include binding `objects`
(Test: Book, Themes). Progress is the existing `profile.book[bookId] = true`; no schema or migration change.

## 6. Resolved world (output of `ThemeResolve.resolve`, built once by `Worlds.luau`)

| Field | Content |
| --- | --- |
| `themeId` | `world.activeThemeId` |
| `zones`, `fixedPlacements` | base with slots replaced, plus overlays |
| `placements` | `expand(zones)` then fixed (ids unique) |
| `objects` | base objects with hero variants applied, plus the **active** binding's `objects` |
| `environmentPalette` | `world.environment.palette` overlaid with `theme.palette` |
| `lighting` | `theme.lighting` |
| `slotPlacementIds` | placement ids that came from slot zones/fixed slots (for the share test) |

Invariants (Test: ThemeResolve): non-slot placements (id, objectId, x, y, z, yaw) are identical for every
supported theme; the number of placements and of slot placements is the same for every theme; the resolved
object ids are unique; the share `#slotPlacementIds / #placements ≤ Config.Budgets.maxDressingSlotShare`.

`Worlds.luau` exposes the resolved result as `Worlds.resolved` (a `WorldDef` whose `objects`,
`environment.palette`, `lighting` are the resolved ones) and keeps `Worlds.active` as the **base** world, so
code that must count only the base kit (Book tier pages, reward ids) keeps reading `Worlds.active`.

## 7. Asset and config shape

`Assets.luau` additions:

```
Assets.palettes = { city = "", winter = "", spring = "", autumn = "", toon = "", neon = "" }  -- content ids
Assets.meshUv   = "legacy"        -- "legacy" | "atlas" (R-07)
Assets.sounds.musicWinter = <today's id>; musicCity/musicSpring/musicAutumn/musicToon/musicNeon = ""
-- Assets.palette (legacy texture) stays until the owner hand-off completes; Assets.sounds.music is renamed musicWinter
```

`Config.luau` additions: `Budgets.meshTriangles = { 500, 700, 1500, 3500, 5000 }`,
`Budgets.maxWeatherParticles = 40`, `Budgets.maxDressingSlotShare = 0.15`,
`Budgets.defaultMaxPlacements = 1400`, `Flags.ThemeSystem = true`, `weatherEmitterHeight = 30`,
`weatherEmitterSize = 60` (studs; the emission box above and around the camera).

## 8. State and transitions

- **Theme choice** is static per server: `Worlds` resolves `activeThemeId` once at require time. A "switch" is
  a content edit plus a release. There is no remote, no live toggle, no date check.
- **Flag**: `Config.Flags.ThemeSystem == false` ⇒ `Worlds.resolved == Worlds.active` (no slots, no overlays,
  no theme palette, world's own lighting, no weather) and the old palette texture. This is the rollback.
- **Atlas migration** (R-07): `meshUv = "legacy"` → (owner uploads, one commit) → `meshUv = "atlas"`; the
  `Assets.palette` field is then deleted.
- **Per player**: only `profile.book` changes (existing path). A theme page is "active" when its `themeId`
  equals `Worlds.activeThemeId`, else "returning"; progress is never reset.

## 9. Relationships

```
tokens.json ──design-tokens.py──▶ Themes.luau (GENERATED PALETTES block) ─┐
     │                                                                     ├─▶ ThemeDef
     └──palette.py──▶ art/atlases/<id>.png, atlas.json, art/palette.json   │
                                       │                                   ▼
Blender sources ─remap_uv_atlas.py─▶ export_all.py ─▶ FBX ─(owner upload)─▶ Assets.palettes / Assets.meshes
                                                                           │
WorldDef ── themeBindings[themeId] ──▶ ThemeResolve.resolve(world, theme, Layout.expand) ──▶ Worlds.resolved
                                                                           │
                          ObjectVisual · WorldBuilder · WorldSpawner · WeatherController · Feedback · BookUi
```
