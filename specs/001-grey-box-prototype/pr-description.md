# Grey-Box Prototype (001-grey-box-prototype)

## Summary

- Repository foundations: Rojo project, StyLua, Selene, luau-lsp strict, `.luaurc`, `scripts/check.sh`,
  `scripts/test-guard.sh`, CI workflow (`.github/workflows/check.yml`), GDD moved to `docs/`, new README.
- Pure rules in `src/shared/Rules` (Absorb, Growth, Movement, StuckStack, RateLimit) with Lune tests
  (56 of 56 passing locally).
- Server-authoritative pickup, knock-off, respawn and speed check (`src/server`), client sends cube IDs only.
- Held cubes respawn after `respawnDelay` while the ball keeps a visual-only record (T090): stack entries
  are keyed `<cubeId>#<n>`, and knock-off, Reset and leave release only cubes still pending from the same pickup.
- Client rolling ball (input from `CharacterContext.MoveAction`, no character), own touch stick for phones
  (Roblox builds its touch controls only for a character), smoothed camera, jump button (96 px), stuck
  visuals in `Weld` mode (`src/client`).
- Jest-Lua server tests for the FR-024 rejections, boundary, stack-of-5 knock-off, registry invariant and
  speed violation (`tests/studio`), passing in Studio.
- `playtest.md` template (FR-025), not yet filled.

## Quality Gates

| Gate | How it is met | Status |
| --- | --- | --- |
| 1. `scripts/check.sh` | Runs StyLua, Selene, luau-lsp strict, Lune suites, Rules guard. `scripts/test-guard.sh` too. | Exit 0 locally; CI `check` green |
| 2. Studio playtest, console read, phone viewport | Studio spike over Rojo and the Studio MCP server: solo scenarios S1 to S8, JitterProbe on the laptop, Jest suite, console read, phone-resolution jump button check. | Pass. Console clean apart from Studio's own `ContentId` line. Jest 19 of 19. JitterProbe `Weld`: resting ΔY 0.0034, rolling speed error 0.029. Solo run reached Tier 4 at 101 s with at most 30 visuals. Phone: Galaxy A16 in the Studio device simulator (viewport 685 × 338), jump button 96 × 96 px, 24 px from the right and bottom edges; dragging the touch stick rolls the ball and the jump button hops 1.27 studs |
| 3. Assets | N/A: plain parts only, no imported assets. | N/A |
| 4. Localisation | N/A: the jump button is a symbol, no player-facing strings. | N/A |
| 5. `tasks.md` ticks | Ticks are recorded in `specs/001-grey-box-prototype/tasks.md`; unticked tasks are listed below. | Partial |

Constitution check: Principles II, III, IV, VI, VII, X and XII pass as written in plan.md. Principle I is
open: the owner skipped the 6-player playtest (T059), so it has no sign-off, so no art, monetization or
live-ops work may start. Principles V, VIII, IX and XI are N/A.

## Open items

- Manual tests skipped by the owner (ticked in tasks.md as skipped): T040 (JitterProbe on the reference
  phone), T058 (multi-client Local Server test), T059 (6+ player playtest). The Constitution I gate stays
  unmet until a playtest is signed off, so no art, monetization or live-ops work yet.
- Studio place: the template `SpawnLocation` and `Baseplate` were deleted in Edit mode (they blocked the
  probe lane); save the place to keep that.

Do not merge without owner approval.

## Test plan

- [x] `scripts/check.sh` exits 0 locally
- [x] `scripts/test-guard.sh` exits 0 locally
- [x] `grep -rIi ricokick` and `shot-engine-career` outside `specs/` history and constitution prose: no hits in code or metadata
- [x] `README.md` links to `docs/rollossal-gdd.md` and `.specify/memory/constitution.md` resolve
- [x] Jest-Lua suite passes in Studio (`return require(game.ServerStorage.Tests.runner)()`)
- [x] Studio playtest: zero console errors and warnings from the game
- [x] JitterProbe on the laptop; `stuckVisualMode` decision recorded in plan.md Risk Results
- [x] Phone-resolution check of the jump button (at least 96 × 96 px, bottom right)
- [x] Touch stick moves the ball in the device simulator (T091)
- [x] CI `check` workflow green

🤖 Generated with [Claude Code](https://claude.com/claude-code)
