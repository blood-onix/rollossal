# Implementation Plan: Main-Street Slice

**Branch**: `010-main-street-slice` | **Date**: 2026-11-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-main-street-slice/spec.md` (backlog item 004i)

## Summary

Build a playable ~200 x 500 stud city-theme slice behind a `Config` flag (Downtown stays the default), and fix the
three things that make it read badly: a bare ball, a cluttered HUD, and unreadable size limits. The work runs in
five strands, in dependency order:

1. **Flags and config** (`Config.Flags.MainStreetSlice`, `SliceHud`, `HeapRedesign`, caps and cooldowns) and the
   `Worlds` precedence change, with the two string-pinned tests updated on purpose.
2. **Pure rules** in `src/shared/Rules/`: `StreetRules` (kerbs, sidewalks, lines, crossings, lamps, trees, bins,
   benches, parked cars, seeded jitter), `SceneKit` (kit expansion) and `Heap` (outer-set selection, burial, coverage),
   each with Lune tests using hand-computed values.
3. **Slice content**: `Content/Worlds/MainStreetSlice.luau` (park with 12 spawns, suburb corner, main street,
   skyline), `Content/SceneKits.luau` (10 kits), `Content/Signs.luau` (sign and billboard slots), plus the 004j
   contract describing the rules and kit format.
4. **Presentation**: heap redesign in `StuckVisuals` (client, from the server's longer `Stuck` tail), slice HUD
   gating (no `Next:`, star row or tier banner), and the immediate too-large-contact bump.
5. **Evidence**: 12-ball Studio benchmark (`playtest.md`), five fixed shots in `captures/`, then owner approval
   (gate 6) before merge.

Props are existing `dt_*` meshes or coloured stand-ins. The 009 bake-off meshes are not uploaded, so 004h meshes swap
in later by changing `assetKey` data only. The facade/sign atlas and billboard images are owner uploads; their ids
stay `""` until then and the renderer uses flat colours.

## Technical Context

**Language/Version**: Luau `--!strict`. Python 3 stdlib only for `art/scripts/palette.py` (unchanged).

**Primary Dependencies**: Roblox engine APIs, Rojo, Lune (unit tests), StyLua, Selene, luau-lsp. **No new tool or
package** (Constitution XII; nothing to justify).

**Storage**: None new. `Profile.bestSize[worldId]` already keys by `Worlds.active.worldId`; the new id
`main_street_slice` needs no schema change.

**Testing**: `scripts/check.sh` (gate 1) with new Lune suites; one Studio playtest (gate 2) with the 12-ball benchmark
at 640 x 360, judged on unthrottled seconds.

**Target Platform**: Roblox mobile first (Constitution VI). Phone fps goes to `docs/release-candidate.md`.

**Project Type**: Roblox game (Rojo project), single repository.

**Performance Goals**: 30 fps or more with 12 balls on unthrottled seconds; fewer than 2,000 active parts on the
server (`Config.Budgets.maxActivePartsPerServer`); first pickup within 5 s for all 12 spawns.

**Constraints**: Rules stay pure (no `Instance`, `workspace`, `game`, `task`, `DateTime`, `Vector3`, `CFrame`,
`GetService`, `Enum`, `tick`, `math.random`, `os.clock`, `os.time` or `require(script`). Server remains authoritative
(II). One atlas per theme plus one shared facade/sign atlas, at most 6 billboard textures (XI). Asset ids only in
`Assets.luau`.

**Scale/Scope**: About 1,200 fixed placements maximum (`maxPlacements = 1200`), 10 kits, 12 spawns, 6 billboard slots.

## Constitution Check

*GATE: passes before Phase 0. Re-checked after Phase 1 (below).*

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I Fun proven in grey box | Pass, with visual gate | A map/art/ball-look feature: gate 6 applies. The five fixed shots go in `specs/010-main-street-slice/captures/` and the PR may open before the owner approves, but must not merge until they do. Phone checks and feel tuning stay on `docs/release-candidate.md`. |
| II Server authority | Pass | Server still owns stuck entries, size and score. The heap selection and the too-large bump are presentation on the client and only change the local ball's velocity, as the client already owns the ball's physics. No new remote. |
| III Pure, tested rules | Pass | `StreetRules`, `SceneKit`, `Heap` are pure, self-contained (no `require(script`) and each has a Lune test with hand-computed values. Dependencies are passed as arguments. |
| IV Safe for everyone | Pass | Shop names are invented proper nouns (allowed, no localisation key). Billboards carry no real brands or ads and `sponsored = false`; a test holds a banned-word and real-brand list. Nothing sponsored. |
| V Ethical monetization | Pass | Nothing sold. Sponsored placements are out of scope. |
| VI Mobile first | Pass, to be measured | Budgets live in `Config`. 12-ball benchmark at 640 x 360, unthrottled seconds only. First pickup within 5 s is a Lune check. Reference-phone reading is an RC item. |
| VII Content is data | Pass | World, kits, signs, billboards and caps are data. New behaviour is behind `Config.Flags`. Lune tests validate content. |
| VIII Player data | Pass | No profile change. |
| IX Strings | Pass | The slice HUD removes text, and the bump has none. No new player-facing string. Shop names are exempt (IV). |
| X Multi-agent | Pass | Own branch. `[P]` rows touch disjoint files (table below). Studio claim goes in `tasks.md` before any 🔒 task. |
| XI Asset pipeline | Pass | One shared facade/sign atlas (`Assets.facadeAtlas`) and **6** billboard textures (`Config.billboardTextureCap = 6`, validated by test). Ids only in `Assets.luau`, `""` until uploaded. One material per mesh. |
| XII Keep it lean | Pass | No new tool, package or service. Reuses `HeavyScene`, `HeavySampler`, `BotRun` and the capture route. |

**Human Approval Required** (Constitution list) touched by this feature:

1. Uploading the facade/sign atlas and billboard textures to Roblox, and putting their ids in `Assets.luau`.
2. Gate 6: owner approval of the five shots and of playing the build, before merge.
3. Turning `MainStreetSlice` on by default (this feature leaves it `false`).
4. Any later swap to real 004h meshes (uploads).

## Post-design re-check (after Phase 1)

No conflict found. The `Worlds` chain tests and `Config.test` pins change deliberately and are listed in tasks. The
heap data stays in the existing `Stuck` attribute (no new remote), so II holds. The 004j contract
(`contracts/street-rules-and-scene-kits.md`) is data and rules only. Row XI is the tightest: if the owner wants more
than 6 billboard textures, the cap changes in `Config` and the test, and the XI wording must be checked again.

## Spec deviations and defaults to confirm

The spec left these "locked in the plan". They are defaults; the owner can change any of them before tasks.

- **D1 Dimensions.** 200 x 500 studs, `halfExtent = 250`, zones along z: park [-250, -130], suburb [-130, -60], main
  street [-60, 170], skyline [170, 250]. Boundaries by invisible `Boundary` blocks (R-01, R-02).
- **D2 Flag precedence.** `MainStreetSlice` outranks `Downtown`, `SnowVillage` and the grey box. The pinned chain tests
  in `Config.test.luau` (about lines 357-372) and `Downtown.test.luau` (about line 1039) are updated on purpose (R-03).
- **D3 Placement cap.** `maxPlacements = 1200` for the slice (default is 1500) (R-04).
- **D4 Stand-in props.** The 009 bake-off meshes are not uploaded, so `hatchback`, `bench`, `street_tree` and
  `fire_hydrant` map to existing `dt_*` meshes, and `shop_front`, fruit crates and flowers are coloured stand-ins (R-08).
- **D5 Facade atlas and billboards.** Deferred to owner upload; ids `""`; slots reference atlas regions by name (R-14).
- **D6 Billboard cap.** 6 unique textures (within the spec's 4 to 8).
- **D7 Heap computed client-side.** The server publishes a longer `Stuck` tail (60, was 30); the client picks the
  outer set. Default is A+B+C, confirmed or replaced by measurement (R-09, R-10).
- **D8 Too-large bump.** Client-side, separate cooldown of 0.4 s, gated by `SliceHud` (R-11).
- **D9 Ambient.** Pigeons on in the park, no moving traffic. Controllers start on "world has `ambient`" instead of
  `Config.Flags.Downtown` (R-13).
- **D10 Slice cameras.** A separate `art/capture/cameras-slice.json`; the exporter gains `--world slice`. `cameras.json`
  and its test stay untouched (R-15).
- **D11 Flags.** Three flags (`MainStreetSlice`, `SliceHud`, `HeapRedesign`), all `false`. The spec only names one; the
  other two let the HUD and heap be tested on other worlds.

## Release-candidate hand-off items

`docs/release-candidate.md` could not be edited during planning (the session's edit rules allow only `specs/**` and
`.specify/**`). These items need adding there, under a new "Main-Street slice (010)" subsection, in the first
implementation task:

- [ ] Gate 6: owner approval of `captures/` and of the build, before merge (the only item that holds the PR).
- [ ] Phone frame rate with 12 balls in the slice, against 30 fps.
- [ ] Upload the shared facade/sign atlas and at most 6 billboard textures; set ids in `Assets.luau`.
- [ ] Swap the real 004h meshes in by `assetKey` data (stand-ins: `shop_front`, fruit crates, flowers).
- [ ] Owner look-and-feel review, and sign-off that the size limit reads without text.
- [ ] Decide whether `MainStreetSlice`, `SliceHud`, `HeapRedesign` default to `true` (they ship `false`).
- [ ] Confirm defaults D1 to D11 above.

## Project Structure

### Documentation (this feature)

```text
specs/010-main-street-slice/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── slice-world-and-flags.md
│   ├── street-rules-and-scene-kits.md
│   ├── heap-rules.md
│   └── signs-and-billboards.md
├── checklists/requirements.md
├── tasks.md          # created later by /speckit-tasks
├── playtest.md       # created at implementation (12-ball benchmark)
└── captures/         # five fixed shots, at implementation
```

### Source Code (repository root)

```text
src/shared/
├── Config.luau                         # edit: flags, caps, cooldowns
├── Assets.luau                         # edit: facadeAtlas, billboards (all "")
├── Worlds.luau                         # edit: flag precedence
├── Content/
│   ├── SceneKits.luau                  # new: 10 kits as data
│   ├── Signs.luau                      # new: SignSlot, BillboardSlot
│   └── Worlds/MainStreetSlice.luau     # new: slice world (data + build step)
└── Rules/
    ├── StreetRules.luau                # new, pure
    ├── SceneKit.luau                   # new, pure
    └── Heap.luau                       # new, pure
src/server/
└── BallService.luau                    # edit: publish longer Stuck tail
src/client/
├── StuckVisuals.luau                   # edit: heap redesign
├── Hud.luau                            # edit: slice gating
├── BallController.luau                 # edit: too-large bump
├── Feedback.luau                       # edit: bump sound hook
└── Main.client.luau                    # edit: ambient start condition
scripts/
└── capture-export.luau                 # edit: --world slice
art/capture/
└── cameras-slice.json                  # new
tests/unit/
├── StreetRules.test.luau               # new
├── SceneKit.test.luau                  # new
├── Heap.test.luau                      # new
├── MainStreetSlice.test.luau           # new (spawns, kits, signs, billboards, determinism)
├── CaptureCamerasSlice.test.luau       # new
├── Config.test.luau                    # edit: new pins, chain string
└── Downtown.test.luau                  # edit: chain order pin
tests/studio/
├── HeavyScene.server.luau              # edit: load slice, 12 balls
└── HeavySampler.client.luau            # edit: slice sampling
docs/release-candidate.md               # edit: Main-Street slice (010) section
```

**Structure Decision**: Rules in `src/shared/Rules/` (pure), content in `src/shared/Content/`, presentation in
`src/client/`. This is the same split as 007 to 009. The slice world is a sibling of `Downtown.luau`.

## Delivery order and parallelism

`[P]` rows touch disjoint files and can run at the same time. 🔒 rows need a Studio claim in `tasks.md`.

| # | Strand | Work | Files | Marker | Depends on |
| --- | --- | --- | --- | --- | --- |
| 1 | Config | Flags, caps, cooldowns, `Assets` placeholders, pins in `Config.test` | `Config.luau`, `Assets.luau`, `Config.test.luau` | | none |
| 2 | Rules | `Heap` and test | `Rules/Heap.luau`, `Heap.test.luau` | [P] | 1 |
| 3 | Rules | `StreetRules` and test | `Rules/StreetRules.luau`, `StreetRules.test.luau` | [P] | 1 |
| 4 | Rules | `SceneKit` and test | `Rules/SceneKit.luau`, `SceneKit.test.luau` | [P] | 1 |
| 5 | Content | `SceneKits` data (10 kits) | `Content/SceneKits.luau` | [P] | 4 |
| 6 | Content | `Signs` data | `Content/Signs.luau` | [P] | 1 |
| 7 | Content | Slice world and `Worlds` precedence, test chain updates | `Content/Worlds/MainStreetSlice.luau`, `Worlds.luau`, `Downtown.test.luau`, `MainStreetSlice.test.luau` | | 3, 5, 6 |
| 8 | Presentation | Heap redesign and longer `Stuck` tail | `StuckVisuals.luau`, `BallService.luau` | [P] | 2 |
| 9 | Presentation | Slice HUD gating | `Hud.luau` | [P] | 1 |
| 10 | Presentation | Too-large bump | `BallController.luau`, `Feedback.luau` | [P] | 1 |
| 11 | Presentation | Ambient start condition | `Main.client.luau` | | 7 |
| 12 | Tooling | Slice cameras and exporter option | `cameras-slice.json`, `capture-export.luau`, `CaptureCamerasSlice.test.luau` | [P] | 7 |
| 13 | Gate 1 | `scripts/check.sh` clean | | | 7 to 12 |
| 14 | Studio | 12-ball benchmark, heap candidates compared, `playtest.md` | `HeavyScene.server.luau`, `HeavySampler.client.luau` | 🔒 | 8 to 11, 13 |
| 15 | Studio | Gate 2 playtest and console read | | 🔒 | 14 |
| 16 | Visual | Five shots in `captures/` | | 🔒 | 12, 15 |
| 17 | Docs | 004j contract copy, RC items | `docs/release-candidate.md` | [P] | 7 |
| 18 | Owner | Gate 6 approval before merge | | | 16 |

If two [P] rows need the same file, the later one waits. `Config.test.luau` is touched only by row 1, and
`Downtown.test.luau` only by row 7.

## Complexity Tracking

No Constitution violation to justify. Two choices add complexity on purpose:

| Choice | Why needed | Simpler option rejected |
| --- | --- | --- |
| Three flags instead of one | `SliceHud` and `HeapRedesign` can be tested on other worlds and rolled back separately | One flag (rejected: a heap or HUD defect would force the whole slice off) |
| Self-contained Rules modules (a little duplicated seeded-generator code) | `require(script` is banned in Rules | A shared `Rules/Rng` (rejected by the purity grep) |
