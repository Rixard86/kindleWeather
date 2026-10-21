local Device = require("device")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local logger = require("logger")
local Constants = require("weather_constants")

local Wifi = {}

local RADIO_SWITCHES = {
    { service = "com.lab126.cmd", property = "wirelessEnable" },
    { service = "com.lab126.wifid", property = "enable" },
}
local POWER_STATE = { service = "com.lab126.powerd", property = "state" }
local CONNECTION_STATE = { service = "com.lab126.wifid", property = "cmState" }
local INTERFACE = "wlan0"
local INTERFACE_STATE_FILE = "/sys/class/net/wlan0/operstate"
local ROUTE_TABLE_FILE = "/proc/net/route"
local DHCP_RESULT_FILE = "/tmp/wlan0"
local DEFAULT_DESTINATION = "00000000"
local ASSOCIATED = "COMPLETED"
local SUPPLICANT_STATUS_COMMAND = "wpa_cli -i wlan0 status 2>/dev/null"
local SUPPLICANT_RECONNECT_COMMAND = "ifconfig wlan0 up; wpa_cli -i wlan0 reconnect 2>&1"
local DHCP_COMMAND = "timeout 20 udhcpc -i wlan0 -n -q -t 3 -T 3 2>&1"
local ROUTE_COMMAND = "route add default gw %s dev wlan0 2>&1"
local GATEWAY_PATTERN = "gw=(%d+%.%d+%.%d+%.%d+)"
local RADIO_OFF = 0

local function lipcHandle()
    return Device.powerd and Device.powerd.lipc_handle
end

local function readProperty(spec)
    local handle = lipcHandle()
    if not handle then
        return "no-lipc"
    end
    local ok, value = pcall(handle.get_string_property, handle, spec.service, spec.property)
    return ok and tostring(value) or "unreadable"
end

local function readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function runCommand(command)
    local pipe = io.popen(command)
    if not pipe then
        return ""
    end
    local output = pipe:read("*a") or ""
    pipe:close()
    return (output:gsub("%s+", " "))
end

local function supplicantState()
    return runCommand(SUPPLICANT_STATUS_COMMAND):match("wpa_state=(%S+)") or "unknown"
end

local function hasDefaultRoute()
    for line in (readFile(ROUTE_TABLE_FILE) or ""):gmatch("[^\n]+") do
        local interface, destination = line:match("^(%S+)%s+(%x+)")
        if interface == INTERFACE and destination == DEFAULT_DESTINATION then
            return true
        end
    end
    return false
end

local function hasAddress()
    local ok, connected = pcall(function() return NetworkMgr:isConnected() end)
    return ok and connected ~= nil and connected ~= false
end

function Wifi.isConnected()
    return hasAddress() and hasDefaultRoute()
end

local isConnected = Wifi.isConnected

local function describeState()
    return string.format("power=%s wifi=%s interface=%s supplicant=%s address=%s route=%s",
        readProperty(POWER_STATE), readProperty(CONNECTION_STATE),
        (readFile(INTERFACE_STATE_FILE) or "missing"):gsub("%s", ""),
        supplicantState(), tostring(hasAddress()), tostring(hasDefaultRoute()))
end

local function reconnectSupplicant()
    logger.info("WeatherScreen: supplicant:", runCommand(SUPPLICANT_RECONNECT_COMMAND))
end

local function requestAddress()
    logger.info("WeatherScreen: dhcp:", runCommand(DHCP_COMMAND))
end

local function addDefaultRoute()
    local gateway = (readFile(DHCP_RESULT_FILE) or ""):match(GATEWAY_PATTERN)
    if gateway and not hasDefaultRoute() then
        logger.info("WeatherScreen: route via", gateway, runCommand(string.format(ROUTE_COMMAND, gateway)))
    end
end

local function isAssociated()
    return supplicantState() == ASSOCIATED
end

local STAGES = {
    { name = "supplicant reconnect", action = reconnectSupplicant, ready = isAssociated },
    { name = "dhcp", action = requestAddress },
    { name = "default route", action = addDefaultRoute },
}

local function waitUntil(spec)
    local deadline = os.time() + spec.seconds
    local check
    check = function()
        if spec.ready() or os.time() >= deadline then
            return spec.on_finished()
        end
        UIManager:scheduleIn(Constants.WIFI_POLL_SECONDS, check)
    end
    check()
end

local function runStages(index, on_done)
    if isConnected() then
        logger.info("WeatherScreen: Wi-Fi connected before stage", index, describeState())
        return on_done(true)
    end
    local stage = STAGES[index]
    if not stage then
        logger.info("WeatherScreen: Wi-Fi not connected after all stages,", describeState())
        return on_done(false)
    end
    logger.info("WeatherScreen: Wi-Fi stage", stage.name, describeState())
    local ok, err = pcall(stage.action)
    if not ok then
        logger.warn("WeatherScreen: Wi-Fi stage failed:", stage.name, err)
    end
    local next_stage = function() runStages(index + 1, on_done) end
    if not stage.ready then
        return next_stage()
    end
    waitUntil({ seconds = Constants.WIFI_STAGE_SECONDS, ready = stage.ready, on_finished = next_stage })
end

function Wifi.isRadioOn()
    local ok, radio_on = pcall(function() return NetworkMgr:isWifiOn() end)
    return ok and radio_on ~= nil and radio_on ~= false
end

function Wifi.turnRadioOff()
    local handle = lipcHandle()
    if not handle then
        return
    end
    for _, switch in ipairs(RADIO_SWITCHES) do
        pcall(handle.set_int_property, handle, switch.service, switch.property, RADIO_OFF)
    end
end

function Wifi.connect(on_done)
    if isConnected() then
        logger.info("WeatherScreen: using the existing connection,", describeState())
        return on_done(true)
    end
    runStages(1, on_done)
end

return Wifi
