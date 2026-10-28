--!strict
-- Hides the world objects far below the local player's tier, for this client only. Contract:
-- specs/004-snow-village/contracts/runtime-api.md. No remote, no server state: the server still
-- decides every pickup, so this only changes what the local client draws and queries.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Tiers = require(Shared.Rules.Tiers)
local Worlds = require(Shared.Worlds)

local OBJECT_TAG = "WorldObject"

local WorldCuller = {}

-- Loaded pooled parts by tier. Streaming adds and removes parts, so this is only what is loaded right now.
local buckets: { [number]: { [BasePart]: boolean } } = {}
local culledTiers: { [number]: boolean } = {}
local takenWatchers: { [BasePart]: RBXScriptConnection? } = {}
local playerTier = 1
local attached = false

local function tierOf(part: BasePart): number?
	local tier = part:GetAttribute("Tier")
	if typeof(tier) == "number" then
		return tier
	end
	return nil
end

local function hide(part: BasePart)
	part.LocalTransparencyModifier = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

-- Comes back as the server last left it: a Taken part stays untouchable and unqueryable, whatever the player
-- tier did in between.
local function restore(part: BasePart)
	local taken = part:GetAttribute("Taken") == true
	part.LocalTransparencyModifier = 0
	part.CanCollide = not taken
	part.CanTouch = not taken
	part.CanQuery = not taken
end

local function stopWatching(part: BasePart)
	local connection = takenWatchers[part]
	if connection then
		connection:Disconnect()
		takenWatchers[part] = nil
	end
end

-- A culled part that respawns gets its replicated CanTouch and CanQuery back, so it is hidden again.
local function cull(part: BasePart)
	hide(part)
	if takenWatchers[part] == nil then
		takenWatchers[part] = part:GetAttributeChangedSignal("Taken"):Connect(function()
			hide(part)
		end)
	end
end

local function uncull(part: BasePart)
	stopWatching(part)
	restore(part)
end

local function track(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local tier = tierOf(instance)
	if tier == nil then
		return
	end
	local bucket = buckets[tier]
	if bucket == nil then
		bucket = {}
		buckets[tier] = bucket
	end
	bucket[instance] = true
	if culledTiers[tier] then
		cull(instance)
	end
end

local function untrack(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	stopWatching(instance)
	local tier = tierOf(instance)
	local bucket = if tier then buckets[tier] else nil
	if bucket then
		bucket[instance] = nil
	end
end

-- Applies the player's tier: only the tiers whose state changes are touched.
function WorldCuller.setPlayerTier(tier: number)
	playerTier = tier
	for objectTier, bucket in buckets do
		local shouldCull = Tiers.isCulled(objectTier, tier, Config.cullTierDelta)
		if shouldCull ~= (culledTiers[objectTier] == true) then
			culledTiers[objectTier] = shouldCull
			for part in bucket do
				if shouldCull then
					cull(part)
				else
					uncull(part)
				end
			end
		end
	end
	-- A tier with no loaded parts yet still needs its state, for parts that stream in later.
	for objectTier = 1, #Worlds.sizeTiers do
		culledTiers[objectTier] = Tiers.isCulled(objectTier, tier, Config.cullTierDelta)
	end
end

function WorldCuller.currentTier(): number
	return playerTier
end

-- Collects the tagged parts and follows streaming. Separate from start() so a test can run it without a ball.
function WorldCuller.attach()
	if attached then
		return
	end
	attached = true
	CollectionService:GetInstanceAddedSignal(OBJECT_TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(OBJECT_TAG):Connect(untrack)
	for _, instance in CollectionService:GetTagged(OBJECT_TAG) do
		track(instance)
	end
end

-- Test helper: forget every part and restore the ones that were culled.
function WorldCuller.reset()
	for _, bucket in buckets do
		for part in bucket do
			if culledTiers[tierOf(part) or 0] then
				uncull(part)
			end
		end
	end
	table.clear(buckets)
	table.clear(culledTiers)
	for part in takenWatchers do
		stopWatching(part)
	end
	playerTier = 1
end

function WorldCuller.start()
	WorldCuller.attach()
	task.spawn(function()
		local player = Players.LocalPlayer
		local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`)
		local function refresh()
			local diameter = ball:GetAttribute("Diameter")
			if typeof(diameter) ~= "number" then
				diameter = Config.startDiameter
			end
			local tier = Tiers.lookup(diameter :: number, Worlds.tierLikes)
			if tier ~= playerTier or next(culledTiers) == nil then
				WorldCuller.setPlayerTier(tier)
			end
		end
		ball:GetAttributeChangedSignal("Diameter"):Connect(refresh)
		refresh()
	end)
end

return WorldCuller
