--!strict
-- Hand-computed expectations for the per-frame camera look scaling.

local harness = require("./harness")
local CameraLook = require("../../src/shared/Rules/CameraLook")

local test, expect = harness.test, harness.expect

local MAX_PITCH = math.rad(80)

test("wrap: stays inside [-pi, pi]", function()
	expect.near(CameraLook.wrap(0.5), 0.5, 1e-9)
	expect.near(CameraLook.wrap(math.pi + 0.5), -math.pi + 0.5, 1e-9)
	expect.near(CameraLook.wrap(-math.pi - 0.5), math.pi - 0.5, 1e-9)
end)

test("advance: first frame adds nothing", function()
	local ey, ep = CameraLook.advance(nil, nil, 1, 0.2, 2, MAX_PITCH)
	expect.equal(ey, 0)
	expect.equal(ep, 0)
end)

test("advance: factor 1 adds nothing", function()
	local ey, ep = CameraLook.advance(0, 0, 0.3, 0.1, 1, MAX_PITCH)
	expect.equal(ey, 0)
	expect.equal(ep, 0)
end)

test("advance: factor 2 doubles a drag (extra equals the drag)", function()
	local ey, ep = CameraLook.advance(0, 0, 0.3, 0.1, 2, MAX_PITCH)
	expect.near(ey, 0.3, 1e-9)
	expect.near(ep, 0.1, 1e-9)
end)

test("advance: factor 0.5 halves a drag (extra is minus half the drag)", function()
	local ey, ep = CameraLook.advance(0, 0, 0.4, -0.2, 0.5, MAX_PITCH)
	expect.near(ey, -0.2, 1e-9)
	expect.near(ep, 0.1, 1e-9)
end)

test("advance: no drag adds nothing, whatever the factor", function()
	local ey, ep = CameraLook.advance(0.5, 0.2, 0.5, 0.2, 2, MAX_PITCH)
	expect.equal(ey, 0)
	expect.equal(ep, 0)
end)

test("advance: yaw delta across the +/-pi seam is the short way round", function()
	local ey = CameraLook.advance(math.pi - 0.1, 0, -math.pi + 0.1, 0, 2, MAX_PITCH)
	expect.near(ey, 0.2, 1e-9)
end)

test("advance: pitch never goes past maxPitch", function()
	local _, ep = CameraLook.advance(0, 0, 0, 1, 3, MAX_PITCH)
	expect.near(ep, MAX_PITCH - 1, 1e-9)
	local _, low = CameraLook.advance(0, 0, 0, -1, 3, MAX_PITCH)
	expect.near(low, -MAX_PITCH + 1, 1e-9)
end)

test("advance: a pitch already past maxPitch is pulled back to it", function()
	local _, ep = CameraLook.advance(0, 1.45, 0, 1.45, 2, MAX_PITCH)
	expect.near(ep, MAX_PITCH - 1.45, 1e-9)
end)

-- A default camera that continues from whatever direction it finds: each frame it adds the drag to the
-- direction left last frame. The client's increment must not be re-applied on top of itself.
test(
	"advance: a camera that continues from its own CFrame ends at factor times the drag",
	function()
		local drag = 0.1
		local factor = 2
		local camera = 0 -- yaw of the camera CFrame
		local prevYaw: number? = nil
		for _ = 1, 4 do
			local yaw = camera + drag -- the default script's output this frame
			local ey = CameraLook.advance(prevYaw, 0, yaw, 0, factor, MAX_PITCH)
			camera = yaw + ey
			prevYaw = CameraLook.wrap(camera)
		end
		-- First frame has no previous direction, so only 3 of the 4 drags are scaled: 0.1 + 3 * 0.2.
		expect.near(camera, 0.7, 1e-9)
	end
)

return {}
