--!strict
-- Snow Village world data. Data only: no Roblox APIs and no requires, so Lune can load it directly.
-- Shape: the WorldDef type in Content/GreyBoxRoom.luau; checked against it in Worlds.luau.
-- Design: specs/004-snow-village/data-model.md. Zone counts are provisional until the grey-box gate.

-- Object catalogue: tier, id, size (longest side in studs), fallback shape of the placeholder part, and an
-- optional w-* palette role for the stand-in Colour (nil = the tier Colour).
local catalogue: { { tier: number, id: string, size: number, shape: string, role: string? } } = {
	{ tier = 1, id = "gumdrop", size = 0.3, shape = "Ball" },
	{ tier = 1, id = "button", size = 0.4, shape = "Cylinder" },
	{ tier = 1, id = "jingle_bell", size = 0.5, shape = "Ball" },
	{ tier = 1, id = "acorn", size = 0.5, shape = "Ball" },
	{ tier = 1, id = "marshmallow", size = 0.6, shape = "Cylinder" },
	{ tier = 1, id = "peppermint", size = 0.7, shape = "Cylinder" },
	{ tier = 1, id = "pine_cone", size = 0.7, shape = "Block" },
	{ tier = 1, id = "bauble", size = 0.8, shape = "Ball" },
	{ tier = 1, id = "cookie", size = 0.9, shape = "Cylinder" },
	{ tier = 1, id = "ribbon_bow", size = 1.0, shape = "Block" },
	{ tier = 1, id = "mini_snow_globe", size = 1.0, shape = "Ball" },
	{ tier = 1, id = "wooden_star", size = 1.1, shape = "Block" },
	{ tier = 1, id = "candy_cane", size = 1.2, shape = "Cylinder" },
	{ tier = 1, id = "sock_ornament", size = 1.3, shape = "Block" },
	{ tier = 1, id = "gingerbread_man", size = 1.3, shape = "Block" },
	{ tier = 1, id = "matchbox_car", size = 1.4, shape = "Block" },
	{ tier = 1, id = "toy_soldier", size = 1.5, shape = "Cylinder" },
	{ tier = 1, id = "cocoa_mug", size = 1.5, shape = "Cylinder" },

	{ tier = 2, id = "rubber_duck", size = 1.6, shape = "Ball" },
	{ tier = 2, id = "mitten_pair", size = 1.7, shape = "Block" },
	{ tier = 2, id = "gift_box", size = 1.8, shape = "Block" },
	{ tier = 2, id = "block_stack", size = 1.9, shape = "Block" },
	{ tier = 2, id = "snowball", size = 2.0, shape = "Ball" },
	{ tier = 2, id = "toy_drum", size = 2.2, shape = "Cylinder" },
	{ tier = 2, id = "snow_boot", size = 2.4, shape = "Block" },
	{ tier = 2, id = "teddy_bear", size = 2.5, shape = "Block" },
	{ tier = 2, id = "plush_penguin", size = 2.6, shape = "Block" },
	{ tier = 2, id = "tin_robot", size = 2.7, shape = "Block" },
	{ tier = 2, id = "lantern", size = 2.8, shape = "Cylinder" },
	{ tier = 2, id = "cat", size = 3.0, shape = "Block" },
	{ tier = 2, id = "wreath", size = 3.0, shape = "Cylinder" },
	{ tier = 2, id = "flower_pot", size = 3.1, shape = "Cylinder" },
	{ tier = 2, id = "toy_sled", size = 3.2, shape = "Block" },
	{ tier = 2, id = "rocking_horse", size = 3.5, shape = "Block" },

	{ tier = 3, id = "barrel", size = 4.2, shape = "Cylinder" },
	{ tier = 3, id = "mailbox", size = 4.5, shape = "Block" },
	{ tier = 3, id = "giant_gift", size = 4.5, shape = "Block" },
	{ tier = 3, id = "snow_mound", size = 4.8, shape = "Ball" },
	{ tier = 3, id = "dog", size = 5.0, shape = "Block" },
	{ tier = 3, id = "fence_section", size = 5.0, shape = "Block" },
	{ tier = 3, id = "firewood_stack", size = 5.0, shape = "Block" },
	{ tier = 3, id = "sledge", size = 6.0, shape = "Block" },
	{ tier = 3, id = "bicycle", size = 6.5, shape = "Block" },
	{ tier = 3, id = "bench", size = 7.0, shape = "Block" },
	{ tier = 3, id = "snowman", size = 8.0, shape = "Ball" },
	{ tier = 3, id = "cocoa_cart", size = 8.0, shape = "Block" },
	{ tier = 3, id = "pine_sapling", size = 9.0, shape = "Cylinder" },
	{ tier = 3, id = "street_lamp", size = 9.5, shape = "Cylinder" },

	{ tier = 4, id = "bus_shelter", size = 10, shape = "Block" },
	{ tier = 4, id = "market_stall", size = 11, shape = "Block" },
	{ tier = 4, id = "big_snowman", size = 12, shape = "Ball" },
	{ tier = 4, id = "kiosk", size = 12, shape = "Block" },
	{ tier = 4, id = "fountain", size = 13, shape = "Cylinder" },
	{ tier = 4, id = "car", size = 14, shape = "Block" },
	{ tier = 4, id = "sleigh", size = 15, shape = "Block" },
	{ tier = 4, id = "van", size = 17, shape = "Block" },
	{ tier = 4, id = "bandstand", size = 18, shape = "Cylinder" },
	{ tier = 4, id = "christmas_tree", size = 20, shape = "Cylinder" },
	{ tier = 4, id = "snowplough", size = 22, shape = "Block" },
	{ tier = 4, id = "bus", size = 25, shape = "Block" },

	{ tier = 5, id = "cottage", size = 28, shape = "Block" },
	{ tier = 5, id = "town_house", size = 34, shape = "Block" },
	{ tier = 5, id = "skating_rink", size = 40, shape = "Cylinder" },
	{ tier = 5, id = "clock_tower", size = 48, shape = "Block" },
}

