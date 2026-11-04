--!strict
-- Scene kit expansion: hand-computed rotation and translation, seeded jitter, ids, and hard errors.

local harness = require("./harness")
local SceneKit = require("../../src/shared/Rules/SceneKit")

local test, expect = harness.test, harness.expect

local WIDE = { minX = -1000, maxX = 1000, minZ = -1000, maxZ = 1000 }

local function kit(entries: { SceneKit.KitEntry }): SceneKit.KitDef
	return { id = "test_kit", halfX = 6, halfZ = 3, entries = entries }
end

local function instance(ox: number, oz: number, yaw: number, seed: number): SceneKit.KitInstance
	return {
		kitId = "test_kit",
		ox = ox,
		oz = oz,
		yaw = yaw,
		seed = seed,
		jitterPos = 0,
		jitterYaw = 0,
	}
end

test("SceneKit: yaw 0 only translates by the origin", function()
	local out = SceneKit.expand(
		kit({ { objectId = "bench", dx = 3, dz = 1, yaw = 0 } }),
		instance(10, 20, 0, 1),
		"k",
		WIDE
	)
	expect.equal(#out, 1)
	expect.near(out[1].x, 13, 1e-9)
	expect.near(out[1].z, 21, 1e-9)
	expect.near(out[1].yaw, 0, 1e-9)
end)

test("SceneKit: a 90 degree instance yaw maps (3, 1) at (10, 20) to (11, 17)", function()
	local out = SceneKit.expand(
		kit({ { objectId = "bench", dx = 3, dz = 1, yaw = 0 } }),
		instance(10, 20, 90, 1),
		"k",
		WIDE
	)
	expect.near(out[1].x, 11, 1e-9)
	expect.near(out[1].z, 17, 1e-9)
	expect.near(out[1].yaw, math.rad(90), 1e-9)
end)

test("SceneKit: a 180 degree instance yaw mirrors both offsets", function()
	local out = SceneKit.expand(
		kit({ { objectId = "bench", dx = 3, dz = 1, yaw = 0 } }),
		instance(10, 20, 180, 1),
		"k",
		WIDE
	)
	expect.near(out[1].x, 7, 1e-9)
	expect.near(out[1].z, 19, 1e-9)
end)

test("SceneKit: entry yaw adds to the instance yaw, in radians", function()
	local out = SceneKit.expand(
		kit({ { objectId = "bench", dx = 0, dz = 0, yaw = 180 } }),
		instance(0, 0, 90, 1),
		"k",
		WIDE
	)
	expect.near(out[1].yaw, math.rad(270), 1e-9)
end)

test("SceneKit: ids are idPrefix_index and unique", function()
	local entries: { SceneKit.KitEntry } = {
		{ objectId = "a", dx = -2, dz = 0, yaw = 0 },
		{ objectId = "b", dx = 0, dz = 0, yaw = 0 },
		{ objectId = "c", dx = 2, dz = 0, yaw = 0 },
	}
	local out = SceneKit.expand(kit(entries), instance(0, 0, 0, 1), "stall", WIDE)
	expect.equal(out[1].id, "stall_1")
	expect.equal(out[2].id, "stall_2")
	expect.equal(out[3].id, "stall_3")
	expect.equal(out[2].objectId, "b")
end)

test("SceneKit: default jitter stays within 0.5 stud and 3 degrees", function()
	local entries: { SceneKit.KitEntry } = {}
	for i = 1, 6 do
		table.insert(entries, { objectId = "a", dx = i - 3.5, dz = 0, yaw = 0 })
	end
	for seed = 1, 40 do
		local plain = SceneKit.expand(kit(entries), instance(5, 5, 0, seed), "k", WIDE)
		local jittered = SceneKit.expand(
			kit(entries),
			{ kitId = "test_kit", ox = 5, oz = 5, yaw = 0, seed = seed },
			"k",
			WIDE
		)
		for i = 1, #plain do
			expect.truthy(math.abs(jittered[i].x - plain[i].x) <= 0.5)
			expect.truthy(math.abs(jittered[i].z - plain[i].z) <= 0.5)
			expect.truthy(math.abs(jittered[i].yaw - plain[i].yaw) <= math.rad(3) + 1e-9)
		end
	end
end)

test("SceneKit: jitter is seeded, deterministic and varies with the seed", function()
	local entries: { SceneKit.KitEntry } = { { objectId = "a", dx = 1, dz = 1, yaw = 0 } }
	local a = SceneKit.expand(
		kit(entries),
		{ kitId = "test_kit", ox = 0, oz = 0, yaw = 0, seed = 7 },
		"k",
		WIDE
	)
	local b = SceneKit.expand(
		kit(entries),
		{ kitId = "test_kit", ox = 0, oz = 0, yaw = 0, seed = 7 },
		"k",
		WIDE
	)
	local c = SceneKit.expand(
		kit(entries),
		{ kitId = "test_kit", ox = 0, oz = 0, yaw = 0, seed = 8 },
		"k",
		WIDE
	)
	expect.equal(a[1].x, b[1].x)
	expect.equal(a[1].z, b[1].z)
	expect.equal(a[1].yaw, b[1].yaw)
	expect.truthy(a[1].x ~= c[1].x or a[1].z ~= c[1].z)
end)

test("SceneKit: an entry outside the footprint is a hard error", function()
	local ok, message = pcall(function()
		SceneKit.expand(
			kit({ { objectId = "a", dx = 6.5, dz = 0, yaw = 0 } }),
			instance(0, 0, 0, 1),
			"k",
			WIDE
		)
	end)
	expect.falsy(ok)
	expect.truthy(string.find(tostring(message), "footprint", 1, true) ~= nil)
	local ok2 = pcall(function()
		SceneKit.expand(
			kit({ { objectId = "a", dx = 0, dz = -3.5, yaw = 0 } }),
			instance(0, 0, 0, 1),
			"k",
			WIDE
		)
	end)
	expect.falsy(ok2)
end)

test("SceneKit: an entry on the footprint edge is allowed", function()
	local out = SceneKit.expand(
		kit({ { objectId = "a", dx = 6, dz = -3, yaw = 0 } }),
		instance(0, 0, 0, 1),
		"k",
		WIDE
	)
	expect.equal(#out, 1)
end)

test("SceneKit: an entry outside the world bounds is a hard error", function()
	local bounds = { minX = -100, maxX = 100, minZ = -250, maxZ = 250 }
	local ok, message = pcall(function()
		SceneKit.expand(
			kit({ { objectId = "a", dx = 3, dz = 0, yaw = 0 } }),
			instance(99, 0, 0, 1),
			"k",
			bounds
		)
	end)
	expect.falsy(ok)
	expect.truthy(string.find(tostring(message), "bounds", 1, true) ~= nil)
	local inside = SceneKit.expand(
		kit({ { objectId = "a", dx = 1, dz = 0, yaw = 0 } }),
		instance(99, 0, 0, 1),
		"k",
		bounds
	)
	expect.equal(#inside, 1)
end)

test("SceneKit: the footprint check uses kit-local offsets, not world-turned ones", function()
	-- (6, 0) is on the edge in kit space; turned 90 degrees it lands 6 studs along z, which is past halfZ = 3.
	local out = SceneKit.expand(
		kit({ { objectId = "a", dx = 6, dz = 0, yaw = 0 } }),
		instance(0, 0, 90, 1),
		"k",
		WIDE
	)
	expect.near(out[1].z, -6, 1e-9)
end)

return {}
