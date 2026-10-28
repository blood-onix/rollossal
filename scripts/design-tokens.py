# Writes docs/design/tokens.css (CSS variables: :root is the first theme, [data-theme="<id>"] overrides the
# world colours) and docs/design/tokens.md (the same values as tables) from docs/design/tokens.json.
# The previews in docs/design/components link tokens.css, so rerun this after any change to the JSON.
# Also rewrites the GENERATED PALETTES block in src/shared/Content/Themes.luau: theme id -> cell name ->
# { r, g, b } for the 32 w-* tokens, the 32 color.hero cells (refs resolved per theme) and the three
# light-* cells, one cell per line so StyLua leaves it alone.
# Run: python3 scripts/design-tokens.py
# Run: python3 scripts/design-tokens.py --check   (compare in memory; exit 1 on the first difference;
#                                                  nothing is written)
# Validation (exit 2): not exactly 32 w-* tokens, not exactly 32 color.hero entries, a ref to an
# unknown role, or a bad hex value.

import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DESIGN = os.path.join(ROOT, "docs", "design")
THEMES_PATH = os.path.join(ROOT, "src", "shared", "Content", "Themes.luau")

BEGIN_MARK = "-- BEGIN GENERATED PALETTES (scripts/design-tokens.py)"
END_MARK = "-- END GENERATED PALETTES (scripts/design-tokens.py)"

tokens = json.load(open(os.path.join(DESIGN, "tokens.json")))
themes = tokens["color"]["themes"]
first = themes[0]["id"]
heroes = tokens["color"]["hero"]
worldTokens = [t for t in tokens["color"]["tokens"] if t["name"].startswith("w-")]
worldByName = {t["name"]: t for t in worldTokens}
lightByName = {
    t["name"]: t
    for t in tokens["color"]["tokens"]
    if t["name"] in ("light-sky", "light-fog", "light-ambient")
}


def fail(message, code=2):
    sys.stderr.write(f"design-tokens: {message}\n")
    sys.exit(code)


def parse_hex(text):
    text = text.strip().lstrip("#")
    if len(text) != 6:
        fail(f"bad hex colour {text!r}")
    try:
        return (int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16))
    except ValueError:
        fail(f"bad hex colour {text!r}")


if len(worldTokens) != 32:
    fail(f"expected exactly 32 w-* tokens in color.tokens, found {len(worldTokens)}")
if len(heroes) != 32:
    fail(f"expected exactly 32 entries in color.hero, found {len(heroes)}")
for hero in heroes:
    ref = hero.get("ref")
    if ref is not None and ref not in worldByName:
        fail(f"color.hero entry {hero['name']} refs unknown role {ref}")
    if ref is None and "value" not in hero:
        fail(f"color.hero entry {hero['name']} has neither ref nor value")


def colour(token, theme):
    value = token["value"]
    return value.get(theme, value[first]) if isinstance(value, dict) else value


# Cells a theme's palette carries: the 32 w-* roles, the 32 hero cells and the 3 light-* cells.
CELL_NAMES = ([t["name"] for t in worldTokens] + [h["name"] for h in heroes] +
              ["light-sky", "light-fog", "light-ambient"])


def cell_rgb(name, theme):
    if name in worldByName:
        return parse_hex(colour(worldByName[name], theme))
    for hero in heroes:
        if hero["name"] == name:
            if "ref" in hero:
                return parse_hex(colour(worldByName[hero["ref"]], theme))
            return parse_hex(hero["value"])
    if name in lightByName:
        return parse_hex(colour(lightByName[name], theme))
    fail(f"unknown palette cell {name!r}")


