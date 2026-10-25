--!strict
-- Run timer maths. Pure: the current time is always an argument.

local RunClock = {}

function RunClock.remaining(now: number, endsAt: number): number
	return math.max(0, endsAt - now)
end

function RunClock.expired(now: number, endsAt: number): boolean
	return now >= endsAt
end

-- "mm:ss" of the whole seconds left, rounded up, never negative.
function RunClock.format(seconds: number): string
	local whole = math.ceil(math.max(0, seconds))
	return string.format("%02d:%02d", whole // 60, whole % 60)
end

return RunClock
