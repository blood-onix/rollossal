# Contract: Runtime modules, containers, tags and attributes

## Workspace layout

```text
Workspace
├── World                       (Folder)
│   ├── Geometry                (Folder)  static anchored parts from environment.blocks
│   ├── Objects                 (Folder)  one pooled part per placement, named by placement id
│   ├── Hub                     (Folder)  hub floor, pad and hub mesh
│   └── Markers                 (Folder)  invisible BoosterSpot / TrapSpot parts (CanCollide, CanTouch, CanQuery off)
├── Balls                       (unchanged)
└── StuckVisuals                (unchanged)
```

Tags (`CollectionService`): `WorldObject` on every pooled part; `BoosterSpot`, `TrapSpot` on markers.
Pooled part attributes: `Size` (number), `Tier` (number), `ObjectId` (string), `Taken` (boolean). The first
three never change after start; `Taken` follows the server state.

`Workspace.GreyBoxRoom` and `Workspace.Hub` no longer exist as top-level names.

## `WorldBuilder` (server, new)

```lua
WorldBuilder.start(world: WorldDef, placements: { Layout.Placement }): BuiltWorld
-- Idempotent. Destroys a previous Workspace.World, creates the folders, applies lighting and streaming,
-- builds Geometry, Hub and Markers, builds one template per used objectId, then one pooled part per placement.
-- Yields (CreateMeshPartAsync) but is called once from Main.server before any ball exists.

export type BuiltWorld = { objects: { BuiltObject }, geometryCount: number }
export type BuiltObject = { placement: Layout.Placement, part: BasePart }

WorldBuilder.getTemplate(objectId: string): BasePart      -- the per-type template (MeshPart or fallback part)
WorldBuilder.applyLighting(lighting: LightingDef)
WorldBuilder.partCount(): number                           -- pooled + geometry (for the budget check)
```

Rules: each pooled part is `Anchored`, `Size` from the template, centre at `y + size/2` (`Size` here means the
longest dimension is `ObjectDef.size`; the template is scaled once if its longest side differs by more than
5 %), `CFrame` yaw from the placement, and carries the attributes and tag above. A missing or failing mesh
falls back to the primitive stand-in and `warn`s once per `objectId`.

## `WorldSpawner` (server, edited)

Pool registry and state only. Keeps its public names so `AbsorbService`, `BallService` and `RunManager`
change as little as possible; `RoomCube` is renamed `PooledWorldObject` (`CubeState` to `ObjectState`).

```lua
WorldSpawner.start()                                  -- builds through WorldBuilder, fills the registry
WorldSpawner.getObject(id: string): PooledWorldObject?   -- was getCube
WorldSpawner.getSpawnSlot(index: number): Vector3     -- from Worlds.active.spawnPoints, full 3D, wraps like today
WorldSpawner.getHubSpawn(): Vector3                   -- unchanged
WorldSpawner.markTaken(obj, now, holderKey)           -- sets takenAt, respawnAt = now + delayFrom(random01)
WorldSpawner.isHeldBy(obj, holderKey): boolean        -- unchanged
WorldSpawner.scatter(obj, position, availableAt)      -- Y from a ground raycast on World.Geometry, fallback spawnCFrame.Y
WorldSpawner.returnToSpawn(obj)                       -- same part, back to spawnCFrame (never Destroy)
WorldSpawner.scatterSpots(centre, count, radius, startAngle)   -- clamps to Worlds.active.halfExtent - 2, y left 0
WorldSpawner.update(now)                              -- respawn gate (below); Scattered -> Available as today
WorldSpawner.refreshCluster(slot: number, now: number)         -- NEW: Taken cluster objects of `slot` -> Available, no sight check
WorldSpawner.registryCounts(): { free, pendingRespawn }        -- unchanged
WorldSpawner.countsByTier(): { [number]: { available: number, total: number } }   -- NEW (bot run and tests)
WorldSpawner.reset()                                  -- test helper, unchanged meaning
```

`update(now)`: for each `Taken` object whose `respawnAt <= now` or `takenAt + forceAfter <= now`, build the
watcher list once per call from `BallService` sessions (position, horizontal velocity unit vector or 0 below
`respawnHeadingMinSpeed`), call `Respawn.canRespawn`, and `returnToSpawn` when true. The registry keeps a
separate list of `Taken` objects, so a tick never walks the whole pool (about 1,500 parts).

`WorldSpawner` takes the watcher list through a function it is given at start (`setWatcherSource`), not by
requiring `BallService` (which already requires `WorldSpawner`; this avoids a require cycle).

## `AbsorbService` (edited)

- `WorldSpawner.getObject(objectId)`; `inRange`, `directionTo` read `object.part`.
- After a valid absorb: `local def = Worlds.objectById[obj.objectId]` (was `objectByTier[cube.tier]`).
- Growth uses `Worlds.growthK` (was `Config.growthK`); `BallService` shrink uses the same value.
- Remote surface, argument types and return codes: **unchanged** (Constitution II).

## `BallService` (edited)

- `freeSlot` loops over `#Worlds.active.spawnPoints` (was `GreyBoxRoom.spawnSlots`).
- `placeAtSpawn`: after setting the position, for a real `Player` call
  `player:RequestStreamAroundAsync(position, 5)` inside `pcall` before `setFrozen(false)` is allowed to run
  (the existing frozen-countdown path keeps the ball held; the request normally finishes inside it).
- `resetBall` and `respawn` call `WorldSpawner.refreshCluster(session.slot, now)` at run start so the
  5-second first-pickup guarantee holds on Roll again (spec edge case).

## `WorldCuller` (client, new)

```lua
WorldCuller.start()
```

Per [research R6](../research.md). Reads `Players.LocalPlayer`'s ball `Diameter` attribute, `Tiers.lookup`
with `Worlds.tierLikes`, `Config.cullTierDelta`. No remote, no server state. Started from `Main.client`
after `StuckVisuals`.

## `BallController`, `StuckVisuals`, `Feedback` (client, edited)

- `BallController`: replace `WaitForChild("GreyBoxRoom")` / `Cubes` with `Workspace:WaitForChild("World")` and
  `World.Objects`; the ground filter is `{ World }`; contact scanning uses the `WorldObject` tag instead of
  `GetChildren()` so streamed-out parts are simply absent.
- `StuckVisuals`: `shadeOf(tier)` (grey) is replaced by cloning `ObjectId`'s visual: the client builds the
  same template via `WorldBuilder`-independent code (a small local `visualFor(objectId)` that uses
  `Assets.meshes` and the palette texture, falling back to a coloured primitive of `ObjectDef.size`). If the
  object's `Size` attribute is read from the pooled part, the `ObjectDef` is the fallback.
- `Feedback`: adds the looped music `Sound` in the `Music` group; adds mesh and palette IDs to the preload
  list (non-empty ones only). Pitch by tier already uses `Worlds.objectById`.

## Studio test seams

- `WorldSpawner.reset()` and `WorldSpawner.start()` as today.
- Specs choose objects with `Worlds.objectsByTier[n][1]` and the first placement with that `objectId`
  (`Worlds.placements`), never a literal id.
- `BotRun.luau` is a server script (not a `require` from the MCP) and returns its report as attributes on
  `Workspace` (`BotRunReport`), read back with `execute_luau`.
