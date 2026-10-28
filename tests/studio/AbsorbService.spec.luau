--!strict
-- Server absorb validation against the real registry (Constitution II, FR-024). Expected values are
-- hand-computed from contracts/rules-api.md and research.md R1, never from the code under test.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local Config = require(ReplicatedStorage.Shared.Config)
local Growth = require(ReplicatedStorage.Shared.Rules.Growth)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local AbsorbService = require(ServerScriptService.AbsorbService)
local BallService = require(ServerScriptService.BallService)
local WorldSpawner = require(ServerScriptService.WorldSpawner)
local Fixtures = require(script.Parent.Fixtures)

-- Fixture placements picked by object type: acorns (0.5) are eatable from the start, a bauble (0.8) sits
-- exactly on the 0.4 * 2 limit, a duck (1.6) is too big for a ball of 2.
local small = Fixtures.ids("acorn", 12)
local bauble = Fixtures.ids("bauble", 1)[1]
local duck = Fixtures.ofTier(2)
local ACORN = 0.5

local NOW = 1000
local created: { BallService.Session } = {}
local nextUserId = 900000

local function newSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId)
	table.insert(created, session)
	return session
end

local function placeOn(session: BallService.Session, objectId: string)
	local object = WorldSpawner.getObject(objectId)
	assert(object, `missing object {objectId}`)
	session.part.Position = object.part.Position + Vector3.yAxis
end

local function objectState(objectId: string): string
	local object = WorldSpawner.getObject(objectId)
	assert(object, `missing object {objectId}`)
	return object.state
end

