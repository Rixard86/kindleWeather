local logger = require("logger")
local Api = require("weather_api")
local Constants = require("weather_constants")
local Panes = require("weather_panes")
local Schedule = require("weather_schedule")
local SleepScreen = require("weather_sleep_screen")

local Downloads = {}

local function freshOpenMeteo(plugin)
    local model = Api.fetchOpenMeteo(plugin:getLocation())
    if model then
        plugin:saveSetting("supplement", model)
    end
    return model
end

local function supplementFor(plugin)
    local cached = plugin.settings:readSetting("supplement")
    if Schedule.supplementIsFresh(cached, os.time()) then
        return cached
    end
    return freshOpenMeteo(plugin) or cached
end

local function fetchForecast(plugin)
    if plugin:getSource() ~= Constants.SOURCE_SMHI then
        return freshOpenMeteo(plugin)
    end
    local model = Api.fetchSmhi({ location = plugin:getLocation(), supplement = supplementFor(plugin) })
    if model then
        return model
    end
    logger.warn("WeatherScreen: SMHI forecast unavailable, using Open-Meteo")
    return freshOpenMeteo(plugin)
end

local function storeNews(plugin, entry)
    if entry.news then
        plugin:saveSetting(entry.key, entry.news)
    end
end

function Downloads.run(plugin)
    local model = fetchForecast(plugin)
    if model then
        plugin:saveSetting("forecast", model)
    end
    local pane = Panes.find(plugin:getPaneId())
    if pane.needs_local_news then
        storeNews(plugin, { key = "news", news = Api.fetchNews(plugin:getLocation()) })
    end
    if pane.needs_national_news then
        storeNews(plugin, { key = "national_news", news = Api.fetchNationalNews() })
    end
    SleepScreen.redraw()
    return model ~= nil
end

return Downloads
