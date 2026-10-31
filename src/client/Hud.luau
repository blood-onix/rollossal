--!strict
-- Run HUD, visible only while the run is Active: timer, star targets, size meter, pickup pop, tier
-- banner and bump flash (layout in contracts/ui.md).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local RunClock = require(Shared.Rules.RunClock)
local Tiers = require(Shared.Rules.Tiers)
local Worlds = require(Shared.Worlds)
local EffectChips = require(script.Parent.EffectChips)
local RunClient = require(script.Parent.RunClient)
local UiKit = require(script.Parent.UiKit)

local TIMER_WIDTH = 170
local TIMER_HEIGHT = 44
local TIMER_TOP = 8
local MARKER_WIDTH = 100
local MARKER_HEIGHT = 36
local MARKER_TOP = 56
local TIMER_TEXT_SIZE = 28
local METER_WIDTH = 160
local METER_HEIGHT = 104
local METER_MARGIN = 8
local METER_VALUE_SIZE = 32
local METER_ROW_HEIGHT = 38
local METER_BAR_TOP = 40
local METER_BAR_HEIGHT = 14
local METER_NEXT_TOP = 58
local METER_POP_SCALE = 1.25
local METER_POP_SECONDS = 0.15
-- Banner and pop sit at fixed offsets below the size meter (which ends at y 112), so at 640x360 neither
-- covers the star row or the meter. The banner is wide enough for the longest headline at 28 px (395).
local BANNER_WIDTH = 480
local BANNER_HEIGHT = 48
local BANNER_TOP = 120
local BANNER_TEXT_SIZE = 28
local POP_WIDTH = 260
local POP_HEIGHT = 32
local POP_TOP = BANNER_TOP + BANNER_HEIGHT + 8
local BUMP_WIDTH = 140
local BUMP_HEIGHT = 32
local BUMP_Y = 0.78
-- Effect chips stack on the left, below the size meter (which ends at y 112).
local CHIPS_LEFT = METER_MARGIN
local CHIPS_TOP = 120

local Hud = {}

