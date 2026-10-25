---

description: "Task list for Saving and Economy (003-saving-and-economy)"
---

# Tasks: Saving and Economy

**Input**: Design documents from `/specs/003-saving-and-economy/`

**Prerequisites**: plan.md, spec.md, research.md (R1 to R14), data-model.md, contracts/ (`remotes.md`, `replicated-state.md`, `rules-api.md`, `content-and-config.md`, `ui.md`), quickstart.md, `.specify/memory/constitution.md` (v1.0.0)

**Tests**: Requested by the spec (FR-016, FR-017, SC-005). Lune unit tests for every new `src/shared/Rules` function, Config, grey-box rewards and Strings; Jest-Lua Studio tests for `DataService` and the touched `RunManager` on the ProfileStore mock store. Expected values are written out by hand from `contracts/rules-api.md`; never compute them by calling the code under test. Tests are listed before the code they cover and must fail first.

**Organization**: Tasks are grouped by user story. The pure rules, Config, Content, Strings, `Localizer`, remotes, `UiKit` helpers, `ProfileClient` and `TopBar` are shared by several stories, so they sit in Phase 2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with the other `[P]` tasks of the same phase (different files, no dependency on an unfinished task)
- **[Story]**: US1 to US4, matching the user stories in spec.md
- Every task names the exact file or files it touches

## Conventions

- Every `.luau` file starts with `--!strict` (Constitution XII).
- **Rules purity** (Constitution III, plan "Design Notes" 9): files in `src/shared/Rules` have no `require` of each other and never contain the words `game`, `task`, `Enum`, `Instance`, `workspace`, `tick` or `require(script`, comments included. Bounds, defaults and the reward lookup enter as arguments built from `Config` by the caller. Lune tests pass literal tables, so expected values never come from `Config`.
- All numbers come from `src/shared/Config.luau`; no magic numbers in server or client scripts.
- Every player-facing string is a `Strings.luau` key read through `Localizer.t`; `LiteralGuard.test.luau` rejects letter-bearing `Text` literals. Icons come from `Content/Icons.luau`.
- Text is at least `Config.minTextSize` (18). Utility controls (TopBar buttons, Book Prev/Next/Close, Settings controls) are at least `Config.minUtilityTouchTarget` (64); Roll again, Play and Jump stay at 96. Status is never colour alone.
- The client sends only `RequestProfile()` and `UpdateSettings(payload)`. Nothing the client sends may set coins, best size, book, rewards or run results (Constitution II).
- New behaviour sits behind `Config.Flags.Saving`; with it off the game is exactly 002.
- **Studio MCP claim** (Constitution X): tasks marked `🔒 Studio` drive Roblox Studio through the Studio MCP server. Only one agent may do this at a time. Before starting, append ` CLAIMED:<agent>` to the task line; remove it when done.
- **Human task**: tasks marked `👤` need people (playtesters, the owner). An agent only prepares them.
- Each task ends with `scripts/check.sh` exiting 0. Quality Gate 2 (Studio playtest with console read, phone-resolution capture for UI) is covered by the `🔒 Studio` task at the end of each story phase; the PR description says how each gate was met.
- Implementation starts only after 002 is merged to `main` and this branch is up to date (plan finding F-1). T001 checks it.

## Path Conventions

Roblox project, Rojo tree as in plan.md "Project Structure": `src/shared` (ReplicatedStorage.Shared), `src/server` (ServerScriptService), `src/client` (StarterPlayer.StarterPlayerScripts), `tests/unit` (Lune), `tests/studio` (Jest-Lua, ServerStorage.Tests), `specs/003-saving-and-economy/`.

---

## Phase 1: Setup

**Purpose**: Make sure the 002 code this feature edits is on the branch and the toolchain is healthy.

- [X] T001 Bring the branch up to date with 002 (plan finding F-1). Confirm 002 is merged to `main`, then merge `main` into `003-saving-and-economy`. Confirm these files now exist: `src/server/RunManager.luau`, `src/server/Remotes.luau`, `src/client/RunClient.luau`, `src/client/UiKit.luau`, `src/client/Hud.luau`, `src/client/HubUi.luau`, `src/client/ResultsUi.luau`, `src/client/Feedback.luau`, `src/client/CameraController.luau`, `src/shared/Worlds.luau`, `src/shared/Localization/Localizer.luau`, `src/shared/Localization/Strings.luau`, `src/shared/Rules/RunClock.luau`, `tests/studio/RunManager.spec.luau`, `tests/unit/RunClock.test.luau`, `tests/unit/Strings.test.luau`. If 002 is not merged yet, stop and report; do not copy 002 code by hand. Run `scripts/check.sh` and record that it exits 0 as the baseline.
- [X] T002 Confirm ProfileStore 1.0.3 is available to the server: run `wally install` if needed, check that `ServerPackages/` contains `lm-loleris/profilestore@1.0.3` and that `default.project.json` maps `ServerPackages` under `ServerScriptService`. Skim `ServerPackages/_Index/*/profilestore*/docs/api.md` for `StartSessionAsync`, `Cancel`, `OnSessionEnd`, `EndSession`, `IsActive`, `AddUserId`, `Mock`. Do not edit `wally.toml` or `wally.lock` (no new packages, Constitution XII); if the package or mapping is missing, stop and report.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure rules with Lune tests, Config, Content, Strings, `Localizer`, remotes, shared UI helpers, the client data module and the TopBar. Every user story needs these.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Lune tests for the Rules (write first, expected to fail until the Rules exist)

