# Tasks: Mechanics Pass — Scaled Jump, Boosters, and Season-Neutral Traps

**Input**: Design documents from `/specs/006-jump-boosters-traps/` (`plan.md`, `spec.md`, `data-model.md`, `contracts/`, `research.md`, `quickstart.md`)  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `contracts/`, `research.md`, `quickstart.md`  
**Tests**: Includes both Lune unit tests (`tests/unit/`) and Jest-Lua Studio integration tests (`tests/studio/`) as specified in `spec.md` (FR-010, FR-011, SC-002).  
**Organization**: Tasks are grouped by user story (US1, US2, US3, US4) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- **🔒**: Studio verification check executed by the agent via Roblox Studio MCP

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify repository toolchain, Rojo server connection, and baseline test suite.

- [X] T001 Verify toolchain, Rojo serve status, and baseline test suite by running `scripts/check.sh`
- [X] T002 Verify Studio MCP connection and sync probe via `scripts/studio-sync-probe.sh` and `scripts/studio-preflight.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core constants, tuning parameters, feature flags, content definitions, localization strings, and shared types that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Add 13 feature flags (`ScaledJump`, `Boosters`, `BoosterDash`, `BoosterMagnet`, `BoosterSpring`, `BoosterShield`, `BoosterSlickTrail`, `Traps`, `TrapSlick`, `TrapBumper`, `TrapSlow`, `TrapSweeper`, `BallToBallBumps`) and all tuning keys (Jump, Vertical guard, Speed, Claiming, Durations, Magnet, Spring, Slick trail, Traps, Ball bumps) to `src/shared/Config.luau`
- [X] T004 [P] Verify configuration schema, tuning constraints (`jumpClearRatio < jumpHoldClearRatio`, `minJumpClearHeight > 1.5`, `boostSpeedCap > maxServerBallSpeed`, `slickTrailMaxPatches <= slickTrailPoolSize`), and all 13 flags in `tests/unit/Config.test.luau`
- [X] T005 [P] Register stock landing audio path `sounds.land = "rbxasset://sounds/action_get_up.mp3"` in `src/shared/Assets.luau`
- [X] T006 [P] Add English and Spanish localization strings for booster names, trap names, and HUD effect chips in `src/shared/Localization/Strings.luau`
- [X] T007 [P] Verify all new localization keys have non-empty `en` and `es` translations and no restricted monetization terms in `tests/unit/Strings.test.luau`
- [X] T008 [P] Define `BoosterDef` and `TrapDef` catalog with winter and city theme dressing and footprints in `src/shared/Content/Hazards.luau`
- [X] T009 [P] Add placeholder icon glyphs (`dash`, `magnet`, `spring`, `shield`, `slick`, `slow`, `bumper`, `sweeper`) to `src/shared/Content/Icons.luau`
- [X] T010 [P] Update `MarkerDef` type to structured schema (`id: string, kind: string, subKind: string, x: number, y: number, z: number, yaw: number, waypoints: { { x: number, z: number } }?`) in `src/shared/Content/GreyBoxRoom.luau`

**Checkpoint**: Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 - Variable Diameter-Scaled Jump That Clears Unabsorbable Obstacles at Every Tier (Priority: P1) 🎯 MVP

**Goal**: Deliver a variable diameter-scaled jump where pressing hops immediately to `0.6 × D` (minimum `1.6` studs) and holding up to `0.25 s` stretches apex to `0.85 × D`, with anti-flight cooldown and server vertical guard enforcement.

**Independent Test**: Lune unit tests verify clearance and velocity formulas across diameters `2, 5, 12, 30, 70`; Studio tests verify vertical anti-cheat accepts legitimate jumps and resets vertical teleports/re-jumps; Studio playtest verifies clearing unabsorbable obstacles at Tiers 1–5 with landing squash and thump.

### Tests for User Story 1

- [X] T011 [P] [US1] Unit test diameter-scaled tap and held jump physics (`tapApex = max(0.6·D, 1.6)`, `holdApex = max(0.85·D, 2.267)`, `takeoffSpeed = sqrt(2·g·tapApex)`, `q <= g`) at diameters `2, 5, 12, 30, 70` against fixed hand-computed values in `tests/unit/Jump.test.luau`
- [X] T012 [P] [US1] Unit test `BallGuard.speedCeiling` and `BallGuard.verticalVerdict` (`E = y + vy²/2g <= airRefEnergy + apexAllowance`) verifying tap/held jump acceptance, slope climbing, and mid-air re-jump rejection in `tests/unit/BallGuard.test.luau`
- [X] T013 [P] [US1] Studio integration test verifying server vertical movement guard accepts valid tap/held jumps and resets mid-air re-jumps and vertical teleports in `tests/studio/BallService.spec.luau`

### Implementation for User Story 1

- [X] T014 [P] [US1] Implement pure jump rules (`tapApex`, `holdApex`, `takeoffSpeed`, `holdGravity`, `upLimit`, `apexAllowance`, `canTakeOff`) in `src/shared/Rules/Jump.luau`
- [X] T015 [US1] Implement `speedCeiling` and `verticalVerdict` in `src/shared/Rules/BallGuard.luau`
- [X] T016 [US1] Extend session state with `airRefEnergy` and integrate vertical velocity clamping and position reset into `src/server/BallService.luau`
- [X] T017 [P] [US1] Refactor `JumpButton` to emit `Pressed` and `Released` BindableEvents instead of `Activated` (preserving `>= 96 px` touch target) in `src/client/JumpButton.luau`
- [X] T018 [US1] Implement variable jump takeoff on press, hold-extension acceleration (`g - holdGravity`) up to `0.25 s`, and ground raycast checks in `src/client/BallController.luau`
- [X] T019 [P] [US1] Implement `land` thump sound playback and landing squash tween (`landingSquashScale = 0.8`, suppressed when `Reduce motion` is on) in `src/client/Feedback.luau`
- [X] T020 [US1] 🔒 Studio playtest verifying Tier 1 kerb clearance at `D = 2`, `0.6 × D` tap clearance, `0.85 × D` held clearance at Tiers 1–5, landing feedback, and zero server violations

**Checkpoint**: User Story 1 is fully functional and independently testable (MVP complete).

---

## Phase 4: User Story 2 - World Boosters with Server-Authoritative Claiming and Active HUD Cues (Priority: P1)

**Goal**: Deliver 5 world boosters (`dash`, `magnet`, `spring`, `shield`, `slick_trail`) with server-authoritative claiming via `ClaimBooster`, temporary attribute replication, magnet part drift, auto-laying slick-trail pooling, and HUD effect chips.

**Independent Test**: Lune unit tests verify booster durations, magnet eligibility, and trail drop rules; Jest-Lua Studio tests verify `ClaimBooster` validation codes (`BadArgs`, `NotActive`, `Disabled`, `RateLimited`, `UnknownMarker`, `Unavailable`, `OutOfRange`), Dash speed cap, and trail pool cap; Studio playtest exercises all 5 boosters on Snow Village.

### Tests for User Story 2

- [X] T021 [P] [US2] Unit test booster enabled checks, durations, magnet candidate filtering (`size <= 0.4·D`, cap `24`), slick-trail drop spacing, and dash target speed in `tests/unit/Boosters.test.luau`
- [X] T022 [P] [US2] Studio integration test for `BoosterService.tryClaim` result codes, rate limiting, respawn cooldown, Shield consumption, and trail pool size in `tests/studio/BoosterService.spec.luau`
- [X] T023 [P] [US2] Studio integration test verifying `Remotes.ClaimBooster` exists (13 total remotes) and rejects non-string, missing, or extra arguments in `tests/studio/Remotes.spec.luau`

### Implementation for User Story 2

- [X] T024 [P] [US2] Implement pure booster rules (`enabled`, `endsAt`, `isActive`, `magnetPick`, `shouldDrop`, `trailExpire`, `dashTarget`) in `src/shared/Rules/Boosters.luau`
- [X] T025 [US2] Register `ClaimBooster` RemoteEvent (13 total events) in `src/server/Remotes.luau`
- [X] T026 [P] [US2] Implement `WorldSpawner.restoreHome(id: string)` for returning magnet-drifted parts to `spawnCFrame` in `src/server/WorldSpawner.luau`
- [X] T027 [US2] Implement `BoosterService` managing claim validation, active session timers, 10 Hz magnet part drift, spring launch publishing, and slick-trail pooling (cap 48) in `src/server/BoosterService.luau`
- [X] T028 [US2] Integrate session booster cleanup on run end, reset, and fall respawn in `src/server/RunManager.luau`
- [X] T029 [US2] Initialize and start `BoosterService` in `src/server/Main.server.luau`
- [X] T030 [US2] Update `BallController` to handle `BoostDash` target speed and apply server-published `Launch` attribute velocity in `src/client/BallController.luau`
- [X] T031 [P] [US2] Implement `EffectChips` component rendering active booster chips (`dash`, `magnet`, `shield`, `slick_trail`) with icon and localized text `>= 18 px` in `src/client/EffectChips.luau`
- [X] T032 [US2] Mount `EffectChips` inside HUD container in `src/client/Hud.luau`
- [X] T033 [US2] 🔒 Studio playtest verifying Dash speed boost, Magnet object pull, Spring launch to rooftop, Shield bump protection, auto-laid Slick Trail, and HUD chips

**Checkpoint**: User Stories 1 and 2 are both fully functional and testable independently.

---

## Phase 5: User Story 3 - Season-Neutral Traps, Roaming Street Sweeper, and Ball-to-Ball Bumps (Priority: P1)

**Goal**: Deliver 4 season-neutral traps (`slick`, `bumper`, `slow`, `sweeper`) and ball-to-ball bump knock-offs scattering up to 3 objects with 3-second victim immunity, Shield protection, shared re-collection, and HUD status chips.

**Independent Test**: Lune unit tests verify trap multipliers, linger timers, knock-off decision matrix (`Knock`, `ShieldAbsorbed`, `Immune`, `Cooldown`, `NothingStuck`), and patrol loop kinematics; Jest-Lua Studio tests verify bumper/sweeper/ball bump knock-offs and 3 s immunity; Studio playtest verifies traps and bumps in both winter and city dressings.

### Tests for User Story 3

- [X] T034 [P] [US3] Unit test trap enabled checks, speed multiplier (`0.5`), turn multiplier (`0.25`), surface linger, and rotated rectangle containment in `tests/unit/Traps.test.luau`
- [X] T035 [P] [US3] Unit test knock-off decision precedence (`Immune` -> `Cooldown` -> `ShieldAbsorbed` -> `NothingStuck` -> `Knock`), closing speed calculation, and `ballBump` ratio/threshold rules in `tests/unit/Knock.test.luau`
- [X] T036 [P] [US3] Unit test closed-loop waypoint path length, position, and heading interpolation in `tests/unit/Patrol.test.luau`
- [X] T037 [P] [US3] Studio integration test verifying bumper/sweeper knock-offs, Shield absorption, ball-to-ball bump 3 s immunity window, and shared re-collection after `scatterGrace` in `tests/studio/HazardService.spec.luau`

### Implementation for User Story 3

- [X] T038 [P] [US3] Implement pure trap rules (`enabled`, `speedMultiplier`, `turnMultiplier`, `surfaceActive`, `insideRect`) in `src/shared/Rules/Traps.luau`
- [X] T039 [P] [US3] Implement pure knock-off decision rules (`decide`, `ballBump`, `closingSpeed`) in `src/shared/Rules/Knock.luau`
- [X] T040 [P] [US3] Implement pure patrol loop kinematics (`length`, `position`) in `src/shared/Rules/Patrol.luau`
- [X] T041 [US3] Implement shared knock-off executor `KnockOff.apply` handling object scattering, ball shrinking (never below `startDiameter`), camera shake, and run notification in `src/server/KnockOff.luau`
- [X] T042 [US3] Refactor obstacle collision handling in `AbsorbService.tryBump` to delegate to `KnockOff.apply` in `src/server/AbsorbService.luau`
- [X] T043 [US3] Implement `HazardService` detecting bumper post, street sweeper, and ball-to-ball bump contacts and publishing bounce `Launch` in `src/server/HazardService.luau`
- [X] T044 [US3] Initialize and start `HazardService` in `src/server/Main.server.luau`
- [X] T045 [P] [US3] Implement deterministic RenderStepped sweeper movement along waypoints using server time and patrol epoch in `src/client/HazardClient.luau`
- [X] T046 [US3] Start `HazardClient` on client initialization in `src/client/Main.client.luau`
- [X] T047 [US3] Update `BallController` to detect `TrapSurface` patches and apply slick turn multiplier and slow speed multiplier with linger in `src/client/BallController.luau`
- [X] T048 [US3] Extend `EffectChips` with surface hazard status chips (`Slippery!`, `Slowed`) in `src/client/EffectChips.luau`
- [X] T049 [US3] 🔒 Studio playtest verifying Slick/Slow surface patches, Bumper Post bounce, Sweeper patrol/bounce, and ball-to-ball bumps with 3 s victim immunity

**Checkpoint**: User Stories 1, 2, and 3 are all independently functional.

---

## Phase 6: User Story 4 - Validated Booster & Trap Marker Spots in World Data (Priority: P2)

**Goal**: Author structured `MarkerDef` entries for 8 BoosterSpots and 8 TrapSpots covering all 9 sub-kinds on Snow Village, enforce Lune content validation and keep-out protection, and build visual/physical instances from markers.

**Independent Test**: Lune unit tests (`Markers.test.luau`, `SnowVillage.test.luau`) verify marker schema, bounds, obstacle keep-outs, and spring pad trajectories; Studio playtest verifies all 16 spots spawn correctly and switch cleanly between winter and city themes.

### Tests for User Story 4

- [X] T050 [P] [US4] Unit test marker validation rules (ID uniqueness, valid kind/subKind, bounds check, waypoint constraints, keep-out coverage, all 9 sub-kinds present) in `tests/unit/Markers.test.luau`
- [X] T051 [P] [US4] Unit test Snow Village markers asserting `>= 6` BoosterSpots, `>= 6` TrapSpots, all 9 sub-kinds, keep-outs, part budget `< 2000`, and spring pad roof trajectory in `tests/unit/SnowVillage.test.luau`

### Implementation for User Story 4

- [X] T052 [P] [US4] Implement pure marker validation rule `Markers.validate` in `src/shared/Rules/Markers.luau`
- [X] T053 [US4] Re-author 8 `BoosterSpot` and 8 `TrapSpot` markers with exact coordinates, spring pads at `(0, ∓126)` facing roofs, sweeper loop waypoints, and matching keep-outs in `src/shared/Content/Worlds/SnowVillage.luau`
- [X] T054 [US4] Implement booster and trap instance creation from world markers using theme palette dressing roles in `src/server/WorldBuilder.luau`
- [X] T055 [US4] 🔒 Studio playtest verifying world builds with all 16 markers spawned, spring pad reaches Y = 11 rooftop, and dressing switches between winter and city themes without code changes

**Checkpoint**: All user stories (US1–US4) are independently functional and verified in world data.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cross-cutting verification, feature flag independence, mobile performance validation, and playtest sign-off documentation.

- [X] T056 [P] Verify individual flag toggles in `Config.Flags` cleanly disable each booster, trap, jump scaling, and ball bumps in `tests/unit/Config.test.luau`
- [X] T057 [P] Verify 640 × 360 mobile HUD layout, minimum 96 px touch targets, text `>= 18 px`, and icon rendering across both FredokaOne and GothamMedium in `tests/unit/Layout.test.luau`
- [X] T058 Run full repository static validation suite (`scripts/check.sh`) ensuring exit 0 for StyLua, Selene, luau-lsp, and all Lune unit tests
- [X] T059 🔒 Execute Jest-Lua integration test suite via `tests/studio/runner` in Studio and verify all specs pass
- [ ] T060 🔒 Execute 640 × 360 Studio playtest capture, measure unthrottled FPS `>= 30`, and document results and sign-off in `specs/006-jump-boosters-traps/playtest.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — executes first.
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Phase 2 — unlocks core variable jump mechanics.
- **User Story 2 (Phase 4)**: Depends on Phase 2; integrates with US1 jump/vertical guard.
- **User Story 3 (Phase 5)**: Depends on Phase 2; integrates with US2 Shield booster and shared KnockOff.
- **User Story 4 (Phase 6)**: Depends on Phase 2 and Content definitions; places and spawns US2/US3 mechanics on Snow Village.
- **Polish (Phase 7)**: Depends on Phases 3–6 being complete.

