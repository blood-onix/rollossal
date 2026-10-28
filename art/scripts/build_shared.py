# Shared constants for the Blender scripts (contract art-pipeline.md): the palette texture is one grid of
# cells, and the modelling guides use the same tolerances everywhere.

CELLS = 8      # the palette texture is an 8 x 8 grid of one-colour swatch cells
EPS = 1e-4     # numeric tolerance for degenerate-face guards and size/origin checks