- [X] T003 [P] Create `tests/unit/Profile.test.luau` with every case in `contracts/rules-api.md` §`Profile.luau` "Test values": defaults (two calls give different tables), reconcile fills, reconcile keeps, reconcile repairs (`coins = "12"` becomes 0, `book = 5` becomes `{}`), reconcile negative (`coins = -3` becomes 0), prepare new, prepare v1 unchanged (`appliedRuns` ends empty), prepare future (`false, "FutureVersion"`, coins still 5, version still 2), prepare bad (`version = "x"` and `version = 0` give `false, "BadVersion"`), migrate mechanism (coins 5 doubled to 10, version 2), migrate two steps, migrate missing (`false, "MissingMigration"`, version 1), migrate v1 identity, and apply cases A1 to A13 with `rewardsFor = function(book) return if book["greybox.cube_t1"] then { "r1" } else {} end`. Use the defaults argument `D` from the contract as a literal. Also assert that a rejected apply leaves `data` unchanged (compare coins, bestSize, book, skinsOwned, appliedRuns).
- [X] T004 [P] Create `tests/unit/Book.test.luau` with every case in `contracts/rules-api.md` §`Book.luau` "Test values": `newIds({ "b", "z", "b", "a" }, { a = true })` is `{ "b", "z" }`; `newIds({}, {})` is `{}`; pages partial (page 1 collected 2, total 4, `rewardEarned false`, entries discovered `{ true, false, true, false }`; page 2 is 0 / 1 with `rewardId` nil); pages complete (`completedRewardIds` is `{ "r1" }`); reward earned; pages order (tiers given as tier 2 then tier 1 come back in that order); empty page (`totalCount 0`, `isComplete false`, reward not in `completedRewardIds`); entries fields; unknown book id; arguments are not mutated.
- [X] T005 [P] Create `tests/unit/Settings.test.luau` with every row in `contracts/rules-api.md` §`Settings.luau` "Test values": `current = { musicVolume = 0.8, effectsVolume = 0.8, cameraSensitivity = 1, reduceMotion = false, language = "auto" }`, bounds `0..1`, `0..1`, `0.5..2`, languages `{ "auto", "en-us", "es-es" }`. Include `0/0`, `math.huge`, `"0.5"`, unknown key `volume`, `"ES-ES"`, `"fr-fr"`, the mixed-fields row (`musicVolume 0.5` and `reduceMotion true` applied, language kept), the non-table candidates `"hello"`, `5`, `nil`, `true`, `{}`, and that the returned table is not `current` and `current` is unchanged.
- [X] T006 [P] Edit `tests/unit/RunClock.test.luau`: add the `uiLocked` table from `contracts/rules-api.md` §`RunClock.luau` addition (`duration = 240`, `endsAt = 240`, `lockSeconds = 5`): now 0 true, 4.99 true, 5 false, 100 false, 240 false, 300 false, -1 true.

### Pure Rules (standalone, no requires between modules)

- [X] T007 [P] Create `src/shared/Rules/Profile.luau` exporting the types and functions in `contracts/rules-api.md` §`Profile.luau`: `SCHEMA_VERSION = 1`, `migrations = {}`, `defaults`, `reconcile`, `migrate`, `prepare`, `applyRunResult(data, result, rewardsFor)`. Constraints to implement exactly (data-model §2 and the contract): `coins` "must be a finite number that is zero or more; anything else (a string, a negative, NaN) becomes `0`, and any valid stored number is kept as is"; `reconcile` fills a missing key from defaults, replaces a wrong-typed key with its default, reconciles `settings` field by field, and "never recurses into `worldsUnlocked`, `skinsOwned`, `book`, `bestSize` or `appliedRuns` beyond requiring that each is a table"; `version` is left alone by `reconcile` (`migrate` owns it); `migrate` returns `false, "BadVersion"` when `version` is not a finite integer ≥ 1, `false, "FutureVersion"` when it exceeds `target`, `false, "MissingMigration"` when a step has no function; `prepare` ends with `data.appliedRuns = {}` (plan finding F-2); `defaults` returns a fresh deep copy on every call with `equipped = {}`, `receipts = {}`; `applyRunResult` follows the 8 ordered steps (Invalid, Duplicate, `isFirstRun = next(data.bestSize) == nil`, `coinsGained = max(0, floor(coins))`, `bestSize[worldId] = max(old or 0, finalDiameter)`, book set insert, `rewardsFor(data.book)` grants into `skinsOwned`, ledger write) and writes nothing before the checks pass. Invariants: `coins ≥ 0`; `bestSize[w]` never decreases; `book[id]` is `true` or absent; `skinsOwned[id]` is `true` or absent. Makes T003 pass.
- [X] T008 [P] Create `src/shared/Rules/Book.luau` exporting the types and `newIds`, `pages`, `completedRewardIds` from `contracts/rules-api.md` §`Book.luau`. `newIds` keeps first-seen order and drops duplicates and ids already in `book`; `pages` returns one `PageSummary` per tier in the order of `tiers` (no re-sort) with `entries` in the order of `objects`; `isComplete` is `totalCount > 0 and collectedCount == totalCount`; `rewardEarned` is `rewardId ~= nil and skinsOwned[rewardId] == true`; `completedRewardIds` lists the `rewardId` of every complete page that has a reward, in tier order. Arguments are never mutated. Makes T004 pass.
- [X] T009 [P] Create `src/shared/Rules/Settings.luau` exporting the types and `validate(current, candidate, bounds)` from `contracts/rules-api.md` §`Settings.luau`. Declare its own `SettingsData` type (no require). Per field and independently: a finite number is clamped to `[min, max]`, any other value is ignored; `reduceMotion` accepts only a boolean; `language` accepts only a string equal (case-sensitive) to an entry of `bounds.languages`; a non-table `candidate` returns a copy of `current`; unknown keys are ignored; NaN and infinite numbers are ignored; the result is always a new table. Ranges to honour through `bounds` (data-model §3): `musicVolume` 0 to 1, `effectsVolume` 0 to 1, `cameraSensitivity` 0.5 to 2.0, `language` one of `"auto"`, `"en-us"`, `"es-es"` (exact, lower case). Makes T005 pass.
- [X] T010 [P] Edit `src/shared/Rules/RunClock.luau`: add `uiLocked(now: number, endsAt: number, duration: number, lockSeconds: number): boolean` with `elapsed = duration - remaining(now, endsAt)` and result `elapsed < lockSeconds`, reusing the module's existing `remaining` logic (no require). Makes T006 pass.

### Config, Content, Strings, Localizer

