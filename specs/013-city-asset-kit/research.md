# Research: Dedicated City Asset Kit, Style Audit, Shop Signage & Meme Originals

Decisions for `plan.md`. Each has Decision, Rationale, Alternatives. No NEEDS CLARIFICATION remains; the open points are
the defaults D1 to D12 in `plan.md`, which the owner can overrule without changing the structure.

## R-01: What the constitution amendment gates

**Decision**: Constitution v4.1.0 (IV: invented shop names; XI: shared fronts and signs atlas, capped billboard set) is
on PR #10 and its merge state was not confirmed when this plan was written (the `gh` call was not available). The plan
gates only strand 5: no shop name is put on a texture, no fronts atlas is generated or uploaded, and no billboard art is
authored until the amendment is merged. The first task in `tasks.md` re-checks the PR and records the result.

Not gated: the audit, the building, street, park, suburb, main street and downtown meshes on the theme atlas, the memes
on the theme atlas, `slot.meme.t*`, and the billboard cap in `Config` (all allowed by Principles IV and XI as they stood
before the amendment). `docs/release-candidate.md` states that no signage is authored and no CC0 mesh is imported until
the amendment is approved; this plan keeps to that.

**Rationale**: the amendment is the owner's, it is cheap to wait for, and five of the seven strands do not need it.

**Alternatives**: wait for the amendment before anything (idle Blender time for no reason); build signage first and hope
(contradicts the release-candidate note).

## R-02: Audit method

**Decision**: `art/scripts/audit_render.py` opens each `art/export/dt_*.fbx` through the Blender MCP, applies the theme
atlas for `city` and `winter`, renders it at two framings (the game-camera framing from `specs/009-style-bible-bakeoff`
`cameras.json`, and a close three-quarter view), and writes one record per mesh into
`specs/013-city-asset-kit/audit/audit.json`. Fields: `id`, `tier`, `size`, `triangles`, `tierBudget`, `floor`,
`floorClass`, `fillRatio` (triangles over floor), `seasonShare` (share of faces whose UVs fall in a `w-season` cell, by
area), `verdict`, `reason`. `audit_report.py` (stdlib) turns the JSON into `audit.md` and checks that all 99 ids are
present, each verdict is one of the three words, and each non-`keep` verdict has a reason of at least a sentence.

Verdict rule, in this order: `replace` if fill ratio is under 0.35 or the silhouette fails the bible (no bevel on a
main edge, boxy where the bible asks for round); `upgrade` if fill ratio is 0.35 to under 1.0 and the silhouette is
sound; `keep` if fill ratio is 1.0 or more and `seasonShare` is under 15 %. A visual pass may move a verdict one step
either way with a written reason. The triangle-only baseline, computed from the manifest and the class floors of R-03, is
12 keep, 36 upgrade and 51 replace.

**Rationale**: FR-001 asks for a recorded count, tier budget, assessment and disposition; a script makes it repeatable
and keeps the numbers out of opinion.

**Alternatives**: a hand-written table (cannot be re-run after an upgrade); a Studio-side audit (needs the Studio claim
that 004i holds, and Rojo sync).

## R-03: Class floors and scene headroom

**Decision**: the style bible's tier floors (150 / 210 / 450 / 1,050 / 1,500) are written for new assets. Four class
overrides are added to the bible's section 11, which already says overrides are recorded there:

| Class | Rule | Floor |
| --- | --- | --- |
| pocket | size 0.8 studs or less | 40 |
| flat | ground pieces: road marking, path, kerb, crossing, blanket, vacant lot, snow pile, rink | 24 |
| panel | billboards and sign boards | 150 |
| tier | everything else | the tier floor |

Targets stay at the bible's tier target, capped at 60 % of the budget. Before any upgrade is built, task 1 measures the
winter city's current triangle total against the 009 ceilings (550,000 unculled, 290,000 culled) by the same sum
`Downtown.test` N10 uses, and writes the headroom into `audit/audit.md`. Upgrades are built highest-visibility first
(vehicles, street furniture, building fronts) and N10 is run after every batch. If the headroom runs out, the order stops
and the plan reports it; the ceilings are not raised in this feature.

