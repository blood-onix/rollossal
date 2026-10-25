--!strict
-- Hub screen (contracts/ui.md "Hub screen"): one big Play button while the ball rests on the plaza.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local RunClient = require(script.Parent.RunClient)
local UiKit = require(script.Parent.UiKit)

local CARD_WIDTH = 300
local CARD_HEIGHT = 180
local CARD_BOTTOM_OFFSET = 16
local TITLE_SIZE = 28
local TITLE_HEIGHT = 40
local PLAY_WIDTH = 260
local PLAY_HEIGHT = 96

local HubUi = {}

function HubUi.start()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local gui = UiKit.screen("HubUi")

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -CARD_BOTTOM_OFFSET)
	card.Size = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	card.BackgroundTransparency = 1
	card.Visible = false
	card.Parent = gui

	UiKit.label({
		parent = card,
		name = "Title",
		text = Localizer.t("ui.hub.title"),
		size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
		position = UDim2.fromOffset(0, 0),
		textSize = TITLE_SIZE,
		heading = true,
	})
	local play = UiKit.button({
		parent = card,
		name = "Play",
		text = `{Icons.play} {Localizer.t("ui.hub.play")}`,
		width = PLAY_WIDTH,
		height = PLAY_HEIGHT,
		position = UDim2.fromScale(0.5, 1),
		anchor = Vector2.new(0.5, 1),
	})
	play.Activated:Connect(function()
		(Remotes:WaitForChild("RollAgain") :: RemoteEvent):FireServer()
	end)

	local function refresh()
		card.Visible = RunClient.state() == "Hub"
	end
	RunClient.stateChanged:Connect(refresh)
	refresh()
end

return HubUi
