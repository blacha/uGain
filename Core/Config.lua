local addonName, uGain = ...

-- Default module settings
uGain.DefaultSettings = {
    xp = true,
    honor = true,
    bgHonor = true,
    reputation = true,
    skill = true,
    money = true,
    currency = true,
    loot = true,
}

-- Initialize SavedVariables
function uGain.InitDB()
    if not uGainDB then
        uGainDB = {}
    end
    -- Migrate previous 'currency' setting to 'money' if money is not yet set
    if uGainDB.money == nil and uGainDB.currency ~= nil then
        uGainDB.money = uGainDB.currency
    end
    for key, val in pairs(uGain.DefaultSettings) do
        if uGainDB[key] == nil then
            uGainDB[key] = val
        end
    end
    uGain.DB = uGainDB
end

-- Query module state
function uGain.IsModuleEnabled(moduleName)
    if not uGain.DB then
        return true
    end
    return uGain.DB[moduleName] ~= false
end

-- Update module state
function uGain.SetModuleEnabled(moduleName, enabled)
    if not uGain.DB then
        uGain.InitDB()
    end
    uGain.DB[moduleName] = enabled and true or false
end

-- Event frame for addon loading
local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("ADDON_LOADED")
configFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        uGain.InitDB()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
