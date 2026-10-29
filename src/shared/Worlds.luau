--!strict
-- The active world and indexes over its content. Table building only, done once at require time.
-- Config.Flags.SnowVillage picks the world; with it off the game is the grey-box room (rollback).
-- 005: the active theme resolves once, here. Worlds.resolved carries the themed palette, lighting,
-- slot objects and overlays; Worlds.active stays the base world (specs/005-theme-art-pipeline/
-- data-model.md §6). With Config.Flags.ThemeSystem off the resolved world IS the base world, which
-- is the rollback for the whole feature.

local Config = require(script.Parent.Config)
local Content = script.Parent.Content
local Layout = require(script.Parent.Rules.Layout)
local Tiers = require(script.Parent.Rules.Tiers)
local ThemeResolve = require(script.Parent.Rules.ThemeResolve)
local Themes = require(Content.Themes)

local GreyBoxRoom = require(Content.GreyBoxRoom)
local SnowVillage = require(Content.Worlds.SnowVillage)

export type WorldDef = GreyBoxRoom.WorldDef
export type ObjectDef = GreyBoxRoom.ObjectDef
export type SizeTierDef = GreyBoxRoom.SizeTierDef
export type LightingDef = GreyBoxRoom.LightingDef
export type ThemeBookPage = GreyBoxRoom.ThemeBookPage
export type ThemePageWithObjects = ThemeBookPage & {
	themeId: string,
	objects: { ObjectDef },
}

local active: WorldDef = if Config.Flags.SnowVillage then SnowVillage else GreyBoxRoom

local function sizeMap(objects: { ObjectDef }): { [string]: number }
	local sizes: { [string]: number } = {}
	for _, object in objects do
		sizes[object.id] = object.size
	end
	return sizes
end

-- The active theme (contract theme-content.md §3): active.activeThemeId when the flag is on.
local themeOn = Config.Flags.ThemeSystem ~= false and active.activeThemeId ~= nil
local activeThemeId: string? = if themeOn then active.activeThemeId :: string else nil
local activeTheme = if activeThemeId ~= nil then (Themes :: any)[activeThemeId :: string] else nil

-- Resolve the active theme once. Without a theme the base world is used exactly as it is, so the
-- pre-005 behaviour (and the rollback flag) needs no resolution at all.
local resolved: WorldDef = active
local worldPlacements: { Layout.Placement }
if activeTheme ~= nil then
	local result = ThemeResolve.resolve(
		active :: any,
		activeTheme :: any,
		Layout.expand,
		Config.Budgets.defaultMaxPlacements
	)
	local themed = table.clone(active)
	themed.objects = result.objects :: any
	themed.zones = result.zones :: any
	themed.fixedPlacements = result.fixedPlacements :: any
	themed.lighting = (activeTheme :: any).lighting :: any
	local environment = table.clone(active.environment)
	environment.palette = result.environmentPalette :: any
	themed.environment = environment
	resolved = themed :: WorldDef
	worldPlacements = result.placements :: any
else
	worldPlacements = Layout.expand(active.zones :: any, sizeMap(active.objects))
	for _, fixed in active.fixedPlacements do
		table.insert(worldPlacements, fixed)
	end
end

local objectById: { [string]: ObjectDef } = {}
local objectByBookId: { [string]: ObjectDef } = {}
local objectsByTier: { [number]: { ObjectDef } } = {}
local sizes: { [string]: number } = {}
for _, object in resolved.objects do
	objectById[object.id] = object
	objectByBookId[object.bookId] = object
	sizes[object.id] = object.size
	local list = objectsByTier[object.tier]
	if list == nil then
		list = {}
		objectsByTier[object.tier] = list
	end
	table.insert(list :: { ObjectDef }, object)
end

local placementById: { [string]: Layout.Placement } = {}
for _, placement in worldPlacements do
	placementById[placement.id] = placement
end

-- Array invariance: a list of SizeTierDef is not accepted where a list of TierLike is expected.
local tierLikes: { Tiers.TierLike } = {}
for _, tier in active.sizeTiers do
	table.insert(tierLikes, tier)
end

-- One book page per supported theme that declares one. Every page carries the ObjectDefs it lists,
-- active or not, so a returning season can still show names and icons (contract
-- theme-content.md §3); the ids are already validated when the world data is written.
local themeBookPages: { ThemePageWithObjects } = {}
local supportedList: { string } = if active.supportedThemes ~= nil
	then active.supportedThemes :: { string }
	else {}
for _, themeId in supportedList do
	local binding = (active.themeBindings :: any)[themeId]
	local page = if binding ~= nil then binding.bookPage else nil
	if page ~= nil then
		local pageObjects: { ObjectDef } = {}
		for _, objectId in page.objectIds do
			local def: ObjectDef? = objectById[objectId]
			if def == nil and binding.objects ~= nil then
				for _, bObject in binding.objects do
					if bObject.id == objectId then
						def = bObject
						break
					end
				end
			end
			if def ~= nil then
				table.insert(pageObjects, def :: ObjectDef)
			end
		end
		table.insert(
			themeBookPages,
			{
				id = page.id,
				nameKey = page.nameKey,
				returningKey = page.returningKey,
				reward = page.reward,
				themeId = themeId,
				objectIds = page.objectIds,
				objects = pageObjects,
			} :: any
		)
	end
end

local Worlds = {
	active = active,
	resolved = resolved,
	activeThemeId = activeThemeId,
	activeTheme = activeTheme,
	-- Resolves any supported theme on demand (Studio specs, QA); a thin wrapper over
	-- Rules/ThemeResolve.resolve (plan deviation D2).
	forTheme = function(themeId: string): ThemeResolve.Resolved
		local theme = (Themes :: any)[themeId]
		if theme == nil then
			error(`Worlds: unknown theme {themeId}`, 2)
		end
		return ThemeResolve.resolve(
			active :: any,
			theme :: any,
			Layout.expand,
			Config.Budgets.defaultMaxPlacements
		)
	end,
	baseObjects = active.objects,
	themeBookPages = themeBookPages,
	sizeTiers = active.sizeTiers,
	tierLikes = tierLikes,
	starThresholds = active.starThresholds or Config.starThresholds,
	growthK = active.growthK or Config.growthK,
	objectById = objectById,
	objectByBookId = objectByBookId,
	objectsByTier = objectsByTier,
	sizes = sizes,
	placements = worldPlacements,
	placementById = placementById,
}

return Worlds
