--!strict
-- Client-only visuals for the stuck objects of every ball. Driven by the server's Stuck attribute.
-- "Weld" re-seats the visuals through Weld.C1 on growth; "Follower" sets their CFrame each frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ObjectVisual = require(Shared.ObjectVisual)
local Worlds = require(Shared.Worlds)

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
local visualFolder: Folder? = nil
-- One template per object type, built on first use and cloned for every stuck visual.
local templates: { [string]: BasePart } = {}

local function templateFor(objectId: string): BasePart?
	local existing = templates[objectId]
	if existing then
		return existing
	end
	local def = Worlds.objectById[objectId]
	if def == nil then
		return nil
	end
	local built = ObjectVisual.build(def)
	templates[objectId] = built
	return built
end

-- Entries are `key,dx,dy,dz` with key `<placementId>#<n>`, unique per pickup; the placement id is the part
-- before `#`. Visuals are keyed by key, so an object eaten twice shows twice.
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
	if not folder then
		return nil
	end
	-- The placement is shared data, so the visual never depends on the pooled part being streamed in.
	local placement = Worlds.placementById[id]
	local template = if placement then templateFor(placement.objectId) else nil
	if not template then
		return nil
	end
	local size = math.max(template.Size.X, template.Size.Y, template.Size.Z)

	local part = template:Clone()
	part.Name = `Stuck_{record.ball.Name}_{key}`
	part.Anchored = false
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
	local size = visual.part.Size
	return math.max(size.X, size.Y, size.Z)
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
