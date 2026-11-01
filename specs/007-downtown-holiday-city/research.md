# Research: Downtown Launch World (007)

Phase 0 decisions. Every point where the spec leaves a design choice open, or where reading the code contradicts
it, is settled here. Numbers marked **provisional** are starting values for the grey-box playtest; they live in
data (`Downtown.luau`, `Config`) and change without code edits. Coordinates: x east, z south, y up, origin at the
centre of the Plaza; "north" is negative z.

## R-01: World selection and rollback

**Decision.** `Config.Flags.Downtown = true`. `Worlds.active` becomes a three-way pick:
`Downtown` if `Flags.Downtown`, else `SnowVillage` if `Flags.SnowVillage`, else `GreyBoxRoom`. `Downtown` is
`require`d next to `SnowVillage` at the top of `Worlds.luau`; both stay loaded, since requiring is table building
only and the Lune tests need both.

**Rationale.** The 004 rollback path (flag off, previous world) is kept and extended by one step. No server or
client code names a world (the `GreyBoxRoom` guard in `check.sh` enforces it), so the switch is one line.

**Alternatives.** (a) Replace the `SnowVillage` flag with a `Config.ActiveWorld = "downtown"` string: a better
long-term shape, rejected now because three tests read `Flags.SnowVillage` and the change buys nothing for 007
(Principle XII). (b) Delete Snow Village: rejected, it is the rollback and the theme-system fixture.

## R-02: "Automatically unlocked" needs no profile code

**Finding.** `worldsUnlocked` is written by `DataService.buildDefaults` for **new** profiles and reconciled as a
table by `Profile.reconcile`, but **nothing in `src` reads it** (grep: `Config`, `Profile`, `DataService` only).
There is no world picker or gate to unlock.

**Decision.** Add `downtown = true` to `Config.DefaultWorldsUnlocked` and stop. No merge for existing profiles,
no migration, no `Profile.SCHEMA_VERSION` bump. When a later feature adds a world picker it must treat a missing
key as `Config.DefaultWorldsUnlocked[key]`; that is recorded in the contract, not built.

**Rationale.** Principle VIII: no schema change, no migration. A merge nobody reads is dead code (Principle XII).

## R-03: Asset keys are prefixed `dt_`

**Finding.** `Assets.meshes` is one flat table shared by every world. 15 Downtown ids already exist as Snow
Village mesh keys: `bauble`, `bench`, `bicycle`, `bus_shelter`, `cocoa_cart`, `fountain`, `gift_box`, `kiosk`,
`mailbox`, `market_stall`, `sleigh`, `snowman`, `snowplough`, `street_lamp`, `wreath`. Reusing those keys would
paint Snow Village's uploaded models onto Downtown objects, and uploading new ones under the same key would break
the rollback world. `ObjectVisual.buildMesh` also returns nil for a missing key and falls back to a stand-in, so
an unprefixed key looks like it works while showing the wrong model.

**Decision.** Object `id`s stay as the spec names them (`bench`, `wreath`, `snowman`…). Every Downtown `assetKey`
is `dt_<id>`, including the two hero variants (`dt_cocoa_truck`, `dt_glass_tower_bow`). The Blender collection
name, the `.fbx` file name, the manifest `id` and the `Assets.meshes` key are all that same `dt_` string. The
`bookId` is `downtown.<id>` and the `nameKey` is `object.downtown.<id>`, so ids can repeat across worlds without
colliding in the book or in Strings.

**Deviation.** FR-005 writes `assetKey = "cocoa_truck"` and `"glass_tower_bow"`. The prefix is applied
uniformly instead (spec deviation D4).

## R-04: Golden-spot representation

**Finding.** `Markers.validate` rejects any kind other than `BoosterSpot` and `TrapSpot`
(`marker kind … is …`), `WorldBuilder.buildMarkers` calls `error` on an unknown sub-kind, and `BoosterService`
filters on `BoosterSpot`. A `GoldenSpot` in `environment.markers`, as the spec asks, would crash world build today.

