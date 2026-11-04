--!strict
-- Main-Street slice world data (010, "vertical slice"). Data plus a build step: no Roblox APIs and no requires, so Lune
-- and the game load it the same way. The pure rules it needs (StreetRules, SceneKit), the kit and sign tables and the
-- Downtown world (whose object catalogue and size tiers the slice reuses) are handed to `build` by the caller
-- (Worlds.luau in the game, the unit tests in Lune). Everything is deterministic: no clock, only seeded generators.
-- Design: specs/010-main-street-slice/data-model.md and contracts/slice-world-and-flags.md.
--
-- Map (x east, z south, studs; the player starts at the -z end and rolls toward +z). The playable rectangle is
-- x in [-100, 100], z in [-250, 250]:
--   park        z in [-250, -130]  twelve spawns in one row, open lawn, picnics and flower beds
--   suburb      z in [-130,  -60]  the road begins, houses and lawns either side
--   main street z in [ -60,  170]  30-stud carriageway, 6-stud pavements, 14 shop facades, two cross streets
--   skyline     z in [ 170,  250]  tier 5 landmarks and the backdrop towers at the end of the street

export type Deps = {
	StreetRules: any,
	SceneKit: any,
	SceneKits: any,
	Signs: any,
	Downtown: any,
}

type Block = {
	id: string,
	kind: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
	swatch: string,
}
type Fixed = {
	id: string,
	objectId: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	spawnSlot: number?,
}

local MainStreetSlice = {}

local SIDES: { { name: string, sign: number } } = {
	{ name = "r", sign = 1 },
	{ name = "l", sign = -1 },
}

-- Tier ranges, the same as Downtown's (008 data-model §2 and §4).
local COIN_RANGE: { { number } } = { { 1, 2 }, { 3, 5 }, { 8, 15 }, { 20, 40 }, { 60, 100 } }
local SIZE_RANGE: { { number } } = {
	{ 0.3, 1.5 },
	{ 1.6, 4.0 },
	{ 4.0, 10.0 },
	{ 10.0, 25.0 },
	{ 25.0, 60.0 },
}

local HALF_X = 100
local HALF_Z = 250
local ROAD_X = 0
local ROAD_FROM = -130
local ROAD_TO = 170
local PAVEMENT_TOP = 0.4
local FACE_X = 31.6
local FRONTAGE = 24
local FACADE_Z = { -48, -24, 36, 60, 84, 134, 158 }
local FACADE_HEIGHT = { 14, 18, 16, 20, 15, 18, 22 }
local FACADE_DEPTH = 14
local SPAWN_Z = -238
local SPAWN_COUNT = 12

local function coinsFor(tier: number, size: number): number
	local coins, span = COIN_RANGE[tier], SIZE_RANGE[tier]
	local fraction = (size - span[1]) / (span[2] - span[1])
	return coins[1] + math.floor((coins[2] - coins[1]) * fraction + 0.5)
end

-- Objects that exist only in the slice (research R-08). Real meshes swap in later by changing `assetKey`.
local sliceCatalogue = {
	{
		id = "fruit_crate",
		tier = 1,
		size = 1.5,
		role = "w-accent-orange",
		shape = "Block",
		assetKey = "",
	},
	{
		id = "flower_pot",
		tier = 1,
		size = 1.2,
		role = "w-accent-red",
		shape = "Cylinder",
		assetKey = "",
	},
	{
		id = "picnic_blanket",
		tier = 2,
		size = 3.8,
		role = "w-accent-red",
		shape = "Block",
		assetKey = "",
	},
	{
		id = "awning",
		tier = 2,
		size = 3.5,
		role = "w-accent-blue",
		shape = "Block",
		assetKey = "",
	},
	{
		id = "road_barrier",
		tier = 3,
		size = 6,
		role = "w-accent-orange",
		shape = "Block",
		assetKey = "",
	},
	{
		id = "shop_front",
		tier = 3,
		size = 8,
		role = "w-wall-b",
		shape = "Block",
		assetKey = "dt_corner_shop_row",
	},
}

-- Seeded Park-Miller generator (the constants Layout and the rules use). Returns values in [0, 1).
local function generator(seed: number): () -> number
	local state = seed % 2147483646 + 1
	return function(): number
		state = state * 48271 % 2147483647
		return state / 2147483647
	end
end