- [X] T011 [P] Edit `src/shared/Config.luau` and `tests/unit/Config.test.luau`. Add exactly the keys of `contracts/content-and-config.md` §Config shape: `dataStoreName = "PlayerProfiles_v1"`, `playerKeyPrefix = "Player_"`, `useMockDataStoreInStudio = true`, `runStartUiLockSeconds = 5`, `settingsRateLimit = 20`, `settingsSendDelay = 0.3`, `minUtilityTouchTarget = 64`, `noticeSeconds = 2`, `Settings = { musicVolume = { default = 0.8, min = 0, max = 1 }, effectsVolume = { default = 0.8, min = 0, max = 1 }, cameraSensitivity = { default = 1.0, min = 0.5, max = 2.0 }, reduceMotionDefault = false, languageDefault = "auto", languages = { "auto", "en-us", "es-es" } }`, `DefaultWorldsUnlocked = { greybox = true, snow_village = true }`, and `Flags.Saving = true`, `Flags.Shop = false` added to the existing `Flags` table. Top-level numbers must be positive and finite; nested tables may hold zero. Tests (hand-written values): data store name, prefix and lock seconds equal the values above; each `default` lies inside its `[min, max]`; `min < max`; `languages` equals `{ "auto", "en-us", "es-es" }`; `languageDefault` is in `languages`; `minUtilityTouchTarget < minTouchTarget` and `>= minTextSize`; `Flags.Saving == true`, `Flags.Shop == false`.
- [X] T012 [P] Edit `src/shared/Content/GreyBoxRoom.luau` and `tests/unit/GreyBoxRoom.test.luau`. Add `export type RewardDef = { rewardId: string, rewardType: "skin" | "trail", nameKey: string }` and the optional `reward: RewardDef?` field on `SizeTierDef` (data-model §9). Add the four grey-box rewards: tier 1 `greybox.reward.tier1` trail `reward.greybox.tier1.name`; tier 2 `greybox.reward.tier2` trail `reward.greybox.tier2.name`; tier 3 `greybox.reward.tier3` skin `reward.greybox.tier3.name`; tier 4 `greybox.reward.tier4` skin `reward.greybox.tier4.name`. Tests: reward ids non-empty and unique across tiers; `rewardType` is `skin` or `trail`; every reward `nameKey` exists in `Strings` (written as a hand-copied list, not read from the content); a tier without `reward` is allowed; every object's `tier` has a `sizeTiers` entry; every object's `bookId` is unique.
- [X] T013 [P] Edit `src/shared/Content/Icons.luau`: add glyphs `gear` `⚙`, `shop` `🛒`, `lock` `🔒`, `unknown` `❓`, `prev` `◀`, `next` `▶`, `close` `✕`, `check` `✔` (`contracts/content-and-config.md` §Icons). A glyph that fails to render in `FredokaOne` or `GothamMedium` is replaced by an emoji in this file only; that check is part of T045.
- [X] T014 [P] Edit `src/shared/Localization/Strings.luau` and `tests/unit/Strings.test.luau`. Change each entry to `{ en: string, es: string? }` (existing 002 entries keep `en` only). Add every key in the table of `contracts/content-and-config.md` §Strings (`ui.topbar.*`, `ui.hud.shop_after_run`, `ui.hud.shop_soon`, `ui.common.close`, `ui.book.*`, `ui.settings.*`, `ui.hub.coins`, `ui.hub.best_size`, `ui.results.coins_total`, `ui.results.first_run_tip`, `reward.greybox.tier1.name` to `tier4.name`, `error.profile_load_failed`, `error.profile_version`, `error.session_ended`) with the exact English and Spanish text and placeholders from that table. Tests: copy the full key list by hand into the test and assert each key exists; `es` present on every key added here; the set of `{placeholder}` names is equal between `en` and `es` for each; extend the existing "every `Localizer.t("…")` literal exists" check from `src/client` to `src/server` as well (the server now calls `Localizer.t` for kick messages).
- [X] T015 Edit `src/shared/Localization/Localizer.luau` (depends on T014): `Localizer.t(key, args?, localeId?)` with locale order `localeId` argument, then the override (when not `"auto"`), then `LocalizationService.RobloxLocaleId`, then `en-us`; a key with no text for the chosen locale falls back to `en-us`; an unknown key still returns the key. Register an `es-es` table from entries that have `es`. Add `Localizer.setLanguage(code)` (`"auto"`, `"en-us"`, `"es-es"`; anything else ignored), `Localizer.getLanguage()`, and `Localizer.changed` as a plain callback list with `Connect(self, fn)` (no `BindableEvent`) fired only after a real change. Spec FR-015, `contracts/content-and-config.md` §Localizer changes.

### Remotes, shared UI helpers, client data

- [X] T016 [P] Edit `src/server/Remotes.luau`: create three more `RemoteEvent`s in `ReplicatedStorage.Remotes`: `UpdateSettings` (client to server), `RequestProfile` (client to server), `ProfileSync` (server to client). The folder then holds twelve events (`contracts/remotes.md`). Do not connect handlers here.
- [X] T017 [P] Edit `src/client/UiKit.luau`: add an optional `minSize` option to `button` (default stays 96×96; TopBar and panel controls pass `Config.minUtilityTouchTarget`), an optional `displayOrder` argument to `screen`, and reusable `panel`, `slider` and `toggle` helpers per `contracts/ui.md` (slider: track 208×24, handle 40×40, whole 56 px row is the drag area, value reported as a raw 0 to 1 fraction; toggle: 224×64 with check or off glyph plus On/Off label). All text uses the dark `UIStroke` and `FredokaOne`/`GothamMedium`. No letter-bearing `Text` literals.
- [X] T018 [P] Edit `src/client/RunClient.luau`: `parseResult` accepts the new fields `coinsTotal: number?` and `isFirstRun: boolean` (additive, `contracts/remotes.md` §RunResult change); a payload without them parses with `coinsTotal = nil` and `isFirstRun = false`. Expose them on the parsed result type.
- [X] T019 Create `src/client/ProfileClient.luau` (depends on T011, T016): the single reader of `ProfileSync` (`contracts/replicated-state.md`). Connect `ProfileSync` first, then fire `RequestProfile` (closes the join race); `parse(snapshot)` type-checks every field and drops the whole snapshot on any problem, never throws; cache with defaults before the first snapshot (`isLoaded() == false`, `coins() == 0`, empty tables, `Config.Settings` defaults); expose `coins()`, `bestSize(worldId)`, `book()`, `skinsOwned()`, `equipped()`, `settings()`, `isLoaded()`, a `changed` callback-list signal, and `sendSettings(candidate)` which debounces `Config.settingsSendDelay` (0.3 s), flushes on `flush()` (called on panel close), and fires `Remotes.UpdateSettings` with one table of preferences only. The client never writes into the snapshot and never sends it back. No-op start when `Config.Flags.Saving` is false.
- [X] T020 Create `src/client/TopBar.luau` (depends on T010, T011, T013, T014, T017): own `ScreenGui` through `UiKit.screen` with a higher `displayOrder` so it stays above the Results dim layer; visible in states `Active`, `Ended`, `Hub` (`RunClient.state()`); top-right column anchored 8 px from the right and top edges, 8 px between buttons, three 150×64 buttons (`Config.minUtilityTouchTarget` high) `[book glyph] ui.topbar.book`, `[shop glyph] ui.topbar.shop`, `[gear glyph] ui.topbar.settings`, text 18 px (`contracts/ui.md` §TopBar). Expose `TopBar.bind(name: "book" | "settings", toggle: () -> ())` so `BookUi` and `SettingsUi` register their toggles without `TopBar` requiring them. Book tap is ignored while `RunClock.uiLocked(Workspace:GetServerTimeNow(), RunClient.endsAt(), Config.runDurationSeconds, Config.runStartUiLockSeconds)` is true in `Active`, and the button then shows `[lock glyph] ui.topbar.book` (glyph and text, not colour); recompute on `RunClient.stateChanged` and with one `task.delay(lock - elapsed)` refresh, no per-frame work. Shop tap opens nothing and shows a one-line 260×32 notice at y 224 for `Config.noticeSeconds` (`ui.hud.shop_after_run` in `Active`, `ui.hud.shop_soon` otherwise; both while `Config.Flags.Shop` is false), replaced by a newer notice and hidden on state change. A Book panel open when a new run starts is closed (`TopBar` fires a registered close callback; add `TopBar.onRunStart(fn)` for panels). One `refreshText()` re-applied on `Localizer.changed`. Start is a no-op when `Config.Flags.Saving` is false.
- [X] T021 Edit `src/client/Main.client.luau` (depends on T019, T020): when `Config.Flags.Saving` is true, start `ProfileClient` and `TopBar` after the existing 002 modules. No other wiring yet.

