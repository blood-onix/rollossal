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

### 013 City asset kit: mesh upload batch 1 and fronts atlas

Needs: (1) upload the 121 FBX files (84 at first; Stage B rebuilt them all and added 12, Stage C added 25, see below) and put each id in `src/shared/Assets.luau` (`meshes.ck_<id>`, now `""`);
(2) upload `art/atlases/fronts/city.png` and `art/atlases/fronts/winter.png` and put the ids in
`Assets.frontsAtlases.city` and `.winter` (now `""`). Stand-in until then: each object draws as its palette-coloured
block part (one warning per key); a fronts object with an empty atlas id has no `TextureID`, with no extra warning.

- 84 meshes in `art/export/ck_*.fbx`, rows in `art/export/manifest.json` (Blender 5.2.3, one `Palette` material each):
  building 25 (6 houses, 9 shops and shop rows, 6 mid-rise, 4 towers), street 11, park 16, suburbs 7, main street 5,
  downtown 6, signage 7, meme 7. The 17 shop, billboard and buffering-billboard meshes use the fronts atlas; the other
  67 use the theme atlas.
- Shop names are final: `docs/design/shop-names.json` has 22 `clear` names in cells `sign_00` to `sign_21` (the rest
  were dropped as close to real businesses). Both fronts atlas PNGs were regenerated with them
  (`python3 art/scripts/fronts_atlas.py`), so upload the regenerated PNGs, not an earlier copy.
- Also re-upload the 87 rebuilt `dt_*` FBX files (`art/export/dt_*.fbx`, see the next section); they keep their keys, so
  replace the ids in `Assets.meshes.dt_<id>` in the same pass. `dt_kiosk` is among them, at 184 triangles (see the next section).
- Gate 6 images: `specs/013-city-asset-kit/contact-sheets/<city|winter>/` (building, street, park, suburbs, mainstreet,
  downtown, signage, meme, audit up to three pages). The pull request does not merge before the owner approves them.

### 013 Rebuilt `dt_*` meshes (T025, T031)

- All 87 audit "upgrade" and "replace" meshes were rebuilt by `art/scripts/dt_upgrade.py` (one bevel segment on
  hard edges plus window and panel reveals), keeping key, size and bottom-centre origin: 86 up to their class floor,
  `dt_kiosk` to 184 triangles. Their FBX files and manifest hashes changed; the 12 "keep" meshes are byte-identical. The
  old asset ids stay in `Assets.luau` until the owner re-uploads (plan D5).
- `dt_kiosk` stops at 184 of its 1,050 floor: at the floor the winter city's Downtown N10 sum was 580,302 unculled and
  302,436 culled against 550,000 and 290,000. With the other 86 rebuilt the sum is 546,702, so 35 placements leave room
  for 94 more triangles each; the built sum is 549,782 unculled and 271,916 culled. Ceilings are not raised; revisit
  when 009 raises one (`CAPPED` in `dt_upgrade.py`).
- The look of the rebuilt meshes is an automated finish on the old silhouettes; owner taste check (gate 6) is open.

### 013 Tween-appeal rework, Stage A pilot (owner decision 2026-11-07; Phase 9, T065–T075)

**Stage B go: owner approved the pilot images on 2026-11-07**, and the pilot sedan
kept as it is (a rounder, lofted sedan was tried and rejected the same day). Stage B (rollout to every kit and `dt_*` asset, re-run of the 99-mesh
audit) can start. Gate 6 for the whole kit still needs the Stage B images. Report with triangles as % of tier ceiling,
muted share, snow share and sizes: `specs/013-city-asset-kit/contact-sheets/pilot/README.md`. Images in that folder:

- Contact sheets, three-quarter street level and top view: `street-city.png`, `street-winter.png`, `top-city.png`,
  `top-winter.png`.
- Street scenes at D1 and D5: `scene-mainstreet-city-d1.png`, `scene-mainstreet-city-d5.png`,
  `scene-mainstreet-winter-d1.png`, `scene-mainstreet-winter-d5.png`, `scene-suburb-city-d1.png`,
  `scene-suburb-city-d5.png`, `scene-suburb-winter-d1.png`, `scene-suburb-winter-d5.png`.
- Before / after: `before-after-city.png`, `before-after-winter.png`.

Re-upload batch (replace the ids in the same pass as the batch above): the city and winter theme atlases
(`art/atlases/city.png`, `art/atlases/winter.png`; the other four theme atlases were regenerated too, palette only
changed for city and winter), the city and winter fronts atlases (wear cells `fx_snowcap`, `fx_glasslit` and the new
brick and render grime), and eight pilot FBX files: `ck_house_gable_fence`, `ck_shop_row_three`, `ck_tower_slab`,
`ck_street_lamp_double`, `ck_bin_street`, `ck_car_sedan`, `ck_tree_oak`, `dt_fire_hydrant`. Stand-in until then: the
old atlas and mesh ids (or the block stand-ins for `ck_*`).

