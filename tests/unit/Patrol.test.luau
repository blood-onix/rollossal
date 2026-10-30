--!strict
-- A 20 x 20 square at speed 10 (contracts/rules-api.md): one side takes 2 s, the loop 8 s.

local harness = require("./harness")
local Patrol = require("../../src/shared/Rules/Patrol")

local test, expect = harness.test, harness.expect

local square = { { x = 0, z = 0 }, { x = 20, z = 0 }, { x = 20, z = 20 }, { x = 0, z = 20 } }

test("length: perimeter of the closed loop", function()
	expect.near(Patrol.length(square), 80, 1e-9)
end)

test("position: along the sides", function()
	local cases =
		{ { 0, 0, 0 }, { 1, 10, 0 }, { 2, 20, 0 }, { 3, 20, 10 }, { 4, 20, 20 }, { 6, 0, 20 } }
	for _, case in cases do
		local pose = Patrol.position(square, 10, case[1])
		expect.near(pose.x, case[2], 1e-9)
		expect.near(pose.z, case[3], 1e-9)
	end
end)

test("position: wraps by length / speed", function()
	local home = Patrol.position(square, 10, 8)
	expect.near(home.x, 0, 1e-9)
	expect.near(home.z, 0, 1e-9)
	local a, b = Patrol.position(square, 10, 9), Patrol.position(square, 10, 1)
	expect.near(a.x, b.x, 1e-9)
	expect.near(a.z, b.z, 1e-9)
end)

test("position: heading follows each side (atan2(dx, dz), 0 faces +Z)", function()
	expect.near(Patrol.position(square, 10, 1).heading, math.pi / 2, 1e-9)
	expect.near(Patrol.position(square, 10, 3).heading, 0, 1e-9)
	expect.near(Patrol.position(square, 10, 5).heading, -math.pi / 2, 1e-9)
	expect.near(math.abs(Patrol.position(square, 10, 7).heading), math.pi, 1e-9)
end)
