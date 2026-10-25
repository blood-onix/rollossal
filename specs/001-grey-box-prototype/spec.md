# Feature Specification: Grey-Box Prototype

**Feature Branch**: `001-grey-box-prototype`

**Created**: 2026-10-24

**Status**: Draft

**Input**: User description: "Build the first playable grey-box of Rollossal: one rolling ball per player that sticks to anything small enough, grows by volume, and has a camera that pulls back as it grows. One room with 30 cubes in 4 sizes. The goal is a fun test with 6 people, and proof that the core physics (a growing sphere with welded parts) works without jitter. Design brief: README.md §3.1, §3.2, §12 (risks). Constitution: I, II, III, VI, X, XII."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Core Rolling, Absorbing, and Growing Loop (Priority: P1)

A player joins the grey-box room and immediately controls a rolling sphere (starting at 2 studs diameter) with no pre-run menu and no visible avatar. Within 5 seconds of spawning, the player steers into nearby small cubes, absorbs them on contact, sees them stick to the ball's surface while the ball's diameter grows by volume, and experiences the camera smoothly pulling back as the ball progresses through all 4 cube sizes in the room.

**Why this priority**: This is the foundational core toy of Rollossal and the mandatory Constitution Principle I gate. Under Principle I, no art, monetization, or live-ops work may begin until ball control, absorption, and growth are proven fun in grey-box playtesting and signed off by the owner.

**Independent Test**: Can be tested solo in the grey-box room by spawning, rolling into Tier 1 cubes within 5 seconds, growing large enough to unlock Tiers 2, 3, and 4 in sequence within two minutes, jumping over a low kerb/step on PC or mobile touch, and verifying smooth camera pullback and zero physics jitter.

**Acceptance Scenarios**:

1. **Given** a newly joined player spawns in the grey-box room as a 2-stud diameter ball with their character avatar hidden, **When** the player steers using thumbstick or WASD toward the nearest smallest cubes, **Then** the ball rolls smoothly in the input direction and absorbs its first cube within 5 seconds of joining.
2. **Given** a player's ball has diameter $D$ and approaches a cube of size $S$ where $S \le 0.4 \times D$, **When** the ball comes within absorption range of the cube, **Then** the server validates the pickup, increases the ball's authoritative diameter to $(D^3 + 0.6 \times S^3)^{1/3}$, attaches the cube visually to the ball (`CanCollide = false`, `Massless = true`), and capped visual stuck objects never exceed the 30 most recent pickups.
3. **Given** a player's ball grows in diameter across the 4 cube size tiers in the 30-cube room, **When** the authoritative diameter increases, **Then** the player's maximum rolling speed scales with $\text{diameter}^{0.5}$ (up to a configured cap) and the camera smoothly adjusts its follow distance toward $4 \times \text{diameter}$ (within configured minimum and maximum clamp bounds).
4. **Given** a player is rolling on PC or mobile, **When** the player presses Space on PC or taps the on-screen Jump button ($\ge 96\text{ px}$) on mobile, **Then** the ball performs a small vertical hop sufficient to clear low kerbs and steps without allowing double-jumping in mid-air.

---

### User Story 2 - Obstacle Bumping, Knock-Offs, and Recovery (Priority: P2)

When a player rolls into a cube whose size exceeds $0.4 \times \text{ballDiameter}$, that cube acts as a solid physical obstacle. If the player impacts the obstacle at a speed above the configured bump speed threshold, up to the 3 most recently absorbed cubes knock off the ball, scatter into the room where they can be collected again, and the ball shrinks by their volume (never below the 2-stud starting diameter).

**Why this priority**: Bumping and knock-offs provide physical feedback and risk without permanent punishment, completing the core physical interaction loop defined in the design brief (§3.2).

**Independent Test**: Can be tested in a solo session by absorbing at least 4 small cubes, accelerating into a Tier 3 or Tier 4 cube above the bump speed threshold, and verifying that 3 stuck cubes detach and scatter, the ball shrinks back by their volume, and the scattered cubes can be re-absorbed.

