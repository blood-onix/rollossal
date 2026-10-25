# Contract: Config, Content, Strings, Localizer and Icons (saving and economy)

Values and meaning of the Config keys: [data-model.md](../data-model.md) §1. All live in
`src/shared/Config.luau`; no script uses a bare number for them.

## Config shape

```lua
dataStoreName = "PlayerProfiles_v1",
playerKeyPrefix = "Player_",
useMockDataStoreInStudio = true,
runStartUiLockSeconds = 5,
settingsRateLimit = 20,
settingsSendDelay = 0.3,
minUtilityTouchTarget = 64,
noticeSeconds = 2,
Settings = {
	musicVolume = { default = 0.8, min = 0, max = 1 },
	effectsVolume = { default = 0.8, min = 0, max = 1 },
	cameraSensitivity = { default = 1.0, min = 0.5, max = 2.0 },
	reduceMotionDefault = false,
	languageDefault = "auto",
	languages = { "auto", "en-us", "es-es" },
},
DefaultWorldsUnlocked = { greybox = true, snow_village = true },
Flags = { ..., Saving = true, Shop = false },
```

`Config.test.luau` additions (hand-written expectations): the three values above for the data store
name/prefix/lock seconds; each `default` inside its `[min, max]`; `min < max`; `languages` equals
`{ "auto", "en-us", "es-es" }`; `languageDefault` is in `languages`; `minUtilityTouchTarget <
minTouchTarget` and `>= minTextSize`; `Flags.Saving == true`, `Flags.Shop == false`.

## `Content/GreyBoxRoom.luau`

`SizeTierDef.reward: RewardDef?` ([data-model.md](../data-model.md) §9). Grey-box rewards:

| tier | `rewardId` | `rewardType` | `nameKey` |
| --- | --- | --- | --- |
| 1 | `greybox.reward.tier1` | `trail` | `reward.greybox.tier1.name` |
| 2 | `greybox.reward.tier2` | `trail` | `reward.greybox.tier2.name` |
| 3 | `greybox.reward.tier3` | `skin` | `reward.greybox.tier3.name` |
| 4 | `greybox.reward.tier4` | `skin` | `reward.greybox.tier4.name` |

`GreyBoxRoom.test.luau` additions: reward ids non-empty and unique across tiers, `rewardType` is `skin` or
`trail`, every `nameKey` exists in `Strings`, every object's `bookId` is unique (already tested in 002),
and every object's `tier` has a `sizeTiers` entry (so no page is orphaned).

## `Content/Icons.luau` additions (glyphs; placeholders until real icons exist)

| id | glyph | used by |
| --- | --- | --- |
| `gear` | `⚙` | Settings button |
| `shop` | `🛒` | Shop button |
| `lock` | `🔒` | Book button during the lock, locked reward |
| `unknown` | `❓` | silhouette card |
| `prev` | `◀` | Book previous page |
| `next` | `▶` | Book next page |
| `close` | `✕` | panel close |
| `check` | `✔` | reward earned, toggle on |

Every glyph is checked in `FredokaOne` and `GothamMedium` in the capture task (002 found `↻` missing and
used an emoji). A glyph that does not render is replaced by an emoji in this file only.

## `Localizer` changes

```lua
Localizer.t(key: string, args: { [string]: any }?, localeId: string?): string
Localizer.setLanguage(code: string): ()      -- "auto" | "en-us" | "es-es"; anything else ignored
Localizer.getLanguage(): string
Localizer.changed: { Connect: (self, fn: () -> ()) -> () }     -- fired after a real change
```

Locale order: `localeId` argument, then the override (when not `"auto"`), then
`LocalizationService.RobloxLocaleId`, then `en-us`. A key with no text for the chosen locale falls back to
`en-us`; an unknown key returns the key (002 behaviour, unchanged).

## `Strings.luau` shape and new keys

Entry type becomes `{ en: string, es: string? }`. Placeholder names must match between `en` and `es`
(Lune test). All keys below ship with both. Spanish is a draft for owner review in Feature 007.