### User Story Dependencies

- **US1 (Jump)**: Completely independent of US2, US3, and US4.
- **US2 (Boosters)**: Can be developed in parallel with US1 once Phase 2 is complete. Uses vertical guard envelope from US1 for spring launches.
- **US3 (Traps & Bumps)**: Can be developed in parallel with US1/US2 once Phase 2 is complete. Uses Shield state defined in Phase 2 / US2.
- **US4 (World Markers)**: Authors marker data and WorldBuilder spawning for US2 boosters and US3 traps.

### Parallel Opportunities

- **Phase 2 (Foundational)**: T004, T005, T006, T007, T008, T009, T010 can all run in parallel after T003.
- **Phase 3 (US1)**: Tests T011, T012, T013 run in parallel; rules T014, UI T017, and feedback T019 run in parallel.
- **Phase 4 (US2)**: Tests T021, T022, T023 run in parallel; rules T024, spawner T026, and UI T031 run in parallel.
- **Phase 5 (US3)**: Tests T034, T035, T036, T037 run in parallel; rules T038, T039, T040 and client T045 run in parallel.
- **Phase 6 (US4)**: Tests T050, T051 run in parallel; rule T052 runs in parallel with data authoring T053.
- **Phase 7 (Polish)**: T056 and T057 run in parallel.

