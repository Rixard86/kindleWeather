local Calendar = require("weather_calendar")
local Constants = require("weather_constants")

local NewsDates = {}

local MONTH_NUMBERS = {
    Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
    Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12,
}
local RFC_822_PATTERN = "(%d+)%s+(%a+)%s+(%d+)%s+(%d+):(%d+):?(%d*)%s*([%+%-]?%w*)"
local NUMERIC_ZONE_PATTERN = "^([%+%-])(%d%d)(%d%d)$"
local SECONDS_PER_MINUTE = 60

local function zoneOffsetSeconds(zone)
    local sign, hours, minutes = zone:match(NUMERIC_ZONE_PATTERN)
    if not sign then
        return 0
    end
    local offset = tonumber(hours) * Constants.SECONDS_PER_HOUR + tonumber(minutes) * SECONDS_PER_MINUTE
    return sign == "-" and -offset or offset
end

function NewsDates.parse(text)
    local day, month_name, year, hours, minutes, seconds, zone = (text or ""):match(RFC_822_PATTERN)
    local month = MONTH_NUMBERS[month_name]
    if not month then
        return nil
    end
    return Calendar.utcEpoch({
        year = tonumber(year),
        month = month,
        day = tonumber(day),
        hour = tonumber(hours),
        minute = tonumber(minutes),
        second = tonumber(seconds),
    }) - zoneOffsetSeconds(zone)
end

return NewsDates
