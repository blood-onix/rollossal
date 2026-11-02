--!strict
-- Downtown world data (008, "Inside Out"). Data only: no Roblox APIs and no requires, so Lune can load it directly.
-- Shape: the WorldDef type in Content/GreyBoxRoom.luau; checked against it in Worlds.luau.
-- Design: specs/008-downtown-inside-out/data-model.md and contracts/world-content.md (C1 to C18, N1 to N10).
-- Everything is built once at require time by plain loops over the tables below: no clock, no randomness.
--
-- Map (x east, z south, studs; origin at the centre of the Old Quarter plaza; m = max(|x|, |z|)). The playable
-- square is 880 x 880 in five rings that grow outwards:
--   1 Old Quarter (m <= 90): 8-stud lanes, 30-stud main streets, plaza and landmark, 12 spawns, bollard gates.
--   2 Terraces (90 to 185): 16-stud streets, house rows on plinths, roofed 4.5 shortcuts, storm drain.
--   3 Yards (185 to 290): Park, Market, Construction Site, Car Park, Rail Yard.
--   4 Boulevard (295 to 355): two 26-stud carriageways and an 8-stud median.
--   5 Skyline (north, east) and Harbour (south, west) out to 440, then the horizon towers and water.

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

-- Scenery that only the Holiday City theme shows (garlands, sledding slope): themeBindings.winter.blocks.
local winterBlocks: { Block } = {}

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
	swatch: string,
	into: { Block }?
)
	table.insert(into or blocks, {
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

-- Rotation and shape helpers ------------------------------------------------------------------------------------------
-- Rings 1 and 2, the Boulevard and the Skyline are drawn once for the north-east (or north) side and turned three
-- times (clockwise, as seen from above with north up): (x, z) -> (-z, x). Yards are written out in full.

local function turn(r: number, x: number, z: number): (number, number)
	for _ = 1, r do
		x, z = -z, x
	end
	return x, z
end

type Area = { x0: number, x1: number, z0: number, z1: number }

-- A slab from `bottom` (default the ground) up to `top`, given by canonical corners and turned r times.
local function slab(
	id: string,
	r: number,
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	top: number,
	swatch: string,
	bottom: number?
): Area
	local cx, cz = turn(r, (x0 + x1) / 2, (z0 + z1) / 2)
	local w, d = x1 - x0, z1 - z0
	if r % 2 == 1 then
		w, d = d, w
	end
	local base = bottom or 0
	block(id, "Block", cx, base + (top - base) / 2, cz, 0, w, top - base, d, swatch)
	return { x0 = cx - w / 2, x1 = cx + w / 2, z0 = cz - d / 2, z1 = cz + d / 2 }
end

-- A Wedge that rises towards +Z at yaw 0, +X at 90, -Z at 180 and -X at 270. Size is (width, rise, run).
local function ramp(
	id: string,
	x: number,
	z: number,
	yaw: number,
	width: number,
	rise: number,
	run: number,
	from: number,
	swatch: string,
	into: { Block }?
)
	block(id, "Wedge", x, from + rise / 2, z, yaw, width, rise, run, swatch, into)
end

local sizeOf: { [string]: number } = {}
for _, entry in catalogue do
	sizeOf[entry.id] = entry.size
end

local function fixedAt(id: string, objectId: string, x: number, y: number, z: number)
	table.insert(
		fixedPlacements,
		{ id = id, objectId = objectId, x = x, y = y, z = z, yaw = 0, spawnSlot = nil }
	)
end

-- Stands objects side by side along the long axis of a plinth, cycling through `ids`, centred on the strip. An
-- object that is wider than the strip, or would run past the end, is skipped. Returns how many were placed.
local function stock(
	prefix: string,
	area: Area,
	y: number,
	ids: { string },
	maxCount: number,
	gap: number?
): number
	local w, d = area.x1 - area.x0, area.z1 - area.z0
	local alongX = w >= d
	local length = if alongX then w else d
	local across = if alongX then d else w
	local chosen: { string } = {}
	local used = 0
	for index = 1, #ids * 4 do
		if #chosen >= maxCount then
			break
		end
		local objectId = ids[(index - 1) % #ids + 1]
		local size = sizeOf[objectId]
		local step = size + (gap or 1)
		if size <= across - 1 and used + step - (gap or 1) <= length then
			table.insert(chosen, objectId)
			used += step
		end
	end
	used -= (gap or 1)
	local cursor = ((if alongX then area.x0 else area.z0) + (length - used) / 2)
	local midX, midZ = (area.x0 + area.x1) / 2, (area.z0 + area.z1) / 2
	for index, objectId in chosen do
		local size = sizeOf[objectId]
		local at = cursor + size / 2
		fixedAt(
			`{prefix}_{index}`,
			objectId,
			if alongX then at else midX,
			y,
			if alongX then midZ else at
		)
		cursor += size + (gap or 1)
	end
	return #chosen
end

-- Pace levers (specs/008-downtown-inside-out/research.md R-07), solved with tests/unit/Pace.test.
local TUNE = {
	laneMax = 2.4,
	loopMax = 2.2,
	t3Rare = 0.1,
	crumbBig = 16,
	smallWeight = 7,
	padCount = 12,
	stripCount = 10,
	bigCrumbs = 2,
	midWeight = 10,
	bigWeight = 100,
	laneT2 = { 3, 3, 3, 1 },
	loopT2 = 5,
	radialT3 = 0,
	yardT2 = 17,
	yardT3 = 5,
	parkT3 = 8,
	yardT4 = 4,
	boulevardT4 = 7,
	boulevardT2 = 18,
	boulevardT3 = 10,
	quay = 4,
}

-- Mixes by tier. Heroes are fixed placements, so zone mixes skip them.
-- The doorstep (a) is mostly the three big Tier 1 kinds with a few tiny ones to start on: with 40 objects a spawn
-- must be able to reach D 5 alone when twelve starters share the Old Quarter (FR-008). The other Tier 1 kinds
-- come in the small (c) zone of each doorstep.
local t1Crumbs: { MixEntry } = {}
-- Every doorstep object is one a D 2 ball can eat (size <= 0.4 * D = 0.8): a bigger one would be a wall the new ball
-- cannot move through. The three big kinds (headphones, basketball, takeout box) wait in the c zone behind it.
for _, id in { "bottle_cap", "aa_battery", "earbud_case", "puzzle_cube", "soda_can", "tennis_ball" } do
	table.insert(t1Crumbs, { objectId = id, weight = TUNE.smallWeight })
end
for _, id in { "coffee_cup", "donut", "smartphone" } do
	table.insert(t1Crumbs, { objectId = id, weight = TUNE.crumbBig })
end
-- The bigger Tier 1 kinds stand in the strips either side of the pad, where the ball reaches them after the pad.
local t1Big: { MixEntry } = {}
for _, id in { "water_bottle", "pizza_slice", "game_controller" } do
	table.insert(t1Big, { objectId = id, weight = TUNE.midWeight })
end
for _, id in { "headphones", "basketball", "takeout_box" } do
	table.insert(t1Big, { objectId = id, weight = TUNE.bigWeight })
end
local t2Lane = mix(idsOfTier(2, true, 0, TUNE.laneMax))
local t2All = mix(idsOfTier(2, true))
local t2Loop = mix(idsOfTier(2, true, 0, TUNE.loopMax))
local t3Radial = mix(idsOfTier(3, true, 0, 6.0))
-- The big Tier 3 kinds (7 studs and up) are rarer, so the climb from D 12 to D 30 takes more pickups (pace tuning).
local t3All: { MixEntry } = {}
for _, id in idsOfTier(3, true) do
	table.insert(t3All, { objectId = id, weight = if sizeOf[id] > 6.6 then TUNE.t3Rare else 1 })
end
local t4Cars = mix({ "hatchback", "taxi", "pickup_truck", "delivery_van" })
local t4Yard = mix({ "bus_shelter", "kiosk", "hatchback", "taxi", "pickup_truck", "delivery_van" })
local t3Quay = mix(idsOfTier(3, true, 0, 6.0))

local zoneSeed = 9000
local function seed(): number
	zoneSeed += 7
	return zoneSeed
end

-- Shell ------------------------------------------------------------------------------------------------------------
-- Dark asphalt ground under everything (top 0). The south and west edges stop at the harbour, where a shallow
-- basin of water sits 0.4 below it (R-13); the north and east reach the horizon.

block("dt_ground", "Block", 80, -0.5, -80, 0, 960, 1, 960, "w-asphalt")
block("dt_basin_s", "Block", 0, -0.9, 480, 0, 1120, 1, 160, "w-water")
block("dt_basin_w", "Block", -480, -0.9, -80, 0, 160, 1, 960, "w-water")
-- Invisible walls: inner faces at +-440, 8 thick, 200 tall (R-01). North and south are longer so the corners close.
block("dt_boundary_n", "Boundary", 0, 100, -444, 0, 896, 200, 8, "w-asphalt")
block("dt_boundary_s", "Boundary", 0, 100, 444, 0, 896, 200, 8, "w-asphalt")
block("dt_boundary_e", "Boundary", 444, 100, 0, 0, 8, 200, 880, "w-asphalt")
block("dt_boundary_w", "Boundary", -444, 100, 0, 0, 8, 200, 880, "w-asphalt")

-- Ring 1: the Old Quarter -----------------------------------------------------------------------------------------
-- Canonical north-east quarter [15, 90] x [-90, -15]. Two 8-wide lanes (x = 52.5 and z = -52.5) cut it into four
-- sub-blocks; the inner one is notched by the 15 x 15 plaza corner. Main streets are 30 wide (|t| <= 15).

local PLINTH = 1.2
local quarterPlinths: { { name: string, x0: number, x1: number, z0: number, z1: number } } = {
	{ name = "far", x0 = 56.5, x1 = 90, z0 = -90, z1 = -56.5 },
	{ name = "north", x0 = 15, x1 = 48.5, z0 = -90, z1 = -56.5 },
	{ name = "east", x0 = 56.5, x1 = 90, z0 = -48.5, z1 = -15 },
	{ name = "inner_a", x0 = 30, x1 = 48.5, z0 = -48.5, z1 = -15 },
	{ name = "inner_b", x0 = 15, x1 = 30, z0 = -48.5, z1 = -30 },
}
local plinthArea: { [string]: Area } = {}
for r = 0, 3 do
	for _, p in quarterPlinths do
		plinthArea[`{p.name}{r}`] =
			slab(`dt_pl1_{r}_{p.name}`, r, p.x0, p.x1, p.z0, p.z1, PLINTH, "w-sidewalk")
	end
	-- Edge walls (top 6) seal the lane ends and the sub-block outer faces; the main-street gap stays open.
	slab(`dt_edge_{r}_a`, r, 15, 92, -92, -90, 6, "w-wall-b")
	slab(`dt_edge_{r}_b`, r, 90, 92, -90, -15, 6, "w-wall-b")
end
block("dt_plaza", "Block", 0, 0.15, 0, 0, 60, 0.3, 60, "w-sand")
box("dt_pedestal", 0, 0, 12, 12, 2.4, "w-kerb")

-- Spawns: three per quarter on the lanes, never on a main street. Slot 1 to 12 run clockwise from the north-east.
local spawnPoints = {}
local spawnAt: { { slot: number, x: number, z: number, axis: string } } = {}
local canonicalSpawns = {
	{ x = 52.5, z = -38, axis = "z" },
	{ x = 52.5, z = -68, axis = "z" },
	{ x = 35, z = -52.5, axis = "x" },
}
for r = 0, 3 do
	for index, spawn in canonicalSpawns do
		local slot = r * 3 + index
		local x, z = turn(r, spawn.x, spawn.z)
		local axis = spawn.axis
		if r % 2 == 1 then
			axis = if axis == "z" then "x" else "z"
		end
		table.insert(spawnAt, { slot = slot, x = x, z = z, axis = axis })
		table.insert(spawnPoints, {
			slot = slot,
			x = x,
			y = 0,
			z = z,
			yaw = math.floor(math.deg(math.atan2(-x, -z)) + 0.5),
		})
	end
end

-- Doorsteps: a zone of 32 core Tier 1 objects (a) and 8 slot.small (b) on the lane, within 10 studs of the spawn.
-- The second zone sits on the main-street side of the first.
for _, spawn in spawnAt do
	local slot = spawn.slot
	local name = string.format("dt_z_door_%02d", slot)
	-- Which way is the main street along this lane? Towards the origin on the lane's long axis.
	local along = if spawn.axis == "z" then spawn.z else spawn.x
	local towards = if along > 0 then -1 else 1
	local function at(offset: number): (number, number)
		if spawn.axis == "z" then
			return spawn.x, spawn.z + towards * offset
		end
		return spawn.x + towards * offset, spawn.z
	end
	local function strip(offset: number, length: number): (number, number, number, number)
		local sx, sz = at(offset)
		if spawn.axis == "x" then
			return sx, sz, length, 8
		end
		return sx, sz, 8, length
	end
	-- A pad of things a D 2 ball can eat on the spawn itself, then the bigger Tier 1 kinds in the strips either side
	-- of it: the ball clears the pad (D 3) before it meets anything it cannot eat.
	local px, pz, pw, pd = strip(0, 4.0)
	zone(name .. "_a", px, pz, pw, pd, 0, t1Crumbs, TUNE.padCount, slot * 100 + 1, slot)
	local fx, fz, fw, fd = strip(3.5, 2.95)
	zone(name .. "_d", fx, fz, fw, fd, 0, t1Big, TUNE.stripCount, slot * 100 + 4, slot)
	local gx, gz, gw, gd = strip(-3.5, 2.95)
	zone(name .. "_e", gx, gz, gw, gd, 0, t1Big, TUNE.stripCount, slot * 100 + 5, slot)
	local bx, bz, bw, bd = strip(6.55, 3)
	zone(name .. "_b", bx, bz, bw, bd, 0, mix({ "slot.small" }), 8, slot * 100 + 2, slot)
	local cx, cz, cw, cd = strip(-6.55, 3)
	zone(name .. "_c", cx, cz, cw, cd, 0, t1Big, TUNE.bigCrumbs, slot * 100 + 3, slot)
end

-- Lane scatter: 16 Tier 2 objects per quarter on the free lane segments (canonical coordinates).
local laneSegments = {
	{ x = 52.5, z = -85.025, w = 8, d = 9.95 },
	{ x = 52.5, z = -21, w = 8, d = 11.9 },
	{ x = 73.25, z = -52.5, w = 33.5, d = 8 },
	{ x = 21, z = -52.5, w = 11.9, d = 8 },
}
for r = 0, 3 do
	for index, segment in laneSegments do
		local x, z = turn(r, segment.x, segment.z)
		local w, d = segment.w, segment.d
		if r % 2 == 1 then
			w, d = d, w
		end
		zone(`dt_z_lane_{r}_{index}`, x, z, w, d, 0, t2Lane, TUNE.laneT2[index], seed(), nil)
	end
end

-- Bollard gates: eight cones per main-street gap, 3.75 apart (1.75 between them), in the plane of the edge wall.
for r = 0, 3 do
	for index = 1, 8 do
		local x, z = turn(r, -13.125 + (index - 1) * 3.75, -91)
		fixedAt(`dt_g_{r}_{index}`, "traffic_cone", x, 0, z)
	end
end

-- Shops on the plinths. Ring 1 Tier 5 is the shop-row on the far plinth; Tier 4 the rest.
for r = 0, 3 do
	local far = plinthArea[`far{r}`]
	fixedAt(
		`dt_b1_{r}_far`,
		"corner_shop_row",
		(far.x0 + far.x1) / 2,
		PLINTH,
		(far.z0 + far.z1) / 2
	)
	stock(`dt_b1_{r}_north`, plinthArea[`north{r}`], PLINTH, { "corner_bakery" }, 1)
	stock(`dt_b1_{r}_east`, plinthArea[`east{r}`], PLINTH, { "corner_bakery" }, 1)
	stock(`dt_b1_{r}_ia`, plinthArea[`inner_a{r}`], PLINTH, { "kiosk", "kiosk" }, 2)
	stock(`dt_b1_{r}_ib`, plinthArea[`inner_b{r}`], PLINTH, { "bus_shelter" }, 1)
end
-- The landmark slot stands on the pedestal; the fountain beside it on the plaza slab; one keyboard in a lane.
fixedAt("dt_l_1", "slot.landmark", 0, 2.4, 0)
fixedAt("dt_f_fountain", "fountain", 24, 0.3, -24)
fixedAt("dt_f_keyboard", "keyboard", 52.5, 0, -52.5)

-- Tier 1 and 2 heroes in free lane segments.
do
	local function hero(objectId: string, r: number, x: number, z: number)
		local tx, tz = turn(r, x, z)
		fixedAt("dt_h_" .. objectId, objectId, tx, 0, tz)
	end
	hero("rubber_duck_sunglasses", 0, 52.5, -56)
	hero("lost_sneaker", 1, 45.8, -52.5)
	hero("inflatable_flamingo", 2, 52.5, -56)
	hero("spinning_office_chair", 3, 45.8, -52.5)
	hero("pizza_box_tower", 1, 52.5, -56)
end

-- Ring 2: the Terraces --------------------------------------------------------------------------------------------
-- Canonical north side, turned in a pinwheel (each side runs past one corner). Loop A is m 92 to 108, row 1 is m 108
-- to 142 (34 deep), loop B is m 142 to 158, row 2 is m 158 to 185 (27 deep). Radial streets are 16 wide.

local ROW1: { { number } } = { { -108, -63 }, { -47, -15 }, { 15, 47 }, { 63, 132 } }
local ROW2: { { number } } = { { -132, -63 }, { -47, -15 }, { 15, 47 }, { 63, 132 }, { 148, 185 } }
local t4Fill =
	{ "corner_bakery", "kiosk", "delivery_van", "big_street_tree", "taxi", "pickup_truck" }
local t5Queue: { string } = {}
for _ = 1, 12 do
	table.insert(t5Queue, "townhouse")
end
for _ = 1, 5 do
	table.insert(t5Queue, "corner_shop_row")
end
local t5Next = 1

local function terraceBuilding(prefix: string, area: Area, y: number, deep: number)
	local w, d = area.x1 - area.x0, area.z1 - area.z0
	local nextBuilding = t5Queue[t5Next]
	if
		nextBuilding ~= nil
		and math.min(w, d) >= sizeOf[nextBuilding] + 1
		and math.max(w, d) >= sizeOf[nextBuilding] + 1
	then
		t5Next += 1
		fixedAt(prefix, nextBuilding, (area.x0 + area.x1) / 2, y, (area.z0 + area.z1) / 2)
	else
		stock(prefix, area, y, t4Fill, deep)
	end
end

for r = 0, 3 do
	-- Row 1: the fourth segment holds the alley, so it is two plinths with a roofed 4.5 gap between flank walls.
	for index, segment in ROW1 do
		if index == 4 then
			local a = slab(`dt_pl2_{r}_r1_{index}a`, r, 63, 94.25, -142, -108, PLINTH, "w-sidewalk")
			local b =
				slab(`dt_pl2_{r}_r1_{index}b`, r, 100.75, 132, -142, -108, PLINTH, "w-sidewalk")
			slab(`dt_sc_{r}_wa`, r, 94.25, 95.25, -142, -108, 5.2, "w-wall-a")
			slab(`dt_sc_{r}_wb`, r, 99.75, 100.75, -142, -108, 5.2, "w-wall-a")
			slab(`dt_sc_{r}_roof`, r, 94.25, 100.75, -142, -108, 5.4, "w-roof-a", 4.9)
			terraceBuilding(`dt_b2_{r}_r1_{index}a`, a, PLINTH, 2)
			terraceBuilding(`dt_b2_{r}_r1_{index}b`, b, PLINTH, 2)
		else
			local area = slab(
				`dt_pl2_{r}_r1_{index}`,
				r,
				segment[1],
				segment[2],
				-142,
				-108,
				PLINTH,
				"w-sidewalk"
			)
			terraceBuilding(`dt_b2_{r}_r1_{index}`, area, PLINTH, 3)
		end
	end
	-- Row 2. The north side's third segment is left empty for a golden spot; the west side's first becomes the
	-- storm-drain tunnel (r = 3 turns canonical north into west).
	for index, segment in ROW2 do
		if r == 3 and index == 4 then
			slab(`dt_pl2_{r}_r2_{index}a`, r, 63, 132, -185, -174.75, PLINTH, "w-sidewalk")
			slab(`dt_pl2_{r}_r2_{index}b`, r, 63, 132, -168.25, -158, PLINTH, "w-sidewalk")
			slab(`dt_drain_{r}_wa`, r, 63, 132, -174.75, -173.75, 5.2, "dt-concrete")
			slab(`dt_drain_{r}_wb`, r, 63, 132, -169.25, -168.25, 5.2, "dt-concrete")
			slab(`dt_drain_{r}_roof`, r, 63, 132, -174.75, -168.25, 5.4, "dt-concrete", 4.9)
		else
			local area = slab(
				`dt_pl2_{r}_r2_{index}`,
				r,
				segment[1],
				segment[2],
				-185,
				-158,
				PLINTH,
				"w-sidewalk"
			)
			-- Left empty at r 0, index 3: golden spot 1 stands here.
			if r ~= 0 or index ~= 3 then
				terraceBuilding(`dt_b2_{r}_r2_{index}`, area, PLINTH, 4)
			end
		end
	end
end

-- Scatter on loop A (Tier 2) and the radial streets (Tier 3); loop B is left for the markers and the winter overlays.
for r = 0, 3 do
	for index, span in { { 17, 45 }, { 65, 90 }, { -45, -17 }, { -90, -65 } } do
		local cx, cz = turn(r, (span[1] + span[2]) / 2, -105.5)
		local w, d = span[2] - span[1], 5
		if r % 2 == 1 then
			w, d = d, w
		end
		zone(`dt_z_loopa_{r}_{index}`, cx, cz, w, d, 0, t2Loop, TUNE.loopT2, seed(), nil)
	end
	for index, tangent in { 55, -55 } do
		local cx, cz = turn(r, tangent, -125)
		local w, d = 16, 34
		if r % 2 == 1 then
			w, d = d, w
		end
		zone(`dt_z_radial_{r}_{index}`, cx, cz, w, d, 0, t3Radial, TUNE.radialT3, seed(), nil)
	end
end

-- Ring 3: the Yards ------------------------------------------------------------------------------------------------
-- Five districts on slabs 0.25 to 0.5 thick. Each scatter run is a grid of square tiles; every tile is one zone.
local TILE = { t2 = 24, t3 = 36, t4 = 42 }
local tileMix: { [string]: { MixEntry } } = { t2 = t2All, t3 = t3All, t4 = t4Yard }
local runs = 0
local function tileRun(
	prefix: string,
	kind: string,
	x0: number,
	z0: number,
	nx: number,
	nz: number,
	y: number,
	count: number
)
	local ts = TILE[kind]
	runs += 1
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			zone(
				`dt_z_{prefix}_{kind}{runs}_{i}_{j}`,
				x0 + ts * (i + 0.5),
				z0 + ts * (j + 0.5),
				ts,
				ts,
				y,
				tileMix[kind],
				count,
				seed(),
				nil
			)
		end
	end
end

-- Park (north-west): lawns, a pond, hedges. Winter adds a sledding slope and a rink (theme blocks and overlays).
block("dt_park_lawn_n", "Block", -152.5, 0.15, -237.5, 0, 275, 0.3, 105, "w-grass")
block("dt_park_lawn_w", "Block", -237.5, 0.15, -100, 0, 105, 0.3, 170, "w-grass")
block("dt_park_pond", "Block", -270, 0.175, -270, 0, 40, 0.35, 40, "w-water")
for index, x in { -265, -215, -165, -115, -65, -30 } do
	box(`dt_park_hedge_{index}`, x, -188, 30, 1.5, 1.2, "w-leaf-dark")
end
box("dt_park_gate_a", -240, -186, 4, 1, 1.2, "w-wood")
box("dt_park_golden", -70, -215, 8, 8, 1.0, "w-kerb")
tileRun("park", "t3", -244, -282, 4, 2, 0.3, TUNE.parkT3)
tileRun("park", "t3", -286, -70, 2, 1, 0.3, TUNE.parkT3)
tileRun("park", "t2", -210, -70, 1, 2, 0.3, 4)
fixedAt("dt_f_park_ev", "ev_charging_station", -60, 0.3, -250)
fixedAt("dt_h_inflatable_tube_guy", "inflatable_tube_guy", -30, 0.3, -215)
fixedAt("dt_f_park_bench", "bench", -30, 0.3, -285)
fixedAt("dt_f_park_tree", "big_street_tree", -30, 0.3, -260)
fixedAt("dt_f_park_street_tree", "street_tree", -50, 0.3, -285)
-- Yard dressing slot (snowman, paddling pool): on the west lawn.
zone("dt_z_park_slot", -255, -140, 20, 20, 0.3, mix({ "slot.yard" }), 4, 3003, nil)

-- Market (north-east): paving, counters, vans, vending.
block("dt_market_n", "Block", 152.5, 0.15, -237.5, 0, 275, 0.3, 105, "w-sand")
block("dt_market_e", "Block", 237.5, 0.15, -100, 0, 105, 0.3, 170, "w-sand")
for index = 0, 5 do
	box(`dt_market_counter_{index + 1}`, 40 + index * 40, -195, 14, 4, 1.2, "w-wood")
end
tileRun("market", "t3", 30, -285, 4, 2, 0.3, TUNE.yardT3)
tileRun("market", "t2", 262, -285, 1, 3, 0.3, 4)
tileRun("market", "t4", 190, -175, 2, 3, 0.3, TUNE.yardT4)
fixedAt("dt_f_market_apartment", "apartment_block", 230, 0.3, -250)
fixedAt("dt_f_market_billboard", "billboard", 270, 0.3, -200)
fixedAt("dt_h_arcade_cabinet", "arcade_cabinet", 280, 0.3, -30)
fixedAt("dt_h_vending_machine", "vending_machine", 280, 0.3, -45)
fixedAt("dt_f_market_hotdog", "hot_dog_cart", 280, 0.3, -60)
-- Medium dressing slot (gift box, beach ball): on the east paving.
zone("dt_z_market_slot", 280, -175, 12, 12, 0.3, mix({ "slot.medium" }), 4, 3103, nil)

-- Construction Site (west, south half): hoarding, scaffold ramps up to a container platform.
block("dt_site_slab", "Block", -237.5, 0.25, 100, 0, 105, 0.5, 170, "dt-concrete")
for index, z in { 35, 75, 115, 155 } do
	box(`dt_site_hoarding_{index}`, -190, z, 1, 20, 4, "dt-hoarding", 0.5)
end
box("dt_site_platform", -250, 100, 20, 20, 2, "w-metal", 0.5)
ramp("dt_site_ramp_w", -263, 100, 90, 8, 2, 6, 0.5, "w-wood")
ramp("dt_site_ramp_e", -237, 100, 270, 8, 2, 6, 0.5, "w-wood")
ramp("dt_site_ramp_n", -250, 87, 180, 8, 2, 6, 0.5, "w-wood")
ramp("dt_site_ramp_s", -250, 113, 0, 8, 2, 6, 0.5, "w-wood")
fixedAt("dt_f_site_container", "shipping_container", -250, 2.5, 100)
tileRun("site", "t3", -286, 22, 2, 1, 0.5, TUNE.yardT3)
tileRun("site", "t4", -286, 132, 2, 1, 0.5, TUNE.yardT4)

-- Car Park (south, west half): three decks, four ramps, two parapets; the golden spot is on the top deck.
block("dt_car_slab", "Block", -152.5, 0.25, 237.5, 0, 275, 0.5, 105, "dt-concrete")
box("dt_car_deck_1", -170, 255, 60, 60, 2, "dt-concrete", 0.5)
box("dt_car_deck_2", -170, 255, 40, 40, 2, "dt-concrete", 2.5)
box("dt_car_deck_3", -170, 255, 20, 20, 2, "dt-concrete", 4.5)
ramp("dt_car_ramp_1", -170, 222, 0, 8, 2, 6, 0.5, "w-metal")
ramp("dt_car_ramp_2", -170, 232, 0, 8, 2, 6, 2.5, "w-metal")
ramp("dt_car_ramp_3", -170, 242, 0, 8, 2, 6, 4.5, "w-metal")
ramp("dt_car_ramp_4", -137, 255, 270, 8, 2, 6, 0.5, "w-metal")
box("dt_car_parapet_1", -170, 265.3, 20, 0.6, 1, "dt-concrete", 6.5)
box("dt_car_parapet_2", -170, 274.7, 40, 0.6, 1, "dt-concrete", 4.5)
tileRun("car", "t3", -286, 190, 2, 2, 0.5, TUNE.yardT3)
tileRun("car", "t2", -130, 190, 4, 3, 0.5, 3)

-- Rail Yard (south-east): bed, six tracks, a platform, containers and vans.
block("dt_rail_s", "Block", 152.5, 0.125, 237.5, 0, 275, 0.25, 105, "w-soil")
block("dt_rail_e", "Block", 237.5, 0.125, 100, 0, 105, 0.25, 170, "w-soil")
for index = 0, 5 do
	block(
		`dt_rail_track_{index + 1}`,
		"Block",
		125,
		0.15,
		232 + index * 4,
		0,
		190,
		0.3,
		1.5,
		"w-metal-dark"
	)
end
box("dt_rail_platform_1", 100, 262, 100, 8, 1.0, "w-sidewalk")
box("dt_rail_platform_2", 100, 276, 100, 8, 1.0, "w-sidewalk")
tileRun("rail", "t3", 30, 190, 3, 1, 0.25, TUNE.yardT3)
tileRun("rail", "t2", 150, 190, 4, 1, 0.25, 4)
tileRun("rail", "t4", 190, 30, 2, 3, 0.25, TUNE.yardT4)
fixedAt("dt_f_rail_cinema", "cinema", 250, 0.25, 270)

-- Separators: low fences (top 3) at the seams between yards; the 30-wide approaches stay open.
box("dt_sep_1", -237.5, 185, 105, 1, 3, "w-wood")
box("dt_sep_2", -185, 237.5, 1, 105, 3, "w-wood")
box("dt_sep_3", 185, 237.5, 1, 105, 3, "w-wood")
box("dt_sep_4", 237.5, 185, 105, 1, 3, "w-wood")
box("dt_sep_5", -185, -237.5, 1, 105, 3, "w-wood")
box("dt_sep_6", 185, -237.5, 1, 105, 3, "w-wood")

-- Ring 4: the Boulevard --------------------------------------------------------------------------------------------
-- m 295 to 355: inner carriageway 26, median 8 (top 0.8), outer carriageway 26.
for r = 0, 3 do
	slab(`dt_med_{r}_a`, r, -321, -15, -329, -321, 0.8, "w-kerb")
	slab(`dt_med_{r}_b`, r, 15, 329, -329, -321, 0.8, "w-kerb")
	for index, x in { -200, 60, 220 } do
		slab(`dt_shelter_{r}_{index}`, r, x - 3, x + 3, -327, -323, 3.0, "w-glass", 0.8)
	end
	slab(`dt_billboard_{r}`, r, -84, -72, -326, -324, 7.0, "w-trim", 0.8)
	for half = 0, 1 do
		local sign = if half == 0 then 1 else -1
		-- Inner carriageway (z -321 to -295): cars.
		local innerX, innerW = sign * 105, 160
		local cx, cz = turn(r, innerX, -308)
		local w, d = innerW, 26
		if r % 2 == 1 then
			w, d = d, w
		end
		zone(`dt_z_blv_in_{r}_{half}`, cx, cz, w, d, 0, t4Cars, TUNE.boulevardT4, seed(), nil)
		-- Outer carriageway (z -355 to -329): small things, Tier 2 near the axis and Tier 3 beyond.
		local outer: { { x: number, w: number, mix: { MixEntry }, count: number } } = {
			{ x = sign * 87.5, w = 125, mix = t2All, count = TUNE.boulevardT2 },
			{ x = sign * 220, w = 130, mix = t3Radial, count = TUNE.boulevardT3 },
		}
		for part, spec in outer do
			local ox, oz = turn(r, spec.x, -350.5)
			local ow, od = spec.w, 9
			if r % 2 == 1 then
				ow, od = od, ow
			end
			zone(
				`dt_z_blv_out_{r}_{half}_{part}`,
				ox,
				oz,
				ow,
				od,
				0,
				spec.mix,
				spec.count,
				seed(),
				nil
			)
		end
	end
end
-- Street dressing slot (sleigh, ice cream truck): one on the outer carriageway of each side.
for r = 0, 3 do
	local sx, sz = turn(r, -300, -308)
	zone(`dt_z_blv_slot_{r}`, sx, sz, 20, 20, 0, mix({ "slot.street" }), 1, 4301 + r, nil)
end
-- Big vehicles stand in the unzoned stretches of the north carriageway.
fixedAt("dt_f_blv_traffic_light", "traffic_light", 280, 0.8, -325)
fixedAt("dt_f_blv_street_lamp", "street_lamp", -280, 0.8, -325)
fixedAt("dt_f_blv_bus", "city_bus", 210, 0, -308)
fixedAt("dt_f_blv_fire", "fire_engine", 240, 0, -308)
fixedAt("dt_f_blv_garbage", "garbage_truck", 268, 0, -308)
fixedAt("dt_h_donut_food_truck", "donut_food_truck", -210, 0, -308)
fixedAt("dt_h_monster_truck", "monster_truck", -245, 0, -308)

-- Ring 5: Skyline (north, east) and Harbour (south, west), then the horizon ----------------------------------------
for index, span in { { 20, 230 }, { 230, 440 }, { -230, -20 }, { -440, -230 } } do
	slab(`dt_podium_n{index}`, 0, span[1], span[2], -440, -360, PLINTH, "w-sidewalk")
end
for index, span in { { -360, -190 }, { -190, -20 }, { 20, 190 }, { 190, 360 } } do
	slab(`dt_podium_e{index}`, 0, 360, 440, span[1], span[2], PLINTH, "w-sidewalk")
end
fixedAt("dt_h_glass_tower", "glass_tower", 330, PLINTH, -400)
fixedAt("dt_h_tower_crane", "tower_crane", -330, PLINTH, -400)
fixedAt("dt_h_ferris_wheel", "ferris_wheel", 400, PLINTH, -275)
fixedAt("dt_h_rocket_water_tower", "rocket_water_tower", 400, PLINTH, 275)
local t5Towers = { "apartment_block", "apartment_block", "ev_charging_station", "townhouse" }
local skylineAreas: { Area } = {
	{ x0 = 22, x1 = 228, z0 = -430, z1 = -370 },
	{ x0 = -228, x1 = -22, z0 = -430, z1 = -370 },
	{ x0 = 232, x1 = 296, z0 = -430, z1 = -370 },
	{ x0 = 364, x1 = 438, z0 = -430, z1 = -370 },
	{ x0 = -438, x1 = -366, z0 = -430, z1 = -370 },
	{ x0 = -298, x1 = -232, z0 = -430, z1 = -370 },
	{ x0 = 370, x1 = 430, z0 = -358, z1 = -306 },
	{ x0 = 370, x1 = 430, z0 = -244, z1 = -22 },
	{ x0 = 370, x1 = 430, z0 = 22, z1 = 256 },
	{ x0 = 370, x1 = 430, z0 = 294, z1 = 358 },
}
for index, area in skylineAreas do
	stock(`dt_b5_{index}`, area, PLINTH, t5Towers, 6)
end

-- Harbour: quays (top 1.2) broken at the avenues, a shallow basin beyond, and ramped lips back out of the water.
for index, span in { { -400, -20 }, { 20, 440 } } do
	slab(`dt_quay_s{index}`, 0, span[1], span[2], 360, 400, PLINTH, "w-sidewalk")
end
for index, span in { { -360, -20 }, { 20, 360 } } do
	slab(`dt_quay_w{index}`, 0, -400, -360, span[1], span[2], PLINTH, "w-sidewalk")
end
for index, x in { -300, -150, 150, 300 } do
	ramp(`dt_lip_s{index}`, x, 402.5, 180, 8, 1.6, 5, -0.4, "w-sidewalk")
end
for index, z in { -250, -100, 100, 250 } do
	ramp(`dt_lip_w{index}`, -402.5, z, 90, 8, 1.6, 5, -0.4, "w-sidewalk")
end
stock(
	"dt_b5_qs1",
	{ x0 = -398, x1 = -22, z0 = 370, z1 = 390 },
	PLINTH,
	{ "shipping_container" },
	4,
	30
)
stock(
	"dt_b5_qs2",
	{ x0 = 22, x1 = 438, z0 = 370, z1 = 390 },
	PLINTH,
	{ "shipping_container" },
	4,
	30
)
stock(
	"dt_b5_qw1",
	{ x0 = -392, x1 = -368, z0 = -358, z1 = -22 },
	PLINTH,
	{ "shipping_container" },
	4,
	30
)
stock(
	"dt_b5_qw2",
	{ x0 = -392, x1 = -368, z0 = 22, z1 = 358 },
	PLINTH,
	{ "shipping_container" },
	4,
	30
)
zone("dt_z_quay_1", -200, 365, 300, 9, PLINTH, t3Quay, TUNE.quay, seed(), nil)
zone("dt_z_quay_2", 230, 365, 190, 9, PLINTH, t3Quay, TUNE.quay, seed(), nil)

-- Horizon: eight static towers beyond the invisible wall. Blocks, not placements; nothing reaches them.
for index, at in
	{
		{ -300, -500 },
		{ -100, -500 },
		{ 100, -500 },
		{ 300, -500 },
		{ 500, -300 },
		{ 500, -100 },
		{ 500, 100 },
		{ 500, 300 },
	}
do
	local height = 120 + (index % 3) * 40
	block(`dt_horizon_{index}`, "Block", at[1], height / 2, at[2], 0, 60, height, 60, "w-wall-b")
end

-- Markers (data-model.md §13) ---------------------------------------------------------------------------------------
-- yaw is in degrees and local +Z is the facing. Boosters and traps stand on open asphalt (the Markers rules refuse
-- any block above 0.2 under them); golden spots stand on a plinth, pedestal, median, deck or podium.

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

-- Old Quarter
spot("booster-dash-1", "BoosterSpot", "dash", -6, -50)
spot("trap-bumper-1", "TrapSpot", "bumper", 7, -70)
-- Terraces (loop B)
spot("booster-magnet-1", "BoosterSpot", "magnet", -100, -150)
spot("booster-slick_trail-1", "BoosterSpot", "slick_trail", 150, -100)
spot("trap-slow-1", "TrapSpot", "slow", -150, 100)
-- Yards (the main-street approaches)
spot("booster-spring-1", "BoosterSpot", "spring", 0, -250, 0)
spot("booster-shield-1", "BoosterSpot", "shield", 200, 0)
spot("trap-slick-1", "TrapSpot", "slick", 260, 0)
sweeperLoop(
	"trap-sweeper-1",
	{ { x = -8, z = 205 }, { x = 8, z = 205 }, { x = 8, z = 235 }, { x = -8, z = 235 } }
)
-- Boulevard
spot("booster-dash-2", "BoosterSpot", "dash", 0, -345)
spot("trap-bumper-2", "TrapSpot", "bumper", 12, -310)
sweeperLoop(
	"trap-sweeper-2",
	{ { x = -8, z = 315 }, { x = 8, z = 315 }, { x = 8, z = 328 }, { x = -8, z = 328 } }
)
-- Skyline and Harbour
spot("booster-shield-2", "BoosterSpot", "shield", 0, -380)
spot("booster-magnet-2", "BoosterSpot", "magnet", 390, 0)
spot("trap-slick-2", "TrapSpot", "slick", 0, 380)
-- Golden spots: a Terraces plinth, the Park pedestal, the Car Park top deck, a Boulevard median, a Skyline podium.
spot("golden-1", "GoldenSpot", "golden", 31, -171.5, 0, 1.2)
spot("golden-2", "GoldenSpot", "golden", -70, -215, 0, 1.0)
spot("golden-3", "GoldenSpot", "golden", -170, 255, 0, 6.5)
spot("golden-4", "GoldenSpot", "golden", 150, -325, 0, 0.8)
spot("golden-5", "GoldenSpot", "golden", 250, -364, 0, 1.2)

-- Keep-outs (data-model.md §12) ---------------------------------------------------------------------------------------
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

-- A canonical (north) rectangle turned r times, for the keep-outs.
local function turned(
	r: number,
	x: number,
	z: number,
	w: number,
	d: number
): (number, number, number, number)
	local tx, tz = turn(r, x, z)
	if r % 2 == 1 then
		return tx, tz, d, w
	end
	return tx, tz, w, d
end

for r = 0, 3 do
	-- Four gates: the bollard gaps at the Old Quarter edge. The keep-out is the street mouth just outside the cones.
	local gx, gz, gw, gd = turned(r, 0, -96, 30, 7)
	keepOut(`ko_gate_{r + 1}`, "gate", gx, gz, gw, gd)
	-- Four alleys (one per side) and, on the west side, the storm drain.
	local sx, sz, sw, sd = turned(r, 97.5, -125, 6.5, 34)
	keepOut(`ko_shortcut_{r}`, "shortcut", sx, sz, sw, sd)
	-- Four main-street corridors from the plaza edge to the end of Ring 2.
	local cx, cz, cw, cd = turned(r, 0, -107.5, 30, 155)
	keepOut(`ko_sightline_street_{r}`, "sightline", cx, cz, cw, cd)
end
do
	local dx, dz, dw, dd = turned(3, 97.5, -171.5, 69, 8)
	keepOut("ko_shortcut_drain", "shortcut", dx, dz, dw, dd)
end
-- Twelve lane corridors, 8 wide, from each spawn to the main street its lane meets.
for r = 0, 3 do
	local lanes = {
		{ x = 52.5, z = -25, w = 8, d = 20 },
		{ x = 52.5, z = -43.5, w = 8, d = 57 },
		{ x = 25, z = -52.5, w = 20, d = 8 },
	}
	for index, lane in lanes do
		local lx, lz, lw, ld = turned(r, lane.x, lane.z, lane.w, lane.d)
		keepOut(`ko_sightline_lane_{r * 3 + index}`, "sightline", lx, lz, lw, ld)
	end
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

-- Winter overlays (data-model.md §14): Tier 2 to 4 dressing in areas the base layout leaves free. They sit clear of
-- every keep-out and every base zone, so they never plug a route.
local overlayZones: { Zone } = {}
local overlayFixed: { Fixed } = {}

local function overlayZone(
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	objectId: string,
	count: number
)
	table.insert(overlayZones, {
		id = id,
		x = x,
		z = z,
		w = w,
		d = d,
		y = y,
		mix = { { objectId = objectId, weight = 1 } },
		count = count,
		seed = seed(),
		spawnSlot = nil,
	})
end

-- Park: sleds at the foot of the slope, snow piles on the lawn, the pond becomes a rink.
overlayZone("dt_ol_sleds", -220, -125, 46, 10, 0.3, "wooden_sled", 14)
overlayZone("dt_ol_snow_1", -240, -178, 100, 14, 0.3, "snow_pile", 6)
overlayZone("dt_ol_snow_2", -240, -160, 100, 14, 0.3, "snow_pile", 6)
table.insert(overlayFixed, {
	id = "dt_ol_rink",
	objectId = "ice_rink",
	x = -270,
	y = 0.35,
	z = -270,
	yaw = 0,
	spawnSlot = nil,
})
-- Market: cocoa carts between the stalls and the paving, market stalls on the east side.
overlayZone("dt_ol_cocoa", 100, -206, 150, 13, 0.3, "cocoa_cart", 8)
overlayZone("dt_ol_stalls", 230, -29, 80, 22, 0.3, "market_stall", 5)
-- Boulevard: pots and wreaths on the median (canonical north, turned for the other three sides).
for r = 0, 3 do
	local ax, az = turn(r, -135, -325)
	local bx, bz = turn(r, 110, -325)
	local cx, cz = turn(r, -40, -325)
	local dx, dz = turn(r, 275, -325)
	local d = 6
	local w30, w25, w40 = 30, 25, 40
	local d30, d25, d40 = d, d, d
	if r % 2 == 1 then
		w30, d30 = d30, w30
		w25, d25 = d25, w25
		w40, d40 = d40, w40
	end
	overlayZone(`dt_ol_pots_{r}_1`, ax, az, w30, d30, 0.8, "poinsettia_pot", 2)
	overlayZone(`dt_ol_pots_{r}_2`, bx, bz, w30, d30, 0.8, "poinsettia_pot", 2)
	overlayZone(`dt_ol_wreaths_{r}_1`, cx, cz, w25, d25, 0.8, "wreath", 2)
	overlayZone(`dt_ol_wreaths_{r}_2`, dx, dz, w40, d40, 0.8, "wreath", 2)
end

-- Holiday-only scenery (F2): garlands over the Ring 1 and Ring 2 main streets, the sledding slope and its ramp.
for r = 0, 3 do
	for index, m in { 45, 65, 100, 125, 150, 175 } do
		local gx, gz, gw, gd = turned(r, 0, -m, 30, 0.6)
		block(`dt_garland_{r}_{index}`, "Block", gx, 11, gz, 0, gw, 0.4, gd, "w-trim", winterBlocks)
	end
end
ramp("dt_park_slope", -220, -95, 0, 40, 5, 40, 0.3, "w-season", winterBlocks)
ramp("dt_park_sledramp", -255, -95, 0, 10, 2, 6, 0.3, "w-wood", winterBlocks)

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
		slots: { [string]: string },
		overlays: { zones: { Zone }, fixedPlacements: { Fixed } },
		heroVariants: { [string]: { assetKey: string, nameKey: string?, size: number? } },
		objects: { typeof(objects[1]) }?,
		blocks: { Block }?,
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
			blocks = winterBlocks,
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
flock("Old Quarter", { { 10, 10 }, { -10, 12 }, { 14, -12 }, { -12, -10 }, { 0, 18 } })
flock("Terraces", { { 20, -125 }, { 30, -112 }, { -30, -112 }, { -20, -125 }, { 0, -118 } })
flock("Park", { { -120, -250 }, { -100, -240 }, { -140, -200 }, { -110, -270 }, { -80, -265 } })
flock("Market", { { 100, -240 }, { 120, -230 }, { 60, -235 }, { 140, -250 }, { 80, -255 } })
flock("Harbour", { { -300, 392 }, { -250, 392 }, { 100, 392 }, { 150, 392 }, { 300, 392 } })

-- Ambient traffic (client-only, no collision): a lane of cars on the Terraces ring road and one round the Boulevard.
-- Both run clockwise on asphalt the static scatter leaves free (loop A's props sit on its outer half, the Boulevard's
-- on the outermost strip of its outer carriageway). Loops are squares with cut corners, so cars turn in two steps.
local function squareLoop(half: number, cut: number): { { x: number, z: number } }
	return {
		{ x = -half + cut, z = -half },
		{ x = half - cut, z = -half },
		{ x = half, z = -half + cut },
		{ x = half, z = half - cut },
		{ x = half - cut, z = half },
		{ x = -half + cut, z = half },
		{ x = -half, z = half - cut },
		{ x = -half, z = -half + cut },
	}
end
local carColours: { { number } } = {
	{ 214, 70, 62 },
	{ 238, 196, 66 },
	{ 70, 118, 196 },
	{ 236, 238, 242 },
	{ 62, 146, 98 },
	{ 232, 132, 52 },
}
local function convoy(
	count: number,
	first: number,
	kinds: { "car" | "van" | "bus" }
): { { kind: "car" | "van" | "bus", phase: number, colour: { number } } }
	local cars = {}
	for index = 1, count do
		table.insert(cars, {
			kind = kinds[(index - 1) % #kinds + 1],
			phase = (first + (index - 1) / count) % 1,
			colour = carColours[(index * 5 + math.floor(first * 100)) % #carColours + 1],
		})
	end
	return cars
end
local traffic = {
	{
		id = "terraces_ring",
		speed = 16,
		waypoints = squareLoop(99, 6),
		cars = convoy(7, 0, { "car", "car", "van", "car", "bus" }),
	},
	{
		id = "boulevard",
		speed = 24,
		waypoints = squareLoop(339, 12),
		cars = convoy(16, 0.03, { "car", "car", "van", "car", "car", "bus" }),
	},
}

local Downtown = {
	worldId = "downtown",
	starThresholds = { 20, 45, 80 },
	-- PROVISIONAL, owner to confirm: solved with the pace model (tests/unit/Pace.test, 008 research R-07).
	growthK = 3.6,
	halfExtent = 440,
	outerHalfExtent = 560,
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
	maxPlacements = 1500,
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
		center = { x = -620, z = 0 },
		halfExtent = 24,
		spawn = { x = 0, z = 0 },
		padRadius = 5,
		assetKey = "hub",
	},
	-- Used only when Flags.ThemeSystem is off: a copy of the winter look, with fog pushed out for the 320-stud camera.
	lighting = {
		ambient = { 150, 165, 190 },
		outdoorAmbient = { 170, 185, 210 },
		brightness = 2,
		clockTime = 16.5,
		fogColor = { 205, 218, 235 },
		fogStart = 500,
		fogEnd = 1600,
		atmosphereDensity = 0.3,
		atmosphereColor = { 200, 215, 235 },
		atmosphereDecay = { 190, 200, 220 },
	},
	ambient = { pigeons = pigeons, traffic = traffic },
}

return Downtown
