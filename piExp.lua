local PiExp_ExpCurrent = 0
local PiExp_LevelCurrent = 0

local PiExp_Colors = {
    PiExp_light = "|cffffc2a1",
    PiExp_medium = "|cffff9a63",
    PiExp_dark = "|cffff7831",
    PiExp_resume = "|r",
}

function PiExp_stringComma( number )

    while true do
        number, k = string.gsub( number, "^(-?%d+)(%d%d%d)", "%1,%2" )
        if ( k == 0 ) then break end
    end

    return number

end

function PiExp_ScanAndReport()

    local currentXp = UnitXP("player")
    local nextLevelXp = UnitXPMax("player")
    local currentLevel = UnitLevel("player")

    local xpChange = currentXp - PiExp_ExpOld
    PiExp_ExpOld = currentXp

    -- Xp was reset skip..
    if (xpChange == 0) then
        return
    end

    -- Level change occured dont message anything
    if currentLevel ~= PiExp_LevelCurrent then
        PiExp_LevelCurrent = currentLevel
        return
    end

    local remainingXp = nextLevelXp - currentXp
    local xpGainPercent = (currentXp / nextLevelXp) * 100
    local xpRemainingPercent = (remainingXp / nextLevelXp) * 100

    local nextLevel = PiExp_LevelCurrent + 1
    local repsToNextLevel = (floor(remainingXp/xpChange)) + 1


      local chatMessage = PiExp_Colors.PiExp_dark .. "+" .. PiExp_stringComma(xpChange) ..
                        PiExp_Colors.PiExp_medium .. " XP" ..
                        PiExp_Colors.PiExp_light .. " - " ..
                        PiExp_Colors.PiExp_dark .. PiExp_stringComma(currentXp) ..
                        PiExp_Colors.PiExp_light .. " / " ..
                        PiExp_Colors.PiExp_dark .. PiExp_stringComma(nextLevelXp) ..
                        PiExp_Colors.PiExp_light .. " to " ..
                        PiExp_Colors.PiExp_medium.."lvl " ..
                        PiExp_Colors.PiExp_dark .. nextLevel  ..
                        PiExp_Colors.PiExp_light .. " (" .. PiExp_Colors.PiExp_dark .. PiExp_stringComma(remainingXp) .. PiExp_Colors.PiExp_light .. " xp left)" ..
                        PiExp_Colors.PiExp_light .. " (" .. PiExp_Colors.PiExp_dark .. PiExp_stringComma(repsToNextLevel) .. PiExp_Colors.PiExp_light .. " reps)"

    DEFAULT_CHAT_FRAME:AddMessage(chatMessage)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, data)
    if event == "PLAYER_ENTERING_WORLD" then
        PiExp_ExpOld = UnitXP("player")
        PiExp_LevelCurrent = UnitLevel("player")
    else
        PiExp_ScanAndReport()
    end
end)
