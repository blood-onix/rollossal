# Implementation Plan: Park City Map (Grey Box)

**Branch**: `claude/zealous-volta-6h9wnq` (spec folder `012-park-city-map`) | **Date**: 2026-11-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/012-park-city-map/spec.md`

## Summary

Turn the approved Park City layout into a playable grey box, in four stages. Each stage ends in a build the owner can
play. The world is generated from `park-city-layout.json` into Luau content data by a script. Tiers 3–6 (942 objects)
stay server Parts through the existing builder and pool. Tiers 1–2 (3,107 objects) become server data plus client
drawing. The size and readability rules are per-world data, so Downtown and Snow Village keep today's rules. Growth
pace is reported, never gated.

Read first: [research.md](research.md) (six decisions), [data-model.md](data-model.md), [quickstart.md](quickstart.md).
There are no `contracts/`: every interface is either the layout JSON (owned by the design) or an internal module, and
the one new remote is described in `data-model.md`.

## Technical Context

**Language/Version**: Luau (`--!strict`) on Roblox; Python 3 for the layout and world scripts; Lune for unit tests.

**Primary Dependencies**: none new (Constitution XII). Rojo 7.7.1, Lune, StyLua, Selene, luau-lsp as today.

**Storage**: none. No profile or DataStore change.

**Testing**: Lune unit tests in `tests/unit` (the floor, gate 1); Jest-Lua specs in `tests/studio` for the server light
state and absorb validation; the Studio MCP for the playtest, the benchmark and the console read.

**Target Platform**: Roblox, phone first. Frame rate is checked in agent Studio runs, judged on unthrottled seconds.

**Performance Goals**: server parts under 2,000 with 12 balls; every unthrottled benchmark second at 30 fps or more.

**Constraints**: Part budget (below); the 1,000 × 1,000 map; Principle II for every light-object claim.

**Scale/Scope**: 4,049 objects, 71 blocks, 12 spawns, 233 scenes, about 100 placeholders.

### Part budget (server, 12 balls)

| Item | Parts |
| --- | --- |
| Tier 3–6 objects (pooled) | 942 |
| Blocks (the layout's 190 minus 119 hedge blocks, which become light objects) | 71 |
| Placeholders (rails, pads, catapults, water) | about 100 |
| Boundary walls, hub | about 20 |
| Balls (12) | 12 |
| Runtime (stuck visuals are client-side; boosters, traps, hazards, traffic) | about 100 |
| **Total** | **about 1,250** |

If Stage B measures over 1,800, thin Tier 1–2 first as the brief allows (it only applies to the Parts-only Stage B,
where the light system does not exist yet). Stage B reports the part count, and the thinning rule is "drop every second
Tier 2 object of scenes tagged park fill", recorded when used.

## Constitution Check

Constitution on disk is **4.0.0**. The brief mentions a 4.1.0 amendment "if it has landed". It has not: neither
`.specify/memory/constitution.md` nor its sync report mentions 4.1.0. The only mention is the owner's prompt
(`docs/design/speckit-prompts-012.md`) asking for it as a MINOR bump. The remote branches
`constitution-4.0.0-visual-gate` and `constitution-playtest-timing` were checked: the second holds an older text
(pre-3.0) and neither is a 4.1.0. This plan is
checked against 4.0.0 and notes where a 4.1.0 might matter (nothing known). Re-check when it lands.

| Principle / gate | Status |
| --- | --- |
| I Grey box first; gate 6 | Met. Every stage ends in a playable build; Stage D produces fixed shots and waits for owner approval before merge. |
| II Server authority | Met. Light absorbs are validated on the server from its data: existence, taken, distance to the data position, size rule, rate limit. The client sends only an id string. `LightDelta` is server to client and carries indices only. |
| III Pure tested rules | Met. New pure rules `Absorb.canEat`, `Growth.growByBulk`, `Movement.speedCap`, `HeapFit`, `Light` each get a Lune test of fixed values. No Roblox APIs in `Rules`. |
| IV Safe | Met. No text added; names are common nouns. Hedge, fence and hoarding gates are objects, not people or animals. |
| V, VIII Monetization, data | Not touched. No schema change. |
| VI Mobile first | The first pickup within 3 s (stricter than 5 s) is a gate (G4). Text-free cues (the rule is colour-and-motion; reduce-motion turns the bob off). Phone fps is on the RC list. |
| VII Content is data; flags; tests | Met. The map is generated content data. `Flags.ParkCity`, `Flags.HeapFix`, `Flags.ReadableRules`, all off. Lune tests validate ids, dims, tiers. |
| IX Localised strings | Met. 219 object name keys in English and Spanish (generated). Cues have no text. The tier banner and star-target text are not shown in Park City and Stage A. Spanish names are a first pass (RC list). |
| X Multi-agent | One agent drives Studio at a time; the claim goes on the Studio tasks in `tasks.md`. |
| XI Asset pipeline | Grey box: stand-in parts only, no new meshes, no transparency (water is an opaque slab). |
| XII Lean | No new package or tool. New modules, each with at least two current users or no alternative: `Rules/Light` (client draw query, server verdict and pace test), `Rules/HeapFit` (StuckVisuals and its test, and the Stage A and B heaps), `LightField` (the one client module; nothing existing can host a pool). Existing modules change in place. |
| Gates 1–5 | Gate 1 by `scripts/check.sh`. Gate 2 by the Stage D playtest and console read. Gates 3 (no asset) and 4 (strings in tables) as above. Gate 5 by `tasks.md`. |
| Gate 6 | Stage D, as above. |

No violations. Complexity Tracking is empty.

**Difference to record**: knock-off scatters Parts only. A knocked-off light object leaves the stack and is not dropped
(there is no part to drop), and it stays taken until its normal respawn. If this feels wrong when played, it is a
tuning item for the owner, not a gate.

## Project Structure

### Documentation (this feature)

```text
specs/012-park-city-map/
├── plan.md            # this file
├── research.md        # six decisions
├── data-model.md      # generated world data and light-object state
├── quickstart.md      # how to validate each stage
├── tasks.md           # /speckit-tasks
├── pace-report.md     # written by the ParkPace test (Stage D)
├── playtest.md        # agent runs and the owner's gate 6 record
└── shots/             # fixed shots (PNG), Stage D
```

### Source code

```text
scripts/
├── park_city_layout.py        # existing; gains --check
├── park_city_world.py         # NEW: JSON → Luau world data (+ --check)
└── capture-export.luau        # extended: --world parkcity

