# Contract: Street rules and scene kits (for 004j)

This is the format the Downtown rebuild (004j) reuses. Rules are pure (Constitution III): no engine types, no
`require(script`, no clock, no `math.random`. Randomness is a local Park-Miller generator
(`seed = seed * 48271 % 2147483647`) seeded from the `StreetDef` or `KitInstance`.

## `StreetRules.expand(def: StreetDef) -> StreetOut`

Produces `blocks` (ground-level slabs) and `placements`. Guarantees:

| Rule | Value |
| --- | --- |
| Road surface | `w-asphalt`, at least 2.5x darker than `w-sidewalk` |
| Sidewalk | `w-sidewalk`, raised 0.4 stud, at least 6 studs wide on each side |
| Kerb | `w-kerb` band along every sidewalk edge |
| Centre line | stripe 1 stud wide, 1 stud gap |
| Zebra crossing | at every junction, stripe 1 stud wide, 1 stud gap, across the carriageway |
| Trees | every `treeEvery` = 18 studs along the sidewalk line |
| Lamps | every `lampEvery` = 24 studs; a lamp shifts along the line until 4 studs or more from any trunk |
| Bins | one at every junction corner |
| Benches | face the road (yaw = segment yaw +- 90 toward the carriageway) |
| Parked cars | parallel to the kerb (yaw = segment yaw or +180) |
| Jitter | seeded, at most `jitterPos` studs and `jitterYaw` degrees; never a full-circle yaw |

Same `StreetDef` gives the same output (SC-005).

## `SceneKit.expand(kit, instance, idPrefix, bounds) -> { Placement }`

Rotates kit-local entries by `instance.yaw`, adds the origin, applies seeded jitter, assigns ids
`idPrefix_1..n`, and errors if any entry falls outside the kit footprint or `bounds`.

## Kit format (`Content/SceneKits.luau`)

```text
{ id = "bus_stop", halfX = 6, halfZ = 3,
  entries = { { objectId = "bus_shelter", dx = 0, dz = 0, yaw = 0 },
              { objectId = "bench", dx = 3, dz = 1, yaw = 180 } } }
```

Rules for kit authors: every `objectId` exists in the world's object table; entries stay inside the footprint; no
two entries overlap their sizes by more than 20%; no text or branding (Constitution IV).

## The 10 kits

`picnic_spread`, `cafe_terrace`, `bus_stop`, `fruit_stall`, `bike_rack`, `road_works`, `car_park_rows`, `yard_sale`,
`flower_bed`, `recycling_point`.

## Swapping props (FR-004)

Replace an `ObjectDef.assetKey` (and nothing else) to change a prop's mesh. Rules, kits and placements do not change.

## Tests

`StreetRules.test.luau` and `SceneKit.test.luau` use hand-computed positions (for example a 90 degree instance yaw
maps `(dx, dz) = (3, 1)` at origin `(10, 20)` to `(11, 17)`) and check every guarantee above.
