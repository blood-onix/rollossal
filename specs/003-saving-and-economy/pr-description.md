# PR: 003-saving-and-economy

## Quality Gates

- Gate 1 (`scripts/check.sh`): passed (exit 0) on the final commit.
- Gate 2 (Studio playtest with console read + phone-resolution captures): Studio was in sync (49 files, no mismatches) and the Play checks and Jest runner (59/59) ran on 2026-10-26; the run found and fixed several UI defects (see `playtest.md`, round 3). 33 captures at 640×360, 844×390 and 1280×720 were taken and measured; the image files still have to be copied into `captures/` (see `captures/README.md`), so this gate is not fully met until then. Real-device checks stay in T048.
- Gate 3 (assets): N/A, no assets.
- Gate 4 (every new string in `Strings.luau`): all keys from `contracts/content-and-config.md` added with English and Spanish text.
- Gate 5 (`tasks.md` ticks): reconciled; Studio-only and human tasks left unchecked with blockers noted.

## Owner-approved (2026-10-25)

- DataStore name: `PlayerProfiles_v1`
- Key: `Player_<UserId>`
- v1 profile keys: version, coins, bestSize, book, skinsOwned, equipped, settings, worldsUnlocked, receipts, appliedRuns.

## Open owner items

1. Confirm the private test place is a separate experience from the live one (otherwise a `Config.dataStoreName` override for test builds needs owner approval).
2. Confirm 64 px utility-button minimum, slider usability by touch, and camera sensitivity effect on touch on a real phone.
