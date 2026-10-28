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
