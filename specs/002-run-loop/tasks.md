---

description: "Task list for the Run Loop (002-run-loop)"
---

# Tasks: Run Loop

**Input**: Design documents from `/specs/002-run-loop/`

**Prerequisites**: plan.md, spec.md, research.md (R1 to R14), data-model.md, contracts/ (`rules-api.md`, `remotes.md`, `replicated-state.md`, `content-and-config.md`, `ui.md`), quickstart.md, `.specify/memory/constitution.md` (v1.0.0). Feature 001 is merged: `src/server/{Remotes,WorldSpawner,BallService,AbsorbService,Main.server}.luau`, `src/client/*` and `tests/` exist and must keep passing.

**Tests**: Requested by the spec (FR-023, FR-024). Lune unit tests for every new `src/shared/Rules` module, `Config`, `GreyBoxRoom`, `Strings` and a string-literal guard; Jest-Lua Studio tests for server run authority (`tests/studio/RunManager.spec.luau`). Expected numbers are copied by hand from `contracts/rules-api.md` and `research.md` R1; never compute them by calling the code under test.

**Organization**: Tasks are grouped by user story. The pure rules, content, strings, remotes and `Worlds` seam (all code that US1 and US2 read) sit in Phase 2 because every story needs them. Story 3 (P2) holds the tests, guards and seam checks that prove the "pure, data-driven, localised" promises, and can start as soon as Phase 2 files exist.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with the other `[P]` tasks of the same phase (different files, no dependency on an unfinished task)
- **[Story]**: US1 to US3, matching the user stories in spec.md
- Every task names the exact file or files it touches

## Conventions

- Every `.luau` file starts with `--!strict`. `src/shared/Rules` files are pure: no `require` of each other, and none of the words the `scripts/check.sh` purity guard rejects (`Instance`, `workspace`, `game`, `task`, `DateTime`, `Vector3`, `CFrame`, `GetService`, `Enum`, `tick`, `math.random`, `os.clock`, `os.time`, `require(script`) **even in comments**. Time enters as an argument.
- Every number comes from `src/shared/Config.luau` or world data in `GreyBoxRoom.luau`; no magic numbers in server or client scripts.
- Every player-facing string is `Localizer.t("key", args)`; icons are `Icons[id]`. Never type an English word into a `Text` property (a Lune test fails on it). Symbol-only text such as `★` is allowed through `Icons`.
- Nothing a client sends may set a size, coin, star, tier or result (Constitution II). The only client intents are `RollAgain` and `BackToHub`, with zero arguments.
- New behaviour sits behind `Config.Flags.RunLoop`. With the flag off or no `RunState` attribute, the game behaves as in 001 (R13).
- Server modules take the clock as an argument (`now`); only `Main.server.luau` calls `os.clock()`. Tests inject `now`. Mirror 001: `BallService.newSession(userId, nil)` lets Jest tests run without a real `Player`, so `RunManager` functions take `userId` plus an optional `Player`.
- **Studio MCP claim** (Constitution X): tasks marked `🔒 Studio` drive Roblox Studio through the Studio MCP server. Only one agent may do this at a time. Before starting, append ` CLAIMED:<agent>` to the task line; remove it when done.
- **Human task**: tasks marked `👤` need people (playtesters, the owner). An agent only prepares them. An agent's statement never counts as owner approval.
- Each task ends with `scripts/check.sh` exiting 0. Quality Gate 2 (Studio playtest with console read) applies to every task that touches `src/server` or `src/client`; the dedicated Studio tasks cover it for the feature.

## Path Conventions

