# Contract: Fronts Atlas and Billboards

Covers FR-004, FR-005 and Constitution XI. This contract is gated by the amendment (plan strand 0).

## Config

`src/shared/Config.luau`, `Budgets`: add `billboardTextures = 8`. `Config.test` asserts the value and that it is a positive
integer. This is the cap the feature states.

## Generator: `art/scripts/fronts_atlas.py`

Python 3 standard library only (Constitution XII). Same style as `art/scripts/palette.py`.

| Option | Behaviour |
| --- | --- |
| (none) | writes `art/atlases/fronts/<themeId>.png` for all six themes and `art/atlases/fronts/fronts.json` |
| `--check` | regenerates in memory, compares the pixel SHA-256 of each theme with `fronts.json` and the layout with the committed JSON, exits 1 on any difference or a missing file |

`scripts/check.sh` runs `python3 art/scripts/fronts_atlas.py --check` right after `palette.py --check`.

Inputs: `docs/design/tokens.json` (the theme colours) and `docs/design/shop-names.json` (the vetted names; written by the
vetting task, see `shop-names-and-memes.md`). Text uses a built-in 5 x 7 bitmap font scaled 4x; no font file, no network.

## Layout (1,024 x 1,024, identical on every theme)

| Region | Cells | Cell size | Y range |
| --- | --- | --- | --- |
| Sign cells `sign_00` to `sign_23` | 4 across, 6 down | 256 x 64 | 0 to 383 |
| Billboard cells `bb_*` | 4 across, 2 down | 256 x 128 | 384 to 639 |
| Facade strips `fx_brick`, `fx_render`, `fx_glass`, `fx_shutter`, `fx_shopglaze`, `fx_cornice` | 6 stacked | 1,024 x 64 | 640 to 1,023 |

An inset of 2 px on every side (as the theme atlas) keeps bilinear filtering off the neighbour.

## `fronts.json`

```json
{
  "version": 1,
  "size": 1024,
  "themes": { "city": { "pixelSha256": "…" }, "winter": { "pixelSha256": "…" } },
  "signs": { "sign_00": { "u0": 0, "v0": 0, "u1": 0, "v1": 0, "name": "Blocky Mart" } },
  "billboards": { "bb_404": { "u0": 0, "v0": 0, "u1": 0, "v1": 0 } },
  "strips": { "fx_brick": { "u0": 0, "v0": 0, "u1": 0, "v1": 0 } }
}
```

Rules checked by `CityKit.test` (reads the JSON with Lune):

1. At most 24 `signs` and at most `Config.Budgets.billboardTextures` `billboards` keys.
2. Every `name` in `signs` is a `clear` entry in `shop-names.json`; no name outside it.
3. Every fronts object in `CityKit` has all faces' target cells named in its data (`signCell` or `billboardCell`) and those
   cells exist.
4. `winter` and `city` have equal layouts and different pixels.

## Appearance rules

- Sign cells: shop name on two lines at most, 13 characters per line, one `w-accent-*` background role, one text role.
- Billboard cells: pictogram, number or one short word. No real ad, brand, logo, face, flag or QR-like pattern.
- `w-season` appears only as a thin trim on the winter facade strips and sign borders (under 15 % of each cell).
- No transparency: every pixel is opaque. No PBR maps.

## Per-mesh rule

A fronts mesh has one material and every face's UV lies inside one sign cell, billboard cell or facade strip. It does not use
the theme atlas. `export_all.py` checks this against `fronts.json`.

## Runtime

`ObjectDef.atlas = "fronts"` plus `Assets.frontsAtlases` (see `content-and-pipeline.md`). Uploading the two PNGs is on the
owner hand-off.

## Measurement of the cap

Stated cap 8. Measured by (1) the data test above; (2) the PNG size of each atlas (checked in the contact-sheet task and
written to `audit/audit.md`); (3) `Downtown.test` N10, which the signage meshes do not change because they are not placed
by this feature.
