--!strict
-- Ball sessions: one Part per player, network-owned by that player, with server-side growth easing,
-- the Stuck attribute, the per-Heartbeat speed and displacement check, and respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BallGuard = require(Shared.Rules.BallGuard)
local Jump = require(Shared.Rules.Jump)
local JumpTuning = require(Shared.JumpTuning)
local Layout = require(Shared.Rules.Layout)
local Respawn = require(Shared.Rules.Respawn)
local StuckStack = require(Shared.Rules.StuckStack)
local Worlds = require(Shared.Worlds)
local WorldSpawner = require(script.Parent.WorldSpawner)

-- A visual-only record of one pickup. key is unique per pickup (`<id>#<n>`), so the same object can
-- appear twice after it respawns and is eaten again.
export type StuckEntry = {
	key: string,
	id: string,
	size: number,
	tier: number,
	dir: { x: number, y: number, z: number },
}

export type Sample = { t: number, speed: number }

export type Violation = {
	userId: number,
	kind: "Speed" | "Displacement" | "Vertical",
	measured: number,
	limit: number,
	at: number,
}

export type Session = {
	player: Player?,
	ownerUserId: number,
	part: BasePart,
	slot: number,
	authoritativeDiameter: number,
	physicalDiameter: number,
	stuckStack: { StuckEntry },
	absorbWindow: { number },
	bumpWindow: { number },
	lastBumpAt: number,
	lastRespawnAt: number,
	speedSamples: { Sample },
	lastValidPosition: Vector3,
	lastValidVelocity: Vector3,
	violations: number,
	violationLog: { Violation },
	lastWarnAt: number,
	-- Run loop: which floor the ball belongs on, and whether the server holds it still (after the bell).
	zone: "Room" | "Hub",
	frozen: boolean,
	-- True while the ball is held still until the world around its spawn has streamed in.
	streamHold: boolean,
	-- Vertical guard (006, research R-03): the energy y + vy^2/2g taken on the last grounded step.
	airRefEnergy: number,
	-- Boost windows set by BoosterService (R-04): the Dash horizontal ceiling, its decay grace, and the Spring
	-- window with the vertical speed it launched at.
	boostUntil: number,
	boostGraceUntil: number,
	springUntil: number,
	springVy: number,
	-- Shield (a Sticky coat) end time, and the end of the 3 s immunity after a ball-to-ball knock-off.
	shieldUntil: number,
	immuneUntil: number,
	-- Counts the Launch facts published on this ball.
	launchSeq: number,
}

local BallService = {}

local sessions: { [number]: Session } = {}
local random = Random.new()
-- Services that keep per-ball effect state (BoosterService) register here; BallService cannot require them.
local clearHooks: { (Session) -> () } = {}

local function getBallsFolder(): Folder
	local existing = Workspace:FindFirstChild("Balls")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Balls"
	folder.Parent = Workspace
	return folder
end

local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function healthiestSlot(except: Session?): number
	local available: { number } = {}
	for slot = 1, #Worlds.active.spawnPoints do
		available[slot] = WorldSpawner.availableInCluster(slot)
	end
	local inUse: { [number]: boolean } = {}
	for _, session in sessions do
		if session ~= except then
			inUse[session.slot] = true
		end
	end
	return Layout.healthiestSlot(available, inUse)
end

function BallService.publishStuck(session: Session)
	local visible = StuckStack.visibleTail(session.stuckStack, Config.maxVisibleStuck)
	local entries = {}
	for _, entry in visible do
		table.insert(
			entries,
			string.format("%s,%.2f,%.2f,%.2f", entry.key, entry.dir.x, entry.dir.y, entry.dir.z)
		)
	end
	session.part:SetAttribute("Stuck", table.concat(entries, ";"))
end

function BallService.setDiameter(session: Session, newDiameter: number)
	session.authoritativeDiameter = newDiameter
	session.part:SetAttribute("Diameter", newDiameter)
end

function BallService.getSession(player: Player): Session?
	return sessions[player.UserId]
end

function BallService.allSessions(): { [number]: Session }
	return sessions
end

function BallService.getSessionByUserId(userId: number): Session?
	return sessions[userId]
end

-- The objects these entries can still release: those waiting to respawn from the same pickup. An object
-- that has already respawned (or been taken again) stays where it is.
function BallService.releasableObjects(entries: { StuckEntry }): { WorldSpawner.PooledWorldObject }
	local cubes: { WorldSpawner.PooledWorldObject } = {}
	for _, entry in entries do
		local cube = WorldSpawner.getObject(entry.id)
		if cube and WorldSpawner.isHeldBy(cube, entry.key) then
			table.insert(cubes, cube)
		end
	end
	return cubes
