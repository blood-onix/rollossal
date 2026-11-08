# Stage C of the 013 tween-appeal rework (Phase 9, owner request 2026-11-08: "we're missing small objects"). Run into
# kit_rework.py's namespace by load_stage_b(), so it uses the same builder vocabulary (bbx, rcy, usp, lmb, pg, smo, trs,
# tube, arc_pts, lobe_cluster).
#
# 1. The Downtown pocket set (tier 1 dt_* meshes the new-rule audit marks "upgrade") rebuilt in the kit style: smooth
#    round parts, real proportions, one accent. Keys and sizes are unchanged. Winter Downtown sits at the N10 ceiling
#    (550,000 unculled, 82 triangles of headroom), so the placement-weighted triangle sum of the set must not grow:
#    heavily placed meshes (basketball 90, bauble 96, headphones 67, takeout box 84) stay at or under their old counts,
#    and rarely placed heroes (duck, sneaker, keyboard) take the extra detail. Every mesh stays at or above its audit
#    floor (pocket 40, tier 1 150). The four audit "keep" meshes (aa_battery, mini_gift, puzzle_cube, takeout_box) are
#    not touched. Authoring units are the old recipe's (about one unit across).
# 2. New ck_* small objects, filling tier 1 and the low half of tier 2 (1.6-3.0 studs) that the kit lacked. Authored in
#    metres (UNIT 3.2 for a natural run); real size decides the stud size through kit_sizes.py.

PNK, SAND, WATER = "w-accent-pink", "w-sand", "w-water"


def octa(w, h, c=0.25):
    """Rounded rectangle outline (8 points, corners cut by c of the shorter side), centred on the origin."""
    k = min(w, h) * c
    x, y = w / 2, h / 2
    return [(-x + k, -y), (x - k, -y), (x, -y + k), (x, y - k), (x - k, y), (-x + k, y), (-x, y - k), (-x, -y + k)]


# ---------------------------------------------------------------------------------------------- 1. pocket set (dt_*)
def dt_bottle_cap():
    return [rcy((0, 0, 0.1), 0.5, 0.2, RED, 10, r2=0.47), rcy((0, 0, 0.215), 0.42, 0.03, MET, 10)]


def dt_basketball():
    return [usp((0, 0, 0.5), 0.5, ORG, (1, 1, 1), 10, 6), trs((0, 0, 0.5), 0.5, 0.03, MDK, 9, 3, True)]


def dt_bauble():
    return [usp((0, 0, 0.3), 0.3, RED, (1, 1, 1), 8, 5), rcy((0, 0, 0.63), 0.09, 0.1, YEL, 4)]


def dt_coffee_cup():
    return [rcy((0, 0, 0.42), 0.33, 0.84, WHT, 10, r2=0.42),
            rcy((0, 0, 0.45), 0.384, 0.3, WOOD, 10, r2=0.416),
            rcy((0, 0, 0.88), 0.45, 0.08, RUB, 10, r2=0.42)]


def dt_donut():
    return [trs((0, 0, 0.27), 0.5, 0.27, WOOD, 10, 6), trs((0, 0, 0.4), 0.5, 0.2, PNK, 10, 3)]


def dt_earbud_case():
    pts = [(-0.5, 0.2), (-0.4, 0.02), (0.4, 0.02), (0.5, 0.2), (0.5, 0.6), (0.4, 0.78), (-0.4, 0.78), (-0.5, 0.6)]
    return [smo(pg((0, 0, 0), pts, 0.6, WHT, "y")), bx((0, 0, 0.55), (0.98, 0.62, 0.025), MET)]


def dt_fairy_light_bulb():
    return [rcy((0, 0, 0.15), 0.13, 0.3, MDK, 10), usp((0, 0, 0.62), 0.27, GLIT, (0.9, 0.9, 1.25), 12, 7)]


def dt_game_controller():
    pts = [(-0.5, -0.02), (-0.38, -0.2), (0.0, -0.14), (0.38, -0.2), (0.5, -0.02), (0.44, 0.2), (0.15, 0.24),
           (-0.15, 0.24), (-0.44, 0.2)]
    return [smo(pg((0, 0, 0.14), pts, 0.2, TEAL, "z")),
            usp((-0.36, -0.2, 0.13), 0.18, TEAL, (1, 1.2, 0.75), 8, 4),
            usp((0.36, -0.2, 0.13), 0.18, TEAL, (1, 1.2, 0.75), 8, 4),
            bx((-0.26, 0.06, 0.25), (0.16, 0.05, 0.03), MDK), rcy((0.26, 0.06, 0.25), 0.07, 0.03, RED, 4)]


