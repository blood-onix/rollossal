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

-- A world's absorb rule (Worlds.rules.absorb). "size" keeps today's rule on the longest side; "bulk" is the
-- Park City rule: chunky enough (bulk) and not too long (longest).
export type Rule = {
	mode: string,
	ratio: number,
	longestRatio: number?,
	garnish: number?,
}

-- bulk: cube root of l*w*h. longest: the longest side. For a cube both equal its size.
function Absorb.canEat(rule: Rule, diameter: number, bulk: number, longest: number): boolean
	if rule.mode == "bulk" then
		return bulk <= rule.ratio * diameter
			and longest <= (rule.longestRatio or math.huge) * diameter
	end
	return longest <= rule.ratio * diameter
end

-- Cube root of the bounding-box volume, from dims = {l, w, h}.
function Absorb.bulkOf(dims: { number }): number
	return (dims[1] * dims[2] * dims[3]) ^ (1 / 3)
end

-- The smallest ball diameter that can eat an object of this bulk and longest side.
function Absorb.needsDiameter(rule: Rule, bulk: number, longest: number): number
	if rule.mode == "bulk" then
		return math.max(bulk / rule.ratio, longest / (rule.longestRatio or math.huge))
	end
	return longest / rule.ratio
end

return Absorb
