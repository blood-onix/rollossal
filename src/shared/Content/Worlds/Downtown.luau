--!strict
-- Downtown world data (007). Data only: no Roblox APIs and no requires, so Lune can load it directly.
-- Shape: the WorldDef type in Content/GreyBoxRoom.luau; checked against it in Worlds.luau.
-- Design: specs/007-downtown-holiday-city/data-model.md, contracts/world-content.md (invariants C1 to C18).
-- Everything is built once at require time by plain loops over the tables below: no clock, no randomness.
--
-- Map (x east, z south, studs). The playable square is 600 x 600.
--   * Skyline Block: z -300 to -220 (north band). Waterfront: z 220 to 300 (south band).
--   * Spawn streets at z = -135 (slots 1 to 6) and z = 135 (slots 7 to 12); three doorsteps per quadrant.
--   * Sidewalk and alley strip: |z| 160 to 220, with the 4-stud alleys cut through the building rows.
--   * Interior: Park (west), Construction Site (north-east), Car Park (south-east), Market Street along z = 0,
--     the Plaza (centre) with its fountain, and the storm-drain tunnel at x = -100.

type Shape = "Block" | "Ball" | "Cylinder"

-- tier, id, size (longest side), fallback shape, w-* role, hero. Heroes are the 14 in the design list.
local catalogue: { { tier: number, id: string, size: number, shape: Shape, role: string, hero: boolean } } =
	{
		{
			tier = 1,
			id = "bottle_cap",
			size = 0.3,
			shape = "Cylinder",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 1,
			id = "aa_battery",
			size = 0.4,
			shape = "Cylinder",
			role = "w-accent-yellow",
			hero = false,
		},
		{
			tier = 1,
			id = "earbud_case",
			size = 0.5,
			shape = "Block",
			role = "w-white",
			hero = false,
		},
		{
			tier = 1,
			id = "puzzle_cube",
			size = 0.5,
			shape = "Block",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 1,
			id = "soda_can",
			size = 0.6,
			shape = "Cylinder",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 1,
			id = "tennis_ball",
			size = 0.6,
			shape = "Ball",
			role = "w-accent-yellow",
			hero = false,
		},
		{
			tier = 1,
			id = "coffee_cup",
			size = 0.7,
			shape = "Cylinder",
			role = "w-white",
			hero = false,
		},
		{
			tier = 1,
			id = "donut",
			size = 0.8,
			shape = "Cylinder",
			role = "w-accent-pink",
			hero = false,
		},
		{
			tier = 1,
			id = "smartphone",
			size = 0.8,
			shape = "Block",
			role = "w-rubber",
			hero = false,
		},
		{
			tier = 1,
			id = "water_bottle",
			size = 0.9,
			shape = "Cylinder",
			role = "w-accent-blue",
			hero = false,
		},
		{
			tier = 1,
			id = "pizza_slice",
			size = 0.9,
			shape = "Block",
			role = "w-sand",
			hero = false,
		},
		{
			tier = 1,
			id = "game_controller",
			size = 0.9,
			shape = "Block",
			role = "w-accent-teal",
			hero = false,
		},
		{
			tier = 1,
			id = "headphones",
			size = 1.0,
			shape = "Block",
			role = "w-accent-teal",
			hero = false,
		},
		{
			tier = 1,
			id = "basketball",
			size = 1.0,
			shape = "Ball",
			role = "w-accent-orange",
			hero = false,
		},
		{
			tier = 1,
			id = "takeout_box",
			size = 1.2,
			shape = "Block",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 1,
			id = "rubber_duck_sunglasses",
			size = 1.2,
			shape = "Ball",
			role = "w-accent-yellow",
			hero = true,
		},
		{
			tier = 1,
			id = "lost_sneaker",
			size = 1.3,
			shape = "Block",
			role = "w-accent-red",
			hero = true,
		},
		{ tier = 1, id = "keyboard", size = 1.5, shape = "Block", role = "w-rubber", hero = false },

		{
			tier = 2,
			id = "boombox_speaker",
			size = 2.0,
			shape = "Block",
			role = "w-accent-teal",
			hero = false,
		},
		{
			tier = 2,
			id = "traffic_cone",
			size = 2.0,
			shape = "Cylinder",
			role = "w-accent-orange",
			hero = false,
		},
		{ tier = 2, id = "skateboard", size = 2.2, shape = "Block", role = "w-wood", hero = false },
		{
			tier = 2,
			id = "fire_hydrant",
			size = 2.4,
			shape = "Cylinder",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 2,
			id = "suitcase",
			size = 2.6,
			shape = "Block",
			role = "w-accent-blue",
			hero = false,
		},
		{
			tier = 2,
			id = "acoustic_guitar",
			size = 3.0,
			shape = "Block",
			role = "w-wood",
			hero = false,
		},
		{
			tier = 2,
			id = "newspaper_box",
			size = 3.0,
			shape = "Block",
			role = "w-accent-blue",
			hero = false,
		},
		{
			tier = 2,
			id = "inflatable_flamingo",
			size = 3.0,
			shape = "Ball",
			role = "w-accent-pink",
			hero = true,
		},
		{
			tier = 2,
			id = "potted_palm",
			size = 3.2,
			shape = "Cylinder",
			role = "w-leaf",
			hero = false,
		},
		{
			tier = 2,
			id = "spinning_office_chair",
			size = 3.4,
			shape = "Cylinder",
			role = "w-accent-teal",
			hero = true,
		},
		{
			tier = 2,
			id = "wheelie_bin",
			size = 3.5,
			shape = "Block",
			role = "w-metal-dark",
			hero = false,
		},
		{
			tier = 2,
			id = "shopping_cart",
			size = 3.6,
			shape = "Block",
			role = "w-metal",
			hero = false,
		},
		{
			tier = 2,
			id = "e_scooter",
			size = 3.8,
			shape = "Block",
			role = "w-accent-blue",
			hero = false,
		},
		{
			tier = 2,
			id = "parking_meter",
			size = 3.8,
			shape = "Cylinder",
			role = "w-metal-dark",
			hero = false,
		},
		{
			tier = 2,
			id = "pizza_box_tower",
			size = 3.9,
			shape = "Block",
			role = "w-white",
			hero = true,
		},

		{
			tier = 3,
			id = "mailbox",
			size = 4.5,
			shape = "Block",
			role = "w-accent-blue",
			hero = false,
		},
		{
			tier = 3,
			id = "satellite_dish",
			size = 5.0,
			shape = "Cylinder",
			role = "w-white",
			hero = false,
		},
		{
			tier = 3,
			id = "drum_kit",
			size = 5.0,
			shape = "Cylinder",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 3,
			id = "pallet_stack",
			size = 5.0,
			shape = "Block",
			role = "w-wood",
			hero = false,
		},
		{
			tier = 3,
			id = "picnic_table",
			size = 6.0,
			shape = "Block",
			role = "w-wood",
			hero = false,
		},
		{
			tier = 3,
			id = "recycling_bank",
			size = 6.0,
			shape = "Block",
			role = "w-accent-teal",
			hero = false,
		},
		{
			tier = 3,
			id = "moped",
			size = 6.0,
			shape = "Block",
			role = "w-accent-orange",
			hero = false,
		},
		{
			tier = 3,
			id = "bicycle",
			size = 6.5,
			shape = "Block",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 3,
			id = "arcade_cabinet",
			size = 6.5,
			shape = "Block",
			role = "w-accent-teal",
			hero = true,
		},
		{ tier = 3, id = "bench", size = 7.0, shape = "Block", role = "w-wood", hero = false },
		{
			tier = 3,
			id = "vending_machine",
			size = 7.0,
			shape = "Block",
			role = "w-accent-red",
			hero = true,
		},
		{
			tier = 3,
			id = "hot_dog_cart",
			size = 7.5,
			shape = "Block",
			role = "w-accent-yellow",
			hero = false,
		},
		{
			tier = 3,
			id = "street_tree",
			size = 9.0,
			shape = "Cylinder",
			role = "w-leaf",
			hero = false,
		},
		{
			tier = 3,
			id = "inflatable_tube_guy",
			size = 9.0,
			shape = "Cylinder",
			role = "w-accent-red",
			hero = true,
		},
		{
			tier = 3,
			id = "street_lamp",
			size = 9.5,
			shape = "Cylinder",
			role = "w-metal-dark",
			hero = false,
		},
		{
			tier = 3,
			id = "traffic_light",
			size = 9.8,
			shape = "Cylinder",
			role = "w-metal-dark",
			hero = false,
		},

		{
			tier = 4,
			id = "bus_shelter",
			size = 10,
			shape = "Block",
			role = "w-glass",
			hero = false,
		},
		{ tier = 4, id = "kiosk", size = 12, shape = "Block", role = "w-wall-c", hero = false },
		{ tier = 4, id = "fountain", size = 13, shape = "Cylinder", role = "w-kerb", hero = false },
		{
			tier = 4,
			id = "hatchback",
			size = 14,
			shape = "Block",
			role = "w-accent-blue",
			hero = false,
		},
		{
			tier = 4,
			id = "taxi",
			size = 14,
			shape = "Block",
			role = "w-accent-yellow",
			hero = false,
		},
		{
			tier = 4,
			id = "pickup_truck",
			size = 16,
			shape = "Block",
			role = "w-accent-orange",
			hero = false,
		},
		{
			tier = 4,
			id = "delivery_van",
			size = 17,
			shape = "Block",
			role = "w-white",
			hero = false,
		},
		{
			tier = 4,
			id = "donut_food_truck",
			size = 18,
			shape = "Block",
			role = "w-accent-pink",
			hero = true,
		},
		{
			tier = 4,
			id = "billboard",
			size = 18,
			shape = "Block",
			role = "w-metal-dark",
			hero = false,
		},
		{
			tier = 4,
			id = "monster_truck",
			size = 18,
			shape = "Block",
			role = "w-accent-teal",
			hero = true,
		},
		{
			tier = 4,
			id = "shipping_container",
			size = 20,
			shape = "Block",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 4,
			id = "big_street_tree",
			size = 20,
			shape = "Cylinder",
			role = "w-leaf",
			hero = false,
		},
		{
			tier = 4,
			id = "garbage_truck",
			size = 20,
			shape = "Block",
			role = "w-accent-teal",
			hero = false,
		},
		{
			tier = 4,
			id = "corner_bakery",
			size = 22,
			shape = "Block",
			role = "w-wall-b",
			hero = false,
		},
		{
			tier = 4,
			id = "fire_engine",
			size = 24,
			shape = "Block",
			role = "w-accent-red",
			hero = false,
		},
		{
			tier = 4,
			id = "city_bus",
			size = 25,
			shape = "Block",
			role = "w-accent-red",
			hero = false,
		},

		{
			tier = 5,
			id = "corner_shop_row",
			size = 26,
			shape = "Block",
			role = "w-wall-a",
			hero = false,
		},
		{ tier = 5, id = "townhouse", size = 30, shape = "Block", role = "w-wall-a", hero = false },
		{
			tier = 5,
			id = "ev_charging_station",
			size = 32,
			shape = "Block",
			role = "w-white",
			hero = false,
		},
		{
			tier = 5,
			id = "rocket_water_tower",
			size = 34,
			shape = "Cylinder",
			role = "w-metal",
			hero = true,
		},
		{ tier = 5, id = "cinema", size = 36, shape = "Block", role = "w-wall-c", hero = false },
		{
			tier = 5,
			id = "apartment_block",
			size = 40,
			shape = "Block",
			role = "w-wall-a",
			hero = false,
		},
		{
			tier = 5,
			id = "ferris_wheel",
			size = 50,
			shape = "Cylinder",
			role = "w-metal",
			hero = true,
		},
		{
			tier = 5,
			id = "tower_crane",
			size = 55,
			shape = "Block",
			role = "w-accent-yellow",
			hero = true,
		},
		{ tier = 5, id = "glass_tower", size = 60, shape = "Block", role = "w-glass", hero = true },
	}

