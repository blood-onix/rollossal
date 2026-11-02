--!strict
-- Feature 009, US4: the client half of the heavy-scene benchmark. Not shipped and never run from ServerStorage: copy
-- its source into the Client datamodel with the Studio MCP `execute_luau` during Play, after HeavyScene has been
-- cloned into ServerScriptService on the server. It points the camera at the scene, then writes one fps value per
-- second for every step into the Workspace attribute `HeavyFps` (JSON keyed by step; set on the client, so it stays
-- local) and returns at once; read the result later with
--   return workspace:GetAttribute("HeavyFps")
-- Seconds at exactly 15 fps are throttled Studio, not the scene: report them separately and judge the rest.

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WARMUP_SECONDS = 10
local SAMPLE_SECONDS = 60
local CAMERA_HEIGHT = 330
local THROTTLED_FPS = 15

local results: { [string]: { number } } = {}
Workspace:SetAttribute("HeavyFps", "{}")

local camera = Workspace.CurrentCamera
local centre = Workspace:GetAttribute("HeavyCentre")
if camera == nil or typeof(centre) ~= "Vector3" then
	error("HeavySampler: start HeavyScene first")
end
local CAMERA_CFRAME = CFrame.lookAt(centre + Vector3.new(0, CAMERA_HEIGHT, 1), centre)
-- execute_luau puts the camera back to Custom when it returns, and the game's CameraController moves it every frame,
-- so the pose is applied again after the camera scripts on every render step.
RunService:BindToRenderStep("HeavySamplerCamera", Enum.RenderPriority.Camera.Value + 10, function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 70
	camera.CFrame = CAMERA_CFRAME
end)

local frames = 0
local windowStart = os.clock()
local step = 0
local stepStart = 0
local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function()
	frames += 1
	local now = os.clock()
	local current = Workspace:GetAttribute("HeavyStep")
	if typeof(current) ~= "number" then
		return
	end
	if current ~= step then
		step = current
		stepStart = now
		windowStart = now
		frames = 0
		if step == -1 then
			connection:Disconnect()
			RunService:UnbindFromRenderStep("HeavySamplerCamera")
			results.done = { 1 }
			Workspace:SetAttribute("HeavyFps", HttpService:JSONEncode(results))
			return
		end
		results[tostring(step)] = {}
		return
	end
	if now - windowStart >= 1 then
		local fps = frames / (now - windowStart)
		frames = 0
		windowStart = now
		local list = results[tostring(step)]
		if list ~= nil and now - stepStart >= WARMUP_SECONDS and #list < SAMPLE_SECONDS then
			table.insert(list, math.floor(fps * 10 + 0.5) / 10)
			Workspace:SetAttribute("HeavyFps", HttpService:JSONEncode(results))
		end
	end
end)
print(`HeavySampler: recording; throttled seconds read about {THROTTLED_FPS} fps`)
