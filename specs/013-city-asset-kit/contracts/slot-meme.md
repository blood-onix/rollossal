# Contract: `slot.meme`

Covers FR-009 and SC-004. The only runtime logic touched is a table in a pure Rules module.

## Slot ids

| Slot | Tier | Objects that may bind (default set) |
| --- | --- | --- |
| `slot.meme.t2` | 2 | `ck_meme_wet_floor_sign` |
| `slot.meme.t3` | 3 | `ck_meme_pond_cart` |
| `slot.meme.t4` | 4 | `ck_meme_cone_statue`, `ck_meme_phone_1pc`, `ck_meme_buffering_billboard` |
| `slot.meme.t5` | 5 | `ck_meme_banana_scale`, `ck_meme_vacant_lot` |

`ThemeResolve.SLOT_TIERS` gains these four keys. `ThemeResolve.isSlot` already matches the `slot.` prefix. `resolve` is
unchanged: it maps `binding.slots[slotId]` to an object and errors if the tier does not equal `SLOT_TIERS[slotId]`.

## Binding

A world names a slot id in a zone `mix` or a fixed placement (this feature does not add any). Each theme binding maps it:

```text
themeBindings.<theme>.slots["slot.meme.t4"] = "<object id>"
```

The mapped object must exist in the world's resolved lookup. To make `CityKit` objects bindable the lookup must contain them:
004i, 010 or 012 adds `CityKit.objects` to its world's object list when it places a slot. That is outside this feature; the
tests below use a toy world.

## Tests (`ThemeResolve.test.luau`)

1. `SLOT_TIERS["slot.meme.t2"]` to `["slot.meme.t5"]` equal 2 to 5.
2. **Data-only swap.** A toy world with one fixed placement of `slot.meme.t4` and two objects of tier 4. With binding A the
   resolved placement object is A; with binding B it is B. The world table is deep-equal in both runs. This is the FR-009 and
   SC-004 swap test.
3. A binding to a tier 3 object for `slot.meme.t4` errors with the existing message.
4. A world mixing `slot.meme.t4` with plain object ids in one zone is rejected as today (a zone is all slots or all objects).
5. `maxDressingSlotShare` still bounds meme slots in a toy world with 20 % slot placements.

## Localisation and content tests (`CityKit.test`, `Strings.test`)

- All seven meme objects exist, 5 to 8 of them, each with `en` and `es` names.
- Each meme object's tier equals the slot tier it is listed under above.
- Every meme object is inanimate: its `role` is not `animal`, `person` or `character` (a closed list in the test).
- No meme `en` or `es` name contains an entry from the keep-out list (loaded from `docs/design/shop-names.json` `bannedTerms`
  plus the meme keep-out terms in `contracts/shop-names-and-memes.md`).

## Out of scope

Placing meme slots in a map, a weekly rotation scheduler, and remote content updates.
