--!strict
-- Expected values are written out by hand from contracts/rules-api.md (RunClock table).

local harness = require("./harness")
local RunClock = require("../../src/shared/Rules/RunClock")

local test, expect = harness.test, harness.expect

test("remaining: counts down and never goes below 0", function()
	expect.equal(RunClock.remaining(10, 250), 240)
	expect.equal(RunClock.remaining(300, 250), 0)
end)

test("expired: false just before the end, true at the end", function()
	expect.falsy(RunClock.expired(249.999, 250))
	expect.truthy(RunClock.expired(250, 250))
end)

test("format: rounds up to whole seconds as mm:ss", function()
	expect.equal(RunClock.format(240), "04:00")
	expect.equal(RunClock.format(239.2), "04:00")
	expect.equal(RunClock.format(239), "03:59")
	expect.equal(RunClock.format(61), "01:01")
	expect.equal(RunClock.format(60.5), "01:01")
	expect.equal(RunClock.format(59.01), "01:00")
	expect.equal(RunClock.format(0.4), "00:01")
end)

test("format: zero and negative show 00:00, long runs keep the minutes", function()
	expect.equal(RunClock.format(0), "00:00")
	expect.equal(RunClock.format(-3), "00:00")
	expect.equal(RunClock.format(600), "10:00")
end)

test("uiLocked: true for the first lockSeconds of a 240 s run, then false", function()
	local duration, endsAt, lockSeconds = 240, 240, 5
	expect.truthy(RunClock.uiLocked(0, endsAt, duration, lockSeconds))
	expect.truthy(RunClock.uiLocked(4.99, endsAt, duration, lockSeconds))
	expect.falsy(RunClock.uiLocked(5, endsAt, duration, lockSeconds))
	expect.falsy(RunClock.uiLocked(100, endsAt, duration, lockSeconds))
	expect.falsy(RunClock.uiLocked(240, endsAt, duration, lockSeconds))
end)

test("uiLocked: past the end is unlocked, before the start is locked", function()
	expect.falsy(RunClock.uiLocked(300, 240, 240, 5))
	expect.truthy(RunClock.uiLocked(-1, 240, 240, 5))
end)

return {}
