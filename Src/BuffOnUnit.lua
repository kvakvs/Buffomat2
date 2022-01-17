---@class Bm2BuffOnUnitModule
local buffOnUnitModule = Bm2Module.DeclareModule("BuffOnUnit") ---@type Bm2BuffOnUnitModule

local spellsDb = Bm2Module.Import("SpellsDb")---@type Bm2SpellsDbModule

---Active aura or enchantment or other buff on an unit
---@class Bm2BuffOnUnit
---@field buffId string buffid key in spellsDb.allAvailableBuffs
---@field spellId number|nil Spellid for aura from blizzard API
---@field enchantmentId number|nil Enchantment id from blizzard API
---@field maxDuration number In seconds, max duration
---@field expires number In gametime seconds, when the buff is to expire
---@field source string UnitId who gave this buff

local buffOnUnitClass = {} ---@type Bm2BuffOnUnit
buffOnUnitClass.__index = buffOnUnitClass

---@return Bm2BuffOnUnit
---@param buffId string buffid key in spellsDb.allAvailableBuffs
---@param enchantmentId number Enchantment id from blizzard API
function buffOnUnitModule:New(buffId, spellId, enchantmentId, maxDuration, expires, source)
  local fields = {} ---@type Bm2BuffOnUnit
  setmetatable(fields, buffOnUnitClass)

  fields.buffId = buffId
  fields.enchantmentId = enchantmentId
  fields.spellId = spellId
  fields.maxDuration = maxDuration
  fields.expires = expires
  fields.source = source

  return fields
end

---Check whether this spell.id belongs to single buffs
---@return boolean
function buffOnUnitClass:IsSingle()
  return spellsDb.singleBuffSpellIds[self.spellId] ~= nil
end

--function memberBuffClass:Cancel()
--  local ret = false
--  if not InCombatLockdown() and list then
--    for i = 1, 40 do
--      --name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId,
--      local _, _, _, _, _, _, source, _, _, spellId = UnitBuff("player", i, "CANCELABLE")
--      if tContains(list, spellId) then
--        ret = true
--        BOM.CancelBuffSource = source or "player"
--        CancelUnitBuff("player", i)
--        break
--      end
--    end
--  end
--  return ret
--end