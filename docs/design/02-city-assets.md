# City asset list

The proposed Downtown catalogue: **74 absorbable objects in 5 tiers**, plus non-absorbable scenery. Sizes are the longest side in studs (`ObjectDef.size`). An object is absorbed when `size ≤ 0.4 × ball diameter` (`Config.absorbRatio`), so it needs a ball of `size ÷ 0.4`. Triangle budgets today follow `Config.Budgets.meshTriangles` (300 / 300 / 800 / 2,500 / 2,500); the stylised-real look proposes 500 / 700 / 1,500 / 3,500 / 5,000 (*Art style: how realistic*). Model every object in real-world proportions; the Twist column is the one thing exaggerated.

**Kit column**: **Core** is reused by every city level and theme; **★ Hero** is a showpiece built to grab attention (oversized feature, motion, glow or a sight gag); **Slot** is filled per theme (*World kit and seasons*, Pattern 2).

**What makes a hero.** At least two of: a silhouette you can read from 50 studs away; one big `w-accent-*` area; something that moves or lights up (`w-glow` with Neon, a spin, a sway); a sight gag a 17-year-old would clip ("the ball ate the vending machine and it's still dispensing"). Plan 2–3 heroes per tier, placed on sightlines (*Default level: Downtown*).

## Tier 1, Pocket (ball 2–5 studs; objects 0.3–1.5)

A ball about a football's size next to an avatar's foot. Litter-scale city stuff, dense around every spawn.

| Object | Size | Swatches | Twist | Kit |
| --- | --- | --- | --- | --- |
| Bottle cap | 0.3 | `w-metal`, `w-accent-red` | Crimped edge, reads as a coin-sized star | Core |
| AA battery | 0.4 | `w-accent-yellow`, `w-metal` | Chunky + terminal | Core |
| Earbud case | 0.5 | `w-white` | Lid slightly open | Core |
| Puzzle cube | 0.5 | `w-accent-red`, `-blue`, `-yellow` | Half-solved, generic (not the trademarked one) | Core |
| Soda can | 0.6 | `w-accent-red`, `w-metal` | One upright, one crushed variant (same mesh, scaled) | Core |
| Tennis ball | 0.6 | `w-accent-yellow`, `w-white` | Fuzz seam as a raised band | Core |
| To-go coffee cup | 0.7 | `w-white`, `w-wood` | Sleeve and lid; steam is not modelled | Core |
| Donut | 0.8 | `w-accent-pink`, `w-wood` | Sprinkles in 3 accents | Core |
| Smartphone | 0.8 | `w-rubber`, `w-glass` | Screen face in `w-glow`, a cracked corner | Core |
| Water bottle | 0.9 | `w-glass`, `w-accent-blue` | Clearly water: blue cap and label band, no glass-bottle neck | Core |
| Pizza slice | 0.9 | `w-sand`, `w-accent-red` | Cheese drip hanging off the tip | Core |
| Game controller | 0.9 | `w-rubber`, `w-accent-teal` | Generic shape, no brand layout | Core |
| Headphones | 1.0 | `w-rubber`, `w-accent-teal` | Oversized cups | Core |
| Basketball | 1.0 | `w-accent-orange`, `w-rubber` | Seam lines as grooves | Core |
| Takeout box | 1.2 | `w-white`, `w-accent-red` | Chopsticks sticking out | Core |
| ★ Rubber Duck in Sunglasses | 1.2 | `w-accent-yellow`, `w-rubber` | Faces the spawn; the daily golden object candidate | Hero |
| ★ The Lost Sneaker | 1.3 | `w-white`, `w-accent-red` | One per spawn porch, laces trailing. Where's the other one? It's in tier 3, on a lamp post. | Hero |
| Computer keyboard | 1.5 | `w-rubber`, `w-white` | One missing key | Core |
| *Slot: small* | 0.6–1.2 | theme | Ice lolly / bauble / egg / pumpkin / glow stick | Slot |

## Tier 2, Sidewalk (ball 5–12; objects 1.6–4)

The pavement itself: things people step around.

