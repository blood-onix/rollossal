--!strict
-- Park City growth pace: a REPORT, never a gate (spec FR-022, US4). It writes specs/012-park-city-map/pace-report.md
-- and fails only on the three playability floors (constitution 4.1.0): the first pickup within 3 s of every spawn,
-- no gap in the open-route food ladder, and (checked by scripts/park_city_layout.py) the park coverage rule.
--
-- Model (deterministic, no clock, no randomness): a greedy eater starts at a spawn at D 1, repeatedly takes the
-- reachable edible object with the most volume per stud of travel, and spends travel time at the roll speed plus a
-- per-pickup handling time. It ignores rails, pads, catapults and walls (it rolls in straight lines), so it is a
-- floor on what a person can do on the open ground, not a prediction.
-- Profiles map scripts/growth-sim.py's three profiles. Its route efficiency (0.6 / 0.9 / 1.2) scales the travel
-- speed and its bump loss (3.5 / 2 / 1 % of volume per minute) is applied as is. Its seconds per pickup (1.6 / 1.15 /
-- 0.9) become pickup rates for crumbs in dense places, 1 / 1.5 / 2 a second (Pace.test uses 1.5), so the handling time
-- per pickup is the inverse. growthK 1.6 and garnish 0.08 are the world's own rules.

local fs = require("@lune/fs")

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local ParkCity = require("../../src/shared/Content/Worlds/ParkCity")
local Parts = require("../../src/shared/Content/Worlds/ParkCityParts")
local LightData = require("../../src/shared/Content/Worlds/ParkCityLight")
local Absorb = require("../../src/shared/Rules/Absorb")
local Growth = require("../../src/shared/Rules/Growth")
local Light = require("../../src/shared/Rules/Light")
local Movement = require("../../src/shared/Rules/Movement")
local Tiers = require("../../src/shared/Rules/Tiers")

local test, expect = harness.test, harness.expect

local RULES = ParkCity.rules
local RUN_SECONDS = 240
local STEP_SECONDS = 30
local BASE_SPEED = 18
local REFERENCE_DIAMETER = 2

local objectById: { [string]: any } = {}
for _, object in ParkCity.objects do
	objectById[object.id] = object
end

-- One flat list of every object (light rows first, then the Parts), in the Light grid's row format.
local kinds: { string } = {}
local kindIndex: { [string]: number } = {}
local function kindOf(kind: string): number
	local index = kindIndex[kind]
	if index == nil then
		table.insert(kinds, kind)
		index = #kinds
		kindIndex[kind] = index
	end
	return index
end
local data: { number } = {}
local count = 0
local function push(kind: string, x: number, y: number, z: number)
	table.insert(data, kindOf(kind))
	table.insert(data, x)
	table.insert(data, y)
	table.insert(data, z)
	table.insert(data, 0)
	count += 1
end
for index = 1, LightData.count do
	local at = (index - 1) * LightData.stride
	push(
		LightData.kinds[LightData.data[at + 1]],
		LightData.data[at + 2],
		LightData.data[at + 3],
		LightData.data[at + 4]
	)
end
for _, row in Parts do
	push(row.objectId, row.x, row.y, row.z)
end
local grid = Light.buildGrid(data, 5, count, 64)

local function defAt(index: number): any
	return objectById[kinds[data[(index - 1) * 5 + 1]]]
end

local rule = RULES.absorb :: Absorb.Rule

type Profile = { name: string, handling: number, efficiency: number, bumpLoss: number }
local PROFILES: { Profile } = {
	{ name = "weak", handling = 1.0, efficiency = 0.6, bumpLoss = 0.035 },
	{ name = "median", handling = 0.67, efficiency = 0.9, bumpLoss = 0.02 },
	{ name = "skilled", handling = 0.5, efficiency = 1.2, bumpLoss = 0.01 },
}

type Run = { sizeAt: { number }, tierAt: { [number]: number }, final: number, firstPickup: number? }

