# Feature Specification: Saving and Economy (DataService, Coins, Best Size, Collection Book, Settings)

**Feature Branch**: `003-saving-and-economy`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "Make progress persist: a ProfileStore-backed DataService that saves coins, best size per world, the collection book and settings, plus the Book screen and the Settings screen. Design brief: README.md §3.5 (progression and economy), §4 (collection book, settings), §9 (profile schema v1). Constitution: II, V (one soft currency), VIII (player data), IX. Depends on 002 (run results with run IDs)."

## Clarifications

### Session 2026-10-25

- Q: Do you approve the proposed ProfileStore DataStore name (`"PlayerProfiles_v1"`), player key format (`"Player_<UserId>"`), and Profile Schema v1 key names? → A: Approved proposed DataStore key name (`"PlayerProfiles_v1"` / `"Player_<UserId>"`) and Profile Schema v1 keys (`version`, `coins`, `worldsUnlocked`, `skinsOwned`, `equipped`, `book`, `bestSize`, `receipts`, `appliedRuns`, `settings` with `musicVolume`, `effectsVolume`, `cameraSensitivity`, `reduceMotion`, `language`).
- Q: How should the MVP handle spending coins while only one world exists? → A: Let coins accumulate until Candy Town unlocks in Feature 011 (world unlocks and ball cores remain in Feature 011).

## Owner Approval Gate *(Constitution Principle VIII & Human Approval Required)*

The owner has approved (2026-10-25) the DataStore name, player key format, and Profile Schema v1 field names below:

- **Approved ProfileStore DataStore Name**: `"PlayerProfiles_v1"`
- **Approved Per-Player Key Format**: `"Player_" .. tostring(userId)` (stores only numeric Roblox `UserId` and gameplay progress; never stores usernames, display names, chat logs, contact details, or personal data)
- **Approved Profile Schema v1 Keys & Defaults**:
  - `version: number` — `1`
  - `coins: number` — `0` (non-negative integer; soft currency earned only through play)
  - `worldsUnlocked: { [string]: boolean }` — `{ greybox = true, snow_village = true }`
  - `skinsOwned: { [string]: boolean }` — `{}` (set of owned skin/trail cosmetic IDs, including rewards earned by completing collection book pages)
  - `equipped: { skin: string?, trail: string? }` — `{ skin = nil, trail = nil }`
  - `book: { [string]: boolean }` — `{}` (set of discovered `bookId` strings)
  - `bestSize: { [string]: number }` — `{}` (map of `worldId -> bestFinalDiameter` in studs; monotonically non-decreasing per world)
  - `receipts: { string }` — `{}` (ordered list/set of processed `PurchaseId` strings reserved for Feature 006 idempotent `ProcessReceipt`)
  - `appliedRuns: { [string]: boolean }` — `{}` (or bounded recent run-ID ledger ensuring each `runId` from Feature 002 is applied at most once)
  - `settings: { musicVolume: number, effectsVolume: number, cameraSensitivity: number, reduceMotion: boolean, language: string }` — `{ musicVolume = 0.8, effectsVolume = 0.8, cameraSensitivity = 1.0, reduceMotion = false, language = "auto" }`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Persistent Player Profile, Session Locking, and Idempotent Run Saving (Priority: P1)

When a player joins the server, `DataService` loads their profile using ProfileStore with an active session lock, reconciles any missing fields against the v1 default schema, runs any pending version migrations, and replicates their saved state (coins, best size per world, discovered collection book entries, owned/equipped cosmetics, and settings) to their client. Each time the player completes a run (Feature 002), the server applies that `RunResult` (keyed by its unique `runId`) to the player's profile **exactly once**: adding earned coins, raising `bestSize[worldId]` if beaten, recording newly absorbed `bookId`s in the `book` set, and granting any newly completed tier-page cosmetic rewards. When the player leaves or the server shuts down (`game:BindToClose`), the profile is saved and its session lock is released. If a player's profile cannot be loaded on join, the server kicks the player with a friendly, localized message rather than allowing them to play unsaved.

**Why this priority**: Persistent progress is the core deliverable of Feature 003 and enforces Constitution Principles II (Server Authority), V (One Soft Currency), and VIII (Player Data and Privacy). Without reliable session-locked saving and idempotent run application, player progress can be lost or duplicated.

