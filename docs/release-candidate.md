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
  pickup ≤ 5 s; D 5 at 10 to 50 s; D 12 at 62 to 110 s; D 30 at 105 to 180 s; D 80 by 210 s; D 150 by 240 s). The
  Lune model is the only evidence so far.
- [ ] Captures at phone resolutions (640 × 360, 844 × 390, 1280 × 720), saved by hand or by the owner.
- [ ] Frame rate with 12 balls in `winter` (≥ 30 fps) over 60 s: per-second client Heartbeat (render) frame times, with
  seconds at exactly 15 fps reported as throttled, in Studio and on the reference phone. `playtest.md` Gate 2 has no
  valid figure (its `GetRealPhysicsFPS` samples measure the physics step, not rendering).
- [ ] Confirm the plan's deviations D1 to D8 and any pace mark that had to be relaxed (see `playtest.md` "Deviations").
- [ ] The camera at D 80 (320 studs back) and the fog (500 to 1600) on a phone.

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

None yet.