src/shared/
├── Config.luau                # flags + a few keys (heapNewestGrace, lightPoolCap, lightDrawRadius, wobble/ripple/thud values)
├── Worlds.luau                # picks ParkCity; resolves Worlds.rules; light helpers
├── ObjectVisual.luau          # dims-sized stand-in
├── Content/Worlds/ParkCity*.luau   # GENERATED (3 files)
├── Localization/ParkCityStrings.luau   # GENERATED
└── Rules/
    ├── Absorb.luau  Growth.luau  Movement.luau   # canEat, growByBulk, speedCap
    ├── HeapFit.luau                              # NEW
    └── Light.luau                                # NEW: grid, verdict

src/server/
├── WorldBuilder.luau   # placeholders; hub from world data (already); six-tier budgets
├── WorldSpawner.luau   # light state, respawn, delta outbox
├── AbsorbService.luau  # world rule; "L<n>" ids
├── BallService.luau  KnockOff.luau  BoosterService.luau  RunManager.luau  # Worlds.rules
└── Remotes.luau        # LightDelta

src/client/
├── LightField.luau     # NEW
├── StuckVisuals.luau   # HeapFit, light ids, wobble-safe
├── BallController.luau # world rule, speed cap, thud
├── CameraController.luau  Feedback.luau  Hud.luau  WorldCuller.luau  # camera min, thud nudge, no banners, tier ripple/bob

