--!strict
-- Sounds, haptics and camera shake for run events. Every sound has a visual twin in Hud or ResultsUi.

local ContentProvider = game:GetService("ContentProvider")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local HapticService = game:GetService("HapticService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Assets)
local Config = require(Shared.Config)
local Absorb = require(Shared.Rules.Absorb)
local Worlds = require(Shared.Worlds)
local CameraController = require(script.Parent.CameraController)
local RunClient = require(script.Parent.RunClient)

local HAPTIC_STRENGTH = 0.3
local HAPTIC_SECONDS = 0.05
-- Text-free cues of the readable-rules worlds (012 FR-015, FR-017). Look values; owner tuning.
local OBJECT_TAG = "WorldObject"
local LIGHT_TAG = "LightObject"
local BOB_AMPLITUDE = 0.06 -- of the object's longest side
local BOB_HZ = 1.4
local WOBBLE_SECONDS = 0.9
local WOBBLE_ANGLE = math.rad(14)
local CUE_SCAN_INTERVAL = 0.15
local THUD_COOLDOWN = 0.5
local THUD_BOUNCE_SPEED = 8
local THUD_SHAKE_SECONDS = 0.12
local THUD_SHAKE_MAGNITUDE = 0.25

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
	-- The active theme picks its own track (contract theme-content.md §6). With ThemeSystem off no
	-- track plays. "" means no track: nothing plays and no warning.
	if not Config.Flags.ThemeSystem then
		return
	end
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

-- Config.Debug.quietAudio (Studio only): no music, effects capped, whatever the saved settings say.
local function applyDebugAudio()
	if Config.Debug.quietAudio then
		musicGroup.Volume = 0
		effectsGroup.Volume = math.min(effectsGroup.Volume, Config.Debug.quietEffectsVolume)
	end
end

function Feedback.setVolumes(music: number, effects: number)
	musicGroup.Volume = music
	effectsGroup.Volume = effects
	applyDebugAudio()
end

applyDebugAudio()

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

-- Landing thump plus a short squash of the ball's look (006). The squash is a client-only SpecialMesh scale, so
-- the physics size the server owns never changes. It is skipped under Reduce motion; the thump still plays.
local squashTween: Tween? = nil

function Feedback.landed(ball: BasePart, impactSpeed: number)
	play(Assets.sounds.land, math.clamp(1.2 - impactSpeed / 200, 0.8, 1.2))
	if Players.LocalPlayer:GetAttribute("ReduceMotion") == true then
		return
	end
	local mesh = ball:FindFirstChild("SquashMesh")
	if mesh == nil then
		local created = Instance.new("SpecialMesh")
		created.Name = "SquashMesh"
		created.MeshType = Enum.MeshType.Sphere
		created.Parent = ball
		mesh = created
	end
	local squashMesh = mesh :: SpecialMesh
	if squashTween then
		squashTween:Cancel()
	end
	local half = Config.landingSquashDuration / 2
	local scale = Config.landingSquashScale
	squashMesh.Scale = Vector3.new(1 / math.sqrt(scale), scale, 1 / math.sqrt(scale))
	local back = TweenService:Create(
		squashMesh,
		TweenInfo.new(half, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = Vector3.one }
	)
	squashTween = back
	back:Play()
end

-- Bump: contact with a too-big object bounces the ball back with a thud and a short camera nudge. A cooldown stops
-- rubbing along a wall from chattering. Only the readable-rules worlds use it.
local lastThudAt = 0

function Feedback.thud(ball: BasePart, awayFrom: Vector3)
	local now = os.clock()
	if now - lastThudAt < THUD_COOLDOWN then
		return
	end
	lastThudAt = now
	play(Assets.sounds.bump, 0.7)
	local away = Vector3.new(ball.Position.X - awayFrom.X, 0, ball.Position.Z - awayFrom.Z)
	if away.Magnitude > 1e-3 then
		ball.AssemblyLinearVelocity += away.Unit * THUD_BOUNCE_SPEED
	end
	CameraController.shake(THUD_SHAKE_SECONDS, THUD_SHAKE_MAGNITUDE)
end

-- Bob and new-tier wobble. The parts are anchored and only the local copy moves; a part another script moves (a
-- pool reuse, a scatter) is dropped from the animation, never fought over.
type Anim = { home: CFrame, set: CFrame, phase: number, bobbing: boolean, wobbleAt: number? }
local anims: { [BasePart]: Anim } = {}

local function animFor(part: BasePart): Anim
	local anim = anims[part]
	if anim == nil then
		anim = {
			home = part.CFrame,
			set = part.CFrame,
			phase = (part.Position.X * 0.37 + part.Position.Z * 0.51) % (math.pi * 2),
			bobbing = false,
			wobbleAt = nil,
		}
		anims[part] = anim
	end
	return anim :: Anim
end

local function reduceMotion(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceMotion") == true
end

local function tagged(): { Instance }
	local all = CollectionService:GetTagged(OBJECT_TAG)
	table.move(
		CollectionService:GetTagged(LIGHT_TAG),
		1,
		#CollectionService:GetTagged(LIGHT_TAG),
		#all + 1,
		all
	)
	return all
end

local function nearBall(part: BasePart, ball: BasePart, radius: number): boolean
	return part.Parent ~= nil
		and part:GetAttribute("Taken") ~= true
		and part.CanTouch
		and (part.Position - ball.Position).Magnitude <= radius
end

-- Up to Config.bobCount edible objects near the ball, nearest first, bob; too-big objects never move.
local function scanBob(ball: BasePart)
	local diameter = ball:GetAttribute("Diameter")
	if typeof(diameter) ~= "number" or reduceMotion() then
		for _, anim in anims do
			anim.bobbing = false
		end
		return
	end
	local radius = Config.bobRadiusDiameters * diameter
	local found: { { part: BasePart, distance: number } } = {}
	for _, instance in tagged() do
		local part = instance :: BasePart
		if not nearBall(part, ball, radius) then
			continue
		end
		local size, bulk = part:GetAttribute("Size"), part:GetAttribute("Bulk")
		if typeof(size) ~= "number" then
			continue
		end
		if
			Absorb.canEat(
				Worlds.rules.absorb,
				diameter,
				if typeof(bulk) == "number" then bulk else size,
				size
			)
		then
			table.insert(
				found,
				{ part = part, distance = (part.Position - ball.Position).Magnitude }
			)
		end
	end
	table.sort(found, function(a, b)
		return a.distance < b.distance
	end)
	local chosen: { [BasePart]: boolean } = {}
	for index = 1, math.min(#found, Config.bobCount) do
		chosen[found[index].part] = true
		animFor(found[index].part).bobbing = true
	end
	for part, anim in anims do
		if not chosen[part] then
			anim.bobbing = false
		end
	end
end

-- All objects of the newly unlocked tier near the ball wobble once, together.
local function wobbleTier(ball: BasePart, tier: number)
	local diameter = ball:GetAttribute("Diameter")
	if typeof(diameter) ~= "number" or reduceMotion() then
		return
	end
	local radius = Config.wobbleRadiusDiameters * diameter
	local now = os.clock()
	for _, instance in tagged() do
		local part = instance :: BasePart
		if part:GetAttribute("Tier") == tier and nearBall(part, ball, radius) then
			animFor(part).wobbleAt = now
		end
	end
end

local function stepAnims(now: number)
	for part, anim in anims do
		local wobbleAt = anim.wobbleAt
		local wobbling = wobbleAt ~= nil and now - wobbleAt < WOBBLE_SECONDS
		local gone = part.Parent == nil or part:GetAttribute("Taken") == true
		local moved = (part.Position - anim.set.Position).Magnitude > 0.05
		if gone or moved then
			anims[part] = nil
		elseif not anim.bobbing and not wobbling then
			part.CFrame = anim.home
			anims[part] = nil
		else
			local lift = 0
			if anim.bobbing then
				local size = part:GetAttribute("Size")
				lift = math.sin(now * BOB_HZ * math.pi * 2 + anim.phase)
					* BOB_AMPLITUDE
					* (if typeof(size) == "number" then size else 1)
			end
			local roll = 0
			if wobbling then
				local t = (now - (wobbleAt :: number)) / WOBBLE_SECONDS
				roll = WOBBLE_ANGLE * (1 - t) * math.sin(t * math.pi * 6)
			end
			anim.set = anim.home * CFrame.new(0, lift, 0) * CFrame.Angles(0, 0, roll)
			part.CFrame = anim.set
		end
	end
end

local function startCues()
	if Worlds.rules.absorb.mode ~= "bulk" then
		return
	end
	task.spawn(function()
		local ball = Workspace:WaitForChild("Balls")
			:WaitForChild(`Ball_{Players.LocalPlayer.UserId}`)
		local since = 0
		RunService.RenderStepped:Connect(function(dt: number)
			since += dt
			if since >= CUE_SCAN_INTERVAL then
				since = 0
				scanBob(ball :: BasePart)
			end
			stepAnims(os.clock())
		end)
		RunClient.tierUnlocked:Connect(function(tier: number)
			wobbleTier(ball :: BasePart, tier)
		end)
	end)
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
		local paletteId = if atlas ~= "" and atlas ~= nil then atlas else Assets.meshUv
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
	startCues()

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
