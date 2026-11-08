# The Stage B QA image set (013 Phase 9, T079): every ck_* asset on tile sheets by zone, street-level and top view, in
# city and winter; a main street and a suburb corner assembled from the Stage B kit at real spacing (style bible
# sections 6 and 7), seen from the ball camera at D1 and D5; and before/after stacks of the building and downtown sheets.
# Run through the Blender MCP after the kit is built (art/scripts/kit_rework.py), one theme and part at a time if a
# call would run long:
#   PARAMS = {"root": "<repo root>", "only": ["tiles_city_street"]}   # "only" filters job names by substring
#   exec(open(PARAMS["root"] + "/art/scripts/stage_b_shots.py").read()); run_stage_b(PARAMS)
# Writes into specs/013-city-asset-kit/contact-sheets/stage-b/; kit_report(root, path) writes the per-asset report.json. Uses street_shots.py for every render and
# pilot_shots.py for the ground colours.

import os

GROUPS = {
    "houses-shops": ["house_semi_garage", "house_bungalow", "house_gable_fence", "house_corner_bay",
                     "house_terrace_pair", "house_split_level", "shop_bakery", "shop_grocer", "shop_pizzeria",
                     "shop_cafe", "shop_bookshop", "shop_pharmacy_cross"],
    "rows-midrises-towers": ["shop_row_three", "shop_row_arcade", "shop_row_corner", "midrise_brick_8",
                             "midrise_render_10", "midrise_setback", "midrise_courtyard", "midrise_corner_clock",
                             "midrise_mixed", "tower_slab", "tower_stepped", "tower_twin", "tower_crown"],
    "street": ["road_marking_dash", "road_marking_arrow", "crossing_zebra", "kerb_corner", "street_sign", "planter_box",
               "bollard", "railing_section", "bus_stop_pole", "street_lamp_double", "bin_street", "traffic_lights",
               "parking_meter", "scooter_dock", "motorbike"],
    "park": ["tree_oak", "tree_pine", "tree_birch", "bush", "hedge_row", "flower_bed", "picnic_blanket",
             "picnic_basket", "swing_set", "slide", "seesaw", "climbing_frame", "sandpit", "path_straight",
             "path_curve", "pond_edge"],
    "suburbs-mainstreet": ["barbecue", "lawn_mower", "garden_fence", "trampoline", "garden_shed", "car_sedan",
                           "car_estate", "skip", "cafe_table_parasol", "fruit_crates", "sandwich_board", "bike_rack",
                           "post_box", "food_truck", "phone_repair_kiosk"],
    "downtown": ["landmark_clock_tower", "landmark_obelisk", "landmark_arch", "tram", "subway_entrance", "limousine",
                 "neon_sign", "scaffolding", "water_tank", "car_sports", "taxi"],
    "signage-memes": ["billboard_404", "billboard_chart", "billboard_loading", "billboard_empty", "billboard_arrow",
                      "billboard_testcard", "billboard_nested", "meme_wet_floor_sign", "meme_pond_cart",
                      "meme_cone_statue", "meme_phone_1pc", "meme_buffering_billboard", "meme_banana_scale",
                      "meme_vacant_lot"],
}
# Stage C (owner request 2026-11-08): the new small objects; the reworked Downtown pocket set is a dt_* group
GROUPS["small-tier1"] = ["chip_bag", "padlock", "newspaper_bundle", "soccer_ball", "flying_disc", "sand_pail",
                         "garden_gnome", "watering_can", "flower_pot", "recycling_box", "grocery_bag", "cupcake",
                         "sunglasses"]
GROUPS["small-tier2"] = ["traffic_cone", "kick_scooter", "cardboard_boxes", "bistro_chair", "flower_buckets",
                         "potted_shrub", "leaf_pile", "bird_bath", "cooler", "kids_bike", "toolbox", "rain_barrel"]
POCKET = ["dt_basketball", "dt_bauble", "dt_bottle_cap", "dt_coffee_cup", "dt_donut", "dt_earbud_case",
          "dt_fairy_light_bulb", "dt_game_controller", "dt_gingerbread_cookie", "dt_headphones", "dt_ice_lolly",
          "dt_keyboard", "dt_lost_sneaker", "dt_pizza_slice", "dt_rubber_duck_sunglasses", "dt_smartphone",
          "dt_soda_can", "dt_tennis_ball", "dt_water_bottle"]
# old sheets in contact-sheets/<theme>/ that show the same groups before the rework
BEFORE = {"houses-shops": "building.png", "downtown": "downtown.png", "street": "street.png", "park": "park.png"}


def ck(name):
    return "ck_" + name


