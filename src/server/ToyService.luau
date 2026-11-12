--!strict
-- The map's toys: boost, bounce and spring pads, catapults, rails and pipes. The server decides (Constitution II): it
-- sees a ball on a toy, opens the ball guard's flight window, and publishes a Launch or Ride fact that the owner's
-- client applies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Toys = require(Shared.Rules.Toys)
local Worlds = require(Shared.Worlds)
local Tiers = require(Shared.Rules.Tiers)
local BallService = require(script.Parent.BallService)
local BoosterService = require(script.Parent.BoosterService)
local RunManager = require(script.Parent.RunManager)

type Session = BallService.Session

local ANY_RAIL = "anyRail"

local ToyService = {}

local pads: { any } = {}
local catapults: { any } = {}
local rails: { any } = {}
local cooldowns: { [number]: { [string]: number } } = {}
local rideSeq: { [number]: number } = {}
local toySeq: { [number]: number } = {}
local lastTier: { [number]: number } = {}

local function cooling(session: Session, id: string, now: number): boolean
	local own = cooldowns[session.ownerUserId]
	return own ~= nil and now < (own[id] or -math.huge)
end

local function cool(session: Session, id: string, now: number, seconds: number)
	local own = cooldowns[session.ownerUserId]
	if own == nil then
		own = {}
		cooldowns[session.ownerUserId] = own
	end
	(own :: { [string]: number })[id] = now + seconds
end

-- Tells the owner's client which toy fired, for its sound and camera kick.
local function announce(session: Session, kind: string)
	local seq = (toySeq[session.ownerUserId] or 0) + 1
	toySeq[session.ownerUserId] = seq
	session.part:SetAttribute("ToyFx", `{seq};{kind}`)
end

-- The ball guard allows the flight this launch is about to make.
local function openFlight(session: Session, now: number, seconds: number, vy: number)
	session.flightUntil = math.max(session.flightUntil, now + seconds + Config.toyFlightGrace)
	if vy > 0 then
		session.springUntil = math.max(session.springUntil, now + seconds)
		session.springVy = math.max(vy, session.springVy)
	end
	session.boostGraceUntil = math.max(session.boostGraceUntil, session.flightUntil)
end

local function firePad(session: Session, pad: any, now: number)
	local gravity = Workspace.Gravity
	local velocity = session.part.AssemblyLinearVelocity
	local dx, dz = Toys.direction(pad.yaw)
	if pad.kind == "boost" then
		openFlight(session, now, Config.toyBoostFlight, 0)
		BallService.publishLaunch(session, Vector3.new(dx, 0, dz) * Config.toyBoostSpeed)
		BoosterService.grantDash(session, now, Config.toyBoostDash)
		announce(session, "boost")
		return
	end
	local apex: number
	if pad.kind == "bounce" then
		apex = math.max(Config.toyBounceApexFloor, (pad.up or 0) * Config.toyBounceApexScale)
	else
		apex = (pad.up or 0) * Config.toySpringApexScale
	end
	local vy = Toys.apexSpeed(apex, gravity)
	local forward = (pad.forward or 0) * Config.toyBounceForwardScale
	openFlight(session, now, 2 * vy / gravity, vy)
	BallService.publishLaunch(
		session,
		Vector3.new(velocity.X + dx * forward, vy, velocity.Z + dz * forward)
	)
	announce(session, pad.kind)
end

local function checkPads(session: Session, ball: Toys.Vec3, diameter: number, now: number)
	for _, pad in pads do
		if
			not cooling(session, pad.id, now)
			and diameter >= (pad.dMin or 0) * Config.toyMinSizeScale
			and Toys.onPad(ball, diameter, pad, Config.toyPadVerticalReach)
		then
			cool(session, pad.id, now, Config.toyPadCooldown)
			firePad(session, pad, now)
			return
		end
	end
end

local function checkCatapults(session: Session, ball: Toys.Vec3, diameter: number, now: number)
	for _, catapult in catapults do
		local big = catapult.kind == "big_slingshot"
		-- Only a ball in the bucket is thrown; rolling past the frame does nothing.
		local scale = if big then 2 else 1
		local reach = Config.toyCatapultReach * scale
			+ Config.toyCatapultReachPerDiameter * diameter
		local aimX, aimZ = Toys.direction(catapult.restYaw)
		local bucket = Config.toyCatapultBucket * scale
		local dx = ball.x - (catapult.x - aimX * bucket)
		local dz = ball.z - (catapult.z - aimZ * bucket)
		if
			dx * dx + dz * dz <= reach * reach
			and diameter >= catapult.dMin * Config.toyMinSizeScale
			and diameter <= catapult.dMax * Config.toyMaxSizeScale
			and not cooling(session, catapult.id, now)
		then
			cool(session, catapult.id, now, Config.toyCatapultCooldown)
			local arc = Toys.arc(ball, catapult.landing, catapult.apex, Workspace.Gravity)
			openFlight(session, now, arc.seconds, arc.vy)
			BallService.publishLaunch(session, Vector3.new(arc.vx, arc.vy, arc.vz))
			announce(session, "catapult")
			return
		end
	end
