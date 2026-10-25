# Playtest record: grey-box prototype (Constitution Principle I gate)

Record participants by age group only. Never record names.

## Session

- Date:
- Commit SHA:
- Reference phone (model and OS, owner to confirm or replace): TODO(REFERENCE_PHONE)
- Stuck visual mode (`Config.stuckVisualMode`):

## Participants

| Age group | Count | Notes |
|-----------|-------|-------|
| Adult (18 and over) | | Target: at least 3 |
| Child (10 to 12) | | Target: at least 3 |

## Measurements

| Measure | Target | Result | Pass (yes / no) |
|---------|--------|--------|-----------------|
| First pickup time | 5 s or less | | |
| Sphere-resize jitter (resting, from the jitter probe) | Height change below 0.05 studs, speed below 1 stud/s | | |
| Frame rate on the reference phone | 30 fps or more | | |
| Growth satisfaction (participant rating, 1 to 5) | Recorded per participant | | |
| Rejected honest absorbs (count) | 0 | | |
| Speed violations (count per player) | 0 | | |

## Tuning observations

- Bump threshold (`bumpSpeedThreshold`) observations: pre-playtest Studio run (T046, solo, laptop): a
  full-speed hit at about 18 studs/s knocks off reliably once `absorbDistanceTolerance` is 6.0; a hit
  from a 1-stud run-up reaches about 4 studs/s and blocks. The window between 4 and 15 studs/s is untested
  with people.
- Other tuning changes (`respawnDelay`, `absorbDistanceTolerance`, `rollTorqueGain`, `rollForceGain`):
  before the playtest, `absorbDistanceTolerance` 2.0 → 6.0 and `displacementSlack` 1.5 → 4 (reasons in
  plan.md "Studio Run"); roll gains 60 and 6 unchanged (no slip at `baseSpeed`).
- Chosen `stuckVisualMode` and the jitter numbers behind the choice: `"Weld"`; laptop resting 0.0034
  studs and 0.003 studs/s, rolling speed error 0.029 studs/s (research R4). Phone numbers: pending T040.

## Issues found

| # | Severity (blocker, major, minor) | Description | Steps to reproduce | Ticket or fix |
|---|----------------------------------|-------------|--------------------|---------------|
| 1 | | | | |

## Sign-off

- Playtest verdict (ship, fix then ship, do not ship):
- Owner sign-off (name and date):
