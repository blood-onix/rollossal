# PR Description: 003-saving-and-economy

## Summary

Implements persistent player profiles (ProfileStore-backed DataService), idempotent run saving, Collection Book screen, Settings screen, and economy HUD/Hub/Results integration.

## Quality Gates

- **Gate 1 — `scripts/check.sh`**: exits 0 (StyLua, Selene, Rojo sourcemap, luau-lsp strict, Lune unit tests, Rules purity guard). Verified 2026-10-25.
- **Gate 2 — Studio playtest with console read + phone captures**: pending Studio Rojo plugin connection (see blockers). Captures to be stored under `specs/003-saving-and-economy/captures/`.
- **Gate 3 — Assets**: N/A (no new assets).
- **Gate 4 — Strings**: every new string lives in `src/shared/Localization/Strings.luau` and resolves through `Localizer` (verified by Lune `Strings.test.luau`).
- **Gate 5 — tasks.md ticks**: all completed tasks ticked; remaining unchecked tasks listed below.

## Owner-approved DataStore (Constitution VIII, 2026-10-25)

- DataStore name: `"PlayerProfiles_v1"`
- Per-player key: `"Player_" .. tostring(userId)`
- Profile Schema v1 keys: `version`, `coins`, `worldsUnlocked`, `skinsOwned`, `equipped`, `book`, `bestSize`, `receipts`, `appliedRuns`, `settings` (with `musicVolume`, `effectsVolume`, `cameraSensitivity`, `reduceMotion`, `language`).

## Open owner items

1. Confirm the private test place is a separate experience from the live one (otherwise a `Config.dataStoreName` override for test builds is a key-name change needing owner approval).
2. Confirm the 64 px utility-button minimum on a real phone, sliders usable by touch, and the camera-sensitivity effect on touch (T035 risk row).

## Blockers / remaining tasks

- Studio MCP sync (Rojo plugin not connected): Studio tasks T027, T031, T035, T040, T044, T045 blocked pending the owner pressing Connect in the Rojo plugin. Non-Studio work (audit, pr-description) completed.
- Jest-Lua DataService spec (T022/T032/T041) and RunManager spec edits (T023) not yet written; flagged as remaining.
- Human checks T048 require a private test place and participants.

## Deviation from plan

None recorded yet; to be updated after Studio playtest.