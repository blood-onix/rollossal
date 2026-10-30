---
description: "Task list for 005-theme-art-pipeline: season-theme system + stylised-real art pipeline"
---

# Tasks: Season-Theme System and Stylised-Real Art Pipeline

**Input**: Design documents from `/specs/005-theme-art-pipeline/`

**Prerequisites**: plan.md (required), spec.md (required, 3 user stories), data-model.md, contracts/theme-content.md + art-pipeline.md, quickstart.md, research.md (R-01..R-12)

**Tests**: OPTIONAL — included only where explicitly requested (spec SC-001/SC-002/SC-003/SC-004; quickstart verifies Lune + check.sh + Studio). TDD-style "fail first" noted per contract.

**Feature branch**: `005-theme-art-pipeline`

**Constitution check**: Passed (Principles IV, VII, XI v2.0.0). No owner-approval item triggered (no remote/price/tool changes). Two close-call abstractions kept (`Assets.meshUv`, `ThemeResolve` takes `expand`) per plan Complexity Tracking.

---

## Phase 1: Setup — Token Sync & Project Init

**Purpose**: Regenerate design tokens and establish the new atlas schema

- [X] T001 Update `docs/design/tokens.json`: add `color.hero` (32 entries: 6 legacy refs `snow`/`snow_light`/`stone`/`wood`/`brick`/`ice` → `w-*`; 26 reserved `hero-07..hero-32` at `#ff00ff`); regenerate `tokens.css`/`tokens.md`
- [X] T002 [P] Run `python3 scripts/design-tokens.py` and verify the `GENERATED PALETTES` block in `Content/Themes.luau` is rewritten correctly (one cell per line, tabs preserved for StyLua)
- [X] T003 [P] Update `scripts/check.sh`: add "Design tokens in sync" step (compare `tokens.json` vs `Themes.luau` block via `--check`) and "Atlas determinism" step
- [X] T004 [P] Create `tests/unit/Atlas.test.luau` (new): verify exactly 6 theme PNGs exist, each 1024×1024 IHDR, `atlas.json` lists 6 ids with pixel sha256

---

## Phase 2: Foundational — Config, Assets, Budgets & Strings

**Purpose**: Blocking prerequisites — theme data, resolution and runtime all depend on these

- [X] T005 Update `src/shared/Config.luau`: `Budgets.meshTriangles = { 500, 700, 1500, 3500, 5000 }`; add `maxWeatherParticles = 40`, `maxDressingSlotShare = 0.15`, `defaultMaxPlacements = 1400`, `Flags.ThemeSystem = true`, `weatherEmitterHeight = 30`, `weatherEmitterSize = 60`
- [X] T006 [P] Regenerate `art/scripts/budgets.json` from `Config`; verify `scripts/art-budgets.luau` matches via `lune run scripts/art-sync`
- [X] T007 Update `src/shared/Assets.luau`: add `palettes = { city="", winter="", spring="", autumn="", toon="", neon="" }`, `meshUv = "legacy"`, rename `music` → `musicWinter`, add `musicCity`/`musicSpring`/`musicAutumn`/`musicToon`/`musicNeon = ""`, `sounds` map preserved
- [X] T008 Update `src/shared/Localization/Strings.luau`: add theme names (`theme.*.name` en+es), object/slot/overlay/book/returning keys (~25 new strings); extend `Strings.test`
- [X] T009 [P] Update `Content/GreyBoxRoom.luau`: add `ThemeBinding` type, `WorldDef.themeBindings`, `ThemeBookPage`, extend `ObjectDef.role: string?`; verify `lune run tests/unit/run` still passes (base types)

---

## Phase 3: User Story 1 — Theme Data-Only Switch (P1) 🎯 MVP

**Goal**: One world re-themes by changing `activeThemeId` with zero code edits; palette, lighting, weather, slots, overlays, hero variants resolve purely from data

