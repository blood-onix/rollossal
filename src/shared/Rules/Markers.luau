--!strict
-- Marker validation (006, data-model.md): checks the booster and trap spots of a world. Pure; the world's
-- blocks, keep-outs, extent and the footprint rows (Content/Hazards) are arguments. Returns one error string per
-- problem; an empty list means valid. Every error starts with "marker <rule>".

export type Waypoint = { x: number, z: number }

export type Marker = {
	id: string,
	kind: string,
	subKind: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	waypoints: { Waypoint }?,
}

export type Block = {
	id: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
}

export type KeepOut = { id: string, kind: string, x: number, z: number, w: number, d: number }

type Footprint = { w: number, d: number }
type Row = { subKind: string, footprint: Footprint }
export type Defs = { boosters: { Row }, traps: { Row } }

-- An axis-aligned rectangle: centre and half extents.
export type Rect = { x: number, z: number, hx: number, hz: number }

local EPSILON = 1e-6
-- A block whose top is at or under this height is ground: a marker may sit on it.
local GROUND_TOP = 0.2

local Markers = {
	-- Every sub-kind a world must carry, by marker kind.
	SUBKINDS = {
		BoosterSpot = { "dash", "magnet", "spring", "shield", "slick_trail" },
		TrapSpot = { "slick", "bumper", "slow", "sweeper" },
	} :: { [string]: { string } },
}

-- The axis-aligned box around a w x d rectangle rotated by yaw degrees.
local function rotatedBox(x: number, z: number, w: number, d: number, yaw: number): Rect
	local angle = math.rad(yaw)
	local c, s = math.abs(math.cos(angle)), math.abs(math.sin(angle))
	return { x = x, z = z, hx = (w / 2) * c + (d / 2) * s, hz = (w / 2) * s + (d / 2) * c }
end

local function overlaps(a: Rect, b: Rect): boolean
	return math.abs(a.x - b.x) < a.hx + b.hx - EPSILON
		and math.abs(a.z - b.z) < a.hz + b.hz - EPSILON
end

local function contains(outer: Rect, inner: Rect): boolean
	return math.abs(outer.x - inner.x) + inner.hx <= outer.hx + EPSILON
		and math.abs(outer.z - inner.z) + inner.hz <= outer.hz + EPSILON
end

-- The keep-out one sweeper path segment needs: the segment's box grown by half the sweeper's long side, so the
-- machine can swing round a corner without leaving it.
function Markers.segmentRect(a: Waypoint, b: Waypoint, footprint: Footprint): Rect
	local reach = footprint.w / 2
	return {
		x = (a.x + b.x) / 2,
		z = (a.z + b.z) / 2,
		hx = math.abs(b.x - a.x) / 2 + reach,
		hz = math.abs(b.z - a.z) / 2 + reach,
	}
end

local function findRow(defs: Defs, kind: string, subKind: string): Row?
	local rows: { Row } = if kind == "BoosterSpot" then defs.boosters else defs.traps
	for _, row in rows do
		if row.subKind == subKind then
			return row
		end
	end
	return nil
end

