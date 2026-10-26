--!strict
-- Grey-box room data. Data only: no Roblox APIs, so Lune can validate it.
-- Layout and tiers: specs/001-grey-box-prototype/data-model.md §2 and research.md R1.
-- Run-loop tiers, objects, star targets and hub: specs/002-run-loop/data-model.md §2.
-- Feature 004 widens the shared types to the WorldDef schema (specs/004-snow-village/data-model.md §1) and
-- adds the world-agnostic fields; the room's own data above stays as it was.

export type TierDef = { tier: number, size: number, count: number, shade: number }
export type CubeSpawn = { id: string, tier: number, x: number, z: number }
export type RewardDef = { rewardId: string, rewardType: "skin" | "trail", nameKey: string }
export type SizeTierDef = {
	tier: number,
	nameKey: string,
	minDiameter: number,
	maxDiameter: number?,
	headlineKey: string,
	headlineIcon: string,
	reward: RewardDef?,
}
export type ObjectDef = {
	id: string,
	tier: number,
	size: number,
	coins: number,
	bookId: string,
	nameKey: string,
	icon: string,
	-- Key in Assets.meshes. Absent for the grey-box cubes, which are always plain parts.
	assetKey: string?,
	-- Shape of the procedural stand-in part: "Block", "Ball" or "Cylinder". Absent means "Block".
	fallback: string?,
	-- Grey level 0..255 of the stand-in. Absent means the colour comes from the tier.
	shade: number?,
}
export type HubDef = {
	center: { x: number, z: number },
	halfExtent: number,
	spawn: { x: number, z: number },
	padRadius: number,
	assetKey: string?,
}
export type MixEntry = { objectId: string, weight: number }
export type ZoneDef = {
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
export type PlacementSeed = {
	id: string,
	objectId: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	spawnSlot: number?,
}
-- y is the surface the ball rests on; the ball sits at y + startDiameter / 2 + 0.5.
export type SpawnPoint = { slot: number, x: number, y: number, z: number, yaw: number }
export type BlockDef = {
	id: string,
	kind: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
	swatch: string,
}
export type MarkerDef = { kind: string, x: number, y: number, z: number }
export type EnvironmentDef = {
	palette: { [string]: { number } },
	blocks: { BlockDef },
	markers: { MarkerDef },
}
export type LightingDef = {
	ambient: { number },
	outdoorAmbient: { number },
	brightness: number,
	clockTime: number,
	fogColor: { number },
	fogStart: number,
	fogEnd: number,
	atmosphereDensity: number,
	atmosphereColor: { number },
	atmosphereDecay: { number },
}
export type WorldDef = {
	worldId: string,
	starThresholds: { number }?,
	growthK: number?,
	sizeTiers: { SizeTierDef },
	objects: { ObjectDef },
	zones: { ZoneDef },
	fixedPlacements: { PlacementSeed },
	spawnPoints: { SpawnPoint },
	halfExtent: number,
	outerHalfExtent: number,
	environment: EnvironmentDef,
	hub: HubDef,
	lighting: LightingDef?,
}
-- The room's own fields plus every WorldDef field (spelled out: an intersection would stop the data table
-- below from being checked against its type while it is written).
export type Room = {
	worldId: string,
	starThresholds: { number }?,
	growthK: number?,
	sizeTiers: { SizeTierDef },
	objects: { ObjectDef },
	zones: { ZoneDef },
	fixedPlacements: { PlacementSeed },
	spawnPoints: { SpawnPoint },
	halfExtent: number,
	outerHalfExtent: number,
	environment: EnvironmentDef,
	hub: HubDef,
	lighting: LightingDef?,
	wallHeight: number,
	kerb: { x: number, z: number, length: number, depth: number, height: number },
	spawnRingRadius: number,
	spawnSlots: number,
	tiers: { TierDef },
	cubes: { CubeSpawn },
}

