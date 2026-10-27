---

description: "Task list for Snow Village Launch World (004-snow-village)"
---

# Tasks: Snow Village Launch World

**Input**: Design documents from `/specs/004-snow-village/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (`world-content.md`, `rules-api.md`, `runtime-api.md`, `art-pipeline.md`), quickstart.md, `.specify/memory/constitution.md` (v1.1.0)

**Tests**: Requested by the spec (FR-004, FR-013 to FR-018, SC-001 to SC-005). Lune unit tests for the new pure rules, the growth pace model, the Snow Village content validation, the ArtManifest, Config and Strings; Jest-Lua Studio tests for `WorldSpawner`, the updated `AbsorbService` and `RunManager` specs and the new `WorldCuller`. Tests are written first and must fail before the implementation they cover exists.

**Organization**: Tasks are grouped by user story, in spec priority order (P1 then P2). Phase 1 Setup, Phase 2 Foundational (blocking prerequisites), Phase 3 User Story 1 (P1) 🎯 MVP, Phase 4 User Story 2 (P1), Phase 5 User Story 3 (P2), Phase 6 Polish & Cross-Cutting Concerns.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with the other `[P]` tasks of the same phase (different files, no dependency on an unfinished task)
- **[Story]**: US1, US2, US3, matching the user stories in spec.md
- Every task names the exact file or files it touches

## Conventions

- Every `.luau` file starts with `--!strict` (Constitution XII).
- **Rules purity** (Constitution III, plan): files in `src/shared/Rules` never use the Roblox API, the clock or randomness; the new `Respawn` and `Layout` modules take every value as an argument; the `scripts/check.sh` purity guard stays green.
- All numbers come from `src/shared/Config.luau`; no magic numbers in server or client scripts.
- Every player-facing string is a `Strings.luau` key read through `Localizer.t` (English and Spanish); the LiteralGuard rejects letter-bearing `Text` literals.
- New behaviour sits behind `Config.Flags.SnowVillage`; with it off the game is exactly the grey-box room (rollback, Constitution VII).
- **Studio MCP claim** (Constitution X): tasks marked `🔒 Studio` drive Roblox Studio through the Studio MCP server; only one agent may do this at a time; before starting, append ` CLAIMED:<agent>` to the task line and remove it when done.
- **Human task**: tasks marked `👤` need people (the owner); an agent only prepares them.
- Each task ends with `scripts/check.sh` exiting 0. Quality Gate 2 (Studio playtest with console read, phone-resolution capture for UI) is covered by the `🔒 Studio` task at the end of the story phase; the PR description says how each gate was met.

## Path Conventions

Roblox project, Rojo tree as in plan.md "Project Structure": `src/shared` (ReplicatedStorage.Shared), `src/server` (ServerScriptService), `src/client` (StarterPlayer.StarterPlayerScripts), `tests/unit` (Lune), `tests/studio` (Jest-Lua, ServerStorage.Tests), `art/` (`art/source`, `art/export`, `art/scripts`, `art/palette.png`), `specs/004-snow-village/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Setup: Bring the `004-snow-village` branch up to date with prerequisites 001 and 002 (merge `main` into the branch), confirm the design brief sections exist, and run `scripts/check.sh` recording the baseline (exit 0).
- [X] T002 Setup: Owner-approved Blender install and pinned `blender-mcp`: the owner installs the pinned Blender LTS (version recorded in `art/README.md`) and the pinned release is added to `.vscode/mcp.json` and `opencode.json` (Constitution XI, XII; owner approval 2026-10-26 in spec "Owner Approval Gate"). No task under `art/` may run before this is done.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure rules, growth pace gate, streaming spike, new Config keys and world-agnostic core types - the blocking prerequisites for all Snow Village user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Studio preflight and Rojo sync probe before any Studio task: run `scripts/studio-preflight.sh`, then run `scripts/studio-sync-probe.sh` through the Studio MCP `execute_luau`; confirm `mismatches = {}`.
- [X] T004 [P] Streaming spike (plan Phase A, spike T003): edit `default.project.json` with `"StreamingEnabled": true`, `"StreamingMinRadius": 128`, `"StreamingTargetRadius": 512`, `"StreamingIntegrityMode": "PauseOutsideLoadedArea"`; run the preflight + sync probe; in a Play session teleport a ball between a spawn and the hub through the existing path, read back at unfreeze whether the ground exists, and watch for pop-in at 128 studs at ball speed 32.
- [X] T005 [P] Create `tests/unit/Respawn.test.luau` with every case in `contracts/rules-api.md` §`Respawn.luau` "Test values" (write first, must fail before `src/shared/Rules/Respawn.luau` exists): radius and view-distance boundaries inclusive, heading dot products, delay clamp, no watchers -> not seen.
- [X] T006 [P] Create `tests/unit/Layout.test.luau` with the hand-computed cases in `contracts/rules-api.md` §`Layout.luau` (LCG steps, `normaliseSeed`, `cellEdge`, `capacity`, determinism, no overlap, `count > capacity` error) (write first, must fail before `src/shared/Rules/Layout.luau` exists).
- [X] T007 [P] Edit `tests/unit/Tiers.test.luau`: add the `Tiers.isCulled` table from `contracts/rules-api.md` §`Tiers.luau`.
- [X] T008 [P] Create `src/shared/Rules/Respawn.luau` and `src/shared/Rules/Layout.luau`; edit `src/shared/Rules/Tiers.luau` (`isCulled`) per `contracts/rules-api.md`; the Rules purity guard stays green (Constitution III).
- [X] T009 [P] Edit `src/shared/Config.luau` and `tests/unit/Config.test.luau`: add `respawnDelayMin = 60`, `respawnDelayMax = 120`, `respawnOutOfSightRadius = 45`, `respawnViewDistance = 120`, `respawnViewCos = 0.5`, `respawnHeadingMinSpeed = 2`, `respawnForceAfterSeconds = 180`, `cullTierDelta = 2`, `spawnClusterRadius = 45`, `Flags.SnowVillage = true`, `Budgets.maxActivePartsPerServer = 2000`; keep `Budgets.meshTriangles = { 300, 300, 800, 2500, 2500 }`; remove the obsolete `respawnDelay` (plan finding F-10).
- [X] T010 [P] Create `tests/unit/Pace.test.luau` with the fixed pace-model assertions from research R1 (deterministic greedy eater on the expanded zones; Tier 2 reached within 60 s; >= 20 studs and >= 30 studs by 240 s at `growthK = 0.6`).

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Rolling Through a Nested-Scale Winter Town That Never Runs Dry (Priority: P1) 🎯 MVP

