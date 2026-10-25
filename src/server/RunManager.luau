--!strict
-- Owns every player's run: starts it, ends it at the bell, builds one RunResult and handles the two
-- post-run intents. The clock is always an argument; only Main.server reads os.clock().
-- Contracts: specs/002-run-loop/contracts/remotes.md and replicated-state.md.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Worlds = require(Shared.Worlds)
local Coins = require(Shared.Rules.Coins)
local RunClock = require(Shared.Rules.RunClock)
local Stars = require(Shared.Rules.Stars)
local Tiers = require(Shared.Rules.Tiers)
local BallService = require(script.Parent.BallService)
local FriendCache = require(script.Parent.FriendCache)
local Remotes = require(script.Parent.Remotes)

type ObjectDef = Worlds.ObjectDef

export type RunState = "Active" | "Ended" | "Hub"

export type RunSession = {
	runId: string,
	userId: number,
	player: Player?,
	worldId: string,
	state: RunState,
	startedAt: number,
	endsAt: number,
	absorbedCoinValues: { number },
	absorbedBookIds: { string },
	unlockedTiers: { [number]: boolean },
	resultPublished: boolean,
}

export type RunResult = {
	runId: string,
	worldId: string,
	finalDiameter: number,
	stars: number,
	coins: number,
	newBookIds: { string },
	bestSelfSize: number,
	bestFriendSize: number?,
}

type Publisher = (userId: number, result: RunResult) -> ()
-- name is PickupConfirmed, TierUnlocked or KnockedOff; payload is the object id, the tier, or nil.
type EventSink = (userId: number, name: string, payload: unknown) -> ()

local RunManager = {}

local runs: { [number]: RunSession } = {}
local bestSelfSize: { [number]: number } = {}
local seenBookIds: { [number]: { [string]: boolean } } = {}
local runSeq = 0
local shuttingDown = false

local function defaultPublisher(userId: number, result: RunResult)
	local run = runs[userId]
	if run and run.player then
		Remotes.RunResult:FireClient(run.player, result)
	end
end

local publisher: Publisher = defaultPublisher

-- Facts go to the owning player only (Constitution II: the server sends, the client never reports).
local sinkEvents: { [string]: RemoteEvent } = {
	PickupConfirmed = Remotes.PickupConfirmed,
	TierUnlocked = Remotes.TierUnlocked,
	KnockedOff = Remotes.KnockedOff,
}

local function defaultSink(userId: number, name: string, payload: unknown)
	local run = runs[userId]
	local event = sinkEvents[name]
	if run and run.player and event then
		if payload == nil then
			event:FireClient(run.player)
		else
			event:FireClient(run.player, payload)
		end
	end
end

local sink: EventSink = defaultSink

function RunManager.setEventSink(fn: EventSink?)
	sink = fn or defaultSink
end

function RunManager.setPublisher(fn: Publisher?)
	publisher = fn or defaultPublisher
end

function RunManager.getRun(userId: number): RunSession?
	return runs[userId]
end

-- All three attributes are written together, RunState last, so a client that sees the new state also
-- sees the matching id and end time.
local function writeAttributes(run: RunSession, now: number)
	local player = run.player
	if not player then
		return
	end
	if run.state == "Active" then
		player:SetAttribute("RunId", run.runId)
		player:SetAttribute("RunEndsAt", Workspace:GetServerTimeNow() + (run.endsAt - now))
	elseif run.state == "Ended" then
		player:SetAttribute("RunId", run.runId)
	else
		player:SetAttribute("RunId", "")
		player:SetAttribute("RunEndsAt", 0)
	end
	player:SetAttribute("RunState", run.state)
end

function RunManager.startRun(userId: number, player: Player?, now: number): RunSession
	runSeq += 1
	local run: RunSession = {
		runId = `{userId}-{runSeq}`,
		userId = userId,
		player = player,
		worldId = Worlds.active.worldId,
		state = "Active",
		startedAt = now,
		endsAt = now + Config.runDurationSeconds,
		absorbedCoinValues = {},
		absorbedBookIds = {},
		unlockedTiers = { [1] = true },
		resultPublished = false,
	}
	runs[userId] = run
	local session = BallService.getSessionByUserId(userId)
	if session then
		session.zone = "Room"
		BallService.resetBall(session)
		if session.frozen then
			BallService.setFrozen(session, false)
		end
	end
	writeAttributes(run, now)
	return run
end

function RunManager.discard(userId: number)
	runs[userId] = nil
end

function RunManager.acceptsPickups(userId: number, now: number): boolean
	local run = runs[userId]
	if run == nil then
		return true
	end
	return run.state == "Active" and not RunClock.expired(now, run.endsAt)
end

-- What the Reset button does: Return keeps the run, Full is the 001 reset, Reject ignores it.
function RunManager.resetAction(userId: number): "Return" | "Full" | "Reject"
	local run = runs[userId]
	if run == nil or run.state == "Hub" then
		return "Full"
	end
	if run.state == "Active" then
		return "Return"
	end
	return "Reject"
end

