--!strict
-- Size-tier lookup and progress towards the next tier. Pure: no Roblox APIs, no clock, no randomness.

export type TierLike = { minDiameter: number }

local Tiers = {}

-- Index of the last tier whose minDiameter is at most the diameter (1 if below the first), and the
-- next tier's minDiameter, or nil on the top tier.
function Tiers.lookup(diameter: number, tiers: { TierLike }): (number, number?)
	local index = 1
	for i, tier in tiers do
		if tier.minDiameter <= diameter then
			index = i
		end
	end
	local nextTier = tiers[index + 1]
	if nextTier then
		return index, nextTier.minDiameter
	end
	return index, nil
end

-- 1 on the top tier, else the fraction of the way to the next tier, clamped to 0..1.
function Tiers.progress(diameter: number, tiers: { TierLike }): number
	local index, nextMin = Tiers.lookup(diameter, tiers)
	if nextMin == nil then
		return 1
	end
	local currentMin = tiers[index].minDiameter
	return math.clamp((diameter - currentMin) / (nextMin - currentMin), 0, 1)
end

-- True when an object's tier is at least `delta` tiers below the player's (the client may hide it).
function Tiers.isCulled(objectTier: number, playerTier: number, delta: number): boolean
	return objectTier <= playerTier - delta
end

-- Collision class of a mesh by tier: Hull for tiers 4-5, Box otherwise and for untiered meshes (hub).
function Tiers.collisionClass(tier: number?): "Box" | "Hull"
	if tier ~= nil and tier >= 4 then
		return "Hull"
	end
	return "Box"
end

return Tiers
