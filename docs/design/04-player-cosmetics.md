# Player cosmetics and shop

Everything a player can show off. All cosmetic, never stats (ball cores are a separate, coin-only system per the GDD). Five equip slots: **Skin, Topper, Trail, Aura, Pickup effect**. A **set** is a skin and a topper sold or earned together.

## The design problem: the ball gets covered, and it spins

From about 30 seconds in, stuck objects cover most of the ball's surface, and the ball is always rolling. Two consequences:

- A skin alone disappears exactly when the player is proudest. Mid-run identity lives in the **topper**, **trail** and **aura**.
- **A face painted on the skin spins upside down** every half-second. Anything with a face or ears (the kitten, the dog) is a set: an all-over pattern on the skin plus an upright topper that carries the face and looks where you roll.

| Moment | What shows | So design for |
| --- | --- | --- |
| Hub, spawn, first 30 s, results | The skin | Bold, big pattern, readable at 2 studs |
| Mid-run (covered ball) | Topper, trail, aura | Things that sit **above** or **behind** the pile, scaled with diameter |
| Every pickup | Pickup effect | A short burst on the contact point |

## Skins

One texture per skin on a sphere MeshPart (512 px; sports balls use the same UV layout so new ones are a texture only), or a built-in `Material` + `Color` for the simplest.

### Sports balls (the obvious ones, done generic)

Generic designs only: no league, maker or tournament logos, no copied official panel layouts or colourways.

| Skin | Look | Note |
| --- | --- | --- |
| Rubber (default) | Matte red dodgeball, one white seam | `SmoothPlastic` + `w-accent-red` |
| Football | Classic black pentagons on white | The 32-panel pattern is generic; no maker's swirls |
| Basketball | Orange, black seams, pebbled grain | Grain as a fine normal-free texture |
| Baseball | White, red stitch curves | |
| Tennis Ball | Fluoro yellow-green, white seam | Same mesh UVs as the tier-1 tennis ball prop |
| Volleyball | Curved panels in white, yellow, teal | Not the blue-yellow of the best-known brand |
| Bowling Ball | Glossy swirl, three finger holes | Holes are texture, not geometry |
| Golf Ball | White dimples | Dimples as a texture pattern |
| Beach Ball | Six colour segments, white caps | |
| Eight-Ball | Black with a white 8 disc | |

### Material skins

Chrome (`Material.Foil`), Carbon Fibre, Holo Foil, Lava Lamp (Neon core), Galaxy, Ringed Planet (ring is a non-rotating child), Disco, Wireframe, Pixel (300-tri voxel mesh), Watermelon, **Golden** (not for sale: full Downtown book).

### Creature sets (skin + topper)

The player is the cute thing; nothing gets hurt. The fur goes on the skin, the face and ears on the upright topper.

| Set | Skin | Topper | The joke |
| --- | --- | --- | --- |
| Kitten Ball | Tabby stripes | Ears and a face that looks where you roll | Meows on tier-up instead of the fanfare (sound swap) |
| Pupper Ball | Shiba-coloured fur | Pointy ears, smug face, tongue out | A generic shiba, not the famous photo |
| Chonk Cat | Orange fur | Tiny ears on a huge round face | The topper squashes wider as you grow |
| Loaf | Bread crust | A cat sitting as a loaf on top | Cat loaf is a generic internet idea, drawn our way |
| Hamster Pilot | Frosted-shell lines (opaque) | A hamster in a tiny seat on top, steering | Hamster balls are see-through; ours fake it so there is no transparency cost |
| Frog Prince | Green speckles | Crown on a frog face | Any frog face must not look like the well-known meme frog |

### Meme-flavoured originals

Internet humour lands with 16+ players, but **meme images are almost all owned by someone**, and Roblox acts on takedown notices. The rule: **use the idea, never the image, the name or the music.**

Keep out entirely: Nyan Cat, Doge (the Kabosu photo), Grumpy Cat, Trollface, Pepe, "This Is Fine", Among Us crewmates, Skibidi Toilet, Rickroll, Crab Rave, Gigachad, Stonks' Meme Man, and any real person's face. Also nothing that mocks a group of people.

Safe originals that play on the same humour:

| Item | Slot | What it is |
| --- | --- | --- |
| Banana for Scale | Topper | A banana on top, in a game about size. Scales with you. |
| Side-Eye | Topper | A pair of eyes that side-eye the nearest other ball |
| Low Battery | Set | Battery-red skin; topper battery icon drains with the run timer |
| Signal Bars | Topper | Bars that fill with your tier: everyone can see how big you are |
| Loading… | Skin | A buffering ring that never finishes |
| 404 | Skin | Glitched, broken-pixel ball (numerals only, no words) |
| Number Go Up | Skin | Green arrow chart wrapping the ball |
| Hmm | Topper | A thinking face with a hand on its chin, drawn generic |

## Toppers (float above the ball)

A small model that hovers above the top of the ball, upright, never rolling, and scales with diameter, so it rides on top of the pile at every size. Toppers are the 16+ joke slot and carry every face.

Traffic Cone, Propeller Cap, Crown, Halo, Antenna with blinking tip, Tiny Rain Cloud, Googly Eyes, Party Hat, Chef Hat, Satellite Dish, plus the set and meme toppers above.

**Rules**: ≤ 300 tris, palette atlas only, bobs 0.2 × diameter at most, and Reduce motion stops the bob.

