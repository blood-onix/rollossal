--!strict
-- DataService tests on the ProfileStore mock store. Unique user ids from 900001 up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local beforeEach = JestGlobals.beforeEach
local Config = require(ReplicatedStorage.Shared.Config)
local ProfileStore = require(ServerScriptService.ServerPackages:WaitForChild("ProfileStore"))
local DataService = require(ServerScriptService.DataService)
local Localizer = require(ReplicatedStorage.Shared.Localization.Localizer)
local Worlds = require(ReplicatedStorage.Shared.Worlds)

local WORLD = Worlds.active.worldId

-- Book ids of every object of one tier, and of every object in the world, from the world data.
local function bookIdsOfTier(tier: number): { string }
	local ids: { string } = {}
	local list = Worlds.objectsByTier[tier]
	assert(list, `no objects in tier {tier}`)
	for _, object in list do
		table.insert(ids, object.bookId)
	end
	return ids
end

local function allBookIds(): { string }
	local ids: { string } = {}
	for _, object in Worlds.active.objects do
		table.insert(ids, object.bookId)
	end
	return ids
end

local function rewardIdOf(tier: number): string
	local reward = Worlds.sizeTiers[tier].reward
	assert(reward, `tier {tier} has no reward`)
	return reward.rewardId
end

local FIRST_BOOK_ID = bookIdsOfTier(1)[1]

local nextUserId = 900000
local function newUserId(): number
	nextUserId += 1
	return nextUserId
end

local function fakePlayer(userId: number): any
	return { Parent = Players, LocaleId = "en-us", UserId = userId }
end

local capturedKicks: { { player: any, msg: string } } = {}
local capturedSyncs: { { player: any, snap: any } } = {}

local function installSeams()
	DataService.setKick(function(player, msg)
		table.insert(capturedKicks, { player = player, msg = msg })
	end)
	DataService.setSync(function(player, snap)
		table.insert(capturedSyncs, { player = player, snap = snap })
	end)
end

local function setup()
	beforeAll(function()
		DataService.setStore(ProfileStore.New("test").Mock)
		installSeams()
	end)
	beforeEach(function()
		table.clear(capturedKicks)
		table.clear(capturedSyncs)
	end)
end

