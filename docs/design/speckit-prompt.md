# Spec Kit prompt: Downtown, Holiday City and the theme system

Paste the block below after `/speckit-specify`. It is built from this design system (see [README.md](README.md))
and written 2026-10-27; update it if the design changes before the spec is created. The "needs owner approval"
items are meant to come back in `/speckit-clarify`.

If the spec comes out too large, split it into two that ship in order: (1) the theme system and art pipeline
(patterns, atlas generator, budgets), then (2) Downtown content with Holiday City.

```text
Feature: Downtown, the first city level, launching in December as Holiday City, built on a swappable season-theme system and a stylised-real art style.

Source of truth for the design: the Rollossal design system artifact (https://claude.ai/artifact/MxTiuk6Fh1eud9PFLmJq9j), sections "World kit and seasons" (Patterns 1, 2, 2b, 3, 4, 5), "City asset list", "Default level: Downtown", "Launch theme: Holiday City", "Art style: how realistic" and "Roblox limits, safety and performance". The key decisions are restated here.

WHY
The game will most likely be ready around December 1, so the launch world must be a Christmas map. Long term, the first level is a city that is re-themed by season instead of a new map per season. One map keeps the small launch player base together in full 12-player servers, halves the pacing and balance work, and makes every later season (January Sunny City, spring, autumn, night) a data change. Launch players are age-checked 16+ during the trial, so props look like real city objects with one absurd twist each, festive but never cute or babyish.

WHAT
1. A new world, Downtown, as content data. It replaces Snow Village as the launch world; Snow Village stays in the code only as the Config rollback path, like GreyBoxRoom.
   - It reuses the current WorldDef shape, Layout.expand zones, fixed placements, spawn points, the hub and the 600 x 600 envelope (halfExtent 300, outer 400).
   - It has 12 doorstep spawns and about 1,400 placements in total, theme overlays included.
2. Five size tiers with the current minimum diameters 2 / 5 / 12 / 30 / 70 and absorb rule 0.4: Pocket, Sidewalk, Street, Block, Skyline. The core kit has 74 absorbable object types, including 2-3 hero props per tier.
   - Pocket: cans, water bottles, tennis balls, phones.
   - Sidewalk: cones, hydrants, e-scooters, bins.
   - Street: bikes, lamps, vending machines, young trees.
   - Block: cars, vans, buses, bus stops, small shops.
   - Skyline: buildings, a crane, a Ferris wheel, The Glass Tower.
   The core kit is season-neutral: every top face uses the shared "season" palette role.
3. Level layout in rings matching the tiers:
   - Stoops and alleys (spawns), then sidewalks, then the park, the construction site and the car park, then Market Street and the Plaza, then the Skyline Block and the Waterfront.
   - Each ring is gated by objects one tier up.
   - Narrow alleys and a storm drain are shortcuts only tier 1-2 balls fit through.
   - Hero props sit on sightlines, and every spawn can see a tier 5 landmark.
4. Pacing targets in a 4:00 run: first pickup by 0:05, tier 2 by about 0:30, tier 3 by about 1:30, tier 4 by about 2:45. 3 stars (80) means reaching tier 5. Checked by an agent-driven bot run within ±20 s, in every theme that ships.
5. A theme system that is data only (Constitution VII). A theme is:
   - a palette atlas with a fixed layout (the client swaps MeshPart.TextureID; stand-in parts take Part.Color from the same palette role)
   - a lighting block, a camera-attached weather emitter (max 40 particles, off with Reduce motion) and a music track
   - dressing slots: placements whose object depends on the theme (slot.small, slot.medium, slot.yard, slot.street, slot.landmark)
   - optional overlays: extra zones and fixed placements that only that theme adds. They count in the placement budget, never block ring gates, shortcuts or landmark sightlines, and must pass the same pacing check.
   - optional hero variants: a base hero mapped to an alternate mesh with the same tier, size (±10%), collision class and coins
   - its own collection-book page for theme-only objects. The page returns with the theme every year and is never "limited".
   The active theme is chosen by id in data. Switching is a content change, never code.
6. Themes in this feature:
   - winter / Holiday City (LAUNCH, full art):
     - The winter palette and golden-hour lighting (clockTime about 16.5), snowfall and a holiday music track (owner picks).
     - Slots: bauble, gift box, snowman, sleigh, and the Mega Tree as the Plaza landmark.
     - Overlays: a Christmas market of 6 stalls, a cocoa cart and a gift pile around the Mega Tree; garlands on Market Street; fairy-light bulbs, baubles and mini gifts at the doorsteps; a sledding slope and an ice rink in the park; snow piles and a snowplough at the edges.
     - Hero variants: the Cocoa Truck (for the Donut Food Truck) and the bow-wrapped Glass Tower.
     - The 20 holiday objects are listed in "Launch theme: Holiday City".
     - No elves, plush or cartoon Santa; the reindeer is a light-up wire decoration.
   - city / Sunny City (needed by January): palette, lighting and its slot dressing. It may ship with palette and lighting only if the dressing is late.
   - spring, autumn, toon, neon: palette and lighting tokens defined only; no art in this feature.
7. Stylised-real art style:
   - Real proportions, one bevel segment on silhouette edges, smooth shading on round parts.
   - One 1,024 px gradient atlas per theme, generated by script from the palette roles: 64 gradient cells on top, 8 trim strips below. One material per mesh.
   - RenderFidelity Automatic for LOD. No SurfaceAppearance/PBR, no transparency, no per-prop lights (glow is Material.Neon).
   - The Blender pipeline (export checks, UV rule, palette script) is updated to match.
8. Content rules:
   - No absorbable people or live animals; pigeons are ambient and fly off.
   - No weapons, alcohol-like bottles, gambling imagery, real brands or words on textures; pictograms only.
   - Every object name is a localisation key in English and Spanish.
9. The January switch:
   - Changing the active theme to city removes the overlays, hero variants and holiday slots and leaves the base map untouched.
   - The Holiday book page stays visible with progress kept, marked as returning next December.

NEEDS OWNER APPROVAL (must be resolved in /speckit-clarify before planning)
- Constitution XI amendment: allow smooth shading (it currently says "flat-shaded").
- Config.Budgets.meshTriangles: from 300/300/800/2500/2500 to the proposed 500/700/1500/3500/5000. Lock the numbers only after a measured capture on the reference phone at full density with 12 balls and the Holiday overlays.
- Whether the Snow Village cat and dog content is retired along with the rest of Snow Village (proposal: yes).
- The holiday music track.
- How the January switch is triggered: a data change in a release (proposal) or a date check in data. Neither may show a countdown to players (Constitution V).

OUT OF SCOPE
Ball skins, toppers, trails and the shop, including holiday cosmetics (shop feature). Co-op merge. The people playtest (backlog 004d). Art for spring, autumn, toon and neon. Store-page icon and thumbnails (launch kit feature).

SUCCESS
- Downtown loads with stand-in parts before any art exists, then with meshes.
- Holiday City and Sunny City both load from the same base layout, and switching between them is a data-only change.
- 30 fps on the reference phone at 640 x 360 with 12 balls in Holiday City (the heaviest theme).
- Active parts stay under Config.Budgets.maxActivePartsPerServer (2,000).
- The pacing targets are hit in bot runs in both shipped themes.
- Lune tests cover the content:
  - unique ids, sizes ascending by tier
  - every slot filled in every defined theme, every palette role present in every theme
  - overlays inside the placement budget and clear of gate, shortcut and sightline areas
  - every hero variant matches its base's tier, size (±10%), collision class and coins
```
