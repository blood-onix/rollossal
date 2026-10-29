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