**Checkpoint**: `scripts/check.sh` exits 0 (all new Lune suites pass, purity guard green, luau-lsp strict clean). Foundation ready; user stories can begin.

---

## Phase 3: User Story 1 - Persistent Player Profile, Session Locking, and Idempotent Run Saving (Priority: P1) 🎯 MVP

**Goal**: A session-locked profile per player that survives leave and rejoin, with every run result applied exactly once, and a kick (never unsaved play) when it cannot load.

**Independent Test**: Jest-Lua suite `DataService.spec` and `RunManager.spec` pass on the mock store; in a Studio Play session complete a run, leave and rejoin, and read coins, best size and book back through MCP `execute_luau` unchanged (quickstart §2 and §3 steps 1 to 5 on the server side).

### Tests for User Story 1 (write first, ensure they FAIL before implementation)

- [X] T022 [P] [US1] Create `tests/studio/DataService.spec.luau` (Jest-Lua, `DataService.setStore(ProfileStore.New("test").Mock)`-style mock store, unique test user ids from 900001 up so no real key is touched, `setKick` and `setSync` seams to capture output): new profile has all v1 defaults (`version = 1`, `coins = 0`, empty `book` and `bestSize`, default `settings`); a partial stored profile is reconciled and saved values survive; a v1 profile loads unchanged (migration identity); apply adds coins, raises `bestSize`, inserts `book` entries as a set and grants a completed page reward into `skinsOwned`, and the captured `ProfileSync` snapshot carries the new values; a repeated `runId` and a late `runId` change nothing; apply after `release` returns `nil` and changes nothing; coins never go negative (`coins = -5`) and `bestSize` never decreases; `appliedRuns` is empty after a second `load` of the same user; a store stub whose `StartSessionAsync` returns `nil` makes `load` return false and the captured kick message equals `Localizer.t("error.profile_load_failed", nil, "en-us")`; a profile with `version = 2` is released unchanged and kicked with `error.profile_version`; `OnSessionEnd` while present kicks with `error.session_ended`; `DataService.shutdown()` releases every profile and later `applyRunResult` returns `nil`; `snapshot` and `getBook` return copies (mutating them does not change saved data). The suite never reads or writes a real DataStore key (spec edge case, FR-005).
- [X] T023 [P] [US1] Edit `tests/studio/RunManager.spec.luau`: with a mock profile loaded through `DataService`, the published result carries `coinsTotal` and `isFirstRun`, `newBookIds` is computed against the persistent `book`, and `bestSelfSize` is the persistent best; a user with no profile gets the 002 behaviour (`coinsTotal = nil`, `isFirstRun = false`) so every existing 002 test stays valid.

### Implementation for User Story 1

