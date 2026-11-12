--!strict
-- What the map's toys do to a ball: boost, bounce and spring pads, catapults, rails and pipes.
-- Pure: positions, gravity and tuning are arguments. Yaw follows the layout file: 0 = north (-z), 90 = east (+x).

export type Vec3 = { x: number, y: number, z: number }
export type Pad = { x: number, y: number, z: number, yaw: number, size: { number } }
export type Arc = { vx: number, vy: number, vz: number, seconds: number }
export type PathHit = { along: number, distance: number, tx: number, ty: number, tz: number }
export type Giant = { x: number, z: number, need: number, hidden: boolean? }

local Toys = {}

local LEAVING = 0.3

function Toys.direction(yawDegrees: number): (number, number)
	local yaw = math.rad(yawDegrees)
	return math.sin(yaw), -math.cos(yaw)
end

-- Whether the ball stands on the pad. The footprint turns with the pad's own yaw, as the drawn Part does; the bottom
-- of the ball has to be within verticalReach of the pad, so rolling into a raised cap still counts.
function Toys.onPad(ball: Vec3, diameter: number, pad: Pad, verticalReach: number): boolean
	local radius = diameter / 2
	if math.abs(ball.y - radius - pad.y) > verticalReach then
		return false
	end
	local yaw = math.rad(pad.yaw)
	local cosine, sine = math.cos(yaw), math.sin(yaw)
	local dx, dz = ball.x - pad.x, ball.z - pad.z
	local margin = 0.5 + radius * 0.3
	return math.abs(cosine * dx - sine * dz) <= pad.size[1] / 2 + margin
		and math.abs(sine * dx + cosine * dz) <= pad.size[2] / 2 + margin
end

-- Upward speed that lifts the ball by `apex` studs.
function Toys.apexSpeed(apex: number, gravity: number): number
	return math.sqrt(2 * gravity * math.max(apex, 0))
end

-- The launch that peaks `apex` studs above the higher end and comes down at `to`.
function Toys.arc(from: Vec3, to: Vec3, apex: number, gravity: number): Arc
	local top = math.max(from.y, to.y) + apex
	local vy = math.sqrt(2 * gravity * (top - from.y))
	local seconds = vy / gravity + math.sqrt(2 * (top - to.y) / gravity)
	return {
		vx = (to.x - from.x) / seconds,
		vy = vy,
		vz = (to.z - from.z) / seconds,
		seconds = seconds,
	}
end

function Toys.pathLength(points: { { number } }): number
	local total = 0
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		total += math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2)
	end
	return total
end

-- The closest point of a polyline to `at`: how far along it lies, how far away it is, and the path's direction there.
function Toys.nearestOnPath(points: { { number } }, at: Vec3): PathHit
	local best: PathHit = { along = 0, distance = math.huge, tx = 0, ty = 0, tz = 1 }
	local walked = 0
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local ex, ey, ez = b[1] - a[1], b[2] - a[2], b[3] - a[3]
		local lengthSquared = ex * ex + ey * ey + ez * ez
		local length = math.sqrt(lengthSquared)
		if length > 0 then
			local px, py, pz = at.x - a[1], at.y - a[2], at.z - a[3]
			local f = math.clamp((px * ex + py * ey + pz * ez) / lengthSquared, 0, 1)
			local dx, dy, dz = px - ex * f, py - ey * f, pz - ez * f
			local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
			if distance < best.distance then
				best = {
					along = walked + length * f,
					distance = distance,
					tx = ex / length,
					ty = ey / length,
					tz = ez / length,
				}
			end
			walked += length
		end
	end
	return best
end

-- The point `along` studs down the polyline (clamped to its ends) and the direction there.
function Toys.pointAt(
	points: { { number } },
	along: number
): (number, number, number, number, number, number)
	local remaining = math.max(along, 0)
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local ex, ey, ez = b[1] - a[1], b[2] - a[2], b[3] - a[3]
		local length = math.sqrt(ex * ex + ey * ey + ez * ez)
		if length > 0 and (remaining <= length or index == #points - 1) then
			local f = math.min(remaining / length, 1)
			return a[1] + ex * f,
				a[2] + ey * f,
				a[3] + ez * f,
				ex / length,
				ey / length,
				ez / length
		end
		remaining -= length
	end
	local last = points[#points]
	return last[1], last[2], last[3], 0, 0, 1
end

-- A rail is caught near either end, or anywhere along it when the ball is already rolling with it, so crossing a
-- track at right angles leaves the ball alone. Returns the direction to ride (1 or -1), or nil for no catch.
function Toys.railCatch(
	hit: PathHit,
	length: number,
	vx: number,
	vz: number,
	endReach: number,
	alignment: number
): number?
	local flat = math.sqrt(vx * vx + vz * vz)
	local tangentFlat = math.sqrt(hit.tx * hit.tx + hit.tz * hit.tz)
	local along = 0
	if flat > 1e-3 and tangentFlat > 1e-3 then
		along = (vx * hit.tx + vz * hit.tz) / (flat * tangentFlat)
	end
	if math.abs(along) >= alignment then
		return if along >= 0 then 1 else -1
	end
	-- At an end the ball may come in from any side, but one rolling away from the rail is left alone.
	if hit.along <= endReach and along > -LEAVING then
		return 1
	end
	if length - hit.along <= endReach and along < LEAVING then
		return -1
	end
	return nil
end

-- A rail over the ball's head is not for catching: a big ball on the street must not be snatched up to a roof.
function Toys.railAtBallLevel(
	railY: number,
	ballY: number,
	diameter: number,
	limit: number
): boolean
	return railY - (ballY - diameter / 2) <= limit
end

-- How far a size-tier jump reaches: with the ball's size, but never a whole street.
function Toys.vacuumRadius(diameter: number, floor: number, factor: number, ceiling: number): number
	return math.min(ceiling, math.max(floor, factor * diameter))
end

-- Which giants to point out to a ball: the nearest ones it can eat now and the smallest ones still out of reach.
function Toys.pickGoals(
	giants: { Giant },
	diameter: number,
	x: number,
	z: number,
	edibleCount: number,
	aheadCount: number
): { Giant }
	local edible: { Giant }, ahead: { Giant } = {}, {}
	for _, giant in giants do
		if not giant.hidden then
			table.insert(if giant.need <= diameter then edible else ahead, giant)
		end
	end
	local function distance(giant: Giant): number
		return (giant.x - x) ^ 2 + (giant.z - z) ^ 2
	end
	table.sort(edible, function(a, b)
		return distance(a) < distance(b)
	end)
	table.sort(ahead, function(a, b)
		if a.need ~= b.need then
			return a.need < b.need
		end
		return distance(a) < distance(b)
	end)
	local picked: { Giant } = {}
	for index = 1, math.min(edibleCount, #edible) do
		table.insert(picked, edible[index])
	end
	for index = 1, math.min(aheadCount, #ahead) do
		table.insert(picked, ahead[index])
	end
	return picked
end

return Toys
