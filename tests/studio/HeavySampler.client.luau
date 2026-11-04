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

-- Feature 010 slice mode: when the Workspace attribute `HeavyMode` is "slice" (set by HeavyScene), the sampler leaves the
-- camera alone, drives the player's ball like an eater (nearest absorbable object, up to 18 * sqrt(D / 2) studs/s,
-- capped at 32) and writes one { fps, draw, tris, stuck, parts, d } record per second into the attribute
-- `HeavySliceFps` (JSON) until HeavyStep is -1. draw and tris come from Stats.SceneDrawcallCount and
-- SceneTriangleCount; stuck is the number of client stuck visuals; parts counts BaseParts outside StuckVisuals.
if Workspace:GetAttribute("HeavyMode") == "slice" then
	local CollectionService = game:GetService("CollectionService")
	local Players = game:GetService("Players")
	local Stats = game:GetService("Stats")
	local samples: { { [string]: number } } = {}
	Workspace:SetAttribute("HeavySliceFps", "[]")
	local ball: BasePart? = nil
	local frames, windowStart, retargetAt = 0, os.clock(), 0
	local target: BasePart? = nil
	local sliceConnection: RBXScriptConnection
	sliceConnection = RunService.Heartbeat:Connect(function()
		frames += 1
		local now = os.clock()
		if Workspace:GetAttribute("HeavyStep") == -1 then
			sliceConnection:Disconnect()
			Workspace:SetAttribute("HeavySliceDone", true)
			return
		end
		if ball == nil or ball.Parent == nil then
			local balls = Workspace:FindFirstChild("Balls")
			ball = if balls
				then balls:FindFirstChild(`Ball_{Players.LocalPlayer.UserId}`) :: BasePart?
				else nil
		end
		local mine = ball
		if mine ~= nil then
			local diameter = mine.Size.X
			if target == nil or target:GetAttribute("Taken") == true or now >= retargetAt then
				target = nil
				retargetAt = now + 0.4
				local best = math.huge
				for _, instance in CollectionService:GetTagged("WorldObject") do
					local part = instance :: BasePart
					local size = part:GetAttribute("Size")
					if
						part:GetAttribute("Taken") ~= true
						and typeof(size) == "number"
						and size <= 0.4 * diameter
					then
						local distance = (part.Position - mine.Position).Magnitude
						if distance < best then
							best, target = distance, part
						end
					end
				end
			end
			if target ~= nil then
				local flat = target.Position - mine.Position
				flat = Vector3.new(flat.X, 0, flat.Z)
				if flat.Magnitude > 0.05 then
					local speed = math.min(18 * math.sqrt(diameter / 2), 32)
					local velocity = mine.AssemblyLinearVelocity
					mine.AssemblyLinearVelocity =
						Vector3.new(flat.Unit.X * speed, velocity.Y, flat.Unit.Z * speed)
				end
			end
		end
		if now - windowStart >= 1 then
			local stuckFolder = Workspace:FindFirstChild("StuckVisuals")
			local stuck = if stuckFolder then #stuckFolder:GetChildren() else 0
			local parts = 0
			for _, descendant in Workspace:GetDescendants() do
				if
					descendant:IsA("BasePart")
					and (stuckFolder == nil or not descendant:IsDescendantOf(stuckFolder))
				then
					parts += 1
				end
			end
			local okDraw, draw = pcall(function()
				return Stats.SceneDrawcallCount
			end)
			local okTris, tris = pcall(function()
				return Stats.SceneTriangleCount
			end)
			table.insert(samples, {
				fps = math.floor(frames / (now - windowStart) * 10 + 0.5) / 10,
				draw = if okDraw then draw else -1,
				tris = if okTris then tris else -1,
				stuck = stuck,
				parts = parts,
				d = if mine then math.floor(mine.Size.X * 10) / 10 else 0,
			})
			frames, windowStart = 0, now
			Workspace:SetAttribute("HeavySliceFps", HttpService:JSONEncode(samples))
		end
	end)
	print("HeavySampler: slice mode, recording")
	return
end

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
