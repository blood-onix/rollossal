--!strict
-- The art gate that runs without Blender (specs/004-snow-village/contracts/art-pipeline.md): the exported
-- meshes through their manifest, the asset keys, the budgets file and the hard-coded id scan. With no
-- manifest yet the mesh checks run in fallback mode and only the id scan, key coverage and budgets file apply.
-- 007 generalises it to both worlds: Snow Village keys are the object ids, Downtown keys are dt_<id> (theme-only
-- objects and hero variants included). Downtown meshes arrive wave by wave, so they are optional in the manifest
-- and in Assets.meshes until REQUIRE_ASSET_IDS=1, which demands the manifest and every imported asset id.
--
-- Local vars and test helpers:
--
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local harness = require("./harness")
local ArtBudgets = require("../../scripts/art-budgets")
local Fbx = require("../../scripts/fbx-geometry")
local Assets = require("../../src/shared/Assets")
local Config = require("../../src/shared/Config")
local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")
local Downtown = require("../../src/shared/Content/Worlds/Downtown")
local CityKit = require("../../src/shared/Content/CityKit")

local test, expect = harness.test, harness.expect

local MANIFEST = "art/export/manifest.json"
local BUDGETS = "art/scripts/budgets.json"
local requireIds = process.env.REQUIRE_ASSET_IDS == "1"

type ManifestEntry = { id: string, tier: number, triangles: number, bytes: number, sha256: string }

local hasManifest = fs.isFile(MANIFEST)

local function readManifest(): { meshes: { ManifestEntry }, blender: string? }
	return serde.decode("json", fs.readFile(MANIFEST))
end

local function sameValue(a: unknown, b: unknown): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	local left, right = a :: { [unknown]: unknown }, b :: { [unknown]: unknown }
	for key, value in left do
		if not sameValue(value, right[key]) then
			return false
		end
	end
	for key in right do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function walk(directory: string, found: { string })
	for _, name in fs.readDir(directory) do
		local path = `{directory}/{name}`
		if fs.isDir(path) then
			walk(path, found)
		elseif string.match(name, "%.luau$") then
			table.insert(found, path)
		end
	end
end

-- The mesh keys the two worlds ask for, by world.
local snowKeys: { [string]: boolean } = {}
local downtownKeys: { [string]: boolean } = {}
local kitKeys: { [string]: boolean } = {}
for _, entry in ArtBudgets.meshes() do
	if entry.world == "snow_village" then
		snowKeys[entry.key] = true
	elseif entry.world == "city_kit" then
		kitKeys[entry.key] = true
	else
		downtownKeys[entry.key] = true
	end
end

test(
	"Art: the committed budgets file matches Config and the Snow Village and Downtown data",
	function()
		expect.truthy(fs.isFile(BUDGETS))
		local committed = serde.decode("json", fs.readFile(BUDGETS))
		expect.truthy(sameValue(committed, ArtBudgets.build()))
	end
)

