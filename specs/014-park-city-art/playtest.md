# Playtest log: 014 Park City art

Studio: one instance, "Rollossal" (place 112788738500883), Rojo 7.7.1 connected (sync probe: no mismatches before each
Studio run). All runs on 2026-11-08, dress table at Stage 3, `ACTIVE_THEME = "winter"` unless noted.

## Coverage (US1, SC-001)

`specs/014-park-city-art/coverage.md`, Stage 3: 219 kinds, 68 exact, 37 substitute, 114 stand-in. Placements: 1,660
exact, 411 substitute, 2,542 stand-in. Thirteen exact kinds sit outside the 0.6 to 1.6 scale window and are flagged
in the report as stand-in candidates (cupcake 4.0, football 2.86, see_saw 2.11, water_tank 0.34, and others); by R-02
only substitutes fail the generator on scale. The owner build list is at the end of the report.

## Theme switch (US2, SC-002)

- `ACTIVE_THEME = "city"` then regenerate: the only change in `ParkCity.luau` is the `activeThemeId` line.
- Plaza landmark: `mega_tree` in `winter` (stand-in until Stage 3, the `dt_mega_tree` mesh from Stage 3), `giant_duck`
  in `city`, both on the same row (`slotRows`), same tier, bulk and dims.
- Winter contrast: roads `w-asphalt` (0.251, 0.267, 0.294), lawns `w-grass` (0.894, 0.914, 0.937); the Lune contrast
  test passes (luminance gap at least 90).

## Light objects (US3, FR-007)

- Jest `LightFieldMeshes.spec` 6 of 6. It caught a real defect first: slots built before a mesh had loaded stayed
  stand-ins for good. Fixed with `LightField.upgrade(kind)`.
- Play: 46 mesh slots of 104 near spawn 1 (winter), 79 of 229 at the spawn 1 lawn (city); never above 450.

## Late-game traversal (US3 T027, FR-010, FR-011)

The client velocity driver (`18·√(D/2)` capped at 32) with `Flags.DebugSize` (switched on for the run and back off
afterwards; the tour sizes now include 60 and 100). Stuck = less than 6 studs of travel in 3 s.

| D | Route | Waypoints reached | Stuck | Result |
| --- | --- | --- | --- | --- |
| 35 | spawn 1, park edge, Ring Road north and east, Spoke east, core street to the Plaza | 7 of 7 | 0 | grew to 40.1 |
| 60 | spawn 1, Ring Road north, Spoke north, core, Spoke west, Ring Road west and south, Spoke south | 10 of 10 | 0 | grew to 78.8 |
| 100 | Ring Road north, Spoke north, core, Glass Tower | 7 of 7 | 0 | Glass Tower eaten (`Taken`), grew to 122.9 |

Notes:

- A straight line from spawn 1 to the Ring Road corner runs into the Giant Oak and its spiral ramp (a park landmark).
  The ball moved slowly there without stopping. It is not a route, and the driver now goes round it.
- The console of that session had many `Vertical violation` lines (energy about 1,500 to 2,000 against about 450 to
  600) and ten `Displacement violation` lines, all for the agent's own ball. They came during the debug run, which set
  the size with DebugSize at the spawn, called RespawnBall and RollAgain, and once had two drivers running at the same
  time. The displacement lines match the respawn teleports. The vertical lines most likely come from resizing a D 1
  ball to D 35 to 100 inside the ground. This is not checked in normal play, so it is listed in
  `docs/release-candidate.md`.
- Unit bounds (`ParkCityClearance`): free width on every route at least 1.25 × the largest ball meant for it, and
  no solid Tier 4 to 6 object on a carriageway. Exempt: anything the smallest late ball (D 35) eats on contact, which
  is the Downtown hoarding ring (needs D 16.6). It closes the ends of the Spokes on purpose, as the core's gate (012).
  The ideal eater reaches D 142.6 against a floor of 115, and the Glass Tower needs D 95.9.

## Budget and benchmark (US4)

- `ParkCityBudget` (winter): unculled 892,157 triangles at the worst probe (Roof Run); 876,493 at spawn 1; Tier 5
  culled 363,693; map-edge scenery 33,408.