**Independent Test**: Change `SnowVillage.activeThemeId = "city"` (data only) in `Content/Worlds/SnowVillage.luau` and run `lune run tests/unit/run`; expect all `Themes`, `ThemeResolve`, `SnowVillage`, `Book`, `Config` suites pass. Revert after.

- [X] T010 [US1] Create `src/shared/Content/Themes.luau` (new pure data module, no `require`): `ThemeDef` schema + 6 themes from `palettes` block (64 cells + `light-*` + 6 lighting scalars); `id` unique; `maxParticles <= 40`; `rate × lifetime ≤ maxParticles`; weather `kind` in `{"snow","petals","leaves","sparkle","none"}`
- [X] T011 [US1] [P] Write `tests/unit/Themes.test.luau` (fail-first): theme id uniqueness, 64-cell completeness (32 `w-*` + 32 hero with refs + reserved), lighting field presence, weather arithmetic, palette values match `tokens.json`
- [X] T012 [US1] Create `src/shared/Rules/ThemeResolve.luau` (pure module, takes `expand` argument — no sibling requires): `resolve(world, theme, expand)` — replace slot ids in zones/fixed, apply `heroVariants`, merge overlays, build `environmentPalette`, return plain table
- [X] T013 [US1] Write `tests/unit/ThemeResolve.test.luau`: verify non-slot placements bit-identical across themes; slot share `≤ 0.15`; resolved object ids unique; `themeId` set; overlay clear of `keepOutAreas`
- [X] T014 [US1] Update `src/shared/Worlds.luau`: at `require` time call `ThemeResolve.resolve` with `Worlds.activeThemeId`; expose `Worlds.resolved` (resolved def) and `Worlds.active` (base); `worlds.forTheme` thin wrapper for Studio specs
- [X] T015 [US1] [P] Update `Content/Worlds/SnowVillage.luau`: declare `supportedThemes = {"winter","city"}`; `themeBindings["winter"]` with 5 slot kinds mapping to existing objects + `winter_lights` overlay + `big_snowman`; `themeBindings["city"]` with new stand-ins (`ice_lolly` T1 0.7, `beach_ball` T2 1.6, `paddling_pool` T3 6, `ice_cream_truck` T4 14, `giant_duck` T5 30) + `beach_towel` overlay; `heroVariant big_snowman → fountain`; `bookPage` for both; `keepOutAreas` (markers + 4 sightlines); `maxPlacements = 1700`; `activeThemeId = "winter"` (default)
- [X] T016 [US1] [P] Update `Content/GreyBoxRoom.luau` types (`ObjectDef.role`, `ThemeBinding.slots/overlays/heroVariants/objects/bookPage`); add `WorldDef.activeThemeId`, `supportedThemes`, `themeBindings`, `keepOutAreas`, `maxPlacements`

---

## Phase 4: User Story 2 — Stylised-Real Gradient Atlas & Blender Export (P1)

**Goal**: Deterministic 1024 px atlas per theme (8×8 gradient cells + 8 trim strips); export rules enforce split normals, single `Palette` material, UV inside one cell/strip, provisional budgets

**Independent Test**: `python3 art/scripts/palette.py --check` exits 0; `python3 art/scripts/export_all.py --out art/export` exits 0 on all `.blend`; `lune run tests/unit/Atlas.test` passes.

