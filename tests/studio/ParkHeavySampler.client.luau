--!strict
-- 012 G6, reused by 014 US4: the client half of the Park City 12-ball benchmark. Not shipped; copy its source into the Client datamodel
-- with the Studio MCP `execute_luau` during Play, after ParkHeavyScene is running on the server. It records one fps
-- value per second for SECONDS seconds into the local Workspace attribute `ParkHeavyFps` (JSON: fps list, the
-- viewport size, the light pool size and how many of its slots are meshes) and returns at once; read it later with
--   return workspace:GetAttribute("ParkHeavyFps")
-- `fps` counts RenderStepped, the frames actually drawn; `heartbeat` is the same count for Heartbeat, which stays near 60
-- when Studio is not drawing, so it is never the frame rate. Seconds at about 15 fps (or 0) with Heartbeat near 60 are
-- throttled Studio, not the scene: report them separately.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SECONDS = 60

local function meshSlots(): number
	local count = 0
	for _, part in CollectionService:GetTagged("LightObject") do
		if part:IsA("MeshPart") then
			count += 1
		end
	end
	return count
end
local function perSecond(count: number, seconds: number): number
	return math.floor(count / seconds * 10 + 0.5) / 10
end

local samples: { number } = {}
local heartbeats: { number } = {}
local frames = 0
local beats = 0
local windowStart = os.clock()
local renderConnection = RunService.RenderStepped:Connect(function()
	frames += 1
end)
local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function()
	beats += 1
	local now = os.clock()
	if now - windowStart >= 1 then
		table.insert(samples, perSecond(frames, now - windowStart))
		table.insert(heartbeats, perSecond(beats, now - windowStart))
		frames = 0
		beats = 0
		windowStart = now
		local camera = Workspace.CurrentCamera
		Workspace:SetAttribute(
			"ParkHeavyFps",
			HttpService:JSONEncode({
				fps = samples,
				heartbeat = heartbeats,
				done = #samples >= SECONDS,
				viewport = if camera then { camera.ViewportSize.X, camera.ViewportSize.Y } else nil,
				lightPool = #CollectionService:GetTagged("LightObject"),
				lightMeshes = meshSlots(),
			})
		)
		if #samples >= SECONDS then
			renderConnection:Disconnect()
			connection:Disconnect()
		end
	end
end)
