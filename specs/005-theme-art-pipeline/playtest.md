# 005 Studio playtest observations

Date: 2026-10-28. Commit: 6649f96 plus uncommitted working tree (`src/shared/ObjectVisual.luau`, `specs/005-theme-art-pipeline/tasks.md`).
Place: Rollossal (placeId 112788738500883), Studio instance 7a58188e.

## Preflight and sync (T036 precondition)

- Rojo serving on localhost:34872.
- Sync probe on Server: 68 scripts checked, `mismatches = {}`.
- The probe could not run on Edit because a playtest was already running; it ran on Server instead.

## Play session, winter (T036, not passed)

- Play restarted on the current code.
- `activeThemeId` = `winter` (Worlds module).
- Blocker: the world does not build. Console: `ServerScriptService.WorldBuilder:243` and `ObjectVisual` fail with "The current thread cannot write 'CollisionFidelity' (lacking capability PluginOrOpenCloud)". "Hub mesh failed to build, the hub stays bare" is logged. `Workspace` has no `World` folder; only `Balls`, `Camera`, `Terrain`.
- Because the build aborts, lighting is not applied: `ClockTime` 14, `Brightness` 3 (winter expects 15.5 and 2). No ParticleEmitter and no Sound instances exist in the datamodel.
- Console also reports `Infinite yield possible on Workspace.Balls:WaitForChild("Ball_...")` from the client CameraController.
- Pre-existing console noise, not from this feature: DataStore `StudioAccessToApisNotAllowed`, `ContentId rbxassetid://203785492 failed`.

## Unit-level theme switch (T047)

- `tests/studio/ThemeSwitch.spec` run alone on Server: 11 passed, 0 failed.
- Gap: the spec does not set `ReduceMotion`, so the "false under ReduceMotion" half of T047 is unverified. The live toggle belongs to T038.

## Not run

- T037 to T041: depend on a built world; blocked by the CollisionFidelity failure above.
- T039: `ObjectTemplates.spec` only checks FR-009 (no scripts under meshes). It does not assert the render, collision and transparency rules the task names.
- T045: owner hand-off, requires owner approval.

## Round 3, 2026-10-28 (working tree on 005-theme-art-pipeline after a3c873d)

Changes this round: `ObjectVisual.fidelity` wraps both `RenderFidelity` and `CollisionFidelity` writes in `pcall`; `ObjectTemplates.spec` gains render/transparency and no-light/no-surface assertions.

