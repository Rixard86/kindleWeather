local Constants = require("weather_constants")
local NewsDates = require("news_dates")
local Url = require("weather_url")

local NewsFeed = {}

local NAMED_ENTITIES = { amp = "&", lt = "<", gt = ">", quot = "\"", apos = "'" }
local ENTITY_PATTERN = "&(#?%w+);"
local DECIMAL_ENTITY_PATTERN = "^#(%d+)$"
local HEX_ENTITY_PATTERN = "^#[xX](%x+)$"
local HEX_BASE = 16
local ASCII_LIMIT = 128
local CDATA_PATTERN = "^%s*<!%[CDATA%[(.-)%]%]>%s*$"
local SOURCE_SEPARATOR = " - "
local NEVER = 0

function NewsFeed.buildUrl(place)
    local query = Url.escape(place .. " " .. Constants.NEWS_WINDOW)
    return string.format("%s?q=%s&hl=%s&gl=%s&ceid=%s", Constants.NEWS_URL, query,
        Constants.NEWS_LANGUAGE, Constants.NEWS_REGION, Constants.NEWS_EDITION)
end

function NewsFeed.buildTopStoriesUrl()
    return string.format("%s?hl=%s&gl=%s&ceid=%s", Constants.NEWS_TOP_STORIES_URL,
        Constants.NEWS_LANGUAGE, Constants.NEWS_REGION, Constants.NEWS_EDITION)
end

local function decodeEntity(entity)
    if NAMED_ENTITIES[entity] then
        return NAMED_ENTITIES[entity]
    end
    local hex = entity:match(HEX_ENTITY_PATTERN)
    local number = tonumber(entity:match(DECIMAL_ENTITY_PATTERN)) or (hex and tonumber(hex, HEX_BASE))
    if number and number < ASCII_LIMIT then
        return string.char(number)
    end
end

local function decodeEntities(text)
    return (text:gsub(ENTITY_PATTERN, decodeEntity))
end

local function tagText(block, tag)
    local raw = block:match("<" .. tag .. "[^>]*>(.-)</" .. tag .. ">")
    if not raw then
        return nil
    end
    return decodeEntities(raw:gsub(CDATA_PATTERN, "%1"))
end

local function withoutSourceSuffix(title, source)
    local suffix = source and (SOURCE_SEPARATOR .. source)
    if suffix and #title > #suffix and title:sub(-#suffix) == suffix then
        return title:sub(1, -#suffix - 1)
    end
    return title
end

local function parseItem(block)
    local title = tagText(block, "title")
    if not title then
        return nil
    end
    local source = tagText(block, "source")
    return {
        title = withoutSourceSuffix(title, source),
        source = source,
        published = NewsDates.parse(tagText(block, "pubDate")),
    }
end

local function newestFirst(first, second)
    return (first.published or NEVER) > (second.published or NEVER)
end

function NewsFeed.parse(xml, fetched_at)
    if type(xml) ~= "string" then
        return nil
    end
    local items = {}
    for block in xml:gmatch("<item>(.-)</item>") do
        items[#items + 1] = parseItem(block)
    end
    table.sort(items, newestFirst)
    local newest = {}
    for index = 1, math.min(#items, Constants.NEWS_MAX_ITEMS) do
        newest[index] = items[index]
    end
    return { fetched_at = fetched_at, items = newest }
end

return NewsFeed
