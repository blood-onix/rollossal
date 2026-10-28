--!strict
-- The numbers the Blender scripts need, taken from Config and the Snow Village data so there is one source of
-- truth. Blender cannot read Luau. scripts/art-sync.luau writes this to art/scripts/budgets.json and
-- tests/unit/ArtManifest.test.luau fails when the committed file is stale. Contract:
-- specs/004-snow-village/contracts/art-pipeline.md "Budget source".

local Config = require("../src/shared/Config")
local SnowVillage = require("../src/shared/Content/Worlds/SnowVillage")

export type Budgets = {
	meshTriangles: { number },
	sizes: { [string]: number },
	tiers: { [string]: number },
}

local ArtBudgets = {}

function ArtBudgets.build(): Budgets
	local sizes: { [string]: number } = {}
	local tiers: { [string]: number } = {}
	for _, object in SnowVillage.objects do
		sizes[object.id] = object.size
		tiers[object.id] = object.tier
	end
	-- The hub is modelled to the top tier's triangle budget and has no size rule of its own.
	tiers.hub = #Config.Budgets.meshTriangles
	local triangles: { number } = {}
	for index, count in Config.Budgets.meshTriangles do
		triangles[index] = count
	end
	return { meshTriangles = triangles, sizes = sizes, tiers = tiers }
end

return ArtBudgets
