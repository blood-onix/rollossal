--!strict
-- Validates Absorb, Bump and RespawnBall requests. Rejections are silent: they return a code and
-- never reach the client or the console.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = Shared.Rules
local Absorb = require(Rules.Absorb)
local Growth = require(Rules.Growth)
local Light = require(Rules.Light)
local RateLimit = require(Rules.RateLimit)
local StuckStack = require(Rules.StuckStack)
local Worlds = require(Shared.Worlds)
local Remotes = require(script.Parent.Remotes)
local RunManager = require(script.Parent.RunManager)
local BallService = require(script.Parent.BallService)
local KnockOff = require(script.Parent.KnockOff)
local WorldSpawner = require(script.Parent.WorldSpawner)

type Session = BallService.Session
type StuckEntry = BallService.StuckEntry

local AbsorbService = {}

-- Server-wide pickup counter; makes every StuckEntry key unique across balls and respawns.
local pickupCount = 0

local function round2(value: number): number
	return math.round(value * 100) / 100
end

local function ballRadius(session: Session): number
	return session.physicalDiameter / 2
end

local function inRange(session: Session, pooled: WorldSpawner.PooledWorldObject): boolean
	local distance = (session.part.Position - pooled.part.Position).Magnitude
	return distance <= ballRadius(session) + pooled.size / 2 + Config.absorbDistanceTolerance
end

-- True when the ball is within `Config.bumpContactTolerance` studs of the part's own box. `inRange` is a loose centre
-- test (half the longest side), which counts a ball 7 studs from a 16 deep terrace wall as touching it.
local function nearBox(session: Session, part: BasePart): boolean
	local half = part.Size / 2
	local offset = part.CFrame:PointToObjectSpace(session.part.Position)
	local inside = Vector3.new(
		math.clamp(offset.X, -half.X, half.X),
		math.clamp(offset.Y, -half.Y, half.Y),
		math.clamp(offset.Z, -half.Z, half.Z)
	)
	return (offset - inside).Magnitude <= ballRadius(session) + Config.bumpContactTolerance
end

local function directionTo(
	session: Session,
	pooled: WorldSpawner.PooledWorldObject
): { x: number, y: number, z: number }
	local offset = session.part.CFrame:PointToObjectSpace(pooled.part.Position)
	local unit = if offset.Magnitude > 0 then offset.Unit else Vector3.yAxis
	return { x = round2(unit.X), y = round2(unit.Y), z = round2(unit.Z) }
end

-- Light ids ("L<n>", Park City Tiers 1 and 2) are judged from the server's own data, never from a Part. Returns the
-- light's info when the id is a light id (even a bad one: info is then nil and `isLight` still true).
local function lightIndex(objectId: string): (boolean, number?)
	local data = Worlds.light
	if data == nil or string.sub(objectId, 1, 1) ~= "L" then
		return false, nil
	end
	return true, Light.parseId(objectId, data.count)
end

local function lightVerdict(session: Session, info: WorldSpawner.LightInfo): string
	local data = Worlds.light
	local offset = session.part.Position - Vector3.new(info.x, info.y, info.z)
	return Light.verdict({
		exists = data ~= nil,
		taken = info.taken,
		distance = offset.Magnitude,
		ballRadius = ballRadius(session),
		size = info.size,
		tolerance = Config.absorbDistanceTolerance,
		edible = Absorb.canEat(
			Worlds.rules.absorb,
			session.authoritativeDiameter,
			info.bulk,
			info.size
		),
	})
end

-- The bulk a pickup adds to the ball's volume right now: nothing under the garnish fraction (Growth.growByBulk).
local function gainOf(session: Session, bulk: number): number
	local garnish = Worlds.rules.absorb.garnish or 0
	return if bulk < garnish * session.authoritativeDiameter then 0 else bulk
end

local function absorbLight(session: Session, index: number, objectId: string, now: number): string
	local info = WorldSpawner.getLight(index)
	if info == nil then
		return "UnknownObject"
	end
	local verdict = lightVerdict(session, info)
	if verdict ~= "Ok" then
		return verdict
	end
	local rules = Worlds.rules
	pickupCount += 1
	local key = `{objectId}#{pickupCount}`
	WorldSpawner.takeLight(index, now)
	local offset = session.part.CFrame:PointToObjectSpace(Vector3.new(info.x, info.y, info.z))
	local unit = if offset.Magnitude > 0 then offset.Unit else Vector3.yAxis
	local entry: StuckEntry = {
		key = key,
		id = objectId,
		size = info.size,
		gain = gainOf(session, info.bulk),
		tier = info.tier,
		dir = { x = round2(unit.X), y = round2(unit.Y), z = round2(unit.Z) },
	}
	session.stuckStack = StuckStack.push(session.stuckStack, entry, Config.maxTrackedStuck)
	BallService.setDiameter(
		session,
		Growth.growByBulk(
			session.authoritativeDiameter,
			info.bulk,
			rules.growthK,
			rules.absorb.garnish or 0
		)
	)
	BallService.publishStuck(session)
	local def = Worlds.objectById[info.kind]
	if def then
		RunManager.onPickup(session.ownerUserId, def, now)
	end
	return "Ok"