**Independent Test**: Can be tested via Jest-Lua Studio tests (`tests/studio`) using the ProfileStore mock store and verified in the private test place by completing a run, observing updated coins, best size, and book entries on the results and hub screens, leaving and rejoining the server, and confirming all progress and settings persist unchanged.

**Acceptance Scenarios**:

1. **Given** a first-time player joins the server, **When** `DataService` loads their profile with a session lock, **Then** the profile is initialized with all Profile Schema v1 default values (`version = 1`, `coins = 0`, empty `book` and `bestSize`, default `settings`) and replicated to the client.
2. **Given** an existing player's stored profile is missing one or more v1 fields (e.g., a newly added setting or sub-table), **When** `DataService` loads the profile, **Then** missing fields are reconciled with v1 defaults without overwriting existing saved values, and a v1 profile runs through the migration table and loads unchanged.
3. **Given** a player finishes a run and `RunManager` produces a `RunResult` with a unique `runId`, **When** `DataService` applies the result for the first time, **Then** `profile.coins` increases by `result.coins` (never going negative), `profile.bestSize[worldId]` updates to `math.max(previousBest, result.finalDiameter)`, each entry in `result.newBookIds` is added to `profile.book`, and if the run's new entries complete a tier page in `src/shared/Content`, the page's cosmetic reward ID is added to `profile.skinsOwned`.
4. **Given** a `RunResult` with `runId` has already been applied to a player's profile, **When** the same `runId` (or a late duplicate) is submitted again, **Then** `DataService` makes zero changes to `coins`, `bestSize`, or `book`.
5. **Given** a player's profile load fails or yields `nil` from ProfileStore, **When** the join handler finishes attempting to acquire the profile session, **Then** the server kicks the player with a friendly localized message (`error.profile_load_failed`) and never spawns an unsaved session.
6. **Given** a player is connected with an active profile session and leaves the game or the server shuts down (`game:BindToClose`), **When** the teardown handler runs, **Then** the profile is saved and the session lock is released so a subsequent server can load the profile without lock contention.

---

### User Story 2 - Collection Book Screen, Page Progress, and First-Time Results Callouts (Priority: P1)

