local SpinWidget = require("ui/widget/spinwidget")
local UIManager = require("ui/uimanager")
local T = require("ffi/util").template
local Format = require("weather_format")
local I18n = require("weather_i18n")

local NightMenu = {}

local FIRST_HOUR = 0
local LAST_HOUR = 23
local HOUR_STEP = 1
local HOUR_HOLD_STEP = 3
local TITLE_KEYS = { start_hour = "night_start_title", end_hour = "night_end_title" }
local ITEM_KEYS = { start_hour = "night_start", end_hour = "night_end" }

local function withChanges(plugin, changes)
    local night = plugin:getNightMode()
    local updated = { enabled = night.enabled, start_hour = night.start_hour, end_hour = night.end_hour }
    for key, value in pairs(changes) do
        updated[key] = value
    end
    return updated
end

local function nightLabel(plugin)
    local night = plugin:getNightMode()
    local state = I18n.text("off")
    if night.enabled then
        state = T(I18n.text("night_hours"), Format.hourOfDay(night.start_hour), Format.hourOfDay(night.end_hour))
    end
    return T(I18n.text("night_item"), state)
end

local function showHourPicker(plugin, spec)
    UIManager:show(SpinWidget:new{
        title_text = I18n.text(TITLE_KEYS[spec.key]),
        value = plugin:getNightMode()[spec.key],
        value_min = FIRST_HOUR,
        value_max = LAST_HOUR,
        value_step = HOUR_STEP,
        value_hold_step = HOUR_HOLD_STEP,
        wrap = true,
        ok_text = I18n.text("apply"),
        cancel_text = I18n.text("cancel"),
        callback = function(spin)
            plugin:setNightMode(withChanges(plugin, { [spec.key] = spin.value }))
            if spec.menu then
                spec.menu:updateItems()
            end
        end,
    })
end

local function hourItem(plugin, key)
    return {
        text_func = function() return T(I18n.text(ITEM_KEYS[key]), Format.hourOfDay(plugin:getNightMode()[key])) end,
        enabled_func = function() return plugin:getNightMode().enabled end,
        keep_menu_open = true,
        callback = function(touchmenu_instance)
            showHourPicker(plugin, { key = key, menu = touchmenu_instance })
        end,
    }
end

function NightMenu.item(plugin)
    return {
        text_func = function() return nightLabel(plugin) end,
        sub_item_table = {
            {
                text_func = function() return I18n.text("night_enable") end,
                checked_func = function() return plugin:getNightMode().enabled end,
                callback = function()
                    plugin:setNightMode(withChanges(plugin, { enabled = not plugin:getNightMode().enabled }))
                end,
            },
            hourItem(plugin, "start_hour"),
            hourItem(plugin, "end_hour"),
        },
    }
end

return NightMenu
