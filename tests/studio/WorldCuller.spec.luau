--!strict
-- Client sub-tier culling (FR-015, research R6) against mock pooled parts. The culler changes local state only:
-- the replicated Transparency and the Taken attribute are never written (so other players are unaffected).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local Config = require(ReplicatedStorage.Shared.Config)
local WorldCuller = require(StarterPlayer.StarterPlayerScripts.WorldCuller)

local created: { BasePart } = {}

local function makePart(tier: number, taken: boolean): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part:SetAttribute("Tier", tier)
	part:SetAttribute("Size", 1)
	part:SetAttribute("Taken", taken)
	part.Transparency = if taken then 1 else 0
	part.CanCollide = not taken
	part.CanTouch = not taken
	part.CanQuery = not taken
	CollectionService:AddTag(part, "WorldObject")
	part.Parent = Workspace
	table.insert(created, part)
	-- Tag and attribute signals are deferred: let the culler see the part before the test goes on.
	task.wait()
	return part
end

local function isHidden(part: BasePart): boolean
	return part.LocalTransparencyModifier == 1
		and not part.CanCollide
		and not part.CanTouch
		and not part.CanQuery
end

describe("WorldCuller", function()
	beforeEach(function()
		WorldCuller.reset()
		WorldCuller.attach()
	end)
	afterEach(function()
		for _, part in created do
			part:Destroy()
		end
		table.clear(created)
		WorldCuller.reset()
	end)

	it("uses a two-tier gap", function()
		expect(Config.cullTierDelta).toBe(2)
	end)

	it("hides the tiers at least two below the player and keeps the rest", function()
		local parts: { BasePart } = {}
		for tier = 1, 5 do
			parts[tier] = makePart(tier, false)
		end

		WorldCuller.setPlayerTier(1)
		for tier = 1, 5 do
			expect(isHidden(parts[tier])).toBe(false)
		end

		WorldCuller.setPlayerTier(3)
		expect(isHidden(parts[1])).toBe(true)
		expect(isHidden(parts[2])).toBe(false)

		WorldCuller.setPlayerTier(4)
		expect(isHidden(parts[1])).toBe(true)
		expect(isHidden(parts[2])).toBe(true)
		expect(isHidden(parts[3])).toBe(false)

		WorldCuller.setPlayerTier(5)
		expect(isHidden(parts[3])).toBe(true)
		expect(isHidden(parts[4])).toBe(false)
		expect(isHidden(parts[5])).toBe(false)
	end)

	it("restores a tier at once when the player shrinks back", function()
		local one = makePart(1, false)
		local two = makePart(2, false)
		WorldCuller.setPlayerTier(4)
		expect(isHidden(two)).toBe(true)

		WorldCuller.setPlayerTier(3)
		expect(isHidden(two)).toBe(false)
		expect(two.LocalTransparencyModifier).toBe(0)
		expect(two.CanTouch).toBe(true)
		expect(two.CanQuery).toBe(true)
		expect(isHidden(one)).toBe(true)

		WorldCuller.setPlayerTier(1)
		expect(isHidden(one)).toBe(false)
	end)

	it("never revives a part that was Taken while it was hidden", function()
		local taken = makePart(1, true)
		local free = makePart(1, false)
		WorldCuller.setPlayerTier(4)
		expect(isHidden(taken)).toBe(true)

		WorldCuller.setPlayerTier(1)
		expect(taken.CanTouch).toBe(false)
		expect(taken.CanQuery).toBe(false)
		expect(taken.CanCollide).toBe(false)
		expect(taken.Transparency).toBe(1)
		expect(free.CanTouch).toBe(true)
	end)

	it("hides a culled part again when the server respawns it", function()
		local part = makePart(1, true)
		WorldCuller.setPlayerTier(4)
		-- The server restores the part: Taken false and its replicated properties come back.
		part.CanTouch = true
		part.CanQuery = true
		part:SetAttribute("Taken", false)
		task.wait()
		expect(isHidden(part)).toBe(true)
	end)

	it("hides a part that streams in after the tier was set", function()
		WorldCuller.setPlayerTier(4)
		local late = makePart(1, false)
		expect(isHidden(late)).toBe(true)
		local near = makePart(3, false)
		expect(isHidden(near)).toBe(false)
	end)

	it("changes no replicated property and no attribute", function()
		local part = makePart(1, false)
		WorldCuller.setPlayerTier(5)
		expect(part.Transparency).toBe(0)
		expect(part:GetAttribute("Taken")).toBe(false)
		expect(part:GetAttribute("Tier")).toBe(1)
		WorldCuller.setPlayerTier(1)
		expect(part.Transparency).toBe(0)
	end)
end)
