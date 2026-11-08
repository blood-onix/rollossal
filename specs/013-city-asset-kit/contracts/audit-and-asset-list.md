# Contract: Audit and Asset List

Covers FR-001 to FR-004, SC-001 and SC-002. The audit is a file and a script, not a runtime feature.

## Files

| Path | Written by | Checked by |
| --- | --- | --- |
| `specs/013-city-asset-kit/audit/audit.json` | `art/scripts/audit_render.py` | `art/scripts/audit_report.py` |
| `specs/013-city-asset-kit/audit/audit.md` | `art/scripts/audit_report.py` | owner review |
| `specs/013-city-asset-kit/audit/renders/<theme>/<id>.png` | `audit_render.py` | `audit_report.py` (file exists) |

## `audit.json` shape

```json
{
  "version": 1,
  "blender": "5.2.3",
  "headroom": { "unculledCeiling": 550000, "culledCeiling": 290000, "unculled": 0, "culled": 0 },
  "meshes": [
    {
      "id": "dt_bench",
      "tier": 3,
      "size": 7,
      "triangles": 48,
      "tierBudget": 1500,
      "floorClass": "tier",
      "floor": 450,
      "fillRatio": 0.107,
      "seasonShare": { "city": 0.02, "winter": 0.09 },
      "verdict": "replace",
      "reason": "A sentence naming the style-bible rule that fails.",
      "renders": { "city": "renders/city/dt_bench.png", "winter": "renders/winter/dt_bench.png" }
    }
  ]
}
```

## Rules `audit_report.py` enforces (non-zero exit on any failure)

1. `meshes` holds exactly the 99 `dt_*` ids of `art/export/manifest.json`, each once.
2. `triangles`, `tier` and `size` equal the manifest and `budgets.json` values.
3. `tierBudget` equals `Config.Budgets.meshTriangles[tier]` (read from `art/scripts/budgets.json`).
4. `floorClass` is one of `pocket`, `flat`, `panel`, `tier`; `floor` is 40, 24, 150, or the tier floor (150, 210, 450,
   1050, 1500). `pocket` requires `size <= 0.8`.
5. `verdict` is `keep`, `upgrade` or `replace`; `keep` requires `fillRatio >= 1` and `seasonShare` under 0.15 in both themes;
   any other verdict requires a `reason` of at least 40 characters.
6. A verdict may differ from the triangle-only baseline in `data-model.md` §1.1 by one step, and then `reason` must say why.
7. `headroom.unculled` and `headroom.culled` are the winter-city sums that `Downtown.test` N10 computes, and are at or
   under the two ceilings.
8. Both render paths exist.

## Asset list contract (the finalised list)

`data-model.md` §2 is the list. `tests/unit/CityKit.test.luau` reads `src/shared/Content/CityKit.luau` and requires:

| Check | Expected |
| --- | --- |
| Object count | 84 |
| Per-group counts | building 25, street 11, park 16, suburbs 7, mainstreet 5, downtown 6, signage 7, meme 7 |
| Keys | `ck_` plus id, unique, none starts with `dt_` |
| Tier and size | size inside the tier band of `budgets.json`; `size <= Config.absorbRatio * TIER_CEILINGS[tier]` |
| Triangle target | at most `Config.Budgets.meshTriangles[tier]`; at least the class floor |
| Building variants | at least four per class (house, shop, midrise, tower) |
| Atlas | `atlas = "fronts"` on exactly the 17 shop, billboard and buffering-billboard objects |
| Names | `nameKey` present, `en` and `es` non-empty and different from the key |

## Verdict outcomes

| Verdict | What happens | Manifest and `Assets.luau` |
| --- | --- | --- |
| `keep` | nothing | no change |
| `upgrade` | the same silhouette is rebuilt to its floor-to-target band | same key, new hash in `manifest.json`, old uploaded id kept until re-upload |
| `replace` | rebuilt from a new recipe | same key and size, new hash, old id kept until re-upload |

An `upgrade` or `replace` never changes `id`, `tier` or `size`, so `Downtown.luau` and `budgets.json` do not change.

## Style conformance per mesh (FR-004), enforced by `export_all.py`

One material named `Palette`; UVs inside one atlas cell or strip; origin at the bottom centre; longest side within ±5 % of
the budget size; triangles inside the tier budget. Checked by the audit or the build, not by eye: no PBR, transparency or
per-prop light (no such data exists on a mesh); `w-season` share under 15 % (audit field `seasonShare`).
