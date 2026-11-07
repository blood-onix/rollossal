--!strict
-- 012 G6: Park City with twelve balls. Eleven playerless bots join the Studio player and eat across the real map for
-- SECONDS seconds, so the server carries 12 balls, their stuck visuals replicate, and every client draws its light
-- field. Pair it with ParkHeavySampler.client (one fps value per second). Run inside Play, with Flags.ParkCity on:
--   local copy = game.ServerStorage.Tests.ParkHeavyScene:Clone(); copy.Parent = game.ServerScriptService
-- (a Script in ServerStorage never runs). It writes the part count and bot sizes as JSON in the
-- `ParkHeavyReport` attribute of Workspace when the time is up. It starts only once.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Absorb = require(Shared.Rules.Absorb)
local Light = require(Shared.Rules.Light)
local Movement = require(Shared.Rules.Movement)
local Worlds = require(Shared.Worlds)
local AbsorbService = require(ServerScriptService.AbsorbService)
local BallService = require(ServerScriptService.BallService)
local RunManager = require(ServerScriptService.RunManager)
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local BOT_COUNT = 11
local FIRST_BOT_USER_ID = 710000
local SECONDS = 75
local RETARGET_SECONDS = 0.4
local SEARCH_RADIUS = 60
local BOT_GROUP = "ParkHeavyBalls"
local OBJECT_GROUP = "ParkHeavyObjects"

if Workspace:GetAttribute("ParkHeavyStart") ~= nil or Worlds.light == nil then
	script:Destroy()
	return
end
Workspace:SetAttribute("ParkHeavyStart", os.clock())
Workspace:SetAttribute("ParkHeavyReport", "")

local light = Worlds.light :: Worlds.LightData
local grid = Light.buildGrid(light.data, light.stride, light.count, Config.lightCellSize)

type Bot = { session: BallService.Session, target: number?, retargetAt: number, wander: Vector3 }
local bots: { Bot } = {}
local startedAt = os.clock()

pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, BOT_GROUP)
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, OBJECT_GROUP)
PhysicsService:CollisionGroupSetCollidable(BOT_GROUP, OBJECT_GROUP, false)
for _, instance in CollectionService:GetTagged("WorldObject") do
	(instance :: BasePart).CollisionGroup = OBJECT_GROUP
end

for index = 1, BOT_COUNT do
	local userId = FIRST_BOT_USER_ID + index
	local session = BallService.newSession(userId, nil)
	session.part.CollisionGroup = BOT_GROUP
	RunManager.startRun(userId, nil, os.clock())
	if session.frozen then
		BallService.setFrozen(session, false)
	end
	table.insert(bots, { session = session, target = nil, retargetAt = 0, wander = Vector3.xAxis })
end

local function pick(bot: Bot): number?
	local position = bot.session.part.Position
	local best, bestScore = nil, -1
	for _, index in
		Light.query(grid, light.data, light.stride, position.X, position.Z, SEARCH_RADIUS)
	do
		local info = WorldSpawner.getLight(index)
		if info and not info.taken then
			local eatable = Absorb.canEat(
				Worlds.rules.absorb,
				bot.session.authoritativeDiameter,
				info.bulk,
				info.size
			)
			if eatable then
				local distance = (Vector3.new(info.x, info.y, info.z) - position).Magnitude
				local score = info.bulk ^ 3 / math.max(distance, 3)
				if score > bestScore then
					best, bestScore = index, score
				end
			end
		end
	end
	return best
end

local connection: RBXScriptConnection? = nil
connection = RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, bot in bots do
		local session = bot.session
		local part = session.part
		local diameter = session.authoritativeDiameter
		if now >= bot.retargetAt then
			bot.target = pick(bot)
			bot.retargetAt = now + RETARGET_SECONDS
			if bot.target == nil then
				bot.wander = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
			end
		end
		local direction = bot.wander
		local target = bot.target
		if target then
			local info = WorldSpawner.getLight(target)
			if info then
				local offset = Vector3.new(info.x, info.y, info.z) - part.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				if flat.Magnitude > 0.05 then
					direction = flat.Unit
				end
				if offset.Magnitude <= diameter / 2 + info.size / 2 + 0.3 then
					AbsorbService.tryAbsorb(session, `L{target}`, now)
				end
			end
		end
		local speed = Movement.targetSpeed(
			diameter,
			Config.baseSpeed,
			Config.startDiameter,
			Config.speedExponent,
			Movement.speedCap(diameter, Worlds.rules.speedCap)
		)
		local velocity = part.AssemblyLinearVelocity
		part.AssemblyLinearVelocity =
			Vector3.new(direction.X * speed, velocity.Y, direction.Z * speed)
	end
	if now - startedAt >= SECONDS then
		(connection :: RBXScriptConnection):Disconnect()
		local parts = 0
		for _, descendant in Workspace:GetDescendants() do
			if descendant:IsA("BasePart") then
				parts += 1
			end
		end
		local sizes = {}
		for _, bot in bots do
			table.insert(sizes, math.floor(bot.session.authoritativeDiameter * 100) / 100)
		end
		Workspace:SetAttribute(
			"ParkHeavyReport",
			HttpService:JSONEncode({
				seconds = SECONDS,
				serverParts = parts,
				balls = BOT_COUNT + 1,
				botSizes = sizes,
			})
		)
		for _, instance in CollectionService:GetTagged("WorldObject") do
			(instance :: BasePart).CollisionGroup = "Default"
		end
		for _, bot in bots do
			RunManager.discard(bot.session.ownerUserId)
			BallService.removeSession(bot.session)
		end
		script:Destroy()
	end
end)
