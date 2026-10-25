--!strict
-- Every player-facing string, keyed. Data only: no Roblox APIs, so Lune can validate it.
-- Placeholders use {name}. English is complete; Spanish arrives with Feature 007.
-- Key list: specs/002-run-loop/contracts/content-and-config.md

local Strings: { [string]: { en: string } } = {
	["ui.hud.time_label"] = { en = "Time" },
	["ui.hud.target_label"] = { en = "Target" },
	["ui.hud.star_target"] = { en = "{stars} star: {size}" },
	["ui.hud.size_label"] = { en = "Size" },
	["ui.hud.size_value"] = { en = "{size}" },
	["ui.hud.next_tier"] = { en = "Next: {icon} {headline}" },
	["ui.hud.max_tier"] = { en = "Biggest size reached" },
	["ui.pickup.pop"] = { en = "+ {name}" },
	["ui.banner.tier_unlock"] = { en = "You can roll up: {headline}!" },
	["ui.bump.label"] = { en = "Bump!" },
	["ui.results.title"] = { en = "Time's up!" },
	["ui.results.final_size"] = { en = "Final size: {size}" },
	["ui.results.stars"] = { en = "{stars} of 3 stars" },
	["ui.results.coins"] = { en = "Coins: {coins}" },
	["ui.results.new_entries"] = { en = "New in your book: {count}" },
	["ui.results.no_new_entries"] = { en = "No new book entries" },
	["ui.results.friend_best"] = { en = "Best friend size: {size}" },
	["ui.results.self_best"] = { en = "Your best size: {size}" },
	["ui.results.roll_again"] = { en = "Roll again" },
	["ui.results.back_to_hub"] = { en = "Back to hub" },
	["ui.hub.title"] = { en = "Ready to roll?" },
	["ui.hub.play"] = { en = "Play" },
	["tier.greybox.1.name"] = { en = "Tiny" },
	["tier.greybox.2.name"] = { en = "Small" },
	["tier.greybox.3.name"] = { en = "Medium" },
	["tier.greybox.4.name"] = { en = "Large" },
	["tier.greybox.1.headline"] = { en = "TINY CUBES" },
	["tier.greybox.2.headline"] = { en = "SMALL CUBES" },
	["tier.greybox.3.headline"] = { en = "MEDIUM CUBES" },
	["tier.greybox.4.headline"] = { en = "LARGE CUBES" },
	["object.greybox.cube_t1"] = { en = "Tiny cube" },
	["object.greybox.cube_t2"] = { en = "Small cube" },
	["object.greybox.cube_t3"] = { en = "Medium cube" },
	["object.greybox.cube_t4"] = { en = "Large cube" },
}

return Strings
