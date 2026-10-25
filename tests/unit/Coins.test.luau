--!strict
-- Expected values are written out by hand from contracts/rules-api.md (Coins table).

local harness = require("./harness")
local Coins = require("../../src/shared/Rules/Coins")

local test, expect = harness.test, harness.expect

local values = { 1, 2, 3, 5 }

local function options(friend: boolean, boostCount: number, double: boolean): Coins.Options
	return {
		friendBonusRate = 0.2,
		hasFriendInServer = friend,
		hasDoubleCoins = double,
		friendBoostRate = 0.25,
		friendBoostCount = boostCount,
	}
end

test("total: empty list is 0 with every multiplier on", function()
	expect.equal(Coins.total({}, options(true, 3, true)), 0)
end)

test("total: no multipliers is the base 11", function()
	expect.equal(Coins.total(values, options(false, 0, false)), 11)
end)

test("total: friend only 13.2 rounds to 13", function()
	expect.equal(Coins.total(values, options(true, 0, false)), 13)
end)

test("total: boost count 2 only 16.5 rounds half up to 17", function()
	expect.equal(Coins.total(values, options(false, 2, false)), 17)
end)

test("total: double only is 22", function()
	expect.equal(Coins.total(values, options(false, 0, true)), 22)
end)

test("total: friend + boost 1 + double is 33", function()
	expect.equal(Coins.total(values, options(true, 1, true)), 33)
end)

test("total: single 5 with boost count 2 is 7.5, rounds to 8", function()
	expect.equal(Coins.total({ 5 }, options(false, 2, false)), 8)
end)

test("total: three 1s with a friend is 3.6, rounds to 4", function()
	expect.equal(Coins.total({ 1, 1, 1 }, options(true, 0, false)), 4)
end)

test("total: one 1 with a friend is 1.2, rounds to 1", function()
	expect.equal(Coins.total({ 1 }, options(true, 0, false)), 1)
end)

test("total: boost count 0 equals no boost", function()
	expect.equal(Coins.total(values, options(false, 0, false)), 11)
end)

test("total: extra trailing entries never lower the total", function()
	for _, opts in { options(false, 0, false), options(true, 2, true) } do
		expect.truthy(Coins.total({ 1, 2, 3, 5, 1 }, opts) >= Coins.total(values, opts))
	end
end)

return {}
