--!strict
-- Grey-box room data. Data only: no Roblox APIs, so Lune can validate it.
-- Layout and tiers: specs/001-grey-box-prototype/data-model.md §2 and research.md R1.
-- Run-loop tiers, objects, star targets and hub: specs/002-run-loop/data-model.md §2.

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
}
export type HubDef = {
	center: { x: number, z: number },
	halfExtent: number,
	spawn: { x: number, z: number },
	padRadius: number,
}
export type Room = {
	worldId: string,
	starThresholds: { number }?,
	sizeTiers: { SizeTierDef },
	objects: { ObjectDef },
	hub: HubDef,
	halfExtent: number,
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
}

return GreyBoxRoom
