--!strict
-- Park City late-game clearance and the finale (014 research R-08 and R-09, FR-010, FR-011). From the layout file and
-- the generated world: big balls have room on the routes (no static block they cannot roll over narrows a route below
-- 1.25 x the largest ball meant to use it), no solid big object stands on a carriageway, and the map holds enough
-- food for a ball to reach D 100 with 15 % to spare, so the Glass Tower (needs D 95.9) can be eaten. Physics wedging
-- is sampled in Studio (tasks.md T027); these are the data bounds.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local ParkCity = require("../../src/shared/Content/Worlds/ParkCity")
local Parts = require("../../src/shared/Content/Worlds/ParkCityParts")
local Light = require("../../src/shared/Content/Worlds/ParkCityLight")
local Absorb = require("../../src/shared/Rules/Absorb")
local Growth = require("../../src/shared/Rules/Growth")

local test, expect = harness.test, harness.expect

local layout = serde.decode("json", fs.readFile("docs/design/maps/park-city-layout.json")) :: any

local BALLS = { 35, 60, 100 }
local WIDTH_MARGIN = 1.25
-- A block is a wall to a ball of diameter D when its top stands more than this share of D above the route.
local STEP_SHARE = 0.25
local SPARE = 1.15

-- The routes a big ball uses: rect {x0, z0, x1, z1}, the surface height, and the largest ball meant to use it (the
-- top of the zone's highest tier: Ring Road Tier 4, the neighbourhoods Tier 5; the core gets the spec's D 100).
type Route = { id: string, rect: { number }, surface: number, ball: number }
local ROUTES: { Route } = {
	{ id = "ring_n", rect = { -300, -300, 300, -262 }, surface = 0.1, ball = 35 },
	{ id = "ring_s", rect = { -300, 262, 300, 300 }, surface = 0.1, ball = 35 },
	{ id = "ring_w", rect = { -300, -300, -262, 300 }, surface = 0.1, ball = 35 },
	{ id = "ring_e", rect = { 262, -300, 300, 300 }, surface = 0.1, ball = 35 },
	{ id = "spoke_n", rect = { -20, -300, 20, -150 }, surface = 0.35, ball = 80 },
	{ id = "spoke_s", rect = { -20, 150, 20, 300 }, surface = 0.35, ball = 80 },
	{ id = "spoke_w", rect = { -300, -20, -150, 20 }, surface = 0.35, ball = 80 },
	{ id = "spoke_e", rect = { 150, -20, 300, 20 }, surface = 0.35, ball = 80 },
	{ id = "market_street", rect = { 30, -215, 262, -185 }, surface = 0.3, ball = 80 },
	{ id = "terrace_street", rect = { -265, 198, -20, 218 }, surface = 0.3, ball = 80 },
	{ id = "core_ns", rect = { -20, -150, 20, 150 }, surface = 0.4, ball = 100 },
	{ id = "core_ew", rect = { -150, -20, 150, 20 }, surface = 0.4, ball = 100 },
}
local SEARCH = 200

local walls: { any } = {}
for _, block in layout.blocks do
	if block.kind ~= "wall" then
		table.insert(walls, block)
	end
end

local function isWall(block: any, x: number, z: number, surface: number, diameter: number): boolean
	local r = block.rect
	return x >= r[1]
		and x <= r[3]
		and z >= r[2]
		and z <= r[4]
		and block.y[2] > surface + STEP_SHARE * diameter
		and block.y[1] < surface + diameter
end

-- The narrowest free span across the route, sampled every 4 studs along it: from the centre line out to the first
-- wall on each side (capped at SEARCH studs a side).
local function narrowest(route: Route, diameter: number): (number, number)
	local r = route.rect
	local alongX = (r[3] - r[1]) > (r[4] - r[2])
	local a0, a1 = if alongX then r[1] else r[2], if alongX then r[3] else r[4]
	local centre = if alongX then (r[2] + r[4]) / 2 else (r[1] + r[3]) / 2
	local worst, worstAt = math.huge, a0
	for t = a0 + 2, a1 - 2, 4 do
		local span = 0
		for _, side in { -1, 1 } do
			local d = 0
			while d < SEARCH do
				local x, z =
					if alongX then t else centre + side * d, if alongX then centre + side * d else t
				local blocked = false
				for _, block in walls do
					if isWall(block, x, z, route.surface, diameter) then
						blocked = true
						break
					end
				end
				if blocked then
					break
				end
				d += 1
			end
			span += d
		end
		if span < worst then
			worst, worstAt = span, t
		end
	end
	return worst, worstAt
