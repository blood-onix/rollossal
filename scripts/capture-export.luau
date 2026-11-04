--!strict
-- Resolves the Downtown world (or, with --world slice, the 010 Main-Street slice) for one theme into a deterministic JSON file for the offline Blender renderer
-- (specs/009-style-bible-bakeoff/contracts/capture-route.md). Run from the repo root:
--   lune run scripts/capture-export -- --theme city --out art/render/world-city.json
--   lune run scripts/capture-export -- --world slice --out art/render/world-slice.json
-- With --world slice the theme is city and the shots are art/capture/cameras-slice.json.

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local Config = require("../src/shared/Config")
local DowntownWorld = require("../src/shared/Content/Worlds/Downtown")
local MainStreetSlice = require("../src/shared/Content/Worlds/MainStreetSlice")
local SceneKit = require("../src/shared/Rules/SceneKit")
local SceneKits = require("../src/shared/Content/SceneKits")
local Signs = require("../src/shared/Content/Signs")
local StreetRules = require("../src/shared/Rules/StreetRules")
local Layout = require("../src/shared/Rules/Layout")
local ThemeResolve = require("../src/shared/Rules/ThemeResolve")
local Themes = require("../src/shared/Content/Themes")

local function fail(message: string): never
	stdio.ewrite(`capture-export: {message}\n`)
	process.exit(1)
end

local themeId = "city"
local worldName = "downtown"
local outPath: string? = nil
local index = if process.args[1] == "--" then 2 else 1
while index <= #process.args do
	local flag = process.args[index]
	local value = process.args[index + 1]
	if flag == "--theme" and value ~= nil then
		themeId = value
	elseif flag == "--world" and (value == "slice" or value == "downtown") then
		worldName = value
	elseif flag == "--out" and value ~= nil then
		outPath = value
	else
		fail(`unknown or incomplete argument {flag}`)
	end
	index += 2
end
local output = outPath
	or (
		if worldName == "slice"
			then "art/render/world-slice.json"
			else `art/render/world-{themeId}.json`
	)

-- The world under export: Downtown as written, or the slice built from the same pure rules the game uses.
local Downtown: any = if worldName == "slice"
	then MainStreetSlice.build({
		StreetRules = StreetRules,
		SceneKit = SceneKit,
		SceneKits = SceneKits,
		Signs = Signs,
		Downtown = DowntownWorld,
	})
	else DowntownWorld

local theme = (Themes :: any)[themeId]
if theme == nil then
	fail(`unknown theme {themeId}`)
end

local ok, resolvedOrError = pcall(
	ThemeResolve.resolve,
	Downtown,
	{ id = themeId, palette = theme.palette, lighting = theme.lighting },
	Layout.expand,
	Config.Budgets.defaultMaxPlacements
)
if not ok then
	fail(`world did not resolve for {themeId}: {resolvedOrError}`)
end
local resolved: ThemeResolve.Resolved = resolvedOrError :: any

-- Minimal JSON writer: sorted keys, numbers at three decimals, so two runs give identical bytes.
local function number(value: number): string
	local text = string.format("%.3f", value)
	if string.find(text, ".", 1, true) ~= nil then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	if text == "-0" or text == "" then
		return "0"
	end
	return text
end

local function encode(value: any, indent: string): string
	local kind = type(value)
	if kind == "number" then
		return number(value)
	elseif kind == "string" then
		return `"{value}"`
	elseif kind == "boolean" then
		return tostring(value)
	end
	local inner = indent .. "  "
	local parts = {}
	if #value > 0 then
		for _, item in value do
			table.insert(parts, inner .. encode(item, inner))
		end
		return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
	end
	local keys = {}
	for key in value do
		table.insert(keys, key)
	end
	table.sort(keys)
	if #keys == 0 then
		return "[]"
	end
	for _, key in keys do
		table.insert(parts, `{inner}"{key}": {encode(value[key], inner)}`)
	end
	return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

local function rgb(swatch: string): { number }
	local colour = Downtown.environment.palette[swatch] or theme.palette[swatch]
	if colour == nil then
		fail(`swatch {swatch} is in neither the world palette nor the {themeId} palette`)
	end
	return colour
end

local blocks = {}
local function addBlocks(list: { any }?)
	for _, item in list or {} do
		if item.kind ~= "Boundary" then
			table.insert(blocks, {
				id = item.id,
				kind = item.kind,
				x = item.cframe.x,
				y = item.cframe.y,
				z = item.cframe.z,
				yaw = item.cframe.yaw,
				sx = item.size.x,
				sy = item.size.y,
				sz = item.size.z,
				rgb = rgb(item.swatch),
			})
		end
	end
end
addBlocks(Downtown.environment.blocks)
local binding = (Downtown.themeBindings :: any)[themeId]
if binding == nil then
	fail(`world {Downtown.worldId} has no binding for theme {themeId}`)
end
addBlocks(binding.blocks)

local objectById: { [string]: ThemeResolve.ObjectLike } = {}
for _, object in resolved.objects do
	objectById[object.id] = object
end

local placements = {}
for _, placement in resolved.placements do
	local object = objectById[placement.objectId]
	if object == nil then
		fail(`placement {placement.id} uses unknown object {placement.objectId}`)
	end
	table.insert(placements, {
		id = placement.id,
		objectId = placement.objectId,
		assetKey = object.assetKey or `dt_{object.id}`,
		x = placement.x,
		y = placement.y,
		z = placement.z,
		yaw = placement.yaw,
		size = object.size,
		fallback = object.fallback or "Block",
	})
end

local spawns = {}
for _, spawn in Downtown.spawnPoints do
	table.insert(spawns, { slot = spawn.slot, x = spawn.x, z = spawn.z, yaw = spawn.yaw })
end

local function sortBy(list: { any }, key: string)
	table.sort(list, function(a, b)
		return a[key] < b[key]
	end)
end
sortBy(blocks, "id")
sortBy(placements, "id")
sortBy(spawns, "slot")

local dir = string.match(output, "^(.*)/[^/]+$")
if dir ~= nil and dir ~= "" then
	fs.writeDir(dir)
end
fs.writeFile(output, encode({
	theme = themeId,
	world = Downtown.worldId,
	blocks = blocks,
	placements = placements,
	spawns = spawns,
}, "") .. "\n")
print(`wrote {output}: {#blocks} blocks, {#placements} placements, {#spawns} spawns`)