local function simulate(spawn: { x: number, z: number }, profile: Profile): Run
	local taken: { [number]: boolean } = {}
	local x, z, diameter, time = spawn.x, spawn.z, RULES.startDiameter, 0
	local run: Run = { sizeAt = {}, tierAt = {}, final = diameter, firstPickup = nil }
	local nextMark = STEP_SECONDS
	local tier = 1
	local function mark(now: number)
		while nextMark <= now and nextMark <= RUN_SECONDS do
			table.insert(run.sizeAt, diameter)
			nextMark += STEP_SECONDS
		end
	end
	local stalled = 0
	while time < RUN_SECONDS and stalled < 3 do
		local best, bestScore, bestDistance = nil, -1, 0
		-- Look near first; when nothing near is worth eating, widen the search (a person rolls to the next place).
		for widen = 0, 4 do
			local radius = math.min(500, (45 + 6 * diameter) * 2 ^ widen)
			for _, index in Light.query(grid, data, 5, x, z, radius) do
				if not taken[index] then
					local def = defAt(index)
					if
						Absorb.canEat(rule, diameter, def.bulk, def.size)
						and def.bulk >= RULES.absorb.garnish * diameter
					then
						local at = (index - 1) * 5
						local distance = math.sqrt((data[at + 2] - x) ^ 2 + (data[at + 4] - z) ^ 2)
						local score = def.bulk ^ 3 / math.max(distance, 3)
						if score > bestScore then
							best, bestScore, bestDistance = index, score, distance
						end
					end
				end
			end
			if best ~= nil then
				break
			end
		end
		if best == nil then
			stalled += 1
			time += 5
			mark(time)
			continue
		end
		stalled = 0
		local speed = Movement.targetSpeed(
			diameter,
			BASE_SPEED,
			REFERENCE_DIAMETER,
			Config.speedExponent,
			Movement.speedCap(diameter, RULES.speedCap)
		) * profile.efficiency
		time += bestDistance / speed + profile.handling
		mark(time)
		if time > RUN_SECONDS then
			break
		end
		taken[best] = true
		local def = defAt(best)
		local at = (best - 1) * 5
		x, z = data[at + 2], data[at + 4]
		diameter = Growth.growByBulk(diameter, def.bulk, RULES.growthK, RULES.absorb.garnish)
		-- Bumps cost a share of the volume per minute, spread over the pickups as they happen.
		diameter *= (1 - profile.bumpLoss * (bestDistance / speed + profile.handling) / 60) ^ (1 / 3)
		diameter = math.max(diameter, RULES.startDiameter)
		if run.firstPickup == nil then
			run.firstPickup = time
		end
		local reached = Tiers.lookup(diameter, ParkCity.sizeTiers)
		while tier < reached do
			tier += 1
			run.tierAt[tier] = time
		end
	end
	mark(RUN_SECONDS)
	run.final = diameter
	return run
end

local function fmt(value: number): string
	return string.format("%.1f", value)
end

