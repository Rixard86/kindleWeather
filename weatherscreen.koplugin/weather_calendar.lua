local Calendar = {}

local MONTHS_BEFORE_MARCH = 2
local MARCH_BASED_MONTH_SHIFT = 9
local MONTHS_PER_YEAR = 12
local DAYS_IN_FIVE_MONTH_CYCLE = 153
local MONTHS_IN_CYCLE = 5
local CYCLE_ROUNDING = 2
local YEARS_PER_ERA = 400
local DAYS_PER_ERA = 146097
local DAYS_PER_YEAR = 365
local LEAP_YEAR_INTERVAL = 4
local CENTURY_YEARS = 100
local DAYS_FROM_ERA_START_TO_EPOCH = 719468
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400

local function daysSinceEpoch(date)
    local year = date.month <= MONTHS_BEFORE_MARCH and date.year - 1 or date.year
    local era = math.floor(year / YEARS_PER_ERA)
    local year_of_era = year - era * YEARS_PER_ERA
    local month_from_march = (date.month + MARCH_BASED_MONTH_SHIFT) % MONTHS_PER_YEAR
    local day_of_year = math.floor((DAYS_IN_FIVE_MONTH_CYCLE * month_from_march + CYCLE_ROUNDING) / MONTHS_IN_CYCLE)
        + date.day - 1
    local day_of_era = year_of_era * DAYS_PER_YEAR + math.floor(year_of_era / LEAP_YEAR_INTERVAL)
        - math.floor(year_of_era / CENTURY_YEARS) + day_of_year
    return era * DAYS_PER_ERA + day_of_era - DAYS_FROM_ERA_START_TO_EPOCH
end

function Calendar.utcEpoch(parts)
    return daysSinceEpoch(parts) * SECONDS_PER_DAY
        + parts.hour * SECONDS_PER_HOUR
        + parts.minute * SECONDS_PER_MINUTE
        + (parts.second or 0)
end

function Calendar.localDayStart(epoch, utc_offset)
    return math.floor((epoch + utc_offset) / SECONDS_PER_DAY) * SECONDS_PER_DAY - utc_offset
end

return Calendar
