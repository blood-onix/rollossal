--!strict
-- The remote set (006 D2): thirteen RemoteEvents, and ClaimBooster takes exactly one string.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local afterEach = JestGlobals.afterEach

local BallService = require(ServerScriptService.BallService)
local BoosterService = require(ServerScriptService.BoosterService)
local WorldSpawner = require(ServerScriptService.WorldSpawner)
require(ServerScriptService.Remotes)

local NOW = 3000
local created: { BallService.Session } = {}

describe("Remotes", function()
	beforeAll(function()
		WorldSpawner.start()
		BoosterService.init()
	end)
	afterEach(function()
		for _, session in created do
			BallService.removeSession(session)
		end
		table.clear(created)
	end)

	it("has thirteen RemoteEvents including ClaimBooster", function()
		local folder = ReplicatedStorage:WaitForChild("Remotes")
		local events = 0
		for _, child in folder:GetChildren() do
			if child:IsA("RemoteEvent") then
				events += 1
			end
		end
		expect(events).toBe(13)
		expect(folder:FindFirstChild("ClaimBooster")).never.toBeNil()
		expect(folder:FindFirstChild("ClaimBooster"):IsA("RemoteEvent")).toBe(true)
	end)

	it("ClaimBooster drops a non-string, missing or extra argument as BadArgs", function()
		local session = BallService.newSession(930001)
		table.insert(created, session)
		expect(BoosterService.handle(session, NOW, 42)).toBe("BadArgs")
		expect(BoosterService.handle(session, NOW)).toBe("BadArgs")
		expect(BoosterService.handle(session, NOW, "booster-dash-1", "extra")).toBe("BadArgs")
		expect(BoosterService.handle(session, NOW, { "booster-dash-1" })).toBe("BadArgs")
		expect(BoosterService.handle(session, NOW, "no-such-marker")).toBe("UnknownMarker")
	end)
end)
