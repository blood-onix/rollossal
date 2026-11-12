--!strict
-- Asteroid shower (fun slice): once per round, at a random moment in the window, rocks are aimed at the balls in
-- play. Each rock is announced to every client as a ground ring for meteorWarnSeconds, then lands: the balls under
-- it lose a share of their volume and are knocked away from the point. Time is os.clock; clients get server time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Feast = require(Shared.Rules.Feast)
local Worlds = require(Shared.Worlds)
local BallService = require(script.Parent.BallService)
local RunManager = require(script.Parent.RunManager)
local Remotes = require(script.Parent.Remotes)

type Session = BallService.Session

type Rock = {
	x: number,
	y: number,
	z: number,
	impactAt: number,
}

local MeteorService = {}

local random = Random.new()

local rocks: { Rock } = {}
-- Server clock time the shower begins this round (math.huge once begun or when no round is running).
local showerAt = math.huge
local showerEndsAt = -math.huge
local nextRockAt = math.huge

local function clearShower()
	rocks = {}
	showerAt = math.huge
	showerEndsAt = -math.huge
	nextRockAt = math.huge
end

-- The balls a rock can hit: not frozen, not held for streaming, and in the Room.
local function inPlay(): { Session }
	local list: { Session } = {}
	for _, session in BallService.allSessions() do
		if not session.frozen and not session.streamHold and session.zone == "Room" then
			table.insert(list, session)
		end
	end
	return list
end

local function clampToSlice(x: number, z: number): (number, number)
	if not Config.Slice.enabled then
		return x, z
	end
	return math.clamp(x, Config.Slice.minX, Config.Slice.maxX),
		math.clamp(z, Config.Slice.minZ, Config.Slice.maxZ)
end

-- Picks a target ball and a point near it: close with meteorAimChance, otherwise a wider scatter.
local function scheduleRock(now: number, targets: { Session })
	local target = targets[random:NextInteger(1, #targets)]
	local spread = Config.meteorAimSpread
	if random:NextNumber() >= Config.meteorAimChance then
		spread = Config.meteorAimSpread * 6
	end
	local position = target.part.Position
	local x, z = clampToSlice(
		position.X + random:NextNumber(-spread, spread),
		position.Z + random:NextNumber(-spread, spread)
	)
	local y = position.Y - target.part.Size.Y / 2
	local impactAt = now + Config.meteorWarnSeconds

	table.insert(rocks, { x = x, y = y, z = z, impactAt = impactAt })
	Remotes.MeteorEvent:FireAllClients(
		"rock",
		x,
		y,
		z,
		Config.meteorRadius,
		Workspace:GetServerTimeNow() + Config.meteorWarnSeconds
	)
end

-- Shrinks and knocks away every in-play ball under the rock. Immune balls are skipped.
local function land(rock: Rock, now: number)
	for _, session in inPlay() do
		local dx = session.part.Position.X - rock.x
		local dz = session.part.Position.Z - rock.z
		local distance = math.sqrt(dx * dx + dz * dz)
		if
			distance <= Config.meteorRadius + session.authoritativeDiameter / 2
			and now >= session.immuneUntil
			and now >= session.feastShieldUntil
		then
			BallService.setDiameter(
				session,
				Feast.shrinkByShare(
					session.authoritativeDiameter,
					Config.meteorShrinkShare,
					Worlds.rules.startDiameter
				)
			)
			local dirX = 0
			local dirZ = 0
			if distance > 0 then
				dirX = dx / distance
				dirZ = dz / distance
			end
			BallService.publishLaunch(
				session,
				Vector3.new(
					dirX * Config.meteorKnockSpeed,
					Config.meteorKnockSpeed * 0.5,
					dirZ * Config.meteorKnockSpeed
				)
			)
			if session.player then
				Remotes.MeteorHit:FireClient(session.player)
			end
		end
	end
end

function MeteorService.start()
	local function schedule(startedAt: number)
		rocks = {}
		showerAt = startedAt + random:NextNumber(Config.meteorWindowStart, Config.meteorWindowEnd)
		showerEndsAt = -math.huge
		nextRockAt = math.huge
	end
	RunManager.onRoundStart(function(round)
		schedule(round.startedAt)
	end)
	-- A player who joined before the services started has already begun the first round.
	if RunManager.roundActive(os.clock()) then
		schedule(RunManager.round().startedAt)
	end
end

function MeteorService.step(now: number)
	if not RunManager.roundActive(now) then
		clearShower()
		return
	end

	if now >= showerAt then
		showerAt = math.huge
		showerEndsAt = now + Config.meteorShowerSeconds
		nextRockAt = now
		Remotes.MeteorEvent:FireAllClients(
			"shower",
			Workspace:GetServerTimeNow() + Config.meteorShowerSeconds
		)
	end

	if now < showerEndsAt and now >= nextRockAt then
		nextRockAt = now + Config.meteorInterval
		local targets = inPlay()
		if #targets > 0 then
			scheduleRock(now, targets)
		end
	end

	local index = 1
	while index <= #rocks do
		local rock = rocks[index]
		if now >= rock.impactAt then
			table.remove(rocks, index)
			land(rock, now)
		else
			index += 1
		end
	end
end

return MeteorService
