--!strict
-- Expected values are hand-computed from contracts/rules-api.md §Absorb. Never computed from the code under test.

local harness = require("./harness")
local Absorb = require("../../src/shared/Rules/Absorb")

local test, expect = harness.test, harness.expect

test("canAbsorb: equal size passes", function()
	expect.equal(Absorb.canAbsorb(2, 0.8, 0.4), true)
end)

test("canAbsorb: just above the limit fails", function()
	expect.equal(Absorb.canAbsorb(2, 0.8001, 0.4), false)
end)

test("canAbsorb: tier 1 at start passes", function()
	expect.equal(Absorb.canAbsorb(2, 0.75, 0.4), true)
end)

test("canAbsorb: tier 2 at start fails", function()
	expect.equal(Absorb.canAbsorb(2, 0.95, 0.4), false)
end)

test("canAbsorb: tier 2 passes at D = 2.375", function()
	expect.equal(Absorb.canAbsorb(2.375, 0.95, 0.4), true)
end)

test("isKnockOff: too big and fast knocks off", function()
	expect.equal(Absorb.isKnockOff(2, 0.95, 16, 0.4, 15), true)
end)

test("isKnockOff: speed equal to threshold does not knock off", function()
	expect.equal(Absorb.isKnockOff(2, 0.95, 15, 0.4, 15), false)
end)

test("isKnockOff: absorbable cube never knocks off", function()
	expect.equal(Absorb.isKnockOff(2, 0.75, 40, 0.4, 15), false)
end)

-- canEat. Bulk of a box is (l*w*h)^(1/3), worked by hand below.
local bulkRule: Absorb.Rule = { mode = "bulk", ratio = 0.5, longestRatio = 1.5 }
local sizeRule: Absorb.Rule = { mode = "size", ratio = 0.4 }

test("canEat: a violin (3 x 1.1 x 0.4, bulk 1.0968) is edible at D 2.2", function()
	-- 1.0968 <= 0.5 * 2.2 = 1.1 and 3 <= 1.5 * 2.2 = 3.3
	expect.equal(Absorb.canEat(bulkRule, 2.2, 1.0968, 3), true)
end)

test(
	"canEat: the violin is refused at D 2.1 (too long: 3 > 3.15 is false, bulk 1.0968 > 1.05)",
	function()
		expect.equal(Absorb.canEat(bulkRule, 2.1, 1.0968, 3), false)
	end
)

test("canEat: a lamp post (0.4 x 0.4 x 8, bulk 1.0868, longest 8) is not edible at D 3", function()
	-- bulk passes (1.0868 <= 1.5) but 8 > 4.5
	expect.equal(Absorb.canEat(bulkRule, 3, 1.0868, 8), false)
end)

test("canEat: bulk mode boundary is inclusive", function()
	expect.equal(Absorb.canEat(bulkRule, 4, 2, 6), true)
	expect.equal(Absorb.canEat(bulkRule, 4, 2.0001, 6), false)
	expect.equal(Absorb.canEat(bulkRule, 4, 2, 6.0001), false)
end)

test("canEat: size mode keeps size <= ratio * D exactly", function()
	expect.equal(Absorb.canEat(sizeRule, 2, 0.8, 0.8), true)
	expect.equal(Absorb.canEat(sizeRule, 2, 0.8001, 0.8001), false)
	expect.equal(Absorb.canEat(sizeRule, 2, 0.75, 0.75), Absorb.canAbsorb(2, 0.75, 0.4))
end)

test("bulkOf: 3 x 1.1 x 0.4 -> 1.32^(1/3) = 1.0970", function()
	expect.near(Absorb.bulkOf({ 3, 1.1, 0.4 }), 1.0970, 1e-4)
end)

test("needsDiameter: violin 2.19, hatchback 15, bench 7, size mode 2", function()
	expect.near(Absorb.needsDiameter(bulkRule, Absorb.bulkOf({ 3, 1.1, 0.4 }), 3), 2.1936, 1e-3)
	expect.near(Absorb.needsDiameter(bulkRule, Absorb.bulkOf({ 14, 6, 5 }), 14), 15.0, 0.3)
	expect.near(Absorb.needsDiameter(bulkRule, Absorb.bulkOf({ 7, 2, 3 }), 7), 7.0, 0.3)
	expect.near(Absorb.needsDiameter(sizeRule, 0.8, 0.8), 2, 1e-9)
end)

return {}
