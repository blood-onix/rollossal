--!strict
-- Contract tests for src/shared/Rules/ThemeResolve.luau (specs/005-theme-art-pipeline/contracts/
-- theme-content.md §2, data-model.md §6): the eight fixed behaviours, cross-theme stability of the
-- non-slot placements, the slot share cap, unique resolved ids, and overlays clear of keepOutAreas.

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local Layout = require("../../src/shared/Rules/Layout")
local ThemeResolve = require("../../src/shared/Rules/ThemeResolve")

local test, expect = harness.test, harness.expect

-- ---------------------------------------------------------------- the hand-written world

local function makeObject(
	id: string,
	tier: number,
	size: number,
	bookId: string
): ThemeResolve.ObjectLike
	return {
		id = id,
		tier = tier,
		size = size,
		coins = tier,
		bookId = bookId,
		nameKey = `n.{id}`,
		icon = `i.{id}`,
	}
end

local SMALL_WINTER = { ["slot.small"] = "small_a" } -- tier 1
local SMALL_CITY = { ["slot.small"] = "thorn" } -- tier 1 as well, but a bigger object

-- The keepOutAreas of the hand-written world: one sightline along z = 0, x in [325, 355].
local KEEP_OUTS = { { id = "ko_line", kind = "sightline", x = 340, z = 0, w = 30, d = 10 } }

local function makeWorld(): ThemeResolve.WorldLike
	local smallA = makeObject("small_a", 1, 2, "b_small_a")
	local midA = makeObject("mid_a", 2, 8, "b_mid_a")
	local midB = makeObject("mid_b", 2, 10, "b_mid_b")
	local streetA = makeObject("street_a", 4, 30, "b_street_a")
	streetA.assetKey = "mesh.street_a"
	return {
		worldId = "test_world",
		objects = { smallA, midA, midB, streetA },
		zones = {
			-- A plain zone: 24 non-slot placements, identical under every theme.
			{
				id = "plain",
				x = 0,
				z = 0,
				w = 96,
				d = 60,
				y = 0,
				mix = { { objectId = "small_a", weight = 1 }, { objectId = "mid_a", weight = 1 } },
				count = 24,
				seed = 7,
			},
			-- A slot zone: every placement is a slot, replaced per theme.
			{
				id = "slotz",
				x = 100,
				z = 0,
				w = 60,
				d = 40,
				y = 0,
				mix = { { objectId = "slot.small", weight = 1 } },
				count = 2,
				seed = 7,
			},
		},
		fixedPlacements = {
			{ id = "fp_ground", objectId = "mid_b", x = 200, y = 1, z = 0, yaw = 0.5 },
			{ id = "fp_slot", objectId = "slot.small", x = 210, y = 1, z = 0, yaw = 2.5 },
		},
		environment = { palette = { ["w-grass"] = { 11, 22, 33 }, ["w-wood"] = { 44, 55, 66 } } },
		themeBindings = {
			winter = {
				slots = SMALL_WINTER,
			},
			city = {
				slots = SMALL_CITY,
				objects = {
					makeObject("thorn", 1, 7, "c_thorn"),
					makeObject("fence", 1, 3, "c_fence"),
				},
				heroVariants = {
					street_a = { assetKey = "mesh.fountain", nameKey = "c.fountain", size = 32 },
				},
				overlays = {
					zones = {
						{
							id = "ov_city",
							x = 340,
							z = 30,
							w = 24,
							d = 16,
							y = 0,
							mix = { { objectId = "fence", weight = 1 } },
							count = 2,
							seed = 3,
						},
					},
					fixedPlacements = {
						{ id = "ov_fp", objectId = "fence", x = 385, y = 1, z = 0, yaw = 1.5 },
					},
				},
			},
		},
	}
end

local WINTER =
	{ id = "winter", palette = { ["w-snow"] = { 250, 250, 255 } }, lighting = { brightness = 2 } }
local CITY = {
	id = "city",
	palette = { ["w-asphalt"] = { 86, 90, 100 }, ["w-wood"] = { 1, 2, 3 } },
	lighting = { brightness = 3 },
}
local AUTUMN = { id = "autumn", palette = {}, lighting = { brightness = 1 } }