-- Coin range per tier. Within a tier coins rise with size, from the low end to the high end.
local coinRange: { { number } } = { { 1, 2 }, { 3, 5 }, { 8, 15 }, { 20, 40 }, { 60, 100 } }

local tierSizeSpan: { { number } } = {}
for _, entry in catalogue do
	local span = tierSizeSpan[entry.tier]
	if span == nil then
		tierSizeSpan[entry.tier] = { entry.size, entry.size }
	else
		span[1] = math.min(span[1], entry.size)
		span[2] = math.max(span[2], entry.size)
	end
end

local objects = {}
for _, entry in catalogue do
	local span = tierSizeSpan[entry.tier]
	local range = coinRange[entry.tier]
	local fraction = (entry.size - span[1]) / (span[2] - span[1])
	table.insert(objects, {
		id = entry.id,
		tier = entry.tier,
		size = entry.size,
		coins = range[1] + math.floor((range[2] - range[1]) * fraction + 0.5),
		bookId = "snow_village." .. entry.id,
		nameKey = "object.snow_village." .. entry.id,
		icon = "cube",
		assetKey = entry.id,
		fallback = entry.shape,
		shade = nil,
		-- The stand-in takes the theme palette colour at this w-* role (005); nil keeps the tier colour.
		role = entry.role,
	})
end

local rewardTypes: { "trail" | "skin" } = { "trail", "skin", "trail", "skin", "trail" }
local headlineIcons = { "cube", "cube", "cube", "cube", "cube" }
local minDiameters = { 2, 5, 12, 30, 70 }
local sizeTiers = {}
for tier = 1, 5 do
	table.insert(sizeTiers, {
		tier = tier,
		nameKey = `tier.snow_village.{tier}.name`,
		minDiameter = minDiameters[tier],
		maxDiameter = minDiameters[tier + 1],
		headlineKey = `tier.snow_village.{tier}.headline`,
		headlineIcon = headlineIcons[tier],
		reward = {
			rewardId = `snow_village.reward.tier{tier}`,
			rewardType = rewardTypes[tier],
			nameKey = `reward.snow_village.tier{tier}.name`,
		},
	})
end

-- Object groups used by the zone mixes below. Weights are relative.
local function mix(ids: { string }, weight: number): { { objectId: string, weight: number } }
	local entries = {}
	for _, id in ids do
		table.insert(entries, { objectId = id, weight = weight })
	end
	return entries
