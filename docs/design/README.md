# Rollossal design system

Exported from the [Rollossal design system artifact](https://claude.ai/artifact/MxTiuk6Fh1eud9PFLmJq9j) on 2026-10-27. This folder is the repo copy
that every agent can read; edit here or in the artifact and keep the two in step.

**Status: proposal.** Where it differs from the [game design brief](../rollossal-gdd.md) (the launch world is
Downtown in its Holiday City theme instead of Snow Village, and the art style is stylised real), this folder is
the newer intent, but these points need the owner's approval before a spec relies on them:

- a Constitution XI amendment for the stylised-real look (gradient atlas, one bevel segment);
- the per-tier triangle budgets in `Config.Budgets.meshTriangles` (500 / 700 / 1,500 / 3,500 / 5,000 proposed);
- retiring Snow Village as the launch world;
- the holiday music track;
- how the January switch from Holiday City to Sunny City is triggered.

## Contents

- [World kit and seasons](01-world-kit.md)
- [City asset list](02-city-assets.md)
- [Default level: Downtown](03-city-level.md)
- [Player cosmetics and shop](04-player-cosmetics.md)
- [Roblox limits, safety and performance](05-roblox-limits.md)
- [Art style: how realistic](06-art-style.md)
- [Launch theme: Holiday City](07-holiday-city.md)
- [Tokens](tokens.md): every colour per theme, type, spacing, radius and touch sizes ([tokens.json](tokens.json), [tokens.css](tokens.css)). Regenerate the CSS and tables with `python3 scripts/design-tokens.py` after editing the JSON.
- [components/](components): one folder per preview, each with a `README.md` and a static `preview.html`.
- [Spec Kit prompt](speckit-prompt.md): the `/speckit-specify` input for Downtown, Holiday City and the theme system.
- [Constitution prompt](constitution-prompt.md): the `/speckit-constitution` input that amended the constitution to 2.0.0 for this design system.
- [index.html](index.html): all previews on one page with a theme switch. Open it in a browser straight from disk.

Previews take the theme from the URL, for example `components/CityMap/preview.html?theme=winter`.

## Brand book

Rollossal is a rolling-ball growth game for Roblox: start small, stick to everything smaller than you, and finish a 4-minute run big enough to eat the city. This system covers three layers. Use each for its own job:

1. **World kit**: the `w-*` swatches, `light-*` lighting and the city props. Every theme (`city`, `winter`, `spring`, `autumn`, `toon`, `neon`) recolours the same meshes. See *World kit and seasons*, *City asset list*, *Default level: Downtown* and *Art style: how realistic*.
2. **Player cosmetics**: ball skins, auras, trails and pickup effects. See *Player cosmetics and shop*.
3. **UI**: the `ui-*` tokens, type styles and touch targets taken from `src/client/UiKit.luau`. They are the same in every theme.

*Roblox limits, safety and performance* covers the rules every asset must pass.

### Who it is for

- **First audience: age-checked 16+ players** during the trial (the first 250 engaged players unlock under-16 access). They need spectacle, absurd humour, a score worth chasing and cosmetics that look cool rather than cute.
- **Then 10–15.** Nothing is cruel or crude, so the same build works for them without a reskin.
- **The rule: never babyish.** Props are real city things (e-scooters, vending machines, food trucks, cranes) with one absurd twist each. No nursery sweets, plush toys or pastel baby props in the core kit. The joke is scale: "my ball just ate a bus."

### Content fundamentals (voice)

- **Short, loud, physical.** Banners are caps and 2–5 words: `YOU CAN ROLL UP: BUSES`, `TIME'S UP!`. Pickups are `+ Traffic Cone`. Set banners in `banner`, pickups in `body`.
- **Brag, don't nag.** Results lead with the number (`34.6`), then stars, then what is new. No "Don't give up!", no exclamation spam: one `!` per screen at most.
- **Deadpan object names.** Name props like a shop label, not a joke: "Inflatable Tube Guy", "Office Chair (Spinning)", "Suspiciously Large Donut". The twist is in the model; the name stays plain.
- **Second person, no slang that dates.** "You", never "we". No memes, real brands or creator names.
- **Every string is a localisation key** (`object.city.traffic_cone`). Never put words on textures: signs use pictograms (see Iconography), so English and Spanish ship the same meshes.
- **Status is never colour alone** (Constitution VI): every tier chip shows its number, every toggle its label.

### Visual foundations

**The look: stylised real.** Real city objects in real proportions, simplified into clean low-poly forms with bevelled edges, smooth round parts and gradient shading, all on one shared texture (see *Art style: how realistic*). Exaggerate only the one hero feature, and by at most 10 %. Big clean colour areas read at phone size; texture detail does not. It should look like a real city that a giant ball is eating, not a toy town.

**Colour, world.** Every mesh face UVs into exactly one cell of the shared gradient atlas (1,024 px: 8 × 8 palette cells on top, trim strips below). The cells are the `w-*` tokens: rows 0–3 hold the 32 shared roles (ground, buildings, materials, accents), rows 4–7 stay free for level-specific heroes. A theme is a different atlas with the same layout, so **one asset set gives six cities**. Rules:
- Model with roles, not colours: paint a hydrant `w-accent-red`, not "red". In `neon` it becomes hot pink-red; in `winter` holiday red.
- Keep any one prop to 2–4 swatches and give each one hero accent (`w-accent-*`). The accents are where the eye goes; the city around them (`w-wall-*`, `w-sidewalk`, `w-asphalt`) stays quiet.
- Put the seasonal face on every roof top, hedge top, car roof and lamp head with `w-season`. That one cell is the snow cap in `winter`, blossom in `spring`, leaf piles in `autumn` and neon strips in `neon`, so the theme changes with no new geometry.
- Light faces (`w-glow`) use `Material.Neon` on a separate MeshPart child only on tier 4–5 hero props; never a PointLight per prop.
- `w-water` and `w-glass` are opaque. Transparency costs overdraw on phones.

**Colour, UI.** Panels `ui-panel`, cards and shop tiles `ui-card`, primary buttons `ui-button`, unselected options `ui-off`. All text is `ui-text` with a 2 px `ui-stroke` outline (`stroke-text`), so it also reads over the 3D world. `ui-highlight` marks the selected shop tile and the coin glyph only. Tier chips use `tier-1`…`tier-5` beside the tier number.

**Lighting.** Each theme sets `light-sky`, `light-fog` and `light-ambient` in its `WorldDef.lighting`. Fog starts around 150 studs and ends around 900, which also hides streaming pop-in.

**Type.** Headings in Roblox's built-in `Enum.Font.FredokaOne` (`title` 36, `meter` 32, `banner` 28; buttons use `banner`). Body in `Enum.Font.GothamMedium` (`body` 20, `small` 18). On the web these previews stand in with Fredoka and Montserrat. **Nothing under 18 px** (`Config.minTextSize`); text scales with `UIScale` from a 720 px short side.

**Shape, radius, spacing.** Buttons `radius-button`, panels `radius-panel`, sliders, the Jump button and ball swatches `radius-round`. HUD sits `space-2` from the screen edge; buttons and columns are `space-3` apart; Jump is `space-6` in from the bottom-right corner.

**Touch.** Jump, Merge and Roll again are at least `touch-main` (96 px); TopBar icons and close at least `touch-utility` (64 px). One thumb plays the whole game.

**Motion.** Pickups pop (scale 1 → 1.15 → 1 over `Config.growTime` 0.25 s), the tier banner holds 2.5 s, and the camera pulls back with the ball's size. Shake only on knock-off, and **Reduce motion** removes it and every cosmetic particle burst.

### Iconography

- UI icons are glyphs from `src/shared/Content/Icons.luau` until real icon assets exist (★ ⏱ ● ■ ▤ ⌂ ▶ ⚙ 🛒 🔒). Check every new glyph in a capture with both FredokaOne and GothamMedium: a glyph missing from FredokaOne renders blank, one missing from GothamMedium renders as a box.
- **In-world signs are pictograms, never words**: a donut on the bakery, a bus on the stop, a wrench on the garage, an arrow on one-way streets. Model them as 1–2 swatch shapes on a `w-trim` board.
- No real logos, brands, flags or national symbols, and nothing that imitates them.

### Building on it

- A new level reuses the **core kit** (about 70 % of placements), adds 8–12 **hero props**, and picks a theme palette. Add new colours in palette rows 4–7, never by editing a row 0–3 role.
- A new season is one palette atlas, one `lighting` block, a weather effect and 6–10 **dressing props** that fill the `slot.*` placements (see *World kit and seasons*). An event season can add **overlays** and **hero variants** on top. No code change, per Constitution VII.
- Downtown launches in December as **Holiday City** (*Launch theme: Holiday City*) and switches to Sunny City in January.