def lane_items():
    """Main street: road along x (y -12..12), north fronts face -y (yaw 180), south fronts face +y (yaw 0)."""
    north = [("midrise_brick_8", -64.0, 23.0), ("tower_slab", -33.0, 14.0), ("shop_row_three", 2.0, 24.7),
             ("shop_cafe", 34.0, 19.6), ("shop_bakery", 52.5, 19.6), ("shop_bookshop", 70.5, 20.1)]
    south = [("shop_row_arcade", -40.0, 22.1), ("shop_grocer", -6.0, 23.6), ("shop_pizzeria", 14.5, 21.8),
             ("midrise_mixed", 41.0, 21.5), ("shop_pharmacy_cross", 67.0, 22.5)]
    items = [[ck(i), x, 22.0 + d / 2 - 4.0, 180] for i, x, d in north]
    items += [[ck(i), x, -(22.0 + d / 2 - 4.0), 0] for i, x, d in south]
    for x in (-60, -36, -12, 12, 36, 60):
        items.append([ck("street_lamp_double"), x, 14.0, 0])
        items.append([ck("street_lamp_double"), x + 12, -14.0, 0])
    for x in (-48, 0, 48):
        items.append([ck("tree_oak"), x, 15.5, 0])
    items.append([ck("tree_birch"), 24.0, -15.5, 0])
    items += [
        [ck("crossing_zebra"), -22.0, 0.0, 90],
        [ck("traffic_lights"), -28.5, 13.2, 180], [ck("traffic_lights"), -15.5, -13.2, 0],
        [ck("parking_meter"), 18.0, 13.2, 180], [ck("parking_meter"), -2.0, 13.2, 180],
        [ck("scooter_dock"), -50.0, 17.0, 180], [ck("bike_rack"), 6.0, 14.2, 0],
        [ck("post_box"), -8.0, 13.8, 180], [ck("bin_street"), 28.0, 14.0, 180], ["dt_fire_hydrant", 42.0, 13.6, 180],
        [ck("cafe_table_parasol"), 34.0, 18.5, 0], [ck("sandwich_board"), 44.5, 15.0, 160],
        [ck("fruit_crates"), 54.0, 15.6, 180],
        [ck("phone_repair_kiosk"), -18.0, -17.5, 0], [ck("scaffolding"), 41.0, -15.8, 0],
        [ck("bollard"), -26.0, -12.9, 0], [ck("bollard"), -18.0, -12.9, 0],
        [ck("taxi"), -6.0, 8.6, 0], [ck("motorbike"), 10.0, 9.4, 0], [ck("car_sedan"), 26.0, 8.6, 0],
        [ck("car_sports"), 8.0, -4.4, 180], [ck("food_truck"), 66.0, -8.0, 180], [ck("car_estate"), -58.0, -8.6, 180],
        [ck("neon_sign"), 2.0, 31.0, 180], [ck("water_tank"), -33.0, 27.0, 0],
        # Stage C: the small end at ball height, around the D1 ball's walk (north pavement, x -40 to 0)
        [ck("chip_bag"), -36.0, 13.8, 40], ["dt_coffee_cup", -33.5, 16.4, 0], ["dt_soda_can", -31.0, 13.4, 0],
        [ck("newspaper_bundle"), -27.0, 19.5, 15], [ck("traffic_cone"), -24.0, 13.0, 0], [ck("traffic_cone"), -21.0, 13.0, 0],
        [ck("cardboard_boxes"), -18.0, 19.6, 10], [ck("grocery_bag"), -14.5, 18.8, 0], ["dt_smartphone", -12.0, 15.0, 30],
        [ck("kick_scooter"), -10.5, 17.6, 200], [ck("potted_shrub"), -6.0, 19.8, 0], [ck("potted_shrub"), 10.0, 19.8, 0],
        [ck("padlock"), 6.0, 13.4, 0], ["dt_lost_sneaker", 1.5, 16.0, 70], [ck("sunglasses"), 22.0, 15.2, 20],
        [ck("bistro_chair"), 31.0, 17.0, 120], [ck("bistro_chair"), 37.0, 17.6, 230], [ck("cupcake"), 34.5, 15.6, 0],
        [ck("flower_buckets"), -6.0, -17.5, 0], ["dt_water_bottle", -30.0, -13.6, 0],
    ]
    lifts = {i[0]: 0.4 for i in items}
    for i in ("ck_car_sedan", "ck_car_sports", "ck_car_estate", "ck_taxi", "ck_motorbike", "ck_food_truck",
              "ck_crossing_zebra"):
        lifts[i] = 0.0
    lifts["ck_neon_sign"] = 0.4 + 42.1
    lifts["ck_water_tank"] = 0.4 + 52.0
    return items, lifts


