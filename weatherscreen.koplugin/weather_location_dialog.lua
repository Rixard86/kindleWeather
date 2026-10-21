local InputDialog = require("ui/widget/inputdialog")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local T = require("ffi/util").template
local Api = require("weather_api")
local I18n = require("weather_i18n")
local Location = require("weather_location")

local LocationDialog = {}

local function search(plugin, query)
    NetworkMgr:runWhenOnline(function()
        local location = Api.findLocation(query)
        if not location then
            return plugin:notify(T(I18n.text("place_not_found"), query))
        end
        plugin:saveSetting("location", location)
        plugin:clearDownloads()
        plugin:downloadAll()
        plugin:notify(T(I18n.text("location_set"), Location.label(location)))
    end)
end

function LocationDialog.show(plugin)
    local dialog
    dialog = InputDialog:new{
        title = I18n.text("location_title"),
        input = plugin:getLocation().name,
        input_hint = I18n.text("location_hint"),
        buttons = { {
            { text = I18n.text("cancel"), id = "close", callback = function() UIManager:close(dialog) end },
            {
                text = I18n.text("search"),
                is_enter_default = true,
                callback = function()
                    local query = dialog:getInputText()
                    UIManager:close(dialog)
                    search(plugin, query)
                end,
            },
        } },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

return LocationDialog