**Rationale**: 97 of the 99 meshes are under their tier floor, so a straight application would mark almost everything
for rebuild; the bible says to keep litter cheap and spend on what is seen. N10 reads the manifest, so upgrades change
it directly.

**Alternatives**: raise nothing and mark all 97 (no concentration of effort); relax the floors globally (loses the bar the
009 bake-off set).

## R-04: How the asset list is finalised

**Decision**: `data-model.md` holds the list: for each of the six groups, the retained or upgraded `dt_*` ids with their
audit baseline, and the new `ck_*` pieces with tier, stud size and triangle target. Rules: every size is inside the tier's
band in `art/scripts/budgets.json` (T1 0.3 to 1.5, T2 1.6 to 3.9, T3 4.2 to 9.8, T4 10 to 25, T5 26 to 60); every piece
is one mesh; names follow the spec's six groups. The spec's items that already exist as `dt_*` (street lamp, traffic
light, bus shelter, picnic table, mailbox, wheelie bin, bicycle, hatchback, newspaper box, hydrant, bench, scooter,
delivery van, taxi, bus, kiosk, cinema) are covered by their audit verdict, not duplicated. The list is a contract:
`CityKit.test` reads the Lune catalogue and checks it against the sizes and counts in `contracts/audit-and-asset-list.md`.

**Rationale**: FR-003 needs the list finalised in the plan; reusing existing items avoids two meshes for one idea.

**Alternatives**: a full replacement list under new keys (throws away 12 keeps and 36 cheap upgrades, and moves the 99
out of Downtown).

## R-05: Building modules and joining

**Decision**: modules (wall, window bay at 6 studs, door, shop front, awning, cornice, roof) live as Blender collections
in `art/source/ck_buildings.blend`, each at three widths (1, 2 and 3 bays, 6 / 12 / 18 studs). A variant is a recipe in
`kit_recipes.py`: a list of module placements. The recipe joins the modules into one object, merges coincident vertices,
removes interior faces, bevels main silhouette edges by one segment, and sets one material. `export_all.py` already
rejects a second material, an off-atlas UV and a wrong origin. Variants differ in bay count, storey count, roof shape,
colour roles (2 to 4 per building, one accent) and trim, so two neighbours always differ in at least two of those.

**Rationale**: spec edge case "Single-Part Absorbable Building Rule" and bible section 5 (one repeating bay).

**Alternatives**: one-off hand modelling per building (slow, no repeat guarantee); multi-part buildings (breaks the
single-mesh rule).

## R-06: How many building variants

**Decision**: 25. Six suburban houses (T4), nine shop buildings (six T4, three T5 rows), six mid-rise blocks (T5), four
towers (T5). With the six upgraded `dt_` buildings that gives 31 distinct buildings. The no-adjacent-repeat condition is
met when each class has at least four variants, so any street can alternate: houses 6, shops 9, mid-rise 6, towers 4.

**Rationale**: a placement system that avoids repeating the previous neighbour needs at least two choices; four per class
gives room for a three-in-a-row look without a repeat in a window of three. The placement code is 004i / 010 / 012.

**Alternatives**: fewer variants with random yaw (the bible and 009 leave yaw to 004i / 004j); more variants (triangle and
upload cost with no player-visible gain at this scale).

## R-07: Props to tier

**Decision**: each new prop is built to its class floor and tier target by the bake-off method from 009: silhouette first
(bevels, wheel arches, canopy lobes, window reveals), no hidden faces. Defaults for targets: T1 200, T2 300, T3 600,
T4 1,400, T5 2,200, flats 24 to 80, shop buildings 2,000, vehicles 1,400 to 1,600. Each source collection notes any prop
that ends below its floor with a reason, as the bible requires. Recipes use the DSL in `build_objects.py` where it
suffices and the bmesh bevel builder from `bakeoff_props.py` where it does not.

**Rationale**: 009 measured these bands on five props (hatchback 1,420, shop front 2,032, bench 564, tree 456, hydrant 364).

## R-08: Key prefix and the test impact

