# Contract: Signs and billboards

## Tables (`src/shared/Content/Signs.luau`)

```text
SignSlot      = { id, facadeId, shopName, atlasRegion, x, y, z, yaw }
BillboardSlot = { id, x, y, z, yaw, imageAsset, sponsored }
```

- `shopName` is an invented proper noun. No localisation key is needed (Constitution IV and IX).
- `atlasRegion` names a cell of the one shared facade/sign atlas (`Assets.facadeAtlas`).
- `imageAsset` is `"b1"` to `"b6"`, a key into `Assets.billboards`. All ids start `""`; the owner uploads later.
- `sponsored` is always `false`. Selling placements is out of scope.

## Limits

- Unique `imageAsset` values: at most `Config.billboardTextureCap` = 6 (Constitution XI).
- One facade/sign atlas for the whole slice (no per-sign textures).

## Validation (Lune, `MainStreetSlice.test.luau`)

1. Every sign `facadeId` exists in the world's facades; ids unique.
2. Every `atlasRegion` is in the region list in `Signs.luau`.
3. Every billboard `imageAsset` is a key of `Assets.billboards`, and the distinct count is at most the cap.
4. Every billboard has `sponsored == false`.
5. `shopName` and billboard ids pass a banned list: real brands and logos, "Roblox", "Robux", "Blox", alcohol,
   gambling names, flags, memes.
6. Every slot lies inside the world bounds.

## Rendering

With an empty id, the renderer draws a flat palette-coloured plate. Studio measures texture memory with all 6
billboard textures once the owner uploads (RC item).
