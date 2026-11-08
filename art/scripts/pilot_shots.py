# The Stage A pilot QA image set (013 Phase 9, T072): tile sheets (street-level and top) in city and winter, a short
# main-street block and a suburb corner per theme at ball sizes D1 and D5, and the before/after stacks. The streets are
# assembled from the pilot meshes at real spacing (style bible sections 6 and 7: road darker than sidewalk, 0.4-stud kerb,
# lamps every 24 studs, trees between them, cars along their lane, hydrants and bins facing the road).
# Run through the Blender MCP after art/scripts/kit_rework.py:
#   PARAMS = {"root": "<repo root>"}
#   exec(open(PARAMS["root"] + "/art/scripts/pilot_shots.py").read()); run_pilot(PARAMS)
# Writes into specs/013-city-asset-kit/contact-sheets/pilot/. The "before" tiles (_before_<theme>.png) are rendered once,
# before the rework, by street_shots.py with "lighting": "before" and are not rewritten here.

import json
import os

PILOT = ["ck_house_gable_fence", "ck_shop_row_three", "ck_tower_slab", "ck_car_sedan", "ck_tree_oak",
         "ck_street_lamp_double", "ck_bin_street", "dt_fire_hydrant"]


def hexrgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def ground_colours(root, theme):
    tokens = json.load(open(os.path.join(root, "docs", "design", "tokens.json"), encoding="utf-8"))
    out = {}
    for t in tokens["color"]["tokens"] + tokens["color"]["hero"]:
        v = t.get("value")
        if isinstance(v, dict):
            out[t["name"]] = hexrgb(v.get(theme, v["city"]))
    return out


def main_street(theme, c):
    """Road along x (y -12..12): two traffic lanes and parking lanes, kerbs, 10-stud sidewalks; a shop row and the
    tower on the north side (fronts facing the road), lamps, trees, a bin, a hydrant and parked cars."""
    g = []
    g.append([-120, -12, 120, 12, -0.05, 0.0, c["w-asphalt"]])
    g.append([-120, -0.25, 120, 0.25, 0.0, 0.02, c["w-road-line"]])
    if theme == "winter":
        g += [[-120, 8.0, 120, 12, 0.0, 0.01, c["w-road-slush"]], [-120, -12, 120, -8.0, 0.0, 0.01, c["w-road-slush"]],
              [-120, 2.5, 120, 4.2, 0.0, 0.012, c["w-road-slush"]], [-120, -4.2, 120, -2.5, 0.0, 0.012, c["w-road-slush"]]]
    for sy in (1, -1):
        y0, y1 = (12, 12.5) if sy > 0 else (-12.5, -12)
        g.append([-120, y0, 120, y1, -0.05, 0.4, c["w-kerb"]])
        y0, y1 = (12.5, 22) if sy > 0 else (-22, -12.5)
        g.append([-120, y0, 120, y1, -0.05, 0.4, c["w-sidewalk"]])
        y0, y1 = (22, 70) if sy > 0 else (-70, -22)
        g.append([-120, y0, 120, y1, -0.05, 0.38, c["w-pavement-stained"]])
    lift = 0.4
    items = [["ck_shop_row_three", 2.0, 22.0 + 24.7 / 2 - 4.4, 180], ["ck_tower_slab", -33.0, 22.0 + 19.0 / 2 - 4.0, 180]]
    for x in (-36, -12, 12, 36, 60):
        items.append(["ck_street_lamp_double", x, 14.0, 0])
        items.append(["ck_street_lamp_double", x + 12, -14.0, 0])
    for x in (-24, 0, 24, 48):
        items.append(["ck_tree_oak", x, 15.5, 0])
        items.append(["ck_tree_oak", x + 12, -15.5, 30])
    items += [["ck_bin_street", -6.0, 14.0, 180], ["dt_fire_hydrant", 17.0, 13.6, 180], ["ck_bin_street", 30.0, -14.0, 0],
              ["ck_car_sedan", -20.0, 8.6, 0], ["ck_car_sedan", 9.0, 8.6, 0], ["ck_car_sedan", 40.0, -8.6, 180]]
    lifts = {i[0]: lift for i in items if i[0] not in ("ck_car_sedan",)}
    return g, items, lifts


