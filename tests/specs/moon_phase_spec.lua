local MoonDrawing = require("moon_drawing")
local MoonPhase = require("moon_phase")
local expect = require("spec_helper")

local ONE_HOUR = 3600
local ONE_DAY = 86400
local BEFORE_JANUARY_2024_NEW_MOON = 1704844800
local OFFICIAL_2024_PHASES = {
    { key = "new_moon", time = 1704974220 },
    { key = "first_quarter", time = 1705549980 },
    { key = "full_moon", time = 1706205240 },
    { key = "last_quarter", time = 1706915880 },
    { key = "new_moon", time = 1707519540 },
}
local FULL_MOON_INDEX = 3
local NEW_MOON_INDEX = 1
local NEARLY_ZERO = 0.01
local NEARLY_ONE = 0.99
local WAXING_HALFWAY = 0.125
local WAXING_GIBBOUS = 0.375
local THREE_DAYS = 3 * ONE_DAY
local NEW_MOON_FRACTION = 0
local FULL_MOON_FRACTION = 0.5

local function withinAnHour(actual, expected)
    expect.equal(math.abs(actual - expected) < ONE_HOUR, true)
end

return {
    ["predicts official 2024 phase times within an hour"] = function()
        local events = MoonPhase.upcoming(BEFORE_JANUARY_2024_NEW_MOON, #OFFICIAL_2024_PHASES)
        for index, official in ipairs(OFFICIAL_2024_PHASES) do
            expect.equal(events[index].key, official.key)
            withinAnHour(events[index].time, official.time)
        end
    end,
    ["names the phase near and between events"] = function()
        local full_moon = OFFICIAL_2024_PHASES[FULL_MOON_INDEX].time
        expect.equal(MoonPhase.name(full_moon + ONE_HOUR), "full_moon")
        expect.equal(MoonPhase.name(full_moon - THREE_DAYS), "waxing_gibbous")
        expect.equal(MoonPhase.name(full_moon + THREE_DAYS), "waning_gibbous")
    end,
    ["is dark at new moon and fully lit at full moon"] = function()
        local new_moon = OFFICIAL_2024_PHASES[NEW_MOON_INDEX].time
        local full_moon = OFFICIAL_2024_PHASES[FULL_MOON_INDEX].time
        expect.equal(MoonPhase.illumination(new_moon + ONE_HOUR) < NEARLY_ZERO, true)
        expect.equal(MoonPhase.illumination(full_moon) > NEARLY_ONE, true)
    end,
    ["draws a full disc at full moon and none at new moon"] = function()
        local full_disc = "M32 4 A28 28 0 0 0 32 60 A28.00 28 0 0 0 32 4Z"
        local empty_disc = "M32 4 A28 28 0 0 1 32 60 A28.00 28 0 0 0 32 4Z"
        expect.equal(MoonDrawing.svg(FULL_MOON_FRACTION):find(full_disc, 1, true) ~= nil, true)
        expect.equal(MoonDrawing.svg(NEW_MOON_FRACTION):find(empty_disc, 1, true) ~= nil, true)
    end,
    ["bulges the terminator the right way"] = function()
        expect.equal(MoonDrawing.svg(WAXING_HALFWAY):find("0 0 1 32 60 A19.80 28 0 0 0 32 4Z", 1, true) ~= nil, true)
        expect.equal(MoonDrawing.svg(WAXING_GIBBOUS):find("0 0 1 32 60 A19.80 28 0 0 1 32 4Z", 1, true) ~= nil, true)
    end,
}
