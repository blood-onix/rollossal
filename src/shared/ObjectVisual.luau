--!strict
-- Builds the template part for one object type: a MeshPart when its asset id is imported, otherwise a plain
-- stand-in part of the same size. Used by the server (pooled world objects) and the client (stuck visuals).
-- Layout, gameplay and tests never wait for art.
-- 005: the texture comes from the active theme's atlas (contracts/theme-content.md §6); stand-ins take
-- their Colour from the theme palette at the object's w-* role, else the tier Colour.

local AssetService = game:GetService("AssetService")

local Assets = require(script.Parent.Assets)
local Worlds = require(script.Parent.Worlds)

type ObjectDef = Worlds.ObjectDef

local SIZE_TOLERANCE = 0.05
-- Stand-in colours by tier (placeholder look, replaced by the palette texture once meshes are imported).
local TIER_COLOURS: { Color3 } = {
	Color3.fromRGB(255, 190, 120),
	Color3.fromRGB(150, 210, 150),
	Color3.fromRGB(130, 180, 235),
	Color3.fromRGB(235, 140, 140),
	Color3.fromRGB(200, 160, 235),
}

local ObjectVisual = {}

local warned: { [string]: boolean } = {}

local function warnOnce(objectId: string, reason: string)
	if not warned[objectId] then
		warned[objectId] = true
		warn(`[Rollossal] {objectId}: using the stand-in part ({reason})`)
	end
end

-- The mesh texture: the active theme's atlas when the meshes are atlas-era, else the legacy shared
-- palette. Never both. "" means no TextureID at all (contracts/theme-content.md §6).
local function textureId(): string
	local theme = Worlds.activeTheme
	if
		Assets.meshUv == "atlas"
		and theme ~= nil
		and Assets.palettes[theme.paletteAssetKey] ~= ""
	then
		return Assets.palettes[theme.paletteAssetKey]
	elseif Assets.meshUv == "legacy" and Assets.palette ~= "" then
		return Assets.palette
	end
	return ""
end

local function colourFor(def: ObjectDef): Color3
	local theme = Worlds.activeTheme
	local role = def.role
	if theme ~= nil and role ~= nil then
		local cell = theme.palette[role]
		if cell ~= nil then
			return Color3.fromRGB(cell[1], cell[2], cell[3])
		end
	end
	local shade = def.shade
	if shade then
		return Color3.fromRGB(shade, shade, shade)
	end
	return TIER_COLOURS[math.clamp(def.tier, 1, #TIER_COLOURS)]
end

local function standIn(def: ObjectDef): Part
	local part = Instance.new("Part")
	local shape = def.fallback or "Block"
	part.Shape = if shape == "Ball"
		then Enum.PartType.Ball
		elseif shape == "Cylinder" then Enum.PartType.Cylinder
		else Enum.PartType.Block
	part.Size = Vector3.one * def.size
	part.Color = colourFor(def)
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Fidelity rules (contracts/theme-content.md §6): automatic rendering, hull collision for the big
-- tiers, box for the rest. Never a SurfaceAppearance, a light, or a Transparency above 0.
local function fidelity(mesh: MeshPart, tier: number?)
	mesh.RenderFidelity = Enum.RenderFidelity.Automatic
	mesh.CollisionFidelity = if tier ~= nil and tier >= 4
		then Enum.CollisionFidelity.Hull
		else Enum.CollisionFidelity.Box
end

-- The imported mesh scaled so its longest side is `longestSide`, or nil with a one-time warning.
-- `tier` (1-5) selects the collision fidelity; nil (the hub) keeps Box.
function ObjectVisual.buildMesh(
	assetKey: string?,
	label: string,
	longestSide: number,
	tier: number?
): MeshPart?
	local contentId = if assetKey then Assets.meshes[assetKey] else nil
	if contentId == nil or contentId == "" then
		return nil
	end
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(contentId :: any)
	end)
	if not ok then
		warnOnce(label, tostring(result))
		return nil
	end
	local mesh = result :: MeshPart
	local longest = math.max(mesh.Size.X, mesh.Size.Y, mesh.Size.Z)
	if longest > 0 and math.abs(longest - longestSide) > longestSide * SIZE_TOLERANCE then
		mesh.Size = mesh.Size * (longestSide / longest)
	end
	local id = textureId()
	if id ~= "" then
		mesh.TextureID = id
	end
	fidelity(mesh, tier)
	return mesh
end

-- A fresh, unparented template. May yield when a mesh id is set; callers cache the result per object id.
function ObjectVisual.build(def: ObjectDef): BasePart
	return ObjectVisual.buildMesh(def.assetKey, def.id, def.size, def.tier) or standIn(def)
end

return ObjectVisual
