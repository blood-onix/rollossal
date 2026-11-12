--!strict
-- The generated Park City world (src/shared/Content/Worlds/ParkCity*.luau) against its source, the layout file
-- docs/design/maps/park-city-layout.json (012 research R1; G1 world data and G2 world matches layout).
-- The tier list, stars and shot names are written out by hand from the spec and the design document.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local ParkCity = require("../../src/shared/Content/Worlds/ParkCity")
local Parts = require("../../src/shared/Content/Worlds/ParkCityParts")
local Light = require("../../src/shared/Content/Worlds/ParkCityLight")
local Names = require("../../src/shared/Localization/ParkCityStrings")
local Tiers = require("../../src/shared/Rules/Tiers")

local test, expect = harness.test, harness.expect

local layout = serde.decode("json", fs.readFile("docs/design/maps/park-city-layout.json")) :: any

local objectById: { [string]: any } = {}
for _, object in ParkCity.objects do
	objectById[object.id] = object
end

-- Every generated object as a row {kind, x, y, z}, parts first.
local generated: { { kind: string, x: number, y: number, z: number, light: boolean } } = {}
for _, row in Parts do
	table.insert(generated, { kind = row.objectId, x = row.x, y = row.y, z = row.z, light = false })
end
for index = 1, Light.count do
	local at = (index - 1) * Light.stride
	table.insert(generated, {
		kind = Light.kinds[Light.data[at + 1]],
		x = Light.data[at + 2],
		y = Light.data[at + 3],
		z = Light.data[at + 4],
		light = true,
	})
end