def suburb_items():
    """Corner of two 16-stud streets; houses on the north-east and north-west blocks with gardens toward the street."""
    lift = 0.42
    items = [
        [ck("house_semi_garage"), 27.0, 13.0 + 22.9 / 2, 180], [ck("house_bungalow"), 56.0, 13.0 + 22.7 / 2, 180],
        [ck("house_corner_bay"), 13.0 + 17.7 / 2, 52.0, 90], [ck("house_split_level"), -30.0, 13.0 + 25.0 / 2, 180],
        [ck("garden_fence"), 18.0, 13.6, 0], [ck("garden_fence"), 46.0, 13.6, 0], [ck("garden_fence"), 66.0, 13.6, 0],
        [ck("hedge_row"), -14.0, 14.0, 0], [ck("bush"), 40.0, 16.0, 0], [ck("flower_bed"), 62.0, 17.0, 0],
        [ck("street_lamp_double"), 10.5, 10.5, 45], ["dt_fire_hydrant", 11.0, -10.8, 0],
        [ck("tree_pine"), 39.0, 10.8, 0], [ck("tree_birch"), 70.0, 10.8, 0], [ck("tree_oak"), 10.8, 32.0, 0],
        [ck("tree_oak"), -46.0, 10.8, 0], [ck("bin_street"), 20.0, 10.4, 180], [ck("post_box"), 33.0, 10.4, 180],
        [ck("car_estate"), 44.0, 5.2, 180], [ck("car_sedan"), -24.0, -5.2, 0], [ck("skip"), 76.0, 4.0, 0],
        [ck("lawn_mower"), 50.0, 18.0, 210], [ck("barbecue"), 68.0, 20.0, 0],
        [ck("street_lamp_double"), 34.0, -10.5, 0], [ck("road_marking_arrow"), 30.0, -3.5, 90],
        # Stage C: garden and kerb clutter around the D1 ball's walk (north pavement and front gardens, x 20 to 80)
        [ck("garden_gnome"), 60.0, 15.6, 200], [ck("watering_can"), 49.0, 16.5, 30], [ck("flower_pot"), 57.5, 15.0, 0],
        [ck("flower_pot"), 63.5, 15.0, 0], [ck("recycling_box"), 23.5, 11.0, 0], [ck("rain_barrel"), 38.5, 24.0, 0],
        [ck("kids_bike"), 44.0, 15.8, 160], [ck("toolbox"), 53.0, 20.0, 20], [ck("soccer_ball"), 71.0, 15.8, 0],
        [ck("leaf_pile"), 75.5, 18.0, 0], [ck("bird_bath"), 66.5, 22.0, 0], [ck("sand_pail"), 68.5, 15.4, 0],
        [ck("flying_disc"), 73.0, 13.6, 0], ["dt_tennis_ball", 79.0, 11.2, 0], [ck("cooler"), 28.0, 18.5, 200],
        [ck("newspaper_bundle"), 34.0, 11.3, 80], [ck("traffic_cone"), 77.0, 7.2, 0],
    ]
    lifts = {i[0]: 0.38 for i in items}
    for i in ("ck_house_semi_garage", "ck_house_bungalow", "ck_house_corner_bay", "ck_house_split_level",
              "ck_garden_fence", "ck_hedge_row", "ck_bush", "ck_flower_bed", "ck_lawn_mower", "ck_barbecue",
              "ck_garden_gnome", "ck_watering_can", "ck_kids_bike", "ck_toolbox", "ck_soccer_ball", "ck_leaf_pile",
              "ck_bird_bath", "ck_sand_pail", "ck_flying_disc", "ck_cooler", "ck_rain_barrel"):
        lifts[i] = lift
    for i in ("ck_car_estate", "ck_car_sedan", "ck_skip", "ck_road_marking_arrow", "ck_traffic_cone"):
        lifts[i] = 0.0
    return items, lifts


