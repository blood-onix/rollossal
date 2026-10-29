# Research: Season-Theme System and Stylised-Real Art Pipeline

Every "NEEDS CLARIFICATION" from the Technical Context is resolved here. Each entry: **Decision**,
**Rationale**, **Alternatives considered**. Facts about the current repo were read on 2026-10-28.

## R-01: How the atlas PNGs are produced

**Decision**: `art/scripts/palette.py` is plain Python 3 using only the standard library. It writes PNGs with
`zlib` + `struct` (8-bit RGB, filter type 0, `zlib.compress(level=9)`), reads `docs/design/tokens.json` with
`json`, and does colour maths with `colorsys`. It has two modes: no flag (generate) and `--check` (regenerate
in memory and compare against the committed files). It does **not** import `bpy`.

**Rationale**: the current `palette.py` imports `bpy` only to save an image, which makes it impossible to run
in CI (`scripts/check.sh` has no Blender) and means "deterministic" cannot be enforced. Pillow is not
installed here and a new package needs owner approval (Principle XII); a stdlib PNG writer is about 25 lines.
`python3` is already a project dependency (`scripts/design-tokens.py`) and is present on the CI runner.

**Determinism**: PNG bytes can differ between zlib builds, so the committed contract is the **pixel hash**:
`art/atlases/atlas.json` stores `sha256` of the raw scanline buffer (filter byte + RGB, row by row) per theme.
`--check` rebuilds the buffer, compares it to `atlas.json` and also decodes each committed PNG's pixel data
(`zlib.decompress` of the IDAT chunks) and compares it, so a hand-edited PNG fails. A Lune test
(`Atlas.test.luau`) separately checks that every PNG exists, has a 1,024 × 1,024 IHDR, and that `atlas.json`
lists exactly the six theme ids.

**Alternatives**: Blender's `bpy.data.images` (needs Blender in CI, float round-trips); Pillow (new
dependency); storing uncompressed PNGs (3 MB × 6 in git); byte-hashing PNGs (breaks on a zlib upgrade).

## R-02: Gradient maths

**Decision**: for a cell with base colour `c` (sRGB bytes), convert to HSL with `colorsys.rgb_to_hls`,
multiply lightness by a factor that goes **linearly from 1.12 at the cell's top pixel row to 0.85 at its bottom
pixel row** (`factor(y) = 1.12 − 0.27 · y/63`, `y = 0..63`), clamp lightness to `[0, 1]`, convert back,
`round()` to bytes. Hue and saturation are untouched.

**Rationale**: the spec says "+12 % … −15 % lightness". A *relative* change keeps dark roles (`w-rubber`)
visibly gradient-shaded rather than clamped, and white/near-white roles lose shade at the bottom, which is
what the bake-in AO wants. Done in sRGB-HSL, not linear light, because the design previews are sRGB too and
the artist reads it in the same space. Python floats are IEEE-754 doubles, so the result is identical on
every machine.

**Alternatives**: additive ±12/−15 points of lightness (clamps white at the top, makes black flat); working in
linear light (looks different from the design previews).

## R-03: Trim strips

**Decision**: eight strips, each 1,024 × 64 px, drawn with integer arithmetic only (no random numbers, no
floats beyond the colour conversion of the role colours). Order and role colours:

| # | Strip | Pattern | Colours |
| --- | --- | --- | --- |
| 0 | `trim-grille` | 8 px dark bars every 16 px, 2 px frame lines top and bottom | `w-metal` base, `w-metal-dark` bars |
| 1 | `trim-vent-slats` | 6 px slats every 12 px, lower edge of each slat 2 px darker | `w-metal`, `w-metal-dark` |
| 2 | `trim-tyre-tread` | 12 px blocks alternating at 16 px, rows offset by 8 px | `w-rubber`, `w-asphalt` |
| 3 | `trim-window-frame` | 4 px frame and a mullion every 128 px around a glass field | `w-trim`, `w-glass` |
| 4 | `trim-brick-course` | 16 × 8 px bricks, mortar 2 px, offset every other course | `w-wall-b`, `w-trim` |
| 5 | `trim-panel-seams` | 1-px seams every 64 px, 2-px lighter edge | `w-metal`, `w-metal-dark` |
| 6 | `trim-kerb-stone` | 96 px stones with a 3-px joint | `w-kerb`, `w-sidewalk` |
| 7 | `trim-wood-grain` | horizontal lines at fixed offsets from a small integer sequence `(i·37) mod 11` | `w-wood`, `w-bark` |

