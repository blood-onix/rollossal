--!strict
-- Friend lookups per pair of present players. IsFriendsWith yields and can fail, so results are cached
-- off the hot path and readers get a synchronous answer that defaults to "not friends" (research R7).

local Players = game:GetService("Players")

local FriendCache = {}

local friends: { [number]: { [number]: boolean } } = {}

local function lookup(player: Player, other: Player)
	task.spawn(function()
		local ok, result = pcall(player.IsFriendsWithAsync, player, other.UserId)
		local row = friends[player.UserId]
		if row then
			row[other.UserId] = ok and result == true
		end
	end)
end

function FriendCache.areFriends(a: number, b: number): boolean
	local row = friends[a]
	return row ~= nil and row[b] == true
end

function FriendCache.hasFriendIn(userId: number, presentUserIds: { number }): boolean
	for _, other in presentUserIds do
		if other ~= userId and FriendCache.areFriends(userId, other) then
			return true
		end
	end
	return false
end

function FriendCache.start()
	local function onPlayerAdded(player: Player)
		friends[player.UserId] = {}
		for _, other in Players:GetPlayers() do
			if other ~= player then
				lookup(player, other)
				lookup(other, player)
			end
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		friends[player.UserId] = nil
		for _, row in friends do
			row[player.UserId] = nil
		end
	end)
end

return FriendCache
