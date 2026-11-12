--!strict
-- The active world and indexes over its content. Table building only, done once at require time.
-- Config.Flags.Downtown picks Downtown; with it off Config.Flags.SnowVillage picks Snow Village; with both off
-- the game is the grey-box room (rollback).
-- 005: the active theme resolves once, here. Worlds.resolved carries the themed palette, slot objects
-- and overlays; Worlds.active stays the base world (specs/005-theme-art-pipeline/data-model.md §6).
-- With Config.Flags.ThemeSystem off the theme still resolves (the base zones name slots and cannot be
-- placed without it); only the theme's lighting, weather and music are withheld. The base world's
-- own lighting then applies.

local Config = require(script.Parent.Config)
local Content = script.Parent.Content
local Absorb = require(script.Parent.Rules.Absorb)
local Doorstep = require(script.Parent.Rules.Doorstep)
local Layout = require(script.Parent.Rules.Layout)
local Tiers = require(script.Parent.Rules.Tiers)
local Movement = require(script.Parent.Rules.Movement)
local ThemeResolve = require(script.Parent.Rules.ThemeResolve)
local Themes = require(Content.Themes)

local GreyBoxRoom = require(Content.GreyBoxRoom)
local SnowVillage = require(Content.Worlds.SnowVillage)
local Downtown = require(Content.Worlds.Downtown)
-- Park City (012) is generated data; required only when its flag is on.
local ParkCity = if Config.Flags.ParkCity then require(Content.Worlds.ParkCity) else nil

export type WorldDef = GreyBoxRoom.WorldDef
export type ObjectDef = GreyBoxRoom.ObjectDef
export type BlockDef = GreyBoxRoom.BlockDef
export type SceneryDef = GreyBoxRoom.SceneryDef
export type SizeTierDef = GreyBoxRoom.SizeTierDef
export type LightingDef = GreyBoxRoom.LightingDef
export type ThemeBookPage = GreyBoxRoom.ThemeBookPage
export type ThemePageWithObjects = ThemeBookPage & {
	themeId: string,
	objects: { ObjectDef },
}

local active: WorldDef = if Config.Flags.Downtown
	then Downtown :: any
	elseif Config.Flags.SnowVillage then SnowVillage :: any
	else GreyBoxRoom

