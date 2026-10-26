--!strict
-- Settings validation: take what a candidate table says field by field, clamp numbers, ignore the rest.
-- Pure: no Roblox APIs, no clock, no randomness. Bounds come in as an argument.
-- Contract: specs/003-saving-and-economy/contracts/rules-api.md §Settings; data-model §3.

export type SettingsData = {
	musicVolume: number,
	effectsVolume: number,
	cameraSensitivity: number,
	reduceMotion: boolean,
	language: string,
}
export type Range = { min: number, max: number }
export type Bounds = {
	musicVolume: Range,
	effectsVolume: Range,
	cameraSensitivity: Range,
	languages: { string },
}

local Settings = {}

local function clampedNumber(value: unknown, range: Range, fallback: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.clamp(value, range.min, range.max)
end

local function allowedLanguage(value: unknown, languages: { string }, fallback: string): string
	if type(value) ~= "string" then
		return fallback
	end
	for _, code in languages do
		if code == value then
			return value
		end
	end
	return fallback
end

function Settings.validate(current: SettingsData, candidate: unknown, bounds: Bounds): SettingsData
	local result: SettingsData = {
		musicVolume = current.musicVolume,
		effectsVolume = current.effectsVolume,
		cameraSensitivity = current.cameraSensitivity,
		reduceMotion = current.reduceMotion,
		language = current.language,
	}
	if type(candidate) ~= "table" then
		return result
	end
	local fields = candidate :: { [string]: unknown }
	result.musicVolume = clampedNumber(fields.musicVolume, bounds.musicVolume, current.musicVolume)
	result.effectsVolume =
		clampedNumber(fields.effectsVolume, bounds.effectsVolume, current.effectsVolume)
	result.cameraSensitivity =
		clampedNumber(fields.cameraSensitivity, bounds.cameraSensitivity, current.cameraSensitivity)
	if type(fields.reduceMotion) == "boolean" then
		result.reduceMotion = fields.reduceMotion
	end
	result.language = allowedLanguage(fields.language, bounds.languages, current.language)
	return result
end

return Settings