## Trails (the crazy part)

A `Trail` between two attachments on a non-rotating follower (the ball spins; the trail must not). `WidthScale` grows with diameter. Ground trails lie flat (attachments side by side, `FaceCamera` false); wall trails stand up (attachments one above the other).

### Inspired by (the reference is the look, never the name)

Players will get the reference; the item never names it or copies its logo, music or exact design.

| Trail | Inspired by | What it does |
| --- | --- | --- |
| Light Cycle | The '80s neon bike film | A solid glowing wall stands up behind you, 1 × diameter tall, fades in 3 s. Best in Night City. Never named after the film. |
| Rainbow Lane | Kart racing's rainbow track | Flat six-band ribbon on the ground. Not called "Rainbow Road". |
| Drift Sparks | Kart drifting | Sparks under the ball on turns: blue, then orange, then purple the longer you turn. Purely visual. |
| Twin Fire Tracks | The time-travel car | Two burning tyre lines that linger 1 s after a fast straight (cartoon flame, no smoke). |
| Hyperspace | Sci-fi jump to lightspeed | White streaks stretch behind you at top speed. |
| Code Rain | The green-code hacker film | Columns of green symbols fall behind you (random symbols, never words). |
| Snake | The old phone game | A pixel tail whose length is your stuck-object count. |
| Ink Splat | Paint-shooter games | Splats in your chosen accent on the ground. |
| Speed Lines | Anime and the fast blue hedgehog | Lines stream past the ball above half speed. |

### Original and crazy

| Trail | What it does |
| --- | --- |
| Caution Tape | Yellow-black tape unspools behind you. Very Downtown. |
| Toilet Paper | A roll unravels behind you. The 16+ favourite; fine for Minimal. |
| Endless Receipt | A shop receipt prints out behind you forever (pictograms, no text). |
| Red Carpet | Rolls out under you. VIP energy. |
| Duckling Parade | Five rubber ducks follow you in a line (5 pooled parts). |
| Domino Run | Dominoes stand up behind you and topple in sequence (client animation, no physics). |
| Banana Peels | Peels drop behind you. Cosmetic only: nobody slips. |
| Crop Circles | Flattened circle patterns appear on grass you cross. |
| Giant Footprints | Left, right, left: huge prints, as if something walked. |
| Lava Cracks | Glowing cracks in the road that cool and fade. |
| Tyre Skids, Comet, Piano Keys, Flower Bloom, Pixel Path, Bubble Wrap | As in the first draft. |

Pooled-part trails (Duckling Parade, Domino Run, Banana Peels, Footprints, Lava Cracks, Flower Bloom, Pixel Path) keep at most 20 pieces alive per ball, fading in 2 s, and never collide.

## Auras (around the ball)

`ParticleEmitter`s on attachments around the ball, scaled with diameter: Orbit Rings, Spark Field, Pixel Bits, Bubble Shield, Music Notes, Glitch, Static Crackle, Snow Swirl (winter), Petal Swirl (spring), Leaf Swirl (autumn).

## Pickup effects (every pop)

Replace the default pop burst: Confetti, Pixel Shatter, Star Pop, Comic Burst (shape only, no words), Spark Ring, Bubble Pop. They also change the pitch-rising pickup sound's timbre, never its volume.

## Unlocking (Constitution V)

| Route | Gives |
| --- | --- |
| Coins (earned by playing only) | Sports balls, most material skins, toppers, trails, auras |
| First time reaching a tier | The world's `sizeTiers[n].reward` (alternating trail and skin) |
| Completing a collection-book page | A topper per page; Golden skin for the full book |
| Robux | Creature sets, a few showcase trails, the season pack. Cosmetic only; price read from `MarketplaceService` |

Never: random boxes, rarity colours, countdowns, "limited" stock, pop-up offers during a run.

## Shop screen

- Tabs: **Skins, Toppers, Trails, Auras, Effects, Passes.** Shop is closed during a run (TopBar shows "after this run").
- Tiles on `ui-card`, `radius-panel`; a static icon, the name in `body`, a "what it does" line in `small`, the price button (● coins or Robux from `GetProductInfo`). Selected tile: 3 px `ui-highlight` ring. Owned: an "Equip" button in `ui-button`. Sets show both parts in one tile.
- The live preview is **one** ViewportFrame for the selected item (a spinning ball with the full loadout), never one per tile.

## Performance budget per ball

| | Own ball | Other players' balls |
| --- | --- | --- |
| Trails | 1 | 1, off beyond 150 studs |
| Particle emitters | 2, ≤ 30 particles alive | half rate, off beyond 150 studs |
| Pooled trail pieces | 20 | 10 |
| Reduce motion | Particles off, topper bob off; flat trails stay | same |

## Launch set (proposed)

- **Skins (10)**: Rubber, Football, Basketball, Tennis Ball, Baseball, Chrome, Galaxy, Disco, Pixel, Eight-Ball.
- **Sets (2)**: Kitten Ball, Pupper Ball.
- **Toppers (5)**: Traffic Cone, Crown, Googly Eyes, Banana for Scale, Signal Bars.
- **Trails (6)**: Rainbow Lane, Light Cycle, Drift Sparks, Caution Tape, Toilet Paper, Tyre Skids.
- **Auras (3)**: Orbit Rings, Spark Field, Pixel Bits.
- **Pickup effects (3)**: Confetti, Pixel Shatter, Comic Burst.