**Acceptance Scenarios**:

1. **Given** a player's ball has absorbed at least 3 cubes and has diameter $D > 2$, **When** the ball collides with a cube of size $S > 0.4 \times D$ at a relative impact speed exceeding `bumpSpeedThreshold`, **Then** the server removes the 3 most recently absorbed cubes from the ball, reduces the ball's authoritative diameter by their volume contribution (clamped to never drop below `startDiameter = 2`), and makes the 3 scattered cubes available for re-collection in the room.
2. **Given** a player's ball has absorbed fewer than 3 cubes (or 0 cubes), **When** the ball collides with an unabsorbable cube above `bumpSpeedThreshold`, **Then** only the currently stuck cubes (if any) are knocked off and the ball's diameter never shrinks below 2 studs.
3. **Given** a player's ball touches an unabsorbable cube at a gentle speed at or below `bumpSpeedThreshold`, **When** the contact occurs, **Then** the cube blocks the ball physically without knocking off any stuck cubes.

---

### User Story 3 - Shared Multiplayer Grey-Box Session and Server Authority (Priority: P2)

Up to 12 players (with a target playtest group of at least 6 simultaneous players: 3+ adults and 3+ children aged 10–12) join the same server, each controlling their own independent rolling ball in the 30-cube room. The server enforces strict authority over every absorption and movement check so no client can spoof sizes, absorb taken or distant objects, exceed rate limits, or speed-hack, while absorbed cubes respawn simply so the shared room never runs dry.

**Why this priority**: Rollossal is a multiplayer co-op experience where client-owned ball physics must coexist safely with server-authoritative progression (Constitution Principle II) and support a 6-player playtest (Constitution Principle I).

**Independent Test**: Can be tested via automated Studio tests for all invalid absorb/speed cases and a 6-player multiplayer session verifying concurrent rolling, non-duplicating cube pickups, simple cube respawning, and playtest recording in `specs/001-grey-box-prototype/playtest.md`.

**Acceptance Scenarios**:

1. **Given** multiple players are rolling in the same server, **When** two players attempt to absorb the same cube nearly simultaneously, **Then** the server awards the cube to the first valid request and rejects the second request because the cube is already marked taken.
2. **Given** a client sends an absorb request to the server, **When** the argument is not a string, references an unknown or already-taken object ID, exceeds the allowed distance ($\text{ballRadius} + \text{size}/2 + \text{absorbDistanceTolerance}$), violates the size rule ($S > 0.4 \times D$), or is the 11th request within 1 second (`absorbRateLimit = 10/s`), **Then** the server rejects the request and leaves the player's diameter unchanged.
3. **Given** a client-owned ball moves faster than `maxServerBallSpeed` on a server heartbeat, **When** the server speed sanity check runs, **Then** the server clamps or resets the ball's velocity/position to within legal bounds and logs the violation.
4. **Given** 6 players are actively absorbing cubes in the 30-cube room, **When** cubes are absorbed, **Then** absorbed cubes respawn after their configured simple respawn delay so players always have absorbable targets across all 4 size tiers.

---

### User Story 4 - Repository Foundations and Automated Quality Gate (Priority: P3)

A developer or coding agent working on Rollossal runs a single verification command (`scripts/check.sh`) locally or in GitHub Actions CI that validates formatting, linting, strict static types, pure-rule isolation (`src/shared/Rules`), and unit tests, backed by clean project metadata (`wally.toml`, `rokit.toml`, `default.project.json`, `docs/rollossal-gdd.md`, `.gitignore`).

**Why this priority**: Establishes Constitution Principles III, X, and XII and resolves all four repository setup TODOs (`TODO(GDD_PATH)`, `TODO(CHECK_SCRIPT)`, `TODO(GITIGNORE)`, and Ricokick template leftovers) so every task in this feature and subsequent features is gated by automated checks.

