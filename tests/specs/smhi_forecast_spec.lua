local Constants = require("weather_constants")
local Forecast = require("weather_forecast")
local I18n = require("weather_i18n")
local SmhiForecast = require("smhi_forecast")
local WeatherCodes = require("weather_codes")
local expect = require("spec_helper")

local FETCHED_AT = 1792571400
local SUPPLEMENT_FETCHED_AT = 1792492200
local FIRST_STEP_TIME = 1792573200
local WEDNESDAY_START = 1792533600
local WEDNESDAY_SUNRISE = 1792562413
local SMHI_DAY_COUNT = 11
local FRIDAY_INDEX = 3
local PRECISION = 1000
local LIGHT_RAIN = 1018
local OVERCAST = 1006
local EXPECTED_URL = "https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1"
    .. "/geotype/point/lon/12.3200/lat/58.3800/data.json"

local function rounded(value)
    return math.floor(value * PRECISION + 0.5) / PRECISION
end

local function parsedFixture()
    local supplement = Forecast.parse(FIXTURES.forecast, SUPPLEMENT_FETCHED_AT)
    return SmhiForecast.parse(FIXTURES.smhi, { fetched_at = FETCHED_AT, supplement = supplement })
end

return {
    ["builds the point forecast url"] = function()
        expect.equal(SmhiForecast.buildUrl({ latitude = 58.38, longitude = 12.32 }), EXPECTED_URL)
    end,
    ["rejects responses without a time series"] = function()
        expect.isNil(SmhiForecast.parse(nil, { fetched_at = FETCHED_AT }))
        expect.isNil(SmhiForecast.parse({}, { fetched_at = FETCHED_AT }))
        expect.isNil(SmhiForecast.parse({ timeSeries = {} }, { fetched_at = FETCHED_AT }))
    end,
    ["reads current conditions from the first step"] = function()
        local model = parsedFixture()
        expect.equal(model.source, Constants.SOURCE_SMHI)
        expect.equal(model.utc_offset, 7200)
        expect.equal(model.current.time, FIRST_STEP_TIME)
        expect.equal(model.current.temperature, 10.4)
        expect.equal(model.current.humidity, 95)
        expect.equal(model.current.code, LIGHT_RAIN)
        expect.equal(rounded(model.current.feels_like), 7.268)
        expect.equal(#model.hours, Constants.FORECAST_HOURS)
    end,
    ["summarises each local day"] = function()
        local model = parsedFixture()
        local wednesday = model.days[1]
        expect.equal(#model.days, SMHI_DAY_COUNT)
        expect.equal(wednesday.time, WEDNESDAY_START)
        expect.equal(wednesday.high, 11.4)
        expect.equal(wednesday.low, 10.3)
        expect.equal(wednesday.rain_chance, 100)
        expect.equal(wednesday.code, LIGHT_RAIN)
        expect.equal(model.days[FRIDAY_INDEX].code, OVERCAST)
    end,
    ["takes uv and sun times from the supplement"] = function()
        local wednesday = parsedFixture().days[1]
        expect.equal(wednesday.uv_index, 1.15)
        expect.equal(wednesday.sunrise, WEDNESDAY_SUNRISE)
    end,
    ["works without a supplement"] = function()
        local model = SmhiForecast.parse(FIXTURES.smhi, { fetched_at = FETCHED_AT })
        expect.equal(model.utc_offset, 0)
        expect.isNil(model.days[1].uv_index)
        expect.equal(model.current.is_day, 1)
    end,
    ["treats missing values as absent"] = function()
        local model = SmhiForecast.parse({ timeSeries = { {
            time = "2026-10-21T09:00:00Z",
            data = { air_temperature = 9999, relative_humidity = 80, wind_speed = 2, symbol_code = 9999 },
        } } }, { fetched_at = FETCHED_AT })
        expect.isNil(model.current.temperature)
        expect.isNil(model.current.feels_like)
        expect.isNil(model.current.code)
    end,
    ["names and draws smhi symbols"] = function()
        I18n.setLanguage("sv")
        expect.equal(WeatherCodes.describe(LIGHT_RAIN, true).label, "Lätt regn")
        I18n.setLanguage("en")
        expect.equal(WeatherCodes.describe(LIGHT_RAIN, true).label, "Light rain")
        expect.equal(WeatherCodes.describe(LIGHT_RAIN, true).icon, "drizzle")
        expect.equal(WeatherCodes.describe(Constants.SMHI_CODE_OFFSET + 1, false).icon, "clear_night")
    end,
}
