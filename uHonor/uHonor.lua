local C = {
    light = "|cFFABD6F4",
    medium = "|cffffbb00",
    dark = "|cffff8800",
    resume = "|r"
}

local HonorCurrencyId = 1901

local function uHonor_OnHonorGain(text)
    local currentHonor = C_CurrencyInfo.GetCurrencyInfo(HonorCurrencyId).quantity or 0

    local currentHonorText = ""
    if currentHonor > 0 then
        currentHonorText = " (" .. uC(uShared_StringComma(currentHonor), C.dark) .. ")."
    end

    local honorGainPattern = uShared_GetSearchPattern("COMBATLOG_HONORGAIN")
    local honorGainMatch, _, playerName, _, honorGain = string.find(text, honorGainPattern)
    if (honorGainMatch) then
        local message = uC("+" .. uShared_StringComma(honorGain), C.dark) .. " Honor " .. uC(playerName, C.light) ..
                            " killed" .. currentHonorText

        uShared_PrintAll("CHAT_MSG_COMBAT_HONOR_GAIN", message)
        return
    end

    local honorAwardPattern = uShared_GetSearchPattern("COMBATLOG_HONORAWARD")
    local honorAwardMatch, _, honorAward = string.find(text, honorAwardPattern)

    if (honorAwardMatch) then
        local message = uC("+" .. uShared_StringComma(honorAward), C.dark) .. " Honor" .. currentHonorText
        uShared_PrintAll("CHAT_MSG_COMBAT_HONOR_GAIN", message)
        return
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    uHonor_OnHonorGain('You have been awarded 84 honor points.')
    uHonor_OnHonorGain('Player dies, honorable kill Rank: Private (8 Honor Points)')
    if event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        uHonor_OnHonorGain(...)
    end
end)

-- Filter out honor gains
local function uHonor_FiltertHonorGain(self, event, msg, ...)
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_HONOR_GAIN", uHonor_FiltertHonorGain)

