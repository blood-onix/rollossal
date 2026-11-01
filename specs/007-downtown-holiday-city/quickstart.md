# Quickstart: validating Downtown (007)

A validation guide: what to run and what to see. It contains no implementation code. All Studio steps follow
`AGENTS.md` (nothing may take over the owner's screen; the agent uses the Studio MCP only).

## 0. Prerequisites

- Toolchain from `rokit` (StyLua, Selene, luau-lsp, Lune, Rojo). `scripts/studio-preflight.sh` has started
  `rojo serve` on `localhost:34872`.
- For 🔒 steps: Studio is open on the dev place with the Rojo plugin connected. Check with
  `scripts/studio-sync-probe.sh` through `execute_luau`: `mismatches = {}`.
- `ServerScriptService.LoadStringEnabled` on in the dev place (Jest). Off in anything published.

## 1. Pure checks (no Studio, no Blender)

Run `scripts/check.sh`. Expect exit 0 and, in the Lune section:

- `Downtown` tests: counts (74; 18/15/16/16/9), ids, sizes, coins, slots, overlays, keep-outs, spawn density,
  part budget in `winter` and `city`, markers including 5 golden spots.
- `Pace` tests: Downtown × `winter` and `city`, all 12 spawns inside the windows (first pickup ≤ 5 s; Tier 2 10–50 s;
  Tier 3 70–110 s; Tier 4 145–185 s; D ≥ 80 by 240 s).
- `Themes`: `winter.clockTime == 16.5`. `Markers`: golden cases. `Config`: `Flags.Downtown` and the unlock.
- `ArtManifest` and `Strings` cover Downtown.
- The `GreyBoxRoom` guard and the Rules purity guard still pass.

## 2. Grey box in Studio (US1) 🔒

1. Run the sync probe; `mismatches = {}`.
2. `start_stop_play`. On `Server`: `Worlds.active.worldId` (read through the live game's own attributes or the
   built `World` folder names) shows `downtown`; the `World` folder has `Geometry`, `Objects`, `Markers`.
3. Count parts under `Workspace.World`: `≤ 2,000 − 12 − 64`. Console: no warnings from `WorldBuilder`,
   `ObjectVisual` or `ThemeResolve`.
4. Bot run per quadrant (AGENTS.md "Driving the ball"): from at least one spawn per side, drive the greedy eater for
   240 s; record the time of the first pickup and of D = 5, 12, 30, 80. Compare with the windows above.
5. Check the geometry by hand with the bot or with `character_navigation`: kerbs need a jump at D = 2; a D = 6 ball
   cannot enter an alley or the drain tunnel; the Car Park ramp climbs to the top deck; the spring launches onto the
   container stack.
6. `screen_capture` from the four districts and from each spawn toward its landmark: the Ferris Wheel or the Glass
   Tower is visible from every spawn.
7. Owner plays and records the verdict under "Grey box" in `playtest.md`. **No Blender work starts before this.**

## 3. Holiday City and Sunny City (US2) 🔒

1. In `winter`: capture the Plaza (tree, six stalls, cocoa cart), the Park (slope, sleds, rink), Market Street
   (garlands, stoops with crumbs). Snow falls (≤ 40 particles); golden-hour light; the holiday track plays.
2. Book: page "Downtown: Holiday" lists 18 objects; "Downtown: Sunny" lists 5; progress works; no reward shown.
3. Switch: set `activeThemeId = "city"` in `Downtown.luau`, let Rojo sync, restart Play. Same base layout, no
   overlays, no hero variants, five slot stand-ins, sun palette, city music. Console clean. Restore `"winter"`.
4. `tests/studio` Jest suite green, including the updated `RunManager`, `ThemeSwitch` and `WorldSpawner` specs.

## 4. Meshes and performance (US3) 🔒

Per wave: `scripts/check.sh` green with the new `.fbx` in the manifest; owner uploads; ids land in `Assets.luau`;
a capture shows the wave's objects at tier size. `ObjectVisual` warns nothing for a mesh that loads.

Final gate (in `winter`, 12 balls, 640 × 360):

1. Start Play; spawn or simulate 12 balls (bots) across the 12 doorsteps.
2. Sample frame rate each second for 60 s with the MCP; label seconds at exactly 15 fps "throttled" and judge on the
   rest. Pass: ≥ 30 fps on the unthrottled seconds.
3. Record active parts (must be `< 2,000`), per-tier triangle maxima against `500 / 700 / 1,500 / 3,500 / 5,000`, and
   the draw of the heaviest district.
4. Write the numbers and the owner's sign-off into `specs/007-downtown-holiday-city/playtest.md`.

## 5. Rollback check

Set `Config.Flags.Downtown = false`, sync, play: Snow Village loads and `scripts/check.sh` still passes. Set
`SnowVillage = false` as well: the grey-box room loads. Restore both.

## 6. Done when

`check.sh` exits 0; Jest green; US1, US2 and the final capture are recorded in `playtest.md` with the owner's
sign-off; every spec success criterion SC-001…SC-005 has a recorded result.
