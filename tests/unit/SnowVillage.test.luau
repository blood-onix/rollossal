--!strict
-- Content validation for src/shared/Content/Worlds/SnowVillage.luau (spec FR-004, data-model.md). The ranges
-- below are written out by hand from the spec and the GDD, not read from the data under test.

local fs = require("@lune/fs")

local harness = require("./harness")
local Assets = require("../../src/shared/Assets")
local Config = require("../../src/shared/Config")
local Icons = require("../../src/shared/Content/Icons")
local Hazards = require("../../src/shared/Content/Hazards")
local Layout = require("../../src/shared/Rules/Layout")
local Markers = require("../../src/shared/Rules/Markers")
local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")
local Strings = require("../../src/shared/Localization/Strings")
local Themes = require("../../src/shared/Content/Themes")
local ThemeResolve = require("../../src/shared/Rules/ThemeResolve")

local test, expect = harness.test, harness.expect

local TIER_COUNTS = { 18, 16, 14, 12, 4 }
local SIZE_RANGES = { { 0.3, 1.5 }, { 1.5, 4.0 }, { 4.0, 10.0 }, { 10.0, 25.0 }, { 25.0, 60.0 } }
local COIN_RANGES = { { 1, 2 }, { 3, 5 }, { 8, 15 }, { 20, 40 }, { 60, 100 } }
local MIN_DIAMETERS = { 2, 5, 12, 30, 70 }
local TIER_CEILINGS = { 5, 12, 30, 70, 150 }
local SPAWN_CLUSTER_MIN = 10
local EATABLE_AT_START = 0.8
local TRAVEL_RADIUS = 54
local HUB_PARTS = 3

local objectById: { [string]: typeof(SnowVillage.objects[1]) } = {}
local sizes: { [string]: number } = {}
for _, object in SnowVillage.objects do
	objectById[object.id] = object
	sizes[object.id] = object.size
end
-- The base kit never names the slot ids, but slot zones and fixed placements do. Under the base
-- (winter) look they stand for their mapped object, so expand and reach checks see real sizes
-- (005, research R-11).
for slotId, objectId in SnowVillage.themeBindings.winter.slots do
	sizes[slotId] = sizes[objectId]
end

local placements = Layout.expand(SnowVillage.zones, sizes)
for _, fixed in SnowVillage.fixedPlacements do
	table.insert(placements, fixed)
end

-- Resolved per-theme worlds (005): the slot zones, fixed landmarks and overlays re-mapped per theme.
local resolved: { [string]: ThemeResolve.Resolved } = {}
local resolvedSizes: { [string]: { [string]: number } } = {}
for _, themeId in SnowVillage.supportedThemes do
	local sizeMap = table.clone(sizes)
	for slotId, objectId in SnowVillage.themeBindings[themeId].slots do
		sizeMap[slotId] = sizeMap[objectId]
	end
	for _, object in SnowVillage.themeBindings[themeId].objects or {} do
		sizeMap[object.id] = object.size
	end
	resolvedSizes[themeId] = sizeMap
	resolved[themeId] = ThemeResolve.resolve(
		SnowVillage,
		{ id = themeId, palette = {}, lighting = {} },
		Layout.expand,
		Config.Budgets.defaultMaxPlacements
	)
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
	for _, key in { "pickup", "tierUnlock", "bump", "bell", "musicWinter" } do
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
	local slotKinds = { small = true, medium = true, yard = true, street = true }
	for _, zone in SnowVillage.zones do
		expect.truthy(zone.count <= Layout.capacity(zone, sizes))
		expect.truthy(math.abs(zone.x) + zone.w / 2 <= SnowVillage.halfExtent)
		expect.truthy(math.abs(zone.z) + zone.d / 2 <= SnowVillage.halfExtent)
		for _, item in zone.mix do
			expect.truthy(objectById[item.objectId] ~= nil or ThemeResolve.isSlot(item.objectId))
			if zone.spawnSlot then
				expect.equal(objectById[item.objectId].tier, 1)
			end
		end
		-- 005 R-11: a dressing-slot zone is well-formed — id sv_slot_<kind>_NN, one known slot kind, one placement.
		local kind = string.match(zone.id, "^sv_slot_(%a+)_%d%d$")
		if kind ~= nil then
			expect.truthy(slotKinds[kind] ~= nil)
			expect.truthy(
				ThemeResolve.isSlot(zone.mix[1].objectId)
					and zone.mix[1].objectId == "slot." .. kind
			)
			expect.equal(zone.count, 1)
		end
	end
