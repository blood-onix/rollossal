# Contract: Remotes (run loop)

Adds to the three 001 events in [`../../001-grey-box-prototype/contracts/remotes.md`](../../001-grey-box-prototype/contracts/remotes.md).
All are `RemoteEvent`s in `ReplicatedStorage.Remotes`, created by `src/server/Remotes.luau` before any player
joins. Constitution II: the client sends intents with no data; the server sends facts.

## Client to server (2)

Both handlers take `...: unknown`, so extra or wrong arguments can be detected.

| Event | Arguments | Accepted when | Effect |
| --- | --- | --- | --- |
| `RollAgain` | none | run state is `Ended` or `Hub` | `resetBall`, `zone = Room`, start a new run (new `runId`, `endsAt = now + 240`), state `Active` |
| `BackToHub` | none | run state is `Ended` | `resetBall`, `zone = Hub`, unfreeze, state `Hub`, no timer |

Validation order (first failure ends the request; nothing is mutated before all pass):

| # | Check | Reject code (internal, never sent) |
| --- | --- | --- |
| 1 | `select("#", ...) == 0` (any argument at all is rejected) | `BadArgument` |
| 2 | the player has a run record (`Flags.RunLoop` on, player in the server) | `NoRun` |
| 3 | state is in the "accepted when" column | `WrongState` |
| 4 | the server is not shutting down | `ShuttingDown` |

State is its own rate limit: a second `RollAgain` finds the state already `Active` and is `WrongState`.
Reject codes are for tests; they are never sent to the client and never `warn`.

There is no remote to end a run, report a size, a star count, coins, or a result. A client that wants to cheat
has nothing to send (FR-013).

## Server to client (4), `FireClient` to the owning player only

| Event | Payload | When |
| --- | --- | --- |
| `PickupConfirmed` | `objectId: string` (an `ObjectDef.id`, e.g. `"cube_t2"`) | after every validated absorb in an `Active` run |
| `TierUnlocked` | `tier: number` (2..N) | once per tier per run, when the new diameter reaches `minDiameter` of a tier not in `unlockedTiers` |
| `KnockedOff` | none | after a validated knock-off that popped at least one entry (an empty-stack bump does nothing, as in 001) |
| `RunResult` | `{ runId: string, worldId: string, finalDiameter: number, stars: number, coins: number, newBookIds: { string }, bestSelfSize: number, bestFriendSize: number? }` | exactly once per `runId`, when the run ends |

The client treats payloads as untrusted shape: it checks `typeof` of each field before use and ignores a
malformed payload (never throws). `RunResult` is not stored by the client; the results screen shows it until
the player acts.

`RunResult` is sent once. If the client script was not yet listening (not possible at 240 s after join in
normal play), the player sees no results screen for that run; the `RunState` attribute still reads `Ended`
and the HUD offers **Roll again**. (R5)

## Not remotes

Run state and the timer end are attributes on the `Player` ([replicated-state.md](replicated-state.md)).
