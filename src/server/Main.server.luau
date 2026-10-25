--!strict
-- Starts the server services in order, then drives the per-Heartbeat room and ball updates.

local RunService = game:GetService("RunService")

require(script.Parent.Remotes)
local WorldSpawner = require(script.Parent.WorldSpawner)
local BallService = require(script.Parent.BallService)
local AbsorbService = require(script.Parent.AbsorbService)

WorldSpawner.start()
BallService.start()
AbsorbService.start()

RunService.Heartbeat:Connect(function(dt: number)
	local now = os.clock()
	WorldSpawner.update(now)
	BallService.step(now, dt)
end)
