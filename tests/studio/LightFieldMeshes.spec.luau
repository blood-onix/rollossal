--!strict
-- 014 (research R-05, contracts/dress-and-coverage.md §3): light objects drawn through ObjectVisual. Driven directly
-- (no LocalPlayer in the server datamodel): init under a test folder, refresh at a dense spawn, read the slots.
-- Skipped unless the active world has light objects (Park City).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local afterAll = JestGlobals.afterAll

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local LightField = require(StarterPlayer.StarterPlayerScripts.LightField)

local LOAD_TIMEOUT = 60
local ATTRIBUTES = { "Size", "Bulk", "Longest", "Tier", "ObjectId", "Taken" }

local lightDescribe = if Worlds.light ~= nil and Config.Flags.LightMeshes
	then describe
	else describe.skip

lightDescribe("LightField meshes", function()
	local parent: Folder

	-- Every visible slot: the slot parts the field put at a light id.
	local function visible(): { BasePart }
		local out = {}
		for _, child in (parent:FindFirstChild("LightField") :: Instance):GetChildren() do
			if child:IsA("BasePart") and child:GetAttribute("Taken") == false then
				table.insert(out, child)
			end
		end
		return out
	end

	beforeAll(function()
		parent = Instance.new("Folder")
		parent.Name = "LightFieldMeshesSpec"
		parent.Parent = Workspace
		LightField.init(parent)
		-- Draw before the meshes have loaded (as a client does at once): the stand-in slots must switch to their
		-- meshes in place when the loads finish, with the ball standing still.
		local spawn = Worlds.active.spawnPoints[1]
		LightField.refreshAt(Vector3.new(spawn.x, 0, spawn.z), 1)
		local waited = 0
		while LightField.loadingCount() > 0 and waited < LOAD_TIMEOUT do
			waited += task.wait(0.1)
		end
	end)

	afterAll(function()
		LightField.reset()
		parent:Destroy()
	end)

	it("loads every light kind's template", function()
		expect(LightField.loadingCount()).toBe(0)
	end)

	it("draws at most the pool cap, and something near a spawn", function()
		local shown = visible()
		expect(#shown > 0).toBe(true)
		expect(#shown <= Config.lightPoolCap).toBe(true)
		expect(LightField.drawnCount()).toBe(#shown)
		expect(LightField.parkedCount() <= Config.lightPoolCap).toBe(true)
	end)

	it("every slot has the gameplay attributes, the tag and no scripts", function()
		for _, part in visible() do
			for _, name in ATTRIBUTES do
				expect(part:GetAttribute(name) ~= nil).toBe(true)
			end
			expect(CollectionService:HasTag(part, "LightObject")).toBe(true)
			expect(string.match(part.Name, "^L%d+$") ~= nil).toBe(true)
			expect(part.Anchored).toBe(true)
			expect(part.CanQuery).toBe(false)
			for _, descendant in part:GetDescendants() do
				expect(descendant:IsA("BaseScript")).toBe(false)
			end
		end
	end)

	it(
		"a kind with a mesh is a MeshPart with the theme atlas; a stand-in takes its role colour",
		function()
			local theme = Worlds.activeTheme :: any
			local meshes, standIns = 0, 0
			for _, part in visible() do
				local def = Worlds.objectById[part:GetAttribute("ObjectId") :: string]
				if def.assetKey ~= nil and part:IsA("MeshPart") then
					meshes += 1
					local atlas = if def.atlas == "fronts"
						then Assets.frontsAtlases[theme.paletteAssetKey]
						else Assets.palettes[theme.paletteAssetKey]
					expect((part :: MeshPart).TextureID).toBe(atlas)
				elseif def.assetKey == nil then
					standIns += 1
					expect(part:IsA("MeshPart")).toBe(false)
					local cell = theme.palette[def.role :: string]
					expect(part.Color).toEqual(Color3.fromRGB(cell[1], cell[2], cell[3]))
				end
			end
			expect(meshes > 0).toBe(true)
			expect(standIns > 0).toBe(true)
		end
	)

	it("moving away parks slots and stays within the cap", function()
		local spawn = Worlds.active.spawnPoints[7]
		LightField.refreshAt(Vector3.new(spawn.x, 0, spawn.z), 1)
		expect(#visible() <= Config.lightPoolCap).toBe(true)
		expect(LightField.parkedCount() <= Config.lightPoolCap).toBe(true)
		expect(LightField.poolSize()).toBe(LightField.drawnCount() + LightField.parkedCount())
	end)

	it("a taken light is released at once", function()
		local shown = visible()
		local index = tonumber(string.match(shown[1].Name, "^L(%d+)$")) :: number
		local before = LightField.drawnCount()
		LightField.apply({ index }, {}, false)
		expect(LightField.drawnCount()).toBe(before - 1)
		LightField.apply({}, { index }, false)
	end)
end)

return {}
