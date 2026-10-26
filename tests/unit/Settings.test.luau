--!strict
-- Expected values are hand-written from contracts/rules-api.md §Settings. Never computed from the code under test.

local harness = require("./harness")
local Settings = require("../../src/shared/Rules/Settings")

local test, expect = harness.test, harness.expect

local bounds = {
	musicVolume = { min = 0, max = 1 },
	effectsVolume = { min = 0, max = 1 },
	cameraSensitivity = { min = 0.5, max = 2 },
	languages = { "auto", "en-us", "es-es" },
}

local function newCurrent(): any
	return {
		musicVolume = 0.8,
		effectsVolume = 0.8,
		cameraSensitivity = 1,
		reduceMotion = false,
		language = "auto",
	}
end

-- Asserts the result equals the baseline except for the listed overrides.
local function expectResult(result: any, changes: { [string]: any })
	local expected = newCurrent()
	for key, value in changes do
		expected[key] = value
	end
	for _, key in
		{ "musicVolume", "effectsVolume", "cameraSensitivity", "reduceMotion", "language" }
	do
		expect.equal(result[key], expected[key], key)
	end
end

local function check(candidate: unknown, changes: { [string]: any })
	local current = newCurrent()
	local result = Settings.validate(current, candidate, bounds)
	expectResult(result, changes)
end

test("validate: musicVolume 0.25 is applied", function()
	check({ musicVolume = 0.25 }, { musicVolume = 0.25 })
end)

test("validate: musicVolume 1.5 clamps to 1", function()
	check({ musicVolume = 1.5 }, { musicVolume = 1 })
end)

test("validate: musicVolume -0.2 clamps to 0", function()
	check({ musicVolume = -0.2 }, { musicVolume = 0 })
end)

test("validate: effectsVolume 0 is applied", function()
	check({ effectsVolume = 0 }, { effectsVolume = 0 })
end)

test("validate: cameraSensitivity 0.1 clamps to 0.5", function()
	check({ cameraSensitivity = 0.1 }, { cameraSensitivity = 0.5 })
end)

test("validate: cameraSensitivity 3 clamps to 2", function()
	check({ cameraSensitivity = 3 }, { cameraSensitivity = 2 })
end)

test("validate: cameraSensitivity 1.25 is applied", function()
	check({ cameraSensitivity = 1.25 }, { cameraSensitivity = 1.25 })
end)

test("validate: reduceMotion true is applied", function()
	check({ reduceMotion = true }, { reduceMotion = true })
end)

test('validate: reduceMotion "yes" is ignored', function()
	check({ reduceMotion = "yes" }, {})
end)

test("validate: language es-es is applied", function()
	check({ language = "es-es" }, { language = "es-es" })
end)

test("validate: language fr-fr is ignored", function()
	check({ language = "fr-fr" }, {})
end)

test("validate: language ES-ES is ignored (case-sensitive)", function()
	check({ language = "ES-ES" }, {})
end)

test("validate: NaN is ignored", function()
	check({ musicVolume = 0 / 0 }, {})
end)

test("validate: infinity is ignored, not clamped", function()
	check({ musicVolume = math.huge }, {})
	check({ musicVolume = -math.huge }, {})
end)

test("validate: a numeric string is ignored", function()
	check({ musicVolume = "0.5" }, {})
end)

test("validate: an unknown key is ignored", function()
	check({ volume = 3 }, {})
end)

test("validate: fields are independent", function()
	check(
		{ musicVolume = 0.5, language = "xx", reduceMotion = true },
		{ musicVolume = 0.5, reduceMotion = true }
	)
end)

test("validate: a non-table candidate returns a copy of current", function()
	check("hello", {})
	check(5, {})
	check(nil, {})
	check(true, {})
end)

test("validate: an empty table changes nothing", function()
	check({}, {})
end)

test("validate: the result is a new table and current is unchanged", function()
	local current = newCurrent()
	local result = Settings.validate(current, { musicVolume = 0.1, language = "en-us" }, bounds)
	expect.truthy(result ~= current)
	expect.equal(current.musicVolume, 0.8)
	expect.equal(current.language, "auto")
	local copy = Settings.validate(current, "hello", bounds)
	expect.truthy(copy ~= current)
end)

test("validate: the candidate table is not mutated", function()
	local candidate: any = { musicVolume = 9, language = "xx", bogus = 1 }
	Settings.validate(newCurrent(), candidate, bounds)
	expect.equal(candidate.musicVolume, 9)
	expect.equal(candidate.language, "xx")
	expect.equal(candidate.bogus, 1)
end)

test("validate: values at the exact bounds are kept", function()
	check({ musicVolume = 0, effectsVolume = 1, cameraSensitivity = 0.5 }, {
		musicVolume = 0,
		effectsVolume = 1,
		cameraSensitivity = 0.5,
	})
	check({ cameraSensitivity = 2 }, { cameraSensitivity = 2 })
end)

test("validate: every listed language is accepted", function()
	check({ language = "en-us" }, { language = "en-us" })
	check({ language = "auto" }, {})
end)

test("validate: the result holds exactly the five settings", function()
	local result: any = Settings.validate(newCurrent(), { bogus = 1, volume = 3 }, bounds)
	local count = 0
	for _ in result do
		count += 1
	end
	expect.equal(count, 5)
end)

return {}
