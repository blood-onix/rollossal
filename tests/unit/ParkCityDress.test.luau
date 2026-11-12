--!strict
-- Park City's dress (014): every placed kind resolves to an uploaded mesh or a recorded stand-in, the coverage report
-- matches the generated world, and winter keeps its contrast (FR-002, FR-005, SC-001; contracts/dress-and-coverage.md).

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local Assets = require("../../src/shared/Assets")
local Themes = require("../../src/shared/Content/Themes")
local ParkCity = require("../../src/shared/Content/Worlds/ParkCity")
local Parts = require("../../src/shared/Content/Worlds/ParkCityParts")
local Light = require("../../src/shared/Content/Worlds/ParkCityLight")

local test, expect = harness.test, harness.expect

local coverage = serde.decode("json", fs.readFile("specs/014-park-city-art/coverage.json")) :: any
local manifest = serde.decode("json", fs.readFile("art/export/manifest.json")) :: any

local inManifest: { [string]: boolean } = {}
for _, mesh in manifest.meshes do
	inManifest[mesh.id] = true
end

local themes = Themes :: any
local SUPPORTED = { "winter", "city" }

local function roleInBothThemes(role: string?): boolean
	if role == nil or string.sub(role, 1, 2) ~= "w-" then
		return false
	end
	for _, themeId in SUPPORTED do
		if themes[themeId].palette[role] == nil then
			return false
		end
	end
	return true
end

-- One object def: a mesh key that is uploaded and in the manifest, or a stand-in with a w-* role in both themes.
-- A mesh object also keeps a role (it colours the part if the mesh fails to load).
local function expectResolves(object: any)
	expect.truthy(roleInBothThemes(object.role), `{object.id} role {object.role}`)
	if object.assetKey ~= nil then
		local id = (Assets.meshes :: any)[object.assetKey]
		expect.truthy(
			id ~= nil and id ~= "",
			`{object.id}: {object.assetKey} is not an uploaded mesh`
		)
		expect.truthy(
			inManifest[object.assetKey],
			`{object.id}: {object.assetKey} is not in the manifest`
		)
	end
	if object.atlas ~= nil then
		expect.equal(object.atlas, "fronts", object.id)
	end
	expect.truthy(
		object.fallback == "Block"
			or object.fallback == "Ball"
			or object.fallback == "Cylinder"
			or object.fallback == "Wedge",
		`{object.id} fallback`
	)
end

local objectById: { [string]: any } = {}
for _, object in ParkCity.objects do
	objectById[object.id] = object
end

test("ParkCityDress: every kind resolves to an uploaded mesh or a w-* stand-in role", function()
	for _, object in ParkCity.objects do
		expectResolves(object)
	end
	for _, themeId in SUPPORTED do
		for _, object in ParkCity.themeBindings[themeId].objects do
			expectResolves(object)
		end
	end
end)

test("ParkCityDress: every placed kind has an object def", function()
	for _, row in Parts do
		expect.truthy(objectById[row.objectId], `part {row.id} kind {row.objectId}`)
	end
	for index = 1, Light.count do
		local kind = Light.kinds[Light.data[(index - 1) * Light.stride + 1]]
		expect.truthy(objectById[kind], `light {index} kind {kind}`)
	end
	-- Slot placements resolve in every supported theme to a base or theme-only object.
	for _, themeId in SUPPORTED do
		local binding = ParkCity.themeBindings[themeId]
		local own: { [string]: boolean } = {}
		for _, object in binding.objects do
			own[object.id] = true
		end
		local slots: { string } = {}
		for _, slot in ParkCity.slotRows do
			table.insert(slots, slot)
		end
		for _, row in ParkCity.slotPlacements do
			table.insert(slots, row.objectId)
		end
		for _, slot in slots do
			local target = binding.slots[slot]
			expect.truthy(target ~= nil and (objectById[target] or own[target]), `{themeId} {slot}`)
		end
		for _, row in binding.overlays.fixedPlacements do
			expect.truthy(own[row.objectId], `{themeId} overlay {row.id}`)
		end
	end
end)

