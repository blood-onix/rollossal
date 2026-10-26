--!strict
-- Collection book panel: one page per size tier, a card per object, a reward line per page.
-- Layout and rules: specs/003-saving-and-economy/contracts/ui.md §BookUi. Data comes from ProfileClient only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Book = require(Shared.Rules.Book)
local Config = require(Shared.Config)
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local Worlds = require(Shared.Worlds)
local ProfileClient = require(script.Parent.ProfileClient)
local UiKit = require(script.Parent.UiKit)

local PANEL_WIDTH = 464
local PANEL_HEIGHT = 240
local PANEL_X = 8
local PANEL_Y = 112
local HEADER_HEIGHT = 64
local REWARD_HEIGHT = 28
local GRID_HEIGHT = 148
local CARD_WIDTH = 108
local CARD_HEIGHT = 84
local CARD_GAP = 8
local SCROLL_BAR = 6
local PROGRESS_TEXT_SIZE = 20
local ICON_TEXT_SIZE = 28
local CARD_COLOUR = Color3.fromRGB(58, 63, 74)
local UNKNOWN_COLOUR = Color3.fromRGB(185, 189, 199)

local BookUi = {}

local gui: ScreenGui? = nil
local currentPage = 1
local openCallbacks: { () -> () } = {}
local refresh: () -> () = function() end

local function summaries(): { Book.PageSummary }
	return Book.pages(
		Worlds.sizeTiers :: any,
		Worlds.active.objects :: any,
		ProfileClient.book(),
		ProfileClient.skinsOwned()
	)
end