end

function AbsorbService.tryAbsorb(session: Session, objectId: unknown, now: number): string
	if not RunManager.acceptsPickups(session.ownerUserId, now) then
		return "RunEnded"
	end
	if typeof(objectId) ~= "string" then
		return "BadArgument"
	end

	local allowed, window =
		RateLimit.allow(session.absorbWindow, now, Config.absorbRateLimit, Config.rateLimitWindow)
	session.absorbWindow = window
	if not allowed then
		return "RateLimited"
	end

	local isLight, index = lightIndex(objectId)
	if isLight then
		if index == nil then
			return "UnknownObject"
		end
		return absorbLight(session, index, objectId, now)
	end

	local pooled = WorldSpawner.getObject(objectId)
	if not pooled then
		return "UnknownObject"
	end
	if pooled.state ~= "Available" or (pooled.availableAt ~= nil and now < pooled.availableAt) then
		return "AlreadyTaken"
	end
	if not inRange(session, pooled) then
		return "OutOfRange"
	end
	local rules = Worlds.rules
	local def = Worlds.objectById[pooled.objectId]
	local bulk = if def then Worlds.bulkOf(def) else pooled.size
	if not Absorb.canEat(rules.absorb, session.authoritativeDiameter, bulk, pooled.size) then
		return "TooBig"
	end

	pickupCount += 1
	local key = `{pooled.id}#{pickupCount}`
	WorldSpawner.markTaken(pooled, now, key)
	local entry: StuckEntry = {
		key = key,
		id = pooled.id,
		size = pooled.size,
		gain = if rules.absorb.mode == "bulk" then gainOf(session, bulk) else nil,
		tier = pooled.tier,
		dir = directionTo(session, pooled),
	}
	session.stuckStack = StuckStack.push(session.stuckStack, entry, Config.maxTrackedStuck)
	local grown = if rules.absorb.mode == "bulk"
		then Growth.growByBulk(
			session.authoritativeDiameter,
			bulk,
			rules.growthK,
			rules.absorb.garnish or 0
		)
		else Growth.growDiameter(session.authoritativeDiameter, pooled.size, rules.growthK)
	BallService.setDiameter(session, grown)
	BallService.publishStuck(session)
	if def then
		RunManager.onPickup(session.ownerUserId, def, now)
	end
	return "Ok"
end

function AbsorbService.tryBump(session: Session, objectId: unknown, now: number): string
	if not RunManager.acceptsPickups(session.ownerUserId, now) then
		return "RunEnded"
	end
	if typeof(objectId) ~= "string" then
		return "BadArgument"
	end

	local allowed, window =
		RateLimit.allow(session.bumpWindow, now, Config.absorbRateLimit, Config.rateLimitWindow)
	session.bumpWindow = window
	if not allowed then
		return "RateLimited"
	end

	local isLight, index = lightIndex(objectId)
	if isLight then
		if index == nil then
			return "UnknownObject"
		end
		local info = WorldSpawner.getLight(index)
		if info == nil then
			return "UnknownObject"
		end
		local verdict = lightVerdict(session, info)
		if verdict ~= "TooBig" then
			-- A bump claims a too-big object; anything else is refused with its own reason.
			return if verdict == "Ok" then "NotAKnockOff" else verdict
		end
		if Config.softObstacles[info.kind] then
			return "SoftObstacle"
		end
		if now - session.lastBumpAt < Config.bumpCooldown then
			return "Cooldown"
		end
		if BallService.peakSpeed(session, now) <= Config.bumpSpeedThreshold then
			return "NotAKnockOff"
		end
		local decision = KnockOff.apply(session, "obstacle", now)
		if decision == "Immune" or decision == "Cooldown" then
			return decision
		end
		return "Ok"
	end

	local pooled = WorldSpawner.getObject(objectId)
	if not pooled then
		return "UnknownObject"
	end
	if pooled.state ~= "Available" then
		return "AlreadyTaken"
	end
	if not inRange(session, pooled) then
		return "OutOfRange"
	end
	if Config.softObstacles[pooled.objectId] then
		return "SoftObstacle"
	end
	if Worlds.rules.absorb.mode == "bulk" and not nearBox(session, pooled.part) then
		return "OutOfRange"
	end
	if now - session.lastBumpAt < Config.bumpCooldown then
		return "Cooldown"
	end
	local peak = BallService.peakSpeed(session, now)
	local def = Worlds.objectById[pooled.objectId]
	local bulk = if def then Worlds.bulkOf(def) else pooled.size
	local tooBig =
		not Absorb.canEat(Worlds.rules.absorb, session.authoritativeDiameter, bulk, pooled.size)
	if not (tooBig and peak > Config.bumpSpeedThreshold) then
		return "NotAKnockOff"
	end

	local decision = KnockOff.apply(session, "obstacle", now)
	if decision == "Immune" or decision == "Cooldown" then
		return decision
	end
	return "Ok"
