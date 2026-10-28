# Button

The game's chunky button (`UiKit.button`): a `ui-button` or `ui-off` fill, `radius-button` corners, a `banner` label in white with the 2 px `ui-stroke` outline.

- **Consumer provides**: a localisation key for the label, width and height (clamped up to `touch-main` 96 px for main actions, `touch-utility` 64 px for icon buttons), and the activate callback.
- **Use** `ui-button` for the one action you want next (Roll again, Equip, Buy), `ui-off` for the alternative (Hub, Cancel) and for unselected options.
- **Do** keep the label at 28 px: white on `ui-button` is 4.1:1, which only passes as large text.
- **Don't** put two `ui-button` fills side by side, or use colour alone for on/off; toggles also change their label.
