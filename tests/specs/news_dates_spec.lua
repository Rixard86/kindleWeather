local NewsDates = require("news_dates")
local expect = require("spec_helper")

local TUESDAY_04_47_15_UTC = 1792471635
local LEAP_DAY_NOON_UTC = 1709208000
local LAST_SECOND_OF_1999 = 946684799
local SECONDS_PART = 15

return {
    ["parses gmt dates"] = function()
        expect.equal(NewsDates.parse("Tue, 20 Oct 2026 04:47:15 GMT"), TUESDAY_04_47_15_UTC)
    end,
    ["applies numeric time zones"] = function()
        expect.equal(NewsDates.parse("Tue, 20 Oct 2026 06:47:15 +0200"), TUESDAY_04_47_15_UTC)
        expect.equal(NewsDates.parse("Mon, 19 Oct 2026 23:47:15 -0500"), TUESDAY_04_47_15_UTC)
    end,
    ["handles the unix epoch, leap days and year ends"] = function()
        expect.equal(NewsDates.parse("Thu, 01 Jan 1970 00:00:00 GMT"), 0)
        expect.equal(NewsDates.parse("Thu, 29 Feb 2024 12:00:00 GMT"), LEAP_DAY_NOON_UTC)
        expect.equal(NewsDates.parse("Fri, 31 Dec 1999 23:59:59 GMT"), LAST_SECOND_OF_1999)
    end,
    ["accepts dates without seconds"] = function()
        expect.equal(NewsDates.parse("Tue, 20 Oct 2026 04:47 GMT"), TUESDAY_04_47_15_UTC - SECONDS_PART)
    end,
    ["returns nil for unreadable dates"] = function()
        expect.isNil(NewsDates.parse(nil))
        expect.isNil(NewsDates.parse("yesterday"))
        expect.isNil(NewsDates.parse("Tue, 20 Foo 2026 04:47:15 GMT"))
    end,
}
