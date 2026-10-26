--!strict
-- Top-right button column: Book, Shop, Settings. Shown in Active, Ended and Hub.
-- Layout and rules: specs/003-saving-and-economy/contracts/ui.md §TopBar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local RunClock = require(Shared.Rules.RunClock)
local RunClient = require(script.Parent.RunClient)
local UiKit = require(script.Parent.UiKit)

local DISPLAY_ORDER = 100
local EDGE_MARGIN = 8
local BUTTON_WIDTH = 150
local BUTTON_GAP = 8
local NOTICE_WIDTH = 260
local NOTICE_HEIGHT = 32
local NOTICE_Y = 224
-- Ends left of the 96 px Jump zone (24 px in from the right, 8 px spare), so the notice never covers it.
local NOTICE_RIGHT_MARGIN = 136
local PANEL_COLOUR = Color3.fromRGB(40, 44, 52)

local TopBar = {}

local bindCallbacks: { [string]: () -> () } = {}
local runStartCallbacks: { () -> () } = {}

-- BookUi and SettingsUi register their toggles here, so TopBar never requires them.
function TopBar.bind(name: "book" | "settings", toggle: () -> ())
	bindCallbacks[name] = toggle
end

-- Panels that must close when a new run starts (the Book) register here.
function TopBar.onRunStart(fn: () -> ())
	table.insert(runStartCallbacks, fn)
end

local function bookLocked(): boolean
	return RunClient.state() == "Active"
		and RunClock.uiLocked(
			Workspace:GetServerTimeNow(),
			RunClient.endsAt(),
			Config.runDurationSeconds,
			Config.runStartUiLockSeconds
		)
end

function TopBar.start()
	if not Config.Flags.Saving then
		return
	end
	local screen = UiKit.screen("TopBar", DISPLAY_ORDER)
	local utility = Config.minUtilityTouchTarget

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.new(1, -EDGE_MARGIN, 0, EDGE_MARGIN)
	root.Size = UDim2.fromOffset(BUTTON_WIDTH, 3 * utility + 2 * BUTTON_GAP)
	root.Parent = screen

	local function makeButton(index: number, name: string): TextButton
		return UiKit.button({
			parent = root,
			name = name,
			text = "",
			width = BUTTON_WIDTH,
			height = utility,
			position = UDim2.fromOffset(0, (index - 1) * (utility + BUTTON_GAP)),
			minSize = utility,
			textSize = Config.minTextSize,
		})
	end
	local bookButton = makeButton(1, "Book")
	local shopButton = makeButton(2, "Shop")
	local settingsButton = makeButton(3, "Settings")

	local function refreshText()
		local bookGlyph = if bookLocked() then Icons.lock else Icons.book
		bookButton.Text = `{bookGlyph} {Localizer.t("ui.topbar.book")}`
		shopButton.Text = `{Icons.shop} {Localizer.t("ui.topbar.shop")}`
		settingsButton.Text = `{Icons.gear} {Localizer.t("ui.topbar.settings")}`
	end

	-- The notice is one label under the bar; a newer notice replaces it and a state change hides it.
	local notice = Instance.new("Frame")
	notice.Name = "Notice"
	notice.AnchorPoint = Vector2.new(1, 0)
	notice.Position = UDim2.new(1, -NOTICE_RIGHT_MARGIN, 0, NOTICE_Y)
	notice.Size = UDim2.fromOffset(NOTICE_WIDTH, NOTICE_HEIGHT)
	notice.BackgroundColor3 = PANEL_COLOUR
	notice.Visible = false
	notice.Parent = screen
	local noticeCorner = Instance.new("UICorner")
	noticeCorner.CornerRadius = UDim.new(0, 8)
	noticeCorner.Parent = notice
	local noticeLabel = UiKit.label({
		parent = notice,
		name = "Text",
		text = "",
		size = UDim2.fromScale(1, 1),
		position = UDim2.fromScale(0, 0),
	})
	local noticeToken = 0
	local function hideNotice()
		noticeToken += 1
		notice.Visible = false
	end
	local function showNotice(key: string)
		noticeToken += 1
		local token = noticeToken
		noticeLabel.Text = Localizer.t(key)
		notice.Visible = true
		task.delay(Config.noticeSeconds, function()
			if noticeToken == token then
				notice.Visible = false
			end
		end)
	end

	-- One delayed refresh when the first seconds of a run end; nothing runs per frame.
	local lockToken = 0
	local function scheduleLockRefresh()
		lockToken += 1
		local token = lockToken
		refreshText()
		if not bookLocked() then
			return
		end
		local remaining = RunClock.remaining(Workspace:GetServerTimeNow(), RunClient.endsAt())
		local elapsed = Config.runDurationSeconds - remaining
		-- The delay runs on the local clock and the lock on server time, so the callback can fire a hair
		-- early: it re-runs the whole check instead of assuming the lock has ended.
		task.delay(math.max(0, Config.runStartUiLockSeconds - elapsed), function()
			if lockToken == token then
				scheduleLockRefresh()
			end
		end)
	end

	bookButton.Activated:Connect(function()
		if bookLocked() then
			return
		end
		local toggle = bindCallbacks["book"]
		if toggle then
			toggle()
		end
	end)
	shopButton.Activated:Connect(function()
		-- Flags.Shop is false in this feature: the button only explains when the shop will open.
		showNotice(
			if RunClient.state() == "Active" then "ui.hud.shop_after_run" else "ui.hud.shop_soon"
		)
	end)
	settingsButton.Activated:Connect(function()
		local toggle = bindCallbacks["settings"]
		if toggle then
			toggle()
		end
	end)

	local lastState = RunClient.state()
	local function onState()
		local state = RunClient.state()
		screen.Enabled = state ~= nil
		hideNotice()
		if state == "Active" and lastState ~= "Active" then
			for _, fn in runStartCallbacks do
				fn()
			end
		end
		lastState = state
		scheduleLockRefresh()
	end
	RunClient.stateChanged:Connect(onState)
	Localizer.changed:Connect(refreshText)
	screen.Enabled = lastState ~= nil
	scheduleLockRefresh()
end

return TopBar
