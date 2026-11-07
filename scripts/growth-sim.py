#!/usr/bin/env python3
"""Growth economy simulator for the Park City level design (docs/design/09-park-city-level.md, section 3).

Stdlib only, deterministic. It answers: with this much food, placed this way, how big does a weak, a median, a
skilled and an expert player get in one run, and how big does a player get who ignores every challenge?

Model (simple on purpose; the real check is the in-game pace test and the owner's play):
- The map is a list of food pools (data below). A pool is one place: a doorstep, a trail, a set piece. Each has the
  bulk sizes of its objects, the seconds per pickup while you are in it (dense = fast), the seconds it costs to get
  in (travel plus the challenge), the skill it needs (0 open, 1 a jump or a rail, 2 the brave route), and whether
  other players compete for it.
- A player eats greedily: every step it picks the pool with the best growth per second over the next 12 s, counting
  the cost to get there, and eats the biggest object it can (bulk <= ratio * D) or the one that grows it most.
- Growth: D^3 <- D^3 + k * bulk^3, but objects under `garnishRatio * D` give nothing (they are "crushed").
- Bumps: each profile loses a share of volume per minute (knock-offs from careless rolling).
- Counts in the pools are the share ONE player can expect when 12 play; `contested` pools scale by the profile's
  share (good players take more of a shared set piece).

Run: python3 scripts/growth-sim.py [--run 300]   (prints the tables used in the design doc; --run sets the run length)
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

START_D = 1.0
RATIO = 0.5  # edible when bulk <= RATIO * D
GARNISH = 0.08  # objects under GARNISH * D give no growth
K = 1.6
RUN = 240.0
STEP = 0.1


def logspread(lo: float, hi: float, n: int) -> list[float]:
    if n == 1:
        return [math.sqrt(lo * hi)]
    return [lo * (hi / lo) ** (i / (n - 1)) for i in range(n)]


@dataclass
class Pool:
    name: str
    sizes: list[float]
    interval: float  # seconds per pickup in this pool
    access: float  # seconds to get in from the previous area (travel + challenge)
    skill: int = 0
    contested: bool = False
    left: list[float] = field(default_factory=list)


def pools() -> list[Pool]:
    P = Pool
    return [
        # Sizes are BULK (cube root of the bounding-box volume), see the design doc section 3.
        # Tier 1 Crumb (D 1 to 2.5) and Tier 2 Pocket (D 2.5 to 6): the park floor of the player's own quarter
        P("doorstep", logspread(0.25, 0.5, 20), 0.7, 0),
        P("park trails", logspread(0.3, 1.1, 50), 1.8, 0),
        P("mushroom glade / flower beds", logspread(0.5, 1.3, 22), 0.8, 8, 0, True),
        P("duck island / tree house", logspread(1.4, 3.0, 20), 0.7, 14, 1, True),
        # Tier 3 Picnic (D 6 to 15): park kit
        P("park kit (picnic lawn, paths)", logspread(1.35, 4.5, 36), 2.0, 6),
        P("hedge maze walls", [2.6] * 16, 0.8, 10, 0, True),
        P("skate park / playground", logspread(3.0, 7.5, 18), 0.8, 14, 1, True),
        # Tier 4 Street (D 15 to 35): street kit and the first cars
        P("gate corners / ring road", logspread(5.0, 11.0, 20), 2.2, 15),
        P("roof run", logspread(6.5, 15.0, 22), 0.9, 18, 2, True),
        P("yards and market street", logspread(6.0, 12.0, 14), 2.0, 10),
        # Tier 5 House (D 35 to 80)
        P("neighbourhood cars / sheds", logspread(12.0, 24.0, 12), 2.4, 10),
        P("car park decks / crane", logspread(16.0, 36.0, 12), 1.4, 16, 1, True),
        P("cottages and shops", logspread(22.0, 40.0, 7), 2.6, 8, 0, True),
        # Tier 6 Skyline (D 80 to 150): scarce, about 50 objects for the whole server
        P("downtown terraces and blocks", logspread(36.0, 60.0, 4), 3.0, 10, 0, True),
        P("sky rail / glass tower", logspread(55.0, 75.0, 2), 2.0, 14, 2, True),
    ]


@dataclass
class Profile:
    name: str
    pace: float  # multiplier on seconds per pickup and access time
    skill: int
    share: float  # share of contested pools
    loss_per_min: float  # volume share lost to bumps per minute
    ignore_challenges: bool = False


PROFILES = [
    Profile("weak (new player)", 1.6, 0, 0.6, 0.035),
    Profile("median", 1.15, 1, 0.9, 0.02),
    Profile("median, skips every challenge", 1.15, 1, 0.9, 0.02, True),
    Profile("skilled", 0.9, 2, 1.2, 0.01),
    Profile("expert, best route", 0.75, 2, 1.5, 0.004),
]


def best_bite(pool: Pool, d: float) -> float | None:
    edible = [s for s in pool.left if s <= RATIO * d]
    return max(edible) if edible else None


def growth(d: float, s: float) -> float:
    if s < GARNISH * d:
        return d
    return (d**3 + K * s**3) ** (1 / 3)


def simulate(p: Profile) -> list[tuple[float, float]]:
    ps = pools()
    for pool in ps:
        n = len(pool.sizes)
        keep = round(n * (p.share if pool.contested else 1.0))
        # Keep the share spread across the sizes.
        idx = sorted({min(n - 1, int(i * n / max(keep, 1))) for i in range(keep)})
        pool.left = [pool.sizes[i] for i in idx] if keep > 0 else []
    t, d = 0.0, START_D
    current: Pool | None = None
    marks = []
    next_mark = 0.0
    while t <= RUN:
        if t >= next_mark:
            marks.append((next_mark, d))
            next_mark += 30
        best, best_rate = None, 0.0
        for pool in ps:
            if pool.skill > p.skill or (p.ignore_challenges and pool.skill > 0):
                continue
            bite = best_bite(pool, d)
            if bite is None:
                continue
            access = 0 if pool is current else pool.access * p.pace
            per = pool.interval * p.pace
            # Growth over the next 12 s in this pool (rough: repeat the best bite).
            horizon = max(12.0, access + 8.0)
            bites = max(0.0, (horizon - access) / per)
            n = min(bites, sum(1 for s in pool.left if s <= RATIO * d and s >= GARNISH * d))
            gain = growth(d, bite) ** 3 - d**3
            rate = n * gain / horizon
            if rate > best_rate:
                best, best_rate = pool, rate
        if best is None:
            t += STEP
            d = max(START_D, d * (1 - p.loss_per_min / 3 * STEP / 60))
            continue
        if best is not current:
            t += best.access * p.pace
            current = best
        bite = best_bite(best, d)
        best.left.remove(bite)
        dt = best.interval * p.pace
        t += dt
        d = growth(d, bite)
        d *= (1 - p.loss_per_min * dt / 60) ** (1 / 3)
    while next_mark <= RUN:
        marks.append((next_mark, d))
        next_mark += 30
    return marks


def main() -> None:
    import sys

    global RUN
    if "--run" in sys.argv:
        RUN = float(sys.argv[sys.argv.index("--run") + 1])
    print(f"start D {START_D}, edible when bulk <= {RATIO} x D, k {K}, garnish < {GARNISH} x D gives nothing\n")
    header = "| Player | " + " | ".join(f"{int(m // 60)}:{int(m % 60):02d}" for m in range(0, int(RUN) + 1, 30)) + " |"
    print(header)
    print("|" + " --- |" * (header.count("|") - 1))
    for p in PROFILES:
        marks = simulate(p)
        print(f"| {p.name} | " + " | ".join(f"{d:.1f}" for _, d in marks) + " |")


if __name__ == "__main__":
    main()
