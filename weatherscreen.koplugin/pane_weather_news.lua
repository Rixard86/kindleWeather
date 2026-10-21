local Layout = require("weather_layout")
local NewsWidgets = require("news_widgets")

local WeatherNewsPane = {
    EXTRA_CREDIT_KEY = "news_credit",
}

function WeatherNewsPane.content(context, box)
    return NewsWidgets.column(context, {
        title_key = "local_news",
        news = context.news,
        box = box,
        headline_size = Layout.NEWS_HEADLINE_FONT_SIZE,
    })
end

return WeatherNewsPane
