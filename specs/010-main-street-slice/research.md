# Research: Main-Street Slice (010 / backlog 004i)

Phase 0 decisions. Every spec "locked in the plan" item is settled here. Numbers are plan defaults and are listed
as confirm items in `plan.md` ("Spec deviations and defaults to confirm"). No `NEEDS CLARIFICATION` remains.

## R-01 Slice dimensions and zone layout

- **Decision**: The slice is 200 studs wide (x in [-100, 100]) and 500 studs long (z in [-250, 250]). The player
  starts at the -z end and rolls toward +z. Zones along z: park [-250, -130], suburb corner [-130, -60], main street
  [-60, 170], skyline backdrop [170, 250]. The carriageway is 30 studs wide along z, with 6-stud sidewalks and facade
  rows on both sides. There are two cross-street junctions (z = 10 and z = 110), each with zebra crossings. The skyline
  is tier 5 landmarks plus backdrop towers beyond the street end, visible from the park.
- **Rationale**: 200 x 500 is the spec's range. The park is 120 studs deep, which fits 12 spawns at 10+ studs apart
  with room to roll. The street is 230 studs long, which fits 4 bays of 6 studs per 24 studs of frontage per side
  with two junctions.
- **Alternatives**: A square map (rejected: it breaks the "street ahead, skyline in sight" read). A winding street
  (rejected: more rule complexity for no gain in a slice).

## R-02 Square clamp in `WorldSpawner` versus a rectangular world

- **Decision**: Set `halfExtent = 250` (the long axis). Keep the 200-wide limit with invisible `Boundary` blocks at
  x = +-100 and z = +-250. Do not change `WorldSpawner.scatterSpots`. The slice builds no scattered zones (all
  placements are fixed), so the square clamp never sees the empty x range.
- **Rationale**: `scatterSpots` clamps to `halfExtent - 2` on both axes. With only fixed placements, nothing scatters.
  `Boundary` blocks already exist in `WorldDef.environment.blocks`.
- **Alternatives**: Add `halfExtentX/Z` to `WorldDef` (rejected: it touches every world and the clamp consumers for
  one slice).

## R-03 World selection and the pinned `Worlds` chain

- **Decision**: Add `Config.Flags.MainStreetSlice` (default `false`). It outranks Downtown:
  `if Config.Flags.MainStreetSlice then MainStreetSlice :: any elseif Config.Flags.Downtown then ...`. Update the two
  tests that pin the chain (`Config.test.luau` around lines 357-372 and `Downtown.test.luau` around line 1039) in the
  same task, and add a new assertion for the slice branch.
- **Rationale**: The chain is a single readable expression. A second statement would let `active` be assigned twice
  and hide precedence. The two tests are string pins, so they are updated deliberately and noted in the plan.
- **Alternatives**: A wrapper statement after the chain (rejected: duplicates `active` and hides the precedence). Making
  Downtown lower than the slice by leaving it off in config (rejected: a flag combination must resolve the same way
  every time).

## R-04 Placement production for a rule-built world

- **Decision**: `Content/Worlds/MainStreetSlice.luau` is a data module with a build step at require time. It calls
  the pure `Rules/StreetRules` and `Rules/SceneKit` expansions and emits `fixedPlacements` (ids unique) and
  `environment.blocks`. `activeThemeId = "city"`, `supportedThemes = {"city"}`, and `themeBindings.city` has
  `slots = {}`, empty overlays and no `bookPage` reward. `maxPlacements = 1200`.
- **Rationale**: `ThemeResolve` accepts fixed placements without zones and enforces unique ids and the cap. 1,200 is
  under the 1,500 default and leaves room under the 2,000-part server budget (with 12 balls, see R-09).
- **Alternatives**: Zones with slots (rejected: random placement is exactly what the spec replaces). Computing
  placements on the server at startup only (rejected: clients need identical data to resolve `Worlds.placementById`).

## R-05 Rules modules are self-contained

- **Decision**: New pure modules `Rules/StreetRules.luau`, `Rules/SceneKit.luau` and `Rules/Heap.luau`. They do not
  require siblings by `script`. Shared helpers (the seeded generator, yaw rotation) are duplicated or passed in as
  arguments. Content modules and tests inject the dependencies (as `ThemeResolve` does with `expand`). The seeded
  generator is Park-Miller (48271 / 2147483647), the same constants as `Layout`.
- **Rationale**: Constitution III and the `check.sh` purity grep forbid `require(script`. Lune tests can then
  hand-compute expected values.
- **Alternatives**: A shared `Rules/Rng.luau` required by name (rejected: needs `require(script.Parent...)`, which the
  grep forbids).

## R-06 Street rule set

