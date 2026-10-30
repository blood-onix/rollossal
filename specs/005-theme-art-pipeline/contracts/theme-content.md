# Contract: Theme content, resolution and runtime

Interfaces other code and tests depend on. Types are in [data-model.md](../data-model.md). All Luau files start
with `--!strict`.

## 1. `Content/Themes.luau` (data; no Roblox APIs; no requires)

```lua
export type ThemeDef = { id, nameKey, paletteAssetKey, palette, lighting, weather, musicAssetKey }
return { city = ThemeDef, winter = ThemeDef, spring = ..., autumn = ..., toon = ..., neon = ..., order = { "city", "winter", ... } }
```

- The table is keyed by theme id; `order` lists ids in `tokens.json` theme order (used by tests and the QA grid).
- The block between `-- BEGIN GENERATED PALETTES (scripts/design-tokens.py)` and
  `-- END GENERATED PALETTES` is written by `python3 scripts/design-tokens.py`; nothing else in the file is.
- `python3 scripts/design-tokens.py --check` exits 1 if the block, `tokens.css` or `tokens.md` is stale.

## 2. `Rules/ThemeResolve.luau` (pure; no Roblox API; no `require(script`)

```lua
export type Resolved = {
  themeId: string,
  zones: { Zone },
  fixedPlacements: { Placement },
  placements: { Placement },
  objects: { ObjectLike },
  environmentPalette: { [string]: { number } },
  lighting: LightingLike,
  slotPlacementIds: { [string]: boolean },
}

ThemeResolve.SLOT_TIERS: { [string]: number }   -- slot.small=1 … slot.landmark=5
ThemeResolve.isSlot(objectId: string): boolean   -- string.sub(id, 1, 5) == "slot."
ThemeResolve.resolve(
  world: WorldLike, theme: ThemeLike, expand: (zones: { Zone }, sizes: { [string]: number }) -> { Placement }
): Resolved
```

Behaviour (each line has a fixed-value test in `ThemeResolve.test.luau`):

1. `world.themeBindings[theme.id]` missing ⇒ `error("ThemeResolve: world X has no binding for theme Y")`.
2. A slot id with no entry in `binding.slots` ⇒ `error` naming the slot and theme.
3. A zone whose `mix` mixes slot and non-slot ids ⇒ `error`.
4. A slot mapped to an object whose tier differs from `SLOT_TIERS[slot]` ⇒ `error`.
5. Inputs are not mutated (the function returns new tables; base `world` stays reusable for the next theme).
6. Output order: expanded base zones, base fixed placements, expanded overlay zones, overlay fixed placements.
   Base placement ids are the same for every theme.
7. `heroVariants[baseId]`: the resolved object is a copy of the base object with `assetKey` (and `nameKey` when
   given) replaced; `id`, `tier`, `size`, `coins`, `bookId` unchanged. Unknown `baseId` ⇒ `error`.
8. `expand` is called once, with the sizes of the *resolved* object list, so slot zones size their cells from the
   themed object.

`Worlds.luau` (Roblox side) passes `Layout.expand`; the tests pass `require("../../src/shared/Rules/Layout").expand`.

## 3. `Worlds.luau` exports (additions)

