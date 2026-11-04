--!strict
-- Expected values are hand-computed from specs/010-main-street-slice/contracts/heap-rules.md.

local harness = require("./harness")
local Config = require("../../src/shared/Config")
local Heap = require("../../src/shared/Rules/Heap")

local test, expect = harness.test, harness.expect

local function entry(key: string, size: number, tier: number, age: number): Heap.HeapEntry
	return { key = key, id = key, size = size, tier = tier, age = age }
end

local function keys(list: { Heap.HeapEntry }): { string }
	local out = {}
	for _, e in list do
		table.insert(out, e.key)
	end
	return out
end

test("score: size over one plus age", function()
	expect.equal(Heap.score(entry("a", 2, 1, 0)), 2)
	expect.equal(Heap.score(entry("a", 2, 1, 1)), 1)
	expect.equal(Heap.score(entry("a", 3, 1, 2)), 1)
end)

test("select: a new large item beats an old small one at cap 1", function()
	local result = Heap.select(
		{ entry("old", 0.5, 1, 9), entry("new", 1.5, 1, 0) },
		{ cap = 1, protectTier = 4 }
	)
	expect.same(keys(result.outer), { "new" })
	expect.same(keys(result.buried), { "old" })
end)

test("select: order is best score first", function()
	-- scores: a 1/(1+0)=1, b 3/(1+2)=1 (tie, key order), c 2/(1+0)=2
	local result = Heap.select(
		{ entry("a", 1, 1, 0), entry("b", 3, 1, 2), entry("c", 2, 1, 0) },
		{ cap = 3, protectTier = 4 }
	)
	expect.same(keys(result.outer), { "c", "a", "b" })
	expect.same(keys(result.buried), {})
end)

test("select: ties break by key, whatever the input order", function()
	local one = Heap.select(
		{ entry("b", 1, 1, 0), entry("a", 1, 1, 0) },
		{ cap = 1, protectTier = 4 }
	)
	local two = Heap.select(
		{ entry("a", 1, 1, 0), entry("b", 1, 1, 0) },
		{ cap = 1, protectTier = 4 }
	)
	expect.same(keys(one.outer), { "a" })
	expect.same(keys(two.outer), { "a" })
	expect.same(keys(one.buried), { "b" })
end)

test("select: tier 4 and above stay outside while protected count fits the cap", function()
	local result = Heap.select({
		entry("bus", 0.1, 4, 50),
		entry("big1", 2, 1, 0),
		entry("big2", 2, 1, 0),
		entry("big3", 2, 1, 0),
	}, { cap = 2, protectTier = 4 })
	expect.equal(#result.outer, 2)
	expect.equal(table.find(keys(result.outer), "bus") ~= nil, true)
end)

test("select: more protected items than cap keeps the best protected ones", function()
	local result = Heap.select({
		entry("p1", 10, 4, 0),
		entry("p2", 20, 5, 0),
		entry("p3", 5, 4, 0),
		entry("small", 99, 1, 0),
	}, { cap = 2, protectTier = 4 })
	expect.same(keys(result.outer), { "p2", "p1" })
	expect.same(keys(result.buried), { "small", "p3" })
end)

test("select: under the cap nothing is buried and the input is untouched", function()
	local input = { entry("b", 1, 1, 0), entry("a", 2, 1, 0) }
	local result = Heap.select(input, { cap = 5, protectTier = 4 })
	expect.equal(#result.outer, 2)
	expect.equal(#result.buried, 0)
	expect.equal(input[1].key, "b")
end)

test("select: is deterministic over repeated runs", function()
	local input = {}
	for i = 1, 60 do
		table.insert(input, entry(`k{i}`, (i % 7) / 4 + 0.3, (i % 5) + 1, 60 - i))
	end
	local a = Heap.select(input, { cap = 40, protectTier = 4 })
	local b = Heap.select(input, { cap = 40, protectTier = 4 })
	expect.same(keys(a.outer), keys(b.outer))
	expect.equal(#a.outer, 40)
	expect.equal(#a.buried, 20)
end)

test("coverage: hand-computed discs over the sphere", function()
	-- D = 5: sphere area 25 pi. Ten patches of diameter 2: 10 * pi = 0.4 of it.
	local outer = {}
	for i = 1, 10 do
		table.insert(outer, entry(`k{i}`, 1, 1, 0))
	end
	local covered = Heap.coverage(5, outer, function()
		return 2
	end)
	expect.near(covered, 0.4, 1e-9)
end)

test("coverage: clamped to 1 and 0 for an empty heap", function()
	local outer = { entry("a", 1, 1, 0) }
	expect.equal(
		Heap.coverage(1, outer, function()
			return 10
		end),
		1
	)
	expect.equal(
		Heap.coverage(5, {}, function()
			return 2
		end),
		0
	)
end)

test("coverage: the default local cap hides at least the target at the target diameter", function()
	-- 40 items of footprint 1.5 at D = 5: 40 * pi * 0.5625 / (25 pi) = 0.9.
	local outer = {}
	for i = 1, Config.heapLocalCap do
		table.insert(outer, entry(`k{i}`, 1.5, 1, 0))
	end
	local covered = Heap.coverage(Config.heapCoverageTargetD, outer, function(e)
		return e.size
	end)
	expect.near(covered, 0.9, 1e-9)
	expect.equal(covered >= Config.heapCoverageTarget, true)
end)

test(
	"coverage: the remote cap alone is below the target, so remote balls rely on the core colour",
	function()
		local outer = {}
		for i = 1, Config.heapRemoteCap do
			table.insert(outer, entry(`k{i}`, 1.5, 1, 0))
		end
		local covered = Heap.coverage(Config.heapCoverageTargetD, outer, function(e)
			return e.size
		end)
		-- 12 * 0.5625 / 25 = 0.27
		expect.near(covered, 0.27, 1e-9)
	end
)

test("coreColor: mean of the buried colours", function()
	local palette: { [string]: Heap.Colour } = {
		a = { r = 1, g = 0, b = 0 },
		b = { r = 0, g = 1, b = 0 },
		c = { r = 0, g = 0, b = 1 },
		d = { r = 1, g = 1, b = 1 },
	}
	local buried =
		{ entry("a", 1, 1, 0), entry("b", 1, 1, 0), entry("c", 1, 1, 0), entry("d", 1, 1, 0) }
	local result = Heap.coreColor(buried, function(e)
		return palette[e.key]
	end)
	expect.near(result.r, 0.5, 1e-9)
	expect.near(result.g, 0.5, 1e-9)
	expect.near(result.b, 0.5, 1e-9)
end)

test("coreColor: nothing buried is neutral grey", function()
	local result = Heap.coreColor({}, function()
		return { r = 1, g = 0, b = 0 }
	end)
	expect.same(result, { r = 0.5, g = 0.5, b = 0.5 })
end)

test("buryProgress: linear and clamped", function()
	expect.near(Heap.buryProgress(0.1, 0.4), 0.25, 1e-9)
	expect.equal(Heap.buryProgress(0, 0.4), 0)
	expect.equal(Heap.buryProgress(0.8, 0.4), 1)
	expect.equal(Heap.buryProgress(-1, 0.4), 0)
	expect.equal(Heap.buryProgress(0.1, 0), 1)
end)
