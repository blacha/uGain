local addonName, uGain = ...

local CurrencyCache = {}
local LastReported = {}

local function uCurrency_GetCurrencyInfo(currencyID)
    if not currencyID then return nil end

    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if info and info.name and info.name ~= "" then
            return {
                name = info.name,
                quantity = info.quantity or 0,
                maxQuantity = info.maxQuantity or 0,
                maxWeeklyQuantity = info.maxWeeklyQuantity or 0,
                quantityEarnedThisWeek = info.quantityEarnedThisWeek or 0,
                quality = info.quality or 1,
            }
        end
    end

    if GetCurrencyInfo then
        local name, currentAmount, _, earnedThisWeek, weeklyMax, totalMax, _, rarity = GetCurrencyInfo(currencyID)
        if name and name ~= "" then
            return {
                name = name,
                quantity = currentAmount or 0,
                maxQuantity = totalMax or 0,
                maxWeeklyQuantity = weeklyMax or 0,
                quantityEarnedThisWeek = earnedThisWeek or 0,
                quality = rarity or 1,
            }
        end
    end

    return nil
end

local function uCurrency_GetCurrencyLink(currencyID, name, quality)
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyLink then
        local link = C_CurrencyInfo.GetCurrencyLink(currencyID, 0)
        if link and link ~= "" then
            return link
        end
    end

    if GetCurrencyLink then
        local link = GetCurrencyLink(currencyID, 0)
        if link and link ~= "" then
            return link
        end
    end

    local colorHex = uGain.C.white
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        colorHex = ITEM_QUALITY_COLORS[quality].hex or uGain.C.white
    end

    if currencyID and name then
        return string.format("%s|Hcurrency:%d|h[%s]|h|r", colorHex, currencyID, name)
    end

    return uGain.Color(name or "Currency", uGain.C.light)
end

local function uCurrency_FormatMessage(currencyID, diff, newQuantity, info)
    local name = info and info.name or "Currency"
    local quality = info and info.quality or 1
    local link = uCurrency_GetCurrencyLink(currencyID, name, quality)

    local gainText
    if diff < 0 then
        gainText = uGain.Color("-" .. uGain.StringComma(abs(diff)), uGain.C.negative)
    else
        gainText = uGain.Color("+" .. uGain.StringComma(diff), uGain.C.medium)
    end

    local totalText
    if info and info.maxQuantity and info.maxQuantity > 0 then
        totalText = uGain.Color(uGain.StringComma(newQuantity), uGain.C.light) .. "/" .. uGain.Color(uGain.StringComma(info.maxQuantity), uGain.C.white)
    else
        totalText = uGain.Color(uGain.StringComma(newQuantity), uGain.C.light)
    end

    local weeklyText = ""
    if info and info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0 then
        weeklyText = " - Weekly: " .. uGain.Color(uGain.StringComma(info.quantityEarnedThisWeek), uGain.C.light) .. "/" .. uGain.Color(uGain.StringComma(info.maxWeeklyQuantity), uGain.C.white)
    end

    return string.format("%s %s (Total: %s%s)", gainText, link, totalText, weeklyText)
end

local function uCurrency_ScanAll()
    local getListSize = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize or GetCurrencyListSize
    local getListInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo or GetCurrencyListInfo
    local getListLink = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListLink or GetCurrencyListLink
    local expandList = C_CurrencyInfo and C_CurrencyInfo.ExpandCurrencyList or ExpandCurrencyList

    if not getListSize or not getListInfo then
        return
    end

    local count = getListSize() or 0
    local toCollapse = {}
    local index = 0

    while index < count do
        index = index + 1
        local info = getListInfo(index)
        if info then
            local isHeader, isHeaderExpanded, quantity
            if type(info) == "table" then
                isHeader = info.isHeader
                isHeaderExpanded = info.isHeaderExpanded
                quantity = info.quantity or 0
            else
                local _, h, exp, _, _, q = getListInfo(index)
                isHeader = h
                isHeaderExpanded = exp
                quantity = q or 0
            end

            if isHeader then
                if not isHeaderExpanded and expandList then
                    table.insert(toCollapse, index)
                    expandList(index, true)
                    count = getListSize() or count
                end
            else
                local currencyID = nil
                if getListLink then
                    local link = getListLink(index)
                    if link then
                        if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyIDFromLink then
                            currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
                        end
                        if not currencyID then
                            currencyID = tonumber(link:match("|Hcurrency:(%d+)"))
                        end
                    end
                end

                if currencyID then
                    CurrencyCache[currencyID] = quantity
                end
            end
        end
    end

    if #toCollapse > 0 and expandList then
        for i = #toCollapse, 1, -1 do
            expandList(toCollapse[i], false)
        end
    end
