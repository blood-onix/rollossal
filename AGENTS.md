# Agent notes for Rollossal

Read by every coding agent (Claude Code loads it through `CLAUDE.md`; opencode and GitHub Copilot read it
directly, Copilot also through `.github/copilot-instructions.md`). The constitution (`.specify/memory/constitution.md`) still governs; this file is about how to get the work done.

## Design system

`docs/design/` is the art and content direction: the themes (seasons), the city asset list by tier, the
Downtown layout, cosmetics, Roblox budgets and safety rules, and the colour, type and touch tokens. Read its
`README.md` before speccing or building a world, prop, theme, cosmetic or UI screen. It is a proposal: the
items its README lists as needing the owner's approval stay open until a spec or the constitution records the
decision. `tokens.css` and `tokens.md` are generated from `tokens.json`: change the JSON, then run
`python3 scripts/design-tokens.py`.

A world map comes from one layout file (constitution VII). For Park City that is
`docs/design/maps/park-city-layout.json`, written by `scripts/park_city_layout.py`; the map pictures come from
`scripts/park_city_render.py` and the game's world module is generated from the same file. Change the script,
never the JSON, the SVGs or the world module by hand (see `docs/design/maps/README.md`). The Python scripts in
`scripts/` use the standard library only.

## Never take over the user's screen

The user works on this same laptop while the agent runs. Nothing the agent starts may steal focus, move the
mouse, press keys, switch apps or windows, or otherwise act on the user's desktop outside the Studio MCP tools.

- Forbidden, in the foreground or in a background task, loop, cron or `ScheduleWakeup`: `osascript` /
  AppleScript / JXA (`tell application ... to activate`, `System Events`), `open -a`, `cliclick`, `caffeinate`
  tricks that wake the display, `xdotool`, and anything else that raises, focuses or drives an app window.
- Loops are not the problem. Running a test, a playtest, a sampler or a poll in a loop or a background task is
  fine, as long as the loop only touches files, `rojo`, git, the Studio MCP tools or the game itself. What is
  forbidden is a loop (or any one-off) that acts on the owner's desktop: activating or focusing Studio, moving
  the mouse, pressing keys, keeping the display awake.
- Do not "keep Studio awake" or unthrottled by activating it on a timer, and do not stop the laptop from
  sleeping. The owner is working on the machine, so it does not sleep, and Studio is in front whenever they
  want it to be.
- A throttled Studio (15 fps in the background) is a known limit, not a reason to skip a task. Run the
  measurement anyway without touching the window, record per-second samples, report the seconds at exactly
  15 fps as "throttled" separately from the rest, and judge the result on the unthrottled seconds. Do not
  withdraw or hand back a 🔒 task only because Studio might be in the background. If there are no unthrottled
  seconds in the window that matters, ask the owner once to keep Studio in front for the run, then rerun.
- Background tasks may poll files, `rojo`, git or the Studio MCP probe. They may not touch the GUI.
- If a step seems to need this, stop and ask. Approval covers one named action, once, not a loop.

## Studio tasks (🔒) are done by the agent, not handed back

A task marked 🔒 in a `tasks.md` is a Studio check the agent runs through the Studio MCP server. When Studio
MCP is connected, do the task. Do not end `/speckit-implement` with "blocked on Rojo sync" until the steps
below have been tried and the wait has run out.

1. `scripts/studio-preflight.sh` (also runs at session start through `.claude/settings.json`). It starts
   `rojo serve default.project.json` in the background if nothing answers on `localhost:34872`.
2. `list_roblox_studios`, then run the output of `scripts/studio-sync-probe.sh` through `execute_luau`
   (datamodel `Edit`, or `Server` while a playtest runs). `mismatches = {}` means Studio has the repo's code.
3. If there are mismatches, the Rojo plugin is not connected (only a person can press Connect; the MCP mouse
   tool only reaches the game viewport during Play). Ask the user once, keep doing the non-Studio work, and
   re-run the probe every 30 to 60 s (Monitor or ScheduleWakeup) for up to 20 minutes. Continue when it
   passes. Never paste repo code into Studio by hand: Rojo is the only way code gets into the place.

