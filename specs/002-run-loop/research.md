# Research: Run Loop

**Feature**: `002-run-loop` | Spec: [spec.md](spec.md) | Plan: [plan.md](plan.md)

Every `NEEDS CLARIFICATION` from the Technical Context is resolved here. Format: Decision, Rationale,
Alternatives considered. Numbers are hand-computed; the Lune tests copy them as fixed values.

## R1. Grey-box tiers and star targets (finding F-1)

**Decision**: Size tiers follow the moment each cube size becomes absorbable (`S / 0.4`, from 001 R1).
Star targets for the grey-box room are `{ 3.0, 4.0, 5.0 }` studs, stored in `GreyBoxRoom.starThresholds`.
`Config.starThresholds = { 20, 45, 80 }` stays as the default for worlds that do not override it.

| Tier | `minDiameter` | Source | Headline (banner) | Object | Coins |
| --- | --- | --- | --- | --- | --- |
| 1 | 2.0 | `Config.startDiameter` | TINY CUBES | `cube_t1` (0.75) | 1 |
| 2 | 2.375 | `0.95 / 0.4` | SMALL CUBES | `cube_t2` (0.95) | 2 |
| 3 | 3.0 | `1.2 / 0.4` | MEDIUM CUBES | `cube_t3` (1.2) | 3 |
| 4 | 3.75 | `1.5 / 0.4` | LARGE CUBES | `cube_t4` (1.5) | 5 |

`maxDiameter` of tier `n` equals `minDiameter` of tier `n+1`; tier 4 has none. Banners fire for tiers 2 to
4 only (tier 1 is the start state).

**Why `{ 20, 45, 80 }` cannot be used here**: the ball's volume grows by `0.6·S³` per pickup. The room
holds 30 cubes worth `12·0.253125 + 9·0.514425 + 6·1.0368 + 3·2.025 = 19.96` volume units per refill, and
every cube respawns after 15 s (`Config.respawnDelay`). The most a solo ball can eat is therefore about
`19.96 / 15 = 1.33` volume units per second at the very best. 001 measured Tier 4 opening at 101 s
(`D³ ≥ 52.73`). From there to the bell is 139 s, so the hard ceiling is `D³ ≈ 52.73 + 1.33·139 = 238`,
`D ≈ 6.2`; a skilled player at about 1.4 pickups/s reaches roughly `D³ ≈ 52.73 + 0.93·139 ≈ 182`, `D ≈ 5.7`.
`D = 20` needs `D³ = 8000`. No star could ever be earned.

**Why `{ 3.0, 4.0, 5.0 }`**: 1 star is "unlocked Tier 3" (`D³ = 27`, about 65 s solo); 2 stars is "past Tier 4's
gate" (`D³ = 64`, about 115 to 125 s solo); 3 stars is `D³ = 125`, which needs about 0.5 volume units per
second after Tier 4 opens, a strong but possible run. These are provisional. The playtest (Principle I)
confirms or retunes them; they are data, so retuning is a one-line edit.

**Rationale**: the spec's Assumptions already allow world-level star thresholds. The pure rule takes the
array as an argument, so one function serves both worlds (FR-001, FR-006).

**Alternatives considered**: (a) keep `{ 20, 45, 80 }` and accept zero stars: makes the results screen
untestable. (b) Scale the room so `{ 20, 45, 80 }` is reachable: needs hundreds of cubes and new art,
belongs to Feature 004. (c) Lower the global `Config.starThresholds`: wrong for Snow Village.

## R2. Run clock and replication of time

**Decision**: `RunManager.step(now)` receives the clock as an argument, exactly like `WorldSpawner.update`
and `BallService.step`. `Main.server` passes `os.clock()`. A run stores `startedAt = now` and
`endsAt = now + Config.runDurationSeconds`. `RunClock.expired(now, endsAt)` is `now >= endsAt`.
For replication the server also writes `RunEndsAt = Workspace:GetServerTimeNow() + (endsAt − now)` to the
player; the client shows `RunClock.format(RunEndsAt − Workspace:GetServerTimeNow())`.

