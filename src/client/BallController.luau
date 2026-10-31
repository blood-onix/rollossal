--!strict
-- Drives the local ball: roll torque and force from the move vector, grounded hop, contact scan that
-- sends object IDs to the server, local collision toggling, and the Reset button.

local CollectionService = game:GetService("CollectionService")
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
local Boosters = require(Shared.Rules.Boosters)
local Jump = require(Shared.Rules.Jump)
local JumpTuning = require(Shared.JumpTuning)
local Movement = require(Shared.Rules.Movement)
local Traps = require(Shared.Rules.Traps)
local Feedback = require(script.Parent.Feedback)
local JumpButton = require(script.Parent.JumpButton)
local RunClient = require(script.Parent.RunClient)
local TouchStick = require(script.Parent.TouchStick)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AbsorbRemote = Remotes:WaitForChild("Absorb") :: RemoteEvent
local BumpRemote = Remotes:WaitForChild("Bump") :: RemoteEvent
local RespawnRemote = Remotes:WaitForChild("RespawnBall") :: RemoteEvent
local ClaimRemote = Remotes:WaitForChild("ClaimBooster") :: RemoteEvent

local OBJECT_TAG = "WorldObject"
local BOOSTER_TAG = "BoosterSpot"
local SURFACE_TAG = "TrapSurface"
-- A surface patch counts only while the ball is this close to it vertically (studs).
local SURFACE_REACH = 4
local CLAIM_PENDING_SECONDS = 1.0
local UP = Vector3.new(0, 1, 0)
local PENDING_SECONDS = 0.5
local COLLIDE_INTERVAL = 0.1

local BallController = {}

local pendingUntil: { [string]: number } = {}
local sendTimes: { number } = {}
local collideTimer = 0
local surfaceNow = { slick = false, slow = false }

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

-- No run state means the 001 behaviour: everything is allowed.
local function mayRoll(): boolean
	local state = RunClient.state()
	return state == nil or state == "Active" or state == "Hub"
end

local function mayAbsorb(): boolean
	local state = RunClient.state()
	return state == nil or state == "Active"
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

-- Which surface effects are on the local ball now, for the HUD chips.
function BallController.surfaces(): { [string]: boolean }
	return surfaceNow
end

