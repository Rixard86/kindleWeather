local Device = require("device")
local Format = require("weather_format")
local I18n = require("weather_i18n")
local Layout = require("weather_layout")
local MoonIcons = require("moon_icons")
local MoonPhase = require("moon_phase")
local Widgets = require("weather_widgets")

local Screen = Device.screen

local MoonPane = {}

local UPCOMING_COUNT = 4
local PERCENT = 100
local LOOKAHEAD_EVENTS = 4
local PHASE_FRACTIONS = { new_moon = 0, first_quarter = 0.25, full_moon = 0.5, last_quarter = 0.75 }

local function nextFullMoon(now)
    for _, event in ipairs(MoonPhase.upcoming(now, LOOKAHEAD_EVENTS)) do
        if event.key == "full_moon" then
            return event
        end
    end
end

local function labelledValue(entry, width)
    return Widgets.stack({
        Widgets.text(I18n.text(entry.label_key), { size = Layout.LABEL_FONT_SIZE, bold = true, max_width = width }),
        Widgets.text(entry.value, { size = Layout.VALUE_FONT_SIZE, bold = true, max_width = width }),
    }, "left")
end

local function summary(context, width)
    local full_moon = nextFullMoon(context.now)
    return Widgets.stack({
        Widgets.paragraph(I18n.text(MoonPhase.name(context.now)), {
            size = Layout.CURRENT_CONDITION_FONT_SIZE,
            font = Layout.HAND_FONT_FILE,
            width = width,
        }),
        Widgets.verticalGap(Layout.SECTION_GAP),
        labelledValue({ label_key = "illuminated", value = Format.percent(MoonPhase.illumination(context.now)
            * PERCENT) }, width),
        Widgets.verticalGap(Layout.ROW_GAP),
        labelledValue({ label_key = "next_full_moon", value = Format.daysUntil(full_moon.time - context.now) }, width),
        Widgets.text(Format.date(full_moon.time, context.model.utc_offset),
            { size = Layout.DAY_TEMPERATURE_FONT_SIZE, max_width = width }),
    }, "left")
end

local function phaseRow(context, spec)
    local icon_size = math.floor(spec.width * Layout.MOON_ROW_ICON_RATIO)
    local name_width = math.floor(spec.width * Layout.MOON_NAME_RATIO)
    local date_width = spec.width - icon_size - context.icon_gap - name_width
    local date = Format.date(spec.event.time, context.model.utc_offset)
    return Widgets.row({
        Widgets.image(MoonIcons.path(PHASE_FRACTIONS[spec.event.key]), icon_size),
        Widgets.horizontalGap(context.icon_gap),
        Widgets.alignLeft(Widgets.text(I18n.text(spec.event.key), { size = Layout.DAY_LABEL_FONT_SIZE, bold = true }),
            { w = name_width }),
        Widgets.alignRight(Widgets.text(date, { size = Layout.DAY_TEMPERATURE_FONT_SIZE }), { w = date_width }),
    })
end

local function upcomingList(context, spec)
    local line_height = Screen:scaleBySize(Layout.LIGHT_LINE_THICKNESS)
    local row_height = math.floor(spec.height / UPCOMING_COUNT) - line_height
    local rows = {}
    for _, event in ipairs(MoonPhase.upcoming(context.now, UPCOMING_COUNT)) do
        local row = phaseRow(context, { event = event, width = spec.width })
        rows[#rows + 1] = Widgets.alignLeft(row, { w = spec.width, h = row_height })
        rows[#rows + 1] = Widgets.separator(spec.width, Layout.LIGHT_LINE_THICKNESS)
    end
    return Widgets.stack(rows, "left")
end

function MoonPane.content(context, box)
    local picture_size = math.floor(box.w * Layout.MOON_PICTURE_RATIO)
    local summary_width = box.w - picture_size - context.icon_gap
    local picture = Widgets.image(MoonIcons.path(MoonPhase.cycleFraction(context.now)), picture_size)
    local top = Widgets.stack({
        Widgets.row({
            picture,
            Widgets.horizontalGap(context.icon_gap),
            Widgets.alignLeft(summary(context, summary_width), { w = summary_width }),
        }),
        Widgets.verticalGap(Layout.SECTION_GAP),
        Widgets.text(I18n.text("upcoming_phases"), { size = Layout.LABEL_FONT_SIZE, bold = true }),
    }, "left")
    local list = upcomingList(context, { width = box.w, height = box.h - top:getSize().h })
    return Widgets.stack({ top, list }, "left")
end

return MoonPane
