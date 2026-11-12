--!strict
-- The rules of the map's toys: pad footprints, launch arcs and catching a rail.

local harness = require("./harness")
local Toys = require("../../src/shared/Rules/Toys")

local test, expect = harness.test, harness.expect

local function near(a: number, b: number, tolerance: number?)
	expect.truthy(math.abs(a - b) <= (tolerance or 1e-6), `{a} is not near {b}`)
end

test("Toys.direction: yaw 0 is north, 90 is east, 180 is south", function()
	local x, z = Toys.direction(0)
	near(x, 0)
	near(z, -1)
	x, z = Toys.direction(90)
	near(x, 1)
	near(z, 0)
	x, z = Toys.direction(180)
	near(x, 0)
	near(z, 1)
end)

test("Toys.onPad: the footprint turns with the pad", function()
	local pad = { x = 0, y = 0, z = 0, yaw = 90, size = { 20, 30 } }
	-- Turned a quarter, the 30 side lies along x.
	expect.truthy(Toys.onPad({ x = 14, y = 0.5, z = 0 }, 1, pad, 2))
	expect.falsy(Toys.onPad({ x = 0, y = 0.5, z = 14 }, 1, pad, 2))
end)

test("Toys.onPad: a ball well above the pad does not trigger it", function()
	local pad = { x = 0, y = 0, z = 0, yaw = 0, size = { 8, 8 } }
	expect.truthy(Toys.onPad({ x = 0, y = 1, z = 0 }, 2, pad, 2.5))
	expect.falsy(Toys.onPad({ x = 0, y = 10, z = 0 }, 2, pad, 2.5))
end)

test("Toys.arc lands on its target, at the same or a greater height", function()
	local gravity = 196.2
	local from = { x = 0, y = 1, z = 0 }
	for _, to in { { x = 170, y = 0, z = 40 }, { x = -90, y = 25, z = 120 } } do
		local arc = Toys.arc(from, to, 60, gravity)
		local t = arc.seconds
		near(from.x + arc.vx * t, to.x, 1e-3)
		near(from.z + arc.vz * t, to.z, 1e-3)
		near(from.y + arc.vy * t - gravity * t * t / 2, to.y, 1e-3)
	end
end)

test("Toys.nearestOnPath and pointAt agree along a bent rail", function()
	local path = { { 0, 0, 0 }, { 10, 0, 0 }, { 10, 0, 10 } }
	near(Toys.pathLength(path), 20)
	local hit = Toys.nearestOnPath(path, { x = 12, y = 0, z = 5 })
	near(hit.along, 15)
	near(hit.distance, 2)
	near(hit.tz, 1)
	local x, _, z, _, _, tz = Toys.pointAt(path, 15)
	near(x, 10)
	near(z, 5)
	near(tz, 1)
end)

test("Toys.pointAt holds the end of the path past its length", function()
	local path = { { 0, 0, 0 }, { 10, 0, 0 } }
	local x = Toys.pointAt(path, 99)
	near(x, 10)
end)

test("Toys.railCatch: rolling with the rail catches it, in that direction", function()
	local hit = { along = 50, distance = 1, tx = 1, ty = 0, tz = 0 }
	expect.equal(Toys.railCatch(hit, 100, 10, 0, 10, 0.8), 1)
	expect.equal(Toys.railCatch(hit, 100, -10, 0, 10, 0.8), -1)
end)

test("Toys.railCatch: crossing mid-rail at right angles leaves the ball alone", function()
	local hit = { along = 50, distance = 1, tx = 1, ty = 0, tz = 0 }
	expect.equal(Toys.railCatch(hit, 100, 0, 10, 10, 0.8), nil)
end)

test("Toys.pickGoals: the nearest edible giants, then the next ones to grow towards", function()
	local giants = {
		{ x = 100, z = 0, need = 5 },
		{ x = 10, z = 0, need = 8 },
		{ x = 300, z = 0, need = 11 },
		{ x = 5, z = 0, need = 80 },
		{ x = 1, z = 0, need = 4, hidden = true },
	}
	local picked = Toys.pickGoals(giants, 10, 0, 0, 1, 1)
	expect.equal(#picked, 2)
	expect.equal(picked[1].need, 8)
	expect.equal(picked[2].need, 11)
end)

test("Toys.railCatch: a ball rolling away from a rail end is left alone", function()
	expect.equal(
		Toys.railCatch({ along = 4, distance = 1, tx = 1, ty = 0, tz = 0 }, 100, -5, 10, 10, 0.95),
		nil
	)
	expect.equal(
		Toys.railCatch({ along = 96, distance = 1, tx = 1, ty = 0, tz = 0 }, 100, 5, 10, 10, 0.95),
		nil
	)
end)

test("Toys.railAtBallLevel: a roof rail does not catch a big ball on the street", function()
	expect.falsy(Toys.railAtBallLevel(30, 18, 36, 6))
	expect.truthy(Toys.railAtBallLevel(30, 48, 36, 6))
	expect.truthy(Toys.railAtBallLevel(0.6, 1, 2, 6))
end)

test("Toys.vacuumRadius grows with the ball between its floor and ceiling", function()
	expect.equal(Toys.vacuumRadius(1, 8, 3, 30), 8)
	expect.equal(Toys.vacuumRadius(5, 8, 3, 30), 15)
	expect.equal(Toys.vacuumRadius(80, 8, 3, 30), 30)
end)

test("Toys.pickGoals: fewer giants than badges is fine", function()
	expect.equal(#Toys.pickGoals({ { x = 0, z = 0, need = 2 } }, 1, 0, 0, 2, 2), 1)
	expect.equal(#Toys.pickGoals({}, 1, 0, 0, 2, 2), 0)
end)

test("Toys.railCatch: either end catches a ball from any direction", function()
	expect.equal(
		Toys.railCatch({ along = 4, distance = 1, tx = 1, ty = 0, tz = 0 }, 100, 0, 10, 10, 0.8),
		1
	)
	expect.equal(
		Toys.railCatch({ along = 96, distance = 1, tx = 1, ty = 0, tz = 0 }, 100, 0, 10, 10, 0.8),
		-1
	)
end)
