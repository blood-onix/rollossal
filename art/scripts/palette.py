# Writes art/palette.png (the one shared texture, an 8 x 8 grid of 32-px swatches on 256 x 256) and
# art/palette.json (swatch name -> UV centre that export_all.py validates face UVs against).
# The swatch colours duplicate the SnowVillage environment palette values on purpose: Blender cannot run
# Luau, scripts/art-sync.luau keeps budgets.json in sync with the Luau data, and this file keeps the
# texture in sync with the same numbers (contract art-pipeline.md).
# Run: blender --background --python art/scripts/palette.py

import os

import bpy

CELLS = 8
SIZE = 256
SWATCHES = [
    ("snow", (236, 242, 250)),
    ("snow_light", (247, 250, 255)),
    ("stone", (150, 158, 170)),
    ("wood", (150, 105, 70)),
    ("brick", (170, 85, 75)),
    ("ice", (170, 205, 235)),
]


def art_dir() -> str:
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> None:
    art = art_dir()
    cell = SIZE // CELLS
    pixels = [0.0] * (SIZE * SIZE * 4)
    palette = {}
    for index, (name, rgb) in enumerate(SWATCHES):
        col, row = index % CELLS, index // CELLS
        for y in range(cell):
            for x in range(cell):
                # Blender image pixels start at the bottom-left; the swatch grid starts at the top-left.
                flat = ((SIZE - 1 - (row * cell + y)) * SIZE + col * cell + x) * 4
                pixels[flat + 0] = rgb[0] / 255.0
                pixels[flat + 1] = rgb[1] / 255.0
                pixels[flat + 2] = rgb[2] / 255.0
                pixels[flat + 3] = 1.0
        c_u = (col + 0.5) / CELLS
        c_v = 1.0 - (row + 0.5) / CELLS
        palette[name] = {"u": round(c_u, 6), "v": round(c_v, 6)}
        print(f"palette: {name} cell ({col},{row}) uv ({c_u:.4f}, {c_v:.4f})")

    image = bpy.data.images.new("palette", SIZE, SIZE)
    image.pixels.foreach_set(pixels)
    png_path = os.path.join(art, "palette.png")
    image.filepath_raw = png_path
    image.file_format = "PNG"
    image.save()

    json_path = os.path.join(art, "palette.json")
    with open(json_path, "w", encoding="utf-8") as handle:
        import json

        json.dump(palette, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print(f"palette: wrote {png_path}")
    print(f"palette: wrote {json_path}")


main()
