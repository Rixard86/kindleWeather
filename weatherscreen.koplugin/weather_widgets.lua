local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FontList = require("fontlist")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local LeftContainer = require("ui/widget/container/leftcontainer")
local LineWidget = require("ui/widget/linewidget")
local RightContainer = require("ui/widget/container/rightcontainer")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local ffiUtil = require("ffi/util")
local Layout = require("weather_layout")

local Screen = Device.screen

local DIRECTORY_LEVEL_PATTERN = "/[^/]+"
local PARENT_DIRECTORY = "../"

local Widgets = {
    icon_dir = "",
    font_dir = nil,
}

local function pathToRoot(directory)
    local _, depth = directory:gsub(DIRECTORY_LEVEL_PATTERN, "")
    return string.rep(PARENT_DIRECTORY, depth)
end

function Widgets.useFontsFrom(plugin_path)
    local font_root = ffiUtil.realpath(FontList.fontdir)
    local plugin_root = ffiUtil.realpath(plugin_path)
    if font_root and plugin_root then
        Widgets.font_dir = pathToRoot(font_root) .. plugin_root:gsub("^/", "") .. "/fonts/"
    end
end

local function face(style)
    local custom_face = style.font and Widgets.font_dir and Font:getFace(Widgets.font_dir .. style.font, style.size)
    return custom_face or Font:getFace(Layout.FONT_NAME, style.size)
end

local function boxFor(widget, box)
    return Geom:new{ w = box.w, h = box.h or widget:getSize().h }
end

function Widgets.text(content, style)
    return TextWidget:new{
        text = content,
        face = face(style),
        bold = style.bold,
        fgcolor = Blitbuffer.COLOR_BLACK,
        max_width = style.max_width,
    }
end

function Widgets.paragraph(content, style)
    return TextBoxWidget:new{
        text = content,
        face = face(style),
        width = style.width,
        bold = style.bold,
        alignment = style.align,
        fgcolor = Blitbuffer.COLOR_BLACK,
    }
end

function Widgets.image(file, size)
    return ImageWidget:new{
        file = file,
        width = size,
        height = size,
        alpha = true,
    }
end

function Widgets.icon(name, size)
    return Widgets.image(Widgets.icon_dir .. name .. ".svg", size)
end

function Widgets.verticalGap(size)
    return VerticalSpan:new{ width = Screen:scaleBySize(size) }
end

function Widgets.verticalFill(pixels)
    return VerticalSpan:new{ width = pixels }
end

function Widgets.horizontalGap(pixels)
    return HorizontalSpan:new{ width = pixels }
end

function Widgets.separator(width, thickness)
    return LineWidget:new{
        dimen = Geom:new{ w = width, h = Screen:scaleBySize(thickness) },
        background = thickness == Layout.HEAVY_LINE_THICKNESS and Blitbuffer.COLOR_BLACK
            or Blitbuffer.COLOR_GRAY_5,
    }
end

function Widgets.alignLeft(widget, box)
    return LeftContainer:new{ dimen = boxFor(widget, box), widget }
end

function Widgets.alignCenter(widget, box)
    return CenterContainer:new{ dimen = boxFor(widget, box), widget }
end

function Widgets.alignRight(widget, box)
    return RightContainer:new{ dimen = boxFor(widget, box), widget }
end

function Widgets.stack(children, align)
    local group = VerticalGroup:new{ align = align }
    for _, child in ipairs(children) do
        group[#group + 1] = child
    end
    return group
end

function Widgets.verticalLine(height, thickness)
    return LineWidget:new{
        dimen = Geom:new{ w = Screen:scaleBySize(thickness), h = height },
        background = Blitbuffer.COLOR_GRAY_5,
    }
end

function Widgets.row(children, align)
    local group = HorizontalGroup:new{ align = align or "center" }
    for _, child in ipairs(children) do
        group[#group + 1] = child
    end
    return group
end

return Widgets
