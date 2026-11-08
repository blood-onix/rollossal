# Contract: dress table, coverage report and light visual

Three interfaces that more than one agent or test relies on. Internal to the repo; no remote, no player data.

## 1. Dress table (`scripts/park_city_dress.py`)

A Python module exposing:

```text
CURRENT_STAGE: int            # 1, 2 or 3; the build stage being generated
ACTIVE_THEME: str             # "winter" by default; the one-line theme switch
DRESS: dict[str, dict]        # kind -> entry (data-model.md section 1)
SWATCH_ROLE: dict[str, str]   # layout block kind -> w-* role
SLOT_BINDINGS: dict           # theme id -> { slot id -> object id }
THEME_ONLY: dict[str, dict]   # theme id -> { object id -> object fields }
```

Standard library only. `park_city_world.py` imports it and exits 1 on any validation failure in data-model.md section 1.
`--check` also fails when `coverage.md` or `coverage.json` is stale.

## 2. Coverage report

`specs/014-park-city-art/coverage.json`:

```json
{ "stage": 1, "theme": "winter",
  "totals": { "kinds": 219, "exact": 0, "substitute": 0, "standin": 0 },
  "kinds": [ { "id": "bench", "tier": 2, "placements": 40, "status": "exact",
               "assetKey": "dt_bench", "scale": 1.02, "fitChecked": true, "stage": 1, "note": "" } ],
  "ownerBuildList": [ "<kind ids by value>" ] }
```

Rules the Lune test enforces (`ParkCityDress.test.luau`):

1. `kinds` has every id in `ParkCity.objects` and no other (FR-001, SC-001).
2. For each object in the generated world: `assetKey` set means it is in `Assets.meshes` with a non-empty id and in the
   manifest; `assetKey` absent means `role` is in both theme palettes (FR-002).
3. Every `ParkCityParts` and `ParkCityLight` kind has an object (no placement of an unknown kind).
4. `coverage.json` totals equal the counts computed from the world module.

## 3. Light visual (`LightField`)

- Input: `Worlds.light` (rows), `Worlds.objectById`, `Worlds.activeTheme`, `Config.lightPoolCap`, `Config.lightDrawRadius`.
- Output: a client-side Part or MeshPart per visible light id, named by the id, parented to the light folder.
- Invariants: section 6 of data-model.md. The server never reads these parts; a click or touch sends only the id string
  (unchanged). `BallController` still finds them by the `LightObject` tag.
- Failure behaviour: a mesh that fails to load keeps the stand-in and warns once per kind (`ObjectVisual.warnOnce`). No
  error reaches the console twice.
- Covered by a Jest spec `LightFieldMeshes` (every visible slot has the attributes and no scripts; visible count ≤ pool
  cap at a dense point; a kind with a mesh produces a MeshPart with the active atlas `TextureID`) and by `ObjectTemplates`
  unchanged.
