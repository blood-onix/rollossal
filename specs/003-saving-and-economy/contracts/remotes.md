# Contract: Remotes (saving and economy)

Three new `RemoteEvent`s in `ReplicatedStorage.Remotes`, created by `src/server/Remotes.luau` (the folder
then holds twelve events: three from 001, six from 002, three here). Constitution II: the client sends
intents and preferences only. It never sends coins, sizes, results, book entries or rewards, and nothing it
sends can change them.

## `UpdateSettings(payload: table)` client → server

Intent: "these are my preferences". Handler signature `(player: Player, ...: unknown)`. Validation order
(first failure ends the request; nothing is mutated before all pass):

| # | Check | Reject code (internal) |
| --- | --- | --- |
| 1 | exactly one argument | `BadArgument` |
| 2 | `Config.Flags.Saving` is true and the server is not shutting down | `Disabled` |
| 3 | `RateLimit.allow(window, now, Config.settingsRateLimit, Config.rateLimitWindow)` (own window per player) | `RateLimited` |
| 4 | the player has an active profile | `NoProfile` |
| 5 | `typeof(payload) == "table"` | `BadArgument` |

On success: `profile.Data.settings = Settings.validate(profile.Data.settings, payload, bounds)` (bounds
built from `Config.Settings`), then `ProfileSync` to that player. Field-level problems (wrong type, NaN,
out of range, unknown key, unsupported language) are not request errors: bad fields are ignored or
clamped (see [rules-api.md](rules-api.md)) and the request still succeeds. Reject codes are for tests and
counters; they are never sent and never `warn`. A request with zero or two arguments, or a non-table,
changes nothing.

Accepted payload keys (all optional): `musicVolume`, `effectsVolume`, `cameraSensitivity` (numbers),
`reduceMotion` (boolean), `language` (string). Anything else is ignored.

## `RequestProfile()` client → server

Intent: "send me my saved state". No arguments; any argument is `BadArgument`. Rate-limited with its own
window (`Config.settingsRateLimit` per `Config.rateLimitWindow`). If the player has an active profile the
server answers with `ProfileSync`; if the profile is still loading it sends nothing now and `ProfileSync`
follows when the load finishes. Answers go to the requester only.

## `ProfileSync(snapshot: table)` server → client

Fired to one player: when its profile finishes loading, inside every successful run application, after
every accepted `UpdateSettings`, and in reply to `RequestProfile`. Payload (plain tables, no Instances):

```lua
{
	coins: number,
	bestSize: { [string]: number },        -- worldId -> studs
	book: { [string]: boolean },
	skinsOwned: { [string]: boolean },
	equipped: { skin: string?, trail: string? },
	settings: { musicVolume: number, effectsVolume: number, cameraSensitivity: number,
	            reduceMotion: boolean, language: string },
}
```

The client parses defensively (`ProfileClient.parse`): every field type-checked, anything wrong drops the
whole snapshot and keeps the previous one. It never throws.

## `RunResult` change (002 event, additive)

Two fields are added to the payload documented in `specs/002-run-loop/contracts/remotes.md`:
`coinsTotal: number?` and `isFirstRun: boolean`. `RunClient.parseResult` accepts a payload without them.
`bestSelfSize` is now the persistent best; `newBookIds` is computed against the persistent book.

## Not remotes

Loading, saving, applying a run, and granting rewards have no remote: they are server calls
(`DataService.applyRunResult`) driven by `RunManager`.