Rojo tree as in plan.md "Project Structure": `src/shared` (ReplicatedStorage.Shared), `src/server` (ServerScriptService), `src/client` (StarterPlayer.StarterPlayerScripts), `tests/unit` (Lune, auto-discovered `*.test.luau`), `tests/studio` (Jest-Lua, `ServerStorage.Tests`, auto-discovered `*.spec.luau`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Constants and placeholder asset tables that everything else reads. No new tool or package (Constitution XII).

- [X] T001 [P] Edit `src/shared/Config.luau`: add the run-loop keys from data-model §1, exactly `runDurationSeconds = 240`, `rollAgainDelaySeconds = 3`, `starThresholds = { 20, 45, 80 }`, `friendBonusRate = 0.20`, `friendBoostRate = 0.25`, `pickupPopDuration = 1.0`, `tierBannerDuration = 2.5`, `knockOffShakeDuration = 0.35`, `knockOffShakeMagnitude = 0.6`, `pickupPitchStep = 0.08`, `minTextSize = 18`, `minTouchTarget = 96`, `uiReferenceShortSide = 720`, and `Flags.RunLoop = true` next to the existing flags. Keep the existing keys and layout style.
- [X] T002 [P] Create `src/shared/Assets.luau` (contracts/content-and-config.md "Assets"): `Assets.sounds = { pickup = "rbxasset://sounds/electronicpingshort.wav", tierUnlock = "rbxasset://sounds/button.wav", bump = "rbxasset://sounds/snap.mp3", bell = "rbxasset://sounds/bass.wav" }`. This is the only file that may hold a `SoundId` (Constitution XI). Paths are confirmed or replaced in T040.
- [X] T003 [P] Create `src/shared/Content/Icons.luau` (contracts/content-and-config.md "Icons"): table `{ [iconId]: glyph }` with `star = "★"`, `star_empty = "☆"`, `clock = "⏱"`, `coin = "●"`, `cube = "■"`, `arrow = "▲"`, `book = "▤"`, `retry = "↻"`, `home = "⌂"`, `play = "▶"`. Data only. A glyph that does not render is swapped here in T040.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure rules, world data, strings, the localiser, the `Worlds` seam, remotes and the friend cache. US1 and US2 cannot start until these exist.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Create `src/shared/Rules/Stars.luau` per contracts/rules-api.md: `stars(diameter: number, thresholds: { number }): number` returns the count of thresholds `t` with `diameter >= t` (inclusive lower bound, thresholds ascending), so `0` to `#thresholds`. Pure, standalone.
- [X] T005 [P] Create `src/shared/Rules/Tiers.luau` per contracts/rules-api.md: `export type TierLike = { minDiameter: number }`; `lookup(diameter, tiers): (number, number?)` returns the index of the last tier with `minDiameter <= diameter` (or `1` if below the first) and `tiers[index + 1].minDiameter`, or `nil` on the top tier; `progress(diameter, tiers): number` returns `1` on the top tier, else `(diameter - min[i]) / (min[i+1] - min[i])` clamped to `0..1`. Pure, standalone.
- [X] T006 [P] Create `src/shared/Rules/Coins.luau` per FR-003 and contracts/rules-api.md: `export type Options = { friendBonusRate: number, hasFriendInServer: boolean, hasDoubleCoins: boolean, friendBoostRate: number, friendBoostCount: number }`; `total(absorbedCoinValues: { number }, options: Options): number` computes `base = sum(values)`, `a = base * (hasFriendInServer ? 1 + friendBonusRate : 1)`, `b = a * (1 + friendBoostRate * friendBoostCount)`, `c = b * (hasDoubleCoins ? 2 : 1)`, returns `math.floor(c + 0.5)` (half-up; `0` base always gives `0`). Pure, standalone.
- [X] T007 [P] Create `src/shared/Rules/RunClock.luau` per contracts/rules-api.md: `remaining(now, endsAt)` = `math.max(0, endsAt - now)`; `expired(now, endsAt)` = `now >= endsAt`; `format(seconds)` = `mm:ss` of `math.ceil(math.max(0, seconds))` (so `239.2` prints `04:00` and `0.4` prints `00:01`; minutes may exceed two digits only if the input does, never negative). Pure, standalone.
- [X] T008 [P] Create `src/shared/Localization/Strings.luau`: plain data table `{ [key: string]: { en: string } }` with every key and English text from contracts/content-and-config.md "String keys" (`ui.hud.*`, `ui.pickup.pop`, `ui.banner.tier_unlock`, `ui.bump.label`, `ui.results.*`, `ui.hub.*`, `tier.greybox.1..4.name` = `Tiny`/`Small`/`Medium`/`Large`, `tier.greybox.1..4.headline` = `TINY CUBES`/`SMALL CUBES`/`MEDIUM CUBES`/`LARGE CUBES`, `object.greybox.cube_t1..4` = `Tiny cube`/`Small cube`/`Medium cube`/`Large cube`). Placeholders use `{name}`. No Roblox APIs, so Lune can load it. Spanish is Feature 007.
- [X] T009 Edit `src/shared/Content/GreyBoxRoom.luau` (FR-005, FR-006, R1, R12; depends on T003, T008): extend `Room` with `worldId: string` (`"greybox"`), `starThresholds: { number }?` (`{ 3.0, 4.0, 5.0 }`), `sizeTiers: { SizeTierDef }`, `objects: { ObjectDef }`, `hub: HubDef`, and export the three new types. `SizeTierDef = { tier: number, nameKey: string, minDiameter: number, maxDiameter: number?, headlineKey: string, headlineIcon: string }` with `tier` 1..4, `minDiameter` 2.0 / 2.375 / 3.0 / 3.75 ("strictly ascending by tier; tier 1 == Config.startDiameter"), `maxDiameter` equal to the next tier's `minDiameter` and `nil` on tier 4, keys `tier.greybox.<n>.name` / `.headline`, `headlineIcon = "cube"`. `ObjectDef = { id: string, tier: number, size: number, coins: number, bookId: string, nameKey: string, icon: string }` with ids `cube_t1..cube_t4`, sizes 0.75 / 0.95 / 1.2 / 1.5 ("equals the layout tier's size"), coins 1 / 2 / 3 / 5 ("positive integer"), bookIds `greybox.cube_t1..4`, nameKeys `object.greybox.cube_t1..4`, `icon = "cube"`. `HubDef = { center: { x: number, z: number }, halfExtent: number, spawn: { x: number, z: number }, padRadius: number }` with `center = { x = 160, z = 0 }`, `halfExtent = 16`, `spawn = { x = 0, z = 0 }` (offset from centre), `padRadius = 4`. Leave `halfExtent`, `wallHeight`, `kerb`, `spawnRingRadius`, `spawnSlots`, `tiers` and `cubes` unchanged.
- [X] T010 Create `src/shared/Worlds.luau` (R12, contracts/content-and-config.md "Worlds"; depends on T001, T009): `Worlds.active = require(Content.GreyBoxRoom)` (the one line Feature 004 changes), `Worlds.sizeTiers`, `Worlds.starThresholds` (the world's own, else `Config.starThresholds`), `Worlds.objectByTier`, `Worlds.objectById`, `Worlds.objectByBookId`, all built once at require time with no other behaviour. If luau-lsp strict rejects passing `{ SizeTierDef }` where `{ Tiers.TierLike }` is expected (array invariance), build the `{ TierLike }` list once here and export it as `Worlds.tierLikes`.
- [X] T011 [P] Create `src/shared/Localization/Localizer.luau` (R8; depends on T008): build one `LocalizationTable` from `Strings` (`SetEntries`, source locale `en-us`), expose `Localizer.t(key: string, args: { [string]: string | number }?): string` that calls the translator's `FormatByKey` for `LocalizationService.RobloxLocaleId` and falls back to `en-us`, and returns the key itself if the key is unknown (never errors). Placeholders use the `{name}` form.
- [X] T012 [P] Edit `src/server/Remotes.luau` per contracts/remotes.md: add `RollAgain`, `BackToHub` (client to server) and `PickupConfirmed`, `TierUnlocked`, `KnockedOff`, `RunResult` (server to client) as `RemoteEvent`s in `ReplicatedStorage.Remotes`, created with the existing `getOrCreateEvent`. Update the header comment to "seven" events.
- [X] T013 [P] Create `src/server/FriendCache.luau` (R7): `friends[userId][otherUserId] = boolean`; `FriendCache.start()` connects `PlayerAdded` (fill the new player's row for everyone present and everyone else's entry for the new player, each lookup in `task.spawn` around `pcall(player.IsFriendsWith, player, otherId)`; failure stores `false`) and `PlayerRemoving` (delete the leaver's row and column); `FriendCache.hasFriendIn(userId, presentUserIds): boolean` and `FriendCache.areFriends(a, b): boolean` read the cache synchronously and default to `false`.

**Checkpoint**: `scripts/check.sh` passes (StyLua, Selene, luau-lsp strict, existing Lune tests, purity guard). Foundation ready; user stories can begin.

---

## Phase 3: User Story 1 - Personal 4-Minute Timed Run, End-of-Run Results, One-Tap Roll Again (Priority: P1) 🎯 MVP

**Goal**: Every player starts a run on join, the server ends it at the bell and publishes one result, the player sees a results screen and can **Roll again** or go **Back to hub**.

**Independent Test**: Jest-Lua `RunManager.spec` passes (end at 240 s of injected time with no client input, one result per `runId`, absorb rejected from `endsAt`, spoofed intents ignored, fall keeps state, Roll again gives a new `runId` within `rollAgainDelaySeconds`, leaving mid-run publishes nothing); in Studio, three runs in a row with **Roll again** each show their own results, **Back to hub** reaches the plaza (quickstart scenarios 1, 6 to 12).

### Tests for User Story 1 (write FIRST, they fail until T018 to T020)

- [X] T014 [US1] Create `tests/studio/RunManager.spec.luau` (FR-024, R14) in the style of `tests/studio/AbsorbService.spec.luau`: sessions from `BallService.newSession(userId, nil)`, injected `now`, results captured through `RunManager.setPublisher(fn)`. Cases: a run starts with a unique `runId` and `endsAt = now + Config.runDurationSeconds`; `acceptsPickups` is true at `endsAt - 0.001` and false at `endsAt`; `RunManager.step(startedAt + 240)` publishes exactly one result and `step(startedAt + 340)` publishes none; the result has `finalDiameter`, `stars` (from `Worlds.starThresholds`), `coins`, `newBookIds`, `bestSelfSize`, `bestFriendSize == nil` with no friends; absorb after the bell changes nothing; `RollAgain`/`BackToHub` handlers called with an extra argument, with a wrong argument, in `Active`, or twice in a row change nothing; fall below `Config.fallRespawnY` mid-run keeps `authoritativeDiameter`, stuck stack and `runId`; `RollAgain` after the bell gives a new `runId`, diameter `Config.startDiameter`, empty stack and a restart within `Config.rollAgainDelaySeconds` of injected time; `BackToHub` puts the session in zone `Hub` and state `Hub`, and absorb is rejected there; `RollAgain` from `Hub` starts a run; removing the player mid-run publishes nothing; three consecutive runs have distinct `runId`s.

### Implementation for User Story 1: server

- [X] T015 [P] [US1] Edit `src/server/WorldSpawner.luau` (R6): `start` also builds `Workspace.Hub` (Folder with `Floor`, an anchored grey Part `2 * hub.halfExtent` square centred at `hub.center`, and `StartPad`, an anchored flat disc of radius `hub.padRadius` with no text and no touch detection); add `WorldSpawner.getHubSpawn(): Vector3` (hub centre plus `hub.spawn`, raised so a 2-stud ball rests on the floor). Read hub data through `Worlds.active.hub`. No change to the cube registry.
- [X] T016 [P] [US1] Edit `src/server/BallService.luau` (R3, R4; contracts/replicated-state.md "Ball behaviour by state"): add `zone: "Room" | "Hub"` (default `"Room"`) and `frozen: boolean` (default `false`) to `Session`; `placeAtSpawn` uses the hub spawn when `zone == "Hub"`; add `BallService.setFrozen(session, frozen)` (frozen: zero both velocities and set `part.Anchored = true`; released: `Anchored = false`, `SetNetworkOwner(player)` again, reset `lastValidPosition`); the speed and displacement check in `step` skips frozen balls; add `BallService.returnToSpawn(session)` (position and velocity only; size, stuck stack untouched) and `BallService.resetBall(session)` (release cubes still pending from the stack via `releasableCubes`, clear the stack, `authoritativeDiameter` and `physicalDiameter` back to `Config.startDiameter`, place at the zone spawn, `publishStuck`); the fall check in `step` now calls `returnToSpawn` instead of `respawn`. `BallService` must not require `RunManager`. Keep `BallService.respawn` as the 001 full reset.
- [X] T017 [US1] Create `src/server/RunManager.luau` (FR-009 to FR-016, data-model §4 and §5, R2, R5, R7; depends on T006, T007, T010, T012, T013, T015, T016). Module state per data-model §4 (`runs`, `bestSelfSize`, `seenBookIds`, `runSeq`). API: `RunManager.start()` (flag check, `PlayerAdded` after `BallService` has made the session, players already present, `PlayerRemoving` deletes the run without a result, `game:BindToClose` sets a shutting-down flag), `startRun(userId, player, now)` (new `runId` `"<userId>-<runSeq>"`, `startedAt = now`, `endsAt = now + Config.runDurationSeconds`, `state = "Active"`, `resultPublished = false`, empty `absorbedCoinValues`/`absorbedBookIds`, `unlockedTiers = { [1] = true }`, zone `Room`, ball reset, and write player attributes `RunId`, `RunEndsAt = Workspace:GetServerTimeNow() + (endsAt - now)`, then `RunState` last), `acceptsPickups(userId, now): boolean` (true when `Active` and `now < endsAt`, or when the player has no run), `resetAction(userId): "Return" | "Full" | "Reject"` (Active: `Return`; Hub or no run: `Full`; Ended: `Reject`), `onPickup(userId, object, now)` (append `object.coins` to `absorbedCoinValues`, add `bookId` if new to the run; no events yet, US2 adds them), `step(now)` (for each `Active` run with `RunClock.expired(now, endsAt)`: set `Ended`, `BallService.setFrozen(session, true)`, build the `RunResult` once per `runId` guarded by `resultPublished`, with `finalDiameter = session.authoritativeDiameter`, `stars = Stars.stars(finalDiameter, Worlds.starThresholds)`, `coins = Coins.total(...)` with `hasFriendInServer` from `FriendCache`, `friendBonusRate = Config.friendBonusRate`, `hasDoubleCoins = false`, `friendBoostRate = Config.friendBoostRate`, `friendBoostCount = 0`, `newBookIds` = run book ids minus `seenBookIds[userId]` in first-pickup order, `bestSelfSize = max(previous, finalDiameter)`, `bestFriendSize` = max `bestSelfSize` among present friends or `nil`; then update `seenBookIds` and `bestSelfSize` in that order, then publish; after publication nothing more is emitted), `setPublisher(fn)` (default fires `Remotes.RunResult:FireClient`), intents `handleRollAgain(userId, now, ...: unknown)` and `handleBackToHub(userId, now, ...: unknown)` checking in order: no arguments, a run record exists, state allowed (`RollAgain`: `Ended` or `Hub`; `BackToHub`: `Ended`), not shutting down; failures change nothing and do not `warn`; `RollAgain` does `resetBall`, zone `Room`, `startRun`; `BackToHub` does `resetBall`, zone `Hub`, `setFrozen(false)`, state `Hub`, `RunEndsAt = 0`, `RunId = ""`; and `getRun(userId)` for tests. `Remotes.RollAgain.OnServerEvent` / `BackToHub.OnServerEvent` call the handlers with `os.clock()`.
- [X] T018 [US1] Edit `src/server/AbsorbService.luau` (FR-010, FR-011; depends on T016, T017): in `tryAbsorb` and `tryBump`, call `RunManager.acceptsPickups(session.userId, now)` first and return `"RunEnded"` (silent, no `warn`) when false; after a validated absorb call `RunManager.onPickup(session.userId, object, now)` with the `ObjectDef` found through `Worlds.objectByTier[cube.tier]`; `tryRespawn` follows `RunManager.resetAction(session.userId)`: `Return` calls `BallService.returnToSpawn` (cooldown as 001), `Full` calls `BallService.respawn`, `Reject` returns `"RunEnded"` without changing anything.
- [X] T019 [US1] Edit `src/server/Main.server.luau` (depends on T017, T018): require `FriendCache` and `RunManager`; start in order `WorldSpawner.start()`, `FriendCache.start()`, `BallService.start()`, `AbsorbService.start()`, `RunManager.start()`; in the Heartbeat call `RunManager.step(now)` after `BallService.step(now, dt)`.

### Implementation for User Story 1: client

- [X] T020 [P] [US1] Create `src/client/RunClient.luau` (R5, data-model §6): the single reader of run state. Reads `RunState`, `RunId`, `RunEndsAt` from `Players.LocalPlayer` attributes and the `RunResult` event; exposes `RunClient.state()`, `RunClient.endsAt()`, `RunClient.remaining(): number` (via `RunClock.remaining(Workspace:GetServerTimeNow(), endsAt)`), and signals `stateChanged(state)`, `pickup(objectId)`, `tierUnlocked(tier)`, `knockedOff()`, `result(result)` (all four events re-signalled; `PickupConfirmed`/`TierUnlocked`/`KnockedOff` only forwarded here, used by US2). Check `typeof` of every `RunResult` field and ignore a malformed payload (never throw). No run UI when `RunState` is absent.
- [X] T021 [P] [US1] Create `src/client/UiKit.luau` (R10, contracts/ui.md rules): `UiKit.screen(name)` returns a `ScreenGui` (`ResetOnSpawn = false`, `IgnoreGuiInset = true`) with a `UIScale` of `math.max(1, math.min(viewport.X, viewport.Y) / Config.uiReferenceShortSide)` updated on `ViewportSize` change; `UiKit.label(...)` and `UiKit.button(...)` create `TextLabel`/`TextButton` with a dark `UIStroke` (thickness 2), `FredokaOne` for headings or `GothamMedium` for body, `TextSize` clamped to at least `Config.minTextSize` (18), and buttons at least `Config.minTouchTarget` (96) in width and height. Text is passed in already localised.
- [X] T022 [US1] Create `src/client/Hud.luau` (FR-017 US1 part; depends on T020, T021): visible only in state `Active`. Top centre row 1: timer `[clock glyph] Localizer.t("ui.hud.time_label")` plus `RunClock.format(RunClient.remaining())` in 28 px `FredokaOne`, text updated at most once per whole second. Row 2: three star markers (each 100×36) `[star glyph] ui.hud.star_target` with `stars` and one-decimal `size` from `Worlds.starThresholds`, filled `★` once the ball's `Diameter` attribute reaches the threshold, else `☆` (state carried by the glyph, not colour). Layout, sizes and positions exactly as in contracts/ui.md; keep the bottom 130 px of both corners free. The size meter, pop and banner are added in T033.
- [X] T023 [P] [US1] Create `src/client/ResultsUi.luau` (FR-020; depends on T020, T021): on `RunClient.result`, show the full-screen dim layer (black, 0.35 transparency) and a centred 600×320 panel per contracts/ui.md: title `ui.results.title`; left column `ui.results.final_size` (one decimal), three star glyphs 36 px (`★` earned, `☆` not) with `ui.results.stars`, `[coin glyph] ui.results.coins`; right column `[book glyph] ui.results.new_entries` or `ui.results.no_new_entries`, up to 4 lines `[icon] object name` for `newBookIds` through `Worlds.objectByBookId`, then `ui.results.friend_best` if `bestFriendSize` exists, else `ui.results.self_best`; two buttons 250×96, 20 px apart: **Roll again** (`[retry glyph] ui.results.roll_again`) firing `Remotes.RollAgain` and **Back to hub** (`[home glyph] ui.results.back_to_hub`) firing `Remotes.BackToHub`, both with zero arguments. The panel hides on the `RunState` change away from `Ended`, not on click. No timers, prices, offers or anything for sale (Constitution V).
- [X] T024 [P] [US1] Create `src/client/HubUi.luau` (FR-015; depends on T020, T021): in state `Hub` show the bottom-centre card `ui.hub.title` (28 px) above one 260×96 **Play** button (`[play glyph] ui.hub.play`) that fires `Remotes.RollAgain` with zero arguments; hidden in every other state.
- [X] T025 [P] [US1] Edit `src/client/BallController.luau` (R3): ignore move and jump input unless `RunClient`/the `RunState` attribute is `Active` or `Hub`, or the attribute is absent (001 behaviour); keep the Reset button callback firing `RespawnBall` (the server decides what it does).
- [X] T026 [US1] Edit `src/client/Main.client.luau` (depends on T020 to T025): start `RunClient`, `Hud`, `ResultsUi`, `HubUi` after the existing modules.

### Studio verification for User Story 1

- [ ] T027 [US1] 🔒 Studio: Serve with `rojo serve default.project.json`, press Play, and run `return require(game.ServerStorage.Tests.runner)()` through MCP `execute_luau`. Confirm `RunManager.spec` and all 001 suites pass. In the same session confirm the R3 behaviour: after the bell the ball is anchored, and after **Roll again** and **Back to hub** it is unanchored and still controlled by the player's input (network owner re-assigned). If re-owning misbehaves, apply the R3 fallback (keep the ball unanchored and zero its velocity every Heartbeat while `Ended`), changing only `BallService.setFrozen`. Fix defects in the owning file before ticking (depends on T014, T019, T026).
- [ ] T028 [US1] 🔒 Studio: Run quickstart scenarios 1, 6, 7, 8, 9, 10, 11 and 12 solo, fast-forwarding with `RunManager.step(os.clock() + 240)` (quickstart §3). Expected: `04:00` timer and three star targets with no menu; fall keeps size, stack and timer; results screen once with two 96 px buttons; **Roll again** gives a new run within 3 s, size `2.0`, new `RunId`; three consecutive runs have distinct ids; **Back to hub** shows the plaza and **Play**, absorbing is rejected there; leaving mid-run publishes nothing. Read the console with `get_console_output`: zero new errors or warnings (depends on T027).
- [ ] T029 [US1] 🔒 Studio: Capture the results screen and the hub screen at 640×360, 844×390 and 1280×720 with `screen_capture`; verify no clipping or overlap, text at least 18 px and both results buttons at least 96 px (measure `AbsoluteSize` times `UIScale.Scale` through `execute_luau`). Record the sizes for the PR description (SC-002, Quality Gate 2) (depends on T028).

**Checkpoint**: User Story 1 is fully functional and testable on its own. MVP: stop here and validate.

---

## Phase 4: User Story 2 - Size Tiers, Live HUD Meter and Sensory Feedback (Priority: P1)

**Goal**: The HUD shows the live size meter and next tier, every pickup pops with sound and haptic, tier unlock banners fire once per tier per run, and a knock-off shakes the camera without touching coins.

**Independent Test**: In one run, absorb through Tier 1 to Tier 4 and see the meter, 1 s pickup pop and one banner per tier, including no second banner after a knock-off and regrow; Jest cases for the tier banner and knock-off events pass; HUD captures at phone resolution are clean (quickstart scenarios 2 to 5).

### Tests for User Story 2 (write FIRST, they fail until T031 and T032)

- [X] T030 [US2] Edit `tests/studio/RunManager.spec.luau` (FR-024; same file as T014, run after it): add cases with a stub event sink (`RunManager.setEventSink(fn)` records `PickupConfirmed`, `TierUnlocked`, `KnockedOff`): a validated pickup emits `PickupConfirmed(objectId)`; growing across `minDiameter` 2.375 emits `TierUnlocked(2)` once; a knock-off then regrow across 2.375 emits no second `TierUnlocked`; `KnockedOff` is emitted only when at least one stuck entry popped (an empty-stack bump emits nothing); a knock-off does not change `absorbedCoinValues` and the result `coins` is the full total; a pickup that crosses two tier thresholds in one step emits one `TierUnlocked` for the highest tier and marks the lower tiers unlocked silently; no event is emitted after the bell.

### Implementation for User Story 2: server

- [X] T031 [US2] Edit `src/server/RunManager.luau` (FR-010; depends on T030): extend `onPickup` to look up the tier with `Tiers.lookup(session.authoritativeDiameter, Worlds.sizeTiers)` (use `Worlds.tierLikes` if T010 added it), fire `PickupConfirmed(object.id)`, and when the tier is greater than 1 and not in `unlockedTiers`, mark every tier up to it and fire `TierUnlocked(tier)` for the highest; add `onKnockOff(userId)` firing `KnockedOff()` and storing nothing; add `setEventSink(fn)` (default fires the `FireClient` remotes to the owning player only). Coins and `unlockedTiers` are never reduced.
- [X] T032 [US2] Edit `src/server/AbsorbService.luau` (depends on T031): after a validated knock-off in `tryBump` that popped at least one entry, call `RunManager.onKnockOff(session.userId)`. An empty-stack bump keeps its 001 behaviour and fires nothing.

### Implementation for User Story 2: client

- [X] T033 [US2] Edit `src/client/Hud.luau` (FR-017; depends on T022): add the top-left size meter 160×104 (`ui.hud.size_label`, the diameter from the ball's `Diameter` attribute through `ui.hud.size_value` with `string.format("%.1f", d)` in 32 px, a 160×14 progress bar filled by `Tiers.progress(d, Worlds.sizeTiers)`, and `ui.hud.next_tier` with the arrow icon and next tier headline, or `ui.hud.max_tier` on the top tier), updated on `Diameter` change only; the centre pickup pop (260×32, `ui.pickup.pop` with the object icon and `ui.pickup.pop` name from `Worlds.objectById`, fades over `Config.pickupPopDuration`, a new pickup replaces it); the tier banner (380×48, `ui.banner.tier_unlock` with the tier's `headlineIcon`, shown `Config.tierBannerDuration`); the bump flash (140×32, `[cube glyph] ui.bump.label` for `Config.knockOffShakeDuration`, shown even when `ReduceMotion` is on); the 0.15 s scale pop of the meter number on pickup (instant when the player attribute `ReduceMotion` is true). Positions and sizes exactly as in contracts/ui.md.
- [X] T034 [P] [US2] Edit `src/client/CameraController.luau` (R11): add `CameraController.shake(duration: number, magnitude: number)` that adds a decaying random offset in a `RunService:BindToRenderStep` step after the camera update and unbinds when finished; do nothing when the player attribute `ReduceMotion` is true. The existing distance smoothing already provides the tier pull-back (001 R5); add no extra pull-back code.
- [X] T035 [US2] Create `src/client/Feedback.luau` (FR-018, FR-019, R11; depends on T002, T020, T034): on `RunClient.pickup` play `Assets.sounds.pickup` with `PlaybackSpeed = 1 + Config.pickupPitchStep * (tier - 1)` (tier from `Worlds.objectById[objectId].tier`) and a light haptic pulse via `HapticService` inside `pcall` (`IsVibrationSupported(Enum.UserInputType.Gamepad1)` then `SetMotor`; unsupported devices skip silently, never error); on `tierUnlocked` play `Assets.sounds.tierUnlock`; on `knockedOff` play `Assets.sounds.bump` and call `CameraController.shake(Config.knockOffShakeDuration, Config.knockOffShakeMagnitude)`; on `result` play `Assets.sounds.bell`. Initialise the `ReduceMotion` player attribute to `false` (or from the engine's reduced-motion setting if Studio shows one exists). Each sound has a visual twin from `Hud`/`ResultsUi`.
- [X] T036 [US2] Edit `src/client/Main.client.luau` (depends on T035): start `Feedback`.

### Studio verification for User Story 2

- [ ] T037 [US2] 🔒 Studio: Run `return require(game.ServerStorage.Tests.runner)()` and confirm the new `RunManager.spec` cases pass with all earlier suites. Fix defects in the owning file (depends on T030 to T032, T036).
- [ ] T038 [US2] 🔒 Studio: Confirm each `Assets.sounds` path plays in Play mode and replace any that does not in `src/shared/Assets.luau`; confirm every `Icons` glyph renders in `FredokaOne` and `GothamMedium` in a viewport capture and swap any that does not in `src/shared/Content/Icons.luau` (R9). Note whether the engine exposes a reduced-motion setting (R11) (depends on T037).
- [ ] T039 [US2] 🔒 Studio: Run quickstart scenarios 2, 3, 4 and 5 solo (fast-forward with `RunManager.step` where useful). Expected: pickup sound, `+ Tiny cube` pop fading in about 1 s, meter pop and bar fill; one `You can roll up: SMALL CUBES!` banner at size 2.375 and `Next:` changes; bump flash, shake and sound on a knock-off with coins intact in the results; no second banner after regrowing across an unlocked tier. Read the console: zero new errors or warnings (depends on T038).
- [ ] T040 [US2] 🔒 Studio: Capture the HUD with a pickup pop and a tier banner visible together at 640×360, 844×390 and 1280×720; verify no overlap with the size meter, star row, thumbstick or Jump button, and text at least 18 px. Record sizes for the PR description (SC-002) (depends on T039).

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Pure Run Rules, Data-Driven Tiers and Full Localisation (Priority: P2)

**Goal**: Prove with Lune tests and guards that the rules are pure and hand-verified, the world is data only, and no English literal lives in a script.

**Independent Test**: `scripts/check.sh` exits 0 with the new Lune suites and `scripts/test-guard.sh` still fails on a bad Rules file (quickstart §1).

> These tests need only the Phase 2 files and can be written in parallel with Phase 3 and Phase 4. Expected values are hand-computed from `contracts/rules-api.md`.

### Tests for User Story 3

- [X] T041 [P] [US3] Create `tests/unit/Stars.test.luau` (FR-001, FR-023) using `tests/unit/harness.luau`: every row of the `Stars` table in contracts/rules-api.md (`19.99 -> 0`, `20 -> 1`, `44.99 -> 1`, `45 -> 2`, `79.99 -> 2`, `80 -> 3` with `{20,45,80}`; `2.99 -> 0`, `3 -> 1`, `4 -> 2`, `5 -> 3`, `1000 -> 3` with `{3,4,5}`; `7` with `{}` is `0`).
- [X] T042 [P] [US3] Create `tests/unit/Tiers.test.luau` (FR-002, FR-023) with `minDiameter = { 2, 2.375, 3, 3.75 }`: `lookup` rows `1.5 -> (1, 2.375)`, `2 -> (1, 2.375)`, `2.374 -> (1, 2.375)`, `2.375 -> (2, 3)`, `2.999 -> (2, 3)`, `3 -> (3, 3.75)`, `3.75 -> (4, nil)`, `100 -> (4, nil)`; `progress` rows `1.5 -> 0`, `2 -> 0`, `2.1875 -> 0.5`, `2.6875 -> 0.5`, `3.375 -> 0.5`, `3.75 -> 1`, `9 -> 1`.
- [X] T043 [P] [US3] Create `tests/unit/Coins.test.luau` (FR-003, FR-023) with `values = {1,2,3,5}` (base 11), `friendBonusRate = 0.2`, `friendBoostRate = 0.25`: empty list with every multiplier `0`; no multipliers `11`; friend only `13`; boost count 2 only `17`; double only `22`; friend + boost count 1 + double `33`; `{5}` boost count 2 `8`; `{1,1,1}` friend `4`; `{1}` friend `1`; boost count 0 equals no boost `11`. Also assert that the same list with extra trailing entries never gives a smaller total (knock-offs cannot lower coins).
- [X] T044 [P] [US3] Create `tests/unit/RunClock.test.luau` (FR-023): `remaining(10, 250) == 240`, `remaining(300, 250) == 0`, `expired(249.999, 250) == false`, `expired(250, 250) == true`, `format` of `240 -> "04:00"`, `239.2 -> "04:00"`, `239 -> "03:59"`, `61 -> "01:01"`, `60.5 -> "01:01"`, `59.01 -> "01:00"`, `0.4 -> "00:01"`, `0 -> "00:00"`, `-3 -> "00:00"`, `600 -> "10:00"`.
- [X] T045 [P] [US3] Edit `tests/unit/GreyBoxRoom.test.luau` (FR-008, data-model §2 "Validation rules"): `sizeTiers[i].tier == i`; `minDiameter` strictly ascends; `sizeTiers[1].minDiameter == 2`; `maxDiameter[i] == minDiameter[i+1]` and the top tier has none; for tier `n >= 2`, `minDiameter == layoutTier(n).size / 0.4` within `1e-9`; object `id` and `bookId` unique; `coins` positive integer; `size == layoutTier(tier).size`; every layout tier has exactly one object and every cube's tier has an object; `starThresholds` ascending, positive, length 3; every `nameKey`, `headlineKey` has a non-empty `en` in `Strings` and every `icon`/`headlineIcon` exists in `Icons`; `hub.halfExtent > 0` and `|hub.center.x| - hub.halfExtent > room.halfExtent + 2`. Existing 001 assertions stay.
- [X] T046 [P] [US3] Edit `tests/unit/Config.test.luau`: keep the two invariants (every number finite; every top-level number greater than zero except `fallRespawnY`); add a test that `Config.starThresholds` is ascending, positive, length 3, and that `Config.Flags.RunLoop` is a boolean.
- [X] T047 [P] [US3] Create `tests/unit/Strings.test.luau` (FR-022, R8): every entry has a non-empty `en` string; `{placeholders}` are balanced (every `{` closes, names are `[%w_]+`); every key listed in contracts/content-and-config.md exists; every `Localizer.t("…")` string literal found by scanning `src/client/*.luau` has a key in `Strings`. Read files with `@lune/fs` as `tests/unit/run.luau` does.
- [X] T048 [P] [US3] Create `tests/unit/LiteralGuard.test.luau` (FR-022, SC-005, R8): scan `src/client/*.luau` and `src/server/*.luau` and fail on any `Text = "…"` or `.Text = "…"` assignment whose literal contains two or more consecutive letters; symbol-only text is allowed. Include a self-check: the guard's matcher rejects a fixture string like `label.Text = "Roll again"` and accepts `label.Text = Icons.star`.

### Verification for User Story 3

- [X] T049 [US3] Run `scripts/check.sh` and `scripts/test-guard.sh`; both exit 0 (depends on T041 to T048). Also confirm the world seam (FR-006): `grep -rnE "greybox|cube_t|GreyBoxRoom" src/server/RunManager.luau src/client/Hud.luau src/client/ResultsUi.luau src/client/HubUi.luau src/client/Feedback.luau src/client/RunClient.luau` returns no hit (those modules read the world only through `Worlds`), and fix any hit.

**Checkpoint**: All three user stories work independently and every gate in `scripts/check.sh` is green.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Playtest scaffolding, final Studio pass and the PR description.

- [X] T050 [P] Create `specs/002-run-loop/playtest.md` as the fill-in template (Constitution I, quickstart §7): date, commit hash, players by age group (adults and children aged 10 to 12), per-run table (final diameter, stars, when Tiers 2, 3, 4 opened, coins), star-threshold verdict for `{ 3.0, 4.0, 5.0 }` (retune in `GreyBoxRoom.starThresholds` if most runs earn 0 or 3 stars), phone vibration result (finding F-3), 6-player feel (finding F-4), phone capture links, findings, and an owner sign-off line left blank.
- [ ] T051 👤 Run the playtest with real players (at least 3 adults and 3 children aged 10 to 12, including one phone at the reference spec) on the private test place, never the live place. Time a solo run to the bell three times (quickstart §7), run quickstart scenario 13 with two accounts (friend bonus and friend row), fill in `specs/002-run-loop/playtest.md` and collect the owner's sign-off. Constitution I: no art, monetization or live-ops work may start until this is signed off (depends on T050).
- [ ] T052 🔒 Studio: SC-006 console cleanliness. Run quickstart scenarios 1 to 11 in one Play session driven through the Studio MCP server and read the console with `get_console_output`: zero new errors and zero warnings (a speed-violation `warn` in honest play counts as a failure). Record the result for the PR (depends on T040).
- [X] T053 Verify every `.luau` file under `src` and `tests` starts with `--!strict` (`grep -L '^--!strict' $(git ls-files '*.luau')` prints nothing) and that no `SoundId` or `rbxasset://` string exists outside `src/shared/Assets.luau`; fix any listed (Constitution XI, XII).
- [ ] T054 Draft `specs/002-run-loop/pr-description.md` stating how each Quality Gate was met (plan.md "Quality Gates mapping": gate 1 `scripts/check.sh`; gate 2 Studio playtest, console read and phone captures from T029, T040, T052; gate 3 sounds are engine built-ins recorded in `Assets.luau`; gate 4 every new string in `Strings.luau`; gate 5 `tasks.md` ticks) and the Constitution check outcome, including findings F-1 to F-4. Mark every completed task in this file `- [X]`.

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 Setup**: no dependencies; T001, T002, T003 run in parallel.
- **Phase 2 Foundational**: depends on Phase 1 for `Config` (T001) and `Icons` (T003). Blocks US1 and US2. Internal order: T004 to T008 are independent; T009 needs T003 and T008; T010 needs T001 and T009; T011 needs T008; T012 and T013 are independent.
- **Phase 3 US1**: depends on Phase 2. **Phase 4 US2**: depends on Phase 3 (it extends `RunManager`, `AbsorbService`, `Hud`, `Main.client`, and the same `RunManager.spec`). **Phase 5 US3**: its test files depend only on Phase 2 and can run in parallel with Phases 3 and 4; T049 runs last. **Phase 6 Polish**: after the stories it covers.

### Story completion order

```text
Phase 1 -> Phase 2 -> US1 (P1, MVP) -> US2 (P1)
                  \-> US3 tests (P2) can start right after Phase 2, T049 after all code
US1, US2, US3 -> Polish
```

### Within each story

- Jest spec first (T014, T030), then server modules, then client modules, then Studio tasks (last in the story, one agent at a time).
- US1 server order: T015 and T016 (parallel) -> T017 -> T018 -> T019. US1 client: T020, T021, T023 (after both), T024, T025 in parallel where the dependency list allows -> T022 -> T026.
- US2 server order: T031 -> T032. Client: T034 first, then T033 and T035 -> T036.

### File ownership (keeps `[P]` tasks disjoint)

`Config.luau` T001 · `Assets.luau` T002 · `Icons.luau` T003 · `Rules/*` T004 to T007 · `Strings.luau` T008 · `GreyBoxRoom.luau` T009 · `Worlds.luau` T010 · `Localizer.luau` T011 · `Remotes.luau` T012 · `FriendCache.luau` T013 · `WorldSpawner.luau` T015 · `BallService.luau` T016 · `RunManager.luau` T017, T031 · `AbsorbService.luau` T018, T032 · `Main.server.luau` T019 · `RunClient.luau` T020 · `UiKit.luau` T021 · `Hud.luau` T022, T033 · `ResultsUi.luau` T023 · `HubUi.luau` T024 · `BallController.luau` T025 · `Main.client.luau` T026, T036 · `CameraController.luau` T034 · `Feedback.luau` T035 · `RunManager.spec.luau` T014, T030 · one Lune test file per T041 to T048.

---

## Parallel Execution Examples

```text
Phase 1:  T001  T002  T003                    (three separate files)
Phase 2:  T004  T005  T006  T007  T008  T012  T013     (then T009 -> T010; T011 after T008)
US1:      T015  T016                           (WorldSpawner, BallService)
          T020  T021  T025                     (RunClient, UiKit, BallController)
          then T023  T024                      (ResultsUi, HubUi), T022 (Hud)
US2:      T034  then T033  T035                (CameraController, then Hud, Feedback)
US3:      T041  T042  T043  T044  T045  T046  T047  T048    (eight test files, start after Phase 2)
```

With several agents (each in its own worktree, Constitution X): one agent on the Rules and their Lune tests (T004 to T007, T041 to T044), one on content and strings (T008 to T011, T045, T047), one on `src/server`, one on `src/client`. Only one agent drives Studio at a time.

---

## Implementation Strategy

### MVP first (User Story 1 only)

1. Phase 1 and Phase 2, then check the foundation with `scripts/check.sh`.
2. Phase 3 (US1). Stop and validate: three runs in a row, one result per run, **Roll again** within 3 s, **Back to hub**.
3. That is a playable run loop with a timer, star targets and results, enough for an early look before the feedback polish.

### Incremental delivery

1. Add US2 (meter, pop, banner, sounds, shake): validate in a single run through all four tiers.
2. Add US3 tests and guards (can be merged earlier): run `scripts/check.sh` and `scripts/test-guard.sh`.
3. Polish: playtest template, final console read, PR description.

---

## Notes

- Finding F-1 (plan.md): the grey-box room overrides the production star targets with `{ 3.0, 4.0, 5.0 }` (`GreyBoxRoom.starThresholds`); `Config.starThresholds = { 20, 45, 80 }` stays the default and the Stars boundary tests use it. The grey-box values are provisional until the playtest (T051).
- Finding F-2: `rollAgainDelaySeconds = 3` is an upper bound asserted by tests, not a delay; **Roll again** restarts at once.
- Finding F-3: phone haptics may be unavailable; `Feedback` never errors, and the real-device result goes in `playtest.md`.
- Finding F-4: crowded servers starve the room, so stars are a solo or small-group measure here; pooling and refill rules come with Feature 004.
- No save data (coins, best sizes and seen book entries are in-memory per server session; Feature 003), no purchases, no new tool or package. Constitution V, VIII and XII have nothing to add.
- `[P]` marks only tasks on disjoint files. Commit after each task or logical group; never commit place files or secrets.
