local addonName, uGain = ...

-- Color definitions
uGain.C = {
    light    = "|cffabd6f4",
    medium   = "|cffffbb00",
    dark     = "|cffd27edf",
    gold     = "|cffffd700",
    silver   = "|cffc7c7cf",
    copper   = "|cffeda55f",
    negative = "|cffe25e6f",
    white    = "|cffffffff",
    yellow   = "|cffffff78",
    orange   = "|cffff7831",
    red      = "|cfff8a3a8",
    resume   = "|r"
}

-- Format text with a WoW color code
function uGain.Color(text, color)
    return string.format("%s%s|r", color, text or "")
end

-- Format numbers with comma delimiters (e.g., 1023 -> 1,023)
function uGain.StringComma(number)
    if not number then return "" end
    local length = 0
    local formatted = tostring(number)
    while true do
        formatted, length = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if length == 0 then
            break
        end
    end
    return formatted
end

-- Format money amounts as gg.ss.cc
function uGain.FormatMoney(amount)
    local value = abs(amount)
    local gold = floor(value * 0.0001)
    local silver = floor(mod(value * 0.01, 100))
    local copper = floor(mod(value, 100))
    return string.format("%s%d|r.%s%02d|r.%s%02d|r", uGain.C.gold, gold, uGain.C.silver, silver, uGain.C.copper, copper)
end

-- Print a message to all chat windows registered for the event
function uGain.PrintAll(eventName, message)
    local frameFound = false
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame and (frame:IsEventRegistered(eventName) or (i == NUM_CHAT_WINDOWS and not frameFound)) then
            frame:AddMessage(message)
            frameFound = true
        end
    end
end

-- Cache and transform global Blizzard format strings to Lua pattern regex
local searchPatterns = {}
function uGain.GetSearchPattern(globalStringName)
    local globalString = _G[globalStringName]
    if globalString == nil then
        return nil
    end

    if searchPatterns[globalStringName] then
        return searchPatterns[globalStringName]
    end

    -- Escape Lua magic characters
    local searchPattern = string.gsub(globalString, "([%^%(%)%.%[%]%*%+%-%?])", "%%%1")

    -- Convert %1$s / %s to (.-) and %1$d / %d to (%d+)
    searchPattern = string.gsub(searchPattern, "%%%d?%$?s", "(.-)")
    searchPattern = string.gsub(searchPattern, "%%%d?%$?d", "(%%d+)")

    -- Escape any remaining $ characters
    searchPattern = string.gsub(searchPattern, "%$", "%%$")

    searchPatterns[globalStringName] = searchPattern
    return searchPattern
end

-- Backwards compatibility aliases for macros / external addons
_G.uGain = uGain
_G.uC = uGain.Color
_G.uShared_StringComma = uGain.StringComma
_G.uShared_PrintAll = uGain.PrintAll
_G.uShared_GetSearchPattern = uGain.GetSearchPattern
