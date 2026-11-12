--!strict
-- Asteroid shower visuals (fun slice): for each rock the server announces, a warning ring on the ground and a rock
-- that falls onto it, then an impact burst. A hit on the local ball shakes the camera. The shower's end time is
-- set as a Workspace attribute for the banner. Client-only: the server decides every hit.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local RING_COLOR = Color3.fromRGB(255, 60, 40)
local RING_LIFT = 0.15
local RING_THICKNESS = 0.2
local RING_TRANSPARENCY_START = 0.85
local RING_TRANSPARENCY_END = 0.25
local ROCK_COLOR = Color3.fromRGB(90, 70, 60)
local ROCK_FALL_SIDE = 0.3
local IMPACT_COLOR = Color3.fromRGB(255, 140, 40)
local IMPACT_SCALE = 3
local IMPACT_SECONDS = 0.35
local IMPACT_TRANSPARENCY_START = 0.3
local IMPACT_TRANSPARENCY_END = 1
-- Below this much warning left the rock skips its fall and lands at once.
local MIN_FALL_SECONDS = 0.05
local SHAKE_BIND_NAME = "MeteorShake"

local MeteorClient = {}

local random = Random.new()
local fxFolder: Folder = Instance.new("Folder")

local function makePart(
	shape: Enum.PartType,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number
): Part
	local part = Instance.new("Part")
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = fxFolder
	return part
end

local function spawnImpact(x: number, y: number, z: number, radius: number)
	local burst = makePart(
		Enum.PartType.Ball,
		Vector3.new(radius, radius, radius),
		CFrame.new(x, y, z),
		IMPACT_COLOR,
		Enum.Material.Neon,
		IMPACT_TRANSPARENCY_START
	)
	TweenService
		:Create(
			burst,
			TweenInfo.new(IMPACT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = Vector3.new(
					radius * IMPACT_SCALE,
					radius * IMPACT_SCALE,
					radius * IMPACT_SCALE
				),
				Transparency = IMPACT_TRANSPARENCY_END,
			}
		)
		:Play()
	Debris:AddItem(burst, IMPACT_SECONDS)
end

-- The rock has arrived: remove the warning ring and the rock, then show the impact.
local function land(ring: Part, rock: Part, x: number, y: number, z: number, radius: number)
	ring:Destroy()
	rock:Destroy()
	spawnImpact(x, y, z, radius)
end

local function onRock(x: number, y: number, z: number, radius: number, impactAt: number)
	local remaining = impactAt - Workspace:GetServerTimeNow()
	local ring = makePart(
		Enum.PartType.Cylinder,
		Vector3.new(RING_THICKNESS, radius * 2, radius * 2),
		CFrame.new(x, y + RING_LIFT, z) * CFrame.Angles(0, 0, math.pi / 2),
		RING_COLOR,
		Enum.Material.Neon,
		RING_TRANSPARENCY_START
	)
	local rock = makePart(
		Enum.PartType.Ball,
		Vector3.new(radius, radius, radius),
		CFrame.new(x + Config.meteorFallHeight * ROCK_FALL_SIDE, y + Config.meteorFallHeight, z),
		ROCK_COLOR,
		Enum.Material.Slate,
		0
	)
	local fire = Instance.new("Fire")
	fire.Size = radius
	fire.Heat = 0
	fire.Parent = rock

	if remaining <= MIN_FALL_SECONDS then
		land(ring, rock, x, y, z, radius)
		return
	end

	local fallInfo = TweenInfo.new(remaining, Enum.EasingStyle.Linear)
	TweenService:Create(ring, fallInfo, { Transparency = RING_TRANSPARENCY_END }):Play()
	TweenService:Create(rock, fallInfo, { CFrame = CFrame.new(x, y, z) }):Play()
	-- Safety net in case a tween is interrupted: the parts never outlive their fall plus the impact.
	Debris:AddItem(ring, remaining + IMPACT_SECONDS)
	Debris:AddItem(rock, remaining + IMPACT_SECONDS)
	task.delay(remaining, function()
		land(ring, rock, x, y, z, radius)
	end)
end

local function onHit()
	if Players.LocalPlayer:GetAttribute("ReduceMotion") == true then
		return
	end
	-- Unbind first so a second hit during a shake restarts it instead of erroring on a duplicate bind.
	RunService:UnbindFromRenderStep(SHAKE_BIND_NAME)
	local started = os.clock()
	local magnitude = Config.knockOffShakeMagnitude * 2
	RunService:BindToRenderStep(SHAKE_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		if os.clock() - started >= Config.knockOffShakeDuration then
			RunService:UnbindFromRenderStep(SHAKE_BIND_NAME)
			return
		end
		local camera = Workspace.CurrentCamera
		if camera then
			local offset = Vector3.new(
				random:NextNumber(-magnitude, magnitude),
				random:NextNumber(-magnitude, magnitude),
				random:NextNumber(-magnitude, magnitude)
			)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
		end
	end)
end

local function onEvent(
	kind: unknown,
	first: unknown,
	second: unknown,
	third: unknown,
	fourth: unknown,
	fifth: unknown
)
	if kind == "shower" then
		if typeof(first) == "number" then
			Workspace:SetAttribute("ShowerEndsAt", first)
		end
	elseif kind == "rock" then
		if
			typeof(first) == "number"
			and typeof(second) == "number"
			and typeof(third) == "number"
			and typeof(fourth) == "number"
			and typeof(fifth) == "number"
		then
			onRock(first, second, third, fourth, fifth)
		end
	end
end

function MeteorClient.start()
	fxFolder.Name = "MeteorFx"
	fxFolder.Parent = Workspace

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local meteorEvent = remotes:WaitForChild("MeteorEvent") :: RemoteEvent
	local meteorHit = remotes:WaitForChild("MeteorHit") :: RemoteEvent
	meteorEvent.OnClientEvent:Connect(onEvent)
	meteorHit.OnClientEvent:Connect(onHit)
end

return MeteorClient
