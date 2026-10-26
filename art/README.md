# Art pipeline (Snow Village)

Contract: `specs/004-snow-village/contracts/art-pipeline.md`.

## Pinned tools

| Tool | Version | Status |
| --- | --- | --- |
| Blender | 5.2.3 LTS (binary `/Applications/Blender.app/Contents/MacOS/Blender`) | installed, MCP addon connected |
| `mcp-for-blender` (the Blender MCP server, started with `uvx`) | **2.2.4** (pinned in `.vscode/mcp.json` and `opencode.json` as `uvx mcp-for-blender==2.2.4`; latest PyPI release as of 2026-10-26, addon protocol 15 — the protocol the installed addon runs) | pinned |

Update the pin only together with the Blender addon (re-running `uvx mcp-for-blender` upgrades the addon on disk;
keep both at one release).

## Files

- `scripts/budgets.json`: triangle budgets, object sizes and tiers from `Config` and the Snow Village data.
  Regenerate with `lune run scripts/art-sync` after changing either; `tests/unit/ArtManifest.test.luau` fails
  when the committed file is stale.
