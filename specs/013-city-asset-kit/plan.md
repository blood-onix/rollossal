# Implementation Plan: Dedicated City Asset Kit, Style Audit, Shop Signage & Meme Originals

**Branch**: `013-city-asset-kit` | **Date**: 2026-11-07 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/013-city-asset-kit/spec.md`

## Summary

Bring every absorbable city object into the one "stylised real" look of `docs/design/08-style-bible.md`, as single
meshes inside their tier budgets, with a kit that lets a street avoid repeating a building. No map placement, no ball
cosmetic, no direct upload. Strands, in dependency order:

0. **Amendment prerequisite (signage only).** Constitution v4.1.0 (invented shop names, a shared fronts and signs
   atlas, a capped billboard set) is on PR #10 and was not confirmed merged when this plan was written. Strand 5
   (signage, fronts atlas, billboards) does not start until it is. Strands 1 to 4, 6 and 7 do not depend on it
   (Constitution IV and XI already allow everything they use) (R-01).
1. **Audit of the 99 `dt_*` meshes (US1).** A Blender script renders each mesh in `city` and `winter` at game-camera
   and close range, reads its triangle count from the manifest, its tier budget from `Config`, and its `w-season`
   share from the UV cells it uses, and writes `specs/013-city-asset-kit/audit/audit.json` plus a rendered table. Each
   mesh gets `keep`, `upgrade` or `replace` and a rationale. 97 of the 99 sit below their style-bible tier floor, so
   the audit applies class overrides (tiny litter, flat ground pieces) instead of upgrading everything. A
   triangle-only pass with those overrides gives a baseline of 12 keep, 36 upgrade and 51 replace; the visual pass can
   move a verdict one step and nothing else (R-02, R-03).
2. **Finalised asset list (FR-003).** 84 new `ck_*` meshes plus the retained or upgraded `dt_*`, by zone, tier and stud
   size, are in [data-model.md](data-model.md). The list is the contract for strand 3. Sizes sit inside the existing
   tier bands in `art/scripts/budgets.json` (R-04).
3. **Kit build (US2).** `art/scripts/kit_recipes.py` builds the modular building pieces as collections in
   `art/source/ck_buildings.blend`, joins them into one mesh per variant, and builds the street, park, suburb, main
   street and downtown props to their tier floor-to-target bands. Upgraded or replaced `dt_*` meshes keep their key,
   size and old uploaded id until the owner re-uploads. New `ck_*` keys are registered with `""` (R-05, R-06, R-07).
4. **Content, tests and budgets.** `CityKit.luau` (the `ck_*` object catalogue), `CityKitStrings.luau` (English and
   Spanish names), `ArtBudgets` and `ArtManifest.test` learn a third key set, `Config.Budgets.billboardTextures = 8`
   lands with its test (R-08, R-09).
5. **Signage (US3), after strand 0.** A script-generated 1,024 px fronts and signs atlas per theme (sign cells,
   billboard designs, facade tiles), about 20 vetted invented shop names, eight billboard designs, and shop-front and
   billboard meshes that use it. One small runtime change: an object can name the fronts atlas (R-10 to R-13).
6. **Meme originals (US4).** Seven inanimate originals and a `slot.meme.t2 … t5` slot family in `ThemeResolve`, bound
   per theme in data, with a Lune test that changing only the binding changes the resolved object (R-14, R-15).
7. **Contact sheets, hand-off, gates.** `contact_sheet.py` renders one sheet per zone in `city` and `winter`, plus the
   audit, signage and meme sheets. One owner hand-off batch goes on `docs/release-candidate.md`. Gate 6 images go to the
   owner (R-16, R-17).

No remote, no DataStore field, no new package. The map files (`Downtown.luau`, `SnowVillage.luau`, `ParkCity.luau`)
are not edited: the kit is a catalogue that 004i, 010 and 012 place later.

## Technical Context

**Language/Version**: Luau (`--!strict`, Lune 0.10.x via Rokit) for content, strings, budgets and tests; Python 3
(standard library only) for the audit report, the fronts atlas generator and the contact-sheet composer; Python 3
inside Blender 5.2.3 LTS (`bpy`, `bmesh`) for the kit recipes, the audit renders and the exports.

**Primary Dependencies**: none new. Blender 5.2.3 LTS through the pinned `mcp-for-blender` 2.2.4 (`art/README.md`),
Rokit toolchain, Roblox Studio MCP for one Gate 2 smoke test. Shop-name collision searches use ordinary web search by
the agent; they are evidence, not a dependency.

**Storage**: files only. Audit and contact-sheet output under `specs/013-city-asset-kit/`; sources in `art/source/`;
exports in `art/export/`; no DataStore, no `Profile` field.

**Testing**: `scripts/check.sh` (StyLua, Selene, luau-lsp strict, design tokens, `palette.py --check`, the new
`fronts_atlas.py --check`, Lune suite). New `tests/unit/CityKit.test.luau`. Edited: `ArtManifest.test`, `Config.test`,
`ThemeResolve.test`, `Strings.test`. `Downtown.test` N10 (550,000 / 290,000 scene ceilings) is read, not edited, and
must keep passing after upgrades. Agent-run Studio smoke test (Gate 2) and Blender renders (Gate 6).

**Target Platform**: Roblox, mobile first (30 fps reference phone), 12 players per server. Tooling runs on the owner's
Mac.

**Project Type**: Roblox game (single Rojo project) plus art tooling under `art/` and `scripts/`.

**Performance Goals**: no object above its tier budget (`Config.Budgets.meshTriangles`); the winter city's scene
triangle total stays under the 009 ceilings (550,000 unculled, 290,000 culled) after every upgrade. The first audit
task measures the headroom before any upgrade is built (R-03).

**Constraints**: one mesh and one material per absorbable object; no PBR, transparency or per-prop light; `w-season`
under 15 % of visible area per mesh; origin at the bottom centre; longest side within ±5 % of `budgets.json`; every
face's UVs inside one atlas cell or strip; only one agent drives Blender (Constitution X); `Assets.luau` and
`manifest.json` diffs stay small (R-09); no script touches the owner's desktop (AGENTS.md).

**Billboard texture cap (Constitution XI)**: **8 billboard designs**, all packed in the fronts and signs atlas, stored as
`Config.Budgets.billboardTextures = 8`. It is measured by a data test (design count in the atlas layout is at most the
cap) and by the atlas file size. No separate billboard texture files exist.

**Scale/Scope**: 99 audited meshes (2 themes each); 84 new meshes (25 building, 11 street, 16 park, 7 suburbs, 5 main
street, 6 downtown, 7 meme, 7 billboard); 26 shop-name candidates narrowed to at least 20; 8 billboard designs (the 7
billboard meshes plus the buffering meme billboard); fronts atlas generated for 6 themes and uploaded for 2; 9 contact
sheets (6 zones, audit, signage, meme) × 2 themes, so 18 images.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 (below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | Pass | No gameplay, pace or rule change. The pace test is untouched; only art and a catalogue. |
| II Server authority | Pass | No remote, no server code. |
| III Pure, tested rules | Pass | One `Rules` edit: new entries in `ThemeResolve.SLOT_TIERS` (pure table), with Lune tests. No new Rules file, purity guard unchanged. |
| IV Safe for everyone | Pass, signage gated | Shop names are invented proper nouns with a recorded collision search and the banned-word list; billboards are deadpan, no real ads; meme originals exclude the `04-player-cosmetics.md` keep-out list and named brainrot characters; nothing animate. Other text on the world is pictogram or a localisation key. Signage waits for the amendment (strand 0). |
| V Ethical monetization | Pass | Nothing sold, no paid placement. |
| VI Mobile first | Pass, measured | Tier budgets per object, scene ceilings re-checked by N10 after upgrades, atlas stays 1,024 px. |
| VII Content is data | Pass | The kit is `CityKit.luau` data; `slot.meme.*` binds per theme in data; a theme swaps atlases, never meshes. |
| VIII Player data | Pass | No profile change. |
| IX Strings | Pass | Every kit and meme name has `en` and `es` in `CityKitStrings.luau`; shop names on textures need no key. |
| X Multi-agent | Pass | Own branch; Blender claimed in `tasks.md`; Studio is not claimed except for one Gate 2 smoke test, scheduled when 004i does not hold it. Shared-file edits are small and listed (R-09). |
| XI Asset pipeline | Pass, signage gated | In-house Blender; one material per mesh; fronts atlas generated by script per theme; billboard cap 8 in `Config`; no CC0 import, so no licence record. |
| XII Keep it lean | Pass | Python stdlib only, no new tool, package or external service. |

Gates for this feature: **Gate 1** `scripts/check.sh` exits 0. **Gate 2** applies (a `ThemeResolve` and `ObjectVisual`
change): one Studio playtest and a console read, run by the agent. **Gate 3** each mesh is in budget and its key is in
`Assets.luau`; new meshes are `""` plus one batched hand-off on `docs/release-candidate.md`. **Gate 4** kit and meme names
in both tables. **Gate 5** tasks ticked. **Gate 6** applies: the output is world art; the PR opens with the sheets and does
not merge before the owner approves them.

**Human Approval Required**: (1) the merge of the 4.1.0 / 4.0.0 amendment (PR #10), which gates strand 5 only;
(2) the owner's mesh upload batch, which holds nothing; (3) the Gate 6 image approval, which holds the merge. The per-class
triangle overrides (D3) are added to the style bible's section 11, which the owner approved as the place for them.

### Post-design re-check (after Phase 1)

Unchanged: all rows pass; IV and XI stay gated for strand 5 only. Points checked against the design: (a) the only
`src/shared/Rules` change is four table entries in `SLOT_TIERS`, no new logic; (b) `Downtown.luau`, `SnowVillage.luau`,
`ParkCity.luau` are not edited, so 004i, 010 and 012 do not collide on content; (c) `ArtManifest.test` keeps "Downtown asks
for 99 meshes" by giving the kit its own prefix and key set; (d) upgrades keep `dt_*` keys, so the 99 stay 99 and no
`Assets.luau` line is removed; (e) `fronts_atlas.py --check` is deterministic, stdlib, and added to `check.sh` like
`palette.py --check`; (f) the 84 new meshes add no triangles to any world until a map places them, so N10 changes only by
the upgrades; (g) the amendment text in the constitution was re-read for "one material per mesh": every `ck_*` mesh uses
either the theme atlas or the fronts atlas, never both.

## Spec deviations and defaults to confirm

These resolve ambiguities. None changes an owner decision.

- **D1: billboard cap is 8 designs, packed in the fronts atlas.** The spec's default of 8 stands. "Texture" is read as
  "design", because a billboard mesh has one material and every other texture file would need its own render path.
- **D2: new meshes use the `ck_` key prefix and a third key set.** `dt_` would break the `== 99` assertions in
  `ArtManifest.test` and mix kit pieces into Downtown. `ArtBudgets.meshes()` gains `world = "city_kit"`.
- **D3: per-class triangle overrides.** Class floors replace the tier floor where a mesh cannot spend it: tiny pocket
  litter (size at most 0.8 studs) floor 40; flat ground pieces (road marking, path, kerb, crossing, blanket) floor 24;
  billboard and sign panels floor 150; hydrant-like small tier 2 props keep the tier floor. Targets stay at the tier
  target or 60 % of the budget, whichever is lower. Recorded in the bible's section 11 (R-03).
- **D4: `slot.meme` is a family `slot.meme.t2` to `slot.meme.t5`.** `ThemeResolve` maps one tier per slot. Memes span
  four tiers (wet floor sign 3 studs, pond cart 4.6, cone statue 12, banana statue 28), and forcing one tier would make
  the gags the wrong size. Four table entries keep the Rules logic unchanged; swapping is still data only (R-14).
- **D5: upgraded and replaced `dt_*` meshes keep key, size and old asset id.** The old mesh stays visible, which beats a
  stand-in, until the owner re-uploads. The manifest holds the new hash. Brand-new `ck_*` keys use `""`.
- **D6: only shop fronts, shop rows and billboards use the fronts atlas.** Houses, mid-rises, towers and all props stay
  on the theme atlas, so most of the kit does not wait for the amendment or the fronts atlas (R-10).
- **D7: per-object atlas choice is a field on `ObjectDef` (`atlas = "fronts"`).** Default is the theme atlas, so no
  existing object changes. `ObjectVisual` reads it; `Assets.frontsAtlases` holds the ids (`""` until uploaded) (R-11).
- **D8: shop names are candidates until searched.** The plan lists 26 candidates; none is called vetted until its
  search record exists (R-12). The spec's three examples are candidates too.
- **D9: city and winter only.** The fronts atlas is generated for all six themes by the same script, but only `city` and
  `winter` are uploaded and rendered, because no world uses another theme today.
- **D10: the seven meme originals** are banana statue, pond cart, cone statue, wet floor sign, phone statue at 1 %,
  bare stud-plate vacant lot and a buffering billboard. Hybrid statues are held back as an eighth if the owner wants
  one; the other billboard gags (404, number go up) are ordinary `ck_billboard_*` designs.
- **D11: shop-row and mid-rise sizes follow the existing tier bands,** so the largest tower is 60 studs, the same as
  `dt_glass_tower`. No tier band changes.
- **D12: the Gate 2 smoke test places objects by `execute_luau` in a scratch place copy,** not in a map, because
  placement is out of scope.

## Project Structure

### Documentation (this feature)

```text
specs/013-city-asset-kit/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R-01 … R-17
├── data-model.md        # Phase 1: entities, the finalised asset list, atlas layout, name candidates
├── quickstart.md        # Phase 1: how to prove it end to end
├── contracts/
│   ├── audit-and-asset-list.md      # audit.json and asset-list schema, class floors, verdict rules
│   ├── content-and-pipeline.md      # CityKit.luau, key prefix, ArtBudgets, manifest, Assets, hand-off
│   ├── fronts-atlas-and-billboards.md # atlas layout, generator CLI, Config cap, ObjectVisual field
│   ├── slot-meme.md                 # slot family, binding rules, tests
│   └── shop-names-and-memes.md      # name rules, search record, banned words, meme rules
├── checklists/requirements.md
├── audit/               # audit.json, audit.md, renders (created during implementation)
├── contact-sheets/      # city/ and winter/ PNGs, one per zone (created during implementation)
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
art/
├── scripts/
│   ├── audit_render.py         # NEW: Blender; renders each dt_* mesh, computes w-season share, writes audit.json
│   ├── audit_report.py         # NEW: stdlib; audit.json to audit.md, verdict counts, class-floor application
│   ├── kit_recipes.py          # NEW: Blender; building modules, joins, and the zone props
│   ├── fronts_atlas.py         # NEW: stdlib; generates art/atlases/fronts/<theme>.png, layout JSON, --check
│   ├── contact_sheet.py        # NEW: Blender; one sheet per zone and theme from the manifest
│   ├── export_all.py           # EDIT: also reads fronts layout for objects marked atlas fronts
│   └── budgets.json            # REGENERATED by `lune run scripts/art-sync`
├── source/
│   ├── ck_buildings.blend      # NEW: modules, variants (claimed Blender only)
│   ├── ck_props_t1_t3.blend    # NEW: small props, street, park, suburb, main street
│   └── ck_props_t4_t5.blend    # NEW: cars, trees, downtown, landmarks, memes
├── atlases/fronts/             # NEW: <theme>.png, fronts.json (layout), generated
└── export/                     # NEW ck_*.fbx; manifest.json gains 84 rows; upgraded dt_* rows change hash