-- Coin ranges and the object size range of each tier (data-model.md §2 and §4).
local coinRange: { { number } } = { { 1, 2 }, { 3, 5 }, { 8, 15 }, { 20, 40 }, { 60, 100 } }
local sizeRange: { { number } } = {
	{ 0.3, 1.5 },
	{ 1.6, 4.0 },
	{ 4.0, 10.0 },
	{ 10.0, 25.0 },
	{ 25.0, 60.0 },
}

local function coinsFor(tier: number, size: number): number
	local coins = coinRange[tier]
	local span = sizeRange[tier]
	local fraction = (size - span[1]) / (span[2] - span[1])
	return coins[1] + math.floor((coins[2] - coins[1]) * fraction + 0.5)
end

local function objectDef(
	tier: number,
	id: string,
	size: number,
	shape: Shape,
	role: string
): {
	id: string,
	tier: number,
	size: number,
	coins: number,
	bookId: string,
	nameKey: string,
	icon: string,
	assetKey: string?,
	fallback: string?,
	shade: number?,
	role: string?,
}
	return {
		id = id,
		tier = tier,
		size = size,
		coins = coinsFor(tier, size),
		bookId = "downtown." .. id,
		nameKey = "object.downtown." .. id,
		icon = "cube",
		assetKey = "dt_" .. id,
		fallback = shape,
		shade = nil,
		role = role,
	}
end

local objects = {}
for _, entry in catalogue do
	table.insert(objects, objectDef(entry.tier, entry.id, entry.size, entry.shape, entry.role))
end

local minDiameters = { 2, 5, 12, 30, 70 }
local sizeTiers = {}
for tier = 1, 5 do
	table.insert(sizeTiers, {
		tier = tier,
		nameKey = `tier.downtown.{tier}.name`,
		minDiameter = minDiameters[tier],
		maxDiameter = minDiameters[tier + 1],
		headlineKey = `tier.downtown.{tier}.headline`,
		headlineIcon = "cube",
		-- No tier reward at launch (D6): cosmetics are Features 006a and 006b.
		reward = nil,
	})
end

-- Zone, fixed placement, block and marker builders ------------------------------------------------------------

