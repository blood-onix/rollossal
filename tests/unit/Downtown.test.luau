--!strict
-- Content validation for src/shared/Content/Worlds/Downtown.luau (007 and 008; contracts/world-content.md
-- invariants C1 to C18 and N1 to N10, data-model.md). The ranges below are written out by hand from the spec and the design, not read
-- from the data under test.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

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
-- The winter overlays (data-model.md section 14): Tier 2 to 4 dressing, one ice rink, no Tier 1.
local OVERLAY_COUNTS: { [string]: number } = {
	wooden_sled = 14,
	snow_pile = 12,
	cocoa_cart = 8,
	market_stall = 5,
	poinsettia_pot = 16,
	wreath = 16,
	ice_rink = 1,
}
local OVERLAY_TOTAL = 72
local HUB_PARTS = 3
local BALLS = 12
-- Runtime parts of Feature 006 (48 trail patches and 16 sweeper and bumper parts) that a Studio capture sees.
local RUNTIME_PARTS = 64
local SPAWN_RADIUS = 10
local TIER_TARGETS = { 470, 386, 260, 204, 56 }
local MAX_PARTS = 1850
local MIN_NEAR_TIER_1 = 40
-- Measured by the 009 heavy-scene benchmark (specs/009-style-bible-bakeoff/playtest.md): the highest step that held
-- 60 fps on every sampled second was 699,872 triangles, of which 367,264 tier 4 to 5. Ceiling = floor10k(0.8 x step).
local UNCULLED_TRIANGLE_CEILING = 550000
local CULLED_TRIANGLE_CEILING = 290000

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
	expect.equal(Downtown.halfExtent, 440)
	expect.equal(Downtown.outerHalfExtent, 560)
	expect.equal(Downtown.maxPlacements, 1500)
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
		expect.equal(#resolved.winter.placements - #resolved.city.placements, OVERLAY_TOTAL)
		-- C7: winter (city plus the overlays) stays within the 1500 cap.
		expect.truthy(
			#resolved.city.placements >= 1300
				and #resolved.winter.placements <= Config.Budgets.defaultMaxPlacements
		)
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

test("Downtown C8: dressing slots stay inside the 15 percent share and are 109 in all", function()
	local expected = { small = 96, medium = 4, yard = 4, street = 4, landmark = 1 }
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
		expect.equal(slots, 109, themeId)
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
			expect.equal(point.y, 0)
			-- In the Old Quarter (m <= 90) and never inside a main-street corridor.
			expect.truthy(math.max(math.abs(point.x), math.abs(point.z)) <= 90)
			expect.truthy(math.abs(point.x) >= 15 and math.abs(point.z) >= 15)
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
	expect.equal(total, OVERLAY_TOTAL)
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
	expect.equal(counts.gate, 4)
	expect.equal(counts.shortcut, 5)
	expect.equal(counts.sightline, 16)
	expect.truthy(counts.marker >= 15 + 5, `marker keep-outs {counts.marker}`)
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
	"Downtown C16: 4 main-street and 12 lane corridors are clear of tall blocks and Tier 4 and 5 buildings",
	function()
		local corridors = {}
		local streets, lanes = 0, 0
		for _, keepOut in Downtown.keepOutAreas do
			if keepOut.kind == "sightline" then
				table.insert(corridors, keepOut)
				if keepOut.w == 30 or keepOut.d == 30 then
					streets += 1
				elseif keepOut.w == 8 or keepOut.d == 8 then
					lanes += 1
				end
			end
		end
		expect.equal(#corridors, 16)
		expect.equal(streets, 4)
		expect.equal(lanes, 12)
		-- Every spawn is the near end of one lane corridor.
		for _, point in Downtown.spawnPoints do
			local found = false
			for _, corridor in corridors do
				if
					math.abs(point.x - corridor.x) <= corridor.w / 2
					and math.abs(point.z - corridor.z) <= corridor.d / 2
				then
					found = true
				end
			end
			expect.truthy(found, `slot {point.slot} has a corridor`)
		end
		local all = table.clone(Downtown.environment.blocks)
		for _, themeId in Downtown.supportedThemes do
			local themeBlocks = (Downtown.themeBindings :: any)[themeId].blocks
			local list = if themeBlocks
				then table.move(themeBlocks, 1, #themeBlocks, #all + 1, table.clone(all))
				else all
			for _, block in list do
				local top = block.cframe.y + block.size.y / 2
				local bottom = block.cframe.y - block.size.y / 2
				-- Garlands hang at bottom y >= 9: overhead, not a sightline block.
				if block.kind ~= "Boundary" and top > 2.5 and bottom < 9 then
					local sideways = block.cframe.yaw % 180 ~= 0
					local rect = {
						block.cframe.x - (if sideways then block.size.z else block.size.x) / 2,
						block.cframe.x + (if sideways then block.size.z else block.size.x) / 2,
						block.cframe.z - (if sideways then block.size.x else block.size.z) / 2,
						block.cframe.z + (if sideways then block.size.x else block.size.z) / 2,
					}
					for _, corridor in corridors do
						expect.falsy(
							intersects(rect, rectOf(corridor)),
							`{themeId}: block {block.id} crosses {corridor.id}`
						)
					end
				end
			end
			for _, placement in resolved[themeId].placements do
				local object = resolvedObjects[themeId][placement.objectId]
				local isLandmark = object.id == "mega_tree" or object.id == "giant_duck"
				if object.tier >= 4 and not isLandmark then
					for _, corridor in corridors do
						local half = object.size / 2
						local hit = math.abs(placement.x - corridor.x) < half + corridor.w / 2
							and math.abs(placement.z - corridor.z) < half + corridor.d / 2
						expect.falsy(hit, `{themeId}: {placement.id} blocks {corridor.id}`)
					end
				end
			end
		end
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

test(
	"Downtown C14: at most 215 base blocks, 250 in winter, and the part budget holds in both themes",
	function()
		local baseBlocks = #Downtown.environment.blocks
		expect.truthy(baseBlocks <= 215, `{baseBlocks} blocks`)
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
			expect.truthy(blocks <= 250, `{themeId}: {blocks} blocks`)
			local total = #resolved[themeId].placements + blocks + built + HUB_PARTS + BALLS
			expect.truthy(
				total + RUNTIME_PARTS <= MAX_PARTS,
				`{themeId}: {total} parts plus {RUNTIME_PARTS} runtime parts`
			)
			expect.truthy(total + RUNTIME_PARTS < Config.Budgets.maxActivePartsPerServer)
		end
	end
)

test(
	"Downtown: every block swatch exists in the world palette or every theme, and kinds are known",
	function()
		local palette = Downtown.environment.palette
		local ids: { [string]: boolean } = {}
		for _, block in Downtown.environment.blocks do
			expect.falsy(ids[block.id], block.id)
			ids[block.id] = true
			expect.truthy(
				block.kind == "Block"
					or block.kind == "Wedge"
					or block.kind == "Cylinder"
					or block.kind == "Boundary",
				block.id
			)
			expect.truthy(block.size.x > 0 and block.size.y > 0 and block.size.z > 0, block.id)
			expect.truthy(block.cframe.yaw % 90 == 0, `{block.id} yaw`)
			for _, themeId in Downtown.supportedThemes do
				expect.truthy(
					palette[block.swatch] ~= nil
						or (Themes :: any)[themeId].palette[block.swatch] ~= nil,
					`{block.id} swatch {block.swatch}`
				)
			end
			-- Blocks sit inside the playable square; the invisible walls may be 8 outside it and the horizon
			-- towers stand beyond it.
			local limit = Downtown.halfExtent + 2
			if block.kind == "Boundary" then
				limit = Downtown.halfExtent + 8
			elseif string.sub(block.id, 1, 11) == "dt_horizon_" then
				limit = Downtown.outerHalfExtent
			elseif string.sub(block.id, 1, 9) == "dt_basin_" or block.id == "dt_ground" then
				limit = Downtown.outerHalfExtent + 100
			end
			expect.truthy(
				math.abs(block.cframe.x) <= limit and math.abs(block.cframe.z) <= limit,
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
				-- Within 4.5 studs of the block's footprint: the lane edge is the kerb (D5).
				local sideways = block.cframe.yaw % 180 ~= 0
				local hx = (if sideways then block.size.z else block.size.x) / 2
				local hz = (if sideways then block.size.x else block.size.z) / 2
				local dx = math.max(math.abs(point.x - block.cframe.x) - hx, 0)
				local dz = math.max(math.abs(point.z - block.cframe.z) - hz, 0)
				if dx * dx + dz * dz <= 4.5 * 4.5 then
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
			kinds.BoosterSpot + kinds.TrapSpot >= 9 and kinds.BoosterSpot + kinds.TrapSpot <= 16
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
	"Downtown traffic: every lane is a closed loop of spaced cars that drives clear of solid blocks",
	function()
		local ambient = Downtown.ambient
		expect.truthy(ambient ~= nil and ambient.traffic ~= nil)
		local lanes = (ambient :: any).traffic
		expect.truthy(#lanes >= 2)
		local solids = {}
		for _, block in Downtown.environment.blocks do
			local top = block.cframe.y + block.size.y / 2
			if block.kind ~= "Boundary" and top > 0.3 then
				local sx, sz = block.size.x, block.size.z
				if math.floor(block.cframe.yaw / 90 + 0.5) % 2 == 1 then
					sx, sz = sz, sx
				end
				table.insert(solids, {
					x0 = block.cframe.x - sx / 2,
					x1 = block.cframe.x + sx / 2,
					z0 = block.cframe.z - sz / 2,
					z1 = block.cframe.z + sz / 2,
					id = block.id,
				})
			end
		end
		local CAR_HALF_WIDTH = 3.6
		for _, lane in lanes do
			expect.truthy(#lane.waypoints >= 3, lane.id)
			expect.truthy(lane.speed > 0, lane.id)
			local length = 0
			for index, from in lane.waypoints do
				local to = lane.waypoints[index % #lane.waypoints + 1]
				expect.truthy(math.abs(from.x) <= Downtown.halfExtent, lane.id)
				expect.truthy(math.abs(from.z) <= Downtown.halfExtent, lane.id)
				local dx, dz = to.x - from.x, to.z - from.z
				local segment = math.sqrt(dx * dx + dz * dz)
				length += segment
				for step = 0, math.floor(segment / 3) do
					local f = step * 3 / segment
					local px, pz = from.x + dx * f, from.z + dz * f
					for _, solid in solids do
						local hit = px > solid.x0 - CAR_HALF_WIDTH
							and px < solid.x1 + CAR_HALF_WIDTH
							and pz > solid.z0 - CAR_HALF_WIDTH
							and pz < solid.z1 + CAR_HALF_WIDTH
						expect.falsy(hit, `{lane.id} drives into {solid.id} near {px}, {pz}`)
					end
				end
			end
			expect.truthy(#lane.cars >= 1, lane.id)
			-- 30 studs between cars: the longest body is 25 long.
			expect.truthy(length / #lane.cars >= 30, `{lane.id}: cars closer than 30 studs`)
			for _, car in lane.cars do
				expect.truthy(car.phase >= 0 and car.phase < 1, lane.id)
				expect.truthy(#car.colour == 3, lane.id)
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
	expect.equal(Downtown.hub.center.x, -620)
	expect.equal(Downtown.hub.center.z, 0)
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

test(
	"Downtown N9 (F2): garlands, the slope and the sled ramp belong to the winter theme only",
	function()
		local function ids(list: { { id: string } }): { [string]: boolean }
			local set: { [string]: boolean } = {}
			for _, block in list do
				set[block.id] = true
			end
			return set
		end
		for _, block in Downtown.environment.blocks do
			expect.falsy(string.find(block.id, "garland", 1, true), block.id)
			expect.falsy(string.find(block.id, "slope", 1, true), block.id)
		end
		local winterList = (Downtown.themeBindings :: any).winter.blocks or {}
		local winter = ids(winterList)
		expect.truthy(winter.dt_park_slope and winter.dt_park_sledramp)
		local garlands = 0
		for _, block in winterList do
			if string.find(block.id, "garland", 1, true) then
				garlands += 1
				expect.truthy(block.cframe.y - block.size.y / 2 >= 9, block.id)
			end
		end
		expect.equal(garlands, 24)
		expect.truthy(#winterList <= 35)
		expect.falsy((Downtown.themeBindings :: any).city.blocks ~= nil)
	end
)

-- Helpers for the 008 layout checks -------------------------------------------------------------------------------

type Rect = { number }

local function blockRect(block: any): Rect
	local sideways = block.cframe.yaw % 180 ~= 0
	local hx = (if sideways then block.size.z else block.size.x) / 2
	local hz = (if sideways then block.size.x else block.size.z) / 2
	return { block.cframe.x - hx, block.cframe.x + hx, block.cframe.z - hz, block.cframe.z + hz }
end

local function blockTop(block: any): number
	return block.cframe.y + block.size.y / 2
end

local function blockBottom(block: any): number
	return block.cframe.y - block.size.y / 2
end

local function blocksFor(themeId: string): { any }
	local all = table.clone(Downtown.environment.blocks) :: { any }
	local themeBlocks = (Downtown.themeBindings :: any)[themeId].blocks
	if themeBlocks then
		table.move(themeBlocks, 1, #themeBlocks, #all + 1, all)
	end
	return all
end

test("Downtown N1: the envelope pins and four invisible 8-thick boundary walls", function()
	expect.equal(Downtown.halfExtent, 440)
	expect.equal(Downtown.outerHalfExtent, 560)
	expect.equal(Downtown.hub.center.x, -620)
	expect.equal(Downtown.hub.center.z, 0)
	expect.equal(Config.cameraMaxDistance, 320)
	local found: { [string]: boolean } = {}
	for _, block in Downtown.environment.blocks do
		if block.kind == "Boundary" then
			expect.truthy(block.size.y >= 150, block.id)
			local rect = blockRect(block)
			-- Inner faces at +-halfExtent, thickness >= 8.
			if block.size.x >= 800 and block.size.z <= block.size.x then
				local north = block.cframe.z < 0
				expect.truthy(block.size.z >= 8, block.id)
				expect.equal(
					if north then rect[4] else rect[3],
					if north then -440 else 440,
					block.id
				)
				found[if north then "n" else "s"] = true
			else
				local west = block.cframe.x < 0
				expect.truthy(block.size.x >= 8, block.id)
				expect.equal(
					if west then rect[2] else rect[1],
					if west then -440 else 440,
					block.id
				)
				found[if west then "w" else "e"] = true
			end
		end
	end
	for _, side in { "n", "s", "e", "w" } do
		expect.truthy(found[side], side)
	end
	-- The old perimeter wall is gone.
	for _, block in Downtown.environment.blocks do
		expect.falsy(string.find(block.id, "dt_wall_", 1, true), block.id)
	end
end)

-- Rasterises blocks (top > 0.2) and Tier 4 or 5 buildings onto a 5-stud grid over [-440, 440]^2.
local function coverage(themeId: string): number
	local cells = 176
	local marked: { [number]: boolean } = {}
	local count = 0
	local function mark(rect: Rect)
		local i0 = math.max(0, math.floor((rect[1] + 440) / 5))
		local i1 = math.min(cells - 1, math.ceil((rect[2] + 440) / 5) - 1)
		local j0 = math.max(0, math.floor((rect[3] + 440) / 5))
		local j1 = math.min(cells - 1, math.ceil((rect[4] + 440) / 5) - 1)
		for i = i0, i1 do
			for j = j0, j1 do
				local key = i * cells + j
				if not marked[key] then
					marked[key] = true
					count += 1
				end
			end
		end
	end
	for _, block in blocksFor(themeId) do
		if block.kind ~= "Boundary" and blockTop(block) > 0.2 and blockBottom(block) < 9 then
			mark(blockRect(block))
		end
	end
	for _, placement in resolved[themeId].placements do
		local object = resolvedObjects[themeId][placement.objectId]
		if object.tier >= 4 then
			local half = object.size / 2
			mark({ placement.x - half, placement.x + half, placement.z - half, placement.z + half })
		end
	end
	return count / (cells * cells)
end

test("Downtown N2: built coverage is at least 20 percent in both themes", function()
	for _, themeId in Downtown.supportedThemes do
		local value = coverage(themeId)
		expect.truthy(value >= 0.2, `{themeId}: coverage {value}`)
	end
end)

test("Downtown N3 and N4: at least 50 static blocks and no tall perimeter wall", function()
	local count = 0
	for _, block in Downtown.environment.blocks do
		if block.kind ~= "Boundary" then
			local rect = blockRect(block)
			local area = (rect[2] - rect[1]) * (rect[4] - rect[3])
			if blockTop(block) > 0.5 or area < 4000 then
				count += 1
			end
			-- Nothing within 12 studs of the playable edge is taller than 8.
			local touches = rect[2] >= 428 and rect[1] <= 452
				or rect[1] <= -428 and rect[2] >= -452
				or rect[4] >= 428 and rect[3] <= 452
				or rect[3] <= -428 and rect[4] >= -452
			if touches and string.sub(block.id, 1, 11) ~= "dt_horizon_" then
				expect.truthy(blockTop(block) <= 8, `{block.id} is a tall perimeter wall`)
			end
		end
	end
	expect.truthy(count >= 50, `{count} static blocks`)
end)

test(
	"Downtown N6: base placements per tier are within 10 percent of 470 / 386 / 260 / 204 / 56",
	function()
		local counts = { 0, 0, 0, 0, 0 }
		for _, placement in resolved.city.placements do
			local tier = resolvedObjects.city[placement.objectId].tier
			counts[tier] += 1
		end
		for tier = 1, 5 do
			local target = TIER_TARGETS[tier]
			expect.truthy(
				counts[tier] >= math.ceil(target * 0.9) and counts[tier] <= math.floor(target * 1.1),
				`tier {tier}: {counts[tier]} placements, wanted {target} +- 10 percent`
			)
		end
		-- The winter overlays carry Tier 2 and above only (D5), and the base is the same in both themes.
		for _, placement in resolved.winter.placements do
			if string.sub(placement.id, 1, 6) == "dt_ol_" then
				expect.truthy(resolvedObjects.winter[placement.objectId].tier >= 2, placement.id)
			end
		end
	end
)

-- Free width across a street at a point: from the centre outwards until a block with top >= 1 (a plinth or wall).
local function clearWidth(x: number, z: number, alongX: boolean, themeId: string): number
	local solid: { Rect } = {}
	for _, block in blocksFor(themeId) do
		if block.kind == "Block" and blockTop(block) >= 1.0 and blockBottom(block) < 3 then
			table.insert(solid, blockRect(block))
		end
	end
	local function inside(px: number, pz: number): boolean
		for _, rect in solid do
			if px > rect[1] and px < rect[2] and pz > rect[3] and pz < rect[4] then
				return true
			end
		end
		return false
	end
	local low, high = 0, 0
	while
		low < 80
		and not inside(if alongX then x - low - 0.5 else x, if alongX then z else z - low - 0.5)
	do
		low += 0.5
	end
	while
		high < 80
		and not inside(if alongX then x + high + 0.5 else x, if alongX then z else z + high + 0.5)
	do
		high += 0.5
	end
	return low + high
end

test("Downtown N7: street widths per ring", function()
	local function widths(
		label: string,
		points: { { number } },
		alongX: boolean,
		minimum: number,
		maximum: number
	)
		for _, themeId in Downtown.supportedThemes do
			for _, point in points do
				local width = clearWidth(point[1], point[2], alongX, themeId)
				expect.truthy(
					width >= minimum and width <= maximum,
					`{themeId} {label} at ({point[1]}, {point[2]}): {width}`
				)
			end
		end
	end
	-- Ring 1 lanes: 8 +- 1, sampled away from the crossings.
	local laneX, laneZ = {}, {}
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			for _, t in { 22, 38, 65, 75, 85 } do
				table.insert(laneX, { sx * 52.5, sz * t })
				table.insert(laneZ, { sx * t, sz * 52.5 })
			end
		end
	end
	widths("lane x", laneX, true, 7, 9)
	widths("lane z", laneZ, false, 7, 9)
	-- Main streets 30 +- 1 through Rings 1 and 2, at points between the loops.
	local north, east = {}, {}
	for _, sign in { -1, 1 } do
		for _, t in { 40, 60, 80, 115, 125, 135, 165, 175 } do
			table.insert(north, { 0, sign * t })
			table.insert(east, { sign * t, 0 })
		end
	end
	widths("main street ns", north, true, 29, 31)
	widths("main street ew", east, false, 29, 31)
	-- Ring 2 loops and radials: 16 to 30.
	widths("loop A", { { 30, -100 }, { 70, -100 }, { -30, 100 }, { -70, 100 } }, false, 15, 30)
	widths("loop B", { { 30, -150 }, { 70, -150 }, { -30, 150 }, { 70, 150 } }, false, 15, 30)
	widths("radial", { { 55, -125 }, { -55, -125 }, { 55, -170 }, { -55, 170 } }, true, 15, 30)
	-- Ring 5 avenues: at least 40.
	widths("avenue n", { { 0, -400 }, { 0, -380 } }, true, 40, 80)
	widths("avenue e", { { 400, 0 }, { 380, 0 } }, false, 40, 80)
	-- Ring 3 approaches: at least 30 (open ground beyond the yards' fences is measured as 80).
	widths("approach", { { 0, -250 }, { 250, 0 } }, true, 30, 200)
	-- Ring 4: two 26-stud carriageways either side of an 8-stud median, 60 in all.
	local medians = 0
	for _, block in Downtown.environment.blocks do
		if string.sub(block.id, 1, 7) == "dt_med_" then
			medians += 1
			expect.truthy(math.abs(blockTop(block) - 0.8) < 0.01, block.id)
			local rect = blockRect(block)
			local thin = math.min(rect[2] - rect[1], rect[4] - rect[3])
			expect.equal(thin, 8, block.id)
			local face = if rect[2] - rect[1] < rect[4] - rect[3] then rect[1] else rect[3]
			local centre = (face + thin / 2)
			local inner = math.abs(centre) - 4 - 295
			local outer = 355 - (math.abs(centre) + 4)
			expect.truthy(inner >= 24 and outer >= 24, block.id)
			expect.equal(inner + 8 + outer, 60, block.id)
		end
	end
	expect.equal(medians, 8)
end)

-- Flood fill over the Old Quarter at 2-stud cells: can a ball of diameter D leave it? Walls and the bollard cones
-- (size 2, eaten only when 0.4 D >= 2) are the obstacles, grown by the ball's radius.
local function leavesOldQuarter(diameter: number): boolean
	local radius = diameter / 2
	local walls: { Rect } = {}
	for _, block in Downtown.environment.blocks do
		if
			block.kind == "Block"
			and blockBottom(block) < diameter
			and blockTop(block) > math.max(2.5, 0.5 * diameter)
		then
			local rect = blockRect(block)
			table.insert(
				walls,
				{ rect[1] - radius, rect[2] + radius, rect[3] - radius, rect[4] + radius }
			)
		end
	end
	for _, fixed in Downtown.fixedPlacements do
		if fixed.objectId == "traffic_cone" and 2.0 > Config.absorbRatio * diameter then
			table.insert(walls, {
				fixed.x - 1 - radius,
				fixed.x + 1 + radius,
				fixed.z - 1 - radius,
				fixed.z + 1 + radius,
			})
		end
	end
	local function blocked(x: number, z: number): boolean
		for _, rect in walls do
			if x > rect[1] and x < rect[2] and z > rect[3] and z < rect[4] then
				return true
			end
		end
		return false
	end
	-- Cells are 2 studs; indices run -60 to 59 (x, z from -120 to 118).
	local seen: { [number]: boolean } = {}
	local function key(i: number, j: number): number
		return (i + 100) * 1000 + (j + 100)
	end
	local start = Downtown.spawnPoints[1]
	local queue = { { math.floor(start.x / 2), math.floor(start.z / 2) } }
	seen[key(queue[1][1], queue[1][2])] = true
	local head = 1
	while head <= #queue do
		local cell = queue[head]
		head += 1
		for _, step in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local i, j = cell[1] + step[1], cell[2] + step[2]
			if i >= -60 and i < 60 and j >= -60 and j < 60 and not seen[key(i, j)] then
				local x, z = i * 2 + 1, j * 2 + 1
				if not blocked(x, z) then
					seen[key(i, j)] = true
					if math.max(math.abs(x), math.abs(z)) >= 93 then
						return true
					end
					table.insert(queue, { i, j })
				end
			end
		end
	end
	return false
end

test("Downtown N8: a D 2 ball cannot leave the Old Quarter, a D 5 ball can", function()
	expect.falsy(leavesOldQuarter(2))
	expect.falsy(leavesOldQuarter(4.5))
	expect.truthy(leavesOldQuarter(5))
end)

test(
	"Downtown N5 (F5, F6): every shortcut is 4.5 wide with a roof at 4.8 to 5.0 and 5.2 walls",
	function()
		local byId: { [string]: any } = {}
		for _, block in Downtown.environment.blocks do
			byId[block.id] = block
		end
		local shortcuts = 0
		for _, keepOut in Downtown.keepOutAreas do
			if keepOut.kind == "shortcut" then
				shortcuts += 1
				local name = string.gsub(keepOut.id, "^ko_shortcut_", "")
				local prefix = if name == "drain" then "dt_drain_3" else `dt_sc_{name}`
				local wallA, wallB, roof =
					byId[prefix .. "_wa"], byId[prefix .. "_wb"], byId[prefix .. "_roof"]
				expect.truthy(wallA ~= nil and wallB ~= nil and roof ~= nil, keepOut.id)
				local a, b, r = blockRect(wallA), blockRect(wallB), blockRect(roof)
				local acrossX = (a[2] - a[1]) < (a[4] - a[3])
				local gap = if acrossX then math.abs(b[1] - a[2]) else math.abs(b[3] - a[4])
				if acrossX and b[1] < a[1] then
					gap = a[1] - b[2]
				elseif not acrossX and b[3] < a[3] then
					gap = a[3] - b[4]
				end
				expect.truthy(math.abs(gap - 4.5) <= 0.1, `{keepOut.id}: gap {gap}`)
				expect.truthy(blockTop(wallA) >= 5.2 and blockTop(wallB) >= 5.2, keepOut.id)
				local bottom = blockBottom(roof)
				expect.truthy(bottom >= 4.8 and bottom <= 5.0, `{keepOut.id}: roof bottom {bottom}`)
				-- The roof covers the corridor along its length and across both walls.
				local length = if acrossX then keepOut.d else keepOut.w
				local roofLength = if acrossX then r[4] - r[3] else r[2] - r[1]
				expect.truthy(roofLength >= length - 0.01, keepOut.id)
				expect.truthy(
					if acrossX
						then r[1] <= math.min(a[1], b[1]) and r[2] >= math.max(a[2], b[2])
						else r[3] <= math.min(a[3], b[3]) and r[4] >= math.max(a[4], b[4]),
					keepOut.id
				)
			end
		end
		expect.equal(shortcuts, 5)
	end
)

test("Downtown N10: the triangle ceilings hold against the art manifest", function()
	local manifest = serde.decode("json", fs.readFile("art/export/manifest.json"))
	local triangles: { [string]: number } = {}
	for _, mesh in manifest.meshes do
		triangles[mesh.id] = mesh.triangles
	end
	local total, culled = 0, 0
	for _, placement in resolved.winter.placements do
		local object = resolvedObjects.winter[placement.objectId]
		local count = triangles[object.assetKey :: string]
		expect.truthy(count ~= nil, `no manifest row for {object.assetKey}`)
		total += count
		if object.tier >= 4 then
			culled += count
		end
	end
	expect.truthy(
		total <= UNCULLED_TRIANGLE_CEILING,
		`unculled {total} of {UNCULLED_TRIANGLE_CEILING}`
	)
	expect.truthy(culled <= CULLED_TRIANGLE_CEILING, `culled {culled} of {CULLED_TRIANGLE_CEILING}`)
end)

test(
	"Downtown: each ring group has a booster and a trap, and every Studio-built block id is unique",
	function()
		local groups = {
			{ 0, 90 },
			{ 90, 185 },
			{ 185, 290 },
			{ 290, 360 },
			{ 360, 440 },
		}
		for index, group in groups do
			local booster, trap = false, false
			for _, marker in Downtown.environment.markers do
				local m = math.max(math.abs(marker.x), math.abs(marker.z))
				if m > group[1] and m <= group[2] then
					booster = booster or marker.kind == "BoosterSpot"
					trap = trap or marker.kind == "TrapSpot"
				end
			end
			expect.truthy(booster and trap, `ring group {index}`)
		end
	end
)

return {}
