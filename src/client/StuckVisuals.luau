--!strict
-- Client-only visuals for the stuck cubes of every ball. Driven by the server's Stuck attribute.
-- "Weld" re-seats the visuals through Weld.C1 on growth; "Follower" sets their CFrame each frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local GreyBoxRoom = require(Shared.Content.GreyBoxRoom)

type Visual = {
	part: BasePart,
	dir: Vector3,
	weld: Weld?,
}

type BallRecord = {
	ball: BasePart,
	visuals: { [string]: Visual },
}

local StuckVisuals = {}

local records: { [BasePart]: BallRecord } = {}
local cubesFolder: Folder? = nil
local visualFolder: Folder? = nil

local function shadeOf(tier: number): number
	for _, def in GreyBoxRoom.tiers do
		if def.tier == tier then
			return def.shade
		end
	end
	return 128
end

-- Entries are `key,dx,dy,dz` with key `<cubeId>#<n>`, unique per pickup; the cube id is the part
-- before `#`. Visuals are keyed by key, so a cube eaten twice shows twice.
local function parseStuck(text: string): { { key: string, id: string, dir: Vector3 } }
	local entries = {}
	for segment in string.gmatch(text, "[^;]+") do
		local key, dx, dy, dz =
			string.match(segment, "^([^,]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)$")
		local x, y, z = tonumber(dx), tonumber(dy), tonumber(dz)
		local id = key and string.match(key, "^([^#]+)")
		if key and id and x and y and z then
			table.insert(entries, { key = key, id = id, dir = Vector3.new(x, y, z) })
		end
	end
	local first = math.max(1, #entries - Config.maxVisibleStuck + 1)
	local visible = {}
	for index = first, #entries do
		table.insert(visible, entries[index])
	end
	return visible
end

local function offsetFor(ball: BasePart, visual: Visual, size: number): Vector3
	local radius = ball.Size.X / 2
	local direction = if visual.dir.Magnitude > 0 then visual.dir.Unit else Vector3.yAxis
	return direction * (radius + size * Config.stuckEmbed)
end

local function createVisual(record: BallRecord, key: string, id: string, dir: Vector3): Visual?
	local folder = visualFolder
	local cubes = cubesFolder
	if not folder or not cubes then
		return nil
	end
	local cube = cubes:FindFirstChild(id)
	if not cube then
		return nil
	end
	local size = cube:GetAttribute("Size")
	local tier = cube:GetAttribute("Tier")
	if typeof(size) ~= "number" or typeof(tier) ~= "number" then
		return nil
	end

	local part = Instance.new("Part")
	part.Name = `Stuck_{record.ball.Name}_{key}`
	part.Size = Vector3.one * size
	part.Color = Color3.fromRGB(shadeOf(tier), shadeOf(tier), shadeOf(tier))
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Parent = folder

	local visual: Visual = { part = part, dir = dir, weld = nil }
	if Config.stuckVisualMode == "Weld" then
		local weld = Instance.new("Weld")
		weld.Part0 = record.ball
		weld.Part1 = part
		weld.C0 = CFrame.identity
		weld.C1 = CFrame.new(-offsetFor(record.ball, visual, size))
		weld.Parent = part
		visual.weld = weld
	else
		part.CFrame = record.ball.CFrame * CFrame.new(offsetFor(record.ball, visual, size))
	end
	return visual
end

local function sizeOf(visual: Visual): number
	return visual.part.Size.X
end

local function reseat(record: BallRecord)
	for _, visual in record.visuals do
		if visual.weld then
			visual.weld.C1 = CFrame.new(-offsetFor(record.ball, visual, sizeOf(visual)))
		end
	end
end

local function sync(record: BallRecord)
	local raw = record.ball:GetAttribute("Stuck")
	local wanted: { [string]: { id: string, dir: Vector3 } } = {}
	if typeof(raw) == "string" then
		for _, entry in parseStuck(raw) do
			wanted[entry.key] = { id = entry.id, dir = entry.dir }
		end
	end

	for key, visual in record.visuals do
		if not wanted[key] then
			visual.part:Destroy()
			record.visuals[key] = nil
		end
	end
	for key, entry in wanted do
		if not record.visuals[key] then
			local visual = createVisual(record, key, entry.id, entry.dir)
			if visual then
				record.visuals[key] = visual
			end
		end
	end
end

local function untrack(ball: BasePart)
	local record = records[ball]
	if not record then
		return
	end
	for _, visual in record.visuals do
		visual.part:Destroy()
	end
	records[ball] = nil
end

local function track(instance: Instance)
	if not instance:IsA("BasePart") or records[instance] then
		return
	end
	local record: BallRecord = { ball = instance, visuals = {} }
	records[instance] = record
	instance:GetAttributeChangedSignal("Stuck"):Connect(function()
		sync(record)
	end)
	instance:GetPropertyChangedSignal("Size"):Connect(function()
		reseat(record)
	end)
	sync(record)
end

function StuckVisuals.start()
	local ballsFolder = Workspace:WaitForChild("Balls")
	local room = Workspace:WaitForChild("GreyBoxRoom")
	cubesFolder = room:WaitForChild("Cubes") :: Folder

	local folder = Instance.new("Folder")
	folder.Name = "StuckVisuals"
	folder.Parent = Workspace
	visualFolder = folder

	ballsFolder.ChildAdded:Connect(track)
	ballsFolder.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("BasePart") then
			untrack(child)
		end
	end)
	for _, child in ballsFolder:GetChildren() do
		track(child)
	end

	RunService.RenderStepped:Connect(function()
		if Config.stuckVisualMode ~= "Follower" then
			return
		end
		for _, record in records do
			for _, visual in record.visuals do
				visual.part.CFrame = record.ball.CFrame
					* CFrame.new(offsetFor(record.ball, visual, sizeOf(visual)))
			end
		end
	end)
end

return StuckVisuals
