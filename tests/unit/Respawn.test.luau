--!strict
-- Expected values are worked out by hand in specs/004-snow-village/contracts/rules-api.md (Respawn).

local harness = require("./harness")
local Respawn = require("../../src/shared/Rules/Respawn")

local test, expect = harness.test, harness.expect

local params: Respawn.SightParams = { radius = 45, viewDistance = 120, viewCos = 0.5 }
local watcher: Respawn.Watcher = { x = 0, z = 0, hx = 1, hz = 0 }
local watchers = { watcher }

local function seen(x: number, z: number, list: { Respawn.Watcher }?): boolean
	return Respawn.isSeen({ x = x, z = z }, list or watchers, params)
end

test("isSeen: radius boundary is inclusive", function()
	expect.truthy(seen(45, 0))
	expect.falsy(seen(0, 46))
end)

test("isSeen: view distance boundary is inclusive", function()
	expect.truthy(seen(120, 0))
	expect.falsy(seen(121, 0))
end)

test("isSeen: behind and beside the heading are not seen", function()
	expect.falsy(seen(-100, 0))
	expect.falsy(seen(0, 100))
end)

test("isSeen: inside the cone is seen", function()
	expect.truthy(seen(60, 60))
	expect.truthy(seen(50, 86.6))
	expect.falsy(seen(49, 86.6))
end)

test("isSeen: a watcher with no heading only sees inside the radius", function()
	local still: { Respawn.Watcher } = { { x = 0, z = 0, hx = 0, hz = 0 } }
	expect.falsy(seen(100, 0, still))
	expect.truthy(seen(30, 0, still))
end)

test("isSeen: a point exactly on a watcher is seen", function()
	expect.truthy(seen(0, 0))
	local still: { Respawn.Watcher } = { { x = 0, z = 0, hx = 0, hz = 0 } }
	expect.truthy(seen(0, 0, still))
end)

test("isSeen: no watchers means not seen", function()
	expect.falsy(seen(0, 0, {}))
end)

test("isSeen: any one of several watchers is enough", function()
	local both: { Respawn.Watcher } = { watcher, { x = 500, z = 500, hx = 0, hz = 0 } }
	expect.truthy(seen(510, 500, both))
	expect.falsy(seen(300, 300, both))
end)

test("delayFrom: interpolates and clamps the unit number", function()
	expect.equal(Respawn.delayFrom(0, 60, 120), 60)
	expect.equal(Respawn.delayFrom(0.5, 60, 120), 90)
	expect.equal(Respawn.delayFrom(1, 60, 120), 120)
	expect.equal(Respawn.delayFrom(2, 60, 120), 120)
	expect.equal(Respawn.delayFrom(-1, 60, 120), 60)
end)

local function canRespawn(now: number, list: { Respawn.Watcher }): boolean
	return Respawn.canRespawn(now, 0, 100, { x = 10, z = 0 }, list, params, 180)
end

test("canRespawn: too early", function()
	expect.falsy(canRespawn(99.99, {}))
end)

test("canRespawn: due and unseen", function()
	expect.truthy(canRespawn(100, {}))
end)

test("canRespawn: due but watched waits", function()
	expect.falsy(canRespawn(100, watchers))
	expect.falsy(canRespawn(179.99, watchers))
end)

test("canRespawn: starvation ceiling ignores sight", function()
	expect.truthy(canRespawn(180, watchers))
end)

return {}