def luau_block():
    lines = ["local palettes: { [string]: { [string]: { number } } } = {"]
    for theme in themes:
        lines.append(f'\t{theme["id"]} = {{')
        for name in CELL_NAMES:
            r, g, b = cell_rgb(name, theme["id"])
            lines.append(f'\t\t["{name}"] = {{ {r}, {g}, {b} }},')
        lines.append("\t},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def replace_block(text):
    before, rest = text.split(BEGIN_MARK, 1)
    after = rest.split(END_MARK, 1)[1]
    return f"{before}{BEGIN_MARK}\n{luau_block()}{END_MARK}{after}"


def css_output():
    css = [
        "/* Generated from tokens.json by scripts/design-tokens.py. Do not edit by hand. */",
        ":root {",
    ]
    css += [f"  --{t['name']}: {colour(t, first)};" for t in tokens["color"]["tokens"]]
    for family in ("spacing", "radius", "touch"):
        css += [f"  --{t['name']}: {t['value']};" for t in tokens[family]["tokens"]]
    css += [f"  --font-{k}: {v};" for k, v in tokens["type"]["families"].items()]
    css.append("}")
    for theme in themes[1:]:
        css.append(f'[data-theme="{theme["id"]}"] {{')
        css += [
            f"  --{t['name']}: {colour(t, theme['id'])};"
            for t in tokens["color"]["tokens"]
            if isinstance(t["value"], dict)
        ]
        css.append("}")
    return "\n".join(css) + "\n"


def md_output():
    md = [
        "# Tokens",
        "",
        "Generated from [tokens.json](tokens.json) by `scripts/design-tokens.py`; `tokens.css` holds the same values as CSS variables.",
        "",
        "## Colour",
        "",
        "World tokens (`w-*`, `light-*`) change per theme; UI and tier tokens are the same in every theme.",
        "",
        "| Token | " + " | ".join(f"`{t['id']}` {t['name']}" for t in themes) + " | Usage |",
        "| --- | " + " | ".join("---" for _ in themes) + " | --- |",
    ]
    for t in tokens["color"]["tokens"]:
        md.append(
            f"| `{t['name']}` | "
            + " | ".join(f"`{colour(t, th['id'])}`" for th in themes)
            + f" | {t.get('usage', '')} |"
        )
    md += ["", "## Type", "", "| Style | Family | Size / line | Weight | Sample | Usage |",
           "| --- | --- | --- | --- | --- | --- |"]
    for group in tokens["type"]["groups"]:
        for s in group["styles"]:
            md.append(
                f"| `{s['name']}` | {group['family']} | {s['fontSize']} / {s['lineHeight']} | "
                f"{s['fontWeight']} | {s['sample']} | {s['usage']} |"
            )
    for family in ("spacing", "radius", "touch"):
        md += ["", f"## {family.capitalize()}", "", "| Token | Value | Usage |", "| --- | --- | --- |"]
        md += [f"| `{t['name']}` | {t['value']} | {t.get('usage', '')} |" for t in tokens[family]["tokens"]]
    return "\n".join(md) + "\n"


# color.hero is exposed to the palette generator and the Luau block only (R-04): the design site is
# unchanged, so CSS and Markdown ignore it.

check = "--check" in sys.argv[1:]

themes_file = open(THEMES_PATH).read()
expected = {
    os.path.join(DESIGN, "tokens.css"): css_output(),
    os.path.join(DESIGN, "tokens.md"): md_output(),
    THEMES_PATH: replace_block(themes_file),
}

if check:
    for path, wanted in expected.items():
        have = open(path).read()
        if have == wanted:
            continue
        message = f"stale: {os.path.relpath(path, ROOT)}. Run python3 scripts/design-tokens.py"
        for have_line, want_line in zip(have.splitlines(), wanted.splitlines()):
            if have_line != want_line:
                message += f"\n  first difference: {have_line!r} vs {want_line!r}"
                break
        if len(have.splitlines()) != len(wanted.splitlines()):
            message += f"\n  line count {len(have.splitlines())} vs {len(wanted.splitlines())}"
        fail(message, 1)
    print("tokens in sync")
    sys.exit(0)

for path, wanted in expected.items():
    with open(path, "w") as f:
        f.write(wanted)
print(f"wrote tokens.css, tokens.md and the palettes block in {os.path.relpath(THEMES_PATH, ROOT)}")
