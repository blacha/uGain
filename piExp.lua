local PiExp_CurrentExp = 0
local PiExp_CurrentLevel = 0

local PiExp_Colors = {
    light = "|cFFABD6F4",
    medium = "|cFF03FFAC",
    dark = "|cFF02FEDC",
    resume = "|r",
}

-- Convert a number to a formated number
-- eg 1023 -> 1,023
function PiExp_StringComma(number)
    while true do
        number, k = string.gsub( number, "^(-?%d+)(%d%d%d)", "%1,%2" )
        if ( k == 0 ) then break end
    end

    return number
end

-- Find all windwos with CombatXPGain and print our messages there
function PiExp_PrintToXPWindow(message)
    local success = false
    for i = 1, NUM_CHAT_WINDOWS do
        frame = _G[ "ChatFrame" .. i ]:IsEventRegistered( "CHAT_MSG_COMBAT_XP_GAIN" ) and _G[ "ChatFrame" .. i ]
        if frame or ( i == NUM_CHAT_WINDOWS and not success ) then
            frame:AddMessage(message)
            success = true
        end
    end
end

function PiExp_FormatChatMessage(xpType, xpChange, currentXp,  nextLevelXp, nextLevel)
    local remainingXp = nextLevelXp - currentXp
    local xpGainPercent = (currentXp / nextLevelXp) * 100
    local xpRemainingPercent = (remainingXp / nextLevelXp) * 100

    local repsToNextLevel = (floor(remainingXp/xpChange)) + 1

    return PiExp_Colors.dark .. "+" .. PiExp_StringComma(xpChange) ..
            PiExp_Colors.medium .. " " .. xpType ..
            PiExp_Colors.light .. " - " ..
            PiExp_Colors.light .. PiExp_StringComma(currentXp) ..
            PiExp_Colors.light .. " / " ..
            PiExp_Colors.light .. PiExp_StringComma(nextLevelXp) ..
            PiExp_Colors.light .. " to lvl " ..
            PiExp_Colors.dark .. nextLevel  ..
            PiExp_Colors.light .. " (" .. PiExp_Colors.medium .. PiExp_StringComma(remainingXp) .. PiExp_Colors.light .. " " .. xpType .. " left)" ..
            PiExp_Colors.light .. " (" .. PiExp_Colors.medium .. PiExp_StringComma(repsToNextLevel) .. PiExp_Colors.light .. " reps)"
end

function PiExp_ScanAndReportExp()

    local currentXp = UnitXP("player")
    local nextLevelXp = UnitXPMax("player")
    local currentLevel = UnitLevel("player")

    local xpChange = currentXp - PiExp_CurrentExp
    PiExp_CurrentExp = currentXp

    -- Xp was reset skip..
    if (xpChange == 0) then
        return
    end

    -- Level change occured dont message anything
    if currentLevel ~= PiExp_CurrentLevel then
        PiExp_CurrentLevel = currentLevel
        return
    end

    local chatMessage = PiExp_FormatChatMessage("XP", xpChange, currentXp, nextLevelXp, currentLevel + 1)
    -- DEFAULT_CHAT_FRAME:AddMessage(chatMessage)
    PiExp_PrintToXPWindow(chatMessage)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")


eventFrame:SetScript("OnEvent", function(self, event, data)
    if event == "PLAYER_ENTERING_WORLD" then
        PiExp_CurrentExp = UnitXP("player")
        PiExp_CurrentLevel = UnitLevel("player")
        PiExp_ScanAndReportExp()
    elseif event == "PLAYER_XP_UPDATE" then
        PiExp_ScanAndReportExp()
    end
end)

-- Filter out XP Gains
function PiExp_FilterCombatXpGain(self, event, msg, ...)
    local xpGained = string.match(msg, "ou gain (%d+) experience")
    if xpGained then
        return true
    else
        return false
    end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_XP_GAIN", PiExp_FilterCombatXpGain)