end

local function join(
	...: { { objectId: string, weight: number } }
): { { objectId: string, weight: number } }
	local joined = {}
	for _, part in { ... } do
		for _, entry in part do
			table.insert(joined, entry)
		end
	end
	return joined
end

local tinyCrumbs = {
	"gumdrop",
	"button",
	"jingle_bell",
	"acorn",
	"marshmallow",
	"peppermint",
	"pine_cone",
	"bauble",
}
local bigCrumbs = {
	"cookie",
	"ribbon_bow",
	"mini_snow_globe",
	"wooden_star",
	"candy_cane",
	"sock_ornament",
	"gingerbread_man",
	"matchbox_car",
	"toy_soldier",
	"cocoa_mug",
}
local smallToys = { "rubber_duck", "mitten_pair", "gift_box", "block_stack", "snowball" }
local midToys = { "toy_drum", "snow_boot", "teddy_bear", "plush_penguin", "tin_robot" }
local bigToys = { "lantern", "cat", "wreath", "flower_pot", "toy_sled", "rocking_horse" }
local smallYard =
	{ "barrel", "mailbox", "giant_gift", "snow_mound", "dog", "fence_section", "firewood_stack" }
local bigYard =
	{ "sledge", "bicycle", "bench", "snowman", "cocoa_cart", "pine_sapling", "street_lamp" }
local smallStreet = { "bus_shelter", "market_stall", "big_snowman", "kiosk", "fountain" }
local midStreet = { "car", "sleigh", "van", "bandstand" }
local bigStreet = { "christmas_tree", "snowplough", "bus" }

-- Twelve spawn points on a 4 x 3 grid with a wide gap in the middle for the town square.
local spawnColumns = { -200, -100, 100, 200 }
local spawnRows = { -120, 0, 120 }
local porchHeight = 0.6

local spawnPoints = {}
local zones = {}
local blocks = {}
local markers = {}

local function zone(
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	entries: { { objectId: string, weight: number } },
	count: number,
	seed: number,
	slot: number?
)
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
		spawnSlot = slot,
	})
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

local slot = 0
for rowIndex, rowZ in spawnRows do
	for columnIndex, columnX in spawnColumns do
		slot += 1
		local name = string.format("sv_%02d", slot)
		table.insert(spawnPoints, { slot = slot, x = columnX, y = porchHeight, z = rowZ, yaw = 0 })

		-- Which way is the middle of the town: the porch ramp and the kerb face it.
		local inward = if columnX < 0 then 1 else -1

		zone(
			name .. "_porch",
			columnX,
			rowZ,
			20,
			20,
			porchHeight,
			join(mix(tinyCrumbs, 3), mix(bigCrumbs, 1)),
			-- 39: one placement is carved out for the spawn's slot.small zone (005, research R-11).
			39,
			slot * 100 + 1,
			slot
		)
		zone(
			name .. "_yard_a",
			columnX + 37,
			rowZ,
			22,
			20,
			0,
			join(mix(bigCrumbs, 2), mix(smallToys, 1)),
			-- 19 for the first eight spawns: one placement carved out for their slot.medium zone.
			if slot <= 8 then 19 else 20,
			slot * 100 + 2,
			nil
		)
		zone(
			name .. "_yard_b",
			columnX - 37,
			rowZ,
			22,
			20,
			0,
			join(mix(bigCrumbs, 2), mix(smallToys, 1)),
			20,
			slot * 100 + 3,
			nil
		)
		zone(
			name .. "_lawn_n",
			columnX,
			rowZ - 23,
			96,
			22,
			0,
			join(mix(midToys, 2), mix(bigToys, 2)),
			14,
			slot * 100 + 4,
			nil
		)
		zone(
			name .. "_lawn_s",
			columnX,
			rowZ + 23,
			96,
			22,
			0,
			join(mix(midToys, 1), mix(smallYard, 1)),
			12,
			slot * 100 + 5,
			nil
		)
		zone(
			name .. "_lane_n",
			columnX,
			rowZ - 47,
			96,
			22,
			0,
			mix(smallYard, 1),
			-- 9 for the first six spawns: one placement carved out for their slot.yard zone.
			if slot <= 6 then 9 else 10,
			slot * 100 + 6,
			nil
		)
		zone(
			name .. "_lane_s",
			columnX,
			rowZ + 47,
			96,
			22,
			0,
			mix(bigYard, 1),
			7,
			slot * 100 + 7,
			nil
		)

		block(
			name .. "_porch",
			"Block",
			columnX,
			porchHeight / 2,
			rowZ,
			0,
			22,
			porchHeight,
			22,
			"wood"
		)
		-- A wedge rises towards local +Z, so yaw -90 raises it towards -x and yaw 90 towards +x. One ramp on
		-- each side, both rising onto the porch.
		block(
			name .. "_ramp_in",
			"Wedge",
			columnX + inward * 18,
			porchHeight / 2,
			rowZ,
			if inward == 1 then -90 else 90,
			10,
			porchHeight,
			14,
			"snow_light"
		)
		block(
			name .. "_ramp_out",
			"Wedge",
			columnX - inward * 18,
			porchHeight / 2,
			rowZ,
			if inward == 1 then 90 else -90,
			10,
			porchHeight,
			14,
			"snow_light"
		)
		block(
			name .. "_kerb",
			"Block",
			columnX + inward * 30,
			0.75,
			rowZ + 11,
			0,
			28,
			1.5,
			2,
			"stone"
		)
		if rowIndex ~= 2 or columnIndex % 2 == 1 then
			table.insert(markers, {
				kind = if slot % 2 == 0 then "BoosterSpot" else "TrapSpot",
				x = columnX + inward * 40,
				y = 0,
				z = rowZ - 16,
			})
		end
	end
