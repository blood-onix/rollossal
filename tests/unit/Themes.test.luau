--!strict
-- Data validation for src/shared/Content/Themes.luau (specs/005-theme-art-pipeline/data-model.md §1-2,
-- contracts/theme-content.md §1/§8). Hand-written expectations: the exact 64 + 3 cells per theme must
-- equal docs/design/tokens.json, the lighting derives from the light-* cells, and the weather
-- arithmetic caps live particles at Config.Budgets.maxWeatherParticles.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local Assets = require("../../src/shared/Assets")
local Config = require("../../src/shared/Config")
local Themes = require("../../src/shared/Content/Themes")
local Strings = require("../../src/shared/Localization/Strings")

local test, expect = harness.test, harness.expect

local function hexToRgb(hex: string): { number }
	local text = string.lower(string.gsub(hex, "^#", ""))
	expect.truthy(#text == 6, `bad hex colour {hex}`)
	local values = { string.byte(text, 1, 6) }
	local function digit(byte: number): number
		expect.truthy(byte ~= nil)
		if byte >= 48 and byte <= 57 then
			return byte - 48
		elseif byte >= 97 and byte <= 102 then
			return byte - 87
		end
		error(`bad hex digit in {hex}`)
	end
	return {
		digit(values[1]) * 16 + digit(values[2]),
		digit(values[3]) * 16 + digit(values[4]),
		digit(values[5]) * 16 + digit(values[6]),
	}
end

local tokens = serde.decode("json", fs.readFile("docs/design/tokens.json"))
local tokenThemes = tokens.color.themes
local firstTheme = tokenThemes[1].id

local worldTokens: { [string]: { [string]: { number } } } = {}
local lightCells: { [string]: { [string]: { number } } } = {}
do
	local byName: { [string]: { [string]: { number } } } = {}
	for _, token in tokens.color.tokens do
		local value = token.value
		if type(value) == "table" then
			local perTheme: { [string]: { number } } = {}
			for _, theme in tokenThemes do
				if value[theme.id] ~= nil then
					perTheme[theme.id] = hexToRgb(value[theme.id])
				end
			end
			perTheme._default = hexToRgb(value[firstTheme])
			byName[token.name] = perTheme
		else
			byName[token.name] = { _default = hexToRgb(value :: any) }
		end
	end
	for name, perTheme in byName do
		if string.sub(name, 1, 2) == "w-" then
			worldTokens[name] = perTheme
		elseif string.sub(name, 1, 6) == "light-" then
			lightCells[name] = perTheme
		end
	end
end

local heroCells: { [string]: { [string]: { number } } } = {}
local heroNames: { string } = {}
for _, hero in tokens.color.hero do
	table.insert(heroNames, hero.name)
	if hero.ref ~= nil then
		heroCells[hero.name] = table.clone(worldTokens[hero.ref :: string])
	else
		heroCells[hero.name] = { _default = hexToRgb(hero.value) }
	end
end

local EXPECTED_CELLS: { [string]: { string } } = {}
do
	local names = {}
	for name in worldTokens do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in heroNames do
		table.insert(names, name)
	end
	table.insert(names, "light-sky")
	table.insert(names, "light-fog")
	table.insert(names, "light-ambient")
	table.sort(names)
	for _, theme in tokenThemes do
		EXPECTED_CELLS[theme.id] = names
	end
end

local function rgb(tokenEntry: { [string]: { number } }, theme: string): { number }
	if tokenEntry[theme] ~= nil then
		return tokenEntry[theme]
	end
	expect.truthy(tokenEntry._default ~= nil, `no value for {theme}`)
	return tokenEntry._default :: { number }
end

test("Themes: six themes, unique ids, tokens.json order, data-only shape", function()
	expect.same(Themes.order, { "city", "winter", "spring", "autumn", "toon", "neon" })
	local tokenIds = {}
	for _, theme in tokenThemes do
		table.insert(tokenIds, theme.id)
	end
	expect.same(tokenIds, Themes.order)
	local seen: { [string]: boolean } = {}
	for _, id in Themes.order do
		expect.falsy(seen[id], `duplicate theme id {id}`)
		seen[id] = true
		local theme = (Themes :: any)[id]
		expect.equal(theme.id, id)
		expect.equal(theme.nameKey, `theme.{id}.name`)
		expect.equal(theme.paletteAssetKey, id)
		expect.equal(type(theme.musicAssetKey), "string")
	end
end)

for _, id in Themes.order do
	local theme = (Themes :: any)[id]

	test(
		`Themes: {id} palette has exactly 64 cells + 3 light cells equal to tokens.json`,
		function()
			local palette = theme.palette
			local names = {}
			for name in palette do
				table.insert(names, name)
			end
			table.sort(names)
			expect.same(names, EXPECTED_CELLS[id])
			for name in palette do
				local want
				if string.sub(name, 1, 2) == "w-" then
					want = rgb(worldTokens[name], id)
				elseif string.sub(name, 1, 6) == "light-" then
					want = rgb(lightCells[name], id)
				else
					want = rgb(heroCells[name], id)
				end
				local got = palette[name]
				expect.equal(#got, 3, `{name}: three channels`)
				for channel = 1, 3 do
					expect.equal(got[channel], want[channel], `{id}.{name} channel {channel}`)
				end
			end
		end
	)
end

test("Themes: lighting derives from the light-* cells with sane scalars", function()
	for _, id in Themes.order do
		local theme = (Themes :: any)[id]
		local light = theme.lighting
		local palette = theme.palette
		expect.same(light.ambient, palette["light-ambient"])
		expect.same(light.outdoorAmbient, palette["light-sky"])
		expect.same(light.fogColor, palette["light-fog"])
		expect.same(light.atmosphereColor, palette["light-sky"])
		expect.same(light.atmosphereDecay, palette["light-fog"])
		expect.truthy(light.brightness >= 0 and light.brightness <= 5, `{id} brightness range`)
		expect.truthy(light.clockTime >= 0 and light.clockTime <= 24, `{id} clockTime range`)
		expect.truthy(light.fogEnd > light.fogStart and light.fogStart > 0, `{id} fog range`)
		expect.truthy(
			light.atmosphereDensity >= 0 and light.atmosphereDensity <= 1,
			`{id} atmosphereDensity range`
		)
	end
	expect.equal(Themes.winter.lighting.clockTime, 15.5)
	expect.equal(Themes.city.lighting.clockTime, 13)
end)

local KINDS = { snow = true, petals = true, leaves = true, sparkle = true, none = true }

test("Themes: weather arithmetic caps particles and kinds are the five allowed ones", function()
	for _, id in Themes.order do
		local weather = (Themes :: any)[id].weather
		expect.truthy(KINDS[weather.kind] ~= nil, `{id}: weather kind {weather.kind}`)
		expect.equal(#weather.color, 3)
		if weather.kind == "none" then
			expect.equal(weather.rate, 0)
			expect.equal(weather.maxParticles, 0)
			expect.equal(weather.lifetime, 0)
		else
			expect.truthy(weather.rate > 0 and weather.lifetime > 0)
			expect.truthy(weather.size > 0 and weather.speed >= 0)
		end
		expect.truthy(
			weather.rate * weather.lifetime <= weather.maxParticles,
			`{id}: rate x lifetime must stay within maxParticles`
		)
		expect.truthy(
			weather.maxParticles <= Config.Budgets.maxWeatherParticles,
			`{id}: maxParticles must stay within the config cap`
		)
		expect.equal(math.floor(weather.maxParticles), weather.maxParticles)
	end
	expect.equal(Themes.winter.weather.kind, "snow")
	expect.equal(Themes.city.weather.kind, "none")
	expect.equal(Themes.spring.weather.rate * Themes.spring.weather.lifetime, 40)
end)

test("Themes: every palette asset key, music key and name key resolves", function()
	for _, id in Themes.order do
		local theme = (Themes :: any)[id]
		expect.truthy(Assets.palettes[theme.paletteAssetKey] ~= nil, `{id}: Assets.palettes key`)
		expect.truthy(
			Assets.sounds[theme.musicAssetKey] ~= nil,
			`{id}: Assets.sounds key {theme.musicAssetKey}`
		)
		local entry = (Strings :: { [string]: { en: string, es: string? } })[theme.nameKey]
		expect.truthy(entry ~= nil and entry.en ~= "", `{id}: Strings key`)
	end
end)
