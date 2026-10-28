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

local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "Music"
musicGroup.Parent = SoundService
local effectsGroup = Instance.new("SoundGroup")
effectsGroup.Name = "Effects"
effectsGroup.Parent = SoundService

-- The one looping background track, in the Music group so settings.musicVolume controls it. Nil while
-- the active theme's Assets.sounds key is empty.
local musicTrack: Sound? = nil

local function createMusic()
	-- The active theme picks its own track (contract theme-content.md §6); with no theme the winter
	-- track is today's behaviour (the rollback). "" means no track: nothing plays and no warning.
	local theme = Worlds.activeTheme
	local key = if theme ~= nil then theme.musicAssetKey else "musicWinter"
	local soundId = Assets.sounds[key]
	if soundId == "" or soundId == nil then
		return
	end
	local track = Instance.new("Sound")
	track.Name = "ThemeMusic"
	track.SoundId = soundId
	track.Looped = true
	track.Volume = 1
	track.SoundGroup = musicGroup
	track.Parent = SoundService
	musicTrack = track
end

function Feedback.setVolumes(music: number, effects: number)
	musicGroup.Volume = music
	effectsGroup.Volume = effects
end

-- The ReduceMotion attribute is the saved setting OR the engine's reduced-motion setting. Both sources
-- recompute it from here, so neither can overwrite the other.
local savedReduceMotion = false

local function applyReduceMotion()
	Players.LocalPlayer:SetAttribute(
		"ReduceMotion",
		savedReduceMotion or GuiService.ReducedMotionEnabled
	)
end

function Feedback.setReduceMotion(on: boolean)
	savedReduceMotion = on
	applyReduceMotion()
end

local function play(soundId: string, speed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.PlaybackSpeed = speed or 1
	sound.SoundGroup = effectsGroup
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
		-- Music is preloaded as its Sound instance below; a bare string id here fails as a type mismatch.
		-- (Contract theme-content.md §6: the preload list skips every music* key.)
		for key, soundId in Assets.sounds do
			if string.sub(key, 1, 5) ~= "music" and soundId ~= "" then
				table.insert(ids, soundId)
			end
		end
		-- The palette texture loads here too. The active theme's atlas when the meshes are atlas-era
		-- ("" means not imported yet); else the legacy shared palette. "" skips the preload. Meshes
		-- are not preloaded: PreloadAsync on a bare mesh id logs "Asset type does not match requested
		-- type"; ObjectVisual loads them with CreateMeshPartAsync.
		local theme = Worlds.activeTheme
		local atlas = if theme ~= nil then Assets.palettes[theme.paletteAssetKey] else ""
		local paletteId = if atlas ~= "" and atlas ~= nil then atlas else Assets.palette
		if paletteId ~= nil and paletteId ~= "" then
			table.insert(ids, paletteId)
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, ids)
		-- The music starts only once it is loaded, so it never begins late or stutters.
		local track = musicTrack
		if track then
			pcall(ContentProvider.PreloadAsync, ContentProvider, { track })
			track:Play()
		end
	end)
end

-- The engine exposes the player's reduced-motion setting (GuiService.ReducedMotionEnabled), so the
-- ReduceMotion attribute follows it as well as the saved setting.
local function followReducedMotion()
	applyReduceMotion()
	GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"):Connect(applyReduceMotion)
end

function Feedback.start()
	followReducedMotion()
	createMusic()
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
