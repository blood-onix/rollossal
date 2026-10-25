# PR draft: Grey-Box Prototype (001-grey-box-prototype)

Status: DRAFT. Not for submission until Quality Gate 2 (Studio) and the CI run are complete.

## Summary

- Repository foundations: Rojo project, StyLua, Selene, luau-lsp strict, `.luaurc`, `scripts/check.sh`,
  `scripts/test-guard.sh`, CI workflow (`.github/workflows/check.yml`), GDD moved to `docs/`, new README.
- Pure rules in `src/shared/Rules` (Absorb, Growth, Movement, StuckStack, RateLimit) with Lune tests
  (56 of 56 passing locally).
- Server-authoritative pickup, knock-off, respawn and speed check (`src/server`), client sends cube IDs only.
- Client rolling ball, smoothed camera, jump button (96 px minimum), stuck visuals (`src/client`).
- Jest-Lua server tests for FR-024 rejections, boundary, stack-of-5 knock-off, registry invariant and
  speed violation (`tests/studio`), not yet run in Studio.
- `playtest.md` template (FR-025), not yet filled.

## Quality Gates

| Gate | How it is met | Status |
| --- | --- | --- |
| 1. `scripts/check.sh` | Runs StyLua, Selene, luau-lsp strict, Lune suites, Rules guard. Exit 0 locally. `scripts/test-guard.sh` exit 0. | Local pass. CI run pending (T065). |
| 2. Studio playtest, console read, phone viewport | Studio spike, JitterProbe, Jest suite, console read and phone-resolution capture of the jump button. | Pending. Rojo sync into Studio not yet connected (T079, T080, T056, T058, T067). |
| 3. Assets | N/A: plain parts only, no imported assets. | N/A |
| 4. Localisation | N/A: the jump button is a symbol, no player-facing strings. | N/A |
| 5. `tasks.md` ticks | Ticks are recorded in `specs/001-grey-box-prototype/tasks.md`; unticked tasks there are the open items listed below. | Partial |

Constitution check: Principles II, III, IV, VI, VII, X and XII pass as written in plan.md. Principle I is
open: the 6-player playtest and owner sign-off (T059) have not happened, so no art, monetization or
live-ops work may start. Principles V, VIII, IX and XI are N/A.

## Open before merge

- T040: JitterProbe and fps on the reference phone (Galaxy A53/A54 class). Needs a physical device.
- T059: 6+ player playtest and owner sign-off. Needs people and the owner's approval.
- T065: push, open PR, confirm `check` workflow is green. Needs the owner's go-ahead.
- T079 and T080 (Studio spike, Jest run, JitterProbe on the laptop, console read, phone viewport capture):
  blocked in this round, see the summary in the round report.

## Test plan

- [x] `scripts/check.sh` exits 0 locally
- [x] `scripts/test-guard.sh` exits 0 locally
- [x] `grep -rIi ricokick` and `shot-engine-career` outside `specs/` history and constitution prose: no hits in code or metadata
- [x] `README.md` links to `docs/rollossal-gdd.md` and `.specify/memory/constitution.md` resolve
- [ ] Jest-Lua suite passes in Studio (`return require(game.ServerStorage.Tests.runner)()`)
- [ ] Studio playtest: zero console errors and warnings
- [ ] JitterProbe on the laptop; `stuckVisualMode` decision recorded in plan.md Risk Results
- [ ] Phone-resolution viewport capture of the jump button (at least 96 x 96 px, bottom right)
- [ ] CI `check` workflow green

🤖 Generated with [Claude Code](https://claude.com/claude-code)
