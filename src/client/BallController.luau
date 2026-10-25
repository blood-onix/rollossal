--!strict
-- Drives the local ball: roll torque and force from the move vector, grounded hop, contact scan that
-- sends cube IDs to the server, local collision toggling, and the Reset button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Absorb = require(Shared.Rules.Absorb)
local Movement = require(Shared.Rules.Movement)
local JumpButton = require(script.Parent.JumpButton)
local TouchStick = require(script.Parent.TouchStick)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AbsorbRemote = Remotes:WaitForChild("Absorb") :: RemoteEvent
local BumpRemote = Remotes:WaitForChild("Bump") :: RemoteEvent
local RespawnRemote = Remotes:WaitForChild("RespawnBall") :: RemoteEvent

local UP = Vector3.new(0, 1, 0)
local PENDING_SECONDS = 0.5
local COLLIDE_INTERVAL = 0.1

local BallController = {}

local pendingUntil: { [string]: number } = {}
local sendTimes: { number } = {}
local collideTimer = 0

local function readDiameter(ball: BasePart): number
	local diameter = ball:GetAttribute("Diameter")
	if typeof(diameter) ~= "number" then
		return Config.startDiameter
	end
	return diameter
end

local function flatten(vector: Vector3): Vector3
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return if flat.Magnitude > 0 then flat.Unit else Vector3.zero
end

local function worldDirection(move: Vector3): Vector3
	local camera = Workspace.CurrentCamera
	local look = flatten(camera.CFrame.LookVector)
	local right = flatten(camera.CFrame.RightVector)
	local direction = right * move.X - look * move.Z
	if direction.Magnitude < 1e-3 then
		return Vector3.zero
	end
	return direction.Unit
end

-- Returns a reader for the move vector in the legacy GetMoveVector convention (forward is -Z). Newer
-- Studio builds ship the PlayerModule under StarterPlayer with an Input Action System MoveAction
-- (forward is +Y) and no GetControls; older builds copy the legacy PlayerModule into PlayerScripts.
local function moveReader(player: Player): () -> Vector3
	local modern = StarterPlayer:FindFirstChild("PlayerModule")
	local contexts = modern and modern:FindFirstChild("InputContexts")
	local character = contexts and contexts:FindFirstChild("CharacterContext")
	local action = character and character:FindFirstChild("MoveAction")
	if action and action:IsA("InputAction") then
		return function(): Vector3
			local state = action:GetState()
			if typeof(state) ~= "Vector2" then
				return Vector3.zero
			end
			return Vector3.new(state.X, 0, -state.Y)
		end
	end
	local playerModuleScript =
		player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript
	local controls = (require(playerModuleScript) :: any):GetControls()
	return function(): Vector3
		return controls:GetMoveVector()
	end
end

local function budgetAllows(now: number): boolean
	local kept = {}
	for _, time in sendTimes do
		if now - time < 1 then
			table.insert(kept, time)
		end
	end
	sendTimes = kept
	return #sendTimes < Config.clientSendBudget
end

function BallController.start()
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`) :: BasePart
	local room = Workspace:WaitForChild("GreyBoxRoom") :: Folder
	local cubes = room:WaitForChild("Cubes") :: Folder
	local spin = ball:WaitForChild("AngularVelocity") :: AngularVelocity
	local readMove = moveReader(player)
	local readTouch = TouchStick.create()

	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = { room }

	local function isGrounded(): boolean
		local radius = ball.Size.X / 2
		local probe = Vector3.new(0, -(radius + Config.groundProbeExtra), 0)
		return Workspace:Raycast(ball.Position, probe, groundParams) ~= nil
	end

	local function jump()
		if isGrounded() then
			ball:ApplyImpulse(Vector3.yAxis * ball.AssemblyMass * Config.jumpImpulse)
		end
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.Space then
			jump()
		end
	end)
	local jumpTapped = JumpButton.create()
	if jumpTapped then
		jumpTapped.Event:Connect(jump)
	end

	task.spawn(function()
		local bindable = Instance.new("BindableEvent")
		bindable.Event:Connect(function()
			RespawnRemote:FireServer()
		end)
		for _ = 1, 20 do
			if pcall(function()
				StarterGui:SetCore("ResetButtonCallback", bindable)
			end) then
				return
			end
			task.wait(1)
		end
	end)

	local function contactScan(now: number, radius: number, diameter: number)
		for _, cube in cubes:GetChildren() do
			local part = cube :: BasePart
			local size = part:GetAttribute("Size")
			if part:GetAttribute("Taken") == true or typeof(size) ~= "number" then
				continue
			end
			if
				(ball.Position - part.Position).Magnitude
				> radius + size / 2 + Config.clientContactMargin
			then
				continue
			end
			local pending = pendingUntil[part.Name]
			if pending and now < pending then
				continue
			end
			if not budgetAllows(now) then
				return
			end
			pendingUntil[part.Name] = now + PENDING_SECONDS
			table.insert(sendTimes, now)
			if Absorb.canAbsorb(diameter, size, Config.absorbRatio) then
				AbsorbRemote:FireServer(part.Name)
			else
				BumpRemote:FireServer(part.Name)
			end
		end
	end

	local function updateCollisions(diameter: number)
		for _, cube in cubes:GetChildren() do
			local part = cube :: BasePart
			local size = part:GetAttribute("Size")
			if typeof(size) ~= "number" then
				continue
			end
			local taken = part:GetAttribute("Taken") == true
			part.CanCollide = not (taken or Absorb.canAbsorb(diameter, size, Config.absorbRatio))
		end
	end

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		local diameter = readDiameter(ball)
		local radius = ball.Size.X / 2
		local mass = ball.AssemblyMass
		local speed = Movement.targetSpeed(
			diameter,
			Config.baseSpeed,
			Config.startDiameter,
			Config.speedExponent,
			Config.speedCap
		)
		local move = readMove()
		if readTouch and move.Magnitude < 1e-3 then
			move = readTouch()
		end
		local direction = worldDirection(move)

		spin.MaxTorque = Config.rollTorqueGain * mass * radius * radius
		if direction.Magnitude > 0 then
			spin.AngularVelocity = UP:Cross(direction) * (speed / radius)
			ball:ApplyImpulse(direction * mass * Config.rollForceGain * dt)
		else
			spin.AngularVelocity = Vector3.zero
		end

		contactScan(now, radius, diameter)

		collideTimer += dt
		if collideTimer >= COLLIDE_INTERVAL then
			collideTimer = 0
			updateCollisions(diameter)
		end
	end)
end

return BallController
