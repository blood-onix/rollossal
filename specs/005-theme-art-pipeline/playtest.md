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

## Round 5, 2026-10-28 (working tree after 6649f96 with uncommitted T055 spec change)

- Studio: one instance (Rollossal, placeId 112788738500883). Sync probe on Edit: 69 checked, `mismatches = {}`, after the spec edit.
- T055: `ObjectTemplates.spec` now asserts that every object with an `Assets.meshes` id builds a `MeshPart` template. Edit-mode runner: 113 passed, 0 failed (all 7 suites). The MeshPart checks are no longer vacuous: all 64 objects in `Worlds.active.objects` have an `assetKey` with a mesh id, and all 64 templates are `MeshPart` (none are stand-ins).
- T039: the render (`Automatic`), collision (Box tiers 1-3, Hull tiers 4-5), transparency and no-light/no-SurfaceAppearance checks pass on those 64 real MeshParts.
- T040 (Book proof): not passed. Winter's world builds (36 `winter_lights` objects, ClockTime 15.5). A client Heartbeat driver (nearest absorbable part, horizontal velocity at `min(18·√(D/2), 32)`, jump when stuck) grew the ball from 2.0 to about 2.6 on the client, and the server's authoritative `Diameter` was 2.11 when read. Client and server diameters differ, and the client value oscillated between 2.5 and 2.8 rather than climbing. `winter_lights` (size 2.2) needs diameter ≥ 5.5, far beyond reach in one 240 s run with this driver. Play was stopped; the Book page was not read, and the city switch was not run.
- T041: not run (needs Studio in front; out of scope for the agent this round).
- Gap for the next round: the client/server diameter mismatch and the oscillation are a gameplay observation to investigate (not diagnosed here).
- Quality gates: not met. Open: T040 Book proof, T041 fps and capture.

## Round 8, 2026-10-28 (commit cf4a371 plus uncommitted working tree)

- Studio: one instance (Rollossal, placeId 112788738500883, id 7a58188e). Sync probe on Edit: 69 checked, `mismatches = {}`.
- T040 (Book proof): not passed. Play on winter: `activeThemeId` = `winter`, 6 `winter_lights` instances in the world, ball at `Diameter` 2. The Book page needs `winter_lights` absorbed, which needs `size` 2.2 ≤ 0.4 × diameter, so diameter ≥ 5.5. With `growthK` 0.6 that is about 260 units of tier-1 volume (`size³`), far beyond one 240 s run with the client driver used in rounds 5 to 7. No Book page was read and the city switch was not run for this check. Play was stopped.
- T041: not run. Needs Studio in front for an unthrottled window (owner); out of scope for the agent.
- Open for the next round: T040 needs either a longer run with an owner-approved test diameter, or a test-only way to grow the ball to 5.5 that the owner approves.
- Quality gates: not met. Open: T040 Book proof, T041 fps and 640×360 capture.

## Round 9, 2026-10-28 (commit 42bfd32 plus uncommitted working tree)

- Studio: one instance (Rollossal, placeId 112788738500883, id 7a58188e). Sync probe on Edit: 69 checked, `mismatches = {}`.
- T061: `ObjectVisual.buildMesh` picks `Enum.CollisionFidelity.Hull` or `.Box` with an explicit `if`, not a dynamic index. `scripts/check.sh` exits 0: StyLua, Selene, luau-lsp strict analysis, token and atlas sync, Lune unit suites (343 passed, 0 failed), and the GreyBoxRoom and purity guards.
- T063 (glyph check, Play on Client): a temporary 640×360 frame holds two labels, `Icons.retry` plus text, in FredokaOne and in GothamMedium. The 🔁 glyph renders in both labels (screen capture `ScreenCapture_T063_glyph`), and `TextFits` is true for both at 18 px. Caveat: the Studio viewport is not 640×360, so the frame was drawn at scale 1 inside the viewport and not captured at true 640×360 pixels. The temporary GUI was removed when Play stopped.
- Console during the T063 Play session: only pre-existing noise (DataStore `StudioAccessToApisNotAllowed`, profilestore, `ContentId rbxassetid://203785492`). The id appears in no repo source, so the failure is not from game code.
- T062 (export negative test): `art/scripts/test_export_negative.py` is written. It builds fixtures for UV across a cell edge, a second material, and over-budget triangles, then checks that `art/scripts/export_all.py --source` exits non-zero with the rule named. It has NOT been run: the Blender binary is under `/Applications`, and the sandbox hook blocked the run from the shell. Open until someone runs it.
- Quality gates: still not met (T040 Book proof, T041 fps and 640×360 capture, T045 owner hand-off, T054 music track). T042 stays open until those are resolved.

## Round 10, 2026-10-29 (commit c92b895 plus uncommitted working tree)

