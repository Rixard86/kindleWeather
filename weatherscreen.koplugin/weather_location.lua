local Constants = require("weather_constants")
local I18n = require("weather_i18n")
local Url = require("weather_url")

local Location = {}

function Location.buildSearchUrl(query)
    return string.format("%s?name=%s&count=%d&language=%s&format=json",
        Constants.GEOCODE_URL, Url.escape(query), Constants.GEOCODE_RESULT_COUNT, I18n.language())
end

function Location.parseSearch(response)
    local results = type(response) == "table" and response.results
    local first = type(results) == "table" and results[1]
    if type(first) ~= "table" or not first.latitude or not first.longitude then
        return nil
    end
    return {
        name = first.name,
        country = first.country,
        latitude = first.latitude,
        longitude = first.longitude,
    }
end

function Location.label(location)
    if location.country then
        return location.name .. ", " .. location.country
    end
    return location.name
end

return Location
