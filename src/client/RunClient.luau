--!strict
-- The single reader of run state on the client: Player attributes plus the four server events.
-- Everything here is derived, never authoritative (specs/002-run-loop/data-model.md §6).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RunClock = require(Shared.Rules.RunClock)

export type RunState = "Active" | "Ended" | "Hub"

export type RunResult = {
	runId: string,
	worldId: string,
	finalDiameter: number,
	stars: number,
	coins: number,
	newBookIds: { string },
	bestSelfSize: number,
	bestFriendSize: number?,
	-- Saving and economy (additive): absent or false when the server has no profile for the player.
	coinsTotal: number?,
	isFirstRun: boolean,
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> (),
	Fire: (self: Signal<T...>, T...) -> (),
}

local function newSignal<T...>(): Signal<T...>
	local listeners: { (T...) -> () } = {}
	local signal = {} :: Signal<T...>
	function signal.Connect(_self: Signal<T...>, fn: (T...) -> ())
		table.insert(listeners, fn)
	end
	function signal.Fire(_self: Signal<T...>, ...: T...)
		for _, fn in listeners do
			task.spawn(fn, ...)
		end
	end
	return signal
end

local RunClient = {
	stateChanged = newSignal() :: Signal<RunState?>,
	pickup = newSignal() :: Signal<string>,
	tierUnlocked = newSignal() :: Signal<number>,
	knockedOff = newSignal() :: Signal<>,
	result = newSignal() :: Signal<RunResult>,
}

local player = Players.LocalPlayer

function RunClient.state(): RunState?
	local value = player:GetAttribute("RunState")
	if value == "Active" or value == "Ended" or value == "Hub" then
		return value
	end
	return nil
end

function RunClient.endsAt(): number
	local value = player:GetAttribute("RunEndsAt")
	return if typeof(value) == "number" then value else 0
end

function RunClient.remaining(): number
	return RunClock.remaining(Workspace:GetServerTimeNow(), RunClient.endsAt())
end

-- Returns the payload when every field has the right type, else nil. Never throws.
local function parseResult(payload: unknown): RunResult?
	if typeof(payload) ~= "table" then
		return nil
	end
	local data = payload :: { [string]: unknown }
	local newBookIds = data.newBookIds
	if typeof(newBookIds) ~= "table" then
		return nil
	end
	local ids: { string } = {}
	for _, id in newBookIds :: { unknown } do
		if typeof(id) ~= "string" then
			return nil
		end
		table.insert(ids, id)
	end
	local friendBest: number? = nil
	if data.bestFriendSize ~= nil then
		if typeof(data.bestFriendSize) ~= "number" then
			return nil
		end
		friendBest = data.bestFriendSize
	end
	local coinsTotal: number? = nil
	if data.coinsTotal ~= nil then
		if typeof(data.coinsTotal) ~= "number" then
			return nil
		end
		coinsTotal = data.coinsTotal
	end
	local isFirstRun = false
	if data.isFirstRun ~= nil then
		if typeof(data.isFirstRun) ~= "boolean" then
			return nil
		end
		isFirstRun = data.isFirstRun
	end
	if
		typeof(data.runId) ~= "string"
		or typeof(data.worldId) ~= "string"
		or typeof(data.finalDiameter) ~= "number"
		or typeof(data.stars) ~= "number"
		or typeof(data.coins) ~= "number"
		or typeof(data.bestSelfSize) ~= "number"
	then
		return nil
	end
	return {
		runId = data.runId,
		worldId = data.worldId,
		finalDiameter = data.finalDiameter,
		stars = data.stars,
		coins = data.coins,
		newBookIds = ids,
		bestSelfSize = data.bestSelfSize,
		bestFriendSize = friendBest,
		coinsTotal = coinsTotal,
		isFirstRun = isFirstRun,
	}
end

function RunClient.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local pickupEvent = remotes:WaitForChild("PickupConfirmed") :: RemoteEvent
	local tierEvent = remotes:WaitForChild("TierUnlocked") :: RemoteEvent
	local knockedEvent = remotes:WaitForChild("KnockedOff") :: RemoteEvent
	local resultEvent = remotes:WaitForChild("RunResult") :: RemoteEvent

	player:GetAttributeChangedSignal("RunState"):Connect(function()
		RunClient.stateChanged:Fire(RunClient.state())
	end)
	pickupEvent.OnClientEvent:Connect(function(objectId: unknown)
		if typeof(objectId) == "string" then
			RunClient.pickup:Fire(objectId)
		end
	end)
	tierEvent.OnClientEvent:Connect(function(tier: unknown)
		if typeof(tier) == "number" then
			RunClient.tierUnlocked:Fire(tier)
		end
	end)
	knockedEvent.OnClientEvent:Connect(function()
		RunClient.knockedOff:Fire()
	end)
	resultEvent.OnClientEvent:Connect(function(payload: unknown)
		local result = parseResult(payload)
		if result then
			RunClient.result:Fire(result)
		end
	end)
end

return RunClient
