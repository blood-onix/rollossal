--!strict
-- Client-only visuals for the stuck objects of every ball. Driven by the server's Stuck attribute.
-- "Weld" re-seats the visuals through Weld.C1 on growth; "Follower" sets their CFrame each frame.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ObjectVisual = require(Shared.ObjectVisual)
local Heap = require(Shared.Rules.Heap)
local Worlds = require(Shared.Worlds)

-- HeapRedesign (010): a buried item shrinks into the core over this many seconds instead of popping.
local BURY_SECONDS = 0.25

type Visual = {
	part: BasePart,
	dir: Vector3,
	weld: Weld?,
	-- Heap only: the template size at scale 1, the entry's tier, and when burying started (nil while outer).
	baseSize: Vector3,
	buriedAt: number?,
}

type BallRecord = {
	ball: BasePart,
	visuals: { [string]: Visual },
	-- Heap only: the colour the ball had before the core tint, and whether this is the local player's ball.
	baseColor: Color3?,
	isLocal: boolean,
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
	local limit = if Config.Flags.HeapRedesign
		then Config.maxPublishedStuck
		else Config.maxVisibleStuck
	local first = math.max(1, #entries - limit + 1)
	local visible = {}
	for index = first, #entries do
		table.insert(visible, entries[index])
	end
	return visible
end

-- Attachments grow with the ball: (D / start diameter) ^ heapScaleExponent. 1 when the heap is off.
local function heapScale(ball: BasePart): number
	if not Config.Flags.HeapRedesign then
		return 1
	end
	return math.max(ball.Size.X / Config.startDiameter, 1) ^ Config.heapScaleExponent
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

	local visual: Visual =
		{ part = part, dir = dir, weld = nil, baseSize = template.Size, buriedAt = nil }
	if Config.Flags.HeapRedesign then
		part.Size = template.Size * heapScale(record.ball)
		size = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	end
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

-- Size of a visual now: scaled with the ball and, while burying, shrunk towards nothing.
local function applyHeapScale(record: BallRecord, visual: Visual, now: number)
	local scale = heapScale(record.ball)
	if visual.buriedAt ~= nil then
		scale *= 1 - Heap.buryProgress(now - visual.buriedAt, BURY_SECONDS)
	end
	visual.part.Size = visual.baseSize * math.max(scale, 0.001)
end

local function reseat(record: BallRecord)
	local now = os.clock()
	for _, visual in record.visuals do
		if Config.Flags.HeapRedesign then
			applyHeapScale(record, visual, now)
		end
		if visual.weld then
			visual.weld.C1 = CFrame.new(-offsetFor(record.ball, visual, sizeOf(visual)))
		end
	end
end

local function paletteOf(entry: Heap.HeapEntry): Heap.Colour
	local template = templates[entry.id]
	local colour = if template then template.Color else Color3.new(0.5, 0.5, 0.5)
	return { r = colour.R, g = colour.G, b = colour.B }
end

-- HeapRedesign: the outer shell keeps welded visuals, everything else is buried (shrunk, then destroyed) and its
-- colour tints the core. Entries are `{ key, id, dir }` oldest first.
local function syncHeap(record: BallRecord, parsed: { { key: string, id: string, dir: Vector3 } })
	local now = os.clock()
	local count = #parsed
	local entries: { Heap.HeapEntry } = {}
	local dirs: { [string]: Vector3 } = {}
	local ids: { [string]: string } = {}
	for index, entry in parsed do
		local placement = Worlds.placementById[entry.id]
		local def = if placement then Worlds.objectById[placement.objectId] else nil
		if def then
			-- templateFor caches the colour source for paletteOf.
			templateFor(def.id)
			table.insert(entries, {
				key = entry.key,
				id = def.id,
				size = def.size,
				tier = def.tier,
				age = count - index,
			})
			dirs[entry.key] = entry.dir
			ids[entry.key] = entry.id
		end
	end

	local cap = if record.isLocal then Config.heapLocalCap else Config.heapRemoteCap
	local result = Heap.select(entries, { cap = cap, protectTier = 4 })

	local present: { [string]: boolean } = {}
	for _, entry in result.outer do
		present[entry.key] = true
		local visual = record.visuals[entry.key]
		if visual then
			visual.buriedAt = nil
		else
			local created = createVisual(record, entry.key, ids[entry.key], dirs[entry.key])
			if created then
				record.visuals[entry.key] = created
			end
		end
	end
	for key, visual in record.visuals do
		if not present[key] then
			if ids[key] ~= nil then
				-- Still held, just buried: shrink it.
				if visual.buriedAt == nil then
					visual.buriedAt = now
				end
			else
				-- Knocked off: gone at once, as before.
				visual.part:Destroy()
				record.visuals[key] = nil
			end
		end
	end

	-- Core tint: the mean colour of the buried items; the original colour once nothing is buried.
	if record.baseColor == nil then
		record.baseColor = record.ball.Color
	end
	if #result.buried > 0 then
		local tint = Heap.coreColor(result.buried, paletteOf)
		record.ball.Color = Color3.new(tint.r, tint.g, tint.b)
	else
		record.ball.Color = record.baseColor :: Color3
	end
end

local function sync(record: BallRecord)
	local raw = record.ball:GetAttribute("Stuck")
	local parsed: { { key: string, id: string, dir: Vector3 } } = if typeof(raw) == "string"
		then parseStuck(raw)
		else {}
	if Config.Flags.HeapRedesign then
		syncHeap(record, parsed)
		return
	end

	local wanted: { [string]: { id: string, dir: Vector3 } } = {}
	for _, entry in parsed do
		wanted[entry.key] = { id = entry.id, dir = entry.dir }
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
	local record: BallRecord = {
		ball = instance,
		visuals = {},
		baseColor = nil,
		isLocal = instance.Name == `Ball_{Players.LocalPlayer.UserId}`,
	}
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
		if Config.Flags.HeapRedesign then
			local now = os.clock()
			for _, record in records do
				for key, visual in record.visuals do
					local buriedAt = visual.buriedAt
					if buriedAt ~= nil then
						if now - buriedAt >= BURY_SECONDS then
							visual.part:Destroy()
							record.visuals[key] = nil
						else
							applyHeapScale(record, visual, now)
							if visual.weld then
								visual.weld.C1 =
									CFrame.new(-offsetFor(record.ball, visual, sizeOf(visual)))
							end
						end
					end
				end
			end
		end
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
