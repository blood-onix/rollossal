--!strict
-- End-of-run screen (contracts/ui.md "Results screen"). Shows what the server sent; sells nothing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local Worlds = require(Shared.Worlds)
local RunClient = require(script.Parent.RunClient)
local UiKit = require(script.Parent.UiKit)

local PANEL_WIDTH = 464
local PANEL_HEIGHT = 320
local COLUMN_WIDTH = 214
local COLUMN_TOP = 52
local COLUMN_MARGIN = 12
-- The TopBar column (150 wide, 8 from the edge) stays on screen over the dim layer, so the panel is centred
-- in the space to its left instead of in the whole screen.
local TOPBAR_CLEARANCE = 166
local BUTTON_WIDTH = 214
local BUTTON_HEIGHT = 96
local BUTTON_GAP = 12
local DIM_TRANSPARENCY = 0.35
local TITLE_SIZE = 36
local STAR_SIZE = 36
local BODY_SIZE = 20
local MAX_ENTRY_LINES = 4
local FIRST_RUN_ENTRY_LINES = 3
local ENTRY_LINE_HEIGHT = 24
local BEST_ROW_HEIGHT = 28
local TIP_HEIGHT = 54
local TIP_TEXT_SIZE = 18

local ResultsUi = {}

local function sizeText(value: number): string
	return string.format("%.1f", value)
end

