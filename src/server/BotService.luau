--!strict
-- Bot rivals: server-driven balls that fill a round, so there is always someone to race, hunt and run from. A bot
-- is an ordinary ball session with no player. It rolls to the best food it can eat, claims it through AbsorbService
-- like a client would, runs from hunters in Feast and chases prey. Bots start and stop with the shared round.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Absorb = require(Shared.Rules.Absorb)
local Feast = require(Shared.Rules.Feast)
local Movement = require(Shared.Rules.Movement)
local Worlds = require(Shared.Worlds)
local AbsorbService = require(script.Parent.AbsorbService)
local BallService = require(script.Parent.BallService)
local MapEvents = require(script.Parent.MapEvents)
local RunManager = require(script.Parent.RunManager)
local WorldSpawner = require(script.Parent.WorldSpawner)

type Session = BallService.Session

type Bot = {
	session: Session,
	spin: AngularVelocity?,
	speedFactor: number,
	paceFinish: number,
	full: boolean,
	hunter: boolean,
	-- What the bot is rolling to: a food id with its position and reach, a ball, or just a direction.
	targetId: string?,
	targetAt: Vector3?,
	targetReach: number,
	prey: Session?,
	heading: Vector3,
	thinkAt: number,
	sweepAt: number,
	wanderUntil: number,
	checkAt: number,
	checkPosition: Vector3,
	avoid: { [string]: number },
	-- Turn (radians) the bot is holding to get round something it cannot eat, and until when.
	steerAngle: number,
	steerUntil: number,
	orbDelay: number,
}

local UP = Vector3.yAxis
local CELL_KEY = 4096

local BotService = {}

local bots: { Bot } = {}
local random = Random.new()
local frozen = true

-- Light objects (Park City Tiers 1 and 2) by ground cell, so a bot never walks the whole list.
local lightCells: { [number]: { number } } = {}
local lightX: { [number]: number } = {}
local lightY: { [number]: number } = {}
local lightZ: { [number]: number } = {}
local lightBulk: { [number]: number } = {}
local lightSize: { [number]: number } = {}

local function inSlice(x: number, z: number): boolean
	local slice = Config.Slice
	if not slice.enabled then
		return true
	end
	return x > slice.minX and x < slice.maxX and z > slice.minZ and z < slice.maxZ
end

local function cellOf(x: number, z: number): (number, number)
	return math.floor(x / Config.botLightCell), math.floor(z / Config.botLightCell)
end

local function cellKey(cx: number, cz: number): number
	return (cx + CELL_KEY / 2) * CELL_KEY + (cz + CELL_KEY / 2)
end

local function buildLightIndex()
	local data = Worlds.light
	if data == nil then
		return
	end
	for index = 1, data.count do
		local info = WorldSpawner.getLight(index)
		if info and inSlice(info.x, info.z) then
			lightX[index], lightY[index], lightZ[index] = info.x, info.y, info.z
			lightBulk[index], lightSize[index] = info.bulk, info.size
			local key = cellKey(cellOf(info.x, info.z))
			local cell = lightCells[key]
			if cell == nil then
				cell = {}
				lightCells[key] = cell
			end
			table.insert(cell :: { number }, index)
		end
	end
end

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function canEat(diameter: number, bulk: number, size: number): boolean
	return Absorb.canEat(Worlds.rules.absorb, diameter, bulk, size)
end

-- Worth of a food item to a ball: its bulk over the roll it costs. A player picks roughly like this (the nearest
-- thing of a decent size), not the single best item on the map, so bots do not out-eat a person. Garnish adds
-- nothing to the ball, so it is worth next to nothing.
local function score(diameter: number, bulk: number, distance: number): number
	local garnish = Worlds.rules.absorb.garnish or 0
	local gain = if bulk < garnish * diameter then bulk * Config.botGarnishWorth else bulk
	return gain / (distance + diameter)
end

-- Food far above or below the ball (on a roof, an island or a ramp) cannot be claimed from here.
local function sameLevel(session: Session, y: number, size: number): boolean
	local radius = session.physicalDiameter / 2
	return math.abs(y - session.part.Position.Y) <= radius + size / 2 + Config.botSweepReach
end

-- Equal starts: for the first part of a round bots leave the food around every player spawn alone, so a player's
-- first snacks are still there when they arrive.
local function keptForPlayers(x: number, z: number, now: number): boolean
	if now - RunManager.round().startedAt >= Config.botKeepOutSeconds then
		return false
	end
	local limit = Config.botKeepOutRadius * Config.botKeepOutRadius
	for _, slot in Config.Slice.spawnSlots do
		local spawn = WorldSpawner.getSpawnSlot(slot)
		if (x - spawn.X) ^ 2 + (z - spawn.Z) ^ 2 <= limit then
			return true
		end
	end
	return false
