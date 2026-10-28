--!strict
-- The pooled registry against the real Snow Village world (FR-013, FR-014, plan R4, R5). Expected values come
-- from the spec and the Config numbers, never from the code under test.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeAll = JestGlobals.beforeAll
local beforeEach = JestGlobals.beforeEach
local afterAll = JestGlobals.afterAll

local Config = require(ReplicatedStorage.Shared.Config)
local Worlds = require(ReplicatedStorage.Shared.Worlds)
local WorldSpawner = require(ServerScriptService.WorldSpawner)
local Fixtures = require(script.Parent.Fixtures)

local NOW = 5000
local acorns = Fixtures.ids("acorn", 4)

local function get(id: string): WorldSpawner.PooledWorldObject
	local object = WorldSpawner.getObject(id)
	assert(object, `missing object {id}`)
	return object
end

local function noWatchers(): { any }
	return {}
end

-- A single ball standing on the object's spot, so the object is in sight.
local function watcherOn(object: WorldSpawner.PooledWorldObject): () -> { any }
	local position = object.spawnCFrame.Position
	return function()
		return { { x = position.X, z = position.Z, hx = 0, hz = 0 } }
	end
end

local function take(object: WorldSpawner.PooledWorldObject, now: number, key: string)
	WorldSpawner.markTaken(object, now, key)
end

