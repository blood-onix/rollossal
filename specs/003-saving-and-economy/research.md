# Research: Saving and Economy

Phase 0 decisions. Each has Decision, Rationale and Alternatives. No `NEEDS CLARIFICATION` remains; the two
owner confirmations are in plan.md "Open Items". Code facts come from the 002 branch (`002-run-loop`,
commit `11b1302`) and from the installed ProfileStore 1.0.3 docs (`ServerPackages/_Index/.../docs/api.md`).

## R1. ProfileStore usage and the mock store

**Decision.** `DataService` creates the store once:

```lua
local store = ProfileStore.New(Config.dataStoreName)          -- "PlayerProfiles_v1", no template
if RunService:IsStudio() and Config.useMockDataStoreInStudio then
	store = store.Mock
end
```

A player's profile is `store:StartSessionAsync(Config.playerKeyPrefix .. userId, { Cancel = leftGame })`
where `leftGame` returns `player.Parent == nil`. After a successful start: `profile:AddUserId(userId)`
(erasure support), `Profile.prepare(profile.Data, defaults)` (R3, R11), `profile.OnSessionEnd` handler,
and the entry is stored in `profiles[userId]`. Release: `Players.PlayerRemoving` and a `game:BindToClose`
handler both call `profile:EndSession()`, which saves and releases and is a no-op on an ended session.
No `template` is given to `ProfileStore.New`: defaults, reconcile and migration are pure Rules so Lune can
test them (spec FR-003); a `nil` template leaves a new profile's `Data` as `{}`, which `prepare` fills.

**Facts checked in the 1.0.3 source.**

- `StartSessionAsync` returns `nil` when another server holds the session at the same moment, or when
  `START_SESSION_TIMEOUT` (120 s) passes without a session. Both end in a kick (R11).
- `OnSessionEnd` fires after our own `EndSession`, after a steal, and at server shutdown.
- ProfileStore registers its own `BindToClose` (sets `IsClosing`, ends sessions). Ours is additional and
  idempotent; it exists so `DataService` stops handing out profiles and `RunManager` stops applying.
- `ProfileStore.Mock` keeps a separate in-memory store; the same key through `store` and `store.Mock` are
  different profiles. Auto-save is 300 s; changes made while a session is active are saved with it.

**Rationale.** It is the package the constitution names; the mock switch is the documented way to avoid
live writes from Studio. **Alternatives.** Studio detection through a place-id list (rejected: fragile,
needs ids in Config); using `profile:Reconcile()` with a template (rejected: not testable in Lune and it
recurses into sets such as `book`).

## R2. Pure and impure split (finding F-8)

**Decision.** Three standalone Rules modules, none requiring another:

- `Profile.luau`: `defaults`, `reconcile`, `migrate`, `prepare`, `applyRunResult`.
- `Book.luau`: `newIds`, `pages`, `completedRewardIds`.
- `Settings.luau`: `validate`.

`Profile.applyRunResult(data, result, rewardsFor)` takes `rewardsFor: (book) -> { string }`. `DataService`
passes `function(book) return Book.completedRewardIds(Worlds.sizeTiers, Worlds.active.objects, book) end`.
Defaults and bounds are built from `Config` by `DataService` and passed in as tables; Lune tests pass
literal tables, so expected values never come from `Config`.

**Rationale.** `check.sh` forbids `require(script` under `src/shared/Rules`, and the module-per-concern layout
from 001 has no cross-requires. A function argument keeps `applyRunResult` testable with a fake reward
table. **Alternatives.** One big `Economy.luau` (rejected: mixes three concerns, 400+ lines, blocks
parallel tasks); relative `require("./Book")` (rejected: Lune accepts it but the guard and Roblox do not).

## R3. Idempotency and the ledger (finding F-2)

**Decision.** `Profile.applyRunResult` rejects a `runId` found in `data.appliedRuns` and otherwise records
it. `Profile.prepare` sets `data.appliedRuns = {}` on every load. Evidence: `RunManager.startRun` builds
`runId = "{userId}-{runSeq}"` with `runSeq` a module upvalue, so ids restart per server; a session lock
means one server per player at a time, so every id that can ever repeat in a session is new to that
session. The 002 `resultPublished` flag is a second guard for the same run.

