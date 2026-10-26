# Research: Snow Village Launch World

Phase 0 decisions. Each entry: Decision, Rationale, Alternatives. "Spike" marks something that cannot be
settled by reading and is proven by an early task (named in the plan phases); until the spike passes, the
fallback applies. No NEEDS CLARIFICATION remains open; items that need the owner are in
[plan.md](plan.md) under Human Approval Required.

## R1. Growth pace and object density (finding F-1)

**Decision**: write a pure pace model (`tests/unit/Pace.test.luau`) before any layout is authored, and size
the zones from its output. If it fails with `growthK = 0.6`, add optional `growthK` to `WorldDef` and ask the
owner to set it; do not relax the 5 s / 60 s rules.

**Arithmetic** (hand-computed; the Lune test must assert fixed numbers like these, not recompute them).
Growth is `D' = (D³ + k·s³)^(1/3)`. If a ball always eats objects of size `s = ρ·D`, one pickup multiplies D
by `(1 + k·ρ³)^(1/3)`.

| k | ρ | D growth per pickup | Tier 1→2 (×2.5) | 1 star (×10) | Tier 4 (×15) | 3 stars (×40) |
| --- | --- | --- | --- | --- | --- | --- |
| 0.6 | 0.40 (best) | 1.26 % | 73 | 183 | 216 | 294 |
| 0.6 | 0.30 (typical) | 0.54 % | 171 | 430 | 506 | 689 |
| 1.0 | 0.40 | 2.09 % | 44 | 111 | 131 | 178 |
| 1.0 | 0.30 | 0.89 % | 103 | 259 | 305 | 415 |
| 1.5 | 0.40 | 3.1 % | 30 | 75 | 89 | 121 |
| 1.5 | 0.30 | 1.33 % | 69 | 174 | 205 | 279 |

(Pickups to reach the target from D = 2: `ln(ratio) / ln-growth`; e.g. `ln 2.5 / 0.01256 = 73`.)

**Reading it**: a ball moves 18–32 studs/s, so even a perfect line of objects every 10 studs gives 2–3
pickups per second. With `k = 0.6`, Tier 2 inside 60 s needs at least 73 pickups and realistically 100+,
which is 1.7+ per second for a full minute on a thumb stick. One star needs 183–430 pickups in 240 s. Tier 1
objects range 0.3–1.5 studs but only those ≤ 0.8 are eatable at spawn; at D = 2 an object of size 0.8 adds
just 0.307 of the ball's 8 volume.

