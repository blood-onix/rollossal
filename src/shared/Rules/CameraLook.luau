--!strict
-- Camera look sensitivity. Pure: angles in radians, no Roblox APIs.
-- The default camera script owns the look direction and has no sensitivity setting for touch or gamepad.
-- Each frame the client reads the direction it produced, and `advance` returns the extra yaw and pitch
-- to add on top, so the net turn per frame is `factor` times what the player dragged.

local CameraLook = {}

local TAU = 2 * math.pi

-- Smallest signed difference between two yaw angles, in [-pi, pi].
function CameraLook.wrap(delta: number): number
	return (delta + math.pi) % TAU - math.pi
end

-- prevYaw/prevPitch are the default script's direction last frame (nil on the first frame).
-- extraYaw/extraPitch are the offsets accumulated so far. yaw/pitch are the default script's direction
-- now. The returned pitch offset keeps yaw/pitch + offset inside +/- maxPitch.
function CameraLook.advance(
	prevYaw: number?,
	prevPitch: number?,
	extraYaw: number,
	extraPitch: number,
	yaw: number,
	pitch: number,
	factor: number,
	maxPitch: number
): (number, number)
	if prevYaw ~= nil and prevPitch ~= nil then
		extraYaw += CameraLook.wrap(yaw - prevYaw) * (factor - 1)
		extraPitch += (pitch - prevPitch) * (factor - 1)
	end
	extraYaw = CameraLook.wrap(extraYaw)
	extraPitch = math.clamp(extraPitch, -maxPitch - pitch, maxPitch - pitch)
	return extraYaw, extraPitch
end

return CameraLook