**Independent Test**: Can be tested by executing `scripts/check.sh` from a clean checkout and verifying exit code 0, and by introducing a forbidden Roblox identifier in `src/shared/Rules` to confirm `scripts/check.sh` fails as required.

**Acceptance Scenarios**:

1. **Given** the repository source tree and configuration files are set up, **When** a developer or CI workflow runs `scripts/check.sh`, **Then** StyLua formatting check, Selene linting, `luau-lsp analyze` in strict mode, Lune unit tests (`tests/unit`), and the `src/shared/Rules` forbidden-identifier check all run and exit with status 0.
2. **Given** a module under `src/shared/Rules` contains any forbidden Roblox or non-deterministic identifier (`Instance`, `workspace`, `game`, `task`, `math.random`, `os.clock`, `os.time`, `tick`, `DateTime`, `Vector3`, `CFrame`, or any service), **When** `scripts/check.sh` is executed, **Then** the script fails with a non-zero exit code.
3. **Given** a developer inspects the repository root and documentation, **When** checking `docs/rollossal-gdd.md`, `README.md`, `wally.toml`, `rokit.toml`, and `.gitignore`, **Then** the full design brief lives at `docs/rollossal-gdd.md`, `README.md` links to it concisely, no leftover `ricokick` references remain, and `.rbxl`/`.rbxlx` and secret files are git-ignored.

---

### Edge Cases

- **Exact Absorb Boundary**: When an object's size $S$ is exactly equal to $0.4 \times \text{ballDiameter}$, absorption MUST succeed; when $S$ is even slightly above $0.4 \times \text{ballDiameter}$ (e.g., $+10^{-4}$ studs), absorption MUST fail.
- **Shrink Floor on Knock-Off**: When a ball loses stuck objects due to a high-speed bump, floating-point rounding or repeated knock-offs MUST never reduce the ball's diameter below `startDiameter` (2 studs).
- **31st Stuck Object Visual Cap**: When a player absorbs their 31st object (and beyond), the oldest visible stuck object is removed so at most `maxVisibleStuck` (30) stuck visuals remain attached, while the ball's volume and diameter retain the growth from buried objects.
- **Welded-Part Resize Jitter**: If resizing a rolling physics sphere with welded parts causes visible or measurable physics jitter, `StuckVisuals` MUST switch to the documented fallback where stuck visuals are client-side followers updated relative to the ball's transform rather than physics welds.
- **Rate Limit Bursting**: If a client fires more than 10 absorb requests within a 1-second window (e.g., rolling into a dense pile or exploiting), requests 1 through 10 are evaluated normally and request 11+ within that window are rejected cleanly without erroring.
- **Player Disconnect / Respawn Mid-Session**: When a player leaves the server, their ball and any attached visuals are cleaned up without leaking parts; if a player resets or respawns, a fresh 2-stud ball is spawned cleanly.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Repository Foundations & Quality Gates