`RunClock.format(seconds)` uses `math.ceil`, clamps below 0 to 0, and prints `mm:ss`. So 240 shows `04:00`,
0.4 shows `00:01`, and `00:00` appears only at the bell.

**Rationale**: an injected clock lets Jest tests step 240 s instantly and assert that no second result
appears (FR-024). `GetServerTimeNow` is the engine's synchronised clock, so the client countdown matches
the server within network latency. Using `os.clock` for authority and server time only for display keeps
the authoritative path independent of clock jumps.

**Alternatives considered**: `task.delay(240, endRun)` per run: not steppable, leaks on leave, hard to test.
Replicating a remaining-seconds number every second: more traffic, drifts, and a frozen client shows stale
data.

## R3. Freezing the ball at the bell

**Decision**: when a run ends the server sets `AssemblyLinearVelocity` and `AssemblyAngularVelocity` to
zero and `part.Anchored = true`. When the ball is released (Roll again or Back to hub) the server sets
`Anchored = false` and calls `part:SetNetworkOwner(player)` again. `BallController` also ignores input
unless `RunState` is `Active` or `Hub`. `AbsorbService` rejects Absorb and Bump unless the run accepts
them (R5); the check uses `now`, so a request that arrives in the same Heartbeat as the bell is rejected
even if `step` has not run yet.

**Rationale**: anchoring is authoritative and cannot be bypassed by a client that ignores the lock.
`SetNetworkOwner` is not allowed on an anchored part and ownership is dropped while anchored, so it must be
reassigned after unanchoring (documented Roblox behaviour; verified in the first Studio task, with the
fallback below).

**Fallback if re-owning misbehaves** (checked in the Studio spike task): keep the ball unanchored and
zero its velocity every Heartbeat while `Ended`, with `Massless`-style input lock only. Same contract, so
only `BallService.setFrozen` changes.

**Alternatives considered**: input-lock only (client-trusting, rejected by Principle II); `PlatformStand`
(no humanoid here); destroying and recreating the ball (loses ReplicationFocus, resets visuals, more churn).

## R4. Fall and Reset button mid-run

**Decision**: `BallService.step` now calls a new `returnToSpawn(session)` when `y < Config.fallRespawnY`:
position and velocity reset, `authoritativeDiameter`, `stuckStack` and the run all untouched (FR-016). The
Roblox Reset button (`RespawnBall`) does the same while a run is `Active`; in `Hub` (or when no run exists,
as in the 001 tests) it keeps the 001 full reset (`BallService.respawn`); in `Ended` it is rejected.
`resetBall` (new) is the run-boundary reset: return releasable cubes to their spawn spots, clear the stack,
diameter back to `startDiameter`, place at the zone spawn.

**Rationale**: the spec says a fall must not wipe a run. A Reset that wiped the ball during a run would be
an equal accident on a phone. The 001 behaviour stays for the no-run case, so the 001 Jest tests pass
unchanged.

**Alternatives considered**: Reset ends the run (punishes a stuck ball and creates a results screen the
player did not earn); Reset disabled during runs (a ball wedged in the kerb has no escape).

## R5. How run state and events reach the client

**Decision**: state as attributes on the `Player` (replicated to everyone, which is fine because none of it
is secret): `RunState` (`"Active" | "Ended" | "Hub"`), `RunId` (string), `RunEndsAt` (server time, number,
`0` outside `Active`). One-shot facts use four server-to-client RemoteEvents fired with `FireClient` to the
owning player only: `PickupConfirmed(objectId)`, `TierUnlocked(tier)`, `KnockedOff()`, `RunResult(result)`.
Client intents: `RollAgain()` and `BackToHub()`, zero arguments.

The current tier and the progress fraction are not replicated: the client computes them from the ball's
`Diameter` attribute with the same pure `Tiers` rule, so they cannot disagree with the server's diameter.
Only the "banner already shown" decision is server state (`unlockedTiers`), because it depends on history.

**Rationale**: attributes survive late joins and reconnects of the client script; events carry things that
must happen once. Four typed events are clearer and cheaper than one stringly-typed event. Two intent
events avoid parsing an action string. `PickupConfirmed` carries an object type ID because the HUD needs
the name and icon; the client resolves it through `Worlds`.