- [X] T017 [US2] [P] Rewrite `art/scripts/palette.py`: stdlib-only (no `bpy`); read `tokens.json`; generate 6 PNGs (`city`, `winter`, `spring`, `autumn`, `toon`, `neon`) 1024×1024; gradient `factor(y) = 1.12 − 0.27·y/63`; 8 trim strips with procedural patterns (no words/logos); write `art/palette.json` (UV bounds for 64 cells + 8 strips) and `art/atlases/atlas.json` (sha256 of scanline buffer per theme)
- [X] T018 [US2] [P] Write `tests/unit/Atlas.test.luau` (if T004 not done): verify PNG dimensions, `atlas.json` completeness, pixel hash matches regenerated buffer
- [X] T019 [US2] [P] Create `art/scripts/build_shared.py` (new, constants): atlas geometry (`128×64` cells, 8 strips `1024×64`), inset `≥ 1 px` half-texel inside cell/strip boundary, split-normal export flag
- [X] T020 [US2] Update `art/scripts/export_all.py`: allow `has_custom_normals` / `mesh_smooth_type`; validate UV within one cell/strip per `palette.json`; single `Palette` material only; identity world matrix; origin at footprint centre-bottom; longest dimension `±5%` of declared `size`; triangle count `≤ Config.Budgets.meshTriangles[tier]` (`500/700/1500/3500/5000`); exit non-zero with descriptive error on failure (negative test: move UV across edge → fail; add second material → fail; exceed budget → fail)
- [X] T021 [US2] [P] Create `art/scripts/qa_grid.py` (new): render one prop across 6 atlases into `art/qa/theme_grid_*.png` for cross-theme readability check
- [X] T022 [US2] Update `docs/design/01-world-kit.md` / design docs as needed (Principle XI v2.0.0 already in constitution; no new approval needed)

---

## Phase 5: User Story 3 — Returning Collection-Book Pages (P2)

**Goal**: Each active theme shows a `bookPage`; inactive theme pages remain visible with preserved progress + returning label (no "limited", no timer/countdown)

**Independent Test**: In Studio, absorb `winter_lights`; open Book → `winter` page shows 1/1. Switch data to `city`; Book still lists `winter` page with 1/1 and returning label; no timer word; tier pages untouched.

- [X] T023 [US3] Update `src/shared/Rules/Book.luau`: add `Book.themePages(pages, objects, book, activeThemeId)` returning `PageSummary` with `themeId`, `isActive`, `returningKey`; tier = 0; base tier pages call `Book.pages` with base objects only (excl. binding objects); theme page appended after tier pages in `supportedThemes` order; `returningKey` validated (no "limited", "left", "ends", "hurry", digits-with-colon)
- [X] T024 [US3] [P] Write `tests/unit/Book.test.luau` extensions: theme page visibility when active/inactive; progress preserved; `nameKey` loc; returning key forbidden words; base tier completeness unchanged across themes
- [X] T025 [US3] Update `src/client/BookUi.luau`: append theme summaries after tier pages; show returning label with calendar-free icon (no clock/hourglass) when inactive; active page highlighted; text ≥ 18 px (`TextFits` true at 640×360)
- [X] T026 [US3] [P] Update `src/shared/Localization/Strings.luau` keys for `theme.*.book.name` / `theme.*.book.returning` (en + es); extend `Strings.test`

---

## Phase 6: Runtime — ObjectVisual, Weather, Music, Snow Village Wiring

**Purpose**: Theme applies at runtime without new remotes; weather capped; all rules pure

- [X] T027 [P] Update `src/shared/ObjectVisual.luau`: `MeshPart.TextureID = Assets.palettes[theme.paletteAssetKey]` (fallback to `Assets.palette` only if `meshUv == "legacy"` and id empty); `RenderFidelity = Automatic`; `ObjectDef.role` → `Part.Color = theme.palette[role]` else tier colour; ground/env `SmoothPlastic`, `Transparency = 0`; zero `SurfaceAppearance`, zero per-prop `Light`, `Neon` only on glow child (Tier 4-5 heroes, optional, not used in 005)
- [X] T028 [P] Update `src/server/WorldBuilder.luau`: resolve world via `Worlds.resolved`; apply hero variants to placed objects; add theme-only overlay objects; ground block colours from `w-*` roles
- [X] T029 [P] Update `src/server/WorldSpawner.luau`: pass `Worlds.resolved` to `WorldBuilder`
- [X] T030 [P] Create `src/client/WeatherController.luau`: single camera-attached transparent `Part` holding `ParticleEmitter`; `CFrame` updated to `Camera.CFrame * CFrame.new(0, 30, 0)` every `RenderStepped`; emit from `Worlds.activeTheme.weather`; `Rate = rate`, `Rate × Lifetime ≤ 40`; `Enabled = false` + `:Clear()` when `ReduceMotion` true; return when false; `kind = "none"` → disabled
- [X] T031 [P] Update `src/client/Feedback.luau`: play `musicAssetKey` from `Assets.sounds`; preload atlas `TextureID` via `Assets.palettes`
- [X] T032 [P] Update `src/client/Main.client.luau`: start `WeatherController`; connect `GetAttributeChangedSignal("ReduceMotion")`

