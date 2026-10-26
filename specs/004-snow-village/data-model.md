# Data Model: Snow Village Launch World

Entities, fields, validation rules and state transitions. Types are Luau; the content module has no Roblox
API calls (Lune requires it directly). Numbers marked *provisional* are tuned in the grey-box gate.

## 1. WorldDef (shared type, `Content/GreyBoxRoom.luau` exports it, `Content/Worlds/SnowVillage.luau` fills it)

| Field | Type | Notes |
| --- | --- | --- |
| `worldId` | string | `"snow_village"` (grey box keeps `"greybox"`) |
| `starThresholds` | `{ number }` | `{ 20, 45, 80 }` |
| `growthK` | `number?` | optional per-world growth efficiency; absent means `Config.growthK`. Added only if the pace gate (research R1) fails with 0.6 |
| `sizeTiers` | `{ SizeTierDef }` | 5 entries, see §2 |
| `objects` | `{ ObjectDef }` | 64 entries, see §3 |
| `zones` | `{ ZoneDef }` | placement zones expanded by `Rules/Layout`, see §4 |
| `fixedPlacements` | `{ PlacementSeed }` | hand-placed entries: landmarks, rooftop items |
| `spawnPoints` | `{ SpawnPoint }` | 12 entries, see §5 |
| `halfExtent` | number | 300 (playable Tiers 1–4 town) |
| `outerHalfExtent` | number | 400 (Tier 5 landmark ring) |
| `environment` | `EnvironmentDef` | static geometry and marker spots, see §6 |
| `hub` | `HubDef` | see §7 |
| `lighting` | `LightingDef` | see §8 |
| `respawn` | none | respawn timing is `Config`, never per world |

`GreyBoxRoom` is widened to the same type: its 30 cubes become `fixedPlacements`, its ring becomes
`spawnPoints`, `kerb` becomes one `environment.blocks` entry. Its Lune test keeps asserting the old values.

## 2. SizeTierDef (existing type, no change)

`tier`, `nameKey`, `minDiameter`, `maxDiameter?`, `headlineKey`, `headlineIcon`, `reward?`. Snow Village:

| Tier | Name key | minDiameter | maxDiameter | Object size range |
| --- | --- | --- | --- | --- |
| 1 | `tier.snow_village.1.name` Crumbs | 2 | 5 | 0.3–1.5 |
| 2 | Toys | 5 | 12 | 1.5–4.0 |
| 3 | Yard | 12 | 30 | 4.0–10.0 |
| 4 | Street | 30 | 70 | 10.0–25.0 |
| 5 | Town | 70 | nil (absorbable cap 150) | 25.0–60.0 |

The object-size range per tier is *validation data* held in the Lune test, as in the spec (FR-004), not a
runtime field. `reward` per tier: `snow_village.reward.tier1..5` (type alternating `trail` / `skin`, name
keys `reward.snow_village.tierN.name`), using the 003 grant path unchanged; real cosmetics arrive with 006.

Validation: `minDiameter` ascends and each tier's `maxDiameter` equals the next `minDiameter`; tier 5 has no
`maxDiameter`.

## 3. ObjectDef (existing type plus two fields)

`id`, `tier`, `size`, `coins`, `bookId`, `nameKey`, `icon` (existing) plus:

- `assetKey: string`: key in `Assets.meshes`.
- `fallback: "Block" | "Ball" | "Cylinder"`: shape of the procedural stand-in (R8).

Rules (Lune): ids and `bookId`s unique across all 64 (`bookId = "snow_village." .. id`); `tier ∈ 1..5`;
`size` inside the tier range; `size ≤ 0.4 × tierCeiling` (ceilings 5, 12, 30, 70, 150); `coins` positive
integer inside the tier's range (1–2, 3–5, 8–15, 20–40, 60–100) and the ranges ascend; `nameKey` and
`assetKey` resolve; counts are 18 / 16 / 14 / 12 / 4.

Provisional catalogue (`size` in studs, longest dimension; coins interpolate within the tier range by size).
The names are the plan's starting set for the Blender workload; renaming is a data change.