| Name | Type | Meaning |
| --- | --- | --- |
| `Worlds.active` | `WorldDef` | the **base** world (unchanged meaning) |
| `Worlds.activeThemeId` | `string?` | `active.activeThemeId` (regardless of `Config.Flags.ThemeSystem`; the flag gates lighting, weather and music) |
| `Worlds.activeTheme` | `ThemeDef?` | `Themes[activeThemeId]` |
| `Worlds.resolved` | `WorldDef` | base world with resolved `objects`, `environment.palette`, `lighting` |
| `Worlds.forTheme(themeId)` | `(string) -> Resolved` | resolves any supported theme (Studio specs, QA); wraps `ThemeResolve.resolve` |
| `Worlds.placements`, `placementById`, `objectById`, `objectByBookId`, `objectsByTier`, `sizes` | as today | now built from the resolved result (so they include the active theme's objects) |
| `Worlds.baseObjects` | `{ ObjectDef }` | `active.objects` (tier pages) |
| `Worlds.themeBookPages` | `{ ThemeBookPageWithObjects }` | for each `supportedThemes` entry that has a `bookPage`: the page plus the `ObjectDef`s it lists (active **or** not) |

Consumers keep working: `WorldSpawner` passes `Worlds.resolved` and `Worlds.placements` to `WorldBuilder.start`;
`WorldBuilder` is unchanged apart from the checks in §6 because the resolved world already carries the themed
palette and lighting.

## 4. `Rules/Book.luau` (addition)

```lua
export type ThemePageDef = { id, nameKey, returningKey, themeId, objectIds: { string } }
Book.themePages(pages: { ThemePageDef }, objects: { BookObject }, book: { [string]: boolean }, activeThemeId: string?): { PageSummary }
```

- One `PageSummary` per page, `tier = 0`, `themeId`, `isActive = (themeId == activeThemeId)`,
  `returningKey` (set only when not active), entries in `objectIds` order, `collectedCount/totalCount/isComplete`
  as for tier pages, `rewardEarned = false`.
- `Book.pages` and `Book.completedRewardIds` behave exactly as before (existing tests stay green).

## 5. `Assets.luau` and `Config.luau`

See data-model §7. Contract rules:

- `ObjectVisual` and `Feedback` read ids only through `Assets`. A new Lune check in `ArtManifest.test` keeps the
  "no `rbxassetid://` outside `Assets.luau`" scan and now also scans `src/client/WeatherController.luau`.
- With `REQUIRE_ASSET_IDS=1`: every `Assets.meshes` entry non-empty; if `meshUv == "atlas"`, every
  `Assets.palettes` entry non-empty and `Assets.palette` must be absent.

## 6. Runtime behaviour

**`ObjectVisual`**

- `buildMesh(assetKey, label, longestSide, tier?)` sets `RenderFidelity = Automatic`; `CollisionFidelity = Box`
  for `tier` 1–3 and `Hull` for 4–5 (default `Box` when `tier` is nil, e.g. the hub); never sets a
  `SurfaceAppearance`, light, or `Transparency` above 0.
- Texture: if `Assets.meshUv == "atlas"` and `Assets.palettes[theme.paletteAssetKey] ~= ""` ⇒ that id;
  elseif `meshUv == "legacy"` and `Assets.palette ~= ""` ⇒ `Assets.palette`; else no `TextureID` (the mesh
  keeps the engine default). Never both.
- Stand-in `Part`: `Color = theme.palette[def.role]` when `def.role` and a theme are set, else the existing
  `shade` / tier colour. `Material = SmoothPlastic` for stand-ins; `Transparency = 0`.
- The warn-once rule is unchanged (one warning per object id).

**`WorldBuilder`**: ground and hub parts keep `Material.SmoothPlastic` and `Transparency = 0` (markers keep
their existing invisible parts); swatch names resolve through `world.environment.palette`, which already holds
the theme colours.

**`WeatherController` (client)**

```lua
WeatherController.start()                         -- from Main.client; no-op when the flag is off or kind == "none"
WeatherController.isEmitting(): boolean           -- for Studio specs
```

- One emitter total; created on `start`, destroyed never; `Enabled` follows
  `ReduceMotion ~= true and weather.kind ~= "none"`; `:Clear()` on every transition to disabled.
- Emitter `Rate = weather.rate`, `Lifetime = NumberRange.new(weather.lifetime * 0.8, weather.lifetime)`,
  `Size`, `Speed`, `Color` from data; never reads `Config` numbers other than `maxWeatherParticles`,
  `weatherEmitterHeight`, `weatherEmitterSize`.
- Follows `workspace.CurrentCamera` on `RenderStepped`; handles camera replacement.

**`Feedback`**: music track = `Assets.sounds[Worlds.activeTheme.musicAssetKey]`; empty id ⇒ nothing plays and no
warning; the `Sound` is named `ThemeMusic`; the preload list skips every `music*` key as before and adds the
active atlas id when it is non-empty.

**`BookUi`**: `summaries()` = `Book.pages(sizeTiers, Worlds.baseObjects, …)` followed by
`Book.themePages(...)`. A theme page shows `Localizer.t(nameKey)`, the progress line, and for a non-active
page one line `Localizer.t(returningKey)` with an icon from `Icons` (not a clock). Minimum text size 18 px.
`defaultPage()` still prefers the first incomplete **tier** page.

## 7. Strings (`Localization/Strings.luau`, English and Spanish)

New keys (every one has `en` and `es`; `Strings.test` extended):

- `theme.<id>.name` × 6 (Sunny City, Holiday City, Blossom City, Harvest City, Toon City, Night City)
- `object.snow_village.<id>` for the 7 theme-only stand-ins and 1 hero variant name
- `book.page.snow_village.winter.name`, `book.page.snow_village.city.name`
- `book.page.snow_village.winter.returning`, `book.page.snow_village.city.returning`
- `ui.book.theme_returning` is **not** needed: the per-page `returningKey` carries the sentence.

A test fails if any returning string contains `limited`, `left`, `ends`, `hurry` or a `0:00`-style timer
(English and Spanish equivalents: `limitado`, `quedan`, `termina`, `date prisa`).

## 8. Tests that pin this contract

| File | Proves |
| --- | --- |
| `Themes.test` | 6 unique ids; 64 cells + 3 light cells per theme equal `tokens.json`; lighting derivation and ranges; weather cap arithmetic; keys exist in `Assets`/`Strings` |
| `ThemeResolve.test` | behaviours 1–8 with small hand-written worlds; non-slot placements identical across themes; error cases |
| `SnowVillage.test` (extended) | the proof counts in research R-11; winter placements ⊇ today's; slot share ≤ 15 %; overlays vs keep-outs; hero variant ±10 %; per-theme zone capacity (`Layout.expand` does not throw); theme-only objects inside tier size ranges; part budget with overlays ≤ 2,000 |
| `Book.test` (extended) | theme pages: counts, active/returning flags, preserved progress after switching, no `tier` page includes theme-only objects |
| `Config.test` / `ArtManifest.test` (extended) | new budgets; `budgets.json` in sync; id scan |
| `tests/studio/ObjectTemplates.spec`, `ThemeSwitch.spec` | fidelity by tier, no SurfaceAppearance/lights/transparency, theme applied to templates; reduce-motion toggles the emitter |
