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

export type SpeedCapRule = {
	base: number,
	fromDiameter: number,
	slope: number,
	max: number,
}

-- The speed cap grows slowly with size once the ball is past fromDiameter.
function Movement.speedCap(diameter: number, rule: SpeedCapRule): number
	if diameter <= rule.fromDiameter then
		return math.min(rule.max, rule.base)
	end
	return math.min(rule.max, rule.base + rule.slope * (diameter - rule.fromDiameter))
end

return Movement