end

-- Town square in the middle and the T4 streets around it.
zone("sv_square", 0, 0, 100, 120, 0, join(mix(bigStreet, 1), mix(midStreet, 1)), 10, 9001, nil)
zone("sv_street_n", 0, -155, 100, 50, 0, join(mix(smallStreet, 1), mix(midStreet, 1)), 6, 9002, nil)
zone("sv_street_s", 0, 155, 100, 50, 0, join(mix(smallStreet, 1), mix(midStreet, 1)), 6, 9003, nil)
zone(
	"sv_band_n",
	0,
	-240,
	590,
	100,
	0,
	join(mix(smallStreet, 2), mix(midStreet, 2), mix(bigStreet, 1)),
	-- 24: two placements carved out for the two slot.street zones on this band.
	24,
	9004,
	nil
)
zone(
	"sv_band_s",
	0,
	240,
	590,
	100,
	0,
	join(mix(smallStreet, 2), mix(midStreet, 2), mix(bigStreet, 1)),
	24,
	9005,
	nil
)
zone("sv_edge_e", 276, 0, 40, 340, 0, mix(bigYard, 1), 14, 9006, nil)
zone("sv_edge_w", -276, 0, 40, 340, 0, mix(bigYard, 1), 14, 9007, nil)

-- Two low rooftops reached by long snow ramps, with Tier 2 toys on top.
for index, roofZ in { -100, 100 } do
	local direction = if roofZ < 0 then 1 else -1
	local name = if roofZ < 0 then "sv_roof_n" else "sv_roof_s"
	block(name, "Block", 0, 5.5, roofZ, 0, 24, 11, 24, "brick")
	block(
		name .. "_ramp",
		"Wedge",
		0,
		5.5,
		roofZ + direction * 25,
		if direction == 1 then 180 else 0,
		12,
		11,
		26,
		"snow_light"
	)
	zone(
		name .. "_top",
		0,
		roofZ,
		20,
		20,
		11,
		join(mix(midToys, 1), mix(bigToys, 1)),
		12,
		9100 + index,
		nil
	)
end

-- Ground, the landmark ring boundary and the Tier 5 landmarks.
block("sv_ground", "Block", 0, -0.5, 0, 0, 800, 1, 800, "snow")
block("sv_sidewalk", "Block", 0, 0.05, -380, 0, 800, 0.1, 24, "w-sidewalk")
block("sv_wall_n", "Block", 0, 20, -402, 0, 808, 40, 4, "stone")
block("sv_wall_s", "Block", 0, 20, 402, 0, 808, 40, 4, "stone")
block("sv_wall_e", "Block", 402, 20, 0, 0, 4, 40, 808, "stone")
block("sv_wall_w", "Block", -402, 20, 0, 0, 4, 40, 808, "stone")