| Object | Size | Swatches | Twist | Kit |
| --- | --- | --- | --- | --- |
| Boombox speaker | 2.0 | `w-rubber`, `w-accent-teal` | Cone faces pulse with `w-glow` on tier 4+ balls only (cheap) | Core |
| Traffic cone | 2.0 | `w-accent-orange`, `w-white` | Always slightly too many of them | Core |
| Skateboard | 2.2 | `w-wood`, `w-rubber` | Wheels `w-accent-yellow` | Core |
| Fire hydrant | 2.4 | `w-accent-red`, `w-metal` | Big side caps, chunky bolts | Core |
| Suitcase | 2.6 | `w-accent-blue`, `w-rubber` | Pull handle up, stickers in pictograms | Core |
| Acoustic guitar | 3.0 | `w-wood`, `w-bark` | Leaning on a wall, case open | Core |
| Newspaper box | 3.0 | `w-accent-blue`, `w-glass` | Pictogram front, no text | Core |
| ★ Inflatable Flamingo | 3.0 | `w-accent-pink`, `w-white` | Pool float on dry land, far from any pool | Hero |
| Potted palm | 3.2 | `w-leaf`, `w-wall-b` | Pot in a facade role so it matches its shop | Core |
| ★ Spinning Office Chair | 3.4 | `w-rubber`, `w-accent-teal` | Rotates slowly on its own (client tween, 1 axis) | Hero |
| Wheelie bin | 3.5 | `w-metal-dark`, `w-accent-blue` | Lid ajar; recycling variant in `w-accent-teal` | Core |
| Shopping cart | 3.6 | `w-metal`, `w-accent-red` | One wheel turned sideways | Core |
| E-scooter | 3.8 | `w-accent-blue`, `w-rubber` | Lying on its side, as they do | Core |
| Parking meter | 3.8 | `w-metal-dark`, `w-glass` | Screen in `w-glow` | Core |
| ★ Pizza Box Tower | 3.9 | `w-white`, `w-bark` | 12 boxes, leaning dangerously | Hero |
| *Slot: medium* | 1.8–3.5 | theme | Beach ball / gift box / flower crate / hay bale / speaker cube | Slot |

## Tier 3, Street (ball 12–30; objects 4–10)

Street furniture and the first things with wheels. The camera pulls back here and the sidewalk starts to look small.

| Object | Size | Swatches | Twist | Kit |
| --- | --- | --- | --- | --- |
| Mailbox | 4.5 | `w-accent-blue`, `w-metal-dark` | Rounded top, pictogram envelope | Core |
| Satellite dish | 5.0 | `w-white`, `w-metal` | Points at the sky, slightly wrong | Core |
| Drum kit | 5.0 | `w-accent-red`, `w-metal` | Set up on the pavement for a busker | Core |
| Pallet stack | 5.0 | `w-wood`, `w-bark` | Crates of fruit on top in 3 accents | Core |
| Picnic table | 6.0 | `w-wood` | Benches attached | Core |
| Recycling bank | 6.0 | `w-accent-teal`, `w-metal-dark` | Three round holes | Core |
| Moped | 6.0 | `w-accent-orange`, `w-rubber` | Delivery box on the back | Core |
| Bicycle | 6.5 | `w-accent-red`, `w-rubber` | Basket on the front | Core |
| ★ Arcade Cabinet | 6.5 | `w-accent-teal`, `w-rubber` | Screen and buttons in `w-glow`, game is a ball eating a city | Hero |
| Bench | 7.0 | `w-wood`, `w-metal-dark` | A folded newspaper left on the seat | Core |
| ★ Vending Machine | 7.0 | `w-accent-red`, `w-glass` | Lit front; when knocked it drops 3 soda cans (tier 1, re-collectable) | Hero |
| Hot-dog cart | 7.5 | `w-accent-yellow`, `w-accent-red` | Umbrella, oversized sausage on top | Core |
| Street tree (young) | 9.0 | `w-leaf`, `w-leaf-dark`, `w-bark` | Canopy top in `w-season` | Core |
| ★ Inflatable Tube Guy | 9.0 | `w-accent-red`, `w-accent-yellow` | The car-dealer air dancer. Sways in 3 segments (client CFrame tween), visible from blocks away | Hero |
| Street lamp | 9.5 | `w-metal-dark`, `w-glow` | The other Lost Sneaker hangs from it by the laces | Core |
| Traffic light | 9.8 | `w-metal-dark`, `w-accent-red`/`yellow`/`teal` | Lamps are shape-coded (circle, triangle, square) as well as colour | Core |
| *Slot: yard* | 6–9 | theme | Paddling pool / snowman / blossom tree / scarecrow / neon arrow | Slot |

## Tier 4, Block (ball 30–70; objects 10–25)

Vehicles, stops and small shops. "My ball ate a bus" lives here.

