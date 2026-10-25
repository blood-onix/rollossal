---

description: "Task list for the Grey-Box Prototype (001-grey-box-prototype)"
---

# Tasks: Grey-Box Prototype

**Input**: Design documents from `/specs/001-grey-box-prototype/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (`remotes.md`, `replicated-state.md`, `rules-api.md`, `config-and-content.md`), quickstart.md, `.specify/memory/constitution.md` (v1.0.0)

**Tests**: Requested by the spec. Lune unit tests for every `src/shared/Rules` function, `Config` and `GreyBoxRoom` (FR-011, Constitution III, VII) and Jest-Lua Studio tests for server absorb validation (FR-024, Constitution II). Expected numbers are written out by hand from `contracts/rules-api.md` and `research.md` R1; never compute them by calling the code under test.

**Organization**: Tasks are grouped by user story. Part A of the spec (repository foundations) is needed by every other task, so its configuration files and `scripts/check.sh` are in Phases 1 and 2. Story 4 (P3) holds the remaining Part A work: CI, the GDD move, the new README and the guard self-test.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with the other `[P]` tasks of the same phase (different files, no dependency on an unfinished task)
- **[Story]**: US1 to US4, matching the user stories in spec.md
- Every task names the exact file or files it touches

## Conventions

- Every `.luau` file starts with `--!strict` (Constitution XII, FR-004). `src/shared/Rules` files avoid the forbidden words listed in FR-005 even in comments, and have no `require` of each other.
- All numbers come from `src/shared/Config.luau`; no magic numbers in server or client scripts (FR-012). Rules receive their parameters as arguments.
- **Studio MCP claim** (Constitution X): tasks marked `🔒 Studio` drive Roblox Studio through the Studio MCP server. Only one agent may do this at a time. Before starting, append ` CLAIMED:<agent>` to the task line; remove it when done. The Blender MCP server is not used in this feature.
- **Human task**: tasks marked `👤` need people (playtesters, the owner). An agent only prepares them.
- Each task ends with `scripts/check.sh` exiting 0 once it exists (T025). Quality Gate 2 (Studio playtest with console read) applies to every task that touches `src/server` or `src/client`; the dedicated Studio tasks below cover it for the feature, and the PR description must say how each gate was met.

## Path Conventions

Roblox project, Rojo tree as in plan.md "Project Structure": `src/shared` (ReplicatedStorage.Shared), `src/server` (ServerScriptService), `src/client` (StarterPlayer.StarterPlayerScripts), `tests/unit` (Lune), `tests/studio` (Jest-Lua, ServerStorage.Tests), `scripts/`, `docs/`, `.github/workflows/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository metadata and tool configuration (FR-001 to FR-004). All of these are separate files.

- [X] T001 [P] In `wally.toml` change `[package] name` from `ricokick/ricokick` to `rollossal/rollossal` (FR-001). Leave `ProfileStore`, `Jest` and `JestGlobals` entries untouched (no new packages, Constitution XII).
- [X] T002 [P] In `rokit.toml` rewrite the three header comments so the first says "Tool versions for Rollossal", and the third cites `specs/001-grey-box-prototype/plan.md` "Technical Context" instead of `specs/001-shot-engine-career/plan.md` (FR-001). Do not change the `[tools]` pins.
- [X] T003 [P] In `.gitignore` add the missing `*.pem` and `*.key` lines under a "Secrets" comment (FR-002). Confirm the existing file already ignores `.env`, `.env.*`, `*.rbxl`, `*.rbxlx`, `*.rbxl.lock`, `*.rbxlx.lock`, `sourcemap.json`, `/Packages/`, `/ServerPackages/` and `/DevPackages/`; add any that are missing. Also add `roblox.yml` if T007's Selene setup generates one.
- [X] T004 [P] Create `default.project.json` for Rojo 7.7.1 (FR-003, research R9): `name` "Rollossal"; `ReplicatedStorage` contains `Shared` → `src/shared`, `Packages` → `Packages`, `DevPackages` → `DevPackages`; `ServerScriptService` → `src/server` with `ServerPackages` → `ServerPackages` inside it; `StarterPlayer.StarterPlayerScripts` → `src/client`; `ServerStorage.Tests` → `tests/studio` (never replicated); `Players` with `$properties` `CharacterAutoLoads = false` (research R3); `Workspace` and `Lighting` left as Rojo defaults.
- [X] T005 [P] Create `.luaurc` at the repository root with `{ "languageMode": "strict" }` and an alias block only if luau-lsp needs it for `Shared`/`Packages` requires (FR-004).
- [X] T006 [P] Create `stylua.toml` (Luau syntax, `column_width = 100`, tabs, `quote_style = "AutoPreferDouble"`, `call_parentheses = "Always"`) (FR-004).
- [X] T007 [P] Create `selene.toml` with `std = "roblox"` (FR-004). If the installed Selene 0.32.0 needs `selene generate-roblox-std` to produce `roblox.yml`, note it in the file as a comment; `scripts/check.sh` (T025) will run that command and `roblox.yml` is git-ignored (T003).
- [X] T008 Run `rokit install` then `wally install` from the repo root so `Packages/`, `ServerPackages/` and `DevPackages/` exist and `wally.lock` is regenerated for the new package name (depends on T001, T002). Commit the updated `wally.lock`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure rules with their Lune tests, shared Config and Content, the one verification command, and the remote objects. Every user story needs these.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Lune harness and Rules tests (written first, expected to fail until the Rules exist)

- [X] T009 [P] Create `tests/unit/harness.luau` (about 40 lines, no new library): exports `test(name, fn)`, `expect.equal(actual, expected)`, `expect.near(actual, expected, tolerance)`, `expect.truthy`, `expect.falsy`, and a `summary()` that prints pass/fail counts and calls `process.exit(1)` if any test failed.
- [X] T010 [P] Create `tests/unit/Absorb.test.luau` with the eight cases in `contracts/rules-api.md` §Absorb: `canAbsorb(2, 0.8, 0.4)` true; `canAbsorb(2, 0.8001, 0.4)` false; `canAbsorb(2, 0.75, 0.4)` true; `canAbsorb(2, 0.95, 0.4)` false; `canAbsorb(2.375, 0.95, 0.4)` true; `isKnockOff(2, 0.95, 16, 0.4, 15)` true; `isKnockOff(2, 0.95, 15, 0.4, 15)` false; `isKnockOff(2, 0.75, 40, 0.4, 15)` false.
- [X] T011 [P] Create `tests/unit/Growth.test.luau` with the cases in `contracts/rules-api.md` §Growth: `growDiameter(2, 0.75, 0.6)` ≈ 2.0209 (±1e-4); `growDiameter(3.75, 1.5, 0.6)` ≈ 3.7975 (±1e-4); 22 repeated Tier 1 pickups from D=2 give ≈ 2.3851 (±1e-3) and ≥ 2.375; 21 give ≈ 2.3703 and < 2.375; `shrinkDiameter(3, {0.95}, 0.6, 2)` ≈ 2.9808 (±1e-3); `shrinkDiameter(2.05, {1.5, 1.5, 1.5}, 0.6, 2)` equals 2 exactly; `shrinkDiameter(2, {0.75}, 0.6, 2)` equals 2 exactly; `shrinkDiameter(3, {}, 0.6, 2)` equals 3.
- [X] T012 [P] Create `tests/unit/Movement.test.luau` with the cases in `contracts/rules-api.md` §Movement: `targetSpeed(2, 18, 2, 0.5, 32)` = 18; `targetSpeed(8, 18, 2, 0.5, 32)` = 32 (uncapped would be 36); `targetSpeed(4.5, 18, 2, 0.5, 32)` = 27; `cameraDistance(2, 4, 8, 80)` = 8; `(5, 4, 8, 80)` = 20; `(1, 4, 8, 80)` = 8; `(30, 4, 8, 80)` = 80.
- [X] T013 [P] Create `tests/unit/StuckStack.test.luau`: pushing 31 entries onto cap 30 drops the first; `popRecent` of 3 from 5 returns the last three (newest last) and leaves two; `popRecent` of 3 from 2 returns both; `popRecent` from empty returns two empty lists; `visibleTail` of 40 with max 30 returns entries 11 to 40 in order; none of the three functions mutates its input (`contracts/rules-api.md` §StuckStack).
- [X] T014 [P] Create `tests/unit/RateLimit.test.luau`: 10 calls at `now = 100.0, 100.05, …` (step 0.05) are all allowed with limit 10, window 1; the 11th at 100.5 is refused; a call at 101.06 is allowed once the oldest entries age out; an entry at exactly `now − window` is dropped; refused calls do not append (`contracts/rules-api.md` §RateLimit).

