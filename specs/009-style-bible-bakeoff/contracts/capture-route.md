# Contract: Capture route

## `art/capture/cameras.json`

See `data-model.md` for fields. Example shape (values filled at implementation):

```json
{ "version": 1, "theme": "city", "fov": 70, "resolution": [1280, 720], "shots": [ { "name": "01_spawn_d2", "diameter": 2, "position": [0,0,0], "lookAt": [0,0,0], "lighting": {} } ] }
```

## Lune exporter

```
lune run scripts/capture-export -- --theme city --out art/render/world-city.json
```

- Reads `src/shared/Content/Worlds/Downtown.luau`, `Themes.luau`, `Rules/Layout`, `Rules/ThemeResolve`.
- `--theme` defaults to `city`. `--out` defaults to `art/render/world-<theme>.json` (git-ignored directory).
- Exit 0 on success; non-zero if the theme is unknown or the world fails to resolve.
- Output is deterministic (sorted keys, fixed precision). Does not write under `src/`.

## Blender renderer

Run through the Blender MCP (`blender_execute_blender_code`); the Blender binary is not invoked from the shell.

Inputs: the world JSON, `art/capture/cameras.json`, `art/export/*.fbx`, `art/atlases/<theme>.png`.
Output: `specs/009-style-bible-bakeoff/captures/before/<shot>.png` and `capture-manifest.json`.

Rules:

- Mesh scale: longest side equals the object's `size` (same as `ObjectVisual.buildMesh`).
- Placement: `(x, y + size.Y/2, z)` and yaw about Y in radians.
- FBX import axes match `export_all.py` (`-Z` forward, `Y` up).
- `Boundary` blocks are skipped.
- No random; fixed sample count; one image per shot, 1280×720.
- Does not touch `art/export/`, `manifest.json` or `art/atlases/`.

## Studio path

1. `scripts/studio-preflight.sh`, then `scripts/studio-sync-probe.sh` through `execute_luau`; require
   `mismatches = {}`.
2. For each shot: `screen_capture` with `camera_position` and `look_at_position` from `cameras.json`, in the camera's
   theme.
3. Save as `captures/before/studio_<shot>.png` and add to the manifest with `source: studio-screen-capture`.
4. If the probe shows mismatches after the Rojo wait, record one tooling failure and rely on the offline set.

## Filenames

`01_spawn_d2.png`, `02_street_d5.png`, `03_midgame_d12_30.png`, `04_lategame_d80.png`, `05_overhead_map.png`
(optionally `winter_` prefixed for the second theme).
