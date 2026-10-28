# Tokens

Generated from [tokens.json](tokens.json) by `scripts/design-tokens.py`; `tokens.css` holds the same values as CSS variables.

## Colour

World tokens (`w-*`, `light-*`) change per theme; UI and tier tokens are the same in every theme.

| Token | `city` Sunny City | `winter` Holiday City | `spring` Blossom City | `autumn` Harvest City | `toon` Toon City | `neon` Night City | Usage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `w-asphalt` | `#4a4f5c` | `#565c6b` | `#5b5f6b` | `#4b4c55` | `#3b3f73` | `#1c1e2b` | Roads, car-park floors, tyre rubber on big vehicles. Palette row 0. |
| `w-road-line` | `#f2d64b` | `#e8eef6` | `#fff1a8` | `#f0c048` | `#ffffff` | `#ffd23f` | Lane dashes, zebra crossings, parking bays. |
| `w-sidewalk` | `#c9c4bb` | `#e8eef6` | `#e3ddd2` | `#c4b8a5` | `#ffd6e8` | `#2e3142` | Pavement slabs, plaza floor, stoops. |
| `w-kerb` | `#9a958e` | `#b9c3d1` | `#b7b0a6` | `#94897a` | `#ff9ec9` | `#474b61` | Kerb edges, steps, planter rims, statue plinths. |
| `w-grass` | `#6fbf4a` | `#eef3fa` | `#8ed866` | `#a7a24a` | `#4be36a` | `#1f4a3a` | Park lawns, verges, roof gardens. |
| `w-soil` | `#8a6544` | `#c9d3e0` | `#9a7452` | `#7a5233` | `#c27a3a` | `#2b2230` | Planter beds, dirt paths, the construction site. |
| `w-water` | `#3fa7d6` | `#b7d9ef` | `#6cc7e6` | `#4f8fa8` | `#29c4ff` | `#12384f` | Fountain and pond water, swimming pool, canal. Opaque on purpose (mobile overdraw). |
| `w-sand` | `#e6cf96` | `#e3e9f2` | `#f0dfae` | `#d9b97a` | `#ffe36b` | `#4a4255` | Playground pit, beach-volley court, building site. |
| `w-wall-a` | `#e9e1d3` | `#efe6d8` | `#fbeee4` | `#ecdcc4` | `#fff36b` | `#3a3c52` | Main facade colour (cream plaster). Most buildings. |
| `w-wall-b` | `#d9735b` | `#b8473f` | `#f3a8a0` | `#b5563a` | `#ff5e9c` | `#4a2f4f` | Second facade (terracotta brick). Alternate every other shop. |
| `w-wall-c` | `#6f9fc9` | `#3f6f5a` | `#a8d3c4` | `#5f7a5a` | `#5ec8ff` | `#23415a` | Third facade (painted blue/green). Corner buildings and kiosks. |
| `w-roof-a` | `#a8443a` | `#f7faff` | `#e07a8a` | `#7a3b2a` | `#ff3b3b` | `#262838` | Pitched roofs, awnings stripe 1. Winter turns it to snow. |
| `w-roof-b` | `#3d4a5c` | `#dfe8f3` | `#6f8fb3` | `#3f3f4a` | `#7b5cff` | `#1b1d29` | Flat roofs, bus and truck roofs, dark awnings. |
| `w-glass` | `#a9d8ef` | `#ffd98a` | `#c4e9f5` | `#ffd08a` | `#b8f1ff` | `#ffd36b` | Windows, windscreens, phone screens. Night and Holiday light them warm. |
| `w-trim` | `#f5f2ea` | `#f7faff` | `#ffffff` | `#efe5d3` | `#ffffff` | `#5b5f7a` | Window frames, door frames, cornices, sign borders. |
| `w-door` | `#5b3a2a` | `#7a2f2a` | `#7a5ba8` | `#4a2e22` | `#ff8a00` | `#ff3fa4` | Doors, shutters, bench slats on dark props. |
| `w-metal` | `#b8bec7` | `#c4ccd6` | `#c3c8d0` | `#aeb2b8` | `#d6dcff` | `#7a8099` | Poles, railings, rims, vending machine body, cans. |
| `w-metal-dark` | `#5d6470` | `#4d5563` | `#6a7180` | `#555a63` | `#5a5fa8` | `#383c4f` | Lamp posts, bin bodies, machinery, scaffolding. |
| `w-rubber` | `#26282d` | `#26282d` | `#2d2f35` | `#26272b` | `#1d1d3a` | `#111219` | Tyres, skateboard grip, cables, keyboard keys. |
| `w-wood` | `#a8754a` | `#8f5f3c` | `#b98a5c` | `#9a6a40` | `#ff9f4a` | `#5a4440` | Benches, crates, pallets, market stalls, guitar body. |
| `w-leaf` | `#4fa83d` | `#2e6b4a` | `#7ccd57` | `#e07b2b` | `#2fe05a` | `#1f6b4f` | Tree canopy (light face), hedges, potted plants. |
| `w-leaf-dark` | `#2f7a34` | `#1f4d36` | `#4c9b45` | `#b8452a` | `#12a84a` | `#114433` | Tree canopy (shadow face), topiary, ivy. |
| `w-bark` | `#6b4a33` | `#5a3d2b` | `#7a5640` | `#5e4330` | `#b05a2a` | `#3a2c2a` | Trunks, wooden poles, cardboard. |
| `w-white` | `#f7f7f4` | `#ffffff` | `#fffdf8` | `#f6f1e7` | `#ffffff` | `#d8dcf0` | Pure highlights: sneakers, fridge, ice cream, porcelain, road signs. |
| `w-accent-red` | `#e8483f` | `#d93a3a` | `#f2626b` | `#c8432f` | `#ff2e4d` | `#ff3b5c` | Hero accent 1: fire hydrant, buses, taxis' trim, the giant tube man. |
| `w-accent-yellow` | `#ffc93c` | `#ffd25a` | `#ffe06b` | `#f2b632` | `#ffe600` | `#ffe04a` | Hero accent 2: taxi body, traffic cone band, crane, rubber duck. |
| `w-accent-blue` | `#2f7de1` | `#6fb6ff` | `#7fb4ff` | `#4f7fb8` | `#2e7bff` | `#3fa9ff` | Hero accent 3: e-scooters, mailboxes, utility vans, recycling bins. |
| `w-accent-pink` | `#ff6fa8` | `#f2a0b6` | `#ff9cc7` | `#d9788a` | `#ff4fc3` | `#ff3fd0` | Hero accent 4: donut icing, flamingo, food-truck wraps. |
| `w-accent-orange` | `#ff8a2b` | `#ff9a3d` | `#ffb36b` | `#f07a1f` | `#ff7a00` | `#ff8a3d` | Hero accent 5: traffic cones, construction kit, basketballs. |
| `w-accent-teal` | `#1fb5a6` | `#2f8f6a` | `#5fd1bd` | `#3f8f7f` | `#00e0c0` | `#19ffd1` | Hero accent 6: arcade cabinets, gaming chairs, shop signs. |
| `w-glow` | `#fff3b0` | `#ffe8a3` | `#fff7cc` | `#ffd27a` | `#fffbe0` | `#fff0a0` | Light faces: lamp heads, neon signs, headlights. Use with Material Neon, never a PointLight per prop. |
| `w-season` | `#6fbf4a` | `#ffffff` | `#ffc2da` | `#e8952f` | `#4be36a` | `#19ffd1` | The seasonal overlay face: snow caps, blossom, leaf piles, neon strips. Model caps and piles on every roof, hedge and car roof with this swatch. |
| `light-sky` | `#8fd0ff` | `#b9cde6` | `#a9dcff` | `#f2c99a` | `#6fe0ff` | `#141632` | Lighting: Sky top colour (Atmosphere.Color / skybox tint). |
| `light-fog` | `#d6ecff` | `#dbe5f1` | `#f0f4ff` | `#edd9c0` | `#e8fbff` | `#23264a` | Lighting: FogColor and Atmosphere.Decay. Hides streaming edges. |
| `light-ambient` | `#9aa6b8` | `#9aa8c4` | `#b0b4c8` | `#a89a8a` | `#c0c0e0` | `#4a4f7a` | Lighting: OutdoorAmbient. |
| `ui-panel` | `#282c34` | `#282c34` | `#282c34` | `#282c34` | `#282c34` | `#282c34` | Panels: Results, TopBar, Settings (UiKit PANEL_COLOUR 40,44,52). Ground for ui-text. |
| `ui-card` | `#3a3f4a` | `#3a3f4a` | `#3a3f4a` | `#3a3f4a` | `#3a3f4a` | `#3a3f4a` | Book cards and shop tiles on ui-panel (BookUi CARD_COLOUR 58,63,74). Ground for ui-text. |
| `ui-button` | `#3c8c5a` | `#3c8c5a` | `#3c8c5a` | `#3c8c5a` | `#3c8c5a` | `#3c8c5a` | Primary buttons and selected options (UiKit BUTTON_COLOUR 60,140,90). ui-text on it is 4.1:1, passes only because button text is 28px with the 2px ui-stroke outline; never put text under 24px on it. |
| `ui-off` | `#5a5e66` | `#5a5e66` | `#5a5e66` | `#5a5e66` | `#5a5e66` | `#5a5e66` | Off toggles and unselected options (OFF_COLOUR 90,94,102). ui-text on it 6.5:1. |
| `ui-track` | `#14161a` | `#14161a` | `#14161a` | `#14161a` | `#14161a` | `#14161a` | Slider tracks (TRACK_COLOUR 20,22,26). |
| `ui-handle` | `#ebebeb` | `#ebebeb` | `#ebebeb` | `#ebebeb` | `#ebebeb` | `#ebebeb` | Slider handles on ui-track. |
| `ui-text` | `#ffffff` | `#ffffff` | `#ffffff` | `#ffffff` | `#ffffff` | `#ffffff` | All UI text, always with the ui-stroke outline. Reads on ui-panel, ui-card, ui-off, ui-control and over the 3D world. |
| `ui-stroke` | `#141414` | `#141414` | `#141414` | `#141414` | `#141414` | `#141414` | 2px UIStroke on every text element (STROKE_COLOUR 20,20,20). |
| `ui-control` | `#3c3c3c` | `#3c3c3c` | `#3c3c3c` | `#3c3c3c` | `#3c3c3c` | `#3c3c3c` | Touch controls: Jump button and thumbstick base (60,60,60), at 0.3–0.5 transparency over the world. |
| `ui-unknown` | `#b9bdc7` | `#b9bdc7` | `#b9bdc7` | `#b9bdc7` | `#b9bdc7` | `#b9bdc7` | Silhouette fill for book entries not found yet (UNKNOWN_COLOUR). |
| `ui-bar-back` | `#1e1e1e` | `#1e1e1e` | `#1e1e1e` | `#1e1e1e` | `#1e1e1e` | `#1e1e1e` | Size meter bar background (Hud 30,30,30). |
| `ui-bar-fill` | `#6ec878` | `#6ec878` | `#6ec878` | `#6ec878` | `#6ec878` | `#6ec878` | Size meter progress fill (Hud 110,200,120); 8.9:1 on ui-bar-back. |
| `ui-highlight` | `#ffc93c` | `#ffc93c` | `#ffc93c` | `#ffc93c` | `#ffc93c` | `#ffc93c` | Intentional addition: selected shop tile ring, coin glyph, new-item dot. 9.8:1 on ui-panel. Never a button fill. |
| `tier-1` | `#ffbe78` | `#ffbe78` | `#ffbe78` | `#ffbe78` | `#ffbe78` | `#ffbe78` | Tier 1 chip and stand-in part colour (ObjectVisual TIER_COLOURS[1]). Always beside the tier number. |
| `tier-2` | `#96d296` | `#96d296` | `#96d296` | `#96d296` | `#96d296` | `#96d296` | Tier 2 chip and stand-in colour. |
| `tier-3` | `#82b4eb` | `#82b4eb` | `#82b4eb` | `#82b4eb` | `#82b4eb` | `#82b4eb` | Tier 3 chip and stand-in colour. |
| `tier-4` | `#eb8c8c` | `#eb8c8c` | `#eb8c8c` | `#eb8c8c` | `#eb8c8c` | `#eb8c8c` | Tier 4 chip and stand-in colour. |
| `tier-5` | `#c8a0eb` | `#c8a0eb` | `#c8a0eb` | `#c8a0eb` | `#c8a0eb` | `#c8a0eb` | Tier 5 chip and stand-in colour. |

