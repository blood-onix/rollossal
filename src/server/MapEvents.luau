--!strict
-- Map events that give every ball somewhere to go:
--   Crown zone: a glowing circle that grows any ball standing in it, and moves every so often (Config.Hill).
--   Golden drop: a golden orb under a sky beam; the first ball to touch it gets a jump in size (Config.Golden).
-- Both are built here at run time, like the launch ramps. Clients are told through two Workspace attributes:
-- EventKey (a Strings key for the banner) and EventUntil (server time the banner ends).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BallService = require(script.Parent.BallService)
local FlowService = require(script.Parent.FlowService)
local RunManager = require(script.Parent.RunManager)

type Session = BallService.Session

local GOLD = Color3.fromRGB(255, 205, 60)
local BEAM_HEIGHT = 260

local MapEvents = {}

local random = Random.new()
local folder: Folder? = nil

local hillDisc: Part? = nil
local hillBeam: Part? = nil
local hillIndex = 0
local hillMoveAt = 0
local hillTickAt = 0
-- When the zone closes because a player has started using it (math.huge while nobody has).
local hillCloseAt = math.huge
-- False while the zone is away between two appearances.
local hillOpen = false

local orb: Part? = nil
local orbBeam: Part? = nil
local orbAt: Vector3? = nil
local orbEndsAt = 0
local orbLandsAt = 0
local nextDropAt = math.huge

