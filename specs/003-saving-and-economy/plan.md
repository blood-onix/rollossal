# Implementation Plan: Saving and Economy

**Branch**: `003-saving-and-economy` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-saving-and-economy/spec.md`

## Summary

Make progress persist. A server `DataService` loads one ProfileStore profile per player (session-locked,
mock store in Studio), reconciles and migrates it with pure rules, and applies every 002 `RunResult`
exactly once: coins added, best size raised, book entries inserted as a set, completed-page cosmetic
rewards granted. The client gets a read-only `ProfileSync` snapshot and shows it in three places: a new
**Book** screen (tier pages, silhouettes, `collected / total`, reward badge), a new **Settings** screen
(music, effects, camera sensitivity, reduce motion, language; applied live, validated and saved by the
server), and the Hub and Results screens (persistent coins, best size, "New in your book", a first-run
tip). A new top-right **TopBar** (Book, Shop, Settings) opens the two screens. Profile defaults,
reconcile, migration, idempotent run application, book pages and settings validation are pure Luau in
`src/shared/Rules`, tested with Lune. The owner already approved the DataStore name, key format and the
Profile Schema v1 keys (spec, Owner Approval Gate); this plan changes none of them.

Technical approach, one line each (reasoning and alternatives are in [research.md](research.md)):

- **Store**: `ProfileStore.New("PlayerProfiles_v1")`, key `"Player_<UserId>"`, `.Mock` whenever
  `RunService:IsStudio()` and `Config.useMockDataStoreInStudio` (R1).
- **Pure/impure split**: `Rules/Profile`, `Rules/Book`, `Rules/Settings` are standalone modules; the
  reward lookup is passed to `Profile.applyRunResult` as a function, because Rules may not `require` each
  other (R2).
- **Idempotency**: `appliedRuns[runId]` is the guard; the ledger is emptied on every profile load, because
  a `runId` is unique only inside one server (finding F-2, R3).
- **First run**: derived from an empty `bestSize`, no new schema field (finding F-3, R4).
- **Replication**: one server-to-client `ProfileSync` snapshot plus a zero-argument `RequestProfile`
  intent; `RunResult` also carries `coinsTotal` and `isFirstRun` so the Results screen never depends on
  event ordering (R5).
- **Run integration**: `RunManager` reads the persistent book and best size from `DataService`, applies the
  result, then publishes it; without a profile it behaves exactly as in 002 (R6).
- **Settings**: client applies at once, debounces, sends `UpdateSettings`; server validates, clamps,
  rate-limits, saves and echoes (R7).
- **Language**: `Localizer` gets an override, a `changed` signal and an optional locale argument for the
  server-side kick message; new strings ship with `en` and `es` (R8).
- **Book content**: tier `reward` is optional data on `SizeTierDef`; the grey-box tiers get four
  placeholder rewards so the grant path is testable (R9).
- **UI**: `TopBar`, `BookUi`, `SettingsUi` built with `UiKit`; utility buttons use a 64 px minimum so the
  bar fits 640×360 (finding F-4, R10).
- **Failures**: no profile means kick; a profile from a newer schema means kick; a session ended by
  another server means kick (R11).

## Technical Context

**Language/Version**: Luau (strict mode, `--!strict` on every file), Roblox engine as shipped with the
installed Studio.

**Primary Dependencies**: `lm-loleris/profilestore@1.0.3` (already pinned in `wally.toml`, installed in
`ServerPackages`), Rojo 7.7.1, Jest-Lua (`jsdotlua/jest@3.10.0`), Lune 0.10.5. Roblox services only:
`DataStoreService` (through ProfileStore), `RunService`, `Players`, `LocalizationService`, `SoundService`,
`UserInputService`, `GuiService`. **No new tools or packages** (Constitution XII).

**Storage**: ProfileStore DataStore `"PlayerProfiles_v1"`, key `"Player_<UserId>"`, Profile Schema v1
(owner-approved, spec Owner Approval Gate). Auto-save every 300 s (ProfileStore default) and on release.
Studio and tests use `ProfileStore.Mock`, never the live store.

**Testing**: Lune unit tests in `tests/unit` for `Profile`, `Book`, `Settings`, `RunClock`, Config, Content
and Strings; Jest-Lua Studio tests in `tests/studio` (`DataService.spec.luau`, plus the touched
`RunManager.spec.luau`) on the mock store; Studio MCP playtest with console read and phone-resolution
captures of TopBar, BookUi, SettingsUi, Hub and Results; static gates StyLua 2.5.2, Selene 0.32.0,
luau-lsp 1.70.1 (strict).

**Target Platform**: Roblox client (PC and phones) and Roblox server. Reference phone: Galaxy A53/A54
class (carried assumption).

**Project Type**: Roblox game (Rojo-managed Luau project: shared, server and client trees).

**Performance Goals**: 30 fps on the reference phone with a panel open. `ProfileSync` is sent on load, after
each applied run and after each accepted settings change: a few hundred bytes, never per frame. Book grid
is built once per open and per snapshot change (at most 15 cards per tier page plus 4 page headers).

**Constraints**: nothing the client sends may set coins, best size, book, rewards or run results (II);
`UpdateSettings` carries preferences only, is type-checked, clamped and rate-limited (II, VIII); Rules free
of Roblox APIs (III); only `UserId` and progress stored (VIII); every string through `Localizer` (IX); no
paid path to coins (V); no menu in front of the first run: Book is locked for the first 5 s of a run (VI);
text ≥ 18 px, status never by colour alone (VI); new behaviour behind `Config.Flags.Saving` (VII).

**Scale/Scope**: 1 world (grey-box), 4 tiers, 4 objects, 12 players per server. About 8 new Luau source
files, 12 edited, 5 new test files, 6 edited (see Project Structure).

## Constitution Check

*GATE: passes before Phase 0 research; re-checked after Phase 1 design.* Constitution v1.0.0.

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I. Fun proven in grey box | **Pass** | The grey-box gate was met by 001 and 002 playtests. Saving, Book and Settings are persistence and menus, not a new core mechanic; the UI is plain `UiKit` frames, no art, no new audio. The Book screen and Hub additions get a short grey-box check in `specs/003-saving-and-economy/playtest.md` (date, commit, participants by age group, owner sign-off) before any polish. |
| II. Server authority | **Pass** | Coins, best size, book and rewards change only inside `DataService.applyRunResult`, called by `RunManager` with a server-built result. The client may send two things: `RequestProfile()` (no arguments) and `UpdateSettings(payload)`, which carries only preferences (volumes, sensitivity, reduce motion, language), is type-checked, clamped, rate-limited and never trusted for progress. Jest-Lua tests cover duplicate and late `runId`, malformed settings and load failure (FR-017). |
| III. Pure, tested rules | **Pass** | `Profile`, `Book`, `Settings` and the new `RunClock.uiLocked` are standalone pure modules with hand-computed Lune tests ([contracts/rules-api.md](contracts/rules-api.md)). Bounds and defaults enter as arguments built from `Config`, so Rules need no `require`. `check.sh` already greps `src/shared/Rules` (note: the words `game`, `task`, `Enum` are forbidden even in comments there). |
| IV. Safe for everyone | **Pass** | No chat, no gore, no player-vs-player. Nothing here changes the maturity answers. Saving never removes progress (no loss on knock-off or on leaving). The Book is finite (pages of fixed size), no infinite feed. |
| V. Ethical monetization | **Pass** | One soft currency, earned only by `RunResult.coins`; no code path adds coins except `applyRunResult`. No prices, no offers; the Shop button shows only a notice and is behind `Config.Flags.Shop = false`. `receipts` is reserved for Feature 006 and untouched. |
| VI. Mobile first | **Pass** | Book cannot open in the first 5 s of a run (`Config.runStartUiLockSeconds`); no menu appears in front of the first run. Text ≥ 18 px after `UIScale`; status uses icon plus label (page `3 / 4` text, reward badge glyph, silhouette plus `???`). Panels leave the top-centre timer visible and avoid the right-hand TopBar column; captures at 640×360, 844×390, 1280×720. Utility buttons are 64 px high (finding F-4); primary actions stay at 96 px. |
| VII. Content is data | **Pass** | Page rewards are optional data on `SizeTierDef` (`reward`); Book pages are computed from `Worlds.active`, so a new world needs no code. Lune tests validate reward IDs and keys. New behaviour sits behind `Config.Flags.Saving` (and `Shop`). |
| VIII. Player data | **Pass (owner-approved)** | ProfileStore only; `version` carried; `Profile.migrate` plus a mechanism test ships with v1; only `UserId` and progress stored (`profile:AddUserId`); no names. DataStore name, key and v1 keys were approved on 2026-10-25 (spec). No player-influenced text is shown, so no `TextService` filtering is needed. |
| IX. Localised strings | **Pass** | Every new string is a `Strings.luau` key (including the kick messages); `LiteralGuard` test already rejects letter-bearing `Text` literals. New keys ship with `en` and `es`; the full Spanish pass for 002 strings is Feature 007. |
| X. Multi-agent discipline | **Pass** | Own branch; file ownership below keeps `[P]` tasks disjoint; Studio MCP claimed per task; no place files or secrets; no live publishing. |
| XI. Asset pipeline | **Pass** | No imported assets. Icons are glyphs in `Content/Icons.luau`; no sounds added. |
| XII. Keep it lean | **Pass** | ProfileStore is already pinned and named in the constitution. Each new abstraction has two users: `Settings` (server validate, client clamp), `Profile` (DataService, tests of the same rules in Lune and Studio), `ProfileClient` (HubUi, ResultsUi, BookUi, SettingsUi, Feedback, CameraController), `TopBar` (Book and Settings screens), `Book` (server rewards, BookUi). |

**Quality Gates mapping** (the PR description states how each was met): gate 1 `scripts/check.sh`; gate 2
Studio MCP playtest (join, run, bell, rejoin, settings change, book open) with console read, plus captures
of TopBar, BookUi, SettingsUi, Hub and Results at 640×360, 844×390 and 1280×720; gate 3 N/A (no assets);
gate 4 every new string in `Strings.luau`; gate 5 `tasks.md` ticks.

**Human Approval Required items**: DataStore name, key and v1 schema keys are **already approved** (spec,
2026-10-25). Nothing else triggers approval: no publish, no prices, no maturity change, no new tool, no
spend. One owner confirmation is requested, not blocking: see Open Items.

**Post-design re-check (after Phase 1)**: no violation found. The design adds no tool, package or service;
every progress decision stays on the server; Rules stay pure; no schema key was added or renamed (the
first-run flag and the ledger bound are solved without one). Complexity Tracking stays empty.

### Findings (spec, constitution and dependency gaps the plan resolves)

- **F-1 This branch has no 002 code yet.** `003-saving-and-economy` was cut from `main`, which does not
  contain `RunManager`, `Localizer`, `Hud`, `ResultsUi`, `HubUi`, `UiKit`, `Worlds` or `RunResult`; they
  live on `002-run-loop`. Everything below is designed against that branch (commit `11b1302`). Implementation
  must start after 002 is merged to `main` and this branch is brought up to date (merge or rebase). The
  planning artifacts do not depend on the merge.
- **F-2 `runId` is only unique inside one server.** 002 builds it as `"<userId>-<serverRunSeq>"`, and
  `serverRunSeq` restarts at 0 on every server. A ledger that survived across sessions would reject a real
  run on a later server whose id repeats an old one (`123-1` today and next week). Two servers cannot hold
  the same profile at once (session lock), so the ledger only has to cover the current session. Plan: empty
  `appliedRuns` on every profile load (`Profile.prepare`); the key and type stay as approved, no 002 change.
- **F-3 The spec's first-run trigger has no counter to read.** "0 applied runs to 1 applied run" cannot
  work once the ledger is emptied per session, and schema v1 has no run counter (adding one needs owner
  approval). Every applied run writes `bestSize[worldId]` (`finalDiameter ≥ 2`), so `next(bestSize) == nil`
  before the apply means "first run ever". `Profile.applyRunResult` returns `isFirstRun`; `RunResult` gets a
  boolean `isFirstRun` field (additive to 002).
- **F-4 Three 96 px buttons do not fit the HUD at 640×360.** `UiKit.button` forces 96×96. Stacked in the
  top-right column they need 3×96 + gaps = 304 px, but the bottom 130 px of each corner is reserved for the
  thumbstick and Jump (002 ui.md), leaving 230 px; side by side they collide with the timer block
  (x 165 to 475). Plan: `Config.minUtilityTouchTarget = 64` for TopBar, Book and Settings controls, 96 px
  stays for Roll again, Play and Jump. The owner confirms the 64 px figure at the playtest.
- **F-5 Shop has no screen yet.** The spec only defines the Shop button during a run. Outside a run, and in
  all states while `Config.Flags.Shop` is false, tapping it shows a short localized notice
  (`ui.hud.shop_after_run` during a run, `ui.hud.shop_soon` otherwise). Feature 006 turns the flag on.
- **F-6 `Localizer.t` has no locale argument and no language override.** The spec's kick message calls
  `Localizer.t(key, nil, playerLocale)` and Settings needs a live language. Both are added (R8).
- **F-7 Camera sensitivity may not be settable for touch.** Roblox exposes mouse delta scaling to scripts
  (`UserInputService.MouseDeltaSensitivity`); the default camera's touch pan speed is not documented as
  scriptable. Handled as a measured risk (Risk Results below) with a defined fallback.
  Review round 4: instead of leaving touch unscaled, `CameraController` now scales every look input after the
  default camera script runs (pure `Rules/CameraLook`, applied at `RenderPriority.Camera + 1`), so the slider
  works on mouse, touch and gamepad. `MouseDeltaSensitivity` is left at its default to avoid scaling twice.
  The feel on a real phone is still an owner check (T048 d).
- **F-8 Rules cannot `require` each other.** `check.sh` forbids `require(script` under `src/shared/Rules`,
  and 001 made every Rules module standalone. The spec's "apply a run, grant page rewards" therefore cannot
  call `Book` from `Profile`; the server passes the reward lookup in as a function (R2).
- **F-9 Test place may share the live DataStore.** If the private test place belongs to the same experience
  as the live place, it shares `"PlayerProfiles_v1"` with live players. Studio is safe (mock). See Open Items.

### Open Items (owner, not blocking planning)

1. Confirm the private test place is a **separate experience** from the live one. If it is not, a published
   test build would write to live profiles; the fix is a `Config.dataStoreName` override for test builds,
   which is a key-name change and needs owner approval before it is made.
2. Confirm the 64 px utility-button minimum (F-4) at the first phone playtest.

## Project Structure

### Documentation (this feature)

```text
specs/003-saving-and-economy/
├── plan.md              # This file
├── research.md          # Phase 0 output: decisions R1 to R14
├── data-model.md        # Phase 1 output: profile, settings, snapshot, flows, states
├── quickstart.md        # Phase 1 output: how to run, test and verify
├── contracts/
│   ├── remotes.md             # UpdateSettings, RequestProfile, ProfileSync, RunResult additions
│   ├── replicated-state.md    # what the server publishes, what each client module reads
│   ├── rules-api.md           # Profile, Book, Settings, RunClock signatures and test values
│   ├── content-and-config.md  # Config keys, SizeTierDef reward, string keys, icons
│   └── ui.md                  # TopBar, BookUi, SettingsUi, Hub and Results changes
├── checklists/requirements.md  # (from /speckit-specify)
├── playtest.md          # Created during implementation, filled during the check
└── tasks.md             # Phase 2 output (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
src/shared/                           # -> ReplicatedStorage.Shared
├── Config.luau                       # EDIT: saving keys, Settings bounds, utility target, Flags.Saving/Shop
├── Content/
│   ├── GreyBoxRoom.luau              # EDIT: SizeTierDef.reward (optional) + four grey-box rewards
│   └── Icons.luau                    # EDIT: gear, shop, lock, unknown, prev, next, close glyphs
├── Localization/
│   ├── Localizer.luau                # EDIT: setLanguage, changed signal, optional locale argument, es table
│   └── Strings.luau                  # EDIT: optional es field; ~50 new keys with en and es
└── Rules/                            # pure; standalone modules, no requires
    ├── Profile.luau                  # NEW: defaults, reconcile, migrate, prepare, applyRunResult
    ├── Book.luau                     # NEW: newIds, pages, completedRewardIds
    ├── Settings.luau                 # NEW: validate (clamp, type-check)
    └── RunClock.luau                 # EDIT: uiLocked

src/server/                           # -> ServerScriptService
├── DataService.luau                  # NEW: ProfileStore sessions, apply, settings, sync, kick
├── Remotes.luau                      # EDIT: UpdateSettings, RequestProfile, ProfileSync
├── RunManager.luau                   # EDIT: persistent book/best size, apply before publish, new result fields
└── Main.server.luau                  # EDIT: start DataService (behind Config.Flags.Saving)

src/client/                           # -> StarterPlayer.StarterPlayerScripts
├── ProfileClient.luau                # NEW: snapshot cache, signals, RequestProfile, UpdateSettings sender
├── TopBar.luau                       # NEW: Book, Shop, Settings buttons, 5 s lock, shop notice
├── BookUi.luau                       # NEW: tier pages, silhouettes, progress, reward badge
├── SettingsUi.luau                   # NEW: 3 sliders, toggle, language selector
├── UiKit.luau                        # EDIT: minSize option on button; slider, toggle, panel helpers
├── RunClient.luau                    # EDIT: parse coinsTotal, isFirstRun
├── HubUi.luau                        # EDIT: coins and best size rows
├── ResultsUi.luau                    # EDIT: total coins, first-run tip, persistent best size
├── Feedback.luau                     # EDIT: sound groups from volumes; ReduceMotion = setting or system
├── CameraController.luau             # EDIT: sensitivity (risk R7)
└── Main.client.luau                  # EDIT: start ProfileClient, TopBar, BookUi, SettingsUi

tests/
├── unit/                             # Lune
│   ├── Profile.test.luau  Book.test.luau  Settings.test.luau            # NEW
│   └── RunClock.test.luau  Config.test.luau  GreyBoxRoom.test.luau  Strings.test.luau  # EDIT
└── studio/                           # Jest-Lua, -> ServerStorage.Tests
    ├── DataService.spec.luau         # NEW: load, reconcile, apply, idempotency, failure, settings
    └── RunManager.spec.luau          # EDIT: persistent fields in the result
```

**Structure Decision**: the standard Rollossal layout from the design brief §9. `DataService` sits next to
`RunManager` on the server; the client gets one data module (`ProfileClient`) the way 002 has `RunClient`.
`TopBar` is its own module rather than part of `Hud`, because `Hud` is visible only in `Active` and the bar
must also show in `Ended` and `Hub`. `[P]` tasks can run in parallel across these disjoint groups: Rules
plus unit tests; Config plus Content plus Strings; `DataService` plus its spec; client data and UI files
(`BookUi`, `SettingsUi`, `TopBar` are disjoint from `HubUi`/`ResultsUi`).

## Design Notes That Affect Tasks

1. **Load, never block play.** `Players.PlayerAdded` starts the run at once (002) and, in parallel,
   `DataService` yields in `StartSessionAsync`. ProfileStore gives up after 120 s, half a run, so by the
   bell the profile is loaded or the player has been kicked. `applyRunResult` returns `nil` when no
   profile exists; `RunManager` then publishes as in 002 (which also keeps every 002 Jest test valid).
2. **Bell round trip.** `endRun` builds the result with `newBookIds` and `bestSelfSize` read from
   `DataService`, calls `DataService.applyRunResult`, merges `coinsTotal` and `isFirstRun` into the result,
   then publishes. `DataService` fires `ProfileSync` inside the apply, before the publisher fires `RunResult`.
   The Results screen uses the fields on the result, never the snapshot, so event order cannot matter.
3. **Apply is synchronous.** `Profile.applyRunResult` runs with no yield between the ledger check and the
   write, and `DataService` checks `profile:IsActive()` first (the documented guarantee holds until the
   next yield). A session that already ended grants nothing.
4. **`appliedRuns` lifetime.** Emptied in `Profile.prepare`, filled by every apply, saved with the profile.
   It never needs bounding because it holds at most one entry per run in one session (a session is hours,
   a run is 240 s).
5. **Settings echo.** The server always replies with the authoritative settings through `ProfileSync`, so
   a clamped value snaps the control back. The client debounces 0.3 s and flushes on panel close; the
   server allows `Config.settingsRateLimit` (20) updates per `Config.rateLimitWindow` and ignores the rest
   without a warning.
6. **Time.** `DataService` reads no clock except for the rate limiter, which takes `os.clock()` from the
   remote handler like 002. Rules never read time; `RunClock.uiLocked` gets `now`, `endsAt`, `duration`
   and `lockSeconds` as arguments.
7. **Logging.** Only real failures `warn`: a profile that will not load, a future-version profile, a
   session stolen while the player is present. Ordinary rejections (duplicate run, bad settings payload,
   rate limit) are silent counters, so a clean playtest shows no warnings (SC-005).
8. **Language switch.** `Localizer.setLanguage` fires `Localizer.changed`; `Hud`, `HubUi`, `ResultsUi`,
   `TopBar`, `BookUi` and `SettingsUi` each re-apply their static labels from one `refreshText` function.
   Dynamic labels already rebuild text per update.
9. **Rules purity words.** Do not write `game`, `task`, `Enum`, `Instance`, `workspace`, `tick` or `require(script`
   anywhere in `src/shared/Rules`, comments included.

## Risk Results (to be filled during implementation)

| Risk | Measured result | Decision |
| --- | --- | --- |
| Camera sensitivity reachable by script on PC and touch (F-7, R7) | Superseded by review round 4 and 5. The first spike (2026-10-26) only showed that the slider set `UserInputService.MouseDeltaSensitivity` (2.0 at 200%); the effect on the real pan was not measured, and the touch pan has no script-visible scale. `CameraController` no longer sets `MouseDeltaSensitivity`. It applies `Rules/CameraLook` after the default camera script, so the slider scales mouse, touch and gamepad. **No Studio or device measurement of this path is recorded yet**: the logic is covered by closed-loop unit tests (`tests/unit/CameraLook.test.luau`, which feed the adjusted look back as the default script does), but the feel on a mouse, a phone and a gamepad is unmeasured. | `CameraLook` per-frame increment at `RenderPriority.Camera + 1`; `MouseDeltaSensitivity` left at its default. Owner check at 50 % and 200 % on mouse, real phone and gamepad (the camera must stop when the input stops) stays in T048(d). |
| Setting glyphs render in `FredokaOne` and `GothamMedium` (⚙, 🛒, 🔒, ◀, ▶, ✕) (002 found `↻` missing) | Capture of every glyph at 48 px in both fonts (2026-10-26). Render in both: ⚙ 🛒 🔒 ❓ ◀ ▶ ▤ ⌂ ● ■ ▲ ★ ☆ ⏱ ❌ ✅. Fail: `✕` (blank in FredokaOne, a box in GothamMedium), `✘` and `✗` (blank or box). Render but only as a dark grey glyph that is nearly invisible on the dark panels: `✔` and `✖`. ⚙ and 🛒 render as small grey emoji on the green TopBar buttons; the text label carries the meaning. | `Icons.close` is now `❌` and `Icons.check` is `✅` (this file only, as T013 allows). Other glyphs kept. |
| TopBar, Book and Settings fit 640×360 without covering timer or corner controls (F-4) | Measured on exact 640×360, 844×390 and 1280×720 frames (2026-10-26). First pass found four real defects, all fixed: the 002 size meter box ends at y 112, so panels at y 100 clipped its second line (panels now y 112, 464×240); the TopBar column covered the right half of the 600×320 Results panel (panel now 464×320, centred left of the TopBar); the Spanish tip and two Spanish setting labels did not fit (shortened); the Shop notice at y 224 reached into the Jump zone (right edge now 136 px from the screen edge). Final pass: no text under 18 px, no text that fails `TextFits`, nothing outside the frame, nothing over the timer block, TopBar clear of both bottom corners, no unexpected overlaps, at all three sizes. | Offsets adjusted in the UI files and in `contracts/ui.md`; 64 px utility minimum kept. Known: the transient 002 tier banner (480 wide at y 120) crosses the TopBar column at 640 wide for its few seconds; it belongs to 002. |
| Profile load time on a cold DataStore | pending (Studio with API access to a throwaway key, optional) | None expected; kick path covers failure |

## Complexity Tracking

No Constitution Check violations. Nothing to justify.
