local Constants = require("weather_constants")
local NewsFeed = require("news_feed")
local expect = require("spec_helper")

local FETCHED_AT = 1792492200
local NEWEST_PUBLISHED = 1792471635
local FIXTURE_ITEM_COUNT = 10
local EXPECTED_URL = "https://news.google.com/rss/search?q=V%C3%A4nersborg%20when%3A2d"
    .. "&hl=sv&gl=SE&ceid=SE:sv"

local function feed(items)
    return "<rss><channel><title>Feed</title>" .. table.concat(items) .. "</channel></rss>"
end

return {
    ["builds a two-day search url for the place"] = function()
        expect.equal(NewsFeed.buildUrl("Vänersborg"), EXPECTED_URL)
    end,
    ["builds the swedish top stories url"] = function()
        expect.equal(NewsFeed.buildTopStoriesUrl(), "https://news.google.com/rss?hl=sv&gl=SE&ceid=SE:sv")
    end,
    ["returns nil without a response"] = function()
        expect.isNil(NewsFeed.parse(nil, FETCHED_AT))
    end,
    ["reads every fixture item newest first"] = function()
        local news = NewsFeed.parse(FIXTURES.news, FETCHED_AT)
        expect.equal(news.fetched_at, FETCHED_AT)
        expect.equal(#news.items, FIXTURE_ITEM_COUNT)
        expect.equal(news.items[1].published, NEWEST_PUBLISHED)
        for index = 2, #news.items do
            expect.equal(news.items[index - 1].published >= news.items[index].published, true)
        end
    end,
    ["strips the source name from the headline"] = function()
        local first = NewsFeed.parse(FIXTURES.news, FETCHED_AT).items[1]
        expect.equal(first.title, "Politikerna i Vänersborg fattar inte vad jäv är")
        expect.equal(first.source, "TTELA")
    end,
    ["decodes entities and cdata"] = function()
        local news = NewsFeed.parse(feed({
            "<item><title><![CDATA[Bil &amp; buss]]></title></item>",
            "<item><title>Det &quot;nya&quot; torget &#39;idag&#39; &#x21;</title></item>",
        }), FETCHED_AT)
        expect.equal(news.items[1].title, "Bil & buss")
        expect.equal(news.items[2].title, "Det \"nya\" torget 'idag' !")
    end,
    ["keeps headlines whose source is not repeated"] = function()
        local news = NewsFeed.parse(feed({
            "<item><title>Nytt styre - igen</title><source url=\"x\">TTELA</source></item>",
        }), FETCHED_AT)
        expect.equal(news.items[1].title, "Nytt styre - igen")
    end,
    ["limits the number of headlines"] = function()
        local items = {}
        for index = 1, Constants.NEWS_MAX_ITEMS + 5 do
            items[index] = "<item><title>Nyhet " .. index .. "</title></item>"
        end
        expect.equal(#NewsFeed.parse(feed(items), FETCHED_AT).items, Constants.NEWS_MAX_ITEMS)
    end,
    ["returns an empty list for a feed without items"] = function()
        expect.equal(#NewsFeed.parse(feed({}), FETCHED_AT).items, 0)
    end,
}
