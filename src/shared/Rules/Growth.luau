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

return Growth