**Decision.** Keep the spec's shape: `kind = "GoldenSpot"`, `subKind = "golden"`, in `environment.markers`.
Three small code changes, all covered by tests:

1. `Rules/Markers`: a `GoldenSpot` marker needs no hazard row. Its footprint is the constant
   `Markers.GOLDEN_FOOTPRINT = { w = 6, d = 6 }`, it must be inside the world, off solid blocks and other markers
   (as every marker), and carry a covering `marker` keep-out. The coverage list gains "at least 5 golden spots" only
   when the caller asks for it (`opts.requireGolden`), so Snow Village's fixture is unchanged.
2. `WorldBuilder.buildMarkers`: `continue` on `GoldenSpot`. No part is built (Feature 012 spawns the object), so
   golden spots cost **0** parts.
3. `BoosterService` already filters on `BoosterSpot`; no change.

**Rationale.** Keeps one marker list and one validator (Principle VII); the alternative `goldenSpots` list on
`WorldDef` would add a schema field the spec does not name.

**Anchoring.** Three of the five hiding places in the design are absorbable objects (bus shelter, Ferris Wheel,
Tower Crane). A spot hung on an object floats once the ball eats it. So every spot's `y` is the top of **static
geometry** declared in `environment.blocks`: a bus-stop roof slab on Market Street (spot 1), the Car Park top deck
slab (2), the drain-tunnel floor (3), the crane's concrete ballast stack at the foot of the tower (4), a ticket-hut
platform behind the wheel (5). Spot 4 therefore sits on the crane's base ballast, not the jib counterweight,
which would be 50 studs up and unreachable below Tier 4 (spec deviation D2, owner to confirm).

## R-05: Part budget

`total = placements + blocks + built markers + HUB_PARTS(3) + 12 balls ≤ 2,000`, plus about 64 runtime parts from
006 (48 trail patches, 16 sweeper and bumper parts) that `SnowVillage.test` does not count but a Studio capture
sees.

| Item | Cap | Why |
| --- | --- | --- |
| Placements (winter, heaviest) | 1,395 | `maxPlacements = 1400` |
| `environment.blocks` | 400 | the existing `SnowVillage.test` cap; target ≈ 330 |
| Built markers | 9 minimum, 16 cap | 5 boosters + 4 traps, up to Snow Village's 16; golden spots build nothing |
| Hub + balls | 15 | 3 + 12 |
| Runtime (006) | 64 | trail pool + sweeper/bumper |
| **Worst case** | **1,890** | leaves 110 for animated hero child parts (R-13) |

`Downtown.test` asserts the first four sum to ≤ 2,000 − 64 in both themes.

## R-06: Layout authoring and the baked-offset method

**Decision.** Author `Downtown.luau` the way Snow Village was: small local helpers (`zone`, `block`, `spot`), a
catalogue table, per-spawn zones with a `spawnSlot`, district zones, and `fixedPlacements` for heroes, landmarks
and slot positions. `Layout.expand` places zone contents on a seeded grid (cell edge = 1.2 × the largest object
in the mix, `count` must fit the cell capacity). Where a slot must sit beside a porch or in a fountain, the offset
is **baked** into data from a one-off scratch search (as 004 did), never computed at require time. Add no layout
code.

**District map (planning-level, ± 20 studs; grey box moves things).**

