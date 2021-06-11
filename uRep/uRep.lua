local C = {
    white = "|cffffffff",
    yellow = "|cffffff78",
    orange = "|cffff7831",
    red = "|cfff8a3a8",
    resume = "|r"
}
local FACTION_BAR_COLORS = {
    [1] = "|cfff8a3a8", -- 36000 Hated - Red
    [2] = "|cfff3c6a5", -- 3000 Hostile - Orange
    [3] = "|cffe5e1ab", -- 3000 Unfriendly - Yellow
    [4] = "|cffcccbd4", -- 3000 Neutral - Gray
    [5] = "|cff85b464", -- 6000 Friendly - Tan
    [6] = "|cff9cdcaa", -- 12000 Honored - Green
    [7] = "|cff96caf7", -- 21000 Revered - Blue
    [8] = "|cffbfb2f3" -- 1000 Exalted - Purple
};

local Factions = {}
local FactionCount = 0
local StandingMax = 8
local StandingMin = 1

local function uRep_StandingText(standingId)
    return uC(_G["FACTION_STANDING_LABEL" .. standingId], FACTION_BAR_COLORS[standingId])
end

local function uRep_ReportFaction(factionIndex)
    local name, _, standingId, barMin, barMax, currentRep, _, _, isHeader = GetFactionInfo(factionIndex)
    if isHeader then
        return nil
    end

    -- Unknwon faction ??
    local faction = Factions[name]
    if not faction then
        return nil
    end

    -- Rep has not changed
    local diff = currentRep - faction.currentRep
    if diff == 0 then
        return nil
    end

    -- Changed standing between levels!
    if standingId ~= faction.standingId then
        local message = "New standing with " .. uC(name, C.yellow) .. " is " .. uRep_StandingText(standingId) .. "!"
        uShared_PrintAll("CHAT_MSG_COMBAT_FACTION_CHANGE", message)
    end

    local remaining
    local nextStandingId = standingId
    local colorChange = C.orange

    if diff > 0 then
        remaining = barMax - currentRep
        if standingId < StandingMax then
            nextStandingId = standingId + 1
        end
    else
        colorChange = C.red
        remaining = currentRep - barMin
        if standingId > StandingMin then
            nextStandingId = standingId - 1
        end
    end

    local change = abs(currentRep - faction.currentRep)
    local repetitions = math.ceil(remaining / change)

    local message = uC(string.format("%+d", diff), colorChange) .. " " .. uC(name, C.yellow) .. ", " ..
                        uC(uShared_StringComma(remaining), C.orange) .. " more to " .. uRep_StandingText(nextStandingId) ..
                        " (" .. uC(uShared_StringComma(repetitions), C.orange) .. " reps)."

    faction.currentRep = currentRep
    faction.standingId = standingId
    uShared_PrintAll("CHAT_MSG_COMBAT_FACTION_CHANGE", message)
end

local function uRep_LoadFactions()
    local oldFactionCount = FactionCount
    FactionCount = GetNumFactions()

    for i = 1, FactionCount do
        local name, _, standingId, _, barMax, currentRep, _, _, isHeader = GetFactionInfo(i)
        local oldFaction = Factions[name]
        if oldFaction == nil and oldFactionCount > 0 and (not isHeader) then
            local factionChangeMessage = "Faction " .. uC(name, C.yellow) .. " found at " .. " " ..
                                             uC(uShared_StringComma(currentRep), C.orange) .. " / " ..
                                             uC(uShared_StringComma(barMax), C.yellow) .. " (" ..
                                             uRep_StandingText(standingId) .. ")."
            uShared_PrintAll("CHAT_MSG_COMBAT_FACTION_CHANGE", factionChangeMessage)
        end
        Factions[name] = {}
        Factions[name].currentRep = currentRep
        Factions[name].standingId = standingId
    end
end

local function uRep_ScanAndReport()
    local currentFactionCount = GetNumFactions()
    if (currentFactionCount ~= FactionCount) then
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

ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", function()
    return true
end)
