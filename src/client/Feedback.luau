--!strict
-- Sounds, haptics and camera shake for run events. Every sound has a visual twin in Hud or ResultsUi.

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local HapticService = game:GetService("HapticService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Assets)
local Config = require(Shared.Config)
local Worlds = require(Shared.Worlds)
local CameraController = require(script.Parent.CameraController)
local RunClient = require(script.Parent.RunClient)

local HAPTIC_STRENGTH = 0.3
local HAPTIC_SECONDS = 0.05

local Feedback = {}

local function play(soundId: string, speed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.PlaybackSpeed = speed or 1
	sound.Parent = SoundService
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
end

-- Unsupported devices skip silently; nothing here may raise.
local function haptic()
	pcall(function()
		local input = Enum.UserInputType.Gamepad1
		if HapticService:IsVibrationSupported(input) then
			HapticService:SetMotor(input, Enum.VibrationMotor.Small, HAPTIC_STRENGTH)
			task.delay(HAPTIC_SECONDS, function()
				pcall(HapticService.SetMotor, HapticService, input, Enum.VibrationMotor.Small, 0)
			end)
		end
	end)
end

-- A sound created on first use is still loading when Play is called, so the first tier banner or bell
-- would be late or silent. Preloading happens off the main thread and never raises.
local function preloadSounds()
	task.spawn(function()
		local ids = {}
		for _, soundId in Assets.sounds do
			table.insert(ids, soundId)
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, ids)
	end)
end

-- The engine exposes the player's reduced-motion setting (GuiService.ReducedMotionEnabled, checked in
-- T038), so the ReduceMotion attribute follows it (research R11).
local function followReducedMotion()
	local player = Players.LocalPlayer
	local function sync()
		player:SetAttribute("ReduceMotion", GuiService.ReducedMotionEnabled)
	end
	sync()
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(sync)
end

function Feedback.start()
	followReducedMotion()
	preloadSounds()

	RunClient.pickup:Connect(function(objectId: string)
		local object = Worlds.objectById[objectId]
		local tier = if object then object.tier else 1
		play(Assets.sounds.pickup, 1 + Config.pickupPitchStep * (tier - 1))
		haptic()
	end)
	RunClient.tierUnlocked:Connect(function()
		play(Assets.sounds.tierUnlock)
	end)
	RunClient.knockedOff:Connect(function()
		play(Assets.sounds.bump)
		CameraController.shake(Config.knockOffShakeDuration, Config.knockOffShakeMagnitude)
	end)
	RunClient.result:Connect(function()
		play(Assets.sounds.bell)
	end)
end

return Feedback