- **Decision**: `StreetRules.expand(def, ids)` takes street segments, junctions and an `ids` table of object ids and
  returns `{ blocks, placements }`. Rules (from `docs/design/08-style-bible.md`):
  kerb band 0.4 stud high; sidewalk at least 6 studs wide; asphalt darker than the sidewalk; centre line and lane lines
  (1-stud stripe, 1-stud gap); zebra crossing at every junction; a tree every 18 studs and a lamp every 24 studs, with a
  lamp never within 4 studs of a trunk (the lamp shifts along the line to clear it); a bin at every corner; benches
  facing the road; cars parked parallel to the kerb (yaw = segment yaw or +180). Jitter is seeded, at most +-0.5 stud
  position and +-3 degrees yaw. There is no random full-circle yaw.
- **Rationale**: This is the FR-005 list and the style bible numbers. Determinism comes from the seed (SC-005).
- **Alternatives**: Hand-authored placements (rejected: not reusable by 004j).

## R-07 Scene kits

- **Decision**: `Content/SceneKits.luau` holds the 10 kits as data (`picnic_spread`, `cafe_terrace`, `bus_stop`,
  `fruit_stall`, `bike_rack`, `road_works`, `car_park_rows`, `yard_sale`, `flower_bed`, `recycling_point`). Each kit is
  a list of `{ objectId, dx, dz, yaw }` entries in kit-local space with a footprint (`halfX`, `halfZ`). `Rules/SceneKit`
  rotates entries by the instance yaw, adds the origin, applies seeded jitter, and rejects any entry outside the
  footprint or the world bounds.
- **Rationale**: Kits as data with a pure expander meets FR-006/FR-008 and is testable (all objects known, inside
  bounds).
- **Alternatives**: Kits as Luau functions (rejected: not data, hard to validate).

## R-08 Object stand-ins for props not in the 99-prop catalogue

- **Decision**: The slice owns its own `ObjectDef`s for objects with no catalogue match (`shop_front`, `fruit_crate`,
  `flower_pot`, `picnic_blanket`, `awning`, plus `road_works` barriers). `assetKey` points to an existing `dt_*` mesh
  where one fits (`dt_corner_shop_row`, `dt_pallet_stack`, `dt_potted_palm`) and otherwise is `""`, so `ObjectVisual`
  falls back to coloured stand-in parts. The 009 bake-off meshes are not uploaded, so they cannot be referenced.
  Real 004h meshes swap in by changing `assetKey` data only (FR-004).
- **Rationale**: Uses the existing swap mechanism. No new asset upload is needed to ship the slice.
- **Alternatives**: Wait for 004h (rejected: blocks the slice). CC0 or Creator Store (rejected: the owner declined).

## R-09 Ball heap approach

- **Decision**: The default design combines two options and is confirmed by measurement at 12 balls:
  - **B** (content-coloured core): the base sphere's colour is set to the average palette of buried items, so a thinly
    covered ball does not look bare.
  - **A** (outer shell cap): `Rules/Heap.select(entries, cap)` chooses which entries stay as welded visuals. Score =
    size-weighted recency. Tier 4+ items are protected (milestones). Others are buried by shrinking to the core over a
    few frames (no pop).
  - Caps in `Config`: `heapLocalCap = 40`, `heapRemoteCap = 12`, `heapScaleExponent = 1.0` (attachments scale
    linearly with the ball), `heapCoverageTargetD = 5` and `heapCoverageTarget = 0.6` (SC-003).
  - The candidates compared in `playtest.md`: (1) raise `maxVisibleStuck` only (baseline), (2) A, (3) A+B,
    (4) A+B with remote LOD (C), (5) merged lumps (D). Measure parts, triangles, draw calls and fps with 12 balls.
    The default is A+B+C unless a measurement says otherwise.
- **Rationale**: FR-013 requires comparison, not just raising the cap. A+B keeps part count bounded. C is the only
  way 12 balls fit the budget.
- **Alternatives**: D (merging into lumps) needs mesh combination that EditableMesh cannot do in Play, so it is
  measured only if A+B+C misses the budget.

## R-10 Where the heap choice is computed

- **Decision**: Client-side from the server's `Stuck` data. `BallService.publishStuck` publishes a longer tail
  (`Config.maxPublishedStuck = 60`, up from `maxVisibleStuck = 30`) in the same attribute format. The server remains
  authoritative for what is stuck (size, score). No new remote.
- **Rationale**: Constitution II is met (the server owns state, the client only presents it). Attribute payload is
  60 entries x about 20 bytes, well under the attribute limit.
- **Alternatives**: A server-computed outer set (rejected: more replication, and per-client LOD differs).

## R-11 Too-large contact bump

