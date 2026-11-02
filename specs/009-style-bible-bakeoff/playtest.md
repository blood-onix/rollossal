# Playtest and measurements: 009 style bible, bake-off, ceiling

Agent-run record. Dates are 2026-11-02 unless stated.

## Capture route

- Offline path (primary for the committed set, D1): `lune run scripts/capture-export -- --theme city` (196 blocks,
  1,403 placements, 12 spawns; two runs are byte-identical, sha1 `9691ef01…`), then `art/scripts/capture_render.py`
  through the Blender MCP (Blender 5.2.3 LTS, EEVEE). All 99 `dt_*` and shared FBX found, none missing. Output:
  `captures/before/01…05_*.png` (1280×720) and `capture-manifest.json`.
- Studio path (supplementary): Rojo synced (spot probe of 5 files, `mismatches = {}`), `screen_capture` run for all 5
  shots with the same cameras. Tooling limit, counted as one failure: the Studio MCP returns the image to the agent
  and cannot write a file (the constitution already says capture files must not be required), so no `studio_*` file is
  committed. Composition was compared by eye and matches the offline set. Differences: Studio shows the winter theme
  (the Edit place's `activeThemeId`), a 568×940 portrait viewport, Roblox lighting and fog, the ball is not drawn in
  either path. Not retried (two-failure rule).

## Benchmark

Run 2026-11-02 in Studio Play on the dev place (desktop, Rojo synced), `tests/studio/HeavyScene.server.luau` cloned into
`ServerScriptService`, `tests/studio/HeavySampler.client.luau` run on the Client through `execute_luau`. One fps sample
per second after a 10 s warm-up, 60 s per step, camera locked on the scene so every triangle is in the frustum. 12
rolling balls and a floor are in the scene. Studio's own `ContentId rbxassetid://203785492 failed` line and the DataStore
`StudioAccessToApisNotAllowed` lines are the known pre-existing noise (grepped: only older playtest notes mention them).

| Step | Triangles built | Culled set (tier 4 to 5, 52.5 %) | Heavy-scene parts | Samples | Throttled (15 fps) seconds | Lowest | Average | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 300k | 299,956 | 157,404 | 800 | 58 | 0 | 59.8 | 60.0 | pass |
| 500k | 499,736 | 262,241 | 1,325 | 60 | 0 | 58.0 | 60.0 | pass |
| 700k | 699,872 | 367,264 | 1,851 | 60 | 0 | 59.9 | 60.0 | pass |

Workspace at the 700k step: 3,632 descendants (the 1,851 heavy parts plus the Downtown world), `Stats.PrimitivesCount`
3,621, `InstanceCount` 52,864. Every second is at the 60 fps vsync cap, so the desktop has headroom the cap hides; the
true limit is above 700k on this machine.

Deviations and findings:

- **EditableMesh is not usable in Play.** First attempt (procedural spheres, R-12) failed with "EditableMesh is not
  accessible. Go to the Security Tab in Experience Settings to enable this API"; a mesh made in Edit mode comes through
  Play with `Content{SourceType=None}`. Counted as the tooling failure for the procedural route (two-failure rule), so no
  third driver was built. The scene instead repeats the game's 15 heaviest uploaded meshes (300 to 564 triangles each).
  Inside the part limit (under 2,000) that reaches about 723,000 triangles, so the planned 750k and 1M steps could not
  run; the highest step is 700k (699,872). A 1M step is an owner item: enable the experience's Security setting for
  mesh APIs in a dev copy, or provide uploaded 1,000+ triangle meshes (`docs/release-candidate.md`).
- First sampler run was invalid: the harness resets the camera to Custom when an `execute_luau` call returns, so the
  scene was out of view. The sampler now re-applies the camera on every render step; the numbers above are from the
  second run, camera confirmed `Scriptable` at (0, 1830, 1).
- The first run's partial window for 300k (58 of 60 samples) is the client attaching a second after the step began.
- The scene is theme-agnostic geometry, so `winter` and `city` were not run separately.
- Desktop at the vsync cap is an upper bound for the mobile target; the margin below and the owner's phone reading
  (RC item) cover that.

## Ceiling

Highest passing step: 700k (699,872 triangles; the planned 750k and 1M steps could not be built inside the part limit,
see Benchmark). Margin 20 % (D5), rounded down to 10,000:

- `UNCULLED_TRIANGLE_CEILING` = floor10k(0.8 × 699,872) = **550,000** (was 250,000).
- `CULLED_TRIANGLE_CEILING` = floor10k(0.8 × 367,264) = **290,000** (was 100,000).

Both are constants in `tests/unit/Downtown.test.luau` ("Downtown N10") and stated in `docs/design/03-city-level.md`. The
current Downtown content is far below them (so the audit still passes); the room is for the style bible's higher
triangle floors. Revisit when the owner's phone reading arrives.

## Visual gate dry run

The five committed "before" shots (offline, `city`) read against `docs/design/08-style-bible.md`, 2026-11-02. The
constitution amendment (v3.1.0) is applied in the same pull request but the owner has not yet reviewed these shots, so
this is a dry run of the gate, not a binding verdict. Where the current map
misses the bible:

| Bible section | Observation in the shots | Shots |
| --- | --- | --- |
| 2 Colour hierarchy | Ground, walls and props are all saturated mid-tones. Parked vehicles in yellow, blue and red fill the yards at the same contrast as the buildings, so no single accent leads the eye. Skyline towers are one flat salmon red. | 03, 04, 05 |
| 3 Edges | Buildings and towers are plain boxes; towers have no bevel, floor bands or window rhythm. | 04, 05 |
| 4 Triangle utilisation | Props look thin up close: cars are 216-triangle boxes with four blocks of wheels; litter on the spawn lane is faceted. | 01, 03 |
| 5 Facades | Buildings are isolated boxes with gaps, not a continuous frontage. Windows are flat blue rectangles; no awnings, signs or shop names anywhere. The ground-floor of the large red building (left, shot 02) is an unbroken wall. | 02, 03 |
| 6 Roads | Road is dark and the sidewalk pale (good), but there are no centre or edge lines and no crossings on the main streets; kerbs read only as a thin lighter band. | 02, 03, 05 |
| 7 Trees, lamps, props | No street trees or lamps are visible along the kerbs in the five shots. Vehicles in the yards are at random yaw. Only the cone row (shot 02) is aligned. | 02, 03, 04 |
| 8 Lighting | Warm sun and soft blue shadows are close to the bible (offline Blender; Roblox adds its own fog and tone mapping, see the Studio comparison). | all |
| 9 Themes | The yards in shot 04 are flat beige and brown slabs, which read as bare ground rather than market or construction site (the park in shot 05 is a flat green slab). | 04, 05 |
| 10 Ball | The ball is not drawn in the offline set, so the heap look cannot be judged from it. | 01 to 04 |

Studio comparison (shots taken live, not saved): same composition; the Studio winter look has lower contrast, a grey
horizon haze and no hard yellow or red accents on the ground, so its colour hierarchy is calmer than the offline one,
and fog softens the skyline.

Biggest gaps, in order: facade continuity and signage, street furniture (trees, lamps, markings, crossings), prop
orientation, and prop detail. Map layout is not changed by 009; these go to the map-design effort.

## Console read

Gate 2, 2026-11-02. Rojo synced (spot probe plus `HeavyScene` and `HeavySampler` present in `ServerStorage.Tests`).
Play session 1: a clean start with the game running for 20 s (1 player, 1,780 workspace descendants, the heavy scene
absent as expected). Play sessions 2 and 3: the two heavy-scene benchmark runs. Console after each: only the known
pre-existing noise (DataStore `StudioAccessToApisNotAllowed`, `[profilestore] … data will not be saved`, three
`ContentId rbxassetid://203785492 failed` lines, which no repo file references outside older playtest notes). The first
benchmark attempt also printed the EditableMesh "not accessible" error from `HeavyScene`; that script was changed and the
runs after it were clean. The harness line "execute_luau changed camera type" is from the sampler call, not the game.
No new warning or error from any game script. This feature changes no `src/` file, so the check is a regression read.

## Deviations

D1 (offline set first) applied. D2 to D9 as in plan.md.