local GreyBoxRoom: Room = {
	worldId = "greybox",
	-- Provisional: a 30-cube room cannot grow a ball far past 5 studs (plan.md F-1). Retune after the playtest.
	starThresholds = { 3.0, 4.0, 5.0 },
	sizeTiers = {
		{
			tier = 1,
			nameKey = "tier.greybox.1.name",
			minDiameter = 2.0,
			maxDiameter = 2.375,
			headlineKey = "tier.greybox.1.headline",
			headlineIcon = "cube",
			reward = {
				rewardId = "greybox.reward.tier1",
				rewardType = "trail",
				nameKey = "reward.greybox.tier1.name",
			},
		},
		{
			tier = 2,
			nameKey = "tier.greybox.2.name",
			minDiameter = 2.375,
			maxDiameter = 3.0,
			headlineKey = "tier.greybox.2.headline",
			headlineIcon = "cube",
			reward = {
				rewardId = "greybox.reward.tier2",
				rewardType = "trail",
				nameKey = "reward.greybox.tier2.name",
			},
		},
		{
			tier = 3,
			nameKey = "tier.greybox.3.name",
			minDiameter = 3.0,
			maxDiameter = 3.75,
			headlineKey = "tier.greybox.3.headline",
			headlineIcon = "cube",
			reward = {
				rewardId = "greybox.reward.tier3",
				rewardType = "skin",
				nameKey = "reward.greybox.tier3.name",
			},
		},
		{
			tier = 4,
			nameKey = "tier.greybox.4.name",
			minDiameter = 3.75,
			maxDiameter = nil,
			headlineKey = "tier.greybox.4.headline",
			headlineIcon = "cube",
			reward = {
				rewardId = "greybox.reward.tier4",
				rewardType = "skin",
				nameKey = "reward.greybox.tier4.name",
			},
		},
	},
	objects = {
		{
			id = "cube_t1",
			tier = 1,
			size = 0.75,
			coins = 1,
			bookId = "greybox.cube_t1",
			nameKey = "object.greybox.cube_t1",
			icon = "cube",
		},
		{
			id = "cube_t2",
			tier = 2,
			size = 0.95,
			coins = 2,
			bookId = "greybox.cube_t2",
			nameKey = "object.greybox.cube_t2",
			icon = "cube",
		},
		{
			id = "cube_t3",
			tier = 3,
			size = 1.2,
			coins = 3,
			bookId = "greybox.cube_t3",
			nameKey = "object.greybox.cube_t3",
			icon = "cube",
		},
		{
			id = "cube_t4",
			tier = 4,
			size = 1.5,
			coins = 5,
			bookId = "greybox.cube_t4",
			nameKey = "object.greybox.cube_t4",
			icon = "cube",
		},
	},
	hub = {
		center = { x = 160, z = 0 },
		halfExtent = 16,
		spawn = { x = 0, z = 0 },
		padRadius = 4,
	},
	halfExtent = 36,
	wallHeight = 20,
	kerb = { x = -20, z = -12, length = 22, depth = 2, height = 1.0 },
	spawnRingRadius = 5,
	spawnSlots = 12,
	tiers = {
		{ tier = 1, size = 0.75, count = 12, shade = 200 },
		{ tier = 2, size = 0.95, count = 9, shade = 160 },
		{ tier = 3, size = 1.2, count = 6, shade = 120 },
		{ tier = 4, size = 1.5, count = 3, shade = 80 },
	},
	cubes = {
		{ id = "T1-01", tier = 1, x = 11, z = 0 },
		{ id = "T1-02", tier = 1, x = 0, z = 12 },
		{ id = "T1-03", tier = 1, x = -11, z = 0 },
		{ id = "T1-04", tier = 1, x = 3, z = -13 },
		{ id = "T1-05", tier = 1, x = 15, z = 9 },
		{ id = "T1-06", tier = 1, x = -9, z = 15 },
		{ id = "T1-07", tier = 1, x = -15, z = -7 },
		{ id = "T1-08", tier = 1, x = 9, z = -18 },
		{ id = "T1-09", tier = 1, x = 19, z = -4 },
		{ id = "T1-10", tier = 1, x = -3, z = 20 },
		{ id = "T1-11", tier = 1, x = -16, z = -19 },
		{ id = "T1-12", tier = 1, x = -24, z = -18 },
		{ id = "T2-01", tier = 2, x = 24, z = 8 },
		{ id = "T2-02", tier = 2, x = 21, z = -14 },
		{ id = "T2-03", tier = 2, x = 8, z = 27 },
		{ id = "T2-04", tier = 2, x = -14, z = 26 },
		{ id = "T2-05", tier = 2, x = -27, z = 10 },
		{ id = "T2-06", tier = 2, x = -25, z = -4 },
		{ id = "T2-07", tier = 2, x = 13, z = -26 },
		{ id = "T2-08", tier = 2, x = 28, z = -3 },
		{ id = "T2-09", tier = 2, x = -5, z = -26 },
		{ id = "T3-01", tier = 3, x = 30, z = 20 },
		{ id = "T3-02", tier = 3, x = -30, z = 22 },
		{ id = "T3-03", tier = 3, x = -30, z = -26 },
		{ id = "T3-04", tier = 3, x = 28, z = -24 },
		{ id = "T3-05", tier = 3, x = 0, z = 31 },
		{ id = "T3-06", tier = 3, x = -8, z = -31 },
		{ id = "T4-01", tier = 4, x = 32, z = 31 },
		{ id = "T4-02", tier = 4, x = -32, z = 31 },
		{ id = "T4-03", tier = 4, x = 31, z = -31 },
	},
	-- World-agnostic fields, filled below from the data above.
	zones = {},
	fixedPlacements = {},
	spawnPoints = {},
	outerHalfExtent = 36,
	environment = { palette = {}, blocks = {}, markers = {} },
}

