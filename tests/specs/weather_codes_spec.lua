local WeatherCodes = require("weather_codes")
local expect = require("spec_helper")

local CLEAR_SKY = 0
local PARTLY_CLOUDY = 2
local OVERCAST = 3
local LIGHT_RAIN = 61
local UNLISTED_CODE = 1234

return {
    ["describes clear daytime sky"] = function()
        local condition = WeatherCodes.describe(CLEAR_SKY, true)
        expect.equal(condition.label, "Clear")
        expect.equal(condition.icon, "clear")
    end,
    ["uses night icons for clear and partly cloudy skies"] = function()
        expect.equal(WeatherCodes.describe(CLEAR_SKY, false).icon, "clear_night")
        expect.equal(WeatherCodes.describe(PARTLY_CLOUDY, false).icon, "partly_night")
    end,
    ["keeps precipitation icons at night"] = function()
        expect.equal(WeatherCodes.describe(LIGHT_RAIN, false).icon, "rain")
    end,
    ["treats a missing day flag as daytime"] = function()
        expect.equal(WeatherCodes.describe(OVERCAST, nil).icon, "cloudy")
        expect.equal(WeatherCodes.describe(CLEAR_SKY, nil).icon, "clear")
    end,
    ["falls back for unknown codes"] = function()
        local condition = WeatherCodes.describe(UNLISTED_CODE, true)
        expect.equal(condition.label, "Unknown")
        expect.equal(condition.icon, "cloudy")
    end,
}