---

## Phase 7: Blender Pipeline (Blender claim) 🔒

**Purpose**: Re-UV 65 meshes, rebuild with split normals/bevel, export and validate

- [X] T033 [P] [Blender] Execute `remap_uv_atlas.py` via `execute_blender_code`: migrate 65 collections from legacy 256 px grid to new atlas cells (`snow…ice` at cells 32-37); verify idempotent on second run (`"already migrated"`): migrate 65 collections from legacy 256 px grid to new atlas cells (`snow…ice` at cells 32-37); verify idempotent on second run (`"already migrated"`)
- [X] T034 [P] [Blender] Execute `export_all.py --out art/export`: all 65 meshes with split normals, single `Palette` material, UV inside cell/strip, bevel modifier applied (`4-8%` size), identity transform, footprint-centre origin; budget check `≤ {500,700,1500,3500,5000}` per `Config.Budgets.meshTriangles`; manifest `art/export/manifest.json`: all 65 meshes with split normals, single `Palette` material, UV inside cell/strip, bevel modifier applied (`4-8%` size), identity transform, footprint-centre origin; budget check `≤ {500,700,1500,3500,5000}` per `Config.Budgets.meshTriangles`; manifest `art/export/manifest.json`
- [X] T035 [P] [Blender] Execute `qa_grid.py -- --object <name> --out art/qa`: generate `theme_grid_*.png` for a reference prop across 6 atlases; confirm readable in all themes

---

## Phase 8: Studio Proof (Studio claim) 🔒

**Purpose**: Confirm data-only switch, rules, performance, no new errors

- [X] T036 [P] [Studio] Preflight (`scripts/studio-preflight.sh`); sync probe passes (`mismatches = {}`); start Play (`start_stop_play`); record `Lighting.ClockTime`, `Atmosphere`, `ParticleEmitter.Enabled`, `ThemeMusic` playing, 32 slot placements (winter ids); `get_console_output`: zero new errors/warnings
- [X] T037 [P] [Studio] Stop Play; edit `src/shared/Content/Worlds/SnowVillage.luau` `activeThemeId = "city"` only; wait for Rojo sync; re-run probe; start Play; confirm lighting changed to `13`, emitter `Enabled = false`, music stopped, placements = 5 city stand-ins with `role` colours, overlay `beach_towel`, `fountain` mesh at hero, ground `w-grass`/`w-kerb`/`w-sidewalk`; zero new errors
- [X] T038 [P] [Studio] Set `winter`; set `LocalPlayer` attribute `ReduceMotion = true`; confirm emitter `Enabled = false` + `:Clear()` within 1 frame; set false → restored; arithmetic check `Rate × Lifetime ≤ 40` (validates `src/client/WeatherController.luau`)
- [X] T039 [P] [Studio] Template rules check (`tests/studio/ObjectTemplates.spec`): each object `RenderFidelity == Automatic`, `CollisionFidelity` Box (T1-3) / Hull (T4-5), zero `SurfaceAppearance`/`Light` descendants, `Transparency == 0`
- [X] T040 [P] [Studio] Book proof (drive ball to absorb `winter_lights`): open Book → `winter` page 1/1; switch to `city`; Book still lists `winter` 1/1 with returning label, no timer, tier pages 100 % achievable (validates `src/client/BookUi.luau`, `src/shared/Rules/Book.luau`)
- [ ] T041 [P] [Studio] 640 × 360 capture: clone root frame to `USC`-sized container (with `UIScale` if needed); record `AbsolutePosition` of Book theme page; `TextFits` true at `≥ 18 px`; fps per second for 60 s with 12 balls' parts; report throttled (15 fps) separately; unthrottled mean `≥ 30`; active parts `< 2000` (validates `src/shared/Config.luau` budgets)
- [ ] T042 [P] [Studio] Record all observations in `specs/005-theme-art-pipeline/playtest.md` (date + commit); confirm Quality Gates met (server/client behaviour, UI, assets, strings)