def dt_gingerbread_cookie():
    parts = [rcy((0, 0.33, 0.06), 0.18, 0.12, WOOD, 12), bbx((0, 0, 0.06), (0.34, 0.38, 0.12), WOOD, 0.04)]
    for sx in (-1, 1):
        parts += [lmb((sx * 0.15, 0.08, 0.06), (sx * 0.42, 0.15, 0.06), 0.08, 0.07, WOOD, 8),
                  lmb((sx * 0.08, -0.15, 0.06), (sx * 0.18, -0.45, 0.06), 0.08, 0.08, WOOD, 8),
                  rcy((sx * 0.06, 0.36, 0.125), 0.03, 0.01, WHT, 6)]
    parts += [rcy((0, y, 0.125), 0.035, 0.01, WHT, 6) for y in (0.1, 0.0, -0.1)]
    return parts


def dt_headphones():
    band = [(x, 0.0, z) for x, z in arc_pts(0.0, 0.45, 0.42, 0.0, math.pi, 4)]
    parts = tube(band, 0.05, TEAL, 5, joints=False)
    for sx in (-1, 1):
        parts += [rcy((sx * 0.45, 0, 0.3), 0.2, 0.16, MDK, 9, axis="x"),
                  bx((sx * 0.42, 0, 0.47), (0.06, 0.1, 0.14), TEAL)]
    return parts


def dt_ice_lolly():
    pts = [(-0.22, 0.5), (0.22, 0.5), (0.24, 0.95), (0.2, 1.12), (0.08, 1.2), (-0.08, 1.2), (-0.2, 1.12), (-0.24, 0.95)]
    return [bbx((0, 0, 0.27), (0.1, 0.04, 0.54), WOOD, 0.015), smo(pg((0, 0, 0), pts, 0.22, PNK, "y")),
            usp((0.15, 0.11, 0.53), 0.04, PNK, (1, 1, 1.4), 6, 4)]


def dt_keyboard():
    parts = [bbx((0, 0, 0.06), (1.5, 0.55, 0.12), RUB, 0.03)]
    for row, y in enumerate((0.14, 0.0, -0.14)):
        for k in range(4):
            if row == 1 and k == 2:
                continue  # the missing key
            parts.append(bx((-0.48 + 0.32 * k, y, 0.14), (0.26, 0.11, 0.05), WHT))
    parts.append(bx((0.0, -0.24, 0.14), (0.7, 0.05, 0.05), WHT))
    return parts


def dt_lost_sneaker():
    return [bbx((0, 0, 0.06), (1.0, 0.42, 0.12), WHT, 0.04),
            usp((-0.12, 0, 0.3), 0.36, RED, (1.05, 0.58, 0.62), 10, 6),
            usp((0.28, 0, 0.18), 0.2, RED, (1.3, 0.95, 0.6), 8, 4),
            bx((-0.47, 0, 0.42), (0.06, 0.14, 0.16), WHT),
            bx((0.05, 0, 0.45), (0.05, 0.3, 0.03), WHT), bx((0.16, 0, 0.38), (0.05, 0.3, 0.03), WHT)]


def dt_pizza_slice():
    parts = [pg((0, 0, 0.05), [(-0.45, -0.55), (0.45, -0.55), (0, 0.6)], 0.1, SAND, "z"),
             lmb((-0.47, -0.58, 0.09), (0.47, -0.58, 0.09), 0.09, 0.09, WOOD, 8),
             pg((0, 0, 0.105), [(-0.4, -0.5), (0.4, -0.5), (0, 0.52)], 0.01, YEL, "z"),
             usp((0.0, 0.6, 0.04), 0.05, YEL, (1, 1, 1.6), 6, 4)]
    parts += [rcy((x, y, 0.115), 0.09, 0.02, RED, 8) for x, y in ((-0.18, -0.3), (0.16, -0.25), (0.0, 0.08))]
    return parts


