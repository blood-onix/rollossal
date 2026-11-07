--!strict
-- Park City for the offline Blender renderer (012 T039, research R6): the world data as boxes in one deterministic JSON
-- file. capture-export.luau is written for Downtown's data shape (zones, themes, atlas meshes), and drawing light
-- rows and placeholders there needs more than its 60 lines, so this is the second small script research R6 names.
-- Everything is a grey-box box by dims. Run from the repo root:
--   lune run scripts/park-capture-export -- --out art/render/world-parkcity.json

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local ParkCity = require("../src/shared/Content/Worlds/ParkCity")
local Parts = require("../src/shared/Content/Worlds/ParkCityParts")
local LightData = require("../src/shared/Content/Worlds/ParkCityLight")

local outPath = "art/render/world-parkcity.json"
local index = if process.args[1] == "--" then 2 else 1
while index <= #process.args do
	if process.args[index] == "--out" and process.args[index + 1] ~= nil then
		outPath = process.args[index + 1]
	else
		stdio.ewrite(`park-capture-export: unknown or incomplete argument {process.args[index]}\n`)
		process.exit(1)
	end
	index += 2
end

local TIER_COLOURS = {
	{ 240, 210, 80 },
	{ 240, 150, 60 },
	{ 220, 70, 70 },
	{ 160, 90, 200 },
	{ 80, 130, 230 },
	{ 40, 40, 50 },
}
local objectById: { [string]: any } = {}
for _, object in ParkCity.objects do
	objectById[object.id] = object
end

