--!strict
-- Street rules. Segment under test: x = 0, z 0 -> 100 (yaw 0), carriageway 30, sidewalk 6. The along axis is +z and the
-- right-hand side is +x. Everything below is worked out by hand from the contract in
-- specs/010-main-street-slice/contracts/street-rules-and-scene-kits.md.

local harness = require("./harness")
local Themes = require("../../src/shared/Content/Themes")
local StreetRules = require("../../src/shared/Rules/StreetRules")

local test, expect = harness.test, harness.expect

local IDS: StreetRules.StreetIds =
	{ tree = "tree", lamp = "lamp", bin = "bin", bench = "bench", car = "car", hydrant = "hydrant" }

local function def(seed: number, jitterPos: number, jitterYaw: number): StreetRules.StreetDef
	return {
		seed = seed,
		segments = {
			{ id = "m", x0 = 0, z0 = 0, x1 = 0, z1 = 100, width = 30, sidewalk = 6, yaw = 0 },
		},
		junctions = {},
		ids = IDS,
		treeEvery = 18,
		lampEvery = 24,
		lampTreeClear = 4,
		jitterPos = jitterPos,
		jitterYaw = jitterYaw,
	}
end

local function withJunction(
	seed: number,
	jitterPos: number,
	jitterYaw: number
): StreetRules.StreetDef
	local d = def(seed, jitterPos, jitterYaw)
	d.segments[1].z1 = 200
	d.junctions = { { id = "j1", x = 0, z = 100, crossWidth = 20 } }
	return d
end

local function blocksWith(out: StreetRules.StreetOut, pattern: string): { StreetRules.BlockDef }
	local found = {}
	for _, b in out.blocks do
		if string.find(b.id, pattern) ~= nil then
			table.insert(found, b)
		end
	end
	return found
end

local function placementsOf(out: StreetRules.StreetOut, objectId: string): { StreetRules.Placement }
	local found = {}
	for _, p in out.placements do
		if p.objectId == objectId then
			table.insert(found, p)
		end
	end
	table.sort(found, function(a, b)
		return a.id < b.id
	end)
	return found
end

local function byId(out: StreetRules.StreetOut, id: string): StreetRules.Placement
	for _, p in out.placements do
		if p.id == id then
			return p
		end
	end
	error(`no placement {id}`)
end

local function blockById(out: StreetRules.StreetOut, id: string): StreetRules.BlockDef
	for _, b in out.blocks do
		if b.id == id then
			return b
		end
	end
	error(`no block {id}`)
end

local function angleDiff(a: number, b: number): number
	return math.abs((a - b + 180) % 360 - 180)
end

