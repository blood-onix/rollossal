--!strict
-- Sanity checks on src/shared/Content/GreyBoxRoom.luau (data-model §2) and the fixed-number
-- chain check. Expected values are hand-computed (research.md R1); none is taken from the room data.

local harness = require("./harness")
local Room = require("../../src/shared/Content/GreyBoxRoom")
local Growth = require("../../src/shared/Rules/Growth")

local test, expect = harness.test, harness.expect

local function tierSize(tier: number): number
	for _, def in Room.tiers do
		if def.tier == tier then
			return def.size
		end
	end
	error(`no tier {tier}`)
end

test("Room: exactly 30 cubes", function()
	expect.equal(#Room.cubes, 30)
end)

test("Room: cube IDs are unique", function()
	local seen: { [string]: boolean } = {}
	for _, cube in Room.cubes do
		expect.falsy(seen[cube.id])
		seen[cube.id] = true
	end
end)

test("Room: per-tier cube counts match TierDef.count", function()
	for _, def in Room.tiers do
		local n = 0
		for _, cube in Room.cubes do
			if cube.tier == def.tier then
				n += 1
			end
		end
		expect.equal(n, def.count)
	end
end)

test("Room: tier sizes strictly ascend", function()
	for i = 2, #Room.tiers do
		expect.truthy(Room.tiers[i].size > Room.tiers[i - 1].size)
	end
end)

test("Room: every cube lies within halfExtent - 4", function()
	for _, cube in Room.cubes do
		expect.truthy(math.abs(cube.x) <= Room.halfExtent - 4)
		expect.truthy(math.abs(cube.z) <= Room.halfExtent - 4)
	end
end)

test("Room: any two cubes are at least 4 studs apart", function()
	local cubes = Room.cubes
	for i = 1, #cubes do
		for j = i + 1, #cubes do
			local dx = cubes[i].x - cubes[j].x
			local dz = cubes[i].z - cubes[j].z
			expect.truthy(math.sqrt(dx * dx + dz * dz) >= 4)
		end
	end
end)

test("Room: each of the 12 spawn slots has a Tier 1 cube within 10 studs", function()
	local ring = Room.spawnRingRadius
	for slot = 0, Room.spawnSlots - 1 do
		local angle = 2 * math.pi * slot / Room.spawnSlots
		local sx = ring * math.cos(angle)
		local sz = ring * math.sin(angle)
		local nearest = math.huge
		for _, cube in Room.cubes do
			if cube.tier == 1 then
				local dx = cube.x - sx
				local dz = cube.z - sz
				nearest = math.min(nearest, math.sqrt(dx * dx + dz * dz))
			end
		end
		expect.truthy(nearest <= 10)
	end
end)

test("Room: Tier 1 is absorbable at start, every other tier is not (0.8 = 0.4 x 2)", function()
	expect.truthy(tierSize(1) <= 0.8)
	for tier = 2, #Room.tiers do
		expect.truthy(tierSize(tier) > 0.8)
	end
end)

test("Room: chain of pickups opens Tier 2, then Tier 3, then Tier 4", function()
	-- Tier 1 to Tier 2 gate (D >= 2.375): exactly 22 pickups from D = 2
	local d = 2
	local n1 = 0
	while d < 2.375 do
		d = Growth.growDiameter(d, tierSize(1), 0.6)
		n1 += 1
	end
	expect.equal(n1, 22)

	-- Tier 2 to Tier 3 gate (D >= 3.0): 27 pickups from D = 2.3851
	local n2 = 0
	while d < 3.0 do
		d = Growth.growDiameter(d, tierSize(2), 0.6)
		n2 += 1
	end
	expect.equal(n2, 27)

	-- Tier 3 to Tier 4 gate (D >= 3.75): 25 pickups from D = 3.0169
	local n3 = 0
	while d < 3.75 do
		d = Growth.growDiameter(d, tierSize(3), 0.6)
		n3 += 1
	end
	expect.equal(n3, 25)
end)

return {}