- Studio: one instance (Rollossal, placeId 112788738500883). Sync probe on Edit: 68 checked, `mismatches = {}`.
- T048: the world builds on winter. `Workspace.World` exists (1692 BaseParts); the console shows no CollisionFidelity error. Lighting `ClockTime` 15.5, `Brightness` 2 (winter). Note for FR-004: the tier Box/Hull collision class is not settable at runtime (locked write), so the tier collision class is decided by the engine default, not by `fidelity`.
- T036 (winter, Play): `ParticleEmitter` `ThemeWeather` enabled, rate 10; `ThemeMusic` playing (`rbxassetid://80565841497538`); `Atmosphere` present (density 0.3). Console: only pre-existing noise (DataStore `StudioAccessToApisNotAllowed`, `ContentId rbxassetid://203785492`). The 32 winter slot placements are asserted by the ThemeSwitch spec on resolved data; an in-world count was not taken.
- T037 (city, data-only edit of `activeThemeId` in `SnowVillage.luau`, then reverted): `ClockTime` 13, `Brightness` 3, emitter disabled, `ThemeMusic` absent (`musicCity` is empty in Assets, so no track is created). City slot instances: ice_lolly 12, beach_ball 8, paddling_pool 6, ice_cream_truck 4, giant_duck 2 (total 32). Overlay: 6 `sv_ol_beach_towel_*` parts. Hero: the 3 `big_snowman` placements carry `ObjectId=big_snowman` (variant copies keep the base id) and the same fountain MeshId as the 6 native fountains. Stand-in colours match the city roles (`ice_lolly` ff6fa8, `beach_ball` 2f7de1, `paddling_pool` 3fa7d6, `ice_cream_truck` f7f7f4, `giant_duck` ffc93c). Ground: `w-grass` (111, 191, 74) and `w-kerb` (154, 149, 142) on the kerb blocks. Gap: the layout has no `w-sidewalk` block, so that part of the ground check is not met. Console: no new errors. The data edit was reverted to `winter` after the run.
- T038 (winter): `ReduceMotion` true leads to `Enabled = false` within one `RenderStepped`; false restores `Enabled = true`, rate 10. Arithmetic: rate 10 × lifetime = 40 ≤ 40. `:Clear()` runs on the same transition (`WeatherController.applyEnabled`) but is not observable from the datamodel.
- T039 (`ObjectTemplates.spec`): the Studio runner passes 7 suites, 111 tests, 0 failed (includes the new T049 assertions). Limit: every template is a stand-in Part (no `assetKey` meshes are imported), so the `RenderFidelity` and `CollisionFidelity` checks on MeshParts are vacuous until T045. Collision class is not asserted.
- T047: `ThemeSwitch.spec` passes (11 tests). The ReduceMotion half is covered live by T038; a server datamodel has no `LocalPlayer`, so the spec cannot toggle it.
- T040 (Book proof): not passed. Winter's page only reaches 1/1 if `winter_lights` is absorbed in winter. A light has size 2.2, and absorb needs `size <= 0.4 × diameter`, so the ball needs diameter ≥ 5.5. The client drive loop (Heartbeat, eats nearest absorbable cube) grew the ball from 2.0 to 2.4 in about 70 s with 2:26 left in a 4-minute run, and did not reach a light. Book opens (TopBar `Book` → `Collection book`, 0/18 crumbs) but no theme page was read.
- T041 (fps, 60 s): Studio was throttled to 15 fps in 59 of 60 seconds (1 unthrottled second, partial). Per AGENTS.md, these samples are not a valid measurement; a rerun needs Studio in front (owner to keep it in front). The 640×360 capture was not taken.
- Pre-existing, not from this feature: `DataStoreService` `StudioAccessToApisNotAllowed` (profilestore, data not saved), `ContentId rbxassetid://203785492 failed`.

Quality gates: not met yet. Open: T037 overlay/hero identity, T039 collision class, T040 Book proof, T041 fps and 640×360 capture (needs Studio in front).

## Round 4, 2026-10-28 (working tree after f898c19)

- Studio: one instance (Rollossal, placeId 112788738500883). Sync probe on Edit: 69 checked, `mismatches = {}`, before and after the city edit.
- T050: `ObjectVisual.buildMesh` passes `RenderFidelity` and `CollisionFidelity` to `CreateMeshPartAsync`; no `fidelity()` post-create writes remain (grep).
- T039 (Edit, `runner` on all 7 suites): 112 passed, 0 failed, including ObjectTemplates (5 tests) and ThemeSwitch (11). Limit: every template is a stand-in Part (no meshes imported), so the MeshPart-only `RenderFidelity` and collision Box/Hull assertions are vacuous until T045. T039 stays open for that reason.
- T037 (city, data-only edit of `activeThemeId`, then reverted to `winter`): `ClockTime` 13; emitter `ThemeWeather` `Enabled = false`; `ThemeMusic` absent (`musicCity` empty); 32 slot stand-ins (ice_lolly 12, beach_ball 8, paddling_pool 6, ice_cream_truck 4, giant_duck 2) with distinct role colours; 6 `sv_ol_beach_towel_*` overlay parts; 3 `big_snowman` hero copies (fountain asset); ground `sv_ground` (111,191,74), kerb (154,149,142), `sv_sidewalk` (201,196,187). World has 0 scripts. Console: only pre-existing noise plus `ContentId rbxassetid://203785492` (the id appears only in spec notes, not game code).
- T040 (Book proof): not passed. Driver loop (Client Heartbeat, nearest absorbable cube) left the ball at diameter 2 in ~90 s; the ball stalled on a porch lip about 1 stud above a ground gumdrop, so it never absorbed anything. Winter's page needs `winter_lights` (size 2.2, diameter ≥ 5.5). Still open.
- T041 (fps, 640x360 capture): not run this round; needs Studio in front for an unthrottled window (owner to keep it there).
