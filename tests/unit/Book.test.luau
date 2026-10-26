--!strict
-- Expected values are hand-written from contracts/rules-api.md §Book. Never computed from the code under test.

local harness = require("./harness")
local Book = require("../../src/shared/Rules/Book")

local test, expect = harness.test, harness.expect

local tier1: any = {
	tier = 1,
	nameKey = "t1",
	reward = { rewardId = "r1", rewardType = "trail", nameKey = "rn1" },
}
local tier2: any = { tier = 2, nameKey = "t2" }

local function newTiers(): any
	return {
		{
			tier = 1,
			nameKey = "t1",
			reward = { rewardId = "r1", rewardType = "trail", nameKey = "rn1" },
		},
		{ tier = 2, nameKey = "t2" },
	}
end

local function newObjects(): any
	return {
		{ bookId = "a", tier = 1, nameKey = "na", icon = "ia" },
		{ bookId = "b", tier = 1, nameKey = "nb", icon = "ib" },
		{ bookId = "c", tier = 1, nameKey = "nc", icon = "ic" },
		{ bookId = "d", tier = 1, nameKey = "nd", icon = "id" },
		{ bookId = "e", tier = 2, nameKey = "ne", icon = "ie" },
	}
end

local function flags(entries: { any }): { boolean }
	local out: { boolean } = {}
	for _, entry in entries do
		table.insert(out, entry.isDiscovered)
	end
	return out
end

