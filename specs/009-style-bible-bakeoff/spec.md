# Feature Specification: Visual Capture Route, Style Bible, Asset Bake-Off & Scene Triangle Ceiling

**Feature Branch**: `009-style-bible-bakeoff`

**Created**: 2026-11-02

**Status**: Draft

**Input**: User description: "Owner, 2026-11-02, after playing 008: the result is not good enough, mostly the level design, and the props look childish. The spawn looks like \"someone vomited random objects in groups\". Inside Out is rejected. There is no fixed launch date: quality comes first, and the owner is ready to postpone everything. This item comes first because nothing else can be judged until agents and the owner can see the game."

## Clarifications

### Session 2026-11-02 (review round 2)

- Q: FR-008 and SC-003 ask for the five-prop bake-off across the required sources, verified CC0 licence records and a sourcing rule backed by a side-by-side comparison. Only Source 1 (own Blender) ran; the owner declined Source 2 (CC0 download) and Source 4 (Creator Store inspection), and Source 3 cannot run (generators off). Waive, or reopen? → A: **Waived by the owner.** The multi-source comparison and the CC0 licence record are waived for this feature; the Source 1 sourcing rule (in-house Blender to the style bible's per-tier floors and targets) is final. FR-007's five-prop run is met by Source 1. The requirement text above is unchanged; this records the owner's waiver of its multi-source and CC0-licence parts. A CC0 import in a later feature still needs its licence recorded (constitution Principle XI).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Repeatable 5-Shot Visual Capture Route & "Before" Baseline Set (Priority: P1)

Previously, map and art work shipped without anyone viewing the actual rendered scene because live viewport captures timed out when the editor window was in the background, and the two-failure tooling fallback allowed visual verification to be deferred to the release candidate. As a result, geometric tests passed while the spawn area looked like randomly scattered objects and parked vehicles faced random directions.

To prevent any visual work from ever again shipping blind, the team has a repeatable, two-path capture route that guarantees five fixed camera shots of the world:
1. **Spawn at start size** (`diameter = 2` studs), showing doorstep framing, initial edible clutter, kerb, and street opening;
2. **Street level at Tier 2 transition** (`diameter = 5` studs), showing street enclosure, building fronts, sidewalks, and street furniture;
3. **Mid-game street/district view** (`diameter = 12 to 30` studs), showing block scale, trees, lamps, and vehicles;
4. **Late-game view** (`diameter = 80` studs), showing full pullback framing across city blocks and landmarks;
5. **Overhead view of the whole map**, showing overall street layout, block structure, and object distribution.

The capture route attempts live engine viewport capture first (asking the owner at most once to keep the editor window in front if background throttling causes timeouts), and automatically falls back to an offline 3D scene renderer that loads the world placement data, environment geometry, and exported meshes to render the exact same five camera viewpoints to image files on disk. Using this route, the five fixed shots of the current post-008 Downtown map are captured and committed into the feature folder (`specs/009-style-bible-bakeoff/`) as the **"before" baseline set**. Visual features are never exempt from producing images under the two-failure tooling rule.

**Why this priority**: Nothing else—neither style rules, asset quality, nor level layout—can be evaluated by agents or the owner until both can reliably see the world from fixed, comparable camera angles saved in the repository.

**Independent Test**: Can be independently verified by running the capture route against the current world data and confirming that all five fixed camera shots exist as non-empty, legible image files in `specs/009-style-bible-bakeoff/` with documented camera coordinates, targets, and fields of view so future features (`004h`, `004i`, `004j`) can render identical "after" shots.

**Acceptance Scenarios**:

1. **Given** the current world data and exported meshes, **When** the capture route is executed (via live viewport capture with the window in front, or via the offline 3D scene fallback renderer that loads world placements, blocks, and meshes from disk), **Then** all five fixed shots (spawn at `D = 2`, street level at `D = 5`, mid-game at `D = 12–30`, late game at `D = 80`, and full-map overhead) are generated and saved as image files in `specs/009-style-bible-bakeoff/captures/before/`.
2. **Given** the live editor capture tool fails or times out twice, **When** a map or art feature is being verified, **Then** the offline fallback renderer MUST still produce and save all five fixed shots to disk; the feature MUST NOT be marked complete or deferred to the release candidate without images.
3. **Given** the camera definitions for the five fixed shots, **When** inspected, **Then** each shot specifies repeatable position, look-at target, field of view, and lighting/theme state (`city` as the primary baseline) so "before" and "after" sets are directly comparable.

---

### User Story 2 - Authoritative Style Bible Aligned to Concept Reference (`docs/design/08-style-bible.md`) (Priority: P1)

Current props use only a tiny fraction of their triangle budgets (medians of `72 / 108 / 136 / 216 / 272` triangles across Tiers 1–5 against budgets of `500 / 700 / 1,500 / 3,500 / 5,000`), giving them a blocky, childish appearance, while ` winter` turns every top surface white and obscures street readability.

A comprehensive style bible (`docs/design/08-style-bible.md`) is authored to establish the visual bar for the game and explicitly override `docs/design/06-art-style.md` wherever the two conflict. Anchored to the owner's concept image (placed in the feature folder on request), the style bible defines concrete, enforceable rules for:
- **Main-street composition**: A dense main street viewed down its length, enclosed by continuous, varied building fronts with awnings and invented shop signs;
- **Ground & road rules**: Dark asphalt roads with yellow centre/lane lines and pedestrian crossings, framed by pale sidewalks with distinct kerbs;
- **Street furniture & prop placement rules**: Trees and street lamps evenly spaced along kerb lines; bins, benches, and hydrants in believable urban positions aligned to street and kerb axes rather than scattered with random yaw;
- **Object detail & geometry**: How much geometric detail each object class and tier receives so meshes utilize a meaningful share of their `500 / 700 / 1,500 / 3,500 / 5,000` triangle budgets (wheel arches, recessed windows, bevelled silhouettes, distinct awnings, signage boards, and recognizable sub-parts);
- **Colour, proportions, edge treatment & facades**: Real-world proportions, bevelled silhouettes, smooth round surfaces vs. crisp architectural planes, continuous facade modules with varied heights/awnings/invented proper-noun shop names (safe under Minimal rating rules), and warm sunlight;
- **Ball visual target**: A rolling ball that reads as an actual heap of collected objects rather than a bare sphere with sparse attachments;
- **Theme evaluation order**: Every asset and street layout is judged in `city` (Sunny City) first; `winter` (Holiday City) is applied strictly as seasonal dressing on top and MUST NOT blanket every top surface in white.

**Why this priority**: Gives agents and the owner a single, unambiguous visual specification before rebuilding the asset library (`004h`), vertical slice (`004i`), or full map (`004j`).

**Independent Test**: Can be verified by reviewing `docs/design/08-style-bible.md` and `docs/design/README.md` to confirm that all required sections (concept reference, colour rules, proportions, edge treatment, per-class/per-tier detail targets, facade and signage rules, ground/road/kerb/crossing rules, deliberate orientation vs. scatter rules, lighting, ball heap appearance, and `city`-first / `winter`-dressing rules) are documented and explicitly take precedence over `06-art-style.md`.

**Acceptance Scenarios**:

1. **Given** `docs/design/08-style-bible.md`, **When** inspected against the feature requirements, **Then** it covers colour rules, proportions, edge treatment, detail budgets per object class and tier, continuous/varied facade rules with awnings and invented proper-noun signage, dark road with yellow lines and crossings, pale sidewalks with kerbs, evenly spaced trees and lamps, realistic bin/bench/vehicle placement orientations, warm sun lighting, ball-as-object-heap rules, and the `city`-first / `winter`-dressing rule.
2. **Given** any conflict between `docs/design/08-style-bible.md` and `docs/design/06-art-style.md` (such as signage text rules, atlas usage for facades/signs, `w-season` snow coverage, or target triangle utilization), **When** consulted by an agent or reviewer, **Then** `docs/design/08-style-bible.md` and `docs/design/README.md` explicitly state that `08-style-bible.md` overrides `06-art-style.md`.
3. **Given** the owner's concept reference image prompt/request, **When** the feature folder is prepared, **Then** the location for the concept image (`specs/009-style-bible-bakeoff/concept-reference.png` or equivalent) is documented and referenced by the style bible.

---

### User Story 3 - Five-Prop Multi-Source Asset Bake-Off & Sourcing Rule (Priority: P1)

Before committing to re-authoring all 99+ city assets, the owner needs to compare concrete visual results and triangle counts across candidate asset pipelines in the exact same small street scene under identical warm-sun lighting:
The same **5 representative items**—(1) a **hatchback** (Tier 4 vehicle), (2) a **shop front** (Tier 4/5 facade with awning and sign), (3) a **bench** (Tier 3 street furniture), (4) a **street tree** (Tier 3 foliage), and (5) a **fire hydrant** (Tier 2 sidewalk prop)—are assembled in a small street diorama (dark road with yellow markings, pale sidewalk with kerb) and rendered from matching camera angles with exact triangle counts recorded for each source:
1. **Source 1 — Upgraded In-House Pipeline**: Built with our procedural/scripted 3D pipeline using a substantial share of the tier triangle budgets (`500 / 700 / 1,500 / 3,500 / 5,000`) in accordance with `08-style-bible.md`.
2. **Source 2 — Curated CC0 Asset Pack**: Imported from a coherent CC0 pack (such as Kenney or Quaternius), mapped onto our shared theme atlas, with the pack's exact CC0 licence and attribution status verified and recorded.
3. **Source 3 — AI 3D Generation (Single Hero Only, With Owner Approval)**: One hero prop generated via AI 3D mesh generation and cleaned up to budget, executed only after explicit owner approval because generation may consume paid credits; if the owner declines or defers paid credit spend, this is recorded and compared against Sources 1, 2, and Creator Store.
4. **Comparison Baseline — Marketplace / Creator Store Inspection**: Checked as a comparison if a suitable mesh-only, Minimal-safe asset exists, documenting licence/script safety and visual fit while confirming why marketplace assets are not the default source.

From the side-by-side renders and triangle table, the owner chooses the winning direction, and the chosen asset sourcing rule is committed to the design documentation and bake-off report.

**Why this priority**: Prevents wasting effort on an asset production method that still looks childish or inconsistent, and gives the owner a direct visual choice backed by rendered street scenes and triangle metrics.

**Independent Test**: Can be verified by inspecting the bake-off report and rendered comparison images in `specs/009-style-bible-bakeoff/bakeoff/`, confirming that all 5 items are shown in the same lit small-street setup with measured triangle counts per prop and source, licences recorded for CC0 packs, owner approval respected for any paid 3D generation, and the resulting written asset sourcing rule recorded.

**Acceptance Scenarios**:

1. **Given** the 5 bake-off subjects (hatchback, shop front, bench, street tree, hydrant), **When** built/imported for Source 1 (upgraded pipeline utilizing budget) and Source 2 (CC0 pack moved onto the atlas with licence recorded), plus Source 3 (single AI-generated and cleaned-up hero, subject to prior owner credit approval) and any suitable mesh-only marketplace comparison, **Then** each candidate set is placed into the identical small street scene with the same warm-sun lighting and rendered at matching angles.
2. **Given** the bake-off report in `specs/009-style-bible-bakeoff/bakeoff/README.md`, **When** inspected, **Then** it tabulates the exact triangle count of each of the 5 items across every tested source against its tier budget, records the verified licence URL and terms for every CC0 pack tested, and includes the side-by-side renders.
3. **Given** the completed bake-off comparison presented to the owner, **When** the owner selects the winning asset direction, **Then** the decision is codified as an explicit written rule in `docs/design/08-style-bible.md` and `specs/009-style-bible-bakeoff/bakeoff/README.md`.

---

### User Story 4 - Measured Scene Triangle Ceiling & Heavy-Scene Performance Benchmark (Priority: P2)

`docs/design/03-city-level.md` previously set an arbitrary `250,000`-triangle ceiling for the whole scene (`100,000` culled), which discouraged using the per-tier mesh triangle budgets even though the platform's documented low-end baseline is below `1,000` draw calls and `1,000,000` triangles, and today's entire Downtown scene is only roughly `170,000` triangles because individual meshes average just `72–272` triangles.

To ensure the upgraded assets in `004h`–`004j` can use their full triangle budgets without guessing at performance limits, a heavy test scene is constructed and benchmarked in a live session (testing elevated scene triangle totals up toward the platform's `1,000,000`-triangle / `< 1,000` draw-call envelope while maintaining `< 2,000` active parts and 12 active balls). The arbitrary `250,000`-triangle ceiling in `docs/design/03-city-level.md` (and any corresponding test assertions) is replaced with the empirically measured triangle and draw-call limit. In addition, the owner is asked once for an early phone reading (which is recorded if provided, and does not block completion of this feature).

**Why this priority**: Unlocks the triangle budget needed by the style bible and asset bake-off while keeping the 30 fps mobile performance guarantee grounded in actual measurement.

**Independent Test**: Can be verified by running the heavy test scene benchmark, recording frame rate (separating unthrottled seconds from any 15 fps background-throttled seconds), draw-call/part counts, and total scene triangles in `specs/009-style-bible-bakeoff/playtest.md`, and confirming that `docs/design/03-city-level.md` and unit tests reflect the new measured scene triangle ceiling.

**Acceptance Scenarios**:

1. **Given** a heavy test scene in Play representing high-budget meshes across Downtown placement counts (plus 12 active balls), **When** frame rate, active parts, and triangle counts are sampled over 60 seconds, **Then** the unthrottled frame rate (`>= 30 fps`), total triangles, and active parts (`< 2,000`) are recorded in `specs/009-style-bible-bakeoff/playtest.md`.
2. **Given** the measured heavy-scene benchmark results, **When** `docs/design/03-city-level.md` and `tests/unit/Downtown.test.luau` are updated, **Then** the arbitrary `250,000` unculled / `100,000` culled triangle ceiling is replaced with the measured scene triangle ceiling.
3. **Given** that physical phone performance on the heavier scene is unproven, **When** the benchmark is reported, **Then** the owner is asked once for an early phone reading and the open phone verification is tracked without blocking this feature.

---

### Edge Cases

- **Live Viewport Capture Timeouts When Editor Is Backgrounded**: If live viewport capture times out, the agent asks the owner at most once to keep the editor window in front for a capture pass, and regardless of whether live capture succeeds, the offline fallback renderer MUST be capable of producing all five fixed camera shots directly from world data and exported meshes so visual verification never stalls or ships without images.
- **Prerequisite Constitution Amendment Before Planning**: The prompt specifies a prerequisite constitution amendment (`/speckit-constitution`) covering Principle IV (invented proper-noun shop names and short signage on textures/billboards), Principle I & Quality Gates (visual gate where owner inspection of fixed shots and playing the build can hold map/art features), and Principle XI (imported CC0 meshes on the atlas count as made/edited in Blender with licence recorded, plus one shared facade/sign atlas if needed and a capped set of billboard textures). If the constitution has not yet been amended when `/speckit-plan` runs, the plan MUST require or verify the constitution amendment first rather than ignoring the governance rules.
- **Paid Credits for AI 3D Generation (`generate_3d`)**: Because generating a 3D hero mesh via the 3D generator may cost user credits or money, the agent MUST NOT invoke paid 3D generation without explicit owner approval (Constitution Human Approval Required). If approval is not yet granted at execution time, the bake-off prepares Sources 1, 2, and the marketplace comparison and prompts the owner once before running Source 3.
- **Winter Theme Over-Whiting (`w-season`)**: Applying `w-season` to every horizontal surface turns the entire map white in `winter` and destroys contrast. The style bible MUST restrict `w-season` snow caps to designated seasonal accents/roof trims so roads, sidewalks, kerbs, and building facades preserve their `city` readability in `winter`.
- **Small Mesh Upload Batches**: Uploading new meshes to the game engine requires an owner hand-off or interactive asset upload; therefore, the bake-off relies primarily on offline 3D renders for the owner's decision and keeps any in-engine mesh upload batch minimal (at most the 5 bake-off props or winning set).

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Prerequisite Governance & Visual Gate Alignment

- **FR-001**: Before implementation planning (`/speckit-plan`) proceeds to execution, the repository's constitution (`.specify/memory/constitution.md`) MUST reflect or be amended via `/speckit-constitution` to include the owner's 2026-11-02 decisions:
  - **Principle IV**: Allow invented proper-noun shop names and short signage on textures and billboards (untranslated proper nouns for shop names; localisation keys or pictograms for all other text), while keeping real brands/logos, meme images, real faces, alcohol/gambling names, and "Roblox"/"Robux"/"Blox" or Roblox logo imitations strictly banned, and ensuring placeholder art never imitates a real ad;
  - **Principle I & Quality Gates**: Establish a **visual gate** for map and art features so that the five fixed shots are mandatory (never waived by the two-failure tooling rule) and the owner's review of the fixed shots and playing the build CAN hold map and art features, while non-visual owner checks remain on `docs/release-candidate.md`;
  - **Principle XI**: Count imported CC0 meshes as "made or edited in Blender" when moved onto the project atlas with their licence recorded, and permit one shared atlas for building fronts and signs (if needed by the bake-off) plus a capped set of billboard textures.

#### Part B: Repeatable 5-Shot Capture Route & "Before" Set

- **FR-002**: The project MUST provide a repeatable capture route that renders five fixed camera viewpoints of the active world (`city` theme by default, with `winter` optional):
  1. `01_spawn_d2`: Spawn doorstep at start size (`diameter = 2` studs);
  2. `02_street_d5`: Street level at the Tier 2 transition (`diameter = 5` studs);
  3. `03_midgame_d12_30`: Mid-game street and district framing (`diameter = 12 to 30` studs);
  4. `04_lategame_d80`: Late-game pullback framing (`diameter = 80` studs);
  5. `05_overhead_map`: Full-map overhead orthographic or high-altitude perspective view showing all rings/blocks.
- **FR-003**: The capture route MUST support two execution paths using the same five camera definitions:
  1. **Primary (Live Studio Capture)**: Captures the five viewpoints in Studio via `screen_capture` (asking the owner at most once to keep Studio in front if background throttling causes timeouts);
  2. **Fallback (Offline 3D Scene Renderer)**: A repeatable script (`art/scripts/`) that loads the world module's static blocks, resolved placements, palette/atlas textures, and exported meshes (`art/export/`) into Blender and renders the exact same five camera viewpoints to PNG/JPG files on disk without requiring Studio.
- **FR-004**: Using the capture route, the five fixed shots of the current (post-008) Downtown world MUST be generated and committed under `specs/009-style-bible-bakeoff/captures/before/` as the "before" baseline set.

#### Part C: Style Bible (`docs/design/08-style-bible.md`)

- **FR-005**: A new design document `docs/design/08-style-bible.md` MUST be created (and linked in `docs/design/README.md` with an explicit rule that `08-style-bible.md` overrides `06-art-style.md` on conflict), grounded in the owner's concept image (`specs/009-style-bible-bakeoff/concept-reference.png`, requested from the owner if not yet in the folder).
- **FR-006**: `docs/design/08-style-bible.md` MUST define concrete, testable art and layout standards covering:
  - **Colour & Surface Hierarchy**: Desaturated quiet architectural and ground surfaces (`w-asphalt`, `w-sidewalk`, `w-kerb`, `w-wall-*`) vs. saturated hero/prop accents (`w-accent-*`);
  - **Proportions & Edge Treatment**: Real-world object proportions (no chunky toy scaling), silhouette bevels, smooth shading on cylindrical/round forms, and crisp edges on architectural planes;
  - **Detail & Triangle Utilization by Object Class & Tier**: Minimum and target triangle utilization bands within the `500 / 700 / 1,500 / 3,500 / 5,000` budgets for Tier 1 clutter, Tier 2 sidewalk props, Tier 3 street furniture/trees, Tier 4 vehicles/shops, and Tier 5 buildings/landmarks so props never ship as 70–270 triangle boxes;
  - **Facade & Signage Rules**: Continuous, varied building fronts lining streets with awnings, recessed shop windows, cornice/floor bands, and invented proper-noun shop signage (compliant with Minimal maturity rules);
  - **Ground, Road & Street Furniture Rules**: Dark asphalt carriageways with yellow centre/lane lines and pedestrian crossings, pale raised sidewalks with distinct kerbs, evenly spaced street trees and lamps along kerbs, and benches/bins/vehicles oriented parallel or perpendicular to the kerb/road rather than placed with random yaw;
  - **Lighting & Theme Layering**: Warm directional sunlight with clear street shadows; all worlds and assets are judged in `city` first, while `winter` is dressing layered on top that MUST NOT turn every top surface white;
  - **Ball Appearance**: How the player's ball reads visually as a dense, overlapping heap of absorbed objects rather than a bare sphere.

#### Part D: Five-Item Asset Bake-Off & Written Sourcing Rule

- **FR-007**: An asset bake-off MUST be conducted across the same five city items—`hatchback` (Tier 4), `shop_front` (`corner_bakery` / shop facade, Tier 4/5), `bench` (Tier 3), `street_tree` (Tier 3), and `fire_hydrant` (Tier 2)—placed in a consistent small-street test scene (dark road with yellow lines/crossing, pale sidewalk with kerb, warm sun lighting) and rendered at matching camera angles:
  - **Candidate 1 (In-House Blender Pipeline at Full Detail Budget)**: All 5 items modelled/updated in Blender utilizing a realistic share of the `500 / 700 / 1,500 / 3,500 / 5,000` tier triangle budgets and style-bible rules;
  - **Candidate 2 (CC0 Asset Pack on Project Atlas)**: Matching items imported from a coherent CC0 pack (e.g., Kenney or Quaternius) into Blender, remapped onto the project's shared atlas, with the pack's licence URL, CC0 dedication, and attribution notes recorded;
  - **Candidate 3 (Blender MCP `generate_3d` Single Hero + Cleanup)**: One hero item generated via `generate_3d` and cleaned up in Blender to fit budget and style rules, executed ONLY after explicit owner approval (or documented as awaiting/declined credit approval if the owner chooses not to spend credits);
  - **Comparison 4 (Creator Store / Marketplace Inspection)**: Inspection and comparison of a suitable mesh-only Creator Store equivalent (if available), documenting script-safety verification, licence uncertainty, and style consistency against Candidates 1–3.
- **FR-008**: The bake-off results—including side-by-side street renders, per-prop triangle counts vs. tier budgets, CC0 licence records, and the owner's chosen asset sourcing rule—MUST be documented in `specs/009-style-bible-bakeoff/bakeoff/README.md` and summarized in `docs/design/08-style-bible.md`. Any in-engine mesh upload hand-off MUST be kept to a small batch (at most the 5 bake-off props if needed).

#### Part E: Measured Scene Triangle Ceiling & Heavy-Scene Benchmark

- **FR-009**: A heavy test scene in Studio MUST be run and measured (simulating Downtown placement counts populated with higher-budget meshes up toward the platform's low-end baseline of `< 1,000` draw calls and `<= 1,000,000` triangles, with 12 active balls and `< 2,000` active parts), recording 60-second frame-rate samples (separating unthrottled seconds from any 15 fps background-throttled seconds), active part counts, and total unculled and culled (`cullTierDelta = 2`) scene triangles in `specs/009-style-bible-bakeoff/playtest.md`.
- **FR-010**: Based on the heavy test scene measurement, the `250,000` unculled / `100,000` culled triangle ceilings in `docs/design/03-city-level.md` and `tests/unit/Downtown.test.luau` MUST be replaced with the empirically measured scene triangle ceilings. The owner MUST be asked once for an early phone reading (which is logged in `playtest.md` if available or tracked on `docs/release-candidate.md` without blocking this feature).
- **FR-011**: `scripts/check.sh` (format, lint, typecheck, and all Lune unit tests) MUST exit `0`.

### Key Entities

- **Fixed Camera Shot Set (`01_spawn_d2` .. `05_overhead_map`)**: Five deterministic camera definitions (position, look-at target, FOV, and target ball diameter context) shared between live Studio capture and the offline Blender world renderer to produce comparable "before" and "after" image sets.
- **Style Bible (`docs/design/08-style-bible.md`)**: The authoritative visual specification governing main-street composition, facade continuity, road/sidewalk/kerb markings, deliberate prop orientation, per-tier triangle utilization, invented proper-noun signage, lighting, ball-heap appearance, and `city`-first / `winter`-dressing rules.
- **Bake-Off Candidate Matrix**: A structured comparison of the 5 benchmark assets (`hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`) across 3+ production sources, recording triangle counts, atlas/texture usage, licence provenance, rendered street appearance, and the owner's selected sourcing rule.
- **Measured Scene Triangle Ceiling**: The empirically validated maximum unculled and `cullTierDelta = 2` culled triangle counts for a Downtown scene in `docs/design/03-city-level.md` and `tests/unit/Downtown.test.luau`, replacing the arbitrary `250,000` / `100,000` limits.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The repeatable capture route executes cleanly and produces all 5 fixed "before" shots (`01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`) as committed image files under `specs/009-style-bible-bakeoff/captures/before/`.
- **SC-002**: `docs/design/08-style-bible.md` is committed, linked from `docs/design/README.md` as overriding `06-art-style.md` on conflict, and defines explicit, measurable standards for all 8 required areas (colour hierarchy, proportions, edge treatment, per-class/per-tier detail & triangle floors, continuous facades & invented signage, road/sidewalk/kerb/crossing rules & non-random prop orientation, warm sun lighting & `city`-first/`winter`-dressing rules, and ball-heap visual density).
- **SC-003**: The 5-prop asset bake-off (`hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`) is rendered in a single consistent small-street scene under identical lighting across the required sources, with measured triangle counts and verified CC0 licences committed in `specs/009-style-bible-bakeoff/bakeoff/`, and the owner's chosen asset sourcing direction is recorded as a written rule.
- **SC-004**: A 60-second heavy-scene performance benchmark in Studio confirms `>= 30 fps` on unthrottled seconds and `< 2,000` active parts at the new measured triangle ceiling, replacing the `250,000`-triangle ceiling in `docs/design/03-city-level.md` and `tests/unit/Downtown.test.luau` with results logged in `specs/009-style-bible-bakeoff/playtest.md`.
- **SC-005**: `scripts/check.sh` exits `0` with zero formatting, lint, typecheck, or unit test errors.

## Scope & Boundaries

### In Scope

- Coordinating with or verifying the prerequisite constitution amendment (`/speckit-constitution` for Principles I, IV, XI, and Quality Gates) before `/speckit-plan`.
- Building the repeatable 5-shot visual capture route (Studio `screen_capture` primary path + offline Blender world/mesh fallback renderer) and committing the 5 "before" shots of the current world in `specs/009-style-bible-bakeoff/captures/before/`.
- Asking the owner to place the concept reference image into `specs/009-style-bible-bakeoff/` and authoring `docs/design/08-style-bible.md` (plus updating `docs/design/README.md` so `08-style-bible.md` overrides `06-art-style.md` on conflict).
- Running the 5-item asset bake-off (`hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`) in one small street scene across: (1) our Blender pipeline using a realistic share of the triangle budget, (2) a coherent CC0 pack (e.g., Kenney or Quaternius) moved onto our atlas with its licence verified and recorded, (3) one hero generated via Blender MCP `generate_3d` and cleaned up (after owner approval for any credit spend), and (4) a Creator Store mesh-only comparison if a suitable mesh exists; presenting the renders and triangle counts for the owner's choice and recording the written sourcing rule.
- Running a heavy test scene in Studio to replace the `250,000`-triangle ceiling in `docs/design/03-city-level.md` (and `tests/unit/Downtown.test.luau`) with a measured limit, recording results in `specs/009-style-bible-bakeoff/playtest.md`, and asking the owner once for an early phone reading.

### Out of Scope

- Rebuilding the full 99-object city asset library (**Feature 004h**).
- Building the playable main-street vertical slice with the new assets and layout rules (**Feature 004i**).
- Redesigning and rebuilding the full Downtown map layout (**Feature 004j**).
- Changing `src/shared/Rules/Layout.luau` yaw/alignment behaviour or `src/shared/Content/Worlds/Downtown.luau` level layout (those belong to `004i` / `004j` once the style bible and bake-off direction are locked).

## Assumptions

- **Feature Ordering & Numbering**: Although referred to in the backlog sequence alongside `004h` (full asset library), `004i` (slice), and `004j` (map), this specification uses the repository's sequential feature numbering (`009-style-bible-bakeoff`, following `008-downtown-inside-out`).
- **Offline Blender Renderer Guarantees the "Before" Set**: Because Studio `screen_capture` can time out when the Studio window is not in the foreground on the owner's desktop, the offline Blender scene renderer (reading `Downtown.luau` geometry/placements, `art/export/*.fbx`, and the theme palette/atlas) guarantees that all 5 fixed shots are always produced and saved as PNG/JPG files in `specs/009-style-bible-bakeoff/captures/before/`, while Studio `screen_capture` is also run when Studio is in front.
- **Owner Approval Gate for Paid `generate_3d` Credits & Bake-Off Winner**: In accordance with the prompt and Constitution Human Approval Required, invoking `generate_3d` (if it consumes paid credits) requires asking the owner first, and the final bake-off direction and visual sign-off are confirmed by the owner before the feature closes.
- **Early Phone Reading Is Non-Blocking**: Asking the owner once for an early phone FPS reading on the heavy scene fulfills the phone check requirement for this item; if a physical phone reading is not immediately available, the Studio heavy-scene measurement locks the updated ceiling in `docs/design/03-city-level.md` and the phone reading remains tracked on `docs/release-candidate.md`.
