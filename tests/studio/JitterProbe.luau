--!strict
-- Quickstart §6 jitter probe for the current Config.stuckVisualMode. Config is frozen, so set the mode
-- in Config.luau first, then run in Play mode through the Studio MCP server:
--   return require(game.ServerStorage.Tests.JitterProbe)()
-- Visuals only exist on a client, so their deltas are measured while the client scripts are running.
-- A require from the MCP context gets its own BallService instance that the live Heartbeat loop never
-- steps, so the probe calls BallService.step itself to run the real growth easing on its own session.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BallService = require(ServerScriptService.BallService)

local VISUAL_COUNT = 30
local GROWTH_STEPS = 20
local GROWTH_INCREMENT = 0.05
local STEP_FRAMES = 10
local SETTLE_FRAMES = 30
local ROLL_SPEED = 15
local PROBE_USER_ID = 990001
-- Clear floor away from the spawn ring, and a cube-free lane along +X that is long enough for the
-- rolling phase (30 spin-up plus 230 measured frames at 15 studs/s is about 65 studs).
local REST_POSITION = Vector3.new(-22, 0, 20)
local ROLL_START = Vector3.new(-32, 0, 4.5)

type Stats = {
	maxBallDeltaY: number,
	maxVisualDeltaY: number,
	maxBallSpeed: number,
	maxSpeedError: number,
}

local function attachVisuals(session: BallService.Session)
	local room = Workspace:WaitForChild("GreyBoxRoom") :: Folder
	local cubes = (room:WaitForChild("Cubes") :: Folder):GetChildren()
	for index = 1, VISUAL_COUNT do
		local cube = cubes[index] :: BasePart
		local angle = index / VISUAL_COUNT * math.pi * 2
		table.insert(session.stuckStack, {
			key = `{cube.Name}#probe{index}`,
			id = cube.Name,
			size = cube:GetAttribute("Size") :: number,
			tier = cube:GetAttribute("Tier") :: number,
			dir = { x = math.cos(angle), y = 0.3, z = math.sin(angle) },
		})
	end
	BallService.publishStuck(session)
end

local function visualParts(): { BasePart }
	local parts: { BasePart } = {}
	local folder = Workspace:FindFirstChild("StuckVisuals")
	if folder then
		for _, child in folder:GetChildren() do
			table.insert(parts, child :: BasePart)
		end
	end
	return parts
end

local function measure(session: BallService.Session, frames: number, targetSpeed: number?): Stats
	local ball = session.part
	local stats: Stats =
		{ maxBallDeltaY = 0, maxVisualDeltaY = 0, maxBallSpeed = 0, maxSpeedError = 0 }
	local lastBallY = ball.Position.Y
	local lastVisualY: { [BasePart]: number } = {}
	local grown = 0
	for frame = 1, frames do
		if grown < GROWTH_STEPS and frame % STEP_FRAMES == 0 then
			grown += 1
			BallService.setDiameter(session, session.authoritativeDiameter + GROWTH_INCREMENT)
		end
		if targetSpeed then
			ball.AssemblyLinearVelocity = Vector3.new(targetSpeed, ball.AssemblyLinearVelocity.Y, 0)
		end
		local dt = RunService.Heartbeat:Wait()
		BallService.step(os.clock(), dt)

		local velocity = ball.AssemblyLinearVelocity
		stats.maxBallDeltaY = math.max(stats.maxBallDeltaY, math.abs(ball.Position.Y - lastBallY))
		stats.maxBallSpeed = math.max(stats.maxBallSpeed, velocity.Magnitude)
		lastBallY = ball.Position.Y
		if targetSpeed then
			local horizontal = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			stats.maxSpeedError = math.max(stats.maxSpeedError, math.abs(horizontal - targetSpeed))
		end
		for _, part in visualParts() do
			local previous = lastVisualY[part] or part.Position.Y
			stats.maxVisualDeltaY =
				math.max(stats.maxVisualDeltaY, math.abs(part.Position.Y - previous))
			lastVisualY[part] = part.Position.Y
		end
	end
	return stats
end

return function(): boolean
	local mode = Config.stuckVisualMode
	local frames = GROWTH_STEPS * STEP_FRAMES + SETTLE_FRAMES
	local session = BallService.newSession(PROBE_USER_ID)
	local passed = false

	-- With a speed, the settle frames also spin the ball up, so the friction transient of a standing
	-- start is not counted as growth jitter.
	local function settleAt(position: Vector3, speed: number?)
		local ball = session.part
		ball.AssemblyLinearVelocity = Vector3.zero
		ball.AssemblyAngularVelocity = Vector3.zero
		ball.Position = position + Vector3.yAxis * (ball.Size.Y / 2)
		session.lastValidPosition = ball.Position
		for _ = 1, SETTLE_FRAMES do
			if speed then
				ball.AssemblyLinearVelocity = Vector3.new(speed, ball.AssemblyLinearVelocity.Y, 0)
			end
			BallService.step(os.clock(), RunService.Heartbeat:Wait())
		end
	end

	local ok, err = pcall(function()
		session.part:SetNetworkOwner(nil)
		attachVisuals(session)
		settleAt(REST_POSITION)
		local resting = measure(session, frames, nil)

		BallService.setDiameter(session, Config.startDiameter)
		settleAt(ROLL_START, ROLL_SPEED)
		local rolling = measure(session, frames, ROLL_SPEED)

		print(`[JitterProbe {mode}] visual parts seen: {#visualParts()}`)
		print(
			`[JitterProbe {mode}] resting: ballΔY={resting.maxBallDeltaY} visualΔY={resting.maxVisualDeltaY} speed={resting.maxBallSpeed}`
		)
		print(
			`[JitterProbe {mode}] rolling: ballΔY={rolling.maxBallDeltaY} visualΔY={rolling.maxVisualDeltaY} speedErr={rolling.maxSpeedError}`
		)
		passed = resting.maxBallDeltaY < 0.05
			and resting.maxBallSpeed < 1
			and rolling.maxSpeedError < 1
		print(`[JitterProbe {mode}] pass: {passed}`)
	end)

	BallService.removeSession(session)
	if not ok then
		error(err)
	end
	return passed
end
