--!strict
-- Server-side anti-cheat verdict for one ball step. Pure: no Roblox APIs, no clock, no randomness; every number
-- is an argument. Speed is the horizontal speed of the physics body; stepSpeed is the horizontal distance
-- from the last valid position divided by the step, so a teleport shows up there even at a low body speed.

export type Verdict = "Ok" | "Speed" | "Displacement"
export type VerticalVerdict = "Ok" | "Vertical"
export type VerticalInput = {
	y: number,
	vy: number,
	grounded: boolean,
	g: number,
	airRefEnergy: number,
	upLimit: number,
	apexAllowance: number,
}

local BallGuard = {}

-- A speed over the ceiling wins over a displacement, because the speed branch clamps the velocity and keeps the
-- position; only a displacement alone resets the ball.
function BallGuard.verdict(
	speed: number,
	stepSpeed: number,
	maxSpeed: number,
	slack: number
): Verdict
	if speed > maxSpeed then
		return "Speed"
	end
	if stepSpeed > maxSpeed * slack then
		return "Displacement"
	end
	return "Ok"
end

-- Horizontal distance per second between two positions over one step. A step with no time is no movement.
function BallGuard.stepSpeed(
	fromX: number,
	fromZ: number,
	toX: number,
	toZ: number,
	dt: number
): number
	if dt <= 0 then
		return 0
	end
	local dx, dz = toX - fromX, toZ - fromZ
	return math.sqrt(dx * dx + dz * dz) / dt
end

-- The horizontal ceiling: a Dash or Spring window (boosted) and the short grace after it use the boost cap.
function BallGuard.speedCeiling(
	base: number,
	boostCap: number,
	boosted: boolean,
	inGrace: boolean
): number
	if boosted or inGrace then
		return boostCap
	end
	return base
end

-- Vertical verdict for one step (research R-03). Ballistic flight conserves E = y + vy^2/2g, so a mid-air second
-- jump (vy back at the take-off speed, higher up) shows as energy over the reference taken on the ground.
-- Grounded steps always pass and refresh the reference, so ramps and stairs never trip it. Falling never fails.
-- Returns the verdict and the new reference energy.
function BallGuard.verticalVerdict(input: VerticalInput): (VerticalVerdict, number)
	if input.grounded then
		local up = math.max(input.vy, 0)
		return "Ok", input.y + up * up / (2 * input.g)
	end
	if input.vy > input.upLimit then
		return "Vertical", input.airRefEnergy
	end
	if input.vy >= 0 then
		local energy = input.y + input.vy * input.vy / (2 * input.g)
		if energy > input.airRefEnergy + input.apexAllowance then
			return "Vertical", input.airRefEnergy
		end
	end
	return "Ok", input.airRefEnergy
end

return BallGuard
