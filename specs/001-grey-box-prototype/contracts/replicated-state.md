# Contract: Replicated state (server → clients)

What the server publishes. Clients treat it as read-only truth.

## Instances

| Path | Created by | Notes |
| --- | --- | --- |
| `Workspace.GreyBoxRoom` | `WorldSpawner` | `Floor`, `Walls`, `Kerb` (static, anchored) and `Cubes` (30 parts) |
| `Workspace.GreyBoxRoom.Cubes.<id>` | `WorldSpawner` | Anchored `Part`, cube-shaped, grey by tier |
| `Workspace.Balls.Ball_<UserId>` | `BallService` | Ball `Part`, network owner is that player |
| `ReplicatedStorage.Remotes.{Absorb, Bump, RespawnBall}` | `Remotes` | See [remotes.md](remotes.md) |

## Attributes

**On each cube part** (static unless noted):

| Attribute | Type | Meaning |
| --- | --- | --- |
| `Size` | number | Edge length in studs. Informational for the client; the server uses its registry |
| `Tier` | number | 1 to 4 |
| `Taken` | boolean | Changes. `true` from pickup until the cube respawns (`respawnDelay`) or is knocked off, even if a ball still shows it. Clients hide and skip taken cubes |

When `Taken` is set, the server also sets `Transparency = 1`, `CanCollide = false`, `CanTouch = false`.
On respawn or scatter it clears `Taken`, restores `Transparency = 0` and `CanCollide = true`, and sets
the `CFrame`.

**On each ball part**:

| Attribute | Type | Meaning |
| --- | --- | --- |
| `Diameter` | number | The authoritative diameter. Read by `BallController` (speed, absorb check), `CameraController` (distance) and `StuckVisuals` |
| `Stuck` | string | Visible tail of the stack, oldest first, `;`-separated entries `key,dx,dy,dz` where `key` is `<cubeId>#<n>`, unique per pickup (local-space unit direction, 2 decimals). At most `Config.maxVisibleStuck` (30) entries. Empty string when none |

Example: `T1-04#12,0.12,0.97,-0.21;T1-09#13,-0.80,0.55,0.23;T1-04#41,0.66,-0.10,0.74` (T1-04 eaten
twice: it respawned in between).

The physical `Size` of the ball part follows `Diameter` with an ease of `Config.growTime`; visuals and
camera that need the on-screen radius read `part.Size.X / 2`.

## Client-side use of `Stuck`

`StuckVisuals` parses the string, compares the key list with the visuals it has for that ball, creates
missing visuals (size and shade from the `Size` and `Tier` attributes of the cube named by the part of the
key before `#`), and destroys visuals no longer listed. The 31st-object eviction and knock-offs both appear as entries leaving the list.
Malformed entries are skipped (never throw). On ball removal the ball's visuals are destroyed.

## Server checks (per Heartbeat, `BallService`)

For each active ball, with `dt` the Heartbeat step:

- `speed = horizontal speed of AssemblyLinearVelocity` (the vertical component is ignored so falling
  and hops do not trigger it). Violation `Speed` if `speed > Config.maxServerBallSpeed`.
- `step = horizontal displacement since the last Heartbeat`. Violation `Displacement` if
  `step / dt > Config.maxServerBallSpeed × Config.displacementSlack` (4; 1.5 gave honest-play false
  positives in the T079 Studio run).
- On violation: clamp the velocity to the limit, and for `Displacement` also set the position back to
  `lastValidPosition`; `warn` once per violation with the user ID, measured value and limit; add to
  the player's violation count. A ball may not be reset more often than once per 0.5 s (prevents
  warning spam from one long violation).
- Otherwise update `lastValidPosition`, `lastValidVelocity` and push a sample `{ t, speed }` for the
  bump check.
- Separate from the check: a ball with `y < Config.fallRespawnY` is respawned.
