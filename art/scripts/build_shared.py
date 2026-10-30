# Shared constants for the art scripts. Stdlib Python only: palette.py (no Blender) and the Blender
# scripts are in the same folder, so everything imports from here.
# Atlas geometry: contract specs/005-theme-art-pipeline/contracts/art-pipeline.md §1.
#  1024 x 1024 px, PNG row 0 at the top.
#  Palette cells: index i (0..63), col = i % 8, row = i // 8,
#                 x0 = col * 128, y0 = row * 64, size 128 x 64 (region y < 512).
#  Trim strips: index k (0..7), x0 = 0, y0 = 512 + k * 64, size 1024 x 64.
#  Inner (usable) rect of every cell and strip: inset 1 px on every side.
# UV convention (Blender, origin bottom-left): u = x / SIZE, v = 1 - y / SIZE, so a cell's inner
#  u = (x0 + 1) / SIZE .. (x0 + w - 1) / SIZE and v = 1 - (y0 + h - 1) / SIZE .. 1 - (y0 + 1) / SIZE.
# Gradient inside a cell: lightness factor at pixel row r (0 = top of the cell, 63 = bottom)
#  factor(r) = 1.12 - 0.27 * r / 63.

SIZE = 1024            # atlas side in pixels
CELLS_ACROSS = 8       # palette cells per row
CELLS_DOWN = 8         # palette cell rows (rows 0..7, all above the trim strips)
CELL_W = 128
CELL_H = 64
STRIP_COUNT = 8
STRIP_H = 64
STRIPS_TOP = 512       # y of the top edge of strip 0
INSET = 1              # px inset on every side of a cell / strip (>= 1 px half-texel)
GRAD_TOP = 1.12        # lightness factor at a cell's top pixel row
GRAD_BOTTOM = 0.85     # at the bottom row: factor(r) = GRAD_TOP - (GRAD_TOP - GRAD_BOTTOM) * r / (CELL_H - 1)
LEGACY_CELL_W = 0.125  # the old 256 px, 8 x 8 grid: legacy cell = column c of row 0
LEGACY_ROW_V = 0.875   # legacy cells all sit at v in [7/8, 1]
EPS = 1e-4             # numeric tolerance for degenerate-face guards and size/origin checks
UV_TOLERANCE = 1e-6    # export_all.py: face UVs must be inside a cell / strip inner rect within this

# Split normals are allowed; the FBX export preserves them (contract art-pipeline.md rule 2).
FBX_MESH_SMOOTH_TYPE = "FACE"

STRIP_NAMES = [
    "trim-grille",
    "trim-vent-slats",
    "trim-tyre-tread",
    "trim-window-frame",
    "trim-brick-course",
    "trim-panel-seams",
    "trim-kerb-stone",
    "trim-wood-grain",
]

# The legacy Snow Village swatch names in old-palette.json order (row 0, columns 0..5). remap_uv_atlas.py
# maps their cells to the atlas cells LEGACY_TO_INDEX below (cells 32..37, data-model.md §4).
LEGACY_SWATCHES = ["snow", "snow_light", "stone", "wood", "brick", "ice"]
LEGACY_TO_INDEX = {name: 32 + index for index, name in enumerate(LEGACY_SWATCHES)}
