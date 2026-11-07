--!strict
-- Expected values are hand-computed from contracts/rules-api.md §Movement.

local harness = require("./harness")
local Movement = require("../../src/shared/Rules/Movement")

local test, expect = harness.test, harness.expect

test("targetSpeed: base speed at start diameter", function()
	expect.equal(Movement.targetSpeed(2, 18, 2, 0.5, 32), 18)
end)

test("targetSpeed: capped at D = 8 (uncapped would be 36)", function()
	expect.equal(Movement.targetSpeed(8, 18, 2, 0.5, 32), 32)
end)

test("targetSpeed: 18 * sqrt(4.5 / 2) = 27 at D = 4.5", function()
	expect.near(Movement.targetSpeed(4.5, 18, 2, 0.5, 32), 27, 1e-9)
end)

test("cameraDistance: start distance is the minimum", function()
	expect.equal(Movement.cameraDistance(2, 4, 8, 80), 8)
end)

test("cameraDistance: mid range is 4 * D", function()
	expect.equal(Movement.cameraDistance(5, 4, 8, 80), 20)
end)

test("cameraDistance: clamps up to the minimum", function()
	expect.equal(Movement.cameraDistance(1, 4, 8, 80), 8)
end)

test("cameraDistance: clamps down to the maximum", function()
	expect.equal(Movement.cameraDistance(30, 4, 8, 80), 80)
end)

local parkCap: Movement.SpeedCapRule = { base = 32, fromDiameter = 12, slope = 0.4, max = 56 }

test("speedCap: 32 at D 1 and D 12", function()
	expect.equal(Movement.speedCap(1, parkCap), 32)
	expect.equal(Movement.speedCap(12, parkCap), 32)
end)

test("speedCap: D 20 -> 32 + 0.4 * 8 = 35.2, D 30 -> 39.2", function()
	expect.near(Movement.speedCap(20, parkCap), 35.2, 1e-9)
	expect.near(Movement.speedCap(30, parkCap), 39.2, 1e-9)
end)

test("speedCap: capped at 56 (D 80 would give 59.2)", function()
	expect.near(Movement.speedCap(80, parkCap), 56, 1e-9)
end)

return {}
