# Spec Kit prompts for Park City (012)

Written 2026-11-04 after the Park City design (09-park-city-level.md) and spec 012. Paste each block after its command.
The constitution amendment lands by pull request with the owner's approval (Governance).

## 1. Constitution amendment

Paste after `/speckit-constitution`:

```text
Amend the Rollossal constitution (.specify/memory/constitution.md, now 4.0.0). The owner asked for these changes on 2026-11-04, after features 008 and 010 failed as maps and the owner could not test them. Keep every other principle, the Human Approval list and Governance as they are, keep the plain style, and write a Sync Impact Report. I expect a MINOR bump (4.1.0): the changes add rules and narrow when pace can fail a feature, and redefine nothing incompatibly. Say so if you find otherwise.

1. Principle I and Quality Gates: measure, don't gate, before the map is playable.
   - Growth pace (sizes and tier times against pace windows) MUST be measured and reported by the Lune pace test, and MUST NOT fail a feature before the RC.
   - The pace test MAY fail a feature only on playability floors:
     - every spawn reaches a first pickup within 3 s;
     - the open-route food ladder has no gap (each zone's smallest food is at most 1.25 x the previous zone's largest);
     - the map's coverage rule (no park quarter has more than 5 % of its area more than 40 studs from food, or the equivalent rule the map's design document sets).
   - Add one line to the rationale: the owner could not test 008 and 010 because their gates demanded pace proof from maps that were not ready to play.

2. Principle VII (Content Is Data): a world map comes from one layout.
   - A world map MUST come from a single layout data source, written by a script in scripts/ (for Park City: docs/design/maps/park-city-layout.json from scripts/park_city_layout.py).
   - The script MUST check the layout: no scene or building on a road, path, water or another scene (0 overlaps), the coverage rule, and the budgets. It MUST print the objects per tier.
   - The map pictures (overview, zone maps, close-ups) MUST be rendered from the same data, never drawn by hand.
   - The game's world module MUST be generated from the layout, never edited by hand. A test MUST check that the world data matches the layout.

3. Principle I and gate 6: design before build for maps.
   - A feature whose main output is a world map MUST start from a layout whose rendered maps the owner has approved (as Park City was on 2026-11-04).
   - Gate 6 (fixed shots, and the owner playing the build) still applies at the end.

4. Principle II (Server Authority): server state without a Part.
   - Absorbable objects MAY exist on the server as data only, with no server Part ("light objects", for example Tier 1 and 2 food). Clients draw them near their camera.
   - The server MUST still own their state (available, taken, respawn) and MUST validate every absorb of one against its data position and size, with the same checks as for Parts. The tests/studio absorb-validation rule covers them.

5. Principle XII (Keep It Lean): name what already exists.
   - Python 3 standard-library scripts in scripts/ for design data (design-tokens.py, park_city_layout.py, park_city_render.py, growth-sim.py) are part of the existing toolchain, not a new tool. They MUST NOT use third-party packages.

6. Workflow, under Governance or Principle I: playable first.
   - A large feature SHOULD be staged so that its first stage is a build the owner can play: rules and look on an existing map, or a grey box with fewer objects.
   - Each later stage SHOULD end playable as well.

Update the templates and docs that repeat any changed rule (.specify/templates/*, AGENTS.md, CLAUDE.md, .github/copilot-instructions.md, .claude/skills/speckit-*), and list what you checked in the Sync Impact Report.
```

## 2. Plan for 012

Paste after `/speckit-plan` (on spec `specs/012-park-city-map`):

```text
Plan feature 012 (specs/012-park-city-map/spec.md): build the approved Park City layout as a playable grey box. Inputs: docs/design/09-park-city-level.md (v2, approved), docs/design/maps/park-city-layout.json (the single source of every coordinate), docs/design/maps/README.md, scripts/park_city_layout.py, scripts/growth-sim.py, and the constitution (with the 4.1.0 amendment if it has landed).

How to plan this time. Features 008 and 010 produced large plans and no map the owner could judge. Keep this plan lean and playable:
- Stage the work so that each stage ends in a build the owner can play, and say what they will see at the end of each:
  - Stage A: the size and readability rules on the EXISTING Downtown map, behind flags. That covers bulk and dims, garnish, D 1 start, the six tiers and stars as world data, the heap fix, the wobble and ripple cues, no banners, and the speed cap.
  - Stage B: the Park City world from the layout as Parts, with Tier 1 - 2 thinned if needed to fit the part budget, plus the inert placeholders and the hub move.
  - Stage C: light objects (Tier 1 - 2 as server data plus client drawing) at the full layout density.
  - Stage D: the pace report, fixed shots, the heavy-scene benchmark, the Studio playtest and console read, then gate 6.
- Hard gates are G1 - G8 of the spec and nothing more. Growth pace is REPORTED, never pass/fail. Do not add pace windows, tier-time targets or bot-run pass criteria as gates or tasks. Owner-only checks go to docs/release-candidate.md.
- research.md only for real unknowns (at most about six), each with a decision.
- No contracts that restate the design doc. data-model.md describes the generated world data and the light-object state, and points at the layout JSON for everything else.
- Aim for about 40 tasks or fewer. Prefer changing existing modules (WorldBuilder, WorldSpawner, AbsorbService, BallService, StuckVisuals, WorldCuller, Hud, Worlds, Config, Rules) over new layers. Constitution XII: no new packages; an abstraction needs two current users.

Decisions the plan must make (record each in research.md):
1. How the layout becomes content data. Options: a script that writes src/shared/Content/Worlds/ParkCity.luau from the JSON (compact: only what the game needs), or a Rojo JSON module. Consider the size (the JSON is large because it stores every object position) and how the test proves the world matches the layout.
2. Light objects:
   - how the server stores state for about 3,100 objects;
   - how taken and respawn changes reach clients (a compact delta, not one event per object at join);
   - how clients pool and draw objects within 120 studs and apply cullTierDelta;
   - how an absorb request names a light object and is validated (Principle II);
   - how StuckVisuals draws an eaten light object.
3. Per-world rules: the absorb rule (bulk <= 0.5 D and longest <= 1.5 D), garnish, growth by bulk, the start diameter, tiers, stars, growthK and the speed cap as world data, so Downtown and Snow Village keep today's rules. The pure functions go in src/shared/Rules with Lune tests of fixed values.
4. The heap fix: feature 010's unmerged branch (origin/010-main-street-slice) has a heap redesign (Rules/Heap.luau, StuckVisuals changes) measured at 30+ fps with 12 balls. Decide whether to reuse it, or to apply only the placement fix (inside the surface, long axis along it, <= 0.45 D, bounding box <= 1.25 D).
5. Placeholders: how rails, pads, catapults, bullseyes, water and ice are drawn and kept inert, carrying the data that 013 needs. Deep water is a shallow floor until 013.
6. Fixed shots: where the camera positions live (layout or world data), and the capture route, with the Blender fallback of gate 6 if Studio captures fail.

Also cover:
- the flags: ParkCity, plus a separate heap-fix flag on whenever Park City is on;
- moving the hub to x = -760 when Park City is active;
- the pace report as a Lune test that reads the generated world data and writes specs/012-park-city-map/pace-report.md;
- updating HeavyScene and HeavySampler for Park City;
- the Studio steps from AGENTS.md (preflight, sync probe, 🔒 tasks done by the agent);
- which Downtown tests must keep passing unchanged.
```
