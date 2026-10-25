--!strict
-- Roll speed and camera distance. Pure: no Roblox APIs, no clock, no randomness.

local Movement = {}

function Movement.targetSpeed(
	diameter: number,
	baseSpeed: number,
	startDiameter: number,
	exponent: number,
	cap: number
): number
	return math.min(cap, baseSpeed * ((diameter / startDiameter) ^ exponent))
end

function Movement.cameraDistance(
	diameter: number,
	multiplier: number,
	minDistance: number,
	maxDistance: number
): number
	return math.min(maxDistance, math.max(minDistance, multiplier * diameter))
end

return Movement
