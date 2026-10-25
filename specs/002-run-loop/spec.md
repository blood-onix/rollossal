# Feature Specification: Run Loop

**Feature Branch**: `002-run-loop`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "Turn free rolling into 4-minute runs with a clear ending: a personal timer, size tiers that unlock as the ball grows, a target with 1–3 stars, a results screen and a one-tap Roll again. This makes the 5-second, 1-minute and one-run loops of the design brief real. Design brief: README.md §2 (core loop, run flow), §3.3 (tiers and targets), §4 (HUD, results). Constitution: II, III, IV (runs with clear endings), VI, VII, IX. Depends on 001."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Personal 4-Minute Timed Run, End-of-Run Results, and One-Tap Roll Again (Priority: P1)

A player joins the server and immediately begins a personal 4-minute (`240` second) run at a room spawn point with a countdown timer (`mm:ss`) and star targets visible at the top centre of the screen. The player rolls and absorbs objects to grow their ball. When the 4-minute timer reaches `00:00` (the bell rings), the server stops the player's ball, computes and publishes the authoritative run summary once for that unique run ID, and presents the results screen showing final diameter, stars earned (`0`–`3`), coins earned, object types collected for the first time during the run, and the best final size among the player's friends in the server. From the results screen, the player taps **Roll again** to reset their ball to starting size (`2` studs) at a spawn point and start a new 4-minute run within about 3 seconds in the same server, or taps **Back to hub** to move to the grey-box hub plaza and start a new run when ready.

**Why this priority**: This implements the core one-run loop of the design brief (`docs/rollossal-gdd.md` §2) and satisfies Constitution Principle IV (the game must be built from runs with clear endings) and Principle II (the server alone decides timers, sizes, stars, coins, unlocks, and run results).

**Independent Test**: Can be tested solo or with friends by completing three consecutive runs using **Roll again** (with `runDurationSeconds` configured to 240s in production or a shortened test duration in automated Studio tests), verifying that each run stops the ball at the bell, displays the authoritative results screen once per unique run ID, and starts a fresh run within 3 seconds of tapping **Roll again**, as well as verifying **Back to hub** transitions the player to the grey-box hub plaza.

**Acceptance Scenarios**:

1. **Given** a player joins the server or spawns into the grey-box room, **When** their session starts, **Then** the server immediately starts a personal run with a unique `runId` and a `240`-second countdown timer (`Config.runDurationSeconds = 240`), and the client HUD displays the remaining time in `mm:ss` format alongside the star target markers.
2. **Given** a player is in an active run and has absorbed objects, **When** `240` seconds elapse on the server, **Then** the server transitions the run to ended, halts the player's ball and rejects further absorb/bump requests for that run, and publishes a single authoritative result payload containing `runId`, `finalDiameter`, `stars` (`0`–`3`), `coins`, `newBookIds` (first-time object types absorbed in this run), and `bestFriendSize` (best final size among Roblox friends in the server).
3. **Given** the results screen is displayed at the end of a run, **When** the player activates **Roll again**, **Then** the server resets the player's ball to `Config.startDiameter` (`2` studs) with an empty stuck stack at a room spawn slot and begins a new run with a fresh `runId` and full timer within 3 seconds in the same server.
4. **Given** the results screen is displayed at the end of a run, **When** the player activates **Back to hub**, **Then** the server moves the player to the grey-box hub plaza outside the active rolling room, hides the run results screen, and allows the player to re-enter a new run from the hub without typing or rejoining.
5. **Given** a player completes a run, taps **Roll again**, completes a second run, taps **Roll again**, and completes a third run, **When** each run ends, **Then** each of the three runs carries a distinct `runId`, resets per-run state cleanly, and presents its own accurate results screen.

---

### User Story 2 - Size Tier Progression, Live HUD Meter, and Sensory Feedback (Priority: P1)