function MainStreetSlice.build(deps: Deps): any
	local blocks: { Block } = {}
	local fixed: { Fixed } = {}

	local function block(
		id: string,
		x: number,
		y: number,
		z: number,
		sx: number,
		sy: number,
		sz: number,
		swatch: string,
		kind: string?
	)
		table.insert(blocks, {
			id = id,
			kind = kind or "Block",
			cframe = { x = x, y = y, z = z, yaw = 0 },
			size = { x = sx, y = sy, z = sz },
			swatch = swatch,
		})
	end

	-- A box standing on y0 with its footprint centred on (x, z).
	local function box(
		id: string,
		x: number,
		z: number,
		w: number,
		d: number,
		h: number,
		swatch: string,
		y0: number?
	)
		block(id, x, (y0 or 0) + h / 2, z, w, h, d, swatch)
	end

	local function put(
		id: string,
		objectId: string,
		x: number,
		y: number,
		z: number,
		yawDegrees: number
	)
		table.insert(fixed, {
			id = id,
			objectId = objectId,
			x = x,
			y = y,
			z = z,
			yaw = math.rad(yawDegrees),
			spawnSlot = nil,
		})
	end

	-- Ground and the invisible edge ------------------------------------------------------------------------------
	block("ms_ground", 0, -0.5, 0, 2 * HALF_X, 1, 2 * HALF_Z, "w-grass")
	block("ms_wall_e", HALF_X + 0.5, 50, 0, 1, 100, 2 * HALF_Z, "w-asphalt", "Boundary")
	block("ms_wall_w", -HALF_X - 0.5, 50, 0, 1, 100, 2 * HALF_Z, "w-asphalt", "Boundary")
	block("ms_wall_n", 0, 50, HALF_Z + 0.5, 2 * HALF_X + 2, 100, 1, "w-asphalt", "Boundary")
	block("ms_wall_s", 0, 50, -HALF_Z - 0.5, 2 * HALF_X + 2, 100, 1, "w-asphalt", "Boundary")
	block("ms_path", 0, 0.05, -190, 8, 0.1, 120, "w-sand")

	-- The street: one straight segment from the park gate to the skyline, two cross streets ----------------------
	local street = deps.StreetRules.expand({
		seed = 1010,
		segments = {
			{
				id = "ms_st",
				x0 = ROAD_X,
				z0 = ROAD_FROM,
				x1 = ROAD_X,
				z1 = ROAD_TO,
				width = 30,
				sidewalk = 6,
				yaw = 0,
			},
		},
		junctions = {
			{ id = "ms_j1", x = ROAD_X, z = 10, crossWidth = 14, reach = 80 },
			{ id = "ms_j2", x = ROAD_X, z = 110, crossWidth = 14, reach = 80 },
		},
		ids = {
			tree = "street_tree",
			lamp = "street_lamp",
			bin = "wheelie_bin",
			bench = "bench",
			car = "hatchback",
			hydrant = "fire_hydrant",
		},
		treeEvery = 18,
		lampEvery = 24,
		lampTreeClear = 4,
		jitterPos = 0.4,
		jitterYaw = 4,
	})
	for _, b in street.blocks do
		table.insert(blocks, b)
	end
	for _, p in street.placements do
		table.insert(fixed, p)
	end

	-- Forecourt pavement between the street pavement (x 21.6) and the building faces (x 31.6), cut at the cross streets.
	local forecourtRuns = { { -60, 3 }, { 17, 103 }, { 117, 170 } }
	for index, run in forecourtRuns do
		local mid, length = (run[1] + run[2]) / 2, run[2] - run[1]
		for _, side in SIDES do
			box(
				`ms_court_{side.name}_{index}`,
				side.sign * 26.6,
				mid,
				10,
				length,
				PAVEMENT_TOP,
				"w-sidewalk"
			)
		end
	end

	-- Facades: 14 shop buildings, face at |x| = 31.6, 24 studs of frontage each ----------------------------------
	local walls = { "w-wall-a", "w-wall-b", "w-wall-c" }
	local roofs = { "w-roof-a", "w-roof-b" }
	for _, side in SIDES do
		local name, sign = side.name, side.sign
		for index, z in FACADE_Z do
			local height = FACADE_HEIGHT[index]
			local centre = sign * (FACE_X + FACADE_DEPTH / 2)
			local pick = (index + (if sign == 1 then 0 else 1)) % #walls + 1
			box(`ms_fac_{name}_{index}`, centre, z, FACADE_DEPTH, FRONTAGE, height, walls[pick])
			box(
				`ms_roof_{name}_{index}`,
				centre,
				z,
				FACADE_DEPTH + 0.8,
				FRONTAGE + 0.8,
				0.6,
				roofs[index % #roofs + 1],
				height
			)
			-- Shop window and door on the ground floor, a second window row on the taller buildings.
			block(
				`ms_win_{name}_{index}`,
				sign * (FACE_X - 0.05),
				3.5,
				z - 3,
				0.1,
				3.6,
				12,
				"w-glass"
			)
			block(
				`ms_door_{name}_{index}`,
				sign * (FACE_X - 0.05),
				2.2,
				z + 8.5,
				0.1,
				4.4,
				3,
				"w-door"
			)
			if height >= 17 then
				block(
					`ms_upwin_{name}_{index}`,
					sign * (FACE_X - 0.05),
					14.5,
					z,
					0.1,
					2.4,
					16,
					"w-glass"
				)
			end
			-- The shop front and its awning stand on the forecourt, facing the street.
			local facing = if sign == 1 then 90 else 270
			put(`ms_shop_{name}_{index}`, "shop_front", sign * 26.6, PAVEMENT_TOP, z - 6, facing)
			put(`ms_awning_{name}_{index}`, "awning", sign * 26.6, PAVEMENT_TOP, z + 7.5, facing)
		end
	end

	-- Signs and billboards ---------------------------------------------------------------------------------------
	for _, slot in deps.Signs.signSlots do
		block(
			`{slot.id}_plate`,
			slot.x,
			slot.y,
			slot.z,
			0.3,
			3,
			10,
			deps.Signs.regionSwatch[slot.atlasRegion]
		)
	end
	for _, slot in deps.Signs.billboards do
		local onEnd = slot.yaw == 0 or slot.yaw == 180
		block(
			`{slot.id}_plate`,
			slot.x,
			slot.y,
			slot.z,
			if onEnd then 20 else 0.3,
			12,
			if onEnd then 0.3 else 20,
			deps.Signs.imageSwatch[slot.imageAsset]
		)
	end

	-- Towers: side towers (face at |x| = 82) and backdrop towers (face at z = 241) ------------------------------
	local towerHeights = { 52, 60, 56, 64 }
	for _, side in SIDES do
		local name, sign = side.name, side.sign
		for index, z in { -30, 45, 75, 135 } do
			box(
				`ms_tower_{name}_{index}`,
				sign * 90,
				z,
				16,
				24,
				towerHeights[(index + (if sign == 1 then 0 else 1) - 1) % #towerHeights + 1],
				"w-metal-dark"
			)
		end
	end
	box("ms_back_l", -30, 245.5, 36, 9, 70, "w-wall-c")
	box("ms_back_r", 30, 245.5, 36, 9, 70, "w-wall-b")

	-- Suburb: three houses either side of the road, behind the kit lots ---------------------------------------------
	for _, side in SIDES do
		local name, sign = side.name, side.sign
		for index, z in { -112, -90, -68 } do
			local x = sign * 64
			box(`ms_house_{name}_{index}`, x, z, 16, 18, 10, walls[(index + 1) % #walls + 1])
			box(`ms_house_roof_{name}_{index}`, x, z, 17, 19, 0.6, roofs[index % #roofs + 1], 10)
			block(
				`ms_house_door_{name}_{index}`,
				sign * (64 - 8 - 0.05),
				2.2,
				z,
				0.1,
				4.4,
				3,
				"w-door"
			)
		end
	end

	-- Scene kits: every one of the ten at least once --------------------------------------------------------------
	local bounds = { minX = -98, maxX = 98, minZ = -248, maxZ = 248 }
	local kitCount = 0
	local function kit(kitId: string, x: number, z: number, yaw: number, y: number?)
		kitCount += 1
		local placed = deps.SceneKit.expand(
			deps.SceneKits.kits[kitId],
			{ kitId = kitId, ox = x, oz = z, yaw = yaw, seed = 500 + kitCount, y = y or 0 },
			`ms_kit_{kitCount}_{kitId}`,
			bounds
		)
		for _, p in placed do
			table.insert(fixed, p)
		end
	end
	-- Park lawn.
	kit("picnic_spread", -30, -190, 0)
	kit("picnic_spread", 32, -176, 20)
	kit("picnic_spread", -62, -152, 340)
	kit("flower_bed", 52, -205, 0)
	kit("flower_bed", -52, -205, 0)
	kit("yard_sale", 70, -150, 0)
	kit("yard_sale", -70, -150, 0)
	-- Suburb corner: lots between the road pavement and the houses; the kit front faces the road.
	kit("car_park_rows", 44, -112, 90)
	kit("bus_stop", 44, -86, 90)
	kit("fruit_stall", 44, -68, 90)
	kit("cafe_terrace", -44, -118, 270)
	kit("recycling_point", -44, -102, 270)
	kit("road_works", -44, -86, 270)
	kit("yard_sale", -44, -68, 270)
	-- Main street forecourts, in the gaps between facades: bike racks by the first cross street, flower beds beside
	-- both cross streets.
	kit("bike_rack", 26.6, -4.5, 90, PAVEMENT_TOP)
	kit("bike_rack", -26.6, -4.5, 270, PAVEMENT_TOP)
	kit("flower_bed", 26.6, 22, 90, PAVEMENT_TOP)
	kit("flower_bed", -26.6, 22, 270, PAVEMENT_TOP)
	kit("flower_bed", 26.6, 99, 90, PAVEMENT_TOP)
	kit("flower_bed", -26.6, 99, 270, PAVEMENT_TOP)

	-- Park: trees, a fountain and a kiosk -------------------------------------------------------------------------
	for index, at in
		{ { -84, -200 }, { 84, -196 }, { -88, -162 }, { 90, -150 }, { -40, -140 }, { 44, -138 } }
	do
		put(`ms_park_tree_{index}`, "street_tree", at[1], 0, at[2], 0)
	end
	put("ms_park_fountain", "fountain", 0, 0, -170, 0)
	put("ms_park_kiosk", "kiosk", 62, 0, -190, 0)
	put("ms_park_bench_1", "bench", -12, 0, -170, 90)
	put("ms_park_bench_2", "bench", 12, 0, -170, 270)

	-- Spawns: one row in the park, 16 studs apart, facing +z. A tier 1 trail runs ahead of each. -------------------
	local spawnPoints = {}
	local trailIds = {
		"bottle_cap",
		"soda_can",
		"tennis_ball",
		"donut",
		"water_bottle",
		"pizza_slice",
		"coffee_cup",
		"puzzle_cube",
	}
	for slot = 1, SPAWN_COUNT do
		local x = -88 + (slot - 1) * 16
		table.insert(spawnPoints, { slot = slot, x = x, y = 0, z = SPAWN_Z, yaw = 0 })
		for step, id in trailIds do
			local ahead = 4 + (step - 1) * 1.8
			local sway = if step % 2 == 0 then 1.8 else -1.8
			table.insert(fixed, {
				id = `ms_trail_{slot}_{step}`,
				objectId = id,
				x = x + sway,
				y = 0,
				z = SPAWN_Z + ahead,
				yaw = math.rad(step * 37 % 360),
				spawnSlot = slot,
			})
		end
	end

	-- Scattered loose items on the lawns (seeded) -----------------------------------------------------------------
	local function scatter(
		prefix: string,
		ids: { string },
		count: number,
		x0: number,
		x1: number,
		z0: number,
		z1: number,
		seed: number,
		y: number?
	)
		local rand = generator(seed)
		for index = 1, count do
			local x = x0 + rand() * (x1 - x0)
			local z = z0 + rand() * (z1 - z0)
			local yaw = rand() * 360
			put(`{prefix}_{index}`, ids[(index - 1) % #ids + 1], x, y or 0, z, yaw)
		end
	end
	local tier1 = {
		"aa_battery",
		"earbud_case",
		"smartphone",
		"game_controller",
		"headphones",
		"basketball",
		"takeout_box",
		"lost_sneaker",
		"keyboard",
		"rubber_duck_sunglasses",
		"bottle_cap",
		"soda_can",
		"tennis_ball",
		"donut",
	}
	local tier2 = {
		"boombox_speaker",
		"traffic_cone",
		"skateboard",
		"suitcase",
		"acoustic_guitar",
		"newspaper_box",
		"inflatable_flamingo",
		"spinning_office_chair",
		"wheelie_bin",
		"shopping_cart",
		"e_scooter",
		"pizza_box_tower",
		"picnic_blanket",
	}
	local tier3 = {
		"mailbox",
		"satellite_dish",
		"drum_kit",
		"pallet_stack",
		"moped",
		"arcade_cabinet",
		"vending_machine",
		"hot_dog_cart",
		"road_barrier",
	}
	scatter("ms_sc1_park", tier1, 70, -94, 94, -214, -134, 11)
	scatter("ms_sc2_park", tier2, 36, -94, 94, -214, -134, 12)
	scatter("ms_sc3_park", tier3, 12, -94, 94, -214, -134, 13)
	scatter("ms_sc1_subr", tier1, 14, 76, 94, -126, -66, 14)
	scatter("ms_sc1_subl", tier1, 14, -94, -76, -126, -66, 15)
	scatter("ms_sc2_subr", tier2, 10, 76, 94, -126, -66, 16)
	scatter("ms_sc2_subl", tier2, 10, -94, -76, -126, -66, 17)
	scatter("ms_sc3_subr", tier3, 5, 76, 94, -126, -66, 18)
	scatter("ms_sc3_subl", tier3, 5, -94, -76, -126, -66, 19)

	-- Main street: small litter on the pavements and forecourts, clear of the cross streets.
	local streetRuns = { { -56, 0 }, { 22, 100 }, { 122, 166 } }
	for index, run in streetRuns do
		scatter(`ms_sc1_stR{index}`, tier1, 18, 22, 31, run[1], run[2], 30 + index, PAVEMENT_TOP)
		scatter(`ms_sc1_stL{index}`, tier1, 18, -31, -22, run[1], run[2], 40 + index, PAVEMENT_TOP)
		scatter(`ms_sc2_stR{index}`, tier2, 6, 22, 31, run[1], run[2], 50 + index, PAVEMENT_TOP)
		scatter(`ms_sc2_stL{index}`, tier2, 6, -31, -22, run[1], run[2], 60 + index, PAVEMENT_TOP)
	end

	-- Tier 4: vehicles and stalls in the suburb and the street lots -------------------------------------------------
	put("ms_veh_1", "delivery_van", 90, 0, -118, 270)
	put("ms_veh_2", "donut_food_truck", -90, 0, -118, 90)
	put("ms_veh_3", "corner_bakery", 80, 0, 100, 270)
	put("ms_veh_4", "shipping_container", -80, 0, 104, 90)

	-- Skyline landmarks (tier 5), all at z >= 170 ------------------------------------------------------------------
	put("ms_sky_1", "glass_tower", -78, 0, 214, 0)
	put("ms_sky_2", "ferris_wheel", 0, 0, 212, 0)
	put("ms_sky_3", "tower_crane", 75, 0, 214, 0)
	put("ms_sky_4", "corner_shop_row", -48, 0, 180, 0)
	put("ms_sky_5", "corner_shop_row", 48, 0, 180, 0)

	-- Objects: Downtown's catalogue entries the slice uses, then the slice-only ones -----------------------------
	local used: { [string]: boolean } = {}
	for _, p in fixed do
		used[p.objectId] = true
	end
	local downtownById: { [string]: any } = {}
	for _, object in deps.Downtown.objects do
		downtownById[object.id] = object
	end
	local objects: { any } = {}
	for _, object in deps.Downtown.objects do
		if used[object.id] then
			table.insert(objects, object)
		end
	end
	for _, entry in sliceCatalogue do
		table.insert(objects, {
			id = entry.id,
			tier = entry.tier,
			size = entry.size,
			coins = coinsFor(entry.tier, entry.size),
			bookId = "slice." .. entry.id,
			nameKey = "object.slice." .. entry.id,
			icon = "cube",
			assetKey = entry.assetKey,
			fallback = entry.shape,
			shade = nil,
			role = entry.role,
		})
		downtownById[entry.id] = objects[#objects]
	end
	for _, p in fixed do
		if downtownById[p.objectId] == nil then
			error(`MainStreetSlice: placement {p.id} uses unknown object {p.objectId}`)
		end
	end

	-- Ambient pigeons on the forecourts and the park lawn (no traffic: the street is a stage, not a road).
	local pigeons = {
		{ district = "Park", x = -20, z = -205 },
		{ district = "Park", x = 16, z = -196 },
		{ district = "Park", x = -34, z = -152 },
		{ district = "Main Street", x = 25, z = 40 },
		{ district = "Main Street", x = -25, z = 55 },
		{ district = "Main Street", x = 24, z = 125 },
		{ district = "Main Street", x = -25, z = 142 },
	}

	local downtown = deps.Downtown
	return {
		worldId = "main_street_slice",
		starThresholds = downtown.starThresholds,
		growthK = downtown.growthK,
		halfExtent = HALF_Z,
		outerHalfExtent = 300,
		sizeTiers = downtown.sizeTiers,
		objects = objects,
		zones = {},
		fixedPlacements = fixed,
		spawnPoints = spawnPoints,
		activeThemeId = "city",
		supportedThemes = { "city" },
		themeBindings = {
			city = {
				slots = {},
				overlays = { zones = {}, fixedPlacements = {} },
				heroVariants = {},
			},
		},
		maxPlacements = 1200,
		environment = { palette = {}, blocks = blocks, markers = {} },
		hub = {
			center = { x = -400, z = 0 },
			halfExtent = 24,
			spawn = { x = 0, z = 0 },
			padRadius = 5,
			assetKey = "hub",
		},
		lighting = downtown.lighting,
		ambient = { pigeons = pigeons },
	}
end

return MainStreetSlice