local fixedPlacements: { { id: string, objectId: string, x: number, y: number, z: number, yaw: number, spawnSlot: number? } } =
	{
		{ id = "sv_landmark_01", objectId = "cottage", x = -330, y = 0, z = -330, yaw = 0 },
		{ id = "sv_landmark_02", objectId = "cottage", x = 330, y = 0, z = 330, yaw = 0 },
		{ id = "sv_landmark_03", objectId = "town_house", x = 330, y = 0, z = -330, yaw = 0 },
		{ id = "sv_landmark_04", objectId = "town_house", x = -330, y = 0, z = 330, yaw = 0 },
		{ id = "sv_landmark_05", objectId = "slot.landmark", x = 0, y = 0, z = -355, yaw = 0 },
		{ id = "sv_landmark_06", objectId = "slot.landmark", x = 0, y = 0, z = 355, yaw = 0 },
		{ id = "sv_landmark_07", objectId = "clock_tower", x = -355, y = 0, z = 0, yaw = 0 },
		{ id = "sv_landmark_08", objectId = "clock_tower", x = 355, y = 0, z = 0, yaw = 0 },
	}

-- Extra marker spots (Feature 004b) in the streets, so there are at least 6 of each kind.
for index, spot in { { -60, 0 }, { 60, 0 }, { 0, -60 }, { 0, 60 }, { -150, -180 }, { 150, 180 } } do
	table.insert(markers, {
		kind = if index % 2 == 0 then "BoosterSpot" else "TrapSpot",
		x = spot[1],
		y = 0,
		z = spot[2],
	})
end

-- 005: theme scaffolding (specs/005-theme-art-pipeline, research R-11). The spawn loop and the street
-- bands above lost 32 counts in total; the slot zones below put them back as dressing slots that
-- ThemeResolve re-maps per season. Winter equals today's look: it maps the slots to existing objects
-- and adds no hero variant. City re-maps the slots to its own stand-ins, swaps the big snowman for a
-- fountain and lays out its own overlay.

-- Dressing-slot zones: 32 placements in all (research R-11: small 12, medium 8, yard 6, street 4,
-- landmark 2). Positions are searched so that no footprint overlaps any other placement under either
-- theme (checked by tests/unit/SnowVillage.test). Spawn-relative zones are built per spawn point; the
-- baked offsets come from the scratch position search (lat gap ≥ 0.25 reach margin to every base
-- placement, clear of porch/ramp/kerb blocks and of base-zone rects, halfExtent inside).
local slotOffsets = {
	small = {
		{ -15, 9 },
		{ -15, 9 },
		{ 15, 9 },
		{ 15, 9 },
		{ -15, 9 },
		{ 15, -9 },
		{ 15, 9 },
		{ 15, -9 },
		{ -15, 9 },
		{ -15, 9 },
		{ -15, -9 },
		{ 15, 9 },
	},
	medium = {
		{ -52, 0 },
		{ 52, 0 },
		{ -53, 0 },
		{ 52, 0 },
		{ -52, 0.5 },
		{ 52, 63 },
		{ -52, -63 },
		{ 52, 0 },
	},
	yard = { { -58, -60 }, { 59.5, 36.5 }, { -60, 36 }, { 58, -60 }, { 184, -70 }, { 108, -70 } },
}
for _, spawnPoint in spawnPoints do
	local number = spawnPoint.slot
	local index = number -- spawn slots are 1..12 and match the offset indices
	-- One slot.small beside the porch, on the ground between porch and yard.
	local smallOffset = slotOffsets.small[index] :: { number }
	table.insert(zones, {
		id = string.format("sv_slot_small_%02d", number),
		x = spawnPoint.x + smallOffset[1],
		z = spawnPoint.z + smallOffset[2],
		w = 8,
		d = 4,
		y = 0,
		mix = { { objectId = "slot.small", weight = 1 } },
		count = 1,
		seed = 5100 + number,
		spawnSlot = nil,
	})
	-- One slot.medium beside the yard for the first eight spawns.
	if number <= 8 then
		local mediumOffset = slotOffsets.medium[index] :: { number }
		table.insert(zones, {
			id = string.format("sv_slot_medium_%02d", number),
			x = spawnPoint.x + mediumOffset[1],
			z = spawnPoint.z + mediumOffset[2],
			w = 8,
			d = 6,
			y = 0,
			mix = { { objectId = "slot.medium", weight = 1 } },
			count = 1,
			seed = 5200 + number,
			spawnSlot = nil,
		})
	end
	-- One slot.yard in the north lane for the first six spawns.
	if number <= 6 then
		local yardOffset = slotOffsets.yard[index] :: { number }
		table.insert(zones, {
			id = string.format("sv_slot_yard_%02d", number),
			x = spawnPoint.x + yardOffset[1],
			z = spawnPoint.z + yardOffset[2],
			w = 20,
			d = 20,
			y = 0,
			mix = { { objectId = "slot.yard", weight = 1 } },
			count = 1,
			seed = 5300 + number,
			spawnSlot = nil,
		})
	end
