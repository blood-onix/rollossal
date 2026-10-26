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
