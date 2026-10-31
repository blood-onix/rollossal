--!strict
-- Touch-only jump button. Meaning is carried by the up-arrow shape and its bottom-right position.
-- Emits Pressed when a finger lands on it and Released when that same finger lifts, wherever it is by then,
-- so a hold keeps the jump stretched and a drag off the button still ends it.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local JumpButton = {}

export type Events = { Pressed: BindableEvent, Released: BindableEvent }

function JumpButton.create(): Events?
	if not UserInputService.TouchEnabled then
		return nil
	end

	local pressed = Instance.new("BindableEvent")
	local released = Instance.new("BindableEvent")

	local gui = Instance.new("ScreenGui")
	gui.Name = "JumpButtonGui"
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.Name = "Jump"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -24)
	button.Size = UDim2.fromOffset(96, 96)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.BackgroundTransparency = 0.2
	button.Text = "▲"
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button

	local activeInput: InputObject? = nil
	button.InputBegan:Connect(function(input: InputObject)
		if
			activeInput == nil
			and (
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			activeInput = input
			pressed:Fire()
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == activeInput then
			activeInput = nil
			released:Fire()
		end
	end)

	button.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return { Pressed = pressed, Released = released }
end

return JumpButton
