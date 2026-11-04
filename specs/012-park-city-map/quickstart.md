# Quickstart: validating Park City

Run from the repo root. Each block is one check. Expected results are in the text after it.

## Before anything (Studio checks only)

```bash
scripts/studio-preflight.sh
```

Then in Claude Code: `list_roblox_studios`, and run the output of `scripts/studio-sync-probe.sh` through
`execute_luau` (datamodel `Edit`). `mismatches = {}` means Studio has the repo's code. If not, ask the owner once to
press Connect in the Rojo plugin and re-run the probe every 30 to 60 s for up to 20 minutes (AGENTS.md).

## Regenerate the world data

```bash
python3 scripts/park_city_layout.py
```

Prints the objects per tier and fails (exit 1) on overlaps, on a park quarter over the 5 % coverage rule, or on a part or
light budget. Expect `overlaps: []` and the coverage table of the README (G2). (Today the script exits 0 on these; the
first Stage B task changes that, as constitution 4.1.0 requires.)

```bash
python3 scripts/park_city_layout.py --check
```

The layout script has no `--check` flag today; the first Stage B task adds one that exits non-zero when the committed JSON
differs from a fresh run. Expect exit 0.

```bash
python3 scripts/park_city_world.py
```

Rewrites `ParkCity.luau`, `ParkCityParts.luau`, `ParkCityLight.luau` and `ParkCityStrings.luau`. Then:

```bash
python3 scripts/park_city_world.py --check
```

Expect exit 0 (nothing would change). `scripts/check.sh` runs this step.

## Gate 1, 2, 4, 5: unit tests

```bash
scripts/check.sh
```

Expect exit 0. It includes the new tests: `Absorb`, `Growth`, `Movement`, `HeapFit`, `Light`, `ParkCity`, `ParkPace` and
the unchanged Downtown tests.

```bash
lune run tests/unit/run
```

Faster loop for the same Lune tests. `ParkPace` rewrites `specs/012-park-city-map/pace-report.md` (deterministic; a
second run leaves no diff).

## Stage A: Downtown with the new rules (flag `ReadableRules`)

Set `Config.Flags.ReadableRules = true` in the working copy, sync with Rojo, then `start_stop_play`. Expect:

- the ball starts at D 1 and the first pickup is within a few seconds;
- grow to about D 10 and check the heap outline against the ball's real size (a `screen_capture` in Play);
- a violin-like long thin object edible when its bulk is under half the diameter;
- a thud, a camera nudge and no text when you hit something too big;
- no tier banner, no "next tier" line, no star-target text.

## Stage B and C: Park City

Set `Config.Flags.ParkCity = true`, sync, `start_stop_play`. Expect:

- `execute_luau` on `Server`: part count of `Workspace.World` descendants plus balls is under 2,000; zero light objects
  among them (count `WorldObject` parts with `Tier <= 2`: 0).
- on `Client`: `LightField` has drawn parts around the ball (the pool count is above 0, at most 450) and `Taken`
  light objects disappear for a second client (`start_stop_play` with simulated players, as `BotRun` does).
- try `Absorb:FireServer("L1")` from a client far from object 1: the server refuses it (check `AbsorbService` return
  through the Studio spec, `tests/studio/AbsorbService.spec`).
- roll from a spawn through a gate to the Plaza; no static geometry blocks a designed route.

## Stage D: report, shots, benchmark, playtest

```bash
lune run tests/unit/run
```

Writes the pace report. Read `specs/012-park-city-map/pace-report.md`: the per-spawn tables and the list of spawns
more than 15 % behind the median. It never fails on these.

```bash
lune run scripts/park-capture-export -- --out art/render/world-parkcity.json
```

Writes the world for the offline renderer. Render the eleven shots (research R6) into `specs/012-park-city-map/shots/` with `art/scripts/park_capture_render.py`
through the Blender MCP (its header has the call).

Heavy-scene benchmark (G6): run `tests/studio/ParkHeavyScene.server.luau` inside Play with `Flags.ParkCity` on and start
`ParkHeavySampler.client.luau`, as its header says. The report lands in the `ParkHeavyReport` attribute and in
`specs/012-park-city-map/playtest.md`: every unthrottled second at or above 30 fps, throttled seconds listed apart,
viewport size recorded.

Studio playtest and console read (G7): `start_stop_play`, play a short route as a bot (`BotRun`), then
`get_console_output`. Expect no new errors or warnings from game scripts.

Gate 6: open the pull request with the shots attached. Do not merge until the owner has approved them and played the
build, recorded in `specs/012-park-city-map/playtest.md`.
