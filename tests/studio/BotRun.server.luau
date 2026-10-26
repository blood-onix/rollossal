--!strict
-- Quickstart §3: twelve playerless balls steered by a simple eater for one full run, to see that no tier zone
-- runs dry (SC-003) and what the part count is. It must run inside the playing server, because a require from
-- the Studio MCP gets its own copies of BallService and WorldSpawner. Start it while Play is running:
--   local copy = game.ServerStorage.Tests.BotRun:Clone(); copy.Parent = game.ServerScriptService
-- (a Script in ServerStorage never runs). It writes the report as JSON in the `BotRunReport` attribute of
-- Workspace when the run ends, and prints one line per minute. It starts only when that attribute is empty
-- and `BotRunStart` is not set, so cloning it twice does nothing.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Movement = require(Shared.Rules.Movement)
local Worlds = require(Shared.Worlds)
local AbsorbService = require(ServerScriptService.AbsorbService)
local BallService = require(ServerScriptService.BallService)
local RunManager = require(ServerScriptService.RunManager)
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local BOT_COUNT = 12
local FIRST_BOT_USER_ID = 700000
local RETARGET_SECONDS = 0.4
local STUCK_SECONDS = 2
local STUCK_DISTANCE = 2
local CONTACT_MARGIN = 0.3
local SAMPLE_SECONDS = 60
local TIER_AVAILABLE_FLOOR = 0.2
-- A real player's client turns off collision with the objects it can eat; the server-owned bot balls cannot,
-- so the bots and the pooled objects live in groups that never collide (the geometry still does).
local BOT_GROUP = "BotRunBalls"
local OBJECT_GROUP = "BotRunObjects"

type Bot = {
	session: BallService.Session,
	target: BasePart?,
	retargetAt: number,
	anchorPosition: Vector3,
	anchorAt: number,
	wander: Vector3,
	firstPickupAt: number?,
	tier2At: number?,
	tier4At: number?,
}

if Workspace:GetAttribute("BotRunStart") ~= nil then
	script:Destroy()
	return
end
Workspace:SetAttribute("BotRunStart", os.clock())
Workspace:SetAttribute("BotRunReport", "")

local startedAt = os.clock()
local bots: { Bot } = {}
local samples: { { at: number, tiers: { [string]: number }, parts: number } } = {}
local pickups = 0

local function setUpGroups()
	pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, BOT_GROUP)
	pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, OBJECT_GROUP)
	PhysicsService:CollisionGroupSetCollidable(BOT_GROUP, OBJECT_GROUP, false)
	for _, instance in CollectionService:GetTagged("WorldObject") do
		(instance :: BasePart).CollisionGroup = OBJECT_GROUP
	end
end

local function releaseGroups()
	for _, instance in CollectionService:GetTagged("WorldObject") do
		(instance :: BasePart).CollisionGroup = "Default"
	end
end

local function startBot(index: number): Bot
	local userId = FIRST_BOT_USER_ID + index
	local session = BallService.newSession(userId, nil)
	session.part.CollisionGroup = BOT_GROUP
	RunManager.startRun(userId, nil, os.clock())
	if session.frozen then
		BallService.setFrozen(session, false)
	end
	return {
		session = session,
		target = nil,
		retargetAt = 0,
		anchorPosition = session.part.Position,
		anchorAt = os.clock(),
		wander = Vector3.xAxis,
		firstPickupAt = nil,
		tier2At = nil,
		tier4At = nil,
	}
end

-- The eatable object with the most volume per stud of travel.
local function pickTarget(bot: Bot): BasePart?
	local session = bot.session
	local position = session.part.Position
	local limit = Config.absorbRatio * session.authoritativeDiameter
	local best: BasePart? = nil
	local bestScore = -1
	for _, instance in CollectionService:GetTagged("WorldObject") do
		local part = instance :: BasePart
		local size = part:GetAttribute("Size")
		if part:GetAttribute("Taken") ~= true and typeof(size) == "number" and size <= limit then
			local distance = (part.Position - position).Magnitude
			local score = size ^ 3 / math.max(distance, 3)
			if score > bestScore then
				best = part
				bestScore = score
			end
		end
	end
	return best
end

