--!strict
-- Camera look sensitivity. Pure: angles in radians, no Roblox APIs.
-- The default camera script has no sensitivity setting for touch or gamepad, and it starts every frame from
-- the camera's current transform, so whatever the client wrote last frame is the base it turns from. Each
-- frame the client compares the direction the default script produced with the direction it left the camera
-- in, the difference being only what the player dragged, and `advance` returns the extra yaw and pitch to
-- add this frame so the net turn is `factor` times the drag. The extra is not accumulated: it is already in
-- the transform the default script continues from.

local CameraLook = {}

local TAU = 2 * math.pi

-- Smallest signed difference between two yaw angles, in [-pi, pi].
function CameraLook.wrap(delta: number): number
	return (delta + math.pi) % TAU - math.pi
end

-- prevYaw/prevPitch are the direction the client left the camera in last frame (nil on the first frame).
-- yaw/pitch are the direction the default script produced now. Returns the yaw and pitch to add to the
-- camera this frame; the pitch increment keeps pitch + increment inside +/- maxPitch.
function CameraLook.advance(
	prevYaw: number?,
	prevPitch: number?,
	yaw: number,
	pitch: number,
	factor: number,
	maxPitch: number
): (number, number)
	if prevYaw == nil or prevPitch == nil or factor == 1 then
		return 0, 0
	end
	local extraYaw = CameraLook.wrap(yaw - prevYaw) * (factor - 1)
	local extraPitch = (pitch - prevPitch) * (factor - 1)
	return extraYaw, math.clamp(extraPitch, -maxPitch - pitch, maxPitch - pitch)
end

return CameraLook