**Rationale**: all patterns are pictograms with no glyphs (Principle IV), tile horizontally (1,024 is a
multiple of every period used), and recolour per theme because they read role colours.

**Alternatives**: noise textures (need a seeded RNG; harder to test); bitmap files committed by hand (not
reproducible per theme).

## R-04: Cells 32 to 63 (the level's hero rows)

**Decision**: add `color.hero` to `docs/design/tokens.json`: 32 entries in a fixed order.
Entries 0–5 are the legacy Snow Village swatch names, each a **reference** to a `w-*` role so they recolour
per theme: `snow → w-season`, `snow_light → w-roof-a`, `stone → w-kerb`, `wood → w-wood`,
`brick → w-wall-b`, `ice → w-water`. Entries 6–31 are named `hero-07 … hero-32` with the single value `#ff00ff`
and `"reserved": true`. `scripts/design-tokens.py` ignores `color.hero` for CSS/Markdown (so the design site is
unchanged) and exposes it to the palette generator and the Luau block (R-05).

**Rationale**: the spec requires all 64 cells in all themes but `tokens.json` defines only the 32 shared
roles. References (not copied hex) keep one source of truth. Magenta for unassigned cells is a standard
"unmapped" signal: if a face ever lands there the QA grid shows it at once.

**Alternatives**: leave rows 4–7 transparent (a theme "must fill all 64", and transparency is banned);
duplicate the `w-*` colours (hides mistakes); let 004e add the cells later (the validator and `ThemeDef`
completeness test need the 64 now).

## R-05: Where the Luau palette values come from

**Decision**: `Content/Themes.luau` has one block between the lines
`-- BEGIN GENERATED PALETTES (scripts/design-tokens.py)` and `-- END GENERATED PALETTES` that defines
`local palettes: { [string]: { [string]: { number } } }` (theme id → cell name → `{ r, g, b }`; 64 cells plus
`light-sky`, `light-fog`, `light-ambient`, one cell per line so StyLua leaves it alone).
`scripts/design-tokens.py` rewrites exactly that block (and `--check` compares). The hand-written part of the
file builds each `ThemeDef` from `palettes[id]`. `Themes.test.luau` also reads `tokens.json` with
`@lune/serde` and asserts every value equals the token's hex, so drift fails `check.sh` even if someone edits
the block by hand.

**Rationale**: Content modules must have no `require` (Roblox uses `script.Parent`, Lune uses paths), so the
palette must live in the same file as the theme. Generation prevents 6 × 67 hand-typed numbers; the test is
the safety net. Colours in `lighting` are derived in Luau from the same block
(`ambient = light-ambient`, `outdoorAmbient = light-sky`, `fogColor = light-fog`, `atmosphereColor = light-sky`,
`atmosphereDecay = light-fog`); the scalar values (`brightness`, `clockTime`, `fogStart`, `fogEnd`,
`atmosphereDensity`) are hand-authored per theme and range-checked.

**Alternatives**: a separate generated `ThemePalettes.luau` (cannot be required from `Themes.luau` in both
runtimes); reading JSON at runtime (Roblox cannot); duplicating by hand with only a test (error-prone).

## R-06: Theme look versus world binding; how resolution works

**Decision**: split the data by who owns it (spec deviation D1).

