--!strict
-- Knock-off rules (006): what a qualifying hit does, and when two balls bump. Pure: `now` and all state are
-- arguments.

export type DecideInput = {
	now: number,
	stuckCount: number,
	shieldUntil: number,
	immuneUntil: number,
	lastBumpAt: number,
	bumpCooldown: number,
}

export type Decision = "Knock" | "ShieldAbsorbed" | "Immune" | "Cooldown" | "NothingStuck"

local Knock = {}

function Knock.decide(i: DecideInput): Decision
	if i.now < i.immuneUntil then
		return "Immune"
	end
	if i.now - i.lastBumpAt < i.bumpCooldown then
		return "Cooldown"
	end
	-- A shield is spent by any qualifying hit, even when nothing is stuck.
	if i.now < i.shieldUntil then
		return "ShieldAbsorbed"
	end
	if i.stuckCount == 0 then
		return "NothingStuck"
	end
	return "Knock"
end

-- The bigger ball (dA) bumps the smaller (dB) when it is at least ratio times as wide and closing fast enough.
function Knock.ballBump(
	dA: number,
	dB: number,
	closing: number,
	ratio: number,
	threshold: number
): boolean
	return dA >= ratio * dB and closing >= threshold
end

-- How fast A closes on B: A's peak speed towards B minus B's speed along the same line (a retreating B only).
function Knock.closingSpeed(peakA: number, vBAlongLine: number): number
	return math.max(0, peakA - math.max(0, vBAlongLine))
end

return Knock