### Rules implementation (pure, standalone, no requires between modules)

- [X] T015 [P] Create `src/shared/Rules/Absorb.luau` exporting `canAbsorb(diameter: number, size: number, ratio: number): boolean` (`size <= ratio * diameter`) and `isKnockOff(diameter, size, impactSpeed, ratio, threshold): boolean` (`not canAbsorb(...) and impactSpeed > threshold`) (FR-008).
- [X] T016 [P] Create `src/shared/Rules/Growth.luau` exporting `growDiameter(diameter, size, k)` = `(D^3 + k * size^3) ^ (1/3)` and `shrinkDiameter(diameter, sizes: {number}, k, floor)` computed as `max(floor^3, D^3 - k * sum(size^3))` before the cube root so the result never drops below `floor` (FR-009).
- [X] T017 [P] Create `src/shared/Rules/Movement.luau` exporting `targetSpeed(diameter, baseSpeed, startDiameter, exponent, cap)` = `min(cap, baseSpeed * (diameter / startDiameter) ^ exponent)` and `cameraDistance(diameter, multiplier, minDistance, maxDistance)` = `clamp(multiplier * diameter, minDistance, maxDistance)` (FR-010).
- [X] T018 [P] Create `src/shared/Rules/StuckStack.luau` with generic `push<T>(stack, entry, cap)`, `popRecent<T>(stack, n): (remaining, removed)` and `visibleTail<T>(stack, maxVisible)`. All three return new lists and never mutate input (data-model §5).
- [X] T019 [P] Create `src/shared/Rules/RateLimit.luau` exporting `allow(timestamps: {number}, now, limit, window): (boolean, {number})`: drop entries with `t <= now - window`; if the count is below `limit`, append `now` and return true; refused calls append nothing (data-model §7).

### Config and Content

- [X] T020 [P] Create `src/shared/Config.luau` as one read-only table with exactly the keys and values of `contracts/config-and-content.md`: `startDiameter` 2, `absorbRatio` 0.4, `growthK` 0.6, `maxVisibleStuck` 30, `maxTrackedStuck` 120, `knockOffCount` 3, `bumpSpeedThreshold` 15, `bumpSpeedWindow` 0.35, `bumpCooldown` 1.0, `respawnDelay` 15, `scatterDistance` 6, `scatterGrace` 1.0, `absorbRateLimit` 10, `rateLimitWindow` 1, `absorbDistanceTolerance` 2.0, `maxServerBallSpeed` 56, `displacementSlack` 1.5, `fallRespawnY` -50, `respawnBallCooldown` 3, `speedExponent` 0.5, `baseSpeed` 18, `speedCap` 32, `cameraMultiplier` 4, `cameraMinDistance` 8, `cameraMaxDistance` 80, `cameraSmoothing` 4, `jumpImpulse` 24, `groundProbeExtra` 0.3, `growTime` 0.25, `clientContactMargin` 0.3, `clientSendBudget` 8, `rollTorqueGain` 60, `rollForceGain` 6, `stuckVisualMode` "Weld", `stuckEmbed` 0.35, `Flags = { AvatarPusher = false, BigBallMode = false, RewardedAds = false }`, `Budgets = { maxActivePartsPerServer = 500, meshTriangles = { 300, 300, 800, 2500, 2500 } }` (index = tier). Must be loadable by Lune (no Roblox API).
- [X] T021 [P] Create `src/shared/Content/GreyBoxRoom.luau` (data only, no Roblox API, exports the `TierDef`, `CubeSpawn` and `Room` types from data-model §2): `halfExtent = 36`, `wallHeight = 20`, `kerb = { x = -20, z = -12, length = 22, depth = 2, height = 1.0 }`, `spawnRingRadius = 5`, `spawnSlots = 12`, `tiers` = sizes 0.75 / 0.95 / 1.2 / 1.5, counts 12 / 9 / 6 / 3, shades 200 / 160 / 120 / 80, and the 30 `cubes` with IDs `T<tier>-<two digit index>` at the exact x,z positions in data-model §2 (Tier 1: 01 (11,0) · 02 (0,12) · 03 (−11,0) · 04 (3,−13) · 05 (15,9) · 06 (−9,15) · 07 (−15,−7) · 08 (9,−18) · 09 (19,−4) · 10 (−3,20) · 11 (−16,−19) · 12 (−24,−18); Tier 2: 01 (24,8) · 02 (21,−14) · 03 (8,27) · 04 (−14,26) · 05 (−27,10) · 06 (−25,−4) · 07 (13,−26) · 08 (28,−3) · 09 (−5,−26); Tier 3: 01 (30,20) · 02 (−30,22) · 03 (−30,−26) · 04 (28,−24) · 05 (0,31) · 06 (−8,−31); Tier 4: 01 (32,31) · 02 (−32,31) · 03 (31,−31)). `y` is not stored.

### Config and Content tests

- [X] T022 [P] Create `tests/unit/Config.test.luau` asserting data-model §1: every number is finite and positive (except `fallRespawnY`, which is negative); `cameraMinDistance ≤ cameraMaxDistance`; `baseSpeed ≤ speedCap`; `speedCap < maxServerBallSpeed`; `startDiameter ≥ 2`; `knockOffCount ≥ 1`; `maxVisibleStuck ≤ maxTrackedStuck`; `stuckVisualMode` is `"Weld"` or `"Follower"`; the three feature flags exist and are `false`; `Budgets.meshTriangles` has entries for tiers 1 to 5 equal to 300, 300, 800, 2500, 2500 (depends on T020).
- [X] T023 [P] Create `tests/unit/GreyBoxRoom.test.luau` asserting data-model §2: exactly 30 cubes; IDs unique; per-tier counts equal `TierDef.count`; tier sizes strictly ascend; every cube is within `halfExtent − 4`; any two cubes are at least 4 studs apart (centre to centre); each of the 12 spawn slots (evenly spaced on the ring of radius `spawnRingRadius`) has a Tier 1 cube within 10 studs; Tier 1 size ≤ `absorbRatio × startDiameter` and every other tier size is above it. Also the chain check on fixed numbers using the room's real tier sizes and `Rules.Growth`: from D=2, 22 Tier-1 pickups open Tier 2 (D ≥ 2.375, and 21 do not), then 27 Tier-2 pickups open Tier 3 (D ≥ 3.0, and 26 do not), then 25 Tier-3 pickups open Tier 4 (D ≥ 3.75, and 24 do not) (depends on T016, T021).
- [X] T024 Create `tests/unit/run.luau`: requires every `*.test.luau` suite in `tests/unit`, then calls `harness.summary()` so the process exits non-zero on any failure (depends on T009 to T014, T022, T023). Run `lune run tests/unit/run` and confirm every suite passes.

