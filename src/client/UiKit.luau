--!strict
-- Shared building blocks for the run UI: a scaled ScreenGui, outlined labels and big buttons.
-- Rules: specs/002-run-loop/contracts/ui.md. Text is passed in already localised.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Icons = require(Shared.Content.Icons)

export type LabelProps = {
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2,
	anchor: Vector2?,
	textSize: number?,
	heading: boolean?,
	xAlign: Enum.TextXAlignment?,
	name: string?,
}

export type ButtonProps = {
	parent: Instance,
	text: string,
	width: number,
	height: number,
	position: UDim2,
	anchor: Vector2?,
	name: string?,
	-- Smallest width and height. Defaults to Config.minTouchTarget (96); utility controls pass
	-- Config.minUtilityTouchTarget (64).
	minSize: number?,
	textSize: number?,
}

export type PanelProps = {
	parent: Instance,
	size: UDim2,
	position: UDim2,
	anchor: Vector2?,
	name: string?,
}

export type SliderProps = {
	parent: Instance,
	position: UDim2,
	anchor: Vector2?,
	name: string?,
	value: number,
	-- Called with the raw 0 to 1 fraction while the player drags.
	onChanged: (fraction: number) -> (),
}

export type Slider = {
	frame: Frame,
	-- Moves the handle without calling onChanged (used for the authoritative echo).
	set: (fraction: number) -> (),
	isDragging: () -> boolean,
}

export type ToggleProps = {
	parent: Instance,
	position: UDim2,
	anchor: Vector2?,
	name: string?,
	on: boolean,
	onText: string,
	offText: string,
	onChanged: (on: boolean) -> (),
}

export type Toggle = {
	button: TextButton,
	-- Sets the state without calling onChanged.
	set: (on: boolean) -> (),
	setLabels: (onText: string, offText: string) -> (),
}

local UiKit = {}

local STROKE_COLOUR = Color3.fromRGB(20, 20, 20)
local STROKE_THICKNESS = 2
local TEXT_COLOUR = Color3.new(1, 1, 1)
local BUTTON_COLOUR = Color3.fromRGB(60, 140, 90)
local PANEL_COLOUR = Color3.fromRGB(40, 44, 52)
local PANEL_CORNER = 16
local BUTTON_TEXT_SIZE = 28
local OFF_COLOUR = Color3.fromRGB(90, 94, 102)
local TRACK_COLOUR = Color3.fromRGB(20, 22, 26)
local HANDLE_COLOUR = Color3.fromRGB(235, 235, 235)
-- Slider geometry (contracts/ui.md §SettingsUi): the whole row is the drag area.
local SLIDER_ROW_WIDTH = 224
local SLIDER_ROW_HEIGHT = 56
local SLIDER_TRACK_WIDTH = 208
local SLIDER_TRACK_HEIGHT = 24
local SLIDER_HANDLE_SIZE = 40
local TOGGLE_WIDTH = 224
local TOGGLE_HEIGHT = 64

-- object is a TextLabel or a TextButton; the two share no type that holds the text properties.
local function style(object: any, textSize: number?, heading: boolean?)
	object.BackgroundTransparency = 1
	object.Font = if heading then Enum.Font.FredokaOne else Enum.Font.GothamMedium
	object.TextSize = math.max(Config.minTextSize, textSize or Config.minTextSize)
	object.TextColor3 = TEXT_COLOUR
	object.TextWrapped = true
	local stroke = Instance.new("UIStroke")
	stroke.Color = STROKE_COLOUR
	stroke.Thickness = STROKE_THICKNESS
	stroke.Parent = object
end

-- A ScreenGui whose UIScale never drops below 1, so base sizes are minimums on every screen.
-- displayOrder lifts a screen above others (the TopBar sits above the Results dim layer).
function UiKit.screen(name: string, displayOrder: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = displayOrder or 0

	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local camera = Workspace.CurrentCamera :: Camera
	local function update()
		local viewport = camera.ViewportSize
		scale.Scale = math.max(1, math.min(viewport.X, viewport.Y) / Config.uiReferenceShortSide)
	end
	update()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function UiKit.label(props: LabelProps): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.name or "Label"
	label.Text = props.text
	label.Size = props.size
	label.Position = props.position
	label.AnchorPoint = props.anchor or Vector2.zero
	label.TextXAlignment = props.xAlign or Enum.TextXAlignment.Center
	style(label, props.textSize, props.heading)
	label.Parent = props.parent
	return label
end

function UiKit.button(props: ButtonProps): TextButton
	local button = Instance.new("TextButton")
	button.Name = props.name or "Button"
	button.Text = props.text
	local minSize = props.minSize or Config.minTouchTarget
	button.Size = UDim2.fromOffset(math.max(props.width, minSize), math.max(props.height, minSize))
	button.Position = props.position
	button.AnchorPoint = props.anchor or Vector2.zero
	button.AutoButtonColor = true
	style(button, props.textSize or BUTTON_TEXT_SIZE, true)
	button.BackgroundTransparency = 0
	button.BackgroundColor3 = BUTTON_COLOUR
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	button.Parent = props.parent
	return button
end

-- A dark rounded frame for the Book and Settings panels. It swallows taps so they do not reach the world.
function UiKit.panel(props: PanelProps): Frame
	local panel = Instance.new("Frame")
	panel.Name = props.name or "Panel"
	panel.Size = props.size
	panel.Position = props.position
	panel.AnchorPoint = props.anchor or Vector2.zero
	panel.BackgroundColor3 = PANEL_COLOUR
	panel.BorderSizePixel = 0
	panel.Active = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, PANEL_CORNER)
	corner.Parent = panel
	panel.Parent = props.parent
	return panel
