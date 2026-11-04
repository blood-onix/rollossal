# Research: Park City Map (Grey Box)

Six decisions, one per real unknown. Everything else follows the existing code. Facts below were read from the repo on
2026-11-04 (`Worlds.luau`, `WorldBuilder`, `WorldSpawner`, `AbsorbService`, `StuckVisuals`, `BallController`,
`Config`, the layout JSON, and `origin/010-main-street-slice`).

## R1 How the layout becomes content data

- **Decision**: a script, `scripts/park_city_world.py`, reads `docs/design/maps/park-city-layout.json` and writes three
  generated Luau modules under `src/shared/Content/Worlds/`:
  - `ParkCity.luau`: the `WorldDef` (palette, 71 non-hedge blocks, spawns, hub, lighting, tiers, stars, rules,
    object definitions, placeholders, fixed shots) and the Part placements as `fixedPlacements`.
  - `ParkCityParts.luau`: the 942 Tier 3–6 placements as compact rows.
  - `ParkCityLight.luau`: the 3,107 light objects (Tiers 1–2, including the maze's 119 hedge pieces) as one flat
    number array plus a kind list (stride 5: kind index, x, y, z, yaw; x, y, z rounded to 0.01).
  Each file starts with a "generated, do not edit" line. `python3 scripts/park_city_world.py --check` fails when the
  files differ from what the JSON would produce, and `scripts/check.sh` runs it (the same pattern as
  `design-tokens.py --check`). The step order is layout script → layout JSON → world script → world data.
- **Why Luau and not a Rojo JSON module**: Lune tests `require` Luau only, and `Worlds.luau` is already required by
  Lune tests (`Downtown.test`, `Pace.test`). A JSON module would make `Worlds` unloadable in Lune.
- **Size**: the layout JSON is 726 KB because every scene and trail item carries its own tier, bulk and name. The game
  needs only kind, position, height and facing per object, and one row per kind for the rest. Expected output is
  about 150 KB for the light file and 50 KB for the parts file. A flat number array avoids 3,107 nested table
  constructors (slow to parse, and near Luau's constant limits).
- **How the test proves the match** (`tests/unit/ParkCity.test.luau`): the test reads the JSON with `serde` and checks
  the generated modules against it:
  - the object count per tier equals `summary.objectsByTier`;
  - every JSON object (scene items, trail items, kerb items, landmarks) is found in the generated data at its
    position within 0.01 and the same kind; the counts of blocks, spawns, rails, pads, catapults, water and tunnels
    are equal;
  - every kind has `dims` equal to the JSON's, and its tier equals `Tiers.lookup(needsD)` for the six park tiers.
  This is G1 (world data) and G2 (world matches layout) in one test.
- **Hedges**: the layout lists the maze's hedge pieces both as blocks and as Tier 2 objects (119 each). The generator
  drops the hedge blocks and emits the objects only, with `solid = true`, so a hedge stops a small ball and is eaten by
  a big one. This keeps 119 parts off the server.
- **Object names (Principle IX)**: the world has 219 kinds, so each needs a name key. The generator writes
  `object.park.<id>` keys with English and Spanish text into `src/shared/Localization/ParkCityStrings.luau`, which
  `Strings.luau` merges. English comes from the id (`pine_cone` → "Pine cone"). Spanish comes from a name table in the
  script. The Spanish names are a first pass and go on `docs/release-candidate.md` for review.
- **Alternatives**: a runtime read of the JSON (not possible in Roblox, which has no file access). A hand-edited
  `ParkCity.luau` (rejected by FR-002). One big generated file (rejected: any edit to a sign would re-diff 200 KB).

## R2 Light objects (Tiers 1–2 as data)

- **Server state** (in `WorldSpawner`, no new module): parallel arrays indexed by light index (1..3,107) read from
  `ParkCityLight`: `state` (0 available, 1 taken), `respawnAt`, `takenAt`. A `pendingLight` set (as `pending` today)
  holds the taken indices, so the tick never walks 3,107 entries. Respawn uses the same `Respawn.canRespawn` sight
  rule, delays and starvation ceiling as parts. Nothing is a Part, so FR-021 holds by construction.
- **Light id**: the string `"L" .. index`. The existing `Absorb` remote already takes a string id, so no new request
  remote is needed. `tryAbsorb` and `tryBump` branch on the prefix. Both check the same things as today: run accepts
  pickups, `typeof == "string"`, a strict id pattern `^L%d+$` with an index in range, the rate limit, taken state, the
  distance from the ball to the **data** position (`radius + size/2 + absorbDistanceTolerance`), and the world's size
  rule. A bad index returns `UnknownObject`.
- **Reaching clients**: one new RemoteEvent, `LightDelta`, server to client only.
  - **At join**: the client already holds the static light data (shared module) and assumes all are available. The
    server sends one message with the indices currently taken. After a few minutes that is a few hundred numbers.
  - **After that**: the server collects changes during a frame window of 0.25 s and sends one message with two number
    arrays, `taken` and `restored`. At 12 players the traffic is bounded by the absorb rate (10 per second each), about
    120 numbers per second at the very worst.
  - **Interest filtering** is not needed at 12 players, and not built.
- **Client drawing** (`src/client/LightField.luau`, the one new client module): a spatial grid of 64-stud cells, built
  once from the shared data by `Rules/Light` (pure, two current users: the client's draw query, and the pace test's
  food search; the server's absorb verdict `Light.verdict` lives there too, so Lune tests can pin it). Every 0.2 s, or after moving 10 studs, the module:
  - queries cells within 120 studs of the camera;
  - drops objects culled by `Tiers.isCulled(objectTier, playerTier, Config.cullTierDelta)` and objects marked taken;
  - assigns the remainder to pooled Parts (cap 450; the nearest first), reusing Parts by changing `Size`, `Color` and
    `Shape`, and parenting unused ones to nil.
  Pool Parts get the attributes and tag that `BallController` already reads from pooled world objects (`Name` = light id,
  `Size`, `Tier`, `Taken`, plus `Bulk` and `Longest` for the world rule), so the ball's contact scan and its collision
  switch (`updateCollisions`) need no new path. `solid` objects (hedges) stay collidable until the ball can eat them.
  A claim for a light object the client never drew is still judged by the server's data.
- **StuckVisuals**: `parseStuck` already splits the placement id from `key#n`. `createVisual` looks the id up in
  `Worlds.placementById`; for ids starting with `L` it takes the kind from the light data instead
  (`Worlds.lightKind(id)`), then builds the visual through the same template path.
- **Alternatives**: one RemoteEvent per object (rejected by the brief). A per-client replicated folder of attributes
  (rejected: 3,107 instances). Server Parts with streaming (rejected: counts against the 2,000 budget before streaming
  helps, and the server still simulates them).

## R3 Per-world rules

- **Decision**: `WorldDef.rules` is optional world data. Downtown and Snow Village omit it and keep today's numbers.
  ```
  rules = {
    startDiameter = 1,
    growthK = 1.6,
    absorb = { mode = "bulk", ratio = 0.5, longestRatio = 1.5, garnish = 0.08 },
    speedCap = { base = 32, fromDiameter = 12, slope = 0.4, max = 56 },
    cameraMinDistance = 4,
  }
  ```
  `Worlds.luau` resolves it once into `Worlds.rules` with defaults from `Config` (`startDiameter`, `absorbRatio`,
  `growthK`, `speedCap`, `cameraMinDistance`). All call sites that read those `Config` values for gameplay move to
  `Worlds.rules`: `BallService` (start diameter, 3 sites), `WorldSpawner` (2), `KnockOff` (1), `AbsorbService` (2),
  `BoosterService` (magnet), `BallController` (3), `CameraController` (2), `RunManager` (final diameter). With no
  `rules` table every one of them returns exactly what it reads today.
- **Pure functions** (`src/shared/Rules`, all with Lune tests of fixed values):
  - `Absorb.canEat(rule, diameter, bulk, longest)`: true iff `bulk <= ratio * D and longest <= longestRatio * D`. In the
    size mode of today's worlds it keeps `size <= absorbRatio * D`.
  - `Growth.growByBulk(D, bulk, k, garnish)`: unchanged for garnish `0`; when `bulk < garnish * D` returns `D`.
  - `Movement.speedCap(D, rule)`: `min(max, base)` up to `fromDiameter`, then `base + slope * (D - fromDiameter)`,
    capped at `max`. `Movement.maxSpeed` already takes a cap, so the server ceiling becomes
    `max(Config.maxServerBallSpeed, cap(D) * 1.1)`. 32 up to D 12 is the same as today's `speedCap`; the rule only
    adds the rise. `BallGuard.verdict` is unchanged.
  - `HeapFit` (R4).
- **Object data**: `ObjectDef` gains optional `dims = {l, w, h}` and `bulk`. Pooled Parts carry `Bulk` and `Longest`
  attributes next to `Size`. A def without `dims` is a cube of `size`, so existing worlds behave the same.
  `ObjectVisual.standIn` sizes the stand-in to `dims` when present.
- **Stage A on Downtown** (flag `Flags.ReadableRules`, off): `Worlds.luau` applies a `readableRules` table that
  `Downtown.luau` already could carry as data: six tiers, stars 20/50/90, the rules above and a `dims` table for the
  few long thin objects (violin, lamp post, ladder, and the like; at most 30 entries, read from the design doc's 3.2
  table). Downtown's smallest object is 0.3, so a D 1 start has food. Object tiers are recomputed from `needsD`. Open
  point for Stage A's first task: `Budgets.meshTriangles` has five entries; Tier 6 needs a sixth (see `data-model.md`).
- **Alternatives**: a global flag that swaps `Config` numbers (rejected: Snow Village and Downtown would change, and
  the spec says they keep today's rules). Passing the rule table through every function (rejected: `Worlds.rules` is
  resolved once, like `Worlds.growthK` today).

## R4 The heap fix

- **Decision**: apply only the placement fix. Do not merge or cherry-pick feature 010's heap.
- **What 010 holds** (`origin/010-main-street-slice`, fetched): `Rules/Heap.luau` selects which stuck items stay
  outside (a score of size over age, with protected tiers first), computes how much of the sphere they hide, a core
  colour for the buried items, and a bury animation. It adds 160 lines to `StuckVisuals` and 10 `Config` keys, and
  depends on 010's other changes (`Hud`, `Worlds`, `BallController`, new `SceneKit` and `StreetRules`, 49 files in all).
  Its measured result is 30+ fps with 12 balls.
- **Why not**: it answers "which items to show" and not "how big and where an item sits". The owner's complaint was
  size: the heap looked three times its real size because items are placed on the surface by their longest side and
  stick out. 010's rules do not bound that, and the branch is unmerged and touches the files this feature changes
  (`Hud`, `Worlds`, `BallController`), so merging would bring a second set of conflicts for no gain on this problem.
- **What we build** (`Rules/HeapFit.luau`, pure): for a stuck item of dims `(l, w, h)` on a ball of diameter `D`, it
  returns the item scale and the offset along the surface normal:
  - scale so the longest side is at most `0.45 D`;
  - the long axis is tangent to the surface, the thinnest axis points along the normal;
  - the centre is pushed in so the item reaches at most `0.125 D` above the surface (the 1.25 D box);
  - the single newest catch with the largest bulk may reach `0.25 D` for 3 s (`Config.heapNewestGrace`), then eases
    to the normal fit.
  `StuckVisuals` calls it in `offsetFor`/`createVisual` and in `reseat` when the flag is on. `maxVisibleStuck` (30)
  and the tail rule stay. Tiers and the cap are not redesigned.
- **If G6 fails** with 12 balls, the fallback is 010's `Heap.select` cap on top of this fix. That would be a new
  decision recorded then, not now.
- **Flag**: `Flags.HeapFix` (default off) and `Flags.ParkCity`; `StuckVisuals` checks
  `Config.Flags.HeapFix or Config.Flags.ParkCity`, so Park City always has it.

## R5 Placeholders, kept inert

- **Decision**: `WorldBuilder` gets one function, `buildPlaceholders`, that reads `world.placeholders` and makes plain
  anchored Parts in a `Placeholders` folder. It has no behaviour: no scripts, no touch handlers, no attributes the
  game reads.

  | Layout item | Drawn as | Collides |
  | --- | --- | --- |
  | Rail / zipline (14) | thin Neon beam along `points`, small end posts | no |
  | Boost, bounce, spring, bullseye, lily pad (40 pads) | flat disc or square at `size`; lily pad is a slab at `y` | pads and bullseyes no; lily pads yes (they are the route) |
  | Catapult / slingshot (6) | base block plus an arm block at `restYaw` | base yes, arm no |
  | Water (stream, pond, sprinklers) | opaque blue slab 0.05 above the ground, over the ground block | no |
  | Tunnels (7), drains | already blocks with an opening in the layout | yes |

  Deep water: the ground block is one slab under the whole park, so the pond is already a floor. The water surface
  only paints it. Ice is a winter item and is not built.
- **Carrying 013's data**: the generated `placeholders` list holds the full layout record per item (rail `points`,
  `dMin`, `dMax`, `speed`, `exit`; pad `up`, `forward`, `dMax`; catapult `aimArc`, `range`, `apex`; water `depth`,
  `wadeFromD`). 013 reads the world data, not the Parts, so adding behaviour moves nothing. Each Part carries its
  placeholder id as `Name` and a `Placeholder` tag so 013 can find it. A test asserts counts and ids equal the layout.
- **Part cost**: about 14 × 3 + 40 + 6 × 2 + 3 ≈ 100 Parts, inside the budget in `plan.md`.
- **Alternatives**: no drawing at all (rejected by FR-005). Meshes (rejected: grey box, art is 015).

## R6 Fixed shots and the capture route

- **Decision**: camera positions live in `ParkCity.luau` as `shots = { { name, pos, look, fov } }`, generated by
  `park_city_world.py` from the layout: four quarter shots at spawns 1, 4, 7 and 10 (D 1 camera height, looking at the
  quarter's set piece), then Duck Island (`pond` landmark), the Hedge Maze (maze centre), the Roof Run, the Car Park,
  the Plaza and a high overview. `ParkCity.test.luau` pins the names and order and checks each position is inside the
  map. The existing `art/capture/cameras.json` (feature 009) is Downtown's and stays unchanged.
- **Capture route**: the Studio MCP `screen_capture` returns an image and cannot save a file (AGENTS.md, constitution
  gate 2), and the owner must see the shots where they can open them, so the primary route is offline rendering, the
  same Blender route feature 009 built: extend `scripts/capture-export.luau` with `--world parkcity`, so it resolves
  `ParkCity` instead of Downtown and writes the JSON (blocks, parts, light objects at their rows, placeholders and shots)
  that `art/scripts/capture_render.py` renders. Output PNGs go to `specs/012-park-city-map/shots/`.
  - Studio is used for the playtest (G7) and for inline checks with `screen_capture`; a Studio capture is a second
    opinion, never the only image set.
  - If the Blender route fails twice, per the constitution the agent asks the owner once to keep Studio in front and
    tries the Studio capture; this is the "another route" the gate allows, in the other order.
- **Risk to check in the first task of Stage D**: `capture-export.luau` and `capture_render.py` are written for
  Downtown's data shape (zones plus placements, one theme). A light-object row and a placeholder need a draw rule
  there. If that is more than about 60 lines, the fallback is a second small script, `scripts/park-capture-export.luau`,
  that writes only boxes by `dims` for blocks, parts and light objects. Both stay grey box.