-- The path segments of a sweeper loop, the last one closing it.
local function segments(waypoints: { Waypoint }): { { Waypoint } }
	local list = {}
	for i = 1, #waypoints do
		table.insert(list, { waypoints[i], waypoints[i % #waypoints + 1] })
	end
	return list
end

local function waypointError(marker: Marker, halfExtent: number): boolean
	local waypoints = marker.waypoints
	if marker.subKind ~= "sweeper" then
		return waypoints ~= nil
	end
	if waypoints == nil or #waypoints < 3 then
		return true
	end
	for _, point in waypoints do
		if math.abs(point.x) > halfExtent or math.abs(point.z) > halfExtent then
			return true
		end
	end
	for _, pair in segments(waypoints) do
		if pair[1].x == pair[2].x and pair[1].z == pair[2].z then
			return true
		end
	end
	return false
end

-- The rectangles a marker occupies: one footprint box, or one box per path segment for a sweeper.
function Markers.footprints(marker: Marker, row: Row): { Rect }
	local waypoints = marker.waypoints
	if marker.subKind == "sweeper" and waypoints and #waypoints >= 3 then
		local rects = {}
		for _, pair in segments(waypoints) do
			table.insert(rects, Markers.segmentRect(pair[1], pair[2], row.footprint))
		end
		return rects
	end
	return {
		rotatedBox(marker.x, marker.z, row.footprint.w, row.footprint.d, marker.yaw),
	}
end

local function anyOverlap(listA: { Rect }, listB: { Rect }): boolean
	for _, a in listA do
		for _, b in listB do
			if overlaps(a, b) then
				return true
			end
		end
	end
	return false
end

local function insideWorld(rects: { Rect }, halfExtent: number): boolean
	for _, rect in rects do
		if
			math.abs(rect.x) + rect.hx > halfExtent + EPSILON
			or math.abs(rect.z) + rect.hz > halfExtent + EPSILON
		then
			return false
		end
	end
	return true
end

local function keepOutRects(keepOutAreas: { KeepOut }): { Rect }
	local rects = {}
	for _, area in keepOutAreas do
		if area.kind == "marker" then
			table.insert(rects, { x = area.x, z = area.z, hx = area.w / 2, hz = area.d / 2 })
		end
	end
	return rects
end

local function covered(need: Rect, keepOuts: { Rect }): boolean
	for _, keepOut in keepOuts do
		if contains(keepOut, need) then
			return true
		end
	end
	return false
end

-- The keep-out rectangles a marker needs: its footprint box, or one box per sweeper segment.
function Markers.requiredKeepOuts(marker: Marker, row: Row): { Rect }
	local waypoints = marker.waypoints
	if marker.subKind == "sweeper" and waypoints and #waypoints >= 3 then
		return Markers.footprints(marker, row)
	end
	return { rotatedBox(marker.x, marker.z, row.footprint.w, row.footprint.d, marker.yaw) }
end

function Markers.validate(
	markers: { Marker },
	blocks: { Block },
	keepOutAreas: { KeepOut },
	halfExtent: number,
	defs: Defs
): { string }
	local errors: { string } = {}
	local seen: { [string]: boolean } = {}
	local present: { [string]: boolean } = {}
	local placed: { { id: string, rects: { Rect } } } = {}
	local keepOuts = keepOutRects(keepOutAreas)

	local solid: { Rect } = {}
	for _, block in blocks do
		if block.cframe.y + block.size.y / 2 > GROUND_TOP then
			table.insert(
				solid,
				rotatedBox(
					block.cframe.x,
					block.cframe.z,
					block.size.x,
					block.size.z,
					block.cframe.yaw
				)
			)
		end
	end

	for _, marker in markers do
		local label = marker.id
		if marker.id == "" or seen[marker.id] then
			table.insert(errors, `marker id {label} is empty or not unique`)
		end
		seen[marker.id] = true

		if marker.kind ~= "BoosterSpot" and marker.kind ~= "TrapSpot" then
			table.insert(errors, `marker kind {label} is {marker.kind}`)
			continue
		end
		local row = findRow(defs, marker.kind, marker.subKind)
		if row == nil then
			table.insert(errors, `marker subKind {label} is {marker.subKind} for {marker.kind}`)
			continue
		end
		present[marker.subKind] = true

		if waypointError(marker, halfExtent) then
			table.insert(errors, `marker waypoints {label} has an invalid path`)
		end

		local rects = Markers.footprints(marker, row)
		if not insideWorld(rects, halfExtent) then
			table.insert(errors, `marker bounds {label} leaves the world`)
		end

		local blocked = anyOverlap(rects, solid)
		if not blocked then
			for _, other in placed do
				if anyOverlap(rects, other.rects) then
					blocked = true
					break
				end
			end
		end
		if blocked then
			table.insert(errors, `marker overlap {label} sits on a block or another marker`)
		end
		table.insert(placed, { id = marker.id, rects = rects })

		for _, need in Markers.requiredKeepOuts(marker, row) do
			if not covered(need, keepOuts) then
				table.insert(errors, `marker keepout {label} has no matching keep-out`)
				break
			end
		end
	end

	for _, kind in { "BoosterSpot", "TrapSpot" } do
		for _, subKind in Markers.SUBKINDS[kind] do
			if not present[subKind] then
				table.insert(errors, `marker coverage {kind} {subKind} is missing`)
			end
		end
	end
	return errors
end

return Markers
