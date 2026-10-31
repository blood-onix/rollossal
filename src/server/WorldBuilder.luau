--!strict
-- Builds Workspace.World from the active world's data: static geometry, the hub, marker spots, lighting, one
-- template per object type and one pooled part per placement. Contract: specs/004-snow-village/contracts/runtime-api.md.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Hazards = require(Shared.Content.Hazards)
local Boosters = require(Shared.Rules.Boosters)
local Layout = require(Shared.Rules.Layout)
local Traps = require(Shared.Rules.Traps)
local ObjectVisual = require(Shared.ObjectVisual)
local Worlds = require(Shared.Worlds)

type WorldDef = Worlds.WorldDef
type LightingDef = Worlds.LightingDef
type ObjectDef = Worlds.ObjectDef

export type BuiltObject = { placement: Layout.Placement, part: BasePart }
export type BuiltWorld = { objects: { BuiltObject }, geometryCount: number }

local OBJECT_TAG = "WorldObject"
local RING_HEIGHT = 0.4
local PATCH_HEIGHT = 0.2
local BUMPER_HEIGHT = 3
local SWEEPER_HEIGHT = 3
local FALLBACK_GREY = Color3.fromRGB(150, 150, 150)
local HUB_FLOOR_THICKNESS = 1
local PAD_THICKNESS = 0.2
local ATMOSPHERE_NAME = "WorldAtmosphere"
local DEFAULT_HUB_FLOOR = { 110, 110, 110 }
local DEFAULT_HUB_PAD = { 150, 150, 150 }
-- Authored footprint of art/export/hub.fbx in studs (the hub has no ObjectDef size rule).
local HUB_LONGEST_SIDE = 12.75

local WorldBuilder = {}

local templates: { [string]: BasePart? } = {}
local builtParts = 0

