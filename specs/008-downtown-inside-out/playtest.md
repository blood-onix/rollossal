# Playtest log: 008 Downtown "Inside Out" Map Redesign (Concept A)

**Date**: 2026-11-01  
**Author**: opencode agent  
**Status**: Studio Stage 1 (US1), Stage 2 (US2), and Gate 2 (US3) verified via Studio MCP on live place `112788738500883`.

---

## Smoke Check & Rojo Sync Probe (Studio MCP)
- **Rojo Sync**: Connected to `localhost:34872`. Ran `scripts/studio-sync-probe.sh` via `execute_luau` in Edit datamodel:
  `checked: 89, mismatches: {}` — 100% of repo scripts synchronized to the Studio DataModel without divergence.
- **World Built in Play**: Server spawned `Workspace.World` with `Geometry` (226 blocks), `Objects` (1,434 pooled placements), `Hub` (3 parts), and `Markers` (15 parts). Total active server BaseParts: `1,728` to `1,740` (budget `<= 1,850`, hard limit `< 2,000`).
- **Console Log**: No Lua/Luau runtime errors. Only expected Studio DataStore access warning and bot displacement/vertical violations from fake user IDs `7000xx`.

---

## Stage 1 Verification (T013 - User Story 1)
- **Spawns**: 12 Old Quarter lane spawns verified at canonical lane mouths (`dt_z_door_01` to `dt_z_door_12`).
- **First Pickup**: In both single-eater and concurrent 12-eater (`simulateTwelve`) models, all 12 spawns achieve first pickup within `<= 1.12 s` (well under the `<= 5 s` ceiling).
- **First Minute**: All 12 spawns achieve `D >= 5` (Tier 2) within `18.6 s to 20.9 s` (well within the `10–50 s` pace window, and concurrent starters reach Tier 2 within `22 s to 48 s` vs `<= 60 s` requirement).
- **Kerb Collision**: 1.2-stud kerbs (`dt_door_NN_kerb`) verified at every spawn mouth. D 2 ball held-jump apex is 2.27 studs (clearing 1.2), while unjumping ball is physically contained behind kerb.
- **Screen Captures**: `screen_capture` tool attempted twice for overhead and street-level views; timed out due to MCP Studio window backgrounding. Transferred to `docs/release-candidate.md` per AGENTS.md two-failure tooling limit.

---

## Stage 2 Verification (T022 - User Story 2)
- **Rings 2–5 Geometry**: Full 5-ring world verified in Workspace:
  - Ring 1 (Old Quarter): 8-stud lanes, 30-stud main streets, central plaza with fountain and pedestal landmark slot.
  - Ring 2 (Terraces): Plinths (top 1.2), house rows on plinths, 4 enclosed alleys with flanking walls (top 5.2) and overhead roof slabs (bottom y 4.9).
  - Ring 3 (Yards): 5 district slabs (top 0.25 to 0.5) for Park, Market, Construction Site, Car Park, Rail Yard.
  - Ring 4 (Boulevard): 60-stud orbital road with two 26-stud carriageways and 8-stud median (top 0.8), bus shelters, and billboards.
  - Ring 5 (Skyline & Harbour): 8 Skyline podiums (top 1.2), 4 Harbour quays (top 1.2), 2 shallow water basins (top -0.4), and 8 ramped exit lips.
- **Sphere Cast Validation**:
  - **4.5 Alleys**: Swept sphere along alley 0 corridor (`dt_sc_0`): `D = 4.4` sphere cast cleared unobstructed (`hit = nil`); `D = 5.0` sphere cast was physically blocked by flank wall `dt_sc_0_wa` (`hit = dt_sc_0_wa`).
  - **Storm-Drain Tunnel**: Clearance verified at mouth gap 4.5 studs and roof bottom y 4.9 studs; D 4.5 passes, D 5.0 blocked from entering.
  - **Climbing Ramps**:
    - Car Park stepped ramps (`dt_car_ramp_1..4`): rise 2.0 studs, run 6.0 studs, incline `18.4°` (`<= 20°` requirement).
    - Construction Site ramps (`dt_site_ramp_w/e/n/s`): rise 2.0 studs, run 6.0–8.0 studs, incline `14.0°` to `18.4°` (`<= 20°`).
    - Harbour lips (`dt_lip_s1`): rise 1.6 studs, run 5.0 studs, incline `17.7°` (`<= 20°`).
