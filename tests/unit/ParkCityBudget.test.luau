--!strict
-- Park City's scene triangle cost (014 research R-07, FR-012). Sums art/export/manifest.json triangles over what a
-- player's client draws at fixed probes: every server Part (the 1,138 Parts rows, the active theme's slot and meme
-- rows and the map-edge scenery) plus the light window (the nearest Config.lightPoolCap light objects within
-- Config.lightDrawRadius). "Culled" is the same scene for a Tier 5 ball, with tiers culled by Config.cullTierDelta.
-- A stand-in counts as a box (12 triangles). When the benchmark has set the ceilings in Config.Budgets, the worst
-- probe stays under them.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local ParkCity = require("../../src/shared/Content/Worlds/ParkCity")
local Parts = require("../../src/shared/Content/Worlds/ParkCityParts")
local Light = require("../../src/shared/Content/Worlds/ParkCityLight")

local test, expect = harness.test, harness.expect

local layout = serde.decode("json", fs.readFile("docs/design/maps/park-city-layout.json")) :: any
local manifest = serde.decode("json", fs.readFile("art/export/manifest.json")) :: any

local STAND_IN = 12
local CULL_TIER = 5

local trianglesOf: { [string]: number } = {}
for _, mesh in manifest.meshes do
	trianglesOf[mesh.id] = mesh.triangles
end

local world = ParkCity :: any
local theme = world.themeBindings[world.activeThemeId]
local objectById: { [string]: any } = {}
for _, object in world.objects do
	objectById[object.id] = object
end
for _, object in theme.objects do
	objectById[object.id] = object
end

local function cost(object: any): number
	return if object.assetKey then trianglesOf[object.assetKey] or STAND_IN else STAND_IN
end

local function culled(tier: number, playerTier: number?): boolean
	return playerTier ~= nil and tier <= playerTier - Config.cullTierDelta
end

-- Server Parts the client draws: layout rows (slot rows as the active theme binds them), slot meme rows, theme overlays.
local serverRows: { any } = {}
for _, row in Parts do
	local slot = world.slotRows[row.id]
	table.insert(serverRows, if slot then theme.slots[slot] else row.objectId)
end
for _, row in world.slotPlacements do
	table.insert(serverRows, theme.slots[row.objectId])
end
for _, row in theme.overlays.fixedPlacements do
	table.insert(serverRows, row.objectId)
end

local sceneryTriangles = 0
for _, row in world.environment.scenery do
	sceneryTriangles += if row.assetKey then trianglesOf[row.assetKey] or STAND_IN else STAND_IN
end

local function serverTriangles(playerTier: number?): number
	local total = sceneryTriangles
	for _, objectId in serverRows do
		local object = objectById[objectId]
		if not culled(object.tier, playerTier) then
			total += cost(object)
		end
	end
	return total
end

local function lightTriangles(x: number, z: number, playerTier: number?): number
	local radius2 = Config.lightDrawRadius * Config.lightDrawRadius
	local near: { { distance: number, triangles: number } } = {}
	for index = 1, Light.count do
		local at = (index - 1) * Light.stride
		local object = objectById[Light.kinds[Light.data[at + 1]]]
		local dx, dz = Light.data[at + 2] - x, Light.data[at + 4] - z
		local distance = dx * dx + dz * dz
		if distance <= radius2 and not culled(object.tier, playerTier) then
			table.insert(near, { distance = distance, triangles = cost(object) })
		end
	end
	table.sort(near, function(a, b)
		return a.distance < b.distance
	end)
	local total = 0
	for k = 1, math.min(#near, Config.lightPoolCap) do
		total += near[k].triangles
	end
	return total
end

local probes: { { name: string, x: number, z: number } } = {}
for _, spawn in layout.spawns do
	table.insert(probes, { name = spawn.id, x = spawn.x, z = spawn.z })
end
table.insert(probes, { name = "plaza", x = 0, z = 0 })
table.insert(probes, { name = "roof_run", x = 168, z = -232 })
table.insert(probes, { name = "glass_tower", x = 120, z = -120 })

local function worst(playerTier: number?): (number, string)
	local server = serverTriangles(playerTier)
	local most, at = 0, ""
	for _, probe in probes do
		local total = server + lightTriangles(probe.x, probe.z, playerTier)
		if total > most then
			most, at = total, probe.name
		end
	end
	return most, at
end

local unculled, unculledAt = worst(nil)
-- The benchmark's player sits at spawn 1 (tests/studio/ParkHeavyScene), so that probe is the measured scene.
local benchmarked = serverTriangles(nil) + lightTriangles(probes[1].x, probes[1].z, nil)
local culledTotal, culledAt = worst(CULL_TIER)

test("ParkCityBudget: every drawn kind has a triangle count", function()
	for _, objectId in serverRows do
		local object = objectById[objectId]
		expect.truthy(object ~= nil, `{objectId} has no object def`)
		if object.assetKey then
			expect.truthy(
				trianglesOf[object.assetKey] ~= nil,
				`{object.assetKey} is not in the manifest`
			)
		end
	end
	print(
		`  Park City triangles ({world.activeThemeId}): unculled {unculled} (worst at {unculledAt}), Tier {CULL_TIER} culled {culledTotal} (worst at {culledAt}); scenery {sceneryTriangles}; {probes[1].name} (benchmarked) {benchmarked}`
	)
	expect.truthy(unculled > 0 and culledTotal <= unculled, "culling never adds triangles")
end)

test("ParkCityBudget: the worst probe stays under the benchmarked ceilings", function()
	local budgets = Config.Budgets :: any
	if budgets.parkCityTrianglesUnculled ~= nil then
		expect.truthy(
			unculled <= budgets.parkCityTrianglesUnculled,
			`unculled {unculled} at {unculledAt} > {budgets.parkCityTrianglesUnculled}`
		)
	end
	if budgets.parkCityTrianglesCulled ~= nil then
		expect.truthy(
			culledTotal <= budgets.parkCityTrianglesCulled,
			`culled {culledTotal} at {culledAt} > {budgets.parkCityTrianglesCulled}`
		)
	end
end)

return {}