end

local function checkRails(session: Session, ball: Toys.Vec3, diameter: number, now: number)
	-- Rails lie side by side: the end of one ride must not catch the ball on the next rail and throw it back.
	if cooling(session, ANY_RAIL, now) then
		return
	end
	local velocity = session.part.AssemblyLinearVelocity
	for _, rail in rails do
		local pipe = rail.kind == "pipe"
		local hit = Toys.nearestOnPath(rail.points, ball)
		local reach = diameter / 2 + (if pipe then Config.toyPipeReach else Config.toyRailReach)
		local _, railY = Toys.pointAt(rail.points, hit.along)
		if
			hit.distance <= reach
			and Toys.railAtBallLevel(railY, ball.y, diameter, Config.toyRailAboveBall)
			and diameter <= rail.dMax * Config.toyMaxSizeScale
			and not cooling(session, rail.id, now)
		then
			local direction = Toys.railCatch(
				hit,
				rail.length,
				velocity.X,
				velocity.Z,
				Config.toyRailEndReach,
				if pipe then math.huge else Config.toyRailAlignment
			)
			if direction ~= nil then
				local travel = if direction > 0 then rail.length - hit.along else hit.along
				local seconds = travel
					/ (
						rail.speed
						* (if pipe then Config.toyPipeSpeedScale else Config.toyRailSpeedScale)
					)
				cool(session, rail.id, now, seconds + Config.toyRailCooldown)
				cool(session, ANY_RAIL, now, seconds + Config.toyRailCooldown)
				session.rideUntil = now + seconds + 0.3
				-- The guard's spring window covers the ride: a rail may climb and the ball is off the ground.
				openFlight(session, now, seconds + 1.5, Config.toyRideGuardSpeed)
				local seq = (rideSeq[session.ownerUserId] or 0) + 1
				rideSeq[session.ownerUserId] = seq
				session.part:SetAttribute(
					"Ride",
					string.format("%d;%s;%.2f;%d", seq, rail.id, hit.along, direction)
				)
				announce(session, if pipe then "pipe" else "rail")
				return
			end
		end
	end
end

-- A size-tier jump sucks in everything edible around the ball for a moment.
local function checkVacuum(session: Session, now: number)
	local tier = Tiers.lookup(session.authoritativeDiameter, Worlds.tierLikes)
	local last = lastTier[session.ownerUserId]
	lastTier[session.ownerUserId] = tier
	if last ~= nil and tier > last then
		session.vacuumUntil = now + Config.vacuumSeconds
		session.part:SetAttribute("Vacuum", Workspace:GetServerTimeNow() + Config.vacuumSeconds)
		announce(session, "vacuum")
	end
end

-- Once per Heartbeat.
function ToyService.step(now: number)
	for _, session in BallService.allSessions() do
		if
			session.frozen
			or session.streamHold
			or now < session.rideUntil
			or not RunManager.acceptsPickups(session.ownerUserId, now)
		then
			continue
		end
		checkVacuum(session, now)
		local at = session.part.Position
		local ball = { x = at.X, y = at.Y, z = at.Z }
		local diameter = session.physicalDiameter
		checkPads(session, ball, diameter, now)
		checkCatapults(session, ball, diameter, now)
		checkRails(session, ball, diameter, now)
	end
end

function ToyService.start()
	if not Config.Flags.Toys then
		return
	end
	for _, item in ((Worlds.active :: any).placeholders or {}) :: { any } do
		local kind: string = item.kind
		if kind == "boost" or kind == "bounce" or kind == "spring" then
			table.insert(pads, item)
		elseif kind == "catapult" or kind == "big_slingshot" then
			if item.landing == nil then
				local dx, dz = Toys.direction(item.restYaw)
				local distance = (item.range[1] + item.range[2]) / 2
				item = table.clone(item)
				item.landing = { x = item.x + dx * distance, y = 0, z = item.z + dz * distance }
			end
			table.insert(catapults, item)
		elseif kind == "pipe" or (kind == "rail" and Config.toyRails) then
			item = table.clone(item)
			item.length = Toys.pathLength(item.points)
			table.insert(rails, item)
		end
	end
	BallService.onClear(function(session: Session)
		session.part:SetAttribute("Ride", "")
		session.rideUntil = -math.huge
		session.part:SetAttribute("Vacuum", 0)
		cooldowns[session.ownerUserId] = nil
		lastTier[session.ownerUserId] = nil
	end)
end

return ToyService
