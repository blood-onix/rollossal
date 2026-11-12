--!strict
-- Draws Park City's light objects (Tiers 1 and 2) near the local ball from the shared position data (012 Stage C).
-- The server owns the truth: it validates every claim from its own data and sends LightDelta (indices only). This
-- module only decides what this client draws.
-- 014 (research R-05): each light kind has one template from ObjectVisual (its mesh with the theme atlas, or its
-- role-coloured stand-in) and its own pool of clones, because a MeshPart cannot change mesh. Until a kind's mesh has
-- loaded its slots show the stand-in. At most Config.lightPoolCap slots are visible and at most as many are parked.
-- Flags.LightMeshes off draws 012's tier-coloured blocks.
-- Slot parts carry the attributes BallController reads from pooled world objects and the tag "LightObject".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Light = require(Shared.Rules.Light)
local ObjectVisual = require(Shared.ObjectVisual)
local Tiers = require(Shared.Rules.Tiers)
local Worlds = require(Shared.Worlds)

type ObjectDef = Worlds.ObjectDef

local LIGHT_TAG = "LightObject"
local PARKED = CFrame.new(0, -2000, 0)

local LightField = {}

type Slot = { part: BasePart, index: number?, kind: string, template: BasePart }

local takenSet: { [number]: boolean } = {}
local assigned: { [number]: Slot } = {}
-- Parked slots by kind, and how many there are in all.
local free: { [string]: { Slot } } = {}
local parkedTotal = 0
-- A kind's final template (its mesh, or its stand-in when it has no mesh or the mesh failed), and the stand-in
-- shown while the mesh loads.
local templates: { [string]: BasePart? } = {}
local loadingLooks: { [string]: BasePart? } = {}
local loading = 0
local grid: Light.Grid? = nil
local folder: Instance? = nil

local function tierColour(tier: number): Color3
	return if tier <= 1 then Color3.fromRGB(255, 190, 120) else Color3.fromRGB(150, 210, 150)
end

-- 012's look, for Flags.LightMeshes off: a block of the kind's dims in its tier colour.
local function legacyTemplate(def: ObjectDef): BasePart
	local part = Instance.new("Part")
	local dims = def.dims
	part.Size = if dims then Vector3.new(dims[1], dims[3], dims[2]) else Vector3.one * def.size
	part.Color = tierColour(def.tier)
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function templateFor(kind: string): BasePart
	local ready = templates[kind]
	if ready ~= nil then
		return ready
	end
	local look = loadingLooks[kind]
	if look == nil then
		local def = Worlds.objectById[kind]
		look = if Config.Flags.LightMeshes then ObjectVisual.standIn(def) else legacyTemplate(def)
		loadingLooks[kind] = look
	end
	return look :: BasePart
end

local function newSlot(kind: string, template: BasePart): Slot
	local part = template:Clone()
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.CFrame = PARKED
	part.Name = "L0"
	part:SetAttribute("Taken", true)
	CollectionService:AddTag(part, LIGHT_TAG)
	part.Parent = folder
	return { part = part, index = nil, kind = kind, template = template }
end

-- A parked slot of this kind that shows the kind's current look, or a new clone. A parked stand-in whose mesh has
-- loaded since is destroyed on the way.
local function acquire(kind: string): Slot
	local template = templateFor(kind)
	local list = free[kind]
	while list ~= nil and #list > 0 do
		local slot = table.remove(list) :: Slot
		parkedTotal -= 1
		if slot.template == template then
			return slot
		end
		slot.part:Destroy()
	end
	return newSlot(kind, template)
end

local function release(slot: Slot)
	local index = slot.index
	if index ~= nil then
		assigned[index] = nil
		slot.index = nil
	end
	if parkedTotal >= Config.lightPoolCap then
		slot.part:Destroy()
		return
	end
	local part = slot.part
	part:SetAttribute("Taken", true)
	part.CanTouch = false
	part.CanCollide = false
	part.CFrame = PARKED
	local list = free[slot.kind]
	if list == nil then
		list = {}
		free[slot.kind] = list
	end
	table.insert(list :: { Slot }, slot)
	parkedTotal += 1
end

local function assign(slot: Slot, index: number)
	local data = Worlds.light :: Worlds.LightData
	local at = (index - 1) * data.stride
	local def = Worlds.objectById[slot.kind]
	local part = slot.part
	part.Name = `L{index}`
	part:SetAttribute("Size", def.size)
	part:SetAttribute("Bulk", Worlds.bulkOf(def))
	part:SetAttribute("Longest", def.size)
	part:SetAttribute("Tier", def.tier)
	part:SetAttribute("ObjectId", def.id)
	part:SetAttribute("Taken", false)
	part.CFrame = CFrame.new(
		data.data[at + 2],
		data.data[at + 3] + part.Size.Y / 2,
		data.data[at + 4]
	) * CFrame.Angles(0, data.data[at + 5], 0)
	-- BallController switches collision on by the ball's size; a solid piece (hedge) starts collidable.
	part.CanCollide = def.solid == true
	part.CanTouch = true
	slot.index = index
	assigned[index] = slot
end

