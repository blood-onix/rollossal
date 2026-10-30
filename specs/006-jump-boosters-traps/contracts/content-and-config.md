# Contract: Content and Config (006)

Data-only surfaces. Content modules have no requires (they are plain tables); `Config` is frozen.

## `Config.Flags` additions

All `true` by default except where noted. A mechanic is live only if its master flag (where one exists) **and** its
own flag are true.

| Flag | Default | Gate |
| --- | --- | --- |
| `ScaledJump` | `true` | off restores the 001 hop (`jumpImpulse`) (D1) |
| `Boosters` | `true` | master for the five below |
| `BoosterDash`, `BoosterMagnet`, `BoosterSpring`, `BoosterShield`, `BoosterSlickTrail` | `true` | each booster |
| `Traps` | `true` | master for the four below |
| `TrapSlick`, `TrapBumper`, `TrapSlow`, `TrapSweeper` | `true` | each trap |
| `BallToBallBumps` | `true` | ball-to-ball knock-offs (owner approved 2026-10-30) |

## `Config` keys (values: research R-18, all provisional)

| Group | Keys |
| --- | --- |
| Jump | `jumpClearRatio`, `jumpHoldClearRatio`, `minJumpClearHeight`, `jumpHoldMaxSeconds`, `jumpCooldown`, `landingMinSpeed`, `landingSquashScale`, `landingSquashDuration`; existing `jumpImpulse` kept for the flag-off path |
| Vertical guard | `verticalSlack`, `airEnergyAllowance`, `maxSlopeRatio` |
| Speed | `dashSpeedMultiplier`, `boostSpeedCap`, `boostDecayGrace`; existing `maxServerBallSpeed` |
| Claiming | `boosterRadius`, `boosterRespawnDelay`, `boosterClaimRateLimit`, `springCooldown` |
| Durations | `dashDuration`, `magnetDuration`, `shieldDuration`, `slickTrailDuration` |
| Magnet | `magnetRadiusFactor`, `magnetPullSpeed`, `magnetMaxPulled`, `magnetScanInterval` |
| Spring | `springVerticalSpeed`, `springForwardSpeed`, `springFlightDuration` |
| Slick trail | `slickTrailSpacing`, `slickTrailMaxPatches`, `slickTrailPatchLifetime`, `slickTrailPoolSize` |
| Traps | `slickTurnMultiplier`, `slickLingerSeconds`, `slowSpeedMultiplier`, `slowLingerSeconds`, `bumperBounceSpeed`, `sweeperSpeed`, `sweeperBounceSpeed`, `hazardContactMargin` |
| Ball bumps | `ballBumpSizeRatio`, `ballBumpImmunitySeconds`, `ballBumpContactMargin` |

Reused unchanged: `knockOffCount`, `bumpSpeedThreshold`, `bumpSpeedWindow`, `bumpCooldown`, `scatterGrace`,
`absorbDistanceTolerance`, `absorbRatio`, `minTouchTarget`, `fallRespawnY`, `displacementSlack`,
`Budgets.maxActivePartsPerServer`.

`Config.test` additions: every key above exists with the right type; ratios in `(0, 1]` order as
`jumpClearRatio (0.6) < jumpHoldClearRatio (0.85)`; `1.0 ≥ slickTurnMultiplier > 0`, `1.0 ≥ slowSpeedMultiplier > 0`;
`boostSpeedCap > maxServerBallSpeed`; `minJumpClearHeight > 1.5` (a Tier 1 kerb clears);
`slickTrailMaxPatches ≤ slickTrailPoolSize` (the pool is shared by all balls and recycles oldest-first when full);
`Flags` has all 13 new keys; `minTouchTarget ≥ 96`. The spring pad's arc is checked by the Snow Village roof
test below, not here.

## `Content/Hazards.luau`

```lua
--!strict
export type Dressing = { colourRole: string, nameKey: string, iconKey: string }
export type BoosterDef = {
	subKind: string, flag: string, consumable: boolean, durationKey: string?,
	footprint: { w: number, d: number }, dressing: { [string]: Dressing },
}
export type TrapDef = {
	subKind: string, flag: string, surface: boolean, knocks: boolean,
	footprint: { w: number, d: number }, dressing: { [string]: Dressing },
}
return { boosters = { ...5 rows }, traps = { ...4 rows } }
```

Rows (footprints in studs; colour roles are existing `tokens.json` roles):

