--!strict
-- Diameter-scaled jump (006, research R-01). Pure: gravity, time and tuning are arguments.
-- A tap sets the take-off speed for an apex of tapApex(d); a hold lowers gravity to holdGravity for at most
-- holdMaxSeconds so the apex reaches holdApex(d). Heights are the rise of the ball's bottom, in studs.

export type JumpTuning = {
	clearRatio: number,
	holdClearRatio: number,
	minClear: number,
	holdMaxSeconds: number,
	verticalSlack: number,
	airEnergyAllowance: number,
	maxSlopeRatio: number,
}

local Jump = {}

-- Rise of a tapped jump: a fraction of the diameter, never under the floor that clears a Tier 1 kerb.
function Jump.tapApex(d: number, p: JumpTuning): number
	return math.max(p.clearRatio * d, p.minClear)
end

-- Rise of a held jump. The floor scales with the same hold-to-tap ratio so a held hop is always higher.
function Jump.holdApex(d: number, p: JumpTuning): number
	return math.max(p.holdClearRatio * d, p.minClear * p.holdClearRatio / p.clearRatio)
end

function Jump.takeoffSpeed(d: number, g: number, p: JumpTuning): number
	return math.sqrt(2 * g * Jump.tapApex(d, p))
end

-- The gravity q that applies while the button is held so the apex is exactly holdApex.
-- If the whole ascent fits in holdSeconds: q = v0^2 / (2 * h2). Otherwise the hold ends before the apex and
-- h2 = v0*T - q*T^2/2 + (v0 - q*T)^2 / (2g) is solved for the smaller root of the quadratic in q.
function Jump.holdGravity(d: number, g: number, holdSeconds: number, p: JumpTuning): number
	local v0 = Jump.takeoffSpeed(d, g, p)
	local h1 = Jump.tapApex(d, p)
	local h2 = Jump.holdApex(d, p)
	local q = v0 * v0 / (2 * h2)
	if v0 / q <= holdSeconds then
		return q
	end
	local a = holdSeconds * holdSeconds / (2 * g)
	local b = -(holdSeconds * holdSeconds / 2 + v0 * holdSeconds / g)
	local c = v0 * holdSeconds + h1 - h2
	local discriminant = math.max(b * b - 4 * a * c, 0)
	q = (-b - math.sqrt(discriminant)) / (2 * a)
	return math.clamp(q, 0, g)
end

-- Largest upward speed the server accepts: the take-off speed (or the spring speed while its window is open)
-- with slack, never below what a ramp climbed at the horizontal ceiling needs.
function Jump.upLimit(
	d: number,
	g: number,
	ceiling: number,
	springVy: number?,
	p: JumpTuning
): number
	local launch = math.max(Jump.takeoffSpeed(d, g, p), springVy or 0)
	return math.max(launch * p.verticalSlack, ceiling * p.maxSlopeRatio)
end

-- How far the airborne energy y + vy^2/2g may sit above the reference taken on the ground.
function Jump.apexAllowance(d: number, springVy: number?, g: number, p: JumpTuning): number
	local springApex = if springVy then springVy * springVy / (2 * g) else 0
	return (math.max(Jump.holdApex(d, p), springApex) + p.airEnergyAllowance) * p.verticalSlack
end

-- A take-off needs the ground, a finished cooldown and no upward motion left from a recent jump.
function Jump.canTakeOff(
	grounded: boolean,
	now: number,
	lastJumpAt: number,
	vy: number,
	cooldown: number
): boolean
	return grounded and now - lastJumpAt >= cooldown and vy <= 2
end

return Jump