**Rationale.** Persisting the ledger would reject real runs after a server restart. Clearing at load keeps
the approved key and type and bounds the table by construction. **Alternatives.** Add a per-server nonce
to `runId` in 002 (rejected for now: a cross-feature change, unnecessary once the ledger is per session);
bounded FIFO list (rejected: the approved type is a map, and an ordered list needs a second key, which
needs owner approval).

**Late result after the session ended.** `DataService.applyRunResult` returns `nil` when `profile:IsActive()`
is false (profile released, stolen or never loaded), mutating nothing.

## R4. First run (finding F-3)

**Decision.** `isFirstRun = next(data.bestSize) == nil` evaluated inside `applyRunResult` before the
write. Each applied run sets `bestSize[worldId] = max(old or 0, finalDiameter)` with `finalDiameter ≥ 2`
(`Config.startDiameter`), so the table is empty exactly until the first applied run. The value is returned
in the outcome, merged into `RunResult.isFirstRun` and drives `ui.results.first_run_tip`.

**Rationale.** No schema key is added (key changes need owner approval). **Alternatives.** A
`runsCompleted` counter in the profile (rejected: schema change); a client-side "seen tip" flag (rejected:
repeats on a new device).

**Edge.** A player whose first run ends while the profile is unavailable never sees the tip; the next
applied run is then their "first". Acceptable: the tip is advice, not progress.

## R5. Replication to the client

**Decision.** One server-to-client `RemoteEvent` `ProfileSync(snapshot)` and one zero-argument
client-to-server `RequestProfile()`. The snapshot is built by `DataService.snapshot(userId)` and contains
`coins`, `bestSize`, `book`, `skinsOwned`, `equipped`, `settings` (plain tables, no `Instance`). Sent when a
profile finishes loading, inside every apply and settings change, and in reply to `RequestProfile`.
`ProfileClient` connects `ProfileSync` first, then fires `RequestProfile`, which closes the join race
(a push that arrives before the connection is simply requested again).

**Rationale.** Sets and maps do not fit `Player` attributes; one snapshot keeps all UI consistent.
002 already uses remotes for one-shot events. **Alternatives.** Attributes per field (rejected: sets);
`RemoteFunction` for the snapshot (rejected: yields on the server, can hang); `ValueObject` folders under
the player (rejected: more instances, partial updates visible).

**Size.** Greybox: under 500 bytes. Snow Village (60 entries in `book`, a few `skinsOwned`): under 3 KB.

## R6. RunManager integration and fallback

**Decision.** Edit `RunManager` only at three seams:

1. `buildResult`: `seen = DataService.getBook(userId) or seenBookIds[userId] or {}` and
   `best = DataService.getBestSize(userId, run.worldId) or bestSelfSize[userId] or 0`.
2. `endRun`: after `buildResult`, `local outcome = DataService.applyRunResult(userId, result)`; if non-nil,
   set `result.coinsTotal = outcome.coinsTotal` and `result.isFirstRun = outcome.isFirstRun`;
   `result.bestSelfSize` is already the persistent best. Then the existing publisher call.
3. `bestFriendSize`: prefer `DataService.getBestSize(otherId, worldId)` over the in-memory map.

The in-memory maps stay as the fallback for users with no profile (flag off, Jest tests with fake ids).
`RunResult` gains `coinsTotal: number?` and `isFirstRun: boolean` (false when no profile).

**Rationale.** Smallest change that keeps 002 behaviour and tests intact; the flag-off path is exactly 002.
**Alternatives.** Making `RunManager` require a profile to start a run (rejected: delays the first run,
breaks Constitution VI); moving result building into `DataService` (rejected: mixes run and data concerns).

## R7. Settings: validation, application and the camera

**Server.** `UpdateSettings(payload: unknown)`: the handler takes `...unknown`, requires exactly one
argument, rate-limits with `RateLimit.allow` (limit `Config.settingsRateLimit`), then
`profile.Data.settings = Settings.validate(current, payload, bounds)` and `ProfileSync`. A non-table, NaN,
infinite, wrong-type, unknown-key or unsupported-language field is ignored; numbers clamp to bounds.
Fields are independent: one bad field never blocks the others.

