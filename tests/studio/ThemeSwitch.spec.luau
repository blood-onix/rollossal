--!strict
-- 005: the data-only season switch, pinned in Studio (T047). Worlds.forTheme("winter") and
-- Worlds.forTheme("city") must change palette, lighting, weather, music key, slot objects, overlay
-- placements and the hero variants, while every non-slot base placement stays identical — that
-- identity is what makes changing activeThemeId a data-only switch (spec US1, contract §2/§3).
-- 007: nothing here names an object of one world. The slot objects, the overlay objects and the hero
-- variants are read from Worlds.active.themeBindings, so the same spec proves Downtown and Snow Village.
-- The reduce-motion statement is pinned here as far as a server datamodel can see it: the weather
-- controller has not started in this context, so isEmitting() is false; the live emitter toggle is
-- the Studio proof (T038, execute_luau on Client under Play).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Worlds = require(ReplicatedStorage.Shared.Worlds)
local Themes = require(ReplicatedStorage.Shared.Content.Themes)
local Weather = require(ReplicatedStorage.Shared.Rules.Weather)
local WeatherController = require(StarterPlayer.StarterPlayerScripts.WeatherController)

local active: any = Worlds.active
local bindings: any = active.themeBindings

local function slotObjects(resolved: any): { string }
	local ids: { string } = {}
	for _, placement: any in resolved.placements do
		if resolved.slotPlacementIds[placement.id] then
			table.insert(ids, placement.objectId)
		end
	end
	return ids
end

local function idSet(ids: { string }): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, id in ids do
		set[id] = true
	end
	return set
end

local function valueSet(map: { [string]: string }): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, id in map do
		set[id] = true
	end
	return set
end

-- True when a placement comes from the theme's overlay (an overlay zone expands to "<zoneId>_NNN").
local function isOverlay(themeId: string, placementId: string): boolean
	local overlays = bindings[themeId].overlays
	for _, fixed: any in overlays.fixedPlacements do
		if fixed.id == placementId then
			return true
		end
	end
	local zoneId = string.match(placementId, "^(.-)_%d+$")
	for _, zone: any in overlays.zones do
		if zone.id == zoneId then
			return true
		end
	end
	return false
end

local function overlayPlacements(resolved: any, themeId: string): number
	local count = 0
	for _, placement: any in resolved.placements do
		if isOverlay(themeId, placement.id) then
			count += 1
		end
	end
	return count
end

-- Non-slot base placements only: identical across themes is the data-only signature.
local function baseByPlacementId(resolved: any, themeId: string): { [string]: any }
	local byId: { [string]: any } = {}
	for _, placement: any in resolved.placements do
		local isSlot = resolved.slotPlacementIds[placement.id] or false
		if not isSlot and not isOverlay(themeId, placement.id) then
			byId[placement.id] = {
				objectId = placement.objectId,
				x = placement.x,
				y = placement.y,
				z = placement.z,
				yaw = placement.yaw,
				spawnSlot = placement.spawnSlot,
			}
		end
	end
	return byId
end

local function objectIn(resolved: any, objectId: string): any
	for _, object: any in resolved.objects do
		if object.id == objectId then
			return object
		end
	end
	error(`no {objectId} in the resolved objects`)
end

local winter = Worlds.forTheme("winter")
local city = Worlds.forTheme("city")

