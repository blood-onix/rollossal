# Playtest Notes: 003-saving-and-economy

## Audit (T046)

- Client-to-server remotes added: `RequestProfile` (no arguments) and `UpdateSettings` (preferences only). Verified via grep of `src/client`.
- No client code path sends coins, sizes, book entries, rewards or results.
- Writers of `coins`, `bestSize`, `book`, `skinsOwned`: only `Profile.applyRunResult` (called from `DataService.applyRunResult`) and `Profile.reconcile` (defaults). Verified.
- `receipts` and `worldsUnlocked` untouched apart from defaults.
- No username or display name stored; log lines print only numeric `UserId` (`warn(userId)` in DataService).
- No price, offer or purchase prompt in new UI.
- `scripts/check.sh` exits 0; `scripts/test-guard.sh` passes; Rules purity guard passes on `src/shared/Rules`.

## Studio (superseded)

The early "pending Rojo Connect" note no longer applies: the sync probe passes (49 files, no mismatches) and the 2026-10-26 round below ran in Studio.

## Human checks (T048)

Pending private test place and participants.
## Studio convergence round (2026-10-25)

- Rojo sync probe: mismatches = {} (only JitterProbe byte-count typo in probe; file is 5534 bytes). Studio in sync.
- `scripts/check.sh`: exit 0 (193 Lune tests pass, purity guard green).
- Jest runner (Server datamodel): DataService.spec 14/14, RunManager.spec 26/26, AbsorbService.spec 19/19 — 0 failures.
- Console (Play session): only Studio artifacts (`DataStoreService: StudioAccessToApisNotAllowed`, `[profilestore] Roblox API services unavailable`, `ContentId rbxassetid://203785492`); no game-script errors or warnings.
- UpdateSettings fuzz (T040): fired "x", {musicVolume=9, language="xx", bogus=1}, no-arg and two-arg from client; server stayed up; musicVolume clamped to 1, language unchanged (auto), unknown key ignored; no console errors. Verified via DataService.snapshot.
- Profile load: manual DataService.load succeeds on mock store; snapshot returns v1 defaults (coins 0, empty book/bestSize, default settings).
- Correction (2026-10-26): `screen_capture` does return images to this agent. The "image-model limitation" above was wrong, and the visual sub-checks it deferred were run in the round below. The earlier T040 tick had also rested on stub `SettingsUi` and `BookUi` code; see below.


## Studio convergence round 3 (2026-10-26)

Environment: Studio Play on the Rojo-synced place (sync probe: 49 files, 0 mismatches), ProfileStore mock store, viewport 1180×1090. Method for phone sizes (AGENTS.md): the live screens are cloned into a frame of the exact size (640×360, 844×390, 1280×720), measured, and captured with `screen_capture`. In those frames the UI scale is 1. The 1280×720 frame is shown at 0.921 because the Studio viewport is 1180 wide. Measurements per frame: every visible text's `TextSize` (≥ 18), `TextFits`, bounds inside the frame, overlap with the timer block (centre ± 155, y 0 to 100), TopBar clear of both bottom 130 px corners, and text-on-text overlaps outside the modal Book and Settings panels.

### Defects found and fixed in this round

The earlier ticks of T028, T036 and T040 were wrong: `SettingsUi` was a title and a close button only, and `BookUi` had no cards, reward line or tier name; both started open on screen. T028 and T036 were un-ticked, rebuilt to `contracts/ui.md`, and re-verified below.

