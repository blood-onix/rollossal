# Feature Specification: Dedicated City Asset Kit, Style Audit, Shop Signage & Meme Originals

**Feature Branch**: `013-city-asset-kit`

**Created**: 2026-11-07

**Status**: Draft

**Input**: User description: "The dedicated art item (owner, 2026-11-02): a full asset list in one design style, built in parallel with the slice. Depends on 004g (style bible and asset source rule). Parallel with 004i: this item claims Blender, 004i claims Studio (constitution X). Both touch `src/shared/Assets.luau` and `art/export/manifest.json`, so keep those merges small. Mesh uploads are an owner hand-off: batch them, and meanwhile the fallback stand-ins hold. Constitution: IV, VI, XI."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Audit of Existing 99 City Meshes Against the Style Bible (Priority: P1)

Before rebuilding or adding dozens of city assets, the existing 99 `dt_*` meshes are rendered in a consistent quality-assurance setup and evaluated against the authoritative style bible (real-world proportions, 1-segment silhouette bevels, smooth round forms vs. sharp architectural planes, 2–4 palette roles with one accent, seasonal trim discipline, and per-tier triangle utilization). Each of the 99 meshes is classified as **keep**, **upgrade**, or **replace** so the team never rebuilds an asset that already passes and concentrates triangle budgets where players actually look—keeping tiny ground litter cheap while giving high-visibility street furniture, vehicles, and building fronts the geometric detail they need.

**Why this priority**: Establishes the exact work scope for the asset pass, prevents wasted effort on already-passing meshes, and ensures the total scene triangle budget stays focused on the most visible objects.

**Independent Test**: Can be verified independently by inspecting the completed audit report and rendered contact sheets for all 99 `dt_*` assets, confirming every asset has a recorded triangle count, tier budget comparison, style-bible verdict (`keep`, `upgrade`, or `replace`), and rationale.

**Acceptance Scenarios**:

1. **Given** the 99 existing `dt_*` city meshes, **When** the style-bible audit is run, **Then** all 99 meshes are rendered in both `city` and `winter` palettes and listed in an audit table with their current triangle counts, tier ceilings, and an explicit `keep`, `upgrade`, or `replace` disposition.
2. **Given** an existing `dt_*` mesh that already meets the style bible's silhouette, colour hierarchy, and readability standards (such as small ground litter where extra polygons are invisible at camera distance), **When** classified in the audit, **Then** it is marked `keep` and is not redundantly rebuilt.
3. **Given** an existing `dt_*` mesh that looks boxy, lacks silhouette bevels, blankets top surfaces in seasonal white, or fails to read at its game-camera distance, **When** classified in the audit, **Then** it is marked `upgrade` or `replace` with specific remediation notes for the production pass.

---

### User Story 2 - Cohesive Zone-by-Zone City Asset Kit & Contact Sheets (Priority: P1)

Players rolling from the park and suburbs into main street and downtown see a cohesive, believable city built in one unified "stylised real" visual style rather than repetitive placeholder boxes. Every absorbable building and prop is a single-mesh object within its tier's triangle ceiling, assembled from modular building pieces or zone kits so a street never repeats the same building next to itself:
- **Building kit**: Wall, window bay, door, shop front, awning, cornice, and roof modules in multiple widths, combined into single meshes per building variant covering suburban houses with garages and fences, shop rows, mid-rise blocks, and downtown towers.
- **Street kit**: Road markings, pedestrian crossings, kerb corners, street lamps, traffic lights, street signs, bus stops, planters, bollards, and railings.
- **Park zone**: Three distinct tree types, bushes, flower beds, picnic table, picnic blanket and basket, playground equipment, park paths, and pond edge pieces.
- **Suburbs zone**: Mailbox, wheelie bin, barbecue, lawn mower, garden fence, trampoline, bicycle, and driveway cars.
- **Main street zone**: Cafe table and parasol, fruit crates, newspaper box, fire hydrant, bench, scooter, and delivery van.
- **Downtown zone**: Taxis, buses, kiosks, office towers, a cinema, and large landmarks that a late-game ball can eat.

For owner visual review (Gate 6), every zone's complete asset set is rendered into a clear zone contact sheet in both `city` (Sunny City) and `winter` (Holiday City) themes.

