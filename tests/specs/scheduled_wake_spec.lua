local expect = require("spec_helper")

local pending_actions = {}

local function stub(name, module)
    package.preload[name] = function() return module end
end

local function runPendingActions()
    while #pending_actions > 0 do
        table.remove(pending_actions, 1)()
    end
end

local wakeup_mgr = { tasks = {} }

function wakeup_mgr:addTask(seconds_from_now, callback)
    table.insert(self.tasks, { epoch = os.time() + seconds_from_now, callback = callback })
    table.sort(self.tasks, function(first, second) return first.epoch < second.epoch end)
end

function wakeup_mgr:removeTasks(_, callback)
    for index = #self.tasks, 1, -1 do
        if self.tasks[index].callback == callback then
            table.remove(self.tasks, index)
        end
    end
end

function wakeup_mgr:wakeupAction()
    self.tasks[1].callback()
    table.remove(self.tasks, 1)
end

local function memorySettings()
    local values = {}
    return {
        readSetting = function(_, key, default)
            if values[key] == nil then return default end
            return values[key]
        end,
        saveSetting = function(_, key, value) values[key] = value end,
        delSetting = function(_, key) values[key] = nil end,
        nilOrTrue = function(_, key) return values[key] ~= false end,
        flush = function() end,
    }
end

local UIManager = {}

function UIManager:scheduleIn(_, action)
    table.insert(pending_actions, action)
end

function UIManager:nextTick(action)
    table.insert(pending_actions, action)
end

local function ignore() end

stub("datastorage", { getSettingsDir = function() return "settings" end })
stub("device", { wakeup_mgr = wakeup_mgr })
stub("luasettings", { open = function() return memorySettings() end })
stub("ui/uimanager", UIManager)
stub("ui/widget/container/widgetcontainer", { extend = function(_, class) return class end })
stub("logger", { info = ignore, warn = ignore, dbg = ignore })
stub("ffi/util", { template = function(text) return text end })
stub("weather_sleep_screen", { install = ignore })
stub("weather_widgets", { useFontsFrom = ignore })
stub("weather_wifi", {
    isRadioOn = function() return true end,
    connect = function(on_done) on_done(true) end,
})
stub("weather_downloads", {
    run = function(plugin)
        plugin:saveSetting("forecast", { fetched_at = os.time() })
        return true
    end,
})
for _, name in ipairs({ "ui/widget/infomessage", "ui/network/manager", "weather_gallery",
        "weather_location_dialog", "weather_menu", "weather_orientation", "weather_panes", "weather_preview" }) do
    stub(name, {})
end

local WeatherScreen = require("main")

local function startedPlugin()
    local plugin = setmetatable({
        path = "plugin",
        ui = { menu = { registerToMainMenu = ignore } },
    }, { __index = WeatherScreen })
    plugin:init()
    return plugin
end

return {
    ["keeps the next wake when the refresh finishes during the wakeup"] = function()
        startedPlugin():scheduleNextRefresh()
        wakeup_mgr:wakeupAction()
        runPendingActions()
        expect.equal(#wakeup_mgr.tasks, 1)
    end,
}