-- Park City (012) replaces whichever world the chain above picked. 014: the rows named in slotRows (the Plaza
-- landmark) become theme slots and slotPlacements (the memes) are added, so the theme resolve below maps them.
if ParkCity ~= nil then
	local park = table.clone(ParkCity) :: any
	local slotRows: { [string]: string } = park.slotRows or {}
	local fixed: { any } = {}
	for _, row in require(Content.Worlds.ParkCityParts) :: { any } do
		local slot = slotRows[row.id]
		if slot ~= nil then
			row = table.clone(row)
			row.objectId = slot
		end
		table.insert(fixed, row)
	end
	local slotPlacements: { any } = park.slotPlacements or {}
	for _, row in slotPlacements do
		table.insert(fixed, row)
	end
	-- Fun slice: small food for the food flow to place (Config.Flow.stock), parked out of sight until it is used.
	if Config.Slice.enabled and Config.Flow.enabled then
		local flow = Config.Flow
		local index = 0
		for _, entry in flow.stock do
			for _ = 1, entry.count do
				table.insert(fixed, {
					id = `flow-{index + 1}`,
					objectId = entry.kind,
					x = flow.stockOrigin.x + (index % flow.stockPerRow) * flow.stockSpacing,
					y = flow.stockOrigin.y,
					z = flow.stockOrigin.z + (index // flow.stockPerRow) * flow.stockSpacing,
					yaw = 0,
				})
				index += 1
			end
		end
	end
	park.fixedPlacements = fixed :: any
	-- Fun slice: the generated map has no booster spots yet, so the section gets a few here (Config.Slice.boosters).
	if Config.Slice.enabled then
		local environment = table.clone(park.environment)
		local markers = table.clone(environment.markers or {})
		for index, spot in Config.Slice.boosters do
			table.insert(markers, {
				id = `slice-booster-{index}`,
				kind = "BoosterSpot",
				subKind = spot.kind,
				x = spot.x,
				y = 0,
				z = spot.z,
				yaw = spot.yaw or 0,
				waypoints = nil,
			})
		end
		environment.markers = markers
		park.environment = environment
	end
	active = park :: any
end

local function sizeMap(objects: { ObjectDef }): { [string]: number }
	local sizes: { [string]: number } = {}
	for _, object in objects do
		sizes[object.id] = object.size
	end
	return sizes
end

-- The active theme (contract theme-content.md §3): active.activeThemeId, whatever the flag says.
local activeThemeId: string? = active.activeThemeId
local activeTheme = if activeThemeId ~= nil then (Themes :: any)[activeThemeId :: string] else nil

-- Resolve the active theme once. Worlds without a theme keep their base zones, objects and lighting.
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
	if Config.Flags.ThemeSystem then
		themed.lighting = (activeTheme :: any).lighting :: any
	end
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

-- Park City light objects (Tiers 1 and 2) are data: row i of the flat array is the light id "L"..i.
export type LightData = {
	stride: number,
	count: number,
	kinds: { string },
	ranges: { [string]: { number } },
	data: { number },
}
local light: LightData? = if ParkCity ~= nil then require(Content.Worlds.ParkCityLight) else nil

-- The kind (ObjectDef id) of a light id such as "L12", or nil.
local function lightKind(id: string): string?
	local current = light
	if current == nil then
		return nil
	end
	local digits = string.match(id, "^L(%d+)$")
	local index = if digits then tonumber(digits) else nil
	if index == nil or index < 1 or index > current.count then
		return nil
	end
	return current.kinds[current.data[(index - 1) * current.stride + 1]]
end

-- 012 Stage A: Downtown's readable-rules table (six tiers, bulk rule, dims) replaces its numbers.
local readable = if Config.Flags.ReadableRules then active.readableRules else nil
if readable ~= nil then
	local rule: Absorb.Rule = (readable.rules.absorb :: any) :: Absorb.Rule
	local tiersForLookup: { Tiers.TierLike } = {}
	for _, tier in readable.sizeTiers do
		table.insert(tiersForLookup, tier)
	end
	local objects: { ObjectDef } = {}
	local needs: { [string]: number } = {}
	for _, object in resolved.objects do
		local copy = table.clone(object)
		local dims = readable.dims[object.id]
		local bulk = object.size
		if dims ~= nil then
			copy.dims = dims
			bulk = Absorb.bulkOf(dims)
			copy.bulk = bulk
			copy.size = math.max(dims[1], dims[2], dims[3])
		end
		needs[object.id] = Absorb.needsDiameter(rule, bulk, copy.size)
		copy.tier = Tiers.lookup(needs[object.id], tiersForLookup)
		table.insert(objects, copy)
	end
	local overlay = table.clone(resolved)
	overlay.objects = objects
	overlay.sizeTiers = readable.sizeTiers
	overlay.starThresholds = readable.starThresholds
	overlay.growthK = readable.rules.growthK
	overlay.rules = readable.rules
	worldPlacements = Doorstep.clear(
		worldPlacements,
		(active.spawnPoints :: any) :: { Doorstep.Spawn },
		needs,
		readable.rules.startDiameter or Config.startDiameter,
		readable.doorstepClearRadius
	)
	resolved = overlay
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
for _, tier in resolved.sizeTiers do
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
		if page.reward ~= nil then
			error(
				`Worlds: theme {themeId} bookPage {page.id} declares a reward; theme page rewards are not granted before 006a`,
				2
			)
		end
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

local worldRules: GreyBoxRoom.RulesDef = resolved.rules or {}
local growthK: number = worldRules.growthK or resolved.growthK or Config.growthK

-- The rules every gameplay read goes through (012 R3). With no `rules` table each field is today's Config value.
export type Rules = {
	startDiameter: number,
	growthK: number,
	absorb: Absorb.Rule,
	speedCap: Movement.SpeedCapRule,
	cameraMinDistance: number,
}
local rules: Rules = {
	startDiameter = worldRules.startDiameter or Config.startDiameter,
	growthK = growthK,
	absorb = (worldRules.absorb :: any) or { mode = "size", ratio = Config.absorbRatio },
	speedCap = (worldRules.speedCap :: any) or {
		base = Config.speedCap,
		fromDiameter = math.huge,
		slope = 0,
		max = Config.speedCap,
	},
	cameraMinDistance = worldRules.cameraMinDistance or Config.cameraMinDistance,
}
table.freeze(rules)

-- Bulk and longest side of an object def; a def without dims is a cube of its size.
local function bulkOf(def: ObjectDef): number
	return def.bulk or def.size
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
	sizeTiers = resolved.sizeTiers,
	tierLikes = tierLikes,
	starThresholds = resolved.starThresholds or Config.starThresholds,
	growthK = growthK,
	rules = rules,
	bulkOf = bulkOf,
	light = light,
	lightKind = lightKind,
	objectById = objectById,
	objectByBookId = objectByBookId,
	objectsByTier = objectsByTier,
	sizes = sizes,
	placements = worldPlacements,
	placementById = placementById,
}

return Worlds
