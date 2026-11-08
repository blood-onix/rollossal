# Tasks: Dedicated City Asset Kit, Style Audit, Shop Signage & Meme Originals

**Input**: Design documents from `/specs/013-city-asset-kit/` (`spec.md`, `plan.md`, `data-model.md`, `quickstart.md`, `contracts/`)  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `contracts/`, `quickstart.md`  
**Tests**: Unit tests, schema checks, and budget validations are required per specification (`CityKit.test.luau`, `ThemeResolve.test.luau`, `ArtManifest.test.luau`, `Strings.test.luau`, `Config.test.luau`).  
**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.  
**Concurrency Claims**: Blender claimed by feature `013-city-asset-kit` for 3D modeling and rendering; Studio MCP claimed only for Gate 2 smoke test (🔒).  
**Claim record (T001)**: Blender claimed by `013-city-asset-kit` from 2026-11-07; verified `1b9e0ee` (PR #10, constitution 4.0.0) and `3b28dac` (4.1.0) are ancestors of the branch.  
**Amendment Prerequisite**: Constitution v4.0.0 / v4.1.0 visual gate and signage amendment confirmed merged in `main` (commit `1b9e0ee`, PR #10). Strand 5 / US3 is unlocked.

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

## Path Conventions

- Content and Game Code: `src/shared/` (`Content/`, `Localization/`, `Rules/`, `Config.luau`, `Assets.luau`, `ObjectVisual.luau`)
- Art Pipeline & Blender Tooling: `art/scripts/`, `art/source/`, `art/export/`, `art/atlases/`
- Tooling & Checks: `scripts/` (`art-budgets.luau`, `check.sh`)
- Tests: `tests/unit/`
- Documentation & Design: `docs/design/`, `docs/release-candidate.md`
- Feature Artifacts: `specs/013-city-asset-kit/` (`audit/`, `contact-sheets/`, `playtest.md`)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, budget configuration, and style bible baseline updates

- [X] T001 Verify and record merge of Constitution PR #10 (commit `1b9e0ee`) and record active Blender claim in `specs/013-city-asset-kit/tasks.md`
- [X] T002 [P] Define `Config.Budgets.billboardTextures = 8` in `src/shared/Config.luau` and verify positive integer assertion in `tests/unit/Config.test.luau`
- [X] T003 [P] Update style bible section 11 in `docs/design/08-style-bible.md` recording class floors: "pocket floor 40 (size <= 0.8 studs), flat floor 24, panel floor 150, tier floors 150, 210, 450, 1050, 1500"

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Implement audit report and verification script `art/scripts/audit_report.py` enforcing 99 `dt_*` manifest meshes, `fillRatio = triangles / floor`, `seasonShare < 0.15`, baseline verdict rules, and headroom checks against 550,000 unculled and 290,000 culled ceilings
- [X] T005 [P] Implement Blender audit rendering script `art/scripts/audit_render.py` to render meshes in `city` and `winter` palettes and compute `w-season` UV surface area share
- [X] T006 [P] Extend `ObjectDef` in `src/shared/Content/GreyBoxRoom.luau` with optional `atlas: string?` ("fronts") and `zone: string?` fields
- [X] T007 Implement CityKit catalogue module skeleton returning `{ objects: { ObjectDef } }` in `src/shared/Content/CityKit.luau`
- [X] T008 [P] Implement localisation table skeleton in `src/shared/Localization/CityKitStrings.luau` and merge into `src/shared/Localization/Localizer.luau`
- [X] T009 Append `CityKit.objects` as world "city_kit" in `scripts/art-budgets.luau` and sync `art/scripts/budgets.json` via `lune run scripts/art-sync`
- [X] T010 [P] Extend `tests/unit/ArtManifest.test.luau` to support the third key set (`ck_` prefix, 84 expected keys, disjoint from SnowVillage and Downtown)
- [X] T011 [P] Create test suite `tests/unit/CityKit.test.luau` verifying 84 total count, zone counts, key prefix rules, tier size bands, and fronts atlas flags

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Audit of Existing 99 City Meshes Against the Style Bible (Priority: P1) 🎯 MVP

**Goal**: Render all 99 existing `dt_*` meshes in both `city` and `winter` themes, evaluate triangle utilization and seasonal trim share, assign `keep`, `upgrade`, or `replace` verdicts, and ensure scene headroom remains within 009 ceilings.

**Independent Test**: Run `python3 art/scripts/audit_report.py --check specs/013-city-asset-kit/audit/audit.json` to verify all 99 meshes have documented triangle counts, tier ceilings, valid verdicts matching baseline rules within one step, and that all 198 render PNGs exist.

### Tests for User Story 1

- [X] T012 [P] [US1] Add audit data validation test in `tests/unit/CityKit.test.luau` asserting `audit.json` contains exactly 99 `dt_*` entries, valid verdicts, and passes headroom ceiling checks

### Implementation for User Story 1

- [X] T013 [US1] Run Blender audit render script `art/scripts/audit_render.py` via Blender MCP to render all 99 `dt_*` meshes in `city` and `winter` themes into `specs/013-city-asset-kit/audit/renders/city/` and `specs/013-city-asset-kit/audit/renders/winter/` and compute `seasonShare` UV area values
- [X] T014 [US1] Execute `art/scripts/audit_report.py` to evaluate meshes against class floors, apply the baseline verdicts (12 keep, 36 upgrade, 51 replace), enforce "seasonShare under 0.15 in both city and winter", and generate `specs/013-city-asset-kit/audit/audit.json`
- [X] T015 [US1] Generate comprehensive markdown audit report `specs/013-city-asset-kit/audit/audit.md` via `art/scripts/audit_report.py` showing per-mesh triangle counts, tier budgets, floor classes, fill ratios, and headroom summary
- [X] T016 [US1] Implement contact sheet generator script `art/scripts/contact_sheet.py` in Blender Python supporting composite grid renders with id and triangle count captions
- [X] T017 [US1] Render composite audit contact sheets `specs/013-city-asset-kit/contact-sheets/city/audit.png` and `specs/013-city-asset-kit/contact-sheets/winter/audit.png` via `art/scripts/contact_sheet.py`

**Checkpoint**: User Story 1 complete. Audit report and renders verify existing asset status and confirm headroom before any mesh rebuilding begins.

---

## Phase 4: User Story 2 - Cohesive Zone-by-Zone City Asset Kit & Contact Sheets (Priority: P1)

**Goal**: Model, budget, and export 84 new `ck_*` single-mesh objects plus upgraded `dt_*` assets across Building kit (25), Street kit (11), Park (16), Suburbs (7), Main street (5), and Downtown (6), with contact sheets for owner Gate 6 review and an upload batch hand-off.

**Independent Test**: Run `lune run tests/unit/run` to validate that all 84 objects meet tier size bands, class floors, and triangle budgets, check that exported FBX files match `manifest.json` sha256 hashes, and inspect rendered zone contact sheets.

### Tests for User Story 2

- [X] T018 [P] [US2] Add unit tests in `tests/unit/CityKit.test.luau` verifying size constraints: "T1 0.3 to 1.5, T2 1.6 to 3.9, T3 4.2 to 9.8, T4 10 to 25, T5 26 to 60 studs", triangle targets <= 60% of budget, and at least 4 building variants per class (house, shop, midrise, tower)

### Implementation for User Story 2

- [X] T019 [US2] Build modular building collections (walls, window bays, doors, awnings, cornices, roofs) and join into 25 single-mesh building variants in `art/source/ck_buildings.blend` via `art/scripts/kit_recipes.py`
- [X] T020 [P] [US2] Model 11 single-mesh street kit props (`ck_road_marking_*`, `ck_crossing_zebra`, `ck_kerb_corner`, `ck_street_sign`, `ck_planter_box`, `ck_bollard`, `ck_railing_section`, `ck_bus_stop_pole`, `ck_street_lamp_double`, `ck_bin_street`) in `art/source/ck_props_t1_t3.blend`
- [X] T021 [P] [US2] Model 16 single-mesh park zone props (trees, bushes, flower beds, picnic gear, playground equipment, paths, pond edge) in `art/source/ck_props_t1_t3.blend` and `art/source/ck_props_t4_t5.blend`
- [X] T022 [P] [US2] Model 7 single-mesh suburbs zone props (barbecue, lawn mower, garden fence, trampoline, garden shed, sedan car, estate car) in `art/source/ck_props_t1_t3.blend` and `art/source/ck_props_t4_t5.blend`
- [X] T023 [P] [US2] Model 5 single-mesh main street zone props (cafe table with parasol, fruit crates, sandwich board, bike rack, post box) in `art/source/ck_props_t1_t3.blend`
- [X] T024 [P] [US2] Model 6 single-mesh downtown zone props (clock tower, obelisk, triumphal arch, tram, subway entrance, limousine) in `art/source/ck_props_t4_t5.blend`
- [X] T025 [US2] Rebuild upgraded and replaced `dt_*` meshes in `art/source/` per audit verdicts, preserving exact keys, tier sizes, and bottom-centre origins while adding silhouette bevels and respecting "w-season under 15% area"
- [X] T026 [US2] Populate `src/shared/Content/CityKit.luau` with complete `ObjectDef` entries for all 70 zone objects (building, street, park, suburbs, mainstreet, downtown) with `bookId`, `nameKey`, `assetKey`, `tier`, `size`, `role`, and `dims`
- [X] T027 [P] [US2] Register English and Spanish localisation names for all 70 zone objects in `src/shared/Localization/CityKitStrings.luau` and verify with `tests/unit/Strings.test.luau`
- [X] T028 [US2] Register 84 `ck_*` mesh keys as `""` in `src/shared/Assets.luau` in one sorted block without removing or reordering any existing `dt_*` entries
- [X] T029 [US2] Update `art/scripts/export_all.py` to enforce single material named `Palette`, bottom-centre origin, and longest side within ±5% of budget size for `ck_*` meshes
- [X] T030 [US2] Export FBX meshes for building, street, park, suburbs, mainstreet, and downtown to `art/export/ck_*.fbx` and record entries in `art/export/manifest.json` with tiers, triangles, bytes, and sha256 hashes
- [X] T031 [US2] Re-export upgraded `dt_*` meshes to `art/export/` and update sha256 hashes in `art/export/manifest.json` while keeping original keys and tier sizes
- [X] T032 [US2] Render zone contact sheets for building, street, park, suburbs, mainstreet, and downtown in `city` and `winter` themes into `specs/013-city-asset-kit/contact-sheets/<theme>/<zone>.png` via `art/scripts/contact_sheet.py`
- [X] T033 [US2] Record the mesh export batch and empty asset ID stand-in instructions in `docs/release-candidate.md` under "Owner hand-offs"

**Checkpoint**: User Stories 1 and 2 complete. All 70 core zone assets and upgraded `dt_*` meshes are built, budgeted, exported, localized, and rendered into contact sheets.

---

## Phase 5: User Story 3 - Invented Shop Signage & Deadpan Placeholder Billboards (Priority: P2)

**Goal**: Deliver a vetted catalogue of >=20 invented proper-noun shop names, a deterministic 1,024 px fronts and signs atlas across all 6 themes, 7 billboard meshes, 9 fronts-atlas shop buildings, runtime texture selection in `ObjectVisual.luau`, and contact sheets.

**Independent Test**: Run `python3 art/scripts/fronts_atlas.py --check` (exits 0), run `lune run tests/unit/run` to validate shop name safety checks, billboard texture cap (<= 8), and fronts atlas cell bindings, and inspect rendered signage contact sheets.

### Tests for User Story 3

- [X] T034 [P] [US3] Add unit tests in `tests/unit/CityKit.test.luau` enforcing sign text constraints: "at most 2 lines, at most 13 characters each, upper and lower case letters, digits, '&' and '\'' only", banned terms check (roblox, robux, blox, alcohol, gambling), and billboard cap `Config.Budgets.billboardTextures = 8`

### Implementation for User Story 3

- [X] T035 [US3] Conduct trademark and brand safety searches for 26 candidate names and record at least 20 and at most 24 `clear` names with search queries, dates, and sign cell assignments in `docs/design/shop-names.json`
- [X] T036 [US3] Implement fronts and signs atlas generator `art/scripts/fronts_atlas.py` using Python 3 stdlib to generate 1,024x1,024 PNGs for 6 themes and layout `art/atlases/fronts/fronts.json` containing 24 sign cells (256x64), 8 billboard cells (256x128), 6 facade strips (1,024x64), and 2 px insets
- [X] T037 [US3] Implement `--check` CLI flag in `art/scripts/fronts_atlas.py` for deterministic pixel hash and layout validation and add execution to `scripts/check.sh`
- [X] T038 [P] [US3] Add `frontsAtlases = { city = "", winter = "" }` table in `src/shared/Assets.luau`
- [X] T039 [P] [US3] Update `textureId` in `src/shared/ObjectVisual.luau` to return `Assets.frontsAtlases[theme.paletteAssetKey]` when `def.atlas == "fronts"` and fall back cleanly without warnings when empty
- [X] T040 [US3] Update `art/scripts/export_all.py` to validate that UVs of meshes marked `atlas = "fronts"` lie strictly within one sign cell, billboard cell, or facade strip from `art/atlases/fronts/fronts.json`
- [X] T041 [US3] Model 7 single-mesh billboard variants (`ck_billboard_404`, `ck_billboard_chart`, `ck_billboard_loading`, `ck_billboard_empty`, `ck_billboard_arrow`, `ck_billboard_testcard`, `ck_billboard_nested`) in `art/source/ck_props_t4_t5.blend` mapped to `bb_*` cells
- [X] T042 [US3] UV-map the 9 shop building variants in `art/source/ck_buildings.blend` to assigned sign cells and facade strips from `art/atlases/fronts/fronts.json`
- [X] T043 [US3] Register the 7 billboard objects in `src/shared/Content/CityKit.luau` with `atlas = "fronts"`, register strings in `src/shared/Localization/CityKitStrings.luau`, export FBX meshes to `art/export/`, and update `art/export/manifest.json`
- [X] T044 [US3] Render signage contact sheets `specs/013-city-asset-kit/contact-sheets/city/signage.png` and `specs/013-city-asset-kit/contact-sheets/winter/signage.png` via `art/scripts/contact_sheet.py`
- [X] T045 [US3] Record the fronts atlas PNGs and billboard mesh entries in `docs/release-candidate.md` under "Owner hand-offs"

**Checkpoint**: User Stories 1, 2, and 3 complete. Shop signage and billboards are vetted, generated, mapped, and verified.

---

## Phase 6: User Story 4 - Meme Originals & Swappable `slot.meme` Dressing Slot (Priority: P2)

**Goal**: Deliver 7 inanimate meme original objects, support content-driven rotation via `slot.meme.t2 … t5` in `ThemeResolve.luau`, provide full English and Spanish localisation, and render meme contact sheets.

**Independent Test**: Run `lune run tests/unit/run` to verify that `ThemeResolve.test.luau` passes the data-only swap test across meme slot tiers and that `CityKit.test.luau` verifies all 7 memes are inanimate, within budget, and free of keep-out terms.

### Tests for User Story 4

- [X] T046 [P] [US4] Add slot tier mapping `slot.meme.t2 = 2`, `slot.meme.t3 = 3`, `slot.meme.t4 = 4`, `slot.meme.t5 = 5` to `SLOT_TIERS` in `src/shared/Rules/ThemeResolve.luau`
- [X] T047 [P] [US4] Implement unit tests in `tests/unit/ThemeResolve.test.luau` verifying `slot.meme.t*` tiers, data-only swap without layout edits, and rejection of mismatched tiers
- [X] T048 [P] [US4] Add meme content validation tests in `tests/unit/CityKit.test.luau` asserting exactly 7 inanimate meme originals, role restrictions (no person/animal/character), and keep-out term checks (no Nyan Cat, Doge, Italian-brainrot names)

### Implementation for User Story 4

- [X] T049 [US4] Model the 7 inanimate meme original meshes (`ck_meme_wet_floor_sign`, `ck_meme_pond_cart`, `ck_meme_cone_statue`, `ck_meme_phone_1pc`, `ck_meme_buffering_billboard`, `ck_meme_banana_scale`, `ck_meme_vacant_lot`) in `art/source/ck_props_t1_t3.blend` and `art/source/ck_props_t4_t5.blend` using idea-only geometry and bottom-centre origins
- [X] T050 [US4] Register all 7 meme ObjectDefs in `src/shared/Content/CityKit.luau` with correct tiers, sizes, and `atlas = "fronts"` on `ck_meme_buffering_billboard`
- [X] T051 [P] [US4] Register English and Spanish localisation names for all 7 meme originals in `src/shared/Localization/CityKitStrings.luau` and verify coverage with `tests/unit/Strings.test.luau`
- [X] T052 [US4] Export meme FBX meshes to `art/export/ck_meme_*.fbx` and record rows in `art/export/manifest.json` with triangle counts within tier budgets
- [X] T053 [US4] Render meme contact sheets `specs/013-city-asset-kit/contact-sheets/city/meme.png` and `specs/013-city-asset-kit/contact-sheets/winter/meme.png` via `art/scripts/contact_sheet.py`
- [X] T054 [US4] Record meme mesh export entries in `docs/release-candidate.md` under "Owner hand-offs"

**Checkpoint**: User Stories 1 through 4 complete. Meme originals and swappable slots are fully functional and tested.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cross-cutting validation, Studio smoke testing, full pipeline verification, and release candidate hand-off

- [X] T055 Run complete unit test suite `lune run tests/unit/run` confirming all 84 objects, budgets, strings, manifest hashes, and slot bindings pass
- [X] T056 Execute Gate 2 Studio playtest smoke test via Studio MCP in a scratch copy of the place verifying stand-in rendering for empty IDs and fronts atlas fallback with zero game script errors, recording results in `specs/013-city-asset-kit/playtest.md` 🔒
- [X] T057 Verify that all 18 contact sheets (9 zones × 2 themes: building, street, park, suburbs, mainstreet, downtown, signage, meme, audit) exist in `specs/013-city-asset-kit/contact-sheets/` and are ready for Gate 6 owner review
- [X] T058 Execute repository-wide quality verification `scripts/check.sh` confirming StyLua, Selene, strict luau-lsp, design tokens, `palette.py --check`, and `fronts_atlas.py --check` exit 0
- [X] T059 Verify that winter city triangle scene headroom remains under 550,000 unculled and 290,000 culled in `tests/unit/Downtown.test.luau` N10 after all mesh upgrades
- [X] T060 Update `docs/release-candidate.md` with complete batched owner upload instructions (FBX paths, Asset keys to fill, fronts atlas PNGs) and Gate 6 image review package

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 (audit scripts and test harness)
- **User Story 2 (Phase 4)**: Depends on Phase 2 (CityKit catalogue skeleton, budgets, export tooling) and Phase 3 (audit verdicts define keep/upgrade/replace for `dt_*`)
- **User Story 3 (Phase 5)**: Depends on Phase 2 and Phase 1 (billboard cap). PR #10 is confirmed merged, so fronts atlas generation and signage modeling can proceed in parallel with US2/US4
- **User Story 4 (Phase 6)**: Depends on Phase 2 and Phase 4 (prop modeling pipeline); fronts-atlas billboard meme depends on Phase 5 atlas layout
- **Polish (Phase 7)**: Depends on all user stories (US1–US4) being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start immediately after Foundational (Phase 2). Produces audit verdicts that guide US2 mesh upgrades.
- **User Story 2 (P1)**: Can start building recipes and new `ck_*` props after Foundational; upgrades to `dt_*` execute after US1 audit verdicts are produced.
- **User Story 3 (P2)**: Fronts atlas generator and shop name vetting can start immediately after Foundational. Fronts-mapped meshes (9 shops, 7 billboards) integrate after atlas layout is committed.
- **User Story 4 (P2)**: `slot.meme` Rules changes and standalone meme props can start after Foundational; buffering billboard coordinates with US3 atlas.

### Within Each User Story

- Tests written first and verified against requirements
- Blender source models authored and joined into single meshes
- ObjectDefs and localisation entries registered in parallel
- Meshes exported via `export_all.py` and recorded in `manifest.json`
- Contact sheets rendered in both `city` and `winter` palettes
- Batch hand-off entries recorded in `docs/release-candidate.md`

### Parallel Opportunities

- **Phase 1**: T002 (`Config.luau`) and T003 (`08-style-bible.md`) can run in parallel
- **Phase 2**: T005, T006, T008, T010, T011 can run in parallel once T004/T007 are established
- **Phase 4**: Zone modeling tasks T020 (street), T021 (park), T022 (suburbs), T023 (main street), T024 (downtown) can be authored in parallel batches across `.blend` files; T027 (strings) can run in parallel with modeling
- **Phase 5**: T034 (tests), T038 (`Assets.luau`), T039 (`ObjectVisual.luau`) can run in parallel with atlas script T036
- **Phase 6**: T046 (`ThemeResolve.luau`), T047 (unit tests), T048 (validation tests), T051 (strings) can run in parallel with meme prop modeling T049

---

## Parallel Example: User Story 1

```bash
# Launch test definition and render preparations:
Task: "T012 [P] [US1] Add audit data validation test in tests/unit/CityKit.test.luau"
Task: "T013 [US1] Run Blender audit render script art/scripts/audit_render.py via Blender MCP"
```

## Parallel Example: User Story 2

```bash
# Model independent zone prop sets across split .blend files:
Task: "T020 [P] [US2] Model 11 single-mesh street kit props in art/source/ck_props_t1_t3.blend"
Task: "T021 [P] [US2] Model 16 single-mesh park zone props in art/source/ck_props_t1_t3.blend and ck_props_t4_t5.blend"
Task: "T022 [P] [US2] Model 7 single-mesh suburbs zone props in art/source/ck_props_t1_t3.blend and ck_props_t4_t5.blend"
Task: "T023 [P] [US2] Model 5 single-mesh main street zone props in art/source/ck_props_t1_t3.blend"
Task: "T027 [P] [US2] Register English and Spanish localisation names in src/shared/Localization/CityKitStrings.luau"
```

## Parallel Example: User Story 3

```bash
# Author tests and runtime atlas hookup in parallel with name vetting:
Task: "T034 [P] [US3] Add unit tests in tests/unit/CityKit.test.luau"
Task: "T038 [P] [US3] Add frontsAtlases table in src/shared/Assets.luau"
Task: "T039 [P] [US3] Update textureId in src/shared/ObjectVisual.luau"
```

## Parallel Example: User Story 4

```bash
# Rules updates, tests, and localisation in parallel with meme prop modeling:
Task: "T046 [P] [US4] Add slot tier mapping to SLOT_TIERS in src/shared/Rules/ThemeResolve.luau"
Task: "T047 [P] [US4] Implement unit tests in tests/unit/ThemeResolve.test.luau"
Task: "T048 [P] [US4] Add meme content validation tests in tests/unit/CityKit.test.luau"
Task: "T051 [P] [US4] Register English and Spanish localisation names in src/shared/Localization/CityKitStrings.luau"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (verify PR #10, configure billboard cap, update style bible class floors)
2. Complete Phase 2: Foundational (audit report script, CityKit catalogue skeleton, budgets, test harness)
3. Complete Phase 3: User Story 1 (render all 99 `dt_*` meshes, generate `audit.json` and `audit.md`, compose audit sheets)
4. **STOP and VALIDATE**: Verify audit verdicts match baseline rules, headroom is confirmed, and audit contact sheet is reviewed.
5. Deploy/checkpoint audit artifacts.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation and audit tooling ready
2. Add User Story 1 (Audit) → Validated scope for upgrades; headroom confirmed (MVP!)
3. Add User Story 2 (Zone Kit) → 84 new single-mesh props and upgraded `dt_*` assets exported and rendered
4. Add User Story 3 (Signage & Billboards) → Vetted shop names, fronts atlas generator, billboard meshes, and runtime atlas selection
5. Add User Story 4 (Meme Originals & Slots) → 7 meme gags and data-driven swappable slot family in `ThemeResolve.luau`
6. Phase 7 (Polish) → Gate 2 Studio smoke test, 18 contact sheets verified, `scripts/check.sh` clean, and owner hand-off documented

### Parallel Team Strategy

- **Agent / Developer 1 (Blender Art Pipeline)**: Executes Phase 3 audit renders, Phase 4 modular building recipes & prop modeling, Phase 5 billboard modeling, Phase 6 meme modeling, and contact sheet generation.
- **Agent / Developer 2 (Luau Engine & Tooling)**: Executes Phase 1 Config cap, Phase 2 catalogue & budgets, Phase 5 fronts atlas generator & `ObjectVisual.luau` atlas selection, Phase 6 `ThemeResolve.luau` slot family and unit tests, and Phase 7 `check.sh` verification.
- **Studio MCP (Agent)**: Executes Phase 7 T056 Gate 2 smoke test when Studio claim is active without desktop disruption.

---

## Notes

- Every absorbable prop and building variant MUST be a single unified mesh with origin at the bottom centre and one material named `Palette`.
- All newly added `ck_*` mesh keys are registered as `""` in `src/shared/Assets.luau` so dimensional stand-ins hold without errors until the owner completes the batched upload.
- Upgraded or replaced `dt_*` meshes keep their original keys, tier sizes, and existing uploaded asset IDs in `Assets.luau`.
- No script may touch the owner's desktop, move the mouse, or steal focus outside of Studio MCP tools during playtest (AGENTS.md).
- Visual gate (Gate 6) holds the pull request merge until the owner reviews and approves the 18 contact sheets.

---

## Phase 8: Convergence

**Purpose**: Gaps found by the convergence assessment (round 1). Order matters: T063 changes a mesh, so T064 renders after it.

- [X] T061 Make `python3 art/scripts/audit_report.py --check specs/013-city-asset-kit/audit/audit.json` exit 0 again: `audit.json` is the pre-rebuild baseline, so for the 86 rebuilt `dt_*` meshes the check must require manifest triangles >= `floor` (as `tests/unit/CityKit.test.luau` already does) and keep requiring an exact match only for `keep` meshes and any deferred mesh; it currently fails 86 "triangles differ from the manifest" errors, so the US1 independent test and quickstart section 1 do not pass per SC-001/US1 (partial)
- [X] T062 Correct `docs/release-candidate.md` "013 City asset kit: mesh upload batch 1 and fronts atlas": it still says "8 clear so far, 10 dropped, at least 20 needed" and "upgraded `dt_*` meshes are not part of this batch yet", but `docs/design/shop-names.json` now has 22 `clear` names with cells `sign_00` to `sign_21`, the atlas PNGs were regenerated with them, and the 86 rebuilt `dt_*` FBX files are listed in the next section; state the final counts and fold the rebuilt `dt_*` re-upload into the batch instructions per T045, T060, FR-011 (partial)
- [X] T063 Rebuild `dt_kiosk` (audit verdict `replace`, 96 triangles, floor 1050) to the highest triangle count that keeps the winter city Downtown N10 sum within 550,000 unculled and 290,000 culled (bevel and reveals as the other rebuilt meshes), re-export it, update its `art/export/manifest.json` row and `Assets.luau` stays unchanged, remove the `dt_kiosk` exception from `tests/unit/CityKit.test.luau` only if the new count reaches its floor, otherwise record the reached count and the reason in `docs/release-candidate.md` per FR-002, FR-003 downtown "kiosks", T025, T031 (partial)
- [X] T064 Re-render the Gate 6 contact sheets after the final meshes and atlas: `building`, `street`, `park`, `suburbs`, `mainstreet`, `downtown` (rendered 20:30 to 20:33, before the `dt_*` rebuild at 20:39) and `signage`, `meme` (rendered before the 22-name atlas regenerated at 20:35), in `city` and `winter` via `art/scripts/contact_sheet.py`, into `specs/013-city-asset-kit/contact-sheets/<theme>/`, so the owner reviews the shipped geometry and sign names per FR-013, SC-005, T032, T044, T053 (partial)

---

## Phase 9: Tween-appeal rework (owner decision 2026-11-07)

**Purpose**: The owner rejected the first sheets as too childish. Rework the kit to "stylised real with punch" (spec
"Owner decision 2026-11-07", plan R1 to R6, research R-18, style bible sections 2, 3, 7, 8, 9). Constitution XI is
unchanged. Owner checks go to `docs/release-candidate.md`.

### Stage A: pilot (stops for the owner's go)

- [X] T065 Record the decision in `spec.md`, `plan.md`, `research.md` (R-18 real dimensions) and `docs/design/08-style-bible.md` sections 2, 3, 7, 8, 9
- [X] T066 Render the "before" tiles of the 8 pilot assets (current meshes, atlas and lighting) in `city` and `winter` with `art/scripts/street_shots.py`
- [X] T067 Muted urban palette and wear cells: `docs/design/tokens.json` (`city`, `winter` world tokens; 8 reserved hero cells become `w-glass-lit`, `w-pavement-stained`, `w-paint-worn`, `w-road-slush`, `w-concrete`, `w-graffiti`, `w-snowcap`, `w-icicle`), per-theme hero values and patterns in `art/scripts/palette.py`, `scripts/design-tokens.py` and `tests/unit/Themes.test.luau`; regenerate with `python3 scripts/design-tokens.py` and `python3 art/scripts/palette.py`
- [X] T068 Late-afternoon lighting as data: `Themes.city` / `Themes.winter` values, optional `shadowSoftness`, `geographicLatitude`, `grading` in `LightingDef` (`Themes.luau`, `GreyBoxRoom.luau`), applied in `src/server/WorldBuilder.luau`, tested in `tests/unit/Themes.test.luau`
- [X] T069 Rework builder and pilot recipes in `art/scripts/kit_rework.py` (bevelled boxes, smooth round parts, limbs, snow caps, icicles) for `ck_house_gable_fence`, `ck_shop_row_three`, `ck_tower_slab`, `ck_bin_street`, `dt_fire_hydrant`, `ck_street_lamp_double`, `ck_tree_oak`, `ck_car_sedan`; buildings at least 60 % of their tier ceiling and at least 70 % muted by area
- [X] T070 Pilot sizes from research R-18 in `src/shared/Content/CityKit.luau` (house 24.5, shop row 44, bin 3.4), `lune run scripts/art-sync` for `art/scripts/budgets.json`
- [X] T071 Build the 8 pilot meshes through the Blender MCP, export them with `art/scripts/export_all.py --prefix <id> --partial`, update `art/export/manifest.json`
- [X] T072 QA images in `specs/013-city-asset-kit/contact-sheets/pilot/`: street-level and top tile sheets in `city` and `winter`, one main-street and one suburb-corner scene per theme at D1 and D5, the before/after sheet
- [X] T073 Per-asset report (triangles, % of tier ceiling, muted share) in `specs/013-city-asset-kit/contact-sheets/pilot/README.md`
- [X] T074 Gate 2 smoke test for the lighting change: Studio playtest, console read, `Lighting` and `ColorCorrectionEffect` values, recorded in `specs/013-city-asset-kit/playtest.md` 🔒
- [X] T075 `scripts/check.sh` exits 0; list the pilot images and the re-upload batch (2 theme atlases, 8 meshes) on `docs/release-candidate.md`; stop for the owner's go

### Stage B: rollout (after the owner's go on Stage A)

- [X] T076 Apply the approved direction to every asset in the finalised zone list through `art/scripts/kit_rework.py`, with research R-18 sizes and the owner's answers on towers and tier moves
- [X] T077 Content mix: trim the playground to swing set and slide in default placements; add the urban props (traffic lights, parking meter, e-scooter dock, food truck, phone-repair kiosk, neon-edged shop sign, scaffolding, crane or skip, rooftop water tank, sports car, taxi, motorbike) inside existing tiers, with `CityKit.luau` entries, en-us and es-es names, `Assets.luau` keys as `""`
- [X] T078 Re-run the 99-mesh audit (`audit_render.py`, `audit_report.py`) with the new rules (muted share, smooth round parts, 60 % of ceiling for tier 3 to 5) and give keep / upgrade / replace verdicts
- [X] T079 Re-render all contact sheets (street-level and top) and street scenes in `city` and `winter`; Gate 6 package on `docs/release-candidate.md`; one batched mesh upload hand-off

### Stage C: the small end (owner request 2026-11-08, "we're missing small objects")

- [X] T080 Rebuild the Downtown pocket set (the 19 tier 1 `dt_*` meshes the new-rule audit marks upgrade) in the kit style through `art/scripts/kit_stage_c.py`, keeping keys, sizes and the winter Downtown N10 placement-weighted triangle sum under its ceiling; `build_objects.py --world downtown` re-applies them
- [X] T081 Add small kit objects: 13 tier 1 and 12 tier 2 objects up to 3 studs across street, park, suburbs and main street, with `CityKit.luau` entries, en-us and es-es names, `Assets.luau` keys as `""`, and a test that the small end stays stocked
- [X] T082 Re-run the rework audit; small-object and pocket contact sheets in `city` and `winter`; D1 and D5 street scenes with small objects at ball height
- [X] T083 `scripts/check.sh` exits 0; Gate 2 smoke test 🔒; Stage C on the Gate 6 package and the upload batch in `docs/release-candidate.md`
