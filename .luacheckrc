std = "lua51"
max_line_length = false
exclude_files = {
  ".luacheckrc"
}
ignore = {
  "212",
  "311",
  "121",
}

globals = {
  "uGainDB",
  "SLASH_UGAIN1",
  "SLASH_UGAIN2",
  "SlashCmdList",
}

read_globals = {
  "abs",
  "floor",
  "mod",
  "format",
  "GetMoney",
  "UnitXP",
  "UnitXPMax",
  "UnitLevel",
  "MAX_PLAYER_LEVEL",
  "CreateFrame",
  "ChatFrame_AddMessageEventFilter",
  "GetPVPSessionStats",
  "GetAccountExpansionLevel",
  "GetNumFactions",
  "GetFactionInfo",
  "GetNumSkillLines",
  "GetSkillLineInfo",
  "NUM_CHAT_WINDOWS",
  "DEFAULT_CHAT_FRAME",
  "UIParent",
  "Settings",
  "InterfaceOptions_AddCategory",
  "InterfaceOptionsFrame_OpenToCategory",
  "C_CurrencyInfo",
  "C_PvP",
  "uC",
  "uShared_StringComma",
  "uShared_GetSearchPattern",
  "uShared_PrintAll",
}