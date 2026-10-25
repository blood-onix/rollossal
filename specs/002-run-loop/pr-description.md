# 002 Run Loop

> **DRAFT. Not ready to open.** Gate 2 (Studio playtest) evidence is missing: tasks T027 to T029, T037 to T040 and T052 have not run, and the playtest T051 needs people. Every line marked **PENDING** below must be filled with real results before this goes up.

## Summary

Every player starts a personal 4-minute run on join. The server ends it at the bell and publishes one result (final size, stars, coins, new book entries, best sizes). The results screen offers **Roll again** and **Back to hub**. The HUD shows the timer, three star targets, a live size meter with the next tier, a pickup pop and a tier-unlock banner. Pickups and knock-offs give sound, haptic and camera-shake feedback. All of it sits behind `Config.Flags.RunLoop`; with the flag off the game behaves as in 001.

- Pure rules with hand-computed Lune tests: `Stars`, `Tiers`, `Coins`, `RunClock`.
- World data (tiers, objects, star targets, hub) in `GreyBoxRoom.luau`, read only through `Worlds.luau`.
- All player-facing text is `Localizer.t(key)` over `Strings.luau`; a Lune guard rejects English literals in `Text` assignments.
- Server authority: the only client intents are `RollAgain` and `BackToHub`, with zero arguments.

## Quality Gates

| Gate | Status | How it was met |
| --- | --- | --- |
| 1. `scripts/check.sh` exits 0 | **Met** | StyLua, Selene, luau-lsp strict, 93 Lune tests, Rules purity guard all pass (re-run at the time of this draft). |
| 2. Studio playtest, console read, phone captures | **PENDING** | Not run. The Rojo plugin in Studio was disconnected (`WebSocket error: 400`), so the place holds none of the 002 code. See "Studio evidence" below. |
| 3. Assets within budget and in `Assets.luau` | **Met** | No imported assets. Four engine-bundled placeholder sounds (`rbxasset://sounds/...`), recorded only in `src/shared/Assets.luau` (T053). Whether each one plays is part of T038, **PENDING**. |
| 4. New strings in the localisation tables | **Met** | Every new string is a key in `src/shared/Localization/Strings.luau`. `Strings.test.luau` and `LiteralGuard.test.luau` enforce it. |
| 5. Tasks ticked in `tasks.md` | **Partial** | All code tasks are ticked. T027 to T029, T037 to T040, T051, T052 and T054 are open. |

### Studio evidence (gate 2): PENDING

| Task | What it proves | Result |
| --- | --- | --- |
| T027 | Jest runner passes (`RunManager.spec` plus 001 suites); R3 anchor/unanchor after the bell, Roll again, Back to hub | PENDING |
| T028 | Quickstart 1, 6 to 12, console clean | PENDING |
| T029 | Results and hub captures at 640×360, 844×390, 1280×720; text ≥ 18 px, results buttons ≥ 96 px | PENDING (sizes: ___) |
| T037 | New US2 Jest cases pass | PENDING |
| T038 | Each `Assets.sounds` path plays, each `Icons` glyph renders, reduced-motion setting noted | PENDING |
| T039 | Quickstart 2 to 5, console clean | PENDING |
| T040 | HUD with pickup pop and tier banner at the three resolutions; no overlap | PENDING (sizes: ___) |
| T052 | SC-006: quickstart 1 to 11 in one session, zero errors and warnings | PENDING |

## Constitution check (v1.0.0)

| Principle | Outcome |
| --- | --- |
| I. Fun proven in grey box | **Open.** Playtest template is at `playtest.md`. T051 (3+ adults, 3+ children aged 10 to 12, a real phone, two-account friend test, owner sign-off) is not done. No art, monetization or live-ops work may start until the owner signs off. |
| II. Server authority | Pass by design. The server starts, ends and scores runs; absorb and bump are rejected from `now >= endsAt`; `RunManager.spec` covers early end, spoofed arguments, absorb after the bell and single publication. Jest results are PENDING (T027, T037). |
| III. Pure, tested rules | Pass. `Stars`, `Tiers`, `Coins`, `RunClock` are standalone, purity-guarded, with hand-computed tests. |
| IV. Safe for everyone | Pass. Nothing changes the maturity answers. |
| V. Ethical monetization | Pass. No offers, prices or timers on the results screen; `friendBoost` and `doubleCoins` are fixed at `0`/`false`. |
| VI. Mobile first | Pass in code (18 px minimum text, 96 px buttons, glyph plus label). Phone captures are PENDING (T029, T040). |
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
- **F-4** Crowded servers starve the room, so stars are a solo or small-group measure here. Pooling comes with Feature 004.

## Not in this PR

No save data (Feature 003), no purchases, no Spanish strings (Feature 007), no second world (Feature 004).
