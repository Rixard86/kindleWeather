local MoonDrawing = {}

local CANVAS = 64
local CENTER = 32
local RADIUS = 28
local FULL_TURN = 2 * math.pi
local HALF = 0.5
local QUARTER = 0.25
local THREE_QUARTERS = 0.75
local CLOCKWISE = 1
local COUNTER_CLOCKWISE = 0
local DARK_SIDE = "#5A5A5A"
local LIT_SIDE = "#FFFFFF"
local OUTLINE = 'stroke="#000" stroke-width="3" stroke-linejoin="round"'

local function terminatorSweep(fraction)
    local crescent = fraction < QUARTER or fraction > THREE_QUARTERS
    local waxing = fraction < HALF
    if waxing == crescent then
        return COUNTER_CLOCKWISE
    end
    return CLOCKWISE
end

local function litPath(fraction)
    local top, bottom = CENTER - RADIUS, CENTER + RADIUS
    local limb_sweep = fraction < HALF and CLOCKWISE or COUNTER_CLOCKWISE
    local terminator_radius = math.abs(math.cos(FULL_TURN * fraction)) * RADIUS
    return string.format("M%d %d A%d %d 0 0 %d %d %d A%.2f %d 0 0 %d %d %dZ",
        CENTER, top, RADIUS, RADIUS, limb_sweep, CENTER, bottom,
        terminator_radius, RADIUS, terminatorSweep(fraction), CENTER, top)
end

function MoonDrawing.svg(fraction)
    return string.format(
        '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
            .. '<circle cx="%d" cy="%d" r="%d" fill="%s"/>'
            .. '<path d="%s" fill="%s"/>'
            .. '<circle cx="%d" cy="%d" r="%d" fill="none" %s/></svg>',
        CANVAS, CANVAS, CANVAS, CANVAS,
        CENTER, CENTER, RADIUS, DARK_SIDE,
        litPath(fraction), LIT_SIDE,
        CENTER, CENTER, RADIUS, OUTLINE)
end

return MoonDrawing
