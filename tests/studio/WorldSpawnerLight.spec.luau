--!strict
-- Park City light state in WorldSpawner (012). Skipped unless Flags.ParkCity is on; kept in its own file because
-- WorldSpawner.spec builds its fixtures from Downtown.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local beforeEach = JestGlobals.beforeEach
local afterAll = JestGlobals.afterAll

local Config = require(ReplicatedStorage.Shared.Config)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local NOW = 5000

local function noWatchers(): { any }
	return {}
end

local lightDescribe = if Worlds.light ~= nil then describe else describe.skip

lightDescribe("WorldSpawner light state", function()
	local index = 1

	beforeAll(function()
		WorldSpawner.start()
	end)
	beforeEach(function()
		WorldSpawner.reset()
		WorldSpawner.flushLight()
		WorldSpawner.setWatcherSource(noWatchers)
	end)
	afterAll(function()
		WorldSpawner.setWatcherSource(noWatchers)
	end)

	it("a take sets the state and the outbox", function()
		WorldSpawner.takeLight(index, NOW)
		expect((WorldSpawner.getLight(index) :: WorldSpawner.LightInfo).taken).toBe(true)
		local taken, restored = WorldSpawner.flushLight()
		expect((taken :: { number })[1]).toBe(index)
		expect(#(restored :: { number })).toBe(0)
		local again = WorldSpawner.flushLight()
		expect(again).toBe(nil)
	end)

	it("returns after its delay when no ball can see it", function()
		WorldSpawner.takeLight(index, NOW)
		WorldSpawner.flushLight()
		WorldSpawner.update(NOW + Config.respawnDelayMax + 1)
		expect((WorldSpawner.getLight(index) :: WorldSpawner.LightInfo).taken).toBe(false)
		local _, restored = WorldSpawner.flushLight()
		expect((restored :: { number })[1]).toBe(index)
	end)

	it("stays taken while a ball watches the spot, until the starvation ceiling", function()
		local info = WorldSpawner.getLight(index) :: WorldSpawner.LightInfo
		WorldSpawner.setWatcherSource(function()
			return { { x = info.x, z = info.z, hx = 0, hz = 0 } }
		end)
		WorldSpawner.takeLight(index, NOW)
		WorldSpawner.update(NOW + Config.respawnDelayMax + 1)
		expect((WorldSpawner.getLight(index) :: WorldSpawner.LightInfo).taken).toBe(true)
		WorldSpawner.update(NOW + Config.respawnForceAfterSeconds + 1)
		expect((WorldSpawner.getLight(index) :: WorldSpawner.LightInfo).taken).toBe(false)
	end)

	it("a bad index has no info", function()
		expect(WorldSpawner.getLight(0)).toBe(nil)
		expect(WorldSpawner.getLight(10 ^ 7)).toBe(nil)
	end)
end)

return {}
