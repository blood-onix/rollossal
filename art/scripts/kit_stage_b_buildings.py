# Stage B buildings of the tween-appeal rework (013 Phase 9 T076; owner go on the pilot 2026-11-07). Loaded by
# art/scripts/kit_rework.py (load_stage_b) into its namespace, so the constructors (bbx, rcy, usp, lmb, bx, pg, raw), the
# facade helpers (on_wall, window, drainpipe, icicles, gable_roof) and the swatch names come from there.
#
# Same rules as the approved pilot (style bible sections 2, 3, 9; research R-18): real storeys (3 m housing = 9.6 studs
# with a sill plinth, 4 m shop ground floor = 13), real doors (6.7 x 2.9), muted walls and roofs, accents only on doors,
# signs and awnings, every variant with its own silhouette feature, snow as geometry on ridges, sills, copings and
# canopies (never a blanket over a roof), and 60 % or more of the tier ceiling where it is seen.
# Shops and shop rows (atlas "fronts") use only fronts cells: fx_* strips and their sign cells.
#
# Owner defaults recorded in docs/release-candidate.md: mid-rises and towers keep real storeys (the approved pilot
# tower), so the "8" and "10" in two mid-rise ids are names, not floor counts.

import math


# ---------------------------------------------------------------------------------------------- shared helpers
def lit_of(i, j, seed=0, every=4):
    return (i * 7 + j * 3 + seed) % every == 0


def win_rows(n, p, us, zs, w, h, glass=None, lit=None, frame=None, every=4, seed=0, simple=False, mull=1,
             transom=False, snow=None):
    glass, lit, frame, snow = glass or GLS, lit or GLIT, frame or TRIM, snow or SNOW
    parts = []
    for i, z in enumerate(zs):
        for j, u in enumerate(us):
            g = lit if (not simple and lit_of(i, j, seed, every)) else glass
            parts += window(n, p, u, z, w, h, g, frame, snow=snow, mull=mull, transom=transom, simple=simple)
    return parts


def spread(span, cols, margin=0.0):
    pitch = (span - 2 * margin) / cols
    return [-span / 2 + margin + pitch * (c + 0.5) for c in range(cols)]


def split_body(W, D, GF, top, upper, ground, cx=0.0, cy2=0.0, bev_u=0.3, bev_g=0.1):
    """Upper floors and ground floor as two stacked boxes (no coplanar faces, so ground-floor doors and glass on the
    wall plane stay visible)."""
    return [bbx((cx, cy2, (GF + top) / 2), (W, D, top - GF), upper, bev_u), bbx((cx, cy2, GF / 2), (W, D, GF), ground, bev_g)]


def gutter_x(x0, x1, y, z, n_ice, s=MDK, ice=ICE):
    return [rcy(((x0 + x1) / 2, y, z), 0.24, x1 - x0, s, 8, axis="x")] + icicles(x0 + 0.8, x1 - 0.8, y, z - 0.25, n_ice, ice)


def gutter_y(y0, y1, x, z, n_ice, s=MDK):
    out = [rcy((x, (y0 + y1) / 2, z), 0.24, y1 - y0, s, 8, axis="y")]
    for k in range(n_ice):
        y = y0 + 0.8 + (y1 - y0 - 1.6) * (k + 0.5) / n_ice
        length = 0.55 + 0.45 * ((k * 7) % 5) / 4
        out.append(rcy((x, y, z - 0.25 - length / 2), 0.11, length, ICE, 6, r2=0.0))
    return out


def hip_roof(w, d, z, rise, s, over=1.0, cx=0.0, cy_=0.0, snow=SNOW, fascia=TRIM):
    """Hip roof with eaves overhang: two trapezoid slopes and two triangular hips, a fascia board and a snow ridge."""
    a, b = w / 2 + over, d / 2 + over
    if a >= b:
        i = min(b, a - 0.5)
        verts = [(-a, -b, 0), (a, -b, 0), (a, b, 0), (-a, b, 0), (-a + i, 0, rise), (a - i, 0, rise)]
        faces = [(0, 1, 5, 4), (2, 3, 4, 5), (1, 2, 5), (3, 0, 4), (3, 2, 1, 0)]
        ridge = (2 * (a - i) + 0.6, 1.2)
    else:
        i = min(a, b - 0.5)
        verts = [(-a, -b, 0), (a, -b, 0), (a, b, 0), (-a, b, 0), (0, -b + i, rise), (0, b - i, rise)]
        faces = [(1, 2, 5, 4), (3, 0, 4, 5), (0, 1, 4), (2, 3, 5), (3, 2, 1, 0)]
        ridge = (1.2, 2 * (b - i) + 0.6)
    verts = [(x + cx, y + cy_, zz + z) for x, y, zz in verts]
    parts = [raw(verts, faces, s), bx((cx, cy_, z + rise + 0.05), (ridge[0], ridge[1], 0.3), snow)]
    parts += [bx((cx, cy_ + sy * (b - 0.1), z - 0.2), (2 * a, 0.24, 0.55), fascia) for sy in (-1, 1)]
    parts += [bx((cx + sx * (a - 0.1), cy_, z - 0.2), (0.24, 2 * b, 0.55), fascia) for sx in (-1, 1)]
    return parts


def mono_roof(w, d, z, rise, s, over=0.8, cx=0.0, cy_=0.0, snow=SNOW):
    """Mono-pitch roof rising toward -y, with a snow line on the high edge."""
    a, b = w / 2 + over, d / 2 + over
    pts = [(-b, 0.0), (b, 0.0), (b, 0.45), (-b, rise + 0.45), (-b, rise)]
    parts = [pg((cx, cy_, z), [(-y, zz) for y, zz in pts], 2 * a, s, "y", math.pi / 2)]
    parts.append(bx((cx, cy_ - b + 0.4, z + rise + 0.55), (2 * a, 0.9, 0.16), snow))
    return parts


def chimney(x, y, z0, h, wall, cap=CONC, pots=2, w=2.0, d=1.5, snow=SNOW, pot=ROOF):
    parts = [bbx((x, y, z0 + h / 2), (w, d, h), wall, 0.08), bbx((x, y, z0 + h + 0.22), (w + 0.5, d + 0.5, 0.44), cap, 0.05),
             bx((x, y, z0 + h + 0.48), (w + 0.3, d + 0.3, 0.1), snow)]
    for k in range(pots):
        px = x + (k - (pots - 1) / 2) * 0.85
        parts.append(rcy((px, y, z0 + h + 0.9), 0.3, 0.8, pot, 10, r2=0.24))
    return parts


def door_unit(n, p, u, z0, wall_trim=TRIM, door=DOOR, canopy=ROOFB, steps=2, fan=True):
    """Front door 6.7 x 2.9 with a surround, fanlight and a canopy with a snow line; steps down to the path."""
    parts = [on_wall(n, p, u, z0 + 3.35, 2.9, 0.12, 6.7, 0.0, door),
             on_wall(n, p, u - 1.65, z0 + 3.5, 0.35, 0.34, 7.2, 0.17, wall_trim),
             on_wall(n, p, u + 1.65, z0 + 3.5, 0.35, 0.34, 7.2, 0.17, wall_trim),
             on_wall(n, p, u, z0 + 7.1, 3.7, 0.4, 0.4, 0.2, wall_trim),
             on_wall(n, p, u, z0 + 2.9, 0.5, 0.1, 0.12, 0.08, MET)]
    if fan:
        parts.append(on_wall(n, p, u, z0 + 6.2, 2.0, 0.08, 0.7, 0.08, GLIT))
    if canopy:
        parts += [on_wall(n, p, u, z0 + 7.9, 4.4, 2.0, 0.3, 1.0, canopy, 0.06),
                  on_wall(n, p, u, z0 + 8.1, 4.2, 1.8, 0.12, 1.0, SNOW)]
    for k in range(steps):
        top = z0 - 0.3 * k
        parts.append(on_wall(n, p, u, top / 2, 3.8, 0.9, max(top, 0.2), 0.45 + 0.9 * k, CONC, 0.04))
    return parts


def low_wall(x0, x1, y, wall=WB, rail=True, h=2.0):
    mid, span = (x0 + x1) / 2, x1 - x0
    parts = [bbx((mid, y, h / 2), (span, 0.9, h), wall, 0.06), bx((mid, y, h + 0.08), (span + 0.1, 1.1, 0.16), CONC),
             bx((mid, y, h + 0.22), (span, 0.95, 0.12), SNOW)]
    if rail:
        parts.append(bx((mid, y, h + 1.55), (span, 0.12, 0.14), WORN))
        for k in range(int(span / 1.6)):
            parts.append(bx((x0 + 0.8 + k * 1.6, y, h + 0.95), (0.12, 0.12, 1.5), WORN))
    return parts


def shrub(x, y, r, s=LEAF):
    return [usp((x, y, r * 0.85), r, s, (1.1, 1.0, 0.9), 10, 6)]


def ac_unit(n, p, u, z, s=WHT, grille=MDK):
    return [on_wall(n, p, u, z, 2.0, 1.4, 1.4, 0.7, s, 0.06), on_wall(n, p, u, z, 1.2, 0.06, 1.0, 1.42, grille)]


