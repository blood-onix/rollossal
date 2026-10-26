# Rollossal Constitution

Rollossal is a Roblox co-op rolling game: players roll a ball that sticks to every object
smaller than itself and grows until it can swallow the town; friends can merge balls. It is
built by a two-person team (a father and his son) with several AI coding agents working in
parallel, using Spec Kit, the Roblox Studio MCP server and, for 3D assets, a Blender MCP
server. The design spec is `docs/rollossal-gdd.md`.

In this document, **the owner** means the human who owns the Roblox experience (the account
or group it is published under). **Owner approval** means an approving review or a written
"approved" comment from the owner on the pull request (or task) concerned. An agent's own
statement never counts as owner approval.

## Core Principles

### I. Fun Is Proven in Grey Box First

- Art, monetization and live-ops work MUST NOT start until the owner has played a grey-box
  build of ball control, absorption and growth and signed off. The sign-off MUST be recorded
  in that feature's `playtest.md`.
- Every new mechanic MUST get a grey-box check before any polish (art, VFX, audio, UI
  styling) is applied to it. The check is an agent-driven Studio playtest through the Studio
  MCP server (with simulated clients when the mechanic needs several players) plus the owner
  playing it. Outside players are not required for this check.
- A playtest with outside people (at least 3 adults and at least 3 children aged 10–12) MUST
  take place once the game has its world art and animation, and MUST be recorded with the
  owner's sign-off before the first publish to the live place. A mechanic that lands after
  that round MUST get its own round with outside people before it ships to the live place.
- Each playtest MUST be recorded in the feature's spec folder (`specs/<feature>/playtest.md`)
  with the date, the build or commit, participant counts per age group (when people take
  part), findings, and the owner's sign-off. Children are recorded by age group only, never
  by name.

Rationale: the genre is crowded and art is expensive. A mechanic that is not fun in grey
boxes will not be saved by polish, so grey box still proves each mechanic before polish. But
showing a grey-box room to children gives little signal: they judge what looks like a game.
Outside people therefore test once the game reads as a game, and always before launch.

### II. Server Authority

- The client MAY own the ball's physics (network ownership) for smooth control.
- The server alone MUST decide absorption, size, score, coins, unlocks and run results.
- The server MUST validate every absorb request:
  - the object exists and has not already been taken;
  - the distance from ball to object is within the allowed limit;
  - the size rule (from `src/shared/Rules`) passes;
  - the player has made at most N absorbs per second, where N is defined in
    `src/shared/Config`.
- The server MUST sanity-check ball speed against a limit defined in Config and reject or
  correct out-of-range movement.
- RemoteEvents and RemoteFunctions MUST accept only input-like data (move direction, button
  intents, the ID of a target object) and MUST type-check every argument. They MUST NOT
  accept sizes, scores, coin amounts, unlocks or results from the client.
- Nothing the client sends is trusted for any change to progress. Absorb validation MUST be
  covered by tests in `tests/studio`.

Rationale: a client-owned rolling ball invites speed and absorb exploits; progress must only
ever come from the server.

### III. Pure, Tested Rules

- Growth maths, the absorb rule, star thresholds, coin rewards and merge maths MUST live in
  `src/shared/Rules`.
- `src/shared/Rules`, and every module it requires, MUST NOT use Roblox APIs: no `Instance`,
  `workspace`, `game`, `task`, services, Roblox datatypes, `math.random` or clock reads.
  Any randomness or time MUST be passed in as an argument (for example a seed or a date).
- Every change to `src/shared/Rules` MUST come with a passing Lune unit test in
  `tests/unit` that asserts fixed expected values (no values computed by the code under test).
- `scripts/check.sh` MUST fail if a forbidden identifier appears under `src/shared/Rules`.

Rationale: pure rules are cheap to test outside Studio, identical on server and client, and
safe for parallel agents to change.

### IV. Safe for Everyone (Target Rating: Minimal)

- The game MUST NOT contain blood, gore, weapons, romance, alcohol, strong language,
  gambling imagery, free-form drawing or hangout-centred spaces.
- Gameplay MUST NOT depend on text chat; every action is possible without typing.
- Player-to-player swallowing MUST be opt-in only, live in its own mode (never on in the
  default mode), and MUST NOT take away any persistent progress.
- The game MUST be built from runs with clear endings. There is no endless feed and no
  infinite scrolling.
- Any change that could alter the answers to the Roblox maturity questionnaire MUST have
  owner approval before work starts.

Rationale: the target audience is 10–12; a Minimal label and under-16 access depend on it.

### V. Ethical Monetization

- Only cosmetics, convenience passes and private servers MAY be sold.
- The game MUST NOT sell random items, loot boxes or paid luck boosts, and MUST NOT allow
  player-to-player trading.
- Nothing paid MAY change the outcome of a competitive mode.
- There MUST be exactly one soft currency, Coins, earned only through play and never sold
  for Robux (directly or bundled).
- Prices MUST be read from `MarketplaceService` and shown before purchase; prices MUST NOT
  be hard-coded in UI.
- There MUST be no countdown pressure, no pop-up offers during a run, and no fake "limited"
  stock.
- `ProcessReceipt` MUST be idempotent: processed receipt IDs are stored in the player
  profile, and a repeated receipt grants nothing. This MUST be covered by tests in
  `tests/studio`.
- Adding or changing prices, game passes or developer products MUST have owner approval.

Rationale: "fair and kind" is a design pillar; the audience is children, and trust is the
product.

### VI. Mobile First