- **Decision**: Client-side in `BallController.contactScan` / the collision path. On contact with a part whose size
  fails `Absorb.canAbsorb`, apply an immediate `AssemblyLinearVelocity` change away from the contact point and play
  `Assets.sounds.bump`. A cooldown `Config.tooLargeBumpCooldown = 0.4` s per ball. No text, no HUD. Gated by
  `Config.Flags.SliceHud`. The existing `BumpRemote` server flow and `bumpCooldown` stay unchanged.
- **Rationale**: US3 asks for immediate physical feedback. The server cannot add latency to it. Changes only the
  local ball's velocity, which the client already owns. The server still validates absorb and knock-off.
- **Alternatives**: Server-driven bump (rejected: latency). Reusing `bumpCooldown` (rejected: 1.0 s feels dead).

## R-12 HUD simplification

- **Decision**: With `Config.Flags.SliceHud` on, `Hud` does not create `NextTier`, `Star1..n` and `TierBanner`.
  Timer and size readout stay, and the `METER` offsets are reviewed. With the flag off the legacy path is byte-for-byte
  unchanged. `SliceHud` is set to the same value as `MainStreetSlice` in `Config`, but kept as a separate flag so the
  HUD can be tested on other worlds.
- **Rationale**: Keeps legacy tests and `Strings.test` keys valid.
- **Alternatives**: Deleting the elements (rejected: breaks the other worlds).

## R-13 Ambient controllers on the slice

- **Decision**: The slice sets `ambient = { pigeons = <small>, traffic = nil }`. `PigeonController` and
  `TrafficController` start under `Config.Flags.Downtown`; the plan changes the start condition to
  "world has `ambient`" so the slice can opt in or out by data. Default: pigeons on (a few in the park), traffic off
  (parked cars only).
- **Rationale**: Moving moving cars adds physics risk and a part budget; parked cars cover the street read.
- **Alternatives**: Run Downtown's full ambient (rejected: budget).

## R-14 Signs, billboards and the atlas

- **Decision**: `Content/Signs.luau` holds `SignSlot` and `BillboardSlot` tables. `Config.billboardTextureCap = 6`.
  `Assets.luau` gains `facadeAtlas = ""` and `billboards = { b1 .. b6 }`, all `""` until the owner uploads. A sign slot
  names an `atlasRegion` (data); the shared facade/sign atlas is one image. Shop names are invented proper nouns
  (Constitution IV allows these without localisation keys). A banned-word and real-brand list lives in the test.
  `sponsored = false` on every billboard.
- **Rationale**: One facade/sign atlas plus a capped set of 6 billboard textures meets XI. Empty ids make the
  renderer use flat colours, so the slice works without uploads.
- **Alternatives**: Generating the atlas in `palette.py` (rejected for this feature: it would change a
  determinism-checked script; deferred to the owner upload hand-off).

## R-15 Capture route

- **Decision**: `art/capture/cameras-slice.json` holds the 5 slice shots (`01_spawn_d2`, `02_street_d5`,
  `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`) with the same camera-distance-by-diameter rule as
  `cameras.json`. `scripts/capture-export.luau` gains a `--world slice` option. A new `CaptureCamerasSlice.test.luau`
  pins the file. `cameras.json` and its test are untouched. The primary route is Studio `screen_capture` (image only).
  If it fails, ask the owner once, then use the offline Blender route (`art/scripts/capture_render.py`).
- **Rationale**: The exporter is coupled to Downtown; a selector is the smallest change.
- **Alternatives**: Editing `cameras.json` (rejected: its test pins the Downtown shots).

## R-16 Benchmark protocol

- **Decision**: Reuse `tests/studio/HeavyScene.server.luau`, `HeavySampler.client.luau` and `BotRun.server.luau`,
  extended to load the slice world and spawn 12 balls. Run at 640x360. Record per-second samples. Seconds at exactly
  15 fps are reported as "throttled" and excluded. Pass: 30 fps or more on unthrottled seconds, under 2,000 parts, and
  zero console errors or warnings. Results go in `specs/010-main-street-slice/playtest.md`. Phone fps goes to
  `docs/release-candidate.md`.
- **Rationale**: Matches AGENTS.md and constitution VI.
- **Alternatives**: A new harness (rejected: Constitution XII).

## R-17 Config keys and test impact

- **Decision**: New `Config` keys: `Flags.MainStreetSlice`, `Flags.SliceHud`, `Flags.HeapRedesign` (all `false`),
  `billboardTextureCap`, `heapLocalCap`, `heapRemoteCap`, `heapScaleExponent`, `heapCoverageTargetD`,
  `heapCoverageTarget`, `maxPublishedStuck`, `tooLargeBumpCooldown`. `Config.test.luau` gets pins for each.
  `DefaultWorldsUnlocked` is left alone (selection does not read it).
- **Rationale**: Content and tuning are data (VII). All new behaviour sits behind flags.
- **Alternatives**: Literals in modules (rejected by VII).