def water_tank(x, y, z, r=2.4, h=4.0, legs=4.4, wood=WOOD, steel=MDK, rings=True, snow=SNOW):
    parts = [rcy((x, y, z + legs + h / 2), r, h, wood, 16), rcy((x, y, z + legs + h + 0.45), r + 0.15, 0.9, steel, 16, r2=0.25),
             rcy((x, y, z + legs + h + 0.95), r * 0.5, 0.2, snow, 12, r2=0.15),
             bx((x, y, z + legs - 0.1), (2 * r * 0.8, 2 * r * 0.8, 0.25), steel)]
    for k in range(4):
        parts.append(bx((x + (1 if k % 2 else -1) * r * 0.66, y + (1 if k // 2 else -1) * r * 0.66, z + legs / 2),
                        (0.3, 0.3, legs), steel))
    for k in range(int(h / 1.2) if rings else 0):
        parts.append(rcy((x, y, z + legs + 0.6 + k * 1.2), r + 0.06, 0.12, steel, 16))
    return parts


# ---------------------------------------------------------------------------------------------- houses (tier 4)
def house_semi_garage():
    """Two-storey render house with a hipped slate roof and a flat-roofed garage wing on the right: up-and-over door,
    driveway, a box bay window with its own lead roof, porch canopy, chimney, gutters and a hedge."""
    W, D, ST, PL = 15.0, 12.5, 8.8, 0.8
    H = ST * 2
    fy, by = D / 2, -D / 2
    parts = [bbx((0, 0, PL / 2), (W + 0.5, D + 0.5, PL), CONC, 0.08), bbx((0, 0, PL + H / 2), (W, D, H), WA, 0.25),
             bx((0, 0, PL + ST), (W + 0.3, D + 0.3, 0.4), TRIM)]
    parts += hip_roof(W, D, PL + H, 5.4, ROOFB, 1.0)
    # garage wing, 3.2 m wide
    GW, GD, GH = 10.4, 14.5, 9.6
    gx = W / 2 + GW / 2
    parts += [bbx((gx, -1.0, GH / 2), (GW, GD, GH), WA, 0.2), bbx((gx, -1.0, GH + 0.35), (GW + 0.6, GD + 0.6, 0.7), CONC, 0.06),
              bx((gx, -1.0, GH + 0.76), (GW + 0.4, GD + 0.4, 0.12), SNOW)]
    gfy = -1.0 + GD / 2
    parts += [on_wall("+y", gfy, gx, 3.4, 7.8, 0.12, 6.8, -0.12, WORN),
              on_wall("+y", gfy, gx, 7.05, 8.6, 0.4, 0.5, 0.2, TRIM)]
    for k in range(4):
        parts.append(on_wall("+y", gfy, gx, 1.0 + 1.6 * k, 7.6, 0.08, 0.1, -0.04, MDK))
    parts += [on_wall("+y", gfy, gx + 2.8, 2.6, 0.5, 0.1, 0.25, 0.04, MET),
              bx((gx, gfy + 5.0, 0.06), (8.4, 10.0, 0.12), STAIN)]  # driveway
    parts += window("+x", W / 2 + GW, 1.0, 5.0, 3.0, 2.4, simple=True)
    # box bay on the ground floor, left
    bay_x = -3.6
    parts += [bbx((bay_x, fy + 1.1, PL + 3.6), (6.4, 2.2, 6.4), WA, 0.12),
              bbx((bay_x, fy + 1.2, PL + 7.05), (7.0, 2.6, 0.5), ROOFB, 0.1), bx((bay_x, fy + 1.2, PL + 7.36), (6.8, 2.4, 0.12), SNOW)]
    parts += window("+y", fy + 2.2, bay_x, PL + 3.8, 4.6, 4.2, mull=2, transom=True)
    parts += window("+x", bay_x + 3.2, -(fy + 1.1), PL + 3.8, 1.2, 4.2, simple=True)
    parts += window("-x", bay_x - 3.2, fy + 1.1, PL + 3.8, 1.2, 4.2, simple=True)
    parts += door_unit("+y", fy, 3.8, PL)
    parts += win_rows("+y", fy, [-3.6, 3.8], [PL + ST * 1.5], 3.4, 4.2, seed=1)
    parts += win_rows("-y", by, spread(W, 3), [PL + ST * 0.5, PL + ST * 1.5], 3.0, 4.2, simple=True)
    parts += win_rows("-x", -W / 2, [0.0], [PL + ST * 0.5, PL + ST * 1.5], 2.6, 4.0, simple=True)
    parts += chimney(-W / 2 + 2.2, -1.0, PL + H, 7.2, WA)
    parts += gutter_x(-W / 2 - 0.8, W / 2 + 0.8, fy + 1.0, PL + H - 0.45, 6) + gutter_x(-W / 2 - 0.8, W / 2 + 0.8, by - 1.0, PL + H - 0.45, 3)
    parts += drainpipe(-W / 2 + 0.3, fy + 0.95, PL, PL + H - 0.4) + drainpipe(W / 2 - 0.4, by - 0.95, PL, PL + H - 0.4)
    # front garden: lawn, path, low hedge with a gap
    parts += [bx((-2.5, fy + 4.0, 0.08), (W - 5.0, 8.0, 0.16), GRASS), bx((3.8, fy + 4.0, 0.06), (3.0, 8.0, 0.12), STAIN)]
    for x0, x1 in ((-W / 2, 2.0), ):
        n = int((x1 - x0) / 1.6)
        for k in range(n):
            parts.append(usp((x0 + 0.8 + k * 1.6, fy + 7.6, 1.1), 1.0, LEAF if k % 2 else LDK, (1.0, 0.8, 1.1), 8, 5))
    return parts


def house_bungalow():
    """Single-storey brick bungalow, wide and low under a big hipped roof, with a timber veranda across the front
    (posts, rail, steps), a front gable over the entrance, two chimneys, gutters, bins by the side wall."""
    W, D, ST, PL = 22.0, 13.0, 9.2, 1.2
    fy, by = D / 2, -D / 2
    parts = [bbx((0, 0, PL / 2), (W + 0.5, D + 0.5, PL), CONC, 0.08), bbx((0, 0, PL + ST / 2), (W, D, ST), WB, 0.25),
             bx((0, 0, PL + 1.2), (W + 0.2, D + 0.2, 0.3), CONC)]
    parts += hip_roof(W, D, PL + ST, 6.2, ROOF, 1.2)
    # front gable over the entrance, ridge along y
    parts += gable_roof(7.0, 4.0, PL + ST, 4.6, ROOF, 0.7, False, 0.0, fy + 1.0)
    parts.append(bx((0, fy + 3.1, PL + ST + 1.6), (5.6, 0.3, 2.4), WOOD))
    parts += door_unit("+y", fy, 0.0, PL, canopy=None, steps=0)
    parts += win_rows("+y", fy, [-7.0, 7.0], [PL + ST * 0.52], 4.6, 4.6, mull=2, seed=1)
    parts += win_rows("-y", by, spread(W, 4), [PL + ST * 0.52], 3.2, 4.2, simple=True)
    parts += win_rows("+x", W / 2, [-2.5, 2.5], [PL + ST * 0.52], 2.8, 4.2, simple=True)
    parts += win_rows("-x", -W / 2, [0.0], [PL + ST * 0.52], 2.8, 4.2, simple=True)
    # veranda: deck, posts, beam, rails, steps
    vy = fy + 2.0
    parts += [bbx((0, vy, PL - 0.2), (W + 1.0, 4.0, 0.4), WOOD, 0.05), bx((0, vy + 1.6, PL + ST - 0.6), (W + 1.0, 0.5, 0.6), WOOD)]
    for k in range(7):
        x = -W / 2 + k * W / 6
        parts += [rcy((x, vy + 1.6, PL + (ST - 0.6) / 2), 0.25, ST - 0.6, WHT, 10), rcy((x, vy + 1.6, PL + 0.2), 0.36, 0.4, WHT, 10)]
    for x0, x1 in ((-W / 2, -2.2), (2.2, W / 2)):
        parts += [bx(((x0 + x1) / 2, vy + 1.75, PL + 2.6), (x1 - x0, 0.2, 0.2), WHT),
                  bx(((x0 + x1) / 2, vy + 1.75, PL + 2.76), (x1 - x0, 0.22, 0.1), SNOW)]
        for k in range(int((x1 - x0) / 0.9)):
            parts.append(bx((x0 + 0.45 + k * 0.9, vy + 1.75, PL + 1.5), (0.12, 0.12, 2.1), WHT))
    for k in range(2):
        parts.append(bbx((0, vy + 2.4 + 0.9 * k, (PL - 0.4 * (k + 1)) / 2 + 0.1), (4.0, 0.9, PL - 0.4 * (k + 1) + 0.2), CONC, 0.04))
    parts += chimney(-W / 2 + 4.0, -1.5, PL + ST + 2.0, 5.2, WB) + chimney(W / 2 - 4.0, -1.5, PL + ST + 2.0, 5.2, WB, pots=1)
    parts += gutter_x(-W / 2 - 1.0, W / 2 + 1.0, by - 1.2, PL + ST - 0.45, 4) + gutter_y(-D / 2 - 1, D / 2 + 1, W / 2 + 1.2, PL + ST - 0.45, 3)
    parts += drainpipe(W / 2 - 0.3, by - 1.15, PL, PL + ST - 0.4)
    # wheelie bins by the right wall and a front lawn
    for k, s in enumerate((MDK, LDK)):
        parts += [bbx((W / 2 + 1.6, -3.0 + 2.4 * k, 1.8), (1.9, 2.0, 3.4), s, 0.1), bbx((W / 2 + 1.6, -3.0 + 2.4 * k, 3.6), (2.1, 2.2, 0.25), s, 0.05),
                  bx((W / 2 + 1.6, -3.0 + 2.4 * k, 3.78), (2.0, 2.1, 0.1), SNOW)]
    parts += [bx((0, fy + 7.5, 0.08), (W, 3.0, 0.16), GRASS)] + shrub(-8.0, fy + 7.0, 1.4) + shrub(8.5, fy + 7.0, 1.2, LDK)
    return parts


def house_corner_bay():
    """Two-storey brick house with a three-storey octagonal corner turret under a conical roof (the silhouette feature),
    side-gable slate roof, dormer, porch, chimney and a front railing."""
    W, D, ST, PL = 15.0, 12.0, 8.8, 0.8
    H = ST * 2
    fy, by = D / 2, -D / 2
    parts = [bbx((0, 0, PL / 2), (W + 0.5, D + 0.5, PL), CONC, 0.08), bbx((0, 0, PL + H / 2), (W, D, H), WB, 0.25),
             bx((0, 0, PL + ST), (W + 0.3, D + 0.3, 0.4), TRIM)]
    parts += gable_roof(W, D, PL + H, 5.6, ROOFB, 0.9, True)
    # turret on the front-left corner
    tx, ty, tr = -W / 2 + 0.6, fy - 0.6, 3.4
    th = H + 2.6
    parts += [rcy((tx, ty, PL + th / 2), tr, th, WB, 8, yaw=math.pi / 8), rcy((tx, ty, PL + ST), tr + 0.2, 0.4, TRIM, 8, yaw=math.pi / 8),
              rcy((tx, ty, PL + th + 0.2), tr + 0.5, 0.45, TRIM, 8, yaw=math.pi / 8),
              rcy((tx, ty, PL + th + 2.9), tr + 0.6, 5.0, ROOFB, 8, r2=0.0, yaw=math.pi / 8),
              rcy((tx, ty, PL + th + 0.8), tr + 0.3, 0.8, SNOW, 8, r2=tr - 0.4, yaw=math.pi / 8),
              rcy((tx, ty, PL + th + 5.9), 0.12, 1.2, MDK, 6), usp((tx, ty, PL + th + 5.5), 0.3, MDK, (1, 1, 1), 8, 5)]
    for k in range(1, 6):  # one window per street-facing facet and storey (facet normals at multiples of 45 degrees)
        a = k * math.pi / 4
        ap = tr * math.cos(math.pi / 8)
        cx, cy2 = tx + math.cos(a) * ap, ty + math.sin(a) * ap
        for f, (z, h) in enumerate(((PL + ST * 0.5, 4.2), (PL + ST * 1.5, 4.0), (PL + H + 1.3, 1.8))):
            parts += [bx((cx, cy2, z), (1.9, 0.3, h), GLIT if (k + f) % 3 == 0 else GLS, a + math.pi / 2),
                      bx((cx + math.cos(a) * 0.12, cy2 + math.sin(a) * 0.12, z - h / 2 - 0.15), (2.3, 0.5, 0.25), TRIM, a + math.pi / 2),
                      bx((cx + math.cos(a) * 0.15, cy2 + math.sin(a) * 0.15, z - h / 2 + 0.0), (2.1, 0.4, 0.1), SNOW, a + math.pi / 2),
                      bx((cx + math.cos(a) * 0.1, cy2 + math.sin(a) * 0.1, z + h / 2 + 0.15), (2.3, 0.4, 0.3), TRIM, a + math.pi / 2)]
    parts += door_unit("+y", fy, 3.0, PL)
    parts += win_rows("+y", fy, [3.0], [PL + ST * 1.5], 2.6, 4.2, seed=2)
    parts += win_rows("+y", fy, [-0.6], [PL + ST * 0.5, PL + ST * 1.5], 2.0, 4.2, seed=1)
    parts += win_rows("+x", W / 2, [-2.4, 2.4], [PL + ST * 0.5, PL + ST * 1.5], 2.8, 4.2, seed=3)
    parts += win_rows("-y", by, spread(W, 3), [PL + ST * 0.5, PL + ST * 1.5], 2.8, 4.0, simple=True)
    # dormer on the rear slope
    parts += [bbx((3.0, by + 3.0, PL + H + 2.0), (3.6, 3.0, 3.6), WB, 0.08)] + gable_roof(3.6, 3.0, PL + H + 3.8, 1.6, ROOFB, 0.3, False, 3.0, by + 3.0)
    parts += window("-y", by + 1.5, -3.0, PL + H + 2.0, 2.2, 2.4, simple=True)
    parts += chimney(W / 2 - 1.6, 0.0, PL + H, 8.0, WB)
    parts += gutter_x(-W / 2 + 3.0, W / 2 + 0.9, fy + 0.9, PL + H - 0.45, 4) + gutter_x(-W / 2 - 0.9, W / 2 + 0.9, by - 0.9, PL + H - 0.45, 3)
    parts += drainpipe(W / 2 - 0.3, fy + 0.85, PL, PL + H - 0.4)
    parts += low_wall(-W / 2 - 3.0, 1.0, fy + 6.0, WB) + low_wall(5.0, W / 2, fy + 6.0, WB)
    parts += [bx((0, fy + 3.0, 0.08), (W, 6.0, 0.16), GRASS), bx((3.0, fy + 3.0, 0.1), (3.0, 6.0, 0.12), STAIN)]
    parts += shrub(-2.0, fy + 2.5, 1.3, LDK) + shrub(W / 2 - 1.4, fy + 2.4, 1.2)
    return parts


def house_terrace_pair():
    """Two mirrored terraced houses under one slate roof: the left in brick, the right painted render, each with a
    canted bay, door with fanlight, a dormer; a shared chimney stack on the party wall, low walls with gates."""
    W, D, ST, PL = 24.0, 11.0, 8.6, 0.8
    H = ST * 2
    fy, by = D / 2, -D / 2
    half = W / 2
    parts = [bbx((0, 0, PL / 2), (W + 0.5, D + 0.5, PL), CONC, 0.08),
             bbx((-half / 2, 0, PL + H / 2), (half, D, H), WB, 0.2), bbx((half / 2, 0, PL + H / 2), (half, D, H), WA, 0.2),
             bx((0, 0, PL + ST), (W + 0.3, D + 0.3, 0.4), TRIM), bx((0, fy + 0.2, PL + H / 2), (0.6, 0.5, H), CONC)]
    parts += gable_roof(W, D, PL + H, 5.2, ROOFB, 0.8, True)
    for side in (-1, 1):
        wall = WB if side < 0 else WA
        bay_x = side * (half - 3.4)
        door_x = side * 2.4
        # canted bay: front panel plus two angled panels, a lead roof with snow
        parts += [bbx((bay_x, fy + 1.0, PL + 3.6), (4.2, 2.0, 7.2), wall, 0.1)]
        for sx in (-1, 1):
            parts.append(bx((bay_x + sx * 2.6, fy + 0.55, PL + 3.6), (1.6, 0.4, 7.2), wall, sx * 0.6))
        parts += [bbx((bay_x, fy + 1.0, PL + 7.4), (6.4, 2.6, 0.5), ROOFB, 0.08), bx((bay_x, fy + 1.0, PL + 7.7), (6.2, 2.4, 0.12), SNOW)]
        parts += window("+y", fy + 2.0, bay_x, PL + 3.8, 3.4, 4.4, mull=1, transom=True)
        parts += door_unit("+y", fy, door_x, PL, canopy=None, steps=1)
        parts += win_rows("+y", fy, [bay_x, door_x], [PL + ST * 1.5], 2.6, 4.2, seed=2 + side)
        parts += win_rows("-y", by, [side * 3.0, side * (half - 3.0)], [PL + ST * 0.5, PL + ST * 1.5], 2.6, 4.0, simple=True)
        # dormer on the front slope
        dx = side * 6.0
        parts += [bbx((dx, fy - 1.6, PL + H + 1.6), (3.4, 2.6, 3.2), wall, 0.06)] + gable_roof(3.4, 2.6, PL + H + 3.2, 1.5, ROOFB, 0.3, False, dx, fy - 1.6)
        parts += window("+y", fy - 0.3, dx, PL + H + 1.6, 2.0, 2.2, simple=True)
        parts += low_wall(side * 1.0 if side > 0 else -half, side * half if side > 0 else -1.0, fy + 5.5, wall,
                          rail=side < 0, h=1.6)
        parts += [bx((side * half / 2, fy + 2.75, 0.08), (half, 5.5, 0.16), GRASS if side < 0 else STAIN)]
        parts += [bx((door_x, fy + 2.75, 0.1), (3.0, 5.5, 0.12), CONC)]
    parts += chimney(0.0, 0.0, PL + H + 2.6, 4.4, WB, pots=4, w=3.6, d=1.6)
    parts += gutter_x(-half - 0.8, half + 0.8, fy + 0.8, PL + H - 0.45, 7) + gutter_x(-half - 0.8, half + 0.8, by - 0.8, PL + H - 0.45, 4)
    parts += drainpipe(0.6, fy + 0.75, PL, PL + H - 0.4) + drainpipe(-half + 0.3, by - 0.75, PL, PL + H - 0.4)
    parts += shrub(-half + 1.5, fy + 2.6, 1.2) + shrub(half - 1.5, fy + 2.4, 1.0, LDK)
    return parts


def house_split_level():
    """Modern split-level house: a timber-clad upper volume half a storey above a rendered lower one, mono-pitch and flat
    roofs, a big corner window, a steel balcony, a carport on slim posts and a gravel drive."""
    ST, PL = 9.2, 0.6
    parts = []
    # lower volume (render), flat roof with coping
    LW, LD = 13.0, 12.0
    lx = -4.5
    parts += [bbx((lx, 0, PL / 2), (LW + 0.4, LD + 0.4, PL), CONC, 0.06), bbx((lx, 0, PL + ST / 2), (LW, LD, ST), WA, 0.2),
              bbx((lx, 0, PL + ST + 0.35), (LW + 0.6, LD + 0.6, 0.7), CONC, 0.06), bx((lx, 0, PL + ST + 0.76), (LW + 0.4, LD + 0.4, 0.12), SNOW)]
    # upper volume (timber), offset half a storey, mono-pitch roof
    UW, UD = 12.0, 11.0
    ux, uz = 6.0, PL + ST / 2
    parts += [bbx((ux, -0.5, uz / 2), (UW, UD, uz), CONC, 0.1), bbx((ux, -0.5, uz + ST * 0.75), (UW, UD, ST * 1.5), WOOD, 0.15)]
    parts += mono_roof(UW, UD, uz + ST * 1.5, 3.2, ROOFB, 0.8, ux, -0.5)
    for k in range(17):  # vertical cladding battens on the front
        parts.append(on_wall("+y", 5.0, ux - UW / 2 + 0.5 + k * 0.69, uz + ST * 0.75, 0.14, 0.14, ST * 1.5, 0.07, BARK))
    # windows: lower long window with a lit pane, upper corner window, rear
    parts += window("+y", LD / 2, lx - 1.0, PL + ST * 0.5, 7.4, 4.6, GLIT, MDK, mull=3)
    parts += [on_wall("+y", 5.0, ux + 2.6, uz + ST * 0.9, 6.0, 0.16, 6.0, 0.1, GLS),
              on_wall("+x", ux + UW / 2, -1.2, uz + ST * 0.9, 4.6, 0.16, 6.0, 0.1, GLS),
              on_wall("+y", 5.0, ux + 2.6, uz + ST * 0.9 + 3.2, 6.6, 0.5, 0.4, 0.2, MDK),
              on_wall("+y", 5.0, ux + 2.6, uz + ST * 0.9 - 3.2, 6.6, 0.6, 0.35, 0.3, MDK),
              on_wall("+y", 5.0, ux + 2.6, uz + ST * 0.9 - 2.9, 6.4, 0.5, 0.12, 0.35, SNOW)]
    parts += win_rows("-y", -LD / 2, [lx - 3.0, lx + 3.0], [PL + ST * 0.5], 3.2, 4.0, simple=True)
    parts += win_rows("-y", -0.5 - UD / 2, [ux - 2.5, ux + 2.5], [uz + ST * 0.8], 3.0, 4.0, simple=True)
    # entrance: door in the lower volume under a cantilevered canopy
    parts += door_unit("+y", LD / 2, lx + 4.2, PL, wall_trim=MDK, canopy=CONC, steps=1, fan=False)
    # balcony off the upper volume, -x side over the lower roof
    parts += [bx((ux - UW / 2 - 0.1, -0.5, uz + ST * 0.5), (0.2, 4.0, 0.2), MET)]
    for k in range(6):
        parts.append(bx((lx + LW / 2 - 4.5 + k * 0.9, LD / 2 - 0.3, PL + ST + 1.6), (0.1, 0.1, 1.8), MET))
    parts += [bx((lx + LW / 2 - 2.25, LD / 2 - 0.3, PL + ST + 2.5), (4.8, 0.14, 0.14), MET),
              on_wall("-x", ux - UW / 2, 0.5, PL + ST + 3.5, 2.9, 0.12, 6.4, 0.05, DOOR)]
    # carport in front of the upper volume: slim posts, thin roof with snow, a gravel drive
    cy0 = 5.0 + 6.4
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.append(rcy((ux + sx * 4.6, cy0 + sy * 5.4, 4.2), 0.18, 8.4, MET, 8))
    parts += [bbx((ux, cy0, 8.55), (10.4, 12.4, 0.4), MDK, 0.05), bx((ux, cy0, 8.82), (10.2, 12.2, 0.12), SNOW),
              bx((ux, cy0, 0.05), (9.6, 12.8, 0.1), STAIN)]
    parts += drainpipe(lx - LW / 2 + 0.3, LD / 2 + 0.3, PL, PL + ST) + drainpipe(ux + UW / 2 - 0.3, -0.5 - UD / 2 - 0.3, uz, uz + ST * 1.5)
    parts += [bx((lx, LD / 2 + 3.5, 0.08), (LW, 7.0, 0.16), GRASS)] + shrub(lx - 4.5, LD / 2 + 2.5, 1.4) + shrub(lx - 1.8, LD / 2 + 2.2, 0.9, LDK)
    for k in range(5):  # stepping stones to the door
        parts.append(bx((lx + 4.2, LD / 2 + 1.0 + k * 1.3, 0.12), (2.2, 0.9, 0.14), CONC))
    for k in range(14):  # cladding battens on the +x and -y faces of the upper volume
        parts.append(on_wall("+x", ux + UW / 2, -0.5 - UD / 2 + 0.6 + k * 0.75 - 5.0 * 0, uz + ST * 0.75 + 0.0, 0.14, 0.14, ST * 1.5, 0.07, BARK) if k < 3 or k > 9 else
                     on_wall("-y", -0.5 - UD / 2, ux - UW / 2 + 0.5 + k * 0.8, uz + ST * 0.75, 0.14, 0.14, ST * 1.5, 0.07, BARK))
    # slatted fence along the drive and a bin store by the door
    for k in range(7):
        parts.append(bx((ux + UW / 2 + 0.4, 6.0 + k * 1.9, 2.0), (0.2, 1.5, 4.0), WOOD))
    parts += [bx((ux + UW / 2 + 0.4, 11.7, 4.1), (0.3, 13.2, 0.2), BARK), bx((ux + UW / 2 + 0.4, 11.7, 4.26), (0.3, 13.0, 0.1), SNOW),
              bbx((lx - 3.0, LD / 2 + 1.6, 1.9), (4.4, 2.4, 3.8), WOOD, 0.06), bx((lx - 3.0, LD / 2 + 1.6, 3.86), (4.6, 2.6, 0.14), SNOW)]
    parts += [pg((ux, -0.5, uz + ST * 1.5 + 0.5), [(-3.0, 0.6), (3.0, 2.6), (3.0, 2.8), (-3.0, 0.8)], 5.0, MDK, "y", math.pi / 2)]  # solar panel
    parts += window("+x", lx + LW / 2, -2.0, PL + ST * 0.5, 4.0, 4.4, simple=True)
    return parts


# ---------------------------------------------------------------------------------------------- shops (tier 4, fronts atlas)
FB, FR, FG, FL, FS, FC, FW, FN = FX_BRICK, FX_RENDER, FX_GLASS, FX_LIT, FX_SHUT, FX_CORN, FX_SHOP, FX_SNOW


def shop_front(fy, cx, bay, sign, door_left=False, awning="slope", z_sign=10.4):
    """A 4 m shopfront on the +y wall: stall riser, mullioned glazing, recessed door with a lit fanlight, fascia sign,
    an awning (slope, flat or none) with a snow line and icicles."""
    dx = cx + (-bay * 0.3 if door_left else bay * 0.3)
    gx = cx + (bay * 0.12 if door_left else -bay * 0.12)
    gw = bay * 0.58
    parts = [on_wall("+y", fy, gx, 1.0, gw + 0.4, 0.5, 2.0, 0.2, FR), on_wall("+y", fy, gx, 5.6, gw, 0.12, 7.0, 0.06, FW),
             on_wall("+y", fy, gx, 2.05, gw + 0.3, 0.6, 0.2, 0.3, FC), on_wall("+y", fy, dx, 3.6, 3.2, 0.12, 7.2, 0.06, FS),
             on_wall("+y", fy, dx, 7.5, 3.2, 0.12, 0.8, 0.08, FL), on_wall("+y", fy, dx, 7.35, 3.8, 0.4, 0.3, 0.2, FC),
             on_wall("+y", fy, cx, z_sign, bay - 1.6, 0.4, 2.0, 0.25, sign),
             on_wall("+y", fy, cx, z_sign + 1.15, bay - 1.2, 0.6, 0.3, 0.3, FC), on_wall("+y", fy, cx, z_sign + 1.36, bay - 1.3, 0.5, 0.12, 0.35, FN)]
    for m in range(4):
        parts.append(on_wall("+y", fy, gx - gw / 2 + gw * m / 3, 5.6, 0.22, 0.24, 7.2, 0.14, FC))
    parts.append(on_wall("+y", fy, gx, 6.9, gw, 0.2, 0.18, 0.12, FC))
    if awning == "slope":
        parts += [pg((cx, fy, 9.15), [(0.0, 0.0), (3.6, -1.5), (3.6, -2.1), (3.4, -2.1), (0.0, -0.25)], bay - 2.0, FS, "y", math.pi / 2),
                  pg((cx, fy, 9.15), [(0.0, 0.05), (3.6, -1.45), (3.6, -1.35), (0.0, 0.17)], bay - 2.2, FN, "y", math.pi / 2)]
        parts += icicles(cx - bay / 2 + 1.4, cx + bay / 2 - 1.4, fy + 3.55, 7.05, 4, FN)
    elif awning == "flat":
        parts += [bbx((cx, fy + 1.4, 9.0), (bay - 1.0, 2.8, 0.4), FC, 0.06), bx((cx, fy + 1.4, 9.26), (bay - 1.2, 2.6, 0.12), FN)]
        for sx in (-1, 1):
            parts.append(lmb((cx + sx * (bay / 2 - 1.2), fy + 0.1, 11.5), (cx + sx * (bay / 2 - 1.2), fy + 2.6, 9.2), 0.08, 0.08, FS, 6))
    return parts


def shop_body(W, D, GF, ST, floors, upper, roof="parapet"):
    top = GF + ST * floors
    fy = D / 2
    parts = split_body(W, D, GF, top, upper, FR, bev_u=0.25, bev_g=0.12) + [bx((0, 0, GF + 0.3), (W + 0.6, D + 0.6, 0.6), FC)]
    for u in (-W / 2 + 0.6, W / 2 - 0.6):  # pilasters
        parts.append(on_wall("+y", fy, u, GF / 2, 1.2, 0.6, GF, 0.3, FC))
    if roof == "parapet":
        parts += [bbx((0, 0, top + 0.8), (W + 1.0, D + 1.0, 1.0), FC, 0.1),
                  bx((0, fy + 0.3, top + 1.36), (W + 0.8, 0.5, 0.12), FN), bx((0, -fy - 0.3, top + 1.36), (W + 0.8, 0.5, 0.12), FN),
                  bx((0, fy + 0.3, top - 0.8), (W + 0.4, 0.6, 0.8), FC)]
        for k in range(int(W / 2.0)):  # dentils under the cornice
            parts.append(bx((-W / 2 + 1.0 + k * 2.0, fy + 0.25, top - 1.45), (0.6, 0.5, 0.4), FC))
    return parts, top


def upper_windows(W, D, GF, ST, floors, cols, arched=False, seed=0, side_cols=1, rear_cols=None):
    fy, by = D / 2, -D / 2
    parts = []
    us = spread(W, cols, 0.6)
    for f in range(floors):
        z = GF + ST * f + ST * 0.5
        for j, u in enumerate(us):
            g = FL if lit_of(f, j, seed, 3) else FG
            parts += window("+y", fy, u, z, 2.4, 4.6, g, FC, snow=FN, transom=True)
            if arched:
                parts.append(on_wall("+y", fy, u, z + 2.75, 3.0, 0.4, 0.6, 0.2, FB))
        for u in spread(W, rear_cols or cols, 0.6):
            parts += window("-y", by, u, z, 2.4, 4.6, FG, FC, snow=FN, simple=True)
        for side, p in (("+x", W / 2), ("-x", -W / 2)):
            for u in spread(D, side_cols, 1.0):
                parts += window(side, p, u, z, 2.4, 4.4, FG, FC, snow=FN, simple=True)
    return parts


def shop_extras(W, D, top, wall=FB, flue=True):
    """Back of a shop: a single-storey rear extension with a door and a coping, wheelie bins, roof vents, an AC unit,
    gutters with icicles on the rear eave line, a satellite dish."""
    by = -D / 2
    parts = [bbx((-W / 4, by - 2.0, 4.6), (W / 2 - 1.0, 4.0, 9.2), wall, 0.15), bbx((-W / 4, by - 2.0, 9.5), (W / 2 - 0.4, 4.6, 0.6), FC, 0.06),
             bx((-W / 4, by - 2.0, 9.86), (W / 2 - 0.6, 4.4, 0.12), FN)]
    parts += [on_wall("-y", by - 4.0, -W / 4 + 2.0, 3.4, 2.8, 0.12, 6.8, 0.0, FS), on_wall("-y", by - 4.0, -W / 4 + 2.0, 7.1, 3.4, 0.3, 0.3, 0.15, FC)]
    parts += window("-y", by - 4.0, -W / 4 - 2.0, 5.0, 2.2, 3.0, FG, FC, snow=FN, simple=True)
    for k in range(2):
        x = W / 4 + 1.2 + k * 2.4
        parts += [bbx((x, by - 1.2, 1.8), (2.0, 2.0, 3.4), FS, 0.1), bbx((x, by - 1.2, 3.6), (2.2, 2.2, 0.25), FC, 0.05),
                  bx((x, by - 1.2, 3.78), (2.0, 2.0, 0.1), FN)]
    parts += [rcy((W / 4, -2.0, top + 1.0), 0.45, 2.0, FC, 10), usp((W / 4, -2.0, top + 2.1), 0.6, FC, (1, 1, 0.5), 10, 4),
              rcy((W / 4 + 2.0, -3.5, top + 0.8), 0.35, 1.6, FC, 10)]
    parts += ac_unit("-y", by, W / 4 - 2.0, top - 3.0, FR, FG)
    parts += [usp((-W / 2 + 2.0, by + 2.0, top + 2.0), 1.2, FC, (0.4, 1.0, 1.0), 10, 6), rcy((-W / 2 + 2.0, by + 2.0, top + 1.0), 0.12, 1.6, FS, 6)]
    if flue:
        parts += drainpipe(W / 2 - 0.4, by - 0.4, 0.2, top - 0.3, FS)
    return parts


def shop_bakery():
    """Brick bakery, two storeys under a street-facing gable with a bargeboard and a round attic window, a sloped
    awning, a bay of bread shelves behind the glass, a tall bread-oven chimney on the right."""
    W, D, GF, ST = 18.0, 14.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 1, FB, roof="gable")
    fy = D / 2
    parts += gable_roof(W, D, top, 5.6, FS, 0.8, False, 0, 0, snow=FN, fascia=FC)
    parts += [pg((0, fy + 0.15, top), [(-W / 2, 0), (W / 2, 0), (0, 5.3)], 0.3, FR, "y"),
              rcy((0, fy + 0.3, top + 2.2), 1.3, 0.3, FC, 14, axis="y"), rcy((0, fy + 0.42, top + 2.2), 0.95, 0.12, FL, 14, axis="y")]
    for k in range(5):  # half-timber boards in the gable
        x = -6.0 + 3.0 * k
        parts.append(bx((x, fy + 0.35, top + 1.8 - abs(x) * 0.22), (0.4, 0.2, 3.4 - abs(x) * 0.42), FS))
    parts += [bx((0, fy + 0.35, top + 0.25), (W - 1.0, 0.2, 0.4), FS)]
    for u in spread(W, 3, 0.6):  # window boxes under the upper windows
        parts += [on_wall("+y", fy, u, GF + 1.6, 3.0, 0.8, 0.7, 0.5, FS), on_wall("+y", fy, u, GF + 2.0, 2.8, 0.7, 0.1, 0.5, FN)]
    parts += shop_front(fy, 0.0, W - 1.4, SHOP_SIGN["ck_shop_bakery"][0], door_left=False, awning="slope")
    for k in range(3):  # bread shelves behind the glass
        parts.append(on_wall("+y", fy, -2.0, 3.6 + 1.6 * k, 9.0, 0.6, 0.2, -0.4, FS))
    parts += upper_windows(W, D, GF, ST, 1, 3, seed=1)
    parts += chimney(W / 2 - 2.0, -2.0, top + 1.0, 3.4, FB, cap=FC, pots=1, w=2.4, d=2.4, snow=FN, pot=FS)
    for u in spread(W, 3, 0.6):  # louvred shutters beside the upper windows
        for sx in (-1, 1):
            parts.append(on_wall("+y", D / 2, u + sx * 2.0, GF + ST * 0.5, 1.1, 0.2, 4.8, 0.1, FS))
    parts += drainpipe(-W / 2 + 0.4, fy + 0.4, 0.2, top - 0.3, FS)
    parts += shop_extras(W, D, top, FB, flue=False)
    return parts


def shop_grocer():
    """Rendered corner grocer, flat roof with parapet, a deep canopy on two posts over a produce stall of stacked
    crates, roller shutter half down, a projecting blade sign."""
    W, D, GF, ST = 19.0, 15.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 1, FR)
    fy = D / 2
    parts += shop_front(fy, 0.0, W - 1.4, SHOP_SIGN["ck_shop_grocer"][0], door_left=True, awning=None)
    parts += [bbx((0, fy + 2.4, 9.4), (W - 0.6, 4.8, 0.45), FS, 0.08), bx((0, fy + 2.4, 9.7), (W - 0.8, 4.6, 0.12), FN)]
    for sx in (-1, 1):
        parts.append(rcy((sx * (W / 2 - 1.0), fy + 4.4, 4.6), 0.18, 9.2, FS, 8))
    parts += icicles(-W / 2 + 1.0, W / 2 - 1.0, fy + 4.75, 9.05, 7, FN)
    # produce stall: trestle, stepped crate rows
    for r in range(3):
        for k in range(5):
            parts.append(bbx((-6.0 + k * 2.2, fy + 1.4 + r * 0.9, 1.3 + r * 0.55), (2.0, 1.0, 0.7), FS, 0.05))
    parts += [bx((-1.6, fy + 2.3, 0.6), (11.6, 2.8, 0.2), FC)] + [bx((x, fy + 2.3, 0.3), (0.2, 2.6, 0.6), FS) for x in (-7.2, 4.0)]
    parts += [on_wall("+y", fy, 4.6, 6.8, 3.2, 0.2, 0.9, 0.0, FS)]  # half-down shutter box
    # blade sign on a bracket
    parts += [bx((W / 2 - 0.2, fy + 1.4, GF + 4.0), (0.3, 2.4, 3.0), SHOP_SIGN["ck_shop_grocer"][0]),
              bx((W / 2 - 0.2, fy + 1.4, GF + 5.7), (0.3, 2.6, 0.2), FC), bx((W / 2 - 0.2, fy + 1.4, GF + 5.86), (0.3, 2.4, 0.1), FN)]
    parts += upper_windows(W, D, GF, ST, 1, 4, seed=2)
    parts += [bbx((-4.0, -3.0, top + 2.2), (5.0, 4.0, 2.0), FR, 0.08), bx((-4.0, -3.0, top + 3.26), (4.8, 3.8, 0.12), FN)]
    parts += drainpipe(-W / 2 + 0.4, fy + 0.4, 0.2, top - 0.3, FS)
    parts += shop_extras(W, D, top, FR)[:12]
    return parts