local function colour(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function folder(name: string, parent: Instance): Folder
	local created = Instance.new("Folder")
	created.Name = name
	created.Parent = parent
	return created
end

local function staticPart(name: string, size: Vector3, cframe: CFrame, tint: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = tint
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function buildGeometry(world: WorldDef, parent: Folder): number
	local palette = world.environment.palette
	local count = 0
	for _, block in world.environment.blocks do
		local swatch = palette[block.swatch]
		if swatch == nil then
			error(`WorldBuilder: block {block.id} uses unknown swatch {block.swatch}`)
		end
		local at = block.cframe
		local cframe = CFrame.new(at.x, at.y, at.z) * CFrame.Angles(0, math.rad(at.yaw), 0)
		local size = Vector3.new(block.size.x, block.size.y, block.size.z)
		local part: BasePart
		if block.kind == "Wedge" then
			local wedge = Instance.new("WedgePart")
			wedge.Name = block.id
			wedge.Anchored = true
			wedge.Size = size
			wedge.CFrame = cframe
			wedge.Color = colour(swatch)
			wedge.Material = Enum.Material.SmoothPlastic
			wedge.Transparency = 0
			wedge.TopSurface = Enum.SurfaceType.Smooth
			wedge.BottomSurface = Enum.SurfaceType.Smooth
			part = wedge
		else
			local block3d = staticPart(block.id, size, cframe, colour(swatch))
			if block.kind == "Cylinder" then
				block3d.Shape = Enum.PartType.Cylinder
			end
			part = block3d
		end
		part.Parent = parent
		count += 1
	end
	return count
end

local function dressingColour(world: WorldDef, row: HazardRow, themeId: string): Color3
	local dressing = row.dressing[themeId]
	local rgb = if dressing then world.environment.palette[dressing.colourRole] else nil
	return if rgb then colour(rgb) else FALLBACK_GREY
end

type HazardRow = {
	subKind: string,
	footprint: { w: number, d: number },
	dressing: { [string]: Hazards.Dressing },
}

local function findRow(isBooster: boolean, subKind: string): HazardRow?
	if isBooster then
		for _, row in Hazards.boosters do
			if row.subKind == subKind then
				return row
			end
		end
	else
		for _, row in Hazards.traps do
			if row.subKind == subKind then
				return row
			end
		end
	end
	return nil
end

local function markerPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	tint: Color3,
	solid: boolean
): Part
	local part = staticPart(name, size, cframe, tint)
	part.CanCollide = solid
	part.CanTouch = false
	part.CanQuery = solid
	return part
end

-- Grey-box visuals for the booster and trap markers (006, research R-15): primitive parts coloured from the
-- active theme's palette roles. A booster or trap whose flags are off is not built at all.
local function buildMarkers(world: WorldDef, parent: Folder, themeId: string): number
	local count = 0
	local builtPatrol = Workspace:GetServerTimeNow()
	for _, marker in world.environment.markers do
		local yaw = CFrame.Angles(0, math.rad(marker.yaw), 0)
		local isBooster = marker.kind == "BoosterSpot"
		local row = findRow(isBooster, marker.subKind)
		if row == nil then
			error(`WorldBuilder: marker {marker.id} has unknown sub-kind {marker.subKind}`)
		end
		local live = if isBooster
			then Boosters.enabled(Config.Flags, marker.subKind)
			else Traps.enabled(Config.Flags, marker.subKind)
		if not live then
			continue
		end
		local tint = dressingColour(world, row, themeId)
		local footprint = row.footprint
		local part: Part
		if isBooster then
			-- A flat ring: a cylinder lying on its side, its axis pointing up.
			part = markerPart(
				marker.id,
				Vector3.new(RING_HEIGHT, footprint.w, footprint.d),
				CFrame.new(marker.x, marker.y + RING_HEIGHT / 2, marker.z)
					* yaw
					* CFrame.Angles(0, 0, math.pi / 2),
				tint,
				false
			)
			part.Shape = Enum.PartType.Cylinder
			part:SetAttribute("SubKind", marker.subKind)
			part:SetAttribute("Taken", false)
			CollectionService:AddTag(part, "BoosterSpot")
		elseif marker.subKind == "slick" or marker.subKind == "slow" then
			part = markerPart(
				marker.id,
				Vector3.new(footprint.w, PATCH_HEIGHT, footprint.d),
				CFrame.new(marker.x, marker.y + PATCH_HEIGHT / 2, marker.z) * yaw,
				tint,
				false
			)
			part:SetAttribute("Kind", marker.subKind)
			part:SetAttribute("HalfX", footprint.w / 2)
			part:SetAttribute("HalfZ", footprint.d / 2)
			part:SetAttribute("Yaw", marker.yaw)
			part:SetAttribute("OwnerUserId", 0)
			CollectionService:AddTag(part, "TrapSurface")
		elseif marker.subKind == "bumper" then
			-- A cylinder's long axis is X, so the post stands up when rotated; its diameter is Size.Y and Z.
			part = markerPart(
				marker.id,
				Vector3.new(BUMPER_HEIGHT, footprint.w, footprint.d),
				CFrame.new(marker.x, marker.y + BUMPER_HEIGHT / 2, marker.z)
					* CFrame.Angles(0, 0, math.pi / 2),
				tint,
				true
			)
			part.Shape = Enum.PartType.Cylinder
			part:SetAttribute("Kind", "bumper")
			part:SetAttribute("Radius", footprint.w / 2)
			part:SetAttribute("Height", BUMPER_HEIGHT)
			CollectionService:AddTag(part, "TrapHazard")
		else
			-- The sweeper: long side along its travel (local Z). Only the clients move it.
			part = markerPart(
				marker.id,
				Vector3.new(footprint.d, SWEEPER_HEIGHT, footprint.w),
				CFrame.new(marker.x, marker.y + SWEEPER_HEIGHT / 2, marker.z) * yaw,
				tint,
				true
			)
			part:SetAttribute("Kind", "sweeper")
			part:SetAttribute("PatrolEpoch", builtPatrol)
			part:SetAttribute("Speed", Config.sweeperSpeed)
			local waypoints: { { x: number, z: number } } = marker.waypoints or {}
			part:SetAttribute("WpCount", #waypoints)
			for index, point in waypoints do
				part:SetAttribute(`Wp{index}X`, point.x)
				part:SetAttribute(`Wp{index}Z`, point.z)
			end
			CollectionService:AddTag(part, "TrapHazard")
		end
		part:SetAttribute("MarkerId", marker.id)
		part.Parent = parent
		count += 1
	end
	return count
end

local function buildHub(world: WorldDef, parent: Folder)
	local hub = world.hub
	local palette = world.environment.palette
	local floorTint = colour(palette.hub_floor or DEFAULT_HUB_FLOOR)
	local padTint = colour(palette.hub_pad or DEFAULT_HUB_PAD)
	local floor = staticPart(
		"Floor",
		Vector3.new(hub.halfExtent * 2, HUB_FLOOR_THICKNESS, hub.halfExtent * 2),
		CFrame.new(hub.center.x, -HUB_FLOOR_THICKNESS / 2, hub.center.z),
		floorTint
	)
	floor.Parent = parent

	-- A flat disc, rotated so the cylinder's axis points up. Decoration only: no text, no touch.
	local pad = staticPart(
		"StartPad",
		Vector3.new(PAD_THICKNESS, hub.padRadius * 2, hub.padRadius * 2),
		CFrame.new(hub.center.x + hub.spawn.x, PAD_THICKNESS / 2, hub.center.z + hub.spawn.z)
			* CFrame.Angles(0, 0, math.pi / 2),
		padTint
	)
	pad.Shape = Enum.PartType.Cylinder
	pad.CanTouch = false
	pad.Parent = parent
end

function WorldBuilder.applyLighting(lighting: LightingDef)
	Lighting.Ambient = colour(lighting.ambient)
	Lighting.OutdoorAmbient = colour(lighting.outdoorAmbient)
	Lighting.Brightness = lighting.brightness
	Lighting.ClockTime = lighting.clockTime
	Lighting.FogColor = colour(lighting.fogColor)
	Lighting.FogStart = lighting.fogStart
	Lighting.FogEnd = lighting.fogEnd

	-- A place has at most one Atmosphere that counts, so reuse the one it already has.
	local settings = Lighting:FindFirstChildOfClass("Atmosphere")
	if settings == nil then
		settings = Instance.new("Atmosphere")
		settings.Name = ATMOSPHERE_NAME
		settings.Parent = Lighting
	end
	settings.Density = lighting.atmosphereDensity
	settings.Color = colour(lighting.atmosphereColor)
	settings.Decay = colour(lighting.atmosphereDecay)
end

-- One template per object type, built on first use (a mesh template yields while the asset loads).
local function templateFor(def: ObjectDef): BasePart
	local existing = templates[def.id]
	if existing then
		return existing
	end
	local built = ObjectVisual.build(def)
	templates[def.id] = built
	return built
end

function WorldBuilder.getTemplate(objectId: string): BasePart
	local template = templates[objectId]
	if template == nil then
		error(`WorldBuilder: no template for object {objectId}`)
	end
	return template
end

-- Pooled parts plus static geometry, for the part budget check.
function WorldBuilder.partCount(): number
	return builtParts
end

-- Idempotent: a previous Workspace.World is destroyed first. Yields while meshes load, so call it once,
-- before any ball exists.
function WorldBuilder.start(
	world: WorldDef,
	placements: { Layout.Placement },
	themeId: string?
): BuiltWorld
	local existing = Workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	table.clear(templates)

	local root = Instance.new("Folder")
	root.Name = "World"
	local geometry = folder("Geometry", root)
	local objectsFolder = folder("Objects", root)
	local hub = folder("Hub", root)
	local markers = folder("Markers", root)

	local geometryCount = buildGeometry(world, geometry)
	buildHub(world, hub)
	local markerCount = buildMarkers(world, markers, themeId or world.activeThemeId or "winter")

	local defs: { [string]: ObjectDef } = {}
	for _, def in world.objects do
		defs[def.id] = def
	end

	-- Mesh templates load in parallel: built one after another, 64 asset loads take longer than the 5 s the
	-- clients wait for their ball before WaitForChild warns.
	local pending = 0
	local failure: string? = nil
	for _, def in world.objects do
		pending += 1
		task.spawn(function()
			local ok, err = pcall(templateFor, def)
			if not ok and failure == nil then
				failure = tostring(err)
			end
			pending -= 1
		end)
	end
	local hubMesh: MeshPart? = nil
	pending += 1
	task.spawn(function()
		local ok, result =
			pcall(ObjectVisual.buildMesh, world.hub.assetKey, "hub", HUB_LONGEST_SIDE)
		if ok then
			hubMesh = result
		else
			warn(`[Rollossal] Hub mesh failed to build, the hub stays bare: {result}`)
		end
		pending -= 1
	end)
	while pending > 0 do
		task.wait()
	end
	if failure ~= nil then
		error(failure)
	end
	if hubMesh then
		hubMesh.Name = "HubMesh"
		hubMesh.Anchored = true
		hubMesh.CFrame = CFrame.new(world.hub.center.x, hubMesh.Size.Y / 2, world.hub.center.z)
		hubMesh.Parent = hub
	end

	local objects: { BuiltObject } = {}
	for _, placement in placements do
		local def = defs[placement.objectId]
		if def == nil then
			error(
				`WorldBuilder: placement {placement.id} names unknown object {placement.objectId}`
			)
		end
		local part = templateFor(def):Clone()
		part.Name = placement.id
		part.Anchored = true
		part.CFrame = CFrame.new(placement.x, placement.y + part.Size.Y / 2, placement.z)
			* CFrame.Angles(0, placement.yaw, 0)
		part:SetAttribute("Size", def.size)
		part:SetAttribute("Tier", def.tier)
		part:SetAttribute("ObjectId", def.id)
		part:SetAttribute("Taken", false)
		CollectionService:AddTag(part, OBJECT_TAG)
		part.Parent = objectsFolder
		table.insert(objects, { placement = placement, part = part })
	end

	root.Parent = Workspace
	-- Edit-mode runs (the Studio specs) build the world without touching the place's own lighting.
	if world.lighting and RunService:IsRunning() then
		WorldBuilder.applyLighting(world.lighting)
	end
	builtParts = geometryCount + #objects + markerCount
	return { objects = objects, geometryCount = geometryCount }
end

return WorldBuilder
