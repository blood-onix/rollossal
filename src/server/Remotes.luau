--!strict
-- Creates ReplicatedStorage.Remotes with the thirteen RemoteEvents from the contracts/remotes.md files of 001 (three),
-- 002 (six), 003 (three) and 006 (one).
-- Required by Main.server before any player joins; idempotent if the folder already exists.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getOrCreateEvent(parent: Instance, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = parent
	return event
end

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local folder = getOrCreateFolder(ReplicatedStorage, "Remotes")

-- Park City remotes (012). Created only when their flag is on, so the other worlds keep the thirteen events.
local function whenOn(flag: boolean, name: string): RemoteEvent?
	return if flag then getOrCreateEvent(folder, name) else nil
end

local Remotes = {
	Absorb = getOrCreateEvent(folder, "Absorb"),
	Bump = getOrCreateEvent(folder, "Bump"),
	RespawnBall = getOrCreateEvent(folder, "RespawnBall"),
	-- Run loop (specs/002-run-loop/contracts/remotes.md): two zero-argument intents, four facts.
	RollAgain = getOrCreateEvent(folder, "RollAgain"),
	BackToHub = getOrCreateEvent(folder, "BackToHub"),
	PickupConfirmed = getOrCreateEvent(folder, "PickupConfirmed"),
	TierUnlocked = getOrCreateEvent(folder, "TierUnlocked"),
	KnockedOff = getOrCreateEvent(folder, "KnockedOff"),
	RunResult = getOrCreateEvent(folder, "RunResult"),
	-- Saving and economy (specs/003-saving-and-economy/contracts/remotes.md): two intents, one fact.
	UpdateSettings = getOrCreateEvent(folder, "UpdateSettings"),
	RequestProfile = getOrCreateEvent(folder, "RequestProfile"),
	ProfileSync = getOrCreateEvent(folder, "ProfileSync"),
	-- Mechanics pass (specs/006-jump-boosters-traps/contracts/runtime-api.md): one intent, a marker id string.
	ClaimBooster = getOrCreateEvent(folder, "ClaimBooster"),
	-- Park City (012): LightDelta is server to client (indices only); DebugSize is the Studio-only size tool.
	LightDelta = whenOn(Config.Flags.ParkCity, "LightDelta"),
	DebugSize = whenOn(Config.Flags.DebugSize, "DebugSize"),
}

return Remotes
