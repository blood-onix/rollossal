--!strict
-- Out-of-sight respawn rule. Pure: no Roblox APIs, no clock, no randomness; every number is an argument.
-- Horizontal (x, z) geometry only, so a player on a rooftop still sees the street below.

export type Point = { x: number, z: number }
-- hx, hz: unit heading of the ball's horizontal velocity, or 0, 0 when it is slower than the minimum speed.
export type Watcher = { x: number, z: number, hx: number, hz: number }
export type SightParams = { radius: number, viewDistance: number, viewCos: number }

local Respawn = {}

-- `unit` is a 0..1 number the caller got from its own Random.
function Respawn.delayFrom(unit: number, minDelay: number, maxDelay: number): number
	return minDelay + math.clamp(unit, 0, 1) * (maxDelay - minDelay)
end

-- A watcher sees a point inside `radius`, or inside `viewDistance` and inside the heading cone.
function Respawn.isSeen(point: Point, watchers: { Watcher }, params: SightParams): boolean
	for _, watcher in watchers do
		local dx = point.x - watcher.x
		local dz = point.z - watcher.z
		local distance = math.sqrt(dx * dx + dz * dz)
		if distance <= params.radius then
			return true
		end
		local hasHeading = watcher.hx ~= 0 or watcher.hz ~= 0
		if hasHeading and distance <= params.viewDistance then
			local dot = (dx * watcher.hx + dz * watcher.hz) / distance
			if dot >= params.viewCos then
				return true
			end
		end
	end
	return false
end

-- The starvation ceiling beats sight: after `forceAfter` seconds the object returns even in view.
function Respawn.canRespawn(
	now: number,
	takenAt: number,
	respawnAt: number,
	point: Point,
	watchers: { Watcher },
	params: SightParams,
	forceAfter: number
): boolean
	if now >= takenAt + forceAfter then
		return true
	end
	return now >= respawnAt and not Respawn.isSeen(point, watchers, params)
end

return Respawn