- `ThemeDef` (global, `Content/Themes.luau`): `id`, `nameKey`, `paletteAssetKey`, `palette`, `lighting`,
  `weather`, `musicAssetKey`.
- `WorldDef.themeBindings[themeId]` (per world): `slots`, `overlays`, `heroVariants`, `objects` (theme-only
  `ObjectDef`s), `bookPage`.
- `WorldDef.activeThemeId`, `supportedThemes`, `keepOutAreas`, `maxPlacements` as in FR-002.

`Rules/ThemeResolve.resolve(world, theme, expand)` (pure) does, in order:

1. Replace slot ids in `zones[].mix[].objectId` and `fixedPlacements[].objectId` with `binding.slots[slotId]`.
2. Build the object list: the world's objects, with `heroVariants` applied (`assetKey`, optional `nameKey`),
   plus the binding's theme-only `objects`.
3. `expand(zones + overlay zones, sizes)` where `sizes` comes from step 2, then append the fixed placements
   and overlay fixed placements.
4. Merge `theme.palette` over `world.environment.palette` (theme wins) and take `theme.lighting`.

It returns plain tables; `Worlds.luau` and the Lune tests both call it (the tests pass `Layout.expand`).

**The purity rule that keeps "base placements unchanged"**: a zone's `mix` is either **all slot ids or no slot
ids** (validated). `Layout` derives cell size from the zone's largest object, so mixing a slot into a normal
zone would move every other object in it when the theme changes. Slot-only zones keep all non-slot
placement ids, positions and yaws bit-identical across themes. The slot share is then simply
(placements from slot-only zones and slot fixed placements) ÷ (all placements).

**Rationale**: matches design doc `01-world-kit.md` (slots = where, theme = what) while fixing the
object-catalogue collision; the resolve logic is testable in Lune.

**Alternatives**: slots inside normal mixes (breaks the unchanged-layout guarantee); resolving inside
`Worlds.luau` (untestable); runtime theme switching with remotes (not asked for; "switch by release").

## R-07: The old meshes and the new atlas (UV migration)

**Decision**: the 65 existing meshes have UVs planar-shrunk into cells of the *old* 256 px, 8 × 8 grid. Placed
on the new atlas the same UVs land on the boundary between two rows. So:

1. `remap_uv_atlas.py` (Blender) maps each face's UVs with an **affine transform** from the legacy cell
   (identified by the swatch name table in the old `palette.json`: `snow, snow_light, stone, wood, brick, ice`,
   row 0, columns 0–5) into the inner rect of the matching new cell (`snow … ice` are cells 32–37 per R-04),
   keeping the original relative position (so a face that sat high in the cell stays high in the gradient).
   It runs on the committed `.blend` sources, so hand edits survive; recipes in `build_objects.py` are not
   re-run.