local function recordSample(now: number)
	local tiers: { [string]: number } = {}
	for tier, counts in WorldSpawner.countsByTier() do
		tiers[tostring(tier)] = math.floor(counts.available / counts.total * 1000) / 1000
	end
	local parts = 0
	local world = Workspace:FindFirstChild("World")
	if world then
		parts = #world:GetDescendants() + BOT_COUNT
	end
	table.insert(samples, { at = math.floor(now - startedAt), tiers = tiers, parts = parts })
	local line = {}
	for tier = 1, #Worlds.sizeTiers do
		table.insert(line, `T{tier} {tiers[tostring(tier)]}`)
	end
	print(
		`[BotRun {math.floor(now - startedAt)} s] available {table.concat(line, ", ")}, parts {parts}`
	)
end

local function step(bot: Bot, now: number)
	local session = bot.session
	if session.frozen then
		return
	end
	local part = session.part
	local diameter = session.authoritativeDiameter
	local tier = 1
	for index, def in Worlds.sizeTiers do
		if diameter >= def.minDiameter then
			tier = index
		end
	end
	if tier >= 2 and bot.tier2At == nil then
		bot.tier2At = now - startedAt
	end
	if tier >= 4 and bot.tier4At == nil then
		bot.tier4At = now - startedAt
	end

	local target = bot.target
	local stale = target == nil
		or target:GetAttribute("Taken") == true
		or (target:GetAttribute("Size") :: number) > Config.absorbRatio * diameter
	if stale or now >= bot.retargetAt then
		bot.target = pickTarget(bot)
		bot.retargetAt = now + RETARGET_SECONDS
		target = bot.target
	end

	if now - bot.anchorAt >= STUCK_SECONDS then
		if (part.Position - bot.anchorPosition).Magnitude < STUCK_DISTANCE then
			bot.wander = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
			bot.target = nil
			bot.retargetAt = now + STUCK_SECONDS
			target = nil
		end
		bot.anchorPosition = part.Position
		bot.anchorAt = now
	end

	local direction = bot.wander
	if target then
		local offset = target.Position - part.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude > 0.05 then
			direction = flat.Unit
		end
		local reach = diameter / 2 + (target:GetAttribute("Size") :: number) / 2 + CONTACT_MARGIN
		if offset.Magnitude <= reach then
			local before = session.authoritativeDiameter
			AbsorbService.tryAbsorb(session, target.Name, now)
			if session.authoritativeDiameter > before then
				pickups += 1
				if bot.firstPickupAt == nil then
					bot.firstPickupAt = now - startedAt
				end
			end
		end
	end
	local speed = Movement.targetSpeed(
		diameter,
		Config.baseSpeed,
		Config.startDiameter,
		Config.speedExponent,
		Config.speedCap
	)
	local velocity = part.AssemblyLinearVelocity
	part.AssemblyLinearVelocity = Vector3.new(direction.X * speed, velocity.Y, direction.Z * speed)
end

local function finish()
	local report = {
		seconds = Config.runDurationSeconds,
		bots = {},
		samples = samples,
		pickups = pickups,
		everyTierKeptShare = true,
	}
	for _, sample in samples do
		for _, share in sample.tiers do
			if share < TIER_AVAILABLE_FLOOR then
				report.everyTierKeptShare = false
			end
		end
	end
	for _, bot in bots do
		table.insert(report.bots, {
			finalDiameter = math.floor(bot.session.authoritativeDiameter * 100) / 100,
			firstPickup = bot.firstPickupAt,
			tier2 = bot.tier2At,
			tier4 = bot.tier4At,
		})
	end
	Workspace:SetAttribute("BotRunReport", HttpService:JSONEncode(report))
	print("[BotRun] done")
end

setUpGroups()
for index = 1, BOT_COUNT do
	table.insert(bots, startBot(index))
end

local lastSample = startedAt
local connection: RBXScriptConnection? = nil
connection = RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, bot in bots do
		step(bot, now)
	end
	if now - lastSample >= SAMPLE_SECONDS then
		lastSample = now
		recordSample(now)
	end
	if now - startedAt >= Config.runDurationSeconds + 1 then
		if connection then
			connection:Disconnect()
		end
		recordSample(now)
		finish()
		releaseGroups()
		for _, bot in bots do
			RunManager.discard(bot.session.ownerUserId)
			BallService.removeSession(bot.session)
		end
		script:Destroy()
	end
end)
