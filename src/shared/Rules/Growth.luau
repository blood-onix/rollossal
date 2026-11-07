--!strict
-- Volume-preserving growth and shrink. Pure: no Roblox APIs, no clock, no randomness.

local Growth = {}

local function cubeRoot(x: number): number
	return x ^ (1 / 3)
end

function Growth.growDiameter(diameter: number, size: number, k: number): number
	return cubeRoot(diameter ^ 3 + k * size ^ 3)
end

function Growth.shrinkDiameter(
	diameter: number,
	sizes: { number },
	k: number,
	floor: number
): number
	local total = 0
	for _, size in sizes do
		total += size ^ 3
	end
	local floorVolume = floor ^ 3
	local volume = math.max(floorVolume, diameter ^ 3 - k * total)
	return cubeRoot(volume)
end

-- Bulk-mode growth: the volume grows by k times the object's bulk cubed. An object under the garnish
-- fraction of the ball adds nothing (it still pops).
function Growth.growByBulk(diameter: number, bulk: number, k: number, garnish: number): number
	if bulk < garnish * diameter then
		return diameter
	end
	return cubeRoot(diameter ^ 3 + k * bulk ^ 3)
end

return Growth
