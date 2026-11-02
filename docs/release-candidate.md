# Release-candidate list

What waits for the release candidate (RC): a build on the private test place with the launch world in its final
layout and art, the juice pass and every feature in launch scope. The owner declares it (constitution, preamble).

Anything that needs a person, a real device, the final map or owner taste goes here, not in `tasks.md`. Nothing on
this list holds a feature; only the constitution's Human Approval list can stop one (Quality Gates).

The round with outside people (Principle I) also runs on the RC. Record it, and the results of the checks below, in
the feature's `playtest.md`, then tick the item here.

## Checks on the RC

The Downtown map is now the "Inside Out" layout of feature 008 (880 × 880 studs, five rings). The 008 numbers come from
the Lune pace model and the agent-run Studio checks in `specs/008-downtown-inside-out/playtest.md`; the items below
need a person or a device.

### Downtown layout and pacing

Source: `specs/007-downtown-holiday-city/playtest.md` (T015, T016, T035, T039, closed by owner decision, not verified).

- [ ] D 5/12/30/80 timings across the 12 spawns. The bots in rounds 4 to 10 never got past about D 5.6 and only one
  spawn was driven, so this needs a person. Do not build another bot for it.
- [ ] Live shortcut and Car Park checks, in Play. Static geometry is already checked: kerbs 1.2 studs, Car Park ramps
  rise 2 studs, tunnel gap 4.6 studs (sphere cast: D 4.5 passes, D 4.9 and up are blocked), sightlines from 12 of 12
  spawns.
- [ ] Captures at phone resolutions, saved by hand or by the owner. `screen_capture` returns the image only and cannot
  save a file.
- [ ] The owner's layout and pacing sign-off.
- [ ] The final performance and approval pass, including the imported `dt_*` meshes in Play (appearance, single
  material, atlas UVs). So far: 59 to 60 fps with 13 balls and 1,566 parts, at the default Studio viewport rather
  than 640 × 360. Triangle budgets are in `Config.Budgets.meshTriangles`.

**Known pace gap.** The owner's one logged round: D 12 at about 120 s (window 70 to 110 s), D 30 at 240 s (window 145
to 185 s), 1 star (thresholds 20 / 45 / 80), D 80 not reached. One run, one spawn, `winter`, on the placeholder map,
with the HUD size meter hidden behind the top bar (since fixed). The windows come from a greedy-eater model, so this
is not a pass or a fail. `growthK` and the windows stay as they are until the RC.

### Downtown "Inside Out" (008)

Source: `specs/008-downtown-inside-out/` (FR-014, quickstart §6). None of these holds the feature.

- [ ] Owner look-and-feel sign-off for the Stage 1 slice (Old Quarter and the first Terraces block) and for the full map,
  in `winter` and `city`: dark asphalt against light plinths, landmark, bollard gates, the 30-stud main streets.
- [ ] Human-played D 5, 12, 30 and 80 timings from several of the 12 spawns, against the windows in the spec (first
  pickup ≤ 5 s; D 5 at 10 to 50 s; D 12 at 35 to 110 s and D 30 at 65 to 180 s (both lower bounds relaxed again on 2026-11-02, model timings); D 80 by 210 s; D 150 by 240 s). The
  Lune model is the only evidence so far.
- [ ] Captures at phone resolutions (640 × 360, 844 × 390, 1280 × 720), saved by hand or by the owner.
- [ ] Overhead and street-level captures of Stage 1 (Old Quarter and first Terraces block) and of Rings 2 to 5, in
  `winter` and `city` (FR-013, SC-002, T013, T022). `screen_capture` timed out twice in Stage 1 and again in Stage 2
  and again on 2026-11-02, so none was taken; geometry was checked by measurement only.
- [ ] Frame rate with 12 balls in `winter` (≥ 30 fps) over 60 s on the reference phone. The Studio half is met
  (`playtest.md` Gate 2: 60 of 60 unthrottled seconds at 59.9 to 60.1 fps, 0 throttled); the phone is still open.
- [ ] Confirm the plan's deviations D1 to D8 (`plan.md`, "Spec deviations and defaults to confirm") and any pace mark that
  had to be relaxed (`playtest.md` "Deviations").
- [ ] Owner look at the 2026-11-02 changes (`playtest.md` "Owner feedback round"): the 12 doorsteps (pad plus big-kind
  strips), the cosmetic traffic on the Terraces ring road and the Boulevard, and whether the city still reads as
  "objects dumped in groups" (parked vehicles and scatter are still random-yaw zones; no road markings or lamps yet).