end
-- Four slot.street zones in the two T4 bands (2 carved out of each above).
for index, def in
	{
		{ x = -153.5, z = -215 },
		{ x = 158.5, z = -240 },
		{ x = -150, z = 272 },
		{ x = 150, z = 240 },
	}
do
	table.insert(zones, {
		id = string.format("sv_slot_street_%02d", index),
		x = def.x,
		z = def.z,
		w = 38,
		d = 20,
		y = 0,
		mix = { { objectId = "slot.street", weight = 1 } },
		count = 1,
		seed = 5400 + index,
		spawnSlot = nil,
	})
end

-- Theme-only stand-ins: no assetKey yet, sizes inside the tier range, coin in the tier range, and
-- Colour comes from the theme palette at the object's w-* role (contracts/theme-content.md §6).
local themeKitSpecs: { { tier: number, id: string, size: number, shape: string, coins: number, role: string } } =
	{
		{
			tier = 1,
			id = "ice_lolly",
			size = 0.7,
			shape = "Cylinder",
			coins = 1,
			role = "w-accent-pink",
		},
		{
			tier = 2,
			id = "beach_ball",
			size = 1.6,
			shape = "Ball",
			coins = 3,
			role = "w-accent-blue",
		},
		{
			tier = 3,
			id = "paddling_pool",
			size = 6.0,
			shape = "Cylinder",
			coins = 8,
			role = "w-water",
		},
		{
			tier = 4,
			id = "ice_cream_truck",
			size = 14.0,
			shape = "Block",
			coins = 25,
			role = "w-white",
		},
		{
			tier = 5,
			id = "giant_duck",
			size = 30.0,
			shape = "Ball",
			coins = 65,
			role = "w-accent-yellow",
		},
	}
local cityKit = {}
for _, spec in themeKitSpecs do
	table.insert(cityKit, {
		id = spec.id,
		tier = spec.tier,
		size = spec.size,
		coins = spec.coins,
		bookId = "snow_village." .. spec.id,
		nameKey = "object.snow_village." .. spec.id,
		icon = "cube",
		assetKey = nil,
		fallback = spec.shape,
		shade = nil,
		role = spec.role,
	})
end

local winterLights = {
	id = "winter_lights",
	tier = 2,
	size = 2.2,
	coins = 3,
	bookId = "snow_village.winter_lights",
	nameKey = "object.snow_village.winter_lights",
	icon = "cube",
	assetKey = nil,
	fallback = "Cylinder",
	shade = nil,
	role = "w-glow",
}
local beachTowel = {
	id = "beach_towel",
	tier = 2,
	size = 2.4,
	coins = 3,
	bookId = "snow_village.beach_towel",
	nameKey = "object.snow_village.beach_towel",
	icon = "cube",
	assetKey = nil,
	fallback = "Block",
	shade = nil,
	role = "w-accent-orange",
}

local slotsWinter = {
	["slot.small"] = "bauble",
	["slot.medium"] = "gift_box",
	["slot.yard"] = "snowman",
	["slot.street"] = "sleigh",
	["slot.landmark"] = "skating_rink",
}
local slotsCity = {
	["slot.small"] = "ice_lolly",
	["slot.medium"] = "beach_ball",
	["slot.yard"] = "paddling_pool",
	["slot.street"] = "ice_cream_truck",
	["slot.landmark"] = "giant_duck",
}