## Type

| Style | Family | Size / line | Weight | Sample | Usage |
| --- | --- | --- | --- | --- | --- |
| `title` | display | 36px / 40px | 600 | TIME'S UP! | Results title and stars (ResultsUi TITLE_SIZE). Enum.Font.FredokaOne. |
| `meter` | display | 32px / 36px | 600 | 34.6 | Size meter number (Hud METER_VALUE_SIZE). |
| `banner` | display | 28px / 32px | 600 | YOU CAN ROLL UP: BUSES | Tier banner, timer, all button labels (BANNER/TIMER/BUTTON_TEXT_SIZE). Caps for banners. |
| `body` | body | 20px / 24px | 500 | + Traffic Cone | Results rows, book progress, pickup pop (BODY_SIZE). Enum.Font.GothamMedium. |
| `small` | body | 18px / 22px | 500 | Shop opens after this run | Tips, notices, shop 'what it does' line. 18px is the floor (Config.minTextSize); nothing smaller on any screen. |

## Spacing

| Token | Value | Usage |
| --- | --- | --- |
| `space-1` | 4px | Icon to label gap. |
| `space-2` | 8px | HUD edge margin (Hud METER_MARGIN, TIMER_TOP). |
| `space-3` | 12px | Gap between buttons and columns (ResultsUi BUTTON_GAP, COLUMN_MARGIN). |
| `space-6` | 24px | Jump button inset from the bottom-right corner. |

## Radius

| Token | Value | Usage |
| --- | --- | --- |
| `radius-button` | 12px | Buttons and toggles (UiKit CornerRadius 12). |
| `radius-panel` | 16px | Panels and shop tiles (PANEL_CORNER). |
| `radius-round` | 999px | Slider track and handle, Jump button, ball previews (UDim 0.5). |

## Touch

| Token | Value | Usage |
| --- | --- | --- |
| `touch-main` | 96px | Jump, Merge, Roll again: Config.minTouchTarget. |
| `touch-utility` | 64px | TopBar icon buttons and close: Config.minUtilityTouchTarget. |
| `stroke-text` | 2px | UIStroke thickness on all text. |
