---@class Bm2ItemDefModule
local itemDefModule = Bm2Module.DeclareModule("ItemDef")

---@class Bm2ItemDefinition
---@field name string Useful name for debugging
---@field id number Ingame item id
---@field isTBC boolean
local classItemDef = {}
classItemDef.__index = classItemDef

---@return Bm2ItemDefinition
---@param itemName string
---@param itemId number
---@param isTBC boolean
function itemDefModule:New(itemName, itemId, isTBC)
  local fields = {}
  setmetatable(fields, classItemDef)

  fields.name = itemName
  fields.id = itemId
  fields.isTBC = isTBC

  return fields
end