end

local function uCurrency_OnDisplayUpdate(currencyID, quantity, quantityChange)
    if not uGain.IsModuleEnabled("currency") then
        if currencyID and quantity then
            CurrencyCache[currencyID] = quantity
        end
        return
    end

    if not currencyID then
        uCurrency_ScanAll()
        return
    end

    -- If honor module is active and tracking honor currency (1901), leave it to Modules/Honor.lua
    if currencyID == 1901 and uGain.IsModuleEnabled("honor") then
        if quantity then
            CurrencyCache[currencyID] = quantity
        end
        return
    end

    local info = uCurrency_GetCurrencyInfo(currencyID)
    if not info or not info.name or info.name == "" then
        return
    end

    local currentQuantity = info.quantity
    local prevQuantity = CurrencyCache[currencyID]
    local diff = 0

    if prevQuantity ~= nil then
        diff = currentQuantity - prevQuantity
    elseif quantityChange and quantityChange ~= 0 then
        diff = quantityChange
    end

    CurrencyCache[currencyID] = currentQuantity

    if diff ~= 0 then
        LastReported[currencyID] = { time = GetTime(), diff = diff }
        local msg = uCurrency_FormatMessage(currencyID, diff, currentQuantity, info)
        uGain.PrintAll("CHAT_MSG_CURRENCY", msg)
    end
end

local function uCurrency_OnChatMessage(text)
    if not uGain.IsModuleEnabled("currency") or not text then
        return
    end

    local currencyID = tonumber(text:match("|Hcurrency:(%d+)")) or tonumber(text:match("currency:(%d+)"))
    if not currencyID then
        return
    end

    -- Skip honor currency if honor module is enabled
    if currencyID == 1901 and uGain.IsModuleEnabled("honor") then
        return
    end

    -- Skip if already reported via CURRENCY_DISPLAY_UPDATE within 1 second
    local now = GetTime()
    if LastReported[currencyID] and (now - LastReported[currencyID].time < 1) then
        return
    end

    local qtyMatch = text:match("x%s*(%d+)") or text:match("(%d+)%s*x")
    local diff = tonumber(qtyMatch) or 1

    local info = uCurrency_GetCurrencyInfo(currencyID)
    local currentQuantity = info and info.quantity or ((CurrencyCache[currencyID] or 0) + diff)
    CurrencyCache[currencyID] = currentQuantity
    LastReported[currencyID] = { time = now, diff = diff }

    local msg = uCurrency_FormatMessage(currencyID, diff, currentQuantity, info)
    uGain.PrintAll("CHAT_MSG_CURRENCY", msg)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
eventFrame:RegisterEvent("CHAT_MSG_CURRENCY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CURRENCY_DISPLAY_UPDATE" then
        uCurrency_OnDisplayUpdate(...)
    elseif event == "CHAT_MSG_CURRENCY" then
        local text = ...
        uCurrency_OnChatMessage(text)
    elseif event == "PLAYER_ENTERING_WORLD" then
        uCurrency_ScanAll()
    end
end)

-- Filter out default Blizzard currency messages when currency module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_CURRENCY", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("currency") then
        return false -- let Blizzard show default message
    end

    -- If honor currency and honor module is enabled, suppress default message
    local currencyID = tonumber(msg and msg:match("|Hcurrency:(%d+)")) or tonumber(msg and msg:match("currency:(%d+)"))
    if currencyID == 1901 and uGain.IsModuleEnabled("honor") then
        return true
    end

    return true -- suppress default message
end)