tests/unit/   Absorb, Growth, Movement, HeapFit, Light, ParkCity, ParkPace (new/extended)
tests/studio/ AbsorbService.spec (light), WorldSpawner.spec (light), HeavyScene + HeavySampler (Park City)
```

**Structure Decision**: single Rojo project as today. One generator script, three generated content modules, two new
pure rule modules and one new client module. Nothing else is new.

## Stages

Each stage ends with a build the owner can play. About 38 tasks in all; `/speckit-tasks` splits them.

### Stage A: the rules on the existing Downtown map (about 10 tasks)

Behind `Flags.ReadableRules` (off) and `Flags.HeapFix` (off). Downtown is the map; the layout is not used yet.

- Per-world `rules` and the pure functions (R3), with Lune tests: bulk and longest rule, garnish, growth by bulk, the
  speed cap, the start diameter, six tiers and stars as data on Downtown's readable table, `dims` for the long thin
  objects.
- Heap fix (R4): `HeapFit` and its use in `StuckVisuals`, with the bound test at D 1, 2, 5, 10, 20, 50, 100 (SC-004).
- Cues: the bob (up to 24 edible within 4 D, off with Reduce motion), the new-tier ripple (6 D), the thud, camera
  nudge and bounce, and no tier banner, next-tier line or star-target text when the flag is on.
- Owner sees: Downtown starts at D 1; the ball looks its real size at every size; a long thin object is eaten when
  chunky enough; nearby food wobbles; a new tier rings out; too-big things thud, with no text on screen. The owner can
  judge "can I tell what I can eat?" before any new map exists.

### Stage B: the Park City world from the layout, as Parts (about 10 tasks)

Behind `Flags.ParkCity` (off). The light objects are not built yet, so Tier 1–2 objects are pooled Parts only in the
areas Stage B needs, and thinned if the part count would exceed 1,800 (drop every second Tier 2 object of park-fill
scenes; recorded where used). The doorstep crumbs, trails and all Tier 3–6 objects are complete.

- `park_city_world.py` and its `--check`; the three generated modules and the strings; `ParkCity.test` (match to the
  layout, ids, dims, tiers, spawns, placeholders).
- `Worlds.luau` picks ParkCity. Blocks, ramps, decks, maze, tunnels and drains built by the existing builder; the hub is
  at x = −760 because the world's `hub` data says so (no code change beyond reading it).
- Placeholders (R5): rails, pads, catapults, bullseyes, water, all inert.
- Owner sees: the whole 1,000 × 1,000 map, every ring, spawn and set piece at the layout coordinates, with food at
  reduced small-object density, and the placeholder rails, pads, catapults and water in place.

### Stage C: light objects at the layout's full density (about 8 tasks)

- `Rules/Light` and its test (verdict, grid query). `WorldSpawner` light state and respawn; the `L<n>` path in
  `AbsorbService`; `LightDelta`; `LightField` pooling and the tier cull; `StuckVisuals` for light ids.
- Studio specs: a far claim is refused, a taken object is refused, a too-big object is refused, the rate limit holds,
  a take reaches a second client, respawn works.
- Stage B's thinning is removed. Owner sees: the full-density food, 3,107 crumbs and pockets, with 12 balls.

### Stage D: report, shots, benchmark, playtest, gate 6 (about 10 tasks)

- `ParkPace.test`: the report for 12 spawns and 3 profiles (writes `pace-report.md`; passes whatever the pace is), the
  first-pickup check (G4) and the open-route ladder check (G5), and the 20 doorstep crumbs per spawn.
- `HeavyScene` and `HeavySampler` for Park City: 12 bot balls rolling on the real map for 60 s, one fps value per
  second, throttled seconds apart; the part count read at the same time (G3, G6).
- The fixed shots (R6), rendered into `shots/`.
- The Studio playtest and the console read (G7). Studio steps follow AGENTS.md: preflight, sync probe, tasks done by
  the agent; a Rojo wait that runs out is one failure of the two-failure rule except for the gate 2 playtest, which
  must run before the pull request.
- The pull request opens to show the shots; the owner's approval is recorded in `playtest.md` and holds the merge.
- Owner-only items go to `docs/release-candidate.md`: phone frame rate, `growthK` and star tuning, the pace sign-off,
  the Spanish object names, and whether the knock-off difference is right.

## Flags

| Flag | Default | Effect |
| --- | --- | --- |
| `Flags.ParkCity` | false | `Worlds.active` is Park City; implies `HeapFix`. |
| `Flags.HeapFix` | false | `StuckVisuals` uses `HeapFit` (also on whenever `ParkCity` is on). |
| `Flags.ReadableRules` | false | Stage A: Downtown uses its `readableRules` table (bulk rule, D 1, six tiers, stars, speed cap) and the cues. Park City always has them as its own data. |

## What must keep passing unchanged

With all three flags off, these existing tests are not edited and must pass: `Absorb`, `Growth`, `Tiers`, `Stars`,
`StuckStack`, `Movement`, `BallGuard`, `Config` (new keys are added; no existing pin changes), `Downtown`,
`SnowVillage`, `Pace` (the Downtown and Snow Village pace model, still asserting its 008 and 004 targets), `Layout`,
`Themes`, `ThemeResolve`, `Strings` (the new strings table is merged and its keys are balanced), `CaptureCameras`
(`art/capture/cameras.json` is not touched) and the Jest specs `AbsorbService`, `WorldSpawner`, `WorldCuller`,
`BallService`, `RunManager`, `ObjectTemplates` and `ThemeSwitch`, run on Downtown. A change to an existing function
signature that would force a test edit is a defect in the change.

## Hard gates

G1 to G8 of the spec and nothing else. Growth pace is reported. No pace window, tier-time target or bot-run pass
criterion is a gate or a task.

## Open points for the first tasks of a stage (not blockers)

- Stage A: a sixth entry in the mesh-triangle budget for Tier 6 (Downtown recomputed tiers can reach 6).
- Stage C: how `BallController`'s `objectParts` set picks up pool parts (by the `WorldObject` tag, as pooled parts do).
- Stage D: whether `capture-export.luau` can draw light rows and placeholders in about 60 lines, else a second small
  export script (research R6).
