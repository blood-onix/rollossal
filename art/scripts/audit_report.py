#!/usr/bin/env python3
"""Audit report for the 99 dt_* meshes (013 US1; specs/013-city-asset-kit/contracts/audit-and-asset-list.md).

Standard library only. Inputs: art/export/manifest.json, art/scripts/budgets.json, <audit>/render-data.json (written by
audit_render.py through Blender) and the winter-city triangle totals from `lune run scripts/audit-headroom`.

  python3 art/scripts/audit_report.py                 write audit.json and audit.md from the inputs
  python3 art/scripts/audit_report.py --check FILE    validate FILE (audit.json); exit 1 on any failure
  python3 art/scripts/audit_report.py --rework        Phase 9 (T078): audit-rework.json and audit-rework.md from
                                                      <audit>/rework/render-data.json with the 2026-11-07 rules

Verdict rule (research R-02), triangles only: replace under 0.35 of the floor, upgrade from 0.35 to under 1.0, keep at
1.0 or more with w-season under 15 % in both themes. A keep with a heavy w-season share moves one step to upgrade.
`audit/overrides.json` ({id: {"verdict": ..., "reason": ...}}) records a visual-pass change of one step.
"""

import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AUDIT_DIR = os.path.join(ROOT, "specs", "013-city-asset-kit", "audit")
TIER_FLOORS = [150, 210, 450, 1050, 1500]
TIER_TARGETS = [200, 300, 600, 1400, 2200]
FLAT_IDS = {"dt_snow_pile", "dt_ice_rink"}
UNCULLED_CEILING = 550000
CULLED_CEILING = 290000
SEASON_LIMIT = 0.15
STEPS = ["replace", "upgrade", "keep"]
THEMES = ("city", "winter")
BASELINE = {"keep": 12, "upgrade": 36, "replace": 51}


# rebuilt below the audit floor because the N10 ceilings run out (art/scripts/dt_upgrade.py CAPPED); needs only > baseline
CAPPED = ("dt_kiosk",)
# baseline "keep" meshes rebuilt on purpose by the Phase 9 rework (art/scripts/kit_stage_c.py, the pocket set): they no
# longer match the baseline count and only have to stay at or above their floor
REWORKED = ("dt_fairy_light_bulb", "dt_ice_lolly", "dt_tennis_ball")


def load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def floor_class(mesh_id, tier, size):
    if mesh_id in FLAT_IDS:
        return "flat", 24
    if size <= 0.8:
        return "pocket", 40
    return "tier", TIER_FLOORS[tier - 1]


def target_for(tier, budget):
    return min(TIER_TARGETS[tier - 1], int(budget * 0.6))


def baseline_verdict(fill, season):
    if fill < 0.35:
        return "replace"
    if fill < 1.0:
        return "upgrade"
    return "keep" if max(season.values()) < SEASON_LIMIT else "upgrade"


def headroom():
    out = subprocess.run(["lune", "run", "scripts/audit-headroom"], cwd=ROOT, capture_output=True, text=True, check=True)
    return json.loads(out.stdout.strip().splitlines()[-1])


