local T = require("ffi/util").template
local Constants = require("weather_constants")
local I18n = require("weather_i18n")
local Location = require("weather_location")
local NightMenu = require("weather_night_menu")
local Orientation = require("weather_orientation")
local Panes = require("weather_panes")

local Menu = {}

local function textOf(key)
    return function() return I18n.text(key) end
end

local function intervalItems(plugin)
    local items = {}
    local choices = Constants.INTERVAL_CHOICES_HOURS
    for index = 1, #choices do
        local hours = choices[index]
        items[#items + 1] = {
            text_func = function() return T(I18n.text("interval_choice"), hours) end,
            radio = true,
            checked_func = function() return plugin:getIntervalHours() == hours end,
            callback = function() plugin:setIntervalHours(hours) end,
        }
    end
    return items
end

local function paneItems(plugin)
    local items = {}
    for index = 1, #Panes.LIST do
        local pane = Panes.LIST[index]
        items[#items + 1] = {
            text_func = textOf(pane.name_key),
            radio = true,
            checked_func = function() return plugin:getPaneId() == pane.id end,
            callback = function() plugin:setPane(pane.id) end,
        }
    end
    return items
end

local function paneLabel(plugin)
    return T(I18n.text("pane_item"), I18n.text(Panes.find(plugin:getPaneId()).name_key))
end

local SOURCE_NAMES = { smhi = "SMHI", open_meteo = "Open-Meteo" }

local function sourceItems(plugin)
    local items = {}
    for index = 1, #Constants.SOURCE_CHOICES do
        local source = Constants.SOURCE_CHOICES[index]
        items[#items + 1] = {
            text = SOURCE_NAMES[source],
            radio = true,
            checked_func = function() return plugin:getSource() == source end,
            callback = function() plugin:setSource(source) end,
        }
    end
    return items
end

local function orientationItems(plugin)
    local items = {}
    for index = 1, #Orientation.CHOICES do
        local choice = Orientation.CHOICES[index]
        items[#items + 1] = {
            text_func = textOf(choice),
            radio = true,
            checked_func = function() return plugin:getOrientation() == choice end,
            callback = function() plugin:setOrientation(choice) end,
        }
    end
    return items
end

local function languageItems(plugin)
    local items = {}
    local codes = I18n.LANGUAGE_CODES
    for index = 1, #codes do
        local code = codes[index]
        items[#items + 1] = {
            text = I18n.languageName(code),
            radio = true,
            checked_func = function() return I18n.language() == code end,
            callback = function() plugin:setLanguage(code) end,
        }
    end
    return items
end

function Menu.build(plugin)
    return {
        text_func = textOf("menu_title"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text_func = textOf("show_when_sleeping"),
                checked_func = function() return plugin:isEnabled() end,
                callback = function() plugin:toggleEnabled() end,
            },
            { text_func = function() return paneLabel(plugin) end, sub_item_table = paneItems(plugin) },
            {
                text_func = function() return T(I18n.text("orientation_item"), I18n.text(plugin:getOrientation())) end,
                sub_item_table = orientationItems(plugin),
            },
            { text_func = textOf("preview"), callback = function() plugin:showPreview() end },
            {
                text_func = textOf("save_gallery"),
                keep_menu_open = true,
                callback = function() plugin:saveGallery() end,
            },
            { text_func = textOf("refresh_now"), keep_menu_open = true, callback = function() plugin:refreshNow() end },
            {
                text_func = function() return T(I18n.text("location_item"), Location.label(plugin:getLocation())) end,
                keep_menu_open = true,
                callback = function() plugin:changeLocation() end,
            },
            {
                text_func = function() return T(I18n.text("source_item"), SOURCE_NAMES[plugin:getSource()]) end,
                sub_item_table = sourceItems(plugin),
            },
            {
                text_func = function() return T(I18n.text("interval_item"), plugin:getIntervalHours()) end,
                sub_item_table = intervalItems(plugin),
            },
            NightMenu.item(plugin),
            {
                text_func = function() return T(I18n.text("language_item"), I18n.languageName(I18n.language())) end,
                sub_item_table = languageItems(plugin),
            },
        },
    }
end

return Menu
