--!strict
-- Single reader of ProfileSync on the client. Never writes into the snapshot; never sends it back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Localizer = require(Shared.Localization.Localizer)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ProfileClient = {}

local snapshot = {
	coins = 0,
	bestSize = {} :: { [string]: number },
	book = {} :: { [string]: boolean },
	skinsOwned = {} :: { [string]: boolean },
	equipped = {} :: { [string]: boolean },
	settings = {
		musicVolume = Config.Settings.musicVolume.default,
		effectsVolume = Config.Settings.effectsVolume.default,
		cameraSensitivity = Config.Settings.cameraSensitivity.default,
		reduceMotion = Config.Settings.reduceMotionDefault,
		language = Config.Settings.languageDefault,
	},
}
local loaded = false
local listeners: { () -> () } = {}
local pending: { [string]: any }? = nil
local debounceThread: thread? = nil

local function fireChanged()
	for _, fn in listeners do
		task.spawn(fn)
	end
end

local function deepCopy(t: any): any
	if typeof(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t do
		out[k] = deepCopy(v)
	end
	return out
end

function ProfileClient.coins(): number
	return snapshot.coins
end

function ProfileClient.bestSize(worldId: string): number?
	return snapshot.bestSize[worldId]
end

function ProfileClient.book(): { [string]: boolean }
	return deepCopy(snapshot.book)
end

function ProfileClient.skinsOwned(): { [string]: boolean }
	return deepCopy(snapshot.skinsOwned)
end

function ProfileClient.equipped(): { [string]: boolean }
	return deepCopy(snapshot.equipped)
end

function ProfileClient.settings(): any
	return deepCopy(snapshot.settings)
end

function ProfileClient.isLoaded(): boolean
	return loaded
end

function ProfileClient.changedConnect(fn: () -> ()): ()
	table.insert(listeners, fn)
end

ProfileClient.changed = {
	Connect = function(_self: any, fn: () -> ())
		table.insert(listeners, fn)
	end,
}

local function parse(s: any): boolean
	if typeof(s) ~= "table" then
		return false
	end
	if typeof(s.coins) ~= "number" then
		return false
	end
	if typeof(s.bestSize) ~= "table" then
		return false
	end
	if typeof(s.book) ~= "table" then
		return false
	end
	if typeof(s.skinsOwned) ~= "table" then
		return false
	end
	if typeof(s.equipped) ~= "table" then
		return false
	end
	if typeof(s.settings) ~= "table" then
		return false
	end
	snapshot.coins = s.coins
	snapshot.bestSize = deepCopy(s.bestSize)
	snapshot.book = deepCopy(s.book)
	snapshot.skinsOwned = deepCopy(s.skinsOwned)
	snapshot.equipped = deepCopy(s.equipped)
	snapshot.settings = deepCopy(s.settings)
	loaded = true
	return true
end

local function applySettings(s: any)
	local Feedback = require(script.Parent.Feedback)
	local CameraController = require(script.Parent.CameraController)
	Feedback.setVolumes(s.musicVolume, s.effectsVolume)
	Feedback.setReduceMotion(s.reduceMotion)
	CameraController.setSensitivity(s.cameraSensitivity)
	Localizer.setLanguage(s.language)
end

-- Applies a settings table on this client at once, before the server has answered. The snapshot is not
-- touched: the server echo (ProfileSync) stays the only thing that writes it.
function ProfileClient.preview(settings: any)
	applySettings(settings)
end

function ProfileClient.start()
	if not Config.Flags.Saving then
		return
	end
	local profileSync = Remotes:WaitForChild("ProfileSync") :: RemoteEvent
	profileSync.OnClientEvent:Connect(function(payload)
		if parse(payload) then
			applySettings(snapshot.settings)
			fireChanged()
		end
	end)
	-- fire RequestProfile after connecting
	task.defer(function()
		(Remotes:WaitForChild("RequestProfile") :: RemoteEvent):FireServer()
	end)
end

function ProfileClient.sendSettings(candidate: any)
	if not Config.Flags.Saving then
		return
	end
	pending = candidate
	if debounceThread then
		task.cancel(debounceThread)
	end
	debounceThread = task.delay(Config.settingsSendDelay, function()
		debounceThread = nil
		local p = pending
		pending = nil
		if p ~= nil then
			(Remotes:WaitForChild("UpdateSettings") :: RemoteEvent):FireServer(p)
		end
	end)
end

function ProfileClient.flush()
	if debounceThread then
		task.cancel(debounceThread)
		debounceThread = nil
	end
	local p = pending
	pending = nil
	if p ~= nil then
		(Remotes:WaitForChild("UpdateSettings") :: RemoteEvent):FireServer(p)
	end
end

return ProfileClient
