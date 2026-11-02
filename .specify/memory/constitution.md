<!--
Sync Impact Report (temporary; remove before commit)
Version change: 3.0.0 -> 4.0.0 (owner-approved request, 2026-11-02; approval on the PR still needed)
Bump reason: MAJOR. "Owner taste MUST NOT hold a feature" and "only the Human Approval list can
  stop a feature" are redefined incompatibly: for a map, world-art or ball-look feature the owner's
  approval now can hold it. A plan written to 3.0.0 for such a feature (taste on the RC list, no
  images, no wait) breaks the new rule. Same test as the 3.0.0 bump. The IV and XI changes alone
  would be MINOR.
Why: feature 008 closed as done with no images ever taken of the map, and the owner rejected the
  result. Backlog item 004g records this.
Modified principles:
  - I (title unchanged): map, world-art and ball-look features are not finished until images exist
    and the owner has approved them. Rationale extended.
  - IV (title unchanged): invented shop names and short signage allowed on textures and billboards;
    ban list extended; shop names need no localisation key; billboard and paid-placement rules.
    Maturity-questionnaire rule kept.
  - XI (title unchanged): imported CC0 meshes count as made or edited in Blender; one more shared
    atlas for building fronts and signs; a capped set of billboard textures. Rationale extended.
Modified sections:
  - Quality Gates: new gate 6 (visual gate); the RC-list and two-failure rules name it as the second
    wait outside the Human Approval list.
Added sections: none
Removed sections: none
Unchanged: II, III, V, VI, VII, VIII, IX, X, XII, Human Approval Required, Governance, launch rules.
Drafting choices the request did not spell out (overrule on the PR):
  - Gate 6 holds the merge, not the opening of the PR. Owner approval is defined as a review or
    comment on the PR or task, so the PR is the natural place to show the images.
  - Gate 2's "capture files MUST NOT be required" does not apply to gate 6, which needs images the
    owner can see. The Studio MCP still cannot save a capture, so a feature names its route.
  - The shop-name rule is written in IV as the one exception to IX and gate 4. Their text is unchanged.
Files updated: AGENTS.md (two-failure limit, owner checks, new visual gate paragraph);
  docs/design/05-roblox-limits.md, README.md, 06-art-style.md, 03-city-level.md, 02-city-assets.md.
  02-city-assets.md's "not in the kit" line on real brands still holds, so it is unchanged.
