--!strict
-- Expected values are hand-written from contracts/rules-api.md §Profile. Never computed from the code under test.

local harness = require("./harness")
local Profile = require("../../src/shared/Rules/Profile")

local test, expect = harness.test, harness.expect

local D = {
	worldsUnlocked = { greybox = true },
	settings = {
		musicVolume = 0.8,
		effectsVolume = 0.8,
		cameraSensitivity = 1,
		reduceMotion = false,
		language = "auto",
	},
}

-- Stable text form of a value (sorted keys) so two tables can be compared in one assertion.
local function serialize(value: any): string
	if type(value) ~= "table" then
		return tostring(value)
	end
	local keys: { string } = {}
	for key in value do
		table.insert(keys, tostring(key))
	end
	table.sort(keys)
	local parts: { string } = {}
	for _, key in keys do
		local child = value[key]
		if child == nil then
			child = value[tonumber(key) :: number]
		end
		table.insert(parts, `{key}={serialize(child)}`)
	end
	return "{" .. table.concat(parts, ",") .. "}"
end

local function isEmpty(t: { [any]: any }): boolean
	return next(t) == nil
end

-- A literal v1 profile, written out so the tests do not depend on Profile.defaults.
local function fresh(): any
	return {
		version = 1,
		coins = 0,
		worldsUnlocked = { greybox = true },
		skinsOwned = {},
		equipped = {},
		book = {},
		bestSize = {},
		receipts = {},
		appliedRuns = {},
		settings = {
			musicVolume = 0.8,
			effectsVolume = 0.8,
			cameraSensitivity = 1,
			reduceMotion = false,
			language = "auto",
		},
	}
end

-- The progress fields a rejected apply must leave alone.
local function progress(data: any): string
	return serialize({
		coins = data.coins,
		bestSize = data.bestSize,
		book = data.book,
		skinsOwned = data.skinsOwned,
		appliedRuns = data.appliedRuns,
	})
end

local function rewardsFor(book: { [string]: boolean }): { string }
	if book["greybox.cube_t1"] then
		return { "r1" }
	end
	return {}
end

local function run(overrides: { [string]: any }?): any
	local result: any = {
		runId = "7-1",
		worldId = "greybox",
		finalDiameter = 3.5,
		coins = 12,
		newBookIds = { "greybox.cube_t1", "greybox.cube_t2" },
	}
	if overrides then
		for key, value in overrides do
			result[key] = value
		end
	end
	return result
end

-- defaults

test("defaults: version 1, empty collections, copied worlds and settings", function()
	local data = Profile.defaults(D)
	expect.equal(data.version, 1)
	expect.equal(data.coins, 0)
	expect.equal(data.worldsUnlocked.greybox, true)
	expect.truthy(isEmpty(data.book))
	expect.truthy(isEmpty(data.bestSize))
	expect.truthy(isEmpty(data.skinsOwned))
	expect.truthy(isEmpty(data.appliedRuns))
	expect.truthy(isEmpty(data.receipts))
	expect.truthy(isEmpty(data.equipped))
	expect.equal(data.settings.musicVolume, 0.8)
	expect.equal(data.settings.effectsVolume, 0.8)
	expect.equal(data.settings.cameraSensitivity, 1)
	expect.equal(data.settings.reduceMotion, false)
	expect.equal(data.settings.language, "auto")
end)

test("defaults: two calls give different tables", function()
	local a = Profile.defaults(D)
	local b = Profile.defaults(D)
	expect.truthy(a ~= b)
	expect.truthy(a.book ~= b.book)
	expect.truthy(a.settings ~= b.settings)
	expect.truthy(a.worldsUnlocked ~= b.worldsUnlocked)
	a.book.x = true
	a.worldsUnlocked.other = true
	expect.equal(b.book.x, nil)
	expect.equal(b.worldsUnlocked.other, nil)
	expect.equal(D.worldsUnlocked.other, nil)
end)

test("constants: schema version is 1 and there is nothing to migrate from", function()
	expect.equal(Profile.SCHEMA_VERSION, 1)
	expect.truthy(isEmpty(Profile.migrations))
end)

-- reconcile

test("reconcile fills: missing keys come from the defaults", function()
	local data: any = { version = 1, coins = 7, settings = { musicVolume = 0.3 } }
	Profile.reconcile(data, D)
	expect.equal(data.coins, 7)
	expect.equal(data.settings.musicVolume, 0.3)
	expect.equal(data.settings.effectsVolume, 0.8)
	expect.equal(data.settings.language, "auto")
	expect.truthy(type(data.book) == "table" and isEmpty(data.book))
	expect.equal(data.worldsUnlocked.greybox, true)
end)

