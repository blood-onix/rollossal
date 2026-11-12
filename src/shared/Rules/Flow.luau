--!strict
-- The food flow formula: how much edible food a ball should have around it, how big each new piece should be and
-- where it lands. Pure: sizes, random draws (0 to 1) and tuning are arguments.
--
-- "need" is the diameter a ball must have to eat an object (Absorb.needsDiameter). An object is worth rolling to when
-- its need is between worthShare x D and D: big enough to grow the ball, small enough to eat now.

local Flow = {}

export type Tuning = {
	radiusBase: number,
	radiusPerDiameter: number,
	radiusMin: number,
	radiusMax: number,
	worthShare: number,
	target: number,
	perTick: number,
	smallDiameter: number,
	smallTarget: number,
	smallPerTick: number,
	smallNeedLow: number,
	smallNeedHigh: number,
	needLow: number,
	needHigh: number,
	needSkew: number,
	nearShare: number,
	spreadDegrees: number,
}

-- The ring around a ball the flow keeps stocked. It grows with the ball, so the next food is always a few seconds
-- of rolling away.
function Flow.radius(diameter: number, tuning: Tuning): number
	return math.clamp(
		tuning.radiusBase + tuning.radiusPerDiameter * diameter,
		tuning.radiusMin,
		tuning.radiusMax
	)
end

function Flow.worth(need: number, diameter: number, tuning: Tuning): boolean
	return need <= diameter and need >= tuning.worthShare * diameter
end

-- How many pieces the ring should hold and how many may arrive at once. A small ball eats often, so it gets
-- the bigger numbers.
function Flow.quota(diameter: number, tuning: Tuning): (number, number)
	if diameter < tuning.smallDiameter then
		return tuning.smallTarget, tuning.smallPerTick
	end
	return tuning.target, tuning.perTick
end

-- How many pieces are missing from a ring that should hold `target`.
function Flow.deficit(count: number, target: number): number
	return math.max(0, target - count)
end

-- The need of the next piece: a share of D between needLow and needHigh. A skew under 1 leans to the big end, so
-- most new food is a real bite and some is a snack.
function Flow.pickNeed(diameter: number, draw: number, tuning: Tuning): number
	local small = diameter < tuning.smallDiameter
	local low = if small then tuning.smallNeedLow else tuning.needLow
	local high = if small then tuning.smallNeedHigh else tuning.needHigh
	local share = low + (high - low) * draw ^ tuning.needSkew
	return diameter * share
end

-- Where the piece lands, as a flat offset from the ball: somewhere in the ring, spread evenly over its area and
-- within spreadDegrees either side of the ball's heading (hx, hz; any direction when the ball stands still).
function Flow.offset(
	radius: number,
	hx: number,
	hz: number,
	drawDistance: number,
	drawAngle: number,
	tuning: Tuning
): (number, number)
	local distance = radius * (tuning.nearShare + (1 - tuning.nearShare) * math.sqrt(drawDistance))
	local moving = hx * hx + hz * hz > 1e-6
	local spread = if moving then math.rad(tuning.spreadDegrees) else math.pi
	local base = if moving then math.atan2(hz, hx) else 0
	local angle = base + (drawAngle * 2 - 1) * spread
	return math.cos(angle) * distance, math.sin(angle) * distance
end

return Flow
