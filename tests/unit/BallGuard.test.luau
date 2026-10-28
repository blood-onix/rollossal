--!strict
-- Hand-computed: the ceiling is 56 studs/s and the slack 4, so the displacement limit is 224 studs/s.

local harness = require("./harness")
local BallGuard = require("../../src/shared/Rules/BallGuard")

local test, expect = harness.test, harness.expect

test("verdict: at or under both limits is Ok", function()
	expect.equal(BallGuard.verdict(56, 224, 56, 4), "Ok")
	expect.equal(BallGuard.verdict(0, 0, 56, 4), "Ok")
end)

test("verdict: speed over the ceiling is Speed", function()
	expect.equal(BallGuard.verdict(56.1, 10, 56, 4), "Speed")
end)

test("verdict: a step over 224 studs/s alone is Displacement", function()
	expect.equal(BallGuard.verdict(20, 224.1, 56, 4), "Displacement")
	expect.equal(BallGuard.verdict(20, 247.4, 56, 4), "Displacement")
end)

test("verdict: Speed wins when both limits are broken", function()
	expect.equal(BallGuard.verdict(80, 300, 56, 4), "Speed")
end)

test("stepSpeed: horizontal 3-4-5 over half a second is 10", function()
	expect.near(BallGuard.stepSpeed(0, 0, 3, 4, 0.5), 10, 1e-9)
end)

test("stepSpeed: a zero or negative step is no movement", function()
	expect.equal(BallGuard.stepSpeed(0, 0, 100, 100, 0), 0)
	expect.equal(BallGuard.stepSpeed(0, 0, 100, 100, -1), 0)
end)

test("stepSpeed: one 60 Hz step of 4 studs is 240, over the displacement limit", function()
	local speed = BallGuard.stepSpeed(0, 0, 4, 0, 1 / 60)
	expect.near(speed, 240, 1e-9)
	expect.equal(BallGuard.verdict(10, speed, 56, 4), "Displacement")
end)

return {}