end

test("ParkCityClearance: no wall narrows a route below 1.25 x the balls meant to use it", function()
	for _, route in ROUTES do
		for _, diameter in BALLS do
			if diameter <= route.ball then
				local width, at = narrowest(route, diameter)
				expect.truthy(
					width >= WIDTH_MARGIN * diameter,
					`{route.id} at {at}: free width {width} for a D {diameter} ball`
				)
			end
		end
		-- The largest ball meant for the route, too.
		local width, at = narrowest(route, route.ball)
		expect.truthy(
			width >= WIDTH_MARGIN * route.ball,
			`{route.id} at {at}: free width {width} for a D {route.ball} ball`
		)
	end
end)

-- A solid big object on a road wedges a late ball only if that ball cannot eat it, so a piece that the smallest late
-- ball (D 35) can eat on contact is not a wedge.
test("ParkCityClearance: no solid Tier 4-6 object stands on a carriageway or street", function()
	local rule = ParkCity.rules.absorb :: any
	local objectById: { [string]: any } = {}
	for _, object in ParkCity.objects do
		objectById[object.id] = object
	end
	local carriageways = {}
	for _, route in ROUTES do
		if string.sub(route.id, 1, 4) ~= "core" then
			table.insert(carriageways, route)
		end
	end
	for _, row in Parts do
		local object = objectById[row.objectId]
		if
			object.tier >= 4
			and object.solid
			and Absorb.needsDiameter(rule, object.bulk, object.size) > BALLS[1]
		then
			for _, route in carriageways do
				local r = route.rect
				local inside = row.x > r[1] and row.x < r[3] and row.z > r[2] and row.z < r[4]
				expect.falsy(inside, `{row.id} ({row.objectId}) stands on {route.id}`)
			end
		end
	end
end)

test(
	"ParkCityClearance: the map feeds a ball past D 100 with 15 % spare (finale supply floor)",
	function()
		local rule = ParkCity.rules.absorb :: any
		local objectById: { [string]: any } = {}
		for _, object in ParkCity.objects do
			objectById[object.id] = object
		end
		-- Every placement's needs-D and bulk; an ideal eater takes anything it can, smallest need first.
		local food: { { needs: number, bulk: number } } = {}
		local function add(kind: string)
			local object = objectById[kind]
			table.insert(
				food,
				{ needs = Absorb.needsDiameter(rule, object.bulk, object.size), bulk = object.bulk }
			)
		end
		for _, row in Parts do
			add(row.objectId)
		end
		for index = 1, Light.count do
			add(Light.kinds[Light.data[(index - 1) * Light.stride + 1]])
		end
		table.sort(food, function(a, b)
			return a.needs < b.needs
		end)
		local diameter = ParkCity.rules.startDiameter
		local nextIndex = 1
		while nextIndex <= #food and food[nextIndex].needs <= diameter + 1e-9 do
			diameter = Growth.growByBulk(
				diameter,
				food[nextIndex].bulk,
				ParkCity.rules.growthK,
				rule.garnish
			)
			nextIndex += 1
		end
		local glass = objectById.glass_tower
		local glassNeeds = Absorb.needsDiameter(rule, glass.bulk, glass.size)
		print(
			`  finale supply: an ideal eater reaches D {math.floor(diameter * 10) / 10}; Glass Tower needs D {glassNeeds}`
		)
		expect.truthy(glassNeeds <= 100, `Glass Tower needs D {glassNeeds}`)
		expect.truthy(
			diameter >= 100 * SPARE,
			`ideal eater stops at D {diameter}, under {100 * SPARE}`
		)
		expect.equal(nextIndex, #food + 1)
	end
)

return {}
