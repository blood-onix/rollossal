--!strict
-- A size badge floats over the giants worth going for: green over the nearest ones the ball can eat now, gold with
-- the size to reach over the next ones it is growing towards. A number and a colour, so there is nothing to translate.
-- Client only: the server still decides every pickup.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Absorb = require(Shared.Rules.Absorb)
local Config = require(Shared.Config)
local Toys = require(Shared.Rules.Toys)
local Worlds = require(Shared.Worlds)

local OBJECT_TAG = "WorldObject"
local EDIBLE_BADGES, AHEAD_BADGES = 2, 2
local REFRESH_SECONDS = 0.4
local HEADROOM = 5
local PLACEMENT_MATCH = 3
local PULSE_SPEED, PULSE_SIZE = 6, 0.1
local EDIBLE_COLOUR = Color3.fromRGB(60, 190, 90)
local AHEAD_COLOUR = Color3.fromRGB(255, 170, 30)

type Giant = Toys.Giant

type Badge = {
	gui: BillboardGui,
	anchor: Attachment,
	label: TextLabel,
	pill: Frame,
	scale: UIScale,
	edible: boolean,
}

local GiantBadges = {}

local topOf: { [Giant]: number } = {}
local partOf: { [Giant]: BasePart? } = {}

local function isGiant(objectId: string): boolean
	return string.sub(objectId, 1, 5) == "mega_" or string.sub(objectId, 1, 9) == "colossal_"
end

local function collectGiants(): { Giant }
	local giants: { Giant } = {}
	for _, placement in Worlds.placements do
		if isGiant(placement.objectId) then
			local def = Worlds.objectById[placement.objectId]
			local giant: Giant = {
				x = placement.x,
				z = placement.z,
				need = Absorb.needsDiameter(Worlds.rules.absorb, def.bulk or def.size, def.size),
			}
			topOf[giant] = placement.y + (def.dims :: { number })[3] + HEADROOM
			table.insert(giants, giant)
		end
	end
	return giants
end

local function makeBadge(parent: Instance): Badge
	local anchor = Instance.new("Attachment")
	anchor.Name = "GiantBadgeAnchor"
	anchor.Parent = Workspace.Terrain

	local gui = Instance.new("BillboardGui")
	gui.Name = "GiantBadge"
	gui.Adornee = anchor
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Size = UDim2.fromOffset(84, 46)
	gui.Enabled = false

	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.Position = UDim2.fromScale(0.5, 0.5)
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = AHEAD_COLOUR
	pill.BorderSizePixel = 0
	pill.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = pill

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 3
	stroke.Parent = pill

	local scale = Instance.new("UIScale")
	scale.Parent = pill

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 32
	label.Parent = pill

	gui.Parent = parent
	return { gui = gui, anchor = anchor, label = label, pill = pill, scale = scale, edible = false }
end

function GiantBadges.start()
	if not Config.Flags.Toys then
		return
	end
	local giants = collectGiants()
	if #giants == 0 then
		return
	end
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`) :: BasePart
	local playerGui = player:WaitForChild("PlayerGui")

	-- Parts stream in and out, so a giant's Part is matched to its placement as it arrives.
	local function attach(instance: Instance)
		local objectId = instance:GetAttribute("ObjectId")
		if
			not instance:IsA("BasePart")
			or typeof(objectId) ~= "string"
			or not isGiant(objectId)
		then
			return
		end
		for _, giant in giants do
			if
				math.abs(giant.x - instance.Position.X) < PLACEMENT_MATCH
				and math.abs(giant.z - instance.Position.Z) < PLACEMENT_MATCH
			then
				partOf[giant] = instance
				return
			end
		end
	end
	CollectionService:GetInstanceAddedSignal(OBJECT_TAG):Connect(attach)
	for _, instance in CollectionService:GetTagged(OBJECT_TAG) do
		attach(instance)
	end

	local badges: { Badge } = {}
	for _ = 1, EDIBLE_BADGES + AHEAD_BADGES do
		table.insert(badges, makeBadge(playerGui))
	end

	local sinceRefresh = REFRESH_SECONDS
	local clock = 0
	RunService.RenderStepped:Connect(function(dt: number)
		clock += dt
		local pulse = if player:GetAttribute("ReduceMotion") == true
			then 1
			else 1 + math.sin(clock * PULSE_SPEED) * PULSE_SIZE
		for _, badge in badges do
			badge.scale.Scale = if badge.edible then pulse else 1
		end

		sinceRefresh += dt
		if sinceRefresh < REFRESH_SECONDS then
			return
		end
		sinceRefresh = 0

		for _, giant in giants do
			local part = partOf[giant]
			if part and part:IsDescendantOf(Workspace) then
				giant.hidden = part:GetAttribute("Taken") == true
			end
		end

		local goals = if ball.Anchored
			then {}
			else Toys.pickGoals(
				giants,
				ball.Size.X,
				ball.Position.X,
				ball.Position.Z,
				EDIBLE_BADGES,
				AHEAD_BADGES
			)
		for index, badge in badges do
			local goal = goals[index]
			badge.gui.Enabled = goal ~= nil
			if goal ~= nil then
				local edible = goal.need <= ball.Size.X
				badge.edible = edible
				badge.anchor.WorldPosition = Vector3.new(goal.x, topOf[goal], goal.z)
				badge.pill.BackgroundColor3 = if edible then EDIBLE_COLOUR else AHEAD_COLOUR
				badge.label.Text = tostring(math.ceil(goal.need))
			else
				badge.edible = false
			end
		end
	end)
end

return GiantBadges