end

function BallService.peakSpeed(session: Session, now: number): number
	local peak = 0
	for _, sample in session.speedSamples do
		if now - sample.t <= Config.bumpSpeedWindow and sample.speed > peak then
			peak = sample.speed
		end
	end
	return peak
end

function BallService.newSession(userId: number, player: Player?): Session
	local part = Instance.new("Part")
	part.Name = `Ball_{userId}`
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * Config.startDiameter
	part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.8, 0, 1, 1)
	part:SetAttribute("Diameter", Config.startDiameter)
	part:SetAttribute("Stuck", "")

	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	local spin = Instance.new("AngularVelocity")
	spin.Attachment0 = attachment
	spin.RelativeTo = Enum.ActuatorRelativeTo.World
	spin.AngularVelocity = Vector3.zero
	spin.Parent = part

	local slot = healthiestSlot()
	local spawn = WorldSpawner.getSpawnSlot(slot)
	part.Position = spawn
	part.Parent = getBallsFolder()

	local session: Session = {
		player = player,
		ownerUserId = userId,
		part = part,
		slot = slot,
		authoritativeDiameter = Config.startDiameter,
		physicalDiameter = Config.startDiameter,
		stuckStack = {},
		absorbWindow = {},
		bumpWindow = {},
		lastBumpAt = -math.huge,
		lastRespawnAt = -math.huge,
		speedSamples = {},
		lastValidPosition = spawn,
		lastValidVelocity = Vector3.zero,
		violations = 0,
		violationLog = {},
		lastWarnAt = -math.huge,
		zone = "Room",
		frozen = false,
		streamHold = false,
		airRefEnergy = 0,
		boostUntil = -math.huge,
		boostGraceUntil = -math.huge,
		springUntil = -math.huge,
		springVy = 0,
		shieldUntil = -math.huge,
		immuneUntil = -math.huge,
		launchSeq = 0,
	}
	part:SetAttribute("Launch", "")
	part:SetAttribute("BoostDash", 0)
	part:SetAttribute("BoostMagnet", 0)
	part:SetAttribute("BoostShield", 0)
	part:SetAttribute("BoostTrail", 0)
	if player then
		part:SetNetworkOwner(player)
		-- No character, so streaming needs the ball as its focus or the client never receives it.
		player.ReplicationFocus = part
	end
	sessions[userId] = session
	return session
end

-- Registers a function called whenever a ball's effects are cleared (run end, reset, respawn, leaving).
function BallService.onClear(hook: (Session) -> ())
	table.insert(clearHooks, hook)
end

-- Ends every booster effect and the ball-bump immunity (data-model.md "State summary"): run end, Roll again, hub,
-- reset, fall respawn and leaving all come through here.
function BallService.clearEffects(session: Session)
	session.boostUntil = -math.huge
	session.boostGraceUntil = -math.huge
	session.springUntil = -math.huge
	session.springVy = 0
	session.shieldUntil = -math.huge
	session.immuneUntil = -math.huge
	session.part:SetAttribute("BoostDash", 0)
	session.part:SetAttribute("BoostMagnet", 0)
	session.part:SetAttribute("BoostShield", 0)
	session.part:SetAttribute("BoostTrail", 0)
	for _, hook in clearHooks do
		hook(session)
	end
end

-- The Launch fact (R-07): the owner's client applies each new seq once, because a server write to a
-- client-owned part's velocity is unreliable.
function BallService.publishLaunch(session: Session, velocity: Vector3)
	session.launchSeq += 1
	session.part:SetAttribute(
		"Launch",
		string.format("%d;%.2f;%.2f;%.2f", session.launchSeq, velocity.X, velocity.Y, velocity.Z)
	)
end

function BallService.removeSession(session: Session)
	BallService.clearEffects(session)
	for _, cube in BallService.releasableObjects(session.stuckStack) do
		WorldSpawner.returnToSpawn(cube)
	end
	session.stuckStack = {}
	session.part:Destroy()
	sessions[session.ownerUserId] = nil
end

-- Anchored while the run holds the ball or the world around it is still streaming in; otherwise handed back
-- to its player.
local function applyAnchor(session: Session)
	local part = session.part
	local held = session.frozen or session.streamHold
	part.Anchored = held
	if not held then
		if session.player then
			part:SetNetworkOwner(session.player)
		end
		session.lastValidPosition = part.Position
		session.lastValidVelocity = Vector3.zero
	end
end