- [ ] The camera at D 80 (320 studs back) and the fog (500 to 1600) on a phone.

### Style bible, look gate and bake-off (009)

Source: `specs/009-style-bible-bakeoff/` (FR-001, FR-009, FR-010). None of these holds the feature, except where the
constitution amendment is needed before signage or a CC0 import is *authored* (not before this feature merges).

- [ ] Owner approval of the constitution amendment (v4.0.0: Principle IV invented shop names, Principle I and Quality
  Gates gate 6, Principle XI CC0 and shared sign atlas), on its own pull request: https://github.com/blood-onix/rollossal/pull/10. Until
  it is approved no signage is authored and no CC0 mesh is imported into the game.
- [ ] The concept reference image: add it as `specs/009-style-bible-bakeoff/concept-reference.png`. The bible (section
  12) then gets a "checked against the concept" pass.
- [ ] Early phone frame-rate reading on the heavy scene (the mid-range phone): run `tests/studio/HeavyScene.server.luau`
  in Play on a build the phone can join, or tell the agent the model and the reading from the owner's own run. The
  desktop result is 60 fps on every second at 699,872 triangles with 1,851 parts, so the ceilings (550,000 and
  290,000) may need a one-line lowering.
- [ ] Owner taste review of the five "before" shots (`specs/009-style-bible-bakeoff/captures/before/`) against the
  style bible, and of the bake-off renders.
- [ ] A 1,000,000-triangle benchmark step (and the planned 750k): needs the experience's Security setting that enables
  mesh APIs (EditableMesh) in a dev copy, or uploaded meshes of 1,000+ triangles. The step that ran is 700k.
- [x] Choose the asset sourcing rule from `specs/009-style-bible-bakeoff/bakeoff/README.md`. Owner decision, 2026-11-02:
  in-house Blender to the bible's floors and targets. CC0 download and Creator Store inspection declined; the owner can
  reopen the CC0 test after looking at the renders.
- [ ] Accept a reduced SC-003, or reopen the comparison. Only Source 1 (in-house Blender) was run; Source 2 (CC0 pack on
  the atlas, licence recorded) and the side-by-side were declined, so no CC0 licence is verified and the sourcing rule
  is not backed by a comparison (FR-007, FR-008, SC-003 open). See `specs/009-style-bible-bakeoff/bakeoff/README.md`.
- [ ] Approve or decline any `generate_3d` credit spend, only if the generators are turned on (they are off today).
- [ ] Confirm the plan's deviations D1 to D9 (`plan.md`) and the benchmark deviation (`playtest.md` "Benchmark").

### Phone

Source: `specs/004-snow-village/playtest.md` (SC-004 phone half, not met and not waived).

- [ ] Phone check at Tier 4: 30 fps on the reference phone. The owner's run on a Google Pixel 7 Pro read avg
  59 fps, lowest 22 fps, but never reached Tier 4, so it is not a Tier 4 figure. The Studio half is met in Snow Village
  (59.9 fps, min 57, 1,702 of 2,000 parts). The reference phone is still an assumption: Galaxy A53/A54 class, from the
  001 spec, until the owner names one.

### Tuning

Source: `specs/006-jump-boosters-traps/playtest.md` (owner sign-off 2026-10-30 covers the mechanics as built, not their
values).

- [ ] Jump height.
- [ ] Booster durations.
- [ ] Trap strength.
- [ ] Bump knock-back. Two-player bump feel has not been played; only Jest covers it.

## Owner hand-offs

Batch these. The feature has already shipped with its stand-in or fallback. Each entry: what is needed, which feature,
and what stands in until then.

None yet.

## Defaults taken

Open questions settled by their proposed default. The owner can overrule any of them. Each entry: the question, the
default, the spec that records it.

None yet.

## Checks moved after two tooling failures

Each entry: the check, the feature, what was tried, and why it failed. A game defect does not belong here; fix it.
Neither does Gate 2's Studio playtest and console read, which must run before the pull request.

- Studio live capture files (009 T010): `screen_capture` returns the image to the agent only, so no `studio_*` file can
  be committed; the offline Blender set is the committed baseline, and composition was compared by eye.
- Procedural EditableMesh benchmark scene (009 T022, T023): the API is off in Play and a mesh made in Edit mode loses its
  content when Play starts. The benchmark ran on the game's own uploaded meshes instead (up to 700k triangles).
