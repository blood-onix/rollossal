# Playtest Notes: 003-saving-and-economy

## Audit (T046)

- Client-to-server remotes added: `RequestProfile` (no arguments) and `UpdateSettings` (preferences only). Verified via grep of `src/client`.
- No client code path sends coins, sizes, book entries, rewards or results.
- Writers of `coins`, `bestSize`, `book`, `skinsOwned`: only `Profile.applyRunResult` (called from `DataService.applyRunResult`) and `Profile.reconcile` (defaults). Verified.
- `receipts` and `worldsUnlocked` untouched apart from defaults.
- No username or display name stored; log lines print only numeric `UserId` (`warn(userId)` in DataService).
- No price, offer or purchase prompt in new UI.
- `scripts/check.sh` exits 0; `scripts/test-guard.sh` passes; Rules purity guard passes on `src/shared/Rules`.

## Studio (pending Rojo Connect)

Studio MCP reports Rojo plugin not connected (files missing in Edit datamodel). Owner must press Connect in the Rojo plugin; then re-run `scripts/studio-sync-probe.sh` via `execute_luau`. Studio tasks T027, T031, T035, T040, T044, T045 remain unchecked until sync succeeds.

## Human checks (T048)

Pending private test place and participants.
## Studio convergence round (2026-10-25)

- Rojo sync probe: mismatches = {} (only JitterProbe byte-count typo in probe; file is 5534 bytes). Studio in sync.
- `scripts/check.sh`: exit 0 (193 Lune tests pass, purity guard green).
- Jest runner (Server datamodel): DataService.spec 14/14, RunManager.spec 26/26, AbsorbService.spec 19/19 — 0 failures.
- Console (Play session): only Studio artifacts (`DataStoreService: StudioAccessToApisNotAllowed`, `[profilestore] Roblox API services unavailable`, `ContentId rbxassetid://203785492`); no game-script errors or warnings.
- UpdateSettings fuzz (T040): fired "x", {musicVolume=9, language="xx", bogus=1}, no-arg and two-arg from client; server stayed up; musicVolume clamped to 1, language unchanged (auto), unknown key ignored; no console errors. Verified via DataService.snapshot.
- Profile load: manual DataService.load succeeds on mock store; snapshot returns v1 defaults (coins 0, empty book/bestSize, default settings).
- Limitation: this model cannot receive screen_capture images, so visual capture verification (T031, T044, T045) is deferred to a human/image-capable pass. Code-level verification for those is covered by the Lune/Jest suites and the contracts.