---

## Phase 9: Polish, Cross-Cutting & Owner Hand-Off

**Purpose**: Final synchronization, documentation, upload

- [X] T043 [P] Update `art/README.md`: new atlas layout (1024 px, 8×8 cells 128×64, 8 strips 1024×64), `palette.json` schema, split-normal rules, budget table, UV inset rule; reference `contracts/art-pipeline.md`
- [X] T044 [P] Update `tests/unit/run` / `scripts/check.sh` final validation: all 8 suites (`Themes`, `ThemeResolve`, `Atlas`, `Book`, `SnowVillage`, `Config`, `ArtManifest`, `Strings`) pass; `check.sh` exits 0
- [X] T045 [P] Owner hand-off (ask first): upload `art/atlases/*.png` (6) + `art/export/*.fbx` (65) + `manifest.json`; single commit: `Assets.palettes.*` filled, `Assets.meshUv = "atlas"`, delete `Assets.palette`; run `REQUIRE_ASSET_IDS=1 lune run tests/unit/run`; confirm mesh recolour between `winter`/`city` in Studio; record in PR; set `LoadStringEnabled` off in published place (`AGENTS.md`)
- [X] T046 [P] Commit `tasks.md` generation; verify all tasks follow `- [ ] T### [P?] [US?] Description with file path`; none missing ID, checkbox, or file reference

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1–2 (Setup + Foundational)**: No dependencies; can start immediately; Phase 2 BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 (Config/Assets/Strings/token block); can start once T005–T009 complete
- **Phase 4 (US2)**: T017 can start in parallel with Phase 3 once T001/T003 done (tokens); T020 depends on T019 (build_shared constants); Blender tasks (Phase 7) depend on T020 and Phase 3 data (binding objects exist for QA)
- **Phase 5 (US3)**: Depends on Phase 3 (ThemeResolve + Book.luau); can parallel with Phase 4 once T012/T013/T014 done
- **Phase 6 (Runtime)**: Depends on Phase 3 (resolution) + Phase 2 (config/assets); can start once T027 files have data
- **Phase 7 (Blender)**: Depends on Phase 1 (atlas generated) + Phase 3 (binding objects for QA) + Phase 2 (budgets); sequential (one agent, Blender MCP)
- **Phase 8 (Studio)**: Depends on Phase 6 + Phase 7 + Phase 5; requires Studio MCP; 🔒 claim
- **Phase 9 (Polish)**: Depends on all above; hand-off asks owner first (Principle X)

### User Story Dependencies

- **US1 (P1)**: No story dependencies; delivers theme resolution and Snow Village proof
- **US2 (P1)**: Independent of US1 at pipeline level; depends only on Phase 1 tokens; integrates at Phase 6/8 via `ObjectVisual.TextureID`
- **US3 (P2)**: Depends on US1 (needs `ThemeResolve`, `Worlds.resolved`, `Book.luau` extension); can run in parallel with US2 once foundation done

### Parallel Opportunities (marked [P] above)

