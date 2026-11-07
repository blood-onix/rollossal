--!strict
-- Keeps a spawn's doorstep open (012 Stage A). Under a stricter absorb rule a new ball can be boxed in by objects it
-- cannot eat yet; this drops the doorstep objects within `radius` of a spawn that need more than the start diameter.

local Doorstep = {}

export type Spawn = { x: number, z: number }
export type Item = { objectId: string, x: number, z: number, spawnSlot: number? }

-- True when the placement is a doorstep object (it has a spawn slot) standing within radius of one of the spawns and
-- needing a bigger ball than the start diameter. `needs` maps an object id to the diameter that can eat it.
function Doorstep.blocks(
	item: Item,
	spawns: { Spawn },
	needs: { [string]: number },
	startDiameter: number,
	radius: number
): boolean
	if item.spawnSlot == nil or (needs[item.objectId] or 0) <= startDiameter then
		return false
	end
	for _, spawn in spawns do
		local dx, dz = item.x - spawn.x, item.z - spawn.z
		if dx * dx + dz * dz <= radius * radius then
			return true
		end
	end
	return false
end

-- The placements with the blocking doorstep objects removed. Order is kept.
function Doorstep.clear<T>(
	placements: { T },
	spawns: { Spawn },
	needs: { [string]: number },
	startDiameter: number,
	radius: number
): { T }
	local kept = {}
	for _, placement in placements do
		if not Doorstep.blocks(placement :: any, spawns, needs, startDiameter, radius) then
			table.insert(kept, placement)
		end
	end
	return kept
end

return Doorstep