test("Art: no mesh, texture or sound id is hard-coded outside Assets.luau", function()
	local files: { string } = {}
	walk("src", files)
	expect.truthy(#files > 0)
	for _, path in files do
		if path ~= "src/shared/Assets.luau" then
			local text = fs.readFile(path)
			if
				string.find(text, "rbxassetid://", 1, true)
				or string.find(text, "rbxasset://sounds", 1, true)
			then
				error(`{path} holds an asset id`)
			end
		end
	end
end)

test(
	"Art: Assets.meshes holds every Snow Village key and the hub, and no key the worlds do not ask for",
	function()
		local wanted: { [string]: boolean } = { hub = true }
		for _, object in SnowVillage.objects do
			wanted[object.assetKey :: string] = true
		end
		for key in wanted do
			expect.truthy(Assets.meshes[key] ~= nil)
		end
		for key in Assets.meshes do
			expect.truthy(
				wanted[key] or downtownKeys[key] or kitKeys[key],
				`{key} is not an asset key of any world`
			)
		end
		expect.equal(SnowVillage.hub.assetKey, "hub")
		expect.equal(Downtown.hub.assetKey, "hub")
	end
)

test("Art: Downtown asks for 99 meshes, all keyed dt_ and disjoint from Snow Village", function()
	local count = 0
	for key in downtownKeys do
		count += 1
		expect.truthy(string.sub(key, 1, 3) == "dt_", key)
		expect.falsy(snowKeys[key], key)
	end
	expect.equal(count, 99)
	expect.equal(#ArtBudgets.meshes(), #SnowVillage.objects + 99 + #CityKit.objects)
end)

test(
	"Art: the city kit asks for 84 meshes, all keyed ck_ and disjoint from Snow Village and Downtown",
	function()
		local count = 0
		for key in kitKeys do
			count += 1
			expect.truthy(string.sub(key, 1, 3) == "ck_", key)
			expect.falsy(snowKeys[key], key)
			expect.falsy(downtownKeys[key], key)
		end
		expect.equal(count, 84)
		expect.equal(#CityKit.objects, 84)
		for _, object in CityKit.objects do
			expect.truthy(Assets.meshes[object.assetKey :: string] ~= nil, object.id)
		end
	end
)

test("Art: with REQUIRE_ASSET_IDS=1 every Downtown key is in Assets.meshes", function()
	if not requireIds then
		return
	end
	for key in downtownKeys do
		expect.truthy(Assets.meshes[key] ~= nil, `{key} is missing from Assets.meshes`)
	end
end)

test(
	"Art: the manifest has an entry per Snow Village object and the hub, plus the Downtown meshes built",
	function()
		if not hasManifest then
			expect.falsy(requireIds)
			return
		end
		local manifest = readManifest()
		local byId: { [string]: ManifestEntry } = {}
		for _, entry in manifest.meshes do
			expect.falsy(byId[entry.id])
			byId[entry.id] = entry
		end
		local budgets = ArtBudgets.build()
		for _, object in SnowVillage.objects do
			local entry = byId[object.id]
			expect.truthy(entry ~= nil, object.id)
			expect.equal(entry.tier, object.tier)
		end
		expect.truthy(byId.hub ~= nil)
		local downtownBuilt, kitBuilt = 0, 0
		for id, entry in byId do
			if downtownKeys[id] then
				downtownBuilt += 1
				expect.equal(entry.tier, budgets.tiers[id], id)
			elseif kitKeys[id] then
				kitBuilt += 1
				expect.equal(entry.tier, budgets.tiers[id], id)
			else
				expect.truthy(snowKeys[id] or id == "hub", `{id} is not a mesh of any world`)
			end
		end
		expect.equal(#manifest.meshes, #SnowVillage.objects + 1 + downtownBuilt + kitBuilt)
		if requireIds then
			expect.equal(downtownBuilt, 99)
			expect.equal(kitBuilt, 84)
		end
	end
)

test(
	"Art: every exported FBX matches its manifest entry and its triangle budget, counted from the file",
	function()
		if not hasManifest then
			return
		end
		for _, entry in readManifest().meshes do
			local path = `art/export/{entry.id}.fbx`
			expect.truthy(fs.isFile(path))
			local data = fs.readFile(path)
			expect.equal(#data, entry.bytes, `{entry.id} bytes`)
			expect.equal(serde.hash("sha256", data), entry.sha256, `{entry.id} sha256`)
			local geometry = Fbx.read(data)
			expect.equal(geometry.triangles, entry.triangles, `{entry.id} triangles`)
			expect.truthy(geometry.triangles <= Config.Budgets.meshTriangles[entry.tier])
		end
	end
)

test("Art: with REQUIRE_ASSET_IDS=1 every mesh and the palette have an imported id", function()
	if not requireIds then
		return
	end
	expect.truthy(hasManifest)
	expect.truthy(Assets.meshUv ~= "")
	-- ck_* ids stay "" until the owner's upload batch lands (013 hand-off); they are counted, not required.
	local pendingKit = 0
	for key, id in Assets.meshes do
		if kitKeys[key] and id == "" then
			pendingKit += 1
		else
			expect.truthy(id ~= "", `{key} has no asset id`)
		end
	end
	if pendingKit > 0 then
		print(`note: {pendingKit} city kit meshes still wait for the owner's upload`)
	end
end)

return {}
