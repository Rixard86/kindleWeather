local JSON = require("json")
local http = require("socket.http")
local logger = require("logger")
local ltn12 = require("ltn12")
local socket = require("socket")
local socketutil = require("socketutil")
local Constants = require("weather_constants")
local Forecast = require("weather_forecast")
local Location = require("weather_location")
local NewsFeed = require("news_feed")
local SmhiForecast = require("smhi_forecast")

local Api = {}

local SKIPPED_RESPONSE_VALUES = 1

local function requestBody(url)
    local sink = {}
    socketutil:set_timeout(Constants.HTTP_BLOCK_TIMEOUT_SECONDS, Constants.HTTP_TOTAL_TIMEOUT_SECONDS)
    local ok, status = pcall(function()
        return socket.skip(SKIPPED_RESPONSE_VALUES, http.request({
            url = url,
            method = "GET",
            sink = ltn12.sink.table(sink),
        }))
    end)
    socketutil:reset_timeout()
    if not ok or status ~= Constants.HTTP_STATUS_OK then
        logger.warn("WeatherScreen: request failed:", status)
        return nil
    end
    return table.concat(sink)
end

local function getJson(url)
    local body = requestBody(url)
    if not body then
        return nil
    end
    local ok, decoded = pcall(JSON.decode, body, JSON.decode.simple)
    if not ok then
        logger.warn("WeatherScreen: unreadable response:", decoded)
        return nil
    end
    return decoded
end

function Api.fetchOpenMeteo(location)
    return Forecast.parse(getJson(Forecast.buildUrl(location)), os.time())
end

function Api.fetchSmhi(spec)
    return SmhiForecast.parse(getJson(SmhiForecast.buildUrl(spec.location)),
        { fetched_at = os.time(), supplement = spec.supplement })
end

function Api.fetchNews(location)
    return NewsFeed.parse(requestBody(NewsFeed.buildUrl(location.name)), os.time())
end

function Api.fetchNationalNews()
    return NewsFeed.parse(requestBody(NewsFeed.buildTopStoriesUrl()), os.time())
end

function Api.findLocation(query)
    return Location.parseSearch(getJson(Location.buildSearchUrl(query)))
end

return Api
