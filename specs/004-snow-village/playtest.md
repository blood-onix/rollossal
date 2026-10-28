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
| SC-002 import (2026-10-27) | Owner ran the Studio bulk import: 65 `MeshId`s read by name through `execute_luau` and written to `Assets.meshes`; palette image id `rbxassetid://95185035371248` (owner copied it from Asset Manager → Images) written to `Assets.palette`, and it loads (`AssetFetchStatus.Success`). The 65 imported models were deleted from Workspace. `REQUIRE_ASSET_IDS=1 scripts/check.sh` exit 0 (270 tests, ArtManifest id test PASS). Studio, Rojo synced (`Assets` 4018 bytes): `ObjectVisual.build` for all 64 objects returned a `MeshPart` (0 stand-ins), longest side within 5 % of `ObjectDef.size`, 0 scripts in templates, `TextureID` = palette. Imported parts arrive about 100x too big (acorn about 50 studs); `ObjectVisual` rescales them. |
| Rollback smoke test | `Flags.SnowVillage` flipped to `false` in the repo (Rojo synced, Edit-mode read-back `flag = false`); Play run: `Workspace.World` 30 objects, 6 geometry blocks, hub with floor, world id `greybox`, one spawned ball (`Ball_7967226345`, unanchored, on the old spawn ring); console had no game-script errors (only Studio's own DataStore warning and `rbxassetid://203785492` lines, which are not in the repo). Flag restored to `true`, sync probe re-run: `mismatches = {}` (60 files). |

### SC scoreboard (agent-verifiable parts only, round 2)

- **SC-001**: met (this round).
- **SC-002**: met (2026-10-27): import done, ids in `Assets.luau`, `REQUIRE_ASSET_IDS=1 scripts/check.sh` exit 0, template size/script check green in Studio. Still to do: a Play restart look at the real art on a phone-size screen (part of SC-005).
- **SC-003**: known limit, not met and not waived. Balance (`growthK = 1.5`, Tier 3/Tier 4 placement counts) is deferred by the owner to the new map from the design-system spec (spec.md, Owner Approval Gate, 2026-10-28). Latest numbers: "Converge round 7" below (T4 0.135 at 240 s against the 20% floor).
- **SC-004**: Studio half met ("Converge round 7", Studio in front: 59.9 fps mean, min 57 in the Tier-4 window, 1,702 of 2,000 parts). Phone half is a known limit: the Pixel 7 Pro check never reached Tier 4, so it is deferred by the owner to the new map (see "Owner phone check and sign-off").
- **SC-005**: met on PC (owner sign-off 2026-10-27); the phone half is not measured (see SC-004).

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

### Owner sign-off on the final art build (2026-10-27)

- [x] Played the final Snow Village build with the real art on PC (build bc27958 plus the music change):
  owner's verdict "I like it so far". Signed off by the owner on 2026-10-27, recorded by the agent at the owner's
  instruction in chat (SC-005, PC half). Console in two fresh Play runs: only Studio's own `rbxassetid://203785492`
  line from game start (no game-script warning or error).
- [x] Final audio: music track `rbxassetid://80565841497538` (owner's own mp3, 174.6 s, loads in Studio), default
  `musicVolume` 0.4 in `Config.Settings`. Pickup/bell cues stay the engine placeholders.
- [ ] Reference phone (SC-004, fps at Tier 4): NOT measured. The owner accepted closing T031/T032 without it; it
  stays an open item for the publish checklist (also: `LoadStringEnabled` must be off in anything published).
- [ ] SC-003 balance: still deferred by the owner; `growthK = 1.5` unchanged, Tier 3/Tier 4 counts unchanged. Not waived.
- Outside-people playtest stays deferred to 004d.

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

## Converge round 4 (agent, 2026-10-27, build bce0a6d, tree clean)

A fresh 12-ball BotRun with the real art (`Assets.meshes` filled, Studio frontmost at Play start, Rojo probe
`mismatches = {}`, 60 files). Recorded before T034 exists, as the SC-004 evidence pass.

| Check | Result |
| --- | --- |
| Parts at Tier 4 (SC-004 server half) | 1,701 including 12 balls at every sample (60 to 241 s): inside the 2,000 budget. |
| SC-003 (BotRun) | `everyTierKeptShare` false again: T2 0.119 at 60 s, T3 0.118 at 120 s, T4 0.108 at 180 s and 0.081 at 240 s. Same shape as the two earlier runs; owners' SC-003 deferral unchanged. |
| Bots | 5 of 12 reached Tier 4 (69 to 117 s, final diameters 42.7 to 81.3); first pickup 0.03 to 0.4 s; Tier 2 at 10 to 28 s; 1,522 pickups. |
| Console | Game-script lines: three `Displacement violation` bot lines (bots race past the speed ceiling; known BotRun artefact) and `ContentId rbxassetid://80565841497538 failed due to: Asset type does not match requested type`. Traced in-Play: the WinterMusic `Sound` itself loads and plays fine (`IsLoaded` true, `TimeLength` 174.55 s), the failure comes from the bare-string `PreloadAsync` of `Assets.sounds.music` in `Feedback.preloadSounds`; appended as T034. The `rbxassetid://203785492` line is Studio's own (id not in the repo). |
| SC-004 fps in Studio | Not measurable this session: Studio's render loop idles at exactly 15 fps whenever the window is in the background and the owner was working in other apps (Brave/Telegram) during the 70 to 150 s Tier-4 window; a per-second RenderStepped sampler recorded 60 fps for the first 37 focused seconds at Tier 1-2 and no unthrottled window at Tier 4. Needs a session with Studio kept in the foreground for the Tier-4 phase (measurement harness is in place). |

## Converge round 7 (agent, 2026-10-28, T035 rerun without window activation)

Rojo probe clean on the key scripts (7 checked, no mismatches). BotRun 240 s, 12 bots, with a Client
`RenderStepped` sampler (one bucket per second), no activation, no keep-awake.

- **No unthrottled seconds.** 262 buckets, 261 at 14-16 fps (Studio's background throttle); only the first
  second read 60. Studio was not in front for the whole run, so there is no Tier-4 fps number from this run.
  It is not evidence for or against SC-004.
- Server half, same as before: 1,702 parts including balls (budget 2,000); 6 of 12 bots reached Tier 4
  (75 to 201 s, final diameters 32 to 79); 1,695 pickups; `everyTierKeptShare` false (T4 0.067 at 180 s,
  0.121 at 240 s; T3 0.118 at 120 s). SC-003 stays with the owner's deferred balance tuning.
- T035 stays open: needs one rerun with Studio kept in front for the ~4 minute run (AGENTS.md rule).

### Round 7 rerun with Studio in front (2026-10-28, T035)

Same setup (no activation, no keep-awake), owner kept Studio in front for the whole run.

- 267 one-second samples, **0 throttled seconds** (none at 14 to 16 fps): mean **59.9 fps**, min 56, max 60.
- Tier-4 window (first bot at Tier 4 at 74 s, to run end): 167 samples, mean **59.9 fps**, min **57**; no second under 30.
- **SC-004 Studio half: met** (>= 30 fps at Tier 4 with 12 bots and 1,702 parts). The phone half stays with the owner
  (publish checklist).
- Run facts: 5 of 12 bots reached Tier 4 (74 to 131 s, final diameters 38 to 80), 1,463 pickups, 1,702 parts
  including balls (budget 2,000). `everyTierKeptShare` false (T4 0.108 at 180 s, 0.135 at 240 s; T3 0.128 at
  120 s): SC-003 stays with the owner's deferred balance tuning, not waived.
- Console: no game-script lines. Studio's own DataStore warning, ProfileStore notice and three
  `rbxassetid://203785492` lines (Studio's, id not in the repo); no `80565841497538` line.

## Owner phone check and sign-off of the remaining human items (2026-10-28, T032)

Recorded by the agent at the owner's instruction in chat.

- **SC-004 phone half**: owner played on their phone with the owner-only FPS readout (`FpsReadout`,
  `Config.Flags.DebugFps`). Readout: **avg 59 fps, lowest 22 fps**. The lowest is below the 30 fps target; it is the
  single lowest one-second reading of the session, not a sustained figure, and the owner judged the play "quite
  smooth" and accepted it. Phone model: **Google Pixel 7 Pro** (owner, in chat, 2026-10-28). The Tier-4 time window
  and the Tier-4 share of the session were **not measured**: the owner says Tier 4 is hard to reach by hand on this
  map, which suits bots that skip bumps, so the 59/22 fps readout is not a Tier-4 figure. **SC-004 phone half is
  therefore not verifiably met, and not waived**; the owner chose to skip it in this spec and redo it on the new map
  from the design system spec. Server half: 1,702 parts
  (budget 2,000), see the round 7 rerun above (59.9 fps in Studio, min 57).
- **SC-003 balance (`growthK`, Tier 3/Tier 4 placement)**: **skipped for now**, by the owner. It cannot be measured
  properly without the proper map; `growthK = 1.5` and the Tier 3/Tier 4 counts stay as they are. Not met, not waived:
  revisit when the final map exists.
- The owner asked to close the remaining human items on the card, so T032 and the card go on to Review with the two
  points above as known limits.

## Phone-size UI captures (agent, 2026-10-27, T033)

Method: AGENTS.md clone-into-exact-size-frame. A `CaptureHarness` ScreenGui on the Client holds a full-viewport
black backdrop and an exact W×H frame with the cloned live screen (Hud, BookUi, Results with TopBar). Red
translucent zones mark the Jump (96 px, bottom right, 24 px in) and Thumb (120 px, bottom left) areas. Studio's
viewport is 1180×979, so the 1280×720 frame runs at UIScale 0.9219; the 640×360 and 844×390 frames run at 1.
Measured with `TextFits`, `TextSize`, `AbsolutePosition`/`AbsoluteSize` (divided by the scale).

Results (all text labels and buttons with text):

- Hud at 640×360, 844×390 and 1280×720: no `TextFits` failures, minimum TextSize 18.
- Book page 1 (18 cards) at 640×360, 844×390 and 1280×720; pages 2–5 at 640×360 only. Card counts per page
  18 / 16 / 14 / 12 / 4 (64 total). Next is disabled on page 5. Pages 2–5 are not captured at the two larger
  sizes: the panel is a fixed 464×240 at every size and the grid scrolls, so 640×360 is the tightest check.
- Results at 640×360, 844×390 and 1280×720: no `TextFits` failures, minimum TextSize 18. Final size 2.0,
  0 of 3 stars, Coins 0 (total 0), "No new book entries", and the first-run tip at 18 px in the captures.
- Glyphs: a sheet at 1280×720 shows all 18 `Icons` entries (star, star_empty, clock, coin, cube, arrow, book,
  retry, home, play, gear, shop, lock, unknown, prev, next, close, check) in both `FredokaOne` and
  `GothamMedium`. All of them render; none is blank or a box. The tier-headline icons are all `cube`.

Observations (layout facts for the owner, not T033 failures):

- (a) Hud, 640×360: the three star-target labels touch with no gap.
- (b) Results, 640×360: the RollAgain button (about x 17–231, y 232–328) overlaps the thumb zone (0–120,
  240–360). Results is modal and the run has ended, so there is no live thumb input here. Still, a 1 px
  clearance is tight.
- (c) Book, 640×360: the bottom-left cards overlap the thumb zone. Book is modal.
- (d) The 1280×720 captures are drawn at 0.92 to fit Studio's viewport. The TextSize values in this section
  are the true values; only the picture is scaled.

Capture files (`captures/`): hud_640x360, hud_844x390, hud_1280x720, book_p1_640x360, book_p2_640x360,
book_p3_640x360, book_p4_640x360, book_p5_640x360, book_p1_844x390, book_p1_1280x720,
glyphs_icons_fredoka_gotham_1280x720, results_640x360, results_844x390, results_1280x720 (all `.jpg`).
The first `book_p1_640x360` attempt is not stored: its backdrop was missing, so the live panel showed through.
It was re-captured after the backdrop fix.

## Review round 1 (2026-10-27): hub mesh and bot run

- Hub (F1): Play in Studio shows `Workspace.World.Hub` with `Floor`, `StartPad` and `HubMesh` (MeshPart, anchored,
  centred on the hub at (-460, 0), bottom at y 0, size 12 x 7.92 x 12.75). Console: only Studio's own
  `rbxassetid://203785492` lines and the DataStore/ProfileStore notices.
- Open for the owner: `StartPad` is at `hub.center + hub.spawn` (the same centre as the carousel plinth). Not
  checked by eye; `hub.spawn` is unchanged pending the owner's decision (see `questions.json`).
- BotRun 240 s (F6, F3 data): `everyTierKeptShare` false. Available share at 60 s T2 0.116, T4 1.0; at 240 s T2 1.0,
  T3 0.874, T4 0.121, T5 0.75 (1,702 parts). Displacement violations: 2 (`user 7967226345` 247.4 > 224, bot
  `700007` 338.1 > 224). Speed violations: 2, both for `user 7967226345` (79.7 and 56.5 > 56). The previous 12-bot
  runs logged 3 to 4 displacement lines, so the `BallService` lastValidPosition change reduces the count but does
  not remove it; the remaining bot line is the known BotRun speed artefact.

## Review round 1 SC-003 run (agent, 2026-10-28, 12 bots, 240 s)

Placement counts raised (Tier 2 lawn_n 14 to 18 per spawn, Tier 3 lane_n 10 to 14, Tier 4 bands 26 to 44 and streets, square). Parts 1,840 of 2,000. Result: `everyTierKeptShare` false, the share did not reach 20 %.

- Available share at 60 / 120 / 180 / 240 s: T2 0.078 / 0.283 / 0.559 / 0.919; T3 0.225 / 0.122 / 0.178 / 0.194; T4 0.982 / 0.086 / 0.103 / 0.051.
- The placement counts were reverted after this run: they did not meet SC-003 and cost part headroom. The part budget (2,000) leaves about 160 parts for more placements, so placements alone cannot meet SC-003. The remaining levers (growthK, the part budget, or the pool shape) are the owner's decision; SC-003 stays open.

## Review round 3 (agent, 2026-10-28)

Fixed: CI `check` failed at "Install tools from rokit.toml" with a 403 from the GitHub API (unauthenticated
rate limit on the shared runner); the step now passes `github.token`. The hub mesh task in `WorldBuilder` is
protected by `pcall` and warns. The displacement and speed verdict moved into `Rules/BallGuard` with unit tests
(including a 247.4 studs/s step, the logged value), and the FPS readout's window logic into `Rules/FpsStats`
with tests for the warm-up, the reset on tap and the creator gate. F4 was already done: `ArtManifest.test`
counts triangles from the FBX files with `scripts/fbx-geometry.luau`.

Not fixed, with the reason:

- **SC-003 balance and the SC-004 phone half (F3, F7, F11, F20)**: the owner's recorded decision (spec.md, "Deferred
  Balance and Phone Check", 2026-10-28) is to re-measure both on the new map. Not met, not waived.
- **The logged 247.4 > 224 displacement (F6, F17)**: only seen in BotRun, whose bots set velocity directly; it was
  not reproduced with a player. The verdict logic is now tested, so the remaining question is only whether a real
  player can trigger it; the `Displacement` log (`session.violationLog`) is the place to look in the new-map run.
- **Respawn sight rule (F15)**: the server only knows the ball's heading, not the player's camera. Modelling the
  view cone needs the client to report its look direction; left for the mechanics pass (004b).
- **Porches (F16)**: single 0.6-stud block with ramps is a content change for the new map.
