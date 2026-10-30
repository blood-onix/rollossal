--!strict
-- Moves the local copy of every street sweeper (006, research R-11). The server builds each sweeper once at
-- the start of its loop and never moves it; every client computes the same pose from Rules/Patrol with
-- GetServerTimeNow() minus the patrol epoch, so all balls see the sweeper in the same place to within latency.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Patrol = require(Shared.Rules.Patrol)

local HAZARD_TAG = "TrapHazard"

type Sweeper = {
	part: BasePart,
	waypoints: { Patrol.Point },
	speed: number,
	epoch: number,
	y: number,
}

local HazardClient = {}

local sweepers: { [BasePart]: Sweeper } = {}

local function readWaypoints(part: BasePart): { Patrol.Point }?
	local count = part:GetAttribute("WpCount")
	if typeof(count) ~= "number" or count < 3 then
		return nil
	end
	local points: { Patrol.Point } = {}
	for index = 1, count do
		local x = part:GetAttribute(`Wp{index}X`)
		local z = part:GetAttribute(`Wp{index}Z`)
		if typeof(x) ~= "number" or typeof(z) ~= "number" then
			return nil
		end
		table.insert(points, { x = x, z = z })
	end
	return points
end

local function track(instance: Instance)
	if not instance:IsA("BasePart") or instance:GetAttribute("Kind") ~= "sweeper" then
		return
	end
	local waypoints = readWaypoints(instance)
	local epoch = instance:GetAttribute("PatrolEpoch")
	if waypoints == nil or typeof(epoch) ~= "number" then
		return
	end
	local speed = instance:GetAttribute("Speed")
	sweepers[instance] = {
		part = instance,
		waypoints = waypoints,
		speed = if typeof(speed) == "number" then speed else Config.sweeperSpeed,
		epoch = epoch,
		y = instance.Position.Y,
	}
end

function HazardClient.start()
	CollectionService:GetInstanceAddedSignal(HAZARD_TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(HAZARD_TAG):Connect(function(instance: Instance)
		if instance:IsA("BasePart") then
			sweepers[instance] = nil
		end
	end)
	for _, instance in CollectionService:GetTagged(HAZARD_TAG) do
		track(instance)
	end
	RunService.RenderStepped:Connect(function()
		local serverNow = Workspace:GetServerTimeNow()
		for _, sweeper in sweepers do
			local pose =
				Patrol.position(sweeper.waypoints, sweeper.speed, serverNow - sweeper.epoch)
			sweeper.part.CFrame = CFrame.new(pose.x, sweeper.y, pose.z)
				* CFrame.Angles(0, pose.heading, 0)
		end
	end)
end

return HazardClient
