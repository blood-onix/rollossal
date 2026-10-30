--!strict
-- The one knock-off executor (006, research R-12): an obstacle bump, a bumper post, a street sweeper and a
-- ball-to-ball bump all pop, shrink, scatter and notify the run the same way, and share the shield, cooldown and
-- immunity decision (Rules/Knock). Time is passed in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Growth = require(Shared.Rules.Growth)
local Knock = require(Shared.Rules.Knock)
local StuckStack = require(Shared.Rules.StuckStack)
local Worlds = require(Shared.Worlds)
local BallService = require(script.Parent.BallService)
local RunManager = require(script.Parent.RunManager)
local WorldSpawner = require(script.Parent.WorldSpawner)

type Session = BallService.Session

export type Source = "obstacle" | "bumper" | "sweeper" | "ball"

local KnockOff = {}

local random = Random.new()

-- Returns the Knock.decide result. On "Knock" the victim loses up to knockOffCount stuck objects, shrinks (never
-- below startDiameter) and the objects land on the floor for anyone to collect after scatterGrace. A shield is
-- spent by any qualifying hit. The attacker, if any, is never touched.
function KnockOff.apply(session: Session, source: Source, now: number): Knock.Decision
	local decision = Knock.decide({
		now = now,
		stuckCount = #session.stuckStack,
		shieldUntil = session.shieldUntil,
		immuneUntil = session.immuneUntil,
		lastBumpAt = session.lastBumpAt,
		bumpCooldown = Config.bumpCooldown,
	})
	if decision == "ShieldAbsorbed" then
		session.shieldUntil = -math.huge
		session.part:SetAttribute("BoostShield", 0)
		session.lastBumpAt = now
		return decision
	end
	if decision == "Immune" or decision == "Cooldown" or decision == "NothingStuck" then
		return decision
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
		Config.scatterDistance + session.physicalDiameter / 2,
		random:NextNumber(0, math.pi * 2)
	)
	for index, releasedObject in released do
		WorldSpawner.scatter(releasedObject, spots[index], now + Config.scatterGrace)
	end

	session.lastBumpAt = now
	if source == "ball" then
		session.immuneUntil = now + Config.ballBumpImmunitySeconds
	end
	BallService.publishStuck(session)
	RunManager.onKnockOff(session.ownerUserId)
	return "Knock"
end

return KnockOff
