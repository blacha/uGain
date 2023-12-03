local Cache = {}
local LastCount = -1

local C = {
    light = "|cffabd6f4",
    medium = "|cffffbb00",
    dark = "|cffd27edf",
    resume = "|r"
}


local function uSkill_Report(index)
    local name, isHeader, _, skillPoints, _, _, maxPoints = GetSkillLineInfo(index)
    if isHeader then
        return nil
    end
    local last = Cache[name]

    if last == nil or last.points == skillPoints then
        return nil
    end

    local gain = skillPoints - last.points
    last.points = skillPoints

    local message = uC("+" ..gain, C.dark) .. " " ..uC(name, C.medium) .. " " .. "( " .. uC(skillPoints, C.dark) .. " / " .. uC(maxPoints, C.light) .. " )"

    uShared_PrintAll("CHAT_MSG_SKILL", message)
end

local function uSkill_LoadSkills()
    LastCount = GetNumSkillLines()

    for i = 1, LastCount do
        local name, isHeader, _, skillPoints, _, _, _ = GetSkillLineInfo(i)
        if not isHeader then
            Cache[name] = {}
            Cache[name].points = skillPoints
        end
    end
end


local function uRep_ScanAndReport()
    local currentCount = GetNumSkillLines()
    if (currentCount ~= LastCount) then
        return uSkill_LoadSkills()
    end

    for i = 1, currentCount do
        uSkill_Report(i)
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SKILL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", uRep_ScanAndReport)

-- Filter out honor gains
local function uSkill_FilterChatMessage(self, event, msg, ...)
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SKILL", uSkill_FilterChatMessage)