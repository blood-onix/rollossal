--!strict
-- The art gate that runs without Blender (specs/004-snow-village/contracts/art-pipeline.md): the exported
-- meshes through their manifest, the asset keys, the budgets file and the hard-coded id scan. With no
-- manifest yet the mesh checks run in fallback mode and only the id scan, key coverage and budgets file apply.
-- REQUIRE_ASSET_IDS=1 also demands the manifest and every imported asset id (the final gate).

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local harness = require("./harness")
local ArtBudgets = require("../../scripts/art-budgets")
local Assets = require("../../src/shared/Assets")
local Config = require("../../src/shared/Config")
local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")

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

test("Art: the committed budgets file matches Config and the Snow Village data", function()
	expect.truthy(fs.isFile(BUDGETS))
	local committed = serde.decode("json", fs.readFile(BUDGETS))
	expect.truthy(sameValue(committed, ArtBudgets.build()))
end)

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

test("Art: Assets.meshes has one key per object asset key plus the hub, and no other", function()
	local wanted: { [string]: boolean } = { hub = true }
	for _, object in SnowVillage.objects do
		wanted[object.assetKey :: string] = true
	end
	for key in wanted do
		expect.truthy(Assets.meshes[key] ~= nil)
	end
	for key in Assets.meshes do
		expect.truthy(wanted[key])
	end
	expect.equal(SnowVillage.hub.assetKey, "hub")
end)

test(
	"Art: the manifest has one entry per object plus the hub, inside the triangle budgets",
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
		expect.equal(#manifest.meshes, #SnowVillage.objects + 1)
		for _, object in SnowVillage.objects do
			local entry = byId[object.id]
			expect.truthy(entry ~= nil)
			expect.equal(entry.tier, object.tier)
			expect.truthy(entry.triangles <= Config.Budgets.meshTriangles[object.tier])
		end
		local hub = byId.hub
		expect.truthy(hub ~= nil)
		expect.truthy(hub.triangles <= Config.Budgets.meshTriangles[#Config.Budgets.meshTriangles])
	end
)

test("Art: every manifest entry matches its exported file in size and SHA-256", function()
	if not hasManifest then
		return
	end
	for _, entry in readManifest().meshes do
		local path = `art/export/{entry.id}.fbx`
		expect.truthy(fs.isFile(path))
		local data = fs.readFile(path)
		expect.equal(#data, entry.bytes, `{entry.id} bytes`)
		expect.equal(serde.hash("sha256", data), entry.sha256, `{entry.id} sha256`)
	end
end)

test("Art: with REQUIRE_ASSET_IDS=1 every mesh and the palette have an imported id", function()
	if not requireIds then
		return
	end
	expect.truthy(hasManifest)
	expect.truthy(Assets.palette ~= "")
	for key, id in Assets.meshes do
		expect.truthy(id ~= "", `{key} has no asset id`)
	end
end)

return {}
