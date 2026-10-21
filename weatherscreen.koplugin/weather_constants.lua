local SECONDS_PER_MINUTE = 60
local MINUTES_PER_HOUR = 60
local HOURS_PER_DAY = 24
local SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR
local MINIMUM_WAKE_MINUTES = 5
local SLEEP_REFRESH_MIN_AGE_MINUTES = 10

return {
    SETTINGS_FILE_NAME = "weatherscreen.lua",
    PREVIEW_SCREENSHOT_NAME = "weatherscreen_preview.png",
    DEFAULT_LOCATION = {
        name = "Vänersborg",
        country = "Sweden",
        latitude = 58.38075,
        longitude = 12.3234,
    },
    DEFAULT_INTERVAL_HOURS = 3,
    INTERVAL_CHOICES_HOURS = { 1, 2, 3, 6 },
    SECONDS_PER_HOUR = SECONDS_PER_HOUR,
    SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY,
    MIN_WAKE_DELAY_SECONDS = MINIMUM_WAKE_MINUTES * SECONDS_PER_MINUTE,
    SLEEP_REFRESH_MIN_AGE_SECONDS = SLEEP_REFRESH_MIN_AGE_MINUTES * SECONDS_PER_MINUTE,
    SLEEP_REFRESH_DELAY_SECONDS = 1,
    SUPPLEMENT_MAX_AGE_SECONDS = SECONDS_PER_HOUR * HOURS_PER_DAY,
    FORECAST_URL = "https://api.open-meteo.com/v1/forecast",
    SMHI_URL_TEMPLATE = "https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1"
        .. "/geotype/point/lon/%.4f/lat/%.4f/data.json",
    SMHI_CODE_OFFSET = 1000,
    SOURCE_SMHI = "smhi",
    SOURCE_OPEN_METEO = "open_meteo",
    SOURCE_CHOICES = { "smhi", "open_meteo" },
    DEFAULT_SOURCE = "smhi",
    GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search",
    FORECAST_DAYS = 8,
    FORECAST_HOURS = 24,
    WEEK_LENGTH_DAYS = 7,
    GEOCODE_RESULT_COUNT = 1,
    NEWS_URL = "https://news.google.com/rss/search",
    NEWS_TOP_STORIES_URL = "https://news.google.com/rss",
    NEWS_WINDOW = "when:2d",
    NEWS_LANGUAGE = "sv",
    NEWS_REGION = "SE",
    NEWS_EDITION = "SE:sv",
    NEWS_MAX_ITEMS = 10,
    DEFAULT_PANE = "simple_weather",
    DEFAULT_ORIENTATION = "portrait",
    DEFAULT_NIGHT_MODE = { enabled = false, start_hour = 23, end_hour = 6 },
    HTTP_BLOCK_TIMEOUT_SECONDS = 15,
    HTTP_TOTAL_TIMEOUT_SECONDS = 30,
    HTTP_STATUS_OK = 200,
    WIFI_STAGE_SECONDS = 15,
    WIFI_POLL_SECONDS = 3,
    CYCLE_WATCHDOG_SECONDS = 120,
    MESSAGE_TIMEOUT_SECONDS = 3,
    PREVIEW_SCREENSHOT_DELAY_SECONDS = 1,
}
