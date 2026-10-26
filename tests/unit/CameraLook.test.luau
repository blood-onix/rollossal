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

-- Closed loop, as in CameraController.bindLook: the default script continues from the CFrame the client
-- left, adds the player's drag to it, and the client then adds `advance`'s extra on top and remembers the
-- direction it left. A feedback error shows up as a turn that is not factor times the drag, or as a camera
-- that keeps turning once the drag stops.
local function simulate(factor: number, yawDrags: { number }, pitchDrags: { number })
	local cameraYaw, cameraPitch = 0, 0
	local prevYaw: number? = nil
	local prevPitch: number? = nil
	local history: { number } = {}
	for frame, dragYaw in yawDrags do
		local yaw = CameraLook.wrap(cameraYaw + dragYaw)
		local pitch = cameraPitch + (pitchDrags[frame] or 0)
		local ey, ep = CameraLook.advance(prevYaw, prevPitch, yaw, pitch, factor, MAX_PITCH)
		cameraYaw, cameraPitch = yaw + ey, pitch + ep
		prevYaw, prevPitch = CameraLook.wrap(cameraYaw), cameraPitch
		table.insert(history, cameraYaw)
	end
	return cameraYaw, cameraPitch, history
end

-- The first frame has no previous direction and is only used to prime the loop, so it carries no drag.
test("closed loop: factor 2 turns twice the drag, then stops when the input stops", function()
	local yaw, _, history = simulate(2, { 0, 0.1, 0.1, 0.1, 0, 0, 0, 0 }, {})
	expect.near(yaw, 0.6, 1e-9)
	expect.near(history[5], history[8], 1e-9)
end)

test("closed loop: factor 0.5 turns half the drag, then stops when the input stops", function()
	local yaw, _, history = simulate(0.5, { 0, 0.1, 0.1, 0.1, 0, 0, 0, 0 }, {})
	expect.near(yaw, 0.15, 1e-9)
	expect.near(history[5], history[8], 1e-9)
end)

test("closed loop: factor 1 turns exactly the drag", function()
	local yaw = simulate(1, { 0, 0.1, 0.1, 0.1, 0, 0 }, {})
	expect.near(yaw, 0.3, 1e-9)
end)

test("closed loop: no drag means no turn at any factor", function()
	for _, factor in { 0.5, 1, 2 } do
		local yaw, pitch = simulate(factor, { 0, 0, 0, 0, 0, 0 }, {})
		expect.equal(yaw, 0)
		expect.equal(pitch, 0)
	end
end)

test("closed loop: pitch scales too and holds once the input stops", function()
	local _, pitch = simulate(2, { 0, 0, 0, 0, 0, 0 }, { 0, 0.1, 0.1, 0, 0, 0 })
	expect.near(pitch, 0.4, 1e-9)
end)

test("closed loop: a drag across the +/-pi seam still scales by the short way round", function()
	local yaw = simulate(2, { 0, math.pi - 0.05, 0.1, 0, 0 }, {})
	-- The drags add up to pi + 0.05, doubled and wrapped to [-pi, pi].
	expect.near(CameraLook.wrap(yaw), CameraLook.wrap(2 * (math.pi + 0.05)), 1e-9)
end)

return {}
