
**Expected questionnaire answers:** no violence beyond cartoon bumping, no blood, no fear, no
romance, no gambling, no social hangout, no free-form drawing, no paid random items, no trading.
**Expected label: Minimal.**

**Kids and Select (under-16 access) checklist:**
- The owner's account is ID-verified with 2FA on, or the game is owned by the owner's group.
- The full questionnaire is completed.
- The 1,000 Robux fee is paid, or Premium has been held for 2 months.
- 250 plays from highly engaged age-checked 16+ players within 60 days, or the refundable
  50,000 Robux expedited review.

**Code requirements:** `PolicyService` checks wrap any future ads or paid-item features.

## 9. Technical architecture

```
src/shared/Rules/      pure: absorb rule, growth maths, stars, coins, merge maths (Lune-tested)
src/shared/Content/    data: worlds, objects, tiers, skins, theme packs
src/shared/Config      flags, tuning numbers, budgets
src/shared/Assets.luau asset IDs
src/server/            BallService, AbsorbService, RunManager, WorldSpawner, DataService
                       (ProfileStore), PurchaseService (ProcessReceipt), Telemetry
src/client/            BallController (input to torque), CameraController, StuckVisuals,
                       Hud, ResultsUi, BookUi, ShopUi, Settings
tests/unit/            Lune tests for Rules and Content validation (sizes ascending, IDs unique)
tests/studio/          Jest-Lua tests: DataService, PurchaseService, absorb validation
art/source, art/export Blender files and exports
```

**Profile schema v1 (proposed; owner approves key names):** `version`, `coins`,
`worldsUnlocked`, `skinsOwned`, `equipped`, `book` (a set of `bookId`s), `bestSize` per world,
`receipts` (processed receipt IDs), `settings`.

**Performance**
- Streaming is on (`StreamingEnabled`).
- Objects are pooled and reused rather than created and destroyed.
- Visible stuck objects are capped.
- Objects far below the current tier are hidden on the client for that player.

**Analytics (Roblox analytics events):**
- Tutorial steps: spawn, first pickup, first tier.
- Run start and end, with size and stars.
- Merges, shop opens, first purchase.
- KPIs: play-through rate, first-session bounce under 1 minute and 1–3 minutes, D1 and D7
  retention, runs per session, co-play share.

## 10. MVP scope and keep/kill

- **MVP:** Snow Village, tiers 1–4, 60 objects, solo and merge, runs and results, coins, book,
  5 skins, 2 trails, 2x Coins, Friend Boost, VIP server, saving, English and Spanish, phone UI.
- **Keep or kill (proposed):**
  - Keep if players average at least 3 runs per session and D1 retention is at least 10%.
  - Kill if D1 is under 8%, or most first sessions end within 3 minutes.

## 11. Feature backlog (in `/speckit-specify` order)

1. **Grey-box prototype:** ball control, the absorb rule, growth, camera and one room with 30
   cubes of 4 sizes. A fun test with 6 people.
2. **Run loop:** the timer, targets, stars, the results screen, Roll again.
3. **Saving and economy:** DataService with ProfileStore, coins, best size, collection book.
4. **Snow Village content:** about 60 objects in 4 tiers via the Blender pipeline, respawning,
   world layout.
5. **Co-op:** merge and split, Friend Boost, party flow.
6. **Shop and purchases:** skins, trails, passes, an idempotent receipt handler, the VIP server.
7. **Onboarding, analytics and localisation:** the first-60-seconds flow, events, English and
   Spanish tables.
8. **Launch kit:** icon, thumbnails, completed questionnaire, Kids and Select prerequisites,
   test place to live (owner).
9. **After launch:** Big Ball mode, the avatar pusher, the Candy Town reskin, weekly object
   drops.

## 12. Risks and open questions

**Risks**
- **Resizing a rolling sphere with welded parts may cause jitter.** Feature 1 must prove it.
  Fallback: the visual stuck objects follow the ball client-side and are not welded.
- **Physics on a client-owned ball invites speed exploits.** Server speed checks, and absorbs
  are validated on the server.
- **Phone performance at tier 5.** Test early on a mid-range Android phone.
- **"Grow" fatigue: the genre is crowded.** The physical rolling ball must look different in
  the icon and first clip.

**Open questions (owner)**
- Prices.
- Extra locales.
- Whether Big Ball mode is in the launch build.
- The DataStore key name.