- All Setup tasks (T001–T004) can run together
- All Foundational (T005–T009) can run together (different files; no same-file writes except `Config`/`Assets`/`String` are disjoint from each other)
- Within US1: T010 + T011 + T012 + T013 + T016 can run in parallel (different files); T015 depends on T014; T015 includes slot-zone carving that must match `ThemeResolve` rules (test T013 validates)
- US2: T017 + T019 + T022 (design updates) parallel; T020 depends on T019; T021 depends on T020; T023 depends on T017
- US3: T023 + T025 + T026 parallel; T024 depends on T023
- Runtime Phase 6: T027 + T028 + T030 + T031 + T032 are disjoint files (`ObjectVisual`, `WorldBuilder`, `WeatherController`, `Feedback`, `Main.client`) → all [P]
- Studio Phase 8: T036–T042 are sequential per setup rules (Play → edit → Play → capture), but each sub-check is independent of others once sync passes

---

## Parallel Example: User Story 1 (once Phase 2 done)

```bash
# Launch model + rule + test together:
Task T010: Create Content/Themes.luau
Task T012: Create Rules/ThemeResolve.luau
Task T011: Write Themes.test.luau (fail-first, then implement)
Task T013: Write ThemeResolve.test.luau

# Launch world proof in parallel (disjoint file):
Task T015: Update Content/Worlds/SnowVillage.luau (slots + overlays + bindings)
Task T016: Update Content/GreyBoxRoom.luau types
```

---

## Implementation Strategy

### MVP First (US1 + minimal US2 + US3 core)

1. Complete Phase 1–2 (Setup + Foundational)
2. Complete T010 (Themes) + T012 (ThemeResolve) + T015 (Snow Village proof bindings)
3. **STOP and VALIDATE**: `lune run tests/unit/run` — all `Themes`, `ThemeResolve`, `SnowVillage`, `Book`, `Config` pass; change `activeThemeId` to `"city"`, confirm zero code edits, revert
4. Deploy/demo: Studio Play with `winter` shows old layout; edit to `city` shows stand-ins + new lighting; no errors; Book shows returning page

### Incremental Delivery

1. Phase 1–2 → Foundation ready
2. Phase 3 → Theme resolution; Snow Village proves data-only switch (MVP!)
3. Phase 4 → Atlas generated, export validated (pipeline ready for 004e)
4. Phase 5 → Book pages returned; no FOMO
5. Phase 6 → Runtime applies atlas, weather, music
6. Phase 7 → Blender meshes re-UV'd, exported, QA grid visual
7. Phase 8 → Studio proof recorded (fps ≥ 30, zero errors, capture saved)
8. Phase 9 → Owner uploads; `meshUv = "atlas"`; publish-ready

### Team / Agent Split (Principle X: disjoint claims)

- Agent A (Python/CI): T001–T004, T017–T022, T033–T035
- Agent B (Luau/Lune): T005–T016, T023–T032, T036–T042
- Studio / Blender: claimed per task (`[Blender]`, `[Studio]`, `🔒`); no live publish; agent never activates display (`AGENTS.md`)

---

## Notes

- All tasks use strict checklist format: `- [ ] T### [P?] [US?] Description with exact file path`
- [P] = parallelizable (different files, no dependency on incomplete tasks within the same file)
- [US1]/[US2]/[US3] = maps to spec user story (P1, P1, P2); Setup/Foundational/Polish = no story label
- No vague tasks: every description names exact file path and constraint (e.g., "`maxParticles <= 40`", "`rate × lifetime ≤ maxParticles`", "UV inset `>= 1 px`", `meshUv = "legacy"` → `"atlas"`)
- Tests only where spec/quickstart explicitly asks: `Atlas.test`, `Themes.test`, `ThemeResolve.test`, `Book.test` extensions, `String.test`; `check.sh` steps; Studio specs (`ObjectTemplates.spec`, `ThemeSwitch.spec` — new)
- `Tasks.md` path: `/Users/Roman_Tikhonov/Projects/Personal/rollossal/specs/005-theme-art-pipeline/tasks.md`
- Generated by `/speckit-tasks` on 2026-10-28 from `FEATURE_DIR = specs/005-theme-art-pipeline`

