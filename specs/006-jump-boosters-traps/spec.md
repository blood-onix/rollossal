# Feature Specification: Mechanics Pass — Scaled Jump, Boosters, and Season-Neutral Traps

**Feature Branch**: `006-jump-boosters-traps`

**Created**: 2026-10-30

**Status**: Draft

**Input**: User description: "Make the default mode richer before it gets polish and before people test it. Owner feedback (2026-10-26): \"jump is useless, you cannot jump over the obstacles or boxes\", and the game needs boosters and traps so players can trick each other. Design brief: docs/rollossal-gdd.md §3.1 (ball control), §3.2 (bumping); design system: docs/design/03-city-level.md (layout rules), 01-world-kit.md (slots). Constitution: I (grey-box first), II, III, IV, VI, VII (every booster and trap behind a flag). Depends on 004. Grey-boxed on Snow Village; 004e (Downtown) places the boosters and traps from the marker spots this feature defines."

## Clarifications

### Session 2026-10-30

- Q: How should player-to-player tricking work in the default mode (and do you approve the cartoon-bumping maturity scope)? → A: Ball-to-ball bumps. Knocked-off objects scatter and anyone can grab them. Victims get 3 s of immunity. The slick patch is a booster pickup that lays a short trail on its own (no extra button).
- Q: Should the diameter-scaled jump be a single-tap hop or include a hold-to-charge higher jump? → A: Variable jump: pressing hops right away to 0.6×, holding up to 0.25 s stretches it to 0.85×.
- Q: Do you approve the proposed 4 starter boosters and 4 season-neutral traps including the roaming Street Sweeper? → A: Approve all 4 boosters and 4 traps with Street Sweeper.

## Owner Approval Gate *(Constitution Principles I, IV, V, VI, VII & Human Approval Required)*

- **Player-to-Player Tricking & Maturity Questionnaire Gate (Confirmed Owner Decision, 2026-10-30, Constitution Principle IV)**:
  - **Ball-to-Ball Bumps**: Approved for the default mode under the "cartoon bumping" maturity scope. When a larger ball bumps a smaller ball at speed, up to `Config.knockOffCount` (`3`) recent stuck objects scatter onto nearby ground where **any player can grab them**, and the bumped victim receives **3 seconds of bump immunity** (`Config.ballBumpImmunitySeconds = 3.0`). Player-to-player swallowing remains strictly out of the default mode (Feature 009).
  - **Auto-Laying Slick-Trail Pickup (No Extra Button)**: Picking up a slick-patch booster pickup (`slick_trail`) automatically lays a short trail of temporary slick patches behind the rolling ball on its own over its active duration, requiring **no extra HUD button** (preserving one-thumb mobile play with the single Jump action button).
- **Variable Jump Input Model (Confirmed Owner Decision, 2026-10-30, Constitution Principle VI)**:
  - **Immediate 0.6× Hop + 0.25 s Hold Extension to 0.85×**: Pressing the `>= 96 px` mobile Jump button or Spacebar hops **immediately** on press to clear `0.6 × ballDiameter` (with a `1.6`-stud minimum floor at Tier 1 so `1.5`-stud kerbs clear from `startDiameter = 2`). Holding the button during the first `0.25` seconds (`Config.jumpHoldMaxSeconds = 0.25`) of ascent smoothly stretches the jump apex up to `0.85 × ballDiameter` (`Config.jumpHoldClearRatio = 0.85`).
