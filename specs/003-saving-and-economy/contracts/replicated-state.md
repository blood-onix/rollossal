# Contract: Server state and what the client reads

No new `Player` attributes and no new instances. The server publishes the profile only through the
`ProfileSync` event ([remotes.md](remotes.md)). Everything the client holds is derived and read-only
(Constitution II).

## Server-side API (`src/server/DataService.luau`)

```lua
DataService.start(): ()                                            -- no-op when Config.Flags.Saving is false
DataService.load(userId: number, player: Player?): boolean         -- yields; false = no profile (caller kicks)
DataService.release(userId: number): ()                            -- EndSession + forget; safe twice
DataService.shutdown(): ()                                         -- sets shuttingDown, releases every profile
DataService.hasProfile(userId: number): boolean                    -- true only while the session is active
DataService.getBook(userId: number): { [string]: boolean }?        -- a copy; nil without a profile
DataService.getBestSize(userId: number, worldId: string): number?  -- nil without a profile or an entry
DataService.getCoins(userId: number): number?
DataService.applyRunResult(userId: number, result: RunResult): Profile.Outcome?   -- nil = no active profile
DataService.updateSettings(userId: number, candidate: unknown): boolean           -- false = no active profile
DataService.snapshot(userId: number): ProfileSnapshot?
-- test seams
DataService.setStore(store: any): ()                               -- inject a ProfileStore (mock) before load
DataService.setKick(fn: ((player: Player, message: string) -> ())?): ()
DataService.setSync(fn: ((userId: number, snapshot: ProfileSnapshot) -> ())?): ()
```

`load` is what `Players.PlayerAdded` calls (inside `task.spawn`). It implements the state machine in
[data-model.md](../data-model.md) §8 and returns `true` once the profile is `Active` and `ProfileSync` has
been sent. `getBook` and `snapshot` return copies, so a caller can never mutate saved data by accident.
`applyRunResult` checks `profile:IsActive()` first, runs `Profile.applyRunResult` with the world's reward
lookup, fires `ProfileSync`, and returns the outcome; it never yields.

`DataService` requires `RunManager`'s `RunResult` type only as a type (a structural table), not the module,
so `RunManager → DataService` is the only dependency edge.

## What each client module reads

| Module | Reads | From |
| --- | --- | --- |
| `ProfileClient` | the snapshot; exposes `coins()`, `bestSize(worldId)`, `book()`, `skinsOwned()`, `settings()`, `isLoaded()` and a `changed` signal | `ProfileSync` |
| `TopBar` | `RunClient.state()`, `RunClient.endsAt()`, `Config.runDurationSeconds`, `Config.runStartUiLockSeconds` | existing 002 state |
| `BookUi` | `Book.pages(Worlds.sizeTiers, Worlds.active.objects, ProfileClient.book(), ProfileClient.skinsOwned())` | snapshot + content |
| `SettingsUi` | `ProfileClient.settings()` for initial values; writes through `ProfileClient.sendSettings` | snapshot |
| `HubUi` | `ProfileClient.coins()`, `ProfileClient.bestSize(Worlds.active.worldId)` | snapshot |
| `ResultsUi` | the `RunResult` fields (`coins`, `coinsTotal`, `bestSelfSize`, `newBookIds`, `isFirstRun`) | `RunResult` event |
| `Feedback` | `settings().musicVolume`, `effectsVolume`, `reduceMotion` | snapshot |
| `CameraController` | `settings().cameraSensitivity` | snapshot |
| `Localizer` | `settings().language` through `ProfileClient` | snapshot |

`ProfileClient` is the single reader of `ProfileSync`. On `changed` it applies the settings to
`Feedback`, `CameraController` and `Localizer` (through each module's own setter), so no other module
subscribes to the remote.

## Client defaults before the first snapshot

`ProfileClient` starts with `isLoaded() == false`, `coins() == 0`, empty tables and the `Config.Settings`
defaults. Screens that need data (Book, Hub rows) show the defaults without error; Book and Settings may
open before the snapshot arrives and refresh when `changed` fires. Nothing waits on the snapshot.

## Client-local state (not replicated)

The `ReduceMotion` Player attribute is set by `Feedback` on the client only (as in 002): it is
`settings().reduceMotion or GuiService.ReducedMotionEnabled`. It is never read by the server.
