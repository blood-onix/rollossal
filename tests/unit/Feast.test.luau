--!strict
-- Hand-computed values for the Feast rules.

local harness = require("./harness")
local Feast = require("../../src/shared/Rules/Feast")

local test, expect = harness.test, harness.expect

local function near(a: number, b: number)
	expect.truthy(math.abs(a - b) < 1e-6)
end

test("modeFor: fixed modes and the alternation", function()
	expect.equal(Feast.modeFor("Classic", 1), "Classic")
	expect.equal(Feast.modeFor("Feast", 2), "Feast")
	expect.equal(Feast.modeFor("Alternate", 1), "Feast")
	expect.equal(Feast.modeFor("Alternate", 2), "Classic")
	expect.equal(Feast.modeFor("Alternate", 3), "Feast")
	expect.equal(Feast.modeFor("nonsense", 1), "Classic")
end)

test("open: closed during the grace, open from its last second", function()
	expect.equal(Feast.open(159.9, 100, 60), false)
	expect.equal(Feast.open(160, 100, 60), true)
end)

test("canEat: the victim is at most the ratio of the eater", function()
	expect.equal(Feast.canEat(10, 7.5, 0.75), true)
	expect.equal(Feast.canEat(10, 7.6, 0.75), false)
	expect.equal(Feast.canEat(7.5, 10, 0.75), false)
end)

test("touching: radii plus the margin", function()
	expect.equal(Feast.touching(7.3, 10, 4, 0.3), true)
	expect.equal(Feast.touching(7.4, 10, 4, 0.3), false)
end)

test("eaterDiameter: gains a share of the victim's volume", function()
	near(Feast.eaterDiameter(2, 2, 0.5), 12 ^ (1 / 3))
	near(Feast.eaterDiameter(10, 0, 0.5), 10)
end)

test("victimDiameter: keeps a share, never under the start", function()
	near(Feast.victimDiameter(10, 0.6, 1), 6)
	near(Feast.victimDiameter(1.2, 0.6, 1), 1)
end)

test("fleeRadius: scales with the hunter over a floor", function()
	expect.equal(Feast.fleeRadius(2, 5, 30), 30)
	expect.equal(Feast.fleeRadius(10, 5, 30), 50)
end)

test("shrinkByShare: takes a share of the volume, never under the start", function()
	near(Feast.shrinkByShare(10, 0.271, 1), 9)
	near(Feast.shrinkByShare(1, 0.5, 1), 1)
end)

test("bittenDiameter and biterDiameter: the eater gains a share of what the victim lost", function()
	near(Feast.bittenDiameter(10, 0.8, 1), 8)
	near(Feast.bittenDiameter(1.1, 0.8, 1), 1)
	near(Feast.biterDiameter(10, 10, 8, 0.5), (1000 + 0.5 * (1000 - 512)) ^ (1 / 3))
	near(Feast.biterDiameter(10, 1, 1, 0.5), 10)
end)

test("swallows: the third bite in a row finishes, a late bite starts again", function()
	local done, count = Feast.swallows(0, math.huge, 6, 3)
	expect.equal(done, false)
	expect.equal(count, 1)
	done, count = Feast.swallows(2, 2, 6, 3)
	expect.equal(done, true)
	expect.equal(count, 3)
	done, count = Feast.swallows(2, 7, 6, 3)
	expect.equal(done, false)
	expect.equal(count, 1)
end)

test("paceFloor: from the start size to the finish along the round", function()
	near(Feast.paceFloor(0, 240, 1, 41, 1), 1)
	near(Feast.paceFloor(120, 240, 1, 41, 1), 21)
	near(Feast.paceFloor(500, 240, 1, 41, 1), 41)
	near(Feast.paceFloor(120, 240, 1, 41, 2), 11)
end)

return {}
