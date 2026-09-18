local addonName, uGain = ...

local FACTION_BAR_COLORS = {
    [1] = "|cfff8a3a8", -- Hated - Red
    [2] = "|cfff3c6a5", -- Hostile - Orange
    [3] = "|cffe5e1ab", -- Unfriendly - Yellow
    [4] = "|cffcccbd4", -- Neutral - Gray
    [5] = "|cff85b464", -- Friendly - Tan
    [6] = "|cff9cdcaa", -- Honored - Green
    [7] = "|cff96caf7", -- Revered - Blue
    [8] = "|cffbfb2f3"  -- Exalted - Purple
}

local Factions = {}
local FactionCount = 0
local StandingMax = 8
local StandingMin = 1

local function uRep_StandingText(standingId)
    local label = _G["FACTION_STANDING_LABEL" .. standingId] or ("Standing " .. standingId)
    return uGain.Color(label, FACTION_BAR_COLORS[standingId] or uGain.C.white)
end

local function uRep_GetNumFactions()
    if C_Reputation and C_Reputation.GetNumFactions then
        return C_Reputation.GetNumFactions() or 0
    elseif GetNumFactions then
        return GetNumFactions() or 0
    end
    return 0
end

local function uRep_GetFactionInfo(index)
    if C_Reputation and C_Reputation.GetFactionDataByIndex then
        local data = C_Reputation.GetFactionDataByIndex(index)
        if data then
            return data.name, data.description, data.reaction, data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding, data.atWarWith, data.canToggleAtWar, data.isHeader
        end
        return nil
    elseif GetFactionInfo then
        return GetFactionInfo(index)
    end
    return nil
end

local function uRep_ReportFaction(factionIndex)
    if not uGain.IsModuleEnabled("reputation") then
        return nil
    end

    local name, _, standingId, barMin, barMax, currentRep, _, _, isHeader = uRep_GetFactionInfo(factionIndex)
    if isHeader or not name then
        return nil
    end

    standingId = standingId or 1
    barMin = barMin or 0
    barMax = barMax or 0
    currentRep = currentRep or 0

    local faction = Factions[name]
    if not faction then
        Factions[name] = {
            currentRep = currentRep,
            standingId = standingId,
        }
        return nil
    end

    local diff = currentRep - faction.currentRep
    if diff == 0 then
        return nil
    end

    -- Standing rank changed!
    if standingId ~= faction.standingId then
        local message = "New standing with " .. uGain.Color(name, uGain.C.yellow) .. " is " .. uRep_StandingText(standingId) .. "!"
        uGain.PrintAll("CHAT_MSG_COMBAT_FACTION_CHANGE", message)
    end

    local colorChange = uGain.C.orange
    local remaining = 0
    local nextStandingId = standingId
    local isCapped = false

    if diff > 0 then
        if standingId >= StandingMax then
            isCapped = true
        else
            remaining = barMax - currentRep
            nextStandingId = standingId + 1
        end
    else
        colorChange = uGain.C.red
        if standingId <= StandingMin then
            isCapped = true
        else
            remaining = currentRep - barMin
            nextStandingId = standingId - 1
        end
    end

    local message = uGain.Color(string.format("%+d", diff), colorChange) .. " " .. uGain.Color(name, uGain.C.yellow)

    if isCapped then
        message = message .. " (" .. uRep_StandingText(standingId) .. " - Max)."
    else
        local change = abs(diff)
        local repetitions = (change > 0 and remaining > 0) and math.ceil(remaining / change) or 1
        message = message .. ", " .. uGain.Color(uGain.StringComma(remaining), uGain.C.orange) .. " more to " ..
            uRep_StandingText(nextStandingId) .. " (" .. uGain.Color(uGain.StringComma(repetitions), uGain.C.orange) .. " reps)."
    end

    faction.currentRep = currentRep
    faction.standingId = standingId
    uGain.PrintAll("CHAT_MSG_COMBAT_FACTION_CHANGE", message)
end

local function uRep_LoadFactions()
    FactionCount = uRep_GetNumFactions()

    for i = 1, FactionCount do
        local name, _, standingId, _, _, currentRep, _, _, isHeader = uRep_GetFactionInfo(i)
        if name and not isHeader then
            if not Factions[name] then
                Factions[name] = {}
            end
            Factions[name].currentRep = currentRep or 0
            Factions[name].standingId = standingId or 1
        end
    end
end

local function uRep_ScanAndReport()
    local currentFactionCount = uRep_GetNumFactions()
    if currentFactionCount ~= FactionCount then
        return uRep_LoadFactions()
    end

    for factionIndex = 1, currentFactionCount do
        uRep_ReportFaction(factionIndex)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:SetScript("OnEvent", uRep_ScanAndReport)

-- Filter out default Blizzard faction change messages when module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("reputation") then
        return false -- let Blizzard show default message
    end
    return true -- suppress default message
end)
