---@class Bm2MacroModule
---@field lines table<number, string>
---@field icon string
local macro = Bm2Module.DeclareModule("Macro")
macro.lines = {}

---@type Bm2ConstModule
local bm2const = Bm2Module.Import("Const")

function macro:Clear()
  if InCombatLockdown() then
    return
  end

  macro:Recreate()
  macro.lines = {}
  macro.icon = bm2const.MacroIconDisabled
  EditMacro(bm2const.MacroName, nil, macro.icon, macro:GetText())
end

---@return string
function macro:GetText()
  local t = "#showtooltip\n/bm2 update"
  for i, line in ipairs(macro.lines) do
    t = t .. "\n" .. line
  end
  return t
end

---Recreate if macro is missing
function macro:Recreate()
  if GetMacroInfo(bm2const.MacroName) == nil then
    local perAccount, perChar = GetNumMacros()
    local isChar

    if perChar < MAX_CHARACTER_MACROS then
      isChar = 1
    elseif perAccount >= MAX_ACCOUNT_MACROS then
      Bm2Addon:Print(_t("Need one macro slot to operate"))
      return
    end

    CreateMacro(bm2const.MacroName, bm2const.MacroIcon, "", isChar)
  end
end
