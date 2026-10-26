--!strict
-- Settings panel: music and effects volume, camera sensitivity, reduce motion, language.
-- Layout and rules: specs/003-saving-and-economy/contracts/ui.md §SettingsUi. A change applies on this
-- client at once, goes to the server through ProfileClient (debounced), and the server echo wins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Icons = require(Shared.Content.Icons)
local Localizer = require(Shared.Localization.Localizer)
local ProfileClient = require(script.Parent.ProfileClient)
local UiKit = require(script.Parent.UiKit)

local PANEL_WIDTH = 464
local PANEL_HEIGHT = 240
local PANEL_X = 8
local PANEL_Y = 112
local HEADER_HEIGHT = 64
local COLUMN_WIDTH = 224
local COLUMN_GAP = 8
local LEFT_X = 4
local RIGHT_X = LEFT_X + COLUMN_WIDTH + COLUMN_GAP
local ROW_PITCH = 56
local LABEL_HEIGHT = 20
local SLIDER_OFFSET = 12
local VALUE_WIDTH = 52
local TOGGLE_OFFSET = LABEL_HEIGHT + 2
local LANGUAGE_LABEL_Y = HEADER_HEIGHT + TOGGLE_OFFSET + 64 + 4
local LANGUAGE_BUTTON_Y = LANGUAGE_LABEL_Y + LABEL_HEIGHT + 2
local LANGUAGE_BUTTON_WIDTH = 72
local LANGUAGE_BUTTON_GAP = 4
local SELECTED_COLOUR = Color3.fromRGB(60, 140, 90)
local UNSELECTED_COLOUR = Color3.fromRGB(90, 94, 102)
local PERCENT = 100

local LANGUAGES: { { code: string, key: string } } = {
	{ code = "auto", key = "ui.settings.language_auto" },
	{ code = "en-us", key = "ui.settings.language_en_us" },
	{ code = "es-es", key = "ui.settings.language_es_es" },
}

local SettingsUi = {}

local gui: ScreenGui? = nil
local openCallbacks: { () -> () } = {}

-- Other panels register here so only one of Book and Settings is open at a time.
function SettingsUi.onOpen(fn: () -> ())
	table.insert(openCallbacks, fn)
end

function SettingsUi.isOpen(): boolean
	return gui ~= nil and gui.Enabled
end

function SettingsUi.close()
	local screen = gui
	if screen and screen.Enabled then
		screen.Enabled = false
		ProfileClient.flush()
	end
end

function SettingsUi.toggle()
	local screen = gui
	if screen == nil then
		return
	end
	if screen.Enabled then
		SettingsUi.close()
		return
	end
	for _, fn in openCallbacks do
		fn()
	end
	screen.Enabled = true
end

