# Contract: Config, Content, Strings and Assets (run loop)

Values and derivations: [data-model.md](../data-model.md) §1 to §3 and [research.md](../research.md) R1, R8, R9.

## Config keys

See the table in data-model.md §1. All live in `src/shared/Config.luau`; no script uses a bare number for
them. `Config.Flags.RunLoop = true`.

## `Worlds.luau` (`src/shared/Worlds.luau`, Roblox-side seam)

```lua
Worlds.active: Room                                   -- require(Content.GreyBoxRoom); the one line Feature 004 changes
Worlds.sizeTiers: { SizeTierDef }
Worlds.starThresholds: { number }                     -- world's own, else Config.starThresholds
Worlds.objectByTier: { [number]: ObjectDef }
Worlds.objectById: { [string]: ObjectDef }
Worlds.objectByBookId: { [string]: ObjectDef }
```

Built once at require time. No behaviour beyond table building.

## String keys (`Strings.luau`, English)

Placeholders use `{name}`. Every key has `en`; Spanish arrives in Feature 007.

| Key | English | Placeholders |
| --- | --- | --- |
| `ui.hud.time_label` | `Time` | |
| `ui.hud.target_label` | `Target` | |
| `ui.hud.star_target` | `{stars} star: {size}` | `stars`, `size` |
| `ui.hud.size_label` | `Size` | |
| `ui.hud.size_value` | `{size}` | `size` (one decimal) |
| `ui.hud.next_tier` | `Next: {icon} {headline}` | `icon`, `headline` |
| `ui.hud.max_tier` | `Biggest size reached` | |
| `ui.pickup.pop` | `+ {name}` | `name` |
| `ui.banner.tier_unlock` | `You can roll up: {headline}!` | `headline` |
| `ui.bump.label` | `Bump!` | |
| `ui.results.title` | `Time's up!` | |
| `ui.results.final_size` | `Final size: {size}` | `size` |
| `ui.results.stars` | `{stars} of 3 stars` | `stars` |
| `ui.results.coins` | `Coins: {coins}` | `coins` |
| `ui.results.new_entries` | `New in your book: {count}` | `count` |
| `ui.results.no_new_entries` | `No new book entries` | |
| `ui.results.friend_best` | `Best friend size: {size}` | `size` |
| `ui.results.self_best` | `Your best size: {size}` | `size` |
| `ui.results.roll_again` | `Roll again` | |
| `ui.results.back_to_hub` | `Back to hub` | |
| `ui.hub.title` | `Ready to roll?` | |
| `ui.hub.play` | `Play` | |
| `tier.greybox.{1..4}.name` | `Tiny`, `Small`, `Medium`, `Large` | |
| `tier.greybox.{1..4}.headline` | `TINY CUBES`, `SMALL CUBES`, `MEDIUM CUBES`, `LARGE CUBES` | |
| `object.greybox.cube_t{1..4}` | `Tiny cube`, `Small cube`, `Medium cube`, `Large cube` | |

The apostrophe in `Time's up!` is data, not code. Sizes are formatted by the caller with
`string.format("%.1f", d)` and passed as a string argument (digits are not a player-facing sentence).
`ui.hud.target_label` and `ui.hud.time_label` are the text twins of the clock and star icons (VI).

## Icons (`Content/Icons.luau`)

| Id | Glyph | Used for |
| --- | --- | --- |
| `star` | `★` | star targets, results stars |
| `star_empty` | `☆` | unearned star on results |
| `clock` | `⏱` | timer |
| `coin` | `●` | coins |
| `cube` | `■` | object icons, bump flash |
| `arrow` | `▲` | next-tier silhouette |
| `book` | `▤` | new book entries |
| `retry` | `🔁` | Roll again (`↻` has no glyph in either UI font, T038) |
| `home` | `⌂` | Back to hub |
| `play` | `▶` | Play |

Glyph rendering is confirmed in the viewport capture task (research R9); a missing glyph is swapped here only.

## Assets (`src/shared/Assets.luau`)

```lua
Assets.sounds = {
	pickup = "rbxasset://sounds/electronicpingshort.wav",
	tierUnlock = "rbxasset://sounds/button.wav",
	bump = "rbxasset://sounds/snap.mp3",
	bell = "rbxasset://sounds/bass.wav",
}
```

Engine-bundled placeholders; nothing uploaded. The first Studio task confirms each path plays and replaces
any that does not. This is the only file that holds a `SoundId`.
