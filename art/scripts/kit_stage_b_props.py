# Stage B props of the tween-appeal rework (013 Phase 9 T076, T077; owner go on the pilot 2026-11-07). Loaded by
# art/scripts/kit_rework.py (load_stage_b) into its namespace after kit_stage_b_buildings.py, so the constructors (bbx,
# rcy, usp, lmb, bx, pg, raw, smo, trs), the helpers and the swatch names come from there.
#
# Same rules as the approved pilot props (bin, hydrant, lamp, oak, sedan): authored at real size (1 m = 3.2 studs, research
# R-18; kit_sizes.py clamps a prop into its tier band and keeps its aspect), smooth round parts with 12 or more segments
# where wider than a stud, muted street furniture with accents only where real objects have them, snow as geometry on
# the surfaces that hold it, triangles spent on silhouette. Vehicles follow the approved sedan's side-profile build
# (owner rejected a lofted body on 2026-11-07). Billboards use only fronts cells (one atlas per mesh).

import math

M = 3.2  # studs per metre
LINE, WATER, SAND, PNK, GLOW = "w-road-line", "w-water", "w-sand", "w-accent-pink", "w-glow"


# ---------------------------------------------------------------------------------------------- shared prop helpers
def tube(points, r, s, n=8, joints=True):
    """A bent tube through points (rails, handles, frames): limbs, with a ball at each inner joint."""
    parts = [lmb(a, b, r, r, s, n) for a, b in zip(points, points[1:])]
    if joints:
        parts += [usp(p, r * 1.02, s, (1, 1, 1), n, max(4, n // 2)) for p in points[1:-1]]
    return parts


def arc_pts(cx, cy2, r, a0, a1, n):
    return [(cx + r * math.cos(a0 + (a1 - a0) * k / n), cy2 + r * math.sin(a0 + (a1 - a0) * k / n)) for k in range(n + 1)]


def lobe_cluster(c, r, n, s1, s2, seed=0, squash=0.8, seg=12, rings=7, snow=True):
    """Smooth canopy or bush: one core lobe and n lobes around it, two greens; a squashed snow cap on the top lobe."""
    x, y, z = c
    parts = [usp((x, y, z), r, s1, (1.05, 1.0, squash), seg, rings)]
    for k in range(n):
        a = 2 * math.pi * (k + 0.3 * seed) / n
        rr = r * (0.62 + 0.12 * ((k * 5 + seed) % 3))
        dz = r * (0.15 * ((k * 3 + seed) % 3) - 0.2)
        parts.append(usp((x + math.cos(a) * r * 0.75, y + math.sin(a) * r * 0.75, z + dz), rr, s2 if k % 2 else s1,
                         (1.0, 1.0, squash), seg, rings))
    if snow:
        parts.append(usp((x, y, z + r * squash * 0.72), r * 0.62, SNOW, (1.0, 1.0, 0.32), seg, 4))
    return parts


def kerb_run(x0, y0, x1, y1, n, h, w, s=KERB, z0=0.0):
    """n kerb stones from (x0, y0) to (x1, y1), each bevelled, with a hairline gap."""
    out = []
    dx, dy = (x1 - x0) / n, (y1 - y0) / n
    length = math.hypot(dx, dy) - 0.08
    yaw = math.atan2(dy, dx)
    for k in range(n):
        out.append(bbx((x0 + dx * (k + 0.5), y0 + dy * (k + 0.5), z0 + h / 2), (length, w, h), s, 0.06, yaw))
    return out


def wheel(x, y, z, r, w, side, tyre=RUB, rim=MET, hub=MDK, spokes=5, seg=20):
    """Car wheel seen from side `side` (+1 / -1 along y): smooth tyre, dished rim, hub, spokes."""
    yw = y + side * (w / 2 - 0.02)
    parts = [rcy((x, y, z), r, w, tyre, seg, axis="y"),
             rcy((x, yw, z), r * 0.66, 0.06, hub, 16, axis="y"),
             rcy((x, yw + side * 0.02, z), r * 0.64, 0.05, rim, 16, r2=r * 0.58, axis="y"),
             rcy((x, yw + side * 0.05, z), r * 0.18, 0.1, rim, 10, axis="y")]
    for k in range(spokes):
        a = 2 * math.pi * k / spokes
        parts.append(bx((x + math.cos(a) * r * 0.36, yw + side * 0.04, z + math.sin(a) * r * 0.36),
                        (r * 0.46, 0.06, r * 0.12) if abs(math.sin(a)) < 0.6 else (r * 0.12, 0.06, r * 0.46), rim))
    return parts


# ---------------------------------------------------------------------------------------------- street kit
def road_marking_dash():
    """A 3 m centre-line dash on a patch of worn asphalt, with two road studs; slush shows in winter (w-road-slush)."""
    parts = [bbx((0, 0, 0.06), (11.2, 2.6, 0.12), SLUSH, 0.04),
             bbx((0, 0, 0.15), (9.6, 0.5, 0.06), LINE, 0.02)]
    for x in (-5.1, 5.1):
        parts += [rcy((x, 0, 0.17), 0.32, 0.1, MDK, 12), rcy((x, 0.0, 0.25), 0.2, 0.08, WHT, 12, r2=0.12)]
    return parts


def road_marking_arrow():
    """A 5 m lane arrow (shaft and head) on a patch of asphalt, worn paint at the tail."""
    head = [(0.0, -2.4), (4.6, 0.0), (0.0, 2.4), (0.0, 1.0), (0.0, -1.0)]
    parts = [bbx((0, 0, 0.06), (17.6, 6.0, 0.12), SLUSH, 0.04),
             bbx((-3.2, 0, 0.15), (10.6, 1.0, 0.06), LINE, 0.02),
             pg((2.0, 0, 0.15), head, 0.06, LINE, "z"),
             bx((-8.0, 0, 0.14), (0.6, 0.9, 0.04), WORN)]
    return parts


def crossing_zebra():
    """Zebra crossing over one lane: seven 0.5 m stripes with 0.5 m gaps, a give-way line each side, kerb ends."""
    parts = [bbx((0, 0, 0.06), (11.6, 9.6, 0.12), SLUSH, 0.04)]
    for k in range(4):
        parts += [bbx((-4.8 + k * 3.2, 0, 0.15), (1.6, 8.0, 0.06), LINE, 0.02),
                  bx((-4.8 + k * 3.2 + 0.4, 2.6 - k * 1.1, 0.19), (0.5, 0.9, 0.02), WORN)]
    for sy in (-1, 1):
        parts += [bx((0, sy * 4.4, 0.14), (10.8, 0.3, 0.04), LINE)]
    for sx in (-1, 1):
        parts += kerb_run(sx * 5.6, -4.8, sx * 5.6, 4.8, 4, 0.42, 0.6)
    return parts


def kerb_corner():
    """Pavement corner: a quarter-round sidewalk on kerb stones, a dropped kerb with a tactile pad, a gully grate."""
    S, R = 9.0, 5.0
    outline = [(-S, -S), (S, -S), (S, S - R)] + arc_pts(S - R, S - R, R, 0.0, math.pi / 2, 8)[1:] + [(-S, S)]
    parts = [pg((0, 0, 0.2), outline, 0.4, WALK, "z"), bx((0, 0, 0.02), (2 * S + 3.4, 2 * S + 3.4, 0.04), SLUSH)]
    for k in range(4):  # paving joints
        parts.append(bx((-S + 3.6 * (k + 1), -1.0, 0.41), (0.08, 2 * S - 2.2, 0.02), KERB))
    parts += kerb_run(S + 0.3, -S, S + 0.3, S - R, 5, 0.42, 0.6)
    pts = arc_pts(S - R, S - R, R + 0.3, 0.0, math.pi / 2, 6)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        parts += kerb_run(x0, y0, x1, y1, 1, 0.42, 0.6)
    parts += kerb_run(S - R, S + 0.3, -S, S + 0.3, 5, 0.42, 0.6)
    a = math.pi / 4  # tactile pad on the dropped kerb at the corner's middle
    px, py = S - R + math.cos(a) * (R - 1.4), S - R + math.sin(a) * (R - 1.4)
    parts.append(bx((px, py, 0.42), (2.2, 2.2, 0.06), RED, -a))
    for i in range(3):
        for j in range(3):
            u, v = (i - 1) * 0.6, (j - 1) * 0.6
            parts.append(rcy((px + u * math.cos(-a) - v * math.sin(-a), py + u * math.sin(-a) + v * math.cos(-a), 0.48),
                             0.16, 0.06, RED, 8))
    parts.append(bx((S + 1.2, -S + 3.0, 0.03), (1.4, 2.4, 0.04), MDK))  # gully grate in the gutter
    for k in range(5):
        parts.append(bx((S + 1.2, -S + 2.0 + k * 0.5, 0.07), (1.2, 0.12, 0.05), MET))
    return parts


def street_sign():
    """Street-name post (2.6 m): slim galvanised pole on a collar, two blank name plates crossed at the top with borders
    and a finial, a round give-way-style plate lower down; snow on the plate tops."""
    H = 8.4
    parts = [rcy((0, 0, H / 2), 0.14, H, MET, 10), rcy((0, 0, 0.15), 0.28, 0.3, MDK, 12),
             usp((0, 0, H + 0.12), 0.2, MDK, (1, 1, 1), 10, 6)]
    for k, yaw in enumerate((0.0, math.pi / 2)):
        z = H - 0.55 - k * 1.05
        parts += [bbx((0, 0, z), (2.8, 0.1, 0.85), BLU, 0.04, yaw), bx((0, 0, z + 0.46), (2.7, 0.14, 0.06), SNOW, yaw)]
        for side in (-1, 1):
            ox, oy = (0.0, side) if k == 0 else (side, 0.0)
            parts += [bx((ox * 0.06, oy * 0.06, z), (2.5, 0.02, 0.6), WHT, yaw),
                      bx((ox * 0.075, oy * 0.075, z), (2.3, 0.02, 0.44), BLU, yaw)]
    parts += [rcy((0, 0.16, 5.2), 0.7, 0.08, RED, 16, axis="y"), rcy((0, 0.2, 5.2), 0.52, 0.04, WHT, 16, axis="y"),
              rcy((0, 0, 5.92), 0.14, 0.04, SNOW, 8)]
    for z in (4.9, 5.5):
        parts.append(rcy((0, 0, z), 0.18, 0.1, MDK, 10))
    return parts


def planter_box():
    """Timber-clad street planter (1.2 x 0.5 m, 0.5 m tall) on dark feet, three clipped shrubs, snow on the shrubs."""
    L, D, H = 3.9, 1.7, 1.6
    parts = [bbx((0, 0, H / 2 + 0.1), (L, D, H), WOOD, 0.06), bx((0, 0, H + 0.12), (L - 0.3, D - 0.3, 0.06), SOIL),
             bbx((0, 0, H + 0.14), (L + 0.12, D + 0.12, 0.16), CONC, 0.04)]
    for k in range(4):  # cladding slat joints, both long faces
        z = 0.35 + k * 0.4
        for sy in (-1, 1):
            parts.append(bx((0, sy * (D / 2 + 0.02), z), (L - 0.1, 0.04, 0.05), BARK))
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(bx((sx * (L / 2 - 0.3), sy * (D / 2 - 0.3), 0.05), (0.4, 0.4, 0.1), MDK))
    for k, x in enumerate((-1.2, 0.0, 1.2)):
        r = 0.72 if k == 1 else 0.6
        parts += [usp((x, 0, H + 0.2 + r * 0.7), r, LEAF if k != 1 else LDK, (1.05, 1.0, 0.9), 10, 6),
                  usp((x, 0, H + 0.2 + r * 1.3), r * 0.6, SNOW, (1.0, 1.0, 0.35), 8, 3)]
    return parts


def bollard():
    """Cast street bollard (1 m, 15 cm): tapered barrel, a reflective band, a dome cap, a ground collar; snow on the dome."""
    parts = [rcy((0, 0, 1.45), 0.26, 2.7, MDK, 12, r2=0.23), rcy((0, 0, 0.08), 0.36, 0.16, MDK, 12),
             rcy((0, 0, 2.4), 0.25, 0.22, WHT, 12), usp((0, 0, 2.8), 0.25, MDK, (1, 1, 0.75), 12, 4),
             usp((0, 0, 2.94), 0.17, SNOW, (1, 1, 0.45), 8, 3)]
    return parts


def railing_section():
    """Pedestrian guard rail (2 m x 1.1 m): round posts on base plates, top and bottom rails, vertical bars, a high
    visibility gap panel; worn paint, snow on the top rail."""
    L, H = 6.4, 3.5
    parts = []
    for x in (-L / 2, L / 2):
        parts += [rcy((x, 0, H / 2), 0.16, H, WORN, 10), usp((x, 0, H), 0.2, WORN, (1, 1, 0.8), 10, 5),
                  bx((x, 0, 0.04), (0.6, 0.6, 0.08), MDK)]
    parts += [rcy((0, 0, H - 0.2), 0.12, L, WORN, 10, axis="x"), rcy((0, 0, 0.55), 0.1, L, WORN, 10, axis="x"),
              rcy((0, 0, 2.55), 0.08, L, WORN, 8, axis="x"), bx((0, 0, H - 0.04), (L, 0.16, 0.08), SNOW)]
    for k in range(10):
        x = -L / 2 + 0.58 * (k + 1)
        if 4 <= k <= 5:
            continue
        parts.append(rcy((x, 0, (0.55 + 2.55) / 2), 0.06, 2.0, WORN, 6))
    parts += [bbx((0, 0, 1.55), (1.2, 0.06, 1.9), MET, 0.03), bx((0, 0.05, 1.55), (0.9, 0.04, 0.3), WHT)]
    return parts


def bus_stop_pole():
    """Bus-stop flag pole (2.8 m): slim pole, a flag with a rounded bus pictogram plate, a timetable case, a collar;
    snow on the flag top."""
    H = 9.0
    parts = [rcy((0, 0, H / 2), 0.16, H, MET, 10), rcy((0, 0, 0.15), 0.3, 0.3, MDK, 12),
             usp((0, 0, H + 0.05), 0.18, MDK, (1, 1, 1), 10, 5),
             bbx((0.9, 0, H - 0.9), (1.9, 0.12, 1.5), YEL, 0.05), bx((0.9, 0.07, H - 0.85), (1.2, 0.04, 0.7), WHT),
             bx((0.9, 0.09, H - 0.85), (0.9, 0.04, 0.42), BLU), bx((0.9, 0, H - 0.1), (1.9, 0.16, 0.06), SNOW)]
    for x in (0.6, 1.2):
        parts.append(rcy((x, 0.11, H - 1.18), 0.11, 0.04, MDK, 10, axis="y"))
    parts += [bbx((0, 0.25, 4.6), (1.2, 0.3, 1.6), MDK, 0.05), bx((0, 0.41, 4.6), (1.0, 0.04, 1.35), GLS),
              bx((0, 0.25, 5.45), (1.3, 0.4, 0.06), SNOW), bx((0, 0.42, 4.75), (0.7, 0.03, 0.8), WHT)]
    for z in (H - 1.8, H - 0.1):
        parts.append(rcy((0, 0, z), 0.2, 0.12, MDK, 10))
    return parts


# ---------------------------------------------------------------------------------------------- park
def tree_pine():
    """Spruce (12 m): flared trunk, seven drooping tiers, each three offset smooth cones in two greens, snow on every
    tier's top, a leader at the tip."""
    parts = [rcy((0, 0, 0.6), 1.1, 1.2, BARK, 12, r2=0.75), rcy((0, 0, 4.0), 0.75, 7.0, BARK, 12, r2=0.35)]
    for k in range(4):  # root flare
        a = 2 * math.pi * (k + 0.25) / 4
        parts.append(lmb((0, 0, 1.0), (math.cos(a) * 1.5, math.sin(a) * 1.5, 0.05), 0.4, 0.15, BARK, 8))
    tiers = 7
    for t in range(tiers):
        z = 4.2 + t * 4.6
        r = 7.6 - t * 0.95
        h = 6.2 - t * 0.35
        for j in range(3):
            a = 2 * math.pi * (j + 0.4 * t) / 3
            o = r * 0.12
            parts.append(rcy((math.cos(a) * o, math.sin(a) * o, z + h / 2 + j * 0.25), r * (1.0 - 0.06 * j), h,
                             LDK if (t + j) % 2 else LEAF, 20, r2=r * 0.12))
        parts.append(rcy((0, 0, z + h * 0.72), r * 0.42, h * 0.3, SNOW, 14, r2=r * 0.08))
    parts.append(rcy((0, 0, 4.2 + tiers * 4.6 + 1.6), 0.9, 4.2, LEAF, 12, r2=0.05))
    return parts


def tree_birch():
    """Silver birch (12 m): slim leaning white trunk with dark bark bands, three limbs, an airy canopy of many small
    lobes in two greens."""
    parts = [rcy((0, 0, 0.4), 0.75, 0.8, WHT, 12, r2=0.55),
             lmb((0, 0, 0.6), (0.6, 0.2, 14.0), 0.55, 0.3, WHT, 12),
             lmb((0.6, 0.2, 14.0), (0.9, 0.3, 26.0), 0.3, 0.12, WHT, 10)]
    for k in range(9):  # bark bands (lenticels)
        z = 1.6 + k * 2.6
        x = 0.6 * z / 14.0 if z < 14 else 0.6 + 0.3 * (z - 14) / 12
        rr = 0.56 - 0.022 * k
        parts.append(rcy((x, 0.2 * min(z, 14) / 14, z), rr + 0.03, 0.22 + 0.08 * (k % 2), MDK, 8))
    limbs = [((0.4, 0.15, 10.5), (4.6, 1.2, 17.5)), ((0.5, 0.2, 12.5), (-4.0, -0.6, 19.0)),
             ((0.7, 0.25, 16.0), (1.2, -3.8, 21.0)), ((0.7, 0.25, 17.5), (-1.0, 3.6, 22.5))]
    for a, b in limbs:
        parts.append(lmb(a, b, 0.24, 0.1, WHT, 8))
    lobes = [((0.9, 0.3, 26.4), 3.4), ((4.8, 1.3, 19.6), 3.0), ((-4.2, -0.6, 20.6), 3.1), ((1.3, -3.9, 22.6), 2.8),
             ((-1.1, 3.7, 23.8), 2.9), ((3.2, 2.6, 24.4), 2.5), ((-2.8, -2.6, 24.8), 2.5), ((2.8, -1.8, 27.0), 2.3),
             ((-2.4, 1.4, 27.6), 2.4)]
    for k, (c, r) in enumerate(lobes):
        parts.append(usp(c, r, LEAF if k % 3 else LDK, (1.0, 1.0, 0.92), 10, 6))
    parts.append(usp((0.9, 0.3, 29.0), 1.6, SNOW, (1.0, 1.0, 0.35), 8, 3))
    return parts


def bush():
    """Garden shrub (1.6 m wide, 1 m tall): a smooth cluster of lobes in two greens on a soil mound; snow on top."""
    parts = [usp((0, 0, 0.1), 2.3, SOIL, (1.0, 1.0, 0.12), 12, 3)]
    parts += lobe_cluster((0, 0, 1.6), 1.55, 4, LEAF, LDK, seed=1, squash=0.85, seg=10, rings=6)
    return parts


def hedge_row():
    """Clipped hedge (2 m x 0.7 m, 1.2 m tall): a soft-edged body, a rounded clipped top, bulges along the sides, a soil
    strip; a snow blanket on the flat top only."""
    L, D, H = 6.4, 2.2, 3.8
    parts = [bbx((0, 0, H / 2 - 0.3), (L, D, H - 0.6), LDK, 0.45), bx((0, 0, 0.06), (L + 0.6, D + 0.6, 0.12), SOIL)]
    for k in range(4):
        x = -L / 2 + 0.8 + k * (L - 1.6) / 3
        parts.append(usp((x, 0, H - 0.75), 1.15, LEAF, (1.0, 0.95, 0.6), 12, 6))
        for sy in (-1, 1):
            parts.append(usp((x + 0.4 * sy, sy * (D / 2 - 0.25), H * 0.45), 0.85, LDK if k % 2 else LEAF,
                             (1.1, 0.55, 1.2), 10, 6))
    parts.append(bbx((0, 0, H - 0.18), (L - 0.4, D - 0.4, 0.22), SNOW, 0.08))
    return parts


def flower_bed():
    """Raised flower bed (1.2 x 0.7 m) with stone edging, soil, leafy mounds and round flower heads in four colours."""
    L, D = 3.9, 2.3
    parts = [bx((0, 0, 0.32), (L - 0.3, D - 0.3, 0.06), SOIL)]
    for sy in (-1, 1):
        parts += [bx((0, sy * D / 2, 0.25), (L, 0.3, 0.5), KERB), bx((sy * L / 2, 0, 0.25), (0.3, D - 0.3, 0.5), KERB)]
    for k, x in enumerate((-1.1, 0.0, 1.1)):
        parts.append(usp((x, 0.1 * (k - 1), 0.45), 0.62, LEAF if k % 2 else LDK, (1.1, 1.0, 0.7), 8, 4))
    colours = (PNK, YEL, RED, ORG)
    for k in range(8):
        x = -1.4 + (k % 4) * 0.95
        y = -0.45 if k < 4 else 0.45
        parts.append(usp((x + 0.3 * (k // 4), y, 0.95 + 0.1 * (k % 2)), 0.24, colours[k % 4], (1, 1, 0.8), 8, 4))
    return parts


def picnic_blanket():
    """Picnic blanket (1.5 x 1.2 m): a checked cloth with a folded corner, slightly lifted off the grass."""
    L, D = 4.8, 3.8
    parts = [bbx((0, 0, 0.05), (L, D, 0.1), RED, 0.03)]
    for k in range(4):
        parts.append(bx((-L / 2 + (k + 0.75) * L / 4.2, 0, 0.11), (0.42, D - 0.06, 0.02), WHT))
        parts.append(bx((0, -D / 2 + (k + 0.75) * D / 4.2, 0.12), (L - 0.06, 0.38, 0.02), WHT))
    parts.append(raw([(L / 2 - 1.3, D / 2, 0.1), (L / 2, D / 2, 0.1), (L / 2, D / 2 - 1.3, 0.1), (L / 2 - 0.45, D / 2 - 0.45, 0.28)],
                     [(0, 1, 2), (0, 3, 1), (1, 3, 2), (2, 3, 0)], WHT))
    return parts


def picnic_basket():
    """Wicker picnic basket (45 cm): woven body with bands, a twin-flap lid, a looped handle, a checked cloth peeking out,
    a bread loaf and a juice bottle."""
    L, D, H = 1.45, 0.95, 0.75
    parts = [bbx((0, 0, H / 2), (L, D, H), WOOD, 0.05), bbx((0, 0, H + 0.04), (L + 0.06, D + 0.06, 0.08), BARK, 0.02)]
    for z in (0.25, 0.5):
        parts.append(bx((0, 0, z), (L + 0.02, D + 0.02, 0.04), BARK))
    parts += [bbx((-0.36, 0.12, H + 0.1), (0.7, D * 0.75, 0.05), WOOD, 0.02, 0.0)]
    parts += tube([(-0.55, 0, H + 0.08), (-0.45, 0, H + 0.42), (0.0, 0, H + 0.56), (0.45, 0, H + 0.42), (0.55, 0, H + 0.08)],
                  0.035, BARK, 6, joints=False)
    parts += [bx((0.3, 0.48, H - 0.05), (0.5, 0.04, 0.2), RED), bx((0.3, 0.5, H - 0.05), (0.12, 0.03, 0.2), WHT),
              usp((0.28, -0.1, H + 0.12), 0.16, BARK, (2.2, 1.0, 0.9), 8, 5),
              rcy((0.5, 0.2, H + 0.12), 0.08, 0.3, TEAL, 10), rcy((0.5, 0.2, H + 0.32), 0.04, 0.1, WHT, 8)]
    return parts


def swing_set():
    """Two-seat swing (3.2 m wide, 2.2 m tall): A-frame tube legs on ground plates, a top beam, chains, a flat rubber
    seat and a cradle seat, rubber safety tiles; snow along the beam."""
    W, H, F = 10.2, 7.0, 2.6
    parts = [rcy((0, 0, H), 0.24, W + 0.6, WORN, 12, axis="x"), bx((0, 0, H + 0.26), (W, 0.3, 0.1), SNOW)]
    for sx in (-1, 1):
        x = sx * W / 2
        for sy in (-1, 1):
            parts += [lmb((x, 0, H), (x + sx * 0.3, sy * F, 0.1), 0.18, 0.18, WORN, 10),
                      bx((x + sx * 0.3, sy * F, 0.05), (0.5, 0.5, 0.1), MDK)]
        parts += [usp((x, 0, H), 0.34, MDK, (1, 1, 1), 10, 6), lmb((x, -1.4, 3.6), (x, 1.4, 3.6), 0.1, 0.1, WORN, 8)]
    for k, x in enumerate((-2.2, 2.2)):
        for sx in (-0.65, 0.65):
            parts.append(rcy((x + sx, 0, H - 2.5), 0.05, 4.9, MET, 6))
        parts.append(bx((x, 0, 0.04), (2.6, 3.4, 0.08), RUB))
        if k == 0:
            parts += [bbx((x, 0, 1.5), (1.5, 0.55, 0.16), RUB, 0.06), bx((x, 0, 1.6), (1.4, 0.45, 0.04), SNOW)]
        else:
            parts += [bbx((x, 0, 1.45), (1.2, 1.0, 0.3), RED, 0.1), bbx((x, -0.42, 1.9), (1.2, 0.16, 0.7), RED, 0.06),
                      bbx((x, 0.42, 1.9), (1.2, 0.16, 0.7), RED, 0.06)]
            for sx in (-1, 1):
                parts.append(bx((x + sx * 0.55, 0, 2.0), (0.14, 1.0, 0.1), RED))
    for sx in (-1, 1):
        for x0 in (-2.2, 2.2):
            parts.append(rcy((x0 + sx * 0.65, 0, H - 0.18), 0.12, 0.2, MDK, 8, axis="x"))
    return parts


def slide():
    """Playground slide (platform 1.5 m, chute 3.4 m): a ladder with round rails, a platform with side panels and a
    hood, a dished chute with rolled lips and a flat run-out; snow on the platform hood and the run-out."""
    P = 4.8
    parts = []
    for x in (-5.4, -3.2):  # tower legs
        for y in (-1.2, 1.2):
            parts.append(rcy((x, y, (P + 3.2) / 2), 0.16, P + 3.2, WORN, 10))
    parts += [bbx((-4.3, 0, P), (2.7, 2.7, 0.24), WOOD, 0.05), bx((-4.3, 0, P + 0.13), (2.5, 2.5, 0.04), SNOW)]
    for sy in (-1, 1):
        parts.append(bbx((-4.3, sy * 1.25, P + 1.1), (2.4, 0.12, 1.6), ORG, 0.05))
    parts += [raw([(-5.7, -1.45, P + 3.2), (-2.9, -1.45, P + 3.2), (-2.9, 1.45, P + 3.2), (-5.7, 1.45, P + 3.2),
                   (-4.3, 0.0, P + 4.4)], [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (3, 2, 1, 0)], BLU),
              raw([(-5.0, -0.6, P + 3.85), (-3.6, -0.6, P + 3.85), (-4.3, 0.0, P + 4.42)], [(0, 1, 2)], SNOW)]
    for y in (-0.75, 0.75):  # ladder down the back
        parts.append(lmb((-5.6, y, P + 0.9), (-7.4, y, 0.0), 0.12, 0.12, WORN, 8))
    for k in range(5):
        t = (k + 0.5) / 5
        parts.append(rcy((-5.6 - 1.8 * t, 0, P + 0.9 - (P + 0.9) * t), 0.08, 1.5, MET, 8, axis="y"))
    bed = [(-2.9, P - 0.05), (-2.6, P - 0.05), (3.6, 1.2), (4.4, 0.85), (6.4, 0.75), (6.4, 0.45), (4.3, 0.55),
           (3.5, 0.9), (-2.9, P - 0.4)]
    parts.append(bev(pg((0, 0, 0), bed, 1.6, YEL, "y"), 0.04))
    for sy in (-1, 1):
        lip = [(-2.9, P + 0.7), (3.6, 1.95), (4.4, 1.55), (6.4, 1.3), (6.4, 0.75), (4.4, 0.85), (3.6, 1.2), (-2.6, P - 0.05)]
        parts.append(pg((0, sy * 0.88, 0), lip, 0.16, YEL, "y"))
        parts += tube([(-2.9, sy * 0.92, P + 0.75), (3.6, sy * 0.92, 2.0), (4.4, sy * 0.92, 1.6), (6.4, sy * 0.92, 1.35)],
                      0.12, YEL, 8)
    parts += [bx((5.4, 0, 0.98), (1.8, 1.4, 0.05), SNOW), rcy((5.8, 0, 0.35), 0.16, 0.7, WORN, 8)]
    parts.append(bx((0, 0, 0.04), (13.5, 4.4, 0.08), RUB))
    return parts


def path_straight():
    """Park path (2.5 m wide, 2.5 m long): three rows of bevelled paving slabs, concrete edging both sides, a grass
    verge strip."""
    L, W = 8.0, 8.0
    parts = []
    for i in range(3):
        for j in range(3):
            parts.append(bbx((-L / 3 + i * L / 3 + (0.3 if j == 1 else 0.0), -W * 0.27 + j * W * 0.27, 0.12),
                             (L / 3 - 0.12, W * 0.27 - 0.12, 0.24), WALK, 0.05))
    for sy in (-1, 1):
        parts += kerb_run(-L / 2, sy * W * 0.43, L / 2, sy * W * 0.43, 3, 0.36, 0.45, CONC)
        parts.append(bbx((0, sy * W * 0.48, 0.08), (L, 0.5, 0.16), GRASS, 0.05))
    parts.append(bx((-L / 2 + 0.3, 0.0, 0.25), (0.4, 0.6, 0.02), STAIN))
    return parts


def path_curve():
    """Curved park path (a quarter turn, 2.5 m wide): two rings of wedge-cut paving slabs and concrete edging."""
    R0, R1 = 2.6, 10.4
    parts = []
    n = 6
    for ring, (ra, rb) in enumerate(((R0, (R0 + R1) / 2), ((R0 + R1) / 2, R1))):
        for k in range(n):
            a0 = math.pi / 2 * (k + 0.03) / n
            a1 = math.pi / 2 * (k + 0.97) / n
            pts = [(ra * math.cos(a0), ra * math.sin(a0)), (rb * math.cos(a0), rb * math.sin(a0)),
                   (rb * math.cos(a1), rb * math.sin(a1)), (ra * math.cos(a1), ra * math.sin(a1))]
            parts.append(pg((0, 0, 0.12), [(x + 0.06 * 0, y) for x, y in pts], 0.24, WALK, "z"))
    for r in (R0 - 0.3, R1 + 0.3):
        pts = arc_pts(0, 0, r, 0, math.pi / 2, 5)
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            parts += kerb_run(x0, y0, x1, y1, 1, 0.36, 0.45, CONC)
    return parts


def pond_edge():
    """Small pond (3 m): a water disc ringed by smooth rounded edging stones, lily pads, two reed clumps."""
    R = 4.6
    parts = [rcy((0, 0, 0.08), R, 0.16, WATER, 24)]
    for k in range(14):
        a = 2 * math.pi * k / 14
        r = 0.75 + 0.18 * ((k * 5) % 3)
        parts.append(usp((math.cos(a) * (R + 0.35), math.sin(a) * (R + 0.35), 0.18), r, KERB if k % 3 else CONC,
                         (1.25, 1.0, 0.5), 10, 4))
    for x, y, r in ((1.6, 1.0, 0.55), (-1.2, -1.8, 0.45), (2.4, -0.8, 0.4)):
        parts.append(rcy((x, y, 0.19), r, 0.04, LEAF, 12))
    for cx, cy2 in ((-3.0, 2.6), (3.2, 2.4)):
        for k in range(5):
            a = 2 * math.pi * k / 5
            parts.append(rcy((cx + math.cos(a) * 0.3, cy2 + math.sin(a) * 0.3, 1.0 + 0.15 * (k % 3)), 0.07,
                             1.8 + 0.3 * (k % 3), LDK, 6, r2=0.0))
        parts.append(usp((cx, cy2, 1.4), 0.15, BARK, (1, 1, 2.2), 8, 5))
    return parts


RECIPES.update({
    "ck_road_marking_dash": road_marking_dash,
    "ck_road_marking_arrow": road_marking_arrow,
    "ck_crossing_zebra": crossing_zebra,
    "ck_kerb_corner": kerb_corner,
    "ck_street_sign": street_sign,
    "ck_planter_box": planter_box,
    "ck_bollard": bollard,
    "ck_railing_section": railing_section,
    "ck_bus_stop_pole": bus_stop_pole,
    "ck_tree_pine": tree_pine,
    "ck_tree_birch": tree_birch,
    "ck_bush": bush,
    "ck_hedge_row": hedge_row,
    "ck_flower_bed": flower_bed,
    "ck_picnic_blanket": picnic_blanket,
    "ck_picnic_basket": picnic_basket,
    "ck_swing_set": swing_set,
    "ck_slide": slide,
    "ck_path_straight": path_straight,
    "ck_path_curve": path_curve,
    "ck_pond_edge": pond_edge,
})


# ---------------------------------------------------------------------------------------------- more helpers
def arch_face(c, w, h, s, depth, yaw=0.0, n=8):
    """A round-headed panel (window, opening) in the xz plane: a rectangle w x h whose top is a half circle."""
    r = w / 2
    pts = [(-r, 0.0), (r, 0.0)] + arc_pts(0.0, h - r, r, 0.0, math.pi, n)[:-1] + [(-r, h - r)]
    pts = [(x, z) for x, z in pts]
    dedup = []
    for p in pts:
        if not dedup or abs(dedup[-1][0] - p[0]) + abs(dedup[-1][1] - p[1]) > 1e-4:
            dedup.append(p)
    return pg(c, dedup, depth, s, "y", yaw)


def profile_car(body, glass, roof, pillars, wheel_xs, W, paint, snow, tyre_r=1.05, lights=None, seams=(-0.85, 2.8), arch_h=1.0,
                well=None,
                handles=(0.3, -2.6), mirror_x=2.75, skirt=8.2, bumper=True, plate=True, antenna=True, belt_z=2.82,
                handle_z=2.45, seam_z=1.9, seam_h=1.7, mirror_z=3.05, grille_z=1.6, rims=5):
    """The approved sedan's construction (art/scripts/kit_rework.py car_sedan), parameterised: a bevelled side-profile
    body, greenhouse and roof prisms, pillar prisms, a belt line, door seams and handles, mirrors, wheel wells with arch
    lips, smooth tyres with dished five-spoke rims, side skirts, lights, grille, bumpers and a blank plate."""
    xs = [x for x, _ in body]
    fx, rx = max(xs), min(xs)
    parts = [bev(pg((0, 0, 0), body, W * 0.97, paint, "y"), 0.18),
             bev(pg((0, 0, 0), glass, W * 0.84, GLS, "y"), 0.06),
             bev(pg((0, 0, 0), roof, W * 0.86, paint, "y"), 0.05),
             pg((0, 0, 0.05), snow, W * 0.62, SNOW, "y")]
    for sy in (-1, 1):
        y = sy * W * 0.42
        parts += [pg((0, y, 0), p, 0.12, paint, "y") for p in pillars]
        parts += [bx(((fx + rx) / 2 - 0.6, sy * W * 0.487, belt_z), ((fx - rx) * 0.54, 0.06, 0.1), TRIM)]
        parts += [bx((x, sy * W * 0.487, seam_z), (0.06, 0.06, seam_h), MDK) for x in seams]
        parts += [bx((x, sy * W * 0.49, handle_z), (0.6, 0.08, 0.14), MET) for x in handles]
        if mirror_x is not None:
            parts.append(bbx((mirror_x, sy * (W * 0.5 + 0.2), mirror_z), (0.6, 0.45, 0.35), paint, 0.05))
        parts.append(bbx(((fx + rx) / 2 - 0.1, sy * W * 0.485, 0.95), (skirt, 0.16, 0.3), MDK, 0.03))
    for x in wheel_xs:
        wz, wr = well or (tyre_r + 0.1, tyre_r + 0.33)
        parts.append(rcy((x, 0, wz), wr, W * 0.975, RUB, 20, axis="y"))
        for sy in (-1, 1):
            parts += wheel(x, sy * (W / 2 - 0.55), tyre_r, tyre_r, 0.95, sy, spokes=rims)
            k = tyre_r / 1.05
            lip = [(-1.55, 1.05), (-1.4, 1.75), (-0.9, 2.3), (0.0, 2.55), (0.9, 2.3), (1.4, 1.75), (1.55, 1.05), (1.75, 1.05),
                   (1.6, 1.9), (1.0, 2.55), (0.0, 2.8), (-1.0, 2.55), (-1.6, 1.9), (-1.75, 1.05)]
            parts.append(pg((x, sy * (W * 0.485), 0), [(u * k, 1.05 + (z * k - 1.05) * arch_h) for u, z in lip], 0.12, MDK, "y"))
    lz = lights or (2.0, 2.2)
    for sy in (-1, 1):
        parts += [bbx((fx - 0.05, sy * W * 0.35, lz[0]), (0.2, 1.1, 0.5), WHT, 0.04),
                  bbx((rx + 0.0, sy * W * 0.36, lz[1]), (0.2, 1.2, 0.45), RED, 0.04),
                  bx((fx, sy * W * 0.35, 1.3), (0.1, 0.6, 0.12), ORG)]
    parts.append(bbx((fx + 0.03, 0, grille_z), (0.15, W * 0.41, 0.6), MDK, 0.04))
    if bumper:
        parts += [bbx((fx - 0.15, 0, 1.0), (0.6, W * 0.96, 0.45), MDK, 0.08),
                  bbx((rx + 0.1, 0, 1.05), (0.55, W * 0.96, 0.5), MDK, 0.08)]
    if plate:
        parts.append(bx((rx - 0.07, 0, 1.75), (0.06, 1.6, 0.5), YEL))
    if antenna:
        parts.append(lmb((rx + 4.7, 0.0, roof[0][1] + 0.2), (rx + 3.9, 0.0, roof[0][1] + 1.2), 0.04, 0.02, MDK, 6))
    return parts


# ---------------------------------------------------------------------------------------------- suburbs
def barbecue():
    """Kettle barbecue (1 m tall, 57 cm bowl): a domed lid on a bowl with a seam band and a lid handle, a top vent, three
    splayed legs to an ash pan, two wheels; snow on the lid."""
    R, Z = 0.95, 2.1
    parts = [usp((0, 0, Z), R, MDK, (1, 1, 0.82), 14, 7), rcy((0, 0, Z + 0.02), R + 0.04, 0.12, MET, 14),
             rcy((0, 0, Z + R * 0.82 + 0.03), 0.22, 0.1, MET, 10), usp((0, 0, Z + R * 0.55), 0.6, SNOW, (1, 1, 0.3), 10, 3)]
    parts += tube([(0.0, -0.35, Z + 0.62), (0.0, -0.35, Z + 0.86), (0.0, 0.35, Z + 0.86), (0.0, 0.35, Z + 0.62)], 0.04, MET, 6,
                  joints=False)
    parts.append(bbx((0, 0, Z + 0.9), (0.14, 0.8, 0.14), WOOD, 0.03))
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 2
        foot = (math.cos(a) * 1.0, math.sin(a) * 1.0, 0.0)
        parts.append(lmb((math.cos(a) * 0.55, math.sin(a) * 0.55, Z - 0.55), foot, 0.06, 0.05, MET, 8))
        if k > 0:
            parts.append(rcy((foot[0] * 1.05, foot[1] * 1.05, 0.25), 0.25, 0.1, RUB, 10, axis="x"))
    parts += [rcy((0, 0, 0.95), 0.6, 0.06, MET, 12), rcy((0, 0, 0.75), 0.24, 0.3, MDK, 10, r2=0.3),
              bx((1.05, 0, Z - 0.25), (0.4, 0.06, 0.06), MET)]
    return parts


def lawn_mower():
    """Push mower (deck 55 cm, 1.6 m with handle): a round-nosed deck with a rib, a domed engine cover with a pull
    cord, four wheels, a fabric grass bag, a looped handle."""
    parts = [rcy((0.2, 0, 0.75), 1.0, 0.5, RED, 14), bbx((-0.55, 0, 0.75), (1.3, 1.96, 0.5), RED, 0.12),
             usp((0.25, 0, 1.15), 0.62, MDK, (1, 1, 0.6), 10, 4),
             rcy((0.25, 0, 1.6), 0.24, 0.16, RED, 10), bbx((-0.1, 0.45, 1.35), (0.35, 0.25, 0.3), MET, 0.04)]
    for x in (-0.95, 0.9):
        for sy in (-1, 1):
            parts += [rcy((x, sy * 1.08, 0.45), 0.42, 0.2, RUB, 10, axis="y"),
                      rcy((x, sy * 1.18, 0.45), 0.2, 0.04, MET, 8, axis="y")]
    parts += [bbx((-1.6, 0, 1.15), (1.0, 1.4, 1.0), MDK, 0.2), bx((-1.6, 0, 1.68), (0.7, 1.0, 0.06), RUB)]
    parts += tube([(-1.2, -0.62, 1.1), (-2.8, -0.62, 3.9), (-2.8, 0.62, 3.9), (-1.2, 0.62, 1.1)], 0.06, MET, 6, joints=False)
    parts += [rcy((-2.8, 0, 3.9), 0.1, 1.0, RUB, 8, axis="y"), lmb((-2.7, -0.3, 3.75), (-2.3, -0.3, 3.4), 0.03, 0.03, MDK, 6)]
    return parts


def garden_fence():
    """Picket fence section (2 m x 1.1 m): pointed pickets on two rails between square posts with caps; worn white paint,
    snow on the rails and caps."""
    L, H = 6.4, 3.5
    parts = []
    for x in (-L / 2, L / 2):
        parts += [bbx((x, 0, H / 2 + 0.2), (0.45, 0.45, H + 0.4), WHT, 0.04), bbx((x, 0, H + 0.48), (0.6, 0.6, 0.16), TRIM, 0.03),
                  usp((x, 0, H + 0.62), 0.2, TRIM, (1, 1, 0.8), 10, 5), bx((x, 0, H + 0.58), (0.5, 0.5, 0.06), SNOW)]
    for z in (0.9, 2.6):
        parts += [bbx((0, -0.18, z), (L, 0.14, 0.3), WHT, 0.03), bx((0, -0.18, z + 0.18), (L - 0.4, 0.14, 0.06), SNOW)]
    n = 11
    for k in range(n):
        x = -L / 2 + 0.45 + (L - 0.9) * (k + 0.5) / n
        h = H - 0.1 + 0.18 * math.sin(math.pi * (k + 0.5) / n)
        parts.append(bev(pg((x, 0.0, 0), [(-0.17, 0.12), (0.17, 0.12), (0.17, h - 0.32), (0.0, h), (-0.17, h - 0.32)],
                            0.12, WHT, "y"), 0.02))
    parts.append(bx((0.0, 0.07, 1.4), (0.25, 0.03, 0.25), WORN))
    return parts


def trampoline():
    """Garden trampoline (3.6 m, 2.6 m net): a padded round frame on W legs, a dark mat, curved net poles to a top
    ring, a net of thin cords; snow on the pad ring."""
    R, Z = 5.6, 2.6
    parts = [trs((0, 0, Z + 0.15), R - 0.35, 0.35, BLU, 24, 5),
             rcy((0, 0, Z + 0.05), R - 0.7, 0.06, MDK, 24), trs((0, 0, Z + 0.45), R - 0.35, 0.16, SNOW, 20, 3)]
    for k in range(6):  # W legs
        a = 2 * math.pi * k / 6
        c, s2 = math.cos(a), math.sin(a)
        parts += tube([(c * R, s2 * R, Z), (c * (R + 0.3), s2 * (R + 0.3), 0.1), (c * (R - 1.2), s2 * (R - 1.2), 0.1),
                       (c * (R - 0.9), s2 * (R - 0.9), Z)], 0.12, MET, 6, joints=False)
    poles = 6
    for k in range(poles):  # curved net poles
        a = 2 * math.pi * (k + 0.5) / poles
        c, s2 = math.cos(a), math.sin(a)
        parts += tube([(c * (R + 0.15), s2 * (R + 0.15), Z), (c * (R + 0.35), s2 * (R + 0.35), Z + 3.6),
                       (c * (R + 0.05), s2 * (R + 0.05), Z + 8.0)], 0.12, BLU, 8, joints=False)
    parts.append(trs((0, 0, Z + 8.0), R + 0.05, 0.1, MDK, 18, 3))
    for k in range(12):  # net cords
        a = 2 * math.pi * k / 12
        parts.append(bx((math.cos(a) * (R + 0.2), math.sin(a) * (R + 0.2), Z + 4.0), (0.04, 0.04, 8.0), MDK))
    return parts


def garden_shed():
    """Timber garden shed (2.4 x 1.8 m, 2.3 m ridge): clapboard walls on a plinth, a felt gable roof with fascia boards
    and a snow ridge, a ledged door with hinges, a four-pane window, a water butt under a downpipe."""
    W, D, Hw = 7.7, 5.8, 5.8
    parts = [bbx((0, 0, Hw / 2 + 0.3), (W, D, Hw), WOOD, 0.06), bbx((0, 0, 0.15), (W + 0.4, D + 0.4, 0.3), CONC, 0.04)]
    for k in range(8):  # clapboard lines, front and sides
        z = 0.9 + k * 0.68
        parts += [bx((0, D / 2 + 0.03, z), (W - 0.1, 0.06, 0.08), BARK), bx((W / 2 + 0.03, 0, z), (0.06, D - 0.1, 0.08), BARK),
                  bx((-W / 2 - 0.03, 0, z), (0.06, D - 0.1, 0.08), BARK)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(bx((sx * (W / 2 - 0.05), sy * (D / 2 - 0.05), Hw / 2 + 0.3), (0.3, 0.3, Hw), TRIM))
    parts += gable_roof(W, D, Hw + 0.3, 2.4, ROOFB, over=0.5, ridge_x=True)
    parts += [on_wall("+y", D / 2, -1.6, 3.05, 2.6, 0.14, 5.5, 0.07, DOOR)]
    for z in (1.0, 4.9):
        parts.append(on_wall("+y", D / 2, -1.6, z, 2.4, 0.08, 0.3, 0.15, BARK))
        parts.append(on_wall("+y", D / 2, -2.6, z, 0.7, 0.06, 0.12, 0.2, MDK))
    parts.append(lmb((-0.6, D / 2 + 0.16, 1.2), (-2.5, D / 2 + 0.16, 4.7), 0.08, 0.08, BARK, 6))
    parts.append(on_wall("+y", D / 2, -0.55, 3.0, 0.12, 0.1, 0.4, 0.2, MET))
    parts += window("+y", D / 2, 1.9, 3.9, 2.2, 1.8, GLS, TRIM, mull=1, transom=True)
    parts += [rcy((W / 2 + 0.9, D / 2 - 1.2, 1.4), 0.85, 2.8, TEAL, 16), rcy((W / 2 + 0.9, D / 2 - 1.2, 2.85), 0.9, 0.1, MDK, 16),
              rcy((W / 2 + 0.9, D / 2 - 1.2, 2.93), 0.7, 0.06, SNOW, 14), rcy((W / 2 + 0.3, D / 2 - 1.2, Hw / 2 + 1.8), 0.14, Hw - 1.0, MDK, 8)]
    return parts


def car_estate():
    """Estate car (4.8 x 1.8 x 1.5 m): the sedan's build with a long roof to an upright tailgate, a D pillar, roof rails;
    snow on the roof."""
    body = [(-7.55, 0.95), (7.45, 0.95), (7.55, 1.55), (7.35, 2.45), (3.4, 2.85), (-7.45, 3.0), (-7.65, 1.75)]
    glass = [(-7.25, 2.95), (3.1, 2.8), (0.9, 4.45), (-6.95, 4.55)]
    roof = [(-7.05, 4.47), (0.95, 4.38), (0.85, 4.62), (-6.95, 4.72)]
    pillars = [[(-1.05, 2.85), (-0.55, 2.85), (-0.8, 4.48), (-1.25, 4.48)],
               [(-4.4, 2.9), (-3.9, 2.9), (-3.9, 4.5), (-4.4, 4.5)],
               [(-7.3, 2.95), (-6.5, 2.95), (-6.6, 4.55), (-7.0, 4.55)]]
    snow = [(-6.6, 4.72), (0.55, 4.6), (0.5, 4.68), (-6.55, 4.78)]
    parts = profile_car(body, glass, roof, pillars, (-4.7, 4.5), 5.8, TEAL, snow, seams=(-0.85, 2.8, -4.15), skirt=8.6)
    for sy in (-1, 1):
        parts += tube([(-6.6, sy * 2.2, 4.72), (-6.4, sy * 2.2, 4.98), (0.2, sy * 2.2, 4.9), (0.4, sy * 2.2, 4.66)], 0.07, MET, 6,
                      joints=False)
    return parts


# ---------------------------------------------------------------------------------------------- main street
def cafe_table_parasol():
    """Café set: a 2.7 m parasol (eight-rib canopy with a scalloped valance, a vent cap, a pole), a round bistro table
    and two wire chairs; snow on the canopy."""
    Hc = 7.2
    parts = [rcy((0, 0, Hc + 0.65), 4.3, 1.3, RED, 16, r2=0.45), rcy((0, 0, Hc + 1.45), 0.7, 0.35, RED, 16, r2=0.3),
             rcy((0, 0, Hc + 1.25), 2.6, 0.55, SNOW, 16, r2=0.5), rcy((0, 0, Hc / 2 + 0.6), 0.1, Hc + 1.2, MET, 10),
             usp((0, 0, Hc + 1.75), 0.18, MET, (1, 1, 1), 8, 5)]
    for k in range(16):  # valance scallops
        a = 2 * math.pi * (k + 0.5) / 16
        parts.append(bbx((math.cos(a) * 4.15, math.sin(a) * 4.15, Hc - 0.15), (1.55, 0.06, 0.35), WHT if k % 2 else RED,
                         0.0, a + math.pi / 2))
    for k in range(8):  # ribs under the canopy
        a = 2 * math.pi * k / 8
        parts.append(lmb((0, 0, Hc - 1.6), (math.cos(a) * 2.6, math.sin(a) * 2.6, Hc + 0.25), 0.04, 0.04, MET, 6))
    parts += [rcy((0, 0, 2.4), 1.15, 0.1, WHT, 18), rcy((0, 0, 2.3), 1.2, 0.06, MET, 18),
              rcy((0, 0, 1.2), 0.1, 2.3, MDK, 10), rcy((0, 0, 0.06), 0.75, 0.12, MDK, 16, r2=0.6)]
    for k, a in enumerate((0.0, math.pi)):
        cx, cy2 = math.cos(a) * 2.2, math.sin(a) * 2.2
        back = 1 if k == 0 else -1
        parts += [rcy((cx, cy2, 1.48), 0.7, 0.1, WORN, 16)]
        for j in range(4):
            b = 2 * math.pi * (j + 0.5) / 4
            parts.append(lmb((cx + math.cos(b) * 0.45, cy2 + math.sin(b) * 0.45, 1.45),
                             (cx + math.cos(b) * 0.62, cy2 + math.sin(b) * 0.62, 0.0), 0.05, 0.05, MDK, 6))
        bxx = cx + back * 0.68
        parts += tube([(bxx, cy2 - 0.55, 1.5), (bxx + back * 0.12, cy2 - 0.55, 3.0), (bxx + back * 0.12, cy2 + 0.55, 3.0),
                       (bxx, cy2 + 0.55, 1.5)], 0.05, MDK, 6, joints=False)
        parts.append(bx((bxx + back * 0.1, cy2, 2.6), (0.06, 1.0, 0.5), WORN))
    return parts


def fruit_crates():
    """Grocer's display: three slatted wooden crates (two below, one tilted on top) heaped with round fruit in four
    colours on a dark stand."""
    parts = [bbx((0, 0, 0.35), (3.9, 2.0, 0.7), MDK, 0.05)]
    crate = [((-0.98, 0, 1.3), 0.0), ((0.98, 0, 1.3), 0.0)]
    for (x, y, z), _ in crate:
        parts += [bx((x, y, z), (1.85, 1.8, 1.2), WOOD)]
        for k in range(2):
            parts.append(bx((x, y + 0.92, z - 0.3 + k * 0.6), (1.85, 0.06, 0.12), BARK))
    fruit = [((-1.35, -0.35), RED), ((-0.65, -0.35), RED), ((-1.0, 0.4), RED),
             ((0.65, -0.35), ORG), ((1.35, -0.35), ORG), ((1.0, 0.4), YEL)]
    for (x, y), c in fruit:
        parts.append(usp((x, y, 2.0), 0.36, c, (1, 1, 0.95), 8, 4))
    parts += [bx((0, -0.1, 2.75), (1.9, 1.5, 0.9), WOOD), bx((0, 0.66, 2.75), (1.9, 0.06, 0.12), BARK)]
    for x, y, c in ((-0.45, -0.25, LEAF), (0.4, -0.25, LEAF), (0.0, 0.35, LEAF)):
        parts.append(usp((x, y - 0.1, 3.36), 0.34, c, (1, 1, 0.95), 8, 4))
    return parts


def sandwich_board():
    """Pavement A-board (1 m): two framed chalkboard panels leaning together with a hinge bar, abstract chalk strokes
    and a pictogram cup; snow on the top bar."""
    H, Wd, lean = 3.2, 1.9, 0.33
    parts = []
    for sy in (-1, 1):
        top, foot = (0, sy * 0.08, H), (0, sy * (0.08 + H * lean), 0.0)
        a = math.atan2(H * lean, H)
        cy2, cz = sy * (0.08 + H * lean / 2), H / 2
        verts = []
        for (u, v) in ((-Wd / 2, 0.0), (Wd / 2, 0.0), (Wd / 2, H), (-Wd / 2, H)):
            y = sy * (0.08 + (H - v) * lean)
            verts.append((u, y, v))
        t = 0.1
        verts2 = [(x, y + sy * t, z) for x, y, z in verts]
        parts.append(raw(verts + verts2, [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)],
                         WOOD))
        inner = [(x * 0.8, y + sy * (t + 0.02), 0.25 + z * 0.8) for x, y, z in verts]
        inner2 = [(x, y - sy * 0.02, z) for x, y, z in inner]
        parts.append(raw(inner + inner2, [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], MDK))
        for k, (u, v, w) in enumerate(((0.0, 2.5, 1.1), (-0.15, 2.1, 0.8), (0.1, 1.7, 0.9))):
            y = sy * (0.08 + (H - v) * lean + t + 0.05)
            parts.append(bx((u, y, v), (w, 0.02, 0.1), WHT, 0.0))
        yc = sy * (0.08 + (H - 1.0) * lean + t + 0.06)
        parts += [rcy((0, yc, 1.0), 0.28, 0.04, WHT, 12, axis="y"), rcy((0.32, yc, 1.05), 0.1, 0.04, WHT, 8, axis="y")]
    parts += [rcy((0, 0, H + 0.02), 0.08, Wd + 0.1, MET, 8, axis="x"), bx((0, 0, H + 0.14), (Wd, 0.28, 0.06), SNOW)]
    return parts


def bike_rack():
    """Two Sheffield stands on a paved strip with a parked city bike: tube hoops, smooth tyres, a diamond frame, a
    basket."""
    parts = [bx((0, 0, 0.04), (8.0, 2.4, 0.08), WALK)]
    for x in (-2.4, 2.4):
        parts += tube([(x - 1.1, 0, 0.05), (x - 1.1, 0, 2.35), (x - 0.8, 0, 2.75), (x + 0.8, 0, 2.75), (x + 1.1, 0, 2.35),
                       (x + 1.1, 0, 0.05)], 0.13, MDK, 6, joints=False)
        parts.append(bx((x, 0, 2.92), (1.4, 0.24, 0.06), SNOW))
    y = 0.5
    r = 1.05
    for x in (-3.0, 0.6):
        parts += [trs((x, y, r + 0.05), r, 0.12, RUB, 16, 3, stand=True)]
    bb, seat, head = (-1.3, y, 1.25), (-1.75, y, 2.85), (0.2, y, 2.95)
    parts += [lmb((-3.0, y, 1.1), bb, 0.06, 0.06, TEAL, 5), lmb((-3.0, y, 1.1), seat, 0.06, 0.06, TEAL, 5),
              lmb(bb, seat, 0.08, 0.08, TEAL, 6), lmb(seat, head, 0.08, 0.08, TEAL, 6), lmb(bb, head, 0.09, 0.09, TEAL, 6),
              lmb(head, (0.6, y, 1.1), 0.06, 0.06, TEAL, 6), lmb((-1.75, y, 2.85), (-1.85, y, 3.25), 0.04, 0.04, MET, 6),
              usp((-1.85, y, 3.32), 0.22, RUB, (1.6, 0.7, 0.45), 8, 3), lmb(head, (0.05, y, 3.5), 0.05, 0.05, MET, 5),
              lmb((0.05, y - 0.7, 3.5), (0.05, y + 0.7, 3.5), 0.05, 0.05, MDK, 5), rcy(bb, 0.25, 0.08, MDK, 8, axis="y"),
              bbx((0.75, y, 3.1), (0.8, 0.8, 0.55), WOOD, 0.04)]
    return parts


def post_box():
    """Pillar post box (1.6 m): a smooth red cylinder on a dark plinth, a domed cap over a moulded cornice, a hooded
    letter slot, a plate and a door outline; snow on the cap."""
    R = 0.85
    parts = [rcy((0, 0, 0.2), R + 0.1, 0.4, MDK, 16), rcy((0, 0, 2.4), R, 4.0, RED, 16),
             rcy((0, 0, 4.5), R + 0.1, 0.2, RED, 16), usp((0, 0, 4.62), R + 0.04, RED, (1, 1, 0.5), 16, 5),
             usp((0, 0, 4.92), R * 0.7, SNOW, (1, 1, 0.32), 12, 3), rcy((0, 0, 5.1), 0.16, 0.12, RED, 8)]
    parts += [bbx((0, R - 0.02, 3.65), (1.0, 0.3, 0.18), RED, 0.03), bx((0, R + 0.06, 3.5), (0.85, 0.06, 0.08), MDK),
              bx((0, R + 0.03, 2.7), (0.75, 0.06, 0.55), WHT), bx((0, R + 0.05, 2.7), (0.6, 0.04, 0.4), MDK),
              bx((0, R + 0.02, 1.25), (0.3, 0.04, 0.22), YEL)]
    for x in (-0.62, 0.62):
        parts.append(bx((x * 0.98, R * 0.72, 2.2), (0.06, 0.06, 2.8), MDK, math.atan2(R * 0.72, x)))
    return parts


# ---------------------------------------------------------------------------------------------- downtown
def landmark_clock_tower():
    """Civic clock tower (36 m): a rusticated stone base with an arched door, a brick shaft with corner pilasters and
    tall arched windows, a cornice, a clock stage with four lit faces, hands and hour marks, an open belfry with arched
    openings and columns, a lead spire with lucarnes and a finial; snow on every cornice."""
    S = 19.0  # shaft width
    parts = [bbx((0, 0, 1.0), (S + 3.0, S + 3.0, 2.0), CONC, 0.1), bbx((0, 0, 7.5), (S + 1.4, S + 1.4, 11.0), CONC, 0.15)]
    for k in range(4):  # rustication joints on the base
        parts.append(bx((0, 0, 3.4 + k * 2.6), (S + 1.6, S + 1.6, 0.2), KERB))
    parts += [bbx((0, 0, 13.3), (S + 2.0, S + 2.0, 0.8), CONC, 0.06), bx((0, 0, 13.75), (S + 1.6, S + 1.6, 0.1), SNOW),
              bbx((0, 0, 37.0), (S, S, 46.0), WB, 0.2)]
    parts.append(arch_face((0, S / 2 + 0.7 + 0.05, 2.0), 5.2, 8.8, DOOR, 0.2))
    parts.append(arch_face((0, S / 2 + 0.8 + 0.1, 2.0), 6.4, 9.6, TRIM, 0.1))
    parts += [bbx((0, S / 2 + 2.4, 1.0), (8.0, 3.0, 2.0), CONC, 0.06)]
    for sx in (-1, 1):  # corner pilasters
        for sy in (-1, 1):
            parts.append(bbx((sx * (S / 2 + 0.1), sy * (S / 2 + 0.1), 37.0), (2.2, 2.2, 46.0), CONC, 0.06))
    for side in range(4):  # tall windows, clock stage, belfry, per face
        yaw = side * math.pi / 2
        c, s2 = -math.sin(yaw), math.cos(yaw)
        def at(u, d, z):
            return (u * math.cos(yaw) - d * math.sin(yaw), u * math.sin(yaw) + d * math.cos(yaw), z)
        for u in (-4.0, 4.0):
            parts.append(arch_face(at(u, S / 2 + 0.05, 20.0), 3.2, 12.0, GLS, 0.2, yaw))
            parts.append(arch_face(at(u, S / 2, 19.6), 4.2, 13.0, TRIM, 0.2, yaw))
            parts.append(bbx(at(u, S / 2 + 0.3, 19.5), (4.6, 0.8, 0.4), TRIM, 0.04, yaw))
        parts.append(rcy(at(0, S / 2 + 0.25, 52.0), 6.4, 0.5, TRIM, 24, axis="y", yaw=yaw))
        parts.append(rcy(at(0, S / 2 + 0.55, 52.0), 5.6, 0.2, GLIT, 24, axis="y", yaw=yaw))
        for k in range(12):
            a = 2 * math.pi * k / 12
            parts.append(bx(at(math.cos(a) * 4.8, S / 2 + 0.7, 52.0 + math.sin(a) * 4.8), (0.6 if k % 3 == 0 else 0.3, 0.1, 0.3), MDK,
                            yaw))
        parts += [bx(at(0.0, S / 2 + 0.8, 53.7), (0.35, 0.1, 3.4), MDK, yaw), bx(at(1.2, S / 2 + 0.8, 52.0), (2.6, 0.1, 0.3), MDK, yaw),
                  rcy(at(0, S / 2 + 0.85, 52.0), 0.4, 0.15, MDK, 12, axis="y", yaw=yaw)]
        for u in (-4.6, 0.0, 4.6):  # belfry columns and openings
            parts.append(rcy(at(u, S / 2 - 1.2, 69.0), 0.7, 9.0, CONC, 12))
        for u in (-2.3, 2.3):
            parts.append(arch_face(at(u, S / 2 - 1.6, 64.5), 3.4, 8.6, MDK, 0.4, yaw))
    parts += [bbx((0, 0, 60.4), (S + 2.4, S + 2.4, 1.0), CONC, 0.08), bx((0, 0, 61.0), (S + 2.0, S + 2.0, 0.12), SNOW),
              bbx((0, 0, 69.0), (S - 2.6, S - 2.6, 16.0), WB, 0.1),
              bbx((0, 0, 74.0), (S + 1.6, S + 1.6, 1.2), CONC, 0.08), bx((0, 0, 74.66), (S + 1.2, S + 1.2, 0.12), SNOW)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts += [rcy((sx * (S / 2 - 0.3), sy * (S / 2 - 0.3), 69.0), 0.9, 9.0, CONC, 12),
                      rcy((sx * (S / 2 + 0.3), sy * (S / 2 + 0.3), 76.6), 0.5, 3.0, CONC, 10, r2=0.1)]
    parts += [rcy((0, 0, 85.5), S * 0.66, 21.0, ROOF, 4, r2=0.3, yaw=math.pi / 4),
              rcy((0, 0, 76.8), S * 0.62, 2.4, SNOW, 4, r2=S * 0.52, yaw=math.pi / 4),
              usp((0, 0, 96.4), 0.9, MET, (1, 1, 1), 12, 6), rcy((0, 0, 99.0), 0.12, 4.4, MET, 8, r2=0.02)]
    for side in range(4):  # lucarnes on the spire
        yaw = side * math.pi / 2
        u, d = 0.0, 4.0
        p = (-d * math.sin(yaw), d * math.cos(yaw), 79.0)
        parts += [bbx(p, (2.4, 2.6, 3.2), ROOF, 0.04, yaw),
                  pg(p, [(-1.4, 1.6), (1.4, 1.6), (0.0, 3.0)], 2.8, ROOF, "y", yaw),
                  bx((p[0] - 1.32 * math.sin(yaw), p[1] + 1.32 * math.cos(yaw), 78.9), (1.4, 0.1, 2.0), GLIT, yaw)]
    return parts


def landmark_obelisk():
    """War-memorial obelisk (18 m): three granite steps, a moulded die with a bronze plaque and wreaths, a tapered shaft
    with a base band, a gilt pyramidion; chain posts around; snow on the steps and the die."""
    parts = []
    for k, (w, h) in enumerate(((22.0, 1.2), (18.4, 1.2), (15.2, 1.2))):
        z = k * 1.2
        parts += [bbx((0, 0, z + h / 2), (w, w, h), KERB if k == 0 else CONC, 0.08), bx((0, 0, z + h + 0.03), (w - 0.6, w - 0.6, 0.06), SNOW)]
    parts += [bbx((0, 0, 4.4), (12.4, 12.4, 1.2), CONC, 0.1), bbx((0, 0, 8.6), (10.0, 10.0, 7.2), CONC, 0.15),
              bbx((0, 0, 12.6), (11.4, 11.4, 0.8), CONC, 0.08), bx((0, 0, 13.04), (11.0, 11.0, 0.08), SNOW),
              bbx((0, 0, 13.8), (8.0, 8.0, 1.6), CONC, 0.08),
              rcy((0, 0, 37.0), 3.4 * 1.414, 44.8, CONC, 4, r2=1.9 * 1.414, yaw=math.pi / 4),
              rcy((0, 0, 15.2), 4.0 * 1.414, 0.8, CONC, 4, r2=3.6 * 1.414, yaw=math.pi / 4),
              rcy((0, 0, 60.6), 1.95 * 1.414, 2.6, MET, 4, r2=0.0, yaw=math.pi / 4)]
    for side in range(4):
        yaw = side * math.pi / 2
        def at(u, d, z):
            return (u * math.cos(yaw) - d * math.sin(yaw), u * math.sin(yaw) + d * math.cos(yaw), z)
        parts += [bbx(at(0, 5.05, 8.8), (5.2, 0.2, 3.4), YEL if side == 0 else MET, 0.05, yaw),
                  bx(at(0, 5.18, 9.0), (3.8, 0.06, 0.25), MDK, yaw), bx(at(0, 5.18, 8.2), (3.0, 0.06, 0.2), MDK, yaw),
                  smo(("torus", at(0, 5.3, 5.8), 0.85, 0.2, LDK, 14, 5, True))]
    for k in range(8):  # chain posts with chains
        a = 2 * math.pi * k / 8
        x, y = math.cos(a) * 13.6, math.sin(a) * 13.6
        parts += [rcy((x, y, 1.4), 0.3, 2.8, MDK, 10), usp((x, y, 2.85), 0.36, MDK, (1, 1, 1), 10, 6)]
        b = 2 * math.pi * (k + 1) / 8
        x2, y2 = math.cos(b) * 13.6, math.sin(b) * 13.6
        mx, my = (x + x2) / 2 * 0.99, (y + y2) / 2 * 0.99
        parts += [lmb((x, y, 2.5), (mx, my, 1.7), 0.07, 0.07, MDK, 6), lmb((mx, my, 1.7), (x2, y2, 2.5), 0.07, 0.07, MDK, 6)]
    for sx in (-1, 1):  # four lamp standards on the top step's corners
        for sy in (-1, 1):
            x, y = sx * 6.6, sy * 6.6
            parts += [rcy((x, y, 3.0), 0.55, 0.6, MDK, 12), rcy((x, y, 3.9), 0.4, 1.2, MDK, 12, r2=0.25),
                      rcy((x, y, 7.2), 0.18, 6.6, MDK, 10, r2=0.13), rcy((x, y, 10.6), 0.3, 0.2, MDK, 12),
                      rcy((x, y, 11.3), 0.5, 1.2, GLIT, 8, r2=0.62), rcy((x, y, 12.1), 0.75, 0.4, MDK, 8, r2=0.2),
                      rcy((x, y, 12.35), 0.4, 0.12, SNOW, 8, r2=0.1), usp((x, y, 12.5), 0.16, MDK, (1, 1, 1.4), 8, 4)]
    return parts


def landmark_arch():
    """Triumphal arch (15 m wide, 14 m tall): two rusticated piers around a round-headed passage, coffered soffit,
    engaged columns on high plinths, an entablature with a cornice, an attic with a blank plaque, keystone and
    spandrel wreaths; snow on the cornice and the attic."""
    W, D, H = 48.0, 16.0, 36.0
    r = 7.0
    face = [(-W / 2, 0.0), (-r, 0.0), (-r, 20.0)] + arc_pts(0.0, 20.0, r, math.pi, 0.0, 10)[1:-1] + [(r, 20.0), (r, 0.0), (W / 2, 0.0),
                                                                                                (W / 2, H), (-W / 2, H)]
    parts = [pg((0, 0, 0), face, D, WA, "y")]
    parts.append(pg((0, 0, 19.4), [(-r + 0.05, 0.0), (r - 0.05, 0.0), (r - 0.05, 0.2), (-r + 0.05, 0.2)], D - 0.2, MDK, "y"))
    for k in range(5):  # rustication joints on the piers
        z = 2.0 + k * 3.6
        for sx in (-1, 1):
            for sy in (-1, 1):
                parts.append(bx((sx * (W / 2 + r) / 2, sy * (D / 2 + 0.05), z), (W / 2 - r - 0.2, 0.1, 0.25), KERB))
    for sy in (-1, 1):
        for u in (-20.0, -10.5, 10.5, 20.0):  # engaged columns on plinths
            parts += [bbx((u, sy * (D / 2 + 0.9), 2.4), (3.2, 1.8, 4.8), CONC, 0.06),
                      rcy((u, sy * (D / 2 + 0.9), 14.9), 1.2, 20.2, WC, 16), rcy((u, sy * (D / 2 + 0.9), 25.4), 1.5, 0.8, CONC, 16, r2=1.2),
                      bbx((u, sy * (D / 2 + 0.9), 26.1), (3.4, 2.0, 0.6), CONC, 0.04), rcy((u, sy * (D / 2 + 0.9), 5.1), 1.45, 0.6, CONC, 16)]
        parts += [bbx((0, sy * (D / 2 + 0.6), 27.5), (W + 1.0, 1.4, 2.2), CONC, 0.08),
                  bbx((0, sy * (D / 2 + 1.0), 28.9), (W + 2.0, 2.2, 0.8), CONC, 0.06), bx((0, sy * (D / 2 + 1.0), 29.33), (W + 1.6, 1.8, 0.08), SNOW),
                  bbx((0, sy * (D / 2 + 0.25), 32.8), (14.0, 0.5, 4.6), MET, 0.05), bx((0, sy * (D / 2 + 0.52), 33.4), (10.0, 0.06, 0.4), MDK),
                  bx((0, sy * (D / 2 + 0.52), 32.2), (7.0, 0.06, 0.3), MDK),
                  bev(pg((0, sy * (D / 2 + 0.35), 25.6), [(-1.1, 0.0), (1.1, 0.0), (1.5, 2.2), (-1.5, 2.2)], 0.7, CONC, "y"), 0.04)]
        for u in (-4.4, 4.4):
            parts.append(smo(("torus", (u * 1.6, sy * (D / 2 + 0.25), 23.6), 1.3, 0.3, LDK, 14, 5, True)))
    parts += [bbx((0, 0, H + 0.6), (W - 4.0, D - 1.0, 1.2), CONC, 0.08), bx((0, 0, H + 1.26), (W - 4.6, D - 1.6, 0.1), SNOW)]
    for k in range(6):  # coffer ribs in the passage vault
        y = -D / 2 + (k + 0.5) * D / 6
        pts = arc_pts(0.0, 20.0, r - 0.1, 0.0, math.pi, 10)
        for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
            parts.append(lmb((x0, y, z0), (x1, y, z1), 0.25, 0.25, CONC, 6))
    return parts


def tram():
    """Low-floor tram (30 m, three sections): rounded cab ends with a raked windscreen, a continuous window band with
    pillars, double doors, a livery stripe, articulation bellows, roof pods and a pantograph, bogie skirts with wheels;
    snow on the roof."""
    Hh, Wd = 11.6, 8.5
    secs = [(-30.0, -10.4), (-9.6, 9.6), (10.4, 30.0)]
    parts = []
    for i, (x0, x1) in enumerate(secs):
        if i == 0:
            prof = [(x0 + 1.6, 1.0), (x1, 1.0), (x1, Hh), (x0 + 2.6, Hh), (x0 + 0.2, 7.0), (x0, 4.0), (x0 + 0.4, 1.8)]
        elif i == 2:
            prof = [(x0, 1.0), (x1 - 1.6, 1.0), (x1 - 0.4, 1.8), (x1, 4.0), (x1 - 0.2, 7.0), (x1 - 2.6, Hh), (x0, Hh)]
        else:
            prof = [(x0, 1.0), (x1, 1.0), (x1, Hh), (x0, Hh)]
        parts += [bev(pg((0, 0, 0), prof, Wd, WHT, "y"), 0.3)]
        parts += [bx(((x0 + x1) / 2, sy * (Wd / 2 + 0.02), 3.2), (x1 - x0 - 1.0, 0.06, 0.7), RED) for sy in (-1, 1)]
        parts += [bbx(((x0 + x1) / 2, 0, Hh + 0.5), (x1 - x0 - 4.0, Wd - 2.0, 1.0), WHT, 0.12),
                  bx(((x0 + x1) / 2, 0, Hh + 1.04), (x1 - x0 - 4.6, Wd - 2.6, 0.08), SNOW),
                  bx(((x0 + x1) / 2, 0, Hh + 0.04), (x1 - x0 - 0.8, Wd - 0.6, 0.08), SNOW)]
        n = 5 if i == 1 else 4
        xa, xb = x0 + (3.6 if i == 0 else 0.8), x1 - (3.6 if i == 2 else 0.8)
        for sy in (-1, 1):
            parts.append(bx(((xa + xb) / 2, sy * (Wd / 2 + 0.03), 7.6), (xb - xa, 0.08, 3.6), GLS))
            for k in range(n + 1):
                x = xa + (xb - xa) * k / n
                parts.append(bx((x, sy * (Wd / 2 + 0.07), 7.6), (0.35, 0.08, 3.7), MDK))
            dx = (x0 + x1) / 2 + (2.0 if i != 1 else 0.0) * (1 if i == 0 else -1)
            parts += [bx((dx, sy * (Wd / 2 + 0.09), 5.4), (4.0, 0.08, 8.4), GLS), bx((dx, sy * (Wd / 2 + 0.12), 5.4), (0.15, 0.06, 8.4), MDK),
                      bx((dx, sy * (Wd / 2 + 0.12), 9.7), (4.2, 0.08, 0.3), MDK)]
        for x in ((x0 + 5.0, x1 - 5.0) if i != 1 else ((x0 + x1) / 2,)):
            for sy in (-1, 1):
                parts.append(rcy((x - 1.3, sy * (Wd / 2 - 0.9), 1.0), 0.9, 0.5, MDK, 14, axis="y"))
                parts.append(rcy((x + 1.3, sy * (Wd / 2 - 0.9), 1.0), 0.9, 0.5, MDK, 14, axis="y"))
            parts.append(bbx((x, 0, 1.1), (5.4, Wd - 0.2, 1.0), MDK, 0.1))
    for xa in (-10.0, 10.0):  # articulation bellows
        parts.append(bbx((xa, 0, 6.0), (0.9, Wd - 0.8, Hh - 1.6), RUB, 0.1))
        for k in range(3):
            parts.append(bx((xa, 0, 2.0 + k * 3.6), (1.0, Wd - 0.6, 0.2), MDK))
    for sx in (-1, 1):  # cab glazing, lights, destination blind
        x = sx * 30.0
        parts += [raw([(x - sx * 0.2 + 0.0, -Wd / 2 + 0.6, 7.0), (x - sx * 0.2, Wd / 2 - 0.6, 7.0),
                       (x - sx * 2.6, Wd / 2 - 0.6, Hh - 0.4), (x - sx * 2.6, -Wd / 2 + 0.6, Hh - 0.4),
                       (x - sx * 0.05, -Wd / 2 + 0.6, 7.0), (x - sx * 0.05, Wd / 2 - 0.6, 7.0),
                       (x - sx * 2.45, Wd / 2 - 0.6, Hh - 0.3), (x - sx * 2.45, -Wd / 2 + 0.6, Hh - 0.3)],
                      [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], GLS),
                  bx((x - sx * 2.75, 0, Hh - 0.2), (0.2, 3.6, 0.7), GLIT)]
        for sy in (-1, 1):
            parts += [rcy((x - sx * 0.2, sy * 2.6, 3.2), 0.4, 0.15, WHT, 12, axis="x"), bx((x - sx * 0.25, sy * 2.6, 2.4), (0.12, 0.8, 0.3), RED)]
    parts += [bbx((0, 0, Hh + 1.6), (6.0, 4.0, 1.0), MDK, 0.1)]
    parts += tube([(-1.6, -1.6, Hh + 2.1), (0.8, -1.4, Hh + 4.0), (-0.6, -1.2, Hh + 6.0)], 0.12, MDK, 6)
    parts += tube([(-1.6, 1.6, Hh + 2.1), (0.8, 1.4, Hh + 4.0), (-0.6, 1.2, Hh + 6.0)], 0.12, MDK, 6)
    parts.append(rcy((-0.6, 0, Hh + 6.05), 0.12, 3.6, MET, 8, axis="y"))
    return parts


def subway_entrance():
    """Metro entrance (6.5 m) on a raised pavement block: granite walls round a stair well, steps down to the well floor,
    round handrails, a curved glass canopy on steel ribs, a totem with a roundel; snow on the canopy and walls."""
    L, Wd, P = 20.8, 8.0, 3.0
    parts = [bx((0, Wd / 2 + 1.6, P / 2), (L + 2.4, 1.2, P), WALK),
             bx((0, -Wd / 2 - 1.6, P / 2), (L + 2.4, 1.2, P), WALK), bx((-L / 2 - 0.6, 0, P / 2), (1.2, Wd + 2.0, P), WALK),
             bx((L / 2 + 0.7, 0, P / 2), (1.0, Wd + 2.0, P), WALK), bx((0, 0, 0.05), (L, Wd + 2.0, 0.1), MDK)]
    for sy in (-1, 1):
        parts += [bbx((0, sy * (Wd / 2 + 0.5), P + 1.6), (L, 1.0, 3.2), CONC, 0.08), bx((0, sy * (Wd / 2 + 0.5), P + 3.24), (L - 0.2, 0.9, 0.08), SNOW),
                  bx((0, sy * (Wd / 2 + 0.5), P / 2), (L, 1.0, P), CONC)]
    parts += [bbx((-L / 2 + 0.5, 0, P + 1.6), (1.0, Wd, 3.2), CONC, 0.08), bx((-L / 2 + 0.5, 0, P / 2), (1.0, Wd, P), CONC)]
    n = 10
    for k in range(n):  # steps from the pavement down to the well floor
        top = P - (k + 1) * P / n
        parts.append(bx((L / 2 - 0.6 - k * 1.1, 0, (top + 0.1) / 2 + 0.05), (1.1, Wd, top + 0.1 if top > 0 else 0.2), KERB))
        parts.append(bx((L / 2 - 0.1 - k * 1.1, 0, top + 0.15), (0.1, Wd, 0.05), YEL))
    for sy in (-1, 1):
        parts += tube([(L / 2 + 0.5, sy * (Wd / 2 - 0.3), P + 3.2), (L / 2 - 1.0, sy * (Wd / 2 - 0.3), P + 3.2),
                       (L / 2 - 11.0, sy * (Wd / 2 - 0.3), 3.2)], 0.14, MET, 8)
    ribs = 6
    for k in range(ribs):  # curved canopy on ribs
        x = -L / 2 + 1.5 + k * (L - 3.0) / (ribs - 1)
        pts = [(x, -Wd / 2 - 0.3, P + 3.2)] + [(x, -Wd / 2 - 0.3 + (Wd + 0.6) * t, P + 9.0 + 1.6 * math.sin(math.pi * t))
                                               for t in (0.0, 0.25, 0.5, 0.75, 1.0)] + [(x, Wd / 2 + 0.3, P + 3.2)]
        parts += tube(pts, 0.16, MDK, 10, joints=False)
    for t0 in range(4):
        t1 = t0 + 1
        za, zb = P + 9.2 + 1.6 * math.sin(math.pi * t0 / 4), P + 9.2 + 1.6 * math.sin(math.pi * t1 / 4)
        ya, yb = -Wd / 2 - 0.3 + (Wd + 0.6) * t0 / 4, -Wd / 2 - 0.3 + (Wd + 0.6) * t1 / 4
        verts = [(-L / 2 + 1.0, ya, za), (L / 2 - 1.0, ya, za), (L / 2 - 1.0, yb, zb), (-L / 2 + 1.0, yb, zb)]
        box = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
        parts.append(raw(verts + [(x, y, z + 0.12) for x, y, z in verts], box, GLS))
        if 1 <= t0 <= 2:
            parts.append(raw([(x, y, z + 0.14) for x, y, z in verts] + [(x, y, z + 0.3) for x, y, z in verts], box, SNOW))
    tx, ty = L / 2 + 0.7, Wd / 2 + 1.6
    parts += [rcy((tx, ty, P + 3.6), 0.22, 7.2, MDK, 10), rcy((tx, ty, P + 7.8), 1.3, 0.3, RED, 20, axis="x"),
              rcy((tx, ty, P + 7.8), 0.85, 0.36, WHT, 20, axis="x"), bx((tx, ty, P + 7.8), (0.42, 2.9, 0.55), BLU),
              rcy((tx, ty, P + 0.2), 0.5, 0.4, MDK, 12), usp((tx, ty, P + 9.2), 0.3, SNOW, (1, 1, 0.5), 8, 3)]
    return parts


def limousine():
    """Stretch limousine (8.5 m): the sedan's build stretched, a long greenhouse with four side pillars, a raised rear
    roof, chrome trim, a third axle-free long body; snow on the roof."""
    body = [(-13.4, 0.95), (13.4, 0.95), (13.5, 1.55), (13.3, 2.45), (9.4, 2.85), (-10.4, 2.95), (-13.3, 2.75), (-13.5, 1.75)]
    glass = [(-10.3, 2.85), (9.1, 2.8), (6.9, 4.4), (-9.3, 4.45)]
    roof = [(-9.35, 4.38), (6.95, 4.34), (6.85, 4.58), (-9.25, 4.62)]
    pillars = [[(x - 0.3, 2.85), (x + 0.3, 2.85), (x + 0.2, 4.45), (x - 0.4, 4.45)] for x in (-6.0, -2.0, 2.0, 5.0)]
    pillars.append([(-10.3, 2.85), (-9.3, 2.85), (-8.95, 4.45), (-9.3, 4.47)])
    snow = [(-8.9, 4.58), (6.5, 4.55), (6.45, 4.64), (-8.85, 4.66)]
    parts = profile_car(body, glass, roof, pillars, (-10.4, 10.4), 6.0, MDK, snow, seams=(-6.3, -1.7, 4.7, 8.8),
                        handles=(-5.4, -1.0, 5.6), mirror_x=8.75, skirt=17.0)
    for sy in (-1, 1):
        parts.append(bx((-0.6, sy * 2.94, 1.55), (21.0, 0.06, 0.12), MET))
    return parts


# ---------------------------------------------------------------------------------------------- billboards (fronts atlas)
def billboard(cell, W, H, lift, legs, lamps, braces):
    """Roadside billboard, fronts cells only: the poster face in a framed edge, steel legs, a rear truss of round
    members, a front catwalk with grating and a rail, gooseneck lamps over the top; snow on the frame top and the
    catwalk."""
    S, T, SN, LT = FS, FC, FN, FL
    z0 = lift
    parts = [bx((0, 0.05, z0 + H / 2), (W, 0.3, H), cell),
             bbx((0, -0.15, z0 + H / 2), (W + 0.3, 0.3, H + 0.3), S, 0.05),
             bbx((0, 0.1, z0 + H + 0.25), (W + 0.8, 0.8, 0.5), T, 0.06), bx((0, 0.1, z0 + H + 0.54), (W + 0.6, 0.7, 0.08), SN),
             bbx((0, 0.1, z0 - 0.25), (W + 0.8, 0.8, 0.5), T, 0.06)]
    for sx in (-1, 1):
        parts.append(bbx((sx * (W / 2 + 0.2), 0.1, z0 + H / 2), (0.5, 0.8, H + 0.9), T, 0.05))
    for x in legs:
        parts += [rcy((x, -1.0, (z0 + H * 0.8) / 2), 0.5, z0 + H * 0.8, S, 16), rcy((x, -1.0, 0.3), 0.9, 0.6, S, 16, r2=0.6),
                  bbx((x, -1.0, 0.05), (2.4, 2.4, 0.1), T, 0.03)]
    ys = -0.9
    for k in range(braces + 1):  # rear truss: horizontal chords and diagonals
        x = -W / 2 + W * k / braces
        parts.append(lmb((x, ys, z0 + 0.3), (x, ys, z0 + H - 0.3), 0.12, 0.12, S, 8))
        if k < braces:
            x2 = -W / 2 + W * (k + 1) / braces
            parts.append(lmb((x, ys, z0 + 0.3), (x2, ys, z0 + H - 0.3), 0.1, 0.1, S, 8))
    for z in (z0 + 0.3, z0 + H / 2, z0 + H - 0.3):
        parts.append(rcy((0, ys, z), 0.14, W, S, 8, axis="x"))
    cy0 = 1.4
    parts += [bx((0, cy0, z0 - 0.6), (W, 2.0, 0.12), S), bx((0, cy0, z0 - 0.52), (W - 0.2, 1.8, 0.04), SN)]
    for k in range(int(W / 1.6)):
        parts.append(bx((-W / 2 + 0.8 + k * 1.6, cy0, z0 - 0.66), (0.1, 2.0, 0.1), T))
    parts.append(rcy((0, cy0 + 0.95, z0 + 1.6), 0.08, W, S, 8, axis="x"))
    for k in range(int(W / 4.0) + 1):
        x = -W / 2 + k * W / int(W / 4.0)
        parts += [rcy((x, cy0 + 0.95, z0 + 0.5), 0.07, 2.2, S, 6), lmb((x, cy0 - 0.9, z0 - 0.6), (x, -0.4, z0 - 1.8), 0.08, 0.08, S, 6)]
    for k in range(lamps):
        x = -W / 2 + W * (k + 0.5) / lamps
        parts += tube([(x, -0.2, z0 + H + 0.5), (x, -0.2, z0 + H + 1.6), (x, 1.2, z0 + H + 2.2), (x, 2.4, z0 + H + 1.9)], 0.09, S, 6)
        parts += [bbx((x, 2.6, z0 + H + 1.75), (1.1, 0.9, 0.35), S, 0.05), bx((x, 2.6, z0 + H + 1.56), (0.9, 0.7, 0.04), LT),
                  bx((x, 2.6, z0 + H + 1.96), (1.0, 0.8, 0.06), SN)]
    return parts


def bb_t4(cell):
    return lambda: billboard(cell, 19.2, 9.6, 6.4, (-5.5, 5.5), 4, 8)


def bb_t5(cell):
    return lambda: billboard(cell, 38.4, 12.8, 12.8, (-12.0, 0.0, 12.0), 7, 14)


# ---------------------------------------------------------------------------------------------- meme originals
def meme_wet_floor_sign():
    """Wet-floor A-frame sign (60 cm): two yellow panels with rounded tops, a hazard triangle and abstract bars, a hinge
    and a handle slot, standing in a smooth puddle."""
    H, Wd, lean = 2.0, 1.0, 0.26
    parts = [rcy((0.2, 0.1, 0.02), 1.7, 0.04, WATER, 24, r2=1.65), rcy((-0.9, -0.8, 0.02), 0.6, 0.04, WATER, 16)]
    for sy in (-1, 1):
        def at(u, v, out=0.0):
            return (u, sy * (0.06 + (H - v) * lean + out), v)
        verts = [at(-Wd / 2, 0.0), at(Wd / 2, 0.0), at(Wd / 2, H - 0.25), at(Wd * 0.3, H), at(-Wd * 0.3, H), at(-Wd / 2, H - 0.25)]
        verts2 = [(x, y + sy * 0.08, z) for x, y, z in verts]
        n = len(verts)
        faces = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, n + i, n + (i + 1) % n, (i + 1) % n) for i in range(n)]
        parts.append(bev(raw(verts + verts2, faces, YEL), 0.03))
        tri = [at(0.0, 1.55, 0.1), at(0.42, 0.85, 0.1), at(-0.42, 0.85, 0.1)]
        parts.append(raw(tri + [(x, y + sy * 0.03, z) for x, y, z in tri], [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], MDK))
        for k, w in enumerate((0.7, 0.5)):
            c = at(0.0, 0.55 - k * 0.2, 0.1)
            parts.append(bx(c, (w, 0.03, 0.09), MDK))
        parts.append(bx(at(0.0, H - 0.18, 0.1), (0.36, 0.03, 0.12), MDK))
    parts += [rcy((0, 0, H + 0.02), 0.06, Wd * 0.7, MDK, 8, axis="x"), bx((0, 0, H + 0.1), (Wd * 0.55, 0.16, 0.04), SNOW)]
    return parts


def meme_pond_cart():
    """A shopping trolley tipped into a small pond: a wire basket of thin rods with a red plastic handle, a child seat
    flap, a chassis with castor wheels in the air, ripples around it, lily pads; ice-skin in winter (w-water)."""
    R = 4.5
    parts = [rcy((0, 0, 0.08), R, 0.16, WATER, 20)]
    for k in range(7):
        a = 2 * math.pi * k / 7
        parts.append(usp((math.cos(a) * (R + 0.2), math.sin(a) * (R + 0.2), 0.15), 0.75 + 0.12 * (k % 3), KERB, (1.3, 1.0, 0.45), 8, 4))
    parts += [trs((0.4, 0.2, 0.18), 2.6, 0.05, WHT, 20, 3)]
    tilt = 0.55
    water = 0.12
    def rot(x, y, z):  # the trolley pitched nose first into the water, handle end up
        c, s2 = math.cos(tilt), math.sin(tilt)
        return (x * c + z * s2 + 0.4, y + 0.2, -x * s2 + z * c - 0.9)
    def seg(a, b, r, s3, n):
        """A rod clipped at the water line: below it the trolley is under water and nothing is built."""
        if a[2] < water and b[2] < water:
            return []
        if a[2] < water or b[2] < water:
            lo, hi = (a, b) if a[2] < b[2] else (b, a)
            t = (water - lo[2]) / (hi[2] - lo[2])
            lo = tuple(lo[i] + (hi[i] - lo[i]) * t for i in range(3))
            a, b = lo, hi
        return [lmb(a, b, r, r, s3, n)]
    L, Wd, H, Z = 3.0, 1.8, 1.4, 1.2
    corners = [(-L / 2, -Wd / 2), (L / 2, -Wd / 2), (L / 2, Wd / 2), (-L / 2, Wd / 2)]
    for z in (Z, Z + H):
        ring = [rot(x, y, z) for x, y in corners]
        for p0, p1 in zip(ring, ring[1:] + ring[:1]):
            parts += seg(p0, p1, 0.06, MET, 6)
    for x, y in corners:
        parts += seg(rot(x, y, Z), rot(x, y, Z + H), 0.05, MET, 6)
    for k in range(1, 6):  # side rods
        x = -L / 2 + L * k / 6
        for y in (-Wd / 2, Wd / 2):
            parts += seg(rot(x, y, Z), rot(x, y, Z + H), 0.03, MET, 4)
    for k in range(1, 3):
        y = -Wd / 2 + Wd * k / 3
        parts += seg(rot(L / 2, y, Z), rot(L / 2, y, Z + H), 0.03, MET, 4)
        parts += seg(rot(-L / 2, y, Z), rot(-L / 2, y, Z + H), 0.03, MET, 4)
    parts += seg(rot(-L / 2 - 0.3, -Wd / 2, Z + H + 0.4), rot(-L / 2 - 0.3, Wd / 2, Z + H + 0.4), 0.1, RED, 10)
    parts += seg(rot(-L / 2, -Wd / 2, Z + H), rot(-L / 2 - 0.3, -Wd / 2, Z + H + 0.4), 0.05, MET, 6)
    parts += seg(rot(-L / 2, Wd / 2, Z + H), rot(-L / 2 - 0.3, Wd / 2, Z + H + 0.4), 0.05, MET, 6)
    parts.append(bx(rot(-L / 2 + 0.35, 0, Z + H - 0.2), (0.08, Wd - 0.2, 0.4), RED, 0.0))
    for x, y in corners:  # chassis and castors (the rear pair lifted clear of the water)
        parts += seg(rot(x * 0.9, y * 0.8, Z), rot(x * 0.9, y * 0.8, 0.3), 0.05, MET, 6)
        c = rot(x * 0.9, y * 0.8, 0.15)
        if c[2] > water + 0.25:
            parts.append(rcy(c, 0.25, 0.14, RUB, 12, axis="y"))
    parts += seg(rot(-L / 2 * 0.9, 0, 0.3), rot(L / 2 * 0.9, 0, 0.3), 0.06, MET, 6)
    parts += [rcy((-2.4, -2.2, 0.19), 0.6, 0.04, LEAF, 14), rcy((2.6, 2.0, 0.19), 0.45, 0.04, LEAF, 14)]
    return parts


def meme_cone_statue():
    """A civic bronze-look statue of a plain, faceless standing figure in a long coat on a stepped stone plinth, with a
    traffic cone placed on its head; a blank plaque; snow on the shoulders, the plinth and the cone tip."""
    st = WC  # stone-statue look (muted)
    parts = [bbx((0, 0, 0.5), (11.0, 11.0, 1.0), KERB, 0.08), bbx((0, 0, 1.4), (9.2, 9.2, 0.8), CONC, 0.08),
             bbx((0, 0, 4.4), (7.0, 7.0, 5.2), CONC, 0.12), bbx((0, 0, 7.25), (7.8, 7.8, 0.5), CONC, 0.06),
             bx((0, 0, 7.53), (7.4, 7.4, 0.06), SNOW), bx((0, 0, 1.83), (8.8, 8.8, 0.06), SNOW),
             bbx((0, 3.55, 4.6), (3.8, 0.1, 2.0), MET, 0.04), bx((0, 3.62, 4.9), (2.6, 0.04, 0.2), MDK), bx((0, 3.62, 4.3), (2.0, 0.04, 0.16), MDK)]
    z = 7.5
    parts += [bbx((0, 0, z + 0.25), (3.6, 3.0, 0.5), st, 0.08),
              rcy((0, 0, z + 3.2), 1.55, 5.4, st, 16, r2=1.2),  # coat skirt
              lmb((-0.55, 0.1, z + 0.5), (-0.6, 0.1, z + 3.0), 0.45, 0.5, st, 12), lmb((0.55, -0.1, z + 0.5), (0.6, -0.1, z + 3.0), 0.45, 0.5, st, 12),
              usp((-0.6, 0.45, z + 0.65), 0.45, st, (1.0, 1.6, 0.6), 10, 6), usp((0.6, 0.3, z + 0.65), 0.45, st, (1.0, 1.6, 0.6), 10, 6),
              usp((0, 0, z + 7.0), 1.45, st, (1.15, 0.85, 1.25), 16, 10),  # chest
              usp((0, 0, z + 8.4), 1.4, st, (1.3, 0.85, 0.5), 14, 6),  # shoulders
              rcy((0, 0, z + 8.9), 0.45, 0.8, st, 12), usp((0, 0, z + 9.95), 0.95, st, (0.92, 1.0, 1.12), 16, 10)]
    for sx in (-1, 1):
        parts += [lmb((sx * 1.55, 0, z + 8.3), (sx * 1.85, 0.25, z + 6.0), 0.48, 0.4, st, 12),
                  lmb((sx * 1.85, 0.25, z + 6.0), (sx * 1.6, 0.75 if sx > 0 else 0.4, z + 4.1), 0.4, 0.34, st, 12),
                  usp((sx * 1.6, 0.75 if sx > 0 else 0.4, z + 3.85), 0.38, st, (0.8, 1.0, 1.2), 10, 6),
                  usp((sx * 1.55, 0, z + 8.3), 0.5, st, (1, 1, 1), 12, 6),
                  usp((sx * 1.2, 0, z + 8.85), 0.55, SNOW, (1.4, 1.0, 0.25), 10, 4)]
    parts += [rcy((0, 0, z + 2.4), 1.65, 0.3, st, 16), bx((0, 1.05, z + 5.5), (0.25, 0.3, 4.4), st)]
    cz = z + 10.7  # traffic cone: base, body with two reflective bands, rounded tip
    parts += [bbx((0, 0, cz + 0.1), (2.3, 2.3, 0.2), ORG, 0.06), rcy((0, 0, cz + 1.75), 0.95, 3.1, ORG, 18, r2=0.18),
              rcy((0, 0, cz + 1.1), 0.83, 0.4, WHT, 18, r2=0.73), rcy((0, 0, cz + 2.1), 0.6, 0.35, WHT, 18, r2=0.52),
              usp((0, 0, cz + 3.3), 0.2, ORG, (1, 1, 1), 10, 5), usp((0, 0, cz + 3.45), 0.15, SNOW, (1, 1, 0.5), 8, 3)]
    return parts


def meme_phone_1pc():
    """A giant smartphone propped on its kickstand on a plinth, screen lit with an abstract price-card layout, a
    camera bump, side buttons, a charging cable snaking off to a plug, and a hanging "1 pc" price tag (pictogram)."""
    W, H, T = 7.0, 14.0, 0.9
    a = 0.22  # leaning back
    def lean(x, y, z):
        return (x, y - z * math.sin(a), z * math.cos(a) + 1.6)
    parts = [bbx((0, 0, 0.8), (12.0, 7.0, 1.6), CONC, 0.12), bx((0, 0, 1.62), (11.6, 6.6, 0.06), SNOW)]
    slab = []
    hw, hh, r = W / 2, H, 1.0
    corner = []
    for cx, cz, a0 in ((hw - r, r, -math.pi / 2), (hw - r, hh - r, 0.0), (-hw + r, hh - r, math.pi / 2), (-hw + r, r, math.pi)):
        corner += arc_pts(cx, cz, r, a0, a0 + math.pi / 2, 8)
    for y in (T / 2, -T / 2):
        slab.append([lean(x, y, z) for x, z in corner])
    n = len(corner)
    verts = slab[0] + slab[1]
    faces = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    parts.append(bev(raw(verts, faces, MDK), 0.18))
    scr = []
    for cx, cz, a0 in ((hw - r, r, -math.pi / 2), (hw - r, hh - r, 0.0), (-hw + r, hh - r, math.pi / 2), (-hw + r, r, math.pi)):
        scr += arc_pts(cx, cz, r - 0.35, a0, a0 + math.pi / 2, 8)
    sv = [lean(x, T / 2 + 0.02, z) for x, z in scr] + [lean(x, T / 2 + 0.08, z) for x, z in scr]
    m = len(scr)
    parts.append(raw(sv, [tuple(range(m - 1, -1, -1)), tuple(range(m, 2 * m))] + [(i, n2, m + n2, m + i) for i, n2 in ((i, (i + 1) % m) for i in range(m))], GLIT))
    for u, z, w, h, s in ((0.0, 9.6, 4.6, 3.6, WHT), (0.0, 9.6, 2.6, 2.0, RED), (-1.2, 6.2, 2.4, 0.4, WHT), (-1.6, 5.4, 1.6, 0.3, WHT),
                          (0.0, 3.0, 4.8, 1.2, BLU), (0.0, H - 0.8, 1.4, 0.3, MDK)):
        parts.append(bx(lean(u, T / 2 + 0.12, z), (w, 0.06, h), s))
    parts += [bbx(lean(1.8, -T / 2 - 0.25, H - 2.2), (2.6, 0.5, 2.6), MDK, 0.2)]
    for u in (1.2, 2.4):
        parts.append(rcy(lean(u, -T / 2 - 0.55, H - 2.2), 0.5, 0.2, GLS, 16, axis="y"))
    for z, h in ((H - 3.4, 1.6), (H - 5.6, 1.0)):
        parts.append(bbx(lean(hw + 0.08, 0, z), (0.2, 0.5, h), MET, 0.05))
    parts += [lmb(lean(0, -T / 2, 6.0), (0, -4.8, 1.65), 0.25, 0.25, MDK, 10)]  # kickstand
    for i in range(3):  # app icons under the price card
        for j in range(2):
            parts.append(rcy(lean(-2.0 + i * 2.0, T / 2 + 0.14, 5.6 - j * 1.2), 0.42, 0.06, (TEAL, YEL, BLU, RED, LEAF, ORG)[i + 3 * j], 16,
                             axis="y"))
    parts += [bbx((0, 0, 1.85), (9.0, 5.0, 0.5), CONC, 0.06)]
    parts += tube([lean(0, 0, 0.0), (0.0, 0.8, 2.3), (1.6, 2.2, 2.3), (3.0, 1.4, 2.3), (4.0, 0.4, 2.0), (5.0, 1.2, 1.75),
                   (5.4, 2.6, 1.75)], 0.18, WHT, 10)
    parts += [bbx((5.4, 3.3, 2.1), (1.0, 1.3, 0.9), WHT, 0.12), bx((5.1, 3.95, 2.1), (0.12, 0.4, 0.3), MET), bx((5.7, 3.95, 2.1), (0.12, 0.4, 0.3), MET)]
    tag = lean(-hw + 0.6, T / 2 + 0.3, H - 0.6)
    parts += [lmb(tag, (tag[0] - 0.5, tag[1] + 0.3, tag[2] - 1.6), 0.03, 0.03, MDK, 6),
              bbx((tag[0] - 0.6, tag[1] + 0.35, tag[2] - 2.4), (1.8, 0.1, 1.2), WHT, 0.05),
              bx((tag[0] - 0.6, tag[1] + 0.42, tag[2] - 2.25), (0.25, 0.04, 0.7), RED),
              bx((tag[0] - 0.15, tag[1] + 0.42, tag[2] - 2.4), (0.45, 0.04, 0.45), RED)]
    return parts


def meme_banana_scale():
    """"Banana for scale", civic size: an 8.5 m banana lying on a giant platform scale with a round dial and a needle;
    a smooth curved peel in segments with ridges, a dark stem and tip, brown flecks; snow on its top."""
    parts = [bbx((0, 0, 0.9), (30.0, 12.0, 1.8), MDK, 0.2), bbx((0, 0, 1.9), (28.6, 10.6, 0.3), MET, 0.06),
             bx((0, 0, 2.06), (28.0, 10.0, 0.04), WALK)]
    for k in range(12):
        parts.append(bx((-12.6 + k * 2.3, 0, 2.1), (0.2, 9.6, 0.06), MDK))
    parts += [bbx((-16.4, 0, 6.0), (3.0, 4.0, 12.0), MDK, 0.15), rcy((-14.8, 0, 9.0), 3.4, 0.4, MET, 28, axis="x"),
              rcy((-14.55, 0, 9.0), 3.0, 0.3, WHT, 28, axis="x")]
    for k in range(10):
        a = math.pi * (0.1 + 0.8 * k / 9)
        parts.append(bx((-14.38, math.cos(a) * 2.5, 9.0 + math.sin(a) * 2.5), (0.06, 0.18, 0.5), MDK))
    parts += [lmb((-14.3, 0, 9.0), (-14.3, 1.6, 11.0), 0.12, 0.05, RED, 6), rcy((-14.3, 0, 9.0), 0.35, 0.2, MDK, 12, axis="x")]
    n = 14  # banana: tube of tapered segments along an arc
    pts = []
    for k in range(n + 1):
        t = k / n
        ang = math.pi * (0.25 + 0.5 * t)
        pts.append((-math.cos(ang) * 16.0, 0.0, 2.1 + 16.0 - math.sin(ang) * 16.0 + 2.2))
    for k in range(n):
        t0, t1 = k / n, (k + 1) / n
        r0 = 0.6 + 2.0 * math.sin(math.pi * t0) ** 0.6
        r1 = 0.6 + 2.0 * math.sin(math.pi * t1) ** 0.6
        parts.append(lmb(pts[k], pts[k + 1], r0, r1, YEL, 14))
        if 0 < k:
            parts.append(usp(pts[k], r0 * 1.0, YEL, (1, 1, 1), 14, 7))
    for k in range(2, n - 1, 3):
        parts.append(usp((pts[k][0], 0.6, pts[k][2] + 0.4), 0.3, BARK, (1.5, 1, 0.5), 8, 4))
    parts += [lmb(pts[0], (pts[0][0] - 1.4, 0, pts[0][2] + 1.2), 0.45, 0.35, BARK, 10), usp(pts[-1], 0.55, BARK, (1, 1, 1), 10, 6),
              usp((0, 0, 2.1 + 2.2 + 16.0 - 16.0 + 2.6), 3.6, SNOW, (2.0, 0.6, 0.18), 12, 4)]
    return parts


def meme_vacant_lot():
    """A vacant city lot (9.5 m square): cracked gravel ground with puddles, a chain-link fence on round posts with a
    gate, a blank "for sale" board on legs, weeds, a dumped tyre and a pallet, one traffic cone, an abstract-graffiti
    party wall; snow heaps in winter."""
    S = 30.0
    parts = [bbx((0, 0, 0.15), (S, S, 0.3), STAIN, 0.05)]
    for x, y, r in ((-6.0, 4.0, 2.2), (5.0, -7.0, 1.6), (8.0, 6.0, 1.2)):
        parts.append(rcy((x, y, 0.32), r, 0.04, WATER, 18))
    for x0, y0, x1, y1 in ((-10, -2, -3, 1), (2, 3, 9, -1), (-4, -9, 1, -12)):
        parts.append(bx(((x0 + x1) / 2, (y0 + y1) / 2, 0.31), (math.hypot(x1 - x0, y1 - y0), 0.15, 0.02), MDK, math.atan2(y1 - y0, x1 - x0)))
    parts += [bbx((0, -S / 2 + 0.8, 7.0), (S, 1.6, 14.0), WB, 0.1), bx((0, -S / 2 + 1.62, 4.0), (12.0, 0.04, 5.0), GRAF),
              bx((0, -S / 2 + 0.8, 14.06), (S - 0.2, 1.4, 0.12), SNOW)]
    posts = []
    for k in range(7):
        posts.append((-S / 2 + 0.3 + k * (S - 0.6) / 6, S / 2 - 0.3))
    for k in range(1, 6):
        posts += [(-S / 2 + 0.3, S / 2 - 0.3 - k * (S - 2.2) / 5), (S / 2 - 0.3, S / 2 - 0.3 - k * (S - 2.2) / 5)]
    for x, y in posts:
        parts += [rcy((x, y, 3.0), 0.16, 6.0, MET, 10), usp((x, y, 6.0), 0.2, MET, (1, 1, 0.7), 8, 4)]
    for (xa, ya, xb, yb) in ((-S / 2 + 0.3, S / 2 - 0.3, -3.0, S / 2 - 0.3), (3.0, S / 2 - 0.3, S / 2 - 0.3, S / 2 - 0.3),
                             (-S / 2 + 0.3, S / 2 - 0.3, -S / 2 + 0.3, -S / 2 + 1.6), (S / 2 - 0.3, S / 2 - 0.3, S / 2 - 0.3, -S / 2 + 1.6)):
        parts.append(lmb((xa, ya, 5.8), (xb, yb, 5.8), 0.08, 0.08, MET, 6))
        for z in (1.0, 2.6, 4.2):
            parts.append(lmb((xa, ya, z), (xb, yb, z), 0.04, 0.04, MET, 4))
    parts += [lmb((-3.0, S / 2 - 0.1, 0.4), (0.0, S / 2 - 0.1, 5.6), 0.06, 0.06, MET, 6)]
    gate = [(-3.0, S / 2 - 0.3), (0.2, S / 2 + 2.6)]
    for z in (0.6, 3.0, 5.6):
        parts.append(lmb((gate[0][0], gate[0][1], z), (gate[1][0], gate[1][1], z), 0.07, 0.07, MET, 6))
    parts.append(lmb((gate[1][0], gate[1][1], 0.3), (gate[1][0], gate[1][1], 5.8), 0.08, 0.08, MET, 6))
    parts += [bbx((6.0, 8.0, 6.6), (8.0, 0.3, 4.4), WHT, 0.06), bx((6.0, 8.17, 7.6), (6.4, 0.04, 1.0), RED),
              bx((6.0, 8.17, 6.0), (5.0, 0.04, 0.4), MDK), bx((6.0, 8.17, 5.3), (3.6, 0.04, 0.4), MDK)]
    for x in (3.0, 9.0):
        parts.append(bx((x, 8.0, 2.4), (0.3, 0.3, 4.8), WOOD))
    parts.append(bx((6.0, 8.0, 8.86), (7.8, 0.4, 0.1), SNOW))
    for x, y in ((-10.0, -8.0), (-11.0, 10.0), (10.0, -10.0), (-2.0, 11.5), (11.0, 1.0), (-7.0, -1.0)):
        parts += lobe_cluster((x, y, 0.8), 0.9, 3, LEAF, LDK, seed=int(x), squash=0.7, seg=8, rings=5, snow=False)
    parts += [trs((-6.0, -6.0, 0.7), 1.3, 0.45, RUB, 18, 8), bbx((9.0, -4.0, 0.6), (4.0, 3.2, 0.5), WOOD, 0.04)]
    for k in range(4):
        parts.append(bx((9.0 - 1.5 + k * 1.0, -4.0, 0.9), (0.7, 3.2, 0.1), WOOD))
    parts += [bbx((-2.0, 4.0, 0.42), (1.6, 1.6, 0.2), ORG, 0.04), rcy((-2.0, 4.0, 1.75), 0.68, 2.5, ORG, 16, r2=0.12),
              rcy((-2.0, 4.0, 1.6), 0.5, 0.35, WHT, 16, r2=0.44),
              usp((-10.0, 8.0, 0.3), 3.0, SNOW, (1.2, 1.0, 0.25), 12, 4), usp((10.0, 10.0, 0.3), 2.2, SNOW, (1.0, 1.2, 0.25), 12, 4)]
    return parts


RECIPES.update({
    "ck_barbecue": barbecue,
    "ck_lawn_mower": lawn_mower,
    "ck_garden_fence": garden_fence,
    "ck_trampoline": trampoline,
    "ck_garden_shed": garden_shed,
    "ck_car_estate": car_estate,
    "ck_cafe_table_parasol": cafe_table_parasol,
    "ck_fruit_crates": fruit_crates,
    "ck_sandwich_board": sandwich_board,
    "ck_bike_rack": bike_rack,
    "ck_post_box": post_box,
    "ck_landmark_clock_tower": landmark_clock_tower,
    "ck_landmark_obelisk": landmark_obelisk,
    "ck_landmark_arch": landmark_arch,
    "ck_tram": tram,
    "ck_subway_entrance": subway_entrance,
    "ck_limousine": limousine,
    "ck_billboard_404": bb_t4("bb_404"),
    "ck_billboard_chart": bb_t4("bb_chart"),
    "ck_billboard_loading": bb_t4("bb_loading"),
    "ck_billboard_empty": bb_t4("bb_empty"),
    "ck_billboard_arrow": bb_t4("bb_arrow"),
    "ck_billboard_testcard": bb_t5("bb_testcard"),
    "ck_billboard_nested": bb_t5("bb_nested"),
    "ck_meme_buffering_billboard": bb_t4("bb_buffering"),
    "ck_meme_wet_floor_sign": meme_wet_floor_sign,
    "ck_meme_pond_cart": meme_pond_cart,
    "ck_meme_cone_statue": meme_cone_statue,
    "ck_meme_phone_1pc": meme_phone_1pc,
    "ck_meme_banana_scale": meme_banana_scale,
    "ck_meme_vacant_lot": meme_vacant_lot,
})


# ---------------------------------------------------------------------------------------------- urban props (T077)
def signal_head(x, y, z, yaw=0.0, lit=0, lenses=3, s=MDK):
    """Traffic signal head facing +y (turned by yaw about its own centre): housing, a backplate with a reflective
    border, three lenses (one lit) under hooded visors; snow on the top."""
    c, sn = math.cos(yaw), math.sin(yaw)
    def at(u, d, h):
        return (x + u * c - d * sn, y + u * sn + d * c, z + h)
    H = 1.15 * lenses
    parts = [bbx(at(0, 0, 0), (1.1, 1.0, H), s, 0.08, yaw), bbx(at(0, -0.55, 0), (1.9, 0.08, H + 0.8), MDK, 0.03, yaw),
             bx(at(0, -0.5, 0), (1.95, 0.04, H + 0.85), YEL, yaw), bx(at(0, -0.55, 0), (1.7, 0.1, H + 0.6), MDK, yaw),
             bx(at(0, 0, H / 2 + 0.06), (1.0, 0.9, 0.1), SNOW, yaw)]
    colours = (RED, YEL, TEAL)
    for k in range(lenses):
        h = H / 2 - 0.575 - k * 1.15
        parts += [rcy(at(0, 0.52, h), 0.38, 0.06, colours[k] if k == lit else MDK, 14, axis="y", yaw=yaw),
                  rcy(at(0, 0.5, h), 0.42, 0.04, colours[k], 14, axis="y", yaw=yaw) if k == lit else
                  rcy(at(0, 0.5, h), 0.42, 0.04, GLS, 14, axis="y", yaw=yaw),
                  bbx(at(0, 0.82, h + 0.38), (0.9, 0.6, 0.08), s, 0.02, yaw)]
        for su in (-1, 1):
            parts.append(bx(at(su * 0.44, 0.8, h + 0.1), (0.06, 0.56, 0.55), s, yaw))
    return parts


def traffic_lights():
    """Junction signal (5.5 m pole, 4 m mast arm): a flared base, a tapered pole with collars, a curved mast arm with a
    tie rod carrying two signal heads and a blank street-name plate, a pole-mounted head and a pedestrian signal, a
    push-button box; snow on the heads and the arm."""
    Hp = 17.6
    parts = [rcy((0, 0, 0.35), 0.75, 0.7, MDK, 16, r2=0.55), rcy((0, 0, 0.08), 0.95, 0.16, CONC, 16),
             rcy((0, 0, Hp / 2), 0.42, Hp, WORN, 16, r2=0.3), usp((0, 0, Hp), 0.32, WORN, (1, 1, 0.8), 12, 5),
             rcy((0, 0, 3.0), 0.48, 0.2, MDK, 16), rcy((0, 0, 9.0), 0.4, 0.2, MDK, 16)]
    arm = [(0.0, 0.0, 15.6)] + [(0.0, 3.0 * k, 15.6 + 0.08 * k * k) for k in range(1, 5)]
    parts += tube(arm, 0.24, WORN, 12)
    parts += [lmb((0, 0, Hp - 0.3), (0, 8.0, 16.6), 0.07, 0.07, MDK, 6), bx((0, 6.0, 16.48 + 0.2), (0.3, 6.0, 0.06), SNOW)]
    for d in (6.5, 11.6):
        parts += [rcy((0, d, 16.2 + 0.05 * d), 0.12, 1.0, MDK, 8)]
        parts += signal_head(0, d, 13.9 + 0.05 * d, yaw=math.pi / 2, lit=2 if d > 7 else 0)
    parts += [bbx((0.25, 9.0, 17.6), (0.1, 3.6, 0.9), BLU, 0.04), bx((0.32, 9.0, 17.6), (0.04, 3.2, 0.6), WHT),
              bx((0.34, 9.0, 17.6), (0.04, 3.0, 0.44), BLU)]
    parts += signal_head(0.95, 0, 11.0, yaw=0.0, lit=0)
    parts += [bx((0.5, 0, 11.0), (0.6, 0.4, 0.4), MDK)]
    parts += [bbx((-0.95, 0, 7.0), (1.0, 0.9, 2.2), MDK, 0.06, 0.0), bx((-0.95, 0.47, 7.55), (0.7, 0.04, 0.7), RED),
              bx((-0.95, 0.47, 6.55), (0.7, 0.04, 0.7), GLS), bx((-0.95, 0, 8.16), (0.9, 0.8, 0.08), SNOW),
              bbx((0, 0.62, 4.0), (0.8, 0.5, 1.2), YEL, 0.06), rcy((0, 0.9, 3.85), 0.22, 0.1, MDK, 12, axis="y"),
              bx((0, 0.89, 4.35), (0.5, 0.04, 0.25), MDK)]
    return parts


def parking_meter():
    """Double-head parking meter (1.5 m): a slim post on a collar, a yoke carrying two rounded meter heads with domed
    windows, coin slots and card readers, a small solar panel; snow on the heads."""
    parts = [rcy((0, 0, 0.1), 0.42, 0.2, CONC, 14), rcy((0, 0, 1.6), 0.18, 3.0, WORN, 12), rcy((0, 0, 3.1), 0.24, 0.12, MDK, 12),
             bbx((0, 0, 3.25), (1.9, 0.5, 0.2), MDK, 0.05)]
    for sx in (-1, 1):
        x = sx * 0.62
        parts += [bbx((x, 0, 3.75), (0.95, 0.8, 0.9), WORN, 0.12), usp((x, 0, 4.25), 0.48, WORN, (1.0, 0.85, 0.75), 14, 7),
                  usp((x, 0.25, 4.3), 0.34, GLS, (1.0, 0.6, 0.85), 12, 6), rcy((x, 0.33, 4.3), 0.38, 0.06, MET, 14, axis="y"),
                  bx((x, 0.41, 3.65), (0.3, 0.04, 0.06), MDK), bbx((x, 0.42, 3.45), (0.5, 0.1, 0.25), MDK, 0.03),
                  bx((x, 0.48, 3.45), (0.3, 0.02, 0.06), TEAL), usp((x, 0, 4.58), 0.36, SNOW, (1.0, 0.85, 0.35), 10, 3)]
    parts += [lmb((0, 0, 4.4), (0, -0.2, 4.95), 0.05, 0.05, MDK, 6), bbx((0, -0.25, 5.0), (0.9, 0.6, 0.06), MDK, 0.02, 0.0),
              bx((0, -0.25, 5.04), (0.8, 0.5, 0.03), GLS), bx((0, -0.25, 5.08), (0.8, 0.5, 0.03), SNOW)]
    return parts


def e_scooter(x, y, yaw, colour):
    c, sn = math.cos(yaw), math.sin(yaw)
    def at(u, v, z):
        return (x + u * c - v * sn, y + u * sn + v * c, z)
    parts = [bbx(at(0.0, 0, 0.55), (2.6, 0.55, 0.22), colour, 0.06, yaw)]
    for u in (-1.45, 1.45):
        parts += [rcy(at(u, 0, 0.42), 0.4, 0.22, RUB, 12, axis="y", yaw=yaw), bx(at(u * 0.98, 0, 0.88), (0.8, 0.3, 0.06), colour, yaw)]
    parts += [lmb(at(1.35, 0, 0.5), at(1.15, 0, 3.6), 0.11, 0.09, colour, 8), lmb(at(1.15, -0.7, 3.65), at(1.15, 0.7, 3.65), 0.06, 0.06, MDK, 8),
              usp(at(1.2, 0, 3.4), 0.13, WHT, (1, 1, 1), 8, 4), bbx(at(1.2, 0, 3.7), (0.25, 0.35, 0.12), MDK, 0.02, yaw),
              lmb(at(-0.6, -0.2, 0.45), at(-0.95, -0.55, 0.05), 0.04, 0.04, MDK, 6)]
    return parts


def scooter_dock():
    """E-scooter dock (3 m): a concrete pad with a painted bay outline, a charging rail with a totem and screen, three
    parked e-scooters in two colours (no brand)."""
    L, D = 9.6, 4.6
    parts = [bbx((0, 0, 0.06), (L, D, 0.12), CONC, 0.04)]
    for sy in (-1, 1):
        parts.append(bx((0, sy * (D / 2 - 0.25), 0.13), (L - 0.4, 0.15, 0.02), WHT))
    for sx in (-1, 1):
        parts.append(bx((sx * (L / 2 - 0.25), 0, 0.13), (0.15, D - 0.4, 0.02), WHT))
    parts += [rcy((0, -1.7, 0.75), 0.12, L - 1.6, MDK, 10, axis="x")]
    for x in (-3.8, -1.3, 1.3, 3.8):
        parts += [rcy((x, -1.7, 0.4), 0.12, 0.7, MDK, 8), rcy((x, -1.7, 0.78), 0.22, 0.2, TEAL, 8)]
    parts += [bbx((L / 2 - 0.8, -1.7, 2.6), (1.0, 0.7, 5.0), MDK, 0.15), bx((L / 2 - 0.8, -1.33, 3.6), (0.7, 0.04, 1.0), GLIT),
              bx((L / 2 - 0.8, -1.33, 2.4), (0.6, 0.04, 0.3), TEAL), usp((L / 2 - 0.8, -1.7, 5.15), 0.4, SNOW, (1.2, 0.9, 0.3), 8, 3)]
    for k, x in enumerate((-2.6, 0.0, 2.6)):
        parts += e_scooter(x, 0.3, math.pi / 2 + (0.08 if k == 1 else 0.0), TEAL if k != 1 else ORG)
    return parts


def food_truck():
    """Street-food step van (6.5 m): a side-profile body with a sloping cab nose, a long serving hatch with a propped
    awning, a steel counter and an abstract menu board, a roof extractor and vent, a gas bottle cage, mirrors, wheels
    from the sedan kit, lights and bumpers; snow on the roof and the awning."""
    L, W = 20.8, 7.4
    body = [(-10.4, 1.1), (10.0, 1.1), (10.4, 2.6), (10.2, 5.2), (8.2, 9.6), (7.6, 10.2), (-10.2, 10.2), (-10.4, 9.8)]
    parts = [bev(pg((0, 0, 0), body, W, ORG, "y"), 0.3),
             bev(pg((0, 0, 0), [(9.9, 5.8), (8.3, 9.3), (7.3, 9.3), (7.3, 5.8)], W - 0.6, GLS, "y"), 0.06),
             bbx((-1.2, 0, 10.45), (17.6, W - 0.8, 0.5), WHT, 0.1), bx((-1.2, 0, 10.74), (17.0, W - 1.2, 0.08), SNOW)]
    for sy in (-1, 1):
        y = sy * (W / 2 + 0.02)
        parts += [bx((-0.5, y, 2.4), (19.6, 0.06, 0.8), WHT), bx((8.4, y, 6.6), (1.4, 0.06, 2.4), GLS),
                  bx((8.4, sy * (W / 2 + 0.06), 4.2), (0.06, 0.06, 4.2), MDK)]
    yh = W / 2
    parts += [bx((-1.6, yh + 0.03, 6.3), (11.0, 0.06, 4.2), MDK), bx((-1.6, yh - 0.6, 6.0), (10.4, 0.1, 3.4), GLIT),
              bbx((-1.6, yh + 0.6, 4.1), (11.6, 1.3, 0.25), MET, 0.05)]
    pivot = (yh + 0.05, 8.5)
    flap = [(-7.3, pivot[0], pivot[1]), (4.1, pivot[0], pivot[1]), (4.1, pivot[0] + 3.4, pivot[1] + 1.4), (-7.3, pivot[0] + 3.4, pivot[1] + 1.4)]
    parts.append(bev(raw(flap + [(x, y, z + 0.2) for x, y, z in flap],
                         [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], ORG), 0.04))
    parts.append(raw([(x, y, z + 0.22) for x, y, z in flap] + [(x, y, z + 0.3) for x, y, z in flap],
                     [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], SNOW))
    for x in (-6.5, 3.3):
        parts.append(lmb((x, yh + 0.1, 5.0), (x, yh + 3.0, 9.8), 0.07, 0.07, MET, 6))
    for k in range(5):  # menu board
        parts.append(bx((-8.6, yh + 0.05, 8.2 - k * 0.7), (2.6, 0.04, 0.3), WHT if k % 2 == 0 else YEL))
    parts += [bbx((-8.6, yh + 0.02, 7.0), (3.0, 0.06, 4.2), MDK, 0.02)]
    parts += [rcy((5.6, yh + 0.04, 6.4), 0.9, 0.06, YEL, 18, axis="y"),
              rcy((5.6, yh + 0.08, 6.4), 0.6, 0.06, RED, 18, axis="y")]
    parts += [rcy((-5.0, 0, 11.0), 0.7, 1.0, MET, 14), rcy((-5.0, 0, 11.6), 0.95, 0.2, MDK, 14, r2=0.5),
              bbx((2.0, 0, 11.0), (2.0, 2.0, 0.6), MET, 0.08), bx((2.0, 0, 11.34), (1.8, 1.8, 0.06), SNOW)]
    parts += [bbx((-11.0, -1.5, 3.0), (1.2, 1.6, 2.6), MET, 0.06), rcy((-11.0, -1.5, 3.0), 0.5, 2.2, RED, 12)]
    for x in (-6.8, 6.4):
        parts.append(rcy((x, 0, 1.35), 1.5, W * 0.98, RUB, 20, axis="y"))
        for sy in (-1, 1):
            parts += wheel(x, sy * (W / 2 - 0.6), 1.2, 1.2, 1.0, sy)
    for sy in (-1, 1):
        parts += [bbx((10.3, sy * 2.6, 3.3), (0.2, 1.2, 0.7), WHT, 0.04), bbx((-10.45, sy * 2.9, 3.6), (0.2, 0.9, 1.0), RED, 0.04),
                  lmb((8.8, sy * W / 2, 8.4), (9.2, sy * (W / 2 + 0.9), 8.0), 0.05, 0.05, MDK, 6),
                  bbx((9.2, sy * (W / 2 + 0.95), 7.5), (0.25, 0.4, 1.1), MDK, 0.04)]
    parts += [bbx((10.3, 0, 1.4), (0.7, W * 0.98, 0.7), MDK, 0.1), bbx((-10.5, 0, 1.4), (0.6, W * 0.98, 0.7), MDK, 0.1),
              bbx((10.45, 0, 2.6), (0.15, 3.0, 0.9), MDK, 0.04), bx((-10.68, 0, 2.6), (0.06, 1.6, 0.5), YEL)]
    return parts


def phone_repair_kiosk():
    """Phone-repair kiosk (2.4 x 1.8 m): a panelled steel booth on a plinth, a glazed counter with a half-raised slatted
    shutter, a lit fascia with an abstract phone pictogram, phones on a display shelf, a roof overhang, an AC unit, a
    stool; snow on the roof."""
    W, D, H = 7.7, 5.8, 8.6
    parts = [bbx((0, 0, 0.2), (W + 0.4, D + 0.4, 0.4), CONC, 0.05), bbx((0, 0, H / 2 + 0.3), (W, D, H - 0.6), WORN, 0.12),
             bbx((0, 0, H + 0.1), (W + 1.4, D + 1.4, 0.5), MDK, 0.1), bx((0, 0, H + 0.4), (W + 1.2, D + 1.2, 0.1), SNOW)]
    for sx in (-1, 1):
        parts.append(bx((sx * W / 4, -D / 2 - 0.03, H / 2), (0.12, 0.06, H - 1.2), MDK))
        parts.append(bx((sx * (W / 2 + 0.03), 0, H / 2), (0.06, 0.12, H - 1.2), MDK))
    yf = D / 2
    parts += [bx((0, yf + 0.03, 4.4), (W - 1.2, 0.08, 3.6), GLS), bx((0, yf - 0.5, 4.0), (W - 1.4, 0.06, 2.6), GLIT),
              bbx((0, yf + 0.5, 2.5), (W - 0.6, 1.0, 0.25), MET, 0.05)]
    for k in range(6):  # slatted shutter, half up
        parts.append(bx((0, yf + 0.12, 6.0 + k * 0.28), (W - 1.0, 0.1, 0.24), MET))
    parts += [bbx((0, yf + 0.1, 7.6), (W - 0.4, 0.3, 1.2), BLU, 0.05), bbx((-2.4, yf + 0.3, 7.6), (0.55, 0.06, 0.95), WHT, 0.08),
              bx((-2.4, yf + 0.34, 7.6), (0.38, 0.03, 0.7), BLU), bx((0.6, yf + 0.3, 7.75), (3.4, 0.04, 0.28), WHT),
              bx((0.3, yf + 0.3, 7.35), (2.8, 0.04, 0.2), WHT)]
    for k in range(5):  # phones on the display shelf
        x = -2.6 + k * 1.3
        parts += [bbx((x, yf - 0.3, 3.4), (0.55, 0.08, 1.0), MDK, 0.06), bx((x, yf - 0.25, 3.42), (0.45, 0.02, 0.85), GLS if k % 2 else GLIT)]
    parts += [bx((0, yf - 0.4, 2.85), (W - 1.4, 0.5, 0.1), MET)]
    parts += ac_unit("+x", W / 2, 0.6, 6.5)
    parts += [rcy((2.6, yf + 2.0, 1.4), 0.65, 0.15, RUB, 14), rcy((2.6, yf + 2.0, 0.7), 0.1, 1.3, MET, 8)]
    for k in range(3):
        a = 2 * math.pi * k / 3
        parts.append(lmb((2.6, yf + 2.0, 0.9), (2.6 + math.cos(a) * 0.55, yf + 2.0 + math.sin(a) * 0.55, 0.0), 0.04, 0.04, MET, 6))
    return parts


def neon_sign():
    """Rooftop neon sign (4 x 3.4 m): a steel lattice frame on roof feet and a catwalk, a dark backboard, neon tubes
    (w-glow, tier 4 hero) tracing a double border, a star and a wave; snow on the frame top and the catwalk."""
    W, H, Z = 12.8, 10.8, 3.2
    parts = [bbx((0, 0, Z + H / 2), (W, 0.5, H), MDK, 0.08), bx((0, 0, Z + H + 0.1), (W, 0.6, 0.12), SNOW)]
    for x in (-W / 2 + 0.6, -W / 6, W / 6, W / 2 - 0.6):  # lattice legs and braces behind
        parts += [rcy((x, -1.2, (Z + H) / 2), 0.16, Z + H, MET, 8), bx((x, -1.2, 0.08), (0.8, 2.4, 0.16), CONC),
                  lmb((x, -1.2, 0.3), (x, 0.0, Z), 0.1, 0.1, MET, 6), lmb((x, -1.2, 0.3), (x, -2.6, 0.0), 0.08, 0.08, MET, 6)]
    for z in (Z + 1.0, Z + H / 2, Z + H - 1.0):
        parts.append(rcy((0, -1.2, z), 0.1, W, MET, 8, axis="x"))
    for k in range(6):
        x0, x1 = -W / 2 + 0.6 + k * (W - 1.2) / 6, -W / 2 + 0.6 + (k + 1) * (W - 1.2) / 6
        parts.append(lmb((x0, -1.2, Z + 1.0 + (k % 2) * (H - 2)), (x1, -1.2, Z + H - 1.0 - (k % 2) * (H - 2)), 0.07, 0.07, MET, 6))
    parts += [bx((0, 1.5, Z - 0.5), (W, 2.0, 0.12), MET), bx((0, 1.5, Z - 0.42), (W - 0.2, 1.8, 0.04), SNOW),
              rcy((0, 2.4, Z + 0.6), 0.07, W, MET, 6, axis="x")]
    for k in range(5):
        x = -W / 2 + k * W / 4
        parts.append(rcy((x, 2.4, Z), 0.06, 1.2, MET, 6))
    yg = 0.35
    for inset in (0.5, 1.0):
        x0, x1, z0, z1 = -W / 2 + inset, W / 2 - inset, Z + inset, Z + H - inset
        parts += tube([(x0, yg, z0), (x1, yg, z0), (x1, yg, z1), (x0, yg, z1), (x0, yg, z0)], 0.12, GLOW, 8)
    sc, sz = (-2.6, Z + H * 0.6)
    star = []
    for k in range(11):
        a = math.pi / 2 + k * math.pi / 5
        r = 2.6 if k % 2 == 0 else 1.1
        star.append((sc + math.cos(a) * r, yg, sz + math.sin(a) * r))
    parts += tube(star, 0.12, GLOW, 8)
    wave = [(0.8 + k * 0.55, yg, Z + H * 0.55 + 0.9 * math.sin(k * 0.9)) for k in range(9)]
    parts += tube(wave, 0.12, GLOW, 8)
    parts += tube([(0.8, yg, Z + 2.2), (5.2, yg, Z + 2.2)], 0.12, GLOW, 8) + tube([(0.8, yg, Z + 3.2), (4.0, yg, Z + 3.2)], 0.12, GLOW, 8)
    for k in range(8):  # tube clips
        parts.append(bx((-W / 2 + 1.0 + k * (W - 2.0) / 7, 0.3, Z + 0.5), (0.2, 0.3, 0.3), MET))
    return parts


def scaffolding():
    """Tube-and-board scaffold (two 2.5 m bays, three 2 m lifts): standards on base plates, ledgers and transoms,
    zig-zag braces, timber boards with toe boards and guard rails, a ladder, a tarp on the top lift; snow on the boards."""
    B, Lh, D = 8.0, 6.4, 3.8
    n_b, n_l = 2, 3
    parts = []
    xs = [-B * n_b / 2 + k * B for k in range(n_b + 1)]
    top = Lh * n_l + 3.4
    for x in xs:
        for y in (-D / 2, D / 2):
            parts += [rcy((x, y, top / 2), 0.16, top, MET, 8), bx((x, y, 0.04), (0.7, 0.7, 0.08), MDK),
                      bbx((x, y, 0.3), (1.0, 0.3, 0.2), WOOD, 0.02)]
    for l in range(1, n_l + 1):
        z = l * Lh
        for y in (-D / 2, D / 2):
            parts.append(rcy((0, y, z), 0.14, B * n_b + 0.6, MET, 8, axis="x"))
            parts.append(rcy((0, y, z + 3.0), 0.12, B * n_b + 0.6, MET, 8, axis="x"))
        for x in xs:
            parts.append(rcy((x, 0, z), 0.12, D + 0.6, MET, 8, axis="y"))
        for b in range(n_b):
            x0 = xs[b]
            for k in range(5):
                parts.append(bx((x0 + B / 2, -D / 2 + 0.38 + k * 0.76, z + 0.2), (B - 0.2, 0.7, 0.16), WOOD))
            parts += [bx((x0 + B / 2, 0, z + 0.3), (B - 0.4, D - 0.4, 0.04), SNOW),
                      bx((x0 + B / 2, D / 2 + 0.05, z + 0.55), (B - 0.2, 0.08, 0.5), WOOD),
                      rcy((x0 + B / 2, D / 2, z + 1.6), 0.1, B, MET, 8, axis="x")]
    for b in range(n_b):
        for l in range(n_l):
            x0, x1 = xs[b], xs[b + 1]
            za, zb = l * Lh, (l + 1) * Lh
            a, c = ((x0, za), (x1, zb)) if (b + l) % 2 == 0 else ((x1, za), (x0, zb))
            parts.append(lmb((a[0], D / 2 + 0.2, a[1]), (c[0], D / 2 + 0.2, c[1]), 0.1, 0.1, MET, 6))
    for k in range(2):
        parts.append(lmb((xs[0] + 1.0 + k * 1.4, -D / 2 - 0.4, 0.0), (xs[0] + 1.0 + k * 1.4, -D / 2 - 0.4, Lh * n_l + 3.0), 0.1, 0.1, WOOD, 6))
    for k in range(int((Lh * n_l + 3.0) / 1.0)):
        parts.append(bx((xs[0] + 1.7, -D / 2 - 0.4, 0.8 + k * 1.0), (1.4, 0.12, 0.12), WOOD))
    parts += [bx((xs[1] + B / 2, D / 2 + 0.3, Lh * n_l + 1.7), (B - 0.4, 0.06, 3.0), BLU),
              bx((xs[1] + B / 2 - 2.0, D / 2 + 0.34, Lh * n_l + 1.0), (1.6, 0.04, 1.2), WORN)]
    return parts


def skip():
    """Builder's skip (3.7 m): a sloped-end steel body with ribs and lifting lugs, heaped with rubble, planks, a pipe
    offcut and a bag; snow on the heap."""
    L0, L1, Wd, H = 11.6, 7.4, 5.4, 3.8
    prof = [(-L1 / 2, 0.0), (L1 / 2, 0.0), (L0 / 2, H), (-L0 / 2, H)]
    parts = [bev(pg((0, 0, 0), prof, Wd, YEL, "y"), 0.08), bx((0, 0, H - 0.1), (L0 - 0.8, Wd - 0.6, 0.06), MDK)]
    for sy in (-1, 1):
        for k in range(5):
            x = -2.8 + k * 1.4
            parts.append(bx((x, sy * (Wd / 2 + 0.06), H / 2), (0.25, 0.12, H - 0.2), YEL))
        parts.append(bx((0, sy * (Wd / 2 + 0.06), H - 0.15), (L0 - 0.4, 0.14, 0.3), WORN))
        for sx in (-1, 1):
            parts.append(rcy((sx * (L0 / 2 - 0.8), sy * (Wd / 2 + 0.25), H - 0.9), 0.32, 0.3, MDK, 12, axis="y"))
    for sx in (-1, 1):
        parts.append(bx((sx * (L1 / 2 - 0.4), 0, 0.12), (0.6, Wd - 0.2, 0.24), MDK))
    for x, y, r, s in ((-2.5, -0.8, 1.6, CONC), (1.4, 0.6, 1.9, CONC), (-0.2, -1.0, 1.2, WB), (3.4, -1.2, 1.1, KERB), (-3.6, 1.2, 1.0, WB)):
        parts.append(usp((x, y, H - 0.2), r, s, (1.2, 1.0, 0.55), 10, 5))
    parts += [bbx((0.4, 0.3, H + 0.9), (5.5, 0.55, 0.18), WOOD, 0.03, 0.4), bbx((-1.0, -0.6, H + 0.75), (4.8, 0.5, 0.16), WOOD, 0.03, -0.3),
              lmb((-3.0, 1.6, H + 0.4), (1.0, 2.0, H + 1.4), 0.3, 0.3, MDK, 10), bbx((2.8, 1.4, H + 0.6), (1.4, 1.2, 1.0), WHT, 0.25),
              usp((-0.5, 0.0, H + 1.0), 2.4, SNOW, (1.6, 1.1, 0.25), 10, 3)]
    return parts


def water_tank_prop():
    """Rooftop water tank (3.6 m wide, 3.6 m tall on 2.4 m legs): timber staves bound by steel hoops, a conical roof with
    a hatch and finial, a steel stand with cross braces on a roof slab, a ladder, an outlet pipe; snow on the roof."""
    R, Ht, Lg = 5.8, 11.5, 7.7
    z0 = Lg + 0.6
    parts = [bbx((0, 0, 0.3), (2 * R + 3.0, 2 * R + 3.0, 0.6), CONC, 0.06), rcy((0, 0, z0 + Ht / 2), R, Ht, WOOD, 24),
             bbx((0, 0, z0 - 0.3), (2 * R + 0.6, 2 * R + 0.6, 0.6), MDK, 0.05)]
    for k in range(24):  # staves
        a = 2 * math.pi * (k + 0.5) / 24
        parts.append(bx((math.cos(a) * (R + 0.02), math.sin(a) * (R + 0.02), z0 + Ht / 2), (0.08, 0.2, Ht - 0.2), BARK, a))
    for k in range(6):  # hoops
        parts.append(trs((0, 0, z0 + 1.0 + k * (Ht - 2.0) / 5), R + 0.1, 0.12, MDK, 24, 4))
    parts += [rcy((0, 0, z0 + Ht + 1.6), R + 0.5, 3.2, ROOF, 24, r2=0.4), rcy((0, 0, z0 + Ht + 2.2), R * 0.7, 1.6, SNOW, 20, r2=0.6),
              usp((0, 0, z0 + Ht + 3.4), 0.45, MDK, (1, 1, 1), 10, 5), bbx((R * 0.45, 0, z0 + Ht + 1.2), (1.4, 1.4, 0.6), MDK, 0.05)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * R * 0.72, sy * R * 0.72
            parts += [rcy((x, y, (z0 + 0.6) / 2), 0.4, z0 - 0.6, MDK, 12), bx((x, y, 0.65), (1.2, 1.2, 0.1), MDK)]
    for (ax, ay), (bx2, by) in ((((-1, -1), (1, -1))), (((1, -1), (1, 1))), (((1, 1), (-1, 1))), (((-1, 1), (-1, -1)))):
        p0 = (ax * R * 0.72, ay * R * 0.72)
        p1 = (bx2 * R * 0.72, by * R * 0.72)
        parts += [lmb((p0[0], p0[1], 1.0), (p1[0], p1[1], z0 - 0.8), 0.12, 0.12, MDK, 6),
                  lmb((p1[0], p1[1], 1.0), (p0[0], p0[1], z0 - 0.8), 0.12, 0.12, MDK, 6)]
    for sy in (-1, 1):
        parts.append(lmb((R + 0.6, sy * 0.7, 0.6), (R + 0.6, sy * 0.7, z0 + Ht + 0.4), 0.1, 0.1, MET, 6))
    for k in range(int((z0 + Ht) / 1.2)):
        parts.append(rcy((R + 0.6, 0, 1.2 + k * 1.2), 0.07, 1.4, MET, 6, axis="y"))
    parts += tube([(-R * 0.3, 0.0, z0 - 0.6), (-R * 0.3, 0.0, 1.5), (-R - 1.0, 0.0, 1.5), (-R - 1.0, 0.0, 0.6)], 0.3, MDK, 10)
    return parts


def car_sports():
    """Sports coupé (4.4 x 1.9 x 1.25 m): the sedan's construction, low and wide: a long bonnet, a fastback glasshouse,
    one door with a side intake, larger rims, a rear wing; snow on the roof."""
    body = [(-7.0, 0.8), (7.05, 0.8), (7.15, 1.3), (6.9, 2.0), (2.4, 2.4), (-4.6, 2.6), (-6.95, 2.5), (-7.15, 1.5)]
    glass = [(-4.7, 2.45), (2.2, 2.25), (-0.3, 3.65), (-3.0, 3.7)]
    roof = [(-3.1, 3.62), (-0.25, 3.58), (-0.35, 3.84), (-3.0, 3.88)]
    pillars = [[(-4.7, 2.45), (-3.4, 2.45), (-2.85, 3.66), (-3.15, 3.7)]]
    snow = [(-2.8, 3.84), (-0.55, 3.8), (-0.6, 3.9), (-2.75, 3.94)]
    parts = profile_car(body, glass, roof, pillars, (-4.5, 4.4), 6.1, RED, snow, tyre_r=1.02, lights=(1.65, 2.0),
                        arch_h=0.62, well=(1.0, 1.12),
                        seams=(-1.5, 2.0), handles=(-1.0,), mirror_x=1.8, mirror_z=2.75, belt_z=2.3, handle_z=2.05,
                        seam_z=1.55, seam_h=1.3, grille_z=1.15, skirt=7.6, antenna=False, rims=10)
    for sy in (-1, 1):
        parts.append(pg((0, sy * 3.0, 0), [(-3.6, 1.3), (-2.4, 1.3), (-2.6, 2.05), (-3.6, 2.05)], 0.1, MDK, "y"))
    parts += [bbx((-6.6, 0, 3.05), (1.2, 5.6, 0.14), MDK, 0.03)]
    for sy in (-1, 1):
        parts.append(bx((-6.4, sy * 2.0, 2.75), (0.3, 0.12, 0.6), MDK))
    parts += [rcy((-7.2, 1.0, 0.95), 0.2, 0.3, MET, 12, axis="x"), rcy((-7.2, -1.0, 0.95), 0.2, 0.3, MET, 12, axis="x")]
    return parts


def taxi():
    """City taxi: the approved sedan's profile in taxi yellow with a lit roof sign (blank), a chequer band along both
    sides and a fare light; snow on the roof around the sign."""
    W = 5.8
    body = [(-7.45, 0.95), (7.45, 0.95), (7.55, 1.55), (7.35, 2.45), (3.4, 2.85), (-4.4, 2.95), (-7.3, 2.75), (-7.55, 1.75)]
    glass = [(-4.3, 2.85), (3.1, 2.8), (0.9, 4.45), (-3.3, 4.5)]
    roof = [(-3.35, 4.42), (0.95, 4.38), (0.85, 4.62), (-3.25, 4.66)]
    pillars = [[(-1.05, 2.85), (-0.55, 2.85), (-0.8, 4.48), (-1.25, 4.48)],
               [(-4.3, 2.85), (-3.3, 2.85), (-2.95, 4.48), (-3.3, 4.5)]]
    snow = [(-2.9, 4.62), (-1.9, 4.61), (-1.85, 4.68), (-2.85, 4.7)]
    parts = profile_car(body, glass, roof, pillars, (-4.6, 4.5), W, YEL, snow, antenna=False)
    parts += [bbx((-1.2, 0, 5.05), (1.0, 2.8, 0.8), WHT, 0.12), bx((-1.2, 0, 5.05), (1.04, 2.4, 0.4), GLIT),
              bx((-1.2, 0, 4.7), (1.4, 3.0, 0.1), MDK), bx((-1.2, 0, 5.48), (0.9, 2.6, 0.06), SNOW)]
    for sy in (-1, 1):
        for k in range(14):
            for r in range(2):
                if (k + r) % 2 == 0:
                    parts.append(bx((-5.2 + k * 0.8, sy * W * 0.49, 2.05 + r * 0.3), (0.8, 0.04, 0.3), MDK))
    parts.append(bx((2.0, 0, 3.4), (0.4, 0.8, 0.3), RED))
    return parts


def motorbike():
    """Naked roadster motorbike (2.1 m): smooth tyres with spoked rims, front forks and a handlebar with mirrors, a
    round headlight, a teardrop tank, a stepped seat, a finned engine block, an exhaust to a silencer, mudguards, a
    side stand; snow on the seat."""
    parts = []
    for x in (-2.3, 2.4):
        parts += [trs((x, 0, 1.05), 0.85, 0.24, RUB, 16, 4, stand=True), rcy((x, 0, 1.05), 0.68, 0.06, MDK, 10, axis="y"),
                  rcy((x, 0, 1.05), 0.16, 0.5, MET, 8, axis="y")]
        for k in range(5):
            a = 2 * math.pi * k / 5
            parts.append(lmb((x, 0, 1.05), (x + math.cos(a) * 0.62, 0, 1.05 + math.sin(a) * 0.62), 0.03, 0.03, MET, 4))
    parts += [smo(pg((2.4, 0, 0), arc_pts(0.0, 1.05, 1.15, math.pi * 0.15, math.pi * 0.85, 4) + arc_pts(0.0, 1.05, 1.05, math.pi * 0.85, math.pi * 0.15, 4),
                     0.4, MDK, "y")),
              smo(pg((-2.3, 0, 0), arc_pts(0.0, 1.05, 1.15, math.pi * 0.35, math.pi * 0.95, 4) + arc_pts(0.0, 1.05, 1.05, math.pi * 0.95, math.pi * 0.35, 4),
                     0.4, MDK, "y"))]
    for sy in (-1, 1):
        parts += [lmb((2.4, sy * 0.25, 1.05), (1.6, sy * 0.25, 3.3), 0.1, 0.09, MET, 6)]
    parts += [lmb((1.6, -1.1, 3.6), (1.6, 1.1, 3.6), 0.06, 0.06, MDK, 6), lmb((1.6, 0, 3.3), (1.6, 0, 3.6), 0.08, 0.08, MDK, 6),
              usp((2.0, 0, 3.1), 0.38, MET, (0.8, 1, 1), 10, 5), rcy((2.32, 0, 3.1), 0.3, 0.05, GLIT, 12, axis="x"),
              usp((0.6, 0, 2.95), 0.75, RED, (1.4, 0.85, 0.6), 12, 6), bbx((-1.0, 0, 2.7), (1.9, 0.9, 0.3), MDK, 0.1),
              bbx((-2.0, 0, 2.95), (0.9, 0.8, 0.3), MDK, 0.1), bx((-1.0, 0, 2.88), (1.7, 0.8, 0.04), SNOW),
              lmb((1.6, 0, 3.0), (-1.8, 0, 2.5), 0.12, 0.12, MDK, 6), lmb((-1.8, 0, 2.5), (-2.3, 0, 1.05), 0.1, 0.1, MDK, 6),
              lmb((0.0, 0, 1.0), (-2.3, 0, 1.05), 0.08, 0.08, MDK, 6), lmb((1.6, 0, 3.0), (0.6, 0, 1.0), 0.12, 0.12, MDK, 6),
              bbx((0.3, 0, 1.55), (1.3, 0.8, 1.1), MDK, 0.08)]
    for k in range(3):
        parts.append(bx((0.3, 0, 1.3 + k * 0.28), (1.5, 1.0, 0.06), MET))
    for sy in (-1, 1):
        parts += [lmb((1.6, sy * 1.05, 3.6), (1.4, sy * 1.2, 4.2), 0.03, 0.03, MDK, 6), rcy((1.4, sy * 1.2, 4.25), 0.18, 0.06, MET, 8, axis="x")]
    parts += tube([(0.9, 0.4, 1.4), (0.3, 0.55, 0.75), (-1.2, 0.6, 0.85), (-2.6, 0.6, 1.5)], 0.1, MET, 8, joints=False)
    parts += [rcy((-2.4, 0.6, 1.45), 0.2, 1.2, MET, 12, r2=0.17, axis="x"), lmb((-0.4, -0.35, 1.1), (-0.8, -0.9, 0.0), 0.04, 0.04, MDK, 6),
              bbx((-2.6, 0, 2.55), (0.3, 0.6, 0.2), RED, 0.03)]
    return parts


RECIPES.update({
    "ck_traffic_lights": traffic_lights,
    "ck_parking_meter": parking_meter,
    "ck_scooter_dock": scooter_dock,
    "ck_food_truck": food_truck,
    "ck_phone_repair_kiosk": phone_repair_kiosk,
    "ck_neon_sign": neon_sign,
    "ck_scaffolding": scaffolding,
    "ck_skip": skip,
    "ck_water_tank": water_tank_prop,
    "ck_car_sports": car_sports,
    "ck_taxi": taxi,
    "ck_motorbike": motorbike,
})

STAGE_B_PROPS.update(k for k in RECIPES if not k.startswith(BUILDINGS) and k not in (
    "ck_car_sedan", "ck_tree_oak", "ck_street_lamp_double", "ck_bin_street", "dt_fire_hydrant"))
