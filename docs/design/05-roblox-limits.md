# Roblox limits, safety and performance

The checklist every new prop, cosmetic or level passes before it goes into a world's data.

## Audience and rating

- The launch build is open to **age-checked 16+ players only** until the trial unlocks under-16 access. Design for them first (spectacle, deadpan humour, cool cosmetics), but **keep every asset Minimal-safe**. The same build has to pass for ages 9–15 later without a reskin.
- Constitution IV rules out: blood, gore, weapons, romance, alcohol, strong language, gambling imagery, free-form drawing, hangout-centred spaces. Any prop that could change a questionnaire answer needs the owner's approval first.

## Living beings: none absorbable

**Recommendation: never let the ball absorb people or real animals.** The rating would probably survive cartoon animals, but a parent watching "the ball swallowed the dog" reads it as harm, and Roblox review sees screenshots without context. Keep the joke with stand-ins instead:

| Instead of | Use |
| --- | --- |
| A pedestrian | Nothing. The city is empty of people, like early morning. (Also no NPC cost.) |
| A cat or dog | A dog statue, an inflatable dog balloon, a cat-shaped bin |
| Birds | Ambient pigeons that flap off when a ball gets close (never absorbed, ≤ 8 per district) |
| A horse | A carousel horse on the Waterfront ride |

Inanimate things with faces (the rubber duck, a mascot statue) are fine. Avoid googly-eyed food that seems to suffer.

## Moderation-safe modelling

- Bottles are clearly **water or soda**: a screw cap and a colour band, no long glass neck, no labels with words.
- Nothing shaped like a weapon (no swords, bats with spikes, toy guns, knives in the kitchen props), syringe, pill, cigarette, vape or lighter.
- No real logos, brands, mascots, flags, landmarks or trademarked shapes (generic puzzle cube, generic controller).
- No words on textures (localisation and moderation both); pictograms only.
- Vehicles are never shown crashed, burning or upside down.

## Engine budgets (from `src/shared/Config.luau`)

| Budget | Value | What it means for art |
| --- | --- | --- |
| Active parts per server | 2,000 | About 1,400 placements per level, ground included |
| Triangles per mesh by tier | 300 / 300 / 800 / 2,500 / 2,500 today; 500 / 700 / 1,500 / 3,500 / 5,000 proposed for stylised real | Silhouette first, one bevel segment, no hidden faces; `RenderFidelity` Automatic for LOD |
| Visible stuck objects per ball | 30 (of 120 tracked) | Older pickups are "buried" and removed |
| Touch targets | 96 px main, 64 px utility | Shop tiles too |
| Text | 18 px minimum | All screens, all locales |
| Frame rate | 30 fps on the mid-range reference phone | Checked in a Studio capture at 640 × 360 |

## Keep it cheap

- **One texture.** All world props share the 1,024 px gradient atlas; a theme is another atlas with the same layout. No SurfaceAppearance/PBR, no per-prop textures, no decals with words. Realism comes from proportions, bevels and baked gradient shading, not texture maps.
- **One MeshPart per absorbable prop**, one asset id per type. 40 cones = one mesh in memory. No multi-part models, no Unions (CSG) on anything absorbable.
- **Default Parts for ground**: roads, pavements, kerbs, lawns are `Part`s with `SmoothPlastic` and a `w-*` colour. Use Roblox built-in materials only where they cost nothing extra (`Neon` for glow, `Foil` for chrome skins). Terrain is not used: it does not recolour by theme.
- **Opaque everything.** Water and glass are opaque swatches; transparency costs overdraw on phones.
- **No lights per prop.** Glow is `Material.Neon`. A theme may add up to 8 `PointLight`s for the whole map (night Plaza), never one per lamp.
- **Motion is client-side and rare.** Spinning chair, turning donut, swaying Tube Guy, the Ferris Wheel: a client `RenderStepped` tween on a child part, only within 200 studs of the camera. No server-replicated animation.
- **Collisions.** `CollisionFidelity = Box` for tier 1–3 props, `Hull` for tier 4–5; never `PreciseConvexDecomposition`. Stuck objects have `CanCollide` off and are massless.
- **Streaming on** (`StreamingEnabled`), fog from about 150 studs, the far skyline is one non-colliding mesh behind the fog.
- **Culling.** Objects two tiers below the player are hidden client-side (`cullTierDelta`). Design levels so that's a feature: the city really does empty out.
- **Creator Store meshes** may be used only mesh-only, inspected for scripts, re-UV'd onto the palette (Constitution XI). In practice it is faster to model the low-poly prop in Blender with the existing pipeline.

## Before a prop ships

1. It reads at tier size in a 640 × 360 capture.
2. It uses 2–4 `w-*` roles and one accent, plus `w-season` if it has a top face.
3. It looks right in all six themes (render the palette QA grid per theme).
4. It's under its tier's triangle budget, one material, one MeshPart.
5. It passes the "not in the kit" list in *City asset list*.
6. Its name is a localisation key in English and Spanish.
