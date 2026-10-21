local Constants = require("weather_constants")
local Forecast = require("weather_forecast")
local expect = require("spec_helper")

local FETCHED_AT = 1792492200
local TEN_MINUTES = 600
local THREE_HOURS = 3 * Constants.SECONDS_PER_HOUR
local FIFTEEN_O_CLOCK_INDEX = 3
local EXPECTED_URL = "https://api.open-meteo.com/v1/forecast?latitude=58.38075&longitude=12.3234"
    .. "&current=apparent_temperature,is_day,relative_humidity_2m,temperature_2m,weather_code"
    .. "&hourly=apparent_temperature,is_day,relative_humidity_2m,temperature_2m,weather_code"
    .. "&daily=daylight_duration,precipitation_probability_max,sunrise,sunset,temperature_2m_max,temperature_2m_min,uv_index_max,weather_code"
    .. "&timezone=auto&timeformat=unixtime&forecast_days=8&forecast_hours=24"

local function parsedFixture()
    return Forecast.parse(FIXTURES.forecast, FETCHED_AT)
end

return {
    ["builds the forecast url"] = function()
        expect.equal(Forecast.buildUrl(Constants.DEFAULT_LOCATION), EXPECTED_URL)
    end,
    ["rejects responses without current conditions"] = function()
        expect.isNil(Forecast.parse(nil, FETCHED_AT))
        expect.isNil(Forecast.parse({ error = true }, FETCHED_AT))
    end,
    ["parses current conditions and series"] = function()
        local model = parsedFixture()
        expect.equal(model.utc_offset, 7200)
        expect.equal(model.current.temperature, 8.6)
        expect.equal(model.current.humidity, 85)
        expect.equal(#model.hours, Constants.FORECAST_HOURS)
        expect.equal(#model.days, Constants.FORECAST_DAYS)
        expect.equal(model.days[1].uv_index, 1.85)
        expect.equal(model.days[2].rain_chance, 100)
    end,
    ["uses current conditions while they are fresh"] = function()
        local model = parsedFixture()
        expect.equal(Forecast.currentConditions(model, FETCHED_AT + TEN_MINUTES), model.current)
    end,
    ["uses the hourly forecast once current conditions are old"] = function()
        local model = parsedFixture()
        expect.equal(Forecast.currentConditions(model, FETCHED_AT + THREE_HOURS), model.hours[FIFTEEN_O_CLOCK_INDEX])
    end,
    ["returns a week starting today"] = function()
        local model = parsedFixture()
        local week = Forecast.week(model, FETCHED_AT)
        expect.equal(#week, Constants.WEEK_LENGTH_DAYS)
        expect.equal(week[1], model.days[1])
        expect.equal(week[Constants.WEEK_LENGTH_DAYS], model.days[Constants.WEEK_LENGTH_DAYS])
    end,
    ["moves the week forward after midnight"] = function()
        local model = parsedFixture()
        local week = Forecast.week(model, model.days[2].time + TEN_MINUTES)
        expect.equal(#week, Constants.WEEK_LENGTH_DAYS)
        expect.equal(week[1], model.days[2])
    end,
    ["returns no days when the forecast has run out"] = function()
        local model = parsedFixture()
        local after_last_day = model.days[#model.days].time + Constants.SECONDS_PER_DAY
        expect.equal(#Forecast.week(model, after_last_day), 0)
    end,
}
