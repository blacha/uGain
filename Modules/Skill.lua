local addonName, uGain = ...

local Cache = {}
local LastCount = -1

local function uSkill_GetNumSkillLines()
    if C_SkillInfo and C_SkillInfo.GetNumSkillLines then
        return C_SkillInfo.GetNumSkillLines()
    elseif GetNumSkillLines then
        return GetNumSkillLines()
    end
    return 0
end

local function uSkill_GetSkillLineInfo(index)
    if C_SkillInfo and C_SkillInfo.GetSkillLineInfo then
        local data = C_SkillInfo.GetSkillLineInfo(index)
        if type(data) == "table" then
            local name = data.name or data.skillName
            local isHeader = false
            if data.isHeader ~= nil then
                isHeader = not not data.isHeader
            elseif data.header ~= nil then
                isHeader = not not data.header
            end
            local skillPoints = data.rank
            if skillPoints == nil then skillPoints = data.currentRank end
            if skillPoints == nil then skillPoints = data.skillRank end
            if skillPoints == nil then skillPoints = data.skillPoints end
            if skillPoints == nil then skillPoints = data.points end
            if skillPoints == nil then skillPoints = data.level end
            skillPoints = tonumber(skillPoints) or 0

            local maxPoints = data.maxRank
            if maxPoints == nil then maxPoints = data.maxLevel end
            if maxPoints == nil then maxPoints = data.skillMaxRank end
            if maxPoints == nil then maxPoints = data.maxPoints end
            maxPoints = tonumber(maxPoints) or 0

            return name, isHeader, skillPoints, maxPoints
        elseif data ~= nil then
            return data
        end
    end

    if GetSkillLineInfo then
        local a1, a2, a3, a4, a5, a6, a7 = GetSkillLineInfo(index)
        if type(a1) == "table" then
            local data = a1
            local name = data.name or data.skillName
            local isHeader = false
            if data.isHeader ~= nil then
                isHeader = not not data.isHeader
            elseif data.header ~= nil then
                isHeader = not not data.header
            end
            local skillPoints = data.rank
            if skillPoints == nil then skillPoints = data.currentRank end
            if skillPoints == nil then skillPoints = data.skillRank end
            if skillPoints == nil then skillPoints = data.skillPoints end
            if skillPoints == nil then skillPoints = data.points end
            if skillPoints == nil then skillPoints = data.level end
            skillPoints = tonumber(skillPoints) or 0

            local maxPoints = data.maxRank
            if maxPoints == nil then maxPoints = data.maxLevel end
            if maxPoints == nil then maxPoints = data.skillMaxRank end
            if maxPoints == nil then maxPoints = data.maxPoints end
            maxPoints = tonumber(maxPoints) or 0

            return name, isHeader, skillPoints, maxPoints
        elseif a1 ~= nil then
            return a1, not not a2, tonumber(a4) or 0, tonumber(a7) or 0
        end
    end

    return nil
end

local function uSkill_IsSupported()
    return (C_SkillInfo and C_SkillInfo.GetSkillLineInfo ~= nil)
        or GetSkillLineInfo ~= nil
end

local function uSkill_Report(index)
    if not uGain.IsModuleEnabled("skill") then
        return nil
    end

    local name, isHeader, skillPoints, maxPoints = uSkill_GetSkillLineInfo(index)
    if isHeader or not name then
        return nil
    end

    local last = Cache[name]
    if last == nil then
        Cache[name] = { points = skillPoints, maxPoints = maxPoints }
        return nil
    end

    if last.points == skillPoints then
        last.maxPoints = maxPoints
        return nil
    end

    local gain = skillPoints - last.points
    last.points = skillPoints
    last.maxPoints = maxPoints

    if gain <= 0 then
        return nil
    end

    local message = uGain.Color("+" .. gain, uGain.C.dark) .. " " ..
        uGain.Color(name, uGain.C.medium) .. " (" ..
        uGain.Color(skillPoints, uGain.C.dark) .. " / " ..
        uGain.Color(maxPoints, uGain.C.light) .. ")"

    uGain.PrintAll("CHAT_MSG_SKILL", message)
end

local function uSkill_LoadSkills()
    local count = uSkill_GetNumSkillLines()
    if count == 0 then
        return
    end

    LastCount = count
    for i = 1, count do
        local name, isHeader, skillPoints, maxPoints = uSkill_GetSkillLineInfo(i)
        if name and not isHeader then
            if not Cache[name] then
                Cache[name] = {}
            end
            Cache[name].points = skillPoints
            Cache[name].maxPoints = maxPoints
        end
    end
end

local function uSkill_ScanAndReport(self, event, msg, ...)
    local currentCount = uSkill_GetNumSkillLines()
    if currentCount > 0 then
        if LastCount == -1 then
            uSkill_LoadSkills()
            return
        end

        for i = 1, currentCount do
            uSkill_Report(i)
        end
        LastCount = currentCount
    end

    -- Fallback: If triggered by CHAT_MSG_SKILL and message contains skill increase,
    -- ensure any skill that was collapsed or missed is detected and reported.
    if event == "CHAT_MSG_SKILL" and msg and uGain.IsModuleEnabled("skill") then
        local pattern = uGain.GetSearchPattern("ERR_SKILL_UP_SI")
        if pattern then
            local name, rankStr = msg:match(pattern)
            if name and rankStr then
                local rank = tonumber(rankStr)
                if rank then
                    local last = Cache[name]
                    if not last then
                        Cache[name] = { points = rank, maxPoints = rank }
                        local message = uGain.Color("+1", uGain.C.dark) .. " " ..
                            uGain.Color(name, uGain.C.medium) .. " (" ..
                            uGain.Color(rank, uGain.C.dark) .. " / " ..
                            uGain.Color(rank, uGain.C.light) .. ")"
                        uGain.PrintAll("CHAT_MSG_SKILL", message)
                    elseif last.points ~= rank then
                        local gain = rank - last.points
                        last.points = rank
                        if gain > 0 then
                            local maxPoints = last.maxPoints or rank
                            local message = uGain.Color("+" .. gain, uGain.C.dark) .. " " ..
                                uGain.Color(name, uGain.C.medium) .. " (" ..
                                uGain.Color(rank, uGain.C.dark) .. " / " ..
                                uGain.Color(maxPoints, uGain.C.light) .. ")"
                            uGain.PrintAll("CHAT_MSG_SKILL", message)
                        end
                    end
                end
            end
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SKILL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:SetScript("OnEvent", uSkill_ScanAndReport)

-- Filter out default Blizzard skill gain messages when module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_SKILL", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("skill") or not uSkill_IsSupported() then
        return false -- let Blizzard show default message
    end
    return true -- suppress default message
end)

