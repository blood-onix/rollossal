--!strict
-- Contract test for art/capture/cameras.json (specs/009-style-bible-bakeoff/contracts/ceiling-and-tests.md): the five
-- fixed shots, in order, with the in-game camera distance per ball diameter. World coordinates are not pinned.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local Themes = require("../../src/shared/Content/Themes")

local test, expect = harness.test, harness.expect

local SHOT_NAMES =
	{ "01_spawn_d2", "02_street_d5", "03_midgame_d12_30", "04_lategame_d80", "05_overhead_map" }
local MAX_PITCH_DEGREES = 80

local cameras = serde.decode("json", fs.readFile("art/capture/cameras.json"))

local function distance(a: { number }, b: { number }): number
	local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

test("CaptureCameras: five shots in the fixed order with unique names", function()
	expect.equal(cameras.version, 1)
	expect.equal(#cameras.shots, #SHOT_NAMES)
	local seen: { [string]: boolean } = {}
	for index, name in SHOT_NAMES do
		local shot = cameras.shots[index]
		expect.equal(shot.name, name)
		expect.truthy(not seen[shot.name], `duplicate shot {shot.name}`)
		seen[shot.name] = true
	end
end)

test("CaptureCameras: field of view, resolution and theme", function()
	expect.equal(cameras.fov, 70)
	expect.equal(cameras.resolution[1], 1280)
	expect.equal(cameras.resolution[2], 720)
	expect.truthy((Themes :: any)[cameras.theme] ~= nil, `theme {cameras.theme} is not in Themes`)
end)

test("CaptureCameras: ball shots keep the in-game camera distance", function()
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

test("CaptureCameras: every shot stays inside the pitch limit", function()
	for _, shot in cameras.shots do
		local total = distance(shot.position, shot.lookAt)
		local pitch = math.deg(math.asin(math.abs(shot.position[2] - shot.lookAt[2]) / total))
		expect.truthy(pitch <= MAX_PITCH_DEGREES, `{shot.name}: pitch {pitch}`)
	end
end)
