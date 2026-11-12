--!strict
-- Hand-computed values for the food flow formula.

local harness = require("./harness")
local Flow = require("../../src/shared/Rules/Flow")

local test, expect = harness.test, harness.expect

local tuning: Flow.Tuning = {
	radiusBase = 20,
	radiusPerDiameter = 5,
	radiusMin = 40,
	radiusMax = 150,
	worthShare = 0.4,
	target = 8,
	perTick = 1,
	smallDiameter = 8,
	smallTarget = 10,
	smallPerTick = 3,
	smallNeedLow = 0.65,
	smallNeedHigh = 1,
	needLow = 0.45,
	needHigh = 0.95,
	needSkew = 0.7,
	nearShare = 0.3,
	spreadDegrees = 90,
}

local function near(a: number, b: number)
	expect.truthy(math.abs(a - b) < 1e-6)
end

test("radius: grows with the ball between its floor and ceiling", function()
	expect.equal(Flow.radius(1, tuning), 40)
	expect.equal(Flow.radius(10, tuning), 70)
	expect.equal(Flow.radius(100, tuning), 150)
end)

test("worth: edible now and big enough to matter", function()
	expect.equal(Flow.worth(4, 10, tuning), true)
	expect.equal(Flow.worth(10, 10, tuning), true)
	expect.equal(Flow.worth(3.9, 10, tuning), false)
	expect.equal(Flow.worth(10.1, 10, tuning), false)
end)

test("quota: a small ball gets a fuller ring, filled faster", function()
	local target, perTick = Flow.quota(3, tuning)
	expect.equal(target, 10)
	expect.equal(perTick, 3)
	target, perTick = Flow.quota(8, tuning)
	expect.equal(target, 8)
	expect.equal(perTick, 1)
end)

test("deficit: what is missing, never negative", function()
	expect.equal(Flow.deficit(3, 8), 5)
	expect.equal(Flow.deficit(12, 8), 0)
end)

test("pickNeed: between the low and high share of the ball", function()
	near(Flow.pickNeed(10, 0, tuning), 4.5)
	near(Flow.pickNeed(10, 1, tuning), 9.5)
	local middle = Flow.pickNeed(10, 0.5, tuning)
	expect.truthy(middle > 7 and middle < 9.5)
end)

test("pickNeed: a small ball's pieces are near the biggest it can eat", function()
	near(Flow.pickNeed(2, 0, tuning), 1.3)
	near(Flow.pickNeed(2, 1, tuning), 2)
end)

test("offset: inside the ring and ahead of a moving ball", function()
	for step = 0, 10 do
		local dx, dz = Flow.offset(100, 1, 0, step / 10, step / 10, tuning)
		local distance = math.sqrt(dx * dx + dz * dz)
		expect.truthy(distance >= 30 - 1e-6 and distance <= 100 + 1e-6)
		expect.truthy(dx >= -1e-6)
	end
	local dx, dz = Flow.offset(100, 0, 0, 1, 0, tuning)
	near(dx, -100)
	near(dz, 0)
end)

return {}