- All core play MUST work with one thumb (movement on the stick, actions on large buttons).
- The game MUST hold 30 fps on the mid-range reference phone.
- Text on phones MUST be at least 18 px.
- Information MUST NOT be conveyed by colour alone or by sound alone.
- A new player MUST roll up their first object within 5 seconds of joining and reach the
  first growth tier within 60 seconds, with no menu in front of the first run.
- Performance budgets MUST be defined in `src/shared/Config` and checked in playtests:
  visible stuck objects per ball, active parts per server, and triangles per mesh.

Rationale: most of the audience plays on phones, and the first minute decides retention.

### VII. Content Is Data

- Worlds, objects, size tiers and theme skins MUST live in data modules under
  `src/shared/Content`.
- A reskin (for example Winter to Candy) MUST change only data and assets, not code. A reskin
  that needs a code change is a defect in the content model, fixed in its own task.
- New features MUST ship behind flags in `src/shared/Config`.
- Content data MUST be validated by Lune tests in `tests/unit` (for example: sizes ascend
  by tier, IDs are unique).

Rationale: monthly worlds and weekly object drops are only affordable if they are data.

### VIII. Player Data and Privacy

- Player profiles MUST be stored with ProfileStore.
- The profile schema MUST carry a version number; every schema change MUST ship with a
  migration and a test of that migration.
- Only user IDs and game progress MAY be stored. No names, chat logs, contact details or
  other personal data.
- Any player-visible text that a player can influence MUST go through `TextService`
  filtering.
- Changing a DataStore schema, key name or migration MUST have owner approval.

Rationale: lost or corrupted progress is the fastest way to lose players, and the audience
includes children.

### IX. Localised Strings

- Every player-facing string MUST come from the localisation tables. Player-facing strings
  MUST NOT be hard-coded in scripts or UI.
- English and Spanish MUST be complete at launch. Portuguese (Brazil) and Russian are
  proposed and need owner approval to add.

Rationale: localisation added later means rewriting every UI file.

### X. Multi-Agent Discipline

- Each feature MUST be worked on its own branch and merged by pull request.
- Tasks marked `[P]` in `tasks.md` MUST touch disjoint files.
- Each agent MUST work in its own git worktree.
- Only one agent at a time MAY drive Roblox Studio through the Studio MCP server, and only
  one MAY drive Blender through the Blender MCP server. An agent MUST claim the tool on its
  task in `tasks.md` before using it and release the claim when done.
- Agents MUST NOT publish to the live place. Publishing to the private test place is allowed.
- Agents MUST NOT commit secrets (API keys, cookies, tokens) or place files (`.rbxl`,
  `.rbxlx`); `.gitignore` MUST exclude place files.

Rationale: parallel agents are only faster if they never collide on files, tools or the
live game.

### XI. Asset Pipeline

- 3D assets MUST be made or edited in Blender. Sources live in `art/source` and exports
  (FBX or glTF) in `art/export`.
- Assets MUST be low-poly and flat-shaded, MUST share one palette texture, and MUST stay
  within the triangle budgets in `src/shared/Config`.
- Uploaded asset IDs MUST be recorded in `src/shared/Assets.luau` and MUST NOT be hard-coded
  anywhere else.
- Creator Store models containing scripts MUST NOT be used. Mesh-only models MAY be used
  after an inspection confirms they contain no scripts.

Rationale: one palette and strict budgets keep the look coherent and phones fast; scripted
free models are a security risk.

### XII. Keep It Lean

- Prefer Roblox built-ins and the existing toolchain: Rokit, Wally, ProfileStore, StyLua,
  Selene, luau-lsp in strict mode, Lune, Jest-Lua, Rojo 7.7.1, the Roblox Studio MCP server
  and GitHub Actions.
- A new tool, package or external service MUST have: a concrete problem it solves, a pinned
  version, a justification line in the feature's `plan.md`, and owner approval.
- No abstractions for hypothetical needs; an abstraction needs at least two current users.
- Every Luau file MUST start with `--!strict`.

Rationale: a two-person team with agents can only maintain what it understands.

## Quality Gates

A task is done only when all of the following hold:

1. Format, lint, type check and unit tests pass: `scripts/check.sh` exits 0.
2. If the task touches server, client or UI behaviour: an agent has run a Studio playtest
   through the Studio MCP server, read the console, and seen no new errors or warnings. For
   UI changes it has also captured the viewport at a phone resolution.
3. If the task adds an asset: it is within budget and its ID is in `src/shared/Assets.luau`.
4. If the task adds a player-facing string: the string is in the localisation tables.
5. The task is ticked in `tasks.md`.

Each pull request description MUST state which gates applied and how each was met.

## Human Approval Required

Agents MUST stop and get owner approval before any of the following:

- Publishing to the live place.
- DataStore schema, key name or migration changes.
- Prices, game passes or developer products (adding or changing).
- Anything that could change the answers to the Roblox maturity questionnaire.
- New tools, packages or external services.
- Spending real money (ads, fees, Robux).

## Governance

- This constitution overrides every other rules file in the repository (agent instruction
  files, skills, the design spec and plans). Where the design spec conflicts with it, the
  constitution wins and the spec is corrected.
- Amendments MUST be made by pull request, with a version bump and owner approval.
- Versioning follows semantic versioning:
  - MAJOR: a principle or governance rule is removed or redefined incompatibly.
  - MINOR: a principle or section is added or materially expanded.
  - PATCH: clarifications, wording and typo fixes.
- Agents MUST check the constitution during `/speckit-plan` and `/speckit-analyze` and MUST
  flag conflicts in the plan or analysis instead of working around them. A conflict is
  resolved by changing the work or by amending the constitution, never by ignoring it.

**Version**: 1.1.0 | **Ratified**: 2026-10-24 | **Last Amended**: 2026-10-26
