# Implementation Plan: Downtown Launch World — Core City Kit, Holiday City (`winter`) and Sunny City (`city`)

**Branch**: `007-downtown-holiday-city` | **Date**: 2026-10-31 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-downtown-holiday-city/spec.md`

## Summary

Replace Snow Village with Downtown as the launch world: a 600 × 600 stud playable city with 74 core objects in five tiers,
a December theme (Holiday City, `winter`) and a January theme (Sunny City, `city`) that switch by changing one
data field. Snow Village stays in the repo as the rollback world. Four strands, in dependency order:

1. **Selection, rules and Config (Luau, Lune-tested)**. `Worlds.active` becomes a three-way pick behind a new
   `Flags.Downtown` (Downtown, else Snow Village, else the grey-box room). `DefaultWorldsUnlocked` gains
   `downtown` (nothing reads it, so there is no profile merge or schema bump, research R-02). `Rules/Markers`
   learns the `GoldenSpot` kind (fixed 6 × 6 footprint, optional "at least 5" check) and `WorldBuilder` skips it,
   so golden spots cost no part (R-04). `Themes.winter.clockTime` moves from 15.5 to 16.5 (R-09).
2. **Grey-box layout (US1)**. New `Content/Worlds/Downtown.luau`: 12 doorstep spawns with 40 Tier 1 objects each,
   district zones, 74 objects with `dt_`-prefixed asset keys (R-03), static scenery blocks, 12 sightline
   keep-outs to the Glass Tower and the Ferris Wheel, 9 to 12 hazard markers and 5 golden spots, all as data.
   `Pace.test` and the part-budget test run on it in both themes; `growthK` is solved with the pace model (R-08).
   Stand-in parts only: no `Assets.meshes` entry is needed.
3. **Themes and strings (US2)**. `themeBindings` for `winter` (5 slot objects, 13 overlays, 2 hero variants,
   150 placements) and `city` (5 slot objects, no overlays); 99 object, 10 tier and 4 book-page strings in en and
   es; the book page `downtown.winter` survives the switch to `city`. `PigeonController` adds ambient pigeons
   from data (R-14).
4. **Art and performance lock (US3)**. The art scripts are generalised to both worlds (R-15). Meshes are modelled
   in Blender in seven waves A to G (99 meshes: 94 for launch, 5 Sunny City slots that may defer), each followed
   by an owner upload hand-off, then a 640 × 360, 12-ball capture at ≥ 30 fps with parts < 2,000.

No remote, no DataStore field, no new tool and nothing sold. Hero motion is out of scope (R-13).

## Technical Context

**Language/Version**: Luau (`--!strict`, Roblox, Rojo 7.7.1, luau-lsp strict) for game code and tests. Python 3
and Blender for the art scripts and `.blend` sources, as in features 004 and 005.

**Primary Dependencies**: none new. Existing Rokit toolchain (StyLua, Selene, luau-lsp, Lune 0.10.x, Rojo),
Jest-Lua in `tests/studio`, Roblox Studio MCP, Blender MCP and `art/scripts`.

**Storage**: none. No DataStore key, no `Profile` field, no `SCHEMA_VERSION` change. `worldsUnlocked.downtown`
is a default for new profiles that nothing reads yet (R-02).

**Testing**: Lune unit tests in `tests/unit` (new `Downtown`; extended `Config`, `Themes`, `Pace`, `Markers`,
`ArtManifest`, `Strings`); Jest-Lua specs in `tests/studio` (`RunManager`, `ThemeSwitch` made world-agnostic; five
more specs audited, R-17); agent-driven Studio bot playtests across all 12 spawns in both themes; 640 × 360
captures; the owner's sign-off in `playtest.md`.

**Target Platform**: Roblox, mobile first (30 fps on the mid-range reference phone), 12 players per server.

**Project Type**: Roblox game (single Rojo project) with an offline Blender art pipeline.

**Performance Goals**: ≥ 30 fps unthrottled in a 640 × 360 Studio capture with 12 balls in `winter`; first
pickup ≤ 5 s; Tier 2 at 30 ± 20 s, Tier 3 at 90 ± 20 s, Tier 4 at 165 ± 20 s, D ≥ 80 by 240 s from every spawn.

**Constraints**: `src/shared/Rules` has no Roblox API and no clock or random; active server parts stay under
2,000 (worst case 1,890, R-05, asserted per theme by `Downtown.test`); every `assetKey` is `dt_<id>`; one
material and one MeshPart per prop, atlas UVs, triangle budgets from `Config.Budgets`; no new remote; every
string in en and es; no "limited", countdown or date wording; no absorbable people or animals; dressing slots
≤ 15 % of placements (148, 10.6 %).

**Scale/Scope**: 1 new world module; 1 new client module; 1 new test file; 74 core objects + 18 theme-only
objects + 2 hero variants + 5 Sunny City slot objects (99 meshes); 1,245 base placements, 150 winter overlays;
about 330 scenery blocks; 12 spawns; 12 sightline corridors; 9 to 12 hazard markers + 5 golden spots; 113 new
strings per language; 1 new flag.

## Constitution Check

*GATE: passed before Phase 0; re-checked after Phase 1 (below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | Pass | US1 ships with stand-in parts only and a bot-played pace test; the owner signs the grey-box layout in `specs/007-downtown-holiday-city/playtest.md` before any Blender wave starts (Delivery order, rows 12 to 13). Every pace number is data. |
| II Server authority | Pass | No new remote. Layout, markers and golden spots are server-built world data; the ball physics and `BallGuard` are untouched. `PigeonController` is client-local decoration the server never replicates or trusts. |
| III Pure, tested rules | Pass | The only rule change is `Rules/Markers` (pure data validation, constants as arguments). `Downtown.test` validates the layout with the existing pure `Layout`, `Growth`, `Pace` and `ThemeResolve` rules. The `Rules` purity grep in `check.sh` is unchanged. |
| IV Safe for everyone | Pass, one flag | No absorbable people or animals, no gore, no words on textures; pigeons are decorative and unabsorbable. The `light_up_reindeer` is a wire-frame lamp, not an animal model, and is flagged for owner review (see below). Hero meshes are checked against the per-object safety list in `contracts/art-and-strings.md`. |
| V Ethical monetization | Pass | Nothing sold. Holiday objects are labelled "Back for the holidays": no "limited", countdown, date or FOMO wording, enforced by a `Strings.test` scan of the new keys. No cosmetic reward ships (D6). |
| VI Mobile first | Pass | 30 fps at 640 × 360 with 12 balls is a gate (US3); parts worst case 1,890; first pickup ≤ 5 s by test; pigeons are skipped under Reduce motion; no new HUD or touch target. |
| VII Content is data | Pass | The world, both themes, spawns, zones, markers and pigeons are tables in `Downtown.luau`. The January switch is `activeThemeId = "city"` with no code change, proven by `ThemeSwitch.spec` and `Downtown.test`. `Flags.Downtown` gives the rollback. |
| VIII Player data | Pass | No profile, DataStore or schema change (R-02). The only touch is a default table read by nothing. |
| IX Strings | Pass | 99 object, 10 tier and 4 book-page keys in en and es (R-16); `Strings.test` extended with a Downtown block that checks both languages and every `nameKey`. |
| X Multi-agent | Pass | Own branch. `[P]` tasks touch disjoint files (Delivery order). Studio and Blender tasks claim that tool in `tasks.md`, and 🔒 tasks are run through the MCP without touching the owner's screen (AGENTS.md). No live publish. |
| XI Asset pipeline | Pass | Stylised-real meshes from Blender: atlas UVs, one material, split normals, `Config.Budgets` triangle caps, asset ids only in `Assets.luau`. `dt_` keys stop Downtown from colliding with Snow Village meshes (R-03). Uploads are owner hand-offs because Studio's 3D Importer is GUI-only. |
| XII Keep it lean | Pass | No new tool, package or remote. The art scripts are generalised, not duplicated; `Layout` and the pace model are reused as they are. One small kind (`GoldenSpot`) and one small client module (`PigeonController`); see Complexity Tracking. |

**Human Approval Required**:

- Hero meshes and the `light_up_reindeer` lamp: the owner confirms the look in the wave captures (Principle IV).
- Spec deviations D1 to D7 below.
- The App Store and Roblox maturity questionnaire is unaffected (no new interaction type), but the owner re-checks
  it if the reindeer is ever modelled as an animal.

### Post-design re-check (after Phase 1)

Unchanged: all rows still pass. Points checked against the design: (a) the `GoldenSpot` kind adds one branch to a
pure rule and one `continue` to `WorldBuilder`, with no part and no remote (R-04); (b) winter's part total is
1,395 + 400 + 16 + 15 + 64 = 1,890 < 2,000, and `Downtown.test` asserts the first four terms; (c) every id, key and
string pattern keeps Snow Village and Downtown disjoint (`dt_`, `downtown.<id>`, `object.downtown.<id>`); (d) the
tier split sums to the totals in `data-model.md`.

## Spec deviations to confirm

These resolve conflicts between the spec text and the code, the design docs or the constitution. None changes an
owner decision. D1 to D4 need a one-line spec edit if accepted.

- **D1: spring-pad placement is researched, not copied.** The design leaves it to Downtown. The `spring` marker
  sits against the Construction Site container stack, where a real hop is needed (R-12). Coordinates come from a
  scratch search in the task phase.
- **D2: golden spot 4 sits on the crane's base ballast, not the jib counterweight.** The jib counterweight is
  about 50 studs up and unreachable below Tier 4. Every golden spot is anchored on static `environment.blocks`
  geometry so it cannot float when an absorbable object is eaten (R-04).
- **D3: the layout is a gradient, not strict concentric rings.** Tier 1 at 12 doorsteps, Tier 5 in the Skyline and
  Waterfront bands, Tier 4 in the centre. The owner confirms the feel in the grey-box playtest (R-06).
- **D4: `assetKey` is `dt_cocoa_truck` and `dt_glass_tower_bow`, not `cocoa_truck` and `glass_tower_bow`.**
  FR-005 writes the unprefixed form; 15 Downtown ids collide with existing Snow Village keys in the flat
  `Assets.meshes`, so every Downtown key is prefixed uniformly (R-03).
- **D5: the tier split differs slightly from the rough 480 / 380 / 280 / 180 / 60.** Provisional result is 540 /
  380 / 255 / 164 / 56 = 1,395 in `winter`, 1,245 in `city`, because 12 × 40 Tier 1 objects fill the spec's whole
  Tier 1 target from the base layout (R-07). The pace model and `Layout` capacity are the limits that matter.
- **D6: no tier rewards at launch.** Snow Village gives each tier a trail or skin; cosmetics are Features 006a and
  006b. `RewardDef` is optional, so Downtown tiers carry none and book pages still complete (R-10).
- **D7: hero motion is deferred.** The design asks for a spinning chair, swaying Tube Guy, turning Ferris Wheel
  and swinging crane jib. None is in the spec; each needs multi-part models and extra parts. Heroes are static
  meshes in 007 (R-13).
- **Also changing, no owner decision involved**: `Themes.winter.clockTime` 15.5 → 16.5 with `Themes.test`
  line 177; `Config.test` default-unlock and flag checks; `Pace.test`, `ArtManifest.test` and
  `scripts/art-budgets.luau` generalised from Snow Village to both worlds; two studio specs made world-agnostic
  (R-17); the Plaza fountain and the garland and slope scenery are plain `environment.blocks` (R-11); the
  absorbable `fountain` goes on the pond edge, Waterfront and side squares.

## Project Structure

### Documentation (this feature)

```text
specs/007-downtown-holiday-city/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R-01 … R-18
├── data-model.md        # Phase 1: WorldDef, tiers, 74 objects, themes, spawns, zones, markers, pigeons
├── quickstart.md        # Phase 1: how to prove it end to end
├── contracts/
│   ├── rules-and-code.md      # Worlds, Markers, WorldBuilder, Config, Themes, PigeonController, tests
│   ├── world-content.md       # Invariants C1 … C18, naming rules, pace contract
│   └── art-and-strings.md     # Mesh rules, waves A to G, owner hand-off, strings, safety checklist
├── playtest.md          # Owner sign-off (created during implementation, Principle I)
├── captures/            # 640 × 360 captures per wave and the final fps run
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
src/shared/
├── Config.luau                               # + Flags.Downtown, DefaultWorldsUnlocked.downtown
├── Assets.luau                               # dt_* mesh ids as waves are uploaded (owner hand-off)
├── Worlds.luau                               # three-way active pick; Downtown required beside SnowVillage
├── Content/
│   ├── Themes.luau                           # winter clockTime 16.5; optional ambient field
│   ├── GreyBoxRoom.luau                      # types: GoldenSpot kind, optional ambient.pigeons
│   └── Worlds/
│       ├── SnowVillage.luau                  # unchanged (rollback world)
│       └── Downtown.luau                     # NEW: layout, objects, tiers, themeBindings, markers, pigeons
├── Rules/
│   └── Markers.luau                          # GoldenSpot kind, GOLDEN_FOOTPRINT, opts.requireGolden
└── Localization/Strings.luau                 # + 99 object, 10 tier, 4 book keys (en, es)

