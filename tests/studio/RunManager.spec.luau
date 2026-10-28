--!strict
-- Server run authority (Constitution II, FR-024). Expected values are hand-computed from
-- contracts/rules-api.md, contracts/remotes.md and data-model.md, never from the code under test.
-- Time is injected. It starts at os.clock() so the live Heartbeat step in Play mode never ends a test run.

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
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local AbsorbService = require(ServerScriptService.AbsorbService)
local BallService = require(ServerScriptService.BallService)
local RunManager = require(ServerScriptService.RunManager)
local WorldSpawner = require(ServerScriptService.WorldSpawner)
local Fixtures = require(script.Parent.Fixtures)

-- Fixture placements picked by object type: acorns (0.5) are eatable from the start, baubles (0.8) are the
-- biggest object eatable at the start diameter, a duck and a yard object are too big for a ball of 2 to eat.
local small = Fixtures.ids("acorn", 12)
local baubles = Fixtures.ids("bauble", 4)
local duck = Fixtures.ofTier(2)
local yardObject = Fixtures.ofTier(3)

local created: { BallService.Session } = {}
local nextUserId = 800000
local published: { { userId: number, result: RunManager.RunResult } } = {}

local function newSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId, nil)
	table.insert(created, session)
	return session
end

local function startRun(session: BallService.Session, now: number): RunManager.RunSession
	return RunManager.startRun(session.ownerUserId, nil, now)
end

local function placeOn(session: BallService.Session, objectId: string)
	local object = WorldSpawner.getObject(objectId)
	assert(object, `missing object {objectId}`)
	session.part.Position = object.part.Position + Vector3.yAxis
end

local function eat(session: BallService.Session, objectId: string, now: number): string
	placeOn(session, objectId)
	return AbsorbService.tryAbsorb(session, objectId, now)
end

local function getRun(session: BallService.Session): RunManager.RunSession
	local run = RunManager.getRun(session.ownerUserId)
	assert(run, "no run")
	return run
end

local function setup()
	beforeAll(function()
		WorldSpawner.start()
		-- No ball watches a spot during the specs, so a due object always returns.
		WorldSpawner.setWatcherSource(function()
			return {}
		end)
	end)
	beforeEach(function()
		WorldSpawner.reset()
		table.clear(published)
		RunManager.setPublisher(function(userId: number, result: RunManager.RunResult)
			table.insert(published, { userId = userId, result = result })
		end)
	end)
	afterEach(function()
		for _, session in created do
			RunManager.discard(session.ownerUserId)
			BallService.removeSession(session)
		end
		table.clear(created)
		RunManager.setPublisher(nil)
	end)
end

