--!strict
-- Expected values are worked by hand from research R4 (bound 1.25 D box, longest side at most 0.45 D).

local harness = require("./harness")
local HeapFit = require("../../src/shared/Rules/HeapFit")

local test, expect = harness.test, harness.expect

local params: HeapFit.Params = {
	maxScale = 0.45,
	bound = 1.25,
	newestBound = 0.25,
	embed = 0.35,
	grace = 3,
}

local shapes: { { number } } = {
	{ 3, 1.1, 0.4 }, -- violin
	{ 8, 0.4, 0.4 }, -- lamp post
	{ 2, 2, 2 }, -- cube
	{ 40, 30, 20 }, -- a car-sized thing
	{ 0.3, 0.3, 0.3 }, -- crumb
	{ 5, 5, 4 }, -- thick slab
}

test("fit: the longest side is scaled to 0.45 D", function()
	local fit = HeapFit.fit({ 3, 1.1, 0.4 }, 2, params)
	expect.near(fit.long, 0.9, 1e-9)
	expect.near(fit.scale, 0.3, 1e-9)
end)

test("fit: small items are never enlarged", function()
	local fit = HeapFit.fit({ 0.3, 0.3, 0.3 }, 10, params)
	expect.equal(fit.scale, 1)
end)

test("fit: the long axis lies tangent, the thinnest points along the normal", function()
	local fit = HeapFit.fit({ 1, 3, 0.5 }, 20, params)
	expect.equal(fit.longAxis, 2)
	expect.equal(fit.midAxis, 1)
	expect.equal(fit.thinAxis, 3)
end)

test("fit: the heap stays inside the 1.25 D box at every size (SC-004)", function()
	for _, d in { 1, 2, 5, 10, 20, 50, 100 } do
		for _, dims in shapes do
			local fit = HeapFit.fit(dims, d, params)
			expect.truthy(fit.scale * dims[fit.longAxis] <= 0.45 * d + 1e-9, "scale bound")
			expect.truthy(fit.scale <= 1)
			local top = fit.centerDistance + fit.thin / 2
			expect.truthy(top <= d / 2 + 0.125 * d + 1e-9, `box bound D {d}`)
			expect.truthy(fit.long / 2 <= 0.625 * d + 1e-9)
		end
	end
end)

test("fit: a thick slab is buried so its top sits 0.125 D above the surface", function()
	local fit = HeapFit.fit({ 5, 5, 4 }, 10, params)
	-- scaled by 4.5/5 = 0.9 -> thin 3.6; reach = min(1.25, 0.65 * 3.6) = 1.25
	expect.near(fit.reach, 1.25, 1e-9)
	expect.near(fit.centerDistance, 5 + 1.25 - 1.8, 1e-9)
end)

test("fit: the newest catch may reach 0.25 D, then eases to the normal fit", function()
	local dims = { 5, 5, 4 }
	local fresh = HeapFit.fit(dims, 10, params, 0)
	expect.near(fresh.reach, 0.65 * 3.6, 1e-9) -- 2.34 < 2.5, thickness-limited
	local normal = HeapFit.fit(dims, 10, params)
	local done = HeapFit.fit(dims, 10, params, 3)
	expect.near(done.reach, normal.reach, 1e-12)
	expect.truthy(fresh.reach > normal.reach)
end)

test("fit: the newest-catch allowance has no jump between frames", function()
	local previous = HeapFit.fit({ 5, 5, 4 }, 10, params, 0).reach
	local worst = 0
	for i = 1, 180 do
		local reach = HeapFit.fit({ 5, 5, 4 }, 10, params, i / 60).reach
		worst = math.max(worst, math.abs(reach - previous))
		expect.truthy(reach <= previous + 1e-12, "monotone ease")
		previous = reach
	end
	expect.truthy(worst < 0.05, `largest step {worst}`)
end)

return {}