def build():
    manifest = {m["id"]: m for m in load(os.path.join(ROOT, "art", "export", "manifest.json"))["meshes"]}
    budgets = load(os.path.join(ROOT, "art", "scripts", "budgets.json"))
    render = load(os.path.join(AUDIT_DIR, "render-data.json"))
    overrides_path = os.path.join(AUDIT_DIR, "overrides.json")
    overrides = load(overrides_path) if os.path.isfile(overrides_path) else {}
    meshes = []
    for mesh_id in sorted(k for k in manifest if k.startswith("dt_")):
        tier = budgets["tiers"][mesh_id]
        size = budgets["sizes"][mesh_id]
        tris = manifest[mesh_id]["triangles"]
        cls, floor = floor_class(mesh_id, tier, size)
        fill = round(tris / floor, 3)
        data = render["meshes"][mesh_id]
        verdict = baseline_verdict(fill, data["seasonShare"])
        if fill >= 1.0 and verdict == "upgrade":
            reason = (f"w-season covers {max(data['seasonShare'].values()):.0%} of the surface, over the 15% limit "
                      f"of the style bible, so the mesh is rebuilt with the season colour as trim only.")
        elif verdict == "replace":
            reason = (f"{tris} triangles is {fill:.2f} of the {cls} floor {floor} (under 0.35), so the silhouette "
                      f"cannot meet the style bible and is rebuilt from a new recipe.")
        elif verdict == "upgrade":
            reason = (f"{tris} triangles is {fill:.2f} of the {cls} floor {floor}; the silhouette is kept and "
                      f"rebuilt with bevels and detail up to the floor-to-target band.")
        else:
            reason = f"{tris} triangles meets the {cls} floor {floor} and w-season stays under 15%."
        entry = {
            "id": mesh_id, "tier": tier, "size": size, "triangles": tris,
            "tierBudget": budgets["meshTriangles"][tier - 1], "floorClass": cls, "floor": floor,
            "fillRatio": fill, "baselineVerdict": verdict, "seasonShare": data["seasonShare"],
            "verdict": verdict, "reason": reason, "renders": data["renders"],
        }
        if mesh_id in overrides:
            entry["verdict"] = overrides[mesh_id]["verdict"]
            entry["reason"] = overrides[mesh_id]["reason"]
        meshes.append(entry)
    totals = headroom()
    projected_unculled, projected_culled = totals["unculled"], totals["culled"]
    floor_unculled, floor_culled = totals["unculled"], totals["culled"]
    by_id = {m["id"]: m for m in meshes}
    for key, count in totals["placements"].items():
        m = by_id.get(key)
        if m and m["verdict"] != "keep":
            extra = (target_for(m["tier"], m["tierBudget"]) - m["triangles"]) * count
            if extra > 0:
                projected_unculled += extra
                if m["tier"] >= 4:
                    projected_culled += extra
            extra = (m["floor"] - m["triangles"]) * count
            if extra > 0:
                floor_unculled += extra
                if m["tier"] >= 4:
                    floor_culled += extra
    return {
        "version": 1, "blender": render["blender"],
        "headroom": {"unculledCeiling": UNCULLED_CEILING, "culledCeiling": CULLED_CEILING,
                     "unculled": totals["unculled"], "culled": totals["culled"],
                     "projectedUnculled": projected_unculled, "projectedCulled": projected_culled,
                     "atFloorUnculled": floor_unculled, "atFloorCulled": floor_culled},
        "meshes": meshes,
    }


def counts(meshes):
    result = {"keep": 0, "upgrade": 0, "replace": 0}
    for m in meshes:
        result[m["verdict"]] += 1
    return result


