--!strict
-- Icon-plus-text chips for every effect on the local ball (006, research R-17): Dash, Magnet, Sticky coat and
-- Slick trail from the ball's Boost attributes, Slippery! and Slowed from the surface the ball is rolling on.
-- Meaning is never colour or sound alone; text is at least 18 px (UiKit.label raises it to Config.minTextSize).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local BallController = require(script.Parent.BallController)
local UiKit = require(script.Parent.UiKit)

export type Chips = { update: () -> () }

local CHIP_WIDTH = 190
local CHIP_HEIGHT = 32
local CHIP_GAP = 4
local BACKGROUND = Color3.fromRGB(20, 22, 26)
local BACKGROUND_TRANSPARENCY = 0.35

type Effect = { key: string, icon: string, attribute: string?, surface: string? }

-- Display order, top to bottom.
local EFFECTS: { Effect } = {
	{ key = "dash", icon = "dash", attribute = "BoostDash" },
	{ key = "magnet", icon = "magnet", attribute = "BoostMagnet" },
	{ key = "shield", icon = "shield", attribute = "BoostShield" },
	{ key = "slick_trail", icon = "slick", attribute = "BoostTrail" },
	{ key = "slick", icon = "slick", surface = "slick" },
	{ key = "slow", icon = "slow", surface = "slow" },
}

local EffectChips = {}

function EffectChips.create(parent: GuiObject, top: number): Chips
	local ball = Workspace:WaitForChild("Balls"):WaitForChild(`Ball_{Players.LocalPlayer.UserId}`)
	local chips: { [string]: TextLabel } = {}
	for _, effect in EFFECTS do
		local chip = UiKit.label({
			parent = parent,
			name = `Chip_{effect.key}`,
			text = "",
			size = UDim2.fromOffset(CHIP_WIDTH, CHIP_HEIGHT),
			position = UDim2.fromOffset(0, top),
			xAlign = Enum.TextXAlignment.Left,
		})
		chip.BackgroundColor3 = BACKGROUND
		chip.BackgroundTransparency = BACKGROUND_TRANSPARENCY
		chip.Visible = false
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = chip
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.Parent = chip
		chips[effect.key] = chip
	end

	local function active(effect: Effect, serverNow: number): boolean
		local attribute = effect.attribute
		if attribute then
			local ends = ball:GetAttribute(attribute)
			return typeof(ends) == "number" and ends > serverNow
		end
		return BallController.surfaces()[effect.surface :: string] == true
	end

	local function render()
		local row = 0
		local serverNow = Workspace:GetServerTimeNow()
		for _, effect in EFFECTS do
			local chip = chips[effect.key]
			local on = active(effect, serverNow)
			if on then
				chip.Position = UDim2.fromOffset(0, top + row * (CHIP_HEIGHT + CHIP_GAP))
				chip.Text = `{Icons[effect.icon]} {Localizer.t(`ui.fx.{effect.key}`)}`
				row += 1
			end
			chip.Visible = on
		end
	end

	Localizer.changed.Connect(Localizer.changed, render)
	return { update = render }
end

return EffectChips