**Alternatives considered**: a `Folder` of `ValueBase` objects per player (more instances, same effect);
sending the whole run state on every change (needless traffic); letting the client infer pickups from the
`Stuck` attribute (cannot know which object type was eaten once old entries scroll off, and cannot tell a
knock-off from the 31st-object eviction).

## R6. The hub plaza

**Decision**: `WorldSpawner.start` also builds `Workspace.Hub`: one anchored grey floor `2·hub.halfExtent`
square, centred at `hub.center` (far from the room so streaming never shows both), plus a flat disc "start
pad" part with no text. `WorldSpawner.getHubSpawn()` returns the ball spawn point. The ball is the same
part; `Session.zone` is `"Room"` or `"Hub"` and decides where `placeAtSpawn` puts it. In the hub the player
can roll freely (state `Hub`: absorbs rejected, no timer). A large **Play** button on the HUD
(`HubUi`) sends `RollAgain`, which from `Hub` starts a new run in the room (FR-014, FR-015). The start pad
is decoration only; no touch detection (YAGNI).

**Rationale**: reuses the ball, camera and network ownership. The spec allows "pad and/or on-screen
button"; one big button is the one-thumb choice.

**Alternatives considered**: a ProximityPrompt (small target on phones); teleporting the player to a
character in a hub (the game has no characters).

## R7. Friends, best sizes and the friend bonus

**Decision**: `FriendCache` stores `friends[userId][otherUserId] = boolean`. On `PlayerAdded` it fills the
new player's row for everyone present, and everyone else's row for the new player, each lookup in
`task.spawn(pcall(player.IsFriendsWith, player, otherId))`; failure stores `false`. On `PlayerRemoving` the
leaver's row and column are deleted. `RunManager` keeps in-memory `bestSelfSize[userId]` (best completed
`finalDiameter` this server session) and `seenBookIds[userId]` (set). At the bell:
`hasFriendInServer` = any cached `true` among present players; `bestFriendSize` = the maximum
`bestSelfSize` among present friends with a recorded size, else `nil`. `bestSelfSize` in the result includes
the run just ended. The results screen shows the friend row if `bestFriendSize` exists, else the player's own
best (spec Assumption).

**Rationale**: `IsFriendsWith` yields and can fail; caching once per pair keeps the bell path synchronous
and deterministic. A friend who finishes later is read from `bestSelfSize` at the bell, which is current.

**Alternatives considered**: calling `IsFriendsWith` at the bell (can yield and delay the result);
`Players:GetFriendsAsync` (pages the whole friends list, heavier and rate-limited).

## R8. Localisation

**Decision**: `Strings.luau` is a plain table `{ [key]: { en: string } }`, keyed `ui.hud.*`,
`ui.banner.*`, `ui.pickup.*`, `ui.results.*`, `ui.hub.*`, `tier.greybox.<n>.name|headline`,
`object.greybox.<id>` (full list in [contracts/content-and-config.md](contracts/content-and-config.md)).
`Localizer.luau` builds one `LocalizationTable` from it (`SetEntries`, source locale `en-us`), and exposes
`Localizer.t(key, args?)`, which calls `Translator:FormatByKey` for the player's locale
(`LocalizationService.RobloxLocaleId`) and falls back to `en-us`. Placeholders use Roblox's `{name}` form.
Spanish is added to `Strings.luau` in Feature 007 with no code change.

Two Lune tests enforce IX: `Strings.test` checks every key referenced by `GreyBoxRoom` and every
`Localizer.t("…")` literal found in `src/client` has a non-empty `en` entry and that `{placeholders}`
are well formed; `LiteralGuard.test` scans `src/client` and `src/server` and fails on any `Text = "…"` or
`.Text = "…"` whose literal contains two or more consecutive letters. Symbol-only text such as `▲` and `★`
is allowed (it carries no words).