## Phase 10: Convergence

- [X] T047 Write `tests/studio/ThemeSwitch.spec.luau` (Jest-Lua) asserting that `Worlds.forTheme("winter")` and `Worlds.forTheme("city")` change palette, lighting, weather, music key, slot objects, overlay placements and hero variant while non-slot base placements stay identical, and that `WeatherController.isEmitting()` is false under `ReduceMotion` per plan: tests/studio ThemeSwitch.spec (missing)

## Phase 11: Convergence

- [X] T048 Make `fidelity()` in `src/shared/ObjectVisual.luau` tolerate the locked `CollisionFidelity` write the same way `RenderFidelity` is tolerated (`pcall`), so `WorldBuilder` builds Snow Village without aborting; re-run Play and confirm no CollisionFidelity error, a `World` folder exists, and note in `specs/005-theme-art-pipeline/playtest.md` that the tier Box/Hull collision class is not settable at runtime per FR-004 (contradicts)
- [X] T049 Extend `tests/studio/ObjectTemplates.spec.luau` to assert, for every template in `Worlds.active.objects`, `RenderFidelity == Automatic`, `Transparency == 0`, and zero `SurfaceAppearance`/`Light` descendants (`PointLight`, `SpotLight`, `SurfaceLight`) per Constitution XI and T039 (missing)

## Phase 12: Convergence

- [X] T050 Pass `CollisionFidelity` (`Box` for tiers 1-3, `Hull` for tiers 4-5) and `RenderFidelity = Automatic` as options to `AssetService:CreateMeshPartAsync` in `src/shared/ObjectVisual.luau`, and remove the silently failing post-create writes in `fidelity()` per FR-004 (partial)
- [X] T051 Assert `CollisionFidelity` is `Box` for tiers 1-3 and `Hull` for tiers 4-5 on every MeshPart template in `tests/studio/ObjectTemplates.spec.luau` per T039 and FR-004 (missing)
- [X] T052 Add a `w-sidewalk` ground block (`swatch = "w-sidewalk"`) to `src/shared/Content/Worlds/SnowVillage.luau` so the city ground shows `w-grass`, `w-kerb` and `w-sidewalk` per T037 (partial)
- [X] T053 Move the reduce-motion emitter rule out of `src/client/WeatherController.luau` into a pure function in `src/shared/Rules/Weather.luau` with a Lune test in `tests/unit/Weather.test.luau`, so emitter-off under `ReduceMotion` is checked without Studio per T047 (partial)
- [X] T054 [Owner] Supply a looping city music track and set `musicCity` in `src/shared/Assets.luau` (currently `""`, so Sunny City plays no music) per FR-005 and US1 acceptance 1 (missing); the owner decided on 2026-10-30 to reuse the winter track `80565841497538` for every theme, so `musicCity` is set to it

## Phase 13: Convergence

- [X] T055 Make `tests/studio/ObjectTemplates.spec.luau` require a `MeshPart` template for every object whose `Assets.meshes` id is set and assert its render and collision fidelity there, so a silent stand-in fallback fails the spec per US2/AC3

## Phase 14: Convergence

- [X] T056 Enforce the world placement budget in `src/shared/Rules/ThemeResolve.luau` (base placements plus overlay placements must not exceed `world.maxPlacements`, defaulting to `Config.Budgets.defaultMaxPlacements` = 1400 when nil) and assert it in `tests/unit/SnowVillage.test.luau` for every supported theme against `maxPlacements = 1700` per FR-002, FR-011 (missing)
- [X] T057 Add a pure collision-class rule to `src/shared/Rules/Tiers.luau` (Box for tiers 1-3, Hull for tiers 4-5), use it in `ObjectVisual.buildMesh`, and assert in `tests/unit/ThemeResolve.test.luau` that every `heroVariant` keeps its base hero's collision class per FR-011 (partial)
- [X] T058 In `tests/studio/ThemeSwitch.spec.luau` the reduce-motion case must set the `LocalPlayer` attribute `ReduceMotion = true`, assert `WeatherController.isEmitting()` is false, and restore the attribute; if no `LocalPlayer` exists in that Jest context, rename the case to say it checks only the unstarted state per US1/AC2 (partial)

