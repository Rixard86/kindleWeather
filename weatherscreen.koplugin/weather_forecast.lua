local Constants = require("weather_constants")

local Forecast = {}

local CONDITION_FIELDS = {
    temperature = "temperature_2m",
    feels_like = "apparent_temperature",
    humidity = "relative_humidity_2m",
    code = "weather_code",
    is_day = "is_day",
}

local HOURLY_FIELDS = {
    time = "time",
    temperature = "temperature_2m",
    feels_like = "apparent_temperature",
    humidity = "relative_humidity_2m",
    code = "weather_code",
    is_day = "is_day",
}

local DAILY_FIELDS = {
    time = "time",
    code = "weather_code",
    high = "temperature_2m_max",
    low = "temperature_2m_min",
    rain_chance = "precipitation_probability_max",
    uv_index = "uv_index_max",
    sunrise = "sunrise",
    sunset = "sunset",
    daylight = "daylight_duration",
}

local function apiFieldList(field_map)
    local names = {}
    for key, api_name in pairs(field_map) do
        if key ~= "time" then
            names[#names + 1] = api_name
        end
    end
    table.sort(names)
    return table.concat(names, ",")
end

local function encodeQuery(parameters)
    local parts = {}
    for _, parameter in ipairs(parameters) do
        parts[#parts + 1] = parameter.key .. "=" .. tostring(parameter.value)
    end
    return table.concat(parts, "&")
end

function Forecast.buildUrl(location)
    return Constants.FORECAST_URL .. "?" .. encodeQuery({
        { key = "latitude", value = location.latitude },
        { key = "longitude", value = location.longitude },
        { key = "current", value = apiFieldList(CONDITION_FIELDS) },
        { key = "hourly", value = apiFieldList(HOURLY_FIELDS) },
        { key = "daily", value = apiFieldList(DAILY_FIELDS) },
        { key = "timezone", value = "auto" },
        { key = "timeformat", value = "unixtime" },
        { key = "forecast_days", value = Constants.FORECAST_DAYS },
        { key = "forecast_hours", value = Constants.FORECAST_HOURS },
    })
end

local function readRecord(source, field_map)
    local record = {}
    for key, api_name in pairs(field_map) do
        record[key] = source[api_name]
    end
    return record
end

local function readRows(source, field_map)
    local rows = {}
    if type(source) ~= "table" or type(source.time) ~= "table" then
        return rows
    end
    for index = 1, #source.time do
        local row = {}
        for key, api_name in pairs(field_map) do
            local column = source[api_name]
            row[key] = type(column) == "table" and column[index] or nil
        end
        rows[index] = row
    end
    return rows
end

function Forecast.parse(response, fetched_at)
    if type(response) ~= "table" or type(response.current) ~= "table" then
        return nil
    end
    return {
        source = Constants.SOURCE_OPEN_METEO,
        fetched_at = fetched_at,
        utc_offset = tonumber(response.utc_offset_seconds) or 0,
        current = readRecord(response.current, CONDITION_FIELDS),
        hours = readRows(response.hourly, HOURLY_FIELDS),
        days = readRows(response.daily, DAILY_FIELDS),
    }
end

local function lastIndexAtOrBefore(rows, moment)
    local found
    for index, row in ipairs(rows) do
        if row.time > moment then
            break
        end
        found = index
    end
    return found
end

function Forecast.currentConditions(model, now)
    if now - model.fetched_at < Constants.SECONDS_PER_HOUR then
        return model.current
    end
    local index = lastIndexAtOrBefore(model.hours, now)
    return index and model.hours[index] or model.current
end

function Forecast.week(model, now)
    local week = {}
    local first_index = lastIndexAtOrBefore(model.days, now)
    if not first_index or now >= model.days[first_index].time + Constants.SECONDS_PER_DAY then
        return week
    end
    for index = first_index, #model.days do
        if #week >= Constants.WEEK_LENGTH_DAYS then
            break
        end
        week[#week + 1] = model.days[index]
    end
    return week
end

return Forecast
