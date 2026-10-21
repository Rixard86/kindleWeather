local Constants = require("weather_constants")

local LANGUAGES = {
    en = require("weather_strings_en"),
    sv = require("weather_strings_sv"),
}

local DEFAULT_LANGUAGE = "en"

local I18n = {
    DEFAULT_LANGUAGE = DEFAULT_LANGUAGE,
    LANGUAGE_CODES = { "en", "sv" },
}

local current_code = DEFAULT_LANGUAGE

local function strings()
    return LANGUAGES[current_code]
end

function I18n.setLanguage(code)
    current_code = LANGUAGES[code] and code or DEFAULT_LANGUAGE
end

function I18n.language()
    return current_code
end

function I18n.languageName(code)
    return LANGUAGES[code].text.language_name
end

function I18n.text(key)
    return strings().text[key] or LANGUAGES[DEFAULT_LANGUAGE].text[key] or key
end

function I18n.weekday(index)
    return strings().weekdays[index]
end

function I18n.month(index)
    return strings().months[index]
end

function I18n.condition(code)
    local smhi_label = type(code) == "number" and strings().smhi_conditions[code - Constants.SMHI_CODE_OFFSET]
    return smhi_label or strings().conditions[code] or strings().text.unknown_condition
end

return I18n
