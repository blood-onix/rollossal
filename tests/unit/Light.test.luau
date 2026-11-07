--!strict
-- Light objects: the grid query, the id check and the server verdict. Expected values are worked by hand.

local harness = require("./harness")
local Light = require("../../src/shared/Rules/Light")

local test, expect = harness.test, harness.expect

-- Four rows, stride 5 (kind, x, y, z, yaw): L1 (0, 0), L2 (50, 0), L3 (130, 0), L4 (-70, 70).
local data = {
	1,
	0,
	0,
	0,
	0,
	1,
	50,
	0,
	0,
	0,
	2,
	130,
	0,
	0,
	0,
	1,
	-70,
	0,
	70,
	0,
}
local grid = Light.buildGrid(data, 5, 4, 64)

local function sorted(list: { number }): { number }
	table.sort(list)
	return list
end

test(
	"query: rows within 120 studs of the origin are L1, L2 and L4 (distance 99), not L3 (130)",
	function()
		expect.same(sorted(Light.query(grid, data, 5, 0, 0, 120)), { 1, 2, 4 })
	end
)

test("query: a small radius returns only the row it covers", function()
	expect.same(sorted(Light.query(grid, data, 5, 52, 3, 5)), { 2 })
end)

test("query: the radius is round, not square (L4 at 99 is outside 90)", function()
	expect.same(sorted(Light.query(grid, data, 5, 0, 0, 90)), { 1, 2 })
end)

test("parseId: accepts L1 .. L4 only", function()
	expect.equal(Light.parseId("L1", 4), 1)
	expect.equal(Light.parseId("L4", 4), 4)
	expect.equal(Light.parseId("L5", 4), nil)
	expect.equal(Light.parseId("L0", 4), nil)
	expect.equal(Light.parseId("L01", 4), nil)
	expect.equal(Light.parseId("l1", 4), nil)
	expect.equal(Light.parseId("L1 ", 4), nil)
	expect.equal(Light.parseId("L-1", 4), nil)
	expect.equal(Light.parseId("L1e3", 4), nil)
	expect.equal(Light.parseId(12, 4), nil)
	expect.equal(Light.parseId("p12", 4), nil)
end)

local base: Light.VerdictInput = {
	exists = true,
	taken = false,
	distance = 1.2,
	ballRadius = 0.5,
	size = 0.4,
	tolerance = 6,
	edible = true,
}

local function with(change: { [string]: any }): Light.VerdictInput
	local copy = table.clone(base)
	for key, value in change do
		(copy :: any)[key] = value
	end
	return copy
end

test("verdict: an in-range edible object is accepted", function()
	expect.equal(Light.verdict(base), "Ok")
end)

test("verdict: an unknown index is refused first", function()
	expect.equal(Light.verdict(with({ exists = false, taken = true })), "UnknownObject")
end)

test("verdict: a taken object is refused", function()
	expect.equal(Light.verdict(with({ taken = true })), "AlreadyTaken")
end)

test("verdict: a far claim is refused (limit 0.5 + 0.2 + 6 = 6.7)", function()
	expect.equal(Light.verdict(with({ distance = 6.7 })), "Ok")
	expect.equal(Light.verdict(with({ distance = 6.71 })), "OutOfRange")
	expect.equal(Light.verdict(with({ distance = 300 })), "OutOfRange")
end)

test("verdict: a too-big object is refused", function()
	expect.equal(Light.verdict(with({ edible = false })), "TooBig")
end)

return {}
