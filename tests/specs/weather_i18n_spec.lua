local I18n = require("weather_i18n")
local WeatherCodes = require("weather_codes")
local expect = require("spec_helper")
local english = require("weather_strings_en")
local swedish = require("weather_strings_sv")

local WEEK_LENGTH = 7
local YEAR_LENGTH_MONTHS = 12
local PARTLY_CLOUDY = 2
local SMHI_SYMBOL_COUNT = 27

local function missingKeys(reference, translation)
    local missing = {}
    for key in pairs(reference) do
        if translation[key] == nil then
            missing[#missing + 1] = tostring(key)
        end
    end
    table.sort(missing)
    return table.concat(missing, ", ")
end

return {
    ["swedish has every english text"] = function()
        expect.equal(missingKeys(english.text, swedish.text), "")
    end,
    ["both languages name every weather code"] = function()
        for _, code_language in ipairs({ "en", "sv" }) do
            I18n.setLanguage(code_language)
            local unknown = I18n.text("unknown_condition")
            local unnamed = {}
            for code in pairs(WeatherCodes.KNOWN_CODES) do
                if I18n.condition(code) == unknown then
                    unnamed[#unnamed + 1] = tostring(code)
                end
            end
            expect.equal(table.concat(unnamed, ", "), "")
        end
        I18n.setLanguage("en")
    end,
    ["both languages name all smhi symbols"] = function()
        expect.equal(#english.smhi_conditions, SMHI_SYMBOL_COUNT)
        expect.equal(#swedish.smhi_conditions, SMHI_SYMBOL_COUNT)
    end,
    ["both languages have full calendars"] = function()
        expect.equal(#english.weekdays, WEEK_LENGTH)
        expect.equal(#swedish.weekdays, WEEK_LENGTH)
        expect.equal(#english.months, YEAR_LENGTH_MONTHS)
        expect.equal(#swedish.months, YEAR_LENGTH_MONTHS)
    end,
    ["switches the language"] = function()
        I18n.setLanguage("sv")
        expect.equal(I18n.language(), "sv")
        expect.equal(I18n.text("today"), "Idag")
        expect.equal(WeatherCodes.describe(PARTLY_CLOUDY, true).label, "Halvklart")
        I18n.setLanguage("en")
        expect.equal(I18n.text("today"), "Today")
    end,
    ["falls back to english for unknown languages"] = function()
        I18n.setLanguage("xx")
        expect.equal(I18n.language(), "en")
    end,
}