---

## Parallel Example: User Story 1

```bash
# Launch test creation for User Story 1 in parallel:
Task: "T011 [P] [US1] Unit test diameter-scaled tap and held jump physics in tests/unit/Jump.test.luau"
Task: "T012 [P] [US1] Unit test BallGuard.speedCeiling and BallGuard.verticalVerdict in tests/unit/BallGuard.test.luau"
Task: "T013 [P] [US1] Studio integration test for server vertical movement guard in tests/studio/BallService.spec.luau"

# Launch decoupled implementation components in parallel:
Task: "T014 [P] [US1] Implement pure jump rules in src/shared/Rules/Jump.luau"
Task: "T017 [P] [US1] Refactor JumpButton to emit Pressed/Released in src/client/JumpButton.luau"
Task: "T019 [P] [US1] Implement land thump sound and squash tween in src/client/Feedback.luau"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`scripts/check.sh`, Studio sync probe).
2. Complete Phase 2: Foundational (`Config.luau`, flags, `Assets.luau`, `Strings.luau`, `Icons.luau`, `Hazards.luau`, `GreyBoxRoom.luau`).
3. Complete Phase 3: User Story 1 (Variable diameter-scaled jump, anti-flight cooldown, server vertical guard, landing feedback).
4. **STOP and VALIDATE**: Verify Tiers 1–5 obstacle clearing in Studio. Deploy/demo as MVP.

### Incremental Delivery

1. Setup + Foundational -> Shared baseline ready.
2. User Story 1 -> Variable jump clears obstacles across all tiers (MVP!).
3. User Story 2 -> World boosters (`dash`, `magnet`, `spring`, `shield`, `slick_trail`) and HUD chips.
4. User Story 3 -> Season-neutral traps (`slick`, `bumper`, `slow`, `sweeper`) and cartoon ball-to-ball bumps.
5. User Story 4 -> Snow Village markers re-authored, validated, and spawned in world data with winter/city theme switching.
6. Polish -> Flags verified, mobile constraints validated, Studio runner green, owner playtest signed off.
