--!strict
-- Player-facing text: Strings.luau feeds one LocalizationTable. Unknown keys return the key, never an error.
-- args maps placeholder names to strings or numbers; it is typed loosely so table literals are accepted.

local LocalizationService = game:GetService("LocalizationService")

local Strings = require(script.Parent.Strings)

local SOURCE_LOCALE = "en-us"

local Localizer = {}

local localizationTable = Instance.new("LocalizationTable")
localizationTable.SourceLocaleId = SOURCE_LOCALE
do
	local entries = {}
	for key, texts in Strings do
		table.insert(entries, {
			Key = key,
			Values = { [SOURCE_LOCALE] = texts.en },
		})
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

function Localizer.t(key: string, args: { [string]: any }?): string
	if Strings[key] == nil then
		return key
	end
	local formatArgs = stringifyNumbers(args)
	for _, localeId in { LocalizationService.RobloxLocaleId, SOURCE_LOCALE } do
		local translator = getTranslator(localeId)
		if translator then
			local ok, text = pcall(function()
				return translator:FormatByKey(key, formatArgs)
			end)
			if ok and text ~= "" then
				return text
			end
		end
	end
	return key
end

return Localizer
