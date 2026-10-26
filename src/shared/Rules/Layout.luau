--!strict
-- Seeded zone expander: turns hand-authored zones into pooled-object placements.
-- Pure: no Roblox APIs, no clock, no randomness. Uses its own Park-Miller generator, exact in doubles.

export type MixEntry = { objectId: string, weight: number }
export type Zone = {
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	mix: { MixEntry },
	count: number,
	seed: number,
	spawnSlot: number?,
}
export type Placement = {
	id: string,
	objectId: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	spawnSlot: number?,
}

local MULTIPLIER = 48271
local MODULUS = 2147483647
local CELL_MARGIN = 1.2

local Layout = {}

-- 1.2 * the largest size among the objectIds in the zone's mix.
function Layout.cellEdge(zone: Zone, sizes: { [string]: number }): number
	local largest = 0
	for _, entry in zone.mix do
		local size = sizes[entry.objectId]
		if size == nil then
			error(`Layout: zone {zone.id} names unknown object {entry.objectId}`)
		end
		largest = math.max(largest, size)
	end
	return CELL_MARGIN * largest
end

local function gridSize(zone: Zone, edge: number): (number, number)
	return math.floor(zone.w / edge), math.floor(zone.d / edge)
end

function Layout.capacity(zone: Zone, sizes: { [string]: number }): number
	local columns, rows = gridSize(zone, Layout.cellEdge(zone, sizes))
	return columns * rows
end

-- One generator step on a state in 1 .. 2147483646.
function Layout.next(state: number): number
	return state * MULTIPLIER % MODULUS
end

-- Makes any whole-number seed a valid generator state.
function Layout.normaliseSeed(seed: number): number
	return seed % (MODULUS - 1) + 1
end

local function pickObject(mix: { MixEntry }, unit: number): string
	local total = 0
	for _, entry in mix do
		total += entry.weight
	end
	local target = unit * total
	local running = 0
	for _, entry in mix do
		running += entry.weight
		if target < running then
			return entry.objectId
		end
	end
	return mix[#mix].objectId
end

local function expandZone(zone: Zone, sizes: { [string]: number }, into: { Placement })
	local edge = Layout.cellEdge(zone, sizes)
	local columns, rows = gridSize(zone, edge)
	local cells = columns * rows
	if zone.count > cells then
		error(`Layout: zone {zone.id} wants {zone.count} objects but holds {cells}`)
	end

	local state = Layout.normaliseSeed(zone.seed)
	local order = table.create(cells)
	for i = 1, cells do
		order[i] = i - 1
	end
	-- Fisher-Yates over the row-major cell indices.
	for i = cells, 2, -1 do
		state = Layout.next(state)
		local j = state % i + 1
		order[i], order[j] = order[j], order[i]
	end

	local originX = zone.x - columns * edge / 2
	local originZ = zone.z - rows * edge / 2
	for index = 1, zone.count do
		local cell = order[index]
		local column = cell % columns
		local row = cell // columns

		state = Layout.next(state)
		local unitX = state / MODULUS
		state = Layout.next(state)
		local unitZ = state / MODULUS
		state = Layout.next(state)
		local objectId = pickObject(zone.mix, state / MODULUS)
		state = Layout.next(state)
		local yaw = math.rad(state % 360)

		local slack = (edge - sizes[objectId]) / 2
		table.insert(into, {
			id = string.format("%s_%03d", zone.id, index),
			objectId = objectId,
			x = originX + (column + 0.5) * edge + (unitX * 2 - 1) * slack,
			y = zone.y,
			z = originZ + (row + 0.5) * edge + (unitZ * 2 - 1) * slack,
			yaw = yaw,
			spawnSlot = zone.spawnSlot,
		})
	end
end

-- Zones are expanded in order; each zone owns its seed, so editing one zone moves only its objects.
function Layout.expand(zones: { Zone }, sizes: { [string]: number }): { Placement }
	local placements: { Placement } = {}
	for _, zone in zones do
		expandZone(zone, sizes, placements)
	end
	return placements
end

return Layout