end

local function seekRadius(diameter: number): number
	return math.clamp(
		Config.botSeekRadiusFloor + Config.botSeekRadiusPerDiameter * diameter,
		Config.botSeekRadiusFloor,
		Config.botSeekRadius
	)
end

local function bestFood(bot: Bot, now: number): (string?, Vector3?, number)
	local session = bot.session
	local position = session.part.Position
	local diameter = session.authoritativeDiameter
	local radius = seekRadius(diameter)
	local bestId: string? = nil
	local bestAt: Vector3? = nil
	local bestReach = 0
	local bestScore = 0

	local cx, cz = cellOf(position.X, position.Z)
	local span = math.ceil(radius / Config.botLightCell)
	for dx = -span, span do
		for dz = -span, span do
			local cell = lightCells[cellKey(cx + dx, cz + dz)]
			if cell == nil then
				continue
			end
			for _, index in cell do
				local id = `L{index}`
				local avoidUntil = bot.avoid[id]
				if avoidUntil ~= nil and now < avoidUntil then
					continue
				end
				if
					not canEat(diameter, lightBulk[index], lightSize[index])
					or not sameLevel(session, lightY[index], lightSize[index])
				then
					continue
				end
				local x, z = lightX[index], lightZ[index]
				if keptForPlayers(x, z, now) then
					continue
				end
				local distance = math.sqrt((x - position.X) ^ 2 + (z - position.Z) ^ 2)
				if distance > radius then
					continue
				end
				local value = score(diameter, lightBulk[index], distance)
				if value > bestScore then
					local info = WorldSpawner.getLight(index)
					if info and not info.taken then
						bestScore = value
						bestId = id
						bestAt = Vector3.new(x, lightY[index], z)
						bestReach = lightSize[index] / 2
					end
				end
			end
		end
	end

	-- Bigger things are Parts in the pool.
	for _, candidate in WorldSpawner.candidatesNear(position, radius, now) do
		if
			not candidate.available
			or not inSlice(candidate.pos.x, candidate.pos.z)
			or keptForPlayers(candidate.pos.x, candidate.pos.z, now)
		then
			continue
		end
		local avoidUntil = bot.avoid[candidate.id]
		if avoidUntil ~= nil and now < avoidUntil then
			continue
		end
		local pooled = WorldSpawner.getObject(candidate.id)
		local def = if pooled then Worlds.objectById[pooled.objectId] else nil
		local bulk = if def then Worlds.bulkOf(def) else candidate.size
		if
			not canEat(diameter, bulk, candidate.size)
			or not sameLevel(session, candidate.pos.y, candidate.size)
		then
			continue
		end
		local distance =
			math.sqrt((candidate.pos.x - position.X) ^ 2 + (candidate.pos.z - position.Z) ^ 2)
		local value = score(diameter, bulk, distance)
		if value > bestScore then
			bestScore = value
			bestId = candidate.id
			bestAt = Vector3.new(candidate.pos.x, candidate.pos.y, candidate.pos.z)
			bestReach = candidate.size / 2
		end
	end
	return bestId, bestAt, bestReach
end

-- The closest ball that can eat this bot, and the closest it can eat, when eating is open.
local function scanBalls(bot: Bot, now: number): (Session?, Session?)
	local session = bot.session
	local position = session.part.Position
	local diameter = session.authoritativeDiameter
	local hunter: Session? = nil
	local hunterDistance = math.huge
	local prey: Session? = nil
	local preyDistance = Config.botChaseRadius
	for _, other in BallService.allSessions() do
		if other == session or other.frozen or other.streamHold or other.zone ~= "Room" then
			continue
		end
		local distance = flat(other.part.Position - position).Magnitude
		local theirs = other.authoritativeDiameter
		if Feast.canEat(theirs, diameter, Config.feastEatRatio) then
			local reach = Feast.fleeRadius(
				theirs,
				Config.feastFleeRadiusDiameters,
				Config.feastFleeRadiusFloor
			)
			if distance <= reach and distance < hunterDistance then
				hunter, hunterDistance = other, distance
			end
		elseif
			bot.hunter
			and Feast.canEat(diameter, theirs, Config.feastEatRatio)
			and now >= other.feastShieldUntil
			and distance < preyDistance
		then
			prey, preyDistance = other, distance
		end
	end
	return hunter, prey
end

local function randomHeading(): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

