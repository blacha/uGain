local LastMoney = -1

local C = {
    gold = "|cffffd700",
    silver = "|cffc7c7cf",
    copper = "|cffeda55f",
    negative ="|cffe25e6f",
    resume = "|r"
}

local function uMoney_formatMoney(amount)
    local value = abs(amount)
    local gold = floor(value * 0.0001)
    local silver = floor(mod(value * 0.01, 100))
    local copper = floor(mod(value, 100))

    if amount > 0 then
        return format('%s+|r %s%d|r.%s%02d|r.%s%02d|r', C.gold, C.gold, gold, C.silver, silver, C.copper, copper)
    end

    return format('%s-|r %s%d|r.%s%02d|r.%s%02d|r', C.negative, C.gold, gold, C.silver, silver, C.copper, copper)

end


local function uMoney_scanAndReport(event)
    local currentMoney = GetMoney()
    if LastMoney > 0 then
        local moneyDiff = currentMoney - LastMoney
        uShared_PrintAll("CHAT_MSG_MONEY", uMoney_formatMoney(moneyDiff))
    end
    LastMoney = currentMoney
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", uMoney_scanAndReport)

-- Filter out honor gains
local function uMoney_FilterChatMessage(self, event, msg, ...)
    uShared_PrintAll("CHAT_MSG_MONEY", "hello")
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", uMoney_FilterChatMessage)