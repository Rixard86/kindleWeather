local Device = require("device")
local Constants = require("weather_constants")
local I18n = require("weather_i18n")
local Layout = require("weather_layout")
local Top = require("weather_top")
local Widgets = require("weather_widgets")

local Screen = Device.screen

local Page = {}

local GAPS_AROUND_DIVIDER = 2
local CREDIT_SEPARATOR = "  ·  "

local function credits(context, pane)
    local text = I18n.text("credit_" .. (context.model.source or Constants.SOURCE_OPEN_METEO))
    if pane.EXTRA_CREDIT_KEY then
        text = text .. CREDIT_SEPARATOR .. I18n.text(pane.EXTRA_CREDIT_KEY)
    end
    return text
end

local function portrait(context, pane)
    local top = Top.section(context)
    local footer = Top.footer(context, credits(context, pane))
    local box = { w = context.content_width, h = Top.remainingHeight(context, { top, footer }) }
    local body = Widgets.stack({ top, pane.content(context, box) }, "left")
    return Top.page(context, { body = body, footer = footer })
end

local function landscape(context, pane)
    local footer = Top.footer(context, credits(context, pane))
    local body_height = Top.remainingHeight(context, { footer }) - Screen:scaleBySize(Layout.SECTION_GAP)
    local panel_width = math.floor(context.content_width * Layout.SIDE_PANEL_RATIO)
    local gap = Screen:scaleBySize(Layout.COLUMN_GAP)
    local divider = Widgets.verticalLine(body_height, Layout.LIGHT_LINE_THICKNESS)
    local box = {
        w = context.content_width - panel_width - GAPS_AROUND_DIVIDER * gap - divider:getSize().w,
        h = body_height,
    }
    local body = Widgets.row({
        Widgets.alignLeft(Top.sidePanel(context, { w = panel_width, h = body_height }), { w = panel_width }),
        Widgets.horizontalGap(gap),
        divider,
        Widgets.horizontalGap(gap),
        pane.content(context, box),
    }, "top")
    return Top.page(context, { body = body, footer = footer })
end

function Page.build(view, pane)
    local context = Top.createContext(view)
    if not context.model then
        return Top.emptyPage(context)
    end
    if context.landscape then
        return landscape(context, pane)
    end
    return portrait(context, pane)
end

return Page