def shop_pizzeria():
    """Brick pizzeria with arched upper windows, a flat roof, a tall steel oven flue climbing the side wall, a flat
    canopy on tie rods, two tables on the pavement."""
    W, D, GF, ST = 18.0, 14.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 1, FB)
    fy = D / 2
    parts += shop_front(fy, 0.0, W - 1.4, SHOP_SIGN["ck_shop_pizzeria"][0], door_left=True, awning="flat")
    parts += upper_windows(W, D, GF, ST, 1, 3, arched=True, seed=0)
    # flue: square duct up the +x wall, offsets, cowl
    fx = W / 2 + 0.7
    parts += [rcy((fx, -2.0, (top + 3.0) / 2), 0.55, top + 3.0, FS, 12), rcy((fx, -2.0, top + 3.4), 0.85, 0.8, FC, 12, r2=0.5),
              rcy((fx, -2.0, top + 3.9), 0.6, 0.12, FN, 12)]
    for k in range(4):
        parts.append(bx((fx - 0.4, -2.0, 3.0 + k * (top / 4)), (0.8, 0.3, 0.3), FC))
    for k in range(2):  # pavement tables
        x = -5.0 + 7.0 * k
        parts += [rcy((x, fy + 3.4, 2.45), 1.2, 0.12, FC, 14), rcy((x, fy + 3.4, 1.2), 0.1, 2.4, FS, 8),
                  rcy((x, fy + 3.4, 0.05), 0.6, 0.1, FS, 10)]
        for sx in (-1, 1):
            parts += [rcy((x + sx * 1.9, fy + 3.4, 1.5), 0.55, 0.12, FS, 10), rcy((x + sx * 1.9, fy + 3.4, 0.75), 0.07, 1.5, FS, 6),
                      bx((x + sx * 2.35, fy + 3.4, 2.2), (0.12, 1.0, 1.4), FS)]
    parts += shop_extras(W, D, top, FB, flue=False)
    for u in spread(W, 3, 0.6):  # iron balconettes
        parts += [on_wall("+y", D / 2, u, GF + 2.2, 3.4, 0.9, 0.15, 0.45, FS), on_wall("+y", D / 2, u, GF + 3.4, 3.4, 0.12, 0.12, 0.85, FS),
                  on_wall("+y", D / 2, u, GF + 3.52, 3.3, 0.2, 0.08, 0.85, FN)]
        for k in range(5):
            parts.append(on_wall("+y", D / 2, u - 1.5 + 0.75 * k, GF + 2.8, 0.1, 0.1, 1.1, 0.85, FS))
    return parts


