# Rollossal: game design brief

Status: draft 0.1, 2026-10-24. Numbers marked **(proposed)** are starting values to tune in
playtests; the owners confirm them in `/speckit-clarify` or in a pull request. **TBD (owner)**
marks decisions only the owners make, such as prices.

## 1. Summary

| | |
| --- | --- |
| Logline | Roll a ball that sticks to everything smaller than itself and grow from crumbs to houses. Merge with friends to grow faster. |
| Genre | Co-op growth / collection ("number goes up" with a physical toy) |
| Inspiration | Katamari Damacy (the feel); Roblox "grow" simulators (the progression). No Katamari names, art or music. |
| Platforms | Phone first, then PC, tablet, console (gamepad) |
| Session | 4-minute runs (proposed); a typical session is 3–6 runs |
| Rating target | Minimal |
| Launch theme | Winter: **Snow Village**. Reskin in January: **Candy Town** |
| Launch window | Release to the 16+ trial around 2026-12-01; aim for under-16 access before the school holidays |

### Audience

- **First audience:** age-checked 16+ players, who see every new Roblox game during its trial
  period and spend the most. They decide whether the game unlocks for ages 9–15. They need
  humour, a satisfying physical feel and a score to chase.
- **Target audience:** ages 10–12. They need instant fun, visible progress, collecting,
  friends, and moments worth a clip.
- **Design rule:** never babyish. The joke ("my ball just ate a bus") works at every age.

### Pillars

1. **Satisfying growth.** Every few seconds something gets swallowed, and every minute the
   world gets smaller.
2. **Funny with friends.** Merging, racing to be biggest, swallowing your friend in the opt-in
   mode.
3. **Collect the world.** A collection book of every object you've ever rolled up.
4. **Fair and kind.** Nothing for sale wins, and nothing pressures you.

## 2. Core loop

| Time scale | Loop |
| --- | --- |
| 5 seconds | Steer, touch something smaller, it sticks with a "pop" and a sound, and the size number ticks up |
| 1 minute | Hit a size tier: the camera pulls back, a banner reads "You can roll up: CATS!", and yesterday's walls become food |
| One run (4 min) | Reach the target size before the bell. Earn 1–3 stars, coins and new entries in the book |
| Over days | Coins unlock new worlds and ball cores. Fill the collection book. Beat your best size per world. Weekly new objects or events |

### Run flow

1. Spawn as a small ball (diameter 2 studs, proposed) in the shared world, with a 4:00 timer.
2. Roll up objects. Tiers unlock at set diameters.
3. When the bell rings, a results screen shows final size, stars, coins, new book entries and
   the best size among your friends.
4. **Roll again** (big button, same friends, about 3 seconds) or **Back to hub**.

## 3. Mechanics

### 3.1 Ball control

- **The ball** is one physics sphere (`Part`, `Shape = Ball`). The client owns its physics.
  Input comes from `Humanoid.MoveDirection` (the thumbstick or WASD), applied as torque through
  an `AngularVelocity` constraint plus a small forward force.
- **Speed** rises with size but more slowly than size, so big balls feel heavy (proposed:
  speed ∝ diameter^0.5, capped).
- **Camera** follows the ball, and its distance grows with diameter (proposed: 4 × diameter,
  clamped).
- **Avatar:** in the MVP it is hidden and the player *is* the ball. After the MVP, the avatar
  appears behind the ball with a pushing animation (feature flag `AvatarPusher`).
- **Jump:** a small hop, for kerbs and stairs. A button on mobile, Space on PC.

### 3.2 Absorbing objects

- **Object data:** every object has a data entry with `size` (its longest dimension in studs),
  `coins`, `tier` and `bookId`.
- **Absorb rule (proposed):** an object is absorbed if `size ≤ 0.4 × ballDiameter`.
- **Growth by volume** (proposed efficiency `k = 0.6`), so growth slows naturally:
  `newD = (D³ + k · size³)^(1/3)`.
- **What sticking looks like:** the object is welded at the contact point, with
  `CanCollide = false` and `Massless = true`. Only the **30 most recent** stuck objects stay
  visible (proposed); older ones count as buried and are removed.
