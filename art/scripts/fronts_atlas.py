# Generates the fronts and signs atlas, one deterministic 1,024 x 1,024 px PNG per theme (stdlib Python 3, no Blender,
# so it runs in scripts/check.sh). 013 strand 5; contract specs/013-city-asset-kit/contracts/fronts-atlas-and-billboards.md.
# Inputs: docs/design/tokens.json (theme colours, through palette.py) and docs/design/shop-names.json (the `clear`
# names, each with its `cell`). Text is a built-in 5 x 7 bitmap font scaled up; no font file, no network.
#
# Layout, identical on every theme (px, row 0 at the top; 2 px inset on every side of a cell or strip):
#   sign_00 .. sign_21   22 cells, 4 across x 6 down, 256 x 64,  y 0..383     one shop name each, two lines at most
#   fx_snowcap, fx_glasslit  the last two 256 x 64 cells of that grid (013 rework, plan R2): snow caps (stone coping
#                        outside winter) and lit windows; listed under "strips" because they are facade surfaces
#   bb_*                  8 cells, 4 across x 2 down, 256 x 128, y 384..639    the billboard designs (the cap)
#   fx_*                  6 strips, stacked, 1,024 x 64,          y 640..1023  facade strips
# Writes art/atlases/fronts/<themeId>.png and art/atlases/fronts/fronts.json (layout, names, pixel SHA-256 per theme).
# Run: python3 art/scripts/fronts_atlas.py
# Run: python3 art/scripts/fronts_atlas.py --check   regenerate in memory, compare the committed files, exit 1 on any
#                                                    difference or a missing file; nothing is written.

import hashlib
import json
import os
import struct
import sys
import zlib

import palette as P

SIZE = 1024
INSET = 2
SIGN_W, SIGN_H, SIGN_COLS, SIGN_COUNT = 256, 64, 4, 22
WEAR_NAMES = ["fx_snowcap", "fx_glasslit"]  # in sign grid slots 22 and 23
BB_W, BB_H, BB_COLS, BB_TOP = 256, 128, 4, 384
BB_NAMES = ["bb_404", "bb_chart", "bb_loading", "bb_empty", "bb_arrow", "bb_testcard", "bb_nested", "bb_buffering"]
FX_NAMES = ["fx_brick", "fx_render", "fx_glass", "fx_shutter", "fx_shopglaze", "fx_cornice"]
FX_TOP, FX_H = 640, 64
MAX_LINE = 13
BILLBOARD_CAP = 8  # Config.Budgets.billboardTextures
ACCENTS = ["w-accent-red", "w-accent-yellow", "w-accent-blue", "w-accent-teal", "w-accent-orange", "w-accent-pink"]

ROOT = P.ROOT
FRONTS = os.path.join(P.ATLASES, "fronts")
NAMES_PATH = os.path.join(P.DESIGN, "shop-names.json")

FONT = {
    "A": "01110 10001 10001 11111 10001 10001 10001", "B": "11110 10001 10001 11110 10001 10001 11110",
    "C": "01110 10001 10000 10000 10000 10001 01110", "D": "11110 10001 10001 10001 10001 10001 11110",
    "E": "11111 10000 10000 11110 10000 10000 11111", "F": "11111 10000 10000 11110 10000 10000 10000",
    "G": "01110 10001 10000 10111 10001 10001 01111", "H": "10001 10001 10001 11111 10001 10001 10001",
    "I": "01110 00100 00100 00100 00100 00100 01110", "J": "00111 00010 00010 00010 00010 10010 01100",
    "K": "10001 10010 10100 11000 10100 10010 10001", "L": "10000 10000 10000 10000 10000 10000 11111",
    "M": "10001 11011 10101 10101 10001 10001 10001", "N": "10001 11001 10101 10011 10001 10001 10001",
    "O": "01110 10001 10001 10001 10001 10001 01110", "P": "11110 10001 10001 11110 10000 10000 10000",
    "Q": "01110 10001 10001 10001 10101 10010 01101", "R": "11110 10001 10001 11110 10100 10010 10001",
    "S": "01111 10000 10000 01110 00001 00001 11110", "T": "11111 00100 00100 00100 00100 00100 00100",
    "U": "10001 10001 10001 10001 10001 10001 01110", "V": "10001 10001 10001 10001 10001 01010 00100",
    "W": "10001 10001 10001 10101 10101 10101 01010", "X": "10001 10001 01010 00100 01010 10001 10001",
    "Y": "10001 10001 01010 00100 00100 00100 00100", "Z": "11111 00001 00010 00100 01000 10000 11111",
    "0": "01110 10001 10011 10101 11001 10001 01110", "1": "00100 01100 00100 00100 00100 00100 01110",
    "2": "01110 10001 00001 00010 00100 01000 11111", "3": "11110 00001 00001 01110 00001 00001 11110",
    "4": "00010 00110 01010 10010 11111 00010 00010", "5": "11111 10000 11110 00001 00001 10001 01110",
    "6": "00110 01000 10000 11110 10001 10001 01110", "7": "11111 00001 00010 00100 01000 01000 01000",
    "8": "01110 10001 10001 01110 10001 10001 01110", "9": "01110 10001 10001 01111 00001 00010 01100",
    "&": "01100 10010 10100 01000 10101 10010 01101", "'": "00100 00100 01000 00000 00000 00000 00000",
    " ": "00000 00000 00000 00000 00000 00000 00000",
}