def dt_rubber_duck_sunglasses():
    parts = [usp((0, 0, 0.32), 0.4, YEL, (1.25, 0.95, 0.8), 12, 5), usp((0.28, 0, 0.78), 0.24, YEL, (1, 1, 1), 10, 5),
             usp((0.52, 0, 0.74), 0.1, ORG, (1.3, 1.1, 0.5), 8, 4), usp((-0.5, 0, 0.48), 0.12, YEL, (1, 0.8, 1), 6, 4)]
    parts += [rcy((0.46, sy * 0.11, 0.85), 0.08, 0.03, MDK, 8, axis="x") for sy in (-1, 1)]
    parts.append(bx((0.47, 0, 0.86), (0.02, 0.08, 0.02), MDK))
    return parts


def dt_smartphone():
    return [smo(pg((0, 0, 0.05), octa(0.5, 1.0, 0.2), 0.1, RUB, "z")), bx((0, 0, 0.101), (0.42, 0.88, 0.004), GLS)]


def dt_soda_can():
    return [rcy((0, 0, 0.44), 0.3, 0.88, RED, 10), rcy((0, 0, 0.94), 0.3, 0.12, MET, 10, r2=0.24),
            bx((0, 0.06, 1.005), (0.12, 0.2, 0.01), MET)]


def dt_tennis_ball():
    return [usp((0, 0, 0.5), 0.5, YEL, (1, 1, 1), 8, 5)]


def dt_water_bottle():
    return [rcy((0, 0, 0.33), 0.3, 0.66, GLS, 10), rcy((0, 0, 0.33), 0.305, 0.3, BLU, 10),
            rcy((0, 0, 0.75), 0.3, 0.18, GLS, 10, r2=0.14), rcy((0, 0, 0.88), 0.13, 0.08, GLS, 8),
            rcy((0, 0, 0.96), 0.15, 0.1, BLU, 6)]


# ---------------------------------------------------------------------------------------------- 2. new kit objects
# Tier 1 (real size under about 0.47 m)
def chip_bag():
    """Crumpled chip bag (0.25 m): a flat pillow with bulged faces, crimped seals top and bottom, a round logo."""
    pts = [(-0.09, 0.012), (0.09, 0.012), (0.095, 0.06), (0.1, 0.18), (0.09, 0.236), (-0.09, 0.236), (-0.1, 0.18),
           (-0.095, 0.06)]
    return [smo(pg((0, 0, 0), pts, 0.05, ORG, "y")), usp((0, 0, 0.125), 0.1, ORG, (0.9, 0.35, 1.05), 10, 6),
            bbx((0, 0, 0.24), (0.2, 0.02, 0.02), MET, 0.004), bbx((0, 0, 0.008), (0.2, 0.02, 0.02), MET, 0.004),
            usp((0, 0.033, 0.14), 0.04, YEL, (1, 0.3, 1), 8, 4)]


def padlock():
    """Padlock (0.08 m): a bevelled body, keyhole, a bent shackle."""
    pts = [(-0.017, 0, 0.044), (-0.017, 0, 0.058)] + [(x, 0, z) for x, z in arc_pts(0, 0.058, 0.017, math.pi, 0, 4)][1:-1] \
        + [(0.017, 0, 0.058), (0.017, 0, 0.044)]
    return [bbx((0, 0, 0.022), (0.05, 0.022, 0.044), MET, 0.004), bx((0, 0.0115, 0.018), (0.006, 0.002, 0.014), MDK)] \
        + tube(pts, 0.007, MET, 6, joints=False)


def newspaper_bundle():
    """Bundle of newspapers (0.42 m) tied with twine, the top paper askew."""
    return [bbx((0, 0, 0.045), (0.42, 0.3, 0.09), WHT, 0.01), bbx((0.01, 0.005, 0.135), (0.41, 0.29, 0.09), WHT, 0.01, 0.05),
            bx((-0.05, 0.0, 0.1805), (0.25, 0.08, 0.003), MDK),
            bx((0, 0, 0.092), (0.43, 0.012, 0.188), WOOD), bx((0.08, 0, 0.092), (0.012, 0.31, 0.188), WOOD)]