-- Turns a heading back into the section when the bot is at its fence.
local function keepInside(position: Vector3, heading: Vector3): Vector3
	local slice = Config.Slice
	if not slice.enabled then
		return heading
	end
	local margin = Config.botSpawnRing * 2
	local x, z = heading.X, heading.Z
	if position.X < slice.minX + margin then
		x = math.abs(x) + 0.3
	elseif position.X > slice.maxX - margin then
		x = -math.abs(x) - 0.3
	end
	if position.Z < slice.minZ + margin then
		z = math.abs(z) + 0.3
	elseif position.Z > slice.maxZ - margin then
		z = -math.abs(z) - 0.3
	end
	local turned = Vector3.new(x, 0, z)
	return if turned.Magnitude > 1e-3 then turned.Unit else heading
end

local function think(bot: Bot, now: number)
	local session = bot.session
	local position = session.part.Position
	bot.prey = nil
	if RunManager.feastOpen(now) then
		local hunter, prey = scanBalls(bot, now)
		if hunter then
			local away = flat(position - hunter.part.Position)
			bot.targetId, bot.targetAt = nil, nil
			bot.heading =
				keepInside(position, if away.Magnitude > 1e-3 then away.Unit else randomHeading())
			return
		end
		if prey then
			bot.targetId, bot.targetAt = nil, nil
			bot.prey = prey
			return
		end
	end
	-- Map events pull in the bots near them, so a golden drop is a race and the crown zone is contested.
	local orb, orbLandsAt = MapEvents.orbPosition()
	local hill = if bot.full then nil else MapEvents.hillPosition()
	local lure: Vector3? = nil
	-- A bot only notices a drop a moment after it has landed, so it never sits waiting under one.
	if
		orb
		and now >= orbLandsAt + bot.orbDelay
		and flat(orb - position).Magnitude <= Config.botOrbRadius
	then
		lure = orb
	elseif hill and flat(hill - position).Magnitude <= Config.botHillRadius then
		lure = hill
	end
	if lure then
		local towards = flat(lure - position)
		bot.targetId, bot.targetAt = nil, nil
		if towards.Magnitude > 1e-3 then
			bot.heading = towards.Unit
		end
		return
	end
	if now < bot.wanderUntil then
		return
	end
	local id: string?, at: Vector3?, reach = nil, nil, 0
	if not bot.full then
		id, at, reach = bestFood(bot, now)
	end
	bot.targetId, bot.targetAt, bot.targetReach = id, at, reach
	if id == nil then
		-- Nothing to eat in sight: pick a direction and hold it for a while, so the bot leaves the empty patch
		-- instead of circling in it.
		bot.heading = keepInside(position, randomHeading())
		bot.wanderUntil = now + Config.botExploreSeconds
	end
end

-- Claims every light object the ball is rolling over, as a player's client does on contact.
local function sweep(bot: Bot, now: number)
	local session = bot.session
	local position = session.part.Position
	local diameter = session.authoritativeDiameter
	local reach = session.physicalDiameter / 2 + Config.botSweepReach
	local cx, cz = cellOf(position.X, position.Z)
	local span = math.ceil(reach / Config.botLightCell)
	for dx = -span, span do
		for dz = -span, span do
			local cell = lightCells[cellKey(cx + dx, cz + dz)]
			if cell == nil then
				continue
			end
			for _, index in cell do
				local size = lightSize[index]
				local offset = Vector3.new(lightX[index], lightY[index], lightZ[index]) - position
				if
					offset.Magnitude <= reach + size / 2
					and canEat(diameter, lightBulk[index], size)
					and not keptForPlayers(lightX[index], lightZ[index], now)
				then
					AbsorbService.tryAbsorb(session, `L{index}`, now)
				end
			end
		end
	end
end

local steerParams = RaycastParams.new()
local steerReady = false

local function turned(heading: Vector3, angle: number): Vector3
	local cos, sin = math.cos(angle), math.sin(angle)
	return Vector3.new(heading.X * cos - heading.Z * sin, 0, heading.X * sin + heading.Z * cos)
end

-- True when something the ball can neither eat nor roll up stands in this direction.
local function blocked(part: BasePart, diameter: number, direction: Vector3, reach: number): boolean
	local radius = part.Size.X / 2 * Config.botSteerRadiusShare
	local hit = Workspace:Spherecast(part.Position, radius, direction * reach, steerParams)
	if hit == nil or hit.Normal.Y > Config.botSteerSlopeNormal then
		return false
	end
	local bulk, longest = hit.Instance:GetAttribute("Bulk"), hit.Instance:GetAttribute("Longest")
	if typeof(bulk) == "number" and typeof(longest) == "number" then
		return not canEat(diameter, bulk, longest)
	end
	return true
