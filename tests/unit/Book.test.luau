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

local function expectError(fn: () -> (), needle: string)
	local ok, err = pcall(fn)
	expect.falsy(ok)
	local message = if type(err) == "string" then err else tostring(err)
	expect.truthy(
		string.find(message, needle, 1, true) ~= nil,
		`expected "{needle}" in the error message, got "{message}"`
	)
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

-- themePages (005, contracts/theme-content.md §4)

local function newThemePages(): any
	return {
		{
			id = "w.th",
			nameKey = "tp.winter",
			returningKey = "tp.winter.returning",
			themeId = "winter",
			objectIds = { "sv.winter_lights" },
		},
		{
			id = "w.city",
			nameKey = "tp.city",
			returningKey = "tp.city.returning",
			themeId = "city",
			objectIds = { "sv.lolly", "sv.towel", "sv.ball" },
		},
	}
end

local function newThemeObjects(): any
	return {
		{ bookId = "sv.lolly", tier = 1, nameKey = "n.lolly", icon = "i1" },
		{ bookId = "sv.towel", tier = 2, nameKey = "n.towel", icon = "i2" },
		{ bookId = "sv.ball", tier = 2, nameKey = "n.ball", icon = "i3" },
		{ bookId = "sv.winter_lights", tier = 2, nameKey = "n.lights", icon = "i4" },
	}
end

