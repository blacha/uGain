local uExp_CurrentExp = 0
local uExp_CurrentLevel = 0

local uExpC = {
    light = "|cFFABD6F4",
    medium = "|cFF03FFAC",
    dark = "|cFF02FEDC",
    resume = "|r",
}

-- Convert a number to a formated number
-- eg 1023 -> 1,023
local function uExp_StringComma(number)
    local length = 0
    while true do
        number, length = string.gsub( number, "^(-?%d+)(%d%d%d)", "%1,%2" )
        if ( length == 0 ) then break end
    end

    return number
end

-- Find all windwos with CombatXPGain and print our messages there
local function uExp_PrintToXPWindow(message)
    local success = false
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G[ "ChatFrame" .. i ]:IsEventRegistered( "CHAT_MSG_COMBAT_XP_GAIN" ) and _G[ "ChatFrame" .. i ]
        if frame or ( i == NUM_CHAT_WINDOWS and not success ) then
            frame:AddMessage(message)
            success = true
        end
    end
end

local function uExp_FormatChatMessage(xpType, xpChange, currentXp,  nextLevelXp, nextLevel)
    local remainingXp = nextLevelXp - currentXp
    -- local xpGainPercent = (currentXp / nextLevelXp) * 100
    -- local xpRemainingPercent = (remainingXp / nextLevelXp) * 100

    local repsToNextLevel = floor(remainingXp/xpChange) + 1

    local xpRemainingTxt = uExp_StringComma(remainingXp)
    local repsTxt = uExp_StringComma(repsToNextLevel)

    return uExpC.dark .. "+" .. uExp_StringComma(xpChange) ..
            uExpC.medium .. " " .. xpType ..
            uExpC.light .. " - " ..
            uExpC.light .. uExp_StringComma(currentXp) ..
            uExpC.light .. " / " ..
            uExpC.light .. uExp_StringComma(nextLevelXp) ..
            uExpC.light .. " to lvl " ..
            uExpC.dark .. nextLevel  ..
            uExpC.light .. " (" .. uExpC.medium .. xpRemainingTxt .. uExpC.light .. " " .. xpType .. " left)" ..
            uExpC.light .. " (" .. uExpC.medium .. repsTxt .. uExpC.light .. " reps)"
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

    local chatMessage = uExp_FormatChatMessage("XP", xpChange, currentXp, nextLevelXp, currentLevel + 1)
    -- DEFAULT_CHAT_FRAME:AddMessage(chatMessage)
    uExp_PrintToXPWindow(chatMessage)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


eventFrame:SetScript("OnEvent", function(self, event, data)
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
    local xpGained = string.match(msg, "ou gain (%d+) experience")
    if xpGained then
        return true
    else
        return false
    end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_XP_GAIN", uExp_FilterCombatXpGain)