local function resolve(
	world: ThemeResolve.WorldLike,
	theme: ThemeResolve.ThemeLike
): ThemeResolve.Resolved
	return ThemeResolve.resolve(world, theme, Layout.expand)
end

local function expectError(fn: () -> (), needle: string)
	local ok, err = pcall(fn)
	expect.falsy(ok)
	local message = if type(err) == "string" then err else tostring(err)
	expect.truthy(
		string.find(message, needle, 1, true) ~= nil,
		`expected "{needle}" in the error message, got "{message}"`
	)
end

local function objectById(resolved: ThemeResolve.Resolved, id: string): ThemeResolve.ObjectLike
	for _, object in resolved.objects do
		if object.id == id then
			return object
		end
	end
	error(`no object {id} in the resolved list`)
end

local function countKeys(map: { [string]: boolean }): number
	local count = 0
	for _ in map do
		count += 1
	end
	return count
end

local function idList(resolved: ThemeResolve.Resolved): { string }
	local ids = {}
	for i, placement in resolved.placements do
		ids[i] = placement.id
	end
	return ids
end

-- ---------------------------------------------------------------- behaviour 1: no binding

test("missing themeBindings entry: error names the theme", function()
	expectError(function()
		resolve(makeWorld(), AUTUMN)
	end, "no binding for theme autumn")
end)

-- ---------------------------------------------------------------- behaviour 2: unmapped slot

test("slot with no mapping: error names the slot", function()
	local world = makeWorld()
	local bindings = table.clone(world.themeBindings :: any)
	bindings.city = { slots = {} }
	world.themeBindings = bindings
	expectError(function()
		resolve(world, CITY)
	end, "slot.small has no themeBindings mapping")
end)

test("slot mapped to an unknown object: error names the object", function()
	local world = makeWorld()
	local bindings = table.clone(world.themeBindings :: any)
	bindings.city = { slots = { ["slot.small"] = "ghost" } }
	world.themeBindings = bindings
	expectError(function()
		resolve(world, CITY)
	end, "unknown object ghost")
end)

-- ---------------------------------------------------------------- behaviour 3: mixed zone

test("zone mixing slot and non-slot ids: error", function()
	local world = makeWorld()
	world.themeBindings = table.clone(world.themeBindings :: any) -- same shape, fresh tables only
	table.insert(world.zones, {
		id = "mixed",
		x = 0,
		z = 200,
		w = 60,
		d = 20,
		y = 0,
		mix = { { objectId = "slot.small", weight = 1 }, { objectId = "mid_a", weight = 1 } },
		count = 1,
		seed = 1,
	})
	expectError(function()
		resolve(world, CITY)
	end, "zone mixed mixes slot and non-slot ids")
end)

-- ---------------------------------------------------------------- behaviour 4: slot tier

test("slot mapped to the wrong tier: error", function()
	local world = makeWorld()
	local bindings = table.clone(world.themeBindings :: any)
	bindings.city = { slots = { ["slot.small"] = "mid_a" } } -- tier 2, slot.small is tier 1
	world.themeBindings = bindings
	expectError(function()
		resolve(world, CITY)
	end, "slot.small is tier 1")
end)

-- ---------------------------------------------------------------- behaviour 5: no mutation

test("inputs are not mutated: the base world survives both themes", function()
	local world = makeWorld()
	local city = resolve(world, CITY)
	expect.equal(city.objects[4].assetKey :: string, "mesh.fountain") -- resolved copy is themed
	expect.equal(world.zones[2].mix[1].objectId, "slot.small")
	expect.equal(world.fixedPlacements[2].objectId, "slot.small")
	expect.equal(world.objects[4].assetKey :: string, "mesh.street_a") -- the base object is untouched
	expect.equal(table.concat(world.environment.palette["w-wood"], ","), "44,55,66")
	-- and the same world resolves the same theme again, unchanged
	local again = resolve(world, WINTER)
	expect.equal(again.placements[1].id, "plain_001")
	expect.equal(again.placements[28].id, "fp_slot")
	expect.equal(again.placements[28].objectId, "small_a")
end)

