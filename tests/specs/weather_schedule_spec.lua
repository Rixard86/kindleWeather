local Constants = require("weather_constants")
local Schedule = require("weather_schedule")
local expect = require("spec_helper")

local NOW = 1792492200
local THREE_HOURS = 3 * Constants.SECONDS_PER_HOUR
local ONE_HOUR = Constants.SECONDS_PER_HOUR
local ONE_MINUTE = 60
local SUMMER_TIME_OFFSET = 7200
local LOCAL_02_00 = 1792540800
local LOCAL_03_00 = 1792544400
local LOCAL_05_00 = 1792551600
local LOCAL_06_00 = 1792555200
local LOCAL_12_00 = 1792576800
local LOCAL_22_59 = 1792616340
local LOCAL_23_00 = 1792616400
local LOCAL_23_30 = 1792618200
local NEXT_MORNING_06_00 = 1792641600
local OVERNIGHT = { start_hour = 23, end_hour = 6, utc_offset = SUMMER_TIME_OFFSET }

return {
    ["converts hours to seconds"] = function()
        expect.equal(Schedule.intervalSeconds(3), THREE_HOURS)
    end,
    ["wakes soon when there is no forecast yet"] = function()
        local delay = Schedule.secondsUntilRefresh({ interval_seconds = THREE_HOURS }, NOW)
        expect.equal(delay, Constants.MIN_WAKE_DELAY_SECONDS)
    end,
    ["waits until the forecast is due"] = function()
        local state = { last_success = NOW - ONE_HOUR, interval_seconds = THREE_HOURS }
        expect.equal(Schedule.secondsUntilRefresh(state, NOW), THREE_HOURS - ONE_HOUR)
    end,
    ["wakes soon when the forecast is overdue"] = function()
        local state = { last_success = NOW - THREE_HOURS - ONE_HOUR, interval_seconds = THREE_HOURS }
        expect.equal(Schedule.secondsUntilRefresh(state, NOW), Constants.MIN_WAKE_DELAY_SECONDS)
    end,
    ["waits a full interval after a failed attempt"] = function()
        local state = {
            last_success = NOW - THREE_HOURS - ONE_HOUR,
            last_attempt = NOW,
            interval_seconds = THREE_HOURS,
        }
        expect.equal(Schedule.secondsUntilRefresh(state, NOW), THREE_HOURS)
    end,
    ["reuses an open-meteo supplement for a day"] = function()
        expect.equal(Schedule.supplementIsFresh({ fetched_at = NOW - ONE_HOUR }, NOW), true)
        expect.equal(Schedule.supplementIsFresh({ fetched_at = NOW - Constants.SECONDS_PER_DAY }, NOW), false)
        expect.equal(Schedule.supplementIsFresh(nil, NOW), false)
        expect.equal(Schedule.supplementIsFresh({}, NOW), false)
    end,
    ["refreshes before sleep when the forecast is old or missing"] = function()
        expect.equal(Schedule.shouldRefreshBeforeSleep(nil, NOW), true)
        expect.equal(Schedule.shouldRefreshBeforeSleep(NOW - ONE_HOUR, NOW), true)
        expect.equal(Schedule.shouldRefreshBeforeSleep(NOW - Constants.SLEEP_REFRESH_MIN_AGE_SECONDS, NOW), true)
    end,
    ["skips the sleep refresh for a fresh forecast"] = function()
        expect.equal(Schedule.shouldRefreshBeforeSleep(NOW - ONE_MINUTE, NOW), false)
    end,
    ["moves a night time wake to the end of the night"] = function()
        expect.equal(Schedule.skipQuietHours(LOCAL_02_00, OVERNIGHT), LOCAL_06_00)
    end,
    ["moves a late evening wake to the next morning"] = function()
        expect.equal(Schedule.skipQuietHours(LOCAL_23_30, OVERNIGHT), NEXT_MORNING_06_00)
        expect.equal(Schedule.skipQuietHours(LOCAL_23_00, OVERNIGHT), NEXT_MORNING_06_00)
    end,
    ["keeps wakes outside the night"] = function()
        expect.equal(Schedule.skipQuietHours(LOCAL_12_00, OVERNIGHT), LOCAL_12_00)
        expect.equal(Schedule.skipQuietHours(LOCAL_22_59, OVERNIGHT), LOCAL_22_59)
        expect.equal(Schedule.skipQuietHours(LOCAL_06_00, OVERNIGHT), LOCAL_06_00)
    end,
    ["handles nights that do not cross midnight"] = function()
        local early_hours = { start_hour = 1, end_hour = 5, utc_offset = SUMMER_TIME_OFFSET }
        expect.equal(Schedule.skipQuietHours(LOCAL_03_00, early_hours), LOCAL_05_00)
        expect.equal(Schedule.skipQuietHours(LOCAL_12_00, early_hours), LOCAL_12_00)
    end,
    ["ignores a night that starts and ends at the same hour"] = function()
        local empty_night = { start_hour = 6, end_hour = 6, utc_offset = SUMMER_TIME_OFFSET }
        expect.equal(Schedule.skipQuietHours(LOCAL_02_00, empty_night), LOCAL_02_00)
    end,
    ["waits a full interval after a first failed attempt"] = function()
        local state = { last_attempt = NOW, interval_seconds = THREE_HOURS }
        expect.equal(Schedule.secondsUntilRefresh(state, NOW), THREE_HOURS)
    end,
}
