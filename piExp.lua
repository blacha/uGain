local PiExp_CurrentExp = 0
local PiExp_CurrentLevel = 0

local PiAzerite_CurrentExp = 0;
local PiAzerite_CurrentLevel = 0

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

    local remainingXp = nextLevelXp - currentXp
    local xpGainPercent = (currentXp / nextLevelXp) * 100
    local xpRemainingPercent = (remainingXp / nextLevelXp) * 100

    local nextLevel = PiExp_CurrentLevel + 1
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

function PiExp_ScanAndReportAzerite()
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();

	if (not azeriteItemLocation) then
		return;
    end

    local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation);
	local currentXp, nextLevelXp = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation);
    currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation);

    local xpChange = currentXp - PiAzerite_CurrentExp
    PiAzerite_CurrentExp = currentXp

    if xpChange == 0  then
        return
    end

    if currentLevel ~= PiAzerite_LevelCurrent then
        PiAzerite_LevelCurrent = currentLevel
        return
    end

    local remainingXp = nextLevelXp - currentXp
    local xpGainPercent = (currentXp / nextLevelXp) * 100
    local xpRemainingPercent = (remainingXp / nextLevelXp) * 100

    local nextLevel = PiAzerite_LevelCurrent + 1
    local repsToNextLevel = (floor(remainingXp/xpChange)) + 1


    local chatMessage = PiExp_Colors.PiExp_dark .. "+" .. PiExp_stringComma(xpChange) ..
                        PiExp_Colors.PiExp_medium .. " Azerite" ..
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

    -- DEFAULT_CHAT_FRAME:AddMessage(string.format("GAL AZERITE_ITEM_EXPERIENCE_CHANGED old AP: %d new AP: %d - Level %d", oldExperienceAmount, newExperienceAmount, GetPowerLevel(azeriteItemLocation)))
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
eventFrame:RegisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, data)
    if event == "PLAYER_ENTERING_WORLD" then
        PiExp_CurrentExp = UnitXP("player")
        PiExp_CurrentLevel = UnitLevel("player")
        PiExp_ScanAndReportAzerite()
    elseif event == "PLAYER_XP_UPDATE" then
        PiExp_ScanAndReportExp()
    elseif event == "AZERITE_ITEM_EXPERIENCE_CHANGED" then
        PiExp_ScanAndReportAzerite()
    elseif event == "AZERITE_ITEM_POWER_LEVEL_CHANGED" then
        PiExp_ScanAndReportAzerite()
    end
end)