### Verification command and remotes

- [X] T025 Create `scripts/check.sh` (`#!/usr/bin/env bash`, `set -euo pipefail`, fail-fast, `chmod +x`) running in order (research R9): `stylua --check src tests scripts`; `selene src tests` (after `selene generate-roblox-std` if T007 says it is needed); `rojo sourcemap default.project.json --output sourcemap.json`; `luau-lsp analyze` on `src` and `tests/studio` in strict mode with the Roblox definitions file (download `globalTypes.d.luau` for luau-lsp tag `1.70.1` to an ignored path and confirm the filename); `lune run tests/unit/run`; then the Rules guard: a word-bounded `grep -nE` over `src/shared/Rules` for `Instance`, `workspace`, `game`, `task`, `math.random`, `os.clock`, `os.time`, `tick`, `DateTime`, `Vector3`, `CFrame`, `GetService`, `Enum`, `require(script`, failing on any hit (comments are not exempt) (FR-005). Accept an optional `RULES_DIR` env var (default `src/shared/Rules`) so T063 can point the guard at a temp directory.
- [X] T026 [P] Create `src/server/Remotes.luau`: creates `ReplicatedStorage.Remotes` with three `RemoteEvent`s named `Absorb`, `Bump`, `RespawnBall`, exports them, and is required before any player joins (`contracts/remotes.md`).
- [X] T027 Run `scripts/check.sh` and confirm exit code 0 (depends on T005 to T008, T015 to T026).

**Checkpoint**: Foundation ready. The Rules are tested, `scripts/check.sh` works, user stories can begin. The server tasks of US1 and the client tasks of US1 can run in parallel.

---

## Phase 3: User Story 1 - Core Rolling, Absorbing, and Growing Loop (Priority: P1) 🎯 MVP

**Goal**: A player joins, controls a 2-stud ball with no menu or avatar, absorbs a first cube within 5 s, sees cubes stick, the ball grow by volume, the speed rise as `D^0.5`, the camera pull back to `4 × D`, and can hop a low kerb.

**Independent Test**: Solo in the room (quickstart S1 to S4 and S8): first pickup within 5 s; Tiers 2, 3 and 4 become absorbable in turn; camera distance follows `4 × D`; one hop of about 1.5 studs clears the 1.0-stud kerb with no double jump; never more than 30 stuck visuals; no visible jitter when the ball grows.

### Server (US1)

- [X] T028 [P] [US1] Create `src/server/WorldSpawner.luau`: `start()` builds `Workspace.GreyBoxRoom` from `Content.GreyBoxRoom` (anchored grey `Floor` and `Walls` at ±`halfExtent` with `wallHeight`, the `Kerb` part, and a `Cubes` folder); one anchored `Part` per cube named by its ID, cube-shaped at `Vector3.new(x, size/2, z)`, `Size`/`Tier` attributes (static) and `Taken = false`, grey `Color3` from the tier `shade`; plain parts only (no art). Keeps the registry of `RoomCube` records (`id`, `tier`, `size`, `spawnCFrame`, `part`, `state` `"Available" | "Taken" | "Scattered"`, `respawnAt?`, `availableAt?`; data-model §3). Exports `getCube(id): RoomCube?`, `markTaken(cube, now)` (state `Taken`, `Taken = true`, `Transparency = 1`, `CanCollide = false`, `CanTouch = false`, `respawnAt = now + Config.respawnDelay`) and `getSpawnSlot(index: number): Vector3` (one of 12 evenly spaced slots on the spawn ring, `y` above the floor). Reads time via `os.clock()` passed in, never inside Rules.
- [X] T029 [P] [US1] Create `src/server/BallService.luau` and export its `Session` type (all PlayerBall fields from data-model §4). On `PlayerAdded` (and for players already in game): create a session and a `Part` named `Ball_<UserId>` in `Workspace.Balls`, `Shape = Ball`, size `Config.startDiameter`, `CustomPhysicalProperties(1, 0.8, 0, 1, 1)`, an `Attachment` and an `AngularVelocity` (`RelativeTo = World`, goal zero, `MaxTorque` left for the client to set from `rollTorqueGain`), placed at a free spawn slot, `SetNetworkOwner(player)` (FR-013); write attributes `Diameter` (= 2) and `Stuck` (= ""). Exports `getSession(player): Session?`, `setDiameter(session, newDiameter)` (updates `authoritativeDiameter` and the `Diameter` attribute at once, then eases the physical `Size` over `Config.growTime` per Heartbeat step, research R6) and `publishStuck(session)` (writes the `Stuck` attribute from `StuckStack.visibleTail(stack, Config.maxVisibleStuck)`, entries `id,dx,dy,dz` separated by `;`, direction rounded to 2 decimals, at most 30 entries; contract `replicated-state.md`). On `PlayerRemoving` destroy the ball and drop the session (no leaked parts).
- [X] T030 [US1] Create `src/server/AbsorbService.luau` exporting `tryAbsorb(session, objectId: unknown, now: number): string` (a result code: `"Ok"`, `"BadArgument"`, `"UnknownObject"`, `"AlreadyTaken"`, `"OutOfRange"`, `"TooBig"`) and wiring `Remotes.Absorb.OnServerEvent` as a thin wrapper that takes `...unknown` (FR-015, `contracts/remotes.md`). Check order for now: exactly one argument and `typeof(objectId) == "string"`; `WorldSpawner.getCube`; cube state `Available` and `now ≥ availableAt`; 3D distance from ball centre to cube centre ≤ `physicalDiameter/2 + size/2 + Config.absorbDistanceTolerance` using the server's registry size; `Rules.Absorb.canAbsorb(session.authoritativeDiameter, cube.size, Config.absorbRatio)`. Nothing is mutated before all pass. On success: `WorldSpawner.markTaken`; push a `StuckEntry` `{ id, size, tier, dir }` with `dir = ballCFrame:PointToObjectSpace(cubePosition).Unit` rounded to 2 decimals via `StuckStack.push(stack, entry, Config.maxTrackedStuck)`; `BallService.setDiameter(session, Growth.growDiameter(D, size, Config.growthK))`; `BallService.publishStuck`. Rejections are silent: no `warn`, no error, never sent to the client (SC-007). The server never reads a size, score or diameter from the client (depends on T028, T029).
- [X] T031 [US1] Create `src/server/Main.server.luau`: requires and starts, in order, `Remotes`, `WorldSpawner`, `BallService`, `AbsorbService` (depends on T026, T028 to T030).

### Client (US1) — can run in parallel with the server tasks above

