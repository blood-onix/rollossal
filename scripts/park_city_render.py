#!/usr/bin/env python3
"""Draw the Park City map references from docs/design/maps/park-city-layout.json (stdlib only).

Every picture is a view of the same data, so the zone maps, close-ups and the overview always agree with each other and
with what feature 012 builds. Run scripts/park_city_layout.py first, then this.

Run: python3 scripts/park_city_render.py
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPS = ROOT / "docs" / "design" / "maps"
L = json.loads((MAPS / "park-city-layout.json").read_text())

TIER_COLOR = {1: "#f4c430", 2: "#f08a24", 3: "#e0453a", 4: "#8e44ad", 5: "#2f6fd6", 6: "#1d2433"}
TIER_NAME = {1: "Crumb", 2: "Pocket", 3: "Picnic", 4: "Street", 5: "House", 6: "Skyline"}
BLOCK_STYLE = {
    "grass": ("#a6d785", None), "road": ("#5b616e", None), "pavement": ("#d6d0c2", None), "plaza": ("#c5ccd9", None),
    "gravel": ("#e9dcb4", None), "woods": ("#7fb36a", None), "hedge": ("#3f7d3a", "#25501f"), "roof": ("#e39b6e", "#7a3f20"),
    "deck": ("#b4b8c2", "#555"), "ramp": ("#cbb89a", "#7a6a4a"), "building": ("#e8d9bf", "#9c8a6a"), "track": ("#7a5a46", None),
    "island": ("#d8c48a", "#8a7a40"), "jetty": ("#9b7146", None), "bowl": ("#a9a9b4", "#666"), "tunnel": ("#6b4c2a", None),
    "hoarding": ("#e0662f", None), "sand": ("#f1dfa4", "#c2a95a"), "glass": ("#bfe3f2", "#5a8aa0"), "tower": ("#d98b5f", "#7a3f20"),
    "log_platform": ("#8a5a2b", None), "stone": ("#9a9a9a", None), "bridge": ("#9b7146", None), "box": ("#b9b9c4", "#666"),
    "tree_trunk": ("#5a3b22", "#2e1d10"), "railing": (None, "#2e5d2a"), "wall": (None, None),
}


class View:
    def __init__(self, name, title, x0, z0, x1, z1, scale, detail=True, labels=True, note=""):
        self.name, self.title, self.note = name, title, note
        self.x0, self.z0, self.x1, self.z1, self.s = x0, z0, x1, z1, scale
        self.detail, self.labels = detail, labels
        self.out: list[str] = []
        self.pad, self.top = 30, 60

    def X(self, x):
        return (x - self.x0) * self.s + self.pad

    def Z(self, z):
        return (z - self.z0) * self.s + self.top

    def inside(self, x, z, margin=0):
        return self.x0 - margin <= x <= self.x1 + margin and self.z0 - margin <= z <= self.z1 + margin

    def add(self, el):
        self.out.append(el)

    def rect(self, x0, z0, x1, z1, fill, stroke=None, sw=1, op=1.0, dash=None):
        x0, x1 = max(min(x0, x1), self.x0 - 5), min(max(x0, x1), self.x1 + 5)
        z0, z1 = max(min(z0, z1), self.z0 - 5), min(max(z0, z1), self.z1 + 5)
        if x1 <= x0 or z1 <= z0:
            return
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.add(f'<rect x="{self.X(x0):.1f}" y="{self.Z(z0):.1f}" width="{(x1 - x0) * self.s:.1f}" height="{(z1 - z0) * self.s:.1f}" '
                 f'fill="{fill or "none"}" opacity="{op}"{st}{d}/>')

    def poly(self, pts, fill="none", stroke="#000", sw=1, op=1.0, dash=None, closed=True, marker=False):
        p = " ".join(f"{self.X(x):.1f},{self.Z(z):.1f}" for x, z in pts)
        d = f' stroke-dasharray="{dash}"' if dash else ""
        m = ' marker-end="url(#arr)"' if marker else ""
        tag = "polygon" if closed else "polyline"
        self.add(f'<{tag} points="{p}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" opacity="{op}" '
                 f'stroke-linejoin="round" stroke-linecap="round"{d}{m}/>')

    def circle(self, x, z, r_px, fill, stroke=None, sw=1, op=1.0):
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        self.add(f'<circle cx="{self.X(x):.1f}" cy="{self.Z(z):.1f}" r="{r_px:.2f}" fill="{fill}" opacity="{op}"{st}/>')

    def text(self, x, z, s, size=11, fill="#1d2433", anchor="middle", weight="600", halo=True):
        s = str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        h = ' paint-order="stroke" stroke="#fff" stroke-width="3" stroke-linejoin="round"' if halo else ""
        self.add(f'<text x="{self.X(x):.1f}" y="{self.Z(z):.1f}" font-size="{size}" font-weight="{weight}" fill="{fill}" '
                 f'text-anchor="{anchor}" font-family="Montserrat,Arial,sans-serif"{h}>{s}</text>')

    def rot_rect(self, cx, cz, w, d, yaw, **kw):
        a = math.radians(yaw)
        fx, fz = math.sin(a), -math.cos(a)
        rx, rz = math.cos(a), math.sin(a)
        pts = []
        for u, v in ((-0.5, 0.5), (0.5, 0.5), (0.5, -0.5), (-0.5, -0.5)):  # v + = front
            pts.append((cx + u * w * rx + v * d * fx, cz + u * w * rz + v * d * fz))
        self.poly(pts, **kw)
        return pts

    def svg(self):
        W = (self.x1 - self.x0) * self.s + 2 * self.pad
        H = (self.z1 - self.z0) * self.s + self.top + 110
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W:.0f} {H:.0f}" width="{W:.0f}" height="{H:.0f}">'
                '<defs><marker id="arr" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="5" markerHeight="5" orient="auto">'
                '<path d="M0,0 L10,5 L0,10 z" fill="#d6246e"/></marker>'
                f'<clipPath id="clip"><rect x="{self.pad}" y="{self.top}" width="{(self.x1 - self.x0) * self.s:.0f}" '
                f'height="{(self.z1 - self.z0) * self.s:.0f}"/></clipPath></defs>'
                f'<rect width="{W:.0f}" height="{H:.0f}" fill="#f7f4ec"/>'
                f'<text x="{self.pad}" y="26" font-size="18" font-weight="700" fill="#1d2433" font-family="Montserrat,Arial,sans-serif">{self.title}</text>'
                f'<text x="{self.pad}" y="46" font-size="12" fill="#55606e" font-family="Montserrat,Arial,sans-serif">'
                f'x {self.x0} to {self.x1}, z {self.z0} to {self.z1} (z south is down). 1 grid square = {self.grid()} studs. {self.note}</text>'
                '<g clip-path="url(#clip)">')
        legend = self.legend(H - 95, W)
        return head + "".join(self.out) + "</g>" + legend + "</svg>"

    def grid(self):
        span = max(self.x1 - self.x0, self.z1 - self.z0)
        return 100 if span > 600 else 50 if span > 250 else 20 if span > 120 else 10

    def legend(self, y, W):
        parts = []
        x = self.pad
        for t in range(1, 7):
            parts.append(f'<circle cx="{x + 6}" cy="{y + 8}" r="6" fill="{TIER_COLOR[t]}"/>'
                         f'<text x="{x + 16}" y="{y + 12}" font-size="11" font-family="Montserrat,Arial,sans-serif" fill="#1d2433">'
                         f'T{t} {TIER_NAME[t]}</text>')
            x += 100
        y2 = y + 28
        x = self.pad
        sym = [
            ('<circle cx="{x}" cy="{y}" r="7" fill="#fff" stroke="#1d2433" stroke-width="2"/>', "spawn"),
            ('<rect x="{x0}" y="{y0}" width="12" height="9" fill="#ffb020" stroke="#7a5200"/>', "boost pad"),
            ('<circle cx="{x}" cy="{y}" r="6" fill="#59c27a" stroke="#1f6b3a"/>', "bounce / lily pad"),
            ('<circle cx="{x}" cy="{y}" r="6" fill="#4cc9f0" stroke="#1b6f8a"/>', "spring pad"),
            ('<line x1="{x0}" y1="{y}" x2="{x1}" y2="{y}" stroke="#d6246e" stroke-width="3"/>', "rail / zipline"),
            ('<polygon points="{tri}" fill="#8a5a2b"/>', "catapult"),
            ('<circle cx="{x}" cy="{y}" r="6" fill="#ffd700" stroke="#7a6200"/>', "golden spot"),
            ('<circle cx="{x}" cy="{y}" r="6" fill="none" stroke="#7a4fd0" stroke-width="2" stroke-dasharray="3 2"/>', "hazard"),
        ]
        for tpl, name in sym:
            cx, cy = x + 7, y2 + 7
            parts.append(tpl.format(x=cx, y=cy, x0=cx - 6, y0=cy - 4, x1=cx + 8, tri=f"{cx - 6},{cy + 6} {cx + 6},{cy + 6} {cx},{cy - 6}")
                         + f'<text x="{x + 18}" y="{y2 + 11}" font-size="11" font-family="Montserrat,Arial,sans-serif" fill="#1d2433">{name}</text>')
            x += 128
        y3 = y2 + 30
        parts.append(f'<text x="{self.pad}" y="{y3 + 10}" font-size="11" fill="#55606e" font-family="Montserrat,Arial,sans-serif">'
                     'Scenes: thin outline, the thick edge is the FRONT (small things spill to the front, the big thing stands at the back). '
                     'Dots: objects at their real bulk, coloured by tier. Dashed lines: trails. Data: docs/design/maps/park-city-layout.json</text>')
        return "".join(parts)


def draw(v: View):
    # Grid
    g = v.grid()
    for x in range(int(math.floor(v.x0 / g) * g), int(v.x1) + 1, g):
        v.add(f'<line x1="{v.X(x):.1f}" y1="{v.Z(v.z0):.1f}" x2="{v.X(x):.1f}" y2="{v.Z(v.z1):.1f}" stroke="#000" stroke-opacity="0.07"/>')
    for z in range(int(math.floor(v.z0 / g) * g), int(v.z1) + 1, g):
        v.add(f'<line x1="{v.X(v.x0):.1f}" y1="{v.Z(z):.1f}" x2="{v.X(v.x1):.1f}" y2="{v.Z(z):.1f}" stroke="#000" stroke-opacity="0.07"/>')
    # Blocks (ground first, by area, largest first)
    blocks = sorted(L["blocks"], key=lambda b: -abs((b["rect"][2] - b["rect"][0]) * (b["rect"][3] - b["rect"][1])))
    for b in blocks:
        fill, stroke = BLOCK_STYLE.get(b["kind"], ("#ccc", "#888"))
        x0, z0, x1, z1 = b["rect"]
        if b["kind"] == "wall":
            continue
        if b["kind"] == "spiral":
            cx, cz, r = (x0 + x1) / 2, (z0 + z1) / 2, (x1 - x0) / 2
            v.circle(cx, cz, r * v.s, "none", "#a08660", max(2, 8 * v.s * 0.8), op=0.55)
            if v.labels and v.s >= 3:
                v.text(cx, cz + r + 8, b["label"], 10, "#3a2a1a")
            continue
        if b["kind"] == "railing":
            v.rect(x0, z0, x1, z1, None, stroke, 2, dash="6 3")
            continue
        v.rect(x0, z0, x1, z1, fill, stroke, 1)
        if v.labels and b.get("label") and v.s >= 3 and b["kind"] not in ("grass", "pavement", "plaza", "road", "gravel", "woods"):
            cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
            if v.inside(cx, cz):
                v.text(cx, cz + 3, b["label"], 9 if v.s < 5 else 11, "#3a2a1a")
    # Water
    for w in L["water"]:
        if "ellipse" in w:
            cx, cz, rx, rz = w["ellipse"]
            v.add(f'<ellipse cx="{v.X(cx):.1f}" cy="{v.Z(cz):.1f}" rx="{rx * v.s:.1f}" ry="{rz * v.s:.1f}" fill="#6cc3e8" stroke="#3a8fb7" stroke-width="2"/>')
            if v.s >= 3:
                v.add(f'<ellipse cx="{v.X(cx):.1f}" cy="{v.Z(cz):.1f}" rx="{22 * v.s:.1f}" ry="{22 * v.s:.1f}" fill="none" stroke="#fff" stroke-dasharray="4 3" opacity="0.8"/>')
        else:
            x0, z0, x1, z1 = w["rect"]
            col = "#9fdcf0" if w["kind"] == "wading" else "#cdeff8"
            v.rect(x0, z0, x1, z1, col, "#3a8fb7" if w["kind"] == "wading" else "#7ab", 1, op=0.9)
            if w["kind"] == "slick" and v.s >= 2:
                v.text((x0 + x1) / 2, (z0 + z1) / 2, "wet grass (slick)", 10, "#2a6f8a")
    # Tunnels and drains (small only)
    for tn in L.get("tunnels", []):
        v.poly(tn["points"], stroke="#6b4c2a", sw=max(2, tn["width"] * v.s), closed=False, op=0.8)
        if v.labels and v.s >= 3:
            (ax, az) = tn["points"][0]
            v.text(ax, az + 6, f"{tn['id'].replace('_', ' ')}: {tn['note']}", 10, "#6b4c2a")
    # Re-draw the island above the pond
    for b in L["blocks"]:
        if b["kind"] in ("island", "jetty"):
            fill, stroke = BLOCK_STYLE[b["kind"]]
            v.rect(*b["rect"], fill, stroke, 1)
    # Landmarks and buildings (footprints from dims)
    for lm in L["landmarks"]:
        dims = L["objects"][lm["object"]]["dims"]
        if not v.inside(lm["x"], lm["z"], 60):
            continue
        l, w = dims[0], dims[1]
        v.rot_rect(lm["x"], lm["z"], l, w, lm.get("yaw", 0), fill=TIER_COLOR[lm["tier"]], stroke="#1d2433", sw=1, op=0.35)
        key = {"glass_tower", "giant_oak", "giant_duck", "ferris_wheel", "windmill", "car_park", "station_hall"}
        if v.labels and (v.s >= 2 or lm["object"] in key):
            name = lm["object"].replace("_", " ")
            if name.startswith("roof building"):
                name = "roof building"
            v.text(lm["x"], lm["z"] + 3, f"{name} (D {lm['needsD']:.0f})", 9 if v.s < 4 else 11, "#1d2433")
    # Hazards
    for h in L["hazards"]:
        if "path" in h:
            v.poly(h["path"], stroke="#7a4fd0", sw=2, dash="6 4")
            x, z = h["path"][0]
            if v.inside(x, z) and v.labels:
                v.text(x, z - 3, f"{h['id']} (food from D {h.get('eatenFromD', '?')})", 10, "#7a4fd0")
        elif "radius" in h:
            v.circle(h["x"], h["z"], h["radius"] * v.s, "none", "#7a4fd0", 2)
            if v.labels and v.s >= 2:
                v.text(h["x"], h["z"] - h["radius"] - 2, f"{h['id']} (spins; flings D < {h['flingsBelowD']})", 10, "#7a4fd0")
    # Scenes
    for sc in L["scenes"]:
        if not v.inside(sc["x"], sc["z"], 40):
            continue
        w, d = sc["footprint"]
        if sc["kind"] != "floating" and v.detail:
            pts = v.rot_rect(sc["x"], sc["z"], w, d, sc["yaw"], fill="#ffffff", stroke="#6b5b3a", sw=0.8, op=0.45)
            # front edge
            v.poly([pts[0], pts[1]], stroke="#6b5b3a", sw=2.5, closed=False)
        for it in sc["items"]:
            r = max(it["bulk"] / 2 * v.s, 0.9 if v.s < 2 else 1.4)
            v.circle(it["x"], it["z"], r, TIER_COLOR[it["tier"]], "#00000055" if v.s >= 4 else None, 0.5)
        if v.labels and sc.get("label") and v.s >= 1.5:
            v.text(sc["x"], sc["z"] - d / 2 - 2, sc["label"], 9 if v.s < 4 else 11, "#4a3a1a")
    # Trails
    for t in L["trails"]:
        if v.detail:
            v.poly(t["points"], stroke="#8a6a2a", sw=1, dash="3 4", closed=False, op=0.6)
        for it in t["items"]:
            if v.inside(it["x"], it["z"], 5):
                r = max(it["bulk"] / 2 * v.s, 0.9 if v.s < 2 else 1.4)
                v.circle(it["x"], it["z"], r, TIER_COLOR[it["tier"]], "#00000055" if v.s >= 4 else None, 0.5)
    # Rails
    for r in L["rails"]:
        pts = [(p[0], p[2]) for p in r["points"]]
        v.poly(pts, stroke="#d6246e", sw=max(2, 1.2 * v.s ** 0.5), closed=False, marker=r["exit"] == "launch" and len(pts) == 2)
        mx, mz = pts[0]
        grouped = r["id"][-1] in "bcd" and r["id"][:-1] in ("R7", "R3", "R5")
        if v.labels and v.inside(mx, mz) and not grouped:
            v.text(mx, mz - 3, f"{r['id']} {r['name']} (D {r['dMin']}-{r['dMax']})", 10 if v.s < 4 else 12, "#d6246e")
    # Pads
    for p in L["pads"]:
        if not v.inside(p["x"], p["z"], 10):
            continue
        w, d = p["size"]
        if p["kind"] == "boost":
            v.rot_rect(p["x"], p["z"], w, d, p["yaw"], fill="#ffb020", stroke="#7a5200", sw=1)
            a = math.radians(p["yaw"])
            v.poly([(p["x"], p["z"]), (p["x"] + math.sin(a) * d * 0.6, p["z"] - math.cos(a) * d * 0.6)], stroke="#7a5200", sw=2, closed=False)
        elif p["kind"] in ("bounce", "platform"):
            v.circle(p["x"], p["z"], max(w / 2 * v.s, 3), "#59c27a", "#1f6b3a", 1)
        elif p["kind"] == "spring":
            v.circle(p["x"], p["z"], max(w / 2 * v.s, 3), "#4cc9f0", "#1b6f8a", 1)
        elif p["kind"] == "bullseye":
            v.circle(p["x"], p["z"], max(w / 2 * v.s, 3), "none", "#d62828", 2)
            v.circle(p["x"], p["z"], max(w / 6 * v.s, 1.5), "#d62828")
    # Catapults
    for c in L["catapults"]:
        if not v.inside(c["x"], c["z"], 20):
            continue
        a0 = math.radians(c["restYaw"] - c["aimArc"])
        a1 = math.radians(c["restYaw"] + c["aimArc"])
        reach = 60
        arc = [(c["x"], c["z"])]
        for k in range(13):
            a = a0 + (a1 - a0) * k / 12
            arc.append((c["x"] + math.sin(a) * reach, c["z"] - math.cos(a) * reach))
        v.poly(arc, fill="#8a5a2b", stroke="#8a5a2b", sw=1, op=0.12)
        s = 7 if c["kind"] == "catapult" else 10
        v.poly([(c["x"] - s / 2, c["z"] + s / 2), (c["x"] + s / 2, c["z"] + s / 2), (c["x"], c["z"] - s / 2)], fill="#8a5a2b", stroke="#3a2010")
        if v.labels:
            v.text(c["x"], c["z"] + s + 6, f"{c['id']} {c['kind'].replace('_', ' ')} (D {c['dMin']}-{c['dMax']})", 10, "#5a3a1a")
    # Golden spots
    for gs in L["golden"]:
        v.circle(gs["x"], gs["z"], max(3 * v.s ** 0.5, 4), "#ffd700", "#7a6200", 1)
    # Spawns
    for s in L["spawns"]:
        if v.inside(s["x"], s["z"], 10):
            if v.s >= 8:  # close-ups: the real starting ball (D 1) for scale
                v.circle(s["x"], s["z"], 0.5 * v.s, "#ffffff", "#1d2433", 2)
                v.text(s["x"], s["z"] - 1.5, "start ball, D 1", 12)
            else:
                v.circle(s["x"], s["z"], max(4 * v.s, 8), "#ffffff", "#1d2433", 2, op=0.9)
                v.text(s["x"], s["z"] + 4, s["id"][-2:].lstrip("0"), 11 if v.s < 3 else 14)
            v.circle(s["x"], s["z"], 35 * v.s, "none", "#1d2433", 0.6, op=0.4)
    # Zone names on the overview
    if not v.detail:
        for zn in L["zones"]:
            x0, z0, x1, z1 = zn["rect"]
            cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
            if zn["id"].startswith("park"):
                cx, cz = x0 * 0.0 + (x0 + x1) / 2 * 1.55, (z0 + z1) / 2 * 1.55
            if zn["id"] == "ring_road":
                cx, cz = 0, -280
            v.text(cx, cz, zn["name"], 13, "#1d2433", weight="700")


def elevation_roof_run():
    rr = L["roofRun"]
    s, pad, top = 4.0, 30, 60
    x_hi, x_lo = 280, 20
    W = (x_hi - x_lo) * s + 2 * pad
    H = 40 * s + top + 70
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W:.0f} {H:.0f}" width="{W:.0f}" height="{H:.0f}">',
           '<defs><marker id="arr" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#d6246e"/></marker></defs>',
           f'<rect width="{W:.0f}" height="{H:.0f}" fill="#f7f4ec"/>',
           f'<text x="{pad}" y="26" font-size="18" font-weight="700" fill="#1d2433" font-family="Montserrat,Arial,sans-serif">Roof Run: side view, looking north (east on the left)</text>',
           f'<text x="{pad}" y="46" font-size="12" fill="#55606e" font-family="Montserrat,Arial,sans-serif">Roofs 18 wide; gaps sized for a D 8 tap jump (70 %); gap 7 is the brave gap (boost pad before it). y in studs.</text>']

    def X(x):
        return (x_hi - x) * s + pad

    def Y(y):
        return top + (40 - y) * s

    out.append(f'<line x1="{X(x_hi)}" y1="{Y(0)}" x2="{X(x_lo)}" y2="{Y(0)}" stroke="#5b616e" stroke-width="3"/>')
    for y in (10, 20, 30):
        out.append(f'<line x1="{X(x_hi)}" y1="{Y(y)}" x2="{X(x_lo)}" y2="{Y(y)}" stroke="#000" stroke-opacity="0.08"/>'
                   f'<text x="{X(x_hi) - 4}" y="{Y(y) + 4}" font-size="10" text-anchor="end" font-family="Arial">y {y}</text>')
    out.append(f'<polygon points="{X(275)},{Y(0)} {X(254)},{Y(10)} {X(254)},{Y(0)}" fill="#cbb89a" stroke="#7a6a4a"/>'
               f'<text x="{X(268)}" y="{Y(-3) + 14}" font-size="10" font-family="Arial">delivery ramp</text>')
    prev = None
    for k, r in enumerate(rr["roofs"]):
        x0, x1 = r["x"] - 9, r["x"] + 9
        out.append(f'<rect x="{X(x1)}" y="{Y(r["y"])}" width="{18 * s}" height="{r["y"] * s}" fill="#e39b6e" stroke="#7a3f20"/>'
                   f'<text x="{X(r["x"])}" y="{Y(r["y"]) - 4}" font-size="11" text-anchor="middle" font-weight="700" font-family="Arial">{k + 1}</text>')
        if prev is not None:
            gap = rr["gaps"][k - 1]
            col = "#d62828" if k == rr["braveGap"] else "#1d2433"
            out.append(f'<text x="{X((prev + x1) / 2)}" y="{Y(2)}" font-size="11" text-anchor="middle" fill="{col}" font-family="Arial" font-weight="700">{gap:g}</text>')
        prev = x0
    out.append(f'<rect x="{X(85 - 9 - 0) - 12}" y="{Y(18) - 4}" width="10" height="4" fill="#ffb020" stroke="#7a5200"/>')
    out.append(f'<polygon points="{X(56)},{Y(20)} {X(38)},{Y(26)} {X(38)},{Y(20)}" fill="#cbb89a" stroke="#7a6a4a"/>')
    out.append(f'<path d="M {X(38)} {Y(26)} Q {X(26)} {Y(40)} {X(20)} {Y(10)}" fill="none" stroke="#d6246e" stroke-width="2" stroke-dasharray="5 3" marker-end="url(#arr)"/>'
               f'<text x="{X(40)}" y="{Y(33)}" font-size="10" font-family="Arial" fill="#d6246e">billboard ramp: over the hoardings to the Plaza</text>')
    out.append(f'<text x="{pad}" y="{H - 20}" font-size="11" fill="#55606e" font-family="Arial">Gap widths in studs under each gap. Up: the delivery ramp, or the spring pad in Market Street at x 165. A fall lands in Market Street (y 0.3) with nothing lost.</text>')
    out.append("</svg>")
    (MAPS / "zone-nbh-ne-roofrun-side.svg").write_text("".join(out))


VIEWS = [
    View("park-city", "Park City overview: 1,000 x 1,000 studs, 12 spawns, eat inwards", -510, -510, 510, 510, 1.0, detail=False),
    View("zone-park-nw", "Park NW: Woods and Campsite (Tiers 1-3)", -505, -505, -255, -15, 2.2),
    View("zone-park-ne", "Park NE: Pond and Boathouse (Tiers 1-3)", 15, -505, 505, -15, 2.0),
    View("zone-park-se", "Park SE: Playground, Skate Park and Courts (Tiers 1-3)", 15, 15, 505, 505, 2.0),
    View("zone-park-sw", "Park SW: Gardens and Hedge Maze (Tiers 1-3)", -505, 15, -15, 505, 2.0),
    View("zone-ring-gate-n", "Ring Road: the north gate corner (Tiers 2-4)", -80, -345, 80, -235, 6.0),
    View("zone-nbh-ne", "Neighbourhood NE: Market Street and the Roof Run (Tiers 3-5)", 20, -265, 280, -140, 4.0),
    View("zone-nbh-se", "Neighbourhood SE: Car Park and Building Site (Tiers 4-5)", 135, 15, 265, 265, 4.0),
    View("zone-nbh-sw", "Neighbourhood SW: Terraces and Cottages (Tiers 3-5)", -270, 140, -15, 265, 4.0),
    View("zone-nbh-nw", "Neighbourhood NW: Station and Rail Yard (Tiers 3-5)", -265, -265, -15, -125, 4.0),
    View("zone-downtown", "Downtown (Tiers 5-6)", -160, -160, 160, 160, 3.0),
    View("detail-doorstep", "Close-up: spawn 1 doorstep (acorn fall), first 10 seconds", -480, -480, -410, -410, 12.0),
    View("detail-glade-oak", "Close-up: Mushroom Glade, Giant Oak, root tunnels, stream", -480, -480, -295, -260, 4.5),
    View("detail-duck-island", "Close-up: Duck Island and its three routes", 255, -410, 425, -265, 5.0),
    View("detail-hedge-maze", "Close-up: Hedge Maze (corridors 6 wide; walls are food from D 4.8)", -392, 288, -288, 392, 8.0),
    View("detail-skate-playground", "Close-up: Playground and Skate Park", 290, 195, 410, 400, 4.5),
]


def main():
    for v in VIEWS:
        draw(v)
        (MAPS / f"{v.name}.svg").write_text(v.svg())
    elevation_roof_run()
    print("\n".join(sorted(p.name for p in MAPS.glob("*.svg"))))


if __name__ == "__main__":
    main()
