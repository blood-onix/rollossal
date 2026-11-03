# Feature Specification: Main-Street Vertical Slice, Rule-Driven Placement & Ball Heap Redesign

**Feature Branch**: `010-main-street-slice`

**Created**: 2026-11-02

**Status**: Draft

**Input**: User description: "Prove the new look and the new way of placing things on a small piece of world, before touching the whole map. Depends on 004g. Runs alongside 004h: it starts with the bake-off props and existing `dt_*` meshes and swaps in new ones as they land. Constitution: I, IV, VI, VII, XI."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Playable Main-Street Vertical Slice with Open Park Start & Rule-Driven Placement (Priority: P1)

Instead of redesigning the entire 880 × 880 Downtown map at once or relying on random grid-scattered zones, players can load into a self-contained ~200 × 500 stud vertical slice in the `city` theme (enabled behind a configuration flag so Downtown remains the default world until the full map rebuild in `004j`).

A player joins on open park ground with immediate food to absorb, no walls or bollard gates trapping the ball, and a clear sightline down a suburban corner into a continuous main street lined with building fronts on both sides and the city skyline visible ahead. Up to 12 starting players spawn on open ground without blocking or starving one another. Every object in the slice is placed with a clear urban purpose through deterministic street rules, composable scene kits (picnic spread, cafe terrace, bus stop, fruit stall, bike rack, road works, car park rows, yard sale, flower bed, recycling point), and natural bulk groupings (rows of parked cars, stacks of fruit crates, lines of cones, and food trails along kerbs, paths, and shop fronts) rather than random scatter.

**Why this priority**: Proves the new visual bar (`docs/design/08-style-bible.md`), the rule-based placement model, and the open-start first minute on a small, inspectable piece of world before scaling the approach to the full map (`004j`).

**Independent Test**: Can be independently tested by enabling the slice world in configuration, running deterministic unit tests on street rules and scene kit expansion, generating the five fixed camera shots (`01_spawn_d2` through `05_overhead_map`), and playing a run from the open park start down the main street toward the skyline with 12 active balls.

**Acceptance Scenarios**:

1. **Given** the vertical slice configuration flag is off (the default), **When** a server starts, **Then** the game loads the existing default world (`Downtown`) unchanged; **When** the slice flag is enabled, **Then** the server loads the ~200 × 500 stud `city` vertical slice.
2. **Given** 12 players starting simultaneously in the vertical slice, **When** the run begins in the open park start area, **Then** every player has immediate Tier 1 food within reach (first pickup within 5 seconds), an unobstructed path and sightline toward the main street and skyline goal, and 12 spawn positions that do not block or collide with one another.
3. **Given** the slice's world content definition, **When** expanded by the pure placement rules, **Then** kerbs, sidewalks, road markings, pedestrian crossings, evenly spaced lamps and street trees, corner bins, road-facing benches, parallel-parked vehicles, and all 10 starter scene kits resolve deterministically within the slice boundaries with intentional orientations (plus only small seeded jitter where real objects naturally vary).
4. **Given** the bake-off props from `009-style-bible-bakeoff` and existing `dt_*` meshes, **When** new meshes from `004h` land, **Then** the slice swaps them in via data without changing placement rule logic.

---

### User Story 2 - Player Ball as a Lumpy Object Heap (Priority: P1)

Previously, the player's ball rendered as a plain grey sphere with at most 30 sparse stuck objects, failing to read as the centrepiece of the frame. In the vertical slice, the ball is redesigned to look like a dense, lumpy heap of what the player has eaten, with recognisable objects sticking out of its silhouette.

