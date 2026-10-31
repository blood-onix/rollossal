--!strict
-- 005: the data-only season switch, pinned in Studio (T047). Worlds.forTheme("winter") and
-- Worlds.forTheme("city") must change palette, lighting, weather, music key, slot objects, overlay
-- placements and the hero variant, while every non-slot base placement stays identical — that
-- identity is what makes changing activeThemeId a data-only switch (spec US1, contract §2/§3).
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

local SLOT_OBJECT_IDS_WINTER = { "bauble", "gift_box", "snowman", "sleigh", "skating_rink" }
local SLOT_OBJECT_IDS_CITY = {
	"ice_lolly",
	"beach_ball",
	"paddling_pool",
	"ice_cream_truck",
	"giant_duck",
}
local SLOT_PLACEMENT_COUNT = 32 -- small 12 + medium 8 + yard 6 + street 4 + landmark 2
local OVERLAY_COUNT = 6 -- each overlay zone places 6 stand-ins

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

local function overlayCount(resolved: any, objectId: string): number
	local count = 0
	for _, placement: any in resolved.placements do
		if not resolved.slotPlacementIds[placement.id] and placement.objectId == objectId then
			count += 1
		end
	end
	return count
end

-- Non-slot base placements only: identical across themes is the data-only signature.
local function baseByPlacementId(resolved: any): { [string]: any }
	local byId: { [string]: any } = {}
	for _, placement: any in resolved.placements do
		local isSlot = resolved.slotPlacementIds[placement.id] or false
		local isOverlay = string.sub(placement.id, 1, 6) == "sv_ol_"
		if not isSlot and not isOverlay then
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

local winter = Worlds.forTheme("winter")
local city = Worlds.forTheme("city")

describe("Worlds.forTheme: winter to city (data-only switch)", function()
	it("resolves both supported themes", function()
		expect(winter.themeId).toBe("winter")
		expect(city.themeId).toBe("city")
	end)

	it("changes the environment palette, ground swatch included", function()
		-- The ground blocks pick their colour from the legacy "snow" swatch: white snow in winter,
		-- the w-grass green in city.
		expect(winter.environmentPalette["snow"]).toEqual({ 255, 255, 255 })
		expect(city.environmentPalette["snow"]).toEqual({ 111, 191, 74 })
		expect(winter.environmentPalette["w-glow"]).toEqual({ 255, 232, 163 })
		expect(city.environmentPalette["w-glow"]).toEqual({ 255, 243, 176 })
	end)

	it("gives city the ground roles (w-grass, w-kerb, w-sidewalk)", function()
		for _, role in { "w-grass", "w-kerb", "w-sidewalk" } do
			expect(city.environmentPalette[role] ~= nil).toBe(true)
			expect(#city.environmentPalette[role]).toBe(3)
		end
	end)

	it("changes the lighting (city 13:00 and brighter than winter 15:30)", function()
		expect(winter.lighting.clockTime).toBe(15.5)
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

	it("replaces the slot objects with the city stand-ins, 32 slot placements in both", function()
		local winterSlots = slotObjects(winter)
		local citySlots = slotObjects(city)
		expect(#winterSlots).toBe(SLOT_PLACEMENT_COUNT)
		expect(#citySlots).toBe(SLOT_PLACEMENT_COUNT)
		expect(idSet(winterSlots)).toEqual(idSet(SLOT_OBJECT_IDS_WINTER))
		expect(idSet(citySlots)).toEqual(idSet(SLOT_OBJECT_IDS_CITY))
	end)

	it("swaps the overlay: winter lights in winter, beach towels in city, never both", function()
		expect(overlayCount(winter, "winter_lights")).toBe(OVERLAY_COUNT)
		expect(overlayCount(winter, "beach_towel")).toBe(0)
		-- Six from the overlay zone, plus the one fixed towel the city theme places by hand.
		expect(overlayCount(city, "beach_towel")).toBe(OVERLAY_COUNT + 1)
		expect(overlayCount(city, "winter_lights")).toBe(0)
	end)

	it("applies the hero variant: big_snowman becomes the fountain in city only", function()
		local function bigSnowman(resolved: any): any
			for _, object: any in resolved.objects do
				if object.id == "big_snowman" then
					return object
				end
			end
			error("no big_snowman in the resolved objects")
		end

		local winterSnowman = bigSnowman(winter)
		local citySnowman = bigSnowman(city)
		expect(winterSnowman.assetKey).toBe("big_snowman")
		expect(citySnowman.assetKey).toBe("fountain")
		expect(citySnowman.nameKey).toBe("object.snow_village.big_snowman_fountain")
		-- Gameplay identity survives the art swap (contract behaviour 7).
		expect(citySnowman.id).toBe("big_snowman")
		expect(citySnowman.tier).toBe(4)
		expect(citySnowman.size).toBe(12)
		expect(citySnowman.coins).toBe(winterSnowman.coins)
		expect(citySnowman.bookId).toBe(winterSnowman.bookId)
	end)

	it("keeps every non-slot base placement identical across the two themes", function()
		local winterBase = baseByPlacementId(winter)
		local cityBase = baseByPlacementId(city)

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
