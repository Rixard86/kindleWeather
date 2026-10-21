local Calendar = require("weather_calendar")
local Constants = require("weather_constants")

local SmhiForecast = {}

local ISO_TIME_PATTERN = "^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z$"
local MISSING_VALUE = 9999
local NOON_HOUR = 12
local NOON_SECONDS = NOON_HOUR * Constants.SECONDS_PER_HOUR
local PERCENT = 100
local VAPOUR_PRESSURE_FACTOR = 6.105
local MAGNUS_A = 17.27
local MAGNUS_B = 237.7
local HUMIDITY_WEIGHT = 0.33
local WIND_WEIGHT = 0.70
local APPARENT_OFFSET = 4.0
local DAY = 1
local NIGHT = 0

function SmhiForecast.buildUrl(location)
    return string.format(Constants.SMHI_URL_TEMPLATE, location.longitude, location.latitude)
end

function SmhiForecast.apparentTemperature(step)
    if not (step.temperature and step.humidity and step.wind) then
        return nil
    end
    local vapour_pressure = step.humidity / PERCENT * VAPOUR_PRESSURE_FACTOR
        * math.exp(MAGNUS_A * step.temperature / (MAGNUS_B + step.temperature))
    return step.temperature + HUMIDITY_WEIGHT * vapour_pressure - WIND_WEIGHT * step.wind - APPARENT_OFFSET
end

local function isoToEpoch(text)
    local year, month, day, hour, minute, second = (text or ""):match(ISO_TIME_PATTERN)
    if not year then
        return nil
    end
    return Calendar.utcEpoch({
        year = tonumber(year), month = tonumber(month), day = tonumber(day),
        hour = tonumber(hour), minute = tonumber(minute), second = tonumber(second),
    })
end

local function present(value)
    if value == nil or value == MISSING_VALUE then
        return nil
    end
    return value
end

local function readSteps(series)
    local steps = {}
    for _, entry in ipairs(series) do
        local data = entry.data or {}
        local time = isoToEpoch(entry.time)
        if time then
            steps[#steps + 1] = {
                time = time,
                temperature = present(data.air_temperature),
                humidity = present(data.relative_humidity),
                wind = present(data.wind_speed),
                rain_chance = present(data.probability_of_precipitation),
                symbol = present(data.symbol_code),
            }
        end
    end
    return steps
end

local function sunDays(supplement)
    local by_start = {}
    for _, day in ipairs(supplement and supplement.days or {}) do
        by_start[day.time] = day
    end
    return by_start
end

local function isDaylight(time, context)
    local sun = context.sun_days[Calendar.localDayStart(time, context.utc_offset)]
    if not (sun and sun.sunrise and sun.sunset) then
        return true
    end
    return time >= sun.sunrise and time < sun.sunset
end

local function conditionsAt(step, context)
    return {
        time = step.time,
        temperature = step.temperature,
        feels_like = SmhiForecast.apparentTemperature(step),
        humidity = step.humidity,
        code = step.symbol and Constants.SMHI_CODE_OFFSET + step.symbol,
        is_day = isDaylight(step.time, context) and DAY or NIGHT,
    }
end

local function newDay(start, context)
    local sun = context.sun_days[start] or {}
    return {
        time = start,
        uv_index = sun.uv_index,
        sunrise = sun.sunrise,
        sunset = sun.sunset,
        daylight = sun.daylight,
        noon_distance = math.huge,
    }
end

local function includeStep(day, entry)
    local step = entry.step
    if step.temperature then
        day.high = math.max(day.high or step.temperature, step.temperature)
        day.low = math.min(day.low or step.temperature, step.temperature)
    end
    if step.rain_chance then
        day.rain_chance = math.max(day.rain_chance or step.rain_chance, step.rain_chance)
    end
    local distance = math.abs((step.time + entry.utc_offset) % Constants.SECONDS_PER_DAY - NOON_SECONDS)
    if step.symbol and distance < day.noon_distance then
        day.noon_distance = distance
        day.code = Constants.SMHI_CODE_OFFSET + step.symbol
    end
end

local function dailySummaries(steps, context)
    local days, by_start = {}, {}
    for _, step in ipairs(steps) do
        local start = Calendar.localDayStart(step.time, context.utc_offset)
        if not by_start[start] then
            by_start[start] = newDay(start, context)
            days[#days + 1] = by_start[start]
        end
        includeStep(by_start[start], { step = step, utc_offset = context.utc_offset })
    end
    for _, day in ipairs(days) do
        day.noon_distance = nil
    end
    return days
end

function SmhiForecast.parse(response, spec)
    if type(response) ~= "table" or type(response.timeSeries) ~= "table" then
        return nil
    end
    local steps = readSteps(response.timeSeries)
    if #steps == 0 then
        return nil
    end
    local supplement = spec.supplement or {}
    local context = { utc_offset = supplement.utc_offset or 0, sun_days = sunDays(supplement) }
    local hours = {}
    for _, step in ipairs(steps) do
        if step.time <= spec.fetched_at + Constants.FORECAST_HOURS * Constants.SECONDS_PER_HOUR then
            hours[#hours + 1] = conditionsAt(step, context)
        end
    end
    return {
        source = Constants.SOURCE_SMHI,
        fetched_at = spec.fetched_at,
        utc_offset = context.utc_offset,
        current = conditionsAt(steps[1], context),
        hours = hours,
        days = dailySummaries(steps, context),
    }
end

return SmhiForecast
