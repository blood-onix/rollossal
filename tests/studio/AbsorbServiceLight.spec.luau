--!strict
-- Park City light objects (012): server validation from data. Skipped unless Flags.ParkCity is on. Kept in its
-- own file because AbsorbService.spec builds its fixtures from Downtown.

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
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local NOW = 1000
local created: { BallService.Session } = {}
local nextUserId = 920000

local function newSession(): BallService.Session
	nextUserId += 1
	local session = BallService.newSession(nextUserId)
	table.insert(created, session)
	return session
end

local lightDescribe = if Worlds.light ~= nil then describe else describe.skip

lightDescribe("AbsorbService light objects", function()
	local function firstLight(small: boolean): WorldSpawner.LightInfo
		for index = 1, (Worlds.light :: Worlds.LightData).count do
			local info = WorldSpawner.getLight(index)
			assert(info, "light row")
			if (info.bulk <= 0.4) == small and (small or info.bulk > 0.6) then
				return info
			end
		end
		error("no light row")
	end

	local function stand(session: BallService.Session, info: WorldSpawner.LightInfo)
		session.part.Position = Vector3.new(info.x, info.y + 0.5, info.z)
	end

	beforeAll(function()
		WorldSpawner.start()
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

	it("refuses a claim from far away", function()
		local session = newSession()
		local info = firstLight(true)
		session.part.Position = Vector3.new(info.x + 200, info.y, info.z)
		expect(AbsorbService.tryAbsorb(session, `L{info.index}`, NOW)).toBe("OutOfRange")
		expect((WorldSpawner.getLight(info.index) :: WorldSpawner.LightInfo).taken).toBe(false)
	end)

	it("takes an in-range edible object and then refuses it as taken", function()
		local session = newSession()
		local info = firstLight(true)
		stand(session, info)
		expect(AbsorbService.tryAbsorb(session, `L{info.index}`, NOW)).toBe("Ok")
		stand(session, info)
		expect(AbsorbService.tryAbsorb(session, `L{info.index}`, NOW + 1)).toBe("AlreadyTaken")
	end)

	it("refuses a too-big object", function()
		local session = newSession()
		local info = firstLight(false)
		stand(session, info)
		expect(AbsorbService.tryAbsorb(session, `L{info.index}`, NOW)).toBe("TooBig")
	end)

	it("holds the rate limit", function()
		local session = newSession()
		local info = firstLight(true)
		stand(session, info)
		local limited = false
		for i = 1, Config.absorbRateLimit + 2 do
			if
				AbsorbService.tryAbsorb(session, `L{info.index}`, NOW + i * 0.01) == "RateLimited"
			then
				limited = true
			end
		end
		expect(limited).toBe(true)
	end)

	it("returns UnknownObject for an index out of range or a malformed id", function()
		local session = newSession()
		local count = (Worlds.light :: Worlds.LightData).count
		expect(AbsorbService.tryAbsorb(session, `L{count + 1}`, NOW)).toBe("UnknownObject")
		expect(AbsorbService.tryAbsorb(session, "L0", NOW + 1)).toBe("UnknownObject")
		expect(AbsorbService.tryAbsorb(session, "Lx", NOW + 2)).toBe("UnknownObject")
	end)
end)

return {}
