---@class Bm2MemberModule
local memberModule = Bm2Module.DeclareModule("Member")

--local engineModule = Bm2Module.Import("Engine"); ---@type Bm2EngineModule
--local partyModule = Bm2Module.Import("Party"); ---@type Bm2PartyModule
local buffOnUnitModule = Bm2Module.Import("BuffOnUnit"); ---@type Bm2BuffOnUnitModule
local engineModule = Bm2Module.Import("Engine"); ---@type Bm2EngineModule
local spellsDb = Bm2Module.Import("SpellsDb"); ---@type Bm2SpellsDbModule

---A party member or a player
---@class Bm2Member
---@field buffExists table<number, boolean> Availability of all auras even those not supported by Buffomat, by id, no extra detail stored
---@field buffs table<string, Bm2BuffOnUnit> Buffs on player keyed by buffid, only buffs supported by Buffomat are stored
---@field mainHandEnchantment Bm2BuffOnUnit|nil Mainhand player weapon buff
---@field offHandEnchantment Bm2BuffOnUnit|nil Offhand player weapon buff
---@field class string
---@field distance number
---@field group number Raid group number (9 if temporary moved out of the raid by BOM)
---@field hasReputationTrinket boolean Has AD reputation trinket equipped
---@field hasRidingTrinket boolean Has carrot/riding crop trinket equipped
---@field hasResurrection boolean Was recently resurrected (resurrection pending)
---@field isConnected boolean Is online
---@field isDead boolean Is this member dead
---@field isGhost boolean Is dead and corpse released
---@field isSameZone boolean Same zone as the player. Updated in party.GetPartyMembers()
---@field isPlayer boolean Is this a player
---@field isTank boolean Is this member marked as tank
---@field link string
---@field name string
---@field needBuff boolean
---@field unitId string

local memberClass = {} ---@type Bm2Member
memberClass.__index = memberClass

---@return Bm2Member
function memberModule:New()
  local fields = {} ---@type Bm2Member
  setmetatable(fields, memberClass)

  return fields
end

function memberClass:HasBuff(buffId)
  return self.buffs[buffId] ~= nil
end

---@param unitid string
---@param name string
---@param group number
---@param class string
---@param link string
---@param isTank boolean
function memberClass:Construct(unitid, name, group, class, link, isTank)
  self.distance = 100000
  self.unitId = unitid
  self.name = name
  self.group = group
  self.hasResurrection = self.hasResurrection or false
  self.class = class
  self.link = link
  self.isTank = isTank
  self.buffs = self.buffs or {}
  self.buffExists = self.buffExists or {}
end

---@return string
function memberClass:UnitFullName()
  return UnitFullName(self.unitId)
end

---@return string
function memberClass:GetZone()
  return C_Map.GetBestMapForUnit(self.unitId)
end

---Force updates buffs for one party member
---@param player Bm2Member
---@return boolean Someone is ghost
function memberClass:ForceUpdateBuffs(player)
  self.isPlayer = (self.name == player.name or self.name == "player")
  self.isDead = UnitIsDeadOrGhost(self.unitId) and not UnitIsFeignDeath(self.unitId)
  self.isGhost = UnitIsGhost(self.unitId)
  self.isConnected = UnitIsConnected(self.unitId)
  self.needBuff = true

  wipe(self.buffs)
  wipe(self.buffExists)

  if self.isDead then
    engineModule.activeBuffs[self.name] = nil
  else
    self.hasReputationTrinket = false
    self.hasRidingTrinket = false

    local buffIndex = 0

    repeat
      buffIndex = buffIndex + 1

      local unitAura = engineModule:UnitAura(self.unitId, buffIndex, "HELPFUL")
      local spellId = unitAura.spellId

      if spellId then
        self.buffExists[spellId] = true -- save all buffids even those not supported
      end

      local buffId = spellsDb.buffReverseLookup[spellId]
      local buff = spellsDb.allPossibleBuffs[buffId]

      if buff then
        -- Skip members who have a buff on the global ignore list - example phaseshifted imps
        if tContains(spellsDb.ignoreMembersWithAura, spellId) then
          wipe(self.buffs)
          self.needBuff = false
          break
        end

        --if tContains(BOM.ArgentumDawn.spells, spellId) then
        --  self.hasArgentumDawn = true
        --end

        --if tContains(BOM.Carrot.spells, spellId) then
        --  self.hasCarrot = true
        --end

        self.buffs[buffId] = buffOnUnitModule:New(
            buffId,
            spellId,
            nil,
            unitAura.duration,
            unitAura.expirationTime,
            unitAura.source)
      end

    until (not unitAura.name)
  end -- if is not dead

  return self.isGhost
end
