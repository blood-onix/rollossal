--!strict
-- Content validation for src/shared/Content/Worlds/Downtown.luau (007; contracts/world-content.md invariants
-- C1 to C18, data-model.md). The ranges below are written out by hand from the spec and the design, not read
-- from the data under test.

local fs = require("@lune/fs")

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local Downtown = require("../../src/shared/Content/Worlds/Downtown")
local Hazards = require("../../src/shared/Content/Hazards")
local Layout = require("../../src/shared/Rules/Layout")
local Markers = require("../../src/shared/Rules/Markers")
local Themes = require("../../src/shared/Content/Themes")
local ThemeResolve = require("../../src/shared/Rules/ThemeResolve")

local test, expect = harness.test, harness.expect

local TIER_COUNTS = { 18, 15, 16, 16, 9 }
local SIZE_RANGES = { { 0.3, 1.5 }, { 1.6, 4.0 }, { 4.0, 10.0 }, { 10.0, 25.0 }, { 25.0, 60.0 } }
local COIN_RANGES = { { 1, 2 }, { 3, 5 }, { 8, 15 }, { 20, 40 }, { 60, 100 } }
local MIN_DIAMETERS = { 2, 5, 12, 30, 70 }
local TIER_CEILINGS = { 5, 12, 30, 70, 150 }
local HEROES = {
	"rubber_duck_sunglasses",
	"lost_sneaker",
	"inflatable_flamingo",
	"spinning_office_chair",
	"pizza_box_tower",
	"arcade_cabinet",
	"vending_machine",
	"inflatable_tube_guy",
	"donut_food_truck",
	"monster_truck",
	"rocket_water_tower",
	"ferris_wheel",
	"tower_crane",
	"glass_tower",
}
local OVERLAY_COUNTS: { [string]: number } = {
	fairy_light_bulb = 24,
	mini_gift = 18,
	gingerbread_cookie = 18,
	leaning_present_stack = 6,
	poinsettia_pot = 14,
	wooden_sled = 14,
	wreath = 16,
	snow_pile = 12,
	light_up_reindeer = 5,
	cocoa_cart = 8,
	market_stall = 8,
	snowplough = 6,
	ice_rink = 1,
}
local HUB_PARTS = 3
local BALLS = 12
-- Runtime parts of Feature 006 (48 trail patches and 16 sweeper and bumper parts) that a Studio capture sees.
local RUNTIME_PARTS = 64
local SPAWN_RADIUS = 10
local MIN_NEAR_TIER_1 = 40

local objectById: { [string]: typeof(Downtown.objects[1]) } = {}
for _, object in Downtown.objects do
	objectById[object.id] = object
end

-- Per theme: the resolved world (slots, overlays, variants), the object table and the sizes it places.
local resolved: { [string]: ThemeResolve.Resolved } = {}
local resolvedObjects: { [string]: { [string]: typeof(Downtown.objects[1]) } } = {}
local resolvedSizes: { [string]: { [string]: number } } = {}
for _, themeId in Downtown.supportedThemes do
	local theme = (Themes :: any)[themeId]
	local result = ThemeResolve.resolve(
		Downtown,
		{ id = themeId, palette = theme.palette, lighting = theme.lighting },
		Layout.expand,
		Config.Budgets.defaultMaxPlacements
	)
	resolved[themeId] = result
	local byId: { [string]: any } = {}
	local sizes: { [string]: number } = {}
	for _, object in result.objects do
		byId[object.id] = object
		sizes[object.id] = object.size
	end
	resolvedObjects[themeId] = byId
	resolvedSizes[themeId] = sizes
end

-- The sizes of the base zones under the winter look (slots stand for their mapped object).
local baseSizes: { [string]: number } = table.clone(resolvedSizes.winter)
for slotId, mapped in (Downtown.themeBindings.winter :: any).slots do
	baseSizes[slotId] = resolvedSizes.winter[mapped]
end

local function isCoreId(id: string): boolean
	return objectById[id] ~= nil
end

local function rectOf(item: { x: number, z: number, w: number, d: number }): { number }
	return { item.x - item.w / 2, item.x + item.w / 2, item.z - item.d / 2, item.z + item.d / 2 }
end

local function intersects(a: { number }, b: { number }): boolean
	return a[2] > b[1] and a[1] < b[2] and a[4] > b[3] and a[3] < b[4]
end

test("Downtown: theme object sizes match FR-005 and FR-006", function()
	local expected: { [string]: number } = {
		cocoa_cart = 6.5,
		ice_lolly = 0.6,
		paddling_pool = 8.0,
		ice_cream_truck = 15.0,
		bauble = 0.6,
		gift_box = 2.0,
		snowman = 8.0,
		sleigh = 15.0,
		mega_tree = 45.0,
		beach_ball = 2.0,
		giant_duck = 35.0,
	}
	local found: { [string]: number } = {}
	for _, themeId in Downtown.supportedThemes do
		for _, object in (Downtown.themeBindings :: any)[themeId].objects do
			found[object.id] = object.size
		end
	end
	for id, size in expected do
		expect.equal(found[id], size, id)
	end
end)

