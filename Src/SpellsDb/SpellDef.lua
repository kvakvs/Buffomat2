---@class Bm2SpellDefModule
local spellDefModule = Bm2Module.DeclareModule("SpellDef")

---@class Bm2SpellDefinition
---@field name string Useful name for debugging
---@field id number Ingame spell id
---@field isTBC boolean
---@field reagent Bm2ItemDefinition Required reagent which must be present in the bags
local classSpellDef = {}
classSpellDef.__index = classSpellDef

---@return Bm2SpellDefinition
---@param name string
---@param spellId number
---@param isTBC boolean
function spellDefModule:New(name, spellId, isTBC)
  local fields = {}
  setmetatable(fields, classSpellDef)

  fields.name = name
  fields.id = spellId
  fields.isTBC = isTBC

  return fields
end

---@param item Bm2ItemDefinition
---@return Bm2SpellDefinition
function classSpellDef:Reagent(item)
  self.reagent = item
  return self
end

---@return boolean
function classSpellDef:IsAvailable()
  return IsSpellKnown(self.id)
end
