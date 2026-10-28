# Rollossal: game design brief

Status: draft 0.2, 2026-10-28. Numbers marked **(proposed)** are starting values to tune in
playtests; the owners confirm them in `/speckit-clarify` or in a pull request. **TBD (owner)**
marks decisions only the owners make, such as prices.

**Art and content direction lives in [`docs/design/`](design/README.md)** (the design system:
world kit and seasons, the Downtown level and asset list, Holiday City, cosmetics, Roblox limits,
art style and tokens). This brief covers the game as a whole and defers to it on worlds, props,
themes, cosmetics and look. Since 0.2 the launch world is **Downtown in its Holiday City theme**
(it replaces Snow Village) and January brings **Sunny City**, the same map re-themed (it replaces
Candy Town). The detailed feature stories live in the Conveyor backlog (§11).

## 1. Summary

| | |
| --- | --- |
| Logline | Roll a ball that sticks to everything smaller than itself and grow from bottle caps to skyscrapers. Merge with friends to grow faster. |
| Genre | Co-op growth / collection ("number goes up" with a physical toy) |
| Inspiration | Katamari Damacy (the feel); Roblox "grow" simulators (the progression). No Katamari names, art or music. |
| Platforms | Phone first, then PC, tablet, console (gamepad) |
| Session | 4-minute runs (proposed); a typical session is 3–6 runs |
| Rating target | Minimal |
| Launch world | **Downtown**, one city re-themed by season: **Holiday City** at launch, **Sunny City** in January ([design](design/07-holiday-city.md)) |
| Launch window | Release to the 16+ trial around 2026-12-01; aim for under-16 access before the school holidays |

### Audience

- **First audience:** age-checked 16+ players, who see every new Roblox game during its trial
  period and spend the most. They decide whether the game unlocks for ages 9–15. They need
  humour, a satisfying physical feel and a score to chase.
- **Then:** ages 10–15 once under-16 access unlocks, with 10–12 at the core. They need
  instant fun, visible progress, collecting, friends, and moments worth a clip. Every asset
  stays Minimal-safe, so the same build works for both groups without a reskin.
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

### 3.3 Size tiers (Downtown, proposed)

The full list (74 core objects, heroes and theme slots) is in
[design/02-city-assets.md](design/02-city-assets.md).

| Tier | Ball diameter | Example objects (size) |
| --- | --- | --- |
| 1 Pocket | 2–5 studs | cans, water bottles, tennis balls, phones (0.3–1.5) |
| 2 Sidewalk | 5–12 | cones, hydrants, e-scooters, bins (1.6–4) |
| 3 Street | 12–30 | bikes, lamps, vending machines, young trees (4–10) |
| 4 Block | 30–70 | cars, vans, buses, bus stops, small shops (10–25) |
| 5 Skyline | 70–150 | buildings, a crane, the Ferris Wheel, The Glass Tower (25–60) |

- **Never absorbable:** people and real animals. The city is empty of people; pigeons are
  ambient and fly off ([design/05-roblox-limits.md](design/05-roblox-limits.md)).

- **Run targets (proposed):** 1 star = 20 studs, 2 stars = 45, 3 stars = 80 (tier 5).
- **Pacing (proposed):** first pickup by 0:05, tier 2 by about 0:30, tier 3 by about 1:30,
  tier 4 by about 2:45, checked by bot runs in every theme that ships
  ([design/03-city-level.md](design/03-city-level.md)).
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
  - **Levels and themes:** Downtown (free) is re-themed by season instead of a new map per
    season, which keeps the player base together in full servers. A second city level (for
    example Beach Boardwalk) comes later, unlocked with coins, with a paid early unlock (§6).
    Theme-only objects get their own book page that returns with the theme every year.
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

- **Icon:** a giant snowball-like ball with gifts stuck in it, mid-roll on Market Street in
  Holiday City, one bold word.
- **Thumbnails:** 3–5 for Roblox's built-in thumbnail testing: a size contrast shot ("my ball
  just ate a bus"), friends merging, a tier 5 finale (the bow-wrapped Glass Tower or the Ferris
  Wheel), and the collection book.
- **Title:** "Rollossal: Roll Up Everything". No "Christmas" in the name; seasons go in the
  icon and thumbnails.

## 5. Art and audio direction

**Look:** stylised real ([design/06-art-style.md](design/06-art-style.md)).
- Real city objects in real proportions, simplified into clean low-poly forms: one bevel
  segment on silhouette edges, smooth round parts, gradient shading baked into the texture.
  Only the one hero feature is exaggerated, by at most 10%.
- One 1,024 px gradient atlas per theme, all with the same layout, generated from
  [design/tokens.json](design/tokens.json). A season swaps the atlas, lighting, weather and
  music, never the meshes ([design/01-world-kit.md](design/01-world-kit.md)).
- No PBR maps, no transparency, no light per prop. Constitution XI governs the details.

**Blender pipeline (via MCP)**
- **Files:** sources in `art/source/*.blend`, exported to `art/export/*.fbx`.
- **Triangle budget:** today 300 / 300 / 800 / 2,500 / 2,500 by tier; proposed for stylised
  real 500 / 700 / 1,500 / 3,500 / 5,000, locked after a capture on the reference phone.
- **Import and IDs:** upload through Studio's 3D Importer, then record each ID in
  `src/shared/Assets.luau`.
- **Shared meshes:** objects of the same type reuse one MeshPart, so memory stays low.