**Why this priority**: Delivers the core visual upgrade of the game's world objects across every progression zone while keeping every absorbable building and prop as a single, budget-compliant mesh ready for map placement.

**Independent Test**: Can be verified by inspecting the exported asset files, manifest records, and the rendered contact sheets (one per zone in `city` and `winter`), confirming every listed asset meets the style bible and stays within its tier triangle budget.

**Acceptance Scenarios**:

1. **Given** the finalised asset list across Building kit, Street kit, Park, Suburbs, Main street, and Downtown, **When** each asset is created or upgraded, **Then** every absorbable prop or building variant is exported as a single unified mesh using the shared theme palette/signage atlases, within its tier's triangle ceiling, and with seasonal trim restricted to accent edges rather than blanketing top surfaces.
2. **Given** the modular building kit (wall, window bay, door, shop front, awning, cornice, roof pieces across multiple widths), **When** joined into building variants (suburban houses, shop rows, mid-rise blocks, towers), **Then** there are enough distinct single-mesh building variants that adjacent placements along a street never need to repeat the identical building side by side.
3. **Given** the completed assets for each zone (Building kit, Street kit, Park, Suburbs, Main street, Downtown), **When** QA renders are generated, **Then** one contact sheet per zone is produced in both `city` and `winter` themes and presented for owner approval.
4. **Given** new or updated meshes awaiting upload to the game platform, **When** packaged for the owner hand-off, **Then** uploads are grouped into a clean batch with fallback stand-ins active in data until the owner provides the uploaded asset IDs.

---

### User Story 3 - Invented Shop Signage & Deadpan Placeholder Billboards (Priority: P2)

Main streets and downtown blocks feel alive and readable because shop fronts carry invented shop names and sign art, and billboards display deadpan visual gags rather than blank rectangles or real-world advertisements. Around 20 invented proper-noun shop names (in the tone of *Blocky Mart*, *Cafe Cube*, *Stud Pizza*) are vetted for brand and age-rating safety and paired with facade sign art and a capped set of placeholder billboard designs.

**Why this priority**: Transforms generic architectural boxes into recognizable storefronts and urban landmarks that sell the scale of the city at street level.

**Independent Test**: Can be verified by reviewing the catalogue of ~20 invented shop names, their verification records showing no real-brand collisions or banned terms, and the rendered shop-front and billboard contact sheet in `city` and `winter`.

**Acceptance Scenarios**:

1. **Given** the list of approximately 20 invented shop names, **When** vetted against safety and trademark rules, **Then** every name is searched and confirmed free of real-brand similarity, alcohol or gambling references, and the forbidden words *Roblox*, *Robux*, or *Blox* (or any imitation of the platform logo).
2. **Given** shop-front building variants and billboards, **When** rendered in `city` and `winter`, **Then** shop signs use the approved invented proper-noun names with clean sign art (needing no localisation keys as proper nouns), while all non-shop-name signage uses pictograms or localised string keys, and billboard count stays within the configured cap.

---

### User Story 4 - Meme Originals & Swappable `slot.meme` Dressing Slot (Priority: P2)

Players encounter 5 to 8 deadpan, internet-humour sight gags in the world—built from original geometry and ideas rather than copyrighted meme images, names, or audio—that can be rotated in future content drops without editing the map layout. A dedicated `slot.meme` dressing slot allows any meme prop to be swapped purely through content data.

**Why this priority**: Adds the 16+ deadpan spectacle and shareable moments ("my ball just ate the giant Banana for Scale statue") while protecting the game from copyright takedowns and stale jokes.

**Independent Test**: Can be verified by checking that 5 to 8 meme original assets are modelled, budgeted, named in English and Spanish localisation tables, bound to the `slot.meme` data slot, and rendered on a contact sheet in `city` and `winter`.

**Acceptance Scenarios**:

1. **Given** the starter list of meme concepts (such as a giant Banana for Scale statue, a lost shopping cart in the pond, a statue with a traffic cone on its head, a Wet Floor sign in the middle of nowhere, deadpan joke billboards like buffering/404/number-go-up, a phone statue at 1% battery, a bare grey stud-plate vacant lot, or inanimate original hybrid statues), **When** 5 to 8 meme originals are selected and built, **Then** each uses only the underlying comedic idea—never a copyrighted meme image, protected name, real person's face, music, or named Italian-brainrot character—and passes all Minimal age-rating rules.
2. **Given** a world placement using `slot.meme`, **When** the active meme binding in content data is changed, **Then** the world spawns the newly bound meme object without any change to map geometry or placement code.
3. **Given** each meme original object, **When** added to the content catalogue, **Then** its display name is present in both English and Spanish localisation tables and its mesh stays within its tier's triangle budget.

