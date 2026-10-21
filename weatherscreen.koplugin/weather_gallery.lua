local Blitbuffer = require("ffi/blitbuffer")
local DataStorage = require("datastorage")
local Device = require("device")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local Orientation = require("weather_orientation")
local Panes = require("weather_panes")

local Screen = Device.screen

local Gallery = {
    DIRECTORY_NAME = "weatherscreen_gallery",
}

local ORIENTATIONS = { "portrait", "landscape_left" }

local function outputDirectory()
    local directory = DataStorage:getDataDir() .. "/" .. Gallery.DIRECTORY_NAME
    if not lfs.attributes(directory, "mode") then
        lfs.mkdir(directory)
    end
    return directory
end

local function renderToFile(view, spec)
    local widget = Panes.build(spec.pane_id, view)
    local canvas = Blitbuffer.new(Screen:getWidth(), Screen:getHeight(), Blitbuffer.TYPE_BB8)
    canvas:fill(Blitbuffer.COLOR_WHITE)
    widget:paintTo(canvas, 0, 0)
    canvas:writePNG(spec.path)
    canvas:free()
end

local function saveOne(view, spec)
    local previous_rotation = Orientation.apply(spec.orientation)
    local ok, err = pcall(renderToFile, view, spec)
    Orientation.restore(previous_rotation)
    if not ok then
        logger.warn("WeatherScreen: could not save", spec.path, err)
    end
    return ok
end

function Gallery.saveAll(view)
    local directory = outputDirectory()
    local saved = 0
    for _, pane in ipairs(Panes.LIST) do
        for _, orientation in ipairs(ORIENTATIONS) do
            local path = string.format("%s/%s_%s.png", directory, pane.id, orientation)
            if saveOne(view, { pane_id = pane.id, orientation = orientation, path = path }) then
                saved = saved + 1
            end
        end
    end
    return saved
end

return Gallery
