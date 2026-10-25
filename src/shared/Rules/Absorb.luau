--!strict
-- Pickup and knock-off rules. Pure: no Roblox APIs, no clock, no randomness.

local Absorb = {}

function Absorb.canAbsorb(diameter: number, size: number, ratio: number): boolean
	return size <= ratio * diameter
end

function Absorb.isKnockOff(
	diameter: number,
	size: number,
	impactSpeed: number,
	ratio: number,
	threshold: number
): boolean
	return not Absorb.canAbsorb(diameter, size, ratio) and impactSpeed > threshold
end

return Absorb
