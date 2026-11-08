# Contract: Shop Names, Billboards and Meme Originals

Covers FR-005 to FR-008, SC-003 and SC-004. Constitution IV governs. Shop names and signage are gated by the amendment
(plan strand 0); the meme rules apply now.

## Data file: `docs/design/shop-names.json`

Written by the vetting task, read by `fronts_atlas.py` and `CityKit.test`.

```json
{
  "version": 1,
  "bannedTerms": {
    "platform": ["roblox", "robux", "blox"],
    "alcohol": ["alcohol", "ale", "bar", "beer", "brewery", "cider", "cocktail", "gin", "lager", "liquor", "pub", "rum", "saloon", "spirits", "tavern", "vodka", "whiskey", "whisky", "wine"],
    "gambling": ["bet", "betting", "bingo", "casino", "gamble", "gambling", "jackpot", "lottery", "odds", "poker", "raffle", "roulette", "slots"]
  },
  "names": [
    {
      "name": "Crumb Corner",
      "trade": "bakery",
      "lines": ["Crumb", "Corner"],
      "searches": ["\"Crumb Corner\" bakery", "\"Crumb Corner\" trademark"],
      "date": "2026-11-07",
      "seen": ["one line per notable result, with the site name"],
      "verdict": "clear",
      "note": "",
      "cell": "sign_03"
    }
  ]
}
```

(The `names` entry above shows the shape; the real names come from the vetting task.)

## Matching rules (used by the test and by the task)

- `blox`, `roblox`, `robux`: matched as a substring, case-insensitive, with spaces and punctuation removed, so `Blocky`
  passes and `B-lox` is also checked. `Blocky Mart` contains `block`, not `blox`, and passes.
- Every other term: whole word, case-insensitive. `Barber` is not `bar`; `Toast Lab` is not `ale`.
- A name must not equal or contain a real brand or business name. The search record decides, not a list.
- Sign text is at most 2 lines, at most 13 characters each, upper and lower case letters, digits, `&` and `'` only.
- The platform logo, a lookalike of it, a real person's name, a flag, and a slogan are never allowed on any sign.

## Search record (per name)

At least two queries per name: the name in quotes with its trade, and the name with "trademark" or "brand". The record
keeps the date and the notable results. `verdict`:

| Verdict | Meaning | Action |
| --- | --- | --- |
| `clear` | no business or brand with the same or a near name in a similar trade | allowed, gets a sign cell |
| `close` | a real business or brand is the same or a near match | dropped, replaced by a new candidate |
| `banned` | contains a banned term | dropped |

At least 20 and at most 24 names end `clear` (the sign atlas holds 24). The record is evidence for the owner; it is not a
legal clearance and the document says so.

## `CityKit.test` checks

1. Every `names[].verdict == "clear"` entry has two or more `searches`, a `date`, and `lines` obeying the length rule.
2. No `name` or `lines` item contains a `bannedTerms` entry by the matching rules above.
3. `clear` count is 20 to 24; every `cell` is a distinct `sign_XX` in `fronts.json`.
4. Every `en` or `es` name in `CityKitStrings` for an object passes the banned-term check too.

## Billboard rules

- Eight designs at most (`Config.Budgets.billboardTextures`): `bb_404`, `bb_chart`, `bb_loading`, `bb_empty`, `bb_arrow`,
  `bb_testcard`, `bb_nested`, `bb_buffering`.
- A design is a pictogram, a number, or one short word. It does not imitate a real advertisement, brand, logo or slogan, and it
  does not sell anything. No paid placement exists.
- `bb_404`, `bb_chart` and `bb_loading` share their idea with the cosmetics `404`, `Number Go Up` and `Loading…` in
  `docs/design/04-player-cosmetics.md`. They are separate art; the owner may drop one billboard to avoid the overlap.

## Meme originals

Rule: **use the idea, never the image, the name or the music.**

### Keep-out (checked by the owner at Gate 6 and by the test on names)

Taken from `docs/design/04-player-cosmetics.md`: Nyan Cat, Doge (the Kabosu photo), Grumpy Cat, Trollface, Pepe, "This Is
Fine", Among Us crewmates, Skibidi Toilet, Rickroll, Crab Rave, Gigachad, Stonks' Meme Man, any real person's face, and anything
that mocks a group of people. Added by this feature: the named Italian-brainrot characters (Tralalero Tralala, Bombardiro
Crocodilo, Tung Tung Tung Sahur, Ballerina Cappuccina, Chimpanzini Bananini, Brr Brr Patapim, Lirili Larila) and any of their
sounds. `CityKit.test` rejects any meme name that contains one of these strings.

### The seven originals

| Object | The idea | Not used |
| --- | --- | --- |
| `meme_wet_floor_sign` | a caution sign standing in the middle of nowhere | a real caution-sign logo or brand |
| `meme_pond_cart` | a shopping cart left in a pond | a store logo on the cart |
| `meme_cone_statue` | a statue with a traffic cone on its head | a real statue or a named monument |
| `meme_phone_1pc` | a giant phone at 1 % battery (the number, a red icon) | any phone maker's shape or logo |
| `meme_buffering_billboard` | a billboard stuck on a loading ring | a video-site layout or logo |
| `meme_banana_scale` | a banana statue with a person-sized plinth for scale | the cosmetic topper's model; a new mesh |
| `meme_vacant_lot` | a bare grey stud-plate lot with a spawn pad | any logo, brand or player name |

The hybrid statues are held back (D10) and need their own invented names and a keep-out check before they are added.

### Always

- Inanimate: no person, face, animal or character. A statue is a plain form with no facial features.
- Names are plain descriptions in `en` and `es` (for example "Banana for Scale" and "Plátano a escala"), and they are the
  only text a player sees. Other text on a mesh is a pictogram or a number.
- Each meme passes `docs/design/05-roblox-limits.md` and the Minimal rating, and the owner can veto any of them at Gate 6.

## `CityKitStrings` coverage

The strings module has an entry for all 84 `nameKey`s. `Strings.test` requires both languages for each and rejects an `en`
value equal to its `es` value unless the word is the same in both (a short allow-list in the test).
