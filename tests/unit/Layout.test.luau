--!strict
-- Expected values are worked out by hand in specs/004-snow-village/contracts/rules-api.md (Layout).

local harness = require("./harness")
local Layout = require("../../src/shared/Rules/Layout")

local test, expect = harness.test, harness.expect

local function zone(id: string, w: number, d: number, count: number, seed: number, mix): Layout.Zone
	return { id = id, x = 0, z = 0, w = w, d = d, y = 0, mix = mix, count = count, seed = seed }
end

local one = { { objectId = "a", weight = 1 } }
local sizes: { [string]: number } = { a = 1.0, b = 2.5 }

test("next: three hand-computed generator steps", function()
	expect.equal(Layout.next(1), 48271)
	expect.equal(Layout.next(48271), 182605794)
	expect.equal(Layout.next(182605794), 1291394886)
end)

test("normaliseSeed: any seed becomes a valid state", function()
	expect.equal(Layout.normaliseSeed(0), 1)
	expect.equal(Layout.normaliseSeed(5), 6)
	expect.equal(Layout.normaliseSeed(2147483646), 1)
end)

test("cellEdge and capacity: one object size", function()
	local z = zone("z", 20, 10, 1, 1, one)
	expect.near(Layout.cellEdge(z, sizes), 1.2, 1e-9)
	expect.equal(Layout.capacity(z, sizes), 128)
end)

test("cellEdge and capacity: the largest size in the mix wins", function()
	local z =
		zone("z", 20, 10, 1, 1, { { objectId = "a", weight = 1 }, { objectId = "b", weight = 1 } })
	expect.near(Layout.cellEdge(z, sizes), 3.0, 1e-9)
	expect.equal(Layout.capacity(z, sizes), 18)
end)

test("expand: same input gives the same placements", function()
	local zones = { zone("z", 20, 10, 40, 7, one) }
	local first = Layout.expand(zones, sizes)
	local second = Layout.expand(zones, sizes)
	expect.equal(#first, 40)
	expect.equal(#second, 40)
	for i, placement in first do
		local other = second[i]
		expect.equal(placement.id, other.id)
		expect.equal(placement.objectId, other.objectId)
		expect.equal(placement.x, other.x)
		expect.equal(placement.z, other.z)
		expect.equal(placement.yaw, other.yaw)
	end
end)

test("expand: ids are zone id plus a 3-digit index", function()
	local placements = Layout.expand({ zone("porch", 20, 10, 3, 1, one) }, sizes)
	expect.equal(placements[1].id, "porch_001")
	expect.equal(placements[3].id, "porch_003")
end)

test("expand: changing one seed changes only that zone", function()
	local a1 = zone("a", 20, 10, 20, 1, one)
	local b1 = zone("b", 20, 10, 20, 2, one)
	local b2 = zone("b", 20, 10, 20, 3, one)
	local before = Layout.expand({ a1, b1 }, sizes)
	local after = Layout.expand({ a1, b2 }, sizes)
	local bChanged = false
	for i, placement in before do
		local other = after[i]
		if placement.id:sub(1, 1) == "a" then
			expect.equal(placement.x, other.x)
			expect.equal(placement.z, other.z)
		elseif placement.x ~= other.x or placement.z ~= other.z then
			bChanged = true
		end
	end
	expect.truthy(bChanged)
end)

test("expand: a full zone has no overlapping footprints and stays inside", function()
	local z = zone("full", 20, 10, 128, 11, one)
	local placements = Layout.expand({ z }, sizes)
	expect.equal(#placements, 128)
	for i, p in placements do
		expect.truthy(math.abs(p.x - z.x) <= z.w / 2)
		expect.truthy(math.abs(p.z - z.z) <= z.d / 2)
		for j = i + 1, #placements do
			local q = placements[j]
			local distance = math.sqrt((p.x - q.x) ^ 2 + (p.z - q.z) ^ 2)
			expect.truthy(distance >= 1.0 - 1e-9)
		end
	end
end)

test("expand: mixed sizes do not overlap either", function()
	local z = zone(
		"mix",
		20,
		10,
		18,
		5,
		{ { objectId = "a", weight = 1 }, { objectId = "b", weight = 1 } }
	)
	local placements = Layout.expand({ z }, sizes)
	for i, p in placements do
		for j = i + 1, #placements do
			local q = placements[j]
			local distance = math.sqrt((p.x - q.x) ^ 2 + (p.z - q.z) ^ 2)
			expect.truthy(distance >= (sizes[p.objectId] + sizes[q.objectId]) / 2 - 1e-9)
		end
	end
end)

test("expand: placements carry the zone height and spawn slot", function()
	local z = zone("raised", 20, 10, 2, 1, one)
	z.y = 4.5
	z.spawnSlot = 3
	local placements = Layout.expand({ z }, sizes)
	expect.equal(placements[1].y, 4.5)
	expect.equal(placements[1].spawnSlot, 3)
end)

test("healthiestSlot: the most available objects wins", function()
	expect.equal(Layout.healthiestSlot({ 3, 7, 5 }, {}), 2)
end)

test("healthiestSlot: ties go to the lowest index", function()
	expect.equal(Layout.healthiestSlot({ 4, 4, 2 }, {}), 1)
end)

test("healthiestSlot: a free slot beats a healthier slot already in use", function()
	expect.equal(Layout.healthiestSlot({ 9, 1, 2 }, { [1] = true }), 3)
end)

test("healthiestSlot: when every slot is in use, the healthiest one is chosen", function()
	expect.equal(Layout.healthiestSlot({ 9, 1, 2 }, { [1] = true, [2] = true, [3] = true }), 1)
end)

test("expand: a count above the capacity is an error", function()
	local ok = pcall(Layout.expand, { zone("over", 20, 10, 129, 1, one) }, sizes)
	expect.falsy(ok)
end)

return {}
