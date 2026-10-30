--!strict
-- Boosters (006): validates ClaimBooster, keeps each ball's active effects, drifts Magnet-pulled parts, launches a
-- Spring, and lays the Slick Trail from a fixed pool of patches. The client claims by marker id only; the server
-- decides everything (Constitution II). Time is passed in.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Boosters = require(Shared.Rules.Boosters)
local RateLimit = require(Shared.Rules.RateLimit)
local Worlds = require(Shared.Worlds)
local BallService = require(script.Parent.BallService)
local Remotes = require(script.Parent.Remotes)
local RunManager = require(script.Parent.RunManager)
local WorldSpawner = require(script.Parent.WorldSpawner)

type Session = BallService.Session

export type Marker = {
	markerId: string,
	subKind: string,
	position: Vector3,
	yaw: number,
	state: "Available" | "Taken",
	takenUntil: number,
	-- Nil when the booster's flags are off: the marker is known (so a claim says Disabled) but nothing is built.
	part: BasePart?,
}

type Patch = { part: Part, ownerUserId: number, droppedAt: number }

type State = {
	dashUntil: number,
	magnetUntil: number,
	trailUntil: number,
	springCooldownUntil: number,
	claimWindow: { number },
	trailLastPos: Vector3?,
	patches: { Patch },
	pulled: { [string]: boolean },
	lastScan: number,
}

local BOOSTER_TAG = "BoosterSpot"
local SURFACE_TAG = "TrapSurface"
local PARK_Y = -500
local PATCH_SIZE = Vector3.new(6, 0.2, 6)

local BoosterService = {}

local markers: { [string]: Marker } = {}
local states: { [number]: State } = {}
local pool: { Patch } = {}
local poolBuilt = false

local function stateFor(session: Session): State
	local state = states[session.ownerUserId]
	if state == nil then
		state = {
			dashUntil = -math.huge,
			magnetUntil = -math.huge,
			trailUntil = -math.huge,
			springCooldownUntil = -math.huge,
			claimWindow = {},
			trailLastPos = nil,
			patches = {},
			pulled = {},
			lastScan = -math.huge,
		}
		states[session.ownerUserId] = state
	end
	return state :: State
end

-- Server time the effect ends, for the Boost attributes and the HUD chips; 0 when it is not active.
local function publishedEnd(now: number, untilT: number): number
	if now >= untilT then
		return 0
	end
	return math.floor((Workspace:GetServerTimeNow() + (untilT - now)) * 100) / 100
end

local function publish(session: Session, state: State, now: number)
	local part = session.part
	part:SetAttribute("BoostDash", publishedEnd(now, state.dashUntil))
	part:SetAttribute("BoostMagnet", publishedEnd(now, state.magnetUntil))
	part:SetAttribute("BoostShield", publishedEnd(now, session.shieldUntil))
	part:SetAttribute("BoostTrail", publishedEnd(now, state.trailUntil))
end

local function buildPool()
	if poolBuilt then
		return
	end
	poolBuilt = true
	-- A pool left behind by an earlier build (an Edit-mode spec run) is replaced, never doubled.
	local old = Workspace:FindFirstChild("TrailPatches")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "TrailPatches"
	folder.Parent = Workspace
	for index = 1, Config.slickTrailPoolSize do
		local part = Instance.new("Part")
		part.Name = `Patch_{index}`
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Size = PATCH_SIZE
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(170, 205, 235)
		part.Transparency = 0.4
		part.CFrame = CFrame.new(0, PARK_Y, 0)
		part:SetAttribute("Kind", "slick")
		part:SetAttribute("OwnerUserId", 0)
		part:SetAttribute("ExpiresAt", 0)
		part:SetAttribute("HalfX", PATCH_SIZE.X / 2)
		part:SetAttribute("HalfZ", PATCH_SIZE.Z / 2)
		part:SetAttribute("Yaw", 0)
		CollectionService:AddTag(part, SURFACE_TAG)
		part.Parent = folder
		table.insert(pool, { part = part, ownerUserId = 0, droppedAt = -math.huge })
	end