src/shared/
├── Config.luau                 # EDIT: Budgets.billboardTextures = 8
├── Assets.luau                 # EDIT: 84 ck_* keys as "", frontsAtlases table; no dt_* id removed
├── ObjectVisual.luau           # EDIT: textureId(def) picks the fronts atlas when def.atlas = "fronts"
├── Content/
│   ├── CityKit.luau            # NEW: the 84 ObjectDefs, atlas field, zone tag, class tag
│   └── GreyBoxRoom.luau        # EDIT: ObjectDef gains optional `atlas` and `zone`
├── Localization/
│   ├── CityKitStrings.luau     # NEW: en and es names for the 84 objects
│   └── Localizer.luau          # EDIT: merges CityKitStrings
└── Rules/ThemeResolve.luau     # EDIT: four slot.meme.t* entries in SLOT_TIERS

scripts/
├── art-budgets.luau            # EDIT: adds CityKit.objects as world "city_kit"
├── check.sh                    # EDIT: runs fronts_atlas.py --check
└── (art-sync.luau unchanged)

tests/unit/
├── CityKit.test.luau           # NEW: schema, size bands, tiers, keys, names, billboard cap, no banned words
├── ArtManifest.test.luau       # EDIT: third key set, ck_ prefix, counts
├── Config.test.luau            # EDIT: billboardTextures = 8
├── ThemeResolve.test.luau      # EDIT: slot.meme.t* tiers and data-only swap
├── Strings.test.luau           # EDIT: kit keys in both languages
└── run.luau                    # EDIT: registers CityKit.test