-- The two theme-only objects rest in free flanks of the town square; both clear the keepOutAreas.
local overlayZonesWinter: {
	{
		id: string,
		x: number,
		z: number,
		w: number,
		d: number,
		y: number,
		mix: { { objectId: string, weight: number } },
		count: number,
		seed: number,
		spawnSlot: number?,
	}
} =
	{
		{
			id = "sv_ol_winter_lights",
			x = 30,
			z = 74,
			w = 14,
			d = 14,
			y = 0,
			mix = { { objectId = "winter_lights", weight = 1 } },
			count = 6,
			seed = 9301,
			spawnSlot = nil,
		},
	}
local overlayZonesCity: {
	{
		id: string,
		x: number,
		z: number,
		w: number,
		d: number,
		y: number,
		mix: { { objectId: string, weight: number } },
		count: number,
		seed: number,
		spawnSlot: number?,
	}
} =
	{
		{
			id = "sv_ol_beach_towel",
			x = -30,
			z = -74,
			w = 14,
			d = 14,
			y = 0,
			mix = { { objectId = "beach_towel", weight = 1 } },
			count = 6,
			seed = 9302,
			spawnSlot = nil,
		},
	}

local heroFountain =
	{ assetKey = "fountain", nameKey = "object.snow_village.big_snowman_fountain", size = 13 }

-- 005 (T066): one fixed beach towel in the free band north of the town square, clear of every keep-out.
local cityTowelFixed =
	{ id = "sv_ol_beach_towel_fixed", objectId = "beach_towel", x = -30, y = 0, z = -100, yaw = 0 }

-- 005 (T040 step 3): both slot.landmark placements become giant_duck in city, which leaves the base
-- Tier 5 skating_rink unplaced and its tier page short of 100%. One fixed rink keeps that page
-- completable (spec: base tier pages stay completable in every season). The spot is clear of every
-- keep-out area and of every footprint (about 30 studs of margin).
local cityRinkFixed = {
	id = "sv_ol_skating_rink_fixed",
	objectId = "skating_rink",
	x = -30,
	y = 0,
	z = -280,
	yaw = 0,
}