As a player absorbs objects during a run, the top-left HUD size meter continuously shows their current ball diameter as a large number, a progress bar toward the next size tier threshold, and a preview of the next tier (`"Next: [silhouette] <HEADLINE>"`). Each pickup triggers a short-lived centre screen pop (`"+ <Object Name>"` with an icon, fading in 1 second), a scale "pop" animation, a pickup sound (rising in pitch by tier), and a light haptic pulse on mobile devices. When the ball's authoritative diameter crosses a new size tier threshold, the camera pulls back and a tier banner (`"You can roll up: <HEADLINE>!"`) appears once for that tier in that run. When the player bumps a too-large obstacle fast enough to knock off stuck objects, the camera shakes (unless **Reduce motion** is enabled), while coins earned earlier in the run are never reduced.

**Why this priority**: This delivers the 5-second pickup loop and 1-minute tier-unlock loop from `docs/rollossal-gdd.md` §2 and §4 while meeting Constitution Principle VI (Mobile First readability, ≥18 px text, ≥96 px buttons, `UIScale`, icon + label for every status, never colour or sound alone).

**Independent Test**: Can be tested in a single run by absorbing objects across Tier 1 through Tier 4, verifying the live HUD diameter and progress bar, the 1-second pickup pop, the tier unlock banner firing once per tier even if a knock-off shrinks the ball and it re-crosses the same threshold, and viewport readability captured at phone resolution through the Studio MCP server.

**Acceptance Scenarios**:

1. **Given** a player is in an active run at diameter $D$, **When** $D$ is within tier $T$ with next tier $T+1$, **Then** the top-left HUD displays $D$ as a large number, fills the progress bar proportionally between tier $T$'s minimum diameter and tier $T+1$'s threshold, and displays `"Next: [silhouette] <HEADLINE>"` (or a max-tier indicator when at the highest tier).
2. **Given** a player absorbs an object during a run, **When** the server confirms the pickup, **Then** the client plays a pickup sound and scale "pop", triggers a light haptic pulse on mobile (`HapticService` when supported), and displays a single-line centre pop `"+ <Object Name>"` with an icon that fades out within 1 second.
3. **Given** a player's ball grows and crosses a tier threshold $T > 1$ for the first time in the current run, **When** the threshold is reached, **Then** the tier banner `"You can roll up: <HEADLINE>!"` appears in the centre of the screen with an icon and sound while the camera smoothly pulls back.
4. **Given** a player has already unlocked tier $T$ during the current run and later suffers a knock-off that shrinks the ball below tier $T$'s threshold, **When** the ball grows back across tier $T$'s threshold in the same run, **Then** the tier $T$ banner does NOT appear a second time during that run.
5. **Given** a player collides with an unabsorbable object above `bumpSpeedThreshold` and loses stuck objects, **When** the knock-off occurs, **Then** the client plays a camera shake effect (unless **Reduce motion** is active) and visual indicator, and the player's accumulated run coins remain unchanged.

---

### User Story 3 - Pure Run Rules, Data-Driven World Tiers, and Full Localisation (Priority: P2)

Developers and content creators define stars, tier lookups, and coin reward calculations as pure, deterministic functions in `src/shared/Rules` tested by Lune outside Studio, define world tier tables and object metadata purely as data in `src/shared/Content` so future worlds (such as Snow Village in 004) require zero code changes, and source every player-facing string in UI and banners from a repository `LocalizationTable` (English in this feature; Spanish added in 007).

**Why this priority**: Enforces Constitution Principles III (Pure, Tested Rules), VII (Content Is Data), and IX (Localised Strings from day one) so that run logic is mathematically verified and UI never contains hard-coded strings.

**Independent Test**: Can be tested by running `scripts/check.sh` to execute Lune unit tests on `src/shared/Rules` (boundary tests for stars, tier lookup, and coin multipliers) and `src/shared/Content` validation, plus a check confirming zero hard-coded player-facing strings exist in client/server scripts.

**Acceptance Scenarios**:

