--!strict
-- Rules/Markers.validate (006, data-model.md): one error per broken rule, each starting with its prefix.
-- The fixture is small and written out by hand; the Snow Village set is checked in SnowVillage.test.

local harness = require("./harness")
local Markers = require("../../src/shared/Rules/Markers")

local test, expect = harness.test, harness.expect

type Marker = Markers.Marker

local HALF_EXTENT = 100

local defs: Markers.Defs = {
	boosters = {
		{ subKind = "dash", footprint = { w = 5, d = 5 } },
		{ subKind = "magnet", footprint = { w = 5, d = 5 } },
		{ subKind = "spring", footprint = { w = 8, d = 8 } },
		{ subKind = "shield", footprint = { w = 5, d = 5 } },
		{ subKind = "slick_trail", footprint = { w = 5, d = 5 } },
	},
	traps = {
		{ subKind = "slick", footprint = { w = 14, d = 14 } },
		{ subKind = "bumper", footprint = { w = 4, d = 4 } },
		{ subKind = "slow", footprint = { w = 14, d = 14 } },
		{ subKind = "sweeper", footprint = { w = 10, d = 6 } },
	},
}

local SQUARE = { { x = 0, z = 0 }, { x = 20, z = 0 }, { x = 20, z = 20 }, { x = 0, z = 20 } }

local function marker(id: string, kind: string, subKind: string, x: number, z: number): Marker
	return { id = id, kind = kind, subKind = subKind, x = x, y = 0, z = z, yaw = 0, waypoints = nil }
end

-- One marker per sub-kind, spread 30 studs apart on a grid so nothing touches.
local function validSet(): { Marker }
	local list: { Marker } = {}
	local column = 0
	for _, subKind in Markers.SUBKINDS.BoosterSpot do
		table.insert(
			list,
			marker(`booster-{subKind}-1`, "BoosterSpot", subKind, -80 + column * 30, -60)
		)
		column += 1
	end
	column = 0
	for _, subKind in { "slick", "bumper", "slow" } do
		table.insert(list, marker(`trap-{subKind}-1`, "TrapSpot", subKind, -80 + column * 30, 60))
		column += 1
	end
	local sweeper = marker("trap-sweeper-1", "TrapSpot", "sweeper", 20, -10)
	sweeper.waypoints =
		{ { x = 20, z = -10 }, { x = 40, z = -10 }, { x = 40, z = 10 }, { x = 20, z = 10 } }
	table.insert(list, sweeper)
	return list
end

-- The keep-out each marker needs, built by hand from the footprints above.
local function keepOutsFor(list: { Marker }): { Markers.KeepOut }
	local keepOuts: { Markers.KeepOut } = {}
	local function add(x: number, z: number, w: number, d: number)
		table.insert(
			keepOuts,
			{ id = `ko_marker_{#keepOuts + 1}`, kind = "marker", x = x, z = z, w = w, d = d }
		)
	end
	local sizes: { [string]: number } = {
		dash = 5,
		magnet = 5,
		spring = 8,
		shield = 5,
		slick_trail = 5,
		slick = 14,
		bumper = 4,
		slow = 14,
	}
	for _, item in list do
		if item.subKind == "sweeper" then
			-- 20 x 20 loop, grown by 5 on every side: four 30 x 10 or 10 x 30 boxes on the sides.
			add(30, -10, 30, 10)
			add(40, 0, 10, 30)
			add(30, 10, 30, 10)
			add(20, 0, 10, 30)
		else
			local size = sizes[item.subKind]
			add(item.x, item.z, size, size)
		end
	end
	return keepOuts
end

local function run(
	list: { Marker },
	keepOuts: { Markers.KeepOut }?,
	blocks: { Markers.Block }?
): { string }
	return Markers.validate(
		list,
		blocks or {},
		keepOuts or keepOutsFor(validSet()),
		HALF_EXTENT,
		defs
	)
end