def shop_cafe():
    """Rendered cafe under a slate mansard with two dormers, a full-width folding glass front, a striped awning and
    a café bench, a pendant lamp bracket."""
    W, D, GF, ST = 18.0, 14.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 1, FR, roof="mansard")
    fy = D / 2
    # mansard: steep lower slope, low upper hip; dormers with snow
    parts += [pg((0, 0, top), [(-D / 2 - 0.6, 0), (D / 2 + 0.6, 0), (D / 2 - 1.6, 4.6), (-D / 2 + 1.6, 4.6)], W + 1.0, FS, "y", math.pi / 2),
              bx((0, 0, top + 4.8), (W - 2.0, D - 3.2, 0.4), FC), bx((0, 0, top + 5.06), (W - 2.4, D - 3.6, 0.12), FN),
              bx((0, fy + 0.7, top - 0.2), (W + 1.4, 0.6, 0.5), FC)]
    for u in (-4.5, 4.5):
        parts += [bbx((u, fy - 0.4, top + 2.4), (3.2, 2.6, 3.4), FR, 0.06)] + gable_roof(3.2, 2.6, top + 4.1, 1.2, FS, 0.3, False, u, fy - 0.4, FN, FC)
        parts += window("+y", fy + 0.9, u, top + 2.3, 2.0, 2.2, FL if u > 0 else FG, FC, snow=FN, simple=True)
    # folding glass front instead of a standard shopfront
    parts += [on_wall("+y", fy, 0.0, 5.0, W - 3.0, 0.12, 8.0, 0.06, FW), on_wall("+y", fy, 0.0, 10.4, W - 1.6, 0.4, 2.0, 0.25, SHOP_SIGN["ck_shop_cafe"][0]),
              on_wall("+y", fy, 0.0, 9.2, W - 2.6, 0.3, 0.3, 0.15, FC), on_wall("+y", fy, 0.0, 0.6, W - 2.6, 0.4, 1.2, 0.2, FR)]
    for m in range(7):
        parts.append(on_wall("+y", fy, -(W - 3.0) / 2 + (W - 3.0) * m / 6, 5.0, 0.2, 0.26, 8.0, 0.14, FC))
    parts += [pg((0, fy, 9.6), [(0.0, 0.0), (3.4, -1.6), (3.4, -2.2), (3.2, -2.2), (0.0, -0.25)], W - 2.0, FS, "y", math.pi / 2),
              pg((0, fy, 9.6), [(0.0, 0.05), (3.4, -1.55), (3.4, -1.45), (0.0, 0.17)], W - 2.2, FN, "y", math.pi / 2)]
    parts += icicles(-W / 2 + 1.4, W / 2 - 1.4, fy + 3.35, 7.5, 6, FN)
    parts += [bbx((-4.0, fy + 1.6, 1.6), (6.0, 1.4, 0.3), FS, 0.05), bbx((-4.0, fy + 1.0, 2.6), (6.0, 0.3, 1.8), FS, 0.05)]
    for sx in (-1, 1):
        parts.append(bx((-4.0 + sx * 2.7, fy + 1.4, 0.8), (0.25, 1.2, 1.6), FC))
    parts += upper_windows(W, D, GF, ST, 1, 3, seed=2)
    parts += drainpipe(W / 2 - 0.4, fy + 0.4, 0.2, top - 0.3, FS)
    parts += shop_extras(W, D, top, FR, flue=False)
    for k in range(2):  # pavement tables and chairs under the awning
        x = 2.5 + 4.2 * k
        parts += [rcy((x, fy + 2.2, 2.3), 0.9, 0.1, FC, 12), rcy((x, fy + 2.2, 1.15), 0.08, 2.3, FS, 6)]
        for sx in (-1, 1):
            parts += [bx((x + sx * 1.5, fy + 2.2, 1.4), (0.9, 0.9, 0.12), FS), bx((x + sx * 1.9, fy + 2.2, 2.0), (0.12, 0.9, 1.2), FS)]
    return parts


