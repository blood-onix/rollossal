--!strict
-- Touch-only jump button. Meaning is carried by the up-arrow shape and its bottom-right position.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local JumpButton = {}

function JumpButton.create(): BindableEvent?
	if not UserInputService.TouchEnabled then
		return nil
	end

	local tapped = Instance.new("BindableEvent")

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

	button.Activated:Connect(function()
		tapped:Fire()
	end)

	button.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return tapped
end

return JumpButton