**Decision**: new meshes are keyed `ck_<id>`, with `assetKey = "ck_" .. id`. `ArtBudgets.meshes()` gains a third source,
`CityKit.objects`, with `world = "city_kit"`. `ArtManifest.test` gets a third key set; its Downtown assertions
(`== 99`, `dt_` prefix, `#SnowVillage.objects + 99`) stay as they are, and new assertions state the kit count (84) and the
`ck_` prefix. The manifest-count assertion becomes `#SnowVillage.objects + 1 + downtownBuilt + kitBuilt`. `Assets.meshes`
may hold a `ck_` key only if `CityKit` names it. `export_all.py` needs no change for the prefix, because the budgets file
lists the ids.

**Rationale**: `dt_` would change the 99; the test and `ArtBudgets` are the real couplings. A separate module also keeps
004i, 010 and 012 from editing the file this feature edits.

**Alternatives**: put the kit in `Downtown.luau` (collides with 010 and 012 and breaks the 99); a different suffix scheme
(no gain).

## R-09: Keeping shared-file diffs small

**Decision**: `Assets.luau` gets one block of 84 sorted `ck_*` lines, appended after the last existing mesh line, plus a
small `frontsAtlases` table; no existing line moves. `manifest.json` rows are written by `export_all.py` in id order and
the export runs once per batch, so a batch is one contiguous diff; upgrades rewrite their own row only. `budgets.json` is
regenerated by `lune run scripts/art-sync` in the same commit as the Luau data. Each batch is its own commit.

**Rationale**: spec edge case on parallel contention (FR-012); 004i touches the same two files.

## R-10: Which meshes use the fronts atlas

**Decision**: only the nine shop buildings, the seven `ck_billboard_*` meshes and the buffering meme billboard. They need
sign text and facade tiles that the 64 gradient cells and eight strips of the theme atlas cannot hold. Houses, mid-rises,
towers, vehicles and props stay on the theme atlas, so the amendment gate does not hold them (D6). Every face of a fronts
mesh uses the fronts atlas only; such a mesh has one material and does not use the theme atlas.

**Layout** (1,024 px, same on every theme): sign cells 256 x 64, four across, six rows (24 cells, y 0 to 383); billboard
cells 256 x 128, four across, two rows (8 cells, y 384 to 639); six facade strips 1,024 x 64 (y 640 to 1,023): brick,
render, curtain glass, shutters, shop glazing, cornice trim. `fronts_atlas.py` draws them from `tokens.json` with a
built-in 5 x 7 bitmap font, writes `art/atlases/fronts/<theme>.png` and `fronts.json` (UV inner rects), and has a
`--check` mode that regenerates in memory and compares hashes, as `palette.py --check` does.

**Rationale**: Constitution XI: "generated by script where practical, and per theme where its colours depend on the
theme". One layout across themes means a theme swaps the atlas and never the mesh.

**Alternatives**: a 2,048 px atlas (breaks the 1,024 px rule); sign text as separate decals (more materials); pre-drawn
images (not reproducible, not `--check`-able).

## R-11: Choosing the atlas at runtime

**Decision**: `ObjectDef` gains an optional `atlas: "fronts"?`. `ObjectVisual.textureId` takes the def: if `def.atlas == "fronts"`
it returns `Assets.frontsAtlases[theme.paletteAssetKey]` (when not `""`), otherwise the current theme-atlas branch. Nothing
else changes. When the fronts id is `""`, the object takes the same path as an unset texture today: stand-in colour.

**Rationale**: smallest change that satisfies "a theme swaps its atlases and never the meshes". It needs Gate 2 (a Studio
smoke test) because it touches client rendering.

**Alternatives**: a second material per mesh (forbidden); baking fronts into the theme atlas (does not fit).

## R-12: Shop-name vetting

**Decision**: 26 candidates are listed in `data-model.md` §5. Each gets a record in `contracts/shop-names-and-memes.md`
format: the name, the trade, the search queries run, the date, the top results seen, the verdict `clear`, `close` or
`banned`, and a note. Rules: no word from Roblox, Robux, Blox (case-insensitive, also as part of a word), no alcohol or
gambling term (list in the contract), no real brand, no near-match of a brand in the same trade, no real person, at most 13
characters per line and two lines. A name with a `close` result is dropped, not argued. At least 20 must end `clear`; the
sign atlas holds 24. `CityKit.test` checks every shown name against the banned-word list and the length rule, and that
the number of `clear` names is at least 20 and at most 24.