1. **Given** star thresholds configured at `20`, `45`, and `80` studs, **When** the pure star rule is evaluated in Lune tests, **Then** `19.99` studs returns `0` stars, `20` returns `1` star, `44.99` returns `1` star, `45` returns `2` stars, `79.99` returns `2` stars, and `80` returns `3` stars.
2. **Given** a world's tier table and a ball diameter $D$, **When** the pure tier lookup rule is evaluated, **Then** it returns the current tier record (`tier`, `nameKey`, `minDiameter`, `maxDiameter`, `headlineKey`) and the next tier's threshold diameter (or `nil` when at the top tier), without referencing any world-specific constants in code.
3. **Given** a list of absorbed object coin values and multiplier arguments (`hasFriendInServer`, `hasDoubleCoinsPass`, `friendBoostPassCount`), **When** the pure coin reward rule is evaluated, **Then** it sums the base `coins` of all absorbed objects (never subtracting for knock-offs) and applies multipliers in a fixed, deterministic order tested with exact hand-computed values in Lune.
4. **Given** any player-facing text on the HUD, pickup pop, tier banner, results screen, or hub prompt, **When** rendered on the client, **Then** the text is resolved through the repository `LocalizationTable` by localization key with formatted parameters, and no script contains hard-coded English display literals.

---

### Edge Cases

- **Star & Tier Exact Boundaries**: Diameter `19.99` awards `0` stars while `20.00` awards `1` star; `44.99` awards `1` star while `45.00` awards `2` stars; `79.99` awards `2` stars while `80.00` awards `3` stars. The same exact `>= minDiameter` boundary applies to tier lookups and tier banner triggers.
- **Player Leaves Mid-Run**: If a player disconnects before their 240-second run timer expires, `RunManager` immediately drops the active run, awards and publishes no results, and cleans up all session state and cached friend data for that player.
- **Falling Out of the World Mid-Run**: If a player's ball falls below `Config.fallRespawnY` during an active run, the server respawns the ball back at its spawn slot **at its current authoritative diameter and with its current stuck stack and run timer preserved** (unlike Feature 001's free-rolling reset), so an accidental fall does not wipe out a run in progress.
- **Knock-Offs vs. Coins & Tier Banners**: Knock-offs reduce the ball's current diameter (which CAN lower the final diameter and stars if the run ends before recovery), but knock-offs NEVER subtract from the coins accumulated during the run and NEVER cause an already-shown tier banner to re-fire in the same run.
- **Client Stops Sending or Tries to Cheat Run State**: If a client freezes, stops sending network events, tries to fire an early run-end request, or sends forged sizes/coins, the server still ends the run at exactly `240` seconds and computes results solely from server-authoritative state.
- **No Friends in Server**: When a player has no Roblox friends currently in the same server (or when `Player:IsFriendsWith` fails and defaults safely to `false`), `bestFriendSize` is reported as `nil` (or `0`), and the results screen friend-comparison row displays the player's own session best size for the world (to be backed by persistent profile best size once Feature 003 lands).
- **Server Shutdown Mid-Run (`game:BindToClose`)**: If the server shuts down while runs are in progress, active mid-run sessions are cleanly terminated without publishing partial results as completed runs.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Pure Run Rules (`src/shared/Rules`)

- **FR-001**: `src/shared/Rules` MUST implement a pure star calculation function that takes `finalDiameter: number` and an ordered star-thresholds array (defaulting via `Config.starThresholds = { 20, 45, 80 }`) and returns `0`, `1`, `2`, or `3` stars using inclusive lower bounds (`diameter >= threshold`), verified by Lune unit tests at `19.99 -> 0`, `20 -> 1`, `44.99 -> 1`, `45 -> 2`, `79.99 -> 2`, and `80 -> 3`.
- **FR-002**: `src/shared/Rules` MUST implement a pure tier lookup function that takes `diameter: number` and a world's ordered tier table and returns the active tier entry, its 1-based tier index, and the next tier's threshold diameter (`number?`, `nil` when at the highest tier).
- **FR-003**: `src/shared/Rules` MUST implement a pure coin reward calculation function that takes the array of base `coins` values from every object absorbed during the run (monotonically append-only; knock-offs do not remove coin entries) and multiplier parameters (`friendBonusRate: number`, `hasFriendInServer: boolean`, `hasDoubleCoins: boolean`, `friendBoostRate: number`, `friendBoostCount: number`) and returns an integer coin total computed in this exact deterministic order:
  1. `baseCoins = sum(absorbedCoinValues)`
  2. `afterFriendBonus = baseCoins * (if hasFriendInServer then 1 + friendBonusRate else 1)`
  3. `afterFriendBoost = afterFriendBonus * (1 + friendBoostRate * friendBoostCount)`
  4. `afterDoubleCoins = afterFriendBoost * (if hasDoubleCoins then 2 else 1)`
  5. `totalCoins = math.floor(afterDoubleCoins + 0.5)` (standard half-up rounding to integer, with `0` base coins always yielding `0`).