**Asset count for the MVP:** 74 core Downtown objects, 20 Holiday City objects, the Sunny City
dressing, the cosmetic launch set in [design/04-player-cosmetics.md](design/04-player-cosmetics.md)
and 1 hub.

**Audio**
- A pickup "pop" with pitch rising by tier.
- A tier fanfare.
- A looping music track per theme (a holiday track at launch; the owner picks).
- Every sound has a visual equivalent.

## 6. Monetization

**Rules:** from constitution principle V.
- No paid random items, no trading, nothing paid that wins Big Ball mode.
- Coins are never sold.
- Prices **TBD (owner)**.

| Product | Type | What it does | Priority |
| --- | --- | --- | --- |
| Cosmetics: skins, toppers, trails, auras, pickup effects | Mostly coins; a few Robux items (creature sets, showcase trails) | Cosmetic ([design/04-player-cosmetics.md](design/04-player-cosmetics.md)) | MVP |
| **2x Coins** | Game pass | Doubles coins earned (unlocks only, never size within a run) | MVP |
| **Friend Boost** | Game pass | Everyone in your merged ball earns +25% coins. A purchase that benefits friends | MVP |
| VIP server | Private server | Play with your own friends | MVP |
| Early level unlock | Dev product | Unlocks the next level now; also earnable with coins | After MVP |
| Auto-book | Game pass | Shows where uncollected objects are | After MVP |
| Season cosmetic pack | Pass | Themed skin, topper and trail; returns with its season every year, never "limited" | MVP (holiday pack) |

**Not in the MVP:**
- Rewarded video ads: rules for under-13 players are unclear. Behind a flag, using
  `PolicyService`.
- Subscriptions.

## 7. Live ops and reskin plan

| When | Update |
| --- | --- |
| Launch (about Dec 1) | Downtown in Holiday City (see §10 for the launch scope) |
| Weekly in December | +8–10 new holiday objects on the *Downtown: Holiday* book page, a weekly golden-object event, and one new cosmetic |
| Late December | "Big Ball" opt-in mode |
| January | Downtown switches to Sunny City by data in a release, with a store-page reskin; the Holiday page stays, marked as returning next December |
| Later | Spring, autumn and night themes for Downtown; a second city level once the player base supports it |

## 8. Safety and rating

**Expected questionnaire answers:** no violence beyond cartoon bumping, no blood, no fear, no
romance, no gambling, no social hangout, no free-form drawing, no paid random items, no trading.
No absorbable people or animals, no real brands or meme images, no words on textures.
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

- **MVP:** Downtown in Holiday City (tiers 1–5, the core kit and the holiday objects), solo
  runs and results, coins, book, the cosmetic slots and coin shop, saving, English and Spanish,
  phone UI. Merge and the Robux shop (2x Coins, Friend Boost, VIP server, creature sets) are
  planned for launch; which of them make the 2026-12-01 build is an open question (§12).
- **Keep or kill (proposed):**
  - Keep if players average at least 3 runs per session and D1 retention is at least 10%.
  - Kill if D1 is under 8%, or most first sessions end within 3 minutes.

## 11. Feature backlog (in `/speckit-specify` order)

The full stories, with dependencies, tests and owner questions, live in the Conveyor backlog.
Done: 001 grey-box prototype, 002 run loop, 003 saving and economy, 004 Snow Village content
(now the rollback world).

1. **004a Theme system and art pipeline:** themes as data, the per-theme gradient atlas,
   stylised-real export checks, triangle budgets.
2. **004b Mechanics pass:** a jump that matters, boosters, season-neutral traps.
3. **004e Downtown in Holiday City:** the launch world, Holiday City art, Sunny City palette.
4. **004c Juice pass:** animation, VFX and game feel, driven by the active theme.
5. **004d People playtest:** at least 3 adults and 3 children aged 10–12 on Holiday City,
   recorded with the owner's sign-off.
6. **005 Co-op:** merge and split, friend bonus, party flow.
7. **006a Cosmetics and coin shop**, then **006b Robux purchases**.
8. **007 Onboarding, analytics and localisation.**
9. **008 Launch kit:** store page, questionnaire, Kids and Select, test place to live (owner).
10. **011 January switch to Sunny City.**
11. **After launch:** 009 Big Ball mode, 010 avatar pusher, 012 live ops, 013 second level and
    level select.

## 12. Risks and open questions

**Risks**
- **Resizing a rolling sphere with welded parts may cause jitter.** Feature 1 must prove it.
  Fallback: the visual stuck objects follow the ball client-side and are not welded.
- **Physics on a client-owned ball invites speed exploits.** Server speed checks, and absorbs
  are validated on the server.
- **Phone performance at tier 5.** Test early on a mid-range Android phone, in Holiday City
  (the heaviest theme) with 12 balls.
- **Art volume before launch.** About 94 new meshes for Downtown and Holiday City at roughly
  1.5–2× the old time per prop. Downtown loads with stand-in parts first, so layout and pacing
  never wait on art.
- **"Grow" fatigue: the genre is crowded.** The physical rolling ball must look different in
  the icon and first clip.

**Open questions (owner)**
- Prices.
- Extra locales.
- Whether Big Ball mode is in the launch build.
- Launch scope for 2026-12-01: which of co-op (005), the coin shop (006a) and the Robux shop
  (006b) are in.
- The holiday and Sunny City music tracks.
- The DataStore key name.
