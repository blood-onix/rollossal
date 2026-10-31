--!strict
-- Hand-computed: the ceiling is 56 studs/s and the slack 4, so the displacement limit is 224 studs/s.

local harness = require("./harness")
local BallGuard = require("../../src/shared/Rules/BallGuard")
local Jump = require("../../src/shared/Rules/Jump")

local test, expect = harness.test, harness.expect

test("verdict: at or under both limits is Ok", function()
	expect.equal(BallGuard.verdict(56, 224, 56, 4), "Ok")
	expect.equal(BallGuard.verdict(0, 0, 56, 4), "Ok")
end)

test("verdict: speed over the ceiling is Speed", function()
	expect.equal(BallGuard.verdict(56.1, 10, 56, 4), "Speed")
end)

test("verdict: a step over 224 studs/s alone is Displacement", function()
	expect.equal(BallGuard.verdict(20, 224.1, 56, 4), "Displacement")
	expect.equal(BallGuard.verdict(20, 247.4, 56, 4), "Displacement")
end)

test("verdict: Speed wins when both limits are broken", function()
	expect.equal(BallGuard.verdict(80, 300, 56, 4), "Speed")
end)

test("stepSpeed: horizontal 3-4-5 over half a second is 10", function()
	expect.near(BallGuard.stepSpeed(0, 0, 3, 4, 0.5), 10, 1e-9)
end)

test("stepSpeed: a zero or negative step is no movement", function()
	expect.equal(BallGuard.stepSpeed(0, 0, 100, 100, 0), 0)
	expect.equal(BallGuard.stepSpeed(0, 0, 100, 100, -1), 0)
end)

test("stepSpeed: one 60 Hz step of 4 studs is 240, over the displacement limit", function()
	local speed = BallGuard.stepSpeed(0, 0, 4, 0, 1 / 60)
	expect.near(speed, 240, 1e-9)
	expect.equal(BallGuard.verdict(10, speed, 56, 4), "Displacement")
end)

local G = 196.2
local tuning: Jump.JumpTuning = {
	clearRatio = 0.6,
	holdClearRatio = 0.85,
	minClear = 1.6,
	holdMaxSeconds = 0.25,
	verticalSlack = 1.25,
	airEnergyAllowance = 1.0,
	maxSlopeRatio = 0.5,
}

test("speedCeiling: base unless boosted or in grace (56 / 80)", function()
	expect.equal(BallGuard.speedCeiling(56, 80, false, false), 56)
	expect.equal(BallGuard.speedCeiling(56, 80, true, false), 80)
	expect.equal(BallGuard.speedCeiling(56, 80, false, true), 80)
	expect.equal(BallGuard.speedCeiling(56, 80, true, true), 80)
end)

-- Simulates a jump from y0 with the fixed 1/60 step. A held jump lowers gravity to q for holdFor seconds while
-- the ball rises. Returns the worst verdict seen, checking every airborne step like BallService would.
local function flyArc(d: number, held: boolean, y0: number): string
	local dt = 1 / 60
	local v0 = Jump.takeoffSpeed(d, G, tuning)
	local q = Jump.holdGravity(d, G, tuning.holdMaxSeconds, tuning)
	local upLimit = Jump.upLimit(d, G, 56, nil, tuning)
	local allowance = Jump.apexAllowance(d, nil, G, tuning)
	local y, vy, t = y0, v0, 0
	local _, ref = BallGuard.verticalVerdict({
		y = y,
		vy = vy,
		grounded = true,
		g = G,
		airRefEnergy = 0,
		upLimit = upLimit,
		apexAllowance = allowance,
	})
	while y >= y0 and t < 10 do
		local gravity = if held and t < tuning.holdMaxSeconds and vy > 0 then q else G
		vy -= gravity * dt
		y += vy * dt
		t += dt
		if y < y0 then
			break
		end
		local verdict = BallGuard.verticalVerdict({
			y = y,
			vy = vy,
			grounded = false,
			g = G,
			airRefEnergy = ref,
			upLimit = upLimit,
			apexAllowance = allowance,
		})
		if verdict ~= "Ok" then
			return verdict
		end
	end
	return "Ok"
