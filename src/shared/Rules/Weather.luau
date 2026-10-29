--!strict
-- Whether the weather emitter runs. Pure: no Roblox APIs, so the reduce-motion rule is checked in Lune.

local Weather = {}

-- A missing or "none" kind never emits; reduce-motion silences every kind.
function Weather.emitting(reduceMotion: boolean, kind: string?): boolean
	return not reduceMotion and kind ~= nil and kind ~= "none"
end

return Weather
