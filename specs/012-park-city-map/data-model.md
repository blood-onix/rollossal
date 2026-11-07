# Data Model: Park City Map (Grey Box)

Everything about where things stand, and every dimension, comes from
[`docs/design/maps/park-city-layout.json`](../../docs/design/maps/park-city-layout.json) (shape described in
[`docs/design/maps/README.md`](../../docs/design/maps/README.md)). This file lists only what the generator adds or
changes, and the state the game keeps at run time.

## Generated world data

Written by `scripts/park_city_world.py` (research R1). Never edited by hand.

| Module | Holds | Source in the layout |
| --- | --- | --- |
| `Content/Worlds/ParkCity.luau` | the `WorldDef`: `rules`, `sizeTiers` (6), `starThresholds` {20, 50, 90}, `spawnPoints` (12), `hub` (x −760, z 0), `environment` (palette, 91 blocks, markers), `lighting`, `objects` (219 `ObjectDef`), `placeholders`, `golden`, `shots`, `hazards` | `world`, `zones`, `blocks`, `spawns`, `objects`, `rails` (14 rails and 4 drain pipes, `kind`), `pads`, `catapults`, `water`, `maze`, `hazards`, `golden`, `roofRun` |
| `Content/Worlds/ParkCityParts.luau` | the 1,064 Tier 3–6 `PlacementSeed` rows, used as `fixedPlacements` (the existing builder pools them as Parts); ids `p<n>` | `scenes[].items`, `trails[].items`, `landmarks` with `tier >= 3` |
| `Content/Worlds/ParkCityLight.luau` | `kinds: {string}` and `data: {number}`, stride 5 (kind index, x, y, z, yaw); the light id of row `i` is `"L"..i` | the same sources with `tier <= 2`, in layout order |
| `Localization/ParkCityStrings.luau` | `object.park.<id>` names, English and Spanish | `objects` keys |

Zones are not generated: `zones = {}` (the placements are explicit), so `Layout.expand` yields nothing and
`ThemeResolve` is not used (`activeThemeId = nil`). Spawn crumbs: each spawn's 20 doorstep items come from the
`doorstep_NN` scenes and are ordinary light objects; they are the objects whose index range the G4 test reads.

### ObjectDef (additions to the existing type)

| Field | Meaning |
| --- | --- |
| `dims` | `{l, w, h}` in studs, from the layout. Absent: a cube of `size` (all existing worlds). |
| `bulk` | cube root of `l × w × h`. Pooled Parts carry it as the `Bulk` attribute. |
| `size` | the longest side (`max(l, w, h)`). Kept so every existing reader of `size` still works. |
| `tier` | `Tiers.lookup(needsD)` over the six park tiers, where `needsD = max(2 × bulk, longest / 1.5)`. |
| `solid` | true for hedge pieces (light) and hoarding pieces (Parts): they stay collidable until the ball can eat them. |
| `light` | true for Tier 1–2: not a server Part. |

### WorldDef (additions)

| Field | Meaning |
| --- | --- |
| `rules` | the optional table of research R3. Absent for Downtown and Snow Village. |
| `placeholders` | list of `{ id, kind, ... }`, each the layout record unchanged (`rail`, `pad`, `catapult`, `water`). 013 reads these. |
| `shots` | list of `{ name, pos = {x,y,z}, look = {x,y,z}, fov }` (research R6). |
| `golden` | the 8 golden spots, handed to the existing daily golden-object rule. |

### The six tiers (Park City)

| Tier | Name key | minDiameter |
| --- | --- | --- |
| 1 | Crumb | 1 |
| 2 | Pocket | 2.5 |
| 3 | Picnic | 6 |
| 4 | Street | 15 |
| 5 | House | 35 |
| 6 | Skyline | 80 |

Top of Tier 6 is 150. `Budgets.meshTriangles` has five entries and is indexed by tier; the generator adds a sixth
entry (Skyline) to the world's own budget table, and `ObjectTemplates.spec` stays on Downtown.

## Run-time state

### Light objects (server, inside `WorldSpawner`)

| Field | Type | Notes |
| --- | --- | --- |
| `lightState[i]` | 0 or 1 | 0 available, 1 taken. Starts all 0. |
| `lightTakenAt[i]`, `lightRespawnAt[i]` | number | set on a take, same delays as parts (`respawnDelayMin..Max`). |
| `pendingLight` | set of `i` | taken indices; the tick walks only these. |
| `outbox` | `{ taken: {number}, restored: {number} }` | changes since the last send; flushed every 0.25 s. |

Transitions: available → taken (a valid absorb) → available (respawn by the sight rule, or the starvation ceiling).
There is no Scattered state: a knocked-off light object is not scattered; its stack entry is removed and nothing is
dropped (knock-off scatters Parts only). This is recorded as a difference in `plan.md`.

### LightDelta (the one new remote, server to client)

`LightDelta:FireClient(player, taken: {number}, restored: {number}, isSnapshot: boolean)`. A snapshot (at join and at
run start) lists every taken index; the client resets its taken set to it. A delta applies the two lists. Indices only;
no sizes, no positions.

### Light pool (client, inside `LightField`)

`takenSet`, a 64-stud cell grid over the light rows, and a pool of at most 450 Parts. A pooled Part carries the
attributes `Size`, `Bulk`, `Longest`, `Tier`, `Taken` and the tag `WorldObject`, and its `Name` is the light id.

### Stuck entries

Unchanged shape (`key`, `id`, `size`, `tier`, `dir`). For a light object `id` is `"L<index>"`. Park City entries also
need the object's dims for the heap fit: `StuckVisuals` reads them from the object def by kind, so the published
`Stuck` string does not grow.

## Validation rules (what the Lune tests pin)

- Light ids and part ids are unique; every object has `dims`; every position is inside ±500 (±620 for the outer
  ring's scenery, none today); every `kind` index in the light data exists.
- `tier` equals the tier of `needsD`; tiers ascend by `minDiameter`; the three tier sets (names, minDiameters, stars)
  match the spec's FR-012.
- The count of each placeholder type equals the layout's; every placeholder carries the layout fields 013 needs.
- Three spawn-facing checks: 12 spawns at least 270 studs apart; 20 doorstep light objects per spawn within 15 studs,
  all with `bulk <= 0.5` (edible at D 1) and `longest <= 1.5`.
