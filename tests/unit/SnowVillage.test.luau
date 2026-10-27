--!strict
-- Content validation for src/shared/Content/Worlds/SnowVillage.luau (spec FR-004, data-model.md). The ranges
-- below are written out by hand from the spec and the GDD, not read from the data under test.

local fs = require("@lune/fs")

local harness = require("./harness")
local Assets = require("../../src/shared/Assets")
local Config = require("../../src/shared/Config")
local Icons = require("../../src/shared/Content/Icons")
local Layout = require("../../src/shared/Rules/Layout")
local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")
local Strings = require("../../src/shared/Localization/Strings")

local test, expect = harness.test, harness.expect

local TIER_COUNTS = { 18, 16, 14, 12, 4 }
local SIZE_RANGES = { { 0.3, 1.5 }, { 1.5, 4.0 }, { 4.0, 10.0 }, { 10.0, 25.0 }, { 25.0, 60.0 } }
local COIN_RANGES = { { 1, 2 }, { 3, 5 }, { 8, 15 }, { 20, 40 }, { 60, 100 } }
local MIN_DIAMETERS = { 2, 5, 12, 30, 70 }
local TIER_CEILINGS = { 5, 12, 30, 70, 150 }
local SPAWN_CLUSTER_MIN = 10
local EATABLE_AT_START = 0.8
local TRAVEL_RADIUS = 54

local objectById: { [string]: typeof(SnowVillage.objects[1]) } = {}
local sizes: { [string]: number } = {}
for _, object in SnowVillage.objects do
	objectById[object.id] = object
	sizes[object.id] = object.size
end

local placements = Layout.expand(SnowVillage.zones, sizes)
for _, fixed in SnowVillage.fixedPlacements do
	table.insert(placements, fixed)
end

local function entry(key: string): { en: string, es: string? }?
	return (Strings :: { [string]: { en: string, es: string? } })[key]
end

local function expectBothLanguages(key: string)
	local text = entry(key)
	expect.truthy(text ~= nil)
	expect.truthy(text ~= nil and text.en ~= "")
	expect.truthy(text ~= nil and text.es ~= nil and text.es ~= "")
end