end

local function parkPatch(patch: Patch)
	patch.ownerUserId = 0
	patch.droppedAt = -math.huge
	patch.part:SetAttribute("OwnerUserId", 0)
	patch.part:SetAttribute("ExpiresAt", 0)
	patch.part.CFrame = CFrame.new(0, PARK_Y, 0)
end

local function removeFromOwner(patch: Patch)
	local state = states[patch.ownerUserId]
	if state then
		local index = table.find(state.patches, patch)
		if index then
			table.remove(state.patches, index)
		end
	end
end

-- A free patch, else the oldest one anywhere (the pool is shared by all balls and never grows).
local function acquirePatch(): Patch
	local oldest: Patch = pool[1]
	for _, patch in pool do
		if patch.ownerUserId == 0 then
			return patch
		end
		if patch.droppedAt < oldest.droppedAt then
			oldest = patch
		end
	end
	removeFromOwner(oldest)
	return oldest
end

local function dropPatch(session: Session, state: State, now: number)
	buildPool()
	-- One trail never holds more than slickTrailMaxPatches: recycle its own oldest first.
	if #state.patches >= Config.slickTrailMaxPatches then
		local own = table.remove(state.patches, 1) :: Patch
		parkPatch(own)
	end
	local patch = acquirePatch()
	patch.ownerUserId = session.ownerUserId
	patch.droppedAt = now
	local position = session.part.Position
	local ground = position.Y - session.physicalDiameter / 2
	patch.part:SetAttribute("OwnerUserId", session.ownerUserId)
	patch.part:SetAttribute(
		"ExpiresAt",
		math.floor((Workspace:GetServerTimeNow() + Config.slickTrailPatchLifetime) * 100) / 100
	)
	patch.part.CFrame = CFrame.new(position.X, ground + PATCH_SIZE.Y / 2 + 0.05, position.Z)
	table.insert(state.patches, patch)
end

-- Magnet-pulled parts go home when the magnet ends or the ball is cleared.
local function releasePulled(state: State)
	for id in state.pulled do
		WorldSpawner.restoreHome(id)
	end
	table.clear(state.pulled)
end

local function releasePatches(state: State)
	for _, patch in state.patches do
		parkPatch(patch)
	end
	table.clear(state.patches)
end

-- Run end, reset, respawn or leaving: every effect of this ball ends at once.
function BoosterService.clearSession(session: Session)
	local state = states[session.ownerUserId]
	if state == nil then
		return
	end
	releasePulled(state)
	releasePatches(state)
	state.dashUntil = -math.huge
	state.magnetUntil = -math.huge
	state.trailUntil = -math.huge
	state.trailLastPos = nil
end

function BoosterService.activeFor(
	session: Session,
	at: number?
): { dash: number, magnet: number, shield: number, trail: number }
	local state = stateFor(session)
	local now = at or os.clock()
	return {
		dash = publishedEnd(now, state.dashUntil),
		magnet = publishedEnd(now, state.magnetUntil),
		shield = publishedEnd(now, session.shieldUntil),
		trail = publishedEnd(now, state.trailUntil),
	}
end

-- Ids of the objects this ball's Magnet is drawing in now.
function BoosterService.pulledIds(session: Session): { string }
	local ids: { string } = {}
	for id in stateFor(session).pulled do
		table.insert(ids, id)
	end
	return ids
end

function BoosterService.poolSize(): number
	return #pool
end

function BoosterService.getMarker(markerId: string): Marker?
	return markers[markerId]
end

-- Studio specs and the quickstart read this to find a spot by sub-kind.
function BoosterService.markers(): { [string]: Marker }
	return markers
end

