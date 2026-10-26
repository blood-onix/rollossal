# Playtest: Run Loop (002-run-loop)

Constitution I: record every playtest here. Children are recorded by age group only, never by name.
Run it on the private test place, never the live place. Calibration steps: [quickstart.md](quickstart.md) §7.

| Field | Value |
| --- | --- |
| Date | |
| Build / commit hash | |
| Adults | |
| Children aged 10 to 12 | |
| Devices (include one phone at the reference spec) | |

## Solo timed runs (three, eating everything absorbable)

Expected from research R1: Tier 3 near 65 s, Tier 4 near 100 to 125 s, final size about 4.5 to 5.7.

| Run | Final diameter | Stars | Tier 2 opened (s) | Tier 3 opened (s) | Tier 4 opened (s) | Coins |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |

## Star thresholds `{ 3.0, 4.0, 5.0 }` (finding F-1)

Verdict: _(keep, or retune `GreyBoxRoom.starThresholds` if most runs earn 0 or 3 stars)_

## Other checks

- Scenario 13, two accounts, one a friend (friend bonus and friend row): 
- Phone vibrates on pickup (finding F-3): 
- Feel of a 6-player server (finding F-4): 
- Phone capture links (HUD, results, hub): Studio emulation at 640×360, 844×390, 1280×720 in [captures/](captures/) (T029, T040). Real-phone captures still to add.

## Findings

- **Agent autopilot runs, not a playtest (2026-10-25, Studio, one bot player eating the nearest absorbable
  cube at 85 % of top speed).** Final diameters 4.9 (2★), 5.6 (3★), 6.1 (3★), 5.8 (3★), 5.1 (3★, with six
  deliberate knock-offs). Tier 2 opened at about 45 to 60 s, Tier 3 near 75 s. A bot is a near-perfect
  eater, so most of its runs earning 3 stars says only that the `{ 3.0, 4.0, 5.0 }` targets (F-1) are
  reachable; whether people hit them is what the real playtest decides.

## Owner sign-off

Owner approval (approving review or written "approved" comment, never an agent's statement):

Signed off by: ______________________  Date: ______________

Status (2026-10-25): the owner marked T051 done in the agent session ("so far it works"). The tables above
were not filled with a people playtest. This note is a record of the owner's decision, not a signature;
the owner's approving review or "approved" comment on the PR is the sign-off.
