--!strict
-- Ambient traffic (008): cars, vans and buses that drive a closed loop over the streets, so the city moves. Client-only
-- decoration read from the world data (Worlds.active.ambient.traffic). Every part is anchored, does not collide, is not
-- queryable and is never replicated; nothing here can hurt or block a ball. Position comes from Rules/Patrol with the
-- server clock, so every player sees the same car in the same place. Under Reduce motion the cars stand still.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Worlds = require(Shared.Worlds)
local Patrol = require(Shared.Rules.Patrol)

-- Length (along the road), width and height of the body, then the cabin: length, width, height, offset back.
local KINDS = {
	car = { body = Vector3.new(6.5, 3.2, 14), cabin = Vector3.new(5.4, 2.2, 7), cabinBack = -0.5 },
	van = { body = Vector3.new(7, 5.6, 17), cabin = Vector3.new(6.2, 1.8, 6), cabinBack = 4 },
	bus = { body = Vector3.new(8, 6.6, 25), cabin = Vector3.new(8.2, 1.8, 21), cabinBack = 0 },
}
local CLEARANCE = 0.5
local GLASS = Color3.fromRGB(70, 82, 104)

type Car = {
	body: Part,
	cabin: Part,
	cabinOffset: CFrame,
	bodyHeight: number,
	cabinHeight: number,
	lane: { speed: number, waypoints: { Patrol.Point }, length: number },
	phase: number,
}

local TrafficController = {}

local folder: Folder? = nil
local cars: { Car } = {}
local connection: RBXScriptConnection? = nil
local frozen = false

local function newPart(name: string, size: Vector3, colour: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = true
	part.Size = size
	part.Color = colour
	part.Material = Enum.Material.SmoothPlastic
	return part
end

local function place(car: Car, time: number)
	local lane = car.lane
	local distance = car.phase * lane.length / lane.speed
	local pose = Patrol.position(lane.waypoints, lane.speed, time + distance)
	local base = CFrame.new(pose.x, 0, pose.z) * CFrame.Angles(0, pose.heading, 0)
	car.body.CFrame = base * CFrame.new(0, CLEARANCE + car.bodyHeight / 2, 0)
	car.cabin.CFrame = base
		* CFrame.new(0, CLEARANCE + car.bodyHeight + car.cabinHeight / 2, 0)
		* car.cabinOffset
end

local function step()
	local time = if frozen then 0 else Workspace:GetServerTimeNow()
	for _, car in cars do
		place(car, time)
	end
end

function TrafficController.destroy()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
	if folder ~= nil then
		folder:Destroy()
		folder = nil
	end
	table.clear(cars)
end

-- Builds every car of every lane from the world data. The Studio specs call this directly.
function TrafficController.populate(lanes: { any })
	TrafficController.destroy()
	local root = Instance.new("Folder")
	root.Name = "AmbientTraffic"
	for _, lane in lanes do
		local length = Patrol.length(lane.waypoints)
		for index, spec in lane.cars do
			local kind = KINDS[spec.kind]
			local colour = Color3.fromRGB(spec.colour[1], spec.colour[2], spec.colour[3])
			local body = newPart(`{lane.id}_{index}_body`, kind.body, colour)
			local cabin = newPart(
				`{lane.id}_{index}_cabin`,
				kind.cabin,
				if spec.kind == "car" then GLASS else colour:Lerp(Color3.new(1, 1, 1), 0.35)
			)
			body.Parent = root
			cabin.Parent = root
			table.insert(cars, {
				body = body,
				cabin = cabin,
				cabinOffset = CFrame.new(0, 0, kind.cabinBack),
				bodyHeight = kind.body.Y,
				cabinHeight = kind.cabin.Y,
				lane = { speed = lane.speed, waypoints = lane.waypoints, length = length },
				phase = spec.phase,
			})
		end
	end
	root.Parent = Workspace
	folder = root
	step()
end

function TrafficController.setFrozen(value: boolean)
	frozen = value
	step()
end

function TrafficController.count(): number
	return #cars
end

function TrafficController.start()
	if connection ~= nil then
		return
	end
	local ambient = Worlds.active.ambient
	local lanes = if ambient ~= nil then ambient.traffic else nil
	if lanes == nil then
		return
	end
	local player = Players.LocalPlayer
	frozen = player ~= nil and player:GetAttribute("ReduceMotion") == true
	TrafficController.populate(lanes)
	if player ~= nil then
		player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
			frozen = player:GetAttribute("ReduceMotion") == true
		end)
	end
	connection = RunService.Heartbeat:Connect(step)
end

return TrafficController
