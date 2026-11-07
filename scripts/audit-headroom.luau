--!strict
-- Prints the winter city's triangle totals as JSON, summed the way tests/unit/Downtown.test.luau N10 does (manifest
-- triangles per placement; tier 4 and 5 count as culled). Read by art/scripts/audit_report.py (013 audit headroom).
--   lune run scripts/audit-headroom

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Config = require("../src/shared/Config")
local Downtown = require("../src/shared/Content/Worlds/Downtown")
local Layout = require("../src/shared/Rules/Layout")
local ThemeResolve = require("../src/shared/Rules/ThemeResolve")
local Themes = require("../src/shared/Content/Themes")

local manifest = serde.decode("json", fs.readFile("art/export/manifest.json"))
local triangles: { [string]: number } = {}
for _, mesh in manifest.meshes do
	triangles[mesh.id] = mesh.triangles
end

local theme = (Themes :: any).winter
local resolved = ThemeResolve.resolve(
	Downtown,
	{ id = "winter", palette = theme.palette, lighting = theme.lighting },
	Layout.expand,
	Config.Budgets.defaultMaxPlacements
)
local byId: { [string]: any } = {}
for _, object in resolved.objects do
	byId[object.id] = object
end

local total, culled = 0, 0
local placed: { [string]: number } = {}
for _, placement in resolved.placements do
	local object = byId[placement.objectId]
	local key = object.assetKey :: string
	local count = triangles[key]
	assert(count ~= nil, `no manifest row for {key}`)
	total += count
	placed[key] = (placed[key] or 0) + 1
	if object.tier >= 4 then
		culled += count
	end
end

print(serde.encode("json", { unculled = total, culled = culled, placements = placed }, false))