describe("Worlds.forTheme: winter to city (data-only switch)", function()
	it("resolves both supported themes", function()
		expect(winter.themeId).toBe("winter")
		expect(city.themeId).toBe("city")
	end)

	it("changes the environment palette: the theme roles override the world's", function()
		expect(winter.environmentPalette["w-grass"]).toEqual(Themes.winter.palette["w-grass"])
		expect(city.environmentPalette["w-grass"]).toEqual(Themes.city.palette["w-grass"])
		expect(winter.environmentPalette["w-glow"]).toEqual({ 255, 232, 163 })
		expect(city.environmentPalette["w-glow"]).toEqual({ 255, 243, 176 })
		-- A world-only colour (not a w-* role) survives the switch.
		for name in active.environment.palette do
			if not Themes.winter.palette[name] then
				expect(winter.environmentPalette[name]).toEqual(active.environment.palette[name])
				expect(city.environmentPalette[name]).toEqual(active.environment.palette[name])
			end
		end
	end)

	it("gives city the ground roles (w-grass, w-kerb, w-sidewalk)", function()
		for _, role in { "w-grass", "w-kerb", "w-sidewalk" } do
			expect(city.environmentPalette[role] ~= nil).toBe(true)
			expect(#city.environmentPalette[role]).toBe(3)
		end
	end)

	it("changes the lighting (city 13:00 and brighter than winter at golden hour)", function()
		-- 007: Holiday City moved to 16:30 for the golden-hour look.
		expect(winter.lighting.clockTime).toBe(16.5)
		expect(city.lighting.clockTime).toBe(13)
		expect(winter.lighting.brightness).toBe(2)
		expect(city.lighting.brightness).toBe(3)
	end)

	it("changes the weather (winter snows, city does not)", function()
		expect(Themes.winter.weather.kind).toBe("snow")
		expect(Themes.city.weather.kind).toBe("none")
		expect(Themes.winter.weather.rate).toBe(10)
		expect(Themes.city.weather.rate).toBe(0)
	end)

	it("changes the music key", function()
		expect(Themes.winter.musicAssetKey).toBe("musicWinter")
		expect(Themes.city.musicAssetKey).toBe("musicCity")
	end)

	it(
		"replaces the slot objects with the other theme's, the same number of slot placements",
		function()
			local winterSlots = slotObjects(winter)
			local citySlots = slotObjects(city)
			expect(#winterSlots > 0).toBe(true)
			expect(#citySlots).toBe(#winterSlots)
			expect(idSet(winterSlots)).toEqual(valueSet(bindings.winter.slots))
			expect(idSet(citySlots)).toEqual(valueSet(bindings.city.slots))
		end
	)

	it("swaps the overlay: each theme's overlay objects appear in that theme only", function()
		local function overlayObjects(themeId: string, resolved: any): { [string]: number }
			local counts: { [string]: number } = {}
			for _, placement: any in resolved.placements do
				if isOverlay(themeId, placement.id) then
					counts[placement.objectId] = (counts[placement.objectId] or 0) + 1
				end
			end
			return counts
		end
		local winterOverlay = overlayObjects("winter", winter)
		local cityOverlay = overlayObjects("city", city)
		expect(overlayPlacements(winter, "winter")).toBe(
			#bindings.winter.overlays.fixedPlacements
				+ (function()
					local total = 0
					for _, zone: any in bindings.winter.overlays.zones do
						total += zone.count
					end
					return total
				end)()
		)
		for objectId in winterOverlay do
			expect(cityOverlay[objectId]).toBe(nil)
		end
		for objectId in cityOverlay do
			expect(winterOverlay[objectId]).toBe(nil)
		end
	end)

	it(
		"applies the hero variants: the art changes in the theme that declares one, never the gameplay",
		function()
			local checked = 0
			for themeId, resolved: any in { winter = winter, city = city } do
				local other: any = if themeId == "winter" then city else winter
				for baseId, variant: any in bindings[themeId].heroVariants do
					local varied = objectIn(resolved, baseId)
					local plain = objectIn(other, baseId)
					expect(varied.assetKey).toBe(variant.assetKey)
					expect(plain.assetKey ~= variant.assetKey).toBe(true)
					-- Gameplay identity survives the art swap (contract behaviour 7).
					expect(varied.id).toBe(plain.id)
					expect(varied.tier).toBe(plain.tier)
					expect(varied.size).toBe(plain.size)
					expect(varied.coins).toBe(plain.coins)
					expect(varied.bookId).toBe(plain.bookId)
					checked += 1
				end
			end
			expect(checked > 0).toBe(true)
		end
	)

	it("keeps every non-slot base placement identical across the two themes", function()
		local winterBase = baseByPlacementId(winter, "winter")
		local cityBase = baseByPlacementId(city, "city")

		local winterIds, cityIds: { string } = {}, {}
		for id: string in winterBase do
			table.insert(winterIds, id)
		end
		for id: string in cityBase do
			table.insert(cityIds, id)
		end
		expect(#winterIds > 0).toBe(true)
		expect(#cityIds).toBe(#winterIds)
		expect(idSet(cityIds)).toEqual(idSet(winterIds))
		for id: string in winterBase do
			expect(cityBase[id]).toEqual(winterBase[id])
		end
	end)
end)

describe("WeatherController (unstarted state only)", function()
	it("checks only the unstarted state (no LocalPlayer here)", function()
		-- No LocalPlayer has started the client controller in the datamodel jest runs in, so the
		-- emitter is unstarted and off — the server-side face of "false under ReduceMotion". The
		-- live toggle (attribute on, off within one frame, emitter cleared and restored) is the
		-- Studio proof, recorded against T038.
		expect(WeatherController.start ~= nil).toBe(true)
		expect(typeof(WeatherController.isEmitting)).toBe("function")
		expect(WeatherController.isEmitting()).toBe(false)
		expect(WeatherController.emitterDirection()).toBe(nil)
	end)

	it("moves snow down and neon sparkle up", function()
		-- The emitter's EmissionDirection is set from this motion in applyEnabled. Snow falls
		-- (Bottom), sparkle rises (Top). The live direction is read on Client under Play.
		local snow = Weather.motion(Themes.winter.weather.kind)
		local sparkle = Weather.motion(Themes.neon.weather.kind)
		expect(snow ~= nil and snow.falls).toBe(true)
		expect(sparkle ~= nil and sparkle.falls).toBe(false)
	end)
end)