| Key | English | Spanish | Placeholders |
| --- | --- | --- | --- |
| `ui.topbar.book` | `Book` | `Libro` | |
| `ui.topbar.shop` | `Shop` | `Tienda` | |
| `ui.topbar.settings` | `Settings` | `Ajustes` | |
| `ui.hud.shop_after_run` | `After this run` | `Después de esta partida` | |
| `ui.hud.shop_soon` | `Shop opens soon` | `La tienda abre pronto` | |
| `ui.common.close` | `Close` | `Cerrar` | |
| `ui.book.title` | `Collection book` | `Libro de colección` | |
| `ui.book.page_progress` | `{collected} / {total}` | `{collected} / {total}` | `collected`, `total` |
| `ui.book.unknown` | `???` | `???` | |
| `ui.book.reward` | `Reward: {name}` | `Premio: {name}` | `name` |
| `ui.book.reward_earned` | `Earned` | `Conseguido` | |
| `ui.book.reward_locked` | `Locked` | `Bloqueado` | |
| `ui.book.prev` | `Back` | `Atrás` | |
| `ui.book.next` | `Next` | `Siguiente` | |
| `ui.settings.title` | `Settings` | `Ajustes` | |
| `ui.settings.music_volume` | `Music volume` | `Volumen de la música` | |
| `ui.settings.effects_volume` | `Effects volume` | `Volumen de efectos` | |
| `ui.settings.camera_sensitivity` | `Camera sensitivity` | `Sensibilidad de la cámara` | |
| `ui.settings.reduce_motion` | `Reduce motion` | `Reducir movimiento` | |
| `ui.settings.on` | `On` | `Sí` | |
| `ui.settings.off` | `Off` | `No` | |
| `ui.settings.language` | `Language` | `Idioma` | |
| `ui.settings.language_auto` | `Auto` | `Auto` | |
| `ui.settings.language_en_us` | `English` | `English` | |
| `ui.settings.language_es_es` | `Español` | `Español` | |
| `ui.settings.percent` | `{value}%` | `{value}%` | `value` |
| `ui.hub.coins` | `Coins: {coins}` | `Monedas: {coins}` | `coins` |
| `ui.hub.best_size` | `Best size: {size}` | `Mejor tamaño: {size}` | `size` |
| `ui.results.coins_total` | `Coins: {coins} (total {total})` | `Monedas: {coins} (total {total})` | `coins`, `total` |
| `ui.results.first_run_tip` | `Coins and book entries are saved. Fill book pages for rewards!` | `Las monedas y el libro se guardan. ¡Completa páginas para ganar premios!` | |
| `reward.greybox.tier1.name` | `Tiny Cube Trail` | `Estela de cubo diminuto` | |
| `reward.greybox.tier2.name` | `Small Cube Trail` | `Estela de cubo pequeño` | |
| `reward.greybox.tier3.name` | `Medium Cube Skin` | `Aspecto de cubo mediano` | |
| `reward.greybox.tier4.name` | `Large Cube Skin` | `Aspecto de cubo grande` | |
| `error.profile_load_failed` | `We could not load your saved progress. Please rejoin in a moment.` | `No pudimos cargar tu progreso guardado. Vuelve a entrar en un momento.` | |
| `error.profile_version` | `Your save is from a newer version of the game. Please try again later.` | `Tu partida guardada es de una versión más nueva del juego. Inténtalo más tarde.` | |
| `error.session_ended` | `Your progress was opened on another server. Please rejoin.` | `Tu progreso se abrió en otro servidor. Vuelve a entrar.` | |

The existing `ui.results.new_entries` (`New in your book: {count}`) is reused for "New in your book"
(FR-014); `ui.results.self_best` now shows the persistent best. `ui.results.coins` stays as the fallback
line when `coinsTotal` is nil. The first-run tip text is provisional: it must fit two lines of 18 px text
in the 270 px results column (capture task); shorten it, not the size, if it does not.

`Strings.test.luau` additions: the key list above copied by hand into the test; `es` present on every key
added here; `{name}` placeholder sets equal between `en` and `es`; every `Localizer.t("…")` literal in
`src/client` and `src/server` exists (the existing test covers `src/client`; extend it to `src/server`).