| Object | Size | Swatches | Twist | Kit |
| --- | --- | --- | --- | --- |
| Bus shelter | 10 | `w-glass`, `w-metal-dark` | Ad panel shows a ball pictogram | Core |
| Kiosk | 12 | `w-wall-c`, `w-accent-yellow` | Awning in `w-roof-a` stripes | Core |
| Fountain | 13 | `w-kerb`, `w-water` | Jet as a solid low-poly column | Core |
| Hatchback | 14 | `w-accent-blue` / `-red` / `w-white` | 3 colour variants by role, one mesh each role set | Core |
| Taxi | 14 | `w-accent-yellow`, `w-rubber` | Roof sign is a pictogram | Core |
| Pickup truck | 16 | `w-accent-orange`, `w-rubber` | Bed full of traffic cones | Core |
| Delivery van | 17 | `w-white`, `w-accent-teal` | Rear doors open, boxes spilling | Core |
| ★ Donut Food Truck | 18 | `w-accent-pink`, `w-white` | A 6-stud donut on the roof, slowly turning | Hero |
| Billboard | 18 | `w-metal-dark`, `w-trim` | Image in pictograms; theme swaps the panel role | Core |
| ★ Monster Truck | 18 | `w-accent-teal`, `w-rubber` | Wheels as tall as a car | Hero |
| Shipping container | 20 | `w-accent-red` / `-blue` | Corrugated sides as 6 flat ridges | Core |
| Big street tree | 20 | `w-leaf`, `w-leaf-dark`, `w-bark` | `w-season` canopy top | Core |
| Garbage truck | 20 | `w-accent-teal`, `w-metal-dark` | Arm lifting a wheelie bin | Core |
| Corner bakery | 22 | `w-wall-b`, `w-roof-a`, `w-glass` | Small shop, donut pictogram sign | Core |
| Fire engine | 24 | `w-accent-red`, `w-metal` | Ladder raised a little | Core |
| City bus | 25 | `w-accent-red`, `w-glass` | Bendy-bus accordion joint | Core |
| *Slot: street* | 15–20 | theme | Ice-cream truck / sleigh / parade float / pumpkin cart / lit food truck | Slot |

## Tier 5, Skyline (ball 70–150; objects 25–60)

Buildings and landmarks. Reaching this tier in one run should be possible but rare: that is the clip.

| Object | Size | Swatches | Twist | Kit |
| --- | --- | --- | --- | --- |
| Corner shop row (×3 variants) | 26 | `w-wall-a`/`b`/`c`, `w-glass` | Modules from Pattern 4; rooftop extras vary | Core |
| Townhouse | 30 | `w-wall-a`, `w-roof-a` | Roof garden in `w-season` | Core |
| EV charging station | 32 | `w-white`, `w-accent-teal` | Canopy with `w-glow` underside | Core |
| ★ Rocket Water Tower | 34 | `w-metal`, `w-accent-red` | A water tower painted as a rocket. Fins. | Hero |
| Cinema | 36 | `w-wall-c`, `w-glow` | Marquee bulbs in Neon, pictogram popcorn | Core |
| Apartment block | 40 | `w-wall-a`, `w-glass` | 5 storeys of modules, balconies with tiny props baked in | Core |
| ★ Ferris Wheel | 50 | `w-metal`, 4 accents | Turns slowly (one rotating child); the skyline's marker from every spawn | Hero |
| ★ Tower Crane | 55 | `w-accent-yellow`, `w-metal-dark` | Jib swings slowly, a shipping container hangs off it | Hero |
| ★ The Glass Tower | 60 | `w-glass`, `w-metal` | The finale: helipad on top, the Giant Inflatable Duck tethered to it | Hero |
| *Slot: landmark* | 25–45 | theme | Giant Inflatable Duck / Mega Tree / Hot-Air Balloon / Giant Pumpkin / DJ Stage | Slot |

## Not absorbable (scenery)

Roads, pavements, plazas and lawns (Parts), the river wall, the motorway flyover around the edge, the far skyline (one merged mesh, no collisions, behind the fog), invisible boundary walls.

## Not in the kit, on purpose

- **People and live animals.** No pedestrians, no absorbable pets. Pigeons appear as ambient birds that flutter off when a ball comes near (never absorbed). See *Roblox limits, safety and performance*.
- **Anything that reads as a weapon, alcohol, tobacco, vape, medicine or drug.** Bottles are water or soda only, with a cap and colour band.
- **Gambling imagery**: slot machines, claw machines, scratch cards, dice, casino chips, ATMs stacked with cash.
- **Police cars with weapons, ambulances with injuries, crashed or burning vehicles.**
- **Real brands, logos, mascots and recognisable products.**
- **Babyish props** (nursery sweets, plush toys, pastel baby things) in the core kit. A toy is fine as a sight gag (the duck), not as a category.