Players can track every object type they have ever absorbed across runs. On the results screen at the end of a run, objects absorbed for the first time ever (checked against the player's persistent profile `book`) are highlighted under `"New in your book"`, and a player's very first results screen includes a brief localized explanation of the collection book and coins. From the top-right **Book** button on the HUD or Hub, the player opens `BookUi`, which displays objects grouped by size tier into pages. Discovered objects show their icon and localized name; undiscovered objects appear as silhouettes. Each tier page shows its completion count (e.g., `3 / 4` or `7 / 15`) and the cosmetic reward granted for completing that page.

**Why this priority**: "Collect the world" is Design Pillar 3 (`docs/rollossal-gdd.md` §1, §3.5, §4). The collection book turns every new object type into permanent progression and gives players a clear long-term completion goal.

**Independent Test**: Can be tested via Lune unit tests for pure book page progress and completion rules (`src/shared/Rules/Book.luau`), Jest-Lua Studio tests for persistent book set updates and page reward grants, and a Studio MCP playtest capturing `BookUi` and `ResultsUi` at phone resolutions (`640x360`, `844x390`, `1280x720`).

**Acceptance Scenarios**:

1. **Given** a world's object definitions grouped by tier and a player's `book` set of discovered `bookId`s, **When** the pure book rules in `src/shared/Rules` evaluate a tier page, **Then** they deterministically return the page's `collectedCount`, `totalCount`, completion state (`collectedCount == totalCount and totalCount > 0`), per-entry discovery flags, and any newly unlocked page reward IDs.
2. **Given** a player absorbs an object type during a run whose `bookId` is not yet in their persistent `profile.book`, **When** the run ends and `ResultsUi` opens, **Then** that object type is listed under `"New in your book"` with its icon and localized name; if the player absorbs the same object type again in a subsequent run, it is NOT listed as new.
3. **Given** a player completes their very first recorded run (transitioning from 0 prior completed runs in their profile), **When** `ResultsUi` displays, **Then** a concise localized callout explains how coins and the collection book work.
4. **Given** a player taps the top-right **Book** button (after the first 5 seconds of an active run, or at any time in the Hub), **When** `BookUi` opens, **Then** it renders a tier-grouped grid where discovered objects show their icon and localized label, undiscovered objects show as a silhouette with a localized unknown label, each tier header shows progress (`collected / total`) and page reward status, all text is at least `18 px` on phone viewports, and the top-centre run timer remains visible and uncovered.
5. **Given** a run has just started (within the first `Config.runStartUiLockSeconds = 5` seconds), **When** the player attempts to open `BookUi` (or the button is rendered during the opening seconds), **Then** `BookUi` does not open during those first seconds so the player's immediate rolling start is never obstructed.

---

### User Story 3 - Persistent Settings Screen Applied Live and Across Sessions (Priority: P2)

Players can open the **Settings** screen from the top-right **Settings** button to adjust **Music volume**, **Effects volume**, **Camera sensitivity**, **Reduce motion**, and **Language**. Changes apply immediately on the client (adjusting music and sound effect playback volumes, scaling camera rotation/follow sensitivity, toggling knock-off camera shake and strong UI motion, and switching the active locale on `Localizer`) and are sent to the server to be validated, clamped, and persisted in `profile.settings`. When the player rejoins in a future session, their saved settings are automatically restored and applied on join.

**Why this priority**: Delivers the Settings screen required by `docs/rollossal-gdd.md` §4 and Constitution Principles VI (Mobile First accessibility, including Reduce Motion) and IX (Localised Strings with user-selectable language).

**Independent Test**: Can be tested by opening `SettingsUi` in Studio, toggling **Reduce motion** on, changing **Music volume**, **Effects volume**, **Camera sensitivity**, and **Language**, verifying immediate client effect and server persistence in `profile.settings`, and rejoining in the private test place to confirm all settings persist.

**Acceptance Scenarios**:

1. **Given** a player taps the top-right **Settings** button, **When** `SettingsUi` opens, **Then** it displays controls with icons and localized labels (`≥ 18 px` text on phones) for Music volume (`0%`–`100%`), Effects volume (`0%`–`100%`), Camera sensitivity (`50%`–`200%`), Reduce motion (On/Off), and Language (`Auto`, `English`, `Español`), without covering the top-centre run timer.
2. **Given** a player changes any setting in `SettingsUi`, **When** the control is adjusted, **Then** the client immediately applies the new value (audio volumes in `Feedback`, camera sensitivity in `CameraController`, motion reduction in `Feedback`/`CameraController`, and active locale in `Localizer`) and sends an update intent to the server.
3. **Given** the server receives a settings update intent from a client, **When** `DataService` validates the payload, **Then** it runtime type-checks every field, clamps numeric values to their legal ranges (`musicVolume` and `effectsVolume` in `[0, 1]`, `cameraSensitivity` in `[0.5, 2.0]`), restricts `language` to allowed locale codes (`"auto"`, `"en-us"`, `"es-es"`), rejects malformed payloads without erroring, and saves the valid settings into `profile.settings`.
4. **Given** a player with saved non-default settings rejoins the game, **When** their profile loads on join, **Then** their saved settings are replicated and applied before or as their first run starts.

---

### User Story 4 - Persistent Economy HUD, Hub Best Size, andResults Best-Size Integration (Priority: P2)

A player's persistent coin balance and per-world best size (`bestSize[worldId]`) are visible where they matter: the Hub screen shows the player's persistent coin total and best size for the active world, the Results screen compares the run's final size against their persistent all-time best size for that world (as well as friends in the server), and the top-right HUD button bar provides clear, phone-readable access to **Book**, **Shop** (disabled during a run and showing `"After this run"` per design brief §4), and **Settings**.

**Why this priority**: Connects the server-side economy and `bestSize` data in `DataService` to the player-facing loop on the Hub, HUD, and Results screens (`docs/rollossal-gdd.md` §3.5, §4).

**Independent Test**: Can be tested by completing two runs where Run 1 achieves a larger diameter than Run 2, verifying that `bestSize[worldId]` on both the Results screen and Hub retains Run 1's higher diameter while `coins` equals the sum of both runs.

**Acceptance Scenarios**:

1. **Given** a player completes Run 1 with diameter `18.5` studs and `12` coins, and then completes Run 2 in the same world with diameter `14.0` studs and `8` coins, **When** viewing the Results screen after Run 2 and then returning to the Hub, **Then** the player's persistent coin total shows `20` coins and their best size for the world remains `18.5` studs.
2. **Given** a player is in an active run or in the Hub, **When** viewing the top-right button bar, **Then** the **Book**, **Shop**, and **Settings** buttons each display both an icon and a localized label (`≥ 18 px`), and tapping **Shop** during a run shows the localized `"After this run"` notice rather than opening a shop overlay.

---

### Edge Cases

- **Profile Load Failure or Timeout**: If ProfileStore returns `nil` (e.g., DataStore outage, session lock unrecoverable, or player disconnects mid-load), the server MUST immediately kick the player (if still connected) with a friendly localized message and MUST NOT create an in-memory fallback profile that could lose progress or overwrite existing saved data.
- **Session Lock Stolen / External Release (`OnSessionEnd`)**: Two servers MUST NEVER hold the same player's profile concurrently. If `profile.OnSessionEnd` fires while the player is still in the server, the server kicks the player cleanly and cleans up their session state.
- **Duplicate or Late Run Result (`runId` Idempotency)**: If `DataService.applyRunResult` is called more than once with the same `runId`, or called after the player's profile session has already ended, the duplicate/late call MUST grant nothing and mutate nothing.
- **Best Size Monotonicity**: If a player's new run finishes at a smaller or equal diameter than their recorded `profile.bestSize[worldId]`, `bestSize[worldId]` MUST remain unchanged; it only ever increases.
- **Non-Negative Coins Guarantee**: `profile.coins` MUST start at `0`, only increase from non-negative run coin rewards, and reject or clamp any attempt to apply a negative coin delta so coins never go negative.
- **Collection Book Set Semantics**: Absorbing the same `bookId` multiple times within one run or across multiple runs MUST store that `bookId` only once in `profile.book` and MUST NOT double-count page progress or re-grant a page completion reward already in `profile.skinsOwned`.
- **Book UI Opening Guard During Run Start & Timer Visibility**: Opening `BookUi` MUST be blocked during the first `Config.runStartUiLockSeconds` (`5` seconds) of an active run so it cannot block the first-5-seconds pickup requirement (Constitution Principle VI), and when `BookUi` or `SettingsUi` is open during a run, its panel layout MUST leave the top-centre timer (`mm:ss`) visible.
- **Malformed Client Settings Payloads**: If a client fires the settings update remote with a non-table argument, `NaN` numbers, out-of-range values, unknown keys, or a non-supported language code, the server MUST ignore invalid fields and clamp numeric ranges without throwing an error or corrupting `profile.settings`.
- **Test Isolation from Live DataStores**: Automated tests in `tests/studio` and sessions in the private test place / Studio test mode MUST use ProfileStore's mock store (`ProfileStore.Mock`) and MUST NEVER read or write the production DataStore.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Profile Schema v1 & Pure Collection Book / Profile Rules (`src/shared/Rules`)

- **FR-001**: A shared schema/rules module MUST define Profile Schema v1 (`version = 1`) with the exact owner-approved field names (`version`, `coins`, `worldsUnlocked`, `skinsOwned`, `equipped`, `book`, `bestSize`, `receipts`, `appliedRuns`, `settings`) and default factory values, storing only gameplay progress keyed by numeric Roblox `UserId` and zero personal data (Constitution Principle VIII).
- **FR-002**: `src/shared/Rules` MUST include a pure collection book module (`src/shared/Rules/Book.luau`) with zero Roblox API dependencies (Constitution Principle III) that provides:
  - Filtering/identifying new `bookId`s from a run's absorbed `bookId` list against an existing `book` set (`{ [string]: boolean }`);
  - Grouping a world's object definitions by `tier` into ordered book pages and computing per-page progress (`collectedCount`, `totalCount`, `isComplete`);
  - Determining which tier-page completion cosmetic rewards (`rewardId`) are newly unlocked when a player's `book` set is updated.
- **FR-003**: `src/shared/Rules` MUST include pure profile update and migration helper functions (testable in Lune as well as Jest-Lua) for:
  - Reconciling a partial profile table with v1 defaults without overwriting existing valid fields;
  - Running the versioned migration table (`migrations[version]`) from a profile's stored `version` up to current `SCHEMA_VERSION = 1` (shipping with the new-profile path and a v1 identity/unchanged check);
  - Applying a `RunResult` idempotently by `runId` (updating `coins` non-negatively, raising `bestSize[worldId]` monotonically, inserting `book` entries as a set, granting completed page rewards into `skinsOwned`, and recording `runId` so repeated calls are no-ops);
  - Validating and clamping a settings table (`musicVolume` in `[0, 1]`, `effectsVolume` in `[0, 1]`, `cameraSensitivity` in `[0.5, 2.0]`, `reduceMotion` boolean, `language` in `{"auto", "en-us", "es-es"}`).

#### Part B: Server DataService & RunManager Integration (`src/server`)

- **FR-004**: `src/server/DataService.luau` MUST use `ProfileStore` (`lm-loleris/profilestore@1.0.3` from `wally.toml`) to load each joining player's profile via `StartSessionAsync` with a session lock, reconcile missing fields, run migrations up to `version = 1`, wire `profile.OnSessionEnd` to clean up session state and kick the player if the session ends while they are still connected, release the profile on `Players.PlayerRemoving`, and release/save all active profiles inside `game:BindToClose`.
- **FR-005**: `DataService` MUST support a mock mode (using `ProfileStore.Mock` in Studio tests and when configured for test places) so that automated tests in `tests/studio` never write to the live DataStore.
- **FR-006**: If `StartSessionAsync` fails or returns `nil` for a joining player, `DataService` MUST kick the player with a friendly localized message (`Localizer.t("error.profile_load_failed", nil, playerLocale)`) and MUST NOT allow the player to play an unsaved session.
- **FR-007**: `RunManager` and `DataService` MUST integrate so that:
  - `newBookIds` on `RunResult` are computed against the player's persistent `profile.book` set;
  - `bestSelfSize` on `RunResult` reflects the player's updated persistent `profile.bestSize[worldId]`;
  - Every completed `RunResult` is applied to `DataService` **at most once per `runId`**, and the updated profile state (`coins`, `bestSize`, `book`, `skinsOwned`, `completedRunsCount` / first-run flag) is replicated to the player's client.
- **FR-008**: `Remotes` and `DataService` MUST expose a client-to-server `UpdateSettings` remote event that accepts a single candidate settings payload from the client, validates and clamps all fields through the pure settings validator (never trusting raw client types or out-of-bounds numbers), updates `profile.settings`, and replicates the authoritative settings back to the client.

#### Part C: Content Data & Configuration (`src/shared/Content`, `src/shared/Config`)

- **FR-009**: World tier definitions in `src/shared/Content` (`SizeTierDef` in `GreyBoxRoom.luau` and future worlds) MUST include an optional or required page completion reward definition (`rewardId: string`, `rewardType: "skin" | "trail"`, `rewardNameKey: string`) so completing all collection book entries in a tier grants that cosmetic reward in `profile.skinsOwned` without code changes when new worlds or tiers are added.
- **FR-010**: `src/shared/Config.luau` MUST define the saving, UI, and settings constants in one place: `dataStoreName = "PlayerProfiles_v1"`, `playerKeyPrefix = "Player_"`, `useMockDataStoreInStudio = true`, `runStartUiLockSeconds = 5`, and default/bounds constants for `musicVolume` (`0.8`, `[0, 1]`), `effectsVolume` (`0.8`, `[0, 1]`), `cameraSensitivity` (`1.0`, `[0.5, 2.0]`), `reduceMotion` (`false`), and supported `languages` (`{ "auto", "en-us", "es-es" }`).

#### Part D: Collection Book UI, Settings UI, HUD & Results Enhancements (`src/client`)

- **FR-011**: `Hud` MUST render a top-right button bar containing at most 3 icon+label buttons (`Book`, `Shop`, `Settings`) readable on phones (`≥ 18 px` text, dark `UIStroke` outline, `UIScale` per viewport). Tapping **Book** toggles `BookUi` (except during the first `Config.runStartUiLockSeconds = 5` seconds of an active run, when opening `BookUi` is suppressed); tapping **Settings** toggles `SettingsUi`; tapping **Shop** during a run displays a brief localized `"After this run"` indicator (`ui.hud.shop_after_run`).
- **FR-012**: `BookUi` (`src/client/BookUi.luau`) MUST render the active world's collection book grouped by size tier into pages, displaying:
  - Tier page selector/headers with localized tier name, page completion progress (`"{collected} / {total}"` with icon and label), and page reward status (icon + localized reward name and locked/earned badge);
  - A responsive grid of object cards for that tier where discovered objects show their icon and localized name and undiscovered objects show a dark silhouette icon and localized unknown label (`"???"`);
  - Phone-first layout (`≥ 18 px` text, touch targets `≥ 96 px` for primary navigation/close controls) positioned below the top bar so it NEVER covers the top-centre run timer (`mm:ss`).
- **FR-013**: `SettingsUi` (`src/client/SettingsUi.luau`) MUST render controls with icons and localized labels (`≥ 18 px` text on phones, never covering the top-centre timer) for **Music volume**, **Effects volume**, **Camera sensitivity**, **Reduce motion**, and **Language**, applying changes immediately on the client (`Feedback` audio volumes and motion toggle, `CameraController` sensitivity and shake suppression, `Localizer` locale override) and firing `Remotes.UpdateSettings` to persist them.
- **FR-014**: `ResultsUi` and `HubUi` MUST display the player's persistent `bestSize` for the current world and persistent `coins` balance, list any first-time objects collected in the run under `"New in your book"` with icons and localized names, and on the player's first completed run display a localized onboarding explanation of coins and the collection book (`ui.results.first_run_tip`).

#### Part E: Localisation & Automated Tests (`Constitution Principles III, VIII, IX`)

- **FR-015**: Every new player-facing string in `BookUi`, `SettingsUi`, `Hud`, `ResultsUi`, `HubUi`, tier page rewards, and the profile-load kick message MUST live in `src/shared/Localization/Strings.luau` and resolve through `Localizer`, with `Localizer` supporting an active language override from `settings.language` (`"auto"`, `"en-us"`, `"es-es"`).
- **FR-016**: Lune unit tests in `tests/unit` MUST test:
  - Pure collection book page progress (`collected / total`), page-complete checks, new `bookId` filtering, and tier-page cosmetic reward unlocking;
  - Pure profile default initialization, missing-field reconciliation, v1 migration identity, idempotent `runId` application, non-negative coin enforcement, monotonic `bestSize`, and settings validation/clamping;
  - Content and localization completeness for all new strings and tier reward keys.
- **FR-017**: Jest-Lua Studio integration tests in `tests/studio` (using the ProfileStore mock store, never writing to the live DataStore) MUST test:
  - Loading a brand-new profile populates all v1 defaults;
  - Loading a profile with missing fields reconciles them with defaults while preserving existing fields;
  - Applying a `RunResult` adds coins, updates `bestSize[worldId]`, adds `book` entries as a set, grants completed page rewards, and is strictly idempotent per `runId` (a repeated or late `runId` grants nothing);
  - Coins never go negative and `bestSize[worldId]` only increases;
  - The v1 migration table test passes and a v1 profile loads unchanged;
  - A simulated profile load failure kicks the player with a localized message rather than letting them play unsaved.

### Key Entities

- **PlayerProfile (v1)**: Persistent per-player data record stored in ProfileStore under key `"Player_<UserId>"`. Attributes: `version` (`1`), `coins` (non-negative integer), `worldsUnlocked` (`{ [string]: boolean }`), `skinsOwned` (`{ [string]: boolean }`), `equipped` (`{ skin: string?, trail: string? }`), `book` (`{ [string]: boolean }`), `bestSize` (`{ [string]: number }`), `receipts` (`{ string }`), `appliedRuns` (`{ [string]: boolean }`), `settings` (`PlayerSettings`).
- **PlayerSettings**: Sub-record of `PlayerProfile` controlling client audio, camera, accessibility, and localization preferences. Attributes: `musicVolume` (`0.0`–`1.0`), `effectsVolume` (`0.0`–`1.0`), `cameraSensitivity` (`0.5`–`2.0`), `reduceMotion` (`boolean`), `language` (`"auto" | "en-us" | "es-es"`).
- **BookPageSummary**: Computed view produced by `src/shared/Rules/Book.luau` for a single tier in a world. Attributes: `tier` (`number`), `nameKey` (`string`), `collectedCount` (`number`), `totalCount` (`number`), `isComplete` (`boolean`), `rewardId` (`string`), `rewardNameKey` (`string`), `rewardEarned` (`boolean`), `entries` (list of `{ bookId, nameKey, icon, isDiscovered }`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Coins, per-world best size, collection book entries, owned page-completion rewards, and player settings survive leaving and rejoining in 100% of sessions (verified in Jest-Lua Studio tests and in the private test place).
- **SC-002**: ProfileStore session locking prevents two servers from holding the same player profile concurrently, and 100% of simulated profile load failures kick the player with a localized message rather than allowing unsaved play.
- **SC-003**: Submitting the same `runId` multiple times (or after session close) produces zero duplicate coin grants or state mutations in 100% of test cases.
- **SC-004**: `BookUi` and `SettingsUi` render without text clipping or overlap and without covering the top-centre run timer at phone resolutions (`640x360`, `844x390`, `1280x720`), with all text `>= 18 px` (verified via Studio MCP viewport captures).
- **SC-005**: 100% of Lune unit tests in `tests/unit` and Jest-Lua Studio tests in `tests/studio` pass using the ProfileStore mock store (zero live DataStore writes from tests), `scripts/check.sh` exits `0`, and a Studio playtest completes with zero new console errors or warnings.

## Scope & Boundaries

### In Scope

- `DataService` on the server backed by ProfileStore `1.0.3` (session locking, missing-field reconciliation, versioned migration table with v1 test, `BindToClose` save, kick with localized message on load failure, mock store in Studio/tests).
- Profile Schema v1 (`version`, `coins`, `worldsUnlocked`, `skinsOwned`, `equipped`, `book`, `bestSize`, `receipts`, `appliedRuns`, `settings`) and client replication.
- Idempotent application of `RunResult` from Feature 002 keyed by `runId` (coins added, `bestSize` raised if beaten, `bookId`s added to `book` set, tier-page completion rewards granted to `skinsOwned`).
- Pure collection book rules (`src/shared/Rules/Book.luau`) for page progress (`collected / total`), page completion, and reward unlocking, tested in Lune.
- `BookUi` screen (tier pages, silhouettes for unknown objects, page progress, reward status, top-right Book button, 5-second run-start lock, timer stays visible).
- `SettingsUi` screen (music volume, effects volume, camera sensitivity, reduce motion, language) saved in profile and applied on join and live.
- Results screen `"New in your book"` object list, first-results-screen explanation of coins and the book, and persistent `bestSize` / `coins` display on Results and Hub.

### Out of Scope

- Robux purchases, game passes, developer products, Shop UI, and `ProcessReceipt` implementation (Feature 006; only the `receipts`, `skinsOwned`, and `equipped` schema fields and page-reward grant mechanism are established here).
- Snow Village 60 Blender objects and 3D cosmetic skin/trail assets (Feature 004 and Feature 006).
- Full first-60-seconds tutorial arrow, analytics funnel events, and complete Spanish translation pass (Feature 007).
- World unlock spending UI, Candy Town reskin, and ball cores (Feature 011; coins accumulate in the MVP until Candy Town unlocks).
- Daily golden object and weekly object drops (Feature 012).

## Assumptions

- **Approved DataStore Name and Schema Keys (Confirmed by Owner)**: Uses ProfileStore DataStore name `"PlayerProfiles_v1"` and key format `"Player_<UserId>"` with the v1 schema keys listed in the Owner Approval Gate section (`version`, `coins`, `worldsUnlocked`, `skinsOwned`, `equipped`, `book`, `bestSize`, `receipts`, `appliedRuns`, `settings`).
- **MVP Coin Sink Scope (Confirmed by Owner)**: Coins accumulate in `profile.coins` during the single-world MVP and become spendable when Candy Town and world unlocks/ball cores ship in Feature 011.
- **Run-Start Book Lock Window**: To satisfy "It must not open during a run's first seconds or cover the timer", the Book button ignores open requests during the first `5` seconds of an active run (`Config.runStartUiLockSeconds = 5`), protecting the Constitution Principle VI requirement that a player rolls up their first object within 5 seconds of joining.
- **First Results Screen Explanation Trigger**: A player's "first results screen" is detected when their profile transitions from `0` applied runs to `1` applied run, displaying the localized book-and-coins tip on `ResultsUi` once without requiring a separate schema migration prior to Feature 007.
