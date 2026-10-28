--!strict
-- Server-side anti-cheat verdict for one ball step. Pure: no Roblox APIs, no clock, no randomness; every number
-- is an argument. Speed is the horizontal speed of the physics body; stepSpeed is the horizontal distance
-- from the last valid position divided by the step, so a teleport shows up there even at a low body speed.

export type Verdict = "Ok" | "Speed" | "Displacement"

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

return BallGuard
