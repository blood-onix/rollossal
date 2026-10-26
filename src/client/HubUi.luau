--!strict
-- Hub screen (contracts/ui.md "Hub screen"): one big Play button while the ball rests on the plaza.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local Worlds = require(Shared.Worlds)
local RunClient = require(script.Parent.RunClient)
local UiKit = require(script.Parent.UiKit)
local ProfileClient = require(script.Parent.ProfileClient)

local CARD_WIDTH = 300
local CARD_HEIGHT = 236
local CARD_BOTTOM_OFFSET = 16
local TITLE_SIZE = 28
local TITLE_HEIGHT = 40
local PLAY_WIDTH = 260
local PLAY_HEIGHT = 96
local ROW_HEIGHT = 24

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

	local coinsRow = UiKit.label({
		parent = card,
		name = "Coins",
		text = "",
		size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		position = UDim2.fromOffset(0, TITLE_HEIGHT + 8),
		textSize = 18,
	})
	local bestRow = UiKit.label({
		parent = card,
		name = "BestSize",
		text = "",
		size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		position = UDim2.fromOffset(0, TITLE_HEIGHT + 8 + ROW_HEIGHT + 4),
		textSize = 18,
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

	local function refreshRows()
		coinsRow.Text =
			`{Icons.coin} {Localizer.t("ui.hub.coins", { coins = ProfileClient.coins() })}`
		local best = ProfileClient.bestSize(Worlds.active.worldId)
		bestRow.Text = `{Icons.star} {Localizer.t(
			"ui.hub.best_size",
			{ size = string.format("%.1f", best or 0) }
		)}`
	end
	ProfileClient.changed.Connect(ProfileClient.changed, refreshRows)
	refreshRows()

	local function refresh()
		card.Visible = RunClient.state() == "Hub"
	end
	RunClient.stateChanged:Connect(refresh)
	refresh()

	local function refreshText()
		refreshRows()
		play.Text = `{Icons.play} {Localizer.t("ui.hub.play")}`
	end
	Localizer.changed.Connect(Localizer.changed, refreshText)
end

return HubUi
