#!/usr/bin/env python3
"""Park City layout: the single source of the map references (docs/design/09-park-city-level.md).

Stdlib only, deterministic. It writes:
- docs/design/maps/park-city-layout.json  the layout as data (zones, blocks, spawns, scenes with every object, trails,
                                          rails, pads, catapults, gates, golden spots). Feature 012 builds the grey box
                                          from this file; change the map here, not in the pictures.
- docs/design/maps/*.svg                  the overview, one map per zone and close-ups of the set pieces
                                          (scripts/park_city_render.py draws them).

Coordinates are studs: x east, z south, y up. Origin at the Plaza. `m = max(|x|, |z|)`.
Object sizes are L x W x H; bulk = (L*W*H)^(1/3); tier by bulk (section 3.3 of the design doc).

Run: python3 scripts/park_city_layout.py
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "design" / "maps"

# --------------------------------------------------------------------------------------------------------------
# Objects: id -> (L, W, H). Bulk and tier are derived. Heights matter for the "too tall" rule (longest <= 1.5 D).
# --------------------------------------------------------------------------------------------------------------
OBJECTS: dict[str, tuple[float, float, float]] = {
    # Tier 1 Crumb (bulk <= 1.25)
    "acorn": (0.3, 0.25, 0.3), "conker": (0.4, 0.4, 0.35), "pine_cone": (0.5, 0.4, 0.4), "leaf": (0.6, 0.4, 0.05),
    "daisy": (0.3, 0.3, 0.5), "ladybird": (0.3, 0.25, 0.15), "snail_shell": (0.5, 0.35, 0.4),
    "feather": (0.8, 0.2, 0.1), "button": (0.2, 0.2, 0.05), "coin": (0.25, 0.25, 0.05), "berry": (0.3, 0.3, 0.3),
    "strawberry": (0.4, 0.3, 0.3), "sweet": (0.4, 0.2, 0.2), "biscuit": (0.5, 0.5, 0.1),
    "bottle_cap": (0.3, 0.3, 0.1), "sugar_cube": (0.25, 0.25, 0.25), "seed_packet": (0.6, 0.4, 0.1),
    "tennis_ball": (0.6, 0.6, 0.6), "small_mushroom": (0.5, 0.5, 0.6), "marble": (0.3, 0.3, 0.3),
    "toy_brick": (0.5, 0.25, 0.3), "breadcrumb": (0.3, 0.2, 0.15), "pea": (0.25, 0.25, 0.25),
    "petal": (0.5, 0.3, 0.05), "spoon": (0.8, 0.2, 0.1), "napkin": (0.8, 0.8, 0.05), "ticket": (0.6, 0.3, 0.02),
    "pebble": (0.4, 0.3, 0.25), "bolt": (0.3, 0.2, 0.2), "cone_dropped": (0.6, 0.4, 0.4), "confetti": (0.4, 0.4, 0.05),
    "golden_acorn": (0.6, 0.5, 0.6), "gnome_hat": (1.2, 0.6, 0.6), "cup_small": (0.6, 0.6, 0.8),
    "bell": (0.5, 0.5, 0.4), "grape_bunch": (0.8, 0.5, 0.5), "bird_seed_bag": (0.8, 0.5, 0.4),
    # Tier 2 Pocket (bulk 1.25 - 3)
    "apple": (1.0, 1.0, 1.0), "cupcake": (1.2, 1.2, 1.2), "sandwich": (1.4, 1.2, 0.6), "ice_cream_cone": (1.6, 0.8, 0.8),
    "watermelon": (2.4, 1.6, 1.6), "tulip": (0.6, 0.6, 1.6), "rose": (0.8, 0.8, 1.8), "toadstool": (1.4, 1.4, 1.4),
    "mushroom_cluster": (1.8, 1.6, 1.4), "birds_nest": (1.4, 1.4, 0.6), "cabbage": (2.0, 2.0, 1.6),
    "pumpkin": (2.6, 2.6, 2.0), "tomato_plant": (1.2, 1.2, 2.4), "rubber_duck": (1.2, 1.0, 1.1),
    "toy_car": (1.4, 0.7, 0.6), "football": (2.0, 2.0, 2.0), "frisbee": (2.0, 2.0, 0.3), "helmet": (1.8, 1.4, 1.2),
    "skateboard": (2.6, 0.8, 0.4), "kick_scooter": (2.8, 1.0, 3.0), "trainer": (1.8, 0.7, 0.6), "lantern": (1.3, 1.3, 1.6),
    "watering_can": (2.0, 0.8, 1.4), "picnic_basket": (2.2, 1.4, 1.4), "cool_box": (2.6, 1.6, 1.6),
    "garden_gnome": (1.2, 1.0, 2.2), "violin": (3.0, 1.1, 0.4), "hedge_piece": (3.2, 1.5, 3.0),
    "fence_panel": (3.2, 0.4, 3.0), "party_hat": (1.0, 1.0, 1.4), "present": (1.6, 1.6, 1.4), "lifebuoy": (2.0, 2.0, 0.5),
    "oar": (3.5, 0.5, 0.3), "cushion": (1.8, 1.8, 0.6), "table_lamp": (1.2, 1.2, 2.2), "book_stack": (1.4, 1.0, 1.2),
    "record_box": (1.6, 1.2, 1.0), "mug": (0.9, 0.7, 0.9), "croissant": (1.2, 0.6, 0.5), "coffee_cup": (0.8, 0.8, 1.2),
    "cheese_wheel": (1.8, 1.8, 0.8), "fruit_crate": (2.2, 1.4, 1.0), "scales": (1.6, 1.0, 1.2), "brick_pile": (2.4, 1.6, 1.2),
    "traffic_cone": (1.0, 1.0, 2.0), "lunchbox": (1.2, 0.8, 0.6), "suitcase": (1.8, 0.8, 2.4), "bird_bath": (1.8, 1.8, 2.6),
    "sundial": (1.6, 1.6, 2.4), "pigeon_spot": (0.6, 0.4, 0.5), "potted_plant": (1.4, 1.4, 2.2), "vent": (1.6, 1.6, 1.6),
    "deckchair": (2.4, 1.6, 2.6), "barbecue_small": (2.0, 1.4, 2.2), "fire_ring": (2.8, 2.8, 0.6),
    "mushroom_bouncecap": (3.0, 3.0, 2.0), "lily_pad": (4.0, 4.0, 0.2), "toy_bucket": (1.2, 1.2, 1.2),
    "gnome_king": (1.6, 1.4, 3.6), "birthday_cake": (2.8, 2.8, 3.0), "inflatable_flamingo": (3.0, 1.5, 3.0),
    "racket": (2.2, 0.8, 0.2), "water_bottle": (0.8, 0.8, 1.8), "bike_bottle": (0.6, 0.6, 1.4),
    # Tier 3 Picnic (bulk 3 - 7.5)
    "bicycle": (6.0, 1.0, 3.5), "bmx": (5.0, 1.0, 3.0), "e_scooter": (4.0, 1.0, 4.0), "bench": (7.0, 2.0, 3.0),
    "picnic_table": (6.0, 5.0, 2.5), "camping_tent": (4.5, 4.0, 3.0), "camping_chair": (2.6, 2.4, 3.0),
    "mailbox": (2.0, 2.0, 4.5), "phone_booth": (3.0, 3.0, 8.0), "hot_dog_trolley": (7.5, 3.0, 6.0),
    "ice_cream_cart": (6.0, 3.0, 5.0), "wheelie_bin": (2.0, 2.0, 3.5), "vending_machine": (3.0, 3.0, 7.0),
    "newspaper_box": (2.2, 2.0, 4.0), "lawnmower": (4.0, 2.5, 3.0), "trampoline": (4.4, 4.4, 2.0),
    "roundabout": (9.0, 9.0, 1.5), "see_saw": (8.0, 1.0, 2.0), "swing_set": (10.0, 4.0, 7.0), "pedalo": (7.0, 4.0, 3.0),
    "rowing_boat": (10.0, 4.0, 2.0), "canoe": (9.0, 2.0, 1.4), "ac_unit": (5.0, 3.0, 3.0), "water_tank": (8.0, 6.0, 6.0),
    "satellite_dish": (4.0, 3.0, 4.0), "chimney_stack": (3.0, 2.0, 6.0), "solar_panel": (6.0, 4.0, 1.5),
    "pigeon_coop": (5.0, 4.0, 5.0), "rooftop_hot_tub": (9.0, 9.0, 3.0), "arcade_cabinet": (3.0, 3.0, 6.5),
    "office_chair": (2.5, 2.5, 3.4), "umpire_chair": (3.0, 3.0, 6.0), "net_post": (1.0, 1.0, 4.0),
    "scarecrow": (3.0, 1.0, 5.0), "wheelbarrow": (4.0, 2.0, 2.0), "market_crate_stack": (4.0, 3.0, 4.0),
    "cafe_table_set": (5.0, 5.0, 3.0), "parasol": (6.0, 6.0, 6.0), "armchair": (3.0, 3.0, 3.0),
    "fridge": (2.5, 2.5, 6.0), "sofa": (7.0, 3.0, 3.0), "cardboard_boxes": (3.5, 3.0, 3.0), "road_barrier": (6.0, 1.0, 3.0),
    "cement_mixer": (5.0, 3.0, 4.0), "pallet_bricks": (4.0, 4.0, 3.0), "pipe_bundle": (10.0, 2.0, 2.0),
    "pedal_car": (3.4, 2.0, 2.0), "bin_large": (3.0, 3.0, 4.0), "luggage_trolley": (6.0, 3.0, 3.0),
    "ticket_machine": (2.0, 2.0, 6.0), "paddling_pool": (4.6, 4.6, 1.0), "kennel": (3.0, 3.0, 3.0),
    "bouncy_castle": (10.0, 10.0, 7.0), "catapult": (8.0, 5.0, 6.0), "shelter_bench": (6.0, 2.0, 2.5),
    "bush": (6.0, 6.0, 4.0), "goal": (7.0, 2.0, 2.5), "log": (6.0, 1.2, 1.2), "fruit_tree": (7.0, 7.0, 11.0),
    "boules_set": (1.0, 0.8, 0.6), "giant_chess_piece": (1.2, 1.2, 2.6), "hammock": (6.0, 2.0, 3.0), "flower_planter": (6.0, 2.0, 2.0), "life_ring_stand": (2.0, 1.0, 4.0),
    # Tier 4 Street (bulk 7.5 - 17.5)
    "hatchback": (14.0, 6.0, 5.0), "taxi": (14.0, 6.0, 5.0), "van": (17.0, 7.0, 8.0), "camper_van": (16.0, 7.0, 8.0),
    "city_bus": (25.0, 8.0, 10.0), "minibus": (16.0, 7.0, 7.0), "digger": (16.0, 7.0, 9.0), "parade_float": (18.0, 8.0, 9.0),
    "market_stall": (10.0, 6.0, 8.0), "kiosk": (10.0, 8.0, 9.0), "garden_shed": (9.0, 7.0, 8.0),
    "bus_shelter": (12.0, 4.0, 8.0), "boathouse": (18.0, 12.0, 10.0), "greenhouse": (18.0, 10.0, 10.0),
    "train_carriage": (25.0, 6.0, 9.0), "big_tree": (12.0, 12.0, 20.0), "street_tree": (8.0, 8.0, 14.0),
    "portable_cabin": (14.0, 7.0, 7.0), "skip": (10.0, 6.0, 5.0), "slide_tower": (14.0, 6.0, 12.0),
    "skate_shelter": (14.0, 10.0, 8.0), "fountain": (16.0, 16.0, 8.0), "bandstand": (16.0, 16.0, 12.0),
    "donut_truck": (18.0, 7.0, 10.0), "removal_van": (20.0, 8.0, 10.0), "ice_polisher": (8.0, 5.0, 5.0),
    "delivery_truck": (17.0, 7.0, 8.0), "hoarding": (12.0, 4.0, 12.0), "container": (20.0, 8.0, 8.0),
    # Tier 5 House (bulk 17.5 - 40)
    "cottage": (22.0, 18.0, 20.0), "terrace_house": (30.0, 16.0, 24.0), "corner_shop": (26.0, 18.0, 16.0),
    "apartment_block": (40.0, 20.0, 30.0), "cinema": (36.0, 26.0, 18.0), "hotel": (30.0, 26.0, 40.0),
    "windmill": (15.0, 15.0, 36.0), "giant_duck": (30.0, 20.0, 25.0), "ferris_wheel": (50.0, 10.0, 50.0),
    "giant_oak": (30.0, 30.0, 40.0), "library": (34.0, 26.0, 20.0), "crane_mast": (8.0, 8.0, 70.0),
    # Tier 6 Skyline (bulk 40 - 75)
    "office_tower": (36.0, 36.0, 70.0), "town_hall": (50.0, 34.0, 45.0), "station_hall": (60.0, 40.0, 30.0),
    "car_park": (75.0, 85.0, 26.0), "glass_tower": (35.0, 35.0, 90.0),
}

TIER_BULK = [0.0, 1.25, 3.0, 7.5, 17.5, 40.0, 75.0]


def bulk(obj: str) -> float:
    l, w, h = OBJECTS[obj]
    return (l * w * h) ** (1 / 3)


def tier(obj: str) -> int:
    b = bulk(obj)
    for t in range(1, 7):
        if b <= TIER_BULK[t]:
            return t
    return 6


def needs_d(obj: str) -> float:
    return max(bulk(obj) / 0.5, max(OBJECTS[obj]) / 1.5)


# --------------------------------------------------------------------------------------------------------------
# Scene kinds: a scene is a short story. Items are (object, count, band). Bands: front (spills toward the path),
# mid, back (the big thing that explains the scene). Footprint is width (along the front) x depth.
# --------------------------------------------------------------------------------------------------------------
SCENE_KINDS: dict[str, dict] = {
    "doorstep_acorn": {"fp": (24, 24), "items": [("acorn", 8, "f"), ("conker", 5, "f"), ("leaf", 4, "m"), ("pine_cone", 3, "m")]},
    "doorstep_duck": {"fp": (24, 24), "items": [("breadcrumb", 9, "f"), ("feather", 5, "f"), ("pebble", 4, "m"), ("bird_seed_bag", 2, "m")]},
    "doorstep_toys": {"fp": (24, 24), "items": [("marble", 8, "f"), ("toy_brick", 6, "f"), ("button", 4, "m"), ("tennis_ball", 2, "m")]},
    "doorstep_flower": {"fp": (24, 24), "items": [("petal", 8, "f"), ("daisy", 5, "f"), ("ladybird", 4, "m"), ("seed_packet", 3, "m")]},
    "acorn_fall": {"fp": (16, 12), "items": [("acorn", 8, "f"), ("leaf", 5, "f"), ("conker", 4, "m"), ("pine_cone", 3, "m"), ("birds_nest", 1, "b")]},
    "fairy_ring": {"fp": (12, 12), "items": [("small_mushroom", 10, "f"), ("snail_shell", 3, "m"), ("toadstool", 4, "b"), ("mushroom_cluster", 2, "b")]},
    "flower_bed": {"fp": (20, 8), "items": [("petal", 6, "f"), ("ladybird", 3, "f"), ("daisy", 4, "f"), ("tulip", 8, "m"), ("rose", 5, "m"), ("watering_can", 1, "b"), ("garden_gnome", 1, "b")]},
    "picnic": {"fp": (16, 14), "items": [("breadcrumb", 6, "f"), ("berry", 5, "f"), ("strawberry", 4, "f"), ("sandwich", 3, "m"), ("cupcake", 3, "m"), ("apple", 2, "m"), ("picnic_basket", 1, "b"), ("cool_box", 1, "b"), ("frisbee", 1, "b"), ("picnic_table", 1, "b")]},
    "birthday_party": {"fp": (18, 14), "items": [("confetti", 8, "f"), ("sweet", 6, "f"), ("cupcake", 4, "m"), ("party_hat", 4, "m"), ("present", 3, "m"), ("birthday_cake", 1, "b"), ("bouncy_castle", 1, "b")]},
    "duck_feeding": {"fp": (12, 8), "items": [("breadcrumb", 8, "f"), ("feather", 3, "f"), ("rubber_duck", 3, "m"), ("bench", 1, "b")]},
    "sandpit": {"fp": (14, 14), "items": [("marble", 6, "f"), ("toy_brick", 6, "f"), ("toy_car", 3, "m"), ("toy_bucket", 2, "m"), ("pedal_car", 1, "b")]},
    "tennis_court": {"fp": (30, 60), "items": [("tennis_ball", 40, "f"), ("racket", 3, "m"), ("water_bottle", 3, "m"), ("net_post", 2, "b"), ("umpire_chair", 1, "b")]},
    "campsite": {"fp": (40, 30), "items": [("sweet", 6, "f"), ("pebble", 6, "f"), ("lantern", 3, "m"), ("mug", 3, "m"), ("fire_ring", 1, "m"), ("camping_chair", 3, "b"), ("camping_tent", 3, "b"), ("camper_van", 1, "b")]},
    "allotment_plot": {"fp": (24, 16), "items": [("pea", 8, "f"), ("strawberry", 6, "f"), ("seed_packet", 3, "f"), ("tomato_plant", 4, "m"), ("cabbage", 4, "m"), ("pumpkin", 2, "m"), ("scarecrow", 1, "b"), ("wheelbarrow", 1, "b"), ("garden_shed", 1, "b")]},
    "skate_spot": {"fp": (20, 12), "items": [("bottle_cap", 6, "f"), ("coin", 4, "f"), ("helmet", 3, "m"), ("skateboard", 4, "m"), ("kick_scooter", 3, "m"), ("bmx", 1, "b"), ("bench", 1, "b")]},
    "boat_hire": {"fp": (30, 20), "items": [("lifebuoy", 3, "f"), ("oar", 4, "f"), ("pedalo", 3, "m"), ("canoe", 3, "m"), ("rowing_boat", 2, "b"), ("boathouse", 1, "b")]},
    "ice_cream_stop": {"fp": (12, 8), "items": [("cone_dropped", 6, "f"), ("napkin", 4, "f"), ("ice_cream_cone", 3, "m"), ("ice_cream_cart", 1, "b"), ("bench", 1, "b")]},
    "bike_rack": {"fp": (16, 6), "items": [("bell", 3, "f"), ("bike_bottle", 3, "f"), ("helmet", 2, "m"), ("bicycle", 4, "b"), ("e_scooter", 2, "b")]},
    "bus_stop": {"fp": (16, 8), "items": [("ticket", 4, "f"), ("coffee_cup", 3, "f"), ("suitcase", 1, "m"), ("shelter_bench", 1, "b"), ("bus_shelter", 1, "b")]},
    "cafe_terrace": {"fp": (18, 10), "items": [("sugar_cube", 6, "f"), ("spoon", 4, "f"), ("coffee_cup", 4, "m"), ("croissant", 3, "m"), ("cafe_table_set", 3, "b"), ("parasol", 2, "b")]},
    "market_stall": {"fp": (14, 10), "items": [("grape_bunch", 5, "f"), ("coin", 4, "f"), ("apple", 4, "m"), ("cheese_wheel", 2, "m"), ("fruit_crate", 3, "m"), ("scales", 1, "m"), ("market_crate_stack", 1, "b"), ("market_stall", 1, "b")]},
    "yard_sale": {"fp": (14, 10), "items": [("book_stack", 3, "f"), ("mug", 3, "f"), ("table_lamp", 2, "m"), ("record_box", 2, "m"), ("toy_car", 2, "m"), ("armchair", 1, "b"), ("bicycle", 1, "b")]},
    "removal_van": {"fp": (26, 12), "items": [("cushion", 3, "f"), ("table_lamp", 2, "f"), ("cardboard_boxes", 3, "m"), ("armchair", 1, "m"), ("fridge", 1, "m"), ("sofa", 1, "m"), ("removal_van", 1, "b")]},
    "roadworks": {"fp": (24, 10), "items": [("bolt", 6, "f"), ("traffic_cone", 6, "f"), ("road_barrier", 3, "m"), ("cement_mixer", 1, "b"), ("digger", 1, "b")]},
    "building_site": {"fp": (60, 70), "items": [("brick_pile", 6, "f"), ("pallet_bricks", 6, "m"), ("pipe_bundle", 3, "m"), ("cement_mixer", 2, "m"), ("skip", 2, "b"), ("portable_cabin", 2, "b"), ("digger", 1, "b"), ("container", 3, "b")]},
    "rooftop_garden": {"fp": (14, 16), "items": [("potted_plant", 5, "f"), ("garden_gnome", 2, "f"), ("deckchair", 3, "m"), ("barbecue_small", 1, "m"), ("rooftop_hot_tub", 1, "b"), ("water_tank", 1, "b")]},
    "rooftop_plant": {"fp": (14, 16), "items": [("vent", 4, "f"), ("satellite_dish", 2, "m"), ("chimney_stack", 2, "m"), ("ac_unit", 3, "b"), ("solar_panel", 2, "b"), ("pigeon_coop", 1, "b")]},
    "parking_row": {"fp": (60, 8), "items": [("hatchback", 3, "b"), ("taxi", 1, "b"), ("van", 1, "b")]},
    "school_run": {"fp": (24, 10), "items": [("lunchbox", 4, "f"), ("football", 1, "f"), ("kick_scooter", 3, "m"), ("bicycle", 2, "m"), ("minibus", 1, "b")]},
    "station_platform": {"fp": (60, 10), "items": [("ticket", 8, "f"), ("coffee_cup", 4, "f"), ("suitcase", 4, "m"), ("luggage_trolley", 3, "m"), ("bench", 3, "b"), ("vending_machine", 2, "b"), ("ticket_machine", 2, "b")]},
    "gate_corner": {"fp": (24, 12), "items": [("napkin", 4, "f"), ("coin", 4, "f"), ("mailbox", 1, "m"), ("newspaper_box", 1, "m"), ("wheelie_bin", 1, "m"), ("hot_dog_trolley", 1, "b"), ("phone_booth", 1, "b")]},
    "fountain_plaza": {"fp": (40, 40), "items": [("coin", 10, "f"), ("cafe_table_set", 4, "m"), ("bin_large", 2, "m"), ("fountain", 1, "b")]},
    "front_garden": {"fp": (20, 14), "items": [("garden_gnome", 1, "f"), ("toy_car", 2, "f"), ("wheelie_bin", 2, "m"), ("bicycle", 1, "m"), ("paddling_pool", 1, "m"), ("trampoline", 1, "b"), ("garden_shed", 1, "b")]},
    "park_kit": {"fp": (20, 12), "items": [("napkin", 3, "f"), ("water_bottle", 2, "f"), ("deckchair", 3, "m"), ("bench", 2, "b"), ("flower_planter", 2, "b"), ("bush", 2, "b")]},
    "playground": {"fp": (90, 70), "items": [("marble", 8, "f"), ("toy_car", 4, "f"), ("football", 2, "m"), ("trampoline", 3, "m"), ("see_saw", 1, "m"), ("roundabout", 1, "b"), ("swing_set", 1, "b"), ("slide_tower", 1, "b")]},
    "island_stash": {"fp": (24, 24), "items": [("rubber_duck", 6, "f"), ("cupcake", 3, "f"), ("sandwich", 3, "m"), ("watermelon", 2, "m"), ("cool_box", 2, "m"), ("picnic_basket", 2, "b"), ("inflatable_flamingo", 1, "b"), ("golden_acorn", 1, "m")]},
    "squirrel_stash": {"fp": (10, 10), "items": [("acorn", 4, "f"), ("conker", 4, "m"), ("mushroom_cluster", 2, "b"), ("birds_nest", 2, "b")]},
    "maze_centre": {"fp": (16, 16), "items": [("gnome_hat", 3, "f"), ("garden_gnome", 6, "m"), ("watering_can", 3, "m"), ("bird_bath", 2, "b"), ("gnome_king", 1, "b")]},
    "grove": {"fp": (36, 36), "items": [("leaf", 4, "f"), ("acorn", 3, "f"), ("pine_cone", 2, "f"), ("mushroom_cluster", 2, "m"), ("birds_nest", 1, "m"), ("bush", 3, "m"), ("big_tree", 3, "b")]},
    "meadow": {"fp": (40, 26), "items": [("daisy", 5, "f"), ("ladybird", 1, "f"), ("tulip", 5, "m"), ("rose", 3, "m"), ("bird_bath", 1, "b"), ("deckchair", 2, "b")]},
    "orchard": {"fp": (44, 30), "items": [("strawberry", 3, "f"), ("apple", 6, "f"), ("picnic_basket", 1, "m"), ("wheelbarrow", 1, "m"), ("fruit_tree", 5, "b")]},
    "lawn_games": {"fp": (36, 24), "items": [("boules_set", 2, "f"), ("tennis_ball", 2, "f"), ("frisbee", 1, "m"), ("football", 1, "m"), ("giant_chess_piece", 6, "m"), ("deckchair", 2, "b"), ("picnic_table", 2, "b")]},
    "football_pitch": {"fp": (40, 60), "items": [("bottle_cap", 2, "f"), ("football", 2, "m"), ("traffic_cone", 6, "m"), ("water_bottle", 2, "m"), ("goal", 2, "b"), ("bench", 2, "b")]},
    "log_pile": {"fp": (24, 16), "items": [("pine_cone", 2, "f"), ("snail_shell", 2, "f"), ("mushroom_cluster", 1, "m"), ("log", 6, "m"), ("wheelbarrow", 1, "b"), ("hammock", 1, "b")]},
    "roof_stash": {"fp": (14, 14), "items": [("helmet", 2, "f"), ("skateboard", 3, "m"), ("cool_box", 2, "m"), ("deckchair", 2, "b"), ("barbecue_small", 1, "b")]},
}

# --------------------------------------------------------------------------------------------------------------
# Layout state
# --------------------------------------------------------------------------------------------------------------
layout: dict = {
    "version": 1,
    "units": "studs; x east, z south, y up; origin at the Plaza",
    "world": {"halfExtent": 500, "outerHalfExtent": 620, "hub": {"x": -760, "z": 0}, "startDiameter": 1},
    "zones": [], "blocks": [], "spawns": [], "scenes": [], "trails": [], "rails": [], "pads": [],
    "catapults": [], "gates": [], "golden": [], "landmarks": [], "hazards": [], "water": [],
}


def zone(zid, name, x0, z0, x1, z1, tiers):
    layout["zones"].append({"id": zid, "name": name, "rect": [x0, z0, x1, z1], "tiers": tiers})


def block(bid, kind, x0, z0, x1, z1, y0=0.0, y1=0.2, label=None):
    layout["blocks"].append({"id": bid, "kind": kind, "rect": [x0, z0, x1, z1], "y": [y0, y1], "label": label})


def _hash(*vals) -> float:
    h = 2166136261
    for v in vals:
        for ch in str(v):
            h = ((h ^ ord(ch)) * 16777619) & 0xFFFFFFFF
    return (h % 100000) / 100000.0


def scene(sid, kind, x, z, yaw=0, zone_id="", y=0.0, label=None, fp=None, scale=1.0):
    """Place a scene. yaw: direction the FRONT faces, degrees, 0 = north (-z), 90 = east (+x)."""
    k = SCENE_KINDS[kind]
    w, d = fp or k["fp"]
    items = []
    bands = {"f": (0.1, 0.38), "m": (0.38, 0.68), "b": (0.68, 0.92)}
    a = math.radians(yaw)
    fx, fz = math.sin(a), -math.cos(a)  # front direction
    rx, rz = math.cos(a), math.sin(a)  # right
    # City scenes skip their crumb layer: a ball in the city is past Tier 1 (keeps light objects in the park).
    min_tier = 1 if (zone_id.startswith("park") or zone_id == "") else 2
    for obj, count, band in k["items"]:
        if tier(obj) < min_tier:
            continue
        n = max(1, round(count * scale)) if count > 1 else count
        lo, hi = bands[band]
        cols = max(1, math.ceil(math.sqrt(n * w / max(d * (hi - lo), 1))))
        for i in range(n):
            u = ((i % cols) + 0.5) / cols - 0.5 + (_hash(sid, obj, i, "u") - 0.5) * 0.6 / cols
            depth_frac = lo + (hi - lo) * ((i // cols + 0.5) / max(1, math.ceil(n / cols)))
            depth_frac += (_hash(sid, obj, i, "v") - 0.5) * (hi - lo) * 0.4
            back = (depth_frac - 0.5) * d  # + towards the back
            ox = u * w * rx - back * fx
            oz = u * w * rz - back * fz
            items.append({
                "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 2),
                "x": round(x + ox, 2), "z": round(z + oz, 2), "y": y,
                "yaw": round((yaw + (_hash(sid, obj, i, "y") - 0.5) * 30) % 360, 1),
            })
    layout["scenes"].append({
        "id": sid, "kind": kind, "zone": zone_id, "x": x, "z": z, "y": y, "yaw": yaw, "footprint": [w, d],
        "label": label, "items": items,
    })


def trail(tid, cause, pts, objs, spacing, zone_id="", y=0.0):
    items = []
    seg_lens = [math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)]
    total = sum(seg_lens)
    n = max(1, int(total // spacing))
    for i in range(n):
        s = (i + 0.5) * total / n
        j = 0
        while j < len(seg_lens) - 1 and s > seg_lens[j]:
            s -= seg_lens[j]
            j += 1
        (x0, z0), (x1, z1) = pts[j], pts[j + 1]
        f = s / seg_lens[j] if seg_lens[j] else 0
        jitter = (_hash(tid, i) - 0.5) * 2.0
        nx, nz = -(z1 - z0), x1 - x0
        nl = math.hypot(nx, nz) or 1
        obj = objs[i % len(objs)]
        items.append({"object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 2),
                      "x": round(x0 + (x1 - x0) * f + nx / nl * jitter, 2),
                      "z": round(z0 + (z1 - z0) * f + nz / nl * jitter, 2), "y": y, "yaw": 0})
    layout["trails"].append({"id": tid, "cause": cause, "zone": zone_id, "points": pts, "items": items})


def rail(rid, name, pts3, dmin, dmax, speed, exit_="launch"):
    layout["rails"].append({"id": rid, "name": name, "points": pts3, "dMin": dmin, "dMax": dmax, "speed": speed, "exit": exit_})


def pad(pid, kind, x, z, yaw, w, d, y=0.0, **extra):
    layout["pads"].append({"id": pid, "kind": kind, "x": x, "z": z, "y": y, "yaw": yaw, "size": [w, d], **extra})


def landmark(lid, obj, x, z, yaw=0, y=0.0):
    layout["landmarks"].append({"id": lid, "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 1),
                                "needsD": round(needs_d(obj), 1), "x": x, "z": z, "y": y, "yaw": yaw})


def golden(gid, x, z, y=0.0, where=""):
    layout["golden"].append({"id": gid, "x": x, "z": z, "y": y, "where": where})


# ==============================================================================================================
# The map
# ==============================================================================================================
# Rings and zones
for q, sx, sz in (("nw", -1, -1), ("ne", 1, -1), ("se", 1, 1), ("sw", -1, 1)):
    zone(f"park_{q}", {"nw": "Woods and Campsite", "ne": "Pond and Boathouse", "se": "Playground, Skate Park and Courts",
                       "sw": "Gardens and Hedge Maze"}[q],
         min(0, sx * 500), min(0, sz * 500), max(0, sx * 500), max(0, sz * 500), [1, 2, 3])
zone("ring_road", "Ring Road", -300, -300, 300, 300, [3, 4])
zone("nbh_ne", "Market Street and Roof Run", 20, -260, 260, -150, [3, 4, 5])
zone("nbh_se", "Car Park and Building Site", 150, 20, 260, 260, [4, 5])
zone("nbh_sw", "Terraces and Cottages", -260, 150, -20, 260, [4, 5])
zone("nbh_nw", "Station and Rail Yard", -260, -260, -20, -130, [3, 4, 5])
zone("downtown", "Downtown", -150, -150, 150, 150, [5, 6])

# Ground and roads
block("ground_park", "grass", -500, -500, 500, 500, -1, 0)
block("ring_road", "road", -300, -300, 300, 300, 0, 0.1)
block("city_ground", "pavement", -260, -260, 260, 260, 0, 0.3)
block("downtown_ground", "plaza", -150, -150, 150, 150, 0.3, 0.4)
for sid, (x0, z0, x1, z1) in {
    "spoke_n": (-20, -300, 20, -150), "spoke_s": (-20, 150, 20, 300),
    "spoke_w": (-300, -20, -150, 20), "spoke_e": (150, -20, 300, 20),
}.items():
    block(sid, "road", x0, z0, x1, z1, 0.3, 0.35)
for sid, (x0, z0, x1, z1) in {
    "path_n": (-10, -500, 10, -300), "path_s": (-10, 300, 10, 500),
    "path_w": (-500, -10, -300, 10), "path_e": (300, -10, 500, 10),
}.items():
    block(sid, "gravel", x0, z0, x1, z1, 0, 0.05)
# Park Loop path: a square ring at m = 400, 10 wide
for sid, (x0, z0, x1, z1) in {
    "loop_n": (-405, -405, 405, -395), "loop_s": (-405, 395, 405, 405),
    "loop_w": (-405, -405, -395, 405), "loop_e": (395, -405, 405, 405),
}.items():
    block(sid, "gravel", x0, z0, x1, z1, 0, 0.05)
block("park_edge", "railing", -302, -302, 302, 302, 0, 3, "railing + hedge line, 8 gates")
block("boundary", "wall", -500, -500, 500, 500, 0, 200, "invisible boundary")

# Spawns and doorsteps
SPAWNS = [(-450, -450, "nw"), (-180, -440, "nw"), (-440, -180, "nw"),
          (180, -440, "ne"), (450, -450, "ne"), (440, -180, "ne"),
          (450, 450, "se"), (180, 440, "se"), (440, 180, "se"),
          (-180, 440, "sw"), (-450, 450, "sw"), (-440, 180, "sw")]
DOORSTEP = {"nw": "doorstep_acorn", "ne": "doorstep_duck", "se": "doorstep_toys", "sw": "doorstep_flower"}
for i, (x, z, q) in enumerate(SPAWNS, 1):
    # The front of the doorstep faces the city (towards the origin).
    yaw = math.degrees(math.atan2(-x, z)) % 360
    layout["spawns"].append({"id": f"spawn_{i:02d}", "x": x, "z": z, "quarter": q, "facing": round(yaw, 1)})
    scene(f"doorstep_{i:02d}", DOORSTEP[q], x, z, round(yaw, 1), f"park_{q}", label=f"Spawn {i}")

# Trails from each spawn to the Park Loop (the tutorial line), Tier 1 then the top of Tier 1
TRAIL_OBJS = {"nw": ["acorn", "conker", "pine_cone", "leaf"], "ne": ["breadcrumb", "feather", "pebble", "berry"],
              "se": ["marble", "toy_brick", "bottle_cap", "tennis_ball"], "sw": ["petal", "daisy", "seed_packet", "strawberry"]}
TRAIL_CAUSE = {"nw": "a squirrel's acorn line", "ne": "a leaking bag of bird seed", "se": "toys dropped from a bag",
               "sw": "petals blown off the beds"}
for i, (x, z, q) in enumerate(SPAWNS, 1):
    # Head for the nearest point of the loop at m = 400, then along it 60 studs towards the quarter's set piece.
    if abs(x) >= abs(z):
        tx, tz = math.copysign(400, x), z * 0.85
    else:
        tx, tz = x * 0.85, math.copysign(400, z)
    trail(f"trail_{i:02d}", TRAIL_CAUSE[q], [[x, z], [tx, tz]], TRAIL_OBJS[q], 8.0, f"park_{q}")
# The Park Loop trail: the long open route of Tier 1 - 2, one per side, mixed objects
LOOP_OBJS = ["apple", "toadstool", "watermelon", "mushroom_cluster", "football", "helmet", "picnic_basket", "cabbage"]
for side, pts in {"n": [[-380, -400], [380, -400]], "s": [[380, 400], [-380, 400]],
                  "w": [[-400, 380], [-400, -380]], "e": [[400, -380], [400, 380]]}.items():
    trail(f"loop_{side}", "things dropped along the Park Loop", pts, LOOP_OBJS, 12.0, "park")

# ---------------- NW: Woods and Campsite ----------------
Z = "park_nw"
block("woods_floor", "woods", -500, -500, -300, -300, 0, 0.05, "woods")
scene("glade_ring_1", "fairy_ring", -445, -312, 135, Z, label="fairy ring")
scene("glade_ring_2", "fairy_ring", -418, -288, 160, Z, label="fairy ring")
scene("glade_ring_3", "fairy_ring", -440, -280, 100, Z, label="fairy ring")
for k, (bx, bz) in enumerate(((-455, -300), (-430, -325), (-405, -300), (-430, -275))):
    pad(f"bouncecap_{k + 1}", "bounce", bx, bz, 0, 3, 3, 2.0, up=5, forward=0, dMax=6, object="mushroom_bouncecap")
block("glade_log", "log_platform", -420, -318, -400, -310, 0, 5, "log platform y 5")
scene("glade_log_stash", "squirrel_stash", -410, -314, 180, Z, y=5, label="log stash (bounce up)")
block("oak_trunk", "tree_trunk", -382, -382, -358, -358, 0, 40, "Giant Oak trunk")
block("oak_deck", "deck", -382, -382, -358, -358, 22, 23, "tree house deck y 22")
block("oak_ramp", "spiral", -396, -396, -344, -344, 0, 22, "root ramp: 2 turns round the trunk, 8 wide, 12 deg")
scene("oak_deck_picnic", "picnic", -370, -370, 135, Z, y=23, label="tree house picnic + Magnet", scale=0.8)
scene("oak_fall_1", "acorn_fall", -342, -380, 135, Z, label="acorn fall")
scene("oak_fall_2", "acorn_fall", -380, -342, 315, Z, label="acorn fall")
layout["tunnels"] = []
for k, (ax, az) in enumerate(((-428, -306), (-424, -328), (-404, -302))):
    layout["tunnels"].append({"id": f"root_tunnel_{k + 1}", "points": [[ax, az], [-386, -386]], "width": 3, "height": 3,
                              "note": "small only (D < 3)"})
scene("root_stash", "squirrel_stash", -378, -378, 45, Z, label="root tunnel stash (under the oak)")
golden("gold_roots", -378, -378, 0, "root tunnel stash")
golden("gold_treehouse", -370, -370, 23, "tree house deck")
rail("R4", "Tree House Zipline", [[-370, 24, -370], [-305, 2, -305]], 2, 8, 34)
layout["water"].append({"id": "stream", "kind": "wading", "rect": [-325, -500, -315, -300], "depth": 1.5})
block("footbridge", "bridge", -330, -474, -310, -466, 0, 1.5, "footbridge")
for k in range(4):
    block(f"stepping_{k + 1}", "stone", -326 + k * 3.2, -362, -324.5 + k * 3.2, -358, 0, 0.6, None)
rail("R1", "Fallen Log", [[-335, 1, -445], [-305, 1, -435]], 1, 6, 18)
scene("campsite", "campsite", -455, -90, 90, Z, label="Campsite")
scene("nw_picnic", "picnic", -260, -440, 180, Z, label="picnic")
scene("nw_flowers", "flower_bed", -430, -230, 90, Z, label="flower bed")
scene("nw_kit_1", "park_kit", -360, -416, 0, Z, label="benches by the loop")
scene("nw_kit_2", "park_kit", -416, -120, 90, Z, label="benches by the loop")
scene("nw_ice", "ice_cream_stop", -420, -40, 90, Z, label="ice-cream stop")
scene("nw_school", "school_run", -230, -330, 180, Z, label="school run")
landmark("giant_oak", "giant_oak", -370, -370)

# ---------------- NE: Pond and Boathouse ----------------
# The pond sits in the band between the park edge (m 302) and the Park Loop (m 395), north side, x 110 - 250.
Z = "park_ne"
PX, PZ, PRX, PRZ = 180, -350, 70, 42
layout["water"].append({"id": "pond", "kind": "deep_until", "ellipse": [PX, PZ, PRX, PRZ], "depth": 5, "wadeFromD": 10,
                        "winter": "ice: slick, rink boards, thin ice ring r 15-22 around the island breaks above D 6"})
block("island", "island", PX - 15, PZ - 15, PX + 15, PZ + 15, 0, 1.5, "Duck Island")
scene("island_stash", "island_stash", PX, PZ, 270, Z, y=1.5, label="Duck Island stash")
golden("gold_island", PX + 5, PZ - 5, 1.5, "Duck Island")
for k in range(8):  # 8 pads, 4 wide, gaps 2.5, west shore to the island
    pad(f"lilypad_{k + 1}", "platform", PX - PRX + 4.5 + k * 6.5, PZ, 0, 4, 4, 0.2, object="lily_pad")
for k in range(12):
    dx, dz = PX - PRX + 7.5 + k * 4.3, PZ + (6 if k % 2 else -6)
    layout["scenes"].append({"id": f"duck_{k + 1}", "kind": "floating", "zone": Z, "x": dx, "z": dz, "y": 0.2, "yaw": 0,
                             "footprint": [1, 1], "label": None,
                             "items": [{"object": "rubber_duck", "tier": tier("rubber_duck"), "bulk": round(bulk("rubber_duck"), 2),
                                        "x": dx, "z": dz, "y": 0.2, "yaw": 0}]})
block("jetty", "jetty", PX - 4, PZ + PRZ - 16, PX + 4, PZ + PRZ + 2, 0, 1.5, "jetty")
pad("diving_board", "bounce", PX, PZ + PRZ - 16, 0, 3, 6, 1.5, up=8, forward=14, dMax=6)
rail("R2", "Drain Pipe", [[PX, 0.5, PZ - PRZ - 2], [PX, 0.5, PZ - 15]], 1, 5, 20)
scene("boat_hire", "boat_hire", PX + PRX + 12, PZ, 270, Z, label="Boat hire")
scene("ne_picnic", "picnic", 360, -200, 270, Z, label="Picnic Lawn")
scene("ne_party", "birthday_party", 360, -150, 270, Z, label="birthday party")
scene("ne_duck_feed_1", "duck_feeding", PX - 75, PZ + 25, 90, Z, label="duck feeding")
scene("ne_duck_feed_2", "duck_feeding", PX + 40, PZ + PRZ + 4, 0, Z, label="duck feeding")
scene("ne_flowers", "flower_bed", 440, -330, 270, Z, label="flower bed")
scene("ne_kit_1", "park_kit", 330, -440, 0, Z, label="benches by the loop")
scene("ne_kit_2", "park_kit", 440, -260, 270, Z, label="benches by the loop")
scene("ne_ice", "ice_cream_stop", 420, -40, 270, Z, label="ice-cream stop")
landmark("giant_duck", "giant_duck", 250, -430)

# ---------------- SE: Playground, Skate Park and Courts ----------------
Z = "park_se"
scene("playground", "playground", 349, 235, 270, Z, label="Playground")
block("slide_tower", "tower", 375, 250, 385, 262, 0, 10, "slide tower y 10")
block("sandpit", "sand", 330, 210, 355, 230, 0, 0.1, "sandpit (slow)")
scene("sandpit_toys", "sandpit", 342, 220, 270, Z, label="sandpit")
pad("slide_launch", "bounce", 360, 255, 270, 4, 6, 4, up=6, forward=16, dMax=12, note="end of the slide")
layout["hazards"].append({"id": "roundabout", "kind": "spinner", "x": 320, "z": 250, "radius": 4.5, "flingsBelowD": 5, "object": "roundabout"})
block("skate_bowl", "bowl", 310, 315, 350, 365, -6, 0, "bowl 6 deep")
block("quarter_pipe_1", "ramp", 358, 305, 390, 313, 0, 5, "quarter pipe")
block("quarter_pipe_2", "ramp", 358, 367, 390, 375, 0, 5, "quarter pipe")
block("funbox", "box", 358, 330, 372, 350, 0, 2, "funbox")
block("kicker", "ramp", 378, 335, 388, 345, 0, 3, "kicker")
block("skate_shelter_roof", "roof", 306, 378, 326, 392, 0, 14, "skate shelter roof y 14 (stash)")
scene("skate_roof_stash", "roof_stash", 316, 385, 0, Z, y=14, label="shelter roof stash")
golden("gold_skate_roof", 318, 386, 14, "skate shelter roof")
rail("R3a", "Skate Handrail", [[365, 2.5, 328], [365, 2.5, 352]], 2, 12, 26)
rail("R3b", "Skate Handrail", [[340, 2, 312], [356, 2, 312]], 2, 12, 26)
rail("R3c", "Skate Handrail", [[318, 2, 368], [334, 2, 368]], 2, 12, 26)
pad("boost_bowl_w", "boost", 305, 340, 90, 8, 12)
pad("boost_bowl_n", "boost", 338, 300, 180, 8, 12)
scene("skate_spot_1", "skate_spot", 330, 300, 0, Z, label="skate spot")
scene("skate_spot_2", "skate_spot", 380, 385, 180, Z, label="skate spot")
scene("courts", "tennis_court", 260, 430, 270, Z, label="tennis court")
scene("courts_school", "school_run", 300, 455, 0, Z, label="five-a-side")
scene("se_picnic", "picnic", 200, 330, 0, Z, label="picnic")
scene("se_kit_1", "park_kit", 440, 300, 270, Z, label="benches by the loop")
scene("se_kit_2", "park_kit", 330, 440, 0, Z, label="benches by the loop")
scene("se_ice", "ice_cream_stop", 40, 420, 0, Z, label="ice-cream stop")
landmark("ferris_wheel", "ferris_wheel", 450, 330, 90)

# ---------------- SW: Gardens and Hedge Maze ----------------
Z = "park_sw"
# Maze: 90 x 90, hedge lines on a 6-wide corridor grid (a hand-drawn pattern of 15 x 15 cells of 6 studs).
MAZE = [
    "###############",
    "#.....#.......#",
    "#.###.#.#####.#",
    "#.#...#.#...#.#",
    "#.#.###.#.#.#.#",
    "#.#.....#.#...#",
    "#.####....###.#",
    "#......C......#",
    "#####.....#####",
    "#.....#...#...#",
    "#.#########.#.#",
    "#...#.....#.#.#",
    "###.#.###.#.#.#",
    "#.....#.....#.#",
    "#######.#######",
]
mx0, mz0 = -394, 304
hedges = 0
for r, row in enumerate(MAZE):
    for c, ch in enumerate(row):
        if ch == "#":
            hedges += 1
            block(f"hedge_{r:02d}_{c:02d}", "hedge", mx0 + c * 6, mz0 + r * 6, mx0 + c * 6 + 6, mz0 + r * 6 + 6, 0, 3, None)
scene("maze_centre", "maze_centre", mx0 + 7 * 6 + 3, mz0 + 7 * 6 + 3, 0, Z, label="Gnome King")
golden("gold_maze", mx0 + 7 * 6 + 3, mz0 + 7 * 6 + 3, 0, "maze centre")
for k, (fx, fz) in enumerate([(x, z) for z in (420, 436) for x in (-326, -298, -270)]):
    scene(f"sw_flowers_{k + 1}", "flower_bed", fx, fz, 0, Z, label="formal flower garden" if k == 1 else None)
scene("sw_roses_1", "flower_bed", -312, 454, 180, Z, label="rose garden")
scene("sw_roses_2", "flower_bed", -284, 454, 180, Z, label=None)
ALLOT = [(x, z) for z in (232, 252, 272, 292) for x in (-470, -440)]
for k, (ax, az) in enumerate(ALLOT):
    scene(f"allotment_{k + 1}", "allotment_plot", ax, az, 90 if ax < -455 else 270, Z, label="allotment" if k < 2 else None,
          fp=(16, 24))
block("allotment_path", "gravel", -458, 222, -452, 302, 0, 0.05, None)
block("greenhouse", "glass", -478, 306, -460, 316, 0, 10, "greenhouse, door 2.5 wide")
layout["water"].append({"id": "sprinklers", "kind": "slick", "rect": [-260, 320, -200, 380]})
scene("sprinkler_reward", "picnic", -170, 350, 270, Z, label="picnic past the sprinklers", scale=0.8)
layout["hazards"].append({"id": "lawnmower", "kind": "sweeper", "object": "lawnmower",
                          "path": [[-290, 312], [-195, 312], [-195, 388], [-290, 388]], "speed": 8, "eatenFromD": 6.2})
scene("sw_party", "birthday_party", -440, 360, 90, Z, label="birthday party")
scene("sw_kit_1", "park_kit", -360, 470, 0, Z, label="benches")
scene("sw_kit_2", "park_kit", -440, 320, 90, Z, label="benches by the loop")
scene("sw_ice", "ice_cream_stop", -40, 420, 0, Z, label="ice-cream stop")
landmark("windmill", "windmill", -290, 470)

# Catapults (rest direction towards the city)
for cid, x, z in (("C1", -330, -250), ("C2", 330, -250), ("C3", 260, 330), ("C4", -330, 250)):
    yaw = math.degrees(math.atan2(-x, z)) % 360
    layout["catapults"].append({"id": cid, "kind": "catapult", "x": x, "z": z, "restYaw": round(yaw, 1), "aimArc": 60,
                                "dMin": 2, "dMax": 12, "range": [80, 260], "apex": 60})

# ---------------- Ring Road ----------------
for k, (x, z) in enumerate(((-150, -280), (150, -280), (280, -150), (280, 150), (150, 280), (-150, 280), (-280, 150), (-280, -150))):
    yaw = {(-150, -280): 90, (150, -280): 90, (280, -150): 180, (280, 150): 180, (150, 280): 270, (-150, 280): 270,
           (-280, 150): 0, (-280, -150): 0}[(x, z)]
    pad(f"boost_ring_{k + 1}", "boost", x, z, yaw, 20, 30)
SPOKE_GATES = {"n": (0, -316, 180), "e": (316, 0, 270), "s": (0, 316, 0), "w": (-316, 0, 90)}
for g, (x, z, yaw) in SPOKE_GATES.items():
    ax, az = (x + 34, z) if g in "ns" else (x, z + 34)
    bx, bz = (x - 34, z) if g in "ns" else (x, z - 34)
    scene(f"gate_{g}", "gate_corner", ax, az, yaw, "ring_road", label=f"gate corner {g.upper()}")
    scene(f"gate_{g}_ice", "ice_cream_stop", bx, bz, yaw, "ring_road", label="ice-cream stop")
    layout["gates"].append({"id": f"park_gate_{g}", "x": x, "z": z * 1.0, "kind": "open gate in the railing (Spoke)"})
DIAG_GATES = {"ne": (318, -318, (322, -330)), "se": (318, 318, (296, 330)), "sw": (-250, 318, (-290, 320)),
              "nw": (-318, -318, (-300, -330))}
for g, (x, z, (bx, bz)) in DIAG_GATES.items():
    scene(f"gate_{g}_bikes", "bike_rack", bx, bz, 0, "ring_road", label="bike rack")
    layout["gates"].append({"id": f"park_gate_{g}", "x": x, "z": z, "kind": "open gate in the railing (diagonal)"})
    layout["gates"].append({"id": f"drain_{g}", "x": x * 0.9, "z": z * 0.9, "kind": "drain 3 wide (small only)",
                            "from": [x, z], "to": [x * 0.78, z * 0.78]})
    layout.setdefault("tunnels", []).append({"id": f"drain_{g}", "points": [[x, z], [x * 0.78, z * 0.78]], "width": 3,
                                             "height": 3, "note": "storm drain under the ring road (small only)"})
layout["hazards"].append({"id": "traffic", "kind": "traffic_loop", "loop_m": 280, "speed": 24,
                          "convoy": ["hatchback", "hatchback", "van", "taxi", "hatchback", "hatchback", "city_bus",
                                     "hatchback", "taxi", "van", "hatchback", "hatchback", "hatchback"],
                          "bumpsBelowD": 15})
for k, (x, z, yaw) in enumerate(((-200, -314, 180), (80, -314, 180), (314, 150, 270), (-314, -200, 90))):
    scene(f"ring_busstop_{k + 1}", "bus_stop", x, z, yaw, "ring_road", label="bus stop")
for k, (x, z, yaw) in enumerate(((-100, -248, 0), (248, -100, 90), (-248, 100, 270))):
    scene(f"ring_parking_{k + 1}", "parking_row", x, z, yaw, "ring_road", label="parking row")

# ---------------- NE: Market Street and the Roof Run ----------------
Z = "nbh_ne"
block("market_street", "road", 30, -215, 262, -185, 0.3, 0.35, "Market Street")
ROOFS = [(245, 10), (220, 12), (193, 12), (168, 14), (140, 16), (113, 16), (85, 18), (47, 20)]
for k, (cx, h) in enumerate(ROOFS, 1):
    block(f"roof_{k}", "roof", cx - 9, -245, cx + 9, -219, 0, h, f"roof {k}, y {h}")
    scene(f"roof_{k}_kit", "rooftop_plant" if k % 2 else "rooftop_garden", cx, -232, 180, Z, y=h, label=None)
    OBJECTS[f"roof_building_{k}"] = (18.0, 26.0, float(h))
    layout["landmarks"].append({"id": f"roof_building_{k}", "object": f"roof_building_{k}", "tier": tier(f"roof_building_{k}"),
                                "bulk": round(bulk(f"roof_building_{k}"), 1), "needsD": round(needs_d(f"roof_building_{k}"), 1),
                                "x": cx, "z": -232, "y": 0, "yaw": 180, "note": "the roof is walkable; the building is food"})
gaps = [round((ROOFS[k][0] - 9) - (ROOFS[k + 1][0] + 9), 1) for k in range(len(ROOFS) - 1)]
layout["roofRun"] = {"roofs": [{"id": f"roof_{k}", "x": cx, "width": 18, "depth": 26, "y": h} for k, (cx, h) in enumerate(ROOFS, 1)],
                     "gaps": gaps, "braveGap": 7, "up": ["delivery ramp at the east end", "jump pad at (165, -205)"],
                     "down": "billboard ramp on roof 8, launching south over the hoardings to the Plaza"}
block("delivery_ramp", "ramp", 254, -245, 275, -219, 0, 10, "delivery ramp up to roof 1")
pad("roof_jump_pad", "spring", 165, -205, 0, 6, 6, 0.35, up=16, dMin=6, dMax=20)
pad("boost_brave_gap", "boost", 76, -232, 270, 8, 12, 18)
block("billboard_ramp", "ramp", 38, -245, 56, -228, 20, 26, "billboard ramp: launch south to the Plaza")
golden("gold_roof8", 47, -238, 20, "last roof of the Roof Run")
for k, cx in enumerate((230, 160, 125, 55)):
    layout["landmarks"].append({"id": f"market_shop_{k + 1}", "object": "corner_shop", "tier": tier("corner_shop"),
                                "bulk": round(bulk("corner_shop"), 1), "needsD": round(needs_d("corner_shop"), 1),
                                "x": cx, "z": -170, "y": 0, "yaw": 0})
for k, cx in enumerate((220, 180, 140, 100, 60)):
    scene(f"market_{k + 1}", "market_stall", cx, -200, 180 if k % 2 else 0, Z, label="market stall")
scene("market_cafe_1", "cafe_terrace", 195, -172, 0, Z, label="café terrace")
scene("market_cafe_2", "cafe_terrace", 90, -172, 0, Z, label="café terrace")

# ---------------- SE: Car Park and Building Site ----------------
Z = "nbh_se"
for k, y in enumerate((8, 16, 24), 1):
    block(f"carpark_deck_{k}", "deck", 160, 160, 235, 245, y - 1, y, f"car park deck {k}, y {y}")
    scene(f"carpark_row_{k}a", "parking_row", 197, 175, 0, Z, y=y, label=None)
    scene(f"carpark_row_{k}b", "parking_row", 197, 230, 180, Z, y=y, label=None)
block("carpark_ramp_1", "ramp", 236, 160, 248, 245, 0, 24, "spiral ramp, 12 deg")
block("carpark_ramp_2", "ramp", 148, 160, 160, 245, 0, 24, "spiral ramp, 12 deg")
golden("gold_carpark", 220, 200, 24, "car park top deck")
block("site_hoarding", "hoarding", 165, 40, 245, 130, 0, 8, "site hoardings")
scene("building_site", "building_site", 205, 85, 270, Z, label="Building Site")
block("container_platform", "deck", 220, 100, 240, 120, 11, 12, "container platform y 12")
landmark("crane_mast", "crane_mast", 205, 125)
rail("R6", "Crane Jib", [[200, 26, 165], [130, 30, 110]], 10, 35, 38)
scene("se_roadworks", "roadworks", 200, 30, 0, Z, label="roadworks")
layout["catapults"].append({"id": "S1", "kind": "big_slingshot", "x": 235, "z": 55, "restYaw": 300, "aimArc": 60,
                            "dMin": 12, "dMax": 45, "range": [150, 400], "apex": 90})

# ---------------- SW: Terraces and Cottages ----------------
Z = "nbh_sw"
block("terrace_street", "road", -265, 198, -20, 218, 0.3, 0.35, "Terrace Street")
HOUSES_N = [("cottage", -245), ("cottage", -220), ("terrace_house", -190), ("cottage", -158), ("cottage", -133),
            ("terrace_house", -103), ("cottage", -70)]
for k, (obj, cx) in enumerate(HOUSES_N, 1):
    layout["landmarks"].append({"id": f"house_n{k}", "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 1),
                                "needsD": round(needs_d(obj), 1), "x": cx, "z": 162, "y": 0, "yaw": 180})
    scene(f"garden_n{k}", "front_garden", cx, 186, 180, Z, label=None, fp=(18 if obj == "cottage" else 26, 12))
for k, (obj, cx) in enumerate(reversed(HOUSES_N), 1):
    layout["landmarks"].append({"id": f"house_s{k}", "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 1),
                                "needsD": round(needs_d(obj), 1), "x": cx, "z": 250, "y": 0, "yaw": 180})
    scene(f"garden_s{k}", "front_garden", cx, 230, 0, Z, label=None, fp=(18 if obj == "cottage" else 26, 12))
scene("sw_removal", "removal_van", -175, 208, 0, Z, label="removal van")
scene("sw_yard_sale", "yard_sale", -40, 176, 180, Z, label="yard sale")
for k, (x0, x1) in enumerate(((-260, -100), (-180, -40))):
    rail(f"R5{'ab'[k]}", "Washing Lines", [[x0, 4, 238 + k * 4], [x0 + 15, 4, 238 + k * 4]], 2, 8, 20)

# ---------------- NW: Station and Rail Yard ----------------
Z = "nbh_nw"
block("station_hall", "building", -250, -240, -190, -200, 0, 30, "station hall")
for k in range(4):
    block(f"track_{k + 1}", "track", -250, -186 + k * 8, -40, -182 + k * 8, 0.3, 0.6, f"track {k + 1}")
    rail(f"R7{'abcd'[k]}", "Rail Yard Track", [[-250, 0.6, -184 + k * 8], [-40, 0.6, -184 + k * 8]], 3, 20, 36)
scene("platform_1", "station_platform", -160, -193, 0, Z, label="platform 1", fp=(70, 8))
scene("platform_2", "station_platform", -175, -154, 180, Z, label="platform 2", fp=(50, 6))
for k in range(4):
    layout["landmarks"].append({"id": f"carriage_{k + 1}", "object": "train_carriage", "tier": tier("train_carriage"),
                                "bulk": round(bulk("train_carriage"), 1), "needsD": round(needs_d("train_carriage"), 1),
                                "x": -215 + k * 27, "z": -176, "y": 0.6, "yaw": 0})
block("skyrail_ramp", "spiral", -120, -230, -80, -190, 0, 30, "spiral ramp to the Sky Rail, y 30")
scene("nw_cafe", "cafe_terrace", -60, -230, 180, Z, label="station café")
scene("nw_bus", "bus_stop", -40, -215, 90, Z, label="bus stop")
layout["catapults"].append({"id": "S2", "kind": "big_slingshot", "x": -235, "z": -140, "restYaw": 120, "aimArc": 60,
                            "dMin": 12, "dMax": 45, "range": [150, 400], "apex": 90})

# Catapult stashes on low neighbourhood roofs
# (x, z, y, own block?) - four stashes sit on the roofs of existing buildings, two have their own small roof
for k, (x, z, y, own) in enumerate(((125, -170, 16, False), (160, -170, 16, False), (-70, 162, 20, False),
                                   (-245, 162, 20, False), (-150, -215, 25, True), (120, 175, 22, True)), 1):
    if own:
        block(f"stash_roof_{k}", "roof", x - 8, z - 8, x + 8, z + 8, 0, y, f"catapult stash y {y}")
    scene(f"stash_{k}", "roof_stash", x, z, 0, "neighbourhoods", y=y, label=f"catapult stash y {y}")
    pad(f"bullseye_{k}", "bullseye", x, z, 0, 6, 6, y)

# ---------------- Downtown ----------------
Z = "downtown"
for side, r in (("n", (-150, -152, 150, -148)), ("s", (-150, 148, 150, 152)), ("w", (-152, -150, -148, 150)), ("e", (148, -150, 152, 150))):
    block(f"hoarding_{side}", "hoarding", *r, 0, 12, "hoardings (bulk 8.3, food from D 17)")
for k, (x, z, yaw) in enumerate(((0, -150, 0), (0, 150, 0), (-150, 0, 90), (150, 0, 90))):
    layout["landmarks"].append({"id": f"spoke_truck_{k + 1}", "object": "delivery_truck", "tier": tier("delivery_truck"),
                                "bulk": round(bulk("delivery_truck"), 1), "needsD": round(needs_d("delivery_truck"), 1),
                                "x": x, "z": z, "y": 0.4, "yaw": yaw})
scene("plaza", "fountain_plaza", 0, 0, 0, Z, label="Plaza")
layout["landmarks"].append({"id": "theme_landmark", "object": "giant_duck", "tier": tier("giant_duck"), "bulk": round(bulk("giant_duck"), 1),
                            "needsD": round(needs_d("giant_duck"), 1), "x": 0, "z": 36, "y": 0.4, "yaw": 0,
                            "note": "theme slot: Giant Duck in city, Mega Tree in winter"})
TOWERS = {  # each block is x/z 60..140 from the axes; plots on a 2 x 2 grid at 80 and 120
    "ne": [("glass_tower", 120, -120), ("office_tower", 80, -120), ("cinema", 80, -80), ("corner_shop", 120, -80)],
    "nw": [("office_tower", -120, -120), ("office_tower", -80, -120), ("apartment_block", -80, -80), ("corner_shop", -120, -80)],
    "se": [("apartment_block", 80, 80), ("hotel", 120, 80), ("apartment_block", 80, 120), ("office_tower", 120, 120)],
    "sw": [("town_hall", -100, 80), ("library", -80, 120), ("corner_shop", -120, 120)],
}
for q, items in TOWERS.items():
    for k, (obj, x, z) in enumerate(items, 1):
        layout["landmarks"].append({"id": f"dt_{q}_{k}", "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 1),
                                    "needsD": round(needs_d(obj), 1), "x": x, "z": z, "y": 0.4, "yaw": 0})
golden("gold_glass_tower", 120, -120, 92, "Glass Tower helipad")
rail("R8", "Sky Rail", [[-145, 30, -145], [145, 30, -145], [145, 30, 145], [-145, 30, 145], [-145, 30, -145]], 25, 100, 48)
for k, (x, z) in enumerate(((25, -140), (-25, 140), (140, 25), (-140, -25))):
    pad(f"spring_skyrail_{k + 1}", "spring", x, z, 0, 8, 8, 0.4, up=32, dMin=25, dMax=100)
for k, (x, z, yaw) in enumerate(((40, -60, 0), (-40, 60, 180), (60, 40, 90), (-60, -40, 270))):
    scene(f"dt_cafe_{k + 1}", "cafe_terrace", x, z, yaw, Z, label="café terrace")
for k, (x, z, yaw) in enumerate(((30, -110, 90), (-30, 110, 270), (110, 30, 180), (-110, -30, 0))):
    scene(f"dt_bus_{k + 1}", "bus_stop", x, z, yaw, Z, label="bus stop")
for k, (x, z, yaw) in enumerate(((-30, -100, 90), (30, 100, 270))):
    scene(f"dt_parking_{k + 1}", "parking_row", x, z, yaw, Z, label="parking row")
layout["landmarks"].append({"id": "dt_bandstand", "object": "bandstand", "tier": tier("bandstand"), "bulk": round(bulk("bandstand"), 1),
                            "needsD": round(needs_d("bandstand"), 1), "x": -38, "z": -38, "y": 0.4, "yaw": 0})
layout["landmarks"].append({"id": "dt_donut_truck", "object": "donut_truck", "tier": tier("donut_truck"), "bulk": round(bulk("donut_truck"), 1),
                            "needsD": round(needs_d("donut_truck"), 1), "x": 35, "z": 30, "y": 0.4, "yaw": 90})
for k, (x, z, yaw) in enumerate(((0, -120, 180), (0, 120, 0), (120, 0, 270), (-120, 0, 90))):
    pad(f"boost_spoke_{k + 1}", "boost", x, z, yaw, 20, 30, 0.4, note="faces the Plaza")
landmark("station_hall", "station_hall", -220, -220)
landmark("car_park", "car_park", 197, 203)


# ---------------- Street furniture and trees along kerbs (rule-placed lines, the "street" scene) ----------------
def kerb_line(lid, zone_id, p0, p1, objs, spacing):
    trail(lid, "street furniture along the kerb", [list(p0), list(p1)], objs, spacing, zone_id)


KERB_MIX = ["street_tree", "bench", "wheelie_bin", "street_tree", "newspaper_box", "bike_bottle", "mailbox"]
for side in (-1, 1):
    kerb_line(f"kerb_spoke_n{side}", "nbh", (side * 24, -295), (side * 24, -155), KERB_MIX, 12)
    kerb_line(f"kerb_spoke_s{side}", "nbh", (side * 24, 155), (side * 24, 295), KERB_MIX, 12)
    kerb_line(f"kerb_spoke_w{side}", "nbh", (-295, side * 24), (-155, side * 24), KERB_MIX, 12)
    kerb_line(f"kerb_spoke_e{side}", "nbh", (155, side * 24), (295, side * 24), KERB_MIX, 12)
    kerb_line(f"kerb_dt_n{side}", "downtown", (side * 24, -145), (side * 24, -55), ["street_tree", "bench", "bin_large"], 14)
    kerb_line(f"kerb_dt_s{side}", "downtown", (side * 24, 55), (side * 24, 145), ["street_tree", "bench", "bin_large"], 14)
    kerb_line(f"kerb_dt_w{side}", "downtown", (-145, side * 24), (-55, side * 24), ["street_tree", "bench", "bin_large"], 14)
    kerb_line(f"kerb_dt_e{side}", "downtown", (55, side * 24), (145, side * 24), ["street_tree", "bench", "bin_large"], 14)
RING_MIX = ["street_tree", "bench", "bin_large", "street_tree", "newspaper_box", "mailbox", "e_scooter", "bicycle"]
for name, p0, p1 in (("n", (-250, -256), (250, -256)), ("s", (250, 256), (-250, 256)),
                     ("w", (-256, 250), (-256, -250)), ("e", (256, -250), (256, 250))):
    kerb_line(f"kerb_ring_{name}", "ring_road", p0, p1, RING_MIX, 16)
kerb_line("kerb_market_n", "nbh_ne", (35, -213), (255, -213), ["street_tree", "bench", "bicycle", "wheelie_bin"], 15)
kerb_line("kerb_market_s", "nbh_ne", (35, -187), (255, -187), ["street_tree", "e_scooter", "bin_large", "mailbox"], 15)
kerb_line("kerb_terrace_n", "nbh_sw", (-260, 200), (-25, 200), ["street_tree", "wheelie_bin", "bicycle", "hatchback"], 15)
kerb_line("kerb_terrace_s", "nbh_sw", (-260, 216), (-25, 216), ["street_tree", "wheelie_bin", "hatchback", "van"], 15)
# Park: bushes and benches along the Park Loop (the park kit route of Tier 3)
for name, p0, p1 in (("n", (-380, -412), (380, -412)), ("s", (380, 412), (-380, 412)),
                     ("w", (-412, 380), (-412, -380)), ("e", (412, -380), (412, 380))):
    trail(f"loop_kit_{name}", "benches, bins and bushes along the Park Loop", [list(p0), list(p1)],
          ["bush", "bench", "bin_large", "bush", "flower_planter", "bicycle"], 22, "park")

# ---------------- More parking and buildings ----------------
for k, (x, z, yaw) in enumerate(((-200, -130, 0), (-60, 140, 180), (200, 140, 180), (140, 200, 90), (220, -142, 0)), 1):
    scene(f"nbh_parking_{k}", "parking_row", x, z, yaw, "nbh", label="parking row")
BUILDINGS = [  # the four city blocks between the districts (east, west-north, west-south, south)
    ("apartment_block", 205, -105), ("hotel", 185, -70), ("cinema", 225, -68), ("apartment_block", 205, -38),
    ("library", -205, -100), ("corner_shop", -180, -55), ("corner_shop", -230, -55),
    ("corner_shop", -230, 60), ("corner_shop", -185, 60), ("cottage", -205, 110),
    ("apartment_block", 60, 250), ("apartment_block", 105, 250),
    ("corner_shop", -160, -245),
]
for k, (obj, x, z) in enumerate(BUILDINGS, 1):
    layout["landmarks"].append({"id": f"nbh_building_{k}", "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 1),
                                "needsD": round(needs_d(obj), 1), "x": x, "z": z, "y": 0, "yaw": 0})
DT_MORE: list = []
for k, (obj, x, z) in enumerate(DT_MORE, 1):
    layout["landmarks"].append({"id": f"dt_more_{k}", "object": obj, "tier": tier(obj), "bulk": round(bulk(obj), 1),
                                "needsD": round(needs_d(obj), 1), "x": x, "z": z, "y": 0.4, "yaw": 0})



# --------------------------------------------------------------------------------------------------------------
# Summary and checks
# --------------------------------------------------------------------------------------------------------------
def all_items():
    for s in layout["scenes"]:
        yield from s["items"]
    for t in layout["trails"]:
        yield from t["items"]
    for l in layout["landmarks"]:
        yield {"object": l["object"], "tier": l["tier"]}


def summary() -> dict:
    by_tier = {t: 0 for t in range(1, 7)}
    for it in all_items():
        by_tier[it["tier"]] += 1
    # Hedges are blocks that are food from D 4.8: count them as Tier 2 objects.
    by_tier[tier("hedge_piece")] += hedges
    light = by_tier[1] + by_tier[2]
    parts = sum(by_tier[t] for t in range(3, 7))
    return {"objectsByTier": by_tier, "lightObjects": light, "partObjects": parts, "total": light + parts,
            "scenes": len(layout["scenes"]), "trails": len(layout["trails"]), "blocks": len(layout["blocks"]),
            "hedgePieces": hedges, "roofGaps": gaps}


def footprint_box(cx, cz, w, d, yaw):
    a = math.radians(yaw)
    ex = abs(math.cos(a)) * w / 2 + abs(math.sin(a)) * d / 2
    ez = abs(math.sin(a)) * w / 2 + abs(math.cos(a)) * d / 2
    return (cx - ex, cz - ez, cx + ex, cz + ez)


def overlap(a, b, shrink=0.5):
    return a[0] + shrink < b[2] and b[0] + shrink < a[2] and a[1] + shrink < b[3] and b[1] + shrink < a[3]


def _thing_boxes():
    things = []
    for sc in layout["scenes"]:
        if sc["kind"] == "floating" or sc["y"] > 0.5:
            continue
        things.append((sc["id"], footprint_box(sc["x"], sc["z"], *sc["footprint"], sc["yaw"])))
    for lm in layout["landmarks"]:
        if lm.get("y", 0) > 0.5 or lm["id"].startswith("spoke_truck") or lm["id"].startswith("roof_building"):
            continue
        dims = OBJECTS[lm["object"]]
        things.append((lm["id"], footprint_box(lm["x"], lm["z"], dims[0], dims[1], lm.get("yaw", 0))))
    return things


SOLID_KINDS = {"bowl", "ramp", "box", "roof", "tower", "sand", "glass", "island", "jetty", "log_platform", "spiral",
               "tree_trunk", "deck", "building", "bridge", "stone"}


def _forbidden_boxes(include_solids: bool = True):
    forbidden = []
    for b in layout["blocks"]:
        if b["kind"] in ("gravel",) or b["id"] in ("market_street", "terrace_street") or b["id"].startswith("spoke_") \
                or b["id"].startswith("track_") or b["id"].startswith("hedge_"):
            forbidden.append((b["id"], tuple(b["rect"])))
    # ring road carriageway (m 262 - 300) as four strips
    forbidden += [("ring_n", (-300, -300, 300, -262)), ("ring_s", (-300, 262, 300, 300)),
                  ("ring_w", (-300, -300, -262, 300)), ("ring_e", (262, -300, 300, 300))]
    for w in layout["water"]:
        if "ellipse" in w:
            cx, cz, rx, rz = w["ellipse"]
            forbidden.append((w["id"], (cx - rx, cz - rz, cx + rx, cz + rz)))
        elif w["kind"] != "slick":
            forbidden.append((w["id"], tuple(w["rect"])))
    if include_solids:
        forbidden += [(b["id"], tuple(b["rect"])) for b in layout["blocks"] if b["kind"] in SOLID_KINDS]
        forbidden += [(pd["id"], (pd["x"] - 4, pd["z"] - 4, pd["x"] + 4, pd["z"] + 4)) for pd in layout["pads"]]
        forbidden += [(c["id"], (c["x"] - 6, c["z"] - 6, c["x"] + 6, c["z"] + 6)) for c in layout["catapults"]]
        for h in layout["hazards"]:
            if "path" in h:
                xs = [pt[0] for pt in h["path"]]
                zs = [pt[1] for pt in h["path"]]
                forbidden.append((h["id"], (min(xs) - 3, min(zs) - 3, max(xs) + 3, max(zs) + 3)))
            elif "radius" in h:
                forbidden.append((h["id"], (h["x"] - h["radius"], h["z"] - h["radius"], h["x"] + h["radius"], h["z"] + h["radius"])))
    return forbidden


def check_overlaps() -> list[str]:
    """Scenes and buildings must not sit on roads, paths, water or each other (ground level only)."""
    things = _thing_boxes()
    forbidden = _forbidden_boxes(include_solids=False)
    allowed_pairs = {("root_stash", "giant_oak"), ("playground", "sandpit_toys")}
    street_ok = {"market_street": ("market_",), "terrace_street": ("sw_removal",)}
    problems = []
    for tid, box in things:
        for fid, fbox in forbidden:
            if overlap(box, fbox):
                if fid in street_ok and tid.startswith(street_ok[fid]):
                    continue
                # Scenes meant to touch a path or the pond shore are allowed to overlap their own edge by design.
                if tid.startswith(("doorstep", "duck_", "kerb", "boat_hire", "ne_duck_feed")) and fid in ("pond",):
                    continue
                problems.append(f"{tid} overlaps {fid}")
    for i in range(len(things)):
        for j in range(i + 1, len(things)):
            if overlap(things[i][1], things[j][1], 1.0) and (things[i][0], things[j][0]) not in allowed_pairs \
                    and (things[j][0], things[i][0]) not in allowed_pairs:
                problems.append(f"{things[i][0]} overlaps {things[j][0]}")
    return problems


# ---------------- Park fill: themed natural places wherever the park is still empty ----------------
# Design rule (09-park-city-level.md, section 7): every point of the park is within FILL_RADIUS studs of food (about
# 3 s of rolling for a small ball). Hand-placed set pieces come first; this fills the rest with each quarter's own kind
# of place (groves in the Woods, meadows and orchards by the Pond, games and a pitch in the Playground quarter, orchards
# and meadows in the Gardens). Deterministic: same input, same output.
FILL_RADIUS = 40
FILL_THEMES = {"nw": ["grove", "log_pile", "meadow", "park_kit"], "ne": ["meadow", "orchard", "lawn_games", "park_kit", "grove"],
               "se": ["lawn_games", "football_pitch", "meadow", "orchard", "park_kit"],
               "sw": ["orchard", "meadow", "lawn_games", "park_kit", "grove"]}
SPAWN_CLEAR = 45  # nothing from the fill within this many studs of a spawn


def _food_points():
    pts = []
    for sc in layout["scenes"]:
        pts += [(i["x"], i["z"]) for i in sc["items"]]
    for t in layout["trails"]:
        pts += [(i["x"], i["z"]) for i in t["items"]]
    return pts


def _food_grid():
    from collections import defaultdict
    grid = defaultdict(list)
    for x, z in _food_points():
        grid[(int(x // 20), int(z // 20))].append((x, z))
    return grid


def _nearest(grid, x, z, r=FILL_RADIUS + 20):
    best = 1e9
    for i in range(int((x - r) // 20), int((x + r) // 20) + 1):
        for j in range(int((z - r) // 20), int((z + r) // 20) + 1):
            for px, pz in grid.get((i, j), ()):
                best = min(best, math.hypot(px - x, pz - z))
    return best


def _quarter(x, z):
    return ("n" if z < 0 else "s") + ("w" if x < 0 else "e")


def _in_park(box) -> bool:
    x0, z0, x1, z1 = box
    if max(abs(x0), abs(x1), abs(z0), abs(z1)) > 497:
        return False
    nx = 0 if x0 <= 0 <= x1 else min(abs(x0), abs(x1))
    nz = 0 if z0 <= 0 <= z1 else min(abs(z0), abs(z1))
    return max(nx, nz) >= 306  # the nearest point of the box is still outside the park edge


def _blocked(box) -> bool:
    for _, fbox in _forbidden_boxes():
        if overlap(box, fbox, 0.0):
            return True
    for _, tbox in _thing_boxes():
        if overlap(box, tbox, -2.0):  # keep a 2-stud gap between places
            return True
    return False


def fill_park() -> int:
    grid = _food_grid()
    placed = 0
    counters = {q: 0 for q in FILL_THEMES}
    cells = [(gx, gz) for gx in range(-495, 500, 10) for gz in range(-495, 500, 10) if max(abs(gx), abs(gz)) >= 310]
    for _ in range(3):  # later passes fill what is left between new places
        cells.sort(key=lambda c: (-_nearest(grid, *c), c))
        for (cx, cz) in cells:
            if _nearest(grid, cx, cz) <= FILL_RADIUS:
                continue
            if any(math.hypot(cx - sp["x"], cz - sp["z"]) < SPAWN_CLEAR for sp in layout["spawns"]):
                continue
            q = _quarter(cx, cz)
            kinds = FILL_THEMES[q]
            yaw = round(math.degrees(math.atan2(-cx, cz)) % 360 / 45) * 45 % 360  # front faces the city
            done = False
            for attempt in range(len(kinds)):
                kind = kinds[(counters[q] + attempt) % len(kinds)]
                # Variety: no two places of the same kind within 70 studs of each other.
                if any(sc["kind"] == kind and math.hypot(sc["x"] - cx, sc["z"] - cz) < 70 for sc in layout["scenes"]):
                    continue
                w, d = SCENE_KINDS[kind]["fp"]
                for turn in (0, 90):
                    box = footprint_box(cx, cz, w, d, (yaw + turn) % 360)
                    if _in_park(box) and not _blocked(box):
                        break
                else:
                    continue
                yaw = (yaw + turn) % 360
                done = True
                scene(f"fill_{q}_{counters[q] + 1:02d}", kind, cx, cz, yaw, f"park_{q}", label=kind.replace("_", " "))
                for it in layout["scenes"][-1]["items"]:
                    grid[(int(it["x"] // 20), int(it["z"] // 20))].append((it["x"], it["z"]))
                counters[q] += 1
                placed += 1
                break
            if not done:
                continue
    return placed


def coverage() -> dict:
    grid = _food_grid()
    out = {}
    for q, (sx, sz) in {"nw": (-1, -1), "ne": (1, -1), "se": (1, 1), "sw": (-1, 1)}.items():
        tot = far = 0
        for gx in range(5, 500, 10):
            for gz in range(5, 500, 10):
                x, z = sx * gx, sz * gz
                if max(abs(x), abs(z)) < 305:
                    continue
                tot += 1
                far += _nearest(grid, x, z) > FILL_RADIUS
        out[q] = round(100 * far / tot, 1)
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    layout["objects"] = {k: {"dims": list(v), "bulk": round(bulk(k), 2), "tier": tier(k), "needsD": round(needs_d(k), 1)}
                         for k, v in sorted(OBJECTS.items())}
    layout["sceneKinds"] = {k: {"footprint": list(v["fp"]), "items": [{"object": o, "count": c, "band": b} for o, c, b in v["items"]]}
                            for k, v in SCENE_KINDS.items()}
    before = coverage()
    filled = fill_park()
    layout["summary"] = summary()
    layout["summary"]["parkFill"] = {"placesAdded": filled, "farFromFoodPctBefore": before, "farFromFoodPct": coverage(),
                                     "rule": f"share of park cells more than {FILL_RADIUS} studs from food, by quarter"}
    problems = check_overlaps()
    layout["summary"]["overlaps"] = problems
    (OUT / "park-city-layout.json").write_text(json.dumps(layout, indent=1))
    summ = dict(layout["summary"])
    summ["overlaps"] = len(problems)
    print(json.dumps(summ, indent=1))
    for pr in problems:
        print("OVERLAP:", pr)


if __name__ == "__main__":
    main()
