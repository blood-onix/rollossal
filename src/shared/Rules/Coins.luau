--!strict
-- Run coin total. Pure: no Roblox APIs, no clock, no randomness.

export type Options = {
	friendBonusRate: number,
	hasFriendInServer: boolean,
	hasDoubleCoins: boolean,
	friendBoostRate: number,
	friendBoostCount: number,
}

local Coins = {}

-- The list is append-only, so a knock-off can never lower the total.
function Coins.total(absorbedCoinValues: { number }, options: Options): number
	local base = 0
	for _, value in absorbedCoinValues do
		base += value
	end
	local withFriend = base * (if options.hasFriendInServer then 1 + options.friendBonusRate else 1)
	local withBoost = withFriend * (1 + options.friendBoostRate * options.friendBoostCount)
	local withDouble = withBoost * (if options.hasDoubleCoins then 2 else 1)
	return math.floor(withDouble + 0.5)
end

return Coins
