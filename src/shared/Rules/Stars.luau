--!strict
-- Star count for a final diameter. Pure: no Roblox APIs, no clock, no randomness.

local Stars = {}

-- Count of thresholds the diameter has reached (inclusive lower bound). Thresholds ascend.
function Stars.stars(diameter: number, thresholds: { number }): number
	local count = 0
	for _, threshold in thresholds do
		if diameter >= threshold then
			count += 1
		end
	end
	return count
end

return Stars
