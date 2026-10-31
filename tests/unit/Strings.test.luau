--!strict
-- Checks src/shared/Localization/Strings.luau: shape, balanced placeholders, the keys the contract
-- lists (copied by hand from contracts/content-and-config.md), and that every literal key used by a
-- client script exists.

local fs = require("@lune/fs")
local harness = require("./harness")
local Strings = require("../../src/shared/Localization/Strings")

local test, expect = harness.test, harness.expect

local contractKeys = {
	"ui.hud.time_label",
	"ui.hud.target_label",
	"ui.hud.star_target",
	"ui.hud.size_label",
	"ui.hud.size_value",
	"ui.hud.next_tier",
	"ui.hud.max_tier",
	"ui.pickup.pop",
	"ui.banner.tier_unlock",
	"ui.bump.label",
	"ui.results.title",
	"ui.results.final_size",
	"ui.results.stars",
	"ui.results.coins",
	"ui.results.new_entries",
	"ui.results.no_new_entries",
	"ui.results.friend_best",
	"ui.results.self_best",
	"ui.results.roll_again",
	"ui.results.back_to_hub",
	"ui.hub.title",
	"ui.hub.play",
	"tier.greybox.1.name",
	"tier.greybox.2.name",
	"tier.greybox.3.name",
	"tier.greybox.4.name",
	"tier.greybox.1.headline",
	"tier.greybox.2.headline",
	"tier.greybox.3.headline",
	"tier.greybox.4.headline",
	"object.greybox.cube_t1",
	"object.greybox.cube_t2",
	"object.greybox.cube_t3",
	"object.greybox.cube_t4",
}

-- Keys added by Feature 003 (contracts/content-and-config.md §Strings): English and Spanish ship together.
local savingKeys = {
	"ui.topbar.book",
	"ui.topbar.shop",
	"ui.topbar.settings",
	"ui.hud.shop_after_run",
	"ui.hud.shop_soon",
	"ui.common.close",
	"ui.book.title",
	"ui.book.page_progress",
	"ui.book.unknown",
	"ui.book.reward",
	"ui.book.reward_earned",
	"ui.book.reward_locked",
	"ui.book.prev",
	"ui.book.next",
	"ui.settings.title",
	"ui.settings.music_volume",
	"ui.settings.effects_volume",
	"ui.settings.camera_sensitivity",
	"ui.settings.reduce_motion",
	"ui.settings.on",
	"ui.settings.off",
	"ui.settings.language",
	"ui.settings.language_auto",
	"ui.settings.language_en_us",
	"ui.settings.language_es_es",
	"ui.settings.percent",
	"ui.hub.coins",
	"ui.hub.best_size",
	"ui.results.coins_total",
	"ui.results.more_entries",
	"ui.results.first_run_tip",
	"reward.greybox.tier1.name",
	"reward.greybox.tier2.name",
	"reward.greybox.tier3.name",
	"reward.greybox.tier4.name",
	"error.profile_load_failed",
	"error.profile_version",
	"error.session_ended",
}

