--!strict
-- Builds Workspace.GreyBoxRoom and owns the 30-cube registry. Time is passed in; no Rules here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GreyBoxRoom = require(Shared.Content.GreyBoxRoom)
local Worlds = require(Shared.Worlds)

export type CubeState = "Available" | "Taken" | "Scattered"

export type RoomCube = {
	id: string,
	tier: number,
	size: number,
	spawnCFrame: CFrame,
	part: BasePart,
	state: CubeState,
	respawnAt: number?,
	availableAt: number?,
	-- Key of the stack entry whose pickup made this cube Taken. Only that entry can release it early.
	holderKey: string?,
}

local WorldSpawner = {}

local registry: { [string]: RoomCube } = {}
local cubeList: { RoomCube } = {}
local started = false

local function makePart(name: string, size: Vector3, cframe: CFrame, colour: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function findTier(tier: number)
	for _, def in GreyBoxRoom.tiers do
		if def.tier == tier then
			return def
		end
	end
	error(`no tier definition for tier {tier}`)
end

local function buildRoom(): Folder
	local halfExtent = GreyBoxRoom.halfExtent
	local wallHeight = GreyBoxRoom.wallHeight
	local wallThickness = 2
	local floorColour = Color3.fromRGB(90, 90, 90)
	local wallColour = Color3.fromRGB(70, 70, 70)

	local room = Instance.new("Folder")
	room.Name = "GreyBoxRoom"

	local floor = makePart(
		"Floor",
		Vector3.new(halfExtent * 2, 1, halfExtent * 2),
		CFrame.new(0, -0.5, 0),
		floorColour
	)
	floor.Parent = room

	local span = halfExtent * 2 + wallThickness * 2
	local walls: { { size: Vector3, cframe: CFrame } } = {
		{
			size = Vector3.new(span, wallHeight, wallThickness),
			cframe = CFrame.new(0, wallHeight / 2, -halfExtent - 1),
		},
		{
			size = Vector3.new(span, wallHeight, wallThickness),
			cframe = CFrame.new(0, wallHeight / 2, halfExtent + 1),
		},
		{
			size = Vector3.new(wallThickness, wallHeight, span),
			cframe = CFrame.new(halfExtent + 1, wallHeight / 2, 0),
		},
		{
			size = Vector3.new(wallThickness, wallHeight, span),
			cframe = CFrame.new(-halfExtent - 1, wallHeight / 2, 0),
		},
	}
	local wallFolder = Instance.new("Folder")
	wallFolder.Name = "Walls"
	wallFolder.Parent = room
	for index, wall in walls do
		local part = makePart("Wall" .. index, wall.size, wall.cframe, wallColour)
		part.Parent = wallFolder
	end

	local kerb = GreyBoxRoom.kerb
	local kerbPart = makePart(
		"Kerb",
		Vector3.new(kerb.length, kerb.height, kerb.depth),
		CFrame.new(kerb.x, kerb.height / 2, kerb.z),
		wallColour
	)
	kerbPart.Parent = room

	local cubeFolder = Instance.new("Folder")
	cubeFolder.Name = "Cubes"
	cubeFolder.Parent = room

	for _, spawn in GreyBoxRoom.cubes do
		local def = findTier(spawn.tier)
		local size = def.size
		local spawnCFrame = CFrame.new(spawn.x, size / 2, spawn.z)
		local part = makePart(
			spawn.id,
			Vector3.one * size,
			spawnCFrame,
			Color3.fromRGB(def.shade, def.shade, def.shade)
		)
		part:SetAttribute("Size", size)
		part:SetAttribute("Tier", spawn.tier)
		part:SetAttribute("Taken", false)
		part.Parent = cubeFolder

		local cube: RoomCube = {
			id = spawn.id,
			tier = spawn.tier,
			size = size,
			spawnCFrame = spawnCFrame,
			part = part,
			state = "Available",
			respawnAt = nil,
			availableAt = nil,
			holderKey = nil,
		}
		registry[spawn.id] = cube
		table.insert(cubeList, cube)
	end

	return room
end

local function buildHub(): Folder
	local hub = Worlds.active.hub
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "Hub"

	local floor = makePart(
		"Floor",
		Vector3.new(hub.halfExtent * 2, 1, hub.halfExtent * 2),
		CFrame.new(hub.center.x, -0.5, hub.center.z),
		Color3.fromRGB(110, 110, 110)
	)
	floor.Parent = hubFolder

	-- A flat disc, rotated so the cylinder's axis points up. Decoration only: no text, no touch.
	local pad = makePart(
		"StartPad",
		Vector3.new(0.2, hub.padRadius * 2, hub.padRadius * 2),
		CFrame.new(hub.center.x + hub.spawn.x, 0.1, hub.center.z + hub.spawn.z)
			* CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(150, 150, 150)
	)
	pad.Shape = Enum.PartType.Cylinder
	pad.CanTouch = false
	pad.Parent = hubFolder

	return hubFolder
end

local function setTaken(cube: RoomCube, taken: boolean)
	local part = cube.part
	part:SetAttribute("Taken", taken)
	part.Transparency = if taken then 1 else 0
	part.CanCollide = not taken
	part.CanTouch = not taken
end

function WorldSpawner.start()
	if started then
		return
	end
	started = true
	local existing = Workspace:FindFirstChild("GreyBoxRoom")
	if existing then
		existing:Destroy()
	end
	buildRoom().Parent = Workspace
	local existingHub = Workspace:FindFirstChild("Hub")
	if existingHub then
		existingHub:Destroy()
	end
	buildHub().Parent = Workspace
end

function WorldSpawner.getCube(id: string): RoomCube?
	return registry[id]
end

function WorldSpawner.getSpawnSlot(index: number): Vector3
	local slots = GreyBoxRoom.spawnSlots
	local wrapped = (index - 1) % slots
	local angle = (wrapped / slots) * math.pi * 2
	local radius = GreyBoxRoom.spawnRingRadius
	return Vector3.new(
		math.cos(angle) * radius,
		Config.startDiameter / 2 + 0.5,
		math.sin(angle) * radius
	)
end

-- Where a ball rests on the hub plaza: the hub centre plus the data offset, just above the floor.
function WorldSpawner.getHubSpawn(): Vector3
	local hub = Worlds.active.hub
	return Vector3.new(
		hub.center.x + hub.spawn.x,
		Config.startDiameter / 2 + 0.5,
		hub.center.z + hub.spawn.z
	)
end

function WorldSpawner.markTaken(cube: RoomCube, now: number, holderKey: string)
	cube.state = "Taken"
	cube.respawnAt = now + Config.respawnDelay
	cube.availableAt = nil
	cube.holderKey = holderKey
	setTaken(cube, true)
end

-- True while the cube is still waiting to respawn from the pickup that created this stack entry.
function WorldSpawner.isHeldBy(cube: RoomCube, holderKey: string): boolean
	return cube.state == "Taken" and cube.holderKey == holderKey
end

function WorldSpawner.scatter(cube: RoomCube, position: Vector3, availableAt: number)
	cube.state = "Scattered"
	cube.availableAt = availableAt
	cube.respawnAt = nil
	cube.holderKey = nil
	setTaken(cube, false)
	cube.part.CFrame = CFrame.new(position.X, cube.size / 2, position.Z)
end

function WorldSpawner.returnToSpawn(cube: RoomCube)
	cube.state = "Available"
	cube.availableAt = nil
	cube.respawnAt = nil
	cube.holderKey = nil
	setTaken(cube, false)
	cube.part.CFrame = cube.spawnCFrame
end

-- Ring of evenly spaced points around centre, clamped inside the room. y is left at 0.
function WorldSpawner.scatterSpots(
	centre: Vector3,
	count: number,
	radius: number,
	startAngle: number
): { Vector3 }
	local limit = GreyBoxRoom.halfExtent - 2
	local spots: { Vector3 } = {}
	for i = 0, count - 1 do
		local angle = startAngle + (i / count) * math.pi * 2
		local x = math.clamp(centre.X + math.cos(angle) * radius, -limit, limit)
		local z = math.clamp(centre.Z + math.sin(angle) * radius, -limit, limit)
		table.insert(spots, Vector3.new(x, 0, z))
	end
	return spots
end

-- Taken cubes respawn after respawnDelay even while a ball still shows them: stack entries are
-- visual-only records, so the room refills (research F-1).
function WorldSpawner.update(now: number)
	for _, cube in cubeList do
		if cube.state == "Scattered" then
			if cube.availableAt and now >= cube.availableAt then
				cube.state = "Available"
				cube.availableAt = nil
			end
		elseif cube.state == "Taken" then
			if cube.respawnAt and now >= cube.respawnAt then
				WorldSpawner.returnToSpawn(cube)
			end
		end
	end
end

function WorldSpawner.registryCounts(): { free: number, pendingRespawn: number }
	local free = 0
	local pendingRespawn = 0
	for _, cube in cubeList do
		if cube.state == "Taken" then
			pendingRespawn += 1
		else
			free += 1
		end
	end
	return { free = free, pendingRespawn = pendingRespawn }
end

-- Test helper: every cube back at its spawn point, available, with no timers.
function WorldSpawner.reset()
	for _, cube in cubeList do
		WorldSpawner.returnToSpawn(cube)
	end
end

return WorldSpawner