test(
	"ParkCityDress: the coverage report lists exactly the world's kinds with the same meshes",
	function()
		expect.equal(#coverage.kinds, #ParkCity.objects)
		expect.equal(coverage.totals.kinds, #ParkCity.objects)
		local seen: { [string]: boolean } = {}
		local meshes, standins = 0, 0
		for _, record in coverage.kinds do
			local object = objectById[record.id]
			expect.truthy(object, `coverage kind {record.id} is not in the world`)
			expect.falsy(seen[record.id], `duplicate {record.id}`)
			seen[record.id] = true
			expect.equal(record.assetKey, object.assetKey, record.id)
			expect.equal(record.tier, object.tier, record.id)
			if record.status == "standin" then
				expect.equal(object.assetKey, nil, record.id)
				standins += 1
			else
				expect.truthy(object.assetKey ~= nil, record.id)
				meshes += 1
			end
		end
		expect.equal(coverage.totals.exact + coverage.totals.substitute, meshes)
		expect.equal(coverage.totals.standin, standins)
		expect.equal(
			coverage.totals.exact + coverage.totals.substitute + coverage.totals.standin,
			#ParkCity.objects
		)
		expect.equal(coverage.theme, ParkCity.activeThemeId)
	end
)

test("ParkCityDress: placements per kind in the report equal the world data", function()
	local placed: { [string]: number } = {}
	for _, row in Parts do
		placed[row.objectId] = (placed[row.objectId] or 0) + 1
	end
	for index = 1, Light.count do
		local kind = Light.kinds[Light.data[(index - 1) * Light.stride + 1]]
		placed[kind] = (placed[kind] or 0) + 1
	end
	for _, record in coverage.kinds do
		expect.equal(record.placements, placed[record.id] or 0, record.id)
	end
end)

local function luminance(rgb: { number }): number
	return 0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
end

test("ParkCityDress: winter roads are dark against snow lawns and roofs (FR-005)", function()
	local winter = themes.winter.palette
	local roles: { [string]: string } = {}
	for _, block in ParkCity.environment.blocks do
		if block.kind ~= "Boundary" then
			roles[block.id] = block.swatch
		end
	end
	expect.equal(roles.ring_road, "w-asphalt")
	expect.equal(roles.ground_park, "w-grass")
	expect.equal(roles.roof_1, "w-snowcap")
	for _, dark in { "w-asphalt", "w-road-slush" } do
		for _, light in { "w-grass", "w-snowcap" } do
			local gap = luminance(winter[light]) - luminance(winter[dark])
			expect.truthy(gap >= 90, `winter {light} vs {dark}: luminance gap {gap}`)
		end
	end
end)

test("ParkCityDress: every block swatch and edge scenery role is in both theme palettes", function()
	for _, block in ParkCity.environment.blocks do
		if block.kind ~= "Boundary" then
			expect.truthy(roleInBothThemes(block.swatch), `block {block.id} swatch {block.swatch}`)
		end
	end
	for _, row in ParkCity.environment.scenery or {} do
		expect.truthy(roleInBothThemes(row.role), `scenery {row.id} role {row.role}`)
		if row.assetKey ~= nil then
			expect.truthy(inManifest[row.assetKey], `scenery {row.id}: {row.assetKey}`)
		end
	end
end)

test("ParkCityDress: the theme is winter or city and both are bound", function()
	expect.truthy(ParkCity.activeThemeId == "winter" or ParkCity.activeThemeId == "city")
	expect.same(ParkCity.supportedThemes, { "winter", "city" })
	for _, themeId in SUPPORTED do
		expect.truthy(ParkCity.themeBindings[themeId], themeId)
		expect.truthy(themes[themeId], themeId)
	end
end)

return {}