- **FR-004**: All new modules under `src/shared/Rules` MUST obey Constitution Principle III (strictly pure Luau, `--!strict`, zero Roblox APIs or clock/random reads) and pass `scripts/check.sh` and Lune unit tests in `tests/unit` with hand-computed expected values.

#### Part B: World Tier & Object Content Data (`src/shared/Content`) & Config (`src/shared/Config`)

- **FR-005**: `src/shared/Content` MUST define a world tier schema where each tier record includes `tier: number`, `nameKey: string`, `minDiameter: number`, `maxDiameter: number?`, `headlineKey: string`, and `headlineIcon: string`, and each absorbable object definition includes `id`, `tier`, `size`, `coins`, `bookId`, `nameKey`, and `icon`.
- **FR-006**: `src/shared/Content/GreyBoxRoom.luau` (or a world content table) MUST populate the 4 tiers and object metadata (`coins`, `bookId`, `nameKey`, `headlineKey`) for the grey-box room so that replacing or adding Snow Village's 5 tiers and ~60 objects in Feature 004 requires only data changes and zero code changes to `Rules`, `RunManager`, `Hud`, or `ResultsUi`.
- **FR-007**: `src/shared/Config.luau` MUST define the run loop tuning constants in one place: `runDurationSeconds = 240`, `rollAgainDelaySeconds = 3`, `starThresholds` (for production `{ 20, 45, 80 }` and/or world-overridable star targets), `friendBonusRate = 0.20`, `friendBoostRate = 0.25`, `pickupPopDuration = 1.0`, `tierBannerDuration = 2.5`, and `knockOffShakeDuration = 0.35`.
- **FR-008**: Lune unit tests in `tests/unit` MUST validate content integrity: tier numbers are sequential starting at `1`, `minDiameter` values strictly ascend by tier, object `coins` are positive integers, and every `nameKey` and `headlineKey` referenced in content exists in the English localization table.

#### Part C: Server Run Authority (`src/server/RunManager`)

