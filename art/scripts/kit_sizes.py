# Write real-scale sizes into src/shared/Content/CityKit.luau from a kit_rework.py "natural" report (013 Phase 9, T076;
# research R-18). A natural run builds each recipe at its authoring scale (1 m = 3.2 studs) and reports its dims; this
# sets each object's size to its longest side, clamped into its tier band (Config: T1 0.3-1.5, T2 1.6-3.9, T3 4.2-9.8,
# T4 10-25, T5 26-60), scales the dims to match and recomputes bulk (cube root of the bounding-box volume, as
# Absorb.bulkOf). Then run `lune run scripts/art-sync` so art/scripts/budgets.json follows.
#   python3 art/scripts/kit_sizes.py <report.json> [<report.json> ...]
# Standard library only.

import json
import os
import re
import sys

BANDS = {1: (0.3, 1.5), 2: (1.6, 3.9), 3: (4.2, 9.8), 4: (10.0, 25.0), 5: (26.0, 60.0)}
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
CITYKIT = os.path.join(ROOT, "src", "shared", "Content", "CityKit.luau")


def num(v):
    text = f"{v:.2f}".rstrip("0").rstrip(".")
    return text


def main(paths):
    rows = []
    for path in paths:
        rows += json.load(open(path, encoding="utf-8"))
    text = open(CITYKIT, encoding="utf-8").read()
    changed = []
    for row in rows:
        key = row["id"][3:]
        lo, hi = BANDS[row["tier"]]
        dims = row["dims"]
        longest = max(dims)
        size = round(min(max(longest, lo), hi), 1)
        scale = size / longest
        new_dims = [max(0.05, round(d * scale, 1)) for d in dims]  # flat decals keep a sliver of height
        new_dims[dims.index(longest)] = size
        bulk = round((new_dims[0] * new_dims[1] * new_dims[2]) ** (1 / 3), 2)
        block = re.search(r'\{\n\t\tid = "' + re.escape(key) + r'",.*?\n\t\}', text, re.S)
        if block is None:
            raise SystemExit(f"{key}: no entry in CityKit.luau")
        old = block.group(0)
        new = re.sub(r"\n\t\tsize = [0-9.]+,", f"\n\t\tsize = {num(size)},", old)
        new = re.sub(r"\n\t\tdims = \{[^}]*\},", "\n\t\tdims = { " + ", ".join(num(d) for d in new_dims) + " },", new)
        new = re.sub(r"\n\t\tbulk = [0-9.]+,", f"\n\t\tbulk = {num(bulk)},", new)
        text = text.replace(old, new)
        changed.append(f"{key}: size {num(size)} (scale {scale:.2f}), dims {new_dims}, bulk {bulk}")
    open(CITYKIT, "w", encoding="utf-8").write(text)
    print("\n".join(changed))


if __name__ == "__main__":
    main(sys.argv[1:])
