--!strict
-- FR-009: the world's meshes carry no scripts. The Lune gate cannot see built instances, so this runs in Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll

local Assets = require(ReplicatedStorage.Shared.Assets)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local WorldBuilder = require(ServerScriptService.WorldBuilder)
local WorldSpawner = require(ServerScriptService.WorldSpawner)

local function scriptCount(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			count += 1
		end
	end
	return count
end

local function lightOrSurfaceCount(root: Instance): number
	local count = 0
	for _, descendant in root:GetDescendants() do
		if
			descendant:IsA("SurfaceAppearance")
			or descendant:IsA("PointLight")
			or descendant:IsA("SpotLight")
			or descendant:IsA("SurfaceLight")
		then
			count += 1
		end
	end
	return count
end

describe("World meshes hold no scripts (FR-009)", function()
	beforeAll(function()
		WorldSpawner.start()
	end)

	it("the built world has no script descendants", function()
		expect(scriptCount(Workspace:WaitForChild("World"))).toBe(0)
	end)

	it("every object template has no script descendants", function()
		for _, def in Worlds.active.objects do
			expect(scriptCount(WorldBuilder.getTemplate(def.id))).toBe(0)
		end
	end)

	it("every object with an imported mesh id builds a MeshPart template (US2/AC3)", function()
		for _, def in Worlds.active.objects do
			local meshId = if def.assetKey then Assets.meshes[def.assetKey] else nil
			if meshId ~= nil and meshId ~= "" then
				expect(WorldBuilder.getTemplate(def.id):IsA("MeshPart")).toBe(true)
			end
		end
	end)

	it("every object template renders opaque and automatic (Constitution XI)", function()
		for _, def in Worlds.active.objects do
			local template = WorldBuilder.getTemplate(def.id)
			expect(template.Transparency).toBe(0)
			if template:IsA("MeshPart") then
				expect(template.RenderFidelity).toBe(Enum.RenderFidelity.Automatic)
			end
		end
	end)

	it("no object template holds a light or a SurfaceAppearance (Constitution XI)", function()
		for _, def in Worlds.active.objects do
			expect(lightOrSurfaceCount(WorldBuilder.getTemplate(def.id))).toBe(0)
		end
	end)

	it(
		"MeshPart collision fidelity is Box for tiers 1-3 and Hull for tiers 4-5 (FR-004)",
		function()
			for _, def in Worlds.active.objects do
				local template = WorldBuilder.getTemplate(def.id)
				if template:IsA("MeshPart") then
					local expected = if def.tier >= 4
						then Enum.CollisionFidelity.Hull
						else Enum.CollisionFidelity.Box
					expect(template.CollisionFidelity).toBe(expected)
				end
			end
		end
	)
end)
