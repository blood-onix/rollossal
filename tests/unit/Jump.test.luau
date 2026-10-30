--!strict
-- Hand-computed from research R-01 (g = 196.2). The numbers are not read from the code under test.

local harness = require("./harness")
local Jump = require("../../src/shared/Rules/Jump")

local test, expect = harness.test, harness.expect

local G = 196.2
local p: Jump.JumpTuning = {
	clearRatio = 0.6,
	holdClearRatio = 0.85,
	minClear = 1.6,
	holdMaxSeconds = 0.25,
	verticalSlack = 1.25,
	airEnergyAllowance = 1.0,
	maxSlopeRatio = 0.5,
}

-- D, tapApex, holdApex, takeoffSpeed, holdGravity
local rows = {
	{ 2, 1.6, 2.267, 25.06, 138.49 },
	{ 5, 3.0, 4.25, 34.31, 138.49 },
	{ 12, 7.2, 10.2, 53.15, 131.97 },
	{ 30, 18.0, 25.5, 84.04, 112.14 },
	{ 70, 42.0, 59.5, 128.38, 80.16 },
}

test("tapApex: 0.6 of the diameter with a 1.6 floor", function()
	for _, row in rows do
		expect.near(Jump.tapApex(row[1], p), row[2], 0.01)
	end
end)

test("holdApex: 0.85 of the diameter with a 2.267 floor", function()
	for _, row in rows do
		expect.near(Jump.holdApex(row[1], p), row[3], 0.01)
	end
end)

test("takeoffSpeed: sqrt(2 g tapApex)", function()
	for _, row in rows do
		expect.near(Jump.takeoffSpeed(row[1], G, p), row[4], 0.01)
	end
end)

test("holdGravity: matches the research table and never exceeds g", function()
	for _, row in rows do
		local q = Jump.holdGravity(row[1], G, p.holdMaxSeconds, p)
		expect.near(q, row[5], 0.01)
		expect.truthy(q <= G)
	end
end)

test("the Tier 1 kerb (1.5 studs) is cleared at D = 2 by a tap", function()
	expect.truthy(Jump.tapApex(2, p) > 1.5)
end)

test("a held jump is always higher than a tap", function()
	for _, row in rows do
		expect.truthy(Jump.holdApex(row[1], p) > Jump.tapApex(row[1], p))
	end
end)

test("upLimit: take-off speed with slack, floored by the ramp rule", function()
	-- D = 2: 25.06 * 1.25 = 31.33; the ramp floor 56 * 0.5 = 28 is lower.
	expect.near(Jump.upLimit(2, G, 56, nil, p), 31.33, 0.02)
	-- D = 70: 128.38 * 1.25 = 160.5.
	expect.near(Jump.upLimit(70, G, 56, nil, p), 160.47, 0.05)
	-- Dash ceiling 80 -> floor 40 beats D = 2's 31.33.
	expect.near(Jump.upLimit(2, G, 80, nil, p), 40, 1e-9)
	-- Spring 70 * 1.25 = 87.5 beats the D = 2 take-off.
	expect.near(Jump.upLimit(2, G, 56, 70, p), 87.5, 1e-9)
end)

test("apexAllowance: (apex + 1 stud) * slack, spring apex while its window is open", function()
	-- D = 2: (2.267 + 1) * 1.25 = 4.083
	expect.near(Jump.apexAllowance(2, nil, G, p), 4.083, 0.01)
	-- Spring apex 70^2 / 392.4 = 12.487; (12.487 + 1) * 1.25 = 16.859
	expect.near(Jump.apexAllowance(2, 70, G, p), 16.859, 0.01)
end)

test("canTakeOff: needs ground, a finished cooldown and no upward motion", function()
	expect.equal(Jump.canTakeOff(true, 10, 9, 0, 0.3), true)
	expect.equal(Jump.canTakeOff(false, 10, 9, 0, 0.3), false)
	expect.equal(Jump.canTakeOff(true, 10, 9.8, 0, 0.3), false)
	expect.equal(Jump.canTakeOff(true, 10, 9, 2.1, 0.3), false)
	expect.equal(Jump.canTakeOff(true, 10, 9.7, 0, 0.3), true)
end)

return {}
