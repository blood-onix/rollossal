--!strict
-- Draws Park City's light objects (Tiers 1 and 2) near the local ball from the shared position data, into a pool of
-- Parts (012 Stage C). The server owns the truth: it validates every claim from its own data and sends LightDelta
-- (indices only). This module only decides what this client draws.
-- Pool parts carry the attributes BallController reads from pooled world objects and the tag "LightObject".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Light = require(Shared.Rules.Light)
local Tiers = require(Shared.Rules.Tiers)
local Worlds = require(Shared.Worlds)

local LIGHT_TAG = "LightObject"
local PARKED = CFrame.new(0, -2000, 0)

local LightField = {}

type Slot = { part: BasePart, index: number? }

local takenSet: { [number]: boolean } = {}
local pool: { Slot } = {}
local assigned: { [number]: Slot } = {}
local grid: Light.Grid? = nil
local folder: Folder? = nil

local function newSlot(): Slot
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = PARKED
	part.Name = "L0"
	part:SetAttribute("Taken", true)
	CollectionService:AddTag(part, LIGHT_TAG)
	part.Parent = folder
	return { part = part, index = nil }
end

local function release(slot: Slot)
	local index = slot.index
	if index ~= nil then
		assigned[index] = nil
		slot.index = nil
	end
	local part = slot.part
	part:SetAttribute("Taken", true)
	part.CanTouch = false
	part.CanCollide = false
	part.CFrame = PARKED
end

local function tierColour(tier: number): Color3
	return if tier <= 1 then Color3.fromRGB(255, 190, 120) else Color3.fromRGB(150, 210, 150)
end

local function assign(slot: Slot, index: number)
	local data = Worlds.light :: Worlds.LightData
	local at = (index - 1) * data.stride
	local def = Worlds.objectById[data.kinds[data.data[at + 1]]]
	local part = slot.part
	local dims = def.dims
	local size = if dims then Vector3.new(dims[1], dims[3], dims[2]) else Vector3.one * def.size
	part.Size = size
	part.Color = tierColour(def.tier)
	part.Name = `L{index}`
	part:SetAttribute("Size", def.size)
	part:SetAttribute("Bulk", Worlds.bulkOf(def))
	part:SetAttribute("Longest", def.size)
	part:SetAttribute("Tier", def.tier)
	part:SetAttribute("ObjectId", def.id)
	part:SetAttribute("Taken", false)
	part.CFrame = CFrame.new(data.data[at + 2], data.data[at + 3] + size.Y / 2, data.data[at + 4])
		* CFrame.Angles(0, data.data[at + 5], 0)
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
	local keep: { [number]: boolean } = {}
	for position_ = 1, math.min(#wanted, Config.lightPoolCap) do
		keep[wanted[position_].index] = true
	end
	for index, slot in assigned do
		if not keep[index] then
			release(slot)
		end
	end
	local free: { Slot } = {}
	for _, slot in pool do
		if slot.index == nil then
			table.insert(free, slot)
		end
	end
	for position_ = 1, math.min(#wanted, Config.lightPoolCap) do
		local index = wanted[position_].index
		if assigned[index] == nil then
			local slot: Slot? = table.remove(free)
			if slot == nil then
				if #pool >= Config.lightPoolCap then
					break
				end
				local created = newSlot()
				table.insert(pool, created)
				slot = created
			end
			assign(slot :: Slot, index)
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
	return #pool
end

function LightField.drawnCount(): number
	local count = 0
	for _ in assigned do
		count += 1
	end
	return count
end

function LightField.start()
	local data = Worlds.light
	if data == nil then
		return
	end
	grid = Light.buildGrid(data.data, data.stride, data.count, Config.lightCellSize)
	local created = Instance.new("Folder")
	created.Name = "LightField"
	created.Parent = Workspace
	folder = created

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