describe("AbsorbService rejections", function()
	beforeAll(function()
		WorldSpawner.start()
		-- No ball watches a spot during the specs, so a due object always returns.
		WorldSpawner.setWatcherSource(function()
			return {}
		end)
	end)
	beforeEach(function()
		WorldSpawner.reset()
	end)
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("rejects an unknown object ID and leaves the diameter unchanged", function()
		local session = newSession()
		expect(AbsorbService.tryAbsorb(session, "T9-99", NOW)).toBe("UnknownObject")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("rejects an already taken object", function()
		local session = newSession()
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], NOW)).toBe("Ok")
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], NOW + 1)).toBe("AlreadyTaken")
	end)

	it("rejects an object out of range", function()
		local session = newSession()
		session.part.Position = Vector3.new(30, 1, 30)
		expect(AbsorbService.tryAbsorb(session, small[1], NOW)).toBe("OutOfRange")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("rejects an object too big for the current diameter", function()
		local session = newSession()
		placeOn(session, duck)
		expect(AbsorbService.tryAbsorb(session, duck, NOW)).toBe("TooBig")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("rejects a non-string object ID", function()
		local session = newSession()
		expect(AbsorbService.tryAbsorb(session, 5, NOW)).toBe("BadArgument")
		expect(AbsorbService.tryAbsorb(session, nil, NOW)).toBe("BadArgument")
		expect(AbsorbService.tryAbsorb(session, {}, NOW)).toBe("BadArgument")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("evaluates requests 1 to 10 in one second and refuses request 11", function()
		local session = newSession()
		for index = 1, 10 do
			expect(AbsorbService.tryAbsorb(session, "T9-99", NOW + index * 0.05)).toBe(
				"UnknownObject"
			)
		end
		expect(AbsorbService.tryAbsorb(session, "T9-99", NOW + 0.5)).toBe("RateLimited")
	end)
end)

describe("AbsorbService boundary and growth", function()
	beforeAll(function()
		WorldSpawner.start()
		-- No ball watches a spot during the specs, so a due object always returns.
		WorldSpawner.setWatcherSource(function()
			return {}
		end)
	end)
	beforeEach(function()
		WorldSpawner.reset()
	end)
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("accepts an object exactly at 0.4 times the diameter", function()
		local session = newSession()
		session.authoritativeDiameter = 0.8 / 0.4
		placeOn(session, bauble)
		expect(AbsorbService.tryAbsorb(session, bauble, NOW)).toBe("Ok")
	end)

	it("rejects an object larger than 0.4 times the diameter by 1e-4", function()
		local session = newSession()
		session.authoritativeDiameter = (0.8 - 1e-4) / 0.4
		placeOn(session, bauble)
		expect(AbsorbService.tryAbsorb(session, bauble, NOW)).toBe("TooBig")
	end)

	it("grows the diameter by volume and writes the Diameter and Stuck attributes", function()
		local session = newSession()
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], NOW)).toBe("Ok")
		-- One acorn (0.5) at k = 1.5: D^3 = 8 + 1.5 * 0.125 = 8.1875, D = 2.0155.
		local grown = Growth.growDiameter(2, ACORN, Worlds.growthK)
		expect(session.authoritativeDiameter).toBeCloseTo(2.0155, 3)
		expect(session.authoritativeDiameter).toBeCloseTo(grown, 6)
		expect(session.part:GetAttribute("Diameter")).toBeCloseTo(2.0155, 3)
		local stuck = session.part:GetAttribute("Stuck")
		expect(typeof(stuck)).toBe("string")
		local at = string.find(stuck :: string, small[1] .. "#", 1, true)
		expect(at).toBe(1)
	end)

	it("does not mutate state for a rejected request", function()
		local session = newSession()
		placeOn(session, duck)
		AbsorbService.tryAbsorb(session, duck, NOW)
		expect(#session.stuckStack).toBe(0)
		expect(objectState(duck)).toBe("Available")
	end)

	it("gives a contested object to the first request only", function()
		local first = newSession()
		local second = newSession()
		placeOn(first, small[2])
		placeOn(second, small[2])
		expect(AbsorbService.tryAbsorb(first, small[2], NOW)).toBe("Ok")
		expect(AbsorbService.tryAbsorb(second, small[2], NOW + 0.01)).toBe("AlreadyTaken")
		expect(#second.stuckStack).toBe(0)
	end)
end)

describe("AbsorbService knock-off", function()
	beforeAll(function()
		WorldSpawner.start()
		-- No ball watches a spot during the specs, so a due object always returns.
		WorldSpawner.setWatcherSource(function()
			return {}
		end)
	end)
	beforeEach(function()
		WorldSpawner.reset()
	end)
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("pops exactly 3 of a stack of 5, scatters them, and shrinks the diameter", function()
		local session = newSession()
		local ids = { small[1], small[2], small[3], small[4], small[5] }
		for index, id in ids do
			placeOn(session, id)
			expect(AbsorbService.tryAbsorb(session, id, NOW + index * 0.1)).toBe("Ok")
		end
		expect(#session.stuckStack).toBe(5)
		local grownDiameter = session.authoritativeDiameter

		local bumpTime = NOW + 2
		session.speedSamples = { { t = bumpTime, speed = 20 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, bumpTime)).toBe("Ok")

		expect(#session.stuckStack).toBe(2)
		expect(session.authoritativeDiameter).toBeLessThan(grownDiameter)
		expect(session.authoritativeDiameter).toBeGreaterThanOrEqual(Config.startDiameter)
		expect(objectState(small[5])).toBe("Scattered")
		expect(objectState(small[3])).toBe("Scattered")

		WorldSpawner.update(bumpTime + Config.scatterGrace)
		expect(objectState(small[5])).toBe("Available")
	end)

	it("scatters only the popped objects still waiting to respawn from those pickups", function()
		local session = newSession()
		for index, id in { small[1], small[2], small[3] } do
			placeOn(session, id)
			expect(AbsorbService.tryAbsorb(session, id, NOW + index * 0.1)).toBe("Ok")
		end
		-- All three respawn by NOW + 0.3 + 120 at the latest; their records stay on the ball.
		local later = NOW + Config.respawnDelayMax + 1
		WorldSpawner.update(later)
		expect(objectState(small[2])).toBe("Available")
		expect(objectState(small[3])).toBe("Available")
		placeOn(session, small[4])
		expect(AbsorbService.tryAbsorb(session, small[4], later + 0.5)).toBe("Ok")
		expect(#session.stuckStack).toBe(4)

		local bumpTime = later + 1
		session.speedSamples = { { t = bumpTime, speed = 20 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, bumpTime)).toBe("Ok")

		-- Popped: the 2nd, 3rd and 4th acorn. Only the 4th is still pending, so only it lands on the floor.
		expect(#session.stuckStack).toBe(1)
		expect(objectState(small[4])).toBe("Scattered")
		local t102 = WorldSpawner.getObject(small[2])
		local t103 = WorldSpawner.getObject(small[3])
		assert(t102 and t103, "missing objects")
		expect(t102.state).toBe("Available")
		expect(t102.part.CFrame == t102.spawnCFrame).toBe(true)
		expect(t103.part.CFrame == t103.spawnCFrame).toBe(true)
		-- One acorn (0.5) left, k = 1.5: D^3 = 8 + 1.5 * 0.125 = 8.1875, D = 2.0155.
		expect(session.authoritativeDiameter).toBeCloseTo(2.0155, 3)
	end)

	it("is a no-op with an empty stack", function()
		local session = newSession()
		local bumpTime = NOW + 2
		session.speedSamples = { { t = bumpTime, speed = 20 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, bumpTime)).toBe("Ok")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("rejects a slow hit as not a knock-off", function()
		local session = newSession()
		local bumpTime = NOW + 2
		session.speedSamples = { { t = bumpTime, speed = 5 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, bumpTime)).toBe("NotAKnockOff")
	end)
end)

describe("Registry invariant and ball lifecycle", function()
	beforeAll(function()
		WorldSpawner.start()
		-- No ball watches a spot during the specs, so a due object always returns.
		WorldSpawner.setWatcherSource(function()
			return {}
		end)
	end)
	beforeEach(function()
		WorldSpawner.reset()
	end)
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it(
		"keeps free + pending equal to the pool size across absorbs, a knock-off, a respawn, a refill and a leave",
		function()
			local first = newSession()
			local second = newSession()
			for index, id in { small[1], small[2], small[3] } do
				placeOn(first, id)
				AbsorbService.tryAbsorb(first, id, NOW + index * 0.1)
			end
			placeOn(second, small[4])
			AbsorbService.tryAbsorb(second, small[4], NOW + 1)

			local function total(): number
				local counts = WorldSpawner.registryCounts()
				return counts.free + counts.pendingRespawn
			end
			expect(total()).toBe(#Worlds.placements)
			expect(WorldSpawner.registryCounts().pendingRespawn).toBe(4)

			first.speedSamples = { { t = NOW + 2, speed = 20 } }
			placeOn(first, duck)
			AbsorbService.tryBump(first, duck, NOW + 2)
			expect(total()).toBe(#Worlds.placements)

			-- The knock-off scattered first's three objects; the 4th acorn is still in second's stack and
			-- respawns on its timer anyway: the room refills while the record stays on the ball.
			expect(WorldSpawner.registryCounts().pendingRespawn).toBe(1)
			WorldSpawner.update(NOW + 1 + Config.respawnDelayMax)
			expect(objectState(small[4])).toBe("Available")
			expect(#second.stuckStack).toBe(1)
			expect(WorldSpawner.registryCounts().pendingRespawn).toBe(0)
			expect(total()).toBe(#Worlds.placements)

			-- Reset with a record whose object already respawned: nothing moves, the stack empties.
			AbsorbService.tryRespawn(second, NOW + 20)
			expect(#second.stuckStack).toBe(0)
			local t104 = WorldSpawner.getObject(small[4])
			assert(t104, "missing fourth acorn")
			expect(t104.part.CFrame == t104.spawnCFrame).toBe(true)
			expect(total()).toBe(#Worlds.placements)

			BallService.removeSession(second)
			table.remove(created, table.find(created, second) or 1)
			expect(total()).toBe(#Worlds.placements)
		end
	)

	it("respawns a held object at its random delay and records it again under a new key", function()
		local session = newSession()
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], NOW)).toBe("Ok")
		local pooled = WorldSpawner.getObject(small[1])
		assert(pooled and pooled.respawnAt, "missing respawn time")
		local delay = pooled.respawnAt - NOW
		expect(delay).toBeGreaterThanOrEqual(Config.respawnDelayMin)
		expect(delay).toBeLessThanOrEqual(Config.respawnDelayMax)
		local sameInstance = pooled.part
		WorldSpawner.update(pooled.respawnAt - 0.01)
		expect(objectState(small[1])).toBe("Taken")
		WorldSpawner.update(pooled.respawnAt)
		expect(objectState(small[1])).toBe("Available")
		expect(pooled.part).toBe(sameInstance)
		expect(#session.stuckStack).toBe(1)

		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], NOW + Config.respawnDelayMax + 1)).toBe(
			"Ok"
		)
		expect(#session.stuckStack).toBe(2)
		local first, second = session.stuckStack[1], session.stuckStack[2]
		expect(first.id).toBe(small[1])
		expect(second.id).toBe(small[1])
		expect(first.key).never.toBe(second.key)
		local stuck = session.part:GetAttribute("Stuck") :: string
		expect(#string.split(stuck, ";")).toBe(2)
	end)

	it("respawn returns the diameter to 2 and empties the stack", function()
		local session = newSession()
		placeOn(session, small[1])
		AbsorbService.tryAbsorb(session, small[1], NOW)
		expect(AbsorbService.tryRespawn(session, NOW + 10)).toBe("Ok")
		expect(session.authoritativeDiameter).toBe(2)
		expect(#session.stuckStack).toBe(0)
	end)

	it("corrects a speed violation and counts it", function()
		local session = newSession()
		session.part.AssemblyLinearVelocity = Vector3.new(100, 0, 0)
		BallService.step(NOW, 1 / 60)
		local horizontal = Vector3.new(
			session.part.AssemblyLinearVelocity.X,
			0,
			session.part.AssemblyLinearVelocity.Z
		)
		expect(horizontal.Magnitude).toBeLessThanOrEqual(Config.maxServerBallSpeed + 1e-6)
		expect(session.violations).toBe(1)
	end)
end)
