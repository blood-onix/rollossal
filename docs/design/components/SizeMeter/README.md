# SizeMeter

The HUD's top-left size meter and top-centre timer (`Hud.luau`): the diameter as a big number, a bar to the next tier and the next tier's name, over the 3D world.

- **Consumer provides**: the current diameter, the progress fraction (`Tiers.progress`), the next tier's headline key, the remaining time and the star thresholds.
- **Use it** only during a run, `space-2` from the top-left edge (160 × 104) and top centre (170 × 44).
- **Do** keep every label stroked with `ui-stroke`; it has no panel behind it and must read on every theme's sky and street.
- **Don't** colour-code the stars alone: reached stars are ★ and unreached ☆, with the size beside each.
