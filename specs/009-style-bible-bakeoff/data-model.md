# Data Model: Style Bible, Look Gate and Prop Bake-Off

No runtime data, no DataStore, no `Profile` field. The entities below are files and constants. World content
(`Downtown.luau`) is read, never written.

## Fixed Camera Shot Set

File: `art/capture/cameras.json` (single source for the Studio and Blender paths).

| Field | Type | Rule |
| --- | --- | --- |
| `version` | integer | 1 |
| `theme` | string | `city` (primary) or `winter` (optional second run) |
| `fov` | number | 70 (Roblox default) |
| `resolution` | `[w, h]` | `[1280, 720]` |
| `shots[]` | array | exactly 5, in this order |
| `shots[].name` | string | `01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map` |
| `shots[].diameter` | number | 2, 5, 12 (30 optional second pose), 80, and `null` for the overhead |
| `shots[].position` | `[x, y, z]` | studs, world space |
| `shots[].lookAt` | `[x, y, z]` | studs, world space |
| `shots[].lighting` | object | copied from the theme: `brightness`, `clockTime`, `fogStart`, `fogEnd`, `atmosphere` |

Invariants: names unique and in order; distance from camera to the ball is `min(320, max(8, 4·diameter))` for the four
ball shots; pitch ≤ 80°; `fov` equals 70; `theme` is a key of `Themes`.

## Capture Manifest

File: `captures/before/capture-manifest.json`, written by the renderer or by hand after Studio shots.

| Field | Meaning |
| --- | --- |
| `generated` | ISO date |
| `source` | `blender-offline` or `studio-screen-capture`, per image |
| `blender` | version string (5.2.3) when offline |
| `worldCommit` | git commit the world data came from |
| `theme` | `city` or `winter` |
| `images[]` | `{name, file, source, sha256}` |
| `parityNotes` | the limits from research R-03 |

Studio images are prefixed `studio_`; offline images keep the plain shot name.

## World Export (intermediate, not committed)

Output of `scripts/capture-export.luau`.

| Field | Meaning |
| --- | --- |
| `theme` | resolved theme id |
| `blocks[]` | `{kind, x, y, z, yaw, sx, sy, sz, rgb}`; `Boundary` skipped |
| `placements[]` | `{id, objectId, assetKey, x, y, z, yaw, size}` |
| `spawns[]` | `{slot, x, z, yaw}` |

Keys sorted, numbers formatted with fixed precision, so the file is byte-identical across runs.

## Style Bible Sections

File: `docs/design/08-style-bible.md`. Each section states a rule and, where measurable, a number.

| # | Section | Measurable content |
| --- | --- | --- |
| 1 | Authority | overrides `06-art-style.md`; list of overridden rules |
| 2 | Colour hierarchy | ground < building < accent < prop; token names only |
| 3 | Proportions and edge treatment | chunky silhouettes, bevel width in studs |
| 4 | Triangle utilisation | per-class and per-tier floor and target (table) |
| 5 | Facades, awnings, signs | awning depth, invented shop names, banned list |
| 6 | Roads and pavement | dark road, yellow lines, crossings, pale sidewalk, kerb |
| 7 | Trees, lamps and props | even spacing in studs, non-random orientation rule |
| 8 | Lighting | warm sun values from `Themes.city` |
| 9 | Themes | `city` first; `winter` as dressing, `w-season` an accent never a blanket |
| 10 | The ball | heap look: what the absorbed objects show |
| 11 | Sourcing rule | the owner's rule and the bake-off result |
| 12 | Concept reference | path, status (absent or checked) |

### Triangle floor and target table (proposal)

| Tier | Budget | Floor (about 30 %) | Target (about 55 %) | Today's `dt_*` median |
| --- | --- | --- | --- | --- |
| 1 | 500 | 150 | 275 | 72 |
| 2 | 700 | 210 | 385 | 108 |
| 3 | 1,500 | 450 | 825 | 136 |
| 4 | 3,500 | 1,050 | 1,925 | 216 |
| 5 | 5,000 | 1,500 | 2,750 | 272 |

Per-class overrides (for example a hydrant at 2.4 studs) are added after the bake-off. Applies to new assets only.

## Bake-Off Candidate Matrix

File: `bakeoff/README.md`. Rows: 5 props. Columns: 4 sources.

| Field per cell | Meaning |
| --- | --- |
| `source` | `blender-upgrade`, `cc0-pack`, `generate_3d`, `creator-store` |
| `triangles` | count |
| `look` | 1 to 5 against the bible |
| `atlasFit` | 1 to 5, UVs in one cell or strip, one material |
| `effort` | minutes |
| `licence` | text and URL for CC0 and Creator Store; `own` for Blender |
| `cost` | credits or money; 0 for the free sources |
| `status` | `done`, `not run (reason)` |
| `render` | relative path of the PNG |

Props: `hatchback`, `shop_front`, `bench`, `street_tree`, `fire_hydrant`. Upload hand-off list: at most 5 props, each
with the chosen source.

## Measured Scene Triangle Ceiling

File: `playtest.md` (results) and two constants in `tests/unit/Downtown.test.luau`.

| Field | Meaning |
| --- | --- |
| `step` | 300k, 500k, 750k, 1M triangles (unculled set) |
| `culledSet` | tier ≥ 4 triangles at that step |
| `parts` | server part count (< 2,000) |
| `balls` | 12 |
| `theme` | `winter`, plus `city` for the passing step |
| `samples` | 60 per-second fps values |
| `throttledSeconds` | count at exactly 15 fps |
| `lowest`, `average` | over unthrottled seconds |
| `verdict` | pass if ≥ 30 fps on unthrottled seconds |

Derived: `UNCULLED_TRIANGLE_CEILING = floor10k(0.8 × highest passing step)`;
`CULLED_TRIANGLE_CEILING` from that step's culled set the same way.