---

### Edge Cases

- **Parallel Work & Shared-File Contention (`004i` / Studio vs. Blender)**: Because this feature runs in parallel with the vertical slice (`004i`), this feature claims the 3D modelling tool (Blender) and must not claim or depend on live game-editor sessions when `004i` holds them. Edits to shared manifest and asset-ID registry files (`src/shared/Assets.luau` and `art/export/manifest.json`) must be kept minimal, deterministic, and isolated to small merges so parallel branches do not conflict.
- **Unuploaded Meshes During Owner Hand-Off**: New or replaced meshes do not have platform asset IDs until the owner runs the batch upload. While an asset ID is empty (`""`), the game must cleanly render its fallback stand-in shape and palette colour without errors or warnings.
- **Shop Name Collisions with Real Brands**: An invented name that sounds generic might accidentally match an existing real-world business or trademark. Every candidate shop name must be searched before inclusion; any name with a close real-world brand match is discarded and replaced.
- **Winter Theme Over-Whiting (`w-season`)**: Applying the seasonal swatch across entire roofs, lawns, or car bonnets washes out the scene in `winter`. Every kept, upgraded, or newly built mesh must restrict `w-season` to small accent trims (under 15% of visible surface area).
- **Single-Part Absorbable Building Rule**: Modular building pieces (walls, bays, doors, awnings, cornices, roofs) exist to speed up authoring, but the game requires every absorbable object to be a single mesh instance. All modular components of a building variant must be joined into one unified mesh before export.
- **Imported CC0 Meshes (If Any)**: If the owner reopens CC0 imports for any prop, each pack's CC0 licence and source URL must be verified and recorded in the repository, and the mesh must be remapped onto the project's shared atlas in Blender; otherwise, all assets are built in-house per the 009 sourcing rule.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Existing Asset Audit (`dt_*` Catalogue)

- **FR-001**: All 99 existing `dt_*` meshes MUST be rendered and audited against `docs/design/08-style-bible.md` in both `city` and `winter` themes, recording for each asset: its current triangle count, tier budget, visual assessment, and a disposition of `keep`, `upgrade`, or `replace`.
- **FR-002**: Assets marked `keep` MUST NOT be rebuilt. Triangle budgets MUST be allocated where players see them: small Tier 1 litter stays lightweight and cheap, while high-visibility street furniture, vehicles, heroes, and building fronts use the style bible's detail bands within `Config.Budgets.meshTriangles` (and `Config.Budgets.meshTrianglesSix` where 6-tier indexing applies) without exceeding the measured scene triangle ceiling from feature 009 (`004g`).

#### Part B: Complete Zone Asset Kit

- **FR-003**: The implementation plan MUST finalise the complete asset list by zone, tier, and stud dimensions across all six groups, and every asset on the finalised list MUST be produced (or retained via `keep`) as a single exported mesh per absorbable object:
  1. **Building kit**: Wall, window bay, door, shop front, awning, cornice, and roof modules in multiple widths, joined into single meshes per building variant covering suburban houses (with garages and fences), shop rows, mid-rise blocks, and towers, with enough variants that a street never repeats the same building next to itself;
  2. **Street kit**: Road markings, crossings, kerb corners, street lamps, traffic lights, street signs, bus stop, planters, bollards, and railings;
  3. **Park**: Three distinct tree types, bushes, flower beds, picnic table, blanket and basket, playground pieces, paths, and pond edge;
  4. **Suburbs**: Mailbox, wheelie bin, barbecue, lawn mower, garden fence, trampoline, bicycle, and driveway cars;
  5. **Main street**: Cafe table and parasol, fruit crates, newspaper box, fire hydrant, bench, scooter, and delivery van;
  6. **Downtown**: Taxis, buses, kiosks, office towers, a cinema, and large landmarks a late-game ball can eat.