def shop_bookshop():
    """Brick bookshop with a bowed Georgian shop window of small panes, a pedimented door case, a hanging sign on a
    scrolled bracket, a gable roof with a big dormer."""
    W, D, GF, ST = 18.0, 14.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 1, FB, roof="gable")
    fy = D / 2
    parts += gable_roof(W, D, top, 5.6, FS, 0.8, True, snow=FN, fascia=FC)
    parts += [bbx((-1.0, fy - 1.2, top + 2.0), (6.0, 3.2, 4.0), FB, 0.08)] + gable_roof(6.0, 3.2, top + 4.0, 2.2, FS, 0.4, False, -1.0, fy - 1.2, FN, FC)
    parts += window("+y", fy + 0.4, -1.0, top + 2.0, 4.0, 2.8, FL, FC, snow=FN, mull=2)
    # bow window: a half-cylinder of glass with a base and a lead cap, small-pane glazing bars
    bxp = -3.0
    parts += [rcy((bxp, fy, 5.2), 4.6, 6.2, FW, 12), rcy((bxp, fy, 1.4), 4.8, 2.8, FR, 12), rcy((bxp, fy, 8.6), 5.0, 0.6, FC, 12),
              rcy((bxp, fy, 8.95), 4.8, 0.14, FN, 12)]
    for k in range(7):
        a = math.pi * (k + 0.5) / 7
        parts.append(bx((bxp + math.cos(a) * 4.62, fy + math.sin(a) * 4.62, 5.2), (0.16, 0.16, 6.2), FC))
    for z in (3.6, 5.2, 6.8):
        parts.append(rcy((bxp, fy, z), 4.66, 0.12, FC, 12))
    # door case with a pediment
    dx = 5.5
    parts += [on_wall("+y", fy, dx, 3.6, 3.0, 0.12, 7.2, 0.06, FS), on_wall("+y", fy, dx, 7.8, 3.0, 0.1, 1.0, 0.08, FL)]
    for sx in (-1, 1):
        parts.append(rcy((dx + sx * 2.0, fy + 0.4, 4.2), 0.3, 8.4, FC, 10))
    parts += [pg((dx, fy + 0.4, 8.4), [(-2.6, 0), (2.6, 0), (0, 1.5)], 0.8, FC, "y"),
              pg((dx, fy + 0.4, 8.45), [(-2.4, 0.1), (2.4, 0.1), (0, 1.5)], 0.6, FN, "y")]
    parts += [on_wall("+y", fy, 0.0, 10.4, W - 1.6, 0.4, 2.0, 0.25, SHOP_SIGN["ck_shop_bookshop"][0])]
    # hanging sign on a bracket at the left corner
    parts += [lmb((-W / 2 + 0.4, fy + 0.2, 12.4), (-W / 2 + 0.4, fy + 3.2, 12.4), 0.08, 0.08, FS, 6),
              lmb((-W / 2 + 0.4, fy + 0.2, 11.2), (-W / 2 + 0.4, fy + 2.6, 12.4), 0.06, 0.06, FS, 6),
              bx((-W / 2 + 0.4, fy + 2.2, 11.0), (0.2, 2.0, 2.4), SHOP_SIGN["ck_shop_bookshop"][0])]
    parts += upper_windows(W, D, GF, ST, 1, 3, seed=0)
    parts += chimney(-W / 2 + 1.6, 0.0, top + 1.0, 4.4, FB, cap=FC, pots=2, snow=FN, pot=FS)
    parts += gutter_x(-W / 2 - 0.8, W / 2 + 0.8, -D / 2 - 0.8, top - 0.45, 3, FS, FN)
    parts += gutter_x(-W / 2 - 0.8, W / 2 + 0.8, D / 2 + 0.8, top - 0.45, 4, FS, FN)
    parts += shop_extras(W, D, top, FB, flue=False)
    for k in range(3):  # book trolley outside
        parts.append(bbx((4.0 + 2.0 * (k - 1), D / 2 + 1.4, 1.6 + 0.0), (1.8, 1.2, 0.9), FS, 0.05))
    parts += [bx((4.0, D / 2 + 1.4, 1.0), (6.2, 1.4, 0.2), FC)] + [rcy((4.0 + sx * 2.8, D / 2 + 1.4, 0.4), 0.3, 0.2, FS, 8, axis="y") for sx in (-1, 1)]
    return parts


def shop_pharmacy_cross():
    """Rendered pharmacy with a flat roof and a lit projecting cross box sign on a bracket (the silhouette feature),
    double doors with a ramp and rail, frosted lower glazing, AC units and a satellite dish."""
    W, D, GF, ST = 19.0, 15.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 1, FR)
    fy = D / 2
    parts += shop_front(fy, -1.0, W - 3.4, SHOP_SIGN["ck_shop_pharmacy_cross"][0], door_left=True, awning=None)
    parts += [on_wall("+y", fy, -1.0, 3.2, 10.0, 0.08, 2.4, 0.13, FR)]  # frosted band
    # ramp with a rail to the doors
    parts += [pg((-6.4, fy + 1.6, 0), [(-4.0, 0.0), (2.0, 0.0), (2.0, 0.6), (1.4, 0.6)], 2.4, FC, "y")]
    for k in range(4):
        parts.append(rcy((-9.0 + k * 2.0, fy + 2.9, 1.4), 0.08, 2.8, FS, 6))
    parts.append(lmb((-10.2, fy + 2.9, 2.4), (-4.4, fy + 2.9, 3.0), 0.09, 0.09, FS, 6))
    # cross sign: bracket, box, two crossed boxes, frame, snow on top
    cx, cz = W / 2 - 1.2, GF + 4.6
    parts += [bx((cx, fy + 0.8, cz + 2.4), (0.3, 1.6, 0.3), FS), bx((cx, fy + 0.8, cz - 2.4), (0.3, 1.6, 0.3), FS),
              bbx((cx, fy + 2.0, cz), (0.6, 1.4, 4.4), SHOP_SIGN["ck_shop_pharmacy_cross"][0], 0.08),
              bbx((cx, fy + 2.0, cz), (0.6, 4.4, 1.4), SHOP_SIGN["ck_shop_pharmacy_cross"][0], 0.08),
              bx((cx, fy + 2.0, cz + 2.28), (0.66, 1.3, 0.12), FN), bx((cx, fy + 2.0, cz + 0.78), (0.66, 4.2, 0.1), FN)]
    parts += upper_windows(W, D, GF, ST, 1, 4, seed=1)
    parts += ac_unit("-y", -D / 2, -4.0, GF + 3.0, FR, FG) + ac_unit("-y", -D / 2, 4.0, GF + 3.0, FR, FG)
    parts += [usp((-5.0, -3.0, top + 2.6), 1.6, FC, (0.4, 1.0, 1.0), 12, 6), rcy((-5.0, -3.0, top + 1.6), 0.15, 2.0, FS, 8)]
    parts += drainpipe(-W / 2 + 0.4, fy + 0.4, 0.2, top - 0.3, FS)
    parts += shop_extras(W, D, top, FR)[:14]
    for k in range(4):  # bollards along the kerb
        parts += [rcy((-8.0 + 3.0 * k, fy + 4.2, 1.1), 0.3, 2.2, FS, 10), usp((-8.0 + 3.0 * k, fy + 4.2, 2.2), 0.3, FS, (1, 1, 0.6), 10, 4)]
    return parts


def shop_row_arcade():
    """Four shops behind a covered arcade of round arches (the silhouette feature) under two rendered storeys, a deep
    cornice with a balustrade, four fascia signs inside the arcade, roof plant and a timber water tank."""
    W, D, GF, ST = 44.0, 20.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 2, FR)
    parts[1] = bbx((0, -1.7, GF / 2), (W, D - 3.4, GF), FR, 0.12)  # the arcade: ground floor set back 3.4 behind the piers
    fy = D / 2
    signs = SHOP_SIGN["ck_shop_row_arcade"]
    bay = W / 4
    for k, sign in enumerate(signs):
        cx = -W / 2 + bay * (k + 0.5)
        parts += shop_front(fy - 3.4, cx, bay, sign, door_left=bool(k % 2), awning=None, z_sign=9.6)
    # arcade: floor slab, piers, round arch heads, spandrels, a roof slab carrying the upper floors' front
    parts += [bx((0, fy - 1.7, 0.1), (W, 3.4, 0.2), FC), bx((0, fy, GF - 1.0), (W + 0.4, 0.8, 2.0), FR)]
    n = 8
    for k in range(n + 1):
        x = -W / 2 + W * k / n
        parts += [bbx((x, fy - 0.2, (GF - 2.0) / 2), (1.4, 1.4, GF - 2.0), FC, 0.1), bx((x, fy - 0.2, GF - 2.3), (1.8, 1.6, 0.4), FC)]
    for k in range(n):
        x = -W / 2 + W * (k + 0.5) / n
        span = W / n - 1.4
        pts = [(-span / 2, 0.0)] + [(-math.cos(math.pi * t / 8) * span / 2, math.sin(math.pi * t / 8) * span / 2 * 0.8) for t in range(9)] + [(span / 2, 0.0), (span / 2, 2.4), (-span / 2, 2.4)]
        parts.append(pg((x, fy - 0.1, GF - 4.6), pts[1:9] + [(span / 2, 0.0), (span / 2, 2.6), (-span / 2, 2.6)], 0.8, FR, "y"))
    parts += upper_windows(W, D, GF, ST, 2, 8, seed=3, side_cols=1, rear_cols=4)
    # balustrade on the cornice
    for k in range(int(W / 2.0)):
        parts.append(rcy((-W / 2 + 1.0 + k * 2.0, fy + 0.2, top + 1.8), 0.24, 1.4, FC, 6, r2=0.16))
    parts += [bx((0, fy + 0.2, top + 2.6), (W, 0.6, 0.3), FC), bx((0, fy + 0.2, top + 2.82), (W - 0.2, 0.5, 0.12), FN)]
    parts += water_tank(12.0, -4.0, top + 1.3, 2.4, 4.0, 4.0, FS, FC, rings=False, snow=FN)
    parts += [bbx((-12.0, -3.0, top + 2.4), (6.0, 4.0, 2.4), FR, 0.08)]
    parts += ac_unit("-y", -D / 2, -10.0, GF + ST + 2.0, FR, FG) + ac_unit("-y", -D / 2, 6.0, GF + 2.0, FR, FG)
    parts += drainpipe(-W / 2 + 0.5, -D / 2 - 0.45, 0.2, top - 0.3, FS) + drainpipe(W / 2 - 0.5, -D / 2 - 0.45, 0.2, top - 0.3, FS)
    return parts


def shop_row_corner():
    """Corner block of shops on two streets: brick upper floors, a chamfered corner entrance under a copper-domed
    turret (the silhouette feature), shopfronts with awnings on both faces, a fire escape on the side street."""
    W, D, GF, ST = 40.0, 28.0, 13.0, 9.6
    parts, top = shop_body(W, D, GF, ST, 2, FB)
    fy, fx = D / 2, W / 2
    signs = SHOP_SIGN["ck_shop_row_corner"]
    bay = (W - 8.0) / 3
    for k in range(3):
        cx = -W / 2 + bay * (k + 0.5)
        parts += shop_front(fy, cx, bay, signs[k], door_left=bool(k % 2), awning="slope")
    # side street shop on +x (front rotated), one sign
    parts += [on_wall("+x", fx, -2.0, 5.6, 9.0, 0.12, 7.0, 0.06, FW), on_wall("+x", fx, -2.0, 1.0, 9.4, 0.5, 2.0, 0.2, FR),
              on_wall("+x", fx, -2.0, 10.4, 12.0, 0.4, 2.0, 0.25, signs[3]), on_wall("+x", fx, 4.6, 3.6, 3.2, 0.12, 7.2, 0.06, FS)]
    # chamfered corner: a cylinder turret over the corner entrance
    tx, ty = fx - 2.0, fy - 2.0
    th = top + 3.0
    parts += [rcy((tx, ty, th / 2), 4.6, th, FB, 16), rcy((tx, ty, GF + 0.3), 4.9, 0.6, FC, 16), rcy((tx, ty, th + 0.4), 5.0, 0.8, FC, 16),
              usp((tx, ty, th + 0.8), 4.6, FC, (1.0, 1.0, 0.85), 16, 8), rcy((tx, ty, th + 5.2), 0.4, 1.6, FS, 8, r2=0.1),
              rcy((tx, ty, th + 1.0), 4.7, 0.5, FN, 16, r2=3.6)]
    a = math.pi / 4
    for f, (z, h) in enumerate(((5.6, 7.0), (GF + ST * 0.5, 4.6), (GF + ST * 1.5, 4.6))):
        for da in (-0.6, 0.0, 0.6):
            ang = a + da
            g = FW if f == 0 else (FL if (f + int(da * 10)) % 3 == 0 else FG)
            parts += [bx((tx + math.cos(ang) * 4.55, ty + math.sin(ang) * 4.55, z), (2.6 if f else 3.2, 0.3, h), g, ang + math.pi / 2),
                      bx((tx + math.cos(ang) * 4.7, ty + math.sin(ang) * 4.7, z - h / 2 - 0.15), (3.0, 0.5, 0.25), FC, ang + math.pi / 2)]
    parts += upper_windows(W, D, GF, ST, 2, 7, seed=1, side_cols=2)
    # fire escape on the +x face, rear half
    for f in range(2):
        z = GF + ST * f + 0.4
        parts += [bx((fx + 1.6, -8.0, z), (3.0, 8.0, 0.2), FS), bx((fx + 3.05, -8.0, z + 1.6), (0.15, 8.0, 0.15), FS),
                  bx((fx + 3.1, -8.0, z + 0.22), (0.5, 7.8, 0.08), FN)]
        for k in range(6):
            parts.append(bx((fx + 3.05, -12.0 + 8.0 * k / 5, z + 0.8), (0.12, 0.12, 1.6), FS))
    parts.append(pg((fx + 2.4, -8.0, GF + 0.4), [(-3.4, 0.1), (-2.8, 0.1), (3.2, ST - 0.1), (2.6, ST - 0.1)], 1.2, FS, "x"))
    parts += water_tank(-12.0, -6.0, top + 1.3, 2.4, 4.0, 4.0, FS, FC, snow=FN)
    parts += drainpipe(-W / 2 + 0.5, fy + 0.45, 0.2, top - 0.3, FS)
    return parts