-- First page that is not complete, else the last one.
local function defaultPage(): number
	local pages = summaries()
	for index, page in pages do
		if not page.isComplete then
			return index
		end
	end
	return math.max(1, #pages)
end

-- Other panels register here so only one of Book and Settings is open at a time.
function BookUi.onOpen(fn: () -> ())
	table.insert(openCallbacks, fn)
end

function BookUi.isOpen(): boolean
	return gui ~= nil and gui.Enabled
end

function BookUi.close()
	if gui then
		gui.Enabled = false
	end
end

function BookUi.toggle()
	local screen = gui
	if screen == nil then
		return
	end
	if screen.Enabled then
		screen.Enabled = false
		return
	end
	for _, fn in openCallbacks do
		fn()
	end
	currentPage = defaultPage()
	refresh()
	screen.Enabled = true
end

local function tierName(page: Book.PageSummary): string
	return Localizer.t(page.nameKey)
end

local function buildCard(parent: Instance, entry: Book.BookEntry, order: number)
	local card = Instance.new("Frame")
	card.Name = entry.bookId
	card.LayoutOrder = order
	card.BackgroundColor3 = CARD_COLOUR
	card.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local glyph = if entry.isDiscovered then Icons[entry.icon] or Icons.cube else Icons.unknown
	local glyphLabel = UiKit.label({
		parent = card,
		name = "Icon",
		text = glyph,
		size = UDim2.new(1, 0, 0, 32),
		position = UDim2.fromOffset(0, 4),
		textSize = ICON_TEXT_SIZE,
	})
	local nameLabel = UiKit.label({
		parent = card,
		name = "Name",
		text = if entry.isDiscovered
			then Localizer.t(entry.nameKey)
			else Localizer.t("ui.book.unknown"),
		size = UDim2.new(1, -8, 0, CARD_HEIGHT - 40),
		position = UDim2.fromOffset(4, 38),
	})
	if not entry.isDiscovered then
		glyphLabel.TextColor3 = UNKNOWN_COLOUR
		nameLabel.TextColor3 = UNKNOWN_COLOUR
	end
	card.Parent = parent
end

function BookUi.start()
	if not Config.Flags.Saving then
		return
	end
	local screen = UiKit.screen("BookUi")
	screen.Enabled = false
	gui = screen
	local panel = UiKit.panel({
		parent = screen,
		name = "Panel",
		size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		position = UDim2.fromOffset(PANEL_X, PANEL_Y),
	})

	local utility = Config.minUtilityTouchTarget
	local prev = UiKit.button({
		parent = panel,
		name = "Prev",
		text = Icons.prev,
		width = utility,
		height = utility,
		position = UDim2.fromOffset(0, 0),
		minSize = utility,
	})
	local nextButton = UiKit.button({
		parent = panel,
		name = "Next",
		text = Icons.next,
		width = utility,
		height = utility,
		position = UDim2.fromOffset(PANEL_WIDTH - 2 * utility, 0),
		minSize = utility,
	})
	local close = UiKit.button({
		parent = panel,
		name = "Close",
		text = Icons.close,
		width = utility,
		height = utility,
		position = UDim2.fromOffset(PANEL_WIDTH - utility, 0),
		minSize = utility,
	})
	local textWidth = PANEL_WIDTH - 3 * utility - 16
	local title = UiKit.label({
		parent = panel,
		name = "Title",
		text = "",
		size = UDim2.fromOffset(textWidth, 26),
		position = UDim2.fromOffset(utility + 8, 4),
		heading = true,
	})
	local progress = UiKit.label({
		parent = panel,
		name = "Progress",
		text = "",
		size = UDim2.fromOffset(textWidth, 30),
		position = UDim2.fromOffset(utility + 8, 30),
		textSize = PROGRESS_TEXT_SIZE,
		heading = true,
	})
	local rewardLine = UiKit.label({
		parent = panel,
		name = "Reward",
		text = "",
		size = UDim2.fromOffset(PANEL_WIDTH - 16, REWARD_HEIGHT),
		position = UDim2.fromOffset(8, HEADER_HEIGHT),
	})

	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.Size = UDim2.fromOffset(PANEL_WIDTH, GRID_HEIGHT)
	grid.Position = UDim2.fromOffset(0, HEADER_HEIGHT + REWARD_HEIGHT)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = SCROLL_BAR
	grid.ScrollingDirection = Enum.ScrollingDirection.Y
	grid.CanvasSize = UDim2.fromOffset(0, 0)
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(CARD_WIDTH, CARD_HEIGHT)
	layout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 2)
	padding.Parent = grid

	local function setEnabled(button: TextButton, enabled: boolean)
		button.Active = enabled
		button.AutoButtonColor = enabled
		button.TextTransparency = if enabled then 0 else 0.5
		button.BackgroundTransparency = if enabled then 0 else 0.6
	end

	refresh = function()
		local pages = summaries()
		local total = #pages
		currentPage = math.clamp(currentPage, 1, math.max(1, total))
		local page = pages[currentPage]
		title.Text = Localizer.t("ui.book.title")
		setEnabled(prev, currentPage > 1)
		setEnabled(nextButton, currentPage < total)
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		if page == nil then
			progress.Text = ""
			rewardLine.Visible = false
			return
		end
		progress.Text = `{Localizer.t(
			"ui.book.page_progress",
			{ collected = page.collectedCount, total = page.totalCount }
		)} {tierName(page)}`
		if page.rewardNameKey ~= nil then
			local glyph = if page.rewardEarned then Icons.check else Icons.lock
			local status = Localizer.t(
				if page.rewardEarned then "ui.book.reward_earned" else "ui.book.reward_locked"
			)
			rewardLine.Text = `{glyph} {Localizer.t(
				"ui.book.reward",
				{ name = Localizer.t(page.rewardNameKey) }
			)} · {status}`
			rewardLine.Visible = true
		else
			rewardLine.Visible = false
		end
		for order, entry in page.entries do
			buildCard(grid, entry, order)
		end
	end

	prev.Activated:Connect(function()
		if currentPage > 1 then
			currentPage -= 1
			refresh()
		end
	end)
	nextButton.Activated:Connect(function()
		if currentPage < #summaries() then
			currentPage += 1
			refresh()
		end
	end)
	close.Activated:Connect(BookUi.close)

	currentPage = defaultPage()
	refresh()
	ProfileClient.changed:Connect(refresh)
	Localizer.changed:Connect(refresh)
end

return BookUi