By around diameter `D = 5`, the base sphere is mostly hidden—either taking on the colours of its absorbed contents or replaced by a lightweight inner filler layer. As the player eats more objects, the largest and newest catches stay on the outside of the heap so milestone pickups (such as a bus sticking out of the ball) remain prominently visible, while older, smaller items are buried smoothly without visible popping. Attached objects scale sensibly relative to the growing ball so a collection of small pickups still reads as a cohesive heap rather than tiny specks on a giant sphere. Because simply raising `maxVisibleStuck` without bounds would hurt performance across 12 players, the heap visual system is benchmarked with 12 active balls (including a cheaper representation for remote players' balls if needed) to stay at or above 30 fps within part and triangle budgets.

**Why this priority**: The player's ball occupies the centre of every frame and every shared screenshot; the owner identified the current 30-object grey sphere as broken, making the heap redesign essential for visual approval of the slice.

**Independent Test**: Can be independently tested by unit-testing the pure heap selection, burial, and scaling rules at fixed absorb sequences, inspecting the ball across the five fixed shots (`D = 2`, `D = 5`, `D = 12–30`, `D = 80`), and running a 12-ball Studio benchmark verifying `>= 30 fps` on unthrottled seconds.

**Acceptance Scenarios**:

1. **Given** a ball that has grown to `D = 5` and beyond by absorbing world objects, **When** viewed in gameplay and in the fixed camera shots, **Then** the base sphere is mostly hidden (by absorbed objects, content-derived colours, or a filler layer) and the silhouette reads as a lumpy heap of collected items.
2. **Given** a sequence of absorbed objects of varying sizes and timestamps, **When** the heap selection rule chooses which items sit on the outer layer vs. become buried, **Then** the largest and newest catches remain on the outside, milestone catches (such as a bus or large vehicle) visibly protrude from the heap, stuck items scale sensibly with ball growth, and older small objects transition out without sudden visual popping.
3. **Given** 12 active balls rolling and growing simultaneously in the vertical slice, **When** frame rate, active parts, triangles, and draw calls are measured over a playtest in Studio, **Then** unthrottled seconds hold at least `30 fps` and stay within server part and triangle budgets.

---

### User Story 3 - Visual Size Readability Without HUD Text Prompts (Priority: P1)

Players do not read text prompts like "you can absorb cars" during fast-paced rolling. In the vertical slice, a player can tell what is edible simply by looking at the world and at their ball, and by immediate physical feedback when bumping into something too large.

The slice HUD removes the `Next: SIDEWALK STUFF` line, the star-target text row, and the `YOU CAN ROLL UP: ...` tier banner, keeping only the countdown timer and the ball size readout (adding back any element only if the owner misses it during play). If the current `absorbRatio` (`0.4`), camera framing, or object scaling makes size comparison ambiguous by eye, they are adjusted so edible vs. non-edible objects read clearly. When a player rolls into an object that is too large to absorb, the ball receives an immediate, unmistakable physical bump and impact sound—with no text message—teaching the size rule on contact. If playtesting shows a subtle extra visual cue is needed (such as a slight wobble on nearby edible objects), it may be added without putting default outlines on every object.

**Why this priority**: Directly addresses the owner's requirement that edibility must be understood visually and physically rather than through HUD text.

**Independent Test**: Can be independently tested in a Studio playtest on the slice by verifying that the HUD displays only the timer and size number (no `Next:` line, star-target text row, or roll-up banner), confirming that rolling into an oversized prop produces an immediate physical bump and sound with no text prompt, and validating visual size readability with the owner during Gate 6 review.

**Acceptance Scenarios**:

1. **Given** a player in a run on the vertical slice, **When** inspecting the HUD and triggering tier growth milestones, **Then** the countdown timer and ball size readout are shown, while the `Next: ...` line, the star-target text row, and the `YOU CAN ROLL UP` banner are absent.
2. **Given** a player rolling into an object whose size exceeds the absorb threshold for the ball's current diameter, **When** contact occurs, **Then** the ball experiences an immediate physical bump response and plays a clear non-absorbable impact sound without displaying any explanatory text banner or popup.
3. **Given** objects along the park, suburb, and main street, **When** the owner plays the slice and inspects the five fixed shots, **Then** the owner confirms they can tell which objects are edible vs. too large by eye and physical contact alone.

---

### User Story 4 - Data-Driven Shop Front Signs & Capped Billboard Slots (Priority: P2)

To make the main street read as a lively city corridor while staying compliant with Minimal maturity rules and mobile draw-call budgets, building fronts display invented proper-noun shop names and billboards display placeholder art driven entirely from data tables of sign slots and billboard slots.

Changing a shop name or billboard image requires editing only world/content data. Every billboard slot record includes an `id`, world position/orientation, image asset reference, and a boolean `sponsored` field (set to `false` for all slots in this feature, with no real brands and nothing sold, establishing the data contract required for future paid-content disclosure). To bound draw calls from unique textures, shop-front signs share a single facade/sign atlas and unique billboard textures are strictly capped by a configuration limit that is validated by unit tests and measured in Studio.

**Why this priority**: Delivers the main-street character required by the style bible (`docs/design/08-style-bible.md` section 5) and Constitution Principles IV, VII, and XI while keeping texture memory and draw calls bounded.

**Independent Test**: Can be independently tested via Lune unit tests verifying that all sign and billboard slots in the slice resolve to valid assets, all billboard slots carry `sponsored = false`, no banned words appear in shop names, and unique billboard image assets do not exceed the configured cap.

**Acceptance Scenarios**:

1. **Given** the slice's sign slot and billboard slot tables in content data, **When** validated by unit tests and rendered in the slice, **Then** every sign slot resolves to a shared sign/facade atlas region with an invented proper-noun shop name (compliant with Principle IV), and changing a sign or billboard requires only a data change.
2. **Given** any billboard slot definition in the slice, **When** inspected in unit tests, **Then** it includes `id`, `position` (and orientation), `imageAsset`, and `sponsored = false`, with zero real-world brands or ad imitations.
3. **Given** the configured cap on unique billboard textures in `src/shared/Config.luau`, **When** all billboard slots in the slice are resolved, **Then** the number of distinct billboard texture assets is at or below the cap, and draw calls are recorded in the Studio benchmark.

---

### Edge Cases

- **12 Simultaneous Starters on Open Ground**: If 12 players spawn at once in the park start, their spawn positions and nearby Tier 1 food clusters (trails, picnic spreads, flower beds) must be spaced so no player spawns wedged against static geometry or another ball, and every starter can absorb their first object within 5 seconds.
- **Heap Transition from Small Clutter to Large Landmarks**: When a ball absorbs hundreds of Tier 1–2 items followed by a Tier 4 bus, the heap must bury the oldest tiny items without sudden visual popping, scale mid-tier items appropriately, and keep the bus clearly protruding on the outer shell while staying within the per-ball part/triangle budget.
- **Oversized Object Contact Spam**: If a player repeatedly rubs against a building or parked car that is too large to absorb, the physical bump and sound feedback must respect a short cooldown so audio and camera/physics responses remain crisp rather than chattering every frame.
- **Swapping `004h` Assets Mid-Flight**: Because `004i` starts with the 5 bake-off props from `009` plus existing `dt_*` meshes and swaps in rebuilt `004h` meshes as they land, missing or not-yet-rebuilt meshes must seamlessly use their existing `dt_*` mesh and footprint size without breaking street rules or scene kits.
- **Studio Background Throttling During Captures or Benchmarks**: In accordance with `AGENTS.md` and Constitution Gate 6, if Studio throttles to 15 fps in the background or live viewport captures time out, throttled seconds are reported separately from unthrottled seconds, the owner is asked at most once to keep Studio in front if needed, and the offline Blender fallback renderer guarantees the five fixed camera shots are always produced on disk.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Vertical Slice World & First-Minute Layout

- **FR-001**: The system MUST provide a self-contained vertical slice world (`city` theme, approximately 200 × 500 studs; exact dimensions locked in the implementation plan) under `src/shared/Content/Worlds/` that loads when enabled by a dedicated flag/setting in `src/shared/Config.luau`, leaving `Downtown` as the default world when the flag is off.
- **FR-002**: The vertical slice layout MUST progress along a clear spatial sequence:
  1. An **open park start** on flat, unobstructed ground with immediate Tier 1 food and zero enclosing walls or gates blocking the ball;
  2. A **corner of suburb** transitioning from park paths to residential kerbs, yards, and driveways;
  3. One **main street** enclosed by continuous building fronts with awnings and shop signs on both sides;
  4. The **skyline** visible ahead down the main street from the start of the run so the end-of-run goal is in sight.
- **FR-003**: The open park start MUST provide 12 distinct player spawn points spaced so 12 simultaneous starters do not block one another, each with immediate absorbable Tier 1 objects within a 5-second roll and clear sightlines toward the main street and skyline.
- **FR-004**: The slice MUST initially populate using the 5 upgraded bake-off props from `009-style-bible-bakeoff` (`hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`) alongside existing `dt_*` city meshes, structured so newly rebuilt meshes from `004h` swap in via data updates without requiring changes to placement rules or game code.

#### Part B: Deterministic Street Rules, Scene Kits & Natural Bulk

- **FR-005**: Pure, deterministic street placement functions MUST be implemented under `src/shared/Rules/` (using no Roblox APIs, `math.random`, or clock reads per Constitution Principle III) and driven by world content data to generate:
  - Kerbs and raised sidewalks along road edges;
  - Road surface markings (centre/lane lines) and pedestrian zebra crossings at junctions;
  - Street lamps and street trees at fixed intervals along the kerb (offset so lamps and trees never collide);
  - Bins placed at street corners, benches oriented to face the road or path, and vehicles parked parallel to the kerb along their lane direction;
  - Optional small, seeded position/yaw jitter only where real-world objects naturally vary, replacing random full-circle yaw scatter as the default.
- **FR-006**: The placement system MUST support **scene kits**—named, reusable composite templates in content data consisting of a list of objects with relative positions, rotations, and optional jitter rules, placed in the world as a single data entry—and MUST include at least the 10 starter scene kits:
  1. `picnic_spread`
  2. `cafe_terrace`
  3. `bus_stop`
  4. `fruit_stall`
  5. `bike_rack`
  6. `road_works`
  7. `car_park_rows`
  8. `yard_sale`
  9. `flower_bed`
  10. `recycling_point`
- **FR-007**: World population in the slice MUST use **natural bulk** groupings (such as parked cars in rows, stacked/grouped crates of fruit, lines of traffic cones, and trails of small food leading the eye along kerbs, park paths, and shop fronts) rather than mixed random piles, while preserving object pooling, server-authoritative absorb validation, and seeded determinism.
- **FR-008**: The street placement rules and scene kit data format MUST be documented in a clear specification/contract in the feature directory (or `docs/design/`) so `004j` can apply them directly to the full Downtown map.

#### Part C: Signs & Billboards (Data-Driven Placeholders)

- **FR-009**: The slice MUST define data tables for **sign slots** (on shop fronts/facades) and **billboard slots** in world/content data so that changing any shop name or billboard image requires only a data change (Constitution Principle VII).
- **FR-010**: Every shop-front sign MUST use an invented proper-noun shop name or short Minimal-safe signage (Constitution Principle IV, needing no localisation key for proper-noun shop names) mapped onto a single shared building-front/sign atlas (Constitution Principle XI).
- **FR-011**: Every billboard slot entry MUST include `id`, `position` (and orientation), `imageAsset`, and `sponsored: boolean` (set to `false` for every slot in this feature, with no real brands and nothing sold). The number of unique billboard texture assets used across the scene MUST be bounded by a cap defined in `src/shared/Config.luau`.

#### Part D: Player Ball Heap Redesign

- **FR-012**: The player ball visual representation MUST be redesigned from a bare sphere with sparse attachments into a dense, lumpy heap of absorbed objects:
  - By approximately `D = 5`, the base sphere MUST be mostly hidden (either recoloured/textured to match its absorbed contents or covered by a cheap inner filler layer plus outer stuck objects);
  - Pure heap selection rules in `src/shared/Rules/` MUST keep the **biggest and newest** absorbed objects on the outer layer of the heap so signature catches (e.g., a bus or car sticking out of the heap) are prominently displayed;
  - Older, smaller objects MUST be buried or consolidated into the inner heap without visible popping;
  - Stuck objects MUST scale sensibly relative to the ball's current diameter so a heap of small pickups continues to read as a substantial, bumpy heap as the ball grows.
- **FR-013**: During planning and implementation, candidate approaches for building and rendering the heap across 12 simultaneous balls (including optional simplified/cheaper rendering for other players' balls) MUST be compared and measured for active part count, triangle count, draw calls, and frame rate, rather than simply increasing `Config.maxVisibleStuck`.

#### Part E: Visual Size Readability & HUD Simplification

- **FR-014**: When playing the vertical slice, the HUD MUST omit the `Next: <CATEGORY>` line, the star-target text row, and the `YOU CAN ROLL UP: ...` tier banner, displaying only the run timer and the ball size readout during active play (restoring any omitted element only if requested by the owner after playing).
- **FR-015**: Contact with an unabsorbable (too-large) world object MUST immediately communicate the size rule through a clear physical bump impulse and impact sound (with an appropriate cooldown to prevent frame-by-frame chatter) and MUST NOT display any explanatory text message.
- **FR-016**: Visual readability of what the ball can absorb at its current size (`Config.absorbRatio`, camera framing, and object visual scale) MUST be tested in play; if playtesting shows that edibility is not immediately obvious by eye, the implementation MAY adjust ball camera framing, object sizes, `absorbRatio`, or add a subtle non-text visual cue (such as a slight wobble on nearby edible objects), but MUST NOT put outlines on all objects by default.

#### Part F: Testing, Performance & Visual Gate (Gate 6)

- **FR-017**: Automated Lune unit tests in `tests/unit/` MUST verify:
  - Street placement rules at fixed inputs (kerbs, sidewalks, markings, crossings, spaced lamps/trees, corner bins, road-facing benches, parallel-parked vehicles);
  - Scene kits expanding within slice bounds and referencing only known `Objects` catalogue IDs;
  - Sign slots and billboard slots resolving to valid assets in `src/shared/Assets.luau`, with `sponsored == false` and unique billboard textures within the `Config` cap;
  - Pure ball-heap selection, scaling, and burial rules prioritizing biggest and newest objects;
  - Full placement determinism across repeated runs with the same seed.
- **FR-018**: A Studio playtest and benchmark on the vertical slice with 12 active balls MUST verify zero new console errors or warnings (Quality Gate 2) and at least `30 fps` on unthrottled seconds while recording active parts, scene triangles, and draw calls in `specs/010-main-street-slice/playtest.md`.
- **FR-019**: In accordance with Constitution Quality Gate 6, the five fixed camera shots (`01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`) of the vertical slice (including the redesigned ball heap) MUST be captured and saved under `specs/010-main-street-slice/captures/`, and the feature MUST NOT be merged until the owner has reviewed the shots, played the slice, and approved the look, the ball heap, and visual size readability.

### Key Entities

- **Vertical Slice World (`MainStreetSlice` / `Slice`)**: A ~200 × 500 stud `WorldDef` in `city` theme containing the open park start (with 12 non-blocking spawns), suburban corner, continuous main street with facades on both sides, and visible skyline ahead, gated behind a `Config` flag.
- **Street Rule Specification**: Declarative street segments and junctions in world data expanded by pure functions in `src/shared/Rules/` into kerbs, sidewalks, road markings, crossings, evenly spaced trees and lamps, corner bins, road-facing benches, and parallel-parked cars.
- **Scene Kit (`SceneKit`)**: A named, reusable group of relative object placements (`objectId`, local offset `dx, dy, dz`, local `yaw`, optional seeded jitter) placed as a single world entry (covering the 10 starter kits: picnic spread, cafe terrace, bus stop, fruit stall, bike rack, road works, car park rows, yard sale, flower bed, recycling point).
- **Sign Slot & Billboard Slot (`SignSlot`, `BillboardSlot`)**: Data-driven placement records for shop-front signage (sharing the facade/sign atlas) and billboards (`id`, `position`, `yaw`, `imageAsset`, `sponsored: boolean`), bounded by a `Config` billboard texture cap.
- **Ball Heap State (`HeapState` / `HeapLayer`)**: The pure selection and visual layering model for a player's ball that tracks absorbed objects, keeps the largest and newest items protruding on the exterior shell, buries older tiny items into an inner filler/coloured core without popping, and scales attached meshes so the ball reads as a lumpy heap from `D = 5` upward.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 12 spawn points in the open park start allow a new player to absorb their first object within `5 seconds` with zero enclosing walls or gates blocking movement and a direct sightline down the main street to the skyline.
- **SC-002**: 100% of placed objects in the slice are generated via deterministic street rules, the 10+ named scene kits, or natural bulk/trail placements, verified by Lune unit tests asserting fixed expected coordinates, orientations, bounds, and valid object IDs.
- **SC-003**: By `D = 5`, at least 60% of the player ball's base sphere surface is hidden or replaced by the heap filler/absorbed objects, and at `D >= 12` the outer layer displays the largest and newest absorbed objects (including protruding oversized catches like buses/vehicles) as verified in the fixed camera shots and unit tests.
- **SC-004**: In a 60-second Studio playtest with 12 active balls on the vertical slice, the game maintains `>= 30 fps` across unthrottled seconds, stays under `< 2,000` active parts and within the measured scene triangle ceiling and billboard texture cap, and produces `0` new console errors or warnings.
- **SC-005**: `scripts/check.sh` (format, lint, strict typecheck, and all Lune unit tests) exits `0`.
- **SC-006**: The five fixed shots of the slice and redesigned ball are committed in `specs/010-main-street-slice/captures/`, and the owner approves the slice visuals, the ball heap appearance, and visual size readability without HUD text prompts (Constitution Gate 6) before the pull request is merged.

## Scope & Boundaries

### In Scope

- Building the ~200 × 500 stud `city` vertical slice world (open park start with 12 spawns, suburban corner, main street with continuous building fronts on both sides, skyline visible ahead) behind a `Config` flag so `Downtown` stays the default.
- Implementing pure, Lune-tested street placement rules (`src/shared/Rules/`), the 10 starter scene kits, and natural bulk/food-trail layouts, and documenting the placement rules and scene kit format for `004j`.
- Populating the slice initially with the `009` bake-off props and existing `dt_*` meshes, ready to swap in `004h` meshes via data as they land.
- Implementing data-driven shop-front sign slots (on a shared sign/facade atlas) and capped placeholder billboard slots (with `id`, `position`, `imageAsset`, and `sponsored = false`).
- Redesigning the player ball into a lumpy heap of absorbed objects (prioritizing biggest and newest catches on the outside, burying old small items smoothly, hiding the base sphere by ~`D = 5`, and benchmarking 12 balls in Studio).
- Removing the `Next: SIDEWALK STUFF` line, star-target text row, and `YOU CAN ROLL UP` banner from the slice HUD, ensuring clear physical bump + sound feedback when hitting oversized objects, and tuning visual size readability if needed.
- Capturing the five fixed shots (`004g`/`009` camera route) of the slice and running the owner visual/play review loop (Quality Gate 6), noting what the owner's runs feel like without tuning pace to a rigid mathematical model.

### Out of Scope

- Rebuilding the full 880 × 880 Downtown map (`004j`).
- Authoring the full 99-prop city asset library (`004h`, which runs in parallel and whose meshes swap into this slice via data).
- The visible avatar pusher behind the ball (`010` in the backlog, to be tried on the slice afterwards).
- Juice, wobble/settling animations on stuck objects, and hype pop-ups (`004c`).
- Selling or enabling any paid/sponsored billboard placements (`sponsored` remains `false` everywhere, and no real brands appear).
- Tuning slice run pace to a rigid automated pacing model (feel notes from the owner's runs are recorded instead).

## Assumptions

- **Feature Numbering**: In the repository's sequential Spec Kit numbering, this feature is `010-main-street-slice` (corresponding to backlog item `004i`, following `009-style-bible-bakeoff` which corresponded to `004g`).
- **Config World Selection Flag**: The slice is gated behind a boolean flag in `src/shared/Config.luau` (e.g., `Config.Flags.MainStreetSlice = false` by default, or enabled during slice testing/captures) so existing `Downtown` tests and default server boot behaviour remain untouched until `004j`.
- **HUD Simplification Scope**: Removing the `Next:` line, star-target text row, and `YOU CAN ROLL UP` banner applies when running the vertical slice (or behind a slice/readability flag) so existing unit/Studio tests for legacy worlds are not broken unless updated intentionally.
- **Billboard Texture Cap**: The implementation plan (`plan.md`) will state the exact numeric cap for unique billboard textures in `src/shared/Config.luau` (e.g., 4–8 unique placeholder textures) and verify its draw-call impact in the Studio benchmark.
- **Ball Heap Wobble Deferred to `004c`**: As specified in the prompt, dynamic wobble and settling animations for newly attached heap objects remain in `004c`; this feature focuses on the heap's geometry, layering, scaling, burial, base-sphere concealment, and 12-ball frame rate.