**Density consequences** (provisional, to be replaced by the model's output):

- Each spawn micro-zone (porch, tabletop, gift pile) needs about 75–100 Tier 1 objects (the spec's ~10
  within 3 s is the *guaranteed start*, not the whole zone). 12 zones: 900–1,200 Tier 1 parts. A
  town-wide scatter of Tier 1 is not needed in that case.
- Objects are skewed to the upper end of each tier's size range so that ρ stays near 0.3–0.4: a "ladder" of
  sizes at each ball diameter.
- Pool size target 1,500 (T1 ≈ 800, T2 ≈ 330, T3 ≈ 230, T4 ≈ 100, T5 ≈ 8 instances of 4 types, rest in
  special zones) and `maxActivePartsPerServer = 2000`. A larger `growthK` would cut T1 to ~500.
- Respawn (60–120 s, out of sight) lets a micro-zone refill for the *next* run's player in the same slot, not
  the same run's second lap.

**Model definition** (what `Pace.test.luau` simulates): the zone data expanded by `Layout`; a deterministic
greedy eater that, once per `1/R` seconds, takes the largest uneaten object in its zone sequence with
`size ≤ 0.4·D`, using `Growth.growDiameter` and `Absorb.canAbsorb`; R = 1.5 pickups/s for tiers 1–2 and 1.0
beyond (travel dominates). Assertions (fixed): Tier 2 reached ≤ 60 s; ≥ 20 studs by 240 s; ≥ 30 studs by
240 s for the SC-003 claim. Deterministic: no clock, no randomness.

**Alternatives**: (a) accept the numbers and let Tier 2 take 2–3 minutes: breaks Constitution VI. (b) Lower
`absorbRatio` to 0.5: changes the core mechanic proven in 001, owner call, and alters every bump rule.
(c) Change the tier boundaries (e.g. Tier 2 at 3.5): contradicts GDD §3.3 and the star targets.
(d) Per-world `growthK`: chosen as the lever because Rules already take `k` as an argument, so no Rules
change, only one data field and two call sites (`AbsorbService`, `BallService` shrink).

## R2. Layout as zones expanded by a pure seeded rule

**Decision**: `SnowVillage.zones` is hand-authored data (rectangles/rings with `y`, an object mix with
weights, a count, a seed). `Rules/Layout.expand(zones, objects)` returns the full placement list with a
jittered grid (cell edge ≥ 1.2 × the largest object in the mix) so no two footprints overlap, using its own
integer LCG (no `math.random`, no clock; Constitution III). Explicit hand-placed entries (landmarks,
rooftop items, spawn clusters' first ring) are allowed alongside zones. `Worlds` exposes
`Worlds.placements` (expanded once at require time).

**Rationale**: about 1,500 records cannot be authored by hand or reviewed; zones keep intent readable
("12 gift-pile zones, 90 T1 each"). The expander is deterministic, so server and any test agree. The spawn
cluster rule (≥ 10 Tier 1 objects with `size ≤ 0.8` within 45 studs of each of the 12 spawn points) is a
property of the zone data and is asserted by Lune (FR-004).

**Alternatives**: generated and committed placements file (drifts, noisy diffs); hand-written records (not
feasible); placing objects in Studio by hand (not reproducible, merge-hostile `.rbxl`, Constitution X).

## R3. World container and world selection

**Decision**: `Workspace.World` containing `Geometry` (static, anchored), `Objects` (pooled) and `Hub`
folders. The spec allows aliases; `Workspace.Hub` moves under `World` so one `WaitForChild("World")` covers
clients. `Worlds.active` is `SnowVillage` when `Config.Flags.SnowVillage` is true, else `GreyBoxRoom`.
`GreyBoxRoom` also needs `objectsByTier`, `placements` (its 30 cubes become placements) and `spawnPoints` so
the same code builds it; widening the `Room` type is the only edit to that file.

**Rationale**: the flag is both the rollback and the way the old world stays loadable for A/B checks
(Constitution VII "new features behind flags").

**Alternatives**: delete `GreyBoxRoom` (spec FR-002 keeps it for tests); two parallel code paths (a defect
per Constitution VII).

## R4. Pooling and object states

**Decision**: `WorldBuilder` creates every pooled part once at start (clone of the per-`objectId` template),
sets `Tier`, `Size`, `ObjectId`, `Taken` attributes and the `WorldObject` tag, and parents under
`World.Objects`. `WorldSpawner` keeps the registry (`PooledWorldObject`, states `Available | Taken |
Scattered`) and hides/restores in place. Nothing in `src` calls `Destroy` on a pooled part after start; a
Studio spec records `Instance` identity and child count before and after a respawn cycle.

`markTaken` sets `respawnAt = now + delay` where `delay = Random:NextNumber(Config.respawnDelayMin,
Config.respawnDelayMax)` from a `Random.new(seed)` owned by `WorldSpawner`, and `takenAt = now`.

**Rationale**: existing behaviour (`setTaken`, `returnToSpawn`, `scatter`) already pools; the change is the
delay, the sight gate and indexing by placement instead of by tier.

**Scatter height**: `scatter` currently forces `Y = size/2`. Replace with a downward raycast against
`World.Geometry` from `position + 20 studs`, falling back to the object's `spawnCFrame.Y` when nothing is hit
(edge case in the spec). `scatterSpots` clamps to the world's `halfExtent`.

## R5. Out-of-sight rule (finding F-9)

**Decision**: pure `Respawn.canRespawn(args)` returns true only when `now ≥ respawnAt` **and** no watcher can
see the point, **or** `now ≥ takenAt + forceAfter`. A watcher is `{ position, heading }` where `heading` is
the unit horizontal ball velocity or nil when the ball moves slower than `Config.respawnHeadingMinSpeed`
(2 studs/s). A point is seen if its distance to the watcher is ≤ `respawnOutOfSightRadius` (45), or ≤
`respawnViewDistance` (120) and the angle between `heading` and the direction to the point is ≤
`Config.respawnViewCos` (0.5, i.e. 60° either side, a 120° cone; the number is the plan's, tunable in the grey-box gate).
The check uses a dot product against `respawnViewCos`, so no trigonometry in Rules.

**Server inputs**: ball part `Position` and `AssemblyLinearVelocity` for every session (including playerless
bot sessions). Cost: ~1,500 objects × ≤ 12 watchers only for objects that are `Taken` and due (a few per
tick); `WorldSpawner.update` scans the taken list, not the whole pool.

**Rationale**: the server has no camera; the ball's heading is what the player is about to see and is
anti-cheat safe (nothing from the client). Radius alone would let a camper far from the object but looking at
it see it pop in; the cone covers that.

**Starvation ceiling**: 180 s from `takenAt` (spec edge case), measured from absorption, not from the
scheduled respawn.

**Cluster refresh at run start**: `WorldSpawner.refreshCluster(slot, now)` returns `Taken` objects of that
slot's cluster to `Available` ignoring sight (the arriving player is the only intended watcher and the slots
are far apart); used by `BallService.resetBall` / Roll again. This is the spec's "personal-cluster" rule.

**Alternatives**: client-reported camera (trust boundary, Constitution II); raycast line of sight (cost, and
streaming-dependent on the server only for geometry which is complete there; rejected for being expensive for
little gain).

## R6. Client culling

**Decision**: `WorldCuller` (client) listens to `CollectionService` tag `WorldObject` (added/removed, so it
copes with streaming), groups parts into per-tier sets, and on each change of the local player's tier (from
`Tiers.lookup(Diameter, Worlds.tierLikes)` on the `Diameter` attribute of the local ball) toggles only the
tiers whose `Tiers.isCulled(objectTier, playerTier, Config.cullTierDelta)` result changed. A culled part:
`LocalTransparencyModifier = 1`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`. Restore sets
`LocalTransparencyModifier = 0` and `CanCollide/CanTouch/CanQuery = not Taken` where `Taken` is read from the
attribute (so a server-hidden part is never revived locally). It also listens to `Taken` changes for culled
parts only to keep the restore rule true.

**Rationale**: matches the spec's shrink edge case (knock-off from Tier 4 to 3 restores Tier 2 at once) and
avoids looping 1,500 parts per frame. Local-only changes to an anchored server-owned part do not replicate
and are allowed.

**Alternatives**: `Transparency` on the server (affects everyone); a per-frame loop (waste on phones).

## R7. Streaming (finding F-8)

**Decision**: in `default.project.json`: `Workspace.StreamingEnabled = true`, `StreamingMinRadius = 128`,
`StreamingTargetRadius = 512`, `StreamingIntegrityMode = PauseOutsideLoadedArea`. The ball is already the
`ReplicationFocus`. Spawn and hub teleports (`BallService.placeAtSpawn`) keep the ball frozen, call
`Player:RequestStreamAroundAsync(position, 5)` in a protected `task.spawn`, then continue (an unfrozen ball
at a freshly streamed point never falls through). Hub floor and spawn-pad ground are the largest parts and
stream first.

The numbers are the plan's starting point, not proven. **Spike (T003)**: with Studio's client in Play, teleport
between a spawn and the hub (460 studs apart) and read `Workspace.StreamingEnabled`, log whether the ground
under the ball exists on the client at unfreeze time, and watch for "pop-in" at 128 studs at ball speed 32.

Note: server scripts see everything; client code that did `WaitForChild("GreyBoxRoom"):WaitForChild("Cubes")`
and iterated children (BallController touch detection, StuckVisuals sizes) must tolerate parts that are not
streamed in (use the tag signals, `FindFirstChild`, never `WaitForChild` on a pooled part).

**Alternatives**: no streaming (full 1,500 + geometry replicated to every phone: memory and join time);
`ModelStreamingMode.Persistent` on everything (defeats the point); `Atomic` models for buildings (kept as an
option for the clock tower).

## R8. Mesh templates and the procedural fallback

**Decision**: `WorldBuilder.getTemplate(objectId)` creates one `MeshPart` per `objectId` with
`AssetService:CreateMeshPartAsync(Content.fromAssetId(id))` (yields; run once at start, wrapped in `pcall`)
and sets `TextureID` to the palette texture; placements clone it. If `Assets.meshes[assetKey]` is nil (not
imported yet) or the call fails, build a primitive part sized to `ObjectDef.size` (shape from a `fallback`
field: `Block | Ball | Cylinder`) coloured by tier swatch. The same code path serves the grey-box gate, offline
tests and a failed asset load; failures `warn` once per objectId (and the Studio spec asserts none occur in
the final build).

`StuckVisuals` clones the same template by `objectId` (it already receives the id in each stuck entry), so
there is one template per type on both sides. Mesh scale: the FBX is exported at 1 stud = 1 Blender unit
(scale 1, `apply transform`), and `Size` of the template is read once and compared with `ObjectDef.size`
(longest dimension) in the Studio spec; a deviation > 5 % fails.

**Spike (T004)**: `CreateMeshPartAsync` exists and works from a server script in Studio; `TextureID` is
assignable on the result. If not, the fallback is the importer-produced `MeshPart` inserted by the owner into
`ServerStorage.Templates` (a Rojo-unfriendly binary), which this plan rejects unless the spike fails.

**Alternatives**: `Instance.new("MeshPart")` and set `MeshId` (not writable from scripts); `SpecialMesh` in a
`Part` (extra instance per object, weaker batching).

## R9. Blender pipeline and CI without Blender (findings F-5, F-6)

**Decision**: three scripts in `art/scripts` run with `blender --background --python`:

1. `palette.py` writes `art/palette.png` (e.g. 256 × 256, an 8 × 8 grid of 32-px swatches) and
   `art/palette.json` (name → UV centre). One texture for all 65 meshes.
2. `export_all.py` opens each `art/source/*.blend`, for every collection named after an `objectId` applies
   transforms, checks that every face's UVs lie inside one swatch, triangulates a copy, counts triangles and
   exports `art/export/<id>.fbx` (flat shading, scale 1, forward/up axes fixed, no animation, no materials
   beyond the shared one). It writes `art/export/manifest.json`: `{ id, tier, triangles, bytes, sha256 }`.
3. `tri_report.py` prints the counts (developer aid).

`scripts/check.sh` gets a Lune step (`tests/unit/ArtManifest.test.luau`, plus a plain grep) that: reads the
manifest; checks every object in `Worlds.active.objects` has an entry whose `tier` and triangles satisfy
`Config.Budgets.meshTriangles[tier]` (hub entry against the tier-5 budget); checks each listed `.fbx` exists,
its size equals `bytes` and (via `shasum -a 256` run from check.sh, passed to the test) its hash matches;
checks `Assets.luau` meshes only contain keys the content uses; and greps `src` for `rbxassetid://` outside
`Assets.luau` (FR-007). With no Blender in CI the manifest is trusted because the hash binds it to the FBX it
describes and to the script that wrote both.

**Scripts check (FR-009)**: Studio-side, the import creates plain `MeshPart`s; a Lune/Luau check is not
possible for binary imports, so the final Studio task runs a read-only scan through the MCP
(`execute_luau`: `#template:GetDescendants()` filtered by `IsA("LuaSourceContainer")` equals 0 for every
template) and records the result in `playtest.md`. No Creator Store models are used at all in this plan.

**Blender MCP use**: interactive modelling only, one agent, claimed on the task; the committed `.blend` and
the export script are the source of truth, so a model can be rebuilt without the MCP.

**Workload shape**: one `.blend` per tier (`tier1_crumbs.blend` with 18 objects … `hub.blend`), not per
object, to keep file count and palette consistency manageable. Tier 1 uses very few triangles (≤ 300 allows
~150 quads), so Tier 1–2 meshes are modelled as simple primitives with a few bevelled details.

**Alternatives**: parse FBX in Lune (binary format, fragile); install Blender in CI (heavy, a new CI
dependency and approval); commit only the `.blend` and trust (no gate).

## R10. Importing meshes into Roblox (finding F-4)

**Decision**: owner session: Studio → Asset Manager → Bulk Import on `art/export/*.fbx` (and the palette PNG
through the Studio MCP `upload_image` tool if it accepts local files, otherwise the same bulk import). The
importer lists new Mesh IDs by file name; the owner (or an agent reading the Asset Manager through the Studio
MCP) gives the id list; an agent writes `Assets.meshes[<assetKey>] = "rbxassetid://…"` and the palette
texture ID. Until then the procedural fallback is used.

**Rationale**: no agent-accessible upload exists without an API key (Open Cloud) which is a new service and a
secret (Constitution X, XII).

**Alternatives**: Open Cloud Assets API from a script (needs an API key, new service, owner approval);
Studio's built-in mesh generation (`generate_mesh`) as a substitute for Blender (violates Constitution XI and
the approved plan).

## R11. Winter lighting and audio

**Decision**: lighting in `WorldBuilder.applyLighting(Worlds.active.lighting)`: sets `Lighting.Ambient`,
`OutdoorAmbient`, `Brightness`, `ClockTime`, `FogColor`, `FogStart`, `FogEnd` and creates or updates one
`Atmosphere` child (`Density`, `Color`, `Decay`), from data. Server-side, once at start (replicates).

Audio: `Assets.sounds.music` joins the existing set; `Feedback.start` creates one looping `Sound` in the
`Music` group (`Looped = true`, `Volume = 1`, group volume already driven by `settings.musicVolume`),
preloaded with the other sounds. Pickup pitch by tier, tier fanfare, bump and bell already exist and keep
their visual twins; the pickup uses `Worlds.objectById[objectId].tier` as today (works for 64 objects with no
change). Music starts on the first run state and keeps playing in the hub (it is the game's background).

**Sounds placeholder rule** (AGENTS.md): `rbxasset://` files may stream; the Play check reads `IsLoaded` and
`TimeLength` of every sound, and the music must be preloaded before `Play` (Feedback already preloads).

**Alternatives**: separate lighting initializer module (one function, no second user); per-run music
(restarts annoy players).

## R12. Test and measurement strategy

- **Lune**: `SnowVillage` (all FR-004 assertions, counts 18/16/14/12/4, unique ids, tier chaining,
  absorbability, coin ranges, asset/string keys, 12 spawn clusters, placement count and part budget, no
  overlaps from `Layout`), `Layout` (determinism, no overlap, count), `Respawn` (boundaries of radius, cone,
  delay clamp, starvation), `Pace` (R1), `Tiers.isCulled`, `ArtManifest`, `Config`, `Strings`.
- **Jest-Lua (Studio)**: pooled instances keep identity and child count across absorb → respawn; sight gate
  defers and later releases; 180 s ceiling forces; cluster refresh; scatter lands on ground (`Y > 0` case);
  `WorldCuller` hides Tiers ≤ player − 2, restores on shrink, never revives a `Taken` part; absorb by
  `objectId` works for two objects of the same tier; no module references `GreyBoxRoom` (a source scan).
- **Bot run (`BotRun.luau`)**: 12 playerless `BallService` sessions, each steered toward the nearest
  absorbable object (same rule as AGENTS.md "Driving the ball") for 240 s; reports per ball the final
  diameter, time to Tier 2, first-pickup time, counts of `Available` objects per tier at 60/120/180/240 s
  ("never runs dry" = every tier zone keeps ≥ 20 % available), part count, and console errors. The existing
  caveat applies: it must run as a script inside the playing server, not by `require` from the MCP.
- **Phone**: frame rate and part count at Tier 4 by the owner on the reference phone, recorded in
  `playtest.md` with the build commit; captures at 640 × 360, 844 × 390 and 1280 × 720 for Hud (new tier
  names), Book (18 cards) and Results.
- **Flags**: `Flags.SnowVillage = false` must still start the game with the grey-box room (smoke check in
  the final task).

## R13. Open numbers (all `Config` or data, none needs code)

| Number | Starting value | Settled by |
| --- | --- | --- |
| `respawnDelayMin / Max` | 60 / 120 | spec |
| `respawnOutOfSightRadius`, `respawnViewDistance` | 45, 120 | spec |
| `respawnViewCos` | 0.5 (60° half-angle) | grey-box gate |
| `respawnForceAfterSeconds` | 180 | spec |
| `respawnHeadingMinSpeed` | 2 studs/s | grey-box gate |
| `cullTierDelta` | 2 | spec |
| `spawnClusterRadius` | 45 | spec |
| Streaming min / target radius | 128 / 512 | T003 spike, phone check |
| Pool size / `maxActivePartsPerServer` | ~1,500 / 2,000 | R1 model, bot run, phone fps |
| `growthK` (Snow Village) | 0.6 unless R1 fails | owner after R1 |
| Landmark sizes | 28 / 34 / 40 / 48 | owner after 004d |
| Camera clamp, speed cap for large balls | unchanged | F-3 captures |

## Spike results (2026-10-26)

**Streaming (T004, partly done).** `default.project.json` now sets the four `Workspace` streaming properties and
Rojo 7.7.1 serialises it. In Play, `Workspace.StreamingEnabled` reads `true` on server and client. Parts do
stream out: with the replication focus parked 4,000 studs away the client dropped the room to 2 descendants;
at 700 and 1,400 studs they stayed (Roblox unloads lazily). **Not verified**: `StreamingMinRadius`,
`StreamingTargetRadius` and `StreamingIntegrityMode` cannot be read from a script in this Studio build (not a
valid member), so it is unproven that Rojo applied them, and the fallback in the contract (set them in
`WorldBuilder.start`) is unavailable for the same reason. The hub teleport works: after "Back to hub" the ball
rests on `World.Hub.Floor`, unanchored, no fall, with `RequestStreamAroundAsync` holding the ball first.
Pop-in at 128 studs at ball speed 32 cannot be judged from the API and is left to the owner's phone check.

**Pace (R1).** The model fails with `growthK = 0.6` (96 s to Tier 2, about 15 studs at 240 s) and passes with
1.5 (34 s, 63 to 71 studs). Snow Village sets `growthK = 1.5` as a provisional value for the owner to confirm.
Table of the modelled eater by `k`: 1.0 gives Tier 2 at 53 s and 32 to 38 studs; 2.0 gives 25 s and 83 to 86.

**Blender.** Blender 5.2.3 LTS is installed and its MCP addon (1.8, protocol 15) answers. The CLI binary is
`/Applications/Blender.app/Contents/MacOS/Blender`, not on `PATH`. The `mcp-for-blender` release in both MCP
config files is still unpinned (`uvx mcp-for-blender`), because the release number could not be looked up from
here.
