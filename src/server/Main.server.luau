--!strict
-- Starts the server services in order, then drives the per-Heartbeat room and ball updates.

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

require(script.Parent.Remotes)
local WorldSpawner = require(script.Parent.WorldSpawner)
local BallService = require(script.Parent.BallService)
local AbsorbService = require(script.Parent.AbsorbService)
local FriendCache = require(script.Parent.FriendCache)
local RunManager = require(script.Parent.RunManager)

if Config.Flags.Saving then
	local DataService = require(script.Parent.DataService)
	DataService.start()
end

WorldSpawner.start()
FriendCache.start()
BallService.start()
AbsorbService.start()
RunManager.start()

RunService.Heartbeat:Connect(function(dt: number)
	local now = os.clock()
	WorldSpawner.update(now)
	BallService.step(now, dt)
	RunManager.step(now)
end)
