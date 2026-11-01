--!strict
-- 007: ambient pigeons (research R-14) in Studio. The controller is driven directly (no LocalPlayer in the
-- server datamodel): a pigeon flies off when the ball gets close, at most 8 stand per district, Reduce motion
-- keeps them still and hidden, and reset() (called when a new run starts) brings the flock back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local afterEach = JestGlobals.afterEach

local PigeonController = require(StarterPlayer.StarterPlayerScripts.PigeonController)

local function spots(district: string, count: number, x0: number)
	local list = {}
	for index = 1, count do
		table.insert(list, { district = district, x = x0 + index * 40, z = 0 })
	end
	return list
end

describe("PigeonController", function()
	afterEach(function()
		PigeonController.setReduceMotion(nil)
		PigeonController.destroy()
	end)

	it("caps a district at 8 pigeons and keeps the others", function()
		local all = spots("Park", 12, 0)
		for _, spot in spots("Plaza", 3, 1000) do
			table.insert(all, spot)
		end
		PigeonController.populate(all)
		local total, flown = PigeonController.counts()
		expect(total).toBe(11)
		expect(flown).toBe(0)
	end)

	it("flies off only the pigeons near the ball", function()
		PigeonController.populate({
			{ district = "Park", x = 0, z = 0 },
			{ district = "Park", x = 200, z = 0 },
		})
		PigeonController.scare(Vector3.new(4, 0, 0))
		local total, flown = PigeonController.counts()
		expect(total).toBe(2)
		expect(flown).toBe(1)
	end)

	it("stays still under Reduce motion and hides the flock", function()
		PigeonController.populate({ { district = "Park", x = 0, z = 0 } })
		PigeonController.setReduceMotion(true)
		PigeonController.scare(Vector3.new(1, 0, 0))
		local _, flown = PigeonController.counts()
		expect(flown).toBe(0)
		local folder = PigeonController.folder() :: Folder
		local part = folder:FindFirstChild("Pigeon") :: Part
		expect(part.LocalTransparencyModifier).toBe(1)
		PigeonController.setReduceMotion(false)
		expect(part.LocalTransparencyModifier).toBe(0)
	end)

	it("reset() puts a flown pigeon back on its spot and shows it", function()
		PigeonController.populate({ { district = "Park", x = 10, z = 20 } })
		local folder = PigeonController.folder() :: Folder
		local part = folder:FindFirstChild("Pigeon") :: Part
		local home = part.CFrame
		PigeonController.scare(Vector3.new(10, 0, 20))
		expect((select(2, PigeonController.counts()))).toBe(1)
		PigeonController.reset()
		local _, flown = PigeonController.counts()
		expect(flown).toBe(0)
		expect(part.CFrame).toEqual(home)
		expect(part.Transparency).toBe(0)
		expect(part.LocalTransparencyModifier).toBe(0)
		PigeonController.scare(Vector3.new(10, 0, 20))
		expect((select(2, PigeonController.counts()))).toBe(1)
	end)
end)
