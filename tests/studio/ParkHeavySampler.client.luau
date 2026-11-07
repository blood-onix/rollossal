--!strict
-- 012 G6: the client half of the Park City 12-ball benchmark. Not shipped; copy its source into the Client datamodel
-- with the Studio MCP `execute_luau` during Play, after ParkHeavyScene is running on the server. It records one fps
-- value per second for SECONDS seconds into the local Workspace attribute `ParkHeavyFps` (JSON: fps list, the
-- viewport size and the light pool size) and returns at once; read it later with
--   return workspace:GetAttribute("ParkHeavyFps")
-- Seconds at exactly 15 fps are throttled Studio, not the scene: report them separately.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SECONDS = 60
local samples: { number } = {}
local frames = 0
local windowStart = os.clock()
local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function()
	frames += 1
	local now = os.clock()
	if now - windowStart >= 1 then
		table.insert(samples, math.floor(frames / (now - windowStart) * 10 + 0.5) / 10)
		frames = 0
		windowStart = now
		local camera = Workspace.CurrentCamera
		Workspace:SetAttribute(
			"ParkHeavyFps",
			HttpService:JSONEncode({
				fps = samples,
				done = #samples >= SECONDS,
				viewport = if camera then { camera.ViewportSize.X, camera.ViewportSize.Y } else nil,
				lightPool = #CollectionService:GetTagged("LightObject"),
			})
		)
		if #samples >= SECONDS then
			connection:Disconnect()
		end
	end
end)
