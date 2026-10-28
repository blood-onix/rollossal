# Rollossal

A Roblox game in Luau. The current milestone is a grey-box prototype: one rolling ball per player that absorbs small objects, grows by volume and is tested in a single room.

## Documentation

- [Game design brief](docs/rollossal-gdd.md): the full design spec.
- [Design system](docs/design/README.md): themes, the city asset list, the Downtown layout, cosmetics, budgets and tokens (a proposal; open `docs/design/index.html` for the previews).
- [Constitution](.specify/memory/constitution.md): the principles every change must follow.
- [Grey-box prototype spec](specs/001-grey-box-prototype/spec.md), [plan](specs/001-grey-box-prototype/plan.md) and [tasks](specs/001-grey-box-prototype/tasks.md).

## Checks

Run `scripts/check.sh` before opening a pull request. It runs StyLua, Selene, luau-lsp strict analysis, the Lune unit tests and the Rules purity guard. CI runs the same script on every pull request.

## Setup

Tools are pinned in `rokit.toml` (install with [Rokit](https://github.com/rojo-rbx/rokit)). Packages are pinned in `wally.toml`.

```sh
rokit install
wally install
scripts/check.sh
rojo serve default.project.json
```

Place files (`.rbxl`, `.rbxlx`) and secrets are git-ignored and must not be committed.
