---@class Bm2UiRowBuilderModule
local rowBuilderModule = Bm2Module.DeclareModule("Ui/RowBuilder")

local buffDef = Bm2Module.Import("SpellsDb/BuffDef") ---@type Bm2BuffDefModule
local uiModule = Bm2Module.Import("Ui") ---@type Bm2UiModule

---@class Bm2RowBuilder
---@field parent Bm2Control
---@field prevControl Bm2Control
---@field x number
---@field y number
---@field rowHeight number
local classRowBuilder = {}
classRowBuilder.__index = classRowBuilder

---@return Bm2RowBuilder
function rowBuilderModule:New(parent, rowHeight)
  local obj = {}
  setmetatable(obj, classRowBuilder)

  obj.parent = parent
  obj.x = 0
  obj.y = 0
  obj.rowHeight = rowHeight

  return obj
end

---@return Bm2RowBuilder
function classRowBuilder:NewRow()
  self.y = self.y + self.rowHeight
  self.x = 0
  return self
end

---Creates a row of UI controls for a buff
---@param buff Bm2BuffDefinition
function classRowBuilder:CreateTabRow(buff)
  if buff.buffType == buffDef.BUFFTYPE_SPELL then
    Bm2Addon:Print("tab row for spell " .. buff.buffId)

    local f = uiModule.aceGui:Create("Button")
    f:SetText("TestButton")
    f:SetCallback("OnClick", function() Bm2Addon:Print("Click!") end)
    self.parent:AddChild(f)

  elseif buff.buffType == buffDef.BUFFTYPE_RESURRECTION then
    Bm2Addon:Print("tab row for res " .. buff.buffId)

  elseif buff.buffType == buffDef.BUFFTYPE_ITEM_USE then
    Bm2Addon:Print("tab row for item " .. buff.buffId)

  elseif buff.buffType == buffDef.BUFFTYPE_ITEM_TARGET_USE then
    Bm2Addon:Print("tab row for targeted " .. buff.buffId)

  else
    Bm2Addon:Print("unsupported type create_tabrow for " .. buff.buffId)
  end
end

---Creates a row of UI controls for a consumable buff
---@param buff Bm2BuffDefinition
function classRowBuilder:CreateConsumableTabRow(buff)
  if buff.buffType == buffDef.BUFFTYPE_ITEM_USE then
    Bm2Addon:Print("tab row for item " .. buff.buffId)

  elseif buff.buffType == buffDef.BUFFTYPE_ITEM_TARGET_USE then
    Bm2Addon:Print("tab row for targeted " .. buff.buffId)

  else
    Bm2Addon:Print("unsupported type consum_tabrow for " .. buff.buffId)
  end
end

---Creates a row of UI controls for buff cancellation checkbox
---@param buff Bm2BuffDefinition
function classRowBuilder:CreateCancelTabRow(buff)
  Bm2Addon:Print("cancel_tabrow for " .. buff.buffId)
end