- [X] T032 [P] [US1] Create `src/client/JumpButton.luau`: shown only when `UserInputService.TouchEnabled`; a `ScreenGui` button in the bottom-right at least `96 × 96` px (use `UDim2.fromOffset(96, 96)` or larger with a safe margin), with a symbol glyph and no words; exports a signal (`BindableEvent` or callback) that fires on tap; meaning is carried by shape and position, not colour alone (Constitution VI).
- [X] T033 [P] [US1] Create `src/client/CameraController.luau`: uses the default `Custom` camera with `CameraSubject = Workspace.Balls.Ball_<UserId>` (wait for it); each `RenderStepped` moves a stored distance `d` towards `Rules.Movement.cameraDistance(Diameter, Config.cameraMultiplier, Config.cameraMinDistance, Config.cameraMaxDistance)` with `d += (target − d) · (1 − math.exp(−Config.cameraSmoothing · dt))` and writes `LocalPlayer.CameraMinZoomDistance` and `CameraMaxZoomDistance` to `d` (research R5).
- [X] T034 [P] [US1] Create `src/client/StuckVisuals.luau`: for every ball in `Workspace.Balls` (including late joiners and removed balls), parse the `Stuck` attribute (`;`-separated `id,dx,dy,dz`; skip malformed entries, never throw), diff against the current visuals, create missing ones and destroy those no longer listed (this handles pickup, the 31st-object eviction and knock-off). Each visual is a client-side `Part` sized from the cube's `Size` attribute and shaded by its `Tier`, `CanCollide = false`, `Massless = true`, placed at `ballLocalDirection * (r + S * Config.stuckEmbed)` with `r = ballPart.Size.X / 2`. `Config.stuckVisualMode = "Weld"`: a legacy `Weld` (`Part0 = ball`, `Part1 = visual`) re-seated on growth by updating `Weld.C1`, not the part's `CFrame`. `"Follower"`: no weld; each `RenderStepped` sets `visual.CFrame = ball.CFrame * offset(r)`. Destroy a ball's visuals when the ball is removed (FR-022, research R4, R10).
- [X] T035 [US1] Create `src/client/BallController.luau` (depends on T032): each frame read the move vector with `PlayerModule:GetControls():GetMoveVector()`, convert it to a world direction using the camera's flattened `CFrame` and normalise it (research R3); drive the owned ball with `AngularVelocity = Y × d · (v / r)` where `v = Rules.Movement.targetSpeed(Diameter, Config.baseSpeed, Config.startDiameter, Config.speedExponent, Config.speedCap)`, set `MaxTorque` from `Config.rollTorqueGain · mass · r²`, plus `ApplyImpulse(d · mass · Config.rollForceGain · dt)`; with no input the goal is zero. Jump on `Space` or the `JumpButton` signal via `ApplyImpulse(Y · mass · Config.jumpImpulse)` only when a downward raycast of `r + Config.groundProbeExtra` hits static room geometry (no double jump) (FR-019, FR-020, research R6). Contact scan each Heartbeat over the cube registry: for each cube whose `Taken` attribute is false and whose centre distance is ≤ `r + size/2 + Config.clientContactMargin`, if `Rules.Absorb.canAbsorb(Diameter, size, Config.absorbRatio)` then fire `Remotes.Absorb:FireServer(id)` with a 0.5 s per-cube pending flag and a send budget of `Config.clientSendBudget` per second (research R8). Every 0.1 s set each cube's `CanCollide` locally: `false` if absorbable for the local `Diameter` or `Taken`, otherwise `true` (research R7). Send only the cube ID; no sizes or speeds.
- [X] T036 [US1] Create `src/client/Main.client.luau` starting `CameraController`, `StuckVisuals` and `BallController` (depends on T033 to T035).

### Studio verification (US1)