def write_md(audit, path):
    h = audit["headroom"]
    c = counts(audit["meshes"])
    lines = [
        "# Audit of the 99 dt_* meshes (013 US1)", "",
        f"Verdicts: **{c['keep']} keep, {c['upgrade']} upgrade, {c['replace']} replace** "
        f"(triangle-only baseline {BASELINE['keep']} / {BASELINE['upgrade']} / {BASELINE['replace']}). "
        "Class floors: pocket 40, flat 24, tier 150 / 210 / 450 / 1,050 / 1,500 (style bible section 11). "
        "`seasonShare` is the area share of w-season UVs; it depends on the mesh only, so city and winter match.", "",
        "## Headroom (winter city, Downtown N10 sum)", "",
        "| | Now | Every upgrade and replacement at its floor | At its target | Ceiling |",
        "| --- | --- | --- | --- | --- |",
        f"| Unculled | {h['unculled']:,} | {h['atFloorUnculled']:,} | {h['projectedUnculled']:,} | "
        f"{h['unculledCeiling']:,} |",
        f"| Culled (tier 4 and 5) | {h['culled']:,} | {h['atFloorCulled']:,} | {h['projectedCulled']:,} | "
        f"{h['culledCeiling']:,} |", "",
        "Reading: this is the 013 finding on scene cost. Rebuilding every non-keep mesh to its floor already exceeds "
        "the unculled or culled ceiling when the table above says so, so the upgrades cannot all land at once. "
        "They are built highest-visibility first, Downtown N10 is re-run after each batch and the order stops when the "
        "headroom runs out (research R-03); the ceilings are not raised. The heaviest placed meshes are the kiosk, "
        "taxi, corner bakery, apartment block, townhouse and the hatchback, van and pickup.", "",
        "## Meshes", "",
        "| Id | Tier | Size | Tris | Budget | Class | Floor | Fill | Season | Verdict | Reason |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for m in audit["meshes"]:
        lines.append(f"| `{m['id']}` | {m['tier']} | {m['size']} | {m['triangles']} | {m['tierBudget']} | "
                     f"{m['floorClass']} | {m['floor']} | {m['fillRatio']} | {max(m['seasonShare'].values()):.2f} | "
                     f"{m['verdict']} | {m['reason']} |")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def check(path):
    audit = load(path)
    base = os.path.dirname(path)
    manifest = {m["id"]: m for m in load(os.path.join(ROOT, "art", "export", "manifest.json"))["meshes"]}
    budgets = load(os.path.join(ROOT, "art", "scripts", "budgets.json"))
    errors = []
    expected = sorted(k for k in manifest if k.startswith("dt_"))
    ids = [m["id"] for m in audit["meshes"]]
    if len(expected) != 99:
        errors.append(f"manifest has {len(expected)} dt_ meshes, expected 99")
    if sorted(ids) != expected:
        errors.append("meshes do not match the manifest dt_ ids exactly once each")
    for m in audit["meshes"]:
        i = m["id"]
        if i not in manifest:
            continue
        # audit.json is the pre-rebuild baseline: keep meshes still match the manifest exactly, a rebuilt mesh must
        # have grown to at least its floor (a capped one only has to have grown)
        now = manifest[i]["triangles"]
        if m["verdict"] == "keep" and i in REWORKED:
            if now < m["floor"]:
                errors.append(f"{i}: reworked mesh under the floor {m['floor']}")
        elif m["verdict"] == "keep":
            if m["triangles"] != now:
                errors.append(f"{i}: triangles differ from the manifest")
        elif i in CAPPED:
            if now <= m["triangles"]:
                errors.append(f"{i}: capped mesh was not rebuilt (manifest {now})")
        elif now < m["floor"]:
            errors.append(f"{i}: manifest triangles {now} are under the floor {m['floor']}")
        if m["tier"] != budgets["tiers"].get(i) or m["size"] != budgets["sizes"].get(i):
            errors.append(f"{i}: tier or size differ from budgets.json")
        if m["tierBudget"] != budgets["meshTriangles"][m["tier"] - 1]:
            errors.append(f"{i}: tierBudget wrong")
        if m["floorClass"] not in ("pocket", "flat", "panel", "tier"):
            errors.append(f"{i}: floorClass {m['floorClass']}")
        elif m["floor"] not in (40, 24, 150) and m["floor"] != TIER_FLOORS[m["tier"] - 1]:
            errors.append(f"{i}: floor {m['floor']}")
        if m["floorClass"] == "pocket" and m["size"] > 0.8:
            errors.append(f"{i}: pocket needs size <= 0.8")
        if abs(m["fillRatio"] - m["triangles"] / m["floor"]) > 0.001:
            errors.append(f"{i}: fillRatio is not triangles / floor")
        if m["verdict"] not in STEPS:
            errors.append(f"{i}: verdict {m['verdict']}")
            continue
        if m["verdict"] == "keep" and (m["fillRatio"] < 1 or any(m["seasonShare"][t] >= SEASON_LIMIT for t in THEMES)):
            errors.append(f"{i}: keep needs fillRatio >= 1 and seasonShare under 0.15 in both themes")
        if m["verdict"] != "keep" and len(m.get("reason", "")) < 40:
            errors.append(f"{i}: reason shorter than 40 characters")
        step = abs(STEPS.index(m["verdict"]) - STEPS.index(m["baselineVerdict"]))
        if step > 1:
            errors.append(f"{i}: verdict differs from the baseline by more than one step")
        for theme in THEMES:
            if not os.path.isfile(os.path.join(base, m["renders"][theme])):
                errors.append(f"{i}: missing render {m['renders'][theme]}")
    h = audit["headroom"]
    if h["unculled"] > h["unculledCeiling"] or h["culled"] > h["culledCeiling"]:
        errors.append("headroom over a ceiling")
    if h["unculledCeiling"] != UNCULLED_CEILING or h["culledCeiling"] != CULLED_CEILING:
        errors.append("headroom ceilings differ from 009")
    if h.get("atFloorUnculled", 0) > UNCULLED_CEILING or h.get("atFloorCulled", 0) > CULLED_CEILING:
        print("audit: note: every rebuilt mesh at its floor would exceed a scene ceiling; upgrade in batches (R-03)")
    if errors:
        print("audit: FAILED")
        for error in errors:
            print("  " + error)
        return 1
    c = counts(audit["meshes"])
    print(f"audit: OK: {len(ids)} meshes, {c['keep']} keep, {c['upgrade']} upgrade, {c['replace']} replace")
    return 0


# Phase 9 (T078): the tween-appeal rules of the style bible, sections 2 and 3 (owner decision 2026-11-07).
BUILDINGS = {"dt_apartment_block", "dt_cinema", "dt_corner_bakery", "dt_corner_shop_row", "dt_glass_tower",
             "dt_glass_tower_bow", "dt_townhouse", "dt_kiosk"}
# Props built from boxes and panels on purpose: no round part, so smooth shading is not asked of them.
BOXY = {"dt_shipping_container", "dt_pallet_stack", "dt_vending_machine", "dt_recycling_bank", "dt_newspaper_box",
        "dt_billboard", "dt_arcade_cabinet", "dt_puzzle_cube", "dt_gift_box", "dt_mini_gift", "dt_suitcase",
        "dt_takeout_box", "dt_pizza_box_tower", "dt_leaning_present_stack", "dt_market_stall", "dt_bus_shelter",
        "dt_ice_rink", "dt_ev_charging_station", "dt_snow_pile", "dt_aa_battery", "dt_keyboard"}
MUTED_MIN = 0.70
SMOOTH_MIN = 0.15
CEILING_SHARE = 0.60


def rework_build():
    manifest = {m["id"]: m for m in load(os.path.join(ROOT, "art", "export", "manifest.json"))["meshes"]}
    budgets = load(os.path.join(ROOT, "art", "scripts", "budgets.json"))
    render = load(os.path.join(AUDIT_DIR, "rework", "render-data.json"))
    meshes = []
    for mesh_id in sorted(k for k in manifest if k.startswith("dt_")):
        tier = budgets["tiers"][mesh_id]
        ceiling = budgets["meshTriangles"][tier - 1]
        tris = manifest[mesh_id]["triangles"]
        data = render["meshes"][mesh_id]
        building = mesh_id in BUILDINGS
        hero = not building and tier >= 4 and mesh_id not in FLAT_IDS
        cls, floor = floor_class(mesh_id, tier, budgets["sizes"][mesh_id])
        need = max(floor, int(ceiling * CEILING_SHARE)) if (building and tier >= 3) or hero else floor
        fails = []
        if tris < need:
            what = "60 % of the tier ceiling" if need > floor else f"the {cls} floor"
            fails.append(f"{tris} triangles is {tris / ceiling:.0%} of the {ceiling} ceiling, under {what} ({need})")
        if building and data["mutedShare"] < MUTED_MIN:
            fails.append(f"muted share {data['mutedShare']:.0%} is under the 70 % building rule")
        if mesh_id not in BOXY and not building and data["smoothShare"] < SMOOTH_MIN:
            fails.append(f"round parts are flat-shaded (smooth share {data['smoothShare']:.0%})")
        season = max(data["seasonShare"].values())
        if season >= SEASON_LIMIT:
            fails.append(f"w-season covers {season:.0%}, over 15 %")
        if tris < need * 0.35:
            verdict = "replace"
        elif fails:
            verdict = "upgrade"
        else:
            verdict = "keep"
        if verdict == "keep":
            reason = "meets every 2026-11-07 rule that applies"
        else:
            reason = "; ".join(fails) + (": rebuilt from a new kit_rework recipe" if verdict == "replace"
                                         else ": silhouette kept, rebuilt smooth and to the triangle target")
        meshes.append({
            "id": mesh_id, "tier": tier, "triangles": tris, "tierBudget": ceiling, "ceilingUse": round(tris / ceiling, 3),
            "role": "building" if building else ("hero" if hero else "prop"), "need": need,
            "mutedShare": data["mutedShare"], "smoothShare": data["smoothShare"], "seasonShare": data["seasonShare"],
            "verdict": verdict, "reason": reason, "renders": {t: "rework/" + data["renders"][t] for t in THEMES},
        })
    totals = headroom()
    by_id = {m["id"]: m for m in meshes}
    unculled, culled = totals["unculled"], totals["culled"]
    for key, count in totals["placements"].items():
        m = by_id.get(key)
        if m and m["triangles"] < m["need"]:
            extra = (m["need"] - m["triangles"]) * count
            unculled += extra
            if m["tier"] >= 4:
                culled += extra
    return {
        "version": 1, "rules": "style bible sections 2 and 3, owner decision 2026-11-07", "blender": render["blender"],
        "headroom": {"unculledCeiling": UNCULLED_CEILING, "culledCeiling": CULLED_CEILING,
                     "unculled": totals["unculled"], "culled": totals["culled"],
                     "atNeedUnculled": unculled, "atNeedCulled": culled},
        "meshes": meshes,
    }


def rework_md(audit, path):
    h = audit["headroom"]
    c = counts(audit["meshes"])
    over = h["atNeedUnculled"] > h["unculledCeiling"] or h["atNeedCulled"] > h["culledCeiling"]
    lines = [
        "# Rework audit of the 99 dt_* meshes (013 Phase 9, T078)", "",
        f"Rules: {audit['rules']}. Buildings need a 70 % muted share; tier 3 to 5 buildings and tier 4 to 5 hero props "
        "need 60 % of the tier ceiling; props with round parts must be smooth-shaded (boxy props are exempt); w-season "
        "stays under 15 %. Replace when the mesh is under 0.35 of what it needs.", "",
        f"Verdicts: **{c['keep']} keep, {c['upgrade']} upgrade, {c['replace']} replace**.", "",
        "## Headroom (winter city, Downtown N10 sum)", "",
        "| | Now | Every placed mesh at what it needs | Ceiling |", "| --- | --- | --- | --- |",
        f"| Unculled | {h['unculled']:,} | {h['atNeedUnculled']:,} | {h['unculledCeiling']:,} |",
        f"| Culled (tier 4 and 5) | {h['culled']:,} | {h['atNeedCulled']:,} | {h['culledCeiling']:,} |", "",
        ("Reading: raising every placed mesh to what the new rules ask exceeds a Downtown N10 ceiling, so the rebuilds "
         "go in batches, highest-visibility first, and stop where the headroom runs out (research R-03); the ceilings "
         "are not raised." if over else
         "Reading: every placed mesh fits under the Downtown N10 ceilings at what the new rules ask."), "",
        "## Meshes", "",
        "| Id | Tier | Role | Tris | % of ceiling | Needs | Muted | Smooth | Verdict | Reason |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for m in audit["meshes"]:
        lines.append(f"| `{m['id']}` | {m['tier']} | {m['role']} | {m['triangles']} | {m['ceilingUse']:.0%} | "
                     f"{m['need']} | {m['mutedShare']:.0%} | {m['smoothShare']:.0%} | {m['verdict']} | {m['reason']} |")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def rework_main():
    audit = rework_build()
    with open(os.path.join(AUDIT_DIR, "audit-rework.json"), "w", encoding="utf-8") as handle:
        json.dump(audit, handle, indent=2)
        handle.write("\n")
    rework_md(audit, os.path.join(AUDIT_DIR, "audit-rework.md"))
    print(f"audit: wrote audit-rework.json and audit-rework.md: {counts(audit['meshes'])}, headroom {audit['headroom']}")
    return 0


def main():
    if "--rework" in sys.argv:
        return rework_main()
    if "--check" in sys.argv:
        return check(sys.argv[sys.argv.index("--check") + 1])
    audit = build()
    with open(os.path.join(AUDIT_DIR, "audit.json"), "w", encoding="utf-8") as handle:
        json.dump(audit, handle, indent=2)
        handle.write("\n")
    write_md(audit, os.path.join(AUDIT_DIR, "audit.md"))
    c = counts(audit["meshes"])
    print(f"audit: wrote audit.json and audit.md: {c}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
