local I18n = require("weather_i18n")
local Location = require("weather_location")
local expect = require("spec_helper")

local SEARCH_URL_PREFIX = "https://geocoding-api.open-meteo.com/v1/search?name=V%C3%A4nersborg&count=1"

return {
    ["escapes city names in the search url"] = function()
        I18n.setLanguage("en")
        expect.equal(Location.buildSearchUrl("Vänersborg"), SEARCH_URL_PREFIX .. "&language=en&format=json")
    end,
    ["searches in the chosen language"] = function()
        I18n.setLanguage("sv")
        expect.equal(Location.buildSearchUrl("Vänersborg"), SEARCH_URL_PREFIX .. "&language=sv&format=json")
        I18n.setLanguage("en")
    end,
    ["reads the first search result"] = function()
        local location = Location.parseSearch(FIXTURES.geocode)
        expect.equal(location.name, "Vänersborg")
        expect.equal(location.country, "Sweden")
        expect.equal(location.latitude, 58.38075)
        expect.equal(location.longitude, 12.3234)
    end,
    ["returns nil when nothing is found"] = function()
        expect.isNil(Location.parseSearch({}))
        expect.isNil(Location.parseSearch({ results = {} }))
        expect.isNil(Location.parseSearch(nil))
    end,
    ["labels a location with its country"] = function()
        expect.equal(Location.label({ name = "Vänersborg", country = "Sweden" }), "Vänersborg, Sweden")
        expect.equal(Location.label({ name = "Vänersborg" }), "Vänersborg")
    end,
}