**Two-failure limit.** An agent-run check that fails twice because of tooling, not a game defect, stops there.
Move it to `docs/release-candidate.md` with a note of what was tried, and do not build another driver for it.
A Rojo wait that runs out, or a rerun with still no unthrottled seconds, counts as one failure. A game defect
is still fixed. Gate 2's Studio playtest and console read are exempt: if Rojo stays disconnected, keep doing the
non-Studio work, say so, and do not open the pull request until they have run. The limit also does not excuse a
visual-gate feature from having images: if captures fail, ask the owner once to keep Studio in front and use another
route, such as rendering the world data in Blender.

**Owner checks go to `docs/release-candidate.md`, not `tasks.md`.** That means anything that needs a person, a
real device, the final map or owner taste: no 👤 tasks and no human items. They do not hold the feature; apart from
Gate 2's wait and the visual gate below, only the constitution's Human Approval list can stop one. Tuning values,
phone checks and the people round stay on that list for every feature.

**Visual gate (gate 6).** A feature whose main output is a world map, world art or the look of the player's ball is
not finished until images exist and the owner has approved them, from fixed shots and by playing the build. This
approval can hold the feature. Open the pull request to show the images, and do not merge it before the approval.
Automated tests are a floor for these features and never prove that the look is good.

**Maps and pace (constitution I and VII).** A map feature starts from a layout whose rendered maps the owner has
approved; gate 6 still applies at the end. Stage a large feature so the first stage is a build the owner can play
(its rules and look on an existing map, or a grey box with fewer objects), and end each later stage playable too.
The Lune pace test measures and reports growth pace (sizes and tier times against the pace windows) and never
fails a feature on it before the RC. It fails only on the playability floors: a first pickup within 3 s of every
spawn, no gap in the open-route food ladder (each zone's smallest food at most 1.25 × the previous zone's largest),
and the map's coverage rule.

## How to run the Studio checks

- **Playtest**: `start_stop_play`, then `execute_luau` on `Client` or `Server`. Restart Play after a code
  change: Rojo syncs the Edit place, a running playtest keeps the old code.
- **Server modules are not shared with `execute_luau`**: `require(game.ServerScriptService.RunManager)` from
  the MCP gets a fresh copy, not the one the game is running, so calls like `RunManager.step(...)` do
  nothing to live runs. Let time run (a run is 240 s; start long waits as a background task) or drive the
  game through the client and remotes.
- **Driving the ball**: the client owns the ball's physics. A client-side Heartbeat loop that sets
  `AssemblyLinearVelocity` toward the nearest absorbable cube (`Size` attribute ≤ 0.4 × diameter, `Taken`
  false), at up to `18·√(D/2)` capped at 32, eats like a player without tripping the speed check. A
  vertical teleport below `Config.fallRespawnY` tests the fall path (the anti-teleport check is horizontal).
- **Clicks and keys**: `user_mouse_input` with `instance_path` (for example
  `LocalPlayer.PlayerGui.Results.Dim.Panel.RollAgain`) and `user_keyboard_input` work during Play.
- **Phone sizes**: the MCP cannot resize the viewport. At 640×360, 844×390 and 1280×720 the UI scale is 1,
  so clone the screen's root frame into a frame of that exact size (wrapped in a `UIScale` below 1 if it
  does not fit the Studio viewport), add the 96 px Jump zone (bottom right, 24 px in) and a 120 px thumb
  zone (bottom left), measure `AbsolutePosition`/`AbsoluteSize`, `TextFits`, `TextSize`, and capture it.
- **Glyphs**: a glyph missing from `FredokaOne` renders blank and from `GothamMedium` as a box; check new
  `Icons` entries in a capture with both fonts.
- **Sounds**: `rbxasset://sounds/...` files may stream from Roblox rather than ship on disk; check
  `IsLoaded`/`TimeLength` in Play. Sounds created on first use are still loading when played; preload them.
- **Jest (`tests/studio/runner`)**: Jest-Lua needs `debug.loadmodule` (`FFlagEnableLoadModule`) or
  `loadstring` (`ServerScriptService.LoadStringEnabled`, set in the Properties panel; not scriptable).
  If both are off the suites fail with "loadstring() is not available"; that needs the user, so say so.
  Since 2026-10-25 the owner keeps `LoadStringEnabled` on in the dev place for Jest; it must be off in
  anything published, so flag it in any publish checklist.
- **Console**: `get_console_output` covers the current Play session. Studio's own
  `ContentId rbxassetid://… failed` lines are not from game scripts; grep the repo for the id to be sure.
