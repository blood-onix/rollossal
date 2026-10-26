--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Localizer = require(Shared.Localization.Localizer)
local Book = require(Shared.Rules.Book)
local Profile = require(Shared.Rules.Profile)
local RateLimit = require(Shared.Rules.RateLimit)
local Settings = require(Shared.Rules.Settings)
local Worlds = require(Shared.Worlds)

local ServerPackages = script.Parent:WaitForChild("ServerPackages")
local ProfileStore = require(ServerPackages:WaitForChild("ProfileStore"))

local Remotes = require(script.Parent.Remotes)

local DataService = {}

local store = nil
local profiles: { [number]: any } = {}
local players: { [number]: Player? } = {}
local shuttingDown = false
local function defaultKick(player: Player, message: string)
	player:Kick(message)
end
local kickFn: (Player, string) -> () = defaultKick
local syncFn = function(_player: Player, _snapshot: any) end

function DataService.setStore(s: any)
	store = s
	shuttingDown = false
	profiles = {}
	players = {}
end

-- Test seam. Passing nil restores the production default, `player:Kick(message)`.
function DataService.setKick(fn: ((Player, string) -> ())?)
	kickFn = fn or defaultKick
end

function DataService.setSync(fn: (Player, any) -> ())
	syncFn = fn
end

local function getStore()
	if store then
		return store
	end
	local ps = (ProfileStore :: any).New(Config.dataStoreName)
	if RunService:IsStudio() and Config.useMockDataStoreInStudio then
		ps = ps.Mock
	end
	store = ps
	return store
end

local function defaults()
	return {
		version = Profile.SCHEMA_VERSION,
		coins = 0,
		bestSize = {},
		book = {},
		skinsOwned = {},
		equipped = {},
		worldsUnlocked = {},
		receipts = {},
		appliedRuns = {},
		settings = {
			musicVolume = Config.Settings.musicVolume.default,
			effectsVolume = Config.Settings.effectsVolume.default,
			cameraSensitivity = Config.Settings.cameraSensitivity.default,
			reduceMotion = Config.Settings.reduceMotionDefault,
			language = Config.Settings.languageDefault,
		},
	}
end

-- fill worldsUnlocked default
local function buildDefaults()
	local d = defaults()
	for k, v in Config.DefaultWorldsUnlocked do
		d.worldsUnlocked[k] = v
	end
	return d
end

-- The client-facing view of a profile: only what ProfileSync carries, copied so callers cannot mutate it.
local function buildSnapshot(data: any): any
	return {
		coins = data.coins,
		bestSize = table.clone(data.bestSize),
		book = table.clone(data.book),
		skinsOwned = table.clone(data.skinsOwned),
		equipped = table.clone(data.equipped),
		settings = table.clone(data.settings),
	}
end

local function sendSync(player: Player, data: any)
	local snap = buildSnapshot(data)
	syncFn(player, snap)
	pcall(function()
		Remotes.ProfileSync:FireClient(player, snap)
	end)
end

function DataService.snapshot(userId: number): any
	local p = profiles[userId]
	if not p then
		return nil
	end
	return buildSnapshot(p.Data)
end

function DataService.getBook(userId: number): any
	local p = profiles[userId]
	if not p or not p:IsActive() then
		return nil
	end
	return table.clone(p.Data.book)
end

function DataService.getBestSize(userId: number, worldId: string)
	local p = profiles[userId]
	if not p or not p:IsActive() then
		return nil
	end
	return p.Data.bestSize[worldId]
end

function DataService.load(userId: number, player: Player)
	local s = getStore()
	local key = Config.playerKeyPrefix .. tostring(userId)
	local leftGame = function()
		return player.Parent == nil
	end
	local ok, profile = pcall(function()
		return s:StartSessionAsync(key, { Cancel = leftGame })
	end)
	if not ok or profile == nil then
		warn(`DataService: profile load failed for user {userId}`)
		kickFn(player, Localizer.t("error.profile_load_failed", nil, player.LocaleId))
		return false
	end
	if player.Parent == nil then
		-- Left while the session was being acquired: release the lock at once (FR-004).
		pcall(function()
			profile:EndSession()
		end)
		return false
	end
	profile:AddUserId(userId)
	-- Defaults for an empty profile, migration, then repair of missing fields; a stored version we
	-- cannot read or are too old to understand is left untouched and the session is released.
	local prepared, reason = Profile.prepare(profile.Data, buildDefaults())
	if not prepared then
		pcall(function()
			profile:EndSession()
		end)
		warn(`DataService: unsupported profile ({reason}) for user {userId}`)
		kickFn(player, Localizer.t("error.profile_version", nil, player.LocaleId))
		return false
	end
	profile.OnSessionEnd:Connect(function()
		-- Only a session ended behind our back (lock stolen) kicks; release() forgets the entry first.
		if profiles[userId] == profile and (player.Parent :: Instance?) ~= nil then
			kickFn(player, Localizer.t("error.session_ended", nil, player.LocaleId))
		end
		if profiles[userId] == profile then
			profiles[userId] = nil
			players[userId] = nil
		end
	end)
	profiles[userId] = profile
	players[userId] = player
	sendSync(player, profile.Data)
	return true