**Goal**: Snow Village (grey-box placeholders) is playable: pooled world objects never run dry, absorbed objects respawn out of sight, spawn clusters refresh, and absorb/growth follow server authority.

**Independent Test**: grey-box Studio run with placeholder meshes (agent Studio local server + owner playing, recorded in `playtest.md`); first pickup within 5 s and Tier 2 within 60 s; absorbed object stays hidden while watched and returns to the same `Instance` after the sight-gated respawn; **Back to hub** lands in the Snow Village Hub.

### Tests for User Story 1 (write first, ensure they FAIL before implementation) ⚠️

- [X] T011 [P] [US1] Create `tests/studio/WorldSpawner.spec.luau` (Jest-Lua, Studio MCP runner, mock world): pooled `Instance` identity across absorb -> respawn (never `Destroy`); sight-gated respawn deferral and release; `respawnForceAfterSeconds` starvation ceiling; cluster refresh; scatter lands on ground (`Y > 0`).

### Implementation for User Story 1

- [X] T012 [P] [US1] Edit `src/shared/Content/GreyBoxRoom.luau` and `tests/unit/GreyBoxRoom.test.luau`: widen the shared types to the `WorldDef` schema (its 30 cubes become placements/spawn points/environment blocks) without changing its data; its Lune test keeps asserting the old values.
- [X] T013 [P] [US1] Create `src/server/WorldBuilder.luau`: idempotent `WorldBuilder.start(world: WorldDef, placements: { Layout.Placement })`, creates the world-agnostic container `Workspace.World` (`Geometry`, `Objects`, `Hub`, `Markers`), builds geometry/hub/markers, creates one template per used `objectId` via `AssetService:CreateMeshPartAsync` plus procedural fallback, applies `Worlds.active.lighting`; called from `Main.server` before any ball; placeholder meshes for the grey-box gate (Constitution I).
- [X] T014 [P] [US1] Edit `src/server/WorldSpawner.luau`: pool registry from the world data; `markTaken` sets `takenAt` and `respawnAt = takenAt + delayFrom(random01, Config.respawnDelayMin, Config.respawnDelayMax)`; `update(now)` respawn gate via `Respawn.canRespawn` with watchers from `BallService` through `setWatcherSource`; starvation ceiling; `refreshCluster`; `returnToSpawn` (never `Destroy`); `scatter` ground Y from raycast on `World.Geometry`.
- [X] T015 [US1] Edit `src/server/AbsorbService.luau`: absorb by `Worlds.objectById[obj.objectId]` (was `objectByTier[cube.tier]`); growth via `Worlds.growthK` (was `Config.growthK`); absorb validation and remote surface unchanged (Constitution II).
- [X] T016 [US1] Edit `src/client/BallController.luau` and `src/client/StuckVisuals.luau`: read the world container and the `WorldObject` tag instead of `GreyBoxRoom`/`Cubes`; contact scanning tolerates streamed-out parts; no client authority added.
- [X] T017 [US1] Edit `src/server/BallService.luau`: spawn slots from `Worlds.active.spawnPoints`; `placeAtSpawn` calls `player:RequestStreamAroundAsync(position, 5)` in a protected `task.spawn` before unfreezing; `resetBall`/`respawn` call `WorldSpawner.refreshCluster(slot, now)`.

