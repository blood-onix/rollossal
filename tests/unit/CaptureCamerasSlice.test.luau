--!strict
-- Contract test for art/capture/cameras-slice.json (010 quality gate 6): the five fixed shots of the Main-Street slice, in
-- order, with the in-game camera distance per ball diameter and every look-at point inside the slice.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local Themes = require("../../src/shared/Content/Themes")

local test, expect = harness.test, harness.expect

local SHOT_NAMES =
	{ "01_spawn_d2", "02_street_d5", "03_midgame_d12_30", "04_lategame_d80", "05_overhead_map" }
local MAX_PITCH_DEGREES = 80

local cameras = serde.decode("json", fs.readFile("art/capture/cameras-slice.json"))

local function distance(a: { number }, b: { number }): number
	local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

test("CaptureCamerasSlice: five shots in the fixed order with unique names", function()
	expect.equal(cameras.version, 1)
	expect.equal(cameras.world, "main_street_slice")
	expect.equal(#cameras.shots, #SHOT_NAMES)
	local seen: { [string]: boolean } = {}
	for index, name in SHOT_NAMES do
		local shot = cameras.shots[index]
		expect.equal(shot.name, name)
		expect.truthy(not seen[shot.name], `duplicate shot {shot.name}`)
		seen[shot.name] = true
	end
end)

test("CaptureCamerasSlice: field of view, resolution and theme", function()
	expect.equal(cameras.fov, 70)
	expect.equal(cameras.resolution[1], 1280)
	expect.equal(cameras.resolution[2], 720)
	expect.truthy((Themes :: any)[cameras.theme] ~= nil, `theme {cameras.theme} is not in Themes`)
end)

test("CaptureCamerasSlice: ball shots keep the in-game camera distance", function()
	for _, shot in cameras.shots do
		if shot.diameter ~= nil then
			local expected = math.min(
				Config.cameraMaxDistance,
				math.max(Config.cameraMinDistance, Config.cameraMultiplier * shot.diameter)
			)
			local actual = distance(shot.position, shot.lookAt)
			expect.truthy(
				math.abs(actual - expected) <= 0.01,
				`{shot.name}: distance {actual}, expected {expected}`
			)
		end
	end
end)

test("CaptureCamerasSlice: every shot stays inside the pitch limit", function()
	for _, shot in cameras.shots do
		local total = distance(shot.position, shot.lookAt)
		local pitch = math.deg(math.asin(math.abs(shot.position[2] - shot.lookAt[2]) / total))
		expect.truthy(pitch <= MAX_PITCH_DEGREES, `{shot.name}: pitch {pitch}`)
	end
end)

test(
	"CaptureCamerasSlice: ball shots look at points inside the slice, and the spawn shot looks along +z",
	function()
		local b = cameras.bounds
		expect.equal(b.minX, -100)
		expect.equal(b.maxX, 100)
		expect.equal(b.minZ, -250)
		expect.equal(b.maxZ, 250)
		for _, shot in cameras.shots do
			expect.truthy(
				shot.lookAt[1] >= b.minX
					and shot.lookAt[1] <= b.maxX
					and shot.lookAt[3] >= b.minZ
					and shot.lookAt[3] <= b.maxZ,
				shot.name
			)
			if shot.diameter ~= nil then
				expect.truthy(shot.lookAt[3] > shot.position[3], `{shot.name} looks toward +z`)
			end
		end
		expect.truthy(
			cameras.shots[1].position[3] >= b.minZ,
			"the spawn camera is inside the boundary"
		)
	end
)
