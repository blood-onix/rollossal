--!strict
-- Grey-box room data. Data only: no Roblox APIs, so Lune can validate it.
-- Layout and tiers: specs/001-grey-box-prototype/data-model.md §2 and research.md R1.

export type TierDef = { tier: number, size: number, count: number, shade: number }
export type CubeSpawn = { id: string, tier: number, x: number, z: number }
export type Room = {
	halfExtent: number,
	wallHeight: number,
	kerb: { x: number, z: number, length: number, depth: number, height: number },
	spawnRingRadius: number,
	spawnSlots: number,
	tiers: { TierDef },
	cubes: { CubeSpawn },
}

local GreyBoxRoom: Room = {
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
