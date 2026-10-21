local Calendar = require("weather_calendar")
local Constants = require("weather_constants")

local Schedule = {}

local NEVER = 0

function Schedule.intervalSeconds(hours)
    return hours * Constants.SECONDS_PER_HOUR
end

function Schedule.secondsUntilRefresh(state, now)
    local latest_refresh = math.max(state.last_success or NEVER, state.last_attempt or NEVER)
    if latest_refresh == NEVER then
        return Constants.MIN_WAKE_DELAY_SECONDS
    end
    local due_at = latest_refresh + state.interval_seconds
    return math.max(due_at - now, Constants.MIN_WAKE_DELAY_SECONDS)
end

function Schedule.supplementIsFresh(supplement, now)
    return supplement ~= nil and supplement.fetched_at ~= nil
        and now - supplement.fetched_at < Constants.SUPPLEMENT_MAX_AGE_SECONDS
end

function Schedule.shouldRefreshBeforeSleep(last_success, now)
    return not last_success or now - last_success >= Constants.SLEEP_REFRESH_MIN_AGE_SECONDS
end

local function localHour(epoch, utc_offset)
    return math.floor(((epoch + utc_offset) % Constants.SECONDS_PER_DAY) / Constants.SECONDS_PER_HOUR)
end

local function isQuietHour(hour, quiet)
    if quiet.start_hour == quiet.end_hour then
        return false
    end
    if quiet.start_hour < quiet.end_hour then
        return hour >= quiet.start_hour and hour < quiet.end_hour
    end
    return hour >= quiet.start_hour or hour < quiet.end_hour
end

function Schedule.skipQuietHours(due_at, quiet)
    if not isQuietHour(localHour(due_at, quiet.utc_offset), quiet) then
        return due_at
    end
    local quiet_end = Calendar.localDayStart(due_at, quiet.utc_offset) + quiet.end_hour * Constants.SECONDS_PER_HOUR
    if quiet_end > due_at then
        return quiet_end
    end
    return quiet_end + Constants.SECONDS_PER_DAY
end

return Schedule