def soccer_ball():
    """Soccer ball (0.22 m): smooth white ball, five dark patches."""
    r = 0.11
    parts = [usp((0, 0, r), r, WHT, (1, 1, 1), 12, 7), rcy((0, 0, 2 * r - 0.004), 0.033, 0.012, MDK, 5)]
    parts += [rcy((0, s * (r - 0.004), r), 0.033, 0.012, MDK, 5, axis="y") for s in (-1, 1)]
    parts += [rcy((s * (r - 0.004), 0, r), 0.033, 0.012, MDK, 5, axis="x") for s in (-1, 1)]
    return parts


def flying_disc():
    """Flying disc (0.27 m) lying on the ground: domed top, rolled rim, a ring decal."""
    return [rcy((0, 0, 0.016), 0.125, 0.024, TEAL, 16, r2=0.118), trs((0, 0, 0.012), 0.128, 0.01, TEAL, 16, 4),
            rcy((0, 0, 0.0285), 0.06, 0.002, WHT, 12)]


def sand_pail():
    """Sand pail and shovel (0.3 m): tapered bucket with a rim, sand inside, wire handle; a shovel leaning on it."""
    handle = [(x, 0, z) for x, z in arc_pts(0, 0.15, 0.093, 0, math.pi, 4)]
    return [rcy((0, 0, 0.08), 0.075, 0.16, BLU, 12, r2=0.095), trs((0, 0, 0.16), 0.095, 0.008, BLU, 12, 3),
            rcy((0, 0, 0.15), 0.088, 0.01, SAND, 12)] + tube(handle, 0.004, MET, 5, joints=False) + [
            lmb((0.11, 0.06, 0.06), (0.15, 0.06, 0.29), 0.008, 0.008, YEL, 6),
            bbx((0.105, 0.06, 0.035), (0.06, 0.012, 0.07), YEL, 0.004),
            lmb((0.13, 0.06, 0.29), (0.17, 0.06, 0.29), 0.01, 0.01, YEL, 6)]


def garden_gnome():
    """Garden gnome (0.36 m): plinth, blue coat with a belt, white beard, round nose, tall red hat."""
    return [rcy((0, 0, 0.015), 0.08, 0.03, CONC, 10), rcy((0, 0, 0.1), 0.075, 0.14, BLU, 12, r2=0.055),
            rcy((0, 0, 0.12), 0.07, 0.02, MDK, 12), usp((0, 0.03, 0.18), 0.05, WHT, (1, 0.7, 1.2), 8, 5),
            usp((0, 0, 0.22), 0.045, SAND, (1, 1, 1), 8, 5), usp((0, 0.045, 0.215), 0.016, SAND, (1, 1, 1), 6, 4),
            rcy((0, 0, 0.3), 0.052, 0.14, RED, 12, r2=0.004),
            lmb((-0.06, 0.0, 0.16), (-0.04, 0.05, 0.11), 0.016, 0.014, BLU, 6),
            lmb((0.06, 0.0, 0.16), (0.04, 0.05, 0.11), 0.016, 0.014, BLU, 6)]


def watering_can():
    """Plastic watering can (0.4 m long): round body, filler cap, long spout with a rose, carry handle."""
    handle = [(0.03, 0, 0.22), (0.0, 0, 0.3), (-0.08, 0, 0.3), (-0.1, 0, 0.2)]
    return [rcy((0, 0, 0.11), 0.09, 0.22, TEAL, 12), rcy((0, 0, 0.225), 0.07, 0.015, TEAL, 12),
            lmb((0.07, 0, 0.06), (0.26, 0, 0.24), 0.018, 0.012, TEAL, 6),
            usp((0.265, 0, 0.245), 0.025, MET, (1, 1, 0.6), 8, 4)] + tube(handle, 0.012, TEAL, 6, joints=False)


def flower_pot():
    """Terracotta flower pot (0.38 m with flowers): tapered pot, rim, soil, three flowers and a leaf."""
    parts = [rcy((0, 0, 0.08), 0.075, 0.16, ROOFB, 12, r2=0.098), rcy((0, 0, 0.17), 0.106, 0.03, ROOFB, 12),
             rcy((0, 0, 0.181), 0.095, 0.01, SOIL, 12), usp((0.02, -0.03, 0.22), 0.05, LEAF, (1.2, 0.8, 0.5), 8, 4)]
    for (x, y, z), s in (((-0.04, 0.02, 0.36), RED), ((0.05, 0.03, 0.32), YEL), ((0.0, -0.05, 0.3), PNK)):
        parts += [lmb((x * 0.4, y * 0.4, 0.18), (x, y, z), 0.006, 0.006, LEAF, 5), usp((x, y, z), 0.03, s, (1, 1, 0.6), 6, 4)]
    return parts


