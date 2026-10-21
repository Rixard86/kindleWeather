local DataStorage = require("datastorage")
local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local Constants = require("weather_constants")
local Orientation = require("weather_orientation")

local Screen = Device.screen

local Preview = InputContainer:extend{
    name = "WeatherScreenPreview",
    covers_fullscreen = true,
}

function Preview:init()
    self.dimen = Geom:new{ x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight() }
    self.ges_events.Tap = { GestureRange:new{ ges = "tap", range = self.dimen } }
    if Device:hasKeys() then
        self.key_events.Close = { { Device.input.group.Back } }
    end
end

function Preview:onShow()
    UIManager:setDirty(self, "full")
    self.screenshot_task = function() self:saveScreenshot() end
    UIManager:scheduleIn(Constants.PREVIEW_SCREENSHOT_DELAY_SECONDS, self.screenshot_task)
end

function Preview:saveScreenshot()
    local path = DataStorage:getDataDir() .. "/" .. Constants.PREVIEW_SCREENSHOT_NAME
    local ok, err = pcall(function() Screen:shot(path) end)
    if not ok then
        logger.warn("WeatherScreen: could not save the preview screenshot:", err)
    end
end

function Preview:onTap()
    UIManager:close(self)
    return true
end

Preview.onClose = Preview.onTap

function Preview:onCloseWidget()
    if self.screenshot_task then
        UIManager:unschedule(self.screenshot_task)
    end
    Orientation.restore(self.previous_rotation)
    UIManager:setDirty(nil, "full")
end

return Preview