- [X] T024 [US1] Create `src/server/DataService.luau` (depends on T007, T008, T011, T015, T016): the API in `contracts/replicated-state.md` §Server-side API except `updateSettings` (added in T033). Store: `ProfileStore.New(Config.dataStoreName)`, switched to `.Mock` when `RunService:IsStudio() and Config.useMockDataStoreInStudio`; key `Config.playerKeyPrefix .. tostring(userId)`; no `template` argument (defaults, reconcile and migration are the pure Rules). `load(userId, player)` calls `StartSessionAsync(key, { Cancel = leftGame })` where `leftGame` returns `player.Parent == nil`, then `profile:AddUserId(userId)`, `Profile.prepare(profile.Data, defaults)` with `defaults` built from `Config.DefaultWorldsUnlocked` and `Config.Settings`, wires `profile.OnSessionEnd`, stores the profile, and sends `ProfileSync`. State machine of data-model §8: nil or error means kick with `Localizer.t("error.profile_load_failed", nil, player.LocaleId)` and one `warn` with the numeric `UserId` only; `prepare` returning `"FutureVersion"` or `"BadVersion"` means `EndSession` without changes and kick with `error.profile_version` and one `warn`; `OnSessionEnd` while the player is present means kick with `error.session_ended` and forget the entry; a player who left during load gets `EndSession` at once. Never create an in-memory fallback profile. `applyRunResult(userId, result)` checks `profile:IsActive()` and `shuttingDown` first (returns `nil`), calls `Profile.applyRunResult(profile.Data, result, rewardsFor)` where `rewardsFor = function(book) return Book.completedRewardIds(Worlds.sizeTiers, Worlds.active.objects, book) end`, fires `ProfileSync`, never yields, and returns the `Outcome`; ordinary rejections (duplicate, invalid) are silent. `snapshot` and `getBook` return copies; the snapshot holds only `coins`, `bestSize`, `book`, `skinsOwned`, `equipped`, `settings` (no `version`, `worldsUnlocked`, `receipts`, `appliedRuns`). `start()` is a no-op when `Config.Flags.Saving` is false; otherwise it connects `Players.PlayerAdded` (spawning `load`, also for players already present), `Players.PlayerRemoving` (`release`), `game:BindToClose` (`shutdown`), and the `RequestProfile` handler (zero arguments only, own `RateLimit` window using `Config.settingsRateLimit` per `Config.rateLimitWindow`, replies to the requester with `ProfileSync` when a profile is active, sends nothing while still loading). Expose the test seams `setStore`, `setKick`, `setSync`. Privacy: store only `UserId` and progress (Constitution VIII). Makes T022 pass.
- [X] T025 [US1] Edit `src/server/Main.server.luau`: when `Config.Flags.Saving` is true, `require` and call `DataService.start()` before `RunManager` is started, so a joining player starts their run at once while their profile loads in parallel (plan "Design Notes" 1).
- [X] T026 [US1] Edit `src/server/RunManager.luau` at the three seams of research R6: (1) `buildResult` reads `seen = DataService.getBook(userId) or seenBookIds[userId] or {}` and `best = DataService.getBestSize(userId, run.worldId) or bestSelfSize[userId] or 0`; (2) `endRun` calls `DataService.applyRunResult(userId, result)` after `buildResult` and, when non-nil, sets `result.coinsTotal = outcome.coinsTotal` and `result.isFirstRun = outcome.isFirstRun`, before the existing publisher call, so `ProfileSync` fires before `RunResult`; (3) `bestFriendSize` prefers `DataService.getBestSize(otherId, worldId)` over the in-memory map. Add `coinsTotal: number?` and `isFirstRun: boolean` (false when no profile) to the `RunResult` type. The in-memory maps stay as the fallback. With `Config.Flags.Saving` off the code path is exactly 002. Makes T023 pass.
- [X] T027 [US1] 🔒 Studio: sync the Rojo project, run `return require(game.ServerStorage.Tests.runner)()` through the Studio MCP `execute_luau` and confirm `DataService.spec` and `RunManager.spec` pass with 0 failures. Start a Play session, finish or expire a run, then inspect `DataService.snapshot(userId)` through `execute_luau`: coins, `bestSize`, `book` and `skinsOwned` are updated once. Remove and re-add the player in the same server (the mock store keeps the profile) and confirm the values are restored and `appliedRuns` is empty. Read the console: zero new errors or warnings (SC-005). Record results in `specs/003-saving-and-economy/playtest.md` (create the file if missing, quickstart §3).

**Checkpoint**: User Story 1 is fully functional and testable on its own: progress persists, runs apply once, load failure kicks.

---

## Phase 4: User Story 2 - Collection Book Screen, Page Progress, and First-Time Results Callouts (Priority: P1)

**Goal**: A Book screen with tier pages, silhouettes, `collected / total` and reward badges, a "New in your book" list on Results against the persistent book, and a first-run tip.

**Independent Test**: In Studio, open the Book after the 5 s lock with the timer visible, complete a page and see `1 / 1` and `Earned`, and see the first Results screen show the tip and the new entries (quickstart §4); Lune `Book` suite passes.

### Implementation for User Story 2

- [X] T028 [P] [US2] Create `src/client/BookUi.luau` (depends on T008, T017, T019, T020) per `contracts/ui.md` §BookUi: panel anchored top-left, 464×252 at x 8, y 100 (640×360 base), background `Color3(40,44,52)`, corner 16, below the timer and clear of the right-hand TopBar column; header row 64 with Prev `◀`, `ui.book.title` over `ui.book.page_progress` (`{collected} / {total}`, 20 px `FredokaOne`) plus tier name, Next `▶` and Close `✕`, each 64×64 (`Config.minUtilityTouchTarget`), Prev and Next dimmed with glyph kept on the first and last page; reward row 28 high (`[check or lock glyph] ui.book.reward` with the reward `nameKey`, then `ui.book.reward_earned` or `ui.book.reward_locked`, hidden when the tier has no reward); vertical `ScrollingFrame` grid of 108×84 cards with 8 px gaps (4 per row): discovered card is object icon (28 px) over the localized name (18 px, two lines allowed), undiscovered card is the `unknown` glyph in dark grey over `ui.book.unknown`. Data comes only from `Book.pages(Worlds.sizeTiers, Worlds.active.objects, ProfileClient.book(), ProfileClient.skinsOwned())`. Opens on the first page that is not complete (else the last). Exposes `toggle()` and `close()`; opening it closes `SettingsUi` (one panel at a time; use a small shared-open callback, not a require of `SettingsUi`). Rebuilds on `ProfileClient.changed` and `Localizer.changed` through one `refreshText()`. Closes itself when a new run starts (via `TopBar.onRunStart`). Opens before the first snapshot without error (defaults). Behind `Config.Flags.Saving`.
- [X] T029 [P] [US2] Edit `src/client/ResultsUi.luau`: list `newBookIds` under the existing `ui.results.new_entries` header with icon and localized name (at most 4 lines); when `result.isFirstRun` is true show `ui.results.first_run_tip` (two lines of 18 px, in the 270 px results column; shorten the string rather than the size if it does not fit) in place of the best-size row and cap the entry list at 3 lines (`contracts/ui.md` §Results screen additions). The panel stays 600×320. Add `Localizer.changed` handling through a single `refreshText()`. Spec FR-014, acceptance US2-2 and US2-3.
- [X] T030 [US2] Edit `src/client/Main.client.luau` (depends on T028): start `BookUi` and call `TopBar.bind("book", BookUi.toggle)` behind `Config.Flags.Saving`.
- [ ] T031 [US2] 🔒 Studio: playtest quickstart §4. Within the first 5 s tap Book: nothing opens and the lock glyph shows; after 5 s Book opens below the timer with the timer visible; undiscovered cubes show `???`; headers show `collected / total`; complete a page and confirm `1 / 1`, `Earned` and that `skinsOwned` (via `execute_luau`) holds the reward id exactly once even after eating that cube again in a later run; Book opens at any time in the Hub and from Results. First Results screen shows the tip and the "New in your book" list; a second run does not list the same objects as new and shows no tip. Capture BookUi at 640×360 on a complete and an incomplete page into `specs/003-saving-and-economy/captures/`. Console clean. Append findings to `specs/003-saving-and-economy/playtest.md`.

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Persistent Settings Screen Applied Live and Across Sessions (Priority: P2)

