---@class Bm2ItemDefModule
---@field allItemsByCode table<string, Bm2ItemDefinition> [shortcode]=>ItemDef; Lookup by shortcode
---@field allItemsById table<number, Bm2ItemDefinition> [itemId]=>ItemDef; Lookup by item id
local itemDefModule = Bm2Module.DeclareModule("ItemDef") ---@type Bm2ItemDefModule
itemDefModule.allItemsByCode = {}
itemDefModule.allItemsById = {}

---@class Bm2ItemDefinition
---@field shortCode string Useful name for debugging
---@field itemId number Ingame item id
---@field isTBC boolean
local classItemDef = {} ---@type Bm2ItemDefinition
classItemDef.__index = classItemDef

---@return Bm2ItemDefinition
---@param shortCode string
---@param itemId number
---@param isTBC boolean
function itemDefModule:New(shortCode, itemId, isTBC)
  local fields = {} ---@type Bm2ItemDefinition
  setmetatable(fields, classItemDef)

  fields.shortCode = shortCode
  fields.itemId = itemId
  fields.isTBC = isTBC

  self.allItemsByCode[shortCode] = fields
  self.allItemsById[itemId] = fields
  return fields
end