- **Camera Zoom Verification**:
  - `Rules.Movement.cameraDistance` tested with `Config.cameraMultiplier = 4` and `Config.cameraMaxDistance = 320`:
    - At `D = 20`: camera distance = `80.0 studs`.
    - At `D = 80`: camera distance = `320.0 studs`.
  - Camera pulls back smoothly all the way to 320 studs without premature clamping.

---

## Gate 2 Verification (T025 - User Story 3)
- **12-Ball 60-Second Playtest**:
  - Spawned 12 playerless bots in Holiday City (`winter`) via `ServerStorage.Tests.BotRun:Clone().Parent = ServerScriptService`.
  - 13 concurrent balls active in Workspace (`Balls` folder).
  - Ran for 120 seconds.
- **Performance Sampling (correction after review round 1)**:
  - The earlier figure (`workspace:GetRealPhysicsFPS()`, 15 samples of 60) is the physics step rate, which stays at 60
    whatever the render rate. It is **not** evidence for the render-frame-rate half of FR-013 / SC-005 / US3 AC1 and is
    withdrawn. The run also recorded 15 one-second samples, not 60 s, and did not count throttled seconds.
  - Status: **not measured.** The render-fps check (12 balls, 60 s, per-second client Heartbeat frame times, seconds at
    exactly 15 fps reported as throttled) moved to `docs/release-candidate.md`. Only the part budget and mesh checks
    below are met in Studio.
- **Part Budget**:
  - Total active BaseParts in Workspace during 12-ball run: `1,694` to `1,740` parts (strictly `< 2,000`).
- **Mesh Asset QA (`dt_*`)**:
  - Inspected 1,434 `dt_*` MeshParts in live play:
    - Single material: `Plastic` (or SmoothPlastic).
    - Atlas UV mapping: All meshes use shared color palette atlas (`TextureID ~= ""`).
    - Collision fidelity: `Box` (Minimal collision overhead).
    - DoubleSided: `false`.

---

## Pace Tuning Status (T021, DONE) - 2026-11-02
- **Current**: `growthK = 2.94`, with the `TUNE` values in `Downtown.luau`. `scripts/check.sh` exits 0, 495 Lune tests passed.
- **Model timings across all 12 spawns**: `winter` D 12 at 71-79 s, D 30 at 119-132 s, D 80 by 188 s, D 150 by 239 s.
  `city` D 12 at 67-80 s, D 30 at 110-135 s, D 80 by 185 s, D 150 by 234 s.
- **Finding**: the original windows pinch. About 300 searched combinations of `growthK` and the `TUNE` levers, scored on
  the full Lune suite, stalled at 14 s outside the windows (mostly `city` D 30 at 110 s).

## Deviations
- **Pace lower bounds relaxed (owner, 2026-11-02)**: D 12 from 70-110 s to 62-110 s, D 30 from 120-180 s to 105-180 s.
  The other marks are unchanged. These are model timings; human-played timings are still open in
  `docs/release-candidate.md`.

## Jest

2026-11-02, Studio Edit, `require(game.ServerStorage.Tests.runner)()` after T030/T031 and the review round 1 slot change: 12 suites, 0 failed suites; 154 tests, 151 passed, 0 failed (3 pending).

- T030 option taken (revised in review round 1): built the missing `slot.medium` (4, Market), `slot.yard` (4, Park) and `slot.street` (4, Boulevard) placements in `Downtown.luau`, so all five slot kinds swap by data (US2 AC3, SC-003). The pinned dressing-slot count is now 109 (96 small + 4 + 4 + 4 + 1 landmark). The ThemeSwitch assertion covers all five kinds again. `boulevardT3` went 9 to 10 to keep the pace windows; the city placement band test now checks the 1500 cap (C7). Jest re-run after this change: 12 suites, 0 failed; 154 tests, 151 passed, 0 failed, 3 pending. Lune: 495 passed.
- T031: scatter probe moved to (0, -110), open Ring 2 street at Y = 0. (0, -100) holds a holiday garland at Y 11.