test("Strings: every entry has a non-empty English text", function()
	for key, texts in Strings do
		expect.equal(type(texts.en), "string")
		expect.truthy(#texts.en > 0)
		expect.truthy(#key > 0)
	end
end)

test("Strings: placeholders are balanced and named with letters, digits or underscores", function()
	for key, texts in Strings do
		local depth = 0
		for char in string.gmatch(texts.en, "[{}]") do
			depth += if char == "{" then 1 else -1
			expect.truthy(depth >= 0 and depth <= 1)
		end
		if depth ~= 0 then
			error(`unbalanced braces in {key}`)
		end
		for name in string.gmatch(texts.en, "{([^{}]*)}") do
			expect.truthy(string.match(name, "^[%w_]+$") ~= nil)
		end
	end
end)

test("Strings: every key listed in the contract exists", function()
	for _, key in contractKeys do
		if Strings[key] == nil then
			error(`missing key {key}`)
		end
	end
end)

test("Strings: every key of the saving-and-economy contract exists with Spanish text", function()
	expect.equal(#savingKeys, 38)
	for _, key in savingKeys do
		local entry = Strings[key]
		if entry == nil then
			error(`missing key {key}`)
		end
		expect.truthy(#entry.en > 0)
		if entry.es == nil or #entry.es == 0 then
			error(`missing Spanish text for {key}`)
		end
	end
end)

local function placeholderSet(text: string): { [string]: boolean }
	local names: { [string]: boolean } = {}
	for name in string.gmatch(text, "{([^{}]*)}") do
		names[name] = true
	end
	return names
end

test("Strings: placeholder names are equal between English and Spanish", function()
	for key, texts in Strings do
		if texts.es ~= nil then
			local en, es = placeholderSet(texts.en), placeholderSet(texts.es)
			for name in en do
				if not es[name] then
					error(key .. ": Spanish text lacks {" .. name .. "}")
				end
			end
			for name in es do
				if not en[name] then
					error(key .. ": Spanish text adds {" .. name .. "}")
				end
			end
		end
	end
end)

test("Strings: every Localizer.t literal key used in src/client and src/server exists", function()
	local checked = 0
	for _, folder in { "src/client", "src/server" } do
		for _, name in fs.readDir(folder) do
			if string.match(name, "%.luau$") then
				local source = fs.readFile(`{folder}/{name}`)
				for key in string.gmatch(source, 'Localizer%.t%("([^"]+)"') do
					checked += 1
					if Strings[key] == nil then
						error(`{folder}/{name} uses unknown key {key}`)
					end
				end
			end
		end
	end
	expect.truthy(checked > 0)
end)

-- A key with {placeholders} called without arguments fails to format and shows the raw key on screen.
test(
	"Strings: a Localizer.t call with no arguments never names a key that has placeholders",
	function()
		local checked = 0
		for _, folder in { "src/client", "src/server" } do
			for _, name in fs.readDir(folder) do
				if string.match(name, "%.luau$") then
					local source = fs.readFile(`{folder}/{name}`)
					for key in string.gmatch(source, 'Localizer%.t%("([^"]+)"%)') do
						checked += 1
						local entry = Strings[key]
						if entry ~= nil and string.find(entry.en, "{", 1, true) then
							error(`{folder}/{name} calls {key} without its placeholder arguments`)
						end
					end
				end
			end
		end
		expect.truthy(checked > 0)
	end
)

-- Theme-system keys (005, contracts/theme-content.md §7). The returning labels must never create FOMO:
-- no "limited"/timer wording, in either language (Principle V).
local themeKeys = {
	"theme.city.name",
	"theme.winter.name",
	"theme.spring.name",
	"theme.autumn.name",
	"theme.toon.name",
	"theme.neon.name",
	"object.snow_village.ice_lolly",
	"object.snow_village.beach_ball",
	"object.snow_village.paddling_pool",
	"object.snow_village.ice_cream_truck",
	"object.snow_village.giant_duck",
	"object.snow_village.winter_lights",
	"object.snow_village.beach_towel",
	"object.snow_village.big_snowman_fountain",
	"book.page.snow_village.winter.name",
	"book.page.snow_village.city.name",
}
local returningKeys = {
	"book.page.snow_village.winter.returning",
	"book.page.snow_village.city.returning",
}
local fomoWords = {
	"limited",
	"left",
	"ends",
	"hurry",
	"limitado",
	"quedan",
	"termina",
	"date prisa",
	"última",
	"últimas",
}

test("Strings: every theme-system key exists with English and Spanish", function()
	expect.equal(#themeKeys, 16)
	for _, key in themeKeys do
		local entry = (Strings :: { [string]: { en: string, es: string? } })[key]
		expect.truthy(entry ~= nil, `missing key {key}`)
		expect.truthy(entry ~= nil and entry.en ~= "")
		expect.truthy(entry ~= nil and entry.es ~= nil and entry.es ~= "")
	end
end)

test("Strings: returning labels have no limited or timer wording (Principle V)", function()
	for _, key in returningKeys do
		local entry = (Strings :: { [string]: { en: string, es: string? } })[key]
		expect.truthy(entry ~= nil)
		if entry then
			for _, text in { entry.en, entry.es :: string } do
				local lowered = string.lower(text)
				for _, word in fomoWords do
					expect.truthy(
						string.find(lowered, word, 1, true) == nil,
						`{key}: says the FOMO word {word}`
					)
				end
				expect.truthy(string.match(text, "%d:%d") == nil, `{key}: looks like a timer`)
			end
		end
	end
end)

test(
	"Strings: every Snow Village key exists with English and Spanish and the same placeholders",
	function()
		local SnowVillage = require("../../src/shared/Content/Worlds/SnowVillage")
		local keys: { string } = {}
		for _, object in SnowVillage.objects do
			table.insert(keys, object.nameKey)
		end
		for _, tier in SnowVillage.sizeTiers do
			table.insert(keys, tier.nameKey)
			table.insert(keys, tier.headlineKey)
			if tier.reward then
				table.insert(keys, tier.reward.nameKey)
			end
		end
		expect.equal(#keys, 64 + 5 * 3)
		for _, key in keys do
			local entry = (Strings :: { [string]: { en: string, es: string? } })[key]
			expect.truthy(entry ~= nil)
			expect.truthy(entry ~= nil and entry.en ~= "")
			expect.truthy(entry ~= nil and entry.es ~= nil and entry.es ~= "")
		end
	end
)

-- Feature 006 keys (contracts/content-and-config.md §Strings), written out by hand.
local mechanicsKeys = {
	"ui.fx.dash",
	"ui.fx.magnet",
	"ui.fx.shield",
	"ui.fx.slick_trail",
	"ui.fx.slick",
	"ui.fx.slow",
	"world.booster.dash",
	"world.booster.magnet",
	"world.booster.spring",
	"world.booster.shield",
	"world.booster.slick_trail",
	"world.trap.slick.winter",
	"world.trap.slick.city",
	"world.trap.bumper.winter",
	"world.trap.bumper.city",
	"world.trap.slow.winter",
	"world.trap.slow.city",
	"world.trap.sweeper.winter",
	"world.trap.sweeper.city",
}

test("Strings: every 006 booster, trap and chip key has English and Spanish text", function()
	expect.equal(#mechanicsKeys, 19)
	local restricted = { "buy", "limited", "robux", "price", "comprar", "limitad" }
	for _, key in mechanicsKeys do
		local entry = (Strings :: { [string]: { en: string, es: string? } })[key]
		if entry == nil then
			error(`missing key {key}`)
		end
		expect.truthy(#entry.en > 0)
		if entry.es == nil or #entry.es == 0 then
			error(`missing Spanish text for {key}`)
		end
		for _, word in restricted do
			expect.falsy(string.find(string.lower(entry.en), word, 1, true))
			expect.falsy(string.find(string.lower(entry.es), word, 1, true))
		end
	end
end)

return {}
