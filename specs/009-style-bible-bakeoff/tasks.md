# Tasks: Visual Capture Route, Style Bible, Asset Bake-Off & Scene Triangle Ceiling

**Input**: Design documents from `/specs/009-style-bible-bakeoff/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Includes contract test `tests/unit/CaptureCameras.test.luau`, rewritten audit `Downtown N10` in `tests/unit/Downtown.test.luau`, and Studio benchmark `tests/studio/HeavyScene.server.luau`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- **Studio claim**: released 2026-11-02 (T023 and T029 done; Play stopped).
- **🔒**: Studio MCP task (agent must claim Studio in `tasks.md` before using, and release claim when done; AGENTS.md rules apply)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, directory structure, and tooling environment verification

- [X] T001 Prepare directory structure for capture and bake-off artifacts in `art/capture/`, `art/render/`, `specs/009-style-bible-bakeoff/captures/before/`, and `specs/009-style-bible-bakeoff/bakeoff/renders/`
- [X] T002 Verify Rokit toolchain, background Rojo server status via `scripts/studio-preflight.sh`, and Blender MCP addon status via `blender_get_addon_status`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core governance and infrastructure prerequisites that MUST be complete before user stories proceed

**⚠️ CRITICAL**: No signage authoring, CC0 asset pack ingestion, or binding visual gate enforcement can proceed until prerequisite governance alignment is prepared

- [X] T003 Prepare constitution amendment draft for Principles I, IV, XI and Quality Gates in `.specify/memory/constitution.md` per FR-001 and research R-01 (allowing invented proper-noun shop names on textures/billboards, visual gate holding map/art features via 5 fixed shots, and CC0 meshes on the atlas counted as edited in Blender)
- [X] T004 [P] Create art render scratch folder `art/render/` and verify `.gitignore` ignores intermediate world export JSON dumps per `contracts/capture-route.md`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Repeatable 5-Shot Visual Capture Route & "Before" Baseline Set (Priority: P1) 🎯 MVP

**Goal**: Deliver a repeatable two-path capture route (offline Blender fallback renderer + Studio screen_capture primary path) that guarantees five fixed camera viewpoints (`01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`) and generate the committed "before" baseline set of the post-008 Downtown world.

**Independent Test**: Execute the capture route against current world data; verify all 5 fixed shots exist as non-empty, legible 1280×720 PNG files in `specs/009-style-bible-bakeoff/captures/before/` alongside `capture-manifest.json` documenting camera coordinates, targets, FOV, and parity notes.

### Tests for User Story 1

- [X] T005 [P] [US1] Create unit/contract test `tests/unit/CaptureCameras.test.luau` asserting `art/capture/cameras.json` invariants: exactly 5 shots in order (`01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`), unique names, `fov == 70`, `theme` in `Themes`, ball distance equals `min(320, max(8, 4·diameter))` within 0.01, and camera `pitch <= 80` degrees

### Implementation for User Story 1

- [X] T006 [P] [US1] Define fixed camera shot set in `art/capture/cameras.json` with `version = 1`, `theme = 'city'`, `fov = 70`, `resolution = [1280, 720]`, and 5 shots specifying `diameter` (2, 5, 12, 80, null), world-space `position [x, y, z]`, `lookAt [x, y, z]`, and lighting copied from `Themes.city` (`brightness: 3`, `clockTime: 13`, `fogStart: 200`, `fogEnd: 1000`, `atmosphere: 0.25`)
- [X] T007 [US1] Implement Lune world exporter CLI in `scripts/capture-export.luau` (`lune run scripts/capture-export -- --theme city --out art/render/world-city.json`) resolving Downtown world to deterministic JSON with sorted keys and fixed precision: `theme`, `blocks[]` (`kind, x, y, z, yaw, sx, sy, sz, rgb`, skipping `Boundary`), `placements[]` (`id, objectId, assetKey, x, y, z, yaw, size`), and `spawns[]` (`slot, x, z, yaw`) per `contracts/capture-route.md`
- [X] T008 [US1] Implement offline Blender renderer in `art/scripts/capture_render.py` driven via `blender_execute_blender_code` to load exported world JSON, instance `art/export/dt_*.fbx` (longest side scaled to object `size`, `-Z` forward, `Y` up), map UVs to `art/atlases/city.png`, set camera and sun from `art/capture/cameras.json`, and render 1280×720 PNGs
- [X] T009 [US1] Execute offline capture route to generate and commit the 5 fixed "before" baseline images (`01_spawn_d2.png` through `05_overhead_map.png`) and `capture-manifest.json` (`generated`, `source: 'blender-offline'`, `blender: '5.2.3'`, `worldCommit`, `theme`, `images[]`, `parityNotes`) under `specs/009-style-bible-bakeoff/captures/before/`
- [X] T010 [US1] 🔒 Claim Studio and execute primary path Studio `screen_capture` for the 5 shots from `art/capture/cameras.json`, saving supplementary `studio_<shot>.png` files into `specs/009-style-bible-bakeoff/captures/before/` and recording parity notes in `capture-manifest.json` (or record 1 tooling failure if background throttling times out after 1 owner ask)

**Checkpoint**: At this point, User Story 1 is complete and the visual capture route provides a repeatable baseline for all subsequent visual evaluations.

---

## Phase 4: User Story 2 - Authoritative Style Bible Aligned to Concept Reference (Priority: P1)

**Goal**: Author `docs/design/08-style-bible.md` to establish the authoritative visual bar overriding `06-art-style.md`, specifying colour hierarchy, silhouette bevels, per-tier triangle utilization bands, continuous facade modules with invented proper-noun signage, dark road/pale sidewalk/kerb rules, deliberate prop orientation, warm sun lighting, ball-as-heap visual target, and `city`-first / `winter`-dressing rules.

**Independent Test**: Verify `docs/design/08-style-bible.md` covers all 12 sections, links concept reference path `specs/009-style-bible-bakeoff/concept-reference.png`, is linked from `docs/design/README.md`, and conflicting lines across `README.md`, `02-city-assets.md`, `05-roblox-limits.md`, `06-art-style.md`, `07-holiday-city.md`, and `tokens.md` are resolved.

### Implementation for User Story 2

- [X] T011 [P] [US2] Author `docs/design/08-style-bible.md` covering all 12 sections: authority over `06-art-style.md`, colour hierarchy (`w-asphalt`, `w-sidewalk`, `w-kerb`, `w-wall-*` vs `w-accent-*`), proportions and silhouette bevels, per-tier triangle floors (~30%: T1 150, T2 210, T3 450, T4 1050, T5 1500) and targets (~55%: T1 275, T2 385, T3 825, T4 1925, T5 2750), continuous facades, invented shop signage, road markings, prop alignment, warm sun lighting, `city`-first with `winter`-dressing, ball heap visual target, and concept reference link
- [X] T012 [P] [US2] Update `docs/design/tokens.json` description for `w-season` from "caps and piles on every roof" to the seasonal accent trim rule, then regenerate `docs/design/tokens.md` and `docs/design/tokens.css` via `python3 scripts/design-tokens.py`
- [X] T013 [US2] Update `docs/design/06-art-style.md` and `docs/design/07-holiday-city.md` to establish `08-style-bible.md` precedence, align winter snow caps to seasonal accents rather than full-surface blankets, and cross-reference style bible standards
- [X] T014 [US2] Update `docs/design/README.md`, `docs/design/02-city-assets.md`, and `docs/design/05-roblox-limits.md` to add `08-style-bible.md` to contents and align signage rules to allow invented proper nouns on textures while maintaining strict bans on real brands, logos, flags, memes, and faces

**Checkpoint**: User Stories 1 and 2 are complete. The visual bar is documented with concrete, measurable rules.

---

## Phase 5: User Story 3 - Five-Prop Multi-Source Asset Bake-Off & Sourcing Rule (Priority: P1)

**Goal**: Compare visual appearance and triangle counts across candidate asset pipelines for 5 representative items (`hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`) on a consistent small-street stage in Blender, score them in `specs/009-style-bible-bakeoff/bakeoff/README.md`, and record the written sourcing rule in `docs/design/08-style-bible.md`.

**Independent Test**: Inspect `specs/009-style-bible-bakeoff/bakeoff/README.md` and rendered images under `specs/009-style-bible-bakeoff/bakeoff/renders/`, confirming that all 5 items are evaluated on the same lit small-street stage with measured triangle counts, verified CC0 licences, and the owner's chosen sourcing rule recorded.

### Implementation for User Story 3

- [X] T015 [P] [US3] Create neutral small-street bake-off stage in Blender via `blender_execute_blender_code` with dark asphalt road, pale sidewalk with kerb, warm sun lighting matching `Themes.city`, and dual cameras (3/4 view and tier game-distance view)
- [X] T016 [US3] Model and render Source 1 (in-house upgraded pipeline) for the 5 props (`hatchback` Tier 4, `shop_front` Tier 4/5, `bench` Tier 3, `street_tree` Tier 3, `fire_hydrant` Tier 2) scaled to Downtown sizes, mapped to `art/atlases/city.png`, and utilizing tier floor/target triangle budgets
- [X] T017 [US3] Request owner approval for external CC0 pack download (Kenney or Quaternius), import matching 5 props for Source 2 into Blender, re-UV to `art/atlases/city.png` with single material, render on stage, and record verified CC0 licence URL and terms in `specs/009-style-bible-bakeoff/bakeoff/README.md` (closed by owner decision, 2026-11-02: approval declined, not run, nothing downloaded)
- [X] T018 [US3] Check `blender_get_addon_status` generators and request owner approval for credit spend for Source 3 (single hero via `blender_generate_3d`); clean up mesh to budget or record `not run (generators off / owner declined)` with justification in `specs/009-style-bible-bakeoff/bakeoff/README.md`
- [X] T019 [US3] 🔒 Claim Studio and execute read-only Creator Store search via `search_asset` for Source 4 comparison, inspecting mesh-only models to verify zero scripts, recording triangle counts, creator, and licence terms in `specs/009-style-bible-bakeoff/bakeoff/README.md` (closed by owner decision, 2026-11-02: search done, inspection declined, nothing inserted into the place)
- [X] T020 [US3] Populate bake-off scoring matrix in `specs/009-style-bible-bakeoff/bakeoff/README.md` comparing triangles, look (1-5), atlas fit (1-5), effort (minutes), licence, cost, status (`done`, `not run (reason)`), render links, and upload hand-off list (at most 5 props) per `contracts/bakeoff-report.md`
- [X] T021 [US3] Codify the owner's chosen asset sourcing rule and bake-off findings into section 11 of `docs/design/08-style-bible.md` and `specs/009-style-bible-bakeoff/bakeoff/README.md`

**Checkpoint**: User Stories 1, 2, and 3 are complete. The asset sourcing decision is backed by rendered comparisons, triangle metrics, and licence records.

---

## Phase 6: User Story 4 - Measured Scene Triangle Ceiling & Heavy-Scene Performance Benchmark (Priority: P2)

**Goal**: Benchmark a heavy procedural test scene in Studio (stepping up triangles towards 1,000,000 with < 2,000 parts and 12 balls) to replace arbitrary 250,000/100,000 ceilings in `docs/design/03-city-level.md` and `tests/unit/Downtown.test.luau` with empirically measured values.

**Independent Test**: Verify 60-second frame rate samples (differentiating throttled from unthrottled seconds) in `specs/009-style-bible-bakeoff/playtest.md` and updated constants in `Downtown.test.luau` and `03-city-level.md`.

### Implementation for User Story 4

- [X] T022 [P] [US4] Create benchmark builder and client Heartbeat 60-second fps sampler in `tests/studio/HeavyScene.server.luau` using `AssetService:CreateEditableMesh` to generate scalable procedural triangle steps (300k, 500k, 750k, 1M) without asset uploads
- [X] T023 [US4] 🔒 Claim Studio and run `HeavyScene` benchmark in Play across triangle steps (300k, 500k, 750k, 1M) with 12 balls and < 2,000 parts, logging 60 per-second fps samples, throttled count (15 fps), and unthrottled averages in `specs/009-style-bible-bakeoff/playtest.md`
- [X] T024 [US4] Derive `UNCULLED_TRIANGLE_CEILING` and `CULLED_TRIANGLE_CEILING` (`floor10k(0.8 × highest passing step >= 30 fps)`) and rewrite "Downtown N10" audit in `tests/unit/Downtown.test.luau` to assert against the new constants per `contracts/ceiling-and-tests.md`
- [X] T025 [US4] Update scene triangle ceilings in `docs/design/03-city-level.md` lines 65–66 with measured values and link to `specs/009-style-bible-bakeoff/playtest.md`
- [X] T026 [US4] Prompt owner once for early physical phone FPS reading on the heavy scene and log open verification in `docs/release-candidate.md` without blocking feature completion

**Checkpoint**: All user stories are complete. The triangle ceiling is grounded in measurement.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Quality gate verification, visual gate dry run, and release candidate tracking

- [X] T027 [P] Perform visual gate dry run reviewing the 5 committed "before" captures against `docs/design/08-style-bible.md` and record current map deficiencies in `specs/009-style-bible-bakeoff/playtest.md`
- [X] T028 [P] Prompt owner once for concept reference image `specs/009-style-bible-bakeoff/concept-reference.png` and record tracking entry in `docs/release-candidate.md`
- [X] T029 🔒 Claim Studio, execute Gate 2 Studio playtest, and read console output to verify zero unexpected errors or warnings, logging session transcript in `specs/009-style-bible-bakeoff/playtest.md`
- [X] T030 Run full verification suite via `scripts/check.sh` ensuring StyLua, Selene, luau-lsp strict, Lune tests (including `CaptureCameras` and rewritten `Downtown N10`), and token/palette checks exit 0

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user story work that touches governance/signage/CC0
- **User Stories (Phase 3+)**:
  - **User Story 1 (P1)**: Can start after Foundational (Phase 2) completes
  - **User Story 2 (P1)**: Can start drafting in parallel with US1, finishes after US1 captures and US3 bake-off numbers are available
  - **User Story 3 (P1)**: Can start after US1 stage setup and owner approvals for CC0/credit spend
  - **User Story 4 (P2)**: Can run independently once Foundational (Phase 2) completes
- **Polish (Phase 7)**: Depends on completion of all user stories (US1–US4)

### User Story Dependencies

- **User Story 1 (P1)**: Independent of other stories; produces `art/capture/cameras.json` and the "before" set
- **User Story 2 (P1)**: Drafts independently; incorporates bake-off sourcing rule (from US3) into section 11 and concept image link
- **User Story 3 (P1)**: Depends on bake-off stage and camera rules; incorporates CC0 licence records and produces sourcing decision
- **User Story 4 (P2)**: Independent procedural benchmark; produces measured triangle ceilings for `Downtown.test.luau` and `03-city-level.md`

### Within Each User Story

- Contract test (`CaptureCameras.test.luau`) must be written before implementation completes
- Exporter before offline renderer
- Offline renderer before "before" set commit
- Bake-off stage before prop candidate rendering
- Procedural benchmark execution before rewriting N10 ceiling constants

### Parallel Opportunities

- **Phase 1**: T001 and T002 can run in parallel
- **Phase 2**: T003 and T004 can run in parallel
- **US1**: T005 (`CaptureCameras.test.luau`) and T006 (`cameras.json`) can be authored in parallel
- **US2**: T011 (`08-style-bible.md`) and T012 (`tokens.json` & generation) can run in parallel
- **US3**: T015 (stage setup) can be authored in parallel with US1/US2 tasks
- **US4**: T022 (`HeavyScene.server.luau`) can be authored in parallel with US1–US3 tasks
- **Polish**: T027 and T028 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch camera test and schema authoring together:
Task: "Create unit/contract test tests/unit/CaptureCameras.test.luau"
Task: "Define fixed camera shot set in art/capture/cameras.json"

# After camera JSON exists:
Task: "Implement Lune world exporter CLI in scripts/capture-export.luau"
Task: "Implement offline Blender renderer in art/scripts/capture_render.py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T004`)
3. Complete Phase 3: User Story 1 (`T005`–`T010`)
4. **STOP and VALIDATE**: Confirm all 5 "before" images exist in `specs/009-style-bible-bakeoff/captures/before/` with `capture-manifest.json` and `CaptureCameras.test.luau` passes. This establishes the visual safety net for the entire project.

### Incremental Delivery

1. Setup + Foundational → Tooling and governance baseline established
2. User Story 1 → 5-shot visual capture route & committed "before" set (MVP!)
3. User Story 2 → Authoritative Style Bible and doc alignment
4. User Story 3 → 5-prop bake-off across sources and written sourcing rule
5. User Story 4 → Heavy-scene benchmark and empirical triangle ceiling
6. Polish → Visual gate dry run, RC tracking, and `scripts/check.sh` exit 0

---

## Notes

- `[P]` tasks = different files, no dependencies
- `[Story]` label maps task to specific user story (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- **🔒** denotes Roblox Studio MCP tasks requiring exclusive claim and adherence to `AGENTS.md` (no screen take-over, desktop-safe)
- Commit after each task or logical group
- Keep `art/export/`, `art/export/manifest.json`, and `src/shared/Rules/` untouched