test("themePages: one summary per page, tier 0, no reward, counts over the page's ids", function()
	local pages =
		Book.themePages(newThemePages(), newThemeObjects(), { ["sv.towel"] = true }, "city")
	expect.equal(#pages, 2)
	local winter = pages[1]
	expect.equal(winter.tier, 0)
	expect.equal(winter.nameKey, "tp.winter")
	expect.equal(winter.collectedCount, 0)
	expect.equal(winter.totalCount, 1)
	expect.equal(winter.isComplete, false)
	expect.equal(winter.rewardId, nil)
	expect.equal(winter.rewardType, nil)
	expect.equal(winter.rewardNameKey, nil)
	expect.equal(winter.rewardEarned, false)
	local city = pages[2]
	expect.equal(city.tier, 0)
	expect.equal(city.collectedCount, 1)
	expect.equal(city.totalCount, 3)
	expect.equal(city.isComplete, false)
	expect.equal(city.rewardEarned, false)
end)

test("themePages: active flag and returning key follow activeThemeId", function()
	local activeCity = Book.themePages(newThemePages(), newThemeObjects(), {}, "city")
	expect.equal(activeCity[1].themeId, "winter")
	expect.equal(activeCity[1].isActive, false)
	expect.equal(activeCity[1].returningKey, "tp.winter.returning")
	expect.equal(activeCity[2].themeId, "city")
	expect.equal(activeCity[2].isActive, true)
	expect.equal(activeCity[2].returningKey, nil)

	local activeWinter = Book.themePages(newThemePages(), newThemeObjects(), {}, "winter")
	expect.equal(activeWinter[1].isActive, true)
	expect.equal(activeWinter[1].returningKey, nil)
	expect.equal(activeWinter[2].isActive, false)
	expect.equal(activeWinter[2].returningKey, "tp.city.returning")

	local noTheme = Book.themePages(newThemePages(), newThemeObjects(), {}, nil)
	expect.equal(noTheme[1].isActive, false)
	expect.equal(noTheme[1].returningKey, "tp.winter.returning")
end)

test("themePages: entries come back in objectIds order, with the discovered flag", function()
	local pages = Book.themePages(
		newThemePages(),
		newThemeObjects(),
		{ ["sv.lolly"] = true, ["sv.ball"] = true },
		nil
	)
	local summary = pages[2]
	local ids: { string } = {}
	local names: { string } = {}
	local flagsOut: { boolean } = {}
	for _, entry in summary.entries do
		table.insert(ids, entry.bookId)
		table.insert(names, entry.nameKey)
		table.insert(flagsOut, entry.isDiscovered)
	end
	expect.same(ids, { "sv.lolly", "sv.towel", "sv.ball" })
	expect.same(names, { "n.lolly", "n.towel", "n.ball" })
	expect.same(flagsOut, { true, false, true })
	local winterEntry = pages[1].entries[1]
	expect.equal(winterEntry.bookId, "sv.winter_lights")
	expect.equal(winterEntry.nameKey, "n.lights")
	expect.equal(winterEntry.icon, "i4")
	expect.equal(winterEntry.isDiscovered, false)
end)

test("themePages: complete theme page with everything collected", function()
	local book = { ["sv.lolly"] = true, ["sv.towel"] = true, ["sv.ball"] = true }
	local pages = Book.themePages(newThemePages(), newThemeObjects(), book, "city")
	expect.equal(pages[2].collectedCount, 3)
	expect.equal(pages[2].totalCount, 3)
	expect.equal(pages[2].isComplete, true)
end)

test("themePages: progress preserved when the active theme moves away", function()
	local book: any = { ["sv.lolly"] = true }
	local whileActive = Book.themePages(newThemePages(), newThemeObjects(), book, "city")
	local returned = Book.themePages(newThemePages(), newThemeObjects(), book, "winter")
	expect.equal(whileActive[2].collectedCount, 1)
	expect.equal(returned[2].collectedCount, 1)
	expect.equal(returned[2].totalCount, 3)
	expect.equal(returned[2].isActive, false)
	expect.truthy(returned[2].returningKey ~= nil)
	expect.equal(returned[2].nameKey, whileActive[2].nameKey)
end)

test("themePages: errors name the page and id for an unknown bookId", function()
	local bad: any = {
		{
			id = "w.bad",
			nameKey = "n",
			returningKey = "r",
			themeId = "city",
			objectIds = { "sv.lolly", "sv.ghost" },
		},
	}
	expectError(function()
		Book.themePages(bad, newThemeObjects(), {}, "city")
	end, "w.bad")
	expectError(function()
		Book.themePages(bad, newThemeObjects(), {}, "city")
	end, "sv.ghost")
end)

test("themePages: returning keys may not name FOMO words or a timer", function()
	local limited: any = {
		{
			id = "p1",
			nameKey = "n",
			returningKey = "page.limited.name",
			themeId = "city",
			objectIds = { "sv.lolly" },
		},
	}
	expectError(function()
		Book.themePages(limited, newThemeObjects(), {}, nil)
	end, "limited")
	local left: any = {
		{
			id = "p2",
			nameKey = "n",
			returningKey = "page.LEFT.name",
			themeId = "city",
			objectIds = { "sv.lolly" },
		},
	}
	expectError(function()
		Book.themePages(left, newThemeObjects(), {}, nil)
	end, "LEFT")
	local ending: any = {
		{
			id = "p3",
			nameKey = "n",
			returningKey = "page.ends.soon",
			themeId = "city",
			objectIds = { "sv.lolly" },
		},
	}
	expectError(function()
		Book.themePages(ending, newThemeObjects(), {}, nil)
	end, "ends")
	local timer: any = {
		{
			id = "p4",
			nameKey = "n",
			returningKey = "page.0:00.returns",
			themeId = "city",
			objectIds = { "sv.lolly" },
		},
	}
	expectError(function()
		Book.themePages(timer, newThemeObjects(), {}, nil)
	end, "timer")
	local clean: any = {
		{
			id = "p5",
			nameKey = "n",
			returningKey = "page.snow.soon.name",
			themeId = "city",
			objectIds = { "sv.lolly" },
		},
	}
	local pages = Book.themePages(clean, newThemeObjects(), {}, nil)
	expect.equal(pages[1].returningKey, "page.snow.soon.name")
end)

test("themePages: input untouched, no call changes its arguments", function()
	local pages, objects = newThemePages(), newThemeObjects()
	local book: any = { ["sv.towel"] = true }
	local before = serialize({ pages, objects, book })
	Book.themePages(pages, objects, book, "city")
	expect.equal(serialize({ pages, objects, book }), before)
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