**Rationale**: FR-006 and SC-003. A web search is evidence the agent can do; it is not a legal clearance, so the record is
kept for the owner.

**Alternatives**: purely generated names with no search (fails FR-006); a trademark database (a new external service,
Human Approval).

## R-13: Billboards and the cap

**Decision**: `Config.Budgets.billboardTextures = 8`. The eight designs are cells in the fronts atlas: seven on the
`ck_billboard_*` meshes (404, upward chart, loading ring, empty frame, arrow to nothing, test pattern, billboard of a
billboard) and one on the buffering meme billboard. A design is a pictogram, a number or a short word; none imitates a
real advertisement. `Config.test` asserts the value; `CityKit.test` asserts the billboard-cell count in `fronts.json` is at
most the cap and that each billboard def names one of them. The cap is measured by the atlas file size and by the
scene-triangle check, because billboards share one material.

**Rationale**: spec assumption (default 8); Constitution XI wants the cap in Config and stated here.

## R-14: `slot.meme`

**Decision**: add `slot.meme.t2`, `slot.meme.t3`, `slot.meme.t4`, `slot.meme.t5` to `ThemeResolve.SLOT_TIERS` with tiers 2 to
5. The Rules function `resolve` is unchanged. A world that uses a meme names one of the four slots in a zone mix or a fixed
placement; each theme's `slots` table maps the slot id to a `ck_meme_*` object id of that tier. Swapping a meme is an edit
to that table. Tests: (1) each slot id has the expected tier; (2) a toy world with one `slot.meme.t4` placement resolves to
object A under binding A and to object B under binding B with the world data identical; (3) a binding to an object of the
wrong tier is rejected by the existing error. `maxDressingSlotShare` (0.15) already applies to dressing slots.

**Rationale**: memes are 3 to 28 studs, four tiers; the Rules module maps one tier per slot. Four table entries satisfy
"a `slot.meme` dressing slot" for the content author without new logic.

**Alternatives**: one `slot.meme` of one tier (all memes the same size, so the banana statue and the wet-floor sign
cannot share it); a code change so a slot accepts a tier range (new Rules logic and more tests for the same effect).

## R-15: Meme concepts and rules

**Decision**: seven originals, all inanimate, all on the theme atlas except the billboard: banana statue (T5, 28),
shopping cart in the pond edge (T3, 5), statue with a cone on its head (T4, 12), wet floor sign (T2, 3), phone statue at
1 % (T4, 14), bare grey stud-plate vacant lot with a spawn pad (T5, 30, flat), buffering billboard (T4, 18, fronts atlas).
The hybrid statues are held out (D10). Each meme has a one-line "idea, not image" note in the contract, checked against
the keep-out list in `docs/design/04-player-cosmetics.md` and the named Italian-brainrot characters; names are plain
descriptions ("Banana for Scale") and are the only player-facing text, in `en` and `es`.

**Rationale**: FR-007 and FR-008. Seven sits inside 5 to 8 and leaves room for one more.

## R-16: Contact sheets

**Decision**: `art/scripts/contact_sheet.py` (Blender) loads the manifest rows of one zone, places the meshes on a
neutral stage in a grid, keeps one scale label per row, renders under the 009 lighting in `city` and `winter`, and saves
`contact-sheets/<theme>/<zone>.png`. Nine sheets per theme: six zones, the audit sheet (all 99, three pages if needed),
the signage sheet and the meme sheet. A sheet lists each asset's id and triangle count in a caption strip.

**Rationale**: FR-013 and Gate 6. A single tool keeps every sheet the same, so the owner compares like with like.

## R-17: Blender claim and the upload hand-off

**Decision**: every Blender task is marked **B** in `tasks.md`, with one claim line at the top of the feature
(who, since when). Studio is used for one Gate 2 smoke test only and is claimed then. New meshes are exported in batches by
zone; each batch is one hand-off row on `docs/release-candidate.md` under "Owner hand-offs": the FBX file names, the
count, the manifest commit, the `Assets.luau` keys to fill. Until the ids arrive the entries stay `""` and
`ObjectVisual` draws the stand-in (it warns once, which is the existing behaviour and is not changed).

**Rationale**: Constitution X and spec FR-011, FR-012.
