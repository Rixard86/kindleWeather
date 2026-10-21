local I18n = require("weather_i18n")

local Format = {}

local DEGREE_SIGN = "°"
local MISSING_VALUE = "–"
local ROUNDING_OFFSET = 0.5
local FIRST_WEEKDAY_INDEX = 1
local SECONDS_PER_MINUTE = 60
local MINUTES_PER_HOUR = 60
local SECONDS_PER_DAY = 86400
local HOUR_OF_DAY_PATTERN = "%02d:00"

local function shiftToLocal(epoch, utc_offset)
    return epoch + (utc_offset or 0)
end

local function roundToInteger(value)
    return math.floor(value + ROUNDING_OFFSET)
end

local function weekdayName(local_time)
    return I18n.weekday(tonumber(os.date("!%w", local_time)) + FIRST_WEEKDAY_INDEX)
end

local function dayOfMonth(local_time)
    return tonumber(os.date("!%d", local_time))
end

function Format.temperature(value)
    if type(value) ~= "number" then
        return MISSING_VALUE
    end
    return string.format("%d%s", roundToInteger(value), DEGREE_SIGN)
end

function Format.percent(value)
    if type(value) ~= "number" then
        return MISSING_VALUE
    end
    return string.format("%d%%", roundToInteger(value))
end

function Format.wholeNumber(value)
    if type(value) ~= "number" then
        return MISSING_VALUE
    end
    return string.format("%d", roundToInteger(value))
end

function Format.duration(seconds)
    if type(seconds) ~= "number" then
        return MISSING_VALUE
    end
    local minutes = roundToInteger(seconds / SECONDS_PER_MINUTE)
    return string.format(I18n.text("duration"), math.floor(minutes / MINUTES_PER_HOUR), minutes % MINUTES_PER_HOUR)
end

function Format.daylightChange(seconds)
    if type(seconds) ~= "number" then
        return ""
    end
    local minutes = roundToInteger(seconds / SECONDS_PER_MINUTE)
    if minutes > 0 then
        return string.format(I18n.text("tomorrow_longer"), minutes)
    end
    if minutes < 0 then
        return string.format(I18n.text("tomorrow_shorter"), -minutes)
    end
    return I18n.text("tomorrow_same")
end

function Format.daysUntil(seconds)
    local days = roundToInteger(seconds / SECONDS_PER_DAY)
    if days < 1 then
        return I18n.text("within_a_day")
    end
    if days == 1 then
        return I18n.text("in_one_day")
    end
    return string.format(I18n.text("in_days"), days)
end

function Format.hourOfDay(hour)
    return string.format(HOUR_OF_DAY_PATTERN, hour)
end

function Format.clock(epoch, utc_offset)
    if type(epoch) ~= "number" then
        return MISSING_VALUE
    end
    return os.date("!%H:%M", shiftToLocal(epoch, utc_offset))
end

function Format.weekday(epoch, utc_offset)
    return weekdayName(shiftToLocal(epoch, utc_offset))
end

function Format.weekdayAndDay(epoch, utc_offset)
    local local_time = shiftToLocal(epoch, utc_offset)
    return string.format("%s %d", weekdayName(local_time), dayOfMonth(local_time))
end

function Format.date(epoch, utc_offset)
    local local_time = shiftToLocal(epoch, utc_offset)
    local month = I18n.month(tonumber(os.date("!%m", local_time)))
    return string.format("%s %d %s", weekdayName(local_time), dayOfMonth(local_time), month)
end

function Format.dayKey(epoch, utc_offset)
    return os.date("!%Y-%m-%d", shiftToLocal(epoch, utc_offset))
end

return Format
