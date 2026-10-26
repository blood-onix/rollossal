--!strict
-- Saved player profile rules: defaults, repair, migration and applying one run result exactly once.
-- Pure: no Roblox APIs, no clock, no randomness. Bounds, defaults and the reward lookup come in as
-- arguments. Contract: specs/003-saving-and-economy/contracts/rules-api.md §Profile; data-model §2.

export type SettingsData = {
	musicVolume: number,
	effectsVolume: number,
	cameraSensitivity: number,
	reduceMotion: boolean,
	language: string,
}
export type Data = {
	version: number,
	coins: number,
	worldsUnlocked: { [string]: boolean },
	skinsOwned: { [string]: boolean },
	equipped: { skin: string?, trail: string? },
	book: { [string]: boolean },
	bestSize: { [string]: number },
	receipts: { string },
	appliedRuns: { [string]: boolean },
	settings: SettingsData,
}
export type Defaults = { worldsUnlocked: { [string]: boolean }, settings: SettingsData }
export type RunLike = {
	runId: string,
	worldId: string,
	finalDiameter: number,
	coins: number,
	newBookIds: { string },
}
export type Outcome = {
	applied: boolean,
	reason: string?,
	isFirstRun: boolean,
	coinsGained: number,
	coinsTotal: number,
	bestSize: number,
	newBookIds: { string },
	newRewardIds: { string },
}
export type Migrations = { [number]: (data: { [string]: any }) -> () }

local Profile = {}

Profile.SCHEMA_VERSION = 1
-- Nothing to migrate from at version 1. A later schema adds [1] = function(data) ... end.
Profile.migrations = {} :: Migrations

local TABLE_KEYS =
	{ "worldsUnlocked", "skinsOwned", "equipped", "book", "bestSize", "receipts", "appliedRuns" }

local function isFinite(value: unknown): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function copySettings(settings: SettingsData): SettingsData
	return {
		musicVolume = settings.musicVolume,
		effectsVolume = settings.effectsVolume,
		cameraSensitivity = settings.cameraSensitivity,
		reduceMotion = settings.reduceMotion,
		language = settings.language,
	}
end

function Profile.defaults(defaults: Defaults): Data
	return {
		version = Profile.SCHEMA_VERSION,
		coins = 0,
		worldsUnlocked = table.clone(defaults.worldsUnlocked),
		skinsOwned = {},
		equipped = {},
		book = {},
		bestSize = {},
		receipts = {},
		appliedRuns = {},
		settings = copySettings(defaults.settings),
	}
end

local function reconcileSettings(stored: { [string]: any }, fallback: SettingsData)
	for _, key in { "musicVolume", "effectsVolume", "cameraSensitivity" } do
		if not isFinite(stored[key]) then
			stored[key] = (fallback :: any)[key]
		end
	end
	if type(stored.reduceMotion) ~= "boolean" then
		stored.reduceMotion = fallback.reduceMotion
	end
	if type(stored.language) ~= "string" then
		stored.language = fallback.language
	end
end

function Profile.reconcile(data: { [string]: any }, defaults: Defaults)
	local fresh = Profile.defaults(defaults)
	if not isFinite(data.coins) or (data.coins :: number) < 0 then
		data.coins = fresh.coins
	end
	for _, key in TABLE_KEYS do
		if type(data[key]) ~= "table" then
			data[key] = (fresh :: any)[key]
		end
	end
	if type(data.settings) ~= "table" then
		data.settings = fresh.settings
	else
		reconcileSettings(data.settings, fresh.settings)
	end
end

function Profile.migrate(
	data: { [string]: any },
	migrations: Migrations,
	target: number
): (boolean, string?)
	local version = data.version
	if
		not isFinite(version)
		or (version :: number) < 1
		or version ~= math.floor(version :: number)
	then
		return false, "BadVersion"
	end
	if (version :: number) > target then
		return false, "FutureVersion"
	end
	for step = version :: number, target - 1 do
		local migration = migrations[step]
		if type(migration) ~= "function" then
			return false, "MissingMigration"
		end
		migration(data)
		data.version = step + 1
	end
	return true, nil
end

function Profile.prepare(data: { [string]: any }, defaults: Defaults): (boolean, string?)
	if next(data) == nil then
		data.version = Profile.SCHEMA_VERSION
	else
		local ok, reason = Profile.migrate(data, Profile.migrations, Profile.SCHEMA_VERSION)
		if not ok then
			return false, reason
		end
	end
	Profile.reconcile(data, defaults)
	-- The ledger only guards against a run applied twice in one session (plan finding F-2).
	data.appliedRuns = {}
	return true, nil
end

local function isStringArray(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for key, item in value :: { [unknown]: unknown } do
		if type(key) ~= "number" or type(item) ~= "string" then
			return false
		end
		count += 1
	end
	return count == #(value :: { unknown })
end

local function isNonEmptyString(value: unknown): boolean
	return type(value) == "string" and value ~= ""
end

local function isValidResult(result: RunLike): boolean
	local diameter: unknown = result.finalDiameter
	return isNonEmptyString(result.runId)
		and isNonEmptyString(result.worldId)
		and isFinite(diameter)
		and (diameter :: number) > 0
		and isFinite(result.coins)
		and isStringArray(result.newBookIds)
end

local function rejected(data: Data, result: RunLike, reason: string): Outcome
	local best = 0
	if type(result.worldId) == "string" then
		best = data.bestSize[result.worldId] or 0
	end
	return {
		applied = false,
		reason = reason,
		isFirstRun = false,
		coinsGained = 0,
		coinsTotal = data.coins,
		bestSize = best,
		newBookIds = {},
		newRewardIds = {},
	}
end

function Profile.applyRunResult(
	data: Data,
	result: RunLike,
	rewardsFor: (book: { [string]: boolean }) -> { string }
): Outcome
	if not isValidResult(result) then
		return rejected(data, result, "Invalid")
	end
	if data.appliedRuns[result.runId] == true then
		return rejected(data, result, "Duplicate")
	end

	local isFirstRun = next(data.bestSize) == nil
	local coinsGained = math.max(0, math.floor(result.coins))
	data.coins += coinsGained
	data.bestSize[result.worldId] =
		math.max(data.bestSize[result.worldId] or 0, result.finalDiameter)

	local newBookIds: { string } = {}
	for _, id in result.newBookIds do
		if data.book[id] ~= true then
			data.book[id] = true
			table.insert(newBookIds, id)
		end
	end

	local newRewardIds: { string } = {}
	for _, id in rewardsFor(data.book) do
		if data.skinsOwned[id] ~= true then
			data.skinsOwned[id] = true
			table.insert(newRewardIds, id)
		end
	end

	data.appliedRuns[result.runId] = true

	return {
		applied = true,
		reason = nil,
		isFirstRun = isFirstRun,
		coinsGained = coinsGained,
		coinsTotal = data.coins,
		bestSize = data.bestSize[result.worldId],
		newBookIds = newBookIds,
		newRewardIds = newRewardIds,
	}
end

return Profile