test("reconcile keeps: valid saved values are not changed", function()
	local data: any = {
		version = 1,
		coins = 7,
		book = { a = true },
		bestSize = { greybox = 4.5 },
	}
	Profile.reconcile(data, D)
	expect.equal(data.book.a, true)
	expect.equal(data.bestSize.greybox, 4.5)
	expect.equal(data.coins, 7)
	expect.equal(data.version, 1)
end)

test("reconcile repairs: wrong-typed keys are replaced by the defaults", function()
	local data: any = { version = 1, coins = "12", book = 5 }
	Profile.reconcile(data, D)
	expect.equal(data.coins, 0)
	expect.truthy(type(data.book) == "table" and isEmpty(data.book))
end)

test("reconcile negative: a negative coin count becomes 0", function()
	local data: any = { version = 1, coins = -3 }
	Profile.reconcile(data, D)
	expect.equal(data.coins, 0)
end)

test("reconcile: NaN and infinite coins become 0", function()
	local nan: any = { version = 1, coins = 0 / 0 }
	Profile.reconcile(nan, D)
	expect.equal(nan.coins, 0)
	local inf: any = { version = 1, coins = math.huge }
	Profile.reconcile(inf, D)
	expect.equal(inf.coins, 0)
end)

test("reconcile: a valid fractional coin count is kept as is", function()
	local data: any = { version = 1, coins = 2.5 }
	Profile.reconcile(data, D)
	expect.equal(data.coins, 2.5)
end)

test("reconcile: a wrong-typed setting is replaced field by field", function()
	local data: any = {
		version = 1,
		settings = { musicVolume = "loud", effectsVolume = 0.1, reduceMotion = "yes", language = 5 },
	}
	Profile.reconcile(data, D)
	expect.equal(data.settings.musicVolume, 0.8)
	expect.equal(data.settings.effectsVolume, 0.1)
	expect.equal(data.settings.cameraSensitivity, 1)
	expect.equal(data.settings.reduceMotion, false)
	expect.equal(data.settings.language, "auto")
end)

test("reconcile: settings that are not a table become the default settings", function()
	local data: any = { version = 1, settings = "x" }
	Profile.reconcile(data, D)
	expect.equal(data.settings.musicVolume, 0.8)
	expect.equal(data.settings.language, "auto")
end)

test("reconcile: never looks inside book, bestSize or skinsOwned", function()
	local data: any = {
		version = 1,
		book = { a = "not a boolean" },
		bestSize = { greybox = "big" },
		skinsOwned = { r1 = 3 },
	}
	Profile.reconcile(data, D)
	expect.equal(data.book.a, "not a boolean")
	expect.equal(data.bestSize.greybox, "big")
	expect.equal(data.skinsOwned.r1, 3)
end)

test("reconcile: leaves version alone, even when it is missing or wrong", function()
	local missing: any = { coins = 1 }
	Profile.reconcile(missing, D)
	expect.equal(missing.version, nil)
	local wrong: any = { version = "x" }
	Profile.reconcile(wrong, D)
	expect.equal(wrong.version, "x")
end)

test("reconcile: does not alias the defaults argument", function()
	local data: any = {}
	Profile.reconcile(data, D)
	data.worldsUnlocked.other = true
	data.settings.musicVolume = 0.1
	expect.equal(D.worldsUnlocked.other, nil)
	expect.equal(D.settings.musicVolume, 0.8)
end)

-- prepare

test("prepare new: an empty table becomes the default profile", function()
	local data: any = {}
	local ok, reason = Profile.prepare(data, D)
	expect.equal(ok, true)
	expect.equal(reason, nil)
	expect.equal(data.version, 1)
	expect.equal(serialize(data), serialize(fresh()))
end)

test("prepare v1 unchanged: saved values survive and appliedRuns is emptied", function()
	local data: any = {
		version = 1,
		coins = 5,
		book = { a = true },
		appliedRuns = { ["1-1"] = true },
	}
	local ok = Profile.prepare(data, D)
	expect.equal(ok, true)
	expect.equal(data.coins, 5)
	expect.equal(data.book.a, true)
	expect.truthy(isEmpty(data.appliedRuns))
	expect.equal(data.version, 1)
end)

