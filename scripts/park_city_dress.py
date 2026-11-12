#!/usr/bin/env python3
"""Park City dress table (feature 014, research R-01): how each object kind looks. Hand-edited input, stdlib only.

scripts/park_city_world.py imports this module and writes the fields into the generated world (assetKey, role, atlas,
fallback, shade), the theme data (activeThemeId, supportedThemes, themeBindings) and the coverage report
(specs/014-park-city-art/coverage.md and coverage.json). It is not geometry: a dress change does not touch the layout or
its maps. Contract: specs/014-park-city-art/contracts/dress-and-coverage.md.

Every kind has one status:
  exact       same id or same subject as an uploaded mesh: assetKey
  substitute  a mesh of matching role and silhouette: assetKey and a note; its scale must be within 0.6 to 1.6
  standin     no mesh yet: a w-* role and a fallback shape; the owner picks which to build from the coverage report
`role` is required for every kind (it colours the stand-in and any mesh that falls back). A kind whose stage is later
than CURRENT_STAGE is emitted as a stand-in, so every stage ends playable. A kind's stage is the earliest area that
holds it (1 park and map edge, 2 Ring Road and neighbourhoods, 3 Downtown core), worked out from its placements; an
entry may pin it with `stage`.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# The build stage being generated (1, 2 or 3) and the one-line theme switch (FR-006).
CURRENT_STAGE = 3
ACTIVE_THEME = "winter"
SUPPORTED_THEMES = ("winter", "city")

SCALE_MIN, SCALE_MAX = 0.6, 1.6
FALLBACKS = ("Block", "Ball", "Cylinder", "Wedge")


def exact(asset_key: str, role: str, fallback: str = "Block", atlas: str | None = None, note: str = "",
          stage: int | None = None) -> dict:
    return {"status": "exact", "assetKey": asset_key, "role": role, "fallback": fallback, "atlas": atlas,
            "note": note, "stage": stage}


def sub(asset_key: str, role: str, note: str, fallback: str = "Block", atlas: str | None = None,
        stage: int | None = None) -> dict:
    return {"status": "substitute", "assetKey": asset_key, "role": role, "fallback": fallback, "atlas": atlas,
            "note": note, "stage": stage}


def standin(role: str, note: str, fallback: str = "Block", shade: int | None = None, stage: int | None = None) -> dict:
    return {"status": "standin", "role": role, "fallback": fallback, "shade": shade, "note": note, "stage": stage}


# --- The table: one entry per layout kind (219), tier by tier -------------------------------------------------------
DRESS: dict[str, dict] = {
    # The silly giants: everyday meshes at absurd sizes.
    "mega_cupcake": exact("ck_cupcake", "w-accent-pink", "Cylinder", note="giant cupcake"),
    "mega_duck": exact("rubber_duck", "w-accent-yellow", "Ball", note="giant rubber duck"),
    "mega_gnome": exact("ck_garden_gnome", "w-accent-blue", note="giant gnome"),
    "mega_present": exact("dt_gift_box", "w-accent-red", note="giant present"),
    "mega_football": exact("ck_soccer_ball", "w-white", "Ball", note="giant football"),
    "mega_flamingo": exact("dt_inflatable_flamingo", "w-accent-pink", note="giant inflatable flamingo"),
    "mega_cone": exact("ck_traffic_cone", "w-accent-orange", note="giant traffic cone"),
    "mega_trainer": exact("dt_lost_sneaker", "w-accent-red", note="giant lost sneaker"),
    "colossal_gnome": exact("ck_garden_gnome", "w-accent-blue", note="colossal gnome"),
    "colossal_duck": exact("rubber_duck", "w-accent-yellow", "Ball", note="colossal rubber duck on the pond"),
    "colossal_cupcake": exact("ck_cupcake", "w-accent-pink", "Cylinder", note="colossal cupcake"),
    "colossal_present": exact("dt_gift_box", "w-accent-red", note="colossal present"),
    # Tier 1 (light, client-drawn)
    "acorn": exact("acorn", "w-bark", "Ball"),
    "apple": standin("w-accent-red", "apple", "Ball"),
    "bell": sub("jingle_bell", "w-accent-yellow", "Snow Village jingle bell for a bell", "Ball"),
    "berry": standin("w-accent-red", "berry", "Ball"),
    "bike_bottle": sub("dt_water_bottle", "w-accent-blue", "water bottle for a bike bottle", "Cylinder"),
    "bird_seed_bag": standin("w-sand", "bird seed bag (ck_grocery_bag is twice the size)"),
    "birds_nest": standin("w-bark", "bird's nest", "Cylinder"),
    "biscuit": sub("cookie", "w-wood", "Snow Village cookie for a biscuit", "Cylinder"),
    "bolt": standin("w-metal", "bolt", "Cylinder"),
    "book_stack": standin("w-accent-blue", "stack of books"),
    "bottle_cap": exact("dt_bottle_cap", "w-accent-red", "Cylinder"),
    "boules_set": standin("w-metal", "boules set", "Ball"),
    "breadcrumb": standin("w-sand", "breadcrumb"),
    "button": exact("button", "w-accent-red", "Cylinder"),
    "coffee_cup": exact("dt_coffee_cup", "w-white", "Cylinder"),
    "coin": standin("w-accent-yellow", "coin", "Cylinder"),
    "cone_dropped": sub("pine_cone", "w-bark", "pine cone for a dropped cone", "Ball"),
    "confetti": standin("w-accent-pink", "confetti"),
    "conker": standin("w-bark", "conker", "Ball"),
    "croissant": sub("dt_donut", "w-sand", "donut for a croissant"),
    "cup_small": sub("dt_coffee_cup", "w-white", "coffee cup for a small cup", "Cylinder"),
    "cupcake": exact("ck_cupcake", "w-accent-pink", "Cylinder"),
    "cushion": standin("w-accent-red", "cushion"),
    "daisy": standin("w-white", "daisy"),
    "feather": standin("w-white", "feather"),
    "frisbee": exact("ck_flying_disc", "w-accent-teal", "Cylinder"),
    "gnome_hat": standin("w-accent-red", "gnome hat", "Cylinder"),
    "golden_acorn": standin("w-glow", "golden acorn (kept gold: the acorn mesh would read as a plain acorn)", "Ball"),
    "grape_bunch": standin("w-accent-pink", "bunch of grapes", "Ball"),
    "ice_cream_cone": standin("w-accent-pink", "ice cream cone", "Cylinder"),
    "ladybird": standin("w-accent-red", "ladybird", "Ball"),
    "leaf": standin("w-leaf", "leaf"),
    "lunchbox": sub("dt_takeout_box", "w-accent-red", "takeout box for a lunchbox"),
    "marble": standin("w-accent-teal", "marble", "Ball"),
    "mug": sub("cocoa_mug", "w-white", "Snow Village cocoa mug for a mug", "Cylinder"),
    "napkin": standin("w-white", "napkin"),
    "oar": standin("w-wood", "oar"),
    "party_hat": standin("w-accent-pink", "party hat", "Cylinder"),
    "pea": standin("w-leaf", "pea", "Ball"),
    "pebble": standin("w-concrete", "pebble", "Ball"),
    "petal": standin("w-accent-pink", "petal"),
    "pigeon_spot": standin("w-concrete", "pigeon spot"),
    "pine_cone": exact("pine_cone", "w-bark", "Ball"),
    "racket": standin("w-accent-red", "racket"),
    "record_box": standin("w-wood", "record box"),
    "rose": sub("ck_flower_pot", "w-accent-red", "flower pot for a rose"),
    "rubber_duck": exact("rubber_duck", "w-accent-yellow", "Ball"),
    "sandwich": sub("dt_takeout_box", "w-sand", "takeout box for a sandwich"),
    "scales": standin("w-metal", "kitchen scales"),
    "seed_packet": standin("w-accent-yellow", "seed packet"),
    "skateboard": exact("dt_skateboard", "w-wood"),
    "small_mushroom": standin("w-accent-red", "small mushroom", "Cylinder"),
    "snail_shell": standin("w-sand", "snail shell", "Ball"),
    "spoon": standin("w-metal", "spoon"),
    "strawberry": standin("w-accent-red", "strawberry", "Ball"),
    "sugar_cube": standin("w-white", "sugar cube"),
    "sweet": standin("w-accent-pink", "sweet"),
    "tennis_ball": exact("dt_tennis_ball", "w-accent-yellow", "Ball"),
    "ticket": standin("w-accent-yellow", "ticket"),
    "toy_brick": sub("dt_puzzle_cube", "w-accent-red", "puzzle cube for a toy brick"),
    "toy_bucket": sub("ck_sand_pail", "w-accent-blue", "sand pail for a toy bucket", "Cylinder"),
    "toy_car": sub("matchbox_car", "w-accent-red", "Snow Village matchbox car for a toy car"),
    "trainer": exact("dt_lost_sneaker", "w-accent-red", note="the lost sneaker is a trainer"),
    "tulip": sub("ck_flower_pot", "w-accent-red", "flower pot for a tulip"),
    "violin": sub("dt_acoustic_guitar", "w-wood", "acoustic guitar for a violin"),
    "water_bottle": exact("dt_water_bottle", "w-accent-blue", "Cylinder"),
    # Tier 2 (light, client-drawn)
    "armchair": sub("dt_spinning_office_chair", "w-accent-red", "office chair for an armchair"),
    "barbecue_small": exact("ck_barbecue", "w-metal-dark"),
    "bicycle": exact("dt_bicycle", "w-accent-red"),
    "bird_bath": exact("ck_bird_bath", "w-concrete", "Cylinder"),
    "birthday_cake": standin("w-accent-pink", "birthday cake", "Cylinder"),
    "bmx": sub("dt_bicycle", "w-accent-red", "bicycle for a BMX"),
    "brick_pile": standin("w-wall-b", "pile of bricks", "Block"),
    "cabbage": standin("w-leaf", "cabbage", "Ball"),
    "camping_chair": sub("ck_bistro_chair", "w-accent-teal", "bistro chair for a camping chair"),
    "canoe": standin("w-accent-orange", "canoe"),
    "cheese_wheel": standin("w-accent-yellow", "cheese wheel", "Cylinder"),
    "cool_box": exact("ck_cooler", "w-white"),
    "deckchair": sub("ck_bistro_chair", "w-accent-teal", "bistro chair for a deckchair"),
    "e_scooter": exact("dt_e_scooter", "w-accent-blue"),
    "fence_panel": sub("fence_section", "w-wood", "Snow Village fence section for a fence panel"),
    "fire_ring": standin("w-concrete", "fire ring", "Cylinder"),
    "flower_planter": sub("ck_planter_box", "w-leaf", "planter box for a flower planter"),
    "football": exact("ck_soccer_ball", "w-white", "Ball"),
    "fruit_crate": exact("ck_fruit_crates", "w-wood"),
    "garden_gnome": exact("ck_garden_gnome", "w-accent-blue"),
    "giant_chess_piece": standin("w-white", "giant chess piece", "Cylinder"),
    "gnome_king": standin("w-accent-blue", "gnome king (the gnome mesh is a third of the size)"),
    "hedge_piece": standin("w-leaf-dark", "hedge cube of the maze walls (ck_hedge_row is a long row, not a cube)"),
    "helmet": standin("w-accent-red", "helmet", "Ball"),
    "inflatable_flamingo": exact("dt_inflatable_flamingo", "w-accent-pink"),
    "kennel": standin("w-wood", "kennel"),
    "kick_scooter": exact("ck_kick_scooter", "w-accent-teal"),
    "lantern": exact("lantern", "w-metal-dark"),
    "life_ring_stand": standin("w-accent-red", "life ring stand"),
    "lifebuoy": standin("w-accent-red", "lifebuoy", "Cylinder"),
    "lily_pad": standin("w-leaf", "lily pad", "Cylinder"),
    "log": standin("w-bark", "log", "Cylinder"),
    "mailbox": exact("dt_mailbox", "w-accent-blue"),
    "mushroom_bouncecap": standin("w-accent-red", "bounce-cap mushroom", "Cylinder"),
    "mushroom_cluster": standin("w-accent-red", "mushroom cluster", "Ball"),
    "net_post": standin("w-metal", "net post", "Cylinder"),
    "newspaper_box": exact("dt_newspaper_box", "w-accent-blue"),
    "office_chair": exact("dt_spinning_office_chair", "w-accent-teal"),
    "paddling_pool": exact("dt_paddling_pool", "w-water", "Cylinder"),
    "pedal_car": sub("ck_kids_bike", "w-accent-red", "kids bike for a pedal car"),
    "picnic_basket": exact("ck_picnic_basket", "w-wood"),
    "potted_plant": sub("ck_potted_shrub", "w-leaf", "potted shrub for a potted plant"),
    "present": exact("dt_gift_box", "w-accent-red", note="the gift box is a present"),
    "pumpkin": standin("w-accent-orange", "pumpkin", "Ball"),
    "road_barrier": sub("ck_railing_section", "w-accent-red", "railing section for a road barrier"),
    "scarecrow": standin("w-wood", "scarecrow"),
    "see_saw": exact("ck_seesaw", "w-accent-orange"),
    "suitcase": exact("dt_suitcase", "w-accent-blue"),
    "sundial": standin("w-concrete", "sundial", "Cylinder"),
    "table_lamp": standin("w-accent-yellow", "table lamp", "Cylinder"),
    "ticket_machine": sub("ck_parking_meter", "w-paint-worn", "parking meter for a ticket machine"),
    "toadstool": standin("w-accent-red", "toadstool", "Cylinder"),
    "tomato_plant": sub("ck_potted_shrub", "w-leaf", "potted shrub for a tomato plant"),
    "traffic_cone": exact("ck_traffic_cone", "w-accent-orange"),
    "vent": standin("w-metal", "roof vent"),
    "watering_can": exact("ck_watering_can", "w-accent-teal"),
    "watermelon": standin("w-leaf", "watermelon", "Ball"),
    "wheelbarrow": sub("dt_shopping_cart", "w-accent-red", "shopping cart for a wheelbarrow"),
    "wheelie_bin": exact("dt_wheelie_bin", "w-metal-dark"),
    # Tier 3 (server Parts)
    "ac_unit": standin("w-metal", "air-conditioning unit"),
    "arcade_cabinet": exact("dt_arcade_cabinet", "w-accent-teal"),
    "bench": exact("dt_bench", "w-wood"),
    "bin_large": sub("ck_bin_street", "w-accent-teal", "street bin for a large bin", "Cylinder"),
    "bus_shelter": exact("dt_bus_shelter", "w-glass"),
    "bush": exact("ck_bush", "w-leaf", "Ball"),
    "cafe_table_set": exact("ck_cafe_table_parasol", "w-accent-yellow"),
    "camping_tent": standin("w-accent-orange", "camping tent"),
    "cardboard_boxes": exact("ck_cardboard_boxes", "w-wood"),
    "catapult": standin("w-wood", "catapult"),
    "cement_mixer": standin("w-accent-orange", "cement mixer", "Cylinder"),
    "chimney_stack": standin("w-wall-b", "chimney stack"),
    "fridge": sub("dt_vending_machine", "w-white", "vending machine for a fridge"),
    "goal": standin("w-white", "football goal"),
    "hammock": standin("w-accent-teal", "hammock"),
    "hatchback": exact("dt_hatchback", "w-accent-blue"),
    "hot_dog_trolley": exact("dt_hot_dog_cart", "w-accent-yellow", note="the hot dog cart is the trolley"),
    "ice_cream_cart": sub("dt_cocoa_cart", "w-white", "cocoa cart for an ice cream cart"),
    "ice_polisher": standin("w-accent-teal", "ice polisher"),
    "lawnmower": exact("ck_lawn_mower", "w-accent-red"),
    "luggage_trolley": standin("w-metal", "luggage trolley", "Block"),
    "market_crate_stack": sub("ck_fruit_crates", "w-wood", "fruit crates for a market crate stack"),
    "pallet_bricks": sub("dt_pallet_stack", "w-wood", "pallet stack for a pallet of bricks"),
    "parasol": sub("ck_cafe_table_parasol", "w-accent-yellow", "café table and parasol for a parasol"),
    "pedalo": standin("w-accent-teal", "pedalo"),
    "phone_booth": sub("ck_phone_repair_kiosk", "w-accent-red", "repair kiosk for a phone booth"),
    "picnic_table": exact("dt_picnic_table", "w-wood"),
    "pigeon_coop": standin("w-wood", "pigeon coop"),
    "pipe_bundle": standin("w-metal", "bundle of pipes", "Cylinder"),
    "rooftop_hot_tub": standin("w-water", "rooftop hot tub", "Cylinder"),
    "roundabout": standin("w-accent-red", "playground roundabout", "Cylinder"),
    "rowing_boat": standin("w-wood", "rowing boat"),
    "satellite_dish": exact("dt_satellite_dish", "w-white"),
    "shelter_bench": sub("dt_bench", "w-wood", "bench for a shelter bench"),
    "skip": exact("ck_skip", "w-accent-yellow"),
    "sofa": sub("dt_bench", "w-accent-teal", "bench for a sofa"),
    "solar_panel": standin("w-glass", "solar panel"),
    "swing_set": exact("ck_swing_set", "w-metal"),
    "taxi": exact("ck_taxi", "w-accent-yellow"),
    "trampoline": exact("ck_trampoline", "w-accent-blue", "Cylinder"),
    "umpire_chair": standin("w-white", "umpire chair", "Block"),
    "vending_machine": exact("dt_vending_machine", "w-accent-red"),
    "water_tank": exact("ck_water_tank", "w-wood", "Cylinder"),
    # Tier 4
    "bandstand": exact("bandstand", "w-white", "Cylinder"),
    "big_tree": sub("ck_tree_oak", "w-leaf", "kit oak for a big tree", "Ball"),
    "boathouse": standin("w-wood", "boathouse", "Block"),
    "bouncy_castle": standin("w-accent-pink", "bouncy castle"),
    "camper_van": sub("dt_delivery_van", "w-white", "delivery van for a camper van"),
    "city_bus": exact("dt_city_bus", "w-accent-red"),
    "container": exact("dt_shipping_container", "w-accent-red"),
    "crane_mast": sub("dt_tower_crane", "w-accent-yellow", "tower crane for a crane mast"),
    "delivery_truck": sub("dt_delivery_van", "w-white", "delivery van for a delivery truck"),
    "digger": sub("dt_snowplough", "w-accent-yellow", "snowplough for a digger"),
    "donut_truck": exact("dt_donut_food_truck", "w-accent-pink"),
    "fountain": exact("dt_fountain", "w-kerb", "Cylinder"),
    "fruit_tree": sub("ck_tree_oak", "w-leaf", "kit oak for a fruit tree", "Ball"),
    "garden_shed": exact("ck_garden_shed", "w-wood"),
    "greenhouse": standin("w-glass", "greenhouse"),
    "hoarding": standin("w-paint-worn", "construction hoarding panel (solid, eaten from D 17)"),
    "kiosk": exact("dt_kiosk", "w-wall-c"),
    "market_stall": exact("dt_market_stall", "w-accent-red"),
    "minibus": sub("dt_delivery_van", "w-white", "delivery van for a minibus"),
    "parade_float": standin("w-accent-pink", "parade float"),
    "portable_cabin": sub("dt_shipping_container", "w-wall-c", "shipping container for a site cabin"),
    "removal_van": sub("dt_delivery_van", "w-white", "delivery van for a removal van"),
    "roof_building_1": standin("w-wall-b", "Roof Run building; a shop mesh is taller than the roof and would poke through"),
    "skate_shelter": standin("w-concrete", "skate park shelter"),
    "slide_tower": sub("ck_slide", "w-accent-yellow", "kit slide for a slide tower"),
    "street_tree": exact("dt_street_tree", "w-leaf", "Ball"),
    "train_carriage": sub("ck_tram", "w-accent-yellow", "tram for a train carriage"),
    "van": exact("dt_delivery_van", "w-white"),
    # Tier 5
    "apartment_block": exact("dt_apartment_block", "w-wall-a"),
    "cinema": exact("dt_cinema", "w-wall-c"),
    "corner_shop": exact("ck_shop_grocer", "w-accent-teal", atlas="fronts", note="the grocer is the corner shop"),
    "cottage": sub("ck_house_bungalow", "w-wall-b", "kit bungalow for a cottage"),
    "ferris_wheel": exact("dt_ferris_wheel", "w-metal", "Cylinder"),
    "giant_duck": exact("dt_giant_duck", "w-accent-yellow"),
    "giant_oak": exact("ck_tree_oak", "w-leaf", "Ball", note="the kit oak at giant size"),
    "hotel": sub("ck_midrise_render_10", "w-wall-a", "rendered mid-rise for a hotel"),
    "library": sub("ck_midrise_courtyard", "w-wall-b", "courtyard mid-rise for a library"),
    "roof_building_2": standin("w-wall-a", "Roof Run building; a shop mesh is taller than the roof"),
    "roof_building_3": standin("w-wall-c", "Roof Run building; a shop mesh is taller than the roof"),
    "roof_building_4": standin("w-wall-b", "Roof Run building; a shop mesh is taller than the roof"),
    "roof_building_5": standin("w-wall-a", "Roof Run building; a shop mesh is taller than the roof"),
    "roof_building_6": standin("w-wall-c", "Roof Run building; a shop mesh is taller than the roof"),
    "roof_building_7": standin("w-wall-b", "Roof Run building; a shop mesh is taller than the roof"),
    "roof_building_8": standin("w-wall-a", "Roof Run building; a shop mesh is taller than the roof"),
    "terrace_house": exact("ck_house_terrace_pair", "w-wall-b"),
    "windmill": standin("w-white", "windmill", "Cylinder"),
    # Tier 6
    "car_park": standin("w-concrete", "multi-storey car park (its decks are blocks)"),
    "glass_tower": exact("dt_glass_tower", "w-glass"),
    "office_tower": sub("ck_tower_slab", "w-glass", "kit slab tower for an office tower"),
    "station_hall": standin("w-wall-b", "station hall (also a building block)"),
    "town_hall": sub("ck_landmark_clock_tower", "w-wall-b", "kit clock tower for a town hall"),
}

# --- Block swatches: layout block kind -> w-* role (R-04). One role for both themes: roof is snow in winter. ---------
SWATCH_ROLE: dict[str, str] = {
    "road": "w-asphalt", "track": "w-asphalt",
    "grass": "w-grass", "woods": "w-grass", "island": "w-grass",
    "pavement": "w-sidewalk", "plaza": "w-sidewalk",
    "kerb": "w-kerb", "stone": "w-kerb", "wall": "w-kerb", "bowl": "w-kerb", "box": "w-kerb",
    "roof": "w-snowcap",
    "building": "w-wall-a", "tower": "w-wall-a",
    "glass": "w-glass",
    "gravel": "w-sand", "sand": "w-sand",
    "ramp": "w-concrete", "spiral": "w-concrete", "deck": "w-concrete",
    "bridge": "w-wood", "jetty": "w-wood", "log_platform": "w-wood",
    "tree_trunk": "w-bark", "tunnel_wall": "w-bark", "tunnel_roof": "w-bark",
}
# Blocks whose material differs from their kind's: the Giant Oak's ramp and deck are wood, the maze bridge too.
BLOCK_ROLE: dict[str, str] = {
    "oak_ramp": "w-bark",
    "oak_deck": "w-wood",
    "maze_exit_bridge": "w-wood",
}

# --- Theme slots (R-03) ---------------------------------------------------------------------------------------------
# The Plaza landmark swaps by theme; the memes are the same in both (a theme swaps atlases, not meshes).
MEME_SLOTS = {"slot.meme.t3": "meme_pond_cart", "slot.meme.t4": "meme_cone_statue", "slot.meme.t5": "meme_vacant_lot"}
SLOT_BINDINGS: dict[str, dict[str, str]] = {
    "winter": {"slot.landmark": "mega_tree", **MEME_SLOTS},
    "city": {"slot.landmark": "giant_duck", **MEME_SLOTS},
}
# Theme-only objects. `copyOf` takes a layout kind's dims, tier and bulk (so the swap never changes the rules);
# `citykit` takes a CityKit object's dims and mesh, with the tier from Park City's own bulk rule.
MEMES = ("meme_pond_cart", "meme_cone_statue", "meme_vacant_lot", "meme_phone_1pc", "meme_buffering_billboard",
         "meme_banana_scale")
THEME_ONLY: dict[str, dict[str, dict]] = {
    "winter": {
        "mega_tree": {"copyOf": "giant_duck", "assetKey": "dt_mega_tree", "role": "w-leaf", "fallback": "Cylinder",
                      "en": "Mega tree", "es": "Árbol gigante"},
        **{m: {"citykit": m} for m in MEMES},
    },
    "city": {m: {"citykit": m} for m in MEMES},
}

# --- Map edge scenery (R-10): layout edge kind -> look. Not objects: no tier, never eaten. -------------------------
EDGE_DRESS: dict[str, dict] = {
    "apron": {"role": "w-grass"},
    "hedge": {"role": "w-leaf-dark"},
    "tree": {"assetKey": "dt_street_tree", "role": "w-leaf"},
    "building": {"role": "w-wall-c"},
    "building_b": {"role": "w-wall-b"},
    "building_a": {"role": "w-wall-a"},
}


# --- Catalogue: what exists to map onto ---------------------------------------------------------------------------
def load_catalogue() -> dict:
    """Uploaded mesh keys, manifest ids and triangles, native longest sides, fronts meshes and theme roles."""
    assets_text = (ROOT / "src" / "shared" / "Assets.luau").read_text()
    meshes_block = assets_text.split("meshes = {", 1)[1].split("\n\t}", 1)[0]
    meshes = {k: v for k, v in re.findall(r'^\t\t([a-z0-9_]+) = "([^"]*)"', meshes_block, re.M)}
    manifest = {m["id"]: m for m in json.loads((ROOT / "art" / "export" / "manifest.json").read_text())["meshes"]}
    native: dict[str, float] = {}
    fronts: set[str] = set()
    citykit: dict[str, dict] = {}
    kit_text = (ROOT / "src" / "shared" / "Content" / "CityKit.luau").read_text()
    for block in re.findall(r"\n\t\{\n(.*?)\n\t\},", kit_text, re.S):
        fields = dict(re.findall(r'^\t\t(\w+) = "([^"]*)"', block, re.M))
        dims = re.search(r"dims = \{ ([^}]*) \}", block)
        if "id" not in fields or dims is None:
            continue
        values = [float(v) for v in dims.group(1).split(",")]
        key = fields.get("assetKey", "ck_" + fields["id"])
        native[key] = max(values)
        if fields.get("atlas") == "fronts":
            fronts.add(key)
        citykit[fields["id"]] = {"assetKey": key, "role": fields.get("role"), "atlas": fields.get("atlas"),
                                 "dims": values, "nameKey": fields.get("nameKey"), "fallback": fields.get("fallback")}
    downtown = (ROOT / "src" / "shared" / "Content" / "Worlds" / "Downtown.luau").read_text()
    for kind, size in re.findall(r'id = "([a-z0-9_]+)",\s*size = ([\d.]+),\s*shape = "\w+"', downtown):
        native["dt_" + kind] = float(size)
    themes_text = (ROOT / "src" / "shared" / "Content" / "Themes.luau").read_text()
    palettes = themes_text.split("-- BEGIN GENERATED PALETTES", 1)[1].split("-- END GENERATED PALETTES", 1)[0]
    roles = {}
    for theme in SUPPORTED_THEMES:
        body = palettes.split(f"\n\t{theme} = {{", 1)[1].split("\n\t}", 1)[0]
        roles[theme] = set(re.findall(r'\["(w-[a-z-]+)"\]', body))
    return {"meshes": meshes, "manifest": manifest, "native": native, "fronts": fronts, "citykit": citykit,
            "roles": roles}


def has_role(catalogue: dict, role: str) -> bool:
    return all(role in catalogue["roles"][theme] for theme in SUPPORTED_THEMES)


def mesh_problem(catalogue: dict, key: str) -> str | None:
    if not catalogue["meshes"].get(key):
        return f"assetKey {key} is not an uploaded key in Assets.meshes"
    if key not in catalogue["manifest"]:
        return f"assetKey {key} is not in art/export/manifest.json"
    return None


def scale_of(catalogue: dict, key: str, dims) -> float | None:
    native = catalogue["native"].get(key)
    return round(max(dims) / native, 2) if native else None


def validate(objects: dict, catalogue: dict) -> list[str]:
    """Every rule of data-model.md section 1; an empty list means the table is valid. `objects` is the layout's."""
    problems = []
    for kind in sorted(set(objects) - set(DRESS)):
        problems.append(f"{kind}: no dress entry")
    for kind in sorted(set(DRESS) - set(objects)):
        problems.append(f"{kind}: dress entry for a kind not in the layout")
    for kind, entry in sorted(DRESS.items()):
        status = entry["status"]
        if status not in ("exact", "substitute", "standin"):
            problems.append(f"{kind}: unknown status {status}")
            continue
        if not has_role(catalogue, entry["role"]):
            problems.append(f"{kind}: role {entry['role']} is missing from a theme palette")
        if entry["fallback"] not in FALLBACKS:
            problems.append(f"{kind}: unknown fallback {entry['fallback']}")
        if entry.get("stage") not in (None, 1, 2, 3):
            problems.append(f"{kind}: stage must be 1, 2 or 3")
        if status == "standin":
            if entry.get("assetKey"):
                problems.append(f"{kind}: a stand-in has no assetKey")
            if not entry["note"]:
                problems.append(f"{kind}: a stand-in needs a note")
            continue
        key = entry.get("assetKey")
        if not key:
            problems.append(f"{kind}: {status} needs an assetKey")
            continue
        problem = mesh_problem(catalogue, key)
        if problem:
            problems.append(f"{kind}: {problem}")
        if status == "substitute" and not entry["note"]:
            problems.append(f"{kind}: a substitute needs a note")
        if kind in objects:
            scale = scale_of(catalogue, key, objects[kind]["dims"])
            if status == "substitute" and scale is not None and not SCALE_MIN <= scale <= SCALE_MAX:
                problems.append(f"{kind}: substitute {key} scales by {scale}, outside {SCALE_MIN} to {SCALE_MAX}")
        atlas = entry.get("atlas")
        if atlas not in (None, "fronts"):
            problems.append(f"{kind}: unknown atlas {atlas}")
        if atlas == "fronts" and key not in catalogue["fronts"]:
            problems.append(f"{kind}: atlas fronts on {key}, which is not a fronts-atlas mesh")
        if atlas is None and key in catalogue["fronts"]:
            problems.append(f"{kind}: {key} is a fronts-atlas mesh and needs atlas = \"fronts\"")
    for swatch, role in {**SWATCH_ROLE, **BLOCK_ROLE}.items():
        if not has_role(catalogue, role):
            problems.append(f"block {swatch}: role {role} is missing from a theme palette")
    if ACTIVE_THEME not in SUPPORTED_THEMES:
        problems.append(f"ACTIVE_THEME {ACTIVE_THEME} is not a supported theme")
    if CURRENT_STAGE not in (1, 2, 3):
        problems.append(f"CURRENT_STAGE {CURRENT_STAGE} must be 1, 2 or 3")
    for theme in SUPPORTED_THEMES:
        own = THEME_ONLY.get(theme, {})
        for slot, target in SLOT_BINDINGS[theme].items():
            if target not in objects and target not in own:
                problems.append(f"{theme} {slot}: {target} is neither a layout kind nor a {theme} theme-only object")
        for oid, spec in own.items():
            if oid in objects:
                problems.append(f"{theme} theme-only {oid} clashes with a layout kind")
            if "citykit" in spec and spec["citykit"] not in catalogue["citykit"]:
                problems.append(f"{theme} theme-only {oid}: no CityKit object {spec['citykit']}")
            if "copyOf" in spec and spec["copyOf"] not in objects:
                problems.append(f"{theme} theme-only {oid}: copyOf {spec['copyOf']} is not a layout kind")
            if spec.get("assetKey"):
                problem = mesh_problem(catalogue, spec["assetKey"])
                if problem:
                    problems.append(f"{theme} theme-only {oid}: {problem}")
    for kind, spec in EDGE_DRESS.items():
        if not has_role(catalogue, spec["role"]):
            problems.append(f"edge {kind}: role {spec['role']} is missing from a theme palette")
        if spec.get("assetKey"):
            problem = mesh_problem(catalogue, spec["assetKey"])
            if problem:
                problems.append(f"edge {kind}: {problem}")
    return problems


def area_stage(x: float, z: float) -> int:
    """1 the park (outside the Ring Road), 2 the Ring Road and neighbourhoods, 3 the Downtown core."""
    m = max(abs(x), abs(z))
    return 1 if m >= 300 else 2 if m >= 150 else 3
