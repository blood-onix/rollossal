# Data Model: Main-Street Slice

Types are Luau `--!strict` shapes. Existing types (`WorldDef`, `ObjectDef`, `Placement`, `SpawnPoint`, `BlockDef`,
`StuckEntry`) are in `src/shared/Content/GreyBoxRoom.luau` and `src/shared/Rules/StuckStack.luau` and do not change.

## Config additions (`src/shared/Config.luau`)

| Key | Type | Default | Used by |
| --- | --- | --- | --- |
| `Flags.MainStreetSlice` | boolean | `false` | `Worlds` precedence |
| `Flags.SliceHud` | boolean | `false` | `Hud`, `BallController` too-large bump |
| `Flags.HeapRedesign` | boolean | `false` | `StuckVisuals`, `BallService` tail length |
| `billboardTextureCap` | number | `6` | `Signs` validation test |
| `maxPublishedStuck` | number | `60` | `BallService.publishStuck` (when `HeapRedesign`) |
| `heapLocalCap` | number | `40` | `Heap.select` for the local ball |
| `heapRemoteCap` | number | `12` | `Heap.select` for other players' balls |
| `heapScaleExponent` | number | `1.0` | attachment scale with ball diameter |
| `heapCoverageTargetD` | number | `5` | coverage test diameter |
| `heapCoverageTarget` | number | `0.6` | minimum fraction of the base sphere hidden at that D |
| `tooLargeBumpCooldown` | number | `0.4` | `BallController` |
| `tooLargeBumpImpulse` | number | `18` | studs/s velocity change away from the contact |

## Assets additions (`src/shared/Assets.luau`)

- `facadeAtlas: string = ""`
- `billboards: { b1: string, b2: string, b3: string, b4: string, b5: string, b6: string }`, all `""`.

An empty id means the renderer uses flat palette colours.

## Street rules (`Rules/StreetRules.luau`)

```text
StreetSegment = { id: string, x0: number, z0: number, x1: number, z1: number, width: number,
                  sidewalk: number, yaw: number }          -- width = carriageway; sidewalk >= 6
Junction      = { id: string, x: number, z: number, crossWidth: number }
StreetIds     = { tree: string, lamp: string, bin: string, bench: string, car: string, hydrant: string }
StreetDef     = { seed: number, segments: { StreetSegment }, junctions: { Junction }, ids: StreetIds,
                  treeEvery: number, lampEvery: number, lampTreeClear: number,
                  jitterPos: number, jitterYaw: number }
StreetOut     = { blocks: { BlockDef }, placements: { Placement } }
```

Validation (tested): `sidewalk >= 6`; `treeEvery = 18`, `lampEvery = 24`, `lampTreeClear = 4`; every placement
id is unique; no lamp within `lampTreeClear` of a tree; yaw of every placement is the segment yaw, that yaw + 180, or a
junction axis, plus at most `jitterYaw`.

## Scene kits (`Content/SceneKits.luau`, `Rules/SceneKit.luau`)

```text
KitEntry    = { objectId: string, dx: number, dz: number, yaw: number }   -- kit-local, yaw in degrees
KitDef      = { id: string, halfX: number, halfZ: number, entries: { KitEntry } }
KitInstance = { kitId: string, ox: number, oz: number, yaw: number, seed: number }
```

`SceneKit.expand(kit, instance, idPrefix, bounds) -> { Placement }`:

- world x = ox + dx*cos(yaw) + dz*sin(yaw); world z = oz - dx*sin(yaw) + dz*cos(yaw).
- Placement yaw = entry yaw + instance yaw, plus seeded jitter.
- Placement id = `idPrefix .. "_" .. index`.
- An entry outside the kit footprint or `bounds` is a hard error (tested).

The 10 kits: `picnic_spread`, `cafe_terrace`, `bus_stop`, `fruit_stall`, `bike_rack`, `road_works`, `car_park_rows`,
`yard_sale`, `flower_bed`, `recycling_point`.

## Heap (`Rules/Heap.luau`)

```text
HeapEntry   = { key: string, id: string, size: number, tier: number, age: number }   -- age 0 = newest
HeapParams  = { cap: number, protectTier: number }                                   -- protectTier = 4
HeapResult  = { outer: { HeapEntry }, buried: { HeapEntry } }
```

- `score(e) = e.size / (1 + e.age)`; tier at or above `protectTier` always stays outer while fewer than `cap` are
  protected.
- `select(entries, params) -> HeapResult`: sorts by score then key (stable and deterministic), keeps the first `cap`.
- `coverage(ballD, outer, itemFootprint) -> number`: fraction of the base sphere surface hidden, clamped to [0, 1].
- `coreColor(buried, paletteOf) -> {r,g,b}`: mean of buried item colours (palette lookup injected as a function).
- `buryProgress(elapsed, duration) -> number`: linear 0 to 1, used for the shrink (no pop).

## Signs and billboards (`Content/Signs.luau`)

```text
SignSlot      = { id: string, facadeId: string, shopName: string, atlasRegion: string,
                  x: number, y: number, z: number, yaw: number }
BillboardSlot = { id: string, x: number, y: number, z: number, yaw: number,
                  imageAsset: string, sponsored: boolean }     -- sponsored must be false
```

`imageAsset` is a key into `Assets.billboards` (`"b1"` to `"b6"`), not an id. At most `Config.billboardTextureCap`
distinct values.

## Slice world (`Content/Worlds/MainStreetSlice.luau`)

A `WorldDef` with:

- `worldId = "main_street_slice"`, `halfExtent = 250`, `outerHalfExtent = 300`.
- `spawnPoints`: 12 entries in the park, at least 10 studs apart, facing +z.
- `fixedPlacements`: expanded from `StreetRules` and `SceneKit`, plus trails and park clusters (FR-007).
- `environment.blocks`: ground, street blocks, facade blocks, backdrop towers, `Boundary` blocks at x = +-100 and z = +-250.
- `activeThemeId = "city"`, `supportedThemes = {"city"}`, `themeBindings.city = { slots = {}, overlays = {zones = {}, fixedPlacements = {}} }`.
- `maxPlacements = 1200`, `growthK` and `starThresholds` copied from Downtown until the owner tunes them.
- `ambient = { pigeons = <small> }`, no traffic.

## Slice ObjectDefs

Slice-only objects: `shop_front`, `fruit_crate`, `flower_pot`, `picnic_blanket`, `awning`, `road_barrier`. Each uses
`bookId = "slice." .. id`, `nameKey = "object.slice." .. id`, and `assetKey` of an existing `dt_*` key or `""`, with
`fallback` coloured parts. The stand-ins never reach the book UI because `bookPage` is absent for this world.

## Relationships

```text
Config.Flags.MainStreetSlice --> Worlds.active = MainStreetSlice
MainStreetSlice --uses--> StreetRules.expand, SceneKit.expand, SceneKits, Signs
MainStreetSlice --> ThemeResolve (fixed placements only) --> Worlds.placements
BallService.Stuck (60) --> StuckVisuals --> Heap.select --> welded visuals (outer) / buried (shrunk)
BallController.contactScan --> Absorb.canAbsorb false --> too-large bump (local) + BumpRemote (as before)
```

No state transitions are added. A buried heap entry stays in the server's `StuckStack` until knock-off pops it.
