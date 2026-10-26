# Quickstart: validating Snow Village end to end

A validation guide, not an implementation guide. Contracts: [world-content](contracts/world-content.md),
[rules-api](contracts/rules-api.md), [runtime-api](contracts/runtime-api.md),
[art-pipeline](contracts/art-pipeline.md). Data: [data-model.md](data-model.md).

## Prerequisites

- `rokit install`, `wally install`; `scripts/check.sh` passes on a clean branch.
- Rojo serving (`scripts/studio-preflight.sh` starts it) and the Rojo plugin connected in Studio; the
  sync probe (`scripts/studio-sync-probe.sh` through `execute_luau`) shows `mismatches = {}` (AGENTS.md).
- Jest-Lua needs `LoadStringEnabled` on in the dev place (owner keeps it on; off in anything published).
- For art tasks only: Blender (pinned LTS) installed by the owner; `uvx` available; the pinned `blender-mcp`
  in the two MCP config files (T001).

## 1. Static gate (every task)

```text
scripts/check.sh        # StyLua, Selene, luau-lsp strict, Lune (incl. SnowVillage, Layout, Respawn, Pace, ArtManifest), Rules purity
```

Expected: exit 0. `Pace.test` failing means the world as authored cannot meet the 5 s / 60 s rules: see
research R1 before touching the layout.

## 2. Content and pace (Lune, no Studio)

Run `lune run tests/unit/run`. Expected, by test:

- `SnowVillage`: 64 objects (18/16/14/12/4), unique ids and book ids, sizes inside tier ranges and ≤ 0.4 ×
  ceiling, coin ranges ascending, all keys resolve in `Assets` and `Strings` with `en` and `es`, 12 spawn
  clusters of ≥ 10 Tier 1 placements with `size ≤ 0.8` within 45 studs, no overlaps, pool + geometry + 12
  balls ≤ `maxActivePartsPerServer`.
- `Respawn`, `Layout`, `Tiers.isCulled`: the fixed tables in rules-api.
- `Pace`: Tier 2 by 60 s, ≥ 20 studs and ≥ 30 studs by 240 s for the modelled eater.
- `ArtManifest`: with no art yet the test passes in "fallback" mode (empty `art/export`); with art, every
  object has a manifest entry within budget and a matching hash.

## 3. Grey-box gate (Constitution I; before any Blender mesh)

1. Studio MCP: `list_roblox_studios`, run the sync probe, `start_stop_play` (server).
2. `get_console_output`: no errors or warnings. `Workspace.World.Objects` has the expected child count
   (`#Worlds.placements`) and every child is `Anchored`, tagged `WorldObject`, with the four attributes.
3. Drive one ball (AGENTS.md "Driving the ball") from spawn slot 1: the first pickup arrives in ≤ 5 s;
   record the time Tier 2 is reached.
4. Run `BotRun` (12 playerless balls, 240 s, started in the background): read `Workspace.BotRunReport`.
   Expected: all balls ≥ Tier 3, most ≥ Tier 4 (SC-003), every tier keeps ≥ 20 % of its objects available at
   60/120/180/240 s, no console errors, part count under budget.
5. Respawn proof (Jest `WorldSpawner.spec` plus a manual look): an eaten object stays hidden for ≥ 60 s,
   does not reappear while a ball is within 45 studs or heading toward it within 120, and returns to the
   same `Instance`.
6. The owner plays it on PC and phone (placeholder meshes, flat colours). Notes, build commit, date and the
   owner's sign-off go to `specs/004-snow-village/playtest.md` (grey-box section). Tuning from this step is
   data/Config only.

## 4. Culling, streaming, lighting, audio (Studio)

- `WorldCuller.spec`: at Tier 3 the Tier 1 objects are locally hidden; after a knock-off to Tier 2 they
  return; a `Taken` object is never revived; other players' views are unaffected (two local clients: the
  second still sees Tier 1).
- Streaming: `Workspace.StreamingEnabled` is true; teleporting between spawn slot and hub (`Back to hub`,
  `Roll again`) never drops the ball (log the ground-exists check at unfreeze); no object pops in within one
  ball length at speed 32.
- Lighting: the captured viewport shows the winter ambient and fog; fog does not hide the next tier's objects
  inside 128 studs.
- Audio: `Assets.sounds.*` all have `IsLoaded` and a non-zero `TimeLength` in Play; the music loops and
  follows the Music volume setting; pitch rises with tier on pickups (Tier 1 → 1.0, Tier 5 → 1.32).

## 5. Phone-size captures (Quality Gate 2)

At 640 × 360, 844 × 390, 1280 × 720 (clone-into-sized-frame method, AGENTS.md): Hud with the new tier
names and next-tier line, Results, and Book with 18 cards on page 1 and 5 pages. Text ≥ 18 px, glyph check
of new `Icons` entries in both fonts. Store the captures under `specs/004-snow-village/captures/`.

## 6. Art (after the grey-box gate)

1. Claim Blender on the task. `blender --background --python art/scripts/palette.py`, then model per tier,
   then `blender --background --python art/scripts/export_all.py -- --out art/export`.
2. `scripts/check.sh`: `ArtManifest` passes (budgets, hashes).
3. Owner import session, then the agent fills `Assets.meshes` / `Assets.palette` (art-pipeline hand-off).
4. Restart Play (Rojo syncs the Edit place only). Studio spec: every template's longest side is within 5 %
   of `ObjectDef.size` and has zero script descendants; console shows no `CreateMeshPartAsync` warnings.
5. `REQUIRE_ASSET_IDS=1 scripts/check.sh` passes.

## 7. Final verification (Success Criteria)

- SC-001: `scripts/check.sh` 0 and all Jest suites pass.
- SC-002: manifest within budget, one palette texture, IDs only in `Assets.luau`.
- SC-003: the final `BotRun` and a hand-driven first-pickup/Tier 2 timing.
- SC-004: ≥ 30 fps at Tier 4 on the owner's reference phone and in the 12-ball server run, part count
  recorded; camera/speed observations for F-3.
- SC-005: grey-box and final sections of `playtest.md` signed by the owner; zero new console errors.
- Rollback check: with `Config.Flags.SnowVillage = false` the game still starts in the grey-box room.
