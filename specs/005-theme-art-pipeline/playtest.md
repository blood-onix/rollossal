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

## Round 12, 2026-10-29 (T040 avoiding driver)

- Owner chose the avoiding driver route. Sync probe: 69 checked; the one mismatch (`Assets` at 4850 bytes) was a stale expected count in a scratch copy of the probe; the regenerated probe and a direct read both give 4837, which matches the repo file. Studio matches the repo.
- Driver: client-side Heartbeat loop, source at `scratchpad/avoid_driver.luau` (not in the repo). It steers toward the best eatable cube (`Size <= 0.4 x diameter`) with a clear straight line, and keeps 1.0 stud clear of every untaken prop too big to absorb. Speed is capped at 12 near props, under the 15 knock-off threshold. Surfaces whose top is under 0.7 ball radii above the ball's bottom count as steps, not walls (porch edges are 0.6 high). `winter_lights` goes first once absorbable, anywhere on the map.
- Four runs, each 220 to 240 s of Active run time, Studio not touched (MCP only), each stopped by the run ending:
  - Run A (step rule, no winter priority): 255 absorbs, diameter 43.2 at the end, 0 shrinks, `stuck` 2. Diameter 5.5 reached about 118 s in. `winter_lights` not taken: the ball was never within 90 studs of (30, 74) for long, and the target filter excluded anything further.
  - Run B (plus winter priority): 129 absorbs, 7.62, 0 shrinks. Stuck in the west spawn yard at diameter 3.1 from about 140 s to 195 s, with no reachable target on 234 frames. `winter_lights` not taken.
  - Run C (CLEAR 0.6 plus fallback to the best unclear target): 103 absorbs, 8.68, 0 shrinks. Fallback fired 323 frames, `stuck` 10. Yard pocket from about 80 s to 190 s. `winter_lights` not taken.
  - Run D (as B): 39 absorbs, 3.16, 0 shrinks. Wandered to about x -388, z -256 with no reachable target on 417 frames; diameter 2.67 from about 60 s to 180 s. `winter_lights` not taken.
- Findings:
  - The avoiding route did not produce a knock-off in any run (0 shrinks in 4 runs, 39 to 255 absorbs). The earlier shrink was consistent with bumps into props; the new driver never produced a shrink, which supports that reading but does not confirm it, since bump events are not logged.
  - The early game is the bottleneck: from the west spawn yard at diameter 2 to 3, the ball often cannot find a reachable eatable cube and wanders. Run A escaped quickly and the other runs did not, so this depends on the random wander. Diameter 5.5 came at about 118 s in run A and about 210 s in run C; `winter_lights` needs the ball near (30, 74), so the detour there does not fit a 240 s run from this start.
  - Open question for the owner: is a diameter-2 ball meant to be able to leave the west spawn yard without a prop-free path? If not, the level needs a clear exit or the proof needs a test-only start.
- T040: not done. Options, owner's call: (a) a path planner for the driver (grid search over the world with raycasts), which is a larger job; (b) a test-only growth path, e.g. starting the proof at diameter 5.5 on the server; (c) a level fix if the yard exit is meant to be clear.
- Console: not checked this round. Studio left in Edit after the last run.

## Round 13, 2026-10-29 (T040 path planner, T041 12-ball load)

