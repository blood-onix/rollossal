# PR description draft: Snow Village launch world (004)

Status: **in progress** (the owner's play/internal import is not done). This file says how each Quality Gate was met
and what is still open. It is rewritten when the branch is ready.

## What this changes

- Replaces the grey-box room with Snow Village: 64 object types in 5 tiers, a 600 x 600 stud town inside an
  800 x 800 landmark ring, 12 spawn porches, a town square, rooftops, ramps and kerbs, a hub outside the ring.
- Every module that named the grey-box room is now world-agnostic (`Worlds.active`, `Workspace.World`,
  `WorldObject` tag). `Config.Flags.SnowVillage = false` starts the old room again (checked).
- Pooled objects: hidden and restored in place, never destroyed. Respawn 60 to 120 s, only while no ball can
  see the spot (radius 45, 120-stud heading cone), forced after 180 s. Spawn clusters refresh at run start.
- New pure rules `Respawn`, `Layout`, `Tiers.isCulled`, each with fixed-value Lune tests.
- Client culling (`WorldCuller`), `StreamingEnabled`, winter lighting, a looping-music path in `Feedback`.
- All 65 Blender meshes modelled headlessly and exported (`art/source/*.blend`, `art/export/*.fbx`, manifest);
  the palette ships as `art/palette.png` and the studio import of the FBX files is the owner's hand-off.
  Proportion QA sheet at `art/qa/grid.png`.

## Quality Gates

| Gate | How it was met |
| --- | --- |
| 1. `scripts/check.sh` | exits 0: StyLua, Selene, luau-lsp strict, 270 Lune tests (`SnowVillage`, `Layout`, `Respawn`, `Pace`, `ArtManifest`, `Config`, `Strings`, `Tiers`), the new "no GreyBoxRoom in src/server or src/client" guard, the Rules purity guard. |
| 2. Studio playtest, console read, phone captures | Studio MCP runs recorded in `playtest.md` (world build, hand-driven ball, back to hub, culling, rollback, 12-ball bot run); Jest suites pass (96 tests in 5 suites). **Open**: phone-size captures of Hud, Book (18 cards) and Results, the owner's play on PC and phone, fps at Tier 4 on the reference phone. |
| 3. Assets | `Assets.luau` holds every mesh, palette and sound id (meshes are `""` until the owner's import); `ArtManifest.test` scans `src` for hard-coded ids. All 65 meshes are modelled and exported: `art/export/*.fbx` plus `art/export/manifest.json` (65 entries with per-file size and sha256), `art/palette.png` holds the world's palette swatches, and the ArtManifest tests hash the exported files and check the triangle budgets against the real manifest (no fallback mode left). **Open**: the owner's Studio import of the FBX files fills `Assets.meshes`. |
| 4. Strings | 79 new keys with English and Spanish (64 objects, 5 tier names, 5 headlines, 5 rewards); `Strings.test` and `SnowVillage.test` check them. Spanish is a draft for owner review. |
| 5. `tasks.md` ticks | see the file; open items are listed there. |

## Open items that need the owner

1. **`growthK = 1.5` for Snow Village is provisional.** With 0.6 the pace model needs 96 s for Tier 2 and a
   run ends near 15 studs, so "Tier 2 in 60 s" cannot hold. Confirm or change it (`Content/Worlds/SnowVillage.luau`).
2. **SC-003 is not met yet**: in the 12-bot run Tier 3 fell to 11 % and Tier 4 to 7 % available. Tuning is
   data only (more Tier 3 and 4 placements, or a lower `growthK`); see `playtest.md`.
3. Pin the `mcp-for-blender` release in `.vscode/mcp.json`, `opencode.json` and `art/README.md` (T002).
4. The 3D Importer upload session, the final music track (none ships: `Assets.sounds.music` is empty) and the
   primitive-geometry interpretation of Constitution XI (ground, kerbs, ramps are plain parts, not meshes).
5. `LoadStringEnabled` is on in the dev place for Jest and **must be off in anything published**.
6. Streaming radii and integrity mode could not be read back from a script, so they are unverified.

## Not in this PR

Blender meshes: done (T024; the studio import of the exports remains owner work). The grey-box owner sign-off:
recorded 2026-10-26; the phone/PC pass with the real meshes, the audio IDs and `growthK` stay with the owner
(T032). The outside-people playtest (004d, deferred by owner decision), booster and trap behaviour (004b;
only the marker spots are placed).