function SettingsUi.start()
	if not Config.Flags.Saving then
		return
	end
	local screen = UiKit.screen("SettingsUi")
	screen.Enabled = false
	gui = screen
	local panel = UiKit.panel({
		parent = screen,
		name = "Panel",
		size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT),
		position = UDim2.fromOffset(PANEL_X, PANEL_Y),
	})

	local utility = Config.minUtilityTouchTarget
	local title = UiKit.label({
		parent = panel,
		name = "Title",
		text = "",
		size = UDim2.fromOffset(PANEL_WIDTH - utility - 16, HEADER_HEIGHT),
		position = UDim2.fromOffset(8, 0),
		heading = true,
		xAlign = Enum.TextXAlignment.Left,
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
	close.Activated:Connect(SettingsUi.close)

	-- The values the controls show and the next send carries: always all five fields.
	local current = ProfileClient.settings()

	local function send()
		ProfileClient.preview(current)
		ProfileClient.sendSettings({
			musicVolume = current.musicVolume,
			effectsVolume = current.effectsVolume,
			cameraSensitivity = current.cameraSensitivity,
			reduceMotion = current.reduceMotion,
			language = current.language,
		})
	end

	-- One left-column row: a name and a percent value over a slider.
	local function sliderRow(
		index: number,
		field: string,
		nameKey: string,
		bounds: { min: number, max: number }
	)
		local rowY = HEADER_HEIGHT + (index - 1) * ROW_PITCH
		local name = UiKit.label({
			parent = panel,
			name = field .. "Label",
			text = "",
			size = UDim2.fromOffset(COLUMN_WIDTH - VALUE_WIDTH, LABEL_HEIGHT),
			position = UDim2.fromOffset(LEFT_X, rowY),
			xAlign = Enum.TextXAlignment.Left,
		})
		local value = UiKit.label({
			parent = panel,
			name = field .. "Value",
			text = "",
			size = UDim2.fromOffset(VALUE_WIDTH, LABEL_HEIGHT),
			position = UDim2.fromOffset(LEFT_X + COLUMN_WIDTH - VALUE_WIDTH, rowY),
			xAlign = Enum.TextXAlignment.Right,
		})
		local span = bounds.max - bounds.min
		local function fractionOf(setting: number): number
			return math.clamp((setting - bounds.min) / span, 0, 1)
		end
		local function renderValue()
			value.Text = Localizer.t(
				"ui.settings.percent",
				{ value = math.floor(current[field] * PERCENT + 0.5) }
			)
		end
		local slider = UiKit.slider({
			parent = panel,
			name = field,
			position = UDim2.fromOffset(LEFT_X, rowY + SLIDER_OFFSET),
			value = fractionOf(current[field]),
			onChanged = function(fraction: number)
				current[field] = bounds.min + fraction * span
				renderValue()
				send()
			end,
		})
		return {
			refreshText = function()
				name.Text = Localizer.t(nameKey)
				renderValue()
			end,
			-- The server echo: move the control unless the player is holding it.
			sync = function()
				if not slider.isDragging() then
					slider.set(fractionOf(current[field]))
				end
				renderValue()
			end,
		}
	end

	local rows = {
		sliderRow(1, "musicVolume", "ui.settings.music_volume", Config.Settings.musicVolume),
		sliderRow(2, "effectsVolume", "ui.settings.effects_volume", Config.Settings.effectsVolume),
		sliderRow(
			3,
			"cameraSensitivity",
			"ui.settings.camera_sensitivity",
			Config.Settings.cameraSensitivity
		),
	}

	local reduceLabel = UiKit.label({
		parent = panel,
		name = "ReduceMotionLabel",
		text = "",
		size = UDim2.fromOffset(COLUMN_WIDTH, LABEL_HEIGHT),
		position = UDim2.fromOffset(RIGHT_X, HEADER_HEIGHT),
		xAlign = Enum.TextXAlignment.Left,
	})
	local reduceToggle = UiKit.toggle({
		parent = panel,
		name = "ReduceMotion",
		position = UDim2.fromOffset(RIGHT_X, HEADER_HEIGHT + TOGGLE_OFFSET),
		on = current.reduceMotion,
		onText = Localizer.t("ui.settings.on"),
		offText = Localizer.t("ui.settings.off"),
		onChanged = function(on: boolean)
			current.reduceMotion = on
			send()
		end,
	})

	local languageLabel = UiKit.label({
		parent = panel,
		name = "LanguageLabel",
		text = "",
		size = UDim2.fromOffset(COLUMN_WIDTH, LABEL_HEIGHT),
		position = UDim2.fromOffset(RIGHT_X, LANGUAGE_LABEL_Y),
		xAlign = Enum.TextXAlignment.Left,
	})
	local languageButtons: { [string]: TextButton } = {}
	local function renderLanguages()
		for _, option in LANGUAGES do
			local button = languageButtons[option.code]
			local selected = current.language == option.code
			local text = Localizer.t(option.key)
			button.Text = if selected then `{Icons.check}\n{text}` else text
			button.Font = if selected then Enum.Font.GothamBold else Enum.Font.GothamMedium
			button.BackgroundColor3 = if selected then SELECTED_COLOUR else UNSELECTED_COLOUR
		end
	end
	for index, option in LANGUAGES do
		local button = UiKit.button({
			parent = panel,
			name = "Language_" .. option.code,
			text = "",
			width = LANGUAGE_BUTTON_WIDTH,
			height = utility,
			textSize = Config.minTextSize,
			position = UDim2.fromOffset(
				RIGHT_X + (index - 1) * (LANGUAGE_BUTTON_WIDTH + LANGUAGE_BUTTON_GAP),
				LANGUAGE_BUTTON_Y
			),
			minSize = utility,
		})
		languageButtons[option.code] = button
		button.Activated:Connect(function()
			if current.language == option.code then
				return
			end
			current.language = option.code
			renderLanguages()
			send()
		end)
	end

	local function refreshText()
		title.Text = Localizer.t("ui.settings.title")
		reduceLabel.Text = Localizer.t("ui.settings.reduce_motion")
		languageLabel.Text = Localizer.t("ui.settings.language")
		reduceToggle.setLabels(Localizer.t("ui.settings.on"), Localizer.t("ui.settings.off"))
		for _, row in rows do
			row.refreshText()
		end
		renderLanguages()
	end

	-- The authoritative values replace whatever the controls show, so a clamped value moves its control.
	local function onSnapshot()
		current = ProfileClient.settings()
		reduceToggle.set(current.reduceMotion)
		for _, row in rows do
			row.sync()
		end
		renderLanguages()
	end

	refreshText()
	ProfileClient.changed:Connect(onSnapshot)
	Localizer.changed:Connect(refreshText)
end

return SettingsUi
