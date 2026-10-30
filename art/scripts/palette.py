# Generates one deterministic 1,024 x 1,024 px gradient atlas per theme (stdlib Python 3, no Blender, so
# it runs in scripts/check.sh and any CI runner). Reads docs/design/tokens.json (color.themes, the 32
# w-* tokens, color.hero, the light-* cells) and writes:
#   art/atlases/<themeId>.png   8 x 8 gradient cells (128 x 64) + 8 trim strips (1024 x 64), patterns only,
#                               no words or logos (R-03, Principle IV)
#   art/atlases/atlas.json      {"version": 2, "size": 1024, "themes": {id: {"pixelSha256": hex}}}
#                               sha256 of the raw scanline buffer (filter byte + RGB, row by row)
#   art/palette.json            schema v2 layout: UV bounds for the 64 cells + 8 strips (inner rect)
#   art/palette.png             byte copy of the winter atlas (the launch theme)
# Contract: specs/005-theme-art-pipeline/contracts/art-pipeline.md §1-3. Geometry in build_shared.py.
# Run: python3 art/scripts/palette.py
# Run: python3 art/scripts/palette.py --check   regenerate in memory, compare committed files, exit 1 on
#                                               the first difference; nothing is written.
# Exit codes: 0 ok; 1 --check mismatch or unreadable tokens; 2 invalid tokens.

import colorsys
import hashlib
import json
import os
import shutil
import struct
import sys
import zlib

import build_shared as B

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
DESIGN = os.path.join(ROOT, "docs", "design")
ART = os.path.join(ROOT, "art")
ATLASES = os.path.join(ART, "atlases")

cells = None  # filled by load_tokens


def fail(message, code=2):
    sys.stderr.write(f"palette: {message}\n")
    sys.exit(code)


def parse_hex(text):
    text = text.strip().lstrip("#")
    if len(text) != 6:
        fail(f"bad hex colour {text!r}")
    try:
        return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16))
    except ValueError:
        fail(f"bad hex colour {text!r}")


def load_tokens():
    try:
        tokens = json.load(open(os.path.join(DESIGN, "tokens.json")))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"unreadable tokens.json: {exc}", 1)
    return tokens


def cell_names():
    world = [t for t in tokens["color"]["tokens"] if t["name"].startswith("w-")]
    if len(world) != 32:
        fail(f"expected exactly 32 w-* tokens, found {len(world)}")
    heroes = tokens["color"]["hero"]
    if len(heroes) != 32:
        fail(f"expected exactly 32 color.hero entries, found {len(heroes)}")
    for hero in heroes:
        ref = hero.get("ref")
        if ref is not None and ref not in {t["name"] for t in world}:
            fail(f"color.hero entry {hero['name']} refs unknown role {ref}")
    return world, heroes, [t for t in tokens["color"]["tokens"] if t["name"].startswith("light-")]


def colour(token, theme):
    value = token["value"]
    first = tokens["color"]["themes"][0]["id"]
    return value.get(theme, value[first]) if isinstance(value, dict) else value


def theme_cells(theme):
    """Cell name -> (r, g, b) for the 64 atlas cells of one theme (hero refs resolved per theme)."""
    world, heroes, _ = cell_names()
    out = {}
    for token in world:
        out[token["name"]] = parse_hex(colour(token, theme))
    for hero in heroes:
        out[hero["name"]] = (
            parse_hex(colour(world[[t["name"] for t in world].index(hero["ref"])], theme))
            if "ref" in hero
            else parse_hex(hero["value"])
        )
    return out


def theme_lights(theme):
    _, _, lights = cell_names()
    return {name: parse_hex(colour(token, theme)) for name, token in zip(
        ["light-sky", "light-fog", "light-ambient"], lights)}


tokens = load_tokens()
themes = tokens["color"]["themes"]

# --- pixels ----------------------------------------------------------------


