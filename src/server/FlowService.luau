--!strict
-- Food flow: keeps food a ball can eat within reach of it, so growth never stalls after the ball has cleared the
-- patch around it. The formula is Rules/Flow; this service counts, picks and places.
--
-- Light food (the smallest two tiers, data only) regrows where it was, a few seconds after it was eaten and once
-- every ball has moved away. Bigger objects are Parts: when a ball's ring holds too few worthwhile pieces, objects
-- of the right size are brought in from what was just eaten and from the parts of the map nobody is using, and set
-- down ahead of the ball. Nothing is created: the map's own objects move.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Absorb = require(Shared.Rules.Absorb)
local Flow = require(Shared.Rules.Flow)
local Worlds = require(Shared.Worlds)
local BallService = require(script.Parent.BallService)
local RunManager = require(script.Parent.RunManager)
local WorldSpawner = require(script.Parent.WorldSpawner)

type Session = BallService.Session
type PooledWorldObject = WorldSpawner.PooledWorldObject

local FlowService = {}

local tuning = (Config.Flow :: any) :: Flow.Tuning
local random = Random.new()
local nextAt = 0

-- Every pooled object with the diameter it asks for, sorted by that need.
local byNeed: { PooledWorldObject } = {}
local needOf: { [PooledWorldObject]: number } = {}
local overlap = OverlapParams.new()
-- Where the players' balls are, as of this tick.
local ballPositions: { Vector3 } = {}

local function inSlice(x: number, z: number, margin: number): boolean
	local slice = Config.Slice
	if not slice.enabled then
		return true
	end
	return x > slice.minX + margin
		and x < slice.maxX - margin
		and z > slice.minZ + margin
		and z < slice.maxZ - margin
end

local function buildIndex()
	for _, object in WorldSpawner.allObjects() do
		local def = Worlds.objectById[object.objectId]
		local bulk = if def then Worlds.bulkOf(def) else object.size
		needOf[object] = Absorb.needsDiameter(Worlds.rules.absorb, bulk, object.size)
		table.insert(byNeed, object)
	end
	table.sort(byNeed, function(a: PooledWorldObject, b: PooledWorldObject): boolean
		return needOf[a] < needOf[b]
	end)
	local world = Workspace:FindFirstChild("World")
	local geometry = if world then world:FindFirstChild("Geometry") else nil
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = if geometry then { geometry } else {}
end

-- First index whose need is at least `need`.
local function lowerBound(need: number): number
	local low, high = 1, #byNeed + 1
	while low < high do
		local middle = (low + high) // 2
		if needOf[byNeed[middle]] < need then
			low = middle + 1
		else
			high = middle
		end
	end
	return low
end

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

-- An object the flow may move: eaten a moment ago, or standing where no ball can use it (outside the section).
local function movable(object: PooledWorldObject, now: number): boolean
	if object.spawnSlot ~= nil then
		return false
	end
	if object.state == "Taken" then
		local takenAt = object.takenAt
		return takenAt ~= nil and now - takenAt >= Config.Flow.reuseAfterSeconds
	end
	if object.state == "Available" and Config.Slice.enabled then
		local at = object.part.Position
		return not inSlice(at.X, at.Z, 0)
	end
	if object.state == "Scattered" then
		-- Set down earlier and left behind: free again once no ball is anywhere near it.
		local at = object.part.Position
		local limit = Config.Flow.strayRadius ^ 2
		for _, ball in ballPositions do
			if (at.X - ball.X) ^ 2 + (at.Z - ball.Z) ^ 2 < limit then
				return false
			end
		end
		return true
	end
	return false
end

-- A movable object whose need is close to `need`: a random pick among those inside the tolerance.
local function pick(need: number, diameter: number, now: number): PooledWorldObject?
	local tolerance = Config.Flow.needTolerance
	local low = lowerBound(need * (1 - tolerance))
	local high = lowerBound(math.min(diameter, need * (1 + tolerance)) + 1e-6) - 1
	if high < low then
		return nil
	end
	local start = random:NextInteger(low, high)
	local span = high - low + 1
	for step = 0, span - 1 do
		local object = byNeed[low + (start - low + step) % span]
		if movable(object, now) then
			return object
		end
	end
	return nil
end

-- A free spot for this object in the ball's ring, or nil when the tries run out.
local function place(
	session: Session,
	object: PooledWorldObject,
	radius: number,
	balls: { Session }
): Vector3?
	local centre = session.part.Position
	local heading = flat(session.part.AssemblyLinearVelocity)
	local hx, hz = 0, 0
	if heading.Magnitude >= Config.respawnHeadingMinSpeed then
		hx, hz = heading.Unit.X, heading.Unit.Z
	end
	local floor = centre.Y - session.physicalDiameter / 2
	local size = object.part.Size
	for _ = 1, Config.Flow.placeTries do
		local dx, dz = Flow.offset(radius, hx, hz, random:NextNumber(), random:NextNumber(), tuning)
		local x, z = centre.X + dx, centre.Z + dz
		if not inSlice(x, z, object.size) then
			continue
		end
		local clear = true
		for _, other in balls do
			local limit = Config.Flow.clearFloor
				+ Config.Flow.clearDiameters * other.physicalDiameter
				+ object.size / 2
			local at = other.part.Position
			if (x - at.X) ^ 2 + (z - at.Z) ^ 2 < limit * limit then
				clear = false
				break
			end
		end
		if not clear then
			continue
		end
		-- Level with the ball: not on a roof, a plinth or the bottom of the pond.
		local ground = WorldSpawner.groundAt(Vector3.new(x, centre.Y, z))
		if ground == nil or math.abs(ground - floor) > Config.Flow.groundTolerance then
			continue
		end
		-- Turned the way the object will stand, so a long car is checked along its length.
		local spot = CFrame.new(x, ground + size.Y / 2, z)
			* (object.spawnCFrame - object.spawnCFrame.Position)
		if #Workspace:GetPartBoundsInBox(spot, size, overlap) > 0 then
			continue
		end
		return Vector3.new(x, ground, z)
	end
	return nil