type MixEntry = { objectId: string, weight: number }
type Zone = {
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	mix: { MixEntry },
	count: number,
	seed: number,
	spawnSlot: number?,
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
type Block = {
	id: string,
	kind: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
	swatch: string,
}
type Marker = {
	id: string,
	kind: string,
	subKind: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	waypoints: { { x: number, z: number } }?,
}
type KeepOut = {
	id: string,
	kind: "gate" | "shortcut" | "sightline" | "marker",
	x: number,
	z: number,
	w: number,
	d: number,
}

local zones: { Zone } = {}
local fixedPlacements: { Fixed } = {}
local blocks: { Block } = {}
local markers: { Marker } = {}
local keepOutAreas: { KeepOut } = {}

local function mix(ids: { string }, weight: number?): { MixEntry }
	local entries = {}
	for _, id in ids do
		table.insert(entries, { objectId = id, weight = weight or 1 })
	end
	return entries
end

local function idsOfTier(tier: number, skipHeroes: boolean?, from: number?, to: number?): { string }
	local ids = {}
	for _, entry in catalogue do
		if
			entry.tier == tier
			and not (skipHeroes and entry.hero)
			and entry.size >= (from or 0)
			and entry.size <= (to or math.huge)
		then
			table.insert(ids, entry.id)
		end
	end
	return ids
end

local function zone(
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	entries: { MixEntry },
	count: number,
	seed: number,
	spawnSlot: number?
)
	if count < 1 then
		return
	end
	table.insert(zones, {
		id = id,
		x = x,
		z = z,
		w = w,
		d = d,
		y = y,
		mix = entries,
		count = count,
		seed = seed,
		spawnSlot = spawnSlot,
	})
end

local heroIds: { [string]: boolean } = {}
for _, entry in catalogue do
	heroIds[entry.id] = entry.hero
end

local function fixed(id: string, objectId: string, x: number, z: number, yaw: number?)
	table.insert(
		fixedPlacements,
		{ id = id, objectId = objectId, x = x, y = 0, z = z, yaw = yaw or 0, spawnSlot = nil }
	)
end

local function block(
	id: string,
	kind: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	sx: number,
	sy: number,
	sz: number,
	swatch: string
)
	table.insert(blocks, {
		id = id,
		kind = kind,
		cframe = { x = x, y = y, z = z, yaw = yaw },
		size = { x = sx, y = sy, z = sz },
		swatch = swatch,
	})
end

-- A box standing on the ground (or on y0): centre x, z, footprint w x d, height h.
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
	block(id, "Block", x, (y0 or 0) + h / 2, z, 0, w, h, d, swatch)
end

local function keepOut(
	id: string,
	kind: "gate" | "shortcut" | "sightline" | "marker",
	x: number,
	z: number,
	w: number,
	d: number
)
	table.insert(keepOutAreas, { id = id, kind = kind, x = x, z = z, w = w, d = d })
end

-- Spawns and doorsteps --------------------------------------------------------------------------------------------
-- Twelve doorsteps on the two spawn streets, slots 1 to 12 clockwise from the north-west (data-model.md §6).
-- Every doorstep holds 32 core Tier 1 objects and 8 slot.small objects within 10 studs of its spawn point, in a
-- 14 x 14 square (the corner is 9.9 studs away). The square is split into the core rectangle A and the slot
-- rectangle B so that the two zones never overlap.

local PORCH = 0.6
-- Zone counts that set the growth pace, solved with tests/unit/Pace.test (research R-08). Tuning these (and
-- growthK) is how the pace windows are met; the layout itself does not change.
local TUNE = {
	crumbs = 2,
	walkIn = 7,
	walkOut = 4,
	walkIn1 = 8,
	walkIn2 = 1,
	walkIn3 = 10,
	walkIn4 = 3,
	walkIn5 = 4,
	walkIn6 = 14,
	walkIn7 = 8,
	walkIn8 = 10,
	walkIn9 = 1,
	walkIn10 = 3,
	walkIn11 = 5,
	walkIn12 = 5,
	walkOut1 = 5,
	walkOut2 = 0,
	walkOut3 = 5,
	walkOut4 = 3,
	walkOut5 = 2,
	walkOut6 = 0,
	walkOut7 = 9,
	walkOut8 = 0,
	walkOut9 = 3,
	walkOut10 = 5,
	walkOut11 = 8,
	walkOut12 = 1,
	parkW = 11,
	parkE = 3,
	site = 10,
	car = 4,
	stripN2 = 1,
	stripS2 = 4,
	stripN3 = 4,
	stripS3 = 1,
	stripN4 = 3,
	stripS4 = 3,
	stripN5 = 0,
	stripS5 = 4,
	block = 4,
	marketRow = 6,
	ringStep = 7,
	skyW = 0,
	watW = 8,
}
-- Per-doorstep walk-in and walk-out counts (slot 1 to 12), so each spawn can be tuned on its own.
local WALK_IN = {
	TUNE.walkIn1,
	TUNE.walkIn2,
	TUNE.walkIn3,
	TUNE.walkIn4,
	TUNE.walkIn5,
	TUNE.walkIn6,
	TUNE.walkIn7,
	TUNE.walkIn8,
	TUNE.walkIn9,
	TUNE.walkIn10,
	TUNE.walkIn11,
	TUNE.walkIn12,
}
local WALK_OUT = {
	TUNE.walkOut1,
	TUNE.walkOut2,
	TUNE.walkOut3,
	TUNE.walkOut4,
	TUNE.walkOut5,
	TUNE.walkOut6,
	TUNE.walkOut7,
	TUNE.walkOut8,
	TUNE.walkOut9,
	TUNE.walkOut10,
	TUNE.walkOut11,
	TUNE.walkOut12,
}
local SPAWN_Z = 135
local spawnXs = { -250, -190, -130, 130, 190, 250, 250, 190, 130, -130, -190, -250 }

local spawnPoints = {}
local spawns: { { slot: number, x: number, z: number, inward: number } } = {}
for slot = 1, 12 do
	local north = slot <= 6
	local sz = if north then -SPAWN_Z else SPAWN_Z
	table.insert(spawnPoints, {
		slot = slot,
		x = spawnXs[slot],
		y = PORCH,
		z = sz,
		-- Facing the middle of town: +Z for the north street, -Z for the south one.
		yaw = if north then 0 else 180,
	})
	table.insert(
		spawns,
		{ slot = slot, x = spawnXs[slot], z = sz, inward = if north then 1 else -1 }
	)
end

local t1Core = idsOfTier(1)
local t1Large = idsOfTier(1, false, 0.8)
local t2Core = idsOfTier(2)
local t2Small = idsOfTier(2, false, 0, 3.0)
local t3Small = idsOfTier(3, true, 0, 7.5)

-- Seeds: slot * 100 + offset keeps each zone independent (editing one moves only its own objects).
for _, spawn in spawns do
	local slot, sx, sz, inward = spawn.slot, spawn.x, spawn.z, spawn.inward
	local function off(distance: number): number
		return sz + inward * distance
	end
	local name = string.format("dt_z_door_%02d", slot)
	zone(name .. "_a", sx, off(-2.5), 14, 9, PORCH, mix(t1Core), 32, slot * 100 + 1, slot)
	zone(name .. "_b", sx, off(4.5), 14, 5, PORCH, mix({ "slot.small" }), 8, slot * 100 + 2, slot)
	zone(name .. "_crumbs", sx, off(12), 56, 4, 0, mix(t1Large), TUNE.crumbs, slot * 100 + 6, nil)
	zone(
		name .. "_walk_in",
		sx,
		off(20),
		56,
		12,
		0,
		mix(t2Core),
		WALK_IN[slot],
		slot * 100 + 3 + (if slot == 3 then 80 else 0),
		nil
	)
	zone(name .. "_slot", sx, off(28.5), 56, 4, 0, mix({ "slot.medium" }), 2, slot * 100 + 4, nil)
	zone(
		name .. "_walk_out",
		sx,
		off(-20),
		56,
		12,
		0,
		mix(t2Core),
		WALK_OUT[slot],
		slot * 100 + 5,
		nil
	)
end

-- Heroes of Tiers 1 and 2 stand in the free 7-stud band between the doorstep and the outer sidewalk.
local function bandHero(slot: number, objectId: string)
	local spawn = spawns[slot]
	fixed("dt_h_" .. objectId, objectId, spawn.x - 15, spawn.z - spawn.inward * 10.5, 0)
end
bandHero(2, "rubber_duck_sunglasses")
bandHero(8, "lost_sneaker")
bandHero(5, "inflatable_flamingo")
bandHero(11, "spinning_office_chair")
bandHero(1, "pizza_box_tower")

-- Districts ----------------------------------------------------------------------------------------------------------

local function fixedAt(id: string, objectId: string, x: number, y: number, z: number)
	table.insert(
		fixedPlacements,
		{ id = id, objectId = objectId, x = x, y = y, z = z, yaw = 0, spawnSlot = nil }
	)
end

-- Mid T4 (up to 17 studs), weighted towards the vans and pickups so the wall of cars is mostly food worth a stop.
local t4Mid: { MixEntry } = {}
for _, id in idsOfTier(4, true, 0, 17) do
	table.insert(
		t4Mid,
		{ objectId = id, weight = if id == "pickup_truck" or id == "delivery_van" then 5 else 1 }
	)
end
local t4Heavy = {
	"pickup_truck",
	"delivery_van",
	"garbage_truck",
	"shipping_container",
	"billboard",
	"big_street_tree",
}
local t4Vans = { "delivery_van", "pickup_truck", "taxi" }

-- Park (west): two lawns with a path between them (magnet booster), a pond in the south-west corner, a slope in
-- the south-east, and a hedge of street trees along the east side with one opening (a gate).
zone("dt_z_park_w", -268, -20, 56, 120, 0, mix(t3Small), TUNE.parkW, 3001, nil)
zone("dt_z_park_e", -197, -20, 50, 120, 0, mix(t3Small), TUNE.parkE, 3002, nil)
zone("dt_z_park_slot_w", -268, -90, 56, 16, 0, mix({ "slot.yard" }), 3, 3003, nil)
zone("dt_z_park_slot_e", -197, -90, 50, 16, 0, mix({ "slot.yard" }), 2, 3004, nil)
-- Every third hedge plant is a street tree, the rest is fence (benches and recycling banks).
local hedgeKinds = { "street_tree", "bench", "recycling_bank" }
for index = 1, 17 do
	local z = -96 + (index - 1) * 12
	if z ~= 0 then
		fixed(string.format("dt_g_park_%02d", index), hedgeKinds[index % 3 + 1], -165, z)
	end
end

-- Construction Site (north-east): a pocket for the container stack, spring pad and mud, then the T3 yard.
zone("dt_z_site", 255, -63, 82, 42, 0, mix(t3Small), TUNE.site, 3101, nil)
zone("dt_z_site_slot", 255, -91, 82, 10, 0, mix({ "slot.yard" }), 4, 3102, nil)

-- Car Park (south-east): the spiral sits in the west pocket, the T3 yard east of it.
zone("dt_z_car", 255, 63, 82, 42, 0, mix(t3Small), TUNE.car, 3201, nil)
zone("dt_z_car_slot", 255, 91, 82, 10, 0, mix({ "slot.yard" }), 5, 3202, nil)

-- Market Street east: vans parked along both pavements (the Tier 4 wall).
zone("dt_z_market_n", 233, -26, 126, 24, 0, mix(t4Vans, 1), 6, 4001, nil)
zone("dt_z_market_s", 233, 26, 126, 24, 0, mix(t4Vans, 1), 6, 4002, nil)
zone("dt_z_market_c", 233, 0, 126, 28, 0, mix(t4Vans, 1), TUNE.marketRow, 4003, nil)

-- Centre block, north and south of the Plaza. The right halves are small T4 zones; the left halves hold the heavy
-- and big T4 kinds as fixed placements so every kind stands somewhere. The avenue x -14 to 14 stays open for the
-- Tier 3 arcade and vending heroes.
zone("dt_z_blk_n_r", 105, -81, 106, 34, 0, t4Mid, TUNE.block, 4101, nil)
zone("dt_z_blk_s_r", 105, 81, 106, 34, 0, t4Mid, TUNE.block, 4102, nil)
for _, side in { { name = "n", z = -81 }, { name = "s", z = 81 } } do
	local sign = if side.name == "n" then 1 else 2
	zone(
		`dt_z_blk_{side.name}_slot_l`,
		-38,
		side.z,
		28,
		34,
		0,
		mix({ "slot.street" }),
		1,
		4110 + sign,
		nil
	)
	zone(
		`dt_z_blk_{side.name}_slot_r`,
		38,
		side.z,
		28,
		34,
		0,
		mix({ "slot.street" }),
		1,
		4120 + sign,
		nil
	)
end
zone("dt_z_west_n", -136, -48, 44, 28, 0, mix({ "slot.street" }), 1, 4201, nil)
zone("dt_z_west_s", -136, 48, 44, 28, 0, mix({ "slot.street" }), 1, 4202, nil)
for index, objectId in { "garbage_truck", "shipping_container", "billboard", "big_street_tree" } do
	fixed("dt_f_" .. objectId, objectId, -146 + (index - 1) * 24, -81)
end
for index, objectId in { "corner_bakery", "fire_engine", "city_bus" } do
	fixed("dt_f_" .. objectId, objectId, -140 + (index - 1) * 32, 81)
end

-- Sidewalk strips north and south: T4 clusters between the sightline corridors.
local stripPieces = {
	{ -276.5, 39, 2, 2 },
	{ -220, 46, TUNE.stripN2, TUNE.stripS2 },
	{ -160, 46, TUNE.stripN3, TUNE.stripS3 },
	{ 160, 46, TUNE.stripN4, TUNE.stripS4 },
	{ 220, 46, TUNE.stripN5, TUNE.stripS5 },
	{ 276.5, 39, 2, 2 },
}
for index, piece in stripPieces do
	zone(
		`dt_z_strip_n_{index}`,
		piece[1],
		-190.5,
		piece[2],
		51,
		0,
		t4Mid,
		piece[3],
		4300 + index,
		nil
	)
	zone(
		`dt_z_strip_s_{index}`,
		piece[1],
		190.5,
		piece[2],
		51,
		0,
		t4Mid,
		piece[4],
		4310 + index,
		nil
	)
end

-- The Plaza -------------------------------------------------------------------------------------------------------
-- A square apron, ±62. The fountain basin and pedestal are blocks (below); the landmark slot stands on the pedestal.
-- A ring of Tier 2 bollards at ±58 with four 16-stud openings (the gates) is the Tier 2 wall.
fixedAt("dt_l_1", "slot.landmark", 0, 2.4, 0)
local bollardIds = { "traffic_cone", "parking_meter" }
local ringIndex = 0
for _, edge in { "n", "s", "w", "e" } do
	for step = -52, 52, TUNE.ringStep do
		if math.abs(step) > 10 then
			ringIndex += 1
			local x = if edge == "w" then -58 elseif edge == "e" then 58 else step
			local z = if edge == "n" then -58 elseif edge == "s" then 58 else step
			fixed(string.format("dt_g_plaza_%02d", ringIndex), bollardIds[ringIndex % 2 + 1], x, z)
		end
	end
end
fixed("dt_h_donut_food_truck", "donut_food_truck", -44, -44)
fixed("dt_h_monster_truck", "monster_truck", 44, 44)
fixed("dt_h_inflatable_tube_guy", "inflatable_tube_guy", -72, -14)
fixed("dt_h_arcade_cabinet", "arcade_cabinet", 0, -81)
fixed("dt_h_vending_machine", "vending_machine", 0, 81)
-- The dish stands in the open ground west of the avenue so the Tier 3 page never depends on a random mix.
fixed("dt_f_satellite_dish", "satellite_dish", -88, -46)

-- Skyline Block (north) and Waterfront (south): the Tier 5 rows. The west halves are heavy Tier 4 (vans, trucks,
-- containers) as the approach to the towers, the east halves hold the two smaller buildings, and the heroes and the
-- bigger buildings are fixed. The corridors end at |z| 215, short of the bands.
local t5Row = { "corner_shop_row", "townhouse" }
zone("dt_z_sky_w", -166, -260, 260, 80, 0, mix(t4Heavy), TUNE.skyW, 5001, nil)
zone("dt_z_sky_e", 86, -260, 104, 80, 0, mix(t5Row), 4, 5002, nil)
zone("dt_z_wat_w", -196, 260, 200, 80, 0, mix(t4Heavy), TUNE.watW, 5003, nil)
zone("dt_z_wat_e", 86, 260, 104, 80, 0, mix(t5Row), 4, 5004, nil)
fixed("dt_f_street_lamp", "street_lamp", -20, -222)
fixed("dt_f_traffic_light", "traffic_light", 20, -222)
fixed("dt_h_glass_tower", "glass_tower", 0, -262)
fixed("dt_h_tower_crane", "tower_crane", 170, -262)
fixed("dt_h_rocket_water_tower", "rocket_water_tower", 255, -262)
fixed("dt_h_ferris_wheel", "ferris_wheel", 0, 262)
fixed("dt_f_cinema", "cinema", 170, 262)
fixed("dt_f_apartment_block", "apartment_block", 240, 262)
fixed("dt_f_ev_charging_station", "ev_charging_station", 278, 262)
fixedAt("dt_l_2", "slot.landmark", -66, 0, 262)

-- Side-street and interior fillers: Tier 2 clusters (and Tier 1 scatter along the outer edges) on the open ground
-- between the districts. Each rectangle was picked clear of every zone, keep-out and tall block.
local fillT2 = mix(t2Small)
local fillT1 = mix(t1Large)
local fills: { { string | number | { MixEntry } } } = {
	{ "a", -88, -46, 48, 44, fillT2, 7 },
	{ "b", -95, 45, 34, 44, fillT2, 6 },
	{ "d", -231, -34, 16, 136, fillT1, 13 },
	{ "e", -54, -115, 92, 18, fillT2, 13 },
	{ "f", 54, 115, 92, 18, fillT2, 19 },
	{ "g", -6, 221, 76, 26, fillT2, 68 },
	{ "h", 45, -128, 28, 46, fillT2, 1 },
	{ "i", -45, 128, 28, 46, fillT2, 1 },
	{ "k1", -288, -131, 18, 62, fillT1, 18 },
	{ "k2", -288, 131, 18, 62, fillT1, 15 },
	{ "l1", -113, -191, 20, 56, fillT2, 19 },
	{ "l2", 113, -191, 20, 56, fillT2, 6 },
	{ "l3", -113, 191, 20, 56, fillT2, 23 },
	{ "l4", 113, 191, 20, 56, fillT2, 4 },
	{ "m", 135, 25, 68, 16, fillT2, 32 },
	{ "n", 84, 0, 14, 66, fillT2, 5 },
	{ "o1", 36, -30, 18, 50, fillT2, 17 },
	{ "o2", -36, 30, 18, 50, fillT2, 12 },
	{ "q", -80, 222, 30, 30, fillT2, 23 },
	{ "r1", 288, -134, 18, 58, fillT1, 19 },
	{ "r2", 288, 134, 18, 58, fillT1, 14 },
	{ "r3", 168, -68, 18, 58, fillT1, 2 },
	{ "s", 218, -257, 38, 80, fillT2, 29 },
}
for index, fill in fills do
	zone(
		`dt_z_fill_{fill[1]}`,
		fill[2] :: number,
		fill[3] :: number,
		fill[4] :: number,
		fill[5] :: number,
		0,
		fill[6] :: { MixEntry },
		fill[7] :: number,
		6000 + index,
		nil
	)
end
zone("dt_z_fill_slot", -151, 0, 12, 66, 0, mix({ "slot.medium" }), 6, 6100, nil)

-- Environment blocks ---------------------------------------------------------------------------------------------------
-- Everything is a plain anchored block. Swatches are w-* roles (present in every theme) or the world palette below.

block("dt_ground", "Block", 0, -0.5, 0, 0, 640, 1, 640, "w-sidewalk")
-- Roads sit 0.04 above the ground: under every marker and placement, and no obstacle.
block("dt_road_market", "Block", 75, 0, 0, 0, 450, 0.08, 24, "w-asphalt")
block("dt_road_spawn_n", "Block", 0, 0, -135, 0, 600, 0.08, 10, "w-asphalt")
block("dt_road_spawn_s", "Block", 0, 0, 135, 0, 600, 0.08, 10, "w-asphalt")
block("dt_road_avenue", "Block", 0, 0, 0, 0, 14, 0.08, 600, "w-asphalt")
block("dt_road_line_market", "Block", 75, 0.01, 0, 0, 450, 0.08, 0.6, "w-road-line")
block("dt_plaza_apron", "Block", 0, 0.01, 0, 0, 124, 0.08, 124, "w-sand")

-- Plaza fountain (R-11): basin, water, pedestal; the landmark slot stands on the pedestal at y 2.4.
box("dt_fountain_basin", 0, 0, 44, 44, 1.2, "w-kerb")
block("dt_fountain_water", "Block", 0, 1.25, 0, 0, 38, 0.1, 38, "w-water")
box("dt_fountain_pedestal", 0, 0, 12, 12, 1.2, "w-kerb", 1.2)

-- Doorsteps: a 0.6 porch under the two doorstep zones and a 1.2 kerb across the way in (Tier 1 must jump it).
for _, spawn in spawns do
	local sx, sz, inward = spawn.x, spawn.z, spawn.inward
	local name = string.format("dt_door_%02d", spawn.slot)
	box(name .. "_porch", sx, sz, 18, 14, PORCH, "w-wood")
	box(name .. "_kerb", sx, sz + inward * 9.5, 20, 1, 1.2, "w-kerb")
end

-- Alley rows: three buildings per side with a 4-stud alley between them (the four shortcuts).
local buildingSpans = { { -76, 48 }, { 0, 96 }, { 76, 48 } }
local buildingSwatch = { "w-wall-b", "w-wall-a", "w-wall-c" }
for _, side in { { name = "n", sign = -1 }, { name = "s", sign = 1 } } do
	for index, span in buildingSpans do
		box(
			`dt_alley_{side.name}_{index}`,
			span[1],
			side.sign * 187.5,
			span[2],
			35,
			14,
			buildingSwatch[index]
		)
		box(
			`dt_alley_{side.name}_{index}_roof`,
			span[1],
			side.sign * 187.5,
			span[2] + 1,
			36,
			1,
			"w-roof-b",
			14
		)
	end
end

-- Park: lawns, path, pond (the ice rink in winter) and a slope.
block("dt_park_lawn_w", "Block", -268, 0.02, -20, 0, 56, 0.08, 120, "w-grass")
block("dt_park_lawn_e", "Block", -197, 0.02, -20, 0, 50, 0.08, 120, "w-grass")
block("dt_park_path", "Block", -231, 0.02, 0, 0, 18, 0.08, 196, "w-sand")
block("dt_park_pond", "Block", -268, 0.03, 71, 0, 56, 0.08, 54, "w-water")
-- The slope rises towards +Z (yaw 0): sleds wait at its foot (the northern edge).
block("dt_park_slope", "Wedge", -197, 2.5, 78, 0, 42, 5, 40, "w-season")
for index = 1, 8 do
	box(
		string.format("dt_park_rail_%02d", index),
		-296 + index * 14 - 7,
		97,
		12,
		0.6,
		1.2,
		"w-wood"
	)
end

-- Construction Site: container stack (spring target), a ramp up to it, hoardings, scaffold planks, a mud patch.
block("dt_site_ground", "Block", 233, 0.02, -68, 0, 126, 0.08, 62, "w-soil")
box("dt_site_container_1", 188, -70, 20, 8, 2.6, "dt-container")
box("dt_site_container_2", 188, -70, 20, 8, 2.6, "dt-container", 2.6)
block("dt_site_ramp", "Wedge", 205, 2.6, -70, -90, 8, 5.2, 10, "w-wood")
for index = 1, 6 do
	box(
		string.format("dt_site_hoarding_%02d", index),
		296.5,
		-96 + index * 10,
		1,
		8,
		4,
		"dt-hoarding"
	)
end
box("dt_site_scaffold_1", 232, -92, 1, 1, 8, "w-metal")
box("dt_site_scaffold_2", 276, -92, 1, 1, 8, "w-metal")
box("dt_site_plank", 254, -92, 44, 1, 0.5, "w-wood", 8)
block("dt_site_mud", "Block", 188, 0.03, -48, 0, 14, 0.08, 14, "w-soil")
-- Crane base: a ballast stack under the Skyline Block crane (golden spot 4).
box("dt_crane_ballast", 170, -228, 10, 10, 3, "dt-concrete")
box("dt_crane_ballast_top", 170, -236, 8, 6, 1, "dt-concrete")

-- Car Park: three decks, two ramps up and one ramp across, a top deck (golden spot 2).
block("dt_car_ramp_1", "Wedge", 180, 1, 92, 180, 16, 2, 12, "w-metal")
box("dt_car_deck_1", 180, 78, 16, 16, 2, "dt-concrete")
block("dt_car_ramp_2", "Wedge", 180, 3, 64, 180, 16, 2, 12, "w-metal")
box("dt_car_deck_2", 180, 50, 16, 16, 4, "dt-concrete")
block("dt_car_ramp_3", "Wedge", 194, 5, 50, 90, 16, 2, 12, "w-metal")
box("dt_car_deck_3", 207, 50, 14, 16, 6, "dt-concrete")
box("dt_car_parapet", 207, 41.5, 14, 0.6, 1, "dt-concrete", 6)

-- Storm-drain tunnel under Market Street: floor is the ground, two walls 3.8 tall, no roof (golden spot 3).
-- The chamber (z -8 to 8) keeps the 6-stud gap for the golden spot's 6 x 6 footprint; each 6-stud mouth narrows to 4.6 so a
-- Tier 3+ ball (diameter >= 5) cannot enter.
box("dt_tunnel_wall_w", -103.5, 0, 1, 16, 3.8, "dt-concrete")
box("dt_tunnel_wall_e", -96.5, 0, 1, 16, 3.8, "dt-concrete")
box("dt_tunnel_mouth_wn", -102.8, 11, 1, 6, 3.8, "dt-concrete")
box("dt_tunnel_mouth_en", -97.2, 11, 1, 6, 3.8, "dt-concrete")
box("dt_tunnel_mouth_ws", -102.8, -11, 1, 6, 3.8, "dt-concrete")
box("dt_tunnel_mouth_es", -97.2, -11, 1, 6, 3.8, "dt-concrete")

-- Bus stop on Market Street: a roof slab on two posts (golden spot 1).
box("dt_bus_post_w", 134, -22, 0.6, 0.6, 3, "w-metal-dark")
box("dt_bus_post_e", 146, -22, 0.6, 0.6, 3, "w-metal-dark")
box("dt_bus_roof", 140, -22, 14, 6, 0.6, "w-glass", 3)

-- Waterfront: promenade, quay edge, railings and the ticket hut platform behind the Ferris Wheel (golden spot 5).
block("dt_waterfront_promenade", "Block", 0, 0.02, 212, 0, 560, 0.08, 14, "w-sand")
block("dt_waterfront_quay", "Block", 0, 0.02, 296, 0, 600, 0.08, 8, "w-water")
box("dt_ticket_platform", 0, 292, 12, 8, 1, "w-wood")
box("dt_ticket_hut", -4, 292, 3, 3, 3, "w-wall-b", 1)
for index = 1, 10 do
	box(
		string.format("dt_waterfront_rail_%02d", index),
		-270 + (index - 1) * 60,
		287,
		40,
		0.5,
		1.1,
		"w-metal-dark"
	)
end

-- Garlands over Market Street (winter-neutral: w-trim reads as street cables in the city look).
for index, x in { -130, -60, 60, 100, 200, 260 } do
	block(string.format("dt_garland_%d", index), "Block", x, 11, 0, 0, 0.6, 0.4, 24, "w-trim")
end

-- Planters round the Plaza basin and bus-stop bench.
for index, corner in { { -56, -56 }, { 56, -56 }, { -56, 56 }, { 56, 56 } } do
	box(string.format("dt_plaza_planter_%d", index), corner[1], corner[2], 4, 4, 1, "w-leaf-dark")
end

-- Boundary walls and the far skyline strip.
block("dt_wall_n", "Block", 0, 20, -302, 0, 608, 40, 4, "dt-concrete")
block("dt_wall_s", "Block", 0, 20, 302, 0, 608, 40, 4, "dt-concrete")
block("dt_wall_e", "Block", 302, 20, 0, 0, 4, 40, 608, "dt-concrete")
block("dt_wall_w", "Block", -302, 20, 0, 0, 4, 40, 608, "dt-concrete")

-- Markers (data-model.md §10) ---------------------------------------------------------------------------------------
-- yaw is in degrees and local +Z is the facing: a spring pad at (188, -86) with yaw 0 launches towards the
-- container stack at z = -70. Sweeper loops run on open ground in the north and south pockets.

local function spot(
	id: string,
	kind: string,
	subKind: string,
	x: number,
	z: number,
	yaw: number?,
	y: number?
)
	table.insert(markers, {
		id = id,
		kind = kind,
		subKind = subKind,
		x = x,
		y = y or 0,
		z = z,
		yaw = yaw or 0,
		waypoints = nil,
	})
end

local function sweeperLoop(id: string, corners: { { x: number, z: number } })
	table.insert(markers, {
		id = id,
		kind = "TrapSpot",
		subKind = "sweeper",
		x = corners[1].x,
		y = 0,
		z = corners[1].z,
		yaw = 0,
		waypoints = corners,
	})
end

spot("booster-dash-1", "BoosterSpot", "dash", -70, -130)
spot("booster-dash-2", "BoosterSpot", "dash", 70, 130)
spot("booster-magnet-1", "BoosterSpot", "magnet", -231, 40)
spot("booster-spring-1", "BoosterSpot", "spring", 188, -86, 0)
spot("booster-shield-1", "BoosterSpot", "shield", -30, -30)
spot("booster-slick_trail-1", "BoosterSpot", "slick_trail", -60, 212)
spot("trap-slick-1", "TrapSpot", "slick", -30, -140)
spot("trap-slick-2", "TrapSpot", "slick", 30, 140)
spot("trap-bumper-1", "TrapSpot", "bumper", 198, 92)
spot("trap-slow-1", "TrapSpot", "slow", 188, -48)
sweeperLoop(
	"trap-sweeper-1",
	{ { x = 0, z = -140 }, { x = 24, z = -140 }, { x = 24, z = -116 }, { x = 0, z = -116 } }
)
sweeperLoop(
	"trap-sweeper-2",
	{ { x = -24, z = 116 }, { x = 0, z = 116 }, { x = 0, z = 140 }, { x = -24, z = 140 } }
)
-- Golden spots stand on static geometry: bus-stop roof, Car Park top deck, tunnel floor, crane ballast, ticket
-- platform behind the Ferris Wheel (D2: the ballast, not the jib counterweight).
spot("golden-1", "GoldenSpot", "golden", 140, -22, 0, 3.6)
spot("golden-2", "GoldenSpot", "golden", 207, 50, 0, 6)
spot("golden-3", "GoldenSpot", "golden", -100, 0, 0, 0)
spot("golden-4", "GoldenSpot", "golden", 170, -228, 0, 3)
spot("golden-5", "GoldenSpot", "golden", 2, 292, 0, 1)

-- Keep-outs (data-model.md §9) ---------------------------------------------------------------------------------------
-- Footprints per sub-kind (Content/Hazards.luau); the test compares this table with the Hazards rows.
local footprints: { [string]: { w: number, d: number } } = {
	dash = { w = 5, d = 5 },
	magnet = { w = 5, d = 5 },
	spring = { w = 8, d = 8 },
	shield = { w = 5, d = 5 },
	slick_trail = { w = 5, d = 5 },
	slick = { w = 14, d = 14 },
	bumper = { w = 4, d = 4 },
	slow = { w = 14, d = 14 },
	sweeper = { w = 10, d = 6 },
	golden = { w = 6, d = 6 },
}
for _, marker in markers do
	local footprint = footprints[marker.subKind]
	local waypoints = marker.waypoints
	if waypoints then
		for index, from in waypoints do
			local to = waypoints[index % #waypoints + 1]
			keepOut(
				`ko_marker_{#keepOutAreas + 1}`,
				"marker",
				(from.x + to.x) / 2,
				(from.z + to.z) / 2,
				math.abs(to.x - from.x) + footprint.w,
				math.abs(to.z - from.z) + footprint.w
			)
		end
	else
		keepOut(
			`ko_marker_{#keepOutAreas + 1}`,
			"marker",
			marker.x,
			marker.z,
			footprint.w,
			footprint.d
		)
	end
end

-- Six gates: the openings in the Plaza bollard ring (4), the Park hedge (1) and the Market Street van wall (1).
keepOut("ko_gate_1", "gate", -58, 0, 16, 16)
keepOut("ko_gate_2", "gate", 58, 0, 16, 16)
keepOut("ko_gate_3", "gate", 0, -58, 16, 16)
keepOut("ko_gate_4", "gate", 0, 58, 16, 16)
keepOut("ko_gate_5", "gate", -165, 0, 12, 16)
keepOut("ko_gate_6", "gate", 152, 0, 40, 30)

-- Five shortcuts: the four 4-stud alleys (with their approach) and the drain tunnel mouth.
for _, alley in { { -50, -187.5 }, { 50, -187.5 }, { -50, 187.5 }, { 50, 187.5 } } do
	keepOut(`ko_shortcut_{#keepOutAreas + 1}`, "shortcut", alley[1], alley[2], 8, 60)
end
keepOut("ko_shortcut_tunnel", "shortcut", -100, 0, 14, 44)

-- Twelve sightline corridors, 12 wide and 80 long, one per spawn, from the doorstep out to the sidewalk's end.
for _, spawn in spawns do
	keepOut(
		string.format("ko_sightline_%02d", spawn.slot),
		"sightline",
		spawn.x,
		spawn.z - spawn.inward * 40,
		12,
		80
	)
end

-- Themes (data-model.md §5) -----------------------------------------------------------------------------------------
-- Theme-only objects: the slot objects and, for winter, the overlay objects. Coins follow the same rule as the core.

type ThemeKit = { { tier: number, id: string, size: number, shape: Shape, role: string } }

local winterKit: ThemeKit = {
	{ tier = 1, id = "bauble", size = 0.6, shape = "Ball", role = "w-accent-red" },
	{ tier = 2, id = "gift_box", size = 2.0, shape = "Block", role = "w-accent-red" },
	{ tier = 3, id = "snowman", size = 8.0, shape = "Ball", role = "w-white" },
	{ tier = 4, id = "sleigh", size = 15, shape = "Block", role = "w-accent-red" },
	{ tier = 5, id = "mega_tree", size = 45, shape = "Cylinder", role = "w-leaf" },
	{ tier = 1, id = "fairy_light_bulb", size = 0.5, shape = "Ball", role = "w-glow" },
	{ tier = 1, id = "mini_gift", size = 0.9, shape = "Block", role = "w-accent-red" },
	{ tier = 1, id = "gingerbread_cookie", size = 1.0, shape = "Block", role = "w-wood" },
	{ tier = 2, id = "leaning_present_stack", size = 3.6, shape = "Block", role = "w-accent-red" },
	{ tier = 2, id = "poinsettia_pot", size = 2.4, shape = "Cylinder", role = "w-accent-red" },
	{ tier = 2, id = "wooden_sled", size = 3.2, shape = "Block", role = "w-wood" },
	{ tier = 2, id = "wreath", size = 2.8, shape = "Cylinder", role = "w-leaf" },
	{ tier = 3, id = "snow_pile", size = 6.0, shape = "Ball", role = "w-white" },
	{ tier = 3, id = "light_up_reindeer", size = 7.0, shape = "Block", role = "w-glow" },
	{ tier = 3, id = "cocoa_cart", size = 6.5, shape = "Block", role = "w-accent-orange" },
	{ tier = 4, id = "market_stall", size = 12, shape = "Block", role = "w-accent-red" },
	{ tier = 4, id = "snowplough", size = 22, shape = "Block", role = "w-accent-yellow" },
	{ tier = 5, id = "ice_rink", size = 40, shape = "Cylinder", role = "w-water" },
}
-- Slot objects match the winter ones in size, so a theme switch never moves a base placement (grid and slack).
local cityKit: ThemeKit = {
	{ tier = 1, id = "ice_lolly", size = 0.6, shape = "Cylinder", role = "w-accent-pink" },
	{ tier = 2, id = "beach_ball", size = 2.0, shape = "Ball", role = "w-accent-blue" },
	{ tier = 3, id = "paddling_pool", size = 8.0, shape = "Cylinder", role = "w-water" },
	{ tier = 4, id = "ice_cream_truck", size = 15, shape = "Block", role = "w-white" },
	{ tier = 5, id = "giant_duck", size = 35, shape = "Ball", role = "w-accent-yellow" },
}

local function kitObjects(kit: ThemeKit)
	local list = {}
	local ids = {}
	for _, entry in kit do
		table.insert(list, objectDef(entry.tier, entry.id, entry.size, entry.shape, entry.role))
		table.insert(ids, entry.id)
	end
	return list, ids
end
local winterObjects, winterIds = kitObjects(winterKit)
local cityObjects, cityIds = kitObjects(cityKit)

-- Winter overlays (150): 60 doorstep crumbs, 50 Tier 2, 25 Tier 3, 14 Tier 4, 1 Tier 5.
local overlayZones: { Zone } = {}
local overlayFixed: { Fixed } = {}

local function overlayZone(
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	objectId: string,
	count: number,
	seed: number
)
	table.insert(overlayZones, {
		id = id,
		x = x,
		z = z,
		w = w,
		d = d,
		y = 0,
		mix = { { objectId = objectId, weight = 1 } },
		count = count,
		seed = seed,
		spawnSlot = nil,
	})
end

local function overlayAt(id: string, objectId: string, x: number, z: number)
	table.insert(
		overlayFixed,
		{ id = id, objectId = objectId, x = x, y = 0, z = z, yaw = 0, spawnSlot = nil }
	)
end

for _, spawn in spawns do
	local sx, sz, inward, slot = spawn.x, spawn.z, spawn.inward, spawn.slot
	local z = sz - inward * 10.5
	local odd = slot % 2 == 1
	overlayZone(
		`dt_ol_door_{slot}_lights`,
		sx + 10.75,
		z,
		5.5,
		5,
		"fairy_light_bulb",
		2,
		7000 + slot
	)
	overlayZone(
		`dt_ol_door_{slot}_gifts`,
		sx + 17.25,
		z,
		5.5,
		5,
		"mini_gift",
		if odd then 2 else 1,
		7100 + slot
	)
	overlayZone(
		`dt_ol_door_{slot}_cookies`,
		sx + 23.75,
		z,
		5.5,
		5,
		"gingerbread_cookie",
		if odd then 1 else 2,
		7200 + slot
	)
end
-- Tier 2: shop fronts (pots and wreaths along the alley buildings), the Park slope (sleds), Market Street.
-- Each row is cut in three so it leaves the 8-stud alley approaches (the shortcut keep-outs at x -50 and 50) open.
local function overlayRow(
	id: string,
	z: number,
	d: number,
	objectId: string,
	counts: { number },
	seed: number
)
	local segments = { { -78, 44 }, { 0, 88 }, { 78, 44 } }
	for index, segment in segments do
		overlayZone(
			`{id}_{index}`,
			segment[1],
			z,
			segment[2],
			d,
			objectId,
			counts[index],
			seed * 10 + index
		)
	end
end
overlayRow("dt_ol_pots_n", -156, 8, "poinsettia_pot", { 2, 3, 2 }, 7301)
overlayRow("dt_ol_pots_s", 156, 8, "poinsettia_pot", { 2, 3, 2 }, 7302)
overlayRow("dt_ol_wreaths_n", -164.5, 7, "wreath", { 2, 4, 2 }, 7303)
overlayRow("dt_ol_wreaths_s", 164.5, 7, "wreath", { 2, 4, 2 }, 7304)
overlayZone("dt_ol_sleds", -197, 51, 46, 10, "wooden_sled", 14, 7305)
for index, at in
	{ { -140, -22 }, { -140, 22 }, { -124, -22 }, { -124, 22 }, { 110, -8 }, { 110, 8 } }
do
	overlayAt(`dt_ol_f_{index}`, "leaning_present_stack", at[1], at[2])
end
-- Tier 3: snow piles on the pocket edges, reindeer lamps at the Plaza approaches, cocoa carts in the Plaza.
overlayZone("dt_ol_snow_n", 80, -130, 40, 40, "snow_pile", 6, 7401)
overlayZone("dt_ol_snow_s", -80, 130, 40, 40, "snow_pile", 6, 7402)
for index, at in { { -72, 14 }, { -72, 40 }, { 72, 14 }, { 72, -14 }, { 72, 40 } } do
	overlayAt(`dt_ol_f_{6 + index}`, "light_up_reindeer", at[1], at[2])
end
for index, at in
	{
		{ 50, 22 },
		{ 50, -22 },
		{ -50, 22 },
		{ -50, -22 },
		{ 22, 50 },
		{ -22, 50 },
		{ 22, -50 },
		{ -22, -50 },
	}
do
	overlayAt(`dt_ol_f_{11 + index}`, "cocoa_cart", at[1], at[2])
end
-- Tier 4: six stalls round the tree and two on Market Street; ploughs on the east pavements.
for index = 1, 6 do
	local angle = math.rad((index - 1) * 60)
	overlayAt(
		`dt_ol_f_{19 + index}`,
		"market_stall",
		math.floor(36 * math.cos(angle) * 100 + 0.5) / 100,
		math.floor(36 * math.sin(angle) * 100 + 0.5) / 100
	)
end
overlayAt("dt_ol_f_26", "market_stall", 96, -22)
overlayAt("dt_ol_f_27", "market_stall", 96, 22)
overlayZone("dt_ol_plough_n", 111, -48, 94, 28, "snowplough", 3, 7501)
overlayZone("dt_ol_plough_s", 111, 48, 94, 28, "snowplough", 3, 7502)
-- Tier 5: the Park pond becomes the ice rink.
overlayAt("dt_ol_f_28", "ice_rink", -268, 71)

local winterSlots = {
	["slot.small"] = "bauble",
	["slot.medium"] = "gift_box",
	["slot.yard"] = "snowman",
	["slot.street"] = "sleigh",
	["slot.landmark"] = "mega_tree",
}
local citySlots = {
	["slot.small"] = "ice_lolly",
	["slot.medium"] = "beach_ball",
	["slot.yard"] = "paddling_pool",
	["slot.street"] = "ice_cream_truck",
	["slot.landmark"] = "giant_duck",
}

local themeBindings: {
	[string]: {
		growthK: number?,
		slots: { [string]: string },
		overlays: { zones: { Zone }, fixedPlacements: { Fixed } },
		heroVariants: { [string]: { assetKey: string, nameKey: string?, size: number? } },
		objects: { typeof(objects[1]) }?,
		bookPage: {
			id: string,
			nameKey: string,
			returningKey: string,
			reward: { rewardId: string, rewardType: "skin" | "trail", nameKey: string }?,
			objectIds: { string },
		}?,
	},
} =
	{
		winter = {
			-- Theme-scoped override (Worlds reads it for the active theme). Winter's cocoa cart is 6.5 studs so the
			-- Plaza overlay does not pull D 30 below 145 s on the north-west spawns (Pace.test).
			growthK = 1.95,
			slots = winterSlots,
			overlays = { zones = overlayZones, fixedPlacements = overlayFixed },
			heroVariants = {
				donut_food_truck = {
					assetKey = "dt_cocoa_truck",
					nameKey = "object.downtown.cocoa_truck",
					size = 18,
				},
				glass_tower = {
					assetKey = "dt_glass_tower_bow",
					nameKey = "object.downtown.glass_tower_bow",
					size = 60,
				},
			},
			objects = winterObjects,
			bookPage = {
				id = "downtown.winter",
				nameKey = "book.page.downtown.winter.name",
				returningKey = "book.page.downtown.winter.returning",
				reward = nil,
				objectIds = winterIds,
			},
		},
		city = {
			slots = citySlots,
			overlays = { zones = {}, fixedPlacements = {} },
			heroVariants = {},
			objects = cityObjects,
			bookPage = {
				id = "downtown.city",
				nameKey = "book.page.downtown.city.name",
				returningKey = "book.page.downtown.city.returning",
				reward = nil,
				objectIds = cityIds,
			},
		},
	}

-- Ambient pigeons (R-14): client-only decoration, at most 8 per district, on bare ground or static geometry.
local pigeons: { { district: string, x: number, z: number } } = {}
local function flock(district: string, spots: { { number } })
	for _, at in spots do
		table.insert(pigeons, { district = district, x = at[1], z = at[2] })
	end
end
flock("Park", { { -231, -70 }, { -231, -45 }, { -231, -20 }, { -231, 10 }, { -231, 70 } })
flock("Plaza", { { 30, -14 }, { -30, 14 }, { 14, -30 }, { 8, 28 }, { -14, 26 } })
flock("Waterfront", { { -40, 214 }, { -20, 214 }, { 20, 214 }, { 40, 214 }, { 60, 214 } })
flock("Construction Site", { { 176, -30 }, { 196, -30 }, { 180, -100 }, { 200, -104 } })
flock("Car Park", { { 176, 34 }, { 196, 34 }, { 182, 100 }, { 202, 100 } })

local Downtown = {
	worldId = "downtown",
	starThresholds = { 20, 45, 80 },
	-- PROVISIONAL, owner to confirm: solved with the pace model (tests/unit/Pace.test, research R-08).
	growthK = 1.95,
	halfExtent = 300,
	outerHalfExtent = 400,
	sizeTiers = sizeTiers,
	objects = objects,
	zones = zones,
	fixedPlacements = fixedPlacements,
	spawnPoints = spawnPoints,
	-- The January switch is a data-only change of activeThemeId (FR-005).
	activeThemeId = "winter",
	supportedThemes = { "winter", "city" },
	themeBindings = themeBindings,
	keepOutAreas = keepOutAreas,
	maxPlacements = 1400,
	environment = {
		palette = {
			["dt-concrete"] = { 168, 168, 163 },
			["dt-container"] = { 196, 78, 58 },
			["dt-hoarding"] = { 230, 188, 74 },
		},
		blocks = blocks,
		markers = markers,
	},
	hub = {
		center = { x = -460, z = 0 },
		halfExtent = 24,
		spawn = { x = 0, z = 0 },
		padRadius = 5,
		assetKey = "hub",
	},
	-- Used only when Flags.ThemeSystem is off: a copy of the winter look.
	lighting = {
		ambient = { 150, 165, 190 },
		outdoorAmbient = { 170, 185, 210 },
		brightness = 2,
		clockTime = 16.5,
		fogColor = { 205, 218, 235 },
		fogStart = 150,
		fogEnd = 900,
		atmosphereDensity = 0.3,
		atmosphereColor = { 200, 215, 235 },
		atmosphereDecay = { 190, 200, 220 },
	},
	ambient = { pigeons = pigeons },
}

return Downtown
