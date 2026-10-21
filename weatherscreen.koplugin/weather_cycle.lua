local Device = require("device")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local Constants = require("weather_constants")
local Wifi = require("weather_wifi")

local Cycle = {}
Cycle.__index = Cycle

local POWERD_SERVICE = "com.lab126.powerd"
local PREVENT_SLEEP_PROPERTY = "preventScreenSaver"
local HOLD_ON = 1
local HOLD_OFF = 0

local function batteryLevel()
    local ok, level = pcall(function() return Device.powerd:getCapacity() end)
    return ok and tostring(level) .. "%" or "unknown"
end

local function holdAwake(enabled)
    local handle = Device.powerd and Device.powerd.lipc_handle
    if not handle then
        return
    end
    local ok, err = pcall(function()
        handle:set_int_property(POWERD_SERVICE, PREVENT_SLEEP_PROPERTY, enabled and HOLD_ON or HOLD_OFF)
    end)
    if not ok then
        logger.warn("WeatherScreen: could not change the sleep hold:", err)
    end
end

function Cycle.new(callbacks)
    return setmetatable({ callbacks = callbacks, running = false, token = 0 }, Cycle)
end

function Cycle:start()
    if self.running then
        return
    end
    self.running = true
    self.token = self.token + 1
    self.started_at = os.time()
    logger.info("WeatherScreen: refresh started, battery", batteryLevel())
    local token = self.token
    self.radio_was_on = Wifi.isRadioOn()
    holdAwake(true)
    self.callbacks.on_started()
    UIManager:scheduleIn(Constants.CYCLE_WATCHDOG_SECONDS, function()
        self:finish(token)
    end)
    Wifi.connect(function(connected)
        self:download(token, connected)
    end)
end

function Cycle:download(token, connected)
    if token ~= self.token or not self.running then
        return
    end
    local ok, downloaded = pcall(self.callbacks.download)
    if not ok then
        logger.warn("WeatherScreen: refresh failed:", downloaded)
    end
    logger.info("WeatherScreen: download", downloaded == true and "succeeded" or "failed",
        "with Wi-Fi confirmed:", tostring(connected))
    self:finish(token)
end

function Cycle:finish(token)
    if token ~= self.token or not self.running then
        return
    end
    self.running = false
    if not self.radio_was_on then
        Wifi.turnRadioOff()
    end
    holdAwake(false)
    logger.info("WeatherScreen: refresh finished after", os.time() - self.started_at, "s, battery", batteryLevel())
    self.callbacks.on_finished()
end

return Cycle
