local Constants = require("weather_constants")
local Format = require("weather_format")
local I18n = require("weather_i18n")
local Layout = require("weather_layout")
local Widgets = require("weather_widgets")

local NewsWidgets = {}

local META_SEPARATOR = "  ·  "

local function publishedLabel(context, published)
    local offset = context.model.utc_offset
    local clock = Format.clock(published, offset)
    local day = Format.dayKey(published, offset)
    if day == Format.dayKey(context.now, offset) then
        return clock
    end
    if day == Format.dayKey(context.now - Constants.SECONDS_PER_DAY, offset) then
        return I18n.text("yesterday") .. " " .. clock
    end
    return Format.weekday(published, offset) .. " " .. clock
end

local function metaLine(context, item)
    local parts = {}
    if item.source then
        parts[#parts + 1] = item.source
    end
    if item.published then
        parts[#parts + 1] = publishedLabel(context, item.published)
    end
    return table.concat(parts, META_SEPARATOR)
end

local function newsItem(context, entry)
    return Widgets.stack({
        Widgets.paragraph(entry.item.title, { size = entry.headline_size, bold = true, width = entry.width }),
        Widgets.verticalGap(Layout.NEWS_META_GAP),
        Widgets.text(metaLine(context, entry.item), { size = Layout.NEWS_META_FONT_SIZE, max_width = entry.width }),
        Widgets.verticalGap(Layout.NEWS_ITEM_GAP),
        Widgets.separator(entry.width, Layout.LIGHT_LINE_THICKNESS),
        Widgets.verticalGap(Layout.NEWS_ITEM_GAP),
    }, "left")
end

local function fittingItems(context, spec)
    local entries = {}
    local used_height = 0
    for _, item in ipairs(spec.news.items) do
        local entry = newsItem(context, { item = item, width = spec.box.w, headline_size = spec.headline_size })
        local height = entry:getSize().h
        if used_height + height > spec.box.h then
            break
        end
        entries[#entries + 1] = entry
        used_height = used_height + height
    end
    return Widgets.stack(entries, "left")
end

function NewsWidgets.column(context, spec)
    local title = Widgets.text(I18n.text(spec.title_key), { size = Layout.LABEL_FONT_SIZE, bold = true })
    local gap = Widgets.verticalGap(Layout.ROW_GAP)
    local list_box = { w = spec.box.w, h = spec.box.h - title:getSize().h - gap:getSize().h }
    local list
    if spec.news and #spec.news.items > 0 then
        list = fittingItems(context, { news = spec.news, box = list_box, headline_size = spec.headline_size })
    else
        list = Widgets.paragraph(I18n.text("no_news"), { size = Layout.MESSAGE_FONT_SIZE, width = spec.box.w })
    end
    return Widgets.stack({ title, gap, list }, "left")
end

return NewsWidgets