**Client application points.**

| Setting | Applied by | How |
| --- | --- | --- |
| `musicVolume` | `Feedback` | `SoundGroup "Music"` in `SoundService`, `Volume = value`; no music asset exists yet (Feature 007), the group is ready |
| `effectsVolume` | `Feedback` | `SoundGroup "Effects"`; every sound created by `play` sets `SoundGroup` |
| `cameraSensitivity` | `CameraController` | spike result (Risk Results): `UserInputService.MouseDeltaSensitivity = value`; if the touch pan cannot be scaled, the effect is PC-only and documented |
| `reduceMotion` | `Feedback.followReducedMotion` | `ReduceMotion` attribute = `setting or GuiService.ReducedMotionEnabled`; `Hud` and `CameraController` already read the attribute, so no change there |
| `language` | `Localizer.setLanguage` | R8 |

**Debounce.** `ProfileClient.sendSettings(candidate)` waits 0.3 s after the last change and flushes on panel
close and on `PlayerRemoving`-safe close. A slider drag therefore costs 1 to 3 remotes.

**Rationale.** Settings are preferences, not progress, so a typed, clamped client payload is allowed by
Constitution II; the server never trusts range or type. **Alternatives.** Send every slider tick (rejected:
rate limit trips and the last value can be dropped); a custom follow-camera for touch sensitivity
(rejected: out of scope, 001 chose the default camera, R5 of 001).

## R8. Language and Spanish strings (finding F-6)

**Decision.** `Strings.luau` entries become `{ en: string, es: string? }`. `Localizer`:

- registers `es-es` in the `LocalizationTable` when `es` exists;
- `Localizer.t(key, args?, localeId?)`: locale order is `localeId` argument, then the override, then
  `LocalizationService.RobloxLocaleId`, then `en-us`; a key with no text in the chosen locale falls back to
  `en-us`, never errors;
- `Localizer.setLanguage(code)` with `"auto" | "en-us" | "es-es"` (anything else is ignored) and a
  `Localizer.changed` signal (plain callback list, no Roblox `BindableEvent`, so it works before services).

The server kick uses `Localizer.t("error.profile_load_failed", nil, player.LocaleId)`. All new 003 strings
carry `es`; 002 strings keep `en` only until Feature 007, so Spanish mode shows a mix until then
(documented in quickstart).

**Rationale.** Constitution IX needs Spanish complete at launch; adding `es` now for new strings avoids debt
and makes the language setting testable. Spanish text is a draft for owner review in 007.
**Alternatives.** English-only until 007 (rejected: the language selector would have no visible effect);
Roblox auto-localisation (rejected: not under our control).

## R9. Book pages and rewards content

**Decision.** `SizeTierDef` gets `reward: RewardDef?` with `RewardDef = { rewardId: string, rewardType:
"skin" | "trail", nameKey: string }`. A page is one tier: its entries are `Worlds.active.objects` with that
`tier`, in listed order. Page complete = `totalCount > 0 and collectedCount == totalCount`. The grey-box
room has one object per tier, so each page is `0 / 1` or `1 / 1`; the four grey-box tiers get placeholder
rewards `greybox.reward.tier1` to `tier4` (`trail` for 1 and 2, `skin` for 3 and 4) so the grant path is
exercised. They are data strings in `skinsOwned`; no 3D asset exists (Feature 006). Snow Village (004)
will define its own rewards with no code change (Constitution VII).

**Rationale.** Matches spec FR-009 and the GDD ("completing a page gives a cosmetic reward"). **Alternatives.**
Rewards in a separate table keyed by tier (rejected: second place to keep in sync); no grey-box rewards
(rejected: nothing would exercise the grant in Studio).

## R10. UI layout and rules

**Decision.** Details and pixel numbers are in [contracts/ui.md](contracts/ui.md). Summary:

