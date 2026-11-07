--!strict
-- The pooled-object registry and its state. Builds the world through WorldBuilder, then hides and restores the
-- same parts in place (never Destroy). Time is passed in; the sight rule lives in Rules/Respawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Respawn = require(Shared.Rules.Respawn)
local Worlds = require(Shared.Worlds)
local WorldBuilder = require(script.Parent.WorldBuilder)

export type ObjectState = "Available" | "Taken" | "Scattered"

export type PooledWorldObject = {
	id: string,
	objectId: string,
	tier: number,
	size: number,
	spawnCFrame: CFrame,
	part: BasePart,
	state: ObjectState,
	takenAt: number?,
	respawnAt: number?,
	availableAt: number?,
	-- Key of the stack entry whose pickup made this object Taken. Only that entry can release it early.
	holderKey: string?,
	-- 1..12 when the object belongs to a spawn point's reserved cluster.
	spawnSlot: number?,
}

local RAY_HEIGHT = 20
local RAY_LENGTH = 80

local WorldSpawner = {}

local registry: { [string]: PooledWorldObject } = {}
local objectList: { PooledWorldObject } = {}
-- Objects that are Taken or Scattered, so a tick never walks the whole pool.
local pending: { [PooledWorldObject]: boolean } = {}
local clusters: { [number]: { PooledWorldObject } } = {}
local started = false
local random = Random.new()
local groundParams = RaycastParams.new()
local sightParams: Respawn.SightParams = {
	radius = Config.respawnOutOfSightRadius,
	viewDistance = Config.respawnViewDistance,
	viewCos = Config.respawnViewCos,
}
local watcherSource: () -> { Respawn.Watcher } = function()
	return {}
end

-- Light objects (012 Stage C): Tiers 1 and 2 of Park City are server data, never Parts. Parallel tables by light
-- index; `pendingLight` holds the taken indices so the tick never walks the whole field.
local lightData = Worlds.light
local lightState: { [number]: number } = {}
local lightTakenAt: { [number]: number } = {}
local lightRespawnAt: { [number]: number } = {}
local pendingLight: { [number]: boolean } = {}
local outbox: { taken: { number }, restored: { number } } = { taken = {}, restored = {} }

local function setTaken(object: PooledWorldObject, taken: boolean)
	local part = object.part
	part:SetAttribute("Taken", taken)
	part.Transparency = if taken then 1 else 0
	part.CanCollide = not taken
	part.CanTouch = not taken
	part.CanQuery = not taken
end

function WorldSpawner.start()
	if started then
		return
	end
	started = true
	-- 005: the resolved world carries the active theme's palette, lighting, slot objects, hero
	-- variants and overlay placements, so the builder needs no theme-aware code of its own.
	local built = WorldBuilder.start(Worlds.resolved, Worlds.placements)
	local world = Workspace:WaitForChild("World")
	groundParams.FilterType = Enum.RaycastFilterType.Include
	groundParams.FilterDescendantsInstances = { world:WaitForChild("Geometry") }

	for _, item in built.objects do
		local part = item.part
		local object: PooledWorldObject = {
			id = item.placement.id,
			objectId = item.placement.objectId,
			tier = part:GetAttribute("Tier") :: number,
			size = part:GetAttribute("Size") :: number,
			spawnCFrame = part.CFrame,
			part = part,
			state = "Available",
			takenAt = nil,
			respawnAt = nil,
			availableAt = nil,
			holderKey = nil,
			spawnSlot = item.placement.spawnSlot,
		}
		registry[object.id] = object
		table.insert(objectList, object)
		local slot = object.spawnSlot
		if slot then
			local cluster = clusters[slot]
			if cluster == nil then
				cluster = {}
				clusters[slot] = cluster
			end
			table.insert(cluster :: { PooledWorldObject }, object)
		end
	end
end

-- What the server knows about one light object, or nil for a bad index.
export type LightInfo = {
	index: number,
	kind: string,
	x: number,
	y: number,
	z: number,
	size: number,
	bulk: number,
	tier: number,
	taken: boolean,
}

function WorldSpawner.getLight(index: number): LightInfo?
	if lightData == nil or index < 1 or index > lightData.count then
		return nil
	end
	local at = (index - 1) * lightData.stride
	local kind = lightData.kinds[lightData.data[at + 1]]
	local def = Worlds.objectById[kind]
	return {
		index = index,
		kind = kind,
		x = lightData.data[at + 2],
		y = lightData.data[at + 3],
		z = lightData.data[at + 4],
		size = def.size,
		bulk = Worlds.bulkOf(def),
		tier = def.tier,
		taken = lightState[index] == 1,
	}
end

function WorldSpawner.takeLight(index: number, now: number)
	lightState[index] = 1
	lightTakenAt[index] = now
	lightRespawnAt[index] = now
		+ Respawn.delayFrom(random:NextNumber(), Config.respawnDelayMin, Config.respawnDelayMax)
	pendingLight[index] = true
	table.insert(outbox.taken, index)
end

