local addonName, uGain = ...

-- Module metadata for UI and slash commands
local MODULES = {
    { key = "xp",         label = "Experience (XP) gains and reps to level",        cmd = "xp" },
    { key = "honor",      label = "Honor gains and kill messages",                  cmd = "honor" },
    { key = "bgHonor",    label = "Battleground cumulative honor tracker",          cmd = "bghonor" },
    { key = "reputation", label = "Reputation gains and reps to next standing",    cmd = "rep" },
    { key = "skill",      label = "Skill point gains",                              cmd = "skill" },
    { key = "currency",   label = "Money / Currency changes",                       cmd = "currency" },
}

local checkboxes = {}

-- Create Blizzard Interface Options Panel
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "uGainOptionsPanel", UIParent)
    panel.name = "uGain"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("uGain Options")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Configure which chat events uGain should filter and replace with styled messages.")

    local yOffset = -60
    for _, mod in ipairs(MODULES) do
        local cb = CreateFrame("CheckButton", "uGain_Check_" .. mod.key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        _G[cb:GetName() .. "Text"]:SetText(mod.label)
        cb.moduleKey = mod.key

        cb:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            uGain.SetModuleEnabled(self.moduleKey, isChecked)
        end)

        checkboxes[mod.key] = cb
        yOffset = yOffset - 32
    end

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 20, yOffset - 16)
    note:SetText("Tip: You can also use /ugain <module> or /ugain status in chat.")

    panel:SetScript("OnShow", function()
        for _, mod in ipairs(MODULES) do
            if checkboxes[mod.key] then
                checkboxes[mod.key]:SetChecked(uGain.IsModuleEnabled(mod.key))
            end
        end
    end)

    -- Register with Blizzard Settings API (Modern & Classic fallback)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        category.ID = panel.name
        Settings.RegisterAddOnCategory(category)
        panel.settingsCategoryID = category.ID
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    return panel
end

local optionsPanel = CreateOptionsPanel()

-- Helper to open options panel
local function OpenOptions()
    if Settings and Settings.OpenToCategory and optionsPanel.settingsCategoryID then
        Settings.OpenToCategory(optionsPanel.settingsCategoryID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    end
end

-- Slash command handling
local function PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage(uGain.Color("uGain Module Status:", uGain.C.medium))
    for _, mod in ipairs(MODULES) do
        local enabled = uGain.IsModuleEnabled(mod.key)
        local statusText = enabled and uGain.Color("Enabled", uGain.C.light) or uGain.Color("Disabled", uGain.C.red)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%s] %s: %s", mod.cmd, mod.label, statusText))
    end
end

local function PrintHelp()
    DEFAULT_CHAT_FRAME:AddMessage(uGain.Color("uGain Slash Commands:", uGain.C.medium))
    DEFAULT_CHAT_FRAME:AddMessage("  /ugain           - Open settings panel")
    DEFAULT_CHAT_FRAME:AddMessage("  /ugain status    - Display module status")
    DEFAULT_CHAT_FRAME:AddMessage("  /ugain <module>  - Toggle module (xp, honor, bghonor, rep, skill, currency)")
end

local function HandleSlashCommand(msg)
    local cmd = string.lower(string.trim(msg or ""))

    if cmd == "" then
        OpenOptions()
        return
    end

    if cmd == "status" then
        PrintStatus()
        return
    end

    if cmd == "help" then
        PrintHelp()
        return
    end

    -- Match alias commands
    local targetKey = nil
    for _, mod in ipairs(MODULES) do
        if cmd == mod.cmd or cmd == mod.key then
            targetKey = mod.key
            break
        end
    end

    -- Support "money" as alias for currency
    if cmd == "money" then
        targetKey = "currency"
    end

    if targetKey then
        local newState = not uGain.IsModuleEnabled(targetKey)
        uGain.SetModuleEnabled(targetKey, newState)
        local statusText = newState and uGain.Color("Enabled", uGain.C.light) or uGain.Color("Disabled", uGain.C.red)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("uGain: %s is now %s.", targetKey, statusText))
        if checkboxes[targetKey] and checkboxes[targetKey]:IsVisible() then
            checkboxes[targetKey]:SetChecked(newState)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(uGain.Color("uGain: Unknown command '" .. cmd .. "'.", uGain.C.red))
        PrintHelp()
    end
end

SLASH_UGAIN1 = "/ugain"
SLASH_UGAIN2 = "/ug"
SlashCmdList["UGAIN"] = HandleSlashCommand
