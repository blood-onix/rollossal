--!strict
-- The one weather emitter (005, contracts/theme-content.md §6). A single transparent part rides the
-- camera, high above the player's head, and holds the ParticleEmitter that renders the active
-- theme's weather. All numbers come from the theme data; the only Config values read here are
-- weatherEmitterHeight and weatherEmitterSize.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Worlds = require(Shared.Worlds)

local WeatherController = {}

local anchor: BasePart? = nil
local emitter: ParticleEmitter? = nil

-- The active theme's weather; nil with the ThemeSystem flag off (the pre-005 rollback).
local function weather(): any
	local theme = Worlds.activeTheme
	return if theme ~= nil then theme.weather else nil
end

local function applyEnabled()
	local current = emitter
	if current == nil then
		return
	end
	local reduceMotion = Players.LocalPlayer:GetAttribute("ReduceMotion") == true
	local data = weather()
	local enabled = not reduceMotion and data ~= nil and data.kind ~= "none"
	if enabled and data ~= nil then
		current.Color =
			ColorSequence.new(Color3.fromRGB(data.color[1], data.color[2], data.color[3]))
		current.Rate = data.rate
		current.Lifetime = NumberRange.new(data.lifetime * 0.8, data.lifetime)
		current.Speed = NumberRange.new(data.speed)
		current.Size = NumberSequence.new(data.size)
	end
	-- Clear on every transition to disabled, so a re-enable never replays old particles.
	if not enabled and current.Enabled then
		current:Clear()
	end
	current.Enabled = enabled
end

-- For the Studio specs: true exactly while the emitter is on.
function WeatherController.isEmitting(): boolean
	local current = emitter
	return current ~= nil and current.Enabled
end

function WeatherController.start()
	if not Config.Flags.ThemeSystem then
		return
	end
	if anchor ~= nil then
		return
	end
	-- One emitter total, created on start, destroyed never. The kind is disabled (or the world has
	-- no weather) until applyEnabled says otherwise.
	local frame = Instance.new("Part")
	frame.Name = "WeatherEmitter"
	frame.Anchored = true
	frame.CanCollide = false
	frame.CanQuery = false
	frame.CanTouch = false
	frame.CastShadow = false
	frame.Transparency = 1
	frame.Size = Vector3.one * Config.weatherEmitterSize
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "ThemeWeather"
	particles.Enabled = false
	particles.Parent = frame
	anchor = frame :: BasePart
	frame.Parent = workspace
	emitter = particles
	applyEnabled()

	Players.LocalPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(applyEnabled)

	RunService.RenderStepped:Connect(function()
		local current = anchor
		if current == nil then
			return
		end
		-- Read the camera every render, so a replacement camera is followed without re-connecting.
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		current.CFrame = camera.CFrame * CFrame.new(0, Config.weatherEmitterHeight, 0)
	end)
end

return WeatherController
