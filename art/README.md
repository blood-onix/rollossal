# Art pipeline (Snow Village)

Contract: `specs/004-snow-village/contracts/art-pipeline.md`.

## Pinned tools

| Tool | Version | Status |
| --- | --- | --- |
| Blender | 5.2.3 LTS (binary `/Applications/Blender.app/Contents/MacOS/Blender`) | installed, MCP addon connected |
| `mcp-for-blender` (the Blender MCP server, started with `uvx`) | **not pinned yet** | `.vscode/mcp.json` and `opencode.json` run `uvx mcp-for-blender` unpinned. Task T002 stays open until the release is looked up (`uvx mcp-for-blender --version`) and written into both files as `mcp-for-blender==<version>` |

No script under `art/scripts` other than `budgets.json` exists yet; the Blender tasks (T024) wait for the pin.

## Files

- `scripts/budgets.json`: triangle budgets, object sizes and tiers from `Config` and the Snow Village data.
  Regenerate with `lune run scripts/art-sync` after changing either; `tests/unit/ArtManifest.test.luau` fails
  when the committed file is stale.
