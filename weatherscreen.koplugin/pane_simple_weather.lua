local Device = require("device")
local Constants = require("weather_constants")
local Forecast = require("weather_forecast")
local Format = require("weather_format")
local I18n = require("weather_i18n")
local Layout = require("weather_layout")
local Top = require("weather_top")
local Widgets = require("weather_widgets")

local Screen = Device.screen

local SimpleWeatherPane = {}

local TEMPERATURE_COLUMNS = 2
local ROW_PADDING_SIDES = 2
local MINIMUM_DAYS = 1
local RELATIVE_DAY_KEYS = { "today", "tomorrow" }

local function weekMetrics(context, width)
    local metrics = {
        model = context.model,
        icon_gap = context.icon_gap,
        width = width,
        label_width = math.floor(width * Layout.DAY_LABEL_RATIO),
        day_icon_size = math.floor(width * Layout.DAY_ICON_RATIO),
        temperature_width = math.floor(width * Layout.DAY_TEMPERATURE_RATIO),
    }
    metrics.day_text_width = width - metrics.label_width - metrics.day_icon_size
        - metrics.icon_gap - TEMPERATURE_COLUMNS * metrics.temperature_width
    return metrics
end

local function columnLabel(metrics, label)
    local style = { size = Layout.LABEL_FONT_SIZE, bold = true }
    return Widgets.alignRight(Widgets.text(label, style), { w = metrics.temperature_width })
end

local function weekHeader(metrics, title_key)
    local title_width = metrics.width - TEMPERATURE_COLUMNS * metrics.temperature_width
    local title_style = { size = Layout.LABEL_FONT_SIZE, bold = true }
    return Widgets.row({
        Widgets.alignLeft(Widgets.text(I18n.text(title_key), title_style), { w = title_width }),
        columnLabel(metrics, I18n.text("low")),
        columnLabel(metrics, I18n.text("high")),
    })
end

local function dayLabel(metrics, entry)
    local relative_key = RELATIVE_DAY_KEYS[entry.index]
    local text = relative_key and I18n.text(relative_key)
        or Format.weekdayAndDay(entry.day.time, metrics.model.utc_offset)
    local style = {
        size = Layout.DAY_LABEL_FONT_SIZE,
        bold = true,
        max_width = metrics.label_width,
    }
    return Widgets.alignLeft(Widgets.text(text, style), { w = metrics.label_width })
end

local function dayDescription(metrics, day)
    local details = string.format(I18n.text("day_details"),
        Format.percent(day.rain_chance), Format.wholeNumber(day.uv_index))
    local condition_style = { size = Layout.DAY_CONDITION_FONT_SIZE, max_width = metrics.day_text_width }
    return Widgets.alignLeft(Widgets.stack({
        Widgets.text(Top.describe(day).label, condition_style),
        Widgets.text(details, {
            size = Layout.DAY_DETAIL_FONT_SIZE,
            max_width = metrics.day_text_width,
        }),
    }, "left"), { w = metrics.day_text_width })
end

local function temperatureCell(metrics, value)
    local style = { size = Layout.DAY_TEMPERATURE_FONT_SIZE, bold = value.bold }
    return Widgets.alignRight(Widgets.text(value.text, style), { w = metrics.temperature_width })
end

local function dayRow(metrics, entry)
    local day = entry.day
    return Widgets.row({
        dayLabel(metrics, entry),
        Widgets.icon(Top.describe(day).icon, metrics.day_icon_size),
        Widgets.horizontalGap(metrics.icon_gap),
        dayDescription(metrics, day),
        temperatureCell(metrics, { text = Format.temperature(day.low) }),
        temperatureCell(metrics, { text = Format.temperature(day.high), bold = true }),
    })
end

local function visibleDayCount(metrics, height)
    local line_height = Screen:scaleBySize(Layout.LIGHT_LINE_THICKNESS)
    local minimum_row = metrics.day_icon_size + ROW_PADDING_SIDES * Screen:scaleBySize(Layout.ROW_GAP) + line_height
    return math.max(MINIMUM_DAYS, math.min(Constants.WEEK_LENGTH_DAYS, math.floor(height / minimum_row)))
end

local function weekList(context, spec)
    local line_height = Screen:scaleBySize(Layout.LIGHT_LINE_THICKNESS)
    local row_height = math.floor(spec.height / spec.count) - line_height
    local rows = {}
    for index, day in ipairs(Forecast.week(context.model, context.now)) do
        if index > spec.count then
            break
        end
        local row = dayRow(spec.metrics, { index = index, day = day })
        rows[#rows + 1] = Widgets.alignLeft(row, { w = spec.metrics.width, h = row_height })
        rows[#rows + 1] = Widgets.separator(spec.metrics.width, Layout.LIGHT_LINE_THICKNESS)
    end
    return Widgets.stack(rows, "left")
end

function SimpleWeatherPane.content(context, box)
    local metrics = weekMetrics(context, box.w)
    local list_height = box.h - weekHeader(metrics, "this_week"):getSize().h
    local count = visibleDayCount(metrics, list_height)
    local title_key = count < Constants.WEEK_LENGTH_DAYS and "coming_days" or "this_week"
    local week = weekList(context, { metrics = metrics, height = list_height, count = count })
    return Widgets.stack({ weekHeader(metrics, title_key), week }, "left")
end

return SimpleWeatherPane