describe("DataService", function()
	setup()

	it("new profile has v1 defaults", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		local ok = DataService.load(uid, player)
		expect(ok).toBe(true)
		local snap = DataService.snapshot(uid)
		expect(snap.coins).toBe(0)
		expect(snap.book).toEqual({})
		expect(snap.bestSize).toEqual({})
		expect(snap.settings.musicVolume).toBe(Config.Settings.musicVolume.default)
		DataService.release(uid)
	end)

	it("partial stored profile is reconciled and saved values survive", function()
		local uid = newUserId()
		local store = ProfileStore.New("test").Mock
		DataService.setStore(store)
		local profile = store:StartSessionAsync(Config.playerKeyPrefix .. tostring(uid), {}) :: any
		profile.Data = { version = 1, coins = 5 }
		profile:EndSession()
		DataService.setStore(store)
		local player = fakePlayer(uid)
		local ok = DataService.load(uid, player)
		expect(ok).toBe(true)
		local snap = DataService.snapshot(uid)
		expect(snap.coins).toBe(5)
		DataService.release(uid)
	end)

	it("apply adds coins, raises bestSize, inserts book entries, grants reward", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		local result = {
			runId = "r1",
			worldId = WORLD,
			finalDiameter = 5,
			coins = 10,
			newBookIds = { FIRST_BOOK_ID },
		}
		local outcome = DataService.applyRunResult(uid, result)
		expect(outcome).never.toBe(nil)
		local snap = DataService.snapshot(uid)
		expect(snap.coins).toBe(10)
		expect(snap.book[FIRST_BOOK_ID]).toBe(true)
		expect(#capturedSyncs).toBeGreaterThan(0)
		local lastSync = capturedSyncs[#capturedSyncs].snap
		expect(lastSync.coins).toBe(10)
		expect(lastSync.book[FIRST_BOOK_ID]).toBe(true)
		expect(lastSync.bestSize[WORLD]).toBe(5)
		DataService.release(uid)
	end)

	it("completing all five pages grants every page reward into skinsOwned", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		local outcome = DataService.applyRunResult(uid, {
			runId = "rw1",
			worldId = WORLD,
			finalDiameter = 12,
			coins = 4,
			newBookIds = allBookIds(),
		})
		expect(outcome).never.toBe(nil)
		expect(#outcome.newRewardIds).toBe(#Worlds.sizeTiers)
		local snap = DataService.snapshot(uid)
		for tier = 1, #Worlds.sizeTiers do
			expect(snap.skinsOwned[rewardIdOf(tier)]).toBe(true)
		end
		expect(capturedSyncs[#capturedSyncs].snap.skinsOwned[rewardIdOf(#Worlds.sizeTiers)]).toBe(
			true
		)
		DataService.release(uid)
	end)

	it("only a completed page grants its reward", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		DataService.applyRunResult(uid, {
			runId = "rw2",
			worldId = WORLD,
			finalDiameter = 6,
			coins = 1,
			newBookIds = bookIdsOfTier(1),
		})
		-- Every tier 1 object completes page 1 and nothing else.
		local owned = DataService.snapshot(uid).skinsOwned
		expect(owned[rewardIdOf(1)]).toBe(true)
		expect(owned[rewardIdOf(2)]).toBe(nil)
		DataService.release(uid)
	end)

	it("repeated runId changes nothing", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		local result =
			{ runId = "r1", worldId = WORLD, finalDiameter = 5, coins = 10, newBookIds = {} }
		DataService.applyRunResult(uid, result)
		local coinsBefore = DataService.snapshot(uid).coins
		DataService.applyRunResult(uid, result)
		expect(DataService.snapshot(uid).coins).toBe(coinsBefore)
		DataService.release(uid)
	end)

	it("apply after release returns nil and changes nothing", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		DataService.release(uid)
		local result =
			{ runId = "r2", worldId = WORLD, finalDiameter = 5, coins = 10, newBookIds = {} }
		expect(DataService.applyRunResult(uid, result)).toBe(nil)
	end)

	it("coins never go negative", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		local result =
			{ runId = "r3", worldId = WORLD, finalDiameter = 5, coins = -5, newBookIds = {} }
		DataService.applyRunResult(uid, result)
		expect(DataService.snapshot(uid).coins).toBeGreaterThanOrEqual(0)
		DataService.release(uid)
	end)

	it("bestSize never decreases", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		DataService.applyRunResult(
			uid,
			{ runId = "r4", worldId = WORLD, finalDiameter = 10, coins = 0, newBookIds = {} }
		)
		DataService.applyRunResult(
			uid,
			{ runId = "r5", worldId = WORLD, finalDiameter = 5, coins = 0, newBookIds = {} }
		)
		expect(DataService.snapshot(uid).bestSize[WORLD]).toBe(10)
		DataService.release(uid)
	end)

	it("store returning nil on StartSessionAsync makes load return false and kick", function()
		local stubStore = {
			StartSessionAsync = function()
				return nil
			end,
		}
		DataService.setStore(stubStore)
		local uid = newUserId()
		local player = fakePlayer(uid)
		local ok = DataService.load(uid, player)
		expect(ok).toBe(false)
		expect(#capturedKicks).toBe(1)
		expect(capturedKicks[1].msg).toBe(Localizer.t("error.profile_load_failed", nil, "en-us"))
		DataService.setStore(ProfileStore.New("test").Mock)
	end)

	it("default kick path reaches Player:Kick with the localized message", function()
		local kicked: { string } = {}
		local uid = newUserId()
		local player = fakePlayer(uid)
		player.Kick = function(_self: any, message: string)
			table.insert(kicked, message)
		end
		DataService.setKick(nil)
		DataService.setStore({
			StartSessionAsync = function()
				return nil
			end,
		})
		local ok = DataService.load(uid, player)
		installSeams()
		DataService.setStore(ProfileStore.New("test").Mock)
		expect(ok).toBe(false)
		expect(#kicked).toBe(1)
		expect(kicked[1]).toBe(Localizer.t("error.profile_load_failed", nil, "en-us"))
	end)

	it("player who leaves while the session is acquired gets the session ended at once", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		local ended = 0
		local fakeProfile = {
			Data = {},
			IsActive = function()
				return true
			end,
			AddUserId = function() end,
			EndSession = function()
				ended += 1
			end,
			OnSessionEnd = { Connect = function() end },
		}
		DataService.setStore({
			StartSessionAsync = function()
				player.Parent = nil
				return fakeProfile
			end,
		})
		local ok = DataService.load(uid, player)
		DataService.setStore(ProfileStore.New("test").Mock)
		expect(ok).toBe(false)
		expect(ended).toBe(1)
		expect(DataService.snapshot(uid)).toBe(nil)
	end)

	it("session ended while the player is present kicks with error.session_ended", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		local sessionEnded: (() -> ())? = nil
		local fakeProfile = {
			Data = {},
			IsActive = function()
				return true
			end,
			AddUserId = function() end,
			EndSession = function() end,
			OnSessionEnd = {
				Connect = function(_self: any, fn: () -> ())
					sessionEnded = fn
				end,
			},
		}
		DataService.setStore({
			StartSessionAsync = function()
				return fakeProfile
			end,
		})
		local ok = DataService.load(uid, player)
		expect(ok).toBe(true)
		expect(sessionEnded == nil).toBe(false)
		local fireSessionEnded = sessionEnded :: () -> ()
		fireSessionEnded()
		DataService.setStore(ProfileStore.New("test").Mock)
		expect(#capturedKicks).toBe(1)
		expect(capturedKicks[1].msg).toBe(Localizer.t("error.session_ended", nil, "en-us"))
	end)

	it("version 2 profile released unchanged and kicked with error.profile_version", function()
		local uid = newUserId()
		local store = ProfileStore.New("test").Mock
		DataService.setStore(store)
		local profile = store:StartSessionAsync(Config.playerKeyPrefix .. tostring(uid), {}) :: any
		profile.Data = { version = 2, coins = 5 }
		profile:EndSession()
		local player = fakePlayer(uid)
		local ok = DataService.load(uid, player)
		expect(ok).toBe(false)
		expect(#capturedKicks).toBe(1)
		expect(capturedKicks[1].msg).toBe(Localizer.t("error.profile_version", nil, "en-us"))
		-- The stored data is exactly what was there, and the session lock is free again.
		local stored = store:StartSessionAsync(Config.playerKeyPrefix .. tostring(uid), {}) :: any
		expect(stored).never.toBe(nil)
		expect(stored.Data).toEqual({ version = 2, coins = 5 })
		stored:EndSession()
		DataService.setStore(ProfileStore.New("test").Mock)
	end)

	it("an unreadable stored version is released unchanged and kicked", function()
		local store = ProfileStore.New("test").Mock
		DataService.setStore(store)
		local cases: { { [string]: any } } =
			{ { version = 0, coins = 5 }, { version = 1.5, coins = 5 }, { coins = 5 } }
		for _, stored in cases do
			table.clear(capturedKicks)
			local uid = newUserId()
			local key = Config.playerKeyPrefix .. tostring(uid)
			local profile = store:StartSessionAsync(key, {}) :: any
			profile.Data = table.clone(stored)
			profile:EndSession()
			expect(DataService.load(uid, fakePlayer(uid))).toBe(false)
			expect(#capturedKicks).toBe(1)
			expect(capturedKicks[1].msg).toBe(Localizer.t("error.profile_version", nil, "en-us"))
			expect(DataService.snapshot(uid)).toBe(nil)
			local after = store:StartSessionAsync(key, {}) :: any
			expect(after.Data).toEqual(stored)
			after:EndSession()
		end
		DataService.setStore(ProfileStore.New("test").Mock)
	end)

	it("shutdown releases every profile and later apply returns nil", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		DataService.shutdown()
		local result =
			{ runId = "r6", worldId = WORLD, finalDiameter = 5, coins = 1, newBookIds = {} }
		expect(DataService.applyRunResult(uid, result)).toBe(nil)
	end)

	it("snapshot and getBook return copies", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		local s1 = DataService.snapshot(uid)
		s1.coins = 999
		expect(DataService.snapshot(uid).coins).never.toBe(999)
		local b = DataService.getBook(uid)
		if b then
			b.x = true
		end
		expect(DataService.getBook(uid).x).toBe(nil)
		DataService.release(uid)
	end)
end)

describe("DataService updateSettings", function()
	setup()

	it("saves valid candidate", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		local ok = DataService.updateSettings(uid, { musicVolume = 0.5, reduceMotion = true })
		expect(ok).toBe(true)
		expect(DataService.snapshot(uid).settings.musicVolume).toBe(0.5)
		expect(DataService.snapshot(uid).settings.reduceMotion).toBe(true)
		DataService.release(uid)
	end)

	it("clamps and ignores unknown", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		DataService.updateSettings(uid, { musicVolume = 9, language = "xx", bogus = 1 })
		local s = DataService.snapshot(uid).settings
		expect(s.musicVolume).toBe(1)
		expect(s.language).toBe(Config.Settings.languageDefault)
		DataService.release(uid)
	end)
end)

describe("DataService best-size acceptance", function()
	setup()

	it("two runs sum coins and keep max bestSize", function()
		local uid = newUserId()
		local player = fakePlayer(uid)
		DataService.load(uid, player)
		DataService.applyRunResult(
			uid,
			{ runId = "a", worldId = WORLD, finalDiameter = 18.5, coins = 12, newBookIds = {} }
		)
		local o2 = DataService.applyRunResult(
			uid,
			{ runId = "b", worldId = WORLD, finalDiameter = 14.0, coins = 8, newBookIds = {} }
		)
		expect(DataService.snapshot(uid).coins).toBe(20)
		expect(DataService.snapshot(uid).bestSize[WORLD]).toBe(18.5)
		expect(o2.isFirstRun).toBe(false)
		expect(o2.bestSize).toBe(18.5)
		DataService.release(uid)
	end)
end)

describe("DataService round trip", function()
	setup()

	it("coins, best size, book, rewards and settings survive leave and rejoin", function()
		local uid = newUserId()
		local store = ProfileStore.New("test").Mock
		DataService.setStore(store)
		expect(DataService.load(uid, fakePlayer(uid))).toBe(true)
		local result = {
			runId = "rt1",
			worldId = WORLD,
			finalDiameter = 9.5,
			coins = 17,
			newBookIds = allBookIds(),
		}
		expect(DataService.applyRunResult(uid, result)).never.toBe(nil)
		expect(DataService.updateSettings(uid, {
			musicVolume = 0.25,
			cameraSensitivity = 1.5,
			reduceMotion = true,
			language = "es-es",
		})).toBe(true)
		local before = DataService.snapshot(uid)
		expect(before.coins).toBe(17)
		DataService.release(uid)
		expect(DataService.snapshot(uid)).toBe(nil)

		expect(DataService.load(uid, fakePlayer(uid))).toBe(true)
		local after = DataService.snapshot(uid)
		expect(after).toEqual(before)
		expect(after.settings.language).toBe("es-es")
		expect(after.skinsOwned[rewardIdOf(3)]).toBe(true)

		-- The ledger is per session: the same runId is a new run after a reload.
		local again = DataService.applyRunResult(uid, result)
		expect(again.applied).toBe(true)
		expect(DataService.snapshot(uid).coins).toBe(34)
		DataService.release(uid)
	end)
end)

describe("DataService remote handlers", function()
	setup()

	local function loadedPlayer(): (number, any)
		local uid = newUserId()
		local player = fakePlayer(uid)
		expect(DataService.load(uid, player)).toBe(true)
		return uid, player
	end

	it("UpdateSettings applies a well-formed payload", function()
		local uid, player = loadedPlayer()
		DataService.handleUpdateSettings(player, { musicVolume = 0.4 })
		expect(DataService.snapshot(uid).settings.musicVolume).toBe(0.4)
		DataService.release(uid)
	end)

	it(
		"UpdateSettings rejects malformed arguments without throwing or changing anything",
		function()
			local uid, player = loadedPlayer()
			local before = DataService.snapshot(uid).settings
			expect(function()
				DataService.handleUpdateSettings(player)
				DataService.handleUpdateSettings(player, "x")
				DataService.handleUpdateSettings(player, 5)
				DataService.handleUpdateSettings(player, nil)
				DataService.handleUpdateSettings(player, true)
				DataService.handleUpdateSettings(
					player,
					{ musicVolume = 0.1 },
					{ musicVolume = 0.2 }
				)
				DataService.handleUpdateSettings(
					player,
					{ musicVolume = 0 / 0, effectsVolume = math.huge }
				)
			end).never.toThrow()
			local after = DataService.snapshot(uid).settings
			expect(after).toEqual(before)
			DataService.release(uid)
		end
	)

	it("UpdateSettings clamps and ignores unknown fields", function()
		local uid, player = loadedPlayer()
		DataService.handleUpdateSettings(player, { musicVolume = 9, language = "xx", bogus = 1 })
		local s = DataService.snapshot(uid).settings
		expect(s.musicVolume).toBe(1)
		expect(s.language).toBe(Config.Settings.languageDefault)
		DataService.release(uid)
	end)

	it("UpdateSettings ignores requests past the rate limit", function()
		local uid, player = loadedPlayer()
		for _ = 1, Config.settingsRateLimit do
			DataService.handleUpdateSettings(player, { musicVolume = 0.1 })
		end
		DataService.handleUpdateSettings(player, { musicVolume = 0.9 })
		expect(DataService.snapshot(uid).settings.musicVolume).toBe(0.1)
		DataService.release(uid)
	end)

	it("UpdateSettings from a player with no profile does nothing", function()
		local player = fakePlayer(newUserId())
		expect(function()
			DataService.handleUpdateSettings(player, { musicVolume = 0.3 })
		end).never.toThrow()
		expect(#capturedSyncs).toBe(0)
	end)

	it("RequestProfile replies with the snapshot only for zero arguments", function()
		local uid, player = loadedPlayer()
		table.clear(capturedSyncs)
		DataService.handleRequestProfile(player, "x")
		DataService.handleRequestProfile(player, nil)
		expect(#capturedSyncs).toBe(0)
		DataService.handleRequestProfile(player)
		expect(#capturedSyncs).toBe(1)
		expect(capturedSyncs[1].snap.coins).toBe(0)
		DataService.release(uid)
	end)

	it("RequestProfile ignores requests past the rate limit", function()
		local uid, player = loadedPlayer()
		table.clear(capturedSyncs)
		for _ = 1, Config.settingsRateLimit + 5 do
			DataService.handleRequestProfile(player)
		end
		expect(#capturedSyncs).toBe(Config.settingsRateLimit)
		DataService.release(uid)
	end)

	it("RequestProfile sends nothing while the profile is still loading", function()
		local player = fakePlayer(newUserId())
		DataService.handleRequestProfile(player)
		expect(#capturedSyncs).toBe(0)
	end)
end)
