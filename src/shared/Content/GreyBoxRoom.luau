--!strict
-- Grey-box room data. Data only: no Roblox APIs, so Lune can validate it.
-- Layout and tiers: specs/001-grey-box-prototype/data-model.md §2 and research.md.
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
	-- Palette cell name (a w-* role): the stand-in part takes its Color from theme.palette[role]
	-- (005). Absent means the tier colour.
	role: string?,
	-- Park City (012). Absent: a cube of `size`. dims = {l, w, h}; size stays the longest side.
	dims: { number }?,
	-- Cube root of l * w * h. Absent: equal to `size`.
	bulk: number?,
	-- Stays collidable until the ball can eat it (hedge and hoarding pieces).
	solid: boolean?,
	-- Tier 1-2 object kept as server data, drawn by the client (not a server Part).
	light: boolean?,
	-- City asset kit (013). "fronts" draws the mesh with the fronts and signs atlas instead of the theme atlas.
	atlas: string?,
	-- Contact-sheet and catalogue grouping: building, street, park, suburbs, mainstreet, downtown, signage, meme.
	zone: string?,
}
-- Per-world size and readability rules (012 research R3). Every field falls back to Config.
export type AbsorbRuleDef = { mode: string, ratio: number, longestRatio: number?, garnish: number? }
export type SpeedCapDef = { base: number, fromDiameter: number, slope: number, max: number }
export type RulesDef = {
	startDiameter: number?,
	growthK: number?,
	absorb: AbsorbRuleDef?,
	speedCap: SpeedCapDef?,
	cameraMinDistance: number?,
}
-- Downtown's table for Flags.ReadableRules (Stage A of 012).
export type ReadableRulesDef = {
	sizeTiers: { SizeTierDef },
	starThresholds: { number },
	doorstepClearRadius: number,
	rules: RulesDef,
	dims: { [string]: { number } },
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
-- kind: "Block" (default), "Wedge", "Cylinder", "Spiral" or "Boundary" (an invisible collider: no palette lookup, never drawn).
export type BlockDef = {
	id: string,
	kind: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
	swatch: string,
	-- kind "Spiral" (012): a ramp winding up inside the block's footprint, rising over size.y. Absent otherwise.
	turns: number?,
	width: number?,
}
export type MarkerDef = {
	id: string,
	kind: string,
	subKind: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	waypoints: { { x: number, z: number } }?,
}
-- Map-edge scenery (014 R-10): anchored, never collided with, queried or eaten. A mesh scaled so its longest side
-- is the longest side of `size`, or a stand-in block of `size` coloured by the palette at `role`.
export type SceneryDef = {
	id: string,
	assetKey: string?,
	role: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
}
export type EnvironmentDef = {
	palette: { [string]: { number } },
	blocks: { BlockDef },
	markers: { MarkerDef },
	scenery: { SceneryDef }?,
}
-- Colour grading (one ColorCorrectionEffect in Lighting). tint is RGB 0..255.
export type GradingDef = {
	brightness: number,
	contrast: number,
	saturation: number,
	tint: { number },
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
	-- Optional (013 tween-appeal rework, style bible section 8): applied by WorldBuilder.applyLighting when set.
	shadowSoftness: number?,
	geographicLatitude: number?,
	grading: GradingDef?,
}

-- Theme additions (005, specs/005-theme-art-pipeline/data-model.md §3).

-- A hero variant copies one base object: only the mesh (assetKey), shown name and — for art only — the
-- declared size change. Gameplay always keeps the base size, tier, coins and bookId.
export type HeroVariantDef = { assetKey: string, nameKey: string?, size: number? }

-- A book page for one theme the world supports. The page lists the binding's theme-only objects in
-- `objects` order; progress reuses the existing profile.book map (no schema change).
export type ThemeBookPage = {
	id: string,
	nameKey: string,
	returningKey: string,
	-- RewardDef for 006a; unused and never granted in 005.
	reward: RewardDef?,
	objectIds: { string },
}

-- The per-world binding of one theme: where that theme's objects stand (slots), which extra objects it
-- adds (overlays, theme-only objects), which base objects change (heroVariants) and its book page.
export type ThemeBinding = {
	-- slot id ("slot.small" … "slot.landmark") -> object id; every slot id the world's zones and fixed
	-- placements use must be mapped here, and the object's tier must equal the slot's tier.
	slots: { [string]: string },
	overlays: { zones: { ZoneDef }, fixedPlacements: { PlacementSeed } },
	heroVariants: { [string]: HeroVariantDef },
	-- Theme-only ObjectDefs (slot and overlay objects not in the base kit); optional when every mapped
	-- object is a base kit object.
	objects: { ObjectDef }?,
	-- Scenery blocks only this theme builds, on top of environment.blocks.
	blocks: { BlockDef }?,
	bookPage: ThemeBookPage?,
}

-- Axis-aligned keep-out rectangle: centre x, z with full extents w, d. Overlays may not overlap one.
export type KeepOutDef = {
	id: string,
	kind: "gate" | "shortcut" | "sightline" | "marker",
	x: number,
	z: number,
	w: number,
	d: number,
}

-- Client-only decoration (007, R-14): ambient pigeons stand on the ground or on static geometry.
export type PigeonSpot = { district: string, x: number, z: number }
-- Ambient traffic (client-only, never collides and never hurts): cars, vans and buses that drive a closed loop over
-- the streets. `phase` is where the car starts, as a fraction of the loop; `speed` is studs per second.
export type TrafficCar = { kind: "car" | "van" | "bus", phase: number, colour: { number } }
export type TrafficLane = {
	id: string,
	speed: number,
	waypoints: { { x: number, z: number } },
	cars: { TrafficCar },
}
export type AmbientDef = { pigeons: { PigeonSpot }?, traffic: { TrafficLane }? }

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
	-- Theme additions. activeThemeId nil (or absent) keeps the pre-005 behaviour: no slots, no overlays,
	-- no theme palette or lighting.
	activeThemeId: string?,
	supportedThemes: { string }?,
	themeBindings: { [string]: ThemeBinding }?,
	keepOutAreas: { KeepOutDef }?,
	maxPlacements: number?,
	ambient: AmbientDef?,
	-- Park City (012): size rules, readable-rules table (Downtown), inert placeholders, fixed shots, golden spots.
	rules: RulesDef?,
	readableRules: ReadableRulesDef?,
	placeholders: { any }?,
	shots: { any }?,
	golden: { any }?,
	hazards: { any }?,
	-- Park City (014): generated rows that Worlds turns into theme slots (placement id -> slot id), and the slot
	-- placements it adds to the fixed placements (the memes).
	slotRows: { [string]: string }?,
	slotPlacements: { PlacementSeed }?,
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
	activeThemeId: string?,
	supportedThemes: { string }?,
	themeBindings: { [string]: ThemeBinding }?,
	keepOutAreas: { KeepOutDef }?,
	maxPlacements: number?,
	ambient: AmbientDef?,
	-- Park City (012): size rules, readable-rules table (Downtown), inert placeholders, fixed shots, golden spots.
	rules: RulesDef?,
	readableRules: ReadableRulesDef?,
	placeholders: { any }?,
	shots: { any }?,
	golden: { any }?,
	hazards: { any }?,
}

local GreyBoxRoom: Room = {
	worldId = "greybox",
	-- Provisional: a 30-cube room cannot grow a ball far past 5 studs. Retune after the playtest.
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