- Studio dropped out and reconnected at the start of this round. The repo code is unchanged since Round 12, so the sync check from Round 12 still holds.
- Planner, source at `scratchpad/avoid_driver.luau` (not in the repo). A 2-stud grid over x -320..320, z -260..200. A cell is blocked when a ball of the current diameter would touch an untaken non-absorbable prop (centre distance minus `Size/2` under radius + 0.3 + 1.42 inflation) or non-step scenery. The grid is rebuilt at each 10 % diameter bucket and at least every 5 s (about 0.15 s each). A breadth-first search from the ball picks the best eatable object: `winter_lights` first once absorbable, then size³ per path distance. It replans every 0.6 s and on each absorb, and follows the path with pure pursuit.
- Edit-mode checks on the real map. Diameter 2.0 from the spawn (-200, -120): 161 eatable cubes reachable; the nearest one more than 12 studs away is 16 studs off the path, with a prop margin of 2.7 and no blocked samples. Diameter 5.6: path to `winter_lights` is 282 studs (141 cells), no blocked samples, minimum prop margin 1.74 (bump margin 0.3). The spawn yard is not enclosed; the earlier driver failed because its straight-line test rejected routes a grid search finds.
- Finding: 1,553 of 1,616 tagged objects are MeshParts whose physical `part.Size` differs from the `Size` attribute (for example `sv_04_lawn_s_001`: attribute 5, part 5 × 3.4 × 1.3). The client's bump test uses the attribute as a sphere, so a box test misses the bump range. Tagged objects now use the client's metric.
- Runs, Client datamodel, MCP only, Studio not touched:
  - P1 (box test): `winter_lights` absorbed at 66.1 s, 101 absorbs, 2 shrinks (2.76 → 2.65 at 17.6 s, 5.62 → 5.57 at 64.7 s), 0 stuck, 0 no-path.
  - P2 (client metric): `winter_lights` absorbed at 69.8 s, 85 absorbs, 1 shrink (5.67 → 5.66 at 68.3 s), 1 stuck, 0 no-path. The 6.74 → 2 entry at t 0 is the new run's reset, not a knock-off.
  - P3 (client metric, contact log, run allowed to finish): 134 absorbs to diameter 31.8, 0 shrinks, 0 stuck, 0 no-path, 1 contact (`sv_03_lane_s_004`, size 6.5, gap 0.01, speed 29.5) with no shrink recorded.
- T040 steps 1–2 met: after P1 ended, the Book's winter page read `1 / 1 Holiday charm`.
- T040 step 3 not done: switching to city needs `activeThemeId` changed in the content file and a profile that survives a Play restart. `Config.useMockDataStoreInStudio` is true and the console reports ProfileStore has no API access, so the profile does not survive a restart. Owner decision: enable Studio API access for the dev place, or agree a test-only override.
- T041 12-ball load (quickstart §3, playerless BotRun, 240 s): 1,709 BaseParts (under 2,000, now measured). `everyTierKeptShare` false: tier 3 fell to 0.11 to 0.23 and tier 4 to 0.11 by 240 s, under the 0.2 floor. The bot eater is naive and is not the avoiding planner, so this is a load result, not a verdict on the route.
- T041 fps: not run, needs Studio in front (owner).
- Quality gates: T040 steps 1–2 met, step 3 blocked; T041 tier share fails under the bot load; fps not measured; T042 not signed off; T045 and T054 are owner tasks.

## Round 14, 2026-10-29 (T040 speed cap, step 3 attempt, T041 fps)

- Planner, same grid and search as Round 13, with one addition: when an untaken non-absorbable prop is within 8 studs, the speed is capped at 12 studs/s. The knock-off check uses the peak horizontal speed over 0.35 s, so the cap keeps the peak under 15 before a contact. Source at `scratchpad/avoid_driver.luau`.
- Run P4 (fresh session, MCP only, Studio not touched): `winter_lights` absorbed at 105.7 s, 83 absorbs, max diameter 6.72, 0 shrinks, 1 stuck, 5,276 frames under the speed cap. The 60 contacts logged are all with `sv_square_003` (size 25), at speed about 10 studs/s and gaps from -0.64 to 0.36. At that speed no knock-off is expected, and none was recorded. The ball overlapping a size-25 tagged object is a planner gap: the grid is 2D and does not model a ball resting on top of an object.
- Book after the run ended: winter page `1 / 1 Holiday charm`, the same check as Round 13.
- T040 step 3, attempted two ways, neither completed:
  - A Client-side runtime override (`Worlds.activeThemeId = "city"`) did not reach `BookUi`. The winter page stayed active, so `BookUi` holds its own copy of `Worlds`. The value was reset to `winter` afterwards.
  - Restarting Play with the same profile reset the winter book to `0 / 1`. `Config.useMockDataStoreInStudio` is true, so the mock store does not keep the profile across Play sessions. Step 3 needs Studio API access on the dev place (owner setting), or a test-only server hook.
