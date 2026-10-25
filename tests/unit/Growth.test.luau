--!strict
-- Expected values are hand-computed from contracts/rules-api.md §Growth and cross-checked with a
-- double-precision calculation outside this repo. Tolerances as written in tasks.md T011.

local harness = require("./harness")
local Growth = require("../../src/shared/Rules/Growth")

local test, expect = harness.test, harness.expect

test("growDiameter: first tier 1 pickup from D = 2", function()
	expect.near(Growth.growDiameter(2, 0.75, 0.6), 2.0209, 1e-4)
end)

test("growDiameter: tier 4 pickup at D = 3.75", function()
	-- (3.75^3 + 0.6 * 1.5^3)^(1/3) = 3.797398...; the contract's 3.7975 is rounded too coarsely for 1e-4.
	expect.near(Growth.growDiameter(3.75, 1.5, 0.6), 3.7974, 1e-4)
end)

test("growDiameter: 22 tier 1 pickups from D = 2 reach tier 2 gate", function()
	local d = 2
	for _ = 1, 22 do
		d = Growth.growDiameter(d, 0.75, 0.6)
	end
	expect.near(d, 2.3851, 1e-3)
	expect.truthy(d >= 2.375)
end)

test("growDiameter: 21 tier 1 pickups stay below the tier 2 gate", function()
	local d = 2
	for _ = 1, 21 do
		d = Growth.growDiameter(d, 0.75, 0.6)
	end
	expect.near(d, 2.3703, 1e-3)
	expect.truthy(d < 2.375)
end)

test("shrinkDiameter: one tier 2 cube from D = 3", function()
	expect.near(Growth.shrinkDiameter(3, { 0.95 }, 0.6, 2), 2.9808, 1e-3)
end)

test("shrinkDiameter: clamps to the floor of 2", function()
	expect.equal(Growth.shrinkDiameter(2.05, { 1.5, 1.5, 1.5 }, 0.6, 2), 2)
end)

test("shrinkDiameter: already at the floor stays at 2", function()
	expect.equal(Growth.shrinkDiameter(2, { 0.75 }, 0.6, 2), 2)
end)

test("shrinkDiameter: empty list leaves diameter unchanged", function()
	expect.near(Growth.shrinkDiameter(3, {}, 0.6, 2), 3, 1e-9)
end)

return {}
