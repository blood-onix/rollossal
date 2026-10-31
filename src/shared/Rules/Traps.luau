--!strict
-- Trap rules (006): flags, surface multipliers with linger, rotated-rectangle containment. Pure.

local FLAG_BY_SUBKIND: { [string]: string } = {
	slick = "TrapSlick",
	bumper = "TrapBumper",
	slow = "TrapSlow",
	sweeper = "TrapSweeper",
}

local Traps = {}

function Traps.enabled(flags: { [string]: boolean }, subKind: string): boolean
	local own = FLAG_BY_SUBKIND[subKind]
	return own ~= nil and flags.Traps == true and flags[own] == true
end

-- A slow patch can only slow: the result is never above 1.
function Traps.speedMultiplier(slowActive: boolean, mult: number): number
	return if slowActive then math.min(mult, 1) else 1
end

-- A slick patch can only dull steering: the result is never above 1.
function Traps.turnMultiplier(slickActive: boolean, mult: number): number
	return if slickActive then math.min(mult, 1) else 1
end

-- Inside a patch the effect lasts until now + linger; after leaving it holds until that time. Returns whether
-- the effect is active now and the (possibly extended) end time.
function Traps.surfaceActive(
	now: number,
	insideNow: boolean,
	untilT: number,
	linger: number
): (boolean, number)
	if insideNow then
		return true, now + linger
	end
	return now < untilT, untilT
end

-- Point (px, pz) inside the rectangle centred at (cx, cz) with half extents halfW (local X) and halfD (local Z),
-- rotated by yaw degrees about the vertical axis.
function Traps.insideRect(
	px: number,
	pz: number,
	cx: number,
	cz: number,
	halfW: number,
	halfD: number,
	yaw: number
): boolean
	local angle = math.rad(yaw)
	local cosA, sinA = math.cos(angle), math.sin(angle)
	local dx, dz = px - cx, pz - cz
	-- Rotate the offset by -yaw into the rectangle's own frame.
	local localX = dx * cosA - dz * sinA
	local localZ = dx * sinA + dz * cosA
	return math.abs(localX) <= halfW and math.abs(localZ) <= halfD
end

return Traps