local function applyClaim(session: Session, state: State, marker: Marker, now: number)
	local sub = marker.subKind
	if sub == "dash" then
		state.dashUntil = Boosters.endsAt(now, Config.dashDuration)
		session.boostUntil = state.dashUntil
		session.boostGraceUntil = state.dashUntil + Config.boostDecayGrace
	elseif sub == "magnet" then
		state.magnetUntil = Boosters.endsAt(now, Config.magnetDuration)
	elseif sub == "shield" then
		session.shieldUntil = Boosters.endsAt(now, Config.shieldDuration)
	elseif sub == "slick_trail" then
		state.trailUntil = Boosters.endsAt(now, Config.slickTrailDuration)
		state.trailLastPos = session.part.Position
	elseif sub == "spring" then
		local yaw = math.rad(marker.yaw)
		local forward = Vector3.new(math.sin(yaw), 0, math.cos(yaw)) * Config.springForwardSpeed
		session.springUntil = now + Config.springFlightDuration
		session.springVy = Config.springVerticalSpeed
		session.boostGraceUntil =
			math.max(session.boostGraceUntil, session.springUntil + Config.boostDecayGrace)
		state.springCooldownUntil = now + Config.springCooldown
		BallService.publishLaunch(
			session,
			Vector3.new(forward.X, Config.springVerticalSpeed, forward.Z)
		)
	end
	if sub ~= "spring" then
		marker.state = "Taken"
		marker.takenUntil = now + Config.boosterRespawnDelay
		local part = marker.part
		if part then
			part:SetAttribute("Taken", true)
			part.Transparency = 0.75
		end
	end
	publish(session, state, now)
end

-- Result codes, in the order of contracts/runtime-api.md. Nothing is sent back to the client.
function BoosterService.tryClaim(session: Session, markerId: unknown, now: number): string
	if typeof(markerId) ~= "string" or #markerId < 1 or #markerId > 40 then
		return "BadArgs"
	end
	if not RunManager.acceptsPickups(session.ownerUserId, now) then
		return "NotActive"
	end
	local marker = markers[markerId]
	if marker and not Boosters.enabled(Config.Flags, marker.subKind) then
		return "Disabled"
	end
	local state = stateFor(session)
	local allowed, window = RateLimit.allow(
		state.claimWindow,
		now,
		Config.boosterClaimRateLimit,
		Config.rateLimitWindow
	)
	state.claimWindow = window
	if not allowed then
		return "RateLimited"
	end
	if marker == nil then
		return "UnknownMarker"
	end
	if marker.subKind == "spring" then
		if now < state.springCooldownUntil then
			return "Unavailable"
		end
	elseif marker.state ~= "Available" then
		return "Unavailable"
	end
	local offset = session.part.Position - marker.position
	local flat = math.sqrt(offset.X * offset.X + offset.Z * offset.Z)
	if
		flat
		> session.physicalDiameter / 2 + Config.boosterRadius + Config.absorbDistanceTolerance
	then
		return "OutOfRange"
	end
	applyClaim(session, state, marker, now)
	return "Ok"
end

local function scanMagnet(session: Session, state: State, now: number)
	local diameter = session.authoritativeDiameter
	local reach = Config.magnetRadiusFactor * diameter
	local position = session.part.Position
	local candidates = WorldSpawner.candidatesNear(position, reach, now)
	local picked = Boosters.magnetPick(
		{ x = position.X, y = position.Y, z = position.Z },
		diameter,
		candidates,
		{
			absorbRatio = Config.absorbRatio,
			radiusFactor = Config.magnetRadiusFactor,
			maxPulled = Config.magnetMaxPulled,
		}
	)
	local keep: { [string]: boolean } = {}
	for _, id in picked do
		keep[id] = true
	end
	for id in state.pulled do
		if not keep[id] then
			WorldSpawner.restoreHome(id)
			state.pulled[id] = nil
		end
	end
	for _, id in picked do
		state.pulled[id] = true
	end
end

local function driftPulled(session: Session, state: State, dt: number)
	local target = session.part.Position
	local stepLength = Config.magnetPullSpeed * dt
	for id in state.pulled do
		local object = WorldSpawner.getObject(id)
		if object == nil or object.state ~= "Available" then
			-- Taken by the absorb (or scattered): its own path moves it from here.
			state.pulled[id] = nil
			continue
		end
		local at = object.part.Position
		local offset = Vector3.new(target.X - at.X, 0, target.Z - at.Z)
		local distance = offset.Magnitude
		if distance > 0.05 then
			local move = offset.Unit * math.min(stepLength, distance)
			object.part.CFrame = object.part.CFrame + move
		end
	end