def recycling_box():
    """Kerbside recycling box (0.45 m): open plastic crate with bottles, a can, a newspaper and card."""
    return [bx((0, 0, 0.01), (0.45, 0.32, 0.02), BLU), bx((0, -0.155, 0.14), (0.45, 0.01, 0.26), BLU),
            bx((0, 0.155, 0.14), (0.45, 0.01, 0.26), BLU), bx((-0.22, 0, 0.14), (0.01, 0.3, 0.26), BLU),
            bx((0.22, 0, 0.14), (0.01, 0.3, 0.26), BLU), rcy((-0.12, 0.05, 0.14), 0.035, 0.24, GLS, 8),
            rcy((-0.12, 0.05, 0.29), 0.015, 0.06, GLS, 8), rcy((0.1, -0.06, 0.22), 0.033, 0.12, MET, 10),
            bbx((0.02, 0.06, 0.25), (0.28, 0.2, 0.03), WHT, 0.005, 0.3), bx((0.13, 0.08, 0.3), (0.12, 0.01, 0.16), WOOD, 0.2)]


def grocery_bag():
    """Paper grocery bag (0.52 m with the baguette): folded top, baguette, celery, an apple, a carton."""
    return [bbx((0, 0, 0.17), (0.3, 0.18, 0.34), WOOD, 0.008), bx((0, 0, 0.335), (0.305, 0.185, 0.03), TRIM),
            lmb((-0.08, 0.03, 0.2), (-0.13, 0.0, 0.52), 0.03, 0.025, SAND, 8),
            lmb((0.04, 0.04, 0.25), (0.06, 0.06, 0.45), 0.012, 0.012, LEAF, 5),
            usp((0.06, 0.06, 0.47), 0.04, LEAF, (1, 1, 0.8), 8, 4), usp((0.08, -0.04, 0.36), 0.04, RED, (1, 1, 0.9), 8, 5),
            bbx((0.0, -0.03, 0.37), (0.07, 0.07, 0.14), WHT, 0.006)]


def cupcake():
    """Cupcake (0.1 m): ribbed paper case, frosting swirl, a cherry."""
    return [rcy((0, 0, 0.02), 0.028, 0.04, WHT, 12, r2=0.035), usp((0, 0, 0.052), 0.036, PNK, (1, 1, 0.7), 12, 6),
            usp((0, 0, 0.075), 0.02, PNK, (1, 1, 1), 8, 5), usp((0, 0, 0.095), 0.01, RED, (1, 1, 1), 6, 4)]


def sunglasses():
    """Sunglasses (0.15 m) standing on folded arms: round frames, dark lenses."""
    parts = []
    for sx in (-1, 1):
        parts += [trs((sx * 0.035, 0, 0.032), 0.028, 0.004, RED, 12, 3, True),
                  rcy((sx * 0.035, 0, 0.032), 0.027, 0.004, MDK, 12, axis="y")]
    parts += [lmb((-0.009, 0, 0.042), (0.009, 0, 0.042), 0.003, 0.003, RED, 5),
              bx((0, 0.03, 0.005), (0.13, 0.006, 0.006), RED), bx((0, 0.04, 0.012), (0.13, 0.006, 0.006), RED)]
    return parts


# Tier 2, low half (real size 0.5-0.95 m)
def traffic_cone():
    """Traffic cone (0.7 m): rubber base, orange cone, two white reflective bands, snow on the tip."""
    return [bbx((0, 0, 0.015), (0.38, 0.38, 0.03), RUB, 0.01), rcy((0, 0, 0.36), 0.15, 0.66, ORG, 14, r2=0.03),
            rcy((0, 0, 0.42), 0.0874, 0.08, WHT, 14, r2=0.0728), rcy((0, 0, 0.25), 0.1165, 0.06, WHT, 14, r2=0.1055),
            usp((0, 0, 0.69), 0.035, SNOW, (1, 1, 0.5), 8, 3)]


