---@class Bm2SpellDefModule
---@field allSpells table<number, Bm2SpellDefinition> All created spells indexed by spellid
local spellDefModule = Bm2Module.DeclareModule("SpellDef")
spellDefModule.allSpells = {}

local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule

---@class Bm2SpellDefinition
---@field stringId string Useful name for debugging
---@field spellId number Ingame spell id
---@field isTBC boolean
---@field reagent Bm2ItemDefinition Required reagent which must be present in the bags
---@field spellName string From GetSpellInfo: spell name
---@field spellTexture string From GetSpellInfo: texture of spell icon
---@field spellCost number Mana cost or 0
local classSpellDef = {} ---@type Bm2SpellDefinition
classSpellDef.__index = classSpellDef

---@return Bm2SpellDefinition
---@param stringId string Some short name for spell, for example "fortitude1" for debug printing etc
---@param spellId number
---@param isTBC boolean
function spellDefModule:New(stringId, spellId, isTBC)
  local fields = {} ---@type Bm2SpellDefinition
  setmetatable(fields, classSpellDef)

  fields.stringId = stringId
  fields.spellId = spellId
  fields.isTBC = isTBC

  spellDefModule.allSpells[spellId] = fields

  -- Deferred load of this spell info
  local spellMixin = Spell:CreateFromSpellID(spellId)

  local spellInfoReady_func = function()
    local spellDef = spellDefModule.allSpells[spellId]

    spellDef.spellName = spellMixin:GetSpellName()
    spellDef.spellTexture = spellMixin:GetSpellTexture()

    -- Get spell cost in mana or zero
    local allCosts = GetSpellPowerCost(spellId)
    spellDef.spellCost = 0

    for _i, costRow in allCosts do
      if costRow.type == constModule.PowertypeMana then
        spellDef.spellCost = costRow.cost
      end
    end

    Bm2Addon:Print("Loaded spell " .. spellId .. ": " .. spellDef.spellName)
  end

  spellMixin:ContinueOnSpellLoad(spellInfoReady_func)

  return fields
end

---@param item Bm2ItemDefinition
---@return Bm2SpellDefinition
function classSpellDef:Reagent(item)
  self.reagent = item
  return self
end

---Performs WoW API call for IsSpellKnown.
---Alternatively can use spellsDbModule:IsSpellAvailable using cached data
---@return boolean
function classSpellDef:IsAvailable()
  return IsSpellKnown(self.spellId)
end
