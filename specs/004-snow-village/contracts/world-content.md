# Contract: World content, Worlds, Config, Assets, Strings

## `src/shared/Content/Worlds/SnowVillage.luau`

`--!strict`, data only (no Roblox API; Lune requires it directly). Returns a `WorldDef` ([data-model.md](../data-model.md) §1).

```lua
local SnowVillage: WorldDef = {
	worldId = "snow_village",
	starThresholds = { 20, 45, 80 },
	-- growthK = <only if the pace gate demands it; owner decision>,
	halfExtent = 300,
	outerHalfExtent = 400,
	sizeTiers = { ... 5 ... },
	objects = { ... 64 ... },      -- each: id, tier, size, coins, bookId, nameKey, icon, assetKey, fallback
	zones = { ... },               -- Layout.Zone
	fixedPlacements = { ... },     -- landmarks and rooftop items
	spawnPoints = { ... 12 ... },
	environment = { blocks = { ... }, markers = { ... } },
	hub = { center = { x = -460, z = 0 }, halfExtent = 24, spawn = { x = 0, z = 0 }, padRadius = 5, assetKey = "hub" },
	lighting = { ... },
}
```

Naming: `id` snake_case (`jingle_bell`), `bookId = "snow_village." .. id`, `nameKey = "object.snow_village." .. id`,
`assetKey = id`. Tier keys: `tier.snow_village.N.name`, `tier.snow_village.N.headline`; rewards
`snow_village.reward.tierN` with `reward.snow_village.tierN.name`.

## `src/shared/Worlds.luau`

```lua
Worlds.active: WorldDef                      -- SnowVillage when Config.Flags.SnowVillage, else GreyBoxRoom
Worlds.sizeTiers, Worlds.tierLikes, Worlds.starThresholds     -- as today
Worlds.objectById, Worlds.objectByBookId                       -- as today
Worlds.objectsByTier: { [number]: { ObjectDef } }              -- NEW (replaces objectByTier)
Worlds.placements: { Layout.Placement }                        -- NEW: zones expanded + fixedPlacements
Worlds.growthK: number                                         -- NEW: active.growthK or Config.growthK
```

`objectByTier` is **removed**; its callers (`AbsorbService`, `RunManager.spec`) use `objectById`. Anything
needing "an object of tier N" in tests uses `Worlds.objectsByTier[N][1]`.

## `src/shared/Config.luau` additions

```lua
respawnDelayMin = 60, respawnDelayMax = 120,          -- replaces respawnDelay = 15
respawnOutOfSightRadius = 45, respawnViewDistance = 120, respawnViewCos = 0.5,
respawnHeadingMinSpeed = 2, respawnForceAfterSeconds = 180,
cullTierDelta = 2, spawnClusterRadius = 45,
Flags = { …, SnowVillage = true },
Budgets = { maxActivePartsPerServer = 2000, meshTriangles = { 300, 300, 800, 2500, 2500 } },
```

`Config.test.luau` asserts: min < max, radius < view distance, `0 < respawnViewCos < 1`, force-after ≥ max
delay, `cullTierDelta ≥ 1`, budgets positive and the mesh budget ascending.

## `src/shared/Assets.luau` additions

```lua
Assets.sounds.music = "rbxasset://sounds/…"      -- placeholder until the owner picks the track (F-12)
Assets.palette = ""                              -- rbxassetid of the shared palette texture, "" until imported
Assets.meshes = { gumdrop = "", button = "", … hub = "" }   -- "" means "not imported yet: use the fallback"
```

`Assets.meshes` has exactly one key per `ObjectDef.assetKey` plus `hub` (Lune test, both directions, so no
orphan key). An empty string is allowed until the final gate; `REQUIRE_ASSET_IDS=1 scripts/check.sh` (and the
final task) fail on any `""`. IDs are the only place an `rbxassetid://` string may appear.

## `src/shared/Localization/Strings.luau` additions

About 90 keys, each with `en` and `es`: `object.snow_village.<id>` × 64, `tier.snow_village.N.name` × 5,
`tier.snow_village.N.headline` × 5, `reward.snow_village.tierN.name` × 5, and hub/world title keys if the UI
needs them. `Strings.test.luau` requires non-empty `en` and `es` for every key that `SnowVillage` references
(FR-004), in addition to the existing key list. Spanish is a draft for owner review.

## `default.project.json`

```json
"Workspace": {
  "$className": "Workspace",
  "$properties": {
    "StreamingEnabled": true,
    "StreamingMinRadius": 128,
    "StreamingTargetRadius": 512,
    "StreamingIntegrityMode": "PauseOutsideLoadedArea"
  }
}
```

`StreamingIntegrityMode` is an enum property; if Rojo 7.7.1 cannot serialise it, the same four lines run once
in `WorldBuilder.start` (server) and the project file keeps only `StreamingEnabled` (spike T003 decides).