end

local function layTrail(session: Session, state: State, now: number)
	local position = session.part.Position
	local last = state.trailLastPos
	if last == nil then
		state.trailLastPos = position
		return
	end
	local travelled = Vector3.new(position.X - last.X, 0, position.Z - last.Z).Magnitude
	if Boosters.shouldDrop(travelled, Config.slickTrailSpacing) then
		dropPatch(session, state, now)
		state.trailLastPos = position
	end
end

local function expirePatches(now: number)
	for _, patch in pool do
		if
			patch.ownerUserId ~= 0
			and Boosters.trailExpire(now, patch.droppedAt, Config.slickTrailPatchLifetime)
		then
			removeFromOwner(patch)
			parkPatch(patch)
		end
	end
end

-- Once per Heartbeat: expire effects, run the Magnet and the trail, respawn taken pickups.
function BoosterService.step(now: number, dt: number)
	for _, marker in markers do
		if marker.state == "Taken" and now >= marker.takenUntil then
			marker.state = "Available"
			local part = marker.part
			if part then
				part:SetAttribute("Taken", false)
				part.Transparency = 0
			end
		end
	end
	if poolBuilt then
		expirePatches(now)
	end

	for userId, state in states do
		local session = BallService.getSessionByUserId(userId)
		if session == nil then
			continue
		end
		if Boosters.isActive(now, state.magnetUntil) and not session.frozen then
			if now - state.lastScan >= Config.magnetScanInterval then
				state.lastScan = now
				scanMagnet(session, state, now)
			end
			driftPulled(session, state, dt)
		elseif next(state.pulled) ~= nil then
			releasePulled(state)
		end
		if Boosters.isActive(now, state.trailUntil) and not session.frozen then
			layTrail(session, state, now)
		end
		publish(session, state, now)
	end
end

local function singleString(...: unknown): unknown
	if select("#", ...) ~= 1 then
		return nil
	end
	return (...)
end

-- What the ClaimBooster handler does with the raw arguments: exactly one, a string, or it is BadArgs.
function BoosterService.handle(session: Session, now: number, ...: unknown): string
	return BoosterService.tryClaim(session, singleString(...), now)
end

local function buildMarkers()
	table.clear(markers)
	-- The built parts, by marker id: absent for a booster whose flags are off.
	local parts: { [string]: BasePart } = {}
	for _, instance in CollectionService:GetTagged(BOOSTER_TAG) do
		local id = instance:GetAttribute("MarkerId")
		if instance:IsA("BasePart") and typeof(id) == "string" then
			parts[id] = instance
		end
	end
	for _, def in Worlds.resolved.environment.markers do
		if def.kind == "BoosterSpot" then
			markers[def.id] = {
				markerId = def.id,
				subKind = def.subKind,
				position = Vector3.new(def.x, def.y, def.z),
				yaw = def.yaw,
				state = "Available",
				takenUntil = 0,
				part = parts[def.id],
			}
		end
	end
end

local initialised = false

-- Reads the markers and registers for ball clearing. Needs no Remote, so the Studio specs call it directly.
function BoosterService.init()
	if initialised then
		return
	end
	initialised = true
	buildMarkers()
	BallService.onClear(BoosterService.clearSession)
end

function BoosterService.start()
	BoosterService.init()
	Remotes.ClaimBooster.OnServerEvent:Connect(function(player: Player, ...: unknown)
		local session = BallService.getSession(player)
		if session then
			BoosterService.handle(session, os.clock(), ...)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		states[player.UserId] = nil
	end)
end

-- Test helper: rebuild the marker table from the world and forget every ball's state.
function BoosterService.reset()
	for _, state in states do
		releasePulled(state)
	end
	for _, patch in pool do
		parkPatch(patch)
	end
	table.clear(states)
	buildMarkers()
end

return BoosterService