local function sameFlags(actual: { boolean }, expected: { boolean })
	expect.equal(#actual, #expected)
	for i, value in expected do
		expect.equal(actual[i], value)
	end
end

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

-- newIds

test("newIds: keeps first-seen order, drops duplicates and ids already in the book", function()
	expect.same(Book.newIds({ "b", "z", "b", "a" }, { a = true }), { "b", "z" })
end)

test("newIds empty: nothing in, nothing out", function()
	expect.same(Book.newIds({}, {}), {})
end)

test("newIds: everything new comes back in order", function()
	expect.same(Book.newIds({ "c", "a", "b" }, {}), { "c", "a", "b" })
end)

-- pages

test("pages partial: counts, reward state and discovered flags", function()
	local pages = Book.pages(newTiers(), newObjects(), { a = true, c = true }, {})
	expect.equal(#pages, 2)
	local page1 = pages[1]
	expect.equal(page1.tier, 1)
	expect.equal(page1.nameKey, "t1")
	expect.equal(page1.collectedCount, 2)
	expect.equal(page1.totalCount, 4)
	expect.equal(page1.isComplete, false)
	expect.equal(page1.rewardId, "r1")
	expect.equal(page1.rewardType, "trail")
	expect.equal(page1.rewardNameKey, "rn1")
	expect.equal(page1.rewardEarned, false)
	sameFlags(flags(page1.entries), { true, false, true, false })
	local page2 = pages[2]
	expect.equal(page2.tier, 2)
	expect.equal(page2.collectedCount, 0)
	expect.equal(page2.totalCount, 1)
	expect.equal(page2.isComplete, false)
	expect.equal(page2.rewardId, nil)
	expect.equal(page2.rewardType, nil)
	expect.equal(page2.rewardNameKey, nil)
	expect.equal(page2.rewardEarned, false)
end)

test("pages complete: both pages complete and only tier 1 has a reward id", function()
	local book = { a = true, b = true, c = true, d = true, e = true }
	local pages = Book.pages(newTiers(), newObjects(), book, {})
	expect.equal(pages[1].isComplete, true)
	expect.equal(pages[1].collectedCount, 4)
	expect.equal(pages[2].isComplete, true)
	expect.equal(pages[2].collectedCount, 1)
	expect.same(Book.completedRewardIds(newTiers(), newObjects(), book), { "r1" })
end)

test("reward earned: a complete page whose reward is owned", function()
	local book = { a = true, b = true, c = true, d = true }
	local pages = Book.pages(newTiers(), newObjects(), book, { r1 = true })
	expect.equal(pages[1].isComplete, true)
	expect.equal(pages[1].rewardEarned, true)
end)

test("reward earned: owned means skinsOwned says true, not completion", function()
	local pages = Book.pages(newTiers(), newObjects(), { a = true }, { r1 = true })
	expect.equal(pages[1].isComplete, false)
	expect.equal(pages[1].rewardEarned, true)
	local notOwned = Book.pages(newTiers(), newObjects(), { a = true }, { r1 = false })
	expect.equal(notOwned[1].rewardEarned, false)
end)

test("pages order: tiers come back in the order given, not sorted", function()
	local tiers: any = { tier2, tier1 }
	local pages = Book.pages(tiers, newObjects(), {}, {})
	expect.equal(#pages, 2)
	expect.equal(pages[1].tier, 2)
	expect.equal(pages[2].tier, 1)
end)

test("empty page: no objects means total 0, not complete, reward not listed", function()
	local tiers: any = {
		{
			tier = 3,
			nameKey = "t3",
			reward = { rewardId = "r3", rewardType = "skin", nameKey = "rn3" },
		},
	}
	local pages = Book.pages(tiers, newObjects(), { a = true }, {})
	expect.equal(pages[1].totalCount, 0)
	expect.equal(pages[1].collectedCount, 0)
	expect.equal(pages[1].isComplete, false)
	expect.same(Book.completedRewardIds(tiers, newObjects(), { a = true }), {})
end)

test("entries fields: copied from the object with the discovered flag", function()
	local pages = Book.pages(newTiers(), newObjects(), { a = true }, {})
	local entry = pages[1].entries[1]
	expect.equal(entry.bookId, "a")
	expect.equal(entry.nameKey, "na")
	expect.equal(entry.icon, "ia")
	expect.equal(entry.isDiscovered, true)
	local second = pages[1].entries[2]
	expect.equal(second.bookId, "b")
	expect.equal(second.isDiscovered, false)
end)

test("entries order: follows the order of objects", function()
	local objects: any = {
		{ bookId = "d", tier = 1, nameKey = "nd", icon = "id" },
		{ bookId = "a", tier = 1, nameKey = "na", icon = "ia" },
		{ bookId = "z", tier = 2, nameKey = "nz", icon = "iz" },
		{ bookId = "c", tier = 1, nameKey = "nc", icon = "ic" },
	}
	local pages = Book.pages(newTiers(), objects, {}, {})
	local ids: { string } = {}
	for _, entry in pages[1].entries do
		table.insert(ids, entry.bookId)
	end
	expect.same(ids, { "d", "a", "c" })
	expect.equal(pages[1].totalCount, 3)
	expect.equal(pages[2].entries[1].bookId, "z")
end)

test("unknown book id: an id that is in no object counts on no page", function()
	local pages = Book.pages(newTiers(), newObjects(), { zzz = true }, {})
	expect.equal(pages[1].collectedCount, 0)
	expect.equal(pages[2].collectedCount, 0)
	expect.equal(pages[1].isComplete, false)
end)

test("book values that are not true do not count", function()
	local book: any = { a = false, b = true }
	local pages = Book.pages(newTiers(), newObjects(), book, {})
	expect.equal(pages[1].collectedCount, 1)
	sameFlags(flags(pages[1].entries), { false, true, false, false })
end)

-- completedRewardIds

test("completedRewardIds: lists rewards of complete pages in tier order", function()
	local tiers: any = {
		{
			tier = 2,
			nameKey = "t2",
			reward = { rewardId = "r2", rewardType = "skin", nameKey = "rn2" },
		},
		{
			tier = 1,
			nameKey = "t1",
			reward = { rewardId = "r1", rewardType = "trail", nameKey = "rn1" },
		},
	}
	local objects: any = {
		{ bookId = "a", tier = 1, nameKey = "na", icon = "ia" },
		{ bookId = "e", tier = 2, nameKey = "ne", icon = "ie" },
	}
	expect.same(Book.completedRewardIds(tiers, objects, { a = true, e = true }), { "r2", "r1" })
	expect.same(Book.completedRewardIds(tiers, objects, { a = true }), { "r1" })
	expect.same(Book.completedRewardIds(tiers, objects, {}), {})
end)

test("completedRewardIds: an incomplete page gives nothing", function()
	expect.same(Book.completedRewardIds(newTiers(), newObjects(), { a = true, b = true }), {})
end)

-- purity

test("input untouched: no call changes its arguments", function()
	local tiers, objects = newTiers(), newObjects()
	local book: any = { a = true, c = true }
	local skins: any = { r1 = true }
	local ids: any = { "b", "z", "b", "a" }
	local before = serialize({ tiers, objects, book, skins, ids })
	Book.newIds(ids, book)
	Book.pages(tiers, objects, book, skins)
	Book.completedRewardIds(tiers, objects, book)
	expect.equal(serialize({ tiers, objects, book, skins, ids }), before)
end)

return {}