local function refresh(position: Vector3, playerTier: number)
	local data = Worlds.light :: Worlds.LightData
	local currentGrid = grid
	if currentGrid == nil then
		return
	end
	local near = Light.query(
		currentGrid,
		data.data,
		data.stride,
		position.X,
		position.Z,
		Config.lightDrawRadius
	)
	local wanted: { { index: number, distance: number } } = {}
	for _, index in near do
		if takenSet[index] then
			continue
		end
		local at = (index - 1) * data.stride
		local def = Worlds.objectById[data.kinds[data.data[at + 1]]]
		if Tiers.isCulled(def.tier, playerTier, Config.cullTierDelta) then
			continue
		end
		local dx, dz = data.data[at + 2] - position.X, data.data[at + 4] - position.Z
		table.insert(wanted, { index = index, distance = dx * dx + dz * dz })
	end
	table.sort(wanted, function(a, b)
		return a.distance < b.distance
	end)
	local shown = math.min(#wanted, Config.lightPoolCap)
	local keep: { [number]: boolean } = {}
	for position_ = 1, shown do
		keep[wanted[position_].index] = true
	end
	-- Release first (farthest out), so the visible total never passes the cap.
	for index, slot in assigned do
		if not keep[index] then
			release(slot)
		end
	end
	for position_ = 1, shown do
		local index = wanted[position_].index
		if assigned[index] == nil then
			local kind = data.kinds[data.data[(index - 1) * data.stride + 1]]
			assign(acquire(kind), index)
		end
	end
end

-- A kind's mesh has loaded: its visible stand-in slots switch to the mesh in place.
local function upgrade(kind: string)
	for index, slot in assigned do
		if slot.kind == kind and slot.template ~= templates[kind] then
			assigned[index] = nil
			slot.part:Destroy()
			assign(acquire(kind), index)
		end
	end
end

-- Builds every light kind's template: stand-ins at once, meshes in the background (CreateMeshPartAsync yields).
local function loadTemplates(data: Worlds.LightData)
	for _, kind in data.kinds do
		local def = Worlds.objectById[kind]
		if not Config.Flags.LightMeshes then
			templates[kind] = legacyTemplate(def)
		elseif def.assetKey == nil then
			templates[kind] = ObjectVisual.standIn(def)
		else
			loading += 1
			task.spawn(function()
				-- ObjectVisual.build falls back to the stand-in (and warns once) if the mesh fails to load.
				local ok, built = pcall(ObjectVisual.build, def)
				templates[kind] = if ok then built else ObjectVisual.standIn(def)
				loading -= 1
				upgrade(kind)
			end)
		end
	end
end

-- A server message: a snapshot replaces the taken set, a delta applies two lists.
function LightField.apply(taken: { number }, restored: { number }, isSnapshot: boolean)
	if isSnapshot then
		table.clear(takenSet)
	end
	for _, index in taken do
		takenSet[index] = true
		local slot = assigned[index]
		if slot then
			release(slot)
		end
	end
	for _, index in restored do
		takenSet[index] = nil
	end
end

-- Test and Studio helpers.
function LightField.poolSize(): number
	local count = parkedTotal
	for _ in assigned do
		count += 1
	end
	return count
end

function LightField.drawnCount(): number
	local count = 0
	for _ in assigned do
		count += 1
	end
	return count
end

function LightField.parkedCount(): number
	return parkedTotal
end

-- How many light kinds are still loading their mesh.
function LightField.loadingCount(): number
	return loading
end

-- Draws the light objects around `position` for a ball of `tier` (the Heartbeat loop calls the same function).
function LightField.refreshAt(position: Vector3, tier: number)
	refresh(position, tier)
end

-- Builds the grid, the slot folder (under `parent`, Workspace by default) and the templates. No remote, no ball:
-- the Studio specs call it directly. Returns false when the world has no light objects.
function LightField.init(parent: Instance?): boolean
	local data = Worlds.light
	if data == nil then
		return false
	end
	grid = Light.buildGrid(data.data, data.stride, data.count, Config.lightCellSize)
	local created = Instance.new("Folder")
	created.Name = "LightField"
	created.Parent = parent or Workspace
	folder = created
	loadTemplates(data)
	return true
end

-- Undoes init: every slot and template is destroyed (Studio specs).
function LightField.reset()
	for _, slot in assigned do
		slot.part:Destroy()
	end
	table.clear(assigned)
	table.clear(free)
	table.clear(takenSet)
	parkedTotal = 0
	for _, map in { templates, loadingLooks } do
		for _, part in map do
			(part :: BasePart):Destroy()
		end
		table.clear(map)
	end
	if folder ~= nil then
		folder:Destroy()
		folder = nil
	end
	grid = nil
end

function LightField.start()
	if not LightField.init() then
		return
	end

	local remote =
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LightDelta") :: RemoteEvent
	remote.OnClientEvent:Connect(function(taken: unknown, restored: unknown, isSnapshot: unknown)
		if typeof(taken) == "table" and typeof(restored) == "table" then
			LightField.apply(taken :: { number }, restored :: { number }, isSnapshot == true)
		end
	end)

	task.spawn(function()
		local ball = Workspace:WaitForChild("Balls")
			:WaitForChild(`Ball_{Players.LocalPlayer.UserId}`)
		local lastAt = Vector3.new(math.huge, 0, 0)
		local timer = 0
		RunService.Heartbeat:Connect(function(dt: number)
			timer += dt
			local position = (ball :: BasePart).Position
			local moved = (position - lastAt).Magnitude >= Config.lightRefreshStuds
			if timer < Config.lightRefreshSeconds and not moved then
				return
			end
			timer = 0
			lastAt = position
			local diameter = ball:GetAttribute("Diameter")
			local tier = Tiers.lookup(
				if typeof(diameter) == "number" then diameter else Worlds.rules.startDiameter,
				Worlds.tierLikes
			)
			refresh(position, tier)
		end)
	end)
end

return LightField