end

function DataService.applyRunResult(userId: number, result: any): any
	local profile = profiles[userId]
	if not profile or not profile:IsActive() or shuttingDown then
		return nil
	end
	local rewardsFor = function(book: any)
		return Book.completedRewardIds(Worlds.sizeTiers :: any, Worlds.active.objects :: any, book)
	end
	local outcome = Profile.applyRunResult(profile.Data, result, rewardsFor)
	local player = players[userId]
	if player ~= nil then
		sendSync(player, profile.Data)
	end
	return outcome
end

function DataService.release(userId: number)
	players[userId] = nil
	local profile = profiles[userId]
	if profile then
		profiles[userId] = nil
		pcall(function()
			profile:EndSession()
		end)
	end
end

function DataService.shutdown()
	shuttingDown = true
	for userId, _ in profiles do
		DataService.release(userId)
	end
end

function DataService.updateSettings(userId: number, candidate: any): boolean
	local profile = profiles[userId]
	if not profile or not profile:IsActive() or shuttingDown then
		return false
	end
	local bounds = {
		musicVolume = {
			min = Config.Settings.musicVolume.min,
			max = Config.Settings.musicVolume.max,
		},
		effectsVolume = {
			min = Config.Settings.effectsVolume.min,
			max = Config.Settings.effectsVolume.max,
		},
		cameraSensitivity = {
			min = Config.Settings.cameraSensitivity.min,
			max = Config.Settings.cameraSensitivity.max,
		},
		languages = Config.Settings.languages,
	}
	local validated = Settings.validate(profile.Data.settings, candidate, bounds)
	profile.Data.settings = validated
	local player = players[userId]
	if player ~= nil then
		sendSync(player, profile.Data)
	end
	return true
end

-- Sliding windows of recent request times, one per player and remote; dropped when the player leaves.
local settingsWindows: { [number]: { number } } = {}
local profileWindows: { [number]: { number } } = {}

local function allowRequest(windows: { [number]: { number } }, userId: number): boolean
	local allowed, kept = RateLimit.allow(
		windows[userId] or {},
		os.clock(),
		Config.settingsRateLimit,
		Config.rateLimitWindow
	)
	windows[userId] = kept
	return allowed
end

-- RemoteEvent handlers, exposed so the tests can drive them without a client.
function DataService.handleRequestProfile(player: Player, ...: any)
	if select("#", ...) ~= 0 then
		return
	end
	if shuttingDown or not allowRequest(profileWindows, player.UserId) then
		return
	end
	local profile = profiles[player.UserId]
	if profile and profile:IsActive() then
		sendSync(player, profile.Data)
	end
end

function DataService.handleUpdateSettings(player: Player, ...: any)
	if select("#", ...) ~= 1 then
		return
	end
	if not Config.Flags.Saving or shuttingDown then
		return
	end
	if not allowRequest(settingsWindows, player.UserId) then
		return
	end
	local profile = profiles[player.UserId]
	if not profile or not profile:IsActive() then
		return
	end
	local payload = ...
	if typeof(payload) ~= "table" then
		return
	end
	DataService.updateSettings(player.UserId, payload)
end

function DataService.start()
	if not Config.Flags.Saving then
		return
	end
	getStore()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			DataService.load(player.UserId, player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			DataService.load(player.UserId, player)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		DataService.release(player.UserId)
		settingsWindows[player.UserId] = nil
		profileWindows[player.UserId] = nil
	end)
	game:BindToClose(function()
		DataService.shutdown()
	end)
	Remotes.RequestProfile.OnServerEvent:Connect(DataService.handleRequestProfile)
	Remotes.UpdateSettings.OnServerEvent:Connect(DataService.handleUpdateSettings)
end

return DataService