**Goal**: A Settings screen whose five controls apply on the client at once, are validated, clamped and saved by the server, and are restored on rejoin.

**Independent Test**: Change all five settings in Studio, see the effect at once, rejoin and see the saved values restored; fuzz `UpdateSettings` from MCP and see the server stay up with only legal changes applied (quickstart §5).

### Tests for User Story 3 (write first, ensure they FAIL before implementation)

- [X] T032 [P] [US3] Edit `tests/studio/DataService.spec.luau`: `updateSettings` saves a valid candidate into `profile.Data.settings` and `ProfileSync` carries the authoritative values; `{ musicVolume = 9, language = "xx", bogus = 1 }` makes `musicVolume` 1 with language and unknown key ignored; `"x"`, zero arguments, two arguments, a number and `nil` change nothing and do not throw; `NaN` and `math.huge` are ignored; more than `Config.settingsRateLimit` updates inside one `Config.rateLimitWindow` are ignored after the limit with no `warn`; `updateSettings` with no active profile returns false and mutates nothing; saved non-default settings are present in the first snapshot after a reload (acceptance US3-4).

### Implementation for User Story 3

- [X] T033 [US3] Edit `src/server/DataService.luau` (depends on T009, T032): add `updateSettings(userId, candidate): boolean` (false when no active profile or shutting down) which sets `profile.Data.settings = Settings.validate(profile.Data.settings, candidate, bounds)` with `bounds` built from `Config.Settings`, then sends `ProfileSync`. In `start()` connect `Remotes.UpdateSettings.OnServerEvent` with signature `(player: Player, ...: unknown)` following the validation order of `contracts/remotes.md`: exactly one argument, `Config.Flags.Saving` true and not shutting down, `RateLimit.allow` with `Config.settingsRateLimit` per `Config.rateLimitWindow` in a per-player window, active profile, `typeof(payload) == "table"`. Reject codes are internal counters only; never `warn`, never send them. Field-level problems never reject the request. Makes T032 pass.
- [X] T034 [P] [US3] Edit `src/client/Feedback.luau`: create `SoundGroup`s `Music` and `Effects` under `SoundService`, set every sound made by `play` to the `Effects` group, and expose `setVolumes(music, effects)` and `setReduceMotion(on)`. The `ReduceMotion` Player attribute becomes `setting or GuiService.ReducedMotionEnabled` (client only), which `Hud` and `CameraController` already read. No music asset exists yet; the group is ready for Feature 007.
- [X] T035 [US3] 🔒 Studio: camera sensitivity spike (plan finding F-7, research R7). In Studio try `UserInputService.MouseDeltaSensitivity = value`, then `UserGameSettings.MouseSensitivity`, and check whether the touch pan can be scaled. Edit `src/client/CameraController.luau` to expose `setSensitivity(value)` using the primary approach (`MouseDeltaSensitivity` for mouse). If the touch pan cannot be scaled, keep the setting saved, document the PC-only effect in `specs/003-saving-and-economy/contracts/ui.md` and do not build a custom camera. Fill the "Camera sensitivity" row of plan.md "Risk Results" with the measured result and decision.
- [X] T036 [P] [US3] Create `src/client/SettingsUi.luau` (depends on T017, T019, T020) per `contracts/ui.md` §SettingsUi: same footprint as `BookUi` (464×252 at x 8, y 100); header row 64 with `ui.settings.title` and Close `✕` 64×64; body in two columns of 224 with an 8 px gap. Left: three slider rows of 56 px, `ui.settings.music_volume` (0 to 100), `ui.settings.effects_volume` (0 to 100), `ui.settings.camera_sensitivity` (50 to 200), each with label (18 px) and value through `ui.settings.percent`. Right: `ui.settings.reduce_motion` as a 224×64 toggle `[check or off] ui.settings.on / ui.settings.off`, and `ui.settings.language` with three 72×64 buttons `ui.settings.language_auto`, `_en_us`, `_es_es` where the selected one shows the check glyph and a bold font. Bounds for the sliders come from `Config.Settings` (`musicVolume` 0 to 1, `effectsVolume` 0 to 1, `cameraSensitivity` 0.5 to 2.0). Initial values from `ProfileClient.settings()`; a change applies locally at once and goes through `ProfileClient.sendSettings` (debounced); `ProfileClient.changed` overwrites controls with the authoritative echo (a clamped value moves the control); `ProfileClient.flush()` on close. Slider value rounds to whole percent for display only; the sent number is the raw fraction. Exposes `toggle()` and `close()`; opening it closes `BookUi`; unlike the Book it is not locked at run start and stays open when a new run starts. One `refreshText()` on `Localizer.changed`. Behind `Config.Flags.Saving`.
- [X] T037 [P] [US3] Edit `src/client/Hud.luau`: add one `refreshText()` that re-applies its static labels and connect it to `Localizer.changed` (language switch, plan "Design Notes" 8). Dynamic labels already rebuild per update; do not change layout.
- [X] T038 [US3] Edit `src/client/ProfileClient.luau` (depends on T015, T034, T035): on every `changed`, apply the settings to `Feedback.setVolumes` and `Feedback.setReduceMotion`, `CameraController.setSensitivity`, and `Localizer.setLanguage`, through each module's own setter, so no other module subscribes to `ProfileSync`. Settings saved in a previous session are therefore applied as soon as the first snapshot arrives (acceptance US3-4).
- [X] T039 [US3] Edit `src/client/Main.client.luau` (depends on T036): start `SettingsUi` and call `TopBar.bind("settings", SettingsUi.toggle)` behind `Config.Flags.Saving`.
- [ ] T040 [US3] 🔒 Studio: playtest quickstart §5. Open Settings (five controls, text at least 18 px); drag Music and Effects to 0 then 100 % and hear/see the next pickup change; toggle Reduce motion on and trigger a knock-off (no camera shake, the "Bump!" label still shows); change Camera sensitivity to 200 % and record the result (the T035 risk row); choose Español and see Book, Settings, Hub rows and the Results coins line switch to Spanish while 002 strings stay English (Feature 007); choose Auto again. Leave and rejoin: all five values are restored and applied. Fuzz from MCP: fire `UpdateSettings` with `"x"`, `{ musicVolume = 9, language = "xx", bogus = 1 }`, no arguments and two arguments; the server stays up, `musicVolume` becomes 1, language is unchanged, console has no new errors. Capture SettingsUi at 640×360 into `specs/003-saving-and-economy/captures/`. Append findings to `specs/003-saving-and-economy/playtest.md`.

