--!strict
-- Expected values are written out by hand from contracts/rules-api.md (Tiers tables).

local harness = require("./harness")
local Tiers = require("../../src/shared/Rules/Tiers")

local test, expect = harness.test, harness.expect

local tiers =
	{ { minDiameter = 2 }, { minDiameter = 2.375 }, { minDiameter = 3 }, { minDiameter = 3.75 } }

local function checkLookup(diameter: number, index: number, nextThreshold: number?)
	local actualIndex, actualNext = Tiers.lookup(diameter, tiers)
	expect.equal(actualIndex, index)
	expect.equal(actualNext, nextThreshold)
end

test("lookup: below the first tier and inside tier 1", function()
	checkLookup(1.5, 1, 2.375)
	checkLookup(2, 1, 2.375)
	checkLookup(2.374, 1, 2.375)
end)

test("lookup: boundaries open the next tier", function()
	checkLookup(2.375, 2, 3)
	checkLookup(2.999, 2, 3)
	checkLookup(3, 3, 3.75)
end)

test("lookup: top tier has no next threshold", function()
	checkLookup(3.75, 4, nil)
	checkLookup(100, 4, nil)
end)

test("progress: fraction towards the next tier", function()
	expect.near(Tiers.progress(1.5, tiers), 0, 1e-9)
	expect.near(Tiers.progress(2, tiers), 0, 1e-9)
	expect.near(Tiers.progress(2.1875, tiers), 0.5, 1e-9)
	expect.near(Tiers.progress(2.6875, tiers), 0.5, 1e-9)
	expect.near(Tiers.progress(3.375, tiers), 0.5, 1e-9)
end)

test("progress: top tier is full", function()
	expect.near(Tiers.progress(3.75, tiers), 1, 1e-9)
	expect.near(Tiers.progress(9, tiers), 1, 1e-9)
end)

test("isCulled: objects at least delta tiers below the player are culled", function()
	local cases = {
		{ 1, 3, 2, true },
		{ 2, 3, 2, false },
		{ 2, 4, 2, true },
		{ 3, 4, 2, false },
		{ 3, 5, 2, true },
		{ 4, 5, 2, false },
		{ 1, 1, 2, false },
		{ 1, 2, 2, false },
	}
	for _, case in cases do
		expect.equal(
			Tiers.isCulled(case[1] :: number, case[2] :: number, case[3] :: number),
			case[4] :: boolean
		)
	end
end)

return {}