- **TopBar** (own module, visible in `Active`, `Ended`, `Hub`): top-right column, three buttons 150×64
  (icon plus 18 px label), 8 px apart, from y = 8 to 216, clear of the timer block (x 165 to 475) and of
  the reserved bottom 130 px (finding F-4).
- **Book lock.** `RunClock.uiLocked(now, endsAt, duration, lockSeconds)` is true in the first
  `Config.runStartUiLockSeconds` (5) of an `Active` run; `TopBar` ignores a Book tap then and the button
  shows the lock glyph with its label (state is carried by glyph and text, not colour). Settings is not
  locked: the player opens it deliberately, and it sits on the right clear of the first pickup path.
- **Panels** (Book, Settings): left of the TopBar column, x 8 to 472 at 640 wide, y 100 to 352, below the
  timer and star row, dim layer none. Close and Prev/Next controls are 64 px.
- **Shop.** F-5.

**Rationale.** One column keeps every existing 002 region free; utility controls at 64 px are above
Roblox's usual 44 to 48 px minimum. **Alternatives.** Icon-only buttons (rejected: spec requires icon plus
label); horizontal bar (rejected: collides with the timer at 640 wide).

## R11. Failure handling

**Decision.**

| Case | Behaviour |
| --- | --- |
| `StartSessionAsync` returns `nil` or errors | `kick(player, Localizer.t("error.profile_load_failed", nil, player.LocaleId))`, no profile stored, one `warn` |
| Player left during load | `Cancel` returns true; if a profile still arrives, `EndSession` at once |
| Stored `version` is greater than `SCHEMA_VERSION` (rolled-back server) | `Profile.prepare` returns `false, "FutureVersion"`; `EndSession` without changes, same kick, one `warn` |
| Stored `version` is not a number | treated as corrupt: same as above, `"BadVersion"` |
| `OnSessionEnd` while the player is present | `kick(player, Localizer.t("error.session_ended", ...))`, profile entry removed |
| `BindToClose` | `shuttingDown = true`; every profile `EndSession`; `applyRunResult` and `updateSettings` return nil/false |

Never create an in-memory fallback profile (spec edge case). `kick` is an injectable function so the Jest
test can capture the message instead of ending the test player.

## R12. Test strategy

- **Lune** (`tests/unit`, hand-computed values): `Profile` (defaults, reconcile keeps/repairs, migrate
  mechanism with a fake table plus v1 identity, prepare, apply: coins, best size, book set, rewards,
  duplicate, invalid, negative coins, monotonic best size, first run), `Book` (new ids, pages, rewards,
  empty page), `Settings` (clamp, type-check, unknown keys, NaN), `RunClock.uiLocked`, Config values,
  grey-box rewards (ids unique, keys exist), Strings (003 contract keys, `es` present on every 003 key,
  placeholder names match between `en` and `es`).
- **Jest-Lua** (`tests/studio/DataService.spec.luau`, mock store with unique test user ids from 900001
  so no real key is touched): new profile defaults; reconcile of a partial profile; apply grants and the
  `ProfileSync` payload; duplicate and late run id; session-ended apply; settings payload fuzz; load
  failure kick with localized message (store stub returning `nil`); `OnSessionEnd` kick;
  `BindToClose` path through `DataService.shutdown()`; `RunManager` result carries persistent fields.
- **Studio MCP playtest + captures** for UI and for join/leave persistence on the mock store (one Play
  session; the mock store survives `Players.PlayerRemoving` within a session, so "rejoin" is two loads in
  one server).
- **Human-only:** two real servers contending for one key, and persistence across real server restarts,
  need the private test place (quickstart, last section).

## R13. Feature flags (Constitution VII)

`Config.Flags.Saving = true` gates `DataService.start`, the `ProfileSync` listeners, `TopBar`, `BookUi`
and `SettingsUi`. With it off the game is exactly 002. `Config.Flags.Shop = false` keeps the Shop button a
notice (F-5).

## R14. Privacy

Stored: `UserId` (key and `AddUserId`) and progress only. Not stored: names, display names, chat, locale
(the `language` setting is the player's own choice of `auto`, `en-us` or `es-es`, a game preference).
Logs: warnings print the numeric `UserId` only.
