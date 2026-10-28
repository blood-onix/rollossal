--!strict
-- Running figures behind the owner-only FPS readout. Pure: the caller passes the clock, so the warm-up and the
-- reset are testable. Readings before `ignoreUntil` are shown but not counted, so scene load does not
-- drag the lowest figure down.

export type Stats = { lowest: number, sum: number, seconds: number, ignoreUntil: number }

local FpsStats = {}

function FpsStats.new(now: number, warmup: number): Stats
	return { lowest = math.huge, sum = 0, seconds = 0, ignoreUntil = now + warmup }
end

-- Tapping the readout starts a new window with a fresh warm-up.
function FpsStats.reset(stats: Stats, now: number, warmup: number)
	stats.lowest = math.huge
	stats.sum = 0
	stats.seconds = 0
	stats.ignoreUntil = now + warmup
end

function FpsStats.record(stats: Stats, now: number, fps: number)
	if now >= stats.ignoreUntil then
		stats.lowest = math.min(stats.lowest, fps)
		stats.sum += fps
		stats.seconds += 1
	end
end

-- With nothing counted yet the readout falls back to the current figure.
function FpsStats.average(stats: Stats, current: number): number
	return if stats.seconds > 0 then stats.sum / stats.seconds else current
end

function FpsStats.lowest(stats: Stats, current: number): number
	return if stats.lowest == math.huge then current else stats.lowest
end

-- Only the experience creator sees the readout, and only while the flag is on.
function FpsStats.visibleTo(flag: boolean, creatorId: number, userId: number): boolean
	return flag and creatorId == userId
end

return FpsStats
