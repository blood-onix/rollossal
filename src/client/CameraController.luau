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
