---@class Bm2BuffDefModule
local buffDefModule = Bm2Module.DeclareModule("SpellsDb/BuffDef")

local engine = Bm2Module.Import("Engine")---@type Bm2EngineModule

---@class Bm2BuffDefinition
---@field buffId string
---@field hint string Short explanation text used as tooltip?
---@field defaultOn boolean Set to true to have it enabled by default for new users
---@field singleBuff table<number, Bm2SpellDefinition> Table of spelldefs for single buff, lowest rank first
---@field groupBuff table<number, Bm2SpellDefinition> Table of spelldefs for group buff, lowest rank first
---@field singleDuration number|nil Seconds for single buff or nil (for permanent auras)
---@field groupDuration number|nil Seconds for group buff or nil (if not applicable)
---@field hasCooldown boolean True to only attempt to buff once, as it might go on cooldown after the first cast
---@field cancelForm boolean True to leave shapeshift form/shadow form
---@field targetClasses table<string>|string|nil Classes to only buff, nil to buff everyone, "player" for self only
---@field buffType string Special handling for certain types - Enum buffDefModule.BUFFTYPE_*
---@field shapeshiftFormId number|nil Allows to check whether user is already in that shapeshift
---@field requiresShapeshiftFormId number|nil Requires player to be in this form
---@field sort number|nil Suggests when the buff should be prioritized, 0=asap, 100=anytime, or as 1000=late as possible
local classBuffDef = {}
classBuffDef.__index = classBuffDef

buffDefModule.BUFFTYPE_SPELL = "spell" -- simple cast
buffDefModule.BUFFTYPE_RESURRECTION = "resurrection" -- someone is dead
buffDefModule.BUFFTYPE_ITEM_USE = "item_use" -- right click an item
buffDefModule.BUFFTYPE_ITEM_TARGET_USE = "item_target_use" -- target someone then right click
buffDefModule.BUFFTYPE_TRACKING = "tracking" -- enable via tracking API

buffDefModule.SEQ_EARLY = 0
buffDefModule.SEQ_NORMAL = 100
buffDefModule.SEQ_LATE = 1000

---Returns true if this buff is a class ability, spell or tracking buff
---@return boolean
function classBuffDef:IsClassBuff()
  return self.buffType == buffDefModule.BUFFTYPE_SPELL
      or self.buffType == buffDefModule.BUFFTYPE_TRACKING
      or self.buffType == buffDefModule.BUFFTYPE_RESURRECTION
end

---Returns true if this buff is a consumable item, or elixir
---@return boolean
function classBuffDef:IsConsumableBuff()
  return self.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_USE
      or self.buffType == buffDefModule.BUFFTYPE_ITEM_USE
end

---@return Bm2BuffDefinition
function buffDefModule:New(buffId)
  local fields = {} ---@type Bm2BuffDefinition
  setmetatable(fields, classBuffDef)

  fields.buffId = buffId
  fields.defaultOn = false
  fields.singleBuff = {}
  fields.groupBuff = {}
  fields.sort = buffDefModule.SEQ_NORMAL
  fields.buffType = buffDefModule.BUFFTYPE_SPELL

  return fields
end

---For new Buffomat users this will be enabled by default
---@return Bm2BuffDefinition
function classBuffDef:DefaultEnabled()
  self.defaultEnabled = true
  return self
end

---Special buff types for special handling
---@param buffType string Enum buffDefModule.BUFFTYPE_*
---@return Bm2BuffDefinition
function classBuffDef:Type(buffType)
  self.buffType = buffType
  return self
end

---Buff requires player to leave shapeshift/shadowform to cast
---@return Bm2BuffDefinition
function classBuffDef:CancelForm()
  self.cancelForm = true
  return self
end

---Buff only targets player themself
---@return Bm2BuffDefinition
function classBuffDef:SelfOnly()
  self.targetClasses = "player"
  return self
end

---Buff only targets player themself
---@return Bm2BuffDefinition
function classBuffDef:ShapeshiftFormId(id)
  self.shapeshiftFormId = id
  return self
end

---Ranks for single target buff, add reagent cost in each spelldef
---@param ranks table<Bm2SpellDefinition>|Bm2SpellDefinition
---@return Bm2BuffDefinition
function classBuffDef:SingleBuff(ranks)
  if type(ranks) == "Bm2SpellDefinition" then
    ranks = { ranks }
  end
  self.singleBuff = ranks
  return self
end

---Ranks for group buff, add reagent cost in each spelldef
---@param ranks table<Bm2SpellDefinition>|Bm2SpellDefinition
---@return Bm2BuffDefinition
function classBuffDef:GroupBuff(ranks)
  if type(ranks) == "Bm2SpellDefinition" then
    ranks = { ranks }
  end
  self.groupBuff = ranks
  return self
end

---Attempt to buff once, then it goes on cd
---@return Bm2BuffDefinition
function classBuffDef:HasCooldown()
  self.hasCooldown = true
  return self
end

---@param single number
---@param group number|nil
---@return Bm2BuffDefinition
function classBuffDef:Duration(single, group)
  self.singleDuration = single
  self.groupDuration = group
  return self
end

---Filter classes who can receive the buff
---@param classes table<string>
---@return Bm2BuffDefinition
function classBuffDef:TargetClasses(classes)
  self.targetClasses = classes
  return self
end

---Add a short help text
---@param hint string
---@return Bm2BuffDefinition
function classBuffDef:Hint(hint)
  self.hint = hint
  return self
end

---Requires player to be in this shapeshift form
---@param formId number
---@return Bm2BuffDefinition
function classBuffDef:RequiresShapeshiftFormId(formId)
  self.requiresShapeshiftFormId = formId
  return self
end

---Sorting key, small numbers first, big numbers late
---@param p number
---@return Bm2BuffDefinition
function classBuffDef:Sort(p)
  self.sort = p
  return self
end

---Check whether the spell/buff is available to the player
---@return boolean
function classBuffDef:IsAvailable()
  -- Item buffs are always available, who knows when the user will have the item
  if self.buffType == buffDefModule.BUFFTYPE_ITEM_USE
      or self.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_USE then
    return true
  end

  -- if any of single buff spells are available...
  for _index, spell in ipairs(self.singleBuff) do
    if spell:IsAvailable() then
      return true
    end
  end
  -- if any of group buff spells are available...
  for _index, spell in ipairs(self.groupBuff) do
    if spell:IsAvailable() then
      return true
    end
  end

  return false
end

---Cancels all possible auras of this buff on player
function classBuffDef:Cancel()
  local spellIds = {}

  for _index, spell in ipairs(self.singleBuff) do
    tinsert(spellIds, spell.id)
  end
  for _index, spell in ipairs(self.groupBuff) do
    tinsert(spellIds, spell.id)
  end

  engine:CancelBuff(spellIds)
end