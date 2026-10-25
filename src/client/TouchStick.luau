--!strict
-- Touch-only dynamic thumbstick. The default ControlModule builds its touch controls only for a player
-- with a Humanoid, and the ball has no character, so phones need their own stick. A touch that starts
-- in the left half of the screen places the stick under the finger; dragging gives the move vector.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local RADIUS = 60
local KNOB_SIZE = 48
local DEAD_ZONE = 0.15

local TouchStick = {}

local function circle(name: string, size: number, transparency: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	frame.BackgroundTransparency = transparency
	frame.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	return frame
end

-- Returns a reader for the move vector in the legacy GetMoveVector convention (forward is -Z), or nil
-- on devices without touch.
function TouchStick.create(): (() -> Vector3)?
	if not UserInputService.TouchEnabled then
		return nil
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "TouchStickGui"
	gui.ResetOnSpawn = false

	-- Active, so touches that start here count as processed and the camera does not also pan.
	local zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.Size = UDim2.fromScale(0.5, 1)
	zone.BackgroundTransparency = 1
	zone.Active = true
	zone.Parent = gui

	local ring = circle("Ring", RADIUS * 2, 0.6)
	ring.Parent = gui
	local knob = circle("Knob", KNOB_SIZE, 0.2)
	knob.Parent = gui

	local activeInput: InputObject? = nil
	local origin = Vector2.zero
	local move = Vector3.zero

	local function place(frame: Frame, position: Vector2)
		frame.Position = UDim2.fromOffset(position.X, position.Y)
	end

	local function release()
		activeInput = nil
		move = Vector3.zero
		ring.Visible = false
		knob.Visible = false
	end

	-- The newest touch in the zone takes over, so a touch whose end was lost cannot hold the stick.
	zone.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		move = Vector3.zero
		activeInput = input
		origin = Vector2.new(input.Position.X, input.Position.Y)
		place(ring, origin)
		place(knob, origin)
		ring.Visible = true
		knob.Visible = true
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input ~= activeInput then
			return
		end
		local offset = Vector2.new(input.Position.X, input.Position.Y) - origin
		if offset.Magnitude > RADIUS then
			offset = offset.Unit * RADIUS
		end
		place(knob, origin + offset)
		local scaled = offset / RADIUS
		move = if scaled.Magnitude < DEAD_ZONE
			then Vector3.zero
			else Vector3.new(scaled.X, 0, scaled.Y)
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == activeInput then
			release()
		end
	end)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return function(): Vector3
		return move
	end
end

return TouchStick