local function trackTagged(tag: string, set: { [BasePart]: boolean })
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
		if instance:IsA("BasePart") then
			set[instance] = true
		end
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
		if instance:IsA("BasePart") then
			set[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("BasePart") then
			set[instance] = true
		end
	end
end

-- "seq;vx;vy;vz" from the server (R-07), or nil when the attribute is empty or malformed.
local function parseLaunch(value: unknown): (number?, Vector3?)
	if typeof(value) ~= "string" then
		return nil, nil
	end
	local seq, vx, vy, vz = string.match(value, "^(%d+);(%-?[%d%.]+);(%-?[%d%.]+);(%-?[%d%.]+)$")
	if seq == nil then
		return nil, nil
	end
	return tonumber(seq) :: number,
		Vector3.new(tonumber(vx) :: number, tonumber(vy) :: number, tonumber(vz) :: number)
end

function BallController.start()
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`) :: BasePart
	local world = Workspace:WaitForChild("World") :: Folder
	-- Pooled parts come and go with streaming; the tag signals keep this set to what is loaded right now.
	local objectParts: { [BasePart]: boolean } = {}
	local function trackObject(instance: Instance)
		if instance:IsA("BasePart") then
			objectParts[instance] = true
		end
	end
	CollectionService:GetInstanceAddedSignal(OBJECT_TAG):Connect(trackObject)
	CollectionService:GetInstanceRemovedSignal(OBJECT_TAG):Connect(function(instance: Instance)
		if instance:IsA("BasePart") then
			objectParts[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged(OBJECT_TAG) do
		trackObject(instance)
	end
	local boosterParts: { [BasePart]: boolean } = {}
	local surfaceParts: { [BasePart]: boolean } = {}
	trackTagged(BOOSTER_TAG, boosterParts)
	trackTagged(SURFACE_TAG, surfaceParts)
	local claimPendingUntil: { [string]: number } = {}
	local slickUntil = -math.huge
	local slowUntil = -math.huge
	local spin = ball:WaitForChild("AngularVelocity") :: AngularVelocity
	local readMove = moveReader(player)
	local readTouch = TouchStick.create()

	local groundParams = RaycastParams.new()
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = { world }

	local function isGrounded(): boolean
		local radius = ball.Size.X / 2
		local probe = Vector3.new(0, -(radius + Config.groundProbeExtra), 0)
		return Workspace:Raycast(ball.Position, probe, groundParams) ~= nil
	end

	-- Variable jump (006, research R-01): the press sets the take-off speed for a tap apex of 0.6 x diameter;
	-- holding lowers gravity to holdGravity for at most jumpHoldMaxSeconds, so the apex reaches 0.85 x diameter.
	local lastJumpAt = -math.huge
	local holdUntil = -math.huge
	local holdExtraAccel = 0
	-- The physics step applies gravity before it moves the ball, so a take-off speed set between steps loses about
	-- v0 * dt / 2 of its apex (0.2 studs at 60 fps, enough to miss the 1.5-stud kerb). Adding g * dt / 2 gives the
	-- apex the rule promises; dt is the last Heartbeat step.
	local lastDt = 1 / 60

	local function jumpDiameter(): number
		return math.max(readDiameter(ball), ball.Size.X)
	end

	local function jump()
		local now = os.clock()
		local velocity = ball.AssemblyLinearVelocity
		if
			not mayRoll()
			or not Jump.canTakeOff(isGrounded(), now, lastJumpAt, velocity.Y, Config.jumpCooldown)
		then
			return
		end
		lastJumpAt = now
		if not Config.Flags.ScaledJump then
			ball:ApplyImpulse(Vector3.yAxis * ball.AssemblyMass * Config.jumpImpulse)
			return
		end
		local diameter = jumpDiameter()
		local gravity = Workspace.Gravity
		ball.AssemblyLinearVelocity = Vector3.new(
			velocity.X,
			Jump.takeoffSpeed(diameter, gravity, JumpTuning) + gravity * lastDt / 2,
			velocity.Z
		)
		holdExtraAccel = gravity
			- Jump.holdGravity(diameter, gravity, Config.jumpHoldMaxSeconds, JumpTuning)
		holdUntil = now + Config.jumpHoldMaxSeconds
	end

	-- Releasing the button ends the stretch at once; there is no velocity to bleed off.
	local function releaseJump()
		holdUntil = -math.huge
	end

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.Space then
			jump()
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Space then
			releaseJump()
		end
	end)
	local jumpEvents = JumpButton.create()
	if jumpEvents then
		jumpEvents.Pressed.Event:Connect(jump)
		jumpEvents.Released.Event:Connect(releaseJump)
	end

	-- The server's Launch fact (spring, bumper, sweeper): applied once per new seq, to the ball this client owns.
	local launchSeq = 0
	local startSeq = parseLaunch(ball:GetAttribute("Launch"))
	if startSeq then
		launchSeq = startSeq
	end
	ball:GetAttributeChangedSignal("Launch"):Connect(function()
		local seq, velocity = parseLaunch(ball:GetAttribute("Launch"))
		if seq == nil or velocity == nil or seq <= launchSeq then
			return
		end
		launchSeq = seq
		local current = ball.AssemblyLinearVelocity
		-- A bounce (vy 0) keeps the ball's own vertical speed; a spring sets it.
		ball.AssemblyLinearVelocity =
			Vector3.new(velocity.X, if velocity.Y ~= 0 then velocity.Y else current.Y, velocity.Z)
		releaseJump()
	end)

	local wasAirborne = false
	local lastVerticalSpeed = 0

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
		for part in objectParts do
			local size = part:GetAttribute("Size")
			-- CanTouch is false for a Taken part and for one WorldCuller hides, so a culled part never sends a remote.
			if
				part:GetAttribute("Taken") == true
				or not part.CanTouch
				or typeof(size) ~= "number"
			then
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
		for part in objectParts do
			local size = part:GetAttribute("Size")
			if typeof(size) ~= "number" then
				continue
			end
			local taken = part:GetAttribute("Taken") == true
			part.CanCollide = not (taken or Absorb.canAbsorb(diameter, size, Config.absorbRatio))
		end
	end

	RunService.Heartbeat:Connect(function(dt: number)
		lastDt = math.min(dt, 1 / 30)
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
		-- Dash (server fact BoostDash = the server time it ends): a higher target speed, under the boosted cap.
		local serverNow = Workspace:GetServerTimeNow()
		local dashEnds = ball:GetAttribute("BoostDash")
		if typeof(dashEnds) == "number" and dashEnds > serverNow then
			speed = Boosters.dashTarget(speed, Config.dashSpeedMultiplier, Config.boostSpeedCap)
		end

		-- Slick and Slow patches (R-10) are read here: they only ever dull steering or lower the target speed.
		local slickInside, slowInside = false, false
		local ballPosition = ball.Position
		for part in surfaceParts do
			local owner = part:GetAttribute("OwnerUserId")
			local expires = part:GetAttribute("ExpiresAt")
			local halfX = part:GetAttribute("HalfX")
			local halfZ = part:GetAttribute("HalfZ")
			local at = part.Position
			if
				owner == player.UserId
				or (typeof(expires) == "number" and expires <= serverNow)
				or typeof(halfX) ~= "number"
				or typeof(halfZ) ~= "number"
				or math.abs(ballPosition.Y - radius - at.Y) > SURFACE_REACH
			then
				continue
			end
			local yaw = part:GetAttribute("Yaw")
			if
				Traps.insideRect(
					ballPosition.X,
					ballPosition.Z,
					at.X,
					at.Z,
					halfX,
					halfZ,
					if typeof(yaw) == "number" then yaw else 0
				)
			then
				if part:GetAttribute("Kind") == "slow" then
					slowInside = true
				else
					slickInside = true
				end
			end
		end
		local slickActive, slickEnd =
			Traps.surfaceActive(now, slickInside, slickUntil, Config.slickLingerSeconds)
		local slowActive, slowEnd =
			Traps.surfaceActive(now, slowInside, slowUntil, Config.slowLingerSeconds)
		slickUntil, slowUntil = slickEnd, slowEnd
		surfaceNow.slick = slickActive
		surfaceNow.slow = slowActive
		local turn = Traps.turnMultiplier(slickActive, Config.slickTurnMultiplier)
		local pace = Traps.speedMultiplier(slowActive, Config.slowSpeedMultiplier)
		speed *= pace

		local move = Vector3.zero
		if mayRoll() then
			move = readMove()
			if readTouch and move.Magnitude < 1e-3 then
				move = readTouch()
			end
		end
		local direction = worldDirection(move)

		spin.MaxTorque = Config.rollTorqueGain * mass * radius * radius * turn
		if direction.Magnitude > 0 then
			spin.AngularVelocity = UP:Cross(direction) * (speed / radius)
			ball:ApplyImpulse(direction * mass * Config.rollForceGain * dt * turn * pace)
		else
			spin.AngularVelocity = Vector3.zero
		end

		-- Hold extension: extra upward acceleration (g - q) while the button is held and the ball still rises.
		local velocity = ball.AssemblyLinearVelocity
		if Jump.holdActive(now, holdUntil, velocity.Y) then
			ball:ApplyImpulse(Vector3.yAxis * mass * holdExtraAccel * dt)
		else
			holdUntil = -math.huge
		end

		-- Landing feedback: the step that touches ground after a fall of at least landingMinSpeed.
		local grounded = isGrounded()
		if grounded and wasAirborne and -lastVerticalSpeed >= Config.landingMinSpeed then
			Feedback.landed(ball, -lastVerticalSpeed)
		end
		wasAirborne = not grounded
		lastVerticalSpeed = velocity.Y

		if mayAbsorb() then
			contactScan(now, radius, diameter)
			-- Boosters are claimed by marker id; the server checks range, availability and the rate.
			for part in boosterParts do
				local markerId = part:GetAttribute("MarkerId")
				if typeof(markerId) ~= "string" or part:GetAttribute("Taken") == true then
					continue
				end
				local partPosition = part.Position
				if
					not Boosters.inClaimReach(
						{ x = ballPosition.X, y = ballPosition.Y, z = ballPosition.Z },
						diameter,
						{ x = partPosition.X, y = partPosition.Y, z = partPosition.Z },
						Config.boosterRadius,
						Config.clientContactMargin
					)
				then
					continue
				end
				if (claimPendingUntil[markerId] or 0) > now or not budgetAllows(now) then
					continue
				end
				claimPendingUntil[markerId] = now + CLAIM_PENDING_SECONDS
				table.insert(sendTimes, now)
				ClaimRemote:FireServer(markerId)
			end
		end

		collideTimer += dt
		if collideTimer >= COLLIDE_INTERVAL then
			collideTimer = 0
			updateCollisions(diameter)
		end
	end)
end

return BallController