# ---------------------------------------------------------------------------------------------- mid-rise (tier 5)
def floor_bands(W, D, z, s=CONC, h=0.6):
    return [bx((0, 0, z), (W + 0.4, D + 0.4, h), s)]


def parapet(W, D, top, s=CONC):
    return [bbx((0, 0, top + 0.6), (W + 0.6, D + 0.6, 1.2), s, 0.1)] + \
        [bx((0, sy * (D / 2 + 0.05), top + 1.27), (W + 0.5, 0.6, 0.14), SNOW) for sy in (-1, 1)] + \
        [bx((sx * (W / 2 + 0.05), 0, top + 1.27), (0.6, D - 0.6, 0.14), SNOW) for sx in (-1, 1)]


def all_faces(W, D, z0, ST, floors, cf, cs, wall_glass=None, frame=CONC, seed=0, w_f=2.6, w_s=2.6, h=4.6, mull=1,
              front_full=True, cr=None):
    parts = []
    zs = [z0 + ST * f + ST * 0.52 for f in range(floors)]
    parts += win_rows("+y", D / 2, spread(W, cf, 0.8), zs, w_f, h, frame=frame, seed=seed, mull=mull, simple=not front_full)
    parts += win_rows("-y", -D / 2, spread(W, cr or cf, 0.8), zs, w_f, h, frame=frame, simple=True)
    parts += win_rows("+x", W / 2, spread(D, cs, 0.8), zs, w_s, h, frame=frame, simple=True)
    parts += win_rows("-x", -W / 2, spread(D, cs, 0.8), zs, w_s, h, frame=frame, seed=seed + 1, simple=True)
    return parts


def midrise_brick_8():
    """Brick warehouse conversion: five storeys of tall arched windows over a ground floor of loading doors, a corbelled
    cornice, a goods hoist beam, iron fire escape on the side, a rooftop timber water tank."""
    W, D, GF, ST, F = 28.0, 20.0, 12.0, 9.6, 4
    top = GF + ST * F
    parts = split_body(W, D, GF, top, WB, CONC)
    parts += parapet(W, D, top, CONC)
    for k in range(int(W / 2.4)):
        parts.append(bx((-W / 2 + 1.2 + k * 2.4, D / 2 + 0.25, top - 0.6), (0.8, 0.5, 0.5), WB))
    for f in range(F):
        parts += floor_bands(W, D, GF + ST * f + 0.3, CONC, 0.4)
    us = spread(W, 6, 0.8)
    zs = [GF + ST * f + ST * 0.52 for f in range(F)]
    for f, z in enumerate(zs):
        for j, u in enumerate(us):
            g = GLIT if lit_of(f, j, 1) else GLS
            parts += window("+y", D / 2, u, z, 2.8, 5.0, g, MDK, mull=0)
            parts.append(on_wall("+y", D / 2, u, z + 2.9, 3.6, 0.4, 0.8, 0.2, CONC))
    parts += win_rows("-y", -D / 2, spread(W, 4, 0.8), zs, 2.8, 5.0, simple=True)
    parts += win_rows("+x", W / 2, spread(D, 2, 0.8), zs, 2.6, 5.0, simple=True)
    parts += win_rows("-x", -W / 2, spread(D, 2, 0.8), zs, 2.6, 5.0, simple=True)
    # ground floor: three loading doors and an entrance
    for u in (-9.0, 0.0, 9.0):
        parts += [on_wall("+y", D / 2, u, 4.0, 6.0, 0.12, 8.0, 0.06, WORN), on_wall("+y", D / 2, u, 8.5, 7.0, 0.6, 0.6, 0.3, MDK)]
        for k in range(2):
            parts.append(on_wall("+y", D / 2, u, 2.4 + 2.6 * k, 5.8, 0.06, 0.08, 0.14, MDK))
    parts += door_unit("+y", D / 2, -13.0 + 0.4, 0.0, wall_trim=MDK, canopy=None, steps=0, fan=True)
    parts += [on_wall("-x", -W / 2, 1.0, 3.0, 12.0, 0.06, 4.8, 0.02, GRAF)]
    # hoist beam and doors stacked on the front centre
    parts += [on_wall("+y", D / 2, 0.0, top - 0.2, 0.6, 3.0, 0.6, 1.5, MDK), rcy((0.0, D / 2 + 2.8, top - 1.4), 0.2, 1.6, MDK, 8)]
    # fire escape on +x
    for f in range(F):
        z = GF + ST * f + 0.4
        parts += [bx((W / 2 + 1.6, 0.0, z), (3.0, 10.0, 0.2), MDK), bx((W / 2 + 3.05, 0.0, z + 1.6), (0.15, 10.0, 0.15), MDK),
                  bx((W / 2 + 3.1, 0.0, z + 0.22), (0.5, 9.8, 0.08), SNOW)]
        for k in range(4):
            parts.append(bx((W / 2 + 3.05, -5.0 + 10.0 * k / 3, z + 0.8), (0.12, 0.12, 1.6), MDK))
        if f < F - 1:
            parts.append(pg((W / 2 + 2.4, 0.0, z), [(-4.2, 0.1), (-3.6, 0.1), (3.4, ST - 0.1), (2.8, ST - 0.1)], 1.2, MDK, "x"))
    parts += water_tank(-6.0, -2.0, top + 1.2, 2.8, 4.6, 4.6, rings=False)
    parts += drainpipe(-W / 2 + 0.4, D / 2 + 0.4, 0.2, top - 0.2) + drainpipe(W / 2 - 0.4, -D / 2 - 0.4, 0.2, top - 0.2)
    return parts


def midrise_render_10():
    """Rendered block of flats with continuous balconies on alternate floors (steel rails, snow lines), a setback
    penthouse with a terrace, a recessed lobby and AC units."""
    W, D, GF, ST, F = 30.0, 18.0, 12.0, 9.6, 4
    top = GF + ST * F
    parts = split_body(W, D, GF, top, WA, WC)
    parts += parapet(W, D, top, CONC)
    parts += all_faces(W, D, GF, ST, F, 6, 2, seed=2, w_f=3.0, h=5.2, cr=4, mull=0)
    for f in range(F):
        z = GF + ST * f
        parts += floor_bands(W, D, z + 0.3, CONC, 0.5)
        if f % 2 == 0:
            parts += [bbx((0, D / 2 + 1.5, z + 0.35), (W - 2.0, 3.0, 0.7), CONC, 0.08), bx((0, D / 2 + 2.95, z + 2.9), (W - 2.0, 0.16, 0.16), MET),
                      bx((0, D / 2 + 3.0, z + 3.06), (W - 2.2, 0.2, 0.08), SNOW), bx((0, D / 2 + 2.95, z + 1.2), (W - 2.0, 0.12, 0.12), MET)]
            for k in range(9):
                parts.append(bx((-W / 2 + 1.0 + k * (W - 2.0) / 8, D / 2 + 2.95, z + 1.8), (0.1, 0.1, 2.2), MET))
    # penthouse
    PW, PD = 18.0, 11.0
    parts += [bbx((-3.0, -2.0, top + 1.2 + 4.4), (PW, PD, 8.8), WC, 0.2), bbx((-3.0, -2.0, top + 10.4), (PW + 1.0, PD + 1.0, 0.6), CONC, 0.06),
              bx((-3.0, -2.0, top + 10.76), (PW + 0.8, PD + 0.8, 0.12), SNOW)]
    parts += [on_wall("+y", -2.0 + PD / 2, -3.0, top + 5.4, PW - 3.0, 0.14, 6.4, 0.08, GLIT)]
    for k in range(6):
        parts.append(on_wall("+y", -2.0 + PD / 2, -3.0 - (PW - 3.0) / 2 + k * (PW - 3.0) / 5, top + 5.4, 0.2, 0.24, 6.4, 0.14, MDK))
    for k in range(4):
        parts.append(usp((-10.0 + k * 4.5, D / 2 - 1.8, top + 2.0), 1.0, LEAF if k % 2 else LDK, (1.2, 0.8, 0.9), 10, 6))
    # lobby
    parts += [on_wall("+y", D / 2, 0.0, 4.4, 8.0, 0.12, 8.8, 0.06, GLS), on_wall("+y", D / 2, 0.0, 3.4, 3.0, 0.14, 6.8, 0.12, DOOR),
              on_wall("+y", D / 2, 0.0, 9.6, 10.0, 2.4, 0.5, 1.0, CONC), on_wall("+y", D / 2, 0.0, 9.92, 9.8, 2.2, 0.12, 1.0, SNOW)]
    for u in (-12.0, 8.0):
        parts += ac_unit("-y", -D / 2, u, GF + ST + 2.0) + ac_unit("-y", -D / 2, u, GF + ST * 3 + 2.0)
    parts += drainpipe(W / 2 - 0.4, D / 2 + 0.4, 0.2, top - 0.2)
    return parts


def midrise_setback():
    """Stepped block: three full floors, then two set back behind roof terraces with rails and planters, a stair core
    rising above the top as a lift tower, ribbon windows with concrete bands."""
    W, D, GF, ST = 30.0, 22.0, 12.0, 9.6
    z1 = GF + ST * 2
    parts = split_body(W, D, GF, z1, WC, CONC)
    parts += parapet(W, D, z1, CONC)
    parts += all_faces(W, D, GF, ST, 2, 5, 4, seed=1, w_f=4.2, h=4.6, mull=2)
    for f in range(2):
        parts += floor_bands(W, D, GF + ST * f + 0.3, CONC, 0.5)
    W2, D2 = 22.0, 14.0
    z2 = z1 + ST * 2
    parts += [bbx((0, -2.0, z1 + ST), (W2, D2, ST * 2), WC, 0.25)]
    parts += [bbx((0, -2.0, z2 + 0.6), (W2 + 0.6, D2 + 0.6, 1.2), CONC, 0.1),
              bx((0, -2.0 + D2 / 2 + 0.05, z2 + 1.27), (W2 + 0.5, 0.6, 0.14), SNOW)]
    for f in range(2):
        z = z1 + ST * f + ST * 0.52
        parts += win_rows("+y", -2.0 + D2 / 2, spread(W2, 4, 0.8), [z], 4.0, 4.6, frame=CONC, seed=f, mull=2)
        parts += win_rows("+x", W2 / 2, spread(D2, 2, 0.8), [z], 3.0, 4.6, frame=CONC, simple=True)
        parts += win_rows("-x", -W2 / 2, spread(D2, 2, 0.8), [z], 3.0, 4.6, frame=CONC, simple=True)
    # terrace rails and planters on the lower roof
    for k in range(15):
        parts.append(bx((-W / 2 + 1.0 + k * 2.0, D / 2 - 0.2, z1 + 2.4), (0.1, 0.1, 2.0), MET))
    parts += [bx((0, D / 2 - 0.2, z1 + 3.4), (W - 1.0, 0.14, 0.14), MET)]
    for k in range(5):
        parts += [bbx((-12.0 + k * 6.0, D / 2 - 2.0, z1 + 2.0), (3.6, 1.2, 1.4), CONC, 0.05),
                  usp((-12.0 + k * 6.0, D / 2 - 2.0, z1 + 3.0), 1.0, LEAF if k % 2 else LDK, (1.4, 0.6, 0.8), 10, 6)]
    # lift tower
    parts += [bbx((-6.0, -6.0, z2 + 4.0), (6.0, 6.0, 8.0), CONC, 0.1), bx((-6.0, -6.0, z2 + 8.2), (6.2, 6.2, 0.12), SNOW),
              rcy((6.0, -5.0, z2 + 1.0), 0.6, 2.0, MET, 12), rcy((8.0, -5.0, z2 + 1.0), 0.6, 2.0, MET, 12)]
    parts += door_unit("+y", D / 2, 0.0, 0.0, wall_trim=MDK, canopy=CONC, steps=0, fan=False)
    parts += [on_wall("+y", D / 2, -9.0, 4.4, 9.0, 0.12, 7.0, 0.06, GLS), on_wall("+y", D / 2, 9.0, 4.4, 9.0, 0.12, 7.0, 0.06, GLS)]
    parts += drainpipe(-W / 2 + 0.4, D / 2 + 0.4, 0.2, z1 - 0.2)
    return parts