- **FR-004**: Every asset MUST comply with `docs/design/08-style-bible.md` and `docs/design/05-roblox-limits.md`: real-world proportions (at most one hero feature exaggerated by ≤ 10%), 1-segment bevel on main silhouettes, smooth round parts and sharp hard edges, single material mapped to the shared theme gradient atlas (or the shared building-front/signage atlas and capped billboard textures), no PBR/SurfaceAppearance, no transparency, no per-prop lights, and `w-season` used strictly as an accent trim.

#### Part C: Shop Signage & Placeholder Billboards

- **FR-005**: The feature MUST deliver a vetted list of approximately 20 invented proper-noun shop names (matching the tone of *Blocky Mart*, *Cafe Cube*, *Stud Pizza*) with accompanying sign art and placeholder billboard textures (within a billboard texture cap defined in `src/shared/Config.luau`).
- **FR-006**: Every invented shop name MUST be searched prior to use to verify it is not close to a real-world brand, and MUST NOT contain the words *Roblox*, *Robux*, or *Blox*, any imitation of the Roblox logo, or any alcohol or gambling references. Placeholder billboards MUST NOT imitate real advertisements.

#### Part D: Meme Originals & `slot.meme` Dressing Slot

- **FR-007**: The feature MUST select and build 5 to 8 original meme-inspired objects from the starter concepts (such as a giant Banana for Scale statue, a lost shopping cart in the pond, a statue with a traffic cone on its head, a Wet Floor sign in the middle of nowhere, deadpan joke billboards with buffering/404/number-go-up chart, a phone statue at 1% battery, a bare grey stud-plate vacant lot with a spawn pad and no logo, and inanimate original hybrid statues with invented names).
- **FR-008**: Every meme original MUST follow the rule *"use the idea, never the image, the name or the music"*, MUST exclude all items on the `docs/design/04-player-cosmetics.md` keep-out list as well as named Italian-brainrot characters, MUST be inanimate (no absorbable people or live animals), and MUST pass `docs/design/05-roblox-limits.md` and Minimal rating rules.
- **FR-009**: The content and theme system MUST support a `slot.meme` dressing slot so meme objects can be swapped purely through content data and shipped in weekly drops without modifying map layouts.

#### Part E: Pipeline, Localisation, Hand-Off & Quality Gates

- **FR-010**: Every new or renamed absorbable object and meme original MUST have its player-facing name registered in both English (`en-us`) and Spanish (`es-es`) localisation tables (invented proper-noun shop names on facade textures require no localisation key per Constitution Principle IV).
- **FR-011**: Every exported mesh MUST be recorded in `art/export/manifest.json` with its tier, triangle count, byte size, and SHA-256 hash, and every asset key MUST be registered in `src/shared/Assets.luau` (using `""` for unuploaded meshes so fallback stand-ins work seamlessly until the batched owner upload hand-off completes, with the hand-off recorded on `docs/release-candidate.md`). If any CC0 mesh is imported, its source and verified licence MUST be recorded in the repository.
- **FR-012**: Parallel execution discipline (Constitution Principle X) MUST be respected: this feature claims Blender, leaves Studio to parallel slice work when contended, and keeps diffs to `src/shared/Assets.luau` and `art/export/manifest.json` small and merge-friendly.
- **FR-013**: QA renders MUST be generated in both `city` and `winter` themes, organized into **one contact sheet per zone** (plus the audit and meme/signage sheets), and presented for owner approval under Gate 6.
- **FR-014**: `scripts/check.sh` (formatting, linting, strict type-checking, Rules purity, and Lune unit tests) MUST exit `0`.

### Key Entities