end

function AbsorbService.tryRespawn(session: Session, now: number): string
	local action = RunManager.resetAction(session.ownerUserId)
	if action == "Reject" then
		return "RunEnded"
	end
	if now - session.lastRespawnAt < Config.respawnBallCooldown then
		return "Cooldown"
	end
	session.lastRespawnAt = now
	if action == "Return" then
		BallService.returnToSpawn(session)
	else
		BallService.respawn(session, now)
	end
	return "Ok"
end

-- The Studio-only size tool (012 T025): sets the ball to one of the tour sizes through the normal size path. It does
-- nothing at all unless Flags.DebugSize is on, and never outside Studio.
local DEBUG_SIZES = { 1, 3, 6, 15, 35, 80 }

function AbsorbService.trySetSize(session: Session, requested: unknown): string
	if not Config.Flags.DebugSize or not RunService:IsStudio() then
		return "Disabled"
	end
	if typeof(requested) ~= "number" or not table.find(DEBUG_SIZES, requested) then
		return "BadArgument"
	end
	BallService.setDiameter(session, requested)
	return "Ok"
end

local function singleString(...: unknown): unknown
	if select("#", ...) ~= 1 then
		return nil
	end
	return (...)
end

-- LightDelta (server to client, indices only): the changes every LightDelta interval, a snapshot of every taken
-- index at join and now and then, so a client that missed a message catches up.
local SNAPSHOT_SECONDS = 30
local lastFlush = 0
local lastSnapshot = 0

function AbsorbService.stepLight(now: number)
	local remote = Remotes.LightDelta
	if remote == nil then
		return
	end
	if now - lastSnapshot >= SNAPSHOT_SECONDS then
		lastSnapshot = now
		remote:FireAllClients(WorldSpawner.takenLightIndices(), {}, true)
	end
	if now - lastFlush >= Config.lightDeltaSeconds then
		lastFlush = now
		local taken, restored = WorldSpawner.flushLight()
		if taken ~= nil and restored ~= nil then
			remote:FireAllClients(taken, restored, false)
		end
	end
end

function AbsorbService.start()
	local lightRemote = Remotes.LightDelta
	if lightRemote then
		Players.PlayerAdded:Connect(function(player: Player)
			task.delay(3, function()
				if player.Parent then
					lightRemote:FireClient(player, WorldSpawner.takenLightIndices(), {}, true)
				end
			end)
		end)
	end
	Remotes.Absorb.OnServerEvent:Connect(function(player: Player, ...: unknown)
		local session = BallService.getSession(player)
		if session then
			AbsorbService.tryAbsorb(session, singleString(...), os.clock())
		end
	end)
	Remotes.Bump.OnServerEvent:Connect(function(player: Player, ...: unknown)
		local session = BallService.getSession(player)
		if session then
			AbsorbService.tryBump(session, singleString(...), os.clock())
		end
	end)
	local debugSize = Remotes.DebugSize
	if debugSize then
		debugSize.OnServerEvent:Connect(function(player: Player, ...: unknown)
			local session = BallService.getSession(player)
			if session then
				AbsorbService.trySetSize(session, singleString(...))
			end
		end)
	end
	Remotes.RespawnBall.OnServerEvent:Connect(function(player: Player)
		local session = BallService.getSession(player)
		if session then
			AbsorbService.tryRespawn(session, os.clock())
		end
	end)
end

return AbsorbService