end

-- The heading to drive on: the wanted one, or the smallest turn away from it that is clear. A turn is held for a
-- moment so the bot goes round the obstacle instead of twitching in front of it.
local function steer(bot: Bot, heading: Vector3, speed: number, now: number): Vector3
	if not steerReady then
		local world = Workspace:FindFirstChild("World")
		if world == nil then
			return heading
		end
		steerParams.FilterType = Enum.RaycastFilterType.Include
		steerParams.FilterDescendantsInstances = { world }
		steerParams.RespectCanCollide = true
		steerReady = true
	end
	if now < bot.steerUntil then
		return turned(heading, bot.steerAngle)
	end
	local part = bot.session.part
	local diameter = bot.session.authoritativeDiameter
	local reach = part.Size.X / 2 + speed * Config.botSteerLookSeconds
	if not blocked(part, diameter, heading, reach) then
		return heading
	end
	local side = if random:NextNumber() < 0.5 then 1 else -1
	for _, degrees in Config.botSteerAngles do
		for _, sign in { side, -side } do
			local angle = math.rad(degrees) * sign
			local way = turned(heading, angle)
			if not blocked(part, diameter, way, reach) then
				bot.steerAngle = angle
				bot.steerUntil = now + Config.botSteerHoldSeconds
				return way
			end
		end
	end
	return heading
end