local function luminance(rgb: { number }): number
	local function linear(channel: number): number
		local c = channel / 255
		if c <= 0.04045 then
			return c / 12.92
		end
		return ((c + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * linear(rgb[1]) + 0.7152 * linear(rgb[2]) + 0.0722 * linear(rgb[3])
end

test("StreetRules: the road is a w-asphalt slab over the whole segment", function()
	local out = StreetRules.expand(def(1, 0, 0))
	local road = blockById(out, "m_road")
	expect.equal(road.swatch, "w-asphalt")
	expect.equal(road.kind, "Block")
	expect.near(road.cframe.x, 0, 1e-9)
	expect.near(road.cframe.z, 50, 1e-9)
	expect.near(road.size.x, 30, 1e-9)
	expect.near(road.size.z, 100, 1e-9)
	expect.near(road.cframe.y + road.size.y / 2, 0.1, 1e-9)
end)

-- Linear luminance: the mean of the sRGB bytes gives only 2.38x for the city palette, but light reaching the eye is
-- linear, and that ratio is about 7x.
test(
	"StreetRules: the road is at least 2.5 times darker than the sidewalk (linear luminance)",
	function()
		local out = StreetRules.expand(def(1, 0, 0))
		local palette = Themes.city.palette
		local road = blockById(out, "m_road").swatch
		local walk = blockById(out, "m_walk_r_1").swatch
		expect.equal(road, "w-asphalt")
		expect.equal(walk, "w-sidewalk")
		expect.truthy(luminance(palette[walk]) >= 2.5 * luminance(palette[road]))
	end
)

test(
	"StreetRules: kerb band is w-kerb, 0.4 stud high, 0.6 wide, against the carriageway edge",
	function()
		local out = StreetRules.expand(def(1, 0, 0))
		local right = blockById(out, "m_kerb_r_1")
		expect.equal(right.swatch, "w-kerb")
		expect.near(right.cframe.x, 15.3, 1e-9)
		expect.near(right.size.x, 0.6, 1e-9)
		expect.near(right.size.y, 0.4, 1e-9)
		expect.near(right.cframe.y, 0.2, 1e-9)
		expect.near(right.size.z, 100, 1e-9)
		local left = blockById(out, "m_kerb_l_1")
		expect.near(left.cframe.x, -15.3, 1e-9)
	end
)

test(
	"StreetRules: sidewalk is w-sidewalk, raised 0.4, exactly `sidewalk` wide, beside the kerb",
	function()
		local out = StreetRules.expand(def(1, 0, 0))
		local walk = blockById(out, "m_walk_r_1")
		expect.near(walk.size.x, 6, 1e-9)
		expect.near(walk.cframe.x, 18.6, 1e-9)
		expect.near(walk.cframe.y + walk.size.y / 2, 0.4, 1e-9)
		local left = blockById(out, "m_walk_l_1")
		expect.near(left.cframe.x, -18.6, 1e-9)
	end
)

test("StreetRules: a sidewalk under 6 studs is an error", function()
	local d = def(1, 0, 0)
	d.segments[1].sidewalk = 5.9
	local ok = pcall(StreetRules.expand, d)
	expect.falsy(ok)
end)

test("StreetRules: a yaw that does not match the endpoints is an error", function()
	local d = def(1, 0, 0)
	d.segments[1].yaw = 90
	expect.falsy(pcall(StreetRules.expand, d))
end)

test(
	"StreetRules: centre line dashes are 1 stud long with a 1 stud gap, 0.3 wide, w-road-line",
	function()
		local out = StreetRules.expand(def(1, 0, 0))
		local dashes = blocksWith(out, "^m_dash_")
		expect.equal(#dashes, 50)
		table.sort(dashes, function(a, b)
			return a.cframe.z < b.cframe.z
		end)
		expect.equal(dashes[1].swatch, "w-road-line")
		expect.near(dashes[1].size.z, 1, 1e-9)
		expect.near(dashes[1].size.x, 0.3, 1e-9)
		expect.near(dashes[1].cframe.z, 0.5, 1e-9)
		expect.near(dashes[2].cframe.z, 2.5, 1e-9)
		expect.near(dashes[50].cframe.z, 98.5, 1e-9)
		for _, dash in dashes do
			expect.near(dash.cframe.x, 0, 1e-9)
		end
	end
)

test("StreetRules: trees stand every 18 studs on the sidewalk line, both sides", function()
	local out = StreetRules.expand(def(1, 0, 0))
	local trees = placementsOf(out, "tree")
	expect.equal(#trees, 10)
	local right = {}
	for _, tree in trees do
		if tree.x > 0 then
			table.insert(right, tree.z)
		end
		expect.near(math.abs(tree.x), 17.6, 1e-9)
		expect.near(tree.y, 0.4, 1e-9)
	end
	table.sort(right)
	expect.same(right, { 9, 27, 45, 63, 81 })
end)

test(
	"StreetRules: lamps stand about every 24 studs, shifted to stay 4 or more studs from any trunk",
	function()
		local out = StreetRules.expand(def(1, 0, 0))
		local lamps = placementsOf(out, "lamp")
		expect.equal(#lamps, 8)
		local right = {}
		for _, lamp in lamps do
			if lamp.x > 0 then
				table.insert(right, lamp.z)
			end
			expect.near(math.abs(lamp.x), 16.6, 1e-9)
		end
		table.sort(right)
		expect.same(right, { 13, 36, 59, 85 })
		for _, lamp in lamps do
			for _, tree in placementsOf(out, "tree") do
				local distance = math.sqrt((lamp.x - tree.x) ^ 2 + (lamp.z - tree.z) ^ 2)
				expect.truthy(distance >= 4)
			end
		end
	end
)

test("StreetRules: lamp-tree clearance holds for every seed and a different spacing", function()
	for seed = 1, 20 do
		local d = def(seed, 0.5, 3)
		d.segments[1].z1 = 400
		local out = StreetRules.expand(d)
		for _, lamp in placementsOf(out, "lamp") do
			for _, tree in placementsOf(out, "tree") do
				expect.truthy(math.sqrt((lamp.x - tree.x) ^ 2 + (lamp.z - tree.z) ^ 2) >= 4)
			end
		end
	end
end)

test("StreetRules: benches face the road (segment yaw +- 90 toward the carriageway)", function()
	local out = StreetRules.expand(def(1, 0, 0))
	local benches = placementsOf(out, "bench")
	expect.equal(#benches, 1)
	local bench = benches[1]
	expect.near(bench.z, 54, 1e-9)
	-- On the +x side, so the front (local -Z) must point -x: yaw 90 degrees.
	expect.truthy(bench.x > 0)
	expect.near(bench.yaw, math.rad(90), 1e-9)
	-- Front direction of yaw theta is (-sin, -cos): pointing at the carriageway.
	expect.truthy(-math.sin(bench.yaw) < 0)
end)

test("StreetRules: a junction gets a bin at each of its four corners, facing the road", function()
	local out = StreetRules.expand(withJunction(1, 0, 0))
	local bins = placementsOf(out, "bin")
	expect.equal(#bins, 4)
	for _, bin in bins do
		-- cross street is 20 wide at z = 100, so corners are at z = 100 +- 11.2
		expect.truthy(math.abs(math.abs(bin.z - 100) - 11.2) < 1e-9)
		expect.near(math.abs(bin.x), 16.6, 1e-9)
		local frontX = -math.sin(bin.yaw)
		expect.truthy(frontX * bin.x < 0)
	end
end)

test(
	"StreetRules: a junction cuts the sidewalk and leaves a road patch for the cross street",
	function()
		local out = StreetRules.expand(withJunction(1, 0, 0))
		expect.equal(#blocksWith(out, "^m_walk_r_"), 2)
		local first = blockById(out, "m_walk_r_1")
		expect.near(first.cframe.z + first.size.z / 2, 90, 1e-9)
		local second = blockById(out, "m_walk_r_2")
		expect.near(second.cframe.z - second.size.z / 2, 110, 1e-9)
		local cut = blockById(out, "m_j1_cut_r")
		expect.equal(cut.swatch, "w-asphalt")
		expect.near(cut.size.z, 20, 1e-9)
		expect.near(cut.cframe.z, 100, 1e-9)
	end
)

test("StreetRules: zebra crossings flank the junction, stripes 1 wide with a 1 stud gap", function()
	local out = StreetRules.expand(withJunction(1, 0, 0))
	local south = blocksWith(out, "^m_j1_zebra_s_")
	local north = blocksWith(out, "^m_j1_zebra_n_")
	expect.equal(#south, 14)
	expect.equal(#north, 14)
	table.sort(south, function(a, b)
		return a.cframe.x < b.cframe.x
	end)
	expect.equal(south[1].swatch, "w-white")
	expect.near(south[1].size.x, 1, 1e-9)
	expect.near(south[1].size.z, 4, 1e-9)
	expect.near(south[1].cframe.x, -13, 1e-9)
	expect.near(south[2].cframe.x - south[1].cframe.x, 2, 1e-9)
	expect.near(south[14].cframe.x, 13, 1e-9)
	-- crossWidth 20: south crossing starts 1 stud past the cross street (z = 90 - 1) and is 4 deep.
	expect.near(south[1].cframe.z, 87, 1e-9)
	expect.near(north[1].cframe.z, 113, 1e-9)
end)

test("StreetRules: no centre dash overlaps a crossing or the cross street", function()
	local out = StreetRules.expand(withJunction(1, 0, 0))
	for _, dash in blocksWith(out, "^m_dash_") do
		expect.truthy(dash.cframe.z < 85 or dash.cframe.z > 115)
	end
end)

test("StreetRules: parked cars sit in the kerb lane, parallel to the road", function()
	local seen = 0
	for seed = 1, 10 do
		local out = StreetRules.expand(def(seed, 0, 0))
		for _, car in placementsOf(out, "car") do
			seen += 1
			expect.near(math.abs(car.x), 11.8, 1e-9)
			expect.near(car.y, 0.1, 1e-9)
			local yaw = math.deg(car.yaw) % 360
			if car.x > 0 then
				expect.near(yaw, 180, 1e-9)
			else
				expect.near(yaw, 0, 1e-9)
			end
		end
	end
	expect.truthy(seen > 10)
end)

test("StreetRules: nothing is parked inside a junction or its crossings", function()
	for seed = 1, 10 do
		local out = StreetRules.expand(withJunction(seed, 0, 0))
		for _, car in placementsOf(out, "car") do
			expect.truthy(math.abs(car.z - 100) >= 23 - 1e-9)
		end
	end
end)

test("StreetRules: jitter stays within 0.5 stud and 3 degrees of the un-jittered layout", function()
	for seed = 1, 15 do
		local plain = StreetRules.expand(withJunction(seed, 0, 0))
		local jittered = StreetRules.expand(withJunction(seed, 0.5, 3))
		expect.equal(#jittered.placements, #plain.placements)
		for _, p in plain.placements do
			local q = byId(jittered, p.id)
			expect.equal(q.objectId, p.objectId)
			expect.truthy(math.abs(q.x - p.x) <= 0.5 + 1e-9)
			expect.truthy(math.abs(q.z - p.z) <= 0.5 + 1e-9)
			expect.truthy(angleDiff(math.deg(q.yaw), math.deg(p.yaw)) <= 3 + 1e-9)
		end
	end
end)

test("StreetRules: trees and lamps keep their even spacing, only their yaw is jittered", function()
	local plain = StreetRules.expand(def(3, 0, 0))
	local jittered = StreetRules.expand(def(3, 0.5, 3))
	for _, objectId in { "tree", "lamp" } do
		for _, p in placementsOf(plain, objectId) do
			local q = byId(jittered, p.id)
			expect.equal(q.x, p.x)
			expect.equal(q.z, p.z)
		end
	end
end)

test(
	"StreetRules: every yaw is the segment yaw, +180, or a perpendicular axis, within jitter",
	function()
		for seed = 1, 10 do
			local out = StreetRules.expand(withJunction(seed, 0.5, 3))
			for _, p in out.placements do
				local yaw = math.deg(p.yaw)
				local best = math.min(
					angleDiff(yaw, 0),
					angleDiff(yaw, 90),
					angleDiff(yaw, 180),
					angleDiff(yaw, 270)
				)
				expect.truthy(best <= 3 + 1e-9)
			end
		end
	end
)

test("StreetRules: placement ids and block ids are unique", function()
	local out = StreetRules.expand(withJunction(5, 0.5, 3))
	local seen: { [string]: boolean } = {}
	for _, p in out.placements do
		expect.falsy(seen[p.id], p.id)
		seen[p.id] = true
	end
	local seenBlocks: { [string]: boolean } = {}
	for _, b in out.blocks do
		expect.falsy(seenBlocks[b.id], b.id)
		seenBlocks[b.id] = true
	end
end)

test("StreetRules: the same StreetDef gives the same output; another seed differs", function()
	local a = StreetRules.expand(withJunction(9, 0.5, 3))
	local b = StreetRules.expand(withJunction(9, 0.5, 3))
	local c = StreetRules.expand(withJunction(10, 0.5, 3))
	expect.equal(#a.placements, #b.placements)
	expect.equal(#a.blocks, #b.blocks)
	for i, p in a.placements do
		expect.equal(p.id, b.placements[i].id)
		expect.equal(p.x, b.placements[i].x)
		expect.equal(p.z, b.placements[i].z)
		expect.equal(p.yaw, b.placements[i].yaw)
	end
	local differs = false
	for i, p in a.placements do
		local q = c.placements[i]
		if q == nil or q.x ~= p.x or q.z ~= p.z or q.yaw ~= p.yaw then
			differs = true
		end
	end
	expect.truthy(differs)
end)

test("StreetRules: a street along +x is the same layout turned 90 degrees", function()
	local d = def(1, 0, 0)
	d.segments =
		{ { id = "m", x0 = 0, z0 = 0, x1 = 100, z1 = 0, width = 30, sidewalk = 6, yaw = 90 } }
	local out = StreetRules.expand(d)
	-- Right-hand side of +x travel is -z (n = (cos 90, -sin 90) = (0, -1)).
	local trees = placementsOf(out, "tree")
	for _, tree in trees do
		expect.near(math.abs(tree.z), 17.6, 1e-9)
	end
	local road = blockById(out, "m_road")
	expect.near(road.cframe.x, 50, 1e-9)
	expect.near(road.cframe.yaw, 90, 1e-9)
	expect.near(road.size.x, 30, 1e-9)
	expect.near(road.size.z, 100, 1e-9)
end)

test("StreetRules: a junction that sits on no segment is an error", function()
	local d = def(1, 0, 0)
	d.junctions = { { id = "far", x = 80, z = 50, crossWidth = 20 } }
	expect.falsy(pcall(StreetRules.expand, d))
end)

return {}
