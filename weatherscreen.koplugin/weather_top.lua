local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local Forecast = require("weather_forecast")
local Format = require("weather_format")
local I18n = require("weather_i18n")
local Layout = require("weather_layout")
local WeatherCodes = require("weather_codes")
local Widgets = require("weather_widgets")

local Screen = Device.screen

local Top = {}

local SIDES = 2
local NIGHT = 0
local FOOTER_SEPARATOR = "  ·  "
local PANEL_GAPS = 2

function Top.createContext(view)
    local width, height = Screen:getWidth(), Screen:getHeight()
    local margin = math.floor(math.min(width, height) * Layout.MARGIN_RATIO)
    return {
        model = view.model,
        news = view.news,
        national_news = view.national_news,
        place = view.place,
        now = view.now,
        landscape = width > height,
        width = width,
        margin = margin,
        content_width = width - SIDES * margin,
        content_height = height - SIDES * margin,
        icon_gap = Screen:scaleBySize(Layout.ICON_GAP),
    }
end

function Top.describe(conditions)
    return WeatherCodes.describe(conditions.code, conditions.is_day ~= NIGHT)
end

local function placeText(context, width)
    return Widgets.text(context.place, { size = Layout.PLACE_FONT_SIZE, bold = true, max_width = width })
end

local function dateText(context)
    local date = context.model and Format.date(context.now, context.model.utc_offset) or ""
    return Widgets.text(date, { size = Layout.DATE_FONT_SIZE })
end

local function header(context)
    local half = math.floor(context.content_width / SIDES)
    return Widgets.row({
        Widgets.alignLeft(placeText(context, half), { w = half }),
        Widgets.alignRight(dateText(context), { w = context.content_width - half }),
    })
end

local function labelledValue(entry, align)
    return Widgets.stack({
        Widgets.text(entry.label, { size = Layout.LABEL_FONT_SIZE, bold = true }),
        Widgets.text(entry.value, { size = Layout.VALUE_FONT_SIZE, bold = true }),
    }, align)
end

local function conditionAndTemperature(conditions, width)
    return Widgets.stack({
        Widgets.paragraph(Top.describe(conditions).label, {
            size = Layout.CURRENT_CONDITION_FONT_SIZE,
            font = Layout.HAND_FONT_FILE,
            width = width,
        }),
        Widgets.text(Format.temperature(conditions.temperature),
            { size = Layout.CURRENT_TEMPERATURE_FONT_SIZE, font = Layout.HAND_FONT_FILE, bold = true }),
    }, "left")
end

local function feelsLike(conditions)
    return { label = I18n.text("feels_like"), value = Format.temperature(conditions.feels_like) }
end

local function humidity(conditions)
    return { label = I18n.text("humidity"), value = Format.percent(conditions.humidity) }
end

local function currentBlock(context)
    local conditions = Forecast.currentConditions(context.model, context.now)
    local icon_size = math.floor(context.width * Layout.CURRENT_ICON_RATIO)
    local side_width = math.floor(context.content_width * Layout.CURRENT_SIDE_RATIO)
    local main_width = context.content_width - icon_size - context.icon_gap - side_width
    local side = Widgets.stack({
        labelledValue(feelsLike(conditions), "right"),
        Widgets.verticalGap(Layout.ROW_GAP),
        labelledValue(humidity(conditions), "right"),
    }, "right")
    return Widgets.row({
        Widgets.icon(Top.describe(conditions).icon, icon_size),
        Widgets.horizontalGap(context.icon_gap),
        Widgets.alignLeft(conditionAndTemperature(conditions, main_width), { w = main_width }),
        Widgets.alignRight(side, { w = side_width }),
    })
end

function Top.section(context)
    return Widgets.stack({
        header(context),
        Widgets.verticalGap(Layout.SECTION_GAP),
        currentBlock(context),
        Widgets.verticalGap(Layout.SECTION_GAP),
        Widgets.separator(context.content_width, Layout.HEAVY_LINE_THICKNESS),
        Widgets.verticalGap(Layout.SECTION_GAP),
    }, "left")
