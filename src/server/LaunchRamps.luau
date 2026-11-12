--!strict
-- Launch ramps: a few big ramps that throw a ball rolling up them over what lies ahead (Config.Ramps). The ramp is
-- built here at run time, like the section walls; the generated map is untouched. Only players are launched: a
-- bot rolls up and drops off the end.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BallService = require(script.Parent.BallService)
local RunManager = require(script.Parent.RunManager)

type Session = BallService.Session

type Ramp = {
	start: Vector3,
	forward: Vector3,
	right: Vector3,
}

local BODY = Color3.fromRGB(255, 150, 40)
local LIP = Color3.fromRGB(255, 240, 120)
local STRIPE = Color3.fromRGB(255, 255, 255)

local LaunchRamps = {}

local ramps: { Ramp } = {}
local cooldownUntil: { [Session]: number } = setmetatable({}, { __mode = "k" }) :: any

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	colour: Color3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = colour
	part.Size = size
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function build(parent: Instance, index: number, spot: { x: number, z: number, yaw: number })
	local tuning = Config.Ramps
	local yaw = math.rad(spot.yaw)
	local forward = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
	local right = Vector3.new(forward.Z, 0, -forward.X)
	local start = Vector3.new(spot.x, 0, spot.z)
	local length, width, height = tuning.length, tuning.width, tuning.height

	-- A wedge is highest at its +Z end, so +Z points along the ramp.
	local centre = start + forward * (length / 2) + Vector3.new(0, height / 2, 0)
	local frame = CFrame.lookAt(centre, centre - forward)
	local wedge = Instance.new("WedgePart")
	wedge.Name = `Ramp{index}`
	wedge.Anchored = true
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Color = BODY
	wedge.Size = Vector3.new(width, height, length)
	wedge.CFrame = frame
	wedge.Parent = parent

	-- Glowing lip at the top edge and three stripes up the slope, so the ramp reads as "roll up here" from afar.
	local slope = math.atan2(height, length)
	local slopeFrame = CFrame.lookAt(centre, centre - forward) * CFrame.Angles(slope, 0, 0)
	for step = 1, 3 do
		local along = (step / 4 - 0.5) * math.sqrt(length * length + height * height)
		block(
			parent,
			`Ramp{index}Stripe{step}`,
			Vector3.new(width * 0.7, 0.2, 2),
			slopeFrame * CFrame.new(0, 0.15, along),
			STRIPE
		)
	end
	block(
		parent,
		`Ramp{index}Lip`,
		Vector3.new(width, 0.6, 1.5),
		CFrame.lookAt(
			start + forward * (length - 0.75) + Vector3.new(0, height + 0.3, 0),
			start + forward * length + Vector3.new(0, height + 0.3, 0)
		),
		LIP
	)
	table.insert(ramps, { start = start, forward = forward, right = right })
end

-- Once per Heartbeat: a player's ball on the top part of a ramp, rolling up it fast enough, is thrown.
function LaunchRamps.step(now: number)
	if #ramps == 0 then
		return
	end
	local tuning = Config.Ramps
	for _, session in BallService.allSessions() do
		if
			session.player == nil
			or session.frozen
			or session.streamHold
			or session.zone ~= "Room"
			or now < (cooldownUntil[session] or 0)
			or not RunManager.acceptsPickups(session.ownerUserId, now)
		then
			continue
		end
		local part = session.part
		local position = part.Position
		local velocity = part.AssemblyLinearVelocity
		for _, ramp in ramps do
			local offset = position - ramp.start
			local along = offset:Dot(ramp.forward)
			local across = math.abs(offset:Dot(ramp.right))
			if
				along < tuning.length * tuning.launchFrom
				or along > tuning.length + session.physicalDiameter / 2
				or across > tuning.width / 2
				or position.Y > tuning.height + session.physicalDiameter + tuning.launchHeadroom
			then
				continue
			end
			local speed = velocity:Dot(ramp.forward)
			if speed < tuning.minSpeed then
				continue
			end
			local up = tuning.upSpeed + tuning.upPerDiameter * session.authoritativeDiameter
			local out = math.min(
				tuning.maxForwardSpeed,
				math.max(tuning.forwardSpeed, speed * tuning.speedGain)
			)
			cooldownUntil[session] = now + tuning.cooldown
			-- The same allowance a spring pad gives, so the speed and height checks expect the flight.
			session.springUntil = now + tuning.flightSeconds
			session.springVy = up
			session.boostGraceUntil =
				math.max(session.boostGraceUntil, session.springUntil + Config.boostDecayGrace)
			BallService.publishLaunch(session, ramp.forward * out + Vector3.new(0, up, 0))
			break
		end
	end
end

function LaunchRamps.start()
	if not Config.Ramps.enabled or not Config.Flags.ParkCity then
		return
	end
	local world = Workspace:WaitForChild("World")
	local folder = Instance.new("Folder")
	folder.Name = "LaunchRamps"
	for index, spot in Config.Ramps.spots do
		build(folder, index, spot)
	end
	folder.Parent = world
end

return LaunchRamps