- **FR-009**: `RunManager` MUST assign each player an active personal run immediately upon spawning in the rolling room, generating a globally unique `runId` (such as `<userId>-<serverRunSeq>` or a GUID), recording `startedAt`, setting `endsAt = startedAt + Config.runDurationSeconds`, and initializing per-run state (`coinsEarnedBase = {}`, `absorbedBookIds = {}`, `highestTierReached = 1`, `state = "Active"`).
- **FR-010**: While a player's run is `"Active"`, the server MUST replicate the authoritative run state (`runId`, remaining or end time, current tier, next tier threshold, star thresholds, and pickup/tier/knock-off events) to the client, and `AbsorbService` MUST record each validated pickup's `coins` and `bookId` into the player's active run without trusting any client input.
- **FR-011**: When `now >= run.endsAt` on the server (at `240` seconds), `RunManager` MUST immediately transition the run state from `"Active"` to `"Ended"`, halt the player's ball (`AssemblyLinearVelocity = Vector3.zero`, `AssemblyAngularVelocity = Vector3.zero`, anchored or input-locked while on the results screen), ignore any further `Absorb` or `Bump` requests for that run, and compute and publish the `RunResult` payload **exactly once** for that `runId`.
- **FR-012**: The published `RunResult` MUST include: `runId: string`, `worldId: string`, `finalDiameter: number`, `stars: number` (`0`–`3`), `coins: number`, `newBookIds: { string }` (distinct `bookId`s absorbed during this run that the player had not absorbed earlier in the session), `bestSelfSize: number`, and `bestFriendSize: number?` (the highest completed-run `finalDiameter` in this world among the player's Roblox friends present in the server, using cached `Player:IsFriendsWith` results wrapped in `pcall`).
- **FR-013**: `RunManager` MUST expose a single client-to-server remote intent for post-run actions (`RollAgain` and `BackToHub`, or two zero-argument remote events) that runtime type-checks its arguments, accepts requests only when the player's run is `"Ended"` (or when the player is in `"Hub"`), and rejects any client attempt to end a run early, report a size, or spoof results.
- **FR-014**: When a player in the `"Ended"` or `"Hub"` state triggers **Roll again**, `RunManager` and `BallService` MUST reset the player's ball to `Config.startDiameter` (`2` studs) with an empty stuck stack at a room spawn slot and start a fresh 4-minute run with a new `runId` within at most `Config.rollAgainDelaySeconds` (`3` seconds).
- **FR-015**: When a player in the `"Ended"` state triggers **Back to hub**, `RunManager` MUST transition the player to `"Hub"` state and move their ball/view to a simple grey-box hub plaza in the same place where no run timer is ticking and where an in-world entry pad or large HUD button lets them start a new run at any time.
- **FR-016**: When a player's ball falls below `Config.fallRespawnY` (`-50`) during an `"Active"` run, `BallService` MUST reposition the ball to its spawn slot and zero its velocity **without** resetting `authoritativeDiameter`, `stuckStack`, or the active run timer; when a player leaves the server mid-run (`Players.PlayerRemoving`), `RunManager` MUST discard the unfinished run without publishing a result.

#### Part D: Phone-First Client HUD, Feedback & Results (`src/client`)

- **FR-017**: `Hud` MUST render the active run HUD scaled with `UIScale` per viewport so all text is at least `18 px` on phone viewports, uses `FredokaOne` for headings and `GothamMedium`/`BuilderSans` for body text, applies a dark outline (`UIStroke`) on every text element, and pairs every status indicator with both an icon and a text label (never colour or sound alone):
  - **Top centre**: remaining run time formatted as `mm:ss` with a clock icon, plus the run target bar/display showing the 1-star, 2-star, and 3-star diameter thresholds with star icons and labels.
  - **Top left**: current ball diameter as a large formatted number, a progress bar toward the next tier threshold, and `"Next: [silhouette] <HEADLINE>"` using the localized tier headline name.
  - **Centre (short-lived)**: a single-line pickup pop (`"+ <Object Name>"` with an icon) that fades out over `1.0` second on each pickup, and a tier banner (`"You can roll up: <HEADLINE>!"` with an icon) that displays when the ball crosses a new tier threshold for the first time in the run.
- **FR-018**: Client feedback on every confirmed pickup MUST play a scale "pop" animation on the HUD/ball, play a grey-box placeholder pickup sound (pitch-shifted by tier), and trigger a light haptic pulse on mobile devices where `HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)` or touch haptics are available (wrapped safely so unsupported devices never error).
- **FR-019**: Client feedback on every confirmed knock-off bump MUST trigger a brief camera shake in `CameraController` accompanied by a visual bump indicator and placeholder bump sound, and MUST respect a client `reduceMotion` setting flag that disables camera shake when enabled.
- **FR-020**: `ResultsUi` MUST appear automatically when the server publishes a `RunResult` for the local player and display:
  - Final diameter and `0`–`3` earned stars (each shown with both icon and label);
  - Coins earned in the run;
  - New collection book entries discovered in the run (count and localized object names/icons);
  - Friend comparison row showing the best final size among friends in the server (or the player's own best size in this world when no friend has a recorded size in the server);
  - A large **Roll again** button and a **Back to hub** button, each at least `96 x 96 px` in touch target height/width, with zero countdown timers, zero discounts, and nothing for sale.

#### Part E: Localisation (`Constitution Principle IX`)

- **FR-021**: All player-facing strings across `Hud`, `ResultsUi`, tier banners, object names, and hub UI MUST be stored in a version-controlled localization source module/table in the repository and loaded into a Roblox `LocalizationTable` (English `en-us` complete in this feature; ready for Spanish `es-es` in Feature 007), with a helper module that formats parameterized keys (e.g., `ui.hud.next_tier`, `ui.banner.tier_unlock`, `ui.pickup.pop`, `ui.results.*`, `tier.greybox.*`, `object.greybox.*`).
- **FR-022**: `scripts/check.sh` (or a Lune unit test invoked by `scripts/check.sh`) MUST verify that every localization key referenced in `src/shared/Content` and UI modules has a non-empty English entry and that client/server UI modules do not hard-code raw English sentences on `TextLabel.Text` or `TextButton.Text`.

#### Part F: Automated Tests & Studio Verification

- **FR-023**: Lune unit tests in `tests/unit` MUST cover:
  - Star threshold boundaries (`19.99 -> 0`, `20 -> 1`, `44.99 -> 1`, `45 -> 2`, `79.99 -> 2`, `80 -> 3`);
  - Tier lookup across all tiers (including exact threshold boundaries and max-tier behaviour);
  - Coin reward calculation with and without `hasFriendInServer`, `hasDoubleCoins`, and `friendBoostCount`, plus verification that knock-offs do not reduce coin totals;
  - Content and localization key completeness.
- **FR-024**: Studio integration tests in `tests/studio` (using Jest-Lua) MUST verify that:
  - A run ends on the server when `runDurationSeconds` elapses (`240` seconds of simulated/stepped clock time) even if the client sends no events;
  - `RunResult` is produced and published **exactly once** per `runId` (stepping the server clock after run end never emits a duplicate result);
  - A client cannot end a run early, cannot absorb objects after the run ends, and cannot report or override its diameter, stars, or coins;
  - Falling below `fallRespawnY` mid-run preserves the player's current diameter, stuck stack, and active `runId`;
  - Triggering `RollAgain` after run end resets the ball to `startDiameter` and starts a new run with a distinct `runId`.

### Key Entities

- **RunSession**: Server-authoritative record for a single player's current state (`"Active"`, `"Ended"`, or `"Hub"`). Attributes: `runId` (unique string per run), `userId`, `worldId`, `state`, `startedAt`, `endsAt`, `absorbedCoinValues` (append-only list of base coin amounts from every validated pickup in the run), `absorbedBookIds` (ordered set of `bookId`s absorbed in the run), `unlockedTiers` (set of tier numbers whose banner has already triggered in this run).
- **RunResult**: Immutable summary produced once when a `RunSession` transitions from `"Active"` to `"Ended"`. Attributes: `runId`, `userId`, `worldId`, `finalDiameter`, `stars` (`0`–`3`), `coins` (integer after multipliers), `newBookIds` (array of `bookId`s first collected in this run), `bestSelfSize` (player's best completed run diameter in this world during the session), `bestFriendSize` (`number?`, highest completed run diameter among Roblox friends in the server).
- **WorldTierDef**: Data record in `src/shared/Content` defining one size tier for a world. Attributes: `tier` (`1..N`), `nameKey` (localization key for tier name), `minDiameter` (studs threshold to enter this tier), `maxDiameter` (`number?`), `headlineKey` (localization key for the banner/next-tier headline noun, e.g., `"CATS"` / `"LARGE CUBES"`), `headlineIcon` (icon/silhouette identifier).
- **ObjectContentDef**: Data record in `src/shared/Content` defining an absorbable object type. Attributes: `objectTypeId` / `bookId`, `tier`, `size` (studs), `coins` (positive integer), `nameKey` (localization key for pickup pop and book), `icon` (icon identifier).
- **LocalizationCatalog**: Repository-tracked table of localized string entries keyed by string ID and locale (`en-us`), used to populate Roblox's `LocalizationTable` and resolve all player-facing UI text.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can play three complete runs in a row using **Roll again**, with each run ending cleanly at the bell, displaying an accurate results screen, and starting the next run within 3 seconds of tapping **Roll again**.
- **SC-002**: The HUD (timer, star targets, size meter, next-tier preview, pickup pop, tier banner) and the results screen read clearly without clipping or overlap at a mobile phone resolution (verified by viewport capture through the Roblox Studio MCP server), with all text at least `18 px` and action buttons at least `96 px`.
- **SC-003**: Tier unlock banners appear immediately when the ball's diameter crosses each tier threshold and appear at most once per tier per run, even if a knock-off shrinks the ball below the threshold and the ball later crosses it again.
- **SC-004**: 100% of Lune unit tests in `tests/unit` (stars boundaries, tier lookup, coin rewards with/without multipliers, content & localization validation) and 100% of Jest-Lua Studio tests in `tests/studio` (server 240s run end without client input, single result publication per `runId`, client anti-cheat on run state/size, mid-run fall preservation) pass, and `scripts/check.sh` exits with code `0`.
- **SC-005**: 100% of player-facing strings come from the repository localization table with zero hard-coded UI strings in scripts.
- **SC-006**: A full Studio playtest session covering run start, pickups, tier unlock, knock-off, run end results screen, **Roll again**, and **Back to hub** completes with zero new console errors or warnings.

## Scope & Boundaries

### In Scope

- Pure run rules in `src/shared/Rules` (star thresholds, tier lookup, coin rewards with ordered multipliers) and Lune unit tests in `tests/unit`.
- Data-driven world tier table and object metadata (`coins`, `bookId`, `nameKey`, `headlineKey`) in `src/shared/Content` for the grey-box room, structured so Snow Village (Feature 004) drops in without code changes.
- Server `RunManager` owning the personal 4-minute (`240` s) timer, unique `runId`, once-per-run `RunResult` publication, cached friend best-size lookup (`Player:IsFriendsWith`), **Roll again** reset (~3 s), **Back to hub** grey-box plaza transition, mid-run fall preservation, and mid-run disconnect cleanup.
- Phone-first client HUD (`Hud`) and results screen (`ResultsUi`), pickup pop, once-per-run tier banner, placeholder sound/scale pop, mobile haptic pulse (`HapticService`), and knock-off camera shake with a `reduceMotion` toggle.
- Repository-backed `LocalizationTable` (English `en-us`) and localization helper covering every player-facing string.
- Jest-Lua Studio tests in `tests/studio` for server run authority and Studio MCP viewport captures at phone resolution.

### Out of Scope

- Saving coins, best size, or collection book progress across sessions with ProfileStore (Feature 003).
- Snow Village 3D Blender assets, ~60 object types, final audio, and final hub art (Feature 004).
- Party runs, player-to-player merged balls, and Friend Boost game pass ownership checks (Feature 005).
- Shop UI, skins, trails, and 2x Coins / Friend Boost pass purchases (Feature 006).
- First-60-seconds onboarding arrow/hints, analytics events, and Spanish (`es-es`) translation completion (Feature 007).

## Assumptions

- **Knock-Offs Never Reduce Coins (Confirmed Owner Proposal)**: Once an object is absorbed during a run, its base `coins` value is added to the run's coin tally. Losing stuck objects to a high-speed obstacle bump shrinks the ball's physical/authoritative diameter (affecting current size and potentially final diameter/stars if not recovered before the bell), but never subtracts coins earned during the run.
- **Friend Comparison Fallback When No Friends Are in the Server (Confirmed Owner Proposal)**: When no Roblox friends of the player are in the server (or before any friend has finished a run in the server), the friend comparison row on the results screen displays the player's own best size for the current world (`bestSelfSize`, tracked in-memory per session in Feature 002 and persisted via ProfileStore once Feature 003 lands).
- **Coin Multiplier Application Order**: Because friend bonus (`+20%` when a friend is in the server), Friend Boost pass (`+25%` per merged/party pass holder in Feature 005/006), and `2x Coins` pass (Feature 006) are passed as arguments to the pure coin rule in this feature, they are applied multiplicatively in the order: `baseCoins -> friendBonus -> friendBoost -> doubleCoins`, rounded half-up to the nearest integer via `math.floor(x + 0.5)`. In Feature 002 live runs (before Features 005/006), `hasFriendInServer` is determined from the server's cached friend check, while `hasDoubleCoins = false` and `friendBoostCount = 0`.
- **Star Thresholds in Config vs. Grey-Box Room Scale**: The default star thresholds in `src/shared/Config` are `{ 20, 45, 80 }` studs (`docs/rollossal-gdd.md` §3.3), and the pure star rule and its Lune boundary tests test `{ 20, 45, 80 }` (`19.99 -> 0`, `20 -> 1`, `45 -> 2`, `80 -> 3`). Each world definition in `src/shared/Content` may also optionally specify world-specific star thresholds (or use `Config.starThresholds`) so both the small 4-tier grey-box room and the 5-tier Snow Village (`20 / 45 / 80` studs) use the exact same rule function without code changes.
- **Grey-Box Hub Plaza**: "Back to hub" moves the player to a simple grey-box plaza platform in the same place (`Workspace.Hub`) with a clear visual start pad and/or on-screen **Play / Roll again** button so the player can start a new 4-minute run with one tap.