| District | Ring | Rectangle (x, z ranges) | Notes |
| --- | --- | --- | --- |
| Market Street | 4 | x −150…300, z −12…12 | road, 8-stud pavements both sides (ring 2) |
| The Plaza | 4 | x −60…60, z −60…60 | static fountain basin; `slot.landmark` stands in it; 6 stall ring (winter) |
| The Park | 3 | x −290…−150, z −110…110 | lawns, pond (ice rink in winter), sledding slope (winter) |
| Construction Site | 3 | x 110…290, z −200…−70 | wedge ramps, container stack, crane base |
| Car Park | 3 | x 110…290, z 70…200 | three-level spiral of wedge ramps, top deck |
| Skyline Block | 5 | x −290…290, z −290…−200 | Tier 5 row; Glass Tower at x ≈ 0 |
| Waterfront | 5 | x −290…290, z 205…290 | promenade; Ferris Wheel at x ≈ 0 |
| Stoops and Alleys | 1 | 12 doorsteps (below) | 4-stud alleys; drain tunnel under Market Street at x ≈ −100 |

**Spawns.** Twelve doorsteps, three per quadrant, set back 30 to 60 studs from the Skyline and Waterfront
rows and the Park fence, so each is on a side street: `spawnSlot` 1…12 clockwise from the north-west. The design's
"rings" are a gradient, not concentric: Tier 1 at the 12 doorsteps, Tier 5 in the two bands, Tier 4 in the centre
(spec deviation D3, owner to confirm in grey box).

**Sightlines.** The spec (FR "every one of the 12 spawns has a declared `sightline` keep-out corridor") asks for
one per spawn: 12 `sightline` keep-outs, each an axis-aligned rectangle 12 studs wide and at least 80 long along
the spawn's side street, pointing at `glass_tower` (north, x ≈ 0) or `ferris_wheel` (south, x ≈ 0). Axis-aligned
rectangles, not diagonal rays, keep the keep-out maths as simple as Snow Village's; corridors of neighbouring
spawns may overlap, which `Layout` allows between keep-outs. `Downtown.test` asserts for each spawn that its
straight line to the landmark lies inside its own corridor, and that no base placement of Tier 4 or 5 other than
the landmark sits inside any corridor.

## R-07: Tier split and the 40-per-doorstep rule

**Finding.** 12 spawns × 40 Tier 1 objects = 480, the whole of the spec's Tier 1 target, and Sunny City has no
overlays, so the 40 must come from the base. Winter then adds Tier 1 crumbs on top.

**Decision (provisional).**

| | T1 | T2 | T3 | T4 | T5 | Total |
| --- | --- | --- | --- | --- | --- | --- |
| Base incl. slots | 480 | 330 | 230 | 150 | 55 | 1,245 |
| `winter` overlays | 60 | 50 | 25 | 14 | 1 | 150 |
| `winter` total | 540 | 380 | 255 | 164 | 56 | **1,395** |

Per doorstep: 32 core Tier 1 + 8 `slot.small` = 40 (the slot object counts in both themes, so `city` also passes).
Winter adds 5 crumb overlays per doorstep. Dressing slots: small 96, medium 30, yard 14, street 6, landmark 2 =
**148 = 10.6 %**, under the 15 % cap. The split differs from the spec's "rough 480 / 380 / 280 / 180 / 60" only
in Tier 1 (+60 in winter) and slightly in Tiers 3 to 5; the spec calls it rough, and `Layout` capacity plus the
pace model are the real limits (D5).

## R-08: Growth pace and `growthK`

**Decision.** `Downtown.growthK` is a number in `Downtown.luau`, solved with the pace model, never a guess.
`Pace.test` is generalised to take a world and a theme and runs Downtown in both `winter` and `city`
(plus the existing Snow Village run, unchanged). Starting point: 1.5, the Snow Village value; the model decides.
Targets asserted: first pickup ≤ 5 s; Tier 2 (D = 5) at 30 ± 20 s; Tier 3 (12) at 90 ± 20 s; Tier 4 (30) at
165 ± 20 s; D ≥ 80 by 240 s, from all 12 spawns. If one value cannot satisfy every spawn, the fix is zone counts
and positions (data), then `growthK`, in that order.

**Note.** `Config.growthK` (0.6) stays the default for worlds that set none.

## R-09: Themes: `clockTime`, bindings and the switch