**Checkpoint**: User Stories 1 to 3 all work independently.

---

## Phase 6: User Story 4 - Persistent Economy HUD, Hub Best Size, and Results Best-Size Integration (Priority: P2)

**Goal**: The persistent coin total and per-world best size show on Hub and Results, and the TopBar (built in Phase 2) gives clear icon-plus-label access to Book, Shop and Settings.

**Independent Test**: Two runs of 18.5 studs and 12 coins, then 14.0 studs and 8 coins, leave Hub and Results showing 20 coins and best size 18.5 (acceptance US4-1); the Shop button shows the "After this run" notice during a run (US4-2).

### Tests for User Story 4 (write first, ensure they FAIL before implementation)

- [X] T041 [P] [US4] Edit `tests/studio/DataService.spec.luau`: add the acceptance case "run 1 `finalDiameter = 18.5`, `coins = 12`, then run 2 `finalDiameter = 14.0`, `coins = 8` in the same world" and assert the snapshot has `coins == 20` and `bestSize[worldId] == 18.5`, and that the second outcome has `isFirstRun == false` and `bestSize == 18.5`.

### Implementation for User Story 4

- [X] T042 [P] [US4] Edit `src/client/HubUi.luau`: grow the card from 300×180 to 300×236 and add two 24 px rows above the Play button, `[coin glyph] ui.hub.coins` from `ProfileClient.coins()` and `[star glyph] ui.hub.best_size` from `ProfileClient.bestSize(Worlds.active.worldId)` with one decimal (`0.0` when none) (`contracts/ui.md` §Hub screen additions). Rows refresh on `ProfileClient.changed`. The card stays bottom-centre (x about 170 to 470), clear of both corners, Play stays 96 px. Add one `refreshText()` on `Localizer.changed`.
- [X] T043 [P] [US4] Edit `src/client/ResultsUi.luau` (after T029): show one coins line, `ui.results.coins_total` (`Coins: 12 (total 20)`) when `coinsTotal` exists, else the 002 `ui.results.coins`; the friend/self-best row uses `bestSelfSize`, which is now the persistent best; when `isFirstRun` is true keep T029's rule that the tip replaces the best-size row. The Results screen reads only the `RunResult` fields (`coins`, `coinsTotal`, `bestSelfSize`, `newBookIds`, `isFirstRun`), never the snapshot, so event order cannot matter (plan "Design Notes" 2).
- [ ] T044 [US4] 🔒 Studio: playtest quickstart §3 steps 2 to 6 and the TopBar. Finish two runs (the second smaller): Results after the second run and the Hub both show the summed coins and the larger best size; rejoin in the same server and the first run after rejoining shows no first-run tip. In `Active`, `Ended` and `Hub` the TopBar shows Book, Shop and Settings each with icon and 18 px label; tapping Shop during a run shows `ui.hud.shop_after_run` for 2 s and opens nothing, tapping it in the Hub shows `ui.hud.shop_soon`. Capture Hub and Results (first run and later run) at 640×360 into `specs/003-saving-and-economy/captures/`. Console clean. Append findings to `specs/003-saving-and-economy/playtest.md`.

**Checkpoint**: All four user stories are independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Gate 2 captures at all three resolutions, authority and privacy audit, PR description, human checks.

- [ ] T045 [P] 🔒 Studio: capture the full checklist of `contracts/ui.md` §Capture checklist at 640×360, 844×390 and 1280×720 with the Studio MCP `screen_capture`, stored under `specs/003-saving-and-economy/captures/`: HUD with TopBar in `Active` (timer visible, bar clear), TopBar in `Hub`, BookUi on a complete and an incomplete page, BookUi with the Book button locked at t = 2 s, SettingsUi, Hub with coins and best size, Results on the first run (tip) and a later run, and the same Book page after switching to `es-es`. Pass criteria for each: no overlap, no clipping, the top-centre timer block (x 165 to 475 at 640 wide) visible, all text at least 18 px (SC-004). Also check that the glyphs `⚙ 🛒 🔒 ❓ ◀ ▶ ✕ ✔` render in `FredokaOne` and `GothamMedium` and swap any that do not for an emoji in `src/shared/Content/Icons.luau`. If offsets must move, adjust the numbers in the UI files and in `specs/003-saving-and-economy/contracts/ui.md` but keep the rules (64 px utility minimum, timer visible, bottom 130 px corners free). Fill the remaining plan.md "Risk Results" rows (glyphs, 640×360 fit, optional cold-load time).
- [X] T046 [P] Authority and privacy audit (Constitution II, V, VIII): grep `src/client` and `src/server` and confirm the only client-to-server remotes added are `RequestProfile` (no arguments) and `UpdateSettings` (preferences only); no client code path sends coins, sizes, book entries, rewards or results; the only writers of `coins`, `bestSize`, `book` and `skinsOwned` are in `Profile.applyRunResult` called from `DataService.applyRunResult`; `receipts` and `worldsUnlocked` are untouched apart from defaults; no username or display name is stored; log lines print only the numeric `UserId`; no price, offer or purchase prompt exists anywhere in the new UI. Run `scripts/check.sh` and `scripts/test-guard.sh` and confirm the Rules purity guard passes on the three new Rules files. Record the result in `specs/003-saving-and-economy/playtest.md` under "Audit".
- [X] T047 [P] Create `specs/003-saving-and-economy/pr-description.md` stating which Quality Gates applied and how each was met (plan "Quality Gates mapping": gate 1 `scripts/check.sh`; gate 2 Studio playtest with console read plus the captures; gate 3 N/A, no assets; gate 4 every new string in `Strings.luau`; gate 5 `tasks.md` ticks), the owner-approved DataStore name, key and v1 keys (spec, 2026-10-25), and the two open owner items.
- [ ] T048 👤 Human checks (private test place, not Studio; an agent only prepares them): (a) persistence across real servers: play a run, leave, join a fresh server, confirm coins, best size and book (SC-001); (b) session lock: join the same account from two servers and confirm the first is kicked with `error.session_ended` and neither profile is corrupted (SC-002); (c) **Open Item 1**: the owner confirms the private test place is a separate experience from the live one (if not, a `Config.dataStoreName` override for test builds is a key-name change and needs owner approval first); (d) **Open Item 2**: the owner confirms the 64 px utility-button minimum on a real phone, sliders usable by touch, and the camera sensitivity effect on touch; (e) grey-box check of the Book screen and Hub additions with at least 3 adults and 3 children aged 10 to 12. Record date, commit, participant counts per age group, findings and owner sign-off in `specs/003-saving-and-economy/playtest.md` (Constitution I).
- [ ] T049 Final validation: run `scripts/check.sh` (exit 0), run the Jest runner through the Studio MCP (`DataService.spec` and `RunManager.spec` 0 failures, mock store only), walk quickstart sections 1 to 6 once more on a clean Studio session with a clean console, confirm the captures from T045 are stored, tick every completed task in this file, and note any deviation from plan.md or the contracts in the PR description (T047).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 first (blocks everything: the 002 code must be on the branch), then T002.
- **Foundational (Phase 2)**: depends on Phase 1; blocks all user stories.
- **US1 (Phase 3)**, **US2 (Phase 4)**, **US3 (Phase 5)**, **US4 (Phase 6)**: all depend on Phase 2 only. Priority order is P1 (US1, US2) then P2 (US3, US4).
- **Polish (Phase 7)**: depends on the stories being complete (T045 needs all UI).