def midrise_courtyard():
    """U-shaped brick block around a street courtyard: two wings and a back range, a gated entrance arch between the
    wings with railings, a tree in the yard, mansard attic with dormers on the back range."""
    W, D, ST, GF, F = 42.0, 30.0, 9.6, 11.0, 3
    top = GF + ST * F
    WG = 11.0  # wing width
    parts = []
    for cx, cy2, w, d in ((-(W - WG) / 2, 0.0, WG, D), ((W - WG) / 2, 0.0, WG, D), (0.0, -D / 2 + 5.5, W - 2 * WG, 11.0)):
        parts += split_body(w, d, GF, top, WB, CONC, cx, cy2, 0.25) + [
                  bbx((cx, cy2, top + 0.6), (w + 0.6, d + 0.6, 1.2), CONC, 0.1), bx((cx, cy2, top + 1.27), (w + 0.4, d + 0.4, 0.12), SNOW)]
        for f in range(F):
            parts.append(bx((cx, cy2, GF + ST * f + 0.3), (w + 0.4, d + 0.4, 0.4), CONC))
    zs = [GF + ST * f + ST * 0.52 for f in range(F)]
    for side in (-1, 1):
        cx = side * (W - WG) / 2
        parts += win_rows("+y", D / 2, [cx - 2.6 + 0 * side, cx + 2.6], zs, 2.6, 4.6, seed=side + 2, mull=0)
        for i, z in enumerate(zs):
            for u in spread(D, 2, 2.0):
                parts += window("+x" if side > 0 else "-x", side * W / 2, u, z, 2.6, 4.6,
                                GLIT if lit_of(i, int(u), side) else GLS, simple=True)
            parts += window("-x" if side > 0 else "+x", side * (W / 2 - WG), -6.0 * side, z, 2.6, 4.6, GLS, simple=True)
        parts += door_unit("+y", D / 2, cx, 0.0, canopy=CONC, steps=1)
    parts += win_rows("+y", -D / 2 + 11.0, spread(W - 2 * WG, 3, 0.8), zs, 2.6, 4.6, seed=1, mull=0)
    parts += win_rows("-y", -D / 2, spread(W, 3, 0.8), zs, 2.6, 4.6, simple=True)
    # mansard attic on the back range with dormers
    parts += [pg((0, -D / 2 + 5.5, top + 1.2), [(-6.0, 0), (6.0, 0), (4.0, 4.6), (-4.0, 4.6)], W - 2 * WG, ROOFB, "y", math.pi / 2),
              bx((0, -D / 2 + 5.5, top + 5.9), (W - 2 * WG - 0.4, 8.0, 0.14), SNOW)]
    for u in spread(W - 2 * WG, 3, 1.0):
        parts += [bbx((u, -D / 2 + 9.4, top + 3.6), (2.6, 2.0, 3.0), WB, 0.05)] + gable_roof(2.6, 2.0, top + 5.1, 1.2, ROOFB, 0.2, False, u, -D / 2 + 9.4)
    # gate: arch between the wings with railings
    gx0, gx1 = -(W / 2 - WG), W / 2 - WG
    parts += [bx((0, D / 2 - 0.5, 0.3), (gx1 - gx0, 1.0, 0.6), CONC)]
    for k in range(int((gx1 - gx0) / 1.2)):
        parts.append(bx((gx0 + 0.6 + k * 1.2, D / 2 - 0.5, 2.4), (0.12, 0.12, 3.6), MDK))
    parts += [bx((0, D / 2 - 0.5, 4.2), (gx1 - gx0, 0.16, 0.16), MDK)]
    for sx in (-1, 1):
        parts += [bbx((sx * 3.0, D / 2 - 0.5, 4.0), (1.4, 1.4, 8.0), CONC, 0.08), usp((sx * 3.0, D / 2 - 0.5, 8.6), 0.7, CONC, (1, 1, 1), 10, 6)]
    # yard: paving, tree
    parts += [bx((0, 4.0, 0.06), (gx1 - gx0, D - 11.0, 0.12), STAIN), rcy((0, 4.0, 3.0), 0.5, 6.0, BARK, 10, r2=0.35)]
    parts += [usp((0, 4.0, 8.0), 3.4, LEAF, (1.1, 1.1, 0.85), 12, 7), usp((2.0, 5.0, 9.5), 2.2, LDK, (1, 1, 0.9), 10, 6),
              usp((-2.0, 3.0, 9.4), 2.2, LEAF, (1, 1, 0.9), 10, 6)]
    return parts


def midrise_corner_clock():
    """Corner office block with a rounded corner (a quarter drum) rising into a clock turret with four faces and a
    lead dome (the silhouette feature), stone bands, a ground floor of tall arched windows."""
    W, D, GF, ST, F = 30.0, 24.0, 12.0, 9.6, 4
    top = GF + ST * F
    R = 5.0
    cx, cy2 = W / 2 - R, D / 2 - R
    parts = split_body(W - 2 * R, 2 * R, GF, top, WA, WC, -R, D / 2 - R, 0.2) + split_body(W, D - 2 * R, GF, top, WA, WC, 0.0, -R, 0.2)
    parts += [rcy((cx, cy2, (GF + top) / 2), R, top - GF, WA, 16), rcy((cx, cy2, GF / 2), R, GF, WC, 16)]
    for f in range(F + 1):
        z = GF + ST * f + (0.3 if f < F else 0.6)
        hgt = 0.4 if f < F else 1.2
        parts += [bx((-2.5, 0, z), (W - 4.6, D + 0.4, hgt), CONC), bx((0, -2.5, z), (W + 0.4, D - 4.6, hgt), CONC)]
        if f in (0, F):
            parts.append(rcy((cx, cy2, z), R + 0.2, hgt, CONC, 16))
    parts += [bx((-2.5, D / 2 + 0.05, top + 1.27), (W - 5.0, 0.6, 0.14), SNOW), bx((W / 2 + 0.05, -2.5, top + 1.27), (0.6, D - 5.0, 0.14), SNOW)]
    zs = [GF + ST * f + ST * 0.52 for f in range(F)]
    parts += win_rows("+y", D / 2, spread(W - 10.0, 3, 0.8), zs, 2.8, 4.8, seed=1, mull=0)
    parts += win_rows("+x", W / 2, [-u for u in spread(D - 10.0, 2, 0.8)], zs, 2.8, 4.8, seed=2, mull=0)
    parts += win_rows("-y", -D / 2, spread(W, 4, 0.8), zs, 2.8, 4.8, simple=True)
    parts += win_rows("-x", -W / 2, spread(D, 3, 0.8), zs, 2.8, 4.8, simple=True)
    for f, z in enumerate(zs):  # drum windows
        for k in range(3):
            a = math.pi / 2 * (k + 0.5) / 3
            parts.append(bx((cx + math.cos(a) * (R - 0.05), cy2 + math.sin(a) * (R - 0.05), z), (2.4, 0.3, 4.8),
                            GLIT if (f + k) % 3 == 0 else GLS, a + math.pi / 2))
            parts.append(bx((cx + math.cos(a) * (R + 0.1), cy2 + math.sin(a) * (R + 0.1), z - 2.55), (2.8, 0.5, 0.25), TRIM, a + math.pi / 2))
    # ground floor arched windows on both street faces
    for n, p, us in (("+y", D / 2, spread(W - 10.0, 4, 0.8)), ("+x", W / 2, spread(D - 10.0, 3, 0.8))):
        for u in us:
            parts += [on_wall(n, p, u, 4.6, 3.6, 0.12, 7.0, 0.06, GLS), on_wall(n, p, u, 8.6, 4.4, 0.4, 1.2, 0.2, CONC)]
    # clock turret on the drum
    tz = top + 1.2
    parts += [bbx((cx, cy2, tz + 3.5), (7.0, 7.0, 7.0), WC, 0.15), bbx((cx, cy2, tz + 7.3), (8.0, 8.0, 0.6), CONC, 0.06),
              usp((cx, cy2, tz + 7.6), 3.4, ROOFB, (1.0, 1.0, 0.9), 14, 7), rcy((cx, cy2, tz + 11.4), 0.2, 1.6, MDK, 8, r2=0.05),
              rcy((cx, cy2, tz + 8.0), 3.45, 0.4, SNOW, 14, r2=2.8)]
    for k, (dx, dy) in enumerate(((0, 1), (1, 0), (0, -1), (-1, 0))):
        ax = "y" if dy else "x"
        fx, fy2 = cx + dx * 3.55, cy2 + dy * 3.55
        parts += [rcy((fx, fy2, tz + 3.6), 2.6, 0.3, WHT, 14, axis=ax), rcy((fx + dx * 0.12, fy2 + dy * 0.12, tz + 3.6), 2.85, 0.2, MDK, 14, axis=ax),
                  bx((fx + dx * 0.25, fy2 + dy * 0.25, tz + 4.4), (0.2, 0.2, 1.7), MDK),
                  bx((fx + dx * 0.25, fy2 + dy * 0.25, tz + 3.6), (1.2 if dy else 0.2, 1.2 if dx else 0.2, 0.2), MDK)]
    parts += door_unit("+y", D / 2, -10.0, 0.0, canopy=None, steps=1)
    parts += drainpipe(-W / 2 + 0.4, D / 2 + 0.4, 0.2, top - 0.2)
    return parts


def midrise_mixed():
    """Mixed-use block: a glazed ground floor of shops with coloured awnings, four floors of flats above with box bay
    windows in pairs, a roof garden pergola and solar panels."""
    W, D, GF, ST, F = 32.0, 18.0, 12.0, 9.6, 4
    top = GF + ST * F
    parts = split_body(W, D, GF, top, WB, MDK)
    parts += parapet(W, D, top, CONC)
    for f in range(F):
        parts += floor_bands(W, D, GF + ST * f + 0.3, CONC, 0.4)
    # shop floor: four glazed units, awnings in accents
    for k, s in enumerate((RED, TEAL, YEL, BLU)):
        u = -W / 2 + W / 4 * (k + 0.5)
        parts += [on_wall("+y", D / 2, u, 4.6, W / 4 - 1.6, 0.12, 7.6, 0.06, GLS), on_wall("+y", D / 2, u, 9.8, W / 4 - 1.0, 0.3, 1.6, 0.15, CONC),
                  pg((u, D / 2, 9.0), [(0.0, 0.0), (2.8, -1.2), (2.8, -1.7), (2.6, -1.7), (0.0, -0.2)], W / 4 - 1.6, s, "y", math.pi / 2),
                  pg((u, D / 2, 9.0), [(0.0, 0.05), (2.8, -1.15), (2.8, -1.05), (0.0, 0.15)], W / 4 - 1.8, SNOW, "y", math.pi / 2)]
        for m in range(3):
            parts.append(on_wall("+y", D / 2, u - (W / 4 - 1.6) / 2 + (W / 4 - 1.6) * (m + 1) / 4, 4.6, 0.2, 0.24, 7.6, 0.14, MDK))
    # flats: box bays in pairs
    zs = [GF + ST * f + ST * 0.52 for f in range(F)]
    for i, z in enumerate(zs):
        for j, u in enumerate((-11.0, -4.0, 4.0, 11.0)):
            if j in (1, 2):
                parts += [bbx((u, D / 2 + 0.9, z), (4.6, 1.8, 6.4), WC, 0.1), on_wall("+y", D / 2 + 1.8, u, z, 3.6, 0.12, 4.8, 0.06, GLIT if lit_of(i, j, 0) else GLS),
                          bx((u, D / 2 + 0.9, z + 3.32), (4.8, 2.0, 0.12), SNOW)]
            else:
                parts += window("+y", D / 2, u, z, 3.0, 4.8, GLIT if lit_of(i, j, 1) else GLS, mull=1)
    parts += win_rows("-y", -D / 2, spread(W, 6, 0.8), zs, 2.8, 4.6, simple=True)
    parts += win_rows("+x", W / 2, spread(D, 3, 0.8), zs, 2.6, 4.6, simple=True)
    parts += win_rows("-x", -W / 2, spread(D, 3, 0.8), zs, 2.6, 4.6, simple=True)
    # roof: pergola and solar panels
    for k in range(4):
        for sy in (-1, 1):
            parts.append(bx((-12.0 + k * 3.0, 3.0 + sy * 2.5, top + 3.2), (0.3, 0.3, 4.0), WOOD))
    for k in range(8):
        parts.append(bx((-7.5, 0.5 + k * 0.7, top + 5.3), (10.0, 0.2, 0.3), WOOD))
    parts += [bx((-7.5, 3.0, top + 5.55), (10.0, 5.0, 0.1), SNOW)]
    for k in range(3):
        parts += [pg((6.0 + k * 0.0, -4.0 + k * 3.2, top + 1.2), [(-1.2, 0), (1.2, 0), (1.2, 0.3), (-1.2, 1.4)], 12.0, MDK, "y", math.pi / 2)]
    parts += drainpipe(-W / 2 + 0.4, -D / 2 - 0.4, 0.2, top - 0.2)
    return parts


# ---------------------------------------------------------------------------------------------- towers (tier 5)
def curtain_wall(n, p, span, z0, z1, cols, rows, glass=GLS, fin=MET, lit_every=6, seed=0):
    """Glass curtain wall: one glass sheet per face with vertical fins and horizontal transoms, a few lit panes."""
    parts = [on_wall(n, p, 0.0, (z0 + z1) / 2, span, 0.12, z1 - z0, 0.04, glass)]
    for c in range(cols + 1):
        parts.append(on_wall(n, p, -span / 2 + span * c / cols, (z0 + z1) / 2, 0.24, 0.5, z1 - z0, 0.25, fin))
    for r in range(rows + 1):
        parts.append(on_wall(n, p, 0.0, z0 + (z1 - z0) * r / rows, span + 0.4, 0.5, 1.0 if 0 < r < rows else 0.4, 0.2, CONC))
    for k in range(cols * rows):
        if (k * 5 + seed) % lit_every == 0:
            c, r = k % cols, k // cols
            parts.append(on_wall(n, p, -span / 2 + span * (c + 0.5) / cols, z0 + (z1 - z0) * (r + 0.5) / rows, span / cols - 0.4,
                                 0.08, (z1 - z0) / rows - 0.4, 0.1, GLIT))
    return parts


