# Playtest: Main-Street slice (010)

Run 2026-11-03 in Studio via MCP, flags MainStreetSlice, SliceHud, HeapRedesign temporarily true (reverted to false afterwards).

## T028 result (round 2)
Clean session (no bots).
- Park start: the player ball spawned at (-88, 1, -238) in the park, on open ground. Nothing blocks it.
- HUD: no NextTier, Star or TierBanner instance under PlayerGui.
- Too-large bump: a 20 studs/s push at `ms_trail_1_5` (Size 0.9, above 0.4 x D = 0.8) went 18.3, 11.8, 7, 4.1, 0.5, 0 along the
  approach within 0.3 s, and the ball stopped at the object (still untaken). The impact sound was not heard (no audio check over MCP).
- Console: only Studio's own lines (DataStore write, ProfileStore unavailable, `ContentId rbxassetid://203785492 ...`, not in the
  repo). 0 errors and 0 warnings from game scripts.
- The "Displacement violation" and "Vertical violation" warnings in the benchmark console come from the playerless BotRun balls
  (users 700001 to 700011, moved by the bot driver) and from the player ball right after the HeavyLoad teleport. They exist only
  under the benchmark, not in a normal session.

## T027 benchmark: 12 balls, late-game heap load
Harness: HeavyScene slice mode gained a `HeavyLoad` attribute (set to 30): after 5 s every ball is set to D 30 with a full
120-entry stuck stack of random slice placements, so the heap load of D 12 to 80 is exercised (the eater driver alone only
reached D 2.2). Sampler: the slice branch of HeavySampler, run on the Client datamodel, 43 to 44 one-second samples per
candidate, 0 throttled seconds (none at 15 fps). The viewport was not 640x360 (the MCP cannot resize it); phone fps stays in
`docs/release-candidate.md`. Server parts: 1,072 for every candidate (limit 2,000), 12 balls.

| # | Candidate | median fps | min fps | seconds under 30 | max draw calls | max triangles | max client stuck visuals |
|---|-----------|-----------|---------|------------------|----------------|---------------|--------------------------|
| 1 | baseline: heap off, maxVisibleStuck 60 | 60 | 59.9 | 0 | 62 | 71,910 | 770 |
| 2 | A: outer cap 40 for all balls, no core tint | 60 | 58 | 0 | 57 | 25,414 | 482 |
| 3 | A+B: cap 40 for all balls, core tint | 60 | 17.2 | 1 (second 6) | 45 | 26,492 | 485 |
| 4 | A+B+C: local 40, remote 12 (the default) | 60 | 32.2 | 0 | 29 | 17,542 | 182 |
| 5 | D merged lumps | not measured | | | | | |

Candidate 5 is measured only if 4 misses the budget (research R-09), and 4 does not miss it.

Reading:
- Candidate 4 holds at least 30 fps on every unthrottled second (min 32.2) with the fewest draw calls, triangles and visuals. It
  stays the default. Quality Gate 2 (>= 30 fps, under 2,000 server parts): pass on this laptop.
- Candidate 1 also held 60 fps here, but it draws about twice the calls, four times the triangles and keeps 770 visuals, so it
  has the least headroom on a phone.
- Candidate 3 had one second at 17.2 fps (second 6, the moment the load is applied). The cause was not investigated.
- Earlier default-only run (eater driver, D up to 2.2, 90 s, before the load): 83 samples, median 60 fps, 82 of 83 at 59.7 fps
  or more, one second at 22.6 fps (second 42, cause not investigated), parts 1,061 to 1,079, max draw calls 52, max
  triangles 23,028. That run is below 30 fps for one second; the heavier loaded run of candidate 4 had none.
- This is a laptop result. Phone fps is an owner check in `docs/release-candidate.md`.
