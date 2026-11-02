--!strict
-- Growth pace model (specs/004-snow-village/research.md R1, plan finding F-1; 007 research R-08).
-- A deterministic greedy eater rolls through a world's expanded layout from each spawn point and the test
-- asserts how fast it grows. No clock, no randomness. The pickup rate and the speed formula are the model's
-- assumptions, written as constants here, not read from the world. The world and theme are parameters: Snow
-- Village keeps its 004 targets, Downtown (winter and city) has the 008 targets and an obstacle-aware eater
-- (specs/008-downtown-inside-out/contracts/pace-and-tests.md): walls and unabsorbable buildings add detours.

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
local MARKS = { 5, 12, 20, 30, 80, 150 }

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

type Obstacle = {
	kind: string,
	-- Axis-aligned footprint.
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	-- Wall: bottom and top. Building: its size, and the placement index (so a target is not its own obstacle).
	bottom: number,
	top: number,
	size: number,
	index: number,
}

export type Model = {
	placements: { Placement },
	sizes: { [string]: number },
	spawns: { SpawnPoint },
	growthK: number,
	-- Spatial hash of obstacles (20-stud cells); nil for the blind eater (Snow Village).
	cells: { [number]: { Obstacle } }?,
	-- The placements already eaten (set by the eater that is stepping): an eaten building no longer blocks.
	eaten: { [number]: boolean }?,
}

local CELL = 20
local function cellKey(cx: number, cz: number): number
	return (cx + 1000) * 4096 + (cz + 1000)
end

local function buildObstacles(
	world: any,
	theme: any,
	placements: { Placement },
	sizes: { [string]: number }
)
	local cells: { [number]: { Obstacle } } = {}
	local function add(obstacle: Obstacle)
		for cx = math.floor(obstacle.x0 / CELL), math.floor(obstacle.x1 / CELL) do
			for cz = math.floor(obstacle.z0 / CELL), math.floor(obstacle.z1 / CELL) do
				local key = cellKey(cx, cz)
				local list = cells[key]
				if list == nil then
					list = {}
					cells[key] = list
				end
				table.insert(list, obstacle)
			end
		end
	end
	local all = table.clone(world.environment.blocks)
	local binding = if world.themeBindings then world.themeBindings[theme.id] else nil
	if binding ~= nil and binding.blocks ~= nil then
		table.move(binding.blocks, 1, #binding.blocks, #all + 1, all)
	end
	for _, block in all do
		local top = block.cframe.y + block.size.y / 2
		if block.kind ~= "Boundary" and block.kind ~= "Wedge" and top > 2.5 then
			local sideways = block.cframe.yaw % 180 ~= 0
			local hx = (if sideways then block.size.z else block.size.x) / 2
			local hz = (if sideways then block.size.x else block.size.z) / 2
			add({
				kind = "wall",
				x0 = block.cframe.x - hx,
				x1 = block.cframe.x + hx,
				z0 = block.cframe.z - hz,
				z1 = block.cframe.z + hz,
				bottom = block.cframe.y - block.size.y / 2,
				top = top,
				size = 0,
				index = 0,
			})
		end
	end
	for index, placement in placements do
		local size = sizes[placement.objectId]
		if size >= 2 then
			add({
				kind = "building",
				x0 = placement.x - size / 2,
				x1 = placement.x + size / 2,
				z0 = placement.z - size / 2,
				z1 = placement.z + size / 2,
				bottom = 0,
				top = 0,
				size = size,
				index = index,
			})
		end
	end
	return cells
end

-- Does this obstacle stop a ball of diameter D? Walls: bottom < D and top > max(2.5, D/2). Buildings: size > 0.4 D.
local function blocks(model: Model, obstacle: Obstacle, diameter: number, ignore: number): boolean
	if obstacle.kind == "wall" then
		return obstacle.bottom < diameter and obstacle.top > math.max(2.5, 0.5 * diameter)
	end
	local eaten = model.eaten
	return obstacle.size > Config.absorbRatio * diameter
		and obstacle.index ~= ignore
		and not (eaten ~= nil and eaten[obstacle.index])
end

-- Segment against rectangle (slab method). Returns the entry parameter or nil.
local function hit(obstacle: Obstacle, ax: number, az: number, bx: number, bz: number): number?
	local dx, dz = bx - ax, bz - az
	local t0, t1 = 0, 1
	for axis = 1, 2 do
		local origin = if axis == 1 then ax else az
		local delta = if axis == 1 then dx else dz
		local lo = if axis == 1 then obstacle.x0 else obstacle.z0
		local hi = if axis == 1 then obstacle.x1 else obstacle.z1
		if math.abs(delta) < 1e-9 then
			if origin <= lo or origin >= hi then
				return nil
			end
		else
			local ta, tb = (lo - origin) / delta, (hi - origin) / delta
			if ta > tb then
				ta, tb = tb, ta
			end
			t0, t1 = math.max(t0, ta), math.min(t1, tb)
			if t0 >= t1 then
				return nil
			end
		end
	end
	return t0
end

-- The nearest obstacle on the segment that stops a ball of this diameter. An obstacle the start already stands in
-- (the ball is inside its footprint) is ignored.
local function firstBlocker(
	model: Model,
	ax: number,
	az: number,
	bx: number,
	bz: number,
	diameter: number,
	ignore: number
): Obstacle?
	local cells = model.cells :: { [number]: { Obstacle } }
	local best: Obstacle? = nil
	local bestT = math.huge
	local seen: { [Obstacle]: boolean } = {}
	for cx = math.floor(math.min(ax, bx) / CELL), math.floor(math.max(ax, bx) / CELL) do
		for cz = math.floor(math.min(az, bz) / CELL), math.floor(math.max(az, bz) / CELL) do
			local list = cells[cellKey(cx, cz)]
			if list ~= nil then
				for _, obstacle in list do
					if not seen[obstacle] then
						seen[obstacle] = true
						if blocks(model, obstacle, diameter, ignore) then
							local inside = ax > obstacle.x0
								and ax < obstacle.x1
								and az > obstacle.z0
								and az < obstacle.z1
							local t = if inside then nil else hit(obstacle, ax, az, bx, bz)
							if t ~= nil and t < bestT then
								best, bestT = obstacle, t
							end
						end
					end
				end
			end
		end
	end
	return best
end

-- Path length from A to B for a ball of diameter D, round the first blocking obstacle if needed; nil if none.
local function pathLength(
	model: Model,
	ax: number,
	az: number,
	bx: number,
	bz: number,
	diameter: number,
	ignore: number
): number?
	local straight = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	local blocker = firstBlocker(model, ax, az, bx, bz, diameter, ignore)
	if blocker == nil then
		return straight
	end
	local pad = diameter / 2 + 0.5
	local best: number? = nil
	for _, corner in
		{
			{ blocker.x0 - pad, blocker.z0 - pad },
			{ blocker.x1 + pad, blocker.z0 - pad },
			{ blocker.x0 - pad, blocker.z1 + pad },
			{ blocker.x1 + pad, blocker.z1 + pad },
		}
	do
		if
			firstBlocker(model, ax, az, corner[1], corner[2], diameter, ignore) == nil
			and firstBlocker(model, corner[1], corner[2], bx, bz, diameter, ignore) == nil
		then
			local length = math.sqrt((corner[1] - ax) ^ 2 + (corner[2] - az) ^ 2)
				+ math.sqrt((bx - corner[1]) ^ 2 + (bz - corner[2]) ^ 2)
			if best == nil or length < best then
				best = length
			end
		end
	end
	return best
end

-- The expanded layout of one world under one theme, with the sizes of every object that theme places.
local function modelFor(world: any, themeId: string, obstacleAware: boolean?): Model
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
		cells = if obstacleAware
			then buildObstacles(world, theme, resolved.placements, sizes)
			else nil,
	}
