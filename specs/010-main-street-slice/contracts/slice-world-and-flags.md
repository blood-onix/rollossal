# Contract: Slice world, flags and selection

## Flags

All default `false`. Legacy behaviour is unchanged when they are off.

| Flag | Effect when on |
| --- | --- |
| `Config.Flags.MainStreetSlice` | `Worlds.active` is `MainStreetSlice`. Outranks `Downtown`, `SnowVillage` and the grey box. |
| `Config.Flags.SliceHud` | `Hud` does not build `NextTier`, `Star1..n`, `TierBanner`. The too-large bump is active. |
| `Config.Flags.HeapRedesign` | `StuckVisuals` uses `Heap`; `BallService` publishes `maxPublishedStuck` entries. |

## Selection

```text
local active: WorldDef = if Config.Flags.MainStreetSlice
	then MainStreetSlice :: any
	elseif Config.Flags.Downtown then Downtown :: any
	elseif Config.Flags.SnowVillage then SnowVillage :: any
	else GreyBoxRoom
```

The tests that pin this chain (`Config.test.luau`, `Downtown.test.luau`) are updated in the same task.

## World guarantees (tested in `MainStreetSlice.test.luau`)

1. `worldId = "main_street_slice"`; `halfExtent = 250`; every placement and block is inside x in [-100, 100] and
   z in [-250, 250].
2. Exactly 12 spawn points, at least 10 studs apart pairwise, none inside a solid block or placement footprint, all
   with `yaw` facing +z within 30 degrees.
3. Each spawn has at least one tier 1 placement within 15 studs (a pickup within 5 s at the base roll speed).
4. Zone order along z: park, suburb corner, main street, skyline. The first placement of a main-street facade is at
   z >= -60; the skyline landmarks are at z >= 170.
5. Placement count is at most `maxPlacements` (1,200). Placement ids are unique. Every `objectId` is known.
6. Every object size is at most `absorbRatio * tier ceiling` (same rule as Downtown).
7. Determinism: expanding the world twice gives an identical result.
8. All 10 kits appear at least once.
9. Downtown stays the default: with all three flags off, `Worlds.active.worldId` is unchanged.

## Out of scope for the world

Rebuilding Downtown (004j), the 99-prop library (004h), the avatar pusher, juice and wobble (004c).
