# Playtest log: Snow Village (004)

Constitution I (fun proven in grey box first). The outside-people round is deferred to 004d by owner decision.
This file records the **agent-driven Studio runs**. The owner's play on PC and phone, and the sign-off, are
still to be written (task T032).

## Grey-box section (placeholder meshes, flat colours)

Build: branch `004-snow-village`, uncommitted working tree on 2026-10-26 (all art is the stand-in part
fallback; `Assets.meshes` is empty). Studio local server through the Studio MCP, Rojo synced.

| Check | Result |
| --- | --- |
| World builds | `Workspace.World`: 1,610 pooled objects (T1 856, T2 361, T3 311, T4 74, T5 8), 45 geometry parts, 16 marker parts, hub with floor and pad. Console clean (the `ContentId rbxassetid://203785492` lines are Studio's own; the id is not in the repo). |
| Pool never destroyed | child count of `World.Objects` stayed 1,610 through a full run; Jest `WorldSpawner.spec` checks the same `Instance` after respawn. |
| First pickup | one hand-driven ball from spawn slot 1: first pickup within 0.1 s (gumdrops and acorns lie on the porch). |
| Tier 2 within 60 s | hand-driven ball (client Heartbeat bot with sphere-cast obstacle avoidance): Tier 2 at 55.8 s on one run; a second run of the same bot had not reached it by 160 s because it kept bumping solid Tier 1 big crumbs. The pace model says 34 s for an ideal eater. **Open: a human may be nearer the second number than the first.** |
| Growth over a run | same bot, first run: Tier 3 at 100 s, 40 studs at 150 s, 74.6 studs at 240 s (2 stars, close to 3). |
| Back to hub | Results "Back to hub" put the ball on `Workspace.World.Hub.Floor`, not anchored, no fall. |
| Culling | at D = 14 all 856 Tier 1 objects are hidden locally and Tier 2 is shown; at D = 40 Tiers 1 and 2 are hidden; back at D = 6 everything is shown. |
| Music path | with a temporary id, the looping `WinterMusic` sound plays in the `Music` group, loaded. No track is shipped (`Assets.sounds.music` is empty: nothing bundled with the engine is music). |
| Rollback | `Flags.SnowVillage = false`: world id `greybox`, 30 objects, 6 geometry blocks, ball on the old spawn ring, console clean. |

### 12 playerless balls, one full run (`tests/studio/BotRun.server.luau`)

Bots are server-owned balls with a greedy eater and no obstacle avoidance; the objects and the bots do not
collide (a real client does that for what it can eat). One real ball idles in slot 1, so 13 balls in total.

- First pickup: 0.05 to 0.23 s for every bot.
- Tier 2 (5 studs): 10 to 40 s for every bot.
- Tier 4 (30 studs): 5 of 12 bots, between 70 and 141 s; final diameters 5.5 to 90 studs. The other 7 stalled
  between 5.5 and 9.3 studs: the Tier 3 pool (311) is eaten by the leaders and a stalled bot cannot eat Tier 3
  until 10.5 studs.
- Available share per tier at 60 / 120 / 180 / 240 s: T1 0.25 / 0.83 / 0.94 / 0.81, T2 0.19 / 0.59 / 0.93 /
  0.96, T3 0.31 / 0.11 / 0.54 / 0.68, T4 1.0 / 0.35 / 0.18 / 0.07, T5 1.0 / 1.0 / 0.88 / 0.75.
- Part count: 1,701 including 12 balls (budget 2,000).
- **SC-003 is not met by this run as it stands**: Tier 3 fell to 11 % and Tier 4 to 7 % available, so "no tier
  zone runs dry" fails when five greedy bots race through the top tiers. Levers (data only, for the grey-box
  tuning with the owner): more Tier 3 and Tier 4 placements (the pool has room up to about 1,900), a lower
  `growthK`, or both. They interact with the Tier 2 in 60 s rule, which needs the high `growthK`.

### `growthK` is provisional

`Content/Worlds/SnowVillage.luau` sets `growthK = 1.5`. With the global 0.6 the pace model (`Pace.test`) takes
96 s to Tier 2 and ends a run at about 15 studs, so the Tier 2 in 60 s rule cannot hold. 1.5 gives 34 s and
63 to 71 studs for an ideal eater. The owner confirms or changes it (T032).

## Round 2 final-validation re-run (agent, 2026-10-26, build 71eb5dc, tree clean)

Real art is now exported (T024), so every check re-ran with the manifest engaged.

