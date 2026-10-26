--!strict
-- Creates ReplicatedStorage.Remotes with the twelve RemoteEvents from the contracts/remotes.md files of 001 (three),
-- 002 (six) and 003 (three).
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

local folder = getOrCreateFolder(ReplicatedStorage, "Remotes")

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
}

return Remotes
