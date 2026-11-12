--!strict
-- The owner's side of the map's toys: carries the ball along a rail or through a pipe when the server publishes a
-- Ride fact, and plays the sound and camera kick of each toy (ToyFx). The server decided both.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Assets = require(Shared.Assets)
local Toys = require(Shared.Rules.Toys)
local Worlds = require(Shared.Worlds)
local CameraController = require(script.Parent.CameraController)

local SNAP_SECONDS = 0.12
local PIPE_TOP = 5

local BASE_FOV = 70
local FX: { [string]: { sound: string, speed: number, fov: number, shake: number } } = {
	boost = { sound = Assets.sounds.tierUnlock, speed = 1.5, fov = 18, shake = 0.25 },
	bounce = { sound = Assets.sounds.bell, speed = 2.4, fov = 6, shake = 0 },
	spring = { sound = Assets.sounds.bell, speed = 1.8, fov = 12, shake = 0.3 },
	catapult = { sound = Assets.sounds.bell, speed = 0.8, fov = 26, shake = 0.8 },
	rail = { sound = Assets.sounds.tierUnlock, speed = 0.8, fov = 10, shake = 0 },
	pipe = { sound = Assets.sounds.bump, speed = 0.6, fov = 14, shake = 0.2 },
	vacuum = { sound = Assets.sounds.tierUnlock, speed = 0.7, fov = 24, shake = 1 },
}

local ToyRides = {}

local function reduced(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceMotion") == true
end

-- A flat ring that races outwards from the ball when it jumps a size tier.
local function shockwave(ball: BasePart)
	local diameter = ball.Size.X
	local reach = 2
		* Toys.vacuumRadius(
			diameter,
			Config.vacuumRadiusFloor,
			Config.vacuumRadiusFactor,
			Config.vacuumRadiusCeiling
		)
	local ring = Instance.new("Part")
	ring.Name = "VacuumRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 225, 90)
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, diameter, diameter)
	ring.CFrame = CFrame.new(ball.Position - Vector3.new(0, diameter / 2 - 0.2, 0))
		* CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = Workspace.CurrentCamera
	local tween = TweenService:Create(
		ring,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.2, reach, reach), Transparency = 1 }
	)
	tween.Completed:Connect(function()
		ring:Destroy()
	end)
	tween:Play()
end

local function playFx(kind: string, ball: BasePart)
	local fx = FX[kind]
	if fx == nil then
		return
	end
	if kind == "vacuum" and not reduced() then
		shockwave(ball)
	end
	local sound = Instance.new("Sound")
	sound.SoundId = fx.sound
	sound.PlaybackSpeed = fx.speed
	sound.Volume = 0.8
	sound.Parent = game:GetService("SoundService")
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
	if reduced() then
		return
	end
	if fx.shake > 0 then
		CameraController.shake(0.3, fx.shake)
	end
	local camera = Workspace.CurrentCamera
	camera.FieldOfView = BASE_FOV + fx.fov
	TweenService:Create(
		camera,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = BASE_FOV }
	):Play()
end

-- The polyline the ball follows from where it caught on. A pipe ends with a climb out of its mouth.
local function ridePath(rail: any, along: number, direction: number, radius: number): { { number } }
	local points: { { number } } = {}
	for _, point in rail.points :: { { number } } do
		table.insert(points, { point[1], point[2], point[3] })
	end
	if direction < 0 then
		local reversed = {}
		for index = #points, 1, -1 do
			table.insert(reversed, points[index])
		end
		points = reversed
		along = Toys.pathLength(points) - along
	end
	if rail.kind == "pipe" then
		local last = points[#points]
		table.insert(points, { last[1], PIPE_TOP + radius, last[3] })
	end
	local x, y, z = Toys.pointAt(points, along)
	local trimmed: { { number } } = { { x, y, z } }
	local walked = 0
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		walked += math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2)
		if walked > along then
			table.insert(trimmed, b)
		end
	end
	return trimmed
end

function ToyRides.start()
	if not Config.Flags.Toys then
		return
	end
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`) :: BasePart

	local railsById: { [string]: any } = {}
	for _, item in ((Worlds.active :: any).placeholders or {}) :: { any } do
		if item.kind == "rail" or item.kind == "pipe" then
			railsById[item.id] = item
		end
	end

	local connection: RBXScriptConnection? = nil
	local function finish()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		ball.CanCollide = true
	end

	local function begin(rail: any, along: number, direction: number)
		finish()
		local radius = ball.Size.X / 2
		local pipe = rail.kind == "pipe"
		local points = ridePath(rail, along, direction, radius)
		local length = Toys.pathLength(points)
		local speed = rail.speed
			* (if pipe then Config.toyPipeSpeedScale else Config.toyRailSpeedScale)
		local lift = if pipe then 0 else radius
		local from = ball.Position
		local walked, elapsed = 0, 0
		ball.CanCollide = false
		connection = RunService.Heartbeat:Connect(function(dt: number)
			elapsed += dt
			walked += speed * dt
			local x, y, z, tx, ty, tz = Toys.pointAt(points, walked)
			local target = Vector3.new(x, y + lift, z)
			local tangent = Vector3.new(tx, ty, tz)
			if walked >= length then
				finish()
				ball.CFrame = CFrame.new(target)
				if pipe then
					local first = points[1]
					local flat = Vector3.new(x - first[1], 0, z - first[3])
					local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis
					ball.AssemblyLinearVelocity = forward * Config.toyPipeExitForward
						+ Vector3.yAxis * Config.toyPipeExitUp
				else
					ball.AssemblyLinearVelocity = tangent * speed
						+ Vector3.yAxis * Config.toyRailExitUp
				end
				return
			end
			local blend = math.min(elapsed / SNAP_SECONDS, 1)
			ball.CFrame = CFrame.new(from:Lerp(target, blend))
			ball.AssemblyLinearVelocity = tangent * speed
		end)
	end

	local lastRide = 0
	ball:GetAttributeChangedSignal("Ride"):Connect(function()
		local value = ball:GetAttribute("Ride")
		if value == "" or value == nil then
			finish()
			return
		end
		local seq, id, along, direction =
			string.match(value :: string, "^(%d+);([^;]+);(%-?[%d%.]+);(%-?%d+)$")
		if seq == nil or tonumber(seq) :: number <= lastRide then
			return
		end
		lastRide = tonumber(seq) :: number
		local rail = railsById[id :: string]
		if rail then
			begin(rail, tonumber(along) :: number, tonumber(direction) :: number)
		end
	end)

	local lastFx = 0
	ball:GetAttributeChangedSignal("ToyFx"):Connect(function()
		local seq, kind = string.match(tostring(ball:GetAttribute("ToyFx")), "^(%d+);(%a+)$")
		if seq == nil or tonumber(seq) :: number <= lastFx then
			return
		end
		lastFx = tonumber(seq) :: number
		playFx(kind :: string, ball)
	end)
end

return ToyRides