describe("WorldSpawner pooling and respawn", function()
	beforeAll(function()
		WorldSpawner.start()
	end)
	beforeEach(function()
		WorldSpawner.reset()
		WorldSpawner.setWatcherSource(noWatchers)
	end)
	afterAll(function()
		WorldSpawner.setWatcherSource(noWatchers)
	end)

	it("builds one pooled part per placement under World.Objects", function()
		local objects = Workspace:WaitForChild("World"):WaitForChild("Objects")
		expect(#objects:GetChildren()).toBe(#Worlds.placements)
		for tier, list in Worlds.objectsByTier do
			expect(#list > 0).toBe(true)
			expect(WorldSpawner.countsByTier()[tier].total > 0).toBe(true)
		end
	end)

	it("hides a taken object in place and keeps the same Instance after respawn", function()
		local object = get(acorns[1])
		local part = object.part
		local objects = part.Parent :: Instance
		local before = #objects:GetChildren()
		take(object, NOW, "k1")
		expect(object.state).toBe("Taken")
		expect(part:GetAttribute("Taken")).toBe(true)
		expect(part.Transparency).toBe(1)
		expect(part.CanCollide).toBe(false)
		expect(part.CanTouch).toBe(false)
		expect(part.CanQuery).toBe(false)

		WorldSpawner.update(object.respawnAt :: number)
		expect(object.state).toBe("Available")
		expect(object.part).toBe(part)
		expect(part.Parent).toBe(objects)
		expect(#objects:GetChildren()).toBe(before)
		expect(part:GetAttribute("Taken")).toBe(false)
		expect(part.Transparency).toBe(0)
		expect(part.CFrame == object.spawnCFrame).toBe(true)
	end)

	it("picks a respawn delay between the minimum and the maximum", function()
		for index, id in acorns do
			local object = get(id)
			take(object, NOW, `k{index}`)
			local delay = (object.respawnAt :: number) - NOW
			expect(delay).toBeGreaterThanOrEqual(Config.respawnDelayMin)
			expect(delay).toBeLessThanOrEqual(Config.respawnDelayMax)
		end
	end)

	it("does not respawn before the delay is over", function()
		local object = get(acorns[1])
		take(object, NOW, "k1")
		WorldSpawner.update((object.respawnAt :: number) - 0.01)
		expect(object.state).toBe("Taken")
	end)

	it("defers a due respawn while a ball can see the spot, then releases it", function()
		local object = get(acorns[1])
		take(object, NOW, "k1")
		local due = object.respawnAt :: number
		WorldSpawner.setWatcherSource(watcherOn(object))
		WorldSpawner.update(due)
		expect(object.state).toBe("Taken")
		WorldSpawner.update(due + 10)
		expect(object.state).toBe("Taken")

		WorldSpawner.setWatcherSource(noWatchers)
		WorldSpawner.update(due + 11)
		expect(object.state).toBe("Available")
	end)

	it("respawns after the starvation ceiling even when watched", function()
		local object = get(acorns[1])
		take(object, NOW, "k1")
		WorldSpawner.setWatcherSource(watcherOn(object))
		WorldSpawner.update(NOW + Config.respawnForceAfterSeconds - 0.01)
		expect(object.state).toBe("Taken")
		WorldSpawner.update(NOW + Config.respawnForceAfterSeconds)
		expect(object.state).toBe("Available")
	end)

	it("a ball far from the spot does not block the respawn", function()
		local object = get(acorns[1])
		take(object, NOW, "k1")
		local position = object.spawnCFrame.Position
		WorldSpawner.setWatcherSource(function()
			return {
				{
					x = position.X + Config.respawnViewDistance + 50,
					z = position.Z,
					hx = 1,
					hz = 0,
				},
			}
		end)
		WorldSpawner.update(object.respawnAt :: number)
		expect(object.state).toBe("Available")
	end)

	it(
		"refreshCluster brings a slot's taken objects straight back without a sight check",
		function()
			local cluster: { WorldSpawner.PooledWorldObject } = {}
			for _, placement in Worlds.placements do
				if placement.spawnSlot == 1 and #cluster < 12 then
					table.insert(cluster, get(placement.id))
				end
			end
			expect(#cluster).toBe(12)
			for index, object in cluster do
				take(object, NOW, `c{index}`)
			end
			WorldSpawner.setWatcherSource(watcherOn(cluster[1]))
			WorldSpawner.refreshCluster(1, NOW + 1)
			for _, object in cluster do
				expect(object.state).toBe("Available")
				expect(object.part:GetAttribute("Taken")).toBe(false)
			end
		end
	)

	it("refreshCluster leaves another slot's objects alone", function()
		local other: WorldSpawner.PooledWorldObject? = nil
		for _, placement in Worlds.placements do
			if placement.spawnSlot == 2 then
				other = get(placement.id)
				break
			end
		end
		assert(other, "no slot 2 object")
		take(other, NOW, "o1")
		WorldSpawner.refreshCluster(1, NOW + 1)
		expect(other.state).toBe("Taken")
	end)

	it("scatter lands the same part on the ground, above Y = 0", function()
		local object = get(acorns[1])
		local part = object.part
		take(object, NOW, "k1")
		-- Over the open lawn north of slot 1, which has ground at Y = 0 and nothing on top of it.
		WorldSpawner.scatter(object, Vector3.new(-200, 0, -150), NOW + Config.scatterGrace)
		expect(object.state).toBe("Scattered")
		expect(object.part).toBe(part)
		expect(part.Position.Y).toBeGreaterThan(0)
		expect(part.Position.Y).toBeCloseTo(object.size / 2, 3)
		expect(part:GetAttribute("Taken")).toBe(false)
		WorldSpawner.update(NOW + Config.scatterGrace)
		expect(object.state).toBe("Available")
	end)

	it("scatter on the porch rests on the porch top", function()
		local object = get(acorns[2])
		take(object, NOW, "k2")
		local porch = Worlds.active.spawnPoints[1]
		WorldSpawner.scatter(object, Vector3.new(porch.x, 0, porch.z), NOW)
		expect(object.part.Position.Y).toBeCloseTo(porch.y + object.size / 2, 3)
	end)

	it("returnToSpawn never destroys the part", function()
		local object = get(acorns[3])
		local part = object.part
		WorldSpawner.scatter(object, Vector3.new(-200, 0, -150), NOW)
		WorldSpawner.returnToSpawn(object)
		expect(part.Parent).never.toBe(nil)
		expect(object.state).toBe("Available")
		expect(part.CFrame == object.spawnCFrame).toBe(true)
	end)

	it("counts objects by tier and by state", function()
		local object = get(acorns[1])
		local before = WorldSpawner.countsByTier()[object.tier].available
		take(object, NOW, "k1")
		expect(WorldSpawner.countsByTier()[object.tier].available).toBe(before - 1)
		expect(WorldSpawner.registryCounts().pendingRespawn).toBe(1)
		local total = 0
		for _, entry in WorldSpawner.countsByTier() do
			total += entry.total
		end
		expect(total).toBe(#Worlds.placements)
	end)

	it("gives each spawn slot a position on its porch and wraps past the last slot", function()
		local points = Worlds.active.spawnPoints
		local first = WorldSpawner.getSpawnSlot(1)
		expect(first.X).toBe(points[1].x)
		expect(first.Z).toBe(points[1].z)
		expect(first.Y).toBeCloseTo(points[1].y + Config.startDiameter / 2 + 0.5, 6)
		expect(WorldSpawner.getSpawnSlot(#points + 1)).toBe(first)
	end)

	it("clamps scatter spots inside the town", function()
		local limit = Worlds.active.halfExtent - 2
		local spots = WorldSpawner.scatterSpots(Vector3.new(limit, 0, 0), 8, 30, 0)
		expect(#spots).toBe(8)
		for _, spot in spots do
			expect(math.abs(spot.X)).toBeLessThanOrEqual(limit)
			expect(math.abs(spot.Z)).toBeLessThanOrEqual(limit)
		end
	end)
end)