function RunManager.onPickup(userId: number, object: ObjectDef, _now: number)
	local run = runs[userId]
	if run == nil or run.state ~= "Active" then
		return
	end
	table.insert(run.absorbedCoinValues, object.coins)
	if not table.find(run.absorbedBookIds, object.bookId) then
		table.insert(run.absorbedBookIds, object.bookId)
	end
	sink(userId, "PickupConfirmed", object.id)

	local session = BallService.getSessionByUserId(userId)
	if session == nil then
		return
	end
	-- Banners never repeat: unlocked tiers are never reduced, so a knock-off and regrowth stays silent.
	local tier = Tiers.lookup(session.authoritativeDiameter, Worlds.tierLikes)
	if tier > 1 and not run.unlockedTiers[tier] then
		for lower = 2, tier do
			run.unlockedTiers[lower] = true
		end
		sink(userId, "TierUnlocked", tier)
	end
end

-- A knock-off stores nothing: coins and unlocked tiers are never reduced.
function RunManager.onKnockOff(userId: number)
	local run = runs[userId]
	if run == nil or run.state ~= "Active" then
		return
	end
	sink(userId, "KnockedOff", nil)
end

local function presentUserIds(): { number }
	local ids = {}
	for _, player in Players:GetPlayers() do
		table.insert(ids, player.UserId)
	end
	return ids
end

local function bestFriendSize(userId: number): number?
	local best: number? = nil
	for _, otherId in presentUserIds() do
		if otherId ~= userId and FriendCache.areFriends(userId, otherId) then
			local size = bestSelfSize[otherId]
			if size ~= nil and (best == nil or size > best) then
				best = size
			end
		end
	end
	return best
end

local function buildResult(run: RunSession, finalDiameter: number): RunResult
	local userId = run.userId
	local seen = seenBookIds[userId] or {}
	local newBookIds = {}
	for _, bookId in run.absorbedBookIds do
		if not seen[bookId] then
			table.insert(newBookIds, bookId)
		end
	end
	return {
		runId = run.runId,
		worldId = run.worldId,
		finalDiameter = finalDiameter,
		stars = Stars.stars(finalDiameter, Worlds.starThresholds),
		coins = Coins.total(run.absorbedCoinValues, {
			friendBonusRate = Config.friendBonusRate,
			hasFriendInServer = FriendCache.hasFriendIn(userId, presentUserIds()),
			hasDoubleCoins = false,
			friendBoostRate = Config.friendBoostRate,
			friendBoostCount = 0,
		}),
		newBookIds = newBookIds,
		bestSelfSize = math.max(bestSelfSize[userId] or 0, finalDiameter),
		bestFriendSize = bestFriendSize(userId),
	}
end

local function endRun(run: RunSession, now: number)
	run.state = "Ended"
	local session = BallService.getSessionByUserId(run.userId)
	local finalDiameter = Config.startDiameter
	if session then
		BallService.setFrozen(session, true)
		finalDiameter = session.authoritativeDiameter
	end
	writeAttributes(run, now)
	if run.resultPublished then
		return
	end
	run.resultPublished = true
	local result = buildResult(run, finalDiameter)

	local seen = seenBookIds[run.userId] or {}
	for _, bookId in run.absorbedBookIds do
		seen[bookId] = true
	end
	seenBookIds[run.userId] = seen
	bestSelfSize[run.userId] = result.bestSelfSize

	publisher(run.userId, result)
end

-- Ends every Active run whose time is up. Called once per Heartbeat after BallService.step.
function RunManager.step(now: number)
	if shuttingDown then
		return
	end
	for _, run in runs do
		if run.state == "Active" and RunClock.expired(now, run.endsAt) then
			endRun(run, now)
		end
	end
end

-- Shared checks for the two intents, in the order of contracts/remotes.md. Returns the reject code
-- or nil. Rejections never warn and never change anything.
local function check(userId: number, allowed: { RunState }, ...: unknown): (string?, RunSession?)
	if select("#", ...) ~= 0 then
		return "BadArgument", nil
	end
	local run = runs[userId]
	if run == nil then
		return "NoRun", nil
	end
	if not table.find(allowed, run.state) then
		return "WrongState", nil
	end
	if shuttingDown then
		return "ShuttingDown", nil
	end
	return nil, run
end

function RunManager.handleRollAgain(userId: number, now: number, ...: unknown): string
	local code, run = check(userId, { "Ended", "Hub" }, ...)
	if code or not run then
		return code or "NoRun"
	end
	RunManager.startRun(userId, run.player, now)
	return "Ok"
end

function RunManager.handleBackToHub(userId: number, now: number, ...: unknown): string
	local code, run = check(userId, { "Ended" }, ...)
	if code or not run then
		return code or "NoRun"
	end
	local session = BallService.getSessionByUserId(userId)
	if session then
		session.zone = "Hub"
		BallService.resetBall(session)
		BallService.setFrozen(session, false)
	end
	run.state = "Hub"
	writeAttributes(run, now)
	return "Ok"
end

function RunManager.start()
	if not Config.Flags.RunLoop then
		return
	end

	local function onPlayerAdded(player: Player)
		RunManager.startRun(player.UserId, player, os.clock())
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		RunManager.discard(player.UserId)
	end)

	Remotes.RollAgain.OnServerEvent:Connect(function(player: Player, ...: unknown)
		RunManager.handleRollAgain(player.UserId, os.clock(), ...)
	end)
	Remotes.BackToHub.OnServerEvent:Connect(function(player: Player, ...: unknown)
		RunManager.handleBackToHub(player.UserId, os.clock(), ...)
	end)

	game:BindToClose(function()
		shuttingDown = true
	end)
end

return RunManager
