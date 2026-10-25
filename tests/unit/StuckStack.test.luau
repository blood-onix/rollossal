--!strict
-- Expected values are hand-computed from contracts/rules-api.md §StuckStack.

local harness = require("./harness")
local StuckStack = require("../../src/shared/Rules/StuckStack")

local test, expect = harness.test, harness.expect

local function range(first: number, last: number): { number }
	local list = {}
	for i = first, last do
		table.insert(list, i)
	end
	return list
end

test("push: 31 entries onto cap 30 drops the first", function()
	local stack = range(1, 30)
	local result = StuckStack.push(stack, 31, 30)
	expect.equal(#result, 30)
	expect.equal(result[1], 2)
	expect.equal(result[30], 31)
end)

test("popRecent: 3 from 5 returns the newest three, newest last", function()
	local remaining, removed = StuckStack.popRecent(range(1, 5), 3)
	expect.same(removed, { 3, 4, 5 })
	expect.same(remaining, { 1, 2 })
end)

test("popRecent: 3 from 2 returns both entries", function()
	local remaining, removed = StuckStack.popRecent(range(1, 2), 3)
	expect.same(removed, { 1, 2 })
	expect.same(remaining, {})
end)

test("popRecent: from empty returns two empty lists", function()
	local remaining, removed = StuckStack.popRecent({}, 3)
	expect.same(remaining, {})
	expect.same(removed, {})
end)

test("visibleTail: 40 entries with max 30 returns 11 to 40", function()
	local result = StuckStack.visibleTail(range(1, 40), 30)
	expect.equal(#result, 30)
	expect.equal(result[1], 11)
	expect.equal(result[30], 40)
end)

test("push does not mutate its input", function()
	local stack = range(1, 3)
	StuckStack.push(stack, 4, 2)
	expect.same(stack, { 1, 2, 3 })
end)

test("popRecent does not mutate its input", function()
	local stack = range(1, 5)
	StuckStack.popRecent(stack, 3)
	expect.same(stack, { 1, 2, 3, 4, 5 })
end)

test("visibleTail does not mutate its input", function()
	local stack = range(1, 40)
	StuckStack.visibleTail(stack, 30)
	expect.equal(#stack, 40)
end)

return {}
