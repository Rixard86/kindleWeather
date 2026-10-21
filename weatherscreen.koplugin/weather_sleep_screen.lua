local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local ScreenSaverWidget = require("ui/widget/screensaverwidget")
local Screensaver = require("ui/screensaver")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local Orientation = require("weather_orientation")

local original_show = Screensaver.show

local SleepScreen = {}

local provider
local screen_holder

local function showProvidedScreen(screensaver)
    Device.screen_saver_mode = true
    local previous_rotation = Orientation.apply(provider.orientation())
    if previous_rotation then
        Device.orig_rotation_mode = previous_rotation
    end
    screen_holder = FrameContainer:new{
        bordersize = 0,
        padding = 0,
        margin = 0,
        provider.build(),
    }
    screensaver.screensaver_widget = ScreenSaverWidget:new{
        widget = screen_holder,
        background = Blitbuffer.COLOR_WHITE,
        covers_fullscreen = true,
    }
    screensaver.screensaver_widget.modal = true
    UIManager:show(screensaver.screensaver_widget, "full")
end

local function takesOver(screensaver)
    return provider ~= nil and provider.isEnabled()
        and screensaver.ui ~= nil and screensaver.prefix == ""
end

local function show(screensaver)
    if not takesOver(screensaver) then
        return original_show(screensaver)
    end
    local ok, err = pcall(showProvidedScreen, screensaver)
    if not ok then
        logger.warn("WeatherScreen: using the default sleep screen:", err)
        Orientation.restore(Device.orig_rotation_mode)
        Device.orig_rotation_mode = nil
        return original_show(screensaver)
    end
end

function SleepScreen.install(new_provider)
    provider = new_provider
    Screensaver.show = show
end

function SleepScreen.redraw()
    local widget = Screensaver.screensaver_widget
    if not (provider and screen_holder and widget and widget.widget == screen_holder) then
        return
    end
    screen_holder[1] = provider.build()
    UIManager:setDirty(widget, "full")
end

return SleepScreen
