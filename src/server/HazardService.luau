--!strict
-- Hazard contact (006): detects a ball touching a bumper post or the street sweeper, and one ball bumping a
-- smaller one, on the server (no remote), then runs the shared knock-off and publishes the bounce as a Launch.
-- The sweeper's position comes from Rules/Patrol with server time, the same function the clients move their copy by.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Knock = require(Shared.Rules.Knock)
local Patrol = require(Shared.Rules.Patrol)
local Traps = require(Shared.Rules.Traps)
local BallService = require(script.Parent.BallService)
local KnockOff = require(script.Parent.KnockOff)
local RunManager = require(script.Parent.RunManager)

type Session = BallService.Session

export type HazardInstance = {
	markerId: string,
	subKind: "bumper" | "sweeper",
	part: BasePart,
	centre: Vector3,
	-- Bumper: radius. Sweeper: half extents of the machine (local X across, Z along its travel).
	radius: number,
	halfAcross: number,
	halfAlong: number,
	top: number,
	waypoints: { Patrol.Point }?,
	speed: number,
	epoch: number,
}

local HAZARD_TAG = "TrapHazard"

local HazardService = {}

local hazards: { HazardInstance } = {}
-- When each (ball, hazard) pair last bounced, so a ball resting on a post bounces once per cooldown, not per frame.
local lastContact: { [string]: number } = {}

local function readNumber(part: BasePart, name: string, fallback: number): number
	local value = part:GetAttribute(name)
	return if typeof(value) == "number" then value else fallback
end

local function readWaypoints(part: BasePart): { Patrol.Point }?
	local count = part:GetAttribute("WpCount")
	if typeof(count) ~= "number" or count < 3 then
		return nil
	end
	local points: { Patrol.Point } = {}
	for index = 1, count do
		local x = part:GetAttribute(`Wp{index}X`)
		local z = part:GetAttribute(`Wp{index}Z`)
		if typeof(x) ~= "number" or typeof(z) ~= "number" then
			return nil
		end
		table.insert(points, { x = x, z = z })
	end
	return points
end

local function collect()
	table.clear(hazards)
	for _, instance in CollectionService:GetTagged(HAZARD_TAG) do
		if not instance:IsA("BasePart") then
			continue
		end
		local kind = instance:GetAttribute("Kind")
		local id = instance:GetAttribute("MarkerId")
		if typeof(id) ~= "string" then
			continue
		end
		if kind == "bumper" then
			table.insert(hazards, {
				markerId = id,
				subKind = "bumper",
				part = instance,
				centre = instance.Position,
				radius = readNumber(instance, "Radius", 2),
				halfAcross = 0,
				halfAlong = 0,
				top = instance.Position.Y + readNumber(instance, "Height", 3) / 2,
				waypoints = nil,
				speed = 0,
				epoch = 0,
			})
		elseif kind == "sweeper" then
			local epoch = instance:GetAttribute("PatrolEpoch")
			local speed = instance:GetAttribute("Speed")
			table.insert(hazards, {
				markerId = id,
				subKind = "sweeper",
				part = instance,
				centre = instance.Position,
				radius = 0,
				halfAcross = instance.Size.X / 2,
				halfAlong = instance.Size.Z / 2,
				top = instance.Position.Y + instance.Size.Y / 2,
				waypoints = readWaypoints(instance),
				speed = if typeof(speed) == "number" then speed else Config.sweeperSpeed,
				epoch = if typeof(epoch) == "number" then epoch else 0,
			})
		end
	end
end

function HazardService.hazards(): { HazardInstance }
	return hazards
end

function HazardService.patrolEpoch(): number
	for _, hazard in hazards do
		if hazard.subKind == "sweeper" then
			return hazard.epoch
		end
	end
	return 0
end

local function away(from: Vector3, to: Vector3, speed: number): Vector3
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local direction = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.xAxis
	return direction * speed
end

local function bounce(session: Session, from: Vector3, speed: number)
	BallService.publishLaunch(session, away(from, session.part.Position, speed))
