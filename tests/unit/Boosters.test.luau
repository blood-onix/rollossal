--!strict
-- Hand-computed values (contracts/rules-api.md); none is read from the code under test.

local harness = require("./harness")
local Boosters = require("../../src/shared/Rules/Boosters")

local test, expect = harness.test, harness.expect

local p: Boosters.MagnetTuning = { absorbRatio = 0.4, radiusFactor = 3.0, maxPulled = 24 }
local ORIGIN = { x = 0, y = 0, z = 0 }

test("enabled: needs the master flag and the booster's own flag", function()
	local on = { Boosters = true, BoosterDash = true, BoosterSpring = false }
	expect.truthy(Boosters.enabled(on, "dash"))
	expect.falsy(Boosters.enabled(on, "spring"))
	expect.falsy(Boosters.enabled(on, "magnet"))
	expect.falsy(Boosters.enabled({ Boosters = false, BoosterDash = true }, "dash"))
	expect.falsy(Boosters.enabled(on, "unknown"))
end)

test("endsAt and isActive: active strictly before the end time", function()
	expect.equal(Boosters.endsAt(10, 3), 13)
	expect.truthy(Boosters.isActive(12.9, 13))
	expect.falsy(Boosters.isActive(13, 13))
	expect.falsy(Boosters.isActive(5, 0))
end)

test("magnetPick: obstacles above 0.4 x diameter are never picked", function()
	-- D = 5: limit 2.0, reach 15.
	local candidates: { Boosters.MagnetCandidate } = {
		{ id = "small", pos = { x = 3, y = 0, z = 0 }, size = 2.0, available = true },
		{ id = "obstacle", pos = { x = 2, y = 0, z = 0 }, size = 2.1, available = true },
	}
	expect.same(Boosters.magnetPick(ORIGIN, 5, candidates, p), { "small" })
end)

test("magnetPick: radius, availability and nearest-first order", function()
	local candidates: { Boosters.MagnetCandidate } = {
		{ id = "far", pos = { x = 15.1, y = 0, z = 0 }, size = 1, available = true },
		{ id = "edge", pos = { x = 0, y = 0, z = 15 }, size = 1, available = true },
		{ id = "taken", pos = { x = 1, y = 0, z = 0 }, size = 1, available = false },
		{ id = "b", pos = { x = 6, y = 8, z = 0 }, size = 1, available = true },
		{ id = "a", pos = { x = 4, y = 0, z = 0 }, size = 1, available = true },
	}
	-- b is at distance 10, a at 4, edge at 15 (inside), far at 15.1 (outside).
	expect.same(Boosters.magnetPick(ORIGIN, 5, candidates, p), { "a", "b", "edge" })
end)

test("magnetPick: at most 24 parts, the nearest ones", function()
	local candidates: { Boosters.MagnetCandidate } = {}
	for i = 1, 30 do
		table.insert(
			candidates,
			{ id = `p{i}`, pos = { x = i * 0.4, y = 0, z = 0 }, size = 0.5, available = true }
		)
	end
	local picked = Boosters.magnetPick(ORIGIN, 5, candidates, p)
	expect.equal(#picked, 24)
	expect.equal(picked[1], "p1")
	expect.equal(picked[24], "p24")
end)

test("shouldDrop: a patch every 4 studs travelled", function()
	expect.falsy(Boosters.shouldDrop(3.99, 4))
	expect.truthy(Boosters.shouldDrop(4, 4))
	expect.truthy(Boosters.shouldDrop(9, 4))
end)

test("trailExpire: a patch lives its lifetime", function()
	expect.falsy(Boosters.trailExpire(14.9, 10, 5))
	expect.truthy(Boosters.trailExpire(15, 10, 5))
end)

test("dashTarget: doubles the base speed up to the cap", function()
	expect.near(Boosters.dashTarget(18, 2.0, 80), 36, 1e-9)
	expect.near(Boosters.dashTarget(45, 2.0, 80), 80, 1e-9)
end)

test(
	"inClaimReach: a ball on the ground reaches D/2 + radius + margin flat at every size",
	function()
		local marker = { x = 0, y = 0, z = 0 }
		for _, d in { 12, 30, 70 } do
			local reach = d / 2 + 2.5 + 6
			expect.truthy(
				Boosters.inClaimReach({ x = reach - 0.1, y = d / 2, z = 0 }, d, marker, 2.5, 6)
			)
			expect.falsy(
				Boosters.inClaimReach({ x = reach + 0.1, y = d / 2, z = 0 }, d, marker, 2.5, 6)
			)
			-- the client's smaller margin is always inside the server's
			expect.truthy(
				Boosters.inClaimReach(
					{ x = d / 2 + 2.5 + 0.3, y = d / 2, z = 0 },
					d,
					marker,
					2.5,
					6
				)
			)
		end
	end
)

test("inClaimReach: the gap under the ball counts, a ball far above is out of reach", function()
	local marker = { x = 0, y = 0, z = 0 }
	expect.falsy(Boosters.inClaimReach({ x = 0, y = 12 / 2 + 40, z = 0 }, 12, marker, 2.5, 6))
	expect.truthy(Boosters.inClaimReach({ x = 0, y = 12 / 2 + 5, z = 0 }, 12, marker, 2.5, 6))
end)
