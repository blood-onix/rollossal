--!strict
-- Growth pace model (specs/004-snow-village/research.md R1, plan finding F-1).
-- A deterministic greedy eater rolls through the expanded Snow Village layout from each spawn point and the
-- test asserts how fast it grows. No clock, no randomness. The pickup rate and the speed formula are the
-- model's assumptions, written as constants here, not read from the world.

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")
local Layout = require("../../src/shared/Rules/Layout")
local Growth = require("../../src/shared/Rules/Growth")
local Absorb = require("../../src/shared/Rules/Absorb")

local test, expect = harness.test, harness.expect

local RUN_SECONDS = 240
local TIER_2_DIAMETER = 5
local TIER_2_DEADLINE = 60
-- Pickups per second the thumb stick can sustain: a reflex ceiling, lower once travel dominates.
local SMALL_PICKUP_RATE = 1.5
local LARGE_PICKUP_RATE = 1.0
local LARGE_FROM_DIAMETER = TIER_2_DIAMETER

local growthK: number = (SnowVillage :: { growthK: number? }).growthK or Config.growthK

local sizes: { [string]: number } = {}
local tiers: { [string]: number } = {}
for _, object in SnowVillage.objects do
	sizes[object.id] = object.size
	tiers[object.id] = object.tier
end

local placements = Layout.expand(SnowVillage.zones, sizes)
for _, fixed in SnowVillage.fixedPlacements do
	table.insert(placements, fixed)
end

local function speedFor(diameter: number): number
	return math.min(Config.speedCap, Config.baseSpeed * math.sqrt(diameter / Config.startDiameter))
end

export type Report = {
	tier2At: number?,
	diameterAt: { [number]: number },
	final: number,
	pickups: number,
}

-- The eater starts at a spawn point. At each step it goes for the eatable object with the most volume per
-- second of travel, spends the larger of the travel time and the pickup interval, and grows.
local function simulate(startX: number, startZ: number, k: number): Report
	local eaten: { [number]: boolean } = {}
	local x, z = startX, startZ
	local diameter = Config.startDiameter
	local clock = 0
	local pickups = 0
	local tier2At: number? = nil
	local diameterAt: { [number]: number } = {}

	while clock < RUN_SECONDS do
		local bestIndex = 0
		local bestScore = -1
		local bestTravel = 0
		local speed = speedFor(diameter)
		for index, placement in placements do
			local size = sizes[placement.objectId]
			if not eaten[index] and Absorb.canAbsorb(diameter, size, Config.absorbRatio) then
				local travel = math.sqrt((placement.x - x) ^ 2 + (placement.z - z) ^ 2) / speed
				local interval = if diameter >= LARGE_FROM_DIAMETER
					then 1 / LARGE_PICKUP_RATE
					else 1 / SMALL_PICKUP_RATE
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
		local interval = if diameter >= LARGE_FROM_DIAMETER
			then 1 / LARGE_PICKUP_RATE
			else 1 / SMALL_PICKUP_RATE
		clock += math.max(bestTravel, interval)
		if clock > RUN_SECONDS then
			break
		end
		eaten[bestIndex] = true
		x, z = placement.x, placement.z
		pickups += 1
		diameter = Growth.growDiameter(diameter, sizes[placement.objectId], k)
		if tier2At == nil and diameter >= TIER_2_DIAMETER then
			tier2At = clock
		end
		for _, mark in { 20, 30 } do
			if diameterAt[mark] == nil and diameter >= mark then
				diameterAt[mark] = clock
			end
		end
	end
	return { tier2At = tier2At, diameterAt = diameterAt, final = diameter, pickups = pickups }
end

local reports: { Report } = {}
for _, spawn in SnowVillage.spawnPoints do
	reports[spawn.slot] = simulate(spawn.x, spawn.z, growthK)
end

test("Pace: the model sees the 12 spawn slots", function()
	expect.equal(#reports, 12)
end)

test("Pace: every spawn slot reaches Tier 2 within 60 seconds", function()
	for slot, report in reports do
		local at = report.tier2At
		expect.truthy(at ~= nil)
		expect.truthy((at :: number) <= TIER_2_DEADLINE)
		if at == nil then
			print(`slot {slot}: no Tier 2`)
		end
	end
end)

test("Pace: every spawn slot reaches 20 studs and 30 studs by 240 seconds", function()
	for slot, report in reports do
		if report.final < 30 then
			print(`slot {slot}: final {report.final}, pickups {report.pickups}`)
		end
		expect.truthy(report.diameterAt[20] ~= nil)
		expect.truthy(report.diameterAt[30] ~= nil)
	end
end)

return { simulate = simulate, spawns = SnowVillage.spawnPoints, placements = placements }
