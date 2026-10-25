# 002 Run Loop

> **DRAFT. Not ready to open.** All agent-run Studio checks are done (T027 to T029, T037 to T040, T052): Jest 43 of 43, quickstart 1 to 12, captures, console. They found four game defects and one test defect, all fixed. Still open: the human playtest with owner sign-off (T051). Lines marked **PENDING** wait on it. Untick `ServerScriptService.LoadStringEnabled` in the place before any publish (it was enabled only to run Jest).

## Summary

Every player starts a personal 4-minute run on join. The server ends it at the bell and publishes one result (final size, stars, coins, new book entries, best sizes). The results screen offers **Roll again** and **Back to hub**. The HUD shows the timer, three star targets, a live size meter with the next tier, a pickup pop and a tier-unlock banner. Pickups and knock-offs give sound, haptic and camera-shake feedback. All of it sits behind `Config.Flags.RunLoop`; with the flag off the game behaves as in 001.

- Pure rules with hand-computed Lune tests: `Stars`, `Tiers`, `Coins`, `RunClock`.
- World data (tiers, objects, star targets, hub) in `GreyBoxRoom.luau`, read only through `Worlds.luau`.
- All player-facing text is `Localizer.t(key)` over `Strings.luau`; a Lune guard rejects English literals in `Text` assignments.
- Server authority: the only client intents are `RollAgain` and `BackToHub`, with zero arguments.

## Quality Gates

| Gate | Status | How it was met |
| --- | --- | --- |
| 1. `scripts/check.sh` exits 0 | **Met** | StyLua, Selene, luau-lsp strict, 93 Lune tests, Rules purity guard all pass (re-run after the Studio fixes). |
| 2. Studio playtest, console read, phone captures | **Partial** | Agent playtest through the Studio MCP done: Jest 43 of 43, quickstart 1 to 12, console clean of game errors and warnings, captures at 640×360, 844×390, 1280×720 (see "Studio evidence"). **PENDING**: the human playtest on a real phone (T051). |
| 3. Assets within budget and in `Assets.luau` | **Met** | No imported assets. Four engine-bundled placeholder sounds (`rbxasset://sounds/...`), recorded only in `src/shared/Assets.luau` (T053); all four load and play in Play mode (T038). |
| 4. New strings in the localisation tables | **Met** | Every new string is a key in `src/shared/Localization/Strings.luau`. `Strings.test.luau` and `LiteralGuard.test.luau` enforce it. |
| 5. Tasks ticked in `tasks.md` | **Partial** | All code and agent-runnable Studio tasks are ticked with results. Open: T051 (people) and T054 (this file, final once T051 lands). |

### Studio evidence (gate 2)

Run on 2026-10-25 in Studio 0.744 through the Studio MCP server, with the place synced by Rojo (byte-for-byte check of all 40 scripts). Runs ended in real time; the ball was driven by a client-side autopilot and the buttons by real mouse clicks. Phone sizes were emulated by cloning each screen into frames of exact size (UI scale is 1 at all three); real-phone captures come with T051.

| Task | What it proves | Result |
| --- | --- | --- |
| T027 | Jest runner; R3 anchor/unanchor | **Pass**. Jest 43 of 43 (`AbsorbService.spec` 19, `RunManager.spec` 24), run with `LoadStringEnabled` on because this Studio build disables `debug.loadmodule`. R3: anchored after the bell; unanchored and driven by real input after Roll again and Back to hub. |
| T028 | Quickstart 1, 6 to 12 | **Pass** after one fix (star row printed `1.00 star`). New run 0.67 s after Roll again; ids `…-1` to `…-4` distinct; fall keeps size, 27-entry stack, id and end time; hub rejects absorbs; stop mid-run is clean. |
| T029 | Results and hub at 640×360, 844×390, 1280×720 | **Pass**. Results: buttons 250×96, smallest text 20 px, no overlap or clipping. Hub: Play 260×96, text 28 px. |
| T037 | New US2 Jest cases | **Pass** after fixing the test's setup (it bumped a cube that is absorbable at that size). Also checked in play under T039. |
| T038 | Sounds, glyphs, reduced motion | **Pass** after fixes: sounds preloaded (first tier sound was still loading); `retry` `↻` has no glyph in either font, now `🔁`; `GuiService.ReducedMotionEnabled` exists and now drives `ReduceMotion`. |
| T039 | Quickstart 2 to 5 | **Pass**. One banner per tier, none after knock-off and regrow; 262 pickups sum to 463 coins and the result shows 463 after 6 knock-offs. |
| T040 | HUD with pop and banner at three sizes | **Pass** after a fix: the banner overlapped the star row and cut `CUBES!`; now 480×48 at top y 120, pop at y 176. No overlap with meter, stars, thumb or Jump zones; text ≥ 18 px. |
| T052 | SC-006 console | **Pass**: no game errors or warnings over scenarios 1 to 11 in one session; only Studio's own `ContentId … failed` lines, none referenced by the game. |