end

-- One eater. Each step it goes for the eatable object with the most volume per second of travel, spends the larger
-- of the travel time and the pickup interval, and grows. With obstacles it skips what it cannot reach and pays
-- the detour for what it can (the straight-line score only orders the candidates).
type Eater = {
	x: number,
	z: number,
	diameter: number,
	clock: number,
	pickups: number,
	done: boolean,
	report: Report,
}

local function newEater(startX: number, startZ: number): Eater
	return {
		x = startX,
		z = startZ,
		diameter = Config.startDiameter,
		clock = 0,
		pickups = 0,
		done = false,
		report = {
			firstAt = nil,
			diameterAt = {},
			tier2At = nil,
			final = Config.startDiameter,
			pickups = 0,
		},
	}
end

-- One pickup. `eaten` is shared when several eaters share the world.
local function step(model: Model, eater: Eater, eaten: { [number]: boolean }, k: number)
	local placements, sizes = model.placements, model.sizes
	local speed = speedFor(eater.diameter)
	local interval = if eater.diameter >= LARGE_FROM_DIAMETER
		then 1 / LARGE_PICKUP_RATE
		else 1 / SMALL_PICKUP_RATE
	model.eaten = eaten
	local candidates: { { index: number, score: number } } = {}
	for index, placement in placements do
		local size = sizes[placement.objectId]
		if not eaten[index] and Absorb.canAbsorb(eater.diameter, size, Config.absorbRatio) then
			local travel = math.sqrt((placement.x - eater.x) ^ 2 + (placement.z - eater.z) ^ 2)
				/ speed
			table.insert(
				candidates,
				{ index = index, score = size ^ 3 / math.max(travel, interval) }
			)
		end
	end
	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)
	local pick = 0
	local travel = 0.0
	for rank, candidate in candidates do
		local placement = placements[candidate.index]
		if model.cells == nil then
			pick = candidate.index
			travel = math.sqrt((placement.x - eater.x) ^ 2 + (placement.z - eater.z) ^ 2) / speed
			break
		end
		if rank > 400 then
			break
		end
		local length = pathLength(
			model,
			eater.x,
			eater.z,
			placement.x,
			placement.z,
			eater.diameter,
			candidate.index
		)
		if length ~= nil then
			pick = candidate.index
			travel = length / speed
			break
		end
	end
	if pick == 0 and #candidates > 0 then
		-- Boxed in by buildings the one-corner detour cannot get round: the ball nudges its way out at twice the
		-- straight-line time. Walls and gates are still honoured above; this only stops a courtyard deadlock.
		local candidate = candidates[1]
		local near = placements[candidate.index]
		pick = candidate.index
		travel = 2 * math.sqrt((near.x - eater.x) ^ 2 + (near.z - eater.z) ^ 2) / speed
	end
	if pick == 0 then
		eater.done = true
		return
	end
	local placement = placements[pick]
	eater.clock += math.max(travel, interval)
	if eater.clock > RUN_SECONDS then
		eater.done = true
		return
	end
	eaten[pick] = true
	eater.x, eater.z = placement.x, placement.z
	eater.pickups += 1
	local report = eater.report
	if report.firstAt == nil then
		report.firstAt = eater.clock
	end
	eater.diameter = Growth.growDiameter(eater.diameter, sizes[placement.objectId], k)
	if report.tier2At == nil and eater.diameter >= TIER_2_DIAMETER then
		report.tier2At = eater.clock
	end
	for _, mark in MARKS do
		if report.diameterAt[mark] == nil and eater.diameter >= mark then
			report.diameterAt[mark] = eater.clock
		end
	end
	report.final = eater.diameter
	report.pickups = eater.pickups
