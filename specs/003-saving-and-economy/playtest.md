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

**Blocker: the image files are not in `specs/003-saving-and-economy/captures/`.** `screen_capture` writes only to the harness tool-results folder, and the shell policy blocks copying from outside the project. `captures/README.md` lists every capture with its source file. T031, T044, T045, T051 and T052 therefore stay unticked until the files are copied in.

### Convergence round 6 (2026-10-26)

- `scripts/check.sh`: all checks passed (194 Lune tests, purity guard green).
- The copy is still blocked: a plain single-file `cp` from the harness `tool-results/` folder into `captures/` was denied (Bash in don't-ask mode, command not on the allowlist). The source files exist (the `settings_640x360` source opens and shows the five controls at 18 px, Auto selected). Nothing was copied, so T031, T040, T044, T045, T051, T052 and T053 stay unticked. Run the commands at the end of `captures/README.md` once from the repo root, or add `cp` from that folder to the allowlist, and rerun.
- Observation from `settings_640x360`: the 002 stars label ("STARS:" row) shows a clipped "ES:" fragment to the right of the Settings close button. It sits behind the modal panel, so it is not an overlap of live controls, but a later pass could dim the HUD behind the panel.
- The §5 sub-checks were not redone this round: round 3 above ran them, and redoing them would only add files to the same blocked folder.