| Tier | Objects (size) |
| --- | --- |
| 1 (18) | gumdrop 0.3, button 0.4, jingle_bell 0.5, acorn 0.5, marshmallow 0.6, peppermint 0.7, pine_cone 0.7, bauble 0.8, cookie 0.9, ribbon_bow 1.0, mini_snow_globe 1.0, wooden_star 1.1, candy_cane 1.2, sock_ornament 1.3, gingerbread_man 1.3, matchbox_car 1.4, toy_soldier 1.5, cocoa_mug 1.5 |
| 2 (16) | rubber_duck 1.6, mitten_pair 1.7, gift_box 1.8, block_stack 1.9, snowball 2.0, toy_drum 2.2, snow_boot 2.4, teddy_bear 2.5, plush_penguin 2.6, tin_robot 2.7, lantern 2.8, cat 3.0, wreath 3.0, flower_pot 3.1, toy_sled 3.2, rocking_horse 3.5 |
| 3 (14) | barrel 4.2, mailbox 4.5, giant_gift 4.5, snow_mound 4.8, dog 5.0, fence_section 5.0, firewood_stack 5.0, sledge 6.0, bicycle 6.5, bench 7.0, snowman 8.0, cocoa_cart 8.0, pine_sapling 9.0, street_lamp 9.5 |
| 4 (12) | bus_shelter 10, market_stall 11, big_snowman 12, kiosk 12, fountain 13, car 14, sleigh 15, van 17, bandstand 18, christmas_tree 20, snowplough 22, bus 25 |
| 5 (4) | cottage 28, town_house 34, skating_rink 40, clock_tower 48 (F-2) |

Coins at the extremes: Tier 1 gumdrop 1 … cocoa_mug 2; Tier 5 cottage 60 … clock_tower 100.

## 4. ZoneDef and PlacementSeed

```text
ZoneDef = {
  id: string,                       -- "sv_zone_porch_03"
  x: number, z: number, w: number, d: number,   -- rectangle centre and size (rectangles only)
  y: number,                        -- ground height of the zone (porch 1.2, rooftop 11, street 0)
  mix: { { objectId: string, weight: number } },
  count: number,                    -- placements to produce
  seed: number,                     -- integer, per zone
  spawnSlot: number?,               -- 1..12: tags the placements as that slot's cluster
}
PlacementSeed = { id, objectId, x, y, z, yaw, spawnSlot? }
```

Expanded by `Layout.expand` into `ObjectPlacement` (§ below). Rules: `count ≤ cells` of the zone (the
expander errors in tests otherwise); every `objectId` in `mix` exists; every zone with `spawnSlot` uses only
Tier 1 objects; zone rectangles stay inside `±halfExtent`; Tier 5 landmarks in the outer ring are `fixedPlacements` inside
`±outerHalfExtent`.

Provisional zone budget (pool total ≈ 1,500; re-sized by R1): 12 spawn micro-zones × ~70 T1 (=840, of which
10 are the reserved cluster), Tier 2 front yards ≈ 330, Tier 3 lanes and park ≈ 230, Tier 4 main street and
square ≈ 100, Tier 5 landmarks 4 types × ~2 instances.

### ObjectPlacement (output of expansion; also the entity in the spec)

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | `sv_p_0001` … stable and deterministic |
| `objectId` | string | references `ObjectDef.id` |
| `x, y, z, yaw` | number | `y` is the surface height, the part rests with its centre at `y + size/2` |
| `spawnSlot` | number? | cluster tag, 1..12 |

Validation (Lune on the expanded list): ids unique; every `objectId` resolves; each of the 12 slots has ≥ 10
placements with `spawnSlot = slot`, `size ≤ 0.8` (eatable at start) and distance ≤ `Config.spawnClusterRadius`
(45) from that slot's spawn point; total pool + geometry parts + 12 balls ≤
`Config.Budgets.maxActivePartsPerServer`; no two footprints (circle of radius `size/2`) overlap.

## 5. SpawnPoint

`{ slot: 1..12, x, y, z, yaw }` — the ball rests at `(x, y + startDiameter/2 + 0.5, z)`. `WorldSpawner.getSpawnSlot`
reads this list; the ring formula in `GreyBoxRoom` becomes data. Spawn points sit on porches or tabletops
(raised `y`), 80–120 studs apart, so one micro-zone does not overlap another.

## 6. EnvironmentDef

```text
blocks: { { id, kind = "Block" | "Wedge" | "Cylinder", cframe = {x,y,z,yaw}, size = {x,y,z}, swatch: string } }
markers: { { kind = "BoosterSpot" | "TrapSpot", x, y, z } }
```