**Rationale**: data in a Lune-loadable module is testable outside Studio; the `LocalizationTable` is the
engine's own mechanism, as the constitution asks. A regex scan is crude but cheap and catches the actual
failure (an English sentence typed into a script).

**Alternatives considered**: `LocalizationTable` authored in Studio (not in the repo, not reviewable);
CSV import (a second tool). A luau-lsp custom rule (does not exist).

## R9. Placeholder icons and sounds

**Decision**: icons are Unicode glyphs mapped from an icon ID in `Content/Icons.luau` (`star` → `★`,
`clock` → `⏱`, `coin` → `●`, `cube` → `■`, `arrow` → `▲`, `book` → `▤`, `retry` → `↻`, `home` → `⌂`).
Each icon ID is what content data stores (`icon = "cube"`), so real images can replace the glyph later by
editing one module. A silhouette for "Next:" is the same glyph drawn in a dark colour. The Studio viewport
capture confirms every glyph renders in `FredokaOne`/`GothamMedium`; a glyph that does not render is swapped
in `Icons.luau` (one line).

Sounds: `Assets.luau` lists `pickup`, `tierUnlock`, `bump`, `bell` as engine-bundled `rbxasset://sounds/…`
paths (for example `electronicpingshort.wav`, `button.wav`, `snap.mp3`, `bass.wav`). They are confirmed to
exist and play in the first Studio task; pickup pitch uses `PlaybackSpeed = 1 + 0.08·(tier − 1)`.

**Rationale**: Constitution I forbids polish before the playtest; XI says asset IDs go in `Assets.luau`
only. Built-in sounds need no upload and no owner approval. Glyphs give "icon plus label" without art.

**Alternatives considered**: uploading sounds (account action, may need approval); image icons (needs
Blender/art pipeline, out of scope); drawing shapes from `Frame`s (more code than a glyph).

## R10. Building the UI

**Decision**: all UI is built in code by `UiKit` (no Studio-authored GUIs, so everything is in git and
reviewable). `UiKit.screen(name)` creates a `ScreenGui` (`ResetOnSpawn = false`, `IgnoreGuiInset = true`)
with a `UIScale` whose `Scale = math.max(1, math.min(viewport.X, viewport.Y) / 720)`, updated on
`ViewportSize` change. Every `TextLabel`/`TextButton` gets `UIStroke` (dark, thickness 2), `FredokaOne` for
headings and `GothamMedium` for body, and `TextSize ≥ Config.minTextSize (18)`. Buttons are at least
`Config.minTouchTarget (96)` square in base pixels. Because the scale never drops below 1, on-screen size
is never below the base size.

Layouts are fixed per [contracts/ui.md](contracts/ui.md) and are checked at 640×360 (smallest phone), 844×390
and 1280×720 viewport captures. HUD text updates: the timer label once per second (on the whole-second
change), the meter on `Diameter` attribute change.

**Rationale**: a one-sided scale (≥ 1) is the only simple way to guarantee the 18 px and 96 px floors; the
layouts are designed to fit 640×360 at scale 1.

**Alternatives considered**: `Scale = short/720` with sizes in offset (text drops below 18 px on small
phones: violates VI); `TextScaled` (unpredictable pixel size).

## R11. Feedback: pop, haptics, shake, reduce motion

**Decision**:
- Pickup pop: the centre label fades in and out over `Config.pickupPopDuration` (1.0 s); the HUD meter
  number scales 1.0 → 1.15 → 1.0 over 0.15 s (the "pop"). The ball itself is not scaled (its size is physics).
- Haptics: `Feedback` tries `HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)` and
  `SetMotor` inside `pcall`; unsupported devices silently skip. Finding F-3: phones may have no engine
  vibration API; the real-device result goes in `playtest.md`.
- Shake: `CameraController.shake(duration, magnitude)` adds a decaying random offset in a
  `RunService:BindToRenderStep` step after the camera update, for `Config.knockOffShakeDuration` (0.35 s),
  magnitude `Config.knockOffShakeMagnitude` (0.6 studs). A "bump" label with the `■` icon flashes
  centre-bottom for the same time, so the knock-off never relies on shake alone.