-- Box record: centre (Roblox axes), sizes (Roblox: x, y up, z), yaw (Blender-sense, radians about up), rx (pitch about
-- the box's own long Z axis tilt, radians), wedge flag, colour.
local boxes: { any } = {}
local function box(
	id: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	yaw: number,
	rgb: { number },
	extra: { [string]: any }?
)
	local record: { [string]: any } = {
		id = id,
		x = x,
		y = y,
		z = z,
		sx = sx,
		sy = sy,
		sz = sz,
		yaw = yaw,
		rgb = rgb,
	}
	for key, value in extra or {} do
		record[key] = value
	end
	table.insert(boxes, record)
end

local palette = ParkCity.environment.palette
for _, block in ParkCity.environment.blocks do
	local at, size = block.cframe, block.size
	if block.kind == "Boundary" then
		continue
	elseif block.kind == "Spiral" then
		local steps = math.floor(block.turns * 16 + 0.5)
		local outer = math.min(size.x, size.z) / 2
		local radius = outer - block.width / 2
		local bottom = at.y - size.y / 2
		local function point(step: number): { number }
			local angle = step / 16 * math.pi * 2
			return {
				at.x + math.cos(angle) * radius,
				bottom + size.y * step / steps,
				at.z + math.sin(angle) * radius,
			}
		end
		for step = 0, steps - 1 do
			local from, to = point(step), point(step + 1)
			local dx, dy, dz = to[1] - from[1], to[2] - from[2], to[3] - from[3]
			local flat = math.sqrt(dx * dx + dz * dz)
			-- Blender axes: (x, -z, y). Its +Y direction is (dx, -dz); yaw alpha maps +Y to it.
			box(
				`{block.id}_{step + 1}`,
				(from[1] + to[1]) / 2,
				(from[2] + to[2]) / 2 - 0.4,
				(from[3] + to[3]) / 2,
				block.width,
				0.8,
				math.sqrt(flat * flat + dy * dy) * 1.08,
				math.atan2(-dx, -dz),
				palette[block.swatch],
				{ rx = math.atan2(dy, flat) }
			)
		end
	else
		box(
			block.id,
			at.x,
			at.y,
			at.z,
			size.x,
			size.y,
			size.z,
			math.rad(at.yaw),
			palette[block.swatch],
			{ wedge = if block.kind == "Wedge" then true else nil }
		)
	end
end

local function item(id: string, kind: string, x: number, y: number, z: number, yaw: number)
	local object = objectById[kind]
	local dims = object.dims
	box(id, x, y + dims[3] / 2, z, dims[1], dims[3], dims[2], yaw, TIER_COLOURS[object.tier], nil)
end
for _, row in Parts do
	item(row.id, row.objectId, row.x, row.y, row.z, row.yaw)
end
for row = 1, LightData.count do
	local at = (row - 1) * LightData.stride
	item(
		`L{row}`,
		LightData.kinds[LightData.data[at + 1]],
		LightData.data[at + 2],
		LightData.data[at + 3],
		LightData.data[at + 4],
		LightData.data[at + 5]
	)
end

-- Placeholders, drawn like WorldBuilder does, simplified to boxes.
local PAD = {
	boost = { 255, 160, 40 },
	bounce = { 90, 200, 110 },
	spring = { 70, 140, 235 },
	bullseye = { 230, 60, 60 },
	platform = { 70, 170, 90 },
}
for _, placeholder in ParkCity.placeholders do
	local kind: string = placeholder.kind
	if kind == "rail" then
		local points = placeholder.points
		for step = 1, #points - 1 do
			local a, b = points[step], points[step + 1]
			local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
			local flat = math.sqrt(dx * dx + dz * dz)
			box(
				`{placeholder.id}_{step}`,
				(a[1] + b[1]) / 2,
				(a[2] + b[2]) / 2,
				(a[3] + b[3]) / 2,
				0.6,
				0.6,
				math.sqrt(flat * flat + dy * dy),
				math.atan2(-dx, -dz),
				{ 255, 120, 200 },
				{ rx = math.atan2(dy, flat) }
			)
		end
	elseif kind == "pipe" then
		for _, point in { placeholder.points[1], placeholder.points[#placeholder.points] } do
			box(placeholder.id, point[1], 2, point[3], 4, 4, 4, 0, { 90, 120, 150 })
		end
	elseif PAD[kind] then
		local size = placeholder.size
		box(
			placeholder.id,
			placeholder.x,
			placeholder.y - 0.2,
			placeholder.z,
			size[1],
			0.4,
			size[2],
			math.rad(placeholder.yaw),
			PAD[kind]
		)
	elseif kind == "catapult" or kind == "big_slingshot" then
		local scale = if kind == "big_slingshot" then 2 else 1
		box(
			placeholder.id,
			placeholder.x,
			0.75 * scale,
			placeholder.z,
			4 * scale,
			1.5 * scale,
			4 * scale,
			0,
			{ 140, 100, 60 }
		)
	else
		local rgb = if kind == "slick" then { 150, 200, 230 } else { 70, 140, 200 }
		if placeholder.ellipse then
			local e = placeholder.ellipse
			box(placeholder.id, e[1], 0.1, e[2], e[3] * 2, 0.05, e[4] * 2, 0, rgb)
		else
			local r = placeholder.rect
			box(
				placeholder.id,
				(r[1] + r[3]) / 2,
				0.1,
				(r[2] + r[4]) / 2,
				r[3] - r[1],
				0.05,
				r[4] - r[2],
				0,
				rgb
			)
		end
	end
end

local function number(value: number): string
	local text = string.format("%.3f", value)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
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
		for _, entry in value do
			table.insert(parts, inner .. encode(entry, inner))
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

local shots = {}
for _, shot in ParkCity.shots do
	table.insert(
		shots,
		{ name = shot.name, position = shot.pos, lookAt = shot.look, fov = shot.fov }
	)
end

local dir = string.match(outPath, "^(.*)/[^/]+$")
if dir ~= nil and dir ~= "" then
	fs.writeDir(dir)
end
fs.writeFile(outPath, encode({ world = "park_city", boxes = boxes, shots = shots }, "") .. "\n")
print(`wrote {outPath}: {#boxes} boxes, {#shots} shots`)
