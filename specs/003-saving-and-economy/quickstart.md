# Quickstart: validate Saving and Economy

How to prove the feature works end to end. Contracts: [remotes.md](contracts/remotes.md),
[rules-api.md](contracts/rules-api.md), [replicated-state.md](contracts/replicated-state.md),
[ui.md](contracts/ui.md). Data: [data-model.md](data-model.md). No implementation code lives here.

## Prerequisites

- Feature 002 is merged to `main` and this branch contains it (plan finding F-1).
- `rokit install`, `wally install` (ProfileStore appears in `ServerPackages/`), Studio open on the Rojo
  project (`rojo serve`), the Studio MCP server connected.
- Studio is in its default state: **no** Roblox API access for Studio is needed; `ProfileStore.Mock` is
  used because `Config.useMockDataStoreInStudio = true`.

## 1. Static gate and unit tests (every task)

```bash
scripts/check.sh
```

Expected: exit 0. Includes StyLua, Selene, luau-lsp strict, all Lune suites (`Profile`, `Book`,
`Settings`, `RunClock`, `Config`, `GreyBoxRoom`, `Strings`, `LiteralGuard`) and the Rules purity guard.

## 2. Jest-Lua suites (server logic, mock store)

From the Studio MCP `execute_luau`:

```lua
return require(game.ServerStorage.Tests.runner)()
```

Expected: `DataService.spec` and `RunManager.spec` pass, 0 failures. The suite must not create or read any
real DataStore key (every test uses `store.Mock` and user ids from 900001 up). Covers: new profile has v1
defaults; a partial profile is reconciled and saved values survive; a run adds coins, raises best size,
inserts book entries, grants a completed page reward; a repeated or late `runId` changes nothing; coins
never go negative and best size never drops; a v1 profile loads unchanged; a store returning `nil` kicks
with the localized `error.profile_load_failed`; `OnSessionEnd` kicks; malformed `UpdateSettings` payloads
are ignored or clamped without error.

## 3. Playtest: save, leave, rejoin (Studio, mock store)

1. Start a Play session. Console is clean after join (no warnings, no errors).
2. Roll up every cube type once, wait for the bell (or use the MCP to expire the run), read the Results
   screen: **first run** shows `ui.results.first_run_tip`, `Coins: N (total N)`, and the New in your book list.
3. Tap **Roll again**, finish a smaller run: total coins equals the sum of both runs; best size is the
   larger run's diameter (acceptance scenario US4-1).
4. Tap **Back to hub**: the Hub card shows the same coin total and best size.
5. Leave and rejoin within the same Studio server (the mock store keeps the profile): coins, best size, book
   and settings are restored; the first run after rejoining is **not** shown as a first run.
6. Console after all steps: zero new errors or warnings.

## 4. Playtest: Book and the 5-second lock

1. Join; within the first 5 s tap **Book**: nothing opens, the button shows the lock glyph.
2. After 5 s tap **Book**: the panel opens below the timer; the timer stays visible; undiscovered cubes show
   `???`; tier headers show `collected / total` and the reward line.
3. Complete a page (eat the one cube of a tier): that page shows `1 / 1` and `Earned`; `skinsOwned`
   (inspect through MCP `execute_luau` on the server) holds the page's reward id exactly once, even after
   eating that cube again in a later run.
4. In the Hub, **Book** opens at any time.

## 5. Playtest: Settings

1. Open **Settings**: five controls, all text ≥ 18 px.
2. Drag **Music volume** and **Effects volume** to 0 then 100 %: the next pickup sound is silent / full.
3. Toggle **Reduce motion** on, trigger a knock-off: no camera shake, the "Bump!" label still shows.
4. Change **Camera sensitivity** to 50 % and 200 %: look around with the mouse, on a real phone with touch and
   with a gamepad if available. The turn should be about half / double, and the camera must stop turning when
   the input stops. Record the result in plan.md Risk Results.
5. Choose **Español**: new-feature screens (Book, Settings, Hub rows, Results coins line) switch to Spanish,
   002 strings stay English until Feature 007. Choose **Auto** again.
6. Leave and rejoin: all five values are restored and applied.
7. Fuzz: from MCP, fire `UpdateSettings` with `"x"`, `{ musicVolume = 9, language = "xx", bogus = 1 }`,
   no arguments and two arguments: the server stays up, `musicVolume` becomes 1, language is unchanged,
   console has no new errors.

## 6. Phone-resolution captures (gate 2)

Capture the list in [ui.md](contracts/ui.md) "Capture checklist" at 640×360, 844×390 and 1280×720 with the
Studio MCP `screen_capture`; store them under `specs/003-saving-and-economy/captures/`. Pass when nothing
overlaps, nothing is clipped, the timer is visible and all text is ≥ 18 px.

## 7. Human-only checks (private test place, not Studio)

These need a published private test build and cannot be done by an agent in Studio:

- **Persistence across real servers:** play a run, leave, join a fresh server, confirm coins, best size and
  book (SC-001).
- **Session lock:** join the same account from two servers; the first server's player is kicked with
  `error.session_ended` and neither profile is corrupted (SC-002). Confirm the private test place is a
  separate experience from the live place first (plan, Open Item 1).
- **Phone feel:** TopBar reachable with one thumb, 64 px buttons comfortable (plan, Open Item 2), settings
  sliders usable on a real phone, and the camera sensitivity effect on touch.

Record results in `specs/003-saving-and-economy/playtest.md` (date, commit, participants by age group,
findings, owner sign-off) per Constitution I.

## Done when

`scripts/check.sh` exits 0; both Jest suites pass on the mock store; sections 3 to 6 pass with a clean
console; captures stored; section 7 recorded; `tasks.md` ticked (SC-001 to SC-005).