end

local function panelReading(conditions, width)
    return Widgets.stack({
        Widgets.paragraph(Top.describe(conditions).label, {
            size = Layout.PANEL_CONDITION_FONT_SIZE,
            font = Layout.HAND_FONT_FILE,
            width = width,
            align = "center",
        }),
        Widgets.text(Format.temperature(conditions.temperature),
            { size = Layout.PANEL_TEMPERATURE_FONT_SIZE, font = Layout.HAND_FONT_FILE, bold = true }),
    }, "center")
end

local function panelStats(conditions, width)
    local half = math.floor(width / SIDES)
    return Widgets.stack({
        Widgets.separator(width, Layout.LIGHT_LINE_THICKNESS),
        Widgets.verticalGap(Layout.SECTION_GAP),
        Widgets.row({
            Widgets.alignCenter(labelledValue(feelsLike(conditions), "center"), { w = half }),
            Widgets.alignCenter(labelledValue(humidity(conditions), "center"), { w = width - half }),
        }, "top"),
    }, "left")
end

function Top.sidePanel(context, box)
    local conditions = Forecast.currentConditions(context.model, context.now)
    local heading = Widgets.stack({ placeText(context, box.w), dateText(context) }, "center")
    local reading = panelReading(conditions, box.w)
    local stats = panelStats(conditions, box.w)
    local gap_height = Widgets.verticalGap(Layout.SECTION_GAP):getSize().h
    local free_height = box.h - Top.totalHeight({ heading, reading, stats }) - PANEL_GAPS * gap_height
    local icon_size = math.max(0, math.min(math.floor(box.w * Layout.PANEL_ICON_RATIO), free_height))
    return Widgets.stack({
        Widgets.alignCenter(heading, { w = box.w }),
        Widgets.verticalGap(Layout.SECTION_GAP),
        Widgets.alignCenter(Widgets.icon(Top.describe(conditions).icon, icon_size), { w = box.w }),
        Widgets.alignCenter(reading, { w = box.w }),
        Widgets.verticalFill(math.max(free_height - icon_size, 0)),
        Widgets.verticalGap(Layout.SECTION_GAP),
        stats,
    }, "left")
end

function Top.footer(context, attribution)
    local model = context.model
    local updated = Format.clock(model.fetched_at, model.utc_offset)
    if Format.dayKey(model.fetched_at, model.utc_offset) ~= Format.dayKey(context.now, model.utc_offset) then
        updated = Format.weekday(model.fetched_at, model.utc_offset) .. " " .. updated
    end
    local text = string.format(I18n.text("updated"), updated) .. FOOTER_SEPARATOR .. attribution
    return Widgets.text(text, { size = Layout.FOOTER_FONT_SIZE, max_width = context.content_width })
end

function Top.totalHeight(widgets)
    local total = 0
    for _, widget in ipairs(widgets) do
        total = total + widget:getSize().h
    end
    return total
end

function Top.remainingHeight(context, widgets)
    return context.content_height - Top.totalHeight(widgets)
end

local function frame(context, body)
    return FrameContainer:new{
        bordersize = 0,
        margin = 0,
        padding = context.margin,
        background = Blitbuffer.COLOR_WHITE,
        Widgets.alignLeft(body, { w = context.content_width, h = context.content_height }),
    }
end

function Top.page(context, parts)
    local filler = math.max(Top.remainingHeight(context, { parts.body, parts.footer }), 0)
    return frame(context, Widgets.stack({ parts.body, Widgets.verticalFill(filler), parts.footer }, "left"))
end

function Top.emptyPage(context)
    return frame(context, Widgets.stack({
        header(context),
        Widgets.verticalGap(Layout.SECTION_GAP),
        Widgets.paragraph(I18n.text("no_forecast"), { size = Layout.MESSAGE_FONT_SIZE, width = context.content_width }),
    }, "left"))
end

return Top
