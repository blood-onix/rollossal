--!strict
-- Ball sessions: one Part per player, network-owned by that player, with server-side growth easing,
-- the Stuck attribute, the per-Heartbeat speed and displacement check, and respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GreyBoxRoom = require(Shared.Content.GreyBoxRoom)
local StuckStack = require(Shared.Rules.StuckStack)
local WorldSpawner = require(script.Parent.WorldSpawner)

-- A visual-only record of one pickup. key is unique per pickup (`<id>#<n>`), so the same cube can
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
	kind: "Speed" | "Displacement",
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
}

local BallService = {}

local sessions: { [number]: Session } = {}
local random = Random.new()

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

local function freeSlot(): number
	local used: { [number]: boolean } = {}
	for _, session in sessions do
		used[session.slot] = true
	end
	for index = 1, GreyBoxRoom.spawnSlots do
		if not used[index] then
			return index
		end
	end
	return 1
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

function BallService.getSessionByUserId(userId: number): Session?
	return sessions[userId]
end

-- The cubes these entries can still release: those waiting to respawn from the same pickup. A cube
-- that has already respawned (or been taken again) stays where it is.
function BallService.releasableCubes(entries: { StuckEntry }): { WorldSpawner.RoomCube }
	local cubes: { WorldSpawner.RoomCube } = {}
	for _, entry in entries do
		local cube = WorldSpawner.getCube(entry.id)
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

	local slot = freeSlot()
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
	}
	if player then
		part:SetNetworkOwner(player)
		-- No character, so streaming needs the ball as its focus or the client never receives it.
		player.ReplicationFocus = part
	end
	sessions[userId] = session
	return session
end

function BallService.removeSession(session: Session)
	for _, cube in BallService.releasableCubes(session.stuckStack) do
		WorldSpawner.returnToSpawn(cube)
	end
	session.stuckStack = {}
	session.part:Destroy()
	sessions[session.ownerUserId] = nil
end

local function placeAtSpawn(session: Session)
	local spawn = if session.zone == "Hub"
		then WorldSpawner.getHubSpawn()
		else WorldSpawner.getSpawnSlot(session.slot)
	session.part.AssemblyLinearVelocity = Vector3.zero
	session.part.AssemblyAngularVelocity = Vector3.zero
	session.part.Position = spawn
	session.lastValidPosition = spawn
	session.lastValidVelocity = Vector3.zero
end

-- Scatters the cubes the stack can still release around the ball, empties the stack, resets the
-- diameter and returns the ball to its spawn slot. Scattered cubes are immediately absorbable.
function BallService.respawn(session: Session, now: number)
	local released = BallService.releasableCubes(session.stuckStack)
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
		part.Anchored = true
		return
	end
	part.Anchored = false
	if session.player then
		part:SetNetworkOwner(session.player)
	end
	session.lastValidPosition = part.Position
	session.lastValidVelocity = Vector3.zero
end

-- Fresh ball for a new run: releases cubes still pending from the stack, empties it, starts at the
-- start diameter and moves to the spawn of the current zone.
function BallService.resetBall(session: Session)
	for _, cube in BallService.releasableCubes(session.stuckStack) do
		WorldSpawner.returnToSpawn(cube)
	end
	session.stuckStack = {}
	session.physicalDiameter = Config.startDiameter
	session.part.Size = Vector3.one * Config.startDiameter
	BallService.setDiameter(session, Config.startDiameter)
	placeAtSpawn(session)
	BallService.publishStuck(session)
end

local function recordViolation(
	session: Session,
	kind: "Speed" | "Displacement",
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

-- Called once per Heartbeat with the Heartbeat step dt.
function BallService.step(now: number, dt: number)
	for _, session in sessions do
		local part = session.part

		local alpha = math.min(1, dt / Config.growTime)
		session.physicalDiameter += (session.authoritativeDiameter - session.physicalDiameter) * alpha
		part.Size = Vector3.one * session.physicalDiameter

		if session.frozen then
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

		local stepSpeed = horizontal(part.Position - session.lastValidPosition).Magnitude / dt
		local displacementLimit = Config.maxServerBallSpeed * Config.displacementSlack

		if speed > Config.maxServerBallSpeed then
			local clamped = horizontal(velocity).Unit * Config.maxServerBallSpeed
			part.AssemblyLinearVelocity = Vector3.new(clamped.X, velocity.Y, clamped.Z)
			recordViolation(session, "Speed", speed, Config.maxServerBallSpeed, now)
		elseif stepSpeed > displacementLimit then
			part.Position = session.lastValidPosition
			recordViolation(session, "Displacement", stepSpeed, displacementLimit, now)
		else
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
