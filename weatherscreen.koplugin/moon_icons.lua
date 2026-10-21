local DataStorage = require("datastorage")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local MoonDrawing = require("moon_drawing")

local MoonIcons = {}

local STEPS = 100
local ROUNDING_OFFSET = 0.5

local function cacheDirectory()
    local directory = DataStorage:getDataDir() .. "/cache/weatherscreen"
    if not lfs.attributes(directory, "mode") then
        lfs.mkdir(directory)
    end
    return directory
end

function MoonIcons.path(fraction)
    local step = math.floor(fraction * STEPS + ROUNDING_OFFSET) % STEPS
    local path = string.format("%s/moon_%02d.svg", cacheDirectory(), step)
    if not lfs.attributes(path, "mode") then
        local file, err = io.open(path, "w")
        if not file then
            logger.warn("WeatherScreen: could not write moon picture:", err)
            return path
        end
        file:write(MoonDrawing.svg(step / STEPS))
        file:close()
    end
    return path
end

return MoonIcons