test("prepare future: a newer version is refused and left untouched", function()
	local data: any = { version = 2, coins = 5 }
	local ok, reason = Profile.prepare(data, D)
	expect.equal(ok, false)
	expect.equal(reason, "FutureVersion")
	expect.equal(data.coins, 5)
	expect.equal(data.version, 2)
end)

test("prepare bad: a non-numeric version is refused", function()
	local data: any = { version = "x" }
	local ok, reason = Profile.prepare(data, D)
	expect.equal(ok, false)
	expect.equal(reason, "BadVersion")
end)

test("prepare zero: version 0 is refused", function()
	local data: any = { version = 0 }
	local ok, reason = Profile.prepare(data, D)
	expect.equal(ok, false)
	expect.equal(reason, "BadVersion")
end)

test("prepare: a refused profile is not reconciled", function()
	local data: any = { version = 2 }
	Profile.prepare(data, D)
	expect.equal(data.coins, nil)
	expect.equal(data.settings, nil)
end)

-- migrate

test("migrate mechanism: a registered step runs and the version moves up", function()
	local data: any = { version = 1, coins = 5 }
	local migrations = {
		[1] = function(d: any)
			d.coins = d.coins * 2
		end,
	}
	local ok, reason = Profile.migrate(data, migrations, 2)
	expect.equal(ok, true)
	expect.equal(reason, nil)
	expect.equal(data.coins, 10)
	expect.equal(data.version, 2)
end)

test("migrate two steps: both run in order", function()
	local data: any = { version = 1 }
	local migrations = {
		[1] = function(d: any)
			d.a = 1
		end,
		[2] = function(d: any)
			d.b = 2
		end,
	}
	local ok = Profile.migrate(data, migrations, 3)
	expect.equal(ok, true)
	expect.equal(data.a, 1)
	expect.equal(data.b, 2)
	expect.equal(data.version, 3)
end)

test("migrate missing: a step with no function stops with MissingMigration", function()
	local data: any = { version = 1 }
	local ok, reason = Profile.migrate(data, {}, 2)
	expect.equal(ok, false)
	expect.equal(reason, "MissingMigration")
	expect.equal(data.version, 1)
end)

test("migrate missing: data stays as it was at the failing step", function()
	local data: any = { version = 1 }
	local migrations = {
		[1] = function(d: any)
			d.a = 1
		end,
	}
	local ok, reason = Profile.migrate(data, migrations, 3)
	expect.equal(ok, false)
	expect.equal(reason, "MissingMigration")
	expect.equal(data.a, 1)
	expect.equal(data.version, 2)
end)

test("migrate v1 identity: nothing to do at the current version", function()
	local data: any = { version = 1, coins = 9 }
	local ok = Profile.migrate(data, Profile.migrations, 1)
	expect.equal(ok, true)
	expect.equal(data.coins, 9)
	expect.equal(data.version, 1)
end)

test("migrate: bad versions are refused", function()
	for _, bad in { "x", 0, -1, 1.5, 0 / 0, math.huge } do
		local data: any = { version = bad }
		local ok, reason = Profile.migrate(data, {}, 1)
		expect.equal(ok, false)
		expect.equal(reason, "BadVersion")
	end
	local missing: any = {}
	local ok, reason = Profile.migrate(missing, {}, 1)
	expect.equal(ok, false)
	expect.equal(reason, "BadVersion")
end)

test("migrate: a version above the target is FutureVersion", function()
	local data: any = { version = 3, coins = 1 }
	local ok, reason = Profile.migrate(data, {}, 2)
	expect.equal(ok, false)
	expect.equal(reason, "FutureVersion")
	expect.equal(data.version, 3)
end)

-- applyRunResult

test("A1: first run applies coins, best size, book entries and the reward", function()
	local data = fresh()
	local outcome = Profile.applyRunResult(data, run(), rewardsFor)
	expect.equal(outcome.applied, true)
	expect.equal(outcome.reason, nil)
	expect.equal(outcome.isFirstRun, true)
	expect.equal(outcome.coinsGained, 12)
	expect.equal(outcome.coinsTotal, 12)
	expect.equal(outcome.bestSize, 3.5)
	expect.same(outcome.newBookIds, { "greybox.cube_t1", "greybox.cube_t2" })
	expect.same(outcome.newRewardIds, { "r1" })
	expect.equal(data.coins, 12)
	expect.equal(data.bestSize.greybox, 3.5)
	expect.equal(data.book["greybox.cube_t1"], true)
	expect.equal(data.book["greybox.cube_t2"], true)
	expect.equal(data.skinsOwned.r1, true)
	expect.equal(data.appliedRuns["7-1"], true)
end)

