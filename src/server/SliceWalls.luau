--!strict
-- Fun slice: fences play to one section of the map (Config.Slice) with four see-through walls. The rest of the map
-- stays built and visible behind them; nothing is removed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local THICKNESS = 4
local COLOUR = Color3.fromRGB(120, 220, 255)
local TRANSPARENCY = 0.82

local SliceWalls = {}

local function wall(parent: Instance, name: string, size: Vector3, position: Vector3)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.ForceField
	part.Color = COLOUR
	part.Transparency = TRANSPARENCY
	part.Size = size
	part.Position = position
	part.Parent = parent
end

function SliceWalls.start()
	local slice = Config.Slice
	if not slice.enabled or not Config.Flags.ParkCity then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SliceWalls"
	local height = slice.wallHeight
	local width = slice.maxX - slice.minX
	local depth = slice.maxZ - slice.minZ
	local midX = (slice.minX + slice.maxX) / 2
	local midZ = (slice.minZ + slice.maxZ) / 2
	local y = height / 2 - THICKNESS
	wall(
		folder,
		"West",
		Vector3.new(THICKNESS, height, depth),
		Vector3.new(slice.minX - THICKNESS / 2, y, midZ)
	)
	wall(
		folder,
		"East",
		Vector3.new(THICKNESS, height, depth),
		Vector3.new(slice.maxX + THICKNESS / 2, y, midZ)
	)
	wall(
		folder,
		"North",
		Vector3.new(width, height, THICKNESS),
		Vector3.new(midX, y, slice.minZ - THICKNESS / 2)
	)
	wall(
		folder,
		"South",
		Vector3.new(width, height, THICKNESS),
		Vector3.new(midX, y, slice.maxZ + THICKNESS / 2)
	)
	folder.Parent = Workspace
end

return SliceWalls