local function drive(bot: Bot, now: number)
	local session = bot.session
	local part = session.part
	local position = part.Position
	local diameter = session.authoritativeDiameter

	local heading = bot.heading
	local prey = bot.prey
	if prey and prey.part.Parent ~= nil then
		local towards = flat(prey.part.Position - position)
		if towards.Magnitude > 1e-3 then
			heading = towards.Unit
		end
	elseif bot.targetAt and bot.targetId then
		local towards = flat(bot.targetAt - position)
		if towards.Magnitude <= session.physicalDiameter / 2 + bot.targetReach + 1 then
			local verdict = AbsorbService.tryAbsorb(session, bot.targetId, now)
			if verdict ~= "Ok" then
				bot.avoid[bot.targetId] = now + Config.botAvoidSeconds
			end
			bot.targetId, bot.targetAt = nil, nil
			bot.thinkAt = now
		elseif towards.Magnitude > 1e-3 then
			heading = towards.Unit
		end
	end
	bot.heading = heading

	local speed = Movement.targetSpeed(
		diameter,
		Config.baseSpeed,
		Config.startDiameter,
		Config.speedExponent,
		Movement.speedCap(diameter, Worlds.rules.speedCap)
	) * bot.speedFactor
	if session.fleeing then
		speed *= Config.feastFleeMultiplier
	end
	heading = steer(bot, heading, speed, now)
	local velocity = part.AssemblyLinearVelocity
	-- A bot never jumps: any upward speed here comes from clipping an object at full speed, and would send it
	-- hopping across the map. (A bite's throw is let through in BotService.step.)
	part.AssemblyLinearVelocity =
		Vector3.new(heading.X * speed, math.min(velocity.Y, 0), heading.Z * speed)
	local spin = bot.spin
	if spin then
		local radius = math.max(part.Size.X / 2, 0.1)
		spin.MaxTorque = Config.rollTorqueGain * part.AssemblyMass * radius * radius
		spin.AngularVelocity = UP:Cross(heading) * (speed / radius)
	end
end

-- A bot that has hardly moved is against something it cannot eat: forget the target and roll off another way.
local function unstick(bot: Bot, now: number)
	if now < bot.checkAt then
		return
	end
	local position = bot.session.part.Position
	if flat(position - bot.checkPosition).Magnitude < Config.botStuckStuds then
		if bot.targetId then
			bot.avoid[bot.targetId] = now + Config.botAvoidSeconds
		end
		bot.targetId, bot.targetAt, bot.prey = nil, nil, nil
		bot.heading = keepInside(position, randomHeading())
		bot.wanderUntil = now + Config.botWanderSeconds
	end
	bot.checkAt = now + Config.botStuckSeconds
	bot.checkPosition = position
	for id, untilTime in bot.avoid do
		if now >= untilTime then
			bot.avoid[id] = nil
		end
	end
end

-- A bot's start point: its spot from Config.botSpawns, on whatever ground or object top is there.
local function spawnPoint(index: number, count: number): Vector3
	local spots = Config.botSpawns
	local spot = spots[(index - 1) % #spots + 1]
	local x, z = spot.x, spot.z
	if index > #spots then
		local angle = (index / count) * math.pi * 2
		x += math.cos(angle) * Config.botSpawnRing
		z += math.sin(angle) * Config.botSpawnRing
	end
	local ground = 0
	local world = Workspace:FindFirstChild("World")
	if world then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { world }
		local hit = Workspace:Raycast(
			Vector3.new(x, Config.botSpawnDrop, z),
			Vector3.new(0, -2 * Config.botSpawnDrop, 0),
			params
		)
		if hit then
			ground = hit.Position.Y
		end
	end
	return Vector3.new(x, ground + Worlds.rules.startDiameter, z)
end

local function setFrozen(value: boolean)
	frozen = value
	for _, bot in bots do
		BallService.setFrozen(bot.session, value)
	end
end

local function resetAll(now: number)
	for _, bot in bots do
		local session = bot.session
		session.zone = "Room"
		BallService.resetBall(session)
		bot.targetId, bot.targetAt, bot.prey = nil, nil, nil
		bot.heading = randomHeading()
		bot.thinkAt = now + random:NextNumber(0, Config.botThinkSeconds)
		bot.sweepAt = now
		bot.wanderUntil = now
		bot.checkAt = now + Config.botStuckSeconds
		bot.checkPosition = session.part.Position
		table.clear(bot.avoid)
	end
	setFrozen(false)
end

-- Once per Heartbeat.
function BotService.step(now: number)
	if #bots == 0 then
		return
	end
	if not RunManager.roundActive(now) then
		if not frozen then
			setFrozen(true)
		end
		return
	end
	for _, bot in bots do
		local session = bot.session
		if session.frozen or session.streamHold then
			continue
		end
		if now >= bot.thinkAt then
			bot.thinkAt = now + Config.botThinkSeconds
			-- A bot that has fallen behind its pace curve is lifted to it.
			local round = RunManager.round()
			local floor = Feast.paceFloor(
				now - round.startedAt,
				round.endsAt - round.startedAt,
				Worlds.rules.startDiameter,
				bot.paceFinish,
				Config.botPaceExponent
			)
			local size = session.authoritativeDiameter
			if size < floor then
				-- A little per thought, so a bot that was just bitten recovers over seconds, not at once.
				BallService.setDiameter(session, math.min(floor, size * Config.botPaceStep))
			end
			-- A bot far ahead of its curve stops eating food until the curve catches up, so no rival is a
			-- giant when Feast opens. It still rolls about, flees and hunts.
			bot.full = size > floor * Config.botPaceCeiling + Config.botPaceCeilingHead
			think(bot, now)
		end
		if now >= bot.sweepAt then
			bot.sweepAt = now + Config.botSweepSeconds
			if not bot.full then
				sweep(bot, now)
			end
		end
		-- Thrown by a bite: let the knock carry the ball before it steers again.
		if
			now >= session.feastShieldUntil
			or session.part.AssemblyLinearVelocity.Y <= Config.feastBiteKnockUp / 2
		then
			drive(bot, now)
		end
		unstick(bot, now)
	end
end

function BotService.start()
	if Config.botCount <= 0 or not Config.Flags.ParkCity or not Config.Flags.RunLoop then
		return
	end
	buildLightIndex()
	local count = Config.botCount
	for index = 1, count do
		local name = Config.botNames[(index - 1) % #Config.botNames + 1]
		local session = BallService.newSession(-index, nil, name)
		session.spawnOverride = spawnPoint(index, count)
		session.part.Color = Color3.fromHSV((index - 1) / count, 0.55, 1)
		local share = if count > 1 then (index - 1) / (count - 1) else 1
		table.insert(bots, {
			session = session,
			spin = session.part:FindFirstChildOfClass("AngularVelocity"),
			speedFactor = Config.botSpeedMin + (Config.botSpeedMax - Config.botSpeedMin) * share,
			full = false,
			paceFinish = Config.botPaceFinishMin
				+ (Config.botPaceFinishMax - Config.botPaceFinishMin) * share,
			hunter = index % 3 ~= 0,
			targetId = nil,
			targetAt = nil,
			targetReach = 0,
			prey = nil,
			heading = randomHeading(),
			thinkAt = 0,
			sweepAt = 0,
			wanderUntil = 0,
			checkAt = 0,
			checkPosition = session.part.Position,
			avoid = {},
			steerAngle = 0,
			orbDelay = random:NextNumber(Config.botOrbDelayMin, Config.botOrbDelayMax),
			steerUntil = 0,
		})
	end
	RunManager.onRoundStart(function(round: RunManager.Round)
		resetAll(round.startedAt)
	end)
	local now = os.clock()
	if RunManager.roundActive(now) then
		resetAll(now)
	else
		setFrozen(true)
	end
end

return BotService
