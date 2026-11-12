--!strict
-- Client-only visuals for the stuck objects of every ball. Driven by the server's Stuck attribute.
-- "Weld" re-seats the visuals through Weld.C1 on growth; "Follower" sets their CFrame each frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ObjectVisual = require(Shared.ObjectVisual)
local HeapFit = require(Shared.Rules.HeapFit)
local Worlds = require(Shared.Worlds)

type Visual = {
	part: BasePart,
	dir: Vector3,
	weld: Weld?,
	-- The part's template size, before the heap fit scales it.
	baseSize: Vector3,
	-- Set while an old small item is being buried: when the bury started (seconds).
	buryAt: number?,
}

type BallRecord = {
	ball: BasePart,
	visuals: { [string]: Visual },
	-- The largest item of the latest catch may stick out further for Config.heapNewestGrace.
	newestKey: string?,
	newestAt: number,
}

-- 012 R4: items sit within a 1.25 D box of the ball. Park City always has it; Downtown behind its own flags.
local heapFix = Config.Flags.HeapFix or Config.Flags.ParkCity or Config.Flags.ReadableRules
local fitParams: HeapFit.Params = {
	maxScale = Config.heapFitMaxScale,
	bound = Config.heapFitBound,
	newestBound = Config.heapFitNewestBound,
	embed = Config.stuckEmbed,
	grace = Config.heapNewestGrace,
}
local BURY_SECONDS = 0.3

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

-- Pose of a fitted item in the ball's space: thin axis along the normal, long axis tangent. Sets the part size.
local function fittedPose(record: BallRecord, key: string, visual: Visual): CFrame
	local ball = record.ball
	local newestAge = if record.newestKey == key then os.clock() - record.newestAt else nil
	local base = visual.baseSize
	local fit = HeapFit.fit({ base.X, base.Y, base.Z }, ball.Size.X, fitParams, newestAge)
	visual.part.Size = base * fit.scale
	local normal = if visual.dir.Magnitude > 0 then visual.dir.Unit else Vector3.yAxis
	local reference = if math.abs(normal.Y) < 0.9 then Vector3.yAxis else Vector3.xAxis
	local tangent = normal:Cross(reference).Unit
	local axes: { Vector3 } = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }
	axes[fit.thinAxis] = normal
	axes[fit.longAxis] = tangent
	axes[fit.midAxis] = normal:Cross(tangent)
	-- A box has no handedness: flip the third axis if the assignment came out left-handed.
	axes[3] = axes[1]:Cross(axes[2])
	return CFrame.fromMatrix(normal * fit.centerDistance, axes[1], axes[2], axes[3])
end

local function createVisual(record: BallRecord, key: string, id: string, dir: Vector3): Visual?
	local folder = visualFolder
	if not folder then
		return nil
	end
	-- The placement is shared data, so the visual never depends on the pooled part being streamed in.
	local placement = Worlds.placementById[id]
	local kind = if placement then placement.objectId else Worlds.lightKind(id)
	local template = if kind then templateFor(kind) else nil
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
		{ part = part, dir = dir, weld = nil, baseSize = template.Size, buryAt = nil }
	if Config.stuckVisualMode == "Weld" then
		local weld = Instance.new("Weld")
		weld.Part0 = record.ball
		weld.Part1 = part
		weld.C0 = CFrame.identity
		weld.C1 = if heapFix
			then fittedPose(record, key, visual):Inverse()
			else CFrame.new(-offsetFor(record.ball, visual, size))
		weld.Parent = part
		visual.weld = weld
	elseif heapFix then
		part.CFrame = record.ball.CFrame * fittedPose(record, key, visual)
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
	for key, visual in record.visuals do
		if visual.buryAt ~= nil then
			continue
		end
		if visual.weld then
			visual.weld.C1 = if heapFix
				then fittedPose(record, key, visual):Inverse()
				else CFrame.new(-offsetFor(record.ball, visual, sizeOf(visual)))
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

	if next(wanted) == nil then
		-- A reset (Roll Again, a new round, a swallow): everything goes at once. Nothing sinks slowly into a ball
		-- that has just dropped back to its start size.
		for key, visual in record.visuals do
			visual.part:Destroy()
			record.visuals[key] = nil
		end
		record.newestKey = nil
		return
	end
	for key, visual in record.visuals do
		-- A key used again while its old item is still sinking: the old one goes now.
		if wanted[key] and visual.buryAt ~= nil then
			visual.part:Destroy()
			record.visuals[key] = nil
			continue
		end
		if not wanted[key] then
			if heapFix and visual.weld and visual.buryAt == nil and record.ball.Parent ~= nil then
				-- Older items sink into the ball instead of popping out (stepped in the render loop).
				visual.buryAt = os.clock()
			elseif visual.buryAt == nil then
				visual.part:Destroy()
				record.visuals[key] = nil
			end
		end
	end
	local largest, largestSize = nil, 0
	for key, entry in wanted do
		if not record.visuals[key] then
			local visual = createVisual(record, key, entry.id, entry.dir)
			if visual then
				record.visuals[key] = visual
				local size = math.max(visual.baseSize.X, visual.baseSize.Y, visual.baseSize.Z)
				if size > largestSize then
					largest, largestSize = key, size
				end
			end
		end
	end
	if largest ~= nil then
		record.newestKey = largest
		record.newestAt = os.clock()
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
	local record: BallRecord = { ball = instance, visuals = {}, newestKey = nil, newestAt = 0 }
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
		local now = os.clock()
		for _, record in records do
			-- The newest large catch eases from its allowance to the normal fit, then settles once.
			local newest = if record.newestKey then record.visuals[record.newestKey] else nil
			if newest and newest.weld and newest.buryAt == nil then
				local age = now - record.newestAt
				if heapFix and age < Config.heapNewestGrace + 0.1 then
					newest.weld.C1 =
						fittedPose(record, record.newestKey :: string, newest):Inverse()
				end
			end
			for key, visual in record.visuals do
				local buryAt = visual.buryAt
				if buryAt ~= nil then
					local t = (now - buryAt) / BURY_SECONDS
					if t >= 1 or visual.weld == nil then
						visual.part:Destroy()
						record.visuals[key] = nil
					else
						local pose = fittedPose(record, key, visual)
						visual.weld.C1 = (pose - pose.Position + pose.Position * (1 - t)):Inverse()
					end
				elseif Config.stuckVisualMode == "Follower" then
					visual.part.CFrame = record.ball.CFrame
						* (
							if heapFix
								then fittedPose(record, key, visual)
								else CFrame.new(offsetFor(record.ball, visual, sizeOf(visual)))
						)
				end
			end
		end
	end)
end

return StuckVisuals
