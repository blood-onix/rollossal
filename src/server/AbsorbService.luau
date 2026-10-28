--!strict
-- Validates Absorb, Bump and RespawnBall requests. Rejections are silent: they return a code and
-- never reach the client or the console.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = Shared.Rules
local Absorb = require(Rules.Absorb)
local Growth = require(Rules.Growth)
local RateLimit = require(Rules.RateLimit)
local StuckStack = require(Rules.StuckStack)
local Worlds = require(Shared.Worlds)
local Remotes = require(script.Parent.Remotes)
local RunManager = require(script.Parent.RunManager)
local BallService = require(script.Parent.BallService)
local WorldSpawner = require(script.Parent.WorldSpawner)

type Session = BallService.Session
type StuckEntry = BallService.StuckEntry

local AbsorbService = {}

local random = Random.new()
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

local function directionTo(
	session: Session,
	pooled: WorldSpawner.PooledWorldObject
): { x: number, y: number, z: number }
	local offset = session.part.CFrame:PointToObjectSpace(pooled.part.Position)
	local unit = if offset.Magnitude > 0 then offset.Unit else Vector3.yAxis
	return { x = round2(unit.X), y = round2(unit.Y), z = round2(unit.Z) }
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
	if not Absorb.canAbsorb(session.authoritativeDiameter, pooled.size, Config.absorbRatio) then
		return "TooBig"
	end

	pickupCount += 1
	local key = `{pooled.id}#{pickupCount}`
	WorldSpawner.markTaken(pooled, now, key)
	local entry: StuckEntry = {
		key = key,
		id = pooled.id,
		size = pooled.size,
		tier = pooled.tier,
		dir = directionTo(session, pooled),
	}
	session.stuckStack = StuckStack.push(session.stuckStack, entry, Config.maxTrackedStuck)
	BallService.setDiameter(
		session,
		Growth.growDiameter(session.authoritativeDiameter, pooled.size, Worlds.growthK)
	)
	BallService.publishStuck(session)
	local def = Worlds.objectById[pooled.objectId]
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
	if now - session.lastBumpAt < Config.bumpCooldown then
		return "Cooldown"
	end
	local peak = BallService.peakSpeed(session, now)
	if
		not Absorb.isKnockOff(
			session.authoritativeDiameter,
			pooled.size,
			peak,
			Config.absorbRatio,
			Config.bumpSpeedThreshold
		)
	then
		return "NotAKnockOff"
	end

	if #session.stuckStack == 0 then
		return "Ok"
	end

	local remaining, popped = StuckStack.popRecent(session.stuckStack, Config.knockOffCount)
	session.stuckStack = remaining
	local sizes: { number } = {}
	for _, entry in popped do
		table.insert(sizes, entry.size)
	end
	BallService.setDiameter(
		session,
		Growth.shrinkDiameter(
			session.authoritativeDiameter,
			sizes,
			Worlds.growthK,
			Config.startDiameter
		)
	)

	-- Only objects still waiting to respawn from these pickups land on the floor; the others are
	-- already back in the room, so their records just leave the ball.
	local released = BallService.releasableObjects(popped)
	local spots = WorldSpawner.scatterSpots(
		session.part.Position,
		math.max(#released, 1),
		Config.scatterDistance + ballRadius(session),
		random:NextNumber(0, math.pi * 2)
	)
	for index, releasedObject in released do
		WorldSpawner.scatter(releasedObject, spots[index], now + Config.scatterGrace)
	end

	session.lastBumpAt = now
	BallService.publishStuck(session)
	RunManager.onKnockOff(session.ownerUserId)
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

local function singleString(...: unknown): unknown
	if select("#", ...) ~= 1 then
		return nil
	end
	return (...)
end

function AbsorbService.start()
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
	Remotes.RespawnBall.OnServerEvent:Connect(function(player: Player)
		local session = BallService.getSession(player)
		if session then
			AbsorbService.tryRespawn(session, os.clock())
		end
	end)
end

return AbsorbService