end

-- A horizontal slider reporting a raw 0 to 1 fraction. The whole 224×56 row takes the drag, not just the handle.
function UiKit.slider(props: SliderProps): Slider
	local row = Instance.new("Frame")
	row.Name = props.name or "Slider"
	row.Size = UDim2.fromOffset(SLIDER_ROW_WIDTH, SLIDER_ROW_HEIGHT)
	row.Position = props.position
	row.AnchorPoint = props.anchor or Vector2.zero
	row.BackgroundTransparency = 1
	row.Active = true
	row.Parent = props.parent

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.fromOffset(SLIDER_TRACK_WIDTH, SLIDER_TRACK_HEIGHT)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.BackgroundColor3 = TRACK_COLOUR
	track.BorderSizePixel = 0
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0.5, 0)
	trackCorner.Parent = track
	track.Parent = row

	local handle = Instance.new("Frame")
	handle.Name = "Handle"
	handle.Size = UDim2.fromOffset(SLIDER_HANDLE_SIZE, SLIDER_HANDLE_SIZE)
	handle.AnchorPoint = Vector2.new(0, 0.5)
	handle.BackgroundColor3 = HANDLE_COLOUR
	handle.BorderSizePixel = 0
	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(0.5, 0)
	handleCorner.Parent = handle
	handle.Parent = track

	local travel = SLIDER_TRACK_WIDTH - SLIDER_HANDLE_SIZE
	local function place(fraction: number)
		handle.Position = UDim2.new(0, math.floor(fraction * travel + 0.5), 0.5, 0)
	end
	place(math.clamp(props.value, 0, 1))

	local dragging: InputObject? = nil
	-- AbsoluteSize includes the UIScale, so the fraction is measured in screen pixels on both sides.
	local function fractionAt(x: number): number
		local handleWidth = handle.AbsoluteSize.X
		local span = track.AbsoluteSize.X - handleWidth
		if span <= 0 then
			return 0
		end
		return math.clamp((x - track.AbsolutePosition.X - handleWidth / 2) / span, 0, 1)
	end
	local function drag(input: InputObject)
		local fraction = fractionAt(input.Position.X)
		place(fraction)
		props.onChanged(fraction)
	end

	row.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = input
			drag(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		local active = dragging
		if active == nil then
			return
		end
		local moved = input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		if
			moved and (input == active or active.UserInputType == Enum.UserInputType.MouseButton1)
		then
			drag(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			dragging ~= nil and (input == dragging or input.UserInputType == dragging.UserInputType)
		then
			dragging = nil
		end
	end)

	return {
		frame = row,
		set = function(fraction: number)
			place(math.clamp(fraction, 0, 1))
		end,
		isDragging = function()
			return dragging ~= nil
		end,
	}
end

-- A 224×64 on/off button showing a check or close glyph plus the On or Off text (status is never colour alone).
function UiKit.toggle(props: ToggleProps): Toggle
	local onText, offText = props.onText, props.offText
	local isOn = props.on
	local button = Instance.new("TextButton")
	button.Name = props.name or "Toggle"
	button.Size = UDim2.fromOffset(TOGGLE_WIDTH, TOGGLE_HEIGHT)
	button.Position = props.position
	button.AnchorPoint = props.anchor or Vector2.zero
	button.AutoButtonColor = true
	style(button, BUTTON_TEXT_SIZE, true)
	button.BackgroundTransparency = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	button.Parent = props.parent

	local function render()
		button.Text = if isOn then `{Icons.check} {onText}` else `{Icons.close} {offText}`
		button.BackgroundColor3 = if isOn then BUTTON_COLOUR else OFF_COLOUR
	end
	render()
	button.Activated:Connect(function()
		isOn = not isOn
		render()
		props.onChanged(isOn)
	end)

	return {
		button = button,
		set = function(on: boolean)
			isOn = on
			render()
		end,
		setLabels = function(newOnText: string, newOffText: string)
			onText, offText = newOnText, newOffText
			render()
		end,
	}
end

return UiKit