end

local function countWorth(session: Session, radius: number, now: number): number
	local centre = session.part.Position
	local diameter = session.authoritativeDiameter
	local low = lowerBound(tuning.worthShare * diameter)
	local reach = radius * radius
	local count = 0
	for index = low, #byNeed do
		local object = byNeed[index]
		if needOf[object] > diameter then
			break
		end
		if
			object.state == "Available"
			or (
				object.state == "Scattered"
				and object.availableAt ~= nil
				and now >= object.availableAt
			)
		then
			local at = object.part.Position
			if (at.X - centre.X) ^ 2 + (at.Z - centre.Z) ^ 2 <= reach then
				count += 1
			end
		end
	end
	return count
end

-- A free spot for this object in a ring round a fixed point on the ground.
local function placeAround(centre: Vector3, object: PooledWorldObject, balls: { Session }): Vector3?
	local shake = Config.Shake
	local size = object.part.Size
	for _ = 1, Config.Flow.placeTries do
		local angle = random:NextNumber() * math.pi * 2
		local distance = shake.ringMin + random:NextNumber() * (shake.ringMax - shake.ringMin)
		local x, z = centre.X + math.cos(angle) * distance, centre.Z + math.sin(angle) * distance
		if not inSlice(x, z, object.size) then
			continue
		end
		local clear = true
		for _, other in balls do
			local limit = other.physicalDiameter / 2 + object.size / 2 + Config.Flow.clearFloor
			local at = other.part.Position
			if (x - at.X) ^ 2 + (z - at.Z) ^ 2 < limit * limit then
				clear = false
				break
			end
		end
		if not clear then
			continue
		end
		local ground = WorldSpawner.groundAt(Vector3.new(x, centre.Y + 4, z))
		if ground == nil or math.abs(ground - centre.Y) > Config.Flow.groundTolerance then
			continue
		end
		local spot = CFrame.new(x, ground + size.Y / 2, z)
			* (object.spawnCFrame - object.spawnCFrame.Position)
		if #Workspace:GetPartBoundsInBox(spot, size, overlap) > 0 then
			continue
		end
		return Vector3.new(x, ground, z)
	end
	return nil
end

-- Drops food round `centre` for each of `eaters`, sized for that ball (Config.Shake). Returns how many pieces fell.
function FlowService.burst(
	centre: Vector3,
	eaters: { Session },
	balls: { Session },
	now: number
): number
	if #byNeed == 0 then
		return 0
	end
	local fell = 0
	for _, session in eaters do
		local diameter = session.authoritativeDiameter
		for _ = 1, Config.Shake.perPlayer do
			local object = pick(Flow.pickNeed(diameter, random:NextNumber(), tuning), diameter, now)
			if object == nil then
				break
			end
			local spot = placeAround(centre, object, balls)
			if spot then
				WorldSpawner.scatter(object, spot, now)
				fell += 1
			end
		end
	end
	return fell
end

-- Once per Heartbeat; does its work every Config.Flow.interval seconds.
function FlowService.step(now: number)
	if not Config.Flow.enabled or #byNeed == 0 or now < nextAt then
		return
	end
	nextAt = now + Config.Flow.interval
	if not RunManager.roundActive(now) then
		return
	end

	local balls: { Session } = {}
	local positions: { Vector3 } = {}
	for _, session in BallService.allSessions() do
		if not session.frozen and not session.streamHold and session.zone == "Room" then
			table.insert(balls, session)
			table.insert(positions, session.part.Position)
		end
	end

	-- Placed food is for players: a bot has its pace curve, and a dozen bots would use up the stock. A piece is
	-- "left behind" once no player is near it, wherever the bots are.
	local playerPositions: { Vector3 } = {}
	for _, session in balls do
		if session.player ~= nil then
			table.insert(playerPositions, session.part.Position)
		end
	end
	ballPositions = playerPositions

	for _, session in balls do
		local diameter = session.authoritativeDiameter
		if diameter > Config.Flow.maxDiameter then
			continue
		end
		local radius = Flow.radius(diameter, tuning)
		WorldSpawner.regrowLightNear(
			session.part.Position,
			radius,
			Config.Flow.lightKeepAway,
			positions,
			Config.Flow.lightSeconds,
			Config.Flow.lightPerTick,
			now
		)
		if session.player == nil then
			continue
		end
		local target, perTick = Flow.quota(diameter, tuning)
		local missing = Flow.deficit(countWorth(session, radius, now), target)
		for _ = 1, math.min(missing, perTick) do
			local need = Flow.pickNeed(diameter, random:NextNumber(), tuning)
			local object = pick(need, diameter, now)
			if object == nil then
				break
			end
			local spot = place(session, object, radius, balls)
			if spot then
				WorldSpawner.scatter(object, spot, now)
			end
		end
	end
end

function FlowService.start()
	if not Config.Flow.enabled or not Config.Flags.ParkCity then
		return
	end
	buildIndex()
end

return FlowService
