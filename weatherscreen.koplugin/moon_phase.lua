local MoonPhase = {}

local PHASE_EVENTS = {
    { key = "new_moon", offset = 0 },
    { key = "first_quarter", offset = 0.25 },
    { key = "full_moon", offset = 0.5 },
    { key = "last_quarter", offset = 0.75 },
}
local BETWEEN_EVENTS = {
    new_moon = "waxing_crescent",
    first_quarter = "waxing_gibbous",
    full_moon = "waning_gibbous",
    last_quarter = "waning_crescent",
}
local SECONDS_PER_DAY = 86400
local UNIX_EPOCH_JULIAN_DAY = 2440587.5
local MEAN_NEW_MOON_JDE = 2451550.09766
local SYNODIC_MONTH_DAYS = 29.530588861
local LUNATIONS_PER_CENTURY = 1236.85
local ECCENTRICITY_RATE = 0.002516
local SUN_ANOMALY = { base = 2.5534, rate = 29.10535670 }
local MOON_ANOMALY = { base = 201.5643, rate = 385.81693528 }
local NEW_MOON_TERMS = { moon = -0.40720, sun = 0.17241 }
local FULL_MOON_TERMS = { moon = -0.40614, sun = 0.17302 }
local QUARTER_TERMS = { moon = -0.62801, sun = 0.17172 }
local QUARTER_SHIFT = { base = 0.00306, sun = -0.00038, moon = 0.00026 }
local EVENT_WINDOW_DAYS = 1
local FULL_TURN = 2 * math.pi
local HALF = 0.5
local LOOKBACK_LUNATIONS = 2

local function toJulianDay(epoch)
    return epoch / SECONDS_PER_DAY + UNIX_EPOCH_JULIAN_DAY
end

local function toEpoch(julian_day)
    return (julian_day - UNIX_EPOCH_JULIAN_DAY) * SECONDS_PER_DAY
end

local function sineOfDegrees(degrees)
    return math.sin(math.rad(degrees))
end

local function correction(lunation, offset)
    local eccentricity = 1 - ECCENTRICITY_RATE * lunation / LUNATIONS_PER_CENTURY
    local sun = SUN_ANOMALY.base + SUN_ANOMALY.rate * lunation
    local moon = MOON_ANOMALY.base + MOON_ANOMALY.rate * lunation
    local terms = offset == 0 and NEW_MOON_TERMS or offset == HALF and FULL_MOON_TERMS or QUARTER_TERMS
    local days = terms.moon * sineOfDegrees(moon) + terms.sun * eccentricity * sineOfDegrees(sun)
    if terms == QUARTER_TERMS then
        local shift = QUARTER_SHIFT.base + QUARTER_SHIFT.sun * eccentricity * math.cos(math.rad(sun))
            + QUARTER_SHIFT.moon * math.cos(math.rad(moon))
        days = days + (offset < HALF and shift or -shift)
    end
    return days
end

local function eventTime(lunation, offset)
    local k = lunation + offset
    return toEpoch(MEAN_NEW_MOON_JDE + SYNODIC_MONTH_DAYS * k + correction(k, offset))
end

local function eventsAround(epoch)
    local first = math.floor((toJulianDay(epoch) - MEAN_NEW_MOON_JDE) / SYNODIC_MONTH_DAYS) - LOOKBACK_LUNATIONS
    local events = {}
    for lunation = first, first + 2 * LOOKBACK_LUNATIONS do
        for _, phase in ipairs(PHASE_EVENTS) do
            events[#events + 1] = { key = phase.key, time = eventTime(lunation, phase.offset) }
        end
    end
    table.sort(events, function(a, b) return a.time < b.time end)
    return events
end

function MoonPhase.upcoming(epoch, count)
    local upcoming = {}
    for _, event in ipairs(eventsAround(epoch)) do
        if event.time > epoch and #upcoming < count then
            upcoming[#upcoming + 1] = event
        end
    end
    return upcoming
end

local function neighbours(epoch)
    local previous, following
    for _, event in ipairs(eventsAround(epoch)) do
        if event.time <= epoch then
            previous = event
        elseif not following then
            following = event
        end
    end
    return previous, following
end

function MoonPhase.name(epoch)
    local previous, following = neighbours(epoch)
    local window = EVENT_WINDOW_DAYS * SECONDS_PER_DAY
    if epoch - previous.time < window then
        return previous.key
    end
    if following.time - epoch < window then
        return following.key
    end
    return BETWEEN_EVENTS[previous.key]
end

function MoonPhase.cycleFraction(epoch)
    local last_new, next_new
    for _, event in ipairs(eventsAround(epoch)) do
        if event.key == "new_moon" and event.time <= epoch then
            last_new = event.time
        elseif event.key == "new_moon" and not next_new and event.time > epoch then
            next_new = event.time
        end
    end
    return (epoch - last_new) / (next_new - last_new)
end

function MoonPhase.illumination(epoch)
    return (1 - math.cos(FULL_TURN * MoonPhase.cycleFraction(epoch))) / 2
end

return MoonPhase
