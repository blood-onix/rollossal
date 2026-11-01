--!strict
-- Growth pace model (specs/004-snow-village/research.md R1, plan finding F-1; 007 research R-08).
-- A deterministic greedy eater rolls through a world's expanded layout from each spawn point and the test
-- asserts how fast it grows. No clock, no randomness. The pickup rate and the speed formula are the model's
-- assumptions, written as constants here, not read from the world. The world and theme are parameters: Snow
-- Village keeps its 004 targets, Downtown (winter and city) has the 007 targets.

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")
local Downtown = require("../../src/shared/Content/Worlds/Downtown")
local Themes = require("../../src/shared/Content/Themes")
local Layout = require("../../src/shared/Rules/Layout")
local Growth = require("../../src/shared/Rules/Growth")
local Absorb = require("../../src/shared/Rules/Absorb")
local ThemeResolve = require("../../src/shared/Rules/ThemeResolve")

local test, expect = harness.test, harness.expect

local RUN_SECONDS = 240
local TIER_2_DIAMETER = 5
-- Pickups per second the thumb stick can sustain: a reflex ceiling, lower once travel dominates.
local SMALL_PICKUP_RATE = 1.5
local LARGE_PICKUP_RATE = 1.0
local LARGE_FROM_DIAMETER = TIER_2_DIAMETER
local MARKS = { 5, 12, 20, 30, 80 }

local function speedFor(diameter: number): number
	return math.min(Config.speedCap, Config.baseSpeed * math.sqrt(diameter / Config.startDiameter))
end

export type Report = {
	firstAt: number?,
	-- Seconds at which the ball first reached each diameter in MARKS.
	diameterAt: { [number]: number },
	tier2At: number?,
	final: number,
	pickups: number,
}

type Placement = Layout.Placement
type SpawnPoint = { slot: number, x: number, y: number, z: number, yaw: number }

export type Model = {
	placements: { Placement },
	sizes: { [string]: number },
	spawns: { SpawnPoint },
	growthK: number,
}

-- The expanded layout of one world under one theme, with the sizes of every object that theme places.
local function modelFor(world: any, themeId: string): Model
	local theme = (Themes :: any)[themeId]
	local resolved =
		ThemeResolve.resolve(world, theme, Layout.expand, Config.Budgets.defaultMaxPlacements)
	local sizes: { [string]: number } = {}
	for _, object in resolved.objects do
		sizes[object.id] = object.size
	end
	return {
		placements = resolved.placements,
		sizes = sizes,
		spawns = world.spawnPoints,
		growthK = world.growthK or Config.growthK,
	}
end

-- The eater starts at a spawn point. At each step it goes for the eatable object with the most volume per
-- second of travel, spends the larger of the travel time and the pickup interval, and grows.
local function simulate(model: Model, startX: number, startZ: number, k: number): Report
	local placements, sizes = model.placements, model.sizes
	local eaten: { [number]: boolean } = {}
	local x, z = startX, startZ
	local diameter = Config.startDiameter
	local clock = 0
	local pickups = 0
	local firstAt: number? = nil
	local tier2At: number? = nil
	local diameterAt: { [number]: number } = {}

	while clock < RUN_SECONDS do
		local bestIndex = 0
		local bestScore = -1
		local bestTravel = 0
		local speed = speedFor(diameter)
		local interval = if diameter >= LARGE_FROM_DIAMETER
			then 1 / LARGE_PICKUP_RATE
			else 1 / SMALL_PICKUP_RATE
		for index, placement in placements do
			local size = sizes[placement.objectId]
			if not eaten[index] and Absorb.canAbsorb(diameter, size, Config.absorbRatio) then
				local travel = math.sqrt((placement.x - x) ^ 2 + (placement.z - z) ^ 2) / speed
				local score = size ^ 3 / math.max(travel, interval)
				if score > bestScore then
					bestScore = score
					bestIndex = index
					bestTravel = travel
				end
			end
		end
		if bestIndex == 0 then
			break
		end
		local placement = placements[bestIndex]
		clock += math.max(bestTravel, interval)
		if clock > RUN_SECONDS then
			break
		end
		eaten[bestIndex] = true
		x, z = placement.x, placement.z
		pickups += 1
		if firstAt == nil then
			firstAt = clock
		end
		diameter = Growth.growDiameter(diameter, sizes[placement.objectId], k)
		if tier2At == nil and diameter >= TIER_2_DIAMETER then
			tier2At = clock
		end
		for _, mark in MARKS do
			if diameterAt[mark] == nil and diameter >= mark then
				diameterAt[mark] = clock
			end
		end
	end
	return {
		firstAt = firstAt,
		diameterAt = diameterAt,
		tier2At = tier2At,
		final = diameter,
		pickups = pickups,
	}
end

local function reportsFor(world: any, themeId: string): { Report }
	local model = modelFor(world, themeId)
	local reports: { Report } = {}
	for _, spawn in model.spawns do
		reports[spawn.slot] = simulate(model, spawn.x, spawn.z, model.growthK)
	end
	return reports
end

-- Snow Village (004): winter is the base look.
local snowReports = reportsFor(SnowVillage, "winter")

test("Pace: the model sees the 12 Snow Village spawn slots", function()
	expect.equal(#snowReports, 12)
end)

test("Pace: every Snow Village spawn slot reaches Tier 2 within 60 seconds", function()
	for slot, report in snowReports do
		local at = report.tier2At
		expect.truthy(at ~= nil)
		expect.truthy((at :: number) <= 60)
		if at == nil then
			print(`slot {slot}: no Tier 2`)
		end
	end
end)

test("Pace: every Snow Village spawn slot reaches 20 studs and 30 studs by 240 seconds", function()
	for slot, report in snowReports do
		if report.final < 30 then
			print(`slot {slot}: final {report.final}, pickups {report.pickups}`)
		end
		expect.truthy(report.diameterAt[20] ~= nil)
		expect.truthy(report.diameterAt[30] ~= nil)
	end
end)

-- Downtown (007, contracts/world-content.md "Pace contract"): first pickup <= 5 s; D 5 at 30 +- 20 s;
-- D 12 at 90 +- 20 s; D 30 at 165 +- 20 s; D 80 by 240 s. All 12 spawns, both themes.
for _, themeId in { "winter", "city" } do
	local reports = reportsFor(Downtown, themeId)

	test(`Pace: Downtown {themeId} sees the 12 spawn slots`, function()
		expect.equal(#reports, 12)
	end)

	test(`Pace: Downtown {themeId} hits the pace windows from every spawn`, function()
		local windows = { [5] = { 10, 50 }, [12] = { 70, 110 }, [30] = { 145, 185 } }
		for slot, report in reports do
			local label = `{themeId} slot {slot}`
			expect.truthy(
				report.firstAt ~= nil and (report.firstAt :: number) <= 5,
				`{label} first pickup`
			)
			for mark, window in windows do
				local at = report.diameterAt[mark]
				expect.truthy(at ~= nil, `{label}: never reaches D {mark} (final {report.final})`)
				if at ~= nil then
					expect.truthy(
						at >= window[1] and at <= window[2],
						`{label}: D {mark} at {at}, wanted {window[1]} to {window[2]}`
					)
				end
			end
			local top = report.diameterAt[80]
			expect.truthy(
				top ~= nil and top <= RUN_SECONDS,
				`{label}: D 80 by 240 s (final {report.final})`
			)
		end
	end)
end

return {
	simulate = simulate,
	modelFor = modelFor,
	reportsFor = reportsFor,
	MARKS = MARKS,
}
