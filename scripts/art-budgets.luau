--!strict
-- The numbers the Blender scripts need, taken from Config and the world data so there is one source of truth.
-- Blender cannot read Luau. scripts/art-sync.luau writes this to art/scripts/budgets.json and
-- tests/unit/ArtManifest.test.luau fails when the committed file is stale. Contract:
-- specs/004-snow-village/contracts/art-pipeline.md "Budget source", generalised to both worlds by
-- specs/007-downtown-holiday-city/contracts/rules-and-code.md §7: the union of the Snow Village objects (keyed
-- by id) and the Downtown objects (keyed dt_<id>, theme-only objects and hero variants included), plus the hub.
-- 013 adds the city asset kit (keyed ck_<id>, world "city_kit").

local Config = require("../src/shared/Config")
local SnowVillage = require("../src/shared/Content/Worlds/SnowVillage")
local Downtown = require("../src/shared/Content/Worlds/Downtown")
local CityKit = require("../src/shared/Content/CityKit")

export type Budgets = {
	meshTriangles: { number },
	sizes: { [string]: number },
	tiers: { [string]: number },
}

export type MeshEntry = { key: string, tier: number, size: number, world: string }

local ArtBudgets = {}

-- Every mesh the two worlds ask for, in a stable order: Snow Village first, then Downtown (core, then the theme
-- kits and the hero variants). A variant has its base object's tier and its declared size.
function ArtBudgets.meshes(): { MeshEntry }
	local entries: { MeshEntry } = {}
	for _, object in SnowVillage.objects do
		table.insert(
			entries,
			{ key = object.id, tier = object.tier, size = object.size, world = "snow_village" }
		)
	end
	local function addDowntown(object: { assetKey: string?, tier: number, size: number })
		table.insert(entries, {
			key = object.assetKey :: string,
			tier = object.tier,
			size = object.size,
			world = "downtown",
		})
	end
	for _, object in Downtown.objects do
		addDowntown(object)
	end
	local baseById: { [string]: { tier: number, size: number } } = {}
	for _, object in Downtown.objects do
		baseById[object.id] = object
	end
	for _, themeId in Downtown.supportedThemes do
		local binding = (Downtown.themeBindings :: any)[themeId]
		for _, object in binding.objects or {} do
			addDowntown(object)
		end
		for baseId, variant in binding.heroVariants do
			local base = baseById[baseId]
			addDowntown({
				assetKey = variant.assetKey,
				tier = base.tier,
				size = variant.size or base.size,
			})
		end
	end
	-- The city asset kit (013): ck_* keys, a third key set disjoint from the other two.
	for _, object in CityKit.objects do
		table.insert(entries, {
			key = object.assetKey :: string,
			tier = object.tier,
			size = object.size,
			world = "city_kit",
		})
	end
	return entries
end

function ArtBudgets.build(): Budgets
	local sizes: { [string]: number } = {}
	local tiers: { [string]: number } = {}
	for _, entry in ArtBudgets.meshes() do
		sizes[entry.key] = entry.size
		tiers[entry.key] = entry.tier
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