end)

test("SnowVillage: placement ids are unique and every placement names a known object", function()
	local seen: { [string]: boolean } = {}
	for _, placement in placements do
		expect.falsy(seen[placement.id])
		seen[placement.id] = true
		expect.truthy(
			objectById[placement.objectId] ~= nil or ThemeResolve.isSlot(placement.objectId)
		)
	end
	for _, themeId in SnowVillage.supportedThemes do
		for id in resolved[themeId].slotPlacementIds do
			expect.truthy(
				seen[id] or string.find(id, "sv_landmark", 1, true) == 1,
				`slot placement {id} is unknown to the base layout`
			)
		end
	end
end)

test("SnowVillage: landmarks are Tier 5 objects inside the outer ring", function()
	expect.truthy(#SnowVillage.fixedPlacements >= 4)
	for _, placement in SnowVillage.fixedPlacements do
		if ThemeResolve.isSlot(placement.objectId) then
			-- 005 R-11: two landmark slots placed as fixed placements; the theme maps them.
			expect.truthy(placement.id == "sv_landmark_05" or placement.id == "sv_landmark_06")
			expect.truthy(math.abs(placement.x) <= SnowVillage.outerHalfExtent)
			expect.truthy(math.abs(placement.z) <= SnowVillage.outerHalfExtent)
		else
			expect.equal(objectById[placement.objectId].tier, 5)
			expect.truthy(math.abs(placement.x) <= SnowVillage.outerHalfExtent)
			expect.truthy(math.abs(placement.z) <= SnowVillage.outerHalfExtent)
		end
	end
	for _, object in SnowVillage.objects do
		if object.tier == 5 then
			local found = false
			for _, placement in resolved.winter.placements do
				found = found or placement.objectId == object.id
			end
			expect.truthy(found, `tier 5 object {object.id} is never placed`)
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

test("SnowVillage: footprints stay apart in every supported theme (005)", function()
	for _, themeId in SnowVillage.supportedThemes do
		local themePlacements = resolved[themeId].placements
		local themeSize = resolvedSizes[themeId]
		expect.truthy(
			#themePlacements >= #placements,
			`{themeId} keeps the base placements and adds slots/overlays`
		)
		for i = 1, #themePlacements do
			local a = themePlacements[i]
			local sa = themeSize[a.objectId]
			expect.truthy(sa ~= nil, `{a.id} names unknown {a.objectId} under {themeId}`)
			for j = i + 1, #themePlacements do
				local b = themePlacements[j]
				local reach = (sa + themeSize[b.objectId]) / 2
				local dx, dz = a.x - b.x, a.z - b.z
				if dx * dx + dz * dz < reach * reach - 1e-6 then
					error(`{themeId}: {a.id} and {b.id} overlap`)
				end
			end
		end
	end
end)

test("SnowVillage: 12 spawn points, each with a Tier 1 cluster inside 45 studs", function()
	local points = SnowVillage.spawnPoints
	expect.equal(#points, 12)
	expect.truthy(Config.spawnClusterRadius <= TRAVEL_RADIUS)
	for index, point in points do
		expect.equal(point.slot, index)
		local near = 0
		for _, placement in placements do
			if
				placement.spawnSlot == point.slot
				and sizes[placement.objectId] <= EATABLE_AT_START
			then
				local distance =
					math.sqrt((placement.x - point.x) ^ 2 + (placement.z - point.z) ^ 2)
				if distance <= Config.spawnClusterRadius then
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

test(
	"SnowVillage: the part budget holds for the pool, the geometry, markers, hub and 12 balls",
	function()
		local total = #placements
			+ #SnowVillage.environment.blocks
			+ #SnowVillage.environment.markers
			+ HUB_PARTS
			+ 12
		expect.truthy(total <= Config.Budgets.maxActivePartsPerServer)
		expect.truthy(#SnowVillage.environment.blocks <= 400)
	end
)

test("SnowVillage: the part budget holds with a themed overlay set (005)", function()
	for _, themeId in SnowVillage.supportedThemes do
		local total = #resolved[themeId].placements
			+ #SnowVillage.environment.blocks
			+ #SnowVillage.environment.markers
			+ HUB_PARTS
			+ 12
		expect.truthy(
			total <= Config.Budgets.maxActivePartsPerServer,
			`{themeId}: {total} parts over budget`
		)
	end
end)

test(
	"SnowVillage: 32 dressing slots by kind, two of them in the landmark ring (005, R-11)",
	function()
		local kinds = { small = 0, medium = 0, yard = 0, street = 0 }
		local landmarks = 0
		for _, zone in SnowVillage.zones do
			local kind = string.match(zone.id, "^sv_slot_(%a+)_%d%d$")
			if kind ~= nil then
				kinds[kind] += 1
			end
		end
		for _, placement in SnowVillage.fixedPlacements do
			if placement.objectId == "slot.landmark" then
				landmarks += 1
			end
		end
		expect.equal(kinds.small, 12)
		expect.equal(kinds.medium, 8)
		expect.equal(kinds.yard, 6)
		expect.equal(kinds.street, 4)
		expect.equal(landmarks, 2)
		local slotPlacements = 0
		for _ in resolved.winter.slotPlacementIds do
			slotPlacements += 1
		end
		expect.equal(slotPlacements, 32)
	end
)

test("SnowVillage: dressing slots stay inside the dressing share (005, R-11)", function()
	for _, themeId in SnowVillage.supportedThemes do
		local slotPlacements = 0
		for _ in resolved[themeId].slotPlacementIds do
			slotPlacements += 1
		end
		local share = slotPlacements / #resolved[themeId].placements
		expect.truthy(share <= Config.Budgets.maxDressingSlotShare, `{themeId} slot share {share}`)
	end
end)

test("SnowVillage: winter keeps every non-slot placement today's world has (005, R-11)", function()
	-- Rebuild "today": un-carve the counts the slot zones took from the donor zones. Every winter
	-- placement that is not a slot or overlay must exist in today's pool at the same position.
	local counts: { [string]: number } = {}
	local function spawnNumberOf(zoneId: string): number
		return tonumber(string.sub(zoneId, 4, 5)) or 0
	end
	-- The counts the donor zones used before the 005 slots arrived (research R-11): porch gave up one
	-- per spawn, yard_a one for the first eight spawns, lane_n one for the first six, both bands two.
	local function carvedDelta(zoneId: string): number
		if string.find(zoneId, "_porch", 1, true) then
			return 1
		end
		if string.find(zoneId, "_yard_a", 1, true) and spawnNumberOf(zoneId) <= 8 then
			return 1
		end
		if string.find(zoneId, "_lane_n", 1, true) and spawnNumberOf(zoneId) <= 6 then
			return 1
		end
		if zoneId == "sv_band_n" or zoneId == "sv_band_s" then
			return 2
		end
		return 0
	end
	for _, zone in SnowVillage.zones do
		counts[zone.id] = (zone.count :: number) + carvedDelta(zone.id)
	end
	local todayZones = {}
	for _, zone in SnowVillage.zones do
		local copy = table.clone(zone)
		if counts[zone.id] ~= zone.count then
			copy.count = counts[zone.id]
		end
		table.insert(todayZones, copy)
	end
	local todayPlacements = Layout.expand(todayZones, sizes)
	for _, fixed in SnowVillage.fixedPlacements do
		table.insert(todayPlacements, fixed)
	end
	local todayById: { [string]: typeof(todayPlacements[1]) } = {}
	for _, placement in todayPlacements do
		todayById[placement.id] = placement
	end
	local compared, kept = 0, 0
	for _, placement in resolved.winter.placements do
		local isSlot = resolved.winter.slotPlacementIds[placement.id] ~= nil
			or ThemeResolve.isSlot(placement.objectId)
			or string.find(placement.id, "sv_ol_", 1, true) == 1
		if not isSlot then
			compared += 1
			local original = todayById[placement.id]
			expect.truthy(original ~= nil, `winter placement {placement.id} is new since today`)
			if original ~= nil then
				expect.equal(placement.x, original.x)
				expect.equal(placement.z, original.z)
				expect.equal(placement.objectId, original.objectId)
				kept += 1
			end
		end
	end
	-- today minus carved counts = winter's non-slot pool (with the slot counts given back)
	expect.equal(kept, compared)
	expect.truthy(compared >= 1578, `expected at least 1578 kept placements, got {compared}`)
end)

test("SnowVillage: overlays sit clear of the keep-out areas (005, R-10, T066)", function()
	local counts: { [string]: number } = { sightline = 0, marker = 0, gate = 0, shortcut = 0 }
	for _, keepOut in SnowVillage.keepOutAreas do
		counts[keepOut.kind] += 1
		expect.truthy(keepOut.w > 0 and keepOut.d > 0)
		if keepOut.kind == "sightline" then
			expect.truthy(keepOut.w <= 12 or keepOut.d <= 12)
		end
	end
	expect.equal(counts.sightline, 4)
	-- One per marker, plus one per sweeper path segment in place of the sweeper's own (006, D3): 16 + 2 * 4 - 2.
	expect.equal(counts.marker, 22)
	expect.equal(counts.gate, 24)
	expect.equal(counts.shortcut, 6)
	for _, themeId in SnowVillage.supportedThemes do
		for _, zone in SnowVillage.themeBindings[themeId].overlays.zones do
			local x0, x1 = zone.x - zone.w / 2, zone.x + zone.w / 2
			local z0, z1 = zone.z - zone.d / 2, zone.z + zone.d / 2
			for _, keepOut in SnowVillage.keepOutAreas do
				local ox0, ox1 = keepOut.x - keepOut.w / 2, keepOut.x + keepOut.w / 2
				local oz0, oz1 = keepOut.z - keepOut.d / 2, keepOut.z + keepOut.d / 2
				local intersects = x1 > ox0 and x0 < ox1 and z1 > oz0 and z0 < oz1
				expect.falsy(intersects, `{zone.id} intersects keep-out {keepOut.id}`)
			end
		end
		for _, fixed in SnowVillage.themeBindings[themeId].overlays.fixedPlacements do
			local half = resolvedSizes[themeId][fixed.objectId] / 2
			for _, keepOut in SnowVillage.keepOutAreas do
				local hit = math.abs(fixed.x - keepOut.x) < half + keepOut.w / 2
					and math.abs(fixed.z - keepOut.z) < half + keepOut.d / 2
				expect.falsy(
					hit,
					`{themeId}: fixed placement {fixed.id} sits in keep-out {keepOut.id}`
				)
			end
		end
	end
end)

test(
	"SnowVillage: no placement lands on a gate or in a shortcut alley in any theme (005, T060)",
	function()
		for _, themeId in SnowVillage.supportedThemes do
			local themeSize = resolvedSizes[themeId]
			for _, placement in resolved[themeId].placements do
				local half = themeSize[placement.objectId] / 2
				for _, keepOut in SnowVillage.keepOutAreas do
					if keepOut.kind == "gate" or keepOut.kind == "shortcut" then
						local hit = math.abs(placement.x - keepOut.x) < half + keepOut.w / 2
							and math.abs(placement.z - keepOut.z) < half + keepOut.d / 2
						expect.falsy(
							hit,
							`{themeId}: {placement.id} sits in {keepOut.kind} {keepOut.id}`
						)
					end
				end
			end
		end
	end
)

test(
	"SnowVillage: each gate is a porch ramp and each shortcut alley is 4 studs across (005, T060)",
	function()
		for _, keepOut in SnowVillage.keepOutAreas do
			if keepOut.kind == "gate" then
				expect.equal(keepOut.w, 14)
				expect.equal(keepOut.d, 10)
				local porches = 0
				for _, point in SnowVillage.spawnPoints do
					if math.abs(keepOut.x - point.x) == 18 and keepOut.z == point.z then
						porches += 1
					end
				end
				expect.equal(porches, 1, `gate {keepOut.id} is not a porch ramp`)
			elseif keepOut.kind == "shortcut" then
				expect.equal(math.min(keepOut.w, keepOut.d), 4)
			end
		end
	end
)

test("SnowVillage: the city overlay's fixed beach towel is inside the level (005, T066)", function()
	local fixed = SnowVillage.themeBindings.city.overlays.fixedPlacements
	expect.equal(#fixed, 2)
	local placement = fixed[1]
	expect.equal(placement.objectId, "beach_towel")
	expect.truthy(math.abs(placement.x) <= SnowVillage.halfExtent)
	expect.truthy(math.abs(placement.z) <= SnowVillage.halfExtent)
	local owned = false
	for _, object in SnowVillage.themeBindings.city.objects or {} do
		owned = owned or object.id == placement.objectId
	end
	expect.truthy(
		owned,
		`{placement.id} names {placement.objectId}, which the city binding does not define`
	)
end)

test(
	"SnowVillage: hero variants drift at most 10 percent and copy the base object (005)",
	function()
		for _, themeId in SnowVillage.supportedThemes do
			local binding = SnowVillage.themeBindings[themeId]
			for baseId, variant in binding.heroVariants or {} do
				local base = objectById[baseId]
				expect.truthy(base ~= nil, `hero variant base {baseId} is unknown`)
				if base then
					if variant.size ~= nil then
						local drift = math.abs(variant.size :: number - base.size) / base.size
						expect.truthy(
							drift <= 0.1 + 1e-6,
							`{themeId} hero variant for {baseId} drifts {drift}`
						)
					end
					-- The variant must name art the game has: an asset key or an existing mesh key.
					if variant.assetKey ~= nil then
						expect.truthy(Assets.meshes[variant.assetKey] ~= nil)
					end
					if variant.nameKey ~= nil then
						expectBothLanguages(variant.nameKey :: string)
					end
				end
			end
		end
		-- The resolution keeps the hero variant declared sizes art-only: resolved placements still use the
		-- base sizes, so the reach matrix above covers them.
		for _, placement in resolved.city.placements do
			if placement.id == "sv_landmark_05" or placement.id == "sv_landmark_06" then
				expect.equal(placement.objectId, "giant_duck")
			end
		end
	end
)

test("SnowVillage: theme-only stand-ins stay inside their tier ranges (005)", function()
	for _, themeId in SnowVillage.supportedThemes do
		for _, object in SnowVillage.themeBindings[themeId].objects or {} do
			local range = SIZE_RANGES[object.tier]
			expect.truthy(range ~= nil, `{object.id}: tier {object.tier} out of range`)
			if range then
				expect.truthy(
					object.size >= range[1] and object.size <= range[2],
					`{themeId}/{object.id} size {object.size} outside tier {object.tier}`
				)
			end
			local coinRange = COIN_RANGES[object.tier]
			expect.truthy(coinRange ~= nil)
			if coinRange then
				expect.truthy(
					object.coins >= coinRange[1] and object.coins <= coinRange[2],
					`{themeId}/{object.id} coins {object.coins} outside tier {object.tier}`
				)
			end
			expect.equal(object.bookId, "snow_village." .. object.id)
			expectBothLanguages(object.nameKey)
			expect.truthy(Icons[object.icon] ~= nil)
			expect.truthy(
				object.role ~= nil and string.sub(object.role :: string, 1, 2) == "w-",
				`{themeId}/{object.id} role must be a world role`
			)
		end
	end
	-- The winter binding adds a book page of its own per contract §5; city lists its six objects.
	for _, themeId in SnowVillage.supportedThemes do
		local page = SnowVillage.themeBindings[themeId].bookPage
		expect.truthy(page ~= nil)
		if page then
			expectBothLanguages(page.nameKey)
			expectBothLanguages(page.returningKey)
			for _, objectId in page.objectIds do
				local found = false
				for _, object in SnowVillage.themeBindings[themeId].objects or {} do
					found = found or object.id == objectId
				end
				expect.truthy(found, `book page {page.id} names unknown object {objectId}`)
			end
		end
	end
end)

test("SnowVillage: no theme book page declares a reward before 006a (005 F4)", function()
	for _, themeId in SnowVillage.supportedThemes do
		local page = SnowVillage.themeBindings[themeId].bookPage
		expect.equal(
			page ~= nil and page.reward ~= nil,
			false,
			`{themeId} bookPage declares a reward`
		)
	end
end)

test("SnowVillage: resolving every supported theme succeeds and keeps its shape (005)", function()
	-- The city overlay adds a fixed beach towel (T066) and a fixed skating rink (T040) on top of the
	-- 1616 winter placements.
	local expectedPlacements: { [string]: number } = { winter = 1616, city = 1618 }
	for _, themeId in SnowVillage.supportedThemes do
		local themeResolved = resolved[themeId]
		expect.equal(#themeResolved.placements, expectedPlacements[themeId])
		local slotCount = 0
		for _ in themeResolved.slotPlacementIds do
			slotCount += 1
		end
		expect.equal(slotCount, 32)
		-- Non-slot placements keep their ids across themes; slots and overlays re-name per theme.
		for _, placement in themeResolved.placements do
			if placement.id == "sv_landmark_05" or placement.id == "sv_landmark_06" then
				expect.equal(
					placement.objectId,
					themeId == "winter" and "skating_rink" or "giant_duck"
				)
			end
		end
	end
	-- One overlay zone per theme, each with a fixed amount of glow-path placements.
	for _, themeId in SnowVillage.supportedThemes do
		expect.equal(#SnowVillage.themeBindings[themeId].overlays.zones, 1)
	end
	local overlayPlacements = {}
	for _, placement in resolved.winter.placements do
		if string.find(placement.id, "sv_ol_", 1, true) == 1 then
			overlayPlacements[placement.objectId] = (overlayPlacements[placement.objectId] or 0) + 1
		end
	end
	expect.equal(overlayPlacements.winter_lights, 6)
end)

test(
	"SnowVillage: every theme places every base object, so tier pages reach 100% (005, T040)",
	function()
		for _, themeId in SnowVillage.supportedThemes do
			local placed: { [string]: boolean } = {}
			for _, placement in resolved[themeId].placements do
				placed[placement.objectId] = true
			end
			for _, object in SnowVillage.objects do
				expect.truthy(placed[object.id], `{themeId} never places base object {object.id}`)
			end
		end
	end
)

test("SnowVillage: every theme stays inside the 1700 placement budget (005, FR-002)", function()
	expect.equal(SnowVillage.maxPlacements, 1700)
	for _, themeId in SnowVillage.supportedThemes do
		local count = #resolved[themeId].placements
		expect.truthy(count <= 1700, `{themeId} resolves {count} placements, over 1700`)
	end
end)

test("SnowVillage: every block swatch exists and every marker kind has at least 6 spots", function()
	local environment = SnowVillage.environment
	for _, block in environment.blocks do
		for _, themeId in SnowVillage.supportedThemes do
			local inBase = environment.palette[block.swatch] ~= nil
			local inTheme = Themes[themeId].palette[block.swatch] ~= nil
			expect.truthy(inBase or inTheme)
		end
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

-- 006 markers (spec FR-009, research R-05 and R-14).
local GRAVITY = 196.2
local ROOF_TOP = 11
local ROOF_HALF = 12
local TRAIL_PATCHES = 48
local SWEEPER_PARTS = 2
local BUMPER_PARTS = 2

local function markerDefs(): Markers.Defs
	return Hazards :: any
end

test("SnowVillage: the 16 markers pass Markers.validate for the world and both themes", function()
	local environment = SnowVillage.environment
	for _, themeId in SnowVillage.supportedThemes do
		expect.truthy(SnowVillage.themeBindings[themeId] ~= nil)
		local errors = Markers.validate(
			environment.markers,
			environment.blocks,
			SnowVillage.keepOutAreas,
			SnowVillage.halfExtent,
			markerDefs()
		)
		expect.equal(#errors, 0, table.concat(errors, " | "))
	end
end)

test("SnowVillage: 8 BoosterSpot and 8 TrapSpot cover all nine sub-kinds", function()
	local kinds: { [string]: number } = {}
	local subKinds: { [string]: number } = {}
	for _, marker in SnowVillage.environment.markers do
		kinds[marker.kind] = (kinds[marker.kind] or 0) + 1
		subKinds[marker.subKind] = (subKinds[marker.subKind] or 0) + 1
	end
	expect.equal(kinds.BoosterSpot, 8)
	expect.equal(kinds.TrapSpot, 8)
	local expected: { [string]: number } = {
		dash = 2,
		magnet = 2,
		spring = 2,
		shield = 1,
		slick_trail = 1,
		slick = 2,
		bumper = 2,
		slow = 2,
		sweeper = 2,
	}
	for subKind, count in expected do
		expect.equal(subKinds[subKind], count, subKind)
	end
end)

test("SnowVillage: the keep-out footprints match the Hazards rows", function()
	local footprints: { [string]: { w: number, d: number } } = {}
	for _, row in Hazards.boosters do
		footprints[row.subKind] = row.footprint
	end
	for _, row in Hazards.traps do
		footprints[row.subKind] = row.footprint
	end
	-- A single-marker keep-out has its row's footprint exactly.
	for _, marker in SnowVillage.environment.markers do
		if marker.waypoints == nil then
			local found = false
			for _, keepOut in SnowVillage.keepOutAreas do
				if keepOut.kind == "marker" and keepOut.x == marker.x and keepOut.z == marker.z then
					expect.equal(keepOut.w, footprints[marker.subKind].w, marker.id)
					expect.equal(keepOut.d, footprints[marker.subKind].d, marker.id)
					found = true
				end
			end
			expect.truthy(found)
		end
	end
	-- Sweeper segments are grown by half the sweeper's long side: 5 studs each way.
	expect.equal(footprints.sweeper.w, 10)
end)

test("SnowVillage: markers and sweeper loops stay off every gate and shortcut", function()
	local function overlap(a: Markers.Rect, b: Markers.Rect): boolean
		return math.abs(a.x - b.x) < a.hx + b.hx and math.abs(a.z - b.z) < a.hz + b.hz
	end
	local routes: { Markers.Rect } = {}
	for _, keepOut in SnowVillage.keepOutAreas do
		if keepOut.kind == "gate" or keepOut.kind == "shortcut" then
			table.insert(
				routes,
				{ x = keepOut.x, z = keepOut.z, hx = keepOut.w / 2, hz = keepOut.d / 2 }
			)
		end
	end
	for _, keepOut in SnowVillage.keepOutAreas do
		if keepOut.kind == "marker" then
			local rect = { x = keepOut.x, z = keepOut.z, hx = keepOut.w / 2, hz = keepOut.d / 2 }
			for _, route in routes do
				expect.falsy(overlap(rect, route), keepOut.id)
			end
		end
	end
end)

test(
	"SnowVillage: the part budget holds with 16 markers, 48 trail patches and the hazard parts",
	function()
		for _, themeId in SnowVillage.supportedThemes do
			local total = #resolved[themeId].placements
				+ #SnowVillage.environment.blocks
				+ #SnowVillage.environment.markers
				+ TRAIL_PATCHES
				+ SWEEPER_PARTS
				+ BUMPER_PARTS
				+ HUB_PARTS
				+ 12
			expect.truthy(total < 2000, `{themeId}: {total} parts`)
			expect.truthy(total <= Config.Budgets.maxActivePartsPerServer)
		end
	end
)

test("SnowVillage: each spring pad faces a roof and a launch lands on it", function()
	local roofs = { -100, 100 }
	local pads = 0
	for _, marker in SnowVillage.environment.markers do
		if marker.subKind ~= "spring" then
			continue
		end
		pads += 1
		-- Facing is local +Z: (sin yaw, cos yaw).
		local facingZ = math.cos(math.rad(marker.yaw))
		local roofZ = if marker.z < 0 then roofs[1] else roofs[2]
		expect.truthy(facingZ * (roofZ - marker.z) > 0, marker.id)
		expect.near(marker.x, 0, 1e-9)
		-- Hand-computed (R-05): apex 70^2 / (2 * 196.2) = 12.49 studs.
		local apex = Config.springVerticalSpeed ^ 2 / (2 * GRAVITY)
		expect.truthy(apex >= 12)
		-- The ball's bottom comes back down through the roof top at the larger root of vy*t - g*t^2/2 = 11.
		local vy = Config.springVerticalSpeed
		local landing = (vy + math.sqrt(vy * vy - 2 * GRAVITY * ROOF_TOP)) / GRAVITY
		local travelled = Config.springForwardSpeed * landing
		local landZ = marker.z + facingZ * travelled
		expect.truthy(math.abs(landZ - roofZ) < ROOF_HALF, `{marker.id} lands at z {landZ}`)
		-- At the roof edge it is already above the roof top.
		local edgeDistance = math.abs(roofZ - marker.z) - ROOF_HALF
		local t = edgeDistance / Config.springForwardSpeed
		expect.truthy(vy * t - GRAVITY * t * t / 2 > ROOF_TOP)
	end
	expect.equal(pads, 2)
end)

return {}