local function glow(name: string, shape: Enum.PartType, transparency: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = GOLD
	part.Transparency = transparency
	part.Parent = folder
	return part
end

-- A cylinder's axis is its X; this stands it upright at a point.
local function upright(position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

local function announce(key: string)
	Workspace:SetAttribute("EventKey", key)
	Workspace:SetAttribute("EventUntil", Workspace:GetServerTimeNow() + Config.eventBannerSeconds)
end

local function inPlay(session: Session, now: number): boolean
	return not session.frozen
		and not session.streamHold
		and session.zone == "Room"
		and RunManager.acceptsPickups(session.ownerUserId, now)
end

local function hide(part: Part?)
	if part then
		part.Transparency = 1
	end
end

local function moveHill(now: number)
	local spots = Config.Hill.spots
	local index = random:NextInteger(1, #spots)
	if index == hillIndex then
		index = index % #spots + 1
	end
	hillIndex = index
	hillMoveAt = now + Config.Hill.moveSeconds
	hillCloseAt = math.huge
	hillOpen = true
	local spot = spots[index]
	local radius = Config.Hill.radius
	if hillDisc and hillBeam then
		hillDisc.Size = Vector3.new(0.4, radius * 2, radius * 2)
		hillDisc.CFrame = upright(Vector3.new(spot.x, 0.3, spot.z))
		hillDisc.Transparency = Config.Hill.discTransparency
		hillBeam.Size = Vector3.new(BEAM_HEIGHT, 3, 3)
		hillBeam.CFrame = upright(Vector3.new(spot.x, BEAM_HEIGHT / 2, spot.z))
		hillBeam.Transparency = Config.Hill.beamTransparency
	end
	announce("ui.event.crown")
end

local function stepHill(now: number, playing: { Session })
	local tuning = Config.Hill
	if hillOpen and now >= hillCloseAt then
		-- A player has had their turn: the zone goes away for a while.
		hillOpen = false
		hillMoveAt = now + tuning.restSeconds
		hide(hillDisc)
		hide(hillBeam)
	end
	if now >= hillMoveAt then
		moveHill(now)
	end
	if not hillOpen or now < hillTickAt then
		return
	end
	hillTickAt = now + tuning.interval
	local spot = tuning.spots[hillIndex]
	if spot == nil then
		-- The zone has not appeared yet this round.
		return
	end
	for _, session in playing do
		local at = session.part.Position
		local reach = tuning.radius
		if
			(at.X - spot.x) ^ 2 + (at.Z - spot.z) ^ 2 <= reach * reach
			and at.Y <= session.physicalDiameter / 2 + tuning.headroom
		then
			if session.player ~= nil and hillCloseAt == math.huge then
				hillCloseAt = now + tuning.useSeconds
			end
			BallService.setDiameter(
				session,
				session.authoritativeDiameter * (1 + tuning.growPerSecond * tuning.interval)
			)
		end
	end
end

local shakeAt = math.huge

-- The Giant Oak shakes and food falls round it for every player close by.
local function stepShake(now: number, playing: { Session })
	if now < shakeAt then
		return
	end
	local tuning = Config.Shake
	shakeAt = now + tuning.every
	local centre = Vector3.new(tuning.x, 0, tuning.z)
	local near: { Session } = {}
	for _, session in playing do
		local at = session.part.Position
		if
			session.player ~= nil
			and (at.X - centre.X) ^ 2 + (at.Z - centre.Z) ^ 2 <= tuning.radius ^ 2
		then
			table.insert(near, session)
		end
	end
	if #near > 0 and FlowService.burst(centre, near, playing, now) > 0 then
		announce("ui.event.shake")
	end
end

local function dropOrb(now: number)
	-- Near a player, but not on top of one: a drop a player can reach in time is a race they can win. With no
	-- spot in that band (or no player), any spot.
	local spots = Config.Golden.spots
	local near: { { x: number, z: number } } = {}
	for _, session in BallService.allSessions() do
		if session.player ~= nil then
			local at = session.part.Position
			for _, candidate in spots do
				local distance = math.sqrt((candidate.x - at.X) ^ 2 + (candidate.z - at.Z) ^ 2)
				if distance >= Config.Golden.playerMin and distance <= Config.Golden.playerMax then
					table.insert(near, candidate)
				end
			end
		end
	end
	local pool = if #near > 0 then near else spots
	local spot = pool[random:NextInteger(1, #pool)]
	orbAt = Vector3.new(spot.x, Config.Golden.hover, spot.z)
	orbLandsAt = now + Config.Golden.fallSeconds
	orbEndsAt = orbLandsAt + Config.Golden.lifeSeconds
	nextDropAt = now + Config.Golden.every
	if orb and orbBeam then
		orb.Size = Vector3.one * Config.Golden.orbSize
		orb.Position = orbAt :: Vector3
		orb.Transparency = 0
		orbBeam.Size = Vector3.new(BEAM_HEIGHT, 2, 2)
		orbBeam.CFrame = upright(Vector3.new(spot.x, BEAM_HEIGHT / 2, spot.z))
		orbBeam.Transparency = Config.Golden.beamTransparency
	end
	announce("ui.event.golden")
end

local function clearOrb()
	orbAt = nil
	hide(orb)
	hide(orbBeam)
end

local function stepGolden(now: number, playing: { Session })
	if orbAt == nil then
		if now >= nextDropAt then
			dropOrb(now)
		end
		return
	end
	if now >= orbEndsAt then
		clearOrb()
		return
	end
	local at = orbAt :: Vector3
	-- The orb floats down its beam first, so every ball that sees the beam has time to set off for it.
	if now < orbLandsAt then
		if orb then
			local left = (orbLandsAt - now) / Config.Golden.fallSeconds
			orb.Position = at + Vector3.new(0, left * Config.Golden.fallHeight, 0)
		end
		return
	end
	if orb then
		orb.Position = at + Vector3.new(0, math.sin(now * 3) * Config.Golden.bob, 0)
	end
	for _, session in playing do
		local position = session.part.Position
		local reach = session.physicalDiameter / 2 + Config.Golden.reach
		if (position - at).Magnitude <= reach + Config.Golden.hover then
			local flatDistance = Vector3.new(position.X - at.X, 0, position.Z - at.Z).Magnitude
			if flatDistance <= reach then
				local size = session.authoritativeDiameter
				BallService.setDiameter(
					session,
					math.max(size * (1 + Config.Golden.growShare), size + Config.Golden.minGain)
				)
				clearOrb()
				return
			end
		end
	end
end

-- Where the golden orb is waiting, or nil when there is none.
-- The second value is when it lands (and can first be taken).
function MapEvents.orbPosition(): (Vector3?, number)
	return orbAt, orbLandsAt
end

-- The centre of the crown zone, or nil before the first one appears.
function MapEvents.hillPosition(): Vector3?
	if folder == nil or hillIndex == 0 or not hillOpen or not Config.Hill.enabled then
		return nil
	end
	local spot = Config.Hill.spots[hillIndex]
	return Vector3.new(spot.x, 0, spot.z)
end

-- Once per Heartbeat.
function MapEvents.step(now: number)
	if folder == nil then
		return
	end
	if not RunManager.roundActive(now) then
		return
	end
	local playing: { Session } = {}
	for _, session in BallService.allSessions() do
		if inPlay(session, now) then
			table.insert(playing, session)
		end
	end
	if Config.Hill.enabled then
		stepHill(now, playing)
	end
	if Config.Golden.enabled then
		stepGolden(now, playing)
	end
	if Config.Shake.enabled then
		stepShake(now, playing)
	end
end

local function schedule(round: RunManager.Round)
	hillMoveAt = round.startedAt + Config.Hill.firstAt
	hide(hillDisc)
	hide(hillBeam)
	hillIndex = 0
	hillOpen = false
	hillCloseAt = math.huge
	clearOrb()
	shakeAt = round.startedAt + Config.Shake.firstAt
	nextDropAt = round.startedAt + Config.Golden.firstAt
end

function MapEvents.start()
	if
		not Config.Flags.ParkCity
		or not (Config.Hill.enabled or Config.Golden.enabled or Config.Shake.enabled)
	then
		return
	end
	local world = Workspace:WaitForChild("World")
	local made = Instance.new("Folder")
	made.Name = "MapEvents"
	folder = made
	hillDisc = glow("CrownZone", Enum.PartType.Cylinder, 1)
	hillBeam = glow("CrownBeam", Enum.PartType.Cylinder, 1)
	orb = glow("GoldenOrb", Enum.PartType.Ball, 1)
	orbBeam = glow("GoldenBeam", Enum.PartType.Cylinder, 1)
	made.Parent = world
	RunManager.onRoundStart(schedule)
	-- In Studio the player can join, and the round begin, before this runs.
	local now = os.clock()
	if RunManager.roundActive(now) then
		schedule(RunManager.round())
	end
end

return MapEvents
