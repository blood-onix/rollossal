--!strict
-- Shared building blocks for the run UI: a scaled ScreenGui, outlined labels and big buttons.
-- Rules: specs/002-run-loop/contracts/ui.md. Text is passed in already localised.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

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
}

local UiKit = {}

local STROKE_COLOUR = Color3.fromRGB(20, 20, 20)
local STROKE_THICKNESS = 2
local TEXT_COLOUR = Color3.new(1, 1, 1)
local BUTTON_COLOUR = Color3.fromRGB(60, 140, 90)

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
function UiKit.screen(name: string): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

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
	button.Size = UDim2.fromOffset(
		math.max(props.width, Config.minTouchTarget),
		math.max(props.height, Config.minTouchTarget)
	)
	button.Position = props.position
	button.AnchorPoint = props.anchor or Vector2.zero
	button.AutoButtonColor = true
	style(button, 28, true)
	button.BackgroundTransparency = 0
	button.BackgroundColor3 = BUTTON_COLOUR
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	button.Parent = props.parent
	return button
end

return UiKit
