local addonName, uGain = ...

local uXp_CurrentExp = UnitXP("player") or 0
local uXp_CurrentLevel = UnitLevel("player") or 0

local function uXp_FormatChatMessage(xpChange, currentXp, nextLevelXp, nextLevel)
    local remainingXp = nextLevelXp - currentXp
    if remainingXp < 0 then
        remainingXp = 0
    end

    local repsToNextLevel = 1
    if xpChange > 0 and remainingXp > 0 then
        repsToNextLevel = floor(remainingXp / xpChange) + 1
    end

    local xpGain = uGain.Color("+" .. uGain.StringComma(xpChange), uGain.C.dark) .. " XP - "
    local xpToNextLevel = uGain.Color(uGain.StringComma(currentXp), uGain.C.dark) .. " / " ..
                          uGain.Color(uGain.StringComma(nextLevelXp), uGain.C.light)
    local xpLeft = ",  " .. uGain.Color(uGain.StringComma(remainingXp), uGain.C.dark) .. " XP to lvl " .. uGain.Color(nextLevel, uGain.C.dark)
    local xpReps = " (" .. uGain.Color(uGain.StringComma(repsToNextLevel), uGain.C.dark) .. " reps)."

    return xpGain .. xpToNextLevel .. xpLeft .. xpReps
end

local function uXp_IsMaxLevel(level, nextLevelXp)
    if not nextLevelXp or nextLevelXp == 0 then
        return true
    end
    if IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel() then
        return true
    end
    if GetMaxLevelForPlayerExpansion and level >= GetMaxLevelForPlayerExpansion() then
        return true
    end
    return false
end

local function uXp_ScanAndReportExp()
    if not uGain.IsModuleEnabled("xp") then
        return
    end

    local currentLevel = UnitLevel("player")
    local currentXp = UnitXP("player")
    local nextLevelXp = UnitXPMax("player")

    -- Skip if at max level or max XP is 0
    if uXp_IsMaxLevel(currentLevel, nextLevelXp) then
        return
    end

    local xpChange = currentXp - uXp_CurrentExp
    uXp_CurrentExp = currentXp

    -- Skip if no change
    if xpChange == 0 then
        return
    end

    -- Level change occurred; skip reporting intermediate change
    if currentLevel ~= uXp_CurrentLevel then
        uXp_CurrentLevel = currentLevel
        return
    end

    local chatMessage = uXp_FormatChatMessage(xpChange, currentXp, nextLevelXp, currentLevel + 1)
    uGain.PrintAll("CHAT_MSG_COMBAT_XP_GAIN", chatMessage)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, unitTarget)
    if event == "PLAYER_ENTERING_WORLD" then
        uXp_CurrentExp = UnitXP("player") or 0
        uXp_CurrentLevel = UnitLevel("player") or 0
    elseif event == "PLAYER_XP_UPDATE" then
        if unitTarget == nil or unitTarget == "player" then
            uXp_ScanAndReportExp()
        end
    end
end)

-- Filter out default Blizzard combat XP gain messages if module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_XP_GAIN", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("xp") then
        return false -- let Blizzard show default message
    end
    return true -- suppress default message
end)