- **FR-001**: Repository metadata in `wally.toml` MUST use package name `rollossal/rollossal`, and `rokit.toml` comments MUST reference Rollossal and `specs/001-grey-box-prototype/plan.md` with no leftover references to `ricokick` or `001-shot-engine-career`.
- **FR-002**: A root `.gitignore` MUST exclude Roblox place files (`*.rbxl`, `*.rbxlx`, `*.rbxl.lock`, `*.rbxlx.lock`), secrets (`.env*`, `*.pem`, `*.key`), generated build artifacts, and tool caches (`sourcemap.json`, `Packages/`, `ServerPackages/`, `DevPackages/`).
- **FR-003**: `default.project.json` (targeting Rojo 7.7.1) MUST map `src/shared` to `ReplicatedStorage.Shared`, `src/server` to `ServerScriptService`, `src/client` to `StarterPlayer.StarterPlayerScripts`, and map Wally `Packages`, `ServerPackages`, and `DevPackages`.
- **FR-004**: Repository root MUST include `stylua.toml`, `selene.toml` (configured with `roblox` standard library), and `.luaurc` with `languageMode = "strict"`, and every `.luau` file in the repository MUST begin with `--!strict`.
- **FR-005**: `scripts/check.sh` MUST execute StyLua check, Selene lint, `luau-lsp analyze`, Lune unit tests (`tests/unit`), and a forbidden-identifier check on `src/shared/Rules` that fails if any of `Instance`, `workspace`, `game`, `task`, `math.random`, `os.clock`, `os.time`, `tick`, `DateTime`, `Vector3`, `CFrame`, or `GetService` appears under `src/shared/Rules`.
- **FR-006**: The repository MUST include a Lune unit test runner executing suites under `tests/unit`, a Jest-Lua test runner bootstrap for Studio integration tests under `tests/studio`, and a GitHub Actions workflow under `.github/workflows/` that runs `scripts/check.sh` on every pull request.
- **FR-007**: The full game design brief MUST be moved to `docs/rollossal-gdd.md` and `README.md` MUST be replaced with a concise project overview that links to `docs/rollossal-gdd.md` and `.specify/memory/constitution.md`.

#### Part B: Pure Rules (`src/shared/Rules`)

- **FR-008**: `src/shared/Rules` MUST be pure Luau with zero Roblox engine API dependencies and MUST implement the absorb eligibility check: an object of size $S$ is absorbable by a ball of diameter $D$ if and only if $S \le \text{absorbRatio} \times D$ (with default `absorbRatio = 0.4`).
- **FR-009**: `src/shared/Rules` MUST implement volume-based growth: absorbing an object of size $S$ into a ball of diameter $D$ yields $\text{newD} = (D^3 + k \times S^3)^{1/3}$ (with default `k = 0.6`), and MUST implement the inverse shrink rule for knock-offs that subtracts $\sum k \times S_i^3$ from $D^3$ while clamping the resulting diameter to never fall below `startDiameter` (2 studs).
- **FR-010**: `src/shared/Rules` MUST implement the ball target speed curve scaling with $\text{diameter}^{0.5}$ capped at a configured maximum speed, and the camera target distance curve equal to $4 \times \text{diameter}$ clamped between configured minimum and maximum distances.
- **FR-011**: Every function in `src/shared/Rules` MUST be covered by Lune unit tests in `tests/unit` using fixed, hand-computed expected numbers (never values computed by calling the rule implementation under test), including exact boundary tests for absorption (equal passes, just above fails) and shrink clamping at `startDiameter`.

#### Part C: Central Configuration (`src/shared/Config`)

- **FR-012**: `src/shared/Config` MUST define all tuning constants, feature flags, and performance budgets in one module with no magic numbers scattered across server or client scripts, including: `startDiameter = 2`, `absorbRatio = 0.4`, `growthK = 0.6`, `maxVisibleStuck = 30`, `knockOffCount = 3`, `bumpSpeedThreshold`, `absorbRateLimit = 10`, `absorbDistanceTolerance`, speed curve parameters (`speedExponent = 0.5`, base speed, max speed cap), `maxServerBallSpeed`, camera distance parameters (`cameraMultiplier = 4`, min/max clamp), `jumpImpulse`, `respawnDelay`, a feature-flag table (`AvatarPusher`, `BigBallMode`, `RewardedAds`), and Principle VI performance budgets (`maxVisibleStuck = 30`, `maxActivePartsPerServer`, and per-tier mesh triangle budgets: Tier 1–2 $\le 300$, Tier 3 $\le 800$, Tier 4–5 $\le 2500$).

#### Part D: Server Authority (`src/server`)