- **Asset Audit Record**: An entry for each of the 99 existing `dt_*` meshes capturing its ID, tier, current triangle count, tier budget, visual evaluation in `city` and `winter`, and disposition (`keep`, `upgrade`, `replace`).
- **Zone Asset Kit**: The complete set of single-mesh props and joined modular building variants organized by zone (Building kit, Street kit, Park, Suburbs, Main street, Downtown), each with defined stud dimensions, tier, palette roles, and triangle budget.
- **Shop Sign & Billboard Catalogue**: Approximately 20 vetted, brand-safe invented proper-noun shop names with facade sign art and a capped set of deadpan placeholder billboard textures.
- **Meme Original & `slot.meme` Binding**: A content-swappable dressing slot (`slot.meme`) and 5 to 8 original, Minimal-safe comedic props/statues/billboards with localised names in English and Spanish.
- **Zone Contact Sheet**: A composite QA render sheet per zone showing every asset in that zone rendered under standard `city` and `winter` lighting for owner visual sign-off (Gate 6).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the 99 existing `dt_*` meshes are audited with `city` and `winter` renders and assigned a documented `keep`, `upgrade`, or `replace` verdict before new modelling begins.
- **SC-002**: 100% of the assets in the finalised zone list (Building kit, Street kit, Park, Suburbs, Main street, Downtown, and 5–8 Meme originals) pass style-bible validation in `city` and `winter` QA renders and stay at or below their tier's triangle budget in `Config.Budgets.meshTriangles` (with zero multi-part absorbable models and zero forbidden materials/lights).
- **SC-003**: At least 20 invented shop names are vetted with documented brand-safety checks (zero collisions with real brands, zero forbidden words *Roblox*/*Robux*/*Blox*, zero alcohol/gambling terms) and rendered on shop fronts/signs.
- **SC-004**: 5 to 8 meme originals and the `slot.meme` data-driven dressing slot are implemented, tested for data-only swapping without map edits, and have 100% English and Spanish localisation coverage.
- **SC-005**: One contact sheet per zone (rendered in `city` and `winter`) is committed to the feature directory and approved by the owner (Constitution Gate 6), and any pending mesh uploads are batched into a single documented owner hand-off on `docs/release-candidate.md` while fallback stand-ins hold without runtime errors.
- **SC-006**: `scripts/check.sh` exits `0` with all unit, budget, content-validation, and localisation tests passing.

## Scope & Boundaries

### In Scope

- Auditing and rendering all 99 existing `dt_*` meshes against `docs/design/08-style-bible.md` (`keep`, `upgrade`, `replace`).
- Authoring/upgrading the full city asset kit in Blender across Building kit, Street kit, Park, Suburbs, Main street, and Downtown, joined into single meshes per absorbable variant.
- Vetting ~20 invented shop names and authoring shop-front sign art and capped placeholder billboard art.
- Selecting and authoring 5 to 8 meme original assets and adding the `slot.meme` data-driven dressing slot and English/Spanish localisation entries.
- Rendering QA contact sheets in `city` and `winter` (one contact sheet per zone) for owner Gate 6 approval.
- Updating `art/export/manifest.json`, `src/shared/Assets.luau` (with small, merge-safe edits and fallback stand-ins for unuploaded meshes), and batching the mesh upload hand-off on `docs/release-candidate.md`.

### Out of Scope

- Placing the new or upgraded objects into the playable world maps (handled by the vertical slice `004i` / `010` and full map features `004j` / `012`).
- Player ball cosmetics, skins, toppers, trails, auras, and shop UI (`006a`, `006b`).
- Uploading meshes directly into the live or test place without the owner hand-off when asset upload requires owner credentials.

## Assumptions

- **Feature Numbering & Backlog Mapping**: The prompt refers to backlog IDs `004g` (completed as `009-style-bible-bakeoff`), `004h` (this dedicated art feature, numbered sequentially as `013-city-asset-kit`), `004i` (`010-main-street-slice`), and `004j` / `012`.
- **In-House Blender Sourcing Default**: Per the owner's 2026-11-02 decision in `009-style-bible-bakeoff` (`docs/design/08-style-bible.md` section 11), all new and upgraded world meshes are built in Blender using the in-house pipeline to the style bible's detail bands unless the owner explicitly reopens CC0 pack imports (in which case CC0 licences are recorded per pack).
- **Billboard Texture Cap**: Constitution Principle XI requires the small cap on billboard textures to live in `src/shared/Config.luau` and be stated by the feature that adds them; a default cap of `8` billboard textures (sufficient for deadpan meme billboards and city placeholder ads) will be defined in `Config.Budgets` unless adjusted in `plan.md`.
- **Stand-In Fallback Behaviour**: Newly created meshes that have not yet been uploaded by the owner are registered in `src/shared/Assets.luau` with `""` so the existing spawner automatically uses their dimensional stand-in parts until the batched owner upload hand-off is completed.
