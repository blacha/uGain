local addonName, uGain = ...

local LastMoney = -1

-- Format money with gain (+) or loss (-) indicator
local function uCurrency_FormatMoneyGainLoss(amount)
    if amount < 0 then
        return string.format("%s-|r  %s", uGain.C.negative, uGain.FormatMoney(amount))
    end
    return string.format("%s+|r %s", uGain.C.gold, uGain.FormatMoney(amount))
end

local function uCurrency_ScanAndReport()
    local currentMoney = GetMoney()

    if not uGain.IsModuleEnabled("currency") then
        LastMoney = currentMoney
        return
    end

    if LastMoney > -1 then
        local moneyDiff = currentMoney - LastMoney
        if moneyDiff ~= 0 then
            local msg = uCurrency_FormatMoneyGainLoss(moneyDiff) .. " (current: " .. uGain.FormatMoney(currentMoney) .. ")"
            uGain.PrintAll("CHAT_MSG_MONEY", msg)
        end
    end

    LastMoney = currentMoney
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", uCurrency_ScanAndReport)

-- Filter out default Blizzard money messages when module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("currency") then
        return false -- let Blizzard show default message
    end
    return true -- suppress default message
end)