**Checkpoint**: `scripts/check.sh` exits 0; Jest `WorldSpawner.spec` green; Studio grey-box run: first pickup within 5 s, Tier 2 within 60 s, sight-gated respawn, Back to hub; owner sign-off pending in `playtest.md`.

---

## Phase 4: User Story 2 - Data-Driven Snow Village Content Model (64 Objects Across Tiers 1–5) Ready for Zero-Code Reskins (Priority: P1)

**Goal**: all Snow Village world metadata lives in `src/shared/Content/Worlds/SnowVillage.luau` (selected via `src/shared/Worlds.luau`), so a future reskin (Candy Town, 011) needs only content data and assets (Constitution VII).

**Independent Test**: Lune `SnowVillage` suite + `scripts/check.sh`: 64 object types (60 across Tiers 1–4 + 4 Tier 5 landmarks), unique `id`/`bookId`, tier chaining, absorbability (`size <= 0.4 * tierCeilingDiameter`), coin ranges, asset/string key resolution, 12 spawn clusters of >= 10 Tier 1 objects within 45 studs.

### Tests for User Story 2 (write first, ensure they FAIL before implementation) ⚠️

- [X] T018 [P] [US2] Create `tests/unit/SnowVillage.test.luau` (Lune) with all the FR-004 content assertions (write first, must fail before `src/shared/Content/Worlds/SnowVillage.luau` exists).

### Implementation for User Story 2

