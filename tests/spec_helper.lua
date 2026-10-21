local Expect = {}

local CALLER_LEVEL = 2

local function describeValue(value)
    if type(value) == "string" then
        return string.format("%q", value)
    end
    return tostring(value)
end

function Expect.equal(actual, expected)
    if actual ~= expected then
        error(string.format("expected %s but got %s", describeValue(expected), describeValue(actual)), CALLER_LEVEL)
    end
end

function Expect.isNil(value)
    if value ~= nil then
        error("expected nil but got " .. describeValue(value), CALLER_LEVEL)
    end
end

return Expect
