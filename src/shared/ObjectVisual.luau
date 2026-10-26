--!strict
-- Builds the template part for one object type: a MeshPart when its asset id is imported, otherwise a plain
-- stand-in part of the same size. Used by the server (pooled world objects) and the client (stuck visuals).
-- Plan R8: layout, gameplay and tests never wait for art.

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

local function colourFor(def: ObjectDef): Color3
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
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- The imported mesh scaled so its longest side is ObjectDef.size, or nil with a one-time warning.
local function meshPart(def: ObjectDef): MeshPart?
	local assetKey = def.assetKey
	local contentId = if assetKey then Assets.meshes[assetKey] else nil
	if contentId == nil or contentId == "" then
		return nil
	end
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(contentId :: any)
	end)
	if not ok then
		warnOnce(def.id, tostring(result))
		return nil
	end
	local mesh = result :: MeshPart
	local longest = math.max(mesh.Size.X, mesh.Size.Y, mesh.Size.Z)
	if longest > 0 and math.abs(longest - def.size) > def.size * SIZE_TOLERANCE then
		mesh.Size = mesh.Size * (def.size / longest)
	end
	if Assets.palette ~= "" then
		mesh.TextureID = Assets.palette
	end
	return mesh
end

-- A fresh, unparented template. May yield when a mesh id is set; callers cache the result per object id.
function ObjectVisual.build(def: ObjectDef): BasePart
	return meshPart(def) or standIn(def)
end

return ObjectVisual
