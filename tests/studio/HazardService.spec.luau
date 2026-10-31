--!strict
-- Bumper post, street sweeper and ball-to-ball knock-offs against the real world (006). Expected values come from
-- the Config numbers (knockOffCount 3, immunity 3 s, scatterGrace 1 s) and research R-12, R-13.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local Config = require(ReplicatedStorage.Shared.Config)
local Patrol = require(ReplicatedStorage.Shared.Rules.Patrol)
local AbsorbService = require(ServerScriptService.AbsorbService)
local BallService = require(ServerScriptService.BallService)
local HazardService = require(ServerScriptService.HazardService)
local WorldSpawner = require(ServerScriptService.WorldSpawner)
local Fixtures = require(script.Parent.Fixtures)

local NOW = 4000
local DT = 1 / 60
local SKY = Vector3.new(6000, 6000, 6000)
local created: { BallService.Session } = {}
local nextUserId = 940000

local function newSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId)
	table.insert(created, session)
	session.part.Anchored = true
	return session
end

-- Four dummy stuck entries (not in the registry), so a knock-off has something to pop.
local function stuff(session: BallService.Session, count: number)
	session.stuckStack = {}
	for index = 1, count do
		table.insert(session.stuckStack, {
			key = `dummy#{index}`,
			id = `dummy-{index}`,
			size = 0.5,
			tier = 1,
			dir = { x = 0, y = 1, z = 0 },
		})
	end
end

local function hazardOf(subKind: string): HazardService.HazardInstance
	for _, hazard in HazardService.hazards() do
		if hazard.subKind == subKind then
			return hazard
		end
	end
	error(`no {subKind} hazard built`)
end

describe("HazardService", function()
	beforeAll(function()
		WorldSpawner.start()
		WorldSpawner.setWatcherSource(function()
			return {}
		end)
	end)
	beforeEach(function()
		WorldSpawner.reset()
		HazardService.reset()
	end)
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it(
		"a bumper post knocks off three objects, launches the ball away, and bounces once per cooldown",
		function()
			local bumper = hazardOf("bumper")
			local session = newSession()
			stuff(session, 4)
			session.part.Position = bumper.centre + Vector3.new(bumper.radius + 0.5, 0.5, 0)
			HazardService.step(NOW, DT)
			expect(#session.stuckStack).toBe(4 - Config.knockOffCount)
			local launch = session.part:GetAttribute("Launch") :: string
			expect(string.sub(launch, 1, 2)).toBe("1;")
			expect(tonumber(string.split(launch, ";")[2]) :: number).toBe(Config.bumperBounceSpeed)
			HazardService.step(NOW + 0.1, DT)
			expect(session.launchSeq).toBe(1)
		end
	)

	it("a Shield absorbs a bumper hit but the ball still bounces", function()
		local bumper = hazardOf("bumper")
		local session = newSession()
		stuff(session, 4)
		session.shieldUntil = NOW + 10
		session.part.Position = bumper.centre + Vector3.new(bumper.radius + 0.5, 0.5, 0)
		HazardService.step(NOW, DT)
		expect(#session.stuckStack).toBe(4)
		expect(session.shieldUntil).toBe(-math.huge)
		expect(session.launchSeq).toBe(1)
	end)

	it("the street sweeper knocks off objects where the patrol puts it", function()
		local sweeper = hazardOf("sweeper")
		local session = newSession()
		stuff(session, 4)
		local waypoints = sweeper.waypoints :: { Patrol.Point }
		local pose =
			Patrol.position(waypoints, sweeper.speed, Workspace:GetServerTimeNow() - sweeper.epoch)
		session.part.Position = Vector3.new(pose.x, 1, pose.z)
		HazardService.step(NOW, DT)
		expect(#session.stuckStack).toBe(4 - Config.knockOffCount)
		expect(session.launchSeq).toBe(1)
	end)

	it("a wider ball bumping a smaller one knocks it off and grants 3 s immunity", function()
		local attacker = newSession()
		local victim = newSession()
		attacker.authoritativeDiameter = 5
		attacker.physicalDiameter = 5
		victim.authoritativeDiameter = 2
		victim.physicalDiameter = 2
		stuff(victim, 9)
		attacker.part.Position = SKY
		victim.part.Position = SKY + Vector3.new(3, 0, 0)
		attacker.speedSamples = { { t = NOW, speed = 20 } }

		HazardService.step(NOW, DT)
		expect(#victim.stuckStack).toBe(6)
		expect(victim.immuneUntil).toBe(NOW + Config.ballBumpImmunitySeconds)
		expect(#attacker.stuckStack).toBe(0)
		expect(attacker.authoritativeDiameter).toBe(5)

		-- Past the bump cooldown but inside the immunity: nothing more is knocked off.
		attacker.speedSamples = { { t = NOW + 1.5, speed = 20 } }
		HazardService.step(NOW + 1.5, DT)
		expect(#victim.stuckStack).toBe(6)

		-- Immunity over: the next bump knocks off again.
		attacker.speedSamples = { { t = NOW + 3.5, speed = 20 } }
		HazardService.step(NOW + 3.5, DT)
		expect(#victim.stuckStack).toBe(3)
	end)

	it("two balls of similar size, or a slow bump, knock nothing off", function()
		local a = newSession()
		local b = newSession()
		a.authoritativeDiameter = 3
		a.physicalDiameter = 3
		b.authoritativeDiameter = 2.8
		b.physicalDiameter = 2.8
		stuff(b, 4)
		a.part.Position = SKY
		b.part.Position = SKY + Vector3.new(2, 0, 0)
		a.speedSamples = { { t = NOW, speed = 30 } }
		HazardService.step(NOW, DT)
		expect(#b.stuckStack).toBe(4)
		a.authoritativeDiameter = 6
		a.speedSamples = { { t = NOW + 5, speed = 5 } }
		HazardService.step(NOW + 5, DT)
		expect(#b.stuckStack).toBe(4)
	end)

	it("scattered objects are collectable by a third ball after scatterGrace", function()
		local acorns = Fixtures.ids("acorn", 3)
		local attacker = newSession()
		local victim = newSession()
		local third = newSession()
		attacker.authoritativeDiameter = 5
		attacker.physicalDiameter = 5
		victim.authoritativeDiameter = 2
		victim.physicalDiameter = 2
		victim.stuckStack = {}
		for index, id in acorns do
			local object = WorldSpawner.getObject(id) :: WorldSpawner.PooledWorldObject
			local key = `{id}#{index}`
			WorldSpawner.markTaken(object, NOW, key)
			table.insert(victim.stuckStack, {
				key = key,
				id = id,
				size = object.size,
				tier = object.tier,
				dir = { x = 0, y = 1, z = 0 },
			})
		end
		attacker.part.Position = SKY
		victim.part.Position = SKY + Vector3.new(3, 0, 0)
		attacker.speedSamples = { { t = NOW + 1, speed = 20 } }
		HazardService.step(NOW + 1, DT)
		for _, id in acorns do
			expect((WorldSpawner.getObject(id) :: WorldSpawner.PooledWorldObject).state).toBe(
				"Scattered"
			)
		end
		WorldSpawner.update(NOW + 1 + Config.scatterGrace + 0.01)
		local target = WorldSpawner.getObject(acorns[1]) :: WorldSpawner.PooledWorldObject
		expect(target.state).toBe("Available")
		third.part.Position = target.part.Position + Vector3.yAxis
		expect(AbsorbService.tryAbsorb(third, acorns[1], NOW + 3)).toBe("Ok")
	end)
end)
