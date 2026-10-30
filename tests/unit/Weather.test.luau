--!strict
-- Contract tests for src/shared/Rules/Weather.luau (specs/005-theme-art-pipeline/contracts/
-- theme-content.md §6): the emitter runs only without reduce-motion and only for a real weather kind.

local harness = require("./harness")
local Weather = require("../../src/shared/Rules/Weather")

local test, expect = harness.test, harness.expect

test("reduce-motion silences every weather kind", function()
	for _, kind in { "snow", "petals", "leaves", "sparkle", "none" } do
		expect.falsy(Weather.emitting(true, kind))
	end
end)

test("a real weather kind emits when reduce-motion is off", function()
	for _, kind in { "snow", "petals", "leaves", "sparkle" } do
		expect.truthy(Weather.emitting(false, kind))
	end
end)

test("kind none or missing never emits", function()
	expect.falsy(Weather.emitting(false, "none"))
	expect.falsy(Weather.emitting(false, nil))
end)

test("kind none or missing has no motion", function()
	expect.equal(Weather.motion("none"), nil)
	expect.equal(Weather.motion(nil), nil)
end)

test("snow, petals and leaves fall; sparkle rises", function()
	expect.truthy(Weather.motion("snow").falls)
	expect.truthy(Weather.motion("petals").falls)
	expect.truthy(Weather.motion("leaves").falls)
	expect.falsy(Weather.motion("sparkle").falls)
end)

test("each weather kind moves differently", function()
	local seen = {}
	for _, kind in { "snow", "petals", "leaves", "sparkle" } do
		local m = Weather.motion(kind)
		local key = `{m.falls}|{m.accelerationX}|{m.accelerationY}|{m.spin}`
		expect.falsy(seen[key])
		seen[key] = true
	end
end)

test("the rate cap keeps rate x lifetime within maxParticles and the budget", function()
	expect.near(Weather.cappedRate(10, 4, 40, 40), 10, 1e-9)
	expect.near(Weather.cappedRate(10, 4, 20, 40), 5, 1e-9)
	expect.near(Weather.cappedRate(10, 4, 40, 8), 2, 1e-9)
	expect.near(Weather.cappedRate(10, 0, 40, 40), 0, 1e-9)
end)