local function restoreLight(index: number)
	lightState[index] = 0
	lightTakenAt[index] = nil
	lightRespawnAt[index] = nil
	pendingLight[index] = nil
	table.insert(outbox.restored, index)
end

-- Changes since the last call, as two index lists (nil, nil when there are none).
function WorldSpawner.flushLight(): ({ number }?, { number }?)
	if #outbox.taken == 0 and #outbox.restored == 0 then
		return nil, nil
	end
	local taken, restored = outbox.taken, outbox.restored
	outbox = { taken = {}, restored = {} }
	return taken, restored
end

-- Every taken index, for a join or periodic snapshot.
function WorldSpawner.takenLightIndices(): { number }
	local list: { number } = {}
	for index in pendingLight do
		table.insert(list, index)
	end
	return list
end

-- The doorstep rows of spawn slot `slot` (first, last), or nil.
local function doorstepRange(slot: number): { number }?
	if lightData == nil then
		return nil
	end
	return lightData.ranges[string.format("doorstep_%02d", slot)]
end

-- The spawner reads ball positions through this function so it never requires BallService (which requires
-- the spawner).
function WorldSpawner.setWatcherSource(source: () -> { Respawn.Watcher })
	watcherSource = source
end

function WorldSpawner.getObject(id: string): PooledWorldObject?
	return registry[id]
end

