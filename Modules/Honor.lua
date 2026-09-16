local addonName, uGain = ...

local HonorCurrencyId = 1901
local currentBgHonor = 0

local function uHonor_TrackBgHonor(honorGain)
    if not uGain.IsModuleEnabled("bgHonor") then
        return ""
    end

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
    return " - BG Honor " .. uGain.Color("+" .. uGain.StringComma(currentBgHonor), uGain.C.dark)
end

local function uHonor_GetCurrent()
    -- Classic Era (Expansion 0): Honor is tracked via session/day contribution points
    if GetAccountExpansionLevel and GetAccountExpansionLevel() == 0 and GetPVPSessionStats then
        local _, sessionHonor = GetPVPSessionStats()
        if sessionHonor then
            return sessionHonor
        end
    end

    -- TBC / Wrath / Cata currency API
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local honorCurrency = C_CurrencyInfo.GetCurrencyInfo(HonorCurrencyId)
        if honorCurrency and honorCurrency.name and honorCurrency.name ~= "" then
            return honorCurrency.quantity or 0
        end
    end

    -- Fallback for Classic Era or clients without currency info
    if GetPVPSessionStats then
        local _, sessionHonor = GetPVPSessionStats()
        return sessionHonor or 0
    end

    return 0
end

local function uHonor_OnHonorGain(text)
    if not uGain.IsModuleEnabled("honor") then
        return
    end

    local currentHonor = uHonor_GetCurrent()
    local currentHonorText = ""
    if currentHonor and currentHonor > 0 then
        currentHonorText = ", current " .. uGain.Color(uGain.StringComma(currentHonor), uGain.C.dark)
    end

    local honorGainPattern = uGain.GetSearchPattern("COMBATLOG_HONORGAIN")
    if honorGainPattern then
        local honorGainMatch, _, playerName, unitRank, honorGain = string.find(text, honorGainPattern)
        if honorGainMatch then
            local message = uGain.Color("+" .. uGain.StringComma(honorGain), uGain.C.dark) .. " Honor "

            if GetAccountExpansionLevel and GetAccountExpansionLevel() == 0 and unitRank then
                message = message .. unitRank .. " "
            end

            message = message .. uGain.Color(playerName, uGain.C.light) .. " killed " ..
                currentHonorText .. uHonor_TrackBgHonor(honorGain) .. "."

            uGain.PrintAll("CHAT_MSG_COMBAT_HONOR_GAIN", message)
            return
        end
    end

    local honorAwardPattern = uGain.GetSearchPattern("COMBATLOG_HONORAWARD")
    if honorAwardPattern then
        local honorAwardMatch, _, honorAward = string.find(text, honorAwardPattern)
        if honorAwardMatch then
            local message = uGain.Color("+" .. uGain.StringComma(honorAward), uGain.C.dark) .. " Honor" ..
                currentHonorText .. uHonor_TrackBgHonor(honorAward) .. "."

            uGain.PrintAll("CHAT_MSG_COMBAT_HONOR_GAIN", message)
            return
        end
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
        uHonor_TrackBgHonor()
    end
end)

-- Filter out default combat honor gain message when honor module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_HONOR_GAIN", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("honor") then
        return false -- let Blizzard show default message
    end
    return true -- suppress default message
end)