Captures: `specs/002-run-loop/captures/`.

### Defects found by the Studio checks (all fixed)

1. `Localizer.t` passed numbers to `Translator:FormatByKey`, which prints them with two decimals (`1.00 star: 3.0`, and likewise for coins and counts). Numbers are now passed as plain text.
2. The first tier-unlock sound could be silent: sounds were created on first use and still loading. `Feedback` preloads `Assets.sounds`.
3. The tier banner wrapped and covered the star row on phone sizes. Moved below the size meter and widened (contracts/ui.md updated).
4. The `↻` retry glyph does not exist in FredokaOne or GothamMedium. Replaced with `🔁` (content contract updated).
5. Test only: the "no second TierUnlocked after a knock-off" case bumped a Tier-2 cube at D 2.385, which is absorbable there, so it never knocked off. It now bumps a Tier-3 cube.

## Constitution check (v1.0.0)

| Principle | Outcome |
| --- | --- |
| I. Fun proven in grey box | **Open.** Playtest template is at `playtest.md`. T051 (3+ adults, 3+ children aged 10 to 12, a real phone, two-account friend test, owner sign-off) is not done. No art, monetization or live-ops work may start until the owner signs off. |
| II. Server authority | Pass by design and in play (absorb from the hub rejected, one result per run, coins unchanged by knock-offs). `RunManager.spec` (24 cases, all passing) covers early end, spoofed arguments, absorb after the bell and single publication. |
| III. Pure, tested rules | Pass. `Stars`, `Tiers`, `Coins`, `RunClock` are standalone, purity-guarded, with hand-computed tests. |
| IV. Safe for everyone | Pass. Nothing changes the maturity answers. |
| V. Ethical monetization | Pass. No offers, prices or timers on the results screen; `friendBoost` and `doubleCoins` are fixed at `0`/`false`. |
| VI. Mobile first | Pass at emulated phone sizes (T029, T040): text ≥ 18 px, buttons ≥ 96 px, no overlap with touch controls. Real-phone check in T051. |
| VII. Content is data | Pass. World data lives in `GreyBoxRoom.luau`; a second world is data plus one line in `Worlds.luau`. |
| VIII. Player data | N/A. Session-only tables. |
| IX. Localised strings | Pass, enforced by Lune tests. English only; Spanish is Feature 007. |
| X. Multi-agent discipline | Pass. Own branch, no place files or secrets. |
| XI. Asset pipeline | Pass. See gate 3. |
| XII. Keep it lean | Pass. No new tool or package. |

Human Approval Required items: none triggered (no publish, DataStore, prices, maturity change, new tools or spending).

## Findings carried from the plan

- **F-1** Star targets: the grey-box room overrides the production `{ 20, 45, 80 }` with `{ 3.0, 4.0, 5.0 }`. Provisional until the playtest.
- **F-2** `rollAgainDelaySeconds = 3` is an upper bound asserted by tests; Roll again restarts at once.
- **F-3** Phone haptics may be unavailable; `Feedback` never errors. Real-device result goes in `playtest.md`.
- Reduced motion: the engine exposes `GuiService.ReducedMotionEnabled`; `ReduceMotion` follows it (R11).
- **F-4** Crowded servers starve the room, so stars are a solo or small-group measure here. Pooling comes with Feature 004.

## Not in this PR

No save data (Feature 003), no purchases, no Spanish strings (Feature 007), no second world (Feature 004).