docs/
├── design/08-style-bible.md    # EDIT: section 11 records the D3 class floors
├── design/shop-names.json      # NEW: vetted names, search records, banned terms (after the amendment)
└── release-candidate.md        # EDIT: owner hand-off batch, Gate 6 sheets, LoadStringEnabled note unchanged
```

`Downtown.luau`, `SnowVillage.luau`, `ParkCity.luau`, `Layout.luau` and `src/server/` are not edited.

**Structure Decision**: extend the existing layout. The kit is its own content module so the three map features and this one
never edit the same file. Scripts follow the existing split: Blender work in `art/scripts/` through the MCP, stdlib
generators beside `palette.py`, and Luau only for the data the game and tests read. Source files are split by tier range to
keep each `.blend` small enough to claim and diff.

## Delivery order and parallelism

Tasks are generated by `/speckit-tasks`; this is the dependency spine. `[P]` = no shared files, safe in parallel.
🔒 = Studio MCP task, claimed in `tasks.md` first. **B** = needs the Blender claim, one agent at a time.

| # | Slice | Files | Needs |
| --- | --- | --- | --- |
| 0 | Check PR #10 state; record in `tasks.md` | none | – gates 9 to 13 only |
| 1 | Audit script, scene-total headroom measure, class floors | `audit_render.py`, `audit_report.py`, bible 11 | **B** |
| 2 | Audit run, 99 verdicts, audit sheet | `audit/` | 1, **B** |
| 3 | `CityKit.luau` skeleton, strings, `ArtBudgets`, `ArtManifest.test`, `Config` cap | Luau + tests | – `[P]` with 1, 2 |
| 4 | Building modules and variants (25) | `kit_recipes.py`, `ck_buildings.blend` | 2, **B** |
| 5 | Props for street, park, suburbs, main street, downtown (45) | `ck_props_*.blend` | 2, **B**, `[P]` with 3 |
| 6 | Upgrades and replacements of `dt_*` per audit | `ck_props_*.blend`, `art/export/` | 2, **B** |
| 7 | `slot.meme.t*` and its test | `ThemeResolve.luau`, test | 3 `[P]` |
| 8 | Meme originals (7) | `ck_props_t4_t5.blend` | 5, 7, **B** |
| 9 | Fronts atlas generator, layout, `--check` | `fronts_atlas.py`, `check.sh` | amendment 0 |
| 10 | Shop names with search records; billboard designs | `contracts/shop-names-and-memes.md`, atlas | 0, 9 |
| 11 | 9 shop buildings, 7 billboards and the buffering meme billboard on the fronts atlas | `kit_recipes.py` | 9, 10, **B** |
| 12 | `ObjectVisual` atlas field, `export_all` fronts support | runtime, scripts | 9 |
| 13 | Contact sheets, 9 × 2 | `contact_sheet.py`, `contact-sheets/` | 4 to 11, **B** |
| 14 | Upload hand-off batch entry and Gate 6 package | `release-candidate.md` | 13 |
| 15 | Gate 2: smoke test, console read 🔒; `scripts/check.sh` exit 0 | `playtest.md` | 12; **Studio claim** |

## Complexity Tracking

| Choice | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| Third key set (`ck_`) with its own content module | Keeps Downtown at 99 and lets 004i, 010, 012 place kit pieces without editing a shared file. | Reusing `dt_` breaks `ArtManifest.test` and puts 84 files in a module the other features edit. |
| Per-object atlas field and a second atlas | Constitution XI allows one fronts and signs atlas; shop names and 8 billboard designs do not fit the full 1,024 px theme atlas (64 cells and 8 strips). | Squeezing signs into theme cells would give 128×64 cells with no room for readable names. |
| `slot.meme.t2 … t5` in `ThemeResolve` | Memes are different sizes and `resolve` maps exactly one tier per slot. | A single `slot.meme` needs new logic in a Rules file, or forces every meme into one size. |
| Audit script that computes `w-season` share | FR-001 and the 15 % edge case need a number, not an opinion, for 99 meshes in two themes. | Eyeballing renders cannot be repeated or checked. |

No Constitution row is violated, so there is nothing to justify beyond the choices above.

## Owner decision 2026-11-07: tween-appeal rework

The owner rejected the first contact sheets as too childish (spec "Owner decision 2026-11-07"). The plan gains a
rework strand that runs after Phase 8. Nothing in the constitution changes; every Constitution Check row above still
passes. Rows that the rework touches:

| Principle | How the rework meets it |
| --- | --- |
| I Fun proven in grey box | Stage A (pilot, 8 assets, palette, lighting, QA images) ends viewable and stops for the owner; Stage B rolls out. |
| IV Safe for everyone | Graffiti is abstract shapes only, no words or letters; no brands on the new urban props. |
| VII Content is data | Palette through `tokens.json` and `scripts/design-tokens.py`; lighting as data in `Themes.city` / `Themes.winter`; the two new optional lighting fields are data the world builder applies. |
| XI Asset pipeline | Wear lives in atlas cells (the reserved hero cells), so no new texture, material or runtime cost. Smooth shading uses split normals, which the FBX export already keeps. |

**Design (Stage A).**

- **R1 Rework recipes.** `art/scripts/kit_rework.py` holds the reworked recipes and a builder that adds what the old DSL
  lacks: a bevelled box (one segment), smooth-shaded cylinders, UV spheres and limbs (a tapered cylinder between two
  points), sharp edges kept at caps. It replaces one collection in its existing `.blend` (the rest of the file is
  untouched), so a pilot never rebuilds a whole source file. Stage B moves the rest of the kit onto it.
- **R2 Palette.** `city` and `winter` world tokens move to muted real-material colours; accents keep their saturation.
  Eight reserved hero cells become wear cells (`w-glass-lit`, `w-pavement-stained`, `w-paint-worn`, `w-road-slush`,
  `w-concrete`, `w-graffiti`, `w-snowcap`, `w-icicle`); a hero cell may now hold a per-theme value and a pattern
  (`grime`, `stain`, `chips`, `graffiti`), drawn by `palette.py`. Walls and roofs use the `grime` gradient.
- **R3 Snow on a shared mesh.** A theme never swaps meshes, so snow caps are geometry on every theme, coloured by
  `w-snowcap`: snow in `winter`, stone coping or flashing grey in the other themes. Icicles use `w-icicle`, dark gutter
  metal outside `winter`.
- **R4 Lighting.** `LightingDef` gains optional `shadowSoftness`, `geographicLatitude` and `grading` (`brightness`,
  `contrast`, `saturation`, `tint`), applied by `WorldBuilder.applyLighting` to `Lighting` and one `ColorCorrectionEffect`.
  Worlds without them are unchanged. A Gate 2 smoke test covers the change.
- **R5 QA images.** `art/scripts/street_shots.py` renders the tile sheets (street-level three-quarter and top), the
  street scenes at D1 and D5 and the before/after stack, with EEVEE under the theme lighting on mid-grey.
- **R6 Sizes.** Pilot buildings get real storey and door heights inside their tier band (research R-18); size changes are
  `CityKit.luau` data and the regenerated `budgets.json`.

**Human approval**: the Stage A images (go or no-go for Stage B) and the Stage B images (Gate 6, holds the merge); a re-upload
batch of the changed atlases and pilot meshes (holds nothing).
