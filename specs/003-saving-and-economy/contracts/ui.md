# Contract: Phone-first UI layout (saving and economy)

Grey-box UI: plain frames and text built by `UiKit`, no art. All sizes are **base pixels at
`UIScale = 1`**; the scale is `max(1, min(viewportX, viewportY) / 720)` (002), so on-screen text is never
below its base size. Layout is designed for **640×360 at scale 1** and checked at 640×360, 844×390 and
1280×720 viewport captures through the Studio MCP server (SC-004). The numbers below are the starting
point; the capture task may adjust offsets but not the rules.

## Rules that apply to every element (inherited from 002 `ui.md`, plus this feature)

- Text ≥ `Config.minTextSize` (18). Primary actions (Roll again, Play) stay ≥ `Config.minTouchTarget`
  (96). **Utility controls** (TopBar buttons, Book Prev/Next/Close, Settings controls) are ≥
  `Config.minUtilityTouchTarget` (64) in height and width (plan finding F-4).
- Fonts: `FredokaOne` headings and numbers, `GothamMedium` body; every text has the dark `UIStroke`.
- Every status is icon plus label; colour is decoration only. No sound-only feedback.
- Every string is `Localizer.t(key, args)`; icons are `Icons[id]`. Static labels are re-applied on
  `Localizer.changed`.
- Nothing sits in the bottom 130 px of the left or right corner (thumbstick, Jump) **except the open Book
  or Settings panel, which is modal by design** (the player chose to open it).
- Nothing covers the top-centre timer block (x 165 to 475, y 0 to 100 at 640 wide) in any state.
- No timers, prices, offers or purchase prompts anywhere in this feature (Constitution V).

## TopBar (states `Active`, `Ended`, `Hub`)

Top-right column, anchored top-right, 8 px from the right and top edges, 8 px between buttons.

| Button | Size | Content | Tap |
| --- | --- | --- | --- |
| Book | 150×64 | `[book glyph] ui.topbar.book`; while locked `[lock glyph] ui.topbar.book` | toggles `BookUi`; ignored while `RunClock.uiLocked` is true |
| Shop | 150×64 | `[shop glyph] ui.topbar.shop` | shows a notice: `ui.hud.shop_after_run` in `Active`, `ui.hud.shop_soon` otherwise (Flag `Shop` false); opens nothing |
| Settings | 150×64 | `[gear glyph] ui.topbar.settings` | toggles `SettingsUi` |

Column spans x 482 to 632, y 8 to 216 at 640×360: right of the timer block (ends x 475), above the
reserved bottom 130 px (y 230). The Shop notice is a one-line label (260×32, 18 px, `UIStroke`) at y 224 whose right edge is
136 px from the screen edge (x 244 to 504 at 640 wide), so it stays left of the Jump zone, visible `Config.noticeSeconds` (2 s), replaced by a newer notice, hidden on state change.

Lock behaviour: `TopBar` recomputes `RunClock.uiLocked(Workspace:GetServerTimeNow(), RunClient.endsAt(),
Config.runDurationSeconds, Config.runStartUiLockSeconds)` on `RunClient.stateChanged` and once per
`Heartbeat` for the first 5 s of an `Active` run only (a single `task.delay(lock - elapsed)` refresh is
enough; no per-frame work after that). A Book panel already open when a new run starts (Roll again) is
closed.

## BookUi (panel)

Anchored top-left, x 8 to 472, y 112 to 352 at 640×360 (464×240). It starts at y 112 because the 002 size meter (with its two-line "Next" label) ends at y 112. Background `Color3(40,44,52)`, corner 16.
Only one of Book and Settings is open at a time (opening one closes the other).

| Row | Height | Content |
| --- | --- | --- |
| Header | 64 | `[Prev ◀ 64×64]` `ui.book.title` over the tier page header `ui.book.page_progress` + tier name `[Next ▶ 64×64]` `[Close ❌ 64×64]`. Prev/Next are disabled (dimmed, glyph kept) on the first/last page |
| Reward line | 28 | page reward: `[check or lock glyph] ui.book.reward` with the reward's name key, then `ui.book.reward_earned` or `ui.book.reward_locked` (text, not colour). Hidden when the tier has no reward |
| Grid | 148 | `ScrollingFrame`, vertical scroll only, grid of object cards |

