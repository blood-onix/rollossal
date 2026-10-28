# Writes docs/design/tokens.css (CSS variables: :root is the first theme, [data-theme="<id>"] overrides the
# world colours) and docs/design/tokens.md (the same values as tables) from docs/design/tokens.json.
# The previews in docs/design/components link tokens.css, so rerun this after any change to the JSON.
# Run: python3 scripts/design-tokens.py

import json
import os

DESIGN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "design")

tokens = json.load(open(os.path.join(DESIGN, "tokens.json")))
themes = tokens["color"]["themes"]
first = themes[0]["id"]


def colour(token, theme):
    value = token["value"]
    return value.get(theme, value[first]) if isinstance(value, dict) else value


css = ["/* Generated from tokens.json by scripts/design-tokens.py. Do not edit by hand. */", ":root {"]
css += [f"  --{t['name']}: {colour(t, first)};" for t in tokens["color"]["tokens"]]
for family in ("spacing", "radius", "touch"):
    css += [f"  --{t['name']}: {t['value']};" for t in tokens[family]["tokens"]]
css += [f"  --font-{k}: {v};" for k, v in tokens["type"]["families"].items()]
css.append("}")
for theme in themes[1:]:
    css.append(f'[data-theme="{theme["id"]}"] {{')
    css += [f"  --{t['name']}: {colour(t, theme['id'])};" for t in tokens["color"]["tokens"] if isinstance(t["value"], dict)]
    css.append("}")
with open(os.path.join(DESIGN, "tokens.css"), "w") as f:
    f.write("\n".join(css) + "\n")

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
    md.append(f"| `{t['name']}` | " + " | ".join(f"`{colour(t, th['id'])}`" for th in themes) + f" | {t.get('usage', '')} |")
md += ["", "## Type", "", "| Style | Family | Size / line | Weight | Sample | Usage |", "| --- | --- | --- | --- | --- | --- |"]
for group in tokens["type"]["groups"]:
    for s in group["styles"]:
        md.append(f"| `{s['name']}` | {group['family']} | {s['fontSize']} / {s['lineHeight']} | {s['fontWeight']} | {s['sample']} | {s['usage']} |")
for family in ("spacing", "radius", "touch"):
    md += ["", f"## {family.capitalize()}", "", "| Token | Value | Usage |", "| --- | --- | --- |"]
    md += [f"| `{t['name']}` | {t['value']} | {t.get('usage', '')} |" for t in tokens[family]["tokens"]]
with open(os.path.join(DESIGN, "tokens.md"), "w") as f:
    f.write("\n".join(md) + "\n")