def fail(message, code=2):
    sys.stderr.write(f"fronts_atlas: {message}\n")
    sys.exit(code)


class Canvas:
    def __init__(self):
        self.buf = bytearray(SIZE * SIZE * 3)

    def put(self, x, y, rgb):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            o = (y * SIZE + x) * 3
            self.buf[o:o + 3] = bytes(rgb)

    def rect(self, x0, y0, w, h, rgb):
        row = bytes(rgb) * max(0, w)
        for y in range(max(0, y0), min(SIZE, y0 + h)):
            for x in range(max(0, x0), min(SIZE, x0 + w)):
                o = (y * SIZE + x) * 3
                self.buf[o:o + 3] = bytes(rgb)
        del row

    def frame(self, x0, y0, w, h, t, rgb):
        self.rect(x0, y0, w, t, rgb)
        self.rect(x0, y0 + h - t, w, t, rgb)
        self.rect(x0, y0, t, h, rgb)
        self.rect(x0 + w - t, y0, t, h, rgb)

    def disc(self, cx, cy, r, rgb):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
                    self.put(x, y, rgb)

    def line(self, x0, y0, x1, y1, t, rgb):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.disc(x0, y0, t // 2, rgb)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def text(self, x, y, body, scale, rgb):
        """Draws uppercase glyphs; lowercase letters use the uppercase shape. Returns the drawn width."""
        cx = x
        for ch in body.upper():
            rows = FONT[ch].split()
            for ry, bits in enumerate(rows):
                for rx, bit in enumerate(bits):
                    if bit == "1":
                        self.rect(cx + rx * scale, y + ry * scale, scale, scale, rgb)
            cx += 6 * scale
        return cx - x - scale


def text_width(body, scale):
    return len(body) * 6 * scale - scale


def lum(rgb):
    return (rgb[0] * 299 + rgb[1] * 587 + rgb[2] * 114) // 1000


def load_names():
    try:
        data = json.load(open(NAMES_PATH, encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"unreadable shop-names.json: {exc}", 1)
    clear = [n for n in data["names"] if n["verdict"] == "clear"]
    cells = {}
    for n in clear:
        lines = n["lines"]
        if not 1 <= len(lines) <= 2 or any(len(l) > MAX_LINE or not l or any(c.upper() not in FONT for c in l) for l in lines):
            fail(f"{n['name']}: bad sign lines {lines}")
        cell = n.get("cell")
        if cell is None:
            fail(f"{n['name']}: clear name without a cell")
        if cell in cells:
            fail(f"{cell} used twice")
        index = int(cell.split("_")[1])
        if not 0 <= index < SIGN_COUNT:
            fail(f"{cell} out of range")
        cells[cell] = n
    return cells


def sign_rect(index):
    col, row = index % SIGN_COLS, index // SIGN_COLS
    return col * SIGN_W, row * SIGN_H, SIGN_W, SIGN_H


def bb_rect(index):
    col, row = index % BB_COLS, index // BB_COLS
    return col * BB_W, BB_TOP + row * BB_H, BB_W, BB_H


def fx_rect(index):
    return 0, FX_TOP + index * FX_H, SIZE, FX_H


def paint_sign(c, rgbs, index, shop):
    x0, y0, w, h = sign_rect(index)
    bg = rgbs[ACCENTS[index % len(ACCENTS)]]
    fg = rgbs["w-white"] if lum(bg) < 150 else rgbs["w-metal-dark"]
    c.rect(x0, y0, w, h, bg)
    c.frame(x0, y0, w, h, 3, rgbs["w-season"])
    c.frame(x0 + 3, y0 + 3, w - 6, h - 6, 1, rgbs["w-trim"])
    lines = shop["lines"] if shop else []
    if not lines:
        return
    scale = 4
    while scale > 1 and (max(text_width(l, scale) for l in lines) > w - 16 or len(lines) * 7 * scale + (len(lines) - 1) * scale > h - 12):
        scale -= 1
    total = len(lines) * 7 * scale + (len(lines) - 1) * scale
    y = y0 + (h - total) // 2
    for line in lines:
        c.text(x0 + (w - text_width(line, scale)) // 2, y, line, scale, fg)
        y += 8 * scale


def paint_billboard(c, rgbs, index):
    x0, y0, w, h = bb_rect(index)
    name = BB_NAMES[index]
    dark, light, trim = rgbs["w-metal-dark"], rgbs["w-white"], rgbs["w-trim"]
    red, yel, blu, teal = rgbs["w-accent-red"], rgbs["w-accent-yellow"], rgbs["w-accent-blue"], rgbs["w-accent-teal"]
    c.rect(x0, y0, w, h, light)
    if name == "bb_404":
        c.rect(x0, y0, w, h, dark)
        c.text(x0 + (w - text_width("404", 10)) // 2, y0 + (h - 70) // 2, "404", 10, red)
    elif name == "bb_chart":
        c.rect(x0, y0, w, h, light)
        for gx in range(x0 + 16, x0 + w - 8, 32):
            c.rect(gx, y0 + 10, 1, h - 20, trim)
        c.line(x0 + 24, y0 + h - 24, x0 + 90, y0 + h - 50, 7, teal)
        c.line(x0 + 90, y0 + h - 50, x0 + 130, y0 + h - 42, 7, teal)
        c.line(x0 + 130, y0 + h - 42, x0 + 215, y0 + 26, 7, teal)
        c.line(x0 + 215, y0 + 26, x0 + 190, y0 + 28, 7, teal)
        c.line(x0 + 215, y0 + 26, x0 + 213, y0 + 52, 7, teal)
    elif name == "bb_loading":
        c.rect(x0, y0, w, h, dark)
        cx, cy = x0 + w // 2, y0 + h // 2
        for k in range(12):
            ang = k * 30
            dx = [0, 26, 45, 52, 45, 26, 0, -26, -45, -52, -45, -26][k]
            dy = [-52, -45, -26, 0, 26, 45, 52, 45, 26, 0, -26, -45][k]
            shade_ = 255 - k * 18
            c.disc(cx + dx, cy + dy, 7, (shade_, shade_, shade_))
        del ang
    elif name == "bb_empty":
        c.rect(x0, y0, w, h, rgbs["w-wall-c"])
        c.frame(x0 + 14, y0 + 14, w - 28, h - 28, 8, dark)
    elif name == "bb_arrow":
        c.rect(x0, y0, w, h, light)
        mid = y0 + h // 2
        c.rect(x0 + 24, mid - 12, 130, 24, red)
        for k in range(48):
            c.rect(x0 + 154 + k, mid - 48 + k, 1, 96 - 2 * k, red)
    elif name == "bb_testcard":
        bars = [light, yel, teal, rgbs["w-leaf"], rgbs["w-accent-pink"], red, blu]
        bw = (w - 8) // 7
        for k, col in enumerate(bars):
            c.rect(x0 + 4 + k * bw, y0 + 4, bw, h - 40, col)
        c.rect(x0 + 4, y0 + h - 36, w - 8, 32, dark)
        c.disc(x0 + w // 2, y0 + h - 20, 10, light)
    elif name == "bb_nested":
        c.rect(x0, y0, w, h, rgbs["w-wall-c"])
        px0, py0, pw, ph = x0 + 10, y0 + 8, w - 20, h - 30
        for depth in range(3):
            c.rect(px0, py0, pw, ph, dark if depth % 2 == 0 else light)
            c.frame(px0, py0, pw, ph, 3, trim)
            c.rect(px0 + pw // 2 - 3, py0 + ph, 6, 14 - depth * 4, rgbs["w-metal"])
            nx0, ny0 = px0 + pw // 6, py0 + ph // 6
            px0, py0, pw, ph = nx0, ny0, pw * 2 // 3, ph * 2 // 3
    elif name == "bb_buffering":
        c.rect(x0, y0, w, h, dark)
        cx, cy = x0 + w // 2, y0 + 50
        for k in range(8):
            dx = [0, 24, 34, 24, 0, -24, -34, -24][k]
            dy = [-34, -24, 0, 24, 34, 24, 0, -24][k]
            c.disc(cx + dx, cy + dy, 6, (255 - k * 28,) * 3)
        c.frame(x0 + 28, y0 + h - 28, w - 56, 14, 2, light)
        c.rect(x0 + 31, y0 + h - 25, int((w - 62) * 0.97), 8, yel)
    c.frame(x0, y0, w, h, 3, rgbs["w-metal-dark"])


def paint_strip(c, rgbs, index, theme):
    x0, y0, w, h = fx_rect(index)
    name = FX_NAMES[index]
    trim, glass, door = rgbs["w-trim"], rgbs["w-glass"], rgbs["w-door"]
    grime = [P.grime_factor(round(y * (P.B.CELL_H - 1) / (h - 1))) for y in range(h)]  # darker towards the base
    if name == "fx_brick":
        base = rgbs["w-wall-b"]
        mortar_rgb = P.shade(rgbs["w-kerb"], 1.15)
        for y in range(h):
            for x in range(w):
                mortar = (y % 8) < 2 or ((x + (y // 8 % 2) * 8) % 16) < 2
                tone = 0.92 + 0.08 * P.cell_hash((x + (y // 8 % 2) * 8) // 16, y // 8, 13)  # brick-to-brick variation
                c.put(x0 + x, y0 + y, P.shade(mortar_rgb if mortar else base, grime[y] * (1.0 if mortar else tone)))
    elif name == "fx_render":
        base = rgbs["w-wall-a"]
        for y in range(h):
            for x in range(w):
                streak = (x % 97) < 3 and y > h * 0.3  # rain streaks below the sills
                c.put(x0 + x, y0 + y, P.shade(base, grime[y] * (0.9 if streak else 1.0)))
    elif name == "fx_glass":
        c.rect(x0, y0, w, h, glass)
        for k in range(0, w, 64):
            c.rect(x0 + k, y0, 4, h, rgbs["w-metal-dark"])
        c.rect(x0, y0 + h // 2 - 2, w, 4, rgbs["w-metal-dark"])
        c.rect(x0, y0, w, 3, rgbs["w-metal"])
    elif name == "fx_shutter":
        c.rect(x0, y0, w, h, door)
        for k in range(0, w, 8):
            c.rect(x0 + k, y0, 2, h, trim)
    elif name == "fx_shopglaze":
        c.rect(x0, y0, w, h, glass)
        for k in range(0, w, 128):
            c.rect(x0 + k, y0, 6, h, trim)
        c.rect(x0, y0, w, 5, trim)
        c.rect(x0, y0 + h - 6, w, 6, trim)
    else:  # fx_cornice
        c.rect(x0, y0, w, h, rgbs["w-wall-a"])
        c.rect(x0, y0, w, 6, trim)
        c.rect(x0, y0 + 8, w, 4, rgbs["w-wall-c"])
        for k in range(0, w, 16):
            c.rect(x0 + k, y0 + 16, 10, 20, trim)
        c.rect(x0, y0 + 44, w, 8, rgbs["w-wall-c"])
        c.rect(x0, y0 + h - 4, w, 4, trim)
        if theme == "winter":
            c.rect(x0, y0, w, 4, rgbs["w-season"])  # thin season trim, under 15 % of the strip


def paint_wear(c, rgbs, index):
    x0, y0, w, h = sign_rect(SIGN_COUNT + index)
    if WEAR_NAMES[index] == "fx_snowcap":
        for y in range(h):
            c.rect(x0, y0 + y, w, 1, P.shade(rgbs["w-snowcap"], 1.04 - 0.12 * y / (h - 1)))
    else:  # fx_glasslit: warm lit pane with a dark frame and a cross mullion
        c.rect(x0, y0, w, h, rgbs["w-metal-dark"])
        c.rect(x0 + 6, y0 + 6, w - 12, h - 12, rgbs["w-glass-lit"])
        c.rect(x0 + w // 2 - 2, y0, 4, h, rgbs["w-metal-dark"])


def atlas_pixels(theme, shops):
    rgbs = P.theme_cells(theme)
    c = Canvas()
    for index in range(SIGN_COUNT):
        paint_sign(c, rgbs, index, shops.get(f"sign_{index:02d}"))
    for index in range(len(BB_NAMES)):
        paint_billboard(c, rgbs, index)
    for index in range(len(FX_NAMES)):
        paint_strip(c, rgbs, index, theme)
    for index in range(len(WEAR_NAMES)):
        paint_wear(c, rgbs, index)
    return c.buf


def inner(x0, y0, w, h):
    return {
        "u0": round((x0 + INSET) / SIZE, 6), "u1": round((x0 + w - INSET) / SIZE, 6),
        "v0": round(1 - (y0 + h - INSET) / SIZE, 6), "v1": round(1 - (y0 + INSET) / SIZE, 6),
    }


def layout(shops):
    signs = {}
    for index in range(SIGN_COUNT):
        key = f"sign_{index:02d}"
        entry = inner(*sign_rect(index))
        if key in shops:
            entry["name"] = shops[key]["name"]
        signs[key] = entry
    return {
        "version": 1, "size": SIZE, "inset": INSET,
        "signs": signs,
        "billboards": {name: inner(*bb_rect(i)) for i, name in enumerate(BB_NAMES)},
        "strips": {**{name: inner(*fx_rect(i)) for i, name in enumerate(FX_NAMES)},
                   **{name: inner(*sign_rect(SIGN_COUNT + i)) for i, name in enumerate(WEAR_NAMES)}},
    }


def generate():
    shops = load_names()
    if len(BB_NAMES) > BILLBOARD_CAP:
        fail("more billboard cells than Config.Budgets.billboardTextures")
    out = {}
    for theme in [t["id"] for t in P.themes]:
        pixels = atlas_pixels(theme, shops)
        out[theme] = {"pixels": pixels, "png": P.encode_png(pixels), "sha256": P.hash_of(pixels)}
    doc = layout(shops)
    doc["themes"] = {theme: {"pixelSha256": out[theme]["sha256"]} for theme in out}
    return out, json.dumps(doc, indent=2, sort_keys=True) + "\n"


def main():
    generated, doc = generate()
    json_path = os.path.join(FRONTS, "fronts.json")
    if "--check" in sys.argv[1:]:
        if not os.path.isfile(json_path):
            fail("missing art/atlases/fronts/fronts.json (run python3 art/scripts/fronts_atlas.py)", 1)
        if open(json_path, encoding="utf-8").read() != doc:
            fail("fronts.json is stale (run python3 art/scripts/fronts_atlas.py)", 1)
        for theme, item in generated.items():
            path = os.path.join(FRONTS, f"{theme}.png")
            if not os.path.isfile(path):
                fail(f"missing {os.path.relpath(path, ROOT)}", 1)
            _, _, raw = P.decode_png(path)
            if hashlib.sha256(raw).hexdigest() != item["sha256"]:
                fail(f"{os.path.relpath(path, ROOT)} does not match the regenerated pixels", 1)
        print("fronts atlas in sync")
        return
    os.makedirs(FRONTS, exist_ok=True)
    for theme, item in generated.items():
        with open(os.path.join(FRONTS, f"{theme}.png"), "wb") as handle:
            handle.write(item["png"])
        print(f"fronts_atlas: wrote {theme}.png ({item['sha256'][:12]}, {len(item['png'])} bytes)")
    with open(json_path, "w", encoding="utf-8") as handle:
        handle.write(doc)
    print("fronts_atlas: wrote fronts.json")


if __name__ == "__main__":
    main()
