# Contract: `Config` and `Content`

`src/shared/Config.luau` returns one table. No magic numbers elsewhere (FR-012). Each row says where the
value comes from. `Tune` marks a first guess that the Studio spike or the playtest is expected to adjust.

## Gameplay (from the spec and the brief)

| Key | Value | Source |
| --- | --- | --- |
| `startDiameter` | 2 | spec |
| `absorbRatio` | 0.4 | spec |
| `growthK` | 0.6 | spec |
| `maxVisibleStuck` | 30 | spec; also the Principle VI stuck-objects budget |
| `maxTrackedStuck` | 120 | 4 × visible; bounds server memory |
| `knockOffCount` | 3 | spec |
| `bumpSpeedThreshold` | 15 | spec assumption; Tune in playtest |
| `bumpSpeedWindow` | 0.35 | R2: seconds of server speed samples used for the bump check |
| `bumpCooldown` | 1.0 | R2: seconds between knock-offs per player |
| `respawnDelay` | 15 | spec assumption (seconds) |
| `scatterDistance` | 6 | studs beyond the ball radius where knocked-off cubes land |
| `scatterGrace` | 1.0 | seconds before a scattered cube can be absorbed again |

## Anti-exploit

| Key | Value | Source |
| --- | --- | --- |
| `absorbRateLimit` | 10 | spec (per `rateLimitWindow`) |
| `rateLimitWindow` | 1 | seconds |
| `absorbDistanceTolerance` | 6.0 | Tune against ping (R12). 2.0 rejected every first absorb and every at-speed bump in the T079 Studio run: the server sees the client-owned ball about 0.16 s late (2.9 studs at 18 studs/s, 5.1 at the 32 cap) |
| `maxServerBallSpeed` | 56 | 1.75 × `speedCap`, leaving room for collision pushes and ramps |
| `displacementSlack` | 4 | multiplier for the per-step displacement check (1.5 gave false positives of 85 to 107 studs/s at an honest 18 studs/s in Studio, T079) |
| `fallRespawnY` | −50 | studs |
| `respawnBallCooldown` | 3 | seconds |

## Movement, camera, jump

| Key | Value | Source |
| --- | --- | --- |
| `speedExponent` | 0.5 | spec |
| `baseSpeed` | 18 | studs/s at `startDiameter`; above `bumpSpeedThreshold` so a full-speed hit counts; Tune |
| `speedCap` | 32 | studs/s; reached at D ≈ 6.3 |
| `cameraMultiplier` | 4 | spec |
| `cameraMinDistance` | 8 | = 4 × 2, the start distance |
| `cameraMaxDistance` | 80 | a ball of D = 20, far beyond this grey-box |
| `cameraSmoothing` | 4 | per second, exponential |
| `jumpImpulse` | 24 | studs/s vertical velocity change; hop ≈ 1.47 studs |
| `groundProbeExtra` | 0.3 | studs below the ball surface for the grounded raycast |
| `growTime` | 0.25 | seconds to ease the physical size |
| `clientContactMargin` | 0.3 | studs added to the client's contact test |
| `clientSendBudget` | 8 | max Absorb sends per second from one client; below `absorbRateLimit` |
| `rollTorqueGain` | 60 | Tune (R6) |
| `rollForceGain` | 6 | Tune (R6) |
| `stuckVisualMode` | `"Weld"` | R4; becomes `"Follower"` only if the measurement fails |
| `stuckEmbed` | 0.35 | fraction of a cube's size sunk into the ball surface |

## Flags and budgets

```lua
Flags = { AvatarPusher = false, BigBallMode = false, RewardedAds = false }  -- exist, unused, off
Budgets = {
  maxActivePartsPerServer = 500,          -- counted on a client: 12 balls x (1 + 30 visuals) + room ~ 420
  meshTriangles = { 300, 300, 800, 2500, 2500 },   -- index = tier (spec FR-012)
}
```

Cubes are plain parts (12 triangles), far below every triangle budget.

## Content: `src/shared/Content/GreyBoxRoom.luau`

Data only (see [data-model.md](../data-model.md) §2): `halfExtent = 36`, `wallHeight = 20`, `kerb`,
`spawnRingRadius = 5`, `spawnSlots = 12`, `tiers` (sizes 0.75, 0.95, 1.2, 1.5; counts 12, 9, 6, 3;
shades 200, 160, 120, 80 so tiers differ by size as well as shade) and `cubes` (30 entries). It requires
no Roblox API, so Lune can load it for validation tests.

## Sanity tests (Lune)

`Config.test.luau` and `GreyBoxRoom.test.luau` assert the rules listed in
[data-model.md](../data-model.md) §1 and §2, plus one end-to-end chain check on fixed numbers: starting
from `D = 2`, 22 Tier-1 pickups open Tier 2, 27 Tier-2 pickups open Tier 3, and 25 Tier-3 pickups open
Tier 4, using the room's real tier sizes and `Rules.Growth` (the expected pickup counts are the
hand-computed ones from [research.md](../research.md) R1).
