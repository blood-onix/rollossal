# Style bible

The authoritative visual bar for Rollossal's world art. Written for feature 009
(`specs/009-style-bible-bakeoff/`); it is a proposal until the owner approves it, and the owner's concept reference
(section 12) outranks any line here.

Use it two ways: as the checklist when you author a prop, a facade or a map change, and as the reference the owner and
agents judge the five fixed capture shots against (`art/capture/cameras.json`, set committed under
`specs/009-style-bible-bakeoff/captures/before/`).

## 1. Authority

This document overrides [06-art-style.md](06-art-style.md) where they disagree. `06` stays the record of why
"stylised real" was chosen and of the pipeline limits; this file is the look itself. What it replaces:

| Was | Now |
| --- | --- |
| `w-season` "on every roof, hedge top, car roof and lamp head" (README, 06, 07, tokens) | `w-season` is an accent trim, never a blanket (section 9) |
| "Never put words on textures", "signs are pictograms, never words" (README, 05) | Invented proper-noun shop names and short signage are allowed (section 5). Real brands, logos, flags, memes and faces stay banned. Allowed by constitution v4.0.0 (Principle IV), once its pull request is approved |
| Tier budgets "proposed" as ceilings only | Budgets are ceilings; floors and targets are in section 4 |
| Prop yaw left to chance | Props face a reason (section 7) |

## 2. Colour hierarchy

Quietest to loudest, in the order the eye should read a street:

1. **Ground**: `w-asphalt` (road), `w-sidewalk`, `w-kerb`. Large, low contrast, never the accent.
2. **Buildings**: `w-wall-a/b/c`, `w-roof-a`, `w-glass`. Mid contrast; one wall colour per building.
3. **Accents**: `w-accent-*`, `w-trim`, `w-door`, awnings. Small areas, at most one accent per prop, at most two per
   facade. This is where the eye goes.
4. **Props**: absorbable objects are the highest-contrast things on the street. They sit on the quiet ground so the
   player can read what is edible.

Rules: use token names only, never raw colours; a road is never lighter than its sidewalk; the largest area of any
frame is ground or wall, not accent; `w-glow` is Neon on tier 4 to 5 hero props only.

## 3. Proportions and edge treatment

- Real-world proportions. Only the one hero feature of a prop may be exaggerated, by at most 10 %.
- Chunky, readable silhouettes at phone size: a feature smaller than 3 % of the object's longest side is dropped or
  merged. At D5 on a phone a hydrant must read as a hydrant from its outline alone.
- One bevel segment on silhouette edges (Constitution XI), width about 1.5 % of the longest side (a 14-stud car: 0.2
  stud; a 2.4-stud hydrant: 0.04 stud). Round parts smooth-shaded, hard edges sharp.
- No floating or interpenetrating parts that show at game-camera distance.

## 4. Triangle utilisation

The budget is a ceiling, not a target. Today's `dt_*` meshes use 14 / 15 / 9 / 6 / 5 % of their tier budget (medians
72 / 108 / 136 / 216 / 272 triangles) and read as thin at close range. The bar for **new** assets (the 164 existing
meshes are not retro-fixed by this document):

| Tier | Budget (`Config.Budgets`) | Floor (about 30 %) | Target (about 55 %) | Today's `dt_*` median |
| --- | --- | --- | --- | --- |
| 1 | 500 | 150 | 275 | 72 |
| 2 | 700 | 210 | 385 | 108 |
| 3 | 1,500 | 450 | 825 | 136 |
| 4 | 3,500 | 1,050 | 1,925 | 216 |
| 5 | 5,000 | 1,500 | 2,750 | 272 |

A prop below its floor needs a reason written in its Blender collection notes. Per-class overrides, because a small
prop cannot spend a big tier budget (a 2.4-stud hydrant is tier 2, and 385 triangles is already generous): the
bake-off in `specs/009-style-bible-bakeoff/bakeoff/README.md` sets them, and they are recorded in the table in
section 11 once measured. Spend triangles on silhouette first (bevels, wheel arches, window reveals, tree canopy
lobes), never on hidden faces.

Scene totals are a separate limit, measured by the heavy-scene benchmark (`docs/design/03-city-level.md` and
`specs/009-style-bible-bakeoff/playtest.md`).

## 5. Facades, awnings and signs

- **Continuous facades.** A street frontage reads as a row: shared building line, matching floor heights and cornice
  lines, one repeating module (bay about 6 studs wide: window, window, door), not isolated boxes with gaps.
- **Shop fronts** have a ground-floor glazing band `w-glass`, a door `w-door`, an awning in a `w-accent-*` role
  (depth about 2 studs, 0.4 stud tilt down) and a fascia board for the sign.
