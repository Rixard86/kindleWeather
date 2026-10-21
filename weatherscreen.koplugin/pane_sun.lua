local Forecast = require("weather_forecast")
local Format = require("weather_format")
local I18n = require("weather_i18n")
local Layout = require("weather_layout")
local SimpleWeatherPane = require("pane_simple_weather")
local Widgets = require("weather_widgets")

local SunPane = {}

local STAT_COLUMNS = 3
local TODAY_INDEX = 1
local TOMORROW_INDEX = 2

local function stat(spec)
    return Widgets.alignCenter(Widgets.stack({
        Widgets.icon(spec.icon, spec.icon_size),
        Widgets.text(I18n.text(spec.label_key), { size = Layout.LABEL_FONT_SIZE, bold = true }),
        Widgets.text(spec.value, { size = Layout.SUN_VALUE_FONT_SIZE, font = Layout.HAND_FONT_FILE, bold = true }),
    }, "center"), { w = spec.width })
end

local function todayStats(context, spec)
    local today = spec.week[TODAY_INDEX] or {}
    local offset = context.model.utc_offset
    local width = math.floor(spec.width / STAT_COLUMNS)
    local icon_size = math.floor(spec.width * Layout.SUN_ICON_RATIO)
    return Widgets.row({
        stat({ icon = "sunrise", label_key = "sunrise", value = Format.clock(today.sunrise, offset),
            width = width, icon_size = icon_size }),
        stat({ icon = "sunset", label_key = "sunset", value = Format.clock(today.sunset, offset),
            width = width, icon_size = icon_size }),
        stat({ icon = "clear", label_key = "day_length", value = Format.duration(today.daylight),
            width = width, icon_size = icon_size }),
    }, "top")
end

local function daylightChange(week)
    local today, tomorrow = week[TODAY_INDEX], week[TOMORROW_INDEX]
    if not (today and tomorrow and today.daylight and tomorrow.daylight) then
        return ""
    end
    return Format.daylightChange(tomorrow.daylight - today.daylight)
end

function SunPane.content(context, box)
    local week = Forecast.week(context.model, context.now)
    local change_style = { size = Layout.DAY_CONDITION_FONT_SIZE, bold = true }
    local sun = Widgets.stack({
        todayStats(context, { week = week, width = box.w }),
        Widgets.verticalGap(Layout.ROW_GAP),
        Widgets.alignCenter(Widgets.text(daylightChange(week), change_style), { w = box.w }),
        Widgets.verticalGap(Layout.SECTION_GAP),
        Widgets.separator(box.w, Layout.LIGHT_LINE_THICKNESS),
        Widgets.verticalGap(Layout.SECTION_GAP),
    }, "left")
    local weather = SimpleWeatherPane.content(context, { w = box.w, h = box.h - sun:getSize().h })
    return Widgets.stack({ sun, weather }, "left")
end

return SunPane
