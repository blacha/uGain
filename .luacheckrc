
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

read_globals = {
  "abs",
  "floor",
  "mod",
  "format",
  "GetMoney",
  "UnitXP",
  "UnitXPMax",
  "UnitLevel",
  "CreateFrame",
  "ChatFrame_AddMessageEventFilter",
  "GetNumFactions",
  "GetFactionInfo",
  "GetNumSkillLines",
  "GetSkillLineInfo",
  "NUM_CHAT_WINDOWS",
  "uC",
  "uShared_StringComma",
  "uShared_GetSearchPattern",
  "uShared_PrintAll",
  "C_CurrencyInfo",
  "C_PvP"
}