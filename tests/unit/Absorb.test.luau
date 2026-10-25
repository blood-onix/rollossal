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

return {}
