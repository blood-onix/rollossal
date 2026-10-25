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