local function expectOne(errors: { string }, prefix: string)
	expect.equal(#errors, 1, table.concat(errors, " | "))
	expect.equal(string.sub(errors[1], 1, #prefix), prefix)
end

test("validate: a complete valid set has no errors", function()
	expect.equal(#run(validSet()), 0, table.concat(run(validSet()), " | "))
end)

test("validate: a duplicate id is one marker id error", function()
	local list = validSet()
	list[2].id = list[1].id
	expectOne(run(list), "marker id")
end)

test("validate: an empty id is one marker id error", function()
	local list = validSet()
	list[1].id = ""
	expectOne(run(list), "marker id")
end)

test("validate: an unknown kind is one marker kind error", function()
	local list = validSet()
	list[1].kind = "CoinSpot"
	local errors = run(list)
	-- The skipped marker also leaves its sub-kind uncovered.
	expect.equal(string.sub(errors[1], 1, 11), "marker kind")
end)

test("validate: a sub-kind of the other kind is one marker subKind error", function()
	local list = validSet()
	list[1].subKind = "bumper"
	local errors = run(list)
	expect.equal(string.sub(errors[1], 1, 14), "marker subKind")
end)

test("validate: a marker outside the world is one marker bounds error", function()
	local list = validSet()
	list[1].x = 99
	local keepOuts = keepOutsFor(validSet())
	keepOuts[1].x = 99
	expectOne(run(list, keepOuts), "marker bounds")
end)

test("validate: a marker whose footprint crosses the edge is a bounds error", function()
	local list = validSet()
	-- A 5 x 5 pad centred at 98 reaches 100.5.
	list[1].x = 98
	local keepOuts = keepOutsFor(validSet())
	keepOuts[1].x = 98
	expectOne(run(list, keepOuts), "marker bounds")
end)

test("validate: a marker on a block is one marker overlap error", function()
	local block: Markers.Block = {
		id = "wall",
		cframe = { x = -80, y = 2, z = -60, yaw = 0 },
		size = { x = 4, y = 4, z = 4 },
	}
	expectOne(run(validSet(), nil, { block }), "marker overlap")
end)

test("validate: ground blocks do not count as overlap", function()
	local ground: Markers.Block = {
		id = "ground",
		cframe = { x = 0, y = -0.5, z = 0, yaw = 0 },
		size = { x = 200, y = 1, z = 200 },
	}
	expect.equal(#run(validSet(), nil, { ground }), 0)
end)

test("validate: two markers on the same spot are one marker overlap error", function()
	local list = validSet()
	list[2].x = list[1].x
	list[2].z = list[1].z
	local keepOuts = keepOutsFor(validSet())
	keepOuts[2].x = list[1].x
	keepOuts[2].z = list[1].z
	expectOne(run(list, keepOuts), "marker overlap")
end)

test("validate: a sweeper with two waypoints is one marker waypoints error", function()
	local list = validSet()
	local sweeper = list[#list]
	sweeper.waypoints = { { x = 20, z = -10 }, { x = 40, z = -10 } }
	local keepOuts = keepOutsFor(validSet())
	-- One box for the lone footprint at (20, -10): 10 x 6 grown to cover it.
	table.insert(keepOuts, { id = "ko_extra", kind = "marker", x = 20, z = -10, w = 10, d = 10 })
	expectOne(run(list, keepOuts), "marker waypoints")
end)

test("validate: a zero-length sweeper segment is one marker waypoints error", function()
	local list = validSet()
	local sweeper = list[#list]
	sweeper.waypoints = {
		{ x = 20, z = -10 },
		{ x = 40, z = -10 },
		{ x = 40, z = -10 },
		{ x = 40, z = 10 },
		{ x = 20, z = 10 },
	}
	local errors = run(list, nil)
	expect.equal(string.sub(errors[1], 1, 16), "marker waypoints")
end)

test("validate: a sweeper waypoint outside the world is a waypoints error", function()
	local list = validSet()
	local sweeper = list[#list]
	sweeper.waypoints = { { x = 20, z = -10 }, { x = 140, z = -10 }, { x = 40, z = 10 } }
	local errors = run(list, nil)
	expect.equal(string.sub(errors[1], 1, 16), "marker waypoints")
end)

test("validate: a waypoint list on a non-sweeper is one marker waypoints error", function()
	local list = validSet()
	list[1].waypoints = SQUARE
	expectOne(run(list), "marker waypoints")
end)

test("validate: a marker with no keep-out is one marker keepout error", function()
	local keepOuts = keepOutsFor(validSet())
	table.remove(keepOuts, 1)
	expectOne(run(validSet(), keepOuts), "marker keepout")
end)

test("validate: a keep-out smaller than the footprint is a keepout error", function()
	local keepOuts = keepOutsFor(validSet())
	keepOuts[3].w = 7
	expectOne(run(validSet(), keepOuts), "marker keepout")
end)

test("validate: a missing sweeper segment keep-out is a keepout error", function()
	local keepOuts = keepOutsFor(validSet())
	table.remove(keepOuts, #keepOuts)
	expectOne(run(validSet(), keepOuts), "marker keepout")
end)

test("validate: a missing sub-kind is one marker coverage error", function()
	local list = validSet()
	table.remove(list, 4)
	expectOne(run(list, keepOutsFor(validSet())), "marker coverage")
end)

test("segmentRect: grown by half the long side on every side", function()
	local rect = Markers.segmentRect({ x = 0, z = 0 }, { x = 20, z = 0 }, { w = 10, d = 6 })
	expect.equal(rect.x, 10)
	expect.equal(rect.z, 0)
	expect.equal(rect.hx, 15)
	expect.equal(rect.hz, 5)
end)