-- Holds the ball still until the client has the ground around `position` (streaming), then lets the run
-- release it. The request is protected: a failure or timeout only means the ball is released as it was.
local function holdUntilStreamed(session: Session, position: Vector3)
	local player = session.player
	if player == nil then
		return
	end
	session.streamHold = true
	session.part.Anchored = true
	task.spawn(function()
		pcall(function()
			player:RequestStreamAroundAsync(position, Config.streamRequestTimeout)
		end)
		if session.part.Parent == nil then
			return
		end
		session.streamHold = false
		applyAnchor(session)
	end)
end

local function placeAtSpawn(session: Session)
	BallService.clearEffects(session)
	local spawn = if session.zone == "Hub"
		then WorldSpawner.getHubSpawn()
		else WorldSpawner.getSpawnSlot(session.slot)
	session.part.AssemblyLinearVelocity = Vector3.zero
	session.part.AssemblyAngularVelocity = Vector3.zero
	session.part.Position = spawn
	session.lastValidPosition = spawn
	session.lastValidVelocity = Vector3.zero
	holdUntilStreamed(session, spawn)
end

-- Scatters the cubes the stack can still release around the ball, empties the stack, resets the
-- diameter and returns the ball to its spawn slot. Scattered cubes are immediately absorbable.
function BallService.respawn(session: Session, now: number)
	local released = BallService.releasableObjects(session.stuckStack)
	local spots = WorldSpawner.scatterSpots(
		session.part.Position,
		math.max(#released, 1),
		Config.scatterDistance + session.physicalDiameter / 2,
		random:NextNumber(0, math.pi * 2)
	)
	for index, cube in released do
		WorldSpawner.scatter(cube, spots[index], now)
	end
	session.stuckStack = {}
	BallService.setDiameter(session, Config.startDiameter)
	placeAtSpawn(session)
	WorldSpawner.refreshCluster(session.slot, now)
	BallService.publishStuck(session)
end

-- Position and velocity only: size, stuck stack and anything the run owns stay as they are.
function BallService.returnToSpawn(session: Session)
	placeAtSpawn(session)
end

-- Holds the ball still (anchored, no velocity) or hands it back to its player.
function BallService.setFrozen(session: Session, frozen: boolean)
	local part = session.part
	session.frozen = frozen
	if frozen then
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end
	applyAnchor(session)
end

-- Fresh ball for a new run: releases cubes still pending from the stack, empties it, starts at the
-- start diameter and moves to the spawn of the current zone.
function BallService.resetBall(session: Session)
	for _, cube in BallService.releasableObjects(session.stuckStack) do
		WorldSpawner.returnToSpawn(cube)
	end
	session.stuckStack = {}
	session.physicalDiameter = Config.startDiameter
	session.part.Size = Vector3.one * Config.startDiameter
	BallService.setDiameter(session, Config.startDiameter)
	local room = session.zone == "Room"
	if room then
		session.slot = healthiestSlot(session)
	end
	placeAtSpawn(session)
	if room then
		WorldSpawner.refreshCluster(session.slot, os.clock())
	end
	BallService.publishStuck(session)
end

-- One watcher per ball for the respawn sight rule: its position and, when it moves fast enough, the unit
-- heading of its horizontal velocity.
function BallService.watchers(): { Respawn.Watcher }
	local list: { Respawn.Watcher } = {}
	for _, session in sessions do
		local position = session.part.Position
		local velocity = horizontal(session.part.AssemblyLinearVelocity)
		local hx, hz = 0, 0
		if velocity.Magnitude >= Config.respawnHeadingMinSpeed then
			local unit = velocity.Unit
			hx, hz = unit.X, unit.Z
		end
		table.insert(list, { x = position.X, z = position.Z, hx = hx, hz = hz })
	end
	return list
end

local function recordViolation(
	session: Session,
	kind: "Speed" | "Displacement" | "Vertical",
	measured: number,
	limit: number,
	now: number
)
	session.violations += 1
	table.insert(session.violationLog, {
		userId = session.ownerUserId,
		kind = kind,
		measured = measured,
		limit = limit,
		at = now,
	})
	if now - session.lastWarnAt >= 0.5 then
		session.lastWarnAt = now
		warn(`[Rollossal] {kind} violation for user {session.ownerUserId}: {measured} > {limit}`)
	end
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include

-- Server-side ground probe, the same shape the client uses: a short ray below the ball against the world.
local function isGrounded(part: BasePart, diameter: number): boolean
	local world = Workspace:FindFirstChild("World")
	if world == nil then
		-- No world built yet, so there is no ground to stand on.
		return false
	end
	groundParams.FilterDescendantsInstances = { world }
	local probe = Vector3.new(0, -(diameter / 2 + Config.groundProbeExtra), 0)
	return Workspace:Raycast(part.Position, probe, groundParams) ~= nil
end

-- Horizontal speed ceiling for this session now: raised by a Dash or Spring window and its short grace.
local function ceilingFor(session: Session, now: number): number
	local boosted = now < session.boostUntil or now < session.springUntil
	local inGrace = now < session.boostGraceUntil
	return BallGuard.speedCeiling(Config.maxServerBallSpeed, Config.boostSpeedCap, boosted, inGrace)
end

-- Vertical movement guard (R-03). Clamps an upward speed over the limit, zeroes the rise of a mid-air re-jump
-- (energy over the ground reference), and resets a vertical teleport to the last valid position.
local function guardVertical(session: Session, now: number, dt: number, ceiling: number)
	local part = session.part
	local velocity = part.AssemblyLinearVelocity
	local diameter = math.max(session.authoritativeDiameter, session.physicalDiameter)
	local gravity = Workspace.Gravity
	local springVy = if now < session.springUntil then session.springVy else nil
	local tuning = JumpTuning
	local upLimit = Jump.upLimit(diameter, gravity, ceiling, springVy, tuning)
	local position = part.Position
	local rise = (position.Y - session.lastValidPosition.Y) / math.max(dt, 1e-3)
	if rise > upLimit * Config.displacementSlack then
		part.Position = session.lastValidPosition
		part.AssemblyLinearVelocity = Vector3.new(velocity.X, math.min(velocity.Y, 0), velocity.Z)
		recordViolation(session, "Vertical", rise, upLimit * Config.displacementSlack, now)
		return
	end
	local verdict, reference = BallGuard.verticalVerdict({
		y = position.Y,
		vy = velocity.Y,
		grounded = isGrounded(part, diameter),
		g = gravity,
		airRefEnergy = session.airRefEnergy,
		upLimit = upLimit,
		apexAllowance = Jump.apexAllowance(diameter, springVy, gravity, tuning),
	})
	session.airRefEnergy = reference
	if verdict == "Vertical" then
		local limit = math.min(upLimit, math.max(velocity.Y, 0))
		part.AssemblyLinearVelocity = Vector3.new(velocity.X, math.min(velocity.Y, 0), velocity.Z)
		recordViolation(session, "Vertical", velocity.Y, limit, now)
	end
end

-- Called once per Heartbeat with the Heartbeat step dt.
function BallService.step(now: number, dt: number)
	for _, session in sessions do
		local part = session.part

		local alpha = math.min(1, dt / Config.growTime)
		session.physicalDiameter += (session.authoritativeDiameter - session.physicalDiameter) * alpha
		part.Size = Vector3.one * session.physicalDiameter

		if session.frozen or session.streamHold then
			continue
		end

		if part.Position.Y < Config.fallRespawnY then
			BallService.returnToSpawn(session)
			continue
		end

		local velocity = part.AssemblyLinearVelocity
		local speed = horizontal(velocity).Magnitude
		table.insert(session.speedSamples, { t = now, speed = speed })
		while
			session.speedSamples[1] and now - session.speedSamples[1].t > Config.bumpSpeedWindow
		do
			table.remove(session.speedSamples, 1)
		end

		local position = part.Position
		local last = session.lastValidPosition
		local stepSpeed = BallGuard.stepSpeed(last.X, last.Z, position.X, position.Z, dt)
		local ceiling = ceilingFor(session, now)
		local displacementLimit = ceiling * Config.displacementSlack
		local verdict = BallGuard.verdict(speed, stepSpeed, ceiling, Config.displacementSlack)

		if verdict == "Speed" then
			local clamped = horizontal(velocity).Unit * ceiling
			part.AssemblyLinearVelocity = Vector3.new(clamped.X, velocity.Y, clamped.Z)
			session.lastValidPosition = part.Position
			recordViolation(session, "Speed", speed, ceiling, now)
		elseif verdict == "Displacement" then
			part.Position = session.lastValidPosition
			recordViolation(session, "Displacement", stepSpeed, displacementLimit, now)
		else
			if Config.Flags.ScaledJump then
				guardVertical(session, now, dt, ceiling)
			end
			session.lastValidPosition = part.Position
			session.lastValidVelocity = velocity
		end
	end
end

function BallService.start()
	local function onPlayerAdded(player: Player)
		if not sessions[player.UserId] then
			BallService.newSession(player.UserId, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		local session = sessions[player.UserId]
		if session then
			BallService.removeSession(session)
		end
	end)
end

return BallService