- Owner decisions applied: T059 (D1 bindings on `WorldDef.themeBindings`, D2 `Worlds.forTheme(themeId)`) recorded in spec FR-001..003; T065 (`Assets.meshUv` is the legacy fallback texture, `Assets.renderingMode` is the atlas switch) recorded in spec FR-004; T060 gate keep-outs (24 porch ramps) and shortcut keep-outs (6 alleys, 4 studs across) declared and checked for every placement in every theme; T066 city beach-towel fixed placement at (-30, -100), clear of every keep-out.
- Repairs to the uncommitted working tree found while verifying: `src/shared/Assets.luau` lacked `return Assets` (5 Lune suites failed), and `bell` had a malformed id `rbxassetid://rbxasset://sounds/bass.wav` (HEAD value restored: `rbxasset://sounds/bass.wav`).
- Lune: `tests/unit/run` 346 passed, 0 failed. `scripts/check.sh` exit 0.
- Studio: one instance (Rollossal, placeId 112788738500883, id 7a58188e). Sync probe on Edit: 69 checked, `mismatches = {}`; after the bell fix `Assets` is 4837 bytes and carries the corrected `bell` line.
- T041 (fps, Play, Client, 60 s, Studio not touched): Heartbeat count per second 60 to 61, mean 60.5; 0 seconds at exactly 15 fps (throttled); 60 of 60 seconds at 30 or more. `Workspace` BaseParts 1698 (under 2000). Limit: Heartbeat rate is the frame-rate proxy, play was idle (no ball driver), so the 12-ball load was not measured separately.
- T041 (640 x 360 capture, Book theme-page `AbsolutePosition`, `TextFits` at 18 px): not run. The Book panel opens on the tier-1 page (18 crumbs); the winter and city theme pages need paging to, which was not done this round.
- T040 (Book proof): not run this round. Winter's `winter_lights` (size 2.2) needs diameter 5.5 or more, which earlier driver runs did not reach (rounds 5 to 8). Needs the owner's call: a longer run or a test-only growth path.
- Console during Play: DataStore `StudioAccessToApisNotAllowed` and profilestore (pre-existing), `ContentId rbxassetid://203785492 failed` (no repo source). The `rbxasset://sounds/bass.wav` failure came from the malformed `bell` id, now fixed; not re-observed in Play yet.
- Quality gates: not met. Open: T040 Book proof, T041 640 x 360 capture, T042 sign-off, T045 owner hand-off, T054 music track.

## Round 11, 2026-10-29 (commit c92b895 plus uncommitted working tree)

- Studio: one instance (Rollossal, placeId 112788738500883, id 7a58188e). Sync probe on Edit: 69 checked, `mismatches = {}`. No desktop input: Studio was driven only through the Studio MCP tools.
- T041 capture, 640 x 360: `BookUi.Panel` cloned into a 640 x 360 canvas at UI scale 1 (`UiKit.screen` scale is `max(1, short side / 720)`, which is 1 at 360). Book on the `Holiday charm` page (winter theme page, `0 / 1`, active, so no returning label). Panel at (8, 112), 464 x 240. Every text label fits its box: Progress 20 px, Title 18 px, Reward 18 px, card Name 18 px, Icon 28 px, Prev/Next/Close glyphs 28 px.
- T041 layout finding: the jump zone (96 px at (520, 240)) does not overlap the Book panel. The thumb zone (120 px at (0, 240)) does overlap the first card's Name label (at (14, 242), 100 x 44) while Book is open. Owner to decide whether the panel or the thumb zone moves.
- T041 fps, Client, 60 s, Studio not touched: render rate 15 fps on 52 of 60 seconds and 16 fps on 8 (mean 15.1). Heartbeat mean 60.55. No unthrottled second, so this cannot judge the 30 fps gate. Needs Studio in front (owner) for an unthrottled 60 s run.
- T041 parts: Workspace BaseParts 1696 with one ball and no driver (< 2000). The 12-ball load was not run. Twelve balls add at most twelve parts, so the count stays under 2000 by arithmetic, not by measurement.
- T040 Book proof: not reached. Two driven 240 s runs (client-side Heartbeat driver, nearest-eligible cube scoring as in `tests/studio/BotRun.server.luau`) absorbed 37 cubes by the count of diameter steps, but the ball kept returning to diameter 2.0 (maximum 2.63). The shrink lines up with bumps into larger props, which take the server's knock-off path (`AbsorbService.tryBump`, `Growth.shrinkDiameter`). This is inferred from the code and the timing, not confirmed by logging bump events. The driver also re-picked unreachable porch cubes (`sv_01_porch_029`, `sv_01_porch_002`) and its stuck handling did not move the ball. `winter_lights` stayed un-taken, and the Book stayed `0 / 1 Holiday charm`.
- Console: not checked this round.
- Quality gates: not met. Open: T040 Book proof (needs a driver that avoids props, or a test-only growth path, owner's call), T041 fps (needs Studio in front) and the 12-ball load, T042 sign-off, T045 owner hand-off, T054 music track.
