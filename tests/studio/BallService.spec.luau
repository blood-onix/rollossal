--!strict
-- Server vertical movement guard (006, research R-03). Expected values are hand-computed for a ball of
-- diameter 2: take-off speed 25.06, upLimit 31.33, apex allowance (2.267 + 1) * 1.25 = 4.083 above the ground
-- reference. The ball hangs at Y = 5000, far above any ground, so the server's ground probe finds nothing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local afterEach = JestGlobals.afterEach

local Config = require(ReplicatedStorage.Shared.Config)
local BallService = require(game:GetService("ServerScriptService").BallService)

local HEIGHT = 5000
local DT = 1 / 60
local NOW = 1000

local created: { BallService.Session } = {}
local nextUserId = 910000

local function airborneSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId)
	table.insert(created, session)
	session.part.Anchored = false
	session.part.Position = Vector3.new(0, HEIGHT, 0)
	session.lastValidPosition = session.part.Position
	-- The reference energy the last grounded step would have stored: standing at Y = 5000.
	session.airRefEnergy = HEIGHT
	return session
end

describe("BallService vertical guard", function()
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("accepts a legitimate take-off speed in the air", function()
		local session = airborneSession()
		session.part.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
		BallService.step(NOW, DT)
		expect(session.violations).toBe(0)
		expect(session.part.AssemblyLinearVelocity.Y).toBe(25)
	end)

	it("accepts a held jump near its apex", function()
		local session = airborneSession()
		-- 2.2 studs up at a slow rise: E = 2.2 + 0.2 = 2.4, inside the 4.083 allowance.
		session.part.Position = Vector3.new(0, HEIGHT + 2.2, 0)
		session.lastValidPosition = session.part.Position
		session.part.AssemblyLinearVelocity = Vector3.new(0, 6, 0)
		BallService.step(NOW, DT)
		expect(session.violations).toBe(0)
	end)

	it(
		"stops a mid-air re-jump: the rise is cancelled and a Vertical violation is logged",
		function()
			local session = airborneSession()
			-- 4 studs up and a full take-off speed again: E = 4 + 1.6 = 5.6 > 4.083.
			session.part.Position = Vector3.new(0, HEIGHT + 4, 0)
			session.lastValidPosition = session.part.Position
			session.part.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
			BallService.step(NOW, DT)
			expect(session.violations).toBe(1)
			expect(session.violationLog[1].kind).toBe("Vertical")
			expect(session.part.AssemblyLinearVelocity.Y <= 0).toBe(true)
		end
	)

	it("stops an upward speed over the limit", function()
		local session = airborneSession()
		session.part.AssemblyLinearVelocity = Vector3.new(0, 60, 0)
		BallService.step(NOW, DT)
		expect(session.violations).toBe(1)
		expect(session.violationLog[1].kind).toBe("Vertical")
		expect(session.part.AssemblyLinearVelocity.Y <= 0).toBe(true)
	end)

	it("resets a vertical teleport to the last valid position", function()
		local session = airborneSession()
		session.part.Position = Vector3.new(0, HEIGHT + 300, 0)
		BallService.step(NOW, DT)
		expect(session.violations).toBe(1)
		expect(session.violationLog[1].kind).toBe("Vertical")
		expect(session.part.Position.Y).toBe(HEIGHT)
	end)

	it("never limits a fall", function()
		local session = airborneSession()
		session.part.AssemblyLinearVelocity = Vector3.new(0, -150, 0)
		BallService.step(NOW, DT)
		expect(session.violations).toBe(0)
	end)
end)

-- Horizontal speed ceiling (FR-011). Base ceiling Config.maxServerBallSpeed = 56; a Dash raises it to
-- Config.boostSpeedCap = 80 for dashDuration (3 s) plus boostDecayGrace (0.5 s). Values are the research numbers.
describe("BallService speed ceiling with a Dash", function()
	local DASH_START = NOW
	local DASH_END = DASH_START + 3
	local GRACE_END = DASH_END + 0.5

	local function dashing(): BallService.Session
		local session = airborneSession()
		session.boostUntil = DASH_END
		session.boostGraceUntil = GRACE_END
		return session
	end

	local function runAt(session: BallService.Session, now: number, speed: number)
		session.part.AssemblyLinearVelocity = Vector3.new(speed, 0, 0)
		BallService.step(now, DT)
	end

	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("reads the research numbers from Config", function()
		expect(Config.maxServerBallSpeed).toBe(56)
		expect(Config.boostSpeedCap).toBe(80)
		expect(Config.boostDecayGrace).toBe(0.5)
	end)

	it("accepts a boosted speed above the base ceiling while the Dash is active", function()
		local session = dashing()
		runAt(session, DASH_START + 1, 60)
		expect(session.violations).toBe(0)
		expect(session.part.AssemblyLinearVelocity.X).toBe(60)
	end)

	it("clamps to boostSpeedCap and records a Speed violation above it during a Dash", function()
		local session = dashing()
		runAt(session, DASH_START + 1, 100)
		expect(session.violations).toBe(1)
		expect(session.violationLog[1].kind).toBe("Speed")
		expect(session.violationLog[1].limit).toBe(Config.boostSpeedCap)
		expect(math.abs(session.part.AssemblyLinearVelocity.X - Config.boostSpeedCap) < 1e-3).toBe(
			true
		)
	end)

	it("still accepts the boosted speed just after expiry, inside the grace", function()
		local session = dashing()
		runAt(session, DASH_END + 0.2, 60)
		expect(session.violations).toBe(0)
		expect(session.part.AssemblyLinearVelocity.X).toBe(60)
	end)

	it("clamps an unboosted ball to maxServerBallSpeed once the grace has passed", function()
		local session = dashing()
		runAt(session, GRACE_END + 0.1, 60)
		expect(session.violations).toBe(1)
		expect(session.violationLog[1].kind).toBe("Speed")
		expect(session.violationLog[1].limit).toBe(Config.maxServerBallSpeed)
		expect(math.abs(session.part.AssemblyLinearVelocity.X - Config.maxServerBallSpeed) < 1e-3).toBe(
			true
		)
	end)

	it("clamps a ball that never had a Dash at maxServerBallSpeed", function()
		local session = airborneSession()
		runAt(session, NOW, 100)
		expect(session.violations).toBe(1)
		expect(session.violationLog[1].limit).toBe(Config.maxServerBallSpeed)
	end)
end)

return {}
