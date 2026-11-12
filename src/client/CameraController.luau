--!strict
-- Default Custom camera on the local ball, with the zoom limits eased towards 4 x diameter, and a
-- sensitivity factor applied on top of whatever look input (mouse, touch, gamepad) the default camera reads.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Movement = require(Shared.Rules.Movement)
local CameraLook = require(Shared.Rules.CameraLook)
local Worlds = require(Shared.Worlds)

local SPAWN_VIEW_SECONDS = 2

local CameraController = {}

local SHAKE_BIND = "RollossalCameraShake"
local LOOK_BIND = "RollossalCameraLook"
local MAX_PITCH = math.rad(80)
local sensitivity = 1
local shakeEndsAt = 0
local shakeDuration = 0
local shakeMagnitude = 0
local shakeRandom = Random.new()

-- Adds a decaying random offset to the camera for `duration` seconds. Skipped when the player has
-- ReduceMotion on. Runs after the camera update, so it never fights the default camera script.
function CameraController.shake(duration: number, magnitude: number)
	if Players.LocalPlayer:GetAttribute("ReduceMotion") == true then
		return
	end
	local bound = shakeEndsAt > os.clock()
	shakeDuration = duration
	shakeMagnitude = magnitude
	shakeEndsAt = os.clock() + duration
	if bound then
		return
	end
	RunService:BindToRenderStep(SHAKE_BIND, Enum.RenderPriority.Camera.Value + 2, function()
		local remaining = shakeEndsAt - os.clock()
		if remaining <= 0 then
			RunService:UnbindFromRenderStep(SHAKE_BIND)
			return
		end
		local strength = shakeMagnitude * remaining / shakeDuration
		local camera = Workspace.CurrentCamera :: Camera
		camera.CFrame *= CFrame.new(
			shakeRandom:NextNumber(-strength, strength),
			shakeRandom:NextNumber(-strength, strength),
			0
		)
	end)
end

-- The default camera script has no sensitivity setting for touch or gamepad, so the factor is applied
-- after it runs: see bindLook. MouseDeltaSensitivity stays at its default so mouse look is not scaled twice.
function CameraController.setSensitivity(value: number)
	sensitivity = value
end

-- Each frame, adds (sensitivity - 1) times the default camera's turn since the last frame, as extra yaw
-- and pitch around the camera focus. The default script continues from the CFrame it finds, so last
-- frame's extra is already in it: only this frame's increment is applied, and the direction left behind
-- is kept so the next frame's difference is the player's drag alone.
local function bindLook()
	local prevYaw: number? = nil
	local prevPitch: number? = nil
	RunService:BindToRenderStep(LOOK_BIND, Enum.RenderPriority.Camera.Value + 1, function()
		local camera = Workspace.CurrentCamera :: Camera
		local cframe = camera.CFrame
		local look = cframe.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		local pitch = math.asin(math.clamp(look.Y, -1, 1))
		local extraYaw, extraPitch =
			CameraLook.advance(prevYaw, prevPitch, yaw, pitch, sensitivity, MAX_PITCH)
		prevYaw, prevPitch = CameraLook.wrap(yaw + extraYaw), pitch + extraPitch
		if extraYaw == 0 and extraPitch == 0 then
			return
		end
		local rotation = cframe.Rotation
		local focus = camera.Focus.Position
		local offset = rotation:Inverse() * (cframe.Position - focus)
		local turned = CFrame.Angles(0, extraYaw, 0) * rotation * CFrame.Angles(extraPitch, 0, 0)
		camera.CFrame = CFrame.new(focus + turned * offset) * turned
	end)
end

function CameraController.start()
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`) :: BasePart
	local camera = Workspace.CurrentCamera :: Camera

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = ball
	-- Park City (012): a new ball starts at one of the 12 spawns, looking towards the city. `yaw` is a compass
	-- bearing (north 0, east 90; north is -Z), the spawn's facing in the layout.
	if Worlds.rules.absorb.mode == "bulk" then
		-- The default camera script settles on its own heading in its first frames, so the view is held until it has.
		local held = 0
		RunService:BindToRenderStep(
			"SpawnView",
			Enum.RenderPriority.Camera.Value + 2,
			function(dt: number)
				if held > SPAWN_VIEW_SECONDS then
					RunService:UnbindFromRenderStep("SpawnView")
					return
				end
				local nearest: { x: number, z: number, yaw: number }? = nil
				local best = math.huge
				for _, point in Worlds.active.spawnPoints do
					local distance = (Vector3.new(point.x, 0, point.z) - Vector3.new(
						ball.Position.X,
						0,
						ball.Position.Z
					)).Magnitude
					if distance < best then
						best, nearest = distance, point
					end
				end
				if nearest ~= nil and best < 60 then
					held += dt
					local bearing = math.rad(nearest.yaw)
					local heading = Vector3.new(math.sin(bearing), 0, -math.cos(bearing))
					camera.CFrame = CFrame.lookAt(
						ball.Position - heading * 8 + Vector3.new(0, 4, 0),
						ball.Position
					)
				end
			end
		)
	end
	bindLook()

	local function targetDistance(): number
		local attribute = ball:GetAttribute("Diameter")
		local diameter = if typeof(attribute) == "number"
			then attribute
			else Worlds.rules.startDiameter
		return Movement.cameraDistance(
			diameter,
			Config.cameraMultiplier,
			Worlds.rules.cameraMinDistance,
			Config.cameraMaxDistance
		)
	end

	local distance = targetDistance()
	RunService.RenderStepped:Connect(function(dt: number)
		distance += (targetDistance() - distance) * (1 - math.exp(-Config.cameraSmoothing * dt))
		player.CameraMinZoomDistance = distance
		player.CameraMaxZoomDistance = distance
	end)
end

return CameraController