src/server/
└── WorldBuilder.luau                         # buildMarkers skips GoldenSpot

src/client/
├── PigeonController.luau                     # NEW: ambient pigeons from Downtown.ambient.pigeons
└── Main.client.luau                          # starts PigeonController

scripts/
├── art-budgets.luau                          # union of both worlds' objects, keys dt_<id>
└── art-sync.luau                             # rewrites art/scripts/budgets.json for both worlds

art/
├── scripts/
│   ├── budgets.json                          # regenerated
│   ├── build_objects.py                      # + --world downtown mode
│   └── export_all.py                         # per-collection export, dt_ names
└── source/
    ├── dt_tier1.blend … dt_tier5.blend       # NEW: waves A to E
    └── dt_theme.blend                        # NEW: waves F and G

tests/unit/
├── Downtown.test.luau                        # NEW: counts, spawns, sightlines, budget, bindings, strings
└── Config, Themes, Pace, Markers, ArtManifest, Strings   # extended

tests/studio/
├── RunManager.spec.luau, ThemeSwitch.spec.luau           # made world-agnostic
└── AbsorbService, DataService, HazardService, ObjectTemplates, WorldSpawner   # audited
```

**Structure Decision**: extend the single Rojo project in place. The world is one data module beside Snow Village,
validated by the existing pure rules. Only two Roblox-side files change (`WorldBuilder`, one new client module);
nothing in `src/server` or `src/client` names a world, which the `GreyBoxRoom` guard in `check.sh` enforces. Art
lives in `art/` and enters the game only through `Assets.luau`.

## Delivery order and parallelism

Tasks are generated by `/speckit-tasks`; this is the dependency spine they follow. Rows 1 to 7 are US1, rows 8 to
11 are US2, row 12 proves both, and rows 14 to 18 are US3.

| # | Slice | Files (disjoint → `[P]`-safe) | Needs |
| --- | --- | --- | --- |
| 1 | Flag, unlock default, world pick | `Config.luau`, `Worlds.luau`, `Config.test` | – |
| 2 | Golden-spot marker | `Rules/Markers`, `GreyBoxRoom.luau` (types), `WorldBuilder`, `Markers.test` | – `[P]` with 1 |
| 3 | Theme tweak | `Themes.luau`, `Themes.test` | – `[P]` with 1–2 |
| 4 | Test generalisation | `Pace.test`, `ArtManifest.test`, `scripts/art-budgets.luau`, `art-sync.luau` | 1 `[P]` with 2–3 |
| 5 | Downtown base layout (US1) | `Downtown.luau`: spawns, zones, blocks, 74 objects, keep-outs, markers | 1, 2 |
| 6 | Pace tuning | `Downtown.luau` (`growthK`, counts), scratch pace run | 4, 5 |
| 7 | Downtown test | `Downtown.test.luau` | 5 (grows with 5, 6, 8) |
| 8 | Theme bindings (US2) | `Downtown.luau`: `winter` and `city` bindings, ids, book pages | 5 |
| 9 | Strings (en, es) | `Strings.luau`, `Strings.test` | 5 `[P]` with 6–8 |
| 10 | Pigeons | `PigeonController.luau`, `Main.client`, `Downtown.luau` (`ambient`) | 5 `[P]` with 8–9 |
| 11 | Studio specs | `RunManager.spec`, `ThemeSwitch.spec`, audit of five more | 5, 8 |
| 12 | Studio grey-box proof: 12-spawn bot run in both themes, parts, fps, `winter` ⇄ `city` | `captures/`, `playtest.md` draft | 5–11; **Studio claim**, 🔒 tasks |
| 13 | **Owner sign-off: grey-box layout and Holiday City look** | `playtest.md` | 12, owner; gates rows 14 to 18 |
| 14 | Blender wave A (Tier 1, 18) | `dt_tier1.blend`, `build_objects.py`, `export_all.py` | 13; **Blender claim** |
| 15 | Waves B to E (Tiers 2 to 5, 56) | `dt_tier2…5.blend` | 14 `[P]` per wave; **Blender claim** |
| 16 | Waves F and G (20 + 5) | `dt_theme.blend` | 14 `[P]` with 15; G may defer |
| 17 | Owner upload hand-off per wave | `Assets.luau` (ids), `captures/` | 14–16, owner |
| 18 | Final lock: 640 × 360, 12 balls, `winter`, ≥ 30 fps, parts < 2,000, triangle budgets | `playtest.md`, `captures/` | 17; **Studio claim**, 🔒; owner approval |

## Complexity Tracking

Two choices that could look like extra machinery, kept because each has a concrete current use.

| Choice | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| `GoldenSpot` marker kind (`GOLDEN_FOOTPRINT`, `requireGolden`) | The spec stores golden spots in `environment.markers`; Feature 012 will spawn objects at them. Today `Markers.validate` rejects them and `WorldBuilder` errors on them, so the kind must be added. It builds no part. | A separate `goldenSpots` list on `WorldDef` adds a schema field the spec does not name and a second validator for the same rules (R-04). |
| `PigeonController` (client module + `ambient.pigeons` data) | The design asks for ambient life in five districts; it must be unabsorbable, unreplicated and skipped under Reduce motion, so it cannot be an ordinary placed object. | Placing pigeons as objects makes animals absorbable (Principle IV). Server-driven birds add replication cost for decoration (R-14). |

The `dt_` prefix, the three-way world pick and the generalised art scripts are not listed: each is a data or
naming change that replaces a clash or a hard-wired Snow Village reference, not a new abstraction.