end

-- True and the point the ball is pushed away from, when the ball touches this hazard at server time `serverNow`.
local function touching(
	hazard: HazardInstance,
	session: Session,
	serverNow: number
): (boolean, Vector3)
	local position = session.part.Position
	local radius = session.physicalDiameter / 2
	local margin = Config.hazardContactMargin
	if hazard.subKind == "bumper" then
		local dx, dz = position.X - hazard.centre.X, position.Z - hazard.centre.Z
		local near = hazard.radius + radius + margin
		local low = position.Y - radius
		return dx * dx + dz * dz <= near * near and low <= hazard.top, hazard.centre
	end
	local waypoints = hazard.waypoints
	if waypoints == nil then
		return false, hazard.centre
	end
	local pose = Patrol.position(waypoints, hazard.speed, serverNow - hazard.epoch)
	local centre = Vector3.new(pose.x, hazard.centre.Y, pose.z)
	local inside = Traps.insideRect(
		position.X,
		position.Z,
		pose.x,
		pose.z,
		hazard.halfAcross + radius + margin,
		hazard.halfAlong + radius + margin,
		math.deg(pose.heading)
	)
	return inside and position.Y - radius <= hazard.top, centre
end

local function inPlay(session: Session, now: number): boolean
	return not session.frozen
		and not session.streamHold
		and session.zone == "Room"
		and RunManager.acceptsPickups(session.ownerUserId, now)
end

local function stepHazards(session: Session, now: number, serverNow: number)
	for _, hazard in hazards do
		local hit, from = touching(hazard, session, serverNow)
		if not hit then
			continue
		end
		local key = `{session.ownerUserId}:{hazard.markerId}`
		if now - (lastContact[key] or -math.huge) < Config.bumpCooldown then
			continue
		end
		lastContact[key] = now
		KnockOff.apply(session, hazard.subKind, now)
		local speed = if hazard.subKind == "bumper"
			then Config.bumperBounceSpeed
			else Config.sweeperBounceSpeed
		bounce(session, from, speed)
	end
end

-- Ball-to-ball (R-13): the wider ball (at least ballBumpSizeRatio times) closing fast on a smaller one knocks the
-- smaller one's objects off. Neither ball is swallowed or removed, and the attacker is untouched.
local function stepBumps(playing: { Session }, now: number)
	for _, attacker in playing do
		for _, victim in playing do
			if attacker == victim then
				continue
			end
			local a, b = attacker.part.Position, victim.part.Position
			local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			local reach = attacker.physicalDiameter / 2
				+ victim.physicalDiameter / 2
				+ Config.ballBumpContactMargin
			if flat.Magnitude > reach or flat.Magnitude < 1e-3 then
				continue
			end
			local line = flat.Unit
			local vBAlong = victim.part.AssemblyLinearVelocity:Dot(line)
			local closing = Knock.closingSpeed(BallService.peakSpeed(attacker, now), vBAlong)
			if
				Knock.ballBump(
					attacker.authoritativeDiameter,
					victim.authoritativeDiameter,
					closing,
					Config.ballBumpSizeRatio,
					Config.bumpSpeedThreshold
				)
			then
				KnockOff.apply(victim, "ball", now)
			end
		end
	end
end

-- Once per Heartbeat.
function HazardService.step(now: number, _dt: number)
	local serverNow = Workspace:GetServerTimeNow()
	local playing: { Session } = {}
	for _, session in BallService.allSessions() do
		if inPlay(session, now) then
			table.insert(playing, session)
			if #hazards > 0 then
				stepHazards(session, now, serverNow)
			end
		end
	end
	if Config.Flags.BallToBallBumps and #playing > 1 then
		stepBumps(playing, now)
	end
end

function HazardService.start()
	collect()
	CollectionService:GetInstanceAddedSignal(HAZARD_TAG):Connect(collect)
end

-- Test helper: forget contact history and read the hazards again.
function HazardService.reset()
	table.clear(lastContact)
	collect()
end

return HazardService