Files checked, no change needed:
  - docs/design/04-player-cosmetics.md: lines 71, 98, 109 and 127 are per-item notes (no words on
    these cosmetics), not the rule, and they still comply: not shop names, so pictogram or key.
  - .specify/templates/*, CLAUDE.md, .github/copilot-instructions.md, .claude/skills/speckit-*:
    a search for the changed rules found nothing.
Not checked: backlog item 004g itself (the profile blocks the Conveyor tools) and Conveyor's prompts.
Follow-up TODOs from 4.0.0:
  - Not edited, not on the request's list, and these repeat the old rules:
    - docs/release-candidate.md header: "Nothing on this list holds a feature; only the
      constitution's Human Approval list can stop one"; item "The owner's layout and pacing sign-off".
    - docs/design/components/PropCard/README.md line 8: "Don't use ... words on any face".
    - docs/rollossal-gdd.md line 277: "no words on textures". Governance says the spec is corrected.
    - docs/design/speckit-prompt.md line 60, constitution-prompt.md line 26: past prompts, history.
  - VII lists a theme as "a palette atlas, lighting, ..." and does not name a per-theme fronts atlas.
    Left as is by request; the reskin rule (data and assets only) still covers it.
  - One material per mesh stays, so a building on the fronts atlas needs all its faces in that atlas.
    The feature that adds the atlas settles the layout.
  - The cap on billboard textures does not exist in src/shared/Config.luau yet. The feature that adds
    the textures adds it.
  - Sign text other than a shop name needs a localisation key, and a texture cannot translate itself.
    The feature that adds such a sign picks a pictogram or a localised route.
  - An owner hand-off (gate 3) can still leave stand-ins in a gate 6 feature's images. The owner
    decides whether that is enough to approve.

Carried over from the 3.0.0 report, still open unless marked:
Version change: 2.0.0 -> 3.0.0
Bump reason: MAJOR. Principle I is redefined incompatibly: the owner playing a mechanic was
  required and MUST NOT be now; the outside round moves to the RC; a later mechanic no longer
  gets its own round automatically. Gate 2 changes scope from task to feature, and two items
  leave or narrow on the Human Approval list. A plan written to 2.0.0 (owner sign-off as an
  acceptance gate, timed bot runs, capture files) now breaks the new rules, so this is not a
  MINOR expansion, even though most of the changes relax rules.
Modified principles:
  - I. Fun Is Proven in Grey Box First -> I. Grey Box First, Fun Judged on the Release Candidate:
    rewritten. Title changed because agents now prove a mechanic works and fun is judged later.
  - V. Ethical Monetization: "prices" means Robux prices; coin prices are data set by agents and
    reviewed on the RC; stubbed products behind an off flag allowed; approval before any real
    product or price.
  - VI. Mobile First: targets kept and measured on the RC; agent Studio runs check budgets and
    frame rate until then; real-phone check on the RC.
  - VIII. Player Data and Privacy: schema, key name and migration changes pre-approved until the
    first live publish, if they carry the version bump, migration and test.
  - Preamble: defines the release candidate (RC).
Modified sections:
  - Quality Gates: Gate 2 now per feature, inspected capture instead of a saved file; Gate 3 lets
    an owner hand-off ship with its stand-in (needed, or the hand-off rule could never be met);
    added the agent-runnable, release-candidate list, hand-off, two-failure and default rules.
    Gate 2's Studio playtest is exempt from the two-failure rule (owner decision, 2026-11-01).
  - Human Approval Required: data changes apply from the first live publish on; "prices" narrowed
    to real products and Robux prices. Live publish, questionnaire, new tools and real money stay.
Added sections: none (docs/release-candidate.md is a new file outside this document)
Removed sections: none
Unchanged: II, III, IV, VII, IX, X, XI, XII, Governance.
Files updated: docs/release-candidate.md (new), AGENTS.md ("Studio tasks" section).
Files checked, no change needed: .specify/templates/*, CLAUDE.md, .github/copilot-instructions.md,
  .claude/skills/speckit-*: none repeats the changed rules.
Not checked: Conveyor's own prompts live outside this repo and may still produce human items.
Follow-up TODOs:
  - Not edited, by request. Backlog items that still repeat the old gates:
    - 004f: owner approves the slice and the map as acceptance, owner reviews each ring, "Carried
      over from 007" list (now on the release-candidate list). Owner approval of the map is allowed
      again under gate 6 (4.0.0); the rest is unchanged.
    - 004c: capture set saved in the feature folder; owner signs off the look. Allowed under gate 6
      (4.0.0) if the feature's main output is world art.
    - 004d: cites constitution 1.1.0; "once it looks like a game" should become the RC.
    - 005: owner checks on a real phone; grey-box check "plus the owner playing it".
    - 006a: owner approval of the schema change; coin prices as an owner confirmation.
    - 006b: owner runs the private-test-place purchases; no stubbed-product path yet.
    - 007: owner approval of the onboarding schema change.
    - 008: people round after 004d is automatic and the live publish waits for it (now the
      owner's choice); budgets "locked from 004e's capture".
    - 009, 010: grey-box check "plus the owner playing it"; 009 also needs the owner's sign-off.
    - 011, 013: timed pacing bot runs (+/-20 s); 30 fps on the reference phone as acceptance.
    - 012: "the pacing bot run still passes". Its schema approval stays right after launch.
  - Not edited, by request. Existing specs that repeat the old gates (all finished, so history):
    - 001: spec Story 1 and FR-025; tasks T059.
    - 002 and 003: 👤 human tasks in tasks.md (003 T048); 003's schema gate was met as written.
    - 004: spec Playtest Timing Gate, Deferred Balance, FR-012, SC-004, SC-005, Outside-Player
      Deferral; tasks T032.
    - 005: spec SC-004 and FR-009 (640 x 360 capture).
    - 006: spec Grey-Box Gate, SC-004.
    - 007: spec Grey-Box Gate, Locking Budgets, SC-005; tasks T015, T016, T035, T039. Its
      playtest.md points the open items at 004f; they now live on the release-candidate list.
  - docs/rollossal-gdd.md repeats the old order (section 11, item 5: 004d) and lists prices and the
    DataStore key name as owner questions. Governance says the spec is corrected; not edited, by
    request. docs/design/ not checked for 3.0.0's rules beyond the lines updated in 4.0.0.
  - RESOLVED by gate 6 (4.0.0). Conflict to settle in 004f: its acceptance is owner taste, which
    3.0.0 said MUST NOT hold a feature, yet the RC needs the map in its "final layout". A map
    feature's images and the owner's approval of them can now hold it. Tuning values, phone checks
    and the people round stay RC items.
  - Principle VI wording differs from the request: the MCP cannot resize Studio's viewport
    (AGENTS.md, 007 playtest round 3), so a frame-rate run at another size records that size.
  - Carried from 2.0.0, status not rechecked: flat-shaded/one-palette wording in older art scripts,
    specs/004-snow-village and the GDD; Principle I's "children aged 10-12" against the 16+ trial.
-->

# Rollossal Constitution

Rollossal is a Roblox co-op rolling game: players roll a ball that sticks to every object
smaller than itself and grows until it can swallow the town; friends can merge balls. It is
built by a two-person team (a father and his son) with several AI coding agents working in
parallel, using Spec Kit, the Roblox Studio MCP server and, for 3D assets, a Blender MCP
server. The design spec is `docs/rollossal-gdd.md`. The art and content direction (themes, city
assets, cosmetics, Roblox budgets, colour and type tokens) is `docs/design/`; it is
subordinate to this constitution and, where it conflicts, this constitution wins.

In this document, **the owner** means the human who owns the Roblox experience (the account
or group it is published under). **Owner approval** means an approving review or a written
"approved" comment from the owner on the pull request (or task) concerned. An agent's own
statement never counts as owner approval.

**The release candidate (RC)** means a build on the private test place with the launch world in
its final layout and art, the juice pass and every feature in launch scope. The owner declares
it.

## Core Principles

### I. Grey Box First, Fun Judged on the Release Candidate

- The grey-box gate for ball control, absorption and growth was met by the owner's sign-off on
  2026-10-26 (`specs/004-snow-village/playtest.md`). Art, monetization and live-ops work MAY
  proceed.
- Every new mechanic MUST get an agent-driven grey-box check before any polish (art, VFX, audio,
  UI styling) is applied to it. The check is a Studio playtest through the Studio MCP server,
  with simulated clients when the mechanic needs several players. The owner playing it is
  welcome and MUST NOT be required.
- One playtest with outside people (at least 3 adults and at least 3 children aged 10–12) MUST
  take place on the RC and MUST be recorded with the owner's sign-off before the first publish
  to the live place. It covers every mechanic that landed before it. For a mechanic that lands
  later, the owner decides whether it needs its own round.
- Feel and tuning values (pace windows, `growthK`, star thresholds, jump, booster and trap
  values) are judged on the RC. They MUST NOT block a feature before then.
- A feature whose main output is a world map, world art or the look of the player's ball is not
  finished until images of it exist and the owner has approved them, from fixed shots and by
  playing the build (Quality Gates, gate 6). Automated tests are a floor for these features and
  never prove that the look is good.
- Each agent run and the RC round MUST be recorded in the feature's spec folder
  (`specs/<feature>/playtest.md`) with the date, the build or commit, participant counts per age
  group (when people take part), findings, and, for the RC round, the owner's sign-off. Children
  are recorded by age group only, never by name.

Rationale: art is expensive, and a mechanic that does not work in grey boxes will not be saved
by polish, so an agent still proves each mechanic before polish. Feel is different: tuning
depends on the final map, and neither children nor the owner get useful signal from a build that
does not yet read as a game. People therefore judge it once, on the RC, and always before launch.
The look is different again: tests cannot see it, and a map feature once closed as done with no
images taken and was then rejected. It is seen and approved before the feature is finished.

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
- The ball MUST NOT absorb people or real or live animals. Stand-ins such as statues,
  inflatables or decorations are fine. Ambient animals stay non-absorbable.
- The game MUST NOT show real brands and logos, meme images, real people's faces, flags, alcohol
  or gambling names, the words Roblox, Robux or Blox, anything imitating Roblox's logo, or any name
  close to a real brand.
- Textures and billboards MAY show invented shop names and short signage. Every sign MUST stay
  Minimal-safe.
- Shop names are proper nouns and are not translated, so they need no localisation key. This is the
  one exception to Principle IX and gate 4. All other in-world text MUST stay a pictogram or have a
  localisation key.
- Placeholder billboard art MUST NOT imitate a real ad. A paid placement would need a future
  amendment and owner approval, and MUST meet Roblox's disclosure rules.
- Any change that could alter the answers to the Roblox maturity questionnaire MUST have
  owner approval before work starts.

Rationale: the launch audience is age-checked 16+ players during the trial, then 10–15. A
Minimal label and under-16 access depend on these rules. Every asset stays Minimal-safe, so
the same build works for both groups without a reskin.

### V. Ethical Monetization

- Only cosmetics, convenience passes and private servers MAY be sold.
- The game MUST NOT sell random items, loot boxes or paid luck boosts, and MUST NOT allow
  player-to-player trading.
- Nothing paid MAY change the outcome of a competitive mode.
- There MUST be exactly one soft currency, Coins, earned only through play and never sold
  for Robux (directly or bundled).
- In this constitution, "prices" means Robux prices. Coin prices are tuning values in data that
  agents set and the owner reviews on the RC.
- Prices MUST be read from `MarketplaceService` and shown before purchase; prices MUST NOT
  be hard-coded in UI.
- There MUST be no countdown pressure, no pop-up offers during a run, and no fake "limited"
  stock.
- `ProcessReceipt` MUST be idempotent: processed receipt IDs are stored in the player
  profile, and a repeated receipt grants nothing. This MUST be covered by tests in
  `tests/studio`.
- Robux features MAY be built and tested with stubbed products behind a flag that is off.
- Creating or changing any real game pass, developer product or price MUST have owner approval
  first.

Rationale: "fair and kind" is a design pillar; the audience is children, and trust is the
product.

### VI. Mobile First

- All core play MUST work with one thumb (movement on the stick, actions on large buttons).
- The game MUST hold 30 fps on the mid-range reference phone.
- Text on phones MUST be at least 18 px.
- Information MUST NOT be conveyed by colour alone or by sound alone.
- A new player MUST roll up their first object within 5 seconds of joining and reach the
  first growth tier within 60 seconds, with no menu in front of the first run.
- Performance budgets MUST be defined in `src/shared/Config`: visible stuck objects per ball,
  active parts per server, and triangles per mesh.
- These targets are launch requirements, measured on the RC. Until then, budgets and frame rate
  are checked in agent Studio runs at 640 × 360, judged on unthrottled seconds. The Studio MCP
  cannot resize the viewport, so a run at another size records the size it ran at. The
  real-phone check happens on the RC.

Rationale: most of the audience plays on phones, and the first minute decides retention.

### VII. Content Is Data

- Worlds, objects, size tiers and theme skins MUST live in data modules under
  `src/shared/Content`.
- A reskin (for example Holiday City to Sunny City) MUST change only data and assets, not
  code. A reskin that needs a code change is a defect in the content model, fixed in its own
  task.
- A world's theme MUST be data. A theme is a palette atlas, lighting, weather, music,
  dressing slots, overlays, hero variants and a book page. The active theme is chosen by id
  in data. Switching it is a content change shipped in a release, never a code change and
  never a date check shown to players.
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
- Until the first publish to the live place there is no player data to protect, so changing a
  DataStore schema, key name or migration is pre-approved as long as it carries the version
  bump, the migration and its test. From the first live publish on, each such change MUST have
  owner approval.

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
- An imported CC0 mesh counts as made or edited in Blender once it is imported to Blender and moved
  onto the atlas, with its source and licence recorded in the repo. The licence MUST be checked per
  pack. Any other licence needs owner approval.
- World assets MUST be low-poly in real-world proportions, and MUST stay within the triangle
  budgets in `src/shared/Config`. Silhouette edges get one bevel segment. Round parts MAY be
  smooth-shaded and hard edges stay sharp.
- Every world mesh MUST use the theme's gradient atlas: one 1,024 px texture per theme, all
  with the same layout, generated by script from `docs/design/tokens.json`. Each face's UVs
  MUST sit inside one atlas cell or one trim strip, and each mesh has one material. The next two
  rules are the only exceptions.
- One more shared atlas MAY hold building fronts and signs, by the same rules as the theme atlas:
  generated by script where practical, and per theme where its colours depend on the theme.
- A small capped set of billboard textures MAY be used. The cap lives in `src/shared/Config.luau`,
  is stated by the feature that adds them, and is measured.
- A theme swaps its atlases and never the meshes.
- World assets MUST NOT use SurfaceAppearance/PBR maps, transparency or a light per prop.
  Glow is `Material.Neon`.
- Ball cosmetics (skins) MAY use their own texture of at most 512 px. Toppers use the world
  atlas.
- Uploaded asset IDs MUST be recorded in `src/shared/Assets.luau` and MUST NOT be hard-coded
  anywhere else.
- Creator Store models containing scripts MUST NOT be used. Mesh-only models MAY be used
  after an inspection confirms they contain no scripts.

Rationale: one atlas per theme keeps phones fast and makes a season a texture swap, and
strict budgets keep the look coherent. One extra atlas and a capped billboard set let a street show
shop fronts at a measured cost. Stylised real reads as a real city for the 16+ launch
audience, where flat-shaded toy art reads as a kids' game. Scripted free models are a
security risk.

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

A task is done only when gates 1, 3, 4 and 5 hold. A feature is ready for its pull request only
when gates 1 to 5 hold. A feature under gate 6 is finished, and may merge, only when gate 6 holds
too:

1. Format, lint, type check and unit tests pass: `scripts/check.sh` exits 0.
2. Once per feature, before its pull request, if the feature touches server, client or UI
   behaviour: an agent has run a Studio playtest through the Studio MCP server, read the
   console, and seen no new errors or warnings. For UI changes it has also inspected a capture
   at a phone resolution. Capture files MUST NOT be required, because the Studio MCP cannot save
   them.
3. If the task adds an asset: it is within budget and its ID is in `src/shared/Assets.luau`. When
   the upload is an owner hand-off, it has its stand-in or fallback instead and the hand-off is on
   the release-candidate list.
4. If the task adds a player-facing string: the string is in the localisation tables.
5. The task is ticked in `tasks.md`.
6. If the feature's main output is a world map, world art or the look of the player's ball: images
   of it exist where the owner can see them, and the owner has approved them, from fixed shots and
   by playing the build. Gate 2's capture-file exemption does not apply here. The pull request MAY
   be opened to show the images and MUST NOT be merged before this approval. Automated tests are a
   floor and never prove that the look is good.

Each pull request description MUST state which gates applied and how each was met.

What a feature may require, and what waits for the RC:

- A feature's gates and its `tasks.md` MAY require only what an agent can run: `scripts/check.sh`,
  Lune, Jest-Lua and the Studio MCP server. Pacing is checked by the Lune pace test, and timed
  live bot runs are not required. Gate 6's owner approval is the one exception, and it is a gate,
  not a task.
- Apart from gate 6, anything that needs a person, a real device, the final map or owner taste goes
  in the release-candidate list, `docs/release-candidate.md`. It MUST NOT be a task in `tasks.md` or
  a human item, and MUST NOT hold a feature. Apart from the two waits below, only the Human Approval
  list can stop a feature. Tuning values, phone checks and the people round stay on the list, for a
  gate 6 feature too.
- Owner hand-offs (mesh uploads, music picks and similar) MUST NOT block a feature. It ships with
  its stand-in or fallback, and the hand-off goes on the list in a batch.
- An agent-run check that fails twice because of tooling, not a game defect, moves to the list
  with a note of what was tried. Agents MUST NOT keep building new drivers for it. A game defect
  is still fixed. Gate 2's Studio playtest and console read are exempt: they MUST run before the
  pull request, so a feature waits for Studio and Rojo if it has to. This is the first of two waits
  outside the Human Approval list.
- Gate 6's owner approval is the second wait: it MAY hold a feature. The two-failure rule does not
  excuse a gate 6 feature from having images. If captures fail, the agent asks the owner once to
  keep Studio in front and uses another route, such as rendering the world data in Blender.
- An open question with a proposed default, not on the Human Approval list, is settled by taking
  the default and recording it in the spec and on the list. The owner can overrule it later.

## Human Approval Required

Agents MUST stop and get owner approval before any of the following:

- Publishing to the live place.
- DataStore schema, key name or migration changes, from the first publish to the live place on
  (before that they are pre-approved under Principle VIII).
- Creating or changing any real game pass, developer product or price (Principle V). Coin prices
  and stubbed products behind a flag that is off need no approval.
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

**Version**: 4.0.0 | **Ratified**: 2026-10-24 | **Last Amended**: 2026-11-02
