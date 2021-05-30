local uExp_CurrentExp = 0
local uExp_CurrentLevel = 0

local C = {
    light = "|cFFABD6F4",
    medium = "|cFF03FFAC",
    dark = "|cFF02FEDC",
    resume = "|r"
}

local function uExp_FormatChatMessage(xpChange, currentXp, nextLevelXp, nextLevel)
    local remainingXp = nextLevelXp - currentXp
    local repsToNextLevel = floor(remainingXp / xpChange) + 1

    local xpGain = uC("+" .. uShared_StringComma(xpChange), C.dark) .. " XP - "
    local xpToNextLevel = uC(uShared_StringComma(currentXp), C.dark) .. " / " ..
                              uC(uShared_StringComma(nextLevelXp), C.light)
    local xpLeft = ",  " .. uC(uShared_StringComma(remainingXp), C.dark) .. " XP to lvl " .. uC(nextLevel, C.dark)
    local xpReps = " (" .. uC(uShared_StringComma(repsToNextLevel), C.dark) .. " reps)"

    return xpGain .. xpToNextLevel .. xpLeft .. xpReps
end

local function uExp_ScanAndReportExp()
    local currentXp = UnitXP("player")
    local nextLevelXp = UnitXPMax("player")
    local currentLevel = UnitLevel("player")

    local xpChange = currentXp - uExp_CurrentExp
    uExp_CurrentExp = currentXp

    -- Xp was reset skip..
    if (xpChange == 0) then
        return
    end

    -- Level change occured dont message anything
    if currentLevel ~= uExp_CurrentLevel then
        uExp_CurrentLevel = currentLevel 
        return
    end

    local chatMessage = uExp_FormatChatMessage(xpChange, currentXp, nextLevelXp, currentLevel + 1)
    uShared_PrintAll("CHAT_MSG_COMBAT_XP_GAIN", chatMessage)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, data)
    print("Hello")
    if event == "PLAYER_ENTERING_WORLD" then
        uExp_CurrentExp = UnitXP("player")
        uExp_CurrentLevel = UnitLevel("player")
        uExp_ScanAndReportExp()
    elseif event == "PLAYER_XP_UPDATE" then
        uExp_ScanAndReportExp()
    end
end)

-- Filter out XP Gains
local function uExp_FilterCombatXpGain(self, event, msg, ...)
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_XP_GAIN", uExp_FilterCombatXpGain)

-- "Greater Diskbat dies, you gain 142 experience (+71 Rested bounus)"
