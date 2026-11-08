# Quickstart: Proving the City Asset Kit End to End

A validation guide. Each step says what to run and what you should see. Nothing here is implementation. Run steps in order;
steps marked **B** need the Blender claim in `tasks.md`, steps marked 🔒 need the Studio claim, and steps marked *after
amendment* wait for PR #10 (plan strand 0). Never start anything that focuses Studio or acts on the desktop (AGENTS.md).

## 0. Preconditions

1. `git branch --show-current` prints `013-city-asset-kit`.
2. `tasks.md` has one Blender claim line (who, since when) and no other agent holds it.
3. The state of PR #10 (the 4.1.0 / 4.0.0 amendment) is recorded at the top of `tasks.md`. If it is not merged, skip the
   *after amendment* steps and say so in the PR description.

## 1. The audit (US1, SC-001) **B**

| Run | Expect |
| --- | --- |
| `python3 art/scripts/audit_report.py --check specs/013-city-asset-kit/audit/audit.json` | exit 0; prints "99 meshes, K keep, U upgrade, R replace" with K + U + R = 99 |
| open `specs/013-city-asset-kit/audit/audit.md` | one row per `dt_*` id with triangles, tier budget, floor class, verdict, reason |
| count PNGs in `audit/renders/city` and `audit/renders/winter` | 99 each |
| read the headroom block in `audit.md` | winter-city triangles at or under 550,000 (unculled) and 290,000 (culled) |

Pass: every mesh has a verdict, every non-`keep` has a reason, and the verdicts differ from the baseline in
`data-model.md` §1.1 by at most one step each (with a reason).

## 2. The finalised list and the catalogue (US2, SC-002)

| Run | Expect |
| --- | --- |
| `lune run scripts/art-sync` | rewrites `art/scripts/budgets.json`; `git diff` shows only added `ck_*` keys (84 sizes, 84 tiers) |
| `lune run tests/unit/run` | all suites pass, including `CityKit` (84 objects, per-group counts, size bands, floors, atlas flags) and `ArtManifest` |
| `git diff --stat src/shared/Assets.luau art/export/manifest.json` | one contiguous block of added lines per batch; no `dt_*` line removed |

## 3. Exported meshes (SC-002) **B**

For each batch (building, street, park, suburbs, main street, downtown, meme, signage) after export:

| Check | Expect |
| --- | --- |
| `art/export/ck_<id>.fbx` exists for every id in the batch | yes |
| `manifest.json` row | `{id, tier, triangles, bytes, sha256}` with triangles at or under the tier budget |
| `lune run tests/unit/run` | `ArtManifest` hash and triangle checks pass for every row |
| one material named `Palette`, origin at the bottom centre, longest side within ±5 % | enforced by `export_all.py`; the run ends with no error list |
| upgraded `dt_*` rows | key, tier and size unchanged; `sha256` changed; `Assets.luau` id unchanged |

## 4. Building variants (US2 scenario 2)

Open `contact-sheets/city/building.png`. Expect: 25 new variants plus the six upgraded `dt_` buildings, each a single mesh
on the sheet; at least four distinct variants in each of house, shop, mid-rise and tower classes; no two adjacent tiles in a
row that are the same mesh.

## 5. Fronts atlas, names, billboards (US3, SC-003) *after amendment*

| Run | Expect |
| --- | --- |
| `python3 art/scripts/fronts_atlas.py` | writes `art/atlases/fronts/<theme>.png` for 6 themes and `fronts.json` |
| `python3 art/scripts/fronts_atlas.py --check` | exit 0, run again immediately with the same result (deterministic) |
| open `docs/design/shop-names.json` | at least 20 and at most 24 `clear` names, each with two or more searches and a date |
| `lune run tests/unit/run` | `CityKit` passes the banned-word, length, cell and billboard-cap checks; `Config` asserts `billboardTextures = 8` |
| open `contact-sheets/city/signage.png` and `…/winter/signage.png` | shop names readable, eight billboard designs, no real brand or logo |

## 6. Memes and `slot.meme` (US4, SC-004)

| Run | Expect |
| --- | --- |
| `lune run tests/unit/run` | `ThemeResolve` covers tiers 2 to 5 for `slot.meme.t*`, the data-only swap, and the wrong-tier error |
| inspect `CityKitStrings` keys for the seven `meme_*` objects | `en` and `es` present, plain descriptions, none on the keep-out list |
| open `contact-sheets/city/meme.png` and the winter one | seven objects, all inanimate |

## 7. Contact sheets (US2 scenario 3, SC-005) **B**

Expect 18 images: for each of `city` and `winter`, one per zone (`building`, `street`, `park`, `suburbs`, `mainstreet`,
`downtown`), plus `audit` (up to three pages), `signage` and `meme`. Each caption lists id and triangle count. `w-season`
looks like trim, not a blanket, on every winter sheet.

## 8. Hand-off and stand-ins (SC-005)

1. `docs/release-candidate.md` "Owner hand-offs" has one entry per export batch with the FBX list and the `Assets.luau` keys
   to fill, and one entry for the two fronts atlas PNGs.
2. Every new `ck_*` entry in `Assets.luau` is `""`.
3. 🔒 With Rojo synced (`scripts/studio-sync-probe.sh` through `execute_luau` returns `mismatches = {}`), the Gate 2 smoke test
   in `contracts/content-and-pipeline.md` builds one object of each kind with an empty id and `get_console_output` shows no
   error from game scripts (Studio's own `ContentId` lines are not game errors). Results go in `playtest.md`.

## 9. Gates

| Gate | Run | Expect |
| --- | --- | --- |
| 1 | `scripts/check.sh` | exit 0 (StyLua, Selene, strict luau-lsp, design tokens, `palette.py --check`, `fronts_atlas.py --check`, Lune suite, purity guard) |
| 2 | step 8.3 | no errors; recorded |
| 3 | steps 3 and 8 | every mesh in budget, key in `Assets.luau`, hand-off recorded |
| 4 | `Strings` test | kit and meme names present in both languages |
| 5 | `tasks.md` | all ticked, or moved to `docs/release-candidate.md` with a reason |
| 6 | PR description | the 18 images are attached or linked; the PR is opened and **not merged** until the owner approves them |

## 10. Rollback

All new work is additive: `git revert` of a batch commit removes its `ck_*` rows and FBX files; `dt_*` ids never change, so
no map or test depends on a revert order. If the headroom check in step 1 fails, stop upgrades and report; do not raise the
009 ceilings.
