--!strict
-- Owner-only debug readout for the SC-004 phone check: current, average and lowest frames per second, plus
-- the ball diameter, so the lowest reading can be tied to Tier 4. It is shown only to the experience creator
-- (Config.Flags.DebugFps), so players never see it. Not player-facing text, so the labels are not localised.
-- Tap it to reset the average and the lowest reading.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local UiKit = require(script.Parent.UiKit)

local DISPLAY_ORDER = 50
-- 360 wide stays clear of the 120 px thumb zone and the 96 px Jump zone at 640 x 360.
local WIDTH = 360
local HEIGHT = 32
local BOTTOM_MARGIN = 8
local READOUT_FORMAT = "%d | avg %d | min %d | size %.1f"

local FpsReadout = {}

function FpsReadout.start()
	local player = Players.LocalPlayer
	if not Config.Flags.DebugFps or game.CreatorId ~= player.UserId then
		return
	end

	local gui = UiKit.screen("FpsReadout", DISPLAY_ORDER)
	local button = Instance.new("TextButton")
	button.Name = "Readout"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -BOTTOM_MARGIN)
	button.Size = UDim2.fromOffset(WIDTH, HEIGHT)
	button.BackgroundColor3 = Color3.new(0, 0, 0)
	button.BackgroundTransparency = 0.4
	button.Font = Enum.Font.GothamMedium
	button.TextSize = Config.minTextSize
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = gui

	local frames = 0
	local windowStart = os.clock()
	local lowest = math.huge
	local sum = 0
	local seconds = 0
	local lastShown = 0
	local ignoreUntil = windowStart + Config.debugFpsWarmupSeconds

	local function reset()
		lowest = math.huge
		sum = 0
		seconds = 0
		ignoreUntil = os.clock() + Config.debugFpsWarmupSeconds
	end
	button.Activated:Connect(reset)

	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		if now - windowStart < 1 then
			return
		end
		local fps = math.floor(frames / (now - windowStart) + 0.5)
		frames = 0
		windowStart = now
		lastShown = fps
		if now >= ignoreUntil then
			lowest = math.min(lowest, fps)
			sum += fps
			seconds += 1
		end
		local ball = Workspace:FindFirstChild("Balls")
		local ballPart = ball and ball:FindFirstChild(`Ball_{player.UserId}`)
		local diameter = ballPart and ballPart:GetAttribute("Diameter")
		button.Text = string.format(
			READOUT_FORMAT,
			lastShown,
			if seconds > 0 then sum / seconds else lastShown,
			if lowest == math.huge then lastShown else lowest,
			if typeof(diameter) == "number" then diameter else 0
		)
	end)
end

return FpsReadout
