local addonName, uGain = ...

-- Get bag space: free slots and total capacity across standard bags
local function uLoot_GetBagSlots()
    local totalFree = 0
    local totalSlots = 0
    local numBags = NUM_BAG_SLOTS or NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4

    local getSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local getFree = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots

    for bag = 0, numBags do
        if getSlots and getFree then
            local slots = getSlots(bag) or 0
            local free = getFree(bag) or 0
            totalSlots = totalSlots + slots
            totalFree = totalFree + free
        end
    end

    return totalFree, totalSlots
end

-- Get total item count in bags and number of stacks occupied
local function uLoot_GetItemDetails(itemLink)
    local getItemCount = C_Item and C_Item.GetItemCount or GetItemCount
    local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local itemID = tonumber(itemLink:match("item:(%d+)"))

    local currentCount = 0
    if getItemCount then
        currentCount = getItemCount(itemID or itemLink, false) or 0
    end

    local maxStack = 1
    if C_Item and C_Item.GetItemMaxStackSizeByID and itemID then
        local stack = C_Item.GetItemMaxStackSizeByID(itemID)
        if stack and stack > 0 then
            maxStack = stack
        end
    elseif getItemInfo then
        local _, _, _, _, _, _, _, stackCount = getItemInfo(itemLink)
        if stackCount and stackCount > 0 then
            maxStack = stackCount
        end
    end

    local stacks = tostring(currentCount)
    if maxStack > 1 then
        local ratio = currentCount / maxStack
        stacks = string.format("%.2f", ratio)
        stacks = string.gsub(stacks, "%.?0+$", "")
    end

    return currentCount, stacks
end

-- Parse player's own loot from Blizzard chat text
local function uLoot_ParseLootMessage(text)
    if not text then return nil end

    local itemLink = text:match("(|c.-|Hitem:.-|h%[.-%]|h|r)") or text:match("(|c.-|Hitem:.-|h|r)") or text:match("(|Hitem:.-|h%[.-%]|h)")
    if not itemLink then
        return nil
    end

    if not itemLink:match("^|c") then
        itemLink = "|cffffffff" .. itemLink .. "|r"
    end

    local isSelfLoot = false
    local quantity = 1

    local selfMultiKeys = {
        "LOOT_ITEM_SELF_MULTIPLE",
        "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
        "LOOT_ITEM_CREATED_SELF_MULTIPLE",
        "LOOT_ITEM_REFUND_MULTIPLE",
        "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
    }
    for _, key in ipairs(selfMultiKeys) do
        local pat = uGain.GetSearchPattern(key)
        if pat and string.find(text, pat) then
            isSelfLoot = true
            local match, _, c1, c2 = string.find(text, pat)
            local q = tonumber(c1) or tonumber(c2)
            if not q then
                q = text:match("|h|r%s*x%s*(%d+)") or text:match("|h%s*x%s*(%d+)") or text:match("x(%d+)%s*%.?$")
            end
            quantity = tonumber(q) or 1
            break
        end
    end

    if not isSelfLoot then
        local selfSingleKeys = {
            "LOOT_ITEM_SELF",
            "LOOT_ITEM_PUSHED_SELF",
            "LOOT_ITEM_CREATED_SELF",
            "LOOT_ITEM_REFUND",
            "LOOT_ITEM_BONUS_ROLL_SELF",
        }
        for _, key in ipairs(selfSingleKeys) do
            local pat = uGain.GetSearchPattern(key)
            if pat and string.find(text, pat) then
                isSelfLoot = true
                quantity = 1
                break
            end
        end
    end

    -- Fallback: check if the message starts with self-loot prefixes (handles formatting/punctuation variations)
    if not isSelfLoot then
        local otherPlayerPatterns = {
            "LOOT_ITEM",
            "LOOT_ITEM_MULTIPLE",
            "LOOT_ITEM_PUSHED",
            "LOOT_ITEM_PUSHED_MULTIPLE",
            "CREATED_ITEM",
            "CREATED_ITEM_MULTIPLE",
        }
        local isOtherPlayer = false
        for _, key in ipairs(otherPlayerPatterns) do
            local pat = uGain.GetSearchPattern(key)
            if pat and string.find(text, pat) then
                isOtherPlayer = true
                break
            end
        end

        if not isOtherPlayer then
            local checkPrefixes = { "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_CREATED_SELF" }
            for _, key in ipairs(checkPrefixes) do
                local selfString = _G[key]
                if selfString then
                    local prefix = selfString:match("^(.-)%%%d?%$?s")
                    if prefix and prefix ~= "" then
                        local escapedPrefix = prefix:gsub("([%^%(%)%.%[%]%*%+%-%?])", "%%%1")
                        if string.find(text, escapedPrefix) then
                            isSelfLoot = true
                            local q = text:match("|h|r%s*x%s*(%d+)") or text:match("|h%s*x%s*(%d+)") or text:match("x(%d+)%s*%.?$")
                            quantity = tonumber(q) or 1
                            break
                        end
                    end
                end
            end
        end
    end

    if isSelfLoot then
        return itemLink, quantity
    end

    return nil
