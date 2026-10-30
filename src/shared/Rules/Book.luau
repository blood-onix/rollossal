--!strict
-- Collection book rules: which entries are new, how full each page is, which rewards are earned.
-- Pure: no Roblox APIs, no clock, no randomness. Tiers and objects come in as arguments.
-- Contract: specs/003-saving-and-economy/contracts/rules-api.md §Book.

export type BookObject = { bookId: string, tier: number, nameKey: string, icon: string }
export type BookReward = { rewardId: string, rewardType: string, nameKey: string }
export type BookTier = { tier: number, nameKey: string, reward: BookReward? }
export type BookEntry = { bookId: string, nameKey: string, icon: string, isDiscovered: boolean }
export type PageSummary = {
	tier: number,
	nameKey: string,
	collectedCount: number,
	totalCount: number,
	isComplete: boolean,
	rewardId: string?,
	rewardType: string?,
	rewardNameKey: string?,
	rewardEarned: boolean,
	entries: { BookEntry },
	-- Theme pages only (005, contracts/theme-content.md §4): nil on tier pages.
	themeId: string?,
	isActive: boolean?,
	returningKey: string?,
}

-- A theme page as it travels into the Book: metadata plus the bookIds the page lists, in display
-- order. Callers that hold object ids convert them to bookIds first (BookUi reads
-- Worlds.themeBookPages, whose `objects` are already resolved in objectIds order).
export type ThemePageDef = {
	id: string,
	nameKey: string,
	returningKey: string,
	themeId: string,
	objectIds: { string },
}

local Book = {}

function Book.newIds(absorbedBookIds: { string }, book: { [string]: boolean }): { string }
	local seen: { [string]: boolean } = {}
	local fresh: { string } = {}
	for _, id in absorbedBookIds do
		if book[id] ~= true and not seen[id] then
			seen[id] = true
			table.insert(fresh, id)
		end
	end
	return fresh
end

local function summarize(
	tier: BookTier,
	objects: { BookObject },
	book: { [string]: boolean },
	skinsOwned: { [string]: boolean }
): PageSummary
	local entries: { BookEntry } = {}
	local collected = 0
	for _, object in objects do
		if object.tier == tier.tier then
			local isDiscovered = book[object.bookId] == true
			if isDiscovered then
				collected += 1
			end
			table.insert(entries, {
				bookId = object.bookId,
				nameKey = object.nameKey,
				icon = object.icon,
				isDiscovered = isDiscovered,
			})
		end
	end
	local total = #entries
	local reward = tier.reward
	return {
		tier = tier.tier,
		nameKey = tier.nameKey,
		collectedCount = collected,
		totalCount = total,
		isComplete = total > 0 and collected == total,
		rewardId = if reward then reward.rewardId else nil,
		rewardType = if reward then reward.rewardType else nil,
		rewardNameKey = if reward then reward.nameKey else nil,
		rewardEarned = reward ~= nil and skinsOwned[reward.rewardId] == true,
		entries = entries,
	}
end

function Book.pages(
	tiers: { BookTier },
	objects: { BookObject },
	book: { [string]: boolean },
	skinsOwned: { [string]: boolean }
): { PageSummary }
	local pages: { PageSummary } = {}
	for _, tier in tiers do
		table.insert(pages, summarize(tier, objects, book, skinsOwned))
	end
	return pages
end

-- A returning label must never create FOMO (data-model.md §5, Principle V): no countdown wording in
-- the key it names. Localized text is checked in tests/unit/Strings.test (both languages).
local returningForbidden = { "limited", "left", "ends", "hurry" }

local function validateReturningKey(key: string, pageId: string): string
	if string.match(key, "%d+:%d+") ~= nil then
		error(`Book: theme page {pageId} returningKey {key} looks like a timer`, 2)
	end
	local lowered = string.lower(key)
	for _, word in returningForbidden do
		if string.find(lowered, word, 1, true) ~= nil then
			error(`Book: theme page {pageId} returningKey {key} says {word}`, 2)
		end
	end
	return key
end

function Book.themePages(
	pages: { ThemePageDef },
	objects: { BookObject },
	book: { [string]: boolean },
	activeThemeId: string?
): { PageSummary }
	-- bookId -> object; theme pages pick their entries in objectIds order.
	local byBookId: { [string]: BookObject } = {}
	for _, object in objects do
		byBookId[object.bookId] = object
	end
	local themePages: { PageSummary } = {}
	for _, page in pages do
		local entries: { BookEntry } = {}
		local collected = 0
		for _, bookId in page.objectIds do
			local object = byBookId[bookId]
			if object == nil then
				error(`Book: theme page {page.id} lists unknown bookId {bookId}`, 2)
			end
			local isDiscovered = book[object.bookId] == true
			if isDiscovered then
				collected += 1
			end
			table.insert(entries, {
				bookId = object.bookId,
				nameKey = object.nameKey,
				icon = object.icon,
				isDiscovered = isDiscovered,
			})
		end
		local total = #entries
		local isActive = page.themeId == activeThemeId
		table.insert(
			themePages,
			{
				tier = 0,
				nameKey = page.nameKey,
				collectedCount = collected,
				totalCount = total,
				isComplete = total > 0 and collected == total,
				rewardId = nil,
				rewardType = nil,
				rewardNameKey = nil,
				rewardEarned = false,
				entries = entries,
				themeId = page.themeId,
				isActive = isActive,
				returningKey = if not isActive
					then validateReturningKey(page.returningKey, page.id)
					else nil,
			} :: any
		)
	end
	return themePages
end

function Book.completedRewardIds(
	tiers: { BookTier },
	objects: { BookObject },
	book: { [string]: boolean }
): { string }
	local ids: { string } = {}
	for _, page in Book.pages(tiers, objects, book, {}) do
		if page.isComplete and page.rewardId ~= nil then
			table.insert(ids, page.rewardId)
		end
	end
	return ids
end

return Book