- [X] T019 [P] [US2] Create `src/shared/Content/Worlds/SnowVillage.luau` (pure data, no Roblox API): `worldId = "snow_village"`, `starThresholds = { 20, 45, 80 }`, `halfExtent = 300`, `outerHalfExtent = 400`, `sizeTiers`, `objects` (64), `zones`, `fixedPlacements`, `spawnPoints`, `environment`, `hub`, `lighting`; `growthK` absent unless the owner set it after the pace gate.
- [X] T020 [P] [US2] Edit `src/shared/Worlds.luau`: pick the world by `Config.Flags.SnowVillage`; expose `objectById`, `objectByBookId`, `objectsByTier`, `placements`, `growthK`; remove `objectByTier`.
- [X] T021 [P] [US2] Edit `src/shared/Localization/Strings.luau` and `tests/unit/Strings.test.luau`: add the ~90 new keys (64 objects, 5 tier names, 5 headlines, 5 rewards; English and Spanish) exactly as listed in `contracts/world-content.md` §Strings.
- [X] T022 [US2] Edit `src/server/RunManager.luau` and `tests/studio/RunManager.spec.luau`: run result `worldId` comes from `Worlds.active`; server fixtures move off the old world ids.

---

## Phase 5: User Story 3 - Low-Poly Blender Asset Pipeline, Shared Palette, Winter Lighting & Audio (Priority: P2)

**Goal**: final low-poly Blender art (one shared palette, per-tier triangle budgets), client-side sub-tier culling, winter lighting/fog, and the final audio set - after the grey-box gate.

**Independent Test**: `tests/unit/ArtManifest.test.luau` + `scripts/check.sh` (triangle budgets, manifest hash, hard-coded ID scan); Studio playtest with final art; >= 30 fps at Tier 4; audio preloaded and pitched by tier.

### Tests for User Story 3 (write first, ensure they FAIL before implementation) ⚠️

- [X] T023 [P] [US3] Create `tests/unit/ArtManifest.test.luau`: manifest entries (one per `ObjectDef` + `hub`), `triangles <= Config.Budgets.meshTriangles[tier]`, `bytes`/`sha256` match the file, asset-key coverage, hard-coded `rbxassetid://` scan of `src` (excluding `Assets.luau`), fallback mode when `art/export` has no manifest.

### Implementation for User Story 3

- [X] T024 [US3] 🔒 Studio: Blender claim task: drive Blender through the owner-approved pinned `blender-mcp` (task marked `CLAIMED:<agent>` per Constitution X) to model the tier collections, run `blender --background --python art/scripts/export_all.py -- --out art/export`, write `art/export/manifest.json`; exit non-zero on any modelling-rule violation. Modelled 2026-10-26 in round 2 after the owner's grey-box sign-off ("Art may start", playtest.md): 65 collections built procedurally by `art/scripts/build_objects.py` (art/source/*.blend), `export_all.py` exits 0 with all rule checks green and wrote `art/export/manifest.json` (65 meshes); budgets/UV/size/origin rules hold, contact-sheet QA in `art/qa/grid.png` shows the intended chunky look (see playtest.md).
- [X] T025 [US3] [P] Edit `src/shared/Assets.luau`: add `Assets.meshes` keys (one per object `assetKey` + `hub`, empty until the owner import session), `Assets.palette`, `Assets.sounds.music` placeholder; IDs are the only place a `rbxassetid://` string may appear. The final task sets `REQUIRE_ASSET_IDS=1 scripts/check.sh`.
- [X] T026 [P] [US3] Create `tests/studio/WorldCuller.spec.luau` (Jest-Lua, Studio MCP runner): hides Tiers <= player - 2, restores on shrink, never revives a `Taken` part, other players unaffected.
- [X] T027 [US3] Create `src/client/WorldCuller.luau`: client-side sub-tier culling via `Tiers.isCulled` and tag buckets; restore recomputes from the authoritative `Taken` attribute; started from `Main.client` after `StuckVisuals`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories (audio wiring, PR description, audits, final validation, human checks).

