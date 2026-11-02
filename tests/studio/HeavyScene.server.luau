--!strict
-- Feature 009, US4: the heavy-scene benchmark behind the scene triangle ceiling (specs/009-style-bible-bakeoff/
-- research.md R-12 to R-14). It builds a scene from the game's own uploaded meshes, steps it up through STEPS
-- triangles with 12 rolling balls and under 2,000 parts, and publishes the current step so the client sampler
-- (HeavySampler.client) can record one fps value per second.
--
-- Deviation from R-12 (recorded in playtest.md): EditableMesh is not available in Play (the experience's Security
-- setting is off, and a mesh made in Edit mode loses its content when Play starts), so the scene reuses the game's
-- highest-triangle meshes instead of procedural ones. Their counts come from art/export/manifest.json. The most
-- the scene can reach inside the part limit is about 723,000 triangles; a 1,000,000 step needs EditableMesh.
--
-- Run it inside Play (a Script in ServerStorage never runs):
--   local copy = game.ServerStorage.Tests.HeavyScene:Clone(); copy.Parent = game.ServerScriptService
-- then start the sampler on the Client datamodel (see HeavySampler.client.luau). The report is JSON in the
-- `HeavySceneReport` attribute of Workspace when the last step ends. It starts only when `HeavySceneStart` is unset,
-- so cloning it twice does nothing.
--
-- The scene sits high above the world, a grid of meshes in one plane. The sampler points the camera straight at it,
-- so every triangle is inside the view frustum: the worst case, an upper bound on what a street shows.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ObjectVisual = require(ReplicatedStorage.Shared.ObjectVisual)

-- Asset key and triangle count (art/export/manifest.json), most triangles first.
local MESHES: { { key: string, triangles: number } } = {
	{ key = "dt_ice_rink", triangles = 564 },
	{ key = "bandstand", triangles = 490 },
	{ key = "dt_ferris_wheel", triangles = 460 },
	{ key = "dt_corner_shop_row", triangles = 432 },
	{ key = "dt_mega_tree", triangles = 418 },
	{ key = "dt_donut_food_truck", triangles = 416 },
	{ key = "dt_monster_truck", triangles = 360 },
	{ key = "dt_snowman", triangles = 356 },
	{ key = "dt_apartment_block", triangles = 348 },
	{ key = "dt_fountain", triangles = 324 },
	{ key = "dt_cocoa_truck", triangles = 320 },
	{ key = "dt_garbage_truck", triangles = 312 },
	{ key = "dt_glass_tower_bow", triangles = 308 },
	{ key = "dt_fire_engine", triangles = 300 },
	{ key = "dt_drum_kit", triangles = 300 },
}
local STEPS = { 300000, 500000, 700000 }
local WARMUP_SECONDS = 10
local SAMPLE_SECONDS = 60
local BALL_COUNT = 12
local BALL_DIAMETER = 10
local MAX_MESH_PARTS = 1900
local GRID_COLUMNS = 45
local SPACING = 8
local MESH_SIZE = 6
local SCENE_CENTRE = Vector3.new(0, 1500, 0)
-- Share of the full-budget Downtown at tier 4 and 5 (994,000 of 1,894,200 triangles): the part a culled scene keeps.
local CULLED_SHARE = 994000 / 1894200

if Workspace:GetAttribute("HeavySceneStart") ~= nil then
	script:Destroy()
	return
end
Workspace:SetAttribute("HeavySceneStart", os.clock())
Workspace:SetAttribute("HeavySceneReport", "")
Workspace:SetAttribute("HeavyStep", 0)
Workspace:SetAttribute("HeavyCentre", SCENE_CENTRE)

local scene = Instance.new("Folder")
scene.Name = "HeavyScene"
scene.Parent = Workspace

local templates: { MeshPart } = {}
for _, entry in MESHES do
	local template = ObjectVisual.buildMesh(entry.key, entry.key, MESH_SIZE, 4)
	if template == nil then
		error(`HeavyScene: mesh {entry.key} did not load`)
	end
	template.Anchored = true
	template.CanCollide = false
	template.CanQuery = false
	template.CanTouch = false
	table.insert(templates, template)
end

local function clearMeshes()
	for _, child in scene:GetChildren() do
		if child.Name == "Mesh" then
			child:Destroy()
		end
	end
end

-- Places meshes round-robin from the heaviest down until the next one would pass `target` triangles or the part limit.
local function build(target: number): { parts: number, triangles: number }
	clearMeshes()
	local triangles, count = 0, 0
	local plan: { number } = {}
	while count < MAX_MESH_PARTS do
		local index = count % #MESHES + 1
		if triangles + MESHES[index].triangles > target then
			break
		end
		triangles += MESHES[index].triangles
		count += 1
		table.insert(plan, index)
	end
	local rows = math.ceil(count / GRID_COLUMNS)
	for position, index in plan do
		local part = templates[index]:Clone()
		part.Name = "Mesh"
		local column, row = (position - 1) % GRID_COLUMNS, (position - 1) // GRID_COLUMNS
		part.Position = SCENE_CENTRE
			+ Vector3.new(
				(column - (GRID_COLUMNS - 1) / 2) * SPACING,
				0,
				(row - (rows - 1) / 2) * SPACING
			)
		part.Parent = scene
		if position % 100 == 0 then
			task.wait()
		end
	end
	return { parts = count, triangles = triangles }
end

local function buildFloorAndBalls()
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(GRID_COLUMNS * SPACING, 2, GRID_COLUMNS * SPACING)
	floor.Position = SCENE_CENTRE - Vector3.new(0, 10, 0)
	floor.Color = Color3.fromRGB(90, 96, 110)
	floor.Parent = scene
	for index = 1, BALL_COUNT do
		local ball = Instance.new("Part")
		ball.Name = "Ball"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.one * BALL_DIAMETER
		ball.Position = SCENE_CENTRE + Vector3.new((index - 6.5) * 20, -4, (index % 3 - 1) * 30)
		ball.AssemblyLinearVelocity = Vector3.new(math.cos(index) * 20, 0, math.sin(index) * 20)
		ball.Color = Color3.fromHSV(index / BALL_COUNT, 0.7, 0.95)
		ball.Parent = scene
	end
end

buildFloorAndBalls()

local report: { { step: number, parts: number, triangles: number, culledSet: number } } = {}
for _, step in STEPS do
	local built = build(step)
	local parts = #scene:GetChildren()
	table.insert(report, {
		step = step,
		parts = parts,
		triangles = built.triangles,
		culledSet = math.floor(built.triangles * CULLED_SHARE),
	})
	print(
		`HeavyScene: step {step}: {built.triangles} triangles in {built.parts} meshes, {parts} parts`
	)
	Workspace:SetAttribute("HeavyStep", step)
	Workspace:SetAttribute("HeavyStepAt", os.clock())
	task.wait(WARMUP_SECONDS + SAMPLE_SECONDS + 2)
end
Workspace:SetAttribute("HeavyStep", -1)
Workspace:SetAttribute("HeavySceneReport", HttpService:JSONEncode(report))
print("HeavyScene: done")