def kick_scooter():
    """Kick scooter (0.8 m): deck with grip tape, two wheels, fork, stem, handlebar with grips, rear brake."""
    parts = [bbx((0, 0, 0.07), (0.5, 0.12, 0.03), TEAL, 0.008), bx((-0.02, 0, 0.086), (0.4, 0.1, 0.003), RUB),
             lmb((0.3, 0, 0.06), (0.28, 0, 0.25), 0.012, 0.012, MET, 6), lmb((0.28, 0, 0.1), (0.24, 0, 0.78), 0.016, 0.016, TEAL, 8),
             lmb((0.24, -0.17, 0.78), (0.24, 0.17, 0.78), 0.012, 0.012, MET, 6),
             lmb((0.22, 0, 0.07), (0.28, 0, 0.12), 0.02, 0.02, TEAL, 6), bbx((-0.29, 0, 0.13), (0.1, 0.06, 0.01), TEAL, 0.004)]
    for x in (-0.3, 0.3):
        parts += [rcy((x, 0, 0.06), 0.06, 0.03, RUB, 12, axis="y"), rcy((x, 0, 0.06), 0.03, 0.035, MET, 8, axis="y")]
    parts += [rcy((0.24, s * 0.15, 0.78), 0.018, 0.07, RUB, 8, axis="y") for s in (-1, 1)]
    return parts


def cardboard_boxes():
    """Three cardboard boxes stacked askew (0.64 m), taped, with a shipping label."""
    return [bbx((0, 0, 0.15), (0.5, 0.4, 0.3), WOOD, 0.008), bbx((0.03, 0.02, 0.4), (0.4, 0.32, 0.2), WOOD, 0.008, 0.25),
            bbx((-0.04, -0.02, 0.57), (0.26, 0.22, 0.14), WOOD, 0.006, -0.2),
            bx((0, 0, 0.3015), (0.5, 0.06, 0.003), TRIM), bx((0.03, 0.02, 0.5015), (0.4, 0.05, 0.003), TRIM, 0.25),
            bx((-0.04, -0.02, 0.6415), (0.26, 0.04, 0.003), TRIM, -0.2), bx((0.1, -0.2015, 0.15), (0.12, 0.003, 0.08), WHT)]