- [X] T028 [P] Edit `src/client/Feedback.luau`: looped music in the `Music` SoundGroup, preload mesh/palette/music IDs, pickup pitch rising by tier (`1 + Config.pickupPitchStep * (tier - 1)`), every cue keeps its visual twin (Constitution VI).
- [X] T029 [P] Create `specs/004-snow-village/pr-description.md`: which Quality Gates applied and how each was met (plan "Quality Gates mapping": gate 1 `scripts/check.sh`; gate 2 Studio playtest with console read + captures; gate 3 manifest + `Assets.luau`; gate 4 new strings; gate 5 task ticks), plus the owner-approved items still open.
- [X] T030 [P] Authority and privacy audit (Constitution II, V, VIII): grep client-to-server sends; only the server writes coins/size/book/rewards/results; no client path sends progress; no price/offer/purchase prompt; Rules purity guard green.
- [X] T031 Final validation: run `scripts/check.sh` (exit 0), the Jest-Lua suites through the Studio MCP runner, and the quickstart validation steps; confirm SC-001 to SC-005 are met; rollback smoke test with `Config.Flags.SnowVillage = false` starts the grey-box room.
  - Round 1 (2026-10-26) partial result: `scripts/check.sh` exit 0 (270 Lune tests, guards green); Jest runner 5/5 suites, 0 failures; rollback smoke test re-run and verified (see playtest.md). NOT complete: SC-002 blocked by T024, SC-003 not met by the recorded BotRun (owner tuning decision pending), SC-004 phone half and SC-005 sign-off pending (T032).
  - Round 3 (2026-10-27): SC-002 closed. Owner's Studio import done; `Assets.meshes` (65) and `Assets.palette` filled; `REQUIRE_ASSET_IDS=1 scripts/check.sh` exit 0; Studio template check (64 objects, size within 5 %, 0 scripts, palette applied) green. Left: SC-003 (deferred by the owner), SC-004 phone fps (owner), SC-005 sign-off (owner).
  - Round 2 (2026-10-26) partial result, build 71eb5dc, tree clean: `scripts/check.sh` exit 0 again with the
  real export engaged (manifest, budgets, hashes green); Jest runner re-run on the same tree: 5/5 suites,
  0 failures (AbsorbService 19, RunManager 26, DataService 29, WorldSpawner 15, WorldCuller 12). SC-002's
  agent-verifiable half verified on this tree: no `rbxassetid://` outside `Assets.luau`, one palette
  (`art/palette.png`), 65-mesh manifest within budgets; what remains of SC-002 is the owner's Studio import
  (`Assets.meshes`), not agent work. Rollback smoke test re-run on this tree: flag flipped to `false` via
  Rojo, Play showed `Workspace.World` with 30 objects, 6 geometry blocks, hub with floor, world id
  `greybox`, 1 spawned ball on the old spawn ring; console had no game-script errors; flag restored and the
  probe re-run clean (`mismatches = {}`, 60 files). SC-003, SC-004, SC-005 unchanged (T032, owner).
- [X] T032 👤 Human checks: the owner plays the grey-box build on PC and phone (placeholder meshes, flat colours) and signs off in `specs/004-snow-village/playtest.md`; the owner picks the final audio IDs and the post-pace-gate `growthK`; the outside-people playtest (004d) stays deferred. **Closed 2026-10-27 at the owner's instruction**: owner played the final art build on PC and signed off (playtest.md); final music id and default volume chosen. Carried over, not met and not waived: SC-004 phone fps (never measured) and SC-003 balance (`growthK = 1.5` provisional, deferred by the owner).

---

## Phase 7: Convergence

