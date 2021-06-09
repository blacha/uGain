local C = {
    white = "|cffffffff",
    yellow = "|cffffff78",
    orange = "|cffff7831",
    red = "|cffff0000",
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

local factions = {}
local FactionCount = 0
local standingMax = 8
local standingMin = 1

local function uRep_StandingText(standingId)
    return uC(_G["FACTION_STANDING_LABEL" .. standingId], FACTION_BAR_COLORS[standingId])
end

local function uRep_ReportFaction(factionIndex)
    local name, _, standingId, barMin, barMax, currentRep, _, _, isHeader = GetFactionInfo(factionIndex)
    if isHeader then
        return nil
    end

    -- Unknwon faction ??
    local faction = factions[name]
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
    if diff > 0 then
        remaining = barMax - currentRep
        if standingId < standingMax then
            nextStandingId = standingId + 1
        end
    else
        remaining = currentRep - barMin
        if standingId > standingMin then
            nextStandingId = standingId - 1
        end
    end

    local change = abs(currentRep - faction.currentRep)
    local repetitions = math.ceil(remaining / change)

    local message = uC(string.format("%+d", change), C.orange) .. " " .. uC(name, C.yellow) .. ", " ..
                        uC(uShared_StringComma(remaining), C.orange) .. " more to " .. uRep_StandingText(nextStandingId) ..
                        " (" .. uC(uShared_StringComma(repetitions), C.orange) .. " reps)."

    faction.currentRep = currentRep
    faction.standingId = standingId
    uShared_PrintAll("CHAT_MSG_COMBAT_FACTION_CHANGE", message)
end

local function uRep_LoadFactions()
    FactionCount = GetNumFactions()
    for i = 1, FactionCount do
        local name, _, standingId, _, _, currentRep = GetFactionInfo(i)
        factions[name] = {}
        factions[name].currentRep = currentRep
        factions[name].standingId = standingId

    end
end

local function uRep_ScanAndReport()
    local factionCount = GetNumFactions()
    if (factionCount ~= FactionCount) then
        return uRep_LoadFactions()
    end

    for factionIndex = 1, factionCount do
        uRep_ReportFaction(factionIndex)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:SetScript("OnEvent", uRep_ScanAndReport)

local function uRep_FilterGain(self, event, msg, ...)
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", uRep_FilterGain)