def run_stage_b(params):
    root = params["root"]
    ns = {"__name__": "pilot_shots"}
    exec(open(os.path.join(root, "art", "scripts", "pilot_shots.py")).read(), ns)
    shots = {"__name__": "street_shots"}
    exec(open(os.path.join(root, "art", "scripts", "street_shots.py")).read(), shots)
    sheets = os.path.join(root, "specs", "013-city-asset-kit", "contact-sheets")
    out = os.path.join(sheets, "stage-b")
    jobs = []
    for theme in ("city", "winter"):
        for view in ("street", "top"):
            for group, ids in GROUPS.items():
                jobs.append({"kind": "tiles", "name": f"tiles_{theme}_{view}_{group}", "theme": theme, "view": view,
                             "ids": [ck(i) for i in ids], "columns": 5,
                             "out": os.path.join(out, f"{view}-{theme}-{group}.png")})
        c = ns["ground_colours"](root, theme)
        g, _, _ = ns["main_street"](theme, c)
        items, lifts = lane_items()
        for d, ball, heading in ((1, (-40.0, 15.5), 78), (5, (-70.0, -4.0), 80)):
            jobs.append({"kind": "scene", "name": f"scene_{theme}_main_d{d}", "theme": theme, "D": d, "ground": g,
                         "items": items, "lift": lifts, "ball": list(ball), "ball_z": 0.4 if d == 1 else 0.0,
                         "heading": heading, "out": os.path.join(out, f"scene-mainstreet-{theme}-d{d}.png")})
        g, _, _ = ns["suburb_corner"](theme, c)
        items, lifts = suburb_items()
        for d, ball, heading in ((1, (82.0, 10.5), 265), (5, (92.0, -2.0), 262)):
            jobs.append({"kind": "scene", "name": f"scene_{theme}_suburb_d{d}", "theme": theme, "D": d, "ground": g,
                         "items": items, "lift": lifts, "ball": list(ball), "ball_z": 0.38 if d == 1 else 0.0,
                         "heading": heading, "out": os.path.join(out, f"scene-suburb-{theme}-d{d}.png")})
        for view in ("street", "top"):
            jobs.append({"kind": "tiles", "name": f"tiles_{theme}_{view}_pocket", "theme": theme, "view": view,
                         "ids": POCKET, "columns": 5, "out": os.path.join(out, f"{view}-{theme}-pocket.png")})
        for group, old in BEFORE.items():
            jobs.append({"kind": "stack", "name": f"stack_{theme}_{group}",
                         "paths": [os.path.join(sheets, theme, old), os.path.join(out, f"street-{theme}-{group}.png")],
                         "out": os.path.join(out, f"before-after-{theme}-{group}.png")})
    only = params.get("only")
    if only:
        jobs = [j for j in jobs if any(o in j["name"] for o in only)]
    shots["run"]({"root": root, "jobs": jobs})
    return [j["out"] for j in jobs]


def kit_report(root, out_json):
    """Per-asset report for every ck_* mesh: triangles as a share of the tier ceiling, muted share (area on non-accent
    cells; the fronts atlas sign and billboard cells count as accent) and smooth share, by face area."""
    import glob
    import json
    import bpy
    art = os.path.join(root, "art")
    pal = {n: (c["u0"], c["v0"], c["u1"], c["v1"]) for n, c in json.load(open(os.path.join(art, "palette.json")))["cells"].items()}
    fc = {}
    for cells in json.load(open(os.path.join(art, "atlases", "fronts", "fronts.json"))).values():
        if isinstance(cells, dict):
            fc.update({n: (c["u0"], c["v0"], c["u1"], c["v1"]) for n, c in cells.items() if isinstance(c, dict) and "u0" in c})
    accent = ("w-accent-", "w-glow", "w-graffiti", "hero-", "sign_", "bb_")
    man = {m["id"]: m for m in json.load(open(os.path.join(art, "export", "manifest.json")))["meshes"]}
    bud = json.load(open(os.path.join(art, "scripts", "budgets.json")))
    rows = {}
    for path in sorted(glob.glob(os.path.join(art, "source", "ck_*.blend"))):
        bpy.ops.wm.open_mainfile(filepath=path)
        for col in bpy.data.collections:
            if not col.name.startswith("ck_"):
                continue
            obj = next(o for o in col.objects if o.type == "MESH")
            fronts = col.name.startswith(("ck_shop_", "ck_billboard_", "ck_meme_buffering"))
            cells = fc if fronts else pal
            layer = obj.data.uv_layers.active
            tot = mu = sm = 0.0
            for p in obj.data.polygons:
                a = p.area
                tot += a
                if p.use_smooth:
                    sm += a
                uvs = [layer.data[i].uv for i in p.loop_indices]
                u = sum(x.x for x in uvs) / len(uvs)
                v = sum(x.y for x in uvs) / len(uvs)
                name = next((n for n, (u0, v0, u1, v1) in cells.items() if u0 <= u <= u1 and v0 <= v <= v1), "")
                if not name.startswith(accent):
                    mu += a
            t = bud["tiers"][col.name]
            ceil = bud["meshTriangles"][t - 1]
            tris = man[col.name]["triangles"]
            rows[col.name] = {"tier": t, "triangles": tris, "ceiling": ceil, "ceilingUse": round(tris / ceil, 3),
                              "mutedShare": round(mu / tot, 3), "smoothShare": round(sm / tot, 3),
                              "size": bud["sizes"][col.name], "atlas": "fronts" if fronts else "theme"}
    with open(out_json, "w", encoding="utf-8") as handle:
        json.dump(dict(sorted(rows.items())), handle, indent=2)
        handle.write("\n")
    return len(rows)
