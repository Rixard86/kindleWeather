local Url = {}

local UNRESERVED_CHARACTERS = "[^%w%-%._~]"
local PERCENT_ENCODED_BYTE = "%%%02X"

function Url.escape(text)
    return (text:gsub(UNRESERVED_CHARACTERS, function(character)
        return string.format(PERCENT_ENCODED_BYTE, character:byte())
    end))
end

return Url
