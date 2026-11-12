--!strict
-- Feast (PvP) rules: when a ball eats another, what both become, and when the hunted ball may roll faster.
-- Pure: sizes, distances and the clock are arguments.

local Feast = {}

export type Mode = "Classic" | "Feast"

-- The mode of round number `seq` (1 is the first round). "Alternate" starts with Feast.
function Feast.modeFor(gameMode: string, seq: number): Mode
	if gameMode == "Feast" then
		return "Feast"
	end
	if gameMode == "Alternate" then
		return if seq % 2 == 1 then "Feast" else "Classic"
	end
	return "Classic"
end

-- Eating is open once the grace has passed since the round began.
function Feast.open(now: number, roundStartedAt: number, graceSeconds: number): boolean
	return now - roundStartedAt >= graceSeconds
end

function Feast.canEat(eater: number, victim: number, ratio: number): boolean
	return victim <= ratio * eater
end

function Feast.touching(distance: number, eater: number, victim: number, margin: number): boolean
	return distance <= eater / 2 + victim / 2 + margin
end

-- The eater's new diameter: its volume plus a share of the victim's.
function Feast.eaterDiameter(eater: number, victim: number, share: number): number
	return (eater ^ 3 + share * victim ^ 3) ^ (1 / 3)
end

-- The victim keeps a share of its diameter, never under the start size.
function Feast.victimDiameter(victim: number, keep: number, startDiameter: number): number
	return math.max(startDiameter, victim * keep)
end

-- A bite: the victim keeps `keep` of its diameter (never under the start size).
function Feast.bittenDiameter(victim: number, keep: number, startDiameter: number): number
	return math.max(startDiameter, victim * keep)
end

-- The eater after a bite: its volume plus a share of the volume the victim lost.
function Feast.biterDiameter(
	eater: number,
	victimBefore: number,
	victimAfter: number,
	share: number
): number
	return (eater ^ 3 + share * math.max(0, victimBefore ^ 3 - victimAfter ^ 3)) ^ (1 / 3)
end

-- Whether this bite finishes the victim: it is the last of a run of bites that came close together.
function Feast.swallows(
	bitesSoFar: number,
	sinceLastBite: number,
	window: number,
	needed: number
): (boolean, number)
	local count = if sinceLastBite <= window then bitesSoFar + 1 else 1
	return count >= needed, count
end

-- The size a bot is lifted to if it has fallen behind: a curve from the start size to `finish` over the round.
function Feast.paceFloor(
	elapsed: number,
	duration: number,
	startDiameter: number,
	finish: number,
	exponent: number
): number
	local share = math.clamp(elapsed / duration, 0, 1)
	return startDiameter + (finish - startDiameter) * share ^ exponent
end

-- How close a hunter of this size must be for its prey to get the flee speed.
function Feast.fleeRadius(hunter: number, diameters: number, floor: number): number
	return math.max(floor, hunter * diameters)
end

-- A hit that costs a share of the ball's volume (the asteroid shower), never under the start size.
function Feast.shrinkByShare(diameter: number, share: number, startDiameter: number): number
	return math.max(startDiameter, diameter * (1 - share) ^ (1 / 3))
end

return Feast