test("ParkCity: the generated count per tier equals the layout summary", function()
	local counts: { [number]: number } = {}
	for _, row in generated do
		local tier = objectById[row.kind].tier
		counts[tier] = (counts[tier] or 0) + 1
	end
	for tier = 1, 6 do
		expect.equal(counts[tier], layout.summary.objectsByTier[tostring(tier)], `tier {tier}`)
	end
	expect.equal(#Parts, layout.summary.partObjects)
	expect.equal(Light.count, layout.summary.lightObjects)
	expect.equal(#generated, layout.summary.total)
end)

test(
	"ParkCity: every layout object is in the data at its position (within 0.01), same kind",
	function()
		local cells: { [string]: { any } } = {}
		local function cellKey(kind: string, x: number, z: number): string
			return `{kind}|{math.floor(x / 4)}|{math.floor(z / 4)}`
		end
		for _, row in generated do
			local key = cellKey(row.kind, row.x, row.z)
			local list = cells[key]
			if list == nil then
				list = {}
				cells[key] = list
			end
			table.insert(list :: { any }, row)
		end
		local function take(kind: string, x: number, y: number, z: number): boolean
			for dx = -1, 1 do
				for dz = -1, 1 do
					local list = cells[cellKey(kind, x + dx * 4, z + dz * 4)]
					if list then
						for index, row in list do
							if
								math.abs(row.x - x) <= 0.01
								and math.abs(row.z - z) <= 0.01
								and math.abs(row.y - y) <= 0.01
							then
								table.remove(list, index)
								return true
							end
						end
					end
				end
			end
			return false
		end
		local checked = 0
		local function visit(kind: string, item: any)
			checked += 1
			if not take(kind, item.x, item.y or 0, item.z) then
				error(`layout object {kind} at {item.x}, {item.z} is missing from the world data`)
			end
		end
		for _, scene in layout.scenes do
			for _, item in scene.items do
				visit(item.object, item)
			end
		end
		for _, trail in layout.trails do
			for _, item in trail.items do
				visit(item.object, item)
			end
		end
		for _, landmark in layout.landmarks do
			visit(landmark.object, landmark)
		end
		expect.equal(checked, layout.summary.total)
		-- Nothing is left over: the data holds exactly the layout's objects.
		for _, list in cells do
			expect.equal(#list, 0)
		end
	end
)

test("ParkCity: blocks, spawns and placeholders match the layout in count and id", function()
	expect.equal(#ParkCity.environment.blocks, 90)
	expect.equal(#ParkCity.environment.blocks, #layout.blocks)
	local blockIds: { [string]: boolean } = {}
	for _, block in ParkCity.environment.blocks do
		blockIds[block.id] = true
	end
	for _, block in layout.blocks do
		expect.truthy(blockIds[block.id], `block {block.id}`)
	end
	expect.equal(#ParkCity.spawnPoints, 12)
	expect.equal(#ParkCity.spawnPoints, #layout.spawns)
	for index, spawn in layout.spawns do
		local point = ParkCity.spawnPoints[index]
		expect.equal(point.x, spawn.x)
		expect.equal(point.z, spawn.z)
	end
	expect.equal(#ParkCity.golden, 7)

	local rails, pipes, pads, catapults, water = 0, 0, 0, 0, 0
	local ids: { [string]: boolean } = {}
	for _, placeholder in ParkCity.placeholders do
		expect.falsy(ids[placeholder.id], `duplicate placeholder {placeholder.id}`)
		ids[placeholder.id] = true
	end
	for _, rail in layout.rails do
		if rail.kind == "pipe" then
			pipes += 1
		else
			rails += 1
		end
		expect.truthy(ids[rail.id], `rail {rail.id}`)
	end
	for _, pad in layout.pads do
		pads += 1
		expect.truthy(ids[pad.id], `pad {pad.id}`)
	end
	for _, catapult in layout.catapults do
		catapults += 1
		expect.truthy(ids[catapult.id], `catapult {catapult.id}`)
	end
	for _, area in layout.water do
		water += 1
		expect.truthy(ids[area.id], `water {area.id}`)
	end
	expect.equal(rails, 13)
	expect.equal(pipes, 4)
	expect.equal(pads, 80)
	expect.equal(catapults, 18)
	expect.equal(water, 3)
	expect.equal(#ParkCity.placeholders, rails + pipes + pads + catapults + water)
end)

test(
	"ParkCity: every kind's dims equal the layout's, and its tier is the tier of its bulk",
	function()
		local minimums: { Tiers.TierLike } = {}
		for _, tier in ParkCity.sizeTiers do
			table.insert(minimums, tier)
		end
		local count = 0
		for kind, record in layout.objects do
			count += 1
			local object = objectById[kind]
			expect.truthy(object, kind)
			for axis = 1, 3 do
				expect.equal(object.dims[axis], record.dims[axis], `{kind} dims`)
			end
			expect.equal(object.size, math.max(record.dims[1], record.dims[2], record.dims[3]))
			local bulk = (record.dims[1] * record.dims[2] * record.dims[3]) ^ (1 / 3)
			-- The layout's rule: tier by bulk, inclusive at the top (a bulk of exactly 3 is Tier 2).
			expect.equal(Tiers.lookup(2 * bulk - 1e-6, minimums), object.tier, `{kind} tier`)
			expect.equal(object.tier, record.tier, `{kind} layout tier`)
			expect.near(object.bulk, bulk, 0.01)
		end
		expect.equal(count, #ParkCity.objects)
		expect.equal(count, 231)
	end
)

test("ParkCity: ids are unique and every position is inside the map", function()
	local seen: { [string]: boolean } = {}
	for _, row in Parts do
		expect.falsy(seen[row.id], `duplicate {row.id}`)
		seen[row.id] = true
		expect.truthy(string.match(row.id, "^p%d+$"), row.id)
		expect.truthy(math.abs(row.x) <= 500 and math.abs(row.z) <= 500, `{row.id} outside`)
		expect.truthy(objectById[row.objectId].tier >= 3, `{row.id} is a light object`)
	end
	for _, row in generated do
		expect.truthy(math.abs(row.x) <= 500 and math.abs(row.z) <= 500)
		expect.equal(objectById[row.kind].tier <= 2, row.light, row.kind)
	end
	expect.equal(#Light.data, Light.count * Light.stride)
	for index = 1, Light.count do
		local kindIndex = Light.data[(index - 1) * Light.stride + 1]
		expect.truthy(Light.kinds[kindIndex] ~= nil, `light {index} kind`)
	end
end)

test(
	"ParkCity: six tiers ascend 1 / 2.5 / 6 / 15 / 35 / 80, top 150, stars 20 / 50 / 90",
	function()
		local minimums = { 1, 2.5, 6, 15, 35, 80 }
		expect.equal(#ParkCity.sizeTiers, 6)
		for index, tier in ParkCity.sizeTiers do
			expect.equal(tier.minDiameter, minimums[index])
			expect.equal(tier.maxDiameter, minimums[index + 1] or 150)
		end
		expect.same(ParkCity.starThresholds, { 20, 50, 90 })
		expect.equal(ParkCity.rules.startDiameter, 1)
		expect.equal(ParkCity.rules.absorb.mode, "bulk")
		expect.equal(ParkCity.rules.speedCap.max, 56)
		expect.equal(ParkCity.hub.center.x, -760)
		expect.equal(ParkCity.hub.center.z, 0)
	end
)

test(
	"ParkCity: the eleven fixed shots are pinned by name and order and sit inside the map",
	function()
		local names = {
			"spawn_nw",
			"spawn_ne",
			"spawn_se",
			"spawn_sw",
			"duck_island",
			"hedge_maze",
			"roof_run",
			"car_park",
			"plaza",
			"giant_oak",
			"overview",
		}
		expect.equal(#ParkCity.shots, #names)
		for index, shot in ParkCity.shots do
			expect.equal(shot.name, names[index])
			expect.truthy(math.abs(shot.pos[1]) <= 500 and math.abs(shot.pos[3]) <= 500, shot.name)
			expect.truthy(shot.pos[2] > 0)
			expect.truthy(
				math.abs(shot.look[1]) <= 500 and math.abs(shot.look[3]) <= 500,
				shot.name
			)
		end
	end
)

test("ParkCity: hedge and hoarding pieces are solid, and only they", function()
	local solid = 0
	for _, row in Parts do
		if row.solid then
			solid += 1
			expect.equal(row.objectId, "hoarding")
		end
	end
	expect.equal(solid, 28)
	expect.equal(objectById.hedge_piece.solid, true)
	expect.equal(objectById.hoarding.solid, true)
	local hedges = 0
	for index = 1, Light.count do
		if Light.kinds[Light.data[(index - 1) * Light.stride + 1]] == "hedge_piece" then
			hedges += 1
		end
	end
	expect.equal(hedges, layout.summary.hedgePieces)
end)

test("ParkCity: every kind and tier has an English and Spanish name", function()
	for _, object in ParkCity.objects do
		local entry = (Names :: any)[object.nameKey]
		expect.truthy(entry, object.nameKey)
		expect.truthy(#entry.en > 0 and #entry.es > 0, object.nameKey)
	end
	for _, tier in ParkCity.sizeTiers do
		for _, key in { tier.nameKey, tier.headlineKey } do
			local entry = (Names :: any)[key]
			expect.truthy(entry, key)
			expect.truthy(#entry.en > 0 and #entry.es > 0, key)
		end
	end
	for key, entry in Names :: any do
		expect.falsy(string.find(entry.en, "[{}]"), key)
		expect.falsy(string.find(entry.es, "[{}]"), key)
	end
end)

-- 014: the theme fields, resolved as Worlds.luau does it (slotRows turned into slot ids, slotPlacements added).
local Config = require("../../src/shared/Config")
local Layout = require("../../src/shared/Rules/Layout")
local ThemeResolve = require("../../src/shared/Rules/ThemeResolve")
local Themes = require("../../src/shared/Content/Themes")

local function baseWorld(): any
	local world = table.clone(ParkCity) :: any
	local fixed = {}
	for _, row in Parts do
		local slot = ParkCity.slotRows[row.id]
		if slot ~= nil then
			row = table.clone(row)
			row.objectId = slot
		end
		table.insert(fixed, row)
	end
	for _, row in ParkCity.slotPlacements do
		table.insert(fixed, row)
	end
	world.fixedPlacements = fixed
	return world
end

test("ParkCity: theme fields name a supported theme and bind winter and city", function()
	-- winter is the default; city is the one-line switch in scripts/park_city_dress.py (FR-006).
	expect.truthy(ParkCity.activeThemeId == "winter" or ParkCity.activeThemeId == "city")
	expect.same(ParkCity.supportedThemes, { "winter", "city" })
	expect.truthy(ParkCity.themeBindings.winter and ParkCity.themeBindings.city)
	-- The Plaza landmark is the one slot row, and it is the layout's theme_landmark (a giant duck at the Plaza).
	local count = 0
	for id, slot in ParkCity.slotRows do
		count += 1
		expect.equal(slot, "slot.landmark")
		local row: any = nil
		for _, part in Parts do
			if part.id == id then
				row = part
			end
		end
		expect.equal(row.objectId, "giant_duck")
		expect.equal(row.x, 0)
		expect.equal(row.z, 36)
	end
	expect.equal(count, 1)
end)

test(
	"ParkCity: the Plaza landmark resolves to a mega tree in winter and a giant duck in city",
	function()
		local world = baseWorld()
		local plazaId = next(ParkCity.slotRows)
		local expected = { winter = "mega_tree", city = "giant_duck" }
		for themeId, objectId in expected do
			local result = ThemeResolve.resolve(
				world,
				(Themes :: any)[themeId],
				Layout.expand,
				Config.Budgets.defaultMaxPlacements
			)
			local found = false
			for _, placement in result.fixedPlacements do
				expect.falsy(ThemeResolve.isSlot(placement.objectId), placement.id)
				if placement.id == plazaId then
					found = true
					expect.equal(placement.objectId, objectId)
				end
				-- ThemeResolve drops a placement's `solid`; collision comes from the object def (D4).
				expect.equal((placement :: any).solid, nil)
			end
			expect.truthy(found, themeId)
			expect.truthy(result.slotPlacementIds[plazaId], themeId)
			-- The swap never changes the rules: the theme's landmark has the duck's dims, bulk and tier.
			local byId: { [string]: any } = {}
			for _, object in result.objects do
				byId[object.id] = object
			end
			local landmark, duck = byId[objectId], objectById.giant_duck
			expect.equal(landmark.tier, duck.tier)
			expect.equal(landmark.bulk, duck.bulk)
			expect.same(landmark.dims, duck.dims)
		end
	end
)

test(
	"ParkCity: nothing taller than 1 stud stands within 15 studs of a spawn, and spawns stay apart (FR-008)",
	function()
		for _, spawn in ParkCity.spawnPoints do
			local function near(x: number, z: number, halfX: number, halfZ: number): boolean
				local dx = math.max(math.abs(x - spawn.x) - halfX, 0)
				local dz = math.max(math.abs(z - spawn.z) - halfZ, 0)
				return math.sqrt(dx * dx + dz * dz) <= 15
			end
			for _, block in ParkCity.environment.blocks do
				if
					block.kind ~= "Boundary"
					and near(block.cframe.x, block.cframe.z, block.size.x / 2, block.size.z / 2)
				then
					local top = block.cframe.y + block.size.y / 2
					expect.truthy(top <= 1, `spawn {spawn.slot}: block {block.id} top {top}`)
				end
			end
			for _, row in generated do
				local object = objectById[row.kind]
				local tall = object.dims[3] > 1 and (not row.light or object.solid == true)
				if tall and near(row.x, row.z, 0, 0) then
					error(`spawn {spawn.slot}: {row.kind} at {row.x}, {row.z} is an obstacle`)
				end
			end
		end
		for i, a in ParkCity.spawnPoints do
			for j, b in ParkCity.spawnPoints do
				if i < j then
					local gap = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
					expect.truthy(gap >= 270, `spawns {i} and {j} are {gap} apart`)
				end
			end
		end
	end
)

test(
	"ParkCity: the map edge is scenery in the 500-620 band, within its Part budget, and never an object",
	function()
		local scenery = ParkCity.environment.scenery
		expect.equal(#scenery, #layout.edge.rows)
		expect.truthy(#scenery > 0 and #scenery <= layout.edge.limits.parts)
		local placementIds: { [string]: boolean } = {}
		for _, row in Parts do
			placementIds[row.id] = true
		end
		for _, row in scenery do
			local at = row.cframe
			-- Outside the playable square (the boundary walls are at 500), inside the outer extent.
			expect.truthy(math.max(math.abs(at.x), math.abs(at.z)) > 500, row.id)
			expect.truthy(
				math.abs(at.x) + row.size.x / 2 <= 620.01
					and math.abs(at.z) + row.size.z / 2 <= 620.01,
				row.id
			)
			expect.falsy(placementIds[row.id], row.id)
			expect.equal(objectById[row.id], nil)
		end
	end
)

test("ParkCity: no runtime code reads a placement's solid, only an object def's (D4)", function()
	local function scan(dir: string)
		for _, name in fs.readDir(dir) do
			local path = `{dir}/{name}`
			if fs.isDir(path) then
				if name ~= "Content" then
					scan(path)
				end
			elseif string.match(name, "%.luau$") then
				for reader in string.gmatch(fs.readFile(path), "([%w_]+)%.solid") do
					expect.equal(reader, "def", `{path} reads {reader}.solid`)
				end
			end
		end
	end
	scan("src")
end)

test("ParkCity: spiral blocks carry turns and width, ramps rise to a side", function()
	local spirals = 0
	for _, block in ParkCity.environment.blocks do
		if block.kind == "Spiral" then
			spirals += 1
			expect.truthy(block.turns > 0 and block.width > 0, block.id)
		end
		if block.kind == "Wedge" then
			expect.truthy(block.cframe.yaw % 90 == 0, block.id)
		end
	end
	expect.equal(spirals, 1)
end)

return {}