-- --------------------------------------------------- behaviour 6: order and stable base ids

test("output order: base zones, base fixed, overlay zones, overlay fixed", function()
	local city = resolve(makeWorld(), CITY)
	local ids = {}
	local expected = {}
	for i = 1, 24 do
		table.insert(expected, string.format("plain_%03d", i))
	end
	table.insert(expected, "slotz_001")
	table.insert(expected, "slotz_002")
	table.insert(expected, "fp_ground")
	table.insert(expected, "fp_slot")
	table.insert(expected, "ov_city_001")
	table.insert(expected, "ov_city_002")
	table.insert(expected, "ov_fp")
	for i, placement in city.placements do
		ids[i] = placement.id
	end
	expect.equal(#ids, 31)
	expect.same(ids, expected)
end)

test("base placement ids and non-slot placements are identical for every theme", function()
	local world = makeWorld()
	local winter = resolve(world, WINTER)
	local city = resolve(world, CITY)
	expect.equal(#winter.placements, 28)
	expect.equal(#city.placements, 31)
	-- The 28 base ids appear in both resolutions ...
	local baseIds = idList(winter)
	for i = 1, 28 do
		local id = baseIds[i]
		local found = nil
		for j = 1, #city.placements do
			if city.placements[j].id == id then
				found = j
				break
			end
		end
		expect.truthy(found ~= nil, `placement {id} missing from the city resolution`)
	end
	-- ... and the non-slot placements are bit-identical (id, objectId, x, y, z, yaw).
	local nonSlot = 0
	for _, placement in winter.placements do
		if city.slotPlacementIds[placement.id] == nil then
			nonSlot += 1
			for _, other in city.placements do
				if other.id == placement.id then
					expect.equal(other.id, placement.id)
					expect.equal(other.objectId, placement.objectId)
					expect.equal(other.x, placement.x)
					expect.equal(other.y, placement.y)
					expect.equal(other.z, placement.z)
					expect.equal(other.yaw, placement.yaw)
				end
			end
		end
	end
	expect.equal(nonSlot, 25) -- 24 plain-zone placements + the fixed non-slot one
end)

-- ------------------------------------------------------------- behaviour 7: hero variants

test("hero variant: a copy with art replaced, gameplay fields kept", function()
	local resolved = resolve(makeWorld(), CITY)
	local variant = objectById(resolved, "street_a")
	expect.equal(variant.assetKey :: string, "mesh.fountain")
	expect.equal(variant.nameKey :: string, "c.fountain")
	expect.equal(variant.id, "street_a")
	expect.equal(variant.tier, 4)
	expect.equal(variant.size, 30) -- the base size stays for gameplay
	expect.equal(variant.coins, 4)
	expect.equal(variant.bookId, "b_street_a")
end)

test("hero variant: unknown base id errors", function()
	local world = makeWorld()
	local bindings = table.clone(world.themeBindings :: any)
	bindings.city = { slots = SMALL_CITY, heroVariants = { ghost = { assetKey = "mesh.ghost" } } }
	world.themeBindings = bindings
	expectError(function()
		resolve(world, CITY)
	end, "hero variant for ghost names no base object")
end)

test("hero variant: size drift beyond 10% errors, exactly 10% passes", function()
	local world = makeWorld()
	world.themeBindings = table.clone(world.themeBindings :: any)
	local city = table.clone(world.themeBindings.city :: any)
	city.heroVariants = { street_a = { assetKey = "mesh.fountain", size = 34 } } -- 13.3%
	world.themeBindings.city = city
	expectError(function()
		resolve(world, CITY)
	end, "more than 10% off the base size")

	world.themeBindings = table.clone(world.themeBindings :: any)
	local exact = table.clone(world.themeBindings.city :: any)
	exact.heroVariants = { street_a = { assetKey = "mesh.fountain", size = 33 } } -- exactly 10%
	world.themeBindings.city = exact
	local resolved = resolve(world, CITY)
	expect.equal(objectById(resolved, "street_a").size, 30)
end)

-- ------------------------------------------------ behaviour 8: one expand call, resolved sizes

test("expand is called once, with the sizes of the resolved object list", function()
	local world = makeWorld()
	local calls = 0
	local seenSizes: { [string]: number }? = nil
	local seenZoneIds: { string }? = nil
	local resolved = ThemeResolve.resolve(world, CITY, function(zones, sizes)
		calls += 1
		seenSizes = table.clone(sizes)
		local ids = {}
		for i, zone in zones do
			ids[i] = zone.id
		end
		seenZoneIds = ids
		return {}
	end)
	expect.equal(calls, 1)
	expect.equal(seenSizes.thorn, 7) -- the city-only slot object sizes its slot zone
	expect.equal(seenSizes.small_a, 2) -- the winter object is still there
	expect.equal(seenSizes.street_a, 30) -- the variant keeps the base size for layout
	expect.equal(seenSizes.mid_b, 10)
	expect.same(seenZoneIds, { "plain", "slotz", "ov_city" })
	expect.equal(resolved.themeId, "city")
end)

-- ---------------------------------------------- invariants: ids, share, keep-outs, palette

test("resolved object ids are unique", function()
	local resolved = resolve(makeWorld(), CITY)
	local seen: { [string]: boolean } = {}
	for _, object in resolved.objects do
		expect.falsy(seen[object.id])
		seen[object.id] = true
	end
	expect.equal(#resolved.objects, 6) -- 4 base + 2 city-only
end)

test("themeId is set on the resolved result", function()
	expect.equal(resolve(makeWorld(), CITY).themeId, "city")
	expect.equal(resolve(makeWorld(), WINTER).themeId, "winter")
end)

test("slot share stays within the budget", function()
	local world = makeWorld()
	local winter = resolve(world, WINTER)
	local city = resolve(world, CITY)
	local cap = Config.Budgets.maxDressingSlotShare
	expect.equal(countKeys(winter.slotPlacementIds), 3) -- two slot-zone placements + the slot fixed one
	expect.equal(countKeys(city.slotPlacementIds), 3)
	local winterShare = countKeys(winter.slotPlacementIds) / #winter.placements
	local cityShare = countKeys(city.slotPlacementIds) / #city.placements
	expect.truthy(winterShare <= cap, `winter slot share {winterShare} exceeds {cap}`)
	expect.truthy(cityShare <= cap, `city slot share {cityShare} exceeds {cap}`)
end)

test("overlay placements are clear of the keepOutAreas", function()
	local world = makeWorld()
	local city = resolve(world, CITY)
	local overlays = 0
	for _, placement in city.placements do
		local zoneId = string.match(placement.id, "^(.-)_%d+$")
		local isOverlay = placement.id == "ov_fp" or zoneId == "ov_city"
		if isOverlay then
			overlays += 1
			local size = objectById(city, placement.objectId).size
			for _, out in KEEP_OUTS do
				local clearX = math.abs(placement.x - out.x) >= (size + out.w) / 2
				local clearZ = math.abs(placement.z - out.z) >= (size + out.d) / 2
				expect.truthy(
					clearX or clearZ,
					`overlay {placement.id} at ({placement.x}, {placement.z}) intersects {out.id}`
				)
			end
		end
	end
	expect.equal(overlays, 3)
end)

test("environment palette: base colours stay, theme colours win", function()
	local world = makeWorld()
	local winter = resolve(world, WINTER)
	local city = resolve(world, CITY)
	expect.equal(
		table.concat(winter.environmentPalette["w-grass"], ","),
		table.concat(world.environment.palette["w-grass"], ",")
	)
	expect.equal(table.concat(winter.environmentPalette["w-wood"], ","), "44,55,66")
	expect.equal(table.concat(city.environmentPalette["w-grass"], ","), "11,22,33") -- not a theme cell
	expect.equal(table.concat(city.environmentPalette["w-wood"], ","), "1,2,3") -- the theme palette wins
	expect.equal(city.environmentPalette["w-asphalt"][1], 86) -- a theme-only cell is present
end)