function ResultsUi.start()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local gui = UiKit.screen("Results")

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = DIM_TRANSPARENCY
	dim.Size = UDim2.fromScale(1, 1)
	dim.Visible = false
	dim.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, -TOPBAR_CLEARANCE / 2, 0.5, 0)
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
	panel.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
	panel.Parent = dim
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel

	local title = UiKit.label({
		parent = panel,
		name = "Title",
		text = Localizer.t("ui.results.title"),
		size = UDim2.new(1, 0, 0, 48),
		position = UDim2.fromOffset(0, 4),
		textSize = TITLE_SIZE,
		heading = true,
	})

	local function column(name: string, x: number): Frame
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.BackgroundTransparency = 1
		frame.Position = UDim2.fromOffset(x, COLUMN_TOP)
		frame.Size = UDim2.fromOffset(COLUMN_WIDTH, 100)
		frame.Parent = panel
		return frame
	end
	local left = column("Left", COLUMN_MARGIN)
	local right = column("Right", PANEL_WIDTH - COLUMN_WIDTH - COLUMN_MARGIN)

	local function line(parent: Instance, name: string, row: number, height: number): TextLabel
		return UiKit.label({
			parent = parent,
			name = name,
			text = "",
			size = UDim2.new(1, 0, 0, height),
			position = UDim2.fromOffset(0, row),
			textSize = BODY_SIZE,
			xAlign = Enum.TextXAlignment.Left,
		})
	end

	local finalSize = line(left, "FinalSize", 0, 28)
	local starGlyphs = line(left, "StarGlyphs", 30, STAR_SIZE)
	starGlyphs.TextSize = STAR_SIZE
	local starCount = line(left, "StarCount", 68, 28)
	-- Two lines: the Spanish "Monedas: 600 (total 600)" is wider than the column.
	local coins = line(left, "Coins", 98, 48)

	local newEntries = line(right, "NewEntries", 0, 28)
	local entryLines: { TextLabel } = {}
	for index = 1, MAX_ENTRY_LINES do
		entryLines[index] =
			line(right, `Entry{index}`, 28 + (index - 1) * ENTRY_LINE_HEIGHT, ENTRY_LINE_HEIGHT)
	end
	local bestRowY = 28 + MAX_ENTRY_LINES * ENTRY_LINE_HEIGHT + 4
	local bestRow = line(right, "BestRow", bestRowY, BEST_ROW_HEIGHT)

	local roll = UiKit.button({
		parent = panel,
		name = "RollAgain",
		text = `{Icons.retry} {Localizer.t("ui.results.roll_again")}`,
		width = BUTTON_WIDTH,
		height = BUTTON_HEIGHT,
		position = UDim2.new(0.5, -BUTTON_GAP / 2, 1, -12),
		anchor = Vector2.new(1, 1),
	})
	local hub = UiKit.button({
		parent = panel,
		name = "BackToHub",
		text = `{Icons.home} {Localizer.t("ui.results.back_to_hub")}`,
		width = BUTTON_WIDTH,
		height = BUTTON_HEIGHT,
		position = UDim2.new(0.5, BUTTON_GAP / 2, 1, -12),
		anchor = Vector2.new(0, 1),
	})
	roll.Activated:Connect(function()
		(Remotes:WaitForChild("RollAgain") :: RemoteEvent):FireServer()
	end)
	hub.Activated:Connect(function()
		(Remotes:WaitForChild("BackToHub") :: RemoteEvent):FireServer()
	end)

	-- Everything below is built from the RunResult alone, so a language switch can rebuild it.
	local lastResult: RunClient.RunResult? = nil
	local function render(result: RunClient.RunResult)
		lastResult = result
		finalSize.Text =
			Localizer.t("ui.results.final_size", { size = sizeText(result.finalDiameter) })
		local glyphs = {}
		for index = 1, 3 do
			table.insert(glyphs, if index <= result.stars then Icons.star else Icons.star_empty)
		end
		starGlyphs.Text = table.concat(glyphs, "")
		starCount.Text = Localizer.t("ui.results.stars", { stars = result.stars })
		if result.coinsTotal ~= nil then
			coins.Text = `{Icons.coin} {Localizer.t(
				"ui.results.coins_total",
				{ coins = result.coins, total = result.coinsTotal }
			)}`
		else
			coins.Text = `{Icons.coin} {Localizer.t("ui.results.coins", { coins = result.coins })}`
		end

		if #result.newBookIds > 0 then
			newEntries.Text = `{Icons.book} {Localizer.t(
				"ui.results.new_entries",
				{ count = #result.newBookIds }
			)}`
		else
			newEntries.Text = `{Icons.book} {Localizer.t("ui.results.no_new_entries")}`
		end
		for index, entryLine in entryLines do
			local object = Worlds.objectByBookId[result.newBookIds[index] or ""]
			entryLine.Text = if object
				then `{Icons[object.icon]} {Localizer.t(object.nameKey)}`
				else ""
		end
		-- The first-run tip takes the best-size row and one entry line: two 18 px lines need 40 px.
		bestRow.Position = UDim2.fromOffset(0, bestRowY)
		bestRow.Size = UDim2.new(1, 0, 0, BEST_ROW_HEIGHT)
		bestRow.TextSize = BODY_SIZE
		if result.isFirstRun then
			-- The last visible line becomes "+N more" so every first-time entry is accounted for (FR-014).
			local hidden = #result.newBookIds - FIRST_RUN_ENTRY_LINES
			for index, entryLine in entryLines do
				if index > FIRST_RUN_ENTRY_LINES then
					entryLine.Text = ""
				elseif index == FIRST_RUN_ENTRY_LINES and hidden > 0 then
					entryLine.Text = Localizer.t("ui.results.more_entries", { count = hidden + 1 })
				end
			end
			bestRow.Position =
				UDim2.fromOffset(0, 28 + FIRST_RUN_ENTRY_LINES * ENTRY_LINE_HEIGHT + 4)
			bestRow.Size = UDim2.new(1, 0, 0, TIP_HEIGHT)
			bestRow.TextSize = TIP_TEXT_SIZE
			bestRow.Text = Localizer.t("ui.results.first_run_tip")
		elseif result.bestFriendSize ~= nil then
			bestRow.Text =
				Localizer.t("ui.results.friend_best", { size = sizeText(result.bestFriendSize) })
		else
			bestRow.Text =
				Localizer.t("ui.results.self_best", { size = sizeText(result.bestSelfSize) })
		end
		dim.Visible = RunClient.state() == "Ended"
	end
	RunClient.result:Connect(render)

	local function refreshText()
		title.Text = Localizer.t("ui.results.title")
		roll.Text = `{Icons.retry} {Localizer.t("ui.results.roll_again")}`
		hub.Text = `{Icons.home} {Localizer.t("ui.results.back_to_hub")}`
		local result = lastResult
		if result ~= nil then
			render(result)
		end
	end
	Localizer.changed:Connect(refreshText)
	-- Hidden by the state change, not by a click, so a rejected request leaves the screen up.
	RunClient.stateChanged:Connect(function(state)
		if state ~= "Ended" then
			dim.Visible = false
		end
	end)
end

return ResultsUi