Owner questions:

- Towers at real storey height fit about 5–6 floors in the 60-stud tier 5 cap; keep the 52-stud tower with 4 tall
  storeys plus plant room, or accept fewer, taller-looking floors? (research R-18)
- Tier moves at real size for the bollard, post box, parking meter and road lamp (Stage B; research R-18).
- The car's roof snow cap is shared geometry and reads as a grey roof panel in city: keep, or split city and winter
  meshes later?
- `dt_fire_hydrant` is lean (220 triangles, 31 % of tier 2) because winter Downtown places it 34 times and the N10 scene
  ceiling (550,000 unculled) has no room for more. Every `dt_*` mesh placed many times has the same limit in Stage B
  unless 009 raises the ceiling.
- Owner play check of the late-afternoon lighting and the pilot meshes in Studio, once uploaded (the Gate 2 check in
  `specs/013-city-asset-kit/playtest.md` checks the values, not the look).

### 013 Tween-appeal rework, Stage B (Phase 9, T076–T079)

**Owner reviewed the Stage B images on 2026-11-08 ("I like it")** and noted the kit is missing small objects: the kit
has 2 tier 1 objects and no tier 2 object under 3.1 studs; the pocket set exists only as old-style `dt_*` meshes.

Every `ck_*` asset rebuilt with the approved direction at real size, the 12 urban props added (traffic lights, parking
meter, e-scooter dock, food truck, phone-repair kiosk, neon rooftop sign, scaffolding, skip, rooftop water tank, sports
car, taxi, motorbike), and the 99 `dt_*` meshes re-audited. **Gate 6 holds the merge** until the owner approves the
images in `specs/013-city-asset-kit/contact-sheets/stage-b/` (README there: per-asset triangles as % of the tier
ceiling, muted and smooth shares):

- Contact sheets, street level and top view, city and winter, by group: `street-*.png`, `top-*.png`.
- Street scenes at D1 and D5, city and winter: `scene-mainstreet-*.png`, `scene-suburb-*.png`.
- Before / after: `before-after-<theme>-<houses-shops|downtown|street|park>.png`.

**Upload done 2026-11-08:** all 121 `ck_*` and 99 `dt_*` ids and the city and winter theme and fronts atlases are in
`src/shared/Assets.luau`. Owner played the rebuilt Downtown on 2026-11-08 through a temporary world switch ("it's ok"). Park City is the active
world and Downtown is not coming back as one, so these meshes appear in the game only once a feature dresses Park City
with them: its objects are plain parts today (only the hub is a mesh).

Upload batch (one pass, replaces every earlier 013 batch above): the 121 `ck_*` FBX files in `art/export/` into
`Assets.meshes.ck_<id>` (37 new keys from Stage B and C, all at `""`); all 99 `dt_*` FBX files (they keep their keys); the city and winter
theme and fronts atlases. The `dt_*` FBX files exported before 2026-11-08 had a swatch bug (87 meshes drawn entirely in
the `w-metal` cell): do not upload any earlier copy. Stand-in until then: block parts for `ck_*`, the old ids for `dt_*`.

Owner questions:

- The new-rule audit (`specs/013-city-asset-kit/audit/audit-rework.md`) gives the `dt_*` meshes 35 keep, 63 upgrade
  and 1 replace (after Stage C) (`dt_kiosk`, capped at 184 triangles). Most upgrades are flat-shaded round parts, which costs no triangles
  to fix; raising tier 3 to 5 buildings and heroes to 60 % of the ceiling does. At what the rules ask, the winter
  Downtown N10 sum would be 879,794 unculled and 601,764 culled against 550,000 and 290,000. Options: smooth-shade only
  now (no cost), raise the ceilings, cut Downtown placements, or move Downtown to `ck_*` assets.
- Owner play check of the Stage B meshes in Studio once uploaded (`ck_*` assets are not placed by any world yet).

### 013 Tween-appeal rework, Stage C: the small end (owner request 2026-11-08; Phase 9, T080–T083)

25 new small kit objects (13 tier 1, 12 tier 2 up to 3.1 studs) and the 19 Downtown pocket meshes rebuilt in the kit
style. **Gate 6:** images in `specs/013-city-asset-kit/contact-sheets/stage-b/`:
- `street-<theme>-small-tier1.png`, `street-<theme>-small-tier2.png`, `street-<theme>-pocket.png`, and their top views;
- the re-rendered D1 and D5 scenes, now with small objects at ball height.

They go in the same upload batch as Stage B: the 121 `ck_*` files and all 99 `dt_*` files.

Owner questions:

- The tennis ball and the bauble stay 8 × 5 spheres (slightly faceted up close) because winter Downtown has 54
  triangles of headroom left (549,946 of 550,000). Accept, or trade placements for detail?