- 12-ball benchmark (`ParkHeavyScene` + `ParkHeavySampler`, 75 s server, 60 s client, viewport 1008 × 812, player at
  spawn 1): 60 of 60 seconds at 59.6 to 60.4 fps, 0 throttled seconds. Server parts 1,592 every second, under 2,000.
  The client had 1,530 world parts loaded (with streaming on, close to the whole map) and 46 light mesh slots of 104.
- **Ceilings not set (T032 open).** By R-07 the ceiling is 0.8 × the highest step that held 30 fps. The only step
  measured is the dressed scene itself (876,493, held at 60 fps), so the rule gives 700,000. That is below the scene
  that was just measured as fine, and the budget test would fail on it. Getting a real step above the scene needs a
  stress scene in the same view as the city, which the 009 HeavyScene does not give (it builds its grid 1,500 studs
  up, and its 1,900 parts on top of the city's 1,592 would pass the 2,000-part limit). Owner decision in
  `docs/release-candidate.md`. Until then `ParkCityBudget` reports only.
- `ParkPace` floors pass (first pickup, doorstep, food ladder). Pace changed at spawn 1 after the clearance prune near
  spawns: median-profile final size 77.3 to 46.0 there. Report only; the median of medians went from 52.8 to 49.2.

## Gate 2 (T035)

| Theme | Session | Console |
| --- | --- | --- |
| winter | 12-ball benchmark Play, 75 s | DataStore and profilestore Studio notices; `rbxassetid://203785492` (Studio's own, not in the repo) |
| city | Play, 12 s drive at spawn 1, ate (D 1.0 to 1.02); Plaza `giant_duck` present | same three kinds of line, nothing from game scripts |

Jest (full run, before Stage 3): `LightFieldMeshes` passes. Suites that were already failing before 014 (Downtown
fixtures and 013 expectations): BoosterService, HazardService, Remotes (13 against 14 remotes), AbsorbService,
RunManager, WorldSpawner ("only 0 placements of size 0.5"), ThemeSwitch (Downtown expectations).

## Gate 6 shots (T034 open)

Studio `screen_capture` works in Play and shows the dressed map (seen: `plaza` in winter with the mega tree, memes and
fronts mid-rises; `roof_run` in city: grey stand-in roof buildings, dark streets). The capture lands only in the agent
session's own folder, and copying it into `specs/014-park-city-art/shots/` was refused (outside the project). This is
the same limit 009 recorded. The Blender route renders the world data as grey boxes, which R-12 rules out for this
feature because the shots must show the meshes. So no PNGs are committed yet. The owner can take them from the camera
positions in `specs/012-park-city-map/shots/shots-manifest.json`, plus `edge` (0, 20, -470 looking at 0, 15, -580)
and `overview_high` (0, 900, 700 looking at 0, 0, 0), in both themes.

Second pass, 2026-11-08 (Play, HUD hidden on the client, Studio throttled at 15 fps, which does not affect a still).
The manifest's 11 names already include `roof_run` and `giant_oak`, so the set is 13 views per theme. Captured in both
themes: 11 of the 13, all but the two high overviews. `overview` (y 600) and `overview_high` (y 900) came back as grey
murk, also with fog and atmosphere switched off for the shot; the cause is not known. After two tries they were
replaced with `overview_300` (0, 300, 300 looking at 0, 0, 0), which shows the core and the Ring Road but not the whole
map. **Still not in `shots/`:** the `cp` was refused again (this session cannot run it), so the 24 JPGs exist only in
the agent session folder. To save them, run this from the repo root:

```bash
D=~/.claude/projects/-Users-Roman-Tikhonov-Projects-Personal-rollossal/12cccfb5-7fb6-4a88-a45b-821ccd8d20a5/tool-results
for p in winter-plaza:703431-cim2lm winter-spawn_nw:706297-oaffe1 winter-spawn_ne:707479-7d0ezo \
  winter-spawn_se:708879-qigra0 winter-spawn_sw:709945-vmyut1 winter-duck_island:713544-k7d2vq \
  winter-hedge_maze:714728-swdhpf winter-roof_run:716163-pxoh3n winter-car_park:717430-o7jby4 \
  winter-giant_oak:718677-95ggjf winter-edge:721210-ti3c6u winter-overview_300:770896-4gwunr \
  city-spawn_nw:806726-blzw4l city-spawn_ne:808508-utuqvu city-spawn_se:810175-mfkss0 \
  city-spawn_sw:811908-zj4bf4 city-duck_island:813642-sjdbpc city-hedge_maze:815423-bqzbro \
  city-roof_run:817260-v2p5tu city-car_park:818991-tuoi6p city-plaza:820658-knzjkl \
  city-giant_oak:822374-e5yuxg city-edge:824174-c6pq26 city-overview_300:825958-d48aua; do
  cp "$D/mcp-Roblox_Studio-blob-1794143${p#*:}.jpg" "specs/014-park-city-art/shots/${p%%:*}.jpg"
done
```

Third pass, 2026-11-08 (T042). The overview murk has a cause now: with Studio's graphics quality on `Automatic`, a
throttled Studio does not draw distant geometry. `settings().Rendering.QualityLevel = Level21` (put back to `Automatic`
afterwards) with the HUD and depth of field off shows the whole square. Captured in both themes, so the set is complete
at 13 views per theme plus `edge_ground`: `overview` (0, 600, 480), `overview_high` (0, 900, 700) and `edge_ground`
(-200, 3, -535 looking at 200, 10, -575, along the north band). The small plate floating west of the map in the two
overviews is the Hub at (-760, 0), which is where the layout puts it. Console of both sessions: the same three kinds of
Studio line, nothing from game scripts.

**Still not in `shots/` (T041, T042 open):** the copy was refused a third time by the session's Bash policy, and
`screen_capture` has no output path. The 24 older JPGs come from the command above, and the six new ones from this one,
also run from the repo root:

```bash
D=~/.claude/projects/-Users-Roman-Tikhonov-Projects-Personal-rollossal/98f16ef8-4174-4e16-bd5c-a64fec03f343/tool-results
for p in winter-overview_high:166994-uy4isi winter-edge_ground:191460-9z1ldi winter-overview:198509-dnw7vy \
  city-edge_ground:419926-3xucus city-overview:421841-xcnuqz city-overview_high:423642-y72tfk; do
  cp "$D/mcp-Roblox_Studio-blob-1794144${p#*:}.jpg" "specs/014-park-city-art/shots/${p%%:*}.jpg"
done
```

Fourth pass, 2026-11-08 (T034, T041, T042 still open). The session's Bash policy refused a command that opens with the
same `~/.claude/projects/...` assignment as the copies above (`not-on-allowlist`), so the copy was not tried again and
the policy was not worked around. Whether the session folders still hold the JPGs was not checked. The fallbacks in T041
do not get the images into the repo: `screen_capture` has no output path, so a new capture lands in the session folder
too, and `store_image` only loads a file into Studio. `art/scripts/park_capture_render.py` can write to the repo but
draws grey boxes only, which R-12 says these shots must not be, and R-12's condition (a capture failing twice) is not
met, since the captures work. No grey-box render was saved under the shot names. The two commands above, run by the
owner from the repo root, are what is left.

Fifth pass, 2026-11-09 (T034, T041, T042 still open). The owner copied 19 JPGs into `shots/`, but they are not the Gate 6
set: their blob ids (`1794145…` to `1794148…`) match none of the 30 in the two commands above. All 19 were opened: 15 are
gameplay frames with the HUD on (one is the Results screen), 4 are unnamed views without a HUD, and all are `winter`, so
none can take a `<theme>-<view>.jpg` name. They were left in place, unrenamed. The two copy commands were submitted once
as T041 asks and the session's Bash policy refused them again (`not-on-allowlist`), so nothing was copied. The two
commands above, run by the owner from the repo root, are still what is left.

What the shots show, for the owner's review:

- Plaza landmark: `mega_tree` in `winter`, `giant_duck` in `city`. Fronts mid-rises, the Glass Tower, memes and street
  kit render with their atlases in both themes. Winter roads read dark against snow.
- Still grey blocks (stand-ins on the build list): the Giant Oak (a box with two ellipsoids, and its spiral ramp), the
  Roof Run buildings and the car park. These dominate `spawn_nw`, `giant_oak`, `roof_run` and `car_park`.
- `edge` shows trees and a hedge line in front of plain coloured boxes. The boxes are the most likely part to fail
  "reads as a place" (FR-009). `edge` is at camera height 20. `edge_ground` (height 3) shows the same thing more
  plainly: the silhouette boxes have no windows or roofs and stand on flat ground, next to the mesh trees.
- Pink lines are the inert rail and post placeholders from 012, kept by this feature.
- Crumbs appear only near the ball (the light window), so far views have none. Same in play.
- Console of the `city` capture session: the same three kinds of Studio line as Gate 2, nothing from game scripts.

## Layout changes needing the owner's map approval

The rendered SVGs in `docs/design/maps/` show all three:

- Map-edge band (500 to 620): aprons, hedges, 72 street trees, 40 building silhouettes. Scenery only.
- Spawn clearance: tier 3 and up trail items within 16 studs of a spawn were pruned (10 items, among them the Park Loop
  bench 14.2 studs from spawn 2).
- Six meme spots in the Downtown core (three theme slots: t3 pond cart, t4 cone statue, t5 vacant lot; three plain:
  phone, buffering billboard, banana scale).

## Deviations

- T015: map-edge scenery goes into `ParkCity.luau` `environment.scenery` and not `ParkCityParts.luau`. Parts rows
  become absorbable world objects.
- T018: the carriageway rule exempts objects the smallest late ball eats on contact (the hoarding gate, see above).
- T025: no layout change was needed (supply D 142.6 against a floor of 115).

## Final validation against quickstart (T040 open)

Run 2026-11-08 after the second shot pass, `winter` restored (the five generated files match their earlier checksums).

| Scenario | Result |
| --- | --- |
| Every stage | `scripts/check.sh` exit 0 (593 unit tests), layout `--check` and world `--check` exit 0 |
| 1 Coverage | 219 kinds, all 114 stand-ins have a note, owner build list present |
| 2 Theme switch | Pass: Studio `activeThemeId` `city`, Parts and Light modules unchanged, landmark swaps; contrast test passes |
| 3 Light objects | Pass (rerun below): MeshParts with atlas, stand-in Parts, at most 232 visible of the 450 cap; Jest 6 of 6; console clean |
| 4 Spawns | `ParkPace` floors and doorstep test pass |
| 5 Map edge | **Open (owner)**: SVG approval pending; `edge` and `edge_ground` captured |
| 6 Late game | Pass (rerun below): Lune passes; D 35, 60, 100 reached 26 of 26 waypoints, 0 stuck, Glass Tower eaten |
| 7 Budgets | **Open (owner, T032)**: totals print and the benchmark passed, ceilings not set |
| 8 Gates | Gate 2 passes. **Open (owner)**: shots not in `shots/` (the copy above), no pull request, no owner approval |

The T032 ladder could not run this pass: 10 of 10 seconds sampled in Play were throttled (14.7 to 15.8 fps).

Rerun 2026-11-09: `scripts/check.sh` exit 0. T032 again: 10 of 10 seconds in Play had `RenderStepped` at 15 to 16 with
Heartbeat at 60 to 61 (viewport 1008 × 812), so no unthrottled seconds and no ladder. Sync probe clean on the 27 scripts
this branch changes (a shortened list, not the full probe). Scenarios 5, 7 and 8 stay open as in the table.

Rerun of scenarios 3 and 6 (T043), 2026-11-08, `winter`, sync probe clean, `DebugSize` on for scenario 6 only and back
off afterwards.

Scenario 3, driving toward the nearest edible light object for 25 s from spawn 1 (D 1.0 to 1.55, 156 studs of travel):
46 mesh slots of 104 at the start, peaks of 72 mesh slots and 232 visible, 0 meshes without a `TextureID`, 0 missing
attributes. Jest `LightFieldMeshes` 6 of 6 (Edit).

Scenario 6, client velocity driver in one Play session, stuck = less than 6 studs of travel in 3 s:

| D | Route | Waypoints reached | Stuck | Result |
| --- | --- | --- | --- | --- |
| 35 | spawn 1, Ring Road north and east, Spoke east, Plaza | 8 of 8 | 0 | grew to 40.7 |
| 60 | Plaza, Spoke north, Ring Road north and west, Spoke west, Plaza, Spoke south | 11 of 11 | 0 | grew to 69.9 |
| 100 | Ring Road south, east and north, Spoke north, core, Glass Tower | 7 of 7 | 0 | Glass Tower `Taken`, grew to 115.7 |

The console of this session had only the three Studio lines, with no `Vertical violation` or `Displacement violation`
lines. The earlier run's lines did not come back when one driver ran with no respawn.

## Gate 6: owner approval

- [ ] Owner approval of the shots and of a played build in `winter` and `city`: _pending_