end

local function simulate(model: Model, startX: number, startZ: number, k: number): Report
	local eater = newEater(startX, startZ)
	local eaten: { [number]: boolean } = {}
	while not eater.done and eater.clock < RUN_SECONDS do
		step(model, eater, eaten, k)
	end
	return eater.report
end

-- All twelve spawns eat from one world at once, earliest clock first (FR-008).
local function simulateTwelve(model: Model): { Report }
	local eaten: { [number]: boolean } = {}
	local eaters: { Eater } = {}
	for _, spawn in model.spawns do
		eaters[spawn.slot] = newEater(spawn.x, spawn.z)
	end
	while true do
		local next: Eater? = nil
		for _, eater in eaters do
			if
				not eater.done
				and eater.clock < RUN_SECONDS
				and (next == nil or eater.clock < next.clock)
			then
				next = eater
			end
		end
		if next == nil then
			break
		end
		step(model, next, eaten, model.growthK)
	end
	local reports: { Report } = {}
	for slot, eater in eaters do
		reports[slot] = eater.report
	end
	return reports
end

local function reportsFor(world: any, themeId: string, obstacleAware: boolean?): { Report }
	local model = modelFor(world, themeId, obstacleAware)
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

-- Downtown (008, contracts/pace-and-tests.md): the windows are data. First pickup <= 5 s; D 5 at 10 to 50 s; D 12 at
-- 35 to 110 s (lower bound relaxed 2026-11-02 when the doorstep was rebuilt to start with food a D 2 ball can eat); D 30 at 65 to 180 s (lower bound relaxed the same way); D 80 by 210 s; D 150 by 240 s. All 12 spawns, both themes, obstacle-aware.
local WINDOWS: { [number]: { number } } = {
	[5] = { 10, 50 },
	[12] = { 35, 110 },
	[30] = { 65, 180 },
	[80] = { 0, 210 },
	[150] = { 0, 240 },
}
for _, themeId in { "winter", "city" } do
	local model = modelFor(Downtown, themeId, true)
	local reports: { Report } = {}
	for _, spawn in model.spawns do
		reports[spawn.slot] = simulate(model, spawn.x, spawn.z, model.growthK)
	end

	test(`Pace: Downtown {themeId} sees the 12 spawn slots`, function()
		expect.equal(#reports, 12)
	end)

	test(`Pace: Downtown {themeId} hits the pace windows from every spawn`, function()
		for slot, report in reports do
			local label = `{themeId} slot {slot}`
			expect.truthy(
				report.firstAt ~= nil and (report.firstAt :: number) <= 5,
				`{label} first pickup`
			)
			for mark, window in WINDOWS do
				local at = report.diameterAt[mark]
				expect.truthy(at ~= nil, `{label}: never reaches D {mark} (final {report.final})`)
				if at ~= nil then
					expect.truthy(
						at >= window[1] and at <= window[2],
						`{label}: D {mark} at {at}, wanted {window[1]} to {window[2]}`
					)
				end
			end
		end
	end)

	test(`Pace: Downtown {themeId} twelve starters sharing the food all get going`, function()
		local twelve = simulateTwelve(model)
		for slot, report in twelve do
			local label = `{themeId} slot {slot}`
			expect.truthy(
				report.firstAt ~= nil and (report.firstAt :: number) <= 5,
				`{label} first pickup`
			)
			local five = report.diameterAt[5]
			expect.truthy(five ~= nil and five <= 60, `{label}: D 5 at {five}`)
		end
	end)
end

return {
	simulate = simulate,
	simulateTwelve = simulateTwelve,
	modelFor = modelFor,
	reportsFor = reportsFor,
	MARKS = MARKS,
}
