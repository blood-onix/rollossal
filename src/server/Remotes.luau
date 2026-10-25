--!strict
-- Creates ReplicatedStorage.Remotes with the three RemoteEvents from contracts/remotes.md.
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
}

return Remotes