end

-- Format message: +X [item] (:currentItemCount S: :currentNumberOfStacks, F: :bagSlotsFree/:bagSlotTotal)
local function uLoot_FormatChatMessage(itemLink, quantity)
    local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if getItemInfo and (itemID or itemLink) then
        local _, canonicalLink = getItemInfo(itemID or itemLink)
        if canonicalLink and canonicalLink ~= "" then
            itemLink = canonicalLink
        end
    end

    local currentCount, stacks = uLoot_GetItemDetails(itemLink)
    local freeSlots, totalSlots = uLoot_GetBagSlots()

    local freeColor = uGain.C.green
    if freeSlots < 4 then
        freeColor = uGain.C.red
    elseif freeSlots < 10 then
        freeColor = uGain.C.orange
    end

    local gainText = uGain.Color("+" .. uGain.StringComma(quantity), uGain.C.green)
    local countText = uGain.Color(uGain.StringComma(currentCount), uGain.C.green)
    local stacksText = uGain.Color(uGain.StringComma(stacks), uGain.C.green)
    local freeText = uGain.Color(uGain.StringComma(freeSlots), freeColor)
    local totalText = uGain.Color(uGain.StringComma(totalSlots), uGain.C.lightGreen)

    return string.format("%s %s (Total: %s - Stacks: %s - Bags: %s/%s)",
        gainText,
        itemLink,
        countText,
        stacksText,
        freeText,
        totalText
    )
end

local function uLoot_OnLoot(text)
    if not uGain.IsModuleEnabled("loot") then
        return
    end

    local itemLink, quantity = uLoot_ParseLootMessage(text)
    if not itemLink then
        return
    end

    local message = uLoot_FormatChatMessage(itemLink, quantity)
    uGain.PrintAll("CHAT_MSG_LOOT", message)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:SetScript("OnEvent", function(self, event, text)
    if event == "CHAT_MSG_LOOT" then
        uLoot_OnLoot(text)
    end
end)

-- Filter out default Blizzard loot messages when loot module is enabled
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", function(self, event, msg, ...)
    if not uGain.IsModuleEnabled("loot") then
        return false -- let Blizzard show default message
    end

    if uLoot_ParseLootMessage(msg) then
        return true -- suppress only player self-loot message
    end

    return false -- allow other loot messages (e.g. party/raid) through
end)

-- Add Stack Size to item tooltips (for stackable items with maxStack > 1)
local function uLoot_AddStackSizeToTooltip(tooltip, data)
    if not uGain.IsModuleEnabled("loot") then
        return
    end

    local itemLink
    if tooltip and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        itemLink = link
    end

    if not itemLink and data and data.id then
        local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
        if getItemInfo then
            itemLink = select(2, getItemInfo(data.id))
        end
    end

    if not itemLink then
        return
    end

    local maxStack = 1
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if C_Item and C_Item.GetItemMaxStackSizeByID and itemID then
        maxStack = C_Item.GetItemMaxStackSizeByID(itemID) or 1
    else
        local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
        if getItemInfo then
            local _, _, _, _, _, _, _, stackCount = getItemInfo(itemLink)
            if stackCount and stackCount > 0 then
                maxStack = stackCount
            end
        end
    end

    if maxStack and maxStack > 1 then
        -- Prevent duplicate line on tooltip refresh
        local tooltipName = tooltip.GetName and tooltip:GetName()
        if tooltipName and tooltip.NumLines then
            for i = 1, tooltip:NumLines() do
                local line = _G[tooltipName .. "TextLeft" .. i]
                if line and line.GetText and line:GetText() and string.find(line:GetText(), "Stack Size:") then
                    return
                end
            end
        end

        tooltip:AddLine("Stack Size: " .. uGain.Color(tostring(maxStack), uGain.C.green))
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, uLoot_AddStackSizeToTooltip)
else
    if GameTooltip then
        GameTooltip:HookScript("OnTooltipSetItem", uLoot_AddStackSizeToTooltip)
    end
    if ItemRefTooltip then
        ItemRefTooltip:HookScript("OnTooltipSetItem", uLoot_AddStackSizeToTooltip)
    end
end