- [X] T033 🔒 Studio: produce the phone-size UI captures of Quality Gate 2 per plan Phase D / quickstart §5 / F-13: in a Play session, clone the screen's root Hud, Book and Results into exact-size frames at 640×360, 844×390 and 1280×720 (UIScale below 1 only if it does not fit the Studio viewport), verify `TextFits`/`TextSize`, text ≥ 18 px, the Book's 18 cards on page 1 and 5 pages, and the new `Icons` tier-headline glyphs in both `FredokaOne` and `GothamMedium`; store captures in `specs/004-snow-village/captures/` and record results in `playtest.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories.
- **User Stories (Phase 3+)**: All depend on Foundational phase completion - BLOCKED until it is complete.
  - User Story 1 (Phase 3, P1), User Story 2 (Phase 4, P1), User Story 3 (Phase 5, P2): priority order P1 → P2.
- **Polish (Phase 6)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - no dependencies on other stories. T012 before T013; T013 and T014 before T015; T014 before T017; T012 before T016.
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - no dependencies on other stories. T019 before T020; T020 before T022. Independent of US1 (the grey-box world keeps its own data through the widened `WorldDef`).
- **User Story 3 (P2)**: Depends on US1 (grey-box run, world data) and US2 (content module for `ArtManifest`). T023 after T019; T026 after T007/T009; T027 after T026.

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation.
- Tiers/Respawn/Layout: tests T005 to T007 before the rules T008.
- Config (T009) before the WorldSpawner/AbsorbService/WorldCuller consumers.
- Pace (T010) before any layout authoring.
- Story complete before moving to the next priority.

### Parallel Opportunities

- Phase 2: T005, T006, T008 and T009 can run in parallel (after T003/T004); T007 after T005/T006.
- User Story 1: T011 and T012 can run in parallel; T015 and T016 after T012; T014 before T017.
- User Story 2: T019 and T021 can run in parallel; T020 after T019.
- User Story 3: T025 can run in parallel with T024 once T002 is done; T026 and T025 independent.

---

## Parallel Example: User Story 1

```bash
# Launch all independent User Story 1 tasks together (once T012 is done):
Task: "Widen GreyBoxRoom types (T012)"
Task: "Create WorldBuilder (T013)"

# Then the server-side absorb/spawner tasks:
Task: "Edit WorldSpawner (T014)"
Task: "Edit AbsorbService (T015)"
Task: "Edit client reads (T016)"

# BallService (T017) after WorldSpawner (T014).
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001, T002).
2. Complete Phase 2: Foundational (T003 to T010) - CRITICAL, blocks all stories.
3. Complete Phase 3: User Story 1 (T011 to T017).
4. **STOP and VALIDATE**: grey-box gate (`playtest.md` sign-off), `scripts/check.sh` 0, Jest green, Studio run clean.

### Incremental Delivery

1. Complete Setup + Foundational → foundation ready.
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!).
3. Add User Story 2 → Test independently → Deploy/Demo.
4. Add User Story 3 → Test independently → Deploy/Demo.
5. Add Polish → Final validation and PR description.

### Parallel Team Strategy

With several agents (each in its own worktree, Constitution X):

1. One agent does Phase 1; then agents split Phase 2 along the `[P]` groups (rules tests, rules, config/pace).
2. After the checkpoint: agent A takes User Story 1 (server + client reads), agent B takes User Story 2 (content), agent C takes User Story 3 (art/client culling). The single Studio MCP claim is passed between agents task by task.

---

## Notes

- `[P]` tasks touch disjoint files; a task that edits a file another task in the phase also edits is never `[P]` against it.
- `[Story]` labels map each task to its user story for traceability; Setup, Foundational and Polish tasks have none.
- Verify tests fail before implementing; commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Avoid: vague tasks, same-file conflicts, cross-story dependencies that break independence.

---

## Task Summary

- **Total tasks**: 32 (T001 to T032)
- **Task count per user story**: US1 = 7 tasks (T011 to T017), US2 = 5 tasks (T018 to T022), US3 = 5 tasks (T023 to T027); Setup = 2 (T001, T002), Foundational = 8 (T003 to T010), Polish = 5 (T028 to T032)
- **MVP scope**: Phase 1 (Setup) → Phase 2 (Foundational) → Phase 3 (User Story 1 only)
