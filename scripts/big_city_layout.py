#!/usr/bin/env python3
"""Big City, concept stage: the districts, roads and spawns of the 2,400 x 2,400 map.

Writes docs/design/maps/big-city-layout.json and draws docs/design/maps/big-city.svg from it. This is the page the
owner approves before any district is filled; it holds no objects yet. Standard library only.

x is east, z is south, m = max(|x|, |z|) is the ring measure (as in Park City).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_JSON = ROOT / "docs/design/maps/big-city-layout.json"
OUT_SVG = ROOT / "docs/design/maps/big-city.svg"

HALF = 1200  # playable half extent
SCENERY = 1320  # scenery bound half extent
AVENUE = 20  # half width of the four avenues on the axes
INNER = (300, 340)  # Inner Ring road, m from - to
OUTER = (760, 800)  # Boulevard, m from - to
SIDE = 400  # the side districts span |x| or |z| < SIDE in the outer ring
BASE_SPEED, SPEED_CAP = 18, 32  # Config.baseSpeed, Config.speedCap
PARK_CITY_HALF = 500
PARK_CITY_OBJECTS = {"light": 4771, "part": 1251}

# id, name, ring, sign of x, sign of z (0 = centred on that axis), ball sizes, colour, what is special there.
DISTRICTS = [
    ("park_nw", "Woodland Park", "outer", -1, -1, (2, 14), "#8fc77a",
     "Start. The Giant Oak shakes food down for every size; a stream carries any ball towards the Boulevard."),
    ("park_ne", "Lake Park", "outer", 1, -1, (2, 14), "#7fc4a0",
     "Start. Lily pads for small balls, wading for big ones; the island fountain throws a ball to the Boulevard."),
    ("park_se", "Play Park", "outer", 1, 1, (2, 14), "#a5d16f",
     "Start. Skate bowl and half-pipes: launches that scale with the ball, courts full of balls and kit."),
    ("park_sw", "Gardens", "outer", -1, 1, (2, 14), "#9ccf8e",
     "Start. Low hedge maze a growing ball eats its way through; flower beds; the gnome army jackpot."),
    ("side_n", "Suburb", "outer", 0, -1, (8, 35), "#e6c58f",
     "Streets of houses. Each garden is a food ladder that ends with the house itself."),
    ("side_e", "Beach and Pier", "outer", 1, 0, (8, 35), "#f0dfa0",
     "Sandcastles, deckchairs, beach huts; the pier ends in a ramp over the water."),
    ("side_s", "Farm", "outer", 0, 1, (8, 35), "#d9cf7a",
     "Crop fields (dense light food), hay bales, tractors; the windmill sails fling a ball on a marked spot."),
    ("side_w", "Campsite Hill", "outer", -1, 0, (8, 35), "#b7c98a",
     "The only hill: tents and caravans on the slope, and a downhill run that is the fastest road on the map."),
    ("mid_nw", "Station and Rail Yard", "mid", -1, -1, (20, 80), "#c9b8a8",
     "A train runs a loop through the yard: food on wheels for a big ball, a hazard for a small one."),
    ("mid_ne", "Market and Old Town", "mid", 1, -1, (20, 80), "#e3b59a",
     "Narrow streets with the densest food on the map; stalls, vans, then the shops themselves."),
    ("mid_se", "Harbour", "mid", 1, 1, (20, 80), "#a9c3d6",
     "Container stacks, cranes that lift a ball from a marked pad, boats, and a ship as late food."),
    ("mid_sw", "Funfair and Stadium", "mid", -1, 1, (20, 80), "#e7a9c4",
     "Ferris wheel, bouncy castle, one roller-coaster rail, and the stadium bowl as a Feast arena."),
    ("downtown", "Downtown", "centre", 0, 0, (50, 200), "#b9bfd0",
     "Towers, the Plaza and the Glass Tower finale. Everyone ends up here in the last minute."),
]

SPAWN_OFFSETS = [(1000, 1000), (1000, 560), (560, 1000)]


def rect_of(ring: str, sx: int, sz: int) -> list[list[int]]:
    """The rectangles a district covers (an L-shaped district is two rectangles)."""
    if ring == "centre":
        return [[-INNER[0], -INNER[0], INNER[0], INNER[0]]]
    if ring == "mid":
        a, b = INNER[1], OUTER[0]
        full = [[AVENUE, AVENUE, b, b]]
        cut = [[AVENUE, a, b, b], [a, AVENUE, b, a]]
        rects = cut if a > AVENUE else full
        return [orient(r, sx, sz) for r in rects]
    a, b = OUTER[1], HALF
    if sx != 0 and sz != 0:  # corner park: an L round the corner
        return [orient(r, sx, sz) for r in ([SIDE, a, b, b], [a, SIDE, b, a])]
    if sx == 0:
        return [orient([-SIDE, a, SIDE, b], 1, sz)]
    return [orient([a, -SIDE, b, SIDE], sx, 1)]


def orient(r: list[int], sx: int, sz: int) -> list[int]:
    x0, z0, x1, z1 = r
    xs = sorted((x0 * sx, x1 * sx))
    zs = sorted((z0 * sz, z1 * sz))
    return [xs[0], zs[0], xs[1], zs[1]]


def area(rects: list[list[int]]) -> int:
    return sum((r[2] - r[0]) * (r[3] - r[1]) for r in rects)


def build() -> dict:
    districts = []
    for ident, name, ring, sx, sz, sizes, colour, special in DISTRICTS:
        rects = rect_of(ring, sx, sz)
        districts.append({"id": ident, "name": name, "ring": ring, "rects": rects, "area": area(rects),
                          "ballSizes": list(sizes), "colour": colour, "special": special})
    spawns = []
    for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        for ox, oz in SPAWN_OFFSETS:
            spawns.append({"slot": len(spawns) + 1, "x": ox * sx, "z": oz * sz})
    roads = [
        {"id": "inner_ring", "name": "Inner Ring", "ring": list(INNER)},
        {"id": "boulevard", "name": "Boulevard", "ring": list(OUTER)},
        {"id": "avenue_ns", "name": "North and South Avenue", "rect": [-AVENUE, -HALF, AVENUE, HALF]},
        {"id": "avenue_ew", "name": "East and West Avenue", "rect": [-HALF, -AVENUE, HALF, AVENUE]},
    ]
    side = HALF * 2
    park_side = PARK_CITY_HALF * 2
    ratio = (side * side) / (park_side * park_side)
    summary = {
        "playable": [side, side],
        "areaTimesParkCity": round(ratio, 2),
        "studsSquaredPerBall": side * side // 12,
        "crossingSeconds": {"atStart": round(side / BASE_SPEED), "atSpeedCap": round(side / SPEED_CAP)},
        "spawnToDowntownSeconds": round((1000 - INNER[0]) / SPEED_CAP),
        "objectsAtParkCityDensity": {k: round(v * ratio) for k, v in PARK_CITY_OBJECTS.items()},
        "districtArea": {d["id"]: d["area"] for d in districts},
    }
    return {"version": 0, "stage": "concept", "units": "studs",
            "world": {"halfExtent": HALF, "sceneryHalfExtent": SCENERY}, "roads": roads, "districts": districts,
            "spawns": spawns, "summary": summary}


def render(layout: dict) -> str:
    s = layout["world"]["sceneryHalfExtent"]
    h = layout["world"]["halfExtent"]
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-s} {-s} {2 * s} {2 * s}" '
           f'font-family="Helvetica, Arial, sans-serif">',
           f'<rect x="{-s}" y="{-s}" width="{2 * s}" height="{2 * s}" fill="#dfe8d8"/>',
           f'<rect x="{-h}" y="{-h}" width="{2 * h}" height="{2 * h}" fill="#6f7480"/>']
    for d in layout["districts"]:
        for x0, z0, x1, z1 in d["rects"]:
            out.append(f'<rect x="{x0}" y="{z0}" width="{x1 - x0}" height="{z1 - z0}" fill="{d["colour"]}"/>')
    for road in layout["roads"]:  # the avenues run through the outer ring to the map edge
        if "rect" in road:
            x0, z0, x1, z1 = road["rect"]
            out.append(f'<rect x="{x0}" y="{z0}" width="{x1 - x0}" height="{z1 - z0}" fill="#6f7480"/>')
    for d in layout["districts"]:
        big = max(d["rects"], key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
        cx, cz = (big[0] + big[2]) / 2, (big[1] + big[3]) / 2
        if d["ring"] == "outer" and len(d["rects"]) == 2:  # a corner park: label in the corner itself
            cx = 1000 if big[2] > 0 else -1000
            cz = 1130 if big[3] > 0 else -1110
        if d["ring"] == "mid":
            cx = 550 if cx > 0 else -550
            cz = 640 if cz > 0 else -640
        if cx == 0:  # keep the label off the avenue it straddles
            cx = 160
        if cz == 0:
            cz = -120
        lo, hi = d["ballSizes"]
        out.append(f'<text x="{cx}" y="{cz - 8}" text-anchor="middle" font-size="46" font-weight="bold" '
                   f'fill="#1f2430">{d["name"]}</text>')
        out.append(f'<text x="{cx}" y="{cz + 40}" text-anchor="middle" font-size="36" fill="#1f2430">'
                   f'ball {lo} to {hi}</text>')
    p = PARK_CITY_HALF
    out.append(f'<rect x="{-p}" y="{-p}" width="{2 * p}" height="{2 * p}" fill="none" stroke="#c0392b" '
               f'stroke-width="6" stroke-dasharray="24 16"/>')
    out.append(f'<text x="0" y="{-p - 16}" text-anchor="middle" font-size="34" fill="#c0392b">'
               f'Park City today (1,000 x 1,000), same scale</text>')
    for spawn in layout["spawns"]:
        out.append(f'<circle cx="{spawn["x"]}" cy="{spawn["z"]}" r="22" fill="#ffd23c" stroke="#1f2430" '
                   f'stroke-width="5"/>')
    out.append(f'<text x="{-h}" y="{h + 70}" font-size="40" fill="#1f2430">Big City concept: '
               f'{2 * h:,} x {2 * h:,} studs. Yellow dots: the 12 spawns. Grey: roads.</text>')
    out.append("</svg>")
    return "\n".join(out) + "\n"


def main() -> int:
    layout = build()
    text = json.dumps(layout, indent=1) + "\n"
    svg = render(layout)
    if "--check" in sys.argv:
        ok = OUT_JSON.exists() and OUT_JSON.read_text() == text and OUT_SVG.exists() and OUT_SVG.read_text() == svg
        print("big city layout is up to date" if ok else "big city layout is STALE: run scripts/big_city_layout.py")
        return 0 if ok else 1
    OUT_JSON.write_text(text)
    OUT_SVG.write_text(svg)
    print(json.dumps(layout["summary"], indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
