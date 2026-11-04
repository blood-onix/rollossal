--!strict
-- Scene kit expansion: turns a hand-authored kit (relative offsets) plus a placed instance into world placements.
-- Pure: no Roblox APIs, no clock, no randomness beyond a local seeded Park-Miller generator. Rules modules do
-- not require siblings, so the generator is repeated here and the types are structural copies of Layout's.

export type Placement = {
	id: string,
	objectId: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	spawnSlot: number?,
}
-- dx, dz are kit-local studs; yaw is degrees.
export type KitEntry = { objectId: string, dx: number, dz: number, yaw: number }
export type KitDef = { id: string, halfX: number, halfZ: number, entries: { KitEntry } }
-- yaw is degrees. jitterPos (studs) and jitterYaw (degrees) default to 0.5 and 3; y defaults to 0.
export type KitInstance = {
	kitId: string,
	ox: number,
	oz: number,
	yaw: number,
	seed: number,
	y: number?,
	jitterPos: number?,
	jitterYaw: number?,
}
export type Bounds = { minX: number, maxX: number, minZ: number, maxZ: number }

local MULTIPLIER = 48271
local MODULUS = 2147483647
local DEFAULT_JITTER_POS = 0.5
local DEFAULT_JITTER_YAW = 3
local EPSILON = 1e-9

local SceneKit = {}

local function step(state: number): number
	return state * MULTIPLIER % MODULUS
end

-- A value in [-1, 1].
local function signed(state: number): number
	return state / MODULUS * 2 - 1
end

function SceneKit.expand(
	kit: KitDef,
	instance: KitInstance,
	idPrefix: string,
	bounds: Bounds
): { Placement }
	local jitterPos = instance.jitterPos or DEFAULT_JITTER_POS
	local jitterYaw = instance.jitterYaw or DEFAULT_JITTER_YAW
	local yawRadians = math.rad(instance.yaw)
	local cosYaw, sinYaw = math.cos(yawRadians), math.sin(yawRadians)
	local state = instance.seed % (MODULUS - 1) + 1

	local out: { Placement } = {}
	for index, entry in kit.entries do
		if math.abs(entry.dx) > kit.halfX + EPSILON or math.abs(entry.dz) > kit.halfZ + EPSILON then
			error(
				`SceneKit: kit {kit.id} entry {index} ({entry.objectId}) is outside the footprint `
					.. `({entry.dx}, {entry.dz}) vs half {kit.halfX} x {kit.halfZ}`
			)
		end

		state = step(state)
		local jx = signed(state) * jitterPos
		state = step(state)
		local jz = signed(state) * jitterPos
		state = step(state)
		local jyaw = signed(state) * jitterYaw

		local x = instance.ox + entry.dx * cosYaw + entry.dz * sinYaw + jx
		local z = instance.oz - entry.dx * sinYaw + entry.dz * cosYaw + jz
		if x < bounds.minX or x > bounds.maxX or z < bounds.minZ or z > bounds.maxZ then
			error(
				`SceneKit: kit {kit.id} entry {index} ({entry.objectId}) at ({x}, {z}) is outside the bounds`
			)
		end

		table.insert(out, {
			id = `{idPrefix}_{index}`,
			objectId = entry.objectId,
			x = x,
			y = instance.y or 0,
			z = z,
			yaw = math.rad(entry.yaw + instance.yaw + jyaw),
			spawnSlot = nil,
		})
	end
	return out
end

return SceneKit