- Reduce motion: `ClientSettings` is not built (Settings screen is out of scope). The flag is the
  player attribute `ReduceMotion` (boolean, client-set, default `false`). When true, shake is skipped and
  the pop scale animation is replaced by an instant change. If Studio shows the engine exposes a user
  reduced-motion setting, `Feedback` initialises the attribute from it (checked in the first client task).
  **Checked in T038**: `GuiService.ReducedMotionEnabled` exists, is readable by game scripts and has a change
  signal, so `Feedback` follows it.
- Tier pull-back: the existing camera distance already tracks `4 × diameter` with smoothing (001 R5), so
  crossing a tier is accompanied by the pull-back the diameter growth causes. No extra camera code.
- Tier banner once per tier per run: decided by the server (`unlockedTiers`), delivered as `TierUnlocked`.

**Rationale**: every effect has a text/icon twin (VI). The shake is a single bound render step, removed when
finished.

## R12. Content schema and the world seam

**Decision**: `GreyBoxRoom.luau` gains `worldId = "greybox"`, `starThresholds`, `sizeTiers` (the spec's
`WorldTierDef`), `objects` (the spec's `ObjectContentDef`) and `hub`. The 001 `tiers` list (cube layout:
`size`, `count`, `shade`) stays; a Lune test asserts each object's `size` equals its layout tier's `size`
and that every layout tier has exactly one object. Cubes keep their `tier`; the object for a cube is the one
with the same `tier`. `Worlds.luau` requires the world and builds indexes (`objectByTier`, `objectById`,
`objectByBookId`, `sizeTiers`, `starThresholds` with the `Config` fallback). `RunManager`, `Hud`,
`ResultsUi`, `Feedback` read the world only through `Worlds`, so Feature 004 adds `SnowVillage.luau` and
changes one line in `Worlds.luau`.

**Rationale**: pure rule modules cannot `require` siblings under Lune (001 convention), so lookups that
need the world live in the Roblox-side `Worlds` module; they are 10 lines of table building. Keeping `tiers`
untouched avoids rewriting 001 code and tests.

**Alternatives considered**: merging `tiers` and `objects` (touches `WorldSpawner`, 001 tests); a general
world registry now (one world; Principle XII says wait for the second).

## R13. Feature flag and rollout

**Decision**: `Config.Flags.RunLoop = true`. When `false`, `RunManager` creates no runs and every other
module behaves as in 001 (free rolling, full respawn on fall is replaced by return-to-spawn only, see R4).
The client shows no run UI when the player has no `RunState` attribute.

**Rationale**: Principle VII asks for new features behind flags; a no-run player is exactly the shape the
001 tests already use, so the fallback needs almost no code.

## R14. Test strategy

**Decision**:
- Lune (`tests/unit`): Stars boundaries (`19.99 → 0`, `20 → 1`, `44.99 → 1`, `45 → 2`, `79.99 → 2`, `80 → 3`,
  plus the grey-box `{3,4,5}` set); Tiers lookup at and between every grey-box boundary and past the top;
  progress fractions; Coins with each multiplier alone and combined, rounding at `.5`, empty list; RunClock
  `remaining`, `expired` at the exact `endsAt`, `format` of `240, 239.2, 61, 59.01, 0.4, 0, −3`; content
  integrity; string coverage; literal guard.
- Jest-Lua (`tests/studio/RunManager.spec.luau`) drives `RunManager` with injected `now`: run starts with
  a unique `runId`; absorb at `endsAt − ε` passes and at `endsAt` fails; `step(endsAt)` yields exactly one
  result and `step(endsAt + 100)` yields none; remote handlers called with extra or wrong arguments, or
  while `Active`, change nothing; fall below `fallRespawnY` keeps diameter, stack and `runId`; Roll again
  gives a new `runId`, diameter `2`, empty stack, within `rollAgainDelaySeconds` of injected time; leave
  mid-run publishes nothing; tier banner fires once per tier across a knock-off and regrow.
- Studio MCP playtest and phone-resolution captures for SC-002 and SC-006.

**Rationale**: matches 001's split (pure → Lune; services → Jest-Lua via MCP).