**Decision.** `Themes.winter` changes `lighting(…, 2, 15.5, …)` to `16.5`; `Themes.test.luau:177` changes with
it. `SnowVillage` is unaffected apart from its rollback look (it resolves `winter` the same way). Both bindings
live in `Downtown.themeBindings` and follow the 005 contract: slot tiers must match, overlay ids must not clash
with base ids, hero variants stay within 10 % of the base size, and the `city` overlay set is empty.

**Book pages.** `downtown.winter` lists the 18 theme-only objects (5 slots + 13 overlays); `downtown.city` lists
the 5 slot objects. `Worlds` already builds both pages from `supportedThemes`. Hero variants are not listed
(their `bookId` is the base hero's). The spec's "20 holiday objects" = 18 + 2 variant meshes, so this is
consistent, not a conflict. Neither page declares a `reward` (`Worlds.luau` errors if one does).

## R-10: Tier rewards are left off

**Finding.** Snow Village gives every tier a `reward` (`snow_village.reward.tier{n}`, trail or skin). Cosmetics,
skins and the shop are out of scope (Features 006a/006b), and `RewardDef` is optional on `SizeTierDef`;
`Book` and `Profile` handle `nil`.

**Decision.** Downtown's tiers carry no `reward`, so no reward strings. Book pages still complete and show
progress. 006a adds rewards to `Downtown.luau` as data. Flag for the owner (D6): Downtown players earn no
cosmetic from the book at launch.

## R-11: The Mega Tree and the fountain

**Finding.** The design puts the Mega Tree (`slot.landmark`, Tier 5) "in the Plaza fountain", but `fountain` is
also a Tier 4 core object, and an absorbable fountain would leave the tree standing in nothing.

**Decision.** The Plaza fountain is **static scenery**: 3 to 4 `environment.blocks` (basin ring, water disc, pedestal).
The two `slot.landmark` fixed placements stand on the basin's pedestal and at the Waterfront's east end. The
absorbable core `fountain` (Tier 4, 13 studs) is placed on the Park's pond edge, the Waterfront promenade and two
side squares. In `city`, the Giant Duck floats on the same basin.

## R-12: Markers

**Decision.** 9 hazard markers minimum, targeting 12: boosters `dash` ×2, `magnet` ×1, `spring` ×1, `shield` ×1,
`slick_trail` ×1; traps `slick` ×2, `bumper` ×1, `slow` ×1, `sweeper` ×2 (one loop on the Plaza apron, one on the
Car Park forecourt), plus 5 golden spots. Footprints from `Content/Hazards.luau` (5×5, spring 8×8, slick and slow
14×14, bumper 4×4, sweeper 10×6). The `spring` is placed against the Construction Site container stack, which
gives a real use for a booster in this map (the stack top is a hop only a spring or a Tier 3 jump reaches). Each
marker needs a covering `marker` keep-out; the sweeper needs one per path segment. Positions are provisional and
live on bare ground (a block with top ≤ 0.2).

## R-13: Hero motion is not in the spec

**Finding.** The design asks for motion on several heroes (spinning chair, swaying Tube Guy, turning donut,
turning Ferris Wheel, swinging crane jib). None of it is in the spec's functional requirements.

**Decision.** Out of 007. Heroes are static meshes. Motion is a client-only tween on a child part, needs
multi-part models (Principle XI says one MeshPart per prop) and ~8 extra parts (R-05 reserves 110). It becomes its
own feature after the owner signs off the static look (spec deviation D7).

## R-14: Ambient pigeons

**Decision.** A small client module, `PigeonController`, spawns at most 8 anchored, non-colliding,
non-absorbable parts per district (Park, Plaza, Waterfront, Construction Site, Car Park = ≤ 40 total), each
flying off when a ball's distance drops under 12 studs, gone for good that run. They are never tagged as
absorbable objects and never replicated by the server. The module reads positions from a new
`Downtown.ambient.pigeons` list (`{ district, x, z }`, data) and is skipped when the list is absent, so Snow
Village needs nothing. Skipped entirely under `Reduce motion`. Their parts count against the client, not the
server budget; the 40 are inside the 110 spare.

## R-15: Art pipeline generalisation

**Finding.** `scripts/art-budgets.luau`, `art/scripts/budgets.json`, `ArtManifest.test`, `export_all.py` and
`build_objects.py` are written for Snow Village's 64 objects + `hub` (65 meshes).

**Decision.**

- `art-budgets.luau` builds `sizes` and `tiers` from the **union** of `SnowVillage.objects` and
  `Downtown.objects` plus both worlds' theme-only objects (keys `dt_<id>` for Downtown). `hub` stays.
  `scripts/art-sync.luau` rewrites `art/scripts/budgets.json`.
- `ArtManifest.test` loops both worlds' `objects` and theme objects; `#manifest.meshes` becomes the sum.
- New Blender source files `art/source/dt_tier1.blend`… `dt_tier5.blend` and `dt_theme.blend` (the 18 + 2 holiday
  meshes and the 5 Sunny City meshes). `build_objects.py` gains a `--world downtown` mode; the existing exporter
  already works per collection.
- Triangle budgets are already the stylised-real values in `Config.Budgets.meshTriangles`. "Locking" them means
  the playtest records the capture and the owner approves; the numbers move only if the capture fails.
- 94 core and holiday meshes (99 with Sunny City) is a lot of modelling. The plan therefore delivers art in
  waves by tier, each wave playable with stand-ins for the rest (US1 and US2 never wait for US3).

**What an agent cannot do.** Upload FBX to Roblox (Studio 3D Importer, GUI only) and approve a look. Those are
owner hand-off tasks, as in 004/005 (the plan's Delivery order marks them). Blender modelling itself can be done
by the agent through the Blender MCP tools and `art/scripts`.

## R-16: Strings

**Decision.** New en + es keys, no existing key edited:

- `object.downtown.<id>` for 74 core + 18 theme-only + 2 variant names (`cocoa_truck`, `glass_tower_bow`) + 5 `city`
  slot objects = **99**
- `tier.downtown.{1..5}.name` and `.headline` = 10
- `book.page.downtown.winter.name`, `.returning`, `book.page.downtown.city.name`, `.returning` = 4

Returning labels read like "Back for the holidays": no countdown, no "limited", no date (Principle V).
`Strings.test` and `SnowVillage.test`-style key checks gain a Downtown block.

## R-17: Existing studio specs that hard-code Snow Village

**Finding.** `RunManager.spec` expects `worldId == "snow_village"` and `"snow_village.acorn"` with Snow Village
growth maths; `ThemeSwitch.spec` expects `big_snowman` → `fountain`. Seven specs mention `snow_village`,
`acorn` or `Worlds.active`.

**Decision.** Specs read the world from `Worlds.active` and derive ids and expected sizes from it with the pure
`Growth` rule (no literals), so they pass for any active world. `ThemeSwitch.spec` checks Downtown's variant
(`donut_food_truck` → `dt_cocoa_truck` in winter, none in city). A first audit task lists all seven.

## R-18: Process and sign-off

**Decision.**

1. **Grey box first (Principle I).** US1 ships and is bot-tested with stand-ins only (no `Assets.meshes` entries).
2. Owner plays and signs the grey-box layout in `playtest.md` before any Blender wave starts.
3. US2 (themes) next: Holiday City is data plus stand-ins; sign-off captures the winter look.
4. US3 (meshes) in tier waves, each followed by an upload hand-off and a capture.
5. Final gate: a 640 × 360 capture with 12 balls in `winter`, ≥ 30 fps unthrottled, parts < 2,000, recorded with the
   triangle budgets in `playtest.md` and approved by the owner.

`AGENTS.md` rules apply to every Studio step: nothing may take over the owner's screen, 🔒 tasks are run through
the Studio MCP, and throttled seconds are reported separately.
