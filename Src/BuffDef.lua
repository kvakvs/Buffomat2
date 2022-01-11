---@class Bm2BuffDefModule
local buffDefModule = Bm2Module.DeclareModule("BuffDef")

---@class Bm2BuffDefinition
---@field id string
---@field defaultOn boolean Set to true to have it enabled by default for new users
---@param singleBuff table<number>|number Spellid or list of spellids for single buff, lowest rank first
---@param groupBuff table<number>|number Spellid or list of spellids for group buff, lowest rank first
---@param singleDuration number|nil Seconds for single buff or nil (for permanent auras)
---@param groupDuration number|nil Seconds for group buff or nil (if not applicable)
local classBuffDef = {}
classBuffDef.__index = classBuffDef

---@return Bm2BuffDefinition
function buffDefModule:New(buffId)
  local fields = {}
  setmetatable(fields, classBuffDef)

  fields.id = buffId
  fields.defaultOn = false

  return fields
end

---@return Bm2BuffDefinition
function classBuffDef:DefaultEnabled()
  self.defaultEnabled = true
  return self
end

---@param ranks table<number>|number
---@return Bm2BuffDefinition
function classBuffDef:SingleBuff(ranks)
  self.singleBuff = ranks
  return self
end

---@param ranks table<number>|number
---@return Bm2BuffDefinition
function classBuffDef:GroupBuff(ranks)
  self.groupBuff = ranks
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
