local DataStorage = require("datastorage")
local Device = require("device")
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("luasettings")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local T = require("ffi/util").template
local Constants = require("weather_constants")
local Cycle = require("weather_cycle")
local Downloads = require("weather_downloads")
local Gallery = require("weather_gallery")
local I18n = require("weather_i18n")
local LocationDialog = require("weather_location_dialog")
local Menu = require("weather_menu")
local Orientation = require("weather_orientation")
local Panes = require("weather_panes")
local Preview = require("weather_preview")
local Schedule = require("weather_schedule")
local SleepScreen = require("weather_sleep_screen")
local Widgets = require("weather_widgets")
local Wifi = require("weather_wifi")

local active_plugin
local refresh_cycle

local WeatherScreen = WidgetContainer:extend{
    name = "weatherscreen",
    is_doc_only = false,
}

local function onScheduledWake()
    if active_plugin then
        active_plugin:startBackgroundRefresh()
    end
end

SleepScreen.install({
    isEnabled = function() return active_plugin ~= nil and active_plugin:isEnabled() end,
    orientation = function() return active_plugin:getOrientation() end,
    build = function() return Panes.build(active_plugin:getPaneId(), active_plugin:buildView()) end,
})

function WeatherScreen:init()
    self.settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/" .. Constants.SETTINGS_FILE_NAME)
    I18n.setLanguage(self.settings:readSetting("language", I18n.DEFAULT_LANGUAGE))
    Widgets.icon_dir = self.path .. "/icons/"
    Widgets.useFontsFrom(self.path)
    active_plugin = self
    refresh_cycle = refresh_cycle or Cycle.new({
        on_started = function() active_plugin:saveSetting("last_attempt", os.time()) end,
        download = function() return active_plugin:downloadAll() end,
        on_finished = function() active_plugin:scheduleNextRefresh() end,
    })
    self.ui.menu:registerToMainMenu(self)
end

function WeatherScreen:addToMainMenu(menu_items)
    menu_items.weather_screensaver = Menu.build(self)
end

function WeatherScreen:isEnabled()
    return self.settings:nilOrTrue("enabled")
end

function WeatherScreen:getLocation()
    return self.settings:readSetting("location", Constants.DEFAULT_LOCATION)
end

function WeatherScreen:getIntervalHours()
    return self.settings:readSetting("interval_hours", Constants.DEFAULT_INTERVAL_HOURS)
end

function WeatherScreen:getPaneId()
    return self.settings:readSetting("pane", Constants.DEFAULT_PANE)
end

function WeatherScreen:getSource()
    return self.settings:readSetting("source", Constants.DEFAULT_SOURCE)
end

function WeatherScreen:getOrientation()
    return self.settings:readSetting("orientation", Constants.DEFAULT_ORIENTATION)
end

function WeatherScreen:getNightMode()
    return self.settings:readSetting("night_mode", Constants.DEFAULT_NIGHT_MODE)
end

function WeatherScreen:saveSetting(key, value)
    self.settings:saveSetting(key, value)
    self.settings:flush()
end

function WeatherScreen:buildView()
    return {
        model = self.settings:readSetting("forecast"),
        news = self.settings:readSetting("news"),
        national_news = self.settings:readSetting("national_news"),
        place = self:getLocation().name,
        now = os.time(),
    }
end

function WeatherScreen:downloadAll()
    return Downloads.run(self)
end

function WeatherScreen:scheduleNextRefresh()
    local wakeup_mgr = Device.wakeup_mgr
    if not wakeup_mgr then
        return
    end
    wakeup_mgr:removeTasks(nil, onScheduledWake)
    if not self:isEnabled() then
        return
    end
    local forecast = self.settings:readSetting("forecast")
    local now = os.time()
    local due_at = now + Schedule.secondsUntilRefresh({
        last_success = forecast and forecast.fetched_at,
        last_attempt = self.settings:readSetting("last_attempt"),
        interval_seconds = Schedule.intervalSeconds(self:getIntervalHours()),
    }, now)
    local night = self:getNightMode()
    if night.enabled then
        due_at = Schedule.skipQuietHours(due_at, {
            start_hour = night.start_hour,
            end_hour = night.end_hour,
            utc_offset = forecast and forecast.utc_offset or 0,
        })
    end
    wakeup_mgr:addTask(due_at - now, onScheduledWake)
end

function WeatherScreen:onSuspend()
    self:scheduleNextRefresh()
    local forecast = self.settings:readSetting("forecast")
    if self:isEnabled() and Schedule.shouldRefreshBeforeSleep(forecast and forecast.fetched_at, os.time())
        and Wifi.isConnected() then
        UIManager:scheduleIn(Constants.SLEEP_REFRESH_DELAY_SECONDS, onScheduledWake)
    end
end

function WeatherScreen:startBackgroundRefresh()
    refresh_cycle:start()
end

function WeatherScreen:notify(text)
    UIManager:show(InfoMessage:new{ text = text, timeout = Constants.MESSAGE_TIMEOUT_SECONDS })
end

function WeatherScreen:refreshNow()
    NetworkMgr:runWhenOnline(function()
        if not self:downloadAll() then
            return self:notify(I18n.text("download_failed"))
        end
        self:notify(I18n.text("forecast_updated"))
    end)
end

function WeatherScreen:changeLocation()
    LocationDialog.show(self)
end

function WeatherScreen:clearDownloads()
    self.settings:delSetting("forecast")
    self.settings:delSetting("supplement")
    self.settings:delSetting("news")
    self.settings:flush()
end

function WeatherScreen:toggleEnabled()
    self:saveSetting("enabled", not self:isEnabled())
    self:scheduleNextRefresh()
end

function WeatherScreen:setIntervalHours(hours)
    self:saveSetting("interval_hours", hours)
end

function WeatherScreen:setPane(id)
    self:saveSetting("pane", id)
end

function WeatherScreen:setNightMode(night_mode)
    self:saveSetting("night_mode", night_mode)
end

function WeatherScreen:setSource(source)
    self:saveSetting("source", source)
end

function WeatherScreen:setOrientation(choice)
    self:saveSetting("orientation", choice)
end

function WeatherScreen:setLanguage(code)
    I18n.setLanguage(code)
    self:saveSetting("language", code)
end

function WeatherScreen:saveGallery()
    local saved = Gallery.saveAll(self:buildView())
    UIManager:setDirty(nil, "full")
    self:notify(T(I18n.text("gallery_saved"), saved, Gallery.DIRECTORY_NAME))
end

function WeatherScreen:showPreview()
    local previous_rotation = Orientation.apply(self:getOrientation())
    local ok, pane = pcall(Panes.build, self:getPaneId(), self:buildView())
    if not ok then
        Orientation.restore(previous_rotation)
        logger.warn("WeatherScreen: preview failed:", pane)
        return self:notify(I18n.text("preview_failed"))
    end
    UIManager:show(Preview:new{ pane, previous_rotation = previous_rotation })
end

return WeatherScreen
