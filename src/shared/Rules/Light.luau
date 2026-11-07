--!strict
-- Light objects (Park City Tiers 1 and 2): a grid over the flat position data for the client's draw query, the
-- server's absorb verdict, and the id check. Pure: no Roblox APIs, no clock, no randomness.
-- Row i of `data` (stride numbers: kind index, x, y, z, yaw) is the light id "L"..i.

export type Grid = { cell: number, cells: { [number]: { number } } }

export type Verdict = "Ok" | "UnknownObject" | "AlreadyTaken" | "OutOfRange" | "TooBig"

export type VerdictInput = {
	exists: boolean,
	taken: boolean,
	-- Distance from the ball to the object's data position.
	distance: number,
	ballRadius: number,
	size: number,
	tolerance: number,
	-- The world's absorb rule for this ball and object (Absorb.canEat with the ball's diameter and the object's dims).
	edible: boolean,
}

local Light = {}

local OFFSET = 512
local WIDTH = 1024

local function cellKey(cx: number, cz: number): number
	return (cx + OFFSET) * WIDTH + (cz + OFFSET)
end

function Light.buildGrid(data: { number }, stride: number, count: number, cell: number): Grid
	local cells: { [number]: { number } } = {}
	for index = 1, count do
		local at = (index - 1) * stride
		local key = cellKey(math.floor(data[at + 2] / cell), math.floor(data[at + 4] / cell))
		local list = cells[key]
		if list == nil then
			list = {}
			cells[key] = list
		end
		table.insert(list, index)
	end
	return { cell = cell, cells = cells }
end

-- Indices within `radius` studs (flat) of (x, z).
function Light.query(
	grid: Grid,
	data: { number },
	stride: number,
	x: number,
	z: number,
	radius: number
): { number }
	local found: { number } = {}
	local limit = radius * radius
	local cell = grid.cell
	for cx = math.floor((x - radius) / cell), math.floor((x + radius) / cell) do
		for cz = math.floor((z - radius) / cell), math.floor((z + radius) / cell) do
			local list = grid.cells[cellKey(cx, cz)]
			if list then
				for _, index in list do
					local at = (index - 1) * stride
					local dx, dz = data[at + 2] - x, data[at + 4] - z
					if dx * dx + dz * dz <= limit then
						table.insert(found, index)
					end
				end
			end
		end
	end
	return found
end

-- The index of a light id, or nil: only "L" followed by plain digits, no leading zero, within 1..count.
function Light.parseId(id: unknown, count: number): number?
	if typeof(id) ~= "string" then
		return nil
	end
	local digits = string.match(id, "^L(%d+)$")
	if digits == nil or string.sub(digits, 1, 1) == "0" or #digits > 7 then
		return nil
	end
	local index = tonumber(digits)
	if index == nil or index < 1 or index > count then
		return nil
	end
	return index
end

-- Server verdict for one claim, from data only. The rate limit is checked by the caller.
function Light.verdict(input: VerdictInput): Verdict
	if not input.exists then
		return "UnknownObject"
	end
	if input.taken then
		return "AlreadyTaken"
	end
	if input.distance > input.ballRadius + input.size / 2 + input.tolerance then
		return "OutOfRange"
	end
	if not input.edible then
		return "TooBig"
	end
	return "Ok"
end

return Light