end

test("verticalVerdict: tap and held jumps at D = 2, 5, 12, 30, 70 stay Ok along the arc", function()
	for _, d in { 2, 5, 12, 30, 70 } do
		expect.equal(flyArc(d, false, 0), "Ok", `tap D={d}`)
		expect.equal(flyArc(d, true, 0), "Ok", `held D={d}`)
		expect.equal(flyArc(d, true, 11), "Ok", `held on a roof D={d}`)
	end
end)

test(
	"verticalVerdict: a second take-off at the held apex, or a chain of them, is Vertical",
	function()
		-- D = 5: v0 = 34.31, tap apex 3.0, held apex 4.25, allowance (4.25 + 1) * 1.25 = 6.5625.
		-- A re-jump at the held apex has E = 4.25 + 3.0 = 7.25 > 0 + 6.5625. (A re-jump at the tap apex is E = 6.0 and
		-- is inside the slack by design; the next one is caught: E = 6 + 3 = 9.)
		local d = 5
		local v0 = Jump.takeoffSpeed(d, G, tuning)
		local function reJumpAt(y: number): string
			local verdict = BallGuard.verticalVerdict({
				y = y,
				vy = v0,
				grounded = false,
				g = G,
				airRefEnergy = 0,
				upLimit = Jump.upLimit(d, G, 56, nil, tuning),
				apexAllowance = Jump.apexAllowance(d, nil, G, tuning),
			})
			return verdict
		end
		expect.equal(reJumpAt(4.25), "Vertical")
		expect.equal(reJumpAt(6.0), "Vertical")
	end
)

test("verticalVerdict: an upward speed over the limit is Vertical even near the ground", function()
	local verdict = BallGuard.verticalVerdict({
		y = 0.5,
		vy = 40,
		grounded = false,
		g = G,
		airRefEnergy = 0,
		upLimit = 31.33,
		apexAllowance = 100,
	})
	expect.equal(verdict, "Vertical")
end)

test(
	"verticalVerdict: rolling up a 0.42 ramp is grounded and Ok, and refreshes the reference",
	function()
		-- Horizontal 30 studs/s up a 0.42 slope: vy = 12.6, y = 6.
		local verdict, ref = BallGuard.verticalVerdict({
			y = 6,
			vy = 12.6,
			grounded = true,
			g = G,
			airRefEnergy = 0,
			upLimit = 28,
			apexAllowance = 4,
		})
		expect.equal(verdict, "Ok")
		expect.near(ref, 6 + 12.6 * 12.6 / (2 * G), 1e-9)
	end
)

test("verticalVerdict: falling is never Vertical", function()
	local verdict = BallGuard.verticalVerdict({
		y = 500,
		vy = -90,
		grounded = false,
		g = G,
		airRefEnergy = 0,
		upLimit = 28,
		apexAllowance = 4,
	})
	expect.equal(verdict, "Ok")
end)

test("verticalVerdict: a spring arc is Ok only with the spring limits", function()
	-- Spring: vy 70 up from y = 0, apex 12.487. Without the spring limit it fails; with it, it passes.
	local plain = BallGuard.verticalVerdict({
		y = 3,
		vy = 65,
		grounded = false,
		g = G,
		airRefEnergy = 0,
		upLimit = Jump.upLimit(2, G, 56, nil, tuning),
		apexAllowance = Jump.apexAllowance(2, nil, G, tuning),
	})
	expect.equal(plain, "Vertical")
	local spring = BallGuard.verticalVerdict({
		y = 3,
		vy = 65,
		grounded = false,
		g = G,
		airRefEnergy = 0,
		upLimit = Jump.upLimit(2, G, 56, 70, tuning),
		apexAllowance = Jump.apexAllowance(2, 70, G, tuning),
	})
	expect.equal(spring, "Ok")
end)

return {}
