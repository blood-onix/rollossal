--!strict
-- Default Custom camera on the local ball, with the zoom limits eased towards 4 x diameter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Movement = require(Shared.Rules.Movement)

local CameraController = {}

local SHAKE_BIND = "RollossalCameraShake"
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
	RunService:BindToRenderStep(SHAKE_BIND, Enum.RenderPriority.Camera.Value + 1, function()
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

function CameraController.setSensitivity(value: number)
	local UIS = game:GetService("UserInputService")
	pcall(function()
		UIS.MouseDeltaSensitivity = value
	end)
end

function CameraController.start()
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`) :: BasePart
	local camera = Workspace.CurrentCamera :: Camera

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = ball

	local function targetDistance(): number
		local attribute = ball:GetAttribute("Diameter")
		local diameter = if typeof(attribute) == "number" then attribute else Config.startDiameter
		return Movement.cameraDistance(
			diameter,
			Config.cameraMultiplier,
			Config.cameraMinDistance,
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
