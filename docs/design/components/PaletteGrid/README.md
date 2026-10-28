# PaletteGrid

The 32 shared palette roles (rows 0–3 of the 8 × 8 `art/palette.png`) and the three lighting colours for the current theme.

- **Consumer provides**: nothing; it reads the `w-*` and `light-*` tokens. In the game these are the top half of the 1,024 px gradient atlas, one atlas per theme, each cell 128 × 64 px shading from light (top) to dark (bottom).
- **Use it** to pick a role while modelling: paint faces by role (`w-accent-red`), never by hex.
- **Do** fill all 64 cells in every theme's texture; rows 4–7 belong to the level's heroes.
- **Don't** repurpose a row 0–3 cell for a colour that happens to match; add the new colour in rows 4–7.