- T041 fps, Client, 60 s, Studio not touched: render rate 14 to 16 fps every second (median 15), 40 seconds at exactly 15 fps (throttled), 0 seconds at 30 fps or more. Heartbeat mean 60. This is the background throttle Round 11 recorded, so it cannot judge the 30 fps gate. An unthrottled sample needs Studio in front (owner).
- Quality gates: T040 steps 1–2 met (confirmed again in P4), step 3 blocked on the Studio profile setting; T041 12-bot tier share fails (Round 13); T041 fps throttled, not judged; T042 not signed off; T045 and T054 are owner tasks.

## Round 15, 2026-10-29 (T040 knock-off rate with the speed cap, T042 gate check)

- Step 3's rule is covered by `tests/unit/Book.test.luau` ("progress preserved when the active theme moves away"): with city active, the winter page keeps its 1 / 1 progress, reports `isActive` false, and carries a returning key. `lune run tests/unit/run` passes: 346 passed, 0 failed. The Studio half of step 3 is still blocked (Round 14).
- Run P5 (speed cap, same driver, fresh session, MCP only, Studio not touched): `winter_lights` absorbed at 92.2 s, 72 absorbs, max diameter 6.68, 0 shrinks, 0 stuck, 4,607 frames under the cap. The 60 logged contacts are with large props (`sv_06_lane_s_006`, size 9, plus the size-25 square in Round 14), at speed about 10 studs/s and gaps from 0.16 to 0.38. Those are most likely the ball resting on top of tall props, which the 2D grid does not model.
- Across the capped runs: P4 and P5 had 0 shrinks each. Before the cap, Round 13's runs had 2, 1 and 0. The cap keeps the peak speed near contacts under 15, and that appears to be what prevents the knock-offs. Two runs are too few to call the rate settled.
- Book after P5 ended: winter page `1 / 1 Holiday charm` again, with the reward line hidden, which is correct for an active reward-less theme page.
- T042 gate check (not signed off):
  - Met: parts under 2,000 (1,709 with 12 bots); T040 winter absorb and Book 1 / 1; the planner gives 0 shrinks in its last two runs; the Lune suite is green.
  - Not met: the tier floor under the 12-bot load. Two runs: run 1 (Round 13) had tiers 3 and 4 below 20% by 240 s; run 2 (this round, 1,398 pickups) had tier 4 at 0.03 at 180 s and 0.11 at 240 s, with tier 3 back at 0.79. Tier 4 failed both times. Parts stayed at 1,709. No unthrottled fps sample (needs Studio in front).
  - Open: T040 step 3 (Studio API access, owner setting); T045 hand-off and T054 music track (owner tasks).

## Round 16, 2026-10-29 (T040 step 3 under a test-only setup)

- Approval taken as: run the steps that are reversible and test-only; no Studio settings changed; no balance or spec decisions made; no uploads. T045 (asset upload and commit that publishes content) and T054 (music track) were not done.
- Setup, all temporary and reverted:
  - `src/shared/Content/Worlds/SnowVillage.luau`: `activeThemeId` changed from `"winter"` to `"city"`, synced to Studio by Rojo, Play started, then reverted. After the revert, Studio's copy is back to 26,905 bytes with `"winter"`.
  - A session-only `Script` (`BookGrantTest`) created in `ServerScriptService` in the Server datamodel. It called `DataService.applyRunResult` for the test player with `newBookIds = { "snow_village.winter_lights" }`, the same path a real run result takes. The outcome was `applied`. The script disappears when Play stops.
- Result, with `activeThemeId` = `city` on both client and server (confirmed on the Client):
  - Winter page: `1 / 1 Holiday charm`, reward line `🔁 Back when the snow falls again` (the winter returning label; no timer), progress text white (inactive style).
