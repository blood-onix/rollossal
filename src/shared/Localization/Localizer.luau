--!strict
-- Player-facing text: Strings.luau feeds one LocalizationTable. Unknown keys return the key, never an error.
-- args maps placeholder names to strings or numbers; it is typed loosely so table literals are accepted.

local LocalizationService = game:GetService("LocalizationService")

local Config = require(script.Parent.Parent.Config)
local Strings = require(script.Parent.Strings)

local SOURCE_LOCALE = "en-us"
local SPANISH_LOCALE = "es-es"
local AUTO = "auto"

local Localizer = {}

-- The player's language override (Settings), "auto" meaning follow RobloxLocaleId. Client only in practice.
local language = AUTO
local listeners: { () -> () } = {}

-- Callback list, not a BindableEvent: no Instance, and a plain call in the order connected.
Localizer.changed = {
	Connect = function(_self: any, fn: () -> ())
		table.insert(listeners, fn)
	end,
}

local localizationTable = Instance.new("LocalizationTable")
localizationTable.SourceLocaleId = SOURCE_LOCALE
do
	local entries = {}
	for key, texts in Strings do
		local values = { [SOURCE_LOCALE] = texts.en }
		if texts.es ~= nil then
			values[SPANISH_LOCALE] = texts.es
		end
		table.insert(entries, { Key = key, Values = values })
	end
	localizationTable:SetEntries(entries)
end

local function getTranslator(localeId: string): Translator?
	local ok, translator = pcall(function()
		return localizationTable:GetTranslator(localeId)
	end)
	if ok then
		return translator
	end
	return nil
end

-- Translator formats numbers with two decimals ("1.00"), so numbers are passed as plain text; callers
-- that want a fixed precision format the number themselves.
local function stringifyNumbers(args: { [string]: any }?): { [string]: any }
	local out: { [string]: any } = {}
	if args then
		for name, value in args do
			out[name] = if typeof(value) == "number" then tostring(value) else value
		end
	end
	return out
end

-- Locale order: the localeId argument, the language override (unless "auto"), the Roblox locale, en-us.
-- A locale with no text for the key is skipped, so the key falls back to en-us before it falls back to itself.
function Localizer.t(key: string, args: { [string]: any }?, localeId: string?): string
	local entry = Strings[key]
	if entry == nil then
		return key
	end
	local formatArgs = stringifyNumbers(args)
	local order: { string } = {}
	if localeId ~= nil then
		table.insert(order, localeId)
	end
	if language ~= AUTO then
		table.insert(order, language)
	end
	table.insert(order, LocalizationService.RobloxLocaleId)
	table.insert(order, SOURCE_LOCALE)
	for _, candidate in order do
		-- Only es-es and the source locale have entries; any other locale would just return the English text
		-- through the translator's own fallback, so it is skipped to keep the order explicit.
		local hasText = candidate == SOURCE_LOCALE
			or (candidate == SPANISH_LOCALE and entry.es ~= nil)
		if hasText then
			local translator = getTranslator(candidate)
			if translator then
				local ok, text = pcall(function()
					return translator:FormatByKey(key, formatArgs)
				end)
				if ok and text ~= "" then
					return text
				end
			end
		end
	end
	return key
end

function Localizer.getLanguage(): string
	return language
end

-- Accepts a code from Config.Settings.languages; anything else is ignored. Listeners fire only on a real change.
function Localizer.setLanguage(code: string)
	if
		type(code) ~= "string"
		or table.find(Config.Settings.languages, code) == nil
		or code == language
	then
		return
	end
	language = code
	for _, fn in listeners do
		task.spawn(fn)
	end
end

return Localizer
