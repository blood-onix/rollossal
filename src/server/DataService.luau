--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Localizer = require(Shared.Localization.Localizer)
local Book = require(Shared.Rules.Book)
local Profile = require(Shared.Rules.Profile)
local Settings = require(Shared.Rules.Settings)
local Worlds = require(Shared.Worlds)

local ServerPackages = script.Parent:WaitForChild("ServerPackages")
local ProfileStore = require(ServerPackages:WaitForChild("ProfileStore"))

local Remotes = require(script.Parent.Remotes)

local DataService = {}

local store = nil
local profiles: { [number]: any } = {}
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

local function sendSync(player: Player, data: any)
	local snap = {
		coins = data.coins,
		bestSize = {},
		book = {},
		skinsOwned = {},
		equipped = {},
		settings = {},
	}
	for k, v in data.bestSize do
		snap.bestSize[k] = v
	end
	for k, v in data.book do
		snap.book[k] = v
	end
	for k, v in data.skinsOwned do
		snap.skinsOwned[k] = v
	end
	for k, v in data.equipped do
		snap.equipped[k] = v
	end
	for k, v in data.settings do
		snap.settings[k] = v
	end
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
	local data = p.Data
	local snap = {
		coins = data.coins,
		bestSize = {},
		book = {},
		skinsOwned = {},
		equipped = {},
		settings = {},
	}
	for k, v in data.bestSize do
		snap.bestSize[k] = v
	end
	for k, v in data.book do
		snap.book[k] = v
	end
	for k, v in data.skinsOwned do
		snap.skinsOwned[k] = v
	end
	for k, v in data.equipped do
		snap.equipped[k] = v
	end
	for k, v in data.settings do
		snap.settings[k] = v
	end
	return snap
end

function DataService.getBook(userId: number): any
	local p = profiles[userId]
	if not p or not p:IsActive() then
		return nil
	end
	local out = table.clone(p.Data.book)
	return out
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
		warn(userId)
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
	local d = buildDefaults()
	local _result = Profile.prepare(profile.Data, d)
	-- version handling
	local version = profile.Data.version
	if typeof(version) ~= "number" then
		profile:EndSession()
		kickFn(player, Localizer.t("error.profile_version", nil, player.LocaleId))
		warn(userId)
		return false
	end
	-- migrate
	local target = Profile.SCHEMA_VERSION
	if version > target then
		profile:EndSession()
		kickFn(player, Localizer.t("error.profile_version", nil, player.LocaleId))
		warn(userId)
		return false
	end
	-- reconcile
	Profile.reconcile(profile.Data, d)
	-- prepare
	Profile.prepare(profile.Data, d)
	profile.OnSessionEnd:Connect(function()
		-- Only a session ended behind our back (lock stolen) kicks; release() forgets the entry first.
		if profiles[userId] == profile and (player.Parent :: Instance?) ~= nil then
			kickFn(player, Localizer.t("error.session_ended", nil, player.LocaleId))
		end
		if profiles[userId] == profile then
			profiles[userId] = nil
		end
	end)
	profiles[userId] = profile
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
	if outcome == nil then
		return nil
	end
	-- Profile.applyRunResult returns? contract: writes nothing before checks pass; returns Outcome
	sendSync(Players:GetPlayerByUserId(userId) or nil, profile.Data)
	return outcome
end

function DataService.release(userId: number)
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
	local player = Players:GetPlayerByUserId(userId)
	if player then
		sendSync(player, profile.Data)
	end
	return true
end

-- RateLimit per player window
local rateWindows: any = {}

-- RemoteEvent handlers, exposed so the tests can drive them without a client.
function DataService.handleRequestProfile(player: Player, ...: any)
	if select("#", ...) ~= 0 then
		return
	end
	if shuttingDown then
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
	local now = os.clock()
	local w = rateWindows[player.UserId]
	if not w or now > w.reset then
		w = { count = 0, reset = now + Config.rateLimitWindow }
		rateWindows[player.UserId] = w
	end
	if w.count >= Config.settingsRateLimit then
		return
	end
	w.count += 1
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
		rateWindows[player.UserId] = nil
	end)
	game:BindToClose(function()
		DataService.shutdown()
	end)
	Remotes.RequestProfile.OnServerEvent:Connect(DataService.handleRequestProfile)
	Remotes.UpdateSettings.OnServerEvent:Connect(DataService.handleUpdateSettings)
end

return DataService