test("SnowVillage: identity, star targets and extents", function()
	expect.equal(SnowVillage.worldId, "snow_village")
	expect.equal(#SnowVillage.starThresholds, 3)
	expect.equal(SnowVillage.starThresholds[1], 20)
	expect.equal(SnowVillage.starThresholds[2], 45)
	expect.equal(SnowVillage.starThresholds[3], 80)
	expect.equal(SnowVillage.halfExtent, 300)
	expect.equal(SnowVillage.outerHalfExtent, 400)
end)

test("SnowVillage: the provisional growthK is positive and flagged for the owner", function()
	expect.truthy(SnowVillage.growthK > 0)
end)

test("SnowVillage: 64 objects, 18 / 16 / 14 / 12 / 4 per tier", function()
	expect.equal(#SnowVillage.objects, 64)
	for tier, expected in TIER_COUNTS do
		local count = 0
		for _, object in SnowVillage.objects do
			if object.tier == tier then
				count += 1
			end
		end
		expect.equal(count, expected)
	end
end)

test("SnowVillage: ids and book ids are unique and follow the naming rule", function()
	local ids: { [string]: boolean } = {}
	local books: { [string]: boolean } = {}
	for _, object in SnowVillage.objects do
		expect.falsy(ids[object.id])
		expect.falsy(books[object.bookId])
		ids[object.id] = true
		books[object.bookId] = true
		expect.equal(object.bookId, "snow_village." .. object.id)
		expect.equal(object.nameKey, "object.snow_village." .. object.id)
		expect.equal(object.assetKey, object.id)
	end
end)

test("SnowVillage: size tiers chain from 2 to 70 and the top tier is open", function()
	local tiers = SnowVillage.sizeTiers
	expect.equal(#tiers, 5)
	for index, tier in tiers do
		expect.equal(tier.tier, index)
		expect.equal(tier.minDiameter, MIN_DIAMETERS[index])
		if index < #tiers then
			expect.equal(tier.maxDiameter, tiers[index + 1].minDiameter)
		else
			expect.equal(tier.maxDiameter, nil)
		end
	end
end)

test(
	"SnowVillage: object sizes sit in their tier range and are absorbable inside the tier",
	function()
		for _, object in SnowVillage.objects do
			local range = SIZE_RANGES[object.tier]
			expect.truthy(object.size >= range[1])
			expect.truthy(object.size <= range[2])
			expect.truthy(object.size <= Config.absorbRatio * TIER_CEILINGS[object.tier])
		end
	end
)

test("SnowVillage: coins are whole numbers inside the tier range and the ranges ascend", function()
	for _, object in SnowVillage.objects do
		local range = COIN_RANGES[object.tier]
		expect.equal(object.coins, math.floor(object.coins))
		expect.truthy(object.coins >= range[1])
		expect.truthy(object.coins <= range[2])
	end
	for tier = 2, 5 do
		expect.truthy(COIN_RANGES[tier][1] > COIN_RANGES[tier - 1][2])
	end
	expect.equal(objectById.gumdrop.coins, 1)
	expect.equal(objectById.cocoa_mug.coins, 2)
	expect.equal(objectById.cottage.coins, 60)
	expect.equal(objectById.clock_tower.coins, 100)
end)

test("SnowVillage: every asset key, the hub key and the music resolve in Assets", function()
	local used: { [string]: boolean } = {}
	for _, object in SnowVillage.objects do
		expect.truthy(Assets.meshes[object.assetKey :: string] ~= nil)
		used[object.assetKey :: string] = true
	end
	local hubKey = SnowVillage.hub.assetKey :: string
	expect.truthy(Assets.meshes[hubKey] ~= nil)
	used[hubKey] = true
	for key in Assets.meshes do
		expect.truthy(used[key])
	end
end)

test("SnowVillage: every audio key the client plays exists in Assets.sounds", function()
	local sounds = Assets.sounds :: { [string]: string }
	for _, key in { "pickup", "tierUnlock", "bump", "bell", "music" } do
		expect.truthy(type(sounds[key]) == "string", `sound {key} missing`)
	end
	for _, key in { "pickup", "tierUnlock", "bump", "bell" } do
		expect.truthy(sounds[key] ~= "", `sound {key} is empty`)
	end
	local feedback = fs.readFile("src/client/Feedback.luau")
	for key in string.gmatch(feedback, "Assets%.sounds%.(%w+)") do
		expect.truthy(sounds[key] ~= nil, `Feedback plays Assets.sounds.{key}, not in Assets.luau`)
	end
end)

test("SnowVillage: every name, headline and reward key has English and Spanish text", function()
	for _, object in SnowVillage.objects do
		expectBothLanguages(object.nameKey)
		expect.truthy(Icons[object.icon] ~= nil)
	end
	for _, tier in SnowVillage.sizeTiers do
		expectBothLanguages(tier.nameKey)
		expectBothLanguages(tier.headlineKey)
		expect.truthy(Icons[tier.headlineIcon] ~= nil)
		local reward = tier.reward
		expect.truthy(reward ~= nil)
		if reward then
			expectBothLanguages(reward.nameKey)
			expect.truthy(reward.rewardType == "skin" or reward.rewardType == "trail")
		end
	end
end)

test("SnowVillage: reward ids are unique", function()
	local seen: { [string]: boolean } = {}
	for _, tier in SnowVillage.sizeTiers do
		local reward = tier.reward
		expect.truthy(reward ~= nil)
		if reward then
			expect.falsy(seen[reward.rewardId])
			seen[reward.rewardId] = true
		end
	end
end)

test("SnowVillage: zones fit their cells, name known objects and stay inside the town", function()
	for _, zone in SnowVillage.zones do
		expect.truthy(zone.count <= Layout.capacity(zone, sizes))
		expect.truthy(math.abs(zone.x) + zone.w / 2 <= SnowVillage.halfExtent)
		expect.truthy(math.abs(zone.z) + zone.d / 2 <= SnowVillage.halfExtent)
		for _, item in zone.mix do
			expect.truthy(objectById[item.objectId] ~= nil)
			if zone.spawnSlot then
				expect.equal(objectById[item.objectId].tier, 1)
			end
		end
	end
end)

test("SnowVillage: placement ids are unique and every placement names a known object", function()
	local seen: { [string]: boolean } = {}
	for _, placement in placements do
		expect.falsy(seen[placement.id])
		seen[placement.id] = true
		expect.truthy(objectById[placement.objectId] ~= nil)
	end
end)

test("SnowVillage: landmarks are Tier 5 objects inside the outer ring", function()
	expect.truthy(#SnowVillage.fixedPlacements >= 4)
	for _, placement in SnowVillage.fixedPlacements do
		expect.equal(objectById[placement.objectId].tier, 5)
		expect.truthy(math.abs(placement.x) <= SnowVillage.outerHalfExtent)
		expect.truthy(math.abs(placement.z) <= SnowVillage.outerHalfExtent)
	end
	for _, object in SnowVillage.objects do
		if object.tier == 5 then
			local found = false
			for _, placement in SnowVillage.fixedPlacements do
				found = found or placement.objectId == object.id
			end
			expect.truthy(found)
		end
	end
end)

test("SnowVillage: no two footprints overlap", function()
	for i = 1, #placements do
		local a = placements[i]
		for j = i + 1, #placements do
			local b = placements[j]
			local reach = (sizes[a.objectId] + sizes[b.objectId]) / 2
			local dx, dz = a.x - b.x, a.z - b.z
			if dx * dx + dz * dz < reach * reach - 1e-6 then
				error(`{a.id} and {b.id} overlap`)
			end
		end
	end
end)

test("SnowVillage: 12 spawn points, each with a Tier 1 cluster inside 45 studs", function()
	local points = SnowVillage.spawnPoints
	expect.equal(#points, 12)
	for index, point in points do
		expect.equal(point.slot, index)
		local near = 0
		for _, placement in placements do
			if placement.spawnSlot == point.slot then
				local distance =
					math.sqrt((placement.x - point.x) ^ 2 + (placement.z - point.z) ^ 2)
				if
					sizes[placement.objectId] <= EATABLE_AT_START
					and distance <= Config.spawnClusterRadius
				then
					expect.truthy(distance <= TRAVEL_RADIUS)
					near += 1
				end
			end
		end
		expect.truthy(near >= SPAWN_CLUSTER_MIN)
	end
end)

test("SnowVillage: spawn points sit 80 to 120 studs from their nearest neighbour", function()
	for _, point in SnowVillage.spawnPoints do
		local nearest = math.huge
		for _, other in SnowVillage.spawnPoints do
			if other.slot ~= point.slot then
				nearest =
					math.min(nearest, math.sqrt((point.x - other.x) ^ 2 + (point.z - other.z) ^ 2))
			end
		end
		expect.truthy(nearest >= 80)
		expect.truthy(nearest <= 120)
	end
end)

test("SnowVillage: the part budget holds for the pool, the geometry and 12 balls", function()
	local total = #placements + #SnowVillage.environment.blocks + 12
	expect.truthy(total <= Config.Budgets.maxActivePartsPerServer)
	expect.truthy(#SnowVillage.environment.blocks <= 400)
end)

test("SnowVillage: every block swatch exists and every marker kind has at least 6 spots", function()
	local environment = SnowVillage.environment
	for _, block in environment.blocks do
		expect.truthy(environment.palette[block.swatch] ~= nil)
		expect.truthy(block.kind == "Block" or block.kind == "Wedge" or block.kind == "Cylinder")
	end
	local booster, trap = 0, 0
	for _, marker in environment.markers do
		if marker.kind == "BoosterSpot" then
			booster += 1
		elseif marker.kind == "TrapSpot" then
			trap += 1
		end
	end
	expect.truthy(booster >= 6)
	expect.truthy(trap >= 6)
end)

test(
	"SnowVillage: a wedge and a kerb of height 1 to 2 lie within 60 studs of every spawn",
	function()
		for _, point in SnowVillage.spawnPoints do
			local wedge, kerb = false, false
			for _, block in SnowVillage.environment.blocks do
				local distance =
					math.sqrt((block.cframe.x - point.x) ^ 2 + (block.cframe.z - point.z) ^ 2)
				if distance <= 60 then
					wedge = wedge or block.kind == "Wedge"
					kerb = kerb
						or (
							string.find(block.id, "kerb", 1, true) ~= nil
							and block.size.y >= 1
							and block.size.y <= 2
						)
				end
			end
			expect.truthy(wedge)
			expect.truthy(kerb)
		end
	end
)

test("SnowVillage: the hub sits outside the landmark ring", function()
	local hub = SnowVillage.hub
	expect.equal(hub.center.x, -460)
	expect.equal(hub.center.z, 0)
	expect.truthy(math.abs(hub.center.x) - hub.halfExtent > SnowVillage.outerHalfExtent)
	expect.truthy(hub.padRadius > 0)
end)

test("SnowVillage: lighting values are sane", function()
	local lighting = SnowVillage.lighting
	expect.truthy(lighting.fogEnd > lighting.fogStart)
	expect.truthy(lighting.clockTime >= 0 and lighting.clockTime <= 24)
	expect.truthy(lighting.brightness > 0)
	expect.truthy(lighting.atmosphereDensity >= 0 and lighting.atmosphereDensity <= 1)
	for _, colour in { lighting.ambient, lighting.outdoorAmbient, lighting.fogColor } do
		expect.equal(#colour, 3)
	end
end)

return {}
