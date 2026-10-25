# Contract: Replicated state (run loop)

Adds to [`../../001-grey-box-prototype/contracts/replicated-state.md`](../../001-grey-box-prototype/contracts/replicated-state.md).
Clients treat everything here as read-only truth.

## Player attributes (set by `RunManager`)

| Attribute | Type | Meaning |
| --- | --- | --- |
| `RunState` | `"Active"` \| `"Ended"` \| `"Hub"` | Absent when `Flags.RunLoop` is off or the player has no run. The client shows no run UI when absent |
| `RunId` | string | `<userId>-<n>`; changes on every new run; empty string outside `Active`/`Ended` |
| `RunEndsAt` | number | `Workspace:GetServerTimeNow()` at the bell, set when the run starts; `0` in `Hub` |

All three are written together in one step when the state changes, `RunState` last, so a client that sees the
new `RunState` also sees the matching `RunId` and `RunEndsAt`.

A client-set attribute `ReduceMotion` (boolean, default `false`) lives on the local `Player` and is never read
by the server.

## Instances

| Path | Created by | Notes |
| --- | --- | --- |
| `Workspace.Hub` | `WorldSpawner.start` | Folder with `Floor` (anchored, grey) and `StartPad` (anchored disc). Centre at `hub.center`, outside the room |

## Ball behaviour by state (server-enforced)

| State | `Ball.Anchored` | Absorb / Bump | Fall (`y < fallRespawnY`) | `RespawnBall` (Reset button) | Ball position on entry |
| --- | --- | --- | --- | --- | --- |
| `Active` | false | accepted while `now < endsAt` | `returnToSpawn`: size, stack, run kept | `returnToSpawn` (cooldown as 001) | room spawn slot, `Diameter = 2`, stack empty |
| `Ended` | true, velocity 0 | rejected | n/a (anchored) | rejected | stays where it ended |
| `Hub` | false | rejected | `returnToSpawn` to the hub spawn | 001 full reset at the hub spawn | hub spawn, `Diameter = 2`, stack empty |
| no run (flag off, or 001 tests) | false | accepted | `returnToSpawn` | 001 full reset | n/a |

`Diameter` and `Stuck` attributes on the ball behave as in 001. `resetBall` clears `Stuck` and sets
`Diameter = Config.startDiameter`; `BallService.publishStuck` runs after it.

When a ball is unanchored after `Ended`, the server calls `SetNetworkOwner(player)` again (R3). The speed and
displacement check skips frozen balls and restarts from the new `lastValidPosition` on release.

## Server checks added

- `RunManager.acceptsPickups(userId, now)`: `true` when the run is `Active` and `now < endsAt`, or when the
  player has no run record. Called first by `AbsorbService.tryAbsorb` and `tryBump`; a `false` returns
  `"RunEnded"` (new internal code, silent like the others).
- `RunManager.step(now)` runs after `BallService.step` each Heartbeat and ends every `Active` run with
  `now >= endsAt`.
- `PlayerRemoving`: the run record is deleted without a result; `FriendCache` rows removed.
- `game:BindToClose`: sets a shutting-down flag; `step` publishes nothing afterwards and intents are rejected.
