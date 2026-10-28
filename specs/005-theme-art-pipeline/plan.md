# Implementation Plan: Season-Theme System and Stylised-Real Art Pipeline

**Branch**: `005-theme-art-pipeline` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-theme-art-pipeline/spec.md`

## Summary

Make a world's look a piece of data and make the art pipeline produce that look, without adding any Downtown
content (that is 004e). Three strands, in dependency order:

1. **Atlas and pipeline (Python, Blender)**. `art/scripts/palette.py` becomes a pure-Python (stdlib only, no
   Blender) generator that reads `docs/design/tokens.json` and writes one deterministic 1,024 px gradient atlas
   per theme, `art/palette.json` (UV layout) and `art/atlases/atlas.json` (pixel hashes). `export_all.py`
   learns the new rules (split normals, UV inside one cell or strip with a half-texel inset, new budgets).
   A one-off `remap_uv_atlas.py` moves the 65 existing meshes' UVs from the old 256 px grid to the new atlas.
2. **Theme data and resolution (Luau, Lune-tested)**. `Content/Themes.luau` holds the six themes (palette,
   lighting, weather, music keys). A world binds each theme it supports to its own slots, overlays, hero
   variants, theme-only objects and book page (`WorldDef.themeBindings`). A new pure module
   `Rules/ThemeResolve.luau` turns *base world + theme id* into the placements, objects, palette and lighting
   the game uses. `Worlds.luau` calls it once at require time with `world.activeThemeId`.
3. **Runtime and proof (Roblox, Studio-checked)**. `ObjectVisual` applies the theme atlas and tier collision
   fidelity, a new client `WeatherController` runs the single capped emitter, `Feedback` plays the theme
   music, `BookUi` shows returning theme pages. Snow Village gets one slot of each kind, one overlay per
   theme, one hero variant and a `city` binding as the data-only proof (`winter` ⇄ `city`).

No remote, profile schema, price or tool changes: no owner-approval item is triggered (see Constitution Check).

## Technical Context

**Language/Version**: Luau (`--!strict`, Roblox/Rojo 7.7.1, luau-lsp strict); Python 3 stdlib only for
`palette.py`; Python 3 + `bpy` (Blender 5.2.3 LTS, via the Blender MCP) for the other `art/scripts/*.py`.

**Primary Dependencies**: none new. Existing: Rokit toolchain (StyLua, Selene, luau-lsp, Lune 0.10.x, Rojo),
Blender + `mcp-for-blender==2.2.4`, Roblox Studio MCP. `scripts/design-tokens.py` already uses stdlib Python.

**Storage**: files only. `art/atlases/*.png`, `art/atlases/atlas.json`, `art/palette.json`, `art/palette.png`,
`art/export/*.fbx` + `manifest.json`. No DataStore change: theme book pages reuse the existing
`profile.book[bookId]` map (Profile schema version unchanged).

**Testing**: Lune unit tests in `tests/unit` (new `Themes`, `ThemeResolve`, `Atlas`; extended `Book`, `Config`,
`ArtManifest`, `SnowVillage`, `Strings`); `python3 art/scripts/palette.py --check` as a new `scripts/check.sh`
step; Jest-Lua specs in `tests/studio` for the runtime rules; agent-driven Studio playtest and capture.

**Target Platform**: Roblox (mobile first, 30 fps on the mid-range reference phone), 12 players per server.

**Project Type**: Roblox game (Rojo project) plus a Blender/Python art pipeline.

**Performance Goals**: ≥ 30 fps in a 640 × 360 Studio capture on the proof layout; one weather emitter,
≤ 40 live particles; active server parts < 2,000 (Snow Village is at 1,702 today).

**Constraints**: `src/shared/Rules` stays free of Roblox APIs and of `require(script…)`; Content modules are
data with no requires; world assets use one material, one atlas, no PBR/transparency/prop lights; every string
in en + es; nothing the player can see is date-driven.

**Scale/Scope**: 6 themes × 64 cells + 8 strips; 1 world proving 2 themes (`winter`, `city`); ~32 slot
placements (≈ 2 % of 1,610); 65 meshes get new UVs; ~25 new strings.

## Constitution Check

*GATE: passed before Phase 0; re-checked after Phase 1 (below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | Pass | Gate was met by 001 and 004 (`playtest.md` sign-offs 2026-10-26/27). This feature adds no mechanic; it is the art/pipeline work that follows. Outside-people playtest stays in 004d. |
| II Server authority | Pass | No remote, no client-sent value. Theme and variant resolution happen at require time on both sides from the same data; absorb validation still reads `Worlds.objectById`. |
| III Pure, tested rules | Pass | New logic lives in `Rules/ThemeResolve.luau` and `Rules/Book.luau` (no Roblox API, no `require(script`; the one dependency, `Layout.expand`, is passed in as an argument). Fixed-value Lune tests. `check.sh` purity guard unchanged. |
| IV Safe for everyone | Pass | Proof stand-ins are an ice lolly, beach ball, paddling pool, ice-cream truck, giant duck (inflatable), towel, string lights: none a person, live animal, brand or word. Atlas strips have no words or logos (generator draws patterns only). Maturity answers unchanged. |
| V Ethical monetization | Pass | Returning theme page never says "limited" and never shows a timer; a Lune test forbids both words in the returning keys. |
| VI Mobile first | Pass | Weather ≤ 40 particles and off with Reduce motion; 30 fps capture at 640 × 360; Book labels use the existing ≥ 18 px text style; the returning label is text plus an icon, not colour alone. |
| VII Content is data | Pass | Theme = data (`Themes.luau` + `themeBindings`), chosen by `activeThemeId`; `Config.Flags.ThemeSystem` gates the behaviour; Lune tests validate ids, completeness, budgets, keep-outs. No date check. |
| VIII Player data | Pass | No schema, key or migration change; theme `bookId`s are plain strings in the existing `book` map. |
| IX Strings | Pass | Theme names, new object names, book page names and returning labels go in `Strings.luau` with en + es; `Strings.test` extended. |
| X Multi-agent | Pass | Own branch/worktree. Blender tasks claim "Blender" in `tasks.md`, Studio tasks claim "Studio". `[P]` tasks touch disjoint files (see Delivery order). No live publish. |
| XI Asset pipeline | Pass | This feature *implements* v2.0.0: one 1,024 px atlas per theme from `tokens.json`, UVs inside one cell/strip, one material, split normals, no SurfaceAppearance/transparency/prop lights, uploaded ids only in `Assets.luau`. |
| XII Keep it lean | Pass | No new tool, package or service. Atlas generation uses Python's stdlib (`zlib`, `struct`, `hashlib`, `colorsys`) rather than Pillow or Blender, so it runs in CI as it is. Abstractions each have ≥ 2 users (see Complexity Tracking for the two close calls). |

**Human Approval Required**: none triggered. Asset *uploads* (6 atlases, 65 re-UV'd meshes) remain the owner
hand-off used in 004 (Principle X: agents do not publish live); the code is written so the game is correct
before and after that upload (research R-07).

### Post-design re-check (after Phase 1)

Unchanged: all rows still pass. Two points checked against the design: (a) `ThemeResolve` takes `expand` as an
argument, so the purity guard still passes without touching `Layout`; (b) the `Assets.meshUv` switch (R-07) is
data in `Assets.luau`, the only file allowed to hold ids.

## Spec deviations to confirm

These are places where the plan resolves a conflict between the spec text and the code or the constitution.
None changes the owner's decisions recorded in the spec. Items D1–D3 need a one-line spec edit if accepted.

- **D1: slots, overlays, hero variants, theme-only objects and book page live on the world, not on the theme.**
  FR-001 puts them in `ThemeDef`, but they name *objects of one world's catalogue*; Downtown's `winter` would
  collide with Snow Village's `winter`. FR-002 already allows "world-specific … bindings per theme", so
  `ThemeDef` keeps the look (palette, lighting, weather, music, name) and `WorldDef.themeBindings[themeId]`
  holds the rest. Validation (FR-011) is unchanged.
- **D2: `Worlds.forTheme` is `Rules/ThemeResolve.resolve`.** `Worlds.luau` uses `script.Parent` and cannot run
  in Lune. `Worlds.forTheme(themeId)` is a thin wrapper used at runtime and by Studio specs.
- **D3: glow child (`glowRole`, Neon) is not built.** FR-004 says Tier 4–5 heroes *may* have it; no hero in
  this feature uses it (first user is 004e), so it waits for two users (Principle XII). The *ban* on lights,
  SurfaceAppearance and transparency is enforced now.
- **D4: hero cells 32–63.** `tokens.json` only defines the 32 `w-*` roles. This plan adds a `color.hero` list
  to it (six cells for the legacy Snow Village swatch names, each a reference to a `w-*` role, and 26
  reserved cells coloured `#ff00ff` so any accidental use is obvious). 004e replaces the reserved cells.
- **D5: the default `maxPlacements` is 1,400 but Snow Village already places 1,610.** Snow Village sets
  `maxPlacements = 1700` explicitly (1,610 + overlay headroom, inside the 2,000-part budget at 1,702 today +
  about 100). The 1,400 default stays in `Config` for worlds that omit the field.

## Project Structure

### Documentation (this feature)

```text
specs/005-theme-art-pipeline/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R-01 … R-12
├── data-model.md        # Phase 1: entities, fields, validation, state
├── quickstart.md        # Phase 1: how to prove it end to end
├── contracts/
│   ├── theme-content.md # Themes, WorldDef additions, ThemeResolve, Worlds, Assets, Config, Book, runtime
│   └── art-pipeline.md  # Atlas layout, palette.json, atlas.json, script CLIs, export rules, UV remap
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
docs/design/tokens.json                       # + color.hero (D4); regenerate with scripts/design-tokens.py
scripts/
├── design-tokens.py                          # also rewrites the GENERATED PALETTES block in Themes.luau; --check
├── art-budgets.luau                          # unchanged logic; budgets.json regenerated for the new numbers
└── check.sh                                  # + "Atlas determinism" and "Design tokens in sync" steps

art/
├── palette.png  palette.json                 # 1,024 px winter atlas + new layout map (schema v2)
├── atlases/{city,winter,spring,autumn,toon,neon}.png   # generated, committed
├── atlases/atlas.json                        # per-theme pixel sha256 + layout version
├── scripts/
│   ├── palette.py                            # rewritten: stdlib Python, generate + --check
│   ├── build_shared.py                       # new constants (atlas geometry, inset)
│   ├── export_all.py                         # new rules
│   ├── remap_uv_atlas.py                     # NEW (Blender): legacy cell → atlas cell
│   ├── qa_grid.py                            # NEW (Blender): one prop × six atlases
│   └── budgets.json                          # regenerated
└── README.md                                 # updated pipeline

src/shared/
├── Config.luau                               # budgets, flag
├── Assets.luau                               # palettes{}, meshUv, musicWinter/musicCity
├── Worlds.luau                               # resolve at require time; new exports
├── ObjectVisual.luau                         # atlas TextureID, role colour, fidelity by tier
├── Content/Themes.luau                       # NEW: six ThemeDefs
├── Content/GreyBoxRoom.luau                  # types: ObjectDef.role, WorldDef additions
├── Content/Worlds/SnowVillage.luau           # slots, bindings, keep-outs, maxPlacements
├── Rules/ThemeResolve.luau                   # NEW (pure)
├── Rules/Book.luau                           # + themePages
└── Localization/Strings.luau                 # + theme/object/book strings (en, es)

src/client/
├── WeatherController.luau                    # NEW
├── Feedback.luau                             # theme music, atlas preload
├── BookUi.luau                               # theme pages after tier pages
└── Main.client.luau                          # start WeatherController

src/server/WorldSpawner.luau                  # passes Worlds.resolved to WorldBuilder

tests/unit/   Themes.test, ThemeResolve.test, Atlas.test (new); Book, Config, ArtManifest, SnowVillage, Strings (extended)
tests/studio/ ObjectTemplates.spec (fidelity, no SurfaceAppearance/lights/transparency), ThemeSwitch.spec (new)
```

**Structure Decision**: extend the existing single Rojo project and the `art/` pipeline in place. New pure
logic goes in `src/shared/Rules` (Lune-tested), data in `src/shared/Content`, Roblox-only code in
`src/client` and `ObjectVisual`. The Python atlas generator is its own stdlib-only script so CI and any agent
can run it with no Blender.

## Delivery order and parallelism

Tasks are generated by `/speckit-tasks`; this is the dependency spine they follow.

| # | Slice | Files (disjoint → `[P]`-safe) | Needs |
| --- | --- | --- | --- |
| 1 | tokens + atlas generator + `--check` + `Atlas.test` | `tokens.json`, `design-tokens.py`, `art/scripts/palette.py`, `art/atlases/*`, `art/palette.*`, `tests/unit/Atlas.test` | – |
| 2 | Config/Assets/Strings groundwork, budgets regen | `Config.luau`, `Assets.luau`, `budgets.json`, `Config.test`, `ArtManifest.test` | – `[P]` with 1 |
| 3 | `Themes.luau` + `ThemeResolve` + `Book.themePages` + tests | `Content/Themes.luau`, `Rules/ThemeResolve.luau`, `Rules/Book.luau`, their tests | 1 (palette block), 2 |
| 4 | Snow Village proof data | `SnowVillage.luau`, `GreyBoxRoom.luau` types, `Strings.luau`, `SnowVillage.test` | 3 |
| 5 | `Worlds.luau` wiring, `ObjectVisual`, `WorldSpawner` | those three | 3, 4 |
| 6 | Weather, music, Book UI | `WeatherController`, `Feedback`, `BookUi`, `Main.client` | 5 `[P]` internally |
| 7 | Blender: export rules, UV remap, re-export, QA grid | `export_all.py`, `build_shared.py`, `remap_uv_atlas.py`, `qa_grid.py`, `art/export/*` | 1; **Blender claim** `[P]` with 3–6 |
| 8 | Studio proof: Jest specs, theme switch, 640 × 360 capture, fps | `tests/studio/*`, `captures/` | 5, 6; **Studio claim**, 🔒 tasks |
| 9 | Owner hand-off: upload atlases + meshes, flip `Assets.meshUv` | `Assets.luau` | 7, owner |

## Complexity Tracking

Two choices that could look like speculative abstraction, kept because each has a concrete current use.

| Choice | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| `Assets.meshUv = "legacy" \| "atlas"` | Meshes uploaded today carry old-grid UVs; texturing them with the new atlas would paint wrong colours. The flag lets the code ship before the owner re-uploads, and prevents a half-migrated state. | Switching atlas by "id is non-empty" breaks the game the moment an atlas is uploaded without the re-UV'd meshes. |
| `ThemeResolve.resolve` takes `expand` as an argument | `Rules/` may not `require` siblings (Roblox and Lune load paths differ) and `Worlds.luau` is not loadable in Lune. | Duplicating `Layout.expand` in the rule, or leaving resolution inside `Worlds.luau`, would leave the core of FR-003 untestable. |