def factor(row_in_cell):
    """Lightness multiplier at pixel row `row_in_cell` (0 = top of the cell)."""
    return B.GRAD_TOP - (B.GRAD_TOP - B.GRAD_BOTTOM) * row_in_cell / (B.CELL_H - 1)


def shade(rgb, lightness_factor):
    """sRGB-HSL lightness change, keeping hue and saturation (R-02). Deterministic IEEE-754 maths."""
    h, l, s = colorsys.rgb_to_hls(rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0)
    l = max(0.0, min(1.0, l * lightness_factor))
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (round(r * 255), round(g * 255), round(b * 255))


def paint_strips(put, theme_rgb):
    """The eight trim strips. Integer-geometry patterns that tile horizontally (R-03)."""
    metal = theme_rgb["w-metal"]
    metal_dark = theme_rgb["w-metal-dark"]
    asphalt = theme_rgb["w-asphalt"]
    rubber = theme_rgb["w-rubber"]
    trim = theme_rgb["w-trim"]
    glass = theme_rgb["w-glass"]
    wall_b = theme_rgb["w-wall-b"]
    kerb = theme_rgb["w-kerb"]
    sidewalk = theme_rgb["w-sidewalk"]
    wood = theme_rgb["w-wood"]
    bark = theme_rgb["w-bark"]
    slat_edge = shade(metal_dark, 0.8)
    seam_edge = shade(metal, 1.15)

    def pick(k, x, y):
        if k == 0:  # trim-grille: 8 px bars every 16 px, 2 px frame lines top and bottom
            return metal_dark if (x % 16) < 8 or y < 2 or y >= B.STRIP_H - 2 else metal
        if k == 1:  # trim-vent-slats: 6 px slats every 12 px, 2 px darker lower edge
            if (x % 12) < 6:
                return slat_edge if (x % 12) in (4, 5) else metal_dark
            return metal
        if k == 2:  # trim-tyre-tread: 12 px blocks at 16 px, rows offset by 8 px
            return asphalt if ((x + (y // 8 % 2) * 8) % 16) < 12 else rubber
        if k == 3:  # trim-window-frame: 4 px frame, mullion every 128 px, glass field
            if x < 4 or x >= B.SIZE - 4 or y < 4 or y >= B.STRIP_H - 4 or (x % 128) < 4:
                return trim
            return glass
        if k == 4:  # trim-brick-course: 16 x 8 bricks, 2 px mortar, offset every other course
            if (y % 8) < 2 or ((x + (y // 8 % 2) * 8) % 16) < 2:
                return trim
            return wall_b
        if k == 5:  # trim-panel-seams: 1 px seam every 64 px, 2 px lighter edge
            if (x % 64) == 0:
                return metal_dark
            if (x % 64) in (1, 2):
                return seam_edge
            return metal
        if k == 6:  # trim-kerb-stone: 96 px stones with a 3 px joint
            return sidewalk if (x % 96) < 3 else kerb
        # 7: trim-wood-grain: horizontal bark lines at offsets from the sequence (i * 37) mod 64
        for i in range(12):
            line = (i * 37) % (B.STRIP_H - 2)
            if y in (line, line + 1):
                return bark
        return wood

    for k in range(B.STRIP_COUNT):
        y0 = B.STRIPS_TOP + k * B.STRIP_H
        for y in range(B.STRIP_H):
            for x in range(B.SIZE):
                put(x, y0 + y, pick(k, x, y))


def atlas_pixels(theme):
    """The raw RGB pixel buffer of one theme's atlas, row 0 (top) first."""
    theme_rgb = theme_cells(theme)
    theme_rgb.update(theme_lights(theme))
    buffer = bytearray(B.SIZE * B.SIZE * 3)

    def put(x, y, rgb):
        offset = (y * B.SIZE + x) * 3
        buffer[offset:offset + 3] = bytes(rgb)

    for index in range(64):
        name = atlas_cell_names()[index]
        col, row = index % B.CELLS_ACROSS, index // B.CELLS_ACROSS
        x0, y0 = col * B.CELL_W, row * B.CELL_H
        rgb = theme_rgb[name]
        for y_in_cell in range(B.CELL_H):
            row_rgb = bytes(shade(rgb, factor(y_in_cell)))
            for x in range(B.CELL_W):
                offset = ((y0 + y_in_cell) * B.SIZE + x0 + x) * 3
                buffer[offset:offset + 3] = row_rgb

    paint_strips(put, theme_rgb)
    return buffer


def atlas_cell_names():
    world, heroes, _ = cell_names()
    return [t["name"] for t in world] + [h["name"] for h in heroes]


def scanline_buffer(pixels):
    """sha256 of this buffer equals the atlas.json contract: filter byte + RGB, row by row."""
    raw = bytearray()
    for y in range(B.SIZE):
        raw.append(0)
        raw += pixels[y * B.SIZE * 3:(y + 1) * B.SIZE * 3]
    return bytes(raw)


# --- PNG and JSON output ---------------------------------------------------


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def encode_png(pixels):
    """8-bit RGB PNG, filter type 0 rows (the scanline buffer is the raw IDAT stream)."""
    blob = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", B.SIZE, B.SIZE, 8, 2, 0, 0, 0)
    blob += chunk(b"IHDR", ihdr)
    blob += chunk(b"IDAT", zlib.compress(scanline_buffer(pixels), 9))
    blob += chunk(b"IEND", b"")
    return blob


def decode_png(path):
    """Returns (width, height, raw scanline stream) for a committed PNG, without assumptions about
    which zlib build compressed it (R-01: the committed contract is the pixel hash)."""
    blob = open(path, "rb").read()
    if not blob.startswith(b"\x89PNG\r\n\x1a\n"):
        fail(f"{path}: not a PNG file", 1)
    offset = 8
    length = None
    stream = b""
    while offset < len(blob):
        length, kind = struct.unpack(">I4s", blob[offset:offset + 8])
        data = blob[offset + 8:offset + 8 + length]
        if kind == b"IHDR":
            width, height = struct.unpack(">II", data[:8])
            depth, colour_type = data[8], data[9]
        elif kind == b"IDAT":
            stream += data
        elif kind == b"IEND":
            break
        offset += 12 + length
    if (width, height) != (B.SIZE, B.SIZE) or depth != 8 or colour_type != 2:
        fail(f"{path}: expected a {B.SIZE} x {B.SIZE} 8-bit RGB PNG", 1)
    return width, height, zlib.decompress(stream)


def hash_of(pixels):
    return hashlib.sha256(scanline_buffer(pixels)).hexdigest()


def layout():
    """art/palette.json schema v2 (contract art-pipeline.md §3)."""
    names = atlas_cell_names()
    entries = {}
    for index, name in enumerate(names):
        col, row = index % B.CELLS_ACROSS, index // B.CELLS_ACROSS
        x0, y0 = col * B.CELL_W, row * B.CELL_H
        u0 = (x0 + B.INSET) / B.SIZE
        v1 = 1 - (y0 + B.INSET) / B.SIZE
        u1 = (x0 + B.CELL_W - B.INSET) / B.SIZE
        v0 = 1 - (y0 + B.CELL_H - B.INSET) / B.SIZE
        entries[name] = {
            "index": index,
            "col": col,
            "row": row,
            "u": round((x0 + B.CELL_W / 2) / B.SIZE, 6),
            "v": round(1 - (y0 + B.CELL_H / 2) / B.SIZE, 6),
            "u0": round(u0, 6),
            "v0": round(v0, 6),
            "u1": round(u1, 6),
            "v1": round(v1, 6),
        }
    strips = {}
    for k in range(B.STRIP_COUNT):
        x0, y0 = 0, B.STRIPS_TOP + k * B.STRIP_H
        u0 = (x0 + B.INSET) / B.SIZE
        v1 = 1 - (y0 + B.INSET) / B.SIZE
        u1 = (x0 + B.SIZE - B.INSET) / B.SIZE
        v0 = 1 - (y0 + B.STRIP_H - B.INSET) / B.SIZE
        strips[B.STRIP_NAMES[k]] = {
            "index": k,
            "u": round((x0 + B.SIZE / 2) / B.SIZE, 6),
            "v": round(1 - (y0 + B.STRIP_H / 2) / B.SIZE, 6),
            "u0": round(u0, 6),
            "v0": round(v0, 6),
            "u1": round(u1, 6),
            "v1": round(v1, 6),
        }
    return {
        "version": 2,
        "size": B.SIZE,
        "inset": B.INSET,
        "cells": entries,
        "strips": strips,
    }


def generate():
    """Everything the script writes, in memory."""
    atlases = {}
    for theme in [t["id"] for t in themes]:
        pixels = atlas_pixels(theme)
        atlases[theme] = {"pixels": pixels, "png": encode_png(pixels), "sha256": hash_of(pixels)}
    return atlases


def main():
    check = "--check" in sys.argv[1:]
    generated = generate()
    os.makedirs(ATLASES, exist_ok=True)

    atlas_json = {
        "version": 2,
        "size": B.SIZE,
        "themes": {t["id"]: {"pixelSha256": generated[t["id"]]["sha256"]} for t in themes},
    }
    layout_json = json.dumps(layout(), indent=2, sort_keys=True) + "\n"

    if check:
        for theme in [t["id"] for t in themes]:
            path = os.path.join(ATLASES, f"{theme}.png")
            if not os.path.exists(path):
                fail(f"missing {os.path.relpath(path, ROOT)} (run python3 art/scripts/palette.py)", 1)
            _, _, raw = decode_png(path)
            have = hashlib.sha256(raw).hexdigest()
            want = generated[theme]["sha256"]
            if have != want:
                fail(f"{path}: pixel hash {have} does not match the regenerated {want}", 1)
            if os.path.exists(os.path.join(ATLASES, "atlas.json")):
                recorded = json.load(open(os.path.join(ATLASES, "atlas.json")))
                if recorded["themes"].get(theme, {}).get("pixelSha256") != want:
                    fail(f"atlas.json records a stale hash for {theme}", 1)
        palette_path = os.path.join(ART, "palette.png")
        if open(palette_path, "rb").read() != generated["winter"]["png"]:
            fail(f"{os.path.relpath(palette_path, ROOT)} is not a byte copy of the winter atlas", 1)
        have_layout = open(os.path.join(ART, "palette.json")).read()
        if have_layout != layout_json:
            fail("palette.json is stale (run python3 art/scripts/palette.py)", 1)
        print("atlases in sync")
        return

    for theme in [t["id"] for t in themes]:
        path = os.path.join(ATLASES, f"{theme}.png")
        with open(path, "wb") as handle:
            handle.write(generated[theme]["png"])
        print(f"palette: wrote {path} ({generated[theme]['sha256'][:12]})")
    with open(os.path.join(ATLASES, "atlas.json"), "w", encoding="utf-8") as handle:
        json.dump(atlas_json, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print(f"palette: wrote {os.path.relpath(os.path.join(ATLASES, 'atlas.json'), ROOT)}")
    with open(os.path.join(ART, "palette.json"), "w", encoding="utf-8") as handle:
        handle.write(layout_json)
    print(f"palette: wrote {os.path.relpath(os.path.join(ART, 'palette.json'), ROOT)}")
    shutil.copyfile(os.path.join(ATLASES, "winter.png"), os.path.join(ART, "palette.png"))
    print(f"palette: wrote {os.path.relpath(os.path.join(ART, 'palette.png'), ROOT)} (winter copy)")


if __name__ == "__main__":
    main()