| Check | Result |
| --- | --- |
| Lune / static gate | `scripts/check.sh` exit 0: 270 Lune tests (incl. `ArtManifest` hashing every FBX against the manifest), StyLua, Selene, luau-lsp strict, world-agnostic and Rules purity guards green. |
| Jest (Studio MCP runner) | 5/5 suites, 0 failures: AbsorbService 19, RunManager 26, DataService 29, WorldSpawner 15, WorldCuller 12. |
| SC-002 static half | No `rbxassetid://` anywhere in `src` outside `Assets.luau` (grep); one palette texture (`art/palette.png`, referenced by `manifest.json`); `Assets.meshes` still empty — the `REQUIRE_ASSET_IDS=1` import is the owner's hand-off, so SC-002 stays open until then. |
| Rollback smoke test | `Flags.SnowVillage` flipped to `false` in the repo (Rojo synced, Edit-mode read-back `flag = false`); Play run: `Workspace.World` 30 objects, 6 geometry blocks, hub with floor, world id `greybox`, one spawned ball (`Ball_7967226345`, unanchored, on the old spawn ring); console had no game-script errors (only Studio's own DataStore warning and `rbxassetid://203785492` lines, which are not in the repo). Flag restored to `true`, sync probe re-run: `mismatches = {}` (60 files). |

### SC scoreboard (agent-verifiable parts only, round 2)

- **SC-001**: met (this round).
- **SC-002**: agent half met; open on the owner's Studio import of `Assets.meshes` / `Assets.palette` (T032 hand-off).
- **SC-003**: open — balance tuning deliberately deferred by the owner's grey-box sign-off (`growthK = 1.5` provisional; Tier 3/Tier 4 placement counts unchanged). Latest recorded numbers: the "BotRun after the owner's PC play" section below.
- **SC-004**: open — phone measurement belongs to the owner (T032).
- **SC-005**: open — owner sign-off pending (T032).

## BotRun after the owner's PC play (agent, 2026-10-26, build 3dc60b2)

12 playerless balls, 240 s, run from the owner's Play session (the owner's ball was the 13th).

- First pickup 0.03 to 0.22 s and Tier 2 at 10 to 28 s for every bot. Part count 1,701 (budget 2,000).
- Tier 4: 5 of 12 bots (at 69, 72, 78, 110, 151 s), final diameters 40.7 to 75.5 studs. The other 7 stalled
  between 5.5 and 9.0 studs, as in the earlier run.
- Available share at 60 / 120 / 180 / 240 s: T1 0.26 / 0.80 / 0.97 / 1.0, T2 0.08 / 0.55 / 0.97 / 1.0,
  T3 0.44 / 0.19 / 0.66 / 0.71, T4 1.0 / 0.24 / 0.18 / 0.05, T5 1.0 / 1.0 / 1.0 / 0.75.
- `everyTierKeptShare` is false: Tier 2 at 60 s (0.08) and Tier 4 at 180 s and 240 s (0.18, 0.05) are under the
  20 % floor. SC-003 stays open and is deferred with the balance tuning.
- Console: no game-script errors. Three `Displacement violation` lines (two bots, one real user) were logged;
  not investigated.

## Owner section (to fill in)

- [x] Played on PC, build commit: 3dc60b2 (branch tip when recorded), date: 2026-10-26, notes: owner played and
  could not reach the maximum size within a run, even while trying hard. Owner reads this as a balance matter
  that depends on the final map design, not a layout fault.
- [ ] Played on the reference phone (fps at Tier 4, part count): not done yet (SC-004 stays open)
- [x] Sign-off (grey-box layout gate): signed off by the owner on 2026-10-26 (recorded by the agent at the
  owner's instruction in chat). Art may start. Balance tuning is deliberately deferred until the map design
  settles: `growthK = 1.5` stays provisional and the Tier 3/Tier 4 placement counts stay as they are, so
  SC-003 remains open and is not waived. Audio IDs are not chosen yet.

## Round 2 art pipeline run (agent, 2026-10-26, T024)

The owner's "Art may start" unblocked T024; the art was modelled and exported the same day.

- 65 collections modelled procedurally (`art/scripts/build_objects.py`) and written to
  `art/source/{tier1_crumbs,tier2_toys,tier3_furniture,tier4_street,tier5_town,hub}.blend`.
- `art/scripts/export_all.py` exits 0: collection names, single `Palette` material, flat shading / no custom
  normals / no unapplied modifiers / scale 1 rotation 0, per-face UVs inside one swatch cell, sizes and
  origin, and all triangle budgets hold. `art/export/manifest.json` written (65 meshes, sha256 per file).
- `scripts/check.sh` exit 0 with the real manifest engaged (ArtManifest tests hash every FBX against the
  manifest; `Assets.meshes` stay empty strings — the REQUIRE_ASSET_IDS import is the owner's hand-off).
- Proportion QA (art-pipeline rule 6): headless contact sheet `art/qa/grid.png`, every mesh rendered with its
  palette colours. Shapes read as intended at game scale (carousel, cabin, town house, sled, bicycle,
  snowmen, fences, crumbs); chunky cartoonish look with the exaggerated pieces doing the exaggeration.
  Owner eyes-on with the finished meshes is still part of T032's phone/PC pass.