- [X] T037 [US1] 🔒 Studio: Studio spike. Serve with `rojo serve default.project.json`, connect Studio, press Play, and confirm via the Studio MCP server (research R3, R5, plan Risk Results): WASD and the touch thumbstick move the ball with no character; the default camera accepts the ball as `CameraSubject`; changing the zoom limits each frame does not snap. If either fails, apply the named fallback (R3: `CharacterAutoLoads = true` with a hidden character reading `Humanoid.MoveDirection`, changing only `BallController`'s input function; R5: a `Scriptable` fixed-pitch orbit camera, changing only `CameraController`). Tune `rollTorqueGain` and `rollForceGain` in `src/shared/Config.luau` until the ball rolls without slipping at `baseSpeed`. Read the console with `get_console_output` (depends on T031, T036). **Result (2026-10-25)**: no-character input kept, reading `CharacterContext.MoveAction` because current Studio removed `GetMoveVector` (research R3 result); default camera kept; gains unchanged (no slip at `baseSpeed`); `ReplicationFocus` fix for streaming. Touch thumbstick check moves to T080.
- [X] T038 [US1] 🔒 Studio: Run quickstart scenarios S1, S2, S3, S4 and S8 solo. Expected: first pickup within 5 s; Tiers 2, 3, 4 reached in about 2 min (the room refills in US3 via T049, so tiers 3 and 4 may need the respawn work; record what was reachable); ball speed rises about `√D`; camera distance is `4 × D`; one hop of about 1.5 studs, no second hop, kerb cleared; with 31 or more pickups never more than 30 visuals while the diameter keeps growing. Fix defects in the owning file before ticking (depends on T037). **Result (2026-10-25)**: S1 pass (first pickup 2.0 s); S2 pass after T090 (solo autopilot: Tier 2 at 24 s, Tier 3 at 62 s, Tier 4 at 101 s); S3 pass; S4 pass on PC (1.47-stud hop, kerb cleared, no double hop); S8 pass (248 pickups, never more than 30 visuals, D 5.18).
- [X] T039 [US1] Create `tests/studio/JitterProbe.luau` (maps to `ServerStorage.Tests`, not a `.spec`, not run by Jest): a Studio script run through MCP `execute_luau` implementing quickstart §6 for the current `Config.stuckVisualMode`. Resting phase: a ball on the floor with 30 visuals attached, 20 growth steps through the real `BallService.setDiameter` path; log the maximum change of `Position.Y` and the maximum `AssemblyLinearVelocity.Magnitude` between consecutive Heartbeats. Rolling phase: same at about 15 studs/s. Pass thresholds: resting height deviation below 0.05 studs, resting speed below 1 stud/s, and speed deviation below 1 stud/s during growth (research R4).
- [ ] T040 [US1] 🔒 Studio: Run `JitterProbe` for `"Weld"`, then for `"Follower"` if `"Weld"` fails, on a laptop and then on the reference phone (mid-range Android, Galaxy A53/A54 class unless the owner names another). Set `stuckVisualMode` in `src/shared/Config.luau` to the passing mode (`"Weld"` by default). Replace the pending lines with the measured numbers and the decision in `specs/001-grey-box-prototype/plan.md` §Risk Results (both rows, including the R3/R5 outcome from T037) and in `specs/001-grey-box-prototype/research.md` R4 "R4 result" (depends on T039). **Status (2026-10-25)**: laptop part done (`Weld` passes, numbers in plan.md and research R4); the reference-phone run is deferred by the owner (2026-10-25: no real game to measure yet); revisit before the T059 playtest.
- [X] T041 [US1] 🔒 Studio: Capture the viewport at a phone resolution with `screen_capture` showing the jump button at least 96 × 96 px in the bottom right, and save the image path or measured size in the PR description (Quality Gate 2, SC-001 UI check) (depends on T037). **Result (2026-10-25)**: Studio device simulator (`StudioDeviceSimulatorService:SetDeviceAsync("samsung_galaxy_a16")`, landscape, 780 × 360, viewport 685 × 338) then Play and `screen_capture`: `TouchEnabled` true, `Jump` is 96 × 96 px at (565, 160), 24 px from the right edge and 24 px from the bottom. Passes. The same run found that no touch thumbstick appears (T091).

**Checkpoint**: User Story 1 is fully functional and testable independently. **This is the MVP.**

---

## Phase 4: User Story 2 - Obstacle Bumping, Knock-Offs, and Recovery (Priority: P2)

**Goal**: Hitting a too-big cube fast knocks the 3 newest cubes off the ball; they scatter, can be re-collected, and the ball shrinks by their volume, never below 2 studs.

**Independent Test**: Quickstart S5, S6, S7: with 4 or more small cubes stuck, a fast hit (> 15 studs/s) on a Tier 2/3/4 cube pops 3 and shrinks the ball; a slow hit does nothing; with 0 or 1 cubes stuck only those fall off and the diameter stays ≥ 2.

- [X] T042 [P] [US2] In `src/server/WorldSpawner.luau` add `scatter(cube, position: Vector3, availableAt: number)`: state `Scattered`, set `Taken = false`, `Transparency = 0`, `CanCollide = true`, `CanTouch = true`, `CFrame` at the position (y = `size/2`), and in the update loop promote `Scattered` to `Available` when `now ≥ availableAt` (data-model §3). The cube's `spawnCFrame` stays the original (a cube absorbed from a scattered position still respawns at its original `spawnCFrame`).
- [X] T043 [P] [US2] In `src/server/BallService.luau` add the speed ring buffer: one `{ t, speed }` sample per Heartbeat (horizontal speed of `AssemblyLinearVelocity`) kept for `Config.bumpSpeedWindow` seconds in `session.speedSamples`, and export `peakSpeed(session, now): number` returning the maximum sample speed within the last `Config.bumpSpeedWindow` seconds (research R2). The server measures speed itself; it is never sent by the client.
- [X] T044 [US2] In `src/server/AbsorbService.luau` add `tryBump(session, objectId: unknown, now): string` and wire `Remotes.Bump.OnServerEvent` (`contracts/remotes.md` §Bump). Order: one string argument; cube exists; cube is `Available`; distance ≤ `physicalDiameter/2 + size/2 + Config.absorbDistanceTolerance`; `now − session.lastBumpAt ≥ Config.bumpCooldown` (`"Cooldown"`); `Rules.Absorb.isKnockOff(D, size, BallService.peakSpeed(session, now), Config.absorbRatio, Config.bumpSpeedThreshold)` (`"NotAKnockOff"`). On success (an empty stack is allowed and does nothing): `StuckStack.popRecent(stack, Config.knockOffCount)`; `Rules.Growth.shrinkDiameter(D, poppedSizes, Config.growthK, Config.startDiameter)`; scatter each popped cube with `WorldSpawner.scatter` on a ring of `Config.scatterDistance + ballRadius` studs around the ball (evenly spaced, random start angle from `Random.new()`, clamped inside the room, `y = size/2`) with `availableAt = now + Config.scatterGrace`; `BallService.setDiameter`, `BallService.publishStuck`; `lastBumpAt = now`. Rejections stay silent (depends on T030, T042, T043).
- [X] T045 [P] [US2] In `src/client/BallController.luau` extend the contact scan: for a cube with `Taken == false` that is within contact range and NOT absorbable (`Rules.Absorb.canAbsorb` false for the local `Diameter`), fire `Remotes.Bump:FireServer(id)` under the same pending flag and send budget. Send only the ID.
- [X] T046 [US2] 🔒 Studio: Run quickstart S5, S6 and S7 in Play mode. Expected: eat 4 or more Tier 1 cubes then hit a larger cube above 15 studs/s: the 3 newest pop off, land a few studs away, the ball shrinks and the cubes can be eaten again after about 1 s; a slow hit blocks without knocking anything off; with 0 or 1 cubes stuck only those fall off and the diameter never goes below 2. Read the console: zero new errors or warnings. Record the bump-threshold observations for `playtest.md` (depends on T044, T045). **Result (2026-10-25)**: S5, S6, S7 pass after `absorbDistanceTolerance` 2.0 → 6.0 (plan.md "Studio Run"); observations in playtest.md.

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Shared Multiplayer Session and Server Authority (Priority: P2)

**Goal**: Up to 12 players share the room; the server alone decides every pickup, rejects every invalid request, corrects speed hacks, respawns cubes, and the playtest gate (Constitution I) is recorded.

**Independent Test**: Jest-Lua studio tests pass (all six FR-024 rejections plus boundary, stack-of-5 knock-off, registry invariant, speed violation); a multi-client Studio session shows one winner per contested cube, respawn after 15 s and independent balls; the 6-player playtest is recorded in `playtest.md`.

### Server

- [X] T047 [US3] In `src/server/AbsorbService.luau` add the rate limit to `tryAbsorb` and `tryBump`: immediately after the argument type check call `Rules.RateLimit.allow(session.absorbWindow, now, Config.absorbRateLimit, Config.rateLimitWindow)` (a separate `session.bumpWindow` for `Bump`), returning `"RateLimited"` without error. Final order, fixed by plan Design Note 3: type → rate limit → lookup → taken → distance → size. Every string-typed request counts, valid or not. Request 11 and later within one second are refused (FR-015, depends on T044).
- [X] T048 [P] [US3] In `src/server/WorldSpawner.luau` add the respawn loop and registry helpers: a `Taken` cube whose `respawnAt` has passed returns to `Available` at its original `spawnCFrame` with `Taken = false`, `Transparency = 0`, `CanCollide = true`, `CanTouch = true`, `availableAt = nil` (FR-018); `returnToSpawn(cube)` for a cube dropped from a ball that left; and `registryCounts(stacks): { free: number, stacked: number, pendingRespawn: number }` so a test can check `#free + sum(#stack) + #pendingRespawn = 30`. A cube is either in the free set or in exactly one ball's stack. **Superseded by T090**: held cubes now respawn too; the invariant is `#free + #pendingRespawn = 30`.
- [X] T049 [P] [US3] In `src/server/BallService.luau` add the Heartbeat sanity check (`contracts/replicated-state.md` §Server checks): horizontal speed of `AssemblyLinearVelocity`; `Speed` violation if above `Config.maxServerBallSpeed`; `Displacement` violation if the horizontal step per `dt` exceeds `Config.maxServerBallSpeed × Config.displacementSlack`. On violation clamp the velocity (and for `Displacement` set the position back to `lastValidPosition`), `warn` once with user ID, measured value and limit, increment `session.violations`, append a `ViolationLog` entry, and do not reset the same ball more often than once per 0.5 s. Otherwise update `lastValidPosition` and `lastValidVelocity`. Only these violations call `warn` (plan Design Note 4). Also respawn a ball with `Position.Y < Config.fallRespawnY`. Add `respawn(session)`: diameter back to `Config.startDiameter`, stack emptied and its cubes scattered via `WorldSpawner.scatter` as `Available`, ball repositioned to a free spawn slot (data-model §4 lifecycle). In `PlayerRemoving` return the stack's cubes with `WorldSpawner.returnToSpawn` before destroying the ball (depends on T029, T043; API from T048).
- [X] T050 [US3] In `src/server/AbsorbService.luau` wire `Remotes.RespawnBall.OnServerEvent`: ignore extra arguments; accept only if `now − session.lastRespawnAt ≥ Config.respawnBallCooldown` (3 s), then call `BallService.respawn(session)` and set `lastRespawnAt` (`contracts/remotes.md` §RespawnBall; depends on T047, T049).
- [X] T051 [P] [US3] In `src/client/BallController.luau` bind `StarterGui:SetCore("ResetButtonCallback", bindable)` and fire `Remotes.RespawnBall:FireServer()` with no arguments when it triggers (research R3 "Related"; Reset otherwise does nothing with no character). Wrap in `pcall` retry because `SetCore` can fail before CoreScripts load.

### Jest-Lua tests (Constitution II, FR-024)

- [X] T052 [P] [US3] Create `tests/studio/runner.luau`: exports a function that calls `Jest.runCLI` from `DevPackages` against the spec modules under `ServerStorage.Tests`, so it can be started with `return require(game.ServerStorage.Tests.runner)()` through MCP `execute_luau` (FR-006, research R9).
- [X] T053 [US3] Create `tests/studio/AbsorbService.spec.luau` with a stub session (a plain table matching `BallService.Session`) and the real registry, calling `AbsorbService.tryAbsorb` directly. First the six FR-024 rejections, each leaving `authoritativeDiameter` unchanged: (a) unknown object ID → `UnknownObject`; (b) an already-taken cube → `AlreadyTaken`; (c) out-of-range distance → `OutOfRange`; (d) a cube too big for the current diameter → `TooBig`; (e) a non-string `objectId` (number, nil, table) → `BadArgument`; (f) the 11th request inside one second → `RateLimited`, while requests 1 to 10 were evaluated (depends on T047, T052).
- [X] T054 [US3] In `tests/studio/AbsorbService.spec.luau` add: the exact-boundary pickup (a ball with diameter `D` and a cube of size `0.4 × D` passes; size greater by `1e-4` fails); a valid pickup grows the diameter to `(D^3 + 0.6·S^3)^(1/3)` and writes the `Diameter` and `Stuck` attributes; a knock-off with a stack of 5 via `tryBump` pops exactly 3, scatters them as `Available` after `scatterGrace`, and shrinks the diameter (never below 2); a knock-off with an empty stack is a no-op; a contested cube goes to the first request only (Story 3 scenario 1).
- [X] T055 [US3] In `tests/studio/AbsorbService.spec.luau` add: the registry invariant `#free + sum(#stack) + #pendingRespawn = 30` after absorbs, a knock-off, a respawn and a player leaving; and a speed violation (ball velocity set above `Config.maxServerBallSpeed`) being corrected and counted in `session.violations` (depends on T049). **Superseded by T090** (invariant without stack counts, plus refill tests).
- [X] T056 [US3] 🔒 Studio: Run `return require(game.ServerStorage.Tests.runner)()` through MCP `execute_luau` and confirm all tests pass, including the six rejection cases. Fix defects in the owning file (depends on T053 to T055). **Result (2026-10-25)**: 19 of 19 pass, 0 fail, through the runner in Studio; no defects found. `tests/studio/jest.config.luau` was added earlier (plan.md "Studio Run").

### Multiplayer and playtest gate

- [X] T057 [P] [US3] Create `specs/001-grey-box-prototype/playtest.md` (FR-025, Constitution I) as a fill-in template: date, commit SHA, participant counts per age group (at least 3 adults and at least 3 children aged 10 to 12, recorded by age group only, never by name), first-pickup time (≤ 5 s), sphere-resize jitter observed, growth satisfaction, frame rate on the reference phone (≥ 30 fps), bump-threshold tuning observations (from T046), count of rejected honest absorbs, per-player speed violations, the reference phone model confirmed or replaced by the owner (`TODO(REFERENCE_PHONE)`), and an owner sign-off line.
- [ ] T058 [US3] 🔒 Studio: Local Server test with 3 or more simulated clients, then raise to 12 balls (quickstart §7, SC-004): each ball rolls independently; two players going for the same cube get one winner; other players' stuck visuals appear on their balls; cubes respawn after 15 s; no physics instability; a player leaving and rejoining leaves no stray ball or visuals and a fresh 2-stud ball appears on Reset (Story 3 scenarios 1 to 4, quickstart S9). Read the console: zero new errors or warnings (depends on T050, T051, T056). **Status (2026-10-25)**: not run. The Studio MCP tools start one Play session with one client and offer no multi-client path, so 3+ simulated clients and the rejoin check (quickstart S9) need a Local Server test set up in Studio. **Deferred by the owner (2026-10-25)**: too early for multiplayer testing; revisit before the T059 playtest.
- [ ] T059 [US3] 👤 Run the playtest with 6 or more real players (at least 3 adults and 3 children aged 10 to 12) on the private test place (never the live place), including at least one phone at the reference spec. Fill in `specs/001-grey-box-prototype/playtest.md` and collect the owner's sign-off. An agent's statement never counts as owner approval (Constitution preamble). Constitution I: no art, monetization or live-ops work may start until this is signed off (depends on T057, T058).

**Checkpoint**: User Stories 1 to 3 work independently; the validation tests pass; the playtest gate is recorded.

---

## Phase 6: User Story 4 - Repository Foundations and Automated Quality Gate (Priority: P3)

**Goal**: One command, `scripts/check.sh`, gates local work and CI; the repository metadata and docs are clean.

**Independent Test**: From a clean checkout `scripts/check.sh` exits 0; `scripts/test-guard.sh` exits 0 by proving the Rules guard FAILS on a forbidden identifier; `grep -rIi ricokick .` outside `.git` finds nothing; `docs/rollossal-gdd.md` exists and `README.md` links to it and to the constitution.

- [X] T060 [US4] Move the design brief with `git mv README.md docs/rollossal-gdd.md` (create `docs/` first). Keep the content unchanged (FR-007, resolves `TODO(GDD_PATH)`).
- [X] T061 [US4] Create a new concise `README.md` (about 30 lines) with a short project overview, the setup commands (`rokit install`, `wally install`, `scripts/check.sh`, `rojo serve default.project.json`), and links to `docs/rollossal-gdd.md` and `.specify/memory/constitution.md` (FR-007; depends on T060).
- [X] T062 [P] [US4] Create `.github/workflows/check.yml`: trigger `pull_request`; steps: `actions/checkout` (first-party), install Rokit by downloading the pinned release `rojo-rbx/rokit v1.2.0` binary with `curl` (no third-party action, so no new service needs approval, research R9), `rokit install`, `wally install`, `scripts/check.sh` (FR-006, SC-001).
- [X] T063 [P] [US4] Create `scripts/test-guard.sh` (`chmod +x`): makes a temp directory, writes a `.luau` file containing a forbidden identifier (for example `local x = Vector3.new()`), runs the Rules guard from `scripts/check.sh` against it through `RULES_DIR`, expects a non-zero exit, and exits 0 only if the guard failed; cleans up the temp directory. Proves Story 4 scenario 2 without dirtying the tree (research R9).
- [X] T064 [US4] Run `grep -rIi ricokick . --exclude-dir=.git` and `grep -rIi shot-engine-career . --exclude-dir=.git`, and fix every remaining hit outside `specs/001-shot-engine-career` history (including `.claude`, `.opencode`, `.conveyor-backlog.md` and `wally.lock`). Confirm `docs/rollossal-gdd.md` and `README.md` links resolve (depends on T008, T060, T061).
- [ ] T065 [US4] Run `scripts/check.sh` and `scripts/test-guard.sh` locally (both exit 0), push the branch, open a pull request, and confirm the `check` workflow runs green in GitHub Actions (SC-001; depends on T062, T063, T064). Do not merge without owner approval.

**Checkpoint**: All four user stories are complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final gates that span all stories.

- [X] T066 [P] Verify FR-004: `grep -L '^--!strict' $(git ls-files '*.luau')` prints nothing (every `.luau` file starts with `--!strict`). Fix any file listed.
- [X] T067 🔒 Studio: SC-007 console cleanliness. Run a Studio playtest driven through the Studio MCP server (start play, drive the ball, absorb, bump, reset, stop) and read the console with `get_console_output`: zero new errors and zero warnings. A speed-violation `warn` in honest play is a bug (raise `maxServerBallSpeed` or fix the cause). Record the result for the PR. **Result (2026-10-25)**: zero errors and warnings from game code in a solo drive, absorb, bump, Reset run after `displacementSlack` 1.5 → 4; only Studio's own `ContentId 203785492` line remains.
- [ ] T068 Walk through `quickstart.md` sections 1 to 7 and tick each pass condition in its "Expected outcomes summary"; note any tuning changes made (`respawnDelay`, `bumpSpeedThreshold`, `absorbDistanceTolerance`, tier counts as data per research R1/R12) in `specs/001-grey-box-prototype/plan.md`.
- [X] T069 Draft the pull request description stating how each Quality Gate was met (plan.md "Quality Gates mapping": gate 1 `scripts/check.sh`; gate 2 Studio playtest and console read plus the phone viewport capture from T041; gate 3 and 4 N/A; gate 5 `tasks.md` ticks) and the Constitution check outcome. Mark every completed task in this file `- [x]`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies. T001 to T007 are all parallel; T008 follows T001 and T002.
- **Foundational (Phase 2)**: depends on Setup. Blocks all user stories. Tests T010 to T014 first, then T015 to T019 (Rules), in parallel with T020, T021, T026; T022 and T023 need their modules; T024 needs all tests; T025 needs the configs; T027 is the gate.
- **User Stories (Phase 3+)**: all depend on Foundational. After that:
  - US1 is the MVP and must come first because US2 and US3 extend its files.
  - US2 and US3 both edit `AbsorbService.luau`, `BallService.luau` and `WorldSpawner.luau`, so run them in sequence unless two agents agree on a merge order. Their `[P]` tasks are disjoint only within a phase.
  - US4 (T060 to T065) touches repository metadata only and can run in parallel with US1 to US3 once T027 passes (T062 and T063 need `scripts/check.sh`).
- **Polish (Phase 7)**: after the stories it checks.

### User Story Dependencies

- **US1 (P1)**: starts after Foundational. No dependency on other stories.
- **US2 (P2)**: needs US1's server and client files (it adds `tryBump`, `scatter`, `peakSpeed` and the client Bump send).
- **US3 (P2)**: needs US1 (the `tryAbsorb` it tests) and US2 (`tryBump`, `scatter`, `peakSpeed`) for the full test file; rate limit, respawn, speed check and `RespawnBall` can start after US1.
- **US4 (P3)**: independent of US1 to US3 except for `scripts/check.sh` (T025); T065's CI result needs the whole tree to pass.

### Within Each Story

- Lune tests before the Rules they cover; Config/Content before anything that reads them.
- Server: `WorldSpawner` and `BallService` before `AbsorbService`, then `Main.server`.
- Client: `JumpButton` before `BallController`; `Main.client` last.
- Studio tasks (🔒) last in the story and one agent at a time.

### Parallel Opportunities

- Phase 1: T001 to T007.
- Phase 2: T009 to T014 (tests) together; T015 to T019 (Rules) together; T020, T021, T026 with them; then T022 and T023.
- US1: T028 and T029 together, and T032, T033, T034 together with the server tasks (client and server files are disjoint).
- US2: T042, T043, T045. US3: T048, T049, T051, T052, T057. US4: T062, T063.

---

## Parallel Example: Phase 2 and User Story 1

```bash
# Phase 2: all Rules tests together (disjoint files)
Task: "Create tests/unit/Absorb.test.luau"
Task: "Create tests/unit/Growth.test.luau"
Task: "Create tests/unit/Movement.test.luau"
Task: "Create tests/unit/StuckStack.test.luau"
Task: "Create tests/unit/RateLimit.test.luau"

# Then all Rules modules together:
Task: "Create src/shared/Rules/Absorb.luau"
Task: "Create src/shared/Rules/Growth.luau"
Task: "Create src/shared/Rules/Movement.luau"
Task: "Create src/shared/Rules/StuckStack.luau"
Task: "Create src/shared/Rules/RateLimit.luau"

# User Story 1: server and client files at the same time
Task: "Create src/server/WorldSpawner.luau"
Task: "Create src/server/BallService.luau"
Task: "Create src/client/JumpButton.luau"
Task: "Create src/client/CameraController.luau"
Task: "Create src/client/StuckVisuals.luau"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1: Setup.
2. Phase 2: Foundational; confirm `scripts/check.sh` exits 0 (T027).
3. Phase 3: User Story 1 including the Studio spike and the jitter measurement (T037 to T041).
4. **STOP and VALIDATE**: quickstart S1 to S4 and S8 solo. The jitter result decides `stuckVisualMode` and retires the main risk of this feature.

### Incremental Delivery

1. Setup + Foundational → verification command and pure rules in place.
2. US1 → roll, absorb, grow, camera (MVP, demo solo).
3. US2 → bump and knock-off.
4. US3 → authority, respawn, tests, multi-client, playtest gate (Constitution I).
5. US4 → CI, docs, guard self-test (can be done any time after T027).

### Parallel Team Strategy

With several agents (each in its own worktree, Constitution X): one agent takes Phase 2 Rules and tests, another Config/Content/Remotes, a third `scripts/check.sh`. After the checkpoint: one agent on `src/server`, one on `src/client`, one on US4. Only one agent drives Studio at a time.

---

## Notes

- Finding F-1 (research R1): 30 cubes cannot complete the Tier 4 chain in one pass; the chain needs about 74 pickups before the first Tier 4 cube, so it relies on the 15 s respawn (T048). T038 can therefore only fully confirm Tier 3 and 4 after T048.
- `tests/studio/JitterProbe.luau` (T039) is the only file not listed in plan.md's Project Structure; it holds the quickstart §6 measurement so it is repeatable.
- No player-facing text is added (the jump button is a symbol), so Constitution IX has nothing to localise; no purchases, no stored data (V, VIII); no new tool or package (XII).
- `[P]` marks only tasks on disjoint files. Commit after each task or logical group, and never commit place files or secrets.

---

## Phase 8: Convergence

**Purpose**: Remaining work found by `/speckit-converge` round 1. Phases 1 and 2 (T001 to T026) exist in the tree but are still unticked; Phases 3 to 7 are almost entirely unbuilt (`src/server` holds only `Remotes.luau`, `src/client` and `tests/studio` are empty or missing, `docs/` and `.github/workflows/check.yml` do not exist).

- [X] T070 CRITICAL: Create `tests/studio/runner.luau` and `tests/studio/AbsorbService.spec.luau` covering the six rejections, the exact boundary, a stack-of-5 knock-off, the registry invariant and the speed violation (the work of T052 to T055). `default.project.json` maps `ServerStorage.Tests` to `tests/studio` and `scripts/check.sh` analyses it, so while the folder is missing `rojo sourcemap` and `luau-lsp` cannot pass per Constitution II, FR-024, SC-002 (missing)
- [X] T071 CRITICAL: Create `src/server/WorldSpawner.luau` building `Workspace.GreyBoxRoom` and the 30-cube registry from `Content.GreyBoxRoom` (the work of T028; then T042 `scatter` and T048 respawn loop, `returnToSpawn`, `registryCounts`) per FR-023, FR-018 (missing)
- [X] T072 CRITICAL: Create `src/server/BallService.luau` with the `Session` type, per-player ball `Part`, network ownership, `Diameter` and `Stuck` attributes, growth easing and cleanup on leave (the work of T029; then T043 speed ring buffer and T049 Heartbeat speed and displacement check, fall respawn, `respawn`) per FR-013, FR-014, FR-016 (missing)
- [X] T073 CRITICAL: Create `src/server/AbsorbService.luau` with `tryAbsorb` (type, rate limit, lookup, taken, distance, size; silent rejections), `tryBump` and the `RespawnBall` handler, wired to the `Remotes` events (the work of T030, T044, T047, T050) per FR-015, FR-016, FR-017, Constitution II (missing)
- [X] T074 CRITICAL: Create `src/server/Main.server.luau` starting `Remotes`, `WorldSpawner`, `BallService`, `AbsorbService` in order (the work of T031) per FR-013, US1 (missing)
- [X] T075 HIGH: Create `src/client/JumpButton.luau` (touch only, at least 96 x 96 px, symbol only, bottom right) and `src/client/CameraController.luau` (smoothed zoom toward `Rules.Movement.cameraDistance`) (the work of T032, T033) per FR-020, FR-021, US1/AC3, US1/AC4 (missing)
- [X] T076 HIGH: Create `src/client/StuckVisuals.luau` for every ball: parse the `Stuck` attribute defensively, `Weld` and `Follower` modes behind `Config.stuckVisualMode`, cap at `maxVisibleStuck`, cleanup on ball removal (the work of T034) per FR-022, US1/AC2, SC-006 (missing)
- [X] T077 HIGH: Create `src/client/BallController.luau` (move vector to `AngularVelocity` torque and force, grounded hop on Space or `JumpButton`, contact scan firing `Absorb` and `Bump` by ID only, local `CanCollide` toggling, `ResetButtonCallback` firing `RespawnBall`) and `src/client/Main.client.luau` (the work of T035, T036, T045, T051) per FR-019, FR-020, FR-015, US1/AC1, US2 (missing)
- [X] T078 HIGH: Create `tests/studio/JitterProbe.luau` implementing quickstart §6 for the current `Config.stuckVisualMode` (the work of T039) per SC-006, plan: stuck visual decision (missing)
- [ ] T079 HIGH: 🔒 Studio: With T071 to T077 in place, run the Studio spike and the US1, US2 and multi-client scenarios (T037, T038, T046, T056, T058, T067): confirm no-character input and default camera, tune `rollTorqueGain` and `rollForceGain`, run the Jest suite, run `JitterProbe` on the laptop and set `stuckVisualMode`, read the console for zero errors and warnings, and fill both rows of plan.md "Risk Results" and the research R4 result per SC-001, SC-003, SC-005, SC-006, SC-007 (missing) **Status (2026-10-25)**: Studio spike, tuning, US1 and US2 scenarios (T037, T038, T046), laptop JitterProbe, console (T067) and Risk Results done; Jest (T056) passing (19 of 19); multi-client (T058) deferred by the owner.
- [X] T080 HIGH: 🔒 Studio: Capture the viewport at a phone resolution showing the jump button at least 96 x 96 px bottom right (the work of T041) per FR-020, Quality Gate 2 (missing) **Result (2026-10-25)**: done with T041 (Galaxy A16 in the Studio device simulator, button 96 × 96 px, 24 px from the bottom-right corner).
- [X] T081 HIGH: Create `specs/001-grey-box-prototype/playtest.md` as the fill-in template (the work of T057) per FR-025, Constitution I (missing)
- [X] T082 HIGH: Create `.github/workflows/check.yml` (pull_request, checkout, pinned Rokit from `curl`, `rokit install`, `wally install`, `scripts/check.sh`; the work of T062; the folder is empty) per FR-006, SC-001 (missing)
- [X] T083 HIGH: Create `scripts/test-guard.sh` proving the Rules guard fails on a forbidden identifier through `RULES_DIR` (the work of T063) per FR-005, US4/AC2 (missing)
- [X] T084 HIGH: Move the design brief with `git mv README.md docs/rollossal-gdd.md` and write the new concise `README.md` linking `docs/rollossal-gdd.md` and `.specify/memory/constitution.md` (the work of T060, T061; `docs/` does not exist and `README.md` is still the 16 KB brief) per FR-007, US4/AC3, Constitution TODO(GDD_PATH) (missing)
- [X] T085 HIGH: Run `scripts/check.sh`, fix every failure (StyLua, Selene, luau-lsp strict, Lune suites, Rules guard), then tick T001 to T027 in `tasks.md` as verified (the work of T008, T024, T027); also confirm `Packages/` is created or `default.project.json` copes with it being absent per SC-001, SC-002, FR-005 (partial)
- [X] T086 MEDIUM: Fix the remaining `ricokick` hit in `wally.lock` (line 251, `ricokick/ricokick`) by regenerating it with `wally install`, and fix `.conveyor-backlog.md` or note why it is exempt; then re-run the grep from T064 per FR-001, US4/AC3 (partial)
- [X] T087 MEDIUM: Verify every `.luau` file starts with `--!strict` once all sources exist and fix any listed (the work of T066) per FR-004, Constitution XII (partial)
- [X] T088 MEDIUM: Walk through `quickstart.md` sections 1 to 7 as far as an agent can, tick its "Expected outcomes summary", record tuning changes in `plan.md`, and draft the PR description with the Quality Gate mapping (the work of T068, T069) per SC-001 to SC-007 (missing)
- [X] T089 LOW: Fix the indentation of the `StarterPlayer` block in `default.project.json` (extra leading spaces) per FR-003 (partial)

- [X] T090 HIGH: Make held cubes respawn after `Config.respawnDelay` while the ball keeps a visual-only record (research F-1, quickstart S2/S8, `maxTrackedStuck`): `WorldSpawner.update(now)` respawns every `Taken` cube; `StuckEntry.key` (`<id>#<n>`, server-wide counter) in `AbsorbService` and the `Stuck` attribute; `RoomCube.holderKey` with `WorldSpawner.isHeldBy`; knock-off, Reset and leave release only cubes still pending from the same pickup (`BallService.releasableCubes`); `StuckVisuals` keys visuals by entry key; invariant `#free + #pendingRespawn = 30` with refill, eaten-twice and release tests in `tests/studio/AbsorbService.spec.luau`; data-model §3 to §5, `contracts/replicated-state.md` and `contracts/remotes.md` updated. Verified in Studio through an expect shim (39 of 39) and a 180 s solo run; the Jest run itself waits on T056.
- [ ] T091 HIGH: Touch movement without a character (FR-019, Story 1.1). In the T041 phone run (Galaxy A16 in the Studio device simulator) no thumbstick appeared: the `StarterPlayer.PlayerModule` `ControlModule` creates `TouchGui` only when the player has a Humanoid (`UpdateTouchGuiVisibility`: `doShow = self.humanoid and ...`), and Rollossal has no character, so a phone player cannot move. Fix in `src/client` only: either a small own thumbstick (left-half drag) feeding `BallController`'s move reader, or the research R3 fallback (`CharacterAutoLoads = true` with a hidden character). Verify in the device simulator that dragging moves the ball and the jump button still works.