| subKind | footprint | `winter` role / icon | `city` role / icon |
| --- | --- | --- | --- |
| `dash` | 5 × 5 | `w-accent-red` / `dash` | `w-accent-red` / `dash` |
| `magnet` | 5 × 5 | `w-metal` / `magnet` | `w-metal` / `magnet` |
| `spring` | 8 × 8 | `w-season` / `spring` | `w-sand` / `spring` |
| `shield` | 5 × 5 | `w-glow` / `shield` | `w-glow` / `shield` |
| `slick_trail` | 5 × 5 | `w-water` / `slick` | `w-water` / `slick` |
| `slick` | 14 × 14 | `w-water` (ice) / `slick` | `w-water` (puddle) / `slick` |
| `bumper` | 4 × 4 | `w-season` (snow-capped) / `bumper` | `w-accent-red` / `bumper` |
| `slow` | 14 × 14 | `w-season` (slush) / `slow` | `w-sand` (sand / tar) / `slow` |
| `sweeper` | 10 × 6 | `w-metal` / `sweeper` | `w-metal` / `sweeper` |

Exact roles are playtest-adjustable data; the test only requires that each role exists in the active palette and
that `winter` and `city` are both present.

`Hazards.test` (in `Markers.test` or its own file): unique sub-kinds; both themes present on every row; every
`colourRole` exists in `docs/design/tokens.json`; every `nameKey` and `iconKey` exists in `Strings` / `Icons`; no
row has a price, product or id containing `snowplough`; every `flag` is a `Config.Flags` key.

## `GreyBoxRoom.luau` types

```lua
export type MarkerDef = {
	id: string, kind: string, subKind: string,
	x: number, y: number, z: number, yaw: number,
	waypoints: { { x: number, z: number } }?,
}
```

`KeepOutDef.kind` already allows `"marker"`; no change. Keep-outs are axis-aligned, so a sweeper loop gets one
rect per side (`ko_marker_…`), each as wide as the sweeper footprint.

## Snow Village markers (`SnowVillage.luau`)

8 `BoosterSpot` (dash 2, magnet 2, spring 2, shield 1, slick_trail 1) and 8 `TrapSpot` (slick 2, bumper 2,
slow 2, sweeper 2), ids `booster-<subKind>-<n>` and `trap-<subKind>-<n>`. The 6 extra "Feature 004b" streets at
`{-60,0},{60,0},{0,-60},{0,60},{-150,-180},{150,180}` and the 10 spawn-loop markers are re-authored into this
lineup. Constraints: spring pads at `(0, -126)` and `(0, 126)`, `yaw` facing the nearest Y = 11 roof; sweeper
loops on open lanes with every waypoint outside the gate and shortcut keep-outs; nothing on a block footprint.

`SnowVillage.test` changes: markers pass `Markers.validate` under both themes; at least 6 `BoosterSpot` and 6
`TrapSpot`; all nine sub-kinds covered; `counts.marker == #markers + sweeperSegments`; the part budget test
counts markers plus 48 trail patches plus sweeper and bumper parts and stays under 2,000; every spring pad's
computed apex (`Config.springVerticalSpeed²/(2·196.2)`) ≥ 12 and its landing point (hand-computed from
`springForwardSpeed` and flight time) lies on a roof footprint.

## `Strings.luau` (en, es)

Keys follow `ui.fx.<name>` for chips and `world.booster.<subKind>` / `world.trap.<subKind>.<themeId>` for names:

| Key | en |
| --- | --- |
| `ui.fx.dash` | Dash |
| `ui.fx.magnet` | Magnet |
| `ui.fx.shield` | Sticky coat |
| `ui.fx.slick_trail` | Slick trail |
| `ui.fx.slick` | Slippery! |
| `ui.fx.slow` | Slowed |
| `world.booster.dash` … `world.booster.slick_trail` | Dash boost, Magnet, Spring pad, Sticky coat, Slick trail |
| `world.trap.slick.winter` / `.city` | Ice patch / Puddle |
| `world.trap.bumper.winter` / `.city` | Snowy bollard / Street bollard |
| `world.trap.slow.winter` / `.city` | Slush / Wet sand |
| `world.trap.sweeper.winter` / `.city` | Salt sweeper / Street sweeper |

Spanish equivalents are required for every key (`Strings.test` already fails on a missing `es`). Chip labels use
the HUD text style (≥ 18 px). No string says "limited", "buy" or a price.

## `Icons.luau` additions

`dash`, `magnet`, `spring`, `shield`, `slick`, `slow`, `bumper`, `sweeper`. Placeholder glyphs; each is checked in a
Studio capture under both `FredokaOne` and `GothamMedium` (AGENTS.md: a glyph missing from `FredokaOne` renders
blank), preferring emoji where the plain glyph fails, as the existing `retry` and `close` do.

## `Assets.luau`

`sounds.land` is a stock `rbxasset://sounds/…` thump. The path is not fixed here: the task picks one, checks
`IsLoaded` and `TimeLength` in Play, and records it. No uploaded id is added.
