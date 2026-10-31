--!strict
-- Booster rules (006): flags, durations, magnet pick, slick-trail spacing and expiry, dash target speed.
-- Pure: time, positions and tuning are arguments.

export type Vec3 = { x: number, y: number, z: number }

export type MagnetCandidate = {
	id: string,
	pos: Vec3,
	size: number,
	available: boolean,
}

export type MagnetTuning = {
	absorbRatio: number,
	radiusFactor: number,
	maxPulled: number,
}

local FLAG_BY_SUBKIND: { [string]: string } = {
	dash = "BoosterDash",
	magnet = "BoosterMagnet",
	spring = "BoosterSpring",
	shield = "BoosterShield",
	slick_trail = "BoosterSlickTrail",
}

local Boosters = {}

-- A booster is live only when the master flag and its own flag are both true.
function Boosters.enabled(flags: { [string]: boolean }, subKind: string): boolean
	local own = FLAG_BY_SUBKIND[subKind]
	return own ~= nil and flags.Boosters == true and flags[own] == true
end

function Boosters.endsAt(now: number, duration: number): number
	return now + duration
end

function Boosters.isActive(now: number, until_: number): boolean
	return now < until_
end

-- Ids of at most maxPulled eligible parts, nearest first. Eligible: available, small enough to absorb, and
-- inside radiusFactor x diameter of the ball.
function Boosters.magnetPick(
	ballPos: Vec3,
	diameter: number,
	candidates: { MagnetCandidate },
	p: MagnetTuning
): { string }
	local reach = p.radiusFactor * diameter
	local limit = p.absorbRatio * diameter
	local found: { { id: string, distance: number } } = {}
	for _, candidate in candidates do
		if not candidate.available or candidate.size > limit then
			continue
		end
		local dx = candidate.pos.x - ballPos.x
		local dy = candidate.pos.y - ballPos.y
		local dz = candidate.pos.z - ballPos.z
		local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
		if distance <= reach then
			table.insert(found, { id = candidate.id, distance = distance })
		end
	end
	table.sort(found, function(a, b)
		if a.distance ~= b.distance then
			return a.distance < b.distance
		end
		return a.id < b.id
	end)
	local ids: { string } = {}
	for i = 1, math.min(#found, p.maxPulled) do
		table.insert(ids, found[i].id)
	end
	return ids
end

-- A slick-trail patch is dropped each time the ball has travelled spacing studs since the last one.
function Boosters.shouldDrop(travelled: number, spacing: number): boolean
	return travelled >= spacing
end

function Boosters.trailExpire(now: number, droppedAt: number, lifetime: number): boolean
	return now - droppedAt >= lifetime
end

-- Whether a ball can claim a booster marker. Marker y is ground level and the ball centre sits D/2 above it, so
-- the vertical term is the gap under the ball (not the centre height): a big ball rolling on the ground has gap 0
-- and reaches the same flat distance at any size. Client and server share this and differ only in `margin`.
function Boosters.inClaimReach(
	ball: Vec3,
	diameter: number,
	marker: Vec3,
	boosterRadius: number,
	margin: number
): boolean
	local dx = ball.x - marker.x
	local dz = ball.z - marker.z
	local gap = math.max(0, ball.y - diameter / 2 - marker.y)
	local reach = diameter / 2 + boosterRadius + margin
	return dx * dx + dz * dz + gap * gap <= reach * reach
end

function Boosters.dashTarget(baseSpeed: number, multiplier: number, cap: number): number
	return math.min(baseSpeed * multiplier, cap)
end

return Boosters