def bistro_chair():
    """Bistro chair (0.85 m): round wooden seat, splayed metal legs with a ring, slatted back (front is +y)."""
    parts = [rcy((0, 0, 0.45), 0.2, 0.03, WOOD, 16), trs((0, 0, 0.18), 0.155, 0.008, MDK, 12, 3)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(lmb((sx * 0.13, sy * 0.13, 0.44), (sx * 0.17, sy * 0.17, 0.0), 0.012, 0.012, MDK, 6))
        parts.append(lmb((sx * 0.15, -0.15, 0.45), (sx * 0.16, -0.19, 0.85), 0.01, 0.01, MDK, 6))
    parts += [bbx((0, -0.175 - 0.01 * k, 0.6 + 0.1 * k), (0.3, 0.015, 0.05), WOOD, 0.004) for k in range(3)]
    return parts


def flower_buckets():
    """Florist's stand (0.8 m): a low slatted bench with three metal buckets of flowers."""
    parts = [bbx((0, 0, 0.2), (0.8, 0.35, 0.03), WOOD, 0.006)]
    parts += [bx((sx * 0.36, sy * 0.14, 0.095), (0.03, 0.03, 0.19), MDK) for sx in (-1, 1) for sy in (-1, 1)]
    for x, s in ((-0.25, RED), (0.0, YEL), (0.25, PNK)):
        parts += [rcy((x, 0, 0.315), 0.07, 0.2, MET, 12, r2=0.085), usp((x, 0.01, 0.5), 0.09, LEAF, (1, 1, 1.1), 8, 4),
                  usp((x, -0.01, 0.6), 0.08, s, (1, 1, 0.7), 8, 4)]
    return parts


def potted_shrub():
    """Concrete planter (0.95 m with the shrub): bevelled box, coping, soil, a smooth clipped shrub with snow."""
    return [bbx((0, 0, 0.2), (0.45, 0.45, 0.4), CONC, 0.015), bbx((0, 0, 0.41), (0.49, 0.49, 0.04), TRIM, 0.008),
            bx((0, 0, 0.432), (0.42, 0.42, 0.01), SOIL)] + lobe_cluster((0, 0, 0.68), 0.22, 3, LEAF, LDK, seed=1,
                                                                         squash=0.9, seg=8, rings=5)


def leaf_pile():
    """Pile of raked leaves (0.8 m): three smooth mounds in two greens and orange, loose leaves, snow dusting."""
    parts = [usp((0, 0, 0.06), 0.32, LEAF, (1, 0.8, 0.35), 12, 6), usp((0.15, 0.08, 0.12), 0.18, LDK, (1, 1, 0.6), 10, 5),
             usp((-0.12, -0.05, 0.14), 0.17, ORG, (1, 1, 0.6), 10, 5), usp((0, 0, 0.2), 0.15, SNOW, (1, 1, 0.3), 10, 3)]
    for k, (x, y) in enumerate(((0.38, -0.1), (-0.36, 0.14), (0.2, 0.3), (-0.1, -0.33), (0.33, 0.2))):
        parts.append(bx((x, y, 0.003), (0.07, 0.045, 0.004), (LEAF, ORG, YEL)[k % 3], k * 0.9))
    return parts


def bird_bath():
    """Stone bird bath (0.8 m): plinth, baluster pedestal, shallow bowl with a rolled lip and water."""
    return [rcy((0, 0, 0.04), 0.17, 0.08, CONC, 12), rcy((0, 0, 0.38), 0.08, 0.6, CONC, 12, r2=0.05),
            usp((0, 0, 0.5), 0.08, CONC, (1, 1, 0.6), 12, 5), rcy((0, 0, 0.72), 0.12, 0.12, CONC, 14, r2=0.24),
            trs((0, 0, 0.79), 0.24, 0.02, CONC, 14, 4), rcy((0, 0, 0.775), 0.235, 0.01, WATER, 14)]


def cooler():
    """Picnic cooler (0.62 m): white body, blue lid, a fold-over handle, latches and a drain plug."""
    handle = [(-0.2, 0, 0.4), (-0.2, 0, 0.46), (0.2, 0, 0.46), (0.2, 0, 0.4)]
    return [bbx((0, 0, 0.17), (0.6, 0.38, 0.34), WHT, 0.02), bbx((0, 0, 0.37), (0.62, 0.4, 0.06), BLU, 0.02),
            bx((-0.15, 0.195, 0.32), (0.06, 0.02, 0.06), BLU), bx((0.15, 0.195, 0.32), (0.06, 0.02, 0.06), BLU),
            rcy((0.25, 0.195, 0.04), 0.015, 0.02, MDK, 8, axis="y")] + tube(handle, 0.012, MDK, 6, joints=False)


def kids_bike():
    """Kid's bike (0.9 m): two tyres, red frame, saddle, handlebar with grips, training wheels."""
    frame = [((-0.3, 0, 0.16), (-0.1, 0, 0.42)), ((-0.1, 0, 0.42), (0, 0, 0.18)), ((0, 0, 0.18), (-0.3, 0, 0.16)),
             ((0.22, 0, 0.44), (0.25, 0, 0.3)), ((-0.1, 0, 0.4), (0.22, 0, 0.42)), ((0, 0, 0.18), (0.24, 0, 0.33)),
             ((0.25, 0, 0.3), (0.3, 0, 0.16))]
    parts = [trs((x, 0, 0.16), 0.16, 0.025, RUB, 12, 3, True) for x in (-0.3, 0.3)]
    parts += [lmb(a, b, 0.014, 0.014, RED, 6) for a, b in frame]
    parts += [bbx((-0.11, 0, 0.45), (0.14, 0.07, 0.03), RUB, 0.008), lmb((0.22, 0, 0.44), (0.21, 0, 0.5), 0.012, 0.012, MET, 6),
              lmb((0.21, -0.16, 0.5), (0.21, 0.16, 0.5), 0.01, 0.01, MET, 6), bx((0, 0, 0.18), (0.04, 0.16, 0.03), MDK)]
    parts += [rcy((0.21, s * 0.15, 0.5), 0.016, 0.05, RUB, 6, axis="y") for s in (-1, 1)]
    for s in (-1, 1):
        parts += [trs((-0.3, s * 0.16, 0.06), 0.06, 0.015, RUB, 8, 3, True),
                  lmb((-0.3, s * 0.02, 0.16), (-0.3, s * 0.16, 0.06), 0.008, 0.008, MET, 6)]
    return parts


def toolbox():
    """Toolbox (0.5 m): red body, sloped lid, a carry handle, two latches."""
    handle = [(-0.12, 0, 0.24), (-0.12, 0, 0.3), (0.12, 0, 0.3), (0.12, 0, 0.24)]
    return [bbx((0, 0, 0.09), (0.5, 0.22, 0.18), RED, 0.01),
            pg((0, 0, 0.18), [(-0.11, 0), (0.11, 0), (0.08, 0.06), (-0.08, 0.06)], 0.5, RED, "y", math.pi / 2),
            bx((-0.15, 0.112, 0.17), (0.04, 0.01, 0.05), MET), bx((0.15, 0.112, 0.17), (0.04, 0.01, 0.05), MET),
            bx((0, 0.111, 0.18), (0.5, 0.008, 0.01), MDK)] + tube(handle, 0.012, MDK, 6, joints=False)


def rain_barrel():
    """Wooden rain barrel (0.92 m): bellied staves, three iron hoops, a lid, a tap; snow on the lid."""
    parts = [rcy((0, 0, 0.225), 0.27, 0.45, WOOD, 16, r2=0.3), rcy((0, 0, 0.675), 0.3, 0.45, WOOD, 16, r2=0.27),
             rcy((0, 0, 0.905), 0.26, 0.02, MDK, 16), rcy((0, 0.29, 0.12), 0.02, 0.06, MET, 8, axis="y"),
             usp((0, 0, 0.915), 0.22, SNOW, (1, 1, 0.12), 12, 3)]
    parts += [rcy((0, 0, z), r + 0.006, 0.03, MDK, 16) for z, r in ((0.12, 0.284), (0.45, 0.3), (0.8, 0.284))]
    return parts


STAGE_C_POCKET = {
    "dt_bottle_cap": dt_bottle_cap, "dt_basketball": dt_basketball, "dt_bauble": dt_bauble,
    "dt_coffee_cup": dt_coffee_cup, "dt_donut": dt_donut, "dt_earbud_case": dt_earbud_case,
    "dt_fairy_light_bulb": dt_fairy_light_bulb, "dt_game_controller": dt_game_controller,
    "dt_gingerbread_cookie": dt_gingerbread_cookie, "dt_headphones": dt_headphones, "dt_ice_lolly": dt_ice_lolly,
    "dt_keyboard": dt_keyboard, "dt_lost_sneaker": dt_lost_sneaker, "dt_pizza_slice": dt_pizza_slice,
    "dt_rubber_duck_sunglasses": dt_rubber_duck_sunglasses, "dt_smartphone": dt_smartphone,
    "dt_soda_can": dt_soda_can, "dt_tennis_ball": dt_tennis_ball, "dt_water_bottle": dt_water_bottle,
}
STAGE_C_NEW = {
    "ck_chip_bag": chip_bag, "ck_padlock": padlock, "ck_newspaper_bundle": newspaper_bundle,
    "ck_soccer_ball": soccer_ball, "ck_flying_disc": flying_disc, "ck_sand_pail": sand_pail,
    "ck_garden_gnome": garden_gnome, "ck_watering_can": watering_can, "ck_flower_pot": flower_pot,
    "ck_recycling_box": recycling_box, "ck_grocery_bag": grocery_bag, "ck_cupcake": cupcake,
    "ck_sunglasses": sunglasses, "ck_traffic_cone": traffic_cone, "ck_kick_scooter": kick_scooter,
    "ck_cardboard_boxes": cardboard_boxes, "ck_bistro_chair": bistro_chair, "ck_flower_buckets": flower_buckets,
    "ck_potted_shrub": potted_shrub, "ck_leaf_pile": leaf_pile, "ck_bird_bath": bird_bath, "ck_cooler": cooler,
    "ck_kids_bike": kids_bike, "ck_toolbox": toolbox, "ck_rain_barrel": rain_barrel,
}
RECIPES.update(STAGE_C_POCKET)
RECIPES.update(STAGE_C_NEW)
STAGE_B_PROPS.update(STAGE_C_POCKET)
STAGE_B_PROPS.update(STAGE_C_NEW)
UNIT.update({k: 3.2 for k in STAGE_C_NEW})
