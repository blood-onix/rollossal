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
local AbsorbService = require(ServerScriptService.AbsorbService)
local BallService = require(ServerScriptService.BallService)
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local NOW = 1000
local created: { BallService.Session } = {}
local nextUserId = 900000

local function newSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId)
	table.insert(created, session)
	return session
end

local function placeOn(session: BallService.Session, cubeId: string)
	local cube = WorldSpawner.getCube(cubeId)
	assert(cube, `missing cube {cubeId}`)
	session.part.Position = cube.part.Position + Vector3.yAxis
end

local function cubeState(cubeId: string): string
	local cube = WorldSpawner.getCube(cubeId)
	assert(cube, `missing cube {cubeId}`)
	return cube.state
end

describe("AbsorbService rejections", function()
	beforeAll(function()
		WorldSpawner.start()
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

	it("rejects an already taken cube", function()
		local session = newSession()
		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW)).toBe("Ok")
		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW + 1)).toBe("AlreadyTaken")
	end)

	it("rejects a cube out of range", function()
		local session = newSession()
		session.part.Position = Vector3.new(30, 1, 30)
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW)).toBe("OutOfRange")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("rejects a cube too big for the current diameter", function()
		local session = newSession()
		placeOn(session, "T2-01")
		expect(AbsorbService.tryAbsorb(session, "T2-01", NOW)).toBe("TooBig")
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

	it("accepts a cube exactly at 0.4 times the diameter", function()
		local session = newSession()
		session.authoritativeDiameter = 0.75 / 0.4
		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW)).toBe("Ok")
	end)

	it("rejects a cube larger than 0.4 times the diameter by 1e-4", function()
		local session = newSession()
		session.authoritativeDiameter = (0.75 - 1e-4) / 0.4
		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW)).toBe("TooBig")
	end)

	it("grows the diameter by volume and writes the Diameter and Stuck attributes", function()
		local session = newSession()
		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW)).toBe("Ok")
		expect(session.authoritativeDiameter).toBeCloseTo(2.0209, 3)
		expect(session.part:GetAttribute("Diameter")).toBeCloseTo(2.0209, 3)
		local stuck = session.part:GetAttribute("Stuck")
		expect(typeof(stuck)).toBe("string")
		expect(string.find(stuck :: string, "^T1%-01#%d+,") ~= nil).toBe(true)
	end)

	it("does not mutate state for a rejected request", function()
		local session = newSession()
		placeOn(session, "T2-01")
		AbsorbService.tryAbsorb(session, "T2-01", NOW)
		expect(#session.stuckStack).toBe(0)
		expect(cubeState("T2-01")).toBe("Available")
	end)

	it("gives a contested cube to the first request only", function()
		local first = newSession()
		local second = newSession()
		placeOn(first, "T1-02")
		placeOn(second, "T1-02")
		expect(AbsorbService.tryAbsorb(first, "T1-02", NOW)).toBe("Ok")
		expect(AbsorbService.tryAbsorb(second, "T1-02", NOW + 0.01)).toBe("AlreadyTaken")
		expect(#second.stuckStack).toBe(0)
	end)
end)

describe("AbsorbService knock-off", function()
	beforeAll(function()
		WorldSpawner.start()
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
		local ids = { "T1-01", "T1-02", "T1-03", "T1-04", "T1-05" }
		for index, id in ids do
			placeOn(session, id)
			expect(AbsorbService.tryAbsorb(session, id, NOW + index * 0.1)).toBe("Ok")
		end
		expect(#session.stuckStack).toBe(5)
		local grownDiameter = session.authoritativeDiameter

		local bumpTime = NOW + 2
		session.speedSamples = { { t = bumpTime, speed = 20 } }
		placeOn(session, "T2-01")
		expect(AbsorbService.tryBump(session, "T2-01", bumpTime)).toBe("Ok")

		expect(#session.stuckStack).toBe(2)
		expect(session.authoritativeDiameter).toBeLessThan(grownDiameter)
		expect(session.authoritativeDiameter).toBeGreaterThanOrEqual(Config.startDiameter)
		expect(cubeState("T1-05")).toBe("Scattered")
		expect(cubeState("T1-03")).toBe("Scattered")

		WorldSpawner.update(bumpTime + Config.scatterGrace)
		expect(cubeState("T1-05")).toBe("Available")
	end)

	it("scatters only the popped cubes still waiting to respawn from those pickups", function()
		local session = newSession()
		for index, id in { "T1-01", "T1-02", "T1-03" } do
			placeOn(session, id)
			expect(AbsorbService.tryAbsorb(session, id, NOW + index * 0.1)).toBe("Ok")
		end
		-- All three respawn at NOW + 0.3 + 15 at the latest; their records stay on the ball.
		local later = NOW + Config.respawnDelay + 1
		WorldSpawner.update(later)
		expect(cubeState("T1-02")).toBe("Available")
		expect(cubeState("T1-03")).toBe("Available")
		placeOn(session, "T1-04")
		expect(AbsorbService.tryAbsorb(session, "T1-04", later + 0.5)).toBe("Ok")
		expect(#session.stuckStack).toBe(4)

		local bumpTime = later + 1
		session.speedSamples = { { t = bumpTime, speed = 20 } }
		placeOn(session, "T2-01")
		expect(AbsorbService.tryBump(session, "T2-01", bumpTime)).toBe("Ok")

		-- Popped: T1-02, T1-03, T1-04. Only T1-04 is still pending, so only it lands on the floor.
		expect(#session.stuckStack).toBe(1)
		expect(cubeState("T1-04")).toBe("Scattered")
		local t102 = WorldSpawner.getCube("T1-02")
		local t103 = WorldSpawner.getCube("T1-03")
		assert(t102 and t103, "missing cubes")
		expect(t102.state).toBe("Available")
		expect(t102.part.CFrame == t102.spawnCFrame).toBe(true)
		expect(t103.part.CFrame == t103.spawnCFrame).toBe(true)
		-- One entry of 0.75 left: D³ = 8 + 0.6 · 0.421875 = 8.253125, D ≈ 2.0209.
		expect(session.authoritativeDiameter).toBeCloseTo(2.0209, 3)
	end)

	it("is a no-op with an empty stack", function()
		local session = newSession()
		local bumpTime = NOW + 2
		session.speedSamples = { { t = bumpTime, speed = 20 } }
		placeOn(session, "T2-01")
		expect(AbsorbService.tryBump(session, "T2-01", bumpTime)).toBe("Ok")
		expect(session.authoritativeDiameter).toBe(2)
	end)

	it("rejects a slow hit as not a knock-off", function()
		local session = newSession()
		local bumpTime = NOW + 2
		session.speedSamples = { { t = bumpTime, speed = 5 } }
		placeOn(session, "T2-01")
		expect(AbsorbService.tryBump(session, "T2-01", bumpTime)).toBe("NotAKnockOff")
	end)
end)

describe("Registry invariant and ball lifecycle", function()
	beforeAll(function()
		WorldSpawner.start()
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
		"keeps free + pending equal to 30 across absorbs, a knock-off, a respawn, a refill and a leave",
		function()
			local first = newSession()
			local second = newSession()
			for index, id in { "T1-01", "T1-02", "T1-03" } do
				placeOn(first, id)
				AbsorbService.tryAbsorb(first, id, NOW + index * 0.1)
			end
			placeOn(second, "T1-04")
			AbsorbService.tryAbsorb(second, "T1-04", NOW + 1)

			local function total(): number
				local counts = WorldSpawner.registryCounts()
				return counts.free + counts.pendingRespawn
			end
			expect(total()).toBe(30)
			expect(WorldSpawner.registryCounts().pendingRespawn).toBe(4)

			first.speedSamples = { { t = NOW + 2, speed = 20 } }
			placeOn(first, "T2-01")
			AbsorbService.tryBump(first, "T2-01", NOW + 2)
			expect(total()).toBe(30)

			-- The knock-off scattered first's three cubes; T1-04 is still in second's stack and
			-- respawns on its timer anyway: the room refills while the record stays on the ball.
			expect(WorldSpawner.registryCounts().pendingRespawn).toBe(1)
			WorldSpawner.update(NOW + 1 + Config.respawnDelay)
			expect(cubeState("T1-04")).toBe("Available")
			expect(#second.stuckStack).toBe(1)
			expect(WorldSpawner.registryCounts().pendingRespawn).toBe(0)
			expect(total()).toBe(30)

			-- Reset with a record whose cube already respawned: nothing moves, the stack empties.
			AbsorbService.tryRespawn(second, NOW + 20)
			expect(#second.stuckStack).toBe(0)
			local t104 = WorldSpawner.getCube("T1-04")
			assert(t104, "missing T1-04")
			expect(t104.part.CFrame == t104.spawnCFrame).toBe(true)
			expect(total()).toBe(30)

			BallService.removeSession(second)
			table.remove(created, table.find(created, second) or 1)
			expect(total()).toBe(30)
		end
	)

	it("respawns a held cube after respawnDelay and records it again under a new key", function()
		local session = newSession()
		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW)).toBe("Ok")
		WorldSpawner.update(NOW + Config.respawnDelay - 0.01)
		expect(cubeState("T1-01")).toBe("Taken")
		WorldSpawner.update(NOW + Config.respawnDelay)
		expect(cubeState("T1-01")).toBe("Available")
		expect(#session.stuckStack).toBe(1)

		placeOn(session, "T1-01")
		expect(AbsorbService.tryAbsorb(session, "T1-01", NOW + Config.respawnDelay + 1)).toBe("Ok")
		expect(#session.stuckStack).toBe(2)
		local first, second = session.stuckStack[1], session.stuckStack[2]
		expect(first.id).toBe("T1-01")
		expect(second.id).toBe("T1-01")
		expect(first.key).never.toBe(second.key)
		local stuck = session.part:GetAttribute("Stuck") :: string
		expect(#string.split(stuck, ";")).toBe(2)
	end)

	it("respawn returns the diameter to 2 and empties the stack", function()
		local session = newSession()
		placeOn(session, "T1-01")
		AbsorbService.tryAbsorb(session, "T1-01", NOW)
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