-- The 30 cubes become placements: tier t uses the object "cube_t<t>", resting on the floor (y = 0).
for _, cube in GreyBoxRoom.cubes do
	table.insert(GreyBoxRoom.fixedPlacements, {
		id = cube.id,
		objectId = "cube_t" .. cube.tier,
		x = cube.x,
		y = 0,
		z = cube.z,
		yaw = 0,
	})
end
for _, object in GreyBoxRoom.objects do
	for _, def in GreyBoxRoom.tiers do
		if def.tier == object.tier then
			object.shade = def.shade
		end
	end
	object.fallback = "Block"
end

-- The spawn ring becomes 12 spawn points on the floor.
for slot = 0, GreyBoxRoom.spawnSlots - 1 do
	local angle = (slot / GreyBoxRoom.spawnSlots) * math.pi * 2
	table.insert(GreyBoxRoom.spawnPoints, {
		slot = slot + 1,
		x = math.cos(angle) * GreyBoxRoom.spawnRingRadius,
		y = 0,
		z = math.sin(angle) * GreyBoxRoom.spawnRingRadius,
		yaw = 0,
	})
end

-- Floor, four walls and the kerb as environment blocks.
local environment = GreyBoxRoom.environment
environment.palette = {
	floor = { 90, 90, 90 },
	wall = { 70, 70, 70 },
	hub_floor = { 110, 110, 110 },
	hub_pad = { 150, 150, 150 },
}
local half = GreyBoxRoom.halfExtent
local wall = GreyBoxRoom.wallHeight
local span = half * 2 + 4
local function addBlock(
	id: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	swatch: string
)
	table.insert(environment.blocks, {
		id = id,
		kind = "Block",
		cframe = { x = x, y = y, z = z, yaw = 0 },
		size = { x = sx, y = sy, z = sz },
		swatch = swatch,
	})
end
addBlock("floor", 0, -0.5, 0, half * 2, 1, half * 2, "floor")
addBlock("wall_1", 0, wall / 2, -half - 1, span, wall, 2, "wall")
addBlock("wall_2", 0, wall / 2, half + 1, span, wall, 2, "wall")
addBlock("wall_3", half + 1, wall / 2, 0, 2, wall, span, "wall")
addBlock("wall_4", -half - 1, wall / 2, 0, 2, wall, span, "wall")
addBlock(
	"kerb",
	GreyBoxRoom.kerb.x,
	GreyBoxRoom.kerb.height / 2,
	GreyBoxRoom.kerb.z,
	GreyBoxRoom.kerb.length,
	GreyBoxRoom.kerb.height,
	GreyBoxRoom.kerb.depth,
	"wall"
)

return GreyBoxRoom