- **FR-013**: `BallService` MUST spawn one `Part` (`Shape = Enum.PartType.Ball`, diameter `Config.startDiameter = 2`) per player upon joining/spawning, hide or suppress the player's avatar so the player is represented solely by the ball, grant network ownership of the ball to that player's client, and clean up the ball when the player leaves.
- **FR-014**: `BallService` MUST sanity-check each player ball's speed on every server heartbeat against `Config.maxServerBallSpeed`; if a ball's speed or single-step displacement exceeds the allowed ceiling, the server MUST clamp velocity and reset/correct the ball's position to the last valid bound and log the violation.
- **FR-015**: `AbsorbService` MUST listen on a single absorb `RemoteEvent` that accepts only a single argument (`objectId: unknown`), runtime type-check that `objectId` is a `string`, and validate all four server conditions before mutating state:
  1. The target object exists in the active room registry and is not currently marked taken;
  2. The 3D distance between the player's ball center and the object center is at most $\text{ballRadius} + \text{objectSize}/2 + \text{Config.absorbDistanceTolerance}$;
  3. The pure absorb rule from `src/shared/Rules` passes for the player's current authoritative diameter and the server's recorded object size;
  4. The player has not exceeded `Config.absorbRateLimit` (10 requests per second).
- **FR-016**: When an absorb request passes validation, `AbsorbService` MUST mark the object as taken, update the player's authoritative ball diameter using the pure growth formula from `src/shared/Rules`, record the absorbed object in the player's stuck-object stack, resize the authoritative ball `Part`, and publish the updated authoritative diameter (e.g., via replicated attribute or event) without trusting any client-supplied size, score, or diameter.
- **FR-017**: When a player's ball collides with an unabsorbable object ($S > 0.4 \times D$) at an impact speed exceeding `Config.bumpSpeedThreshold`, the server MUST knock off up to `Config.knockOffCount` (3) of the player's most recently absorbed objects, shrink the player's authoritative ball diameter by their volume via `src/shared/Rules`, and scatter those knocked-off objects back into the room as active, collectable objects.
- **FR-018**: Absorbed objects in the grey-box room MUST respawn after `Config.respawnDelay` seconds so that a 6-player session does not exhaust the room's 30 cubes.

#### Part E: Client Control, Camera & Visuals (`src/client`)

- **FR-019**: `BallController` MUST read the player's directional movement input (`Humanoid.MoveDirection` from mobile thumbstick or PC WASD, or `PlayerModule` `ControlModule` if the character is removed) relative to the camera and apply rolling torque through an `AngularVelocity` constraint plus a small forward force scaled by the pure speed curve from `src/shared/Rules`.
- **FR-020**: `BallController` MUST support a small vertical hop (using `Config.jumpImpulse` when grounded) triggered by pressing `Space` on PC or tapping a dedicated mobile on-screen Jump button situated in the bottom-right area with minimum dimensions of $96 \times 96\text{ px}$.
- **FR-021**: `CameraController` MUST track the player's ball and smoothly interpolate the camera follow distance toward the target distance computed by `src/shared/Rules` ($4 \times \text{diameter}$, clamped) as the ball grows or shrinks.
- **FR-022**: `StuckVisuals` MUST attach each newly absorbed cube to the ball at its contact point with `CanCollide = false` and `Massless = true` (or use client-side CFrame following if physics welds cause sphere-resize jitter), remove the oldest visible stuck object whenever the count exceeds `Config.maxVisibleStuck` (30), and remove the corresponding visuals when a knock-off occurs.

#### Part F: Grey-Box Room, Testing & Playtest Gate