-- Typed once so the winter and city entries share one type instead of a union (see ThemeResolve).
local themeBindings: {
	[string]: {
		slots: { [string]: string },
		overlays: {
			zones: {
				{
					id: string,
					x: number,
					z: number,
					w: number,
					d: number,
					y: number,
					mix: { { objectId: string, weight: number } },
					count: number,
					seed: number,
					spawnSlot: number?,
				}
			},
			fixedPlacements: {
				{
					id: string,
					objectId: string,
					x: number,
					y: number,
					z: number,
					yaw: number,
					spawnSlot: number?,
				}
			},
		},
		heroVariants: { [string]: { assetKey: string, nameKey: string?, size: number? } },
		objects: {
			{
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
		}?,
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
			slots = slotsWinter,
			overlays = { zones = overlayZonesWinter, fixedPlacements = {} },
			heroVariants = {},
			objects = { winterLights },
			bookPage = {
				id = "snow_village.winter",
				nameKey = "book.page.snow_village.winter.name",
				returningKey = "book.page.snow_village.winter.returning",
				reward = nil,
				objectIds = { "winter_lights" },
			},
		},
		city = {
			slots = slotsCity,
			overlays = {
				zones = overlayZonesCity,
				fixedPlacements = { cityTowelFixed, cityRinkFixed },
			},
			heroVariants = { big_snowman = heroFountain },
			objects = { cityKit[1], cityKit[2], cityKit[3], cityKit[4], cityKit[5], beachTowel },
			bookPage = {
				id = "snow_village.city",
				nameKey = "book.page.snow_village.city.name",
				returningKey = "book.page.snow_village.city.returning",
				reward = nil,
				objectIds = {
					"ice_lolly",
					"beach_ball",
					"paddling_pool",
					"ice_cream_truck",
					"giant_duck",
					"beach_towel",
				},
			},
		},
	}

-- Keep-out rectangles for the 005 overlay validation (research R-10): four 12-stud sightline
-- corridors on the axes, and one 10 x 10 rectangle around every marker spot. Gates and shortcuts
-- (T060) are added below.
local keepOutAreas: {
	{
		id: string,
		kind: "gate" | "shortcut" | "sightline" | "marker",
		x: number,
		z: number,
		w: number,
		d: number,
	}
} =
	{
		{ id = "ko_sightline_n", kind = "sightline", x = 0, z = -217.5, w = 12, d = 315 },
		{ id = "ko_sightline_s", kind = "sightline", x = 0, z = 217.5, w = 12, d = 315 },
		{ id = "ko_sightline_e", kind = "sightline", x = 212.5, z = 0, w = 325, d = 12 },
		{ id = "ko_sightline_w", kind = "sightline", x = -212.5, z = 0, w = 325, d = 12 },
	}
for _, marker in markers do
	table.insert(keepOutAreas, {
		id = `ko_marker_{#keepOutAreas + 1}`,
		kind = "marker",
		x = marker.x,
		z = marker.z,
		w = 10,
		d = 10,
	})
end

-- 005 (T060): gate and shortcut keep-outs, so nothing spawns on a route. A gate is a porch ramp, the only
-- way up onto a spawn porch: one on each side of every spawn, 18 studs out. A shortcut is a 4-stud alley
-- between two spawn clusters (docs/design/03-city-level.md: tier 1-2 balls fit, bigger ones stop). Six
-- alleys: two north-south at x = ±150, and four east-west at z = ±60, west and east of the town square.
for _, spawnPoint in spawnPoints do
	for _, side in { -18, 18 } do
		table.insert(keepOutAreas, {
			id = `ko_gate_{#keepOutAreas + 1}`,
			kind = "gate",
			x = spawnPoint.x + side,
			z = spawnPoint.z,
			w = 14,
			d = 10,
		})
	end
end
for _, alley in
	{
		{ x = -150, z = 0, w = 4, d = 356 },
		{ x = 150, z = 0, w = 4, d = 356 },
		{ x = -150, z = -60, w = 196, d = 4 },
		{ x = 150, z = -60, w = 196, d = 4 },
		{ x = -150, z = 60, w = 196, d = 4 },
		{ x = 150, z = 60, w = 196, d = 4 },
	}
do
	table.insert(keepOutAreas, {
		id = `ko_shortcut_{#keepOutAreas + 1}`,
		kind = "shortcut",
		x = alley.x,
		z = alley.z,
		w = alley.w,
		d = alley.d,
	})
end

local SnowVillage = {
	worldId = "snow_village",
	starThresholds = { 20, 45, 80 },
	-- PROVISIONAL, owner to confirm. With Config.growthK = 0.6 the pace model (tests/unit/Pace.test)
	-- needs 96 s for Tier 2 and ends a run at about 15 studs; 1.5 gives Tier 2 in 34 s and 63-71 studs.
	growthK = 1.5,
	halfExtent = 300,
	outerHalfExtent = 400,
	sizeTiers = sizeTiers,
	objects = objects,
	zones = zones,
	fixedPlacements = fixedPlacements,
	spawnPoints = spawnPoints,
	-- 005: the season system (research R-11). Changing activeThemeId is a data-only theme switch.
	activeThemeId = "winter",
	supportedThemes = { "winter", "city" },
	themeBindings = themeBindings,
	keepOutAreas = keepOutAreas,
	maxPlacements = 1700,
	environment = {
		palette = {
			snow = { 236, 242, 250 },
			snow_light = { 247, 250, 255 },
			stone = { 150, 158, 170 },
			wood = { 150, 105, 70 },
			brick = { 170, 85, 75 },
			ice = { 170, 205, 235 },
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
	lighting = {
		ambient = { 150, 165, 190 },
		outdoorAmbient = { 170, 185, 210 },
		brightness = 2,
		clockTime = 15.5,
		fogColor = { 205, 218, 235 },
		fogStart = 150,
		fogEnd = 900,
		atmosphereDensity = 0.3,
		atmosphereColor = { 200, 215, 235 },
		atmosphereDecay = { 190, 200, 220 },
	},
}

return SnowVillage
