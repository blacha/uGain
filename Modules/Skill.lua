local addonName, uGain = ...

local Cache = {}
local LastCount = -1

local function uSkill_Report(index)
    if not uGain.IsModuleEnabled("skill") then
        return nil
    end

    if not GetSkillLineInfo then
        return nil
    end

    local name, isHeader, _, skillPoints, _, _, maxPoints = GetSkillLineInfo(index)
    if isHeader or not name then
        return nil
    end

    local last = Cache[name]
    if last == nil or last.points == skillPoints then
        return nil
    end

    local gain = skillPoints - last.points
    last.points = skillPoints

    local message = uGain.Color("+" .. gain, uGain.C.dark) .. " " ..
        uGain.Color(name, uGain.C.medium) .. " (" ..
        uGain.Color(skillPoints, uGain.C.dark) .. " / " ..
        uGain.Color(maxPoints, uGain.C.light) .. ")"

    uGain.PrintAll("CHAT_MSG_SKILL", message)
end

local function uSkill_LoadSkills()
    if not GetNumSkillLines or not GetSkillLineInfo then
        return
    end

    LastCount = GetNumSkillLines()
    for i = 1, LastCount do
        local name, isHeader, _, skillPoints = GetSkillLineInfo(i)
        if name and not isHeader then
            if not Cache[name] then
                Cache[name] = {}
            end
            Cache[name].points = skillPoints
        end
    end
end

local function uSkill_ScanAndReport()
    if not GetNumSkillLines then
        return
    end

    local currentCount = GetNumSkillLines()
    if currentCount ~= LastCount then
        return uSkill_LoadSkills()
    end

    for i = 1, currentCount do
        uSkill_Report(i)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SKILL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", uSkill_ScanAndReport)

-- Filter out default Blizzard skill gain messages when module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_SKILL", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("skill") then
        return false -- let Blizzard show default message
    end
    return true -- suppress default message
end)
