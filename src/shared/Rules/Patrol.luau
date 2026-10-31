--!strict
-- Closed-loop patrol kinematics (006): the sweeper's position at time t. Pure; server and clients pass the same t.

export type Point = { x: number, z: number }
export type Pose = { x: number, z: number, heading: number }

local Patrol = {}

local function segment(waypoints: { Point }, i: number): (Point, Point)
	return waypoints[i], waypoints[i % #waypoints + 1]
end

function Patrol.length(waypoints: { Point }): number
	local total = 0
	for i = 1, #waypoints do
		local a, b = segment(waypoints, i)
		total += math.sqrt((b.x - a.x) ^ 2 + (b.z - a.z) ^ 2)
	end
	return total
end

-- Heading is the direction of travel in radians, atan2(dx, dz), so 0 faces +Z.
function Patrol.position(waypoints: { Point }, speed: number, t: number): Pose
	local total = Patrol.length(waypoints)
	local first = waypoints[1]
	if total <= 0 or speed <= 0 then
		return { x = first.x, z = first.z, heading = 0 }
	end
	local travelled = (t * speed) % total
	for i = 1, #waypoints do
		local a, b = segment(waypoints, i)
		local dx, dz = b.x - a.x, b.z - a.z
		local len = math.sqrt(dx * dx + dz * dz)
		if travelled <= len and len > 0 then
			local f = travelled / len
			return { x = a.x + dx * f, z = a.z + dz * f, heading = math.atan2(dx, dz) }
		end
		travelled -= len
	end
	return { x = first.x, z = first.z, heading = 0 }
end

return Patrol
