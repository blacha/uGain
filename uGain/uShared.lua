-- Convert a number to a formated number
-- eg 1023 -> 1,023
function uShared_StringComma(number)
    local length = 0
    while true do
        number, length = string.gsub(number, "^(-?%d+)(%d%d%d)", "%1,%2")
        if (length == 0) then
            break
        end
    end

    return number
end

function uC(text, color)
    return string.format("%s%s|r", color, text or "")
end

-- Print a message to every chat window that has the event registered
function uShared_PrintAll(eventName, message)
    local frameFound = false
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame:IsEventRegistered(eventName) or (i == NUM_CHAT_WINDOWS and not frameFound) then
            frame:AddMessage(message)
            frameFound = true
        end
    end
end

local searchPatterns = {}
function uShared_GetSearchPattern(globalStringName)
    -- Don't do anything if the passed global string does not exist.
    local globalString = _G[globalStringName]
    if (globalString == nil) then
        return
    end

    -- Return the cached conversion if it has already been converted.
    if (searchPatterns[globalStringName]) then
        return searchPatterns[globalStringName]
    end

    -- -- Escape lua magic chars.
    local searchPattern = string.gsub(globalString, "([%^%(%)%.%[%]%*%+%-%?])", "%%%1")

    -- -- Convert %1$s / %s to (.+) and %1$d / %d to (%d+).
    searchPattern = string.gsub(searchPattern, "%%%d?%$?s", "(.+)")
    searchPattern = string.gsub(searchPattern, "%%%d?%$?d", "(%%d+)")

    -- -- Escape any remaining $ chars.
    searchPattern = string.gsub(searchPattern, "%$", "%%$")

    -- -- Cache the converted pattern and capture order.
    searchPatterns[globalStringName] = searchPattern

    -- -- Return the converted global string.
    return searchPattern
end