## Phase 15: Convergence

- [X] T059 [Owner] Confirm plan deviations D1 (slots, overlays, heroVariants and bookPage live on `WorldDef.themeBindings`, not `ThemeDef`) and D2 (`Worlds.forTheme(themeId)` takes no world argument), then record them in `spec.md` FR-001, FR-002 and FR-003 per plan "Spec deviations to confirm"; the owner decides, the agent does not edit spec text (contradicts)

## Phase 16: Convergence

- [X] T060 [Owner] Decide whether `SnowVillage` declares `gate` and `shortcut` keep-out areas (its layout has no ring gates or small-only shortcut corridors): add those zones with checks in `tests/unit/SnowVillage.test.luau`, or drop the two kinds from FR-010 in `spec.md`; the owner decides, the agent does not edit spec text per FR-010 (partial)

## Phase 17: Convergence

- [X] T061 Replace the dynamic `Enum.CollisionFidelity[Tiers.collisionClass(tier)]` index in `buildMesh` (`src/shared/ObjectVisual.luau` line 100) with an explicit `Box`/`Hull` branch so luau-lsp strict analysis passes, then re-run `scripts/check.sh` until it exits 0 per SC-001 (partial)
- [X] T062 Add a repeatable negative test for `art/scripts/export_all.py` failure paths (UV crossing a cell or strip edge, a second material, triangles over `Config.Budgets.meshTriangles[tier]`), each exiting non-zero with a descriptive error, run through the Blender MCP per US2/AC2 and T020 (partial)
- [X] T063 [Studio] Check that the `Icons.retry` glyph used by the returning-page label (`src/shared/Content/Icons.luau` line 13, drawn in `src/client/BookUi.luau`) renders in both `FredokaOne` and `GothamMedium` in the 640 × 360 capture per FR-006 and AGENTS.md Glyphs; use a text-only label if either font shows it blank or as a box (partial)

## Phase 18: Convergence

- [X] T064 [Blender] Run `art/scripts/test_export_negative.py` (`python3 -I art/scripts/test_export_negative.py --blender <path>`, or through `execute_blender_code` if the shell run is blocked; do not bypass a sandbox block) and confirm all three cases (UV across a cell edge, second material, over-budget triangles) exit non-zero with their named rule, per US2/AC2 and T062 (partial)
- [X] T065 [Owner] Confirm that `Assets.meshUv` replaces the FR-004 fallback to `Assets.palette` (the flag is the R-07 choice in plan Complexity Tracking) and record it as a deviation in `spec.md` FR-004; the owner decides, the agent does not edit spec text (contradicts)

## Phase 19: Convergence

- [X] T066 Declare at least one `fixedPlacements` entry on the `winter` or `city` overlay in `src/shared/Content/Worlds/SnowVillage.luau` (both are `{}` today), clear of `keepOutAreas` and within `maxPlacements`, and assert it in `tests/unit/SnowVillage.test.luau` per FR-010 (partial)

## Phase 20: Convergence

- [X] T067 Keep the base Tier 5 `skating_rink` placed in `city`: add a fixed `skating_rink` placement to the city overlay in `src/shared/Content/Worlds/SnowVillage.luau`, clear of `keepOutAreas` and every footprint, and assert in `tests/unit/SnowVillage.test.luau` that every theme places every base object, so tier pages reach 100 % in every theme per T040 step 3 and spec "Base Tier Book Pages vs. Theme-Only Objects" (contradicts)
