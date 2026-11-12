--!strict
-- Feast (PvP): once the round's grace has passed, a ball that touches a ball small enough eats it. The eater grows
-- by a share of the victim's volume; the victim comes back at a spawn, smaller, with a short shield. A ball with a
-- hunter close by gets the flee speed, so it has a chance to get away. Rules: Shared/Rules/Feast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Feast = require(Shared.Rules.Feast)
local Worlds = require(Shared.Worlds)
local BallService = require(script.Parent.BallService)
local Remotes = require(script.Parent.Remotes)
local RunManager = require(script.Parent.RunManager)

type Session = BallService.Session

local FeastService = {}

local wasOpen = false

local function inPlay(session: Session, now: number): boolean
	return not session.frozen
		and not session.streamHold
		and session.zone == "Room"
		and RunManager.acceptsPickups(session.ownerUserId, now)
end

local function nameOf(session: Session): string
	local name = session.part:GetAttribute("DisplayName")
	return if typeof(name) == "string" then name else ""
end

-- Bites taken out of each ball in the current run of bites, and when the last one landed.
local bites: { [Session]: { count: number, at: number } } = setmetatable({}, { __mode = "k" }) :: any

-- The last bite of a run: the victim is swallowed and comes back at a spawn, smaller, with a shield.
local function swallow(eater: Session, victim: Session, now: number)
	local eaterSize, victimSize = eater.authoritativeDiameter, victim.authoritativeDiameter
	BallService.setDiameter(
		eater,
		Feast.eaterDiameter(eaterSize, victimSize, Config.feastGainShare)
	)
	local left = Feast.victimDiameter(victimSize, Config.feastKeepShare, Worlds.rules.startDiameter)
	BallService.setDiameter(victim, left)
	-- A bump can only cost a share of the run's peak; the peak follows the ball down, so that floor does too.
	victim.peakDiameter = left
	BallService.relocate(victim)
	victim.feastShieldUntil = now + Config.feastShieldSeconds
	victim.part:SetAttribute(
		"ShieldUntil",
		Workspace:GetServerTimeNow() + Config.feastShieldSeconds
	)
	bites[victim] = nil
	Remotes.FeastEvent:FireAllClients(
		eater.ownerUserId,
		victim.ownerUserId,
		nameOf(eater),
		nameOf(victim)
	)
end

-- One touch: a bite out of the victim, which is thrown clear with a moment's shield so it can run. The last bite
-- of a close run of bites swallows it.
local function eat(eater: Session, victim: Session, now: number)
	local record = bites[victim]
	local done, count = Feast.swallows(
		if record then record.count else 0,
		if record then now - record.at else math.huge,
		Config.feastBiteWindow,
		Config.feastBitesToSwallow
	)
	if done then
		swallow(eater, victim, now)
		return
	end
	bites[victim] = { count = count, at = now }

	local before = victim.authoritativeDiameter
	local after = Feast.bittenDiameter(before, Config.feastBiteKeep, Worlds.rules.startDiameter)
	BallService.setDiameter(victim, after)
	victim.peakDiameter = math.min(victim.peakDiameter, after)
	BallService.setDiameter(
		eater,
		Feast.biterDiameter(eater.authoritativeDiameter, before, after, Config.feastGainShare)
	)
	victim.feastShieldUntil = now + Config.feastBiteShieldSeconds
	victim.part:SetAttribute(
		"ShieldUntil",
		Workspace:GetServerTimeNow() + Config.feastBiteShieldSeconds
	)

	local away = victim.part.Position - eater.part.Position
	local flatAway = Vector3.new(away.X, 0, away.Z)
	local direction = if flatAway.Magnitude > 1e-3 then flatAway.Unit else Vector3.xAxis
	local knock = direction * Config.feastBiteKnockSpeed
		+ Vector3.new(0, Config.feastBiteKnockUp, 0)
	if victim.player then
		-- The owner's client applies a launch; a server write to its ball would be unreliable.
		BallService.publishLaunch(victim, knock)
	else
		victim.part.AssemblyLinearVelocity = knock
	end
	RunManager.onKnockOff(victim.ownerUserId)
end

-- Once per Heartbeat.
function FeastService.step(now: number)
	local open = RunManager.feastOpen(now)
	if not open then
		if wasOpen then
			wasOpen = false
			for _, session in BallService.allSessions() do
				BallService.setFleeing(session, false)
			end
		end
		return
	end
	wasOpen = true

	local playing: { Session } = {}
	for _, session in BallService.allSessions() do
		if inPlay(session, now) then
			table.insert(playing, session)
		else
			BallService.setFleeing(session, false)
		end
	end

	local hunted: { [Session]: boolean } = {}
	local eaten: { [Session]: boolean } = {}
	for _, eater in playing do
		if eaten[eater] then
			continue
		end
		for _, victim in playing do
			if
				victim == eater
				or eaten[victim]
				or not Feast.canEat(
					eater.authoritativeDiameter,
					victim.authoritativeDiameter,
					Config.feastEatRatio
				)
			then
				continue
			end
			local offset = victim.part.Position - eater.part.Position
			local shielded = now < victim.feastShieldUntil
			-- The margin grows with the eater: a client-owned ball is a few frames behind on the server, and the
			-- prey is pushed away as the two balls collide.
			if
				not shielded
				and Feast.touching(
					offset.Magnitude,
					eater.physicalDiameter,
					victim.physicalDiameter,
					Config.feastContactMargin + Config.feastContactShare * eater.physicalDiameter
				)
			then
				eaten[victim] = true
				eat(eater, victim, now)
			elseif
				Vector3.new(offset.X, 0, offset.Z).Magnitude
				<= Feast.fleeRadius(
					eater.authoritativeDiameter,
					Config.feastFleeRadiusDiameters,
					Config.feastFleeRadiusFloor
				)
			then
				hunted[victim] = true
			end
		end
	end
	for _, session in playing do
		BallService.setFleeing(session, hunted[session] == true and not eaten[session])
	end
end

return FeastService