test("A2: second run adds coins, keeps the larger best size, lists no new entries", function()
	local data = fresh()
	Profile.applyRunResult(data, run(), rewardsFor)
	local outcome = Profile.applyRunResult(
		data,
		run({ runId = "7-2", finalDiameter = 2.75, coins = 8, newBookIds = { "greybox.cube_t1" } }),
		rewardsFor
	)
	expect.equal(outcome.applied, true)
	expect.equal(outcome.isFirstRun, false)
	expect.equal(outcome.coinsGained, 8)
	expect.equal(outcome.coinsTotal, 20)
	expect.equal(outcome.bestSize, 3.5)
	expect.same(outcome.newBookIds, {})
	expect.same(outcome.newRewardIds, {})
	expect.equal(data.coins, 20)
	expect.equal(data.bestSize.greybox, 3.5)
end)

test("A3: the same run again is a Duplicate and changes nothing", function()
	local data = fresh()
	Profile.applyRunResult(data, run(), rewardsFor)
	Profile.applyRunResult(
		data,
		run({ runId = "7-2", finalDiameter = 2.75, coins = 8, newBookIds = { "greybox.cube_t1" } }),
		rewardsFor
	)
	local before = progress(data)
	local outcome = Profile.applyRunResult(data, run(), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.reason, "Duplicate")
	expect.equal(outcome.coinsGained, 0)
	expect.equal(outcome.coinsTotal, 20)
	expect.equal(outcome.bestSize, 3.5)
	expect.same(outcome.newBookIds, {})
	expect.same(outcome.newRewardIds, {})
	expect.equal(data.coins, 20)
	expect.equal(progress(data), before)
end)

test("A4: negative coins add nothing", function()
	local data = fresh()
	data.coins = 4
	local outcome = Profile.applyRunResult(data, run({ coins = -5 }), rewardsFor)
	expect.equal(outcome.applied, true)
	expect.equal(outcome.coinsGained, 0)
	expect.equal(data.coins, 4)
	expect.equal(outcome.coinsTotal, 4)
end)

test("A5: fractional coins are floored", function()
	local data = fresh()
	local outcome = Profile.applyRunResult(data, run({ coins = 3.7 }), rewardsFor)
	expect.equal(outcome.coinsGained, 3)
	expect.equal(data.coins, 3)
end)

test("A6: NaN coins are Invalid and change nothing", function()
	local data = fresh()
	local before = progress(data)
	local outcome = Profile.applyRunResult(data, run({ coins = 0 / 0 }), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.reason, "Invalid")
	expect.equal(progress(data), before)
end)

test("A7: an empty runId is Invalid", function()
	local data = fresh()
	local before = progress(data)
	local outcome = Profile.applyRunResult(data, run({ runId = "" }), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.reason, "Invalid")
	expect.equal(progress(data), before)
end)

test("A8: a final diameter of 0 is Invalid", function()
	local data = fresh()
	local before = progress(data)
	local outcome = Profile.applyRunResult(data, run({ finalDiameter = 0 }), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.reason, "Invalid")
	expect.equal(progress(data), before)
end)

test("A9: a NaN final diameter is Invalid", function()
	local data = fresh()
	local before = progress(data)
	local outcome = Profile.applyRunResult(data, run({ finalDiameter = 0 / 0 }), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.reason, "Invalid")
	expect.equal(progress(data), before)
end)

test("A10: a non-string worldId is Invalid", function()
	local data = fresh()
	local before = progress(data)
	local outcome = Profile.applyRunResult(data, run({ worldId = 5 }), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.reason, "Invalid")
	expect.equal(progress(data), before)
end)

test("Invalid: the other malformed fields are refused and write nothing", function()
	local bad = {
		{ runId = 5 },
		{ worldId = "" },
		{ finalDiameter = -1 },
		{ finalDiameter = math.huge },
		{ finalDiameter = "3" },
		{ coins = math.huge },
		{ coins = "12" },
		{ newBookIds = "x" },
		{ newBookIds = { 1, 2 } },
		{ newBookIds = false },
	}
	for index, overrides in bad do
		local data = fresh()
		local before = progress(data)
		local outcome = Profile.applyRunResult(data, run(overrides), rewardsFor)
		expect.equal(outcome.applied, false, `case {index}`)
		expect.equal(outcome.reason, "Invalid")
		expect.equal(progress(data), before)
	end
end)