2. `Assets.meshUv` (`"legacy"` or `"atlas"`, default `"legacy"`) tells `ObjectVisual` which texture belongs to
   the *currently uploaded* meshes. In `"legacy"` it keeps using `Assets.palette` (today's 256 px asset); in
   `"atlas"` it uses `Assets.palettes[theme.paletteAssetKey]`. An empty id falls back to `Assets.palette`
   only in `"legacy"` mode.
3. Owner hand-off (task, outward-facing, ask first): upload the six atlases and the 65 re-UV'd FBX files, fill
   `Assets.palettes` and `Assets.meshes`, set `meshUv = "atlas"` in one commit, then delete `Assets.palette`.
   `ArtManifest.test` with `REQUIRE_ASSET_IDS=1` demands all six atlas ids once `meshUv == "atlas"`.

**Consequence for the proof**: until the owner uploads, a Studio theme switch shows the new look on
**ground blocks, stand-ins, lighting, weather, music and fog**; mesh colours change only after the upload.
The Studio proof therefore also covers theme-only stand-ins with `role` colours. This is stated in the
quickstart and the PR description, not hidden.

**Alternatives**: rebuild all meshes from `build_objects.py` (loses hand edits, and bevel/split-normal remodelling
is 004e's job); sample the old texture for the winter theme only (leaves the other five themes unreachable);
accept the boundary bleed (visibly wrong).

## R-08: Weather emitter and the 40-particle cap

**Decision**: `WeatherController` creates one anchored, non-colliding, fully transparent `Part`
(`Name = "WeatherEmitter"`, `CanCollide/CanQuery/CanTouch = false`, `Massless`) holding one `ParticleEmitter`.
Every `RenderStepped` it sets the part's CFrame to `camera.CFrame * CFrame.new(0, EMITTER_HEIGHT, 0)`
(emission box above the view). The part is cloned never; it is parented to `Workspace.CurrentCamera`'s
sibling folder, not to the world. The emitter uses the default engine particle texture; `weather.kind` only
chooses colour/size/speed/acceleration from the theme data (`snow`: slow, down; `petals`: slow, sideways drift;
`leaves`: larger, rotating; `sparkle`: tiny, upward, short lifetime).

**The cap**: Roblox has no API to read a live particle count, so the cap is enforced by arithmetic:
`Rate × Lifetime ≤ maxParticles ≤ Config.Budgets.maxWeatherParticles (40)`. The data validation
(`Themes.test`) asserts this inequality for every theme using the larger end of `Lifetime`, and the runtime
sets `Rate` from the data (never above `maxParticles / lifetime`). Reduce motion: `Enabled = false` and
`:Clear()` the moment `Player:GetAttribute("ReduceMotion") == true` (listened with
`GetAttributeChangedSignal`); turned on again when it clears.

**Rationale**: matches design doc Pattern 3 and the spec (FR-005). Camera-attached means the cost does not
scale with the world or the ball count.

**Alternatives**: emitter in the world (cost and culling issues); counting particles by sampling
(`ParticleEmitter` does not expose them); a Beam/Trail snow effect (not what the spec asks).

## R-09: Theme book pages

**Decision**: extend `Rules/Book.luau` with `Book.themePages(pages, objects, book, activeThemeId)` returning
`PageSummary`s with three new optional fields: `themeId`, `isActive`, `returningKey`. A theme page has
`tier = 0`. `Book.pages` (tier pages) is untouched and is called with the world's **base** objects only, so
tier pages stay completable in every theme. `BookUi.summaries()` appends the theme pages, in
`supportedThemes` order, after the tier pages; an inactive page shows `returningKey` text with a calendar-free
icon (no clock, no hourglass). `Book.completedRewardIds` is not extended: `bookPage.reward` is in the type
for 006a but unused here (no cosmetics ship in 005).

**Hero variants and book ids**: a variant keeps the base object's `bookId`, so absorbing it credits the base
entry, as the spec requires. A variant object listed on a theme page is not supported (the proof does not
need it).

**Rationale**: smallest change that keeps old tests green; the UI already pages through a list.

**Alternatives**: a second `Book` module (two users, same data: no); making inactive pages disappear
(violates "returning" requirement).

## R-10: Keep-out areas

**Decision**: `keepOutAreas` entries are axis-aligned rectangles `{ id, kind, x, z, w, d }` (centre and full
size, same convention as `ZoneDef`). The validator (in `Themes.test`, one helper, no runtime user) rejects an
overlay when its zone rectangle (zones: the whole `w × d`) or a fixed placement's footprint
(`size × size` square from the object's size) intersects any rectangle. Snow Village declares: one 10 × 10
`marker` rectangle per `environment.markers` entry (built in a loop in the world file), and four `sightline`
corridors 12 studs wide along the axes from the town square to the four landmark ring positions
(`±355, 0` and `0, ±355`). T060 (owner-approved 2026-10-29) adds `gate` and `shortcut` kinds: 24 gates, one per
side of every spawn porch (the porch ramp), and 6 shortcut alleys (4 studs across, the gaps between spawn
clusters). No placement may fall in a gate or an alley, checked for every theme in `SnowVillage.test`.

**Rationale**: the spec's wording (rectangles, four kinds); axis-aligned corridors cover Snow Village's
landmark layout; diagonal sightlines can be decomposed or added as two rectangles by 004e.

**Alternatives**: oriented boxes or polygons (more code than any current world needs).

## R-11: What the Snow Village proof contains

**Decision** (numbers pinned so tests can state them by hand):

- **Slots (5 kinds, 32 placements ≈ 2 % of 1,610, cap 15 %)**: `slot.small` 12, `slot.medium` 8, `slot.yard` 6,
  `slot.street` 4, `slot.landmark` 2 (the two `skating_rink` fixed placements `sv_landmark_05/06` become
  `slot.landmark`). Slot zones are new `sv_slot_*` zones; the counts are carved out of nearby tier-matched
  zones by lowering their `count` (the seeded layout keeps the first N placements, so the rest are unchanged)
  and placed where the existing "no two footprints overlap" test passes.
- **`winter` bindings** map slots to existing objects (`bauble`, `gift_box`, `snowman`, `sleigh`,
  `skating_rink`), so the *winter layout is today's layout plus the slot zones* and base tier pages are
  unchanged. Winter overlay: one 6-object zone of a new theme-only stand-in, `winter_lights` (Tier 2).
- **`city` bindings** map slots to five new theme-only stand-in `ObjectDef`s with no `assetKey`
  (`ice_lolly` T1 size 0.7, `beach_ball` T2 1.6, `paddling_pool` T3 6, `ice_cream_truck` T4 14,
  `giant_duck` T5 30; the winter counterparts are 0.8, 1.8, 8, 15 and 40). Each size sits inside its tier's
  range and is ≤ the winter object's, so every slot zone still fits its cells; city overlay: one 6-object zone of
  `beach_towel` (Tier 2 stand-in); hero variant `big_snowman → fountain` mesh (size 12 vs 13, within 10 %),
  with its own `nameKey`.
- **Book pages**: `winter` page = `winter_lights`; `city` page = the five slot objects + `beach_towel`.
- **Ground blocks** change from legacy swatch names (`snow`, `stone`, `wood`, `snow_light`, `brick`) to
  `w-*` roles (`w-grass`, `w-kerb`, `w-wood`, `w-sidewalk`, `w-wall-b`). `environment.palette` stays as the
  base fallback (hub floor and pad colours).
- **Sizes of these additions to the part budget**: 32 slot + about 12 overlay placements; headroom today is
  298 parts, so `maxPlacements = 1700` and the existing part-budget test still passes.

**Rationale**: the spec's Assumption says to reuse Snow Village; the unavoidable additions are stand-ins for
the `city` side. Winter equals the current look, so there is no regression for existing players.

## R-12: Verification limits and tooling

- **Blender CLI is not on PATH** on this machine (`which blender` finds nothing) but the Blender MCP is live.
  Blender-side tasks run through `execute_blender_code` (the scripts are executed with `runpy`), under the
  Blender claim (Principle X). `palette.py`, `--check` and every Lune test need no Blender.
- **Studio** checks follow `AGENTS.md`: preflight, sync probe, playtest via MCP, 640 × 360 capture by cloning
  the root frame, fps recorded per second with throttled seconds (exactly 15 fps) reported separately. The
  agent never activates Studio or the display.
- **Not measurable in Studio**: live particle count (R-08, so the arithmetic test is the evidence) and the
  phone frame rate (owner device check stays with 004d/004e).
- **Triangle budgets**: only `Config.Budgets.meshTriangles` changes (`{ 500, 700, 1500, 3500, 5000 }`);
  existing meshes are far below it. They are *provisional* until 004e's capture, as the spec says.
- **StyLua**: the generated block is one cell per line and uses tabs; `stylua --check` runs in `check.sh`,
  so a mismatch shows up immediately.