-- Where a ball rests at spawn slot `index` (1-based, wraps over the world's spawn points).
function WorldSpawner.getSpawnSlot(index: number): Vector3
	local points = Worlds.active.spawnPoints
	local point = points[(index - 1) % #points + 1]
	return Vector3.new(point.x, point.y + Worlds.rules.startDiameter / 2 + 0.5, point.z)
end

-- Where a ball rests on the hub plaza: the hub centre plus the data offset, just above the floor.
function WorldSpawner.getHubSpawn(): Vector3
	local hub = Worlds.active.hub
	return Vector3.new(
		hub.center.x + hub.spawn.x,
		Worlds.rules.startDiameter / 2 + 0.5,
		hub.center.z + hub.spawn.z
	)
end

function WorldSpawner.markTaken(object: PooledWorldObject, now: number, holderKey: string)
	object.state = "Taken"
	object.takenAt = now
	object.respawnAt = now
		+ Respawn.delayFrom(random:NextNumber(), Config.respawnDelayMin, Config.respawnDelayMax)
	object.availableAt = nil
	object.holderKey = holderKey
	pending[object] = true
	setTaken(object, true)
end

-- True while the object is still waiting to respawn from the pickup that created this stack entry.
function WorldSpawner.isHeldBy(object: PooledWorldObject, holderKey: string): boolean
	return object.state == "Taken" and object.holderKey == holderKey
end

-- Ground height under a point, from the static geometry. Nil when nothing is below it.
local function groundHeight(position: Vector3): number?
	local origin = Vector3.new(position.X, position.Y + RAY_HEIGHT, position.Z)
	local hit = Workspace:Raycast(origin, Vector3.new(0, -RAY_LENGTH, 0), groundParams)
	return if hit then hit.Position.Y else nil
end

function WorldSpawner.scatter(object: PooledWorldObject, position: Vector3, availableAt: number)
	object.state = "Scattered"
	object.availableAt = availableAt
	object.respawnAt = nil
	object.holderKey = nil
	pending[object] = true
	setTaken(object, false)
	local ground = groundHeight(position)
	local y = if ground then ground + object.part.Size.Y / 2 else object.spawnCFrame.Y
	object.part.CFrame = CFrame.new(position.X, y, position.Z)
		* (object.spawnCFrame - object.spawnCFrame.Position)
end

-- Same part, back to where it started.
function WorldSpawner.returnToSpawn(object: PooledWorldObject)
	object.state = "Available"
	object.takenAt = nil
	object.availableAt = nil
	object.respawnAt = nil
	object.holderKey = nil
	pending[object] = nil
	setTaken(object, false)
	object.part.CFrame = object.spawnCFrame
end

-- Puts a pooled part back at its spawn point and touches no state (the Magnet release, 006 R-08). An object that
-- is not Available (taken, or scattered elsewhere on purpose) stays where it is.
function WorldSpawner.restoreHome(id: string)
	local object = registry[id]
	if object and object.state == "Available" then
		object.part.CFrame = object.spawnCFrame
	end
end

export type Candidate = {
	id: string,
	pos: { x: number, y: number, z: number },
	size: number,
	available: boolean,
}

-- Objects within `radius` studs (flat) of a point, for the Magnet scan. `available` is true when the object
-- can be absorbed right now: Available and past its scatter grace.
function WorldSpawner.candidatesNear(position: Vector3, radius: number, now: number): { Candidate }
	local found: { Candidate } = {}
	local limit = radius * radius
	for _, object in objectList do
		local at = object.part.Position
		local dx, dz = at.X - position.X, at.Z - position.Z
		if dx * dx + dz * dz <= limit then
			table.insert(found, {
				id = object.id,
				pos = { x = at.X, y = at.Y, z = at.Z },
				size = object.size,
				available = object.state == "Available"
					and (object.availableAt == nil or now >= object.availableAt),
			})
		end
	end
	return found
end

-- Ring of evenly spaced points around centre, clamped inside the town. y is left at 0.
function WorldSpawner.scatterSpots(
	centre: Vector3,
	count: number,
	radius: number,
	startAngle: number
): { Vector3 }
	local limit = Worlds.active.halfExtent - 2
	local spots: { Vector3 } = {}
	for i = 0, count - 1 do
		local angle = startAngle + (i / count) * math.pi * 2
		local x = math.clamp(centre.X + math.cos(angle) * radius, -limit, limit)
		local z = math.clamp(centre.Z + math.sin(angle) * radius, -limit, limit)
		table.insert(spots, Vector3.new(x, 0, z))
	end
	return spots
end

-- Scattered objects become absorbable when their grace ends. A Taken object returns once its random delay is
-- over and no ball can see its spot, or after the starvation ceiling whatever is watching. It returns even
-- while a ball still shows it: stack entries are visual-only records, so the world refills.
function WorldSpawner.update(now: number)
	local watchers: { Respawn.Watcher }? = nil
	if lightData ~= nil then
		for index in pendingLight do
			local respawnAt, takenAt = lightRespawnAt[index], lightTakenAt[index]
			if
				respawnAt
				and takenAt
				and (now >= respawnAt or now >= takenAt + Config.respawnForceAfterSeconds)
			then
				if watchers == nil then
					watchers = watcherSource()
				end
				local at = (index - 1) * lightData.stride
				if
					Respawn.canRespawn(
						now,
						takenAt,
						respawnAt,
						{ x = lightData.data[at + 2], z = lightData.data[at + 4] },
						watchers :: { Respawn.Watcher },
						sightParams,
						Config.respawnForceAfterSeconds
					)
				then
					restoreLight(index)
				end
			end
		end
	end
	for object in pending do
		if object.state == "Scattered" then
			local availableAt = object.availableAt
			if availableAt and now >= availableAt then
				object.state = "Available"
				object.availableAt = nil
				pending[object] = nil
			end
		elseif object.state == "Taken" then
			local respawnAt = object.respawnAt
			local takenAt = object.takenAt
			if
				respawnAt
				and takenAt
				and (now >= respawnAt or now >= takenAt + Config.respawnForceAfterSeconds)
			then
				if watchers == nil then
					watchers = watcherSource()
				end
				local position = object.spawnCFrame.Position
				if
					Respawn.canRespawn(
						now,
						takenAt,
						respawnAt,
						{ x = position.X, z = position.Z },
						watchers :: { Respawn.Watcher },
						sightParams,
						Config.respawnForceAfterSeconds
					)
				then
					WorldSpawner.returnToSpawn(object)
				end
			end
		end
	end
end

-- Run start at a spawn point: its Taken or Scattered cluster objects come straight back, with no sight check,
-- so the first pickup is always within reach (spec edge case "Spawn Cluster Availability").
function WorldSpawner.refreshCluster(slot: number, _now: number)
	local range = doorstepRange((slot - 1) % #Worlds.active.spawnPoints + 1)
	if range ~= nil then
		for index = range[1], range[2] do
			if lightState[index] == 1 then
				restoreLight(index)
			end
		end
	end
	local cluster = clusters[(slot - 1) % #Worlds.active.spawnPoints + 1]
	if cluster == nil then
		return
	end
	for _, object in cluster do
		if object.state ~= "Available" then
			WorldSpawner.returnToSpawn(object)
		end
	end
end

function WorldSpawner.availableInCluster(slot: number): number
	local range = doorstepRange(slot)
	if range ~= nil then
		local free = 0
		for index = range[1], range[2] do
			if lightState[index] ~= 1 then
				free += 1
			end
		end
		return free
	end
	local cluster = clusters[slot]
	if cluster == nil then
		return 0
	end
	local available = 0
	for _, object in cluster do
		if object.state == "Available" then
			available += 1
		end
	end
	return available
end

function WorldSpawner.registryCounts(): { free: number, pendingRespawn: number }
	local free = 0
	local pendingRespawn = 0
	for _, object in objectList do
		if object.state == "Taken" then
			pendingRespawn += 1
		else
			free += 1
		end
	end
	return { free = free, pendingRespawn = pendingRespawn }
end

function WorldSpawner.countsByTier(): { [number]: { available: number, total: number } }
	local counts: { [number]: { available: number, total: number } } = {}
	for _, object in objectList do
		local entry = counts[object.tier]
		if entry == nil then
			entry = { available = 0, total = 0 }
			counts[object.tier] = entry
		end
		entry.total += 1
		if object.state == "Available" then
			entry.available += 1
		end
	end
	return counts
end

-- Test helper: every object back at its spawn point, available, with no timers.
function WorldSpawner.reset()
	for index in pendingLight do
		restoreLight(index)
	end
	for _, object in objectList do
		WorldSpawner.returnToSpawn(object)
	end
end

return WorldSpawner
