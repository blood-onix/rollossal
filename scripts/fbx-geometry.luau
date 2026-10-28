--!strict
-- Reads the mesh geometry out of a binary FBX 7.x file (the Blender export): the triangle count and the vertex
-- bounds, straight from the bytes, so a budget check does not have to trust manifest.json.

local serde = require("@lune/serde")

export type Geometry = {
	triangles: number,
	minimum: vector,
	maximum: vector,
}

type Node = { name: string, values: { any }, children: { Node } }

local HEADER_SIZE = 27
local NULL_RECORD_SIZE = 13

local function elementWidth(code: string): number
	if code == "d" or code == "l" then
		return 8
	elseif code == "b" or code == "c" then
		return 1
	end
	return 4
end

local function readArray(data: buffer, at: number, code: string): ({ any }, number)
	local count = buffer.readu32(data, at)
	local encoding = buffer.readu32(data, at + 4)
	local byteLength = buffer.readu32(data, at + 8)
	local width = elementWidth(code)
	local start = at + 12
	local stored = if encoding == 1 then byteLength else count * width
	local raw = buffer.readstring(data, start, stored)
	local values = buffer.fromstring(if encoding == 1 then serde.decompress("zlib", raw) else raw)
	local out = {}
	for index = 0, count - 1 do
		local offset = index * width
		local value: number
		if code == "d" then
			value = buffer.readf64(values, offset)
		elseif code == "f" then
			value = buffer.readf32(values, offset)
		elseif code == "i" or code == "l" then
			value = buffer.readi32(values, offset)
		else
			value = buffer.readu8(values, offset)
		end
		table.insert(out, value)
	end
	return out, start + stored
end

local function readValue(data: buffer, at: number, code: string): (any, number)
	if code == "Y" then
		return buffer.readi16(data, at), at + 2
	elseif code == "C" then
		return buffer.readu8(data, at), at + 1
	elseif code == "I" then
		return buffer.readi32(data, at), at + 4
	elseif code == "F" then
		return buffer.readf32(data, at), at + 4
	elseif code == "D" then
		return buffer.readf64(data, at), at + 8
	elseif code == "L" then
		return buffer.readi32(data, at), at + 8
	elseif code == "S" or code == "R" then
		local length = buffer.readu32(data, at)
		return buffer.readstring(data, at + 4, length), at + 4 + length
	end
	return readArray(data, at, code)
end

local function readNode(data: buffer, at: number): (Node?, number)
	local endOffset = buffer.readu32(data, at)
	if endOffset == 0 then
		return nil, at + NULL_RECORD_SIZE
	end
	local propertyCount = buffer.readu32(data, at + 4)
	local nameLength = buffer.readu8(data, at + 12)
	local node: Node = {
		name = buffer.readstring(data, at + 13, nameLength),
		values = {},
		children = {},
	}
	local cursor = at + 13 + nameLength
	for _ = 1, propertyCount do
		local code = buffer.readstring(data, cursor, 1)
		local value
		value, cursor = readValue(data, cursor + 1, code)
		table.insert(node.values, value)
	end
	while cursor < endOffset do
		local child
		child, cursor = readNode(data, cursor)
		if child == nil then
			break
		end
		table.insert(node.children, child)
	end
	return node, endOffset
end

local function findChild(node: Node, name: string): Node?
	for _, child in node.children do
		if child.name == name then
			return child
		end
	end
	return nil
end

local function collectGeometry(node: Node, found: { Node })
	if
		node.name == "Geometry"
		and findChild(node, "Vertices")
		and findChild(node, "PolygonVertexIndex")
	then
		table.insert(found, node)
	end
	for _, child in node.children do
		collectGeometry(child, found)
	end
end

local function read(bytes: string): Geometry
	assert(string.sub(bytes, 1, 20) == "Kaydara FBX Binary  ", "not a binary FBX file")
	local data = buffer.fromstring(bytes)
	local roots: { Node } = {}
	local cursor = HEADER_SIZE
	while true do
		local node
		node, cursor = readNode(data, cursor)
		if node == nil then
			break
		end
		table.insert(roots, node)
	end

	local geometries: { Node } = {}
	for _, root in roots do
		collectGeometry(root, geometries)
	end
	assert(#geometries == 1, `expected one Geometry node, found {#geometries}`)
	local geometry = geometries[1]

	local vertices = (findChild(geometry, "Vertices") :: Node).values[1] :: { number }
	local indices = (findChild(geometry, "PolygonVertexIndex") :: Node).values[1] :: { number }

	local triangles = 0
	local corners = 0
	for _, index in indices do
		corners += 1
		if index < 0 then
			if corners >= 3 then
				triangles += corners - 2
			end
			corners = 0
		end
	end

	local low = vector.create(math.huge, math.huge, math.huge)
	local high = vector.create(-math.huge, -math.huge, -math.huge)
	for index = 1, #vertices, 3 do
		local x, y, z = vertices[index], vertices[index + 1], vertices[index + 2]
		low = vector.create(math.min(low.x, x), math.min(low.y, y), math.min(low.z, z))
		high = vector.create(math.max(high.x, x), math.max(high.y, y), math.max(high.z, z))
	end

	return { triangles = triangles, minimum = low, maximum = high }
end

return { read = read }