- Not verified: "tier pages 100 % achievable" in T040 step 3. Not checked this round.
- What this does not prove: the win was granted, not earned in a city-theme run. A real city-session run would show the same page logic; the grant only exercises the book update and the Book UI under city.
- Lune suite: 346 passed, 0 failed, after the revert.
- T040: steps 1 and 2 met (planner runs P4 and P5), step 3 met under this test setup except the tier-page check. Not ticked; the owner decides.

## Round 17, 2026-10-29 (T045 upload attempt, blocked)

- Approval: the owner answered "Yes, upload" to the T045 uploads (six atlases and the 65 re-UV'd FBX files).
- Preflight: Studio `Rollossal (placeId: 112788738500883)` listed; Rojo up on localhost:34872; `python3 art/scripts/palette.py --check` reports atlases in sync; `lune run tests/unit/run` 346 passed, 0 failed.
- Atlas upload: `upload_image` accepts only http or https URLs. All six local PNGs (`art/atlases/{city,winter,spring,autumn,toon,neon}.png`) returned `Error Upload: Only http/https URLs are supported`. Nothing was uploaded and no id was created.
- No other route from here: no Open Cloud API key in the environment or the repo, and no Studio tool uploads a local file as an asset. The 004 contract's import path is the owner's Asset Manager, Bulk Import (not scriptable). The agent then reads `MeshId` and `TextureID` back by file name through `execute_luau`, as `specs/004-snow-village/contracts/art-pipeline.md` describes.
- Not changed: `src/shared/Assets.luau`, the commit history, and `Assets.palette`. Nothing is committed.
- Spec discrepancy to settle before the hand-off: T045 says `Assets.meshUv = "atlas"`. The owner-approved FR-004 (T065, `specs/005-theme-art-pipeline/spec.md`) makes `Assets.renderingMode` the switch (`"atlas"`), keeps `Assets.meshUv` as the legacy fallback texture, and removes only `Assets.palette`. `Assets.luau` already follows FR-004 (`renderingMode = "legacy"`, `meshUv` set to the legacy id).
- Ordering for the hand-off: the 65 `Assets.meshes` ids must be replaced in the same commit as `renderingMode = "atlas"`. The current ids point at the legacy-UV meshes, which would sample the atlas wrongly.
- T045 stays open. Steps 4 to 6 of the hand-off wait on the ids.

## Round 18, 2026-10-29 (T045 owner import read back, code hand-off applied)

- Owner ran Asset Manager → Bulk Import. The six atlas images are account-level inventory (not in the place), so their ids were read from Asset Manager. The 65 FBX files came in as 65 Models in Workspace, each with one MeshPart; their MeshIds were read by file name.
- `src/shared/Assets.luau` now: `renderingMode = "atlas"`; `palettes` filled (city 135771669927883, winter 80845524655584, spring 130785517655515, autumn 77294706934568, toon 119324797322203, neon 88161628123428); all 65 `meshes` ids replaced; `palette` field removed; `meshUv` kept as the legacy fallback (FR-004).
- Checks: `REQUIRE_ASSET_IDS=1 lune run tests/unit/run`: 346 passed, 0 failed. `palette.py --check`: atlases in sync. Studio's ReplicatedStorage copy of Assets matches the file (4,888 bytes, atlas mode). All 65 Studio MeshIds match the file. All six atlas ids resolve through MarketplaceService to assets named after their theme (type 1).
- Mesh recolour between winter and city: NOT confirmed. Two Edit-mode captures of one mesh with each atlas looked the same, and the wide shot was too far to judge. Not a pass. Needs a check in Play (or an owner look) on a themed prop.
- Cleanup: the 65 imported Models were removed from Workspace (the 004 contract requires imported parts not to ship). Assets stay in the account.
- Not done: no commit. `LoadStringEnabled` must be off before any publish (AGENTS.md). T045 stays open until the recolour check and the owner's commit decision.

## Round 19, 2026-10-29 (mesh recolour, winter vs city, in Play)

- Method: Play started, then on the Client two anchored clones of one world mesh (`Workspace.World.Objects.sv_edge_w_014`, MeshId `rbxassetid://107596323435241`), sized 10 studs, placed side by side at y = 400. The left clone had `TextureID` = winter atlas (`rbxassetid://80845524655584`), the right clone city atlas (`rbxassetid://135771669927883`). One frame was captured with `screen_capture`. Clones were destroyed and Play stopped afterwards.
- Result, judged by eye on the capture: the two clones are clearly different. Left: darker, redder wood and blue-white runners. Right: lighter, tan wood and grey-white runners. The mesh recolours with the atlas, so the atlas mode works in Play.
- Limits: one mesh, one frame, judged by eye, not pixel-measured. The in-game theme switch was not exercised (the game's own winter and city props were not compared). Edit-mode captures in Round 18 were inconclusive; this Play check is the one that counts.
- T045 recolour check: met for this one mesh. A full check across theme props is still open.

## Round 20, 2026-10-30 (T040 tier 5 in city, T041 fps, T045 atlas per theme)

- Studio: one instance (Rollossal, placeId 112788738500883). Sync probe on Edit: 69 checked, `mismatches = {}`. MCP only; no desktop input.
- Finding (T040 step 3, "tier pages 100 % achievable"): in `city` the base Tier 5 object `skating_rink` was never placed. Both `slot.landmark` placements map to `giant_duck` there, and the rink had no other placement, so the Tier 5 page topped out at 3 / 4. A Lune probe over the resolved placements showed it (winter: 0 base objects missing, city: 1). Tier pages count the base kit only (`Worlds.baseObjects`), and the spec says they stay completable in every season.
- Fix (owner chose "fixed rink in city overlay"): `SnowVillage.luau` gains `cityRinkFixed` (`sv_ol_skating_rink_fixed`, `skating_rink` at (-30, -280)) on the city overlay. The spot is clear of every keep-out and of every footprint (best clearance about 30 studs), inside `halfExtent` 300. Tests: the overlay fixed count is 2, the city placement count is 1618, and a new test checks that every theme places every base object. `lune run tests/unit/run`: 347 passed, 0 failed. `scripts/check.sh` exits 0.
- Live check, Play on `city` (data-only edit of `activeThemeId`, reverted afterwards; Studio's copy is back to 27,425 bytes with `winter`): `sv_ol_skating_rink_fixed` exists at (-30, -280), size 40. All 64 base objects have at least one placement in the world (0 missing, read on Server and on Client). `ClockTime` 13. Console: only the known noise (DataStore `StudioAccessToApisNotAllowed`, profilestore, `ContentId rbxassetid://203785492`).
- T045 atlas per theme, Play, all MeshParts under `Workspace.World`: city: 1,580 MeshParts, every `TextureID` is the city atlas (`rbxassetid://135771669927883`). winter: 1,611 MeshParts, every `TextureID` is the winter atlas (`rbxassetid://80845524655584`). With the Round 19 side-by-side capture, the mesh recolour between `winter` and `city` is confirmed in Play across the game's own props.
- T041 fps, Client, Studio not touched: a 60 s run (render 15 fps in 60 of 60 seconds, mean 15.15) and a 150 s run after the owner was asked to put Studio in front (render 15 fps in 150 of 150 seconds, mean 15.17). Heartbeat mean 60.6 in both. Zero seconds at 30 fps or more, so the 30 fps gate cannot be judged. The Claude window was probably still in front when the owner answered. `Workspace` BaseParts 1,696 (< 2,000). The 640 x 360 capture (Round 11) stands: every label fits at 18 px or more.
- T041 open layout item from Round 11: the 120 px thumb zone overlaps the first Book card's name label while Book is open. Owner decides whether the panel or the thumb zone moves.
- Quality gates: T040 met (steps 1 to 3, with the Round 16 grant caveat); T045 asset, atlas and recolour checks met; T041 fps unjudged (throttled), T042 and T054 open. Publish checklist: `LoadStringEnabled` must be off in the published place (the owner keeps it on in the dev place for Jest).
