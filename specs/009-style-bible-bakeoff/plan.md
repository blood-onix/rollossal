# Implementation Plan: Style Bible, Look Gate and Prop Bake-Off

**Branch**: `009-style-bible-bakeoff` | **Date**: 2026-11-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-style-bible-bakeoff/spec.md`

## Summary

Give the art direction a written bar, a repeatable way to look at the game, a sourcing decision backed by evidence, and
a measured triangle ceiling. No gameplay, rule, world-layout or mesh-export change. Strands, in dependency order:

0. **Constitution amendment gate (prerequisite, FR-001).** The constitution (v3.0.0) has not been amended for the
   2026-11-02 owner decisions. The plan makes `/speckit-constitution` the first delivery step and names the exact
   wording (R-01). Three kinds of work are blocked until it lands: invented shop signage, a CC0 import, and the visual
   gate itself. Not blocked: the capture route, the benchmark, drafting the style bible.
1. **Fixed camera set and capture route (US1).** One `cameras.json` defines five shots (`01_spawn_d2`, `02_street_d5`,
   `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map`). Primary path: Studio `screen_capture`. Fallback: a Lune
   exporter dumps the resolved `city` world to JSON and an offline Blender renderer draws it from the same cameras,
   using `art/export/*.fbx` and the theme atlas. The "before" set of the current post-008 map is committed to
   `captures/before/` (R-02 to R-04).
2. **Style bible (US2).** `docs/design/08-style-bible.md`, linked from `docs/design/README.md`, overriding
   `06-art-style.md` on conflict. The conflicting lines in `README`, `02`, `05`, `06`, `07` and `tokens.md` are listed
   and fixed or pointed at the bible (R-05 to R-07).
3. **Prop bake-off (US3).** Five props (`hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`) from up to
   four sources, rendered on one neutral stage under the same lighting, with a scored matrix in
   `bakeoff/README.md` and the sourcing rule written back into the bible (R-08 to R-11). Bake-off meshes stay out of
   `art/export/` and the manifest.
4. **Heavy-scene benchmark (US4).** A procedural scene (EditableMesh, no uploads) is stepped up in triangles with 12
   balls, sampled per second in Studio, and the 250,000 / 100,000 ceilings in `Downtown N10` and
   `docs/design/03-city-level.md` are replaced by measured values (R-12 to R-14). One early phone-fps ask goes to the
   owner and is tracked on `docs/release-candidate.md`; it does not block.
5. **Docs and RC items.** README contents link, `03-city-level.md` ceilings, `release-candidate.md` entries, and
   `scripts/check.sh` exit 0 (FR-011).

No remote, no DataStore field, no new palette token, no new exported mesh, no new `Rules` file. `Layout.luau`, `Rules/`
and `Downtown.luau` do not change (random placement yaw is 004i/004j, out of scope).

## Technical Context

**Language/Version**: Luau (`--!strict`, Lune 0.10.x via Rokit) for the exporter and tests; Python 3 inside Blender
5.2.3 LTS for the offline renderer and bake-off scenes (same convention as `art/scripts/`); Markdown for the bible and
reports.

**Primary Dependencies**: none new. Existing Rokit toolchain, Blender 5.2.3 LTS driven through the pinned
`mcp-for-blender` 2.2.4 (`art/README.md`), Roblox Studio MCP. Two external resources are used and are covered by
Principle XII below: (a) a CC0 pack download (Kenney or Quaternius) for Source 2, (b) Creator Store inspection for
Source 4. `generate_3d` for Source 3 is credit-gated.

**Principle XII justification line**: the CC0 pack and the Creator Store comparison are evidence inputs to a sourcing
decision, not runtime dependencies; nothing from either ships unless the owner approves a later import. They need the
owner's approval as new external resources (listed under Human Approval).

**Storage**: files only. Camera JSON, capture manifest and PNGs under the feature directory; no DataStore, no `Profile`
field.

**Testing**: `scripts/check.sh` (StyLua, Selene, luau-lsp strict, design-token and palette checks, Lune suite). New Lune
test `CaptureCameras.test.luau` pins the shot set. `Downtown.test` "Downtown N10" is rewritten to the measured ceiling.
Agent-run Studio benchmark and `screen_capture` checks, recorded in `playtest.md`.

**Target Platform**: Roblox, mobile first (30 fps reference phone), 12 players per server. Offline tooling runs on the
owner's Mac (macOS, Blender.app).

**Project Type**: Roblox game (single Rojo project) plus art tooling under `art/` and `scripts/`.

**Performance Goals**: benchmark ceiling is the highest step that holds ≥ 30 fps on unthrottled seconds with 12 balls
and < 2,000 server parts, minus a stated safety margin (R-14). No game-side frame-time change.

**Constraints**: `src/shared/Rules` untouched (purity grep unchanged). One 1,024 px atlas per theme; one material per
mesh; no PBR or transparency (Principle XI). No real brands, logos, flags, memes or faces; invented proper-noun shop
names only after the amendment. New Python under `art/scripts/` is not linted by `check.sh`; new Lune under `scripts/`
is StyLua-checked. Studio throttling at 15 fps is reported separately, never hidden. No script may touch the owner's
desktop (AGENTS.md).

**Scale/Scope**: 5 camera shots × 1 primary theme (+ optional `winter`); 5 bake-off props × up to 4 sources; 1 new
design doc; 1 Lune exporter, 1 Blender renderer script, 1 Studio benchmark script; 1 test rewritten, 1 test added; ~4
doc edits.

## Constitution Check

*GATE: Phase 0 cannot be finalised for the three conflicting rows until the amendment lands. Re-checked after Phase 1
(below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | **Conflict, needs amendment** | v3.0.0 says owner taste "MUST NOT hold a feature". The spec makes the five-shot visual gate hold map and art features. Wording to add is in R-01. This feature itself is not held: it delivers the gate and the evidence. Non-visual owner checks (phone fps) stay on `docs/release-candidate.md`. |
| II Server authority | Pass | No remote, no gameplay code. |
| III Pure, tested rules | Pass | No change under `src/shared/Rules`. New logic is a Lune exporter and pinned constants in tests. |
| IV Safe for everyone | **Conflict, needs amendment** | Bans "words on textures (pictograms only)". US2 and FR need invented shop names and short signage. Real brands, logos, flags, memes, real faces, alcohol or gambling names and "Roblox/Robux/Blox" stay banned. Wording in R-01. Signage is not authored in this feature until the amendment lands; the bible only specifies it. |
| V Ethical monetization | Pass | Nothing sold. |
| VI Mobile first | Pass, to be measured | US4 replaces guessed triangle ceilings with a measured one; fps sampled per second with throttled seconds labelled. Reference-phone reading is an RC item. |
| VII Content is data | Pass | Cameras, shot names and the ceiling are data/constants. World content untouched. |
| VIII Player data | Pass | No profile change. |
| IX Strings | Pass | No player-facing string. Shop names in the bible are art direction, not localisation keys, until a later build feature adds them. |
| X Multi-agent | Pass | Own branch. Rows touching different files are `[P]`. Studio claim goes in `tasks.md` before any 🔒 task. |
| XI Asset pipeline | **Conflict, needs amendment** | Requires 3D assets made or edited in Blender and a 1,024 px atlas per theme. A CC0 mesh remapped onto the atlas in Blender is "edited in Blender" in substance, but the text should say so and allow one shared facade/sign atlas and a capped set of billboard textures. Creator Store models with scripts stay forbidden; mesh-only after inspection. Wording in R-01. |
| XII Keep it lean | Pass with approval | No new package. External CC0 pack, Creator Store inspection and possible `generate_3d` spend need owner approval (below). Justification line is in Technical Context. |

**Human Approval Required** (Constitution, Human Approval list):

1. The constitution amendment itself (PR with owner approval; probably a MINOR bump to 3.1.0).
2. Source 3: one `generate_3d` hero may cost credits. Not run without approval. Currently the addon reports every
   generator OFF, so it is not runnable now either way.
3. Source 2: downloading the CC0 pack (Kenney or Quaternius) as a new external resource, with the licence page recorded.
4. Source 4: Creator Store inspection (read-only; mesh-only models, no scripts). Any upload hand-off is at most 5 props.

None of 2 to 4 holds US1, US2 (draft), or US4. If the owner declines 2 to 4, the bake-off is reported on the sources
that ran and the sourcing rule says so (D4).

### Post-design re-check (after Phase 1)

Unchanged: rows II, III, V, VII, VIII, IX, X pass; rows I, IV, XI remain "needs amendment" and are the gated first
step; VI is measured by US4; XII approvals are listed. Points checked against the design: (a) no file under
`src/shared/Rules`, `Layout.luau` or `Downtown.luau` changes (data-model keeps the world read-only); (b) `art/export/`
and `manifest.json` receive nothing from the bake-off, so `ArtManifest.test` (99 `dt_*`, hash and tier budget) keeps
passing; (c) `Config.Budgets` is not edited, so `Config.test` is unchanged; the ceiling lives as two named constants in
`Downtown.test` (contracts/ceiling-and-tests.md); (d) if `palette.py` gains a shared facade/sign atlas, `--check` must
stay deterministic, and that work is deferred to the build feature that needs it.

## Spec deviations and defaults to confirm

These resolve ambiguities. None changes an owner decision.

- **D1: `captures/before/` is produced offline first.** Studio live shots are taken when Rojo is synced and are
  supplementary. The offline renderer is deterministic and does not need the owner's desktop or a Rojo connection, so
  the committed "before" set does not wait on tooling. The spec allows either path with the same cameras (R-03).
- **D2: benchmark meshes are procedural (EditableMesh) and never uploaded.** No new `Assets.luau` id, no owner
  hand-off for the benchmark (R-12).
- **D3: bake-off assets stay out of `art/export/` and the manifest.** They live under
  `specs/009-style-bible-bakeoff/bakeoff/` (renders, notes) and a Blender scratch file kept out of git, because
  `ArtManifest.test` pins hash and count (R-08).
- **D4: Source 3 is deferred if `generate_3d` is unavailable or the owner declines.** The matrix records "not run" with
  the reason; the rule is written on the three or four sources that ran.
- **D5: the ceiling is the measured step minus a margin, as two constants (unculled, culled).** The spec says
  "measured"; the margin (default 20 % below the last passing step, rounded down to 10,000) is a plan default (R-14).
- **D6: the concept image is absent.** `concept-reference.png` does not exist yet. The bible is drafted from the spec
  and refers to the path; the plan asks the owner once for the image and does not block on it (R-07).
- **D7: triangle counts for the benchmark come from mesh data, not the engine.** Luau cannot read
  `RenderStatsTriangles`, `TriangleCount` or `DrawCallsCount`. Fps is sampled per second with a Heartbeat sampler
  (R-13).
- **D8: the style bible overrides, and conflicting text is edited, not just contradicted.** The pictogram-only lines
  and the "w-season on every top" lines are updated to point at the bible so readers do not meet two rules (R-06).
- **D9: the camera is the default Roblox camera at FOV 70°.** Camera distance by diameter follows the existing
  `Movement.cameraDistance` (D2 → 8, D5 → 20, D12 → 48, D30 → 120, D80 → 320), pitch within the 80° limit (R-02).

## Project Structure

### Documentation (this feature)

```text
specs/009-style-bible-bakeoff/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R-01 … R-14
├── data-model.md        # Phase 1: shot set, capture manifest, bible sections, candidate matrix, ceiling
├── quickstart.md        # Phase 1: how to prove it end to end
├── contracts/
│   ├── capture-route.md     # cameras.json schema, exporter and renderer CLI, filenames, Studio path
│   ├── bakeoff-report.md    # README.md layout, scoring columns, licence and hand-off fields
│   └── ceiling-and-tests.md # new constants, rewritten N10 audit, tests to keep
├── checklists/requirements.md
├── concept-reference.png    # owner-supplied (absent until requested)
├── captures/before/         # 5 PNG + capture manifest (created during implementation)
├── bakeoff/README.md        # created during implementation
├── playtest.md              # agent-run benchmark results (created during implementation)
└── tasks.md                 # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
art/
├── capture/
│   └── cameras.json                 # NEW: the five shots; single source for both paths
└── scripts/
    └── capture_render.py            # NEW: offline Blender renderer (run through the Blender MCP)

scripts/
└── capture-export.luau              # NEW: Lune; resolves the city world to JSON for the renderer

tests/
├── unit/
│   ├── CaptureCameras.test.luau     # NEW: shot names, FOV, D-to-distance, theme, within pitch limit
│   └── Downtown.test.luau           # EDIT: "Downtown N10" uses the measured ceiling constants
└── studio/
    └── HeavyScene.server.luau       # NEW: benchmark builder and per-second sampler (run in Play)

docs/
├── design/
│   ├── 08-style-bible.md            # NEW
│   ├── README.md                    # EDIT: contents link, two pictogram-only lines
│   ├── 02-city-assets.md            # EDIT: signage cross-reference
│   ├── 03-city-level.md             # EDIT: lines 65-66 ceilings
│   ├── 05-roblox-limits.md          # EDIT: line 28 "no words on textures"
│   ├── 06-art-style.md              # EDIT: pointer to 08; w-season-on-every-top lines
│   └── 07-holiday-city.md           # EDIT: line 13 winter caps rule
└── release-candidate.md             # EDIT: phone fps reading, look-and-feel items

.specify/memory/constitution.md      # EDIT in step 0 only, by /speckit-constitution
```

`src/`, `art/export/`, `art/atlases/` and `art/export/manifest.json` are not edited.

**Structure Decision**: extend the existing layout. Capture definitions live in `art/capture/` next to the other art
tooling so both the Lune exporter and the Blender script read the same file. The exporter is Lune because
`Downtown.luau`, `Themes.luau`, `Layout` and `ThemeResolve` are pure modules Lune already loads in tests, so there is no
second implementation of the layout. The benchmark script sits in `tests/studio/` beside `BotRun.server.luau` and is
cloned into the running place the same way, so nothing ships in the game. Bake-off renders and notes live in the
feature directory, not in `art/export/`.

## Delivery order and parallelism

Tasks are generated by `/speckit-tasks`; this is the dependency spine. `[P]` = no shared files, safe in parallel.
🔒 = Studio MCP task; the claim is written in `tasks.md` first and AGENTS.md rules apply.

| # | Slice | Files | Needs |
| --- | --- | --- | --- |
| 0 | **Constitution amendment** (I + Quality Gates, IV, XI wording from R-01), PR for owner approval | `.specify/memory/constitution.md` | Owner approval. Blocks 8 (signage and CC0 import parts) and the visual gate in 12 |
| 1 | Camera definitions and their test | `art/capture/cameras.json`, `CaptureCameras.test.luau` | – `[P]` |
| 2 | Lune world exporter | `scripts/capture-export.luau` | 1 `[P]` with 4, 5 |
| 3 | Offline Blender renderer; "before" shots on `city` (and `winter` if cheap) | `art/scripts/capture_render.py`, `captures/before/` | 1, 2 |
| 4 | Heavy-scene Studio benchmark script | `tests/studio/HeavyScene.server.luau` | – `[P]` with 1–3 |
| 5 | Style bible draft (all sections; concept image path referenced) | `08-style-bible.md` | – `[P]` with 1–4 |
| 6 | Studio live shots, same cameras, supplementary 🔒 | `captures/before/` | 1, Rojo synced; **Studio claim** |
| 7 | Bake-off Source 1 (in-house) and Source 2 (CC0, licence recorded) | `bakeoff/` | 3 (stage), approval 3 |
| 8 | Bake-off Source 3 (`generate_3d`) and Source 4 (Creator Store) | `bakeoff/` | 7; owner approval 2 and 4; amendment 0 for any signage on `shop_front` |
| 9 | Benchmark run: steps 300k / 500k / 750k / 1M, per-second samples 🔒 | `playtest.md` | 4; **Studio claim** |
| 10 | Rewrite N10 and `03-city-level.md` ceilings | `Downtown.test.luau`, `03-city-level.md` | 9 |
| 11 | Bible finish: tier floors/targets from the bake-off, sourcing rule, override list; fix conflicting doc lines; README link | `08-style-bible.md`, `README.md`, `02`, `05`, `06`, `07` | 5, 7, 8, 0 |
| 12 | Visual gate dry run on the "before" set; ask owner for concept image and phone fps; RC entries | `release-candidate.md` | 3, 11, 0 |
| 13 | Gate 2: `scripts/check.sh` exit 0, one Studio playtest, console read 🔒 | `playtest.md` | 10, 11; **Studio claim** |

## Complexity Tracking

| Choice | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| Offline Blender renderer plus Lune exporter | FR needs a repeatable "before" set that does not depend on Rojo sync, Studio focus or the owner's desktop. Studio `screen_capture` is a throttled, manual-sync path. | Studio-only capture was the spec's primary path and is kept; the offline path exists because it is deterministic and survives a disconnected Rojo (R-03). |
| Benchmark by procedural EditableMesh | Needs hundreds of thousands of triangles without uploads or owner steps. | Uploading generated meshes needs owner hand-off and `Assets.luau` ids (R-12). |
| Ceiling as two constants in `Downtown.test`, not `Config.Budgets` | Keeps `Config.test` and runtime code untouched. | A `Config` entry would add a value nothing at runtime reads. |

Constitution rows I, IV and XI are not "violations justified here"; they are conflicts that the first delivery step
resolves by amendment, per FR-001.