### Within Phase 2

- T003 to T006 (tests) before T007 to T010 (Rules); T003 to T007, T004 to T008, T005 to T009, T006 to T010.
- T011, T012, T013, T014 are independent; T015 depends on T014; T016, T017, T018 are independent.
- T019 depends on T011 and T016; T020 depends on T010, T011, T013, T014, T017; T021 depends on T019 and T020.

### User Story Dependencies

- **US1**: no dependency on other stories. T022 and T023 before T024 and T026; T024 before T025; T027 last.
- **US2**: needs only Phase 2 for its code. Its Studio playtest (T031) is richer with US1 in place (persistent book, tip on first run), so run it after US1.
- **US3**: T033 builds on T024 (same file, `DataService.luau`); T038 depends on T034 and T035; T040 needs T036 and T039.
- **US4**: T043 builds on T029 (same file, `ResultsUi.luau`); T041 builds on T022 (same spec file). Needs US1 for persistent values.

### Within Each User Story

- Tests before the code they cover, and they must fail first.
- Edits to a shared file (`DataService.luau`, `DataService.spec.luau`, `ResultsUi.luau`, `ProfileClient.luau`, `Main.client.luau`) happen one at a time in the order of the task IDs; never mark them `[P]` against each other.

### Parallel Opportunities

- Phase 2: T003, T004, T005, T006 together; then T007, T008, T009, T010 together; T011, T012, T013, T014 together with T016, T017, T018.
- US1: T022 and T023 together.
- US2: T028 and T029 together.
- US3: T034, T036 and T037 together (T032 can run alongside them; T035 holds the Studio claim).
- US4: T041, T042 and T043 together.
- Polish: T045, T046, T047 together (T045 holds the Studio claim).
- Only one `🔒 Studio` task runs at a time across the whole feature.

---

## Parallel Example: Phase 2 Rules

```bash
# Launch all Rules tests together:
Task: "Create tests/unit/Profile.test.luau (T003)"
Task: "Create tests/unit/Book.test.luau (T004)"
Task: "Create tests/unit/Settings.test.luau (T005)"
Task: "Edit tests/unit/RunClock.test.luau (T006)"

# Then all Rules modules together:
Task: "Create src/shared/Rules/Profile.luau (T007)"
Task: "Create src/shared/Rules/Book.luau (T008)"
Task: "Create src/shared/Rules/Settings.luau (T009)"
Task: "Edit src/shared/Rules/RunClock.luau (T010)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (002 on the branch) and Phase 2 (Foundational).
2. Complete Phase 3 (US1): the profile loads, runs apply once, load failure kicks.
3. **STOP and VALIDATE**: Jest suites green on the mock store, Studio check T027.
4. Merge or demo if ready: progress already persists, even before any new screen exists.

### Incremental Delivery

1. Setup + Foundational, then US1 (MVP: nothing is lost).
2. Add US2 (Book and first-run tip), validate, demo.
3. Add US3 (Settings), validate, demo.
4. Add US4 (Hub and Results economy rows), validate, demo.
5. Polish: captures at three resolutions, audit, PR description, human checks.

### Parallel Team Strategy

With several agents (each in its own worktree, Constitution X):

1. One agent does Phase 1; then agents split Phase 2 along the `[P]` groups (Rules and tests; Config, Content and Strings; Remotes, `UiKit`, `RunClient`).
2. After the checkpoint: agent A takes US1 (server), agent B takes US2 client UI, agent C takes US3 client UI plus `Feedback` and `Hud`. Agent D waits for US1, then US4. The single Studio MCP claim is passed between agents task by task.

---

## Notes

- `[P]` tasks touch disjoint files; a task that edits a file another task in the phase also edits is never `[P]` against it.
- `[Story]` labels map each task to its user story for traceability; Setup, Foundational and Polish tasks have none.
- Verify tests fail before implementing; commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Never read or write the live DataStore from tests or Studio (`ProfileStore.Mock` only, user ids from 900001).
- The words `game`, `task`, `Enum`, `Instance`, `workspace`, `tick` must not appear in `src/shared/Rules` files, comments included.

---

## Phase 8: Convergence

- [X] T050 Make `scripts/check.sh` exit 0 again: Selene fails on two unused-variable warnings, `afterEach` imported but unused at `tests/studio/DataService.spec.luau:14` and `local run = RunManager.startRun(...)` unused at `tests/studio/RunManager.spec.luau:448`. Remove the unused import and call `RunManager.startRun(uid, nil, now)` without assigning its result, then re-run `scripts/check.sh` to a clean exit per tasks.md Conventions "Each task ends with `scripts/check.sh` exiting 0" and Quality Gate 1 (partial)
