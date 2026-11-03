# Quickstart: validating the Main-Street slice

A validation guide only. Run it after the tasks are done.

## 1. Gate 1 (no Studio)

```text
scripts/check.sh
```

Expect it clean, including the new suites: `StreetRules`, `SceneKit`, `Heap`, `MainStreetSlice`,
`CaptureCamerasSlice`, and the updated `Config` and `Downtown` chain pins. The Rules purity grep must pass.

## 2. Turn the slice on (Studio, Edit)

1. `scripts/studio-preflight.sh`, then run `scripts/studio-sync-probe.sh` through `execute_luau`. `mismatches = {}`.
2. Set `Config.Flags.MainStreetSlice`, `SliceHud` and `HeapRedesign` to `true` in the working copy only. Do not
   commit the change.

## 3. Playtest (Studio, gate 2)

- Start Play. Expect: park start, 12 spawns, suburb corner, main street with continuous fronts, skyline ahead.
- Each of the 12 spawns reaches a first pickup within 5 s.
- Roll to D 5: the base sphere is mostly hidden. Larger and newer items sit outside; older small items sink in.
- HUD shows timer and size only. No `Next:` line, no star row, no `YOU CAN ROLL UP` banner.
- Touch an object that is too large: an immediate bump plus the bump sound, no text, no repeat inside 0.4 s.
- Console: no new errors or warnings.

## 4. 12-ball benchmark (Studio, 640 x 360)

Run the extended `HeavyScene` / `HeavySampler` for each heap candidate in `contracts/heap-rules.md`. Record per-second
fps, parts, triangles and draw calls in `playtest.md`. Label seconds at exactly 15 fps as throttled. Pass on
unthrottled seconds: 30 fps or more, under 2,000 parts.

## 5. Five shots

Capture `01_spawn_d2`, `02_street_d5`, `03_midgame_d12_30`, `04_lategame_d80`, `05_overhead_map` into
`specs/010-main-street-slice/captures/` using `art/capture/cameras-slice.json`. If Studio `screen_capture` fails, ask
the owner once, then use the offline route (`art/scripts/capture_render.py` via `scripts/capture-export.luau --world slice`).

## 6. Owner approval (gate 6)

Show the five shots and let the owner play the build. The PR may open first; it does not merge before approval.

## 7. Release-candidate items

Phone fps with 12 balls, facade atlas and billboard uploads, 004h mesh swap, size-readability and look-and-feel
sign-off, and the default-flag decision are in `docs/release-candidate.md` under "Main-Street slice (010)".
