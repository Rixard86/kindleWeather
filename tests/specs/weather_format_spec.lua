local Format = require("weather_format")
local I18n = require("weather_i18n")
local expect = require("spec_helper")

local SUMMER_TIME_OFFSET = 7200
local TUESDAY_12_15 = 1792491300
local TUESDAY_MIDNIGHT = 1792447200
local THURSDAY_MIDNIGHT = 1792620000
local DAY_LENGTH_SECONDS = 35668.04
local SHORT_DAY_SECONDS = 21900
local FIVE_MINUTES = 300
local HALF_A_MINUTE = 30
local ONE_DAY = 86400
local SIX_DAYS = 6 * ONE_DAY

return {
    ["rounds temperatures to whole degrees"] = function()
        expect.equal(Format.temperature(7.5), "8°")
        expect.equal(Format.temperature(7.4), "7°")
        expect.equal(Format.temperature(-0.6), "-1°")
        expect.equal(Format.temperature(-0.4), "0°")
    end,
    ["shows a dash for missing values"] = function()
        expect.equal(Format.temperature(nil), "–")
        expect.equal(Format.percent(nil), "–")
        expect.equal(Format.wholeNumber(nil), "–")
    end,
    ["formats percentages and whole numbers"] = function()
        expect.equal(Format.percent(84), "84%")
        expect.equal(Format.wholeNumber(1.85), "2")
    end,
    ["formats local clock time from a utc epoch"] = function()
        expect.equal(Format.clock(TUESDAY_12_15, SUMMER_TIME_OFFSET), "12:15")
    end,
    ["formats dates without leading zeros"] = function()
        I18n.setLanguage("en")
        expect.equal(Format.date(TUESDAY_12_15, SUMMER_TIME_OFFSET), "Tue 20 Oct")
        expect.equal(Format.weekdayAndDay(THURSDAY_MIDNIGHT, SUMMER_TIME_OFFSET), "Thu 22")
        expect.equal(Format.weekday(THURSDAY_MIDNIGHT, SUMMER_TIME_OFFSET), "Thu")
    end,
    ["formats dates in swedish"] = function()
        I18n.setLanguage("sv")
        expect.equal(Format.date(TUESDAY_12_15, SUMMER_TIME_OFFSET), "Tis 20 okt")
        expect.equal(Format.weekdayAndDay(THURSDAY_MIDNIGHT, SUMMER_TIME_OFFSET), "Tor 22")
        I18n.setLanguage("en")
    end,
    ["formats day lengths in hours and minutes"] = function()
        I18n.setLanguage("en")
        expect.equal(Format.duration(DAY_LENGTH_SECONDS), "9 h 54 min")
        expect.equal(Format.duration(SHORT_DAY_SECONDS), "6 h 05 min")
        I18n.setLanguage("sv")
        expect.equal(Format.duration(DAY_LENGTH_SECONDS), "9 tim 54 min")
        I18n.setLanguage("en")
        expect.equal(Format.duration(nil), "–")
    end,
    ["describes tomorrow's daylight change"] = function()
        I18n.setLanguage("en")
        expect.equal(Format.daylightChange(-FIVE_MINUTES), "Tomorrow 5 min shorter")
        expect.equal(Format.daylightChange(FIVE_MINUTES), "Tomorrow 5 min longer")
        expect.equal(Format.daylightChange(HALF_A_MINUTE - 1), "Same length tomorrow")
        expect.equal(Format.daylightChange(nil), "")
    end,
    ["counts days until an event"] = function()
        I18n.setLanguage("en")
        expect.equal(Format.daysUntil(SIX_DAYS), "in 6 days")
        expect.equal(Format.daysUntil(ONE_DAY), "tomorrow")
        expect.equal(Format.daysUntil(FIVE_MINUTES), "today")
    end,
    ["formats hours of the day"] = function()
        expect.equal(Format.hourOfDay(6), "06:00")
        expect.equal(Format.hourOfDay(23), "23:00")
    end,
    ["uses the location offset for day keys"] = function()
        expect.equal(Format.dayKey(TUESDAY_MIDNIGHT, SUMMER_TIME_OFFSET), "2026-10-20")
        expect.equal(Format.dayKey(TUESDAY_MIDNIGHT, 0), "2026-10-19")
    end,
}