- `SettingsUi`/`BookUi`: rebuilt (sliders, toggle, language buttons; cards, reward line, paging). Both start closed. Language buttons used the 28 px default and wrapped mid-word; now 18 px.
- `TopBar`: lock glyph stayed after 5 s (the delayed refresh fired a hair early on the local clock and never retried); now re-checks. Bar hidden when there is no run state; notice hidden on state change; run-start callbacks fire only on a new run; Shop notice moved clear of the Jump zone.
- `HubUi`: showed the raw keys `ui.hub.coins` and `ui.hub.best_size` (no placeholder arguments). Fixed, and `Strings.test` now fails any `Localizer.t("key")` call with no arguments for a key that has placeholders (proved by a temporary offending file).
- `ResultsUi`: no `Localizer.changed` handling (T029/T043); first-run tip did not fit its 28 px row; TopBar covered the right half of the 600×320 panel at 640×360. Now 464×320 centred left of the TopBar, tip 3 lines × 18 px, coins line may wrap (Spanish).
- `Hud.refreshText` was an empty stub (T037); now re-applies the static labels and rebuilds star targets and meter.
- Panels moved to y 112, height 240 (the 002 size meter's "Next:" label ends at y 112).
- Glyphs: `✕` and `✔` replaced by `❌` and `✅` (see plan.md Risk Results).
- Spanish: `first_run_tip`, `music_volume` and `camera_sensitivity` shortened so they fit at 18 px. Contract rows updated.

### Quickstart §5 (Settings), in Studio

- Sliders (real mouse drags): Music 80 → 0 → 100 %, Effects 80 → 0 → 100 %. Pickup sounds are created in the `Effects` group; group volume read on real pickups: 0 at 0 %, 1 at 100 %. The value shows at once; the server echo agrees.
- Reduce motion: with the ball idle and a server-fired `KnockedOff`, camera offset peak step 0.888 with the setting off and 0 with it on; the "■ Bump!" label showed in both cases.
- Camera sensitivity 200 %: `UserInputService.MouseDeltaSensitivity` = 2.0. The pan effect itself could not be measured (see plan.md Risk Results).
- Español: Settings, TopBar, Book (title, progress, reward line), Hub rows, Results coins line and first-run tip switch to Spanish; 002 strings (HUD labels, "Time's up!", "Ready to roll?", object and tier names) stay English. Auto restores English. All text fits at the three sizes.
- Fuzz (from the client, server echo read back): `"x"`, `{ musicVolume = 9, language = "xx", bogus = 1 }`, no arguments, two arguments, `NaN` and `math.huge` → `musicVolume` 1, language unchanged, `effectsVolume` unchanged, unknown key ignored, server up, console clean. The snapshot holds exactly `coins`, `bestSize`, `book`, `skinsOwned`, `equipped`, `settings`.
- Rejoin restore: **two halves, not a true rejoin.** Studio cannot re-add a player inside one Play session. (a) Server: `DataService.spec` (14/14) covers reload restoring values, `appliedRuns` empty after a second load, and saved non-default settings in the first snapshot. (b) Client: the server sent a first-snapshot-style payload with music 0.25, effects 0.5, camera 1.5, language es-es; the client applied all of it (sound groups 0.25 and 0.5, sensitivity 1.5, Spanish, controls moved and labelled 25 %, 50 %, 150 %). A real rejoin on separate servers is T048(a).

### Quickstart §3, §4 and TopBar

- Run 1 (driver skipped the tier 4 cube): final size 5.6, 3 stars, `Coins: 603 (total 603)`, "New in your book: 3" with the first-run tip. Run 2 (tier 1 cubes only): final size 2.2, `Coins: 8 (total 611)`, "No new book entries", no tip, `Your best size: 5.6`. Hub afterwards: `Coins: 611`, `Best size: 5.6`.
- Server snapshot after run 2 (read through `RequestProfile` → `ProfileSync`): `coins` 611, `bestSize.greybox` 5.645, `book` holds the three eaten entries, `skinsOwned` holds `greybox.reward.tier1`, `tier2`, `tier3` once each, still unchanged after run 2 re-ate the Tiny cube. The tier 4 page stayed 0 / 1 with the reward Locked.
- Book lock: 🔒 at 0, 2.2 and 4.8 s; ▤ at 6.2 s; a Book tap at about 1 to 2 s did not open it. After the lock the Book opens below the timer with the timer visible, opens in the Hub and from Results, closes at a new run; Settings stays open; one panel at a time.
- Shop notice: "After this run" in Active and "Shop opens soon" in the Hub, 2.0 s each, nothing opens.
- Jest runner (Server datamodel, mock store): AbsorbService 19, DataService 14, RunManager 26: 59 of 59 passed. The returned summary's top-level `success` field is `false` although every count is clean; not investigated.
- Console: no errors or warnings from game scripts. Present: Studio's `StudioAccessToApisNotAllowed` and `[profilestore] Roblox API services unavailable`, the `ContentId rbxassetid://203785492` artifact, my own probe error, the Jest runner's test-user speed violation (user 900021), and one ProfileStore trace `Code should not be running when globalEnv is uninitialised` printed while `DataService.spec` runs under Jest (tests still pass; worth a look, not blocking).

### Phone-size captures (T031, T044, T045, T051): measurements

All 33 frames (11 views × 3 sizes) end with: no text under 18 px, `TextFits` true everywhere, nothing outside the frame, nothing over the timer block, TopBar clear of both bottom corners, and no unexpected text overlaps. Exception: at 640×360 the transient 002 tier banner crosses the TopBar column. The Results panel (002) also sits over the timer block while Ended; the timer reads 00:00 there and is under the dim layer.

Views: HUD with TopBar (Active); Settings (en); Settings (es-es); Results first run; Book incomplete page (0 / 1 Large); Book complete page (1 / 1 Tiny); Book in Spanish; Hub; Book locked at 2.2 s; Book open in Active (timer visible); Results later run. Glyph check: see plan.md Risk Results.

**Blocker (resolved in round 6, second pass, below): the image files were not in `specs/003-saving-and-economy/captures/`.** `screen_capture` writes only to the harness tool-results folder and the shell policy blocked copying from outside the project. All 33 files are now in `captures/`.

### Convergence round 6 (2026-10-26)

- `scripts/check.sh`: all checks passed (194 Lune tests, purity guard green).
- The copy is still blocked: a plain single-file `cp` from the harness `tool-results/` folder into `captures/` was denied (Bash in don't-ask mode, command not on the allowlist). The source files exist (the `settings_640x360` source opens and shows the five controls at 18 px, Auto selected). Nothing was copied, so T031, T040, T044, T045, T051, T052 and T053 stay unticked. Run the commands at the end of `captures/README.md` once from the repo root, or add `cp` from that folder to the allowlist, and rerun.
- Observation from `settings_640x360`: the 002 stars label ("STARS:" row) shows a clipped "ES:" fragment to the right of the Settings close button. It sits behind the modal panel, so it is not an overlap of live controls, but a later pass could dim the HUD behind the panel.
- The §5 sub-checks were not redone this round: round 3 above ran them, and redoing them would only add files to the same blocked folder.

### Convergence round 6, second pass (2026-10-26): captures copied in, clean-session re-run

The copy restriction was lifted. All 33 captures were copied from the harness `tool-results/` folder into `captures/` (`cp -n`, nothing overwritten); `captures/README.md` is updated. `file` reports 33 valid JPEGs.

**Captures reviewed** (all 11 views at 640×360 opened and read; the 1280×720 Results first-run frame spot-checked). Against the pass criteria:

- Text: every visible text reads at 18 px or more, as measured in round 3 (`TextSize` is the source of truth, a 1:1 image only confirms nothing is cut). No text is cut by its own control.
- Timer block (centre ± 155 at 640 wide) is visible and clear in the HUD, Book-locked, Book-open-active, Settings and Settings-es captures. In Results and Hub it is not shown (Ended / Hub), as in round 3.
- TopBar: three 150×64 buttons top-right, clear of both bottom corners, Book shows 🔒 in `book-locked` and ▤ elsewhere; Spanish labels (`Libro`, `Tienda`, `Ajustes`) fit.
- BookUi: complete page `1 / 1 Tiny` with `Earned`, incomplete page `0 / 1 Large` with `Locked` and `???`, Prev/Next dimmed at the ends, Spanish page fits.
- SettingsUi: five controls, `Auto` selected with the check glyph; Spanish labels fit.
- Hub: `Coins: 603`, `Best size: 5.6`; Results first run: tip, `Coins: 603 (total 603)`, three new entries; Results later run: `Coins: 8 (total 611)`, `No new book entries`, `Your best size: 5.6`, no tip.
- Glyphs: ⚙ and 🛒 render as small grey emoji on the green TopBar buttons (the text label carries the meaning); ❓, 🔒, ❌, ✅, ◀, ▶, ▤ render. Matches plan.md Risk Results.

**Cosmetic findings in the captures (not failures of a pass criterion, recorded so they are not hidden):**

1. `book-complete`, `book-incomplete` and `book-es` were taken with the Book opened over the Ended Results panel. The Book panel (y 112) covers the lower part of the Results panel, so a clipped line of Results text ("Tiny cube", "3 of 3 stars") shows just above the Book header. The Book panel itself is clean (`book-open-active` shows it in a run with nothing behind it). A later pass could hide or dim Results while the Book is open from Results.
2. `settings_640x360`: an `ES:` fragment of a transient 002 HUD label shows between the Settings panel and the TopBar column (already noted in round 6, first pass). A later pass could dim the HUD behind a panel.
3. The transient 002 tier banner crossing the TopBar column at 640 wide is unchanged (plan.md Risk Results).

**Clean-session re-run (Studio Play, mock store, code unchanged since the round-3 evidence: no `src/` or `tests/` file is newer than that evidence):**

- `scripts/check.sh`: all checks passed (194 Lune tests, purity guard green).
- Rojo sync probe: 49 files, 0 mismatches. Jest runner (Edit datamodel, mock store): AbsorbService 19, DataService 14, RunManager 26, 59 of 59 passed, 0 failed suites. The summary's top-level `success` is still `false` with every count clean; not investigated.
- §3 on a fresh Play session with the client driver (AGENTS.md method): run 1 (all cubes): `Final size: 6.2`, 3 stars, `Coins: 760 (total 760)`, first-run tip shown, `New in your book: 4` (list capped at 3 lines on a first run). Profile read through `RequestProfile` → `ProfileSync`: `coins` 760, `bestSize.greybox` 6.227, `book` holds all four `greybox.cube_t1..t4`, `skinsOwned` holds `greybox.reward.tier1..tier4` once each, snapshot keys exactly `bestSize, book, coins, equipped, settings, skinsOwned`. Run 2 (smallest cubes only, via Roll again): `Final size: 3.7`, 1 of 3 stars, `Coins: 176 (total 936)` (760 + 176), `Your best size: 6.2`, `No new book entries`, no tip. Back to hub: Hub shows `Coins: 936` and `Best size: 6.2`; snapshot `coins` 936, `bestSize` 6.227, rewards still once each. TopBar shows Book, Shop, Settings with glyph and label in the Hub.
- §4 lock, three fresh sessions: `🔒 Book` at 0 to 4.75 s elapsed, `▤ Book` from 5.08 s (and a forced local run clock: locked at 0.07 s, unlocked at 4.03 s local = 5.03 s elapsed). The clock check at tap time is `RunClock.uiLocked`, so the tap is ignored while locked.
- **Observation, not reproduced:** in the first Play session after the Jest run, the Book button still showed `🔒` at 20 to 35 s elapsed while `RunClock.uiLocked` was false (the lock is evaluated at tap time, so a tap would have opened the Book; only the glyph was stale). Switching the local state Hub → Active refreshed it, and it did not recur in the next three sessions or in a forced run clock. Cause not found; `TopBar.luau` reschedules itself until the lock ends, and no console error accompanied it. If it shows up again, make the Book tap handler call `refreshText()` when it passes the lock check.
- Console in these sessions: only the Studio artifacts (`StudioAccessToApisNotAllowed`, `[profilestore] Roblox API services unavailable`, `ContentId rbxassetid://203785492`) plus **one** `[Rollossal] Displacement violation for user 7967226345: 386.7 > 224` from the 002 `BallService` anti-teleport check. It appeared during the two driven runs; Roll again from the Hub (160 studs), Back to hub and an idle run end did not raise it. Most likely the driver pushed the ball into a solid cube and the physics jumped for one frame; the server reverted the position as designed. `BallService.luau` is unchanged from 002. Not a player-facing error, but recorded because the quickstart expects a clean console.
- §5 on a fresh session, driven through the real `UpdateSettings` remote with the server echo read back through `ProfileSync` (not real slider drags; those were run in round 3): `{ music 0, effects 1, camera 2, reduceMotion true, language es-es }` echoed exactly and applied on the client: `Music` group volume 0, `Effects` group 1, `UserInputService.MouseDeltaSensitivity` 2.0, `ReduceMotion` attribute true, TopBar `▤ Libro`. Fuzz: `"x"`, no arguments and two arguments produced no change; `{ musicVolume = 9, language = "xx", bogus = 1 }` gave `musicVolume` 1.0 with the language kept and the unknown key ignored; `NaN` and `math.huge` were ignored; Auto with defaults restored `▤ Book`. Console in this session: Studio artifacts only, no game-script warning.
- Not re-run: real slider drags, the knock-off camera shake and a true rejoin (Studio cannot re-add a player in one Play session; server half is `DataService.spec`, client half was run in round 3; the real rejoin is T048(a)). The code is unchanged since round 3.