- **FR-023**: The grey-box environment MUST consist of a single plain-part room containing 30 cubes across 4 distinct size tiers (with tier sizes and counts mathematically derived in `plan.md` from `startDiameter = 2`, `absorbRatio = 0.4`, and `growthK = 0.6`) arranged so that Tier 1 cubes sit within 3–5 seconds of spawn and a player can progress through all 4 cube sizes within a couple of minutes.
- **FR-024**: Studio integration tests in `tests/studio` (using Jest-Lua) MUST verify that server absorb validation rejects: (a) a missing/unknown object ID, (b) an already-taken object, (c) an out-of-range distance, (d) an object too large for the current ball diameter, (e) a non-string `objectId` payload, and (f) the 11th request sent within a 1-second window.
- **FR-025**: The feature directory MUST include `specs/001-grey-box-prototype/playtest.md` structured to record the Constitution Principle I gate playtest: date, commit SHA, participant counts by age group (at least 3 adults and 3 children aged 10–12 recorded by age group only, never by name), measured results for first-pickup time ($\le 5\text{ s}$), sphere-resize jitter, growth satisfaction, frame rate on the reference phone ($\ge 30\text{ fps}$), bump threshold tuning observations, and the owner's sign-off.

### Key Entities

- **PlayerBall**: Represents a single player's authoritative physical sphere and state in a server session. Attributes: `ownerUserId`, `authoritativeDiameter` (starts at 2 studs), `stuckStack` (LIFO list of absorbed cube entries for knock-off calculation), `recentRequestTimestamps` (sliding 1-second window for rate limiting), `lastValidPosition`, `lastValidVelocity`.
- **RoomCube**: Represents one of the 30 absorbable/obstacle cubes in the grey-box room. Attributes: `id` (unique string identifier), `tier` (1 to 4), `size` (edge length in studs), `spawnCFrame`, `currentCFrame`, `isTaken` (boolean), `respawnAt` (timestamp when a taken cube returns to the room).
- **StuckVisualEntry**: Client-side visual representation of an absorbed cube attached to a ball (`CanCollide = false`, `Massless = true`, relative contact offset/transform), capped at `maxVisibleStuck = 30` per ball with FIFO eviction of the oldest visual when a 31st object is absorbed.
- **GameConfig**: Read-only shared configuration record (`src/shared/Config`) holding all gameplay tuning constants, anti-exploit limits, feature flags, and performance budgets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `scripts/check.sh` exits with code 0 both locally and in GitHub Actions CI across all checks (formatting, linting, strict type analysis, pure-rules isolation guard, and unit tests).
- **SC-002**: 100% of unit tests in `tests/unit` and Studio validation tests in `tests/studio` pass, and every absorb request is validated on the server with zero reliance on client-supplied sizes, scores, or diameters.
- **SC-003**: A newly spawned player rolls into and absorbs their first Tier 1 cube within 5 seconds of joining and progresses through all 4 cube size tiers within 2 minutes of play in the 30-cube room.
- **SC-004**: Up to 12 players can each roll their own ball concurrently in a single server without physics instability, and at least 6 players (at least 3 adults and 3 children aged 10–12) have played together with findings and owner sign-off recorded in `specs/001-grey-box-prototype/playtest.md`.
- **SC-005**: Every obstacle collision above the bump speed threshold knocks off up to 3 most recently absorbed objects that scatter and can be re-collected, shrinking the ball's diameter by their volume (never below 2 studs).
- **SC-006**: Growing the rolling ball with up to 30 attached stuck objects produces zero visible physics jitter and maintains at least 30 fps on the mid-range reference phone.
- **SC-007**: A Studio playtest session driven through the Roblox Studio MCP server completes with zero new console errors or warnings.

## Scope & Boundaries

### In Scope

- Repository tooling and CI setup (`wally.toml`, `rokit.toml`, `default.project.json`, `stylua.toml`, `selene.toml`, `.luaurc`, `.gitignore`, `scripts/check.sh`, `.github/workflows/`, `docs/rollossal-gdd.md`, `README.md`).
- Pure rules in `src/shared/Rules` (absorb rule, volume growth/shrink math, speed curve, camera distance curve) and Lune unit tests in `tests/unit`.
- Shared configuration and budgets in `src/shared/Config`.
- Server-authoritative `BallService` (spawning, network ownership, heartbeat speed check) and `AbsorbService` (RemoteEvent validation, rate limiting, growth, obstacle bump knock-offs, simple cube respawning) plus Jest-Lua tests in `tests/studio`.
- Client `BallController` (thumbstick/WASD torque + forward force, PC Space & mobile $\ge 96\text{ px}$ Jump button), `CameraController` (smooth pullback), and `StuckVisuals` (30-item visual cap and weld/follower jitter handling).
- Grey-box room with 30 plain-part cubes across 4 sizes and playtest report artifact `specs/001-grey-box-prototype/playtest.md`.

