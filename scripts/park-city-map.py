#!/usr/bin/env python3
"""Draw the Park City level-design map (docs/design/09-park-city-level.md) as an SVG.

Stdlib only. Coordinates are game studs: x east, z south (down on the map), origin at the centre.
Run: python3 scripts/park-city-map.py  ->  docs/design/maps/park-city.svg
"""
from pathlib import Path

HALF = 500  # playable half extent
PAD = 40
S = 1.0  # svg units per stud

shapes: list[str] = []


def X(x: float) -> float:
    return (x + HALF + PAD) * S


def Z(z: float) -> float:
    return (z + HALF + PAD) * S


def rect(x0, z0, x1, z1, fill, stroke="none", sw=1, rx=0, opacity=1.0, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    shapes.append(
        f'<rect x="{X(min(x0, x1)):.1f}" y="{Z(min(z0, z1)):.1f}" width="{abs(x1 - x0) * S:.1f}" '
        f'height="{abs(z1 - z0) * S:.1f}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" '
        f'opacity="{opacity}"{d}/>'
    )


def circle(x, z, r, fill, stroke="none", sw=1, opacity=1.0):
    shapes.append(
        f'<circle cx="{X(x):.1f}" cy="{Z(z):.1f}" r="{r * S:.1f}" fill="{fill}" stroke="{stroke}" '
        f'stroke-width="{sw}" opacity="{opacity}"/>'
    )


def ellipse(x, z, rx, rz, fill, stroke="none", sw=1):
    shapes.append(
        f'<ellipse cx="{X(x):.1f}" cy="{Z(z):.1f}" rx="{rx * S:.1f}" ry="{rz * S:.1f}" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="{sw}"/>'
    )


def line(pts, stroke, sw=2, dash=None, marker=False):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    m = ' marker-end="url(#arrow)"' if marker else ""
    p = " ".join(f"{X(x):.1f},{Z(z):.1f}" for x, z in pts)
    shapes.append(
        f'<polyline points="{p}" fill="none" stroke="{stroke}" stroke-width="{sw}" '
        f'stroke-linecap="round" stroke-linejoin="round"{d}{m}/>'
    )


def text(x, z, s, size=11, fill="#1d2433", weight="600", anchor="middle"):
    shapes.append(
        f'<text x="{X(x):.1f}" y="{Z(z):.1f}" font-size="{size}" font-weight="{weight}" fill="{fill}" '
        f'text-anchor="{anchor}" font-family="Montserrat,Arial,sans-serif">{s}</text>'
    )


GRASS = "#9fd17e"
GRASS_DARK = "#6fae5a"
WOOD = "#4f8f4a"
WATER = "#6cc3e8"
ROAD = "#5b616e"
PAVE = "#c9c3b5"
BLOCK = "#e8d9bf"
DOWNTOWN = "#b9c3d6"
ROOF = "#d98b5f"
RAIL = "#e2457a"
BOOST = "#ffb020"
SPAWN = "#ffffff"
HAZ = "#7a4fd0"
GOLD = "#f2c200"

# Ground: park ring, ring road, neighbourhoods, downtown
rect(-HALF - PAD, -HALF - PAD, HALF + PAD, HALF + PAD, "#7fb86a")
rect(-HALF, -HALF, HALF, HALF, GRASS, stroke="#2e5d2a", sw=3)
rect(-300, -300, 300, 300, ROAD, rx=30)
rect(-260, -260, 260, 260, PAVE, rx=12)
rect(-150, -150, 150, 150, DOWNTOWN, stroke="#e0662f", sw=3, dash="8 5")

# Spokes: four 40-wide avenues from plaza to park edge (paths inside the park)
for a, b in (((-20, -500), (20, -150)), ((-20, 150), (20, 500)), ((-500, -20), (-150, 20)), ((150, -20), (500, 20))):
    (x0, z0), (x1, z1) = a, b
    inside_park = abs(z0) == 500 or abs(x0) == 500 or abs(z1) == 500 or abs(x1) == 500
    rect(x0, z0, x1, z1, "#d8c79d" if inside_park else ROAD)
for x0, z0, x1, z1 in ((-20, -300, 20, -150), (-20, 150, 20, 300), (-300, -20, -150, 20), (150, -20, 300, 20)):
    rect(x0, z0, x1, z1, ROAD)
circle(0, 0, 50, PAVE, stroke="#888", sw=2)

# Park Loop footpath (10 wide, at m = 400) and spawn doorsteps (35-stud food pads)
rect(-405, -405, 405, 405, "none", stroke="#e9dcb4", sw=10, rx=40)
text(0, -409, "Park Loop path", 9, "#7a6a3a")
for sx in (-1, 1):
    for sz in (-1, 1):
        for x, z in ((sx * 180, sz * 440), (sx * 440, sz * 180), (sx * 450, sz * 450)):
            circle(x, z, 35, "#fff7c2", opacity=0.55)

# --- NW: Woods and Campsite --------------------------------------------------------------------------
rect(-500, -500, -300, -300, WOOD, opacity=0.35)
for x, z in ((-470, -330), (-480, -400), (-410, -480), (-340, -470), (-460, -250), (-250, -460), (-330, -420)):
    circle(x, z, 9, WOOD)
circle(-370, -370, 26, "#3c6d37", stroke="#23401f", sw=2)  # Giant Oak
text(-370, -366, "Giant Oak", 10, "#fff")
circle(-430, -300, 32, "#c7e3a3", stroke=WOOD, sw=2)
text(-430, -296, "Mushroom Glade", 10)
rect(-325, -500, -315, -300, WATER)  # stream
text(-305, -505, "Stream", 9, anchor="start")
rect(-490, -120, -420, -60, "#d9c08a", rx=6)
text(-455, -86, "Campsite", 10)
line([(-370, -370), (-305, -305)], RAIL, 3, dash="2 4", marker=True)  # treehouse zipline
line([(-325, -440), (-315, -400)], RAIL, 4)  # fallen log rail
line([(-395, -345), (-415, -310)], "#8a5a2b", 3, dash="1 3")  # root tunnel

# --- NE: Pond and Boathouse ------------------------------------------------------------------------------
ellipse(340, -340, 70, 55, WATER, stroke="#3a8fb7", sw=2)
circle(340, -340, 15, "#c9b77a", stroke="#8a7a40", sw=2)
text(340, -337, "Duck Isl.", 9)
for i in range(6):
    circle(275 + i * 8.5, -340, 2.5, "#4c9a3c")
rect(336, -290, 344, -270, "#9b7146")  # jetty + diving board
line([(340, -395), (340, -355)], RAIL, 4)  # pipe rail
rect(405, -360, 430, -330, "#b06d4a")
text(418, -365, "Boathouse", 9)
circle(250, -430, 12, "#f5d75a", stroke="#a48a10", sw=2)
text(250, -446, "Giant Duck", 9)
rect(200, -330, 260, -280, "#c7e3a3", rx=8)
text(230, -302, "Picnic Lawn", 9)

# --- SE: Playground, Skate park, Courts -----------------------------------------------------------------
rect(290 + 10, 300, 400, 380, "#cfcfd6", stroke="#777", sw=2, rx=10)
ellipse(350, 340, 26, 20, "#a9a9b4", stroke="#666", sw=1)
text(350, 395, "Skate Park", 10)
rect(300, 200, 390, 270, "#f2d27b", stroke="#b6902a", sw=2, rx=8)
text(345, 238, "Playground", 10)
rect(235, 385, 315, 475, "#7fb1a8", stroke="#fff", sw=2)
text(275, 434, "Courts", 10)
circle(450, 330, 22, "none", stroke="#d0465a", sw=4)
text(450, 334, "Ferris", 9)

# --- SW: Gardens, Hedge Maze, Allotments ---------------------------------------------------------------
rect(-385, 295, -295, 385, "#3f7d3a", stroke="#25501f", sw=2)
for k in range(1, 6):
    rect(-385 + k * 15, 295 + (k % 2) * 20, -383 + k * 15, 385 - ((k + 1) % 2) * 20, "#9fd17e")
text(-340, 290, "Hedge Maze", 10)
rect(-480, 230, -400, 310, "#b9a06a", rx=4)
text(-440, 272, "Allotments", 10)
rect(-330, 400, -240, 460, "#f4a6c0", rx=12)
text(-285, 434, "Flower Beds", 10)
circle(-290, 470, 14, "#ffffff", stroke="#999", sw=2)
text(-290, 474, "Mill", 9)
rect(-260, 320, -200, 380, "#b6e2f2", opacity=0.6, rx=6)
text(-230, 354, "Sprinklers", 9)

# --- Ring road -------------------------------------------------------------------------------------------
text(0, -280, "RING ROAD (boost loop)", 11, "#fff")
for x, z in ((-150, -280), (150, -280), (-150, 280), (150, 280), (-280, -150), (-280, 150), (280, -150), (280, 150)):
    circle(x, z, 6, BOOST, stroke="#7a5200", sw=1)

# --- Neighbourhoods --------------------------------------------------------------------------------------
# NE Market Street and Roof Run
rect(40, -250, 250, -215, BLOCK, stroke="#9c8a6a", sw=1)
rect(40, -185, 250, -160, BLOCK, stroke="#9c8a6a", sw=1)
roofs = [(240, -232), (210, -232), (180, -232), (150, -232), (120, -232), (95, -232), (70, -232), (45, -232)]
for i, (x, z) in enumerate(roofs):
    rect(x - 11, z - 13, x + 11, z + 13, ROOF, stroke="#7a3f20", sw=1)
line([(x, z) for x, z in roofs], "#7a3f20", 2, dash="4 3")
line([(45, -232), (40, -150)], ROOF, 3, dash="3 3", marker=True)
text(150, -258, "Roof Run (8 roofs)", 10, anchor="middle")
rect(150, -205, 230, -190, "#e8c26f")
text(190, -194, "Market Street", 9)
# SE Car Park and Construction
rect(160, 160, 235, 245, "#a9adb8", stroke="#555", sw=2)
text(197, 205, "Car Park", 10)
text(197, 218, "3 decks", 8)
rect(165, 40, 245, 130, "#e9d27a", stroke="#b38f1a", sw=2, dash="6 3")
text(205, 88, "Building Site", 10)
line([(200, 160), (130, 110)], RAIL, 4, dash="6 3", marker=True)  # crane jib rail
# SW Terraces
for i in range(4):
    rect(-250 + i * 50, 170, -210 + i * 50, 200, BLOCK, stroke="#9c8a6a", sw=1)
    rect(-250 + i * 50, 215, -210 + i * 50, 245, BLOCK, stroke="#9c8a6a", sw=1)
rect(-250, 202, -60, 211, "#6d6d6d")
text(-155, 260, "Terraces and Cottages", 10)
# NW Station and Rail Yard
rect(-250, -240, -160, -170, "#c2b7a3", stroke="#776", sw=2)
for k in range(4):
    line([(-250, -160 + k * 6), (-40, -160 + k * 6)], "#6b4c3a", 1)
text(-205, -200, "Station", 10)
text(-205, -248, "Rail Yard", 10)

# --- Downtown core -----------------------------------------------------------------------------------------
for x0, z0, x1, z1, name in (
    (60, -140, 140, -60, "Glass Tower block"),
    (-140, -140, -60, -60, "Office block"),
    (60, 60, 140, 140, "Apartments"),
    (-140, 60, -60, 140, "Town Hall"),
):
    rect(x0, z0, x1, z1, "#8f9bb3", stroke="#4a5570", sw=2)
    text((x0 + x1) / 2, (z0 + z1) / 2 + 4, name, 9, "#fff")
circle(100, -100, 16, "#cfe8ff", stroke="#335", sw=2)
text(0, 4, "Plaza", 11)
circle(0, -14, 8, WATER)
rect(-145, -145, 145, 145, "none", stroke=RAIL, sw=3, rx=8, dash="10 6")
text(0, -128, "Sky Rail (y 30)", 9, RAIL)
text(0, 172, "Hoardings close Downtown until D 17", 9, "#b0401a")

# Spawns
spawns = []
for sx in (-1, 1):
    for sz in (-1, 1):
        spawns += [(sx * 180, sz * 440), (sx * 440, sz * 180), (sx * 450, sz * 450)]
for i, (x, z) in enumerate(sorted(spawns, key=lambda p: (p[1] > 0, p[0]))):
    circle(x, z, 9, SPAWN, stroke="#1d2433", sw=2)
    text(x, z + 4, str(i + 1), 10)

# Golden-object spots
for x, z in ((340, -340), (-340, 340), (-370, -380), (45, -232), (197, 205), (100, -100)):
    circle(x + 18, z - 18, 5, GOLD, stroke="#7a6200", sw=1)

# Legend
lx, lz = -495, 505
items = [
    (SPAWN, "spawn"),
    (GOLD, "golden spot"),
    (BOOST, "boost pad"),
    (RAIL, "rail / zipline"),
    (ROOF, "roof route"),
]
for i, (c, name) in enumerate(items):
    circle(lx + i * 120 + 6, lz + 18, 6, c, stroke="#333", sw=1)
    text(lx + i * 120 + 18, lz + 22, name, 11, anchor="start")

title = (
    '<text x="20" y="24" font-size="18" font-weight="700" fill="#1d2433" font-family="Montserrat,Arial,sans-serif">'
    "Park City: 1,000 x 1,000 studs, 12 spawns, eat inwards</text>"
)
W = (2 * HALF + 2 * PAD) * S
H = W + 40
svg = (
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -10 {W:.0f} {H:.0f}" width="{W:.0f}" height="{H:.0f}">'
    '<defs><marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto">'
    f'<path d="M0,0 L10,5 L0,10 z" fill="{RAIL}"/></marker></defs>'
    f'<rect x="0" y="-10" width="{W:.0f}" height="{H:.0f}" fill="#f6f3ea"/>'
    + "".join(shapes)
    + title
    + "</svg>"
)
out = Path(__file__).resolve().parent.parent / "docs" / "design" / "maps" / "park-city.svg"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(svg)
print(out)
