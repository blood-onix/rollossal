--!strict
-- Shared helpers for the Studio specs: pick placements from the active world by object type, so no spec
-- names a literal placement id (contracts/runtime-api.md "Studio test seams").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Worlds = require(ReplicatedStorage.Shared.Worlds)

local Fixtures = {}

-- The ids of the first `count` placements of an object type, in layout order. Errors when the world has fewer.
function Fixtures.ids(objectId: string, count: number): { string }
	local found: { string } = {}
	for _, placement in Worlds.placements do
		if placement.objectId == objectId then
			table.insert(found, placement.id)
			if #found == count then
				return found
			end
		end
	end
	error(`Fixtures: only {#found} placements of {objectId}, wanted {count}`)
end

-- The ids of the first `count` placements of any object of exactly `size` studs (0.5 is eatable from the start,
-- 0.8 sits on the 0.4 * 2 limit), in layout order. Worlds name their small objects differently, so the specs ask
-- for a size instead of a name (007).
function Fixtures.idsOfSize(size: number, count: number): { string }
	local found: { string } = {}
	for _, placement in Worlds.placements do
		local object = Worlds.objectById[placement.objectId]
		if object ~= nil and object.size == size then
			table.insert(found, placement.id)
			if #found == count then
				return found
			end
		end
	end
	error(`Fixtures: only {#found} placements of size {size}, wanted {count}`)
end

-- The object a placement stands for.
function Fixtures.objectOf(placementId: string): Worlds.ObjectDef
	local placement = Worlds.placementById[placementId]
	assert(placement, `Fixtures: no placement {placementId}`)
	local object = Worlds.objectById[placement.objectId]
	assert(object, `Fixtures: placement {placementId} names unknown object {placement.objectId}`)
	return object
end

-- The first object type of a tier, as listed in the world data.
function Fixtures.firstOfTier(tier: number): Worlds.ObjectDef
	local list = Worlds.objectsByTier[tier]
	assert(list and list[1], `Fixtures: no object in tier {tier}`)
	return list[1]
end

-- One placement of the first object of a tier: too big to eat at the start diameter for tiers 2 and up.
function Fixtures.ofTier(tier: number): string
	return Fixtures.ids(Fixtures.firstOfTier(tier).id, 1)[1]
end

return Fixtures
