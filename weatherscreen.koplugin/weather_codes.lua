local Constants = require("weather_constants")
local I18n = require("weather_i18n")

local ICONS = {
    [0] = "clear",
    [1] = "partly",
    [2] = "partly",
    [3] = "cloudy",
    [45] = "fog",
    [48] = "fog",
    [51] = "drizzle",
    [53] = "drizzle",
    [55] = "drizzle",
    [56] = "drizzle",
    [57] = "drizzle",
    [61] = "rain",
    [63] = "rain",
    [65] = "rain",
    [66] = "rain",
    [67] = "rain",
    [71] = "snow",
    [73] = "snow",
    [75] = "snow",
    [77] = "snow",
    [80] = "rain",
    [81] = "rain",
    [82] = "rain",
    [85] = "snow",
    [86] = "snow",
    [95] = "thunder",
    [96] = "thunder",
    [99] = "thunder",
}

local SMHI_ICONS = {
    "clear", "partly", "partly", "partly", "cloudy", "cloudy", "fog",
    "rain", "rain", "rain", "thunder", "sleet", "sleet", "sleet", "snow", "snow", "snow",
    "drizzle", "rain", "rain", "thunder", "sleet", "sleet", "sleet", "snow", "snow", "snow",
}

for symbol, icon in ipairs(SMHI_ICONS) do
    ICONS[Constants.SMHI_CODE_OFFSET + symbol] = icon
end

local UNKNOWN_ICON = "cloudy"

local NIGHT_ICONS = {
    clear = "clear_night",
    partly = "partly_night",
}

local WeatherCodes = {
    KNOWN_CODES = ICONS,
}

function WeatherCodes.describe(code, is_day)
    local icon = ICONS[code] or UNKNOWN_ICON
    if is_day == false then
        icon = NIGHT_ICONS[icon] or icon
    end
    return { label = I18n.condition(code), icon = icon }
end

return WeatherCodes
