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

test("Strings: every Localizer.t literal key used in src/client exists", function()
	local checked = 0
	for _, name in fs.readDir("src/client") do
		if string.match(name, "%.luau$") then
			local source = fs.readFile(`src/client/{name}`)
			for key in string.gmatch(source, 'Localizer%.t%("([^"]+)"') do
				checked += 1
				if Strings[key] == nil then
					error(`{name} uses unknown key {key}`)
				end
			end
		end
	end
	expect.truthy(checked > 0)
end)

return {}
