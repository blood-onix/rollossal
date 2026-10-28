--!strict
-- The active world and indexes over its content. Table building only, done once at require time.
-- Config.Flags.SnowVillage picks the world; with it off the game is the grey-box room (rollback).

local Config = require(script.Parent.Config)
local Content = script.Parent.Content
local Layout = require(script.Parent.Rules.Layout)
local Tiers = require(script.Parent.Rules.Tiers)

local GreyBoxRoom = require(Content.GreyBoxRoom)
local SnowVillage = require(Content.Worlds.SnowVillage)

export type WorldDef = GreyBoxRoom.WorldDef
export type ObjectDef = GreyBoxRoom.ObjectDef
export type SizeTierDef = GreyBoxRoom.SizeTierDef
export type LightingDef = GreyBoxRoom.LightingDef

local active: WorldDef = if Config.Flags.SnowVillage then SnowVillage else GreyBoxRoom

local objectById: { [string]: ObjectDef } = {}
local objectByBookId: { [string]: ObjectDef } = {}
local objectsByTier: { [number]: { ObjectDef } } = {}
local sizes: { [string]: number } = {}
for _, object in active.objects do
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

-- Zones expanded by the seeded layout rule, then the hand-placed entries.
local placements: { Layout.Placement } = Layout.expand(active.zones, sizes)
for _, fixed in active.fixedPlacements do
	table.insert(placements, fixed)
end
local placementById: { [string]: Layout.Placement } = {}
for _, placement in placements do
	placementById[placement.id] = placement
end

-- Array invariance: a list of SizeTierDef is not accepted where a list of TierLike is expected.
local tierLikes: { Tiers.TierLike } = {}
for _, tier in active.sizeTiers do
	table.insert(tierLikes, tier)
end

local Worlds = {
	active = active,
	sizeTiers = active.sizeTiers,
	tierLikes = tierLikes,
	starThresholds = active.starThresholds or Config.starThresholds,
	growthK = active.growthK or Config.growthK,
	objectById = objectById,
	objectByBookId = objectByBookId,
	objectsByTier = objectsByTier,
	placements = placements,
	placementById = placementById,
}

return Worlds
