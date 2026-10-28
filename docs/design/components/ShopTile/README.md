# ShopTile

One item in the shop grid: a static icon, the name, a "what it does" line and the price or Equip button, on `ui-card` with `radius-panel`. The selected tile gets a 3 px `ui-highlight` ring.

- **Consumer provides**: the item id, name and description keys, an icon, the price source (coins from data, or a product id whose Robux price is read from `MarketplaceService.GetProductInfo` at open; shown as "R$ —" until it loads), and whether it is owned or equipped.
- **Use it** in a 3-column grid under the tabs Skins, Toppers, Trails, Auras, Effects, Passes. One live ViewportFrame preview of the selected item sits beside the grid, never one per tile.
- **Do** keep the price button at least 48 px tall inside a tile that is at least `touch-main` wide, and show the price before any purchase prompt.
- **Don't** add rarity colours, "limited" badges, timers or discount strike-throughs. Never hard-code a Robux price.
