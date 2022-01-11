---@class Bm2BuffDefModule
local buffDefModule = Bm2Module.DeclareModule("BuffDef")

---@class Bm2BuffDefinition
---@field id string
---@field defaultOn boolean Set to true to have it enabled by default for new users
---@field singleBuff table<number>|Bm2SpellDefinition Spelldef or list of spellids for single buff, lowest rank first
---@field groupBuff table<number>|Bm2SpellDefinition Spelldef or list of spellids for group buff, lowest rank first
---@field singleDuration number|nil Seconds for single buff or nil (for permanent auras)
---@field groupDuration number|nil Seconds for group buff or nil (if not applicable)
---@field hasCooldown boolean True to only attempt to buff once, as it might go on cooldown after the first cast
---@field cancelForm boolean True to leave shapeshift form/shadow form
---@field targetClasses table<string>|string|nil Classes to only buff, nil to buff everyone, "player" for self only
---@field buffType string Special handling for certain types - Enum buffDefModule.BUFFTYPE_*
local classBuffDef = {}
classBuffDef.__index = classBuffDef

buffDefModule.BUFFTYPE_RESURRECTION = "resurrection"

---@return Bm2BuffDefinition
function buffDefModule:New(buffId)
  local fields = {}
  setmetatable(fields, classBuffDef)

  fields.id = buffId
  fields.defaultOn = false

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

---Ranks for single target buff, add reagent cost in each spelldef
---@param ranks table<Bm2SpellDefinition>|Bm2SpellDefinition
---@return Bm2BuffDefinition
function classBuffDef:SingleBuff(ranks)
  self.singleBuff = ranks
  return self
end

---Ranks for group buff, add reagent cost in each spelldef
---@param ranks table<Bm2SpellDefinition>|Bm2SpellDefinition
---@return Bm2BuffDefinition
function classBuffDef:GroupBuff(ranks)
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
