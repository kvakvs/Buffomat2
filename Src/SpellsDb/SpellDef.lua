---@class Bm2SpellDefModule
---@field allSpells table<number, Bm2SpellDefinition> All created spells indexed by spellid
local spellDefModule = Bm2Module.DeclareModule("SpellDef")
spellDefModule.allSpells = {}

local bagModule = Bm2Module.Import("Bag")---@type Bm2BagModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local taskListModule = Bm2Module.Import("TaskList") ---@type Bm2TaskListModule

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
    spellDef.spellTexture = GetSpellTexture(spellId)

    -- Get spell cost in mana or zero
    local allCosts = GetSpellPowerCost(spellId)
    spellDef.spellCost = 0

    for _i, costRow in ipairs(allCosts) do
      if costRow.type == constModule.PowertypeMana then
        spellDef.spellCost = costRow.cost
      end
    end

    --Bm2Addon:Print("Loaded spell " .. spellId .. ": " .. spellDef.spellName)
  end

  --Stack: Interface\AddOns\Buffomat2\Src/SpellsDb/SpellDef.lua:57: Usage: NonEmptySpell:ContinueOnLoad(callbackFunction)
  if C_Spell.DoesSpellExist(spellId) then
    spellMixin:ContinueOnSpellLoad(spellInfoReady_func)
  else
    Bm2Addon:Print("Spell " .. spellId .. " does not exist, please report to the developer")
  end

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

spellDefModule.REASON_NOTAVAIL = "notAvail" -- spell is not in the spell book
spellDefModule.REASON_REAGENT = "missingReagent" -- spell requires reagent which is not in the bag
spellDefModule.REASON_RANGE = "range" -- spell target is out of spell range
spellDefModule.REASON_MANA_COST = "manaCost" -- player does not have enough mana

---Check has reagent in the bag, is in range, enough mana
---@param target string
---@return boolean|string Reason to not be cast, or true if the spell can be cast
function classSpellDef:CanBeCast(target)
  if not self:IsAvailable() then
    return spellDefModule.REASON_NOTAVAIL
  end

  if self.reagent and not bagModule:AnyInventoryItem(self.reagent.itemId, true) then
    return spellDefModule.REASON_REAGENT -- no reagent
  end

  if not IsSpellInRange(self.spellId, target) then
    return spellDefModule.REASON_RANGE
  end

  if self.spellCost > taskListModule.maxPlayerMana then
    return spellDefModule.REASON_MANA_COST
  end

  return true
end