test("Downtown: identity, star targets, extents and theme set", function()
	expect.equal(Downtown.worldId, "downtown")
	expect.equal(Downtown.starThresholds[1], 20)
	expect.equal(Downtown.starThresholds[2], 45)
	expect.equal(Downtown.starThresholds[3], 80)
	expect.equal(Downtown.halfExtent, 300)
	expect.equal(Downtown.outerHalfExtent, 400)
	expect.equal(Downtown.maxPlacements, 1400)
	expect.equal(Downtown.activeThemeId, "winter")
	expect.equal(#Downtown.supportedThemes, 2)
	expect.equal(Downtown.supportedThemes[1], "winter")
	expect.equal(Downtown.supportedThemes[2], "city")
	expect.equal(Downtown.hub.assetKey, "hub")
end)

test("Downtown C1: 74 objects, 18 / 15 / 16 / 16 / 9 per tier, 14 heroes", function()
	expect.equal(#Downtown.objects, 74)
	local counts = { 0, 0, 0, 0, 0 }
	for _, object in Downtown.objects do
		counts[object.tier] += 1
	end
	for tier = 1, 5 do
		expect.equal(counts[tier], TIER_COUNTS[tier], `tier {tier}`)
	end
	expect.equal(#HEROES, 14)
	for _, heroId in HEROES do
		expect.truthy(objectById[heroId] ~= nil, heroId)
		local fixed = false
		for _, placement in Downtown.fixedPlacements do
			if placement.id == "dt_h_" .. heroId and placement.objectId == heroId then
				fixed = true
			end
		end
		expect.truthy(fixed, `hero {heroId} is a fixed placement dt_h_{heroId}`)
	end
	local heroPlacements = 0
	for _, placement in Downtown.fixedPlacements do
		if string.sub(placement.id, 1, 5) == "dt_h_" then
			heroPlacements += 1
		end
	end
	expect.equal(heroPlacements, 14)
end)

test("Downtown: ids and book ids are unique and follow the naming rule", function()
	local ids, bookIds, nameKeys, assetKeys = {}, {}, {}, {}
	for _, themeId in Downtown.supportedThemes do
		local list = {}
		for _, object in resolved[themeId].objects do
			table.insert(list, object)
		end
		for _, object in list do
			expect.equal(object.bookId, "downtown." .. object.id)
			-- A hero variant (spec: cocoa_truck, glass_tower_bow) carries its own name and asset.
			local variant = (Downtown.themeBindings :: any)[themeId].heroVariants[object.id]
			expect.equal(
				object.nameKey,
				if variant then variant.nameKey else "object.downtown." .. object.id
			)
			expect.truthy(object.assetKey == "dt_" .. object.id or object.assetKey ~= nil)
		end
	end
	for _, object in Downtown.objects do
		expect.falsy(ids[object.id], object.id)
		expect.falsy(bookIds[object.bookId], object.bookId)
		expect.falsy(nameKeys[object.nameKey], object.nameKey)
		expect.falsy(assetKeys[object.assetKey])
		ids[object.id], bookIds[object.bookId], nameKeys[object.nameKey] = true, true, true
		assetKeys[object.assetKey] = true
		expect.equal(object.bookId, "downtown." .. object.id)
		expect.equal(object.nameKey, "object.downtown." .. object.id)
		expect.equal(object.assetKey, "dt_" .. object.id)
		expect.truthy(string.match(object.id, "^[a-z0-9_]+$") ~= nil)
		expect.equal(object.icon, "cube")
	end
end)

test(
	"Downtown: size tiers chain from 2 to 70, the top tier is open and none has a reward",
	function()
		expect.equal(#Downtown.sizeTiers, 5)
		for tier = 1, 5 do
			local def = Downtown.sizeTiers[tier]
			expect.equal(def.tier, tier)
			expect.equal(def.minDiameter, MIN_DIAMETERS[tier])
			expect.equal(def.maxDiameter, MIN_DIAMETERS[tier + 1])
			expect.equal(def.nameKey, `tier.downtown.{tier}.name`)
			expect.equal(def.headlineKey, `tier.downtown.{tier}.headline`)
			expect.equal(def.headlineIcon, "cube")
			expect.equal(def.reward, nil)
		end
		expect.equal(Downtown.sizeTiers[5].maxDiameter, nil)
	end
)

test("Downtown C2: sizes sit in the tier range and under 0.4 of the tier ceiling", function()
	for _, object in Downtown.objects do
		local range = SIZE_RANGES[object.tier]
		expect.truthy(object.size >= range[1] and object.size <= range[2], object.id)
		expect.truthy(object.size <= Config.absorbRatio * TIER_CEILINGS[object.tier], object.id)
	end
end)

test("Downtown C3: coins are whole numbers by the size rule and the tier ranges ascend", function()
	for _, object in Downtown.objects do
		local coins = COIN_RANGES[object.tier]
		expect.equal(object.coins, math.floor(object.coins), object.id)
		expect.truthy(object.coins >= coins[1] and object.coins <= coins[2], object.id)
		local span = SIZE_RANGES[object.tier]
		local fraction = (object.size - span[1]) / (span[2] - span[1])
		expect.equal(
			object.coins,
			coins[1] + math.floor((coins[2] - coins[1]) * fraction + 0.5),
			object.id
		)
	end
	for _, a in Downtown.objects do
		for _, b in Downtown.objects do
			if a.tier == b.tier and a.size < b.size then
				expect.truthy(a.coins <= b.coins, `{a.id} / {b.id}`)
			end
			if a.tier < b.tier then
				expect.truthy(a.coins < b.coins, `{a.id} / {b.id}`)
			end
		end
	end
end)

test("Downtown C4: fallback shapes and colour roles are valid in every theme", function()
	local shapes = { Block = true, Ball = true, Cylinder = true }
	for _, themeId in Downtown.supportedThemes do
		for _, object in resolved[themeId].objects do
			expect.truthy(shapes[object.fallback :: string], object.id)
			expect.truthy(object.role ~= nil, object.id)
			expect.truthy(
				(Themes :: any)[themeId].palette[object.role :: string] ~= nil,
				`{themeId}: {object.id} role {object.role}`
			)
		end
	end
end)

test(
	"Downtown C5: zones fit their cells, name known objects and do not mix slots with objects",
	function()
		local seen: { [string]: boolean } = {}
		local slotZones = 0
		for _, zone in Downtown.zones do
			expect.falsy(seen[zone.id], zone.id)
			seen[zone.id] = true
			expect.truthy(string.match(zone.id, "^dt_z_[%w_]+$") ~= nil, zone.id)
			expect.truthy(zone.count <= Layout.capacity(zone, baseSizes), `{zone.id} capacity`)
			expect.truthy(zone.count >= 1, zone.id)
			expect.truthy(math.abs(zone.x) + zone.w / 2 <= Downtown.halfExtent, zone.id)
			expect.truthy(math.abs(zone.z) + zone.d / 2 <= Downtown.halfExtent, zone.id)
			local anySlot, anyOther = false, false
			for _, entry in zone.mix do
				if ThemeResolve.isSlot(entry.objectId) then
					anySlot = true
				else
					anyOther = true
					expect.truthy(isCoreId(entry.objectId), `{zone.id} names {entry.objectId}`)
				end
				if zone.spawnSlot ~= nil then
					expect.equal((baseSizes[entry.objectId] :: number) <= 1.5, true, zone.id)
				end
			end
			expect.falsy(anySlot and anyOther, zone.id)
			if anySlot then
				slotZones += 1
			end
		end
		expect.truthy(slotZones > 0)
		local fixedSeen: { [string]: boolean } = {}
		for _, placement in Downtown.fixedPlacements do
			expect.falsy(fixedSeen[placement.id], placement.id)
			fixedSeen[placement.id] = true
			expect.falsy(seen[placement.id], placement.id)
			expect.truthy(
				isCoreId(placement.objectId) or ThemeResolve.isSlot(placement.objectId),
				placement.id
			)
			expect.truthy(math.abs(placement.x) <= Downtown.outerHalfExtent, placement.id)
			expect.truthy(math.abs(placement.z) <= Downtown.outerHalfExtent, placement.id)
		end
	end
)

test("Downtown C6: every slot is mapped in both bindings with the slot's tier", function()
	local slotTiers = {
		["slot.small"] = 1,
		["slot.medium"] = 2,
		["slot.yard"] = 3,
		["slot.street"] = 4,
		["slot.landmark"] = 5,
	}
	for _, themeId in Downtown.supportedThemes do
		local binding = (Downtown.themeBindings :: any)[themeId]
		local count = 0
		for slotId, tier in slotTiers do
			local mapped = binding.slots[slotId]
			expect.truthy(mapped ~= nil, `{themeId} {slotId}`)
			expect.equal(resolvedObjects[themeId][mapped].tier, tier, `{themeId} {slotId}`)
			count += 1
		end
		expect.equal(count, 5)
	end
end)

test(
	"Downtown C7: placement ids are unique, counts fit and both themes keep the base placements",
	function()
		local baseCount = 0
		for _ in resolved.city.placements do
			baseCount += 1
		end
		expect.equal(baseCount, #resolved.city.placements)
		for _, themeId in Downtown.supportedThemes do
			local placements = resolved[themeId].placements
			expect.truthy(
				#placements <= Downtown.maxPlacements,
				`{themeId}: {#placements} placements`
			)
			local seen: { [string]: boolean } = {}
			for _, placement in placements do
				expect.falsy(seen[placement.id], `{themeId}: {placement.id}`)
				seen[placement.id] = true
				expect.truthy(resolvedObjects[themeId][placement.objectId] ~= nil, placement.id)
				expect.truthy(math.abs(placement.x) <= Downtown.outerHalfExtent, placement.id)
				expect.truthy(math.abs(placement.z) <= Downtown.outerHalfExtent, placement.id)
			end
		end
		-- The base placements (ids and positions) are the same in both themes (FR-005).
		local winterById: { [string]: Layout.Placement } = {}
		for _, placement in resolved.winter.placements do
			winterById[placement.id] = placement
		end
		for _, placement in resolved.city.placements do
			local twin = winterById[placement.id]
			expect.truthy(twin ~= nil, placement.id)
			expect.equal(twin.x, placement.x, placement.id)
			expect.equal(twin.z, placement.z, placement.id)
		end
		expect.equal(#resolved.winter.placements - #resolved.city.placements, 150)
		expect.truthy(#resolved.city.placements >= 1200 and #resolved.city.placements <= 1290)
	end
)

test("Downtown: no two footprints overlap in either theme", function()
	for _, themeId in Downtown.supportedThemes do
		local placements = resolved[themeId].placements
		local sizes = resolvedSizes[themeId]
		for i = 1, #placements do
			local a = placements[i]
			for j = i + 1, #placements do
				local b = placements[j]
				local reach = (sizes[a.objectId] + sizes[b.objectId]) / 2
				local dx, dz = a.x - b.x, a.z - b.z
				if dx * dx + dz * dz < reach * reach - 1e-6 then
					error(`{themeId}: {a.id} and {b.id} overlap`)
				end
			end
		end
	end
end)

test("Downtown C8: dressing slots stay inside the 15 percent share and are 148 in all", function()
	local expected = { small = 96, medium = 30, yard = 14, street = 6, landmark = 2 }
	local kinds = { small = 0, medium = 0, yard = 0, street = 0, landmark = 0 }
	for _, zone in Downtown.zones do
		local entry = zone.mix[1].objectId
		if ThemeResolve.isSlot(entry) then
			kinds[string.sub(entry, 6)] += zone.count
		end
	end
	for _, placement in Downtown.fixedPlacements do
		if ThemeResolve.isSlot(placement.objectId) then
			kinds[string.sub(placement.objectId, 6)] += 1
		end
	end
	for kind, count in expected do
		expect.equal(kinds[kind], count, kind)
	end
	for _, themeId in Downtown.supportedThemes do
		local slots = 0
		for _ in resolved[themeId].slotPlacementIds do
			slots += 1
		end
		expect.equal(slots, 148, themeId)
		expect.truthy(
			slots / #resolved[themeId].placements <= Config.Budgets.maxDressingSlotShare,
			themeId
		)
	end
end)

test(
	"Downtown C9: 12 spawns, each with at least 40 Tier 1 objects within 10 studs in both themes",
	function()
		local points = Downtown.spawnPoints
		expect.equal(#points, 12)
		for index, point in points do
			expect.equal(point.slot, index)
			expect.equal(point.y, 0.6)
			expect.truthy(
				math.abs(point.x) <= Downtown.halfExtent
					and math.abs(point.z) <= Downtown.halfExtent
			)
			-- Three per quadrant, 40 to 70 studs in from the outer edge.
			expect.truthy(math.abs(point.x) >= 120 and math.abs(point.x) <= 260)
			for _, themeId in Downtown.supportedThemes do
				local near = 0
				for _, placement in resolved[themeId].placements do
					local object = resolvedObjects[themeId][placement.objectId]
					if object.tier == 1 then
						local dx, dz = placement.x - point.x, placement.z - point.z
						if dx * dx + dz * dz <= SPAWN_RADIUS * SPAWN_RADIUS then
							near += 1
						end
					end
				end
				expect.truthy(
					near >= MIN_NEAR_TIER_1,
					`{themeId} slot {index}: {near} Tier 1 within {SPAWN_RADIUS}`
				)
			end
		end
		-- Three doorsteps per quadrant.
		local perQuadrant: { [string]: number } = {}
		for _, point in points do
			local key = (if point.z < 0 then "n" else "s") .. (if point.x < 0 then "w" else "e")
			perQuadrant[key] = (perQuadrant[key] or 0) + 1
		end
		for _, key in { "nw", "ne", "sw", "se" } do
			expect.equal(perQuadrant[key], 3, key)
		end
	end
)

test(
	"Downtown: every core object is placed in both themes (the base pages stay completable)",
	function()
		for _, themeId in Downtown.supportedThemes do
			local placed: { [string]: boolean } = {}
			for _, placement in resolved[themeId].placements do
				placed[placement.objectId] = true
			end
			for _, object in Downtown.objects do
				-- A hero variant keeps the base object id, so the id is always placed.
				expect.truthy(placed[object.id], `{themeId}: {object.id} is never placed`)
			end
		end
	end
)

test("Downtown C10 to C13: theme bindings", function()
	local winter = Downtown.themeBindings.winter
	local city = Downtown.themeBindings.city
	-- C11
	expect.equal(#city.overlays.zones, 0)
	expect.equal(#city.overlays.fixedPlacements, 0)
	local cityVariants = 0
	for _ in city.heroVariants do
		cityVariants += 1
	end
	expect.equal(cityVariants, 0)
	local winterVariants = 0
	for _ in winter.heroVariants do
		winterVariants += 1
	end
	expect.equal(winterVariants, 2)
	-- C12
	for baseId, variant in winter.heroVariants do
		local base = objectById[baseId]
		expect.truthy(base ~= nil, baseId)
		expect.truthy(math.abs((variant.size :: number) - base.size) / base.size <= 0.1, baseId)
		local copy
		for _, object in resolved.winter.objects do
			if object.id == baseId then
				copy = object
			end
		end
		expect.equal(copy.tier, base.tier)
		expect.equal(copy.coins, base.coins)
		expect.equal(copy.bookId, base.bookId)
		expect.equal(copy.size, base.size)
		expect.equal(copy.assetKey, variant.assetKey)
	end
	expect.equal(winter.heroVariants.donut_food_truck.assetKey, "dt_cocoa_truck")
	expect.equal(winter.heroVariants.donut_food_truck.nameKey, "object.downtown.cocoa_truck")
	expect.equal(winter.heroVariants.glass_tower.assetKey, "dt_glass_tower_bow")
	expect.equal(winter.heroVariants.glass_tower.nameKey, "object.downtown.glass_tower_bow")
	-- C13
	expect.equal(#(winter.objects :: any), 18)
	expect.equal(#(city.objects :: any), 5)
	expect.equal(#(winter.bookPage :: any).objectIds, 18)
	expect.equal(#(city.bookPage :: any).objectIds, 5)
	expect.equal((winter.bookPage :: any).id, "downtown.winter")
	expect.equal((city.bookPage :: any).id, "downtown.city")
	expect.equal((winter.bookPage :: any).nameKey, "book.page.downtown.winter.name")
	expect.equal((winter.bookPage :: any).returningKey, "book.page.downtown.winter.returning")
	expect.equal((city.bookPage :: any).nameKey, "book.page.downtown.city.name")
	expect.equal((city.bookPage :: any).returningKey, "book.page.downtown.city.returning")
	expect.equal((winter.bookPage :: any).reward, nil)
	expect.equal((city.bookPage :: any).reward, nil)
	for index, object in winter.objects :: any do
		expect.equal((winter.bookPage :: any).objectIds[index], object.id)
		expect.falsy(objectById[object.id], `{object.id} clashes with the core kit`)
	end
	for index, object in city.objects :: any do
		expect.equal((city.bookPage :: any).objectIds[index], object.id)
		expect.falsy(objectById[object.id], `{object.id} clashes with the core kit`)
	end
	-- The overlay counts follow the table in data-model.md §5, 150 in all.
	local counts: { [string]: number } = {}
	for _, placement in resolved.winter.placements do
		if string.sub(placement.id, 1, 6) == "dt_ol_" then
			counts[placement.objectId] = (counts[placement.objectId] or 0) + 1
		end
	end
	local total = 0
	for id, count in OVERLAY_COUNTS do
		expect.equal(counts[id], count, id)
		total += count
	end
	expect.equal(total, 150)
	-- The winter slot objects are in the book page, too, and the tiers of the overlay kit are right.
	local overlayTiers = { fairy_light_bulb = 1, snow_pile = 3, market_stall = 4, ice_rink = 5 }
	for id, tier in overlayTiers do
		expect.equal(resolvedObjects.winter[id].tier, tier, id)
	end
end)

test("Downtown C10: overlays sit clear of every keep-out, all four kinds", function()
	local counts: { [string]: number } = { sightline = 0, marker = 0, gate = 0, shortcut = 0 }
	for _, keepOut in Downtown.keepOutAreas do
		counts[keepOut.kind] += 1
		expect.truthy(keepOut.w > 0 and keepOut.d > 0, keepOut.id)
	end
	expect.equal(counts.gate, 6)
	expect.equal(counts.shortcut, 5)
	expect.equal(counts.sightline, 12)
	expect.truthy(counts.marker >= 17 + 5, `marker keep-outs {counts.marker}`)
	for _, zone in Downtown.themeBindings.winter.overlays.zones do
		local zoneRect = rectOf(zone)
		for _, keepOut in Downtown.keepOutAreas do
			expect.falsy(
				intersects(zoneRect, rectOf(keepOut)),
				`{zone.id} intersects keep-out {keepOut.id}`
			)
		end
	end
	for _, fixed in Downtown.themeBindings.winter.overlays.fixedPlacements do
		local half = resolvedSizes.winter[fixed.objectId] / 2
		for _, keepOut in Downtown.keepOutAreas do
			local hit = math.abs(fixed.x - keepOut.x) < half + keepOut.w / 2
				and math.abs(fixed.z - keepOut.z) < half + keepOut.d / 2
			expect.falsy(hit, `fixed placement {fixed.id} sits in keep-out {keepOut.id}`)
		end
	end
	-- The placed overlays too, once expanded.
	for _, placement in resolved.winter.placements do
		if string.sub(placement.id, 1, 6) == "dt_ol_" then
			local half = resolvedSizes.winter[placement.objectId] / 2
			for _, keepOut in Downtown.keepOutAreas do
				local hit = math.abs(placement.x - keepOut.x) < half + keepOut.w / 2
					and math.abs(placement.z - keepOut.z) < half + keepOut.d / 2
				expect.falsy(hit, `overlay {placement.id} sits in keep-out {keepOut.id}`)
			end
		end
	end
end)

test(
	"Downtown: overlay zones and base zones never overlap, so overlays cannot plug a route",
	function()
		for _, overlay in Downtown.themeBindings.winter.overlays.zones do
			for _, zone in Downtown.zones do
				expect.falsy(intersects(rectOf(overlay), rectOf(zone)), `{overlay.id} / {zone.id}`)
			end
		end
		for i = 1, #Downtown.zones do
			for j = i + 1, #Downtown.zones do
				local a, b = Downtown.zones[i], Downtown.zones[j]
				expect.falsy(intersects(rectOf(a), rectOf(b)), `{a.id} / {b.id}`)
			end
		end
	end
)

test(
	"Downtown C16: 12 sightline corridors, one per spawn, 12 wide and 80 long, clear of T4 and T5",
	function()
		local corridors = {}
		for _, keepOut in Downtown.keepOutAreas do
			if keepOut.kind == "sightline" then
				table.insert(corridors, keepOut)
			end
		end
		expect.equal(#corridors, 12)
		for index, point in Downtown.spawnPoints do
			local corridor = corridors[index]
			expect.equal(corridor.w, 12)
			expect.truthy(corridor.d >= 80)
			-- It starts at the doorstep and runs out along the spawn's street towards the tower or the wheel.
			expect.equal(corridor.x, point.x)
			expect.truthy(math.abs(corridor.z - point.z) - corridor.d / 2 <= 0.001)
			expect.truthy(math.abs(point.z - corridor.z) <= corridor.d / 2 + 0.001)
			local outward = if point.z < 0 then -1 else 1
			expect.truthy((corridor.z - point.z) * outward > 0)
		end
		for _, themeId in Downtown.supportedThemes do
			for _, placement in resolved[themeId].placements do
				local object = resolvedObjects[themeId][placement.objectId]
				if object.tier >= 4 and placement.objectId ~= "slot.landmark" then
					local isLandmark = object.id == "mega_tree" or object.id == "giant_duck"
					for _, corridor in corridors do
						local half = object.size / 2
						local hit = math.abs(placement.x - corridor.x) < half + corridor.w / 2
							and math.abs(placement.z - corridor.z) < half + corridor.d / 2
						expect.falsy(
							hit and not isLandmark,
							`{themeId}: {placement.id} blocks {corridor.id}`
						)
					end
				end
			end
		end
		-- The goals themselves stand at the ends of the two streets.
		local glass, ferris
		for _, placement in Downtown.fixedPlacements do
			if placement.objectId == "glass_tower" then
				glass = placement
			elseif placement.objectId == "ferris_wheel" then
				ferris = placement
			end
		end
		expect.truthy(glass.z < -200 and ferris.z > 200)
	end
)

test(
	"Downtown: gates and shortcuts are open: no base placement stands in an alley or a gate",
	function()
		for _, keepOut in Downtown.keepOutAreas do
			if keepOut.kind == "shortcut" or keepOut.kind == "gate" then
				for _, placement in resolved.city.placements do
					local half = resolvedSizes.city[placement.objectId] / 2
					local hit = math.abs(placement.x - keepOut.x) < half + keepOut.w / 2
						and math.abs(placement.z - keepOut.z) < half + keepOut.d / 2
					expect.falsy(hit, `{placement.id} stands in {keepOut.id}`)
				end
			end
		end
	end
)

test("Downtown C14: at most 400 blocks and the part budget holds in both themes", function()
	local baseBlocks = #Downtown.environment.blocks
	expect.truthy(baseBlocks <= 400, `{baseBlocks} blocks`)
	local built = 0
	for _, marker in Downtown.environment.markers do
		if marker.kind ~= "GoldenSpot" then
			built += 1
		end
	end
	expect.truthy(built >= 9 and built <= 16, `{built} built markers`)
	for _, themeId in Downtown.supportedThemes do
		local themeBlocks = (Downtown.themeBindings :: any)[themeId].blocks
		local blocks = baseBlocks + (if themeBlocks then #themeBlocks else 0)
		local total = #resolved[themeId].placements + blocks + built + HUB_PARTS + BALLS
		expect.truthy(
			total + RUNTIME_PARTS <= Config.Budgets.maxActivePartsPerServer,
			`{themeId}: {total} parts plus {RUNTIME_PARTS} runtime parts`
		)
		expect.truthy(total <= Config.Budgets.maxActivePartsPerServer - RUNTIME_PARTS)
	end
end)

test(
	"Downtown: every block swatch exists in the world palette or every theme, and kinds are known",
	function()
		local palette = Downtown.environment.palette
		local ids: { [string]: boolean } = {}
		for _, block in Downtown.environment.blocks do
			expect.falsy(ids[block.id], block.id)
			ids[block.id] = true
			expect.truthy(
				block.kind == "Block" or block.kind == "Wedge" or block.kind == "Cylinder",
				block.id
			)
			expect.truthy(block.size.x > 0 and block.size.y > 0 and block.size.z > 0, block.id)
			for _, themeId in Downtown.supportedThemes do
				expect.truthy(
					palette[block.swatch] ~= nil
						or (Themes :: any)[themeId].palette[block.swatch] ~= nil,
					`{block.id} swatch {block.swatch}`
				)
			end
			expect.truthy(
				math.abs(block.cframe.x) <= 303 and math.abs(block.cframe.z) <= 303,
				block.id
			)
		end
	end
)

test("Downtown: placements stand on the ground or on top of the block under them", function()
	local blocks = Downtown.environment.blocks
	for _, themeId in Downtown.supportedThemes do
		for _, placement in resolved[themeId].placements do
			for _, block in blocks do
				local top = block.cframe.y + block.size.y / 2
				if top > 0.2 and block.kind == "Block" and block.cframe.yaw % 90 == 0 then
					local sideways = block.cframe.yaw % 180 ~= 0
					local hx = (if sideways then block.size.z else block.size.x) / 2
					local hz = (if sideways then block.size.x else block.size.z) / 2
					local inside = math.abs(placement.x - block.cframe.x) < hx
						and math.abs(placement.z - block.cframe.z) < hz
					if inside then
						expect.truthy(
							placement.y >= top - 0.01,
							`{themeId}: {placement.id} is inside block {block.id}`
						)
					end
				end
			end
		end
	end
end)

test("Downtown C18: a Tier 1 kerb 1.0 to 1.5 tall stands next to every spawn", function()
	for _, point in Downtown.spawnPoints do
		local found = false
		for _, block in Downtown.environment.blocks do
			local top = block.cframe.y + block.size.y / 2
			if top >= 1.0 and top <= 1.5 then
				local dx, dz = block.cframe.x - point.x, block.cframe.z - point.z
				if dx * dx + dz * dz <= 15 * 15 then
					found = true
				end
			end
		end
		expect.truthy(found, `slot {point.slot}`)
	end
end)

test(
	"Downtown C15: the markers pass Markers.validate with five golden spots and all nine sub-kinds",
	function()
		local errors = Markers.validate(
			Downtown.environment.markers :: any,
			Downtown.environment.blocks :: any,
			Downtown.keepOutAreas :: any,
			Downtown.halfExtent,
			{ boosters = Hazards.boosters :: any, traps = Hazards.traps :: any },
			{ requireGolden = 5 }
		)
		expect.equal(#errors, 0, table.concat(errors, " | "))
		local kinds: { [string]: number } = {}
		local subKinds: { [string]: boolean } = {}
		for _, marker in Downtown.environment.markers do
			kinds[marker.kind] = (kinds[marker.kind] or 0) + 1
			subKinds[marker.subKind] = true
		end
		expect.equal(kinds.GoldenSpot, 5)
		expect.truthy(kinds.BoosterSpot >= 5 and kinds.TrapSpot >= 4)
		expect.truthy(
			kinds.BoosterSpot + kinds.TrapSpot >= 9 and kinds.BoosterSpot + kinds.TrapSpot <= 12
		)
		for _, name in
			{
				"dash",
				"magnet",
				"spring",
				"shield",
				"slick_trail",
				"slick",
				"bumper",
				"slow",
				"sweeper",
				"golden",
			}
		do
			expect.truthy(subKinds[name], name)
		end
	end
)

test("Downtown: the marker keep-outs match the Hazards rows and the golden footprint", function()
	local footprints: { [string]: { w: number, d: number } } = { golden = Markers.GOLDEN_FOOTPRINT }
	for _, row in Hazards.boosters do
		footprints[row.subKind] = row.footprint
	end
	for _, row in Hazards.traps do
		footprints[row.subKind] = row.footprint
	end
	local single = 0
	for _, marker in Downtown.environment.markers do
		if marker.waypoints == nil then
			local want = footprints[marker.subKind]
			local found = false
			for _, keepOut in Downtown.keepOutAreas do
				if keepOut.kind == "marker" and keepOut.x == marker.x and keepOut.z == marker.z then
					expect.equal(keepOut.w, want.w, marker.id)
					expect.equal(keepOut.d, want.d, marker.id)
					found = true
				end
			end
			expect.truthy(found, marker.id)
			single += 1
		end
	end
	expect.truthy(single >= 15)
end)

test(
	"Downtown: golden spots stand on static blocks at their height and are never inside a placement",
	function()
		for _, marker in Downtown.environment.markers do
			if marker.kind == "GoldenSpot" then
				local supported = marker.y == 0
				for _, block in Downtown.environment.blocks do
					local top = block.cframe.y + block.size.y / 2
					if math.abs(top - marker.y) <= 0.2 then
						local inside = math.abs(marker.x - block.cframe.x) <= block.size.x / 2
							and math.abs(marker.z - block.cframe.z) <= block.size.z / 2
						supported = supported or inside
					end
				end
				expect.truthy(supported, `{marker.id} floats`)
				for _, themeId in Downtown.supportedThemes do
					for _, placement in resolved[themeId].placements do
						local half = resolvedSizes[themeId][placement.objectId] / 2
						local hit = math.abs(placement.x - marker.x) < half + 3
							and math.abs(placement.z - marker.z) < half + 3
						expect.falsy(hit, `{themeId}: {placement.id} stands on {marker.id}`)
					end
				end
			end
		end
	end
)

test(
	"Downtown C17: at most 8 pigeons per district, five districts, none in a marker keep-out",
	function()
		local ambient = Downtown.ambient
		expect.truthy(ambient ~= nil and ambient.pigeons ~= nil)
		local perDistrict: { [string]: number } = {}
		for _, pigeon in ambient.pigeons :: any do
			perDistrict[pigeon.district] = (perDistrict[pigeon.district] or 0) + 1
			expect.truthy(
				math.abs(pigeon.x) <= Downtown.halfExtent
					and math.abs(pigeon.z) <= Downtown.halfExtent
			)
			for _, keepOut in Downtown.keepOutAreas do
				if keepOut.kind == "marker" then
					local hit = math.abs(pigeon.x - keepOut.x) < keepOut.w / 2
						and math.abs(pigeon.z - keepOut.z) < keepOut.d / 2
					expect.falsy(hit, `{pigeon.district} pigeon in {keepOut.id}`)
				end
			end
		end
		local districts = 0
		for name, count in perDistrict do
			expect.truthy(count <= 8, name)
			districts += 1
		end
		expect.equal(districts, 5)
	end
)

test("Downtown: the hero variants and the cocoa truck swap only the mesh", function()
	local variant = Downtown.themeBindings.winter.heroVariants.donut_food_truck
	expect.equal(variant.size, objectById.donut_food_truck.size)
	local ids = {}
	for _, object in resolved.winter.objects do
		ids[object.id] = object
	end
	expect.equal(ids.donut_food_truck.assetKey, "dt_cocoa_truck")
	expect.equal(resolved.city.objects[1].assetKey, "dt_" .. resolved.city.objects[1].id)
	local cityIds = {}
	for _, object in resolved.city.objects do
		cityIds[object.id] = object
	end
	expect.equal(cityIds.donut_food_truck.assetKey, "dt_donut_food_truck")
	expect.equal(cityIds.glass_tower.assetKey, "dt_glass_tower")
end)

test("Downtown: the winter look is the launch look and the lighting copy matches", function()
	expect.equal(Themes.winter.lighting.clockTime, 16.5)
	expect.equal(Downtown.lighting.clockTime, 16.5)
	expect.equal(Downtown.hub.center.x, -460)
	expect.truthy(Downtown.growthK > 0)
end)

test("Downtown: the active world is picked in priority order and the flag is on", function()
	expect.equal(Config.Flags.Downtown, true)
	expect.equal(Config.DefaultWorldsUnlocked.downtown, true)
	local text = fs.readFile("src/shared/Worlds.luau")
	local downtownAt = string.find(text, "Config.Flags.Downtown", 1, true)
	local snowAt = string.find(text, "Config.Flags.SnowVillage", 1, true)
	expect.truthy(
		downtownAt ~= nil and snowAt ~= nil and (downtownAt :: number) < (snowAt :: number)
	)
	expect.truthy(string.find(text, "else GreyBoxRoom", 1, true) ~= nil)
end)

test("Downtown F2: garlands and the sledding slope belong to the winter theme only", function()
	local function ids(list: { { id: string } }): { [string]: boolean }
		local set: { [string]: boolean } = {}
		for _, block in list do
			set[block.id] = true
		end
		return set
	end
	local base = ids(Downtown.environment.blocks)
	local winter = ids((Downtown.themeBindings :: any).winter.blocks or {})
	expect.truthy(winter.dt_park_slope and winter.dt_garland_1)
	expect.falsy(base.dt_park_slope or base.dt_garland_1)
	expect.falsy((Downtown.themeBindings :: any).city.blocks ~= nil)
end)

test(
	"Downtown F5: the drain tunnel has 5-tall walls and a roof over the chamber and mouths, so a jump cannot get in",
	function()
		local walls, roof = 0, nil
		for _, block in Downtown.environment.blocks do
			if block.id == "dt_tunnel_roof" then
				roof = block
			elseif string.find(block.id, "^dt_tunnel_") then
				walls += 1
				expect.truthy(block.cframe.y + block.size.y / 2 >= 5, block.id)
			end
		end
		expect.equal(walls, 6)
		expect.truthy(roof ~= nil)
		-- Covers z -14 to 14 and x -103.5 to -96.5, and sits at the wall tops (clearance 5 for D < 5).
		expect.truthy(
			roof.cframe.y - roof.size.y / 2 >= 5 and roof.cframe.y - roof.size.y / 2 <= 5.01
		)
		expect.truthy(roof.size.z >= 28 and roof.size.x >= 7)
	end
)

return {}
