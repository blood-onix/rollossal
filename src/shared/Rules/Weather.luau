--!strict
-- Whether the weather emitter runs, how its particles move, and the live rate cap. Pure: no Roblox
-- APIs, so the reduce-motion rule and the motion table are checked in Lune.

local Weather = {}

-- falls: particles travel down when true, up when false.
-- Accelerations are world-space studs/s², spin is RotSpeed magnitude in degrees/s.
export type Motion = {
	falls: boolean,
	accelerationX: number,
	accelerationY: number,
	spin: number,
}

local motions: { [string]: Motion } = {
	snow = { falls = true, accelerationX = 0, accelerationY = 0, spin = 0 },
	petals = { falls = true, accelerationX = 1, accelerationY = -1, spin = 90 },
	leaves = { falls = true, accelerationX = 2.5, accelerationY = -3, spin = 240 },
	sparkle = { falls = false, accelerationX = 0, accelerationY = 0, spin = 0 },
}

-- Nil for a missing kind, "none", or any kind without a motion; those never emit.
function Weather.motion(kind: string?): Motion?
	if kind == nil then
		return nil
	end
	return motions[kind]
end

-- A missing or "none" kind never emits; reduce-motion silences every kind.
function Weather.emitting(reduceMotion: boolean, kind: string?): boolean
	return not reduceMotion and Weather.motion(kind) ~= nil
end

-- Keeps live particles (rate x lifetime) within the theme's maxParticles and the global budget.
function Weather.cappedRate(
	rate: number,
	lifetime: number,
	maxParticles: number,
	budget: number
): number
	if lifetime <= 0 then
		return 0
	end
	return math.min(rate, maxParticles / lifetime, budget / lifetime)
end

return Weather
