# Contract: Phone-first UI layout (run loop)

Grey-box UI: plain frames and text, no art. Everything is built in code by `UiKit` and is read-only with
respect to progress (Constitution II). All sizes below are **base pixels at `UIScale = 1`**. The scale is
`max(1, min(viewportX, viewportY) / 720)`, so on-screen text is never below its base size.

## Rules that apply to every element (FR-017, Principle VI)

- Text size ≥ `Config.minTextSize` (18). Buttons ≥ `Config.minTouchTarget` (96) in height and width.
- Fonts: `FredokaOne` for headings and numbers, `GothamMedium` for body. Every `TextLabel`/`TextButton` has a
  dark `UIStroke` (thickness 2).
- Every status has an icon glyph and a text label. Colour is decoration only; no meaning is colour-only and
  no feedback is sound-only (each sound has a visual twin).
- Every string is `Localizer.t(key, args)`; icons are `Icons[id]`.
- Layout is designed for **640×360 at scale 1** (smallest phone) and checked at **640×360, 844×390 and
  1280×720** viewport captures through the Studio MCP server (SC-002). No overlap, no clipping.
- The Roblox default thumbstick (bottom left) and the 001 Jump button (bottom right, 96 px) stay clear; no
  run UI sits in the bottom 130 px of either corner.

## HUD (state `Active` only; hidden in `Ended` and `Hub`)

| Region | Element | Base size (w×h) | Content |
| --- | --- | --- | --- |
| Top centre, row 1 | Timer | 170×44 | `[clock glyph] Time` label above or beside `mm:ss` (28 px `FredokaOne`) via `RunClock.format`; text label `ui.hud.time_label` |
| Top centre, row 2 | Star targets | 3 markers, each 100×36 | `[star glyph] ui.hud.star_target` (`1 star: 3.0`, `2 star: 4.0`, `3 star: 5.0`) from `Worlds.starThresholds`. A marker whose threshold the current diameter has reached is filled (`★`) and bold; unreached is outline (`☆`). State is carried by the glyph, not colour |
| Top left | Size meter | 160×104 | `ui.hud.size_label` + diameter number (`ui.hud.size_value`, 32 px) ; progress bar 160×14 filled by `Tiers.progress`; below it `ui.hud.next_tier` (two lines allowed: `Next: ▲` / `MEDIUM CUBES`) or `ui.hud.max_tier` on the top tier |
| Centre, y = 40 % | Pickup pop | 260×32 | one line `ui.pickup.pop` with the object icon; fades out over `Config.pickupPopDuration` (1.0 s); a new pickup replaces it |
| Centre, y = 26 % | Tier banner | 380×48 | `ui.banner.tier_unlock` with the tier's `headlineIcon`; shown `Config.tierBannerDuration` (2.5 s); one per tier per run (server-decided) |
| Bottom centre, y = 78 % | Bump flash | 140×32 | `[cube glyph] ui.bump.label` for `Config.knockOffShakeDuration`; the camera shake is skipped when `ReduceMotion` is on, the label is not |

Updates: timer text changes at most once per whole second; the size meter updates on the ball's `Diameter`
attribute change; the meter number does a 0.15 s scale pop on pickup (instant when `ReduceMotion`).

Top-centre block spans x ≈ 165 to 475 at 640 wide; the size meter spans x 8 to 168 and ends above y 112, so
the two meet only at the star row's left edge, which starts at x 170 (checked in the capture task).

## Results screen (state `Ended`, after `RunResult` arrives)

Full-screen dim layer (black, 0.35 transparency) with one centred panel **600×320** (fits 640×360 with 20 px
margins). No timers, no prices, no offers, nothing for sale (Principle V).

| Area | Content |
| --- | --- |
| Title (36 px, top) | `ui.results.title` |
| Left column | `ui.results.final_size`; three star glyphs 36 px (`★` earned, `☆` not) with `ui.results.stars` beside them; `[coin glyph] ui.results.coins` |
| Right column | `[book glyph] ui.results.new_entries` (or `ui.results.no_new_entries`), then up to 4 lines `[icon] object name` for `newBookIds`; below it the friend row: `ui.results.friend_best` when `bestFriendSize` exists, else `ui.results.self_best` with `bestSelfSize` |
| Bottom row | **Roll again** (`[retry glyph] ui.results.roll_again`) and **Back to hub** (`[home glyph] ui.results.back_to_hub`), each 250×96, 20 px apart |

Buttons fire `RollAgain` / `BackToHub` (see [remotes.md](remotes.md)) and the panel hides on the
`RunState` change, not on the click, so a rejected request leaves the screen up. The panel also hides when
`RunState` leaves `Ended` for any reason.

## Hub screen (state `Hub`)

Bottom-centre card: `ui.hub.title` (28 px) above one **Play** button (`[play glyph] ui.hub.play`, 260×96).
Pressing it fires `RollAgain`. The ball is free to roll on the plaza; there is no timer.

## Sounds and haptics (visual twins above)

| Moment | Sound (`Assets.sounds`) | Twin |
| --- | --- | --- |
| Pickup | `pickup`, `PlaybackSpeed = 1 + 0.08·(tier − 1)` | pickup pop, meter pop |
| Tier unlock | `tierUnlock` | tier banner |
| Knock-off | `bump` | bump flash, camera shake |
| Bell | `bell` | results screen |

Light haptic pulse on pickup where `HapticService` supports it, wrapped in `pcall` (research R11, finding F-3).