test(
	"ParkPace: report for 12 spawns and 3 profiles (never a gate), written to the spec folder",
	function()
		local lines: { string } = {
			"# Park City pace report",
			"",
			"Written by `tests/unit/ParkPace.test.luau`. A report, not a gate (spec FR-022): the test passes whatever these",
			"numbers are. The model is a greedy eater on open ground with no rails, pads or walls; see the test header.",
			"Sizes are ball diameters D; times are seconds into the run. Spawns more than 15 % behind the median spawn's",
			"final size are marked with `*`.",
			"",
		}
		local ticks = RUN_SECONDS // STEP_SECONDS
		for _, profile in PROFILES do
			local runs: { Run } = {}
			local finals: { number } = {}
			for _, spawn in ParkCity.spawnPoints do
				local run = simulate(spawn, profile)
				table.insert(runs, run)
				table.insert(finals, run.final)
			end
			local sorted = table.clone(finals)
			table.sort(sorted)
			local median = (sorted[6] + sorted[7]) / 2
			table.insert(lines, `## Profile: {profile.name}`)
			table.insert(lines, "")
			local head = "| Spawn |"
			local rule_ = "| --- |"
			for tick = 1, ticks do
				head ..= ` {tick * STEP_SECONDS} s |`
				rule_ ..= " --- |"
			end
			head ..= " Tier 2 | Tier 3 | Tier 4 | Tier 5 | Tier 6 |"
			rule_ ..= " --- | --- | --- | --- | --- |"
			table.insert(lines, head)
			table.insert(lines, rule_)
			for index, run in runs do
				local behind = if run.final < median * 0.85 then "*" else ""
				local row = `| {index}{behind} |`
				for tick = 1, ticks do
					row ..= ` {fmt(run.sizeAt[tick] or run.final)} |`
				end
				for tier = 2, 6 do
					local at = run.tierAt[tier]
					row ..= ` {if at then fmt(at) .. " s" else "-"} |`
				end
				table.insert(lines, row)
			end
			table.insert(lines, "")
			table.insert(lines, `Median final size: {fmt(median)}.`)
			table.insert(lines, "")
		end
		fs.writeFile("specs/012-park-city-map/pace-report.md", table.concat(lines, "\n") .. "\n")
		expect.truthy(#lines > 20)
	end
)

test("ParkPace floor G4: every spawn reaches an edible crumb within 3 s at D 1", function()
	local speed = Movement.targetSpeed(
		RULES.startDiameter,
		BASE_SPEED,
		REFERENCE_DIAMETER,
		Config.speedExponent,
		Movement.speedCap(RULES.startDiameter, RULES.speedCap)
	)
	for slot, spawn in ParkCity.spawnPoints do
		local nearest = math.huge
		for _, index in Light.query(grid, data, 5, spawn.x, spawn.z, 60) do
			local def = defAt(index)
			if Absorb.canEat(rule, RULES.startDiameter, def.bulk, def.size) then
				local at = (index - 1) * 5
				nearest = math.min(
					nearest,
					math.sqrt((data[at + 2] - spawn.x) ^ 2 + (data[at + 4] - spawn.z) ^ 2)
				)
			end
		end
		expect.truthy(nearest / speed <= 3, `spawn {slot}: {nearest} studs`)
	end
end)

test(
	"ParkPace floor: every spawn has its 20 doorstep light objects within 15 studs, all edible at D 1",
	function()
		for slot, spawn in ParkCity.spawnPoints do
			local range = LightData.ranges[string.format("doorstep_%02d", slot)]
			expect.truthy(range, `doorstep {slot}`)
			expect.equal(range[2] - range[1] + 1, 20, `spawn {slot} doorstep count`)
			for index = range[1], range[2] do
				local at = (index - 1) * LightData.stride
				local def = objectById[LightData.kinds[LightData.data[at + 1]]]
				local distance = math.sqrt(
					(LightData.data[at + 2] - spawn.x) ^ 2 + (LightData.data[at + 4] - spawn.z) ^ 2
				)
				expect.truthy(distance <= 15, `spawn {slot} row {index}: {distance} studs`)
				expect.truthy(
					def.bulk <= 0.5 and def.size <= 1.5,
					`spawn {slot} row {index}: {def.id}`
				)
			end
		end
	end
)

test(
	"ParkPace floor G5: the open-route food ladder has no gap from D 1 to the size that eats the hoardings",
	function()
		local hoarding = objectById.hoarding
		local ceiling = Absorb.needsDiameter(rule, hoarding.bulk, hoarding.size)
		local needs: { number } = {}
		local seen: { [string]: boolean } = {}
		for _, object in ParkCity.objects do
			local value = Absorb.needsDiameter(rule, object.bulk, object.size)
			local key = string.format("%.2f", value)
			if value <= ceiling and not seen[key] then
				seen[key] = true
				table.insert(needs, value)
			end
		end
		table.sort(needs)
		-- The first food is edible at the start size; every next step is at most 25 % above the one before (or above
		-- the start size, for the sub-start crumbs).
		expect.truthy(needs[1] <= RULES.startDiameter * 1.25)
		for index = 2, #needs do
			local previous = math.max(needs[index - 1], RULES.startDiameter)
			expect.truthy(
				needs[index] <= 1.25 * previous + 1e-9,
				`gap before D {needs[index]} (after {previous})`
			)
		end
		expect.truthy(ceiling > 16 and ceiling < 17)
	end
)

return {}