- **Bumping big objects:** an object above the absorb size is a solid obstacle. A hit faster
  than the bump threshold knocks off the 3 most recent stuck objects (proposed), which scatter
  and can be re-collected. The ball shrinks back by their volume. This gives risk without
  punishment.
- **Respawning:** absorbed world objects respawn after 60–120 s (proposed), out of sight of
  nearby players, so a shared server never runs dry.
- **Server check on every absorb request:**
  - the object exists and has not already been taken;
  - the distance is at most `ballRadius + size/2 + tolerance`;
  - the size rule passes;
  - the request is within the rate limit (proposed 10 per second).

### 3.3 Size tiers (Snow Village, proposed)

| Tier | Ball diameter | Example objects (size) |
| --- | --- | --- |
| 1 Crumbs | 2–5 studs | sweets, buttons, pine cones, ornaments (0.3–1.5) |
| 2 Toys | 5–12 | teddies, gift boxes, snowballs, cats (1.5–4) |
| 3 Yard | 12–30 | snowmen, benches, sledges, fences, dogs (4–10) |
| 4 Street | 30–70 | cars, Christmas trees, kiosks, buses (10–25) |
| 5 Town | 70–150 | houses, the clock tower, the skating rink (25–60) |

- **Run targets (proposed):** 1 star = 20 studs, 2 stars = 45, 3 stars = 80.
- **Experiences to tune for:** reaching tier 5 in one run is possible but rare. That is the
  moment players want to clip.

### 3.4 Multiplayer

- **Server:** a shared world with up to 12 players (proposed). Runs are per player or per
  party; timers are personal.
- **Merge (co-op):**
  - Two friends tap **Merge** while touching.
  - They become one ball with the combined volume plus a 10% bonus (proposed).
  - Steering is the average of their inputs.
  - Coins are split evenly.
  - Either player can split back into two balls, each taking half the volume.
- **Friend boost:** +20% coins while you have a friend in the server (proposed).
- **Big Ball mode** (after MVP, opt-in, separate servers or a separate place):
  - A ball 1.3× bigger than another can swallow it.
  - The swallowed player respawns small at once and loses no permanent progress.
  - It is never on in the default mode.

### 3.5 Progression and economy

- **Coins:** the only currency, earned only by playing.
- **What players progress through:**
  - **Worlds:** Snow Village (free), then Candy Town, Junk City, Space. Each costs coins,
    with a paid early unlock (§6).
  - **Ball cores:** small stat flavours, for example Sticky (absorb rule 0.42), Heavy (fewer
    knock-offs) or Zoomy (+5% speed). They apply only in co-op and solo, never in Big Ball mode.
  - **Collection book:** one entry per object type, showing silhouettes for ones not yet
    found. Completing a page gives a cosmetic reward.
  - **Best size** per world, and a friends leaderboard.
- **Daily golden object:** one hidden object per world per day (seeded by date) worth bonus
  coins. Missing a day costs nothing.

## 4. UI and UX decisions

**Style**
- Chunky, rounded, toy-like.
- Fonts: built-in `FredokaOne` for headings, `GothamMedium`/`BuilderSans` for body text.
- Bright, high-contrast palette with a dark outline on every text element.

**Readability**
- Minimum text 18 px on phones; scale with `UIScale` per viewport.
- Every status uses an icon and a label, never colour alone.

### HUD (during a run)

| Position | Element |
| --- | --- |
| Top centre | Timer (mm:ss) and target size with a star marker |
| Top left | Size meter: the diameter as a large number plus a bar to the next tier, and "Next: [silhouette] CATS" |
| Top right | At most 3 icon buttons with labels: Book, Shop, Settings. Shop is disabled during runs and shows "after this run" |
| Bottom left | Roblox's default thumbstick |
| Bottom right | **Jump** (large) and **Merge** (only appears when touching a friend), each at least 96 px |
| Centre, short-lived | Pickup pop "+ Teddy Bear" with an icon (one line, fades in 1 s); tier banner |