test("A11: two worlds keep separate best sizes", function()
	local data = fresh()
	local first = Profile.applyRunResult(
		data,
		run({ runId = "a-1", worldId = "greybox", finalDiameter = 3.5, newBookIds = {} }),
		rewardsFor
	)
	local second = Profile.applyRunResult(
		data,
		run({ runId = "a-2", worldId = "snow", finalDiameter = 2.5, newBookIds = {} }),
		rewardsFor
	)
	expect.equal(first.isFirstRun, true)
	expect.equal(second.isFirstRun, false)
	expect.equal(data.bestSize.greybox, 3.5)
	expect.equal(data.bestSize.snow, 2.5)
	expect.equal(second.bestSize, 2.5)
end)

test("A12: a repeated id in newBookIds is inserted once", function()
	local data = fresh()
	local outcome = Profile.applyRunResult(data, run({ newBookIds = { "x", "x" } }), rewardsFor)
	expect.equal(data.book.x, true)
	expect.same(outcome.newBookIds, { "x" })
end)

test("A13: an owned reward is not granted again", function()
	local data = fresh()
	data.skinsOwned.r1 = true
	local outcome =
		Profile.applyRunResult(data, run({ newBookIds = { "greybox.cube_t1" } }), rewardsFor)
	expect.equal(outcome.applied, true)
	expect.same(outcome.newRewardIds, {})
	expect.equal(data.skinsOwned.r1, true)
end)

test("apply: a book entry already saved is not listed as new", function()
	local data = fresh()
	data.book["greybox.cube_t1"] = true
	local outcome = Profile.applyRunResult(
		data,
		run({ newBookIds = { "greybox.cube_t1", "greybox.cube_t2" } }),
		rewardsFor
	)
	expect.same(outcome.newBookIds, { "greybox.cube_t2" })
	expect.same(outcome.newRewardIds, { "r1" })
end)

test("apply: best size never decreases and equal size keeps the value", function()
	local data = fresh()
	data.bestSize.greybox = 9
	Profile.applyRunResult(
		data,
		run({ runId = "b-1", finalDiameter = 4, newBookIds = {} }),
		rewardsFor
	)
	expect.equal(data.bestSize.greybox, 9)
	Profile.applyRunResult(
		data,
		run({ runId = "b-2", finalDiameter = 9, newBookIds = {} }),
		rewardsFor
	)
	expect.equal(data.bestSize.greybox, 9)
	Profile.applyRunResult(
		data,
		run({ runId = "b-3", finalDiameter = 10, newBookIds = {} }),
		rewardsFor
	)
	expect.equal(data.bestSize.greybox, 10)
end)

test("apply: a stored best size makes the run not the first", function()
	local data = fresh()
	data.bestSize.snow = 2
	local outcome = Profile.applyRunResult(data, run({ newBookIds = {} }), rewardsFor)
	expect.equal(outcome.isFirstRun, false)
end)

test("apply: a rejected call reports the stored coins and best size", function()
	local data = fresh()
	data.coins = 6
	data.bestSize.greybox = 4.25
	local outcome = Profile.applyRunResult(data, run({ runId = "" }), rewardsFor)
	expect.equal(outcome.applied, false)
	expect.equal(outcome.coinsTotal, 6)
	expect.equal(outcome.bestSize, 4.25)
	expect.equal(outcome.coinsGained, 0)
	expect.equal(outcome.isFirstRun, false)
end)

test("apply: rewardsFor sees the book after this run's entries are added", function()
	local data = fresh()
	local seen: { [string]: boolean }? = nil
	Profile.applyRunResult(data, run({ newBookIds = { "q" } }), function(book)
		seen = table.clone(book)
		return {}
	end)
	expect.truthy(seen)
	expect.equal((seen :: any).q, true)
end)

test("apply: coins stay at zero or more over a run of mixed results", function()
	local data = fresh()
	for index, coins in { -10, 5, -1, 0, 2.9 } do
		Profile.applyRunResult(
			data,
			run({ runId = `c-{index}`, coins = coins, newBookIds = {} }),
			rewardsFor
		)
		expect.truthy(data.coins >= 0)
	end
	expect.equal(data.coins, 7)
end)

return {}