function Hud.start()
	local player = Players.LocalPlayer
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{player.UserId}`)

	local gui = UiKit.screen("Hud")
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	local timerFrame = Instance.new("Frame")
	timerFrame.Name = "Timer"
	timerFrame.BackgroundTransparency = 1
	timerFrame.AnchorPoint = Vector2.new(0.5, 0)
	timerFrame.Position = UDim2.new(0.5, 0, 0, TIMER_TOP)
	timerFrame.Size = UDim2.fromOffset(TIMER_WIDTH, TIMER_HEIGHT)
	timerFrame.Parent = root
	local timeLabel = UiKit.label({
		parent = timerFrame,
		name = "TimeLabel",
		text = `{Icons.clock} {Localizer.t("ui.hud.time_label")}`,
		size = UDim2.new(0, 80, 1, 0),
		position = UDim2.fromOffset(0, 0),
	})
	local timeValue = UiKit.label({
		parent = timerFrame,
		name = "TimeValue",
		text = RunClock.format(Config.runDurationSeconds),
		size = UDim2.new(0, 90, 1, 0),
		position = UDim2.fromOffset(80, 0),
		textSize = TIMER_TEXT_SIZE,
		heading = true,
	})

	local markers: { TextLabel } = {}
	local thresholds = Worlds.starThresholds
	local centre = (#thresholds + 1) / 2
	for index in thresholds do
		local offset = (index - centre) * MARKER_WIDTH
		markers[index] = UiKit.label({
			parent = root,
			name = `Star{index}`,
			text = "",
			size = UDim2.fromOffset(MARKER_WIDTH, MARKER_HEIGHT),
			position = UDim2.new(0.5, offset, 0, MARKER_TOP),
			anchor = Vector2.new(0.5, 0),
		})
	end

	local function reduceMotion(): boolean
		return player:GetAttribute("ReduceMotion") == true
	end

	-- Size meter, top left.
	local meter = Instance.new("Frame")
	meter.Name = "SizeMeter"
	meter.BackgroundTransparency = 1
	meter.Position = UDim2.fromOffset(METER_MARGIN, METER_MARGIN)
	meter.Size = UDim2.fromOffset(METER_WIDTH, METER_HEIGHT)
	meter.Parent = root
	local sizeLabel = UiKit.label({
		parent = meter,
		name = "SizeLabel",
		text = Localizer.t("ui.hud.size_label"),
		size = UDim2.fromOffset(60, METER_ROW_HEIGHT),
		position = UDim2.fromOffset(0, 0),
		xAlign = Enum.TextXAlignment.Left,
	})
	local sizeValue = UiKit.label({
		parent = meter,
		name = "SizeValue",
		text = "",
		size = UDim2.fromOffset(METER_WIDTH - 60, METER_ROW_HEIGHT),
		position = UDim2.fromOffset(60, 0),
		textSize = METER_VALUE_SIZE,
		heading = true,
		xAlign = Enum.TextXAlignment.Right,
	})
	local valueScale = Instance.new("UIScale")
	valueScale.Parent = sizeValue
	local barBack = Instance.new("Frame")
	barBack.Name = "BarBack"
	barBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.fromOffset(0, METER_BAR_TOP)
	barBack.Size = UDim2.fromOffset(METER_WIDTH, METER_BAR_HEIGHT)
	barBack.Parent = meter
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.BackgroundColor3 = Color3.fromRGB(110, 200, 120)
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.Parent = barBack
	local nextTier = UiKit.label({
		parent = meter,
		name = "NextTier",
		text = "",
		size = UDim2.fromOffset(METER_WIDTH, METER_HEIGHT - METER_NEXT_TOP),
		position = UDim2.fromOffset(0, METER_NEXT_TOP),
		xAlign = Enum.TextXAlignment.Left,
	})

	-- One-line messages in the middle of the screen.
	local function message(
		name: string,
		width: number,
		height: number,
		position: UDim2,
		anchorY: number,
		size: number?
	)
		local label = UiKit.label({
			parent = root,
			name = name,
			text = "",
			size = UDim2.fromOffset(width, height),
			position = position,
			anchor = Vector2.new(0.5, anchorY),
			textSize = size,
			heading = true,
		})
		label.Visible = false
		return label
	end
	local pop = message("PickupPop", POP_WIDTH, POP_HEIGHT, UDim2.new(0.5, 0, 0, POP_TOP), 0, nil)
	local banner = message(
		"TierBanner",
		BANNER_WIDTH,
		BANNER_HEIGHT,
		UDim2.new(0.5, 0, 0, BANNER_TOP),
		0,
		BANNER_TEXT_SIZE
	)
	local bump =
		message("BumpFlash", BUMP_WIDTH, BUMP_HEIGHT, UDim2.fromScale(0.5, BUMP_Y), 0.5, nil)

	local chipHost = Instance.new("Frame")
	chipHost.Name = "EffectChips"
	chipHost.BackgroundTransparency = 1
	chipHost.Position = UDim2.fromOffset(CHIPS_LEFT, 0)
	chipHost.Size = UDim2.fromScale(0.4, 1)
	chipHost.Parent = root
	local chips = EffectChips.create(chipHost, CHIPS_TOP)

	local function diameter(): number
		local value = ball:GetAttribute("Diameter")
		return if typeof(value) == "number" then value else 0
	end

	local function renderStars()
		local current = diameter()
		for index, threshold in thresholds do
			local reached = current >= threshold
			local target = Localizer.t("ui.hud.star_target", {
				stars = index,
				size = string.format("%.1f", threshold),
			})
			markers[index].Text = `{if reached then Icons.star else Icons.star_empty} {target}`
		end
	end

	local function renderMeter()
		local current = diameter()
		sizeValue.Text = Localizer.t("ui.hud.size_value", { size = string.format("%.1f", current) })
		barFill.Size = UDim2.fromScale(Tiers.progress(current, Worlds.tierLikes), 1)
		local index, nextMin = Tiers.lookup(current, Worlds.tierLikes)
		local following = Worlds.sizeTiers[index + 1]
		if nextMin ~= nil and following ~= nil then
			nextTier.Text = Localizer.t("ui.hud.next_tier", {
				icon = Icons.arrow,
				headline = Localizer.t(following.headlineKey),
			})
		else
			nextTier.Text = Localizer.t("ui.hud.max_tier")
		end
	end

	local lastTimerText = ""
	local function renderTimer()
		local text = RunClock.format(RunClient.remaining())
		if text ~= lastTimerText then
			lastTimerText = text
			timeValue.Text = text
		end
	end

	local function refresh()
		root.Visible = RunClient.state() == "Active"
		renderTimer()
		renderStars()
		renderMeter()
	end

	-- Fades a message out over `seconds`. A newer call replaces an older one.
	local tokens: { [TextLabel]: number } = {}
	local function show(label: TextLabel, text: string, seconds: number, fade: boolean)
		local token = (tokens[label] or 0) + 1
		tokens[label] = token
		label.Text = text
		label.TextTransparency = 0
		label.Visible = true
		if fade then
			TweenService:Create(label, TweenInfo.new(seconds), { TextTransparency = 1 }):Play()
		end
		task.delay(seconds, function()
			if tokens[label] == token then
				label.Visible = false
			end
		end)
	end

	local function popMeterNumber()
		if reduceMotion() then
			return
		end
		valueScale.Scale = METER_POP_SCALE
		TweenService:Create(valueScale, TweenInfo.new(METER_POP_SECONDS), { Scale = 1 }):Play()
	end

	ball:GetAttributeChangedSignal("Diameter"):Connect(function()
		renderStars()
		renderMeter()
	end)
	RunClient.pickup:Connect(function(objectId: string)
		local object = Worlds.objectById[objectId]
		if object then
			local name = Localizer.t(object.nameKey)
			show(
				pop,
				`{Icons[object.icon]} {Localizer.t("ui.pickup.pop", { name = name })}`,
				Config.pickupPopDuration,
				true
			)
		end
		popMeterNumber()
	end)
	RunClient.tierUnlocked:Connect(function(tier: number)
		local def = Worlds.sizeTiers[tier]
		if def then
			local headline = Localizer.t(def.headlineKey)
			show(
				banner,
				`{Icons[def.headlineIcon]} {Localizer.t(
					"ui.banner.tier_unlock",
					{ headline = headline }
				)}`,
				Config.tierBannerDuration,
				false
			)
		end
	end)
	-- The flash stays even with ReduceMotion on; only the camera shake is skipped.
	RunClient.knockedOff:Connect(function()
		show(
			bump,
			`{Icons.cube} {Localizer.t("ui.bump.label")}`,
			Config.knockOffShakeDuration,
			false
		)
	end)
	RunClient.stateChanged:Connect(refresh)
	RunService.RenderStepped:Connect(function()
		if root.Visible then
			renderTimer()
			chips.update()
		end
	end)
	refresh()
	-- A language switch re-applies the static labels and rebuilds the star targets and the size meter.
	local function refreshText()
		timeLabel.Text = `{Icons.clock} {Localizer.t("ui.hud.time_label")}`
		sizeLabel.Text = Localizer.t("ui.hud.size_label")
		renderStars()
		renderMeter()
	end
	Localizer.changed.Connect(Localizer.changed, refreshText)
end

return Hud
