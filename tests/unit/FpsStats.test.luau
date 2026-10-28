--!strict

local harness = require("./harness")
local FpsStats = require("../../src/shared/Rules/FpsStats")

local test, expect = harness.test, harness.expect

test("record: readings inside the warm-up are not counted", function()
	local stats = FpsStats.new(100, 5)
	FpsStats.record(stats, 102, 10)
	FpsStats.record(stats, 104.9, 12)
	expect.equal(stats.seconds, 0)
	expect.equal(FpsStats.lowest(stats, 55), 55)
	expect.equal(FpsStats.average(stats, 55), 55)
end)

test("record: the warm-up boundary is inclusive and lowest and average follow", function()
	local stats = FpsStats.new(100, 5)
	FpsStats.record(stats, 105, 60)
	FpsStats.record(stats, 106, 22)
	FpsStats.record(stats, 107, 58)
	expect.equal(stats.seconds, 3)
	expect.equal(FpsStats.lowest(stats, 58), 22)
	expect.equal(FpsStats.average(stats, 58), 140 / 3)
end)

test("reset: clears the window and starts a new warm-up", function()
	local stats = FpsStats.new(0, 5)
	FpsStats.record(stats, 10, 20)
	FpsStats.reset(stats, 50, 5)
	expect.equal(stats.seconds, 0)
	expect.equal(FpsStats.lowest(stats, 59), 59)
	FpsStats.record(stats, 54, 15)
	expect.equal(stats.seconds, 0)
	FpsStats.record(stats, 55, 45)
	expect.equal(FpsStats.lowest(stats, 59), 45)
end)

test("visibleTo: only the creator, and only with the flag on", function()
	expect.truthy(FpsStats.visibleTo(true, 7, 7))
	expect.falsy(FpsStats.visibleTo(false, 7, 7))
	expect.falsy(FpsStats.visibleTo(true, 7, 8))
	expect.falsy(FpsStats.visibleTo(true, 0, 8))
end)

return {}