def tower_box(W, D, z0, z1, cols_w, cols_d, rows, core=WC, seed=0, cx=0.0, cy2=0.0, sun=True):
    parts = [bbx((cx, cy2, (z0 + z1) / 2), (W, D, z1 - z0), core, 0.2)]
    for n, p, span, cols in (("+y", D / 2, W, cols_w), ("-y", -D / 2, W, cols_w), ("+x", W / 2, D, cols_d), ("-x", -W / 2, D, cols_d)):
        sub = curtain_wall(n, p, span - 1.6, z0 + 0.6, z1 - 0.6, cols, rows, seed=seed + len(n))
        if cx or cy2:
            sub = [shift(part, cx, cy2) for part in sub]
        parts += sub
    if sun:  # sun-shade louvres on the +x face, every floor
        for r in range(rows):
            z = z0 + 0.6 + (z1 - z0 - 1.2) * (r + 0.85) / rows
            parts.append(bx((cx + W / 2 + 0.9, cy2, z), (1.4, D - 2.0, 0.2), MET))
    return parts


def shift(part, dx, dy):
    """Move a bx/bbx/rcy part by (dx, dy)."""
    kind = part[0]
    c = part[1] if kind != "raw" else None
    if kind in ("box", "bbx", "rcy", "usp"):
        c2 = (c[0] + dx, c[1] + dy, c[2])
        return (kind, c2) + part[2:]
    raise ValueError(kind)


def tower_stepped():
    """Glass tower in three setbacks with stone corner piers and band courses at each step, terrace rails on the
    setbacks, a slim mast on the top (the silhouette)."""
    LOB, ST = 12.0, 9.6
    parts = []
    tiers = [(24.0, 20.0, 0.0, LOB + ST * 2), (19.0, 16.0, LOB + ST * 2, LOB + ST * 3.5), (14.0, 12.0, LOB + ST * 3.5, LOB + ST * 4.6)]
    for k, (w, d, z0, z1) in enumerate(tiers):
        rows = max(1, int(round((z1 - z0 - (LOB if k == 0 else 0)) / ST)))
        zz0 = z0 + (LOB if k == 0 else 0.0)
        parts += tower_box(w, d, zz0, z1, 7 if k < 2 else 5, 6 if k < 2 else 4, rows, WC, seed=k)
        for sx in (-1, 1):
            for sy in (-1, 1):
                parts.append(bx((sx * (w / 2 - 0.5), sy * (d / 2 - 0.5), (z0 + z1) / 2), (1.4, 1.4, z1 - z0), CONC))
        parts += [bbx((0, 0, z1 + 0.4), (w + 0.8, d + 0.8, 0.8), CONC, 0.08), bx((0, 0, z1 + 0.86), (w + 0.6, d + 0.6, 0.12), SNOW)]
        if k < 2:
            for j in range(10):
                parts.append(bx((-w / 2 + 0.5 + j * (w - 1) / 9, d / 2 + 0.3, z1 + 1.6), (0.1, 0.1, 1.6), MET))
    parts += [bbx((0, 0, LOB / 2), (24.4, 20.4, LOB), GLS, 0.0)]
    for u in spread(24.0, 5, 0.4):
        parts.append(bbx((u, 10.2, LOB / 2), (1.2, 1.2, LOB), CONC, 0.06))
    parts += [bbx((0, 12.6, LOB - 1.0), (12.0, 5.0, 0.6), CONC, 0.08), bx((0, 12.6, LOB - 0.64), (11.8, 4.8, 0.12), SNOW),
              on_wall("+y", 10.2, 0.0, 3.4, 4.6, 0.14, 6.8, 0.08, GLIT)]
    top = tiers[-1][3] + 0.8
    parts += [bbx((0, 0, top + 1.5), (6.0, 6.0, 3.0), CONC, 0.08), bx((0, 0, top + 3.06), (5.8, 5.8, 0.12), SNOW),
              rcy((0, 0, top + 3.0 + 3.0), 0.35, 6.0, MET, 8, r2=0.12), usp((0, 0, top + 9.1), 0.35, RED, (1, 1, 1), 8, 5)]
    for k in range(3):
        parts += [rcy((-4.5 + k * 1.6, -4.0, top + 1.0), 0.6, 2.0, MET, 12), usp((-4.5 + k * 1.6, -4.0, top + 2.0), 0.6, MET, (1, 1, 0.4), 12, 4)]
    return parts


def tower_twin():
    """Two slender glass towers on a shared podium, joined by a glazed sky bridge two thirds up (the silhouette), each
    with its own plant crown."""
    LOB, ST = 12.0, 9.6
    W, D = 14.0, 13.0
    parts = [bbx((0, 0, LOB / 2), (40.0, 16.0, LOB), WC, 0.2), bbx((0, 0, LOB + 0.4), (40.6, 16.6, 0.8), CONC, 0.08),
             bx((0, 0, LOB + 0.86), (40.4, 16.4, 0.12), SNOW)]
    for u in spread(40.0, 8, 0.6):
        parts += [on_wall("+y", 8.0, u, LOB / 2, 3.6, 0.12, LOB - 3.0, 0.06, GLS)]
    parts += [on_wall("+y", 8.0, 0.0, 3.4, 6.0, 0.14, 6.8, 0.08, GLIT), bbx((0, 10.4, LOB - 2.2), (10.0, 4.8, 0.5), CONC, 0.06),
              bx((0, 10.4, LOB - 1.9), (9.8, 4.6, 0.12), SNOW)]
    for k in range(4):  # planters along the podium front
        x = -16.0 + k * 10.7
        parts += [bbx((x, 9.2, 0.9), (4.0, 1.6, 1.8), CONC, 0.06), usp((x, 9.2, 2.2), 1.2, LEAF if k % 2 else LDK, (1.5, 0.6, 0.8), 10, 6)]
    top = LOB + ST * 4.6
    for side in (-1, 1):
        cx = side * 12.5
        sub = tower_box(W, D, LOB + 0.8, top, 6, 6, 5, WC, seed=side + 3)
        parts += [shift(p, cx, 0.0) for p in sub]
        parts += [bbx((cx, 0, top + 0.4), (W + 0.8, D + 0.8, 0.8), CONC, 0.08), bx((cx, 0, top + 0.86), (W + 0.6, D + 0.6, 0.12), SNOW),
                  bbx((cx, -1.5, top + 3.0), (8.0, 6.0, 4.4), CONC, 0.08), bx((cx, -1.5, top + 5.26), (7.8, 5.8, 0.12), SNOW)]
        for k in range(3):
            parts.append(rcy((cx - 2.0 + 2.0 * k, 3.6, top + 1.6), 0.5, 1.6, MET, 10))
    # sky bridge
    bz = LOB + ST * 3.0
    parts += [bbx((0, 0, bz), (11.2, 6.0, 4.2), GLS, 0.0), bbx((0, 0, bz + 2.3), (11.6, 6.4, 0.5), MET, 0.05),
              bbx((0, 0, bz - 2.3), (11.6, 6.4, 0.5), MET, 0.05), bx((0, 0, bz + 2.6), (11.4, 6.2, 0.12), SNOW)]
    for k in range(6):
        parts.append(bx((-5.0 + k * 2.0, 3.1, bz), (0.2, 0.3, 4.2), MET))
        parts.append(bx((-5.0 + k * 2.0, -3.1, bz), (0.2, 0.3, 4.2), MET))
    parts += [rcy((12.5, -1.5, top + 8.6), 0.3, 6.6, MET, 8, r2=0.1), usp((12.5, -1.5, top + 12.0), 0.4, RED, (1, 1, 1), 8, 5)]
    return parts


def tower_crown():
    """Square glass tower with chamfered corners and a stepped, faceted stone crown with a spire (the silhouette)."""
    LOB, ST = 12.0, 9.6
    W = 20.0
    top = LOB + ST * 4.0
    parts = tower_box(W, W, LOB, top, 7, 7, 4, WC, seed=2)
    for sx in (-1, 1):  # chamfer piers at the corners
        for sy in (-1, 1):
            parts.append(bx((sx * (W / 2 - 0.4), sy * (W / 2 - 0.4), (LOB + top) / 2), (2.0, 2.0, top - LOB), CONC, math.pi / 4))
    for f in range(4):  # wrap-around corner balconies on every floor (rotated slabs on the chamfers)
        z = LOB + 9.6 * f + 0.4
        for sx in (-1, 1):
            for sy in (-1, 1):
                c = (sx * (W / 2 + 0.4), sy * (W / 2 + 0.4))
                parts += [bbx((c[0], c[1], z), (5.0, 2.4, 0.5), CONC, 0.06, sx * sy * -math.pi / 4),
                          bx((c[0] + sx * 0.8, c[1] + sy * 0.8, z + 1.4), (5.0, 0.2, 0.2), MET, sx * sy * -math.pi / 4),
                          bx((c[0] + sx * 0.8, c[1] + sy * 0.8, z + 0.85), (5.0, 0.1, 1.0), GLS, sx * sy * -math.pi / 4),
                          bx((c[0], c[1], z + 0.31), (4.8, 2.2, 0.1), SNOW, sx * sy * -math.pi / 4)]
    parts += [bbx((0, 0, LOB / 2), (W + 0.4, W + 0.4, LOB), CONC, 0.12)]
    for n, p in (("+y", W / 2), ("-y", -W / 2), ("+x", W / 2), ("-x", -W / 2)):
        parts += [on_wall(n, p + (0.2 if n[0] == "+" else -0.2), 0.0, LOB * 0.45, W - 4.0, 0.12, LOB * 0.7, 0.08, GLS)]
        for u in spread(W - 4.0, 4, 0.0):
            parts.append(on_wall(n, p, u + (W - 4.0) / 8, LOB * 0.45, 0.3, 0.3, LOB * 0.7, 0.16, MET))
    parts += [on_wall("+y", W / 2 + 0.2, 0.0, 3.4, 4.6, 0.14, 6.8, 0.12, GLIT), bbx((0, W / 2 + 2.0, LOB - 1.4), (10.0, 4.0, 0.5), CONC, 0.06),
              bx((0, W / 2 + 2.0, LOB - 1.08), (9.8, 3.8, 0.12), SNOW)]
    # crown: three stepped drums of decreasing size with fins, then a pyramid and spire
    z = top
    for k, (w, h) in enumerate(((W + 0.6, 1.0), (W - 3.0, 3.4), (W - 7.0, 3.0), (W - 11.0, 2.6))):
        parts += [bbx((0, 0, z + h / 2), (w, w, h), CONC, 0.1), bx((0, 0, z + h + 0.06), (w - 0.2, w - 0.2, 0.12), SNOW)]
        if k:
            for n, p in (("+y", w / 2), ("-y", -w / 2), ("+x", w / 2), ("-x", -w / 2)):
                for u in spread(w - 1.0, 3, 0.0):
                    parts.append(on_wall(n, p, u, z + h / 2, 0.5, 0.6, h - 0.4, 0.3, GLIT if k == 3 else MET))
        z += h
    parts += [rcy((0, 0, z + 2.4), 4.6, 4.8, ROOFB, 4, r2=0.0, yaw=math.pi / 4), rcy((0, 0, z + 6.4), 0.3, 3.4, MET, 8, r2=0.05)]
    return parts


SHOP_SIGN = {
    "ck_shop_bakery": ["sign_11"], "ck_shop_grocer": ["sign_00"], "ck_shop_pizzeria": ["sign_01"],
    "ck_shop_cafe": ["sign_09"], "ck_shop_bookshop": ["sign_03"], "ck_shop_pharmacy_cross": ["sign_10"],
    "ck_shop_row_arcade": ["sign_06", "sign_03", "sign_04", "sign_08"],
    "ck_shop_row_corner": ["sign_00", "sign_02", "sign_05", "sign_07"],
}

RECIPES.update({
    "ck_house_semi_garage": house_semi_garage, "ck_house_bungalow": house_bungalow,
    "ck_house_corner_bay": house_corner_bay, "ck_house_terrace_pair": house_terrace_pair,
    "ck_house_split_level": house_split_level,
    "ck_shop_bakery": shop_bakery, "ck_shop_grocer": shop_grocer, "ck_shop_pizzeria": shop_pizzeria,
    "ck_shop_cafe": shop_cafe, "ck_shop_bookshop": shop_bookshop, "ck_shop_pharmacy_cross": shop_pharmacy_cross,
    "ck_shop_row_arcade": shop_row_arcade, "ck_shop_row_corner": shop_row_corner,
    "ck_midrise_brick_8": midrise_brick_8, "ck_midrise_render_10": midrise_render_10,
    "ck_midrise_setback": midrise_setback, "ck_midrise_courtyard": midrise_courtyard,
    "ck_midrise_corner_clock": midrise_corner_clock, "ck_midrise_mixed": midrise_mixed,
    "ck_tower_stepped": tower_stepped, "ck_tower_twin": tower_twin, "ck_tower_crown": tower_crown,
})
