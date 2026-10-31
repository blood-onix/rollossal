--!strict
-- Ambient pigeons (007, research R-14). Client-only decoration: small anchored parts that stand where the world
-- data puts them (Worlds.active.ambient.pigeons) and fly off when the player's ball gets close. They are never
-- tagged as world objects, never absorbable, never replicated, and skipped under Reduce motion. A pigeon that has
-- flown away stays gone for the rest of the run (the Studio spec restarts the controller state with a new run).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Worlds = require(Shared.Worlds)

local MAX_PER_DISTRICT = 8
local SCARE_DISTANCE = 12
local FLY_SECONDS = 1.2
local FLY_RISE = 26
local FLY_AWAY = 30
local PIGEON_SIZE = Vector3.new(0.9, 0.7, 1.4)
local PIGEON_COLOUR = Color3.fromRGB(150, 156, 168)
local GROUND_OFFSET = 0.35
local CHECK_INTERVAL = 0.2

type Pigeon = { part: Part, flown: boolean }

local PigeonController = {}

local folder: Folder? = nil
local pigeons: { Pigeon } = {}
local started = false

local function reduceMotion(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceMotion") == true
end

local function applyVisibility()
	local hidden = reduceMotion()
	for _, pigeon in pigeons do
		pigeon.part.LocalTransparencyModifier = if hidden or pigeon.flown then 1 else 0
	end
end

local function flyOff(pigeon: Pigeon, awayFrom: Vector3)
	pigeon.flown = true
	local part = pigeon.part
	local away = part.Position - awayFrom
	local flat = Vector3.new(away.X, 0, away.Z)
	local direction = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, 1)
	local target = part.Position + direction * FLY_AWAY + Vector3.new(0, FLY_RISE, 0)
	local tween = TweenService:Create(
		part,
		TweenInfo.new(FLY_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ CFrame = CFrame.lookAt(target, target + direction), Transparency = 1 }
	)
	tween.Completed:Once(function()
		part.LocalTransparencyModifier = 1
	end)
	tween:Play()
end

local function build(spots: { { district: string, x: number, z: number } })
	local root = Instance.new("Folder")
	root.Name = "AmbientPigeons"
	local perDistrict: { [string]: number } = {}
	for _, spot in spots do
		local count = (perDistrict[spot.district] or 0) + 1
		perDistrict[spot.district] = count
		if count <= MAX_PER_DISTRICT then
			local part = Instance.new("Part")
			part.Name = "Pigeon"
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Size = PIGEON_SIZE
			part.Color = PIGEON_COLOUR
			part.Material = Enum.Material.SmoothPlastic
			part.CFrame = CFrame.new(spot.x, GROUND_OFFSET, spot.z)
				* CFrame.Angles(0, (spot.x * 7 + spot.z * 13) % 6.283, 0)
			part.Parent = root
			table.insert(pigeons, { part = part, flown = false })
		end
	end
	root.Parent = Workspace
	folder = root
end

function PigeonController.start()
	if started then
		return
	end
	local ambient = Worlds.active.ambient
	local spots = if ambient ~= nil then ambient.pigeons else nil
	if spots == nil then
		return
	end
	started = true
	build(spots)
	applyVisibility()
	Players.LocalPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(applyVisibility)

	local ball: BasePart? = nil
	local sinceCheck = 0
	RunService.Heartbeat:Connect(function(dt)
		sinceCheck += dt
		if sinceCheck < CHECK_INTERVAL then
			return
		end
		sinceCheck = 0
		if reduceMotion() then
			return
		end
		if ball == nil or ball.Parent == nil then
			local balls = Workspace:FindFirstChild("Balls")
			local found = if balls ~= nil
				then balls:FindFirstChild(`Ball_{Players.LocalPlayer.UserId}`)
				else nil
			ball = if found ~= nil and found:IsA("BasePart") then found else nil
		end
		local current = ball
		if current == nil then
			return
		end
		local at = current.Position
		for _, pigeon in pigeons do
			if not pigeon.flown and (pigeon.part.Position - at).Magnitude < SCARE_DISTANCE then
				flyOff(pigeon, at)
			end
		end
	end)
end

-- For the Studio specs: how many pigeons stand and how many have flown.
function PigeonController.counts(): (number, number)
	local flown = 0
	for _, pigeon in pigeons do
		if pigeon.flown then
			flown += 1
		end
	end
	return #pigeons, flown
end

function PigeonController.folder(): Folder?
	return folder
end

return PigeonController