def suburb_corner(theme, c):
    """Two residential streets meeting at a corner (x and y axes, 16 studs wide), 5-stud sidewalks; three houses on the
    north-east block with gardens toward the street, a corner lamp, trees, a hydrant at the corner, a bin and a car."""
    g = [[-120, -8, 120, 8, -0.05, 0.0, c["w-asphalt"]], [-8, -120, 8, 120, -0.05, 0.0, c["w-asphalt"]]]
    if theme == "winter":
        g += [[-120, 5.5, 120, 8, 0.0, 0.01, c["w-road-slush"]], [5.5, -120, 8, 120, 0.0, 0.012, c["w-road-slush"]]]
    for x0, y0, x1, y1 in ((8, 8, 120, 120), (-120, 8, -8, 120), (8, -120, 120, -8), (-120, -120, -8, -8)):
        g.append([x0, y0, x1, y1, -0.05, 0.3, c["w-kerb"]])
        sx = 0.4 if x0 > 0 else -0.4
        sy = 0.4 if y0 > 0 else -0.4
        g.append([x0 + (sx if x0 > 0 else 0), y0 + (sy if y0 > 0 else 0), x1 + (sx if x1 < 0 else 0),
                  y1 + (sy if y1 < 0 else 0), -0.05, 0.38, c["w-sidewalk"]])
        gx0 = 13 if x0 > 0 else -120
        gx1 = 120 if x0 > 0 else -13
        gy0 = 13 if y0 > 0 else -120
        gy1 = 120 if y0 > 0 else -13
        g.append([gx0, gy0, gx1, gy1, -0.05, 0.42, c["w-grass"]])
    lift = 0.42
    items = [["ck_house_gable_fence", 26.0, 13.0 + 21.3 / 2, 180], ["ck_house_gable_fence", 52.0, 13.0 + 21.3 / 2, 180],
             ["ck_house_gable_fence", 13.0 + 21.3 / 2, 48.0, 90],
             ["ck_street_lamp_double", 10.5, 10.5, 45], ["dt_fire_hydrant", 11.0, -10.8, 0],
             ["ck_tree_oak", 39.0, 10.6, 0], ["ck_tree_oak", 65.0, 10.6, 0], ["ck_tree_oak", 10.6, 30.0, 0],
             ["ck_tree_oak", -24.0, 10.6, 0], ["ck_bin_street", 18.0, 10.4, 180], ["ck_car_sedan", 44.0, 5.2, 180],
             ["ck_street_lamp_double", 34.0, -10.5, 0]]
    lifts = {"ck_house_gable_fence": lift, "ck_street_lamp_double": 0.38, "dt_fire_hydrant": 0.38, "ck_tree_oak": 0.38,
             "ck_bin_street": 0.38}
    return g, items, lifts


def run_pilot(params):
    root = params["root"]
    out = os.path.join(root, "specs", "013-city-asset-kit", "contact-sheets", "pilot")
    jobs = []
    for theme in ("city", "winter"):
        jobs.append({"kind": "tiles", "name": f"street_{theme}", "theme": theme, "view": "street", "ids": PILOT,
                     "columns": 4, "out": os.path.join(out, f"street-{theme}.png")})
        jobs.append({"kind": "tiles", "name": f"top_{theme}", "theme": theme, "view": "top", "ids": PILOT,
                     "columns": 4, "out": os.path.join(out, f"top-{theme}.png")})
        c = ground_colours(root, theme)
        g, items, lifts = main_street(theme, c)
        for d, ball, heading in ((1, (-18.0, 16.5), 72), (5, (-62.0, -4.0), 80)):
            jobs.append({"kind": "scene", "name": f"main_{theme}_d{d}", "theme": theme, "D": d, "ground": g,
                         "items": items, "lift": lifts, "ball": list(ball), "ball_z": 0.4 if d == 1 else 0.0,
                         "heading": heading, "out": os.path.join(out, f"scene-mainstreet-{theme}-d{d}.png")})
        g, items, lifts = suburb_corner(theme, c)
        for d, ball, heading in ((1, (70.0, 10.5), 265), (5, (82.0, -2.0), 262)):
            jobs.append({"kind": "scene", "name": f"suburb_{theme}_d{d}", "theme": theme, "D": d, "ground": g,
                         "items": items, "lift": lifts, "ball": list(ball), "ball_z": 0.38 if d == 1 else 0.0,
                         "heading": heading, "out": os.path.join(out, f"scene-suburb-{theme}-d{d}.png")})
    for theme in ("city", "winter"):
        jobs.append({"kind": "stack", "paths": [os.path.join(out, f"_before_{theme}.png"),
                                                os.path.join(out, f"street-{theme}.png")],
                     "out": os.path.join(out, f"before-after-{theme}.png")})
    only = params.get("only")
    if only:
        jobs = [j for j in jobs if any(o in j.get("name", j["out"]) for o in only)]
    run({"root": root, "jobs": jobs})