**Feedback**
- Every pickup has a sound and a scale "pop".
- A light haptic pulse on mobile (`HapticService`).
- Camera shake on knock-offs, and a **Reduce motion** setting that removes it.

### First 60 seconds (protects play-through and first-session bounce, two key ranking signals)

1. Join, then go straight into a 4:00 run. No menu, no loading screen beyond Roblox's own.
2. Arrow and line: "Roll into small things!" Ten tiny objects are placed within 3 seconds of
   the spawn point.
3. By about 30 seconds the first tier banner appears.
4. The first results screen teaches the book and coins. The Shop is only introduced from
   run 2 on.

### Screens

- **Results:** final size, stars, coins, new book entries, the friend comparison, **Roll
  again**. One optional, dismissible line about a relevant cosmetic at most. No discounts, no
  timers.
- **Collection book:** a grid by tier with silhouettes for unknown objects and progress per
  page.
- **Shop:** tabs for Skins, Trails, Passes. Prices are read from `GetProductInfo` and shown
  in Robux on every button. Each item has a "what it does" line.
- **Settings:** music, effects volume, camera sensitivity, reduce motion, language.

### Store page

- **Icon:** a giant snowball with things stuck in it, mid-roll, one bold word.
- **Thumbnails:** 3–5 for Roblox's built-in thumbnail testing: a size contrast shot, friends
  merging, a "ball ate the clock tower" moment, and the collection book.
- **Title:** "Rollossal: Roll Up Everything". No "Christmas" in the name; seasons go in the
  icon and thumbnails.

## 5. Art and audio direction

**Look**
- Low-poly, flat-shaded toy diorama: one shared palette texture, with soft lighting and
  winter fog.
- Objects are slightly oversized and cartoonish, so they read at small sizes on phones.

**Blender pipeline (via MCP)**
- **Files:** sources in `art/source/*.blend`, exported to `art/export/*.fbx`.
- **Triangle budget (proposed):** tier 1–2 objects ≤ 300 triangles, tier 3 ≤ 800, tiers 4–5
  ≤ 2,500.
- **Import and IDs:** upload through Studio's 3D Importer, then record each ID in
  `src/shared/Assets.luau`.
- **Shared meshes:** objects of the same type reuse one MeshPart, so memory stays low.

**Asset count for the MVP:** about 60 object types for Snow Village, plus 8 ball skins, 4 trails
and 1 hub.

**Audio**
- A pickup "pop" with pitch rising by tier.
- A tier fanfare.
- A gentle, looping winter music track.
- Every sound has a visual equivalent.

## 6. Monetization

**Rules:** from constitution principle V.
- No paid random items, no trading, nothing paid that wins Big Ball mode.
- Coins are never sold.
- Prices **TBD (owner)**.

| Product | Type | What it does | Priority |
| --- | --- | --- | --- |
| Ball skins (snowglobe, disco, planet, …) | Dev product or pass per skin | Cosmetic | MVP |
| Trails and pickup effects | Pass per item | Cosmetic | MVP |
| **2x Coins** | Game pass | Doubles coins earned (unlocks only, never size within a run) | MVP |
| **Friend Boost** | Game pass | Everyone in your merged ball earns +25% coins. A purchase that benefits friends | MVP |
| VIP server | Private server | Play with your own friends | MVP |
| Early world unlock | Dev product | Unlocks the next world now; also earnable with coins | After MVP |
| Auto-book | Game pass | Shows where uncollected objects are | After MVP |
| Season cosmetic pack | Pass | Bundle of themed skins for each reskin | Live ops |

**Not in the MVP:**
- Rewarded video ads: rules for under-13 players are unclear. Behind a flag, using
  `PolicyService`.
- Subscriptions.

## 7. Live ops and reskin plan

| When | Update |
| --- | --- |
| Launch (about Dec 1) | Snow Village, 60 objects, co-op merge |
| Weekly in December | +8–10 new objects, a weekly golden-object event, and one new skin |
| Late December | "Big Ball" opt-in mode |
| January | Candy Town world (same code, new content data), with a store-page reskin to candy |
| February onward | Junk City, Space; book pages; monthly world cadence |

## 8. Safety and rating

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