Card (108×84, 8 px gaps, 4 per row at 464 wide): discovered card = object icon (28 px) over the localized
name (18 px, two lines allowed); undiscovered card = `[unknown glyph]` in dark grey over `ui.book.unknown`
(`???`). The silhouette is a dark glyph, not an object shape: information is carried by the glyph and the
`???` text. A tier page with more than 8 cards scrolls; the grey-box pages hold 1 card.

Open page defaults to the first page that is not complete (else the last). The panel refreshes on
`ProfileClient.changed` and on `Localizer.changed`. All text ≥ 18 px; header page text `{collected} /
{total}` is 20 px `FredokaOne`.

## SettingsUi (panel)

Same footprint as BookUi (464×240 at x 8, y 112). Header row 64: `ui.settings.title` and `[Close ❌ 64×64]`.
Body 176 in two columns of 224 with 8 px gap:

| Left column (3 rows of 56) | Right column |
| --- | --- |
| `ui.settings.music_volume` label (18 px) + value `ui.settings.percent` (0 to 100) over a slider (track 208×24, handle 40×40, so the touch target is ≥ 40 wide and the row is 56 high) | `ui.settings.reduce_motion`: a 224×64 toggle button `[check or off] ui.settings.on / ui.settings.off` |
| `ui.settings.effects_volume`, same | `ui.settings.language`: three 72×64 buttons `ui.settings.language_auto`, `_en_us`, `_es_es`; the selected one shows `[check glyph]` and a bold font |
| `ui.settings.camera_sensitivity`, value `ui.settings.percent` (50 to 200), same | |

Slider value rounds to whole percent for display only; the sent number is the raw fraction. Sliders send
through `ProfileClient.sendSettings` (debounced `Config.settingsSendDelay`). Changing a control applies
locally at once (R7), then the server echo overwrites it with the authoritative value; a server-clamped
value moves the control. The slider handles are the one place a utility control is below 64 px (40 px
wide); the track row is 56 px high and the whole row is the drag area, which the capture task checks
against Roblox's 44 px guidance.

Camera sensitivity is applied through `UserInputService.MouseDeltaSensitivity` (mouse only). The touch
pan cannot be scaled by script, so on touch devices the setting is saved and restored but has no effect;
no custom camera is built in this feature (plan finding F-7).

## Hub screen additions (`HubUi`, state `Hub`)

Card grows from 300×180 to 300×236: above the Play button two 24 px rows, `[coin glyph] ui.hub.coins` and
`[star glyph] ui.hub.best_size` (best size of `Worlds.active.worldId`, one decimal, `0.0` when none). Rows
come from `ProfileClient`, refresh on `changed`. Card stays bottom-centre (x ≈ 170 to 470), clear of both
corners.

## Results screen additions (`ResultsUi`, state `Ended`)

Panel is 464×320 (was 600×320 in 002), centred in the space left of the TopBar column (x centre = half the screen width minus 83), because the TopBar stays on screen above the dim layer and a 600 wide panel would sit under its buttons at 640×360. Columns are 214 wide with 12 px margins; the two buttons are 214×96. Left column: `ui.results.final_size`; stars; **one** coins line, `ui.results.coins_total`
(`Coins: 12 (total 20)`) when `coinsTotal` exists, else the 002 `ui.results.coins`. Right column: unchanged
`ui.results.new_entries` header and ≤ 4 object lines (each `[icon] name`), then the friend/self-best row,
where `bestSelfSize` is now the persistent best. **First run (`isFirstRun`)**: the best-size row is replaced
by `ui.results.first_run_tip` (two lines of 18 px) and the entry list shows at most 3 lines; when there are more than 3 entries the third line reads
`ui.results.more_entries` (`+N more`, N counting every entry not shown by name). The TopBar stays
visible above the dim layer (it is a separate ScreenGui; `UiKit.screen` gets an optional `displayOrder`
argument and TopBar passes a higher one), so Book can be opened from the results screen.

## Language switch

Every screen with static text has one `refreshText()` that rebuilds its labels; it is connected to
`Localizer.changed`. The pickup pop and tier banner build their text per event and need no refresh.

## Capture checklist (gate 2)

At 640×360, 844×390 and 1280×720: HUD with TopBar in `Active` (timer visible, bar clear); TopBar in `Hub`;
BookUi open on a complete and an incomplete page; BookUi with the Book button locked at t = 2 s (tap
ignored); SettingsUi open; Hub with coins and best size; Results on the first run (tip) and on a later run;
the same Book page after switching language to `es-es`. For each: no overlap, no clipping, timer visible,
all text ≥ 18 px.