- Names to check in es-es: "Bolsa de patatas" (chip bag), "Magdalena" (cupcake), "Patinete" (kick scooter), "Bici
  infantil" (kid's bike).

## Defaults taken

Open questions settled by their proposed default. The owner can overrule any of them. Each entry: the question, the
default, the spec that records it.

- 013 Stage B, towers and mid-rises: real storey heights, so 52 to 60-stud towers show about 4 to 5 tall storeys plus
  plant room (research R-18; pilot question above stays open).
- 013 Stage B, tier moves: none. Props whose real size passes their tier band keep their real aspect at the band cap
  (bollard, post box, parking meter, road lamp stay in their tiers).
- 013 Stage B, playground trim: seesaw, climbing frame and sandpit stay in the kit but out of default placements
  (`CityKit.notDefault`); they were not reworked.
- 013 Stage B, new prop tiers and zones: traffic lights T4, parking meter T3, scooter dock T3 and motorbike T3 (street);
  food truck T4 and phone-repair kiosk T3 (main street); skip T3 (suburbs); neon sign, scaffolding, water tank, sports
  car and taxi T4 (downtown). The skip stands in for "crane or skip".
- 013 Stage B, props smooth at 60 degrees (buildings at 40), so round parts read smooth and box edges stay sharp.
- 013 Stage B, the tram is a short two-section car (18.75 m authored, 25-stud tier 4 cap).
- 013 Stage B, `w-glow` only on the neon rooftop sign.
- 013 Stage C, the fairy light bulb uses `w-glass-lit` instead of `w-glow` (glow is for tier 4 to 5 heroes only).
- 013 Stage C, the small objects follow real size, so a few sit at their band edge: the padlock and the cupcake at
  0.3 studs, the grocery bag capped at 1.5, and the kid's bike at 3.1 (tier 2).

## Checks moved after two tooling failures

Each entry: the check, the feature, what was tried, and why it failed. A game defect does not belong here; fix it.
Neither does Gate 2's Studio playtest and console read, which must run before the pull request.

- Studio live capture files (009 T010): `screen_capture` returns the image to the agent only, so no `studio_*` file can
  be committed; the offline Blender set is the committed baseline, and composition was compared by eye.
- Procedural EditableMesh benchmark scene (009 T022, T023): the API is off in Play and a mesh made in Edit mode loses its
  content when Play starts. The benchmark ran on the game's own uploaded meshes instead (up to 700k triangles).

## 012 Park City map (owner-only checks)

- [ ] Phone frame rate on a real device (Studio runs gave 55.8 fps minimum on a 1301 x 940 viewport with 12 balls).
- [ ] `growthK` (1.6) and star (20 / 50 / 90) tuning. The pace report (`specs/012-park-city-map/pace-report.md`) is
  the input; spawns 1, 4, 5, 6, 9 and 11 are more than 15 % behind the median for the median profile.
- [ ] Pace sign-off, including the design document's section 5.3 marks (a report in 012, not a gate).
- [ ] Spanish object names (`ParkCityStrings.luau`, a first pass written by the generator script).
- [ ] Knock-off difference: a knocked-off light object (Tier 1 or 2) leaves the stack and is not dropped; it stays taken
  until its normal respawn. Parts (Tier 3 to 6) still scatter.
- [ ] Hedge-maze walls: the client draws at most 450 light objects (nearest first), so a maze piece far from the ball
  can be missing at the edge of the 120-stud radius. Check by playing the maze.
- Publish checklist: `Config.Debug.spawnSlot` must be 0, `Config.Debug.quietAudio` must be false, `Config.Flags.DebugSize` must be false, and `ServerScriptService.LoadStringEnabled` must be off in
  anything published.

## 012 Park City: items from round 2

- Owner by eye: the bob and new-tier wobble cues and the bump thud with `Flags.ReadableRules` on (T016, T047).
- Giant Oak deck: fixed in round 5 (the deck is now a landing at the top of the root ramp, outside the trunk). A D 3 sphere
  walks the ramp onto the deck; driving a real ball up it is still an owner check.

## 012 Park City: items from round 5 (owner feedback of 2026-11-06)

- Owner by play: the Roof Run no longer bumps (bumps now need real contact; the roof buildings are soft obstacles), the
  Terraces and Cottages lanes are wide enough, the four paths to the city and the Park Loop are neither empty nor a
  steering line, and spawns 11 and 12 grow without the hedge maze. The agent could not drive a ball onto a roof (the
  anti-teleport check respawns it).
- Owner tuning: growth is faster after the starter ladders (pace model, median final size about 60 against 26). Spawns 6
  and 12 are still slow in the model. `growthK` and the star thresholds are the first tuning knobs.
- Bump range: `Config.bumpContactTolerance` (2.5 studs) is the server's lag allowance for a bump; tune by feel with the
  bump thud.
