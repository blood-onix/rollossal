--!strict
-- The active world and indexes over its content. Table building only, done once at require time.
-- Feature 004 changes the one line that picks the world.

local Config = require(script.Parent.Config)
local Content = script.Parent.Content
local Tiers = require(script.Parent.Rules.Tiers)

local GreyBoxRoom = require(Content.GreyBoxRoom)

export type ObjectDef = GreyBoxRoom.ObjectDef
export type SizeTierDef = GreyBoxRoom.SizeTierDef

local active: GreyBoxRoom.Room = GreyBoxRoom

local objectByTier: { [number]: GreyBoxRoom.ObjectDef } = {}
local objectById: { [string]: GreyBoxRoom.ObjectDef } = {}
local objectByBookId: { [string]: GreyBoxRoom.ObjectDef } = {}
for _, object in active.objects do
	objectByTier[object.tier] = object
	objectById[object.id] = object
	objectByBookId[object.bookId] = object
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
	objectByTier = objectByTier,
	objectById = objectById,
	objectByBookId = objectByBookId,
}

return Worlds