- **Starter Booster & Trap Lineup (Confirmed Owner Decision, 2026-10-30)**:
  - Approved all 4 starter boosters (**Dash**, **Magnet**, **Spring**, **Shield**, plus the auto-laying **Slick Trail** pickup) and all 4 season-neutral traps (**Slick Patch**, **Bumper Post**, **Slow Patch**, and the roaming **Street Sweeper**, kept distinct from Holiday City's absorbable Tier 4 parked snowplough).
- **Grey-Box Gate (Constitution Principle I)**: All jump, booster, and trap mechanics are proven in grey-box / placeholder form on Snow Village first (via an agent-driven Studio playtest plus the owner playing and signing off in `specs/006-jump-boosters-traps/playtest.md`) before Feature 004c applies polish and before Feature 004d conducts the outside-people playtest.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Variable Diameter-Scaled Jump That Clears Unabsorbable Obstacles at Every Tier (Priority: P1)

Today, pressing Jump applies a fixed small impulse that clears almost nothing once the ball grows past its starting size. With the variable diameter-scaled jump:
- **Immediate Tap Hop (`0.6×` diameter)**: The instant a grounded player presses Jump (`>= 96 px` mobile button or Spacebar), the ball takes off immediately with enough vertical velocity to clear an obstacle `0.6 × ballDiameter` tall (just above the `0.4 × ballDiameter` absorb threshold), with a minimum clearance floor of `1.6` studs so Tier 1 kerbs (`1.0–1.5` studs) and stoops are always cleared from `startDiameter = 2`.
- **Hold Extension (`0.85×` diameter over `0.25 s`)**: If the player continues holding the Jump input for up to `0.25` seconds while ascending, upward extension stretches the jump apex smoothly up to `0.85 × ballDiameter` to reach higher ledges, container stacks, and climbing routes. Releasing early stops the extension immediately.
- **Anti-Flight & Server Vertical Guard**: A ground check and short jump cooldown prevent chaining jumps into mid-air flight. The server's movement guard (`BallGuard` and `BallService`) knows the legitimate vertical velocity and `0.85 × ballDiameter` variable-jump apex height so valid taps and held jumps are never rubber-banded or flagged, while mid-air jump spam or vertical fly/teleport exploits are rejected and corrected.
- **Grey-Box Landing Feedback**: On landing from a jump or drop, the player gets a landing thump sound and a brief landing squash on the ball (with a non-audio visual cue and full respect for `Reduce motion`).

**Why this priority**: Directly resolves the owner's primary gameplay feedback (2026-10-26: *"jump is useless, you cannot jump over the obstacles or boxes"*) and unlocks vertical routes required by `docs/design/03-city-level.md` ("Something to climb": Tier 1 kerbs and stoops, ramps, rooftops, and elevated platforms).

**Independent Test**: Can be verified via Lune unit tests for the pure jump height/impulse rules (both `0.6×` tap and `0.85×` `0.25 s` hold) at fixed diameters across Tiers 1–5, Jest-Lua Studio tests for jump cooldown and vertical anti-cheat enforcement, and a Studio playtest confirming a ball at each of Tiers 1–5 hops cleanly over an unabsorbable `0.6 × diameter` obstacle on tap (and `0.85 × diameter` on a `0.25 s` hold) and lands with squash/thump feedback and zero server violation warnings.

**Acceptance Scenarios**:

1. **Given** a grounded ball at any tier diameter $D$ (e.g., `2`, `5`, `12`, `30`, or `70` studs) facing a solid obstacle or kerb up to `0.6 × D` tall (and at least `1.5` studs tall at $D = 2$), **When** the player taps the `>= 96 px` mobile Jump button or presses Spacebar while steering forward, **Then** the ball takes off immediately on press and its jump apex clears the top of the `0.6 × D` obstacle; **When** the player holds Jump for `0.25` seconds from take-off, **Then** the jump apex stretches to clear `0.85 × D`.
2. **Given** a player has just jumped and the ball is airborne or within the jump cooldown window, **When** the player repeatedly taps or holds Jump in rapid succession, **Then** additional jump take-offs are refused until the ball is grounded again and the cooldown has elapsed, preventing mid-air flight.
3. **Given** the server's per-step movement check (`BallGuard` / `BallService`), **When** a client executes a legitimate tap (`0.6 × D`) or held (`0.85 × D`) jump at any tier diameter, **Then** the server records zero speed or displacement violations; conversely, when a client forces vertical velocity or vertical displacement beyond the allowed variable-jump/launch envelope, the server clamps or resets the ball and records a violation.
4. **Given** an airborne ball lands back on solid ground with downward vertical speed above the landing threshold, **When** contact with the ground is re-established, **Then** a landing thump sound plays (respecting `effectsVolume`) and the ball performs a brief landing squash (suppressed when `Reduce motion` is enabled).

---

### User Story 2 - World Boosters with Server-Authoritative Claiming and Active HUD Cues (Priority: P1)

Players can roll into world boosters placed at `BoosterSpot` markers to gain temporary movement, tricking, or defensive advantages during a run. Each booster type is controlled by its own feature flag and tuning parameters in `src/shared/Config.luau`, is claimed through server validation (exists, not currently taken/cooling down, within contact range, and under the claim rate limit), respawns after its configured delay, ends immediately when the run ends, and is never sold for Coins or Robux (Constitution Principle V):
- **Dash (`dash`)**: Grants a short speed burst (raising target roll speed and the server's accepted speed cap to an explicit boost ceiling for the burst duration so a boosted ball is never flagged while a speed-hacking ball above the boost ceiling still is).
- **Magnet (`magnet`)**: For a few seconds, nearby absorbable world objects (`size <= 0.4 × diameter` within the magnet pull radius) drift smoothly toward the ball; every resulting absorption is still validated individually by the server.
- **Spring / Launch Pad (`spring`)**: Launches the ball upward and forward onto rooftops or elevated routes (such as Snow Village's `Y = 11` rooftops), with the server movement guard permitting the launch arc.
- **Shield / "Sticky Coat" (`shield`)**: Coats the ball so the next qualifying bump (from an obstacle, bumper post, roaming hazard, or larger ball) knocks zero objects off and consumes the shield.
- **Slick-Trail Pickup (`slick_trail`)**: Picking up a slick-patch booster automatically lays a short trail of temporary slick patches behind the player's rolling ball on its own (requiring no extra button). Other balls that roll across those trail patches slip with reduced steering control, while the ball that laid the trail is unaffected by its own patches.

While any timed or single-use booster is active on the player's ball, the HUD displays a clear status chip with both an icon and a localised text label (never colour or sound alone, Constitution Principles VI & IX).

**Why this priority**: Adds pace variety, rooftop routing, automatic trail-laying trickery, and counter-play against bumps and traps while strictly upholding Constitution Principle II (Server Authority), Principle V (Ethical Monetization), and Principle VI (one-thumb mobile play).

**Independent Test**: Can be verified via Lune unit tests for pure booster duration, speed-cap, magnet-radius, slick-trail drop spacing/lifetime, and shield-absorption rules; Jest-Lua Studio tests verifying server claim validation (rejecting taken, out-of-range, flag-disabled, or rate-limited claims and verifying the server speed check with and without Dash); and a Studio playtest exercising all boosters on Snow Village.

**Acceptance Scenarios**:

1. **Given** an available **Dash** booster in an active run with its flag enabled, **When** the ball rolls within contact range and claims it, **Then** the server activates the Dash state on the session, the ball accelerates to the boosted speed for the configured duration without triggering a server speed/displacement violation, and a client exceeding the explicit boost speed cap (or moving at boost speed after Dash plus decay grace expires) is clamped/reset by the server.
2. **Given** an available **Magnet** booster is claimed, **When** the ball rolls near absorbable objects (`size <= 0.4 × ballDiameter`) within the magnet pull radius during the active window, **Then** those absorbable objects drift toward the ball and are absorbed through standard server validation, while unabsorbable obstacles (`size > 0.4 × ballDiameter`) do not drift.
3. **Given** a ball rolls onto a **Spring** booster, **When** the server validates the trigger, **Then** the ball is launched along the spring's upward/forward arc high enough to reach elevated rooftops without triggering a vertical or horizontal anti-cheat violation.
4. **Given** a ball with an active **Shield ("Sticky Coat")** and stuck objects hits an unabsorbable obstacle, trap, or larger ball above the bump threshold, **When** the server processes the bump, **Then** zero stuck objects are knocked off, the ball's diameter does not shrink, and the Shield effect is consumed.
5. **Given** a ball claims a **Slick-Trail** booster pickup (`slick_trail`), **When** the ball rolls forward during the booster's active window, **Then** it automatically spawns a short trail of temporary slick patches behind itself without any extra button press; another ball rolling onto those patches experiences the slick low-control effect until the trail patches expire.
6. **Given** a booster pickup has just been claimed (or a client sends a claim request when out of range, over the rate limit, after the run ends, or while that booster's feature flag is `false`), **When** the server evaluates the claim request, **Then** the request is silently rejected and grants no effect.

---

### User Story 3 - Season-Neutral Traps, Roaming Street Sweeper, and Ball-to-Ball Bumps (Priority: P1)

World traps and hazards are season-neutral mechanics placed at `TrapSpot` markers in world data and dressed per theme (`winter` Holiday City vs. `city` Sunny City) purely through content/theme data, each gated behind its own feature flag in `Config.Flags`:
- **Slick Patch (`slick`)**: A low-traction surface patch (`winter`: ice patch; `city`: spilled water / oil-free wet puddle) that reduces steering turn rate and causes the ball to slide with low control while crossing it and for a brief slip window afterward.
- **Bumper Post (`bumper`)**: A real street bollard (`winter`: snow-capped striped bollard; `city`: street bollard) that physically bounces the ball back on contact and triggers the knock-off rule (scattering up to `3` recent stuck objects unless protected by Shield).
- **Slow Patch (`slow`)**: A high-drag surface patch (`winter`: slush patch; `city`: wet sand / fresh tar patch) that reduces the ball's roll speed while crossing it and for a brief linger window.
- **Roaming Street Sweeper (`sweeper`)**: A non-absorbable municipal Street Sweeper (`winter`: winter salt-brush sweeper; `city`: city street sweeper—distinct from Holiday City's parked absorbable snowplough) that patrols a deterministic street loop and bumps any ball it touches, scattering up to `3` recent stuck objects (unless protected by Shield).
- **Ball-to-Ball Bumps (`BallToBallBumps`)**: When a larger player ball (`diameterA >= Config.ballBumpSizeRatio × diameterB`) bumps a smaller player ball at or above `Config.bumpSpeedThreshold`, up to `Config.knockOffCount` (`3`) recent stuck objects are knocked off the smaller ball (unless protected by Shield) and scatter onto nearby ground where **any player can grab them** after the brief scatter grace period. The bumped victim receives **3 seconds of bump immunity** (`Config.ballBumpImmunitySeconds = 3.0`) so it cannot be repeatedly stripped, while the larger ball is unaffected and never swallows the smaller ball.

All traps and bumps follow Constitution Principle IV: no health bars, no damage, no player death, and no loss of persistent coins or book progress. Knocked-off objects are a "little jackpot" that anyone nearby can collect.

**Why this priority**: Fulfils the owner's request for traps and player-to-player trickery while preserving the "fair and kind" pillar (`docs/design/03-city-level.md` "Cascades") and ensuring zero-code seasonal switching between `winter` and `city` (Constitution Principle VII).

**Independent Test**: Can be verified by Lune unit tests for trap effect rules, knock-off counts, 3-second victim immunity, and theme dressing mappings; Jest-Lua Studio tests for bumper/sweeper/ball-to-ball knock-off validation, shared re-collection of scattered objects, 3-second victim immunity, and Shield interaction; and a Studio playtest verifying every trap works in both `winter` and `city` themes with zero console errors or warnings.

**Acceptance Scenarios**:

1. **Given** a world loaded in the `"winter"` theme and then switched to the `"city"` theme in data, **When** the world's `TrapSpot` markers spawn their traps, **Then** the Slick Patch, Bumper Post, Slow Patch, and Street Sweeper use their `"winter"` visual roles/dressing in `"winter"` and automatically switch to their `"city"` visual roles/dressing in `"city"` without any code changes.
2. **Given** a ball rolls across a **Slick Patch** (static or trail-laid) or a **Slow Patch**, **When** the ball is within the patch footprint (and during the brief post-contact linger window), **Then** the Slick Patch reduces steering responsiveness / lateral grip and the Slow Patch reduces roll speed by its configured multiplier, and both display a HUD status cue (icon + localised label) while active.
3. **Given** a ball with at least 3 stuck objects and no active Shield contacts a **Bumper Post** or the roaming **Street Sweeper**, **When** the server validates the contact and bump cooldown, **Then** up to `Config.knockOffCount` (`3`) most recent stuck objects scatter onto nearby ground for re-collection by any player, the ball shrinks by their volume (never below `startDiameter`), and a knock-off camera shake triggers (unless `Reduce motion` is enabled).
4. **Given** a larger ball $A$ (`diameterA >= Config.ballBumpSizeRatio × diameterB`) bumps a smaller ball $B$ above `Config.bumpSpeedThreshold`, **When** $B$ has no active Shield and is not within its 3-second victim immunity window, **Then** up to `3` recent stuck objects scatter from $B$ onto the ground where either $A$, $B$, or any other player can absorb them after `Config.scatterGrace`, $A$ is unaffected, and $B$ gains `3.0` seconds of immunity against further bumps.
5. **Given** a feature flag for any individual booster, trap, or ball-to-ball bump in `Config.Flags` is set to `false`, **When** the world spawns or steps at runtime, **Then** that specific mechanic is inactive/omitted without affecting any other booster, trap, or core gameplay system.

---

### User Story 4 - Validated Booster & Trap Marker Spots in World Data (Priority: P2)

Booster and trap placements are authored as structured `MarkerDef` entries (`kind = "BoosterSpot"` or `"TrapSpot"`, with specific booster/trap item keys and optional patrol waypoints) in `WorldDef.environment.markers`. Lune content validation enforces that every marker has a unique ID, names a valid booster or trap type, sits inside the playable world bounds, does not overlap static geometry or other markers, and is protected by a `keepOutAreas` rectangle (`kind = "marker"`) so theme overlays never cover or block a booster or trap spot. Snow Village includes marker spots covering every starter booster and trap so the full mechanics pass can be grey-boxed and playtested on Snow Village before Feature 004e authors Downtown.

**Why this priority**: Decouples the mechanics pass (004b) from Downtown level authoring (004e) while guaranteeing through automated Lune tests that theme overlays in 005 and 004e never collide with gameplay pickups or hazards.

**Independent Test**: Can be verified by running `scripts/check.sh` and Lune unit tests (`tests/unit/SnowVillage.test.luau` and `tests/unit/Markers.test.luau`), confirming all marker spots validate cleanly and spawn active boosters and traps in Studio.

**Acceptance Scenarios**:

1. **Given** `WorldDef.environment.markers` in `SnowVillage.luau`, **When** Lune validation runs, **Then** there are at least 6 `BoosterSpot` markers and at least 6 `TrapSpot` markers covering every starter booster kind (`dash`, `magnet`, `spring`, `shield`, `slick_trail`) and every starter trap kind (`slick`, `bumper`, `slow`, `sweeper`), all within `halfExtent`, with unique IDs and matching `keepOutAreas` entries.
2. **Given** a malformed marker definition (unknown booster/trap kind, out-of-bounds coordinates, duplicate ID, missing waypoint for a roaming hazard, or overlapping a theme overlay), **When** the Lune marker validator runs, **Then** validation fails with a clear diagnostic error.

---

### Edge Cases

- **Chained Jumps, Variable Hold Cutoff & Slope Hopping**: A player holding or rapidly mashing Jump while climbing a ramp or landing on a sloped surface MUST NOT accumulate upward velocity across frames; the initial `0.6 × D` take-off impulse only fires when grounded AND `now - lastJumpAt >= Config.jumpCooldown` AND current vertical velocity is not already upward from a recent jump or spring launch, and the `0.85 × D` hold extension applies only while the Jump input remains continuously held within the first `0.25` seconds (`Config.jumpHoldMaxSeconds`) of that jump's take-off.
- **Dash Speed Decay vs. Server Anti-Cheat**: When a player's **Dash** burst expires while the ball is rolling at top boosted speed, physical momentum takes a moment to decelerate back to normal `maxServerBallSpeed`. The server's `BallGuard` check MUST include a short post-boost decay grace window (`Config.boostDecayGrace`, e.g., `0.5` s after Dash ends) so the ball is not falsely flagged for a speed violation on the exact frame the timer expires.
- **Spring Launch vs. Vertical & Horizontal Displacement Checks**: A **Spring** launches the ball faster vertically (and on an arc) than normal ground rolling. The server records the launch timestamp and expected flight window on the session so `BallGuard` validates the ball against the spring launch envelope during flight and reverts to normal ground bounds after landing or flight expiry.
- **Shield & 3-Second Victim Immunity vs. Multiple Simultaneous Hazards**: When a ball with an active **Shield** hits a Bumper Post, Street Sweeper, or larger ball, the Shield absorbs the hit, grants the standard `Config.bumpCooldown` (`1.0` s) immunity window so the same hazard does not immediately strip 3 objects on the next frame, and clears the Shield state. When an unshielded ball is knocked off by a ball-to-ball bump, it receives `Config.ballBumpImmunitySeconds` (`3.0` s) of immunity so neither the same attacker nor a second ball can chain-strip it within those 3 seconds.
- **Slick-Trail Pool Cap & Self-Immunity**: Temporary slick patches laid automatically behind a ball with an active `slick_trail` booster are pooled (bounded by a fixed per-server pool cap so active parts stay strictly within `Config.Budgets.maxActivePartsPerServer = 2000`), despawn automatically after `Config.slickTrailPatchLifetime` seconds, and never slow or slip the ball that laid them.
- **Magnet Pull on Taken or Culled Objects**: **Magnet** only pulls world objects that are currently `Available`, not in their scatter grace period, not hidden by `WorldCuller`, and absorbable (`size <= 0.4 × authoritativeDiameter`). If another player absorbs an object while it is drifting toward a magnetized ball, the server's `AlreadyTaken` check cleanly rejects the second ball's absorb request and snaps the pooled part to Taken state.
- **Run End, Respawn, or Hub Transition During Active Effects**: When a run ends (bell at `240` s), the player taps **Roll again** or **Back to hub**, or the ball falls below `Config.fallRespawnY` / resets, all active booster and trap effects (`Dash`, `Magnet`, `Shield`, `SlickTrail`, `Slick`, `Slow`, spring flight grace, and active trail patches owned by that run) on that session MUST be cleared immediately.
- **Roaming Street Sweeper Streaming & Determinism**: The Street Sweeper's position is driven deterministically from server elapsed clock time along its authored closed waypoint loop in `WorldDef` so all clients and the server agree on its position without physics desync or NPC humanoid overhead.

## Requirements *(mandatory)*

### Functional Requirements

#### Part A: Variable Diameter-Scaled Jump & Vertical Movement Guard (`src/shared/Rules/`, `src/shared/Config.luau`, `src/client/BallController.luau`, `src/server/BallService.luau`)

- **FR-001**: A pure rules module in `src/shared/Rules` (with zero Roblox APIs, validated by `scripts/check.sh` and Lune tests) MUST compute the variable jump clearance heights, take-off vertical velocity/impulse, hold-extension acceleration, and maximum legitimate vertical apex from the ball's authoritative diameter $D$ and tuning parameters in `src/shared/Config.luau`:
  - Pressing Jump while grounded MUST immediately apply the base take-off vertical velocity/impulse so that at any tier diameter $D \ge 2$ studs, a tap-only jump apex clears an obstacle at least `Config.jumpClearRatio × D` (`0.6 × D`, above the `0.4 × D` absorb limit) tall, with a minimum clearance floor (`Config.minJumpClearHeight = 1.6` studs) so Tier 1 kerbs (`1.0–1.5` studs) and stoops are always clearable from `startDiameter = 2`;
  - Holding the Jump input continuously after take-off for up to `Config.jumpHoldMaxSeconds` (`0.25` s) MUST smoothly extend the jump apex up to `Config.jumpHoldClearRatio × D` (`0.85 × D`, with a proportional minimum floor at $D = 2$), stopping immediately if the player releases the button before `0.25` s;
  - Jump cooldown (`Config.jumpCooldown`) and grounded state rules MUST prevent mid-air jumps and jump-spam chaining.
- **FR-002**: `src/shared/Rules/BallGuard.luau` and `src/server/BallService.luau` MUST validate both horizontal and vertical movement:
  - Horizontal speed and step displacement MUST respect `Config.maxServerBallSpeed` normally, or `Config.boostSpeedCap` while the session has an active server-granted **Dash** or **Spring** effect (including `Config.boostDecayGrace` seconds of deceleration grace after expiry);
  - Vertical velocity and vertical step displacement MUST be checked against the maximum legitimate upward velocity and `0.85 × D` held-jump apex height for the ball's current diameter (from the pure jump rule in FR-001, or the active **Spring** launch velocity when spring-launched) so legitimate tap jumps, `0.25` s held jumps, and spring launches produce zero violations, while unapproved vertical flight or upward teleports are clamped or reset to `lastValidPosition` and logged as violations.
- **FR-003**: `src/client/BallController.luau`, `src/client/JumpButton.luau`, and `src/client/Feedback.luau` MUST keep the mobile Jump button at least `96 × 96` px (`Config.minTouchTarget`), emit press and release events so both touch and Spacebar support the immediate `0.6×` hop and up-to-`0.25 s` hold to `0.85×` with one thumb, enforce the ground check and jump cooldown locally, and play grey-box landing feedback when the ball transitions from airborne to grounded with downward speed $\ge$ `Config.landingMinSpeed`:
  - A preloaded landing thump sound (`Assets.sounds.land`) played through the `Effects` `SoundGroup`;
  - A brief visual squash pulse on the ball (`Config.landingSquashScale`, `Config.landingSquashDuration`) that is skipped when `Reduce motion` is enabled.

#### Part B: World Boosters (`src/shared/Rules/`, `src/shared/Config.luau`, `src/server/`, `src/client/`)

- **FR-004**: Each starter booster MUST have its tuning numbers in `src/shared/Config.luau` and its own feature flag in `Config.Flags` (`BoosterDash`, `BoosterMagnet`, `BoosterSpring`, `BoosterShield`, `BoosterSlickTrail`, plus master flag `Boosters`):
  - **Dash (`dash`)**: Grants a speed multiplier (`Config.dashSpeedMultiplier`) for `Config.dashDuration` seconds, raising the client target speed cap and server `BallGuard` speed ceiling to `Config.boostSpeedCap`;
  - **Magnet (`magnet`)**: Active for `Config.magnetDuration` seconds; pulls nearby `Available`, absorbable world objects (`size <= Config.absorbRatio × diameter`) within `Config.magnetRadiusFactor × diameter` toward the ball at `Config.magnetPullSpeed`, with every absorb still validated by `AbsorbService`;
  - **Spring (`spring`)**: Applies an upward (`Config.springVerticalSpeed`) and forward (`Config.springForwardSpeed`) launch velocity sufficient to reach elevated routes and rooftops (`Y = 11+` studs), registering a server launch window (`Config.springFlightDuration`) for `BallGuard`;
  - **Shield (`shield`)**: Active for up to `Config.shieldDuration` seconds or until the next knock-off event; intercepts the next bump/trap/ball-bump knock-off so `0` objects are popped from `stuckStack` and diameter is unchanged, then clears the shield and applies `Config.bumpCooldown`;
  - **Slick-Trail Pickup (`slick_trail`)**: Active for `Config.slickTrailDuration` seconds; automatically drops a short trail of pooled temporary slick patches behind the rolling ball at regular intervals (up to `Config.slickTrailMaxPatches` per trail, lasting `Config.slickTrailPatchLifetime` seconds each) with no extra button required. Other balls crossing those patches receive the slick low-control effect; the laying ball is immune to its own trail.
- **FR-005**: Booster claiming MUST be server-authoritative:
  - A dedicated RemoteEvent (`Remotes.ClaimBooster`) accepts only a single `string` marker/booster ID and runtime type-checks it;
  - The server verifies that the run accepts pickups, the corresponding booster flag is `true`, the player is within the claim rate limit, the booster instance exists and is `Available` (not on respawn cooldown), and the ball is within `ballRadius + boosterRadius + Config.absorbDistanceTolerance`;
  - Consumable pickups (`dash`, `magnet`, `shield`, `slick_trail`) enter a `Taken` state and respawn after `Config.boosterRespawnDelay` seconds; `spring` pads remain in place with a per-player trigger cooldown (`Config.springCooldown`);
  - Active booster state is published on the ball's attributes and cleared on run end, ball reset, or respawn. Boosters MUST NOT be purchasable with Coins or Robux (Constitution Principle V).

#### Part C: Season-Neutral Traps, Hazards & Ball-to-Ball Bumps (`src/shared/Rules/`, `src/shared/Content/`, `src/server/`, `src/client/`)

- **FR-006**: Traps and hazards MUST be season-neutral mechanics defined in content data and dressed per theme (`winter` and `city`) via theme palette roles and dressing definitions, each behind its own feature flag in `Config.Flags` (`TrapSlick`, `TrapBumper`, `TrapSlow`, `TrapSweeper`, plus master flag `Traps`):
  - **Slick Patch (`slick`)**: Lowers steering responsiveness / turn traction to `Config.slickTurnMultiplier` while on the patch and for `Config.slickLingerSeconds` after leaving (`winter`: ice patch using `w-ice` / `w-season`; `city`: oil-free water puddle using `w-water`);
  - **Bumper Post (`bumper`)**: Solid street bollard obstacle that bounces the ball (`Config.bumperBounceSpeed`) and triggers the server knock-off rule on contact without requiring the ball to exceed `bumpSpeedThreshold` (`winter`: festive/snow-capped bollard; `city`: street bollard);
  - **Slow Patch (`slow`)**: Multiplies target roll speed by `Config.slowSpeedMultiplier` while on the patch and for `Config.slowLingerSeconds` after leaving (`winter`: slush patch; `city`: wet sand / fresh tar patch);
  - **Roaming Street Sweeper (`sweeper`)**: Non-absorbable municipal street sweeper moving deterministically along closed loop waypoints at `Config.sweeperSpeed` (`winter`: winter municipal sweeper; `city`: city street sweeper—never using the `snowplough` asset/id, which is an absorbable Tier 4 object). Contact bounces the ball and triggers the server knock-off rule.
- **FR-007**: When ball-to-ball bumping is enabled (`Config.Flags.BallToBallBumps = true`), a ball $A$ contacting another player's ball $B$ in an active run triggers a knock-off on $B$ (scattering up to `Config.knockOffCount` (`3`) stuck objects from $B$ onto the ground where **any player can absorb them** once `Config.scatterGrace` elapses, while $A$ is unaffected) if and only if:
  - $A$'s authoritative diameter is at least `Config.ballBumpSizeRatio` (e.g., `1.25×`) times $B$'s authoritative diameter;
  - The relative or peak approach speed of $A$ meets `Config.bumpSpeedThreshold`;
  - Both balls are within contact range on the server;
  - $B$ is not within its **3-second post-bump victim immunity window** (`Config.ballBumpImmunitySeconds = 3.0`) and does not have an active **Shield** (if $B$ has Shield, `0` objects are knocked off, the Shield is consumed, and $B$ receives standard bump immunity);
  - Upon a ball-to-ball knock-off, $B$ is granted `Config.ballBumpImmunitySeconds` (`3.0` s) of bump immunity;
  - Neither ball is swallowed or destroyed (player-to-player swallowing remains strictly disabled in the default mode per Constitution Principle IV).
- **FR-008**: Every active booster (`dash`, `magnet`, `shield`, `slick_trail`) and active surface trap effect (`slick`, `slow`) on the local player's ball MUST be shown on the HUD with an icon from `src/shared/Content/Icons.luau` and a localised label from `src/shared/Localization/Strings.luau` (in both English `en` and Spanish `es`, `>= 18 px` text on phones, never colour or sound alone).

#### Part D: Marker Spots in World Data & Automated Tests (`src/shared/Content/Worlds/SnowVillage.luau`, `tests/unit/`, `tests/studio/`)

- **FR-009**: `MarkerDef` in `src/shared/Content/GreyBoxRoom.luau` and `src/shared/Content/Worlds/SnowVillage.luau` MUST define structured placement markers for boosters and traps (`id`, `kind: "BoosterSpot" | "TrapSpot"`, `subKind: "dash" | "magnet" | "spring" | "shield" | "slick_trail" | "slick" | "bumper" | "slow" | "sweeper"`, `x`, `y`, `z`, `yaw`, and optional `waypoints` for `sweeper`), and `WorldBuilder` / `WorldSpawner` (or a dedicated `HazardService`) MUST instantiate and pool them from world data within `Config.Budgets.maxActivePartsPerServer` (`2,000`).
- **FR-010**: Lune unit tests (`tests/unit/`) invoked by `scripts/check.sh` MUST verify with fixed hand-computed expected values:
  - Variable jump clearance height and impulse from diameter across fixed diameters (`2, 5, 12, 30, 70` studs) for both immediate tap (`0.6×` diameter, floor `1.6` studs) and `0.25 s` hold (`0.85×` diameter);
  - Vertical and boosted-horizontal `BallGuard` verdicts (accepting valid tap and `0.25 s` held jumps, spring launches, and Dash speeds within cap; rejecting speeds/displacements above cap);
  - Booster durations, magnet eligibility, slick-trail patch lifetime/spacing, and Shield knock-off prevention;
  - Trap speed/turn multipliers, knock-off object counts (`0` with Shield or during 3 s victim immunity, up to `3` without Shield), ball-to-ball size ratio and 3 s immunity window, and deterministic Street Sweeper waypoint interpolation;
  - Marker validation on `SnowVillage` (unique IDs, valid `subKind`s, all starter boosters and traps represented, inside world bounds, protected by `keepOutAreas` in both `winter` and `city` themes).
- **FR-011**: Jest-Lua Studio integration tests (`tests/studio/`) MUST verify:
  - A booster claim is refused when already taken, out of range, over the rate limit, when the run is inactive, or when its feature flag is `false`;
  - The server speed check accepts a Dash-boosted speed within `Config.boostSpeedCap` and clamps/records a violation for a speed above `Config.boostSpeedCap` (or an unboosted ball above `Config.maxServerBallSpeed`);
  - Jump spam / mid-air jump attempts are refused by cooldown/grounding, held jump extension stops after `0.25 s` or release, and vertical teleport attempts are reset by `BallService`;
  - Traps, auto-laid slick trails, and ball-to-ball bumps respect `Shield`, enforce the `3.0 s` victim immunity window on ball-to-ball bumps, and scatter knocked-off objects that any player can re-collect;
  - All new remotes accept only intent/ID arguments and reject non-string or extra arguments.

### Key Entities

- **JumpRule (`src/shared/Rules/Jump.luau` or `Movement.luau`)**: Pure functions mapping ball diameter and hold duration (`0..0.25` s) to immediate take-off velocity (`0.6 × diameter` clearance, floor `1.6` studs), hold extension acceleration (up to `0.85 × diameter` clearance), and maximum legitimate vertical apex height for server anti-cheat validation.
- **BoosterDef & ActiveBoosterState**: Content and runtime representation of world boosters (`dash`, `magnet`, `spring`, `shield`, `slick_trail`), including feature flag name, duration, cooldown/respawn delay, radius, pooled trail patches, and replicated session attributes.
- **TrapDef & HazardInstance**: Season-neutral hazard specification (`slick`, `bumper`, `slow`, `sweeper`) with per-theme visual role/dressing mappings (`winter` vs. `city`), effect multipliers/durations, knock-off behaviour, and deterministic patrol waypoints for roaming hazards.
- **MarkerDef (`BoosterSpot` / `TrapSpot`)**: World-data placement marker in `WorldDef.environment.markers` specifying the exact coordinates, orientation, booster/trap subtype, and patrol path, guarded by a `keepOutAreas` rectangle so theme overlays stay clear.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In automated Studio verification and playtesting, a grounded ball at each of the 5 tier entry diameters (`2`, `5`, `12`, `30`, and `70` studs) hops cleanly over an unabsorbable obstacle of height `0.6 × diameter` (and a `1.5`-stud kerb at diameter `2`) on a single tap, and up to `0.85 × diameter` on a `0.25 s` hold, with zero server anti-cheat violations.
- **SC-002**: 100% of Lune unit tests (variable jump scaling `0.6×` to `0.85×`, vertical/boosted `BallGuard`, booster durations and caps, slick-trail rules, trap knock-offs, 3 s ball-bump immunity, and `MarkerDef` validation) and 100% of Jest-Lua Studio tests (booster claim validation, boosted speed check, jump spam rejection, trap/shield/ball-bump knock-offs with shared re-collection, and remote argument validation) pass, and `scripts/check.sh` exits `0`.
- **SC-003**: Every starter booster (`dash`, `magnet`, `spring`, `shield`, `slick_trail`) and every starter trap (`slick`, `bumper`, `slow`, `sweeper`), plus ball-to-ball bump knock-offs, functions behind its individual `Config.Flags` toggle in a Studio playtest across both `"winter"` and `"city"` theme dressings on Snow Village, with zero new console errors or warnings and `>= 30 fps` maintained at `640 × 360`.
- **SC-004**: Grey-box check (Constitution Principle I) is completed on Snow Village via an agent-driven Studio run plus the owner playing and signing off in `specs/006-jump-boosters-traps/playtest.md` before any Feature 004c juice/polish or Feature 004d outside-people playtest begins.

## Scope & Boundaries

### In Scope

- Pure variable diameter-scaled jump rules (`0.6 × diameter` immediate tap hop, stretching up to `0.85 × diameter` when held up to `0.25 s`), ground check, jump cooldown, landing thump + placeholder landing squash, and vertical anti-cheat validation in `BallGuard` and `BallService`.
- Starter booster set (`dash`, `magnet`, `spring`, `shield`, plus the auto-laying `slick_trail` pickup) with server-authoritative claiming, pooling/respawning, explicit server boost speed cap, and HUD active-effect indicators (icon + localised En/Es label).
- Season-neutral starter traps and hazards (`slick`, `bumper`, `slow`, and roaming `sweeper`) with data-driven `winter` and `city` theme dressing, non-punitive knock-off scattering, and individual feature flags in `Config.Flags`.
- Player-to-player tricking in the default mode: ball-to-ball bump knock-offs on smaller balls (scattering up to 3 objects that anyone can grab, with 3 s victim immunity and Shield protection) and the auto-laying slick-trail booster pickup (no extra button).
- Structured `BoosterSpot` and `TrapSpot` marker definitions and Lune validation on Snow Village (ready for Feature 004e Downtown placement).
- Grey-box playtest verification on Snow Village (agent Studio run + owner sign-off in `playtest.md`).

### Out of Scope

- Authoring the Downtown world layout and placing Downtown's boosters and traps (**Feature 004e**).
- Polished squash-and-stretch animations, themed ground trail puffs, cascade prop animations, and final booster/trap VFX (**Feature 004c**).
- Playtesting with outside participants (adults and children aged 10–12) (**Feature 004d**).
- Player-to-player swallowing (**Feature 009**, Big Ball opt-in mode only per Constitution Principle IV).
- Selling any booster, trap, or gameplay advantage for Coins or Robux (forbidden by Constitution Principle V).

## Assumptions

- **One-Thumb Variable Jump Control**: Pressing the `>= 96 px` mobile Jump button (or Spacebar) always triggers the `0.6 × diameter` take-off velocity on the press frame with zero pre-charge lag, while holding the same button for up to `0.25 s` extends the jump to `0.85 × diameter`.
- **Auto-Laying Slick Trail Requires Zero New HUD Buttons**: The slick-patch pickup (`slick_trail`) is claimed by rolling over a `BoosterSpot` marker just like other boosters and automatically drops pooled slick patches behind the ball as it rolls, keeping the mobile screen free of extra action buttons.
- **Shared Re-Collection of Knocked-Off Objects**: Scattered objects from any knock-off (obstacle, Bumper Post, Street Sweeper, or ball-to-ball bump) land in the world pool as `Scattered` and become `Available` to **any** player once `Config.scatterGrace` (`1.0` s) elapses.
- **Snow Village Grey-Box Proving Ground**: Because Downtown (`004e`) depends on the marker schema defined here, all grey-box verification and theme-dressing switches (`winter` vs. `city`) for this feature run on Snow Village.
