local Device = require("device")
local Layout = require("weather_layout")
local NewsWidgets = require("news_widgets")
local Widgets = require("weather_widgets")

local Screen = Device.screen

local WeatherTwoNewsPane = {
    EXTRA_CREDIT_KEY = "news_credit",
}

local COLUMNS = 2
local GAPS_AROUND_DIVIDER = 2

local function newsColumn(context, spec)
    return NewsWidgets.column(context, {
        title_key = spec.title_key,
        news = spec.news,
        box = spec.box,
        headline_size = Layout.NEWS_COMPACT_HEADLINE_FONT_SIZE,
    })
end

function WeatherTwoNewsPane.content(context, box)
    local gap = Screen:scaleBySize(Layout.COLUMN_GAP)
    local divider = Widgets.verticalLine(box.h, Layout.LIGHT_LINE_THICKNESS)
    local column_width = math.floor((box.w - GAPS_AROUND_DIVIDER * gap - divider:getSize().w) / COLUMNS)
    local column_box = { w = column_width, h = box.h }
    return Widgets.row({
        newsColumn(context, { title_key = "local_news", news = context.news, box = column_box }),
        Widgets.horizontalGap(gap),
        divider,
        Widgets.horizontalGap(gap),
        newsColumn(context, { title_key = "national_news", news = context.national_news, box = column_box }),
    }, "top")
end

return WeatherTwoNewsPane
