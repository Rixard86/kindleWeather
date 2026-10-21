local Page = require("weather_page")

local Panes = {
    LIST = {
        { id = "simple_weather", name_key = "pane_simple_weather", module = require("pane_simple_weather") },
        {
            id = "weather_news",
            name_key = "pane_weather_news",
            module = require("pane_weather_news"),
            needs_local_news = true,
        },
        {
            id = "weather_two_news",
            name_key = "pane_weather_two_news",
            module = require("pane_weather_two_news"),
            needs_local_news = true,
            needs_national_news = true,
        },
        { id = "sun", name_key = "pane_sun", module = require("pane_sun") },
        { id = "moon", name_key = "pane_moon", module = require("pane_moon") },
    },
}

local DEFAULT_PANE_INDEX = 1

function Panes.find(id)
    for _, pane in ipairs(Panes.LIST) do
        if pane.id == id then
            return pane
        end
    end
    return Panes.LIST[DEFAULT_PANE_INDEX]
end

function Panes.build(id, view)
    return Page.build(view, Panes.find(id).module)
end

return Panes
