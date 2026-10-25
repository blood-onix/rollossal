--!strict
-- Sliding-window request limiter. Time is passed in; refused calls append nothing.
-- Pure: no Roblox APIs, no clock, no randomness.

local RateLimit = {}

function RateLimit.allow(
	timestamps: { number },
	now: number,
	limit: number,
	window: number
): (boolean, { number })
	local cutoff = now - window
	local kept: { number } = {}
	for _, t in timestamps do
		if t > cutoff then
			table.insert(kept, t)
		end
	end
	if #kept < limit then
		table.insert(kept, now)
		return true, kept
	end
	return false, kept
end

return RateLimit