- **Signage** is invented proper-noun shop names and short words ("Mabel's Bakery", "Corner Cycles", "Tin Can Diner"),
  set on the fascia or a billboard texture. Pictograms remain valid and are preferred for the absorbable props.
  Banned: real brands and logos, flags, meme images, real faces, alcohol or gambling names, and the words "Roblox",
  "Robux" and "Blox". A name is art direction, not a localisation key, until a build feature adds the texture.
- Signage may be authored once constitution v4.0.0 (Principle IV) is approved on its pull request.
- Facade windows are `w-glass` with a frame trim strip; no window is a flat painted square on a plain wall at D5
  distance.

## 6. Roads and pavement

- **Road**: dark `w-asphalt`, clearly darker than the sidewalk (target: the sidewalk at least 2.5 times as light as the
  road in the capture).
- **Markings**: dashed centre line and edge lines in `w-accent-yellow` / white, 0.3 stud wide, flush with the road; a
  zebra crossing at each main-street junction, stripe 1 stud wide, 1 stud gap.
- **Sidewalk**: pale `w-sidewalk`, raised 0.4 stud on a `w-kerb` edge band, at least 6 studs wide on main streets.
- **Kerb**: lighter than the road, darker than the sidewalk, always present where road meets pavement.

## 7. Trees, lamps and props

- Street trees and lamps at even spacing along the kerb: trees every 18 studs, lamps every 24, offset so a lamp never
  stands within 4 studs of a trunk.
- **Orientation is deliberate**: cars face along their lane (never across a road), benches face the street or a park
  path, bins and hydrants face the road, shop fronts face the street. Random yaw is only for clutter that has no front
  (scattered pickups, debris). Placement yaw as data is tracked by features 004i/004j, not 009.
- Props sit on the ground plane with their base flush; nothing floats or sinks.

## 8. Lighting

Warm sun from `Themes.city`: `brightness 3`, `clockTime 13`, `fogStart 200`, `fogEnd 1000`, `atmosphere 0.25`,
`light-sky` (143, 208, 255), `light-ambient` (154, 166, 184). Shadows read as soft blue-grey, not black. Fog only
softens the far skyline; it never hides the street. Every capture is judged in this lighting.

## 9. Themes

- **`city` first.** The look is established in the `city` theme and the five shots are taken in it. A theme swaps the
  atlas and never the meshes, so a prop that reads in `city` reads in every season.
- **`winter` is dressing.** `w-season` is an accent trim: snow on the roof ridge and the top of the awning, a cap on
  the hedge, a line on the car roof. Never a blanket over every top face; the wall, road and sidewalk colours must
  still show. In the capture the seasonal colour is under 15 % of the visible area.

## 10. The ball

The ball is a heap of what it ate. As it grows it shows its recent absorbs stuck to the surface: small objects as
nubs and plates, mid objects as chunks, big ones as slabs, in the colours of the objects (section 2, accents win).
Target: at D12 and above, at least six distinct recognisable absorbed props visible on the ball at once, and the
ball's own base colour no more than 40 % of its visible surface. (Ball cosmetics are in
[04-player-cosmetics.md](04-player-cosmetics.md); this is the in-run look.)

## 11. Sourcing rule

Result of the 009 bake-off (`specs/009-style-bible-bakeoff/bakeoff/README.md`): Source 1 (in-house Blender) rebuilt the
five props inside their floor-to-target bands (hatchback 1,420, shop front 2,032, bench 564, tree 456, hydrant 364
triangles). CC0 and Creator Store inspection were declined by the owner, and `generate_3d` did not run (generators off),
so there is no side-by-side comparison. **Owner decision, 2026-11-02:**

- New world props are made in Blender with the in-house pipeline to the section 4 floors and targets.
- The owner can reopen the CC0 test after looking at the renders. A CC0 mesh would still need the download and the
  constitution amendment approved; it counts as edited in Blender when re-UV'd onto the atlas, with its licence recorded.
- `generate_3d` output and Creator Store models are not used unless they pass the same five-prop comparison.
- Bevel only the main silhouettes; small details stay flat. Per-class overrides measured so far: hydrant 210 to 385
  (the tier 2 floor and target already suit it).
- **Class floors (013 audit, plan D3).** A class floor replaces the tier floor where a mesh cannot spend it: pocket
  floor 40 (size <= 0.8 studs), flat floor 24 (road marking, path, kerb, crossing, blanket, snow pile, ice rink),
  panel floor 150 (billboard and sign panels). Tier floors stay 150, 210, 450, 1050, 1500 for tiers 1 to 5. Targets
  stay at the tier target or 60 % of the budget, whichever is lower. The audit's `fillRatio` is triangles / floor.

## 12. Concept reference

Path: `specs/009-style-bible-bakeoff/concept-reference.png`. Status: **absent**. The owner is asked once (tracked on
`docs/release-candidate.md`); when it arrives this document gets a "checked against the concept" pass and the
concept wins any disagreement. Its absence does not block any work.
