# TrailAura

Trails drawn behind the ball and auras around it: the cosmetics that stay visible once stuck objects cover the skin.

- **Consumer provides**: the trail or aura id, its colours (palette roles where it should follow the theme, fixed colours where they are the item's identity, like Rainbow Lane), and its cost class (Trail, ParticleEmitter, or pooled parts).
- **Use it** in the shop preview and the cosmetics brief.
- **Do** take the look of a reference (a neon light wall, kart drift sparks) and give it your own name; attach trails to a non-rotating follower and scale `WidthScale` with diameter; keep to one trail and two emitters per ball.
- **Don't** name the film, game or brand it references, copy its logo or music, or let a trail change gameplay (Banana Peels make nobody slip). No more than 20 pooled pieces per ball; Reduce motion turns every particle off.