`blocks` are primitive anchored parts (ground slabs, streets, kerbs 1–2 studs, steps, ramps as wedges,
terrace and rooftop slabs, boundary walls at `±outerHalfExtent`, invisible kill-floor not needed because
`fallRespawnY` exists). `swatch` is a name in `palette.json` mapped to a `Color3` constant table kept inside
the data module so the placeholder look and the final look use the same palette (no UV, plain `Color`).
`markers` are built as small invisible parts tagged `BoosterSpot` / `TrapSpot` (FR-011); at least 6 of each.
Rules: block count ≤ 400; every `swatch` exists; at least one wedge and one kerb of height 1–2 within 60
studs of every spawn point (the jump routes).

## 7. HubDef

`center {x,z}`, `halfExtent`, `spawn {x,z}`, `padRadius`, `assetKey` (hub mesh). Snow Village:
`center = (-460, 0)`, `halfExtent = 24`, so its nearest edge (x = -436) is outside the landmark ring
(`outerHalfExtent = 400`) by 36 studs.

## 8. LightingDef

`ambient`, `outdoorAmbient` (`{r,g,b}` 0–255), `brightness`, `clockTime`, `fogColor`, `fogStart`, `fogEnd`,
`atmosphereDensity`, `atmosphereColor`, `atmosphereDecay`. Provisional: pale blue-white ambient, `clockTime`
15.5, `fogStart` 150, `fogEnd` 900, density 0.3. Fog must not hide the next tier's objects inside the
streaming radius (checked in captures).

## 9. PooledWorldObject (runtime, in `WorldSpawner`)

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | placement id |
| `objectId` | string | |
| `tier`, `size` | number | copied from `ObjectDef` |
| `spawnCFrame` | CFrame | original place; respawn returns here |
| `part` | BasePart | created once, never destroyed |
| `state` | `"Available" \| "Taken" \| "Scattered"` | |
| `takenAt` | number? | set when `Taken`; base for the starvation ceiling |
| `respawnAt` | number? | `takenAt + Random(60..120)` |
| `availableAt` | number? | when a `Scattered` object becomes absorbable |
| `holderKey` | string? | stack entry that holds it (unchanged semantics) |
| `spawnSlot` | number? | cluster tag, used by `refreshCluster` |

State transitions:

```text
Available --absorb (server validated)--------> Taken      (hidden in place, CanCollide/Touch/Query off)
Taken     --now >= respawnAt and not watched--> Available  (same part, back at spawnCFrame)
Taken     --now >= takenAt + 180-----------------> Available  (forced; starvation ceiling)
Taken     --knock-off while holderKey matches----> Scattered (shown near ball, on the ground by raycast)
Scattered --now >= availableAt-----------------> Available  (absorbable; stays where it landed)
Taken/Scattered --run reset / player leaves-----> Available  (returnToSpawn, existing paths; refreshCluster at run start)
```

A `Scattered` object that nobody eats stays where it landed until the run reset returns it; it does not
respawn (unchanged from 001/002).

Part attributes (existing contract kept): `Size`, `Tier`, `Taken`; new: `ObjectId`; tag `WorldObject`.

## 10. Art manifest (`art/export/manifest.json`)

```text
{ "generated": "<iso date>", "blender": "<pinned version>", "palette": "palette.png",
  "meshes": [ { "id": "gumdrop", "tier": 1, "triangles": 84, "bytes": 5120, "sha256": "…" }, … 65 entries (hub id "hub") ] }
```

Rules: one entry per `ObjectDef.id` plus `hub`; `triangles ≤ Config.Budgets.meshTriangles[tier]` (hub uses
the tier-5 budget); `bytes` and `sha256` match the file on disk.

## 11. Config additions (all in `Config.luau`, read-only)

`respawnDelayMin = 60`, `respawnDelayMax = 120`, `respawnOutOfSightRadius = 45`,
`respawnViewDistance = 120`, `respawnViewCos = 0.5`, `respawnHeadingMinSpeed = 2`,
`respawnForceAfterSeconds = 180`, `cullTierDelta = 2`, `spawnClusterRadius = 45`,
`Flags.SnowVillage = true`, `Budgets.maxActivePartsPerServer = 2000`. `respawnDelay` is removed (its users
are listed in plan F-7/F-10); `Budgets.meshTriangles` already holds `{ 300, 300, 800, 2500, 2500 }`.
