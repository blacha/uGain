local C = {
    light = "|cffabd6f4",
    medium = "|cffffbb00",
    dark = "|cffd27edf",
    resume = "|r"
}

local HonorCurrencyId = 1901
local currentBgHonor = 0

local function uHonor_TrackBgHonor(honorGain)
    if (not C_PvP) or (not C_PvP.IsPVPMap()) then
        currentBgHonor = 0
        return ""
    end

    if (not honorGain) then
        return ""
    end

    local gain = tonumber(honorGain, 10)
    if (not gain) then
        return ""
    end

    currentBgHonor = currentBgHonor + gain
    return " - BG Honor " .. uC("+" .. uShared_StringComma(currentBgHonor), C.dark)
end

local function uHonor_OnHonorGain(text)
    local currentHonor = C_CurrencyInfo.GetCurrencyInfo(HonorCurrencyId).quantity or 0

    local currentHonorText = ""
    if currentHonor > 0 then
        currentHonorText = ", current " .. uC(uShared_StringComma(currentHonor), C.dark)
    end

    local honorGainPattern = uShared_GetSearchPattern("COMBATLOG_HONORGAIN")
    local honorGainMatch, _, playerName, _, honorGain = string.find(text, honorGainPattern)
    if (honorGainMatch) then
        local message = uC("+" .. uShared_StringComma(honorGain), C.dark) .. " Honor " .. uC(playerName, C.light) ..
                            " killed" .. currentHonorText .. uHonor_TrackBgHonor(honorGain) .. "."

        uShared_PrintAll("CHAT_MSG_COMBAT_HONOR_GAIN", message)
        return
    end

    local honorAwardPattern = uShared_GetSearchPattern("COMBATLOG_HONORAWARD")
    local honorAwardMatch, _, honorAward = string.find(text, honorAwardPattern)

    if (honorAwardMatch) then
        local message = uC("+" .. uShared_StringComma(honorAward), C.dark) .. " Honor" .. currentHonorText ..
                            uHonor_TrackBgHonor(honorAward) .. "."

        uShared_PrintAll("CHAT_MSG_COMBAT_HONOR_GAIN", message)
        return
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, eventName, ...)

    if eventName == "CHAT_MSG_COMBAT_HONOR_GAIN" then
        uHonor_OnHonorGain(...)
    else
        -- print("OtherEvent:" .. eventName)
        uHonor_TrackBgHonor()
    end
end)

-- Filter out honor gains
local function uHonor_FiltertHonorGain(self, event, msg, ...)
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_HONOR_GAIN", uHonor_FiltertHonorGain)

-- uHonor_OnHonorGain('You have been awarded 85 honor points.')
-- uHonor_OnHonorGain('Player dies, honorable kill Rank: Private (8 Honor Points)')