describe("RunManager run clock", function()
	setup()

	it("starts a run with a unique runId and endsAt = now + 240", function()
		local now = os.clock()
		local first = newSession()
		local second = newSession()
		local runA = startRun(first, now)
		local runB = startRun(second, now)
		expect(runA.endsAt).toBe(now + 240)
		expect(runA.state).toBe("Active")
		expect(runA.runId).never.toBe(runB.runId)
	end)

	it("accepts pickups at endsAt - 0.001 and rejects them at endsAt", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		expect(RunManager.acceptsPickups(session.ownerUserId, run.endsAt - 0.001)).toBe(true)
		expect(RunManager.acceptsPickups(session.ownerUserId, run.endsAt)).toBe(false)
	end)

	it("publishes exactly one result at 240 s and none for the same run later", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		RunManager.step(now + 239.9)
		expect(#published).toBe(0)
		RunManager.step(now + 240)
		expect(#published).toBe(1)
		RunManager.step(now + 340)
		expect(#published).toBe(1)
		expect(getRun(session).state).toBe("Ended")
		expect(session.frozen).toBe(true)
	end)

	it("builds the result from the server's own numbers", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		expect(eat(session, small[1], now + 1)).toBe("Ok")
		expect(eat(session, small[2], now + 2)).toBe("Ok")
		RunManager.step(now + 240)
		local result = published[1].result
		expect(published[1].userId).toBe(session.ownerUserId)
		expect(result.runId).toBe(run.runId)
		expect(result.worldId).toBe("snow_village")
		-- Two acorns (0.5), k = 1.5: D^3 = 8 + 2 * 1.5 * 0.125 = 8.375, D = 8.375^(1/3) = 2.0308.
		expect(result.finalDiameter).toBeCloseTo(2.0308, 3)
		expect(result.stars).toBe(0)
		expect(result.coins).toBe(2)
		expect(result.newBookIds).toEqual({ "snow_village.acorn" })
		expect(result.bestSelfSize).toBe(result.finalDiameter)
		expect(result.bestFriendSize).toBe(nil)
	end)

	it("gives one star at exactly the first star target using the world's targets", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		BallService.setDiameter(session, Worlds.starThresholds[1])
		RunManager.step(now + 240)
		expect(published[1].result.stars).toBe(1)
	end)

	it("rejects absorbs after the bell and changes nothing", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		RunManager.step(run.endsAt)
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], run.endsAt + 1)).toBe("RunEnded")
		expect(session.authoritativeDiameter).toBe(2)
		expect(#session.stuckStack).toBe(0)
		expect(#run.absorbedCoinValues).toBe(0)
	end)

	it("rejects a bump at the bell", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		session.speedSamples = { { t = run.endsAt, speed = 20 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, run.endsAt)).toBe("RunEnded")
	end)

	it("does not publish when the player leaves mid-run", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		RunManager.discard(session.ownerUserId)
		RunManager.step(now + 240)
		expect(#published).toBe(0)
		expect(RunManager.getRun(session.ownerUserId)).toBe(nil)
	end)
end)

describe("RunManager intents", function()
	setup()

	it("ignores RollAgain and BackToHub while Active", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		expect(RunManager.handleRollAgain(session.ownerUserId, now + 1)).toBe("WrongState")
		expect(RunManager.handleBackToHub(session.ownerUserId, now + 1)).toBe("WrongState")
		expect(getRun(session)).toBe(run)
		expect(run.state).toBe("Active")
	end)

	it("ignores an extra or wrong argument", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		RunManager.step(run.endsAt)
		expect(RunManager.handleRollAgain(session.ownerUserId, run.endsAt + 1, 5)).toBe(
			"BadArgument"
		)
		expect(RunManager.handleRollAgain(session.ownerUserId, run.endsAt + 1, nil)).toBe(
			"BadArgument"
		)
		expect(RunManager.handleBackToHub(session.ownerUserId, run.endsAt + 1, "hub")).toBe(
			"BadArgument"
		)
		expect(getRun(session).state).toBe("Ended")
		expect(getRun(session).runId).toBe(run.runId)
	end)

	it("ignores a request from a player with no run", function()
		expect(RunManager.handleRollAgain(123456789, os.clock())).toBe("NoRun")
		expect(RunManager.handleBackToHub(123456789, os.clock())).toBe("NoRun")
	end)

	it("starts a new run with RollAgain after the bell and ignores a second tap", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		expect(eat(session, small[1], now + 1)).toBe("Ok")
		RunManager.step(run.endsAt)
		local restartAt = run.endsAt + 1
		expect(RunManager.handleRollAgain(session.ownerUserId, restartAt)).toBe("Ok")
		local next = getRun(session)
		expect(next.runId).never.toBe(run.runId)
		expect(next.state).toBe("Active")
		expect(next.startedAt - run.endsAt).toBeLessThanOrEqual(Config.rollAgainDelaySeconds)
		expect(next.endsAt).toBe(restartAt + 240)
		expect(session.authoritativeDiameter).toBe(Config.startDiameter)
		expect(#session.stuckStack).toBe(0)
		expect(session.frozen).toBe(false)
		expect(session.zone).toBe("Room")
		expect(RunManager.handleRollAgain(session.ownerUserId, restartAt + 0.1)).toBe("WrongState")
		expect(getRun(session)).toBe(next)
	end)

	it("moves BackToHub to the Hub zone and rejects absorbing there", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		RunManager.step(run.endsAt)
		expect(RunManager.handleBackToHub(session.ownerUserId, run.endsAt + 1)).toBe("Ok")
		expect(session.zone).toBe("Hub")
		expect(getRun(session).state).toBe("Hub")
		expect(session.frozen).toBe(false)
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], run.endsAt + 2)).toBe("RunEnded")
		expect(RunManager.handleBackToHub(session.ownerUserId, run.endsAt + 3)).toBe("WrongState")
	end)

	it("starts a run from the Hub with RollAgain", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		RunManager.step(run.endsAt)
		RunManager.handleBackToHub(session.ownerUserId, run.endsAt + 1)
		local hubRunId = getRun(session).runId
		expect(RunManager.handleRollAgain(session.ownerUserId, run.endsAt + 5)).toBe("Ok")
		expect(getRun(session).runId).never.toBe(hubRunId)
		expect(getRun(session).state).toBe("Active")
		expect(session.zone).toBe("Room")
	end)

	it("gives three consecutive runs distinct runIds", function()
		local now = os.clock()
		local session = newSession()
		local ids: { [string]: boolean } = {}
		local at = now
		startRun(session, at)
		for _ = 1, 3 do
			local run = getRun(session)
			expect(ids[run.runId]).toBe(nil)
			ids[run.runId] = true
			RunManager.step(run.endsAt)
			at = run.endsAt + 1
			RunManager.handleRollAgain(session.ownerUserId, at)
		end
		expect(#published).toBe(3)
	end)
end)

describe("RunManager falls and Reset", function()
	setup()

	it("keeps size, stack and runId when the ball falls mid-run", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		expect(eat(session, small[1], now + 1)).toBe("Ok")
		local diameter = session.authoritativeDiameter
		session.part.Position = Vector3.new(0, Config.fallRespawnY - 10, 0)
		BallService.step(now + 2, 1 / 60)
		expect(session.part.Position.Y).toBeGreaterThan(Config.fallRespawnY)
		expect(session.authoritativeDiameter).toBe(diameter)
		expect(#session.stuckStack).toBe(1)
		expect(getRun(session).runId).toBe(run.runId)
		expect(getRun(session).state).toBe("Active")
	end)

	it("returns to spawn on Reset during a run without losing size", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		expect(eat(session, small[1], now + 1)).toBe("Ok")
		local diameter = session.authoritativeDiameter
		expect(AbsorbService.tryRespawn(session, now + 10)).toBe("Ok")
		expect(session.authoritativeDiameter).toBe(diameter)
		expect(#session.stuckStack).toBe(1)
	end)

	it("rejects Reset after the bell", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		RunManager.step(run.endsAt)
		expect(AbsorbService.tryRespawn(session, run.endsAt + 10)).toBe("RunEnded")
	end)
end)

describe("RunManager events", function()
	setup()

	local events: { { name: string, payload: unknown } } = {}

	beforeEach(function()
		table.clear(events)
		RunManager.setEventSink(function(_userId: number, name: string, payload: unknown)
			table.insert(events, { name = name, payload = payload })
		end)
	end)
	afterEach(function()
		RunManager.setEventSink(nil)
	end)

	local function names(): { string }
		local list = {}
		for _, event in events do
			table.insert(list, event.name)
		end
		return list
	end

	it("emits PickupConfirmed with the object id for a validated pickup", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		expect(eat(session, small[1], now + 1)).toBe("Ok")
		expect(names()).toEqual({ "PickupConfirmed" })
		expect(events[1].payload).toBe("acorn")
	end)

	it("emits TierUnlocked(2) once when growth crosses 5", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		-- D = 4.99 plus one bauble (0.8), k = 1.5: (124.2515 + 0.768)^(1/3) = 5.0003, past 5.
		BallService.setDiameter(session, 4.99)
		expect(eat(session, baubles[1], now + 1)).toBe("Ok")
		expect(names()).toEqual({ "PickupConfirmed", "TierUnlocked" })
		expect(events[2].payload).toBe(2)
		expect(eat(session, baubles[2], now + 2)).toBe("Ok")
		expect(names()).toEqual({ "PickupConfirmed", "TierUnlocked", "PickupConfirmed" })
	end)

	it("emits no second TierUnlocked after a knock-off and regrowth", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		BallService.setDiameter(session, 4.99)
		expect(eat(session, baubles[1], now + 1)).toBe("Ok")
		expect(getRun(session).unlockedTiers[2]).toBe(true)
		-- Knock off, drop below 5, then grow back across it. At D 5.0003 a duck (1.6) is absorbable, so
		-- the knock-off needs a yard object (4.2).
		session.speedSamples = { { t = now + 3, speed = 20 } }
		placeOn(session, yardObject)
		expect(AbsorbService.tryBump(session, yardObject, now + 3)).toBe("Ok")
		BallService.setDiameter(session, 4.99)
		table.clear(events)
		expect(eat(session, baubles[2], now + 5)).toBe("Ok")
		expect(session.authoritativeDiameter).toBeGreaterThan(5)
		expect(names()).toEqual({ "PickupConfirmed" })
	end)

	it(
		"emits one TierUnlocked for the highest tier crossed and unlocks the lower ones silently",
		function()
			local now = os.clock()
			local session = newSession()
			startRun(session, now)
			BallService.setDiameter(session, 12.5)
			RunManager.onPickup(session.ownerUserId, Fixtures.firstOfTier(1), now + 1)
			expect(names()).toEqual({ "PickupConfirmed", "TierUnlocked" })
			expect(events[2].payload).toBe(3)
			expect(getRun(session).unlockedTiers[2]).toBe(true)
			expect(getRun(session).unlockedTiers[3]).toBe(true)
		end
	)

	it("emits KnockedOff only when an entry popped, and keeps every coin", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		session.speedSamples = { { t = now + 1, speed = 20 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, now + 1)).toBe("Ok")
		expect(#events).toBe(0)

		for index, id in { small[1], small[2], small[3] } do
			expect(eat(session, id, now + 2 + index * 0.2)).toBe("Ok")
		end
		table.clear(events)
		session.speedSamples = { { t = now + 5, speed = 20 } }
		placeOn(session, duck)
		expect(AbsorbService.tryBump(session, duck, now + 5)).toBe("Ok")
		expect(names()).toEqual({ "KnockedOff" })
		expect(#session.stuckStack).toBe(0)
		expect(#run.absorbedCoinValues).toBe(3)

		RunManager.step(run.endsAt)
		expect(published[1].result.coins).toBe(3)
	end)

	it("emits nothing after the bell", function()
		local now = os.clock()
		local session = newSession()
		local run = startRun(session, now)
		RunManager.step(run.endsAt)
		placeOn(session, small[1])
		expect(AbsorbService.tryAbsorb(session, small[1], run.endsAt + 1)).toBe("RunEnded")
		session.speedSamples = { { t = run.endsAt + 1, speed = 20 } }
		expect(AbsorbService.tryBump(session, duck, run.endsAt + 1)).toBe("RunEnded")
		expect(#events).toBe(0)
	end)
end)

describe("RunManager with profile", function()
	setup()

	it("published result carries coinsTotal and isFirstRun when profile loaded", function()
		local DataService = require(ServerScriptService.DataService)
		local ProfileStore =
			require(ServerScriptService.ServerPackages:WaitForChild("ProfileStore"))
		DataService.setStore(ProfileStore.New("test").Mock)
		local uid = newSession().ownerUserId
		-- load profile for this user via a fake player
		local Players = game:GetService("Players")
		local player = { Parent = Players, LocaleId = "en-us", UserId = uid } :: any
		DataService.load(uid, player)

		local now = os.clock()
		-- need a session owned by uid; reuse newSession? owner differs. Use RunManager.startRun directly
		local session = BallService.newSession(uid, nil)
		table.insert(created, session)
		RunManager.startRun(uid, nil, now)
		expect(eat(session, small[1], now + 1)).toBe("Ok")
		RunManager.step(now + 240)
		expect(#published).toBe(1)
		local result = published[1].result
		expect(result.coinsTotal).never.toBe(nil)
		expect(result.isFirstRun).toBe(true)
		BallService.removeSession(session)
		DataService.release(uid)
	end)

	it("user with no profile gets 002 behaviour", function()
		local now = os.clock()
		local session = newSession()
		startRun(session, now)
		RunManager.step(now + 240)
		local result = published[#published].result
		expect(result.coinsTotal).toBe(nil)
		expect(result.isFirstRun).toBe(false)
	end)
end)
