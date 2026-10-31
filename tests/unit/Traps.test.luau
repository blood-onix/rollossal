--!strict
-- Hand-computed values (contracts/rules-api.md).

local harness = require("./harness")
local Traps = require("../../src/shared/Rules/Traps")

local test, expect = harness.test, harness.expect

test("enabled: needs the master flag and the trap's own flag", function()
	local on = { Traps = true, TrapSlick = true, TrapBumper = false }
	expect.truthy(Traps.enabled(on, "slick"))
	expect.falsy(Traps.enabled(on, "bumper"))
	expect.falsy(Traps.enabled(on, "sweeper"))
	expect.falsy(Traps.enabled({ Traps = false, TrapSlick = true }, "slick"))
	expect.falsy(Traps.enabled(on, "unknown"))
end)

test("multipliers: exactly 0.5 and 0.25 when active, 1 otherwise, never above 1", function()
	expect.near(Traps.speedMultiplier(true, 0.5), 0.5, 1e-9)
	expect.near(Traps.speedMultiplier(false, 0.5), 1, 1e-9)
	expect.near(Traps.turnMultiplier(true, 0.25), 0.25, 1e-9)
	expect.near(Traps.turnMultiplier(false, 0.25), 1, 1e-9)
	expect.near(Traps.speedMultiplier(true, 3), 1, 1e-9)
	expect.near(Traps.turnMultiplier(true, 3), 1, 1e-9)
end)

test("surfaceActive: inside extends the end to now + linger, leaving holds it", function()
	local active, untilT = Traps.surfaceActive(10, true, 0, 0.6)
	expect.truthy(active)
	expect.near(untilT, 10.6, 1e-9)
	active, untilT = Traps.surfaceActive(10.5, false, 10.6, 0.6)
	expect.truthy(active)
	expect.near(untilT, 10.6, 1e-9)
	active, untilT = Traps.surfaceActive(10.6, false, 10.6, 0.6)
	expect.falsy(active)
	expect.near(untilT, 10.6, 1e-9)
end)

test("insideRect: unrotated rectangle", function()
	-- Centre (10, 20), half width 8 (X), half depth 4 (Z).
	expect.truthy(Traps.insideRect(10, 20, 10, 20, 8, 4, 0))
	expect.truthy(Traps.insideRect(18, 24, 10, 20, 8, 4, 0))
	expect.falsy(Traps.insideRect(18.1, 20, 10, 20, 8, 4, 0))
	expect.falsy(Traps.insideRect(10, 24.1, 10, 20, 8, 4, 0))
end)

test("insideRect: yaw 90 degrees swaps the extents", function()
	-- Rotated a quarter turn, the 8-wide side now runs along Z.
	expect.truthy(Traps.insideRect(10, 28, 10, 20, 8, 4, 90))
	expect.falsy(Traps.insideRect(10, 28.1, 10, 20, 8, 4, 90))
	expect.falsy(Traps.insideRect(18, 20, 10, 20, 8, 4, 90))
	expect.truthy(Traps.insideRect(14, 20, 10, 20, 8, 4, 90))
end)
