# Implementation Plan: Snow Village Launch World

**Branch**: `004-snow-village` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-snow-village/spec.md`

## Summary

Replace the grey-box room with Snow Village: 64 object types in 5 tiers, a 600 × 600 stud town with an
800 × 800 stud landmark ring, pooled objects that respawn out of sight after 60–120 s, a Blender pipeline
with one palette, winter lighting, per-client culling and the final audio set. The work is mostly **data
and refactoring**: every module that today names `GreyBoxRoom` or assumes one object per tier becomes
world-agnostic, so Candy Town (Feature 011) is data plus assets only.

Technical approach, one line each (reasoning and alternatives are in [research.md](research.md)):

- **Pace gate first** (R1): a pure Lune model of growth proves the placement counts can carry a ball to
  Tier 2 in 60 s and Tier 4 in 240 s *before* the layout is authored. With the proposed `growthK = 0.6` it
  almost certainly does not; the lever is an optional per-world `growthK` in `WorldDef`, an owner decision.
- **Layout is zones, not records** (R2): `placements` are produced from hand-authored zone data by a pure,
  seeded expander (`Rules/Layout`). About 1,500 pooled objects cannot be written by hand, and the expander
  guarantees no overlaps and the "10 Tier 1 objects within 45 studs of every spawn" rule by construction.
- **World-agnostic container** (R3): `Workspace.World` with `Geometry`, `Objects` and `Hub` replaces
  `Workspace.GreyBoxRoom`; `Worlds.active` is picked by `Config.Flags.SnowVillage`.
- **Pool, never destroy** (R4): `WorldSpawner` builds every part once; absorb hides in place, respawn
  restores the same instance. A new `WorldBuilder` module builds geometry, hub, lighting and mesh templates,
  so `WorldSpawner` keeps one job (registry and state).
- **Out-of-sight rule** (R5): pure `Rules/Respawn.canRespawn`; the server knows ball positions and
  velocities, not cameras, so "in sight" is a radius plus a heading cone along the ball's velocity.
- **Client culling** (R6): `WorldCuller` buckets tagged parts by tier and only touches the buckets whose
  state changes; restore always recomputes from the authoritative `Taken` attribute.
- **Streaming** (R7): `StreamingEnabled` on, `StreamingIntegrityMode = PauseOutsideLoadedArea`, and
  `Player:RequestStreamAroundAsync` before a frozen ball is released at a spawn or the hub.
- **Meshes** (R8): one `MeshPart` template per `objectId` via `AssetService:CreateMeshPartAsync`, cloned per
  placement; a procedural fallback part when an asset key has no uploaded ID yet, so layout, gameplay and
  tests never wait for art.
- **Pipeline** (R9, R10): headless Blender scripts write FBX plus a committed `manifest.json` (triangles,
  hash); `scripts/check.sh` verifies the manifest in Lune, so CI needs no Blender. Uploading FBX to Roblox
  is a Studio GUI step the owner does in one sitting (R10).
- **Audio** (R11): music joins the existing `Feedback` module and `Music` sound group; pitch-by-tier and the
  other cues already exist. Final audio IDs come from the owner.

## Technical Context

**Language/Version**: Luau (strict mode, `--!strict` on every file), Roblox engine as shipped with the
installed Studio. Blender (pinned LTS, version recorded by task T001) for art only.

**Primary Dependencies**: Rojo 7.7.1, Jest-Lua (`jsdotlua/jest@3.10.0`), Lune 0.10.5, StyLua 2.5.2, Selene
0.32.0, luau-lsp 1.70.1. Roblox services: `AssetService` (`CreateMeshPartAsync`), `CollectionService`,
`Lighting`, `SoundService`, `ContentProvider`, `Players` (`RequestStreamAroundAsync`). **One new tool,
already owner-approved in the spec**: `blender-mcp` (pinned; exact version recorded by T001, see Tool
Justification below) plus Blender itself and headless `blender --background --python` scripts.

**Storage**: N/A. No profile key, schema or DataStore change. The Book (003) gains 64 `bookId`s as data;
`Profile` stores them as it stores any `bookId`.

**Testing**: Lune unit tests (`SnowVillage`, `Layout`, `Respawn`, `Pace`, `Tiers` cull, `Config`, `Strings`,
`ArtManifest`); Jest-Lua Studio tests (`WorldSpawner`, `WorldCuller`, updated `AbsorbService` and
`RunManager` specs); a 12-bot Studio run (`tests/studio/BotRun.luau`, same mechanism as `JitterProbe`);
Studio MCP playtests with console read and captures; owner playing on the reference phone.

**Target Platform**: Roblox client (PC and phones) and server. Reference phone: Galaxy A53/A54 class
(carried assumption from 003).

**Project Type**: Roblox game (Rojo-managed Luau project) plus an `art/` Blender tree.

**Performance Goals**: 30 fps on the reference phone at Tier 4. Provisional pool of about 1,500 pooled
parts, at most 400 static geometry parts, 12 balls: `Budgets.maxActivePartsPerServer` rises from 500 to
2,000 (a Lune test keeps pool + geometry + balls under it; the number is confirmed or lowered by the
measurement in the final playtest). Meshes: Tiers 1–2 ≤ 300 triangles, Tier 3 ≤ 800, Tiers 4–5 and hub
≤ 2,500 (already in `Config.Budgets.meshTriangles`).

**Constraints**: server alone decides absorb, size, coins (II): the culler and the new rules change no
authority. Rules stay pure (III): the random respawn delay is chosen in `WorldSpawner` and passed in. Every
string through `Localizer` (IX), `en` and `es`. New behaviour behind `Config.Flags.SnowVillage` (VII). No
asset ID outside `Assets.luau` (XI). Text ≥ 18 px and no sound-only information (VI).

**Scale/Scope**: 1 new world, 64 object types, ~1,500 placements, 12 spawn points, 1 hub, 65 meshes. About
9 new Luau files (`SnowVillage`, `Layout`, `Respawn`, `WorldBuilder`, `WorldCuller`, plus tests and a
probe), 14 edited, 1 new script directory (`art/`) and 2 new check steps. See Project Structure.

## Constitution Check

*GATE: passes before Phase 0 research; re-checked after Phase 1 design.* Constitution v1.1.0.

| Principle | Status | How this plan meets it |
| --- | --- | --- |
| I. Fun proven in grey box | **Pass, ordered** | Layout and pooled spawner are first built with procedural placeholder parts and played (agent Studio run plus owner) and recorded in `playtest.md` **before** any Blender mesh is swapped in (spec FR-012). The outside-people round is deferred to 004d by owner decision (spec, Playtest Timing Gate; Constitution I v1.1.0). |
| II. Server authority | **Pass** | Absorb validation is unchanged except that the object is looked up by `objectId` (`Worlds.objectById`). Respawn, hide and restore of pooled parts are server-side. The client culler only changes local presentation and never sends anything. Existing absorb tests move to Snow Village fixtures (F-7). |
| III. Pure, tested rules | **Pass** | New pure rules: `Rules/Respawn` (sight, delay clamp, starvation ceiling), `Rules/Layout` (seeded zone expander, own LCG, no `math.random`), `Tiers.isCulled`. Each ships with fixed-value Lune tests ([contracts/rules-api.md](contracts/rules-api.md)). Random delay and seed enter as arguments. |
| IV. Safe for everyone | **Pass** | Winter town, no gore, no chat, no PvP. Nothing changes the maturity answers. Objects are toys, snowmen, cars, houses; the dog and cat are cartoon, no weapons or alcohol (the market-stall and cocoa-cart content is checked against this list in the Phase B content task). |
| V. Ethical monetization | **Pass / N/A** | No prices, passes or products. Book rewards are existing 003 placeholder cosmetics. |
| VI. Mobile first | **Pass, measured** | 5 s first pickup and 60 s first tier are enforced by construction (cluster rule) and **measured** by the pace model (R1) and the bot run; 30 fps and part budget are recorded on the reference phone in `playtest.md`. Every sound keeps its visual twin (pickup text, tier banner, bump label, results). Streaming settings are tuned for phones (R7). **Open conflict**: the pace model may show the 60 s rule cannot hold with `growthK = 0.6` (F-1); resolved by an owner-approved `growthK`, not by relaxing the rule. |
| VII. Content is data | **Pass** | `Content/Worlds/SnowVillage.luau` is pure data; `Worlds.luau` has no world branches; no module names `GreyBoxRoom` after the refactor (a Lune test greps `src/server` and `src/client`). The flag `Config.Flags.SnowVillage` also gives a one-line rollback. |
| VIII. Player data | **Pass / N/A** | No schema, key or migration change. 64 new `bookId`s are ordinary set entries. |
| IX. Localised strings | **Pass** | About 90 new keys (64 objects, 5 tier names, 5 headlines, 5 rewards) ship with `en` and `es`; `Strings.test` extended. Spanish is a draft for owner review (carry assumption). |
| X. Multi-agent discipline | **Pass** | Own branch; `[P]` tasks touch disjoint files (ownership in Project Structure); one Blender claim and one Studio claim at a time, written on the task; no place files, secrets or live publishing. The Blender MCP server is added to the two config files by one task. |
| XI. Asset pipeline | **Pass with one interpretation** | Every one of the 65 meshes is made in Blender, low-poly, flat-shaded, one palette, within budget, IDs only in `Assets.luau`; no scripted Creator Store models (a check step greps import results, R9). **Interpretation (F-11)**: ground, kerbs, ramps and terrace blocks are primitive `Part`s coloured from the palette, like the grey-box room, not Blender assets. Owner to confirm; if rejected, they become extra meshes (about 10) and the budget table grows. |
| XII. Keep it lean | **Pass** | One new tool (`blender-mcp`), owner-approved 2026-10-26, justified below. `WorldBuilder` and `Layout` each have two users (see Complexity Tracking). No new package. |

**Tool justification (Constitution XII)**: *Problem*: 65 low-poly meshes sharing one palette cannot be
hand-made or kept consistent without a modelling tool, and the repo has no way to author or inspect Blender
files. *Tool*: `blender-mcp` (MCP server that drives a running Blender) for interactive modelling, and
headless Blender scripts for deterministic export and triangle counts. *Pin*: the exact `blender-mcp`
release and Blender LTS version are written into `.vscode/mcp.json`, `opencode.json` and `art/README.md` by
task T001; this plan does not guess a version number because no network lookup was possible while planning
(F-5). *Approval*: owner, 2026-10-26, spec "Owner Approval Gate".

**Quality Gates mapping** (the PR description states how each was met): gate 1 `scripts/check.sh` (its
Lune step now includes the art-manifest test); gate 2 Studio MCP playtest of the grey-box check, the final world and the
12-bot run with console read and phone-size captures of Hud, Book (64 cards) and Results; gate 3 manifest
check plus `Assets.luau` entries; gate 4 every new string in `Strings.luau`; gate 5 `tasks.md` ticks.

**Human Approval Required items**: the new tool is **already approved** (spec). Still needed from the owner,
none blocking the start of work: (1) `growthK` for Snow Village (F-1), (2) the primitive-geometry
interpretation (F-11), (3) the 3D Importer upload session and the audio IDs (F-4, F-12), (4) Blender
installation (F-5). No publish, no price, no DataStore change, no maturity change, no spend.

**Post-design re-check (after Phase 1)**: no new violation. Phase 1 design added no tool beyond the approved
one, kept every progress decision on the server, kept Rules pure (the LCG lives inside `Rules/Layout`, the
delay is an argument), and added no schema key. Complexity Tracking lists the two new modules.

### Findings (spec, constitution and dependency gaps the plan resolves)

- **F-1 Growth pace does not fit the spec's numbers.** With `k = 0.6` and absorb ratio 0.4, a ball that eats
  objects of fraction ρ of its diameter grows its diameter by a factor `(1 + 0.6ρ³)^(1/3)` per pickup. At the
  best case ρ = 0.4 that is 1.26 % per pickup, so Tier 1 → 2 (2 → 5 studs) needs about 73 pickups and 1 star
  (20 studs) about 183. At a realistic ρ = 0.3 it is 0.54 %: about 171 pickups for Tier 2 and 430 for one
  star. Constitution VI wants Tier 2 inside 60 s, so 1.2–2.9 pickups per second from spawn, while the spec
  reserves only ~10 objects per spawn. Full arithmetic in research R1. Plan: build the pace model first;
  budget the Tier 1 micro-zones for ~75–100 objects each; and, if the model fails, add an optional
  `growthK` to `WorldDef` (data, per world) for the owner to set. The 60 s rule stays; the world changes.
- **F-2 Tier 5 landmarks are barely reachable.** Absorb needs `size ≤ 0.4 × D`. A 25-stud object needs
  D = 62.5, a 60-stud object needs D = 150, the top of the tier. "Absorbable once D ≥ 70" holds only for sizes
  ≤ 28. Provisional sizes: cottage 28, town house 34, skating rink 40, clock tower 48 (absorbable from
  D = 70, 85, 100, 120). Eating the clock tower is therefore a very rare event for Feature 008's clip; owner
  can lower the sizes (data) after the 004d round.
- **F-3 Camera and speed clamps are tuned for small balls.** `cameraMaxDistance = 80` is reached at
  D = 20, so a Tier 4–5 ball (D 30–150, radius up to 75) fills the view; `speedCap = 32`. Measured in the bot
  run and phone captures; if bad, the fix is `Config` values only (no code), recorded in `playtest.md`.
- **F-4 Mesh upload cannot be done by an agent.** The design brief says upload through Studio's 3D Importer, a
  GUI tool; the Studio MCP server offers `upload_image` (texture) but no FBX upload, and Open Cloud upload
  would need an API key and a new service (Constitution X, XII). Plan: the procedural fallback (R8) keeps
  every task unblocked; one owner session bulk-imports `art/export/*.fbx` into Studio; an agent then reads
  the resulting IDs and fills `Assets.luau`. An environment switch (`REQUIRE_ASSET_IDS=1`) turns the missing IDs into a
  failure only at the final gate.
- **F-5 Blender and the `blender-mcp` version are not verified.** Blender is not installed on this machine
  (`blender` not on PATH; `uvx` and `uv` are). The pin could not be looked up while planning. T001 installs
  Blender (owner), selects and records both versions, and only then edits the two MCP config files.
- **F-6 CI has no Blender.** `scripts/check.sh` runs on GitHub Actions with Rokit tools only. The triangle
  check therefore reads a committed `art/export/manifest.json` written by the export script (name, tier,
  triangles, SHA-256 of the FBX); Lune (`ArtManifest.test`, inside the existing unit-test step) checks budgets, coverage of every
  `assetKey` and that the hash still matches the file (R9).
- **F-7 Existing code and tests are tied to the grey-box room.** `WorldSpawner`, `BallService` (`spawnSlots`),
  `BallController`, `StuckVisuals`, `JitterProbe` name `GreyBoxRoom`; `AbsorbService` and
  `RunManager.spec` use `Worlds.objectByTier`; `AbsorbService.spec` and `RunManager.spec` use cube ids
  `T1-02`, `Config.respawnDelay` and `result.worldId == "greybox"`. All are listed in Project Structure and
  move to `Worlds.active` and id-free helpers. `GreyBoxRoom` and its Lune test stay (spec FR-002).
- **F-8 Streaming plus a client-owned ball can drop the ball through unloaded ground.** There is no
  character; `BallService` already sets `player.ReplicationFocus = ball`. Teleports to the hub (460 studs
  away) and Roll again need the target area loaded before the ball is unfrozen (R7).
- **F-9 The server cannot see cameras.** The spec's "camera or movement forward view cone" is implemented as
  ball position plus the ball's velocity heading (R5). If the owner wants camera-true sight, the client
  would have to report it, which makes a progress-adjacent input; rejected.
- **F-10 `Config.respawnDelay` (15 s) is used by tests and `WorldSpawner`.** It becomes
  `respawnDelayMin/Max = 60/120`. The grey-box world, kept behind `Flags.SnowVillage = false`, then also
  respawns after 60–120 s; the Studio specs read the new constants instead of the old one.
- **F-11 Primitive geometry versus "all 3D assets in Blender"**: see Principle XI row.
- **F-12 Final audio needs owner choices.** Agents cannot upload audio; `search_asset` may find licensed
  tracks, but a person must listen and approve. Placeholders (`rbxasset://sounds/...`) stay until then.
- **F-13 Book capacity.** 003 designed pages for 4 tiers and "at most 15 cards"; Snow Village has 5 pages and
  18 cards on page 1. `BookUi` has no hard limit in code, but the phone-size capture task must confirm that 18
  cards and 5 page headers fit and scroll at 640 × 360.
- **F-14 Spawn guarantee is on a path, not in a circle.** The spec says `≤ 45` studs along the porch
  "runway". The Lune test measures straight-line distance from the spawn point and requires the cluster to
  lie inside a 45-stud radius **and** inside the 3 s travel radius `18 × 3 = 54` studs; the grey-box run
  confirms the real path.

## Implementation Phases

Order matters: Constitution I puts the grey-box check before any art, and F-1 puts the pace model before the
layout. `/speckit-tasks` turns each phase into tasks; the task ids named in this plan (T001 tool pins and
Blender install, T003 streaming spike, T004 mesh-template spike) are the first tasks of Phase A.

| Phase | Content | Gate to leave the phase |
| --- | --- | --- |
| **A. Spikes and the pace gate** | T001 Blender install (owner), pins for `blender-mcp`, check `serde.hash` supports sha256; T002 add `Blender` to `.vscode/mcp.json` and `opencode.json`; T003 streaming spike (`StreamingIntegrityMode` via Rojo, hub teleport, `RequestStreamAroundAsync`); T004 `CreateMeshPartAsync` and `TextureID` spike; `Rules/Respawn`, `Rules/Layout`, `Tiers.isCulled` with tests; first `SnowVillage` data with `Pace.test` | Spikes recorded in `research.md`; `Pace.test` passes, or the owner has chosen `growthK` |
| **B. World-agnostic core with placeholder meshes** | Config keys and flag; `SnowVillage` content (64 objects, zones, spawn points, environment, hub, lighting) and `Worlds`; `WorldBuilder`; pooled `WorldSpawner` with sight-gated respawn and `refreshCluster`; `AbsorbService`, `BallService`, `BallController`, `StuckVisuals`, `JitterProbe` refactor; Strings (en, es), Icons; Studio specs updated and new `WorldSpawner.spec` | `scripts/check.sh` 0; Jest suites pass; Studio Play shows the world, console clean |
| **C. Grey-box gate (Constitution I)** | `BotRun`, hand-driven first pickup, owner plays PC and phone; tune data and Config only; write `playtest.md` | Owner sign-off recorded in `playtest.md` |
| **D. Client and polish systems** | `WorldCuller` and its spec; streaming settings; lighting; music and preload; phone-size captures (Hud, Book, Results); F-3 camera/speed check | Specs pass; captures stored; ≥ 30 fps measured in Studio |
| **E. Art** | `art/` tree, palette, per-tier models via Blender MCP, `export_all`, manifest, `ArtManifest` test; owner import session; `Assets.luau` IDs; swap and verify sizes/scripts in Studio | `REQUIRE_ASSET_IDS=1 scripts/check.sh` 0; every template within 5 % of `ObjectDef.size` |
| **F. Final verification** | Final `BotRun`, owner on the reference phone (fps, parts), `Flags.SnowVillage = false` smoke test, PR description with gates | SC-001 to SC-005 met; `playtest.md` final section signed |

Parallelism (`[P]` candidates, disjoint files): Phase A rules and tests vs tooling tasks; in Phase B the
content/Strings/Icons files, `WorldBuilder`, the client refactors and the Studio spec updates; in Phase E
each tier's `.blend` is one task, but only one Blender claim at a time, so they run in sequence.

## Project Structure

### Documentation (this feature)

```text
specs/004-snow-village/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R1–R12
├── data-model.md        # Phase 1: WorldDef, objects, zones, pool states
├── quickstart.md        # Phase 1: how to validate end to end
├── contracts/
│   ├── world-content.md # SnowVillage data module, Worlds, Config, Assets, Strings additions
│   ├── rules-api.md     # Respawn, Layout, Tiers.isCulled
│   ├── runtime-api.md   # WorldBuilder, WorldSpawner, WorldCuller, containers, tags, attributes
│   └── art-pipeline.md  # Blender scripts, manifest, check step, import hand-off
├── checklists/requirements.md
├── playtest.md          # created by the grey-box gate task
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
art/
├── README.md                     # pinned Blender and blender-mcp versions, how to run the scripts
├── palette.png                   # the one shared palette texture (generated, committed)
├── scripts/
│   ├── palette.py                # writes palette.png and palette.json (swatch name -> UV centre)
│   ├── export_all.py             # blender --background: .blend -> FBX per object + manifest.json
│   └── tri_report.py             # prints triangles per object (developer aid, same counter as export)
├── source/                       # tier1_crumbs.blend … tier5_town.blend, hub.blend
└── export/                       # <objectId>.fbx × 64, hub.fbx, manifest.json

src/shared/
├── Config.luau                   # EDIT: respawnDelayMin/Max, respawnOutOfSightRadius, respawnViewDistance,
│                                 #       respawnViewCos, respawnHeadingMinSpeed, respawnForceAfterSeconds,
│                                 #       cullTierDelta, spawnClusterRadius,
│                                 #       Budgets.maxActivePartsPerServer 2000, Flags.SnowVillage
├── Assets.luau                   # EDIT: meshes, hub, palette texture, music (IDs only here)
├── Worlds.luau                   # EDIT: pick world by flag; objectsByTier, placements, no objectByTier
├── Content/
│   ├── GreyBoxRoom.luau          # EDIT: widen shared types (WorldDef) only; data unchanged
│   ├── Icons.luau                # EDIT: glyphs for the 5 tier headlines (glyph check in capture task)
│   └── Worlds/SnowVillage.luau   # NEW: pure data (tiers, 64 objects, zones, spawn points, hub, lighting)
├── Localization/Strings.luau     # EDIT: ~90 keys, en + es
└── Rules/
    ├── Respawn.luau              # NEW: pure sight rule + delay clamp + starvation ceiling
    ├── Layout.luau               # NEW: pure seeded zone expander (jittered grid)
    └── Tiers.luau                # EDIT: isCulled

src/server/
├── WorldBuilder.luau             # NEW: geometry, hub, lighting, mesh templates, tags
├── WorldSpawner.luau             # EDIT: pool registry from Worlds.active, sight-gated respawn, slots
├── AbsorbService.luau            # EDIT: objectById, no objectByTier, optional world growthK
├── BallService.luau              # EDIT: spawn slots from world data, RequestStreamAroundAsync
├── RunManager.luau               # EDIT only if it reads objectByTier (checked in the refactor task)
└── Main.server.luau              # EDIT: WorldBuilder before WorldSpawner

src/client/
├── WorldCuller.luau              # NEW: sub-tier culling
├── BallController.luau           # EDIT: ground filter on Workspace.World
├── StuckVisuals.luau             # EDIT: clone object visual by objectId (template), no grey cube
├── Feedback.luau                 # EDIT: looped music in the Music group, preload mesh/texture/music IDs
├── BookUi.luau                   # EDIT only if captures show 18 cards do not fit (F-13)
└── Main.client.luau              # EDIT: start WorldCuller

tests/
├── unit/
│   ├── SnowVillage.test.luau     # NEW: content validation (FR-004)
│   ├── Layout.test.luau          # NEW
│   ├── Respawn.test.luau         # NEW
│   ├── Pace.test.luau            # NEW: growth pace model (R1), the F-1 gate
│   ├── ArtManifest.test.luau     # NEW: budgets, coverage, hash, hard-coded id scan
│   ├── Tiers.test.luau           # EDIT: isCulled
│   ├── Config.test.luau          # EDIT: new keys, budgets
│   ├── Strings.test.luau         # EDIT: new keys, es completeness for SnowVillage keys
│   └── run.luau                  # EDIT: register new tests
└── studio/
    ├── WorldSpawner.spec.luau    # NEW: pooling identity, sight-gated respawn, starvation, clusters
    ├── WorldCuller.spec.luau     # NEW: cull, restore on shrink, Taken respected
    ├── BotRun.luau               # NEW: 12 playerless balls for 240 s, reports tiers, parts, errors
    ├── AbsorbService.spec.luau   # EDIT: Snow Village fixtures, respawn delay constants
    ├── RunManager.spec.luau      # EDIT: objectById, worldId from Worlds.active
    └── JitterProbe.luau          # EDIT: container name

scripts/check.sh                  # EDIT: guard "no GreyBoxRoom in src/server|client" (art manifest runs in the Lune step)
scripts/art-sync.luau             # NEW: writes art/scripts/budgets.json from Config and SnowVillage
default.project.json              # EDIT: Workspace.StreamingEnabled, radii, integrity mode
.vscode/mcp.json, opencode.json   # EDIT: blender-mcp, pinned (T001)
```

**Structure Decision**: keep the existing Rojo tree. World content is one data module under
`Content/Worlds`; the two new pure rules go in `Rules`; builder, culler and the art tree are new files, each
with one owner task so `[P]` tasks stay disjoint. `WorldBuilder` is added only because geometry, hub,
lighting and mesh templates would double `WorldSpawner`, which is already 310 lines (see below).

## Complexity Tracking

| Addition | Why Needed | Simpler Alternative Rejected Because |
|----------|------------|-------------------------------------|
| `WorldBuilder` next to `WorldSpawner` | Builds geometry, hub, lighting, mesh templates and placeholder parts; used by the real server start and by the Studio specs that need a world without running the full server | Folding it into `WorldSpawner` makes one 600-line module that mixes build-once code with per-frame state; two current users justify the split |
| `Rules/Layout` seeded expander | ~1,500 placements are not hand-writable; the Lune tests and the runtime both call it, and it makes the spawn-cluster rule true by construction | A generated, committed placements file drifts from the zone data and is reviewed as noise; plain hand-written records do not scale |
| Optional `growthK` on `WorldDef` (only if R1 fails) | Reaching Tier 2 in 60 s may be impossible with 0.6 | Relaxing the 60 s rule is a constitutional change; adding objects without limit breaks the part budget |