### Out of Scope

- Run timer, star thresholds, and end-of-run results screen (Feature 002).
- Persistent player data saving, ProfileStore, coins, and collection book (Feature 003).
- Blender 3D meshes, custom art, audio, VFX, and stylized HUD/UI (Feature 004 and later).
- Out-of-sight object pooling and 60-object Snow Village world layout (Feature 004).
- Co-op player-to-player ball merging and Friend Boost (Feature 005).
- Shop, monetization passes, and developer products (Feature 006).

## Risks & Mitigations

- **Physics jitter when resizing a rolling sphere with welded parts** (`docs/rollossal-gdd.md` §12): Resizing a `Ball` `Part` while `WeldConstraint` children are attached can cause centre-of-mass or collision solver hiccups in Roblox physics. Mitigation: Measure angular/linear velocity stability during Studio verification; if welding produces jitter on growth steps, switch `StuckVisuals` to the client-side follower fallback (updating visual part transforms relative to the ball each render step without physical welds) and record the measurement and decision in `plan.md`.
- **Speed and absorb exploits on client-owned physics**: Because the client holds network ownership of its ball `Part` for responsive steering, a malicious client could teleport the ball or fire rapid/forged absorb events. Mitigation: `BallService` clamps/resets excessive velocity and displacement every heartbeat against `Config.maxServerBallSpeed`, and `AbsorbService` accepts only `objectId` strings and validates existence, availability, 3D distance, size ratio, and a 10/s rate limit on the server.

## Assumptions

- **Mid-Range Reference Phone Default (`TODO(REFERENCE_PHONE)`)**: Until the owner names a different device during playtest sign-off, the reference target for the Constitution Principle VI 30 fps mobile budget is assumed to be a mid-range Android phone equivalent to a Samsung Galaxy A53 / A54 (Snapdragon 695 / Exynos 1280 class, 6 GB RAM, 1080p viewport).
- **Initial Bump Speed Threshold (`bumpSpeedThreshold`)**: Set to an initial default of `15` studs/second relative impact speed in `src/shared/Config`, designed to trigger knock-offs on deliberate medium-to-full-speed collisions with larger cubes while ignoring gentle grazing contacts, and exposed in `src/shared/Config` for playtest tuning.
- **Absorb Distance Tolerance (`absorbDistanceTolerance`)**: Set to `2.0` studs in `src/shared/Config` to accommodate normal client-server replication latency at rolling speeds without allowing distant pickups.
- **Simple Cube Respawn Delay (`respawnDelay`)**: Set to `15` seconds in `src/shared/Config` for the 30-cube grey-box room so that 6 concurrent testers can continuously progress through all 4 cube sizes without depleting the room (whereas the 60–120s out-of-sight respawn rule applies to the larger 60-object world in Feature 004).
- **Plan-Level Implementation Choices**: Specific technical design choices explicitly delegated by the prompt to `/speckit-plan`—namely (1) exact cube sizes and counts across the 4 tiers with volume-progression math, (2) server bump detection mechanism (server touch + relative velocity vs. server-verified client collision report), (3) reading movement input when the character avatar is hidden/removed (`Humanoid.MoveDirection` vs. `PlayerModule` `ControlModule`), and (4) weld vs. client-follower outcome for `StuckVisuals`—will be documented and justified in `specs/001-grey-box-prototype/plan.md`.
