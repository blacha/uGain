local LastMoney = -1

local C = {
    gold = "|cffffd700",
    silver = "|cffc7c7cf",
    copper = "|cffeda55f",
    negative ="|cffe25e6f",
    resume = "|r"
}

-- Format money as gg.ss.cc
-- eg 10.32.12 = 10g 32s 12c
local function uCurrency_formatMoney(amount)
    local value = abs(amount)
    local gold = floor(value * 0.0001)
    local silver = floor(mod(value * 0.01, 100))
    local copper = floor(mod(value, 100))

    return format('%s%d|r.%s%02d|r.%s%02d|r', C.gold, gold, C.silver, silver, C.copper, copper)

end

-- Include a + or - to show money is gained or lost
local function uCurrency_formatMoneyGainLoss(amount)
    if amount < 0 then
        return format("%s-|r  %s", C.negative, uCurrency_formatMoney(amount))
    end

    return format("%s+|r %s", C.gold, uCurrency_formatMoney(amount))
end

local function uCurrency_scanAndReport()
    local currentMoney = GetMoney()
    if LastMoney > -1 then
        local moneyDiff = currentMoney - LastMoney
        uShared_PrintAll("CHAT_MSG_MONEY", uCurrency_formatMoneyGainLoss(moneyDiff) .. " (current: " .. uCurrency_formatMoney(currentMoney) .. ")")
    end
    LastMoney = currentMoney
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", uCurrency_scanAndReport)

-- Filter out moeny gains
local function uCurrency_FilterChatMessage(self, event, msg, ...)
    return true
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", uCurrency_FilterChatMessage)