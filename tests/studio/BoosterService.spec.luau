--!strict
-- Booster claiming against the real world (006, contracts/runtime-api.md). Expected values come from the Config
-- numbers in research R-18 and the contract's result codes, never from the code under test.

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
local BallService = require(ServerScriptService.BallService)
local BoosterService = require(ServerScriptService.BoosterService)
local KnockOff = require(ServerScriptService.KnockOff)
local RunManager = require(ServerScriptService.RunManager)
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local NOW = 2000
local created: { BallService.Session } = {}
local nextUserId = 920000

local function newSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId)
	table.insert(created, session)
	return session
end

local function markerOf(subKind: string): BoosterService.Marker
	for _, marker in BoosterService.markers() do
		if marker.subKind == subKind then
			return marker
		end
	end
	error(`no booster marker of sub-kind {subKind}`)
end

local function stand(session: BallService.Session, marker: BoosterService.Marker)
	session.part.Anchored = true
	session.part.Position = marker.position + Vector3.new(0, 1, 0)
end

describe("BoosterService claims", function()
	beforeAll(function()
		WorldSpawner.start()
		BoosterService.init()
	end)
	beforeEach(function()
		BoosterService.reset()
	end)
	afterEach(function()
		for _, session in created do
			RunManager.discard(session.ownerUserId)
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("refuses non-string and empty arguments as BadArgs", function()
		local session = newSession()
		expect(BoosterService.tryClaim(session, 5, NOW)).toBe("BadArgs")
		expect(BoosterService.tryClaim(session, nil, NOW)).toBe("BadArgs")
		expect(BoosterService.tryClaim(session, "", NOW)).toBe("BadArgs")
		expect(BoosterService.tryClaim(session, string.rep("a", 41), NOW)).toBe("BadArgs")
	end)

	it("refuses an unknown marker and a ball too far away", function()
		local session = newSession()
		expect(BoosterService.tryClaim(session, "no-such-marker", NOW)).toBe("UnknownMarker")
		local marker = markerOf("dash")
		session.part.Position = marker.position + Vector3.new(60, 1, 0)
		expect(BoosterService.tryClaim(session, marker.markerId, NOW + 1)).toBe("OutOfRange")
	end)

	it("rate limits claims: the fifth in a window is RateLimited", function()
		local session = newSession()
		for _ = 1, Config.boosterClaimRateLimit do
			expect(BoosterService.tryClaim(session, "no-such-marker", NOW)).toBe("UnknownMarker")
		end
		expect(BoosterService.tryClaim(session, "no-such-marker", NOW)).toBe("RateLimited")
	end)

	it("refuses a claim when the run is not active", function()
		local session = newSession()
		local run = RunManager.startRun(session.ownerUserId, nil, NOW)
		run.state = "Ended"
		local marker = markerOf("dash")
		stand(session, marker)
		expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("NotActive")
	end)

	-- Flag layers (FR-011): a booster is live only when the master flag and its own flag are both true.
	describe("when a feature flag is off", function()
		local flags = Config.Flags :: { [string]: boolean }
		local saved: { [string]: boolean } = {}

		beforeEach(function()
			saved.Boosters = flags.Boosters
			saved.BoosterDash = flags.BoosterDash
			saved.BoosterSpring = flags.BoosterSpring
		end)
		afterEach(function()
			flags.Boosters = saved.Boosters
			flags.BoosterDash = saved.BoosterDash
			flags.BoosterSpring = saved.BoosterSpring
		end)

		it("refuses every claim as Disabled when the master Boosters flag is false", function()
			flags.Boosters = false
			local session = newSession()
			local marker = markerOf("dash")
			stand(session, marker)
			expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("Disabled")
			expect(marker.state).toBe("Available")
			expect(session.boostUntil).toBe(-math.huge)
			expect(session.boostGraceUntil).toBe(-math.huge)
		end)

		it("refuses only that booster when its own flag is false", function()
			flags.BoosterDash = false
			local session = newSession()
			local dash = markerOf("dash")
			stand(session, dash)
			expect(BoosterService.tryClaim(session, dash.markerId, NOW)).toBe("Disabled")
			expect(dash.state).toBe("Available")
			expect(session.boostUntil).toBe(-math.huge)

			-- Another booster is unaffected by the Dash flag.
			local spring = markerOf("spring")
			stand(session, spring)
			expect(BoosterService.tryClaim(session, spring.markerId, NOW + 1)).toBe("Ok")
		end)

		it("claims again once the flags are restored", function()
			flags.Boosters = false
			local session = newSession()
			local marker = markerOf("dash")
			stand(session, marker)
			expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("Disabled")
			flags.Boosters = saved.Boosters
			expect(BoosterService.tryClaim(session, marker.markerId, NOW + 1)).toBe("Ok")
			expect(marker.state).toBe("Taken")
		end)
	end)

	it("grants a Dash, hides the pickup, and respawns it after boosterRespawnDelay", function()
		local session = newSession()
		local marker = markerOf("dash")
		stand(session, marker)
		expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("Ok")
		expect(session.boostUntil).toBe(NOW + Config.dashDuration)
		expect(session.boostGraceUntil).toBe(NOW + Config.dashDuration + Config.boostDecayGrace)
		expect(marker.state).toBe("Taken")
		expect(BoosterService.tryClaim(session, marker.markerId, NOW + 1)).toBe("Unavailable")

		BoosterService.step(NOW + Config.boosterRespawnDelay + 1, 1 / 60)
		expect(marker.state).toBe("Available")
		local other = newSession()
		stand(other, marker)
		expect(
			BoosterService.tryClaim(other, marker.markerId, NOW + Config.boosterRespawnDelay + 2)
		).toBe("Ok")
	end)

	it("refreshes an active booster instead of stacking it", function()
		local session = newSession()
		local first, second
		for _, marker in BoosterService.markers() do
			if marker.subKind == "magnet" then
				if first == nil then
					first = marker
				else
					second = marker
				end
			end
		end
		expect(first).never.toBeNil()
		expect(second).never.toBeNil()
		stand(session, first)
		expect(BoosterService.tryClaim(session, first.markerId, NOW)).toBe("Ok")
		stand(session, second)
		expect(BoosterService.tryClaim(session, second.markerId, NOW + 3)).toBe("Ok")
		-- The second claim restarts the full duration: 6 s left at NOW + 3, not 3.
		local remaining = BoosterService.activeFor(session, NOW + 3).magnet
			- Workspace:GetServerTimeNow()
		expect(math.abs(remaining - Config.magnetDuration) < 0.5).toBe(true)
	end)

	it("a Shield absorbs the next qualifying hit and is then spent", function()
		local session = newSession()
		local marker = markerOf("shield")
		stand(session, marker)
		expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("Ok")
		expect(session.shieldUntil).toBe(NOW + Config.shieldDuration)
		expect(KnockOff.apply(session, "obstacle", NOW + 1)).toBe("ShieldAbsorbed")
		expect(session.shieldUntil).toBe(-math.huge)
		expect(session.lastBumpAt).toBe(NOW + 1)
		-- Nothing is stuck, so with the shield spent a later hit does nothing.
		expect(KnockOff.apply(session, "obstacle", NOW + 5)).toBe("NothingStuck")
	end)

	it(
		"a Spring publishes a Launch, opens the guard window, and has a per-ball cooldown",
		function()
			local session = newSession()
			local marker = markerOf("spring")
			stand(session, marker)
			expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("Ok")
			local launch = session.part:GetAttribute("Launch") :: string
			expect(string.sub(launch, 1, 2)).toBe("1;")
			expect(session.springUntil).toBe(NOW + Config.springFlightDuration)
			expect(session.springVy).toBe(Config.springVerticalSpeed)
			expect(marker.state).toBe("Available")
			expect(BoosterService.tryClaim(session, marker.markerId, NOW + 1)).toBe("Unavailable")
			expect(
				BoosterService.tryClaim(session, marker.markerId, NOW + Config.springCooldown + 0.1)
			).toBe("Ok")
		end
	)

	it(
		"a Slick Trail lays patches from a fixed pool and never exceeds the pool or its own cap",
		function()
			local session = newSession()
			local marker = markerOf("slick_trail")
			stand(session, marker)
			expect(BoosterService.tryClaim(session, marker.markerId, NOW)).toBe("Ok")
			for step = 1, 80 do
				session.part.Position = marker.position
					+ Vector3.new(step * (Config.slickTrailSpacing + 0.5), 1, 0)
				BoosterService.step(NOW + step * 0.01, 1 / 60)
			end
			expect(BoosterService.poolSize()).toBe(Config.slickTrailPoolSize)
			local owned = 0
			local folder = Workspace:FindFirstChild("TrailPatches")
			for _, patch in folder:GetChildren() do
				if patch:GetAttribute("OwnerUserId") == session.ownerUserId then
					owned += 1
				end
			end
			expect(owned).toBe(Config.slickTrailMaxPatches)
		end
	)

	it("clearing a ball ends its effects and parks its patches", function()
		local session = newSession()
		local marker = markerOf("slick_trail")
		stand(session, marker)
		BoosterService.tryClaim(session, marker.markerId, NOW)
		session.part.Position = marker.position + Vector3.new(10, 1, 0)
		BoosterService.step(NOW + 0.1, 1 / 60)
		BallService.clearEffects(session)
		local active = BoosterService.activeFor(session)
		expect(active.trail).toBe(0)
		local folder = Workspace:FindFirstChild("TrailPatches")
		for _, patch in folder:GetChildren() do
			expect(patch:GetAttribute("OwnerUserId")).toBe(0)
		end
	end)

	it("a Magnet draws small objects towards the ball and sends them home when it ends", function()
		local session = newSession()
		local marker = markerOf("magnet")
		stand(session, marker)
		BoosterService.tryClaim(session, marker.markerId, NOW)
		BoosterService.step(NOW + 0.2, 0.2)
		local pulled = BoosterService.pulledIds(session)
		for _, id in pulled do
			local object = WorldSpawner.getObject(id)
			-- Only objects the ball can absorb are drawn in: at most 0.4 of its diameter 2.
			expect(object ~= nil and object.size <= 0.8).toBe(true)
		end
		expect(#pulled <= Config.magnetMaxPulled).toBe(true)
		BoosterService.step(NOW + Config.magnetDuration + 1, 0.1)
		for _, object in WorldSpawner.candidatesNear(marker.position, 200, NOW) do
			local pooled = WorldSpawner.getObject(object.id)
			if pooled and pooled.state == "Available" then
				expect(pooled.part.CFrame == pooled.spawnCFrame).toBe(true)
			end
		end
	end)
end)
