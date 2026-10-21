local Device = require("device")
local Constants = require("weather_constants")

local Screen = Device.screen

local Orientation = {
    CHOICES = { "portrait", "landscape_left", "landscape_right" },
}

local ROTATIONS = {
    portrait = Screen.DEVICE_ROTATED_UPRIGHT,
    landscape_left = Screen.DEVICE_ROTATED_CLOCKWISE,
    landscape_right = Screen.DEVICE_ROTATED_COUNTER_CLOCKWISE,
}

function Orientation.apply(choice)
    local wanted = ROTATIONS[choice] or ROTATIONS[Constants.DEFAULT_ORIENTATION]
    local current = Screen:getRotationMode()
    if wanted == current then
        return nil
    end
    Screen:setRotationMode(wanted)
    return current
end

function Orientation.restore(previous)
    if previous then
        Screen:setRotationMode(previous)
    end
end

return Orientation
